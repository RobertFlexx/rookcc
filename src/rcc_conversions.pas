unit rcc_conversions;

{$mode objfpc}{$H+}

interface

uses
  rcc_types, rcc_typeops;

type
  { Result of classifying a potential implicit conversion between two types.
    Callers report diagnostics; every case other than ccValid is an error that
    must be reported. ccWarning is reserved for a future warning-emission path;
    RCC has no such path today, so the classifier never returns ccWarning. }
  TConversionClass = (
    ccValid,
    ccWarning,
    ccConstraintViolation,
    ccInvalid
  );

  { Why an implicit conversion was rejected. Callers select diagnostics from
    this; cpNone means the generic "without a cast" / "incompatible types"
    wording applies. }
  TConversionProblem = (
    cpNone,
    { A single-level pointer target loses const or volatile, e.g. the pointer
      target type of `const char *` when converting to `char *`, or of
      `const void *` when converting to `void *`. }
    cpPointerTargetQualifiers,
    { Nested pointer-to-pointer conversion that would add or remove qualifiers
      at an inner level, e.g. `char **` to `const char **`. }
    cpNestedPointerQualifiers,
    { Function pointer and object pointer cannot convert to each other. }
    cpFunctionObjectPointer,
    { Function pointers with incompatible signatures. }
    cpFunctionPointerMismatch
  );
  PConversionProblem = ^TConversionProblem;

  { True when E is an integer constant expression evaluating to zero, i.e. the
    ISO C null pointer constant (or `nullptr`, which the frontend folds into
    integer 0 with pointer type). Enumeration constants and folded casts of
    integer constants qualify; an ordinary variable that merely holds zero is
    not an integer constant expression and is therefore not a null pointer
    constant. }
  function IsNullPointerConstant(E: TExpr): Boolean;

  { Central classification of an implicit conversion from ASource to
    ADestination. AIsNullPointerConstant only applies when ASource is an
    integer being converted to a pointer. ARequireQualifiers selects strict
    assignment-style compatibility, where the destination pointer target must
    carry every qualifier of the source pointer target; comparisons and
    conditional expressions pass False because C only requires compatible
    pointed-to types there. When AProblem is given it receives the reason a
    conversion was rejected (cpNone for generic incompatibilities). }
  function ClassifyConversion(const ADestination, ASource: TCType;
    AIsNullPointerConstant: Boolean;
    AProblem: PConversionProblem = nil;
    ARequireQualifiers: Boolean = True): TConversionClass;

  { "discards 'const' qualifier from pointer target type" suffix naming the
    qualifier(s) the conversion would drop. Only meaningful when the
    conversion failed with cpPointerTargetQualifiers. }
  function PointerTargetQualifierMessage(const ADestination,
    ASource: TCType): string;

implementation

function IsNullPointerConstant(E: TExpr): Boolean;
var
  V: Int64;
begin
  Result := (E <> nil) and EvaluateIntegerConstantExpression(E, V) and (V = 0);
end;

function TypeCarriesQualifiersOf(const ADestination, ASource: TCType): Boolean;
begin
  Result := ((not ASource.IsConst) or ADestination.IsConst) and
    ((not ASource.IsVolatile) or ADestination.IsVolatile);
end;

function SameTypeIncludingQualifiers(const A, B: TCType): Boolean;
begin
  Result := TypesEqual(A, B) and (A.IsConst = B.IsConst) and
    (A.IsVolatile = B.IsVolatile);
end;

function DiscardedQualifierNames(const ADestination,
  ASource: TCType): string;
var
  DestPointee, SourcePointee: TCType;
begin
  DestPointee := PointeeType(DecayType(ADestination));
  SourcePointee := PointeeType(DecayType(ASource));
  Result := '';
  if SourcePointee.IsConst and (not DestPointee.IsConst) then
    Result := 'const';
  if SourcePointee.IsVolatile and (not DestPointee.IsVolatile) then
  begin
    if Result <> '' then Result := Result + ' and volatile'
    else Result := 'volatile';
  end;
end;

function PointerTargetQualifierMessage(const ADestination,
  ASource: TCType): string;
