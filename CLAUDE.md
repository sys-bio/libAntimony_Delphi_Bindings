# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Delphi (Object Pascal) bindings for **libantimony**, plus a console smoke test. The goal is
complete coverage of the C API, working on both Windows and macOS. The library is loaded
dynamically at runtime; nothing here compiles libantimony itself.

`antimony-develop/` is a vendored source copy of upstream sys-bio/antimony (no `.git`, not
built here). Treat it as **read-only reference** — use it for exported signatures, enum
ordinals, and ownership semantics. Do not modify it unless asked.

Published as **https://github.com/sys-bio/libAntimony_Delphi_Bindings**, under the **MIT
licence** (`LICENSE`, © 2022 UW Sauro Lab). That covers the bindings only: libantimony itself,
and the vendored copy in `antimony-develop/`, carry upstream's own licence.

`README.md` is the user-facing document, and it restates several of the invariants recorded
below — `freeAll`, the UTF-8 boundary, `moduleName` coming last, the BOM bug, the platform
`long` width. **When one of those changes, change both.** A convention documented here but
contradicted in the README is worse than one documented nowhere, because the README is what a
caller actually reads.

`WinBinary/` holds the upstream Windows distribution (see below). **`MacBinary/` exists but is
empty** — the macOS `.dylib` is not vendored here, so a macOS build has to source it
separately.

## Build

Delphi 13 / RAD Studio (BDS) **37.0**, Win64 Debug by default:

```
cmd /c '"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" && msbuild libAntimony_Bindings_Project.dproj /t:Build /p:Config=Debug /p:Platform=Win64'
```

`ProjectVersion` in the `.dproj` says 20.3 — stale metadata, ignore it; 37.0 is correct.

## Run

`Win64\Debug\libAntimony_Bindings_Project.exe` loads three models and exercises one function from each
API section (symbols, reactions, stoichiometry matrix, events, interactions, DNA strands,
submodule replacements, the SBML round trip, and the 3.1/3.2 accessors — user functions,
stoichiometry-as-written, `substanceOnly`, `hasValue`). There is no unit-test framework; this
is the verification harness. It ends on `Readln`, so when running it non-interactively
redirect stdout and kill it after a few seconds.

**Never write a BOM.** Write UTF-8 bytes directly —
`TFile.WriteAllBytes(path, TEncoding.UTF8.GetBytes(s))` — rather than
`TFile.WriteAllText(..., TEncoding.UTF8)`, `TStringList.SaveToFile` or `TStreamWriter`, all of
which emit the encoding's preamble. libantimony's parser treats the BOM as ordinary input and
rejects the file with `Unparseable content in line 1: unknown character '?' (an integer value
of -17)` — 0xEF, the first BOM byte — which reads as a syntax error on a file that looks
perfectly correct in an editor.

