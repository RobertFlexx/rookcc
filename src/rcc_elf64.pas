unit rcc_elf64;

{$mode objfpc}{$H+}

interface

uses
  rcc_buffer;

const
  RCCELFBaseVA = QWord($400000);
  RCCELFPageSize = QWord($1000);
  RCCELFTextOffset = QWord($1000);

type
  TELFExecutableLayout = record
    TextOffset: QWord;
    DataOffset: QWord;
    TextVA: QWord;
    DataVA: QWord;
    EntryVA: QWord;
    HasData: Boolean;
    ProgramHeaderCount: LongInt;
  end;

  TDynamicImportKind = (dikFunction, dikObject);

  TDynamicImport = record
    Name: string;
    GOTOffset: QWord;
    GOTLabel: LongInt;
    Kind: TDynamicImportKind;
  end;

  TDynamicImportArray = array of TDynamicImport;

const
  RCCELFBssAlignment = QWord(16);

function AlignELFValue(AValue, AAlignment: QWord): QWord;
function ComputeELFExecutableLayout(ATextSize, ADataSize: QWord;
  AEntryTextOffset: QWord): TELFExecutableLayout;
{ Size of the loaded data image before any .bss region. The backend needs this
  to resolve addresses of zero-initialized objects, which live past the dynamic
  linking metadata that this unit appends after the caller's data buffer. }
function ELF64DataPayloadSize(AText, AData: TByteBuffer;
  const AImports: TDynamicImportArray;
  const ALibraries, ARunPaths: array of string; ABindNow: Boolean): QWord;
procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; ABssSize: QWord = 0); overload;
procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; const AImports: TDynamicImportArray;
  ABssSize: QWord = 0); overload;
procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; const AImports: TDynamicImportArray;
  const ALibraries, ARunPaths: array of string; ABindNow: Boolean;
  const AInterpreter: string; ABssSize: QWord = 0); overload;

implementation

uses
  SysUtils, BaseUnix, rcc_types;

const
  PT_LOAD = LongWord(1);
  PT_DYNAMIC = LongWord(2);
  PT_INTERP = LongWord(3);
  PT_GNU_STACK = LongWord($6474E551);
  PF_X = LongWord(1);
  PF_W = LongWord(2);
  PF_R = LongWord(4);
  ET_EXEC = Word(2);
  EM_X86_64 = Word(62);

  DT_NULL = QWord(0);
  DT_NEEDED = QWord(1);
  DT_HASH = QWord(4);
  DT_STRTAB = QWord(5);
  DT_SYMTAB = QWord(6);
  DT_RELA = QWord(7);
  DT_RELASZ = QWord(8);
  DT_RELAENT = QWord(9);
  DT_STRSZ = QWord(10);
  DT_SYMENT = QWord(11);
  DT_BIND_NOW = QWord(24);
  DT_RUNPATH = QWord(29);

  R_X86_64_GLOB_DAT = QWord(6);
  STB_GLOBAL = Byte(1);
  STT_OBJECT = Byte(1);
  STT_FUNC = Byte(2);

  SHT_NULL = LongWord(0);
  SHT_PROGBITS = LongWord(1);
  SHT_STRTAB = LongWord(3);
  SHT_DYNAMIC = LongWord(6);
  SHT_NOBITS = LongWord(8);
  SHF_WRITE = QWord(1);
  SHF_ALLOC = QWord(2);
  SHF_EXECINSTR = QWord(4);

  LinuxInterpreter = '/lib64/ld-linux-x86-64.so.2';
  DefaultHostedLibrary = 'libc.so.6';

function AlignELFValue(AValue, AAlignment: QWord): QWord;
begin
  if (AAlignment = 0) or ((AAlignment and (AAlignment - 1)) <> 0) then
    raise ERCCError.Create('internal error: ELF alignment must be a power of two');
  Result := (AValue + AAlignment - 1) and not (AAlignment - 1);
end;

function ComputeELFExecutableLayout(ATextSize, ADataSize: QWord;
  AEntryTextOffset: QWord): TELFExecutableLayout;
begin
  Result.TextOffset := RCCELFTextOffset;
  Result.DataOffset := AlignELFValue(Result.TextOffset + ATextSize,
    RCCELFPageSize);
  Result.TextVA := RCCELFBaseVA + Result.TextOffset;
  Result.DataVA := RCCELFBaseVA + Result.DataOffset;
  Result.EntryVA := Result.TextVA + AEntryTextOffset;
  Result.HasData := ADataSize <> 0;
  Result.ProgramHeaderCount := 2;
  if Result.HasData then Inc(Result.ProgramHeaderCount);
