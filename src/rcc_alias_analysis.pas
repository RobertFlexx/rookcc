unit rcc_alias_analysis;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir;

type
  TAliasKind = (
    akUnknown,
    akStackObject,
    akGlobalObject,
    akFunctionObject,
    akDerivedPointer,
    akNullPointer
  );

  TAliasLocation = record
    Kind: TAliasKind;
    RootValue: TIRValue;
    RootSymbol: string;
    ConstantOffset: Int64;
    Size: QWord;
    Alignment: LongInt;
    Escapes: Boolean;
  end;
  TAliasLocationArray = array of TAliasLocation;

  TAliasResult = (
    arNoAlias,
    arMayAlias,
    arMustAlias,
    arPartialAlias
  );

  TAliasAnalysis = class
  private
    FFunction: TIRFunction;
    FLocations: TAliasLocationArray;
    procedure InitializeLocations;
    procedure AnalyzeInstruction(AInstruction: TIRInstruction);
    function IsValidValue(AValue: TIRValue): Boolean;
  public
    constructor Create(AFunction: TIRFunction);
    procedure Run;
    function LocationFor(AValue: TIRValue): TAliasLocation;
    function Query(ALeft, ARight: TIRValue; ALeftSize,
      ARightSize: QWord): TAliasResult;
    procedure MarkEscaping(AValue: TIRValue);
    function Dump: string;
  end;

function AliasKindName(AKind: TAliasKind): string;
function AliasResultName(AResult: TAliasResult): string;

implementation

function AliasKindName(AKind: TAliasKind): string;
begin
  case AKind of
    akUnknown: Result := 'unknown';
    akStackObject: Result := 'stack';
    akGlobalObject: Result := 'global';
    akFunctionObject: Result := 'function';
    akDerivedPointer: Result := 'derived';
    akNullPointer: Result := 'null';
  else
    Result := 'invalid';
  end;
end;

function AliasResultName(AResult: TAliasResult): string;
begin
  case AResult of
    arNoAlias: Result := 'no-alias';
    arMayAlias: Result := 'may-alias';
    arMustAlias: Result := 'must-alias';
    arPartialAlias: Result := 'partial-alias';
  else
    Result := 'invalid';
  end;
end;

constructor TAliasAnalysis.Create(AFunction: TIRFunction);
begin
  inherited Create;
  FFunction := AFunction;
  InitializeLocations;
end;

procedure TAliasAnalysis.InitializeLocations;
var
  I: LongInt;
begin
  SetLength(FLocations, FFunction.ValueCount);
  for I := 0 to High(FLocations) do
  begin
    FLocations[I].Kind := akUnknown;
    FLocations[I].RootValue := I;
    FLocations[I].RootSymbol := '';
    FLocations[I].ConstantOffset := 0;
    FLocations[I].Size := 0;
    FLocations[I].Alignment := 1;
    FLocations[I].Escapes := False;
  end;
end;

function TAliasAnalysis.IsValidValue(AValue: TIRValue): Boolean;
begin
  Result := (AValue >= 0) and (AValue <= High(FLocations));
end;

procedure TAliasAnalysis.AnalyzeInstruction(AInstruction: TIRInstruction);
var
  Value, Base: TIRValue;
  BaseLocation: TAliasLocation;
begin
  if (AInstruction = nil) or not AInstruction.HasResult then Exit;
  Value := AInstruction.ResultValue;
  if not IsValidValue(Value) then Exit;
  case AInstruction.Opcode of
    iroAlloca:
      begin
        FLocations[Value].Kind := akStackObject;
        FLocations[Value].RootValue := Value;
        FLocations[Value].Size := AInstruction.UnsignedImmediate;
        FLocations[Value].Alignment := AInstruction.Alignment;
      end;
    iroAddressOfGlobal:
      begin
        FLocations[Value].Kind := akGlobalObject;
        FLocations[Value].RootValue := Value;
        FLocations[Value].RootSymbol := AInstruction.Symbol;
        FLocations[Value].Alignment := AInstruction.Alignment;
      end;
    iroAddressOfFunction:
      begin
        FLocations[Value].Kind := akFunctionObject;
        FLocations[Value].RootValue := Value;
        FLocations[Value].RootSymbol := AInstruction.Symbol;
      end;
    iroGetElementPtr:
      begin
        if Length(AInstruction.Operands) < 1 then Exit;
        Base := AInstruction.Operands[0];
        if not IsValidValue(Base) then Exit;
        BaseLocation := FLocations[Base];
        FLocations[Value] := BaseLocation;
        FLocations[Value].Kind := akDerivedPointer;
        FLocations[Value].ConstantOffset := BaseLocation.ConstantOffset +
          AInstruction.Immediate;
      end;
    iroCopy, iroBitCast, iroIntToPtr:
      begin
        if Length(AInstruction.Operands) <> 1 then Exit;
        Base := AInstruction.Operands[0];
        if IsValidValue(Base) then FLocations[Value] := FLocations[Base];
      end;
    iroConstant:
      if (AInstruction.ResultType.Kind = irtPointer) and
         (AInstruction.UnsignedImmediate = 0) then
      begin
        FLocations[Value].Kind := akNullPointer;
        FLocations[Value].RootValue := Value;
      end;
  end;
