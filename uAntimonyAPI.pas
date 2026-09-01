unit uAntimonyAPI;

{ A Delphi-shaped wrapper over the raw libantimony bindings in uAntimonyRaw.

  Conventions used throughout:

  * Strings are native Delphi strings. Text crossing the boundary is encoded
    and decoded as UTF-8, because SBML is XML and model notes routinely carry
    non-ASCII characters. (Treating it as the Windows ANSI codepage mangles
    them.)

  * Wherever the C API takes a moduleName, it appears here as the LAST
    parameter and defaults to '' meaning "the main module". So
    getNumReactions() asks about the main module and
    getNumReactions('submod') asks about a named one.

  * Counts and indices are Integer. The C API's unsigned long width differs
    per platform; uAntimonyTypes.TCULong handles that and the conversion
    happens here.

  * Functions that can fail raise EAntimonyError. The two round-trip helpers
    antimonyToSBML and sbmlToAntimony instead return a TModelErrorState for
    callers that would rather branch than catch.

  * Nothing is freed per call. Every pointer libantimony hands back is copied
    into a Delphi string or array immediately, so calling freeAll at any point
    afterwards is safe -- and necessary, since the library leaks otherwise. }

interface

uses
  System.SysUtils,
  uAntimonyTypes,
  uAntimonyRaw;

{ ---------------------------------------------------------------------------
  Library management
  --------------------------------------------------------------------------- }

{ Loads libantimony.dll / .dylib / .so and resolves all entry points. Looks
  beside the executable first, then (on macOS) in the .app bundle's
  Frameworks folder, then lets the OS search. }
function loadAntimonyLibrary(out errMsg: string): Boolean;
procedure unloadAntimonyLibrary;
function antimonyLibraryLoaded: Boolean;

{ Releases every pointer the library has handed out since it was loaded. All
  results from this unit are already copies, so this is always safe to call. }
procedure freeAll;

{ Not exported by every build; returns '' when unavailable. }
function getVersionStr: string;

{ ---------------------------------------------------------------------------
  Input.  All raise EAntimonyError (carrying getLastError) on failure.
  The result is the index of the load, for use with revertTo.
  --------------------------------------------------------------------------- }

function loadFile(const filename: string): Integer;
function loadString(const model: string): Integer;
function loadAntimonyFile(const filename: string): Integer;
function loadAntimonyString(const model: string): Integer;
function loadSBMLFile(const filename: string): Integer;
function loadSBMLString(const model: string): Integer;
function loadSBMLStringWithLocation(const model, location: string): Integer;

function getNumFiles: Integer;
function revertTo(index: Integer): Boolean;
procedure clearPreviousLoads;
procedure addDirectory(const directory: string);
procedure clearDirectories;

{ ---------------------------------------------------------------------------
  Output
  --------------------------------------------------------------------------- }

function writeAntimonyFile(const filename: string; const moduleName: string = ''): Boolean;
function getAntimonyString(const moduleName: string = ''): string;
function writeSBMLFile(const filename: string; const moduleName: string = ''): Boolean;
function getSBMLString(const moduleName: string = ''): string;
function writeCompSBMLFile(const filename: string; const moduleName: string = ''): Boolean;
function getCompSBMLString(const moduleName: string = ''): string;
function printAllDataFor(const moduleName: string = ''): string;

{ ---------------------------------------------------------------------------
  Errors, warnings, validation
  --------------------------------------------------------------------------- }

function checkModule(const moduleName: string = ''): Boolean;
function getLastError: string;
function getWarnings: string;
function getSBMLInfoMessages(const moduleName: string = ''): string;
function getSBMLWarnings(const moduleName: string = ''): string;

{ ---------------------------------------------------------------------------
  Modules
  --------------------------------------------------------------------------- }

function getNumModules: Integer;
function getModuleNames: TArray<string>;
function getNthModuleName(n: Integer): string;
function getMainModuleName: string;

function getNumSymbolsInInterfaceOf(const moduleName: string = ''): Integer;
function getSymbolNamesInInterfaceOf(const moduleName: string = ''): TArray<string>;
function getNthSymbolNameInInterfaceOf(n: Integer; const moduleName: string = ''): string;

{ ---------------------------------------------------------------------------
  Replacements (symbols synchronised via 'is' or a module interface)
  --------------------------------------------------------------------------- }

function getNumReplacedSymbolNames(const moduleName: string = ''): Integer;
{ Each inner array is a [former, replacement] pair. }
function getAllReplacementSymbolPairs(const moduleName: string = ''): TStringGrid2D;
function getNthReplacementSymbolPair(n: Integer; const moduleName: string = ''): TArray<string>;
function getNthFormerSymbolName(n: Integer; const moduleName: string = ''): string;
function getNthReplacementSymbolName(n: Integer; const moduleName: string = ''): string;

function getNumReplacedSymbolNamesBetween(const formerSubmodName,
  replacementSubmodName: string; const moduleName: string = ''): Integer;
function getAllReplacementSymbolPairsBetween(const formerSubmodName,
  replacementSubmodName: string; const moduleName: string = ''): TStringGrid2D;
function getNthReplacementSymbolPairBetween(const formerSubmodName,
  replacementSubmodName: string; n: Integer; const moduleName: string = ''): TArray<string>;
function getNthFormerSymbolNameBetween(const formerSubmodName,
  replacementSubmodName: string; n: Integer; const moduleName: string = ''): string;
function getNthReplacementSymbolNameBetween(const formerSubmodName,
  replacementSubmodName: string; n: Integer; const moduleName: string = ''): string;

{ ---------------------------------------------------------------------------
  User-defined functions ('function f(...) ... end').

  These are the one part of the API with no moduleName parameter: Antimony
  function definitions are not scoped to a module, so they are queried across
  the whole active set.
  --------------------------------------------------------------------------- }

