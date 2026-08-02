unit rcc_elf_image;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, BaseUnix, rcc_types, rcc_buffer, rcc_arch, rcc_object_model;

type
  TELFImageLayout = record
    HeaderSize: QWord;
    ProgramHeaderOffset: QWord;
    ProgramHeaderCount: Word;
    TextOffset: QWord;
    TextAddress: QWord;
    DataOffset: QWord;
    DataAddress: QWord;
    EntryAddress: QWord;
    FileSize: QWord;
  end;

function AlignELF(AValue, AAlignment: QWord): QWord;
function ComputeStaticELFLayout(const ATarget: TTargetDescriptor;
  ATextSize, ADataSize, AEntryOffset: QWord): TELFImageLayout;
procedure WriteStaticELF64Executable(const AFileName: string;
  const ATarget: TTargetDescriptor; AText, AData: TByteBuffer;
  AEntryOffset: QWord);
procedure WriteELF64Relocatable(const AFileName: string;
  AObject: TObjectFile);

implementation

const
  EI_NIDENT = 16;
  ELFCLASS64 = 2;
  ELFDATA2LSB = 1;
  EV_CURRENT = 1;
  ELFOSABI_SYSV = 0;
  ET_REL = 1;
  ET_EXEC = 2;
  PT_LOAD = 1;
  PT_GNU_STACK = $6474E551;
  PF_X = 1;
  PF_W = 2;
  PF_R = 4;
  SHT_NULL = 0;
  SHT_PROGBITS = 1;
  SHT_SYMTAB = 2;
  SHT_STRTAB = 3;
  SHT_RELA = 4;
  SHT_NOBITS = 8;
  SHF_WRITE = 1;
  SHF_ALLOC = 2;
  SHF_EXECINSTR = 4;
  SHF_MERGE = $10;
  SHF_STRINGS = $20;
  SHF_TLS = $400;
  SHN_UNDEF = 0;

procedure AddELFIdent(ABuffer: TByteBuffer);
var
  I: LongInt;
begin
  ABuffer.AddBytes([$7F, Ord('E'), Ord('L'), Ord('F'),
    ELFCLASS64, ELFDATA2LSB, EV_CURRENT, ELFOSABI_SYSV]);
  for I := 8 to EI_NIDENT - 1 do ABuffer.Add8(0);
end;

function AlignELF(AValue, AAlignment: QWord): QWord;
begin
  if AAlignment = 0 then Exit(AValue);
  if (AAlignment and (AAlignment - 1)) <> 0 then
    raise ERCCError.Create('internal error: non-power-of-two ELF alignment');
  Result := (AValue + AAlignment - 1) and not (AAlignment - 1);
end;

function ComputeStaticELFLayout(const ATarget: TTargetDescriptor;
  ATextSize, ADataSize, AEntryOffset: QWord): TELFImageLayout;
begin
  Result.HeaderSize := 64;
  Result.ProgramHeaderOffset := 64;
  Result.ProgramHeaderCount := 2;
  if ADataSize <> 0 then Inc(Result.ProgramHeaderCount);
  Result.TextOffset := AlignELF(Result.HeaderSize +
    QWord(Result.ProgramHeaderCount) * 56, ATarget.PageSize);
  Result.TextAddress := ATarget.PreferredImageBase + Result.TextOffset;
  Result.EntryAddress := Result.TextAddress + AEntryOffset;
  if ADataSize <> 0 then
  begin
    Result.DataOffset := AlignELF(Result.TextOffset + ATextSize,
      ATarget.PageSize);
    Result.DataAddress := ATarget.PreferredImageBase + Result.DataOffset;
    Result.FileSize := Result.DataOffset + ADataSize;
  end
  else
  begin
    Result.DataOffset := 0;
    Result.DataAddress := 0;
    Result.FileSize := Result.TextOffset + ATextSize;
  end;
end;

procedure AddProgramHeader(ABuffer: TByteBuffer; AType, AFlags: LongWord;
  AOffset, AVirtual, APhysical, AFileSize, AMemorySize, AAlign: QWord);
