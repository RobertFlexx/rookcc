unit rcc_link_plan;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_arch, rcc_object_model;

type
  TLinkOutputKind = (
    lokExecutable,
    lokSharedObject,
    lokRelocatable,
    lokStaticArchive
  );

  TLinkInputKind = (
    likObject,
    likArchive,
    likSharedLibrary,
    likRuntimeObject,
    likLinkerScript
  );

  TLinkInput = record
    Kind: TLinkInputKind;
    FileName: string;
    AsNeeded: Boolean;
    WholeArchive: Boolean;
    GroupDepth: LongInt;
  end;
  TLinkInputArray = array of TLinkInput;

  TDynamicSymbolRequest = record
    Name: string;
    IsFunction: Boolean;
    Weak: Boolean;
    VersionName: string;
  end;
  TDynamicSymbolRequestArray = array of TDynamicSymbolRequest;

  TLinkSearchDirectory = record
    Path: string;
    IsSystem: Boolean;
    Origin: string;
  end;
  TLinkSearchDirectoryArray = array of TLinkSearchDirectory;

  TLinkPlan = class
  public
    Target: TTargetDescriptor;
    OutputKind: TLinkOutputKind;
    OutputFile: string;
    EntrySymbol: string;
    Interpreter: string;
    Soname: string;
    Inputs: TLinkInputArray;
    SearchDirectories: TLinkSearchDirectoryArray;
    NeededLibraries: rcc_types.TStringArray;
    RPaths: rcc_types.TStringArray;
    ExportedSymbols: rcc_types.TStringArray;
    DynamicSymbols: TDynamicSymbolRequestArray;
    PositionIndependent: Boolean;
    BindNow: Boolean;
    Relro: Boolean;
    NoExecStack: Boolean;
    StripSymbols: Boolean;
    GarbageCollectSections: Boolean;
    constructor Create(const ATarget: TTargetDescriptor);
    procedure AddInput(AKind: TLinkInputKind; const AFileName: string);
    procedure AddSearchDirectory(const APath, AOrigin: string;
      ASystem: Boolean);
    procedure AddNeededLibrary(const AName: string);
    procedure AddRPath(const APath: string);
    procedure AddExportedSymbol(const AName: string);
    procedure RequireDynamicSymbol(const AName: string;
      AIsFunction, AWeak: Boolean; const AVersion: string = '');
    function FindDynamicSymbol(const AName: string): LongInt;
    procedure Validate;
    function Summary: string;
  end;

function LinkOutputKindName(AKind: TLinkOutputKind): string;
function LinkInputKindName(AKind: TLinkInputKind): string;
function DefaultLinkPlan(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor): TLinkPlan;
function BuildRuntimeLinkPlan(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor; AObject: TObjectFile): TLinkPlan;
function ResolveLibraryFile(APlan: TLinkPlan; const AName: string;
  out APath: string): Boolean;
function LinkPlanText(APlan: TLinkPlan): string;
function CanDirectLink(APlan: TLinkPlan; out AReason: string): Boolean;

implementation

procedure AppendUnique(var AValues: rcc_types.TStringArray; const AValue: string);
var
  I, N: LongInt;
begin
  if AValue = '' then Exit;
  for I := 0 to High(AValues) do
    if AValues[I] = AValue then Exit;
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

function LinkOutputKindName(AKind: TLinkOutputKind): string;
begin
  case AKind of
    lokExecutable: Result := 'executable';
    lokSharedObject: Result := 'shared-object';
    lokRelocatable: Result := 'relocatable';
    lokStaticArchive: Result := 'static-archive';
  else
    Result := 'unknown';
  end;
end;

function LinkInputKindName(AKind: TLinkInputKind): string;
begin
  case AKind of
    likObject: Result := 'object';
    likArchive: Result := 'archive';
    likSharedLibrary: Result := 'shared-library';
    likRuntimeObject: Result := 'runtime-object';
    likLinkerScript: Result := 'linker-script';
  else
    Result := 'unknown';
  end;
end;

constructor TLinkPlan.Create(const ATarget: TTargetDescriptor);
begin
  inherited Create;
  Target := ATarget;
  OutputKind := lokExecutable;
  OutputFile := 'a.out';
  EntrySymbol := '_start';
  Interpreter := ATarget.DefaultDynamicLoader;
  Soname := '';
  SetLength(Inputs, 0);
  SetLength(SearchDirectories, 0);
  SetLength(NeededLibraries, 0);
  SetLength(RPaths, 0);
  SetLength(ExportedSymbols, 0);
  SetLength(DynamicSymbols, 0);
  PositionIndependent := False;
  BindNow := False;
  Relro := True;
  NoExecStack := True;
  StripSymbols := False;
  GarbageCollectSections := False;
