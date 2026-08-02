unit rcc_library_resolver;

{$mode objfpc}{$H+}

interface

type
  TResolvedLibrary = record
    Request: string;
    FileName: string;
    NeededName: string;
    EmitNeeded: Boolean;
  end;
  TResolvedLibraryArray = array of TResolvedLibrary;
  TLibraryStringArray = array of string;

procedure BuildLibrarySearchDirectories(const AUserPaths: array of string;
  const ASysroot, AMultiArch: string; ANativeTarget: Boolean;
  out ADirectories: TLibraryStringArray);
function FindLibraryFile(const ADirectories: TLibraryStringArray;
  const ARequest: string; out AFileName: string): Boolean;
function FindStaticLibraryFile(const ADirectories: TLibraryStringArray;
  const ARequest: string; out AFileName: string): Boolean;
procedure ResolveDefaultLibC(const ADirectories: TLibraryStringArray;
  const ASysroot, ADefaultLibC, AArchitectureName: string;
  AELFMachine: Word; out AFileName: string);

procedure ResolveDynamicLibraries(const AUserPaths, ARequests: array of string;
  const ASysroot, AMultiArch, ADefaultLibC, AArchitectureName: string;
  AELFMachine: Word; ANativeTarget, ARequireDefaultLibC,
  ANoDefaultLibraries, AFreestanding: Boolean;
  out ALibraries: TResolvedLibraryArray);
function ResolvedNeededNames(const ALibraries: TResolvedLibraryArray):
  TLibraryStringArray;
procedure ValidateDynamicSymbolProviders(const ASymbolNames: array of string;
  const ALibraries: TResolvedLibraryArray; AELFMachine: Word);

implementation

uses
  Classes, SysUtils, rcc_types;

const
  ELFMagic0 = Byte($7F);
  ELFClass64 = Byte(2);
  ELFDataLSB = Byte(1);
  ETDyn = Word(3);
  PTLoad = LongWord(1);
  PTDynamic = LongWord(2);
  DTNull = QWord(0);
  DTNeeded = QWord(1);
  DTHash = QWord(4);
  DTStrTab = QWord(5);
  DTSymTab = QWord(6);
  DTSymEnt = QWord(11);
  DTSoname = QWord(14);
  DTGNUHash = QWord($6FFFFEF5);
  SHNUndefined = Word(0);
  STBGlobal = Byte(1);
  STBWeak = Byte(2);
  STBGNUUnique = Byte(10);
  STVDefault = Byte(0);
  STVProtected = Byte(3);

procedure AppendUnique(var AValues: TLibraryStringArray;
  const AValue: string);
var
  I, N: LongInt;
  Value: string;
begin
  Value := Trim(AValue);
  if Value = '' then Exit;
  Value := ExcludeTrailingPathDelimiter(ExpandFileName(Value));
  for I := 0 to High(AValues) do
    if AValues[I] = Value then Exit;
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := Value;
end;

procedure AppendResolved(var AValues: TResolvedLibraryArray;
  const ARequest, AFileName, ANeededName: string; AEmitNeeded: Boolean);
var
  I, N: LongInt;
begin
  if ANeededName = '' then Exit;
  for I := 0 to High(AValues) do
    if AValues[I].NeededName = ANeededName then
    begin
      if AEmitNeeded then AValues[I].EmitNeeded := True;
      Exit;
    end;
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N].Request := ARequest;
  AValues[N].FileName := AFileName;
  AValues[N].NeededName := ANeededName;
  AValues[N].EmitNeeded := AEmitNeeded;
end;

procedure AddRootDirectories(var ADirectories: TLibraryStringArray;
  const ARoot, AMultiArch: string);
var
  Root: string;
begin
  Root := ExcludeTrailingPathDelimiter(ARoot);
  if AMultiArch <> '' then
  begin
    AppendUnique(ADirectories, Root + '/usr/local/lib/' + AMultiArch);
    AppendUnique(ADirectories, Root + '/usr/lib/' + AMultiArch);
    AppendUnique(ADirectories, Root + '/lib/' + AMultiArch);
    AppendUnique(ADirectories, Root + '/usr/' + AMultiArch + '/lib64');
    AppendUnique(ADirectories, Root + '/usr/' + AMultiArch + '/lib');
    AppendUnique(ADirectories, Root + '/' + AMultiArch + '/lib64');
    AppendUnique(ADirectories, Root + '/' + AMultiArch + '/lib');
  end;
  AppendUnique(ADirectories, Root + '/usr/local/lib64');
  AppendUnique(ADirectories, Root + '/usr/lib64');
  AppendUnique(ADirectories, Root + '/lib64');
  AppendUnique(ADirectories, Root + '/usr/local/lib');
  AppendUnique(ADirectories, Root + '/usr/lib');
  AppendUnique(ADirectories, Root + '/lib');
end;

procedure AppendPathList(var ADirectories: TLibraryStringArray;
  const AValue: string);
var
  I, StartPos: LongInt;
  Item: string;
begin
  StartPos := 1;
  for I := 1 to Length(AValue) + 1 do
    if (I > Length(AValue)) or (AValue[I] = ':') then
    begin
      Item := Copy(AValue, StartPos, I - StartPos);
      if Item <> '' then AppendUnique(ADirectories, Item);
      StartPos := I + 1;
    end;
