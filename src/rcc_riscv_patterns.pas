unit rcc_riscv_patterns;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types;

type
  TInstructionPattern = record
    Mnemonic: string;
    OperandForm: string;
    RequiredFeature: string;
    EstimatedLatency: LongInt;
    EstimatedSize: LongInt;
  end;
  TInstructionPatternArray = array of TInstructionPattern;

function BuildRISCV64PatternCatalog: TInstructionPatternArray;
function FindRISCV64Pattern(const ACatalog: TInstructionPatternArray;
  const AMnemonic, AForm: string; out APattern: TInstructionPattern): Boolean;
function RISCV64PatternSummary(const ACatalog: TInstructionPatternArray): string;

implementation

procedure AddPattern(var APatterns: TInstructionPatternArray;
  const AMnemonic, AForm, AFeature: string; ALatency, ASize: LongInt);
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
end;

function BuildRISCV64PatternCatalog: TInstructionPatternArray;
begin
  Result := nil;
  AddPattern(Result,
    'add', 'x,x,x',
    'i', 1, 2);
  AddPattern(Result,
    'add', 'x,x,imm12',
    'm', 2, 3);
  AddPattern(Result,
    'add', 'x,offset(x)',
    'a', 3, 4);
  AddPattern(Result,
    'add', 'offset(x),x',
    'f', 4, 5);
  AddPattern(Result,
    'add', 'label',
    'd', 5, 6);
  AddPattern(Result,
    'add', 'x,label',
    'c', 6, 7);
  AddPattern(Result,
    'add', 'f,f,f',
    'v', 7, 2);
  AddPattern(Result,
    'add', 'f,offset(x)',
    'zbb', 1, 3);
  AddPattern(Result,
    'add', 'offset(x),f',
    'zba', 2, 4);
  AddPattern(Result,
    'add', 'vec,vec,vec',
    'i', 3, 5);
  AddPattern(Result,
    'add', 'vec,offset(x)',
    'm', 4, 6);
  AddPattern(Result,
    'add', 'offset(x),vec',
    'a', 5, 7);
  AddPattern(Result,
    'addi', 'x,x,x',
    'f', 6, 2);
  AddPattern(Result,
    'addi', 'x,x,imm12',
    'd', 7, 3);
  AddPattern(Result,
    'addi', 'x,offset(x)',
    'c', 1, 4);
  AddPattern(Result,
    'addi', 'offset(x),x',
    'v', 2, 5);
  AddPattern(Result,
    'addi', 'label',
    'zbb', 3, 6);
  AddPattern(Result,
    'addi', 'x,label',
    'zba', 4, 7);
  AddPattern(Result,
    'addi', 'f,f,f',
    'i', 5, 2);
  AddPattern(Result,
    'addi', 'f,offset(x)',
    'm', 6, 3);
  AddPattern(Result,
    'addi', 'offset(x),f',
    'a', 7, 4);
  AddPattern(Result,
    'addi', 'vec,vec,vec',
    'f', 1, 5);
  AddPattern(Result,
    'addi', 'vec,offset(x)',
    'd', 2, 6);
  AddPattern(Result,
    'addi', 'offset(x),vec',
    'c', 3, 7);
  AddPattern(Result,
    'sub', 'x,x,x',
    'v', 4, 2);
  AddPattern(Result,
    'sub', 'x,x,imm12',
    'zbb', 5, 3);
  AddPattern(Result,
    'sub', 'x,offset(x)',
    'zba', 6, 4);
  AddPattern(Result,
    'sub', 'offset(x),x',
    'i', 7, 5);
  AddPattern(Result,
    'sub', 'label',
    'm', 1, 6);
  AddPattern(Result,
    'sub', 'x,label',
    'a', 2, 7);
  AddPattern(Result,
    'sub', 'f,f,f',
    'f', 3, 2);
  AddPattern(Result,
    'sub', 'f,offset(x)',
    'd', 4, 3);
  AddPattern(Result,
    'sub', 'offset(x),f',
    'c', 5, 4);
  AddPattern(Result,
    'sub', 'vec,vec,vec',
    'v', 6, 5);
  AddPattern(Result,
    'sub', 'vec,offset(x)',
    'zbb', 7, 6);
  AddPattern(Result,
    'sub', 'offset(x),vec',
    'zba', 1, 7);
  AddPattern(Result,
    'mul', 'x,x,x',
    'i', 2, 2);
  AddPattern(Result,
    'mul', 'x,x,imm12',
    'm', 3, 3);
  AddPattern(Result,
    'mul', 'x,offset(x)',
    'a', 4, 4);
  AddPattern(Result,
    'mul', 'offset(x),x',
    'f', 5, 5);
  AddPattern(Result,
    'mul', 'label',
    'd', 6, 6);
  AddPattern(Result,
    'mul', 'x,label',
    'c', 7, 7);
  AddPattern(Result,
    'mul', 'f,f,f',
    'v', 1, 2);
  AddPattern(Result,
    'mul', 'f,offset(x)',
    'zbb', 2, 3);
  AddPattern(Result,
    'mul', 'offset(x),f',
    'zba', 3, 4);
  AddPattern(Result,
    'mul', 'vec,vec,vec',
    'i', 4, 5);
  AddPattern(Result,
    'mul', 'vec,offset(x)',
    'm', 5, 6);
  AddPattern(Result,
    'mul', 'offset(x),vec',
    'a', 6, 7);
  AddPattern(Result,
    'mulh', 'x,x,x',
    'f', 7, 2);
  AddPattern(Result,
    'mulh', 'x,x,imm12',
    'd', 1, 3);
  AddPattern(Result,
    'mulh', 'x,offset(x)',
    'c', 2, 4);
  AddPattern(Result,
    'mulh', 'offset(x),x',
    'v', 3, 5);
  AddPattern(Result,
    'mulh', 'label',
    'zbb', 4, 6);
  AddPattern(Result,
    'mulh', 'x,label',
    'zba', 5, 7);
  AddPattern(Result,
    'mulh', 'f,f,f',
    'i', 6, 2);
  AddPattern(Result,
    'mulh', 'f,offset(x)',
    'm', 7, 3);
  AddPattern(Result,
    'mulh', 'offset(x),f',
    'a', 1, 4);
  AddPattern(Result,
    'mulh', 'vec,vec,vec',
    'f', 2, 5);
  AddPattern(Result,
    'mulh', 'vec,offset(x)',
    'd', 3, 6);
  AddPattern(Result,
    'mulh', 'offset(x),vec',
    'c', 4, 7);
  AddPattern(Result,
    'mulhu', 'x,x,x',
    'v', 5, 2);
  AddPattern(Result,
    'mulhu', 'x,x,imm12',
    'zbb', 6, 3);
  AddPattern(Result,
    'mulhu', 'x,offset(x)',
    'zba', 7, 4);
  AddPattern(Result,
    'mulhu', 'offset(x),x',
    'i', 1, 5);
  AddPattern(Result,
    'mulhu', 'label',
    'm', 2, 6);
  AddPattern(Result,
    'mulhu', 'x,label',
    'a', 3, 7);
  AddPattern(Result,
    'mulhu', 'f,f,f',
    'f', 4, 2);
  AddPattern(Result,
    'mulhu', 'f,offset(x)',
    'd', 5, 3);
  AddPattern(Result,
    'mulhu', 'offset(x),f',
    'c', 6, 4);
  AddPattern(Result,
    'mulhu', 'vec,vec,vec',
    'v', 7, 5);
  AddPattern(Result,
    'mulhu', 'vec,offset(x)',
    'zbb', 1, 6);
  AddPattern(Result,
    'mulhu', 'offset(x),vec',
    'zba', 2, 7);
  AddPattern(Result,
    'div', 'x,x,x',
    'i', 3, 2);
  AddPattern(Result,
    'div', 'x,x,imm12',
    'm', 4, 3);
  AddPattern(Result,
    'div', 'x,offset(x)',
    'a', 5, 4);
  AddPattern(Result,
    'div', 'offset(x),x',
    'f', 6, 5);
  AddPattern(Result,
    'div', 'label',
    'd', 7, 6);
  AddPattern(Result,
    'div', 'x,label',
    'c', 1, 7);
  AddPattern(Result,
    'div', 'f,f,f',
    'v', 2, 2);
  AddPattern(Result,
    'div', 'f,offset(x)',
    'zbb', 3, 3);
  AddPattern(Result,
    'div', 'offset(x),f',
    'zba', 4, 4);
  AddPattern(Result,
    'div', 'vec,vec,vec',
    'i', 5, 5);
  AddPattern(Result,
    'div', 'vec,offset(x)',
    'm', 6, 6);
  AddPattern(Result,
    'div', 'offset(x),vec',
    'a', 7, 7);
  AddPattern(Result,
    'divu', 'x,x,x',
    'f', 1, 2);
  AddPattern(Result,
    'divu', 'x,x,imm12',
    'd', 2, 3);
  AddPattern(Result,
    'divu', 'x,offset(x)',
    'c', 3, 4);
  AddPattern(Result,
    'divu', 'offset(x),x',
    'v', 4, 5);
  AddPattern(Result,
    'divu', 'label',
    'zbb', 5, 6);
  AddPattern(Result,
    'divu', 'x,label',
    'zba', 6, 7);
  AddPattern(Result,
    'divu', 'f,f,f',
    'i', 7, 2);
  AddPattern(Result,
    'divu', 'f,offset(x)',
    'm', 1, 3);
  AddPattern(Result,
    'divu', 'offset(x),f',
    'a', 2, 4);
  AddPattern(Result,
    'divu', 'vec,vec,vec',
    'f', 3, 5);
  AddPattern(Result,
    'divu', 'vec,offset(x)',
    'd', 4, 6);
  AddPattern(Result,
    'divu', 'offset(x),vec',
    'c', 5, 7);
  AddPattern(Result,
    'rem', 'x,x,x',
    'v', 6, 2);
  AddPattern(Result,
    'rem', 'x,x,imm12',
    'zbb', 7, 3);
  AddPattern(Result,
    'rem', 'x,offset(x)',
    'zba', 1, 4);
  AddPattern(Result,
    'rem', 'offset(x),x',
    'i', 2, 5);
  AddPattern(Result,
    'rem', 'label',
    'm', 3, 6);
  AddPattern(Result,
    'rem', 'x,label',
    'a', 4, 7);
  AddPattern(Result,
    'rem', 'f,f,f',
    'f', 5, 2);
  AddPattern(Result,
    'rem', 'f,offset(x)',
    'd', 6, 3);
  AddPattern(Result,
    'rem', 'offset(x),f',
    'c', 7, 4);
  AddPattern(Result,
    'rem', 'vec,vec,vec',
    'v', 1, 5);
  AddPattern(Result,
    'rem', 'vec,offset(x)',
    'zbb', 2, 6);
  AddPattern(Result,
    'rem', 'offset(x),vec',
    'zba', 3, 7);
  AddPattern(Result,
    'remu', 'x,x,x',
    'i', 4, 2);
  AddPattern(Result,
    'remu', 'x,x,imm12',
    'm', 5, 3);
  AddPattern(Result,
    'remu', 'x,offset(x)',
    'a', 6, 4);
  AddPattern(Result,
    'remu', 'offset(x),x',
    'f', 7, 5);
  AddPattern(Result,
    'remu', 'label',
    'd', 1, 6);
  AddPattern(Result,
    'remu', 'x,label',
    'c', 2, 7);
  AddPattern(Result,
    'remu', 'f,f,f',
    'v', 3, 2);
  AddPattern(Result,
    'remu', 'f,offset(x)',
    'zbb', 4, 3);
  AddPattern(Result,
    'remu', 'offset(x),f',
    'zba', 5, 4);
  AddPattern(Result,
    'remu', 'vec,vec,vec',
    'i', 6, 5);
  AddPattern(Result,
    'remu', 'vec,offset(x)',
    'm', 7, 6);
  AddPattern(Result,
    'remu', 'offset(x),vec',
    'a', 1, 7);
  AddPattern(Result,
    'and', 'x,x,x',
    'f', 2, 2);
  AddPattern(Result,
    'and', 'x,x,imm12',
    'd', 3, 3);
  AddPattern(Result,
    'and', 'x,offset(x)',
    'c', 4, 4);
  AddPattern(Result,
    'and', 'offset(x),x',
    'v', 5, 5);
  AddPattern(Result,
    'and', 'label',
    'zbb', 6, 6);
  AddPattern(Result,
    'and', 'x,label',
    'zba', 7, 7);
  AddPattern(Result,
    'and', 'f,f,f',
    'i', 1, 2);
  AddPattern(Result,
    'and', 'f,offset(x)',
    'm', 2, 3);
  AddPattern(Result,
    'and', 'offset(x),f',
    'a', 3, 4);
  AddPattern(Result,
    'and', 'vec,vec,vec',
    'f', 4, 5);
  AddPattern(Result,
    'and', 'vec,offset(x)',
    'd', 5, 6);
  AddPattern(Result,
    'and', 'offset(x),vec',
    'c', 6, 7);
  AddPattern(Result,
    'andi', 'x,x,x',
    'v', 7, 2);
  AddPattern(Result,
    'andi', 'x,x,imm12',
    'zbb', 1, 3);
  AddPattern(Result,
    'andi', 'x,offset(x)',
    'zba', 2, 4);
  AddPattern(Result,
    'andi', 'offset(x),x',
    'i', 3, 5);
  AddPattern(Result,
    'andi', 'label',
    'm', 4, 6);
  AddPattern(Result,
    'andi', 'x,label',
    'a', 5, 7);
  AddPattern(Result,
    'andi', 'f,f,f',
    'f', 6, 2);
  AddPattern(Result,
    'andi', 'f,offset(x)',
    'd', 7, 3);
  AddPattern(Result,
    'andi', 'offset(x),f',
    'c', 1, 4);
  AddPattern(Result,
    'andi', 'vec,vec,vec',
    'v', 2, 5);
  AddPattern(Result,
    'andi', 'vec,offset(x)',
    'zbb', 3, 6);
  AddPattern(Result,
    'andi', 'offset(x),vec',
    'zba', 4, 7);
  AddPattern(Result,
    'or', 'x,x,x',
    'i', 5, 2);
  AddPattern(Result,
    'or', 'x,x,imm12',
    'm', 6, 3);
  AddPattern(Result,
    'or', 'x,offset(x)',
    'a', 7, 4);
  AddPattern(Result,
    'or', 'offset(x),x',
    'f', 1, 5);
  AddPattern(Result,
    'or', 'label',
    'd', 2, 6);
  AddPattern(Result,
    'or', 'x,label',
    'c', 3, 7);
  AddPattern(Result,
    'or', 'f,f,f',
    'v', 4, 2);
  AddPattern(Result,
    'or', 'f,offset(x)',
    'zbb', 5, 3);
  AddPattern(Result,
    'or', 'offset(x),f',
    'zba', 6, 4);
  AddPattern(Result,
    'or', 'vec,vec,vec',
    'i', 7, 5);
  AddPattern(Result,
    'or', 'vec,offset(x)',
    'm', 1, 6);
  AddPattern(Result,
    'or', 'offset(x),vec',
    'a', 2, 7);
  AddPattern(Result,
    'ori', 'x,x,x',
    'f', 3, 2);
  AddPattern(Result,
    'ori', 'x,x,imm12',
    'd', 4, 3);
  AddPattern(Result,
    'ori', 'x,offset(x)',
    'c', 5, 4);
  AddPattern(Result,
    'ori', 'offset(x),x',
    'v', 6, 5);
  AddPattern(Result,
    'ori', 'label',
    'zbb', 7, 6);
  AddPattern(Result,
    'ori', 'x,label',
    'zba', 1, 7);
  AddPattern(Result,
    'ori', 'f,f,f',
    'i', 2, 2);
  AddPattern(Result,
    'ori', 'f,offset(x)',
    'm', 3, 3);
  AddPattern(Result,
    'ori', 'offset(x),f',
    'a', 4, 4);
  AddPattern(Result,
    'ori', 'vec,vec,vec',
    'f', 5, 5);
  AddPattern(Result,
    'ori', 'vec,offset(x)',
    'd', 6, 6);
  AddPattern(Result,
    'ori', 'offset(x),vec',
    'c', 7, 7);
  AddPattern(Result,
    'xor', 'x,x,x',
    'v', 1, 2);
  AddPattern(Result,
    'xor', 'x,x,imm12',
    'zbb', 2, 3);
  AddPattern(Result,
    'xor', 'x,offset(x)',
    'zba', 3, 4);
  AddPattern(Result,
    'xor', 'offset(x),x',
    'i', 4, 5);
  AddPattern(Result,
    'xor', 'label',
    'm', 5, 6);
  AddPattern(Result,
    'xor', 'x,label',
    'a', 6, 7);
  AddPattern(Result,
    'xor', 'f,f,f',
    'f', 7, 2);
  AddPattern(Result,
    'xor', 'f,offset(x)',
    'd', 1, 3);
  AddPattern(Result,
    'xor', 'offset(x),f',
    'c', 2, 4);
  AddPattern(Result,
    'xor', 'vec,vec,vec',
    'v', 3, 5);
  AddPattern(Result,
    'xor', 'vec,offset(x)',
    'zbb', 4, 6);
  AddPattern(Result,
    'xor', 'offset(x),vec',
    'zba', 5, 7);
  AddPattern(Result,
    'xori', 'x,x,x',
    'i', 6, 2);
  AddPattern(Result,
    'xori', 'x,x,imm12',
    'm', 7, 3);
  AddPattern(Result,
    'xori', 'x,offset(x)',
    'a', 1, 4);
  AddPattern(Result,
    'xori', 'offset(x),x',
    'f', 2, 5);
  AddPattern(Result,
    'xori', 'label',
    'd', 3, 6);
  AddPattern(Result,
    'xori', 'x,label',
    'c', 4, 7);
  AddPattern(Result,
    'xori', 'f,f,f',
    'v', 5, 2);
  AddPattern(Result,
    'xori', 'f,offset(x)',
    'zbb', 6, 3);
  AddPattern(Result,
    'xori', 'offset(x),f',
    'zba', 7, 4);
  AddPattern(Result,
    'xori', 'vec,vec,vec',
    'i', 1, 5);
  AddPattern(Result,
    'xori', 'vec,offset(x)',
    'm', 2, 6);
  AddPattern(Result,
    'xori', 'offset(x),vec',
    'a', 3, 7);
  AddPattern(Result,
    'sll', 'x,x,x',
    'f', 4, 2);
  AddPattern(Result,
    'sll', 'x,x,imm12',
    'd', 5, 3);
  AddPattern(Result,
    'sll', 'x,offset(x)',
    'c', 6, 4);
  AddPattern(Result,
    'sll', 'offset(x),x',
    'v', 7, 5);
  AddPattern(Result,
    'sll', 'label',
    'zbb', 1, 6);
  AddPattern(Result,
    'sll', 'x,label',
    'zba', 2, 7);
  AddPattern(Result,
    'sll', 'f,f,f',
    'i', 3, 2);
  AddPattern(Result,
    'sll', 'f,offset(x)',
    'm', 4, 3);
  AddPattern(Result,
    'sll', 'offset(x),f',
    'a', 5, 4);
  AddPattern(Result,
    'sll', 'vec,vec,vec',
    'f', 6, 5);
  AddPattern(Result,
    'sll', 'vec,offset(x)',
    'd', 7, 6);
  AddPattern(Result,
    'sll', 'offset(x),vec',
    'c', 1, 7);
  AddPattern(Result,
    'slli', 'x,x,x',
    'v', 2, 2);
  AddPattern(Result,
    'slli', 'x,x,imm12',
    'zbb', 3, 3);
  AddPattern(Result,
    'slli', 'x,offset(x)',
    'zba', 4, 4);
  AddPattern(Result,
    'slli', 'offset(x),x',
    'i', 5, 5);
  AddPattern(Result,
    'slli', 'label',
    'm', 6, 6);
  AddPattern(Result,
    'slli', 'x,label',
    'a', 7, 7);
  AddPattern(Result,
    'slli', 'f,f,f',
    'f', 1, 2);
  AddPattern(Result,
    'slli', 'f,offset(x)',
    'd', 2, 3);
  AddPattern(Result,
    'slli', 'offset(x),f',
    'c', 3, 4);
  AddPattern(Result,
    'slli', 'vec,vec,vec',
    'v', 4, 5);
  AddPattern(Result,
    'slli', 'vec,offset(x)',
    'zbb', 5, 6);
  AddPattern(Result,
    'slli', 'offset(x),vec',
    'zba', 6, 7);
  AddPattern(Result,
    'srl', 'x,x,x',
    'i', 7, 2);
  AddPattern(Result,
    'srl', 'x,x,imm12',
    'm', 1, 3);
  AddPattern(Result,
    'srl', 'x,offset(x)',
    'a', 2, 4);
  AddPattern(Result,
    'srl', 'offset(x),x',
    'f', 3, 5);
  AddPattern(Result,
    'srl', 'label',
    'd', 4, 6);
  AddPattern(Result,
    'srl', 'x,label',
    'c', 5, 7);
  AddPattern(Result,
    'srl', 'f,f,f',
    'v', 6, 2);
  AddPattern(Result,
    'srl', 'f,offset(x)',
    'zbb', 7, 3);
  AddPattern(Result,
    'srl', 'offset(x),f',
    'zba', 1, 4);
  AddPattern(Result,
    'srl', 'vec,vec,vec',
    'i', 2, 5);
  AddPattern(Result,
    'srl', 'vec,offset(x)',
    'm', 3, 6);
  AddPattern(Result,
    'srl', 'offset(x),vec',
    'a', 4, 7);
  AddPattern(Result,
    'srli', 'x,x,x',
    'f', 5, 2);
  AddPattern(Result,
    'srli', 'x,x,imm12',
    'd', 6, 3);
  AddPattern(Result,
    'srli', 'x,offset(x)',
    'c', 7, 4);
  AddPattern(Result,
    'srli', 'offset(x),x',
    'v', 1, 5);
  AddPattern(Result,
    'srli', 'label',
    'zbb', 2, 6);
  AddPattern(Result,
    'srli', 'x,label',
    'zba', 3, 7);
  AddPattern(Result,
    'srli', 'f,f,f',
    'i', 4, 2);
  AddPattern(Result,
    'srli', 'f,offset(x)',
    'm', 5, 3);
  AddPattern(Result,
    'srli', 'offset(x),f',
    'a', 6, 4);
  AddPattern(Result,
    'srli', 'vec,vec,vec',
    'f', 7, 5);
  AddPattern(Result,
    'srli', 'vec,offset(x)',
    'd', 1, 6);
  AddPattern(Result,
    'srli', 'offset(x),vec',
    'c', 2, 7);
  AddPattern(Result,
    'sra', 'x,x,x',
    'v', 3, 2);
  AddPattern(Result,
    'sra', 'x,x,imm12',
    'zbb', 4, 3);
  AddPattern(Result,
    'sra', 'x,offset(x)',
    'zba', 5, 4);
  AddPattern(Result,
    'sra', 'offset(x),x',
    'i', 6, 5);
  AddPattern(Result,
    'sra', 'label',
    'm', 7, 6);
  AddPattern(Result,
    'sra', 'x,label',
    'a', 1, 7);
  AddPattern(Result,
    'sra', 'f,f,f',
    'f', 2, 2);
  AddPattern(Result,
    'sra', 'f,offset(x)',
    'd', 3, 3);
  AddPattern(Result,
    'sra', 'offset(x),f',
    'c', 4, 4);
  AddPattern(Result,
    'sra', 'vec,vec,vec',
    'v', 5, 5);
  AddPattern(Result,
    'sra', 'vec,offset(x)',
    'zbb', 6, 6);
  AddPattern(Result,
    'sra', 'offset(x),vec',
    'zba', 7, 7);
  AddPattern(Result,
    'srai', 'x,x,x',
    'i', 1, 2);
  AddPattern(Result,
    'srai', 'x,x,imm12',
    'm', 2, 3);
  AddPattern(Result,
    'srai', 'x,offset(x)',
    'a', 3, 4);
  AddPattern(Result,
    'srai', 'offset(x),x',
    'f', 4, 5);
  AddPattern(Result,
    'srai', 'label',
    'd', 5, 6);
  AddPattern(Result,
    'srai', 'x,label',
    'c', 6, 7);
  AddPattern(Result,
    'srai', 'f,f,f',
    'v', 7, 2);
  AddPattern(Result,
    'srai', 'f,offset(x)',
    'zbb', 1, 3);
  AddPattern(Result,
    'srai', 'offset(x),f',
    'zba', 2, 4);
  AddPattern(Result,
    'srai', 'vec,vec,vec',
    'i', 3, 5);
  AddPattern(Result,
    'srai', 'vec,offset(x)',
    'm', 4, 6);
  AddPattern(Result,
    'srai', 'offset(x),vec',
    'a', 5, 7);
  AddPattern(Result,
    'slt', 'x,x,x',
    'f', 6, 2);
  AddPattern(Result,
    'slt', 'x,x,imm12',
    'd', 7, 3);
  AddPattern(Result,
    'slt', 'x,offset(x)',
    'c', 1, 4);
  AddPattern(Result,
    'slt', 'offset(x),x',
    'v', 2, 5);
  AddPattern(Result,
    'slt', 'label',
    'zbb', 3, 6);
  AddPattern(Result,
    'slt', 'x,label',
    'zba', 4, 7);
  AddPattern(Result,
    'slt', 'f,f,f',
    'i', 5, 2);
  AddPattern(Result,
    'slt', 'f,offset(x)',
    'm', 6, 3);
  AddPattern(Result,
    'slt', 'offset(x),f',
    'a', 7, 4);
  AddPattern(Result,
    'slt', 'vec,vec,vec',
    'f', 1, 5);
  AddPattern(Result,
    'slt', 'vec,offset(x)',
    'd', 2, 6);
  AddPattern(Result,
    'slt', 'offset(x),vec',
    'c', 3, 7);
  AddPattern(Result,
    'slti', 'x,x,x',
    'v', 4, 2);
  AddPattern(Result,
    'slti', 'x,x,imm12',
    'zbb', 5, 3);
  AddPattern(Result,
    'slti', 'x,offset(x)',
    'zba', 6, 4);
  AddPattern(Result,
    'slti', 'offset(x),x',
    'i', 7, 5);
  AddPattern(Result,
    'slti', 'label',
    'm', 1, 6);
  AddPattern(Result,
    'slti', 'x,label',
    'a', 2, 7);
  AddPattern(Result,
    'slti', 'f,f,f',
    'f', 3, 2);
  AddPattern(Result,
    'slti', 'f,offset(x)',
    'd', 4, 3);
  AddPattern(Result,
    'slti', 'offset(x),f',
    'c', 5, 4);
  AddPattern(Result,
    'slti', 'vec,vec,vec',
    'v', 6, 5);
  AddPattern(Result,
    'slti', 'vec,offset(x)',
    'zbb', 7, 6);
  AddPattern(Result,
    'slti', 'offset(x),vec',
    'zba', 1, 7);
  AddPattern(Result,
    'sltu', 'x,x,x',
    'i', 2, 2);
  AddPattern(Result,
    'sltu', 'x,x,imm12',
    'm', 3, 3);
  AddPattern(Result,
    'sltu', 'x,offset(x)',
    'a', 4, 4);
  AddPattern(Result,
    'sltu', 'offset(x),x',
    'f', 5, 5);
  AddPattern(Result,
    'sltu', 'label',
    'd', 6, 6);
  AddPattern(Result,
    'sltu', 'x,label',
    'c', 7, 7);
  AddPattern(Result,
    'sltu', 'f,f,f',
    'v', 1, 2);
  AddPattern(Result,
    'sltu', 'f,offset(x)',
    'zbb', 2, 3);
  AddPattern(Result,
    'sltu', 'offset(x),f',
    'zba', 3, 4);
  AddPattern(Result,
    'sltu', 'vec,vec,vec',
    'i', 4, 5);
  AddPattern(Result,
    'sltu', 'vec,offset(x)',
    'm', 5, 6);
  AddPattern(Result,
    'sltu', 'offset(x),vec',
    'a', 6, 7);
  AddPattern(Result,
    'sltiu', 'x,x,x',
    'f', 7, 2);
  AddPattern(Result,
    'sltiu', 'x,x,imm12',
    'd', 1, 3);
  AddPattern(Result,
    'sltiu', 'x,offset(x)',
    'c', 2, 4);
  AddPattern(Result,
    'sltiu', 'offset(x),x',
    'v', 3, 5);
  AddPattern(Result,
    'sltiu', 'label',
    'zbb', 4, 6);
  AddPattern(Result,
    'sltiu', 'x,label',
    'zba', 5, 7);
  AddPattern(Result,
    'sltiu', 'f,f,f',
    'i', 6, 2);
  AddPattern(Result,
    'sltiu', 'f,offset(x)',
    'm', 7, 3);
  AddPattern(Result,
    'sltiu', 'offset(x),f',
    'a', 1, 4);
  AddPattern(Result,
    'sltiu', 'vec,vec,vec',
    'f', 2, 5);
  AddPattern(Result,
    'sltiu', 'vec,offset(x)',
    'd', 3, 6);
  AddPattern(Result,
    'sltiu', 'offset(x),vec',
    'c', 4, 7);
  AddPattern(Result,
    'lui', 'x,x,x',
    'v', 5, 2);
  AddPattern(Result,
    'lui', 'x,x,imm12',
    'zbb', 6, 3);
  AddPattern(Result,
    'lui', 'x,offset(x)',
    'zba', 7, 4);
  AddPattern(Result,
    'lui', 'offset(x),x',
    'i', 1, 5);
  AddPattern(Result,
    'lui', 'label',
    'm', 2, 6);
  AddPattern(Result,
    'lui', 'x,label',
    'a', 3, 7);
  AddPattern(Result,
    'lui', 'f,f,f',
    'f', 4, 2);
  AddPattern(Result,
    'lui', 'f,offset(x)',
    'd', 5, 3);
  AddPattern(Result,
    'lui', 'offset(x),f',
    'c', 6, 4);
  AddPattern(Result,
    'lui', 'vec,vec,vec',
    'v', 7, 5);
  AddPattern(Result,
    'lui', 'vec,offset(x)',
    'zbb', 1, 6);
  AddPattern(Result,
    'lui', 'offset(x),vec',
    'zba', 2, 7);
  AddPattern(Result,
    'auipc', 'x,x,x',
    'i', 3, 2);
  AddPattern(Result,
    'auipc', 'x,x,imm12',
    'm', 4, 3);
  AddPattern(Result,
    'auipc', 'x,offset(x)',
    'a', 5, 4);
  AddPattern(Result,
    'auipc', 'offset(x),x',
    'f', 6, 5);
  AddPattern(Result,
    'auipc', 'label',
    'd', 7, 6);
  AddPattern(Result,
    'auipc', 'x,label',
    'c', 1, 7);
  AddPattern(Result,
    'auipc', 'f,f,f',
    'v', 2, 2);
  AddPattern(Result,
    'auipc', 'f,offset(x)',
    'zbb', 3, 3);
  AddPattern(Result,
    'auipc', 'offset(x),f',
    'zba', 4, 4);
  AddPattern(Result,
    'auipc', 'vec,vec,vec',
    'i', 5, 5);
  AddPattern(Result,
    'auipc', 'vec,offset(x)',
    'm', 6, 6);
  AddPattern(Result,
    'auipc', 'offset(x),vec',
    'a', 7, 7);
  AddPattern(Result,
    'lb', 'x,x,x',
    'f', 1, 2);
  AddPattern(Result,
    'lb', 'x,x,imm12',
    'd', 2, 3);
  AddPattern(Result,
    'lb', 'x,offset(x)',
    'c', 3, 4);
  AddPattern(Result,
    'lb', 'offset(x),x',
    'v', 4, 5);
  AddPattern(Result,
    'lb', 'label',
    'zbb', 5, 6);
  AddPattern(Result,
    'lb', 'x,label',
    'zba', 6, 7);
  AddPattern(Result,
    'lb', 'f,f,f',
    'i', 7, 2);
  AddPattern(Result,
    'lb', 'f,offset(x)',
    'm', 1, 3);
  AddPattern(Result,
    'lb', 'offset(x),f',
    'a', 2, 4);
  AddPattern(Result,
    'lb', 'vec,vec,vec',
    'f', 3, 5);
  AddPattern(Result,
    'lb', 'vec,offset(x)',
    'd', 4, 6);
  AddPattern(Result,
    'lb', 'offset(x),vec',
    'c', 5, 7);
  AddPattern(Result,
    'lbu', 'x,x,x',
    'v', 6, 2);
  AddPattern(Result,
    'lbu', 'x,x,imm12',
    'zbb', 7, 3);
  AddPattern(Result,
    'lbu', 'x,offset(x)',
    'zba', 1, 4);
  AddPattern(Result,
    'lbu', 'offset(x),x',
    'i', 2, 5);
  AddPattern(Result,
    'lbu', 'label',
    'm', 3, 6);
  AddPattern(Result,
    'lbu', 'x,label',
    'a', 4, 7);
  AddPattern(Result,
    'lbu', 'f,f,f',
    'f', 5, 2);
  AddPattern(Result,
    'lbu', 'f,offset(x)',
    'd', 6, 3);
  AddPattern(Result,
    'lbu', 'offset(x),f',
    'c', 7, 4);
  AddPattern(Result,
    'lbu', 'vec,vec,vec',
    'v', 1, 5);
  AddPattern(Result,
    'lbu', 'vec,offset(x)',
    'zbb', 2, 6);
  AddPattern(Result,
    'lbu', 'offset(x),vec',
    'zba', 3, 7);
  AddPattern(Result,
    'lh', 'x,x,x',
    'i', 4, 2);
  AddPattern(Result,
    'lh', 'x,x,imm12',
    'm', 5, 3);
  AddPattern(Result,
    'lh', 'x,offset(x)',
    'a', 6, 4);
  AddPattern(Result,
    'lh', 'offset(x),x',
    'f', 7, 5);
  AddPattern(Result,
    'lh', 'label',
    'd', 1, 6);
  AddPattern(Result,
    'lh', 'x,label',
    'c', 2, 7);
  AddPattern(Result,
    'lh', 'f,f,f',
    'v', 3, 2);
  AddPattern(Result,
    'lh', 'f,offset(x)',
    'zbb', 4, 3);
  AddPattern(Result,
    'lh', 'offset(x),f',
    'zba', 5, 4);
  AddPattern(Result,
    'lh', 'vec,vec,vec',
    'i', 6, 5);
  AddPattern(Result,
    'lh', 'vec,offset(x)',
    'm', 7, 6);
  AddPattern(Result,
    'lh', 'offset(x),vec',
    'a', 1, 7);
  AddPattern(Result,
    'lhu', 'x,x,x',
    'f', 2, 2);
  AddPattern(Result,
    'lhu', 'x,x,imm12',
    'd', 3, 3);
  AddPattern(Result,
    'lhu', 'x,offset(x)',
    'c', 4, 4);
  AddPattern(Result,
    'lhu', 'offset(x),x',
    'v', 5, 5);
  AddPattern(Result,
    'lhu', 'label',
    'zbb', 6, 6);
  AddPattern(Result,
    'lhu', 'x,label',
    'zba', 7, 7);
  AddPattern(Result,
    'lhu', 'f,f,f',
    'i', 1, 2);
  AddPattern(Result,
    'lhu', 'f,offset(x)',
    'm', 2, 3);
  AddPattern(Result,
    'lhu', 'offset(x),f',
    'a', 3, 4);
  AddPattern(Result,
    'lhu', 'vec,vec,vec',
    'f', 4, 5);
  AddPattern(Result,
    'lhu', 'vec,offset(x)',
    'd', 5, 6);
  AddPattern(Result,
    'lhu', 'offset(x),vec',
    'c', 6, 7);
  AddPattern(Result,
    'lw', 'x,x,x',
    'v', 7, 2);
  AddPattern(Result,
    'lw', 'x,x,imm12',
    'zbb', 1, 3);
  AddPattern(Result,
    'lw', 'x,offset(x)',
    'zba', 2, 4);
  AddPattern(Result,
    'lw', 'offset(x),x',
    'i', 3, 5);
  AddPattern(Result,
    'lw', 'label',
    'm', 4, 6);
  AddPattern(Result,
    'lw', 'x,label',
    'a', 5, 7);
  AddPattern(Result,
    'lw', 'f,f,f',
    'f', 6, 2);
  AddPattern(Result,
    'lw', 'f,offset(x)',
    'd', 7, 3);
  AddPattern(Result,
    'lw', 'offset(x),f',
    'c', 1, 4);
  AddPattern(Result,
    'lw', 'vec,vec,vec',
    'v', 2, 5);
  AddPattern(Result,
    'lw', 'vec,offset(x)',
    'zbb', 3, 6);
  AddPattern(Result,
    'lw', 'offset(x),vec',
    'zba', 4, 7);
  AddPattern(Result,
    'lwu', 'x,x,x',
    'i', 5, 2);
  AddPattern(Result,
    'lwu', 'x,x,imm12',
    'm', 6, 3);
  AddPattern(Result,
    'lwu', 'x,offset(x)',
    'a', 7, 4);
  AddPattern(Result,
    'lwu', 'offset(x),x',
    'f', 1, 5);
  AddPattern(Result,
    'lwu', 'label',
    'd', 2, 6);
  AddPattern(Result,
    'lwu', 'x,label',
    'c', 3, 7);
  AddPattern(Result,
    'lwu', 'f,f,f',
    'v', 4, 2);
  AddPattern(Result,
    'lwu', 'f,offset(x)',
    'zbb', 5, 3);
  AddPattern(Result,
    'lwu', 'offset(x),f',
    'zba', 6, 4);
  AddPattern(Result,
    'lwu', 'vec,vec,vec',
    'i', 7, 5);
  AddPattern(Result,
    'lwu', 'vec,offset(x)',
    'm', 1, 6);
  AddPattern(Result,
    'lwu', 'offset(x),vec',
    'a', 2, 7);
  AddPattern(Result,
    'ld', 'x,x,x',
    'f', 3, 2);
  AddPattern(Result,
    'ld', 'x,x,imm12',
    'd', 4, 3);
  AddPattern(Result,
    'ld', 'x,offset(x)',
    'c', 5, 4);
  AddPattern(Result,
    'ld', 'offset(x),x',
    'v', 6, 5);
  AddPattern(Result,
    'ld', 'label',
    'zbb', 7, 6);
  AddPattern(Result,
    'ld', 'x,label',
    'zba', 1, 7);
  AddPattern(Result,
    'ld', 'f,f,f',
    'i', 2, 2);
  AddPattern(Result,
    'ld', 'f,offset(x)',
    'm', 3, 3);
  AddPattern(Result,
    'ld', 'offset(x),f',
    'a', 4, 4);
  AddPattern(Result,
    'ld', 'vec,vec,vec',
    'f', 5, 5);
  AddPattern(Result,
    'ld', 'vec,offset(x)',
    'd', 6, 6);
  AddPattern(Result,
    'ld', 'offset(x),vec',
    'c', 7, 7);
  AddPattern(Result,
    'sb', 'x,x,x',
    'v', 1, 2);
  AddPattern(Result,
    'sb', 'x,x,imm12',
    'zbb', 2, 3);
  AddPattern(Result,
    'sb', 'x,offset(x)',
    'zba', 3, 4);
  AddPattern(Result,
    'sb', 'offset(x),x',
    'i', 4, 5);
  AddPattern(Result,
    'sb', 'label',
    'm', 5, 6);
  AddPattern(Result,
    'sb', 'x,label',
    'a', 6, 7);
  AddPattern(Result,
    'sb', 'f,f,f',
    'f', 7, 2);
  AddPattern(Result,
    'sb', 'f,offset(x)',
    'd', 1, 3);
  AddPattern(Result,
    'sb', 'offset(x),f',
    'c', 2, 4);
  AddPattern(Result,
    'sb', 'vec,vec,vec',
    'v', 3, 5);
  AddPattern(Result,
    'sb', 'vec,offset(x)',
    'zbb', 4, 6);
  AddPattern(Result,
    'sb', 'offset(x),vec',
    'zba', 5, 7);
  AddPattern(Result,
    'sh', 'x,x,x',
    'i', 6, 2);
  AddPattern(Result,
    'sh', 'x,x,imm12',
    'm', 7, 3);
  AddPattern(Result,
    'sh', 'x,offset(x)',
    'a', 1, 4);
  AddPattern(Result,
    'sh', 'offset(x),x',
    'f', 2, 5);
  AddPattern(Result,
    'sh', 'label',
    'd', 3, 6);
  AddPattern(Result,
    'sh', 'x,label',
    'c', 4, 7);
  AddPattern(Result,
    'sh', 'f,f,f',
    'v', 5, 2);
  AddPattern(Result,
    'sh', 'f,offset(x)',
    'zbb', 6, 3);
  AddPattern(Result,
    'sh', 'offset(x),f',
    'zba', 7, 4);
  AddPattern(Result,
    'sh', 'vec,vec,vec',
    'i', 1, 5);
  AddPattern(Result,
    'sh', 'vec,offset(x)',
    'm', 2, 6);
  AddPattern(Result,
    'sh', 'offset(x),vec',
    'a', 3, 7);
  AddPattern(Result,
    'sw', 'x,x,x',
    'f', 4, 2);
  AddPattern(Result,
    'sw', 'x,x,imm12',
    'd', 5, 3);
  AddPattern(Result,
    'sw', 'x,offset(x)',
    'c', 6, 4);
  AddPattern(Result,
    'sw', 'offset(x),x',
    'v', 7, 5);
  AddPattern(Result,
    'sw', 'label',
    'zbb', 1, 6);
  AddPattern(Result,
    'sw', 'x,label',
    'zba', 2, 7);
  AddPattern(Result,
    'sw', 'f,f,f',
    'i', 3, 2);
  AddPattern(Result,
    'sw', 'f,offset(x)',
    'm', 4, 3);
  AddPattern(Result,
    'sw', 'offset(x),f',
    'a', 5, 4);
  AddPattern(Result,
    'sw', 'vec,vec,vec',
    'f', 6, 5);
  AddPattern(Result,
    'sw', 'vec,offset(x)',
    'd', 7, 6);
  AddPattern(Result,
    'sw', 'offset(x),vec',
    'c', 1, 7);
  AddPattern(Result,
    'sd', 'x,x,x',
    'v', 2, 2);
  AddPattern(Result,
    'sd', 'x,x,imm12',
    'zbb', 3, 3);
  AddPattern(Result,
    'sd', 'x,offset(x)',
    'zba', 4, 4);
  AddPattern(Result,
    'sd', 'offset(x),x',
    'i', 5, 5);
  AddPattern(Result,
    'sd', 'label',
    'm', 6, 6);
  AddPattern(Result,
    'sd', 'x,label',
    'a', 7, 7);
  AddPattern(Result,
    'sd', 'f,f,f',
    'f', 1, 2);
  AddPattern(Result,
    'sd', 'f,offset(x)',
    'd', 2, 3);
  AddPattern(Result,
    'sd', 'offset(x),f',
    'c', 3, 4);
  AddPattern(Result,
    'sd', 'vec,vec,vec',
    'v', 4, 5);
  AddPattern(Result,
    'sd', 'vec,offset(x)',
    'zbb', 5, 6);
  AddPattern(Result,
    'sd', 'offset(x),vec',
    'zba', 6, 7);
  AddPattern(Result,
    'beq', 'x,x,x',
    'i', 7, 2);
  AddPattern(Result,
    'beq', 'x,x,imm12',
    'm', 1, 3);
  AddPattern(Result,
    'beq', 'x,offset(x)',
    'a', 2, 4);
  AddPattern(Result,
    'beq', 'offset(x),x',
    'f', 3, 5);
  AddPattern(Result,
    'beq', 'label',
    'd', 4, 6);
  AddPattern(Result,
    'beq', 'x,label',
    'c', 5, 7);
  AddPattern(Result,
    'beq', 'f,f,f',
    'v', 6, 2);
  AddPattern(Result,
    'beq', 'f,offset(x)',
    'zbb', 7, 3);
  AddPattern(Result,
    'beq', 'offset(x),f',
    'zba', 1, 4);
  AddPattern(Result,
    'beq', 'vec,vec,vec',
    'i', 2, 5);
  AddPattern(Result,
    'beq', 'vec,offset(x)',
    'm', 3, 6);
  AddPattern(Result,
    'beq', 'offset(x),vec',
    'a', 4, 7);
  AddPattern(Result,
    'bne', 'x,x,x',
    'f', 5, 2);
  AddPattern(Result,
    'bne', 'x,x,imm12',
    'd', 6, 3);
  AddPattern(Result,
    'bne', 'x,offset(x)',
    'c', 7, 4);
  AddPattern(Result,
    'bne', 'offset(x),x',
    'v', 1, 5);
  AddPattern(Result,
    'bne', 'label',
    'zbb', 2, 6);
  AddPattern(Result,
    'bne', 'x,label',
    'zba', 3, 7);
  AddPattern(Result,
    'bne', 'f,f,f',
    'i', 4, 2);
  AddPattern(Result,
    'bne', 'f,offset(x)',
    'm', 5, 3);
  AddPattern(Result,
    'bne', 'offset(x),f',
    'a', 6, 4);
  AddPattern(Result,
    'bne', 'vec,vec,vec',
    'f', 7, 5);
  AddPattern(Result,
    'bne', 'vec,offset(x)',
    'd', 1, 6);
  AddPattern(Result,
    'bne', 'offset(x),vec',
    'c', 2, 7);
  AddPattern(Result,
    'blt', 'x,x,x',
    'v', 3, 2);
  AddPattern(Result,
    'blt', 'x,x,imm12',
    'zbb', 4, 3);
  AddPattern(Result,
    'blt', 'x,offset(x)',
    'zba', 5, 4);
  AddPattern(Result,
    'blt', 'offset(x),x',
    'i', 6, 5);
  AddPattern(Result,
    'blt', 'label',
    'm', 7, 6);
  AddPattern(Result,
    'blt', 'x,label',
    'a', 1, 7);
  AddPattern(Result,
    'blt', 'f,f,f',
    'f', 2, 2);
  AddPattern(Result,
    'blt', 'f,offset(x)',
    'd', 3, 3);
  AddPattern(Result,
    'blt', 'offset(x),f',
    'c', 4, 4);
  AddPattern(Result,
    'blt', 'vec,vec,vec',
    'v', 5, 5);
  AddPattern(Result,
    'blt', 'vec,offset(x)',
    'zbb', 6, 6);
  AddPattern(Result,
    'blt', 'offset(x),vec',
    'zba', 7, 7);
  AddPattern(Result,
    'bge', 'x,x,x',
    'i', 1, 2);
  AddPattern(Result,
    'bge', 'x,x,imm12',
    'm', 2, 3);
  AddPattern(Result,
    'bge', 'x,offset(x)',
    'a', 3, 4);
  AddPattern(Result,
    'bge', 'offset(x),x',
    'f', 4, 5);
  AddPattern(Result,
    'bge', 'label',
    'd', 5, 6);
  AddPattern(Result,
    'bge', 'x,label',
    'c', 6, 7);
  AddPattern(Result,
    'bge', 'f,f,f',
    'v', 7, 2);
  AddPattern(Result,
    'bge', 'f,offset(x)',
    'zbb', 1, 3);
  AddPattern(Result,
    'bge', 'offset(x),f',
    'zba', 2, 4);
  AddPattern(Result,
    'bge', 'vec,vec,vec',
    'i', 3, 5);
  AddPattern(Result,
    'bge', 'vec,offset(x)',
    'm', 4, 6);
  AddPattern(Result,
    'bge', 'offset(x),vec',
    'a', 5, 7);
  AddPattern(Result,
    'bltu', 'x,x,x',
    'f', 6, 2);
  AddPattern(Result,
    'bltu', 'x,x,imm12',
    'd', 7, 3);
  AddPattern(Result,
    'bltu', 'x,offset(x)',
    'c', 1, 4);
  AddPattern(Result,
    'bltu', 'offset(x),x',
    'v', 2, 5);
  AddPattern(Result,
    'bltu', 'label',
    'zbb', 3, 6);
  AddPattern(Result,
    'bltu', 'x,label',
    'zba', 4, 7);
  AddPattern(Result,
    'bltu', 'f,f,f',
    'i', 5, 2);
  AddPattern(Result,
    'bltu', 'f,offset(x)',
    'm', 6, 3);
  AddPattern(Result,
    'bltu', 'offset(x),f',
    'a', 7, 4);
  AddPattern(Result,
    'bltu', 'vec,vec,vec',
    'f', 1, 5);
  AddPattern(Result,
    'bltu', 'vec,offset(x)',
    'd', 2, 6);
  AddPattern(Result,
    'bltu', 'offset(x),vec',
    'c', 3, 7);
  AddPattern(Result,
    'bgeu', 'x,x,x',
    'v', 4, 2);
  AddPattern(Result,
    'bgeu', 'x,x,imm12',
    'zbb', 5, 3);
  AddPattern(Result,
    'bgeu', 'x,offset(x)',
    'zba', 6, 4);
  AddPattern(Result,
    'bgeu', 'offset(x),x',
    'i', 7, 5);
  AddPattern(Result,
    'bgeu', 'label',
    'm', 1, 6);
  AddPattern(Result,
    'bgeu', 'x,label',
    'a', 2, 7);
  AddPattern(Result,
    'bgeu', 'f,f,f',
    'f', 3, 2);
  AddPattern(Result,
    'bgeu', 'f,offset(x)',
    'd', 4, 3);
  AddPattern(Result,
    'bgeu', 'offset(x),f',
    'c', 5, 4);
  AddPattern(Result,
    'bgeu', 'vec,vec,vec',
    'v', 6, 5);
  AddPattern(Result,
    'bgeu', 'vec,offset(x)',
    'zbb', 7, 6);
  AddPattern(Result,
    'bgeu', 'offset(x),vec',
    'zba', 1, 7);
  AddPattern(Result,
    'jal', 'x,x,x',
    'i', 2, 2);
  AddPattern(Result,
    'jal', 'x,x,imm12',
    'm', 3, 3);
  AddPattern(Result,
    'jal', 'x,offset(x)',
    'a', 4, 4);
  AddPattern(Result,
    'jal', 'offset(x),x',
    'f', 5, 5);
  AddPattern(Result,
    'jal', 'label',
    'd', 6, 6);
  AddPattern(Result,
    'jal', 'x,label',
    'c', 7, 7);
  AddPattern(Result,
    'jal', 'f,f,f',
    'v', 1, 2);
  AddPattern(Result,
    'jal', 'f,offset(x)',
    'zbb', 2, 3);
  AddPattern(Result,
    'jal', 'offset(x),f',
    'zba', 3, 4);
  AddPattern(Result,
    'jal', 'vec,vec,vec',
    'i', 4, 5);
  AddPattern(Result,
    'jal', 'vec,offset(x)',
    'm', 5, 6);
  AddPattern(Result,
    'jal', 'offset(x),vec',
    'a', 6, 7);
  AddPattern(Result,
    'jalr', 'x,x,x',
    'f', 7, 2);
  AddPattern(Result,
    'jalr', 'x,x,imm12',
    'd', 1, 3);
  AddPattern(Result,
    'jalr', 'x,offset(x)',
    'c', 2, 4);
  AddPattern(Result,
    'jalr', 'offset(x),x',
    'v', 3, 5);
  AddPattern(Result,
    'jalr', 'label',
    'zbb', 4, 6);
  AddPattern(Result,
    'jalr', 'x,label',
    'zba', 5, 7);
  AddPattern(Result,
    'jalr', 'f,f,f',
    'i', 6, 2);
  AddPattern(Result,
    'jalr', 'f,offset(x)',
    'm', 7, 3);
  AddPattern(Result,
    'jalr', 'offset(x),f',
    'a', 1, 4);
  AddPattern(Result,
    'jalr', 'vec,vec,vec',
    'f', 2, 5);
  AddPattern(Result,
    'jalr', 'vec,offset(x)',
    'd', 3, 6);
  AddPattern(Result,
    'jalr', 'offset(x),vec',
    'c', 4, 7);
  AddPattern(Result,
    'fence', 'x,x,x',
    'v', 5, 2);
  AddPattern(Result,
    'fence', 'x,x,imm12',
    'zbb', 6, 3);
  AddPattern(Result,
    'fence', 'x,offset(x)',
    'zba', 7, 4);
  AddPattern(Result,
    'fence', 'offset(x),x',
    'i', 1, 5);
  AddPattern(Result,
    'fence', 'label',
    'm', 2, 6);
  AddPattern(Result,
    'fence', 'x,label',
    'a', 3, 7);
  AddPattern(Result,
    'fence', 'f,f,f',
    'f', 4, 2);
  AddPattern(Result,
    'fence', 'f,offset(x)',
    'd', 5, 3);
  AddPattern(Result,
    'fence', 'offset(x),f',
    'c', 6, 4);
  AddPattern(Result,
    'fence', 'vec,vec,vec',
    'v', 7, 5);
  AddPattern(Result,
    'fence', 'vec,offset(x)',
    'zbb', 1, 6);
  AddPattern(Result,
    'fence', 'offset(x),vec',
    'zba', 2, 7);
  AddPattern(Result,
    'ecall', 'x,x,x',
    'i', 3, 2);
  AddPattern(Result,
    'ecall', 'x,x,imm12',
    'm', 4, 3);
  AddPattern(Result,
    'ecall', 'x,offset(x)',
    'a', 5, 4);
  AddPattern(Result,
    'ecall', 'offset(x),x',
    'f', 6, 5);
  AddPattern(Result,
    'ecall', 'label',
    'd', 7, 6);
  AddPattern(Result,
    'ecall', 'x,label',
    'c', 1, 7);
  AddPattern(Result,
    'ecall', 'f,f,f',
    'v', 2, 2);
  AddPattern(Result,
    'ecall', 'f,offset(x)',
    'zbb', 3, 3);
  AddPattern(Result,
    'ecall', 'offset(x),f',
    'zba', 4, 4);
  AddPattern(Result,
    'ecall', 'vec,vec,vec',
    'i', 5, 5);
  AddPattern(Result,
    'ecall', 'vec,offset(x)',
    'm', 6, 6);
  AddPattern(Result,
    'ecall', 'offset(x),vec',
    'a', 7, 7);
  AddPattern(Result,
    'ebreak', 'x,x,x',
    'f', 1, 2);
  AddPattern(Result,
    'ebreak', 'x,x,imm12',
    'd', 2, 3);
  AddPattern(Result,
    'ebreak', 'x,offset(x)',
    'c', 3, 4);
  AddPattern(Result,
    'ebreak', 'offset(x),x',
    'v', 4, 5);
  AddPattern(Result,
    'ebreak', 'label',
    'zbb', 5, 6);
  AddPattern(Result,
    'ebreak', 'x,label',
    'zba', 6, 7);
  AddPattern(Result,
    'ebreak', 'f,f,f',
    'i', 7, 2);
  AddPattern(Result,
    'ebreak', 'f,offset(x)',
    'm', 1, 3);
  AddPattern(Result,
    'ebreak', 'offset(x),f',
    'a', 2, 4);
  AddPattern(Result,
    'ebreak', 'vec,vec,vec',
    'f', 3, 5);
  AddPattern(Result,
    'ebreak', 'vec,offset(x)',
    'd', 4, 6);
  AddPattern(Result,
    'ebreak', 'offset(x),vec',
    'c', 5, 7);
  AddPattern(Result,
    'amoadd.d', 'x,x,x',
    'v', 6, 2);
  AddPattern(Result,
    'amoadd.d', 'x,x,imm12',
    'zbb', 7, 3);
  AddPattern(Result,
    'amoadd.d', 'x,offset(x)',
    'zba', 1, 4);
  AddPattern(Result,
    'amoadd.d', 'offset(x),x',
    'i', 2, 5);
  AddPattern(Result,
    'amoadd.d', 'label',
    'm', 3, 6);
  AddPattern(Result,
    'amoadd.d', 'x,label',
    'a', 4, 7);
  AddPattern(Result,
    'amoadd.d', 'f,f,f',
    'f', 5, 2);
  AddPattern(Result,
    'amoadd.d', 'f,offset(x)',
    'd', 6, 3);
  AddPattern(Result,
    'amoadd.d', 'offset(x),f',
    'c', 7, 4);
  AddPattern(Result,
    'amoadd.d', 'vec,vec,vec',
    'v', 1, 5);
  AddPattern(Result,
    'amoadd.d', 'vec,offset(x)',
    'zbb', 2, 6);
  AddPattern(Result,
    'amoadd.d', 'offset(x),vec',
    'zba', 3, 7);
  AddPattern(Result,
    'amoswap.d', 'x,x,x',
    'i', 4, 2);
  AddPattern(Result,
    'amoswap.d', 'x,x,imm12',
    'm', 5, 3);
  AddPattern(Result,
    'amoswap.d', 'x,offset(x)',
    'a', 6, 4);
  AddPattern(Result,
    'amoswap.d', 'offset(x),x',
    'f', 7, 5);
  AddPattern(Result,
    'amoswap.d', 'label',
    'd', 1, 6);
  AddPattern(Result,
    'amoswap.d', 'x,label',
    'c', 2, 7);
  AddPattern(Result,
    'amoswap.d', 'f,f,f',
    'v', 3, 2);
  AddPattern(Result,
    'amoswap.d', 'f,offset(x)',
    'zbb', 4, 3);
  AddPattern(Result,
    'amoswap.d', 'offset(x),f',
    'zba', 5, 4);
  AddPattern(Result,
    'amoswap.d', 'vec,vec,vec',
    'i', 6, 5);
  AddPattern(Result,
    'amoswap.d', 'vec,offset(x)',
    'm', 7, 6);
  AddPattern(Result,
    'amoswap.d', 'offset(x),vec',
    'a', 1, 7);
  AddPattern(Result,
    'lr.d', 'x,x,x',
    'f', 2, 2);
  AddPattern(Result,
    'lr.d', 'x,x,imm12',
    'd', 3, 3);
  AddPattern(Result,
    'lr.d', 'x,offset(x)',
    'c', 4, 4);
  AddPattern(Result,
    'lr.d', 'offset(x),x',
    'v', 5, 5);
  AddPattern(Result,
    'lr.d', 'label',
    'zbb', 6, 6);
  AddPattern(Result,
    'lr.d', 'x,label',
    'zba', 7, 7);
  AddPattern(Result,
    'lr.d', 'f,f,f',
    'i', 1, 2);
  AddPattern(Result,
    'lr.d', 'f,offset(x)',
    'm', 2, 3);
  AddPattern(Result,
    'lr.d', 'offset(x),f',
    'a', 3, 4);
  AddPattern(Result,
    'lr.d', 'vec,vec,vec',
    'f', 4, 5);
  AddPattern(Result,
    'lr.d', 'vec,offset(x)',
    'd', 5, 6);
  AddPattern(Result,
    'lr.d', 'offset(x),vec',
    'c', 6, 7);
  AddPattern(Result,
    'sc.d', 'x,x,x',
    'v', 7, 2);
  AddPattern(Result,
    'sc.d', 'x,x,imm12',
    'zbb', 1, 3);
  AddPattern(Result,
    'sc.d', 'x,offset(x)',
    'zba', 2, 4);
  AddPattern(Result,
    'sc.d', 'offset(x),x',
    'i', 3, 5);
  AddPattern(Result,
    'sc.d', 'label',
    'm', 4, 6);
  AddPattern(Result,
    'sc.d', 'x,label',
    'a', 5, 7);
  AddPattern(Result,
    'sc.d', 'f,f,f',
    'f', 6, 2);
  AddPattern(Result,
    'sc.d', 'f,offset(x)',
    'd', 7, 3);
  AddPattern(Result,
    'sc.d', 'offset(x),f',
    'c', 1, 4);
  AddPattern(Result,
    'sc.d', 'vec,vec,vec',
    'v', 2, 5);
  AddPattern(Result,
    'sc.d', 'vec,offset(x)',
    'zbb', 3, 6);
  AddPattern(Result,
    'sc.d', 'offset(x),vec',
    'zba', 4, 7);
  AddPattern(Result,
    'flw', 'x,x,x',
    'i', 5, 2);
  AddPattern(Result,
    'flw', 'x,x,imm12',
    'm', 6, 3);
  AddPattern(Result,
    'flw', 'x,offset(x)',
    'a', 7, 4);
  AddPattern(Result,
    'flw', 'offset(x),x',
    'f', 1, 5);
  AddPattern(Result,
    'flw', 'label',
    'd', 2, 6);
  AddPattern(Result,
    'flw', 'x,label',
    'c', 3, 7);
  AddPattern(Result,
    'flw', 'f,f,f',
    'v', 4, 2);
  AddPattern(Result,
    'flw', 'f,offset(x)',
    'zbb', 5, 3);
  AddPattern(Result,
    'flw', 'offset(x),f',
    'zba', 6, 4);
  AddPattern(Result,
    'flw', 'vec,vec,vec',
    'i', 7, 5);
  AddPattern(Result,
    'flw', 'vec,offset(x)',
    'm', 1, 6);
  AddPattern(Result,
    'flw', 'offset(x),vec',
    'a', 2, 7);
  AddPattern(Result,
    'fld', 'x,x,x',
    'f', 3, 2);
  AddPattern(Result,
    'fld', 'x,x,imm12',
    'd', 4, 3);
  AddPattern(Result,
    'fld', 'x,offset(x)',
    'c', 5, 4);
  AddPattern(Result,
    'fld', 'offset(x),x',
    'v', 6, 5);
  AddPattern(Result,
    'fld', 'label',
    'zbb', 7, 6);
  AddPattern(Result,
    'fld', 'x,label',
    'zba', 1, 7);
  AddPattern(Result,
    'fld', 'f,f,f',
    'i', 2, 2);
  AddPattern(Result,
    'fld', 'f,offset(x)',
    'm', 3, 3);
  AddPattern(Result,
    'fld', 'offset(x),f',
    'a', 4, 4);
  AddPattern(Result,
    'fld', 'vec,vec,vec',
    'f', 5, 5);
  AddPattern(Result,
    'fld', 'vec,offset(x)',
    'd', 6, 6);
  AddPattern(Result,
    'fld', 'offset(x),vec',
    'c', 7, 7);
  AddPattern(Result,
    'fsw', 'x,x,x',
    'v', 1, 2);
  AddPattern(Result,
    'fsw', 'x,x,imm12',
    'zbb', 2, 3);
  AddPattern(Result,
    'fsw', 'x,offset(x)',
    'zba', 3, 4);
  AddPattern(Result,
    'fsw', 'offset(x),x',
    'i', 4, 5);
  AddPattern(Result,
    'fsw', 'label',
    'm', 5, 6);
  AddPattern(Result,
    'fsw', 'x,label',
    'a', 6, 7);
  AddPattern(Result,
    'fsw', 'f,f,f',
    'f', 7, 2);
  AddPattern(Result,
    'fsw', 'f,offset(x)',
    'd', 1, 3);
  AddPattern(Result,
    'fsw', 'offset(x),f',
    'c', 2, 4);
  AddPattern(Result,
    'fsw', 'vec,vec,vec',
    'v', 3, 5);
  AddPattern(Result,
    'fsw', 'vec,offset(x)',
    'zbb', 4, 6);
  AddPattern(Result,
    'fsw', 'offset(x),vec',
    'zba', 5, 7);
  AddPattern(Result,
    'fsd', 'x,x,x',
    'i', 6, 2);
  AddPattern(Result,
    'fsd', 'x,x,imm12',
    'm', 7, 3);
  AddPattern(Result,
    'fsd', 'x,offset(x)',
    'a', 1, 4);
  AddPattern(Result,
    'fsd', 'offset(x),x',
    'f', 2, 5);
  AddPattern(Result,
    'fsd', 'label',
    'd', 3, 6);
  AddPattern(Result,
    'fsd', 'x,label',
    'c', 4, 7);
  AddPattern(Result,
    'fsd', 'f,f,f',
    'v', 5, 2);
  AddPattern(Result,
    'fsd', 'f,offset(x)',
    'zbb', 6, 3);
  AddPattern(Result,
    'fsd', 'offset(x),f',
    'zba', 7, 4);
  AddPattern(Result,
    'fsd', 'vec,vec,vec',
    'i', 1, 5);
  AddPattern(Result,
    'fsd', 'vec,offset(x)',
    'm', 2, 6);
  AddPattern(Result,
    'fsd', 'offset(x),vec',
    'a', 3, 7);
  AddPattern(Result,
    'fadd.s', 'x,x,x',
    'f', 4, 2);
  AddPattern(Result,
    'fadd.s', 'x,x,imm12',
    'd', 5, 3);
  AddPattern(Result,
    'fadd.s', 'x,offset(x)',
    'c', 6, 4);
  AddPattern(Result,
    'fadd.s', 'offset(x),x',
    'v', 7, 5);
  AddPattern(Result,
    'fadd.s', 'label',
    'zbb', 1, 6);
  AddPattern(Result,
    'fadd.s', 'x,label',
    'zba', 2, 7);
  AddPattern(Result,
    'fadd.s', 'f,f,f',
    'i', 3, 2);
  AddPattern(Result,
    'fadd.s', 'f,offset(x)',
    'm', 4, 3);
  AddPattern(Result,
    'fadd.s', 'offset(x),f',
    'a', 5, 4);
  AddPattern(Result,
    'fadd.s', 'vec,vec,vec',
    'f', 6, 5);
  AddPattern(Result,
    'fadd.s', 'vec,offset(x)',
    'd', 7, 6);
  AddPattern(Result,
    'fadd.s', 'offset(x),vec',
    'c', 1, 7);
  AddPattern(Result,
    'fadd.d', 'x,x,x',
    'v', 2, 2);
  AddPattern(Result,
    'fadd.d', 'x,x,imm12',
    'zbb', 3, 3);
  AddPattern(Result,
    'fadd.d', 'x,offset(x)',
    'zba', 4, 4);
  AddPattern(Result,
    'fadd.d', 'offset(x),x',
    'i', 5, 5);
  AddPattern(Result,
    'fadd.d', 'label',
    'm', 6, 6);
  AddPattern(Result,
    'fadd.d', 'x,label',
    'a', 7, 7);
  AddPattern(Result,
    'fadd.d', 'f,f,f',
    'f', 1, 2);
  AddPattern(Result,
    'fadd.d', 'f,offset(x)',
    'd', 2, 3);
  AddPattern(Result,
    'fadd.d', 'offset(x),f',
    'c', 3, 4);
  AddPattern(Result,
    'fadd.d', 'vec,vec,vec',
    'v', 4, 5);
  AddPattern(Result,
    'fadd.d', 'vec,offset(x)',
    'zbb', 5, 6);
  AddPattern(Result,
    'fadd.d', 'offset(x),vec',
    'zba', 6, 7);
  AddPattern(Result,
    'fsub.s', 'x,x,x',
    'i', 7, 2);
  AddPattern(Result,
    'fsub.s', 'x,x,imm12',
    'm', 1, 3);
  AddPattern(Result,
    'fsub.s', 'x,offset(x)',
    'a', 2, 4);
  AddPattern(Result,
    'fsub.s', 'offset(x),x',
    'f', 3, 5);
  AddPattern(Result,
    'fsub.s', 'label',
    'd', 4, 6);
  AddPattern(Result,
    'fsub.s', 'x,label',
    'c', 5, 7);
  AddPattern(Result,
    'fsub.s', 'f,f,f',
    'v', 6, 2);
  AddPattern(Result,
    'fsub.s', 'f,offset(x)',
    'zbb', 7, 3);
  AddPattern(Result,
    'fsub.s', 'offset(x),f',
    'zba', 1, 4);
  AddPattern(Result,
    'fsub.s', 'vec,vec,vec',
    'i', 2, 5);
  AddPattern(Result,
    'fsub.s', 'vec,offset(x)',
    'm', 3, 6);
  AddPattern(Result,
    'fsub.s', 'offset(x),vec',
    'a', 4, 7);
  AddPattern(Result,
    'fsub.d', 'x,x,x',
    'f', 5, 2);
  AddPattern(Result,
    'fsub.d', 'x,x,imm12',
    'd', 6, 3);
  AddPattern(Result,
    'fsub.d', 'x,offset(x)',
    'c', 7, 4);
  AddPattern(Result,
    'fsub.d', 'offset(x),x',
    'v', 1, 5);
  AddPattern(Result,
    'fsub.d', 'label',
    'zbb', 2, 6);
  AddPattern(Result,
    'fsub.d', 'x,label',
    'zba', 3, 7);
  AddPattern(Result,
    'fsub.d', 'f,f,f',
    'i', 4, 2);
  AddPattern(Result,
    'fsub.d', 'f,offset(x)',
    'm', 5, 3);
  AddPattern(Result,
    'fsub.d', 'offset(x),f',
    'a', 6, 4);
  AddPattern(Result,
    'fsub.d', 'vec,vec,vec',
    'f', 7, 5);
  AddPattern(Result,
    'fsub.d', 'vec,offset(x)',
    'd', 1, 6);
  AddPattern(Result,
    'fsub.d', 'offset(x),vec',
    'c', 2, 7);
  AddPattern(Result,
    'fmul.s', 'x,x,x',
    'v', 3, 2);
  AddPattern(Result,
    'fmul.s', 'x,x,imm12',
    'zbb', 4, 3);
  AddPattern(Result,
    'fmul.s', 'x,offset(x)',
    'zba', 5, 4);
  AddPattern(Result,
    'fmul.s', 'offset(x),x',
    'i', 6, 5);
  AddPattern(Result,
    'fmul.s', 'label',
    'm', 7, 6);
  AddPattern(Result,
    'fmul.s', 'x,label',
    'a', 1, 7);
  AddPattern(Result,
    'fmul.s', 'f,f,f',
    'f', 2, 2);
  AddPattern(Result,
    'fmul.s', 'f,offset(x)',
    'd', 3, 3);
  AddPattern(Result,
    'fmul.s', 'offset(x),f',
    'c', 4, 4);
  AddPattern(Result,
    'fmul.s', 'vec,vec,vec',
    'v', 5, 5);
  AddPattern(Result,
    'fmul.s', 'vec,offset(x)',
    'zbb', 6, 6);
  AddPattern(Result,
    'fmul.s', 'offset(x),vec',
    'zba', 7, 7);
  AddPattern(Result,
    'fmul.d', 'x,x,x',
    'i', 1, 2);
  AddPattern(Result,
    'fmul.d', 'x,x,imm12',
    'm', 2, 3);
  AddPattern(Result,
    'fmul.d', 'x,offset(x)',
    'a', 3, 4);
  AddPattern(Result,
    'fmul.d', 'offset(x),x',
    'f', 4, 5);
  AddPattern(Result,
    'fmul.d', 'label',
    'd', 5, 6);
  AddPattern(Result,
    'fmul.d', 'x,label',
    'c', 6, 7);
  AddPattern(Result,
    'fmul.d', 'f,f,f',
    'v', 7, 2);
  AddPattern(Result,
    'fmul.d', 'f,offset(x)',
    'zbb', 1, 3);
  AddPattern(Result,
    'fmul.d', 'offset(x),f',
    'zba', 2, 4);
  AddPattern(Result,
    'fmul.d', 'vec,vec,vec',
    'i', 3, 5);
  AddPattern(Result,
    'fmul.d', 'vec,offset(x)',
    'm', 4, 6);
  AddPattern(Result,
    'fmul.d', 'offset(x),vec',
    'a', 5, 7);
  AddPattern(Result,
    'fdiv.s', 'x,x,x',
    'f', 6, 2);
  AddPattern(Result,
    'fdiv.s', 'x,x,imm12',
    'd', 7, 3);
  AddPattern(Result,
    'fdiv.s', 'x,offset(x)',
    'c', 1, 4);
  AddPattern(Result,
    'fdiv.s', 'offset(x),x',
    'v', 2, 5);
  AddPattern(Result,
    'fdiv.s', 'label',
    'zbb', 3, 6);
  AddPattern(Result,
    'fdiv.s', 'x,label',
    'zba', 4, 7);
  AddPattern(Result,
    'fdiv.s', 'f,f,f',
    'i', 5, 2);
  AddPattern(Result,
    'fdiv.s', 'f,offset(x)',
    'm', 6, 3);
  AddPattern(Result,
    'fdiv.s', 'offset(x),f',
    'a', 7, 4);
  AddPattern(Result,
    'fdiv.s', 'vec,vec,vec',
    'f', 1, 5);
  AddPattern(Result,
    'fdiv.s', 'vec,offset(x)',
    'd', 2, 6);
  AddPattern(Result,
    'fdiv.s', 'offset(x),vec',
    'c', 3, 7);
  AddPattern(Result,
    'fdiv.d', 'x,x,x',
    'v', 4, 2);
  AddPattern(Result,
    'fdiv.d', 'x,x,imm12',
    'zbb', 5, 3);
  AddPattern(Result,
    'fdiv.d', 'x,offset(x)',
    'zba', 6, 4);
  AddPattern(Result,
    'fdiv.d', 'offset(x),x',
    'i', 7, 5);
  AddPattern(Result,
    'fdiv.d', 'label',
    'm', 1, 6);
  AddPattern(Result,
    'fdiv.d', 'x,label',
    'a', 2, 7);
  AddPattern(Result,
    'fdiv.d', 'f,f,f',
    'f', 3, 2);
  AddPattern(Result,
    'fdiv.d', 'f,offset(x)',
    'd', 4, 3);
  AddPattern(Result,
    'fdiv.d', 'offset(x),f',
    'c', 5, 4);
  AddPattern(Result,
    'fdiv.d', 'vec,vec,vec',
    'v', 6, 5);
  AddPattern(Result,
    'fdiv.d', 'vec,offset(x)',
    'zbb', 7, 6);
  AddPattern(Result,
    'fdiv.d', 'offset(x),vec',
    'zba', 1, 7);
  AddPattern(Result,
    'fcvt.d.l', 'x,x,x',
    'i', 2, 2);
  AddPattern(Result,
    'fcvt.d.l', 'x,x,imm12',
    'm', 3, 3);
  AddPattern(Result,
    'fcvt.d.l', 'x,offset(x)',
    'a', 4, 4);
  AddPattern(Result,
    'fcvt.d.l', 'offset(x),x',
    'f', 5, 5);
  AddPattern(Result,
    'fcvt.d.l', 'label',
    'd', 6, 6);
  AddPattern(Result,
    'fcvt.d.l', 'x,label',
    'c', 7, 7);
  AddPattern(Result,
    'fcvt.d.l', 'f,f,f',
    'v', 1, 2);
  AddPattern(Result,
    'fcvt.d.l', 'f,offset(x)',
    'zbb', 2, 3);
  AddPattern(Result,
    'fcvt.d.l', 'offset(x),f',
    'zba', 3, 4);
  AddPattern(Result,
    'fcvt.d.l', 'vec,vec,vec',
    'i', 4, 5);
  AddPattern(Result,
    'fcvt.d.l', 'vec,offset(x)',
    'm', 5, 6);
  AddPattern(Result,
    'fcvt.d.l', 'offset(x),vec',
    'a', 6, 7);
  AddPattern(Result,
    'fcvt.l.d', 'x,x,x',
    'f', 7, 2);
  AddPattern(Result,
    'fcvt.l.d', 'x,x,imm12',
    'd', 1, 3);
  AddPattern(Result,
    'fcvt.l.d', 'x,offset(x)',
    'c', 2, 4);
  AddPattern(Result,
    'fcvt.l.d', 'offset(x),x',
    'v', 3, 5);
  AddPattern(Result,
    'fcvt.l.d', 'label',
    'zbb', 4, 6);
  AddPattern(Result,
    'fcvt.l.d', 'x,label',
    'zba', 5, 7);
  AddPattern(Result,
    'fcvt.l.d', 'f,f,f',
    'i', 6, 2);
  AddPattern(Result,
    'fcvt.l.d', 'f,offset(x)',
    'm', 7, 3);
  AddPattern(Result,
    'fcvt.l.d', 'offset(x),f',
    'a', 1, 4);
  AddPattern(Result,
    'fcvt.l.d', 'vec,vec,vec',
    'f', 2, 5);
  AddPattern(Result,
    'fcvt.l.d', 'vec,offset(x)',
    'd', 3, 6);
  AddPattern(Result,
    'fcvt.l.d', 'offset(x),vec',
    'c', 4, 7);
  AddPattern(Result,
    'feq.d', 'x,x,x',
    'v', 5, 2);
  AddPattern(Result,
    'feq.d', 'x,x,imm12',
    'zbb', 6, 3);
  AddPattern(Result,
    'feq.d', 'x,offset(x)',
    'zba', 7, 4);
  AddPattern(Result,
    'feq.d', 'offset(x),x',
    'i', 1, 5);
  AddPattern(Result,
    'feq.d', 'label',
    'm', 2, 6);
  AddPattern(Result,
    'feq.d', 'x,label',
    'a', 3, 7);
  AddPattern(Result,
    'feq.d', 'f,f,f',
    'f', 4, 2);
  AddPattern(Result,
    'feq.d', 'f,offset(x)',
    'd', 5, 3);
  AddPattern(Result,
    'feq.d', 'offset(x),f',
    'c', 6, 4);
  AddPattern(Result,
    'feq.d', 'vec,vec,vec',
    'v', 7, 5);
  AddPattern(Result,
    'feq.d', 'vec,offset(x)',
    'zbb', 1, 6);
  AddPattern(Result,
    'feq.d', 'offset(x),vec',
    'zba', 2, 7);
  AddPattern(Result,
    'flt.d', 'x,x,x',
    'i', 3, 2);
  AddPattern(Result,
    'flt.d', 'x,x,imm12',
    'm', 4, 3);
  AddPattern(Result,
    'flt.d', 'x,offset(x)',
    'a', 5, 4);
  AddPattern(Result,
    'flt.d', 'offset(x),x',
    'f', 6, 5);
  AddPattern(Result,
    'flt.d', 'label',
    'd', 7, 6);
  AddPattern(Result,
    'flt.d', 'x,label',
    'c', 1, 7);
  AddPattern(Result,
    'flt.d', 'f,f,f',
    'v', 2, 2);
  AddPattern(Result,
    'flt.d', 'f,offset(x)',
    'zbb', 3, 3);
  AddPattern(Result,
    'flt.d', 'offset(x),f',
    'zba', 4, 4);
  AddPattern(Result,
    'flt.d', 'vec,vec,vec',
    'i', 5, 5);
  AddPattern(Result,
    'flt.d', 'vec,offset(x)',
    'm', 6, 6);
  AddPattern(Result,
    'flt.d', 'offset(x),vec',
    'a', 7, 7);
  AddPattern(Result,
    'fle.d', 'x,x,x',
    'f', 1, 2);
  AddPattern(Result,
    'fle.d', 'x,x,imm12',
    'd', 2, 3);
  AddPattern(Result,
    'fle.d', 'x,offset(x)',
    'c', 3, 4);
  AddPattern(Result,
    'fle.d', 'offset(x),x',
    'v', 4, 5);
  AddPattern(Result,
    'fle.d', 'label',
    'zbb', 5, 6);
  AddPattern(Result,
    'fle.d', 'x,label',
    'zba', 6, 7);
  AddPattern(Result,
    'fle.d', 'f,f,f',
    'i', 7, 2);
  AddPattern(Result,
    'fle.d', 'f,offset(x)',
    'm', 1, 3);
  AddPattern(Result,
    'fle.d', 'offset(x),f',
    'a', 2, 4);
  AddPattern(Result,
    'fle.d', 'vec,vec,vec',
    'f', 3, 5);
  AddPattern(Result,
    'fle.d', 'vec,offset(x)',
    'd', 4, 6);
  AddPattern(Result,
    'fle.d', 'offset(x),vec',
    'c', 5, 7);
  AddPattern(Result,
    'vadd.vv', 'x,x,x',
    'v', 6, 2);
  AddPattern(Result,
    'vadd.vv', 'x,x,imm12',
    'zbb', 7, 3);
  AddPattern(Result,
    'vadd.vv', 'x,offset(x)',
    'zba', 1, 4);
  AddPattern(Result,
    'vadd.vv', 'offset(x),x',
    'i', 2, 5);
  AddPattern(Result,
    'vadd.vv', 'label',
    'm', 3, 6);
  AddPattern(Result,
    'vadd.vv', 'x,label',
    'a', 4, 7);
  AddPattern(Result,
    'vadd.vv', 'f,f,f',
    'f', 5, 2);
  AddPattern(Result,
    'vadd.vv', 'f,offset(x)',
    'd', 6, 3);
  AddPattern(Result,
    'vadd.vv', 'offset(x),f',
    'c', 7, 4);
  AddPattern(Result,
    'vadd.vv', 'vec,vec,vec',
    'v', 1, 5);
  AddPattern(Result,
    'vadd.vv', 'vec,offset(x)',
    'zbb', 2, 6);
  AddPattern(Result,
    'vadd.vv', 'offset(x),vec',
    'zba', 3, 7);
  AddPattern(Result,
    'vsub.vv', 'x,x,x',
    'i', 4, 2);
  AddPattern(Result,
    'vsub.vv', 'x,x,imm12',
    'm', 5, 3);
  AddPattern(Result,
    'vsub.vv', 'x,offset(x)',
    'a', 6, 4);
  AddPattern(Result,
    'vsub.vv', 'offset(x),x',
    'f', 7, 5);
  AddPattern(Result,
    'vsub.vv', 'label',
    'd', 1, 6);
  AddPattern(Result,
    'vsub.vv', 'x,label',
    'c', 2, 7);
  AddPattern(Result,
    'vsub.vv', 'f,f,f',
    'v', 3, 2);
  AddPattern(Result,
    'vsub.vv', 'f,offset(x)',
    'zbb', 4, 3);
  AddPattern(Result,
    'vsub.vv', 'offset(x),f',
    'zba', 5, 4);
  AddPattern(Result,
    'vsub.vv', 'vec,vec,vec',
    'i', 6, 5);
  AddPattern(Result,
    'vsub.vv', 'vec,offset(x)',
    'm', 7, 6);
  AddPattern(Result,
    'vsub.vv', 'offset(x),vec',
    'a', 1, 7);
  AddPattern(Result,
    'vmul.vv', 'x,x,x',
    'f', 2, 2);
  AddPattern(Result,
    'vmul.vv', 'x,x,imm12',
    'd', 3, 3);
  AddPattern(Result,
    'vmul.vv', 'x,offset(x)',
    'c', 4, 4);
  AddPattern(Result,
    'vmul.vv', 'offset(x),x',
    'v', 5, 5);
  AddPattern(Result,
    'vmul.vv', 'label',
    'zbb', 6, 6);
  AddPattern(Result,
    'vmul.vv', 'x,label',
    'zba', 7, 7);
  AddPattern(Result,
    'vmul.vv', 'f,f,f',
    'i', 1, 2);
  AddPattern(Result,
    'vmul.vv', 'f,offset(x)',
    'm', 2, 3);
  AddPattern(Result,
    'vmul.vv', 'offset(x),f',
    'a', 3, 4);
  AddPattern(Result,
    'vmul.vv', 'vec,vec,vec',
    'f', 4, 5);
  AddPattern(Result,
    'vmul.vv', 'vec,offset(x)',
    'd', 5, 6);
  AddPattern(Result,
    'vmul.vv', 'offset(x),vec',
    'c', 6, 7);
  AddPattern(Result,
    'vle64.v', 'x,x,x',
    'v', 7, 2);
  AddPattern(Result,
    'vle64.v', 'x,x,imm12',
    'zbb', 1, 3);
  AddPattern(Result,
    'vle64.v', 'x,offset(x)',
    'zba', 2, 4);
  AddPattern(Result,
    'vle64.v', 'offset(x),x',
    'i', 3, 5);
  AddPattern(Result,
    'vle64.v', 'label',
    'm', 4, 6);
  AddPattern(Result,
    'vle64.v', 'x,label',
    'a', 5, 7);
  AddPattern(Result,
    'vle64.v', 'f,f,f',
    'f', 6, 2);
  AddPattern(Result,
    'vle64.v', 'f,offset(x)',
    'd', 7, 3);
  AddPattern(Result,
    'vle64.v', 'offset(x),f',
    'c', 1, 4);
  AddPattern(Result,
    'vle64.v', 'vec,vec,vec',
    'v', 2, 5);
  AddPattern(Result,
    'vle64.v', 'vec,offset(x)',
    'zbb', 3, 6);
  AddPattern(Result,
    'vle64.v', 'offset(x),vec',
    'zba', 4, 7);
  AddPattern(Result,
    'vse64.v', 'x,x,x',
    'i', 5, 2);
  AddPattern(Result,
    'vse64.v', 'x,x,imm12',
    'm', 6, 3);
  AddPattern(Result,
    'vse64.v', 'x,offset(x)',
    'a', 7, 4);
  AddPattern(Result,
    'vse64.v', 'offset(x),x',
    'f', 1, 5);
  AddPattern(Result,
    'vse64.v', 'label',
    'd', 2, 6);
  AddPattern(Result,
    'vse64.v', 'x,label',
    'c', 3, 7);
  AddPattern(Result,
    'vse64.v', 'f,f,f',
    'v', 4, 2);
  AddPattern(Result,
    'vse64.v', 'f,offset(x)',
    'zbb', 5, 3);
  AddPattern(Result,
    'vse64.v', 'offset(x),f',
    'zba', 6, 4);
  AddPattern(Result,
    'vse64.v', 'vec,vec,vec',
    'i', 7, 5);
  AddPattern(Result,
    'vse64.v', 'vec,offset(x)',
    'm', 1, 6);
  AddPattern(Result,
    'vse64.v', 'offset(x),vec',
    'a', 2, 7);
end;

function FindRISCV64Pattern(const ACatalog: TInstructionPatternArray;
  const AMnemonic, AForm: string; out APattern: TInstructionPattern): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if (ACatalog[I].Mnemonic = AMnemonic) and
      (ACatalog[I].OperandForm = AForm) then
    begin
      APattern := ACatalog[I];
      Exit(True);
    end;
  APattern.Mnemonic := '';
  APattern.OperandForm := '';
  APattern.RequiredFeature := '';
  APattern.EstimatedLatency := 0;
  APattern.EstimatedSize := 0;
  Result := False;
end;

function RISCV64PatternSummary(const ACatalog: TInstructionPatternArray): string;
var
  I, Scalar, Vector, Branch: LongInt;
begin
  Scalar := 0;
  Vector := 0;
  Branch := 0;
  for I := 0 to High(ACatalog) do
  begin
    if Pos('vec', ACatalog[I].OperandForm) > 0 then Inc(Vector)
    else Inc(Scalar);
    if Pos('label', ACatalog[I].OperandForm) > 0 then Inc(Branch);
  end;
  Result := Format('RISCV64: %d patterns (%d scalar, %d vector, %d branch)',
    [Length(ACatalog), Scalar, Vector, Branch]);
end;

end.
