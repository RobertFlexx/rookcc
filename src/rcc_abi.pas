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
  const ATarget: TTargetDescriptor): TABIFunctionLayout;
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
     (ATarget.Architecture <> archX86_64) then
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
      if ATarget.Architecture = archX86_64 then
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

procedure AssignLocationRegisters(var ALocation: TABIValueLocation;
  const ATarget: TTargetDescriptor; var AIntegerUsed, AFloatingUsed: LongInt;
  var AStackOffset: QWord);
var
  I, NeededInteger, NeededFloating, IntLimit, FloatLimit, Slot: LongInt;
  IsFloating: Boolean;
begin
  if ALocation.PassMode = apmIgnore then Exit;
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
  if ALocation.PassMode = apmIndirect then
  begin
    NeededInteger := 1;
    NeededFloating := 0;
  end;
  IntLimit := IntegerRegisterLimit(ATarget);
  FloatLimit := FloatingRegisterLimit(ATarget);
  if (AIntegerUsed + NeededInteger <= IntLimit) and
     (AFloatingUsed + NeededFloating <= FloatLimit) then
  begin
    if ALocation.PassMode = apmIndirect then
    begin
      ALocation.Kind := alkIndirect;
      SetLength(ALocation.Parts, 1);
      ALocation.Parts[0].ValueClass := ascInteger;
      ALocation.Parts[0].RegisterNumber :=
        TargetIntegerArgumentRegister(ATarget, AIntegerUsed);
      ALocation.Parts[0].StackOffset := -1;
      ALocation.Parts[0].BitOffset := 0;
      ALocation.Parts[0].BitWidth := ATarget.DataLayout.PointerBits;
      Inc(AIntegerUsed);
      Exit;
    end;
    for I := 0 to High(ALocation.Parts) do
    begin
      IsFloating := ALocation.Parts[I].ValueClass in
        [ascSSE, ascSSEUp, ascX87, ascX87Up, ascComplexX87];
      if IsFloating then
      begin
        ALocation.Parts[I].RegisterNumber := AFloatingUsed;
        Inc(AFloatingUsed);
      end
      else
      begin
        ALocation.Parts[I].RegisterNumber :=
          TargetIntegerArgumentRegister(ATarget, AIntegerUsed);
        Inc(AIntegerUsed);
      end;
    end;
    Exit;
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

function BuildFunctionABILayout(const AReturnType: TCType;
  const AParameters: array of TCType; AVariadic: Boolean;
  const ATarget: TTargetDescriptor): TABIFunctionLayout;
var
  I, ReturnIntegerIndex, ReturnFloatingIndex: LongInt;
  StackOffset: QWord;
  MemoryReturn: Boolean;
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
  StackOffset := 0;
  for I := 0 to High(AParameters) do
  begin
    Result.Parameters[I] := ClassifyCTypeForABI(AParameters[I], ATarget);
    AssignLocationRegisters(Result.Parameters[I], ATarget,
      Result.IntegerRegistersUsed, Result.FloatingRegistersUsed, StackOffset);
  end;
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
