unit rcc_macho;

{$mode objfpc}{$H+}

interface

uses
  rcc_object_model;

procedure WriteMachO64Relocatable(const AFileName: string;
  AObject: TObjectFile);

implementation

uses
  SysUtils, rcc_types, rcc_buffer, rcc_arch;

const
  MH_MAGIC_64 = LongWord($FEEDFACF);
  CPU_ARCH_ABI64 = LongWord($01000000);
  CPU_TYPE_X86 = LongWord(7);
  CPU_TYPE_ARM = LongWord(12);
  CPU_SUBTYPE_X86_64_ALL = LongWord(3);
  CPU_SUBTYPE_ARM64_ALL = LongWord(0);
  MH_OBJECT = LongWord(1);
  MH_SUBSECTIONS_VIA_SYMBOLS = LongWord($2000);

  LC_SEGMENT_64 = LongWord($19);
  LC_SYMTAB = LongWord($2);
  LC_DYSYMTAB = LongWord($B);
  LC_BUILD_VERSION = LongWord($32);
  PLATFORM_MACOS = LongWord(1);

  VM_PROT_READ = LongWord(1);
  VM_PROT_WRITE = LongWord(2);
  VM_PROT_EXECUTE = LongWord(4);

  S_REGULAR = LongWord(0);
  S_ZEROFILL = LongWord(1);
  S_THREAD_LOCAL_REGULAR = LongWord($11);
  S_THREAD_LOCAL_ZEROFILL = LongWord($12);
  S_ATTR_SOME_INSTRUCTIONS = LongWord($00000400);
  S_ATTR_PURE_INSTRUCTIONS = LongWord($80000000);
  S_ATTR_DEBUG = LongWord($02000000);

  N_EXT = Byte($01);
  N_UNDF = Byte($00);
  N_SECT = Byte($0E);
  N_PEXT = Byte($10);
  N_WEAK_REF = Word($0040);
  N_WEAK_DEF = Word($0080);

  X86_64_RELOC_UNSIGNED = LongWord(0);
  X86_64_RELOC_SIGNED = LongWord(1);
  X86_64_RELOC_BRANCH = LongWord(2);
  X86_64_RELOC_GOT_LOAD = LongWord(3);
  X86_64_RELOC_GOT = LongWord(4);
  X86_64_RELOC_TLV = LongWord(9);

  ARM64_RELOC_UNSIGNED = LongWord(0);
  ARM64_RELOC_BRANCH26 = LongWord(2);
  ARM64_RELOC_PAGE21 = LongWord(3);
  ARM64_RELOC_PAGEOFF12 = LongWord(4);
  ARM64_RELOC_GOT_LOAD_PAGE21 = LongWord(5);
  ARM64_RELOC_GOT_LOAD_PAGEOFF12 = LongWord(6);

type
  TMachSection = record
    OriginalIndex: LongInt;
    SectionName: string;
    SegmentName: string;
    Address: QWord;
    Size: QWord;
    FileOffset: LongWord;
    AlignmentPower: LongWord;
    RelocationOffset: LongWord;
    RelocationCount: LongWord;
    Flags: LongWord;
    HasFileData: Boolean;
    Data: TByteBuffer;
  end;
  TMachSectionArray = array of TMachSection;
  TLongIntArray = array of LongInt;

function AlignValue(AValue, AAlignment: QWord): QWord;
begin
  if AAlignment <= 1 then Exit(AValue);
  if (AAlignment and (AAlignment - 1)) <> 0 then
    raise ERCCError.Create('internal error: non-power-of-two Mach-O alignment');
  Result := (AValue + AAlignment - 1) and not (AAlignment - 1);
end;

function Read32(ABuffer: TByteBuffer; AOffset: LongInt): LongWord;
begin
  Result := LongWord(ABuffer.ByteAt(AOffset)) or
    (LongWord(ABuffer.ByteAt(AOffset + 1)) shl 8) or
    (LongWord(ABuffer.ByteAt(AOffset + 2)) shl 16) or
    (LongWord(ABuffer.ByteAt(AOffset + 3)) shl 24);
end;

procedure AddFixedName(ABuffer: TByteBuffer; const AName: string);
var
  I: LongInt;
