unit rcc_licm;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir;

type
  TLICMStats = record
    LoopsVisited: QWord;
    InstructionsExamined: QWord;
    InvariantsFound: QWord;
    InstructionsHoisted: QWord;
    RejectedForAliasing: QWord;
    RejectedForTrapping: QWord;
  end;

procedure RunLoopInvariantCodeMotion(AFunction: TIRFunction;
  out AStats: TLICMStats);

implementation

uses
  rcc_loop_analysis, rcc_alias_analysis;

function SafeToSpeculate(AInstruction: TIRInstruction): Boolean;
begin
  Result := (AInstruction <> nil) and AInstruction.HasResult and
    not AInstruction.HasSideEffects and
    not (AInstruction.Opcode in [iroLoad, iroSDiv, iroUDiv,
      iroSRem, iroURem, iroAlloca, iroPhi, iroCall, iroIntrinsic,
      iroOpaque]);
end;

function OperandsInvariant(AForest: TLoopForest; ALoopIndex: LongInt;
  AInstruction: TIRInstruction; AInvariantValues: array of Boolean): Boolean;
var
  I: LongInt;
  Value: TIRValue;
begin
  for I := 0 to High(AInstruction.Operands) do
  begin
    Value := AInstruction.Operands[I];
    if (Value >= 0) and (Value <= High(AInvariantValues)) and
       AInvariantValues[Value] then Continue;
    if not AForest.IsLoopInvariantValue(ALoopIndex, Value) then Exit(False);
  end;
  Result := True;
end;

procedure MoveInstructionToPreheader(AFunction: TIRFunction;
  AFrom: TIRBasicBlock; AIndex: LongInt; APreheader: TIRBasicBlock);
var
  Instruction: TIRInstruction;
  I, N, InsertIndex: LongInt;
begin
  Instruction := AFrom.Instructions[AIndex];
  for I := AIndex to High(AFrom.Instructions) - 1 do
    AFrom.Instructions[I] := AFrom.Instructions[I + 1];
  SetLength(AFrom.Instructions, Length(AFrom.Instructions) - 1);
  InsertIndex := Length(APreheader.Instructions);
  if APreheader.IsTerminated then Dec(InsertIndex);
  N := Length(APreheader.Instructions);
  SetLength(APreheader.Instructions, N + 1);
  for I := N downto InsertIndex + 1 do
    APreheader.Instructions[I] := APreheader.Instructions[I - 1];
  APreheader.Instructions[InsertIndex] := Instruction;
end;

procedure RunLoopInvariantCodeMotion(AFunction: TIRFunction;
  out AStats: TLICMStats);
var
  Forest: TLoopForest;
  Alias: TAliasAnalysis;
  Invariant: array of Boolean;
  I, BlockID, J: LongInt;
  LoopInfo: TLoopDescriptor;
  Block, Preheader: TIRBasicBlock;
  Instruction: TIRInstruction;
  Changed: Boolean;
begin
  AStats.LoopsVisited := 0;
  AStats.InstructionsExamined := 0;
  AStats.InvariantsFound := 0;
  AStats.InstructionsHoisted := 0;
  AStats.RejectedForAliasing := 0;
  AStats.RejectedForTrapping := 0;
  Forest := TLoopForest.Create(AFunction);
  Alias := TAliasAnalysis.Create(AFunction);
  try
    Forest.Build;
    Alias.Run;
    SetLength(Invariant, AFunction.ValueCount);
    for I := 0 to High(Forest.Loops) do
    begin
      Inc(AStats.LoopsVisited);
      LoopInfo := Forest.Loops[I];
      if LoopInfo.Preheader < 0 then Continue;
      Preheader := AFunction.BlockByID(LoopInfo.Preheader);
      if Preheader = nil then Continue;
      repeat
        Changed := False;
        BlockID := LoopInfo.Blocks.FirstSet;
        while BlockID >= 0 do
        begin
          Block := AFunction.BlockByID(BlockID);
          if Block <> nil then
          begin
            J := 0;
            while J < Length(Block.Instructions) do
            begin
              Instruction := Block.Instructions[J];
              Inc(AStats.InstructionsExamined);
              if SafeToSpeculate(Instruction) and
                 OperandsInvariant(Forest, I, Instruction, Invariant) then
              begin
                Inc(AStats.InvariantsFound);
                if Instruction.ResultValue >= 0 then
                  Invariant[Instruction.ResultValue] := True;
                MoveInstructionToPreheader(AFunction, Block, J, Preheader);
                Inc(AStats.InstructionsHoisted);
                Changed := True;
                Continue;
              end
              else if Instruction.HasSideEffects then
                Inc(AStats.RejectedForAliasing)
              else if Instruction.Opcode in [iroSDiv, iroUDiv, iroSRem, iroURem] then
                Inc(AStats.RejectedForTrapping);
              Inc(J);
            end;
          end;
          BlockID := LoopInfo.Blocks.NextSet(BlockID);
        end;
      until not Changed;
    end;
  finally
    Alias.Free;
    Forest.Free;
  end;
  AFunction.RebuildValueDefinitions;
end;

end.
