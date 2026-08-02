unit rcc_opt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, rcc_types;

type
  TOptimizationStats = record
    ConstantsFolded: QWord;
    AlgebraicSimplifications: QWord;
    BranchesSimplified: QWord;
    DeadStatementsRemoved: QWord;
    ExpressionsVisited: QWord;
    StatementsVisited: QWord;
    PassesRun: QWord;
    ConstantsPropagated: QWord;
    LoopsUnrolled: QWord;
    StrengthReductions: QWord;
    ExpressionsHoisted: QWord;
  end;

procedure OptimizeProgram(AProgram: TProgram; ALevel: LongInt;
  AOptimizeSize: Boolean; out AStats: TOptimizationStats);
function DumpProgramIR(AProgram: TProgram): string;

implementation

uses
  rcc_typeops, rcc_ast_opt2;

function IsInteger(E: TExpr; out V: Int64): Boolean;
begin
  Result := (E <> nil) and (E.Kind = ekInteger);
  if Result then V := E.IntValue else V := 0;
end;

function IsPure(E: TExpr): Boolean;
begin
  if E = nil then Exit(True);
  case E.Kind of
    ekInteger, ekFloat, ekString: Result := True;
    ekVariable: Result := not E.CType.IsVolatile;
    ekUnary, ekAddress: Result := IsPure(E.Left);
    ekBinary: Result := IsPure(E.Left) and IsPure(E.Right);
    ekConditional: Result := IsPure(E.Left) and IsPure(E.Right) and IsPure(E.Third);
  else
    Result := False;
  end;
end;

function ArithmeticShiftRight(A: Int64; Shift: LongInt): Int64;
begin
  Shift := Shift and 63;
  if Shift = 0 then Exit(A);
  if A >= 0 then Result := A shr Shift
  else Result := not ((not A) shr Shift);
end;

function Int64FromBits(AValue: QWord): Int64; inline;
begin


  Move(AValue, Result, SizeOf(Result));
end;

function WrappedAdd(A, B: Int64): Int64; inline;
var
  Bits: QWord;
begin
  {$Q-}
  Bits := QWord(A) + QWord(B);
  {$Q+}
  Result := Int64FromBits(Bits);
end;

function WrappedSubtract(A, B: Int64): Int64; inline;
var
  Bits: QWord;
begin
  {$Q-}
  Bits := QWord(A) - QWord(B);
  {$Q+}
  Result := Int64FromBits(Bits);
end;

function WrappedMultiply(A, B: Int64): Int64; inline;
var
  Bits: QWord;
begin
  {$Q-}
  Bits := QWord(A) * QWord(B);
  {$Q+}
  Result := Int64FromBits(Bits);
end;

function EvalBinary(Op: TBinaryOp; A, B: Int64; AUnsigned: Boolean;
  out V: Int64): Boolean;
begin
  Result := True;
  case Op of
    boAdd: V := WrappedAdd(A, B);
    boSub: V := WrappedSubtract(A, B);
    boMul: V := WrappedMultiply(A, B);
    boDiv:
      if B = 0 then Exit(False)
      else if AUnsigned then V := Int64FromBits(QWord(A) div QWord(B))
      else if (A = Low(Int64)) and (B = -1) then Exit(False)
      else V := A div B;
    boMod:
      if B = 0 then Exit(False)
      else if AUnsigned then V := Int64FromBits(QWord(A) mod QWord(B))
      else if (A = Low(Int64)) and (B = -1) then Exit(False)
      else V := A mod B;
    boShiftLeft: V := Int64FromBits(QWord(A) shl (B and 63));
    boShiftRight:
      if AUnsigned then V := Int64FromBits(QWord(A) shr (B and 63))
      else V := ArithmeticShiftRight(A, B and 63);
    boLess:
      if AUnsigned then V := Ord(QWord(A) < QWord(B)) else V := Ord(A < B);
    boLessEqual:
      if AUnsigned then V := Ord(QWord(A) <= QWord(B)) else V := Ord(A <= B);
    boGreater:
      if AUnsigned then V := Ord(QWord(A) > QWord(B)) else V := Ord(A > B);
    boGreaterEqual:
      if AUnsigned then V := Ord(QWord(A) >= QWord(B)) else V := Ord(A >= B);
    boEqual: V := Ord(A = B);
    boNotEqual: V := Ord(A <> B);
    boBitAnd: V := A and B;
    boBitXor: V := A xor B;
    boBitOr: V := A or B;
    boLogicalAnd: V := Ord((A <> 0) and (B <> 0));
    boLogicalOr: V := Ord((A <> 0) or (B <> 0));
    boComma: V := B;
  else
    Result := False;
  end;
