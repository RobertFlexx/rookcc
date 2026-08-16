unit rcc_x64_patterns;

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

function BuildX64PatternCatalog: TInstructionPatternArray;
function FindX64Pattern(const ACatalog: TInstructionPatternArray;
  const AMnemonic, AForm: string; out APattern: TInstructionPattern): Boolean;
function X64PatternSummary(const ACatalog: TInstructionPatternArray): string;

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

function BuildX64PatternCatalog: TInstructionPatternArray;
begin
  Result := nil;
  AddPattern(Result, 'mov', 'r64,imm64', 'x86-64', 0, 0, 'rcc_backend:EmitMovRaxImm', 'emitted');
  AddPattern(Result, 'mov', 'r64,[mem]', 'x86-64', 0, 0, 'rcc_backend:EmitLoadMemoryTyped', 'emitted');
  AddPattern(Result, 'mov', '[mem],r64', 'x86-64', 0, 0, 'rcc_backend:EmitStoreMemoryTyped', 'emitted');
  AddPattern(Result, 'lea', 'r64,[mem]', 'x86-64', 0, 0, 'rcc_backend:EmitAddressLocal', 'emitted');
  AddPattern(Result, 'push', 'r64', 'x86-64', 0, 1, 'rcc_backend:EmitPushRax', 'emitted');
  AddPattern(Result, 'pop', 'r64', 'x86-64', 0, 1, 'rcc_backend:EmitPopRcx', 'emitted');
  AddPattern(Result, 'add', 'r64,r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'sub', 'r64,r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'imul', 'r64,r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'idiv', 'r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'div', 'r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'and', 'r64,r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'or', 'r64,r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'xor', 'r64,r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'shl', 'r64,cl', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'shr', 'r64,cl', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'sar', 'r64,cl', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'cmp', 'r64,r64', 'x86-64', 0, 0, 'rcc_backend:EmitBinaryOperation', 'emitted');
  AddPattern(Result, 'setcc', 'r8', 'x86-64', 0, 3, 'rcc_backend:EmitSetCC', 'emitted');
  AddPattern(Result, 'call', 'rel32', 'x86-64', 0, 5, 'rcc_backend:EmitCall', 'emitted');
  AddPattern(Result, 'call', 'r64', 'x86-64', 0, 0, 'rcc_backend:EmitIndirectCall', 'emitted');
  AddPattern(Result, 'jmp', 'rel32', 'x86-64', 0, 5, 'rcc_backend:label fixups', 'emitted');
  AddPattern(Result, 'jcc', 'rel32', 'x86-64', 0, 6, 'rcc_backend:EmitJcc', 'emitted');
  AddPattern(Result, 'ret', '', 'x86-64', 0, 1, 'rcc_backend:function epilogue', 'emitted');
  AddPattern(Result, 'syscall', '', 'x86-64', 0, 2, 'rcc_backend:EmitDirectSyscall', 'emitted');
  AddPattern(Result, 'movss', 'xmm,[mem]', 'sse', 0, 0, 'rcc_backend:f32 load/store paths', 'emitted');
  AddPattern(Result, 'movsd', 'xmm,[mem]', 'sse2', 0, 0, 'rcc_backend:f64 load/store paths', 'emitted');
  AddPattern(Result, 'addss', 'xmm,xmm', 'sse', 0, 0, 'rcc_backend:f32 arithmetic', 'emitted');
  AddPattern(Result, 'addsd', 'xmm,xmm', 'sse2', 0, 0, 'rcc_backend:f64 arithmetic', 'emitted');
  AddPattern(Result, 'mulss', 'xmm,xmm', 'sse', 0, 0, 'rcc_backend:f32 arithmetic', 'emitted');
  AddPattern(Result, 'mulsd', 'xmm,xmm', 'sse2', 0, 0, 'rcc_backend:f64 arithmetic', 'emitted');
  AddPattern(Result, 'divss', 'xmm,xmm', 'sse', 0, 0, 'rcc_backend:f32 arithmetic', 'emitted');
  AddPattern(Result, 'divsd', 'xmm,xmm', 'sse2', 0, 0, 'rcc_backend:f64 arithmetic', 'emitted');
end;

function FindX64Pattern(const ACatalog: TInstructionPatternArray;
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

function X64PatternSummary(const ACatalog: TInstructionPatternArray): string;
var
  I, Verified: LongInt;
begin
  Verified := 0;
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Status, 'emitted') then Inc(Verified);
  Result := Format('X64: %d backend-backed instruction forms (%d emitted)',
    [Length(ACatalog), Verified]);
end;

end.
