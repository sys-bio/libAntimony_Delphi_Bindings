unit uAntimonyTypes;

{ Shared types for the libAntimony bindings.

  Everything here mirrors antimony-develop/src/enums.h and the C types used by
  antimony_api.h. Nothing in this unit touches the library itself. }

interface

uses
  System.SysUtils;

type
  { --------------------------------------------------------------------------
    C scalar types.

    libantimony's API uses 'long' and 'unsigned long' throughout. That type is
    NOT the same width on the platforms we target:

      Windows (MSVC, LLP64) ....... long is 32-bit
      macOS / Linux (clang, LP64) . long is 64-bit

    Getting this wrong silently corrupts every count and index the library
    returns, so the aliases below are the single place it is decided.
    -------------------------------------------------------------------------- }
{$IF Defined(MSWINDOWS)}
  TCLong  = Int32;
  TCULong = UInt32;
{$ELSE}
  TCLong  = Int64;
  TCULong = UInt64;
{$ENDIF}

  { C 'int' is 32-bit on every platform we care about. }
  TCInt = Int32;

  { C++ 'bool' is one byte under both MSVC and clang. ByteBool reads only that
    byte, which matters because the upper bits of the return register are not
    guaranteed to be cleared. }
  TCBool = ByteBool;

  PCDouble = ^Double;
  PPCDouble = ^PCDouble;
  PPPAnsiChar = ^PPAnsiChar;
  PCULong = ^TCULong;

  { Untyped-length array views over the C pointers, for indexing only. }
  TPAnsiCharArray = array [0 .. MaxInt div SizeOf(PAnsiChar) - 1] of PAnsiChar;
  PPAnsiCharArray = ^TPAnsiCharArray;

  TPPAnsiCharArray = array [0 .. MaxInt div SizeOf(PPAnsiChar) - 1] of PPAnsiChar;
  PPPAnsiCharArray = ^TPPAnsiCharArray;

  TDoubleArray = array [0 .. MaxInt div SizeOf(Double) - 1] of Double;
  PDoubleArray = ^TDoubleArray;

  TPDoubleArray = array [0 .. MaxInt div SizeOf(PCDouble) - 1] of PCDouble;
  PPDoubleArray = ^TPDoubleArray;

  TCULongArray = array [0 .. MaxInt div SizeOf(TCULong) - 1] of TCULong;
  PCULongArray = ^TCULongArray;

{ C enums are int-sized. $Z4 makes the Delphi equivalents match; without it
  they would be passed as a single byte. }
{$MINENUMSIZE 4}

type
  { enums.h: enum return_type. Ordinals are positional and must stay in step
    with the C header. }
  TReturnType = (
    rtAllSymbols = 0,
    rtAllSpecies,
    rtAllFormulas,
    rtAllDNA,
    rtAllOperators,
    rtAllGenes,
    rtAllReactions,
    rtAllInteractions,
    rtAllEvents,
    rtAllCompartments,
    rtAllUnknown,
    rtVarSpecies,
    rtVarFormulas,
    rtVarOperators,
    rtVarCompartments,
    rtConstSpecies,
    rtConstFormulas,
    rtConstOperators,
    rtConstCompartments,
    rtSubModules,
    rtExpandedStrands,
    rtModularStrands,
    rtAllUnits,
    rtAllDeleted,
    rtAllConstraints,
    rtAllStoichiometries,
    rtAllAlgebraicRules,
    rtAllGeneProducts,
    rtAllGeneProductAssociations,
    rtAllSpeciesFbcInfo
  );

  { enums.h: enum formula_type }
  TFormulaType = (
    ftInitial = 0,
    ftAssignment,
    ftRate,
    ftKinetic,
    ftTrigger,
    ftAlgebraic
  );

  { enums.h: enum rd_type -- the arrow used in an Antimony interaction. }
  TReactionDivider = (
    rdBecomes = 0,
    rdActivates,
    rdInhibits,
    rdInfluences,
    rdBecomesIrreversibly
  );

{$MINENUMSIZE 1}

type
  { Raised by the friendly layer in uAntimonyAPI for load failures and for
    calls made against an unbound entry point. }
  EAntimonyError = class(Exception);

  { Non-raising result for the common 'translate this and tell me what went
    wrong' case. }
  TModelErrorState = record
    errMsg: string;
    sbmlStr: string;
    ok: Boolean;
  end;

  TStringGrid2D = TArray<TArray<string>>;
  TDoubleGrid2D = TArray<TArray<Double>>;

const
  ReturnTypeNames: array [TReturnType] of string = (
    'allSymbols', 'allSpecies', 'allFormulas', 'allDNA', 'allOperators',
    'allGenes', 'allReactions', 'allInteractions', 'allEvents',
    'allCompartments', 'allUnknown', 'varSpecies', 'varFormulas',
    'varOperators', 'varCompartments', 'constSpecies', 'constFormulas',
    'constOperators', 'constCompartments', 'subModules', 'expandedStrands',
    'modularStrands', 'allUnits', 'allDeleted', 'allConstraints',
    'allStoichiometries', 'allAlgebraicRules', 'allGeneProducts',
    'allGeneProductAssociations', 'allSpeciesFbcInfo');

  FormulaTypeNames: array [TFormulaType] of string = (
    'initial assignment', 'assignment rule', 'rate rule', 'kinetic law',
    'trigger', 'algebraic rule');

  ReactionDividerSymbols: array [TReactionDivider] of string = (
    '->', '-o', '-|', '-(', '=>');

implementation

end.
