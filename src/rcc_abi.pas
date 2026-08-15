unit rcc_abi;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_arch;

type
  TABIScalarClass = (
    ascNone,
    ascInteger,
    ascSSE,
    ascSSEUp,
    ascX87,
    ascX87Up,
    ascComplexX87,
    ascMemory
  );

  TABILocationKind = (
    alkInvalid,
    alkRegister,
    alkRegisterPair,
    alkStack,
    alkIndirect,
    alkHiddenPointer
  );

  TABIPassMode = (
    apmDirect,
    apmIndirect,
    apmIgnore
  );

  TABIValuePart = record
    ValueClass: TABIScalarClass;
    RegisterNumber: LongInt;
    StackOffset: Int64;
    BitOffset: LongInt;
    BitWidth: LongInt;
  end;
  TABIValuePartArray = array of TABIValuePart;

  TABIValueLocation = record
    Kind: TABILocationKind;
    PassMode: TABIPassMode;
    Size: QWord;
    Alignment: LongInt;
    Parts: TABIValuePartArray;
    RequiresCopy: Boolean;
    SignExtend: Boolean;
    ZeroExtend: Boolean;
  end;
  TABIValueLocationArray = array of TABIValueLocation;

  TABIFunctionLayout = class
  public
    Target: TTargetDescriptor;
    ReturnLocation: TABIValueLocation;
    Parameters: TABIValueLocationArray;
    StackArgumentDataBytes: QWord;
    StackArgumentBytes: QWord;
    RequiredStackAlignment: LongInt;
    UsesHiddenReturnPointer: Boolean;
    Variadic: Boolean;
    IntegerRegistersUsed: LongInt;
    FloatingRegistersUsed: LongInt;
    constructor Create(const ATarget: TTargetDescriptor);
    function Summary: string;
  end;

function ABIScalarClassName(AClass: TABIScalarClass): string;
function ABILocationKindName(AKind: TABILocationKind): string;
function ABIPassModeName(AMode: TABIPassMode): string;
function EmptyABILocation: TABIValueLocation;
function ClassifyCTypeForABI(const AType: TCType;
  const ATarget: TTargetDescriptor): TABIValueLocation;
function BuildFunctionABILayout(const AReturnType: TCType;
  const AParameters: array of TCType; AVariadic: Boolean;
  const ATarget: TTargetDescriptor;
  AFixedParameterCount: LongInt = -1): TABIFunctionLayout;
function FunctionABIText(ALayout: TABIFunctionLayout): string;
function ValidateABIType(const AType: TCType;
  const ATarget: TTargetDescriptor; out AReason: string): Boolean;
function ABIStackSlotSize(const ATarget: TTargetDescriptor): LongInt;
function ABIShadowSpace(const ATarget: TTargetDescriptor): LongInt;
function ABIRedZoneSize(const ATarget: TTargetDescriptor): LongInt;
function ABIRequiresFramePointer(const ATarget: TTargetDescriptor;
  AHasDynamicAlloca, AHasDebugInfo: Boolean): Boolean;

implementation

type
  TSysVEightByteClasses = array[0..1] of TABIScalarClass;

  TFlattenedABIField = record
    CType: TCType;
    BitOffset: LongInt;
    BitWidth: LongInt;
  end;
  TFlattenedABIFields = array of TFlattenedABIField;

function MinQWord(A, B: QWord): QWord; inline;
begin
  if A < B then Result := A else Result := B;
end;

function MaxLongInt(A, B: LongInt): LongInt; inline;
begin
  if A > B then Result := A else Result := B;
end;

function AlignUp(AValue: QWord; AAlignment: LongInt): QWord;
var
  Mask: QWord;
begin
  if AAlignment <= 1 then Exit(AValue);
  Mask := QWord(AAlignment - 1);
  Result := (AValue + Mask) and not Mask;
end;

procedure AddPart(var AParts: TABIValuePartArray;
  AClass: TABIScalarClass; ARegister: LongInt; AStackOffset: Int64;
  ABitOffset, ABitWidth: LongInt);
var
  N: LongInt;
begin
  N := Length(AParts);
  SetLength(AParts, N + 1);
  AParts[N].ValueClass := AClass;
  AParts[N].RegisterNumber := ARegister;
  AParts[N].StackOffset := AStackOffset;
  AParts[N].BitOffset := ABitOffset;
  AParts[N].BitWidth := ABitWidth;
end;

function ABIScalarClassName(AClass: TABIScalarClass): string;
begin
  case AClass of
    ascNone: Result := 'none';
    ascInteger: Result := 'integer';
    ascSSE: Result := 'sse';
    ascSSEUp: Result := 'sse-up';
    ascX87: Result := 'x87';
    ascX87Up: Result := 'x87-up';
    ascComplexX87: Result := 'complex-x87';
    ascMemory: Result := 'memory';
  else
    Result := 'unknown';
  end;
end;

function ABILocationKindName(AKind: TABILocationKind): string;
begin
  case AKind of
    alkInvalid: Result := 'invalid';
    alkRegister: Result := 'register';
    alkRegisterPair: Result := 'register-pair';
    alkStack: Result := 'stack';
    alkIndirect: Result := 'indirect';
    alkHiddenPointer: Result := 'hidden-pointer';
  else
    Result := 'unknown';
  end;
