unit rcc_diag;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types;

function DiagnosticsUseColor(const AOptions: TCompilerOptions): Boolean;
procedure PrintDiagnostic(const AOptions: TCompilerOptions;
  const AMessage: string);
procedure PrintNote(const AOptions: TCompilerOptions; const AMessage: string);

implementation

uses
  Classes, BaseUnix;

function DiagnosticsUseColor(const AOptions: TCompilerOptions): Boolean;
var
  FileInfo: Stat;
begin
  if GetEnvironmentVariable('NO_COLOR') <> '' then Exit(False);
  case AOptions.ColorMode of
    cmAlways: Exit(True);
    cmNever: Exit(False);
  end;
  Result := (fpFStat(2, FileInfo) = 0) and fpS_ISCHR(FileInfo.st_mode);
end;

function ParseLocation(const AMessage: string; out AFileName: string;
  out ALine, AColumn: LongInt; out ARest: string): Boolean;
var
  P1, P2, P3: LongInt;
  LineText, ColumnText: string;
begin
  Result := False;
  AFileName := '';
  ALine := 0;
  AColumn := 0;
  ARest := AMessage;
  P1 := Pos(':', AMessage);
  if P1 <= 1 then Exit;
  P2 := Pos(':', Copy(AMessage, P1 + 1, MaxInt));
  if P2 = 0 then Exit;
  Inc(P2, P1);
  P3 := Pos(':', Copy(AMessage, P2 + 1, MaxInt));
  if P3 = 0 then Exit;
  Inc(P3, P2);
  LineText := Copy(AMessage, P1 + 1, P2 - P1 - 1);
  ColumnText := Copy(AMessage, P2 + 1, P3 - P2 - 1);
  if not TryStrToInt(LineText, ALine) then Exit;
  if not TryStrToInt(ColumnText, AColumn) then Exit;
  AFileName := Copy(AMessage, 1, P1 - 1);
  ARest := TrimLeft(Copy(AMessage, P3 + 1, MaxInt));
  Result := True;
end;

function LoadSourceLine(const AFileName: string; ALine: LongInt): string;
var
  Lines: TStringList;
begin
  Result := '';
  if (ALine <= 0) or (not FileExists(AFileName)) then Exit;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);
    if ALine <= Lines.Count then Result := Lines[ALine - 1];
  finally
    Lines.Free;
  end;
end;

procedure PrintDiagnostic(const AOptions: TCompilerOptions;
  const AMessage: string);
var
  FileName, Rest, SourceLine, Prefix, Caret: string;
  LineNo, ColumnNo: LongInt;
  UseColor: Boolean;
begin
  UseColor := DiagnosticsUseColor(AOptions);
  if not ParseLocation(AMessage, FileName, LineNo, ColumnNo, Rest) then
  begin
    if UseColor then
      WriteLn(StdErr, #27'[1;31m', AMessage, #27'[0m')
    else
      WriteLn(StdErr, AMessage);
    Exit;
  end;

  Prefix := FileName + ':' + IntToStr(LineNo) + ':' + IntToStr(ColumnNo) + ': ';
  if UseColor then
    WriteLn(StdErr, #27'[1m', Prefix, #27'[1;31m', Rest, #27'[0m')
  else
    WriteLn(StdErr, Prefix, Rest);

  SourceLine := LoadSourceLine(FileName, LineNo);
  if SourceLine <> '' then
  begin
    WriteLn(StdErr, '  ', SourceLine);
    if ColumnNo < 1 then ColumnNo := 1;
    Caret := StringOfChar(' ', ColumnNo + 1) + '^';
    if UseColor then
      WriteLn(StdErr, #27'[1;32m', Caret, #27'[0m')
    else
      WriteLn(StdErr, Caret);
  end;
end;

procedure PrintNote(const AOptions: TCompilerOptions; const AMessage: string);
begin
  if DiagnosticsUseColor(AOptions) then
    WriteLn(StdErr, #27'[1;36mnote: ', AMessage, #27'[0m')
  else
    WriteLn(StdErr, 'note: ', AMessage);
end;

end.
