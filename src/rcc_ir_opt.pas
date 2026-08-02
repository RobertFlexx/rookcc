unit rcc_ir_opt;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir;

type
  TIROptimizationStats = record
    PassesRun: QWord;
    ConstantsFolded: QWord;
    CopiesPropagated: QWord;
    DeadInstructionsRemoved: QWord;
    DeadBlocksRemoved: QWord;
    BranchesSimplified: QWord;
    AlgebraicSimplifications: QWord;
    ValuesRenumbered: QWord;
  end;

procedure OptimizeIRModule(AModule: TIRModule; ALevel: LongInt;
  AOptimizeSize: Boolean; out AStats: TIROptimizationStats);
procedure OptimizeIRFunction(AFunction: TIRFunction; ALevel: LongInt;
  AOptimizeSize: Boolean; var AStats: TIROptimizationStats);

implementation

uses
  rcc_cfg;

type
  TConstantState = (
    csUnknown,
    csConstant,
    csOverdefined
  );
  TConstantValue = record
    State: TConstantState;
    Value: Int64;
  end;
  TConstantValueArray = array of TConstantValue;
  TLongIntArray = array of LongInt;

function IsConstantInstruction(AInstruction: TIRInstruction;
  out AValue: Int64): Boolean;
begin
  Result := (AInstruction <> nil) and
    (AInstruction.Opcode = iroConstant);
  if Result then AValue := AInstruction.Immediate else AValue := 0;
end;

function EvalUnary(AOpcode: TIROpcode; A: Int64; out V: Int64): Boolean;
begin
  Result := True;
  case AOpcode of
    iroCopy, iroBitCast, iroTrunc, iroZExt, iroSExt,
    iroPtrToInt, iroIntToPtr: V := A;
    iroNeg: V := -A;
    iroNot: V := not A;
    iroLogicalNot: V := Ord(A = 0);
  else
    Result := False;
  end;
end;

function EvalBinary(AOpcode: TIROpcode; A, B: Int64;
  out V: Int64): Boolean;
begin
  Result := True;
  case AOpcode of
    iroAdd: V := Int64(QWord(A) + QWord(B));
    iroSub: V := Int64(QWord(A) - QWord(B));
    iroMul: V := Int64(QWord(A) * QWord(B));
    iroSDiv:
      begin
        if (B = 0) or ((A = Low(Int64)) and (B = -1)) then Exit(False);
        V := A div B;
      end;
    iroUDiv:
      begin
        if B = 0 then Exit(False);
        V := Int64(QWord(A) div QWord(B));
      end;
    iroSRem:
      begin
        if (B = 0) or ((A = Low(Int64)) and (B = -1)) then Exit(False);
        V := A mod B;
      end;
    iroURem:
      begin
        if B = 0 then Exit(False);
        V := Int64(QWord(A) mod QWord(B));
      end;
    iroShl: V := Int64(QWord(A) shl (B and 63));
    iroAShr:
      if A >= 0 then V := A shr (B and 63)
      else V := not ((not A) shr (B and 63));
    iroLShr: V := Int64(QWord(A) shr (B and 63));
    iroAnd: V := A and B;
    iroOr: V := A or B;
    iroXor: V := A xor B;
    iroICmpEQ: V := Ord(A = B);
    iroICmpNE: V := Ord(A <> B);
    iroICmpSLT: V := Ord(A < B);
    iroICmpSLE: V := Ord(A <= B);
    iroICmpSGT: V := Ord(A > B);
    iroICmpSGE: V := Ord(A >= B);
    iroICmpULT: V := Ord(QWord(A) < QWord(B));
    iroICmpULE: V := Ord(QWord(A) <= QWord(B));
    iroICmpUGT: V := Ord(QWord(A) > QWord(B));
    iroICmpUGE: V := Ord(QWord(A) >= QWord(B));
  else
    Result := False;
  end;
end;

procedure BuildDefinitionMap(AFunction: TIRFunction;
  out ADefinitions: array of TIRInstruction);
var
  I, J: LongInt;
  Inst: TIRInstruction;
begin
  for I := 0 to High(ADefinitions) do ADefinitions[I] := nil;
  for I := 0 to High(AFunction.Blocks) do
    for J := 0 to High(AFunction.Blocks[I].Instructions) do
    begin
      Inst := AFunction.Blocks[I].Instructions[J];
      if (Inst.ResultValue >= 0) and
         (Inst.ResultValue <= High(ADefinitions)) then
        ADefinitions[Inst.ResultValue] := Inst;
    end;
end;

function DefinitionFor(AValue: TIRValue;
  const ADefinitions: array of TIRInstruction): TIRInstruction;
begin
  if (AValue < 0) or (AValue > High(ADefinitions)) then Exit(nil);
  Result := ADefinitions[AValue];
end;

