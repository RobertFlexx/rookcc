unit rcc_conformance_catalog;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TConformanceCase = record
    TestID: string;
    StandardName: string;
    Area: string;
    Context: string;
    Feature: string;
    ExpectedOutcome: string;
    RequirementLevel: string;
  end;
  TConformanceCaseArray = array of TConformanceCase;

function BuildConformanceCatalog: TConformanceCaseArray;
function ConformanceSummary(const ACatalog: TConformanceCaseArray; const AStandard: string): string;
function FindConformanceCase(const ACatalog: TConformanceCaseArray; const ATestID: string; out ACase: TConformanceCase): Boolean;

implementation

procedure AddCase(var AValues: TConformanceCaseArray; const ATestID, AStandard, AArea, AContext, AFeature, AOutcome, ARequirement: string);
var N: LongInt;
begin
  N := Length(AValues); SetLength(AValues, N + 1);
  AValues[N].TestID := ATestID; AValues[N].StandardName := AStandard;
  AValues[N].Area := AArea; AValues[N].Context := AContext;
  AValues[N].Feature := AFeature; AValues[N].ExpectedOutcome := AOutcome;
  AValues[N].RequirementLevel := ARequirement;
end;

function BuildConformanceCatalog: TConformanceCaseArray;
begin
  Result := nil;
  AddCase(Result, 'c90.lexing.integer-rank.00000', 'c90',
    'lexing', 'constant-expression', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'c99.lexing.integer-rank.00001', 'c99',
    'lexing', 'cross-module', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.lexing.integer-rank.00002', 'c11',
    'lexing', 'block-scope', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.lexing.integer-rank.00003', 'c17',
    'lexing', 'runtime-expression', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.lexing.integer-rank.00004', 'c23',
    'lexing', 'translation-unit', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.lexing.integer-rank.00005', 'gnu90',
    'lexing', 'prototype', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.lexing.integer-rank.00006', 'gnu99',
    'lexing', 'variadic-call', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.lexing.integer-rank.00007', 'gnu11',
    'lexing', 'file-scope', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.lexing.integer-rank.00008', 'gnu17',
    'lexing', 'constant-expression', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.lexing.integer-rank.00009', 'gnu23',
    'lexing', 'cross-module', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.integer-rank.00010', 'posix.1-2008',
    'lexing', 'block-scope', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.lexing.integer-rank.00011', 'rcc1',
    'lexing', 'runtime-expression', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.preprocessing.integer-rank.00012', 'c90',
    'preprocessing', 'translation-unit', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'c99.preprocessing.integer-rank.00013', 'c99',
    'preprocessing', 'prototype', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.preprocessing.integer-rank.00014', 'c11',
    'preprocessing', 'variadic-call', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.preprocessing.integer-rank.00015', 'c17',
    'preprocessing', 'file-scope', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.preprocessing.integer-rank.00016', 'c23',
    'preprocessing', 'constant-expression', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.preprocessing.integer-rank.00017', 'gnu90',
    'preprocessing', 'cross-module', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.preprocessing.integer-rank.00018', 'gnu99',
    'preprocessing', 'block-scope', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.preprocessing.integer-rank.00019', 'gnu11',
    'preprocessing', 'runtime-expression', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.preprocessing.integer-rank.00020', 'gnu17',
    'preprocessing', 'translation-unit', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.preprocessing.integer-rank.00021', 'gnu23',
    'preprocessing', 'prototype', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.integer-rank.00022', 'posix.1-2008',
    'preprocessing', 'variadic-call', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.preprocessing.integer-rank.00023', 'rcc1',
    'preprocessing', 'file-scope', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.declarations.integer-rank.00024', 'c90',
    'declarations', 'constant-expression', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.declarations.integer-rank.00025', 'c99',
    'declarations', 'cross-module', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.declarations.integer-rank.00026', 'c11',
    'declarations', 'block-scope', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.declarations.integer-rank.00027', 'c17',
    'declarations', 'runtime-expression', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.declarations.integer-rank.00028', 'c23',
    'declarations', 'translation-unit', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.declarations.integer-rank.00029', 'gnu90',
    'declarations', 'prototype', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.declarations.integer-rank.00030', 'gnu99',
    'declarations', 'variadic-call', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.declarations.integer-rank.00031', 'gnu11',
    'declarations', 'file-scope', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.declarations.integer-rank.00032', 'gnu17',
    'declarations', 'constant-expression', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.declarations.integer-rank.00033', 'gnu23',
    'declarations', 'cross-module', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.integer-rank.00034', 'posix.1-2008',
    'declarations', 'block-scope', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.declarations.integer-rank.00035', 'rcc1',
    'declarations', 'runtime-expression', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.types.integer-rank.00036', 'c90',
    'types', 'translation-unit', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'c99.types.integer-rank.00037', 'c99',
    'types', 'prototype', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.types.integer-rank.00038', 'c11',
    'types', 'variadic-call', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.types.integer-rank.00039', 'c17',
    'types', 'file-scope', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.types.integer-rank.00040', 'c23',
    'types', 'constant-expression', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.types.integer-rank.00041', 'gnu90',
    'types', 'cross-module', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.types.integer-rank.00042', 'gnu99',
    'types', 'block-scope', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.types.integer-rank.00043', 'gnu11',
    'types', 'runtime-expression', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.types.integer-rank.00044', 'gnu17',
    'types', 'translation-unit', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.types.integer-rank.00045', 'gnu23',
    'types', 'prototype', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.types.integer-rank.00046', 'posix.1-2008',
    'types', 'variadic-call', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.types.integer-rank.00047', 'rcc1',
    'types', 'file-scope', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.conversions.integer-rank.00048', 'c90',
    'conversions', 'constant-expression', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'c99.conversions.integer-rank.00049', 'c99',
    'conversions', 'cross-module', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.conversions.integer-rank.00050', 'c11',
    'conversions', 'block-scope', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.conversions.integer-rank.00051', 'c17',
    'conversions', 'runtime-expression', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.conversions.integer-rank.00052', 'c23',
    'conversions', 'translation-unit', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.conversions.integer-rank.00053', 'gnu90',
    'conversions', 'prototype', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.conversions.integer-rank.00054', 'gnu99',
    'conversions', 'variadic-call', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.conversions.integer-rank.00055', 'gnu11',
    'conversions', 'file-scope', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.conversions.integer-rank.00056', 'gnu17',
    'conversions', 'constant-expression', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.conversions.integer-rank.00057', 'gnu23',
    'conversions', 'cross-module', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.integer-rank.00058', 'posix.1-2008',
    'conversions', 'block-scope', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.conversions.integer-rank.00059', 'rcc1',
    'conversions', 'runtime-expression', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.expressions.integer-rank.00060', 'c90',
    'expressions', 'translation-unit', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'c99.expressions.integer-rank.00061', 'c99',
    'expressions', 'prototype', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.expressions.integer-rank.00062', 'c11',
    'expressions', 'variadic-call', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.expressions.integer-rank.00063', 'c17',
    'expressions', 'file-scope', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.expressions.integer-rank.00064', 'c23',
    'expressions', 'constant-expression', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.expressions.integer-rank.00065', 'gnu90',
    'expressions', 'cross-module', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.expressions.integer-rank.00066', 'gnu99',
    'expressions', 'block-scope', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.expressions.integer-rank.00067', 'gnu11',
    'expressions', 'runtime-expression', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.expressions.integer-rank.00068', 'gnu17',
    'expressions', 'translation-unit', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.expressions.integer-rank.00069', 'gnu23',
    'expressions', 'prototype', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.integer-rank.00070', 'posix.1-2008',
    'expressions', 'variadic-call', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.expressions.integer-rank.00071', 'rcc1',
    'expressions', 'file-scope', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.statements.integer-rank.00072', 'c90',
    'statements', 'constant-expression', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'c99.statements.integer-rank.00073', 'c99',
    'statements', 'cross-module', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.statements.integer-rank.00074', 'c11',
    'statements', 'block-scope', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.statements.integer-rank.00075', 'c17',
    'statements', 'runtime-expression', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.statements.integer-rank.00076', 'c23',
    'statements', 'translation-unit', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.statements.integer-rank.00077', 'gnu90',
    'statements', 'prototype', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.statements.integer-rank.00078', 'gnu99',
    'statements', 'variadic-call', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.statements.integer-rank.00079', 'gnu11',
    'statements', 'file-scope', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.statements.integer-rank.00080', 'gnu17',
    'statements', 'constant-expression', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.statements.integer-rank.00081', 'gnu23',
    'statements', 'cross-module', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.statements.integer-rank.00082', 'posix.1-2008',
    'statements', 'block-scope', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.statements.integer-rank.00083', 'rcc1',
    'statements', 'runtime-expression', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.functions.integer-rank.00084', 'c90',
    'functions', 'translation-unit', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.functions.integer-rank.00085', 'c99',
    'functions', 'prototype', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.functions.integer-rank.00086', 'c11',
    'functions', 'variadic-call', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.functions.integer-rank.00087', 'c17',
    'functions', 'file-scope', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.functions.integer-rank.00088', 'c23',
    'functions', 'constant-expression', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.functions.integer-rank.00089', 'gnu90',
    'functions', 'cross-module', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.functions.integer-rank.00090', 'gnu99',
    'functions', 'block-scope', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.functions.integer-rank.00091', 'gnu11',
    'functions', 'runtime-expression', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.functions.integer-rank.00092', 'gnu17',
    'functions', 'translation-unit', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.functions.integer-rank.00093', 'gnu23',
    'functions', 'prototype', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.functions.integer-rank.00094', 'posix.1-2008',
    'functions', 'variadic-call', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.functions.integer-rank.00095', 'rcc1',
    'functions', 'file-scope', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.aggregates.integer-rank.00096', 'c90',
    'aggregates', 'constant-expression', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'c99.aggregates.integer-rank.00097', 'c99',
    'aggregates', 'cross-module', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.aggregates.integer-rank.00098', 'c11',
    'aggregates', 'block-scope', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.aggregates.integer-rank.00099', 'c17',
    'aggregates', 'runtime-expression', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.aggregates.integer-rank.00100', 'c23',
    'aggregates', 'translation-unit', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.aggregates.integer-rank.00101', 'gnu90',
    'aggregates', 'prototype', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.aggregates.integer-rank.00102', 'gnu99',
    'aggregates', 'variadic-call', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.aggregates.integer-rank.00103', 'gnu11',
    'aggregates', 'file-scope', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.aggregates.integer-rank.00104', 'gnu17',
    'aggregates', 'constant-expression', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.aggregates.integer-rank.00105', 'gnu23',
    'aggregates', 'cross-module', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.integer-rank.00106', 'posix.1-2008',
    'aggregates', 'block-scope', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.aggregates.integer-rank.00107', 'rcc1',
    'aggregates', 'runtime-expression', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.initializers.integer-rank.00108', 'c90',
    'initializers', 'translation-unit', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'c99.initializers.integer-rank.00109', 'c99',
    'initializers', 'prototype', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.initializers.integer-rank.00110', 'c11',
    'initializers', 'variadic-call', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.initializers.integer-rank.00111', 'c17',
    'initializers', 'file-scope', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.initializers.integer-rank.00112', 'c23',
    'initializers', 'constant-expression', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.initializers.integer-rank.00113', 'gnu90',
    'initializers', 'cross-module', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.initializers.integer-rank.00114', 'gnu99',
    'initializers', 'block-scope', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.initializers.integer-rank.00115', 'gnu11',
    'initializers', 'runtime-expression', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.initializers.integer-rank.00116', 'gnu17',
    'initializers', 'translation-unit', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.initializers.integer-rank.00117', 'gnu23',
    'initializers', 'prototype', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.integer-rank.00118', 'posix.1-2008',
    'initializers', 'variadic-call', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.initializers.integer-rank.00119', 'rcc1',
    'initializers', 'file-scope', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.floating.integer-rank.00120', 'c90',
    'floating', 'constant-expression', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'c99.floating.integer-rank.00121', 'c99',
    'floating', 'cross-module', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.floating.integer-rank.00122', 'c11',
    'floating', 'block-scope', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.floating.integer-rank.00123', 'c17',
    'floating', 'runtime-expression', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.floating.integer-rank.00124', 'c23',
    'floating', 'translation-unit', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.floating.integer-rank.00125', 'gnu90',
    'floating', 'prototype', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.floating.integer-rank.00126', 'gnu99',
    'floating', 'variadic-call', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.floating.integer-rank.00127', 'gnu11',
    'floating', 'file-scope', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.floating.integer-rank.00128', 'gnu17',
    'floating', 'constant-expression', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.floating.integer-rank.00129', 'gnu23',
    'floating', 'cross-module', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.floating.integer-rank.00130', 'posix.1-2008',
    'floating', 'block-scope', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.floating.integer-rank.00131', 'rcc1',
    'floating', 'runtime-expression', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.atomics.integer-rank.00132', 'c90',
    'atomics', 'translation-unit', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'c99.atomics.integer-rank.00133', 'c99',
    'atomics', 'prototype', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.atomics.integer-rank.00134', 'c11',
    'atomics', 'variadic-call', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.atomics.integer-rank.00135', 'c17',
    'atomics', 'file-scope', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.atomics.integer-rank.00136', 'c23',
    'atomics', 'constant-expression', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.atomics.integer-rank.00137', 'gnu90',
    'atomics', 'cross-module', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.atomics.integer-rank.00138', 'gnu99',
    'atomics', 'block-scope', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.atomics.integer-rank.00139', 'gnu11',
    'atomics', 'runtime-expression', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.atomics.integer-rank.00140', 'gnu17',
    'atomics', 'translation-unit', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.atomics.integer-rank.00141', 'gnu23',
    'atomics', 'prototype', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.integer-rank.00142', 'posix.1-2008',
    'atomics', 'variadic-call', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.atomics.integer-rank.00143', 'rcc1',
    'atomics', 'file-scope', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.variadics.integer-rank.00144', 'c90',
    'variadics', 'constant-expression', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.variadics.integer-rank.00145', 'c99',
    'variadics', 'cross-module', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.variadics.integer-rank.00146', 'c11',
    'variadics', 'block-scope', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.variadics.integer-rank.00147', 'c17',
    'variadics', 'runtime-expression', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.variadics.integer-rank.00148', 'c23',
    'variadics', 'translation-unit', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.variadics.integer-rank.00149', 'gnu90',
    'variadics', 'prototype', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.variadics.integer-rank.00150', 'gnu99',
    'variadics', 'variadic-call', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.variadics.integer-rank.00151', 'gnu11',
    'variadics', 'file-scope', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.variadics.integer-rank.00152', 'gnu17',
    'variadics', 'constant-expression', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.variadics.integer-rank.00153', 'gnu23',
    'variadics', 'cross-module', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.integer-rank.00154', 'posix.1-2008',
    'variadics', 'block-scope', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.variadics.integer-rank.00155', 'rcc1',
    'variadics', 'runtime-expression', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.library.integer-rank.00156', 'c90',
    'library', 'translation-unit', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'c99.library.integer-rank.00157', 'c99',
    'library', 'prototype', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.library.integer-rank.00158', 'c11',
    'library', 'variadic-call', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.library.integer-rank.00159', 'c17',
    'library', 'file-scope', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.library.integer-rank.00160', 'c23',
    'library', 'constant-expression', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.library.integer-rank.00161', 'gnu90',
    'library', 'cross-module', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.library.integer-rank.00162', 'gnu99',
    'library', 'block-scope', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.library.integer-rank.00163', 'gnu11',
    'library', 'runtime-expression', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.library.integer-rank.00164', 'gnu17',
    'library', 'translation-unit', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.library.integer-rank.00165', 'gnu23',
    'library', 'prototype', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.library.integer-rank.00166', 'posix.1-2008',
    'library', 'variadic-call', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.library.integer-rank.00167', 'rcc1',
    'library', 'file-scope', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.abi.integer-rank.00168', 'c90',
    'abi', 'constant-expression', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'c99.abi.integer-rank.00169', 'c99',
    'abi', 'cross-module', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.abi.integer-rank.00170', 'c11',
    'abi', 'block-scope', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.abi.integer-rank.00171', 'c17',
    'abi', 'runtime-expression', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.abi.integer-rank.00172', 'c23',
    'abi', 'translation-unit', 'integer-rank',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.abi.integer-rank.00173', 'gnu90',
    'abi', 'prototype', 'integer-rank',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.abi.integer-rank.00174', 'gnu99',
    'abi', 'variadic-call', 'integer-rank',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.abi.integer-rank.00175', 'gnu11',
    'abi', 'file-scope', 'integer-rank',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.abi.integer-rank.00176', 'gnu17',
    'abi', 'constant-expression', 'integer-rank',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.abi.integer-rank.00177', 'gnu23',
    'abi', 'cross-module', 'integer-rank',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.abi.integer-rank.00178', 'posix.1-2008',
    'abi', 'block-scope', 'integer-rank',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.abi.integer-rank.00179', 'rcc1',
    'abi', 'runtime-expression', 'integer-rank',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.object-format.integer-rank.00180', 'c90',
    'object-format', 'translation-unit', 'integer-rank',
    'compile-pass', 'required');
  AddCase(Result, 'c99.object-format.integer-rank.00181', 'c99',
    'object-format', 'prototype', 'integer-rank',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.object-format.integer-rank.00182', 'c11',
    'object-format', 'variadic-call', 'integer-rank',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.object-format.integer-rank.00183', 'c17',
    'object-format', 'file-scope', 'integer-rank',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.object-format.integer-rank.00184', 'c23',
    'object-format', 'constant-expression', 'integer-rank',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.object-format.integer-rank.00185', 'gnu90',
    'object-format', 'cross-module', 'integer-rank',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.object-format.integer-rank.00186', 'gnu99',
    'object-format', 'block-scope', 'integer-rank',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.object-format.integer-rank.00187', 'gnu11',
    'object-format', 'runtime-expression', 'integer-rank',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.object-format.integer-rank.00188', 'gnu17',
    'object-format', 'translation-unit', 'integer-rank',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.object-format.integer-rank.00189', 'gnu23',
    'object-format', 'prototype', 'integer-rank',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.integer-rank.00190', 'posix.1-2008',
    'object-format', 'variadic-call', 'integer-rank',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.object-format.integer-rank.00191', 'rcc1',
    'object-format', 'file-scope', 'integer-rank',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.lexing.usual-arithmetic-conversions.00192', 'c90',
    'lexing', 'constant-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'c99.lexing.usual-arithmetic-conversions.00193', 'c99',
    'lexing', 'cross-module', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.lexing.usual-arithmetic-conversions.00194', 'c11',
    'lexing', 'block-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.lexing.usual-arithmetic-conversions.00195', 'c17',
    'lexing', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.lexing.usual-arithmetic-conversions.00196', 'c23',
    'lexing', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.lexing.usual-arithmetic-conversions.00197', 'gnu90',
    'lexing', 'prototype', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.lexing.usual-arithmetic-conversions.00198', 'gnu99',
    'lexing', 'variadic-call', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.lexing.usual-arithmetic-conversions.00199', 'gnu11',
    'lexing', 'file-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.lexing.usual-arithmetic-conversions.00200', 'gnu17',
    'lexing', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.lexing.usual-arithmetic-conversions.00201', 'gnu23',
    'lexing', 'cross-module', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.usual-arithmetic-conversions.00202', 'posix.1-2008',
    'lexing', 'block-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.lexing.usual-arithmetic-conversions.00203', 'rcc1',
    'lexing', 'runtime-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.preprocessing.usual-arithmetic-conversions.00204', 'c90',
    'preprocessing', 'translation-unit', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.preprocessing.usual-arithmetic-conversions.00205', 'c99',
    'preprocessing', 'prototype', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.preprocessing.usual-arithmetic-conversions.00206', 'c11',
    'preprocessing', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.preprocessing.usual-arithmetic-conversions.00207', 'c17',
    'preprocessing', 'file-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.preprocessing.usual-arithmetic-conversions.00208', 'c23',
    'preprocessing', 'constant-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.preprocessing.usual-arithmetic-conversions.00209', 'gnu90',
    'preprocessing', 'cross-module', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.preprocessing.usual-arithmetic-conversions.00210', 'gnu99',
    'preprocessing', 'block-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.preprocessing.usual-arithmetic-conversions.00211', 'gnu11',
    'preprocessing', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.preprocessing.usual-arithmetic-conversions.00212', 'gnu17',
    'preprocessing', 'translation-unit', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.preprocessing.usual-arithmetic-conversions.00213', 'gnu23',
    'preprocessing', 'prototype', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.usual-arithmetic-conversions.00214', 'posix.1-2008',
    'preprocessing', 'variadic-call', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.preprocessing.usual-arithmetic-conversions.00215', 'rcc1',
    'preprocessing', 'file-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.declarations.usual-arithmetic-conversions.00216', 'c90',
    'declarations', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'c99.declarations.usual-arithmetic-conversions.00217', 'c99',
    'declarations', 'cross-module', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.declarations.usual-arithmetic-conversions.00218', 'c11',
    'declarations', 'block-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.declarations.usual-arithmetic-conversions.00219', 'c17',
    'declarations', 'runtime-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.declarations.usual-arithmetic-conversions.00220', 'c23',
    'declarations', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.declarations.usual-arithmetic-conversions.00221', 'gnu90',
    'declarations', 'prototype', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.declarations.usual-arithmetic-conversions.00222', 'gnu99',
    'declarations', 'variadic-call', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.declarations.usual-arithmetic-conversions.00223', 'gnu11',
    'declarations', 'file-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.declarations.usual-arithmetic-conversions.00224', 'gnu17',
    'declarations', 'constant-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.declarations.usual-arithmetic-conversions.00225', 'gnu23',
    'declarations', 'cross-module', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.usual-arithmetic-conversions.00226', 'posix.1-2008',
    'declarations', 'block-scope', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.declarations.usual-arithmetic-conversions.00227', 'rcc1',
    'declarations', 'runtime-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.types.usual-arithmetic-conversions.00228', 'c90',
    'types', 'translation-unit', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'c99.types.usual-arithmetic-conversions.00229', 'c99',
    'types', 'prototype', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.types.usual-arithmetic-conversions.00230', 'c11',
    'types', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.types.usual-arithmetic-conversions.00231', 'c17',
    'types', 'file-scope', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.types.usual-arithmetic-conversions.00232', 'c23',
    'types', 'constant-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.types.usual-arithmetic-conversions.00233', 'gnu90',
    'types', 'cross-module', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.types.usual-arithmetic-conversions.00234', 'gnu99',
    'types', 'block-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.types.usual-arithmetic-conversions.00235', 'gnu11',
    'types', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.types.usual-arithmetic-conversions.00236', 'gnu17',
    'types', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.types.usual-arithmetic-conversions.00237', 'gnu23',
    'types', 'prototype', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.types.usual-arithmetic-conversions.00238', 'posix.1-2008',
    'types', 'variadic-call', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.types.usual-arithmetic-conversions.00239', 'rcc1',
    'types', 'file-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.conversions.usual-arithmetic-conversions.00240', 'c90',
    'conversions', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'c99.conversions.usual-arithmetic-conversions.00241', 'c99',
    'conversions', 'cross-module', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.conversions.usual-arithmetic-conversions.00242', 'c11',
    'conversions', 'block-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.conversions.usual-arithmetic-conversions.00243', 'c17',
    'conversions', 'runtime-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.conversions.usual-arithmetic-conversions.00244', 'c23',
    'conversions', 'translation-unit', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.conversions.usual-arithmetic-conversions.00245', 'gnu90',
    'conversions', 'prototype', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.conversions.usual-arithmetic-conversions.00246', 'gnu99',
    'conversions', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.conversions.usual-arithmetic-conversions.00247', 'gnu11',
    'conversions', 'file-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.conversions.usual-arithmetic-conversions.00248', 'gnu17',
    'conversions', 'constant-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.conversions.usual-arithmetic-conversions.00249', 'gnu23',
    'conversions', 'cross-module', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.usual-arithmetic-conversions.00250', 'posix.1-2008',
    'conversions', 'block-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.conversions.usual-arithmetic-conversions.00251', 'rcc1',
    'conversions', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.expressions.usual-arithmetic-conversions.00252', 'c90',
    'expressions', 'translation-unit', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'c99.expressions.usual-arithmetic-conversions.00253', 'c99',
    'expressions', 'prototype', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.expressions.usual-arithmetic-conversions.00254', 'c11',
    'expressions', 'variadic-call', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.expressions.usual-arithmetic-conversions.00255', 'c17',
    'expressions', 'file-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.expressions.usual-arithmetic-conversions.00256', 'c23',
    'expressions', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.expressions.usual-arithmetic-conversions.00257', 'gnu90',
    'expressions', 'cross-module', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.expressions.usual-arithmetic-conversions.00258', 'gnu99',
    'expressions', 'block-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.expressions.usual-arithmetic-conversions.00259', 'gnu11',
    'expressions', 'runtime-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.expressions.usual-arithmetic-conversions.00260', 'gnu17',
    'expressions', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.expressions.usual-arithmetic-conversions.00261', 'gnu23',
    'expressions', 'prototype', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.usual-arithmetic-conversions.00262', 'posix.1-2008',
    'expressions', 'variadic-call', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.expressions.usual-arithmetic-conversions.00263', 'rcc1',
    'expressions', 'file-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.statements.usual-arithmetic-conversions.00264', 'c90',
    'statements', 'constant-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.statements.usual-arithmetic-conversions.00265', 'c99',
    'statements', 'cross-module', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.statements.usual-arithmetic-conversions.00266', 'c11',
    'statements', 'block-scope', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.statements.usual-arithmetic-conversions.00267', 'c17',
    'statements', 'runtime-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.statements.usual-arithmetic-conversions.00268', 'c23',
    'statements', 'translation-unit', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.statements.usual-arithmetic-conversions.00269', 'gnu90',
    'statements', 'prototype', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.statements.usual-arithmetic-conversions.00270', 'gnu99',
    'statements', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.statements.usual-arithmetic-conversions.00271', 'gnu11',
    'statements', 'file-scope', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.statements.usual-arithmetic-conversions.00272', 'gnu17',
    'statements', 'constant-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.statements.usual-arithmetic-conversions.00273', 'gnu23',
    'statements', 'cross-module', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.statements.usual-arithmetic-conversions.00274', 'posix.1-2008',
    'statements', 'block-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.statements.usual-arithmetic-conversions.00275', 'rcc1',
    'statements', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.functions.usual-arithmetic-conversions.00276', 'c90',
    'functions', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'c99.functions.usual-arithmetic-conversions.00277', 'c99',
    'functions', 'prototype', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.functions.usual-arithmetic-conversions.00278', 'c11',
    'functions', 'variadic-call', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.functions.usual-arithmetic-conversions.00279', 'c17',
    'functions', 'file-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.functions.usual-arithmetic-conversions.00280', 'c23',
    'functions', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.functions.usual-arithmetic-conversions.00281', 'gnu90',
    'functions', 'cross-module', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.functions.usual-arithmetic-conversions.00282', 'gnu99',
    'functions', 'block-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.functions.usual-arithmetic-conversions.00283', 'gnu11',
    'functions', 'runtime-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.functions.usual-arithmetic-conversions.00284', 'gnu17',
    'functions', 'translation-unit', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.functions.usual-arithmetic-conversions.00285', 'gnu23',
    'functions', 'prototype', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.functions.usual-arithmetic-conversions.00286', 'posix.1-2008',
    'functions', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.functions.usual-arithmetic-conversions.00287', 'rcc1',
    'functions', 'file-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.aggregates.usual-arithmetic-conversions.00288', 'c90',
    'aggregates', 'constant-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'c99.aggregates.usual-arithmetic-conversions.00289', 'c99',
    'aggregates', 'cross-module', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.aggregates.usual-arithmetic-conversions.00290', 'c11',
    'aggregates', 'block-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.aggregates.usual-arithmetic-conversions.00291', 'c17',
    'aggregates', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.aggregates.usual-arithmetic-conversions.00292', 'c23',
    'aggregates', 'translation-unit', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.aggregates.usual-arithmetic-conversions.00293', 'gnu90',
    'aggregates', 'prototype', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.aggregates.usual-arithmetic-conversions.00294', 'gnu99',
    'aggregates', 'variadic-call', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.aggregates.usual-arithmetic-conversions.00295', 'gnu11',
    'aggregates', 'file-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.aggregates.usual-arithmetic-conversions.00296', 'gnu17',
    'aggregates', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.aggregates.usual-arithmetic-conversions.00297', 'gnu23',
    'aggregates', 'cross-module', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.usual-arithmetic-conversions.00298', 'posix.1-2008',
    'aggregates', 'block-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.aggregates.usual-arithmetic-conversions.00299', 'rcc1',
    'aggregates', 'runtime-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.initializers.usual-arithmetic-conversions.00300', 'c90',
    'initializers', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'c99.initializers.usual-arithmetic-conversions.00301', 'c99',
    'initializers', 'prototype', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.initializers.usual-arithmetic-conversions.00302', 'c11',
    'initializers', 'variadic-call', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.initializers.usual-arithmetic-conversions.00303', 'c17',
    'initializers', 'file-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.initializers.usual-arithmetic-conversions.00304', 'c23',
    'initializers', 'constant-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.initializers.usual-arithmetic-conversions.00305', 'gnu90',
    'initializers', 'cross-module', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.initializers.usual-arithmetic-conversions.00306', 'gnu99',
    'initializers', 'block-scope', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.initializers.usual-arithmetic-conversions.00307', 'gnu11',
    'initializers', 'runtime-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.initializers.usual-arithmetic-conversions.00308', 'gnu17',
    'initializers', 'translation-unit', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.initializers.usual-arithmetic-conversions.00309', 'gnu23',
    'initializers', 'prototype', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.usual-arithmetic-conversions.00310', 'posix.1-2008',
    'initializers', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.initializers.usual-arithmetic-conversions.00311', 'rcc1',
    'initializers', 'file-scope', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.floating.usual-arithmetic-conversions.00312', 'c90',
    'floating', 'constant-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'c99.floating.usual-arithmetic-conversions.00313', 'c99',
    'floating', 'cross-module', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.floating.usual-arithmetic-conversions.00314', 'c11',
    'floating', 'block-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.floating.usual-arithmetic-conversions.00315', 'c17',
    'floating', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.floating.usual-arithmetic-conversions.00316', 'c23',
    'floating', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.floating.usual-arithmetic-conversions.00317', 'gnu90',
    'floating', 'prototype', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.floating.usual-arithmetic-conversions.00318', 'gnu99',
    'floating', 'variadic-call', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.floating.usual-arithmetic-conversions.00319', 'gnu11',
    'floating', 'file-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.floating.usual-arithmetic-conversions.00320', 'gnu17',
    'floating', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.floating.usual-arithmetic-conversions.00321', 'gnu23',
    'floating', 'cross-module', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.floating.usual-arithmetic-conversions.00322', 'posix.1-2008',
    'floating', 'block-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.floating.usual-arithmetic-conversions.00323', 'rcc1',
    'floating', 'runtime-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.atomics.usual-arithmetic-conversions.00324', 'c90',
    'atomics', 'translation-unit', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.atomics.usual-arithmetic-conversions.00325', 'c99',
    'atomics', 'prototype', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.atomics.usual-arithmetic-conversions.00326', 'c11',
    'atomics', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.atomics.usual-arithmetic-conversions.00327', 'c17',
    'atomics', 'file-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.atomics.usual-arithmetic-conversions.00328', 'c23',
    'atomics', 'constant-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.atomics.usual-arithmetic-conversions.00329', 'gnu90',
    'atomics', 'cross-module', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.atomics.usual-arithmetic-conversions.00330', 'gnu99',
    'atomics', 'block-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.atomics.usual-arithmetic-conversions.00331', 'gnu11',
    'atomics', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.atomics.usual-arithmetic-conversions.00332', 'gnu17',
    'atomics', 'translation-unit', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.atomics.usual-arithmetic-conversions.00333', 'gnu23',
    'atomics', 'prototype', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.usual-arithmetic-conversions.00334', 'posix.1-2008',
    'atomics', 'variadic-call', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.atomics.usual-arithmetic-conversions.00335', 'rcc1',
    'atomics', 'file-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.variadics.usual-arithmetic-conversions.00336', 'c90',
    'variadics', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'c99.variadics.usual-arithmetic-conversions.00337', 'c99',
    'variadics', 'cross-module', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.variadics.usual-arithmetic-conversions.00338', 'c11',
    'variadics', 'block-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.variadics.usual-arithmetic-conversions.00339', 'c17',
    'variadics', 'runtime-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.variadics.usual-arithmetic-conversions.00340', 'c23',
    'variadics', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.variadics.usual-arithmetic-conversions.00341', 'gnu90',
    'variadics', 'prototype', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.variadics.usual-arithmetic-conversions.00342', 'gnu99',
    'variadics', 'variadic-call', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.variadics.usual-arithmetic-conversions.00343', 'gnu11',
    'variadics', 'file-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.variadics.usual-arithmetic-conversions.00344', 'gnu17',
    'variadics', 'constant-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.variadics.usual-arithmetic-conversions.00345', 'gnu23',
    'variadics', 'cross-module', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.usual-arithmetic-conversions.00346', 'posix.1-2008',
    'variadics', 'block-scope', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.variadics.usual-arithmetic-conversions.00347', 'rcc1',
    'variadics', 'runtime-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.library.usual-arithmetic-conversions.00348', 'c90',
    'library', 'translation-unit', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'c99.library.usual-arithmetic-conversions.00349', 'c99',
    'library', 'prototype', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.library.usual-arithmetic-conversions.00350', 'c11',
    'library', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.library.usual-arithmetic-conversions.00351', 'c17',
    'library', 'file-scope', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.library.usual-arithmetic-conversions.00352', 'c23',
    'library', 'constant-expression', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.library.usual-arithmetic-conversions.00353', 'gnu90',
    'library', 'cross-module', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.library.usual-arithmetic-conversions.00354', 'gnu99',
    'library', 'block-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.library.usual-arithmetic-conversions.00355', 'gnu11',
    'library', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.library.usual-arithmetic-conversions.00356', 'gnu17',
    'library', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.library.usual-arithmetic-conversions.00357', 'gnu23',
    'library', 'prototype', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.library.usual-arithmetic-conversions.00358', 'posix.1-2008',
    'library', 'variadic-call', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.library.usual-arithmetic-conversions.00359', 'rcc1',
    'library', 'file-scope', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.abi.usual-arithmetic-conversions.00360', 'c90',
    'abi', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'c99.abi.usual-arithmetic-conversions.00361', 'c99',
    'abi', 'cross-module', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.abi.usual-arithmetic-conversions.00362', 'c11',
    'abi', 'block-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.abi.usual-arithmetic-conversions.00363', 'c17',
    'abi', 'runtime-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.abi.usual-arithmetic-conversions.00364', 'c23',
    'abi', 'translation-unit', 'usual-arithmetic-conversions',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.abi.usual-arithmetic-conversions.00365', 'gnu90',
    'abi', 'prototype', 'usual-arithmetic-conversions',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.abi.usual-arithmetic-conversions.00366', 'gnu99',
    'abi', 'variadic-call', 'usual-arithmetic-conversions',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.abi.usual-arithmetic-conversions.00367', 'gnu11',
    'abi', 'file-scope', 'usual-arithmetic-conversions',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.abi.usual-arithmetic-conversions.00368', 'gnu17',
    'abi', 'constant-expression', 'usual-arithmetic-conversions',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.abi.usual-arithmetic-conversions.00369', 'gnu23',
    'abi', 'cross-module', 'usual-arithmetic-conversions',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.abi.usual-arithmetic-conversions.00370', 'posix.1-2008',
    'abi', 'block-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.abi.usual-arithmetic-conversions.00371', 'rcc1',
    'abi', 'runtime-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.object-format.usual-arithmetic-conversions.00372', 'c90',
    'object-format', 'translation-unit', 'usual-arithmetic-conversions',
    'execute-pass', 'required');
  AddCase(Result, 'c99.object-format.usual-arithmetic-conversions.00373', 'c99',
    'object-format', 'prototype', 'usual-arithmetic-conversions',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.object-format.usual-arithmetic-conversions.00374', 'c11',
    'object-format', 'variadic-call', 'usual-arithmetic-conversions',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.object-format.usual-arithmetic-conversions.00375', 'c17',
    'object-format', 'file-scope', 'usual-arithmetic-conversions',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.object-format.usual-arithmetic-conversions.00376', 'c23',
    'object-format', 'constant-expression', 'usual-arithmetic-conversions',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.object-format.usual-arithmetic-conversions.00377', 'gnu90',
    'object-format', 'cross-module', 'usual-arithmetic-conversions',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.object-format.usual-arithmetic-conversions.00378', 'gnu99',
    'object-format', 'block-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.object-format.usual-arithmetic-conversions.00379', 'gnu11',
    'object-format', 'runtime-expression', 'usual-arithmetic-conversions',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.object-format.usual-arithmetic-conversions.00380', 'gnu17',
    'object-format', 'translation-unit', 'usual-arithmetic-conversions',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.object-format.usual-arithmetic-conversions.00381', 'gnu23',
    'object-format', 'prototype', 'usual-arithmetic-conversions',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.usual-arithmetic-conversions.00382', 'posix.1-2008',
    'object-format', 'variadic-call', 'usual-arithmetic-conversions',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.object-format.usual-arithmetic-conversions.00383', 'rcc1',
    'object-format', 'file-scope', 'usual-arithmetic-conversions',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.lexing.pointer-qualification.00384', 'c90',
    'lexing', 'runtime-expression', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.lexing.pointer-qualification.00385', 'c99',
    'lexing', 'translation-unit', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.lexing.pointer-qualification.00386', 'c11',
    'lexing', 'prototype', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.lexing.pointer-qualification.00387', 'c17',
    'lexing', 'variadic-call', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.lexing.pointer-qualification.00388', 'c23',
    'lexing', 'file-scope', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.lexing.pointer-qualification.00389', 'gnu90',
    'lexing', 'constant-expression', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.lexing.pointer-qualification.00390', 'gnu99',
    'lexing', 'cross-module', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.lexing.pointer-qualification.00391', 'gnu11',
    'lexing', 'block-scope', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.lexing.pointer-qualification.00392', 'gnu17',
    'lexing', 'runtime-expression', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.lexing.pointer-qualification.00393', 'gnu23',
    'lexing', 'translation-unit', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.pointer-qualification.00394', 'posix.1-2008',
    'lexing', 'prototype', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.lexing.pointer-qualification.00395', 'rcc1',
    'lexing', 'variadic-call', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.preprocessing.pointer-qualification.00396', 'c90',
    'preprocessing', 'file-scope', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'c99.preprocessing.pointer-qualification.00397', 'c99',
    'preprocessing', 'constant-expression', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.preprocessing.pointer-qualification.00398', 'c11',
    'preprocessing', 'cross-module', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.preprocessing.pointer-qualification.00399', 'c17',
    'preprocessing', 'block-scope', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.preprocessing.pointer-qualification.00400', 'c23',
    'preprocessing', 'runtime-expression', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.preprocessing.pointer-qualification.00401', 'gnu90',
    'preprocessing', 'translation-unit', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.preprocessing.pointer-qualification.00402', 'gnu99',
    'preprocessing', 'prototype', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.preprocessing.pointer-qualification.00403', 'gnu11',
    'preprocessing', 'variadic-call', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.preprocessing.pointer-qualification.00404', 'gnu17',
    'preprocessing', 'file-scope', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.preprocessing.pointer-qualification.00405', 'gnu23',
    'preprocessing', 'constant-expression', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.pointer-qualification.00406', 'posix.1-2008',
    'preprocessing', 'cross-module', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.preprocessing.pointer-qualification.00407', 'rcc1',
    'preprocessing', 'block-scope', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.declarations.pointer-qualification.00408', 'c90',
    'declarations', 'runtime-expression', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'c99.declarations.pointer-qualification.00409', 'c99',
    'declarations', 'translation-unit', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.declarations.pointer-qualification.00410', 'c11',
    'declarations', 'prototype', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.declarations.pointer-qualification.00411', 'c17',
    'declarations', 'variadic-call', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.declarations.pointer-qualification.00412', 'c23',
    'declarations', 'file-scope', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.declarations.pointer-qualification.00413', 'gnu90',
    'declarations', 'constant-expression', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.declarations.pointer-qualification.00414', 'gnu99',
    'declarations', 'cross-module', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.declarations.pointer-qualification.00415', 'gnu11',
    'declarations', 'block-scope', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.declarations.pointer-qualification.00416', 'gnu17',
    'declarations', 'runtime-expression', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.declarations.pointer-qualification.00417', 'gnu23',
    'declarations', 'translation-unit', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.pointer-qualification.00418', 'posix.1-2008',
    'declarations', 'prototype', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.declarations.pointer-qualification.00419', 'rcc1',
    'declarations', 'variadic-call', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.types.pointer-qualification.00420', 'c90',
    'types', 'file-scope', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'c99.types.pointer-qualification.00421', 'c99',
    'types', 'constant-expression', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.types.pointer-qualification.00422', 'c11',
    'types', 'cross-module', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.types.pointer-qualification.00423', 'c17',
    'types', 'block-scope', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.types.pointer-qualification.00424', 'c23',
    'types', 'runtime-expression', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.types.pointer-qualification.00425', 'gnu90',
    'types', 'translation-unit', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.types.pointer-qualification.00426', 'gnu99',
    'types', 'prototype', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.types.pointer-qualification.00427', 'gnu11',
    'types', 'variadic-call', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.types.pointer-qualification.00428', 'gnu17',
    'types', 'file-scope', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.types.pointer-qualification.00429', 'gnu23',
    'types', 'constant-expression', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.types.pointer-qualification.00430', 'posix.1-2008',
    'types', 'cross-module', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.types.pointer-qualification.00431', 'rcc1',
    'types', 'block-scope', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.conversions.pointer-qualification.00432', 'c90',
    'conversions', 'runtime-expression', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'c99.conversions.pointer-qualification.00433', 'c99',
    'conversions', 'translation-unit', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.conversions.pointer-qualification.00434', 'c11',
    'conversions', 'prototype', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.conversions.pointer-qualification.00435', 'c17',
    'conversions', 'variadic-call', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.conversions.pointer-qualification.00436', 'c23',
    'conversions', 'file-scope', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.conversions.pointer-qualification.00437', 'gnu90',
    'conversions', 'constant-expression', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.conversions.pointer-qualification.00438', 'gnu99',
    'conversions', 'cross-module', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.conversions.pointer-qualification.00439', 'gnu11',
    'conversions', 'block-scope', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.conversions.pointer-qualification.00440', 'gnu17',
    'conversions', 'runtime-expression', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.conversions.pointer-qualification.00441', 'gnu23',
    'conversions', 'translation-unit', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.pointer-qualification.00442', 'posix.1-2008',
    'conversions', 'prototype', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.conversions.pointer-qualification.00443', 'rcc1',
    'conversions', 'variadic-call', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.expressions.pointer-qualification.00444', 'c90',
    'expressions', 'file-scope', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.expressions.pointer-qualification.00445', 'c99',
    'expressions', 'constant-expression', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.expressions.pointer-qualification.00446', 'c11',
    'expressions', 'cross-module', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.expressions.pointer-qualification.00447', 'c17',
    'expressions', 'block-scope', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.expressions.pointer-qualification.00448', 'c23',
    'expressions', 'runtime-expression', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.expressions.pointer-qualification.00449', 'gnu90',
    'expressions', 'translation-unit', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.expressions.pointer-qualification.00450', 'gnu99',
    'expressions', 'prototype', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.expressions.pointer-qualification.00451', 'gnu11',
    'expressions', 'variadic-call', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.expressions.pointer-qualification.00452', 'gnu17',
    'expressions', 'file-scope', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.expressions.pointer-qualification.00453', 'gnu23',
    'expressions', 'constant-expression', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.pointer-qualification.00454', 'posix.1-2008',
    'expressions', 'cross-module', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.expressions.pointer-qualification.00455', 'rcc1',
    'expressions', 'block-scope', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.statements.pointer-qualification.00456', 'c90',
    'statements', 'runtime-expression', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'c99.statements.pointer-qualification.00457', 'c99',
    'statements', 'translation-unit', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.statements.pointer-qualification.00458', 'c11',
    'statements', 'prototype', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.statements.pointer-qualification.00459', 'c17',
    'statements', 'variadic-call', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.statements.pointer-qualification.00460', 'c23',
    'statements', 'file-scope', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.statements.pointer-qualification.00461', 'gnu90',
    'statements', 'constant-expression', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.statements.pointer-qualification.00462', 'gnu99',
    'statements', 'cross-module', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.statements.pointer-qualification.00463', 'gnu11',
    'statements', 'block-scope', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.statements.pointer-qualification.00464', 'gnu17',
    'statements', 'runtime-expression', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.statements.pointer-qualification.00465', 'gnu23',
    'statements', 'translation-unit', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.statements.pointer-qualification.00466', 'posix.1-2008',
    'statements', 'prototype', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.statements.pointer-qualification.00467', 'rcc1',
    'statements', 'variadic-call', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.functions.pointer-qualification.00468', 'c90',
    'functions', 'file-scope', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'c99.functions.pointer-qualification.00469', 'c99',
    'functions', 'constant-expression', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.functions.pointer-qualification.00470', 'c11',
    'functions', 'cross-module', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.functions.pointer-qualification.00471', 'c17',
    'functions', 'block-scope', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.functions.pointer-qualification.00472', 'c23',
    'functions', 'runtime-expression', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.functions.pointer-qualification.00473', 'gnu90',
    'functions', 'translation-unit', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.functions.pointer-qualification.00474', 'gnu99',
    'functions', 'prototype', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.functions.pointer-qualification.00475', 'gnu11',
    'functions', 'variadic-call', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.functions.pointer-qualification.00476', 'gnu17',
    'functions', 'file-scope', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.functions.pointer-qualification.00477', 'gnu23',
    'functions', 'constant-expression', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.functions.pointer-qualification.00478', 'posix.1-2008',
    'functions', 'cross-module', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.functions.pointer-qualification.00479', 'rcc1',
    'functions', 'block-scope', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.aggregates.pointer-qualification.00480', 'c90',
    'aggregates', 'runtime-expression', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'c99.aggregates.pointer-qualification.00481', 'c99',
    'aggregates', 'translation-unit', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.aggregates.pointer-qualification.00482', 'c11',
    'aggregates', 'prototype', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.aggregates.pointer-qualification.00483', 'c17',
    'aggregates', 'variadic-call', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.aggregates.pointer-qualification.00484', 'c23',
    'aggregates', 'file-scope', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.aggregates.pointer-qualification.00485', 'gnu90',
    'aggregates', 'constant-expression', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.aggregates.pointer-qualification.00486', 'gnu99',
    'aggregates', 'cross-module', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.aggregates.pointer-qualification.00487', 'gnu11',
    'aggregates', 'block-scope', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.aggregates.pointer-qualification.00488', 'gnu17',
    'aggregates', 'runtime-expression', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.aggregates.pointer-qualification.00489', 'gnu23',
    'aggregates', 'translation-unit', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.pointer-qualification.00490', 'posix.1-2008',
    'aggregates', 'prototype', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.aggregates.pointer-qualification.00491', 'rcc1',
    'aggregates', 'variadic-call', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.initializers.pointer-qualification.00492', 'c90',
    'initializers', 'file-scope', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'c99.initializers.pointer-qualification.00493', 'c99',
    'initializers', 'constant-expression', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.initializers.pointer-qualification.00494', 'c11',
    'initializers', 'cross-module', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.initializers.pointer-qualification.00495', 'c17',
    'initializers', 'block-scope', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.initializers.pointer-qualification.00496', 'c23',
    'initializers', 'runtime-expression', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.initializers.pointer-qualification.00497', 'gnu90',
    'initializers', 'translation-unit', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.initializers.pointer-qualification.00498', 'gnu99',
    'initializers', 'prototype', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.initializers.pointer-qualification.00499', 'gnu11',
    'initializers', 'variadic-call', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.initializers.pointer-qualification.00500', 'gnu17',
    'initializers', 'file-scope', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.initializers.pointer-qualification.00501', 'gnu23',
    'initializers', 'constant-expression', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.pointer-qualification.00502', 'posix.1-2008',
    'initializers', 'cross-module', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.initializers.pointer-qualification.00503', 'rcc1',
    'initializers', 'block-scope', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.floating.pointer-qualification.00504', 'c90',
    'floating', 'runtime-expression', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.floating.pointer-qualification.00505', 'c99',
    'floating', 'translation-unit', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.floating.pointer-qualification.00506', 'c11',
    'floating', 'prototype', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.floating.pointer-qualification.00507', 'c17',
    'floating', 'variadic-call', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.floating.pointer-qualification.00508', 'c23',
    'floating', 'file-scope', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.floating.pointer-qualification.00509', 'gnu90',
    'floating', 'constant-expression', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.floating.pointer-qualification.00510', 'gnu99',
    'floating', 'cross-module', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.floating.pointer-qualification.00511', 'gnu11',
    'floating', 'block-scope', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.floating.pointer-qualification.00512', 'gnu17',
    'floating', 'runtime-expression', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.floating.pointer-qualification.00513', 'gnu23',
    'floating', 'translation-unit', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.floating.pointer-qualification.00514', 'posix.1-2008',
    'floating', 'prototype', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.floating.pointer-qualification.00515', 'rcc1',
    'floating', 'variadic-call', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.atomics.pointer-qualification.00516', 'c90',
    'atomics', 'file-scope', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'c99.atomics.pointer-qualification.00517', 'c99',
    'atomics', 'constant-expression', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.atomics.pointer-qualification.00518', 'c11',
    'atomics', 'cross-module', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.atomics.pointer-qualification.00519', 'c17',
    'atomics', 'block-scope', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.atomics.pointer-qualification.00520', 'c23',
    'atomics', 'runtime-expression', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.atomics.pointer-qualification.00521', 'gnu90',
    'atomics', 'translation-unit', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.atomics.pointer-qualification.00522', 'gnu99',
    'atomics', 'prototype', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.atomics.pointer-qualification.00523', 'gnu11',
    'atomics', 'variadic-call', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.atomics.pointer-qualification.00524', 'gnu17',
    'atomics', 'file-scope', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.atomics.pointer-qualification.00525', 'gnu23',
    'atomics', 'constant-expression', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.pointer-qualification.00526', 'posix.1-2008',
    'atomics', 'cross-module', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.atomics.pointer-qualification.00527', 'rcc1',
    'atomics', 'block-scope', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.variadics.pointer-qualification.00528', 'c90',
    'variadics', 'runtime-expression', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'c99.variadics.pointer-qualification.00529', 'c99',
    'variadics', 'translation-unit', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.variadics.pointer-qualification.00530', 'c11',
    'variadics', 'prototype', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.variadics.pointer-qualification.00531', 'c17',
    'variadics', 'variadic-call', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.variadics.pointer-qualification.00532', 'c23',
    'variadics', 'file-scope', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.variadics.pointer-qualification.00533', 'gnu90',
    'variadics', 'constant-expression', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.variadics.pointer-qualification.00534', 'gnu99',
    'variadics', 'cross-module', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.variadics.pointer-qualification.00535', 'gnu11',
    'variadics', 'block-scope', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.variadics.pointer-qualification.00536', 'gnu17',
    'variadics', 'runtime-expression', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.variadics.pointer-qualification.00537', 'gnu23',
    'variadics', 'translation-unit', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.pointer-qualification.00538', 'posix.1-2008',
    'variadics', 'prototype', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.variadics.pointer-qualification.00539', 'rcc1',
    'variadics', 'variadic-call', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.library.pointer-qualification.00540', 'c90',
    'library', 'file-scope', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'c99.library.pointer-qualification.00541', 'c99',
    'library', 'constant-expression', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.library.pointer-qualification.00542', 'c11',
    'library', 'cross-module', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.library.pointer-qualification.00543', 'c17',
    'library', 'block-scope', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.library.pointer-qualification.00544', 'c23',
    'library', 'runtime-expression', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.library.pointer-qualification.00545', 'gnu90',
    'library', 'translation-unit', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.library.pointer-qualification.00546', 'gnu99',
    'library', 'prototype', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.library.pointer-qualification.00547', 'gnu11',
    'library', 'variadic-call', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.library.pointer-qualification.00548', 'gnu17',
    'library', 'file-scope', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.library.pointer-qualification.00549', 'gnu23',
    'library', 'constant-expression', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.library.pointer-qualification.00550', 'posix.1-2008',
    'library', 'cross-module', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.library.pointer-qualification.00551', 'rcc1',
    'library', 'block-scope', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.abi.pointer-qualification.00552', 'c90',
    'abi', 'runtime-expression', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'c99.abi.pointer-qualification.00553', 'c99',
    'abi', 'translation-unit', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.abi.pointer-qualification.00554', 'c11',
    'abi', 'prototype', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.abi.pointer-qualification.00555', 'c17',
    'abi', 'variadic-call', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.abi.pointer-qualification.00556', 'c23',
    'abi', 'file-scope', 'pointer-qualification',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.abi.pointer-qualification.00557', 'gnu90',
    'abi', 'constant-expression', 'pointer-qualification',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.abi.pointer-qualification.00558', 'gnu99',
    'abi', 'cross-module', 'pointer-qualification',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.abi.pointer-qualification.00559', 'gnu11',
    'abi', 'block-scope', 'pointer-qualification',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.abi.pointer-qualification.00560', 'gnu17',
    'abi', 'runtime-expression', 'pointer-qualification',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.abi.pointer-qualification.00561', 'gnu23',
    'abi', 'translation-unit', 'pointer-qualification',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.abi.pointer-qualification.00562', 'posix.1-2008',
    'abi', 'prototype', 'pointer-qualification',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.abi.pointer-qualification.00563', 'rcc1',
    'abi', 'variadic-call', 'pointer-qualification',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.object-format.pointer-qualification.00564', 'c90',
    'object-format', 'file-scope', 'pointer-qualification',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.object-format.pointer-qualification.00565', 'c99',
    'object-format', 'constant-expression', 'pointer-qualification',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.object-format.pointer-qualification.00566', 'c11',
    'object-format', 'cross-module', 'pointer-qualification',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.object-format.pointer-qualification.00567', 'c17',
    'object-format', 'block-scope', 'pointer-qualification',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.object-format.pointer-qualification.00568', 'c23',
    'object-format', 'runtime-expression', 'pointer-qualification',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.object-format.pointer-qualification.00569', 'gnu90',
    'object-format', 'translation-unit', 'pointer-qualification',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.object-format.pointer-qualification.00570', 'gnu99',
    'object-format', 'prototype', 'pointer-qualification',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.object-format.pointer-qualification.00571', 'gnu11',
    'object-format', 'variadic-call', 'pointer-qualification',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.object-format.pointer-qualification.00572', 'gnu17',
    'object-format', 'file-scope', 'pointer-qualification',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.object-format.pointer-qualification.00573', 'gnu23',
    'object-format', 'constant-expression', 'pointer-qualification',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.pointer-qualification.00574', 'posix.1-2008',
    'object-format', 'cross-module', 'pointer-qualification',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.object-format.pointer-qualification.00575', 'rcc1',
    'object-format', 'block-scope', 'pointer-qualification',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.lexing.array-decay.00576', 'c90',
    'lexing', 'prototype', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'c99.lexing.array-decay.00577', 'c99',
    'lexing', 'variadic-call', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.lexing.array-decay.00578', 'c11',
    'lexing', 'file-scope', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.lexing.array-decay.00579', 'c17',
    'lexing', 'constant-expression', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.lexing.array-decay.00580', 'c23',
    'lexing', 'cross-module', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.lexing.array-decay.00581', 'gnu90',
    'lexing', 'block-scope', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.lexing.array-decay.00582', 'gnu99',
    'lexing', 'runtime-expression', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.lexing.array-decay.00583', 'gnu11',
    'lexing', 'translation-unit', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.lexing.array-decay.00584', 'gnu17',
    'lexing', 'prototype', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.lexing.array-decay.00585', 'gnu23',
    'lexing', 'variadic-call', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.array-decay.00586', 'posix.1-2008',
    'lexing', 'file-scope', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.lexing.array-decay.00587', 'rcc1',
    'lexing', 'constant-expression', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.preprocessing.array-decay.00588', 'c90',
    'preprocessing', 'cross-module', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'c99.preprocessing.array-decay.00589', 'c99',
    'preprocessing', 'block-scope', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.preprocessing.array-decay.00590', 'c11',
    'preprocessing', 'runtime-expression', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.preprocessing.array-decay.00591', 'c17',
    'preprocessing', 'translation-unit', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.preprocessing.array-decay.00592', 'c23',
    'preprocessing', 'prototype', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.preprocessing.array-decay.00593', 'gnu90',
    'preprocessing', 'variadic-call', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.preprocessing.array-decay.00594', 'gnu99',
    'preprocessing', 'file-scope', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.preprocessing.array-decay.00595', 'gnu11',
    'preprocessing', 'constant-expression', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.preprocessing.array-decay.00596', 'gnu17',
    'preprocessing', 'cross-module', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.preprocessing.array-decay.00597', 'gnu23',
    'preprocessing', 'block-scope', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.array-decay.00598', 'posix.1-2008',
    'preprocessing', 'runtime-expression', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.preprocessing.array-decay.00599', 'rcc1',
    'preprocessing', 'translation-unit', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.declarations.array-decay.00600', 'c90',
    'declarations', 'prototype', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'c99.declarations.array-decay.00601', 'c99',
    'declarations', 'variadic-call', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.declarations.array-decay.00602', 'c11',
    'declarations', 'file-scope', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.declarations.array-decay.00603', 'c17',
    'declarations', 'constant-expression', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.declarations.array-decay.00604', 'c23',
    'declarations', 'cross-module', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.declarations.array-decay.00605', 'gnu90',
    'declarations', 'block-scope', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.declarations.array-decay.00606', 'gnu99',
    'declarations', 'runtime-expression', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.declarations.array-decay.00607', 'gnu11',
    'declarations', 'translation-unit', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.declarations.array-decay.00608', 'gnu17',
    'declarations', 'prototype', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.declarations.array-decay.00609', 'gnu23',
    'declarations', 'variadic-call', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.array-decay.00610', 'posix.1-2008',
    'declarations', 'file-scope', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.declarations.array-decay.00611', 'rcc1',
    'declarations', 'constant-expression', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.types.array-decay.00612', 'c90',
    'types', 'cross-module', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'c99.types.array-decay.00613', 'c99',
    'types', 'block-scope', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.types.array-decay.00614', 'c11',
    'types', 'runtime-expression', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.types.array-decay.00615', 'c17',
    'types', 'translation-unit', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.types.array-decay.00616', 'c23',
    'types', 'prototype', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.types.array-decay.00617', 'gnu90',
    'types', 'variadic-call', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.types.array-decay.00618', 'gnu99',
    'types', 'file-scope', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.types.array-decay.00619', 'gnu11',
    'types', 'constant-expression', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.types.array-decay.00620', 'gnu17',
    'types', 'cross-module', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.types.array-decay.00621', 'gnu23',
    'types', 'block-scope', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.types.array-decay.00622', 'posix.1-2008',
    'types', 'runtime-expression', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.types.array-decay.00623', 'rcc1',
    'types', 'translation-unit', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.conversions.array-decay.00624', 'c90',
    'conversions', 'prototype', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.conversions.array-decay.00625', 'c99',
    'conversions', 'variadic-call', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.conversions.array-decay.00626', 'c11',
    'conversions', 'file-scope', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.conversions.array-decay.00627', 'c17',
    'conversions', 'constant-expression', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.conversions.array-decay.00628', 'c23',
    'conversions', 'cross-module', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.conversions.array-decay.00629', 'gnu90',
    'conversions', 'block-scope', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.conversions.array-decay.00630', 'gnu99',
    'conversions', 'runtime-expression', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.conversions.array-decay.00631', 'gnu11',
    'conversions', 'translation-unit', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.conversions.array-decay.00632', 'gnu17',
    'conversions', 'prototype', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.conversions.array-decay.00633', 'gnu23',
    'conversions', 'variadic-call', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.array-decay.00634', 'posix.1-2008',
    'conversions', 'file-scope', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.conversions.array-decay.00635', 'rcc1',
    'conversions', 'constant-expression', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.expressions.array-decay.00636', 'c90',
    'expressions', 'cross-module', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'c99.expressions.array-decay.00637', 'c99',
    'expressions', 'block-scope', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.expressions.array-decay.00638', 'c11',
    'expressions', 'runtime-expression', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.expressions.array-decay.00639', 'c17',
    'expressions', 'translation-unit', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.expressions.array-decay.00640', 'c23',
    'expressions', 'prototype', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.expressions.array-decay.00641', 'gnu90',
    'expressions', 'variadic-call', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.expressions.array-decay.00642', 'gnu99',
    'expressions', 'file-scope', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.expressions.array-decay.00643', 'gnu11',
    'expressions', 'constant-expression', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.expressions.array-decay.00644', 'gnu17',
    'expressions', 'cross-module', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.expressions.array-decay.00645', 'gnu23',
    'expressions', 'block-scope', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.array-decay.00646', 'posix.1-2008',
    'expressions', 'runtime-expression', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.expressions.array-decay.00647', 'rcc1',
    'expressions', 'translation-unit', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.statements.array-decay.00648', 'c90',
    'statements', 'prototype', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'c99.statements.array-decay.00649', 'c99',
    'statements', 'variadic-call', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.statements.array-decay.00650', 'c11',
    'statements', 'file-scope', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.statements.array-decay.00651', 'c17',
    'statements', 'constant-expression', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.statements.array-decay.00652', 'c23',
    'statements', 'cross-module', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.statements.array-decay.00653', 'gnu90',
    'statements', 'block-scope', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.statements.array-decay.00654', 'gnu99',
    'statements', 'runtime-expression', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.statements.array-decay.00655', 'gnu11',
    'statements', 'translation-unit', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.statements.array-decay.00656', 'gnu17',
    'statements', 'prototype', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.statements.array-decay.00657', 'gnu23',
    'statements', 'variadic-call', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.statements.array-decay.00658', 'posix.1-2008',
    'statements', 'file-scope', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.statements.array-decay.00659', 'rcc1',
    'statements', 'constant-expression', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.functions.array-decay.00660', 'c90',
    'functions', 'cross-module', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'c99.functions.array-decay.00661', 'c99',
    'functions', 'block-scope', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.functions.array-decay.00662', 'c11',
    'functions', 'runtime-expression', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.functions.array-decay.00663', 'c17',
    'functions', 'translation-unit', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.functions.array-decay.00664', 'c23',
    'functions', 'prototype', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.functions.array-decay.00665', 'gnu90',
    'functions', 'variadic-call', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.functions.array-decay.00666', 'gnu99',
    'functions', 'file-scope', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.functions.array-decay.00667', 'gnu11',
    'functions', 'constant-expression', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.functions.array-decay.00668', 'gnu17',
    'functions', 'cross-module', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.functions.array-decay.00669', 'gnu23',
    'functions', 'block-scope', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.functions.array-decay.00670', 'posix.1-2008',
    'functions', 'runtime-expression', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.functions.array-decay.00671', 'rcc1',
    'functions', 'translation-unit', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.aggregates.array-decay.00672', 'c90',
    'aggregates', 'prototype', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'c99.aggregates.array-decay.00673', 'c99',
    'aggregates', 'variadic-call', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.aggregates.array-decay.00674', 'c11',
    'aggregates', 'file-scope', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.aggregates.array-decay.00675', 'c17',
    'aggregates', 'constant-expression', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.aggregates.array-decay.00676', 'c23',
    'aggregates', 'cross-module', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.aggregates.array-decay.00677', 'gnu90',
    'aggregates', 'block-scope', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.aggregates.array-decay.00678', 'gnu99',
    'aggregates', 'runtime-expression', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.aggregates.array-decay.00679', 'gnu11',
    'aggregates', 'translation-unit', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.aggregates.array-decay.00680', 'gnu17',
    'aggregates', 'prototype', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.aggregates.array-decay.00681', 'gnu23',
    'aggregates', 'variadic-call', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.array-decay.00682', 'posix.1-2008',
    'aggregates', 'file-scope', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.aggregates.array-decay.00683', 'rcc1',
    'aggregates', 'constant-expression', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.initializers.array-decay.00684', 'c90',
    'initializers', 'cross-module', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.initializers.array-decay.00685', 'c99',
    'initializers', 'block-scope', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.initializers.array-decay.00686', 'c11',
    'initializers', 'runtime-expression', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.initializers.array-decay.00687', 'c17',
    'initializers', 'translation-unit', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.initializers.array-decay.00688', 'c23',
    'initializers', 'prototype', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.initializers.array-decay.00689', 'gnu90',
    'initializers', 'variadic-call', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.initializers.array-decay.00690', 'gnu99',
    'initializers', 'file-scope', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.initializers.array-decay.00691', 'gnu11',
    'initializers', 'constant-expression', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.initializers.array-decay.00692', 'gnu17',
    'initializers', 'cross-module', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.initializers.array-decay.00693', 'gnu23',
    'initializers', 'block-scope', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.array-decay.00694', 'posix.1-2008',
    'initializers', 'runtime-expression', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.initializers.array-decay.00695', 'rcc1',
    'initializers', 'translation-unit', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.floating.array-decay.00696', 'c90',
    'floating', 'prototype', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'c99.floating.array-decay.00697', 'c99',
    'floating', 'variadic-call', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.floating.array-decay.00698', 'c11',
    'floating', 'file-scope', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.floating.array-decay.00699', 'c17',
    'floating', 'constant-expression', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.floating.array-decay.00700', 'c23',
    'floating', 'cross-module', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.floating.array-decay.00701', 'gnu90',
    'floating', 'block-scope', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.floating.array-decay.00702', 'gnu99',
    'floating', 'runtime-expression', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.floating.array-decay.00703', 'gnu11',
    'floating', 'translation-unit', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.floating.array-decay.00704', 'gnu17',
    'floating', 'prototype', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.floating.array-decay.00705', 'gnu23',
    'floating', 'variadic-call', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.floating.array-decay.00706', 'posix.1-2008',
    'floating', 'file-scope', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.floating.array-decay.00707', 'rcc1',
    'floating', 'constant-expression', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.atomics.array-decay.00708', 'c90',
    'atomics', 'cross-module', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'c99.atomics.array-decay.00709', 'c99',
    'atomics', 'block-scope', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.atomics.array-decay.00710', 'c11',
    'atomics', 'runtime-expression', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.atomics.array-decay.00711', 'c17',
    'atomics', 'translation-unit', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.atomics.array-decay.00712', 'c23',
    'atomics', 'prototype', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.atomics.array-decay.00713', 'gnu90',
    'atomics', 'variadic-call', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.atomics.array-decay.00714', 'gnu99',
    'atomics', 'file-scope', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.atomics.array-decay.00715', 'gnu11',
    'atomics', 'constant-expression', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.atomics.array-decay.00716', 'gnu17',
    'atomics', 'cross-module', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.atomics.array-decay.00717', 'gnu23',
    'atomics', 'block-scope', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.array-decay.00718', 'posix.1-2008',
    'atomics', 'runtime-expression', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.atomics.array-decay.00719', 'rcc1',
    'atomics', 'translation-unit', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.variadics.array-decay.00720', 'c90',
    'variadics', 'prototype', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'c99.variadics.array-decay.00721', 'c99',
    'variadics', 'variadic-call', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.variadics.array-decay.00722', 'c11',
    'variadics', 'file-scope', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.variadics.array-decay.00723', 'c17',
    'variadics', 'constant-expression', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.variadics.array-decay.00724', 'c23',
    'variadics', 'cross-module', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.variadics.array-decay.00725', 'gnu90',
    'variadics', 'block-scope', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.variadics.array-decay.00726', 'gnu99',
    'variadics', 'runtime-expression', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.variadics.array-decay.00727', 'gnu11',
    'variadics', 'translation-unit', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.variadics.array-decay.00728', 'gnu17',
    'variadics', 'prototype', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.variadics.array-decay.00729', 'gnu23',
    'variadics', 'variadic-call', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.array-decay.00730', 'posix.1-2008',
    'variadics', 'file-scope', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.variadics.array-decay.00731', 'rcc1',
    'variadics', 'constant-expression', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.library.array-decay.00732', 'c90',
    'library', 'cross-module', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'c99.library.array-decay.00733', 'c99',
    'library', 'block-scope', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.library.array-decay.00734', 'c11',
    'library', 'runtime-expression', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.library.array-decay.00735', 'c17',
    'library', 'translation-unit', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.library.array-decay.00736', 'c23',
    'library', 'prototype', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.library.array-decay.00737', 'gnu90',
    'library', 'variadic-call', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.library.array-decay.00738', 'gnu99',
    'library', 'file-scope', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.library.array-decay.00739', 'gnu11',
    'library', 'constant-expression', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.library.array-decay.00740', 'gnu17',
    'library', 'cross-module', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.library.array-decay.00741', 'gnu23',
    'library', 'block-scope', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.library.array-decay.00742', 'posix.1-2008',
    'library', 'runtime-expression', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.library.array-decay.00743', 'rcc1',
    'library', 'translation-unit', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.abi.array-decay.00744', 'c90',
    'abi', 'prototype', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.abi.array-decay.00745', 'c99',
    'abi', 'variadic-call', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.abi.array-decay.00746', 'c11',
    'abi', 'file-scope', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.abi.array-decay.00747', 'c17',
    'abi', 'constant-expression', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.abi.array-decay.00748', 'c23',
    'abi', 'cross-module', 'array-decay',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.abi.array-decay.00749', 'gnu90',
    'abi', 'block-scope', 'array-decay',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.abi.array-decay.00750', 'gnu99',
    'abi', 'runtime-expression', 'array-decay',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.abi.array-decay.00751', 'gnu11',
    'abi', 'translation-unit', 'array-decay',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.abi.array-decay.00752', 'gnu17',
    'abi', 'prototype', 'array-decay',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.abi.array-decay.00753', 'gnu23',
    'abi', 'variadic-call', 'array-decay',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.abi.array-decay.00754', 'posix.1-2008',
    'abi', 'file-scope', 'array-decay',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.abi.array-decay.00755', 'rcc1',
    'abi', 'constant-expression', 'array-decay',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.object-format.array-decay.00756', 'c90',
    'object-format', 'cross-module', 'array-decay',
    'compile-fail', 'required');
  AddCase(Result, 'c99.object-format.array-decay.00757', 'c99',
    'object-format', 'block-scope', 'array-decay',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.object-format.array-decay.00758', 'c11',
    'object-format', 'runtime-expression', 'array-decay',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.object-format.array-decay.00759', 'c17',
    'object-format', 'translation-unit', 'array-decay',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.object-format.array-decay.00760', 'c23',
    'object-format', 'prototype', 'array-decay',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.object-format.array-decay.00761', 'gnu90',
    'object-format', 'variadic-call', 'array-decay',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.object-format.array-decay.00762', 'gnu99',
    'object-format', 'file-scope', 'array-decay',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.object-format.array-decay.00763', 'gnu11',
    'object-format', 'constant-expression', 'array-decay',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.object-format.array-decay.00764', 'gnu17',
    'object-format', 'cross-module', 'array-decay',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.object-format.array-decay.00765', 'gnu23',
    'object-format', 'block-scope', 'array-decay',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.array-decay.00766', 'posix.1-2008',
    'object-format', 'runtime-expression', 'array-decay',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.object-format.array-decay.00767', 'rcc1',
    'object-format', 'translation-unit', 'array-decay',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.lexing.function-designator.00768', 'c90',
    'lexing', 'prototype', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'c99.lexing.function-designator.00769', 'c99',
    'lexing', 'variadic-call', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.lexing.function-designator.00770', 'c11',
    'lexing', 'file-scope', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.lexing.function-designator.00771', 'c17',
    'lexing', 'constant-expression', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.lexing.function-designator.00772', 'c23',
    'lexing', 'cross-module', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.lexing.function-designator.00773', 'gnu90',
    'lexing', 'block-scope', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.lexing.function-designator.00774', 'gnu99',
    'lexing', 'runtime-expression', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.lexing.function-designator.00775', 'gnu11',
    'lexing', 'translation-unit', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.lexing.function-designator.00776', 'gnu17',
    'lexing', 'prototype', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.lexing.function-designator.00777', 'gnu23',
    'lexing', 'variadic-call', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.function-designator.00778', 'posix.1-2008',
    'lexing', 'file-scope', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.lexing.function-designator.00779', 'rcc1',
    'lexing', 'constant-expression', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.preprocessing.function-designator.00780', 'c90',
    'preprocessing', 'cross-module', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'c99.preprocessing.function-designator.00781', 'c99',
    'preprocessing', 'block-scope', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.preprocessing.function-designator.00782', 'c11',
    'preprocessing', 'runtime-expression', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.preprocessing.function-designator.00783', 'c17',
    'preprocessing', 'translation-unit', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.preprocessing.function-designator.00784', 'c23',
    'preprocessing', 'prototype', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.preprocessing.function-designator.00785', 'gnu90',
    'preprocessing', 'variadic-call', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.preprocessing.function-designator.00786', 'gnu99',
    'preprocessing', 'file-scope', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.preprocessing.function-designator.00787', 'gnu11',
    'preprocessing', 'constant-expression', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.preprocessing.function-designator.00788', 'gnu17',
    'preprocessing', 'cross-module', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.preprocessing.function-designator.00789', 'gnu23',
    'preprocessing', 'block-scope', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.function-designator.00790', 'posix.1-2008',
    'preprocessing', 'runtime-expression', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.preprocessing.function-designator.00791', 'rcc1',
    'preprocessing', 'translation-unit', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.declarations.function-designator.00792', 'c90',
    'declarations', 'prototype', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'c99.declarations.function-designator.00793', 'c99',
    'declarations', 'variadic-call', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.declarations.function-designator.00794', 'c11',
    'declarations', 'file-scope', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.declarations.function-designator.00795', 'c17',
    'declarations', 'constant-expression', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.declarations.function-designator.00796', 'c23',
    'declarations', 'cross-module', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.declarations.function-designator.00797', 'gnu90',
    'declarations', 'block-scope', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.declarations.function-designator.00798', 'gnu99',
    'declarations', 'runtime-expression', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.declarations.function-designator.00799', 'gnu11',
    'declarations', 'translation-unit', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.declarations.function-designator.00800', 'gnu17',
    'declarations', 'prototype', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.declarations.function-designator.00801', 'gnu23',
    'declarations', 'variadic-call', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.function-designator.00802', 'posix.1-2008',
    'declarations', 'file-scope', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.declarations.function-designator.00803', 'rcc1',
    'declarations', 'constant-expression', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.types.function-designator.00804', 'c90',
    'types', 'cross-module', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.types.function-designator.00805', 'c99',
    'types', 'block-scope', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.types.function-designator.00806', 'c11',
    'types', 'runtime-expression', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.types.function-designator.00807', 'c17',
    'types', 'translation-unit', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.types.function-designator.00808', 'c23',
    'types', 'prototype', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.types.function-designator.00809', 'gnu90',
    'types', 'variadic-call', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.types.function-designator.00810', 'gnu99',
    'types', 'file-scope', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.types.function-designator.00811', 'gnu11',
    'types', 'constant-expression', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.types.function-designator.00812', 'gnu17',
    'types', 'cross-module', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.types.function-designator.00813', 'gnu23',
    'types', 'block-scope', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.types.function-designator.00814', 'posix.1-2008',
    'types', 'runtime-expression', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.types.function-designator.00815', 'rcc1',
    'types', 'translation-unit', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.conversions.function-designator.00816', 'c90',
    'conversions', 'prototype', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'c99.conversions.function-designator.00817', 'c99',
    'conversions', 'variadic-call', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.conversions.function-designator.00818', 'c11',
    'conversions', 'file-scope', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.conversions.function-designator.00819', 'c17',
    'conversions', 'constant-expression', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.conversions.function-designator.00820', 'c23',
    'conversions', 'cross-module', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.conversions.function-designator.00821', 'gnu90',
    'conversions', 'block-scope', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.conversions.function-designator.00822', 'gnu99',
    'conversions', 'runtime-expression', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.conversions.function-designator.00823', 'gnu11',
    'conversions', 'translation-unit', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.conversions.function-designator.00824', 'gnu17',
    'conversions', 'prototype', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.conversions.function-designator.00825', 'gnu23',
    'conversions', 'variadic-call', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.function-designator.00826', 'posix.1-2008',
    'conversions', 'file-scope', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.conversions.function-designator.00827', 'rcc1',
    'conversions', 'constant-expression', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.expressions.function-designator.00828', 'c90',
    'expressions', 'cross-module', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'c99.expressions.function-designator.00829', 'c99',
    'expressions', 'block-scope', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.expressions.function-designator.00830', 'c11',
    'expressions', 'runtime-expression', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.expressions.function-designator.00831', 'c17',
    'expressions', 'translation-unit', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.expressions.function-designator.00832', 'c23',
    'expressions', 'prototype', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.expressions.function-designator.00833', 'gnu90',
    'expressions', 'variadic-call', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.expressions.function-designator.00834', 'gnu99',
    'expressions', 'file-scope', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.expressions.function-designator.00835', 'gnu11',
    'expressions', 'constant-expression', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.expressions.function-designator.00836', 'gnu17',
    'expressions', 'cross-module', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.expressions.function-designator.00837', 'gnu23',
    'expressions', 'block-scope', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.function-designator.00838', 'posix.1-2008',
    'expressions', 'runtime-expression', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.expressions.function-designator.00839', 'rcc1',
    'expressions', 'translation-unit', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.statements.function-designator.00840', 'c90',
    'statements', 'prototype', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'c99.statements.function-designator.00841', 'c99',
    'statements', 'variadic-call', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.statements.function-designator.00842', 'c11',
    'statements', 'file-scope', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.statements.function-designator.00843', 'c17',
    'statements', 'constant-expression', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.statements.function-designator.00844', 'c23',
    'statements', 'cross-module', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.statements.function-designator.00845', 'gnu90',
    'statements', 'block-scope', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.statements.function-designator.00846', 'gnu99',
    'statements', 'runtime-expression', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.statements.function-designator.00847', 'gnu11',
    'statements', 'translation-unit', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.statements.function-designator.00848', 'gnu17',
    'statements', 'prototype', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.statements.function-designator.00849', 'gnu23',
    'statements', 'variadic-call', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.statements.function-designator.00850', 'posix.1-2008',
    'statements', 'file-scope', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.statements.function-designator.00851', 'rcc1',
    'statements', 'constant-expression', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.functions.function-designator.00852', 'c90',
    'functions', 'cross-module', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'c99.functions.function-designator.00853', 'c99',
    'functions', 'block-scope', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.functions.function-designator.00854', 'c11',
    'functions', 'runtime-expression', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.functions.function-designator.00855', 'c17',
    'functions', 'translation-unit', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.functions.function-designator.00856', 'c23',
    'functions', 'prototype', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.functions.function-designator.00857', 'gnu90',
    'functions', 'variadic-call', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.functions.function-designator.00858', 'gnu99',
    'functions', 'file-scope', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.functions.function-designator.00859', 'gnu11',
    'functions', 'constant-expression', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.functions.function-designator.00860', 'gnu17',
    'functions', 'cross-module', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.functions.function-designator.00861', 'gnu23',
    'functions', 'block-scope', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.functions.function-designator.00862', 'posix.1-2008',
    'functions', 'runtime-expression', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.functions.function-designator.00863', 'rcc1',
    'functions', 'translation-unit', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.aggregates.function-designator.00864', 'c90',
    'aggregates', 'prototype', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.aggregates.function-designator.00865', 'c99',
    'aggregates', 'variadic-call', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.aggregates.function-designator.00866', 'c11',
    'aggregates', 'file-scope', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.aggregates.function-designator.00867', 'c17',
    'aggregates', 'constant-expression', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.aggregates.function-designator.00868', 'c23',
    'aggregates', 'cross-module', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.aggregates.function-designator.00869', 'gnu90',
    'aggregates', 'block-scope', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.aggregates.function-designator.00870', 'gnu99',
    'aggregates', 'runtime-expression', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.aggregates.function-designator.00871', 'gnu11',
    'aggregates', 'translation-unit', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.aggregates.function-designator.00872', 'gnu17',
    'aggregates', 'prototype', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.aggregates.function-designator.00873', 'gnu23',
    'aggregates', 'variadic-call', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.function-designator.00874', 'posix.1-2008',
    'aggregates', 'file-scope', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.aggregates.function-designator.00875', 'rcc1',
    'aggregates', 'constant-expression', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.initializers.function-designator.00876', 'c90',
    'initializers', 'cross-module', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'c99.initializers.function-designator.00877', 'c99',
    'initializers', 'block-scope', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.initializers.function-designator.00878', 'c11',
    'initializers', 'runtime-expression', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.initializers.function-designator.00879', 'c17',
    'initializers', 'translation-unit', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.initializers.function-designator.00880', 'c23',
    'initializers', 'prototype', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.initializers.function-designator.00881', 'gnu90',
    'initializers', 'variadic-call', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.initializers.function-designator.00882', 'gnu99',
    'initializers', 'file-scope', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.initializers.function-designator.00883', 'gnu11',
    'initializers', 'constant-expression', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.initializers.function-designator.00884', 'gnu17',
    'initializers', 'cross-module', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.initializers.function-designator.00885', 'gnu23',
    'initializers', 'block-scope', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.function-designator.00886', 'posix.1-2008',
    'initializers', 'runtime-expression', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.initializers.function-designator.00887', 'rcc1',
    'initializers', 'translation-unit', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.floating.function-designator.00888', 'c90',
    'floating', 'prototype', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'c99.floating.function-designator.00889', 'c99',
    'floating', 'variadic-call', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.floating.function-designator.00890', 'c11',
    'floating', 'file-scope', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.floating.function-designator.00891', 'c17',
    'floating', 'constant-expression', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.floating.function-designator.00892', 'c23',
    'floating', 'cross-module', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.floating.function-designator.00893', 'gnu90',
    'floating', 'block-scope', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.floating.function-designator.00894', 'gnu99',
    'floating', 'runtime-expression', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.floating.function-designator.00895', 'gnu11',
    'floating', 'translation-unit', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.floating.function-designator.00896', 'gnu17',
    'floating', 'prototype', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.floating.function-designator.00897', 'gnu23',
    'floating', 'variadic-call', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.floating.function-designator.00898', 'posix.1-2008',
    'floating', 'file-scope', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.floating.function-designator.00899', 'rcc1',
    'floating', 'constant-expression', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.atomics.function-designator.00900', 'c90',
    'atomics', 'cross-module', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'c99.atomics.function-designator.00901', 'c99',
    'atomics', 'block-scope', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.atomics.function-designator.00902', 'c11',
    'atomics', 'runtime-expression', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.atomics.function-designator.00903', 'c17',
    'atomics', 'translation-unit', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.atomics.function-designator.00904', 'c23',
    'atomics', 'prototype', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.atomics.function-designator.00905', 'gnu90',
    'atomics', 'variadic-call', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.atomics.function-designator.00906', 'gnu99',
    'atomics', 'file-scope', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.atomics.function-designator.00907', 'gnu11',
    'atomics', 'constant-expression', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.atomics.function-designator.00908', 'gnu17',
    'atomics', 'cross-module', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.atomics.function-designator.00909', 'gnu23',
    'atomics', 'block-scope', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.function-designator.00910', 'posix.1-2008',
    'atomics', 'runtime-expression', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.atomics.function-designator.00911', 'rcc1',
    'atomics', 'translation-unit', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.variadics.function-designator.00912', 'c90',
    'variadics', 'prototype', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'c99.variadics.function-designator.00913', 'c99',
    'variadics', 'variadic-call', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.variadics.function-designator.00914', 'c11',
    'variadics', 'file-scope', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.variadics.function-designator.00915', 'c17',
    'variadics', 'constant-expression', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.variadics.function-designator.00916', 'c23',
    'variadics', 'cross-module', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.variadics.function-designator.00917', 'gnu90',
    'variadics', 'block-scope', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.variadics.function-designator.00918', 'gnu99',
    'variadics', 'runtime-expression', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.variadics.function-designator.00919', 'gnu11',
    'variadics', 'translation-unit', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.variadics.function-designator.00920', 'gnu17',
    'variadics', 'prototype', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.variadics.function-designator.00921', 'gnu23',
    'variadics', 'variadic-call', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.function-designator.00922', 'posix.1-2008',
    'variadics', 'file-scope', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.variadics.function-designator.00923', 'rcc1',
    'variadics', 'constant-expression', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.library.function-designator.00924', 'c90',
    'library', 'cross-module', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.library.function-designator.00925', 'c99',
    'library', 'block-scope', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.library.function-designator.00926', 'c11',
    'library', 'runtime-expression', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.library.function-designator.00927', 'c17',
    'library', 'translation-unit', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.library.function-designator.00928', 'c23',
    'library', 'prototype', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.library.function-designator.00929', 'gnu90',
    'library', 'variadic-call', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.library.function-designator.00930', 'gnu99',
    'library', 'file-scope', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.library.function-designator.00931', 'gnu11',
    'library', 'constant-expression', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.library.function-designator.00932', 'gnu17',
    'library', 'cross-module', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.library.function-designator.00933', 'gnu23',
    'library', 'block-scope', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.library.function-designator.00934', 'posix.1-2008',
    'library', 'runtime-expression', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.library.function-designator.00935', 'rcc1',
    'library', 'translation-unit', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.abi.function-designator.00936', 'c90',
    'abi', 'prototype', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'c99.abi.function-designator.00937', 'c99',
    'abi', 'variadic-call', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.abi.function-designator.00938', 'c11',
    'abi', 'file-scope', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.abi.function-designator.00939', 'c17',
    'abi', 'constant-expression', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.abi.function-designator.00940', 'c23',
    'abi', 'cross-module', 'function-designator',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.abi.function-designator.00941', 'gnu90',
    'abi', 'block-scope', 'function-designator',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.abi.function-designator.00942', 'gnu99',
    'abi', 'runtime-expression', 'function-designator',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.abi.function-designator.00943', 'gnu11',
    'abi', 'translation-unit', 'function-designator',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.abi.function-designator.00944', 'gnu17',
    'abi', 'prototype', 'function-designator',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.abi.function-designator.00945', 'gnu23',
    'abi', 'variadic-call', 'function-designator',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.abi.function-designator.00946', 'posix.1-2008',
    'abi', 'file-scope', 'function-designator',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.abi.function-designator.00947', 'rcc1',
    'abi', 'constant-expression', 'function-designator',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.object-format.function-designator.00948', 'c90',
    'object-format', 'cross-module', 'function-designator',
    'diagnostic', 'required');
  AddCase(Result, 'c99.object-format.function-designator.00949', 'c99',
    'object-format', 'block-scope', 'function-designator',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.object-format.function-designator.00950', 'c11',
    'object-format', 'runtime-expression', 'function-designator',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.object-format.function-designator.00951', 'c17',
    'object-format', 'translation-unit', 'function-designator',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.object-format.function-designator.00952', 'c23',
    'object-format', 'prototype', 'function-designator',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.object-format.function-designator.00953', 'gnu90',
    'object-format', 'variadic-call', 'function-designator',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.object-format.function-designator.00954', 'gnu99',
    'object-format', 'file-scope', 'function-designator',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.object-format.function-designator.00955', 'gnu11',
    'object-format', 'constant-expression', 'function-designator',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.object-format.function-designator.00956', 'gnu17',
    'object-format', 'cross-module', 'function-designator',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.object-format.function-designator.00957', 'gnu23',
    'object-format', 'block-scope', 'function-designator',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.function-designator.00958', 'posix.1-2008',
    'object-format', 'runtime-expression', 'function-designator',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.object-format.function-designator.00959', 'rcc1',
    'object-format', 'translation-unit', 'function-designator',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.lexing.struct-layout.00960', 'c90',
    'lexing', 'runtime-expression', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.lexing.struct-layout.00961', 'c99',
    'lexing', 'translation-unit', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.lexing.struct-layout.00962', 'c11',
    'lexing', 'prototype', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.lexing.struct-layout.00963', 'c17',
    'lexing', 'variadic-call', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.lexing.struct-layout.00964', 'c23',
    'lexing', 'file-scope', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.lexing.struct-layout.00965', 'gnu90',
    'lexing', 'constant-expression', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.lexing.struct-layout.00966', 'gnu99',
    'lexing', 'cross-module', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.lexing.struct-layout.00967', 'gnu11',
    'lexing', 'block-scope', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.lexing.struct-layout.00968', 'gnu17',
    'lexing', 'runtime-expression', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.lexing.struct-layout.00969', 'gnu23',
    'lexing', 'translation-unit', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.struct-layout.00970', 'posix.1-2008',
    'lexing', 'prototype', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.lexing.struct-layout.00971', 'rcc1',
    'lexing', 'variadic-call', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.preprocessing.struct-layout.00972', 'c90',
    'preprocessing', 'file-scope', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.preprocessing.struct-layout.00973', 'c99',
    'preprocessing', 'constant-expression', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.preprocessing.struct-layout.00974', 'c11',
    'preprocessing', 'cross-module', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.preprocessing.struct-layout.00975', 'c17',
    'preprocessing', 'block-scope', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.preprocessing.struct-layout.00976', 'c23',
    'preprocessing', 'runtime-expression', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.preprocessing.struct-layout.00977', 'gnu90',
    'preprocessing', 'translation-unit', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.preprocessing.struct-layout.00978', 'gnu99',
    'preprocessing', 'prototype', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.preprocessing.struct-layout.00979', 'gnu11',
    'preprocessing', 'variadic-call', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.preprocessing.struct-layout.00980', 'gnu17',
    'preprocessing', 'file-scope', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.preprocessing.struct-layout.00981', 'gnu23',
    'preprocessing', 'constant-expression', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.struct-layout.00982', 'posix.1-2008',
    'preprocessing', 'cross-module', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.preprocessing.struct-layout.00983', 'rcc1',
    'preprocessing', 'block-scope', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.declarations.struct-layout.00984', 'c90',
    'declarations', 'runtime-expression', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.declarations.struct-layout.00985', 'c99',
    'declarations', 'translation-unit', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.declarations.struct-layout.00986', 'c11',
    'declarations', 'prototype', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.declarations.struct-layout.00987', 'c17',
    'declarations', 'variadic-call', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.declarations.struct-layout.00988', 'c23',
    'declarations', 'file-scope', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.declarations.struct-layout.00989', 'gnu90',
    'declarations', 'constant-expression', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.declarations.struct-layout.00990', 'gnu99',
    'declarations', 'cross-module', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.declarations.struct-layout.00991', 'gnu11',
    'declarations', 'block-scope', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.declarations.struct-layout.00992', 'gnu17',
    'declarations', 'runtime-expression', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.declarations.struct-layout.00993', 'gnu23',
    'declarations', 'translation-unit', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.struct-layout.00994', 'posix.1-2008',
    'declarations', 'prototype', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.declarations.struct-layout.00995', 'rcc1',
    'declarations', 'variadic-call', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.types.struct-layout.00996', 'c90',
    'types', 'file-scope', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.types.struct-layout.00997', 'c99',
    'types', 'constant-expression', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.types.struct-layout.00998', 'c11',
    'types', 'cross-module', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.types.struct-layout.00999', 'c17',
    'types', 'block-scope', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.types.struct-layout.01000', 'c23',
    'types', 'runtime-expression', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.types.struct-layout.01001', 'gnu90',
    'types', 'translation-unit', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.types.struct-layout.01002', 'gnu99',
    'types', 'prototype', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.types.struct-layout.01003', 'gnu11',
    'types', 'variadic-call', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.types.struct-layout.01004', 'gnu17',
    'types', 'file-scope', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.types.struct-layout.01005', 'gnu23',
    'types', 'constant-expression', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.types.struct-layout.01006', 'posix.1-2008',
    'types', 'cross-module', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.types.struct-layout.01007', 'rcc1',
    'types', 'block-scope', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.conversions.struct-layout.01008', 'c90',
    'conversions', 'runtime-expression', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.conversions.struct-layout.01009', 'c99',
    'conversions', 'translation-unit', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.conversions.struct-layout.01010', 'c11',
    'conversions', 'prototype', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.conversions.struct-layout.01011', 'c17',
    'conversions', 'variadic-call', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.conversions.struct-layout.01012', 'c23',
    'conversions', 'file-scope', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.conversions.struct-layout.01013', 'gnu90',
    'conversions', 'constant-expression', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.conversions.struct-layout.01014', 'gnu99',
    'conversions', 'cross-module', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.conversions.struct-layout.01015', 'gnu11',
    'conversions', 'block-scope', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.conversions.struct-layout.01016', 'gnu17',
    'conversions', 'runtime-expression', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.conversions.struct-layout.01017', 'gnu23',
    'conversions', 'translation-unit', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.struct-layout.01018', 'posix.1-2008',
    'conversions', 'prototype', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.conversions.struct-layout.01019', 'rcc1',
    'conversions', 'variadic-call', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.expressions.struct-layout.01020', 'c90',
    'expressions', 'file-scope', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.expressions.struct-layout.01021', 'c99',
    'expressions', 'constant-expression', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.expressions.struct-layout.01022', 'c11',
    'expressions', 'cross-module', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.expressions.struct-layout.01023', 'c17',
    'expressions', 'block-scope', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.expressions.struct-layout.01024', 'c23',
    'expressions', 'runtime-expression', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.expressions.struct-layout.01025', 'gnu90',
    'expressions', 'translation-unit', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.expressions.struct-layout.01026', 'gnu99',
    'expressions', 'prototype', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.expressions.struct-layout.01027', 'gnu11',
    'expressions', 'variadic-call', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.expressions.struct-layout.01028', 'gnu17',
    'expressions', 'file-scope', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.expressions.struct-layout.01029', 'gnu23',
    'expressions', 'constant-expression', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.struct-layout.01030', 'posix.1-2008',
    'expressions', 'cross-module', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.expressions.struct-layout.01031', 'rcc1',
    'expressions', 'block-scope', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.statements.struct-layout.01032', 'c90',
    'statements', 'runtime-expression', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.statements.struct-layout.01033', 'c99',
    'statements', 'translation-unit', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.statements.struct-layout.01034', 'c11',
    'statements', 'prototype', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.statements.struct-layout.01035', 'c17',
    'statements', 'variadic-call', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.statements.struct-layout.01036', 'c23',
    'statements', 'file-scope', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.statements.struct-layout.01037', 'gnu90',
    'statements', 'constant-expression', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.statements.struct-layout.01038', 'gnu99',
    'statements', 'cross-module', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.statements.struct-layout.01039', 'gnu11',
    'statements', 'block-scope', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.statements.struct-layout.01040', 'gnu17',
    'statements', 'runtime-expression', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.statements.struct-layout.01041', 'gnu23',
    'statements', 'translation-unit', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.statements.struct-layout.01042', 'posix.1-2008',
    'statements', 'prototype', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.statements.struct-layout.01043', 'rcc1',
    'statements', 'variadic-call', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.functions.struct-layout.01044', 'c90',
    'functions', 'file-scope', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.functions.struct-layout.01045', 'c99',
    'functions', 'constant-expression', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.functions.struct-layout.01046', 'c11',
    'functions', 'cross-module', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.functions.struct-layout.01047', 'c17',
    'functions', 'block-scope', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.functions.struct-layout.01048', 'c23',
    'functions', 'runtime-expression', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.functions.struct-layout.01049', 'gnu90',
    'functions', 'translation-unit', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.functions.struct-layout.01050', 'gnu99',
    'functions', 'prototype', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.functions.struct-layout.01051', 'gnu11',
    'functions', 'variadic-call', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.functions.struct-layout.01052', 'gnu17',
    'functions', 'file-scope', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.functions.struct-layout.01053', 'gnu23',
    'functions', 'constant-expression', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.functions.struct-layout.01054', 'posix.1-2008',
    'functions', 'cross-module', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.functions.struct-layout.01055', 'rcc1',
    'functions', 'block-scope', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.aggregates.struct-layout.01056', 'c90',
    'aggregates', 'runtime-expression', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.aggregates.struct-layout.01057', 'c99',
    'aggregates', 'translation-unit', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.aggregates.struct-layout.01058', 'c11',
    'aggregates', 'prototype', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.aggregates.struct-layout.01059', 'c17',
    'aggregates', 'variadic-call', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.aggregates.struct-layout.01060', 'c23',
    'aggregates', 'file-scope', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.aggregates.struct-layout.01061', 'gnu90',
    'aggregates', 'constant-expression', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.aggregates.struct-layout.01062', 'gnu99',
    'aggregates', 'cross-module', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.aggregates.struct-layout.01063', 'gnu11',
    'aggregates', 'block-scope', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.aggregates.struct-layout.01064', 'gnu17',
    'aggregates', 'runtime-expression', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.aggregates.struct-layout.01065', 'gnu23',
    'aggregates', 'translation-unit', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.struct-layout.01066', 'posix.1-2008',
    'aggregates', 'prototype', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.aggregates.struct-layout.01067', 'rcc1',
    'aggregates', 'variadic-call', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.initializers.struct-layout.01068', 'c90',
    'initializers', 'file-scope', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.initializers.struct-layout.01069', 'c99',
    'initializers', 'constant-expression', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.initializers.struct-layout.01070', 'c11',
    'initializers', 'cross-module', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.initializers.struct-layout.01071', 'c17',
    'initializers', 'block-scope', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.initializers.struct-layout.01072', 'c23',
    'initializers', 'runtime-expression', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.initializers.struct-layout.01073', 'gnu90',
    'initializers', 'translation-unit', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.initializers.struct-layout.01074', 'gnu99',
    'initializers', 'prototype', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.initializers.struct-layout.01075', 'gnu11',
    'initializers', 'variadic-call', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.initializers.struct-layout.01076', 'gnu17',
    'initializers', 'file-scope', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.initializers.struct-layout.01077', 'gnu23',
    'initializers', 'constant-expression', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.struct-layout.01078', 'posix.1-2008',
    'initializers', 'cross-module', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.initializers.struct-layout.01079', 'rcc1',
    'initializers', 'block-scope', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.floating.struct-layout.01080', 'c90',
    'floating', 'runtime-expression', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.floating.struct-layout.01081', 'c99',
    'floating', 'translation-unit', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.floating.struct-layout.01082', 'c11',
    'floating', 'prototype', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.floating.struct-layout.01083', 'c17',
    'floating', 'variadic-call', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.floating.struct-layout.01084', 'c23',
    'floating', 'file-scope', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.floating.struct-layout.01085', 'gnu90',
    'floating', 'constant-expression', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.floating.struct-layout.01086', 'gnu99',
    'floating', 'cross-module', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.floating.struct-layout.01087', 'gnu11',
    'floating', 'block-scope', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.floating.struct-layout.01088', 'gnu17',
    'floating', 'runtime-expression', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.floating.struct-layout.01089', 'gnu23',
    'floating', 'translation-unit', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.floating.struct-layout.01090', 'posix.1-2008',
    'floating', 'prototype', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.floating.struct-layout.01091', 'rcc1',
    'floating', 'variadic-call', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.atomics.struct-layout.01092', 'c90',
    'atomics', 'file-scope', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.atomics.struct-layout.01093', 'c99',
    'atomics', 'constant-expression', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.atomics.struct-layout.01094', 'c11',
    'atomics', 'cross-module', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.atomics.struct-layout.01095', 'c17',
    'atomics', 'block-scope', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.atomics.struct-layout.01096', 'c23',
    'atomics', 'runtime-expression', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.atomics.struct-layout.01097', 'gnu90',
    'atomics', 'translation-unit', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.atomics.struct-layout.01098', 'gnu99',
    'atomics', 'prototype', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.atomics.struct-layout.01099', 'gnu11',
    'atomics', 'variadic-call', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.atomics.struct-layout.01100', 'gnu17',
    'atomics', 'file-scope', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.atomics.struct-layout.01101', 'gnu23',
    'atomics', 'constant-expression', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.struct-layout.01102', 'posix.1-2008',
    'atomics', 'cross-module', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.atomics.struct-layout.01103', 'rcc1',
    'atomics', 'block-scope', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.variadics.struct-layout.01104', 'c90',
    'variadics', 'runtime-expression', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.variadics.struct-layout.01105', 'c99',
    'variadics', 'translation-unit', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.variadics.struct-layout.01106', 'c11',
    'variadics', 'prototype', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.variadics.struct-layout.01107', 'c17',
    'variadics', 'variadic-call', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.variadics.struct-layout.01108', 'c23',
    'variadics', 'file-scope', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.variadics.struct-layout.01109', 'gnu90',
    'variadics', 'constant-expression', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.variadics.struct-layout.01110', 'gnu99',
    'variadics', 'cross-module', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.variadics.struct-layout.01111', 'gnu11',
    'variadics', 'block-scope', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.variadics.struct-layout.01112', 'gnu17',
    'variadics', 'runtime-expression', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.variadics.struct-layout.01113', 'gnu23',
    'variadics', 'translation-unit', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.struct-layout.01114', 'posix.1-2008',
    'variadics', 'prototype', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.variadics.struct-layout.01115', 'rcc1',
    'variadics', 'variadic-call', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.library.struct-layout.01116', 'c90',
    'library', 'file-scope', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.library.struct-layout.01117', 'c99',
    'library', 'constant-expression', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.library.struct-layout.01118', 'c11',
    'library', 'cross-module', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.library.struct-layout.01119', 'c17',
    'library', 'block-scope', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.library.struct-layout.01120', 'c23',
    'library', 'runtime-expression', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.library.struct-layout.01121', 'gnu90',
    'library', 'translation-unit', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.library.struct-layout.01122', 'gnu99',
    'library', 'prototype', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.library.struct-layout.01123', 'gnu11',
    'library', 'variadic-call', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.library.struct-layout.01124', 'gnu17',
    'library', 'file-scope', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.library.struct-layout.01125', 'gnu23',
    'library', 'constant-expression', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.library.struct-layout.01126', 'posix.1-2008',
    'library', 'cross-module', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.library.struct-layout.01127', 'rcc1',
    'library', 'block-scope', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.abi.struct-layout.01128', 'c90',
    'abi', 'runtime-expression', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.abi.struct-layout.01129', 'c99',
    'abi', 'translation-unit', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.abi.struct-layout.01130', 'c11',
    'abi', 'prototype', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.abi.struct-layout.01131', 'c17',
    'abi', 'variadic-call', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.abi.struct-layout.01132', 'c23',
    'abi', 'file-scope', 'struct-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.abi.struct-layout.01133', 'gnu90',
    'abi', 'constant-expression', 'struct-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.abi.struct-layout.01134', 'gnu99',
    'abi', 'cross-module', 'struct-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.abi.struct-layout.01135', 'gnu11',
    'abi', 'block-scope', 'struct-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.abi.struct-layout.01136', 'gnu17',
    'abi', 'runtime-expression', 'struct-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.abi.struct-layout.01137', 'gnu23',
    'abi', 'translation-unit', 'struct-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.abi.struct-layout.01138', 'posix.1-2008',
    'abi', 'prototype', 'struct-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.abi.struct-layout.01139', 'rcc1',
    'abi', 'variadic-call', 'struct-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.object-format.struct-layout.01140', 'c90',
    'object-format', 'file-scope', 'struct-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.object-format.struct-layout.01141', 'c99',
    'object-format', 'constant-expression', 'struct-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.object-format.struct-layout.01142', 'c11',
    'object-format', 'cross-module', 'struct-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.object-format.struct-layout.01143', 'c17',
    'object-format', 'block-scope', 'struct-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.object-format.struct-layout.01144', 'c23',
    'object-format', 'runtime-expression', 'struct-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.object-format.struct-layout.01145', 'gnu90',
    'object-format', 'translation-unit', 'struct-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.object-format.struct-layout.01146', 'gnu99',
    'object-format', 'prototype', 'struct-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.object-format.struct-layout.01147', 'gnu11',
    'object-format', 'variadic-call', 'struct-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.object-format.struct-layout.01148', 'gnu17',
    'object-format', 'file-scope', 'struct-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.object-format.struct-layout.01149', 'gnu23',
    'object-format', 'constant-expression', 'struct-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.struct-layout.01150', 'posix.1-2008',
    'object-format', 'cross-module', 'struct-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.object-format.struct-layout.01151', 'rcc1',
    'object-format', 'block-scope', 'struct-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.lexing.union-layout.01152', 'c90',
    'lexing', 'constant-expression', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.lexing.union-layout.01153', 'c99',
    'lexing', 'cross-module', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.lexing.union-layout.01154', 'c11',
    'lexing', 'block-scope', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.lexing.union-layout.01155', 'c17',
    'lexing', 'runtime-expression', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.lexing.union-layout.01156', 'c23',
    'lexing', 'translation-unit', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.lexing.union-layout.01157', 'gnu90',
    'lexing', 'prototype', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.lexing.union-layout.01158', 'gnu99',
    'lexing', 'variadic-call', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.lexing.union-layout.01159', 'gnu11',
    'lexing', 'file-scope', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.lexing.union-layout.01160', 'gnu17',
    'lexing', 'constant-expression', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.lexing.union-layout.01161', 'gnu23',
    'lexing', 'cross-module', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.union-layout.01162', 'posix.1-2008',
    'lexing', 'block-scope', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.lexing.union-layout.01163', 'rcc1',
    'lexing', 'runtime-expression', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.preprocessing.union-layout.01164', 'c90',
    'preprocessing', 'translation-unit', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.preprocessing.union-layout.01165', 'c99',
    'preprocessing', 'prototype', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.preprocessing.union-layout.01166', 'c11',
    'preprocessing', 'variadic-call', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.preprocessing.union-layout.01167', 'c17',
    'preprocessing', 'file-scope', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.preprocessing.union-layout.01168', 'c23',
    'preprocessing', 'constant-expression', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.preprocessing.union-layout.01169', 'gnu90',
    'preprocessing', 'cross-module', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.preprocessing.union-layout.01170', 'gnu99',
    'preprocessing', 'block-scope', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.preprocessing.union-layout.01171', 'gnu11',
    'preprocessing', 'runtime-expression', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.preprocessing.union-layout.01172', 'gnu17',
    'preprocessing', 'translation-unit', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.preprocessing.union-layout.01173', 'gnu23',
    'preprocessing', 'prototype', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.union-layout.01174', 'posix.1-2008',
    'preprocessing', 'variadic-call', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.preprocessing.union-layout.01175', 'rcc1',
    'preprocessing', 'file-scope', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.declarations.union-layout.01176', 'c90',
    'declarations', 'constant-expression', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.declarations.union-layout.01177', 'c99',
    'declarations', 'cross-module', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.declarations.union-layout.01178', 'c11',
    'declarations', 'block-scope', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.declarations.union-layout.01179', 'c17',
    'declarations', 'runtime-expression', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.declarations.union-layout.01180', 'c23',
    'declarations', 'translation-unit', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.declarations.union-layout.01181', 'gnu90',
    'declarations', 'prototype', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.declarations.union-layout.01182', 'gnu99',
    'declarations', 'variadic-call', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.declarations.union-layout.01183', 'gnu11',
    'declarations', 'file-scope', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.declarations.union-layout.01184', 'gnu17',
    'declarations', 'constant-expression', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.declarations.union-layout.01185', 'gnu23',
    'declarations', 'cross-module', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.union-layout.01186', 'posix.1-2008',
    'declarations', 'block-scope', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.declarations.union-layout.01187', 'rcc1',
    'declarations', 'runtime-expression', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.types.union-layout.01188', 'c90',
    'types', 'translation-unit', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.types.union-layout.01189', 'c99',
    'types', 'prototype', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.types.union-layout.01190', 'c11',
    'types', 'variadic-call', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.types.union-layout.01191', 'c17',
    'types', 'file-scope', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.types.union-layout.01192', 'c23',
    'types', 'constant-expression', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.types.union-layout.01193', 'gnu90',
    'types', 'cross-module', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.types.union-layout.01194', 'gnu99',
    'types', 'block-scope', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.types.union-layout.01195', 'gnu11',
    'types', 'runtime-expression', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.types.union-layout.01196', 'gnu17',
    'types', 'translation-unit', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.types.union-layout.01197', 'gnu23',
    'types', 'prototype', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.types.union-layout.01198', 'posix.1-2008',
    'types', 'variadic-call', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.types.union-layout.01199', 'rcc1',
    'types', 'file-scope', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.conversions.union-layout.01200', 'c90',
    'conversions', 'constant-expression', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.conversions.union-layout.01201', 'c99',
    'conversions', 'cross-module', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.conversions.union-layout.01202', 'c11',
    'conversions', 'block-scope', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.conversions.union-layout.01203', 'c17',
    'conversions', 'runtime-expression', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.conversions.union-layout.01204', 'c23',
    'conversions', 'translation-unit', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.conversions.union-layout.01205', 'gnu90',
    'conversions', 'prototype', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.conversions.union-layout.01206', 'gnu99',
    'conversions', 'variadic-call', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.conversions.union-layout.01207', 'gnu11',
    'conversions', 'file-scope', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.conversions.union-layout.01208', 'gnu17',
    'conversions', 'constant-expression', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.conversions.union-layout.01209', 'gnu23',
    'conversions', 'cross-module', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.union-layout.01210', 'posix.1-2008',
    'conversions', 'block-scope', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.conversions.union-layout.01211', 'rcc1',
    'conversions', 'runtime-expression', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.expressions.union-layout.01212', 'c90',
    'expressions', 'translation-unit', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.expressions.union-layout.01213', 'c99',
    'expressions', 'prototype', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.expressions.union-layout.01214', 'c11',
    'expressions', 'variadic-call', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.expressions.union-layout.01215', 'c17',
    'expressions', 'file-scope', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.expressions.union-layout.01216', 'c23',
    'expressions', 'constant-expression', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.expressions.union-layout.01217', 'gnu90',
    'expressions', 'cross-module', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.expressions.union-layout.01218', 'gnu99',
    'expressions', 'block-scope', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.expressions.union-layout.01219', 'gnu11',
    'expressions', 'runtime-expression', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.expressions.union-layout.01220', 'gnu17',
    'expressions', 'translation-unit', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.expressions.union-layout.01221', 'gnu23',
    'expressions', 'prototype', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.union-layout.01222', 'posix.1-2008',
    'expressions', 'variadic-call', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.expressions.union-layout.01223', 'rcc1',
    'expressions', 'file-scope', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.statements.union-layout.01224', 'c90',
    'statements', 'constant-expression', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.statements.union-layout.01225', 'c99',
    'statements', 'cross-module', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.statements.union-layout.01226', 'c11',
    'statements', 'block-scope', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.statements.union-layout.01227', 'c17',
    'statements', 'runtime-expression', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.statements.union-layout.01228', 'c23',
    'statements', 'translation-unit', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.statements.union-layout.01229', 'gnu90',
    'statements', 'prototype', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.statements.union-layout.01230', 'gnu99',
    'statements', 'variadic-call', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.statements.union-layout.01231', 'gnu11',
    'statements', 'file-scope', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.statements.union-layout.01232', 'gnu17',
    'statements', 'constant-expression', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.statements.union-layout.01233', 'gnu23',
    'statements', 'cross-module', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.statements.union-layout.01234', 'posix.1-2008',
    'statements', 'block-scope', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.statements.union-layout.01235', 'rcc1',
    'statements', 'runtime-expression', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.functions.union-layout.01236', 'c90',
    'functions', 'translation-unit', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.functions.union-layout.01237', 'c99',
    'functions', 'prototype', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.functions.union-layout.01238', 'c11',
    'functions', 'variadic-call', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.functions.union-layout.01239', 'c17',
    'functions', 'file-scope', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.functions.union-layout.01240', 'c23',
    'functions', 'constant-expression', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.functions.union-layout.01241', 'gnu90',
    'functions', 'cross-module', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.functions.union-layout.01242', 'gnu99',
    'functions', 'block-scope', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.functions.union-layout.01243', 'gnu11',
    'functions', 'runtime-expression', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.functions.union-layout.01244', 'gnu17',
    'functions', 'translation-unit', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.functions.union-layout.01245', 'gnu23',
    'functions', 'prototype', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.functions.union-layout.01246', 'posix.1-2008',
    'functions', 'variadic-call', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.functions.union-layout.01247', 'rcc1',
    'functions', 'file-scope', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.aggregates.union-layout.01248', 'c90',
    'aggregates', 'constant-expression', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.aggregates.union-layout.01249', 'c99',
    'aggregates', 'cross-module', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.aggregates.union-layout.01250', 'c11',
    'aggregates', 'block-scope', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.aggregates.union-layout.01251', 'c17',
    'aggregates', 'runtime-expression', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.aggregates.union-layout.01252', 'c23',
    'aggregates', 'translation-unit', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.aggregates.union-layout.01253', 'gnu90',
    'aggregates', 'prototype', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.aggregates.union-layout.01254', 'gnu99',
    'aggregates', 'variadic-call', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.aggregates.union-layout.01255', 'gnu11',
    'aggregates', 'file-scope', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.aggregates.union-layout.01256', 'gnu17',
    'aggregates', 'constant-expression', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.aggregates.union-layout.01257', 'gnu23',
    'aggregates', 'cross-module', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.union-layout.01258', 'posix.1-2008',
    'aggregates', 'block-scope', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.aggregates.union-layout.01259', 'rcc1',
    'aggregates', 'runtime-expression', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.initializers.union-layout.01260', 'c90',
    'initializers', 'translation-unit', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.initializers.union-layout.01261', 'c99',
    'initializers', 'prototype', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.initializers.union-layout.01262', 'c11',
    'initializers', 'variadic-call', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.initializers.union-layout.01263', 'c17',
    'initializers', 'file-scope', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.initializers.union-layout.01264', 'c23',
    'initializers', 'constant-expression', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.initializers.union-layout.01265', 'gnu90',
    'initializers', 'cross-module', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.initializers.union-layout.01266', 'gnu99',
    'initializers', 'block-scope', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.initializers.union-layout.01267', 'gnu11',
    'initializers', 'runtime-expression', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.initializers.union-layout.01268', 'gnu17',
    'initializers', 'translation-unit', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.initializers.union-layout.01269', 'gnu23',
    'initializers', 'prototype', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.union-layout.01270', 'posix.1-2008',
    'initializers', 'variadic-call', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.initializers.union-layout.01271', 'rcc1',
    'initializers', 'file-scope', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.floating.union-layout.01272', 'c90',
    'floating', 'constant-expression', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.floating.union-layout.01273', 'c99',
    'floating', 'cross-module', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.floating.union-layout.01274', 'c11',
    'floating', 'block-scope', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.floating.union-layout.01275', 'c17',
    'floating', 'runtime-expression', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.floating.union-layout.01276', 'c23',
    'floating', 'translation-unit', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.floating.union-layout.01277', 'gnu90',
    'floating', 'prototype', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.floating.union-layout.01278', 'gnu99',
    'floating', 'variadic-call', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.floating.union-layout.01279', 'gnu11',
    'floating', 'file-scope', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.floating.union-layout.01280', 'gnu17',
    'floating', 'constant-expression', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.floating.union-layout.01281', 'gnu23',
    'floating', 'cross-module', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.floating.union-layout.01282', 'posix.1-2008',
    'floating', 'block-scope', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.floating.union-layout.01283', 'rcc1',
    'floating', 'runtime-expression', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.atomics.union-layout.01284', 'c90',
    'atomics', 'translation-unit', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.atomics.union-layout.01285', 'c99',
    'atomics', 'prototype', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.atomics.union-layout.01286', 'c11',
    'atomics', 'variadic-call', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.atomics.union-layout.01287', 'c17',
    'atomics', 'file-scope', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.atomics.union-layout.01288', 'c23',
    'atomics', 'constant-expression', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.atomics.union-layout.01289', 'gnu90',
    'atomics', 'cross-module', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.atomics.union-layout.01290', 'gnu99',
    'atomics', 'block-scope', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.atomics.union-layout.01291', 'gnu11',
    'atomics', 'runtime-expression', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.atomics.union-layout.01292', 'gnu17',
    'atomics', 'translation-unit', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.atomics.union-layout.01293', 'gnu23',
    'atomics', 'prototype', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.union-layout.01294', 'posix.1-2008',
    'atomics', 'variadic-call', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.atomics.union-layout.01295', 'rcc1',
    'atomics', 'file-scope', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.variadics.union-layout.01296', 'c90',
    'variadics', 'constant-expression', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.variadics.union-layout.01297', 'c99',
    'variadics', 'cross-module', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.variadics.union-layout.01298', 'c11',
    'variadics', 'block-scope', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.variadics.union-layout.01299', 'c17',
    'variadics', 'runtime-expression', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.variadics.union-layout.01300', 'c23',
    'variadics', 'translation-unit', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.variadics.union-layout.01301', 'gnu90',
    'variadics', 'prototype', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.variadics.union-layout.01302', 'gnu99',
    'variadics', 'variadic-call', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.variadics.union-layout.01303', 'gnu11',
    'variadics', 'file-scope', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.variadics.union-layout.01304', 'gnu17',
    'variadics', 'constant-expression', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.variadics.union-layout.01305', 'gnu23',
    'variadics', 'cross-module', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.union-layout.01306', 'posix.1-2008',
    'variadics', 'block-scope', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.variadics.union-layout.01307', 'rcc1',
    'variadics', 'runtime-expression', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.library.union-layout.01308', 'c90',
    'library', 'translation-unit', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.library.union-layout.01309', 'c99',
    'library', 'prototype', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.library.union-layout.01310', 'c11',
    'library', 'variadic-call', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.library.union-layout.01311', 'c17',
    'library', 'file-scope', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.library.union-layout.01312', 'c23',
    'library', 'constant-expression', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.library.union-layout.01313', 'gnu90',
    'library', 'cross-module', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.library.union-layout.01314', 'gnu99',
    'library', 'block-scope', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.library.union-layout.01315', 'gnu11',
    'library', 'runtime-expression', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.library.union-layout.01316', 'gnu17',
    'library', 'translation-unit', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.library.union-layout.01317', 'gnu23',
    'library', 'prototype', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.library.union-layout.01318', 'posix.1-2008',
    'library', 'variadic-call', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.library.union-layout.01319', 'rcc1',
    'library', 'file-scope', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.abi.union-layout.01320', 'c90',
    'abi', 'constant-expression', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.abi.union-layout.01321', 'c99',
    'abi', 'cross-module', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.abi.union-layout.01322', 'c11',
    'abi', 'block-scope', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.abi.union-layout.01323', 'c17',
    'abi', 'runtime-expression', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.abi.union-layout.01324', 'c23',
    'abi', 'translation-unit', 'union-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.abi.union-layout.01325', 'gnu90',
    'abi', 'prototype', 'union-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.abi.union-layout.01326', 'gnu99',
    'abi', 'variadic-call', 'union-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.abi.union-layout.01327', 'gnu11',
    'abi', 'file-scope', 'union-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.abi.union-layout.01328', 'gnu17',
    'abi', 'constant-expression', 'union-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.abi.union-layout.01329', 'gnu23',
    'abi', 'cross-module', 'union-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.abi.union-layout.01330', 'posix.1-2008',
    'abi', 'block-scope', 'union-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.abi.union-layout.01331', 'rcc1',
    'abi', 'runtime-expression', 'union-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.object-format.union-layout.01332', 'c90',
    'object-format', 'translation-unit', 'union-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.object-format.union-layout.01333', 'c99',
    'object-format', 'prototype', 'union-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.object-format.union-layout.01334', 'c11',
    'object-format', 'variadic-call', 'union-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.object-format.union-layout.01335', 'c17',
    'object-format', 'file-scope', 'union-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.object-format.union-layout.01336', 'c23',
    'object-format', 'constant-expression', 'union-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.object-format.union-layout.01337', 'gnu90',
    'object-format', 'cross-module', 'union-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.object-format.union-layout.01338', 'gnu99',
    'object-format', 'block-scope', 'union-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.object-format.union-layout.01339', 'gnu11',
    'object-format', 'runtime-expression', 'union-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.object-format.union-layout.01340', 'gnu17',
    'object-format', 'translation-unit', 'union-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.object-format.union-layout.01341', 'gnu23',
    'object-format', 'prototype', 'union-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.union-layout.01342', 'posix.1-2008',
    'object-format', 'variadic-call', 'union-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.object-format.union-layout.01343', 'rcc1',
    'object-format', 'file-scope', 'union-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.lexing.bitfield-layout.01344', 'c90',
    'lexing', 'cross-module', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.lexing.bitfield-layout.01345', 'c99',
    'lexing', 'block-scope', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.lexing.bitfield-layout.01346', 'c11',
    'lexing', 'runtime-expression', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.lexing.bitfield-layout.01347', 'c17',
    'lexing', 'translation-unit', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.lexing.bitfield-layout.01348', 'c23',
    'lexing', 'prototype', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.lexing.bitfield-layout.01349', 'gnu90',
    'lexing', 'variadic-call', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.lexing.bitfield-layout.01350', 'gnu99',
    'lexing', 'file-scope', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.lexing.bitfield-layout.01351', 'gnu11',
    'lexing', 'constant-expression', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.lexing.bitfield-layout.01352', 'gnu17',
    'lexing', 'cross-module', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.lexing.bitfield-layout.01353', 'gnu23',
    'lexing', 'block-scope', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.bitfield-layout.01354', 'posix.1-2008',
    'lexing', 'runtime-expression', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.lexing.bitfield-layout.01355', 'rcc1',
    'lexing', 'translation-unit', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.preprocessing.bitfield-layout.01356', 'c90',
    'preprocessing', 'prototype', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.preprocessing.bitfield-layout.01357', 'c99',
    'preprocessing', 'variadic-call', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.preprocessing.bitfield-layout.01358', 'c11',
    'preprocessing', 'file-scope', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.preprocessing.bitfield-layout.01359', 'c17',
    'preprocessing', 'constant-expression', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.preprocessing.bitfield-layout.01360', 'c23',
    'preprocessing', 'cross-module', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.preprocessing.bitfield-layout.01361', 'gnu90',
    'preprocessing', 'block-scope', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.preprocessing.bitfield-layout.01362', 'gnu99',
    'preprocessing', 'runtime-expression', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.preprocessing.bitfield-layout.01363', 'gnu11',
    'preprocessing', 'translation-unit', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.preprocessing.bitfield-layout.01364', 'gnu17',
    'preprocessing', 'prototype', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.preprocessing.bitfield-layout.01365', 'gnu23',
    'preprocessing', 'variadic-call', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.bitfield-layout.01366', 'posix.1-2008',
    'preprocessing', 'file-scope', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.preprocessing.bitfield-layout.01367', 'rcc1',
    'preprocessing', 'constant-expression', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.declarations.bitfield-layout.01368', 'c90',
    'declarations', 'cross-module', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.declarations.bitfield-layout.01369', 'c99',
    'declarations', 'block-scope', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.declarations.bitfield-layout.01370', 'c11',
    'declarations', 'runtime-expression', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.declarations.bitfield-layout.01371', 'c17',
    'declarations', 'translation-unit', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.declarations.bitfield-layout.01372', 'c23',
    'declarations', 'prototype', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.declarations.bitfield-layout.01373', 'gnu90',
    'declarations', 'variadic-call', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.declarations.bitfield-layout.01374', 'gnu99',
    'declarations', 'file-scope', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.declarations.bitfield-layout.01375', 'gnu11',
    'declarations', 'constant-expression', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.declarations.bitfield-layout.01376', 'gnu17',
    'declarations', 'cross-module', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.declarations.bitfield-layout.01377', 'gnu23',
    'declarations', 'block-scope', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.bitfield-layout.01378', 'posix.1-2008',
    'declarations', 'runtime-expression', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.declarations.bitfield-layout.01379', 'rcc1',
    'declarations', 'translation-unit', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.types.bitfield-layout.01380', 'c90',
    'types', 'prototype', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.types.bitfield-layout.01381', 'c99',
    'types', 'variadic-call', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.types.bitfield-layout.01382', 'c11',
    'types', 'file-scope', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.types.bitfield-layout.01383', 'c17',
    'types', 'constant-expression', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.types.bitfield-layout.01384', 'c23',
    'types', 'cross-module', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.types.bitfield-layout.01385', 'gnu90',
    'types', 'block-scope', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.types.bitfield-layout.01386', 'gnu99',
    'types', 'runtime-expression', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.types.bitfield-layout.01387', 'gnu11',
    'types', 'translation-unit', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.types.bitfield-layout.01388', 'gnu17',
    'types', 'prototype', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.types.bitfield-layout.01389', 'gnu23',
    'types', 'variadic-call', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.types.bitfield-layout.01390', 'posix.1-2008',
    'types', 'file-scope', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.types.bitfield-layout.01391', 'rcc1',
    'types', 'constant-expression', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.conversions.bitfield-layout.01392', 'c90',
    'conversions', 'cross-module', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.conversions.bitfield-layout.01393', 'c99',
    'conversions', 'block-scope', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.conversions.bitfield-layout.01394', 'c11',
    'conversions', 'runtime-expression', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.conversions.bitfield-layout.01395', 'c17',
    'conversions', 'translation-unit', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.conversions.bitfield-layout.01396', 'c23',
    'conversions', 'prototype', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.conversions.bitfield-layout.01397', 'gnu90',
    'conversions', 'variadic-call', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.conversions.bitfield-layout.01398', 'gnu99',
    'conversions', 'file-scope', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.conversions.bitfield-layout.01399', 'gnu11',
    'conversions', 'constant-expression', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.conversions.bitfield-layout.01400', 'gnu17',
    'conversions', 'cross-module', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.conversions.bitfield-layout.01401', 'gnu23',
    'conversions', 'block-scope', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.bitfield-layout.01402', 'posix.1-2008',
    'conversions', 'runtime-expression', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.conversions.bitfield-layout.01403', 'rcc1',
    'conversions', 'translation-unit', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.expressions.bitfield-layout.01404', 'c90',
    'expressions', 'prototype', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.expressions.bitfield-layout.01405', 'c99',
    'expressions', 'variadic-call', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.expressions.bitfield-layout.01406', 'c11',
    'expressions', 'file-scope', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.expressions.bitfield-layout.01407', 'c17',
    'expressions', 'constant-expression', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.expressions.bitfield-layout.01408', 'c23',
    'expressions', 'cross-module', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.expressions.bitfield-layout.01409', 'gnu90',
    'expressions', 'block-scope', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.expressions.bitfield-layout.01410', 'gnu99',
    'expressions', 'runtime-expression', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.expressions.bitfield-layout.01411', 'gnu11',
    'expressions', 'translation-unit', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.expressions.bitfield-layout.01412', 'gnu17',
    'expressions', 'prototype', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.expressions.bitfield-layout.01413', 'gnu23',
    'expressions', 'variadic-call', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.bitfield-layout.01414', 'posix.1-2008',
    'expressions', 'file-scope', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.expressions.bitfield-layout.01415', 'rcc1',
    'expressions', 'constant-expression', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.statements.bitfield-layout.01416', 'c90',
    'statements', 'cross-module', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.statements.bitfield-layout.01417', 'c99',
    'statements', 'block-scope', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.statements.bitfield-layout.01418', 'c11',
    'statements', 'runtime-expression', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.statements.bitfield-layout.01419', 'c17',
    'statements', 'translation-unit', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.statements.bitfield-layout.01420', 'c23',
    'statements', 'prototype', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.statements.bitfield-layout.01421', 'gnu90',
    'statements', 'variadic-call', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.statements.bitfield-layout.01422', 'gnu99',
    'statements', 'file-scope', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.statements.bitfield-layout.01423', 'gnu11',
    'statements', 'constant-expression', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.statements.bitfield-layout.01424', 'gnu17',
    'statements', 'cross-module', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.statements.bitfield-layout.01425', 'gnu23',
    'statements', 'block-scope', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.statements.bitfield-layout.01426', 'posix.1-2008',
    'statements', 'runtime-expression', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.statements.bitfield-layout.01427', 'rcc1',
    'statements', 'translation-unit', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.functions.bitfield-layout.01428', 'c90',
    'functions', 'prototype', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.functions.bitfield-layout.01429', 'c99',
    'functions', 'variadic-call', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.functions.bitfield-layout.01430', 'c11',
    'functions', 'file-scope', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.functions.bitfield-layout.01431', 'c17',
    'functions', 'constant-expression', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.functions.bitfield-layout.01432', 'c23',
    'functions', 'cross-module', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.functions.bitfield-layout.01433', 'gnu90',
    'functions', 'block-scope', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.functions.bitfield-layout.01434', 'gnu99',
    'functions', 'runtime-expression', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.functions.bitfield-layout.01435', 'gnu11',
    'functions', 'translation-unit', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.functions.bitfield-layout.01436', 'gnu17',
    'functions', 'prototype', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.functions.bitfield-layout.01437', 'gnu23',
    'functions', 'variadic-call', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.functions.bitfield-layout.01438', 'posix.1-2008',
    'functions', 'file-scope', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.functions.bitfield-layout.01439', 'rcc1',
    'functions', 'constant-expression', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.aggregates.bitfield-layout.01440', 'c90',
    'aggregates', 'cross-module', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.aggregates.bitfield-layout.01441', 'c99',
    'aggregates', 'block-scope', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.aggregates.bitfield-layout.01442', 'c11',
    'aggregates', 'runtime-expression', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.aggregates.bitfield-layout.01443', 'c17',
    'aggregates', 'translation-unit', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.aggregates.bitfield-layout.01444', 'c23',
    'aggregates', 'prototype', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.aggregates.bitfield-layout.01445', 'gnu90',
    'aggregates', 'variadic-call', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.aggregates.bitfield-layout.01446', 'gnu99',
    'aggregates', 'file-scope', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.aggregates.bitfield-layout.01447', 'gnu11',
    'aggregates', 'constant-expression', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.aggregates.bitfield-layout.01448', 'gnu17',
    'aggregates', 'cross-module', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.aggregates.bitfield-layout.01449', 'gnu23',
    'aggregates', 'block-scope', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.bitfield-layout.01450', 'posix.1-2008',
    'aggregates', 'runtime-expression', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.aggregates.bitfield-layout.01451', 'rcc1',
    'aggregates', 'translation-unit', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.initializers.bitfield-layout.01452', 'c90',
    'initializers', 'prototype', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.initializers.bitfield-layout.01453', 'c99',
    'initializers', 'variadic-call', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.initializers.bitfield-layout.01454', 'c11',
    'initializers', 'file-scope', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.initializers.bitfield-layout.01455', 'c17',
    'initializers', 'constant-expression', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.initializers.bitfield-layout.01456', 'c23',
    'initializers', 'cross-module', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.initializers.bitfield-layout.01457', 'gnu90',
    'initializers', 'block-scope', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.initializers.bitfield-layout.01458', 'gnu99',
    'initializers', 'runtime-expression', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.initializers.bitfield-layout.01459', 'gnu11',
    'initializers', 'translation-unit', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.initializers.bitfield-layout.01460', 'gnu17',
    'initializers', 'prototype', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.initializers.bitfield-layout.01461', 'gnu23',
    'initializers', 'variadic-call', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.bitfield-layout.01462', 'posix.1-2008',
    'initializers', 'file-scope', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.initializers.bitfield-layout.01463', 'rcc1',
    'initializers', 'constant-expression', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.floating.bitfield-layout.01464', 'c90',
    'floating', 'cross-module', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.floating.bitfield-layout.01465', 'c99',
    'floating', 'block-scope', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.floating.bitfield-layout.01466', 'c11',
    'floating', 'runtime-expression', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.floating.bitfield-layout.01467', 'c17',
    'floating', 'translation-unit', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.floating.bitfield-layout.01468', 'c23',
    'floating', 'prototype', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.floating.bitfield-layout.01469', 'gnu90',
    'floating', 'variadic-call', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.floating.bitfield-layout.01470', 'gnu99',
    'floating', 'file-scope', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.floating.bitfield-layout.01471', 'gnu11',
    'floating', 'constant-expression', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.floating.bitfield-layout.01472', 'gnu17',
    'floating', 'cross-module', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.floating.bitfield-layout.01473', 'gnu23',
    'floating', 'block-scope', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.floating.bitfield-layout.01474', 'posix.1-2008',
    'floating', 'runtime-expression', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.floating.bitfield-layout.01475', 'rcc1',
    'floating', 'translation-unit', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.atomics.bitfield-layout.01476', 'c90',
    'atomics', 'prototype', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'c99.atomics.bitfield-layout.01477', 'c99',
    'atomics', 'variadic-call', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.atomics.bitfield-layout.01478', 'c11',
    'atomics', 'file-scope', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.atomics.bitfield-layout.01479', 'c17',
    'atomics', 'constant-expression', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.atomics.bitfield-layout.01480', 'c23',
    'atomics', 'cross-module', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.atomics.bitfield-layout.01481', 'gnu90',
    'atomics', 'block-scope', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.atomics.bitfield-layout.01482', 'gnu99',
    'atomics', 'runtime-expression', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.atomics.bitfield-layout.01483', 'gnu11',
    'atomics', 'translation-unit', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.atomics.bitfield-layout.01484', 'gnu17',
    'atomics', 'prototype', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.atomics.bitfield-layout.01485', 'gnu23',
    'atomics', 'variadic-call', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.bitfield-layout.01486', 'posix.1-2008',
    'atomics', 'file-scope', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.atomics.bitfield-layout.01487', 'rcc1',
    'atomics', 'constant-expression', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.variadics.bitfield-layout.01488', 'c90',
    'variadics', 'cross-module', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'c99.variadics.bitfield-layout.01489', 'c99',
    'variadics', 'block-scope', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.variadics.bitfield-layout.01490', 'c11',
    'variadics', 'runtime-expression', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.variadics.bitfield-layout.01491', 'c17',
    'variadics', 'translation-unit', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.variadics.bitfield-layout.01492', 'c23',
    'variadics', 'prototype', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.variadics.bitfield-layout.01493', 'gnu90',
    'variadics', 'variadic-call', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.variadics.bitfield-layout.01494', 'gnu99',
    'variadics', 'file-scope', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.variadics.bitfield-layout.01495', 'gnu11',
    'variadics', 'constant-expression', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.variadics.bitfield-layout.01496', 'gnu17',
    'variadics', 'cross-module', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.variadics.bitfield-layout.01497', 'gnu23',
    'variadics', 'block-scope', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.bitfield-layout.01498', 'posix.1-2008',
    'variadics', 'runtime-expression', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.variadics.bitfield-layout.01499', 'rcc1',
    'variadics', 'translation-unit', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.library.bitfield-layout.01500', 'c90',
    'library', 'prototype', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'c99.library.bitfield-layout.01501', 'c99',
    'library', 'variadic-call', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.library.bitfield-layout.01502', 'c11',
    'library', 'file-scope', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.library.bitfield-layout.01503', 'c17',
    'library', 'constant-expression', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.library.bitfield-layout.01504', 'c23',
    'library', 'cross-module', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.library.bitfield-layout.01505', 'gnu90',
    'library', 'block-scope', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.library.bitfield-layout.01506', 'gnu99',
    'library', 'runtime-expression', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.library.bitfield-layout.01507', 'gnu11',
    'library', 'translation-unit', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.library.bitfield-layout.01508', 'gnu17',
    'library', 'prototype', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.library.bitfield-layout.01509', 'gnu23',
    'library', 'variadic-call', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.library.bitfield-layout.01510', 'posix.1-2008',
    'library', 'file-scope', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.library.bitfield-layout.01511', 'rcc1',
    'library', 'constant-expression', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.abi.bitfield-layout.01512', 'c90',
    'abi', 'cross-module', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'c99.abi.bitfield-layout.01513', 'c99',
    'abi', 'block-scope', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.abi.bitfield-layout.01514', 'c11',
    'abi', 'runtime-expression', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.abi.bitfield-layout.01515', 'c17',
    'abi', 'translation-unit', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.abi.bitfield-layout.01516', 'c23',
    'abi', 'prototype', 'bitfield-layout',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.abi.bitfield-layout.01517', 'gnu90',
    'abi', 'variadic-call', 'bitfield-layout',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.abi.bitfield-layout.01518', 'gnu99',
    'abi', 'file-scope', 'bitfield-layout',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.abi.bitfield-layout.01519', 'gnu11',
    'abi', 'constant-expression', 'bitfield-layout',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.abi.bitfield-layout.01520', 'gnu17',
    'abi', 'cross-module', 'bitfield-layout',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.abi.bitfield-layout.01521', 'gnu23',
    'abi', 'block-scope', 'bitfield-layout',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.abi.bitfield-layout.01522', 'posix.1-2008',
    'abi', 'runtime-expression', 'bitfield-layout',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.abi.bitfield-layout.01523', 'rcc1',
    'abi', 'translation-unit', 'bitfield-layout',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.object-format.bitfield-layout.01524', 'c90',
    'object-format', 'prototype', 'bitfield-layout',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.object-format.bitfield-layout.01525', 'c99',
    'object-format', 'variadic-call', 'bitfield-layout',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.object-format.bitfield-layout.01526', 'c11',
    'object-format', 'file-scope', 'bitfield-layout',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.object-format.bitfield-layout.01527', 'c17',
    'object-format', 'constant-expression', 'bitfield-layout',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.object-format.bitfield-layout.01528', 'c23',
    'object-format', 'cross-module', 'bitfield-layout',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.object-format.bitfield-layout.01529', 'gnu90',
    'object-format', 'block-scope', 'bitfield-layout',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.object-format.bitfield-layout.01530', 'gnu99',
    'object-format', 'runtime-expression', 'bitfield-layout',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.object-format.bitfield-layout.01531', 'gnu11',
    'object-format', 'translation-unit', 'bitfield-layout',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.object-format.bitfield-layout.01532', 'gnu17',
    'object-format', 'prototype', 'bitfield-layout',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.object-format.bitfield-layout.01533', 'gnu23',
    'object-format', 'variadic-call', 'bitfield-layout',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.bitfield-layout.01534', 'posix.1-2008',
    'object-format', 'file-scope', 'bitfield-layout',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.object-format.bitfield-layout.01535', 'rcc1',
    'object-format', 'constant-expression', 'bitfield-layout',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.lexing.designated-initializer.01536', 'c90',
    'lexing', 'variadic-call', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'c99.lexing.designated-initializer.01537', 'c99',
    'lexing', 'file-scope', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.lexing.designated-initializer.01538', 'c11',
    'lexing', 'constant-expression', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.lexing.designated-initializer.01539', 'c17',
    'lexing', 'cross-module', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.lexing.designated-initializer.01540', 'c23',
    'lexing', 'block-scope', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.lexing.designated-initializer.01541', 'gnu90',
    'lexing', 'runtime-expression', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.lexing.designated-initializer.01542', 'gnu99',
    'lexing', 'translation-unit', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.lexing.designated-initializer.01543', 'gnu11',
    'lexing', 'prototype', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.lexing.designated-initializer.01544', 'gnu17',
    'lexing', 'variadic-call', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.lexing.designated-initializer.01545', 'gnu23',
    'lexing', 'file-scope', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.designated-initializer.01546', 'posix.1-2008',
    'lexing', 'constant-expression', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.lexing.designated-initializer.01547', 'rcc1',
    'lexing', 'cross-module', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.preprocessing.designated-initializer.01548', 'c90',
    'preprocessing', 'block-scope', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'c99.preprocessing.designated-initializer.01549', 'c99',
    'preprocessing', 'runtime-expression', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.preprocessing.designated-initializer.01550', 'c11',
    'preprocessing', 'translation-unit', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.preprocessing.designated-initializer.01551', 'c17',
    'preprocessing', 'prototype', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.preprocessing.designated-initializer.01552', 'c23',
    'preprocessing', 'variadic-call', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.preprocessing.designated-initializer.01553', 'gnu90',
    'preprocessing', 'file-scope', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.preprocessing.designated-initializer.01554', 'gnu99',
    'preprocessing', 'constant-expression', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.preprocessing.designated-initializer.01555', 'gnu11',
    'preprocessing', 'cross-module', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.preprocessing.designated-initializer.01556', 'gnu17',
    'preprocessing', 'block-scope', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.preprocessing.designated-initializer.01557', 'gnu23',
    'preprocessing', 'runtime-expression', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.designated-initializer.01558', 'posix.1-2008',
    'preprocessing', 'translation-unit', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.preprocessing.designated-initializer.01559', 'rcc1',
    'preprocessing', 'prototype', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.declarations.designated-initializer.01560', 'c90',
    'declarations', 'variadic-call', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'c99.declarations.designated-initializer.01561', 'c99',
    'declarations', 'file-scope', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.declarations.designated-initializer.01562', 'c11',
    'declarations', 'constant-expression', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.declarations.designated-initializer.01563', 'c17',
    'declarations', 'cross-module', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.declarations.designated-initializer.01564', 'c23',
    'declarations', 'block-scope', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.declarations.designated-initializer.01565', 'gnu90',
    'declarations', 'runtime-expression', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.declarations.designated-initializer.01566', 'gnu99',
    'declarations', 'translation-unit', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.declarations.designated-initializer.01567', 'gnu11',
    'declarations', 'prototype', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.declarations.designated-initializer.01568', 'gnu17',
    'declarations', 'variadic-call', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.declarations.designated-initializer.01569', 'gnu23',
    'declarations', 'file-scope', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.designated-initializer.01570', 'posix.1-2008',
    'declarations', 'constant-expression', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.declarations.designated-initializer.01571', 'rcc1',
    'declarations', 'cross-module', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.types.designated-initializer.01572', 'c90',
    'types', 'block-scope', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'c99.types.designated-initializer.01573', 'c99',
    'types', 'runtime-expression', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.types.designated-initializer.01574', 'c11',
    'types', 'translation-unit', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.types.designated-initializer.01575', 'c17',
    'types', 'prototype', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.types.designated-initializer.01576', 'c23',
    'types', 'variadic-call', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.types.designated-initializer.01577', 'gnu90',
    'types', 'file-scope', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.types.designated-initializer.01578', 'gnu99',
    'types', 'constant-expression', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.types.designated-initializer.01579', 'gnu11',
    'types', 'cross-module', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.types.designated-initializer.01580', 'gnu17',
    'types', 'block-scope', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.types.designated-initializer.01581', 'gnu23',
    'types', 'runtime-expression', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.types.designated-initializer.01582', 'posix.1-2008',
    'types', 'translation-unit', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.types.designated-initializer.01583', 'rcc1',
    'types', 'prototype', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.conversions.designated-initializer.01584', 'c90',
    'conversions', 'variadic-call', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.conversions.designated-initializer.01585', 'c99',
    'conversions', 'file-scope', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.conversions.designated-initializer.01586', 'c11',
    'conversions', 'constant-expression', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.conversions.designated-initializer.01587', 'c17',
    'conversions', 'cross-module', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.conversions.designated-initializer.01588', 'c23',
    'conversions', 'block-scope', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.conversions.designated-initializer.01589', 'gnu90',
    'conversions', 'runtime-expression', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.conversions.designated-initializer.01590', 'gnu99',
    'conversions', 'translation-unit', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.conversions.designated-initializer.01591', 'gnu11',
    'conversions', 'prototype', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.conversions.designated-initializer.01592', 'gnu17',
    'conversions', 'variadic-call', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.conversions.designated-initializer.01593', 'gnu23',
    'conversions', 'file-scope', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.designated-initializer.01594', 'posix.1-2008',
    'conversions', 'constant-expression', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.conversions.designated-initializer.01595', 'rcc1',
    'conversions', 'cross-module', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.expressions.designated-initializer.01596', 'c90',
    'expressions', 'block-scope', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'c99.expressions.designated-initializer.01597', 'c99',
    'expressions', 'runtime-expression', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.expressions.designated-initializer.01598', 'c11',
    'expressions', 'translation-unit', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.expressions.designated-initializer.01599', 'c17',
    'expressions', 'prototype', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.expressions.designated-initializer.01600', 'c23',
    'expressions', 'variadic-call', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.expressions.designated-initializer.01601', 'gnu90',
    'expressions', 'file-scope', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.expressions.designated-initializer.01602', 'gnu99',
    'expressions', 'constant-expression', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.expressions.designated-initializer.01603', 'gnu11',
    'expressions', 'cross-module', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.expressions.designated-initializer.01604', 'gnu17',
    'expressions', 'block-scope', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.expressions.designated-initializer.01605', 'gnu23',
    'expressions', 'runtime-expression', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.designated-initializer.01606', 'posix.1-2008',
    'expressions', 'translation-unit', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.expressions.designated-initializer.01607', 'rcc1',
    'expressions', 'prototype', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.statements.designated-initializer.01608', 'c90',
    'statements', 'variadic-call', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'c99.statements.designated-initializer.01609', 'c99',
    'statements', 'file-scope', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.statements.designated-initializer.01610', 'c11',
    'statements', 'constant-expression', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.statements.designated-initializer.01611', 'c17',
    'statements', 'cross-module', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.statements.designated-initializer.01612', 'c23',
    'statements', 'block-scope', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.statements.designated-initializer.01613', 'gnu90',
    'statements', 'runtime-expression', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.statements.designated-initializer.01614', 'gnu99',
    'statements', 'translation-unit', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.statements.designated-initializer.01615', 'gnu11',
    'statements', 'prototype', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.statements.designated-initializer.01616', 'gnu17',
    'statements', 'variadic-call', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.statements.designated-initializer.01617', 'gnu23',
    'statements', 'file-scope', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.statements.designated-initializer.01618', 'posix.1-2008',
    'statements', 'constant-expression', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.statements.designated-initializer.01619', 'rcc1',
    'statements', 'cross-module', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.functions.designated-initializer.01620', 'c90',
    'functions', 'block-scope', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'c99.functions.designated-initializer.01621', 'c99',
    'functions', 'runtime-expression', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.functions.designated-initializer.01622', 'c11',
    'functions', 'translation-unit', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.functions.designated-initializer.01623', 'c17',
    'functions', 'prototype', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.functions.designated-initializer.01624', 'c23',
    'functions', 'variadic-call', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.functions.designated-initializer.01625', 'gnu90',
    'functions', 'file-scope', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.functions.designated-initializer.01626', 'gnu99',
    'functions', 'constant-expression', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.functions.designated-initializer.01627', 'gnu11',
    'functions', 'cross-module', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.functions.designated-initializer.01628', 'gnu17',
    'functions', 'block-scope', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.functions.designated-initializer.01629', 'gnu23',
    'functions', 'runtime-expression', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.functions.designated-initializer.01630', 'posix.1-2008',
    'functions', 'translation-unit', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.functions.designated-initializer.01631', 'rcc1',
    'functions', 'prototype', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.aggregates.designated-initializer.01632', 'c90',
    'aggregates', 'variadic-call', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'c99.aggregates.designated-initializer.01633', 'c99',
    'aggregates', 'file-scope', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.aggregates.designated-initializer.01634', 'c11',
    'aggregates', 'constant-expression', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.aggregates.designated-initializer.01635', 'c17',
    'aggregates', 'cross-module', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.aggregates.designated-initializer.01636', 'c23',
    'aggregates', 'block-scope', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.aggregates.designated-initializer.01637', 'gnu90',
    'aggregates', 'runtime-expression', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.aggregates.designated-initializer.01638', 'gnu99',
    'aggregates', 'translation-unit', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.aggregates.designated-initializer.01639', 'gnu11',
    'aggregates', 'prototype', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.aggregates.designated-initializer.01640', 'gnu17',
    'aggregates', 'variadic-call', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.aggregates.designated-initializer.01641', 'gnu23',
    'aggregates', 'file-scope', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.designated-initializer.01642', 'posix.1-2008',
    'aggregates', 'constant-expression', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.aggregates.designated-initializer.01643', 'rcc1',
    'aggregates', 'cross-module', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.initializers.designated-initializer.01644', 'c90',
    'initializers', 'block-scope', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.initializers.designated-initializer.01645', 'c99',
    'initializers', 'runtime-expression', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.initializers.designated-initializer.01646', 'c11',
    'initializers', 'translation-unit', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.initializers.designated-initializer.01647', 'c17',
    'initializers', 'prototype', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.initializers.designated-initializer.01648', 'c23',
    'initializers', 'variadic-call', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.initializers.designated-initializer.01649', 'gnu90',
    'initializers', 'file-scope', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.initializers.designated-initializer.01650', 'gnu99',
    'initializers', 'constant-expression', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.initializers.designated-initializer.01651', 'gnu11',
    'initializers', 'cross-module', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.initializers.designated-initializer.01652', 'gnu17',
    'initializers', 'block-scope', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.initializers.designated-initializer.01653', 'gnu23',
    'initializers', 'runtime-expression', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.designated-initializer.01654', 'posix.1-2008',
    'initializers', 'translation-unit', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.initializers.designated-initializer.01655', 'rcc1',
    'initializers', 'prototype', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.floating.designated-initializer.01656', 'c90',
    'floating', 'variadic-call', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'c99.floating.designated-initializer.01657', 'c99',
    'floating', 'file-scope', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.floating.designated-initializer.01658', 'c11',
    'floating', 'constant-expression', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.floating.designated-initializer.01659', 'c17',
    'floating', 'cross-module', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.floating.designated-initializer.01660', 'c23',
    'floating', 'block-scope', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.floating.designated-initializer.01661', 'gnu90',
    'floating', 'runtime-expression', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.floating.designated-initializer.01662', 'gnu99',
    'floating', 'translation-unit', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.floating.designated-initializer.01663', 'gnu11',
    'floating', 'prototype', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.floating.designated-initializer.01664', 'gnu17',
    'floating', 'variadic-call', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.floating.designated-initializer.01665', 'gnu23',
    'floating', 'file-scope', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.floating.designated-initializer.01666', 'posix.1-2008',
    'floating', 'constant-expression', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.floating.designated-initializer.01667', 'rcc1',
    'floating', 'cross-module', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.atomics.designated-initializer.01668', 'c90',
    'atomics', 'block-scope', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'c99.atomics.designated-initializer.01669', 'c99',
    'atomics', 'runtime-expression', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.atomics.designated-initializer.01670', 'c11',
    'atomics', 'translation-unit', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.atomics.designated-initializer.01671', 'c17',
    'atomics', 'prototype', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.atomics.designated-initializer.01672', 'c23',
    'atomics', 'variadic-call', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.atomics.designated-initializer.01673', 'gnu90',
    'atomics', 'file-scope', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.atomics.designated-initializer.01674', 'gnu99',
    'atomics', 'constant-expression', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.atomics.designated-initializer.01675', 'gnu11',
    'atomics', 'cross-module', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.atomics.designated-initializer.01676', 'gnu17',
    'atomics', 'block-scope', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.atomics.designated-initializer.01677', 'gnu23',
    'atomics', 'runtime-expression', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.designated-initializer.01678', 'posix.1-2008',
    'atomics', 'translation-unit', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.atomics.designated-initializer.01679', 'rcc1',
    'atomics', 'prototype', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.variadics.designated-initializer.01680', 'c90',
    'variadics', 'variadic-call', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'c99.variadics.designated-initializer.01681', 'c99',
    'variadics', 'file-scope', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.variadics.designated-initializer.01682', 'c11',
    'variadics', 'constant-expression', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.variadics.designated-initializer.01683', 'c17',
    'variadics', 'cross-module', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.variadics.designated-initializer.01684', 'c23',
    'variadics', 'block-scope', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.variadics.designated-initializer.01685', 'gnu90',
    'variadics', 'runtime-expression', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.variadics.designated-initializer.01686', 'gnu99',
    'variadics', 'translation-unit', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.variadics.designated-initializer.01687', 'gnu11',
    'variadics', 'prototype', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.variadics.designated-initializer.01688', 'gnu17',
    'variadics', 'variadic-call', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.variadics.designated-initializer.01689', 'gnu23',
    'variadics', 'file-scope', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.designated-initializer.01690', 'posix.1-2008',
    'variadics', 'constant-expression', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.variadics.designated-initializer.01691', 'rcc1',
    'variadics', 'cross-module', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.library.designated-initializer.01692', 'c90',
    'library', 'block-scope', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'c99.library.designated-initializer.01693', 'c99',
    'library', 'runtime-expression', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.library.designated-initializer.01694', 'c11',
    'library', 'translation-unit', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.library.designated-initializer.01695', 'c17',
    'library', 'prototype', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.library.designated-initializer.01696', 'c23',
    'library', 'variadic-call', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.library.designated-initializer.01697', 'gnu90',
    'library', 'file-scope', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.library.designated-initializer.01698', 'gnu99',
    'library', 'constant-expression', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.library.designated-initializer.01699', 'gnu11',
    'library', 'cross-module', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.library.designated-initializer.01700', 'gnu17',
    'library', 'block-scope', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.library.designated-initializer.01701', 'gnu23',
    'library', 'runtime-expression', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.library.designated-initializer.01702', 'posix.1-2008',
    'library', 'translation-unit', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.library.designated-initializer.01703', 'rcc1',
    'library', 'prototype', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.abi.designated-initializer.01704', 'c90',
    'abi', 'variadic-call', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.abi.designated-initializer.01705', 'c99',
    'abi', 'file-scope', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.abi.designated-initializer.01706', 'c11',
    'abi', 'constant-expression', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.abi.designated-initializer.01707', 'c17',
    'abi', 'cross-module', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.abi.designated-initializer.01708', 'c23',
    'abi', 'block-scope', 'designated-initializer',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.abi.designated-initializer.01709', 'gnu90',
    'abi', 'runtime-expression', 'designated-initializer',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.abi.designated-initializer.01710', 'gnu99',
    'abi', 'translation-unit', 'designated-initializer',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.abi.designated-initializer.01711', 'gnu11',
    'abi', 'prototype', 'designated-initializer',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.abi.designated-initializer.01712', 'gnu17',
    'abi', 'variadic-call', 'designated-initializer',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.abi.designated-initializer.01713', 'gnu23',
    'abi', 'file-scope', 'designated-initializer',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.abi.designated-initializer.01714', 'posix.1-2008',
    'abi', 'constant-expression', 'designated-initializer',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.abi.designated-initializer.01715', 'rcc1',
    'abi', 'cross-module', 'designated-initializer',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.object-format.designated-initializer.01716', 'c90',
    'object-format', 'block-scope', 'designated-initializer',
    'compile-fail', 'required');
  AddCase(Result, 'c99.object-format.designated-initializer.01717', 'c99',
    'object-format', 'runtime-expression', 'designated-initializer',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.object-format.designated-initializer.01718', 'c11',
    'object-format', 'translation-unit', 'designated-initializer',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.object-format.designated-initializer.01719', 'c17',
    'object-format', 'prototype', 'designated-initializer',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.object-format.designated-initializer.01720', 'c23',
    'object-format', 'variadic-call', 'designated-initializer',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.object-format.designated-initializer.01721', 'gnu90',
    'object-format', 'file-scope', 'designated-initializer',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.object-format.designated-initializer.01722', 'gnu99',
    'object-format', 'constant-expression', 'designated-initializer',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.object-format.designated-initializer.01723', 'gnu11',
    'object-format', 'cross-module', 'designated-initializer',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.object-format.designated-initializer.01724', 'gnu17',
    'object-format', 'block-scope', 'designated-initializer',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.object-format.designated-initializer.01725', 'gnu23',
    'object-format', 'runtime-expression', 'designated-initializer',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.designated-initializer.01726', 'posix.1-2008',
    'object-format', 'translation-unit', 'designated-initializer',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.object-format.designated-initializer.01727', 'rcc1',
    'object-format', 'prototype', 'designated-initializer',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.lexing.compound-literal.01728', 'c90',
    'lexing', 'translation-unit', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'c99.lexing.compound-literal.01729', 'c99',
    'lexing', 'prototype', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.lexing.compound-literal.01730', 'c11',
    'lexing', 'variadic-call', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.lexing.compound-literal.01731', 'c17',
    'lexing', 'file-scope', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.lexing.compound-literal.01732', 'c23',
    'lexing', 'constant-expression', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.lexing.compound-literal.01733', 'gnu90',
    'lexing', 'cross-module', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.lexing.compound-literal.01734', 'gnu99',
    'lexing', 'block-scope', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.lexing.compound-literal.01735', 'gnu11',
    'lexing', 'runtime-expression', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.lexing.compound-literal.01736', 'gnu17',
    'lexing', 'translation-unit', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.lexing.compound-literal.01737', 'gnu23',
    'lexing', 'prototype', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.compound-literal.01738', 'posix.1-2008',
    'lexing', 'variadic-call', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.lexing.compound-literal.01739', 'rcc1',
    'lexing', 'file-scope', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.preprocessing.compound-literal.01740', 'c90',
    'preprocessing', 'constant-expression', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'c99.preprocessing.compound-literal.01741', 'c99',
    'preprocessing', 'cross-module', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.preprocessing.compound-literal.01742', 'c11',
    'preprocessing', 'block-scope', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.preprocessing.compound-literal.01743', 'c17',
    'preprocessing', 'runtime-expression', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.preprocessing.compound-literal.01744', 'c23',
    'preprocessing', 'translation-unit', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.preprocessing.compound-literal.01745', 'gnu90',
    'preprocessing', 'prototype', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.preprocessing.compound-literal.01746', 'gnu99',
    'preprocessing', 'variadic-call', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.preprocessing.compound-literal.01747', 'gnu11',
    'preprocessing', 'file-scope', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.preprocessing.compound-literal.01748', 'gnu17',
    'preprocessing', 'constant-expression', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.preprocessing.compound-literal.01749', 'gnu23',
    'preprocessing', 'cross-module', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.compound-literal.01750', 'posix.1-2008',
    'preprocessing', 'block-scope', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.preprocessing.compound-literal.01751', 'rcc1',
    'preprocessing', 'runtime-expression', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.declarations.compound-literal.01752', 'c90',
    'declarations', 'translation-unit', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'c99.declarations.compound-literal.01753', 'c99',
    'declarations', 'prototype', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.declarations.compound-literal.01754', 'c11',
    'declarations', 'variadic-call', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.declarations.compound-literal.01755', 'c17',
    'declarations', 'file-scope', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.declarations.compound-literal.01756', 'c23',
    'declarations', 'constant-expression', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.declarations.compound-literal.01757', 'gnu90',
    'declarations', 'cross-module', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.declarations.compound-literal.01758', 'gnu99',
    'declarations', 'block-scope', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.declarations.compound-literal.01759', 'gnu11',
    'declarations', 'runtime-expression', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.declarations.compound-literal.01760', 'gnu17',
    'declarations', 'translation-unit', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.declarations.compound-literal.01761', 'gnu23',
    'declarations', 'prototype', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.compound-literal.01762', 'posix.1-2008',
    'declarations', 'variadic-call', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.declarations.compound-literal.01763', 'rcc1',
    'declarations', 'file-scope', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.types.compound-literal.01764', 'c90',
    'types', 'constant-expression', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.types.compound-literal.01765', 'c99',
    'types', 'cross-module', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.types.compound-literal.01766', 'c11',
    'types', 'block-scope', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.types.compound-literal.01767', 'c17',
    'types', 'runtime-expression', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.types.compound-literal.01768', 'c23',
    'types', 'translation-unit', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.types.compound-literal.01769', 'gnu90',
    'types', 'prototype', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.types.compound-literal.01770', 'gnu99',
    'types', 'variadic-call', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.types.compound-literal.01771', 'gnu11',
    'types', 'file-scope', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.types.compound-literal.01772', 'gnu17',
    'types', 'constant-expression', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.types.compound-literal.01773', 'gnu23',
    'types', 'cross-module', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.types.compound-literal.01774', 'posix.1-2008',
    'types', 'block-scope', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.types.compound-literal.01775', 'rcc1',
    'types', 'runtime-expression', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.conversions.compound-literal.01776', 'c90',
    'conversions', 'translation-unit', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'c99.conversions.compound-literal.01777', 'c99',
    'conversions', 'prototype', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.conversions.compound-literal.01778', 'c11',
    'conversions', 'variadic-call', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.conversions.compound-literal.01779', 'c17',
    'conversions', 'file-scope', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.conversions.compound-literal.01780', 'c23',
    'conversions', 'constant-expression', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.conversions.compound-literal.01781', 'gnu90',
    'conversions', 'cross-module', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.conversions.compound-literal.01782', 'gnu99',
    'conversions', 'block-scope', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.conversions.compound-literal.01783', 'gnu11',
    'conversions', 'runtime-expression', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.conversions.compound-literal.01784', 'gnu17',
    'conversions', 'translation-unit', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.conversions.compound-literal.01785', 'gnu23',
    'conversions', 'prototype', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.compound-literal.01786', 'posix.1-2008',
    'conversions', 'variadic-call', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.conversions.compound-literal.01787', 'rcc1',
    'conversions', 'file-scope', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.expressions.compound-literal.01788', 'c90',
    'expressions', 'constant-expression', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'c99.expressions.compound-literal.01789', 'c99',
    'expressions', 'cross-module', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.expressions.compound-literal.01790', 'c11',
    'expressions', 'block-scope', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.expressions.compound-literal.01791', 'c17',
    'expressions', 'runtime-expression', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.expressions.compound-literal.01792', 'c23',
    'expressions', 'translation-unit', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.expressions.compound-literal.01793', 'gnu90',
    'expressions', 'prototype', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.expressions.compound-literal.01794', 'gnu99',
    'expressions', 'variadic-call', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.expressions.compound-literal.01795', 'gnu11',
    'expressions', 'file-scope', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.expressions.compound-literal.01796', 'gnu17',
    'expressions', 'constant-expression', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.expressions.compound-literal.01797', 'gnu23',
    'expressions', 'cross-module', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.compound-literal.01798', 'posix.1-2008',
    'expressions', 'block-scope', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.expressions.compound-literal.01799', 'rcc1',
    'expressions', 'runtime-expression', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.statements.compound-literal.01800', 'c90',
    'statements', 'translation-unit', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'c99.statements.compound-literal.01801', 'c99',
    'statements', 'prototype', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.statements.compound-literal.01802', 'c11',
    'statements', 'variadic-call', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.statements.compound-literal.01803', 'c17',
    'statements', 'file-scope', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.statements.compound-literal.01804', 'c23',
    'statements', 'constant-expression', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.statements.compound-literal.01805', 'gnu90',
    'statements', 'cross-module', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.statements.compound-literal.01806', 'gnu99',
    'statements', 'block-scope', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.statements.compound-literal.01807', 'gnu11',
    'statements', 'runtime-expression', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.statements.compound-literal.01808', 'gnu17',
    'statements', 'translation-unit', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.statements.compound-literal.01809', 'gnu23',
    'statements', 'prototype', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.statements.compound-literal.01810', 'posix.1-2008',
    'statements', 'variadic-call', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.statements.compound-literal.01811', 'rcc1',
    'statements', 'file-scope', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.functions.compound-literal.01812', 'c90',
    'functions', 'constant-expression', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'c99.functions.compound-literal.01813', 'c99',
    'functions', 'cross-module', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.functions.compound-literal.01814', 'c11',
    'functions', 'block-scope', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.functions.compound-literal.01815', 'c17',
    'functions', 'runtime-expression', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.functions.compound-literal.01816', 'c23',
    'functions', 'translation-unit', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.functions.compound-literal.01817', 'gnu90',
    'functions', 'prototype', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.functions.compound-literal.01818', 'gnu99',
    'functions', 'variadic-call', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.functions.compound-literal.01819', 'gnu11',
    'functions', 'file-scope', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.functions.compound-literal.01820', 'gnu17',
    'functions', 'constant-expression', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.functions.compound-literal.01821', 'gnu23',
    'functions', 'cross-module', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.functions.compound-literal.01822', 'posix.1-2008',
    'functions', 'block-scope', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.functions.compound-literal.01823', 'rcc1',
    'functions', 'runtime-expression', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.aggregates.compound-literal.01824', 'c90',
    'aggregates', 'translation-unit', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.aggregates.compound-literal.01825', 'c99',
    'aggregates', 'prototype', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.aggregates.compound-literal.01826', 'c11',
    'aggregates', 'variadic-call', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.aggregates.compound-literal.01827', 'c17',
    'aggregates', 'file-scope', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.aggregates.compound-literal.01828', 'c23',
    'aggregates', 'constant-expression', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.aggregates.compound-literal.01829', 'gnu90',
    'aggregates', 'cross-module', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.aggregates.compound-literal.01830', 'gnu99',
    'aggregates', 'block-scope', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.aggregates.compound-literal.01831', 'gnu11',
    'aggregates', 'runtime-expression', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.aggregates.compound-literal.01832', 'gnu17',
    'aggregates', 'translation-unit', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.aggregates.compound-literal.01833', 'gnu23',
    'aggregates', 'prototype', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.compound-literal.01834', 'posix.1-2008',
    'aggregates', 'variadic-call', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.aggregates.compound-literal.01835', 'rcc1',
    'aggregates', 'file-scope', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.initializers.compound-literal.01836', 'c90',
    'initializers', 'constant-expression', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'c99.initializers.compound-literal.01837', 'c99',
    'initializers', 'cross-module', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.initializers.compound-literal.01838', 'c11',
    'initializers', 'block-scope', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.initializers.compound-literal.01839', 'c17',
    'initializers', 'runtime-expression', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.initializers.compound-literal.01840', 'c23',
    'initializers', 'translation-unit', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.initializers.compound-literal.01841', 'gnu90',
    'initializers', 'prototype', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.initializers.compound-literal.01842', 'gnu99',
    'initializers', 'variadic-call', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.initializers.compound-literal.01843', 'gnu11',
    'initializers', 'file-scope', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.initializers.compound-literal.01844', 'gnu17',
    'initializers', 'constant-expression', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.initializers.compound-literal.01845', 'gnu23',
    'initializers', 'cross-module', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.compound-literal.01846', 'posix.1-2008',
    'initializers', 'block-scope', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.initializers.compound-literal.01847', 'rcc1',
    'initializers', 'runtime-expression', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.floating.compound-literal.01848', 'c90',
    'floating', 'translation-unit', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'c99.floating.compound-literal.01849', 'c99',
    'floating', 'prototype', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.floating.compound-literal.01850', 'c11',
    'floating', 'variadic-call', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.floating.compound-literal.01851', 'c17',
    'floating', 'file-scope', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.floating.compound-literal.01852', 'c23',
    'floating', 'constant-expression', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.floating.compound-literal.01853', 'gnu90',
    'floating', 'cross-module', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.floating.compound-literal.01854', 'gnu99',
    'floating', 'block-scope', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.floating.compound-literal.01855', 'gnu11',
    'floating', 'runtime-expression', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.floating.compound-literal.01856', 'gnu17',
    'floating', 'translation-unit', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.floating.compound-literal.01857', 'gnu23',
    'floating', 'prototype', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.floating.compound-literal.01858', 'posix.1-2008',
    'floating', 'variadic-call', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.floating.compound-literal.01859', 'rcc1',
    'floating', 'file-scope', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.atomics.compound-literal.01860', 'c90',
    'atomics', 'constant-expression', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'c99.atomics.compound-literal.01861', 'c99',
    'atomics', 'cross-module', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.atomics.compound-literal.01862', 'c11',
    'atomics', 'block-scope', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.atomics.compound-literal.01863', 'c17',
    'atomics', 'runtime-expression', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.atomics.compound-literal.01864', 'c23',
    'atomics', 'translation-unit', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.atomics.compound-literal.01865', 'gnu90',
    'atomics', 'prototype', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.atomics.compound-literal.01866', 'gnu99',
    'atomics', 'variadic-call', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.atomics.compound-literal.01867', 'gnu11',
    'atomics', 'file-scope', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.atomics.compound-literal.01868', 'gnu17',
    'atomics', 'constant-expression', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.atomics.compound-literal.01869', 'gnu23',
    'atomics', 'cross-module', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.compound-literal.01870', 'posix.1-2008',
    'atomics', 'block-scope', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.atomics.compound-literal.01871', 'rcc1',
    'atomics', 'runtime-expression', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.variadics.compound-literal.01872', 'c90',
    'variadics', 'translation-unit', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'c99.variadics.compound-literal.01873', 'c99',
    'variadics', 'prototype', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.variadics.compound-literal.01874', 'c11',
    'variadics', 'variadic-call', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.variadics.compound-literal.01875', 'c17',
    'variadics', 'file-scope', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.variadics.compound-literal.01876', 'c23',
    'variadics', 'constant-expression', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.variadics.compound-literal.01877', 'gnu90',
    'variadics', 'cross-module', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.variadics.compound-literal.01878', 'gnu99',
    'variadics', 'block-scope', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.variadics.compound-literal.01879', 'gnu11',
    'variadics', 'runtime-expression', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.variadics.compound-literal.01880', 'gnu17',
    'variadics', 'translation-unit', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.variadics.compound-literal.01881', 'gnu23',
    'variadics', 'prototype', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.compound-literal.01882', 'posix.1-2008',
    'variadics', 'variadic-call', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.variadics.compound-literal.01883', 'rcc1',
    'variadics', 'file-scope', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.library.compound-literal.01884', 'c90',
    'library', 'constant-expression', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.library.compound-literal.01885', 'c99',
    'library', 'cross-module', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.library.compound-literal.01886', 'c11',
    'library', 'block-scope', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.library.compound-literal.01887', 'c17',
    'library', 'runtime-expression', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.library.compound-literal.01888', 'c23',
    'library', 'translation-unit', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.library.compound-literal.01889', 'gnu90',
    'library', 'prototype', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.library.compound-literal.01890', 'gnu99',
    'library', 'variadic-call', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.library.compound-literal.01891', 'gnu11',
    'library', 'file-scope', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.library.compound-literal.01892', 'gnu17',
    'library', 'constant-expression', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.library.compound-literal.01893', 'gnu23',
    'library', 'cross-module', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.library.compound-literal.01894', 'posix.1-2008',
    'library', 'block-scope', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.library.compound-literal.01895', 'rcc1',
    'library', 'runtime-expression', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.abi.compound-literal.01896', 'c90',
    'abi', 'translation-unit', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'c99.abi.compound-literal.01897', 'c99',
    'abi', 'prototype', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.abi.compound-literal.01898', 'c11',
    'abi', 'variadic-call', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.abi.compound-literal.01899', 'c17',
    'abi', 'file-scope', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.abi.compound-literal.01900', 'c23',
    'abi', 'constant-expression', 'compound-literal',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.abi.compound-literal.01901', 'gnu90',
    'abi', 'cross-module', 'compound-literal',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.abi.compound-literal.01902', 'gnu99',
    'abi', 'block-scope', 'compound-literal',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.abi.compound-literal.01903', 'gnu11',
    'abi', 'runtime-expression', 'compound-literal',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.abi.compound-literal.01904', 'gnu17',
    'abi', 'translation-unit', 'compound-literal',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.abi.compound-literal.01905', 'gnu23',
    'abi', 'prototype', 'compound-literal',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.abi.compound-literal.01906', 'posix.1-2008',
    'abi', 'variadic-call', 'compound-literal',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.abi.compound-literal.01907', 'rcc1',
    'abi', 'file-scope', 'compound-literal',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.object-format.compound-literal.01908', 'c90',
    'object-format', 'constant-expression', 'compound-literal',
    'diagnostic', 'required');
  AddCase(Result, 'c99.object-format.compound-literal.01909', 'c99',
    'object-format', 'cross-module', 'compound-literal',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.object-format.compound-literal.01910', 'c11',
    'object-format', 'block-scope', 'compound-literal',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.object-format.compound-literal.01911', 'c17',
    'object-format', 'runtime-expression', 'compound-literal',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.object-format.compound-literal.01912', 'c23',
    'object-format', 'translation-unit', 'compound-literal',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.object-format.compound-literal.01913', 'gnu90',
    'object-format', 'prototype', 'compound-literal',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.object-format.compound-literal.01914', 'gnu99',
    'object-format', 'variadic-call', 'compound-literal',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.object-format.compound-literal.01915', 'gnu11',
    'object-format', 'file-scope', 'compound-literal',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.object-format.compound-literal.01916', 'gnu17',
    'object-format', 'constant-expression', 'compound-literal',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.object-format.compound-literal.01917', 'gnu23',
    'object-format', 'cross-module', 'compound-literal',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.compound-literal.01918', 'posix.1-2008',
    'object-format', 'block-scope', 'compound-literal',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.object-format.compound-literal.01919', 'rcc1',
    'object-format', 'runtime-expression', 'compound-literal',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.lexing.generic-selection.01920', 'c90',
    'lexing', 'file-scope', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'c99.lexing.generic-selection.01921', 'c99',
    'lexing', 'constant-expression', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.lexing.generic-selection.01922', 'c11',
    'lexing', 'cross-module', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.lexing.generic-selection.01923', 'c17',
    'lexing', 'block-scope', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.lexing.generic-selection.01924', 'c23',
    'lexing', 'runtime-expression', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.lexing.generic-selection.01925', 'gnu90',
    'lexing', 'translation-unit', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.lexing.generic-selection.01926', 'gnu99',
    'lexing', 'prototype', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.lexing.generic-selection.01927', 'gnu11',
    'lexing', 'variadic-call', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.lexing.generic-selection.01928', 'gnu17',
    'lexing', 'file-scope', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.lexing.generic-selection.01929', 'gnu23',
    'lexing', 'constant-expression', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.generic-selection.01930', 'posix.1-2008',
    'lexing', 'cross-module', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.lexing.generic-selection.01931', 'rcc1',
    'lexing', 'block-scope', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.preprocessing.generic-selection.01932', 'c90',
    'preprocessing', 'runtime-expression', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'c99.preprocessing.generic-selection.01933', 'c99',
    'preprocessing', 'translation-unit', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.preprocessing.generic-selection.01934', 'c11',
    'preprocessing', 'prototype', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.preprocessing.generic-selection.01935', 'c17',
    'preprocessing', 'variadic-call', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.preprocessing.generic-selection.01936', 'c23',
    'preprocessing', 'file-scope', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.preprocessing.generic-selection.01937', 'gnu90',
    'preprocessing', 'constant-expression', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.preprocessing.generic-selection.01938', 'gnu99',
    'preprocessing', 'cross-module', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.preprocessing.generic-selection.01939', 'gnu11',
    'preprocessing', 'block-scope', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.preprocessing.generic-selection.01940', 'gnu17',
    'preprocessing', 'runtime-expression', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.preprocessing.generic-selection.01941', 'gnu23',
    'preprocessing', 'translation-unit', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.generic-selection.01942', 'posix.1-2008',
    'preprocessing', 'prototype', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.preprocessing.generic-selection.01943', 'rcc1',
    'preprocessing', 'variadic-call', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.declarations.generic-selection.01944', 'c90',
    'declarations', 'file-scope', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.declarations.generic-selection.01945', 'c99',
    'declarations', 'constant-expression', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.declarations.generic-selection.01946', 'c11',
    'declarations', 'cross-module', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.declarations.generic-selection.01947', 'c17',
    'declarations', 'block-scope', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.declarations.generic-selection.01948', 'c23',
    'declarations', 'runtime-expression', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.declarations.generic-selection.01949', 'gnu90',
    'declarations', 'translation-unit', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.declarations.generic-selection.01950', 'gnu99',
    'declarations', 'prototype', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.declarations.generic-selection.01951', 'gnu11',
    'declarations', 'variadic-call', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.declarations.generic-selection.01952', 'gnu17',
    'declarations', 'file-scope', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.declarations.generic-selection.01953', 'gnu23',
    'declarations', 'constant-expression', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.generic-selection.01954', 'posix.1-2008',
    'declarations', 'cross-module', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.declarations.generic-selection.01955', 'rcc1',
    'declarations', 'block-scope', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.types.generic-selection.01956', 'c90',
    'types', 'runtime-expression', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'c99.types.generic-selection.01957', 'c99',
    'types', 'translation-unit', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.types.generic-selection.01958', 'c11',
    'types', 'prototype', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.types.generic-selection.01959', 'c17',
    'types', 'variadic-call', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.types.generic-selection.01960', 'c23',
    'types', 'file-scope', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.types.generic-selection.01961', 'gnu90',
    'types', 'constant-expression', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.types.generic-selection.01962', 'gnu99',
    'types', 'cross-module', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.types.generic-selection.01963', 'gnu11',
    'types', 'block-scope', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.types.generic-selection.01964', 'gnu17',
    'types', 'runtime-expression', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.types.generic-selection.01965', 'gnu23',
    'types', 'translation-unit', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.types.generic-selection.01966', 'posix.1-2008',
    'types', 'prototype', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.types.generic-selection.01967', 'rcc1',
    'types', 'variadic-call', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.conversions.generic-selection.01968', 'c90',
    'conversions', 'file-scope', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'c99.conversions.generic-selection.01969', 'c99',
    'conversions', 'constant-expression', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.conversions.generic-selection.01970', 'c11',
    'conversions', 'cross-module', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.conversions.generic-selection.01971', 'c17',
    'conversions', 'block-scope', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.conversions.generic-selection.01972', 'c23',
    'conversions', 'runtime-expression', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.conversions.generic-selection.01973', 'gnu90',
    'conversions', 'translation-unit', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.conversions.generic-selection.01974', 'gnu99',
    'conversions', 'prototype', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.conversions.generic-selection.01975', 'gnu11',
    'conversions', 'variadic-call', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.conversions.generic-selection.01976', 'gnu17',
    'conversions', 'file-scope', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.conversions.generic-selection.01977', 'gnu23',
    'conversions', 'constant-expression', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.generic-selection.01978', 'posix.1-2008',
    'conversions', 'cross-module', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.conversions.generic-selection.01979', 'rcc1',
    'conversions', 'block-scope', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.expressions.generic-selection.01980', 'c90',
    'expressions', 'runtime-expression', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'c99.expressions.generic-selection.01981', 'c99',
    'expressions', 'translation-unit', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.expressions.generic-selection.01982', 'c11',
    'expressions', 'prototype', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.expressions.generic-selection.01983', 'c17',
    'expressions', 'variadic-call', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.expressions.generic-selection.01984', 'c23',
    'expressions', 'file-scope', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.expressions.generic-selection.01985', 'gnu90',
    'expressions', 'constant-expression', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.expressions.generic-selection.01986', 'gnu99',
    'expressions', 'cross-module', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.expressions.generic-selection.01987', 'gnu11',
    'expressions', 'block-scope', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.expressions.generic-selection.01988', 'gnu17',
    'expressions', 'runtime-expression', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.expressions.generic-selection.01989', 'gnu23',
    'expressions', 'translation-unit', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.generic-selection.01990', 'posix.1-2008',
    'expressions', 'prototype', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.expressions.generic-selection.01991', 'rcc1',
    'expressions', 'variadic-call', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.statements.generic-selection.01992', 'c90',
    'statements', 'file-scope', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'c99.statements.generic-selection.01993', 'c99',
    'statements', 'constant-expression', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.statements.generic-selection.01994', 'c11',
    'statements', 'cross-module', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.statements.generic-selection.01995', 'c17',
    'statements', 'block-scope', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.statements.generic-selection.01996', 'c23',
    'statements', 'runtime-expression', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.statements.generic-selection.01997', 'gnu90',
    'statements', 'translation-unit', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.statements.generic-selection.01998', 'gnu99',
    'statements', 'prototype', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.statements.generic-selection.01999', 'gnu11',
    'statements', 'variadic-call', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.statements.generic-selection.02000', 'gnu17',
    'statements', 'file-scope', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.statements.generic-selection.02001', 'gnu23',
    'statements', 'constant-expression', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.statements.generic-selection.02002', 'posix.1-2008',
    'statements', 'cross-module', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.statements.generic-selection.02003', 'rcc1',
    'statements', 'block-scope', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.functions.generic-selection.02004', 'c90',
    'functions', 'runtime-expression', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.functions.generic-selection.02005', 'c99',
    'functions', 'translation-unit', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.functions.generic-selection.02006', 'c11',
    'functions', 'prototype', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.functions.generic-selection.02007', 'c17',
    'functions', 'variadic-call', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.functions.generic-selection.02008', 'c23',
    'functions', 'file-scope', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.functions.generic-selection.02009', 'gnu90',
    'functions', 'constant-expression', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.functions.generic-selection.02010', 'gnu99',
    'functions', 'cross-module', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.functions.generic-selection.02011', 'gnu11',
    'functions', 'block-scope', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.functions.generic-selection.02012', 'gnu17',
    'functions', 'runtime-expression', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.functions.generic-selection.02013', 'gnu23',
    'functions', 'translation-unit', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.functions.generic-selection.02014', 'posix.1-2008',
    'functions', 'prototype', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.functions.generic-selection.02015', 'rcc1',
    'functions', 'variadic-call', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.aggregates.generic-selection.02016', 'c90',
    'aggregates', 'file-scope', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'c99.aggregates.generic-selection.02017', 'c99',
    'aggregates', 'constant-expression', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.aggregates.generic-selection.02018', 'c11',
    'aggregates', 'cross-module', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.aggregates.generic-selection.02019', 'c17',
    'aggregates', 'block-scope', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.aggregates.generic-selection.02020', 'c23',
    'aggregates', 'runtime-expression', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.aggregates.generic-selection.02021', 'gnu90',
    'aggregates', 'translation-unit', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.aggregates.generic-selection.02022', 'gnu99',
    'aggregates', 'prototype', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.aggregates.generic-selection.02023', 'gnu11',
    'aggregates', 'variadic-call', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.aggregates.generic-selection.02024', 'gnu17',
    'aggregates', 'file-scope', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.aggregates.generic-selection.02025', 'gnu23',
    'aggregates', 'constant-expression', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.generic-selection.02026', 'posix.1-2008',
    'aggregates', 'cross-module', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.aggregates.generic-selection.02027', 'rcc1',
    'aggregates', 'block-scope', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.initializers.generic-selection.02028', 'c90',
    'initializers', 'runtime-expression', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'c99.initializers.generic-selection.02029', 'c99',
    'initializers', 'translation-unit', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.initializers.generic-selection.02030', 'c11',
    'initializers', 'prototype', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.initializers.generic-selection.02031', 'c17',
    'initializers', 'variadic-call', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.initializers.generic-selection.02032', 'c23',
    'initializers', 'file-scope', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.initializers.generic-selection.02033', 'gnu90',
    'initializers', 'constant-expression', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.initializers.generic-selection.02034', 'gnu99',
    'initializers', 'cross-module', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.initializers.generic-selection.02035', 'gnu11',
    'initializers', 'block-scope', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.initializers.generic-selection.02036', 'gnu17',
    'initializers', 'runtime-expression', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.initializers.generic-selection.02037', 'gnu23',
    'initializers', 'translation-unit', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.generic-selection.02038', 'posix.1-2008',
    'initializers', 'prototype', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.initializers.generic-selection.02039', 'rcc1',
    'initializers', 'variadic-call', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.floating.generic-selection.02040', 'c90',
    'floating', 'file-scope', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'c99.floating.generic-selection.02041', 'c99',
    'floating', 'constant-expression', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.floating.generic-selection.02042', 'c11',
    'floating', 'cross-module', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.floating.generic-selection.02043', 'c17',
    'floating', 'block-scope', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.floating.generic-selection.02044', 'c23',
    'floating', 'runtime-expression', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.floating.generic-selection.02045', 'gnu90',
    'floating', 'translation-unit', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.floating.generic-selection.02046', 'gnu99',
    'floating', 'prototype', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.floating.generic-selection.02047', 'gnu11',
    'floating', 'variadic-call', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.floating.generic-selection.02048', 'gnu17',
    'floating', 'file-scope', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.floating.generic-selection.02049', 'gnu23',
    'floating', 'constant-expression', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.floating.generic-selection.02050', 'posix.1-2008',
    'floating', 'cross-module', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.floating.generic-selection.02051', 'rcc1',
    'floating', 'block-scope', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.atomics.generic-selection.02052', 'c90',
    'atomics', 'runtime-expression', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'c99.atomics.generic-selection.02053', 'c99',
    'atomics', 'translation-unit', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.atomics.generic-selection.02054', 'c11',
    'atomics', 'prototype', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.atomics.generic-selection.02055', 'c17',
    'atomics', 'variadic-call', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.atomics.generic-selection.02056', 'c23',
    'atomics', 'file-scope', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.atomics.generic-selection.02057', 'gnu90',
    'atomics', 'constant-expression', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.atomics.generic-selection.02058', 'gnu99',
    'atomics', 'cross-module', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.atomics.generic-selection.02059', 'gnu11',
    'atomics', 'block-scope', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.atomics.generic-selection.02060', 'gnu17',
    'atomics', 'runtime-expression', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.atomics.generic-selection.02061', 'gnu23',
    'atomics', 'translation-unit', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.generic-selection.02062', 'posix.1-2008',
    'atomics', 'prototype', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.atomics.generic-selection.02063', 'rcc1',
    'atomics', 'variadic-call', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.variadics.generic-selection.02064', 'c90',
    'variadics', 'file-scope', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.variadics.generic-selection.02065', 'c99',
    'variadics', 'constant-expression', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.variadics.generic-selection.02066', 'c11',
    'variadics', 'cross-module', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.variadics.generic-selection.02067', 'c17',
    'variadics', 'block-scope', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.variadics.generic-selection.02068', 'c23',
    'variadics', 'runtime-expression', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.variadics.generic-selection.02069', 'gnu90',
    'variadics', 'translation-unit', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.variadics.generic-selection.02070', 'gnu99',
    'variadics', 'prototype', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.variadics.generic-selection.02071', 'gnu11',
    'variadics', 'variadic-call', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.variadics.generic-selection.02072', 'gnu17',
    'variadics', 'file-scope', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.variadics.generic-selection.02073', 'gnu23',
    'variadics', 'constant-expression', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.generic-selection.02074', 'posix.1-2008',
    'variadics', 'cross-module', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.variadics.generic-selection.02075', 'rcc1',
    'variadics', 'block-scope', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.library.generic-selection.02076', 'c90',
    'library', 'runtime-expression', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'c99.library.generic-selection.02077', 'c99',
    'library', 'translation-unit', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.library.generic-selection.02078', 'c11',
    'library', 'prototype', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.library.generic-selection.02079', 'c17',
    'library', 'variadic-call', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.library.generic-selection.02080', 'c23',
    'library', 'file-scope', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.library.generic-selection.02081', 'gnu90',
    'library', 'constant-expression', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.library.generic-selection.02082', 'gnu99',
    'library', 'cross-module', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.library.generic-selection.02083', 'gnu11',
    'library', 'block-scope', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.library.generic-selection.02084', 'gnu17',
    'library', 'runtime-expression', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.library.generic-selection.02085', 'gnu23',
    'library', 'translation-unit', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.library.generic-selection.02086', 'posix.1-2008',
    'library', 'prototype', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.library.generic-selection.02087', 'rcc1',
    'library', 'variadic-call', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.abi.generic-selection.02088', 'c90',
    'abi', 'file-scope', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'c99.abi.generic-selection.02089', 'c99',
    'abi', 'constant-expression', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.abi.generic-selection.02090', 'c11',
    'abi', 'cross-module', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.abi.generic-selection.02091', 'c17',
    'abi', 'block-scope', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.abi.generic-selection.02092', 'c23',
    'abi', 'runtime-expression', 'generic-selection',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.abi.generic-selection.02093', 'gnu90',
    'abi', 'translation-unit', 'generic-selection',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.abi.generic-selection.02094', 'gnu99',
    'abi', 'prototype', 'generic-selection',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.abi.generic-selection.02095', 'gnu11',
    'abi', 'variadic-call', 'generic-selection',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.abi.generic-selection.02096', 'gnu17',
    'abi', 'file-scope', 'generic-selection',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.abi.generic-selection.02097', 'gnu23',
    'abi', 'constant-expression', 'generic-selection',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.abi.generic-selection.02098', 'posix.1-2008',
    'abi', 'cross-module', 'generic-selection',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.abi.generic-selection.02099', 'rcc1',
    'abi', 'block-scope', 'generic-selection',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.object-format.generic-selection.02100', 'c90',
    'object-format', 'runtime-expression', 'generic-selection',
    'compile-pass', 'required');
  AddCase(Result, 'c99.object-format.generic-selection.02101', 'c99',
    'object-format', 'translation-unit', 'generic-selection',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.object-format.generic-selection.02102', 'c11',
    'object-format', 'prototype', 'generic-selection',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.object-format.generic-selection.02103', 'c17',
    'object-format', 'variadic-call', 'generic-selection',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.object-format.generic-selection.02104', 'c23',
    'object-format', 'file-scope', 'generic-selection',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.object-format.generic-selection.02105', 'gnu90',
    'object-format', 'constant-expression', 'generic-selection',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.object-format.generic-selection.02106', 'gnu99',
    'object-format', 'cross-module', 'generic-selection',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.object-format.generic-selection.02107', 'gnu11',
    'object-format', 'block-scope', 'generic-selection',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.object-format.generic-selection.02108', 'gnu17',
    'object-format', 'runtime-expression', 'generic-selection',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.object-format.generic-selection.02109', 'gnu23',
    'object-format', 'translation-unit', 'generic-selection',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.generic-selection.02110', 'posix.1-2008',
    'object-format', 'prototype', 'generic-selection',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.object-format.generic-selection.02111', 'rcc1',
    'object-format', 'variadic-call', 'generic-selection',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.lexing.static-assert.02112', 'c90',
    'lexing', 'runtime-expression', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'c99.lexing.static-assert.02113', 'c99',
    'lexing', 'translation-unit', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.lexing.static-assert.02114', 'c11',
    'lexing', 'prototype', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.lexing.static-assert.02115', 'c17',
    'lexing', 'variadic-call', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.lexing.static-assert.02116', 'c23',
    'lexing', 'file-scope', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.lexing.static-assert.02117', 'gnu90',
    'lexing', 'constant-expression', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.lexing.static-assert.02118', 'gnu99',
    'lexing', 'cross-module', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.lexing.static-assert.02119', 'gnu11',
    'lexing', 'block-scope', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.lexing.static-assert.02120', 'gnu17',
    'lexing', 'runtime-expression', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.lexing.static-assert.02121', 'gnu23',
    'lexing', 'translation-unit', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.static-assert.02122', 'posix.1-2008',
    'lexing', 'prototype', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.lexing.static-assert.02123', 'rcc1',
    'lexing', 'variadic-call', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.preprocessing.static-assert.02124', 'c90',
    'preprocessing', 'file-scope', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.preprocessing.static-assert.02125', 'c99',
    'preprocessing', 'constant-expression', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.preprocessing.static-assert.02126', 'c11',
    'preprocessing', 'cross-module', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.preprocessing.static-assert.02127', 'c17',
    'preprocessing', 'block-scope', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.preprocessing.static-assert.02128', 'c23',
    'preprocessing', 'runtime-expression', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.preprocessing.static-assert.02129', 'gnu90',
    'preprocessing', 'translation-unit', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.preprocessing.static-assert.02130', 'gnu99',
    'preprocessing', 'prototype', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.preprocessing.static-assert.02131', 'gnu11',
    'preprocessing', 'variadic-call', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.preprocessing.static-assert.02132', 'gnu17',
    'preprocessing', 'file-scope', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.preprocessing.static-assert.02133', 'gnu23',
    'preprocessing', 'constant-expression', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.static-assert.02134', 'posix.1-2008',
    'preprocessing', 'cross-module', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.preprocessing.static-assert.02135', 'rcc1',
    'preprocessing', 'block-scope', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.declarations.static-assert.02136', 'c90',
    'declarations', 'runtime-expression', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'c99.declarations.static-assert.02137', 'c99',
    'declarations', 'translation-unit', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.declarations.static-assert.02138', 'c11',
    'declarations', 'prototype', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.declarations.static-assert.02139', 'c17',
    'declarations', 'variadic-call', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.declarations.static-assert.02140', 'c23',
    'declarations', 'file-scope', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.declarations.static-assert.02141', 'gnu90',
    'declarations', 'constant-expression', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.declarations.static-assert.02142', 'gnu99',
    'declarations', 'cross-module', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.declarations.static-assert.02143', 'gnu11',
    'declarations', 'block-scope', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.declarations.static-assert.02144', 'gnu17',
    'declarations', 'runtime-expression', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.declarations.static-assert.02145', 'gnu23',
    'declarations', 'translation-unit', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.static-assert.02146', 'posix.1-2008',
    'declarations', 'prototype', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.declarations.static-assert.02147', 'rcc1',
    'declarations', 'variadic-call', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.types.static-assert.02148', 'c90',
    'types', 'file-scope', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'c99.types.static-assert.02149', 'c99',
    'types', 'constant-expression', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.types.static-assert.02150', 'c11',
    'types', 'cross-module', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.types.static-assert.02151', 'c17',
    'types', 'block-scope', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.types.static-assert.02152', 'c23',
    'types', 'runtime-expression', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.types.static-assert.02153', 'gnu90',
    'types', 'translation-unit', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.types.static-assert.02154', 'gnu99',
    'types', 'prototype', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.types.static-assert.02155', 'gnu11',
    'types', 'variadic-call', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.types.static-assert.02156', 'gnu17',
    'types', 'file-scope', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.types.static-assert.02157', 'gnu23',
    'types', 'constant-expression', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.types.static-assert.02158', 'posix.1-2008',
    'types', 'cross-module', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.types.static-assert.02159', 'rcc1',
    'types', 'block-scope', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.conversions.static-assert.02160', 'c90',
    'conversions', 'runtime-expression', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'c99.conversions.static-assert.02161', 'c99',
    'conversions', 'translation-unit', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.conversions.static-assert.02162', 'c11',
    'conversions', 'prototype', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.conversions.static-assert.02163', 'c17',
    'conversions', 'variadic-call', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.conversions.static-assert.02164', 'c23',
    'conversions', 'file-scope', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.conversions.static-assert.02165', 'gnu90',
    'conversions', 'constant-expression', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.conversions.static-assert.02166', 'gnu99',
    'conversions', 'cross-module', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.conversions.static-assert.02167', 'gnu11',
    'conversions', 'block-scope', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.conversions.static-assert.02168', 'gnu17',
    'conversions', 'runtime-expression', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.conversions.static-assert.02169', 'gnu23',
    'conversions', 'translation-unit', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.static-assert.02170', 'posix.1-2008',
    'conversions', 'prototype', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.conversions.static-assert.02171', 'rcc1',
    'conversions', 'variadic-call', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.expressions.static-assert.02172', 'c90',
    'expressions', 'file-scope', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'c99.expressions.static-assert.02173', 'c99',
    'expressions', 'constant-expression', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.expressions.static-assert.02174', 'c11',
    'expressions', 'cross-module', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.expressions.static-assert.02175', 'c17',
    'expressions', 'block-scope', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.expressions.static-assert.02176', 'c23',
    'expressions', 'runtime-expression', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.expressions.static-assert.02177', 'gnu90',
    'expressions', 'translation-unit', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.expressions.static-assert.02178', 'gnu99',
    'expressions', 'prototype', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.expressions.static-assert.02179', 'gnu11',
    'expressions', 'variadic-call', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.expressions.static-assert.02180', 'gnu17',
    'expressions', 'file-scope', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.expressions.static-assert.02181', 'gnu23',
    'expressions', 'constant-expression', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.static-assert.02182', 'posix.1-2008',
    'expressions', 'cross-module', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.expressions.static-assert.02183', 'rcc1',
    'expressions', 'block-scope', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.statements.static-assert.02184', 'c90',
    'statements', 'runtime-expression', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.statements.static-assert.02185', 'c99',
    'statements', 'translation-unit', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.statements.static-assert.02186', 'c11',
    'statements', 'prototype', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.statements.static-assert.02187', 'c17',
    'statements', 'variadic-call', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.statements.static-assert.02188', 'c23',
    'statements', 'file-scope', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.statements.static-assert.02189', 'gnu90',
    'statements', 'constant-expression', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.statements.static-assert.02190', 'gnu99',
    'statements', 'cross-module', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.statements.static-assert.02191', 'gnu11',
    'statements', 'block-scope', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.statements.static-assert.02192', 'gnu17',
    'statements', 'runtime-expression', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.statements.static-assert.02193', 'gnu23',
    'statements', 'translation-unit', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.statements.static-assert.02194', 'posix.1-2008',
    'statements', 'prototype', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.statements.static-assert.02195', 'rcc1',
    'statements', 'variadic-call', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.functions.static-assert.02196', 'c90',
    'functions', 'file-scope', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'c99.functions.static-assert.02197', 'c99',
    'functions', 'constant-expression', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.functions.static-assert.02198', 'c11',
    'functions', 'cross-module', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.functions.static-assert.02199', 'c17',
    'functions', 'block-scope', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.functions.static-assert.02200', 'c23',
    'functions', 'runtime-expression', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.functions.static-assert.02201', 'gnu90',
    'functions', 'translation-unit', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.functions.static-assert.02202', 'gnu99',
    'functions', 'prototype', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.functions.static-assert.02203', 'gnu11',
    'functions', 'variadic-call', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.functions.static-assert.02204', 'gnu17',
    'functions', 'file-scope', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.functions.static-assert.02205', 'gnu23',
    'functions', 'constant-expression', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.functions.static-assert.02206', 'posix.1-2008',
    'functions', 'cross-module', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.functions.static-assert.02207', 'rcc1',
    'functions', 'block-scope', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.aggregates.static-assert.02208', 'c90',
    'aggregates', 'runtime-expression', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'c99.aggregates.static-assert.02209', 'c99',
    'aggregates', 'translation-unit', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.aggregates.static-assert.02210', 'c11',
    'aggregates', 'prototype', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.aggregates.static-assert.02211', 'c17',
    'aggregates', 'variadic-call', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.aggregates.static-assert.02212', 'c23',
    'aggregates', 'file-scope', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.aggregates.static-assert.02213', 'gnu90',
    'aggregates', 'constant-expression', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.aggregates.static-assert.02214', 'gnu99',
    'aggregates', 'cross-module', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.aggregates.static-assert.02215', 'gnu11',
    'aggregates', 'block-scope', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.aggregates.static-assert.02216', 'gnu17',
    'aggregates', 'runtime-expression', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.aggregates.static-assert.02217', 'gnu23',
    'aggregates', 'translation-unit', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.aggregates.static-assert.02218', 'posix.1-2008',
    'aggregates', 'prototype', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.aggregates.static-assert.02219', 'rcc1',
    'aggregates', 'variadic-call', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.initializers.static-assert.02220', 'c90',
    'initializers', 'file-scope', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'c99.initializers.static-assert.02221', 'c99',
    'initializers', 'constant-expression', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.initializers.static-assert.02222', 'c11',
    'initializers', 'cross-module', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.initializers.static-assert.02223', 'c17',
    'initializers', 'block-scope', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.initializers.static-assert.02224', 'c23',
    'initializers', 'runtime-expression', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.initializers.static-assert.02225', 'gnu90',
    'initializers', 'translation-unit', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.initializers.static-assert.02226', 'gnu99',
    'initializers', 'prototype', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.initializers.static-assert.02227', 'gnu11',
    'initializers', 'variadic-call', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.initializers.static-assert.02228', 'gnu17',
    'initializers', 'file-scope', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.initializers.static-assert.02229', 'gnu23',
    'initializers', 'constant-expression', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.initializers.static-assert.02230', 'posix.1-2008',
    'initializers', 'cross-module', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.initializers.static-assert.02231', 'rcc1',
    'initializers', 'block-scope', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.floating.static-assert.02232', 'c90',
    'floating', 'runtime-expression', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'c99.floating.static-assert.02233', 'c99',
    'floating', 'translation-unit', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.floating.static-assert.02234', 'c11',
    'floating', 'prototype', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.floating.static-assert.02235', 'c17',
    'floating', 'variadic-call', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.floating.static-assert.02236', 'c23',
    'floating', 'file-scope', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.floating.static-assert.02237', 'gnu90',
    'floating', 'constant-expression', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.floating.static-assert.02238', 'gnu99',
    'floating', 'cross-module', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.floating.static-assert.02239', 'gnu11',
    'floating', 'block-scope', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.floating.static-assert.02240', 'gnu17',
    'floating', 'runtime-expression', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.floating.static-assert.02241', 'gnu23',
    'floating', 'translation-unit', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.floating.static-assert.02242', 'posix.1-2008',
    'floating', 'prototype', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.floating.static-assert.02243', 'rcc1',
    'floating', 'variadic-call', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.atomics.static-assert.02244', 'c90',
    'atomics', 'file-scope', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.atomics.static-assert.02245', 'c99',
    'atomics', 'constant-expression', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.atomics.static-assert.02246', 'c11',
    'atomics', 'cross-module', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.atomics.static-assert.02247', 'c17',
    'atomics', 'block-scope', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.atomics.static-assert.02248', 'c23',
    'atomics', 'runtime-expression', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.atomics.static-assert.02249', 'gnu90',
    'atomics', 'translation-unit', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.atomics.static-assert.02250', 'gnu99',
    'atomics', 'prototype', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.atomics.static-assert.02251', 'gnu11',
    'atomics', 'variadic-call', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.atomics.static-assert.02252', 'gnu17',
    'atomics', 'file-scope', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.atomics.static-assert.02253', 'gnu23',
    'atomics', 'constant-expression', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.atomics.static-assert.02254', 'posix.1-2008',
    'atomics', 'cross-module', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.atomics.static-assert.02255', 'rcc1',
    'atomics', 'block-scope', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.variadics.static-assert.02256', 'c90',
    'variadics', 'runtime-expression', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'c99.variadics.static-assert.02257', 'c99',
    'variadics', 'translation-unit', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.variadics.static-assert.02258', 'c11',
    'variadics', 'prototype', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.variadics.static-assert.02259', 'c17',
    'variadics', 'variadic-call', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.variadics.static-assert.02260', 'c23',
    'variadics', 'file-scope', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.variadics.static-assert.02261', 'gnu90',
    'variadics', 'constant-expression', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.variadics.static-assert.02262', 'gnu99',
    'variadics', 'cross-module', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.variadics.static-assert.02263', 'gnu11',
    'variadics', 'block-scope', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.variadics.static-assert.02264', 'gnu17',
    'variadics', 'runtime-expression', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.variadics.static-assert.02265', 'gnu23',
    'variadics', 'translation-unit', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.variadics.static-assert.02266', 'posix.1-2008',
    'variadics', 'prototype', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.variadics.static-assert.02267', 'rcc1',
    'variadics', 'variadic-call', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.library.static-assert.02268', 'c90',
    'library', 'file-scope', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'c99.library.static-assert.02269', 'c99',
    'library', 'constant-expression', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.library.static-assert.02270', 'c11',
    'library', 'cross-module', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.library.static-assert.02271', 'c17',
    'library', 'block-scope', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.library.static-assert.02272', 'c23',
    'library', 'runtime-expression', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.library.static-assert.02273', 'gnu90',
    'library', 'translation-unit', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.library.static-assert.02274', 'gnu99',
    'library', 'prototype', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.library.static-assert.02275', 'gnu11',
    'library', 'variadic-call', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.library.static-assert.02276', 'gnu17',
    'library', 'file-scope', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.library.static-assert.02277', 'gnu23',
    'library', 'constant-expression', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.library.static-assert.02278', 'posix.1-2008',
    'library', 'cross-module', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.library.static-assert.02279', 'rcc1',
    'library', 'block-scope', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.abi.static-assert.02280', 'c90',
    'abi', 'runtime-expression', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'c99.abi.static-assert.02281', 'c99',
    'abi', 'translation-unit', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.abi.static-assert.02282', 'c11',
    'abi', 'prototype', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.abi.static-assert.02283', 'c17',
    'abi', 'variadic-call', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.abi.static-assert.02284', 'c23',
    'abi', 'file-scope', 'static-assert',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.abi.static-assert.02285', 'gnu90',
    'abi', 'constant-expression', 'static-assert',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.abi.static-assert.02286', 'gnu99',
    'abi', 'cross-module', 'static-assert',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.abi.static-assert.02287', 'gnu11',
    'abi', 'block-scope', 'static-assert',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.abi.static-assert.02288', 'gnu17',
    'abi', 'runtime-expression', 'static-assert',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.abi.static-assert.02289', 'gnu23',
    'abi', 'translation-unit', 'static-assert',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.abi.static-assert.02290', 'posix.1-2008',
    'abi', 'prototype', 'static-assert',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.abi.static-assert.02291', 'rcc1',
    'abi', 'variadic-call', 'static-assert',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.object-format.static-assert.02292', 'c90',
    'object-format', 'file-scope', 'static-assert',
    'execute-pass', 'required');
  AddCase(Result, 'c99.object-format.static-assert.02293', 'c99',
    'object-format', 'constant-expression', 'static-assert',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.object-format.static-assert.02294', 'c11',
    'object-format', 'cross-module', 'static-assert',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.object-format.static-assert.02295', 'c17',
    'object-format', 'block-scope', 'static-assert',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.object-format.static-assert.02296', 'c23',
    'object-format', 'runtime-expression', 'static-assert',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.object-format.static-assert.02297', 'gnu90',
    'object-format', 'translation-unit', 'static-assert',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.object-format.static-assert.02298', 'gnu99',
    'object-format', 'prototype', 'static-assert',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.object-format.static-assert.02299', 'gnu11',
    'object-format', 'variadic-call', 'static-assert',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.object-format.static-assert.02300', 'gnu17',
    'object-format', 'file-scope', 'static-assert',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.object-format.static-assert.02301', 'gnu23',
    'object-format', 'constant-expression', 'static-assert',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.object-format.static-assert.02302', 'posix.1-2008',
    'object-format', 'cross-module', 'static-assert',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.object-format.static-assert.02303', 'rcc1',
    'object-format', 'block-scope', 'static-assert',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.lexing.thread-local.02304', 'c90',
    'lexing', 'constant-expression', 'thread-local',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.lexing.thread-local.02305', 'c99',
    'lexing', 'cross-module', 'thread-local',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.lexing.thread-local.02306', 'c11',
    'lexing', 'block-scope', 'thread-local',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.lexing.thread-local.02307', 'c17',
    'lexing', 'runtime-expression', 'thread-local',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.lexing.thread-local.02308', 'c23',
    'lexing', 'translation-unit', 'thread-local',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.lexing.thread-local.02309', 'gnu90',
    'lexing', 'prototype', 'thread-local',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.lexing.thread-local.02310', 'gnu99',
    'lexing', 'variadic-call', 'thread-local',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.lexing.thread-local.02311', 'gnu11',
    'lexing', 'file-scope', 'thread-local',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.lexing.thread-local.02312', 'gnu17',
    'lexing', 'constant-expression', 'thread-local',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.lexing.thread-local.02313', 'gnu23',
    'lexing', 'cross-module', 'thread-local',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.lexing.thread-local.02314', 'posix.1-2008',
    'lexing', 'block-scope', 'thread-local',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.lexing.thread-local.02315', 'rcc1',
    'lexing', 'runtime-expression', 'thread-local',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.preprocessing.thread-local.02316', 'c90',
    'preprocessing', 'translation-unit', 'thread-local',
    'compile-fail', 'required');
  AddCase(Result, 'c99.preprocessing.thread-local.02317', 'c99',
    'preprocessing', 'prototype', 'thread-local',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.preprocessing.thread-local.02318', 'c11',
    'preprocessing', 'variadic-call', 'thread-local',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.preprocessing.thread-local.02319', 'c17',
    'preprocessing', 'file-scope', 'thread-local',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.preprocessing.thread-local.02320', 'c23',
    'preprocessing', 'constant-expression', 'thread-local',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.preprocessing.thread-local.02321', 'gnu90',
    'preprocessing', 'cross-module', 'thread-local',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.preprocessing.thread-local.02322', 'gnu99',
    'preprocessing', 'block-scope', 'thread-local',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.preprocessing.thread-local.02323', 'gnu11',
    'preprocessing', 'runtime-expression', 'thread-local',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.preprocessing.thread-local.02324', 'gnu17',
    'preprocessing', 'translation-unit', 'thread-local',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.preprocessing.thread-local.02325', 'gnu23',
    'preprocessing', 'prototype', 'thread-local',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.preprocessing.thread-local.02326', 'posix.1-2008',
    'preprocessing', 'variadic-call', 'thread-local',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.preprocessing.thread-local.02327', 'rcc1',
    'preprocessing', 'file-scope', 'thread-local',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.declarations.thread-local.02328', 'c90',
    'declarations', 'constant-expression', 'thread-local',
    'diagnostic', 'required');
  AddCase(Result, 'c99.declarations.thread-local.02329', 'c99',
    'declarations', 'cross-module', 'thread-local',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.declarations.thread-local.02330', 'c11',
    'declarations', 'block-scope', 'thread-local',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.declarations.thread-local.02331', 'c17',
    'declarations', 'runtime-expression', 'thread-local',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.declarations.thread-local.02332', 'c23',
    'declarations', 'translation-unit', 'thread-local',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.declarations.thread-local.02333', 'gnu90',
    'declarations', 'prototype', 'thread-local',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.declarations.thread-local.02334', 'gnu99',
    'declarations', 'variadic-call', 'thread-local',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.declarations.thread-local.02335', 'gnu11',
    'declarations', 'file-scope', 'thread-local',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.declarations.thread-local.02336', 'gnu17',
    'declarations', 'constant-expression', 'thread-local',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.declarations.thread-local.02337', 'gnu23',
    'declarations', 'cross-module', 'thread-local',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.declarations.thread-local.02338', 'posix.1-2008',
    'declarations', 'block-scope', 'thread-local',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.declarations.thread-local.02339', 'rcc1',
    'declarations', 'runtime-expression', 'thread-local',
    'abi-inspect', 'stress');
  AddCase(Result, 'c90.types.thread-local.02340', 'c90',
    'types', 'translation-unit', 'thread-local',
    'compile-pass', 'required');
  AddCase(Result, 'c99.types.thread-local.02341', 'c99',
    'types', 'prototype', 'thread-local',
    'compile-fail', 'extension');
  AddCase(Result, 'c11.types.thread-local.02342', 'c11',
    'types', 'variadic-call', 'thread-local',
    'execute-pass', 'quality');
  AddCase(Result, 'c17.types.thread-local.02343', 'c17',
    'types', 'file-scope', 'thread-local',
    'diagnostic', 'stress');
  AddCase(Result, 'c23.types.thread-local.02344', 'c23',
    'types', 'constant-expression', 'thread-local',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu90.types.thread-local.02345', 'gnu90',
    'types', 'cross-module', 'thread-local',
    'compile-pass', 'extension');
  AddCase(Result, 'gnu99.types.thread-local.02346', 'gnu99',
    'types', 'block-scope', 'thread-local',
    'compile-fail', 'quality');
  AddCase(Result, 'gnu11.types.thread-local.02347', 'gnu11',
    'types', 'runtime-expression', 'thread-local',
    'execute-pass', 'stress');
  AddCase(Result, 'gnu17.types.thread-local.02348', 'gnu17',
    'types', 'translation-unit', 'thread-local',
    'diagnostic', 'required');
  AddCase(Result, 'gnu23.types.thread-local.02349', 'gnu23',
    'types', 'prototype', 'thread-local',
    'abi-inspect', 'extension');
  AddCase(Result, 'posix.1-2008.types.thread-local.02350', 'posix.1-2008',
    'types', 'variadic-call', 'thread-local',
    'compile-pass', 'quality');
  AddCase(Result, 'rcc1.types.thread-local.02351', 'rcc1',
    'types', 'file-scope', 'thread-local',
    'compile-fail', 'stress');
  AddCase(Result, 'c90.conversions.thread-local.02352', 'c90',
    'conversions', 'constant-expression', 'thread-local',
    'execute-pass', 'required');
  AddCase(Result, 'c99.conversions.thread-local.02353', 'c99',
    'conversions', 'cross-module', 'thread-local',
    'diagnostic', 'extension');
  AddCase(Result, 'c11.conversions.thread-local.02354', 'c11',
    'conversions', 'block-scope', 'thread-local',
    'abi-inspect', 'quality');
  AddCase(Result, 'c17.conversions.thread-local.02355', 'c17',
    'conversions', 'runtime-expression', 'thread-local',
    'compile-pass', 'stress');
  AddCase(Result, 'c23.conversions.thread-local.02356', 'c23',
    'conversions', 'translation-unit', 'thread-local',
    'compile-fail', 'required');
  AddCase(Result, 'gnu90.conversions.thread-local.02357', 'gnu90',
    'conversions', 'prototype', 'thread-local',
    'execute-pass', 'extension');
  AddCase(Result, 'gnu99.conversions.thread-local.02358', 'gnu99',
    'conversions', 'variadic-call', 'thread-local',
    'diagnostic', 'quality');
  AddCase(Result, 'gnu11.conversions.thread-local.02359', 'gnu11',
    'conversions', 'file-scope', 'thread-local',
    'abi-inspect', 'stress');
  AddCase(Result, 'gnu17.conversions.thread-local.02360', 'gnu17',
    'conversions', 'constant-expression', 'thread-local',
    'compile-pass', 'required');
  AddCase(Result, 'gnu23.conversions.thread-local.02361', 'gnu23',
    'conversions', 'cross-module', 'thread-local',
    'compile-fail', 'extension');
  AddCase(Result, 'posix.1-2008.conversions.thread-local.02362', 'posix.1-2008',
    'conversions', 'block-scope', 'thread-local',
    'execute-pass', 'quality');
  AddCase(Result, 'rcc1.conversions.thread-local.02363', 'rcc1',
    'conversions', 'runtime-expression', 'thread-local',
    'diagnostic', 'stress');
  AddCase(Result, 'c90.expressions.thread-local.02364', 'c90',
    'expressions', 'translation-unit', 'thread-local',
    'abi-inspect', 'required');
  AddCase(Result, 'c99.expressions.thread-local.02365', 'c99',
    'expressions', 'prototype', 'thread-local',
    'compile-pass', 'extension');
  AddCase(Result, 'c11.expressions.thread-local.02366', 'c11',
    'expressions', 'variadic-call', 'thread-local',
    'compile-fail', 'quality');
  AddCase(Result, 'c17.expressions.thread-local.02367', 'c17',
    'expressions', 'file-scope', 'thread-local',
    'execute-pass', 'stress');
  AddCase(Result, 'c23.expressions.thread-local.02368', 'c23',
    'expressions', 'constant-expression', 'thread-local',
    'diagnostic', 'required');
  AddCase(Result, 'gnu90.expressions.thread-local.02369', 'gnu90',
    'expressions', 'cross-module', 'thread-local',
    'abi-inspect', 'extension');
  AddCase(Result, 'gnu99.expressions.thread-local.02370', 'gnu99',
    'expressions', 'block-scope', 'thread-local',
    'compile-pass', 'quality');
  AddCase(Result, 'gnu11.expressions.thread-local.02371', 'gnu11',
    'expressions', 'runtime-expression', 'thread-local',
    'compile-fail', 'stress');
  AddCase(Result, 'gnu17.expressions.thread-local.02372', 'gnu17',
    'expressions', 'translation-unit', 'thread-local',
    'execute-pass', 'required');
  AddCase(Result, 'gnu23.expressions.thread-local.02373', 'gnu23',
    'expressions', 'prototype', 'thread-local',
    'diagnostic', 'extension');
  AddCase(Result, 'posix.1-2008.expressions.thread-local.02374', 'posix.1-2008',
    'expressions', 'variadic-call', 'thread-local',
    'abi-inspect', 'quality');
  AddCase(Result, 'rcc1.expressions.thread-local.02375', 'rcc1',
    'expressions', 'file-scope', 'thread-local',
    'compile-pass', 'stress');
  AddCase(Result, 'c90.statements.thread-local.02376', 'c90',
    'statements', 'constant-expression', 'thread-local',
    'compile-fail', 'required');
  AddCase(Result, 'c99.statements.thread-local.02377', 'c99',
    'statements', 'cross-module', 'thread-local',
    'execute-pass', 'extension');
  AddCase(Result, 'c11.statements.thread-local.02378', 'c11',
    'statements', 'block-scope', 'thread-local',
    'diagnostic', 'quality');
  AddCase(Result, 'c17.statements.thread-local.02379', 'c17',
    'statements', 'runtime-expression', 'thread-local',
    'abi-inspect', 'stress');
  AddCase(Result, 'c23.statements.thread-local.02380', 'c23',
    'statements', 'translation-unit', 'thread-local',
    'compile-pass', 'required');
  AddCase(Result, 'gnu90.statements.thread-local.02381', 'gnu90',
    'statements', 'prototype', 'thread-local',
    'compile-fail', 'extension');
  AddCase(Result, 'gnu99.statements.thread-local.02382', 'gnu99',
    'statements', 'variadic-call', 'thread-local',
    'execute-pass', 'quality');
  AddCase(Result, 'gnu11.statements.thread-local.02383', 'gnu11',
    'statements', 'file-scope', 'thread-local',
    'diagnostic', 'stress');
  AddCase(Result, 'gnu17.statements.thread-local.02384', 'gnu17',
    'statements', 'constant-expression', 'thread-local',
    'abi-inspect', 'required');
  AddCase(Result, 'gnu23.statements.thread-local.02385', 'gnu23',
    'statements', 'cross-module', 'thread-local',
    'compile-pass', 'extension');
  AddCase(Result, 'posix.1-2008.statements.thread-local.02386', 'posix.1-2008',
    'statements', 'block-scope', 'thread-local',
    'compile-fail', 'quality');
  AddCase(Result, 'rcc1.statements.thread-local.02387', 'rcc1',
    'statements', 'runtime-expression', 'thread-local',
    'execute-pass', 'stress');
  AddCase(Result, 'c90.functions.thread-local.02388', 'c90',
    'functions', 'translation-unit', 'thread-local',
    'diagnostic', 'required');
  AddCase(Result, 'c99.functions.thread-local.02389', 'c99',
    'functions', 'prototype', 'thread-local',
    'abi-inspect', 'extension');
  AddCase(Result, 'c11.functions.thread-local.02390', 'c11',
    'functions', 'variadic-call', 'thread-local',
    'compile-pass', 'quality');
  AddCase(Result, 'c17.functions.thread-local.02391', 'c17',
    'functions', 'file-scope', 'thread-local',
    'compile-fail', 'stress');
  AddCase(Result, 'c23.functions.thread-local.02392', 'c23',
    'functions', 'constant-expression', 'thread-local',
    'execute-pass', 'required');
  AddCase(Result, 'gnu90.functions.thread-local.02393', 'gnu90',
    'functions', 'cross-module', 'thread-local',
    'diagnostic', 'extension');
  AddCase(Result, 'gnu99.functions.thread-local.02394', 'gnu99',
    'functions', 'block-scope', 'thread-local',
    'abi-inspect', 'quality');
  AddCase(Result, 'gnu11.functions.thread-local.02395', 'gnu11',
    'functions', 'runtime-expression', 'thread-local',
    'compile-pass', 'stress');
  AddCase(Result, 'gnu17.functions.thread-local.02396', 'gnu17',
    'functions', 'translation-unit', 'thread-local',
    'compile-fail', 'required');
  AddCase(Result, 'gnu23.functions.thread-local.02397', 'gnu23',
    'functions', 'prototype', 'thread-local',
    'execute-pass', 'extension');
  AddCase(Result, 'posix.1-2008.functions.thread-local.02398', 'posix.1-2008',
    'functions', 'variadic-call', 'thread-local',
    'diagnostic', 'quality');
  AddCase(Result, 'rcc1.functions.thread-local.02399', 'rcc1',
    'functions', 'file-scope', 'thread-local',
    'abi-inspect', 'stress');
end;

function ConformanceSummary(const ACatalog: TConformanceCaseArray; const AStandard: string): string;
var I, Count: LongInt;
begin
  Count := 0;
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].StandardName, AStandard) then Inc(Count);
  Result := Format('%s: policy inventory available (%d records; not certification)',
    [AStandard, Count]);
end;

function FindConformanceCase(const ACatalog: TConformanceCaseArray; const ATestID: string; out ACase: TConformanceCase): Boolean;
var I: LongInt;
begin
  for I := 0 to High(ACatalog) do if ACatalog[I].TestID = ATestID then begin ACase := ACatalog[I]; Exit(True); end;
  ACase.TestID := ''; ACase.StandardName := ''; ACase.Area := ''; ACase.Context := ''; ACase.Feature := ''; ACase.ExpectedOutcome := ''; ACase.RequirementLevel := ''; Result := False;
end;

end.