end;

procedure BuildLibrarySearchDirectories(const AUserPaths: array of string;
  const ASysroot, AMultiArch: string; ANativeTarget: Boolean;
  out ADirectories: TLibraryStringArray);
var
  I: LongInt;
  EnvironmentPaths, Root: string;
begin
  SetLength(ADirectories, 0);
  for I := 0 to High(AUserPaths) do
    AppendUnique(ADirectories, AUserPaths[I]);
  EnvironmentPaths := GetEnvironmentVariable('LIBRARY_PATH');
  if EnvironmentPaths <> '' then
    AppendPathList(ADirectories, EnvironmentPaths);
  EnvironmentPaths := GetEnvironmentVariable('ROOKCC_LIBRARY_PATH');
  if EnvironmentPaths <> '' then
    AppendPathList(ADirectories, EnvironmentPaths);

  if ASysroot <> '' then
  begin
    Root := ExpandFileName(ASysroot);
    AddRootDirectories(ADirectories, Root, AMultiArch);
  end
  else if ANativeTarget then
    AddRootDirectories(ADirectories, '', AMultiArch);
end;

function ReadByte(const AData: TBytes; AOffset: QWord;
  out AValue: Byte): Boolean;
begin
  Result := AOffset < QWord(Length(AData));
  if Result then AValue := AData[LongInt(AOffset)] else AValue := 0;
end;

function ReadLE16(const AData: TBytes; AOffset: QWord;
  out AValue: Word): Boolean;
var
  B0, B1: Byte;
begin
  Result := ReadByte(AData, AOffset, B0) and
    ReadByte(AData, AOffset + 1, B1);
  if Result then AValue := Word(B0) or (Word(B1) shl 8) else AValue := 0;
end;

function ReadLE32(const AData: TBytes; AOffset: QWord;
  out AValue: LongWord): Boolean;
var
  I: LongInt;
  B: Byte;
begin
  AValue := 0;
  for I := 0 to 3 do
  begin
    if not ReadByte(AData, AOffset + QWord(I), B) then Exit(False);
    AValue := AValue or (LongWord(B) shl (I * 8));
  end;
  Result := True;
end;

function ReadLE64(const AData: TBytes; AOffset: QWord;
  out AValue: QWord): Boolean;
var
  I: LongInt;
  B: Byte;
begin
  AValue := 0;
  for I := 0 to 7 do
  begin
    if not ReadByte(AData, AOffset + QWord(I), B) then Exit(False);
    AValue := AValue or (QWord(B) shl (I * 8));
  end;
  Result := True;
end;

function LoadFileBytes(const AFileName: string; out AData: TBytes): Boolean;
var
  Stream: TFileStream;
  Size: Int64;
begin
  SetLength(AData, 0);
  if not FileExists(AFileName) then Exit(False);
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Size := Stream.Size;
    if (Size < 0) or (Size > High(LongInt)) then Exit(False);
    SetLength(AData, LongInt(Size));
    if Size > 0 then Stream.ReadBuffer(AData[0], LongInt(Size));
    Result := True;
  finally
    Stream.Free;
  end;
end;

function IsELF64SharedObject(const AData: TBytes;
  AELFMachine: Word): Boolean;
var
  Machine, FileType: Word;
begin
  Result := (Length(AData) >= 64) and
    (AData[0] = ELFMagic0) and (AData[1] = Ord('E')) and
    (AData[2] = Ord('L')) and (AData[3] = Ord('F')) and
    (AData[4] = ELFClass64) and (AData[5] = ELFDataLSB) and
    ReadLE16(AData, 16, FileType) and ReadLE16(AData, 18, Machine) and
    (FileType = ETDyn) and (Machine = AELFMachine);
end;

function VirtualAddressToOffset(const AData: TBytes;
  AProgramHeaderOffset: QWord; AProgramHeaderSize,
  AProgramHeaderCount: Word; AVirtualAddress: QWord;
  out AFileOffset: QWord): Boolean;
var
  I: LongInt;
  HeaderOffset, SegmentOffset, SegmentVA, SegmentFileSize: QWord;
  SegmentType: LongWord;
begin
  AFileOffset := 0;
  if AProgramHeaderCount = 0 then Exit(False);
  for I := 0 to LongInt(AProgramHeaderCount) - 1 do
  begin
    HeaderOffset := AProgramHeaderOffset + QWord(I) * AProgramHeaderSize;
    if not ReadLE32(AData, HeaderOffset, SegmentType) then Exit(False);
    if SegmentType <> PTLoad then Continue;
    if not ReadLE64(AData, HeaderOffset + 8, SegmentOffset) or
       not ReadLE64(AData, HeaderOffset + 16, SegmentVA) or
       not ReadLE64(AData, HeaderOffset + 32, SegmentFileSize) then
      Exit(False);
    if (AVirtualAddress >= SegmentVA) and
       (AVirtualAddress - SegmentVA < SegmentFileSize) then
    begin
      AFileOffset := SegmentOffset + (AVirtualAddress - SegmentVA);
      Exit(AFileOffset < QWord(Length(AData)));
    end;
  end;
  Result := False;
end;

function ReadCString(const AData: TBytes; AOffset: QWord;
  out AValue: string): Boolean;
