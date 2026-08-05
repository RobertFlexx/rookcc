unit rcc_typeops;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types;

function MakeArrayType(const AElementType: TCType; ALength: Int64): TCType;
function ElementTypeOf(const AType: TCType): TCType;
function PointerTo(const AType: TCType): TCType;
function PointeeType(const AType: TCType): TCType;
function DecayType(const AType: TCType): TCType;
function IsArrayType(const AType: TCType): Boolean;
function IsAggregateType(const AType: TCType): Boolean;
function IsPointerType(const AType: TCType): Boolean;
function IsFunctionType(const AType: TCType): Boolean;
function HasFunctionSignature(const AType: TCType): Boolean;
function FunctionReturnTypeOf(const AType: TCType): TCType;
function FunctionParameterCount(const AType: TCType): LongInt;
function FunctionParameterType(const AType: TCType; AIndex: LongInt): TCType;
function FunctionIsVariadic(const AType: TCType): Boolean;
function IsFloatingType(const AType: TCType): Boolean;
function StorageSize(const AType: TCType): LongInt;
function StorageAlign(const AType: TCType): LongInt;
function FindMember(const AType: TCType; const AName: string;
  out AMember: TStructMember): Boolean;
function TypeName(const AType: TCType): string;
function ConvertIntegerValue(AValue: Int64; const AType: TCType): Int64;
function EvaluateIntegerConstantExpression(E: TExpr;
  out AValue: Int64): Boolean;

implementation

function MakeArrayType(const AElementType: TCType; ALength: Int64): TCType;
var
  Owned: PCType;
begin
  Result := MakeType(ctArray);
  Result.IsPacked := AElementType.IsPacked;
  Result.AlignmentOverride := AElementType.AlignmentOverride;
  Result.SuppressUnusedWarning := AElementType.SuppressUnusedWarning;
  Result.ArrayLength := ALength;
  Result.ElementKind := AElementType.Kind;
  Result.ElementUnsigned := AElementType.IsUnsigned;
  Result.ElementConst := AElementType.IsConst;
  Result.ElementPointerDepth := AElementType.PointerDepth;
  Result.ElementStructInfo := AElementType.StructInfo;
  New(Owned);
  Owned^ := AElementType;
  Result.ElementRef := Owned;
end;

function ElementTypeOf(const AType: TCType): TCType;
begin
  if AType.Kind <> ctArray then
    raise ERCCError.Create('internal error: element type requested for non-array');
  if AType.ElementRef <> nil then Exit(PCType(AType.ElementRef)^);
  Result := MakeType(AType.ElementKind, AType.ElementUnsigned,
    AType.ElementPointerDepth);
  Result.IsConst := AType.ElementConst;
  Result.StructInfo := AType.ElementStructInfo;
end;

function PointerTo(const AType: TCType): TCType;
begin
  Result := AType;
  Inc(Result.PointerDepth);
end;

function PointeeType(const AType: TCType): TCType;
begin
  { A decayed array is an array type carrying PointerDepth > 0, so the pointer
    level must be peeled first; `int (*)[5]` points at `int[5]`, not at `int`. }
  if AType.PointerDepth > 0 then
  begin
    Result := AType;
    Dec(Result.PointerDepth);
    Exit;
  end;
  if AType.Kind = ctArray then Exit(ElementTypeOf(AType));
  raise ERCCError.Create('internal error: pointee type requested for non-pointer');
end;

function DecayType(const AType: TCType): TCType;
begin
  { Only a real array object decays; `int (*)[3]` is already a pointer. }
  if (AType.Kind = ctArray) and (AType.PointerDepth = 0) then
    Result := PointerTo(ElementTypeOf(AType))
  else if (AType.Kind = ctFunction) and (AType.PointerDepth = 0) then
  begin
    Result := AType;
    Result.PointerDepth := 1;
  end
  else
    Result := AType;
end;

function IsArrayType(const AType: TCType): Boolean;
begin
  Result := (AType.Kind = ctArray) and (AType.PointerDepth = 0);
end;

