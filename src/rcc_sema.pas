unit rcc_sema;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;

procedure AnalyzeProgram(AProgram: TProgram);

implementation

uses
  SysUtils, rcc_typeops;

type
  TSymbolKind = (symLocal, symGlobal, symFunction);

  TSymbol = record
    Name: string;
    CType: TCType;
    Kind: TSymbolKind;
    ScopeDepth: LongInt;
  end;

  TSemanticAnalyzer = class
  private
    FProgram: TProgram;
    FSymbols: array of TSymbol;
    FScopeDepth: LongInt;
    FCurrentFunction: TFunction;
    procedure AddSymbol(const AName: string; const AType: TCType;
      AKind: TSymbolKind; const APos: TSourcePos);
    function FindSymbol(const AName: string; out ASymbol: TSymbol): Boolean;
    function FindFunction(const AName: string): TFunction;
    function EditDistance(const A, B: string): LongInt;
    function SuggestSymbol(const AName: string): string;
    function SuggestMember(const AType: TCType; const AName: string): string;
    function IntegerTypeForValue(AValue: Int64;
      const ALiteralText: string): TCType;
    function ArithmeticResultType(const A, B: TCType): TCType;
    function PromotedExpressionType(E: TExpr): TCType;
    function EvaluateIntegerConstant(E: TExpr; out AValue: Int64): Boolean;
    function CompatibleGenericType(const A, B: TCType): Boolean;
    procedure AdoptExpression(ADestination, ASource: TExpr);
    procedure AnalyzeExpr(E: TExpr);
    procedure AnalyzeInitializer(E: TExpr; const AExpectedType: TCType);
    procedure AnalyzeStmt(S: TStmt);
    procedure AnalyzeFunction(F: TFunction);
    procedure InstallFileSymbols;
  public
    constructor Create(AProgram: TProgram);
    procedure Run;
  end;

constructor TSemanticAnalyzer.Create(AProgram: TProgram);
begin
  inherited Create;
  FProgram := AProgram;
  FScopeDepth := 0;
end;

procedure TSemanticAnalyzer.AddSymbol(const AName: string;
  const AType: TCType; AKind: TSymbolKind; const APos: TSourcePos);
var
  I, N: LongInt;
