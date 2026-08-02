unit rcc_paths;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, rcc_types, rcc_build;

procedure AppendUniquePath(var APaths: rcc_types.TStringArray; const APath: string);
procedure AppendPathList(var APaths: rcc_types.TStringArray; const AValue: string);
function ExecutableDirectory: string;
function DiscoverResourceDirectory(const AExplicit, ASysroot: string): string;
procedure AddDefaultIncludePaths(var AOptions: TCompilerOptions);
function SearchDirectoriesText(const AOptions: TCompilerOptions): string;

implementation

uses
  rcc_arch, rcc_library_resolver;

procedure AppendUniquePath(var APaths: rcc_types.TStringArray; const APath: string);
var
  I, N: LongInt;
  P: string;
begin
  if Trim(APath) = '' then Exit;
  P := ExpandFileName(APath);
  for I := 0 to High(APaths) do
    if APaths[I] = P then Exit;
  N := Length(APaths);
  SetLength(APaths, N + 1);
  APaths[N] := P;
end;

procedure AppendPathList(var APaths: rcc_types.TStringArray; const AValue: string);
var
  I, StartPos: LongInt;
  Item: string;
begin
  StartPos := 1;
  for I := 1 to Length(AValue) + 1 do
    if (I > Length(AValue)) or (AValue[I] = ':') then
    begin
      Item := Copy(AValue, StartPos, I - StartPos);
      if Item <> '' then AppendUniquePath(APaths, Item);
      StartPos := I + 1;
    end;
end;

function ExecutableDirectory: string;
var
  P: string;
begin
  P := ParamStr(0);
  if P = '' then P := '.';
  Result := ExtractFileDir(ExpandFileName(P));
end;

function IsResourceDirectory(const APath: string): Boolean;
begin
  Result := DirectoryExists(IncludeTrailingPathDelimiter(APath) + 'include') and
    FileExists(IncludeTrailingPathDelimiter(APath) + 'include/rcc.h');
end;

function DiscoverResourceDirectory(const AExplicit, ASysroot: string): string;
var
  ExeDir, Root, EnvDir: string;
  Candidates: array[0..10] of string;
  I: LongInt;
begin
  if (AExplicit <> '') and IsResourceDirectory(AExplicit) then
    Exit(ExpandFileName(AExplicit));

  EnvDir := GetEnvironmentVariable('ROOKCC_RESOURCE_DIR');
  if (EnvDir <> '') and IsResourceDirectory(EnvDir) then
    Exit(ExpandFileName(EnvDir));
  EnvDir := GetEnvironmentVariable('ROOKCC_HOME');
  if (EnvDir <> '') and IsResourceDirectory(EnvDir) then
    Exit(ExpandFileName(EnvDir));

  ExeDir := ExecutableDirectory;
  Root := ExpandFileName(IncludeTrailingPathDelimiter(ExeDir) + '..');




  Candidates[0] := Root;
  Candidates[1] := IncludeTrailingPathDelimiter(Root) + 'share/rcc';
  Candidates[2] := IncludeTrailingPathDelimiter(Root) + 'lib/rcc';
  Candidates[3] := IncludeTrailingPathDelimiter(Root) +
    'share/rcc/' + RCCVersion;
  Candidates[4] := IncludeTrailingPathDelimiter(Root) +
    'lib/rcc/' + RCCVersion;
  Candidates[5] := IncludeTrailingPathDelimiter(ExeDir) + 'resources';
  Candidates[6] := IncludeTrailingPathDelimiter(GetCurrentDir);
  Candidates[7] := IncludeTrailingPathDelimiter(GetCurrentDir) + 'share/rcc';
  Candidates[8] := RCCDefaultPrefix + '/share/rcc';
  Candidates[9] := '/usr/local/share/rcc';
  Candidates[10] := '/usr/share/rcc';

  if ASysroot <> '' then
  begin
    EnvDir := IncludeTrailingPathDelimiter(ASysroot) + 'usr/share/rcc';
    if IsResourceDirectory(EnvDir) then Exit(ExpandFileName(EnvDir));
  end;

  for I := Low(Candidates) to High(Candidates) do
    if IsResourceDirectory(Candidates[I]) then
      Exit(ExpandFileName(Candidates[I]));
  Result := '';
