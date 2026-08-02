unit rcc_elf_reader;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_buffer;

type
  TELFInputSection = class
  public
    Name: string;
    SectionType: LongWord;
    Flags: QWord;
    Alignment: QWord;
    LinkIndex: LongWord;
    InfoIndex: LongWord;
    EntrySize: QWord;
    MemorySize: QWord;
    Data: TByteBuffer;
    constructor Create;
    destructor Destroy; override;
    function IsAllocated: Boolean;
    function IsExecutable: Boolean;
    function IsWritable: Boolean;
  end;
  TELFInputSectionArray = array of TELFInputSection;

  TELFInputSymbol = record
    Name: string;
    Binding: Byte;
    SymbolType: Byte;
    Visibility: Byte;
    SectionIndex: Word;
    Value: QWord;
    Size: QWord;
    IsDefined: Boolean;
    IsAbsolute: Boolean;
    IsCommon: Boolean;
  end;
  TELFInputSymbolArray = array of TELFInputSymbol;

  TELFInputRelocation = record
    SectionIndex: LongWord;
    Offset: QWord;
    SymbolIndex: LongWord;
    RelocationType: LongWord;
    Addend: Int64;
  end;
  TELFInputRelocationArray = array of TELFInputRelocation;

  TELFRelocatable = class
  public
    SourceName: string;
    ArchiveName: string;
    ArchiveMemberName: string;
    Machine: Word;
    Flags: LongWord;
    Sections: TELFInputSectionArray;
    Symbols: TELFInputSymbolArray;
    Relocations: TELFInputRelocationArray;
    constructor Create;
    destructor Destroy; override;
    function Summary: string;
  end;
  TELFRelocatableArray = array of TELFRelocatable;

function ReadELF64Relocatable(const AFileName: string;
  AExpectedMachine: Word): TELFRelocatable;
procedure ReadRelocatableInputs(const AFileNames: TStringArray;
  AExpectedMachine: Word; out AObjects: TELFRelocatableArray);
procedure FreeRelocatableInputs(var AObjects: TELFRelocatableArray);

implementation

const
  ET_REL = Word(1);
  SHT_NOBITS = LongWord(8);
  SHT_SYMTAB = LongWord(2);
  SHT_STRTAB = LongWord(3);
  SHT_RELA = LongWord(4);
  SHF_WRITE = QWord(1);
  SHF_ALLOC = QWord(2);
  SHF_EXECINSTR = QWord(4);
  SHN_UNDEF = Word(0);
  SHN_ABS = Word($FFF1);
  SHN_COMMON = Word($FFF2);

type
  TByteArray = array of Byte;

  TELFSectionHeader = record
    NameOffset: LongWord;
    SectionType: LongWord;
    Flags: QWord;
    FileOffset: QWord;
    Size: QWord;
    LinkIndex: LongWord;
    InfoIndex: LongWord;
    Alignment: QWord;
    EntrySize: QWord;
  end;
  TELFSectionHeaderArray = array of TELFSectionHeader;

constructor TELFInputSection.Create;
begin
  inherited Create;
  Name := '';
  SectionType := 0;
  Flags := 0;
  Alignment := 1;
  LinkIndex := 0;
  InfoIndex := 0;
  EntrySize := 0;
  MemorySize := 0;
  Data := TByteBuffer.Create;
end;

destructor TELFInputSection.Destroy;
begin
  Data.Free;
  inherited Destroy;
end;

function TELFInputSection.IsAllocated: Boolean;
begin
  Result := (Flags and SHF_ALLOC) <> 0;
end;

function TELFInputSection.IsExecutable: Boolean;
begin
  Result := (Flags and SHF_EXECINSTR) <> 0;
end;

function TELFInputSection.IsWritable: Boolean;
begin
  Result := (Flags and SHF_WRITE) <> 0;
end;

constructor TELFRelocatable.Create;
begin
  inherited Create;
  SourceName := '';
  ArchiveName := '';
  ArchiveMemberName := '';
  Machine := 0;
  Flags := 0;
  SetLength(Sections, 0);
  SetLength(Symbols, 0);
  SetLength(Relocations, 0);
end;

destructor TELFRelocatable.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(Sections) do Sections[I].Free;
  inherited Destroy;
end;

