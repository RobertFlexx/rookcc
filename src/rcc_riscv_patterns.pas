unit rcc_riscv_patterns;

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

function BuildRISCV64PatternCatalog: TInstructionPatternArray;
function FindRISCV64Pattern(const ACatalog: TInstructionPatternArray;
  const AMnemonic, AForm: string; out APattern: TInstructionPattern): Boolean;
function RISCV64PatternSummary(const ACatalog: TInstructionPatternArray): string;

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

function BuildRISCV64PatternCatalog: TInstructionPatternArray;
begin
  Result := nil;
  AddPattern(Result, 'add', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'sub', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'mul', 'x,x,x', 'm', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'div', 'x,x,x', 'm', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'divu', 'x,x,x', 'm', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'rem', 'x,x,x', 'm', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'remu', 'x,x,x', 'm', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'sll', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'srl', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'sra', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'and', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'or', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'xor', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer binary operation', 'emitted');
  AddPattern(Result, 'slt', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer comparison', 'emitted');
  AddPattern(Result, 'sltu', 'x,x,x', 'i', 0, 4, 'rcc_cross_codegen:integer comparison', 'emitted');
  AddPattern(Result, 'addi', 'x,x,imm12', 'i', 0, 4, 'rcc_cross_codegen:EncodeRISCVI', 'emitted');
  AddPattern(Result, 'ld', 'x,offset(x)', 'i', 0, 4, 'rcc_cross_codegen:integer load path', 'emitted');
  AddPattern(Result, 'sd', 'x,offset(x)', 'i', 0, 4, 'rcc_cross_codegen:integer store path', 'emitted');
  AddPattern(Result, 'flw', 'f,offset(x)', 'f', 0, 4, 'rcc_cross_codegen:float load path', 'emitted');
  AddPattern(Result, 'fld', 'f,offset(x)', 'd', 0, 4, 'rcc_cross_codegen:double load path', 'emitted');
  AddPattern(Result, 'fsw', 'f,offset(x)', 'f', 0, 4, 'rcc_cross_codegen:float store path', 'emitted');
  AddPattern(Result, 'fsd', 'f,offset(x)', 'd', 0, 4, 'rcc_cross_codegen:double store path', 'emitted');
  AddPattern(Result, 'fadd.s', 'f,f,f', 'f', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'fadd.d', 'f,f,f', 'd', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'fsub.d', 'f,f,f', 'd', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'fmul.d', 'f,f,f', 'd', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'fdiv.d', 'f,f,f', 'd', 0, 4, 'rcc_cross_codegen:floating binary operation', 'emitted');
  AddPattern(Result, 'jal', 'x,label', 'i', 0, 4, 'rcc_cross_codegen:EmitJump/EmitCall', 'emitted');
  AddPattern(Result, 'jalr', 'x,x,imm12', 'i', 0, 4, 'rcc_cross_codegen:indirect call and return paths', 'emitted');
  AddPattern(Result, 'beq', 'x,x,label', 'i', 0, 4, 'rcc_cross_codegen:conditional fixups', 'emitted');
  AddPattern(Result, 'bne', 'x,x,label', 'i', 0, 4, 'rcc_cross_codegen:conditional fixups', 'emitted');
  AddPattern(Result, 'ecall', '', 'i', 0, 4, 'rcc_cross_codegen:direct syscall path', 'emitted');
end;

function FindRISCV64Pattern(const ACatalog: TInstructionPatternArray;
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

function RISCV64PatternSummary(const ACatalog: TInstructionPatternArray): string;
var
  I, Verified: LongInt;
begin
  Verified := 0;
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Status, 'emitted') then Inc(Verified);
  Result := Format('RISCV64: %d backend-backed instruction forms (%d emitted)',
    [Length(ACatalog), Verified]);
end;

end.