end;

procedure TLinkPlan.AddInput(AKind: TLinkInputKind;
  const AFileName: string);
var
  N: LongInt;
begin
  if AFileName = '' then
    raise ERCCError.Create('internal error: empty linker input');
  N := Length(Inputs);
  SetLength(Inputs, N + 1);
  Inputs[N].Kind := AKind;
  Inputs[N].FileName := AFileName;
  Inputs[N].AsNeeded := False;
  Inputs[N].WholeArchive := False;
  Inputs[N].GroupDepth := 0;
end;

procedure TLinkPlan.AddSearchDirectory(const APath, AOrigin: string;
  ASystem: Boolean);
var
  I, N: LongInt;
begin
  if APath = '' then Exit;
  for I := 0 to High(SearchDirectories) do
    if SearchDirectories[I].Path = APath then Exit;
  N := Length(SearchDirectories);
  SetLength(SearchDirectories, N + 1);
  SearchDirectories[N].Path := APath;
  SearchDirectories[N].IsSystem := ASystem;
  SearchDirectories[N].Origin := AOrigin;
end;

procedure TLinkPlan.AddNeededLibrary(const AName: string);
begin
  AppendUnique(NeededLibraries, AName);
end;

procedure TLinkPlan.AddRPath(const APath: string);
begin
  AppendUnique(RPaths, APath);
end;

procedure TLinkPlan.AddExportedSymbol(const AName: string);
begin
  AppendUnique(ExportedSymbols, AName);
end;

