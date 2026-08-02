unit rcc_verify;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;

procedure VerifyProgram(AProgram: TProgram; const APhase: string);

implementation

uses
  SysUtils;

type
  TPointerArray = array of Pointer;

function PointerInStack(const AStack: TPointerArray; ACount: LongInt;
  AValue: Pointer): Boolean;
var
  I: LongInt;
begin
  for I := 0 to ACount - 1 do
    if AStack[I] = AValue then Exit(True);
  Result := False;
end;

procedure VerifyExpr(E: TExpr; var AStack: TPointerArray;
  var ACount: LongInt; ADepth: LongInt);
var
  I: LongInt;
begin
  if E = nil then Exit;
  if ADepth > 4096 then
    RaiseCompileError(E.Pos, 'internal error: expression nesting exceeds 4096 nodes');
  if PointerInStack(AStack, ACount, Pointer(E)) then
    RaiseCompileError(E.Pos, 'internal error: cyclic expression tree');
  AStack[ACount] := Pointer(E);
  Inc(ACount);
  if (E.Left = E) or (E.Right = E) or (E.Third = E) then
    RaiseCompileError(E.Pos, 'internal error: self-referential expression');
  if E.Kind = ekCall then
  begin
    if (E.Text = '') and (E.Left = nil) then
      RaiseCompileError(E.Pos,
        'internal error: indirect call expression has no callee');
    if (E.Text <> '') and (E.Left = nil) then
      RaiseCompileError(E.Pos,
        'internal error: direct call expression has no callee designator');
  end;
  VerifyExpr(E.Left, AStack, ACount, ADepth + 1);
  VerifyExpr(E.Right, AStack, ACount, ADepth + 1);
  VerifyExpr(E.Third, AStack, ACount, ADepth + 1);
  for I := 0 to High(E.Args) do
    VerifyExpr(E.Args[I], AStack, ACount, ADepth + 1);
  Dec(ACount);
end;

procedure VerifyStmt(S: TStmt; var AStmtStack, AExprStack: TPointerArray;
  var AStmtCount, AExprCount: LongInt; ADepth: LongInt);
var
  I: LongInt;
begin
  if S = nil then Exit;
  if ADepth > 4096 then
    RaiseCompileError(S.Pos, 'internal error: statement nesting exceeds 4096 nodes');
  if PointerInStack(AStmtStack, AStmtCount, Pointer(S)) then
    RaiseCompileError(S.Pos, 'internal error: cyclic statement tree');
  AStmtStack[AStmtCount] := Pointer(S);
  Inc(AStmtCount);
  if (S.InitStmt = S) or (S.Body = S) or (S.ElseBody = S) then
    RaiseCompileError(S.Pos, 'internal error: self-referential statement');
  VerifyExpr(S.Expr, AExprStack, AExprCount, 0);
  VerifyExpr(S.Expr2, AExprStack, AExprCount, 0);
  VerifyStmt(S.InitStmt, AStmtStack, AExprStack, AStmtCount, AExprCount,
    ADepth + 1);
  VerifyStmt(S.Body, AStmtStack, AExprStack, AStmtCount, AExprCount,
    ADepth + 1);
  VerifyStmt(S.ElseBody, AStmtStack, AExprStack, AStmtCount, AExprCount,
    ADepth + 1);
  for I := 0 to High(S.Children) do
    VerifyStmt(S.Children[I], AStmtStack, AExprStack, AStmtCount,
      AExprCount, ADepth + 1);
  for I := 0 to High(S.AsmOutputs) do
    VerifyExpr(S.AsmOutputs[I].Expr, AExprStack, AExprCount, 0);
  for I := 0 to High(S.AsmInputs) do
    VerifyExpr(S.AsmInputs[I].Expr, AExprStack, AExprCount, 0);
  Dec(AStmtCount);
end;

procedure VerifyProgram(AProgram: TProgram; const APhase: string);
var
  I: LongInt;
  StmtStack, ExprStack: TPointerArray;
  StmtCount, ExprCount: LongInt;
begin
  if AProgram = nil then
    raise ERCCError.Create('rcc: internal error: nil program during ' + APhase);
  SetLength(StmtStack, 4096);
  SetLength(ExprStack, 4096);
  StmtCount := 0;
  ExprCount := 0;
  for I := 0 to High(AProgram.Functions) do
  begin
    if AProgram.Functions[I] = nil then
      raise ERCCError.Create('rcc: internal error: nil function during ' + APhase);
    if AProgram.Functions[I].Name = '' then
      RaiseCompileError(AProgram.Functions[I].Pos,
        'internal error: function has no name during ' + APhase);
    if not AProgram.Functions[I].IsPrototype then
      VerifyStmt(AProgram.Functions[I].Body, StmtStack, ExprStack,
        StmtCount, ExprCount, 0);
  end;
  for I := 0 to High(AProgram.Globals) do
    if AProgram.Globals[I] = nil then
      raise ERCCError.Create('rcc: internal error: nil global during ' + APhase);
end;

end.