function TELFRelocatable.Summary: string;
begin
  Result := Format('%s: ELF64 machine=%d sections=%d symbols=%d relocations=%d',
    [SourceName, Machine, Length(Sections), Length(Symbols),
     Length(Relocations)]);
end;

procedure RequireRange(const AData: TByteArray; AOffset, ASize: QWord;
  const AContext: string);
begin
  if (AOffset > QWord(Length(AData))) or
     (ASize > QWord(Length(AData)) - AOffset) then
    raise ERCCError.Create('error: truncated ' + AContext);
end;

function Read8(const AData: TByteArray; AOffset: QWord;
  const AContext: string): Byte;
begin
  RequireRange(AData, AOffset, 1, AContext);
  Result := AData[LongInt(AOffset)];
end;

function Read16(const AData: TByteArray; AOffset: QWord;
  const AContext: string): Word;
begin
  RequireRange(AData, AOffset, 2, AContext);
  Result := Word(AData[LongInt(AOffset)]) or
    (Word(AData[LongInt(AOffset) + 1]) shl 8);
end;

function Read32(const AData: TByteArray; AOffset: QWord;
  const AContext: string): LongWord;
begin
  RequireRange(AData, AOffset, 4, AContext);
  Result := LongWord(AData[LongInt(AOffset)]) or
    (LongWord(AData[LongInt(AOffset) + 1]) shl 8) or
    (LongWord(AData[LongInt(AOffset) + 2]) shl 16) or
    (LongWord(AData[LongInt(AOffset) + 3]) shl 24);
end;

function Read64(const AData: TByteArray; AOffset: QWord;
  const AContext: string): QWord;
begin
  Result := QWord(Read32(AData, AOffset, AContext)) or
    (QWord(Read32(AData, AOffset + 4, AContext)) shl 32);
end;

function ReadCString(const AData: TByteArray; ABase, ASize,
  AOffset: QWord; const AContext: string): string;
var
  P, Limit: QWord;
begin
  if AOffset >= ASize then
    raise ERCCError.Create('error: invalid string offset in ' + AContext);
  RequireRange(AData, ABase, ASize, AContext);
  P := ABase + AOffset;
  Limit := ABase + ASize;
  Result := '';
  while (P < Limit) and (AData[LongInt(P)] <> 0) do
  begin
    Result := Result + Chr(AData[LongInt(P)]);
    Inc(P);
  end;
  if P >= Limit then
    raise ERCCError.Create('error: unterminated string in ' + AContext);
end;

procedure CopyBytesToBuffer(const AData: TByteArray; AOffset, ASize: QWord;
  ABuffer: TByteBuffer; const AContext: string);
var
  I: QWord;
begin
  RequireRange(AData, AOffset, ASize, AContext);
  if ASize = 0 then Exit;
  for I := 0 to ASize - 1 do
    ABuffer.Add8(AData[LongInt(AOffset + I)]);
end;

function LoadFileBytes(const AFileName: string): TByteArray;
var
  Stream: TFileStream;
begin
  Result := nil;
  if not FileExists(AFileName) then
    raise ERCCError.Create('error: linker input not found: ' + AFileName);
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    if Stream.Size > High(LongInt) then
      raise ERCCError.Create('error: linker input is too large: ' + AFileName);
    SetLength(Result, LongInt(Stream.Size));
    if Length(Result) > 0 then Stream.ReadBuffer(Result[0], Length(Result));
  finally
    Stream.Free;
  end;
end;

function ParseELF64Relocatable(const AData: TByteArray;
  const ASourceName: string; AExpectedMachine: Word): TELFRelocatable;
var
  SectionHeaders: TELFSectionHeaderArray;
  SectionHeaderOffset, HeaderOffset, EntryOffset: QWord;
  SectionEntrySize, SectionCount, SectionNameIndex: Word;
  StringHeader, SymbolStringHeader: TELFSectionHeader;
  I, J, N, SymbolTableIndex: LongInt;
  H: TELFSectionHeader;
  S: TELFInputSection;
  SymbolEntryCount, RelocationEntryCount: QWord;
  Info: Byte;
  RelInfo: QWord;
