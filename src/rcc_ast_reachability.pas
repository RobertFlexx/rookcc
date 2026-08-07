unit rcc_ast_reachability;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;

type
  TReachabilityStats = record
    FunctionsRemoved: QWord;
    GlobalsRemoved: QWord;
    DisabledByInlineAsm: Boolean;
  end;

procedure RunStaticReachability(AProgram: TProgram; AEnabled: Boolean;
  out AStats: TReachabilityStats);

implementation

uses
  rcc_typeops;

type
  TBoolArray = array of Boolean;

function HasInlineAsm(S: TStmt): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(False);
  if S.Kind = skAsm then Exit(True);
  if HasInlineAsm(S.InitStmt) or HasInlineAsm(S.Body) or
     HasInlineAsm(S.ElseBody) then Exit(True);
  for I := 0 to High(S.Children) do
    if HasInlineAsm(S.Children[I]) then Exit(True);
  Result := False;
end;

procedure MarkFunction(AProgram: TProgram; AIndex: LongInt;
  var AFunctions, AGlobals: TBoolArray); forward;
procedure MarkGlobal(AProgram: TProgram; AIndex: LongInt;
  var AFunctions, AGlobals: TBoolArray); forward;

procedure ScanExpr(E: TExpr; AProgram: TProgram;
  var AFunctions, AGlobals: TBoolArray);
var
  I, Index: LongInt;
begin
  if E = nil then Exit;
  if (E.Kind = ekCall) and (E.Text <> '') then
  begin
    Index := AProgram.FindFunctionIndex(E.Text);
    if Index >= 0 then MarkFunction(AProgram, Index, AFunctions, AGlobals);
  end;
  if (E.Kind = ekVariable) or E.IsFunctionDesignator then
  begin
    Index := AProgram.FindFunctionIndex(E.Text);
    if Index >= 0 then MarkFunction(AProgram, Index, AFunctions, AGlobals);
    Index := AProgram.FindGlobalIndex(E.Text);
    if Index >= 0 then MarkGlobal(AProgram, Index, AFunctions, AGlobals);
  end;
  ScanExpr(E.Left, AProgram, AFunctions, AGlobals);
  ScanExpr(E.Right, AProgram, AFunctions, AGlobals);
  ScanExpr(E.Third, AProgram, AFunctions, AGlobals);
  for I := 0 to High(E.Args) do
    ScanExpr(E.Args[I], AProgram, AFunctions, AGlobals);
end;

procedure ScanStmt(S: TStmt; AProgram: TProgram;
  var AFunctions, AGlobals: TBoolArray);
var
  I: LongInt;
begin
  if S = nil then Exit;
  ScanExpr(S.Expr, AProgram, AFunctions, AGlobals);
  ScanExpr(S.Expr2, AProgram, AFunctions, AGlobals);
  ScanStmt(S.InitStmt, AProgram, AFunctions, AGlobals);
  ScanStmt(S.Body, AProgram, AFunctions, AGlobals);
  ScanStmt(S.ElseBody, AProgram, AFunctions, AGlobals);
  for I := 0 to High(S.Children) do
    ScanStmt(S.Children[I], AProgram, AFunctions, AGlobals);
  for I := 0 to High(S.AsmOutputs) do
    ScanExpr(S.AsmOutputs[I].Expr, AProgram, AFunctions, AGlobals);
  for I := 0 to High(S.AsmInputs) do
    ScanExpr(S.AsmInputs[I].Expr, AProgram, AFunctions, AGlobals);
end;

procedure MarkFunction(AProgram: TProgram; AIndex: LongInt;
  var AFunctions, AGlobals: TBoolArray);
begin
  if (AIndex < 0) or (AIndex >= Length(AFunctions)) or
     AFunctions[AIndex] then Exit;
  AFunctions[AIndex] := True;
  if not AProgram.Functions[AIndex].IsPrototype then
    ScanStmt(AProgram.Functions[AIndex].Body, AProgram,
      AFunctions, AGlobals);
end;

procedure MarkGlobal(AProgram: TProgram; AIndex: LongInt;
  var AFunctions, AGlobals: TBoolArray);
begin
  if (AIndex < 0) or (AIndex >= Length(AGlobals)) or AGlobals[AIndex] then Exit;
  AGlobals[AIndex] := True;
  ScanExpr(AProgram.Globals[AIndex].Initializer, AProgram,
    AFunctions, AGlobals);
end;

procedure RunStaticReachability(AProgram: TProgram; AEnabled: Boolean;
  out AStats: TReachabilityStats);
var
  LiveFunctions, LiveGlobals: TBoolArray;
  I, WriteIndex: LongInt;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  if (AProgram = nil) or not AEnabled then Exit;
  for I := 0 to High(AProgram.Functions) do
    if not AProgram.Functions[I].IsPrototype and
       HasInlineAsm(AProgram.Functions[I].Body) then
    begin
      AStats.DisabledByInlineAsm := True;
      Exit;
    end;

  SetLength(LiveFunctions, Length(AProgram.Functions));
  SetLength(LiveGlobals, Length(AProgram.Globals));
  for I := 0 to High(AProgram.Functions) do
    if not AProgram.Functions[I].IsStatic or
       (AProgram.Functions[I].Name = 'main') or
       AProgram.Functions[I].ReturnType.PreserveForLinker then
      MarkFunction(AProgram, I, LiveFunctions, LiveGlobals);
  for I := 0 to High(AProgram.Globals) do
    if not AProgram.Globals[I].IsStatic or
       AProgram.Globals[I].CType.IsVolatile or
       AProgram.Globals[I].CType.PreserveForLinker then
      MarkGlobal(AProgram, I, LiveFunctions, LiveGlobals);

  WriteIndex := 0;
  for I := 0 to High(AProgram.Functions) do
  begin
    if AProgram.Functions[I].IsStatic and not LiveFunctions[I] and
       not AProgram.Functions[I].ReturnType.PreserveForLinker then
    begin
      AProgram.Functions[I].Free;
      Inc(AStats.FunctionsRemoved);
      Continue;
    end;
    AProgram.Functions[WriteIndex] := AProgram.Functions[I];
    Inc(WriteIndex);
  end;
  SetLength(AProgram.Functions, WriteIndex);

  WriteIndex := 0;
  for I := 0 to High(AProgram.Globals) do
  begin
    if AProgram.Globals[I].IsStatic and not LiveGlobals[I] and
       not AProgram.Globals[I].CType.IsVolatile and
       not AProgram.Globals[I].CType.PreserveForLinker then
    begin
      AProgram.Globals[I].Free;
      Inc(AStats.GlobalsRemoved);
      Continue;
    end;
    AProgram.Globals[WriteIndex] := AProgram.Globals[I];
    Inc(WriteIndex);
  end;
  SetLength(AProgram.Globals, WriteIndex);
  AProgram.RebuildNameIndexes;
end;

end.
