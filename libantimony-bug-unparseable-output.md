# libantimony renders degenerate SBML as Antimony it cannot read back

**Version tested:** libantimony v3.2.0 (Windows x64, `libantimony.dll` from the
official binary distribution).
**Severity:** the SBML → Antimony → SBML round trip does not survive. Two
outcomes, depending on the construct: 15 cases where `getAntimonyString`
produces text `loadAntimonyString` rejects outright, and 6 where the text
parses but a declared value has been discarded.
**Scope:** 21 SBML Test Suite cases.

---

## Summary

For several legal-but-degenerate SBML constructs, the Antimony *renderer* emits
output the Antimony *parser* does not accept. No consumer code is involved —
three calls are the whole reproduction:

```c
loadSBMLFile("01240-sbml-l3v2.xml");
char* ant = getAntimonyString(getMainModuleName());
loadAntimonyString(ant);        /* -1: "syntax error, unexpected ';'" */
```

The input SBML is unusual but valid — an `<event>` with no
`<listOfEventAssignments>`, a `<speciesReference>` with negative stoichiometry,
a `<reaction>` with neither reactants nor products, a rule with no `<math>`.
libSBML accepts all of them; the suite ships them as deliberate edge cases. The
problem is that Antimony's surface syntax has no way to write them down, and
the renderer emits something malformed rather than reporting that.

Shapes 1–3 below fail to re-read. Shape 4 is different and, we think, worse in
one respect: the rendering *is* valid Antimony, so nothing signals a problem,
but the symbol's declared value has been dropped and the model now computes a
different answer. That one is not recoverable by any route we can find,
including antimony's own SBML export.

This is a different failure from the `bvar` substitution bug reported
separately, though shape 4 shares its character: the model that comes back is
not the model that went in, and nothing reports an error.

---

## Shape 1 — reaction with no reactants and no products (9 cases)

`01245 01246 01300 01301 01302 01303 01304 01305 01306`

```
J0:  -> ; 3;        // 01300
J0:  => ; 2;        // 01246
J0:  -> ; time;     // 01306
```

`loadAntimonyString` →
`Error in model string, line 5: syntax error, unexpected ';', expecting '$' or number or element name`

The SBML is a reaction whose `<listOfReactants>` and `<listOfProducts>` are both
absent or empty, carrying only a kinetic law. It contributes nothing to any
species' rate but is legal, and the suite uses it to check that a rate law with
no participants is evaluated (or not) correctly.

## Shape 2 — negative stoichiometry (5 cases)

`01422 01426 01427 01432 01433`

```
J0: A + -1 A -> ; -1;                                 // 01422
J0: 2 A -> -3 A; -1;                                  // 01426
J0: -2 A -> 3 A; 1;                                   // 01427
J0: 2 A + -1 B -> -1 A + 2 B; 1;                      // 01432
J0: A + 2 A + -4 A -> 5 A + -2 A + A + -1 A; 1;       // 01433
```

`loadAntimonyString` →
`Error in model string, line 9: syntax error, unexpected '-', expecting '$' or number or element name`

A negative `stoichiometry` attribute on a `<speciesReference>` is legal SBML.
The renderer writes the coefficient bare (`-1 A`), which the grammar reads as a
subtraction rather than a stoichiometric coefficient.

## Shape 3 — event with no event assignments (1 case)

`01240`

```
E0: at time > 5.5: ;
```

`loadAntimonyString` →
`Error in model string, line 5: syntax error, unexpected ';', expecting '$' or element name or '\n'`

The SBML `<event>` has a trigger and no `<listOfEventAssignments>`. The renderer
emits the assignment separator followed by nothing.

## Shape 4 — rule with an empty body, declared value discarded (6 cases)

`01234 01235 01465 01552 01554 01657`

These **do** re-read — the parser accepts an empty right-hand side — so they are
less severe than the first three. The damage is different: the rule conveys
nothing *and* the value the symbol was declared with is dropped, so the symbol
ends up with neither a value nor a rule.

### The clearest case: 01234

The whole model is two elements:

