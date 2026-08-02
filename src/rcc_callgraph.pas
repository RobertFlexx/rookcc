unit rcc_callgraph;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_ir;

type
  TCallEdgeKind = (
    cekDirect,
    cekIndirect,
    cekIntrinsic
  );

  TCallEdge = record
    CallerIndex: LongInt;
    CalleeIndex: LongInt;
    CalleeName: string;
    Kind: TCallEdgeKind;
    CallCount: QWord;
  end;
  TCallEdgeArray = array of TCallEdge;

  TCallNode = record
    FunctionIndex: LongInt;
    Name: string;
    IncomingEdges: LongInt;
    OutgoingEdges: LongInt;
    InstructionCount: QWord;
    BlockCount: QWord;
    Recursive: Boolean;
    AddressTaken: Boolean;
    External: Boolean;
  end;
  TCallNodeArray = array of TCallNode;

  TCallGraph = class
  private
    FModule: TIRModule;
    FNodes: TCallNodeArray;
    FEdges: TCallEdgeArray;
    function FunctionIndex(const AName: string): LongInt;
    procedure AddOrIncrementEdge(ACaller, ACallee: LongInt;
      const ACalleeName: string; AKind: TCallEdgeKind);
    procedure MarkRecursiveComponents;
  public
    constructor Create(AModule: TIRModule);
    procedure Build;
    function NodeByName(const AName: string): LongInt;
    function HasPath(AFrom, ATo: LongInt): Boolean;
    function LeafFunction(AIndex: LongInt): Boolean;
    function Dump: string;
    property Nodes: TCallNodeArray read FNodes;
    property Edges: TCallEdgeArray read FEdges;
  end;

implementation

constructor TCallGraph.Create(AModule: TIRModule);
begin
  inherited Create;
  FModule := AModule;
  FNodes := nil;
  FEdges := nil;
end;