end;

procedure TAliasAnalysis.Run;
var
  I, J, K: LongInt;
  Instruction: TIRInstruction;
begin
  InitializeLocations;
  for I := 0 to High(FFunction.Blocks) do
    for J := 0 to High(FFunction.Blocks[I].Instructions) do
    begin
      Instruction := FFunction.Blocks[I].Instructions[J];
      AnalyzeInstruction(Instruction);
      if Instruction.Opcode in [iroCall, iroReturn, iroStore] then
        for K := 0 to High(Instruction.Operands) do
          if IsValidValue(Instruction.Operands[K]) and
             (FFunction.ValueType(Instruction.Operands[K]).Kind = irtPointer) then
            MarkEscaping(Instruction.Operands[K]);
    end;
end;

function TAliasAnalysis.LocationFor(AValue: TIRValue): TAliasLocation;
begin
  if IsValidValue(AValue) then Result := FLocations[AValue]
  else
  begin
    Result.Kind := akUnknown;
    Result.RootValue := -1;
    Result.RootSymbol := '';
    Result.ConstantOffset := 0;
    Result.Size := 0;
    Result.Alignment := 1;
    Result.Escapes := True;
  end;
end;

function RangesOverlap(ALeftOffset: Int64; ALeftSize: QWord;
  ARightOffset: Int64; ARightSize: QWord): Boolean;
var
  LeftEnd, RightEnd: Int64;
begin
  if (ALeftSize = 0) or (ARightSize = 0) then Exit(True);
  LeftEnd := ALeftOffset + Int64(ALeftSize);
  RightEnd := ARightOffset + Int64(ARightSize);
  Result := (ALeftOffset < RightEnd) and (ARightOffset < LeftEnd);
end;

function TAliasAnalysis.Query(ALeft, ARight: TIRValue; ALeftSize,
  ARightSize: QWord): TAliasResult;
var
  L, R: TAliasLocation;
begin
  L := LocationFor(ALeft);
  R := LocationFor(ARight);
  if (L.Kind = akNullPointer) or (R.Kind = akNullPointer) then
    Exit(arNoAlias);
  if (L.Kind = akUnknown) or (R.Kind = akUnknown) then
    Exit(arMayAlias);
  if (L.Kind = akFunctionObject) or (R.Kind = akFunctionObject) then
  begin
    if (L.Kind = R.Kind) and (L.RootSymbol = R.RootSymbol) then
      Exit(arMustAlias);
    Exit(arNoAlias);
  end;
  if (L.RootValue <> R.RootValue) or (L.RootSymbol <> R.RootSymbol) then
  begin
    if ((L.Kind in [akStackObject, akDerivedPointer]) and
        (R.Kind in [akStackObject, akDerivedPointer]) and
        (L.RootValue <> R.RootValue)) or
       ((L.Kind = akGlobalObject) and (R.Kind = akGlobalObject) and
        (L.RootSymbol <> R.RootSymbol)) then Exit(arNoAlias);
    Exit(arMayAlias);
  end;
  if L.ConstantOffset = R.ConstantOffset then
  begin
    if (ALeftSize = ARightSize) or (ALeftSize = 0) or (ARightSize = 0) then
      Exit(arMustAlias);
    Exit(arPartialAlias);
  end;
  if RangesOverlap(L.ConstantOffset, ALeftSize,
    R.ConstantOffset, ARightSize) then Exit(arPartialAlias);
  Result := arNoAlias;
end;

procedure TAliasAnalysis.MarkEscaping(AValue: TIRValue);
var
  Root: TIRValue;
  I: LongInt;
begin
  if not IsValidValue(AValue) then Exit;
  Root := FLocations[AValue].RootValue;
  for I := 0 to High(FLocations) do
    if FLocations[I].RootValue = Root then FLocations[I].Escapes := True;
end;

function TAliasAnalysis.Dump: string;
var
  I: LongInt;
  L: TAliasLocation;
begin
  Result := '';
  for I := 0 to High(FLocations) do
  begin
    L := FLocations[I];
    if L.Kind = akUnknown then Continue;
    Result := Result + IRValueText(I) + ': ' + AliasKindName(L.Kind) +
      ' root=' + IntToStr(L.RootValue) + ' symbol=' + L.RootSymbol +
      ' offset=' + IntToStr(L.ConstantOffset) +
      ' escape=' + BoolToStr(L.Escapes, True) + LineEnding;
  end;
end;

end.