begin
  if Length(AName) > 16 then
    raise ERCCError.Create('error: Mach-O section name exceeds 16 bytes: ' +
      AName);
  for I := 1 to Length(AName) do ABuffer.Add8(Byte(Ord(AName[I])));
  for I := Length(AName) + 1 to 16 do ABuffer.Add8(0);
end;

function AlignmentPower(AAlignment: QWord): LongWord;
var
  Value: QWord;
begin
  Result := 0;
  Value := 1;
  while Value < AAlignment do
  begin
    Value := Value shl 1;
    Inc(Result);
  end;
  if Value <> AAlignment then
    raise ERCCError.Create('internal error: invalid Mach-O section alignment');
end;

procedure MapSection(ASection: TObjectSection; out ASectionName,
  ASegmentName: string; out AFlags: LongWord; out AHasFileData: Boolean);
begin
  AFlags := S_REGULAR;
  AHasFileData := not (ASection.Kind in [oskBSS, oskTLSBSS]);
  case ASection.Kind of
    oskText:
      begin
        ASectionName := '__text';
        ASegmentName := '__TEXT';
        AFlags := S_REGULAR or S_ATTR_PURE_INSTRUCTIONS or
          S_ATTR_SOME_INSTRUCTIONS;
      end;
    oskReadOnlyData:
      begin
        ASectionName := '__const';
        ASegmentName := '__TEXT';
      end;
    oskData:
      begin
        ASectionName := '__data';
        ASegmentName := '__DATA';
      end;
    oskBSS:
      begin
        ASectionName := '__bss';
        ASegmentName := '__DATA';
        AFlags := S_ZEROFILL;
      end;
    oskTLSData:
      begin
        ASectionName := '__thread_data';
        ASegmentName := '__DATA';
        AFlags := S_THREAD_LOCAL_REGULAR;
      end;
    oskTLSBSS:
      begin
        ASectionName := '__thread_bss';
        ASegmentName := '__DATA';
        AFlags := S_THREAD_LOCAL_ZEROFILL;
      end;
    oskDebug:
      begin
        ASectionName := ASection.Name;
        if (Length(ASectionName) > 0) and (ASectionName[1] = '.') then
          ASectionName[1] := '_';
        if Pos('__', ASectionName) <> 1 then
          ASectionName := '_' + ASectionName;
        ASegmentName := '__DWARF';
        AFlags := S_REGULAR or S_ATTR_DEBUG;
      end;
  else
    begin
      ASectionName := ASection.Name;
      if (Length(ASectionName) > 0) and (ASectionName[1] = '.') then
        ASectionName[1] := '_';
      if Pos('__', ASectionName) <> 1 then
        ASectionName := '_' + ASectionName;
      ASegmentName := '__DATA';
    end;
  end;
end;

function FindMappedSection(const ASections: TMachSectionArray;
  AOriginalIndex: LongInt): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(ASections) do
    if ASections[I].OriginalIndex = AOriginalIndex then Exit(I);
  Result := -1;
end;

function IsSkippedSection(ASection: TObjectSection): Boolean;
begin
  Result := (ASection.Kind = oskNull) or
    (ASection.Name = '.note.GNU-stack');
end;

function MachSymbolName(const ATarget: TTargetDescriptor;
  const ASymbol: TObjectSymbol): string;
begin
  Result := ASymbol.Name;
  if (Result <> '') and (ASymbol.SymbolType <> ostFile) and
     (ATarget.SymbolPrefix <> '') and
     (Copy(Result, 1, Length(ATarget.SymbolPrefix)) <>
      ATarget.SymbolPrefix) then
    Result := ATarget.SymbolPrefix + Result;
end;

procedure SortSymbolOrder(AObject: TObjectFile; out AOrder,
  ARemap: TLongIntArray; out ANLocal, ANExternalDefined,
  ANUndefined: LongWord);
var
  I, N: LongInt;

  procedure AddOldIndex(AIndex: LongInt);
  begin
    N := Length(AOrder);
    SetLength(AOrder, N + 1);
    AOrder[N] := AIndex;
    ARemap[AIndex] := N;
  end;

