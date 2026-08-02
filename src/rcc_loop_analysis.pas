unit rcc_loop_analysis;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir, rcc_cfg, rcc_bitset;

type
  TLoopDescriptor = class
  public
    Header: TIRBlockID;
    Latches: TIRBlockIDArray;
    Blocks: TBitSet;
    ParentLoop: LongInt;
    Depth: LongInt;
    Preheader: TIRBlockID;
    ExitBlocks: TIRBlockIDArray;
    DedicatedExits: Boolean;
    Irreducible: Boolean;
    constructor Create(ABlockUniverse: LongInt);
    destructor Destroy; override;
    procedure AddLatch(ABlock: TIRBlockID);
    procedure AddExit(ABlock: TIRBlockID);
    function Contains(ABlock: TIRBlockID): Boolean;
    function BlockCount: LongInt;
  end;
  TLoopDescriptorArray = array of TLoopDescriptor;

  TLoopForest = class
  private
    FFunction: TIRFunction;
    FLoops: TLoopDescriptorArray;
    function MaximumBlockID: LongInt;
    function FindLoopByHeader(AHeader: TIRBlockID): LongInt;
    procedure DiscoverNaturalLoop(ATail, AHeader: TIRBlockID);
    procedure ComputeNesting;
    procedure ComputeLoopMetadata(ALoop: TLoopDescriptor);
  public
    constructor Create(AFunction: TIRFunction);
    destructor Destroy; override;
    procedure Build;
    function InnermostLoopForBlock(ABlock: TIRBlockID): LongInt;
    function IsLoopInvariantValue(ALoopIndex: LongInt;
      AValue: TIRValue): Boolean;
    function Dump: string;
    property Loops: TLoopDescriptorArray read FLoops;
  end;

implementation

constructor TLoopDescriptor.Create(ABlockUniverse: LongInt);
begin
  inherited Create;
  Header := -1;
  Latches := nil;
  Blocks := TBitSet.Create(ABlockUniverse);
  ParentLoop := -1;
  Depth := 1;
  Preheader := -1;
  ExitBlocks := nil;
  DedicatedExits := False;
  Irreducible := False;
end;

destructor TLoopDescriptor.Destroy;
begin
  Blocks.Free;
  inherited Destroy;
end;

procedure AppendUniqueBlock(var AValues: TIRBlockIDArray; AValue: TIRBlockID);
var
  I, N: LongInt;
begin
  for I := 0 to High(AValues) do if AValues[I] = AValue then Exit;
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

procedure TLoopDescriptor.AddLatch(ABlock: TIRBlockID);
begin
  AppendUniqueBlock(Latches, ABlock);
end;

procedure TLoopDescriptor.AddExit(ABlock: TIRBlockID);
begin
  AppendUniqueBlock(ExitBlocks, ABlock);
end;

function TLoopDescriptor.Contains(ABlock: TIRBlockID): Boolean;
begin
  Result := (ABlock >= 0) and (ABlock < Blocks.BitCount) and
    Blocks.Contains(ABlock);
end;

function TLoopDescriptor.BlockCount: LongInt;
begin
  Result := Blocks.Count;
end;

constructor TLoopForest.Create(AFunction: TIRFunction);
begin
  inherited Create;
  FFunction := AFunction;
  FLoops := nil;
end;

destructor TLoopForest.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(FLoops) do FLoops[I].Free;
  inherited Destroy;
end;

function TLoopForest.MaximumBlockID: LongInt;
var
  I: LongInt;
begin
  Result := -1;
  for I := 0 to High(FFunction.Blocks) do
    if FFunction.Blocks[I].ID > Result then Result := FFunction.Blocks[I].ID;
end;

function TLoopForest.FindLoopByHeader(AHeader: TIRBlockID): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(FLoops) do
    if FLoops[I].Header = AHeader then Exit(I);
  Result := -1;
end;

procedure TLoopForest.DiscoverNaturalLoop(ATail, AHeader: TIRBlockID);
var
  Index, N, Head, BlockID, I: LongInt;
  Work: TIRBlockIDArray;
  Block: TIRBasicBlock;
  LoopInfo: TLoopDescriptor;
begin
  Index := FindLoopByHeader(AHeader);
  if Index < 0 then
  begin
    N := Length(FLoops);
    SetLength(FLoops, N + 1);
    FLoops[N] := TLoopDescriptor.Create(MaximumBlockID + 1);
    FLoops[N].Header := AHeader;
    Index := N;
  end;
  LoopInfo := FLoops[Index];
  LoopInfo.AddLatch(ATail);
  LoopInfo.Blocks.Include(AHeader);
  LoopInfo.Blocks.Include(ATail);
  Work := nil;
  SetLength(Work, 1);
  Work[0] := ATail;
  Head := 0;
  while Head < Length(Work) do
  begin
    BlockID := Work[Head];
    Inc(Head);
    Block := FFunction.BlockByID(BlockID);
    if Block = nil then Continue;
    for I := 0 to High(Block.Predecessors) do
      if not LoopInfo.Blocks.Contains(Block.Predecessors[I]) then
      begin
        LoopInfo.Blocks.Include(Block.Predecessors[I]);
        N := Length(Work);
        SetLength(Work, N + 1);
        Work[N] := Block.Predecessors[I];
      end;
  end;