begin
  Result := nil;
  RequireRange(AData, 0, 64, 'ELF header in ' + ASourceName);
  if (Read8(AData, 0, ASourceName) <> $7F) or
     (Read8(AData, 1, ASourceName) <> Ord('E')) or
     (Read8(AData, 2, ASourceName) <> Ord('L')) or
     (Read8(AData, 3, ASourceName) <> Ord('F')) then
    raise ERCCError.Create('error: linker input is not ELF: ' + ASourceName);
  if (Read8(AData, 4, ASourceName) <> 2) or
     (Read8(AData, 5, ASourceName) <> 1) then
    raise ERCCError.Create('error: linker input must be little-endian ELF64: ' +
      ASourceName);
  if Read16(AData, 16, ASourceName) <> ET_REL then
    raise ERCCError.Create('error: linker object is not relocatable ELF: ' +
      ASourceName);
  if Read16(AData, 18, ASourceName) <> AExpectedMachine then
    raise ERCCError.Create('error: linker object architecture mismatch: ' +
      ASourceName);

  SectionHeaderOffset := Read64(AData, 40, ASourceName);
  SectionEntrySize := Read16(AData, 58, ASourceName);
  SectionCount := Read16(AData, 60, ASourceName);
  SectionNameIndex := Read16(AData, 62, ASourceName);
  if (SectionEntrySize < 64) or (SectionCount = 0) or
     (SectionNameIndex >= SectionCount) then
    raise ERCCError.Create('error: invalid ELF section table in ' + ASourceName);
  RequireRange(AData, SectionHeaderOffset,
    QWord(SectionEntrySize) * SectionCount,
    'ELF section table in ' + ASourceName);

  SetLength(SectionHeaders, SectionCount);
  for I := 0 to SectionCount - 1 do
  begin
    HeaderOffset := SectionHeaderOffset + QWord(I) * SectionEntrySize;
    SectionHeaders[I].NameOffset := Read32(AData, HeaderOffset, ASourceName);
    SectionHeaders[I].SectionType := Read32(AData, HeaderOffset + 4, ASourceName);
    SectionHeaders[I].Flags := Read64(AData, HeaderOffset + 8, ASourceName);
    SectionHeaders[I].FileOffset := Read64(AData, HeaderOffset + 24, ASourceName);
    SectionHeaders[I].Size := Read64(AData, HeaderOffset + 32, ASourceName);
    SectionHeaders[I].LinkIndex := Read32(AData, HeaderOffset + 40, ASourceName);
    SectionHeaders[I].InfoIndex := Read32(AData, HeaderOffset + 44, ASourceName);
    SectionHeaders[I].Alignment := Read64(AData, HeaderOffset + 48, ASourceName);
    SectionHeaders[I].EntrySize := Read64(AData, HeaderOffset + 56, ASourceName);
  end;
  StringHeader := SectionHeaders[SectionNameIndex];
  if StringHeader.SectionType <> SHT_STRTAB then
    raise ERCCError.Create('error: invalid ELF section-name table in ' +
      ASourceName);

  Result := TELFRelocatable.Create;
  try
    Result.SourceName := ASourceName;
    Result.Machine := Read16(AData, 18, ASourceName);
    Result.Flags := Read32(AData, 48, ASourceName);
    SetLength(Result.Sections, SectionCount);
    for I := 0 to SectionCount - 1 do
    begin
      H := SectionHeaders[I];
      S := TELFInputSection.Create;
      Result.Sections[I] := S;
      S.Name := ReadCString(AData, StringHeader.FileOffset,
        StringHeader.Size, H.NameOffset, 'section names in ' + ASourceName);
      S.SectionType := H.SectionType;
      S.Flags := H.Flags;
      if H.Alignment = 0 then S.Alignment := 1 else S.Alignment := H.Alignment;
      if (S.Alignment and (S.Alignment - 1)) <> 0 then
        raise ERCCError.Create('error: invalid section alignment in ' +
          ASourceName + ': ' + S.Name);
      S.LinkIndex := H.LinkIndex;
      S.InfoIndex := H.InfoIndex;
      S.EntrySize := H.EntrySize;
      S.MemorySize := H.Size;
      if (H.SectionType <> SHT_NOBITS) and (H.Size <> 0) then
        CopyBytesToBuffer(AData, H.FileOffset, H.Size, S.Data,
          'section ' + S.Name + ' in ' + ASourceName);
    end;

    SymbolTableIndex := -1;
    for I := 0 to SectionCount - 1 do
      if SectionHeaders[I].SectionType = SHT_SYMTAB then
      begin
        if SymbolTableIndex >= 0 then
          raise ERCCError.Create('error: multiple ELF symbol tables are unsupported in ' +
            ASourceName);
        SymbolTableIndex := I;
      end;
    if SymbolTableIndex < 0 then
      raise ERCCError.Create('error: ELF object has no symbol table: ' + ASourceName);
    H := SectionHeaders[SymbolTableIndex];
    if (H.LinkIndex >= SectionCount) or
       (SectionHeaders[H.LinkIndex].SectionType <> SHT_STRTAB) or
       (H.EntrySize < 24) or ((H.Size mod H.EntrySize) <> 0) then
      raise ERCCError.Create('error: invalid ELF symbol table in ' + ASourceName);
    SymbolStringHeader := SectionHeaders[H.LinkIndex];
    SymbolEntryCount := H.Size div H.EntrySize;
    if SymbolEntryCount > High(LongInt) then
      raise ERCCError.Create('error: ELF symbol table is too large in ' + ASourceName);
    SetLength(Result.Symbols, LongInt(SymbolEntryCount));
    for I := 0 to LongInt(SymbolEntryCount) - 1 do
    begin
      EntryOffset := H.FileOffset + QWord(I) * H.EntrySize;
      Info := Read8(AData, EntryOffset + 4, ASourceName);
      Result.Symbols[I].Name := ReadCString(AData,
        SymbolStringHeader.FileOffset, SymbolStringHeader.Size,
        Read32(AData, EntryOffset, ASourceName),
        'symbol names in ' + ASourceName);
      Result.Symbols[I].Binding := Info shr 4;
      Result.Symbols[I].SymbolType := Info and $F;
      Result.Symbols[I].Visibility := Read8(AData, EntryOffset + 5,
        ASourceName) and 3;
      Result.Symbols[I].SectionIndex := Read16(AData, EntryOffset + 6,
        ASourceName);
      Result.Symbols[I].Value := Read64(AData, EntryOffset + 8, ASourceName);
      Result.Symbols[I].Size := Read64(AData, EntryOffset + 16, ASourceName);
      Result.Symbols[I].IsDefined :=
        Result.Symbols[I].SectionIndex <> SHN_UNDEF;
      Result.Symbols[I].IsAbsolute :=
        Result.Symbols[I].SectionIndex = SHN_ABS;
      Result.Symbols[I].IsCommon :=
        Result.Symbols[I].SectionIndex = SHN_COMMON;
      if Result.Symbols[I].IsDefined and
         not Result.Symbols[I].IsAbsolute and
         not Result.Symbols[I].IsCommon and
         (Result.Symbols[I].SectionIndex >= SectionCount) then
        raise ERCCError.Create('error: invalid ELF symbol section in ' +
          ASourceName);
    end;

    for I := 0 to SectionCount - 1 do
      if SectionHeaders[I].SectionType = SHT_RELA then
      begin
        H := SectionHeaders[I];
        if (H.LinkIndex <> LongWord(SymbolTableIndex)) or
           (H.InfoIndex >= SectionCount) or (H.EntrySize < 24) or
           ((H.Size mod H.EntrySize) <> 0) then
          raise ERCCError.Create('error: invalid ELF relocation section in ' +
            ASourceName);
        RelocationEntryCount := H.Size div H.EntrySize;
        if RelocationEntryCount > High(LongInt) then
          raise ERCCError.Create('error: ELF relocation table is too large in ' +
            ASourceName);
        for J := 0 to LongInt(RelocationEntryCount) - 1 do
        begin
          EntryOffset := H.FileOffset + QWord(J) * H.EntrySize;
          RelInfo := Read64(AData, EntryOffset + 8, ASourceName);
          N := Length(Result.Relocations);
          SetLength(Result.Relocations, N + 1);
          Result.Relocations[N].SectionIndex := H.InfoIndex;
          Result.Relocations[N].Offset := Read64(AData, EntryOffset,
            ASourceName);
          Result.Relocations[N].SymbolIndex := LongWord(RelInfo shr 32);
          Result.Relocations[N].RelocationType := LongWord(RelInfo);
          Result.Relocations[N].Addend := Int64(Read64(AData,
            EntryOffset + 16, ASourceName));
          if Result.Relocations[N].SymbolIndex >= QWord(Length(Result.Symbols)) then
            raise ERCCError.Create('error: invalid relocation symbol in ' +
              ASourceName);
          if Result.Relocations[N].Offset >=
             Result.Sections[H.InfoIndex].MemorySize then
            raise ERCCError.Create('error: relocation offset outside section in ' +
              ASourceName);
        end;
      end;
  except
    Result.Free;
    raise;
  end;