end;

procedure ReplaceWithInteger(var E: TExpr; V: Int64; var Stats: TOptimizationStats);
var
  Old: TExpr;
  P: TSourcePos;
  ResultType: TCType;
begin
  Old := E;
  P := Old.Pos;
  ResultType := Old.CType;
  E := TExpr.Create(ekInteger, P);
  E.IntValue := V;


  E.CType := ResultType;
  Old.Free;
  Inc(Stats.ConstantsFolded);
end;

procedure ReplaceWithChild(var E: TExpr; Child: TExpr; var Stats: TOptimizationStats);
var
  Old, Other1, Other2: TExpr;
begin
  Old := E;
  Other1 := nil;
  Other2 := nil;
  if Child = Old.Left then
  begin
    Other1 := Old.Right;
    Other2 := Old.Third;
    Old.Left := nil;
    Old.Right := nil;
    Old.Third := nil;
  end
  else if Child = Old.Right then
  begin
    Other1 := Old.Left;
    Other2 := Old.Third;
    Old.Left := nil;
    Old.Right := nil;
    Old.Third := nil;
  end
  else if Child = Old.Third then
  begin
    Other1 := Old.Left;
    Other2 := Old.Right;
    Old.Left := nil;
    Old.Right := nil;
    Old.Third := nil;
  end;
  Other1.Free;
  Other2.Free;
  Old.Free;
  E := Child;
  Inc(Stats.AlgebraicSimplifications);
end;

procedure OptimizeExpr(var E: TExpr; Level: LongInt;
  var Stats: TOptimizationStats);
var
  I: LongInt;
  A, B, V: Int64;
  UnsignedOperation: Boolean;
  Chosen: TExpr;
