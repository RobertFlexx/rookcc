unit rcc_buffer;

{$mode objfpc}{$H+}

interface

uses
  Classes, rcc_types;

type


  TByteBuffer = class
  private
    FData: array of Byte;
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
    procedure PadTo(ABoundary: LongInt);
    procedure Append(Other: TByteBuffer);
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
  end;

implementation

function TByteBuffer.Size: LongInt;
begin
  Result := Length(FData);
end;

function TByteBuffer.ByteAt(AIndex: LongInt): Byte;
begin
  if (AIndex < 0) or (AIndex >= Length(FData)) then
    raise ERCCError.Create('internal error: byte index outside buffer');
  Result := FData[AIndex];
end;

procedure TByteBuffer.Clear;
begin
  SetLength(FData, 0);
end;

procedure TByteBuffer.Add8(V: Byte);
var
  N: LongInt;
begin
  N := Length(FData);
  SetLength(FData, N + 1);
  FData[N] := V;
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
  I: LongInt;
begin
  for I := Low(A) to High(A) do Add8(A[I]);
end;

procedure TByteBuffer.AddStringZ(const S: string);
var
  I: LongInt;
begin
  for I := 1 to Length(S) do Add8(Byte(Ord(S[I])));
  Add8(0);
end;

procedure TByteBuffer.Patch8(AOffset: LongInt; V: Byte);
begin
  if (AOffset < 0) or (AOffset >= Length(FData)) then
    raise ERCCError.Create('internal error: patch offset outside code buffer');
  FData[AOffset] := V;
end;

procedure TByteBuffer.Patch16(AOffset: LongInt; V: Word);
begin
  if (AOffset < 0) or (AOffset + 1 >= Length(FData)) then
    raise ERCCError.Create('internal error: patch offset outside code buffer');
  FData[AOffset] := Byte(V);
  FData[AOffset + 1] := Byte(V shr 8);
end;

procedure TByteBuffer.Patch32(AOffset: LongInt; V: LongInt);
begin
  if (AOffset < 0) or (AOffset + 3 >= Length(FData)) then
    raise ERCCError.Create('internal error: patch offset outside code buffer');
  FData[AOffset] := Byte(LongWord(V));
  FData[AOffset + 1] := Byte(LongWord(V) shr 8);
  FData[AOffset + 2] := Byte(LongWord(V) shr 16);
  FData[AOffset + 3] := Byte(LongWord(V) shr 24);
end;

procedure TByteBuffer.Patch64(AOffset: LongInt; V: QWord);
begin
  if (AOffset < 0) or (AOffset + 7 >= Length(FData)) then
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

procedure TByteBuffer.PadTo(ABoundary: LongInt);
begin
  if ABoundary <= 0 then
    raise ERCCError.Create('internal error: invalid byte-buffer alignment');
  while (Length(FData) mod ABoundary) <> 0 do Add8(0);
end;

procedure TByteBuffer.Append(Other: TByteBuffer);
var
  I: LongInt;
begin
  if Other = nil then Exit;
  for I := 0 to Other.Size - 1 do Add8(Other.FData[I]);
end;

procedure TByteBuffer.LoadFromFile(const AFileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead);
  try
    SetLength(FData, Stream.Size);
    if Length(FData) > 0 then Stream.ReadBuffer(FData[0], Length(FData));
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
    if Length(FData) > 0 then
      Stream.WriteBuffer(FData[0], Length(FData));
  finally
    Stream.Free;
  end;
end;

end.