end;

function ReadELF64Relocatable(const AFileName: string;
  AExpectedMachine: Word): TELFRelocatable;
var
  Data: TByteArray;
begin
  Data := LoadFileBytes(AFileName);
  Result := ParseELF64Relocatable(Data, AFileName, AExpectedMachine);
end;

function SliceBytes(const AData: TByteArray; AOffset, ASize: QWord;
  const AContext: string): TByteArray;
var
  I: QWord;
begin
  Result := nil;
  RequireRange(AData, AOffset, ASize, AContext);
  if ASize > High(LongInt) then
    raise ERCCError.Create('error: archive member is too large: ' + AContext);
  SetLength(Result, LongInt(ASize));
  if ASize = 0 then Exit;
  for I := 0 to ASize - 1 do Result[LongInt(I)] := AData[LongInt(AOffset + I)];
end;

function FixedText(const AData: TByteArray; AOffset: QWord;
  ALength: LongInt; const AContext: string): string;
var
  I: LongInt;
begin
  RequireRange(AData, AOffset, ALength, AContext);
  Result := '';
  for I := 0 to ALength - 1 do
    Result := Result + Chr(AData[LongInt(AOffset) + I]);
end;

function ParseDecimalField(const AValue, AContext: string): QWord;
var
  I: LongInt;
  Text: string;
