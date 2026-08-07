unit rcc_ast_opt2;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_typeops;

type
  TAdvancedASTOptStats = record
    ConstantsPropagated: QWord;
    LoopsUnrolled: QWord;
    StrengthReductions: QWord;
    ExpressionsHoisted: QWord;
    PropagationBudgetSkips: QWord;
  end;

procedure RunASTPropagation(AProgram: TProgram; ALevel: LongInt;
  out AStats: TAdvancedASTOptStats);
procedure RunASTLoopOptimization(AProgram: TProgram; ALevel: LongInt;
  out AStats: TAdvancedASTOptStats);

implementation

type
  TNameArray = array of string;
  TLongArray = array of LongInt;

  TScanInfo = record
    Modified: TNameArray;
    HasCallOrPtr: Boolean;
    HasVolatile: Boolean;
  end;

  TPropEntry = record
    Name: string;
    DeclDepth: LongInt;
    Live: Boolean;
    AddressTaken: Boolean;
    Value: Int64;
  end;
  TPropMap = array of TPropEntry;

  TRename = record
    OldName: string;
    NewName: string;
  end;
  TRenameArray = array of TRename;

function DefaultIntType: TCType;
begin
  Result := MakeType(ctInt);
end;

{ Value a store actually leaves in the object: narrow destinations wrap, so a
  propagated constant has to be truncated the same way the hardware would. }
function StoredValue(AValue: Int64; const AType: TCType): Int64;
begin
  if IsPointerType(AType) or not IsIntegerType(AType) then Exit(AValue);
  Result := ConvertIntegerValue(AValue, AType);
end;

procedure AppendName(var A: TNameArray; const N: string);
var
  I: LongInt;
begin
  { Modified-name sets feed loop and branch invalidation.  The 2.x pass kept
    duplicates, making large compound blocks repeatedly poison the same
    symbol and growing temporary arrays needlessly. }
  for I := 0 to High(A) do
    if A[I] = N then Exit;
  SetLength(A, Length(A) + 1);
  A[High(A)] := N;
end;

function NameInArray(const A: TNameArray; const N: string): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(A) do
    if A[I] = N then Exit(True);
  Result := False;
end;

procedure CombineNames(var Dest: TNameArray; const A, B: TNameArray);
var
  I: LongInt;
begin
  SetLength(Dest, 0);
  for I := 0 to High(A) do AppendName(Dest, A[I]);
  for I := 0 to High(B) do AppendName(Dest, B[I]);
end;

function WrappedAdd(A, B: Int64): Int64;
begin
  Result := Int64(QWord(A) + QWord(B));
end;

function WrappedSubtract(A, B: Int64): Int64;
begin
  Result := Int64(QWord(A) - QWord(B));
end;

function WrappedMultiply(A, B: Int64): Int64;
begin
  Result := Int64(QWord(A) * QWord(B));
end;

function ArithmeticShiftRight(A: Int64; Shift: LongInt): Int64;
begin
  Shift := Shift and 63;
  if Shift = 0 then Exit(A);
  if A >= 0 then Result := A shr Shift
  else Result := not ((not A) shr Shift);
end;

function PropLookup(const Map: TPropMap; const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := High(Map) downto 0 do
    if Map[I].Name = AName then Exit(I);
  Result := -1;
end;

function PropDeclDepth(const Map: TPropMap; const AName: string;
  ADepth: LongInt): LongInt;
var
  I: LongInt;
begin
  I := PropLookup(Map, AName);
  if I >= 0 then Result := Map[I].DeclDepth else Result := ADepth;
end;

procedure PushEntry(var Map: TPropMap; const AName: string; ADeclDepth: LongInt;
  ALive: Boolean; AValue: Int64);
var
  N: LongInt;
begin
  N := Length(Map);
  SetLength(Map, N + 1);
  Map[N].Name := AName;
  Map[N].DeclDepth := ADeclDepth;
  Map[N].Live := ALive;
  Map[N].AddressTaken := False;
  Map[N].Value := AValue;
end;

procedure MarkAddressTaken(var Map: TPropMap; const AName: string);
var
  I: LongInt;
begin
  I := PropLookup(Map, AName);
  if I >= 0 then
  begin
    Map[I].AddressTaken := True;
    Map[I].Live := False;
  end;
end;

procedure PoisonAddressTaken(var Map: TPropMap);
var
  I: LongInt;
begin
  for I := 0 to High(Map) do
    if Map[I].AddressTaken then Map[I].Live := False;
end;

procedure PoisonAll(var Map: TPropMap);
var
  I: LongInt;
begin
  for I := 0 to High(Map) do Map[I].Live := False;
end;

procedure PoisonNamesInPlace(var Map: TPropMap; const Names: TNameArray);
var
  I, J: LongInt;
begin
  for I := 0 to High(Names) do
  begin
    J := PropLookup(Map, Names[I]);
    if J >= 0 then Map[J].Live := False;
  end;
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
      else if AUnsigned then V := Int64(QWord(A) div QWord(B))
      else if (A = Low(Int64)) and (B = -1) then Exit(False)
      else V := A div B;
    boMod:
      if B = 0 then Exit(False)
      else if AUnsigned then V := Int64(QWord(A) mod QWord(B))
      else if (A = Low(Int64)) and (B = -1) then Exit(False)
      else V := A mod B;
    boShiftLeft: V := Int64(QWord(A) shl (B and 63));
    boShiftRight:
      if AUnsigned then V := Int64(QWord(A) shr (B and 63))
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

function TryConstExpr(E: TExpr; const Map: TPropMap; out V: Int64): Boolean;
var
  A, B: Int64;
  I: LongInt;
  UnsignedOperation: Boolean;
begin
  if E = nil then Exit(False);
  case E.Kind of
    ekInteger:
      begin
        V := E.IntValue;
        Exit(True);
      end;
    ekVariable:
      begin
        I := PropLookup(Map, E.Text);
        if (I >= 0) and Map[I].Live and (not Map[I].AddressTaken) and
           (not E.CType.IsVolatile) then
        begin
          V := Map[I].Value;
          Exit(True);
        end;
        Exit(False);
      end;
    ekUnary:
      begin
        if not TryConstExpr(E.Left, Map, A) then Exit(False);
        case E.UnaryOp of
          uoPositive: V := A;
          uoNegative: V := WrappedSubtract(0, A);
          uoLogicalNot: V := Ord(A = 0);
          uoBitwiseNot: V := not A;
        else
          Exit(False);
        end;
        Exit(True);
      end;
    ekBinary:
      begin
        if not TryConstExpr(E.Left, Map, A) then Exit(False);
        if not TryConstExpr(E.Right, Map, B) then Exit(False);
        case E.BinaryOp of
          boShiftRight, boLess, boLessEqual, boGreater, boGreaterEqual:
            UnsignedOperation := E.OperationType.IsUnsigned;
        else
          UnsignedOperation := E.CType.IsUnsigned;
        end;
        if IsIntegerType(E.OperationType) then
        begin
          A := ConvertIntegerValue(A, E.OperationType);
          if not (E.BinaryOp in [boShiftLeft, boShiftRight]) then
            B := ConvertIntegerValue(B, E.OperationType);
        end;
        if EvalBinary(E.BinaryOp, A, B, UnsignedOperation, V) then Exit(True);
        Exit(False);
      end;
    ekConditional:
      begin
        if not TryConstExpr(E.Left, Map, A) then Exit(False);
        if A <> 0 then Result := TryConstExpr(E.Right, Map, V)
        else Result := TryConstExpr(E.Third, Map, V);
        Exit;
      end;
    ekCast:
      begin
        if not IsIntegerType(E.CType) then Exit(False);
        if not TryConstExpr(E.Left, Map, A) then Exit(False);
        V := ConvertIntegerValue(A, E.CType);
        Exit(True);
      end;
    ekComma:
      begin
        if not TryConstExpr(E.Left, Map, A) then Exit(False);
        Result := TryConstExpr(E.Right, Map, V);
        Exit;
      end;
  else
    Exit(False);
  end;
end;

function ReplaceVariableWithConstant(E: TExpr): TExpr;
begin
  Result := TExpr.Create(ekInteger, E.Pos);
  Result.IntValue := E.IntValue;
  Result.CType := E.CType;
  Result.OperationType := E.OperationType;
end;

procedure PropExpr(var E: TExpr; var Map: TPropMap; LValue: Boolean;
  const Forbidden: TNameArray; Depth: LongInt; var Stats: TAdvancedASTOptStats);
var
  I, J: LongInt;
  A, B, NewValue: Int64;
  NewExpr: TExpr;
begin
  if E = nil then Exit;
  case E.Kind of
    ekVariable:
      if not LValue then
      begin
        I := PropLookup(Map, E.Text);
        if (I >= 0) and Map[I].Live and (not Map[I].AddressTaken) and
           (not E.CType.IsVolatile) and (not NameInArray(Forbidden, E.Text)) then
        begin
          NewExpr := TExpr.Create(ekInteger, E.Pos);
          NewExpr.IntValue := Map[I].Value;
          NewExpr.CType := E.CType;
          NewExpr.OperationType := E.OperationType;
          E.Free;
          E := NewExpr;
          Inc(Stats.ConstantsPropagated);
        end;
      end;
    ekUnary:
      PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
    ekBinary:
      begin
        PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
        PropExpr(E.Right, Map, False, Forbidden, Depth, Stats);
      end;
    ekAssign:
      begin
        PropExpr(E.Left, Map, True, Forbidden, Depth, Stats);
        PropExpr(E.Right, Map, False, Forbidden, Depth, Stats);
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) then
        begin
          if not E.Left.CType.IsVolatile then
          begin
            if E.AssignOp = aoAssign then
            begin
              if TryConstExpr(E.Right, Map, A) then
                PushEntry(Map, E.Left.Text,
                  PropDeclDepth(Map, E.Left.Text, Depth), True,
                  StoredValue(A, E.Left.CType))
              else
                PushEntry(Map, E.Left.Text,
                  PropDeclDepth(Map, E.Left.Text, Depth), False, 0);
            end
            else if TryConstExpr(E.Right, Map, B) then
            begin
              J := PropLookup(Map, E.Left.Text);
              if (J >= 0) and Map[J].Live then
              begin
                case E.AssignOp of
                  aoAdd: NewValue := WrappedAdd(Map[J].Value, B);
                  aoSub: NewValue := WrappedSubtract(Map[J].Value, B);
                  aoMul: NewValue := WrappedMultiply(Map[J].Value, B);
                else
                  J := -2;
                  NewValue := 0;
                end;
                if J >= 0 then
                  PushEntry(Map, E.Left.Text, Map[J].DeclDepth, True,
                    StoredValue(NewValue, E.Left.CType))
                else
                  PushEntry(Map, E.Left.Text,
                    PropDeclDepth(Map, E.Left.Text, Depth), False, 0);
              end
              else
                PushEntry(Map, E.Left.Text,
                  PropDeclDepth(Map, E.Left.Text, Depth), False, 0);
            end
            else
              PushEntry(Map, E.Left.Text,
                PropDeclDepth(Map, E.Left.Text, Depth), False, 0);
          end
          else
            PushEntry(Map, E.Left.Text, PropDeclDepth(Map, E.Left.Text, Depth),
              False, 0);
        end
        else
          PoisonAddressTaken(Map);
      end;
    ekCall:
      begin
        PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
        for I := 0 to High(E.Args) do
          PropExpr(E.Args[I], Map, False, Forbidden, Depth, Stats);
        PoisonAddressTaken(Map);
      end;
    ekConditional:
      begin
        PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
        PropExpr(E.Right, Map, False, Forbidden, Depth, Stats);
        PropExpr(E.Third, Map, False, Forbidden, Depth, Stats);
      end;
    ekAddress:
      begin
        PropExpr(E.Left, Map, True, Forbidden, Depth, Stats);
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) then
          MarkAddressTaken(Map, E.Left.Text);
      end;
    ekDeref:
      begin
        PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
        PoisonAddressTaken(Map);
      end;
    ekPreInc, ekPreDec, ekPostInc, ekPostDec:
      begin
        PropExpr(E.Left, Map, True, Forbidden, Depth, Stats);
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) then
        begin
          J := PropLookup(Map, E.Left.Text);
          if (J >= 0) and Map[J].Live then
          begin
            if E.Kind in [ekPreInc, ekPostInc] then
              PushEntry(Map, E.Left.Text, Map[J].DeclDepth, True,
                WrappedAdd(Map[J].Value, 1))
            else
              PushEntry(Map, E.Left.Text, Map[J].DeclDepth, True,
                WrappedSubtract(Map[J].Value, 1));
          end
          else
            PushEntry(Map, E.Left.Text, PropDeclDepth(Map, E.Left.Text, Depth),
              False, 0);
        end
        else
          PoisonAddressTaken(Map);
      end;
    ekMember, ekArrow, ekIndex:
      begin
        PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
        PropExpr(E.Right, Map, False, Forbidden, Depth, Stats);
        PoisonAddressTaken(Map);
      end;
    ekCast:
      PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
    ekComma:
      begin
        PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
        PropExpr(E.Right, Map, False, Forbidden, Depth, Stats);
      end;
  else
    begin
      PropExpr(E.Left, Map, False, Forbidden, Depth, Stats);
      PropExpr(E.Right, Map, False, Forbidden, Depth, Stats);
      PropExpr(E.Third, Map, False, Forbidden, Depth, Stats);
      for I := 0 to High(E.Args) do
        PropExpr(E.Args[I], Map, False, Forbidden, Depth, Stats);
    end;
  end;