function ResolveCopy(AValue: TIRValue;
  const ADefinitions: array of TIRInstruction): TIRValue;
var
  Guard: LongInt;
  Inst: TIRInstruction;
begin
  Guard := 0;
  while (AValue >= 0) and (AValue <= High(ADefinitions)) do
  begin
    Inst := ADefinitions[AValue];
    if (Inst = nil) or (Inst.Opcode <> iroCopy) or
       (Length(Inst.Operands) <> 1) then Break;
    AValue := Inst.Operands[0];
    Inc(Guard);
    if Guard > Length(ADefinitions) then Break;
  end;
  Result := AValue;
end;

procedure CopyPropagation(AFunction: TIRFunction;
  var AStats: TIROptimizationStats);
var
  Definitions: array of TIRInstruction;
  I, J, K: LongInt;
  OldValue, NewValue: TIRValue;
begin
  SetLength(Definitions, AFunction.ValueCount);
  BuildDefinitionMap(AFunction, Definitions);
  for I := 0 to High(AFunction.Blocks) do
    for J := 0 to High(AFunction.Blocks[I].Instructions) do
      for K := 0 to High(AFunction.Blocks[I].Instructions[J].Operands) do
      begin
        OldValue := AFunction.Blocks[I].Instructions[J].Operands[K];
        NewValue := ResolveCopy(OldValue, Definitions);
        if NewValue <> OldValue then
        begin
          AFunction.Blocks[I].Instructions[J].Operands[K] := NewValue;
          Inc(AStats.CopiesPropagated);
        end;
      end;
end;

procedure ConstantFold(AFunction: TIRFunction;
  var AStats: TIROptimizationStats);
var
  Definitions: array of TIRInstruction;
  I, J: LongInt;
  Inst, ADef, BDef: TIRInstruction;
  A, B, V: Int64;
begin
  SetLength(Definitions, AFunction.ValueCount);
  BuildDefinitionMap(AFunction, Definitions);
  for I := 0 to High(AFunction.Blocks) do
    for J := 0 to High(AFunction.Blocks[I].Instructions) do
    begin
      Inst := AFunction.Blocks[I].Instructions[J];
      if Length(Inst.Operands) = 1 then
      begin
        ADef := DefinitionFor(Inst.Operands[0], Definitions);
        if IsConstantInstruction(ADef, A) and EvalUnary(Inst.Opcode, A, V) then
        begin
          Inst.Opcode := iroConstant;
          SetLength(Inst.Operands, 0);
          Inst.Immediate := V;
          Inc(AStats.ConstantsFolded);
        end;
      end
      else if Length(Inst.Operands) = 2 then
      begin
        ADef := DefinitionFor(Inst.Operands[0], Definitions);
        BDef := DefinitionFor(Inst.Operands[1], Definitions);
        if IsConstantInstruction(ADef, A) and
           IsConstantInstruction(BDef, B) and
           EvalBinary(Inst.Opcode, A, B, V) then
        begin
          Inst.Opcode := iroConstant;
          SetLength(Inst.Operands, 0);
          Inst.Immediate := V;
          Inc(AStats.ConstantsFolded);
        end;
      end;
    end;
end;

procedure AlgebraicSimplify(AFunction: TIRFunction;
  var AStats: TIROptimizationStats);
var
  Definitions: array of TIRInstruction;
  I, J: LongInt;
  Inst, RightDef, LeftDef: TIRInstruction;
  A, B: Int64;
  Replacement: TIRValue;
begin
  SetLength(Definitions, AFunction.ValueCount);
  BuildDefinitionMap(AFunction, Definitions);
  for I := 0 to High(AFunction.Blocks) do
    for J := 0 to High(AFunction.Blocks[I].Instructions) do
    begin
      Inst := AFunction.Blocks[I].Instructions[J];
      if Length(Inst.Operands) <> 2 then Continue;
      LeftDef := DefinitionFor(Inst.Operands[0], Definitions);
      RightDef := DefinitionFor(Inst.Operands[1], Definitions);
      Replacement := -1;
      if IsConstantInstruction(RightDef, B) then
      begin
        case Inst.Opcode of
          iroAdd, iroSub, iroOr, iroXor:
            if B = 0 then Replacement := Inst.Operands[0];
          iroMul, iroSDiv, iroUDiv:
            if B = 1 then Replacement := Inst.Operands[0];
          iroShl, iroAShr, iroLShr:
            if B = 0 then Replacement := Inst.Operands[0];
          iroAnd:
            if B = -1 then Replacement := Inst.Operands[0];
        end;
      end;
      if (Replacement < 0) and IsConstantInstruction(LeftDef, A) then
      begin
        case Inst.Opcode of
          iroAdd, iroOr, iroXor:
            if A = 0 then Replacement := Inst.Operands[1];
          iroMul:
            if A = 1 then Replacement := Inst.Operands[1];
          iroAnd:
            if A = -1 then Replacement := Inst.Operands[1];
        end;
      end;
      if Replacement >= 0 then
      begin
        Inst.Opcode := iroCopy;
        SetLength(Inst.Operands, 1);
        Inst.Operands[0] := Replacement;
        Inc(AStats.AlgebraicSimplifications);
      end;
    end;
