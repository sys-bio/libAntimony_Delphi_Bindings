program libAntimony_Bindings_Project;

{ Smoke test for the libAntimony bindings: loads a small model and exercises
  one function from each section of the API. }

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  uAntimonyTypes in 'uAntimonyTypes.pas',
  uAntimonyRaw in 'uAntimonyRaw.pas',
  uAntimonyAPI in 'uAntimonyAPI.pas';

const
  TestModel =
    'model testModel'                             + sLineBreak +
    '  compartment cell = 1.5;'                   + sLineBreak +
    '  species S1 in cell, S2 in cell, S3 in cell;' + sLineBreak +
    '  J0: S1 -> S2; k1*S1;'                      + sLineBreak +
    '  J1: S2 -> 2 S3; k2*S2;'                    + sLineBreak +
    '  S1 = 10; S2 = 0; S3 = 0;'                  + sLineBreak +
    '  k1 = 0.3; k2 = 0.1;'                       + sLineBreak +
    '  E1: at (S1 < 1): k1 = 0.5;'                + sLineBreak +
    'end';

  { Interactions, DNA strands and submodule replacements have no counterpart in
    the first model, and they are the parts that marshal char*** jagged arrays,
    so they get their own case. }
  TestModel2 =
    'model inner(x)'                              + sLineBreak +
    '  x = 1;'                                    + sLineBreak +
    '  y := x * 2;'                               + sLineBreak +
    'end'                                         + sLineBreak +
    ''                                            + sLineBreak +
    'model outer'                                 + sLineBreak +
    '  A = 5; B = 0;'                             + sLineBreak +
    '  sub: inner(A);'                            + sLineBreak +
    '  R1: A -> B; k*A/(1 + B);'                  + sLineBreak +
    '  k = 0.1;'                                  + sLineBreak +
    '  I1: B -| R1;'                              + sLineBreak +
    '  P1 = 0.5;'                                 + sLineBreak +
    '  G1: -> C; 0.2;'                            + sLineBreak +
    '  dna1: --P1--G1--;'                         + sLineBreak +
    'end';

  { The accessors added in libantimony 3.1: a user-defined function to
    enumerate, a substanceOnly species, a stoichiometry written as a symbol
    (which the numeric getters can only report as NaN), and a symbol referenced
    but never given a value. }
  TestModel3 =
    'function MM(v, k, s)'                        + sLineBreak +
    '  v * s / (k + s)'                           + sLineBreak +
    'end'                                         + sLineBreak +
    ''                                            + sLineBreak +
    'model kinetics'                              + sLineBreak +
    '  compartment c = 2;'                        + sLineBreak +
    '  substanceOnly species S1 in c;'            + sLineBreak +
    '  species S2 in c, S3 in c;'                 + sLineBreak +
    '  S1 = 3; S2 = 1; S3 = 0;'                   + sLineBreak +
    '  n = 2;'                                    + sLineBreak +
    '  R1: S1 + n S2 => S3; MM(Vm, Km, S1);'      + sLineBreak +
    '  R2: S3 => S2; kdeg * S3;'                  + sLineBreak +
    '  Vm = 1; Km = 0.5;'                         + sLineBreak +
    'end';

  { The two items still open in libantimony-requests.md, as minimal SBML L3V2
    models. These are here to be checked through the bindings rather than taken
    on trust: the harness prints what the API returns and draws no conclusion. }

  { §4b: a functionDefinition called with <true/> and with <pi/>. If the
    constants are substituted, no free symbol should appear. }
  BvarLeakSBML =
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<sbml xmlns="http://www.sbml.org/sbml/level3/version2/core" level="3" version="2">' +
    '<model id="bvar_leak">' +
    '<listOfFunctionDefinitions>' +
    '<functionDefinition id="my_and"><math xmlns="http://www.w3.org/1998/Math/MathML">' +
    '<lambda><bvar><ci> x </ci></bvar><apply><and/><ci> x </ci></apply></lambda>' +
    '</math></functionDefinition>' +
    '<functionDefinition id="my_eq"><math xmlns="http://www.w3.org/1998/Math/MathML">' +
    '<lambda><bvar><ci> a </ci></bvar><bvar><ci> b </ci></bvar>' +
    '<apply><eq/><ci> a </ci><ci> b </ci></apply></lambda>' +
    '</math></functionDefinition>' +
    '</listOfFunctionDefinitions>' +
    '<listOfParameters>' +
    '<parameter id="P1" value="3" constant="true"/>' +
    '<parameter id="c" constant="false"/>' +
    '<parameter id="d" constant="false"/>' +
    '</listOfParameters>' +
    '<listOfRules>' +
    '<assignmentRule variable="c"><math xmlns="http://www.w3.org/1998/Math/MathML">' +
    '<piecewise><piece><cn type="integer">1</cn>' +
    '<apply><ci> my_and </ci><true/></apply></piece>' +
    '<otherwise><cn type="integer">0</cn></otherwise></piecewise>' +
    '</math></assignmentRule>' +
    '<assignmentRule variable="d"><math xmlns="http://www.w3.org/1998/Math/MathML">' +
    '<piecewise><piece><cn type="integer">1</cn>' +
    '<apply><ci> my_eq </ci><ci> P1 </ci><pi/></apply></piece>' +
    '<otherwise><cn type="integer">0</cn></otherwise></piecewise>' +
    '</math></assignmentRule>' +
    '</listOfRules></model></sbml>';

  { §2b: conversionFactor on the model and on a species. If it survives, it
    should reappear in the SBML written back out. }
  ConversionFactorSBML =
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<sbml xmlns="http://www.sbml.org/sbml/level3/version2/core" level="3" version="2">' +
    '<model id="cf_test" conversionFactor="m_cf">' +
    '<listOfCompartments><compartment id="C" size="1" constant="true"/></listOfCompartments>' +
    '<listOfSpecies>' +
    '<species id="S1" compartment="C" initialAmount="1.5" hasOnlySubstanceUnits="true" ' +
      'boundaryCondition="false" constant="false" conversionFactor="s1_cf"/>' +
    '<species id="S2" compartment="C" initialAmount="0" hasOnlySubstanceUnits="true" ' +
      'boundaryCondition="false" constant="false"/>' +
    '</listOfSpecies>' +
    '<listOfParameters>' +
    '<parameter id="m_cf" value="0.9" constant="true"/>' +
    '<parameter id="s1_cf" value="1.3" constant="true"/>' +
    '<parameter id="k" value="0.1" constant="true"/>' +
    '</listOfParameters>' +
    '<listOfReactions>' +
    '<reaction id="J0" reversible="false">' +
    '<listOfReactants><speciesReference species="S1" stoichiometry="1" constant="true"/></listOfReactants>' +
    '<listOfProducts><speciesReference species="S2" stoichiometry="1" constant="true"/></listOfProducts>' +
    '<kineticLaw><math xmlns="http://www.w3.org/1998/Math/MathML">' +
    '<apply><times/><ci> k </ci><ci> S1 </ci></apply></math></kineticLaw>' +
    '</reaction></listOfReactions></model></sbml>';

