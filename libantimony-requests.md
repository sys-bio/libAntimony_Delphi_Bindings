# libantimony C API — gaps found

Each item below is something the library **knows internally** but does not
expose, or exposes in a form that loses information. In each case we either
work around it in a way we would rather not, or refuse models we could
otherwise support. Ordered by how much they cost us.

> **Update, libantimony v3.2.0.** Upstream implemented §1, §2 (the string
> accessors), §3 and §4 essentially as requested, and documented §5 as a
> caveat on `getSymbolAssignmentRulesOfType` rather than changing the
> behaviour. All the new accessors are bound in `uAntimonyRaw` and wrapped in
> `uAntimonyAPI`, and are exercised by the smoke test.
>
> **Still outstanding: §2b (`conversionFactor`) and §4b (MathML constant
> arguments)** — both re-tested against 3.2.0 with fresh minimal repros, both
> reproduce unchanged. §2b is the more costly of the two: §4b we can at least
> detect and refuse, whereas a model carrying a `conversionFactor` runs and is
> quietly wrong.

---

## 1. `hasOnlySubstanceUnits` has no accessor

**Status: RESOLVED in v3.2.0.** `getSymbolSubstanceOnly(moduleName, symbolName)`
was added exactly as requested; the bulk variant was not. The text-scraping
workaround can be dropped.

`Variable::GetSubstOnly()` / `SetSubstOnly()` exist in `variable.h`, and the
flag round-trips correctly through Antimony's own serialisation
(`substanceOnly species S1 in c;`). There is no C API getter.

This matters more than it might look: a `substanceOnly` species is expressed in
amounts rather than concentrations, so ignoring the flag is a silent
factor-of-compartment-volume error in the species' trajectory — correct
whenever the volume happens to be 1, wrong otherwise, and never reported.

We currently recover it by calling `getAntimonyString()` and parsing
`substanceOnly species ...` declarations out of the result. That works because
we are parsing the library's own canonical output rather than user input, but
it is obviously fragile.

**Requested:**
```c
bool getSymbolSubstanceOnly(const char* moduleName, const char* symbolName);
/* or, matching the existing bulk-getter style: */
bool* getSymbolSubstanceOnlyOfType(const char* moduleName, return_type rt);
```

---

## 2. Stoichiometry can only be read as a `double`, so symbolic values are lost

**Status: RESOLVED in v3.2.0.** `getNthReactionMthReactantStoichiometryString`
and `getNthReactionMthProductStoichiometryString` were added, taking
`unsigned long` rather than `size_t`. Verified: for `R1: S1 + n S2 => S3`, the
numeric getter returns NaN for S2 and the string getter returns `"n"`, whose
value is then an ordinary symbol lookup. This also supplies the
symbol-to-`(reaction, index)` mapping the correction below asked for, so the
`getAntimonyString` reaction-line parsing can be dropped too.

> **Correction.** For a stoichiometry the model *declares* as a symbol, both
> the name and the defining expression are already available:
>
> ```c
> getSymbolNamesOfType(rtAllStoichiometries);            /* S1_S2_stoichiometry */
> getSymbolAssignmentRulesOfType(rtAllStoichiometries);  /* "2*p1"              */
> ```
>
> The catch, which is what made this look impossible: **both return empty when
> the model is read from antimony source.** Only after an SBML export/import
> round trip do the stoichiometry symbols appear. That is surprising enough to
> be worth documenting on the API even though no new accessor is needed.
>
> What is still missing is the **mapping** from a symbol to the
> `(reaction, reactant/product index)` it belongs to. Elimination does not
> recover it — a reaction may carry two symbolic stoichiometries at once. We
> parse the reaction line out of `getAntimonyString()` to get it, which works
> but is the sort of thing an accessor should not require:
>
> ```c
> /* '' or NULL when that position's stoichiometry was a plain number */
> char* getNthReactionMthReactantStoichiometryName(const char*, size_t, size_t);
> char* getNthReactionMthProductStoichiometryName(const char*, size_t, size_t);
> ```
>
> The remainder of this item — the NaN case, where nothing is reported at all —
> stands unchanged and is the more valuable half.

`getNthReactionReactantStoichiometries` and friends return `double*`. When a
stoichiometry is written as a symbol —

```
reaction1: S1 + generatedId_0 S2 => S3;   generatedId_0 = 2*p1;
```

— the returned value is `NaN`, and there is no way to recover the symbol's
name. `getSymbolNamesOfType(rtAllStoichiometries)` does not report it either,
because `generatedId_0` is an ordinary parameter as far as that query is
concerned.

The value here is often *constant* (`2*p1` folds to 2), so this is not
necessarily about variable stoichiometry — it is about not being able to see
what was written. We currently detect the `NaN` and refuse the model, which
costs us roughly 195 SBML Test Suite cases.

