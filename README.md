# libAntimony Delphi Bindings

<table style="width:100%">
  <tr>
    <td><img alt="Language" src="https://img.shields.io/badge/Delphi-13%20%2F%20RAD%20Studio%2037.0-blue.svg"></td>
    <td><img alt="Platforms" src="https://img.shields.io/badge/Platforms-Win64%20%7C%20macOS%20ARM64-lightgrey"></td>
    <td><img alt="libantimony" src="https://img.shields.io/badge/libantimony-3.2.0-green"></td>
  </tr>
</table>

**Delphi (Object Pascal) bindings for [libantimony](https://github.com/sys-bio/antimony)** —
the library behind the [Antimony](https://tellurium.readthedocs.io/en/latest/antimony.html)
model description language, which converts between Antimony text and
[SBML](https://sbml.org/).

This repository is *bindings only*. It does not build libantimony and it contains no
simulation code — it loads the shared library at runtime and gives you the whole C API as
ordinary Delphi functions.

All **135** non-CellML entry points in `antimony_api.h` are bound and exercised.

---

## Quick start

Add the three units to your project and ship `libantimony.dll` (or `.dylib`) beside your
executable.

```pascal
uses
  uAntimonyTypes, uAntimonyAPI;

var
  errMsg: string;
  res: TModelErrorState;
begin
  if not loadAntimonyLibrary(errMsg) then
    raise Exception.Create(errMsg);
  try
    res := antimonyToSBML(
      'model example'                    + sLineBreak +
      '  S1 -> S2; k1*S1;'               + sLineBreak +
      '  S1 = 10; S2 = 0; k1 = 0.3;'     + sLineBreak +
      'end');

    if res.ok then
      Writeln(res.sbmlStr)
    else
      Writeln('failed: ', res.errMsg);
  finally
    freeAll;                  // see Memory, below -- this is not optional
    unloadAntimonyLibrary;
  end;
end;
```

Interrogating a model rather than converting it:

```pascal
var
  i: Integer;
  names, rates: TArray<string>;
begin
  loadString('S1 -> S2; k1*S1;  S1 = 10; k1 = 0.3;');
  try
    names := getReactionNames;
    rates := getReactionRates;
    for i := 0 to High(names) do
      Writeln(names[i], ':  ', rates[i]);

    for var s in getSymbolNamesOfType(rtAllSpecies) do
      Writeln(s, ' in ', getCompartmentForSymbol(s));
  finally
    freeAll;
  end;
end;
```

---

## The three units

They are deliberately layered, and you can stop at whichever level suits you.

| Unit | Role | Depends on |
|---|---|---|
| `uAntimonyTypes.pas` | C scalar aliases, the three enums, `TModelErrorState`, `EAntimonyError`. Touches no library. | — |
| `uAntimonyRaw.pas` | 1:1 mapping of the C API onto `cdecl` function pointers, plus the loader. No conveniences. | Types |
| `uAntimonyAPI.pas` | The Delphi-shaped layer: native strings, `TArray<>`, exceptions, main-module defaults. **Use this one.** | Types, Raw |

Most callers need only `uAntimonyAPI` (and `uAntimonyTypes` for `TReturnType` and
`TModelErrorState`). `uAntimonyRaw` is there for anything the friendly layer does not cover.

### What `uAntimonyAPI` covers

Library management and versioning · loading from file or string (Antimony, SBML, or
auto-detected) with `revertTo` history · writing Antimony, SBML and comp-SBML · errors,
warnings and validation · modules and their interfaces · symbol replacements · user-defined
functions · symbols of every return type, with equations, initial assignments, assignment
rules, rate rules and compartments · reactions, reactants, products, stoichiometries (numeric
*and* as-written) and rate laws · interactions · the stoichiometry matrix · events ·
DNA strands · translation settings · and the `antimonyToSBML` / `sbmlToAntimony` round trip.

---

## Things worth knowing before you use it

These are the sharp edges. Each one cost someone an afternoon.

### `freeAll` is not optional

Every pointer libantimony returns is `malloc`'d in the C runtime's heap and owned by the
caller. Delphi cannot safely free it, so **nothing is freed per call**. Instead the friendly
layer copies each result into a Delphi string or array immediately — which makes `freeAll`
safe to call at any point, and *necessary*, because the library leaks until you do. Call it
after a batch of queries.

### Strings are UTF-8

Text crosses the boundary as UTF-8 in both directions. SBML is XML and routinely carries
non-ASCII in names and notes; treating it as the Windows ANSI codepage mangles it. The
conversion happens inside the wrapper — you pass and receive ordinary Delphi strings.

### `moduleName` is last and defaults to the main module

The C API takes the module name first; here it is always the **last** parameter, defaulting
to `''` for the main module. So `getNumReactions()` asks about the main module and
`getNumReactions('sub')` about a named one.

The user-function accessors are the one exception — they take no module name at all, because
Antimony function definitions are not scoped to a module. That is the C API's shape, not ours.

### Never write a model file with a BOM

libantimony's parser treats a byte-order mark as ordinary input and rejects the file with

```
Unparseable content in line 1: unknown character '?' (an integer value of -17)
```

(-17 is 0xEF, the BOM's first byte) — a syntax error on a file that looks perfectly correct
in an editor. Write UTF-8 bytes directly:

```pascal
TFile.WriteAllBytes(path, TEncoding.UTF8.GetBytes(s));
```

Not `TFile.WriteAllText(..., TEncoding.UTF8)`, `TStringList.SaveToFile` or `TStreamWriter` —
all three emit the preamble.

### Failure reporting

Functions that can fail raise `EAntimonyError`, carrying `getLastError`. The two round-trip
helpers, `antimonyToSBML` and `sbmlToAntimony`, instead report through `TModelErrorState`
(`ok`, `errMsg`, `sbmlStr`) for callers that would rather branch than catch.

`antimonyToSBML` defaults to `strictWarnings := True`. libantimony can return a valid module
handle while still having written to the error buffer — a symbol used with no initial value,
say — and the SBML that results parses but will not simulate. By default that is reported as
a failure. Pass `False` to take the SBML anyway and read `getLastError` yourself.

### Platform width — why the old bindings were Windows-only

libantimony's API uses `long` and `unsigned long` throughout, and that type is **32-bit on
Windows (LLP64) but 64-bit on macOS and Linux (LP64)**. `uAntimonyTypes.TCLong` / `TCULong`
are the single place this is decided. Any new binding touching a count, index or load handle
must use those aliases, never `Integer` or `NativeInt` directly.

### The loader is best-effort, and says what it could not find

`loadAntimonyLibrary` looks beside the executable, then — on macOS — in the `.app` bundle's
`../Frameworks/`, then falls back to the bare name so the OS search path applies. It resolves
every entry point and, rather than aborting on the first miss, returns `False` with the full
list of names that failed.

That list is the diagnostic: **pairing these bindings with a pre-3.2 libantimony makes the
load fail**, because the 3.1/3.2 accessors are the reason for the update. Use the DLL in
`WinBinary/lib/`.

`getVersionStr` is the one tolerated absence — 3.2.0 exports it but earlier builds did not, so
it is optional and returns `''` when unavailable.

### CellML is deliberately not bound

`loadCellMLFile`, `loadCellMLString`, `writeCellMLFile` and `getCellMLString` are not exported
by the shipped library and are not bound. CellML support is not expected to work.

---

## Repository layout

```
uAntimonyTypes.pas               types and enums
uAntimonyRaw.pas                 raw cdecl bindings and the loader
uAntimonyAPI.pas                 the Delphi-shaped wrapper
libAntimony_Bindings_Project.dpr console smoke test
WinBinary/                       upstream Windows distribution (bin/ lib/ include/ bindings/)
MacBinary/                       placeholder for the macOS distribution -- currently empty
antimony-develop/                vendored upstream source, read-only reference
```

`antimony-develop/` is a copy of [sys-bio/antimony](https://github.com/sys-bio/antimony) kept
for reference — exported signatures, enum ordinals and ownership semantics. It is not built
here and should not be modified. The enums in `uAntimonyTypes` are *positional* transcriptions
of `antimony-develop/src/enums.h`; if upstream ever inserts a member mid-list, they silently
point at the wrong thing.

---

## Building and testing

Delphi 13 / RAD Studio (BDS) **37.0**, Win64 Debug by default:

```
"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && ^
  msbuild libAntimony_Bindings_Project.dproj /t:Build /p:Config=Debug /p:Platform=Win64
```

(`ProjectVersion` in the `.dproj` says 20.3 — stale metadata, ignore it.)

There is no unit-test framework. `Win64\Debug\libAntimony_Bindings_Project.exe` is the
verification harness: it loads three models and exercises one function from each section of
the API — symbols, reactions, the stoichiometry matrix, events, interactions, DNA strands,
submodule replacements, the SBML round trip, and the 3.1/3.2 accessors. It ends on `Readln`,
so when running it non-interactively, redirect stdout and kill it after a few seconds.

`libantimony.dll` and its MSVC runtimes (`msvcp140.dll`, `vcruntime140*.dll`, `concrt140.dll`)
must sit beside the executable.

To re-check exports after swapping in a new DLL:

```
tdump.exe -ee Win64\Debug\libantimony.dll
```

(`tdump` ships in the Delphi `bin` folder. Its output is CRLF, so strip `\r` before comparing
export names against the header.)

---

## Used by

[Iridium](https://github.com/sys-bio/IridiumSimulator) — an interactive desktop simulator for
systems biology — consumes these bindings as a source dependency.

---

## Credits

libantimony is developed by the [sys-bio](https://github.com/sys-bio) group; see
[sys-bio/antimony](https://github.com/sys-bio/antimony) for the library itself and its
licence.
