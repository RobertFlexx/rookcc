unit rcc_warnings;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;

procedure AnalyzeWarnings(AProgram: TProgram; const AOptions: TCompilerOptions);

implementation

uses
  SysUtils;

type
  TTrackedName = record
    Name: string;
    Pos: TSourcePos;
    UseCount: LongInt;
    IsParameter: Boolean;
    SuppressUnused: Boolean;
  end;
  TTrackedNameArray = array of TTrackedName;

function WarningIsDisabled(const AOptions: TCompilerOptions;
  const AOption: string): Boolean;
var
  I: LongInt;
  Name: string;
begin
  Name := LowerCase(AOption);
  if Copy(Name, 1, 2) = '-w' then Delete(Name, 1, 2);
  for I := 0 to High(AOptions.DisabledWarnings) do
    if LowerCase(AOptions.DisabledWarnings[I]) = Name then Exit(True);
  Result := False;
end;

procedure EmitWarning(const APos: TSourcePos; const AMessage, AOption: string;
  const AOptions: TCompilerOptions; var ACount: LongInt);
begin
  if WarningIsDisabled(AOptions, AOption) then Exit;
  Inc(ACount);
  if APos.FileName <> '' then
    WriteLn(StdErr, APos.FileName, ':', APos.Line, ':', APos.Column,
      ': warning: ', AMessage, ' [', AOption, ']')
  else
    WriteLn(StdErr, 'warning: ', AMessage, ' [', AOption, ']');
end;

procedure AddTrackedName(var ANames: TTrackedNameArray; const AName: string;
  const APos: TSourcePos; AIsParameter, ASuppressUnused: Boolean);
var
  N: LongInt;
begin
  if AName = '' then Exit;
  N := Length(ANames);
  SetLength(ANames, N + 1);
  ANames[N].Name := AName;
  ANames[N].Pos := APos;
  ANames[N].UseCount := 0;
  ANames[N].IsParameter := AIsParameter;
  ANames[N].SuppressUnused := ASuppressUnused;
end;

procedure CountNameUse(var ANames: TTrackedNameArray; const AName: string);
var
  I: LongInt;
begin
  { Search backwards so a use is charged to the most recently declared name.
    This is intentionally conservative: it avoids false unused warnings when
    nested scopes shadow an outer declaration. }
  for I := High(ANames) downto 0 do
    if ANames[I].Name = AName then
    begin
      Inc(ANames[I].UseCount);
      Exit;
    end;
end;

procedure WalkExpr(E: TExpr; var ANames: TTrackedNameArray);
var
  I: LongInt;
begin
  if E = nil then Exit;
  if E.Kind = ekVariable then CountNameUse(ANames, E.Text);
  WalkExpr(E.Left, ANames);
  WalkExpr(E.Right, ANames);
  WalkExpr(E.Third, ANames);
  for I := 0 to High(E.Args) do WalkExpr(E.Args[I], ANames);
end;

procedure CollectNamesAndUses(S: TStmt; var ANames: TTrackedNameArray);
var
  I: LongInt;
begin
  if S = nil then Exit;
  if S.Kind = skDecl then AddTrackedName(ANames, S.Name, S.Pos, False,
    S.CType.SuppressUnusedWarning);
  WalkExpr(S.Expr, ANames);
  WalkExpr(S.Expr2, ANames);
  CollectNamesAndUses(S.InitStmt, ANames);
  CollectNamesAndUses(S.Body, ANames);
  CollectNamesAndUses(S.ElseBody, ANames);
  for I := 0 to High(S.Children) do
    CollectNamesAndUses(S.Children[I], ANames);
  for I := 0 to High(S.AsmOutputs) do
    WalkExpr(S.AsmOutputs[I].Expr, ANames);
  for I := 0 to High(S.AsmInputs) do
    WalkExpr(S.AsmInputs[I].Expr, ANames);
end;

