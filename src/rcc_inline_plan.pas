unit rcc_inline_plan;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir, rcc_callgraph;

type
  TInlineDecision = (
    idNever,
    idUnprofitable,
    idProfitable,
    idAlways
  );

  TInlineCandidate = record
    CallerIndex: LongInt;
    CalleeIndex: LongInt;
    CallCount: QWord;
    EstimatedCost: LongInt;
    EstimatedSavings: LongInt;
    Decision: TInlineDecision;
    Reason: string;
  end;
  TInlineCandidateArray = array of TInlineCandidate;

  TInlinePlan = class
  private
    FModule: TIRModule;
    FGraph: TCallGraph;
    FCandidates: TInlineCandidateArray;
    FOptimizationLevel: LongInt;
    FOptimizeSize: Boolean;
    function FunctionCost(AFunction: TIRFunction): LongInt;
    function CallOverhead(AFunction: TIRFunction): LongInt;
    procedure AddCandidate(const ACandidate: TInlineCandidate);
  public
    constructor Create(AModule: TIRModule; AOptimizationLevel: LongInt;
      AOptimizeSize: Boolean);
    destructor Destroy; override;
    procedure Build;
    function Dump: string;
    property Candidates: TInlineCandidateArray read FCandidates;
  end;

function InlineDecisionName(ADecision: TInlineDecision): string;

implementation

function InlineDecisionName(ADecision: TInlineDecision): string;
begin
  case ADecision of
    idNever: Result := 'never';
    idUnprofitable: Result := 'unprofitable';
    idProfitable: Result := 'profitable';
    idAlways: Result := 'always';
  else
    Result := 'invalid';
  end;
end;

constructor TInlinePlan.Create(AModule: TIRModule;
  AOptimizationLevel: LongInt; AOptimizeSize: Boolean);
begin
  inherited Create;
  FModule := AModule;
  FOptimizationLevel := AOptimizationLevel;
  FOptimizeSize := AOptimizeSize;
  FGraph := TCallGraph.Create(AModule);
  FCandidates := nil;
end;

destructor TInlinePlan.Destroy;
begin
  FGraph.Free;
  inherited Destroy;
end;

function TInlinePlan.FunctionCost(AFunction: TIRFunction): LongInt;
var
  I, J: LongInt;
  Instruction: TIRInstruction;
begin
  Result := 0;
  for I := 0 to High(AFunction.Blocks) do
    for J := 0 to High(AFunction.Blocks[I].Instructions) do
    begin
      Instruction := AFunction.Blocks[I].Instructions[J];
      case Instruction.Opcode of
        iroCall, iroIntrinsic: Inc(Result, 8);
        iroSDiv, iroUDiv, iroSRem, iroURem, iroFDiv: Inc(Result, 5);
        iroSwitch: Inc(Result, 2 + Length(Instruction.SwitchCases));
        iroLoad, iroStore: Inc(Result, 2);
      else
        Inc(Result);
      end;
    end;
end;

function TInlinePlan.CallOverhead(AFunction: TIRFunction): LongInt;
begin
  Result := 5 + Length(AFunction.Parameters);
  if AFunction.Variadic then Inc(Result, 8);
end;

procedure TInlinePlan.AddCandidate(const ACandidate: TInlineCandidate);
var
  N: LongInt;
begin
  N := Length(FCandidates);
  SetLength(FCandidates, N + 1);
  FCandidates[N] := ACandidate;
end;

procedure TInlinePlan.Build;
var
  I: LongInt;
  Edge: TCallEdge;
  Candidate: TInlineCandidate;
  Callee: TIRFunction;
  Threshold, Cost: LongInt;
begin
  FCandidates := nil;
  FGraph.Build;
  case FOptimizationLevel of
    0: Threshold := 0;
    1: Threshold := 18;
    2: Threshold := 45;
  else
    Threshold := 100;
  end;
  if FOptimizeSize then Threshold := Threshold div 2;
  for I := 0 to High(FGraph.Edges) do
  begin
    Edge := FGraph.Edges[I];
    if Edge.Kind <> cekDirect then Continue;
    Candidate.CallerIndex := Edge.CallerIndex;
    Candidate.CalleeIndex := Edge.CalleeIndex;
    Candidate.CallCount := Edge.CallCount;
    Candidate.EstimatedCost := High(LongInt);
    Candidate.EstimatedSavings := 0;
    Candidate.Decision := idNever;
    Candidate.Reason := 'external or unresolved callee';
    if (Edge.CalleeIndex >= 0) and
       (Edge.CalleeIndex <= High(FModule.Functions)) then
    begin
      Callee := FModule.Functions[Edge.CalleeIndex];
      Cost := FunctionCost(Callee);
      Candidate.EstimatedCost := Cost;
      Candidate.EstimatedSavings := CallOverhead(Callee) * Edge.CallCount;
      if FGraph.Nodes[Edge.CalleeIndex].Recursive then
      begin
        Candidate.Decision := idNever;
        Candidate.Reason := 'recursive call graph component';
      end
      else if FGraph.Nodes[Edge.CalleeIndex].AddressTaken then
      begin
        Candidate.Decision := idUnprofitable;
        Candidate.Reason := 'address-taken function retained out-of-line';
      end
      else if Cost <= 4 then
      begin
        Candidate.Decision := idAlways;
        Candidate.Reason := 'tiny leaf function';
      end
      else if Cost <= Threshold then
      begin
        Candidate.Decision := idProfitable;
        Candidate.Reason := 'within optimization threshold';
      end
      else
      begin
        Candidate.Decision := idUnprofitable;
        Candidate.Reason := 'code growth exceeds threshold';
      end;
    end;
    AddCandidate(Candidate);
  end;
end;

function TInlinePlan.Dump: string;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to High(FCandidates) do
    Result := Result + Format('inline caller=%d callee=%d decision=%s cost=%d savings=%d reason=%s',
      [FCandidates[I].CallerIndex, FCandidates[I].CalleeIndex,
       InlineDecisionName(FCandidates[I].Decision),
       FCandidates[I].EstimatedCost, FCandidates[I].EstimatedSavings,
       FCandidates[I].Reason]) + LineEnding;
end;

end.