`libantimony.dll` and its MSVC runtimes (`msvcp140.dll`, `vcruntime140*.dll`,
`concrt140.dll`) live beside the exe in `Win64\Debug\`.

## Architecture

Three units, deliberately layered:

| Unit | Role |
|---|---|
| `uAntimonyTypes.pas` | C scalar aliases, the three enums, `TModelErrorState`, `EAntimonyError`. No library access. |
| `uAntimonyRaw.pas` | 1:1 mapping of the C API onto `cdecl` function-pointer variables, plus the loader. No conveniences. |
| `uAntimonyAPI.pas` | Delphi-shaped layer: native strings, `TArray<>`, exceptions, main-module defaults. |

### Platform-width types — the reason the old bindings were Windows-only

libantimony's API uses `long` / `unsigned long` everywhere. That type is **32-bit on Windows
(LLP64) and 64-bit on macOS/Linux (LP64)**. `uAntimonyTypes.TCLong` / `TCULong` are the single
place this is decided. Any new binding that touches a count, index, or load handle must use
those aliases, never `Integer` or `NativeInt` directly.

`TCBool = ByteBool` for C++ `bool` (one byte under both MSVC and clang; `ByteBool` reads only
that byte, which matters because the upper return-register bits aren't guaranteed clear).

### Taking the address of a procedural variable

Binding uses `Bind(@@ant_loadFile, 'loadFile')` — **two** `@`. For a procedural variable `P`,
`@P` yields the *value* stored in P; `@@P` yields the address of the variable. Writing `@P`
compiles fine and then writes through a nil pointer at load time. This bit once already.

### Loader behaviour

`loadAntimonyLibrary` tries, in order: beside the executable, then (macOS only)
`../Frameworks/` for `.app` bundles, then the bare name so the OS search path applies. It
resolves all entry points best-effort and returns False with the full list of names that
failed, rather than aborting on the first one. Names in `OptionalProcs` are permitted to stay
nil and must be `Assigned`-checked at the call site.

The shipped DLL is **libantimony v3.2.0** (`getVersionStr` reports it). All **135** non-CellML
functions in the header are exported and bound. The four CellML entry points
(`loadCellMLFile`, `loadCellMLString`, `writeCellMLFile`, `getCellMLString`) are not exported
and are deliberately not bound — CellML support is not expected to work.

`getVersionStr` *is* exported by 3.2.0, but earlier builds did not export it, so it stays in
`OptionalProcs` and `uAntimonyAPI.getVersionStr` returns `''` when unavailable. Everything
else is required: pairing these bindings with a pre-3.2 DLL makes `loadAntimonyLibrary` fail
with the list of missing names, which is the intended outcome — the accessors added in 3.1/3.2
are the reason for the update.

To re-check exports after swapping in a new DLL:
`tdump.exe -ee Win64\Debug\libantimony.dll` (tdump ships in the Delphi `bin` folder). Note its
output is CRLF, so strip `\r` before comparing export names against the header.

`WinBinary/` is the upstream Windows distribution the current DLL came from: `WinBinary/lib/` holds
`libantimony.dll` and `WinBinary/include/` the matching headers, which agree exactly with
`antimony-develop/src/antimony_api.h.in`.

### Enum ordinals

`TReturnType`, `TFormulaType` and `TReactionDivider` are positional transcriptions of
`enum return_type`, `formula_type` and `rd_type` in `antimony-develop/src/enums.h`. If
upstream inserts a member mid-list these silently point at the wrong thing. `{$MINENUMSIZE 4}`
is required around them so they're passed as C `int`.

### API conventions in `uAntimonyAPI`

- **moduleName is always the last parameter and defaults to `''`**, meaning the main module.
  So `getNumReactions()` asks about the main module, `getNumReactions('sub')` about a named
  one. This is the opposite of the C order — worth remembering when adding functions.
  The **user-function accessors are the one exception**: `getNumUserFunctions`,
  `getNthUserFunctionName/Arguments/Body` take no moduleName at all, because Antimony
  function definitions are not scoped to a module. That is the C API's shape, not ours.
- Strings cross the boundary as **UTF-8**, via `UTF8String` (not `RawByteString`, so the
  codepage is explicit and the conversion is a real decode). SBML carries non-ASCII in names
  and notes; the ANSI codepage mangles it.
- `ModName` returns a `PAnsiChar` backed by a `UTF8String` the *caller* must hold in a local
  — hence the `mb: UTF8String` local in nearly every wrapper. Don't collapse those away.
- Failures raise `EAntimonyError` carrying `getLastError`. The exceptions are `antimonyToSBML`
  and `sbmlToAntimony`, which report through `TModelErrorState`.

### Counted arrays

Every `char**` / `double**` / `char***` the library returns carries no length. The count comes
from a companion call, and the pairing is not always obvious:

| Data | Length source |
|---|---|
| `getSymbol*OfType` | `getNumSymbolsOfType` with the *same* rtype |
| `getReactantNames` (jagged) | `getNumReactions` rows, `getNumReactants(rxn)` per row |
| `getStoichiometryMatrix` | `getStoichiometryMatrixNumRows` × `...NumColumns` |
| `getDNAStrands` | `getNumDNAStrands` rows, `getDNAStrandSizes` per row |
| `getModularDNAStrands` | `getModularDNAStrandSizes` — there is **no** `getSizeOfNthModularDNAStrand` |
| `getAllReplacementSymbolPairs` | `getNumReplacedSymbolNames` rows, always 2 per row |
| `getReactionNames` | `getNumReactions` |
| `getNthUserFunctionArguments(n)` | `getNumUserFunctionArguments(n)` — same `n` |

Any new `char**`-returning binding needs the same paired count call.

### Memory

Every pointer libantimony returns is `malloc`'d in the MSVC heap and owned by the caller.
Delphi cannot safely free it, so **nothing is freed per call**. The friendly layer copies each
result into a Delphi string or array immediately, which makes `freeAll` safe to call at any
point — and necessary, because the library leaks until you do.
