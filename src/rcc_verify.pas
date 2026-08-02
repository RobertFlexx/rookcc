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

function PointerInStack(const AStack: TPointerArray; AValue: Pointer): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(AStack) do
    if AStack[I] = AValue then Exit(True);
  Result := False;
end;

procedure PushPointer(var AStack: TPointerArray; AValue: Pointer);
var
  N: LongInt;
begin
  N := Length(AStack);
  SetLength(AStack, N + 1);
  AStack[N] := AValue;
end;

procedure PopPointer(var AStack: TPointerArray);
begin
  if Length(AStack) > 0 then SetLength(AStack, Length(AStack) - 1);
end;

procedure VerifyExpr(E: TExpr; var AStack: TPointerArray; ADepth: LongInt);
var
  I: LongInt;
begin
  if E = nil then Exit;
  if ADepth > 4096 then
    RaiseCompileError(E.Pos, 'internal error: expression nesting exceeds 4096 nodes');
  if PointerInStack(AStack, Pointer(E)) then
    RaiseCompileError(E.Pos, 'internal error: cyclic expression tree');
  PushPointer(AStack, Pointer(E));
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
  VerifyExpr(E.Left, AStack, ADepth + 1);
  VerifyExpr(E.Right, AStack, ADepth + 1);
  VerifyExpr(E.Third, AStack, ADepth + 1);
  for I := 0 to High(E.Args) do
    VerifyExpr(E.Args[I], AStack, ADepth + 1);
  PopPointer(AStack);
end;

procedure VerifyStmt(S: TStmt; var AStmtStack, AExprStack: TPointerArray;
  ADepth: LongInt);
var
  I: LongInt;
begin
  if S = nil then Exit;
  if ADepth > 4096 then
    RaiseCompileError(S.Pos, 'internal error: statement nesting exceeds 4096 nodes');
  if PointerInStack(AStmtStack, Pointer(S)) then
    RaiseCompileError(S.Pos, 'internal error: cyclic statement tree');
  PushPointer(AStmtStack, Pointer(S));
  if (S.InitStmt = S) or (S.Body = S) or (S.ElseBody = S) then
    RaiseCompileError(S.Pos, 'internal error: self-referential statement');
  VerifyExpr(S.Expr, AExprStack, 0);
  VerifyExpr(S.Expr2, AExprStack, 0);
  VerifyStmt(S.InitStmt, AStmtStack, AExprStack, ADepth + 1);
  VerifyStmt(S.Body, AStmtStack, AExprStack, ADepth + 1);
  VerifyStmt(S.ElseBody, AStmtStack, AExprStack, ADepth + 1);
  for I := 0 to High(S.Children) do
    VerifyStmt(S.Children[I], AStmtStack, AExprStack, ADepth + 1);
  for I := 0 to High(S.AsmOutputs) do
    VerifyExpr(S.AsmOutputs[I].Expr, AExprStack, 0);
  for I := 0 to High(S.AsmInputs) do
    VerifyExpr(S.AsmInputs[I].Expr, AExprStack, 0);
  PopPointer(AStmtStack);
end;

procedure VerifyProgram(AProgram: TProgram; const APhase: string);
var
  I: LongInt;
  StmtStack, ExprStack: TPointerArray;
begin
  if AProgram = nil then
    raise ERCCError.Create('rcc: internal error: nil program during ' + APhase);
  SetLength(StmtStack, 0);
  SetLength(ExprStack, 0);
  for I := 0 to High(AProgram.Functions) do
  begin
    if AProgram.Functions[I] = nil then
      raise ERCCError.Create('rcc: internal error: nil function during ' + APhase);
    if AProgram.Functions[I].Name = '' then
      RaiseCompileError(AProgram.Functions[I].Pos,
        'internal error: function has no name during ' + APhase);
    if not AProgram.Functions[I].IsPrototype then
      VerifyStmt(AProgram.Functions[I].Body, StmtStack, ExprStack, 0);
  end;
  for I := 0 to High(AProgram.Globals) do
    if AProgram.Globals[I] = nil then
      raise ERCCError.Create('rcc: internal error: nil global during ' + APhase);
end;

end.
