unit rcc_string_pool;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types;

type
  TStringPoolEntry = record
    Text: string;
    Hash: QWord;
    Next: LongInt;
  end;

  TStringPool = class
  private
    FBuckets: array of LongInt;
    FEntries: array of TStringPoolEntry;
    function HashText(const AText: string): QWord;
    procedure Rehash(ANewBucketCount: LongInt);
  public
    constructor Create(AInitialBuckets: LongInt = 256);
    procedure Clear;
    function Intern(const AText: string): LongInt;
    function Find(const AText: string): LongInt;
    function TextAt(AIndex: LongInt): string;
    function Count: LongInt;
    function MemoryBytes: QWord;
  end;

implementation

constructor TStringPool.Create(AInitialBuckets: LongInt);
var
  I: LongInt;
begin
  inherited Create;
  if AInitialBuckets < 16 then AInitialBuckets := 16;
  SetLength(FBuckets, AInitialBuckets);
  for I := 0 to High(FBuckets) do FBuckets[I] := -1;
  SetLength(FEntries, 0);
end;

function TStringPool.HashText(const AText: string): QWord;
var
  I: LongInt;
begin
  Result := QWord($CBF29CE484222325);
  for I := 1 to Length(AText) do
  begin
    Result := Result xor Byte(Ord(AText[I]));
    Result := Result * QWord($100000001B3);
  end;
end;

procedure TStringPool.Rehash(ANewBucketCount: LongInt);
var
  I, Bucket: LongInt;
begin
  if ANewBucketCount < 16 then ANewBucketCount := 16;
  SetLength(FBuckets, ANewBucketCount);
  for I := 0 to High(FBuckets) do FBuckets[I] := -1;
  for I := 0 to High(FEntries) do
  begin
    Bucket := LongInt(FEntries[I].Hash mod QWord(Length(FBuckets)));
    FEntries[I].Next := FBuckets[Bucket];
    FBuckets[Bucket] := I;
  end;
end;

procedure TStringPool.Clear;
var
  I: LongInt;
begin
  SetLength(FEntries, 0);
  for I := 0 to High(FBuckets) do FBuckets[I] := -1;
end;

function TStringPool.Find(const AText: string): LongInt;
var
  Hash: QWord;
  Bucket, Index: LongInt;
begin
  if Length(FBuckets) = 0 then Exit(-1);
  Hash := HashText(AText);
  Bucket := LongInt(Hash mod QWord(Length(FBuckets)));
  Index := FBuckets[Bucket];
  while Index >= 0 do
  begin
    if (FEntries[Index].Hash = Hash) and
      (FEntries[Index].Text = AText) then Exit(Index);
    Index := FEntries[Index].Next;
  end;
  Result := -1;
end;

function TStringPool.Intern(const AText: string): LongInt;
var
  Hash: QWord;
  Bucket, N: LongInt;
begin
  Result := Find(AText);
  if Result >= 0 then Exit;
  if Length(FEntries) * 4 >= Length(FBuckets) * 3 then
    Rehash(Length(FBuckets) * 2);
  Hash := HashText(AText);
  Bucket := LongInt(Hash mod QWord(Length(FBuckets)));
  N := Length(FEntries);
  SetLength(FEntries, N + 1);
  FEntries[N].Text := AText;
  FEntries[N].Hash := Hash;
  FEntries[N].Next := FBuckets[Bucket];
  FBuckets[Bucket] := N;
  Result := N;
end;

function TStringPool.TextAt(AIndex: LongInt): string;
begin
  if (AIndex < 0) or (AIndex > High(FEntries)) then
    raise ERCCError.Create('internal error: string-pool index outside range');
  Result := FEntries[AIndex].Text;
end;

function TStringPool.Count: LongInt;
begin
  Result := Length(FEntries);
end;

function TStringPool.MemoryBytes: QWord;
var
  I: LongInt;
begin
  Result := QWord(Length(FBuckets)) * SizeOf(LongInt) +
    QWord(Length(FEntries)) * SizeOf(TStringPoolEntry);
  for I := 0 to High(FEntries) do Inc(Result, Length(FEntries[I].Text));
end;

end.