procedure Show(const caption: string; const values: TArray<string>);
begin
  Writeln(Format('  %-24s %s', [caption + ':', string.Join(', ', values)]));
end;

procedure ShowGrid(const caption: string; const grid: TStringGrid2D);
var
  i: Integer;
begin
  Writeln('  ' + caption + ':');
  for i := 0 to High(grid) do
    Writeln(Format('    [%d] %s', [i, string.Join(', ', grid[i])]));
end;

procedure ReportModel;
var
  i, j: Integer;
  matrix: TDoubleGrid2D;
  row: string;
  dividers: TArray<TReactionDivider>;
begin
  Writeln('Main module: ', getMainModuleName);
  Writeln('Modules:     ', getNumModules, ' (', string.Join(', ', getModuleNames), ')');
  Writeln;

  Writeln('Symbols');
  Show('variable species', getSymbolNamesOfType(rtVarSpecies));
  Show('constant species', getSymbolNamesOfType(rtConstSpecies));
  Show('compartments', getSymbolNamesOfType(rtAllCompartments));
  Show('formulas', getSymbolNamesOfType(rtAllFormulas));
  Show('formula values', getSymbolEquationsOfType(rtAllFormulas));
  Show('species compartments', getSymbolCompartmentsOfType(rtVarSpecies));
  Writeln;

  Writeln('Reactions (', getNumReactions, ')');
  Show('names', getSymbolNamesOfType(rtAllReactions));
  Show('rates', getReactionRates);
  ShowGrid('reactants', getReactantNames);
  ShowGrid('products', getProductNames);
  Writeln;

  Writeln('Stoichiometry matrix (', getStoichiometryMatrixNumRows, ' x ',
    getStoichiometryMatrixNumColumns, ')');
  Show('columns', getStoichiometryMatrixColumnLabels);
  matrix := getStoichiometryMatrix;
  for i := 0 to High(matrix) do
    begin
    row := '';
    for j := 0 to High(matrix[i]) do
      row := row + Format('%8.2f', [matrix[i][j]]);
    Writeln(Format('    %-6s %s',
      [getStoichiometryMatrixRowLabels[i], row]));
    end;
  Writeln;

  Writeln('Events (', getNumEvents, ')');
  for i := 0 to getNumEvents - 1 do
    begin
    Writeln(Format('    %s  trigger: %s', [getNthEventName(i), getTriggerForEvent(i)]));
    for j := 0 to getNumAssignmentsForEvent(i) - 1 do
      Writeln(Format('      %s = %s', [getNthAssignmentVariableForEvent(i, j),
        getNthAssignmentEquationForEvent(i, j)]));
    end;
  Writeln;

  Writeln('Interactions (', getNumInteractions, ')');
  dividers := getInteractionDividers;
  for i := 0 to High(dividers) do
    Writeln('    ', ReactionDividerSymbols[dividers[i]]);

  Writeln('DNA strands: ', getNumDNAStrands);
  Writeln;