begin
  Text := Trim(AValue);
  if Text = '' then
    raise ERCCError.Create('error: empty decimal field in ' + AContext);
  Result := 0;
  for I := 1 to Length(Text) do
  begin
    if not (Text[I] in ['0'..'9']) then
      raise ERCCError.Create('error: invalid decimal field in ' + AContext);
    if Result > (High(QWord) - QWord(Ord(Text[I]) - Ord('0'))) div 10 then
      raise ERCCError.Create('error: decimal field overflow in ' + AContext);
    Result := Result * 10 + QWord(Ord(Text[I]) - Ord('0'));
  end;
end;

function GNUArchiveName(const ALongNames: TByteArray;
  AOffset: QWord; const AContext: string): string;
var
  P: QWord;
begin
  if AOffset >= QWord(Length(ALongNames)) then
    raise ERCCError.Create('error: invalid archive long-name offset in ' + AContext);
  Result := '';
  P := AOffset;
  while (P < QWord(Length(ALongNames))) and
        not (ALongNames[LongInt(P)] in [0, 10]) do
  begin
    if ALongNames[LongInt(P)] = Ord('/') then Break;
    Result := Result + Chr(ALongNames[LongInt(P)]);
    Inc(P);
  end;
end;

procedure AppendObject(var AObjects: TELFRelocatableArray;
  AObject: TELFRelocatable);
var
  N: LongInt;
begin
  N := Length(AObjects);
  SetLength(AObjects, N + 1);
  AObjects[N] := AObject;
end;

procedure ReadArchiveObjects(const AFileName: string; AExpectedMachine: Word;
  var AObjects: TELFRelocatableArray);
var
  Data, MemberData, LongNames: TByteArray;
  Offset, HeaderStart, MemberSize, PayloadOffset, PayloadSize,
    NameLength: QWord;
  RawName, MemberName, Context: string;
  Obj: TELFRelocatable;