var
  I: QWord;
begin
  AValue := '';
  if AOffset >= QWord(Length(AData)) then Exit(False);
  I := AOffset;
  while (I < QWord(Length(AData))) and (AData[LongInt(I)] <> 0) do
  begin
    if Length(AValue) >= 4096 then Exit(False);
    AValue := AValue + Chr(AData[LongInt(I)]);
    Inc(I);
  end;
  Result := I < QWord(Length(AData));
end;

function ELFSharedObjectName(const AFileName: string;
  AELFMachine: Word; out AName: string): Boolean;
var
  Data: TBytes;
  ProgramHeaderOffset, DynamicOffset, DynamicSize, StringTableVA,
    StringTableOffset, SonameOffset, Tag, Value, HeaderOffset: QWord;
  ProgramHeaderSize, ProgramHeaderCount: Word;
  SegmentType: LongWord;
  I: LongInt;
begin
  AName := '';
  if not LoadFileBytes(AFileName, Data) or
     not IsELF64SharedObject(Data, AELFMachine) then Exit(False);
  if not ReadLE64(Data, 32, ProgramHeaderOffset) or
     not ReadLE16(Data, 54, ProgramHeaderSize) or
     not ReadLE16(Data, 56, ProgramHeaderCount) then Exit(False);
  DynamicOffset := 0;
  DynamicSize := 0;
  if ProgramHeaderCount = 0 then Exit(False);
  for I := 0 to LongInt(ProgramHeaderCount) - 1 do
  begin
    HeaderOffset := ProgramHeaderOffset + QWord(I) * ProgramHeaderSize;
    if not ReadLE32(Data, HeaderOffset, SegmentType) then Exit(False);
    if SegmentType = PTDynamic then
    begin
      if not ReadLE64(Data, HeaderOffset + 8, DynamicOffset) or
         not ReadLE64(Data, HeaderOffset + 32, DynamicSize) then Exit(False);
      Break;
    end;
  end;
  if (DynamicOffset = 0) or (DynamicSize < 16) then Exit(False);
  StringTableVA := 0;
  SonameOffset := High(QWord);
  I := 0;
  while QWord(I) * 16 < DynamicSize do
  begin
    HeaderOffset := DynamicOffset + QWord(I) * 16;
    if not ReadLE64(Data, HeaderOffset, Tag) or
       not ReadLE64(Data, HeaderOffset + 8, Value) then Exit(False);
    if Tag = DTNull then Break;
    if Tag = DTStrTab then StringTableVA := Value
    else if Tag = DTSoname then SonameOffset := Value;
    Inc(I);
  end;
  if (StringTableVA = 0) or (SonameOffset = High(QWord)) then
  begin
    AName := ExtractFileName(AFileName);
    Exit(AName <> '');
  end;
  if not VirtualAddressToOffset(Data, ProgramHeaderOffset,
    ProgramHeaderSize, ProgramHeaderCount, StringTableVA,
    StringTableOffset) then Exit(False);
  Result := ReadCString(Data, StringTableOffset + SonameOffset, AName) and
    (AName <> '');
end;

function ELFSharedObjectDependencies(const AFileName: string;
  AELFMachine: Word; out ADependencies: TLibraryStringArray): Boolean;
var
  Data: TBytes;
  NeededOffsets: array of QWord;
  ProgramHeaderOffset, DynamicOffset, DynamicSize, StringTableVA,
    StringTableOffset, Tag, Value, HeaderOffset: QWord;
  ProgramHeaderSize, ProgramHeaderCount: Word;
  SegmentType: LongWord;
  I, N: LongInt;
  Dependency: string;
begin
  SetLength(ADependencies, 0);
  if not LoadFileBytes(AFileName, Data) or
     not IsELF64SharedObject(Data, AELFMachine) then Exit(False);
  if not ReadLE64(Data, 32, ProgramHeaderOffset) or
     not ReadLE16(Data, 54, ProgramHeaderSize) or
     not ReadLE16(Data, 56, ProgramHeaderCount) then Exit(False);
  DynamicOffset := 0;
  DynamicSize := 0;
  if ProgramHeaderCount = 0 then Exit(False);
  for I := 0 to LongInt(ProgramHeaderCount) - 1 do
  begin
    HeaderOffset := ProgramHeaderOffset + QWord(I) * ProgramHeaderSize;
    if not ReadLE32(Data, HeaderOffset, SegmentType) then Exit(False);
    if SegmentType = PTDynamic then
    begin
      if not ReadLE64(Data, HeaderOffset + 8, DynamicOffset) or
         not ReadLE64(Data, HeaderOffset + 32, DynamicSize) then Exit(False);
      Break;
    end;
  end;
  if (DynamicOffset = 0) or (DynamicSize < 16) then Exit(False);
  StringTableVA := 0;
  SetLength(NeededOffsets, 0);
  I := 0;
  while QWord(I) * 16 < DynamicSize do
  begin
    HeaderOffset := DynamicOffset + QWord(I) * 16;
    if not ReadLE64(Data, HeaderOffset, Tag) or
       not ReadLE64(Data, HeaderOffset + 8, Value) then Exit(False);
    if Tag = DTNull then Break;
    if Tag = DTStrTab then StringTableVA := Value
    else if Tag = DTNeeded then
    begin
      N := Length(NeededOffsets);
      SetLength(NeededOffsets, N + 1);
      NeededOffsets[N] := Value;
    end;
    Inc(I);
  end;
  if StringTableVA = 0 then Exit(False);
  if not VirtualAddressToOffset(Data, ProgramHeaderOffset,
    ProgramHeaderSize, ProgramHeaderCount, StringTableVA,
    StringTableOffset) then Exit(False);
  for I := 0 to High(NeededOffsets) do
  begin
    if not ReadCString(Data, StringTableOffset + NeededOffsets[I],
      Dependency) or (Dependency = '') then Exit(False);
    N := Length(ADependencies);
    SetLength(ADependencies, N + 1);
    ADependencies[N] := Dependency;
  end;
  Result := True;
