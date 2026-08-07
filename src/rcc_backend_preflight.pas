unit rcc_backend_preflight;

{$mode objfpc}{$H+}

interface

uses
  rcc_types, rcc_arch;

{ Validate target/backend limitations before optimization and code generation.
  This pass is intentionally linear and allocation-free so unsupported input
  fails after semantic analysis instead of after expensive optimization. }
procedure ValidateBackendSupport(AProgram: TProgram;
  const ATarget: TTargetDescriptor);

implementation

uses
  SysUtils, rcc_typeops;

function DirectLongDouble(const AType: TCType): Boolean;
begin
  Result := (AType.PointerDepth = 0) and (AType.Kind = ctLongDouble);
end;

function TypeContainsUnsupportedScalar(const AType: TCType;
  ARejectAllFloating: Boolean): Boolean;
var
  ElementType, MemberType: TCType;
  Parameters: PFunctionParameterList;
  I: LongInt;
begin
  Result := False;
  if AType.PointerDepth > 0 then Exit;
  if DirectLongDouble(AType) then Exit(True);
  if ARejectAllFloating and (AType.Kind in [ctFloat, ctDouble, ctLongDouble]) then
    Exit(True);
  if AType.Kind = ctArray then
    Exit(TypeContainsUnsupportedScalar(ArrayElementType(AType),
      ARejectAllFloating));
  if (AType.Kind in [ctStruct, ctUnion]) and (AType.StructInfo <> nil) then
    for I := 0 to High(AType.StructInfo^.Members) do
    begin
      MemberType := PCType(AType.StructInfo^.Members[I].CType)^;
      if TypeContainsUnsupportedScalar(MemberType, ARejectAllFloating) then
        Exit(True);
    end;
  if (AType.Kind = ctFunction) and (AType.ReturnType <> nil) then
  begin
    ElementType := PCType(AType.ReturnType)^;
    if TypeContainsUnsupportedScalar(ElementType, ARejectAllFloating) then
      Exit(True);
    if AType.ParamTypes <> nil then
    begin
      Parameters := PFunctionParameterList(AType.ParamTypes);
      for I := 0 to High(Parameters^.Items) do
        if TypeContainsUnsupportedScalar(Parameters^.Items[I],
          ARejectAllFloating) then Exit(True);
    end;
  end;
end;

procedure RejectType(const AType: TCType; const APos: TSourcePos;
  ARejectAllFloating: Boolean; const AContext: string);
begin
  if not TypeContainsUnsupportedScalar(AType, ARejectAllFloating) then Exit;
  if ARejectAllFloating then
    RaiseCompileError(APos, AContext +
      ' uses floating-point data outside the current cross-target integer backend')
  else
    RaiseCompileError(APos, AContext +
      ' uses long double, which is not supported by the x86-64 backend');
end;

function FunctionSignatureUsesLongDouble(F: TFunction): Boolean;
var
  J: LongInt;
begin
  Result := False;
  if F = nil then Exit;
  if TypeContainsUnsupportedScalar(F.ReturnType, False) then Exit(True);
  for J := 0 to High(F.Params) do
    if TypeContainsUnsupportedScalar(F.Params[J].CType, False) then Exit(True);
  Result := False;
end;

function FunctionTypeUsesLongDouble(const AType: TCType): Boolean;
var
  J: LongInt;
  Params: PFunctionParameterList;
begin
  Result := False;
  if (AType.ReturnType = nil) or
    TypeContainsUnsupportedScalar(PCType(AType.ReturnType)^, False) then Exit(True);
  if AType.ParamTypes <> nil then
  begin
    Params := PFunctionParameterList(AType.ParamTypes);
    for J := 0 to High(Params^.Items) do
      if TypeContainsUnsupportedScalar(Params^.Items[J], False) then Exit(True);
  end;
  Result := False;
end;

procedure RejectUnsupportedCallABI(E: TExpr; AProgram: TProgram);
var
  I, GPCount, FPCount: LongInt;
  HasFloating, HasKnownSignature: Boolean;
  Callee: TFunction;
  FunctionType: TCType;
