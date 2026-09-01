unit uAntimonyRaw;

{ A 1:1 mapping of the libantimony C API onto Delphi function pointers.

  Every declaration here matches antimony_api.h exactly -- same name (with an
  'ant_' prefix so it does not collide with the friendly wrappers), same
  parameter order, same C types, cdecl. No convenience, no string conversion,
  no main-module defaults; that is uAntimonyAPI's job.

  Ownership: every pointer libantimony returns was allocated with malloc inside
  the library and is owned by the caller. Delphi cannot safely free memory from
  the MSVC heap, so nothing here frees anything -- copy what you need out
  immediately and call ant_freeAll when you are done with the library.

  The CellML entry points (loadCellMLFile, loadCellMLString, writeCellMLFile,
  getCellMLString) are declared in the header but are not exported by the
  shipped builds, so they are deliberately omitted. }

interface

uses
  System.SysUtils,
  uAntimonyTypes;

var
  { --- Input ------------------------------------------------------------- }
  ant_loadFile: function(filename: PAnsiChar): TCLong; cdecl;
  ant_loadString: function(model: PAnsiChar): TCLong; cdecl;
  ant_loadAntimonyFile: function(filename: PAnsiChar): TCLong; cdecl;
  ant_loadAntimonyString: function(model: PAnsiChar): TCLong; cdecl;
  ant_loadSBMLFile: function(filename: PAnsiChar): TCLong; cdecl;
  ant_loadSBMLString: function(model: PAnsiChar): TCLong; cdecl;
  ant_loadSBMLStringWithLocation: function(model, location: PAnsiChar): TCLong; cdecl;

  ant_getNumFiles: function: TCULong; cdecl;
  ant_revertTo: function(index: TCLong): TCBool; cdecl;
  ant_clearPreviousLoads: procedure; cdecl;
  ant_addDirectory: procedure(directory: PAnsiChar); cdecl;
  ant_clearDirectories: procedure; cdecl;
  ant_setRemoveFunctionDefinitions: procedure(removeFunctionDefinitions: TCBool); cdecl;

  { --- Output ------------------------------------------------------------ }
  { Exported by current builds, but was missing from older ones, so it stays in
    OptionalProcs and must be Assigned-checked. }
  ant_getVersionStr: function: PAnsiChar; cdecl;

  ant_writeAntimonyFile: function(filename, moduleName: PAnsiChar): TCInt; cdecl;
  ant_getAntimonyString: function(moduleName: PAnsiChar): PAnsiChar; cdecl;
  ant_writeSBMLFile: function(filename, moduleName: PAnsiChar): TCInt; cdecl;
  ant_getSBMLString: function(moduleName: PAnsiChar): PAnsiChar; cdecl;
  ant_setWriteSBMLTimestamp: procedure(writeTimestamp: TCBool); cdecl;
  ant_writeCompSBMLFile: function(filename, moduleName: PAnsiChar): TCInt; cdecl;
  ant_getCompSBMLString: function(moduleName: PAnsiChar): PAnsiChar; cdecl;

  { --- Errors and warnings ----------------------------------------------- }
  ant_printAllDataFor: function(moduleName: PAnsiChar): PAnsiChar; cdecl;
  ant_checkModule: function(moduleName: PAnsiChar): TCBool; cdecl;
  ant_getLastError: function: PAnsiChar; cdecl;
  ant_getWarnings: function: PAnsiChar; cdecl;
  ant_getSBMLInfoMessages: function(moduleName: PAnsiChar): PAnsiChar; cdecl;
  ant_getSBMLWarnings: function(moduleName: PAnsiChar): PAnsiChar; cdecl;

  { --- Modules ------------------------------------------------------------ }
  ant_getNumModules: function: TCULong; cdecl;
  ant_getModuleNames: function: PPAnsiChar; cdecl;
  ant_getNthModuleName: function(n: TCULong): PAnsiChar; cdecl;
  ant_getMainModuleName: function: PAnsiChar; cdecl;

  ant_getNumSymbolsInInterfaceOf: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getSymbolNamesInInterfaceOf: function(moduleName: PAnsiChar): PPAnsiChar; cdecl;
  ant_getNthSymbolNameInInterfaceOf: function(moduleName: PAnsiChar; n: TCULong): PAnsiChar; cdecl;

  { --- Replacements ------------------------------------------------------- }
  ant_getNumReplacedSymbolNames: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getAllReplacementSymbolPairs: function(moduleName: PAnsiChar): PPPAnsiChar; cdecl;
  ant_getNthReplacementSymbolPair: function(moduleName: PAnsiChar; n: TCULong): PPAnsiChar; cdecl;
  ant_getNthFormerSymbolName: function(moduleName: PAnsiChar; n: TCULong): PAnsiChar; cdecl;
  ant_getNthReplacementSymbolName: function(moduleName: PAnsiChar; n: TCULong): PAnsiChar; cdecl;

  ant_getNumReplacedSymbolNamesBetween: function(moduleName, formerSubmodName,
    replacementSubmodName: PAnsiChar): TCULong; cdecl;
  ant_getAllReplacementSymbolPairsBetween: function(moduleName, formerSubmodName,
    replacementSubmodName: PAnsiChar): PPPAnsiChar; cdecl;
  ant_getNthReplacementSymbolPairBetween: function(moduleName, formerSubmodName,
    replacementSubmodName: PAnsiChar; n: TCULong): PPAnsiChar; cdecl;
  ant_getNthFormerSymbolNameBetween: function(moduleName, formerSubmodName,
    replacementSubmodName: PAnsiChar; n: TCULong): PAnsiChar; cdecl;
  ant_getNthReplacementSymbolNameBetween: function(moduleName, formerSubmodName,
    replacementSubmodName: PAnsiChar; n: TCULong): PAnsiChar; cdecl;

  { --- User-defined functions --------------------------------------------- }
  { Unlike everything else here these take no moduleName: Antimony function
    definitions are not scoped to a module, so the whole active set is queried
    at once. }
  ant_getNumUserFunctions: function: TCULong; cdecl;
  ant_getNthUserFunctionName: function(n: TCULong): PAnsiChar; cdecl;
  ant_getNumUserFunctionArguments: function(n: TCULong): TCULong; cdecl;
  ant_getNthUserFunctionArguments: function(n: TCULong): PPAnsiChar; cdecl;
  ant_getNthUserFunctionBody: function(n: TCULong): PAnsiChar; cdecl;

  { --- Symbols ------------------------------------------------------------ }
  ant_getNumSymbolsOfType: function(moduleName: PAnsiChar; rtype: TReturnType): TCULong; cdecl;
  ant_getSymbolNamesOfType: function(moduleName: PAnsiChar; rtype: TReturnType): PPAnsiChar; cdecl;
  ant_getSymbolDisplayNamesOfType: function(moduleName: PAnsiChar; rtype: TReturnType): PPAnsiChar; cdecl;
  ant_getSymbolEquationsOfType: function(moduleName: PAnsiChar; rtype: TReturnType): PPAnsiChar; cdecl;
  ant_getSymbolInitialAssignmentsOfType: function(moduleName: PAnsiChar; rtype: TReturnType): PPAnsiChar; cdecl;
  ant_getSymbolAssignmentRulesOfType: function(moduleName: PAnsiChar; rtype: TReturnType): PPAnsiChar; cdecl;
  ant_getSymbolRateRulesOfType: function(moduleName: PAnsiChar; rtype: TReturnType): PPAnsiChar; cdecl;
  ant_getSymbolCompartmentsOfType: function(moduleName: PAnsiChar; rtype: TReturnType): PPAnsiChar; cdecl;

  ant_getNthSymbolNameOfType: function(moduleName: PAnsiChar; rtype: TReturnType; n: TCULong): PAnsiChar; cdecl;
  ant_getNthSymbolDisplayNameOfType: function(moduleName: PAnsiChar; rtype: TReturnType; n: TCULong): PAnsiChar; cdecl;
  ant_getNthSymbolEquationOfType: function(moduleName: PAnsiChar; rtype: TReturnType; n: TCULong): PAnsiChar; cdecl;
  ant_getNthSymbolInitialAssignmentOfType: function(moduleName: PAnsiChar; rtype: TReturnType; n: TCULong): PAnsiChar; cdecl;
  ant_getNthSymbolAssignmentRuleOfType: function(moduleName: PAnsiChar; rtype: TReturnType; n: TCULong): PAnsiChar; cdecl;
  ant_getNthSymbolRateRuleOfType: function(moduleName: PAnsiChar; rtype: TReturnType; n: TCULong): PAnsiChar; cdecl;
  ant_getNthSymbolCompartmentOfType: function(moduleName: PAnsiChar; rtype: TReturnType; n: TCULong): PAnsiChar; cdecl;

  ant_getTypeOfSymbol: function(moduleName, symbolName: PAnsiChar): TReturnType; cdecl;
  ant_getTypeOfEquationForSymbol: function(moduleName, symbolName: PAnsiChar): TFormulaType; cdecl;
  ant_getCompartmentForSymbol: function(moduleName, symbolName: PAnsiChar): PAnsiChar; cdecl;
  ant_getSymbolSubstanceOnly: function(moduleName, symbolName: PAnsiChar): TCBool; cdecl;
  { False for a symbol declared with no value at all, which is otherwise
    indistinguishable from a value of zero. }
  ant_getSymbolHasValue: function(moduleName, symbolName: PAnsiChar): TCBool; cdecl;

  { --- Reactions ---------------------------------------------------------- }
  ant_getNumReactions: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getReactionNames: function(moduleName: PAnsiChar): PPAnsiChar; cdecl;
  ant_getNthReactionName: function(moduleName: PAnsiChar; n: TCULong): PAnsiChar; cdecl;
  ant_getNumReactants: function(moduleName: PAnsiChar; rxn: TCULong): TCULong; cdecl;
  ant_getNumProducts: function(moduleName: PAnsiChar; rxn: TCULong): TCULong; cdecl;

  ant_getReactantNames: function(moduleName: PAnsiChar): PPPAnsiChar; cdecl;
  ant_getNthReactionReactantNames: function(moduleName: PAnsiChar; rxn: TCULong): PPAnsiChar; cdecl;
  ant_getNthReactionMthReactantName: function(moduleName: PAnsiChar; rxn, reactant: TCULong): PAnsiChar; cdecl;
  ant_getProductNames: function(moduleName: PAnsiChar): PPPAnsiChar; cdecl;
  ant_getNthReactionProductNames: function(moduleName: PAnsiChar; rxn: TCULong): PPAnsiChar; cdecl;
  ant_getNthReactionMthProductName: function(moduleName: PAnsiChar; rxn, product: TCULong): PAnsiChar; cdecl;

  ant_getReactantStoichiometries: function(moduleName: PAnsiChar): PPCDouble; cdecl;
  ant_getProductStoichiometries: function(moduleName: PAnsiChar): PPCDouble; cdecl;
  ant_getNthReactionReactantStoichiometries: function(moduleName: PAnsiChar; rxn: TCULong): PCDouble; cdecl;
  ant_getNthReactionProductStoichiometries: function(moduleName: PAnsiChar; rxn: TCULong): PCDouble; cdecl;
  ant_getNthReactionMthReactantStoichiometries: function(moduleName: PAnsiChar; rxn, reactant: TCULong): Double; cdecl;
  ant_getNthReactionMthProductStoichiometries: function(moduleName: PAnsiChar; rxn, product: TCULong): Double; cdecl;

  { The stoichiometry as written. The numeric getters above return NaN when a
    stoichiometry was given as a symbol; these return the symbol's name (or the
    number as text), which is the only way to recover it. }
  ant_getNthReactionMthReactantStoichiometryString: function(moduleName: PAnsiChar; rxn, reactant: TCULong): PAnsiChar; cdecl;
  ant_getNthReactionMthProductStoichiometryString: function(moduleName: PAnsiChar; rxn, product: TCULong): PAnsiChar; cdecl;

  { --- Interactions ------------------------------------------------------- }
  ant_getNumInteractions: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getNumInteractors: function(moduleName: PAnsiChar; rxn: TCULong): TCULong; cdecl;
  ant_getNumInteractees: function(moduleName: PAnsiChar; rxn: TCULong): TCULong; cdecl;

  ant_getInteractorNames: function(moduleName: PAnsiChar): PPPAnsiChar; cdecl;
  ant_getNthInteractionInteractorNames: function(moduleName: PAnsiChar; rxn: TCULong): PPAnsiChar; cdecl;
  ant_getNthInteractionMthInteractorName: function(moduleName: PAnsiChar; interaction, interactor: TCULong): PAnsiChar; cdecl;
  ant_getInteracteeNames: function(moduleName: PAnsiChar): PPPAnsiChar; cdecl;
  ant_getNthInteractionInteracteeNames: function(moduleName: PAnsiChar; rxn: TCULong): PPAnsiChar; cdecl;
  ant_getNthInteractionMthInteracteeName: function(moduleName: PAnsiChar; interaction, interactee: TCULong): PAnsiChar; cdecl;

  ant_getInteractionDividers: function(moduleName: PAnsiChar): PInteger; cdecl;
  ant_getNthInteractionDivider: function(moduleName: PAnsiChar; n: TCULong): TReactionDivider; cdecl;

  { --- Stoichiometry matrix ----------------------------------------------- }
  ant_getStoichiometryMatrix: function(moduleName: PAnsiChar): PPCDouble; cdecl;
  ant_getStoichiometryMatrixRowLabels: function(moduleName: PAnsiChar): PPAnsiChar; cdecl;
  ant_getStoichiometryMatrixColumnLabels: function(moduleName: PAnsiChar): PPAnsiChar; cdecl;
  ant_getStoichiometryMatrixNumRows: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getStoichiometryMatrixNumColumns: function(moduleName: PAnsiChar): TCULong; cdecl;

  ant_getNumReactionRates: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getReactionRates: function(moduleName: PAnsiChar): PPAnsiChar; cdecl;
  ant_getNthReactionRate: function(moduleName: PAnsiChar; rxn: TCULong): PAnsiChar; cdecl;

  { --- Events ------------------------------------------------------------- }
  ant_getNumEvents: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getEventNames: function(moduleName: PAnsiChar): PPAnsiChar; cdecl;
  ant_getNthEventName: function(moduleName: PAnsiChar; event: TCULong): PAnsiChar; cdecl;
  ant_getNumAssignmentsForEvent: function(moduleName: PAnsiChar; event: TCULong): TCULong; cdecl;
  ant_getTriggerForEvent: function(moduleName: PAnsiChar; event: TCULong): PAnsiChar; cdecl;
  ant_getDelayForEvent: function(moduleName: PAnsiChar; event: TCULong): PAnsiChar; cdecl;
  ant_getEventHasDelay: function(moduleName: PAnsiChar; event: TCULong): TCBool; cdecl;
  ant_getPriorityForEvent: function(moduleName: PAnsiChar; event: TCULong): PAnsiChar; cdecl;
  ant_getEventHasPriority: function(moduleName: PAnsiChar; event: TCULong): TCBool; cdecl;
  ant_getPersistenceForEvent: function(moduleName: PAnsiChar; event: TCULong): TCBool; cdecl;
  ant_getT0ForEvent: function(moduleName: PAnsiChar; event: TCULong): TCBool; cdecl;
  ant_getFromTriggerForEvent: function(moduleName: PAnsiChar; event: TCULong): TCBool; cdecl;
  ant_getNthAssignmentVariableForEvent: function(moduleName: PAnsiChar; event, n: TCULong): PAnsiChar; cdecl;
  ant_getNthAssignmentEquationForEvent: function(moduleName: PAnsiChar; event, n: TCULong): PAnsiChar; cdecl;

  { --- DNA strands -------------------------------------------------------- }
  ant_getNumDNAStrands: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getDNAStrandSizes: function(moduleName: PAnsiChar): PCULong; cdecl;
  ant_getSizeOfNthDNAStrand: function(moduleName: PAnsiChar; n: TCULong): TCULong; cdecl;
  ant_getDNAStrands: function(moduleName: PAnsiChar): PPPAnsiChar; cdecl;
  ant_getNthDNAStrand: function(moduleName: PAnsiChar; n: TCULong): PPAnsiChar; cdecl;
  ant_getIsNthDNAStrandOpen: function(moduleName: PAnsiChar; n: TCULong; upstream: TCBool): TCBool; cdecl;

  ant_getNumModularDNAStrands: function(moduleName: PAnsiChar): TCULong; cdecl;
  ant_getModularDNAStrandSizes: function(moduleName: PAnsiChar): PCULong; cdecl;
  ant_getModularDNAStrands: function(moduleName: PAnsiChar): PPPAnsiChar; cdecl;
  ant_getNthModularDNAStrand: function(moduleName: PAnsiChar; n: TCULong): PPAnsiChar; cdecl;
  ant_getIsNthModularDNAStrandOpen: function(moduleName: PAnsiChar; n: TCULong; upstream: TCBool): TCBool; cdecl;

  { --- Memory and defaults ------------------------------------------------ }
  ant_freeAll: procedure; cdecl;
  ant_addDefaultInitialValues: function(moduleName: PAnsiChar): TCBool; cdecl;
  ant_setBareNumbersAreDimensionless: procedure(dimensionless: TCBool); cdecl;