begin
  ABuffer.Add32(AType);
  ABuffer.Add32(AFlags);
  ABuffer.Add64(AOffset);
  ABuffer.Add64(AVirtual);
  ABuffer.Add64(APhysical);
  ABuffer.Add64(AFileSize);
  ABuffer.Add64(AMemorySize);
  ABuffer.Add64(AAlign);
end;

procedure WriteStaticELF64Executable(const AFileName: string;
  const ATarget: TTargetDescriptor; AText, AData: TByteBuffer;
  AEntryOffset: QWord);
var
  Layout: TELFImageLayout;
  FileBuffer: TByteBuffer;
  DataSize: QWord;
begin
  if AText = nil then
    raise ERCCError.Create('internal error: nil text buffer for ELF image');
  if AEntryOffset >= QWord(AText.Size) then
    raise ERCCError.Create('internal error: ELF entry is outside text');
  if AData = nil then DataSize := 0 else DataSize := QWord(AData.Size);
  Layout := ComputeStaticELFLayout(ATarget, QWord(AText.Size),
    DataSize, AEntryOffset);
  FileBuffer := TByteBuffer.Create;
  try
    AddELFIdent(FileBuffer);
    FileBuffer.Add16(ET_EXEC);
    FileBuffer.Add16(ATarget.ELFMachine);
    FileBuffer.Add32(EV_CURRENT);
    FileBuffer.Add64(Layout.EntryAddress);
    FileBuffer.Add64(Layout.ProgramHeaderOffset);
    FileBuffer.Add64(0);
    FileBuffer.Add32(ATarget.ELFFlags);
    FileBuffer.Add16(64);
    FileBuffer.Add16(56);
    FileBuffer.Add16(Layout.ProgramHeaderCount);
    FileBuffer.Add16(64);
    FileBuffer.Add16(0);
    FileBuffer.Add16(0);

    AddProgramHeader(FileBuffer, PT_LOAD, PF_R or PF_X,
      0, ATarget.PreferredImageBase, ATarget.PreferredImageBase,
      Layout.TextOffset + QWord(AText.Size),
      Layout.TextOffset + QWord(AText.Size), ATarget.PageSize);
    if DataSize <> 0 then
      AddProgramHeader(FileBuffer, PT_LOAD, PF_R or PF_W,
        Layout.DataOffset, Layout.DataAddress, Layout.DataAddress,
        DataSize, DataSize, ATarget.PageSize);
    AddProgramHeader(FileBuffer, PT_GNU_STACK, PF_R or PF_W,
      0, 0, 0, 0, 0, 16);

    while QWord(FileBuffer.Size) < Layout.TextOffset do FileBuffer.Add8(0);
    FileBuffer.Append(AText);
    if DataSize <> 0 then
    begin
      while QWord(FileBuffer.Size) < Layout.DataOffset do FileBuffer.Add8(0);
      FileBuffer.Append(AData);
    end;
    FileBuffer.SaveToFile(AFileName);
    if fpChmod(PChar(AFileName), &755) <> 0 then
      raise ERCCError.Create('error: cannot mark output executable: ' +
        AFileName);
  finally
    FileBuffer.Free;
  end;
end;

function SectionType(ASection: TObjectSection): LongWord;
begin
  case ASection.Kind of
    oskNull: Result := SHT_NULL;
    oskBSS, oskTLSBSS: Result := SHT_NOBITS;
  else
    Result := SHT_PROGBITS;
  end;
end;

function SectionFlags(ASection: TObjectSection): QWord;
begin
  Result := 0;
  if osfWrite in ASection.Flags then Result := Result or SHF_WRITE;
  if osfAlloc in ASection.Flags then Result := Result or SHF_ALLOC;
  if osfExecute in ASection.Flags then Result := Result or SHF_EXECINSTR;
  if osfMerge in ASection.Flags then Result := Result or SHF_MERGE;
  if osfStrings in ASection.Flags then Result := Result or SHF_STRINGS;
  if osfTLS in ASection.Flags then Result := Result or SHF_TLS;
end;

function SymbolInfo(ASymbol: TObjectSymbol): Byte;
var
  Bind, Kind: Byte;