begin
  if (E = nil) or (E.Kind <> ekCall) then Exit;

  { Declared direct calls and typed function-pointer calls use the complete
    SysV classifier.  Only the legacy unprototyped/missing-signature path has
    fixed register-only limits, so reject those limits here before any
    optimization work is attempted. }
  HasKnownSignature := False;
  if E.Text <> '' then
  begin
    Callee := AProgram.FindFunction(E.Text);
    HasKnownSignature := Callee <> nil;
    if HasKnownSignature and FunctionSignatureUsesLongDouble(Callee) then
      RaiseCompileError(E.Pos, 'call to function ''' + E.Text +
        ''' uses long double, which is not supported by the x86-64 backend');
  end
  else if E.Left <> nil then
  begin
    FunctionType := DecayType(E.Left.CType);
    if IsPointerType(FunctionType) then FunctionType := PointeeType(FunctionType);
    HasKnownSignature := (FunctionType.Kind = ctFunction) and
      HasFunctionSignature(FunctionType);
    if HasKnownSignature and FunctionTypeUsesLongDouble(FunctionType) then
      RaiseCompileError(E.Pos,
        'call through function pointer uses long double, which is not supported ' +
        'by the x86-64 backend');
  end;
  if HasKnownSignature then Exit;

  GPCount := 0;
  FPCount := 0;
  HasFloating := False;
  for I := 0 to High(E.Args) do
    if IsFloatingType(DecayType(E.Args[I].CType)) then
    begin
      HasFloating := True;
      Inc(FPCount);
    end
    else
      Inc(GPCount);
  if not HasFloating then Exit;
  if FPCount > 8 then
    RaiseCompileError(E.Pos,
      'calls with more than eight SSE register arguments exceed the current ABI lowering limit');
  if GPCount > 6 then
    RaiseCompileError(E.Pos,
      'mixed floating calls with stack-class integer arguments exceed the current ABI lowering limit');
end;

procedure ScanExpr(E: TExpr; AProgram: TProgram;
  ARejectAllFloating: Boolean);
var
  I: LongInt;
begin
  if E = nil then Exit;
  RejectType(E.CType, E.Pos, ARejectAllFloating, 'expression');
  RejectType(E.OperationType, E.Pos, ARejectAllFloating, 'operation');
  RejectUnsupportedCallABI(E, AProgram);
  ScanExpr(E.Left, AProgram, ARejectAllFloating);
  ScanExpr(E.Right, AProgram, ARejectAllFloating);
  ScanExpr(E.Third, AProgram, ARejectAllFloating);
  for I := 0 to High(E.Args) do
    ScanExpr(E.Args[I], AProgram, ARejectAllFloating);
end;

procedure ScanStmt(S: TStmt; AProgram: TProgram;
  ARejectAllFloating: Boolean);
var
  I: LongInt;
begin
  if S = nil then Exit;
  if S.Kind = skDecl then
    RejectType(S.CType, S.Pos, ARejectAllFloating, 'declaration ''' + S.Name + '''');
  ScanExpr(S.Expr, AProgram, ARejectAllFloating);
  ScanExpr(S.Expr2, AProgram, ARejectAllFloating);
  ScanStmt(S.InitStmt, AProgram, ARejectAllFloating);
  ScanStmt(S.Body, AProgram, ARejectAllFloating);
  ScanStmt(S.ElseBody, AProgram, ARejectAllFloating);
  for I := 0 to High(S.Children) do
    ScanStmt(S.Children[I], AProgram, ARejectAllFloating);
  for I := 0 to High(S.AsmOutputs) do
    ScanExpr(S.AsmOutputs[I].Expr, AProgram, ARejectAllFloating);
  for I := 0 to High(S.AsmInputs) do
    ScanExpr(S.AsmInputs[I].Expr, AProgram, ARejectAllFloating);
end;

procedure ValidateBackendSupport(AProgram: TProgram;
  const ATarget: TTargetDescriptor);
var
  I, J: LongInt;
  F: TFunction;
  RejectAllFloating: Boolean;
begin
  if AProgram = nil then Exit;
  RejectAllFloating := ATarget.Architecture <> archX86_64;

  for I := 0 to High(AProgram.Functions) do
  begin
    F := AProgram.Functions[I];
    { Prototypes from system headers (e.g. `strtold`) are only checked when the
      function is actually used; a bare declaration must not fail a program
      that never touches long double. Defined functions are checked directly. }
    if not F.IsPrototype then
    begin
      RejectType(F.ReturnType, F.Pos, RejectAllFloating,
        'return type of function ''' + F.Name + '''');
      for J := 0 to High(F.Params) do
        RejectType(F.Params[J].CType, F.Pos, RejectAllFloating,
          'parameter ''' + F.Params[J].Name + ''' of function ''' + F.Name +
          '''');
      ScanStmt(F.Body, AProgram, RejectAllFloating);
    end;
  end;

  for I := 0 to High(AProgram.Globals) do
  begin
    RejectType(AProgram.Globals[I].CType, AProgram.Globals[I].Pos,
      RejectAllFloating, 'global ''' + AProgram.Globals[I].Name + '''');
    ScanExpr(AProgram.Globals[I].Initializer, AProgram, RejectAllFloating);
  end;
end;

end.
