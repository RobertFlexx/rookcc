unit rcc_cross_backend;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_arch, rcc_buffer, rcc_object_model;

type
  TCrossBackendStats = record
    TextBytes: QWord;
    DataBytes: QWord;
    FunctionsEmitted: QWord;
    InstructionsEmitted: QWord;
    Target: string;
  end;

function CrossTargetProgramSupported(AProgram: TProgram;
  const ATarget: TTargetDescriptor; out AReason: string): Boolean;
function EvaluateConstantExpression(AExpression: TExpr;
  out AValue: Int64): Boolean;
function ExtractConstantMainReturn(AProgram: TProgram;
  out AValue: Int64; out AReason: string): Boolean;
procedure GenerateCrossTargetExecutable(AProgram: TProgram;
  const ATarget: TTargetDescriptor; const AFileName: string;
  out AStats: TCrossBackendStats);
procedure GenerateCrossTargetObject(AProgram: TProgram;
  const ATarget: TTargetDescriptor; const AFileName: string;
  out AStats: TCrossBackendStats);

implementation

uses
  rcc_elf_image, rcc_cross_codegen;

function ArithmeticShiftRight(AValue: Int64; AShift: LongInt): Int64;
begin
  AShift := AShift and 63;
  if AShift = 0 then Exit(AValue);
  if AValue >= 0 then Result := AValue shr AShift
  else Result := not ((not AValue) shr AShift);
end;

function EvaluateConstantExpression(AExpression: TExpr;
  out AValue: Int64): Boolean;
var
  L, R, T: Int64;
begin
  AValue := 0;
  if AExpression = nil then Exit(False);
  case AExpression.Kind of
    ekInteger:
      begin
        AValue := AExpression.IntValue;
        Exit(True);
      end;
    ekUnary:
      begin
        if not EvaluateConstantExpression(AExpression.Left, L) then Exit(False);
        case AExpression.UnaryOp of
          uoPositive: AValue := L;
          uoNegative: AValue := -L;
          uoLogicalNot: AValue := Ord(L = 0);
          uoBitwiseNot: AValue := not L;
        end;
        Exit(True);
      end;
    ekBinary:
      begin
        if not EvaluateConstantExpression(AExpression.Left, L) then Exit(False);
        if (AExpression.BinaryOp = boLogicalAnd) and (L = 0) then
        begin AValue := 0; Exit(True); end;
        if (AExpression.BinaryOp = boLogicalOr) and (L <> 0) then
        begin AValue := 1; Exit(True); end;
        if not EvaluateConstantExpression(AExpression.Right, R) then Exit(False);
        case AExpression.BinaryOp of
          boAdd: AValue := Int64(QWord(L) + QWord(R));
          boSub: AValue := Int64(QWord(L) - QWord(R));
          boMul: AValue := Int64(QWord(L) * QWord(R));
          boDiv:
            begin
              if (R = 0) or ((L = Low(Int64)) and (R = -1)) then Exit(False);
              AValue := L div R;
            end;
          boMod:
            begin
              if (R = 0) or ((L = Low(Int64)) and (R = -1)) then Exit(False);
              AValue := L mod R;
            end;
          boShiftLeft: AValue := Int64(QWord(L) shl (R and 63));
          boShiftRight: AValue := ArithmeticShiftRight(L, R);
          boLess: AValue := Ord(L < R);
          boLessEqual: AValue := Ord(L <= R);
          boGreater: AValue := Ord(L > R);
          boGreaterEqual: AValue := Ord(L >= R);
          boEqual: AValue := Ord(L = R);
          boNotEqual: AValue := Ord(L <> R);
          boBitAnd: AValue := L and R;
          boBitXor: AValue := L xor R;
          boBitOr: AValue := L or R;
          boLogicalAnd: AValue := Ord((L <> 0) and (R <> 0));
          boLogicalOr: AValue := Ord((L <> 0) or (R <> 0));
          boComma: AValue := R;
        else
          Exit(False);
        end;
        Exit(True);
      end;
    ekConditional:
      begin
        if not EvaluateConstantExpression(AExpression.Left, L) then Exit(False);
        if L <> 0 then
          Result := EvaluateConstantExpression(AExpression.Right, AValue)
        else
          Result := EvaluateConstantExpression(AExpression.Third, AValue);
        Exit;
      end;
    ekCast, ekSizeof:
      begin
        if EvaluateConstantExpression(AExpression.Left, T) then
        begin
          AValue := T;
          Exit(True);
        end;
      end;
  end;
  Result := False;
