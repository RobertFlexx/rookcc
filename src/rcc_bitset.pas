unit rcc_bitset;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types;

type
  TBitSet = class
  private
    FWords: array of QWord;
    FBitCount: LongInt;
    procedure CheckIndex(AIndex: LongInt);
  public
    constructor Create(ABitCount: LongInt = 0);
    procedure Resize(ABitCount: LongInt);
    procedure Clear;
    procedure Fill;
    procedure Include(AIndex: LongInt);
    procedure Exclude(AIndex: LongInt);
    function Contains(AIndex: LongInt): Boolean;
    function IsEmpty: Boolean;
    function Count: LongInt;
    function FirstSet: LongInt;
    function NextSet(AAfter: LongInt): LongInt;
    procedure Assign(AOther: TBitSet);
    procedure UnionWith(AOther: TBitSet);
    procedure IntersectWith(AOther: TBitSet);
    procedure Subtract(AOther: TBitSet);
    function Equals(AOther: TBitSet): Boolean; reintroduce;
    function Clone: TBitSet;
    function ToText: string;
    property BitCount: LongInt read FBitCount;
  end;

implementation

function PopCount64(AValue: QWord): LongInt;
begin
  Result := 0;
  while AValue <> 0 do
  begin
    AValue := AValue and (AValue - 1);
    Inc(Result);
  end;
end;

constructor TBitSet.Create(ABitCount: LongInt);
begin
  inherited Create;
  FBitCount := 0;
  Resize(ABitCount);
end;

procedure TBitSet.CheckIndex(AIndex: LongInt);
begin
  if (AIndex < 0) or (AIndex >= FBitCount) then
    raise ERCCError.CreateFmt('internal error: bit index %d outside 0..%d',
      [AIndex, FBitCount - 1]);
end;

procedure TBitSet.Resize(ABitCount: LongInt);
var
  OldWords, NewWords, I: LongInt;
begin
  if ABitCount < 0 then
    raise ERCCError.Create('internal error: negative bit-set size');
  OldWords := Length(FWords);
  NewWords := (ABitCount + 63) div 64;
  SetLength(FWords, NewWords);
  for I := OldWords to NewWords - 1 do FWords[I] := 0;
  FBitCount := ABitCount;
  if (NewWords > 0) and ((ABitCount and 63) <> 0) then
    FWords[NewWords - 1] := FWords[NewWords - 1] and
      ((QWord(1) shl (ABitCount and 63)) - 1);
end;

procedure TBitSet.Clear;
var
  I: LongInt;
begin
  for I := 0 to High(FWords) do FWords[I] := 0;
end;

procedure TBitSet.Fill;
var
  I: LongInt;
begin
  for I := 0 to High(FWords) do FWords[I] := High(QWord);
  if (Length(FWords) > 0) and ((FBitCount and 63) <> 0) then
    FWords[High(FWords)] := (QWord(1) shl (FBitCount and 63)) - 1;
end;

procedure TBitSet.Include(AIndex: LongInt);
begin
  CheckIndex(AIndex);
  FWords[AIndex shr 6] := FWords[AIndex shr 6] or
    (QWord(1) shl (AIndex and 63));
end;

procedure TBitSet.Exclude(AIndex: LongInt);
begin
  CheckIndex(AIndex);
  FWords[AIndex shr 6] := FWords[AIndex shr 6] and
    not (QWord(1) shl (AIndex and 63));
end;

function TBitSet.Contains(AIndex: LongInt): Boolean;
begin
  CheckIndex(AIndex);
  Result := (FWords[AIndex shr 6] and
    (QWord(1) shl (AIndex and 63))) <> 0;
end;

function TBitSet.IsEmpty: Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(FWords) do
    if FWords[I] <> 0 then Exit(False);
  Result := True;
end;

function TBitSet.Count: LongInt;
var
  I: LongInt;
begin
  Result := 0;
  for I := 0 to High(FWords) do Inc(Result, PopCount64(FWords[I]));
end;

function TBitSet.FirstSet: LongInt;
begin
  Result := NextSet(-1);
end;

function TBitSet.NextSet(AAfter: LongInt): LongInt;
var
  I: LongInt;
begin
  I := AAfter + 1;
  while I < FBitCount do
  begin
    if Contains(I) then Exit(I);
    Inc(I);
  end;
  Result := -1;
end;

procedure TBitSet.Assign(AOther: TBitSet);
var
  I: LongInt;
begin
  if AOther = nil then begin Resize(0); Exit; end;
  Resize(AOther.FBitCount);
  for I := 0 to High(FWords) do FWords[I] := AOther.FWords[I];
end;

procedure TBitSet.UnionWith(AOther: TBitSet);
var
  I: LongInt;
begin
  if AOther = nil then Exit;
  if AOther.FBitCount > FBitCount then Resize(AOther.FBitCount);
  for I := 0 to High(AOther.FWords) do
    FWords[I] := FWords[I] or AOther.FWords[I];
end;

procedure TBitSet.IntersectWith(AOther: TBitSet);
var
  I: LongInt;
begin
  if AOther = nil then begin Clear; Exit; end;
  for I := 0 to High(FWords) do
    if I <= High(AOther.FWords) then
      FWords[I] := FWords[I] and AOther.FWords[I]
    else
      FWords[I] := 0;
end;

procedure TBitSet.Subtract(AOther: TBitSet);
var
  I: LongInt;
begin
  if AOther = nil then Exit;
  for I := 0 to High(FWords) do
    if I <= High(AOther.FWords) then
      FWords[I] := FWords[I] and not AOther.FWords[I];
end;

function TBitSet.Equals(AOther: TBitSet): Boolean;
var
  I, Maximum: LongInt;
  LeftWord, RightWord: QWord;
begin
  if AOther = nil then Exit(IsEmpty);
  Maximum := Length(FWords);
  if Length(AOther.FWords) > Maximum then Maximum := Length(AOther.FWords);
  for I := 0 to Maximum - 1 do
  begin
    if I <= High(FWords) then LeftWord := FWords[I] else LeftWord := 0;
    if I <= High(AOther.FWords) then RightWord := AOther.FWords[I]
    else RightWord := 0;
    if LeftWord <> RightWord then Exit(False);
  end;
  Result := True;
end;

function TBitSet.Clone: TBitSet;
begin
  Result := TBitSet.Create;
  Result.Assign(Self);
end;

function TBitSet.ToText: string;
var
  I: LongInt;
  First: Boolean;
begin
  Result := '{';
  First := True;
  I := FirstSet;
  while I >= 0 do
  begin
    if not First then Result := Result + ',';
    Result := Result + IntToStr(I);
    First := False;
    I := NextSet(I);
  end;
  Result := Result + '}';
end;

end.