function TCallGraph.FunctionIndex(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(FModule.Functions) do
    if FModule.Functions[I].Name = AName then Exit(I);
  Result := -1;
end;

function TCallGraph.NodeByName(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(FNodes) do
    if FNodes[I].Name = AName then Exit(I);
  Result := -1;
end;

procedure TCallGraph.AddOrIncrementEdge(ACaller, ACallee: LongInt;
  const ACalleeName: string; AKind: TCallEdgeKind);
var
  I, N: LongInt;
begin
  for I := 0 to High(FEdges) do
    if (FEdges[I].CallerIndex = ACaller) and
       (FEdges[I].CalleeIndex = ACallee) and
       (FEdges[I].CalleeName = ACalleeName) and
       (FEdges[I].Kind = AKind) then
    begin
      Inc(FEdges[I].CallCount);
      Exit;
    end;
  N := Length(FEdges);
  SetLength(FEdges, N + 1);
  FEdges[N].CallerIndex := ACaller;
  FEdges[N].CalleeIndex := ACallee;
  FEdges[N].CalleeName := ACalleeName;
  FEdges[N].Kind := AKind;
  FEdges[N].CallCount := 1;
end;

procedure TCallGraph.Build;
var
  I, J, K, Callee: LongInt;
  FunctionIR: TIRFunction;
  Instruction: TIRInstruction;
begin
  SetLength(FNodes, Length(FModule.Functions));
  FEdges := nil;
  for I := 0 to High(FModule.Functions) do
  begin
    FunctionIR := FModule.Functions[I];
    FNodes[I].FunctionIndex := I;
    FNodes[I].Name := FunctionIR.Name;
    FNodes[I].IncomingEdges := 0;
    FNodes[I].OutgoingEdges := 0;
    FNodes[I].InstructionCount := 0;
    FNodes[I].BlockCount := Length(FunctionIR.Blocks);
    FNodes[I].Recursive := False;
    FNodes[I].AddressTaken := False;
    FNodes[I].External := Length(FunctionIR.Blocks) = 0;
    for J := 0 to High(FunctionIR.Blocks) do
      for K := 0 to High(FunctionIR.Blocks[J].Instructions) do
      begin
        Instruction := FunctionIR.Blocks[J].Instructions[K];
        Inc(FNodes[I].InstructionCount);
        case Instruction.Opcode of
          iroCall:
            begin
              if Instruction.Symbol = '' then
                AddOrIncrementEdge(I, -1, '<indirect>', cekIndirect)
              else
              begin
                Callee := FunctionIndex(Instruction.Symbol);
                AddOrIncrementEdge(I, Callee, Instruction.Symbol, cekDirect);
              end;
            end;
          iroIntrinsic:
            AddOrIncrementEdge(I, -1, Instruction.Symbol, cekIntrinsic);
          iroAddressOfFunction:
            begin
              Callee := FunctionIndex(Instruction.Symbol);
              if Callee >= 0 then FNodes[Callee].AddressTaken := True;
            end;
        end;
      end;
  end;
  for I := 0 to High(FEdges) do
  begin
    if FEdges[I].CallerIndex >= 0 then
      Inc(FNodes[FEdges[I].CallerIndex].OutgoingEdges);
    if FEdges[I].CalleeIndex >= 0 then
      Inc(FNodes[FEdges[I].CalleeIndex].IncomingEdges);
  end;
  MarkRecursiveComponents;
end;

function TCallGraph.HasPath(AFrom, ATo: LongInt): Boolean;
var
  Queue: array of LongInt;
  Visited: array of Boolean;
  Head, Tail, I, Node: LongInt;
begin
  if (AFrom < 0) or (ATo < 0) or
     (AFrom > High(FNodes)) or (ATo > High(FNodes)) then Exit(False);
  SetLength(Visited, Length(FNodes));
  SetLength(Queue, Length(FNodes));
  Head := 0;
  Tail := 1;
  Queue[0] := AFrom;
  Visited[AFrom] := True;
  while Head < Tail do
  begin
    Node := Queue[Head];
    Inc(Head);
    if Node = ATo then Exit(True);
    for I := 0 to High(FEdges) do
      if (FEdges[I].CallerIndex = Node) and
         (FEdges[I].CalleeIndex >= 0) and
         not Visited[FEdges[I].CalleeIndex] then
      begin
        Visited[FEdges[I].CalleeIndex] := True;
        Queue[Tail] := FEdges[I].CalleeIndex;
        Inc(Tail);
      end;
  end;
  Result := False;
end;

procedure TCallGraph.MarkRecursiveComponents;
var
  I: LongInt;
begin
  for I := 0 to High(FEdges) do
    if (FEdges[I].CalleeIndex >= 0) and
       ((FEdges[I].CallerIndex = FEdges[I].CalleeIndex) or
        HasPath(FEdges[I].CalleeIndex, FEdges[I].CallerIndex)) then
    begin
      FNodes[FEdges[I].CallerIndex].Recursive := True;
      FNodes[FEdges[I].CalleeIndex].Recursive := True;
    end;
end;

function TCallGraph.LeafFunction(AIndex: LongInt): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex <= High(FNodes)) and
    (FNodes[AIndex].OutgoingEdges = 0);
end;

function TCallGraph.Dump: string;
var
  I: LongInt;
begin
  Result := 'call graph' + LineEnding;
  for I := 0 to High(FNodes) do
    Result := Result + Format('  %s blocks=%d inst=%d in=%d out=%d recursive=%s address-taken=%s',
      [FNodes[I].Name, FNodes[I].BlockCount, FNodes[I].InstructionCount,
       FNodes[I].IncomingEdges, FNodes[I].OutgoingEdges,
       BoolToStr(FNodes[I].Recursive, True),
       BoolToStr(FNodes[I].AddressTaken, True)]) + LineEnding;
  for I := 0 to High(FEdges) do
    Result := Result + Format('  edge %d -> %s count=%d',
      [FEdges[I].CallerIndex, FEdges[I].CalleeName,
       FEdges[I].CallCount]) + LineEnding;
end;

end.
