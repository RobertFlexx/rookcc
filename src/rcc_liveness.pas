unit rcc_liveness;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir;

type
  TBitVector = array of QWord;

  TBlockLiveness = record
    UseSet: TBitVector;
    DefSet: TBitVector;
    LiveIn: TBitVector;
    LiveOut: TBitVector;
  end;
  TBlockLivenessArray = array of TBlockLiveness;

  TLiveInterval = record
    Value: TIRValue;
    StartPosition: LongInt;
    EndPosition: LongInt;
    UseCount: LongInt;
    Weight: Double;
    AssignedRegister: LongInt;
    StackSlot: LongInt;
    Spilled: Boolean;
  end;
  TLiveIntervalArray = array of TLiveInterval;

  TLivenessResult = record
    Blocks: TBlockLivenessArray;
    Intervals: TLiveIntervalArray;
    InstructionCount: LongInt;
    ValueCount: LongInt;
  end;

procedure InitializeBitVector(var AVector: TBitVector; ABitCount: LongInt);
procedure ClearBitVector(var AVector: TBitVector);
procedure SetBit(var AVector: TBitVector; ABit: LongInt);
procedure ClearBit(var AVector: TBitVector; ABit: LongInt);
function TestBit(const AVector: TBitVector; ABit: LongInt): Boolean;
function UnionInto(var ADestination: TBitVector;
  const ASource: TBitVector): Boolean;
function SubtractInto(var ADestination: TBitVector;
  const ASource: TBitVector): Boolean;
function BitVectorEquals(const ALeft, ARight: TBitVector): Boolean;
function BitVectorText(const AVector: TBitVector; ABitCount: LongInt): string;

procedure ComputeLiveness(AFunction: TIRFunction;
  var AResult: TLivenessResult);
procedure BuildLiveIntervals(AFunction: TIRFunction;
  var AResult: TLivenessResult);
function LivenessSummary(AFunction: TIRFunction;
  const AResult: TLivenessResult): string;

implementation

uses
  Classes;

procedure InitializeBitVector(var AVector: TBitVector; ABitCount: LongInt);
begin
  if ABitCount <= 0 then SetLength(AVector, 0)
  else SetLength(AVector, (ABitCount + 63) div 64);
  ClearBitVector(AVector);
end;

procedure ClearBitVector(var AVector: TBitVector);
var
  I: LongInt;
begin
  for I := 0 to High(AVector) do AVector[I] := 0;
end;

procedure SetBit(var AVector: TBitVector; ABit: LongInt);
begin
  if ABit < 0 then Exit;
  if (ABit div 64) > High(AVector) then Exit;
  AVector[ABit div 64] := AVector[ABit div 64] or
    (QWord(1) shl (ABit and 63));
end;

procedure ClearBit(var AVector: TBitVector; ABit: LongInt);
begin
  if ABit < 0 then Exit;
  if (ABit div 64) > High(AVector) then Exit;
  AVector[ABit div 64] := AVector[ABit div 64] and not
    (QWord(1) shl (ABit and 63));
end;

function TestBit(const AVector: TBitVector; ABit: LongInt): Boolean;
begin
  if (ABit < 0) or ((ABit div 64) > High(AVector)) then Exit(False);
  Result := (AVector[ABit div 64] and
    (QWord(1) shl (ABit and 63))) <> 0;
end;

function UnionInto(var ADestination: TBitVector;
  const ASource: TBitVector): Boolean;
var
  I: LongInt;
  Old: QWord;
begin
  Result := False;
  for I := 0 to High(ADestination) do
  begin
    Old := ADestination[I];
    if I <= High(ASource) then
      ADestination[I] := ADestination[I] or ASource[I];
    if Old <> ADestination[I] then Result := True;
  end;
end;

function SubtractInto(var ADestination: TBitVector;
  const ASource: TBitVector): Boolean;
var
  I: LongInt;
  Old: QWord;
begin
  Result := False;
  for I := 0 to High(ADestination) do
  begin
    Old := ADestination[I];
    if I <= High(ASource) then
      ADestination[I] := ADestination[I] and not ASource[I];
    if Old <> ADestination[I] then Result := True;
  end;