end;

function FindReturnExpression(AStatement: TStmt; out AExpression: TExpr;
  out AReason: string): Boolean;
var
  I: LongInt;
  ConditionValue: Int64;
  Candidate: TExpr;
  Found: Boolean;
begin
  AExpression := nil;
  AReason := '';
  if AStatement = nil then
  begin
    AReason := 'main has no body';
    Exit(False);
  end;
  case AStatement.Kind of
    skReturn:
      begin
        AExpression := AStatement.Expr;
        Exit(True);
      end;
    skBlock:
      begin
        Found := False;
        for I := 0 to High(AStatement.Children) do
        begin
          if AStatement.Children[I].Kind = skEmpty then Continue;
          if AStatement.Children[I].Kind = skDecl then
          begin
            AReason := 'cross-target bootstrap does not yet lower local declarations';
            Exit(False);
          end;
          if AStatement.Children[I].Kind = skExpr then
          begin
            AReason := 'cross-target bootstrap does not yet lower expression statements';
            Exit(False);
          end;
          if FindReturnExpression(AStatement.Children[I], Candidate,
            AReason) then
          begin
            if Found then
            begin
              AReason := 'cross-target bootstrap requires one statically selected return';
              Exit(False);
            end;
            AExpression := Candidate;
            Found := True;
          end
          else if AReason <> '' then Exit(False);
        end;
        if Found then Exit(True);
        AReason := 'main body does not contain a return statement';
        Exit(False);
      end;
    skIf:
      begin
        if not EvaluateConstantExpression(AStatement.Expr, ConditionValue) then
        begin
          AReason := 'cross-target bootstrap requires constant if conditions';
          Exit(False);
        end;
        if ConditionValue <> 0 then
          Exit(FindReturnExpression(AStatement.Body, AExpression, AReason));
        if AStatement.ElseBody <> nil then
          Exit(FindReturnExpression(AStatement.ElseBody, AExpression, AReason));
        AReason := 'constant-false if has no else return';
        Exit(False);
      end;
  else
    AReason := 'statement kind requires a hosted cross compiler';
    Exit(False);
  end;
end;

function ExtractConstantMainReturn(AProgram: TProgram;
  out AValue: Int64; out AReason: string): Boolean;
var
  MainFunction: TFunction;
  ReturnExpression: TExpr;
begin
  AValue := 0;
  AReason := '';
  if AProgram = nil then
  begin
    AReason := 'nil program';
    Exit(False);
  end;
  MainFunction := AProgram.FindFunction('main');
  if MainFunction = nil then
  begin
    AReason := 'program has no main function';
    Exit(False);
  end;
  if MainFunction.IsPrototype or (MainFunction.Body = nil) then
  begin
    AReason := 'main is declared but not defined';
    Exit(False);
  end;
  if Length(MainFunction.Params) <> 0 then
  begin
    AReason := 'cross-target bootstrap currently requires int main(void)';
    Exit(False);
  end;
  if not FindReturnExpression(MainFunction.Body, ReturnExpression,
    AReason) then Exit(False);
  if not EvaluateConstantExpression(ReturnExpression, AValue) then
  begin
    AReason := 'main return expression is not compile-time constant';
    Exit(False);
  end;
  Result := True;
end;

function CrossTargetProgramSupported(AProgram: TProgram;
  const ATarget: TTargetDescriptor; out AReason: string): Boolean;
var
  Value: Int64;