end;

function ABIPassModeName(AMode: TABIPassMode): string;
begin
  case AMode of
    apmDirect: Result := 'direct';
    apmIndirect: Result := 'indirect';
    apmIgnore: Result := 'ignore';
  else
    Result := 'unknown';
  end;
end;

function EmptyABILocation: TABIValueLocation;
begin
  Result.Kind := alkInvalid;
  Result.PassMode := apmDirect;
  Result.Size := 0;
  Result.Alignment := 1;
  SetLength(Result.Parts, 0);
  Result.RequiresCopy := False;
  Result.SignExtend := False;
  Result.ZeroExtend := False;
end;

function IsFloatingCType(const AType: TCType): Boolean;
begin
  Result := (AType.PointerDepth = 0) and
    (AType.Kind in [ctFloat, ctDouble, ctLongDouble]);
end;

function IsAggregateCType(const AType: TCType): Boolean;
begin
  Result := (AType.PointerDepth = 0) and
    (AType.Kind in [ctStruct, ctUnion, ctArray]);
end;

procedure AddFlattenedField(var AFields: TFlattenedABIFields;
  const AType: TCType; ABitOffset, ABitWidth: LongInt);
var
  N: LongInt;
begin
  N := Length(AFields);
  SetLength(AFields, N + 1);
  AFields[N].CType := AType;
  AFields[N].BitOffset := ABitOffset;
  AFields[N].BitWidth := ABitWidth;
end;

function CollectAArch64HFAFields(const AType: TCType; ABaseOffset: LongInt;
  var AFields: TFlattenedABIFields; var AElementKind: TCTypeKind): Boolean;
var
  I, ElementSize: LongInt;
  ElementType, MemberType: TCType;
begin
  Result := False;
  if AType.PointerDepth > 0 then Exit;
  case AType.Kind of
    ctFloat, ctDouble:
      begin
        if (Length(AFields) > 0) and (AElementKind <> AType.Kind) then Exit;
        AElementKind := AType.Kind;
        AddFlattenedField(AFields, AType, ABaseOffset * 8,
          LongInt(CTypeSize(AType) * 8));
        Exit(Length(AFields) <= 4);
      end;
    ctArray:
      begin
        ElementType := ArrayElementType(AType);
        ElementSize := LongInt(CTypeSize(ElementType));
        for I := 0 to LongInt(AType.ArrayLength) - 1 do
          if not CollectAArch64HFAFields(ElementType,
            ABaseOffset + I * ElementSize, AFields, AElementKind) then Exit;
        Exit(Length(AFields) <= 4);
      end;
    ctStruct:
      begin
        if AType.StructInfo = nil then Exit;
        for I := 0 to High(AType.StructInfo^.Members) do
        begin
          if AType.StructInfo^.Members[I].IsBitField then Exit;
          MemberType := PCType(AType.StructInfo^.Members[I].CType)^;
          if CTypeSize(MemberType) = 0 then Continue;
          if not CollectAArch64HFAFields(MemberType,
            ABaseOffset + AType.StructInfo^.Members[I].Offset,
            AFields, AElementKind) then Exit;
        end;
        Exit((Length(AFields) > 0) and (Length(AFields) <= 4));
      end;
  end;
end;

function CollectRISCVFlattenedFields(const AType: TCType;
  ABaseOffset: LongInt; var AFields: TFlattenedABIFields): Boolean;
var
  I, ElementSize: LongInt;
  ElementType, MemberType: TCType;
begin
  Result := False;
  if Length(AFields) > 2 then Exit;
  if AType.PointerDepth > 0 then
  begin
    AddFlattenedField(AFields, AType, ABaseOffset * 8, 64);
    Exit(Length(AFields) <= 2);
  end;
  case AType.Kind of
    ctFloat, ctDouble,
    ctBool, ctChar, ctShort, ctInt, ctLong, ctLongLong, ctEnum:
      begin
        AddFlattenedField(AFields, AType, ABaseOffset * 8,
          LongInt(CTypeSize(AType) * 8));
        Exit(Length(AFields) <= 2);
      end;
    ctArray:
      begin
        ElementType := ArrayElementType(AType);
        ElementSize := LongInt(CTypeSize(ElementType));
        for I := 0 to LongInt(AType.ArrayLength) - 1 do
          if not CollectRISCVFlattenedFields(ElementType,
            ABaseOffset + I * ElementSize, AFields) then Exit;
        Exit((Length(AFields) > 0) and (Length(AFields) <= 2));
      end;
    ctStruct:
      begin
        if AType.StructInfo = nil then Exit;
        for I := 0 to High(AType.StructInfo^.Members) do
        begin
          { The psABI includes bit-fields in mixed FP/integer flattening. Fall
            back to the base integer convention until the bit extraction path
            can describe non-byte-aligned register parts without ambiguity. }
          if AType.StructInfo^.Members[I].IsBitField then Exit;
          MemberType := PCType(AType.StructInfo^.Members[I].CType)^;
          if CTypeSize(MemberType) = 0 then Continue;
          if not CollectRISCVFlattenedFields(MemberType,
            ABaseOffset + AType.StructInfo^.Members[I].Offset,
            AFields) then Exit;
        end;
        Exit((Length(AFields) > 0) and (Length(AFields) <= 2));
      end;
  end;
