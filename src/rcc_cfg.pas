unit rcc_cfg;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir;

type
  TCFGStats = record
    Blocks: QWord;
    Edges: QWord;
    ReachableBlocks: QWord;
    UnreachableBlocks: QWord;
    BackEdges: QWord;
    NaturalLoops: QWord;
  end;

procedure RebuildControlFlowGraph(AFunction: TIRFunction;
  out AStats: TCFGStats);
procedure ComputeReversePostOrder(AFunction: TIRFunction);
procedure ComputeImmediateDominators(AFunction: TIRFunction);
procedure ComputeLoopDepths(AFunction: TIRFunction; out ALoopCount: QWord);
function Dominates(AFunction: TIRFunction; ADominator,
  ABlock: TIRBlockID): Boolean;
function NearestCommonDominator(AFunction: TIRFunction;
  ALeft, ARight: TIRBlockID): TIRBlockID;
procedure RemoveUnreachableBlocks(AFunction: TIRFunction;
  out ARemoved: QWord);

implementation

procedure AddEdge(AFunction: TIRFunction; AFrom, ATo: TIRBlockID;
  var AStats: TCFGStats);
var
  FromBlock, ToBlock: TIRBasicBlock;
begin
  FromBlock := AFunction.BlockByID(AFrom);
  ToBlock := AFunction.BlockByID(ATo);
  if (FromBlock = nil) or (ToBlock = nil) then
    raise ERCCError.Create('internal error: CFG edge references missing block');
  FromBlock.AddSuccessor(ATo);
  ToBlock.AddPredecessor(AFrom);
  Inc(AStats.Edges);
end;

procedure MarkReachable(AFunction: TIRFunction; ABlockID: TIRBlockID);
var
  B: TIRBasicBlock;
  I: LongInt;
begin
  B := AFunction.BlockByID(ABlockID);
  if (B = nil) or B.Reachable then Exit;
  B.Reachable := True;
  for I := 0 to High(B.Successors) do
    MarkReachable(AFunction, B.Successors[I]);
end;

procedure RebuildControlFlowGraph(AFunction: TIRFunction;
  out AStats: TCFGStats);
var
  I, J: LongInt;
  B: TIRBasicBlock;
  T: TIRInstruction;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  for I := 0 to High(AFunction.Blocks) do
  begin
    AFunction.Blocks[I].ClearEdges;
    AFunction.Blocks[I].Reachable := False;
    Inc(AStats.Blocks);
  end;
  for I := 0 to High(AFunction.Blocks) do
  begin
    B := AFunction.Blocks[I];
    T := B.Terminator;
    if T = nil then Continue;
    case T.Opcode of
      iroBranch:
        AddEdge(AFunction, B.ID, T.TrueBlock, AStats);
      iroCondBranch:
        begin
          AddEdge(AFunction, B.ID, T.TrueBlock, AStats);
          AddEdge(AFunction, B.ID, T.FalseBlock, AStats);
        end;
      iroSwitch:
        begin
          AddEdge(AFunction, B.ID, T.DefaultBlock, AStats);
          for J := 0 to High(T.SwitchCases) do
            AddEdge(AFunction, B.ID, T.SwitchCases[J].TargetBlock, AStats);
        end;
    end;
  end;
  if AFunction.EntryBlock >= 0 then
    MarkReachable(AFunction, AFunction.EntryBlock);
  for I := 0 to High(AFunction.Blocks) do
    if AFunction.Blocks[I].Reachable then Inc(AStats.ReachableBlocks)
    else Inc(AStats.UnreachableBlocks);
  ComputeReversePostOrder(AFunction);
  ComputeImmediateDominators(AFunction);
  ComputeLoopDepths(AFunction, AStats.NaturalLoops);
  for I := 0 to High(AFunction.Blocks) do
    for J := 0 to High(AFunction.Blocks[I].Successors) do
      if Dominates(AFunction, AFunction.Blocks[I].Successors[J],
        AFunction.Blocks[I].ID) then Inc(AStats.BackEdges);
end;

procedure DFSPostOrder(AFunction: TIRFunction; ABlockID: TIRBlockID;
  var AVisited: array of Boolean; var AOrder: TIRBlockIDArray);
var
  B: TIRBasicBlock;
  I, N: LongInt;
begin
  B := AFunction.BlockByID(ABlockID);
  if B = nil then Exit;
  if (B.ID < 0) or (B.ID > High(AVisited)) then Exit;
  if AVisited[B.ID] then Exit;
  AVisited[B.ID] := True;
  for I := 0 to High(B.Successors) do
    DFSPostOrder(AFunction, B.Successors[I], AVisited, AOrder);
  N := Length(AOrder);
  SetLength(AOrder, N + 1);
  AOrder[N] := B.ID;
end;

procedure ComputeReversePostOrder(AFunction: TIRFunction);
var
  MaxID, I, N: LongInt;
  Visited: array of Boolean;
  PostOrder: TIRBlockIDArray;
  B: TIRBasicBlock;
begin
  MaxID := -1;
  for I := 0 to High(AFunction.Blocks) do
    if AFunction.Blocks[I].ID > MaxID then MaxID := AFunction.Blocks[I].ID;
  SetLength(Visited, MaxID + 1);
  SetLength(PostOrder, 0);
  if AFunction.EntryBlock >= 0 then
    DFSPostOrder(AFunction, AFunction.EntryBlock, Visited, PostOrder);
  N := 0;
  for I := High(PostOrder) downto 0 do
  begin
    B := AFunction.BlockByID(PostOrder[I]);
    if B <> nil then
    begin
      B.ReversePostOrder := N;
      Inc(N);
    end;
  end;
  for I := 0 to High(AFunction.Blocks) do
    if not AFunction.Blocks[I].Reachable then
      AFunction.Blocks[I].ReversePostOrder := -1;
