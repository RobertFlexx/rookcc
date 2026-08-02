unit rcc_native_linker;

{$mode objfpc}{$H+}

interface

uses
  rcc_types, rcc_arch;

function NeedsNativePlatformLink(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor): Boolean;
function NativePlatformLinkerName(const ATarget: TTargetDescriptor): string;
procedure LinkNativeExecutable(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor; const AGeneratedObject: string);

implementation

uses
  SysUtils, BaseUnix;

procedure AppendArgument(var AArguments: rcc_types.TStringArray;
  const AValue: string);
var
  N: LongInt;
begin
  N := Length(AArguments);
  SetLength(AArguments, N + 1);
  AArguments[N] := AValue;
end;

function IsExecutableFile(const AFileName: string): Boolean;
begin
  Result := FileExists(AFileName) and
    (fpAccess(PChar(AFileName), X_OK) = 0);
end;

function ResolveExecutable(const AName: string): string;
var
  SearchPath, DirectoryName, Candidate: string;
  StartAt, FinishAt: LongInt;
begin
  Result := '';
  if AName = '' then Exit;
  if Pos(DirectorySeparator, AName) > 0 then
  begin
    Candidate := ExpandFileName(AName);
    if IsExecutableFile(Candidate) then Result := Candidate;
    Exit;
  end;

  SearchPath := GetEnvironmentVariable('PATH');
  StartAt := 1;
  while StartAt <= Length(SearchPath) + 1 do
  begin
    FinishAt := StartAt;
    while (FinishAt <= Length(SearchPath)) and
      (SearchPath[FinishAt] <> ':') do Inc(FinishAt);
    DirectoryName := Copy(SearchPath, StartAt, FinishAt - StartAt);
    if DirectoryName = '' then DirectoryName := GetCurrentDir;
    Candidate := IncludeTrailingPathDelimiter(DirectoryName) + AName;
    if IsExecutableFile(Candidate) then Exit(ExpandFileName(Candidate));
    StartAt := FinishAt + 1;
  end;
end;

function NativePlatformLinkerName(const ATarget: TTargetDescriptor): string;
begin
  Result := GetEnvironmentVariable('RCC_PLATFORM_LINKER');
  if Result <> '' then Exit;
  case ATarget.OperatingSystem of
    osDarwin: Result := '/usr/bin/clang';
    osLinux, osFreeBSD, osOpenBSD, osNetBSD: Result := '/usr/bin/cc';
  else
    Result := 'cc';
  end;
end;

function FindNativePlatformLinker(const ATarget: TTargetDescriptor): string;
var
  Requested: string;
begin
  Requested := NativePlatformLinkerName(ATarget);
  Result := ResolveExecutable(Requested);
  if (Result = '') and (GetEnvironmentVariable('RCC_PLATFORM_LINKER') = '') then
  begin
    if ATarget.OperatingSystem = osDarwin then
      Result := ResolveExecutable('clang')
    else
      Result := ResolveExecutable('cc');
  end;
  if Result <> '' then Exit;
  if GetEnvironmentVariable('RCC_PLATFORM_LINKER') <> '' then
    raise ERCCError.Create('error: RCC_PLATFORM_LINKER is not executable: ' +
      Requested);
  if ATarget.OperatingSystem = osDarwin then
    raise ERCCError.Create(
      'error: native macOS linking requires Apple command line tools; ' +
      'install them or set RCC_PLATFORM_LINKER to a compiler driver');
  raise ERCCError.Create('error: native ' +
    OperatingSystemName(ATarget.OperatingSystem) +
    ' linking requires /usr/bin/cc or RCC_PLATFORM_LINKER');
end;

function NeedsNativePlatformLink(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor): Boolean;
begin
  Result := (AOptions.EmitMode = emExecutable) and
    not AOptions.Freestanding and TargetMatchesNativeHost(ATarget) and
    ((ATarget.OperatingSystem = osDarwin) or TargetIsBSD(ATarget) or
     ((ATarget.OperatingSystem = osLinux) and
      (ATarget.Architecture <> archX86_64)));
end;

function DarwinArchitectureName(AArchitecture: TArchitecture): string;
begin
  case AArchitecture of
    archX86_64: Result := 'x86_64';
    archAArch64: Result := 'arm64';
  else
    raise ERCCError.Create(
      'error: native macOS linking supports x86-64 and arm64');
  end;
end;