end;

function MergeSysVClass(ALeft, ARight: TABIScalarClass): TABIScalarClass;
begin
  if ALeft = ascNone then Exit(ARight);
  if ARight = ascNone then Exit(ALeft);
  if ALeft = ARight then Exit(ALeft);
  if (ALeft = ascMemory) or (ARight = ascMemory) then Exit(ascMemory);
  if (ALeft = ascInteger) or (ARight = ascInteger) then Exit(ascInteger);
  if (ALeft in [ascX87, ascX87Up, ascComplexX87]) or
     (ARight in [ascX87, ascX87Up, ascComplexX87]) then Exit(ascMemory);



  Result := ascSSE;
end;

procedure MarkSysVRange(var AClasses: TSysVEightByteClasses;
  AOffset, ASize: LongInt; AClass: TABIScalarClass; var AMemory: Boolean);
var
  FirstPart, LastPart, I: LongInt;
begin
  if ASize <= 0 then Exit;
  FirstPart := AOffset div 8;
  LastPart := (AOffset + ASize - 1) div 8;
  if (FirstPart < 0) or (LastPart > High(AClasses)) then
  begin
    AMemory := True;
    Exit;
  end;
  for I := FirstPart to LastPart do
  begin
    AClasses[I] := MergeSysVClass(AClasses[I], AClass);
    if AClasses[I] = ascMemory then AMemory := True;
  end;
end;

procedure ClassifySysVType(const AType: TCType; ABaseOffset: LongInt;
  var AClasses: TSysVEightByteClasses; var AMemory: Boolean);
var
  I, TypeSize, TypeAlign: LongInt;
  ElementType, MemberType: TCType;
  Member: TStructMember;
begin
  if AMemory then Exit;
  TypeSize := LongInt(CTypeSize(AType));
  TypeAlign := CTypeAlign(AType);
  if (TypeSize < 0) or (ABaseOffset < 0) or
     (ABaseOffset + TypeSize > 16) then
  begin
    AMemory := True;
    Exit;
  end;

  if (TypeAlign > 1) and ((ABaseOffset mod TypeAlign) <> 0) then
  begin
    AMemory := True;
    Exit;
  end;
  if AType.PointerDepth > 0 then
  begin
    MarkSysVRange(AClasses, ABaseOffset, 8, ascInteger, AMemory);
    Exit;
  end;
  case AType.Kind of
    ctBool, ctChar, ctShort, ctInt, ctLong, ctLongLong, ctPointer, ctEnum:
      MarkSysVRange(AClasses, ABaseOffset, TypeSize, ascInteger, AMemory);
    ctFloat, ctDouble:
      MarkSysVRange(AClasses, ABaseOffset, TypeSize, ascSSE, AMemory);
    ctLongDouble:
      AMemory := True;
    ctArray:
      begin
        ElementType := MakeType(AType.ElementKind, AType.ElementUnsigned,
          AType.ElementPointerDepth);
        ElementType.IsConst := AType.ElementConst;
        ElementType.StructInfo := AType.ElementStructInfo;
        TypeSize := LongInt(CTypeSize(ElementType));
        for I := 0 to AType.ArrayLength - 1 do
          ClassifySysVType(ElementType, ABaseOffset + I * TypeSize,
            AClasses, AMemory);
      end;
    ctStruct, ctUnion:
      begin
        if AType.StructInfo = nil then
        begin
          AMemory := True;
          Exit;
        end;
        for I := 0 to High(AType.StructInfo^.Members) do
        begin
          Member := AType.StructInfo^.Members[I];
          MemberType := PCType(Member.CType)^;
          if Member.IsBitField then
            MarkSysVRange(AClasses, ABaseOffset + Member.Offset,
              LongInt(CTypeSize(MemberType)), ascInteger, AMemory)
          else
            ClassifySysVType(MemberType, ABaseOffset + Member.Offset,
              AClasses, AMemory);
        end;
      end;
  else
    AMemory := True;
  end;
end;

function IntegerWidth(const AType: TCType;
  const ATarget: TTargetDescriptor): LongInt;
begin
  if AType.PointerDepth > 0 then Exit(ATarget.DataLayout.PointerBits);
  case AType.Kind of
    ctBool: Result := 1;
    ctChar: Result := ATarget.DataLayout.CharBits;
    ctShort: Result := ATarget.DataLayout.ShortBits;
    ctInt, ctEnum: Result := ATarget.DataLayout.IntBits;
    ctLong: Result := ATarget.DataLayout.LongBits;
    ctLongLong: Result := ATarget.DataLayout.LongLongBits;
  else
    Result := LongInt(CTypeSize(AType) * 8);
  end;
end;

function ValidateABIType(const AType: TCType;
  const ATarget: TTargetDescriptor; out AReason: string): Boolean;