begin
  if E = nil then Exit;
  Inc(Stats.ExpressionsVisited);
  OptimizeExpr(E.Left, Level, Stats);
  OptimizeExpr(E.Right, Level, Stats);
  OptimizeExpr(E.Third, Level, Stats);
  for I := 0 to High(E.Args) do OptimizeExpr(E.Args[I], Level, Stats);
  if Level <= 0 then Exit;

  case E.Kind of
    ekUnary:
      if IsInteger(E.Left, A) then
      begin
        case E.UnaryOp of
          uoPositive: V := A;
          uoNegative: V := WrappedSubtract(0, A);
          uoLogicalNot: V := Ord(A = 0);
          uoBitwiseNot: V := not A;
        end;
        ReplaceWithInteger(E, V, Stats);
      end;

    ekBinary:
      begin
        case E.BinaryOp of
          boShiftRight, boLess, boLessEqual, boGreater, boGreaterEqual:
            UnsignedOperation := E.OperationType.IsUnsigned;
        else
          UnsignedOperation := E.CType.IsUnsigned;
        end;
        if IsInteger(E.Left, A) and IsInteger(E.Right, B) then
        begin
          if IsIntegerType(E.OperationType) then
          begin
            A := ConvertIntegerValue(A, E.OperationType);
            if not (E.BinaryOp in [boShiftLeft, boShiftRight]) then
              B := ConvertIntegerValue(B, E.OperationType);
          end;
          if EvalBinary(E.BinaryOp, A, B, UnsignedOperation, V) then
          begin
            ReplaceWithInteger(E, V, Stats);
            Exit;
          end;
        end;
        if Level >= 2 then
        begin



          if IsInteger(E.Right, B) then
          begin
            case E.BinaryOp of
              boAdd, boSub, boBitOr, boBitXor:
                if B = 0 then begin ReplaceWithChild(E, E.Left, Stats); Exit; end;
              boMul:
                begin
                  if B = 1 then begin ReplaceWithChild(E, E.Left, Stats); Exit; end;
                  if (B = 0) and IsPure(E.Left) then
                  begin ReplaceWithInteger(E, 0, Stats); Exit; end;
                end;
              boDiv:
                if B = 1 then begin ReplaceWithChild(E, E.Left, Stats); Exit; end;
              boShiftLeft, boShiftRight:
                if B = 0 then begin ReplaceWithChild(E, E.Left, Stats); Exit; end;
              boBitAnd:
                begin
                  if B = -1 then begin ReplaceWithChild(E, E.Left, Stats); Exit; end;
                  if (B = 0) and IsPure(E.Left) then
                  begin ReplaceWithInteger(E, 0, Stats); Exit; end;
                end;
              boLogicalAnd:
                begin
                  if (B = 0) and IsPure(E.Left) then
                  begin ReplaceWithInteger(E, 0, Stats); Exit; end;
                end;
              boLogicalOr:
                begin
                  if (B <> 0) and IsPure(E.Left) then
                  begin ReplaceWithInteger(E, 1, Stats); Exit; end;
                end;
              boComma:
                if IsPure(E.Left) then begin ReplaceWithChild(E, E.Right, Stats); Exit; end;
            end;
          end;
          if IsInteger(E.Left, A) then
          begin
            case E.BinaryOp of
              boAdd, boBitOr, boBitXor:
                if A = 0 then begin ReplaceWithChild(E, E.Right, Stats); Exit; end;
              boMul:
                begin
                  if A = 1 then begin ReplaceWithChild(E, E.Right, Stats); Exit; end;
                  if (A = 0) and IsPure(E.Right) then
                  begin ReplaceWithInteger(E, 0, Stats); Exit; end;
                end;
              boBitAnd:
                begin
                  if A = -1 then begin ReplaceWithChild(E, E.Right, Stats); Exit; end;
                  if (A = 0) and IsPure(E.Right) then
                  begin ReplaceWithInteger(E, 0, Stats); Exit; end;
                end;
              boLogicalAnd:
                if A = 0 then begin ReplaceWithInteger(E, 0, Stats); Exit; end;
              boLogicalOr:
                if A <> 0 then begin ReplaceWithInteger(E, 1, Stats); Exit; end;
            end;
          end;
        end;
      end;

    ekConditional:
      if IsInteger(E.Left, A) then
      begin
        if A <> 0 then Chosen := E.Right else Chosen := E.Third;
        ReplaceWithChild(E, Chosen, Stats);
        Inc(Stats.BranchesSimplified);
      end;
  end;
end;

function StatementTerminates(S: TStmt): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(False);
  case S.Kind of
    skReturn, skBreak, skContinue, skGoto: Exit(True);
    skCase, skDefault: Exit(StatementTerminates(S.Body));
    skBlock:
      begin
        for I := High(S.Children) downto 0 do
          if S.Children[I].Kind <> skEmpty then
            Exit(StatementTerminates(S.Children[I]));
      end;
    skIf:
      Exit((S.ElseBody <> nil) and StatementTerminates(S.Body) and
        StatementTerminates(S.ElseBody));
  end;
  Result := False;
end;

procedure ReplaceStatementWithBranch(S: TStmt; Chosen: TStmt;
  var Stats: TOptimizationStats);
var
  Other: TStmt;
begin
  if Chosen = S.Body then Other := S.ElseBody else Other := S.Body;
  S.Expr.Free;
  S.Expr := nil;
  Other.Free;
  S.Body := nil;
  S.ElseBody := nil;
  SetLength(S.Children, 0);
  if Chosen = nil then
    S.Kind := skEmpty
  else
  begin
    S.Kind := skBlock;
    SetLength(S.Children, 1);
    S.Children[0] := Chosen;
  end;
  Inc(Stats.BranchesSimplified);
end;

procedure OptimizeStmt(S: TStmt; Level: LongInt; var Stats: TOptimizationStats);
var
  I, WriteIndex: LongInt;
  ConditionValue: Int64;
  Reachable: Boolean;
