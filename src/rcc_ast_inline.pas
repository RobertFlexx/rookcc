unit rcc_ast_inline;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;

type
  TASTInlineStats = record
    CallsInlined: QWord;
    CandidatesRejected: QWord;
    PassesRun: QWord;
  end;

procedure RunASTInlining(AProgram: TProgram; ALevel, ASizeLevel: LongInt;
  out AStats: TASTInlineStats);

implementation

uses
  SysUtils, rcc_typeops;

type
  TExprVector = array of TExpr;
  TIntVector = array of LongInt;

function CloneExpr(E: TExpr): TExpr;
var
  I: LongInt;
begin
  if E = nil then Exit(nil);
  Result := TExpr.Create(E.Kind, E.Pos);
  Result.IntValue := E.IntValue;
  Result.FloatValue := E.FloatValue;
  Result.Text := E.Text;
  Result.UnaryOp := E.UnaryOp;
  Result.BinaryOp := E.BinaryOp;
  Result.AssignOp := E.AssignOp;
  Result.CType := E.CType;
  Result.OperationType := E.OperationType;
  Result.IsLValue := E.IsLValue;
  Result.IsFunctionDesignator := E.IsFunctionDesignator;
  Result.IsBitField := E.IsBitField;
  Result.Designator := E.Designator;
  Result.HasIndexDesignator := E.HasIndexDesignator;
  Result.IndexDesignator := E.IndexDesignator;
  Result.BitOffset := E.BitOffset;
  Result.BitWidth := E.BitWidth;
  Result.BitStorageSize := E.BitStorageSize;
  Result.Left := CloneExpr(E.Left);
  Result.Right := CloneExpr(E.Right);
  Result.Third := CloneExpr(E.Third);
  SetLength(Result.Args, Length(E.Args));
  for I := 0 to High(E.Args) do Result.Args[I] := CloneExpr(E.Args[I]);
end;

function ExprNodeCount(E: TExpr): LongInt;
var
  I: LongInt;
begin
  if E = nil then Exit(0);
  Result := 1 + ExprNodeCount(E.Left) + ExprNodeCount(E.Right) +
    ExprNodeCount(E.Third);
  for I := 0 to High(E.Args) do Inc(Result, ExprNodeCount(E.Args[I]));
end;