end;

procedure ScanExpr(var E: TExpr; var Info: TScanInfo);
var
  I: LongInt;
begin
  if E = nil then Exit;
  case E.Kind of
    ekVariable:
      if E.CType.IsVolatile then Info.HasVolatile := True;
    ekAssign:
      begin
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) then
          AppendName(Info.Modified, E.Left.Text)
        else
          Info.HasCallOrPtr := True;
        ScanExpr(E.Left, Info);
        ScanExpr(E.Right, Info);
      end;
    ekPreInc, ekPreDec, ekPostInc, ekPostDec:
      begin
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) then
          AppendName(Info.Modified, E.Left.Text)
        else
          Info.HasCallOrPtr := True;
        ScanExpr(E.Left, Info);
      end;
    ekCall:
      begin
        Info.HasCallOrPtr := True;
        ScanExpr(E.Left, Info);
        ScanExpr(E.Right, Info);
        ScanExpr(E.Third, Info);
        for I := 0 to High(E.Args) do
          ScanExpr(E.Args[I], Info);
      end;
    ekDeref, ekIndex, ekArrow, ekMember, ekAddress:
      begin
        Info.HasCallOrPtr := True;
        ScanExpr(E.Left, Info);
        ScanExpr(E.Right, Info);
        ScanExpr(E.Third, Info);
        for I := 0 to High(E.Args) do
          ScanExpr(E.Args[I], Info);
      end;
  else
    begin
      ScanExpr(E.Left, Info);
      ScanExpr(E.Right, Info);
      ScanExpr(E.Third, Info);
      for I := 0 to High(E.Args) do
        ScanExpr(E.Args[I], Info);
    end;
  end;
end;

procedure ScanStmt(S: TStmt; var Info: TScanInfo);
var
  I: LongInt;
begin
  if S = nil then Exit;
  case S.Kind of
    skDecl:
      begin
        AppendName(Info.Modified, S.Name);
        ScanExpr(S.Expr, Info);
      end;
    skExpr:
      ScanExpr(S.Expr, Info);
    skReturn:
      ScanExpr(S.Expr, Info);
    skIf:
      begin
        ScanExpr(S.Expr, Info);
        ScanStmt(S.Body, Info);
        ScanStmt(S.ElseBody, Info);
      end;
    skWhile, skDoWhile:
      begin
        ScanExpr(S.Expr, Info);
        ScanStmt(S.Body, Info);
      end;
    skFor:
      begin
        ScanStmt(S.InitStmt, Info);
        ScanExpr(S.Expr, Info);
        ScanStmt(S.Body, Info);
        ScanExpr(S.Expr2, Info);
      end;
    skSwitch:
      begin
        ScanExpr(S.Expr, Info);
        ScanStmt(S.Body, Info);
      end;
    skCase, skDefault:
      ScanStmt(S.Body, Info);
    skAsm:
      Info.HasCallOrPtr := True;
  else
    begin
      for I := 0 to High(S.Children) do
        ScanStmt(S.Children[I], Info);
      ScanExpr(S.Expr, Info);
      ScanExpr(S.Expr2, Info);
      ScanStmt(S.InitStmt, Info);
      ScanStmt(S.Body, Info);
      ScanStmt(S.ElseBody, Info);
    end;
  end;
end;

function CollectModsExpr(E: TExpr): TScanInfo;
begin
  Result.Modified := nil;
  Result.HasCallOrPtr := False;
  Result.HasVolatile := False;
  ScanExpr(E, Result);
end;