begin
  if S = nil then Exit;
  Inc(Stats.StatementsVisited);
  if (S.InitStmt = S) or (S.Body = S) or (S.ElseBody = S) then
    RaiseCompileError(S.Pos, 'internal error: cyclic statement tree');
  for I := 0 to High(S.Children) do
    if S.Children[I] = S then
      RaiseCompileError(S.Pos, 'internal error: cyclic statement tree');
  OptimizeExpr(S.Expr, Level, Stats);
  OptimizeExpr(S.Expr2, Level, Stats);
  OptimizeStmt(S.InitStmt, Level, Stats);
  OptimizeStmt(S.Body, Level, Stats);
  OptimizeStmt(S.ElseBody, Level, Stats);
  for I := 0 to High(S.Children) do OptimizeStmt(S.Children[I], Level, Stats);
  if S.Kind = skAsm then
  begin
    for I := 0 to High(S.AsmOutputs) do
      OptimizeExpr(S.AsmOutputs[I].Expr, Level, Stats);
    for I := 0 to High(S.AsmInputs) do
      OptimizeExpr(S.AsmInputs[I].Expr, Level, Stats);
  end;

  if Level >= 2 then
  begin
    if (S.Kind = skIf) and IsInteger(S.Expr, ConditionValue) then
    begin
      if ConditionValue <> 0 then
        ReplaceStatementWithBranch(S, S.Body, Stats)
      else
        ReplaceStatementWithBranch(S, S.ElseBody, Stats);
    end
    else if (S.Kind = skWhile) and IsInteger(S.Expr, ConditionValue) and
      (ConditionValue = 0) then
    begin
      S.Expr.Free;
      S.Expr := nil;
      S.Body.Free;
      S.Body := nil;
      S.Kind := skEmpty;
      Inc(Stats.BranchesSimplified);
    end
    else if (S.Kind = skExpr) and IsPure(S.Expr) then
    begin
      S.Expr.Free;
      S.Expr := nil;
      S.Kind := skEmpty;
      Inc(Stats.DeadStatementsRemoved);
    end;
  end;

  if (Level >= 2) and (S.Kind = skBlock) then
  begin




    WriteIndex := 0;
    Reachable := True;
    for I := 0 to High(S.Children) do
    begin
      if (not Reachable) and
        not (S.Children[I].Kind in [skCase, skDefault, skLabel]) then
      begin
        S.Children[I].Free;
        Inc(Stats.DeadStatementsRemoved);
        Continue;
      end;

      if not Reachable then Reachable := True;
      S.Children[WriteIndex] := S.Children[I];
      Inc(WriteIndex);
      if StatementTerminates(S.Children[I]) then Reachable := False;
    end;
    if WriteIndex < Length(S.Children) then
      SetLength(S.Children, WriteIndex);
  end;
end;

procedure AddPassStats(var ATotal: TOptimizationStats;
  const APass: TOptimizationStats);
begin
  Inc(ATotal.ConstantsFolded, APass.ConstantsFolded);
  Inc(ATotal.AlgebraicSimplifications, APass.AlgebraicSimplifications);
  Inc(ATotal.BranchesSimplified, APass.BranchesSimplified);
  Inc(ATotal.DeadStatementsRemoved, APass.DeadStatementsRemoved);
  Inc(ATotal.ExpressionsVisited, APass.ExpressionsVisited);
  Inc(ATotal.StatementsVisited, APass.StatementsVisited);
  Inc(ATotal.ConstantsPropagated, APass.ConstantsPropagated);
  Inc(ATotal.LoopsUnrolled, APass.LoopsUnrolled);
  Inc(ATotal.StrengthReductions, APass.StrengthReductions);
  Inc(ATotal.ExpressionsHoisted, APass.ExpressionsHoisted);
end;

function PassChanged(const AStats: TOptimizationStats): Boolean;
begin
  Result := (AStats.ConstantsFolded <> 0) or
    (AStats.AlgebraicSimplifications <> 0) or
    (AStats.BranchesSimplified <> 0) or
    (AStats.DeadStatementsRemoved <> 0);