begin
  SetLength(AOrder, 0);
  SetLength(ARemap, Length(AObject.Symbols));
  ANLocal := 0;
  ANExternalDefined := 0;
  ANUndefined := 0;
  for I := 0 to High(AObject.Symbols) do
    if AObject.Symbols[I].IsDefined and
       (AObject.Symbols[I].Binding = osbLocal) then
    begin
      AddOldIndex(I);
      Inc(ANLocal);
    end;
  for I := 0 to High(AObject.Symbols) do
    if AObject.Symbols[I].IsDefined and
       (AObject.Symbols[I].Binding <> osbLocal) then
    begin
      AddOldIndex(I);
      Inc(ANExternalDefined);
    end;
  for I := 0 to High(AObject.Symbols) do
    if not AObject.Symbols[I].IsDefined then
    begin
      AddOldIndex(I);
      Inc(ANUndefined);
    end;
end;

procedure RelocationEncoding(const ATarget: TTargetDescriptor;
  const ARelocation: TObjectRelocation; out AType, ALength: LongWord;
  out APCRelative: Boolean; out AImplicitAddend: Int64);
begin
  APCRelative := False;
  AImplicitAddend := ARelocation.Addend;
  case ATarget.Architecture of
    archX86_64:
      case ARelocation.Kind of
        orkAbsolute64:
          begin AType := X86_64_RELOC_UNSIGNED; ALength := 3; end;
        orkAbsolute32:
          begin AType := X86_64_RELOC_UNSIGNED; ALength := 2; end;
        orkPCRelative32:
          begin
            AType := X86_64_RELOC_SIGNED; ALength := 2;
            APCRelative := True;
            AImplicitAddend := ARelocation.Addend + 4;
          end;
        orkCall, orkJump, orkPLT:
          begin
            AType := X86_64_RELOC_BRANCH; ALength := 2;
            APCRelative := True;
            AImplicitAddend := ARelocation.Addend + 4;
          end;
        orkGOT:
          begin
            AType := X86_64_RELOC_GOT_LOAD; ALength := 2;
            APCRelative := True;
            AImplicitAddend := ARelocation.Addend + 4;
          end;
        orkTLS:
          begin
            AType := X86_64_RELOC_TLV; ALength := 2;
            APCRelative := True;
            AImplicitAddend := ARelocation.Addend + 4;
          end;
      else
        raise ERCCError.Create('error: unsupported x86-64 Mach-O relocation ' +
          RelocationKindName(ARelocation.Kind));
      end;
    archAArch64:
      case ARelocation.Kind of
        orkAbsolute64:
          begin AType := ARM64_RELOC_UNSIGNED; ALength := 3; end;
        orkAbsolute32:
          begin AType := ARM64_RELOC_UNSIGNED; ALength := 2; end;
        orkCall, orkJump:
          begin
            AType := ARM64_RELOC_BRANCH26; ALength := 2;
            APCRelative := True;
          end;
        orkPage21:
          begin
            AType := ARM64_RELOC_PAGE21; ALength := 2;
            APCRelative := True;
          end;
        orkPageOffset12:
          begin AType := ARM64_RELOC_PAGEOFF12; ALength := 2; end;
        orkGOTPage21:
          begin
            AType := ARM64_RELOC_GOT_LOAD_PAGE21; ALength := 2;
            APCRelative := True;
          end;
        orkGOTPageOffset12:
          begin AType := ARM64_RELOC_GOT_LOAD_PAGEOFF12; ALength := 2; end;
      else
        raise ERCCError.Create('error: unsupported arm64 Mach-O relocation ' +
          RelocationKindName(ARelocation.Kind));
      end;
  else
    raise ERCCError.Create('error: Mach-O output supports x86-64 and arm64');
  end;
end;

procedure PatchImplicitAddend(ASection: TByteBuffer;
  const ATarget: TTargetDescriptor; const ARelocation: TObjectRelocation;
  ALength: LongWord; AAddend: Int64);
var
  Offset: LongInt;
  Instruction, Mask: LongWord;
  PageAddend: Int64;