end;

procedure AddProgramHeader(ABuffer: TByteBuffer; AType, AFlags: LongWord;
  AOffset, AVirtualAddress, AFileSize, AMemorySize, AAlignment: QWord);
begin
  ABuffer.Add32(AType);
  ABuffer.Add32(AFlags);
  ABuffer.Add64(AOffset);
  ABuffer.Add64(AVirtualAddress);
  ABuffer.Add64(AVirtualAddress);
  ABuffer.Add64(AFileSize);
  ABuffer.Add64(AMemorySize);
  ABuffer.Add64(AAlignment);
end;

procedure AddDynamicEntry(ABuffer: TByteBuffer; ATag, AValue: QWord);
begin
  ABuffer.Add64(ATag);
  ABuffer.Add64(AValue);
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

function ELFOutputIsHosted(const AImports: TDynamicImportArray;
  const ALibraries: array of string): Boolean;
begin
  Result := (Length(AImports) <> 0) or (Length(ALibraries) <> 0);
end;

{ Appends the dynamic linking metadata that follows the caller's data buffer.
  Shared by the writer and by ELF64DataPayloadSize so the two can never
  disagree about where the loaded data image ends. }
procedure BuildELF64DataPayload(ADataPayload, ADynamicBuffer: TByteBuffer;
  AText, AData: TByteBuffer; AEntryTextOffset: QWord;
  const AImports: TDynamicImportArray;
  const ALibraries, ARunPaths: array of string; ABindNow: Boolean;
  out ADynamicOffset: QWord);
var
  Layout: TELFExecutableLayout;
  I, ImportCount: LongInt;
  DynStrOffset, DynStrSize, DynSymOffset, HashOffset, RelaOffset,
    RunPathOffset: QWord;
  LibraryNameOffsets, SymbolNameOffsets: array of QWord;
  SymbolType: Byte;
  ChainValue: LongWord;
  RunPath: string;

  procedure PadDataTo(AAlignment: LongInt);
  begin
    ADataPayload.PadTo(AAlignment);
  end;

  function JoinRunPaths: string;
  var
    PathIndex: LongInt;
  begin
    Result := '';
    for PathIndex := 0 to High(ARunPaths) do
      if ARunPaths[PathIndex] <> '' then
      begin
        if Result <> '' then Result := Result + ':';
        Result := Result + ARunPaths[PathIndex];
      end;
  end;