function CollectModsStmt(S: TStmt): TScanInfo;
begin
  Result.Modified := nil;
  Result.HasCallOrPtr := False;
  Result.HasVolatile := False;
  ScanStmt(S, Result);
end;

procedure MergeScanInfo(var Dest: TScanInfo; const Src: TScanInfo);
var
  I: LongInt;
begin
  for I := 0 to High(Src.Modified) do
    AppendName(Dest.Modified, Src.Modified[I]);
  if Src.HasCallOrPtr then Dest.HasCallOrPtr := True;
  if Src.HasVolatile then Dest.HasVolatile := True;
end;

procedure PropStmt(S: TStmt; var Map: TPropMap; Depth: LongInt;
  const Forbidden: TNameArray; var Stats: TAdvancedASTOptStats);
var
  I, J, Mark: LongInt;
  A: Int64;
  EmptyNames: TNameArray;
  Info, Info2: TScanInfo;
  Combined: TNameArray;
begin
  if S = nil then Exit;
  SetLength(EmptyNames, 0);
  SetLength(Combined, 0);
  case S.Kind of
    skBlock:
      begin
        for I := 0 to High(S.Children) do
          PropStmt(S.Children[I], Map, Depth + 1, Forbidden, Stats);
        J := 0;
        while J < Length(Map) do
        begin
          if Map[J].DeclDepth >= Depth + 1 then
          begin
            Map[J] := Map[High(Map)];
            SetLength(Map, Length(Map) - 1);
          end
          else
            Inc(J);
        end;
      end;
    skDecl:
      begin
        PropExpr(S.Expr, Map, False, Forbidden, Depth, Stats);
        { A static local keeps its value between calls, so its initializer says
          nothing about what it holds when the body runs again. }
        if (not S.CType.IsVolatile) and (not S.IsStatic) and
           TryConstExpr(S.Expr, Map, A) then
          PushEntry(Map, S.Name, Depth, True, A)
        else
          PushEntry(Map, S.Name, Depth, False, 0);
      end;
    skExpr:
      PropExpr(S.Expr, Map, False, Forbidden, Depth, Stats);
    skReturn:
      PropExpr(S.Expr, Map, False, Forbidden, Depth, Stats);
    skIf:
      begin
        Mark := Length(Map);
        PropExpr(S.Expr, Map, False, Forbidden, Depth, Stats);
        PropStmt(S.Body, Map, Depth, Forbidden, Stats);
        PropStmt(S.ElseBody, Map, Depth, Forbidden, Stats);
        Info := CollectModsStmt(S.Body);
        Info2 := CollectModsStmt(S.ElseBody);
        for I := 0 to High(Info2.Modified) do
          AppendName(Info.Modified, Info2.Modified[I]);
        SetLength(Map, Mark);
        PoisonNamesInPlace(Map, Info.Modified);
      end;
    skWhile:
      begin
        Info := CollectModsExpr(S.Expr);
        Info2 := CollectModsStmt(S.Body);
        for I := 0 to High(Info2.Modified) do
          AppendName(Info.Modified, Info2.Modified[I]);
        CombineNames(Combined, Forbidden, Info.Modified);
        Mark := Length(Map);
        for I := 0 to High(Info.Modified) do
          PushEntry(Map, Info.Modified[I], Depth, False, 0);
        PropExpr(S.Expr, Map, False, Combined, Depth, Stats);
        PropStmt(S.Body, Map, Depth, Combined, Stats);
        SetLength(Map, Mark);
        PoisonNamesInPlace(Map, Info.Modified);
      end;
    skDoWhile:
      begin
        Info := CollectModsExpr(S.Expr);
        Info2 := CollectModsStmt(S.Body);
        for I := 0 to High(Info2.Modified) do
          AppendName(Info.Modified, Info2.Modified[I]);
        CombineNames(Combined, Forbidden, Info.Modified);
        Mark := Length(Map);
        for I := 0 to High(Info.Modified) do
          PushEntry(Map, Info.Modified[I], Depth, False, 0);
        PropStmt(S.Body, Map, Depth, Combined, Stats);
        PropExpr(S.Expr, Map, False, Combined, Depth, Stats);
        SetLength(Map, Mark);
        PoisonNamesInPlace(Map, Info.Modified);
      end;
    skFor:
      begin
        Info := CollectModsStmt(S.InitStmt);
        Info2 := CollectModsExpr(S.Expr);
        for I := 0 to High(Info2.Modified) do
          AppendName(Info.Modified, Info2.Modified[I]);
        Info2 := CollectModsExpr(S.Expr2);
        for I := 0 to High(Info2.Modified) do
          AppendName(Info.Modified, Info2.Modified[I]);
        Info2 := CollectModsStmt(S.Body);
        for I := 0 to High(Info2.Modified) do
          AppendName(Info.Modified, Info2.Modified[I]);
        CombineNames(Combined, Forbidden, Info.Modified);
        Mark := Length(Map);
        for I := 0 to High(Info.Modified) do
          PushEntry(Map, Info.Modified[I], Depth, False, 0);
        PropStmt(S.InitStmt, Map, Depth + 1, Combined, Stats);
        PropExpr(S.Expr, Map, False, Combined, Depth, Stats);
        PropStmt(S.Body, Map, Depth, Combined, Stats);
        PropExpr(S.Expr2, Map, False, Combined, Depth, Stats);
        SetLength(Map, Mark);
        PoisonNamesInPlace(Map, Info.Modified);
      end;
    skSwitch:
      begin
        Mark := Length(Map);
        PropExpr(S.Expr, Map, False, Forbidden, Depth, Stats);
        PropStmt(S.Body, Map, Depth + 1, Forbidden, Stats);
        Info := CollectModsStmt(S.Body);
        SetLength(Map, Mark);
        PoisonNamesInPlace(Map, Info.Modified);
      end;
    skCase, skDefault:
      PropStmt(S.Body, Map, Depth, Forbidden, Stats);
    skLabel, skGoto, skAsm:
      PoisonAll(Map);
    skEmpty, skBreak, skContinue, skStaticAssert:
      ;
  end;
end;

function PropExprNodeCount(E: TExpr): QWord;
var
  I: LongInt;
begin
  if E = nil then Exit(0);
  Result := 1 + PropExprNodeCount(E.Left) + PropExprNodeCount(E.Right) +
    PropExprNodeCount(E.Third);
  for I := 0 to High(E.Args) do Inc(Result, PropExprNodeCount(E.Args[I]));
end;

function PropStmtNodeCount(S: TStmt): QWord;
var
  I: LongInt;
begin
  if S = nil then Exit(0);
  Result := 1 + PropExprNodeCount(S.Expr) + PropExprNodeCount(S.Expr2) +
    PropStmtNodeCount(S.InitStmt) + PropStmtNodeCount(S.Body) +
    PropStmtNodeCount(S.ElseBody);
  for I := 0 to High(S.Children) do
    Inc(Result, PropStmtNodeCount(S.Children[I]));
  for I := 0 to High(S.AsmOutputs) do
    Inc(Result, PropExprNodeCount(S.AsmOutputs[I].Expr));
  for I := 0 to High(S.AsmInputs) do
    Inc(Result, PropExprNodeCount(S.AsmInputs[I].Expr));
end;

procedure RunASTPropagation(AProgram: TProgram; ALevel: LongInt;
  out AStats: TAdvancedASTOptStats);
var
  I: LongInt;
  FunctionNodes: QWord;
  Map: TPropMap;
  EmptyNames: TNameArray;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  if ALevel < 1 then Exit;
  SetLength(EmptyNames, 0);
  for I := 0 to High(AProgram.Functions) do
  begin
    if AProgram.Functions[I].IsPrototype then Continue;
    { Constant propagation uses a versioned scope map.  Bound it on giant
      generated functions so -O1 remains a low-latency mode and -O2/-O3 do
      not become quadratic on pathological single-function inputs. }
    FunctionNodes := PropStmtNodeCount(AProgram.Functions[I].Body);
    if ((ALevel = 1) and (FunctionNodes > 24000)) or
       ((ALevel >= 2) and (FunctionNodes > 120000)) then
    begin
      Inc(AStats.PropagationBudgetSkips);
      Continue;
    end;
    SetLength(Map, 0);
    PropStmt(AProgram.Functions[I].Body, Map, 0, EmptyNames, AStats);
  end;
end;

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
  for I := 0 to High(E.Args) do
    Result.Args[I] := CloneExpr(E.Args[I]);
end;

