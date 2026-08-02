unit rcc_object_model;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_buffer, rcc_arch;

type
  TObjectSectionKind = (
    oskNull,
    oskText,
    oskReadOnlyData,
    oskData,
    oskBSS,
    oskTLSData,
    oskTLSBSS,
    oskDebug,
    oskNote,
    oskCustom
  );

  TObjectSectionFlags = set of (
    osfAlloc,
    osfWrite,
    osfExecute,
    osfMerge,
    osfStrings,
    osfTLS
  );

  TObjectSymbolBinding = (
    osbLocal,
    osbGlobal,
    osbWeak
  );

  TObjectSymbolType = (
    ostNoType,
    ostObject,
    ostFunction,
    ostSection,
    ostFile,
    ostTLS
  );

  TObjectSymbolVisibility = (
    osvDefault,
    osvInternal,
    osvHidden,
    osvProtected
  );

  TObjectRelocationKind = (
    orkNone,
    orkAbsolute8,
    orkAbsolute16,
    orkAbsolute32,
    orkAbsolute64,
    orkPCRelative8,
    orkPCRelative16,
    orkPCRelative32,
    orkPCRelative64,
    orkCall,
    orkJump,
    orkGOT,
    orkPLT,
    orkTLS,
    orkPage21,
    orkPageOffset12,
    orkGOTPage21,
    orkGOTPageOffset12,
    orkArchitectureSpecific
  );

  TObjectSection = class
  public
    Name: string;
    Kind: TObjectSectionKind;
    Flags: TObjectSectionFlags;
    Alignment: QWord;
    EntrySize: QWord;
    VirtualSize: QWord;
    LinkSection: LongInt;
    Info: LongInt;
    Data: TByteBuffer;
    constructor Create(const AName: string; AKind: TObjectSectionKind;
      AFlags: TObjectSectionFlags; AAlignment: QWord);
    destructor Destroy; override;
    function Size: QWord;
    procedure PadTo(AAlignment: LongInt);
  end;
  TObjectSectionArray = array of TObjectSection;

  TObjectSymbol = record
    Name: string;
    Binding: TObjectSymbolBinding;
    SymbolType: TObjectSymbolType;
    Visibility: TObjectSymbolVisibility;
    SectionIndex: LongInt;
    Value: QWord;
    Size: QWord;
    IsDefined: Boolean;
  end;
  TObjectSymbolArray = array of TObjectSymbol;

  TObjectRelocation = record
    SectionIndex: LongInt;
    Offset: QWord;
    SymbolIndex: LongInt;
    Kind: TObjectRelocationKind;
    ArchitectureCode: LongWord;
    Addend: Int64;
  end;
  TObjectRelocationArray = array of TObjectRelocation;

  TObjectFile = class
  private
    FTarget: TTargetDescriptor;
    FSections: TObjectSectionArray;
    FSymbols: TObjectSymbolArray;
    FRelocations: TObjectRelocationArray;
    FSourceName: string;
  public
    constructor Create(const ATarget: TTargetDescriptor);
    destructor Destroy; override;
    function AddSection(const AName: string; AKind: TObjectSectionKind;
      AFlags: TObjectSectionFlags; AAlignment: QWord): LongInt;
    function FindSection(const AName: string): LongInt;
    function RequireSection(const AName: string; AKind: TObjectSectionKind;
      AFlags: TObjectSectionFlags; AAlignment: QWord): LongInt;
    function Section(AIndex: LongInt): TObjectSection;
    function AddSymbol(const AName: string; ABinding: TObjectSymbolBinding;
      ASymbolType: TObjectSymbolType; AVisibility: TObjectSymbolVisibility;
      ASectionIndex: LongInt; AValue, ASize: QWord;
      ADefined: Boolean): LongInt;
    function FindSymbol(const AName: string): LongInt;
    function RequireUndefinedSymbol(const AName: string;
      ASymbolType: TObjectSymbolType): LongInt;
    procedure AddRelocation(ASectionIndex: LongInt; AOffset: QWord;
      ASymbolIndex: LongInt; AKind: TObjectRelocationKind;
      AArchitectureCode: LongWord; AAddend: Int64);
    procedure Validate;
    function Summary: string;
    property Target: TTargetDescriptor read FTarget;
    property Sections: TObjectSectionArray read FSections;
    property Symbols: TObjectSymbolArray read FSymbols;
    property Relocations: TObjectRelocationArray read FRelocations;
    property SourceName: string read FSourceName write FSourceName;
  end;

