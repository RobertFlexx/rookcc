unit rcc_instcombine;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math, rcc_types, rcc_ir;

type
  TInstCombineStats = record
    Iterations: QWord;
    InstructionsVisited: QWord;
    IdentitiesFolded: QWord;
    StrengthReductions: QWord;
    ComparisonsCanonicalized: QWord;
    CastsCollapsed: QWord;
    SelectsFolded: QWord;
  end;

procedure CombineInstructions(AFunction: TIRFunction;
  out AStats: TInstCombineStats);

implementation

type
  TInstructionMap = array of TIRInstruction;

procedure BuildMap(AFunction: TIRFunction; out AMap: TInstructionMap);
var
  I, J: LongInt;
  Instruction: TIRInstruction;
begin
  SetLength(AMap, AFunction.ValueCount);
  for I := 0 to High(AMap) do AMap[I] := nil;
  for I := 0 to High(AFunction.Blocks) do
    for J := 0 to High(AFunction.Blocks[I].Instructions) do
    begin
      Instruction := AFunction.Blocks[I].Instructions[J];
      if (Instruction.ResultValue >= 0) and
         (Instruction.ResultValue <= High(AMap)) then
        AMap[Instruction.ResultValue] := Instruction;
    end;
end;

function ConstantValue(AValue: TIRValue; const AMap: TInstructionMap;
  out AConstant: Int64): Boolean;
var
  Instruction: TIRInstruction;
begin
  Result := False;
  AConstant := 0;
  if (AValue < 0) or (AValue > High(AMap)) then Exit;
  Instruction := AMap[AValue];
  if (Instruction <> nil) and (Instruction.Opcode = iroConstant) then
  begin
    AConstant := Instruction.Immediate;
    Result := True;
  end;
end;

function IsPowerOfTwo(AValue: QWord; out AShift: LongInt): Boolean;
begin
  Result := (AValue <> 0) and ((AValue and (AValue - 1)) = 0);
  AShift := 0;
  if not Result then Exit;
  while AValue > 1 do
  begin
    AValue := AValue shr 1;
    Inc(AShift);
  end;
end;

procedure MakeCopy(AInstruction: TIRInstruction; AValue: TIRValue);
begin
  AInstruction.Opcode := iroCopy;
  SetLength(AInstruction.Operands, 1);
  AInstruction.Operands[0] := AValue;
  AInstruction.Immediate := 0;
  AInstruction.UnsignedImmediate := 0;
end;

function CombineOne(AInstruction: TIRInstruction;
  const AMap: TInstructionMap; var AStats: TInstCombineStats): Boolean;
var
  LeftConstant, RightConstant: Int64;
  HasLeft, HasRight: Boolean;
  Temporary: TIRValue;
begin
  Result := False;
  Inc(AStats.InstructionsVisited);
  if Length(AInstruction.Operands) = 2 then
  begin
    HasLeft := ConstantValue(AInstruction.Operands[0], AMap, LeftConstant);
    HasRight := ConstantValue(AInstruction.Operands[1], AMap, RightConstant);
    if HasLeft and not HasRight and AInstruction.IsCommutative then
    begin
      Temporary := AInstruction.Operands[0];
      AInstruction.Operands[0] := AInstruction.Operands[1];
      AInstruction.Operands[1] := Temporary;
      HasRight := True;
      RightConstant := LeftConstant;
      Inc(AStats.ComparisonsCanonicalized);
      Result := True;
    end;
    if HasRight then
      case AInstruction.Opcode of
        iroAdd, iroSub, iroOr, iroXor, iroShl, iroAShr, iroLShr:
          if RightConstant = 0 then
          begin
            MakeCopy(AInstruction, AInstruction.Operands[0]);
            Inc(AStats.IdentitiesFolded);
            Exit(True);
          end;
        iroMul:
          begin
            if RightConstant = 1 then
            begin
              MakeCopy(AInstruction, AInstruction.Operands[0]);
              Inc(AStats.IdentitiesFolded);
              Exit(True);
            end;
            if RightConstant = 0 then
            begin
              AInstruction.Opcode := iroConstant;
              SetLength(AInstruction.Operands, 0);
              AInstruction.Immediate := 0;
              Inc(AStats.IdentitiesFolded);
              Exit(True);
            end;
            if RightConstant = 2 then
            begin
              AInstruction.Opcode := iroAdd;
              AInstruction.Operands[1] := AInstruction.Operands[0];
              Inc(AStats.StrengthReductions);
              Exit(True);
            end;
          end;
        iroAnd:
          if RightConstant = -1 then
          begin
            MakeCopy(AInstruction, AInstruction.Operands[0]);
            Inc(AStats.IdentitiesFolded);
            Exit(True);
          end;
        iroSDiv, iroUDiv:
          if RightConstant = 1 then
          begin
            MakeCopy(AInstruction, AInstruction.Operands[0]);
            Inc(AStats.IdentitiesFolded);
            Exit(True);
          end;
      end;
  end;
  if (AInstruction.Opcode in [iroTrunc, iroZExt, iroSExt, iroBitCast,
      iroFPExt, iroFPTrunc]) and (Length(AInstruction.Operands) = 1) and
     (AInstruction.Operands[0] >= 0) and
     (AInstruction.Operands[0] <= High(AMap)) and
     (AMap[AInstruction.Operands[0]] <> nil) and
     (AMap[AInstruction.Operands[0]].Opcode = AInstruction.Opcode) and
     (Length(AMap[AInstruction.Operands[0]].Operands) = 1) then
  begin
    AInstruction.Operands[0] := AMap[AInstruction.Operands[0]].Operands[0];
    Inc(AStats.CastsCollapsed);
    Result := True;
  end;
  if (AInstruction.Opcode = iroSelect) and
     (Length(AInstruction.Operands) = 3) and
     (AInstruction.Operands[1] = AInstruction.Operands[2]) then
  begin
    MakeCopy(AInstruction, AInstruction.Operands[1]);
    Inc(AStats.SelectsFolded);
    Result := True;
  end;
end;

procedure CombineInstructions(AFunction: TIRFunction;
  out AStats: TInstCombineStats);
var
  Map: TInstructionMap;
  I, J: LongInt;
  Changed: Boolean;
begin
  AStats.Iterations := 0;
  AStats.InstructionsVisited := 0;
  AStats.IdentitiesFolded := 0;
  AStats.StrengthReductions := 0;
  AStats.ComparisonsCanonicalized := 0;
  AStats.CastsCollapsed := 0;
  AStats.SelectsFolded := 0;
  repeat
    Changed := False;
    Inc(AStats.Iterations);
    AFunction.RebuildValueDefinitions;
    BuildMap(AFunction, Map);
    for I := 0 to High(AFunction.Blocks) do
      for J := 0 to High(AFunction.Blocks[I].Instructions) do
        if CombineOne(AFunction.Blocks[I].Instructions[J], Map, AStats) then
          Changed := True;
  until not Changed or (AStats.Iterations >= 6);
  AFunction.RebuildValueDefinitions;
end;

end.