```xml
<parameter id="p" value="3" constant="true"/>
<initialAssignment symbol="p" />              <!-- no <math> -->
```

An `<initialAssignment>` with no `<math>` is a no-op, so `p` should keep the
value 3 — which is exactly what the suite expects, `p = 3` at every timepoint.

What libantimony produces:

```
// getAntimonyString
p = ;
const p;
```

and through the C API, for the only symbol in the model:

| call | result |
|---|---|
| `getNthSymbolEquationOfType` | `""` |
| `getNthSymbolInitialAssignmentOfType` | `""` |
| `getNthSymbolAssignmentRuleOfType` | `""` |
| `getSymbolHasValue` | `false` |
| `getSBMLString` | writes `<parameter id="p" constant="true"/>` — **`value="3"` is gone** |

The `3` is read correctly from the SBML and then discarded. It is not
recoverable by any route, including antimony's own SBML export, so a consumer
cannot reach the answer the suite asks for.

`01235` is the same model with `constant="false"` and an empty
`<assignmentRule>` (renders `p := ;`). Both expect `p = 3` throughout.

For contrast, `01244` is the same one-parameter model with an empty
`<algebraicRule/>`, and it does **not** belong here: it renders as

```
_alg0: 0 = ;
p = 3;
```

The empty rule is still emitted, but `p = 3` survives and `getSymbolHasValue`
is true, so a consumer can ignore the rule and get the right answer. That is
the behaviour we would like for 01234 and 01235 as well — the empty rule can
stay, as long as the value does.

### The stoichiometry cases: 01465 01552 01554 01657

Same shape, reached through a `<speciesReference>`:

```xml
<assignmentRule variable="S1_sr" />                                    <!-- no math -->
<speciesReference id="S1_sr" species="S1" stoichiometry="2" constant="false"/>
```

renders as `S1_sr := ;`.

`getNthReactionMthProductStoichiometryString` correctly returns `"S1_sr"` — the
accessor added in 3.2.0 works — but resolving that symbol yields nothing, so
the stoichiometry the SBML gives as `2` is unreachable. The new accessor leads
to a dead end.

---

## Reproduction

`repro_unparseable.py` beside this file. It needs only the SBML Test Suite and
`libantimony.dll`; no other dependencies.

```
python repro_unparseable.py <path-to-sbml-test-suite/semantic> <path-to-libantimony.dll>
```

It loads each case's `-sbml-l3v2.xml` (falling back to `l3v1`), calls
`getAntimonyString`, feeds the result straight back to `loadAntimonyString`,
and prints the offending line and error for each failure. For shape 4 it also
calls `getSBMLString` and reports whether the declared value survived.

Expected output on v3.2.0, and what we see:

```
15 of 15 re-read failures reproduced.
6 of 6 lost the declared value.
```

---

## What we would like

In rough order of usefulness to us:

1. **Emit parseable text for shapes 1–3**, whatever form that takes — a syntax
   for negative stoichiometry, something to stand in for an empty event
   assignment list and an empty reaction. Any output the parser accepts is
   better than output it does not.
2. **Failing that, report it.** An error or warning on `getAntimonyString` when
   the model contains a construct the renderer cannot express would let us
   refuse the model loudly instead of discovering it at re-parse.
3. **For shape 4, keep the declared value.** An empty rule is a no-op in SBML;
   dropping the symbol's `value` along with it is the part that costs us the
   answer. Rendering `p = 3` and keeping the empty rule -- which is what
   01244 already does -- would make all six cases work.

Item 2 alone would be enough for shapes 1–3: we are content to refuse those,
we only need to be able to tell that we must. Shape 4 is different — those
models are well defined and have an unambiguous expected answer, so we would
rather they worked.

---

## Cases

| shape | re-reads? | n | cases |
|---|---|---|---|
| reaction with no reactants or products | no | 9 | 01245 01246 01300 01301 01302 01303 01304 01305 01306 |
| negative stoichiometry | no | 5 | 01422 01426 01427 01432 01433 |
| event with no assignments | no | 1 | 01240 |
| rule with empty body, value discarded | yes, but empty | 6 | 01234 01235 01465 01552 01554 01657 |