function SectionKindName(AKind: TObjectSectionKind): string;
function SymbolBindingName(ABinding: TObjectSymbolBinding): string;
function SymbolTypeName(AType: TObjectSymbolType): string;
function RelocationKindName(AKind: TObjectRelocationKind): string;
function SectionDefaultELFName(AKind: TObjectSectionKind): string;
function SectionDefaultFlags(AKind: TObjectSectionKind): TObjectSectionFlags;

implementation

constructor TObjectSection.Create(const AName: string;
  AKind: TObjectSectionKind; AFlags: TObjectSectionFlags; AAlignment: QWord);
begin
  inherited Create;
  Name := AName;
  Kind := AKind;
  Flags := AFlags;
  if AAlignment = 0 then Alignment := 1 else Alignment := AAlignment;
  EntrySize := 0;
  VirtualSize := 0;
  LinkSection := 0;
  Info := 0;
  Data := TByteBuffer.Create;
end;

destructor TObjectSection.Destroy;
begin
  Data.Free;
  inherited Destroy;
end;

function TObjectSection.Size: QWord;
begin
  if Kind = oskBSS then Result := VirtualSize
  else if Kind = oskTLSBSS then Result := VirtualSize
  else Result := QWord(Data.Size);
end;

procedure TObjectSection.PadTo(AAlignment: LongInt);
begin
  if AAlignment <= 0 then Exit;
  Data.PadTo(AAlignment);
end;

constructor TObjectFile.Create(const ATarget: TTargetDescriptor);
begin
  inherited Create;
  FTarget := ATarget;
  SetLength(FSections, 0);
  SetLength(FSymbols, 0);
  SetLength(FRelocations, 0);
  FSourceName := '';
  AddSection('', oskNull, [], 1);
end;

destructor TObjectFile.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(FSections) do FSections[I].Free;
  inherited Destroy;
end;

function TObjectFile.AddSection(const AName: string;
  AKind: TObjectSectionKind; AFlags: TObjectSectionFlags;
  AAlignment: QWord): LongInt;
var
  N: LongInt;
