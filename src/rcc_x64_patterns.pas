unit rcc_x64_patterns;

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

function BuildX64PatternCatalog: TInstructionPatternArray;
function FindX64Pattern(const ACatalog: TInstructionPatternArray;
  const AMnemonic, AForm: string; out APattern: TInstructionPattern): Boolean;
function X64PatternSummary(const ACatalog: TInstructionPatternArray): string;

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

function BuildX64PatternCatalog: TInstructionPatternArray;
begin
  Result := nil;
  AddPattern(Result,
    'mov', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'mov', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'mov', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'mov', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'mov', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'mov', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'mov', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'mov', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'mov', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'mov', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'mov', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'mov', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'lea', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'lea', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'lea', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'lea', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'lea', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'lea', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'lea', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'lea', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'lea', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'lea', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'lea', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'lea', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'add', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'add', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'add', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'add', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'add', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'add', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'add', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'add', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'add', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'add', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'add', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'add', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'sub', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'sub', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'sub', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'sub', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'sub', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'sub', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'sub', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'sub', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'sub', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'sub', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'sub', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'sub', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'imul', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'imul', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'imul', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'imul', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'imul', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'imul', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'imul', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'imul', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'imul', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'imul', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'imul', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'imul', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'mul', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'mul', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'mul', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'mul', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'mul', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'mul', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'mul', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'mul', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'mul', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'mul', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'mul', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'mul', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'idiv', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'idiv', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'idiv', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'idiv', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'idiv', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'idiv', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'idiv', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'idiv', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'idiv', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'idiv', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'idiv', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'idiv', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'div', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'div', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'div', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'div', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'div', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'div', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'div', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'div', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'div', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'div', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'div', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'div', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'and', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'and', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'and', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'and', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'and', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'and', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'and', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'and', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'and', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'and', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'and', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'and', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'or', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'or', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'or', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'or', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'or', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'or', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'or', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'or', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'or', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'or', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'or', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'or', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'xor', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'xor', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'xor', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'xor', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'xor', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'xor', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'xor', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'xor', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'xor', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'xor', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'xor', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'xor', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'not', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'not', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'not', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'not', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'not', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'not', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'not', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'not', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'not', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'not', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'not', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'not', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'neg', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'neg', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'neg', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'neg', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'neg', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'neg', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'neg', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'neg', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'neg', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'neg', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'neg', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'neg', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'shl', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'shl', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'shl', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'shl', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'shl', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'shl', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'shl', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'shl', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'shl', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'shl', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'shl', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'shl', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'shr', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'shr', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'shr', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'shr', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'shr', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'shr', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'shr', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'shr', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'shr', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'shr', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'shr', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'shr', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'sar', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'sar', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'sar', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'sar', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'sar', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'sar', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'sar', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'sar', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'sar', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'sar', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'sar', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'sar', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'rol', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'rol', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'rol', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'rol', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'rol', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'rol', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'rol', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'rol', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'rol', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'rol', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'rol', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'rol', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'ror', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'ror', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'ror', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'ror', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'ror', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'ror', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'ror', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'ror', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'ror', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'ror', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'ror', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'ror', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'cmp', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'cmp', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'cmp', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'cmp', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'cmp', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'cmp', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'cmp', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'cmp', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'cmp', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'cmp', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'cmp', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'cmp', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'test', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'test', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'test', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'test', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'test', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'test', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'test', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'test', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'test', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'test', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'test', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'test', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'cmovz', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'cmovz', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'cmovz', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'cmovz', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'cmovz', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'cmovz', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'cmovz', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'cmovz', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'cmovz', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'cmovz', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'cmovz', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'cmovz', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'cmovnz', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'cmovnz', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'cmovnz', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'cmovnz', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'cmovnz', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'cmovnz', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'cmovnz', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'cmovnz', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'cmovnz', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'cmovnz', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'cmovnz', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'cmovnz', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'cmova', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'cmova', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'cmova', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'cmova', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'cmova', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'cmova', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'cmova', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'cmova', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'cmova', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'cmova', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'cmova', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'cmova', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'cmovb', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'cmovb', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'cmovb', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'cmovb', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'cmovb', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'cmovb', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'cmovb', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'cmovb', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'cmovb', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'cmovb', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'cmovb', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'cmovb', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'setz', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'setz', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'setz', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'setz', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'setz', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'setz', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'setz', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'setz', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'setz', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'setz', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'setz', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'setz', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'setnz', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'setnz', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'setnz', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'setnz', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'setnz', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'setnz', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'setnz', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'setnz', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'setnz', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'setnz', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'setnz', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'setnz', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'seta', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'seta', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'seta', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'seta', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'seta', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'seta', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'seta', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'seta', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'seta', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'seta', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'seta', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'seta', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'setb', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'setb', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'setb', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'setb', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'setb', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'setb', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'setb', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'setb', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'setb', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'setb', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'setb', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'setb', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'push', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'push', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'push', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'push', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'push', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'push', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'push', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'push', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'push', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'push', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'push', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'push', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'pop', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'pop', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'pop', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'pop', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'pop', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'pop', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'pop', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'pop', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'pop', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'pop', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'pop', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'pop', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'call', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'call', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'call', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'call', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'call', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'call', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'call', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'call', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'call', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'call', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'call', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'call', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'jmp', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'jmp', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'jmp', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'jmp', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'jmp', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'jmp', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'jmp', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'jmp', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'jmp', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'jmp', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'jmp', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'jmp', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'je', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'je', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'je', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'je', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'je', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'je', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'je', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'je', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'je', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'je', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'je', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'je', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'jne', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'jne', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'jne', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'jne', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'jne', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'jne', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'jne', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'jne', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'jne', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'jne', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'jne', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'jne', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'ja', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'ja', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'ja', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'ja', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'ja', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'ja', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'ja', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'ja', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'ja', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'ja', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'ja', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'ja', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'jb', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'jb', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'jb', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'jb', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'jb', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'jb', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'jb', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'jb', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'jb', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'jb', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'jb', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'jb', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'jge', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'jge', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'jge', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'jge', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'jge', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'jge', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'jge', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'jge', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'jge', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'jge', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'jge', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'jge', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'jl', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'jl', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'jl', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'jl', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'jl', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'jl', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'jl', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'jl', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'jl', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'jl', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'jl', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'jl', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'movzx', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'movzx', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'movzx', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'movzx', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'movzx', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'movzx', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'movzx', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'movzx', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'movzx', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'movzx', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'movzx', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'movzx', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'movsx', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'movsx', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'movsx', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'movsx', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'movsx', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'movsx', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'movsx', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'movsx', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'movsx', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'movsx', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'movsx', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'movsx', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'movsxd', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'movsxd', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'movsxd', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'movsxd', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'movsxd', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'movsxd', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'movsxd', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'movsxd', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'movsxd', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'movsxd', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'movsxd', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'movsxd', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'bsf', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'bsf', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'bsf', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'bsf', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'bsf', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'bsf', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'bsf', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'bsf', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'bsf', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'bsf', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'bsf', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'bsf', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'bsr', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'bsr', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'bsr', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'bsr', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'bsr', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'bsr', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'bsr', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'bsr', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'bsr', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'bsr', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'bsr', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'bsr', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'popcnt', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'popcnt', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'popcnt', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'popcnt', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'popcnt', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'popcnt', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'popcnt', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'popcnt', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'popcnt', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'popcnt', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'popcnt', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'popcnt', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'lzcnt', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'lzcnt', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'lzcnt', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'lzcnt', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'lzcnt', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'lzcnt', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'lzcnt', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'lzcnt', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'lzcnt', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'lzcnt', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'lzcnt', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'lzcnt', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'tzcnt', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'tzcnt', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'tzcnt', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'tzcnt', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'tzcnt', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'tzcnt', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'tzcnt', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'tzcnt', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'tzcnt', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'tzcnt', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'tzcnt', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'tzcnt', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'crc32', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'crc32', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'crc32', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'crc32', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'crc32', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'crc32', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'crc32', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'crc32', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'crc32', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'crc32', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'crc32', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'crc32', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'xchg', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'xchg', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'xchg', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'xchg', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'xchg', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'xchg', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'xchg', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'xchg', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'xchg', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'xchg', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'xchg', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'xchg', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'cmpxchg', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'cmpxchg', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'cmpxchg', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'cmpxchg', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'cmpxchg', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'cmpxchg', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'cmpxchg', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'cmpxchg', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'cmpxchg', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'cmpxchg', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'cmpxchg', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'cmpxchg', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'lock_add', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'lock_add', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'lock_add', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'lock_add', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'lock_add', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'lock_add', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'lock_add', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'lock_add', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'lock_add', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'lock_add', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'lock_add', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'lock_add', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'lock_xadd', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'lock_xadd', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'lock_xadd', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'lock_xadd', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'lock_xadd', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'lock_xadd', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'lock_xadd', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'lock_xadd', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'lock_xadd', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'lock_xadd', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'lock_xadd', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'lock_xadd', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'movss', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'movss', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'movss', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'movss', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'movss', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'movss', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'movss', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'movss', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'movss', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'movss', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'movss', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'movss', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'movsd', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'movsd', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'movsd', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'movsd', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'movsd', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'movsd', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'movsd', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'movsd', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'movsd', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'movsd', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'movsd', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'movsd', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'addss', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'addss', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'addss', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'addss', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'addss', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'addss', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'addss', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'addss', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'addss', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'addss', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'addss', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'addss', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'addsd', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'addsd', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'addsd', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'addsd', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'addsd', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'addsd', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'addsd', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'addsd', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'addsd', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'addsd', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'addsd', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'addsd', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'subss', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'subss', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'subss', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'subss', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'subss', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'subss', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'subss', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'subss', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'subss', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'subss', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'subss', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'subss', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'subsd', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'subsd', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'subsd', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'subsd', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'subsd', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'subsd', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'subsd', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'subsd', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'subsd', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'subsd', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'subsd', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'subsd', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'mulss', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'mulss', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'mulss', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'mulss', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'mulss', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'mulss', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'mulss', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'mulss', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'mulss', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'mulss', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'mulss', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'mulss', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'mulsd', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'mulsd', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'mulsd', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'mulsd', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'mulsd', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'mulsd', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'mulsd', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'mulsd', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'mulsd', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'mulsd', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'mulsd', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'mulsd', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'divss', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'divss', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'divss', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'divss', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'divss', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'divss', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'divss', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'divss', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'divss', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'divss', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'divss', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'divss', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'divsd', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'divsd', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'divsd', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'divsd', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'divsd', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'divsd', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'divsd', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'divsd', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'divsd', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'divsd', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'divsd', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'divsd', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'ucomiss', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'ucomiss', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'ucomiss', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'ucomiss', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'ucomiss', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'ucomiss', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'ucomiss', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'ucomiss', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'ucomiss', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'ucomiss', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'ucomiss', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'ucomiss', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'ucomisd', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'ucomisd', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'ucomisd', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'ucomisd', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'ucomisd', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'ucomisd', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'ucomisd', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'ucomisd', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'ucomisd', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'ucomisd', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'ucomisd', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'ucomisd', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'cvtsi2ss', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'cvtsi2ss', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'cvtsi2ss', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'cvtsi2ss', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'cvtsi2ss', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'cvtsi2ss', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'cvtsi2ss', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'cvtsi2ss', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'cvtsi2ss', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'cvtsi2ss', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'cvtsi2ss', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'cvtsi2ss', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'cvtsi2sd', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'cvtsi2sd', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'cvtsi2sd', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'cvtsi2sd', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'cvtsi2sd', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'cvtsi2sd', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'cvtsi2sd', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'cvtsi2sd', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'cvtsi2sd', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'cvtsi2sd', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'cvtsi2sd', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'cvtsi2sd', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'cvttss2si', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'cvttss2si', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'cvttss2si', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'cvttss2si', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'cvttss2si', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'cvttss2si', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'cvttss2si', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'cvttss2si', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'cvttss2si', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'cvttss2si', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'cvttss2si', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'cvttss2si', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'cvttsd2si', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'cvttsd2si', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'cvttsd2si', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'cvttsd2si', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'cvttsd2si', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'cvttsd2si', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'cvttsd2si', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'cvttsd2si', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'cvttsd2si', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'cvttsd2si', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'cvttsd2si', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'cvttsd2si', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'movaps', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'movaps', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'movaps', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'movaps', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'movaps', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'movaps', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'movaps', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'movaps', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'movaps', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'movaps', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'movaps', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'movaps', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'movapd', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'movapd', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'movapd', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'movapd', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'movapd', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'movapd', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'movapd', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'movapd', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'movapd', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'movapd', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'movapd', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'movapd', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'movups', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'movups', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'movups', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'movups', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'movups', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'movups', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'movups', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'movups', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'movups', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'movups', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'movups', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'movups', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'movupd', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'movupd', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'movupd', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'movupd', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'movupd', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'movupd', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'movupd', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'movupd', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'movupd', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'movupd', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'movupd', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'movupd', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'paddb', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'paddb', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'paddb', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'paddb', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'paddb', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'paddb', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'paddb', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'paddb', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'paddb', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'paddb', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'paddb', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'paddb', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'paddw', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'paddw', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'paddw', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'paddw', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'paddw', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'paddw', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'paddw', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'paddw', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'paddw', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'paddw', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'paddw', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'paddw', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'paddd', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'paddd', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'paddd', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'paddd', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'paddd', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'paddd', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'paddd', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'paddd', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'paddd', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'paddd', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'paddd', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'paddd', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'paddq', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'paddq', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'paddq', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'paddq', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'paddq', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'paddq', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'paddq', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'paddq', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'paddq', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'paddq', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'paddq', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'paddq', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'psubb', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'psubb', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'psubb', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'psubb', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'psubb', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'psubb', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'psubb', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'psubb', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'psubb', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'psubb', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'psubb', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'psubb', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'psubw', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'psubw', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'psubw', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'psubw', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'psubw', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'psubw', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'psubw', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'psubw', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'psubw', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'psubw', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'psubw', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'psubw', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'psubd', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'psubd', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'psubd', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'psubd', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'psubd', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'psubd', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'psubd', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'psubd', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'psubd', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'psubd', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'psubd', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'psubd', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'psubq', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'psubq', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'psubq', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'psubq', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'psubq', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'psubq', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'psubq', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'psubq', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'psubq', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'psubq', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'psubq', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'psubq', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'pmullw', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'pmullw', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'pmullw', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'pmullw', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'pmullw', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'pmullw', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'pmullw', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'pmullw', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'pmullw', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'pmullw', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'pmullw', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'pmullw', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'pmulld', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'pmulld', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'pmulld', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'pmulld', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'pmulld', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'pmulld', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'pmulld', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'pmulld', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'pmulld', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'pmulld', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'pmulld', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'pmulld', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'pand', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'pand', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'pand', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'pand', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'pand', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'pand', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'pand', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'pand', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'pand', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'pand', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'pand', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'pand', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'por', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'por', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'por', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'por', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'por', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'por', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'por', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'por', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'por', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'por', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'por', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'por', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'pxor', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'pxor', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'pxor', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'pxor', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'pxor', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'pxor', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'pxor', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'pxor', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'pxor', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'pxor', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'pxor', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'pxor', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'vaddps', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'vaddps', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'vaddps', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'vaddps', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'vaddps', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'vaddps', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'vaddps', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'vaddps', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'vaddps', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'vaddps', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'vaddps', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'vaddps', 'vec256,vec256',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'vaddpd', 'r64,r64',
    'avx', 6, 2);
  AddPattern(Result,
    'vaddpd', 'r64,imm32',
    'avx2', 7, 3);
  AddPattern(Result,
    'vaddpd', 'r64,[mem]',
    'base', 1, 4);
  AddPattern(Result,
    'vaddpd', '[mem],r64',
    'sse2', 2, 5);
  AddPattern(Result,
    'vaddpd', 'r32,r32',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'vaddpd', 'r32,imm32',
    'popcnt', 4, 7);
  AddPattern(Result,
    'vaddpd', 'xmm,xmm',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'vaddpd', 'xmm,[mem]',
    'avx', 6, 3);
  AddPattern(Result,
    'vaddpd', '[mem],xmm',
    'avx2', 7, 4);
  AddPattern(Result,
    'vaddpd', 'label',
    'base', 1, 5);
  AddPattern(Result,
    'vaddpd', 'vec128,vec128',
    'sse2', 2, 6);
  AddPattern(Result,
    'vaddpd', 'vec256,vec256',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'vsubps', 'r64,r64',
    'popcnt', 4, 2);
  AddPattern(Result,
    'vsubps', 'r64,imm32',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'vsubps', 'r64,[mem]',
    'avx', 6, 4);
  AddPattern(Result,
    'vsubps', '[mem],r64',
    'avx2', 7, 5);
  AddPattern(Result,
    'vsubps', 'r32,r32',
    'base', 1, 6);
  AddPattern(Result,
    'vsubps', 'r32,imm32',
    'sse2', 2, 7);
  AddPattern(Result,
    'vsubps', 'xmm,xmm',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'vsubps', 'xmm,[mem]',
    'popcnt', 4, 3);
  AddPattern(Result,
    'vsubps', '[mem],xmm',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'vsubps', 'label',
    'avx', 6, 5);
  AddPattern(Result,
    'vsubps', 'vec128,vec128',
    'avx2', 7, 6);
  AddPattern(Result,
    'vsubps', 'vec256,vec256',
    'base', 1, 7);
  AddPattern(Result,
    'vsubpd', 'r64,r64',
    'sse2', 2, 2);
  AddPattern(Result,
    'vsubpd', 'r64,imm32',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'vsubpd', 'r64,[mem]',
    'popcnt', 4, 4);
  AddPattern(Result,
    'vsubpd', '[mem],r64',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'vsubpd', 'r32,r32',
    'avx', 6, 6);
  AddPattern(Result,
    'vsubpd', 'r32,imm32',
    'avx2', 7, 7);
  AddPattern(Result,
    'vsubpd', 'xmm,xmm',
    'base', 1, 2);
  AddPattern(Result,
    'vsubpd', 'xmm,[mem]',
    'sse2', 2, 3);
  AddPattern(Result,
    'vsubpd', '[mem],xmm',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'vsubpd', 'label',
    'popcnt', 4, 5);
  AddPattern(Result,
    'vsubpd', 'vec128,vec128',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'vsubpd', 'vec256,vec256',
    'avx', 6, 7);
  AddPattern(Result,
    'vmulps', 'r64,r64',
    'avx2', 7, 2);
  AddPattern(Result,
    'vmulps', 'r64,imm32',
    'base', 1, 3);
  AddPattern(Result,
    'vmulps', 'r64,[mem]',
    'sse2', 2, 4);
  AddPattern(Result,
    'vmulps', '[mem],r64',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'vmulps', 'r32,r32',
    'popcnt', 4, 6);
  AddPattern(Result,
    'vmulps', 'r32,imm32',
    'lzcnt', 5, 7);
  AddPattern(Result,
    'vmulps', 'xmm,xmm',
    'avx', 6, 2);
  AddPattern(Result,
    'vmulps', 'xmm,[mem]',
    'avx2', 7, 3);
  AddPattern(Result,
    'vmulps', '[mem],xmm',
    'base', 1, 4);
  AddPattern(Result,
    'vmulps', 'label',
    'sse2', 2, 5);
  AddPattern(Result,
    'vmulps', 'vec128,vec128',
    'sse4.2', 3, 6);
  AddPattern(Result,
    'vmulps', 'vec256,vec256',
    'popcnt', 4, 7);
  AddPattern(Result,
    'vmulpd', 'r64,r64',
    'lzcnt', 5, 2);
  AddPattern(Result,
    'vmulpd', 'r64,imm32',
    'avx', 6, 3);
  AddPattern(Result,
    'vmulpd', 'r64,[mem]',
    'avx2', 7, 4);
  AddPattern(Result,
    'vmulpd', '[mem],r64',
    'base', 1, 5);
  AddPattern(Result,
    'vmulpd', 'r32,r32',
    'sse2', 2, 6);
  AddPattern(Result,
    'vmulpd', 'r32,imm32',
    'sse4.2', 3, 7);
  AddPattern(Result,
    'vmulpd', 'xmm,xmm',
    'popcnt', 4, 2);
  AddPattern(Result,
    'vmulpd', 'xmm,[mem]',
    'lzcnt', 5, 3);
  AddPattern(Result,
    'vmulpd', '[mem],xmm',
    'avx', 6, 4);
  AddPattern(Result,
    'vmulpd', 'label',
    'avx2', 7, 5);
  AddPattern(Result,
    'vmulpd', 'vec128,vec128',
    'base', 1, 6);
  AddPattern(Result,
    'vmulpd', 'vec256,vec256',
    'sse2', 2, 7);
  AddPattern(Result,
    'vdivps', 'r64,r64',
    'sse4.2', 3, 2);
  AddPattern(Result,
    'vdivps', 'r64,imm32',
    'popcnt', 4, 3);
  AddPattern(Result,
    'vdivps', 'r64,[mem]',
    'lzcnt', 5, 4);
  AddPattern(Result,
    'vdivps', '[mem],r64',
    'avx', 6, 5);
  AddPattern(Result,
    'vdivps', 'r32,r32',
    'avx2', 7, 6);
  AddPattern(Result,
    'vdivps', 'r32,imm32',
    'base', 1, 7);
  AddPattern(Result,
    'vdivps', 'xmm,xmm',
    'sse2', 2, 2);
  AddPattern(Result,
    'vdivps', 'xmm,[mem]',
    'sse4.2', 3, 3);
  AddPattern(Result,
    'vdivps', '[mem],xmm',
    'popcnt', 4, 4);
  AddPattern(Result,
    'vdivps', 'label',
    'lzcnt', 5, 5);
  AddPattern(Result,
    'vdivps', 'vec128,vec128',
    'avx', 6, 6);
  AddPattern(Result,
    'vdivps', 'vec256,vec256',
    'avx2', 7, 7);
  AddPattern(Result,
    'vdivpd', 'r64,r64',
    'base', 1, 2);
  AddPattern(Result,
    'vdivpd', 'r64,imm32',
    'sse2', 2, 3);
  AddPattern(Result,
    'vdivpd', 'r64,[mem]',
    'sse4.2', 3, 4);
  AddPattern(Result,
    'vdivpd', '[mem],r64',
    'popcnt', 4, 5);
  AddPattern(Result,
    'vdivpd', 'r32,r32',
    'lzcnt', 5, 6);
  AddPattern(Result,
    'vdivpd', 'r32,imm32',
    'avx', 6, 7);
  AddPattern(Result,
    'vdivpd', 'xmm,xmm',
    'avx2', 7, 2);
  AddPattern(Result,
    'vdivpd', 'xmm,[mem]',
    'base', 1, 3);
  AddPattern(Result,
    'vdivpd', '[mem],xmm',
    'sse2', 2, 4);
  AddPattern(Result,
    'vdivpd', 'label',
    'sse4.2', 3, 5);
  AddPattern(Result,
    'vdivpd', 'vec128,vec128',
    'popcnt', 4, 6);
  AddPattern(Result,
    'vdivpd', 'vec256,vec256',
    'lzcnt', 5, 7);
end;

function FindX64Pattern(const ACatalog: TInstructionPatternArray;
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

function X64PatternSummary(const ACatalog: TInstructionPatternArray): string;
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
  Result := Format('X64: %d patterns (%d scalar, %d vector, %d branch)',
    [Length(ACatalog), Scalar, Vector, Branch]);
end;

end.
