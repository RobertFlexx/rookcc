unit rcc_sparse_propagation;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir, rcc_bitset, rcc_worklist;

type
  TLatticeKind = (
    lkUnknown,
    lkConstant,
    lkOverdefined
  );

  TLatticeValue = record
    Kind: TLatticeKind;
    IntegerValue: Int64;
    FloatBits: QWord;
  end;
  TLatticeValueArray = array of TLatticeValue;

  TSparsePropagationStats = record
    ValuesVisited: QWord;
    BlocksMadeExecutable: QWord;
    ConstantsDiscovered: QWord;
    InstructionsRewritten: QWord;
    BranchesSimplified: QWord;
  end;

procedure RunSparseConditionalConstantPropagation(AFunction: TIRFunction;
  out AStats: TSparsePropagationStats);

implementation

function Meet(const A, B: TLatticeValue): TLatticeValue;
begin
  if A.Kind = lkUnknown then Exit(B);
  if B.Kind = lkUnknown then Exit(A);
  if (A.Kind = lkConstant) and (B.Kind = lkConstant) and
     (A.IntegerValue = B.IntegerValue) and (A.FloatBits = B.FloatBits) then
    Exit(A);
  Result.Kind := lkOverdefined;
  Result.IntegerValue := 0;
  Result.FloatBits := 0;
end;

function EvaluateUnary(AOpcode: TIROpcode; A: Int64;
  out AResult: Int64): Boolean;
begin
  Result := True;
  case AOpcode of
    iroCopy, iroBitCast, iroTrunc, iroZExt, iroSExt,
    iroPtrToInt, iroIntToPtr: AResult := A;
    iroNeg: AResult := -A;
    iroNot: AResult := not A;
    iroLogicalNot: AResult := Ord(A = 0);
  else
    Result := False;
  end;
end;

function EvaluateBinary(AOpcode: TIROpcode; A, B: Int64;
  out AResult: Int64): Boolean;
begin
  Result := True;
  case AOpcode of
    iroAdd: AResult := A + B;
    iroSub: AResult := A - B;
    iroMul: AResult := A * B;
    iroSDiv: if B <> 0 then AResult := A div B else Exit(False);
    iroUDiv: if B <> 0 then AResult := Int64(QWord(A) div QWord(B)) else Exit(False);
    iroSRem: if B <> 0 then AResult := A mod B else Exit(False);
    iroURem: if B <> 0 then AResult := Int64(QWord(A) mod QWord(B)) else Exit(False);
    iroShl: AResult := Int64(QWord(A) shl (B and 63));
    iroAShr: AResult := A shr (B and 63);
    iroLShr: AResult := Int64(QWord(A) shr (B and 63));
    iroAnd: AResult := A and B;
    iroOr: AResult := A or B;
    iroXor: AResult := A xor B;
    iroICmpEQ: AResult := Ord(A = B);
    iroICmpNE: AResult := Ord(A <> B);
    iroICmpSLT: AResult := Ord(A < B);
    iroICmpSLE: AResult := Ord(A <= B);
    iroICmpSGT: AResult := Ord(A > B);
    iroICmpSGE: AResult := Ord(A >= B);
    iroICmpULT: AResult := Ord(QWord(A) < QWord(B));
    iroICmpULE: AResult := Ord(QWord(A) <= QWord(B));
    iroICmpUGT: AResult := Ord(QWord(A) > QWord(B));
    iroICmpUGE: AResult := Ord(QWord(A) >= QWord(B));
  else
    Result := False;
  end;
end;

function EvaluateInstruction(AInstruction: TIRInstruction;
  const AValues: TLatticeValueArray): TLatticeValue;
var
  A, B, V: Int64;
  I: LongInt;
  Current: TLatticeValue;
begin
  Result.Kind := lkUnknown;
  Result.IntegerValue := 0;
  Result.FloatBits := 0;
  case AInstruction.Opcode of
    iroConstant:
      begin
        Result.Kind := lkConstant;
        Result.IntegerValue := AInstruction.Immediate;
        Result.FloatBits := AInstruction.UnsignedImmediate;
      end;
    iroUndef:
      Result.Kind := lkUnknown;
    iroPhi:
      begin
        Current.Kind := lkUnknown;
        Current.IntegerValue := 0;
        Current.FloatBits := 0;
        for I := 0 to High(AInstruction.Operands) do
          if (AInstruction.Operands[I] >= 0) and
             (AInstruction.Operands[I] <= High(AValues)) then
            Current := Meet(Current, AValues[AInstruction.Operands[I]]);
        Result := Current;
      end;
  else
    if Length(AInstruction.Operands) = 1 then
    begin
      if (AInstruction.Operands[0] < 0) or
         (AInstruction.Operands[0] > High(AValues)) then
      begin
        Result.Kind := lkOverdefined;
        Exit;
      end;
      Current := AValues[AInstruction.Operands[0]];
      if Current.Kind = lkConstant then
      begin
        A := Current.IntegerValue;
        if EvaluateUnary(AInstruction.Opcode, A, V) then
        begin
          Result.Kind := lkConstant;
          Result.IntegerValue := V;
        end
        else Result.Kind := lkOverdefined;
      end
      else Result := Current;
    end
    else if Length(AInstruction.Operands) = 2 then
    begin
      if (AInstruction.Operands[0] < 0) or
         (AInstruction.Operands[0] > High(AValues)) or
         (AInstruction.Operands[1] < 0) or
         (AInstruction.Operands[1] > High(AValues)) then
      begin
        Result.Kind := lkOverdefined;
        Exit;
      end;
      if (AValues[AInstruction.Operands[0]].Kind = lkOverdefined) or
         (AValues[AInstruction.Operands[1]].Kind = lkOverdefined) then
      begin
        Result.Kind := lkOverdefined;
        Exit;
      end;
      if (AValues[AInstruction.Operands[0]].Kind = lkConstant) and
         (AValues[AInstruction.Operands[1]].Kind = lkConstant) then
      begin
        A := AValues[AInstruction.Operands[0]].IntegerValue;
        B := AValues[AInstruction.Operands[1]].IntegerValue;
        if EvaluateBinary(AInstruction.Opcode, A, B, V) then
        begin
          Result.Kind := lkConstant;
          Result.IntegerValue := V;
        end
        else Result.Kind := lkOverdefined;
      end;
    end
    else if AInstruction.HasResult then Result.Kind := lkOverdefined;
  end;