function IsAggregateType(const AType: TCType): Boolean;
begin
  Result := (AType.PointerDepth = 0) and
    (AType.Kind in [ctArray, ctStruct, ctUnion]);
end;

function IsPointerType(const AType: TCType): Boolean;
begin
  Result := (AType.PointerDepth > 0) or (AType.Kind = ctPointer);
end;

function IsFunctionType(const AType: TCType): Boolean;
begin




  Result := (AType.Kind = ctFunction) and (AType.PointerDepth = 0);
end;

function HasFunctionSignature(const AType: TCType): Boolean;
begin
  Result := (AType.Kind = ctFunction) and (AType.ReturnType <> nil) and
    (AType.ParamTypes <> nil) and (AType.ParamCount >= 0);
end;

function FunctionReturnTypeOf(const AType: TCType): TCType;
begin
  if not HasFunctionSignature(AType) then
    raise ERCCError.Create('internal error: function type has no signature');
  Result := PCType(AType.ReturnType)^;
end;

function FunctionParameterCount(const AType: TCType): LongInt;
begin
  if not HasFunctionSignature(AType) then
    raise ERCCError.Create('internal error: function type has no signature');
  Result := AType.ParamCount;
end;

function FunctionParameterType(const AType: TCType;
  AIndex: LongInt): TCType;
var
  Parameters: PFunctionParameterList;
begin
  if not HasFunctionSignature(AType) then
    raise ERCCError.Create('internal error: function type has no signature');
  Parameters := PFunctionParameterList(AType.ParamTypes);
  if (AIndex < 0) or (AIndex >= Length(Parameters^.Items)) then
    raise ERCCError.Create('internal error: function parameter index is out of range');
  Result := Parameters^.Items[AIndex];
end;

function FunctionIsVariadic(const AType: TCType): Boolean;
begin
  Result := HasFunctionSignature(AType) and AType.IsVariadic;
end;

function IsFloatingType(const AType: TCType): Boolean;
begin
  Result := (AType.PointerDepth = 0) and
    (AType.Kind in [ctFloat, ctDouble, ctLongDouble]);
end;

function StorageSize(const AType: TCType): LongInt;
var
  S: Int64;
begin
  S := CTypeSize(AType);
  if S <= 0 then
  begin
    if IsFunctionType(AType) then Exit(0);
    Exit(1);
  end;
  if S > High(LongInt) then
    raise ERCCError.Create('error: object is too large for the x86-64 backend');
  Result := LongInt(S);
end;

function StorageAlign(const AType: TCType): LongInt;
begin
  Result := CTypeAlign(AType);
  if Result < 1 then Result := 1;
  if Result > 16 then Result := 16;
end;

function FindMember(const AType: TCType; const AName: string;
  out AMember: TStructMember): Boolean;
var
  I: LongInt;
  Info: PStructMembers;
  AnonymousType: TCType;
  NestedMember: TStructMember;
begin
  Info := AType.StructInfo;
  if (Info = nil) or not (AType.Kind in [ctStruct, ctUnion]) then
    Exit(False);
  for I := 0 to High(Info^.Members) do
    if Info^.Members[I].Name = AName then
    begin
      AMember := Info^.Members[I];
      Exit(True);
    end;
  for I := 0 to High(Info^.Members) do
    if (Info^.Members[I].Name = '') and
       (Info^.Members[I].CType <> nil) then
    begin
      AnonymousType := PCType(Info^.Members[I].CType)^;
      if (AnonymousType.Kind in [ctStruct, ctUnion]) and
         FindMember(AnonymousType, AName, NestedMember) then
      begin
        AMember := NestedMember;
        Inc(AMember.Offset, Info^.Members[I].Offset);
        Exit(True);
      end;
    end;
  Result := False;
end;

function ConvertIntegerValue(AValue: Int64; const AType: TCType): Int64;
var
  Bits, Mask, SignBit: QWord;
  Width: LongInt;