**Requested:**
```c
char* getNthReactionMthReactantStoichiometryString(const char* moduleName,
                                                   size_t rxn, size_t reactant);
char* getNthReactionMthProductStoichiometryString(const char* moduleName,
                                                  size_t rxn, size_t product);
```
returning the expression as written (and the number as text when it is simply a
number), mirroring how rate laws are already returned as strings.

---

## 2b. `conversionFactor` is destroyed on import and never comes back

**Status: STILL OPEN — re-verified against v3.2.0. Models silently produce
wrong answers. No workaround exists.**

Re-tested with a minimal L3V2 model carrying `conversionFactor="m_cf"` on
`<model>` and `conversionFactor="s1_cf"` on a species. Round-tripping it
(`sbml2antimony` then `antimony2sbml`, both v3.2.0) gives **zero** occurrences
of `conversionFactor` in the re-exported SBML; `m_cf` and `s1_cf` survive only
as ordinary `const` parameters. No accessor was added and the attribute is
still dropped on export, so every claim in this section stands unchanged.

SBML L3's `conversionFactor` -- on `<model>` and on `<species>` -- multiplies a
species' stoichiometric contribution:

```
dA_i/dt = cf_i * SUM_j (N_ij * v_j)
```

with `cf_i` the species' own factor, else the model's, else 1. Suite case
01775 sets `s1_cf = avogadro/1.5e24` on S1 and `m_cf = avogadro/1e24` on the
model; the expected S1 at t=10 is 1.9598, and without the factor it is 1.9.

**Unlike every other gap in this document there is no workaround**, because the
attribute is not merely unexposed -- it is *lost*:

| route | result |
|---|---|
| `getAntimonyString()` | `m_cf` and `s1_cf` appear as ordinary `const` parameters, with nothing marking them as conversion factors |
| C API | no accessor (`AddConversionFactor` in `formula.h` is internal submodel synchronisation, a different thing) |
| `getSBMLString()` | **the attribute is absent** -- antimony does not preserve it through its own export |

That last row is the one that matters. For `hasOnlySubstanceUnits` we can at
least scrape the canonical text; here there is nothing to scrape in any
representation antimony will give us.

It also cannot be DETECTED, so we cannot even refuse such a model loudly -- it
runs and is quietly wrong, which is the outcome this project works hardest to
avoid. Roughly 81 test-suite cases carry the tag.

**Requested:** preserve the attribute through import/export, and expose it:
```c
char* getSymbolConversionFactor(const char* moduleName, const char* symbolName);
char* getModelConversionFactor(const char* moduleName);
```

## 3. Function definitions cannot be enumerated

**Status: RESOLVED in v3.2.0.** The enumeration was added, with two
differences from the request: there is **no `moduleName` parameter** (function
definitions are not module-scoped, so the whole active set is queried), and
`getNumUserFunctionArguments(n)` was added to give the length of the
`getNthUserFunctionArguments(n)` array. The SBML round trip taken purely to
expand function calls is no longer needed.

A model may declare `function R_PFK(a, b, c) ... end` and call it from a rate
law. `getReactionRates` returns the rate law with the call **intact**, and
there is no API to enumerate the definitions or retrieve a body, so a consumer
cannot resolve the call.

We work around it with `setRemoveFunctionDefinitions(true)` and an SBML export/
import round trip, which expands them. That works, but it means every model
pays an SBML serialisation just in case, and it is a strange thing to have to
discover.

**Requested:** either an enumeration —
```c
size_t getNumUserFunctions(const char* moduleName);
char*  getNthUserFunctionName(const char* moduleName, size_t n);
char** getNthUserFunctionArguments(const char* moduleName, size_t n);
char*  getNthUserFunctionBody(const char* moduleName, size_t n);
```
— or, simpler for our purposes, a flag that makes the *Antimony* loader inline
them the way the SBML path already can.

---

## 4. Symbols declared without a value are reported as `rtAllUnknown`

**Status: RESOLVED in v3.2.0, by the accessor rather than the reclassification.**
`getSymbolHasValue(moduleName, symbolName)` was added, so the distinction this
section actually asked for — **"no value" vs "value zero"** — is now visible.
Such symbols are **still reported under `rtAllUnknown`**, so a consumer walking
`rtConstFormulas` / `rtVarFormulas` still will not see them; walk `rtAllUnknown`
as well.

`getSymbolHasValue` does **not** separate a valueless declaration from a typo in
a rate law, and nothing can: by the time the model is in memory the two are the
same thing. `<parameter id="x"/>` and a bare reference to a misspelled `x` both
arrive as a symbol of unknown type with no value, and both serialise as `x = ;`.
That was never what this section asked for — the request was to tell "no value"
apart from "zero" — and the §4b note below is worded accordingly.

An SBML parameter with no `value` attribute is serialised by Antimony as
`x = ;` and is reported under `rtAllUnknown` rather than as a formula. A
consumer walking `rtConstFormulas` / `rtVarFormulas` never sees it, so any
expression referencing `x` looks like a reference to an undefined symbol.