end;

function BitVectorEquals(const ALeft, ARight: TBitVector): Boolean;
var
  I, MaxLength: LongInt;
  L, R: QWord;
begin
  MaxLength := Length(ALeft);
  if Length(ARight) > MaxLength then MaxLength := Length(ARight);
  for I := 0 to MaxLength - 1 do
  begin
    if I <= High(ALeft) then L := ALeft[I] else L := 0;
    if I <= High(ARight) then R := ARight[I] else R := 0;
    if L <> R then Exit(False);
  end;
  Result := True;
end;

function CloneBitVector(const ASource: TBitVector): TBitVector;
var
  I: LongInt;
begin
  Result := nil;
  SetLength(Result, Length(ASource));
  for I := 0 to High(ASource) do Result[I] := ASource[I];
end;

function BitVectorText(const AVector: TBitVector; ABitCount: LongInt): string;
var
  I: LongInt;
begin
  Result := '{';
  for I := 0 to ABitCount - 1 do
    if TestBit(AVector, I) then
    begin
      if Result <> '{' then Result := Result + ',';
      Result := Result + '%' + IntToStr(I);
    end;
  Result := Result + '}';
end;

function BlockIndexByID(AFunction: TIRFunction; AID: TIRBlockID): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(AFunction.Blocks) do
    if AFunction.Blocks[I].ID = AID then Exit(I);
  Result := -1;
end;

procedure ComputeBlockUseDef(AFunction: TIRFunction; ABlockIndex: LongInt;
  var ALiveness: TBlockLiveness);
var
  I, J, V: LongInt;
  Inst: TIRInstruction;
begin
  InitializeBitVector(ALiveness.UseSet, AFunction.ValueCount);
  InitializeBitVector(ALiveness.DefSet, AFunction.ValueCount);
  InitializeBitVector(ALiveness.LiveIn, AFunction.ValueCount);
  InitializeBitVector(ALiveness.LiveOut, AFunction.ValueCount);
  for I := 0 to High(AFunction.Blocks[ABlockIndex].Instructions) do
  begin
    Inst := AFunction.Blocks[ABlockIndex].Instructions[I];
    for J := 0 to High(Inst.Operands) do
    begin
      V := Inst.Operands[J];
      if not TestBit(ALiveness.DefSet, V) then SetBit(ALiveness.UseSet, V);
    end;
    if Inst.ResultValue >= 0 then SetBit(ALiveness.DefSet, Inst.ResultValue);
  end;
end;

procedure ComputeLiveness(AFunction: TIRFunction;
  var AResult: TLivenessResult);
var
  I, J, SuccessorIndex: LongInt;
  Changed: Boolean;
  NewOut, NewIn: TBitVector;
begin


  SetLength(AResult.Blocks, 0);
  SetLength(AResult.Intervals, 0);
  AResult.InstructionCount := 0;
  AResult.ValueCount := AFunction.ValueCount;
  SetLength(AResult.Blocks, Length(AFunction.Blocks));
  for I := 0 to High(AFunction.Blocks) do
  begin
    ComputeBlockUseDef(AFunction, I, AResult.Blocks[I]);
    Inc(AResult.InstructionCount,
      Length(AFunction.Blocks[I].Instructions));
  end;
  repeat
    Changed := False;
    for I := High(AFunction.Blocks) downto 0 do
    begin
      InitializeBitVector(NewOut, AFunction.ValueCount);
      for J := 0 to High(AFunction.Blocks[I].Successors) do
      begin
        SuccessorIndex := BlockIndexByID(AFunction,
          AFunction.Blocks[I].Successors[J]);
        if SuccessorIndex >= 0 then
          UnionInto(NewOut, AResult.Blocks[SuccessorIndex].LiveIn);
      end;
      NewIn := CloneBitVector(NewOut);
      SubtractInto(NewIn, AResult.Blocks[I].DefSet);
      UnionInto(NewIn, AResult.Blocks[I].UseSet);
      if not BitVectorEquals(NewOut, AResult.Blocks[I].LiveOut) then
      begin
        AResult.Blocks[I].LiveOut := NewOut;
        Changed := True;
      end;
      if not BitVectorEquals(NewIn, AResult.Blocks[I].LiveIn) then
      begin
        AResult.Blocks[I].LiveIn := NewIn;
        Changed := True;
      end;
    end;
  until not Changed;
  BuildLiveIntervals(AFunction, AResult);