begin
  ADynamicOffset := 0;
  ImportCount := Length(AImports);
  ADataPayload.Append(AData);
  if not ELFOutputIsHosted(AImports, ALibraries) then Exit;

  PadDataTo(8);
  DynStrOffset := QWord(ADataPayload.Size);
  ADataPayload.Add8(0);
  SetLength(LibraryNameOffsets, Length(ALibraries));
  for I := 0 to High(ALibraries) do
  begin
    LibraryNameOffsets[I] := QWord(ADataPayload.Size) - DynStrOffset;
    ADataPayload.AddStringZ(ALibraries[I]);
  end;
  SetLength(SymbolNameOffsets, ImportCount);
  for I := 0 to ImportCount - 1 do
  begin
    SymbolNameOffsets[I] := QWord(ADataPayload.Size) - DynStrOffset;
    ADataPayload.AddStringZ(AImports[I].Name);
  end;
  RunPath := JoinRunPaths;
  RunPathOffset := 0;
  if RunPath <> '' then
  begin
    RunPathOffset := QWord(ADataPayload.Size) - DynStrOffset;
    ADataPayload.AddStringZ(RunPath);
  end;
  DynStrSize := QWord(ADataPayload.Size) - DynStrOffset;

  PadDataTo(8);
  DynSymOffset := QWord(ADataPayload.Size);
  for I := 1 to 24 do ADataPayload.Add8(0);
  for I := 0 to ImportCount - 1 do
  begin
    ADataPayload.Add32(LongWord(SymbolNameOffsets[I]));
    if AImports[I].Kind = dikObject then SymbolType := STT_OBJECT
    else SymbolType := STT_FUNC;
    ADataPayload.Add8(Byte((STB_GLOBAL shl 4) or SymbolType));
    ADataPayload.Add8(0);
    ADataPayload.Add16(0);
    ADataPayload.Add64(0);
    ADataPayload.Add64(0);
  end;

  PadDataTo(8);
  HashOffset := QWord(ADataPayload.Size);
  ADataPayload.Add32(1);
  ADataPayload.Add32(LongWord(ImportCount + 1));
  if ImportCount > 0 then ADataPayload.Add32(1)
  else ADataPayload.Add32(0);
  ADataPayload.Add32(0);
  for I := 1 to ImportCount do
  begin
    if I < ImportCount then ChainValue := LongWord(I + 1)
    else ChainValue := 0;
    ADataPayload.Add32(ChainValue);
  end;

  PadDataTo(8);
  RelaOffset := QWord(ADataPayload.Size);
  Layout := ComputeELFExecutableLayout(QWord(AText.Size),
    QWord(ADataPayload.Size), AEntryTextOffset);
  for I := 0 to ImportCount - 1 do
  begin
    ADataPayload.Add64(Layout.DataVA + AImports[I].GOTOffset);
    ADataPayload.Add64((QWord(I + 1) shl 32) or R_X86_64_GLOB_DAT);
    ADataPayload.Add64(0);
  end;

  PadDataTo(8);
  ADynamicOffset := QWord(ADataPayload.Size);
  Layout := ComputeELFExecutableLayout(QWord(AText.Size),
    QWord(ADataPayload.Size), AEntryTextOffset);
  for I := 0 to High(ALibraries) do
    AddDynamicEntry(ADynamicBuffer, DT_NEEDED, LibraryNameOffsets[I]);
  AddDynamicEntry(ADynamicBuffer, DT_HASH, Layout.DataVA + HashOffset);
  AddDynamicEntry(ADynamicBuffer, DT_STRTAB, Layout.DataVA + DynStrOffset);
  AddDynamicEntry(ADynamicBuffer, DT_SYMTAB, Layout.DataVA + DynSymOffset);
  AddDynamicEntry(ADynamicBuffer, DT_STRSZ, DynStrSize);
  AddDynamicEntry(ADynamicBuffer, DT_SYMENT, 24);
  AddDynamicEntry(ADynamicBuffer, DT_RELA, Layout.DataVA + RelaOffset);
  AddDynamicEntry(ADynamicBuffer, DT_RELASZ, QWord(ImportCount) * 24);
  AddDynamicEntry(ADynamicBuffer, DT_RELAENT, 24);
  if RunPath <> '' then
    AddDynamicEntry(ADynamicBuffer, DT_RUNPATH, RunPathOffset);
  if ABindNow then AddDynamicEntry(ADynamicBuffer, DT_BIND_NOW, 0);
  AddDynamicEntry(ADynamicBuffer, DT_NULL, 0);
  ADataPayload.Append(ADynamicBuffer);
end;

function ELF64DataPayloadSize(AText, AData: TByteBuffer;
  const AImports: TDynamicImportArray;
  const ALibraries, ARunPaths: array of string; ABindNow: Boolean): QWord;
var
  Payload, Dynamic: TByteBuffer;
  DynamicOffset: QWord;
begin
  Payload := TByteBuffer.Create;
  Dynamic := TByteBuffer.Create;
  try
    BuildELF64DataPayload(Payload, Dynamic, AText, AData, 0, AImports,
      ALibraries, ARunPaths, ABindNow, DynamicOffset);
    Result := QWord(Payload.Size);
  finally
    Payload.Free;
    Dynamic.Free;
  end;
end;

procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; ABssSize: QWord);
var
  EmptyImports: TDynamicImportArray;
begin
  SetLength(EmptyImports, 0);
  WriteELF64Executable(AFileName, AText, AData, AEntryTextOffset, EmptyImports,
    ABssSize);
end;

procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; const AImports: TDynamicImportArray;
  ABssSize: QWord);
var
  DefaultLibraries, EmptyPaths: array of string;
begin
  SetLength(EmptyPaths, 0);
  if Length(AImports) <> 0 then
  begin
    SetLength(DefaultLibraries, 1);
    DefaultLibraries[0] := DefaultHostedLibrary;
  end
  else
    SetLength(DefaultLibraries, 0);
  WriteELF64Executable(AFileName, AText, AData, AEntryTextOffset, AImports,
    DefaultLibraries, EmptyPaths, False, LinuxInterpreter, ABssSize);
end;

procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; const AImports: TDynamicImportArray;
  const ALibraries, ARunPaths: array of string; ABindNow: Boolean;
  const AInterpreter: string; ABssSize: QWord);
