unit rcc_elf_debug;

{$mode objfpc}{$H+}

interface

uses
  rcc_object_model;

procedure AppendELF64DebugSections(const AFileName: string;
  ADebugObject: TObjectFile; ATextOffset, ATextAddress, ATextSize,
  ADataOffset, ADataAddress, ADataSize: QWord);

implementation

uses
  SysUtils, BaseUnix, rcc_types, rcc_buffer;

const
  SHT_NULL = LongWord(0);
  SHT_PROGBITS = LongWord(1);
  SHT_SYMTAB = LongWord(2);
  SHT_STRTAB = LongWord(3);
  SHF_WRITE = QWord(1);
  SHF_ALLOC = QWord(2);
  SHF_EXECINSTR = QWord(4);
  SHF_MERGE = QWord($10);
  SHF_STRINGS = QWord($20);
  R_X86_64_64 = LongWord(1);

function AlignValue(AValue, AAlignment: QWord): QWord;
begin
  if AAlignment = 0 then Exit(AValue);
  Result := (AValue + AAlignment - 1) and not (AAlignment - 1);
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

function SymbolInfo(const ASymbol: TObjectSymbol): Byte;
var
  Binding, SymbolType: Byte;
begin
  case ASymbol.Binding of
    osbLocal: Binding := 0;
    osbGlobal: Binding := 1;
    osbWeak: Binding := 2;
  else
    Binding := 0;
  end;
  case ASymbol.SymbolType of
    ostObject: SymbolType := 1;
    ostFunction: SymbolType := 2;
    ostSection: SymbolType := 3;
    ostFile: SymbolType := 4;
    ostTLS: SymbolType := 6;
  else
    SymbolType := 0;
  end;
  Result := (Binding shl 4) or SymbolType;
end;

function SymbolOther(const ASymbol: TObjectSymbol): Byte;
begin
  case ASymbol.Visibility of
    osvInternal: Result := 1;
    osvHidden: Result := 2;
    osvProtected: Result := 3;
  else
    Result := 0;
  end;
end;

procedure AppendELF64DebugSections(const AFileName: string;
  ADebugObject: TObjectFile; ATextOffset, ATextAddress, ATextSize,
  ADataOffset, ADataAddress, ADataSize: QWord);
var
  FileBuffer, ShStr, StrTab, SymTab: TByteBuffer;
  DebugObjectIndices, DebugFinalIndices: array of LongInt;
  DebugOffsets, SectionNameOffsets, SymbolNameOffsets: array of QWord;
  DebugCount, StrTabIndex, SymTabIndex, ShStrIndex, SectionCount: LongInt;
  I, N, FirstGlobal, FinalSectionIndex: LongInt;
  Relocation: TObjectRelocation;
  Symbol: TObjectSymbol;
  TargetSection: TObjectSection;
  PatchValue: Int64;
  SectionHeaderOffset, CurrentOffset, StrTabOffset, SymTabOffset,
    ShStrOffset, Flags: QWord;
  ShIndex: Word;