begin
  if not IsIntegerType(AType) then Exit(AValue);
  if AType.Kind = ctBool then
  begin
    if AValue = 0 then Exit(0);
    Exit(1);
  end;
  Width := StorageSize(AType) * 8;
  if Width >= 64 then Exit(AValue);
  Mask := (QWord(1) shl Width) - 1;
  Bits := QWord(AValue) and Mask;
  if AType.IsUnsigned then Exit(Int64(Bits));
  SignBit := QWord(1) shl (Width - 1);
  if (Bits and SignBit) <> 0 then Bits := Bits or not Mask;
  Move(Bits, Result, SizeOf(Result));
end;

function EvaluateIntegerConstantExpression(E: TExpr;
  out AValue: Int64): Boolean;
var
  LeftValue, RightValue: Int64;
  LeftBits, RightBits: QWord;
  UseUnsigned: Boolean;
begin
  Result := False;
  AValue := 0;
  if E = nil then Exit;
  case E.Kind of
    ekInteger:
      begin
        AValue := E.IntValue;
        Exit(True);
      end;

    ekUnary:
      begin
        if not EvaluateIntegerConstantExpression(E.Left, LeftValue) then Exit;
        case E.UnaryOp of
          uoPositive: AValue := LeftValue;
          uoNegative: AValue := Int64(QWord(0) - QWord(LeftValue));
          uoLogicalNot:
            if LeftValue = 0 then AValue := 1 else AValue := 0;
          uoBitwiseNot: AValue := Int64(not QWord(LeftValue));
        end;
        Exit(True);
      end;

    ekBinary:
      begin
        if not EvaluateIntegerConstantExpression(E.Left, LeftValue) then Exit;
        if E.BinaryOp = boLogicalAnd then
        begin
          if LeftValue = 0 then
          begin
            AValue := 0;
            Exit(True);
          end;
          if not EvaluateIntegerConstantExpression(E.Right, RightValue) then Exit;
          if RightValue <> 0 then AValue := 1 else AValue := 0;
          Exit(True);
        end;
        if E.BinaryOp = boLogicalOr then
        begin
          if LeftValue <> 0 then
          begin
            AValue := 1;
            Exit(True);
          end;
          if not EvaluateIntegerConstantExpression(E.Right, RightValue) then Exit;
          if RightValue <> 0 then AValue := 1 else AValue := 0;
          Exit(True);
        end;
        if not EvaluateIntegerConstantExpression(E.Right, RightValue) then Exit;
        if IsIntegerType(E.OperationType) then
        begin
          LeftValue := ConvertIntegerValue(LeftValue, E.OperationType);
          if not (E.BinaryOp in [boShiftLeft, boShiftRight]) then
            RightValue := ConvertIntegerValue(RightValue, E.OperationType);
          UseUnsigned := E.OperationType.IsUnsigned;
        end
        else
          UseUnsigned := False;
        LeftBits := QWord(LeftValue);
        RightBits := QWord(RightValue);
        case E.BinaryOp of
          boAdd: AValue := Int64(LeftBits + RightBits);
          boSub: AValue := Int64(LeftBits - RightBits);
          boMul: AValue := Int64(LeftBits * RightBits);
          boDiv:
            begin
              if RightValue = 0 then Exit;
              if UseUnsigned then
                AValue := Int64(LeftBits div RightBits)
              else
              begin
                if (LeftValue = Low(Int64)) and (RightValue = -1) then Exit;
                AValue := LeftValue div RightValue;
              end;
            end;
          boMod:
            begin
              if RightValue = 0 then Exit;
              if UseUnsigned then
                AValue := Int64(LeftBits mod RightBits)
              else if (LeftValue = Low(Int64)) and (RightValue = -1) then
                AValue := 0
              else
                AValue := LeftValue mod RightValue;
            end;
          boShiftLeft:
            begin
              if (RightValue < 0) or (RightValue >= 64) then Exit;
              AValue := Int64(LeftBits shl RightValue);
            end;
          boShiftRight:
            begin
              if (RightValue < 0) or (RightValue >= 64) then Exit;
              if RightValue = 0 then
                AValue := LeftValue
              else if UseUnsigned then
                AValue := Int64(LeftBits shr RightValue)
              else if LeftValue >= 0 then
                AValue := LeftValue shr RightValue
              else
                AValue := Int64((LeftBits shr RightValue) or
                  (not QWord(0) shl (64 - RightValue)));
            end;
          boLess:
            if UseUnsigned then
            begin
              if LeftBits < RightBits then AValue := 1 else AValue := 0;
            end
            else if LeftValue < RightValue then AValue := 1 else AValue := 0;
          boLessEqual:
            if UseUnsigned then
            begin
              if LeftBits <= RightBits then AValue := 1 else AValue := 0;
            end
            else if LeftValue <= RightValue then AValue := 1 else AValue := 0;
          boGreater:
            if UseUnsigned then
            begin
              if LeftBits > RightBits then AValue := 1 else AValue := 0;
            end
            else if LeftValue > RightValue then AValue := 1 else AValue := 0;
          boGreaterEqual:
            if UseUnsigned then
            begin
              if LeftBits >= RightBits then AValue := 1 else AValue := 0;
            end
            else if LeftValue >= RightValue then AValue := 1 else AValue := 0;
          boEqual:
            if LeftBits = RightBits then AValue := 1 else AValue := 0;
          boNotEqual:
            if LeftBits <> RightBits then AValue := 1 else AValue := 0;
          boBitAnd: AValue := Int64(LeftBits and RightBits);
          boBitXor: AValue := Int64(LeftBits xor RightBits);
          boBitOr: AValue := Int64(LeftBits or RightBits);
          boComma: AValue := RightValue;
        else
          Exit;
        end;
        Exit(True);
      end;

    ekConditional:
      begin
        if not EvaluateIntegerConstantExpression(E.Left, LeftValue) then Exit;
        if LeftValue <> 0 then
          Result := EvaluateIntegerConstantExpression(E.Right, AValue)
        else
          Result := EvaluateIntegerConstantExpression(E.Third, AValue);
      end;

    ekCast:
      begin
        if not IsIntegerType(E.CType) then Exit;
        if not EvaluateIntegerConstantExpression(E.Left, LeftValue) then Exit;
        AValue := ConvertIntegerValue(LeftValue, E.CType);
        Exit(True);
      end;

    ekComma:
      begin
        if not EvaluateIntegerConstantExpression(E.Left, LeftValue) then Exit;
        Result := EvaluateIntegerConstantExpression(E.Right, AValue);
      end;
  end;
