unit rcc_regalloc;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_ir, rcc_arch, rcc_liveness;

type
  TAllocationKind = (
    akNone,
    akRegister,
    akStack
  );

  TValueAllocation = record
    Kind: TAllocationKind;
    RegisterNumber: LongInt;
    StackOffset: LongInt;
    WidthBits: LongInt;
  end;
  TValueAllocationArray = array of TValueAllocation;

  TRegisterAllocationStats = record
    ValuesAllocated: QWord;
    RegisterValues: QWord;
    SpilledValues: QWord;
    StackBytes: QWord;
    PeakActiveIntervals: QWord;
  end;

  TRegisterAllocation = class
  public
    Target: TTargetDescriptor;
    Values: TValueAllocationArray;
    StackFrameBytes: LongInt;
    UsedCalleeSaved: array of LongInt;
    Stats: TRegisterAllocationStats;
    function AllocationFor(AValue: TIRValue): TValueAllocation;
    function Summary(AFunction: TIRFunction): string;
  end;

function AllocateRegistersLinearScan(AFunction: TIRFunction;
  const ATarget: TTargetDescriptor;
  const ALiveness: TLivenessResult): TRegisterAllocation;

implementation

type
  TIntervalIndexArray = array of LongInt;
  TActiveEntry = record
    IntervalIndex: LongInt;
    RegisterNumber: LongInt;
  end;
  TActiveArray = array of TActiveEntry;
  TRegisterArray = array of LongInt;

function AlignUp(AValue, AAlignment: LongInt): LongInt;
begin
  if AAlignment <= 1 then Exit(AValue);
  Result := (AValue + AAlignment - 1) and not (AAlignment - 1);
end;

procedure AddRegister(var ARegisters: TRegisterArray; ARegister: LongInt);
var
  N: LongInt;
begin
  N := Length(ARegisters);
  SetLength(ARegisters, N + 1);
  ARegisters[N] := ARegister;
end;

procedure AddActive(var AActive: TActiveArray; AInterval, ARegister: LongInt);
var
  N: LongInt;
begin
  N := Length(AActive);
  SetLength(AActive, N + 1);
  AActive[N].IntervalIndex := AInterval;
  AActive[N].RegisterNumber := ARegister;
end;

procedure DeleteActive(var AActive: TActiveArray; AIndex: LongInt);
var
  I, N: LongInt;
begin
  N := Length(AActive);
  for I := AIndex to N - 2 do AActive[I] := AActive[I + 1];
  SetLength(AActive, N - 1);
end;

procedure SortIntervals(var AIndices: TIntervalIndexArray;
  const AIntervals: TLiveIntervalArray);
var
  I, J, Key: LongInt;
begin
  for I := 1 to High(AIndices) do
  begin
    Key := AIndices[I];
    J := I - 1;
    while (J >= 0) and
      (AIntervals[AIndices[J]].StartPosition >
       AIntervals[Key].StartPosition) do
    begin
      AIndices[J + 1] := AIndices[J];
      Dec(J);
    end;
    AIndices[J + 1] := Key;
  end;
end;

function BuildAllocatableRegisters(const ATarget: TTargetDescriptor): TRegisterArray;
var
  I: LongInt;
begin
  Result := nil;
  for I := 0 to High(ATarget.Registers) do
    if (ATarget.Registers[I].RegClass = rcInteger) and
       not ATarget.Registers[I].Reserved and
       ATarget.Registers[I].CallerSaved then
      AddRegister(Result, ATarget.Registers[I].Number);


  if Length(Result) > 10 then SetLength(Result, 10);
end;

function RegisterInUse(const AActive: TActiveArray;
  ARegister: LongInt): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(AActive) do
    if AActive[I].RegisterNumber = ARegister then Exit(True);
  Result := False;
end;

procedure ExpireOldIntervals(var AActive: TActiveArray;
  const AIntervals: TLiveIntervalArray; AStart: LongInt);
var
  I: LongInt;
