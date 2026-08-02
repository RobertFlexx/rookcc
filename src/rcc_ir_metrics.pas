unit rcc_ir_metrics;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_ir, rcc_cfg;

type
  TIROpcodeCounts = array[TIROpcode] of QWord;

  TIRFunctionMetrics = record
    Name: string;
    Blocks: QWord;
    ReachableBlocks: QWord;
    Instructions: QWord;
    Terminators: QWord;
    PhiNodes: QWord;
    Calls: QWord;
    Loads: QWord;
    Stores: QWord;
    Branches: QWord;
    Values: QWord;
    CriticalEdges: QWord;
    MaxLoopDepth: LongInt;
    EstimatedCost: QWord;
    OpcodeCounts: TIROpcodeCounts;
  end;
  TIRFunctionMetricsArray = array of TIRFunctionMetrics;

  TIRModuleMetrics = record
    Functions: TIRFunctionMetricsArray;
    Globals: QWord;
    GlobalBytes: QWord;
    TotalBlocks: QWord;
    TotalInstructions: QWord;
    TotalValues: QWord;
    TotalCalls: QWord;
    TotalCriticalEdges: QWord;
    HasOpaqueOperations: Boolean;
  end;

function InstructionEstimatedCost(AInstruction: TIRInstruction): LongInt;
function MeasureIRFunction(AFunction: TIRFunction): TIRFunctionMetrics;
function MeasureIRModule(AModule: TIRModule): TIRModuleMetrics;
function IRFunctionMetricsText(const AMetrics: TIRFunctionMetrics): string;
function IRModuleMetricsText(const AMetrics: TIRModuleMetrics): string;
function IRHotOpcodeText(const ACounts: TIROpcodeCounts;
  AMinimumCount: QWord = 1): string;
function EstimateModuleCodeSize(const AMetrics: TIRModuleMetrics): QWord;
function MetricsAreSane(const AMetrics: TIRModuleMetrics;
  out AReason: string): Boolean;

implementation

function InstructionEstimatedCost(AInstruction: TIRInstruction): LongInt;
begin
  if AInstruction = nil then Exit(0);
  case AInstruction.Opcode of
    iroNop, iroUndef: Result := 0;
    iroConstant, iroParameter, iroCopy: Result := 1;
    iroAdd, iroSub, iroAnd, iroOr, iroXor, iroNeg, iroNot,
    iroLogicalNot, iroICmpEQ, iroICmpNE, iroICmpSLT, iroICmpSLE,
    iroICmpSGT, iroICmpSGE, iroICmpULT, iroICmpULE, iroICmpUGT,
    iroICmpUGE, iroTrunc, iroZExt, iroSExt, iroBitCast,
    iroPtrToInt, iroIntToPtr: Result := 1;
    iroShl, iroAShr, iroLShr: Result := 2;
    iroMul: Result := 3;
    iroSDiv, iroUDiv, iroSRem, iroURem: Result := 12;
    iroAlloca: Result := 1;
    iroLoad, iroStore: Result := 4;
    iroAddressOfGlobal, iroAddressOfFunction, iroGetElementPtr: Result := 2;
    iroPhi, iroSelect: Result := 2;
    iroCall, iroIntrinsic: Result := 8;
    iroBranch, iroCondBranch, iroSwitch: Result := 2;
    iroReturn: Result := 1;
    iroUnreachable: Result := 0;
    iroOpaque: Result := 32;
  else
    Result := 4;
  end;
end;

function MeasureIRFunction(AFunction: TIRFunction): TIRFunctionMetrics;
var
  I, J: LongInt;
  B: TIRBasicBlock;
  Inst: TIRInstruction;
  CFGStats: TCFGStats;
  K: LongInt;
begin


  Result.Name := '';
  Result.Blocks := 0;
  Result.ReachableBlocks := 0;
  Result.Instructions := 0;
  Result.Terminators := 0;
  Result.PhiNodes := 0;
  Result.Calls := 0;
  Result.Loads := 0;
  Result.Stores := 0;
  Result.Branches := 0;
  Result.Values := 0;
  Result.CriticalEdges := 0;
  Result.MaxLoopDepth := 0;
  Result.EstimatedCost := 0;
  FillChar(Result.OpcodeCounts, SizeOf(Result.OpcodeCounts), 0);
  if AFunction = nil then Exit;
  Result.Name := AFunction.Name;
  Result.Blocks := Length(AFunction.Blocks);
  Result.Values := AFunction.ValueCount;
  RebuildControlFlowGraph(AFunction, CFGStats);
  for I := 0 to High(AFunction.Blocks) do
    if Length(AFunction.Blocks[I].Successors) > 1 then
      for K := 0 to High(AFunction.Blocks[I].Successors) do
        if Length(AFunction.BlockByID(
          AFunction.Blocks[I].Successors[K]).Predecessors) > 1 then
          Inc(Result.CriticalEdges);
  for I := 0 to High(AFunction.Blocks) do
  begin
    B := AFunction.Blocks[I];
    if B.Reachable then Inc(Result.ReachableBlocks);
    if B.LoopDepth > Result.MaxLoopDepth then
      Result.MaxLoopDepth := B.LoopDepth;
    for J := 0 to High(B.Instructions) do
    begin
      Inst := B.Instructions[J];
      Inc(Result.Instructions);
      Inc(Result.OpcodeCounts[Inst.Opcode]);
      Inc(Result.EstimatedCost, InstructionEstimatedCost(Inst));
      if Inst.IsTerminator then Inc(Result.Terminators);
      case Inst.Opcode of
        iroPhi: Inc(Result.PhiNodes);
        iroCall, iroIntrinsic: Inc(Result.Calls);
        iroLoad: Inc(Result.Loads);
        iroStore: Inc(Result.Stores);
        iroBranch, iroCondBranch, iroSwitch: Inc(Result.Branches);
      end;
    end;
  end;