function getNumUserFunctions: Integer;
function getNthUserFunctionName(n: Integer): string;
function getNumUserFunctionArguments(n: Integer): Integer;
function getNthUserFunctionArguments(n: Integer): TArray<string>;
{ The body as a formula over the function's arguments. }
function getNthUserFunctionBody(n: Integer): string;

{ ---------------------------------------------------------------------------
  Symbols
  --------------------------------------------------------------------------- }

function getNumSymbolsOfType(rtype: TReturnType; const moduleName: string = ''): Integer;
function getSymbolNamesOfType(rtype: TReturnType; const moduleName: string = ''): TArray<string>;
function getSymbolDisplayNamesOfType(rtype: TReturnType; const moduleName: string = ''): TArray<string>;
function getSymbolEquationsOfType(rtype: TReturnType; const moduleName: string = ''): TArray<string>;
function getSymbolInitialAssignmentsOfType(rtype: TReturnType; const moduleName: string = ''): TArray<string>;
function getSymbolAssignmentRulesOfType(rtype: TReturnType; const moduleName: string = ''): TArray<string>;
function getSymbolRateRulesOfType(rtype: TReturnType; const moduleName: string = ''): TArray<string>;
function getSymbolCompartmentsOfType(rtype: TReturnType; const moduleName: string = ''): TArray<string>;

function getNthSymbolNameOfType(rtype: TReturnType; n: Integer; const moduleName: string = ''): string;
function getNthSymbolDisplayNameOfType(rtype: TReturnType; n: Integer; const moduleName: string = ''): string;
function getNthSymbolEquationOfType(rtype: TReturnType; n: Integer; const moduleName: string = ''): string;
function getNthSymbolInitialAssignmentOfType(rtype: TReturnType; n: Integer; const moduleName: string = ''): string;
function getNthSymbolAssignmentRuleOfType(rtype: TReturnType; n: Integer; const moduleName: string = ''): string;
function getNthSymbolRateRuleOfType(rtype: TReturnType; n: Integer; const moduleName: string = ''): string;
function getNthSymbolCompartmentOfType(rtype: TReturnType; n: Integer; const moduleName: string = ''): string;

function getTypeOfSymbol(const symbolName: string; const moduleName: string = ''): TReturnType;
function getTypeOfEquationForSymbol(const symbolName: string; const moduleName: string = ''): TFormulaType;
function getCompartmentForSymbol(const symbolName: string; const moduleName: string = ''): string;

{ True if the symbol was declared 'substanceOnly', i.e. its value is an amount
  rather than a concentration. Ignoring this is a silent factor-of-volume error
  in the species' trajectory whenever the compartment size is not 1. }
function getSymbolSubstanceOnly(const symbolName: string; const moduleName: string = ''): Boolean;

{ False when the symbol was declared with no value at all -- an SBML parameter
  with no 'value', a compartment with no 'size'. This is the only way to tell
  that case apart from a value of zero, since both leave the equation empty. }
function getSymbolHasValue(const symbolName: string; const moduleName: string = ''): Boolean;

{ ---------------------------------------------------------------------------
  Reactions
  --------------------------------------------------------------------------- }

function getNumReactions(const moduleName: string = ''): Integer;
function getReactionNames(const moduleName: string = ''): TArray<string>;
function getNthReactionName(rxn: Integer; const moduleName: string = ''): string;
function getNumReactants(rxn: Integer; const moduleName: string = ''): Integer;
function getNumProducts(rxn: Integer; const moduleName: string = ''): Integer;

{ Outer index is the reaction, inner index the reactant/product. }
function getReactantNames(const moduleName: string = ''): TStringGrid2D;
function getProductNames(const moduleName: string = ''): TStringGrid2D;
function getNthReactionReactantNames(rxn: Integer; const moduleName: string = ''): TArray<string>;
function getNthReactionProductNames(rxn: Integer; const moduleName: string = ''): TArray<string>;
function getNthReactionMthReactantName(rxn, reactant: Integer; const moduleName: string = ''): string;
function getNthReactionMthProductName(rxn, product: Integer; const moduleName: string = ''): string;

function getReactantStoichiometries(const moduleName: string = ''): TDoubleGrid2D;
function getProductStoichiometries(const moduleName: string = ''): TDoubleGrid2D;
function getNthReactionReactantStoichiometries(rxn: Integer; const moduleName: string = ''): TArray<Double>;
function getNthReactionProductStoichiometries(rxn: Integer; const moduleName: string = ''): TArray<Double>;
function getNthReactionMthReactantStoichiometry(rxn, reactant: Integer; const moduleName: string = ''): Double;
function getNthReactionMthProductStoichiometry(rxn, product: Integer; const moduleName: string = ''): Double;

{ The stoichiometry as it was written. The two functions above return NaN when
  a stoichiometry was given as a symbol ('S1 + n S2 => S3; n = 2*p1'); these
  return the symbol's name, whose value can then be looked up like any other.
  A stoichiometry written as a plain number comes back as that number's text. }
function getNthReactionMthReactantStoichiometryString(rxn, reactant: Integer; const moduleName: string = ''): string;
function getNthReactionMthProductStoichiometryString(rxn, product: Integer; const moduleName: string = ''): string;

function getNumReactionRates(const moduleName: string = ''): Integer;
function getReactionRates(const moduleName: string = ''): TArray<string>;
function getNthReactionRate(rxn: Integer; const moduleName: string = ''): string;

{ ---------------------------------------------------------------------------
  Interactions
  --------------------------------------------------------------------------- }

function getNumInteractions(const moduleName: string = ''): Integer;
function getNumInteractors(interaction: Integer; const moduleName: string = ''): Integer;
function getNumInteractees(interaction: Integer; const moduleName: string = ''): Integer;

function getInteractorNames(const moduleName: string = ''): TStringGrid2D;
function getInteracteeNames(const moduleName: string = ''): TStringGrid2D;
function getNthInteractionInteractorNames(interaction: Integer; const moduleName: string = ''): TArray<string>;
function getNthInteractionInteracteeNames(interaction: Integer; const moduleName: string = ''): TArray<string>;
function getNthInteractionMthInteractorName(interaction, interactor: Integer; const moduleName: string = ''): string;
function getNthInteractionMthInteracteeName(interaction, interactee: Integer; const moduleName: string = ''): string;

function getInteractionDividers(const moduleName: string = ''): TArray<TReactionDivider>;
function getNthInteractionDivider(n: Integer; const moduleName: string = ''): TReactionDivider;

{ ---------------------------------------------------------------------------
  Stoichiometry matrix.  Rows are variable species, columns are reactions.
  --------------------------------------------------------------------------- }

function getStoichiometryMatrixNumRows(const moduleName: string = ''): Integer;
function getStoichiometryMatrixNumColumns(const moduleName: string = ''): Integer;
function getStoichiometryMatrix(const moduleName: string = ''): TDoubleGrid2D;
function getStoichiometryMatrixRowLabels(const moduleName: string = ''): TArray<string>;
function getStoichiometryMatrixColumnLabels(const moduleName: string = ''): TArray<string>;

{ ---------------------------------------------------------------------------
  Events
  --------------------------------------------------------------------------- }

function getNumEvents(const moduleName: string = ''): Integer;
function getEventNames(const moduleName: string = ''): TArray<string>;
function getNthEventName(event: Integer; const moduleName: string = ''): string;
function getNumAssignmentsForEvent(event: Integer; const moduleName: string = ''): Integer;
function getTriggerForEvent(event: Integer; const moduleName: string = ''): string;
function getDelayForEvent(event: Integer; const moduleName: string = ''): string;
function getEventHasDelay(event: Integer; const moduleName: string = ''): Boolean;
function getPriorityForEvent(event: Integer; const moduleName: string = ''): string;
function getEventHasPriority(event: Integer; const moduleName: string = ''): Boolean;
function getPersistenceForEvent(event: Integer; const moduleName: string = ''): Boolean;
function getT0ForEvent(event: Integer; const moduleName: string = ''): Boolean;
function getFromTriggerForEvent(event: Integer; const moduleName: string = ''): Boolean;
function getNthAssignmentVariableForEvent(event, n: Integer; const moduleName: string = ''): string;
function getNthAssignmentEquationForEvent(event, n: Integer; const moduleName: string = ''): string;

{ ---------------------------------------------------------------------------
  DNA strands
  --------------------------------------------------------------------------- }

function getNumDNAStrands(const moduleName: string = ''): Integer;
function getDNAStrandSizes(const moduleName: string = ''): TArray<Integer>;
function getSizeOfNthDNAStrand(n: Integer; const moduleName: string = ''): Integer;
function getDNAStrands(const moduleName: string = ''): TStringGrid2D;
function getNthDNAStrand(n: Integer; const moduleName: string = ''): TArray<string>;
function getIsNthDNAStrandOpen(n: Integer; upstream: Boolean; const moduleName: string = ''): Boolean;

function getNumModularDNAStrands(const moduleName: string = ''): Integer;
function getModularDNAStrandSizes(const moduleName: string = ''): TArray<Integer>;
function getModularDNAStrands(const moduleName: string = ''): TStringGrid2D;
function getNthModularDNAStrand(n: Integer; const moduleName: string = ''): TArray<string>;
function getIsNthModularDNAStrandOpen(n: Integer; upstream: Boolean; const moduleName: string = ''): Boolean;

{ ---------------------------------------------------------------------------
  Translation settings.  These are global and persist across loads.
  --------------------------------------------------------------------------- }

procedure setRemoveFunctionDefinitions(removeFunctionDefinitions: Boolean);
procedure setWriteSBMLTimestamp(writeTimestamp: Boolean);
procedure setBareNumbersAreDimensionless(dimensionless: Boolean);
function addDefaultInitialValues(const moduleName: string = ''): Boolean;

{ ---------------------------------------------------------------------------
  Round-trip convenience.  These do not raise; they report through the record.
  --------------------------------------------------------------------------- }

{ Parses Antimony text and returns the flattened SBML for its main module.

  strictWarnings: libantimony can return a valid module handle while still
  having written to the error buffer -- for instance when a symbol is used
  without an initial value. That produces SBML which parses but will not
  simulate, so by default it is reported as a failure. Pass False to accept
  the SBML anyway and read getLastError yourself. }
function antimonyToSBML(const antimonyText: string;
  strictWarnings: Boolean = True): TModelErrorState;

{ Parses SBML and returns the equivalent Antimony text. On success the result's
  sbmlStr field holds the Antimony (the field name is kept for compatibility
  with existing callers). }
function sbmlToAntimony(const sbmlText: string): TModelErrorState;

implementation

uses
  System.AnsiStrings;

{ ---------------------------------------------------------------------------
  Marshalling helpers
  --------------------------------------------------------------------------- }

procedure CheckLoaded;
begin
  if not uAntimonyRaw.antimonyLibraryLoaded then
    raise EAntimonyError.Create
      ('The antimony library has not been loaded; call loadAntimonyLibrary first.');
end;

{ libantimony emits UTF-8. Decoding as UTF-8 rather than the ANSI codepage
  matters for model names and notes carried over from SBML. Going via
  UTF8String rather than RawByteString keeps the codepage explicit, so the
  conversion to string is a real decode and not a codepage-0 guess. }
function AntStr(P: PAnsiChar): string;
var
  u: UTF8String;
  n: Integer;
begin
  if P = nil then
    Exit('');
  n := System.AnsiStrings.StrLen(P);
  if n = 0 then
    Exit('');
  SetString(u, P, n);
  Result := string(u);
end;

function ToUtf8(const S: string): UTF8String;
begin
  Result := UTF8String(S);
end;

{ Resolves the module-name argument. An empty name means the main module, for
  which the library's own pointer is passed straight through. Buf must be a
  local of the caller so the encoded copy outlives the call. }
function ModName(const moduleName: string; var Buf: UTF8String): PAnsiChar;
begin
  CheckLoaded;
  if moduleName = '' then
    Result := ant_getMainModuleName
  else
    begin
    Buf := ToUtf8(moduleName);
    Result := PAnsiChar(Buf);
    end;
end;

function StrArray(P: PPAnsiChar; Count: Integer): TArray<string>;
var
  i: Integer;
begin
  if (P = nil) or (Count <= 0) then
    Exit(nil);
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
    Result[i] := AntStr(PPAnsiCharArray(P)^[i]);
end;

function StrGrid(P: PPPAnsiChar; const RowCounts: TArray<Integer>): TStringGrid2D;
var
  i: Integer;
begin
  if P = nil then
    Exit(nil);
  SetLength(Result, Length(RowCounts));
  for i := 0 to High(RowCounts) do
    Result[i] := StrArray(PPPAnsiCharArray(P)^[i], RowCounts[i]);
end;

function DblArray(P: PCDouble; Count: Integer): TArray<Double>;
var
  i: Integer;
begin
  if (P = nil) or (Count <= 0) then
    Exit(nil);
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
    Result[i] := PDoubleArray(P)^[i];
end;

function DblGrid(P: PPCDouble; const RowCounts: TArray<Integer>): TDoubleGrid2D;
var
  i: Integer;
begin
  if P = nil then
    Exit(nil);
  SetLength(Result, Length(RowCounts));
  for i := 0 to High(RowCounts) do
    Result[i] := DblArray(PPDoubleArray(P)^[i], RowCounts[i]);
end;

{ Raises with whatever the library last recorded. }
procedure RaiseLastError(const context: string);
var
  msg: string;
begin
  msg := AntStr(ant_getLastError);
  if msg = '' then
    msg := 'unknown error';
  raise EAntimonyError.Create(context + ': ' + msg);
end;

function CheckLoad(rc: TCLong; const context: string): Integer;
begin
  if rc = -1 then
    RaiseLastError(context);
  Result := Integer(rc);
end;

{ ---------------------------------------------------------------------------
  Library management
  --------------------------------------------------------------------------- }

function loadAntimonyLibrary(out errMsg: string): Boolean;
begin
  Result := uAntimonyRaw.loadAntimonyLibrary(errMsg);
end;

procedure unloadAntimonyLibrary;
begin
  uAntimonyRaw.unloadAntimonyLibrary;
end;

function antimonyLibraryLoaded: Boolean;
begin
  Result := uAntimonyRaw.antimonyLibraryLoaded;
end;

procedure freeAll;
begin
  CheckLoaded;
  ant_freeAll;
end;

function getVersionStr: string;
begin
  CheckLoaded;
  if not Assigned(ant_getVersionStr) then
    Exit('');
  Result := AntStr(ant_getVersionStr);
end;

{ ---------------------------------------------------------------------------
  Input
  --------------------------------------------------------------------------- }

function loadFile(const filename: string): Integer;
begin
  CheckLoaded;
  Result := CheckLoad(ant_loadFile(PAnsiChar(ToUtf8(filename))),
    Format('Unable to load "%s"', [filename]));
end;

function loadString(const model: string): Integer;
begin
  CheckLoaded;
  Result := CheckLoad(ant_loadString(PAnsiChar(ToUtf8(model))),
    'Unable to load model string');
end;

function loadAntimonyFile(const filename: string): Integer;
begin
  CheckLoaded;
  Result := CheckLoad(ant_loadAntimonyFile(PAnsiChar(ToUtf8(filename))),
    Format('Unable to load Antimony file "%s"', [filename]));
end;

function loadAntimonyString(const model: string): Integer;
begin
  CheckLoaded;
  Result := CheckLoad(ant_loadAntimonyString(PAnsiChar(ToUtf8(model))),
    'Unable to load Antimony string');
end;

function loadSBMLFile(const filename: string): Integer;
begin
  CheckLoaded;
  Result := CheckLoad(ant_loadSBMLFile(PAnsiChar(ToUtf8(filename))),
    Format('Unable to load SBML file "%s"', [filename]));
end;

function loadSBMLString(const model: string): Integer;
begin
  CheckLoaded;
  Result := CheckLoad(ant_loadSBMLString(PAnsiChar(ToUtf8(model))),
    'Unable to load SBML string');
end;

function loadSBMLStringWithLocation(const model, location: string): Integer;
var
  m, l: UTF8String;
begin
  CheckLoaded;
  m := ToUtf8(model);
  l := ToUtf8(location);
  Result := CheckLoad(ant_loadSBMLStringWithLocation(PAnsiChar(m), PAnsiChar(l)),
    'Unable to load SBML string');
end;

function getNumFiles: Integer;
begin
  CheckLoaded;
  Result := Integer(ant_getNumFiles);
end;

function revertTo(index: Integer): Boolean;
begin
  CheckLoaded;
  Result := Boolean(ant_revertTo(index));
end;

procedure clearPreviousLoads;
begin
  CheckLoaded;
  ant_clearPreviousLoads;
end;

procedure addDirectory(const directory: string);
begin
  CheckLoaded;
  ant_addDirectory(PAnsiChar(ToUtf8(directory)));
end;

procedure clearDirectories;
begin
  CheckLoaded;
  ant_clearDirectories;
end;

{ ---------------------------------------------------------------------------
  Output
  --------------------------------------------------------------------------- }

function writeAntimonyFile(const filename, moduleName: string): Boolean;
var
  mb, fb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  fb := ToUtf8(filename);
  Result := ant_writeAntimonyFile(PAnsiChar(fb), p) <> 0;
end;

function getAntimonyString(const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getAntimonyString(ModName(moduleName, mb)));
end;

function writeSBMLFile(const filename, moduleName: string): Boolean;
var
  mb, fb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  fb := ToUtf8(filename);
  Result := ant_writeSBMLFile(PAnsiChar(fb), p) <> 0;
end;

function getSBMLString(const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getSBMLString(ModName(moduleName, mb)));
end;

function writeCompSBMLFile(const filename, moduleName: string): Boolean;
var
  mb, fb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  fb := ToUtf8(filename);
  Result := ant_writeCompSBMLFile(PAnsiChar(fb), p) <> 0;
end;

function getCompSBMLString(const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getCompSBMLString(ModName(moduleName, mb)));
end;

function printAllDataFor(const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_printAllDataFor(ModName(moduleName, mb)));
end;

{ ---------------------------------------------------------------------------
  Errors, warnings, validation
  --------------------------------------------------------------------------- }

function checkModule(const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_checkModule(ModName(moduleName, mb)));
end;

function getLastError: string;
begin
  CheckLoaded;
  Result := AntStr(ant_getLastError);
end;

function getWarnings: string;
begin
  CheckLoaded;
  Result := AntStr(ant_getWarnings);
end;

function getSBMLInfoMessages(const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getSBMLInfoMessages(ModName(moduleName, mb)));
end;

function getSBMLWarnings(const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getSBMLWarnings(ModName(moduleName, mb)));
end;

{ ---------------------------------------------------------------------------
  Modules
  --------------------------------------------------------------------------- }

function getNumModules: Integer;
begin
  CheckLoaded;
  Result := Integer(ant_getNumModules);
end;

function getModuleNames: TArray<string>;
begin
  CheckLoaded;
  Result := StrArray(ant_getModuleNames, Integer(ant_getNumModules));
end;

function getNthModuleName(n: Integer): string;
begin
  CheckLoaded;
  Result := AntStr(ant_getNthModuleName(n));
end;

function getMainModuleName: string;
begin
  CheckLoaded;
  Result := AntStr(ant_getMainModuleName);
end;

function getNumSymbolsInInterfaceOf(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumSymbolsInInterfaceOf(ModName(moduleName, mb)));
end;

function getSymbolNamesInInterfaceOf(const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getSymbolNamesInInterfaceOf(p),
    Integer(ant_getNumSymbolsInInterfaceOf(p)));
end;

function getNthSymbolNameInInterfaceOf(n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthSymbolNameInInterfaceOf(ModName(moduleName, mb), n));
end;

{ ---------------------------------------------------------------------------
  Replacements
  --------------------------------------------------------------------------- }

{ Every replacement row is a fixed [former, replacement] pair. }
function PairCounts(Count: Integer): TArray<Integer>;
var
  i: Integer;
begin
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
    Result[i] := 2;
end;

function getNumReplacedSymbolNames(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumReplacedSymbolNames(ModName(moduleName, mb)));
end;

function getAllReplacementSymbolPairs(const moduleName: string): TStringGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrGrid(ant_getAllReplacementSymbolPairs(p),
    PairCounts(Integer(ant_getNumReplacedSymbolNames(p))));
end;

function getNthReplacementSymbolPair(n: Integer; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
begin
  Result := StrArray(ant_getNthReplacementSymbolPair(ModName(moduleName, mb), n), 2);
end;

function getNthFormerSymbolName(n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthFormerSymbolName(ModName(moduleName, mb), n));
end;

function getNthReplacementSymbolName(n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthReplacementSymbolName(ModName(moduleName, mb), n));
end;

function getNumReplacedSymbolNamesBetween(const formerSubmodName,
  replacementSubmodName, moduleName: string): Integer;
var
  mb, fb, rb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  fb := ToUtf8(formerSubmodName);
  rb := ToUtf8(replacementSubmodName);
  Result := Integer(ant_getNumReplacedSymbolNamesBetween(p, PAnsiChar(fb), PAnsiChar(rb)));
end;

function getAllReplacementSymbolPairsBetween(const formerSubmodName,
  replacementSubmodName, moduleName: string): TStringGrid2D;
var
  mb, fb, rb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  fb := ToUtf8(formerSubmodName);
  rb := ToUtf8(replacementSubmodName);
  Result := StrGrid(ant_getAllReplacementSymbolPairsBetween(p, PAnsiChar(fb), PAnsiChar(rb)),
    PairCounts(Integer(ant_getNumReplacedSymbolNamesBetween(p, PAnsiChar(fb), PAnsiChar(rb)))));
end;

function getNthReplacementSymbolPairBetween(const formerSubmodName,
  replacementSubmodName: string; n: Integer; const moduleName: string): TArray<string>;
var
  mb, fb, rb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  fb := ToUtf8(formerSubmodName);
  rb := ToUtf8(replacementSubmodName);
  Result := StrArray(ant_getNthReplacementSymbolPairBetween(p, PAnsiChar(fb), PAnsiChar(rb), n), 2);
end;

function getNthFormerSymbolNameBetween(const formerSubmodName,
  replacementSubmodName: string; n: Integer; const moduleName: string): string;
var
  mb, fb, rb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  fb := ToUtf8(formerSubmodName);
  rb := ToUtf8(replacementSubmodName);
  Result := AntStr(ant_getNthFormerSymbolNameBetween(p, PAnsiChar(fb), PAnsiChar(rb), n));
end;

function getNthReplacementSymbolNameBetween(const formerSubmodName,
  replacementSubmodName: string; n: Integer; const moduleName: string): string;
var
  mb, fb, rb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  fb := ToUtf8(formerSubmodName);
  rb := ToUtf8(replacementSubmodName);
  Result := AntStr(ant_getNthReplacementSymbolNameBetween(p, PAnsiChar(fb), PAnsiChar(rb), n));
end;

{ ---------------------------------------------------------------------------
  User-defined functions
  --------------------------------------------------------------------------- }

function getNumUserFunctions: Integer;
begin
  CheckLoaded;
  Result := Integer(ant_getNumUserFunctions);
end;

function getNthUserFunctionName(n: Integer): string;
begin
  CheckLoaded;
  Result := AntStr(ant_getNthUserFunctionName(n));
end;

function getNumUserFunctionArguments(n: Integer): Integer;
begin
  CheckLoaded;
  Result := Integer(ant_getNumUserFunctionArguments(n));
end;

function getNthUserFunctionArguments(n: Integer): TArray<string>;
begin
  CheckLoaded;
  Result := StrArray(ant_getNthUserFunctionArguments(n),
    Integer(ant_getNumUserFunctionArguments(n)));
end;

function getNthUserFunctionBody(n: Integer): string;
begin
  CheckLoaded;
  Result := AntStr(ant_getNthUserFunctionBody(n));
end;

{ ---------------------------------------------------------------------------
  Symbols
  --------------------------------------------------------------------------- }

function getNumSymbolsOfType(rtype: TReturnType; const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumSymbolsOfType(ModName(moduleName, mb), rtype));
end;

function getSymbolNamesOfType(rtype: TReturnType; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getSymbolNamesOfType(p, rtype),
    Integer(ant_getNumSymbolsOfType(p, rtype)));
end;

function getSymbolDisplayNamesOfType(rtype: TReturnType; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getSymbolDisplayNamesOfType(p, rtype),
    Integer(ant_getNumSymbolsOfType(p, rtype)));
end;

function getSymbolEquationsOfType(rtype: TReturnType; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getSymbolEquationsOfType(p, rtype),
    Integer(ant_getNumSymbolsOfType(p, rtype)));
end;

function getSymbolInitialAssignmentsOfType(rtype: TReturnType; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getSymbolInitialAssignmentsOfType(p, rtype),
    Integer(ant_getNumSymbolsOfType(p, rtype)));
end;

function getSymbolAssignmentRulesOfType(rtype: TReturnType; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getSymbolAssignmentRulesOfType(p, rtype),
    Integer(ant_getNumSymbolsOfType(p, rtype)));
end;

function getSymbolRateRulesOfType(rtype: TReturnType; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getSymbolRateRulesOfType(p, rtype),
    Integer(ant_getNumSymbolsOfType(p, rtype)));
end;

function getSymbolCompartmentsOfType(rtype: TReturnType; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getSymbolCompartmentsOfType(p, rtype),
    Integer(ant_getNumSymbolsOfType(p, rtype)));
end;

function getNthSymbolNameOfType(rtype: TReturnType; n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthSymbolNameOfType(ModName(moduleName, mb), rtype, n));
end;

function getNthSymbolDisplayNameOfType(rtype: TReturnType; n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthSymbolDisplayNameOfType(ModName(moduleName, mb), rtype, n));
end;

function getNthSymbolEquationOfType(rtype: TReturnType; n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthSymbolEquationOfType(ModName(moduleName, mb), rtype, n));
end;

function getNthSymbolInitialAssignmentOfType(rtype: TReturnType; n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthSymbolInitialAssignmentOfType(ModName(moduleName, mb), rtype, n));
end;

function getNthSymbolAssignmentRuleOfType(rtype: TReturnType; n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthSymbolAssignmentRuleOfType(ModName(moduleName, mb), rtype, n));
end;

function getNthSymbolRateRuleOfType(rtype: TReturnType; n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthSymbolRateRuleOfType(ModName(moduleName, mb), rtype, n));
end;

function getNthSymbolCompartmentOfType(rtype: TReturnType; n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthSymbolCompartmentOfType(ModName(moduleName, mb), rtype, n));
end;

function getTypeOfSymbol(const symbolName, moduleName: string): TReturnType;
var
  mb, sb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  sb := ToUtf8(symbolName);
  Result := ant_getTypeOfSymbol(p, PAnsiChar(sb));
end;

function getTypeOfEquationForSymbol(const symbolName, moduleName: string): TFormulaType;
var
  mb, sb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  sb := ToUtf8(symbolName);
  Result := ant_getTypeOfEquationForSymbol(p, PAnsiChar(sb));
end;

function getCompartmentForSymbol(const symbolName, moduleName: string): string;
var
  mb, sb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  sb := ToUtf8(symbolName);
  Result := AntStr(ant_getCompartmentForSymbol(p, PAnsiChar(sb)));
end;

function getSymbolSubstanceOnly(const symbolName, moduleName: string): Boolean;
var
  mb, sb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  sb := ToUtf8(symbolName);
  Result := Boolean(ant_getSymbolSubstanceOnly(p, PAnsiChar(sb)));
end;

function getSymbolHasValue(const symbolName, moduleName: string): Boolean;
var
  mb, sb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  sb := ToUtf8(symbolName);
  Result := Boolean(ant_getSymbolHasValue(p, PAnsiChar(sb)));
end;

{ ---------------------------------------------------------------------------
  Reactions
  --------------------------------------------------------------------------- }

function getNumReactions(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumReactions(ModName(moduleName, mb)));
end;

function getReactionNames(const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getReactionNames(p), Integer(ant_getNumReactions(p)));
end;

function getNthReactionName(rxn: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthReactionName(ModName(moduleName, mb), rxn));
end;

function getNumReactants(rxn: Integer; const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumReactants(ModName(moduleName, mb), rxn));
end;

function getNumProducts(rxn: Integer; const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumProducts(ModName(moduleName, mb), rxn));
end;

{ Row lengths for the per-reaction jagged arrays. }
function ReactantCounts(p: PAnsiChar): TArray<Integer>;
var
  i, n: Integer;
begin
  n := Integer(ant_getNumReactions(p));
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := Integer(ant_getNumReactants(p, i));
end;

function ProductCounts(p: PAnsiChar): TArray<Integer>;
var
  i, n: Integer;
begin
  n := Integer(ant_getNumReactions(p));
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := Integer(ant_getNumProducts(p, i));
end;

function getReactantNames(const moduleName: string): TStringGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrGrid(ant_getReactantNames(p), ReactantCounts(p));
end;

function getProductNames(const moduleName: string): TStringGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrGrid(ant_getProductNames(p), ProductCounts(p));
end;

function getNthReactionReactantNames(rxn: Integer; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getNthReactionReactantNames(p, rxn),
    Integer(ant_getNumReactants(p, rxn)));
end;

function getNthReactionProductNames(rxn: Integer; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getNthReactionProductNames(p, rxn),
    Integer(ant_getNumProducts(p, rxn)));
end;

function getNthReactionMthReactantName(rxn, reactant: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthReactionMthReactantName(ModName(moduleName, mb), rxn, reactant));
end;

function getNthReactionMthProductName(rxn, product: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthReactionMthProductName(ModName(moduleName, mb), rxn, product));
end;

function getReactantStoichiometries(const moduleName: string): TDoubleGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := DblGrid(ant_getReactantStoichiometries(p), ReactantCounts(p));
end;

function getProductStoichiometries(const moduleName: string): TDoubleGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := DblGrid(ant_getProductStoichiometries(p), ProductCounts(p));
end;

function getNthReactionReactantStoichiometries(rxn: Integer; const moduleName: string): TArray<Double>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := DblArray(ant_getNthReactionReactantStoichiometries(p, rxn),
    Integer(ant_getNumReactants(p, rxn)));
end;

function getNthReactionProductStoichiometries(rxn: Integer; const moduleName: string): TArray<Double>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := DblArray(ant_getNthReactionProductStoichiometries(p, rxn),
    Integer(ant_getNumProducts(p, rxn)));
end;

function getNthReactionMthReactantStoichiometry(rxn, reactant: Integer; const moduleName: string): Double;
var
  mb: UTF8String;
begin
  Result := ant_getNthReactionMthReactantStoichiometries(ModName(moduleName, mb), rxn, reactant);
end;

function getNthReactionMthProductStoichiometry(rxn, product: Integer; const moduleName: string): Double;
var
  mb: UTF8String;
begin
  Result := ant_getNthReactionMthProductStoichiometries(ModName(moduleName, mb), rxn, product);
end;

function getNthReactionMthReactantStoichiometryString(rxn, reactant: Integer;
  const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthReactionMthReactantStoichiometryString(
    ModName(moduleName, mb), rxn, reactant));
end;

function getNthReactionMthProductStoichiometryString(rxn, product: Integer;
  const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthReactionMthProductStoichiometryString(
    ModName(moduleName, mb), rxn, product));
end;

function getNumReactionRates(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumReactionRates(ModName(moduleName, mb)));
end;

function getReactionRates(const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getReactionRates(p), Integer(ant_getNumReactionRates(p)));
end;

function getNthReactionRate(rxn: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthReactionRate(ModName(moduleName, mb), rxn));
end;

{ ---------------------------------------------------------------------------
  Interactions
  --------------------------------------------------------------------------- }

function getNumInteractions(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumInteractions(ModName(moduleName, mb)));
end;

function getNumInteractors(interaction: Integer; const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumInteractors(ModName(moduleName, mb), interaction));
end;

function getNumInteractees(interaction: Integer; const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumInteractees(ModName(moduleName, mb), interaction));
end;

function InteractorCounts(p: PAnsiChar): TArray<Integer>;
var
  i, n: Integer;
begin
  n := Integer(ant_getNumInteractions(p));
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := Integer(ant_getNumInteractors(p, i));
end;

function InteracteeCounts(p: PAnsiChar): TArray<Integer>;
var
  i, n: Integer;
begin
  n := Integer(ant_getNumInteractions(p));
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := Integer(ant_getNumInteractees(p, i));
end;

function getInteractorNames(const moduleName: string): TStringGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrGrid(ant_getInteractorNames(p), InteractorCounts(p));
end;

function getInteracteeNames(const moduleName: string): TStringGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrGrid(ant_getInteracteeNames(p), InteracteeCounts(p));
end;

function getNthInteractionInteractorNames(interaction: Integer; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getNthInteractionInteractorNames(p, interaction),
    Integer(ant_getNumInteractors(p, interaction)));
end;

function getNthInteractionInteracteeNames(interaction: Integer; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getNthInteractionInteracteeNames(p, interaction),
    Integer(ant_getNumInteractees(p, interaction)));
end;

function getNthInteractionMthInteractorName(interaction, interactor: Integer;
  const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthInteractionMthInteractorName(ModName(moduleName, mb),
    interaction, interactor));
end;

function getNthInteractionMthInteracteeName(interaction, interactee: Integer;
  const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthInteractionMthInteracteeName(ModName(moduleName, mb),
    interaction, interactee));
end;

function getInteractionDividers(const moduleName: string): TArray<TReactionDivider>;
var
  mb: UTF8String;
  p: PAnsiChar;
  raw: PInteger;
  i, n: Integer;
begin
  p := ModName(moduleName, mb);
  n := Integer(ant_getNumInteractions(p));
  raw := ant_getInteractionDividers(p);
  if (raw = nil) or (n <= 0) then
    Exit(nil);
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := TReactionDivider(PIntegerArray(raw)^[i]);
end;

function getNthInteractionDivider(n: Integer; const moduleName: string): TReactionDivider;
var
  mb: UTF8String;
begin
  Result := ant_getNthInteractionDivider(ModName(moduleName, mb), n);
end;

{ ---------------------------------------------------------------------------
  Stoichiometry matrix
  --------------------------------------------------------------------------- }

function getStoichiometryMatrixNumRows(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getStoichiometryMatrixNumRows(ModName(moduleName, mb)));
end;

function getStoichiometryMatrixNumColumns(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getStoichiometryMatrixNumColumns(ModName(moduleName, mb)));
end;

function getStoichiometryMatrix(const moduleName: string): TDoubleGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
  counts: TArray<Integer>;
  i, rows, cols: Integer;
begin
  p := ModName(moduleName, mb);
  rows := Integer(ant_getStoichiometryMatrixNumRows(p));
  cols := Integer(ant_getStoichiometryMatrixNumColumns(p));
  SetLength(counts, rows);
  for i := 0 to rows - 1 do
    counts[i] := cols;
  Result := DblGrid(ant_getStoichiometryMatrix(p), counts);
end;

function getStoichiometryMatrixRowLabels(const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getStoichiometryMatrixRowLabels(p),
    Integer(ant_getStoichiometryMatrixNumRows(p)));
end;

function getStoichiometryMatrixColumnLabels(const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getStoichiometryMatrixColumnLabels(p),
    Integer(ant_getStoichiometryMatrixNumColumns(p)));
end;

{ ---------------------------------------------------------------------------
  Events
  --------------------------------------------------------------------------- }

function getNumEvents(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumEvents(ModName(moduleName, mb)));
end;

function getEventNames(const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getEventNames(p), Integer(ant_getNumEvents(p)));
end;

function getNthEventName(event: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthEventName(ModName(moduleName, mb), event));
end;

function getNumAssignmentsForEvent(event: Integer; const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumAssignmentsForEvent(ModName(moduleName, mb), event));
end;

function getTriggerForEvent(event: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getTriggerForEvent(ModName(moduleName, mb), event));
end;

function getDelayForEvent(event: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getDelayForEvent(ModName(moduleName, mb), event));
end;

function getEventHasDelay(event: Integer; const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_getEventHasDelay(ModName(moduleName, mb), event));
end;

function getPriorityForEvent(event: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getPriorityForEvent(ModName(moduleName, mb), event));
end;

function getEventHasPriority(event: Integer; const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_getEventHasPriority(ModName(moduleName, mb), event));
end;

function getPersistenceForEvent(event: Integer; const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_getPersistenceForEvent(ModName(moduleName, mb), event));
end;

function getT0ForEvent(event: Integer; const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_getT0ForEvent(ModName(moduleName, mb), event));
end;

function getFromTriggerForEvent(event: Integer; const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_getFromTriggerForEvent(ModName(moduleName, mb), event));
end;

function getNthAssignmentVariableForEvent(event, n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthAssignmentVariableForEvent(ModName(moduleName, mb), event, n));
end;

function getNthAssignmentEquationForEvent(event, n: Integer; const moduleName: string): string;
var
  mb: UTF8String;
begin
  Result := AntStr(ant_getNthAssignmentEquationForEvent(ModName(moduleName, mb), event, n));
end;

{ ---------------------------------------------------------------------------
  DNA strands
  --------------------------------------------------------------------------- }

function ULongArray(P: PCULong; Count: Integer): TArray<Integer>;
var
  i: Integer;
begin
  if (P = nil) or (Count <= 0) then
    Exit(nil);
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
    Result[i] := Integer(PCULongArray(P)^[i]);
end;

function getNumDNAStrands(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumDNAStrands(ModName(moduleName, mb)));
end;

function getDNAStrandSizes(const moduleName: string): TArray<Integer>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := ULongArray(ant_getDNAStrandSizes(p), Integer(ant_getNumDNAStrands(p)));
end;

function getSizeOfNthDNAStrand(n: Integer; const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getSizeOfNthDNAStrand(ModName(moduleName, mb), n));
end;

function getDNAStrands(const moduleName: string): TStringGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrGrid(ant_getDNAStrands(p),
    ULongArray(ant_getDNAStrandSizes(p), Integer(ant_getNumDNAStrands(p))));
end;

function getNthDNAStrand(n: Integer; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrArray(ant_getNthDNAStrand(p, n),
    Integer(ant_getSizeOfNthDNAStrand(p, n)));
end;

function getIsNthDNAStrandOpen(n: Integer; upstream: Boolean; const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_getIsNthDNAStrandOpen(ModName(moduleName, mb), n, TCBool(upstream)));
end;

function getNumModularDNAStrands(const moduleName: string): Integer;
var
  mb: UTF8String;
begin
  Result := Integer(ant_getNumModularDNAStrands(ModName(moduleName, mb)));
end;

function getModularDNAStrandSizes(const moduleName: string): TArray<Integer>;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := ULongArray(ant_getModularDNAStrandSizes(p),
    Integer(ant_getNumModularDNAStrands(p)));
end;

function getModularDNAStrands(const moduleName: string): TStringGrid2D;
var
  mb: UTF8String;
  p: PAnsiChar;
begin
  p := ModName(moduleName, mb);
  Result := StrGrid(ant_getModularDNAStrands(p),
    ULongArray(ant_getModularDNAStrandSizes(p),
    Integer(ant_getNumModularDNAStrands(p))));
end;

function getNthModularDNAStrand(n: Integer; const moduleName: string): TArray<string>;
var
  mb: UTF8String;
  p: PAnsiChar;
  sizes: TArray<Integer>;
begin
  p := ModName(moduleName, mb);
  { There is no getSizeOfNthModularDNAStrand, so take the length from the
    sizes array. }
  sizes := ULongArray(ant_getModularDNAStrandSizes(p),
    Integer(ant_getNumModularDNAStrands(p)));
  if (n < 0) or (n > High(sizes)) then
    Exit(nil);
  Result := StrArray(ant_getNthModularDNAStrand(p, n), sizes[n]);
end;

function getIsNthModularDNAStrandOpen(n: Integer; upstream: Boolean;
  const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_getIsNthModularDNAStrandOpen(ModName(moduleName, mb), n,
    TCBool(upstream)));
end;

{ ---------------------------------------------------------------------------
  Translation settings
  --------------------------------------------------------------------------- }

procedure setRemoveFunctionDefinitions(removeFunctionDefinitions: Boolean);
begin
  CheckLoaded;
  ant_setRemoveFunctionDefinitions(TCBool(removeFunctionDefinitions));
end;

procedure setWriteSBMLTimestamp(writeTimestamp: Boolean);
begin
  CheckLoaded;
  ant_setWriteSBMLTimestamp(TCBool(writeTimestamp));
end;

procedure setBareNumbersAreDimensionless(dimensionless: Boolean);
begin
  CheckLoaded;
  ant_setBareNumbersAreDimensionless(TCBool(dimensionless));
end;

function addDefaultInitialValues(const moduleName: string): Boolean;
var
  mb: UTF8String;
begin
  Result := Boolean(ant_addDefaultInitialValues(ModName(moduleName, mb)));
end;

{ ---------------------------------------------------------------------------
  Round-trip convenience
  --------------------------------------------------------------------------- }

function antimonyToSBML(const antimonyText: string;
  strictWarnings: Boolean): TModelErrorState;
var
  pending: string;
begin
  Result := Default (TModelErrorState);
  CheckLoaded;

  if ant_loadString(PAnsiChar(ToUtf8(antimonyText))) = -1 then
    begin
    Result.errMsg := AntStr(ant_getLastError);
    Exit;
    end;

  if strictWarnings then
    begin
    pending := AntStr(ant_getLastError);
    if pending <> '' then
      begin
      Result.errMsg := pending;
      Exit;
      end;
    end;

  Result.sbmlStr := AntStr(ant_getSBMLString(ant_getMainModuleName));
  Result.ok := True;
end;

function sbmlToAntimony(const sbmlText: string): TModelErrorState;
begin
  Result := Default (TModelErrorState);
  CheckLoaded;

  if ant_loadSBMLString(PAnsiChar(ToUtf8(sbmlText))) = -1 then
    begin
    Result.errMsg := AntStr(ant_getLastError);
    Exit;
    end;

  Result.sbmlStr := AntStr(ant_getAntimonyString(ant_getMainModuleName));
  Result.ok := True;
end;

end.