begin
  case ASymbol.Binding of
    osbLocal: Bind := 0;
    osbGlobal: Bind := 1;
    osbWeak: Bind := 2;
  else
    Bind := 0;
  end;
  case ASymbol.SymbolType of
    ostNoType: Kind := 0;
    ostObject: Kind := 1;
    ostFunction: Kind := 2;
    ostSection: Kind := 3;
    ostFile: Kind := 4;
    ostTLS: Kind := 6;
  else
    Kind := 0;
  end;
  Result := (Bind shl 4) or Kind;
end;

function SymbolOther(ASymbol: TObjectSymbol): Byte;
begin
  case ASymbol.Visibility of
    osvDefault: Result := 0;
    osvInternal: Result := 1;
    osvHidden: Result := 2;
    osvProtected: Result := 3;
  else
    Result := 0;
  end;
end;

function ELFRelocationType(const ATarget: TTargetDescriptor;
  const ARelocation: TObjectRelocation): LongWord;
begin
  if ARelocation.ArchitectureCode <> 0 then
    Exit(ARelocation.ArchitectureCode);
  case ATarget.Architecture of
    archX86_64:
      case ARelocation.Kind of
        orkNone: Result := 0;
        orkAbsolute8: Result := 14;
        orkAbsolute16: Result := 12;
        orkAbsolute32: Result := 10;
        orkAbsolute64: Result := 1;
        orkPCRelative8: Result := 15;
        orkPCRelative16: Result := 13;
        orkPCRelative32: Result := 2;
        orkPCRelative64: Result := 24;
        orkCall, orkJump, orkPLT: Result := 4;
      else
        raise ERCCError.Create(
          'internal error: x86-64 relocation requires an architecture code');
      end;
    archAArch64:
      case ARelocation.Kind of
        orkNone: Result := 0;
        orkAbsolute32: Result := 258;
        orkAbsolute64: Result := 257;
        orkPCRelative32: Result := 261;
        orkPCRelative64: Result := 260;
        orkCall: Result := 283;
        orkJump: Result := 282;
      else
        raise ERCCError.Create(
          'internal error: AArch64 relocation requires an architecture code');
      end;
    archRISCV64:
      case ARelocation.Kind of
        orkNone: Result := 0;
        orkAbsolute32: Result := 1;
        orkAbsolute64: Result := 2;
        orkCall: Result := 18;
        orkJump: Result := 17;
      else
        raise ERCCError.Create(
          'internal error: RISC-V relocation requires an architecture code');
      end;
  else
    raise ERCCError.Create('internal error: relocation target is unsupported');
  end;
end;

procedure AddSectionHeader(ABuffer: TByteBuffer; AName, AType: LongWord;
  AFlags, AAddress, AOffset, ASize: QWord; ALink, AInfo: LongWord;
  AAlignment, AEntrySize: QWord);
begin
  ABuffer.Add32(AName);
  ABuffer.Add32(AType);
  ABuffer.Add64(AFlags);
  ABuffer.Add64(AAddress);
  ABuffer.Add64(AOffset);
  ABuffer.Add64(ASize);
  ABuffer.Add32(ALink);
  ABuffer.Add32(AInfo);
  ABuffer.Add64(AAlignment);
  ABuffer.Add64(AEntrySize);
end;

procedure WriteELF64Relocatable(const AFileName: string;
  AObject: TObjectFile);
var
  FileBuffer, ShStr, StrTab, SymTab: TByteBuffer;
  RelocationBuffers: array of TByteBuffer;
  RelocationTargets: array of LongInt;
  SectionNameOffsets, SymbolNameOffsets: array of LongWord;
  SectionOffsets: array of QWord;
  OriginalSectionCount, TotalSectionCount: LongInt;
  RelocationSectionStart, RelocationSectionCount: LongInt;
  ShStrIndex, StrTabIndex, SymTabIndex: LongInt;
  I, J, N, FirstGlobal: LongInt;
  SectionHeaderOffset, CurrentOffset: QWord;
  S: TObjectSection;
  ShIndex: Word;
  RelocationType: LongWord;