begin
  Offset := LongInt(ARelocation.Offset);
  if ATarget.Architecture = archX86_64 then
  begin
    case ALength of
      2: ASection.Patch32(Offset, LongInt(AAddend));
      3: ASection.Patch64(Offset, QWord(AAddend));
    else
      raise ERCCError.Create('internal error: invalid x86 Mach-O addend width');
    end;
    Exit;
  end;

  case ARelocation.Kind of
    orkAbsolute64: ASection.Patch64(Offset, QWord(AAddend));
    orkAbsolute32: ASection.Patch32(Offset, LongInt(AAddend));
    orkCall, orkJump:
      begin
        if (AAddend and 3) <> 0 then
          raise ERCCError.Create('error: unaligned arm64 branch addend');
        Instruction := Read32(ASection, Offset);
        Instruction := (Instruction and $FC000000) or
          (LongWord(AAddend div 4) and $03FFFFFF);
        ASection.Patch32(Offset, LongInt(Instruction));
      end;
    orkPage21, orkGOTPage21:
      begin
        PageAddend := AAddend div 4096;
        Instruction := Read32(ASection, Offset);
        Mask := (LongWord(3) shl 29) or (LongWord($7FFFF) shl 5);
        Instruction := Instruction and not Mask;
        Instruction := Instruction or
          ((LongWord(PageAddend) and 3) shl 29) or
          (((LongWord(PageAddend) shr 2) and $7FFFF) shl 5);
        ASection.Patch32(Offset, LongInt(Instruction));
      end;
    orkPageOffset12, orkGOTPageOffset12:
      begin
        Instruction := Read32(ASection, Offset);
        Instruction := (Instruction and not (LongWord($FFF) shl 10)) or
          ((LongWord(AAddend) and $FFF) shl 10);
        ASection.Patch32(Offset, LongInt(Instruction));
      end;
  end;
end;

procedure AddSectionCommand(ABuffer: TByteBuffer;
  const ASection: TMachSection);
begin
  AddFixedName(ABuffer, ASection.SectionName);
  AddFixedName(ABuffer, ASection.SegmentName);
  ABuffer.Add64(ASection.Address);
  ABuffer.Add64(ASection.Size);
  ABuffer.Add32(ASection.FileOffset);
  ABuffer.Add32(ASection.AlignmentPower);
  ABuffer.Add32(ASection.RelocationOffset);
  ABuffer.Add32(ASection.RelocationCount);
  ABuffer.Add32(ASection.Flags);
  ABuffer.Add32(0);
  ABuffer.Add32(0);
  ABuffer.Add32(0);
end;

procedure WriteMachO64Relocatable(const AFileName: string;
  AObject: TObjectFile);
var
  FileBuffer, StringTable, SymbolTable: TByteBuffer;
  Sections: TMachSectionArray;
  SymbolOrder, SymbolRemap, RelocationOrder: TLongIntArray;
  StringOffsets: array of LongWord;
  I, J, N, Mapped, OldSymbol, TargetSection, Selected,
    LoadCommandSize: LongInt;
  HeaderEnd, CurrentFileOffset, CurrentAddress, RelocationEnd,
    SymbolOffset, StringOffset, SegmentFileOffset: QWord;
  SourceObjectAddress, TargetObjectAddress: Int64;
  CPUType, CPUSubtype, RelocType, RelocLength, RelocWord,
    SymbolNumber: LongWord;
  PCRelative, ExternalRelocation: Boolean;
  ImplicitAddend: Int64;
  SymbolType: Byte;
  SymbolDescription: Word;
  SymbolValue: QWord;
  NLocal, NExternalDefined, NUndefined: LongWord;
  SourceSection: TObjectSection;
  Symbol: TObjectSymbol;
  Relocation: TObjectRelocation;