begin
  I := High(AActive);
  while I >= 0 do
  begin
    if AIntervals[AActive[I].IntervalIndex].EndPosition < AStart then
      DeleteActive(AActive, I);
    Dec(I);
  end;
end;

function FindFreeRegister(const ARegisters: TRegisterArray;
  const AActive: TActiveArray): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(ARegisters) do
    if not RegisterInUse(AActive, ARegisters[I]) then Exit(ARegisters[I]);
  Result := -1;
end;

function SpillCandidate(const AActive: TActiveArray;
  const AIntervals: TLiveIntervalArray): LongInt;
var
  I: LongInt;
  BestEnd: LongInt;
  BestWeight: Double;
begin
  Result := -1;
  BestEnd := -1;
  BestWeight := 1.0E300;
  for I := 0 to High(AActive) do
    if (AIntervals[AActive[I].IntervalIndex].Weight < BestWeight) or
       ((AIntervals[AActive[I].IntervalIndex].Weight = BestWeight) and
        (AIntervals[AActive[I].IntervalIndex].EndPosition > BestEnd)) then
    begin
      Result := I;
      BestEnd := AIntervals[AActive[I].IntervalIndex].EndPosition;
      BestWeight := AIntervals[AActive[I].IntervalIndex].Weight;
    end;
end;

function ValueWidth(AFunction: TIRFunction; AValue: TIRValue): LongInt;
var
  T: TIRType;
begin
  T := AFunction.ValueType(AValue);
  case T.Kind of
    irtI1, irtI8, irtI16, irtI32, irtI64: Result := T.Bits;
    irtF32, irtF64, irtF80: Result := T.Bits;
    irtPointer: Result := 64;
    irtAggregate: Result := LongInt(T.AggregateSize * 8);
  else
    Result := 0;
  end;
end;

procedure AssignStackSlot(AFunction: TIRFunction; AValue: TIRValue;
  var AStackBytes: LongInt; var AAllocation: TValueAllocation);
var
  Width, Size, Align: LongInt;
begin
  Width := ValueWidth(AFunction, AValue);
  Size := (Width + 7) div 8;
  if Size <= 0 then Size := 8;
  if Size > 16 then Align := 16
  else if Size >= 8 then Align := 8
  else if Size >= 4 then Align := 4
  else if Size >= 2 then Align := 2
  else Align := 1;
  AStackBytes := AlignUp(AStackBytes, Align);
  Inc(AStackBytes, Size);
  AAllocation.Kind := akStack;
  AAllocation.RegisterNumber := -1;
  AAllocation.StackOffset := AStackBytes;
  AAllocation.WidthBits := Width;
end;

function AllocateRegistersLinearScan(AFunction: TIRFunction;
  const ATarget: TTargetDescriptor;
  const ALiveness: TLivenessResult): TRegisterAllocation;
var
  Registers: TRegisterArray;
  Active: TActiveArray;
  Order: TIntervalIndexArray;
  I, N, IntervalIndex, RegisterNumber, Candidate,
    SpilledInterval, StackBytes: LongInt;
  Current: TLiveInterval;
  Allocation: TValueAllocation;