end;

procedure OptimizeProgram(AProgram: TProgram; ALevel: LongInt;
  AOptimizeSize: Boolean; out AStats: TOptimizationStats);
var
  I, Pass, MaximumPasses: LongInt;
  PassStats: TOptimizationStats;
  AdvancedStats: TAdvancedASTOptStats;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  if AOptimizeSize and (ALevel < 2) then ALevel := 2;
  if ALevel <= 1 then MaximumPasses := 1
  else if ALevel = 2 then MaximumPasses := 3
  else MaximumPasses := 6;

  for Pass := 1 to MaximumPasses do
  begin
    FillChar(PassStats, SizeOf(PassStats), 0);
    for I := 0 to High(AProgram.Functions) do
      if not AProgram.Functions[I].IsPrototype then
        OptimizeStmt(AProgram.Functions[I].Body, ALevel, PassStats);
    AddPassStats(AStats, PassStats);
    Inc(AStats.PassesRun);
    if not PassChanged(PassStats) then Break;
  end;

  FillChar(AdvancedStats, SizeOf(AdvancedStats), 0);
  if ALevel >= 2 then RunASTPropagation(AProgram, ALevel, AdvancedStats);
  if ALevel >= 3 then RunASTLoopOptimization(AProgram, ALevel, AdvancedStats);
  AStats.ConstantsPropagated := AdvancedStats.ConstantsPropagated;
  AStats.LoopsUnrolled := AdvancedStats.LoopsUnrolled;
  AStats.StrengthReductions := AdvancedStats.StrengthReductions;
  AStats.ExpressionsHoisted := AdvancedStats.ExpressionsHoisted;
end;

function ExprText(E: TExpr): string;
var
  I: LongInt;
  Op: string;
begin
  if E = nil then Exit('');
  case E.Kind of
    ekInteger: Result := IntToStr(E.IntValue);
    ekTrap: Result := E.Text;
    ekFloat: Result := FloatToStr(E.FloatValue);
    ekString: Result := 'str(' + QuotedStr(E.Text) + ')';
    ekVariable: Result := '%' + E.Text;
    ekUnary:
      begin
        case E.UnaryOp of
          uoPositive: Op := '+';
          uoNegative: Op := '-';
          uoLogicalNot: Op := '!';
          uoBitwiseNot: Op := '~';
        end;
        Result := Op + ExprText(E.Left);
      end;
    ekBinary:
      begin
        case E.BinaryOp of
          boAdd: Op := 'add'; boSub: Op := 'sub'; boMul: Op := 'mul';
          boDiv: Op := 'div'; boMod: Op := 'mod';
          boShiftLeft: Op := 'shl'; boShiftRight: Op := 'shr';
          boLess: Op := 'lt'; boLessEqual: Op := 'le';
          boGreater: Op := 'gt'; boGreaterEqual: Op := 'ge';
          boEqual: Op := 'eq'; boNotEqual: Op := 'ne';
          boBitAnd: Op := 'and'; boBitXor: Op := 'xor'; boBitOr: Op := 'or';
          boLogicalAnd: Op := 'land'; boLogicalOr: Op := 'lor';
          boComma: Op := 'comma';
        end;
        Result := Op + '(' + ExprText(E.Left) + ', ' + ExprText(E.Right) + ')';
      end;
    ekAssign: Result := 'store(' + ExprText(E.Left) + ', ' + ExprText(E.Right) + ')';
    ekCall:
      begin
        if E.Text = '' then
          Result := 'call *' + ExprText(E.Left) + '('
        else
          Result := 'call @' + E.Text + '(';
        for I := 0 to High(E.Args) do
        begin
          if I > 0 then Result := Result + ', ';
          Result := Result + ExprText(E.Args[I]);
        end;
        Result := Result + ')';
      end;
    ekConditional: Result := 'select(' + ExprText(E.Left) + ', ' +
      ExprText(E.Right) + ', ' + ExprText(E.Third) + ')';
    ekAddress: Result := 'addr(' + ExprText(E.Left) + ')';
    ekDeref: Result := 'load(' + ExprText(E.Left) + ')';
    ekPreInc: Result := 'preinc(' + ExprText(E.Left) + ')';
    ekPreDec: Result := 'predec(' + ExprText(E.Left) + ')';
    ekPostInc: Result := 'postinc(' + ExprText(E.Left) + ')';
    ekPostDec: Result := 'postdec(' + ExprText(E.Left) + ')';
  end;