end;

procedure CountUses(AFunction: TIRFunction; var AUseCounts: TLongIntArray);
var
  I, J, K, V: LongInt;
begin
  SetLength(AUseCounts, 0);
  SetLength(AUseCounts, AFunction.ValueCount);
  for I := 0 to High(AFunction.Blocks) do
    for J := 0 to High(AFunction.Blocks[I].Instructions) do
      for K := 0 to High(AFunction.Blocks[I].Instructions[J].Operands) do
      begin
        V := AFunction.Blocks[I].Instructions[J].Operands[K];
        if (V >= 0) and (V <= High(AUseCounts)) then Inc(AUseCounts[V]);
      end;
end;

procedure DeadInstructionElimination(AFunction: TIRFunction;
  var AStats: TIROptimizationStats);
var
  UseCounts: TLongIntArray;
  Changed: Boolean;
  I, J: LongInt;
  Inst: TIRInstruction;
begin
  UseCounts := nil;
  repeat
    Changed := False;
    CountUses(AFunction, UseCounts);
    for I := 0 to High(AFunction.Blocks) do
    begin
      J := High(AFunction.Blocks[I].Instructions);
      while J >= 0 do
      begin
        Inst := AFunction.Blocks[I].Instructions[J];
        if Inst.HasResult and not Inst.HasSideEffects and
           (UseCounts[Inst.ResultValue] = 0) then
        begin
          AFunction.Blocks[I].DeleteInstruction(J);
          Inc(AStats.DeadInstructionsRemoved);
          Changed := True;
        end;
        Dec(J);
      end;
    end;
  until not Changed;
end;

procedure SimplifyBranches(AFunction: TIRFunction;
  var AStats: TIROptimizationStats);
var
  Definitions: array of TIRInstruction;
  I: LongInt;
  T, ConditionDef: TIRInstruction;
  V: Int64;
begin
  SetLength(Definitions, AFunction.ValueCount);
  BuildDefinitionMap(AFunction, Definitions);
  for I := 0 to High(AFunction.Blocks) do
  begin
    T := AFunction.Blocks[I].Terminator;
    if (T = nil) or (T.Opcode <> iroCondBranch) or
       (Length(T.Operands) <> 1) then Continue;
    ConditionDef := DefinitionFor(T.Operands[0], Definitions);
    if IsConstantInstruction(ConditionDef, V) then
    begin
      T.Opcode := iroBranch;
      if V <> 0 then T.TrueBlock := T.TrueBlock
      else T.TrueBlock := T.FalseBlock;
      T.FalseBlock := -1;
      SetLength(T.Operands, 0);
      Inc(AStats.BranchesSimplified);
    end;
  end;
end;

procedure OptimizeIRFunction(AFunction: TIRFunction; ALevel: LongInt;
  AOptimizeSize: Boolean; var AStats: TIROptimizationStats);
var
  CFGStats: TCFGStats;
  Removed: QWord;
  Iteration: LongInt;
begin
  if (AFunction = nil) or (Length(AFunction.Blocks) = 0) then Exit;
  RebuildControlFlowGraph(AFunction, CFGStats);
  RemoveUnreachableBlocks(AFunction, Removed);
  Inc(AStats.DeadBlocksRemoved, Removed);
  AFunction.RebuildValueDefinitions;
  if ALevel <= 0 then Exit;
  for Iteration := 1 to 2 + Ord(ALevel >= 3) do
  begin
    ConstantFold(AFunction, AStats);
    AlgebraicSimplify(AFunction, AStats);
    CopyPropagation(AFunction, AStats);
    SimplifyBranches(AFunction, AStats);
    DeadInstructionElimination(AFunction, AStats);
    RebuildControlFlowGraph(AFunction, CFGStats);
    RemoveUnreachableBlocks(AFunction, Removed);
    Inc(AStats.DeadBlocksRemoved, Removed);
    AFunction.RebuildValueDefinitions;
    Inc(AStats.PassesRun, 6);
  end;
  AFunction.RebuildValueDefinitions;
end;

procedure OptimizeIRModule(AModule: TIRModule; ALevel: LongInt;
  AOptimizeSize: Boolean; out AStats: TIROptimizationStats);
var
  I: LongInt;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  for I := 0 to High(AModule.Functions) do
    OptimizeIRFunction(AModule.Functions[I], ALevel,
      AOptimizeSize, AStats);
end;

end.