function TLinkPlan.FindDynamicSymbol(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(DynamicSymbols) do
    if DynamicSymbols[I].Name = AName then Exit(I);
  Result := -1;
end;

procedure TLinkPlan.RequireDynamicSymbol(const AName: string;
  AIsFunction, AWeak: Boolean; const AVersion: string);
var
  N: LongInt;
begin
  if AName = '' then
    raise ERCCError.Create('internal error: empty dynamic symbol request');
  if FindDynamicSymbol(AName) >= 0 then Exit;
  N := Length(DynamicSymbols);
  SetLength(DynamicSymbols, N + 1);
  DynamicSymbols[N].Name := AName;
  DynamicSymbols[N].IsFunction := AIsFunction;
  DynamicSymbols[N].Weak := AWeak;
  DynamicSymbols[N].VersionName := AVersion;
end;

procedure TLinkPlan.Validate;
var
  I: LongInt;
begin
  if Target.Architecture = archUnknown then
    raise ERCCError.Create('internal error: link plan has unknown target');
  if OutputFile = '' then
    raise ERCCError.Create('internal error: link plan has no output path');
  if (OutputKind = lokExecutable) and (EntrySymbol = '') then
    raise ERCCError.Create('internal error: executable link has no entry');
  if (OutputKind = lokSharedObject) and not PositionIndependent then
    raise ERCCError.Create('error: shared objects require position-independent code');
  if (Length(DynamicSymbols) > 0) and
     not TargetHasCapability(Target, tcDynamicELF) then
    raise ERCCError.Create('error: target does not support dynamic ELF output');
  for I := 0 to High(Inputs) do
    if Inputs[I].FileName = '' then
      raise ERCCError.Create('internal error: link plan contains empty input');
end;

function TLinkPlan.Summary: string;
begin
  Result := Format('%s %s: %d input(s), %d needed library/libraries, %d dynamic symbol(s)',
    [Target.Triple, LinkOutputKindName(OutputKind), Length(Inputs),
     Length(NeededLibraries), Length(DynamicSymbols)]);
end;

function DefaultLinkPlan(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor): TLinkPlan;
var
  I: LongInt;
begin
  Result := TLinkPlan.Create(ATarget);
  Result.OutputFile := AOptions.OutputFile;
  Result.PositionIndependent := AOptions.PositionIndependent;
  if AOptions.EmitMode = emObject then Result.OutputKind := lokRelocatable
  else Result.OutputKind := lokExecutable;
  for I := 0 to High(AOptions.LibraryPaths) do
    Result.AddSearchDirectory(AOptions.LibraryPaths[I], 'command-line', False);
  for I := 0 to High(AOptions.Libraries) do
    Result.AddNeededLibrary(AOptions.Libraries[I]);
  for I := 0 to High(AOptions.ObjectFiles) do
    Result.AddInput(likObject, AOptions.ObjectFiles[I]);
end;

function BuildRuntimeLinkPlan(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor; AObject: TObjectFile): TLinkPlan;
var
  I: LongInt;
begin
  Result := DefaultLinkPlan(AOptions, ATarget);
  if AObject <> nil then
  begin
    for I := 0 to High(AObject.Symbols) do
      if not AObject.Symbols[I].IsDefined then
        Result.RequireDynamicSymbol(AObject.Symbols[I].Name,
          AObject.Symbols[I].SymbolType = ostFunction,
          AObject.Symbols[I].Binding = osbWeak);
  end;
  if not AOptions.Freestanding then
  begin
    Result.AddNeededLibrary(ATarget.DefaultLibC);
    Result.Interpreter := ATarget.DefaultDynamicLoader;
  end
  else Result.Interpreter := '';
end;

function ResolveLibraryFile(APlan: TLinkPlan; const AName: string;
  out APath: string): Boolean;
var
  I: LongInt;
  Candidate, Base: string;
begin
  APath := '';
  if APlan = nil then Exit(False);
  Base := AName;
  if Pos('lib', Base) <> 1 then Base := 'lib' + Base;
  for I := 0 to High(APlan.SearchDirectories) do
  begin
    Candidate := IncludeTrailingPathDelimiter(APlan.SearchDirectories[I].Path) +
      Base + '.so';
    if FileExists(Candidate) then
    begin
      APath := Candidate;
      Exit(True);
    end;
    Candidate := IncludeTrailingPathDelimiter(APlan.SearchDirectories[I].Path) +
      Base + '.a';
    if FileExists(Candidate) then
    begin
      APath := Candidate;
      Exit(True);
    end;
  end;
  Result := False;
end;

function CanDirectLink(APlan: TLinkPlan; out AReason: string): Boolean;
var
  I: LongInt;
begin
  AReason := '';
  if APlan = nil then
  begin
    AReason := 'nil link plan';
    Exit(False);
  end;
  if APlan.OutputKind in [lokSharedObject, lokStaticArchive] then
  begin
    AReason := 'shared-object and archive production are not complete';
    Exit(False);
  end;
  if Length(APlan.Inputs) > 1 then
  begin
    AReason := 'multi-object relocation resolution is not complete';
    Exit(False);
  end;
  for I := 0 to High(APlan.DynamicSymbols) do
    if APlan.DynamicSymbols[I].VersionName <> '' then
    begin
      AReason := 'symbol-version relocation is not complete';
      Exit(False);
    end;
  if (Length(APlan.DynamicSymbols) > 0) and
     not TargetHasCapability(APlan.Target, tcDynamicELF) then
  begin
    AReason := 'target has no dynamic ELF writer';
    Exit(False);
  end;
  Result := True;
end;

function LinkPlanText(APlan: TLinkPlan): string;
var
  Lines: TStringList;
  I: LongInt;
begin
  if APlan = nil then Exit('<nil link plan>');
  Lines := TStringList.Create;
  try
    Lines.Add('link plan');
    Lines.Add('  target: ' + APlan.Target.Triple);
    Lines.Add('  kind: ' + LinkOutputKindName(APlan.OutputKind));
    Lines.Add('  output: ' + APlan.OutputFile);
    Lines.Add('  entry: ' + APlan.EntrySymbol);
    Lines.Add('  interpreter: ' + APlan.Interpreter);
    Lines.Add('  position independent: ' + BoolToStr(APlan.PositionIndependent, True));
    Lines.Add('  relro: ' + BoolToStr(APlan.Relro, True));
    Lines.Add('  non-executable stack: ' + BoolToStr(APlan.NoExecStack, True));
    for I := 0 to High(APlan.SearchDirectories) do
      Lines.Add('  search: ' + APlan.SearchDirectories[I].Path + ' (' +
        APlan.SearchDirectories[I].Origin + ')');
    for I := 0 to High(APlan.Inputs) do
      Lines.Add('  input: ' + LinkInputKindName(APlan.Inputs[I].Kind) +
        ' ' + APlan.Inputs[I].FileName);
    for I := 0 to High(APlan.NeededLibraries) do
      Lines.Add('  needed: ' + APlan.NeededLibraries[I]);
    for I := 0 to High(APlan.DynamicSymbols) do
      Lines.Add('  dynamic symbol: ' + APlan.DynamicSymbols[I].Name);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