end;

function IntersectDominators(AFunction: TIRFunction;
  ALeft, ARight: TIRBlockID): TIRBlockID;
var
  L, R: TIRBasicBlock;
begin
  while ALeft <> ARight do
  begin
    L := AFunction.BlockByID(ALeft);
    R := AFunction.BlockByID(ARight);
    if (L = nil) or (R = nil) then Exit(-1);
    while L.ReversePostOrder > R.ReversePostOrder do
    begin
      ALeft := L.ImmediateDominator;
      L := AFunction.BlockByID(ALeft);
      if L = nil then Exit(-1);
    end;
    while R.ReversePostOrder > L.ReversePostOrder do
    begin
      ARight := R.ImmediateDominator;
      R := AFunction.BlockByID(ARight);
      if R = nil then Exit(-1);
    end;
  end;
  Result := ALeft;
end;

procedure ComputeImmediateDominators(AFunction: TIRFunction);
var
  Changed: Boolean;
  I, J: LongInt;
  B, P: TIRBasicBlock;
  NewIDom: TIRBlockID;
begin
  for I := 0 to High(AFunction.Blocks) do
    AFunction.Blocks[I].ImmediateDominator := -1;
  B := AFunction.BlockByID(AFunction.EntryBlock);
  if B = nil then Exit;
  B.ImmediateDominator := B.ID;
  repeat
    Changed := False;
    for I := 0 to High(AFunction.Blocks) do
    begin
      B := AFunction.Blocks[I];
      if not B.Reachable or (B.ID = AFunction.EntryBlock) then Continue;
      NewIDom := -1;
      for J := 0 to High(B.Predecessors) do
      begin
        P := AFunction.BlockByID(B.Predecessors[J]);
        if (P = nil) or (P.ImmediateDominator < 0) then Continue;
        if NewIDom < 0 then NewIDom := P.ID
        else NewIDom := IntersectDominators(AFunction, P.ID, NewIDom);
      end;
      if B.ImmediateDominator <> NewIDom then
      begin
        B.ImmediateDominator := NewIDom;
        Changed := True;
      end;
    end;
  until not Changed;
end;

function Dominates(AFunction: TIRFunction; ADominator,
  ABlock: TIRBlockID): Boolean;
var
  B: TIRBasicBlock;
  Guard: LongInt;
begin
  Guard := 0;
  while ABlock >= 0 do
  begin
    if ABlock = ADominator then Exit(True);
    B := AFunction.BlockByID(ABlock);
    if (B = nil) or (B.ImmediateDominator = B.ID) then Break;
    ABlock := B.ImmediateDominator;
    Inc(Guard);
    if Guard > Length(AFunction.Blocks) then Break;
  end;
  Result := False;
end;

function NearestCommonDominator(AFunction: TIRFunction;
  ALeft, ARight: TIRBlockID): TIRBlockID;
begin
  if (ALeft < 0) or (ARight < 0) then Exit(-1);
  Result := IntersectDominators(AFunction, ALeft, ARight);
end;

procedure ComputeLoopDepths(AFunction: TIRFunction; out ALoopCount: QWord);
var
  I, J, K: LongInt;
  Header, Tail, B: TIRBasicBlock;
  Work: TIRBlockIDArray;
  Seen: array of Boolean;
  MaxID, N, ID: LongInt;
begin
  ALoopCount := 0;
  MaxID := -1;
  for I := 0 to High(AFunction.Blocks) do
  begin
    AFunction.Blocks[I].LoopDepth := 0;
    if AFunction.Blocks[I].ID > MaxID then MaxID := AFunction.Blocks[I].ID;
  end;
  for I := 0 to High(AFunction.Blocks) do
  begin
    Tail := AFunction.Blocks[I];
    for J := 0 to High(Tail.Successors) do
    begin
      Header := AFunction.BlockByID(Tail.Successors[J]);
      if (Header = nil) or not Dominates(AFunction, Header.ID, Tail.ID) then
        Continue;
      Inc(ALoopCount);
      SetLength(Seen, MaxID + 1);
      SetLength(Work, 1);
      Work[0] := Tail.ID;
      Seen[Header.ID] := True;
      while Length(Work) > 0 do
      begin
        N := High(Work);
        ID := Work[N];
        SetLength(Work, N);
        if (ID < 0) or (ID > High(Seen)) or Seen[ID] then Continue;
        Seen[ID] := True;
        B := AFunction.BlockByID(ID);
        if B = nil then Continue;
        for K := 0 to High(B.Predecessors) do
        begin
          N := Length(Work);
          SetLength(Work, N + 1);
          Work[N] := B.Predecessors[K];
        end;
      end;
      for K := 0 to High(AFunction.Blocks) do
        if Seen[AFunction.Blocks[K].ID] then
          Inc(AFunction.Blocks[K].LoopDepth);
    end;
  end;
end;

procedure RemoveUnreachableBlocks(AFunction: TIRFunction;
  out ARemoved: QWord);
var
  I, N: LongInt;
  NewBlocks: TIRBasicBlockArray;
begin
  ARemoved := 0;
  SetLength(NewBlocks, 0);
  for I := 0 to High(AFunction.Blocks) do
    if AFunction.Blocks[I].Reachable then
    begin
      N := Length(NewBlocks);
      SetLength(NewBlocks, N + 1);
      NewBlocks[N] := AFunction.Blocks[I];
    end
    else
    begin
      AFunction.Blocks[I].Free;
      Inc(ARemoved);
    end;
  AFunction.Blocks := NewBlocks;
end;

end.