end;

function TypeName(const AType: TCType): string;
var
  Base: string;
begin
  case AType.Kind of
    ctVoid: Base := 'void';
    ctChar: Base := 'char';
    ctShort: Base := 'short';
    ctInt: Base := 'int';
    ctLong: Base := 'long';
    ctLongLong: Base := 'long long';
    ctBool: Base := '_Bool';
    ctFloat: Base := 'float';
    ctDouble: Base := 'double';
    ctLongDouble: Base := 'long double';
    ctPointer: Base := 'pointer';
    ctArray: Base := TypeName(ElementTypeOf(AType)) + '[' +
      IntToStr(AType.ArrayLength) + ']';
    ctStruct:
      if (AType.StructInfo <> nil) and (AType.StructInfo^.Name <> '') then
        Base := 'struct ' + AType.StructInfo^.Name
      else Base := 'anonymous struct';
    ctUnion:
      if (AType.StructInfo <> nil) and (AType.StructInfo^.Name <> '') then
        Base := 'union ' + AType.StructInfo^.Name
      else Base := 'anonymous union';
    ctEnum: Base := 'enum';
    ctFunction: Base := 'function';
  else
    Base := 'type';
  end;
  if AType.IsConst then Base := 'const ' + Base;
  if AType.IsVolatile then Base := 'volatile ' + Base;
  if AType.IsUnsigned and IsIntegerType(AType) then Base := 'unsigned ' + Base;
  Result := Base;
  if AType.PointerDepth > 0 then
    Result := Result + ' ' + StringOfChar('*', AType.PointerDepth);
end;

end.