var
  Layout: TELFExecutableLayout;
  FileBuffer, DataPayload, DynamicBuffer, ShStr: TByteBuffer;
  I, ProgramHeaderCount, SectionCount, ShStrIndex: LongInt;
  Hosted: Boolean;
  InterpOffset, InterpVA, InterpSize: QWord;
  DynamicOffset, DataMemorySize, ShStrOffset, SectionHeaderOffset,
    BssOffset, BssVA: QWord;
  InterpName, TextName, DataName, BssName, ShStrName: LongWord;
  Interpreter: string;

begin
  if (AText = nil) or (AData = nil) then
    raise ERCCError.Create('internal error: nil buffer passed to ELF writer');

  Hosted := ELFOutputIsHosted(AImports, ALibraries);
  Interpreter := AInterpreter;
  if Hosted and (Interpreter = '') then
    raise ERCCError.Create('error: hosted ELF output requires a dynamic linker');
  DataPayload := TByteBuffer.Create;
  DynamicBuffer := TByteBuffer.Create;
  FileBuffer := TByteBuffer.Create;
  ShStr := TByteBuffer.Create;
  try
    BuildELF64DataPayload(DataPayload, DynamicBuffer, AText, AData,
      AEntryTextOffset, AImports, ALibraries, ARunPaths, ABindNow,
      DynamicOffset);

    if ABssSize <> 0 then
      DataMemorySize := AlignELFValue(QWord(DataPayload.Size),
        RCCELFBssAlignment) + ABssSize
    else
      DataMemorySize := QWord(DataPayload.Size);


    Layout := ComputeELFExecutableLayout(QWord(AText.Size),
      QWord(DataPayload.Size), AEntryTextOffset);
    if DataMemorySize <> 0 then Layout.HasData := True;

    if Hosted then ProgramHeaderCount := 5
    else
    begin
      ProgramHeaderCount := 2;
      if Layout.HasData then Inc(ProgramHeaderCount);
    end;

    InterpOffset := 64 + QWord(ProgramHeaderCount) * 56;
    InterpVA := RCCELFBaseVA + InterpOffset;
    InterpSize := QWord(Length(Interpreter) + 1);
    if Hosted and (InterpOffset + InterpSize >= Layout.TextOffset) then
      raise ERCCError.Create('internal error: ELF interpreter exceeds header page');

    FileBuffer.AddBytes([$7F, Ord('E'), Ord('L'), Ord('F'), 2, 1, 1, 0]);
    for I := 1 to 8 do FileBuffer.Add8(0);
    FileBuffer.Add16(ET_EXEC);
    FileBuffer.Add16(EM_X86_64);
    FileBuffer.Add32(1);
    FileBuffer.Add64(Layout.EntryVA);
    FileBuffer.Add64(64);
    FileBuffer.Add64(0);
    FileBuffer.Add32(0);
    FileBuffer.Add16(64);
    FileBuffer.Add16(56);
    FileBuffer.Add16(ProgramHeaderCount);
    FileBuffer.Add16(64);
    FileBuffer.Add16(0);
    FileBuffer.Add16(0);

    if Hosted then
    begin
      AddProgramHeader(FileBuffer, PT_INTERP, PF_R, InterpOffset, InterpVA,
        InterpSize, InterpSize, 1);
      AddProgramHeader(FileBuffer, PT_LOAD, PF_R or PF_X, 0, RCCELFBaseVA,
        Layout.TextOffset + QWord(AText.Size),
        Layout.TextOffset + QWord(AText.Size), RCCELFPageSize);
      AddProgramHeader(FileBuffer, PT_LOAD, PF_R or PF_W, Layout.DataOffset,
        Layout.DataVA, QWord(DataPayload.Size), DataMemorySize,
        RCCELFPageSize);
      AddProgramHeader(FileBuffer, PT_DYNAMIC, PF_R or PF_W,
        Layout.DataOffset + DynamicOffset, Layout.DataVA + DynamicOffset,
        QWord(DynamicBuffer.Size), QWord(DynamicBuffer.Size), 8);
      AddProgramHeader(FileBuffer, PT_GNU_STACK, PF_R or PF_W, 0, 0, 0, 0, 16);
    end
    else
    begin
      AddProgramHeader(FileBuffer, PT_LOAD, PF_R or PF_X, 0, RCCELFBaseVA,
        Layout.TextOffset + QWord(AText.Size),
        Layout.TextOffset + QWord(AText.Size), RCCELFPageSize);
      if Layout.HasData then
        AddProgramHeader(FileBuffer, PT_LOAD, PF_R or PF_W, Layout.DataOffset,
          Layout.DataVA, QWord(DataPayload.Size), DataMemorySize,
          RCCELFPageSize);
      AddProgramHeader(FileBuffer, PT_GNU_STACK, PF_R or PF_W, 0, 0, 0, 0, 16);
    end;

    if Hosted then
    begin
      while QWord(FileBuffer.Size) < InterpOffset do FileBuffer.Add8(0);
      FileBuffer.AddStringZ(Interpreter);
    end;
    while QWord(FileBuffer.Size) < Layout.TextOffset do FileBuffer.Add8(0);
    FileBuffer.Append(AText);
    if Layout.HasData then
    begin
      while QWord(FileBuffer.Size) < Layout.DataOffset do FileBuffer.Add8(0);
      FileBuffer.Append(DataPayload);
    end;

    { Section headers are not needed by the loader, but standard tooling uses
      them for size accounting, inspection, and stripping.  Keep the loaded
      image unchanged and append a compact non-loaded table. }
    ShStr.Add8(0);
    InterpName := 0;
    if Hosted then
    begin
      InterpName := LongWord(ShStr.Size);
      ShStr.AddStringZ('.interp');
    end;
    TextName := LongWord(ShStr.Size);
    ShStr.AddStringZ('.text');
    DataName := 0;
    if QWord(DataPayload.Size) <> 0 then
    begin
      DataName := LongWord(ShStr.Size);
      ShStr.AddStringZ('.data');
    end;
    BssName := 0;
    if ABssSize <> 0 then
    begin
      BssName := LongWord(ShStr.Size);
      ShStr.AddStringZ('.bss');
    end;
    ShStrName := LongWord(ShStr.Size);
    ShStr.AddStringZ('.shstrtab');

    ShStrOffset := QWord(FileBuffer.Size);
    FileBuffer.Append(ShStr);
    SectionHeaderOffset := AlignELFValue(QWord(FileBuffer.Size), 8);
    while QWord(FileBuffer.Size) < SectionHeaderOffset do FileBuffer.Add8(0);

    SectionCount := 2; { NULL + .text }
    if Hosted then Inc(SectionCount); { .interp }
    if QWord(DataPayload.Size) <> 0 then Inc(SectionCount);
    if ABssSize <> 0 then Inc(SectionCount);
    Inc(SectionCount); { .shstrtab }
    ShStrIndex := SectionCount - 1;

    AddSectionHeader(FileBuffer, 0, SHT_NULL, 0, 0, 0, 0,
      0, 0, 0, 0);
    if Hosted then
      AddSectionHeader(FileBuffer, InterpName, SHT_PROGBITS, SHF_ALLOC,
        InterpVA, InterpOffset, InterpSize, 0, 0, 1, 0);
    AddSectionHeader(FileBuffer, TextName, SHT_PROGBITS,
      SHF_ALLOC or SHF_EXECINSTR, Layout.TextVA, Layout.TextOffset,
      QWord(AText.Size), 0, 0, 16, 0);
    if QWord(DataPayload.Size) <> 0 then
      AddSectionHeader(FileBuffer, DataName, SHT_PROGBITS,
        SHF_ALLOC or SHF_WRITE, Layout.DataVA, Layout.DataOffset,
        QWord(DataPayload.Size), 0, 0, 16, 0);
    if ABssSize <> 0 then
    begin
      BssOffset := Layout.DataOffset + AlignELFValue(
        QWord(DataPayload.Size), RCCELFBssAlignment);
      BssVA := Layout.DataVA + AlignELFValue(
        QWord(DataPayload.Size), RCCELFBssAlignment);
      AddSectionHeader(FileBuffer, BssName, SHT_NOBITS,
        SHF_ALLOC or SHF_WRITE, BssVA, BssOffset, ABssSize,
        0, 0, RCCELFBssAlignment, 0);
    end;
    AddSectionHeader(FileBuffer, ShStrName, SHT_STRTAB, 0, 0,
      ShStrOffset, QWord(ShStr.Size), 0, 0, 1, 0);

    FileBuffer.Patch64(40, SectionHeaderOffset);
    FileBuffer.Patch16(60, Word(SectionCount));
    FileBuffer.Patch16(62, Word(ShStrIndex));
    FileBuffer.SaveToFile(AFileName);
    if fpChmod(PChar(AFileName), &755) <> 0 then
      raise ERCCError.Create('error: cannot mark output executable: ' + AFileName);
  finally
    ShStr.Free;
    FileBuffer.Free;
    DynamicBuffer.Free;
    DataPayload.Free;
  end;
end;

end.
