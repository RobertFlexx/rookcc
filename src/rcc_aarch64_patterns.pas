unit rcc_aarch64_patterns;

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

function BuildAArch64PatternCatalog: TInstructionPatternArray;
function FindAArch64Pattern(const ACatalog: TInstructionPatternArray;
  const AMnemonic, AForm: string; out APattern: TInstructionPattern): Boolean;
function AArch64PatternSummary(const ACatalog: TInstructionPatternArray): string;

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

function BuildAArch64PatternCatalog: TInstructionPatternArray;
begin
  Result := nil;
  AddPattern(Result,
    'add', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'add', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'add', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'add', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'add', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'add', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'add', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'add', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'add', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'add', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'add', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'add', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'adds', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'adds', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'adds', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'adds', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'adds', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'adds', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'adds', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'adds', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'adds', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'adds', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'adds', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'adds', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'sub', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'sub', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'sub', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'sub', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'sub', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'sub', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'sub', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'sub', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'sub', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'sub', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'sub', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'sub', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'subs', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'subs', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'subs', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'subs', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'subs', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'subs', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'subs', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'subs', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'subs', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'subs', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'subs', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'subs', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'mul', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'mul', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'mul', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'mul', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'mul', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'mul', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'mul', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'mul', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'mul', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'mul', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'mul', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'mul', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'madd', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'madd', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'madd', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'madd', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'madd', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'madd', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'madd', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'madd', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'madd', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'madd', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'madd', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'madd', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'msub', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'msub', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'msub', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'msub', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'msub', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'msub', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'msub', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'msub', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'msub', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'msub', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'msub', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'msub', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'sdiv', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'sdiv', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'sdiv', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'sdiv', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'sdiv', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'sdiv', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'sdiv', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'sdiv', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'sdiv', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'sdiv', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'sdiv', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'sdiv', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'udiv', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'udiv', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'udiv', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'udiv', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'udiv', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'udiv', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'udiv', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'udiv', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'udiv', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'udiv', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'udiv', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'udiv', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'and', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'and', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'and', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'and', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'and', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'and', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'and', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'and', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'and', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'and', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'and', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'and', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'ands', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'ands', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'ands', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'ands', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'ands', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'ands', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'ands', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'ands', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'ands', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'ands', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'ands', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'ands', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'orr', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'orr', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'orr', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'orr', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'orr', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'orr', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'orr', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'orr', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'orr', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'orr', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'orr', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'orr', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'eor', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'eor', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'eor', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'eor', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'eor', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'eor', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'eor', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'eor', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'eor', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'eor', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'eor', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'eor', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'bic', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'bic', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'bic', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'bic', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'bic', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'bic', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'bic', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'bic', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'bic', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'bic', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'bic', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'bic', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'lsl', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'lsl', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'lsl', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'lsl', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'lsl', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'lsl', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'lsl', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'lsl', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'lsl', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'lsl', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'lsl', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'lsl', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'lsr', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'lsr', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'lsr', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'lsr', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'lsr', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'lsr', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'lsr', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'lsr', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'lsr', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'lsr', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'lsr', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'lsr', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'asr', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'asr', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'asr', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'asr', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'asr', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'asr', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'asr', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'asr', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'asr', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'asr', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'asr', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'asr', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'ror', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'ror', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'ror', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'ror', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'ror', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'ror', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'ror', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'ror', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'ror', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'ror', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'ror', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'ror', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'cmp', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'cmp', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'cmp', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'cmp', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'cmp', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'cmp', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'cmp', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'cmp', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'cmp', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'cmp', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'cmp', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'cmp', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'cmn', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'cmn', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'cmn', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'cmn', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'cmn', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'cmn', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'cmn', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'cmn', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'cmn', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'cmn', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'cmn', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'cmn', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'tst', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'tst', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'tst', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'tst', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'tst', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'tst', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'tst', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'tst', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'tst', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'tst', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'tst', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'tst', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'mov', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'mov', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'mov', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'mov', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'mov', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'mov', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'mov', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'mov', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'mov', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'mov', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'mov', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'mov', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'movz', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'movz', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'movz', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'movz', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'movz', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'movz', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'movz', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'movz', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'movz', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'movz', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'movz', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'movz', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'movk', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'movk', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'movk', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'movk', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'movk', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'movk', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'movk', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'movk', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'movk', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'movk', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'movk', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'movk', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'adr', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'adr', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'adr', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'adr', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'adr', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'adr', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'adr', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'adr', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'adr', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'adr', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'adr', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'adr', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'adrp', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'adrp', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'adrp', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'adrp', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'adrp', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'adrp', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'adrp', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'adrp', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'adrp', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'adrp', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'adrp', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'adrp', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'ldr', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'ldr', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'ldr', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'ldr', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'ldr', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'ldr', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'ldr', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'ldr', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'ldr', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'ldr', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'ldr', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'ldr', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'str', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'str', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'str', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'str', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'str', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'str', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'str', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'str', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'str', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'str', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'str', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'str', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'ldp', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'ldp', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'ldp', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'ldp', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'ldp', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'ldp', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'ldp', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'ldp', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'ldp', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'ldp', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'ldp', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'ldp', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'stp', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'stp', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'stp', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'stp', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'stp', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'stp', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'stp', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'stp', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'stp', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'stp', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'stp', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'stp', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'ldrb', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'ldrb', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'ldrb', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'ldrb', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'ldrb', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'ldrb', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'ldrb', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'ldrb', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'ldrb', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'ldrb', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'ldrb', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'ldrb', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'strb', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'strb', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'strb', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'strb', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'strb', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'strb', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'strb', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'strb', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'strb', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'strb', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'strb', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'strb', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'ldrh', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'ldrh', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'ldrh', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'ldrh', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'ldrh', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'ldrh', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'ldrh', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'ldrh', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'ldrh', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'ldrh', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'ldrh', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'ldrh', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'strh', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'strh', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'strh', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'strh', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'strh', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'strh', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'strh', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'strh', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'strh', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'strh', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'strh', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'strh', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'ldrsw', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'ldrsw', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'ldrsw', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'ldrsw', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'ldrsw', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'ldrsw', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'ldrsw', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'ldrsw', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'ldrsw', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'ldrsw', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'ldrsw', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'ldrsw', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'b', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'b', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'b', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'b', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'b', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'b', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'b', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'b', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'b', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'b', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'b', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'b', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'bl', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'bl', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'bl', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'bl', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'bl', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'bl', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'bl', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'bl', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'bl', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'bl', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'bl', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'bl', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'br', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'br', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'br', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'br', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'br', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'br', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'br', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'br', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'br', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'br', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'br', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'br', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'blr', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'blr', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'blr', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'blr', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'blr', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'blr', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'blr', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'blr', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'blr', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'blr', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'blr', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'blr', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'ret', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'ret', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'ret', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'ret', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'ret', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'ret', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'ret', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'ret', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'ret', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'ret', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'ret', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'ret', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'cbz', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'cbz', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'cbz', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'cbz', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'cbz', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'cbz', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'cbz', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'cbz', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'cbz', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'cbz', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'cbz', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'cbz', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'cbnz', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'cbnz', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'cbnz', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'cbnz', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'cbnz', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'cbnz', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'cbnz', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'cbnz', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'cbnz', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'cbnz', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'cbnz', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'cbnz', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'tbz', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'tbz', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'tbz', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'tbz', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'tbz', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'tbz', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'tbz', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'tbz', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'tbz', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'tbz', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'tbz', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'tbz', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'tbnz', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'tbnz', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'tbnz', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'tbnz', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'tbnz', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'tbnz', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'tbnz', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'tbnz', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'tbnz', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'tbnz', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'tbnz', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'tbnz', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'b.eq', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'b.eq', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'b.eq', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'b.eq', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'b.eq', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'b.eq', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'b.eq', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'b.eq', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'b.eq', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'b.eq', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'b.eq', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'b.eq', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'b.ne', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'b.ne', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'b.ne', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'b.ne', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'b.ne', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'b.ne', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'b.ne', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'b.ne', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'b.ne', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'b.ne', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'b.ne', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'b.ne', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'b.lt', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'b.lt', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'b.lt', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'b.lt', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'b.lt', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'b.lt', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'b.lt', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'b.lt', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'b.lt', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'b.lt', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'b.lt', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'b.lt', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'b.ge', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'b.ge', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'b.ge', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'b.ge', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'b.ge', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'b.ge', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'b.ge', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'b.ge', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'b.ge', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'b.ge', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'b.ge', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'b.ge', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'b.lo', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'b.lo', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'b.lo', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'b.lo', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'b.lo', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'b.lo', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'b.lo', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'b.lo', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'b.lo', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'b.lo', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'b.lo', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'b.lo', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'b.hs', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'b.hs', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'b.hs', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'b.hs', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'b.hs', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'b.hs', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'b.hs', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'b.hs', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'b.hs', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'b.hs', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'b.hs', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'b.hs', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'csel', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'csel', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'csel', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'csel', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'csel', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'csel', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'csel', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'csel', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'csel', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'csel', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'csel', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'csel', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'csinc', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'csinc', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'csinc', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'csinc', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'csinc', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'csinc', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'csinc', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'csinc', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'csinc', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'csinc', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'csinc', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'csinc', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'csinv', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'csinv', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'csinv', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'csinv', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'csinv', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'csinv', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'csinv', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'csinv', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'csinv', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'csinv', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'csinv', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'csinv', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'csneg', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'csneg', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'csneg', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'csneg', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'csneg', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'csneg', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'csneg', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'csneg', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'csneg', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'csneg', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'csneg', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'csneg', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'fmov', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'fmov', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'fmov', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'fmov', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'fmov', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'fmov', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'fmov', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'fmov', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'fmov', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'fmov', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'fmov', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'fmov', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'fadd', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'fadd', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'fadd', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'fadd', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'fadd', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'fadd', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'fadd', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'fadd', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'fadd', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'fadd', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'fadd', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'fadd', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'fsub', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'fsub', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'fsub', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'fsub', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'fsub', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'fsub', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'fsub', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'fsub', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'fsub', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'fsub', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'fsub', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'fsub', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'fmul', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'fmul', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'fmul', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'fmul', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'fmul', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'fmul', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'fmul', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'fmul', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'fmul', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'fmul', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'fmul', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'fmul', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'fdiv', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'fdiv', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'fdiv', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'fdiv', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'fdiv', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'fdiv', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'fdiv', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'fdiv', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'fdiv', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'fdiv', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'fdiv', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'fdiv', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'fcmp', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'fcmp', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'fcmp', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'fcmp', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'fcmp', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'fcmp', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'fcmp', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'fcmp', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'fcmp', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'fcmp', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'fcmp', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'fcmp', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'fcsel', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'fcsel', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'fcsel', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'fcsel', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'fcsel', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'fcsel', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'fcsel', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'fcsel', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'fcsel', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'fcsel', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'fcsel', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'fcsel', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'scvtf', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'scvtf', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'scvtf', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'scvtf', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'scvtf', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'scvtf', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'scvtf', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'scvtf', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'scvtf', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'scvtf', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'scvtf', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'scvtf', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'ucvtf', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'ucvtf', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'ucvtf', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'ucvtf', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'ucvtf', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'ucvtf', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'ucvtf', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'ucvtf', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'ucvtf', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'ucvtf', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'ucvtf', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'ucvtf', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'fcvtzs', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'fcvtzs', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'fcvtzs', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'fcvtzs', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'fcvtzs', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'fcvtzs', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'fcvtzs', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'fcvtzs', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'fcvtzs', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'fcvtzs', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'fcvtzs', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'fcvtzs', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'fcvtzu', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'fcvtzu', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'fcvtzu', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'fcvtzu', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'fcvtzu', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'fcvtzu', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'fcvtzu', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'fcvtzu', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'fcvtzu', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'fcvtzu', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'fcvtzu', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'fcvtzu', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'ldar', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'ldar', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'ldar', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'ldar', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'ldar', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'ldar', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'ldar', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'ldar', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'ldar', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'ldar', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'ldar', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'ldar', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'stlr', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'stlr', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'stlr', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'stlr', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'stlr', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'stlr', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'stlr', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'stlr', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'stlr', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'stlr', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'stlr', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'stlr', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'ldxr', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'ldxr', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'ldxr', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'ldxr', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'ldxr', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'ldxr', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'ldxr', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'ldxr', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'ldxr', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'ldxr', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'ldxr', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'ldxr', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'stxr', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'stxr', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'stxr', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'stxr', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'stxr', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'stxr', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'stxr', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'stxr', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'stxr', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'stxr', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'stxr', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'stxr', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'dmb', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'dmb', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'dmb', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'dmb', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'dmb', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'dmb', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'dmb', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'dmb', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'dmb', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'dmb', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'dmb', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'dmb', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'dsb', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'dsb', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'dsb', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'dsb', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'dsb', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'dsb', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'dsb', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'dsb', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'dsb', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'dsb', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'dsb', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'dsb', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'isb', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'isb', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'isb', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'isb', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'isb', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'isb', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'isb', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'isb', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'isb', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'isb', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'isb', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'isb', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'addv', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'addv', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'addv', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'addv', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'addv', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'addv', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'addv', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'addv', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'addv', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'addv', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'addv', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'addv', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'cnt', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'cnt', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'cnt', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'cnt', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'cnt', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'cnt', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'cnt', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'cnt', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'cnt', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'cnt', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'cnt', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'cnt', 'x,x,label',
    'crypto', 6, 7);
  AddPattern(Result,
    'rev64', 'x,x,x',
    'base', 7, 2);
  AddPattern(Result,
    'rev64', 'x,x,imm12',
    'fp', 1, 3);
  AddPattern(Result,
    'rev64', 'x,[x]',
    'asimd', 2, 4);
  AddPattern(Result,
    'rev64', '[x],x',
    'lse', 3, 5);
  AddPattern(Result,
    'rev64', 'w,w,w',
    'crc', 4, 6);
  AddPattern(Result,
    'rev64', 'w,w,imm12',
    'crypto', 5, 7);
  AddPattern(Result,
    'rev64', 'd,d,d',
    'base', 6, 2);
  AddPattern(Result,
    'rev64', 's,s,s',
    'fp', 7, 3);
  AddPattern(Result,
    'rev64', 'v128,v128,v128',
    'asimd', 1, 4);
  AddPattern(Result,
    'rev64', 'label',
    'lse', 2, 5);
  AddPattern(Result,
    'rev64', 'x,label',
    'crc', 3, 6);
  AddPattern(Result,
    'rev64', 'x,x,label',
    'crypto', 4, 7);
  AddPattern(Result,
    'ext', 'x,x,x',
    'base', 5, 2);
  AddPattern(Result,
    'ext', 'x,x,imm12',
    'fp', 6, 3);
  AddPattern(Result,
    'ext', 'x,[x]',
    'asimd', 7, 4);
  AddPattern(Result,
    'ext', '[x],x',
    'lse', 1, 5);
  AddPattern(Result,
    'ext', 'w,w,w',
    'crc', 2, 6);
  AddPattern(Result,
    'ext', 'w,w,imm12',
    'crypto', 3, 7);
  AddPattern(Result,
    'ext', 'd,d,d',
    'base', 4, 2);
  AddPattern(Result,
    'ext', 's,s,s',
    'fp', 5, 3);
  AddPattern(Result,
    'ext', 'v128,v128,v128',
    'asimd', 6, 4);
  AddPattern(Result,
    'ext', 'label',
    'lse', 7, 5);
  AddPattern(Result,
    'ext', 'x,label',
    'crc', 1, 6);
  AddPattern(Result,
    'ext', 'x,x,label',
    'crypto', 2, 7);
  AddPattern(Result,
    'tbl', 'x,x,x',
    'base', 3, 2);
  AddPattern(Result,
    'tbl', 'x,x,imm12',
    'fp', 4, 3);
  AddPattern(Result,
    'tbl', 'x,[x]',
    'asimd', 5, 4);
  AddPattern(Result,
    'tbl', '[x],x',
    'lse', 6, 5);
  AddPattern(Result,
    'tbl', 'w,w,w',
    'crc', 7, 6);
  AddPattern(Result,
    'tbl', 'w,w,imm12',
    'crypto', 1, 7);
  AddPattern(Result,
    'tbl', 'd,d,d',
    'base', 2, 2);
  AddPattern(Result,
    'tbl', 's,s,s',
    'fp', 3, 3);
  AddPattern(Result,
    'tbl', 'v128,v128,v128',
    'asimd', 4, 4);
  AddPattern(Result,
    'tbl', 'label',
    'lse', 5, 5);
  AddPattern(Result,
    'tbl', 'x,label',
    'crc', 6, 6);
  AddPattern(Result,
    'tbl', 'x,x,label',
    'crypto', 7, 7);
  AddPattern(Result,
    'dup', 'x,x,x',
    'base', 1, 2);
  AddPattern(Result,
    'dup', 'x,x,imm12',
    'fp', 2, 3);
  AddPattern(Result,
    'dup', 'x,[x]',
    'asimd', 3, 4);
  AddPattern(Result,
    'dup', '[x],x',
    'lse', 4, 5);
  AddPattern(Result,
    'dup', 'w,w,w',
    'crc', 5, 6);
  AddPattern(Result,
    'dup', 'w,w,imm12',
    'crypto', 6, 7);
  AddPattern(Result,
    'dup', 'd,d,d',
    'base', 7, 2);
  AddPattern(Result,
    'dup', 's,s,s',
    'fp', 1, 3);
  AddPattern(Result,
    'dup', 'v128,v128,v128',
    'asimd', 2, 4);
  AddPattern(Result,
    'dup', 'label',
    'lse', 3, 5);
  AddPattern(Result,
    'dup', 'x,label',
    'crc', 4, 6);
  AddPattern(Result,
    'dup', 'x,x,label',
    'crypto', 5, 7);
  AddPattern(Result,
    'ins', 'x,x,x',
    'base', 6, 2);
  AddPattern(Result,
    'ins', 'x,x,imm12',
    'fp', 7, 3);
  AddPattern(Result,
    'ins', 'x,[x]',
    'asimd', 1, 4);
  AddPattern(Result,
    'ins', '[x],x',
    'lse', 2, 5);
  AddPattern(Result,
    'ins', 'w,w,w',
    'crc', 3, 6);
  AddPattern(Result,
    'ins', 'w,w,imm12',
    'crypto', 4, 7);
  AddPattern(Result,
    'ins', 'd,d,d',
    'base', 5, 2);
  AddPattern(Result,
    'ins', 's,s,s',
    'fp', 6, 3);
  AddPattern(Result,
    'ins', 'v128,v128,v128',
    'asimd', 7, 4);
  AddPattern(Result,
    'ins', 'label',
    'lse', 1, 5);
  AddPattern(Result,
    'ins', 'x,label',
    'crc', 2, 6);
  AddPattern(Result,
    'ins', 'x,x,label',
    'crypto', 3, 7);
  AddPattern(Result,
    'umaxv', 'x,x,x',
    'base', 4, 2);
  AddPattern(Result,
    'umaxv', 'x,x,imm12',
    'fp', 5, 3);
  AddPattern(Result,
    'umaxv', 'x,[x]',
    'asimd', 6, 4);
  AddPattern(Result,
    'umaxv', '[x],x',
    'lse', 7, 5);
  AddPattern(Result,
    'umaxv', 'w,w,w',
    'crc', 1, 6);
  AddPattern(Result,
    'umaxv', 'w,w,imm12',
    'crypto', 2, 7);
  AddPattern(Result,
    'umaxv', 'd,d,d',
    'base', 3, 2);
  AddPattern(Result,
    'umaxv', 's,s,s',
    'fp', 4, 3);
  AddPattern(Result,
    'umaxv', 'v128,v128,v128',
    'asimd', 5, 4);
  AddPattern(Result,
    'umaxv', 'label',
    'lse', 6, 5);
  AddPattern(Result,
    'umaxv', 'x,label',
    'crc', 7, 6);
  AddPattern(Result,
    'umaxv', 'x,x,label',
    'crypto', 1, 7);
  AddPattern(Result,
    'smaxv', 'x,x,x',
    'base', 2, 2);
  AddPattern(Result,
    'smaxv', 'x,x,imm12',
    'fp', 3, 3);
  AddPattern(Result,
    'smaxv', 'x,[x]',
    'asimd', 4, 4);
  AddPattern(Result,
    'smaxv', '[x],x',
    'lse', 5, 5);
  AddPattern(Result,
    'smaxv', 'w,w,w',
    'crc', 6, 6);
  AddPattern(Result,
    'smaxv', 'w,w,imm12',
    'crypto', 7, 7);
  AddPattern(Result,
    'smaxv', 'd,d,d',
    'base', 1, 2);
  AddPattern(Result,
    'smaxv', 's,s,s',
    'fp', 2, 3);
  AddPattern(Result,
    'smaxv', 'v128,v128,v128',
    'asimd', 3, 4);
  AddPattern(Result,
    'smaxv', 'label',
    'lse', 4, 5);
  AddPattern(Result,
    'smaxv', 'x,label',
    'crc', 5, 6);
  AddPattern(Result,
    'smaxv', 'x,x,label',
    'crypto', 6, 7);
end;

function FindAArch64Pattern(const ACatalog: TInstructionPatternArray;
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

function AArch64PatternSummary(const ACatalog: TInstructionPatternArray): string;
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
  Result := Format('AArch64: %d patterns (%d scalar, %d vector, %d branch)',
    [Length(ACatalog), Scalar, Vector, Branch]);
end;

end.