begin
  if AName = '' then Exit;
  for I := High(FSymbols) downto 0 do
  begin
    if FSymbols[I].ScopeDepth < FScopeDepth then Break;
    if (FSymbols[I].ScopeDepth = FScopeDepth) and
      (FSymbols[I].Name = AName) then
    begin
      if (FScopeDepth = 0) and
        (FSymbols[I].Kind = AKind) and TypesEqual(FSymbols[I].CType, AType) then
        Exit;
      RaiseCompileError(APos, 'redefinition of ''' + AName + '''');
    end;
  end;
  N := Length(FSymbols);
  SetLength(FSymbols, N + 1);
  FSymbols[N].Name := AName;
  FSymbols[N].CType := AType;
  FSymbols[N].Kind := AKind;
  FSymbols[N].ScopeDepth := FScopeDepth;
end;

function TSemanticAnalyzer.FindSymbol(const AName: string;
  out ASymbol: TSymbol): Boolean;
var
  I: LongInt;
begin
  for I := High(FSymbols) downto 0 do
    if FSymbols[I].Name = AName then
    begin
      ASymbol := FSymbols[I];
      Exit(True);
    end;
  Result := False;
end;

function TSemanticAnalyzer.FindFunction(const AName: string): TFunction;
var
  I: LongInt;
begin

  for I := High(FProgram.Functions) downto 0 do
    if FProgram.Functions[I].Name = AName then
      Exit(FProgram.Functions[I]);
  Result := nil;
end;

function TSemanticAnalyzer.EditDistance(const A, B: string): LongInt;
var
  PreviousRow, CurrentRow: array of LongInt;
  I, J, DeleteCost, InsertCost, ReplaceCost, Best: LongInt;
begin
  if A = B then Exit(0);
  if A = '' then Exit(Length(B));
  if B = '' then Exit(Length(A));
  SetLength(PreviousRow, Length(B) + 1);
  SetLength(CurrentRow, Length(B) + 1);
  for J := 0 to Length(B) do PreviousRow[J] := J;
  for I := 1 to Length(A) do
  begin
    CurrentRow[0] := I;
    for J := 1 to Length(B) do
    begin
      DeleteCost := PreviousRow[J] + 1;
      InsertCost := CurrentRow[J - 1] + 1;
      ReplaceCost := PreviousRow[J - 1];
      if A[I] <> B[J] then Inc(ReplaceCost);
      Best := DeleteCost;
      if InsertCost < Best then Best := InsertCost;
      if ReplaceCost < Best then Best := ReplaceCost;
      CurrentRow[J] := Best;
    end;
    PreviousRow := Copy(CurrentRow, 0, Length(CurrentRow));
  end;
  Result := PreviousRow[Length(B)];
end;

function SuggestionThreshold(ALength: LongInt): LongInt;
begin
  if ALength <= 3 then Result := 1
  else if ALength <= 7 then Result := 2
  else Result := 3;
end;

function TSemanticAnalyzer.SuggestSymbol(const AName: string): string;
var
  I, Distance, BestDistance: LongInt;
begin
  Result := '';
  BestDistance := SuggestionThreshold(Length(AName)) + 1;
  for I := High(FSymbols) downto 0 do
  begin
    if FSymbols[I].Name = AName then Continue;
    Distance := EditDistance(AName, FSymbols[I].Name);
    if Distance < BestDistance then
    begin
      BestDistance := Distance;
      Result := FSymbols[I].Name;
    end;
  end;
  if BestDistance > SuggestionThreshold(Length(AName)) then Result := '';
end;

function TSemanticAnalyzer.SuggestMember(const AType: TCType;
  const AName: string): string;
var
  I, Distance, BestDistance: LongInt;
begin
  Result := '';
  if AType.StructInfo = nil then Exit;
  BestDistance := SuggestionThreshold(Length(AName)) + 1;
  for I := 0 to High(AType.StructInfo^.Members) do
  begin
    if AType.StructInfo^.Members[I].Name = '' then Continue;
    Distance := EditDistance(AName, AType.StructInfo^.Members[I].Name);
    if Distance < BestDistance then
    begin
      BestDistance := Distance;
      Result := AType.StructInfo^.Members[I].Name;
    end;
  end;
  if BestDistance > SuggestionThreshold(Length(AName)) then Result := '';
end;

function WithSuggestion(const AMessage, ASuggestion: string): string;
begin
  Result := AMessage;
  if ASuggestion <> '' then
    Result := Result + '; did you mean ''' + ASuggestion + '''?';
end;

function TSemanticAnalyzer.IntegerTypeForValue(AValue: Int64;
  const ALiteralText: string): TCType;
var
  I, LongCount: LongInt;
  HasUnsignedSuffix, HasIntegerSuffix: Boolean;
  Bits: QWord;
begin




  I := Length(ALiteralText);
  LongCount := 0;
  HasUnsignedSuffix := False;
  HasIntegerSuffix := False;
  while (I > 0) and (ALiteralText[I] in ['u', 'U', 'l', 'L']) do
  begin
    HasIntegerSuffix := True;
    if ALiteralText[I] in ['u', 'U'] then
      HasUnsignedSuffix := True
    else
      Inc(LongCount);
    Dec(I);
  end;

  if HasIntegerSuffix then
  begin
    Bits := QWord(AValue);
    if LongCount >= 2 then
      Result := MakeType(ctLongLong, HasUnsignedSuffix)
    else if LongCount = 1 then
      Result := MakeType(ctLong, HasUnsignedSuffix)
    else if HasUnsignedSuffix then
    begin
      if Bits <= QWord(High(Cardinal)) then
        Result := MakeType(ctInt, True)
      else
        Result := MakeType(ctLong, True);
    end
    else
      Result := MakeType(ctInt);
    Exit;
  end;

  if (AValue >= Low(LongInt)) and (AValue <= High(LongInt)) then
    Result := MakeType(ctInt)
  else
    Result := MakeType(ctLongLong);
end;

function TypeRank(const AType: TCType): LongInt;
begin
  if AType.PointerDepth > 0 then Exit(100);
  case AType.Kind of
    ctBool: Result := 0;
    ctChar: Result := 1;
    ctShort: Result := 2;
    ctInt, ctEnum: Result := 3;
    ctLong: Result := 4;
    ctLongLong: Result := 5;
    ctFloat: Result := 6;
    ctDouble: Result := 7;
    ctLongDouble: Result := 8;
  else
    Result := 3;
  end;
end;

function PromotedIntegerType(const AType: TCType): TCType;
begin
  if not IsIntegerType(AType) then Exit(AType);
  if TypeRank(AType) < TypeRank(MakeType(ctInt)) then
    Exit(MakeType(ctInt));
  Result := MakeType(AType.Kind, AType.IsUnsigned);
end;

function UnsignedVersion(const AType: TCType): TCType;
begin
  Result := MakeType(AType.Kind, True);
end;

function TSemanticAnalyzer.PromotedExpressionType(E: TExpr): TCType;
begin
  if E = nil then Exit(MakeType(ctInt));
  Result := DecayType(E.CType);
  if not IsIntegerType(Result) then Exit;
  if E.IsBitField and (TypeRank(Result) <= TypeRank(MakeType(ctInt))) then
  begin


    if E.BitWidth < 32 then Result := MakeType(ctInt)
    else Result := MakeType(ctInt, Result.IsUnsigned);
    Exit;
  end;
  Result := PromotedIntegerType(Result);
end;

function TSemanticAnalyzer.ArithmeticResultType(const A, B: TCType): TCType;
var
  LeftType, RightType, SignedType, UnsignedType: TCType;
  LeftRank, RightRank: LongInt;
begin
  LeftType := DecayType(A);
  RightType := DecayType(B);

  if IsFloatingType(LeftType) or IsFloatingType(RightType) then
  begin
    if (LeftType.Kind = ctLongDouble) or (RightType.Kind = ctLongDouble) then
      Exit(MakeType(ctLongDouble));
    if (LeftType.Kind = ctDouble) or (RightType.Kind = ctDouble) then
      Exit(MakeType(ctDouble));
    Exit(MakeType(ctFloat));
  end;

  LeftType := PromotedIntegerType(LeftType);
  RightType := PromotedIntegerType(RightType);
  LeftRank := TypeRank(LeftType);
  RightRank := TypeRank(RightType);

  if LeftType.IsUnsigned = RightType.IsUnsigned then
  begin
    if LeftRank >= RightRank then Result := LeftType else Result := RightType;
    Exit;
  end;

  if LeftType.IsUnsigned then
  begin
    UnsignedType := LeftType;
    SignedType := RightType;
  end
  else
  begin
    UnsignedType := RightType;
    SignedType := LeftType;
  end;

  if TypeRank(UnsignedType) >= TypeRank(SignedType) then
    Exit(UnsignedType);




  if CTypeSize(SignedType) > CTypeSize(UnsignedType) then
    Exit(SignedType);
  Result := UnsignedVersion(SignedType);
end;


function TSemanticAnalyzer.CompatibleGenericType(const A, B: TCType): Boolean;
var
  LeftType, RightType: TCType;
begin
  LeftType := A;
  RightType := B;
  LeftType.IsConst := False;
  LeftType.IsVolatile := False;
  RightType.IsConst := False;
  RightType.IsVolatile := False;
  if (LeftType.Kind in [ctStruct, ctUnion]) and
    (RightType.Kind = LeftType.Kind) and
    (LeftType.PointerDepth = RightType.PointerDepth) and
    (LeftType.StructInfo <> nil) and (RightType.StructInfo <> nil) and
    (LeftType.StructInfo^.Name <> '') and
    (LeftType.StructInfo^.Name = RightType.StructInfo^.Name) then
    Exit(True);
  Result := TypesEqual(LeftType, RightType);
end;

procedure TSemanticAnalyzer.AdoptExpression(ADestination, ASource: TExpr);
begin
  if (ADestination = nil) or (ASource = nil) then
    raise ERCCError.Create('internal error: invalid generic expression adoption');
  ADestination.Kind := ASource.Kind;
  ADestination.Pos := ASource.Pos;
  ADestination.IntValue := ASource.IntValue;
  ADestination.FloatValue := ASource.FloatValue;
  ADestination.Text := ASource.Text;
  ADestination.UnaryOp := ASource.UnaryOp;
  ADestination.BinaryOp := ASource.BinaryOp;
  ADestination.AssignOp := ASource.AssignOp;
  ADestination.Left := ASource.Left;
  ADestination.Right := ASource.Right;
  ADestination.Third := ASource.Third;
  ADestination.Args := ASource.Args;
  ADestination.CType := ASource.CType;
  ADestination.IsLValue := ASource.IsLValue;
  ADestination.IsFunctionDesignator := ASource.IsFunctionDesignator;
  ADestination.IsBitField := ASource.IsBitField;
  ADestination.BitOffset := ASource.BitOffset;
  ADestination.BitWidth := ASource.BitWidth;
  ADestination.BitStorageSize := ASource.BitStorageSize;
  ASource.Left := nil;
  ASource.Right := nil;
  ASource.Third := nil;
  SetLength(ASource.Args, 0);
  ASource.Free;
end;

function TSemanticAnalyzer.EvaluateIntegerConstant(E: TExpr;
  out AValue: Int64): Boolean;
begin
  Result := EvaluateIntegerConstantExpression(E, AValue);
end;

procedure TSemanticAnalyzer.AnalyzeInitializer(E: TExpr;
  const AExpectedType: TCType);
var
  I, J, NextIndex, MemberIndex: LongInt;
  ElementType: TCType;
  Reordered: TExprArray;
  Item: TExpr;
  Designator: string;
begin
  if E = nil then Exit;
  E.CType := AExpectedType;
  if E.Kind <> ekCompoundLit then
  begin
    AnalyzeExpr(E);
    Exit;
  end;

  if AExpectedType.Kind = ctArray then
  begin
    ElementType := ElementTypeOf(AExpectedType);
    for I := 0 to High(E.Args) do
      AnalyzeInitializer(E.Args[I], ElementType);
  end
  else if AExpectedType.Kind in [ctStruct, ctUnion] then
  begin
    if AExpectedType.StructInfo = nil then
      RaiseCompileError(E.Pos, 'initializer uses incomplete aggregate type');
    SetLength(Reordered, Length(AExpectedType.StructInfo^.Members));
    for I := 0 to High(Reordered) do Reordered[I] := nil;
    NextIndex := 0;
    for I := 0 to High(E.Args) do
    begin
      Item := E.Args[I];
      MemberIndex := -1;
      if (Item <> nil) and (Length(Item.Text) > 1) and
        (Item.Text[1] = '.') then
      begin
        Designator := Copy(Item.Text, 2, MaxInt);
        for J := 0 to High(AExpectedType.StructInfo^.Members) do
          if AExpectedType.StructInfo^.Members[J].Name = Designator then
          begin
            MemberIndex := J;
            Break;
          end;
        if MemberIndex < 0 then
          RaiseCompileError(Item.Pos,
            'unknown designated member ''' + Designator + '''');
        Item.Text := '';
        NextIndex := MemberIndex + 1;
      end
      else
      begin
        while (NextIndex <= High(Reordered)) and
          (Reordered[NextIndex] <> nil) do Inc(NextIndex);
        MemberIndex := NextIndex;
        Inc(NextIndex);
      end;
      if MemberIndex > High(Reordered) then
        RaiseCompileError(Item.Pos, 'too many values in aggregate initializer');
      if Reordered[MemberIndex] <> nil then
        RaiseCompileError(Item.Pos, 'aggregate member initialized twice');
      Reordered[MemberIndex] := Item;
      AnalyzeInitializer(Item,
        PCType(AExpectedType.StructInfo^.Members[MemberIndex].CType)^);
      if AExpectedType.Kind = ctUnion then Break;
    end;
    E.Args := Reordered;
  end
  else
    for I := 0 to High(E.Args) do AnalyzeExpr(E.Args[I]);
end;

procedure TSemanticAnalyzer.AnalyzeExpr(E: TExpr);
var
  Sym: TSymbol;
  FunctionDecl: TFunction;
  Member: TStructMember;
  BaseType, LeftType, RightType, TempType: TCType;
  I, J, SelectedIndex, DefaultIndex: LongInt;
  TempExpr, SelectedExpr: TExpr;
  S: Int64;
begin
  if E = nil then Exit;
  case E.Kind of
    ekInteger:
      E.CType := IntegerTypeForValue(E.IntValue, E.Text);

    ekTrap:
      begin
        E.CType := MakeType(ctVoid);
        E.IsLValue := False;
      end;

    ekNullptr:
      begin
        E.Kind := ekInteger;
        E.IntValue := 0;
        E.Text := '';
        E.CType := MakeType(ctVoid, False, 1);
      end;

    ekFloat:
      begin
        if (E.Text <> '') and (E.Text[Length(E.Text)] in ['f', 'F']) then
          E.CType := MakeType(ctFloat)
        else if (E.Text <> '') and (E.Text[Length(E.Text)] in ['l', 'L']) then
          E.CType := MakeType(ctLongDouble)
        else
          E.CType := MakeType(ctDouble);
      end;

    ekString:
      begin
        E.CType := MakeArrayType(MakeType(ctChar), Length(E.Text) + 1);
        E.IsLValue := True;
      end;

    ekVariable:
      begin
        if not FindSymbol(E.Text, Sym) then
          RaiseCompileError(E.Pos, WithSuggestion(
            'unknown identifier ''' + E.Text + '''', SuggestSymbol(E.Text)));
        E.CType := Sym.CType;
        E.IsLValue := Sym.Kind <> symFunction;
        E.IsFunctionDesignator := Sym.Kind = symFunction;
      end;

    ekUnary:
      begin
        AnalyzeExpr(E.Left);
        case E.UnaryOp of
          uoLogicalNot: E.CType := MakeType(ctInt);
          uoPositive, uoNegative:
            begin
              if not IsArithmeticType(E.Left.CType) then
                RaiseCompileError(E.Pos, 'unary operator requires arithmetic type');
              E.CType := PromotedExpressionType(E.Left);
            end;
          uoBitwiseNot:
            begin
              if not IsIntegerType(E.Left.CType) then
                RaiseCompileError(E.Pos,
                  'bitwise complement requires an integer operand');
              E.CType := PromotedExpressionType(E.Left);
            end;
        end;
      end;

    ekAddress:
      begin
        AnalyzeExpr(E.Left);
        if E.Left.IsBitField then
          RaiseCompileError(E.Pos, 'cannot take the address of a bit-field');
        if not E.Left.IsLValue and not E.Left.IsFunctionDesignator then
          RaiseCompileError(E.Pos, 'address operator requires an lvalue');
        E.CType := PointerTo(E.Left.CType);
      end;

    ekDeref:
      begin
        AnalyzeExpr(E.Left);
        LeftType := DecayType(E.Left.CType);
        if not IsPointerType(LeftType) then
          RaiseCompileError(E.Pos, 'dereference requires pointer type');
        E.CType := PointeeType(LeftType);
        E.IsLValue := E.CType.Kind <> ctFunction;
        E.IsFunctionDesignator := E.CType.Kind = ctFunction;
      end;

    ekIndex:
      begin
        AnalyzeExpr(E.Left);
        AnalyzeExpr(E.Right);
        BaseType := DecayType(E.Left.CType);
        if not IsPointerType(BaseType) then
        begin
          BaseType := DecayType(E.Right.CType);
          if IsPointerType(BaseType) then
          begin
            TempExpr := E.Left;
            E.Left := E.Right;
            E.Right := TempExpr;
          end
          else
            RaiseCompileError(E.Pos, 'subscripted value is not an array or pointer');
        end;
        E.CType := PointeeType(BaseType);
        E.IntValue := StorageSize(E.CType);
        E.IsLValue := True;
      end;

    ekMember:
      begin
        AnalyzeExpr(E.Left);
        BaseType := E.Left.CType;
        if not (BaseType.Kind in [ctStruct, ctUnion]) or
          (BaseType.PointerDepth <> 0) then
          RaiseCompileError(E.Pos, 'member access requires struct or union object');
        if not FindMember(BaseType, E.Text, Member) then
          RaiseCompileError(E.Pos, WithSuggestion(
            'aggregate has no member ''' + E.Text + '''',
            SuggestMember(BaseType, E.Text)));
        E.IntValue := Member.Offset;
        E.CType := PCType(Member.CType)^;
        E.IsLValue := E.Left.IsLValue;
        E.IsBitField := Member.IsBitField;
        E.BitOffset := Member.BitOffset;
        E.BitWidth := Member.BitWidth;
        E.BitStorageSize := Member.Width;
      end;

    ekArrow:
      begin
        AnalyzeExpr(E.Left);
        BaseType := DecayType(E.Left.CType);
        if not IsPointerType(BaseType) then
          RaiseCompileError(E.Pos, 'arrow operator requires pointer type');
        BaseType := PointeeType(BaseType);
        if not (BaseType.Kind in [ctStruct, ctUnion]) then
          RaiseCompileError(E.Pos, 'arrow operator requires pointer to aggregate');
        if not FindMember(BaseType, E.Text, Member) then
          RaiseCompileError(E.Pos, WithSuggestion(
            'aggregate has no member ''' + E.Text + '''',
            SuggestMember(BaseType, E.Text)));
        E.IntValue := Member.Offset;
        E.CType := PCType(Member.CType)^;
        E.IsLValue := True;
        E.IsBitField := Member.IsBitField;
        E.BitOffset := Member.BitOffset;
        E.BitWidth := Member.BitWidth;
        E.BitStorageSize := Member.Width;
      end;

    ekBinary:
      begin
        AnalyzeExpr(E.Left);
        AnalyzeExpr(E.Right);
        LeftType := PromotedExpressionType(E.Left);
        RightType := PromotedExpressionType(E.Right);
        if E.BinaryOp = boComma then
        begin
          E.CType := E.Right.CType;
          E.OperationType := E.Right.CType;
          Exit;
        end;
        if E.BinaryOp in [boLogicalAnd, boLogicalOr] then
        begin
          E.CType := MakeType(ctInt);
          E.OperationType := E.CType;
          Exit;
        end;
        if E.BinaryOp in [boEqual, boNotEqual, boLess, boLessEqual,
          boGreater, boGreaterEqual] then
        begin
          E.CType := MakeType(ctInt);
          if IsArithmeticType(LeftType) and IsArithmeticType(RightType) then
            E.OperationType := ArithmeticResultType(LeftType, RightType)
          else if IsPointerType(LeftType) then
            E.OperationType := LeftType
          else
            E.OperationType := RightType;
          Exit;
        end;
        if (E.BinaryOp in [boAdd, boSub]) and IsPointerType(LeftType) and
          IsIntegerType(RightType) then
        begin
          E.CType := LeftType;
          E.OperationType := LeftType;
          E.IntValue := StorageSize(PointeeType(LeftType));
          Exit;
        end;
        if (E.BinaryOp = boAdd) and IsIntegerType(LeftType) and
          IsPointerType(RightType) then
        begin
          TempExpr := E.Left;
          E.Left := E.Right;
          E.Right := TempExpr;
          E.CType := RightType;
          E.OperationType := RightType;
          E.IntValue := StorageSize(PointeeType(RightType));
          Exit;
        end;
        if (E.BinaryOp = boSub) and IsPointerType(LeftType) and
          IsPointerType(RightType) then
        begin
          E.CType := MakeType(ctLong);
          E.OperationType := E.CType;
          E.IntValue := StorageSize(PointeeType(LeftType));
          Exit;
        end;
        if E.BinaryOp in [boMod, boShiftLeft, boShiftRight,
          boBitAnd, boBitXor, boBitOr] then
        begin
          if not IsIntegerType(LeftType) or not IsIntegerType(RightType) then
            RaiseCompileError(E.Pos, 'operator requires integer operands');
        end;
        if E.BinaryOp in [boShiftLeft, boShiftRight] then
        begin
          E.CType := LeftType;
          E.OperationType := LeftType;
          Exit;
        end;
        E.CType := ArithmeticResultType(LeftType, RightType);
        E.OperationType := E.CType;
      end;

    ekAssign:
      begin
        AnalyzeExpr(E.Left);
        AnalyzeExpr(E.Right);
        if not E.Left.IsLValue then
          RaiseCompileError(E.Pos, 'left side of assignment is not modifiable');
        E.CType := E.Left.CType;
      end;

    ekCall:
      begin
        if (E.Text = '__builtin_va_start') or
           (E.Text = '__builtin_va_arg') or
           (E.Text = '__builtin_va_copy') or
           (E.Text = '__builtin_va_end') then
        begin
          for I := 0 to High(E.Args) do AnalyzeExpr(E.Args[I]);
          if E.Text = '__builtin_va_start' then
          begin
            if Length(E.Args) <> 2 then
              RaiseCompileError(E.Pos,
                '__builtin_va_start expects two arguments');
            if (FCurrentFunction = nil) or
              not FCurrentFunction.IsVariadic then
              RaiseCompileError(E.Pos,
                'va_start is valid only inside a variadic function');
            E.CType := MakeType(ctVoid);
          end
          else if E.Text = '__builtin_va_arg' then
          begin
            if Length(E.Args) <> 1 then
              RaiseCompileError(E.Pos,
                '__builtin_va_arg expects a list and a type');
            E.CType := E.OperationType;
            if (E.CType.Kind in [ctVoid, ctFunction]) and
              (E.CType.PointerDepth = 0) then
              RaiseCompileError(E.Pos,
                'va_arg cannot retrieve this type');
            if CTypeSize(E.CType) <= 0 then
              RaiseCompileError(E.Pos,
                'va_arg requires a complete object type');
          end
          else if E.Text = '__builtin_va_copy' then
          begin
            if Length(E.Args) <> 2 then
              RaiseCompileError(E.Pos,
                '__builtin_va_copy expects two arguments');
            E.CType := MakeType(ctVoid);
          end
          else
          begin
            if Length(E.Args) <> 1 then
              RaiseCompileError(E.Pos,
                '__builtin_va_end expects one argument');
            E.CType := MakeType(ctVoid);
          end;
          Exit;
        end;





        if E.Text <> '' then
        begin
          FunctionDecl := FindFunction(E.Text);
          if FunctionDecl = nil then
            RaiseCompileError(E.Pos, WithSuggestion(
              'call to undeclared function ''' + E.Text + '''',
              SuggestSymbol(E.Text)));
          for I := 0 to High(E.Args) do AnalyzeExpr(E.Args[I]);
          E.CType := FunctionDecl.ReturnType;
          if (not FunctionDecl.IsVariadic) and
            (Length(E.Args) <> Length(FunctionDecl.Params)) then
            RaiseCompileError(E.Pos, 'wrong number of arguments to ''' + E.Text + '''');
          if FunctionDecl.IsVariadic and
            (Length(E.Args) < Length(FunctionDecl.Params)) then
            RaiseCompileError(E.Pos,
              'too few arguments to variadic function ''' + E.Text + '''');
        end
        else
        begin
          AnalyzeExpr(E.Left);
          for I := 0 to High(E.Args) do AnalyzeExpr(E.Args[I]);
          LeftType := DecayType(E.Left.CType);
          if IsPointerType(LeftType) then
            LeftType := PointeeType(LeftType);
          if LeftType.Kind <> ctFunction then
            RaiseCompileError(E.Pos, 'called expression is not a function pointer');
          if HasFunctionSignature(LeftType) then
          begin
            E.CType := FunctionReturnTypeOf(LeftType);
            if (not FunctionIsVariadic(LeftType)) and
              (Length(E.Args) <> FunctionParameterCount(LeftType)) then
              RaiseCompileError(E.Pos,
                'wrong number of arguments to function pointer');
            if FunctionIsVariadic(LeftType) and
              (Length(E.Args) < FunctionParameterCount(LeftType)) then
              RaiseCompileError(E.Pos,
                'too few arguments to variadic function pointer');
          end
          else
            E.CType := MakeType(ctInt);
        end;
      end;

    ekConditional:
      begin
        AnalyzeExpr(E.Left);
        AnalyzeExpr(E.Right);
        AnalyzeExpr(E.Third);
        if TypesEqual(E.Right.CType, E.Third.CType) then
          E.CType := E.Right.CType
        else
          E.CType := ArithmeticResultType(E.Right.CType, E.Third.CType);
      end;

    ekPreInc, ekPreDec, ekPostInc, ekPostDec:
      begin
        AnalyzeExpr(E.Left);
        if not E.Left.IsLValue then
          RaiseCompileError(E.Pos, 'increment/decrement requires an lvalue');
        E.CType := E.Left.CType;
        if IsPointerType(DecayType(E.CType)) then
          E.IntValue := StorageSize(PointeeType(DecayType(E.CType)))
        else
          E.IntValue := 1;
      end;

    ekCast:
      begin
        TempType := E.CType;
        AnalyzeExpr(E.Left);
        E.CType := TempType;
      end;

    ekCompoundLit:
      AnalyzeInitializer(E, E.CType);

    ekComma:
      begin
        AnalyzeExpr(E.Left);
        AnalyzeExpr(E.Right);
        E.CType := E.Right.CType;
      end;

    ekGeneric:
      begin
        AnalyzeExpr(E.Left);
        BaseType := DecayType(E.Left.CType);
        BaseType.IsConst := False;
        BaseType.IsVolatile := False;
        SelectedIndex := -1;
        DefaultIndex := -1;
        for I := 0 to High(E.Args) do
        begin
          if E.Args[I].Text = 'default' then
          begin
            if DefaultIndex >= 0 then
              RaiseCompileError(E.Args[I].Pos,
                '_Generic selection has more than one default association');
            DefaultIndex := I;
            Continue;
          end;
          for J := 0 to I - 1 do
            if (E.Args[J].Text <> 'default') and
              CompatibleGenericType(E.Args[I].CType, E.Args[J].CType) then
              RaiseCompileError(E.Args[I].Pos,
                '_Generic selection contains compatible duplicate types');
          if CompatibleGenericType(BaseType, E.Args[I].CType) then
          begin
            if SelectedIndex >= 0 then
              RaiseCompileError(E.Args[I].Pos,
                '_Generic controlling type matches more than one association');
            SelectedIndex := I;
          end;
        end;
        if SelectedIndex < 0 then SelectedIndex := DefaultIndex;
        if SelectedIndex < 0 then
          RaiseCompileError(E.Pos,
            '_Generic controlling type has no compatible association');
        SelectedExpr := E.Args[SelectedIndex].Left;
        E.Args[SelectedIndex].Left := nil;
        AnalyzeExpr(SelectedExpr);
        E.Left.Free;
        E.Left := nil;
        for I := 0 to High(E.Args) do E.Args[I].Free;
        SetLength(E.Args, 0);
        AdoptExpression(E, SelectedExpr);
      end;

    ekSizeof:
      begin
        AnalyzeExpr(E.Left);
        if E.Left.IsBitField then
          RaiseCompileError(E.Pos, 'sizeof cannot be applied to a bit-field');
        S := CTypeSize(E.Left.CType);
        if S <= 0 then RaiseCompileError(E.Pos, 'sizeof applied to incomplete type');
        E.Left.Free;
        E.Left := nil;
        E.Kind := ekInteger;
        E.IntValue := S;
        E.Text := 'UL';
        E.CType := MakeType(ctLong, True);
      end;

    ekAlignof:
      begin
        AnalyzeExpr(E.Left);
        if E.Left.IsBitField then
          RaiseCompileError(E.Pos, '_Alignof cannot be applied to a bit-field');
        S := CTypeAlign(E.Left.CType);
        if S <= 0 then RaiseCompileError(E.Pos, '_Alignof applied to incomplete type');
        E.Left.Free;
        E.Left := nil;
        E.Kind := ekInteger;
        E.IntValue := S;
        E.Text := 'UL';
        E.CType := MakeType(ctLong, True);
      end;
  end;
end;

procedure TSemanticAnalyzer.AnalyzeStmt(S: TStmt);
var
  I, SavedCount, SavedDepth: LongInt;
  ConstantValue: Int64;
  MessageText: string;
begin
  if S = nil then Exit;
  case S.Kind of
    skEmpty, skBreak, skContinue, skGoto, skLabel: ;
    skAsm:
      begin
        for I := 0 to High(S.AsmOutputs) do
        begin
          AnalyzeExpr(S.AsmOutputs[I].Expr);
          if (S.AsmOutputs[I].Expr = nil) or
             not S.AsmOutputs[I].Expr.IsLValue then
            RaiseCompileError(S.Pos,
              'inline assembly output operand must be a modifiable lvalue');
        end;
        for I := 0 to High(S.AsmInputs) do
          AnalyzeExpr(S.AsmInputs[I].Expr);
      end;
    skCase, skDefault: AnalyzeStmt(S.Body);
    skExpr: AnalyzeExpr(S.Expr);
    skStaticAssert:
      begin
        AnalyzeExpr(S.Expr);
        if (S.Expr = nil) or not IsIntegerType(S.Expr.CType) or
          not EvaluateIntegerConstant(S.Expr, ConstantValue) then
          RaiseCompileError(S.Pos,
            '_Static_assert requires an integer constant expression');
        if ConstantValue = 0 then
        begin
          MessageText := S.Name;
          if MessageText <> '' then
            RaiseCompileError(S.Pos, 'static assertion failed: ' + MessageText)
          else
            RaiseCompileError(S.Pos, 'static assertion failed');
        end;
        S.Expr.Free;
        S.Expr := nil;
        S.Kind := skEmpty;
      end;
    skDecl:
      begin
        AddSymbol(S.Name, S.CType, symLocal, S.Pos);
        AnalyzeInitializer(S.Expr, S.CType);
      end;
    skReturn:
      begin
        AnalyzeExpr(S.Expr);
        if (S.Expr <> nil) and (FCurrentFunction <> nil) then
          S.Expr.CType := S.Expr.CType;
      end;
    skBlock:
      begin
        if S.IsDeclarationGroup then
        begin



          for I := 0 to High(S.Children) do AnalyzeStmt(S.Children[I]);
        end
        else
        begin
          SavedCount := Length(FSymbols);
          SavedDepth := FScopeDepth;
          Inc(FScopeDepth);
          for I := 0 to High(S.Children) do AnalyzeStmt(S.Children[I]);
          SetLength(FSymbols, SavedCount);
          FScopeDepth := SavedDepth;
        end;
      end;
    skIf:
      begin
        AnalyzeExpr(S.Expr);
        AnalyzeStmt(S.Body);
        AnalyzeStmt(S.ElseBody);
      end;
    skWhile, skDoWhile:
      begin
        AnalyzeExpr(S.Expr);
        AnalyzeStmt(S.Body);
      end;
    skFor:
      begin
        SavedCount := Length(FSymbols);
        SavedDepth := FScopeDepth;
        Inc(FScopeDepth);
        AnalyzeStmt(S.InitStmt);
        AnalyzeExpr(S.Expr);
        AnalyzeExpr(S.Expr2);
        AnalyzeStmt(S.Body);
        SetLength(FSymbols, SavedCount);
        FScopeDepth := SavedDepth;
      end;
    skSwitch:
      begin
        AnalyzeExpr(S.Expr);
        AnalyzeStmt(S.Body);
      end;
  end;
end;

procedure TSemanticAnalyzer.AnalyzeFunction(F: TFunction);
var
  I, SavedCount: LongInt;
begin
  if F.IsPrototype then Exit;
  FCurrentFunction := F;
  SavedCount := Length(FSymbols);
  FScopeDepth := 1;
  for I := 0 to High(F.Params) do
  begin
    if F.Params[I].Name = '' then
      RaiseCompileError(F.Pos,
        'parameter names are required in function definitions');
    AddSymbol(F.Params[I].Name, F.Params[I].CType, symLocal, F.Pos);
  end;
  AnalyzeStmt(F.Body);
  SetLength(FSymbols, SavedCount);
  FScopeDepth := 0;
  FCurrentFunction := nil;
end;

procedure TSemanticAnalyzer.InstallFileSymbols;
var
  I: LongInt;
  FunctionType: TCType;
begin
  for I := 0 to High(FProgram.Globals) do
    AddSymbol(FProgram.Globals[I].Name, FProgram.Globals[I].CType,
      symGlobal, FProgram.Globals[I].Pos);
  for I := 0 to High(FProgram.Functions) do
  begin
    FunctionType := MakeType(ctFunction);
    AddSymbol(FProgram.Functions[I].Name, FunctionType, symFunction,
      FProgram.Functions[I].Pos);
  end;
end;

procedure TSemanticAnalyzer.Run;
var
  I: LongInt;
begin
  InstallFileSymbols;
  for I := 0 to High(FProgram.StaticAssertions) do
    AnalyzeStmt(FProgram.StaticAssertions[I]);
  for I := 0 to High(FProgram.Globals) do
    AnalyzeInitializer(FProgram.Globals[I].Initializer,
      FProgram.Globals[I].CType);
  for I := 0 to High(FProgram.Functions) do AnalyzeFunction(FProgram.Functions[I]);
end;

procedure AnalyzeProgram(AProgram: TProgram);
var
  Analyzer: TSemanticAnalyzer;
begin
  if AProgram = nil then
    raise ERCCError.Create('internal error: semantic analysis received nil program');
  Analyzer := TSemanticAnalyzer.Create(AProgram);
  try
    Analyzer.Run;
  finally
    Analyzer.Free;
  end;
end;

end.