begin
  if ADebugObject = nil then
    raise ERCCError.Create('internal error: nil debug object for ELF append');
  SetLength(DebugObjectIndices, 0);
  for I := 1 to High(ADebugObject.Sections) do
    if ADebugObject.Sections[I].Kind = oskDebug then
    begin
      N := Length(DebugObjectIndices);
      SetLength(DebugObjectIndices, N + 1);
      DebugObjectIndices[N] := I;
    end;
  DebugCount := Length(DebugObjectIndices);
  if DebugCount = 0 then Exit;
  SetLength(DebugFinalIndices, Length(ADebugObject.Sections));
  for I := 0 to High(DebugFinalIndices) do DebugFinalIndices[I] := 0;
  if ADebugObject.FindSection('.text') >= 0 then
    DebugFinalIndices[ADebugObject.FindSection('.text')] := 1;
  if ADebugObject.FindSection('.data') >= 0 then
    DebugFinalIndices[ADebugObject.FindSection('.data')] := 2;
  for I := 0 to DebugCount - 1 do
    DebugFinalIndices[DebugObjectIndices[I]] := 3 + I;

  for I := 0 to High(ADebugObject.Relocations) do
  begin
    Relocation := ADebugObject.Relocations[I];
    if (Relocation.ArchitectureCode <> R_X86_64_64) or
       (Relocation.Kind <> orkAbsolute64) then
      raise ERCCError.Create(
        'internal error: final DWARF contains an unexpected relocation');
    Symbol := ADebugObject.Symbols[Relocation.SymbolIndex];
    if not Symbol.IsDefined then
      raise ERCCError.Create('internal error: final DWARF target is undefined');
    TargetSection := ADebugObject.Sections[Symbol.SectionIndex];
    if TargetSection.Name = '.text' then
      PatchValue := Int64(ATextAddress) + Int64(Symbol.Value) +
        Relocation.Addend
    else if TargetSection.Name = '.data' then
      PatchValue := Int64(ADataAddress) + Int64(Symbol.Value) +
        Relocation.Addend
    else
      raise ERCCError.Create(
        'internal error: final DWARF relocation targets an invalid section');
    ADebugObject.Section(Relocation.SectionIndex).Data.Patch64(
      LongInt(Relocation.Offset), QWord(PatchValue));
  end;

  StrTabIndex := 3 + DebugCount;
  SymTabIndex := StrTabIndex + 1;
  ShStrIndex := SymTabIndex + 1;
  SectionCount := ShStrIndex + 1;
  SetLength(DebugOffsets, DebugCount);
  SetLength(SectionNameOffsets, SectionCount);
  SetLength(SymbolNameOffsets, Length(ADebugObject.Symbols));
  FileBuffer := TByteBuffer.Create;
  ShStr := TByteBuffer.Create;
  StrTab := TByteBuffer.Create;
  SymTab := TByteBuffer.Create;
  try
    FileBuffer.LoadFromFile(AFileName);
    ShStr.Add8(0);
    StrTab.Add8(0);
    SectionNameOffsets[1] := QWord(ShStr.Size);
    ShStr.AddStringZ('.text');
    SectionNameOffsets[2] := QWord(ShStr.Size);
    ShStr.AddStringZ('.data');
    for I := 0 to DebugCount - 1 do
    begin
      SectionNameOffsets[3 + I] := QWord(ShStr.Size);
      ShStr.AddStringZ(ADebugObject.Sections[DebugObjectIndices[I]].Name);
    end;
    SectionNameOffsets[StrTabIndex] := QWord(ShStr.Size);
    ShStr.AddStringZ('.strtab');
    SectionNameOffsets[SymTabIndex] := QWord(ShStr.Size);
    ShStr.AddStringZ('.symtab');
    SectionNameOffsets[ShStrIndex] := QWord(ShStr.Size);
    ShStr.AddStringZ('.shstrtab');

    for I := 0 to High(ADebugObject.Symbols) do
    begin
      if ADebugObject.Symbols[I].Name = '' then
        SymbolNameOffsets[I] := 0
      else
      begin
        SymbolNameOffsets[I] := QWord(StrTab.Size);
        StrTab.AddStringZ(ADebugObject.Symbols[I].Name);
      end;
    end;

    for I := 1 to 24 do SymTab.Add8(0);
    FirstGlobal := Length(ADebugObject.Symbols) + 1;
    for I := 0 to High(ADebugObject.Symbols) do
    begin
      Symbol := ADebugObject.Symbols[I];
      if (FirstGlobal = Length(ADebugObject.Symbols) + 1) and
         (Symbol.Binding <> osbLocal) then FirstGlobal := I + 1;
      SymTab.Add32(LongWord(SymbolNameOffsets[I]));
      SymTab.Add8(SymbolInfo(Symbol));
      SymTab.Add8(SymbolOther(Symbol));
      FinalSectionIndex := 0;
      if Symbol.IsDefined then
        FinalSectionIndex := DebugFinalIndices[Symbol.SectionIndex];
      ShIndex := Word(FinalSectionIndex);
      SymTab.Add16(ShIndex);
      if FinalSectionIndex = 1 then
        SymTab.Add64(ATextAddress + Symbol.Value)
      else if FinalSectionIndex = 2 then
        SymTab.Add64(ADataAddress + Symbol.Value)
      else
        SymTab.Add64(Symbol.Value);
      SymTab.Add64(Symbol.Size);
    end;
    if FirstGlobal = Length(ADebugObject.Symbols) + 1 then
      FirstGlobal := Length(ADebugObject.Symbols) + 1;

    for I := 0 to DebugCount - 1 do
    begin
      CurrentOffset := AlignValue(QWord(FileBuffer.Size),
        ADebugObject.Sections[DebugObjectIndices[I]].Alignment);
      while QWord(FileBuffer.Size) < CurrentOffset do FileBuffer.Add8(0);
      DebugOffsets[I] := CurrentOffset;
      FileBuffer.Append(ADebugObject.Sections[DebugObjectIndices[I]].Data);
    end;
    StrTabOffset := QWord(FileBuffer.Size);
    FileBuffer.Append(StrTab);
    CurrentOffset := AlignValue(QWord(FileBuffer.Size), 8);
    while QWord(FileBuffer.Size) < CurrentOffset do FileBuffer.Add8(0);
    SymTabOffset := CurrentOffset;
    FileBuffer.Append(SymTab);
    ShStrOffset := QWord(FileBuffer.Size);
    FileBuffer.Append(ShStr);
    SectionHeaderOffset := AlignValue(QWord(FileBuffer.Size), 8);
    while QWord(FileBuffer.Size) < SectionHeaderOffset do FileBuffer.Add8(0);

    AddSectionHeader(FileBuffer, 0, SHT_NULL, 0, 0, 0, 0,
      0, 0, 0, 0);
    AddSectionHeader(FileBuffer, LongWord(SectionNameOffsets[1]),
      SHT_PROGBITS, SHF_ALLOC or SHF_EXECINSTR, ATextAddress,
      ATextOffset, ATextSize, 0, 0, 16, 0);
    if ADataSize = 0 then
      AddSectionHeader(FileBuffer, LongWord(SectionNameOffsets[2]),
        SHT_PROGBITS, SHF_ALLOC or SHF_WRITE, 0,
        0, 0, 0, 0, 1, 0)
    else
      AddSectionHeader(FileBuffer, LongWord(SectionNameOffsets[2]),
        SHT_PROGBITS, SHF_ALLOC or SHF_WRITE, ADataAddress,
        ADataOffset, ADataSize, 0, 0, 16, 0);
    for I := 0 to DebugCount - 1 do
    begin
      Flags := 0;
      if osfMerge in ADebugObject.Sections[DebugObjectIndices[I]].Flags then
        Flags := Flags or SHF_MERGE;
      if osfStrings in ADebugObject.Sections[DebugObjectIndices[I]].Flags then
        Flags := Flags or SHF_STRINGS;
      AddSectionHeader(FileBuffer, LongWord(SectionNameOffsets[3 + I]),
        SHT_PROGBITS, Flags, 0, DebugOffsets[I],
        QWord(ADebugObject.Sections[DebugObjectIndices[I]].Data.Size),
        0, 0, ADebugObject.Sections[DebugObjectIndices[I]].Alignment,
        QWord(Ord(osfStrings in
          ADebugObject.Sections[DebugObjectIndices[I]].Flags)));
    end;
    AddSectionHeader(FileBuffer, LongWord(SectionNameOffsets[StrTabIndex]),
      SHT_STRTAB, 0, 0, StrTabOffset,
      QWord(StrTab.Size), 0, 0, 1, 0);
    AddSectionHeader(FileBuffer, LongWord(SectionNameOffsets[SymTabIndex]),
      SHT_SYMTAB, 0, 0, SymTabOffset, QWord(SymTab.Size),
      StrTabIndex, FirstGlobal, 8, 24);
    AddSectionHeader(FileBuffer, LongWord(SectionNameOffsets[ShStrIndex]),
      SHT_STRTAB, 0, 0, ShStrOffset, QWord(ShStr.Size), 0, 0, 1, 0);

    FileBuffer.Patch64(40, SectionHeaderOffset);
    FileBuffer.Patch16(58, 64);
    FileBuffer.Patch16(60, Word(SectionCount));
    FileBuffer.Patch16(62, Word(ShStrIndex));
    FileBuffer.SaveToFile(AFileName);
    if fpChmod(PChar(AFileName), &755) <> 0 then
      raise ERCCError.Create('error: cannot restore executable mode: ' +
        AFileName);
  finally
    SymTab.Free;
    StrTab.Free;
    ShStr.Free;
    FileBuffer.Free;
  end;
end;

end.