function AntimonyLibraryFileName: string;

{ Loads the shared library and resolves every entry point above.

  Returns False if the library itself could not be loaded, or if any
  non-optional symbol was missing; errMsg then describes which. Entry points
  named in OptionalProcs are allowed to stay nil -- callers must test them.

  Calling this when the library is already loaded is a no-op that returns
  True. }
function loadAntimonyLibrary(out errMsg: string): Boolean;
procedure unloadAntimonyLibrary;
function antimonyLibraryLoaded: Boolean;

{ Names of entry points that failed to resolve during the last load. }
function antimonyMissingSymbols: TArray<string>;

const
  { Entry points declared in antimony_api.h that real builds may not export.
    getVersionStr is absent from the current Windows DLL. }
  OptionalProcs: array [0 .. 0] of string = ('getVersionStr');

implementation

uses
{$IF Defined(MSWINDOWS)}
  Winapi.Windows,
{$ENDIF}
  System.Classes;

var
  FLibHandle: NativeUInt = 0;
  FMissing: TArray<string>;
  { Every slot Bind has written to, so unload can blank them all again rather
    than leaving 120-odd dangling pointers behind. }
  FSlots: TArray<PPointer>;

function AntimonyLibraryFileName: string;
begin
{$IF Defined(MSWINDOWS)}
  Result := 'libantimony.dll';
{$ELSEIF Defined(MACOS)}
  Result := 'libantimony.dylib';
{$ELSE}
  Result := 'libantimony.so';
{$ENDIF}
end;