var
  Size: Int64;
begin
  AReason := '';
  if AType.Kind = ctVoid then Exit(True);
  Size := CTypeSize(AType);
  if Size < 0 then
  begin
    AReason := 'type has unknown or incomplete size';
    Exit(False);
  end;
  if (AType.PointerDepth > 0) and
     (ATarget.DataLayout.PointerBits <> 64) then
  begin
    AReason := 'this release models only 64-bit target pointers';
    Exit(False);
  end;
  if IsFloatingCType(AType) and
     not TargetHasCapability(ATarget, tcFloatingPoint) then
  begin
    AReason := 'target backend does not advertise floating-point ABI support';
    Exit(False);
  end;
  if (AType.Kind = ctLongDouble) and
     (ATarget.Architecture <> archX86_64) and
     (ATarget.DataLayout.LongDoubleBits <> 64) then
  begin
    AReason := 'long double ABI lowering is not complete for this target';
    Exit(False);
  end;
  Result := True;
end;

function ClassifyAggregate(const AType: TCType;
  const ATarget: TTargetDescriptor): TABIValueLocation;
var
  Size: QWord;
  PartCount, I: LongInt;
  Classes: TSysVEightByteClasses;
  Memory: Boolean;
  Fields: TFlattenedABIFields;
  HFAElementKind: TCTypeKind;
  FloatingFields, IntegerFields: LongInt;
begin
  Result := EmptyABILocation;
  Size := QWord(CTypeSize(AType));
  Result.Size := Size;
  Result.Alignment := CTypeAlign(AType);
  if Size = 0 then
  begin
    Result.Kind := alkInvalid;
    Result.PassMode := apmIgnore;
    Exit;
  end;

  case ATarget.Architecture of
    archX86_64:
      begin
        if Size > 16 then
        begin
          Result.Kind := alkStack;
          Result.PassMode := apmDirect;
          AddPart(Result.Parts, ascMemory, -1, 0, 0,
            LongInt(Size * 8));
          Exit;
        end;
        Classes[0] := ascNone;
        Classes[1] := ascNone;
        Memory := False;
        ClassifySysVType(AType, 0, Classes, Memory);
        if Memory then
        begin
          Result.Kind := alkStack;
          Result.PassMode := apmDirect;
          AddPart(Result.Parts, ascMemory, -1, 0, 0,
            LongInt(Size * 8));
          Exit;
        end;
        PartCount := LongInt((Size + 7) div 8);
        if PartCount = 1 then Result.Kind := alkRegister
        else Result.Kind := alkRegisterPair;
        for I := 0 to PartCount - 1 do
        begin
          if Classes[I] = ascNone then Classes[I] := ascInteger;
          AddPart(Result.Parts, Classes[I], -1, 0, I * 64,
            LongInt(MinQWord(QWord(64), (Size * 8) - QWord(I * 64))));
        end;
      end;
    archAArch64:
      begin
        SetLength(Fields, 0);
        HFAElementKind := ctVoid;
        if CollectAArch64HFAFields(AType, 0, Fields, HFAElementKind) and
           (Length(Fields) >= 1) and (Length(Fields) <= 4) then
        begin
          if Length(Fields) = 1 then Result.Kind := alkRegister
          else Result.Kind := alkRegisterPair;
          for I := 0 to High(Fields) do
            AddPart(Result.Parts, ascSSE, -1, 0,
              Fields[I].BitOffset, Fields[I].BitWidth);
          Exit;
        end;
        if Size > 16 then
        begin
          Result.Kind := alkIndirect;
          Result.PassMode := apmIndirect;
          Result.RequiresCopy := True;
          AddPart(Result.Parts, ascMemory, -1, 0, 0,
            LongInt(Size * 8));
          Exit;
        end;
        PartCount := LongInt((Size + 7) div 8);
        if PartCount = 1 then Result.Kind := alkRegister
        else Result.Kind := alkRegisterPair;
        for I := 0 to PartCount - 1 do
          AddPart(Result.Parts, ascInteger, -1, 0, I * 64,
            LongInt(MinQWord(QWord(64), (Size * 8) - QWord(I * 64))));
      end;
    archRISCV64:
      begin
        if Size > 16 then
        begin
          Result.Kind := alkIndirect;
          Result.PassMode := apmIndirect;
          Result.RequiresCopy := True;
          AddPart(Result.Parts, ascMemory, -1, 0, 0,
            LongInt(Size * 8));
          Exit;
        end;
        SetLength(Fields, 0);
        if (AType.Kind <> ctUnion) and
           CollectRISCVFlattenedFields(AType, 0, Fields) then
        begin
          FloatingFields := 0;
          IntegerFields := 0;
          for I := 0 to High(Fields) do
            if IsFloatingCType(Fields[I].CType) then
              Inc(FloatingFields)
            else
              Inc(IntegerFields);
          if ((Length(Fields) = 1) and (FloatingFields = 1)) or
             ((Length(Fields) = 2) and
              (((FloatingFields = 2) and (IntegerFields = 0)) or
               ((FloatingFields = 1) and (IntegerFields = 1)))) then
          begin
            if Length(Fields) = 1 then Result.Kind := alkRegister
            else Result.Kind := alkRegisterPair;
            for I := 0 to High(Fields) do
              if IsFloatingCType(Fields[I].CType) then
                AddPart(Result.Parts, ascSSE, -1, 0,
                  Fields[I].BitOffset, Fields[I].BitWidth)
              else
                AddPart(Result.Parts, ascInteger, -1, 0,
                  Fields[I].BitOffset, Fields[I].BitWidth);
            Exit;
          end;
        end;
        PartCount := LongInt((Size + 7) div 8);
        if PartCount = 1 then Result.Kind := alkRegister
        else Result.Kind := alkRegisterPair;
        for I := 0 to PartCount - 1 do
          AddPart(Result.Parts, ascInteger, -1, 0, I * 64,
            LongInt(MinQWord(QWord(64), (Size * 8) - QWord(I * 64))));
      end;
  else
    Result.Kind := alkIndirect;
    Result.PassMode := apmIndirect;
    Result.RequiresCopy := True;
  end;