function RenameLookup(const Renames: TRenameArray; const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := High(Renames) downto 0 do
    if Renames[I].OldName = AName then Exit(I);
  Result := -1;
end;

function CloneExprUnroll(E: TExpr; const IVName: string; IVValue: Int64;
  const Renames: TRenameArray; LValue: Boolean): TExpr;
var
  I: LongInt;
  RIdx: LongInt;
begin
  if E = nil then Exit(nil);
  if E.Kind = ekVariable then
  begin
    RIdx := RenameLookup(Renames, E.Text);
    if (RIdx < 0) and (not LValue) and (E.Text = IVName) then
    begin
      Result := TExpr.Create(ekInteger, E.Pos);
      Result.IntValue := IVValue;
      Result.CType := E.CType;
      Result.OperationType := E.OperationType;
      Exit;
    end;
    Result := TExpr.Create(ekVariable, E.Pos);
    if RIdx >= 0 then Result.Text := Renames[RIdx].NewName
    else Result.Text := E.Text;
    Result.CType := E.CType;
    Result.OperationType := E.OperationType;
    Result.IsLValue := E.IsLValue;
    Exit;
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
  case E.Kind of
    ekAssign, ekAddress, ekPreInc, ekPreDec, ekPostInc, ekPostDec:
      Result.Left := CloneExprUnroll(E.Left, IVName, IVValue, Renames, True);
  else
    Result.Left := CloneExprUnroll(E.Left, IVName, IVValue, Renames, False);
  end;
  Result.Right := CloneExprUnroll(E.Right, IVName, IVValue, Renames, False);
  Result.Third := CloneExprUnroll(E.Third, IVName, IVValue, Renames, False);
  SetLength(Result.Args, Length(E.Args));
  for I := 0 to High(E.Args) do
    Result.Args[I] := CloneExprUnroll(E.Args[I], IVName, IVValue, Renames, False);
end;

function CloneStmtUnroll(S: TStmt; const IVName: string; IVValue: Int64;
  var Renames: TRenameArray; var NameCounter: LongInt): TStmt;
var
  I, Mark, N: LongInt;
begin
  if S = nil then Exit(nil);
  Result := TStmt.Create(S.Kind, S.Pos);
  Result.Name := S.Name;
  Result.CType := S.CType;
  Result.CaseValue := S.CaseValue;
  Result.IsDeclarationGroup := S.IsDeclarationGroup;
  Result.AsmTemplate := S.AsmTemplate;
  Result.AsmVolatile := S.AsmVolatile;
  Result.AsmGoto := S.AsmGoto;
  case S.Kind of
    skDecl:
      begin
        N := Length(Renames);
        SetLength(Renames, N + 1);
        Renames[N].OldName := S.Name;
        Result.Name := S.Name + '__r' + IntToStr(NameCounter);
        Inc(NameCounter);
        Renames[N].NewName := Result.Name;
        Result.Expr := CloneExprUnroll(S.Expr, IVName, IVValue, Renames, False);
      end;
    skBlock:
      begin
        Mark := Length(Renames);
        SetLength(Result.Children, Length(S.Children));
        for I := 0 to High(S.Children) do
          Result.Children[I] := CloneStmtUnroll(S.Children[I], IVName,
            IVValue, Renames, NameCounter);
        SetLength(Renames, Mark);
      end;
    skFor:
      begin
        Mark := Length(Renames);
        Result.InitStmt := CloneStmtUnroll(S.InitStmt, IVName, IVValue,
          Renames, NameCounter);
        Result.Expr := CloneExprUnroll(S.Expr, IVName, IVValue, Renames, False);
        Result.Expr2 := CloneExprUnroll(S.Expr2, IVName, IVValue, Renames, False);
        Result.Body := CloneStmtUnroll(S.Body, IVName, IVValue,
          Renames, NameCounter);
        SetLength(Renames, Mark);
      end;
    skIf:
      begin
        Result.Expr := CloneExprUnroll(S.Expr, IVName, IVValue, Renames, False);
        Result.Body := CloneStmtUnroll(S.Body, IVName, IVValue,
          Renames, NameCounter);
        Result.ElseBody := CloneStmtUnroll(S.ElseBody, IVName, IVValue,
          Renames, NameCounter);
      end;
    skWhile, skDoWhile:
      begin
        Result.Expr := CloneExprUnroll(S.Expr, IVName, IVValue, Renames, False);
        Result.Body := CloneStmtUnroll(S.Body, IVName, IVValue,
          Renames, NameCounter);
      end;
    skExpr:
      Result.Expr := CloneExprUnroll(S.Expr, IVName, IVValue, Renames, False);
    skReturn:
      Result.Expr := CloneExprUnroll(S.Expr, IVName, IVValue, Renames, False);
    skSwitch:
      begin
        Result.Expr := CloneExprUnroll(S.Expr, IVName, IVValue, Renames, False);
        Result.Body := CloneStmtUnroll(S.Body, IVName, IVValue,
          Renames, NameCounter);
      end;
    skCase, skDefault:
      Result.Body := CloneStmtUnroll(S.Body, IVName, IVValue,
        Renames, NameCounter);
    skLabel:
      Result.Body := CloneStmtUnroll(S.Body, IVName, IVValue,
        Renames, NameCounter);
    skAsm:
      begin
        SetLength(Result.AsmOutputs, Length(S.AsmOutputs));
        for I := 0 to High(S.AsmOutputs) do
        begin
          Result.AsmOutputs[I] := TAsmOperand.Create;
          Result.AsmOutputs[I].Name := S.AsmOutputs[I].Name;
          Result.AsmOutputs[I].ConstraintText := S.AsmOutputs[I].ConstraintText;
          Result.AsmOutputs[I].IsOutput := S.AsmOutputs[I].IsOutput;
          Result.AsmOutputs[I].Expr := CloneExprUnroll(S.AsmOutputs[I].Expr,
            IVName, IVValue, Renames, False);
        end;
        SetLength(Result.AsmInputs, Length(S.AsmInputs));
        for I := 0 to High(S.AsmInputs) do
        begin
          Result.AsmInputs[I] := TAsmOperand.Create;
          Result.AsmInputs[I].Name := S.AsmInputs[I].Name;
          Result.AsmInputs[I].ConstraintText := S.AsmInputs[I].ConstraintText;
          Result.AsmInputs[I].IsOutput := S.AsmInputs[I].IsOutput;
          Result.AsmInputs[I].Expr := CloneExprUnroll(S.AsmInputs[I].Expr,
            IVName, IVValue, Renames, False);
        end;
        SetLength(Result.AsmClobbers, Length(S.AsmClobbers));
        for I := 0 to High(S.AsmClobbers) do
          Result.AsmClobbers[I] := S.AsmClobbers[I];
        SetLength(Result.AsmLabels, Length(S.AsmLabels));
        for I := 0 to High(S.AsmLabels) do
          Result.AsmLabels[I] := S.AsmLabels[I];
      end;
  else
    begin
      SetLength(Result.Children, Length(S.Children));
      for I := 0 to High(S.Children) do
        Result.Children[I] := CloneStmtUnroll(S.Children[I], IVName,
          IVValue, Renames, NameCounter);
    end;
  end;
end;

function ExprModifiesName(E: TExpr; const AName: string): Boolean;
begin
  if E = nil then Exit(False);
  case E.Kind of
    ekAssign:
      begin
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
           (E.Left.Text = AName) then Exit(True);
        if ExprModifiesName(E.Left, AName) then Exit(True);
        if ExprModifiesName(E.Right, AName) then Exit(True);
      end;
    ekPreInc, ekPreDec, ekPostInc, ekPostDec:
      begin
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
           (E.Left.Text = AName) then Exit(True);
        if ExprModifiesName(E.Left, AName) then Exit(True);
      end;
  else
    if ExprModifiesName(E.Left, AName) then Exit(True);
    if ExprModifiesName(E.Right, AName) then Exit(True);
    if ExprModifiesName(E.Third, AName) then Exit(True);
  end;
  Result := False;
end;

function StmtModifiesName(S: TStmt; const AName: string): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(False);
  case S.Kind of
    skDecl:
      if S.Name = AName then Exit(True);
    skExpr, skReturn:
      if ExprModifiesName(S.Expr, AName) then Exit(True);
    skIf:
      begin
        if ExprModifiesName(S.Expr, AName) then Exit(True);
        if StmtModifiesName(S.Body, AName) then Exit(True);
        if StmtModifiesName(S.ElseBody, AName) then Exit(True);
      end;
    skWhile, skDoWhile:
      begin
        if ExprModifiesName(S.Expr, AName) then Exit(True);
        if StmtModifiesName(S.Body, AName) then Exit(True);
      end;
    skFor:
      begin
        if StmtModifiesName(S.InitStmt, AName) then Exit(True);
        if ExprModifiesName(S.Expr, AName) then Exit(True);
        if ExprModifiesName(S.Expr2, AName) then Exit(True);
        if StmtModifiesName(S.Body, AName) then Exit(True);
      end;
    skSwitch:
      begin
        if ExprModifiesName(S.Expr, AName) then Exit(True);
        if StmtModifiesName(S.Body, AName) then Exit(True);
      end;
    skCase, skDefault, skLabel:
      if StmtModifiesName(S.Body, AName) then Exit(True);
  else
    for I := 0 to High(S.Children) do
      if StmtModifiesName(S.Children[I], AName) then Exit(True);
  end;
  Result := False;
end;

function ExprTakesAddressOf(E: TExpr; const AName: string): Boolean;
begin
  if E = nil then Exit(False);
  if (E.Kind = ekAddress) and (E.Left <> nil) and
     (E.Left.Kind = ekVariable) and (E.Left.Text = AName) then Exit(True);
  if ExprTakesAddressOf(E.Left, AName) then Exit(True);
  if ExprTakesAddressOf(E.Right, AName) then Exit(True);
  if ExprTakesAddressOf(E.Third, AName) then Exit(True);
  Result := False;
end;

function StmtTakesAddressOf(S: TStmt; const AName: string): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(False);
  case S.Kind of
    skDecl:
      if ExprTakesAddressOf(S.Expr, AName) then Exit(True);
    skExpr, skReturn:
      if ExprTakesAddressOf(S.Expr, AName) then Exit(True);
    skIf:
      begin
        if ExprTakesAddressOf(S.Expr, AName) then Exit(True);
        if StmtTakesAddressOf(S.Body, AName) then Exit(True);
        if StmtTakesAddressOf(S.ElseBody, AName) then Exit(True);
      end;
    skWhile, skDoWhile:
      begin
        if ExprTakesAddressOf(S.Expr, AName) then Exit(True);
        if StmtTakesAddressOf(S.Body, AName) then Exit(True);
      end;
    skFor:
      begin
        if StmtTakesAddressOf(S.InitStmt, AName) then Exit(True);
        if ExprTakesAddressOf(S.Expr, AName) then Exit(True);
        if ExprTakesAddressOf(S.Expr2, AName) then Exit(True);
        if StmtTakesAddressOf(S.Body, AName) then Exit(True);
      end;
    skSwitch:
      begin
        if ExprTakesAddressOf(S.Expr, AName) then Exit(True);
        if StmtTakesAddressOf(S.Body, AName) then Exit(True);
      end;
    skCase, skDefault, skLabel:
      if StmtTakesAddressOf(S.Body, AName) then Exit(True);
  else
    for I := 0 to High(S.Children) do
      if StmtTakesAddressOf(S.Children[I], AName) then Exit(True);
  end;
  Result := False;
end;

function StmtHasBarrier(S: TStmt): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(False);
  case S.Kind of
    skBreak, skContinue, skGoto, skLabel, skReturn, skSwitch,
    skCase, skDefault, skAsm, skStaticAssert: Exit(True);
    skIf:
      begin
        if StmtHasBarrier(S.Body) then Exit(True);
        if StmtHasBarrier(S.ElseBody) then Exit(True);
      end;
    skWhile, skDoWhile, skFor:
      begin
        if StmtHasBarrier(S.InitStmt) then Exit(True);
        if StmtHasBarrier(S.Body) then Exit(True);
      end;
  else
    for I := 0 to High(S.Children) do
      if StmtHasBarrier(S.Children[I]) then Exit(True);
  end;
  Result := False;
end;

function CountExprNodes(E: TExpr): LongInt;
var
  I: LongInt;
begin
  if E = nil then Exit(0);
  Result := 1 + CountExprNodes(E.Left) + CountExprNodes(E.Right) +
    CountExprNodes(E.Third);
  for I := 0 to High(E.Args) do
    Result := Result + CountExprNodes(E.Args[I]);
end;

function CountStmtNodes(S: TStmt): LongInt;
var
  I: LongInt;
begin
  if S = nil then Exit(0);
  Result := 1 + CountExprNodes(S.Expr) + CountExprNodes(S.Expr2) +
    CountStmtNodes(S.InitStmt) + CountStmtNodes(S.Body) +
    CountStmtNodes(S.ElseBody);
  for I := 0 to High(S.Children) do
    Result := Result + CountStmtNodes(S.Children[I]);
end;

function ExtractStep(E: TExpr; const IVName: string; out Step: Int64): Boolean;
var
  C: Int64;
begin
  Result := False;
  Step := 0;
  if E = nil then Exit;
  case E.Kind of
    ekPreInc, ekPostInc:
      begin
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
           (E.Left.Text = IVName) then
        begin
          Step := 1;
          Exit(True);
        end;
      end;
    ekPreDec, ekPostDec:
      begin
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
           (E.Left.Text = IVName) then
        begin
          Step := -1;
          Exit(True);
        end;
      end;
    ekAssign:
      if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
         (E.Left.Text = IVName) then
      begin
        if (E.Right <> nil) and (E.Right.Kind = ekInteger) then
        begin
          C := E.Right.IntValue;
          case E.AssignOp of
            aoAdd: Step := C;
            aoSub: Step := -C;
          else
            Exit;
          end;
          Exit(True);
        end;
      end;
  end;
end;

function AnalyzeForIV(S: TStmt; out IVName: string; out Start: Int64;
  out Step: Int64; out IVType: TCType; out HasBound: Boolean;
  out Bound: Int64; out TripCount: Int64): Boolean;
var
  I: LongInt;
  Decl: TStmt;
  BoundExpr: TExpr;
  Op: TBinaryOp;
  B, Diff, S2: Int64;
  EmptyMap: TPropMap;
begin
  Result := False;
  HasBound := False;
  Bound := 0;
  TripCount := -1;
  SetLength(EmptyMap, 0);
  if (S = nil) or (S.Kind <> skFor) then Exit;
  if S.Expr = nil then Exit;
  if S.Expr.Kind <> ekBinary then Exit;
  if not (S.Expr.BinaryOp in [boLess, boLessEqual, boGreater,
    boGreaterEqual, boNotEqual]) then Exit;
  if (S.Expr.Left <> nil) and (S.Expr.Left.Kind = ekVariable) then
  begin
    IVName := S.Expr.Left.Text;
    BoundExpr := S.Expr.Right;
    Op := S.Expr.BinaryOp;
  end
  else if (S.Expr.Right <> nil) and (S.Expr.Right.Kind = ekVariable) then
  begin
    IVName := S.Expr.Right.Text;
    BoundExpr := S.Expr.Left;
    case S.Expr.BinaryOp of
      boLess: Op := boGreater;
      boLessEqual: Op := boGreaterEqual;
      boGreater: Op := boLess;
      boGreaterEqual: Op := boLessEqual;
    else
      Op := S.Expr.BinaryOp;
    end;
  end
  else
    Exit;
  Decl := nil;
  if S.InitStmt <> nil then
  begin
    if S.InitStmt.Kind = skDecl then
    begin
      if S.InitStmt.Name = IVName then Decl := S.InitStmt;
    end
    else if S.InitStmt.Kind = skBlock then
    begin
      for I := 0 to High(S.InitStmt.Children) do
        if (S.InitStmt.Children[I].Kind = skDecl) and
           (S.InitStmt.Children[I].Name = IVName) then
        begin
          Decl := S.InitStmt.Children[I];
          Break;
        end;
    end;
  end;
  if Decl = nil then Exit;
  IVType := Decl.CType;
  if not IsIntegerType(IVType) then Exit;
  if not TryConstExpr(Decl.Expr, EmptyMap, Start) then Exit;
  if not ExtractStep(S.Expr2, IVName, Step) then Exit;
  if Step = 0 then Exit;
  if (BoundExpr <> nil) and (BoundExpr.Kind = ekInteger) then
  begin
    HasBound := True;
    Bound := BoundExpr.IntValue;
    B := Bound;
    if Step > 0 then
    begin
      case Op of
        boLess:
          begin
            Diff := B - Start;
            if Diff <= 0 then TripCount := 0
            else TripCount := (Diff - 1) div Step + 1;
          end;
        boLessEqual:
          begin
            Diff := B - Start;
            if Diff < 0 then TripCount := 0
            else TripCount := Diff div Step + 1;
          end;
        boNotEqual:
          if (B - Start > 0) and ((B - Start) mod Step = 0) then
            TripCount := (B - Start) div Step
          else
            TripCount := -1;
        boGreater, boGreaterEqual: TripCount := 0;
      else
        TripCount := -1;
      end;
    end
    else
    begin
      S2 := -Step;
      case Op of
        boGreater:
          begin
            Diff := Start - B;
            if Diff <= 0 then TripCount := 0
            else TripCount := (Diff - 1) div S2 + 1;
          end;
        boGreaterEqual:
          begin
            Diff := Start - B;
            if Diff < 0 then TripCount := 0
            else TripCount := Diff div S2 + 1;
          end;
        boNotEqual:
          if (Start - B > 0) and ((Start - B) mod S2 = 0) then
            TripCount := (Start - B) div S2
          else
            TripCount := -1;
        boLess, boLessEqual: TripCount := 0;
      else
        TripCount := -1;
      end;
    end;
  end;
  Result := True;
end;

function TryUnrollFor(S: TStmt; var Stats: TAdvancedASTOptStats): TStmt;
var
  IVName: string;
  Start, Step, Bound, Trips: Int64;
  IVType: TCType;
  HasBound: Boolean;
  I, K: LongInt;
  Body: TStmt;
  NewBlock: TStmt;
  Renames: TRenameArray;
  NameCounter: LongInt;
  AssignStmt: TStmt;
  AssignExpr, VarE, IntE: TExpr;
begin
  Result := nil;
  if not AnalyzeForIV(S, IVName, Start, Step, IVType, HasBound, Bound, Trips) then
    Exit;
  if not HasBound then Exit;
  if Trips < 0 then Exit;
  if Trips > 8 then Exit;
  Body := S.Body;
  if Body = nil then Exit;
  if StmtHasBarrier(Body) then Exit;
  if StmtModifiesName(Body, IVName) then Exit;
  if StmtTakesAddressOf(Body, IVName) then Exit;
  if CountStmtNodes(Body) > 24 then Exit;
  NewBlock := TStmt.Create(skBlock, S.Pos);
  SetLength(NewBlock.Children, 1 + Trips + 1);
  NewBlock.Children[0] := S.InitStmt;
  S.InitStmt := nil;
  Renames := nil;
  NameCounter := 1;
  for K := 0 to Trips - 1 do
  begin
    SetLength(Renames, 0);
    NewBlock.Children[1 + K] := CloneStmtUnroll(Body, IVName,
      WrappedAdd(Start, WrappedMultiply(K, Step)), Renames, NameCounter);
  end;
  if Trips > 0 then
  begin
    AssignStmt := TStmt.Create(skExpr, S.Pos);
    AssignExpr := TExpr.Create(ekAssign, S.Pos);
    VarE := TExpr.Create(ekVariable, S.Pos);
    VarE.Text := IVName;
    VarE.CType := IVType;
    VarE.OperationType := IVType;
    VarE.IsLValue := True;
    IntE := TExpr.Create(ekInteger, S.Pos);
    IntE.IntValue := WrappedAdd(Start, WrappedMultiply(Trips, Step));
    IntE.CType := IVType;
    IntE.OperationType := IVType;
    AssignExpr.Left := VarE;
    AssignExpr.Right := IntE;
    AssignExpr.CType := IVType;
    AssignExpr.OperationType := IVType;
    AssignStmt.Expr := AssignExpr;
    NewBlock.Children[1 + Trips] := AssignStmt;
  end
  else
    SetLength(NewBlock.Children, 1);
  Inc(Stats.LoopsUnrolled);
  Result := NewBlock;
end;

procedure AddStrengthCandidate(AValue, AMultiplier: Int64;
  var CValues: TNameArray; var Multipliers: TNameArray;
  var Occurrences: TLongArray; var Count: LongInt);
var
  I: LongInt;
begin
  for I := 0 to Count - 1 do
    if CValues[I] = IntToStr(AValue) then
    begin
      Inc(Occurrences[I]);
      Exit;
    end;
  AppendName(CValues, IntToStr(AValue));
  AppendName(Multipliers, IntToStr(AMultiplier));
  SetLength(Occurrences, Length(Occurrences) + 1);
  Occurrences[High(Occurrences)] := 1;
  Inc(Count);
end;

function FindStrengthCandidate(AValue: Int64;
  const CValues: TNameArray): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(CValues) do
    if CValues[I] = IntToStr(AValue) then Exit(I);
  Result := -1;
end;

procedure CollectStrengthCandidatesExpr(E: TExpr; const IVName: string;
  var CValues: TNameArray; var Multipliers: TNameArray;
  var Occurrences: TLongArray; var Count: LongInt);
var
  I: LongInt;
  C: Int64;
begin
  if E = nil then Exit;
  if E.Kind = ekBinary then
  begin
    if E.BinaryOp = boMul then
    begin
      if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
         (E.Left.Text = IVName) and (E.Right <> nil) and
         (E.Right.Kind = ekInteger) then
      begin
        C := E.Right.IntValue;
        if (C < -1) or (C > 1) then
          AddStrengthCandidate(C, C, CValues, Multipliers, Occurrences, Count);
      end
      else if (E.Right <> nil) and (E.Right.Kind = ekVariable) and
         (E.Right.Text = IVName) and (E.Left <> nil) and
         (E.Left.Kind = ekInteger) then
      begin
        C := E.Left.IntValue;
        if (C < -1) or (C > 1) then
          AddStrengthCandidate(C, C, CValues, Multipliers, Occurrences, Count);
      end;
    end
    else if E.BinaryOp = boShiftLeft then
    begin
      if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
         (E.Left.Text = IVName) and (E.Right <> nil) and
         (E.Right.Kind = ekInteger) then
      begin
        C := E.Right.IntValue;
        if (C >= 1) and (C <= 62) then
          AddStrengthCandidate(C, Int64(QWord(1) shl C), CValues,
            Multipliers, Occurrences, Count);
      end;
    end;
  end;
  CollectStrengthCandidatesExpr(E.Left, IVName, CValues, Multipliers,
    Occurrences, Count);
  CollectStrengthCandidatesExpr(E.Right, IVName, CValues, Multipliers,
    Occurrences, Count);
  CollectStrengthCandidatesExpr(E.Third, IVName, CValues, Multipliers,
    Occurrences, Count);
  for I := 0 to High(E.Args) do
    CollectStrengthCandidatesExpr(E.Args[I], IVName, CValues, Multipliers,
      Occurrences, Count);
end;

procedure CollectStrengthCandidates(S: TStmt; const IVName: string;
  var CValues: TNameArray; var Multipliers: TNameArray;
  var Occurrences: TLongArray; var Count: LongInt);
var
  I: LongInt;
begin
  if S = nil then Exit;
  for I := 0 to High(S.Children) do
    CollectStrengthCandidates(S.Children[I], IVName, CValues, Multipliers,
      Occurrences, Count);
  CollectStrengthCandidatesExpr(S.Expr, IVName, CValues, Multipliers,
    Occurrences, Count);
  CollectStrengthCandidatesExpr(S.Expr2, IVName, CValues, Multipliers,
    Occurrences, Count);
  CollectStrengthCandidates(S.InitStmt, IVName, CValues, Multipliers,
    Occurrences, Count);
  CollectStrengthCandidates(S.Body, IVName, CValues, Multipliers,
    Occurrences, Count);
  CollectStrengthCandidates(S.ElseBody, IVName, CValues, Multipliers,
    Occurrences, Count);
end;

function ReplaceStrengthExprsE(var E: TExpr; const IVName: string;
  const CValues: TNameArray; const Multipliers: TNameArray;
  const AuxNames: TNameArray): Boolean;
var
  I, J: LongInt;
  C: Int64;
  NewE: TExpr;
begin
  Result := False;
  if E = nil then Exit;
  if E.Kind = ekBinary then
  begin
    if E.BinaryOp = boMul then
    begin
      if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
         (E.Left.Text = IVName) and (E.Right <> nil) and
         (E.Right.Kind = ekInteger) then
      begin
        C := E.Right.IntValue;
        J := FindStrengthCandidate(C, CValues);
        if J >= 0 then
        begin
          NewE := TExpr.Create(ekVariable, E.Pos);
          NewE.Text := AuxNames[J];
          NewE.CType := E.CType;
          NewE.OperationType := E.OperationType;
          E.Free;
          E := NewE;
          Exit(True);
        end;
      end
      else if (E.Right <> nil) and (E.Right.Kind = ekVariable) and
         (E.Right.Text = IVName) and (E.Left <> nil) and
         (E.Left.Kind = ekInteger) then
      begin
        C := E.Left.IntValue;
        J := FindStrengthCandidate(C, CValues);
        if J >= 0 then
        begin
          NewE := TExpr.Create(ekVariable, E.Pos);
          NewE.Text := AuxNames[J];
          NewE.CType := E.CType;
          NewE.OperationType := E.OperationType;
          E.Free;
          E := NewE;
          Exit(True);
        end;
      end;
    end
    else if E.BinaryOp = boShiftLeft then
    begin
      if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
         (E.Left.Text = IVName) and (E.Right <> nil) and
         (E.Right.Kind = ekInteger) then
      begin
        C := E.Right.IntValue;
        if (C >= 1) and (C <= 62) then
        begin
          J := FindStrengthCandidate(C, CValues);
          if J >= 0 then
          begin
            NewE := TExpr.Create(ekVariable, E.Pos);
            NewE.Text := AuxNames[J];
            NewE.CType := E.CType;
            NewE.OperationType := E.OperationType;
            E.Free;
            E := NewE;
            Exit(True);
          end;
        end;
      end;
    end;
  end;
  if ReplaceStrengthExprsE(E.Left, IVName, CValues, Multipliers, AuxNames) then
    Result := True;
  if ReplaceStrengthExprsE(E.Right, IVName, CValues, Multipliers, AuxNames) then
    Result := True;
  if ReplaceStrengthExprsE(E.Third, IVName, CValues, Multipliers, AuxNames) then
    Result := True;
  for I := 0 to High(E.Args) do
    if ReplaceStrengthExprsE(E.Args[I], IVName, CValues, Multipliers, AuxNames) then
      Result := True;
end;

function ReplaceStrengthExprs(S: TStmt; const IVName: string;
  const CValues: TNameArray; const Multipliers: TNameArray;
  const AuxNames: TNameArray): Boolean;
var
  I: LongInt;
begin
  Result := False;
  if S = nil then Exit;
  for I := 0 to High(S.Children) do
    if ReplaceStrengthExprs(S.Children[I], IVName, CValues, Multipliers,
      AuxNames) then Result := True;
  if ReplaceStrengthExprsE(S.Expr, IVName, CValues, Multipliers, AuxNames) then
    Result := True;
  if ReplaceStrengthExprsE(S.Expr2, IVName, CValues, Multipliers, AuxNames) then
    Result := True;
  if ReplaceStrengthExprs(S.InitStmt, IVName, CValues, Multipliers, AuxNames) then
    Result := True;
  if ReplaceStrengthExprs(S.Body, IVName, CValues, Multipliers, AuxNames) then
    Result := True;
  if ReplaceStrengthExprs(S.ElseBody, IVName, CValues, Multipliers, AuxNames) then
    Result := True;
end;

function TryStrengthReduceFor(S: TStmt; var Stats: TAdvancedASTOptStats): TStmt;
var
  IVName: string;
  Start, Step: Int64;
  IVType: TCType;
  HasBound: Boolean;
  Bound, Trips: Int64;
  CValues, Multipliers, AuxNames, FinalC, FinalM: TNameArray;
  Occurrences: TLongArray;
  N, I, J, FinalCount: LongInt;
  Body: TStmt;
  InitBlock: TStmt;
  PostExpr, UpdateExpr, CommaExpr: TExpr;
  Decl: TStmt;
  InitVal: TExpr;
  VarE, IntE: TExpr;
begin
  Result := nil;
  if not AnalyzeForIV(S, IVName, Start, Step, IVType, HasBound, Bound, Trips) then
    Exit;
  Body := S.Body;
  if Body = nil then Exit;
  if StmtModifiesName(Body, IVName) then Exit;
  if StmtTakesAddressOf(Body, IVName) then Exit;
  CValues := nil;
  Multipliers := nil;
  Occurrences := nil;
  N := 0;
  CollectStrengthCandidates(Body, IVName, CValues, Multipliers, Occurrences, N);
  if N = 0 then Exit;
  FinalC := nil;
  FinalM := nil;
  FinalCount := 0;
  for I := 0 to N - 1 do
    if Occurrences[I] >= 4 then
    begin
      AppendName(FinalC, CValues[I]);
      AppendName(FinalM, Multipliers[I]);
      Inc(FinalCount);
    end;
  if FinalCount = 0 then Exit;
  if S.InitStmt = nil then Exit;
  if S.InitStmt.Kind = skDecl then
  begin
    InitBlock := TStmt.Create(skBlock, S.InitStmt.Pos);
    InitBlock.IsDeclarationGroup := True;
    SetLength(InitBlock.Children, 1 + FinalCount);
    InitBlock.Children[0] := S.InitStmt;
    S.InitStmt := InitBlock;
  end
  else if S.InitStmt.Kind = skBlock then
  begin
    InitBlock := S.InitStmt;
    InitBlock.IsDeclarationGroup := True;
    SetLength(InitBlock.Children, Length(InitBlock.Children) + FinalCount);
  end
  else
    Exit;
  AuxNames := nil;
  for I := 0 to FinalCount - 1 do
  begin
    Decl := TStmt.Create(skDecl, S.Pos);
    Decl.Name := '__rc' + IntToStr(I);
    Decl.CType := IVType;
    InitVal := TExpr.Create(ekInteger, S.Pos);
    InitVal.IntValue := WrappedMultiply(Start,
      StrToInt64(FinalM[I]));
    InitVal.CType := IVType;
    InitVal.OperationType := IVType;
    Decl.Expr := InitVal;
    InitBlock.Children[Length(InitBlock.Children) - FinalCount + I] := Decl;
    AppendName(AuxNames, Decl.Name);
  end;
  ReplaceStrengthExprs(Body, IVName, FinalC, FinalM, AuxNames);
  PostExpr := S.Expr2;
  for I := 0 to FinalCount - 1 do
  begin
    UpdateExpr := TExpr.Create(ekAssign, S.Pos);
    UpdateExpr.AssignOp := aoAdd;
    VarE := TExpr.Create(ekVariable, S.Pos);
    VarE.Text := AuxNames[I];
    VarE.CType := IVType;
    VarE.OperationType := IVType;
    VarE.IsLValue := True;
    IntE := TExpr.Create(ekInteger, S.Pos);
    IntE.IntValue := WrappedMultiply(Step, StrToInt64(FinalM[I]));
    IntE.CType := IVType;
    IntE.OperationType := IVType;
    UpdateExpr.Left := VarE;
    UpdateExpr.Right := IntE;
    UpdateExpr.CType := IVType;
    UpdateExpr.OperationType := IVType;
    CommaExpr := TExpr.Create(ekBinary, S.Pos);
    CommaExpr.BinaryOp := boComma;
    CommaExpr.Left := PostExpr;
    CommaExpr.Right := UpdateExpr;
    CommaExpr.CType := IVType;
    CommaExpr.OperationType := IVType;
    PostExpr := CommaExpr;
  end;
  S.Expr2 := PostExpr;
  Inc(Stats.StrengthReductions, FinalCount);
  Result := S;
end;

function ExprHoistable(E: TExpr; const Modified: TNameArray;
  var HasVariable: Boolean): Boolean;
var
  I: LongInt;
begin
  if E = nil then Exit(False);
  case E.Kind of
    ekInteger, ekFloat, ekString: Result := True;
    ekVariable:
      begin
        if E.CType.IsVolatile then Exit(False);
        if NameInArray(Modified, E.Text) then Exit(False);
        HasVariable := True;
        Result := True;
      end;
    ekUnary: Result := ExprHoistable(E.Left, Modified, HasVariable);
    ekBinary:
      Result := ExprHoistable(E.Left, Modified, HasVariable) and
        ExprHoistable(E.Right, Modified, HasVariable);
    ekCast: Result := ExprHoistable(E.Left, Modified, HasVariable);
  else
    Result := False;
  end;
end;

procedure FindLICMCandidates(E: TExpr; const Modified: TNameArray;
  var Candidates: array of TExpr; var Count: LongInt);
var
  I: LongInt;
  HasVar: Boolean;
begin
  if E = nil then Exit;
  if (E.Kind in [ekUnary, ekBinary, ekCast]) then
  begin
    HasVar := False;
    if ExprHoistable(E, Modified, HasVar) and HasVar then
    begin
      if Count <= High(Candidates) then
      begin
        Candidates[Count] := E;
        Inc(Count);
      end;
      Exit;
    end;
  end;
  FindLICMCandidates(E.Left, Modified, Candidates, Count);
  FindLICMCandidates(E.Right, Modified, Candidates, Count);
  FindLICMCandidates(E.Third, Modified, Candidates, Count);
  for I := 0 to High(E.Args) do
    FindLICMCandidates(E.Args[I], Modified, Candidates, Count);
end;

procedure FindLICMCandidatesStmt(S: TStmt; const Modified: TNameArray;
  var Candidates: array of TExpr; var Count: LongInt);
var
  I: LongInt;
begin
  if S = nil then Exit;
  FindLICMCandidates(S.Expr, Modified, Candidates, Count);
  FindLICMCandidates(S.Expr2, Modified, Candidates, Count);
  for I := 0 to High(S.Children) do
    FindLICMCandidatesStmt(S.Children[I], Modified, Candidates, Count);
  FindLICMCandidatesStmt(S.InitStmt, Modified, Candidates, Count);
  FindLICMCandidatesStmt(S.Body, Modified, Candidates, Count);
  FindLICMCandidatesStmt(S.ElseBody, Modified, Candidates, Count);
end;

function ReplaceExprNode(var E: TExpr; Target: TExpr; NewE: TExpr): Boolean;
var
  I: LongInt;
begin
  Result := False;
  if E = nil then Exit;
  if E = Target then
  begin
    E := NewE;
    Result := True;
    Exit;
  end;
  if ReplaceExprNode(E.Left, Target, NewE) then Exit(True);
  if ReplaceExprNode(E.Right, Target, NewE) then Exit(True);
  if ReplaceExprNode(E.Third, Target, NewE) then Exit(True);
  for I := 0 to High(E.Args) do
    if ReplaceExprNode(E.Args[I], Target, NewE) then Exit(True);
end;

function ReplaceNodeInStmt(S: TStmt; Target: TExpr; NewE: TExpr): Boolean;
var
  I: LongInt;
begin
  Result := False;
  if S = nil then Exit;
  if ReplaceExprNode(S.Expr, Target, NewE) then Exit(True);
  if ReplaceExprNode(S.Expr2, Target, NewE) then Exit(True);
  for I := 0 to High(S.Children) do
    if ReplaceNodeInStmt(S.Children[I], Target, NewE) then Exit(True);
  if ReplaceNodeInStmt(S.InitStmt, Target, NewE) then Exit(True);
  if ReplaceNodeInStmt(S.Body, Target, NewE) then Exit(True);
  if ReplaceNodeInStmt(S.ElseBody, Target, NewE) then Exit(True);
end;

function TryLICMFor(S: TStmt; var Stats: TAdvancedASTOptStats): TStmt;
var
  Info, Info2: TScanInfo;
  I, K, N: LongInt;
  Modified: TNameArray;
  Candidates: array of TExpr;
  CandidateCount: LongInt;
  Decl: TStmt;
  InitBlock: TStmt;
  CloneE: TExpr;
  VarE: TExpr;
begin
  Result := nil;
  if S = nil then Exit;
  Info := CollectModsStmt(S.Body);
  Info2 := CollectModsExpr(S.Expr);
  MergeScanInfo(Info, Info2);
  Info2 := CollectModsExpr(S.Expr2);
  MergeScanInfo(Info, Info2);
  if Info.HasCallOrPtr then Exit;
  if Info.HasVolatile then Exit;
  Modified := Info.Modified;
  SetLength(Candidates, 64);
  CandidateCount := 0;
  FindLICMCandidatesStmt(S.Body, Modified, Candidates, CandidateCount);
  FindLICMCandidates(S.Expr, Modified, Candidates, CandidateCount);
  FindLICMCandidates(S.Expr2, Modified, Candidates, CandidateCount);
  N := CandidateCount;
  if N = 0 then Exit;
  if S.InitStmt = nil then
  begin
    InitBlock := TStmt.Create(skBlock, S.Pos);
    InitBlock.IsDeclarationGroup := True;
    S.InitStmt := InitBlock;
  end
  else if S.InitStmt.Kind in [skDecl, skExpr] then
  begin
    InitBlock := TStmt.Create(skBlock, S.InitStmt.Pos);
    InitBlock.IsDeclarationGroup := True;
    SetLength(InitBlock.Children, 1);
    InitBlock.Children[0] := S.InitStmt;
    S.InitStmt := InitBlock;
  end
  else if S.InitStmt.Kind = skBlock then
  begin
    InitBlock := S.InitStmt;
    InitBlock.IsDeclarationGroup := True;
  end
  else
    Exit;
  for K := 0 to N - 1 do
  begin
    Decl := TStmt.Create(skDecl, S.Pos);
    Decl.Name := '__li' + IntToStr(K);
    Decl.CType := DefaultIntType;
    CloneE := CloneExpr(Candidates[K]);
    Decl.Expr := CloneE;
    SetLength(InitBlock.Children, Length(InitBlock.Children) + 1);
    InitBlock.Children[High(InitBlock.Children)] := Decl;
    VarE := TExpr.Create(ekVariable, S.Pos);
    VarE.Text := Decl.Name;
    VarE.CType := DefaultIntType;
    VarE.OperationType := DefaultIntType;
    VarE.IsLValue := False;
    if not ReplaceNodeInStmt(S.Body, Candidates[K], VarE) then
    begin
      if not ReplaceExprNode(S.Expr, Candidates[K], VarE) then
        ReplaceExprNode(S.Expr2, Candidates[K], VarE);
    end;
    Inc(Stats.ExpressionsHoisted);
  end;
  Result := S;
end;

function TryLICMWhile(S: TStmt; var Stats: TAdvancedASTOptStats): TStmt;
var
  Info, Info2: TScanInfo;
  I, K, N: LongInt;
  Modified: TNameArray;
  Candidates: array of TExpr;
  CandidateCount: LongInt;
  Decl: TStmt;
  Block: TStmt;
  CloneE: TExpr;
  VarE: TExpr;
begin
  Result := nil;
  if S = nil then Exit;
  Info := CollectModsStmt(S.Body);
  Info2 := CollectModsExpr(S.Expr);
  MergeScanInfo(Info, Info2);
  if Info.HasCallOrPtr then Exit;
  if Info.HasVolatile then Exit;
  Modified := Info.Modified;
  SetLength(Candidates, 64);
  CandidateCount := 0;
  FindLICMCandidatesStmt(S.Body, Modified, Candidates, CandidateCount);
  FindLICMCandidates(S.Expr, Modified, Candidates, CandidateCount);
  N := CandidateCount;
  if N = 0 then Exit;
  Block := TStmt.Create(skBlock, S.Pos);
  SetLength(Block.Children, N + 1);
  for K := 0 to N - 1 do
  begin
    Decl := TStmt.Create(skDecl, S.Pos);
    Decl.Name := '__li' + IntToStr(K);
    Decl.CType := DefaultIntType;
    CloneE := CloneExpr(Candidates[K]);
    Decl.Expr := CloneE;
    Block.Children[K] := Decl;
    VarE := TExpr.Create(ekVariable, S.Pos);
    VarE.Text := Decl.Name;
    VarE.CType := DefaultIntType;
    VarE.OperationType := DefaultIntType;
    VarE.IsLValue := False;
    if not ReplaceNodeInStmt(S.Body, Candidates[K], VarE) then
      ReplaceExprNode(S.Expr, Candidates[K], VarE);
    Inc(Stats.ExpressionsHoisted);
  end;
  Block.Children[N] := S;
  Result := Block;
end;

function LoopOptStmt(S: TStmt; Level: LongInt;
  var Stats: TAdvancedASTOptStats): TStmt;
var
  R: TStmt;
  I: LongInt;
begin
  if S = nil then Exit(nil);
  Result := S;
  case S.Kind of
    skFor:
      begin
        R := TryUnrollFor(S, Stats);
        if R = nil then R := TryStrengthReduceFor(S, Stats);
        if R = nil then R := TryLICMFor(S, Stats);
        if R <> nil then Result := R;
      end;
    skWhile, skDoWhile:
      begin
        R := TryLICMWhile(S, Stats);
        if R <> nil then Result := R;
      end;
  end;
  Result.InitStmt := LoopOptStmt(Result.InitStmt, Level, Stats);
  Result.Body := LoopOptStmt(Result.Body, Level, Stats);
  Result.ElseBody := LoopOptStmt(Result.ElseBody, Level, Stats);
  for I := 0 to High(Result.Children) do
    Result.Children[I] := LoopOptStmt(Result.Children[I], Level, Stats);
end;

procedure RunASTLoopOptimization(AProgram: TProgram; ALevel: LongInt;
  out AStats: TAdvancedASTOptStats);
var
  I: LongInt;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  if ALevel < 3 then Exit;
  for I := 0 to High(AProgram.Functions) do
  begin
    if AProgram.Functions[I].IsPrototype then Continue;
    AProgram.Functions[I].Body :=
      LoopOptStmt(AProgram.Functions[I].Body, ALevel, AStats);
  end;
end;

end.
