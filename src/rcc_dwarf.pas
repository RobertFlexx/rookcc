unit rcc_dwarf;

{$mode objfpc}{$H+}

interface

uses
  rcc_types, rcc_object_model;

type
  TObjectDebugFunction = record
    Name: string;
    FileName: string;
    Line: LongInt;
    TextOffset: QWord;
    TextSize: QWord;
    IsExternal: Boolean;
  end;
  TObjectDebugFunctionArray = array of TObjectDebugFunction;

procedure AddDWARF4ObjectSections(AObject: TObjectFile;
  const ASourceName: string; AStandard: TCStandard;
  ATextSectionSymbol: LongInt; ATextSize: QWord;
  const AFunctions: TObjectDebugFunctionArray);

implementation

uses
  Classes, SysUtils, rcc_buffer, rcc_build;

const
  DWTagCompileUnit = QWord($11);
  DWTagSubprogram = QWord($2E);
  DWChildrenNo = Byte(0);
  DWChildrenYes = Byte(1);
  DWAtName = QWord($03);
  DWAtStmtList = QWord($10);
  DWAtLowPC = QWord($11);
  DWAtHighPC = QWord($12);
  DWAtLanguage = QWord($13);
  DWAtCompDir = QWord($1B);
  DWAtProducer = QWord($25);
  DWAtExternal = QWord($3F);
  DWAtDeclFile = QWord($3A);
  DWAtDeclLine = QWord($3B);
  DWFormAddr = QWord($01);
  DWFormData1 = QWord($0B);
  DWFormData2 = QWord($05);
  DWFormData4 = QWord($06);
  DWFormData8 = QWord($07);
  DWFormFlag = QWord($0C);
  DWFormStrP = QWord($0E);
  DWFormSecOffset = QWord($17);
  DWLangC89 = Word($0001);
  DWLangC99 = Word($000C);
  DWLangC11 = Word($001D);
  R_X86_64_64 = LongWord(1);

procedure AddULEB128(ABuffer: TByteBuffer; AValue: QWord);
var
  B: Byte;
begin
  repeat
    B := Byte(AValue and $7F);
    AValue := AValue shr 7;
    if AValue <> 0 then B := B or $80;
    ABuffer.Add8(B);
  until AValue = 0;
end;

procedure AddPositiveSLEB128(ABuffer: TByteBuffer; AValue: QWord);
var
  B: Byte;
  Finished: Boolean;
begin
  repeat
    B := Byte(AValue and $7F);
    AValue := AValue shr 7;
    Finished := (AValue = 0) and ((B and $40) = 0);
    if not Finished then B := B or $80;
    ABuffer.Add8(B);
  until Finished;
end;

function AddDebugString(ABuffer: TByteBuffer; const AValue: string): LongWord;
begin
  if QWord(ABuffer.Size) > High(LongWord) then
    raise ERCCError.Create('internal error: DWARF string table exceeds 4 GiB');
  Result := LongWord(ABuffer.Size);
  ABuffer.AddStringZ(AValue);
end;

function DebugLanguage(AStandard: TCStandard): Word;
begin
  case AStandard of
    csC90: Result := DWLangC89;
    csC99, csGNU99: Result := DWLangC99;
  else
    Result := DWLangC11;
  end;
end;

procedure AddAttribute(ABuffer: TByteBuffer; AName, AForm: QWord);
begin
  AddULEB128(ABuffer, AName);
  AddULEB128(ABuffer, AForm);
end;

procedure AddDWARF4ObjectSections(AObject: TObjectFile;
  const ASourceName: string; AStandard: TCStandard;
  ATextSectionSymbol: LongInt; ATextSize: QWord;
  const AFunctions: TObjectDebugFunctionArray);
var
  AbbrevIndex, InfoIndex, LineIndex, StrIndex: LongInt;
  Abbrev, Info, LineData, DebugStr: TByteBuffer;
  Files: TStringList;
  FunctionNameOffsets: array of LongWord;
  FunctionFileIndices: array of LongInt;
  ProducerOffset, SourceOffset, DirectoryOffset: LongWord;
  UnitLengthOffset, HeaderLengthOffset, HeaderStart: LongInt;
  RelocationOffset: LongInt;
  I, FileIndex: LongInt;
  Source, FunctionFile: string;