end;

function ClassifyCTypeForABI(const AType: TCType;
  const ATarget: TTargetDescriptor): TABIValueLocation;
var
  Width: LongInt;
begin
  Result := EmptyABILocation;
  Result.Size := QWord(CTypeSize(AType));
  Result.Alignment := CTypeAlign(AType);
  if (AType.Kind = ctVoid) and (AType.PointerDepth = 0) then
  begin
    Result.PassMode := apmIgnore;
    Exit;
  end;
  if IsAggregateCType(AType) then Exit(ClassifyAggregate(AType, ATarget));
  Result.Kind := alkRegister;
  Result.PassMode := apmDirect;
  if IsFloatingCType(AType) then
  begin
    if AType.Kind = ctLongDouble then
    begin
      if ATarget.DataLayout.LongDoubleBits = 64 then
        AddPart(Result.Parts, ascSSE, -1, 0, 0, 64)
      else if ATarget.Architecture = archX86_64 then
      begin
        AddPart(Result.Parts, ascX87, -1, 0, 0, 64);
        AddPart(Result.Parts, ascX87Up, -1, 0, 64, 16);
        Result.Kind := alkRegisterPair;
      end
      else
      begin
        Result.Kind := alkIndirect;
        Result.PassMode := apmIndirect;
        Result.RequiresCopy := True;
        AddPart(Result.Parts, ascMemory, -1, 0, 0,
          LongInt(Result.Size * 8));
      end;
    end
    else
      AddPart(Result.Parts, ascSSE, -1, 0, 0,
        LongInt(Result.Size * 8));
    Exit;
  end;
  Width := IntegerWidth(AType, ATarget);
  AddPart(Result.Parts, ascInteger, -1, 0, 0, Width);
  if Width < ATarget.DataLayout.IntBits then
  begin
    Result.SignExtend := not AType.IsUnsigned;
    Result.ZeroExtend := AType.IsUnsigned;
  end;
end;

function IntegerRegisterLimit(const ATarget: TTargetDescriptor): LongInt;
begin
  case ATarget.Architecture of
    archX86_64: Result := 6;
    archAArch64: Result := 8;
    archRISCV64: Result := 8;
  else
    Result := 0;
  end;
end;

function FloatingRegisterLimit(const ATarget: TTargetDescriptor): LongInt;
begin
  case ATarget.Architecture of
    archX86_64: Result := 8;
    archAArch64: Result := 8;
    archRISCV64: Result := 8;
  else
    Result := 0;
  end;
end;

function ABIStackSlotSize(const ATarget: TTargetDescriptor): LongInt;
begin
  Result := ATarget.DataLayout.PointerBits div 8;
  if Result < 8 then Result := 8;
end;

function ABIShadowSpace(const ATarget: TTargetDescriptor): LongInt;
begin


  Result := 0;
end;

function ABIRedZoneSize(const ATarget: TTargetDescriptor): LongInt;
begin
  if ATarget.Architecture = archX86_64 then Result := 128
  else Result := 0;
end;

function ABIRequiresFramePointer(const ATarget: TTargetDescriptor;
  AHasDynamicAlloca, AHasDebugInfo: Boolean): Boolean;
begin
  Result := AHasDynamicAlloca or AHasDebugInfo;
  if ATarget.Architecture = archUnknown then Result := True;
end;

constructor TABIFunctionLayout.Create(const ATarget: TTargetDescriptor);
begin
  inherited Create;
  Target := ATarget;
  ReturnLocation := EmptyABILocation;
  SetLength(Parameters, 0);
  StackArgumentBytes := 0;
  StackArgumentDataBytes := 0;
  RequiredStackAlignment := ATarget.DataLayout.StackAlignment;
  UsesHiddenReturnPointer := False;
  Variadic := False;
  IntegerRegistersUsed := 0;
  FloatingRegistersUsed := 0;
end;

function TABIFunctionLayout.Summary: string;
begin
  Result := Format('%s: params=%d int-regs=%d fp-regs=%d stack=%d return=%s',
    [Target.Triple, Length(Parameters), IntegerRegistersUsed,
     FloatingRegistersUsed, StackArgumentBytes,
     ABILocationKindName(ReturnLocation.Kind)]);
