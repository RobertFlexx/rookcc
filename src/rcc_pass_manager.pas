unit rcc_pass_manager;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir, rcc_arch, rcc_ir_lower,
  rcc_ir_opt, rcc_liveness, rcc_regalloc, rcc_advanced_pipeline;

type
  TPassPipelineKind = (
    ppkO0,
    ppkO1,
    ppkO2,
    ppkO3,
    ppkOs,
    ppkOz
  );

  TPassManagerStats = record
    Lowering: TIRLoweringStats;
    Optimization: TIROptimizationStats;
    AdvancedOptimization: TAdvancedOptimizationStats;
    FunctionsAnalyzed: QWord;
    ValuesAnalyzed: QWord;
    StackBytesPlanned: QWord;
  end;

  TPassManager = class
  private
    FTarget: TTargetDescriptor;
    FOptimizationLevel: LongInt;
    FOptimizeSize: Boolean;
    FModule: TIRModule;
    FStats: TPassManagerStats;
  public
    constructor Create(const ATarget: TTargetDescriptor;
      AOptimizationLevel: LongInt; AOptimizeSize: Boolean);
    destructor Destroy; override;
    function Build(AProgram: TProgram): TIRModule;
    procedure RunAnalysis;
    function PipelineName: string;
    property Module: TIRModule read FModule;
    property Stats: TPassManagerStats read FStats;
  end;

function PipelineKind(AOptimizationLevel: LongInt;
  AOptimizeSize: Boolean): TPassPipelineKind;
function PipelineKindName(AKind: TPassPipelineKind): string;

implementation

function PipelineKind(AOptimizationLevel: LongInt;
  AOptimizeSize: Boolean): TPassPipelineKind;
begin
  if AOptimizeSize then
  begin
    if AOptimizationLevel >= 3 then Result := ppkOz else Result := ppkOs;
    Exit;
  end;
  case AOptimizationLevel of
    0: Result := ppkO0;
    1: Result := ppkO1;
    2: Result := ppkO2;
  else
    Result := ppkO3;
  end;
end;

function PipelineKindName(AKind: TPassPipelineKind): string;
begin
  case AKind of
    ppkO0: Result := 'O0';
    ppkO1: Result := 'O1';
    ppkO2: Result := 'O2';
    ppkO3: Result := 'O3';
    ppkOs: Result := 'Os';
    ppkOz: Result := 'Oz';
  else
    Result := 'unknown';
  end;
end;

constructor TPassManager.Create(const ATarget: TTargetDescriptor;
  AOptimizationLevel: LongInt; AOptimizeSize: Boolean);
begin
  inherited Create;
  FTarget := ATarget;
  FOptimizationLevel := AOptimizationLevel;
  FOptimizeSize := AOptimizeSize;
  FModule := nil;
  FillChar(FStats, SizeOf(FStats), 0);
end;

destructor TPassManager.Destroy;
begin
  FModule.Free;
  inherited Destroy;
end;

function TPassManager.Build(AProgram: TProgram): TIRModule;
begin
  FModule.Free;
  FModule := LowerProgramToIR(AProgram, FTarget.Triple, FStats.Lowering);
  OptimizeIRModule(FModule, FOptimizationLevel,
    FOptimizeSize, FStats.Optimization);
  if FOptimizationLevel >= 2 then
    RunAdvancedOptimizationPipeline(FModule, FOptimizationLevel,
      FOptimizeSize, FStats.AdvancedOptimization);
  Result := FModule;
end;

procedure TPassManager.RunAnalysis;
var
  I: LongInt;
  Liveness: TLivenessResult;
  Allocation: TRegisterAllocation;
begin
  if FModule = nil then
    raise ERCCError.Create('internal error: pass manager has no IR module');
  Liveness.Blocks := nil;
  Liveness.Intervals := nil;
  Liveness.InstructionCount := 0;
  Liveness.ValueCount := 0;
  try
    for I := 0 to High(FModule.Functions) do
    begin
      if Length(FModule.Functions[I].Blocks) = 0 then Continue;
      ComputeLiveness(FModule.Functions[I], Liveness);
      Allocation := AllocateRegistersLinearScan(FModule.Functions[I],
        FTarget, Liveness);
      try
        Inc(FStats.FunctionsAnalyzed);
        Inc(FStats.ValuesAnalyzed, FModule.Functions[I].ValueCount);
        Inc(FStats.StackBytesPlanned, Allocation.StackFrameBytes);
      finally
        Allocation.Free;
      end;
    end;
  finally
    SetLength(Liveness.Blocks, 0);
    SetLength(Liveness.Intervals, 0);
  end;

end;

function TPassManager.PipelineName: string;
begin
  Result := PipelineKindName(PipelineKind(FOptimizationLevel,
    FOptimizeSize));
end;

end.
