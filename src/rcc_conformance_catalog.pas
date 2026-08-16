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
    Status: string;
    Evidence: string;
    Notes: string;
  end;
  TConformanceCaseArray = array of TConformanceCase;

function BuildConformanceCatalog: TConformanceCaseArray;
function ConformanceSummary(const ACatalog: TConformanceCaseArray;
  const AStandard: string): string;
function ConformanceCatalogSummary(const ACatalog: TConformanceCaseArray): string;
function FindConformanceCase(const ACatalog: TConformanceCaseArray;
  const ATestID: string; out ACase: TConformanceCase): Boolean;

implementation

procedure AddCase(var AValues: TConformanceCaseArray;
  const ATestID, AStandard, AArea, AContext, AFeature, AOutcome,
  ARequirement, AStatus, AEvidence, ANotes: string);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N].TestID := ATestID;
  AValues[N].StandardName := AStandard;
  AValues[N].Area := AArea;
  AValues[N].Context := AContext;
  AValues[N].Feature := AFeature;
  AValues[N].ExpectedOutcome := AOutcome;
  AValues[N].RequirementLevel := ARequirement;
  AValues[N].Status := AStatus;
  AValues[N].Evidence := AEvidence;
  AValues[N].Notes := ANotes;
end;

function BuildConformanceCatalog: TConformanceCaseArray;
begin
  Result := nil;

  AddCase(Result, 'c90.array-decay', 'c90', 'conversions',
    'runtime-expression', 'array-decay', 'execute-pass', 'required',
    'tested', 'tests/semantic_conversions.py:pointer',
    'array objects decay to pointers in ordinary expressions');

  AddCase(Result, 'c90.bitfield-layout', 'c90', 'abi',
    'runtime-expression', 'bitfield-layout', 'execute-pass', 'required',
    'tested', 'tests/c_differential.py:bitfields',
    'layout load store and sizeof are compared with the host compiler');

  AddCase(Result, 'c99.compound-literal', 'c99', 'initializers',
    'runtime-expression', 'compound-literal', 'compile-pass', 'required',
    'implemented', 'src/rcc_sema.pas;src/rcc_backend.pas;src/rcc_cross_codegen.pas',
    'frontend and native backends contain explicit compound literal handling');

  AddCase(Result, 'c99.designated-initializer', 'c99', 'initializers',
    'block-scope', 'designated-initializer', 'compile-pass', 'required',
    'tested', 'tests/standard_modes.py:c99-designator',
    'c99 mode test checks member designators and standard gating');

  AddCase(Result, 'c90.function-designator', 'c90', 'conversions',
    'runtime-expression', 'function-designator', 'execute-pass', 'required',
    'tested', 'tests/c_differential.py:function-pointer',
    'function designators are exercised through function pointer initialization');

  AddCase(Result, 'c11.generic-selection', 'c11', 'expressions',
    'translation-unit', 'generic-selection', 'compile-pass', 'required',
    'implemented', 'src/rcc_frontend.pas;src/rcc_sema.pas',
    'parser gates _Generic to c11 and sema validates associations');

  AddCase(Result, 'c90.integer-rank', 'c90', 'conversions',
    'runtime-expression', 'integer-rank', 'execute-pass', 'required',
    'tested', 'tests/semantic_conversions.py:promotions',
    'integer promotions and mixed signedness are differential tested');

  AddCase(Result, 'c90.pointer-qualification', 'c90', 'types',
    'translation-unit', 'pointer-qualification', 'compile-pass', 'required',
    'implemented', 'src/rcc_conversions.pas;src/rcc_sema.pas',
    'qualification and nested pointer diagnostics have dedicated conversion paths');

  AddCase(Result, 'c11.static-assert', 'c11', 'declarations',
    'translation-unit', 'static-assert', 'compile-pass', 'required',
    'tested', 'tests/standard_modes.py:c11-static-assert',
    'c99 rejection and c11 acceptance are both checked');

  AddCase(Result, 'c90.struct-layout', 'c90', 'abi',
    'cross-module', 'struct-layout', 'execute-pass', 'required',
    'tested', 'tests/cross_abi_interop.py;tests/c_differential.py:aggregate',
    'aggregate layout and calling convention behavior are exercised across objects');

  AddCase(Result, 'c11.thread-local', 'c11', 'declarations',
    'file-scope', 'thread-local', 'compile-pass', 'required',
    'partial', 'src/rcc_object_model.pas;src/rcc_macho.pas',
    'object model has tls sections but the language frontend is not yet complete');

  AddCase(Result, 'c90.union-layout', 'c90', 'abi',
    'runtime-expression', 'union-layout', 'execute-pass', 'required',
    'tested', 'tests/cross_execution.py:union',
    'cross execution suite exercises shared union storage');

  AddCase(Result, 'c90.usual-arithmetic-conversions', 'c90', 'conversions',
    'runtime-expression', 'usual-arithmetic-conversions', 'execute-pass',
    'required', 'tested', 'tests/semantic_conversions.py:usual-arithmetic',
    'mixed signed and unsigned arithmetic is compared with the host compiler');
end;

procedure CountStatus(const ACatalog: TConformanceCaseArray;
  const AStandard: string; out ATotal, ATested, AImplemented, APartial: LongInt);
var
  I: LongInt;
begin
  ATotal := 0;
  ATested := 0;
  AImplemented := 0;
  APartial := 0;
  for I := 0 to High(ACatalog) do
    if (AStandard = '') or SameText(ACatalog[I].StandardName, AStandard) then
    begin
      Inc(ATotal);
      if SameText(ACatalog[I].Status, 'tested') then Inc(ATested)
      else if SameText(ACatalog[I].Status, 'implemented') then Inc(AImplemented)
      else if SameText(ACatalog[I].Status, 'partial') then Inc(APartial);
    end;
end;

function ConformanceSummary(const ACatalog: TConformanceCaseArray;
  const AStandard: string): string;
var
  Total, Tested, Implemented, Partial: LongInt;
begin
  CountStatus(ACatalog, AStandard, Total, Tested, Implemented, Partial);
  Result := Format('%s: %d tracked features (%d tested, %d implemented, %d partial)',
    [AStandard, Total, Tested, Implemented, Partial]);
end;

function ConformanceCatalogSummary(const ACatalog: TConformanceCaseArray): string;
var
  Total, Tested, Implemented, Partial: LongInt;
begin
  CountStatus(ACatalog, '', Total, Tested, Implemented, Partial);
  Result := Format('conformance: %d evidence-backed features (%d tested, %d implemented, %d partial)',
    [Total, Tested, Implemented, Partial]);
end;

function FindConformanceCase(const ACatalog: TConformanceCaseArray;
  const ATestID: string; out ACase: TConformanceCase): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].TestID, ATestID) then
    begin
      ACase := ACatalog[I];
      Exit(True);
    end;
  ACase := Default(TConformanceCase);
  Result := False;
end;

end.
