unit rcc_cfg_cleanup;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir;

type
  TCFGCleanupStats = record
    Iterations: QWord;
    UnreachableBlocksRemoved: QWord;
    RedundantBranchesRemoved: QWord;
    ConstantBranchesFolded: QWord;
    EmptyBlocksBypassed: QWord;
    SwitchesSimplified: QWord;
  end;

procedure CleanupControlFlow(AFunction: TIRFunction;
  out AStats: TCFGCleanupStats);

implementation

uses
  rcc_cfg;

function FindConstantDefinition(AFunction: TIRFunction; AValue: TIRValue;
  out AConstant: Int64): Boolean;
var
  Definition: TIRValueDefinition;
  Block: TIRBasicBlock;
  Instruction: TIRInstruction;
begin
  Result := False;
  AConstant := 0;
  if (AValue < 0) or (AValue > High(AFunction.ValueDefinitions)) then Exit;
  Definition := AFunction.ValueDefinitions[AValue];
  if Definition.DefiningBlock < 0 then Exit;
  Block := AFunction.BlockByID(Definition.DefiningBlock);
  if (Block = nil) or (Definition.DefiningInstruction < 0) or
     (Definition.DefiningInstruction > High(Block.Instructions)) then Exit;
  Instruction := Block.Instructions[Definition.DefiningInstruction];
  Result := Instruction.Opcode = iroConstant;
  if Result then AConstant := Instruction.Immediate;
end;

function FoldTerminator(AFunction: TIRFunction; ABlock: TIRBasicBlock;
  var AStats: TCFGCleanupStats): Boolean;
var
  Terminator: TIRInstruction;
  Constant: Int64;
  I: LongInt;
  Target: TIRBlockID;
begin
  Result := False;
  Terminator := ABlock.Terminator;
  if Terminator = nil then Exit;
  if (Terminator.Opcode = iroCondBranch) and
     (Terminator.TrueBlock = Terminator.FalseBlock) then
  begin
    Terminator.Opcode := iroBranch;
    SetLength(Terminator.Operands, 0);
    Inc(AStats.RedundantBranchesRemoved);
    Exit(True);
  end;
  if (Terminator.Opcode = iroCondBranch) and
     (Length(Terminator.Operands) = 1) and
     FindConstantDefinition(AFunction, Terminator.Operands[0], Constant) then
  begin
    if Constant <> 0 then Target := Terminator.TrueBlock
    else Target := Terminator.FalseBlock;
    Terminator.Opcode := iroBranch;
    Terminator.TrueBlock := Target;
    Terminator.FalseBlock := -1;
    SetLength(Terminator.Operands, 0);
    Inc(AStats.ConstantBranchesFolded);
    Exit(True);
  end;
  if (Terminator.Opcode = iroSwitch) and
     (Length(Terminator.Operands) = 1) and
     FindConstantDefinition(AFunction, Terminator.Operands[0], Constant) then
  begin
    Target := Terminator.DefaultBlock;
    for I := 0 to High(Terminator.SwitchCases) do
      if Terminator.SwitchCases[I].Value = Constant then
      begin
        Target := Terminator.SwitchCases[I].TargetBlock;
        Break;
      end;
    Terminator.Opcode := iroBranch;
    Terminator.TrueBlock := Target;
    Terminator.FalseBlock := -1;
    Terminator.DefaultBlock := -1;
    SetLength(Terminator.Operands, 0);
    SetLength(Terminator.SwitchCases, 0);
    Inc(AStats.SwitchesSimplified);
    Exit(True);
  end;
end;

function BypassEmptyBlocks(AFunction: TIRFunction;
  var AStats: TCFGCleanupStats): Boolean;
var
  I, J, K: LongInt;
  Block, Destination: TIRBasicBlock;
  Terminator: TIRInstruction;
  Target: TIRBlockID;
begin
  Result := False;
  for I := 0 to High(AFunction.Blocks) do
  begin
    Block := AFunction.Blocks[I];
    if (Block.ID = AFunction.EntryBlock) or
       (Length(Block.Instructions) <> 1) then Continue;
    Terminator := Block.Terminator;
    if (Terminator = nil) or (Terminator.Opcode <> iroBranch) then Continue;
    Target := Terminator.TrueBlock;
    if Target = Block.ID then Continue;
    for J := 0 to High(AFunction.Blocks) do
    begin
      Destination := AFunction.Blocks[J];
      Terminator := Destination.Terminator;
      if Terminator = nil then Continue;
      case Terminator.Opcode of
        iroBranch:
          if Terminator.TrueBlock = Block.ID then Terminator.TrueBlock := Target;
        iroCondBranch:
          begin
            if Terminator.TrueBlock = Block.ID then Terminator.TrueBlock := Target;
            if Terminator.FalseBlock = Block.ID then Terminator.FalseBlock := Target;
          end;
        iroSwitch:
          begin
            if Terminator.DefaultBlock = Block.ID then Terminator.DefaultBlock := Target;
            for K := 0 to High(Terminator.SwitchCases) do
              if Terminator.SwitchCases[K].TargetBlock = Block.ID then
                Terminator.SwitchCases[K].TargetBlock := Target;
          end;
      end;
    end;
    Inc(AStats.EmptyBlocksBypassed);
    Result := True;
  end;
end;

procedure CleanupControlFlow(AFunction: TIRFunction;
  out AStats: TCFGCleanupStats);
var
  Changed: Boolean;
  I: LongInt;
  Removed: QWord;
  CFGStats: TCFGStats;
begin
  AStats.Iterations := 0;
  AStats.UnreachableBlocksRemoved := 0;
  AStats.RedundantBranchesRemoved := 0;
  AStats.ConstantBranchesFolded := 0;
  AStats.EmptyBlocksBypassed := 0;
  AStats.SwitchesSimplified := 0;
  repeat
    Changed := False;
    Inc(AStats.Iterations);
    AFunction.RebuildValueDefinitions;
    for I := 0 to High(AFunction.Blocks) do
      if FoldTerminator(AFunction, AFunction.Blocks[I], AStats) then
        Changed := True;
    RebuildControlFlowGraph(AFunction, CFGStats);
    if BypassEmptyBlocks(AFunction, AStats) then Changed := True;
    RebuildControlFlowGraph(AFunction, CFGStats);
    RemoveUnreachableBlocks(AFunction, Removed);
    if Removed <> 0 then
    begin
      Inc(AStats.UnreachableBlocksRemoved, Removed);
      Changed := True;
    end;
  until not Changed or (AStats.Iterations >= 8);
  AFunction.RebuildValueDefinitions;
end;

end.