begin
  if AObject = nil then
    raise ERCCError.Create('internal error: nil object passed to ELF writer');
  AObject.Validate;
  OriginalSectionCount := Length(AObject.Sections);
  SetLength(RelocationBuffers, 0);
  SetLength(RelocationTargets, 0);
  for I := 0 to High(AObject.Relocations) do
  begin
    J := -1;
    for N := 0 to High(RelocationTargets) do
      if RelocationTargets[N] = AObject.Relocations[I].SectionIndex then
      begin
        J := N;
        Break;
      end;
    if J < 0 then
    begin
      J := Length(RelocationTargets);
      SetLength(RelocationTargets, J + 1);
      SetLength(RelocationBuffers, J + 1);
      RelocationTargets[J] := AObject.Relocations[I].SectionIndex;
      RelocationBuffers[J] := TByteBuffer.Create;
    end;
    RelocationType := ELFRelocationType(AObject.Target,
      AObject.Relocations[I]);
    RelocationBuffers[J].Add64(AObject.Relocations[I].Offset);
    RelocationBuffers[J].Add64(
      (QWord(AObject.Relocations[I].SymbolIndex + 1) shl 32) or
      QWord(RelocationType));
    RelocationBuffers[J].Add64(QWord(AObject.Relocations[I].Addend));
  end;
  RelocationSectionCount := Length(RelocationTargets);
  RelocationSectionStart := OriginalSectionCount;
  ShStrIndex := RelocationSectionStart + RelocationSectionCount;
  StrTabIndex := ShStrIndex + 1;
  SymTabIndex := ShStrIndex + 2;
  TotalSectionCount := SymTabIndex + 1;
  SetLength(SectionNameOffsets, TotalSectionCount);
  SetLength(SectionOffsets, TotalSectionCount);
  SetLength(SymbolNameOffsets, Length(AObject.Symbols));

  FileBuffer := TByteBuffer.Create;
  ShStr := TByteBuffer.Create;
  StrTab := TByteBuffer.Create;
  SymTab := TByteBuffer.Create;
  try
    ShStr.Add8(0);
    StrTab.Add8(0);
    for I := 0 to OriginalSectionCount - 1 do
    begin
      SectionNameOffsets[I] := LongWord(ShStr.Size);
      ShStr.AddStringZ(AObject.Sections[I].Name);
    end;
    for I := 0 to RelocationSectionCount - 1 do
    begin
      SectionNameOffsets[RelocationSectionStart + I] := LongWord(ShStr.Size);
      ShStr.AddStringZ('.rela' +
        AObject.Sections[RelocationTargets[I]].Name);
    end;
    SectionNameOffsets[ShStrIndex] := LongWord(ShStr.Size);
    ShStr.AddStringZ('.shstrtab');
    SectionNameOffsets[StrTabIndex] := LongWord(ShStr.Size);
    ShStr.AddStringZ('.strtab');
    SectionNameOffsets[SymTabIndex] := LongWord(ShStr.Size);
    ShStr.AddStringZ('.symtab');

    for I := 0 to High(AObject.Symbols) do
    begin
      SymbolNameOffsets[I] := LongWord(StrTab.Size);
      StrTab.AddStringZ(AObject.Symbols[I].Name);
    end;


    for I := 1 to 24 do SymTab.Add8(0);
    FirstGlobal := Length(AObject.Symbols) + 1;
    for I := 0 to High(AObject.Symbols) do
    begin
      if (FirstGlobal = Length(AObject.Symbols) + 1) and
         (AObject.Symbols[I].Binding <> osbLocal) then
        FirstGlobal := I + 1;
      SymTab.Add32(SymbolNameOffsets[I]);
      SymTab.Add8(SymbolInfo(AObject.Symbols[I]));
      SymTab.Add8(SymbolOther(AObject.Symbols[I]));
      if AObject.Symbols[I].IsDefined then
        ShIndex := Word(AObject.Symbols[I].SectionIndex)
      else
        ShIndex := SHN_UNDEF;
      SymTab.Add16(ShIndex);
      SymTab.Add64(AObject.Symbols[I].Value);
      SymTab.Add64(AObject.Symbols[I].Size);
    end;
    if FirstGlobal = Length(AObject.Symbols) + 1 then
      FirstGlobal := Length(AObject.Symbols) + 1;

    AddELFIdent(FileBuffer);
    FileBuffer.Add16(ET_REL);
    FileBuffer.Add16(AObject.Target.ELFMachine);
    FileBuffer.Add32(EV_CURRENT);
    FileBuffer.Add64(0);
    FileBuffer.Add64(0);
    FileBuffer.Add64(0);
    FileBuffer.Add32(AObject.Target.ELFFlags);
    FileBuffer.Add16(64);
    FileBuffer.Add16(0);
    FileBuffer.Add16(0);
    FileBuffer.Add16(64);
    FileBuffer.Add16(TotalSectionCount);
    FileBuffer.Add16(ShStrIndex);

    CurrentOffset := 64;
    for I := 1 to OriginalSectionCount - 1 do
    begin
      S := AObject.Sections[I];
      if SectionType(S) = SHT_NOBITS then
      begin
        SectionOffsets[I] := CurrentOffset;
        Continue;
      end;
      CurrentOffset := AlignELF(CurrentOffset, S.Alignment);
      while QWord(FileBuffer.Size) < CurrentOffset do FileBuffer.Add8(0);
      SectionOffsets[I] := CurrentOffset;
      FileBuffer.Append(S.Data);
      CurrentOffset := QWord(FileBuffer.Size);
    end;

    for I := 0 to RelocationSectionCount - 1 do
    begin
      CurrentOffset := AlignELF(QWord(FileBuffer.Size), 8);
      while QWord(FileBuffer.Size) < CurrentOffset do FileBuffer.Add8(0);
      SectionOffsets[RelocationSectionStart + I] := CurrentOffset;
      FileBuffer.Append(RelocationBuffers[I]);
    end;

    CurrentOffset := QWord(FileBuffer.Size);
    SectionOffsets[ShStrIndex] := CurrentOffset;
    FileBuffer.Append(ShStr);
    CurrentOffset := QWord(FileBuffer.Size);
    SectionOffsets[StrTabIndex] := CurrentOffset;
    FileBuffer.Append(StrTab);
    CurrentOffset := AlignELF(QWord(FileBuffer.Size), 8);
    while QWord(FileBuffer.Size) < CurrentOffset do FileBuffer.Add8(0);
    SectionOffsets[SymTabIndex] := CurrentOffset;
    FileBuffer.Append(SymTab);

    SectionHeaderOffset := AlignELF(QWord(FileBuffer.Size), 8);
    while QWord(FileBuffer.Size) < SectionHeaderOffset do FileBuffer.Add8(0);


    AddSectionHeader(FileBuffer, 0, SHT_NULL, 0, 0, 0, 0,
      0, 0, 0, 0);
    for I := 1 to OriginalSectionCount - 1 do
    begin
      S := AObject.Sections[I];
      AddSectionHeader(FileBuffer, SectionNameOffsets[I], SectionType(S),
        SectionFlags(S), 0, SectionOffsets[I], S.Size,
        LongWord(S.LinkSection), LongWord(S.Info), S.Alignment, S.EntrySize);
    end;
    for I := 0 to RelocationSectionCount - 1 do
      AddSectionHeader(FileBuffer,
        SectionNameOffsets[RelocationSectionStart + I], SHT_RELA,
        0, 0, SectionOffsets[RelocationSectionStart + I],
        QWord(RelocationBuffers[I].Size), SymTabIndex,
        RelocationTargets[I], 8, 24);
    AddSectionHeader(FileBuffer, SectionNameOffsets[ShStrIndex], SHT_STRTAB,
      0, 0, SectionOffsets[ShStrIndex], QWord(ShStr.Size), 0, 0, 1, 0);
    AddSectionHeader(FileBuffer, SectionNameOffsets[StrTabIndex], SHT_STRTAB,
      0, 0, SectionOffsets[StrTabIndex], QWord(StrTab.Size), 0, 0, 1, 0);
    AddSectionHeader(FileBuffer, SectionNameOffsets[SymTabIndex], SHT_SYMTAB,
      0, 0, SectionOffsets[SymTabIndex], QWord(SymTab.Size),
      StrTabIndex, FirstGlobal, 8, 24);

    FileBuffer.Patch64(40, SectionHeaderOffset);
    FileBuffer.SaveToFile(AFileName);
  finally
    for I := 0 to High(RelocationBuffers) do RelocationBuffers[I].Free;
    SymTab.Free;
    StrTab.Free;
    ShStr.Free;
    FileBuffer.Free;
  end;
end;

end.