end;

procedure DumpStmt(S: TStmt; Lines: TStrings; Indent: LongInt);
var
  I: LongInt;
  P: string;
begin
  if S = nil then Exit;
  P := StringOfChar(' ', Indent);
  case S.Kind of
    skEmpty: Lines.Add(P + 'nop');
    skAsm: Lines.Add(P + 'asm ' + S.AsmTemplate);
    skExpr: Lines.Add(P + ExprText(S.Expr));
    skDecl:
      begin
        if S.Expr <> nil then Lines.Add(P + '%' + S.Name + ' = ' + ExprText(S.Expr))
        else Lines.Add(P + '%' + S.Name + ' = undef');
      end;
    skReturn: Lines.Add(P + 'ret ' + ExprText(S.Expr));
    skBlock: for I := 0 to High(S.Children) do DumpStmt(S.Children[I], Lines, Indent);
    skIf:
      begin
        Lines.Add(P + 'if ' + ExprText(S.Expr));
        DumpStmt(S.Body, Lines, Indent + 2);
        if S.ElseBody <> nil then
        begin
          Lines.Add(P + 'else');
          DumpStmt(S.ElseBody, Lines, Indent + 2);
        end;
      end;
    skWhile:
      begin
        Lines.Add(P + 'while ' + ExprText(S.Expr));
        DumpStmt(S.Body, Lines, Indent + 2);
      end;
    skDoWhile:
      begin
        Lines.Add(P + 'do');
        DumpStmt(S.Body, Lines, Indent + 2);
        Lines.Add(P + 'while ' + ExprText(S.Expr));
      end;
    skFor:
      begin
        Lines.Add(P + 'for');
        DumpStmt(S.InitStmt, Lines, Indent + 2);
        Lines.Add(P + 'cond ' + ExprText(S.Expr));
        DumpStmt(S.Body, Lines, Indent + 2);
        Lines.Add(P + 'post ' + ExprText(S.Expr2));
      end;
    skBreak: Lines.Add(P + 'break');
    skContinue: Lines.Add(P + 'continue');
    skSwitch:
      begin
        Lines.Add(P + 'switch ' + ExprText(S.Expr));
        DumpStmt(S.Body, Lines, Indent + 2);
      end;
    skCase:
      begin
        Lines.Add(P + 'case ' + IntToStr(S.CaseValue) + ':');
        DumpStmt(S.Body, Lines, Indent + 2);
      end;
    skDefault:
      begin
        Lines.Add(P + 'default:');
        DumpStmt(S.Body, Lines, Indent + 2);
      end;
    skGoto: Lines.Add(P + 'goto ' + S.Name);
    skLabel:
      begin
        Lines.Add(P + S.Name + ':');
        DumpStmt(S.Body, Lines, Indent + 2);
      end;
  end;
end;

function DumpProgramIR(AProgram: TProgram): string;
var
  Lines: TStringList;
  I, J: LongInt;
  F: TFunction;
  Header: string;
begin
  Lines := TStringList.Create;
  try
    for I := 0 to High(AProgram.Globals) do
      Lines.Add('global @' + AProgram.Globals[I].Name + ' = ' +
        IntToStr(AProgram.Globals[I].InitialValue));
    for I := 0 to High(AProgram.Functions) do
    begin
      F := AProgram.Functions[I];
      if F.IsPrototype then Continue;
      Header := 'func @' + F.Name + '(';
      for J := 0 to High(F.Params) do
      begin
        if J > 0 then Header := Header + ', ';
        Header := Header + '%' + F.Params[J].Name;
      end;
      Lines.Add(Header + ') {');
      DumpStmt(F.Body, Lines, 2);
      Lines.Add('}');
      Lines.Add('');
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