begin
  if (AName <> '') and (FindSection(AName) >= 0) then
    raise ERCCError.Create('internal error: duplicate object section ''' +
      AName + '''');
  N := Length(FSections);
  SetLength(FSections, N + 1);
  FSections[N] := TObjectSection.Create(AName, AKind, AFlags, AAlignment);
  Result := N;
end;

function TObjectFile.FindSection(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(FSections) do
    if FSections[I].Name = AName then Exit(I);
  Result := -1;
end;

function TObjectFile.RequireSection(const AName: string;
  AKind: TObjectSectionKind; AFlags: TObjectSectionFlags;
  AAlignment: QWord): LongInt;
begin
  Result := FindSection(AName);
  if Result < 0 then Result := AddSection(AName, AKind, AFlags, AAlignment);
end;

function TObjectFile.Section(AIndex: LongInt): TObjectSection;
begin
  if (AIndex < 0) or (AIndex > High(FSections)) then
    raise ERCCError.Create('internal error: invalid object section index');
  Result := FSections[AIndex];
end;

function TObjectFile.AddSymbol(const AName: string;
  ABinding: TObjectSymbolBinding; ASymbolType: TObjectSymbolType;
  AVisibility: TObjectSymbolVisibility; ASectionIndex: LongInt;
  AValue, ASize: QWord; ADefined: Boolean): LongInt;
var
  N: LongInt;
begin
  if (ASectionIndex < 0) or (ASectionIndex > High(FSections)) then
    raise ERCCError.Create('internal error: symbol has invalid section');
  N := Length(FSymbols);
  SetLength(FSymbols, N + 1);
  FSymbols[N].Name := AName;
  FSymbols[N].Binding := ABinding;
  FSymbols[N].SymbolType := ASymbolType;
  FSymbols[N].Visibility := AVisibility;
  FSymbols[N].SectionIndex := ASectionIndex;
  FSymbols[N].Value := AValue;
  FSymbols[N].Size := ASize;
  FSymbols[N].IsDefined := ADefined;
  Result := N;
end;

function TObjectFile.FindSymbol(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := High(FSymbols) downto 0 do
    if FSymbols[I].Name = AName then Exit(I);
  Result := -1;
end;

function TObjectFile.RequireUndefinedSymbol(const AName: string;
  ASymbolType: TObjectSymbolType): LongInt;
begin
  Result := FindSymbol(AName);
  if Result >= 0 then Exit;
  Result := AddSymbol(AName, osbGlobal, ASymbolType, osvDefault,
    0, 0, 0, False);
end;

procedure TObjectFile.AddRelocation(ASectionIndex: LongInt; AOffset: QWord;
  ASymbolIndex: LongInt; AKind: TObjectRelocationKind;
  AArchitectureCode: LongWord; AAddend: Int64);
var
  N: LongInt;
begin
  if (ASectionIndex <= 0) or (ASectionIndex > High(FSections)) then
    raise ERCCError.Create('internal error: relocation has invalid section');
  if (ASymbolIndex < 0) or (ASymbolIndex > High(FSymbols)) then
    raise ERCCError.Create('internal error: relocation has invalid symbol');
  N := Length(FRelocations);
  SetLength(FRelocations, N + 1);
  FRelocations[N].SectionIndex := ASectionIndex;
  FRelocations[N].Offset := AOffset;
  FRelocations[N].SymbolIndex := ASymbolIndex;
  FRelocations[N].Kind := AKind;
  FRelocations[N].ArchitectureCode := AArchitectureCode;
  FRelocations[N].Addend := AAddend;
end;

procedure TObjectFile.Validate;
var
  I: LongInt;
  S: TObjectSection;
begin
  if Length(FSections) = 0 then
    raise ERCCError.Create('internal error: object has no null section');
  if (FSections[0].Kind <> oskNull) or (FSections[0].Name <> '') then
    raise ERCCError.Create('internal error: object section zero is not null');
  for I := 1 to High(FSections) do
  begin
    S := FSections[I];
    if S.Name = '' then
      raise ERCCError.Create('internal error: named object section is empty');
    if (S.Alignment = 0) or ((S.Alignment and (S.Alignment - 1)) <> 0) then
      raise ERCCError.Create('internal error: object section alignment invalid');
  end;
  for I := 0 to High(FSymbols) do
  begin
    if FSymbols[I].SectionIndex > High(FSections) then
      raise ERCCError.Create('internal error: object symbol section invalid');
    if FSymbols[I].IsDefined and (FSymbols[I].SectionIndex = 0) then
      raise ERCCError.Create('internal error: defined object symbol is undefined');
  end;
  for I := 0 to High(FRelocations) do
  begin
    if FRelocations[I].Offset >= Section(FRelocations[I].SectionIndex).Size then
      raise ERCCError.Create('internal error: relocation offset out of range');
    if FRelocations[I].SymbolIndex > High(FSymbols) then
      raise ERCCError.Create('internal error: relocation symbol out of range');
    if FRelocations[I].SymbolIndex < 0 then
      raise ERCCError.Create('internal error: relocation symbol is negative');
  end;
end;

function TObjectFile.Summary: string;
var
  Lines: TStringList;
  I: LongInt;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('object target: ' + FTarget.Triple);
    Lines.Add('sections: ' + IntToStr(Length(FSections)));
    for I := 0 to High(FSections) do
      Lines.Add(Format('  [%d] %-16s %-10s size=%d align=%d',
        [I, FSections[I].Name, SectionKindName(FSections[I].Kind),
         FSections[I].Size, FSections[I].Alignment]));
    Lines.Add('symbols: ' + IntToStr(Length(FSymbols)));
    for I := 0 to High(FSymbols) do
      Lines.Add(Format('  [%d] %-24s %-7s %-8s section=%d value=%d size=%d',
        [I, FSymbols[I].Name,
         SymbolBindingName(FSymbols[I].Binding),
         SymbolTypeName(FSymbols[I].SymbolType),
         FSymbols[I].SectionIndex, FSymbols[I].Value, FSymbols[I].Size]));
    Lines.Add('relocations: ' + IntToStr(Length(FRelocations)));
    for I := 0 to High(FRelocations) do
      Lines.Add(Format('  section=%d offset=%d symbol=%d kind=%s addend=%d',
        [FRelocations[I].SectionIndex, FRelocations[I].Offset,
         FRelocations[I].SymbolIndex,
         RelocationKindName(FRelocations[I].Kind),
         FRelocations[I].Addend]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function SectionKindName(AKind: TObjectSectionKind): string;
begin
  case AKind of
    oskNull: Result := 'null';
    oskText: Result := 'text';
    oskReadOnlyData: Result := 'rodata';
    oskData: Result := 'data';
    oskBSS: Result := 'bss';
    oskTLSData: Result := 'tdata';
    oskTLSBSS: Result := 'tbss';
    oskDebug: Result := 'debug';
    oskNote: Result := 'note';
    oskCustom: Result := 'custom';
  else
    Result := 'unknown';
  end;
end;

function SymbolBindingName(ABinding: TObjectSymbolBinding): string;
begin
  case ABinding of
    osbLocal: Result := 'local';
    osbGlobal: Result := 'global';
    osbWeak: Result := 'weak';
  else
    Result := 'unknown';
  end;
end;

function SymbolTypeName(AType: TObjectSymbolType): string;
begin
  case AType of
    ostNoType: Result := 'notype';
    ostObject: Result := 'object';
    ostFunction: Result := 'function';
    ostSection: Result := 'section';
    ostFile: Result := 'file';
    ostTLS: Result := 'tls';
  else
    Result := 'unknown';
  end;
end;

function RelocationKindName(AKind: TObjectRelocationKind): string;
begin
  case AKind of
    orkNone: Result := 'none';
    orkAbsolute8: Result := 'abs8';
    orkAbsolute16: Result := 'abs16';
    orkAbsolute32: Result := 'abs32';
    orkAbsolute64: Result := 'abs64';
    orkPCRelative8: Result := 'pcrel8';
    orkPCRelative16: Result := 'pcrel16';
    orkPCRelative32: Result := 'pcrel32';
    orkPCRelative64: Result := 'pcrel64';
    orkCall: Result := 'call';
    orkJump: Result := 'jump';
    orkGOT: Result := 'got';
    orkPLT: Result := 'plt';
    orkTLS: Result := 'tls';
    orkPage21: Result := 'page21';
    orkPageOffset12: Result := 'pageoff12';
    orkGOTPage21: Result := 'got-page21';
    orkGOTPageOffset12: Result := 'got-pageoff12';
    orkArchitectureSpecific: Result := 'arch';
  else
    Result := 'unknown';
  end;
end;

function SectionDefaultELFName(AKind: TObjectSectionKind): string;
begin
  case AKind of
    oskText: Result := '.text';
    oskReadOnlyData: Result := '.rodata';
    oskData: Result := '.data';
    oskBSS: Result := '.bss';
    oskTLSData: Result := '.tdata';
    oskTLSBSS: Result := '.tbss';
    oskDebug: Result := '.debug_info';
    oskNote: Result := '.note.rcc';
  else
    Result := '';
  end;
end;

function SectionDefaultFlags(AKind: TObjectSectionKind): TObjectSectionFlags;
begin
  case AKind of
    oskText: Result := [osfAlloc, osfExecute];
    oskReadOnlyData: Result := [osfAlloc];
    oskData, oskBSS: Result := [osfAlloc, osfWrite];
    oskTLSData, oskTLSBSS: Result := [osfAlloc, osfWrite, osfTLS];
  else
    Result := [];
  end;
end;

end.