end;

procedure ConvertLocationToIntegerConvention(var ALocation: TABIValueLocation);
var
  I, PartCount: LongInt;
  RemainingBits: QWord;
begin
  if ALocation.PassMode <> apmDirect then Exit;
  PartCount := LongInt((ALocation.Size + 7) div 8);
  if PartCount < 1 then PartCount := 1;
  if PartCount > 2 then Exit;
  SetLength(ALocation.Parts, 0);
  if PartCount = 1 then ALocation.Kind := alkRegister
  else ALocation.Kind := alkRegisterPair;
  for I := 0 to PartCount - 1 do
  begin
    RemainingBits := ALocation.Size * 8 - QWord(I * 64);
    AddPart(ALocation.Parts, ascInteger, -1, -1, I * 64,
      LongInt(MinQWord(64, RemainingBits)));
  end;
end;

procedure AssignLocationToDarwinCompactStack(
  var ALocation: TABIValueLocation; var AStackOffset: QWord);
var
  I, Alignment: LongInt;
  BaseOffset: QWord;
begin
  Alignment := ALocation.Alignment;
  if Alignment < 1 then Alignment := 1;
  if Alignment > 16 then Alignment := 16;
  AStackOffset := AlignUp(AStackOffset, Alignment);
  BaseOffset := AStackOffset;
  ALocation.Kind := alkStack;
  for I := 0 to High(ALocation.Parts) do
  begin
    ALocation.Parts[I].RegisterNumber := -1;
    ALocation.Parts[I].StackOffset := Int64(BaseOffset +
      QWord(ALocation.Parts[I].BitOffset div 8));
  end;
  AStackOffset := AStackOffset + ALocation.Size;
end;

procedure AssignLocationRegisters(var ALocation: TABIValueLocation;
  const ATarget: TTargetDescriptor; var AIntegerUsed, AFloatingUsed: LongInt;
  var AStackOffset: QWord);
var
  I, NeededInteger, NeededFloating, IntLimit, FloatLimit, Slot: LongInt;
  IsFloating: Boolean;