begin
  Result := 'discards ''' + DiscardedQualifierNames(ADestination, ASource) +
    ''' qualifier from pointer target type';
end;

function ClassifyPointerToPointer(const ADestination, ASource: TCType;
  ARequireQualifiers: Boolean; AProblem: PConversionProblem): TConversionClass;
var
  DestPointee, SourcePointee, DestUnq, SourceUnq: TCType;
  DestFunction, SourceFunction, DestVoidObject, SourceVoidObject: Boolean;
begin
  DestPointee := PointeeType(ADestination);
  SourcePointee := PointeeType(ASource);

  DestFunction := DestPointee.Kind = ctFunction;
  SourceFunction := SourcePointee.Kind = ctFunction;

  if DestFunction or SourceFunction then
  begin
    { Function pointers convert only to compatible function types, and never
      to object pointers, so the object-pointer `void *` rules do not apply. }
    if DestFunction and SourceFunction then
    begin
      if TypesEqual(DestPointee, SourcePointee) then Exit(ccValid);
      if AProblem <> nil then AProblem^ := cpFunctionPointerMismatch;
      Exit(ccConstraintViolation);
    end;
    if AProblem <> nil then AProblem^ := cpFunctionObjectPointer;
    Exit(ccConstraintViolation);
  end;

  DestVoidObject := (DestPointee.Kind = ctVoid) and
    (DestPointee.PointerDepth = 0);
  SourceVoidObject := (SourcePointee.Kind = ctVoid) and
    (SourcePointee.PointerDepth = 0);

  if DestVoidObject and (not IsPointerType(SourcePointee)) then
  begin
    { `void *` converts to and from object pointers (function pointers were
      already rejected above); only qualifier preservation matters. }
    if ARequireQualifiers and
      (not TypeCarriesQualifiersOf(DestPointee, SourcePointee)) then
    begin
      if AProblem <> nil then AProblem^ := cpPointerTargetQualifiers;
      Exit(ccConstraintViolation);
    end;
    Exit(ccValid);
  end;
  if SourceVoidObject and (not IsPointerType(DestPointee)) then
  begin
    if ARequireQualifiers and
      (not TypeCarriesQualifiersOf(DestPointee, SourcePointee)) then
    begin
      if AProblem <> nil then AProblem^ := cpPointerTargetQualifiers;
      Exit(ccConstraintViolation);
    end;
    Exit(ccValid);
  end;

  if IsPointerType(DestPointee) or IsPointerType(SourcePointee) then
  begin
    { Nested pointer-to-pointer conversions (depth >= 2) may not add or remove
      qualification at any inner level: although `char *` converts to
      `const char *`, `char **` does not convert to `const char **` (and vice
      versa) because the pointed-to pointers would become incompatible. The
      rule is unconditional: C11 6.5.8/6.5.9 also require pointers to
      compatible pointed-to types, and a qualifier two levels down is not a
      qualification of the pointed-to type, so `char **` and `const char **`
      are incompatible operands there too. }
    if SameTypeIncludingQualifiers(DestPointee, SourcePointee) then
      Exit(ccValid);
    if AProblem <> nil then AProblem^ := cpNestedPointerQualifiers;
    Exit(ccConstraintViolation);
  end;

  { The pointed-to types are plain objects (depth 1). }
  DestUnq := DestPointee;
  SourceUnq := SourcePointee;
  DestUnq.IsConst := False;
  DestUnq.IsVolatile := False;
  SourceUnq.IsConst := False;
  SourceUnq.IsVolatile := False;
  if not TypesEqual(DestUnq, SourceUnq) then Exit(ccConstraintViolation);
  if ARequireQualifiers and
    (not TypeCarriesQualifiersOf(DestPointee, SourcePointee)) then
  begin
    if AProblem <> nil then AProblem^ := cpPointerTargetQualifiers;
    Exit(ccConstraintViolation);
  end;
  Exit(ccValid);
end;

function ClassifyConversion(const ADestination, ASource: TCType;
  AIsNullPointerConstant: Boolean;
  AProblem: PConversionProblem;
  ARequireQualifiers: Boolean): TConversionClass;
var
  DestType, SourceType: TCType;
  DestIsPointer, SourceIsPointer: Boolean;
begin
  if AProblem <> nil then AProblem^ := cpNone;
  DestType := DecayType(ADestination);
  SourceType := DecayType(ASource);
  DestIsPointer := IsPointerType(DestType);
  SourceIsPointer := IsPointerType(SourceType);

  if not DestIsPointer and not SourceIsPointer then
  begin
    { A pointer to void is still a pointer; only a genuine void expression
      (PointerDepth 0) takes part in void conversions. }
    if (DestType.Kind = ctVoid) or (SourceType.Kind = ctVoid) then
    begin
      if (DestType.Kind = ctVoid) and (SourceType.Kind = ctVoid) then
        Exit(ccValid)
      else
        Exit(ccInvalid);
    end;

    if IsArithmeticType(DestType) and IsArithmeticType(SourceType) then
      Exit(ccValid);

    if (DestType.Kind in [ctStruct, ctUnion]) or
      (SourceType.Kind in [ctStruct, ctUnion]) then
    begin
      if (DestType.Kind in [ctStruct, ctUnion]) and
        (SourceType.Kind in [ctStruct, ctUnion]) and
        TypesEqual(DestType, SourceType) then
        Exit(ccValid);
      Exit(ccInvalid);
    end;

    Exit(ccInvalid);
  end;

  if DestIsPointer and SourceIsPointer then
    Exit(ClassifyPointerToPointer(DestType, SourceType,
      ARequireQualifiers, AProblem));

  if DestIsPointer then
  begin
    { Only the integer constant expression zero (a null pointer constant) may
      convert to a pointer implicitly; any other integer does not. }
    if IsIntegerType(SourceType) and AIsNullPointerConstant then
      Exit(ccValid);
    if IsIntegerType(SourceType) then Exit(ccConstraintViolation);
    Exit(ccInvalid);
  end;

  if IsArithmeticType(DestType) then Exit(ccConstraintViolation);
  Result := ccInvalid;
end;

end.