end;

function IsLibraryTokenCharacter(ACharacter: Char): Boolean;
begin
  Result := not (ACharacter in [' ', #9, #10, #13, '(', ')', ',', ';']);
end;

function LoadLinkerScriptText(const AFileName: string;
  out AText: string): Boolean;
const
  MaximumLinkerScriptSize = 1024 * 1024;
var
  Data: TBytes;
  I: LongInt;
  UpperText: string;
begin
  AText := '';
  if not LoadFileBytes(AFileName, Data) or (Length(Data) = 0) or
     (Length(Data) > MaximumLinkerScriptSize) then Exit(False);
  if (Length(Data) >= 4) and (Data[0] = ELFMagic0) and
     (Data[1] = Ord('E')) and (Data[2] = Ord('L')) and
     (Data[3] = Ord('F')) then Exit(False);
  SetLength(AText, Length(Data));
  for I := 0 to High(Data) do
  begin
    if Data[I] = 0 then
    begin
      AText := '';
      Exit(False);
    end;
    AText[I + 1] := Chr(Data[I]);
  end;
  UpperText := UpperCase(AText);
  Result := (Pos('.SO', UpperText) > 0) and
    ((Pos('GROUP', UpperText) > 0) or (Pos('INPUT', UpperText) > 0));
  if not Result then AText := '';
end;

function LinkerScriptTarget(const AFileName: string;
  const ADirectories: TLibraryStringArray; out ATarget: string): Boolean;
var
  Text, Token, Candidate: string;
  I, J, StartPos: LongInt;
begin
  ATarget := '';
  if not LoadLinkerScriptText(AFileName, Text) then Exit(False);
  I := 1;
  while I <= Length(Text) do
  begin
    while (I <= Length(Text)) and not IsLibraryTokenCharacter(Text[I]) do
      Inc(I);
    StartPos := I;
    while (I <= Length(Text)) and IsLibraryTokenCharacter(Text[I]) do
      Inc(I);
    Token := Copy(Text, StartPos, I - StartPos);
    if (Pos('.so.', LowerCase(Token)) > 0) or
       ((Length(Token) > 3) and
        (LowerCase(Copy(Token, Length(Token) - 2, 3)) = '.so')) then
    begin
      if (Length(Token) > 1) and (Token[1] = '=') then Delete(Token, 1, 1);
      Candidate := '';
      if FileExists(Token) then Candidate := Token
      else
      begin
        Candidate := IncludeTrailingPathDelimiter(
          ExtractFileDir(AFileName)) + Token;
        if not FileExists(Candidate) then Candidate := '';
      end;
      if Candidate = '' then
        for J := 0 to High(ADirectories) do
          if FileExists(IncludeTrailingPathDelimiter(ADirectories[J]) +
            Token) then
          begin
            Candidate := IncludeTrailingPathDelimiter(ADirectories[J]) +
              Token;
            Break;
          end;
      if (Candidate <> '') and (ExpandFileName(Candidate) <>
        ExpandFileName(AFileName)) then
      begin
        ATarget := Candidate;
        Exit(True);
      end;
    end;
  end;
  Result := False;
end;

function CompareVersionText(const ALeft, ARight: string): LongInt;
var
  LeftIndex, RightIndex, LeftStart, RightStart, LeftSignificant,
    RightSignificant, LeftEnd, RightEnd, LeftLength, RightLength: LongInt;
  LeftCharacter, RightCharacter: Char;
begin
  LeftIndex := 1;
  RightIndex := 1;
  while (LeftIndex <= Length(ALeft)) and (RightIndex <= Length(ARight)) do
  begin
    if (ALeft[LeftIndex] in ['0'..'9']) and
       (ARight[RightIndex] in ['0'..'9']) then
    begin
      LeftStart := LeftIndex;
      RightStart := RightIndex;
      while (LeftIndex <= Length(ALeft)) and
        (ALeft[LeftIndex] in ['0'..'9']) do Inc(LeftIndex);
      while (RightIndex <= Length(ARight)) and
        (ARight[RightIndex] in ['0'..'9']) do Inc(RightIndex);
      LeftEnd := LeftIndex - 1;
      RightEnd := RightIndex - 1;
      LeftSignificant := LeftStart;
      RightSignificant := RightStart;
      while (LeftSignificant < LeftEnd) and
        (ALeft[LeftSignificant] = '0') do Inc(LeftSignificant);
      while (RightSignificant < RightEnd) and
        (ARight[RightSignificant] = '0') do Inc(RightSignificant);
      LeftLength := LeftEnd - LeftSignificant + 1;
      RightLength := RightEnd - RightSignificant + 1;
      if LeftLength <> RightLength then
      begin
        if LeftLength > RightLength then Exit(1) else Exit(-1);
      end;
      while LeftSignificant <= LeftEnd do
      begin
        if ALeft[LeftSignificant] <> ARight[RightSignificant] then
        begin
          if ALeft[LeftSignificant] > ARight[RightSignificant] then Exit(1)
          else Exit(-1);
        end;
        Inc(LeftSignificant);
        Inc(RightSignificant);
      end;
      Continue;
    end;
    LeftCharacter := UpCase(ALeft[LeftIndex]);
    RightCharacter := UpCase(ARight[RightIndex]);
    if LeftCharacter <> RightCharacter then
    begin
      if LeftCharacter > RightCharacter then Exit(1) else Exit(-1);
    end;
    Inc(LeftIndex);
    Inc(RightIndex);
  end;
  if LeftIndex <= Length(ALeft) then Exit(1);
  if RightIndex <= Length(ARight) then Exit(-1);
  Result := 0;
end;

function BetterVersionedCandidate(const ACurrent, ACandidate: string): Boolean;
begin
  if ACurrent = '' then Exit(True);
  Result := CompareVersionText(ExtractFileName(ACandidate),
    ExtractFileName(ACurrent)) > 0;
end;

function FindVersionedLibrary(const ADirectory, ABase: string;
  out AFileName: string): Boolean;
var
  Search: TSearchRec;
  Candidate: string;
begin
  AFileName := '';
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + ABase + '.so.*',
    faAnyFile, Search) = 0 then
  begin
    repeat
      if (Search.Attr and faDirectory) = 0 then
      begin
        Candidate := IncludeTrailingPathDelimiter(ADirectory) + Search.Name;
        if BetterVersionedCandidate(AFileName, Candidate) then
          AFileName := Candidate;
      end;
    until FindNext(Search) <> 0;
    FindClose(Search);
  end;
  Result := AFileName <> '';
end;

function FindLibraryFile(const ADirectories: TLibraryStringArray;
  const ARequest: string; out AFileName: string): Boolean;
var
  I: LongInt;
  Base, Candidate: string;
  ExactName: Boolean;
begin
  AFileName := '';
  Base := ARequest;
  ExactName := (Length(Base) > 0) and (Base[1] = ':');
  if ExactName then Delete(Base, 1, 1)
  else if Pos('lib', Base) <> 1 then Base := 'lib' + Base;
  for I := 0 to High(ADirectories) do
  begin
    if ExactName then
      Candidate := IncludeTrailingPathDelimiter(ADirectories[I]) + Base
    else
      Candidate := IncludeTrailingPathDelimiter(ADirectories[I]) + Base + '.so';
    if FileExists(Candidate) then
    begin
      AFileName := Candidate;
      Exit(True);
    end;
    if not ExactName and FindVersionedLibrary(ADirectories[I], Base,
      Candidate) then
    begin
      AFileName := Candidate;
      Exit(True);
    end;
  end;
  if not ExactName then
    for I := 0 to High(ADirectories) do
    begin
      Candidate := IncludeTrailingPathDelimiter(ADirectories[I]) + Base + '.a';
      if FileExists(Candidate) then
      begin
        AFileName := Candidate;
        Exit(True);
      end;
    end;
  Result := False;
end;

function FindStaticLibraryFile(const ADirectories: TLibraryStringArray;
  const ARequest: string; out AFileName: string): Boolean;
var
  I: LongInt;
  Base, Candidate: string;
  ExactName: Boolean;
begin
  AFileName := '';
  Base := ARequest;
  ExactName := (Length(Base) > 0) and (Base[1] = ':');
  if ExactName then Delete(Base, 1, 1)
  else
  begin
    if Pos('lib', Base) <> 1 then Base := 'lib' + Base;
    Base := Base + '.a';
  end;
  for I := 0 to High(ADirectories) do
  begin
    Candidate := IncludeTrailingPathDelimiter(ADirectories[I]) + Base;
    if FileExists(Candidate) and
       (LowerCase(ExtractFileExt(Candidate)) = '.a') then
    begin
      AFileName := Candidate;
      Exit(True);
    end;
  end;
  Result := False;
end;

function DescribeDirectories(const ADirectories: TLibraryStringArray): string;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to High(ADirectories) do
  begin
    if Result <> '' then Result := Result + ', ';
    Result := Result + ADirectories[I];
  end;
  if Result = '' then Result := '(none)';
end;

function DynamicSymbolCount(const AData: TBytes;
  AProgramHeaderOffset: QWord; AProgramHeaderSize,
  AProgramHeaderCount: Word; AHashVA, AGNUHashVA: QWord;
  out ACount: LongWord): Boolean;
var
  HashOffset, BucketsOffset, ChainsOffset: QWord;
  BucketCount, SymbolOffset, BloomSize, Bucket, ChainValue,
    SymbolIndex, I: LongWord;
begin
  ACount := 0;
  if AHashVA <> 0 then
  begin
    if not VirtualAddressToOffset(AData, AProgramHeaderOffset,
      AProgramHeaderSize, AProgramHeaderCount, AHashVA, HashOffset) or
       not ReadLE32(AData, HashOffset + 4, ACount) then Exit(False);
    Exit(ACount <> 0);
  end;
  if AGNUHashVA = 0 then Exit(False);
  if not VirtualAddressToOffset(AData, AProgramHeaderOffset,
    AProgramHeaderSize, AProgramHeaderCount, AGNUHashVA, HashOffset) or
     not ReadLE32(AData, HashOffset, BucketCount) or
     not ReadLE32(AData, HashOffset + 4, SymbolOffset) or
     not ReadLE32(AData, HashOffset + 8, BloomSize) then Exit(False);
  BucketsOffset := HashOffset + 16 + QWord(BloomSize) * 8;
  ChainsOffset := BucketsOffset + QWord(BucketCount) * 4;
  ACount := SymbolOffset;
  if BucketCount = 0 then Exit(False);
  for I := 0 to BucketCount - 1 do
  begin
    if not ReadLE32(AData, BucketsOffset + QWord(I) * 4, Bucket) then
      Exit(False);
    if Bucket = 0 then Continue;
    SymbolIndex := Bucket;
    repeat
      if SymbolIndex < SymbolOffset then Exit(False);
      if not ReadLE32(AData, ChainsOffset +
        QWord(SymbolIndex - SymbolOffset) * 4, ChainValue) then Exit(False);
      if SymbolIndex + 1 > ACount then ACount := SymbolIndex + 1;
      Inc(SymbolIndex);
    until (ChainValue and 1) <> 0;
  end;
  Result := ACount <> 0;
end;

function LoadDynamicSymbols(const AFileName: string; AELFMachine: Word;
  ASymbols: TStringList): Boolean;
var
  Data: TBytes;
  ProgramHeaderOffset, DynamicOffset, DynamicSize, StringTableVA,
    SymbolTableVA, HashVA, GNUHashVA, StringTableOffset,
    SymbolTableOffset, Tag, Value, HeaderOffset, SymbolEntryOffset: QWord;
  ProgramHeaderSize, ProgramHeaderCount, SectionIndex: Word;
  SegmentType, SymbolCount, SymbolNameOffset, I: LongWord;
  SymbolEntrySize: QWord;
  SymbolInfo, SymbolOther, Binding, Visibility: Byte;
  SymbolName: string;
begin
  Result := False;
  if not LoadFileBytes(AFileName, Data) or
     not IsELF64SharedObject(Data, AELFMachine) then Exit;
  if not ReadLE64(Data, 32, ProgramHeaderOffset) or
     not ReadLE16(Data, 54, ProgramHeaderSize) or
     not ReadLE16(Data, 56, ProgramHeaderCount) then Exit;
  DynamicOffset := 0;
  DynamicSize := 0;
  if ProgramHeaderCount = 0 then Exit;
  for I := 0 to LongInt(ProgramHeaderCount) - 1 do
  begin
    HeaderOffset := ProgramHeaderOffset + QWord(I) * ProgramHeaderSize;
    if not ReadLE32(Data, HeaderOffset, SegmentType) then Exit;
    if SegmentType = PTDynamic then
    begin
      if not ReadLE64(Data, HeaderOffset + 8, DynamicOffset) or
         not ReadLE64(Data, HeaderOffset + 32, DynamicSize) then Exit;
      Break;
    end;
  end;
  if (DynamicOffset = 0) or (DynamicSize < 16) then Exit;
  StringTableVA := 0;
  SymbolTableVA := 0;
  HashVA := 0;
  GNUHashVA := 0;
  SymbolEntrySize := 24;
  I := 0;
  while QWord(I) * 16 < DynamicSize do
  begin
    HeaderOffset := DynamicOffset + QWord(I) * 16;
    if not ReadLE64(Data, HeaderOffset, Tag) or
       not ReadLE64(Data, HeaderOffset + 8, Value) then Exit;
    if Tag = DTNull then Break;
    if Tag = DTHash then HashVA := Value
    else if Tag = DTStrTab then StringTableVA := Value
    else if Tag = DTSymTab then SymbolTableVA := Value
    else if Tag = DTSymEnt then SymbolEntrySize := Value
    else if Tag = DTGNUHash then GNUHashVA := Value;
    Inc(I);
  end;
  if (StringTableVA = 0) or (SymbolTableVA = 0) or
     (SymbolEntrySize < 24) then Exit;
  if not DynamicSymbolCount(Data, ProgramHeaderOffset,
    ProgramHeaderSize, ProgramHeaderCount, HashVA, GNUHashVA,
    SymbolCount) then Exit;
  if not VirtualAddressToOffset(Data, ProgramHeaderOffset,
    ProgramHeaderSize, ProgramHeaderCount, StringTableVA,
    StringTableOffset) or
     not VirtualAddressToOffset(Data, ProgramHeaderOffset,
    ProgramHeaderSize, ProgramHeaderCount, SymbolTableVA,
    SymbolTableOffset) then Exit;

  if SymbolCount <= 1 then
  begin
    Result := True;
    Exit;
  end;
  for I := 1 to SymbolCount - 1 do
  begin
    SymbolEntryOffset := SymbolTableOffset + QWord(I) * SymbolEntrySize;
    if not ReadLE32(Data, SymbolEntryOffset, SymbolNameOffset) or
       not ReadByte(Data, SymbolEntryOffset + 4, SymbolInfo) or
       not ReadByte(Data, SymbolEntryOffset + 5, SymbolOther) or
       not ReadLE16(Data, SymbolEntryOffset + 6, SectionIndex) then Exit;
    Binding := SymbolInfo shr 4;
    Visibility := SymbolOther and 3;
    if (SectionIndex = SHNUndefined) or
       not (Binding in [STBGlobal, STBWeak, STBGNUUnique]) or
       not (Visibility in [STVDefault, STVProtected]) or
       (SymbolNameOffset = 0) then Continue;
    if not ReadCString(Data, StringTableOffset + SymbolNameOffset,
      SymbolName) then Exit;
    if SymbolName <> '' then ASymbols.Add(SymbolName);
  end;
  Result := True;
end;

procedure ValidateDynamicSymbolProviders(const ASymbolNames: array of string;
  const ALibraries: TResolvedLibraryArray; AELFMachine: Word);
var
  ExportedSymbols: TStringList;
  I: LongInt;
  Incomplete: Boolean;
begin
  if Length(ASymbolNames) = 0 then Exit;
  ExportedSymbols := TStringList.Create;
  try
    ExportedSymbols.CaseSensitive := True;
    ExportedSymbols.Sorted := True;
    ExportedSymbols.Duplicates := dupIgnore;
    Incomplete := False;
    for I := 0 to High(ALibraries) do
      if ALibraries[I].FileName = '' then
        Incomplete := True
      else if not LoadDynamicSymbols(ALibraries[I].FileName,
        AELFMachine, ExportedSymbols) then
        raise ERCCError.Create('error: cannot read dynamic symbols from ' +
          ALibraries[I].FileName);
    if Incomplete then Exit;
    for I := 0 to High(ASymbolNames) do
      if ExportedSymbols.IndexOf(ASymbolNames[I]) < 0 then
        raise ERCCError.Create('error: undefined reference to ''' +
          ASymbolNames[I] + ''' in selected shared libraries');
  finally
    ExportedSymbols.Free;
  end;
end;

procedure ResolveDefaultLibC(const ADirectories: TLibraryStringArray;
  const ASysroot, ADefaultLibC, AArchitectureName: string;
  AELFMachine: Word; out AFileName: string);
var
  ResolvedName: string;
begin
  AFileName := '';
  if ADefaultLibC = '' then
    raise ERCCError.Create('error: target has no hosted libc dependency');
  if FindLibraryFile(ADirectories, ':' + ADefaultLibC, AFileName) then
  begin
    if not ELFSharedObjectName(AFileName, AELFMachine, ResolvedName) then
      raise ERCCError.Create('error: target libc is not a compatible ' +
        AArchitectureName + ' ELF shared object: ' + AFileName);
    if ResolvedName <> ADefaultLibC then
      raise ERCCError.Create('error: target libc SONAME mismatch: expected ' +
        ADefaultLibC + ', found ' + ResolvedName + ' in ' + AFileName);
    Exit;
  end;
  if ASysroot <> '' then
    raise ERCCError.Create('error: cannot find ' + ADefaultLibC +
      ' in target sysroot ' + ExpandFileName(ASysroot));


end;

function HasResolvedLibrary(const ALibraries: TResolvedLibraryArray;
  const ANeededName: string): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ALibraries) do
    if ALibraries[I].NeededName = ANeededName then Exit(True);
  Result := False;
end;

function FindDynamicDependencyFile(const AParentFile,
  ADependencyName: string; const ADirectories: TLibraryStringArray;
  AELFMachine: Word; out AFileName: string): Boolean;
var
  Candidate, SharedObjectName: string;
begin
  AFileName := '';
  Candidate := IncludeTrailingPathDelimiter(ExtractFileDir(AParentFile)) +
    ADependencyName;
  if FileExists(Candidate) and
     ELFSharedObjectName(Candidate, AELFMachine, SharedObjectName) and
     (SharedObjectName = ADependencyName) then
  begin
    AFileName := Candidate;
    Exit(True);
  end;
  if FindLibraryFile(ADirectories, ':' + ADependencyName, Candidate) and
     ELFSharedObjectName(Candidate, AELFMachine, SharedObjectName) and
     (SharedObjectName = ADependencyName) then
  begin
    AFileName := Candidate;
    Exit(True);
  end;
  Result := False;
end;

procedure ResolveDynamicDependencyClosure(
  var ALibraries: TResolvedLibraryArray;
  const ADirectories: TLibraryStringArray; const ASysroot,
  AArchitectureName: string; AELFMachine: Word; ANativeTarget: Boolean);
var
  Dependencies: TLibraryStringArray;
  LibraryIndex, DependencyIndex: LongInt;
  DependencyName, DependencyFile: string;
begin
  LibraryIndex := 0;
  while LibraryIndex < Length(ALibraries) do
  begin
    if ALibraries[LibraryIndex].FileName <> '' then
    begin
      if not ELFSharedObjectDependencies(
        ALibraries[LibraryIndex].FileName, AELFMachine, Dependencies) then
        raise ERCCError.Create('error: cannot read shared-library dependencies from ' +
          ALibraries[LibraryIndex].FileName);
      for DependencyIndex := 0 to High(Dependencies) do
      begin
        DependencyName := Dependencies[DependencyIndex];
        if HasResolvedLibrary(ALibraries, DependencyName) then Continue;
        if FindDynamicDependencyFile(ALibraries[LibraryIndex].FileName,
          DependencyName, ADirectories, AELFMachine, DependencyFile) then
          AppendResolved(ALibraries, ':' + DependencyName, DependencyFile,
            DependencyName, False)
        else if (ASysroot <> '') or not ANativeTarget then
          raise ERCCError.Create('error: cannot find compatible ' +
            AArchitectureName + ' dependency ' + DependencyName + ' required by ' +
            ALibraries[LibraryIndex].NeededName)
        else
          AppendResolved(ALibraries, ':' + DependencyName, '',
            DependencyName, False);
      end;
    end;
    Inc(LibraryIndex);
  end;
end;

procedure ResolveDynamicLibraries(const AUserPaths, ARequests: array of string;
  const ASysroot, AMultiArch, ADefaultLibC, AArchitectureName: string;
  AELFMachine: Word; ANativeTarget, ARequireDefaultLibC,
  ANoDefaultLibraries, AFreestanding: Boolean;
  out ALibraries: TResolvedLibraryArray);
var
  Directories: TLibraryStringArray;
  I: LongInt;
  Request, FileName, ActualFile, NeededName, ScriptTarget: string;
  HasLibC: Boolean;
begin
  SetLength(ALibraries, 0);
  BuildLibrarySearchDirectories(AUserPaths, ASysroot, AMultiArch,
    ANativeTarget, Directories);
  HasLibC := False;

  for I := 0 to High(ARequests) do
  begin
    Request := ARequests[I];
    if (Length(Request) > 1) and (Request[1] = '@') then
    begin
      FileName := ExpandFileName(Copy(Request, 2, MaxInt));
      if not FileExists(FileName) then
        raise ERCCError.Create('error: shared-library input not found: ' +
          Copy(Request, 2, MaxInt));
      if LowerCase(ExtractFileExt(FileName)) = '.a' then Continue;
      ActualFile := FileName;
      if not ELFSharedObjectName(ActualFile, AELFMachine, NeededName) then
      begin
        ScriptTarget := '';
        if LinkerScriptTarget(ActualFile, Directories, ScriptTarget) and
           ELFSharedObjectName(ScriptTarget, AELFMachine, NeededName) then
          ActualFile := ScriptTarget
        else
          raise ERCCError.Create('error: shared-library input is not a compatible ' +
            AArchitectureName + ' ELF shared object: ' + FileName);
      end;
      AppendResolved(ALibraries, Request, ActualFile, NeededName, True);
      if NeededName = ADefaultLibC then HasLibC := True;
      Continue;
    end;
    if (Request = 'c') or (Request = ':libc.so.6') then
    begin
      ResolveDefaultLibC(Directories, ASysroot, ADefaultLibC,
        AArchitectureName, AELFMachine, FileName);
      AppendResolved(ALibraries, Request, FileName, ADefaultLibC, True);
      HasLibC := True;
      Continue;
    end;
    if AFreestanding then
      raise ERCCError.Create('error: -l' + Request +
        ' requires a hosted target; remove -ffreestanding');
    if not FindLibraryFile(Directories, Request, FileName) then
      raise ERCCError.Create('error: cannot find library -l' + Request +
        '; searched: ' + DescribeDirectories(Directories));
    if LowerCase(ExtractFileExt(FileName)) = '.a' then Continue;
    ActualFile := FileName;
    if not ELFSharedObjectName(ActualFile, AELFMachine, NeededName) then
    begin
      ScriptTarget := '';
      if LinkerScriptTarget(ActualFile, Directories, ScriptTarget) and
         ELFSharedObjectName(ScriptTarget, AELFMachine, NeededName) then
        ActualFile := ScriptTarget
      else
        raise ERCCError.Create('error: library is not a compatible ' +
          AArchitectureName + ' ELF shared object: ' + FileName);
    end;
    AppendResolved(ALibraries, Request, ActualFile, NeededName, True);
  end;

  if ARequireDefaultLibC and not ANoDefaultLibraries and not AFreestanding and
     not HasLibC and (ADefaultLibC <> '') then
  begin
    ResolveDefaultLibC(Directories, ASysroot, ADefaultLibC,
      AArchitectureName, AELFMachine, FileName);
    AppendResolved(ALibraries, 'c', FileName, ADefaultLibC, True);
  end;
  ResolveDynamicDependencyClosure(ALibraries, Directories, ASysroot,
    AArchitectureName, AELFMachine, ANativeTarget);
end;

function ResolvedNeededNames(const ALibraries: TResolvedLibraryArray):
  TLibraryStringArray;
var
  I, N: LongInt;
begin
  Result := nil;
  for I := 0 to High(ALibraries) do
  begin
    if not ALibraries[I].EmitNeeded then Continue;
    N := Length(Result);
    SetLength(Result, N + 1);
    Result[N] := ALibraries[I].NeededName;
  end;
end;

end.
