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

function AlignELFValue(AValue, AAlignment: QWord): QWord;
function ComputeELFExecutableLayout(ATextSize, ADataSize: QWord;
  AEntryTextOffset: QWord): TELFExecutableLayout;
procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord); overload;
procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; const AImports: TDynamicImportArray); overload;
procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; const AImports: TDynamicImportArray;
  const ALibraries, ARunPaths: array of string; ABindNow: Boolean;
  const AInterpreter: string); overload;

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

procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord);
var
  EmptyImports: TDynamicImportArray;
begin
  SetLength(EmptyImports, 0);
  WriteELF64Executable(AFileName, AText, AData, AEntryTextOffset, EmptyImports);
end;

procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; const AImports: TDynamicImportArray);
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
    DefaultLibraries, EmptyPaths, False, LinuxInterpreter);
end;

procedure WriteELF64Executable(const AFileName: string; AText, AData: TByteBuffer;
  AEntryTextOffset: QWord; const AImports: TDynamicImportArray;
  const ALibraries, ARunPaths: array of string; ABindNow: Boolean;
  const AInterpreter: string);
var
  Layout: TELFExecutableLayout;
  FileBuffer, DataPayload, DynamicBuffer: TByteBuffer;
  I, ImportCount, ProgramHeaderCount: LongInt;
  Hosted: Boolean;
  InterpOffset, InterpVA, InterpSize: QWord;
  DynStrOffset, DynStrSize, DynSymOffset, HashOffset, RelaOffset,
    DynamicOffset, RunPathOffset: QWord;
  LibraryNameOffsets, SymbolNameOffsets: array of QWord;
  SymbolType: Byte;
  ChainValue: LongWord;
  RunPath, Interpreter: string;

  procedure PadDataTo(AAlignment: LongInt);
  begin
    DataPayload.PadTo(AAlignment);
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
  if (AText = nil) or (AData = nil) then
    raise ERCCError.Create('internal error: nil buffer passed to ELF writer');

  Hosted := (Length(AImports) <> 0) or (Length(ALibraries) <> 0);
  Interpreter := AInterpreter;
  if Hosted and (Interpreter = '') then
    raise ERCCError.Create('error: hosted ELF output requires a dynamic linker');
  ImportCount := Length(AImports);
  DataPayload := TByteBuffer.Create;
  DynamicBuffer := TByteBuffer.Create;
  FileBuffer := TByteBuffer.Create;
  try
    DataPayload.Append(AData);





    if Hosted then
    begin
      PadDataTo(8);
      DynStrOffset := QWord(DataPayload.Size);
      DataPayload.Add8(0);
      SetLength(LibraryNameOffsets, Length(ALibraries));
      for I := 0 to High(ALibraries) do
      begin
        LibraryNameOffsets[I] := QWord(DataPayload.Size) - DynStrOffset;
        DataPayload.AddStringZ(ALibraries[I]);
      end;
      SetLength(SymbolNameOffsets, ImportCount);
      for I := 0 to ImportCount - 1 do
      begin
        SymbolNameOffsets[I] := QWord(DataPayload.Size) - DynStrOffset;
        DataPayload.AddStringZ(AImports[I].Name);
      end;
      RunPath := JoinRunPaths;
      RunPathOffset := 0;
      if RunPath <> '' then
      begin
        RunPathOffset := QWord(DataPayload.Size) - DynStrOffset;
        DataPayload.AddStringZ(RunPath);
      end;
      DynStrSize := QWord(DataPayload.Size) - DynStrOffset;

      PadDataTo(8);
      DynSymOffset := QWord(DataPayload.Size);
      for I := 1 to 24 do DataPayload.Add8(0);
      for I := 0 to ImportCount - 1 do
      begin
        DataPayload.Add32(LongWord(SymbolNameOffsets[I]));
        if AImports[I].Kind = dikObject then SymbolType := STT_OBJECT
        else SymbolType := STT_FUNC;
        DataPayload.Add8(Byte((STB_GLOBAL shl 4) or SymbolType));
        DataPayload.Add8(0);
        DataPayload.Add16(0);
        DataPayload.Add64(0);
        DataPayload.Add64(0);
      end;

      PadDataTo(8);
      HashOffset := QWord(DataPayload.Size);
      DataPayload.Add32(1);
      DataPayload.Add32(LongWord(ImportCount + 1));
      if ImportCount > 0 then DataPayload.Add32(1)
      else DataPayload.Add32(0);
      DataPayload.Add32(0);
      for I := 1 to ImportCount do
      begin
        if I < ImportCount then ChainValue := LongWord(I + 1)
        else ChainValue := 0;
        DataPayload.Add32(ChainValue);
      end;

      PadDataTo(8);
      RelaOffset := QWord(DataPayload.Size);
      Layout := ComputeELFExecutableLayout(QWord(AText.Size),
        QWord(DataPayload.Size), AEntryTextOffset);
      for I := 0 to ImportCount - 1 do
      begin
        DataPayload.Add64(Layout.DataVA + AImports[I].GOTOffset);
        DataPayload.Add64((QWord(I + 1) shl 32) or R_X86_64_GLOB_DAT);
        DataPayload.Add64(0);
      end;

      PadDataTo(8);
      DynamicOffset := QWord(DataPayload.Size);
      Layout := ComputeELFExecutableLayout(QWord(AText.Size),
        QWord(DataPayload.Size), AEntryTextOffset);
      for I := 0 to High(ALibraries) do
        AddDynamicEntry(DynamicBuffer, DT_NEEDED, LibraryNameOffsets[I]);
      AddDynamicEntry(DynamicBuffer, DT_HASH, Layout.DataVA + HashOffset);
      AddDynamicEntry(DynamicBuffer, DT_STRTAB, Layout.DataVA + DynStrOffset);
      AddDynamicEntry(DynamicBuffer, DT_SYMTAB, Layout.DataVA + DynSymOffset);
      AddDynamicEntry(DynamicBuffer, DT_STRSZ, DynStrSize);
      AddDynamicEntry(DynamicBuffer, DT_SYMENT, 24);
      AddDynamicEntry(DynamicBuffer, DT_RELA, Layout.DataVA + RelaOffset);
      AddDynamicEntry(DynamicBuffer, DT_RELASZ, QWord(ImportCount) * 24);
      AddDynamicEntry(DynamicBuffer, DT_RELAENT, 24);
      if RunPath <> '' then
        AddDynamicEntry(DynamicBuffer, DT_RUNPATH, RunPathOffset);
      if ABindNow then AddDynamicEntry(DynamicBuffer, DT_BIND_NOW, 0);
      AddDynamicEntry(DynamicBuffer, DT_NULL, 0);
      DataPayload.Append(DynamicBuffer);
    end;

    Layout := ComputeELFExecutableLayout(QWord(AText.Size),
      QWord(DataPayload.Size), AEntryTextOffset);

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
    FileBuffer.Add16(0);
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
        Layout.DataVA, QWord(DataPayload.Size), QWord(DataPayload.Size),
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
          Layout.DataVA, QWord(DataPayload.Size), QWord(DataPayload.Size),
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
    FileBuffer.SaveToFile(AFileName);
    if fpChmod(PChar(AFileName), &755) <> 0 then
      raise ERCCError.Create('error: cannot mark output executable: ' + AFileName);
  finally
    FileBuffer.Free;
    DynamicBuffer.Free;
    DataPayload.Free;
  end;
end;

end.