begin
  if AObject = nil then
    raise ERCCError.Create('internal error: nil object passed to Mach-O writer');
  if AObject.Target.ObjectFormat <> ofMachO64 then
    raise ERCCError.Create('internal error: Mach-O writer selected for ' +
      ObjectFormatName(AObject.Target.ObjectFormat));
  case AObject.Target.Architecture of
    archX86_64:
      begin
        CPUType := CPU_ARCH_ABI64 or CPU_TYPE_X86;
        CPUSubtype := CPU_SUBTYPE_X86_64_ALL;
      end;
    archAArch64:
      begin
        CPUType := CPU_ARCH_ABI64 or CPU_TYPE_ARM;
        CPUSubtype := CPU_SUBTYPE_ARM64_ALL;
      end;
  else
    raise ERCCError.Create('error: Mach-O output supports x86-64 and arm64');
  end;
  AObject.Validate;

  SetLength(Sections, 0);
  for I := 1 to High(AObject.Sections) do
  begin
    SourceSection := AObject.Sections[I];
    if IsSkippedSection(SourceSection) then Continue;
    N := Length(Sections);
    SetLength(Sections, N + 1);
    Sections[N].OriginalIndex := I;
    MapSection(SourceSection, Sections[N].SectionName,
      Sections[N].SegmentName, Sections[N].Flags,
      Sections[N].HasFileData);
    Sections[N].AlignmentPower := AlignmentPower(SourceSection.Alignment);
    Sections[N].Size := SourceSection.Size;
    Sections[N].RelocationCount := 0;
    Sections[N].Data := TByteBuffer.Create;
    if Sections[N].HasFileData then
      Sections[N].Data.Append(SourceSection.Data);
  end;

  FileBuffer := TByteBuffer.Create;
  StringTable := TByteBuffer.Create;
  SymbolTable := TByteBuffer.Create;
  try
    LoadCommandSize := 72 + Length(Sections) * 80 + 24 + 24 + 80;
    HeaderEnd := 32 + QWord(LoadCommandSize);
    CurrentFileOffset := HeaderEnd;
    CurrentAddress := 0;
    SegmentFileOffset := 0;
    for I := 0 to High(Sections) do
    begin
      CurrentAddress := AlignValue(CurrentAddress,
        QWord(1) shl Sections[I].AlignmentPower);
      Sections[I].Address := CurrentAddress;
      Inc(CurrentAddress, Sections[I].Size);
      if Sections[I].HasFileData then
      begin
        CurrentFileOffset := AlignValue(CurrentFileOffset,
          QWord(1) shl Sections[I].AlignmentPower);
        Sections[I].FileOffset := LongWord(CurrentFileOffset);
        if SegmentFileOffset = 0 then
          SegmentFileOffset := CurrentFileOffset;
        Inc(CurrentFileOffset, Sections[I].Size);
      end
      else
        Sections[I].FileOffset := 0;
    end;

    for I := 0 to High(AObject.Relocations) do
    begin
      Relocation := AObject.Relocations[I];
      Mapped := FindMappedSection(Sections, Relocation.SectionIndex);
      if Mapped < 0 then
        raise ERCCError.Create('error: Mach-O relocation references a skipped section');
      Inc(Sections[Mapped].RelocationCount);
      RelocationEncoding(AObject.Target, Relocation, RelocType,
        RelocLength, PCRelative, ImplicitAddend);
      Symbol := AObject.Symbols[Relocation.SymbolIndex];
      ExternalRelocation := not ((Symbol.SymbolType = ostSection) and
        Symbol.IsDefined and (Symbol.Name = ''));
      if not ExternalRelocation then
      begin
        TargetSection := FindMappedSection(Sections, Symbol.SectionIndex);
        if TargetSection < 0 then
          raise ERCCError.Create(
            'error: Mach-O relocation target section was skipped');
        SourceObjectAddress := Int64(Sections[Mapped].Address +
          Relocation.Offset);
        TargetObjectAddress := Int64(Sections[TargetSection].Address +
          Symbol.Value);
        case AObject.Target.Architecture of
          archX86_64:
            if PCRelative then
              { Mach-O stores addends in the relocated field.  A local
                relocation names a section ordinal rather than a symbol, so
                preserve the object-file distance between the source field
                and the target section.  RelocationEncoding has already
                converted ELF's -4 PC addend to Mach-O's field convention. }
              Inc(ImplicitAddend, TargetObjectAddress -
                SourceObjectAddress - 4)
            else
              Inc(ImplicitAddend, TargetObjectAddress);
          archAArch64:
            case Relocation.Kind of
              orkAbsolute32, orkAbsolute64:
                Inc(ImplicitAddend, TargetObjectAddress);
              orkCall, orkJump:
                ImplicitAddend := TargetObjectAddress + ImplicitAddend -
                  SourceObjectAddress;
              orkPage21:
                ImplicitAddend :=
                  ((TargetObjectAddress + ImplicitAddend) and
                   not Int64($FFF)) -
                  (SourceObjectAddress and not Int64($FFF));
              orkPageOffset12:
                ImplicitAddend := (TargetObjectAddress +
                  ImplicitAddend) and Int64($FFF);
            else
              raise ERCCError.Create(
                'error: unsupported local arm64 Mach-O relocation ' +
                RelocationKindName(Relocation.Kind));
            end;
        end;
      end;
      PatchImplicitAddend(Sections[Mapped].Data, AObject.Target,
        Relocation, RelocLength, ImplicitAddend);
    end;

    RelocationEnd := AlignValue(CurrentFileOffset, 4);
    for I := 0 to High(Sections) do
      if Sections[I].RelocationCount <> 0 then
      begin
        Sections[I].RelocationOffset := LongWord(RelocationEnd);
        Inc(RelocationEnd, QWord(Sections[I].RelocationCount) * 8);
      end;
    SymbolOffset := AlignValue(RelocationEnd, 8);

    SortSymbolOrder(AObject, SymbolOrder, SymbolRemap,
      NLocal, NExternalDefined, NUndefined);
    StringTable.Add8(0);
    SetLength(StringOffsets, Length(SymbolOrder));
    for I := 0 to High(SymbolOrder) do
    begin
      OldSymbol := SymbolOrder[I];
      if AObject.Symbols[OldSymbol].Name = '' then
        StringOffsets[I] := 0
      else
      begin
        StringOffsets[I] := LongWord(StringTable.Size);
        StringTable.AddStringZ(MachSymbolName(AObject.Target,
          AObject.Symbols[OldSymbol]));
      end;
    end;
    StringTable.PadTo(4);

    for I := 0 to High(SymbolOrder) do
    begin
      OldSymbol := SymbolOrder[I];
      Symbol := AObject.Symbols[OldSymbol];
      SymbolDescription := 0;
      if Symbol.IsDefined then
      begin
        Mapped := FindMappedSection(Sections, Symbol.SectionIndex);
        if Mapped < 0 then
          raise ERCCError.Create('error: Mach-O symbol is defined in a skipped section');
        SymbolType := N_SECT;
        if Symbol.Binding <> osbLocal then SymbolType := SymbolType or N_EXT;
        if (Symbol.Binding <> osbLocal) and
           (Symbol.Visibility in [osvInternal, osvHidden]) then
          SymbolType := SymbolType or N_PEXT;
        SymbolValue := Sections[Mapped].Address + Symbol.Value;
        if Symbol.Binding = osbWeak then
          SymbolDescription := SymbolDescription or N_WEAK_DEF;
        SymbolTable.Add32(StringOffsets[I]);
        SymbolTable.Add8(SymbolType);
        SymbolTable.Add8(Byte(Mapped + 1));
        SymbolTable.Add16(SymbolDescription);
        SymbolTable.Add64(SymbolValue);
      end
      else
      begin
        SymbolType := N_UNDF or N_EXT;
        if Symbol.Binding = osbWeak then
          SymbolDescription := SymbolDescription or N_WEAK_REF;
        SymbolTable.Add32(StringOffsets[I]);
        SymbolTable.Add8(SymbolType);
        SymbolTable.Add8(0);
        SymbolTable.Add16(SymbolDescription);
        SymbolTable.Add64(0);
      end;
    end;
    StringOffset := SymbolOffset + QWord(SymbolTable.Size);

    FileBuffer.Add32(MH_MAGIC_64);
    FileBuffer.Add32(CPUType);
    FileBuffer.Add32(CPUSubtype);
    FileBuffer.Add32(MH_OBJECT);
    FileBuffer.Add32(4);
    FileBuffer.Add32(LoadCommandSize);
    FileBuffer.Add32(MH_SUBSECTIONS_VIA_SYMBOLS);
    FileBuffer.Add32(0);

    FileBuffer.Add32(LC_SEGMENT_64);
    FileBuffer.Add32(72 + Length(Sections) * 80);
    AddFixedName(FileBuffer, '');
    FileBuffer.Add64(0);
    FileBuffer.Add64(CurrentAddress);
    if SegmentFileOffset = 0 then FileBuffer.Add64(HeaderEnd)
    else FileBuffer.Add64(SegmentFileOffset);
    if SegmentFileOffset = 0 then FileBuffer.Add64(0)
    else FileBuffer.Add64(CurrentFileOffset - SegmentFileOffset);
    FileBuffer.Add32(VM_PROT_READ or VM_PROT_WRITE or VM_PROT_EXECUTE);
    FileBuffer.Add32(VM_PROT_READ or VM_PROT_WRITE or VM_PROT_EXECUTE);
    FileBuffer.Add32(Length(Sections));
    FileBuffer.Add32(0);
    for I := 0 to High(Sections) do AddSectionCommand(FileBuffer, Sections[I]);

    FileBuffer.Add32(LC_BUILD_VERSION);
    FileBuffer.Add32(24);
    FileBuffer.Add32(PLATFORM_MACOS);
    FileBuffer.Add32(LongWord(11) shl 16);
    FileBuffer.Add32(0);
    FileBuffer.Add32(0);

    FileBuffer.Add32(LC_SYMTAB);
    FileBuffer.Add32(24);
    FileBuffer.Add32(LongWord(SymbolOffset));
    FileBuffer.Add32(Length(SymbolOrder));
    FileBuffer.Add32(LongWord(StringOffset));
    FileBuffer.Add32(StringTable.Size);

    FileBuffer.Add32(LC_DYSYMTAB);
    FileBuffer.Add32(80);
    FileBuffer.Add32(0);
    FileBuffer.Add32(NLocal);
    FileBuffer.Add32(NLocal);
    FileBuffer.Add32(NExternalDefined);
    FileBuffer.Add32(NLocal + NExternalDefined);
    FileBuffer.Add32(NUndefined);
    for I := 1 to 12 do FileBuffer.Add32(0);

    for I := 0 to High(Sections) do
      if Sections[I].HasFileData then
      begin
        while QWord(FileBuffer.Size) < Sections[I].FileOffset do
          FileBuffer.Add8(0);
        FileBuffer.Append(Sections[I].Data);
      end;
    while QWord(FileBuffer.Size) < AlignValue(CurrentFileOffset, 4) do
      FileBuffer.Add8(0);

    for I := 0 to High(Sections) do
      if Sections[I].RelocationCount <> 0 then
      begin
        SetLength(RelocationOrder, 0);
        for J := 0 to High(AObject.Relocations) do
          if AObject.Relocations[J].SectionIndex = Sections[I].OriginalIndex then
          begin
            N := Length(RelocationOrder);
            SetLength(RelocationOrder, N + 1);
            RelocationOrder[N] := J;
          end;
        for J := 0 to High(RelocationOrder) do
        begin
          Selected := J;
          for N := J + 1 to High(RelocationOrder) do
            if AObject.Relocations[RelocationOrder[N]].Offset >
               AObject.Relocations[RelocationOrder[Selected]].Offset then
              Selected := N;
          if Selected <> J then
          begin
            Mapped := RelocationOrder[J];
            RelocationOrder[J] := RelocationOrder[Selected];
            RelocationOrder[Selected] := Mapped;
          end;
        end;
        while QWord(FileBuffer.Size) < Sections[I].RelocationOffset do
          FileBuffer.Add8(0);
        for J := 0 to High(RelocationOrder) do
        begin
          Relocation := AObject.Relocations[RelocationOrder[J]];
          RelocationEncoding(AObject.Target, Relocation, RelocType,
            RelocLength, PCRelative, ImplicitAddend);
          Symbol := AObject.Symbols[Relocation.SymbolIndex];
          ExternalRelocation := not ((Symbol.SymbolType = ostSection) and
            Symbol.IsDefined and (Symbol.Name = ''));
          if ExternalRelocation then
            SymbolNumber := LongWord(SymbolRemap[Relocation.SymbolIndex])
          else
          begin
            TargetSection := FindMappedSection(Sections, Symbol.SectionIndex);
            if TargetSection < 0 then
              raise ERCCError.Create('error: Mach-O relocation target section was skipped');
            SymbolNumber := LongWord(TargetSection + 1);
          end;
          RelocWord := SymbolNumber and $00FFFFFF;
          if PCRelative then RelocWord := RelocWord or (LongWord(1) shl 24);
          RelocWord := RelocWord or ((RelocLength and 3) shl 25);
          if ExternalRelocation then
            RelocWord := RelocWord or (LongWord(1) shl 27);
          RelocWord := RelocWord or ((RelocType and $F) shl 28);
          FileBuffer.Add32(LongWord(Relocation.Offset));
          FileBuffer.Add32(RelocWord);
        end;
      end;

    while QWord(FileBuffer.Size) < SymbolOffset do FileBuffer.Add8(0);
    FileBuffer.Append(SymbolTable);
    while QWord(FileBuffer.Size) < StringOffset do FileBuffer.Add8(0);
    FileBuffer.Append(StringTable);
    FileBuffer.SaveToFile(AFileName);
  finally
    for I := 0 to High(Sections) do Sections[I].Data.Free;
    SymbolTable.Free;
    StringTable.Free;
    FileBuffer.Free;
  end;
end;

end.