end;

procedure AddDefaultIncludePaths(var AOptions: TCompilerOptions);
var
  ResourceDir, EnvPaths, SysrootPath, Root, MultiArch: string;
begin
  if AOptions.NoStdInc then Exit;
  ResourceDir := DiscoverResourceDirectory(AOptions.ResourceDir,
    AOptions.Sysroot);
  if ResourceDir <> '' then
  begin
    AOptions.ResourceDir := ResourceDir;
    AppendUniquePath(AOptions.SystemIncludePaths,
      IncludeTrailingPathDelimiter(ResourceDir) + 'include');
  end;

  MultiArch := TargetMultiArchName(GetTargetOrRaise(AOptions.TargetTriple));

  if AOptions.Sysroot <> '' then
  begin
    Root := ExcludeTrailingPathDelimiter(ExpandFileName(AOptions.Sysroot));
    SysrootPath := Root + '/usr/include/rcc';
    if DirectoryExists(SysrootPath) then
      AppendUniquePath(AOptions.SystemIncludePaths, SysrootPath);
    AppendUniquePath(AOptions.SystemIncludePaths, Root + '/usr/local/include');
    AppendUniquePath(AOptions.SystemIncludePaths,
      Root + '/usr/include/' + MultiArch);
    AppendUniquePath(AOptions.SystemIncludePaths, Root + '/usr/include');
  end
  else if MultiArch = 'x86_64-linux-gnu' then
  begin
    AppendUniquePath(AOptions.SystemIncludePaths, '/usr/local/include');
    AppendUniquePath(AOptions.SystemIncludePaths,
      '/usr/include/x86_64-linux-gnu');
    AppendUniquePath(AOptions.SystemIncludePaths, '/usr/include');
  end;

  EnvPaths := GetEnvironmentVariable('CPATH');
  if EnvPaths <> '' then AppendPathList(AOptions.IncludePaths, EnvPaths);
  EnvPaths := GetEnvironmentVariable('C_INCLUDE_PATH');
  if EnvPaths <> '' then AppendPathList(AOptions.SystemIncludePaths, EnvPaths);
  EnvPaths := GetEnvironmentVariable('ROOKCC_INCLUDE_PATH');
  if EnvPaths <> '' then AppendPathList(AOptions.SystemIncludePaths, EnvPaths);
end;

function SearchDirectoriesText(const AOptions: TCompilerOptions): string;
var
  Lines: TStringList;
  LibraryDirectories: TLibraryStringArray;
  Target: TTargetDescriptor;
  I: LongInt;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('install: ' + AOptions.ResourceDir);
    Lines.Add('programs: ' + ExecutableDirectory);
    Lines.Add('headers:');
    for I := 0 to High(AOptions.QuoteIncludePaths) do
      Lines.Add('  quote ' + AOptions.QuoteIncludePaths[I]);
    for I := 0 to High(AOptions.IncludePaths) do
      Lines.Add('  user  ' + AOptions.IncludePaths[I]);
    for I := 0 to High(AOptions.SystemIncludePaths) do
      Lines.Add('  system ' + AOptions.SystemIncludePaths[I]);
    Lines.Add('libraries:');
    Target := GetTargetOrRaise(AOptions.TargetTriple);
    BuildLibrarySearchDirectories(AOptions.LibraryPaths, AOptions.Sysroot,
      TargetMultiArchName(Target), Target.Architecture = archX86_64,
      LibraryDirectories);
    for I := 0 to High(LibraryDirectories) do
      Lines.Add('  ' + LibraryDirectories[I]);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