end;

procedure RoundTrip;
var
  state: TModelErrorState;
  back: TModelErrorState;
begin
  Writeln('Antimony -> SBML');
  state := antimonyToSBML(TestModel);
  if not state.ok then
    begin
    Writeln('  FAILED: ', state.errMsg);
    Exit;
    end;
  Writeln('  produced ', Length(state.sbmlStr), ' characters of SBML');

  Writeln('SBML -> Antimony');
  back := sbmlToAntimony(state.sbmlStr);
  if not back.ok then
    Writeln('  FAILED: ', back.errMsg)
  else
    Writeln('  produced ', Length(back.sbmlStr), ' characters of Antimony');
  Writeln;
end;

{ loadFile / loadAntimonyFile take a path rather than a string, so they need a
  file on disk to exercise them. }
procedure FileRoundTrip;
var
  path: string;
  n: Integer;
begin
  path := TPath.Combine(TPath.GetTempPath,
    'antimony_smoketest_' + TPath.GetGUIDFileName + '.txt');
  Writeln('Using temp model file ', path);
  { GetBytes rather than WriteAllText(..., TEncoding.UTF8), which prepends a
    BOM. libantimony's parser rejects the BOM as an unknown character. }
  TFile.WriteAllBytes(path, TEncoding.UTF8.GetBytes(TestModel));
  try
    n := loadFile(path);
    Writeln('loadFile');
    Writeln('  index ', n, ', main module "', getMainModuleName, '", ',
      getNumReactions, ' reactions');

    n := loadAntimonyFile(path);
    Writeln('loadAntimonyFile');
    Writeln('  index ', n, ', ', getNumSymbolsOfType(rtVarSpecies), ' variable species');
    Writeln('  files loaded so far: ', getNumFiles);
    Writeln;
  finally
    { Don't let a failed cleanup mask a real failure from the calls above. }
    try
      TFile.Delete(path);
    except
      on E: Exception do
        Writeln('  (could not delete temp file: ', E.Message, ')');
    end;
  end;
end;

procedure ReportModularModel;
var
  i: Integer;
  dividers: TArray<TReactionDivider>;
begin
  Writeln('Modular model "', getMainModuleName, '"');
  Show('submodules', getSymbolNamesOfType(rtSubModules));
  Show('interface of inner', getSymbolNamesInInterfaceOf('inner'));

  Writeln('  replacements (', getNumReplacedSymbolNames, '):');
  ShowGrid('  pairs', getAllReplacementSymbolPairs);

  Writeln('  interactions (', getNumInteractions, '):');
  dividers := getInteractionDividers;
  for i := 0 to getNumInteractions - 1 do
    Writeln(Format('    %s %s %s',
      [string.Join('+', getNthInteractionInteractorNames(i)),
       ReactionDividerSymbols[dividers[i]],
       string.Join('+', getNthInteractionInteracteeNames(i))]));

  Writeln('  DNA strands (', getNumDNAStrands, '):');
  ShowGrid('  strands', getDNAStrands);
  Writeln('  modular strands (', getNumModularDNAStrands, '):');
  ShowGrid('  strands', getModularDNAStrands);
  Writeln;
end;

{ The accessors added in libantimony 3.1. Each one exists because the
  information was previously only recoverable by scraping getAntimonyString. }
procedure ReportNewAccessors;
var
  i, j: Integer;
  name: string;
begin
  Writeln('User-defined functions (', getNumUserFunctions, ')');
  for i := 0 to getNumUserFunctions - 1 do
    Writeln(Format('    %s(%s) = %s',
      [getNthUserFunctionName(i),
       string.Join(', ', getNthUserFunctionArguments(i)),
       getNthUserFunctionBody(i)]));
  Writeln;

  Writeln('Reaction names (getReactionNames)');
  Show('names', getReactionNames);
  for i := 0 to getNumReactions - 1 do
    Writeln(Format('    [%d] %s', [i, getNthReactionName(i)]));
  Writeln;

  Writeln('Stoichiometries as written');
  for i := 0 to getNumReactions - 1 do
    begin
    for j := 0 to getNumReactants(i) - 1 do
      Writeln(Format('    %s reactant %s: %g -> "%s"',
        [getNthReactionName(i), getNthReactionMthReactantName(i, j),
         getNthReactionMthReactantStoichiometry(i, j),
         getNthReactionMthReactantStoichiometryString(i, j)]));
    for j := 0 to getNumProducts(i) - 1 do
      Writeln(Format('    %s product  %s: %g -> "%s"',
        [getNthReactionName(i), getNthReactionMthProductName(i, j),
         getNthReactionMthProductStoichiometry(i, j),
         getNthReactionMthProductStoichiometryString(i, j)]));
    end;
  Writeln;

  Writeln('Per-symbol flags');
  for name in getSymbolNamesOfType(rtAllSpecies) do
    Writeln(Format('    %-6s substanceOnly=%-5s hasValue=%s',
      [name, BoolToStr(getSymbolSubstanceOnly(name), True),
       BoolToStr(getSymbolHasValue(name), True)]));
  for name in getSymbolNamesOfType(rtAllFormulas) do
    Writeln(Format('    %-6s substanceOnly=%-5s hasValue=%s',
      [name, BoolToStr(getSymbolSubstanceOnly(name), True),
       BoolToStr(getSymbolHasValue(name), True)]));
  { The point of getSymbolHasValue: these are the symbols that were referenced
    but never assigned, and were previously indistinguishable from a zero. }
  for name in getSymbolNamesOfType(rtAllUnknown) do
    Writeln(Format('    %-6s (unknown type)     hasValue=%s',
      [name, BoolToStr(getSymbolHasValue(name), True)]));
  Writeln;
end;

{ Checks the two open items in libantimony-requests.md through the bindings.
  Everything printed is a raw API result; judge it yourself rather than taking
  the surrounding documentation on trust. }
procedure CheckOpenIssues;
var
  name, sbmlOut: string;
begin
  Writeln('=========================================================');
  Writeln('Open issue checks (raw API output -- draw your own conclusion)');
  Writeln('=========================================================');
  Writeln;

  Writeln('[requests.md 4b] MathML constants passed to a functionDefinition');
  Writeln('  Loading SBML where my_and(<true/>) and my_eq(P1, <pi/>) are called.');
  loadSBMLString(BvarLeakSBML);
  Writeln('  --- getAntimonyString ---');
  Writeln(getAntimonyString);
  Writeln('  Symbols of type rtAllUnknown (should be none if the constants were');
  Writeln('  substituted; each one is a lambda bvar that escaped):');
  for name in getSymbolNamesOfType(rtAllUnknown) do
    Writeln(Format('    %s   hasValue=%s', [name, BoolToStr(getSymbolHasValue(name), True)]));
  Writeln;

  Writeln('[requests.md 2b] conversionFactor on <model> and <species>');
  Writeln('  Loading SBML with conversionFactor="m_cf" and "s1_cf".');
  loadSBMLString(ConversionFactorSBML);
  Writeln('  --- getAntimonyString ---');
  Writeln(getAntimonyString);
  sbmlOut := getSBMLString;
  Writeln('  Written back out with getSBMLString: ', Length(sbmlOut), ' characters.');
  Writeln('  Does the round-tripped SBML still contain "conversionFactor"? ',
    BoolToStr(Pos('conversionFactor', sbmlOut) > 0, True));
  Writeln('  (m_cf/s1_cf may still appear as plain parameters; the question is');
  Writeln('   whether anything still marks them as conversion factors.)');
  Writeln;
end;

var
  errMsg: string;
begin
  try
    if not loadAntimonyLibrary(errMsg) then
      begin
      Writeln('Could not load the antimony library.');
      Writeln(errMsg);
      Readln;
      Exit;
      end;

    Writeln('Loaded ', AntimonyLibraryFileName, ' successfully.');
    if getVersionStr <> '' then
      Writeln('Version: ', getVersionStr)
    else
      Writeln('Version: (getVersionStr not exported by this build)');
    Writeln;

    loadAntimonyString(TestModel);
    ReportModel;
    RoundTrip;

    FileRoundTrip;

    loadAntimonyString(TestModel2);
    ReportModularModel;

    loadAntimonyString(TestModel3);
    ReportNewAccessors;

    CheckOpenIssues;

    freeAll;
    unloadAntimonyLibrary;
    Writeln('Done.');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