function antimonyLibraryLoaded: Boolean;
begin
  Result := FLibHandle <> 0;
end;

function antimonyMissingSymbols: TArray<string>;
begin
  Result := FMissing;
end;

function IsOptional(const AName: string): Boolean;
var
  s: string;
begin
  for s in OptionalProcs do
    if s = AName then
      Exit(True);
  Result := False;
end;

{ Resolves AName into Slot. A nil result is recorded rather than raised, so a
  single missing export produces a useful list instead of aborting the load. }
procedure Bind(Slot: PPointer; const AName: string);
var
  P: Pointer;
begin
{$IF Defined(MSWINDOWS)}
  P := Winapi.Windows.GetProcAddress(HMODULE(FLibHandle), PChar(AName));
{$ELSE}
  { The POSIX GetProcAddress is overloaded and takes no bare string -- the
    cast picks the PWideChar overload, same as the Windows branch above. }
  P := System.SysUtils.GetProcAddress(FLibHandle, PChar(AName));
{$ENDIF}
  Slot^ := P;
  FSlots := FSlots + [Slot];
  if (P = nil) and not IsOptional(AName) then
    FMissing := FMissing + [AName];
end;

procedure BindAll;
begin
  FMissing := nil;
  FSlots := nil;

  Bind(@@ant_loadFile, 'loadFile');
  Bind(@@ant_loadString, 'loadString');
  Bind(@@ant_loadAntimonyFile, 'loadAntimonyFile');
  Bind(@@ant_loadAntimonyString, 'loadAntimonyString');
  Bind(@@ant_loadSBMLFile, 'loadSBMLFile');
  Bind(@@ant_loadSBMLString, 'loadSBMLString');
  Bind(@@ant_loadSBMLStringWithLocation, 'loadSBMLStringWithLocation');
  Bind(@@ant_getNumFiles, 'getNumFiles');
  Bind(@@ant_revertTo, 'revertTo');
  Bind(@@ant_clearPreviousLoads, 'clearPreviousLoads');
  Bind(@@ant_addDirectory, 'addDirectory');
  Bind(@@ant_clearDirectories, 'clearDirectories');
  Bind(@@ant_setRemoveFunctionDefinitions, 'setRemoveFunctionDefinitions');

  Bind(@@ant_getVersionStr, 'getVersionStr');
  Bind(@@ant_writeAntimonyFile, 'writeAntimonyFile');
  Bind(@@ant_getAntimonyString, 'getAntimonyString');
  Bind(@@ant_writeSBMLFile, 'writeSBMLFile');
  Bind(@@ant_getSBMLString, 'getSBMLString');
  Bind(@@ant_setWriteSBMLTimestamp, 'setWriteSBMLTimestamp');
  Bind(@@ant_writeCompSBMLFile, 'writeCompSBMLFile');
  Bind(@@ant_getCompSBMLString, 'getCompSBMLString');

  Bind(@@ant_printAllDataFor, 'printAllDataFor');
  Bind(@@ant_checkModule, 'checkModule');
  Bind(@@ant_getLastError, 'getLastError');
  Bind(@@ant_getWarnings, 'getWarnings');
  Bind(@@ant_getSBMLInfoMessages, 'getSBMLInfoMessages');
  Bind(@@ant_getSBMLWarnings, 'getSBMLWarnings');

  Bind(@@ant_getNumModules, 'getNumModules');
  Bind(@@ant_getModuleNames, 'getModuleNames');
  Bind(@@ant_getNthModuleName, 'getNthModuleName');
  Bind(@@ant_getMainModuleName, 'getMainModuleName');
  Bind(@@ant_getNumSymbolsInInterfaceOf, 'getNumSymbolsInInterfaceOf');
  Bind(@@ant_getSymbolNamesInInterfaceOf, 'getSymbolNamesInInterfaceOf');
  Bind(@@ant_getNthSymbolNameInInterfaceOf, 'getNthSymbolNameInInterfaceOf');

  Bind(@@ant_getNumReplacedSymbolNames, 'getNumReplacedSymbolNames');
  Bind(@@ant_getAllReplacementSymbolPairs, 'getAllReplacementSymbolPairs');
  Bind(@@ant_getNthReplacementSymbolPair, 'getNthReplacementSymbolPair');
  Bind(@@ant_getNthFormerSymbolName, 'getNthFormerSymbolName');
  Bind(@@ant_getNthReplacementSymbolName, 'getNthReplacementSymbolName');
  Bind(@@ant_getNumReplacedSymbolNamesBetween, 'getNumReplacedSymbolNamesBetween');
  Bind(@@ant_getAllReplacementSymbolPairsBetween, 'getAllReplacementSymbolPairsBetween');
  Bind(@@ant_getNthReplacementSymbolPairBetween, 'getNthReplacementSymbolPairBetween');
  Bind(@@ant_getNthFormerSymbolNameBetween, 'getNthFormerSymbolNameBetween');
  Bind(@@ant_getNthReplacementSymbolNameBetween, 'getNthReplacementSymbolNameBetween');

  Bind(@@ant_getNumUserFunctions, 'getNumUserFunctions');
  Bind(@@ant_getNthUserFunctionName, 'getNthUserFunctionName');
  Bind(@@ant_getNumUserFunctionArguments, 'getNumUserFunctionArguments');
  Bind(@@ant_getNthUserFunctionArguments, 'getNthUserFunctionArguments');
  Bind(@@ant_getNthUserFunctionBody, 'getNthUserFunctionBody');

  Bind(@@ant_getNumSymbolsOfType, 'getNumSymbolsOfType');
  Bind(@@ant_getSymbolNamesOfType, 'getSymbolNamesOfType');
  Bind(@@ant_getSymbolDisplayNamesOfType, 'getSymbolDisplayNamesOfType');
  Bind(@@ant_getSymbolEquationsOfType, 'getSymbolEquationsOfType');
  Bind(@@ant_getSymbolInitialAssignmentsOfType, 'getSymbolInitialAssignmentsOfType');
  Bind(@@ant_getSymbolAssignmentRulesOfType, 'getSymbolAssignmentRulesOfType');
  Bind(@@ant_getSymbolRateRulesOfType, 'getSymbolRateRulesOfType');
  Bind(@@ant_getSymbolCompartmentsOfType, 'getSymbolCompartmentsOfType');
  Bind(@@ant_getNthSymbolNameOfType, 'getNthSymbolNameOfType');
  Bind(@@ant_getNthSymbolDisplayNameOfType, 'getNthSymbolDisplayNameOfType');
  Bind(@@ant_getNthSymbolEquationOfType, 'getNthSymbolEquationOfType');
  Bind(@@ant_getNthSymbolInitialAssignmentOfType, 'getNthSymbolInitialAssignmentOfType');
  Bind(@@ant_getNthSymbolAssignmentRuleOfType, 'getNthSymbolAssignmentRuleOfType');
  Bind(@@ant_getNthSymbolRateRuleOfType, 'getNthSymbolRateRuleOfType');
  Bind(@@ant_getNthSymbolCompartmentOfType, 'getNthSymbolCompartmentOfType');
  Bind(@@ant_getTypeOfSymbol, 'getTypeOfSymbol');
  Bind(@@ant_getTypeOfEquationForSymbol, 'getTypeOfEquationForSymbol');
  Bind(@@ant_getCompartmentForSymbol, 'getCompartmentForSymbol');
  Bind(@@ant_getSymbolSubstanceOnly, 'getSymbolSubstanceOnly');
  Bind(@@ant_getSymbolHasValue, 'getSymbolHasValue');

  Bind(@@ant_getNumReactions, 'getNumReactions');
  Bind(@@ant_getReactionNames, 'getReactionNames');
  Bind(@@ant_getNthReactionName, 'getNthReactionName');
  Bind(@@ant_getNumReactants, 'getNumReactants');
  Bind(@@ant_getNumProducts, 'getNumProducts');
  Bind(@@ant_getReactantNames, 'getReactantNames');
  Bind(@@ant_getNthReactionReactantNames, 'getNthReactionReactantNames');
  Bind(@@ant_getNthReactionMthReactantName, 'getNthReactionMthReactantName');
  Bind(@@ant_getProductNames, 'getProductNames');
  Bind(@@ant_getNthReactionProductNames, 'getNthReactionProductNames');
  Bind(@@ant_getNthReactionMthProductName, 'getNthReactionMthProductName');
  Bind(@@ant_getReactantStoichiometries, 'getReactantStoichiometries');
  Bind(@@ant_getProductStoichiometries, 'getProductStoichiometries');
  Bind(@@ant_getNthReactionReactantStoichiometries, 'getNthReactionReactantStoichiometries');
  Bind(@@ant_getNthReactionProductStoichiometries, 'getNthReactionProductStoichiometries');
  Bind(@@ant_getNthReactionMthReactantStoichiometries, 'getNthReactionMthReactantStoichiometries');
  Bind(@@ant_getNthReactionMthProductStoichiometries, 'getNthReactionMthProductStoichiometries');
  Bind(@@ant_getNthReactionMthReactantStoichiometryString, 'getNthReactionMthReactantStoichiometryString');
  Bind(@@ant_getNthReactionMthProductStoichiometryString, 'getNthReactionMthProductStoichiometryString');

  Bind(@@ant_getNumInteractions, 'getNumInteractions');
  Bind(@@ant_getNumInteractors, 'getNumInteractors');
  Bind(@@ant_getNumInteractees, 'getNumInteractees');
  Bind(@@ant_getInteractorNames, 'getInteractorNames');
  Bind(@@ant_getNthInteractionInteractorNames, 'getNthInteractionInteractorNames');
  Bind(@@ant_getNthInteractionMthInteractorName, 'getNthInteractionMthInteractorName');
  Bind(@@ant_getInteracteeNames, 'getInteracteeNames');
  Bind(@@ant_getNthInteractionInteracteeNames, 'getNthInteractionInteracteeNames');
  Bind(@@ant_getNthInteractionMthInteracteeName, 'getNthInteractionMthInteracteeName');
  Bind(@@ant_getInteractionDividers, 'getInteractionDividers');
  Bind(@@ant_getNthInteractionDivider, 'getNthInteractionDivider');

  Bind(@@ant_getStoichiometryMatrix, 'getStoichiometryMatrix');
  Bind(@@ant_getStoichiometryMatrixRowLabels, 'getStoichiometryMatrixRowLabels');
  Bind(@@ant_getStoichiometryMatrixColumnLabels, 'getStoichiometryMatrixColumnLabels');
  Bind(@@ant_getStoichiometryMatrixNumRows, 'getStoichiometryMatrixNumRows');
  Bind(@@ant_getStoichiometryMatrixNumColumns, 'getStoichiometryMatrixNumColumns');
  Bind(@@ant_getNumReactionRates, 'getNumReactionRates');
  Bind(@@ant_getReactionRates, 'getReactionRates');
  Bind(@@ant_getNthReactionRate, 'getNthReactionRate');

  Bind(@@ant_getNumEvents, 'getNumEvents');
  Bind(@@ant_getEventNames, 'getEventNames');
  Bind(@@ant_getNthEventName, 'getNthEventName');
  Bind(@@ant_getNumAssignmentsForEvent, 'getNumAssignmentsForEvent');
  Bind(@@ant_getTriggerForEvent, 'getTriggerForEvent');
  Bind(@@ant_getDelayForEvent, 'getDelayForEvent');
  Bind(@@ant_getEventHasDelay, 'getEventHasDelay');
  Bind(@@ant_getPriorityForEvent, 'getPriorityForEvent');
  Bind(@@ant_getEventHasPriority, 'getEventHasPriority');
  Bind(@@ant_getPersistenceForEvent, 'getPersistenceForEvent');
  Bind(@@ant_getT0ForEvent, 'getT0ForEvent');
  Bind(@@ant_getFromTriggerForEvent, 'getFromTriggerForEvent');
  Bind(@@ant_getNthAssignmentVariableForEvent, 'getNthAssignmentVariableForEvent');
  Bind(@@ant_getNthAssignmentEquationForEvent, 'getNthAssignmentEquationForEvent');

  Bind(@@ant_getNumDNAStrands, 'getNumDNAStrands');
  Bind(@@ant_getDNAStrandSizes, 'getDNAStrandSizes');
  Bind(@@ant_getSizeOfNthDNAStrand, 'getSizeOfNthDNAStrand');
  Bind(@@ant_getDNAStrands, 'getDNAStrands');
  Bind(@@ant_getNthDNAStrand, 'getNthDNAStrand');
  Bind(@@ant_getIsNthDNAStrandOpen, 'getIsNthDNAStrandOpen');
  Bind(@@ant_getNumModularDNAStrands, 'getNumModularDNAStrands');
  Bind(@@ant_getModularDNAStrandSizes, 'getModularDNAStrandSizes');
  Bind(@@ant_getModularDNAStrands, 'getModularDNAStrands');
  Bind(@@ant_getNthModularDNAStrand, 'getNthModularDNAStrand');
  Bind(@@ant_getIsNthModularDNAStrandOpen, 'getIsNthModularDNAStrandOpen');

  Bind(@@ant_freeAll, 'freeAll');
  Bind(@@ant_addDefaultInitialValues, 'addDefaultInitialValues');
  Bind(@@ant_setBareNumbersAreDimensionless, 'setBareNumbersAreDimensionless');
