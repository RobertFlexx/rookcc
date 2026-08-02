unit rcc_archive;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_buffer;

type
  TArchiveMember = class
  public
    Name: string;
    ModificationTime: QWord;
    OwnerID: LongWord;
    GroupID: LongWord;
    Mode: LongWord;
    Data: TByteBuffer;
    Symbols: rcc_types.TStringArray;
    constructor Create(const AName: string);
    destructor Destroy; override;
    function Size: QWord;
  end;
  TArchiveMemberArray = array of TArchiveMember;

  TStaticArchive = class
  public
    Members: TArchiveMemberArray;
    Deterministic: Boolean;
    Thin: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure AddMember(AMember: TArchiveMember);
    function FindMember(const AName: string): LongInt;
    function Member(AIndex: LongInt): TArchiveMember;
    procedure Validate;
    function Summary: string;
  end;

function ParseArchiveDecimal(const AValue: string; out AResult: QWord): Boolean;
function FormatArchiveField(const AValue: string; AWidth: LongInt): string;
function ArchiveMemberHeader(const AMember: TArchiveMember): string;
procedure WriteStaticArchive(const AFileName: string;
  AArchive: TStaticArchive);
function StaticArchiveText(AArchive: TStaticArchive): string;

implementation

constructor TArchiveMember.Create(const AName: string);
begin
  inherited Create;
  Name := AName;
  ModificationTime := 0;
  OwnerID := 0;
  GroupID := 0;
  Mode := &644;
  Data := TByteBuffer.Create;
  SetLength(Symbols, 0);
end;

destructor TArchiveMember.Destroy;
begin
  Data.Free;
  inherited Destroy;
end;

function TArchiveMember.Size: QWord;
begin
  if Data = nil then Result := 0 else Result := QWord(Data.Size);
end;

constructor TStaticArchive.Create;
begin
  inherited Create;
  SetLength(Members, 0);
  Deterministic := True;
  Thin := False;
end;

destructor TStaticArchive.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(Members) do Members[I].Free;
  inherited Destroy;
end;

procedure TStaticArchive.AddMember(AMember: TArchiveMember);
var
  N: LongInt;
begin
  if AMember = nil then
    raise ERCCError.Create('internal error: nil archive member');
  if FindMember(AMember.Name) >= 0 then
    raise ERCCError.Create('error: duplicate archive member ''' +
      AMember.Name + '''');
  N := Length(Members);
  SetLength(Members, N + 1);
  Members[N] := AMember;
end;

function TStaticArchive.FindMember(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(Members) do
    if Members[I].Name = AName then Exit(I);
  Result := -1;
end;

function TStaticArchive.Member(AIndex: LongInt): TArchiveMember;
begin
  if (AIndex < 0) or (AIndex > High(Members)) then
    raise ERCCError.Create('internal error: archive member index invalid');
  Result := Members[AIndex];
end;

function TStaticArchive.Summary: string;
var
  Total: QWord;
  I: LongInt;
begin
  Total := 0;
  for I := 0 to High(Members) do Inc(Total, Members[I].Size);
  Result := Format('archive: %d member(s), %d payload byte(s), deterministic=%s',
    [Length(Members), Total, BoolToStr(Deterministic, True)]);
end;

procedure TStaticArchive.Validate;
var
  I: LongInt;
begin
  if Thin then
    raise ERCCError.Create('error: thin archive input is unsupported; use a regular archive');
  for I := 0 to High(Members) do
  begin
    if Members[I].Name = '' then
      raise ERCCError.Create('internal error: archive member has empty name');
    if Pos(LineEnding, Members[I].Name) <> 0 then
      raise ERCCError.Create('internal error: archive member name has newline');
    if Length(Members[I].Name) > 15 then
      raise ERCCError.Create('error: long archive member names require a string table, which is not complete');
  end;
end;

function ParseArchiveDecimal(const AValue: string; out AResult: QWord): Boolean;
var
  I: LongInt;
  C: Char;
begin
  AResult := 0;
  for I := 1 to Length(Trim(AValue)) do
  begin
    C := Trim(AValue)[I];
    if (C < '0') or (C > '9') then Exit(False);
    AResult := AResult * 10 + QWord(Ord(C) - Ord('0'));
  end;
  Result := True;
end;

function FormatArchiveField(const AValue: string; AWidth: LongInt): string;
begin
  if Length(AValue) > AWidth then
    raise ERCCError.Create('internal error: archive field overflow');
  Result := AValue + StringOfChar(' ', AWidth - Length(AValue));
end;

function ToOctal(AValue: QWord): string;
begin
  Result := '';
  repeat
    Result := Chr(Ord('0') + (AValue and 7)) + Result;
    AValue := AValue shr 3;
  until AValue = 0;
end;

function ArchiveMemberHeader(const AMember: TArchiveMember): string;
var
  Stamp, UID, GID, ModeText, SizeText: string;
begin
  if AMember = nil then
    raise ERCCError.Create('internal error: nil archive member header');
  Stamp := IntToStr(AMember.ModificationTime);
  UID := IntToStr(AMember.OwnerID);
  GID := IntToStr(AMember.GroupID);
  ModeText := ToOctal(AMember.Mode);
  SizeText := IntToStr(AMember.Size);
  Result := FormatArchiveField(AMember.Name + '/', 16) +
    FormatArchiveField(Stamp, 12) + FormatArchiveField(UID, 6) +
    FormatArchiveField(GID, 6) + FormatArchiveField(ModeText, 8) +
    FormatArchiveField(SizeText, 10) + '`' + #10;
  if Length(Result) <> 60 then
    raise ERCCError.Create('internal error: invalid archive header size');
end;

procedure AddText(ABuffer: TByteBuffer; const AText: string);
var
  I: LongInt;
begin
  for I := 1 to Length(AText) do ABuffer.Add8(Byte(Ord(AText[I])));
end;

procedure WriteStaticArchive(const AFileName: string;
  AArchive: TStaticArchive);
var
  Buffer: TByteBuffer;
  I: LongInt;
  M: TArchiveMember;
begin
  if AArchive = nil then
    raise ERCCError.Create('internal error: nil archive');
  AArchive.Validate;
  Buffer := TByteBuffer.Create;
  try
    AddText(Buffer, '!<arch>' + #10);
    for I := 0 to High(AArchive.Members) do
    begin
      M := AArchive.Members[I];
      if AArchive.Deterministic then
      begin
        M.ModificationTime := 0;
        M.OwnerID := 0;
        M.GroupID := 0;
      end;
      AddText(Buffer, ArchiveMemberHeader(M));
      Buffer.Append(M.Data);
      if (M.Size and 1) <> 0 then Buffer.Add8(Byte(Ord(#10)));
    end;
    Buffer.SaveToFile(AFileName);
  finally
    Buffer.Free;
  end;
end;

function StaticArchiveText(AArchive: TStaticArchive): string;
var
  Lines: TStringList;
  I: LongInt;
begin
  if AArchive = nil then Exit('<nil archive>');
  Lines := TStringList.Create;
  try
    Lines.Add('archive members=' + IntToStr(Length(AArchive.Members)) +
      ' deterministic=' + BoolToStr(AArchive.Deterministic, True));
    for I := 0 to High(AArchive.Members) do
      Lines.Add(Format('  %-20s %d bytes %d symbols',
        [AArchive.Members[I].Name, AArchive.Members[I].Size,
         Length(AArchive.Members[I].Symbols)]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