end;

procedure TLoopForest.ComputeLoopMetadata(ALoop: TLoopDescriptor);
var
  BlockID, I, OutsidePredCount: LongInt;
  Block, HeaderBlock, ExitBlock: TIRBasicBlock;
  CandidatePreheader: TIRBlockID;
begin
  HeaderBlock := FFunction.BlockByID(ALoop.Header);
  CandidatePreheader := -1;
  OutsidePredCount := 0;
  if HeaderBlock <> nil then
    for I := 0 to High(HeaderBlock.Predecessors) do
      if not ALoop.Contains(HeaderBlock.Predecessors[I]) then
      begin
        CandidatePreheader := HeaderBlock.Predecessors[I];
        Inc(OutsidePredCount);
      end;
  if OutsidePredCount = 1 then ALoop.Preheader := CandidatePreheader;
  BlockID := ALoop.Blocks.FirstSet;
  while BlockID >= 0 do
  begin
    Block := FFunction.BlockByID(BlockID);
    if Block <> nil then
      for I := 0 to High(Block.Successors) do
        if not ALoop.Contains(Block.Successors[I]) then
          ALoop.AddExit(Block.Successors[I]);
    BlockID := ALoop.Blocks.NextSet(BlockID);
  end;
  ALoop.DedicatedExits := True;
  for I := 0 to High(ALoop.ExitBlocks) do
  begin
    ExitBlock := FFunction.BlockByID(ALoop.ExitBlocks[I]);
    if ExitBlock = nil then Continue;
    for BlockID := 0 to High(ExitBlock.Predecessors) do
      if not ALoop.Contains(ExitBlock.Predecessors[BlockID]) then
        ALoop.DedicatedExits := False;
  end;
end;

procedure TLoopForest.ComputeNesting;
var
  I, J: LongInt;
  Candidate: TLoopDescriptor;
begin
  for I := 0 to High(FLoops) do
  begin
    FLoops[I].ParentLoop := -1;
    FLoops[I].Depth := 1;
    for J := 0 to High(FLoops) do
    begin
      if I = J then Continue;
      Candidate := FLoops[J];
      if Candidate.Contains(FLoops[I].Header) and
         (Candidate.BlockCount > FLoops[I].BlockCount) and
         ((FLoops[I].ParentLoop < 0) or
          (Candidate.BlockCount < FLoops[FLoops[I].ParentLoop].BlockCount)) then
        FLoops[I].ParentLoop := J;
    end;
  end;
  for I := 0 to High(FLoops) do
  begin
    J := FLoops[I].ParentLoop;
    while J >= 0 do
    begin
      Inc(FLoops[I].Depth);
      J := FLoops[J].ParentLoop;
    end;
  end;
end;

procedure TLoopForest.Build;
var
  Stats: TCFGStats;
  I, J: LongInt;
begin
  for I := 0 to High(FLoops) do FLoops[I].Free;
  FLoops := nil;
  RebuildControlFlowGraph(FFunction, Stats);
  for I := 0 to High(FFunction.Blocks) do
    for J := 0 to High(FFunction.Blocks[I].Successors) do
      if Dominates(FFunction, FFunction.Blocks[I].Successors[J],
        FFunction.Blocks[I].ID) then
        DiscoverNaturalLoop(FFunction.Blocks[I].ID,
          FFunction.Blocks[I].Successors[J]);
  ComputeNesting;
  for I := 0 to High(FLoops) do ComputeLoopMetadata(FLoops[I]);
end;

function TLoopForest.InnermostLoopForBlock(ABlock: TIRBlockID): LongInt;
var
  I: LongInt;
begin
  Result := -1;
  for I := 0 to High(FLoops) do
    if FLoops[I].Contains(ABlock) and
       ((Result < 0) or (FLoops[I].Depth > FLoops[Result].Depth)) then
      Result := I;
end;

function TLoopForest.IsLoopInvariantValue(ALoopIndex: LongInt;
  AValue: TIRValue): Boolean;
var
  Definition: TIRValueDefinition;
begin
  if (ALoopIndex < 0) or (ALoopIndex > High(FLoops)) then Exit(False);
  if (AValue < 0) or (AValue > High(FFunction.ValueDefinitions)) then
    Exit(False);
  Definition := FFunction.ValueDefinitions[AValue];
  Result := Definition.IsParameter or (Definition.DefiningBlock < 0) or
    not FLoops[ALoopIndex].Contains(Definition.DefiningBlock);
end;

function TLoopForest.Dump: string;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to High(FLoops) do
    Result := Result + Format('loop %d header=bb%d depth=%d blocks=%s preheader=bb%d exits=%d',
      [I, FLoops[I].Header, FLoops[I].Depth,
       FLoops[I].Blocks.ToText, FLoops[I].Preheader,
       Length(FLoops[I].ExitBlocks)]) + LineEnding;
end;

end.