function StatementTerminates(S: TStmt): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(False);
  case S.Kind of
    skReturn, skGoto, skBreak, skContinue: Exit(True);
    skIf:
      Exit((S.ElseBody <> nil) and StatementTerminates(S.Body) and
        StatementTerminates(S.ElseBody));
    skBlock:
      begin
        for I := High(S.Children) downto 0 do
          if S.Children[I] <> nil then Exit(StatementTerminates(S.Children[I]));
        Exit(False);
      end;
  end;
  Result := False;
end;

procedure WarnUnreachable(S: TStmt; const AOptions: TCompilerOptions;
  var AWarningCount: LongInt);
var
  I: LongInt;
  Dead: Boolean;
begin
  if S = nil then Exit;
  if S.Kind = skBlock then
  begin
    Dead := False;
    for I := 0 to High(S.Children) do
    begin
      if S.Children[I] = nil then Continue;
      if S.Children[I].Kind in [skLabel, skCase, skDefault] then Dead := False;
      if Dead and not (S.Children[I].Kind in [skEmpty, skLabel, skCase, skDefault]) then
      begin
        EmitWarning(S.Children[I].Pos, 'statement is unreachable',
          '-Wunreachable-code', AOptions, AWarningCount);
        { One warning per dead region is enough. }
        Dead := False;
      end;
      WarnUnreachable(S.Children[I], AOptions, AWarningCount);
      if StatementTerminates(S.Children[I]) then Dead := True;
    end;
    Exit;
  end;
  WarnUnreachable(S.InitStmt, AOptions, AWarningCount);
  WarnUnreachable(S.Body, AOptions, AWarningCount);
  WarnUnreachable(S.ElseBody, AOptions, AWarningCount);
end;

procedure AnalyzeFunction(AFunction: TFunction; const AOptions: TCompilerOptions;
  var AWarningCount: LongInt);
var
  Names: TTrackedNameArray;
  I: LongInt;
begin
  if (AFunction = nil) or AFunction.IsPrototype or (AFunction.Body = nil) then Exit;
  SetLength(Names, 0);
  for I := 0 to High(AFunction.Params) do
    AddTrackedName(Names, AFunction.Params[I].Name, AFunction.Pos, True,
      AFunction.Params[I].CType.SuppressUnusedWarning);
  CollectNamesAndUses(AFunction.Body, Names);

  if AOptions.WarningLevel >= wlAll then
    for I := 0 to High(Names) do
      if (Names[I].UseCount = 0) and (Names[I].Name <> '') and
         not Names[I].SuppressUnused and (Names[I].Name[1] <> '_') and
         (not Names[I].IsParameter or (AOptions.WarningLevel >= wlExtra)) then
      begin
        if Names[I].IsParameter then
          EmitWarning(Names[I].Pos, 'unused parameter ''' + Names[I].Name + '''',
            '-Wunused-parameter', AOptions, AWarningCount)
        else
          EmitWarning(Names[I].Pos, 'unused variable ''' + Names[I].Name + '''',
            '-Wunused-variable', AOptions, AWarningCount);
      end;

  if AOptions.WarningLevel >= wlAll then
    WarnUnreachable(AFunction.Body, AOptions, AWarningCount);

  if (AFunction.Name <> 'main') and
     not ((AFunction.ReturnType.Kind = ctVoid) and
       (AFunction.ReturnType.PointerDepth = 0)) and
     not StatementTerminates(AFunction.Body) then
    EmitWarning(AFunction.Pos, 'control may reach the end of non-void function ''' +
      AFunction.Name + '''', '-Wreturn-type', AOptions, AWarningCount);
end;

procedure AnalyzeWarnings(AProgram: TProgram; const AOptions: TCompilerOptions);
var
  I, WarningCount: LongInt;
begin
  if AProgram = nil then Exit;
  WarningCount := 0;
  for I := 0 to High(AProgram.Functions) do
    AnalyzeFunction(AProgram.Functions[I], AOptions, WarningCount);
  if AOptions.WarningsAsErrors and (WarningCount > 0) then
    raise ERCCError.CreateFmt('error: treating %d warning(s) as errors',
      [WarningCount]);
end;

end.
