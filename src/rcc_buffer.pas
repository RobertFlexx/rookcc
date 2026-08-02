unit rcc_buffer;

{$mode objfpc}{$H+}

interface

uses
  Classes, rcc_types;

type


  TByteBuffer = class
  private
    FData: array of Byte;
    FUsed: LongInt;
    FCapacity: LongInt;
    procedure Grow(ANeeded: LongInt);
  public
    function Size: LongInt;
    function ByteAt(AIndex: LongInt): Byte;
    procedure Clear;
    procedure Add8(V: Byte);
    procedure Add16(V: Word);
    procedure Add32(V: LongWord);
    procedure Add64(V: QWord);
    procedure AddI32(V: LongInt);
    procedure AddBytes(const A: array of Byte);
    procedure AddStringZ(const S: string);
    procedure Patch8(AOffset: LongInt; V: Byte);
    procedure Patch16(AOffset: LongInt; V: Word);
    procedure Patch32(AOffset: LongInt; V: LongInt);
    procedure Patch64(AOffset: LongInt; V: QWord);
    procedure DeleteBytes(AOffset, ACount: LongInt);
    procedure InsertBytes(AOffset: LongInt; const A: array of Byte);
    procedure PadTo(ABoundary: LongInt);
    procedure Append(Other: TByteBuffer);
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
  end;

implementation

procedure TByteBuffer.Grow(ANeeded: LongInt);
var
  NewCapacity: LongInt;
begin
  if FCapacity - FUsed >= ANeeded then Exit;
  NewCapacity := FCapacity;
  if NewCapacity < 256 then NewCapacity := 256;
  while NewCapacity - FUsed < ANeeded do NewCapacity := NewCapacity * 2;
  SetLength(FData, NewCapacity);
  FCapacity := NewCapacity;
end;

function TByteBuffer.Size: LongInt;
begin
  Result := FUsed;
end;

function TByteBuffer.ByteAt(AIndex: LongInt): Byte;
begin
  if (AIndex < 0) or (AIndex >= FUsed) then
    raise ERCCError.Create('internal error: byte index outside buffer');
  Result := FData[AIndex];
end;

procedure TByteBuffer.Clear;
begin
  FUsed := 0;
  FCapacity := 0;
  SetLength(FData, 0);
end;

procedure TByteBuffer.Add8(V: Byte);
begin
  Grow(1);
  FData[FUsed] := V;
  Inc(FUsed);
end;

procedure TByteBuffer.Add16(V: Word);
begin
  Add8(Byte(V));
  Add8(Byte(V shr 8));
end;

procedure TByteBuffer.Add32(V: LongWord);
begin
  Add8(Byte(V));
  Add8(Byte(V shr 8));
  Add8(Byte(V shr 16));
  Add8(Byte(V shr 24));
end;

procedure TByteBuffer.Add64(V: QWord);
begin
  Add32(LongWord(V));
  Add32(LongWord(V shr 32));
end;

procedure TByteBuffer.AddI32(V: LongInt);
begin
  Add32(LongWord(V));
end;

procedure TByteBuffer.AddBytes(const A: array of Byte);
var
  I, N: LongInt;
begin
  N := Length(A);
  Grow(N);
  for I := 0 to N - 1 do FData[FUsed + I] := A[I];
  Inc(FUsed, N);
end;

procedure TByteBuffer.AddStringZ(const S: string);
var
  I, N: LongInt;
begin
  N := Length(S);
  Grow(N + 1);
  for I := 1 to N do FData[FUsed + I - 1] := Byte(Ord(S[I]));
  FData[FUsed + N] := 0;
  Inc(FUsed, N + 1);
end;

procedure TByteBuffer.Patch8(AOffset: LongInt; V: Byte);
begin
  if (AOffset < 0) or (AOffset >= FUsed) then
    raise ERCCError.Create('internal error: patch offset outside code buffer');
  FData[AOffset] := V;
end;

procedure TByteBuffer.Patch16(AOffset: LongInt; V: Word);
begin
  if (AOffset < 0) or (AOffset + 1 >= FUsed) then
    raise ERCCError.Create('internal error: patch offset outside code buffer');
  FData[AOffset] := Byte(V);
  FData[AOffset + 1] := Byte(V shr 8);
end;

procedure TByteBuffer.Patch32(AOffset: LongInt; V: LongInt);
begin
  if (AOffset < 0) or (AOffset + 3 >= FUsed) then
    raise ERCCError.Create('internal error: patch offset outside code buffer');
  FData[AOffset] := Byte(LongWord(V));
  FData[AOffset + 1] := Byte(LongWord(V) shr 8);
  FData[AOffset + 2] := Byte(LongWord(V) shr 16);
  FData[AOffset + 3] := Byte(LongWord(V) shr 24);
end;

procedure TByteBuffer.Patch64(AOffset: LongInt; V: QWord);
begin
  if (AOffset < 0) or (AOffset + 7 >= FUsed) then
    raise ERCCError.Create('internal error: patch offset outside code buffer');
  FData[AOffset] := Byte(V);
  FData[AOffset + 1] := Byte(V shr 8);
  FData[AOffset + 2] := Byte(V shr 16);
  FData[AOffset + 3] := Byte(V shr 24);
  FData[AOffset + 4] := Byte(V shr 32);
  FData[AOffset + 5] := Byte(V shr 40);
  FData[AOffset + 6] := Byte(V shr 48);
  FData[AOffset + 7] := Byte(V shr 56);
end;

procedure TByteBuffer.DeleteBytes(AOffset, ACount: LongInt);
var
  I: LongInt;
begin
  if ACount = 0 then Exit;
  if (AOffset < 0) or (ACount < 0) or (AOffset + ACount > FUsed) then
    raise ERCCError.Create('internal error: delete range outside code buffer');
  for I := AOffset to FUsed - ACount - 1 do
    FData[I] := FData[I + ACount];
  Dec(FUsed, ACount);
end;

procedure TByteBuffer.InsertBytes(AOffset: LongInt; const A: array of Byte);
var
  I, Count: LongInt;
begin
  Count := Length(A);
  if Count = 0 then Exit;
  if (AOffset < 0) or (AOffset > FUsed) then
    raise ERCCError.Create('internal error: insert offset outside code buffer');
  Grow(Count);
  for I := FUsed - 1 downto AOffset do
    FData[I + Count] := FData[I];
  for I := 0 to Count - 1 do
    FData[AOffset + I] := A[I];
  Inc(FUsed, Count);
end;

procedure TByteBuffer.PadTo(ABoundary: LongInt);
begin
  if ABoundary <= 0 then
    raise ERCCError.Create('internal error: invalid byte-buffer alignment');
  while (FUsed mod ABoundary) <> 0 do Add8(0);
end;

procedure TByteBuffer.Append(Other: TByteBuffer);
var
  I, N: LongInt;
begin
  if Other = nil then Exit;
  N := Other.FUsed;
  Grow(N);
  for I := 0 to N - 1 do FData[FUsed + I] := Other.FData[I];
  Inc(FUsed, N);
end;

procedure TByteBuffer.LoadFromFile(const AFileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead);
  try
    SetLength(FData, Stream.Size);
    FUsed := Stream.Size;
    FCapacity := Stream.Size;
    if FUsed > 0 then Stream.ReadBuffer(FData[0], FUsed);
  finally
    Stream.Free;
  end;
end;

procedure TByteBuffer.SaveToFile(const AFileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    if FUsed > 0 then
      Stream.WriteBuffer(FData[0], FUsed);
  finally
    Stream.Free;
  end;
end;

end.