end;

function MeasureIRModule(AModule: TIRModule): TIRModuleMetrics;
var
  I: LongInt;
  M: TIRFunctionMetrics;
begin


  Result.Functions := nil;
  Result.Globals := 0;
  Result.GlobalBytes := 0;
  Result.TotalBlocks := 0;
  Result.TotalInstructions := 0;
  Result.TotalValues := 0;
  Result.TotalCalls := 0;
  Result.TotalCriticalEdges := 0;
  Result.HasOpaqueOperations := False;
  if AModule = nil then Exit;
  Result.Globals := Length(AModule.Globals);
  Result.HasOpaqueOperations := AModule.HasOpaqueOperations;
  for I := 0 to High(AModule.Globals) do
    Inc(Result.GlobalBytes, Length(AModule.Globals[I].ConstantData) +
      AModule.Globals[I].ZeroFillSize);
  SetLength(Result.Functions, Length(AModule.Functions));
  for I := 0 to High(AModule.Functions) do
  begin
    M := MeasureIRFunction(AModule.Functions[I]);
    Result.Functions[I] := M;
    Inc(Result.TotalBlocks, M.Blocks);
    Inc(Result.TotalInstructions, M.Instructions);
    Inc(Result.TotalValues, M.Values);
    Inc(Result.TotalCalls, M.Calls);
    Inc(Result.TotalCriticalEdges, M.CriticalEdges);
  end;
end;

function IRHotOpcodeText(const ACounts: TIROpcodeCounts;
  AMinimumCount: QWord): string;
var
  Lines: TStringList;
  Op: TIROpcode;
begin
  Lines := TStringList.Create;
  try
    for Op := Low(TIROpcode) to High(TIROpcode) do
      if ACounts[Op] >= AMinimumCount then
        Lines.Add(Format('    %-24s %d', [IROpcodeName(Op), ACounts[Op]]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function IRFunctionMetricsText(const AMetrics: TIRFunctionMetrics): string;
begin
  Result := Format('%s: blocks=%d reachable=%d instructions=%d values=%d calls=%d cost=%d',
    [AMetrics.Name, AMetrics.Blocks, AMetrics.ReachableBlocks,
     AMetrics.Instructions, AMetrics.Values, AMetrics.Calls,
     AMetrics.EstimatedCost]);
end;

function IRModuleMetricsText(const AMetrics: TIRModuleMetrics): string;
var
  Lines: TStringList;
  I: LongInt;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('IR module metrics');
    Lines.Add('  functions: ' + IntToStr(Length(AMetrics.Functions)));
    Lines.Add('  globals: ' + IntToStr(AMetrics.Globals));
    Lines.Add('  global bytes: ' + IntToStr(AMetrics.GlobalBytes));
    Lines.Add('  blocks: ' + IntToStr(AMetrics.TotalBlocks));
    Lines.Add('  instructions: ' + IntToStr(AMetrics.TotalInstructions));
    Lines.Add('  values: ' + IntToStr(AMetrics.TotalValues));
    Lines.Add('  calls: ' + IntToStr(AMetrics.TotalCalls));
    Lines.Add('  critical edges: ' + IntToStr(AMetrics.TotalCriticalEdges));
    Lines.Add('  opaque operations: ' +
      BoolToStr(AMetrics.HasOpaqueOperations, True));
    for I := 0 to High(AMetrics.Functions) do
      Lines.Add('  ' + IRFunctionMetricsText(AMetrics.Functions[I]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function EstimateModuleCodeSize(const AMetrics: TIRModuleMetrics): QWord;
var
  I: LongInt;
begin
  Result := 0;
  for I := 0 to High(AMetrics.Functions) do
    Inc(Result, AMetrics.Functions[I].EstimatedCost * 4 + 16);
end;

function MetricsAreSane(const AMetrics: TIRModuleMetrics;
  out AReason: string): Boolean;
var
  I: LongInt;
begin
  AReason := '';
  if (Length(AMetrics.Functions) = 0) and (AMetrics.Globals = 0) then
  begin
    AReason := 'module contains no functions or globals';
    Exit(False);
  end;
  for I := 0 to High(AMetrics.Functions) do
  begin
    if AMetrics.Functions[I].Blocks = 0 then
    begin
      AReason := 'function ' + AMetrics.Functions[I].Name + ' has no blocks';
      Exit(False);
    end;
    if AMetrics.Functions[I].Terminators <
       AMetrics.Functions[I].ReachableBlocks then
    begin
      AReason := 'function ' + AMetrics.Functions[I].Name +
        ' has reachable blocks without terminators';
      Exit(False);
    end;
  end;
  Result := True;
end;

end.
