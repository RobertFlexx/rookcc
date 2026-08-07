unit rcc_name_index;

{$mode objfpc}{$H+}

interface

type
  { Small deterministic open-addressed string -> integer table.

    RCC uses this for compiler-internal names where lookup dominates and where
    pulling in a heavyweight generic container would add more code and startup
    cost than the table itself.  Values are caller-owned indexes, so the table
    never owns AST or symbol objects. }
  TNameIndex = class
  private
    FKeys: array of string;
    FValues: array of LongInt;
    FStates: array of Byte; { 0 empty, 1 occupied, 2 tombstone }
    FCount: LongInt;
    FDeleted: LongInt;
    function HashName(const AName: string): QWord;
    function FindSlot(const AName: string; AForInsert: Boolean;
      out AFound: Boolean): LongInt;
    procedure Rehash(ANewCapacity: LongInt);
    procedure EnsureInsertCapacity;
  public
    constructor Create(AInitialCapacity: LongInt = 32);
    procedure Clear;
    procedure Put(const AName: string; AValue: LongInt);
    function TryGet(const AName: string; out AValue: LongInt): Boolean;
    function GetOrDefault(const AName: string; ADefault: LongInt): LongInt;
    function Remove(const AName: string): Boolean;
    property Count: LongInt read FCount;
  end;

implementation

function NextPowerOfTwo(AValue: LongInt): LongInt;
begin
  if AValue < 16 then AValue := 16;
  Result := 16;
  while Result < AValue do
  begin
    if Result > (High(LongInt) div 2) then
      Exit(High(LongInt) and not 1);
    Result := Result shl 1;
  end;
end;

constructor TNameIndex.Create(AInitialCapacity: LongInt);
begin
  inherited Create;
  Rehash(NextPowerOfTwo(AInitialCapacity));
end;

function TNameIndex.HashName(const AName: string): QWord;
var
  I: LongInt;
begin
  { FNV-1a.  Keep this local and deterministic; compiler output and diagnostics
    must not depend on a process-randomized hash seed. }
  Result := QWord($CBF29CE484222325);
  for I := 1 to Length(AName) do
  begin
    Result := Result xor Byte(AName[I]);
    Result := Result * QWord($100000001B3);
  end;
  { Avoid poor low-bit distribution for short identifiers before masking. }
  Result := Result xor (Result shr 32);
end;

function TNameIndex.FindSlot(const AName: string; AForInsert: Boolean;
  out AFound: Boolean): LongInt;
var
  Mask, Slot, FirstDeleted: LongInt;
begin
  AFound := False;
  if Length(FStates) = 0 then
  begin
    Result := -1;
    Exit;
  end;
  Mask := Length(FStates) - 1;
  Slot := LongInt(HashName(AName) and QWord(Mask));
  FirstDeleted := -1;
  while True do
  begin
    case FStates[Slot] of
      0:
        begin
          if AForInsert and (FirstDeleted >= 0) then Result := FirstDeleted
          else Result := Slot;
          Exit;
        end;
      1:
        if FKeys[Slot] = AName then
        begin
          AFound := True;
          Result := Slot;
          Exit;
        end;
      2:
        if AForInsert and (FirstDeleted < 0) then FirstDeleted := Slot;
    end;
    Slot := (Slot + 1) and Mask;
  end;
end;

procedure TNameIndex.Rehash(ANewCapacity: LongInt);
var
  OldKeys: array of string;
  OldValues: array of LongInt;
  OldStates: array of Byte;
  I, Slot: LongInt;
  Found: Boolean;
begin
  ANewCapacity := NextPowerOfTwo(ANewCapacity);
  OldKeys := FKeys;
  OldValues := FValues;
  OldStates := FStates;
  SetLength(FKeys, ANewCapacity);
  SetLength(FValues, ANewCapacity);
  SetLength(FStates, ANewCapacity);
  FillChar(FStates[0], Length(FStates) * SizeOf(FStates[0]), 0);
  FCount := 0;
  FDeleted := 0;
  for I := 0 to High(OldStates) do
    if OldStates[I] = 1 then
    begin
      Slot := FindSlot(OldKeys[I], True, Found);
      FStates[Slot] := 1;
      FKeys[Slot] := OldKeys[I];
      FValues[Slot] := OldValues[I];
      Inc(FCount);
    end;
end;

procedure TNameIndex.EnsureInsertCapacity;
begin
  if Length(FStates) = 0 then
    Rehash(32)
  else if ((FCount + FDeleted + 1) * 10 >= Length(FStates) * 7) then
    Rehash(Length(FStates) * 2)
  else if (FDeleted > FCount) and (FDeleted > 32) then
    Rehash(Length(FStates));
end;

procedure TNameIndex.Clear;
begin
  if Length(FStates) <> 0 then
    FillChar(FStates[0], Length(FStates) * SizeOf(FStates[0]), 0);
  FCount := 0;
  FDeleted := 0;
end;

procedure TNameIndex.Put(const AName: string; AValue: LongInt);
var
  Slot: LongInt;
  Found: Boolean;
begin
  EnsureInsertCapacity;
  Slot := FindSlot(AName, True, Found);
  if not Found then
  begin
    if FStates[Slot] = 2 then Dec(FDeleted);
    FStates[Slot] := 1;
    FKeys[Slot] := AName;
    Inc(FCount);
  end;
  FValues[Slot] := AValue;
end;

function TNameIndex.TryGet(const AName: string; out AValue: LongInt): Boolean;
var
  Slot: LongInt;
  Found: Boolean;
begin
  Slot := FindSlot(AName, False, Found);
  Result := Found;
  if Result then AValue := FValues[Slot]
  else AValue := -1;
end;

function TNameIndex.GetOrDefault(const AName: string;
  ADefault: LongInt): LongInt;
begin
  if not TryGet(AName, Result) then Result := ADefault;
end;

function TNameIndex.Remove(const AName: string): Boolean;
var
  Slot: LongInt;
  Found: Boolean;
begin
  Slot := FindSlot(AName, False, Found);
  Result := Found;
  if not Found then Exit;
  FKeys[Slot] := '';
  FValues[Slot] := 0;
  FStates[Slot] := 2;
  Dec(FCount);
  Inc(FDeleted);
end;

end.