begin
  if ALocation.PassMode = apmIgnore then Exit;
  IntLimit := IntegerRegisterLimit(ATarget);
  FloatLimit := FloatingRegisterLimit(ATarget);
  if ALocation.PassMode = apmIndirect then
  begin
    { The object has already been copied by the caller; classify the replacing
      pointer, not the object's original memory-sized placeholder. }
    SetLength(ALocation.Parts, 1);
    ALocation.Parts[0].ValueClass := ascInteger;
    ALocation.Parts[0].BitOffset := 0;
    ALocation.Parts[0].BitWidth := ATarget.DataLayout.PointerBits;
    if AIntegerUsed < IntLimit then
    begin
      ALocation.Kind := alkIndirect;
      ALocation.Parts[0].RegisterNumber :=
        TargetIntegerArgumentRegister(ATarget, AIntegerUsed);
      ALocation.Parts[0].StackOffset := -1;
      Inc(AIntegerUsed);
    end
    else
    begin
      Slot := ABIStackSlotSize(ATarget);
      AStackOffset := AlignUp(AStackOffset, Slot);
      ALocation.Kind := alkStack;
      ALocation.Parts[0].RegisterNumber := -1;
      ALocation.Parts[0].StackOffset := Int64(AStackOffset);
      AStackOffset := AStackOffset + QWord(Slot);
    end;
    Exit;
  end;
  for I := 0 to High(ALocation.Parts) do
    if ALocation.Parts[I].ValueClass = ascMemory then
    begin
      Slot := ABIStackSlotSize(ATarget);
      AStackOffset := AlignUp(AStackOffset,
        MaxLongInt(Slot, ALocation.Alignment));
      ALocation.Kind := alkStack;
      ALocation.Parts[I].RegisterNumber := -1;
      ALocation.Parts[I].StackOffset := Int64(AStackOffset);
      AStackOffset := AStackOffset + AlignUp(ALocation.Size, Slot);
      Exit;
    end;
  NeededInteger := 0;
  NeededFloating := 0;
  for I := 0 to High(ALocation.Parts) do
  begin
    IsFloating := ALocation.Parts[I].ValueClass in
      [ascSSE, ascSSEUp, ascX87, ascX87Up, ascComplexX87];
    if IsFloating then Inc(NeededFloating) else Inc(NeededInteger);
  end;
  if (ATarget.Architecture = archRISCV64) and (NeededFloating > 0) and
     (((AFloatingUsed + NeededFloating) > FloatLimit) or
      ((NeededInteger > 0) and
       ((AIntegerUsed + NeededInteger) > IntLimit))) then
  begin
    { Named FP scalars and flattened aggregates fall back to the base integer
      convention when either required register bank is unavailable. }
    ConvertLocationToIntegerConvention(ALocation);
    NeededFloating := 0;
    NeededInteger := Length(ALocation.Parts);
  end;
  if (AIntegerUsed + NeededInteger <= IntLimit) and
     (AFloatingUsed + NeededFloating <= FloatLimit) then
  begin
    for I := 0 to High(ALocation.Parts) do
    begin
      IsFloating := ALocation.Parts[I].ValueClass in
        [ascSSE, ascSSEUp, ascX87, ascX87Up, ascComplexX87];
      if IsFloating then
      begin
        ALocation.Parts[I].RegisterNumber := AFloatingUsed;
        ALocation.Parts[I].StackOffset := -1;
        Inc(AFloatingUsed);
      end
      else
      begin
        ALocation.Parts[I].RegisterNumber :=
          TargetIntegerArgumentRegister(ATarget, AIntegerUsed);
        ALocation.Parts[I].StackOffset := -1;
        Inc(AIntegerUsed);
      end;
    end;
    Exit;
  end;
  if (ATarget.Architecture = archRISCV64) and
     (NeededFloating = 0) and (NeededInteger = 2) and
     (AIntegerUsed = IntLimit - 1) then
  begin
    { RV64 explicitly splits a two-word scalar/aggregate between the last
      argument register and the first outgoing stack slot. }
    Slot := ABIStackSlotSize(ATarget);
    ALocation.Kind := alkRegisterPair;
    ALocation.Parts[0].RegisterNumber :=
      TargetIntegerArgumentRegister(ATarget, AIntegerUsed);
    ALocation.Parts[0].StackOffset := -1;
    Inc(AIntegerUsed);
    AStackOffset := AlignUp(AStackOffset, Slot);
    ALocation.Parts[1].RegisterNumber := -1;
    ALocation.Parts[1].StackOffset := Int64(AStackOffset);
    AStackOffset := AStackOffset + QWord(Slot);
    Exit;
  end;
  if ATarget.Architecture = archAArch64 then
  begin
    if NeededFloating > 0 then AFloatingUsed := FloatLimit;
    if NeededInteger > 0 then AIntegerUsed := IntLimit;
    if ATarget.OperatingSystem = osDarwin then
    begin
      AssignLocationToDarwinCompactStack(ALocation, AStackOffset);
      Exit;
    end;
  end;
  Slot := ABIStackSlotSize(ATarget);
  AStackOffset := AlignUp(AStackOffset, MaxLongInt(Slot, ALocation.Alignment));
  ALocation.Kind := alkStack;
  for I := 0 to High(ALocation.Parts) do
  begin
    ALocation.Parts[I].RegisterNumber := -1;
    ALocation.Parts[I].StackOffset := Int64(AStackOffset + QWord(I * Slot));
  end;
  AStackOffset := AStackOffset + AlignUp(ALocation.Size, Slot);
end;

procedure AssignLocationToStack(var ALocation: TABIValueLocation;
  const ATarget: TTargetDescriptor; var AStackOffset: QWord);
var
  I, Slot: LongInt;
begin
  if ALocation.PassMode = apmIgnore then Exit;
  Slot := ABIStackSlotSize(ATarget);
  AStackOffset := AlignUp(AStackOffset,
    MaxLongInt(Slot, ALocation.Alignment));
  ALocation.Kind := alkStack;
  for I := 0 to High(ALocation.Parts) do
  begin
    ALocation.Parts[I].RegisterNumber := -1;
    ALocation.Parts[I].StackOffset := Int64(AStackOffset + QWord(I * Slot));
  end;
  AStackOffset := AStackOffset + AlignUp(ALocation.Size, Slot);
end;

procedure UseIntegerConventionForRISCVariadic(
  var ALocation: TABIValueLocation);
begin
  { The RISC-V psABI sends every unnamed argument through the base integer
    convention, including values whose named form would use fa0-fa7. }
  if ALocation.PassMode = apmIndirect then Exit;
  ConvertLocationToIntegerConvention(ALocation);
end;

function BuildFunctionABILayout(const AReturnType: TCType;
  const AParameters: array of TCType; AVariadic: Boolean;
  const ATarget: TTargetDescriptor;
  AFixedParameterCount: LongInt): TABIFunctionLayout;
var
  I, ReturnIntegerIndex, ReturnFloatingIndex: LongInt;
  StackOffset: QWord;
  MemoryReturn, ForceStack, RISCVVariadicStack: Boolean;
begin
  Result := TABIFunctionLayout.Create(ATarget);
  Result.Variadic := AVariadic;
  Result.ReturnLocation := ClassifyCTypeForABI(AReturnType, ATarget);
  MemoryReturn := (Length(Result.ReturnLocation.Parts) > 0) and
    (Result.ReturnLocation.Parts[0].ValueClass = ascMemory);
  if (Result.ReturnLocation.PassMode = apmIndirect) or MemoryReturn then
  begin
    Result.UsesHiddenReturnPointer := True;
    Result.ReturnLocation.Kind := alkHiddenPointer;
    { AAPCS64 dedicates x8 to the indirect result location. SysV AMD64 and
      RISC-V consume their first ordinary integer argument register. }
    if ATarget.Architecture = archAArch64 then
      Result.IntegerRegistersUsed := 0
    else
      Result.IntegerRegistersUsed := 1;
  end
  else if Length(Result.ReturnLocation.Parts) > 0 then
  begin
    ReturnIntegerIndex := 0;
    ReturnFloatingIndex := 0;
    for I := 0 to High(Result.ReturnLocation.Parts) do
      if Result.ReturnLocation.Parts[I].ValueClass in
        [ascSSE, ascSSEUp, ascX87, ascX87Up, ascComplexX87] then
      begin
        Result.ReturnLocation.Parts[I].RegisterNumber := ReturnFloatingIndex;
        Inc(ReturnFloatingIndex);
      end
      else
      begin
        case ATarget.Architecture of
          archX86_64:
            if ReturnIntegerIndex = 0 then
              Result.ReturnLocation.Parts[I].RegisterNumber := 0
            else Result.ReturnLocation.Parts[I].RegisterNumber := 2;
          archAArch64, archRISCV64:
            Result.ReturnLocation.Parts[I].RegisterNumber := ReturnIntegerIndex;
        else
          Result.ReturnLocation.Parts[I].RegisterNumber := ReturnIntegerIndex;
        end;
        Inc(ReturnIntegerIndex);
      end;
  end;
  SetLength(Result.Parameters, Length(AParameters));
  if AFixedParameterCount < 0 then
    AFixedParameterCount := Length(AParameters);
  StackOffset := 0;
  RISCVVariadicStack := False;
  for I := 0 to High(AParameters) do
  begin
    Result.Parameters[I] := ClassifyCTypeForABI(AParameters[I], ATarget);
    ForceStack := False;
    if AVariadic and (I >= AFixedParameterCount) then
    begin
      if ATarget.Architecture = archRISCV64 then
      begin
        UseIntegerConventionForRISCVariadic(Result.Parameters[I]);
        { Variadic values with 2*XLEN alignment and at most 2*XLEN size start
          in an even-numbered argument-register pair. If only a7 remains,
          the value goes wholly to the stack rather than being split. }
        if not RISCVVariadicStack and
           (Result.Parameters[I].PassMode = apmDirect) and
           (Result.Parameters[I].Alignment >= 16) and
           (Result.Parameters[I].Size > 8) and
           (Result.Parameters[I].Size <= 16) and
           ((Result.IntegerRegistersUsed and 1) <> 0) and
           (Result.IntegerRegistersUsed < 8) then
          Inc(Result.IntegerRegistersUsed);
        ForceStack := RISCVVariadicStack;
      end
      else if (ATarget.Architecture = archAArch64) and
              (ATarget.OperatingSystem = osDarwin) then
        ForceStack := True;
    end;
    if ForceStack then
      AssignLocationToStack(Result.Parameters[I], ATarget, StackOffset)
    else
      AssignLocationRegisters(Result.Parameters[I], ATarget,
        Result.IntegerRegistersUsed, Result.FloatingRegistersUsed, StackOffset);
    if AVariadic and (I >= AFixedParameterCount) and
       (ATarget.Architecture = archRISCV64) and
       (Result.Parameters[I].Kind = alkStack) then
      RISCVVariadicStack := True;
  end;
  Result.StackArgumentDataBytes := StackOffset;
  Result.StackArgumentBytes := AlignUp(StackOffset,
    Result.RequiredStackAlignment);
end;

function LocationText(const ALocation: TABIValueLocation): string;
var
  I: LongInt;
begin
  Result := ABILocationKindName(ALocation.Kind) + '/' +
    ABIPassModeName(ALocation.PassMode) + ' size=' + IntToStr(ALocation.Size);
  for I := 0 to High(ALocation.Parts) do
  begin
    Result := Result + LineEnding + '    part ' + IntToStr(I) + ': ' +
      ABIScalarClassName(ALocation.Parts[I].ValueClass);
    if ALocation.Parts[I].RegisterNumber >= 0 then
      Result := Result + ' reg=' + IntToStr(ALocation.Parts[I].RegisterNumber)
    else if ALocation.Parts[I].StackOffset >= 0 then
      Result := Result + ' stack=+' + IntToStr(ALocation.Parts[I].StackOffset);
  end;
end;

function FunctionABIText(ALayout: TABIFunctionLayout): string;
var
  Lines: TStringList;
  I: LongInt;
begin
  if ALayout = nil then Exit('<nil ABI layout>');
  Lines := TStringList.Create;
  try
    Lines.Add('ABI ' + ALayout.Target.Triple);
    Lines.Add('  return: ' + LocationText(ALayout.ReturnLocation));
    for I := 0 to High(ALayout.Parameters) do
      Lines.Add('  parameter ' + IntToStr(I) + ': ' +
        LocationText(ALayout.Parameters[I]));
    Lines.Add('  stack arguments: ' + IntToStr(ALayout.StackArgumentBytes));
    Lines.Add('  stack alignment: ' + IntToStr(ALayout.RequiredStackAlignment));
    Lines.Add('  variadic: ' + BoolToStr(ALayout.Variadic, True));
    Lines.Add('  hidden return pointer: ' +
      BoolToStr(ALayout.UsesHiddenReturnPointer, True));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
