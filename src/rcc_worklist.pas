unit rcc_worklist;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;

type
  TIntWorkList = class
  private
    FItems: array of LongInt;
    FPresent: array of Boolean;
    FHead: LongInt;
    FTail: LongInt;
    FCount: LongInt;
    procedure Grow;
    procedure EnsurePresenceSize(AValue: LongInt);
  public
    constructor Create(AUniverseSize: LongInt = 0);
    procedure Clear;
    procedure Push(AValue: LongInt);
    function Pop(out AValue: LongInt): Boolean;
    function Contains(AValue: LongInt): Boolean;
    function IsEmpty: Boolean;
    property Count: LongInt read FCount;
  end;

implementation

constructor TIntWorkList.Create(AUniverseSize: LongInt);
begin
  inherited Create;
  SetLength(FItems, 16);
  if AUniverseSize < 0 then AUniverseSize := 0;
  SetLength(FPresent, AUniverseSize);
  FHead := 0;
  FTail := 0;
  FCount := 0;
end;

procedure TIntWorkList.Grow;
var
  Old, I: LongInt;
  NewItems: array of LongInt;
begin
  Old := Length(FItems);
  if Old < 16 then Old := 16;
  SetLength(NewItems, Old * 2);
  for I := 0 to FCount - 1 do
    NewItems[I] := FItems[(FHead + I) mod Length(FItems)];
  FItems := NewItems;
  FHead := 0;
  FTail := FCount;
end;

procedure TIntWorkList.EnsurePresenceSize(AValue: LongInt);
var
  Old, I, NewSize: LongInt;
begin
  if AValue < 0 then
    raise ERCCError.Create('internal error: negative work-list value');
  if AValue < Length(FPresent) then Exit;
  Old := Length(FPresent);
  NewSize := Old;
  if NewSize < 16 then NewSize := 16;
  while NewSize <= AValue do NewSize := NewSize * 2;
  SetLength(FPresent, NewSize);
  for I := Old to NewSize - 1 do FPresent[I] := False;
end;

procedure TIntWorkList.Clear;
var
  I: LongInt;
begin
  for I := 0 to High(FPresent) do FPresent[I] := False;
  FHead := 0;
  FTail := 0;
  FCount := 0;
end;

procedure TIntWorkList.Push(AValue: LongInt);
begin
  EnsurePresenceSize(AValue);
  if FPresent[AValue] then Exit;
  if FCount = Length(FItems) then Grow;
  FItems[FTail] := AValue;
  FTail := (FTail + 1) mod Length(FItems);
  Inc(FCount);
  FPresent[AValue] := True;
end;

function TIntWorkList.Pop(out AValue: LongInt): Boolean;
begin
  if FCount = 0 then Exit(False);
  AValue := FItems[FHead];
  FHead := (FHead + 1) mod Length(FItems);
  Dec(FCount);
  if (AValue >= 0) and (AValue < Length(FPresent)) then
    FPresent[AValue] := False;
  Result := True;
end;

function TIntWorkList.Contains(AValue: LongInt): Boolean;
begin
  Result := (AValue >= 0) and (AValue < Length(FPresent)) and
    FPresent[AValue];
end;

function TIntWorkList.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

end.