end;

procedure RunSparseConditionalConstantPropagation(AFunction: TIRFunction;
  out AStats: TSparsePropagationStats);
var
  Values: TLatticeValueArray;
  Executable: TBitSet;
  Work: TIntWorkList;
  I, J, BlockID: LongInt;
  Block: TIRBasicBlock;
  Instruction: TIRInstruction;
  NewValue, OldValue: TLatticeValue;
  Changed, NewlyExecutable: Boolean;
begin
  AStats.ValuesVisited := 0;
  AStats.BlocksMadeExecutable := 0;
  AStats.ConstantsDiscovered := 0;
  AStats.InstructionsRewritten := 0;
  AStats.BranchesSimplified := 0;
  SetLength(Values, AFunction.ValueCount);
  for I := 0 to High(Values) do
  begin
    Values[I].Kind := lkUnknown;
    Values[I].IntegerValue := 0;
    Values[I].FloatBits := 0;
  end;
  for I := 0 to High(AFunction.Parameters) do
    Values[AFunction.Parameters[I].Value].Kind := lkOverdefined;
  Executable := TBitSet.Create(Length(AFunction.Blocks) + 16);
  Work := TIntWorkList.Create(Length(AFunction.Blocks) + 16);
  try
    if AFunction.EntryBlock >= 0 then Work.Push(AFunction.EntryBlock);
    while Work.Pop(BlockID) do
    begin
      if (BlockID >= Executable.BitCount) then Executable.Resize(BlockID + 16);
      NewlyExecutable := not Executable.Contains(BlockID);
      if NewlyExecutable then
      begin
        Executable.Include(BlockID);
        Inc(AStats.BlocksMadeExecutable);
      end;
      Block := AFunction.BlockByID(BlockID);
      if Block = nil then Continue;
      repeat
        Changed := False;
        for I := 0 to High(Block.Instructions) do
        begin
          Instruction := Block.Instructions[I];
          if Instruction.HasResult then
          begin
            Inc(AStats.ValuesVisited);
            OldValue := Values[Instruction.ResultValue];
            NewValue := Meet(OldValue, EvaluateInstruction(Instruction, Values));
            if (NewValue.Kind <> OldValue.Kind) or
               (NewValue.IntegerValue <> OldValue.IntegerValue) or
               (NewValue.FloatBits <> OldValue.FloatBits) then
            begin
              Values[Instruction.ResultValue] := NewValue;
              Changed := True;
              if (NewValue.Kind = lkConstant) and
                 (OldValue.Kind <> lkConstant) then
                Inc(AStats.ConstantsDiscovered);
            end;
          end;
        end;
      until not Changed;
      Instruction := Block.Terminator;
      if Instruction = nil then Continue;
      if not (NewlyExecutable or Changed) then Continue;
      case Instruction.Opcode of
        iroBranch: Work.Push(Instruction.TrueBlock);
        iroCondBranch:
          if (Length(Instruction.Operands) = 1) and
             (Values[Instruction.Operands[0]].Kind = lkConstant) then
          begin
            if Values[Instruction.Operands[0]].IntegerValue <> 0 then
              Work.Push(Instruction.TrueBlock)
            else Work.Push(Instruction.FalseBlock);
          end
          else
          begin
            Work.Push(Instruction.TrueBlock);
            Work.Push(Instruction.FalseBlock);
          end;
        iroSwitch:
          begin
            Work.Push(Instruction.DefaultBlock);
            for J := 0 to High(Instruction.SwitchCases) do
              Work.Push(Instruction.SwitchCases[J].TargetBlock);
          end;
      end;
    end;
    for I := 0 to High(AFunction.Blocks) do
      for J := 0 to High(AFunction.Blocks[I].Instructions) do
      begin
        Instruction := AFunction.Blocks[I].Instructions[J];
        if Instruction.HasResult and
           (Values[Instruction.ResultValue].Kind = lkConstant) and
           (Instruction.Opcode <> iroConstant) and
           not Instruction.HasSideEffects then
        begin
          Instruction.Opcode := iroConstant;
          Instruction.Immediate := Values[Instruction.ResultValue].IntegerValue;
          Instruction.UnsignedImmediate := Values[Instruction.ResultValue].FloatBits;
          SetLength(Instruction.Operands, 0);
          Inc(AStats.InstructionsRewritten);
        end;
      end;
  finally
    Work.Free;
    Executable.Free;
  end;
  AFunction.RebuildValueDefinitions;
end;

end.
