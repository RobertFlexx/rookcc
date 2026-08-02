unit rcc_driver;

{$mode objfpc}{$H+}

interface

function RunCompiler: LongInt;

implementation

uses
  SysUtils, BaseUnix, rcc_types, rcc_cli, rcc_session, rcc_diag;

function RunCompiledProgram(const AFileName: string;
  const AArguments: TStringArray): LongInt;
var
  Executable: string;
  Storage: array of RawByteString;
  ArgValues: array of PChar;
  Child, Waited: TPid;
  Status, I: LongInt;
begin
  Executable := ExpandFileName(AFileName);
  SetLength(Storage, Length(AArguments) + 1);
  SetLength(ArgValues, Length(Storage) + 1);
  Storage[0] := RawByteString(Executable);
  ArgValues[0] := PChar(Storage[0]);
  for I := 0 to High(AArguments) do
  begin
    Storage[I + 1] := RawByteString(AArguments[I]);
    ArgValues[I + 1] := PChar(Storage[I + 1]);
  end;
  ArgValues[High(ArgValues)] := nil;

  Child := fpFork;
  if Child < 0 then
    raise ERCCError.Create('error: unable to create process for -run');
  if Child = 0 then
  begin
    fpExecV(PChar(Storage[0]), @ArgValues[0]);
    fpExit(127);
  end;

  repeat
    Waited := fpWaitPid(Child, @Status, 0);
  until (Waited = Child) or (Waited < 0);
  if Waited < 0 then
    raise ERCCError.Create('error: unable to wait for -run program');
  if WIFEXITED(Status) then Exit(WEXITSTATUS(Status));
  if WIFSIGNALED(Status) then Exit(128 + WTERMSIG(Status));
  Result := 1;
end;

function RunCompiler: LongInt;
var
  Options: TCompilerOptions;
  TemporaryOutput: Boolean;
begin
  Result := 1;
  TemporaryOutput := False;
  try
    if not ParseOptions(Options) then Exit(0);
    if Options.RunAfterCompile and (Options.OutputFile = 'a.out') then
    begin
      Options.OutputFile := GetTempFileName(GetTempDir(False), 'rcc');
      TemporaryOutput := True;
    end;
    Result := CompileWithOptions(Options);
    if (Result = 0) and Options.RunAfterCompile then
      Result := RunCompiledProgram(Options.OutputFile, Options.RunArguments);
  except
    on E: ERCCError do
    begin
      PrintDiagnostic(Options, E.Message);
      Result := 1;
    end;
    on E: Exception do
    begin
      PrintDiagnostic(Options, 'rcc: internal error: ' + E.Message);
      Result := 2;
    end;
  end;
  if TemporaryOutput and FileExists(Options.OutputFile) then
    DeleteFile(Options.OutputFile);
end;

end.
