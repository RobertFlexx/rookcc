unit rcc_aarch64_patterns;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TInstructionPattern = record
    Mnemonic: string;
    OperandForm: string;
    RequiredFeature: string;
    EstimatedLatency: LongInt;
    EstimatedSize: LongInt;
    Evidence: string;
    Status: string;
  end;
  TInstructionPatternArray = array of TInstructionPattern;

function BuildAArch64PatternCatalog: TInstructionPatternArray;
function FindAArch64Pattern(const ACatalog: TInstructionPatternArray;
  const AMnemonic, AForm: string; out APattern: TInstructionPattern): Boolean;
function AArch64PatternSummary(const ACatalog: TInstructionPatternArray): string;

implementation

procedure AddPattern(var APatterns: TInstructionPatternArray;
  const AMnemonic, AForm, AFeature: string; ALatency, ASize: LongInt;
  const AEvidence, AStatus: string);
var
  N: LongInt;
begin
  N := Length(APatterns);
  SetLength(APatterns, N + 1);
  APatterns[N].Mnemonic := AMnemonic;
  APatterns[N].OperandForm := AForm;
  APatterns[N].RequiredFeature := AFeature;
  APatterns[N].EstimatedLatency := ALatency;
  APatterns[N].EstimatedSize := ASize;
  APatterns[N].Evidence := AEvidence;
  APatterns[N].Status := AStatus;
end;

function BuildAArch64PatternCatalog: TInstructionPatternArray;
begin
  Result := nil;
  AddPattern(Result, 'add', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'sub', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'mul', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'sdiv', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'udiv', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'and', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'orr', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'eor', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'lslv', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'lsrv', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'asrv', 'x,x,x', 'base', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'ldr', 'x,[x,imm]', 'base', 0, 4, 'rcc_cross_codegen:load paths', 'emitted');
  AddPattern(Result, 'str', 'x,[x,imm]', 'base', 0, 4, 'rcc_cross_codegen:store paths', 'emitted');
  AddPattern(Result, 'fadd', 's,s,s', 'fp', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'fadd', 'd,d,d', 'fp', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'fsub', 'd,d,d', 'fp', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'fmul', 'd,d,d', 'fp', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'fdiv', 'd,d,d', 'fp', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'b', 'label', 'base', 0, 4, 'rcc_cross_codegen:EmitJump', 'emitted');
  AddPattern(Result, 'b.cond', 'label', 'base', 0, 4, 'rcc_cross_codegen:conditional fixups', 'emitted');
  AddPattern(Result, 'bl', 'label', 'base', 0, 4, 'rcc_cross_codegen:call fixups', 'emitted');
  AddPattern(Result, 'ret', '', 'base', 0, 4, 'rcc_cross_codegen:function epilogue', 'emitted');
  AddPattern(Result, 'svc', '#0', 'base', 0, 4, 'rcc_cross_codegen:direct syscall path', 'emitted');
end;

function FindAArch64Pattern(const ACatalog: TInstructionPatternArray;
  const AMnemonic, AForm: string; out APattern: TInstructionPattern): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Mnemonic, AMnemonic) and
       SameText(ACatalog[I].OperandForm, AForm) then
    begin
      APattern := ACatalog[I];
      Exit(True);
    end;
  APattern := Default(TInstructionPattern);
  Result := False;
end;

function AArch64PatternSummary(const ACatalog: TInstructionPatternArray): string;
var
  I, Verified: LongInt;
begin
  Verified := 0;
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Status, 'emitted') then Inc(Verified);
  Result := Format('AArch64: %d backend-backed instruction forms (%d emitted)',
    [Length(ACatalog), Verified]);
end;

end.