end;

{ Candidate paths, most specific first. The bare name is tried last so the
  platform loader's own search (PATH, @rpath, LD_LIBRARY_PATH) still applies. }
function CandidatePaths: TArray<string>;
var
  libName, exeDir: string;
begin
  libName := AntimonyLibraryFileName;
  exeDir := ExtractFilePath(ParamStr(0));
  Result := [exeDir + libName];
{$IF Defined(MACOS)}
  { An .app bundle puts the executable in Contents/MacOS and dylibs one level
    up in Contents/Frameworks. }
  Result := Result + [exeDir + '../Frameworks/' + libName];
{$ENDIF}
  Result := Result + [libName];
end;

function loadAntimonyLibrary(out errMsg: string): Boolean;
var
  path: string;
begin
  errMsg := '';
  if FLibHandle <> 0 then
    Exit(True);

  for path in CandidatePaths do
    begin
    FLibHandle := SafeLoadLibrary(path);
    if FLibHandle <> 0 then
      Break;
    end;

  if FLibHandle = 0 then
    begin
    errMsg := Format('Could not load %s. Looked in: %s',
      [AntimonyLibraryFileName, string.Join(', ', CandidatePaths)]);
    Exit(False);
    end;

  BindAll;

  if Length(FMissing) > 0 then
    begin
    errMsg := Format('%s loaded but is missing %d expected entry point(s): %s',
      [AntimonyLibraryFileName, Length(FMissing), string.Join(', ', FMissing)]);
    unloadAntimonyLibrary;
    Exit(False);
    end;

  Result := True;
end;

procedure unloadAntimonyLibrary;
var
  Slot: PPointer;
begin
  if FLibHandle = 0 then
    Exit;
  FreeLibrary(FLibHandle);
  FLibHandle := 0;
  for Slot in FSlots do
    Slot^ := nil;
  FSlots := nil;
end;

end.