end;

procedure TouchInterval(var AIntervals: TLiveIntervalArray; AValue,
  APosition: LongInt; AWeight: Double; AUse: Boolean);
begin
  if (AValue < 0) or (AValue > High(AIntervals)) then Exit;
  if AIntervals[AValue].StartPosition < 0 then
    AIntervals[AValue].StartPosition := APosition;
  if APosition > AIntervals[AValue].EndPosition then
    AIntervals[AValue].EndPosition := APosition;
  if AUse then
  begin
    Inc(AIntervals[AValue].UseCount);
    AIntervals[AValue].Weight := AIntervals[AValue].Weight + AWeight;
  end;
end;

procedure BuildLiveIntervals(AFunction: TIRFunction;
  var AResult: TLivenessResult);
var
  I, J, K, Position, V: LongInt;
  Weight: Double;
  Inst: TIRInstruction;
begin
  SetLength(AResult.Intervals, AFunction.ValueCount);
  for V := 0 to High(AResult.Intervals) do
  begin
    AResult.Intervals[V].Value := V;
    AResult.Intervals[V].StartPosition := -1;
    AResult.Intervals[V].EndPosition := -1;
    AResult.Intervals[V].UseCount := 0;
    AResult.Intervals[V].Weight := 0;
    AResult.Intervals[V].AssignedRegister := -1;
    AResult.Intervals[V].StackSlot := -1;
    AResult.Intervals[V].Spilled := False;
  end;
  Position := 0;
  for I := 0 to High(AFunction.Blocks) do
  begin
    Weight := 1.0;
    for J := 1 to AFunction.Blocks[I].LoopDepth do Weight := Weight * 10.0;
    for V := 0 to AFunction.ValueCount - 1 do
      if TestBit(AResult.Blocks[I].LiveIn, V) then
        TouchInterval(AResult.Intervals, V, Position, Weight, False);
    for J := 0 to High(AFunction.Blocks[I].Instructions) do
    begin
      Inst := AFunction.Blocks[I].Instructions[J];
      for K := 0 to High(Inst.Operands) do
        TouchInterval(AResult.Intervals, Inst.Operands[K], Position,
          Weight, True);
      if Inst.ResultValue >= 0 then
        TouchInterval(AResult.Intervals, Inst.ResultValue, Position,
          Weight, False);
      Inc(Position, 2);
    end;
    for V := 0 to AFunction.ValueCount - 1 do
      if TestBit(AResult.Blocks[I].LiveOut, V) then
        TouchInterval(AResult.Intervals, V, Position, Weight, False);
  end;
end;

function LivenessSummary(AFunction: TIRFunction;
  const AResult: TLivenessResult): string;
var
  Lines: TStringList;
  I: LongInt;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('liveness @' + AFunction.Name);
    for I := 0 to High(AFunction.Blocks) do
    begin
      Lines.Add('  ' + AFunction.Blocks[I].Name +
        ' use=' + BitVectorText(AResult.Blocks[I].UseSet,
          AResult.ValueCount) +
        ' def=' + BitVectorText(AResult.Blocks[I].DefSet,
          AResult.ValueCount) +
        ' in=' + BitVectorText(AResult.Blocks[I].LiveIn,
          AResult.ValueCount) +
        ' out=' + BitVectorText(AResult.Blocks[I].LiveOut,
          AResult.ValueCount));
    end;
    Lines.Add('intervals');
    for I := 0 to High(AResult.Intervals) do
      if AResult.Intervals[I].StartPosition >= 0 then
        Lines.Add(Format('  %%%d [%d,%d] uses=%d weight=%.2f',
          [I, AResult.Intervals[I].StartPosition,
           AResult.Intervals[I].EndPosition,
           AResult.Intervals[I].UseCount,
           AResult.Intervals[I].Weight]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