We refuse these models rather than registering unknown symbols as `NaN`
parameters, because doing the latter would also silence a genuine typo in a
rate law — we would rather reject a valid-but-odd model than accept an invalid
one silently.

**Requested:** report such symbols under their actual type with an indication
that no value was supplied, e.g.
```c
bool getSymbolHasValue(const char* moduleName, const char* symbolName);
```
so the distinction between "no value" and "value zero" is visible. The same
applies to a compartment with no `size` (we currently default it to 1, matching
libroadrunner, but we are guessing).

---

## 4b. A MathML constant passed to a function definition is not substituted

**Status: STILL OPEN as a bug — re-verified against v3.2.0 — but it is now
DETECTABLE, which it was not when this was written.**

Reproduced on v3.2.0 with a minimal L3V2 file containing both halves:

```
c := piecewise(1, and(x), 0);     // <true/> not substituted; should be and(true)
d := piecewise(1, P1 == b, 0);    // <ci>P1</ci> substituted, <pi/> not
x = ;   b = ;                     // both escaped bvars
```

The bug is unchanged, and so is our position on it: we already detect the
escaped bvar as an undefined symbol under `rtAllUnknown` and refuse the model.
`getSymbolHasValue` does not change that — it confirms the symbol is valueless
rather than zero, which is tidier than inferring it, but it is not a new
detection route and does not distinguish this artefact from §4's genuine
valueless declaration. The request stands as written.

This is a **bug, and a silent one**: the model that comes back is not the model
that went in, and nothing reports an error.

When a `functionDefinition` is called with one of the MathML symbolic constants
as an argument, the corresponding `bvar` is **left unsubstituted in the body**.
The lambda's formal parameter then escapes into the model as a free symbol,
which Antimony serialises as an undefined variable:

```xml
<functionDefinition id="my_and">
  <lambda><bvar><ci> x </ci></bvar>
    <apply><and/><ci> x </ci></apply></lambda>
</functionDefinition>
...
<apply><ci> my_and </ci><true/></apply>
```

`loadSBMLFile` + `getAntimonyString` on the above gives

```
c := piecewise(1, and(x), 0);     // should be and(true)
x = ;                             // a bvar that escaped; no such parameter exists
```

Reproduced with **libantimony v3.0.0** on the SBML Test Suite's own files,
`01486`, `01490` and `01491` (all `l3v2`, straight from the suite, unmodified).

**Which arguments are affected**, from substituting one at a time into the same
call site in 01490:

| argument | substituted? |
|---|---|
| `<cn>1</cn>`, `<ci>P1</ci>` | yes |
| `<infinity/>`, `<notanumber/>` | yes — come through as `INF` / `NaN` |
| **`<true/>`, `<false/>`, `<pi/>`, `<exponentiale/>`** | **no** |

Case 01486 shows both halves in a single call: `my_eq(P1, pi)` with
`lambda x, y . x == y` renders as `P1 == y` — the `<ci>` argument substituted
and the `<pi/>` did not.

**Why there is no workaround.** The damage is done during SBML *import*, before
any consumer can intervene: it appears with a plain `loadSBMLFile`, with no
round trip and no `setRemoveFunctionDefinitions` involved. The argument is
simply gone from every representation the library will hand back, so it cannot
be recovered from the Antimony rendering, from `getSBMLString`, or through the
C API. Loading the SBML directly does not help either — it is the same path.

The visible symptom for a consumer is §4's: an expression referring to a symbol
the model does not define. So these are not, as we first recorded them,
"synthetic cases that deliberately use undefined values" — they are ordinary
well-defined models, and the undefined symbol is an artefact of this bug.

**Requested:** substitute all MathML constants like any other argument. Failing
that, an error on import would be far better than silently dropping the
argument, since as it stands a model can be corrupted with no diagnostic at all.

**Written up for the developers as a standalone report:**
`libantimony-bug-mathml-constant-args.md`, with the minimal reproduction
`bvar_leak_min.xml` beside it. Send those two rather than this section — they
carry the self-contained repro, the SBML-in/SBML-out evidence and the
per-argument sweep.

---

## 5. `getSymbolAssignmentRulesOfType(rtAllSymbols)` returns kinetic laws

**Status: DOCUMENTED, not fixed, as of v3.2.0.** The header now carries a
`@warning` on `getSymbolAssignmentRulesOfType` describing exactly this and
recommending the six-symbol-class query. The behaviour is unchanged, so the
workaround stays.

Querying assignment rules with `rtAllSymbols` returns each reaction's **kinetic
law** in the assignment-rule slot. A consumer that asks "does this model use
assignment rules?" that way concludes that every ordinary reaction model does.

We work around it by querying only the six symbol classes that can actually
carry a rule (var/const × species, formulas, compartments). Worth either fixing
or documenting, since the natural first query is the one that misleads.

---

## Not requested

- **The `fast` attribute.** Deprecated, effectively unimplemented across tools.