function ParameterIndex(F: TFunction; const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(F.Params) do
    if F.Params[I].Name = AName then Exit(I);
  Result := -1;
end;

function IntegerScalarType(const AType: TCType): Boolean;
begin
  Result := IsIntegerType(AType) or IsPointerType(AType);
end;

function SafeInlineExpression(E: TExpr; F: TFunction): Boolean;
begin
  if E = nil then Exit(True);
  if E.CType.IsVolatile then Exit(False);
  case E.Kind of
    ekInteger, ekNullptr: Exit(True);
    ekVariable:
      Exit(ParameterIndex(F, E.Text) >= 0);
    ekUnary, ekCast:
      Exit(SafeInlineExpression(E.Left, F));
    ekBinary, ekComma:
      Exit(SafeInlineExpression(E.Left, F) and
        SafeInlineExpression(E.Right, F));
    ekConditional:
      Exit(SafeInlineExpression(E.Left, F) and
        SafeInlineExpression(E.Right, F) and
        SafeInlineExpression(E.Third, F));
  end;
  Result := False;
end;

function SafeArgument(E: TExpr): Boolean;
begin
  if E = nil then Exit(True);
  if E.CType.IsVolatile or IsFloatingType(E.CType) or
     IsAggregateType(E.CType) then Exit(False);
  case E.Kind of
    ekInteger, ekNullptr: Exit(True);
    ekVariable: Exit(not E.CType.IsVolatile);
    ekUnary, ekCast: Exit(SafeArgument(E.Left));
    ekBinary, ekComma:
      Exit(SafeArgument(E.Left) and SafeArgument(E.Right));
    ekConditional:
      Exit(SafeArgument(E.Left) and SafeArgument(E.Right) and
        SafeArgument(E.Third));
  else
    Result := False;
  end;
end;

function CastExpression(E: TExpr; const AType: TCType): TExpr;
begin
  if E = nil then Exit(nil);
  if TypesEqual(E.CType, AType) then Exit(E);
  Result := TExpr.Create(ekCast, E.Pos);
  Result.Left := E;
  Result.CType := AType;
  Result.OperationType := AType;
end;

function SubstituteExpr(E: TExpr; F: TFunction;
  const AValues: TExprVector): TExpr;
var
  I, ParamIndex: LongInt;
begin
  if E = nil then Exit(nil);
  if E.Kind = ekVariable then
  begin
    ParamIndex := ParameterIndex(F, E.Text);
    if (ParamIndex >= 0) and (ParamIndex < Length(AValues)) then
      Exit(CloneExpr(AValues[ParamIndex]));
  end;
  Result := TExpr.Create(E.Kind, E.Pos);
  Result.IntValue := E.IntValue;
  Result.FloatValue := E.FloatValue;
  Result.Text := E.Text;
  Result.UnaryOp := E.UnaryOp;
  Result.BinaryOp := E.BinaryOp;
  Result.AssignOp := E.AssignOp;
  Result.CType := E.CType;
  Result.OperationType := E.OperationType;
  Result.IsLValue := E.IsLValue;
  Result.IsFunctionDesignator := E.IsFunctionDesignator;
  Result.IsBitField := E.IsBitField;
  Result.Designator := E.Designator;
  Result.HasIndexDesignator := E.HasIndexDesignator;
  Result.IndexDesignator := E.IndexDesignator;
  Result.BitOffset := E.BitOffset;
  Result.BitWidth := E.BitWidth;
  Result.BitStorageSize := E.BitStorageSize;
  Result.Left := SubstituteExpr(E.Left, F, AValues);
  Result.Right := SubstituteExpr(E.Right, F, AValues);
  Result.Third := SubstituteExpr(E.Third, F, AValues);
  SetLength(Result.Args, Length(E.Args));
  for I := 0 to High(E.Args) do
    Result.Args[I] := SubstituteExpr(E.Args[I], F, AValues);
end;

function AssignmentBinaryOp(AOp: TAssignOp; out AResult: TBinaryOp): Boolean;
begin
  Result := True;
  case AOp of
    aoAdd: AResult := boAdd;
    aoSub: AResult := boSub;
    aoMul: AResult := boMul;
    aoDiv: AResult := boDiv;
    aoMod: AResult := boMod;
    aoBitAnd: AResult := boBitAnd;
    aoBitOr: AResult := boBitOr;
    aoBitXor: AResult := boBitXor;
    aoShiftLeft: AResult := boShiftLeft;
    aoShiftRight: AResult := boShiftRight;
  else
    Result := False;
  end;
end;

function CandidateBody(F: TFunction; out AStatements: TStmtArray): Boolean;
var
  I, N: LongInt;
begin
  SetLength(AStatements, 0);
  if (F = nil) or F.IsPrototype or (F.Body = nil) then Exit(False);
  if F.Body.Kind = skBlock then
  begin
    for I := 0 to High(F.Body.Children) do
      if F.Body.Children[I].Kind <> skEmpty then
      begin
        N := Length(AStatements);
        SetLength(AStatements, N + 1);
        AStatements[N] := F.Body.Children[I];
      end;
  end
  else
  begin
    SetLength(AStatements, 1);
    AStatements[0] := F.Body;
  end;
  Result := Length(AStatements) > 0;
end;

function InlineCost(F: TFunction): LongInt;
var
  Statements: TStmtArray;
  I: LongInt;
begin
  Result := High(LongInt);
  if not CandidateBody(F, Statements) then Exit;
  Result := 0;
  for I := 0 to High(Statements) do
  begin
    if Statements[I].Kind = skReturn then
      Inc(Result, ExprNodeCount(Statements[I].Expr))
    else if Statements[I].Kind = skExpr then
      Inc(Result, ExprNodeCount(Statements[I].Expr))
    else
      Exit(High(LongInt));
  end;
end;

function BuildInlineExpression(ACall: TExpr; F: TFunction;
  ANodeBudget, AKnownCost: LongInt): TExpr;
var
  Values: TExprVector;
  Statements: TStmtArray;
  I, ParamIndex: LongInt;
  StatementExpr, RHS, NewValue: TExpr;
  BinaryOp: TBinaryOp;
begin
  Result := nil;
  if (ACall = nil) or (F = nil) or
     (Length(ACall.Args) <> Length(F.Params)) then Exit;
  if not IntegerScalarType(F.ReturnType) then Exit;
  if AKnownCost > ANodeBudget then Exit;
  for I := 0 to High(F.Params) do
  begin
    if (F.Params[I].Name = '') or
       not IntegerScalarType(F.Params[I].CType) or
       F.Params[I].CType.IsVolatile or
       not SafeArgument(ACall.Args[I]) then Exit;
  end;
  if not CandidateBody(F, Statements) then Exit;

  SetLength(Values, Length(F.Params));
  try
    for I := 0 to High(F.Params) do
      Values[I] := CastExpression(CloneExpr(ACall.Args[I]), F.Params[I].CType);

    for I := 0 to High(Statements) do
    begin
      if Statements[I].Kind = skReturn then
      begin
        if I <> High(Statements) then Exit;
        if not SafeInlineExpression(Statements[I].Expr, F) then Exit;
        Result := SubstituteExpr(Statements[I].Expr, F, Values);
        Result := CastExpression(Result, ACall.CType);
        if ExprNodeCount(Result) > ANodeBudget * 3 then
        begin
          Result.Free;
          Result := nil;
        end;
        Exit;
      end;

      if Statements[I].Kind <> skExpr then Exit;
      StatementExpr := Statements[I].Expr;
      if (StatementExpr = nil) or (StatementExpr.Kind <> ekAssign) or
         (StatementExpr.Left = nil) or
         (StatementExpr.Left.Kind <> ekVariable) then Exit;
      ParamIndex := ParameterIndex(F, StatementExpr.Left.Text);
      if ParamIndex < 0 then Exit;
      if not SafeInlineExpression(StatementExpr.Right, F) then Exit;
      RHS := SubstituteExpr(StatementExpr.Right, F, Values);
      if StatementExpr.AssignOp = aoAssign then
        NewValue := RHS
      else
      begin
        if not AssignmentBinaryOp(StatementExpr.AssignOp, BinaryOp) then
        begin
          RHS.Free;
          Exit;
        end;
        NewValue := TExpr.Create(ekBinary, StatementExpr.Pos);
        NewValue.BinaryOp := BinaryOp;
        NewValue.Left := CloneExpr(Values[ParamIndex]);
        NewValue.Right := RHS;
        NewValue.CType := F.Params[ParamIndex].CType;
        NewValue.OperationType := StatementExpr.OperationType;
      end;
      NewValue := CastExpression(NewValue, F.Params[ParamIndex].CType);
      Values[ParamIndex].Free;
      Values[ParamIndex] := NewValue;
    end;
  finally
    for I := 0 to High(Values) do Values[I].Free;
  end;
end;

procedure CountCallsExpr(E: TExpr; AProgram: TProgram; var ACounts: TIntVector);
var
  I, FunctionIndex: LongInt;
begin
  if E = nil then Exit;
  if (E.Kind = ekCall) and (E.Text <> '') then
  begin
    FunctionIndex := AProgram.FindFunctionIndex(E.Text);
    if FunctionIndex >= 0 then Inc(ACounts[FunctionIndex]);
  end;
  CountCallsExpr(E.Left, AProgram, ACounts);
  CountCallsExpr(E.Right, AProgram, ACounts);
  CountCallsExpr(E.Third, AProgram, ACounts);
  for I := 0 to High(E.Args) do CountCallsExpr(E.Args[I], AProgram, ACounts);
end;

procedure CountCallsStmt(S: TStmt; AProgram: TProgram; var ACounts: TIntVector);
var
  I: LongInt;
begin
  if S = nil then Exit;
  CountCallsExpr(S.Expr, AProgram, ACounts);
  CountCallsExpr(S.Expr2, AProgram, ACounts);
  CountCallsStmt(S.InitStmt, AProgram, ACounts);
  CountCallsStmt(S.Body, AProgram, ACounts);
  CountCallsStmt(S.ElseBody, AProgram, ACounts);
  for I := 0 to High(S.Children) do CountCallsStmt(S.Children[I], AProgram, ACounts);
  for I := 0 to High(S.AsmOutputs) do
    CountCallsExpr(S.AsmOutputs[I].Expr, AProgram, ACounts);
  for I := 0 to High(S.AsmInputs) do
    CountCallsExpr(S.AsmInputs[I].Expr, AProgram, ACounts);
end;

function HasIntegerConstantArgument(E: TExpr): Boolean;
var
  I: LongInt;
begin
  Result := False;
  if E = nil then Exit;
  for I := 0 to High(E.Args) do
    if (E.Args[I] <> nil) and (E.Args[I].Kind in [ekInteger, ekNullptr]) then
      Exit(True);
end;

procedure InlineExpr(var E: TExpr; AProgram: TProgram;
  const ACallCounts, AInlineCosts: TIntVector;
  const ACurrentFunction: string;
  ALevel, ASizeLevel, ANodeBudget: LongInt; var AStats: TASTInlineStats);
var
  I, CalleeIndex, Cost: LongInt;
  Callee: TFunction;
  Replacement, Old: TExpr;
begin
  if E = nil then Exit;
  InlineExpr(E.Left, AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
    ALevel, ASizeLevel, ANodeBudget, AStats);
  InlineExpr(E.Right, AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
    ALevel, ASizeLevel, ANodeBudget, AStats);
  InlineExpr(E.Third, AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
    ALevel, ASizeLevel, ANodeBudget, AStats);
  for I := 0 to High(E.Args) do
    InlineExpr(E.Args[I], AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
      ALevel, ASizeLevel, ANodeBudget, AStats);

  if (E.Kind <> ekCall) or (E.Text = '') or
     (E.Text = ACurrentFunction) then Exit;
  Callee := AProgram.FindFunction(E.Text);
  if (Callee = nil) or not Callee.IsStatic or Callee.IsPrototype or
     Callee.IsVariadic then Exit;
  CalleeIndex := AProgram.FindFunctionIndex(E.Text);
  if (CalleeIndex >= 0) and (CalleeIndex < Length(AInlineCosts)) then
    Cost := AInlineCosts[CalleeIndex]
  else
    Cost := InlineCost(Callee);
  if (Cost = High(LongInt)) or (Cost > ANodeBudget) then
  begin
    Inc(AStats.CandidatesRejected);
    Exit;
  end;
  { -O1 keeps compile-time and code-growth cost deliberately low.  Shared
    helpers are left as calls unless they are genuinely tiny. }
  if (ALevel = 1) and (CalleeIndex >= 0) and
     (ACallCounts[CalleeIndex] > 1) and (Cost > 8) then
  begin
    Inc(AStats.CandidatesRejected);
    Exit;
  end;
  { Size modes inline shared helpers only when the expression is still small
    enough to amortize the call sequence.  A one-call helper is always a size
    candidate because the subsequent reachability pass can delete its body. }
  if (ASizeLevel > 0) and (CalleeIndex >= 0) and
     (ACallCounts[CalleeIndex] > 1) and
     (Cost > 10 - ASizeLevel * 2) and
     not HasIntegerConstantArgument(E) then
  begin
    Inc(AStats.CandidatesRejected);
    Exit;
  end;
  Replacement := BuildInlineExpression(E, Callee, ANodeBudget, Cost);
  if Replacement = nil then
  begin
    Inc(AStats.CandidatesRejected);
    Exit;
  end;
  Old := E;
  E := Replacement;
  Old.Free;
  Inc(AStats.CallsInlined);
end;

procedure InlineStmt(S: TStmt; AProgram: TProgram;
  const ACallCounts, AInlineCosts: TIntVector;
  const ACurrentFunction: string;
  ALevel, ASizeLevel, ANodeBudget: LongInt; var AStats: TASTInlineStats);
var
  I: LongInt;
begin
  if S = nil then Exit;
  InlineExpr(S.Expr, AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
    ALevel, ASizeLevel, ANodeBudget, AStats);
  InlineExpr(S.Expr2, AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
    ALevel, ASizeLevel, ANodeBudget, AStats);
  InlineStmt(S.InitStmt, AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
    ALevel, ASizeLevel, ANodeBudget, AStats);
  InlineStmt(S.Body, AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
    ALevel, ASizeLevel, ANodeBudget, AStats);
  InlineStmt(S.ElseBody, AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
    ALevel, ASizeLevel, ANodeBudget, AStats);
  for I := 0 to High(S.Children) do
    InlineStmt(S.Children[I], AProgram, ACallCounts, AInlineCosts, ACurrentFunction,
      ALevel, ASizeLevel, ANodeBudget, AStats);
  for I := 0 to High(S.AsmOutputs) do
    InlineExpr(S.AsmOutputs[I].Expr, AProgram, ACallCounts,
      AInlineCosts, ACurrentFunction, ALevel, ASizeLevel, ANodeBudget, AStats);
  for I := 0 to High(S.AsmInputs) do
    InlineExpr(S.AsmInputs[I].Expr, AProgram, ACallCounts,
      AInlineCosts, ACurrentFunction, ALevel, ASizeLevel, ANodeBudget, AStats);
end;

procedure RunASTInlining(AProgram: TProgram; ALevel, ASizeLevel: LongInt;
  out AStats: TASTInlineStats);
var
  CallCounts, InlineCosts: TIntVector;
  I, NodeBudget: LongInt;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  if (AProgram = nil) or (ALevel < 1) then Exit;
  { Constant-specialized helpers can become smaller than an out-of-line call
    after folding (rotates and masks are common examples), so size modes need
    enough temporary AST budget to expose that simplification. }
  if ASizeLevel >= 2 then NodeBudget := 24
  else if ASizeLevel = 1 then NodeBudget := 32
  else if ALevel >= 3 then NodeBudget := 96
  else if ALevel = 2 then NodeBudget := 48
  else NodeBudget := 20;

  SetLength(CallCounts, Length(AProgram.Functions));
  SetLength(InlineCosts, Length(AProgram.Functions));
  for I := 0 to High(AProgram.Functions) do
  begin
    InlineCosts[I] := InlineCost(AProgram.Functions[I]);
    if not AProgram.Functions[I].IsPrototype then
      CountCallsStmt(AProgram.Functions[I].Body, AProgram, CallCounts);
  end;
  for I := 0 to High(AProgram.Globals) do
    CountCallsExpr(AProgram.Globals[I].Initializer, AProgram, CallCounts);

  for I := 0 to High(AProgram.Functions) do
    if not AProgram.Functions[I].IsPrototype then
      InlineStmt(AProgram.Functions[I].Body, AProgram, CallCounts,
        InlineCosts, AProgram.Functions[I].Name, ALevel, ASizeLevel,
        NodeBudget, AStats);
  AStats.PassesRun := 1;
end;

end.
