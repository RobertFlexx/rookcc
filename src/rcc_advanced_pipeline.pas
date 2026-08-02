unit rcc_advanced_pipeline;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir;

type
  TAdvancedOptimizationStats = record
    FunctionsProcessed: QWord;
    CFGIterations: QWord;
    ConstantsPropagated: QWord;
    InstructionsCombined: QWord;
    RedundantExpressions: QWord;
    LoopsVisited: QWord;
    InstructionsHoisted: QWord;
    InlineCandidates: QWord;
  end;

procedure RunAdvancedOptimizationPipeline(AModule: TIRModule;
  AOptimizationLevel: LongInt; AOptimizeSize: Boolean;
  out AStats: TAdvancedOptimizationStats);

implementation

uses
  rcc_cfg_cleanup, rcc_sparse_propagation, rcc_instcombine,
  rcc_value_numbering, rcc_licm, rcc_inline_plan;

procedure RunAdvancedOptimizationPipeline(AModule: TIRModule;
  AOptimizationLevel: LongInt; AOptimizeSize: Boolean;
  out AStats: TAdvancedOptimizationStats);
var
  I: LongInt;
  CFGStats: TCFGCleanupStats;
  SparseStats: TSparsePropagationStats;
  CombineStats: TInstCombineStats;
  NumberingStats: TValueNumberingStats;
  LICMStats: TLICMStats;
  Plan: TInlinePlan;
begin
  AStats.FunctionsProcessed := 0;
  AStats.CFGIterations := 0;
  AStats.ConstantsPropagated := 0;
  AStats.InstructionsCombined := 0;
  AStats.RedundantExpressions := 0;
  AStats.LoopsVisited := 0;
  AStats.InstructionsHoisted := 0;
  AStats.InlineCandidates := 0;
  if (AModule = nil) or (AOptimizationLevel <= 0) then Exit;
  for I := 0 to High(AModule.Functions) do
  begin
    if Length(AModule.Functions[I].Blocks) = 0 then Continue;
    Inc(AStats.FunctionsProcessed);
    CleanupControlFlow(AModule.Functions[I], CFGStats);
    Inc(AStats.CFGIterations, CFGStats.Iterations);
    RunSparseConditionalConstantPropagation(AModule.Functions[I], SparseStats);
    Inc(AStats.ConstantsPropagated, SparseStats.InstructionsRewritten);
    CombineInstructions(AModule.Functions[I], CombineStats);
    Inc(AStats.InstructionsCombined, CombineStats.IdentitiesFolded +
      CombineStats.StrengthReductions + CombineStats.CastsCollapsed +
      CombineStats.SelectsFolded);
    RunLocalValueNumbering(AModule.Functions[I], NumberingStats);
    Inc(AStats.RedundantExpressions, NumberingStats.RedundantExpressions);
    if AOptimizationLevel >= 2 then
    begin
      RunLoopInvariantCodeMotion(AModule.Functions[I], LICMStats);
      Inc(AStats.LoopsVisited, LICMStats.LoopsVisited);
      Inc(AStats.InstructionsHoisted, LICMStats.InstructionsHoisted);
    end;
    CleanupControlFlow(AModule.Functions[I], CFGStats);
    Inc(AStats.CFGIterations, CFGStats.Iterations);
  end;
  if AOptimizationLevel >= 2 then
  begin
    Plan := TInlinePlan.Create(AModule, AOptimizationLevel, AOptimizeSize);
    try
      Plan.Build;
      AStats.InlineCandidates := Length(Plan.Candidates);
    finally
      Plan.Free;
    end;
  end;
end;

end.