begin
  Result := TRegisterAllocation.Create;
  Result.Target := ATarget;
  FillChar(Result.Stats, SizeOf(Result.Stats), 0);
  SetLength(Result.Values, AFunction.ValueCount);
  for I := 0 to High(Result.Values) do
  begin
    Result.Values[I].Kind := akNone;
    Result.Values[I].RegisterNumber := -1;
    Result.Values[I].StackOffset := -1;
    Result.Values[I].WidthBits := ValueWidth(AFunction, I);
  end;
  Registers := BuildAllocatableRegisters(ATarget);
  SetLength(Active, 0);
  SetLength(Order, 0);
  for I := 0 to High(ALiveness.Intervals) do
    if ALiveness.Intervals[I].StartPosition >= 0 then
    begin
      N := Length(Order);
      SetLength(Order, N + 1);
      Order[N] := I;
    end;
  SortIntervals(Order, ALiveness.Intervals);
  StackBytes := 0;
  for I := 0 to High(Order) do
  begin
    IntervalIndex := Order[I];
    Current := ALiveness.Intervals[IntervalIndex];
    ExpireOldIntervals(Active, ALiveness.Intervals, Current.StartPosition);
    if QWord(Length(Active)) > Result.Stats.PeakActiveIntervals then
      Result.Stats.PeakActiveIntervals := Length(Active);
    RegisterNumber := FindFreeRegister(Registers, Active);
    if RegisterNumber >= 0 then
    begin
      Result.Values[Current.Value].Kind := akRegister;
      Result.Values[Current.Value].RegisterNumber := RegisterNumber;
      Result.Values[Current.Value].StackOffset := -1;
      Result.Values[Current.Value].WidthBits := ValueWidth(AFunction,
        Current.Value);
      AddActive(Active, IntervalIndex, RegisterNumber);
      Inc(Result.Stats.RegisterValues);
    end
    else
    begin
      Candidate := SpillCandidate(Active, ALiveness.Intervals);
      if (Candidate >= 0) and
         (ALiveness.Intervals[Active[Candidate].IntervalIndex].Weight <
          Current.Weight) and
         (ALiveness.Intervals[Active[Candidate].IntervalIndex].EndPosition >
          Current.EndPosition) then
      begin
        SpilledInterval := Active[Candidate].IntervalIndex;
        Allocation := Result.Values[
          ALiveness.Intervals[SpilledInterval].Value];
        RegisterNumber := Allocation.RegisterNumber;
        AssignStackSlot(AFunction,
          ALiveness.Intervals[SpilledInterval].Value,
          StackBytes,
          Result.Values[ALiveness.Intervals[SpilledInterval].Value]);
        Inc(Result.Stats.SpilledValues);
        Active[Candidate].IntervalIndex := IntervalIndex;
        Active[Candidate].RegisterNumber := RegisterNumber;
        Result.Values[Current.Value].Kind := akRegister;
        Result.Values[Current.Value].RegisterNumber := RegisterNumber;
        Result.Values[Current.Value].StackOffset := -1;
        Result.Values[Current.Value].WidthBits := ValueWidth(AFunction,
          Current.Value);
        Inc(Result.Stats.RegisterValues);
      end
      else
      begin
        AssignStackSlot(AFunction, Current.Value, StackBytes,
          Result.Values[Current.Value]);
        Inc(Result.Stats.SpilledValues);
      end;
    end;
    Inc(Result.Stats.ValuesAllocated);
  end;
  Result.StackFrameBytes := AlignUp(StackBytes,
    ATarget.DataLayout.StackAlignment);
  Result.Stats.StackBytes := Result.StackFrameBytes;
end;

function TRegisterAllocation.AllocationFor(
  AValue: TIRValue): TValueAllocation;
begin
  if (AValue < 0) or (AValue > High(Values)) then
    raise ERCCError.Create('internal error: register allocation value invalid');
  Result := Values[AValue];
end;

function TRegisterAllocation.Summary(AFunction: TIRFunction): string;
var
  Lines: TStringList;
  I: LongInt;
  A: TValueAllocation;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('register allocation @' + AFunction.Name +
      ' target=' + Target.Triple);
    for I := 0 to High(Values) do
    begin
      A := Values[I];
      case A.Kind of
        akRegister:
          Lines.Add(Format('  %%%d -> reg#%d width=%d',
            [I, A.RegisterNumber, A.WidthBits]));
        akStack:
          Lines.Add(Format('  %%%d -> stack[-%d] width=%d',
            [I, A.StackOffset, A.WidthBits]));
      end;
    end;
    Lines.Add('frame bytes: ' + IntToStr(StackFrameBytes));
    Lines.Add('register values: ' + IntToStr(Stats.RegisterValues));
    Lines.Add('spilled values: ' + IntToStr(Stats.SpilledValues));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