function DisplayArgument(const AValue: string): string;
begin
  if (AValue <> '') and
     (Pos(' ', AValue) = 0) and (Pos(#9, AValue) = 0) and
     (Pos('''', AValue) = 0) then Exit(AValue);
  Result := '''' + StringReplace(AValue, '''', '''\''''', [rfReplaceAll]) + '''';
end;

function CommandText(const AExecutable: string;
  const AArguments: rcc_types.TStringArray): string;
var
  I: LongInt;
begin
  Result := DisplayArgument(AExecutable);
  for I := 0 to High(AArguments) do
    Result := Result + ' ' + DisplayArgument(AArguments[I]);
end;

function RunChildProcess(const AExecutable: string;
  const AArguments: rcc_types.TStringArray): LongInt;
var
  Storage: array of RawByteString;
  ArgValues: array of PChar;
  Child, Waited: TPid;
  Status, I: LongInt;
begin
  SetLength(Storage, Length(AArguments) + 1);
  SetLength(ArgValues, Length(Storage) + 1);
  Storage[0] := RawByteString(AExecutable);
  ArgValues[0] := PChar(Storage[0]);
  for I := 0 to High(AArguments) do
  begin
    Storage[I + 1] := RawByteString(AArguments[I]);
    ArgValues[I + 1] := PChar(Storage[I + 1]);
  end;
  ArgValues[High(ArgValues)] := nil;

  Flush(Output);
  Flush(StdErr);
  Child := fpFork;
  if Child < 0 then
    raise ERCCError.Create('error: unable to create native linker process');
  if Child = 0 then
  begin
    fpExecV(PChar(Storage[0]), @ArgValues[0]);
    fpExit(127);
  end;

  repeat
    Waited := fpWaitPid(Child, @Status, 0);
  until (Waited = Child) or (Waited < 0);
  if Waited < 0 then
    raise ERCCError.Create('error: unable to wait for native linker process');
  if WIFEXITED(Status) then Exit(WEXITSTATUS(Status));
  if WIFSIGNALED(Status) then Exit(128 + WTERMSIG(Status));
  Result := 1;
end;

procedure AddLinkerValue(var AArguments: rcc_types.TStringArray;
  const AOption, AValue: string);
begin
  AppendArgument(AArguments, '-Xlinker');
  AppendArgument(AArguments, AOption);
  AppendArgument(AArguments, '-Xlinker');
  AppendArgument(AArguments, AValue);
end;

procedure LinkNativeExecutable(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor; const AGeneratedObject: string);
var
  Executable, LibraryName: string;
  Arguments: rcc_types.TStringArray;
  I, ExitCode: LongInt;
begin
  if not NeedsNativePlatformLink(AOptions, ATarget) then
    raise ERCCError.Create(
      'internal error: native platform linker selected for a non-native target');
  Executable := FindNativePlatformLinker(ATarget);
  SetLength(Arguments, 0);

  if ATarget.OperatingSystem = osDarwin then
  begin
    AppendArgument(Arguments, '-arch');
    AppendArgument(Arguments, DarwinArchitectureName(ATarget.Architecture));
  end;
  if AOptions.Sysroot <> '' then
  begin
    if ATarget.OperatingSystem = osDarwin then
    begin
      AppendArgument(Arguments, '-isysroot');
      AppendArgument(Arguments, AOptions.Sysroot);
    end
    else
      AppendArgument(Arguments, '--sysroot=' + AOptions.Sysroot);
  end;
  if AOptions.StaticLink then AppendArgument(Arguments, '-static');
  if AOptions.NoDefaultLibraries then
    AppendArgument(Arguments, '-nodefaultlibs');
  if AOptions.PositionIndependent then AppendArgument(Arguments, '-pie');

  if AGeneratedObject <> '' then AppendArgument(Arguments, AGeneratedObject);
  for I := 0 to High(AOptions.ObjectFiles) do
    AppendArgument(Arguments, AOptions.ObjectFiles[I]);
  for I := 0 to High(AOptions.LibraryPaths) do
    AppendArgument(Arguments, '-L' + AOptions.LibraryPaths[I]);
  for I := 0 to High(AOptions.RPaths) do
    AddLinkerValue(Arguments, '-rpath', AOptions.RPaths[I]);
  if AOptions.DynamicLinker <> '' then
    AddLinkerValue(Arguments, '--dynamic-linker', AOptions.DynamicLinker);
  if AOptions.BindNow then AddLinkerValue(Arguments, '-z', 'now');
  for I := 0 to High(AOptions.Libraries) do
  begin
    LibraryName := AOptions.Libraries[I];
    if (Length(LibraryName) > 1) and (LibraryName[1] = '@') then
      AppendArgument(Arguments, Copy(LibraryName, 2, MaxInt))
    else
      AppendArgument(Arguments, '-l' + LibraryName);
  end;
  AppendArgument(Arguments, '-o');
  AppendArgument(Arguments, AOptions.OutputFile);

  if AOptions.Verbose then
    WriteLn(StdErr, 'link   ', CommandText(Executable, Arguments));
  ExitCode := RunChildProcess(Executable, Arguments);
  if ExitCode <> 0 then
    raise ERCCError.Create('error: native platform linker failed with exit status ' +
      IntToStr(ExitCode));
end;

end.