begin
  if not (ATarget.Architecture in [archAArch64, archRISCV64]) then
  begin
    AReason := 'cross backend is only selected for AArch64 and RISC-V 64';
    Exit(False);
  end;
  Result := ExtractConstantMainReturn(AProgram, Value, AReason);
end;

procedure EmitAArch64Word(ABuffer: TByteBuffer; AInstruction: LongWord);
begin
  ABuffer.Add32(AInstruction);
end;

procedure EmitAArch64MoveImmediate(ABuffer: TByteBuffer; ARegister: LongInt;
  AValue: QWord; var AInstructionCount: QWord);
var
  Part: LongWord;
  Shift: LongInt;
  First: Boolean;
  Instruction: LongWord;
begin
  First := True;
  for Shift := 0 to 3 do
  begin
    Part := LongWord((AValue shr (Shift * 16)) and $FFFF);
    if First or (Part <> 0) then
    begin
      if First then Instruction := $D2800000
      else Instruction := $F2800000;
      Instruction := Instruction or (LongWord(Shift) shl 21) or
        (Part shl 5) or LongWord(ARegister and 31);
      EmitAArch64Word(ABuffer, Instruction);
      Inc(AInstructionCount);
      First := False;
    end;
  end;
end;

procedure GenerateAArch64Text(AText: TByteBuffer; AReturnValue: Int64;
  out AInstructionCount: QWord; out AMainOffset: QWord);
var
  BranchOffset: LongInt;
  BranchInstruction: LongWord;
begin
  AInstructionCount := 0;

  BranchOffset := 3;
  BranchInstruction := $94000000 or LongWord(BranchOffset and $03FFFFFF);
  EmitAArch64Word(AText, BranchInstruction);
  Inc(AInstructionCount);
  EmitAArch64MoveImmediate(AText, 8, 93, AInstructionCount);
  EmitAArch64Word(AText, $D4000001);
  Inc(AInstructionCount);
  AMainOffset := QWord(AText.Size);
  EmitAArch64MoveImmediate(AText, 0, QWord(AReturnValue), AInstructionCount);
  EmitAArch64Word(AText, $D65F03C0);
  Inc(AInstructionCount);
end;

function EncodeRISCVAddI(ARd, ARs1: LongInt; AImmediate: LongInt): LongWord;
begin
  Result := (LongWord(AImmediate) and $FFF) shl 20;
  Result := Result or (LongWord(ARs1 and 31) shl 15);
  Result := Result or (LongWord(ARd and 31) shl 7) or $13;
end;

function EncodeRISCVLUI(ARd: LongInt; AImmediate20: LongInt): LongWord;
begin
  Result := (LongWord(AImmediate20) and $FFFFF) shl 12;
  Result := Result or (LongWord(ARd and 31) shl 7) or $37;
end;

function EncodeRISCVJAL(ARd: LongInt; AOffset: LongInt): LongWord;
var
  U: LongWord;
begin
  if (AOffset and 1) <> 0 then
    raise ERCCError.Create('internal error: unaligned RISC-V JAL');
  U := LongWord(AOffset);
  Result := ((U shr 20) and 1) shl 31;
  Result := Result or (((U shr 1) and $3FF) shl 21);
  Result := Result or (((U shr 11) and 1) shl 20);
  Result := Result or (((U shr 12) and $FF) shl 12);
  Result := Result or (LongWord(ARd and 31) shl 7) or $6F;
end;

procedure EmitRISCVWord(ABuffer: TByteBuffer; AInstruction: LongWord);
begin
  ABuffer.Add32(AInstruction);
end;

procedure EmitRISCVLoadImmediate(ABuffer: TByteBuffer; ARegister: LongInt;
  AValue: Int64; var AInstructionCount: QWord);
var
  Low12, High20: Int64;