begin
  if AObject = nil then
    raise ERCCError.Create('internal error: nil object passed to DWARF writer');
  Source := ASourceName;
  if Source = '' then Source := 'rcc-input.c';
  AbbrevIndex := AObject.AddSection('.debug_abbrev', oskDebug, [], 1);
  InfoIndex := AObject.AddSection('.debug_info', oskDebug, [], 1);
  LineIndex := AObject.AddSection('.debug_line', oskDebug, [], 1);
  StrIndex := AObject.AddSection('.debug_str', oskDebug,
    [osfMerge, osfStrings], 1);
  Abbrev := AObject.Section(AbbrevIndex).Data;
  Info := AObject.Section(InfoIndex).Data;
  LineData := AObject.Section(LineIndex).Data;
  DebugStr := AObject.Section(StrIndex).Data;


  AddULEB128(Abbrev, 1);
  AddULEB128(Abbrev, DWTagCompileUnit);
  Abbrev.Add8(DWChildrenYes);
  AddAttribute(Abbrev, DWAtProducer, DWFormStrP);
  AddAttribute(Abbrev, DWAtLanguage, DWFormData2);
  AddAttribute(Abbrev, DWAtName, DWFormStrP);
  AddAttribute(Abbrev, DWAtCompDir, DWFormStrP);
  AddAttribute(Abbrev, DWAtStmtList, DWFormSecOffset);
  AddAttribute(Abbrev, DWAtLowPC, DWFormAddr);
  AddAttribute(Abbrev, DWAtHighPC, DWFormData8);
  Abbrev.AddBytes([0, 0]);


  AddULEB128(Abbrev, 2);
  AddULEB128(Abbrev, DWTagSubprogram);
  Abbrev.Add8(DWChildrenNo);
  AddAttribute(Abbrev, DWAtName, DWFormStrP);
  AddAttribute(Abbrev, DWAtDeclFile, DWFormData2);
  AddAttribute(Abbrev, DWAtDeclLine, DWFormData4);
  AddAttribute(Abbrev, DWAtLowPC, DWFormAddr);
  AddAttribute(Abbrev, DWAtHighPC, DWFormData8);
  AddAttribute(Abbrev, DWAtExternal, DWFormFlag);
  Abbrev.AddBytes([0, 0, 0]);

  ProducerOffset := AddDebugString(DebugStr, 'RookCC ' + RCCVersion);
  SourceOffset := AddDebugString(DebugStr, Source);
  DirectoryOffset := AddDebugString(DebugStr, GetCurrentDir);
  SetLength(FunctionNameOffsets, Length(AFunctions));
  for I := 0 to High(AFunctions) do
    FunctionNameOffsets[I] := AddDebugString(DebugStr, AFunctions[I].Name);

  Files := TStringList.Create;
  try
    Files.CaseSensitive := True;
    Files.Duplicates := dupIgnore;
    Files.Add(Source);
    SetLength(FunctionFileIndices, Length(AFunctions));
    for I := 0 to High(AFunctions) do
    begin
      FunctionFile := AFunctions[I].FileName;
      if FunctionFile = '' then FunctionFile := Source;
      FileIndex := Files.IndexOf(FunctionFile);
      if FileIndex < 0 then FileIndex := Files.Add(FunctionFile);
      FunctionFileIndices[I] := FileIndex + 1;
    end;

    UnitLengthOffset := Info.Size;
    Info.Add32(0);
    Info.Add16(4);
    Info.Add32(0);
    Info.Add8(8);
    AddULEB128(Info, 1);
    Info.Add32(ProducerOffset);
    Info.Add16(DebugLanguage(AStandard));
    Info.Add32(SourceOffset);
    Info.Add32(DirectoryOffset);
    Info.Add32(0);
    RelocationOffset := Info.Size;
    Info.Add64(0);
    AObject.AddRelocation(InfoIndex, QWord(RelocationOffset),
      ATextSectionSymbol, orkAbsolute64, R_X86_64_64, 0);
    Info.Add64(ATextSize);
    for I := 0 to High(AFunctions) do
    begin
      AddULEB128(Info, 2);
      Info.Add32(FunctionNameOffsets[I]);
      Info.Add16(Word(FunctionFileIndices[I]));
      if AFunctions[I].Line < 1 then Info.Add32(1)
      else Info.Add32(LongWord(AFunctions[I].Line));
      RelocationOffset := Info.Size;
      Info.Add64(0);
      AObject.AddRelocation(InfoIndex, QWord(RelocationOffset),
        ATextSectionSymbol, orkAbsolute64, R_X86_64_64,
        Int64(AFunctions[I].TextOffset));
      Info.Add64(AFunctions[I].TextSize);
      Info.Add8(Byte(Ord(AFunctions[I].IsExternal)));
    end;
    Info.Add8(0);
    Info.Patch32(UnitLengthOffset, Info.Size - UnitLengthOffset - 4);

    UnitLengthOffset := LineData.Size;
    LineData.Add32(0);
    LineData.Add16(4);
    HeaderLengthOffset := LineData.Size;
    LineData.Add32(0);
    HeaderStart := LineData.Size;
    LineData.AddBytes([1, 1, 1, $FB, 14, 13]);
    LineData.AddBytes([0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1]);
    LineData.Add8(0);
    for I := 0 to Files.Count - 1 do
    begin
      LineData.AddStringZ(Files[I]);
      AddULEB128(LineData, 0);
      AddULEB128(LineData, 0);
      AddULEB128(LineData, 0);
    end;
    LineData.Add8(0);
    LineData.Patch32(HeaderLengthOffset, LineData.Size - HeaderStart);

    for I := 0 to High(AFunctions) do
    begin
      LineData.Add8(0);
      AddULEB128(LineData, 9);
      LineData.Add8(2);
      RelocationOffset := LineData.Size;
      LineData.Add64(0);
      AObject.AddRelocation(LineIndex, QWord(RelocationOffset),
        ATextSectionSymbol, orkAbsolute64, R_X86_64_64,
        Int64(AFunctions[I].TextOffset));
      LineData.Add8(4);
      AddULEB128(LineData, QWord(FunctionFileIndices[I]));
      if AFunctions[I].Line > 1 then
      begin
        LineData.Add8(3);
        AddPositiveSLEB128(LineData, QWord(AFunctions[I].Line - 1));
      end;
      LineData.Add8(1);
      if AFunctions[I].TextSize <> 0 then
      begin
        LineData.Add8(2);
        AddULEB128(LineData, AFunctions[I].TextSize);
      end;
      LineData.AddBytes([0, 1, 1]);
    end;
    LineData.Patch32(UnitLengthOffset,
      LineData.Size - UnitLengthOffset - 4);
  finally
    Files.Free;
  end;
end;

end.