begin
  Data := LoadFileBytes(AFileName);
  if (Length(Data) >= 8) and
     (FixedText(Data, 0, 8, AFileName) = '!<thin>' + #10) then
    raise ERCCError.Create('error: thin archives are unsupported: ' + AFileName);
  if (Length(Data) < 8) or
     (FixedText(Data, 0, 8, AFileName) <> '!<arch>' + #10) then
    raise ERCCError.Create('error: static library is not an ar archive: ' +
      AFileName);
  SetLength(LongNames, 0);
  Offset := 8;
  while Offset < QWord(Length(Data)) do
  begin
    HeaderStart := Offset;
    Context := 'archive member header in ' + AFileName;
    RequireRange(Data, Offset, 60, Context);
    if FixedText(Data, Offset + 58, 2, Context) <> '`' + #10 then
      raise ERCCError.Create('error: invalid archive member trailer in ' +
        AFileName);
    RawName := Trim(FixedText(Data, Offset, 16, Context));
    MemberSize := ParseDecimalField(FixedText(Data, Offset + 48, 10,
      Context), Context);
    PayloadOffset := Offset + 60;
    PayloadSize := MemberSize;
    RequireRange(Data, PayloadOffset, PayloadSize,
      'archive member in ' + AFileName);

    MemberName := RawName;
    if RawName = '//' then
      LongNames := SliceBytes(Data, PayloadOffset, PayloadSize,
        'archive long-name table in ' + AFileName)
    else if (RawName = '/') or (RawName = '/SYM64/') or
            (RawName = '__.SYMDEF') or (RawName = '__.SYMDEF SORTED') then

    else
    begin
      if Copy(RawName, 1, 3) = '#1/' then
      begin
        NameLength := ParseDecimalField(Copy(RawName, 4, MaxInt), Context);
        if NameLength > PayloadSize then
          raise ERCCError.Create('error: invalid BSD archive member name in ' +
            AFileName);
        MemberName := FixedText(Data, PayloadOffset, LongInt(NameLength),
          Context);
        Inc(PayloadOffset, NameLength);
        Dec(PayloadSize, NameLength);
      end
      else if (Length(RawName) > 1) and (RawName[1] = '/') then
        MemberName := GNUArchiveName(LongNames,
          ParseDecimalField(Copy(RawName, 2, MaxInt), Context), Context)
      else if (MemberName <> '') and
              (MemberName[Length(MemberName)] = '/') then
        Delete(MemberName, Length(MemberName), 1);
      if MemberName = '' then
        raise ERCCError.Create('error: archive contains an unnamed member: ' +
          AFileName);
      MemberData := SliceBytes(Data, PayloadOffset, PayloadSize,
        'archive member ' + MemberName + ' in ' + AFileName);
      if (Length(MemberData) < 4) or
         (MemberData[0] <> $7F) or
         (MemberData[1] <> Ord('E')) or
         (MemberData[2] <> Ord('L')) or
         (MemberData[3] <> Ord('F')) then
        raise ERCCError.Create('error: archive member is not ELF: ' +
          AFileName + '(' + MemberName + ')');
      Obj := ParseELF64Relocatable(MemberData,
        AFileName + '(' + MemberName + ')', AExpectedMachine);
      Obj.ArchiveName := AFileName;
      Obj.ArchiveMemberName := MemberName;
      AppendObject(AObjects, Obj);
    end;
    Offset := HeaderStart + 60 + MemberSize;
    if (Offset and 1) <> 0 then Inc(Offset);
    if (Offset < 8) or (Offset > QWord(Length(Data))) then
      raise ERCCError.Create('error: invalid archive member size in ' +
        AFileName);
  end;
end;

procedure ReadRelocatableInputs(const AFileNames: TStringArray;
  AExpectedMachine: Word; out AObjects: TELFRelocatableArray);
var
  I: LongInt;
  Extension: string;
begin
  SetLength(AObjects, 0);
  try
    for I := 0 to High(AFileNames) do
    begin
      Extension := LowerCase(ExtractFileExt(AFileNames[I]));
      if Extension = '.o' then
        AppendObject(AObjects,
          ReadELF64Relocatable(AFileNames[I], AExpectedMachine))
      else if Extension = '.a' then
        ReadArchiveObjects(AFileNames[I], AExpectedMachine, AObjects)
      else
        raise ERCCError.Create('error: unsupported relocatable input: ' +
          AFileNames[I]);
    end;
  except
    FreeRelocatableInputs(AObjects);
    raise;
  end;
end;

procedure FreeRelocatableInputs(var AObjects: TELFRelocatableArray);
var
  I: LongInt;
begin
  for I := 0 to High(AObjects) do AObjects[I].Free;
  SetLength(AObjects, 0);
end;

end.