begin
  if (AValue >= -2048) and (AValue <= 2047) then
  begin
    EmitRISCVWord(ABuffer, EncodeRISCVAddI(ARegister, 0, LongInt(AValue)));
    Inc(AInstructionCount);
    Exit;
  end;
  if (AValue < Low(LongInt)) or (AValue > High(LongInt)) then
    raise ERCCError.Create(
      'error: RISC-V bootstrap backend currently supports 32-bit immediates');
  High20 := (AValue + $800) shr 12;
  Low12 := AValue - (High20 shl 12);
  EmitRISCVWord(ABuffer, EncodeRISCVLUI(ARegister, LongInt(High20)));
  Inc(AInstructionCount);
  EmitRISCVWord(ABuffer, EncodeRISCVAddI(ARegister, ARegister,
    LongInt(Low12)));
  Inc(AInstructionCount);
end;

procedure GenerateRISCVText(AText: TByteBuffer; AReturnValue: Int64;
  out AInstructionCount: QWord; out AMainOffset: QWord);
begin
  AInstructionCount := 0;

  EmitRISCVWord(AText, EncodeRISCVJAL(1, 12));
  Inc(AInstructionCount);
  EmitRISCVWord(AText, EncodeRISCVAddI(17, 0, 93));
  Inc(AInstructionCount);
  EmitRISCVWord(AText, $00000073);
  Inc(AInstructionCount);
  AMainOffset := QWord(AText.Size);
  EmitRISCVLoadImmediate(AText, 10, AReturnValue, AInstructionCount);
  EmitRISCVWord(AText, $00008067);
  Inc(AInstructionCount);
end;

procedure GenerateX86ObjectText(AText: TByteBuffer; AReturnValue: Int64;
  out AInstructionCount: QWord);
begin
  if (AReturnValue < Low(LongInt)) or (AReturnValue > High(LongInt)) then
    raise ERCCError.Create('error: bootstrap object return value is too wide');
  AText.Add8($B8);
  AText.Add32(LongWord(AReturnValue));
  AText.Add8($C3);
  AInstructionCount := 2;
end;

procedure GenerateAArch64ObjectText(AText: TByteBuffer; AReturnValue: Int64;
  out AInstructionCount: QWord);
begin
  AInstructionCount := 0;
  EmitAArch64MoveImmediate(AText, 0, QWord(AReturnValue), AInstructionCount);
  EmitAArch64Word(AText, $D65F03C0);
  Inc(AInstructionCount);
end;

procedure GenerateRISCVObjectText(AText: TByteBuffer; AReturnValue: Int64;
  out AInstructionCount: QWord);
begin
  AInstructionCount := 0;
  EmitRISCVLoadImmediate(AText, 10, AReturnValue, AInstructionCount);
  EmitRISCVWord(AText, $00008067);
  Inc(AInstructionCount);
end;

procedure GenerateCrossTargetExecutable(AProgram: TProgram;
  const ATarget: TTargetDescriptor; const AFileName: string;
  out AStats: TCrossBackendStats);
var
  NativeStats: TCrossCodegenStats;
begin
  GenerateCrossIntegerExecutable(AProgram, ATarget, AFileName, NativeStats);
  AStats.TextBytes := NativeStats.TextBytes;
  AStats.DataBytes := NativeStats.DataBytes;
  AStats.FunctionsEmitted := NativeStats.FunctionsEmitted;
  AStats.InstructionsEmitted := NativeStats.InstructionsEmitted;
  AStats.Target := NativeStats.Target;
end;

procedure GenerateCrossTargetObject(AProgram: TProgram;
  const ATarget: TTargetDescriptor; const AFileName: string;
  out AStats: TCrossBackendStats);
var
  NativeStats: TCrossCodegenStats;
begin
  if ATarget.Architecture = archX86_64 then
    raise ERCCError.Create(
      'internal error: x86-64 object selected the cross backend');
  GenerateCrossIntegerObject(AProgram, ATarget, AFileName, NativeStats);
  AStats.TextBytes := NativeStats.TextBytes;
  AStats.DataBytes := NativeStats.DataBytes;
  AStats.FunctionsEmitted := NativeStats.FunctionsEmitted;
  AStats.InstructionsEmitted := NativeStats.InstructionsEmitted;
  AStats.Target := NativeStats.Target;
end;

end.
