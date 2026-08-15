unit rcc_cross_codegen;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_arch, rcc_buffer;

type
  TCrossCodegenStats = record
    TextBytes: QWord;
    DataBytes: QWord;
    FunctionsEmitted: QWord;
    InstructionsEmitted: QWord;
    Target: string;
  end;

procedure GenerateCrossIntegerExecutable(AProgram: TProgram;
  const ATarget: TTargetDescriptor; const AFileName: string;
  out AStats: TCrossCodegenStats);
procedure GenerateCrossIntegerObject(AProgram: TProgram;
  const ATarget: TTargetDescriptor; const AFileName: string;
  out AStats: TCrossCodegenStats);

implementation

uses
  rcc_typeops, rcc_abi, rcc_elf_image, rcc_object_model, rcc_object_writer;

type
  TCrossFixupKind = (
    cfA64Branch,
    cfA64Call,
    cfA64Zero,
    cfA64NonZero,
    cfRISCVJump,
    cfRISCVCall,
    cfRISCVZero,
    cfRISCVNonZero
  );

  TCrossLabel = record
    Offset: LongInt;
  end;

  TCrossFixup = record
    PatchOffset: LongInt;
    TargetLabel: LongInt;
    Kind: TCrossFixupKind;
  end;

  TCrossNamedLabel = record
    Name: string;
    LabelID: LongInt;
  end;

  TCrossLocal = record
    Name: string;
    Offset: LongInt;
    CType: TCType;
    ScopeDepth: LongInt;
  end;

  TCrossGlobal = record
    Name: string;
    Offset: LongInt;
    Size: LongInt;
    CType: TCType;
    IsStatic: Boolean;
  end;

  TCrossStringLiteral = record
    Value: string;
    GlobalIndex: LongInt;
  end;

  TCrossGlobalFixup = record
    PatchOffset: LongInt;
    GlobalIndex: LongInt;
  end;

  { A pointer stored in initialized data that names another global; the target
    address is only known once the data segment has been placed. }
  TCrossDataPointerFixup = record
    DataOffset: LongInt;
    GlobalIndex: LongInt;
  end;

  TCrossUserLabel = record
    Name: string;
    LabelID: LongInt;
  end;

  { A static local has program lifetime, so it is laid out as a global but
    only visible inside the function that declared it. }
  TCrossStaticLocal = record
    FunctionName: string;
    VariableName: string;
    GlobalIndex: LongInt;
  end;

  TCrossSwitchEntry = record
    Statement: TStmt;
    TargetLabel: LongInt;
    IsDefault: Boolean;
    Value: Int64;
  end;
  TCrossSwitchEntryArray = array of TCrossSwitchEntry;

  TCrossExternalCall = record
    Name: string;
    PatchOffset: LongInt;
  end;

  TCrossIntegerBackend = class
  private
    FProgram: TProgram;
    FTarget: TTargetDescriptor;
    FText: TByteBuffer;
    FData: TByteBuffer;
    FLabels: array of TCrossLabel;
    FFixups: array of TCrossFixup;
    FFunctions: array of TCrossNamedLabel;
    FLocals: array of TCrossLocal;
    FGlobals: array of TCrossGlobal;
    FStrings: array of TCrossStringLiteral;
    FGlobalFixups: array of TCrossGlobalFixup;
    FDataPointerFixups: array of TCrossDataPointerFixup;
    FDataFunctionFixups: array of TCrossDataPointerFixup;
    FFunctionAddressFixups: array of TCrossGlobalFixup;
    FUserLabels: array of TCrossUserLabel;
    FStaticLocals: array of TCrossStaticLocal;
    FCurrentFunctionName: string;
    FExternalCalls: array of TCrossExternalCall;
    FSyscallSites: TTargetSyscallSiteArray;
    FBreakLabels: array of LongInt;
    FContinueLabels: array of LongInt;
    FScopeDepth: LongInt;
    FNextLocalOffset: LongInt;
    FFrameSize: LongInt;
    FLocalLimit: LongInt;
    FPrologueRAOffset: LongInt;
    FPrologueFPOffset: LongInt;
    FEpilogueLabel: LongInt;
    FCurrentReturnType: TCType;
    FCurrentReturnLocation: TABIValueLocation;
    FCurrentUsesHiddenReturn: Boolean;
    FCurrentSRetOffset: LongInt;
    FCurrentIsVariadic: Boolean;
    FCurrentVarArgSaveOffset: LongInt;
    FCurrentVarArgGPUsed: LongInt;
    FCurrentVarArgFPUsed: LongInt;
    FCurrentVarArgStackOffset: LongInt;
    FInstructionCount: QWord;
    FFunctionsEmitted: QWord;
    FObjectMode: Boolean;
    function AlignUp(AValue, AAlignment: LongInt): LongInt;
    function NewLabel: LongInt;
    procedure BindLabel(ALabel: LongInt);
    procedure AddFixup(APatchOffset, ATargetLabel: LongInt;
      AKind: TCrossFixupKind);
    procedure EmitWord(AInstruction: LongWord);
    function FindFunctionLabel(const AName: string): LongInt;
    procedure ReserveFunctionLabels;
    procedure ResolveFixups;
    procedure AllocateGlobals;
    function AddStringLiteral(const AValue: string): LongInt;
    function FindGlobal(const AName: string; out AIndex: LongInt;
      out AType: TCType): Boolean;
    procedure EmitGlobalAddress(AGlobalIndex: LongInt);
    procedure ResolveGlobalFixups(ADataAddress: QWord);
    procedure ResolveFunctionAddressFixups(ATextAddress: QWord);
    procedure EmitLoadAtAddress(const AType: TCType);
    procedure EmitStoreAtAddress(const AType: TCType);
    procedure EmitExtractBitField(const AType: TCType;
      ABitOffset, ABitWidth: LongInt);
    procedure EmitLoadBitField(const AType: TCType;
      ABitOffset, ABitWidth: LongInt);
    procedure EmitStoreBitFieldAtAddress(const AType: TCType;
      ABitOffset, ABitWidth: LongInt);
    procedure EmitLoadGlobal(AGlobalIndex: LongInt; const AType: TCType);
    procedure EmitStoreGlobal(AGlobalIndex: LongInt; const AType: TCType);
    function CountDeclarations(AStatement: TStmt): LongInt;
    procedure AddLocal(const AName: string; const AType: TCType;
      out AOffset: LongInt);
    function FindLocal(const AName: string; out AOffset: LongInt;
      out AType: TCType): Boolean;
    procedure EnterScope;
    procedure LeaveScope(ASavedCount: LongInt);
    procedure PushLoop(ABreakLabel, AContinueLabel: LongInt);
    procedure PopLoop;
    procedure RequireScalar(const AType: TCType; const APos: TSourcePos;
      const AContext: string);
    procedure RequireRegisterValue(const AType: TCType;
      const APos: TSourcePos; const AContext: string);
    function CountExpressionTemporaryBytes(AExpression: TExpr): LongInt;
    function CountLocalBytes(AStatement: TStmt): LongInt;
    procedure EmitLocalAddress(AOffset: LongInt);
    procedure EmitAddLargeImmediate(AValue: Int64);
    procedure EmitMoveAccumulatorToLeft;
    procedure EmitMoveLeftToAccumulator;
    procedure EmitMoveAccumulatorToRegister(ARegister: LongInt);
    procedure EmitMoveStackPointerToAccumulator;
    procedure EmitStackAddress(AOffset: LongInt);
    procedure EmitAdjustStack(AAmount: LongInt);
    procedure EmitLoadLocalToIntegerRegister(AOffset, ARegister: LongInt);
    procedure EmitLoadLocalPartToIntegerRegister(AOffset, ARegister,
      ABitWidth: LongInt);
    procedure EmitStoreIntegerRegisterToLocal(ARegister, AOffset: LongInt);
    procedure EmitStoreIntegerRegisterToLocalPart(ARegister, AOffset,
      ABitWidth: LongInt);
    procedure EmitLoadLocalToFloatRegister(AOffset, ARegister: LongInt;
      const AType: TCType);
    procedure EmitStoreFloatRegisterToLocal(ARegister, AOffset: LongInt;
      const AType: TCType);
    procedure EmitCopyLocalToStack(ASourceOffset, ADestinationOffset,
      ASize: LongInt);
    procedure EmitPushAggregate(ASize: LongInt);
    procedure EmitPopArgumentPair(AIndex: LongInt);
    function AggregateRegisterCount(const AType: TCType): LongInt;
    procedure EmitPopAccumulator;
    procedure EmitCopyBlock(ASize: LongInt);
    function AllocateTemporary(ASize, AAlignment: LongInt): LongInt;
    function AllocateTemporarySlot: LongInt;
    procedure EmitZeroLocalBlock(AOffset, ASize: LongInt);
    procedure GenAddress(AExpression: TExpr);
    function TryGlobalConstantAddress(AExpression: TExpr;
      out AGlobalIndex: LongInt): Boolean;
    function TryConstantFunctionLabel(AExpression: TExpr): LongInt;
    procedure EmitGlobalObject(const AType: TCType; AInitializer: TExpr;
      const APos: TSourcePos);
    procedure InitializeLocalAt(ABaseOffset, AByteOffset: LongInt;
      const AType: TCType; AInitializer: TExpr; const APos: TSourcePos);
    function FindUserLabel(const AName: string): LongInt;
    procedure ReserveUserLabels(AStatement: TStmt);
    procedure CollectSwitchEntries(AStatement: TStmt;
      var AEntries: TCrossSwitchEntryArray);
    procedure GenSwitchBody(AStatement: TStmt;
      const AEntries: TCrossSwitchEntryArray);
    function SwitchTargetFor(AStatement: TStmt;
      const AEntries: TCrossSwitchEntryArray): LongInt;
    procedure EmitFunctionAddress(ALabel: LongInt);
    procedure EmitIndirectCall;
    procedure InternInitializerLiterals(const AType: TCType;
      AExpression: TExpr);
    procedure ReserveStaticLocals(AStatement: TStmt);
    function FindStaticLocal(const AName: string;
      out AGlobalIndex: LongInt; out AType: TCType): Boolean;
    function CountSwitchSlots(AStatement: TStmt): LongInt;
    procedure EmitLoadImmediate(AValue: Int64);
    procedure EmitFloatImmediate(AValue: Double; const AType: TCType);
    procedure EmitNormalize(const AType: TCType);
    procedure EmitBitsToFloatAccumulator(const AType: TCType);
    procedure EmitAccumulatorToFloatRegister(ARegister: LongInt;
      const AType: TCType);
    procedure EmitFloatAccumulatorToBits(const AType: TCType);
    procedure EmitFloatRegisterToAccumulator(ARegister: LongInt;
      const AType: TCType);
    procedure EmitLeftBitsToFloatScratch(const AType: TCType);
    procedure EmitFloatingBinary(AOperation: TBinaryOp;
      const AType: TCType);
    procedure EmitFloatToBool(const AType: TCType);
    procedure EmitConvertIntegerToFloat(const AFromType, AToType: TCType);
    procedure EmitConvertFloatToInteger(const AFromType, AToType: TCType);
    procedure EmitConvertFloatWidth(const AFromType, AToType: TCType);
    procedure EmitPushResult;
    procedure EmitLoadStackValue(AOffset: LongInt);
    procedure EmitPopLeft;
    procedure EmitPopArgument(AIndex: LongInt);
    procedure EmitLoadLocal(AOffset: LongInt);
    procedure EmitStoreLocal(AOffset: LongInt);
    procedure EmitAddImmediate(AValue: LongInt);
    procedure EmitBinary(AOperation: TBinaryOp; AUnsigned: Boolean);
    procedure EmitJump(ALabel: LongInt);
    procedure EmitJumpIfZero(ALabel: LongInt);
    procedure EmitJumpIfNonZero(ALabel: LongInt);
    procedure EmitCall(ALabel: LongInt);
    procedure EmitExternalCall(const AName: string);
    procedure GenExpr(AExpression: TExpr);
    procedure GenExprAsFloating(AExpression: TExpr; const AType: TCType);
    procedure GenExprConverted(AExpression: TExpr; const AType: TCType);
    procedure GenCondition(AExpression: TExpr);
    function TryGenVariadicBuiltin(AExpression: TExpr): Boolean;
    procedure GenAssignment(AExpression: TExpr);
    procedure GenIncDec(AExpression: TExpr; ADelta: LongInt;
      APost: Boolean);
    procedure GenStmt(AStatement: TStmt);
    procedure GenFunction(AFunction: TFunction; ALabel: LongInt);
    procedure EmitStartup;
    procedure GenerateFunctions;
    function FunctionSize(ALabel: LongInt): QWord;
    procedure WriteObject(const AFileName: string);
  public
    constructor Create(AProgram: TProgram; const ATarget: TTargetDescriptor;
      AObjectMode: Boolean);
    destructor Destroy; override;
    procedure GenerateExecutable(const AFileName: string;
      out AStats: TCrossCodegenStats);
    procedure GenerateObject(const AFileName: string;
      out AStats: TCrossCodegenStats);
  end;

function EncodeRISCVR(AFunct7: LongWord; ARs2, ARs1: LongInt;
  AFunct3: LongWord; ARd: LongInt; AOpcode: LongWord): LongWord;
begin
  Result := (AFunct7 and $7F) shl 25;
  Result := Result or (LongWord(ARs2 and 31) shl 20);
  Result := Result or (LongWord(ARs1 and 31) shl 15);
  Result := Result or ((AFunct3 and 7) shl 12);
  Result := Result or (LongWord(ARd and 31) shl 7) or (AOpcode and $7F);
end;

function EncodeRISCVI(AImmediate: LongInt; ARs1: LongInt;
  AFunct3: LongWord; ARd: LongInt; AOpcode: LongWord): LongWord;
begin
  Result := (LongWord(AImmediate) and $FFF) shl 20;
  Result := Result or (LongWord(ARs1 and 31) shl 15);
  Result := Result or ((AFunct3 and 7) shl 12);
  Result := Result or (LongWord(ARd and 31) shl 7) or (AOpcode and $7F);
end;

function EncodeRISCVS(AImmediate: LongInt; ARs2, ARs1: LongInt;
  AFunct3: LongWord): LongWord;
var
  U: LongWord;
begin
  U := LongWord(AImmediate) and $FFF;
  Result := ((U shr 5) and $7F) shl 25;
  Result := Result or (LongWord(ARs2 and 31) shl 20);
  Result := Result or (LongWord(ARs1 and 31) shl 15);
  Result := Result or ((AFunct3 and 7) shl 12);
  Result := Result or ((U and $1F) shl 7) or $23;
end;

function EncodeRISCVStore(AImmediate: LongInt; ARs2, ARs1: LongInt;
  AFunct3, AOpcode: LongWord): LongWord;
var
  U: LongWord;
begin
  U := LongWord(AImmediate) and $FFF;
  Result := ((U shr 5) and $7F) shl 25;
  Result := Result or (LongWord(ARs2 and 31) shl 20);
  Result := Result or (LongWord(ARs1 and 31) shl 15);
  Result := Result or ((AFunct3 and 7) shl 12);
  Result := Result or ((U and $1F) shl 7) or (AOpcode and $7F);
end;

function EncodeRISCVB(AOffset: LongInt; ARs2, ARs1: LongInt;
  AFunct3: LongWord): LongWord;
var
  U: LongWord;
begin
  if (AOffset and 1) <> 0 then
    raise ERCCError.Create('internal error: unaligned RISC-V branch');
  U := LongWord(AOffset);
  Result := ((U shr 12) and 1) shl 31;
  Result := Result or (((U shr 5) and $3F) shl 25);
  Result := Result or (LongWord(ARs2 and 31) shl 20);
  Result := Result or (LongWord(ARs1 and 31) shl 15);
  Result := Result or ((AFunct3 and 7) shl 12);
  Result := Result or (((U shr 1) and $F) shl 8);
  Result := Result or (((U shr 11) and 1) shl 7) or $63;
end;

function EncodeRISCVJAL(ARd: LongInt; AOffset: LongInt): LongWord;
var
  U: LongWord;
begin
  if (AOffset and 1) <> 0 then
    raise ERCCError.Create('internal error: unaligned RISC-V jump');
  U := LongWord(AOffset);
  Result := ((U shr 20) and 1) shl 31;
  Result := Result or (((U shr 1) and $3FF) shl 21);
  Result := Result or (((U shr 11) and 1) shl 20);
  Result := Result or (((U shr 12) and $FF) shl 12);
  Result := Result or (LongWord(ARd and 31) shl 7) or $6F;
end;

function CrossBitFieldMask(AWidth: LongInt): QWord;
begin
  if AWidth <= 0 then Exit(0);
  if AWidth >= 64 then Exit(not QWord(0));
  Result := (QWord(1) shl AWidth) - 1;
end;

{ Fold the constant floating expressions accepted in static initializers.
  Keeping this here avoids making the target-independent evaluator depend on
  host floating-point bit layouts; bytes are materialized only by this
  little-endian AArch64/RISC-V backend. }
function TryEvaluateCrossConstantFloat(AExpression: TExpr;
  out AValue: Double): Boolean;
var
  LeftValue, RightValue: Double;
  IntegerValue: Int64;
begin
  Result := False;
  AValue := 0.0;
  if AExpression = nil then Exit;
  case AExpression.Kind of
    ekFloat:
      begin
        AValue := AExpression.FloatValue;
        Exit(True);
      end;
    ekInteger:
      begin
        AValue := AExpression.IntValue;
        Exit(True);
      end;
    ekCast:
      begin
        if not TryEvaluateCrossConstantFloat(AExpression.Left, AValue) then
          Exit;
        if IsIntegerType(AExpression.CType) and
           not IsPointerType(AExpression.CType) then
          AValue := Trunc(AValue)
        else if AExpression.CType.Kind = ctFloat then
          AValue := Single(AValue);
        Exit(True);
      end;
    ekUnary:
      begin
        if not TryEvaluateCrossConstantFloat(AExpression.Left, LeftValue) then
          Exit;
        case AExpression.UnaryOp of
          uoPositive: AValue := LeftValue;
          uoNegative: AValue := -LeftValue;
        else
          Exit;
        end;
        Exit(True);
      end;
    ekBinary:
      begin
        if not TryEvaluateCrossConstantFloat(AExpression.Left, LeftValue) or
           not TryEvaluateCrossConstantFloat(AExpression.Right, RightValue) then
          Exit;
        case AExpression.BinaryOp of
          boAdd: AValue := LeftValue + RightValue;
          boSub: AValue := LeftValue - RightValue;
          boMul: AValue := LeftValue * RightValue;
          boDiv:
            begin
              if RightValue = 0.0 then Exit;
              AValue := LeftValue / RightValue;
            end;
        else
          Exit;
        end;
        Exit(True);
      end;
  end;
  if EvaluateIntegerConstantExpression(AExpression, IntegerValue) then
  begin
    AValue := IntegerValue;
    Result := True;
  end;
end;

constructor TCrossIntegerBackend.Create(AProgram: TProgram;
  const ATarget: TTargetDescriptor; AObjectMode: Boolean);
begin
  inherited Create;
  FProgram := AProgram;
  FTarget := ATarget;
  FObjectMode := AObjectMode;
  FText := TByteBuffer.Create;
  FData := TByteBuffer.Create;
end;

destructor TCrossIntegerBackend.Destroy;
begin
  FData.Free;
  FText.Free;
  inherited Destroy;
end;

{ Label of a function named by a constant initializer, or -1. }
function TCrossIntegerBackend.TryConstantFunctionLabel(
  AExpression: TExpr): LongInt;
begin
  Result := -1;
  if AExpression = nil then Exit;
  if AExpression.Kind = ekCast then
    Exit(TryConstantFunctionLabel(AExpression.Left));
  if (AExpression.Kind = ekAddress) and (AExpression.Left <> nil) then
    Exit(TryConstantFunctionLabel(AExpression.Left));
  if (AExpression.Kind = ekVariable) and AExpression.IsFunctionDesignator then
    Exit(FindFunctionLabel(AExpression.Text));
end;

{ Recognizes initializers that denote the address of another global, which is
  how string literals and array names appear in static data. }
function TCrossIntegerBackend.TryGlobalConstantAddress(AExpression: TExpr;
  out AGlobalIndex: LongInt): Boolean;
var
  GlobalType: TCType;
begin
  Result := False;
  AGlobalIndex := -1;
  if AExpression = nil then Exit;
  case AExpression.Kind of
    ekString:
      begin
        AGlobalIndex := AddStringLiteral(AExpression.Text);
        Exit(True);
      end;
    ekAddress:
      begin
        if (AExpression.Left <> nil) and
           (AExpression.Left.Kind = ekVariable) then
          Exit(FindGlobal(AExpression.Left.Text, AGlobalIndex, GlobalType));
      end;
    ekVariable:
      begin
        if IsArrayType(AExpression.CType) or
           AExpression.IsFunctionDesignator then
          Exit(FindGlobal(AExpression.Text, AGlobalIndex, GlobalType));
      end;
    ekCast: Exit(TryGlobalConstantAddress(AExpression.Left, AGlobalIndex));
  end;
end;

{ Emits the static image of one object, recursing through aggregates the same
  way the native backend does. }
procedure TCrossIntegerBackend.EmitGlobalObject(const AType: TCType;
  AInitializer: TExpr; const APos: TSourcePos);
var
  Size, Count, I, J, StartOffset, TargetOffset, GlobalIndex, N,
    GroupOffset, GroupSize: LongInt;
  ElementType, MemberType: TCType;
  Value: Int64;
  PackedValue, MemberValue, Mask, FloatBits64: QWord;
  FloatBits32: LongWord;
  FloatValue: Double;
  SingleValue: Single;
  Member: TStructMember;
  ItemInitializer: TExpr;

  procedure AddZeros(AAmount: LongInt);
  var
    Z: LongInt;
  begin
    for Z := 1 to AAmount do FData.Add8(0);
  end;

  procedure AddPackedInteger(AValue: QWord; ASize: LongInt);
  begin
    case ASize of
      1: FData.Add8(Byte(AValue));
      2: FData.Add16(Word(AValue));
      4: FData.Add32(LongWord(AValue));
      8: FData.Add64(AValue);
    else
      RaiseCompileError(APos, 'unsupported bit-field allocation-unit size');
    end;
  end;

  function IntegerInitializer(AExpression: TExpr): QWord;
  var
    ConstantValue: Int64;
  begin
    if AExpression = nil then Exit(0);
    if not EvaluateIntegerConstantExpression(AExpression, ConstantValue) then
      RaiseCompileError(AExpression.Pos,
        'global bit-field initializer is not an integer constant expression');
    Result := QWord(ConstantValue);
  end;

begin
  Size := StorageSize(AType);
  if AInitializer = nil then
  begin
    AddZeros(Size);
    Exit;
  end;

  if IsArrayType(AType) then
  begin
    ElementType := ElementTypeOf(AType);
    StartOffset := FData.Size;
    if (AInitializer.Kind = ekString) and (ElementType.Kind = ctChar) and
       (ElementType.PointerDepth = 0) then
    begin
      Count := Length(AInitializer.Text);
      if Count >= AType.ArrayLength then Count := LongInt(AType.ArrayLength) - 1;
      for I := 1 to Count do FData.Add8(Byte(Ord(AInitializer.Text[I])));
      if FData.Size - StartOffset < AType.ArrayLength then FData.Add8(0);
    end
    else if AInitializer.Kind = ekCompoundLit then
    begin
      for I := 0 to LongInt(AType.ArrayLength) - 1 do
        if I <= High(AInitializer.Args) then
          EmitGlobalObject(ElementType, AInitializer.Args[I], APos)
        else
          EmitGlobalObject(ElementType, nil, APos);
    end;
    while FData.Size - StartOffset < Size do FData.Add8(0);
    if FData.Size - StartOffset > Size then
      RaiseCompileError(APos, 'initializer is too large for array object');
    Exit;
  end;

  if (AType.PointerDepth = 0) and (AType.Kind in [ctStruct, ctUnion]) then
  begin
    if AType.StructInfo = nil then
      RaiseCompileError(APos, 'cannot allocate incomplete aggregate type');
    StartOffset := FData.Size;
    if AInitializer.Kind <> ekCompoundLit then
      RaiseCompileError(APos, 'aggregate initializer requires braces');
    if AType.Kind = ctUnion then
    begin
      if Length(AType.StructInfo^.Members) > 0 then
      begin
        Member := AType.StructInfo^.Members[0];
        ItemInitializer := nil;
        if Length(AInitializer.Args) > 0 then
          ItemInitializer := AInitializer.Args[0];
        if Member.IsBitField then
        begin
          Mask := CrossBitFieldMask(Member.BitWidth);
          PackedValue := (IntegerInitializer(ItemInitializer) and Mask)
            shl Member.BitOffset;
          AddPackedInteger(PackedValue, Member.Width);
        end
        else
          EmitGlobalObject(PCType(Member.CType)^, ItemInitializer, APos);
      end;
    end
    else
    begin
      I := 0;
      while I <= High(AType.StructInfo^.Members) do
      begin
        Member := AType.StructInfo^.Members[I];
        if Member.IsBitField then
        begin
          GroupOffset := Member.Offset;
          GroupSize := Member.Width;
          PackedValue := 0;
          J := I;
          while (J <= High(AType.StructInfo^.Members)) and
            AType.StructInfo^.Members[J].IsBitField and
            (AType.StructInfo^.Members[J].Offset = GroupOffset) and
            (AType.StructInfo^.Members[J].Width = GroupSize) do
          begin
            Member := AType.StructInfo^.Members[J];
            ItemInitializer := nil;
            if J <= High(AInitializer.Args) then
              ItemInitializer := AInitializer.Args[J];
            MemberValue := IntegerInitializer(ItemInitializer);
            Mask := CrossBitFieldMask(Member.BitWidth);
            PackedValue := PackedValue or
              ((MemberValue and Mask) shl Member.BitOffset);
            Inc(J);
          end;
          TargetOffset := StartOffset + GroupOffset;
          while FData.Size < TargetOffset do FData.Add8(0);
          if FData.Size <> TargetOffset then
            RaiseCompileError(APos,
              'overlapping aggregate initialization layout');
          AddPackedInteger(PackedValue, GroupSize);
          I := J;
          Continue;
        end;
        TargetOffset := StartOffset + Member.Offset;
        while FData.Size < TargetOffset do FData.Add8(0);
        if FData.Size <> TargetOffset then
          RaiseCompileError(APos,
            'overlapping aggregate initialization layout');
        MemberType := PCType(Member.CType)^;
        if I <= High(AInitializer.Args) then
          ItemInitializer := AInitializer.Args[I]
        else
          ItemInitializer := nil;
        EmitGlobalObject(MemberType, ItemInitializer, APos);
        Inc(I);
      end;
    end;
    while FData.Size - StartOffset < Size do FData.Add8(0);
    if FData.Size - StartOffset > Size then
      RaiseCompileError(APos, 'aggregate initializer exceeds object size');
    Exit;
  end;

  if IsPointerType(AType) then
  begin
    { A static pointer to a function records the callee's text address. }
    GlobalIndex := TryConstantFunctionLabel(AInitializer);
    if GlobalIndex >= 0 then
    begin
      N := Length(FDataFunctionFixups);
      SetLength(FDataFunctionFixups, N + 1);
      FDataFunctionFixups[N].DataOffset := FData.Size;
      FDataFunctionFixups[N].GlobalIndex := GlobalIndex;
      AddZeros(8);
      Exit;
    end;
    if TryGlobalConstantAddress(AInitializer, GlobalIndex) then
    begin
      N := Length(FDataPointerFixups);
      SetLength(FDataPointerFixups, N + 1);
      FDataPointerFixups[N].DataOffset := FData.Size;
      FDataPointerFixups[N].GlobalIndex := GlobalIndex;
      AddZeros(8);
      Exit;
    end;
  end;

  if IsFloatingType(AType) then
  begin
    if (AType.Kind = ctLongDouble) and (StorageSize(AType) <> 8) then
      RaiseCompileError(APos,
        'long double is not supported by the cross-target backend');
    if not TryEvaluateCrossConstantFloat(AInitializer, FloatValue) then
      RaiseCompileError(APos,
        'cross-target floating initializer must be a constant expression');
    if AType.Kind = ctFloat then
    begin
      SingleValue := FloatValue;
      Move(SingleValue, FloatBits32, SizeOf(FloatBits32));
      FData.Add32(FloatBits32);
    end
    else
    begin
      Move(FloatValue, FloatBits64, SizeOf(FloatBits64));
      FData.Add64(FloatBits64);
    end;
    Exit;
  end;

  Value := 0;
  if not EvaluateIntegerConstantExpression(AInitializer, Value) then
    RaiseCompileError(APos,
      'cross-target global initializer must be a constant expression');
  Value := ConvertIntegerValue(Value, AType);
  for I := 0 to Size - 1 do
    FData.Add8(Byte(QWord(Value) shr (I * 8)));
end;

{ A string literal used as a pointer value becomes its own global, so it has to
  be interned before any object's bytes are laid out. A string filling a char
  array is inlined instead and needs no literal. }
procedure TCrossIntegerBackend.InternInitializerLiterals(const AType: TCType;
  AExpression: TExpr);
var
  J: LongInt;
  ElementType: TCType;
begin
  if AExpression = nil then Exit;
  if IsArrayType(AType) then
  begin
    ElementType := ElementTypeOf(AType);
    if (AExpression.Kind = ekString) and (ElementType.Kind = ctChar) and
       (ElementType.PointerDepth = 0) then Exit;
    if AExpression.Kind = ekCompoundLit then
      for J := 0 to High(AExpression.Args) do
        InternInitializerLiterals(ElementType, AExpression.Args[J]);
    Exit;
  end;
  if (AType.PointerDepth = 0) and (AType.Kind in [ctStruct, ctUnion]) and
     (AType.StructInfo <> nil) and (AExpression.Kind = ekCompoundLit) then
  begin
    for J := 0 to High(AExpression.Args) do
      if J <= High(AType.StructInfo^.Members) then
        InternInitializerLiterals(PCType(AType.StructInfo^.Members[J].CType)^,
          AExpression.Args[J]);
    Exit;
  end;
  if IsPointerType(AType) and (AExpression.Kind = ekString) then
    AddStringLiteral(AExpression.Text);
end;

procedure TCrossIntegerBackend.AllocateGlobals;
var
  I, N: LongInt;
  Global: TGlobal;

begin
  for I := 0 to High(FProgram.Globals) do
  begin
    Global := FProgram.Globals[I];
    if Global.IsExtern then Continue;
    InternInitializerLiterals(Global.CType, Global.Initializer);
  end;

  for I := 0 to High(FProgram.Globals) do
  begin
    Global := FProgram.Globals[I];
    if Global.IsExtern then Continue;
    FData.PadTo(StorageAlign(Global.CType));
    N := Length(FGlobals);
    SetLength(FGlobals, N + 1);
    FGlobals[N].Name := Global.Name;
    FGlobals[N].Offset := FData.Size;
    FGlobals[N].Size := StorageSize(Global.CType);
    FGlobals[N].CType := Global.CType;
    FGlobals[N].IsStatic := Global.IsStatic;
    EmitGlobalObject(Global.CType, Global.Initializer, Global.Pos);
  end;

  { Static locals share the data segment, so they are laid out here too. }
  for I := 0 to High(FProgram.Functions) do
    if not FProgram.Functions[I].IsPrototype then
    begin
      FCurrentFunctionName := FProgram.Functions[I].Name;
      ReserveStaticLocals(FProgram.Functions[I].Body);
    end;
  FCurrentFunctionName := '';
end;

function TCrossIntegerBackend.AddStringLiteral(
  const AValue: string): LongInt;
var
  I, N, GlobalIndex: LongInt;
begin
  for I := 0 to High(FStrings) do
    if FStrings[I].Value = AValue then
      Exit(FStrings[I].GlobalIndex);
  GlobalIndex := Length(FGlobals);
  SetLength(FGlobals, GlobalIndex + 1);
  FGlobals[GlobalIndex].Name := '__rcc_string_' +
    IntToStr(Length(FStrings));
  FGlobals[GlobalIndex].Offset := FData.Size;
  FGlobals[GlobalIndex].Size := Length(AValue) + 1;
  FGlobals[GlobalIndex].CType := MakeType(ctChar);
  FGlobals[GlobalIndex].IsStatic := True;
  FData.AddStringZ(AValue);
  N := Length(FStrings);
  SetLength(FStrings, N + 1);
  FStrings[N].Value := AValue;
  FStrings[N].GlobalIndex := GlobalIndex;
  Result := GlobalIndex;
end;

function TCrossIntegerBackend.FindGlobal(const AName: string;
  out AIndex: LongInt; out AType: TCType): Boolean;
var
  I: LongInt;
begin
  for I := High(FGlobals) downto 0 do
    if FGlobals[I].Name = AName then
    begin
      AIndex := I;
      AType := FGlobals[I].CType;
      Exit(True);
    end;
  AIndex := -1;
  AType := MakeType(ctVoid);
  Result := False;
end;

procedure TCrossIntegerBackend.EmitGlobalAddress(AGlobalIndex: LongInt);
var
  N, P: LongInt;
begin
  if (AGlobalIndex < 0) or (AGlobalIndex > High(FGlobals)) then
    raise ERCCError.Create('internal error: invalid cross global index');
  P := FText.Size;
  if FTarget.Architecture = archAArch64 then
  begin
    if FObjectMode and (FTarget.ObjectFormat = ofMachO64) then
    begin
      { Darwin uses the normal page/page-offset address materialization pair.
        The Mach-O writer attaches ARM64_RELOC_PAGE21 and PAGEOFF12. }
      EmitWord($90000000); { adrp x0, symbol@PAGE }
      EmitWord($91000000); { add  x0, x0, symbol@PAGEOFF }
    end
    else
    begin
      EmitWord($D2800000);
      EmitWord($F2A00000);
      EmitWord($F2C00000);
      EmitWord($F2E00000);
    end;
  end
  else
  begin
    EmitWord(LongWord(10 shl 7) or $37);
    EmitWord(EncodeRISCVI(0, 10, 0, 10, $13));
  end;
  N := Length(FGlobalFixups);
  SetLength(FGlobalFixups, N + 1);
  FGlobalFixups[N].PatchOffset := P;
  FGlobalFixups[N].GlobalIndex := AGlobalIndex;
end;

{ Patches the constant-materialization sequences that take the address of a
  function, now that the text segment placement is known. }
procedure TCrossIntegerBackend.ResolveFunctionAddressFixups(
  ATextAddress: QWord);
var
  I, P, Shift: LongInt;
  Address: QWord;
  High20, Low12: Int64;
begin
  for I := 0 to High(FDataFunctionFixups) do
    FData.Patch64(FDataFunctionFixups[I].DataOffset,
      ATextAddress + QWord(FLabels[FDataFunctionFixups[I].GlobalIndex].Offset));
  for I := 0 to High(FFunctionAddressFixups) do
  begin
    P := FFunctionAddressFixups[I].PatchOffset;
    Address := ATextAddress +
      QWord(FLabels[FFunctionAddressFixups[I].GlobalIndex].Offset);
    if FTarget.Architecture = archAArch64 then
    begin
      FText.Patch32(P, LongInt($D2800000 or
        (LongWord(Address and $FFFF) shl 5)));
      for Shift := 1 to 3 do
        FText.Patch32(P + Shift * 4, LongInt($F2800000 or
          (LongWord(Shift) shl 21) or
          (LongWord((Address shr (Shift * 16)) and $FFFF) shl 5)));
    end
    else
    begin
      if Address > QWord(High(LongInt)) then
        raise ERCCError.Create('error: RISC-V function address exceeds medlow range');
      High20 := (Int64(Address) + $800) shr 12;
      Low12 := Int64(Address) - (High20 shl 12);
      FText.Patch32(P, LongInt((LongWord(High20) and $FFFFF) shl 12 or
        LongWord(10 shl 7) or $37));
      FText.Patch32(P + 4,
        LongInt(EncodeRISCVI(LongInt(Low12), 10, 0, 10, $13)));
    end;
  end;
end;

procedure TCrossIntegerBackend.ResolveGlobalFixups(ADataAddress: QWord);
var
  I, P, Shift: LongInt;
  Address: QWord;
  High20, Low12: Int64;
begin
  for I := 0 to High(FDataPointerFixups) do
    FData.Patch64(FDataPointerFixups[I].DataOffset,
      ADataAddress + QWord(FGlobals[FDataPointerFixups[I].GlobalIndex].Offset));
  for I := 0 to High(FGlobalFixups) do
  begin
    P := FGlobalFixups[I].PatchOffset;
    Address := ADataAddress +
      QWord(FGlobals[FGlobalFixups[I].GlobalIndex].Offset);
    if FTarget.Architecture = archAArch64 then
    begin
      FText.Patch32(P, LongInt($D2800000 or
        (LongWord(Address and $FFFF) shl 5)));
      for Shift := 1 to 3 do
        FText.Patch32(P + Shift * 4, LongInt($F2800000 or
          (LongWord(Shift) shl 21) or
          (LongWord((Address shr (Shift * 16)) and $FFFF) shl 5)));
    end
    else
    begin
      if Address > QWord(High(LongInt)) then
        raise ERCCError.Create('error: RISC-V global address exceeds medlow range');
      High20 := (Int64(Address) + $800) shr 12;
      Low12 := Int64(Address) - (High20 shl 12);
      FText.Patch32(P, LongInt((LongWord(High20) and $FFFFF) shl 12 or
        LongWord(10 shl 7) or $37));
      FText.Patch32(P + 4,
        LongInt(EncodeRISCVI(LongInt(Low12), 10, 0, 10, $13)));
    end;
  end;
end;

procedure TCrossIntegerBackend.EmitLoadAtAddress(const AType: TCType);
var
  Size: LongInt;
  Funct3: LongWord;
begin
  Size := StorageSize(AType);
  if FTarget.Architecture = archAArch64 then
    case Size of
      1: EmitWord($39400000);
      2: EmitWord($79400000);
      4: EmitWord($B9400000);
      8: EmitWord($F9400000);
    else
      raise ERCCError.Create('internal error: invalid cross global load width');
    end
  else
  begin
    case Size of
      1: Funct3 := 4;
      2: Funct3 := 5;
      4: Funct3 := 6;
      8: Funct3 := 3;
    else
      raise ERCCError.Create('internal error: invalid cross global load width');
    end;
    EmitWord(EncodeRISCVI(0, 10, Funct3, 10, $03));
  end;
  EmitNormalize(AType);
end;

procedure TCrossIntegerBackend.EmitStoreAtAddress(const AType: TCType);
var
  Size: LongInt;
  Funct3: LongWord;
begin
  Size := StorageSize(AType);
  if FTarget.Architecture = archAArch64 then
    case Size of
      1: EmitWord($39000001);
      2: EmitWord($79000001);
      4: EmitWord($B9000001);
      8: EmitWord($F9000001);
    else
      raise ERCCError.Create('internal error: invalid cross global store width');
    end
  else
  begin
    case Size of
      1: Funct3 := 0;
      2: Funct3 := 1;
      4: Funct3 := 2;
      8: Funct3 := 3;
    else
      raise ERCCError.Create('internal error: invalid cross global store width');
    end;
    EmitWord(EncodeRISCVS(0, 5, 10, Funct3));
  end;
end;

{ Extracts and sign-extends a bit-field from a raw allocation-unit value in
  the accumulator. }
procedure TCrossIntegerBackend.EmitExtractBitField(const AType: TCType;
  ABitOffset, ABitWidth: LongInt);
var
  Shift: LongInt;
begin
  if ABitOffset > 0 then
  begin
    EmitMoveAccumulatorToLeft;
    EmitLoadImmediate(ABitOffset);
    EmitBinary(boShiftRight, True);
  end;
  EmitMoveAccumulatorToLeft;
  EmitLoadImmediate(Int64(CrossBitFieldMask(ABitWidth)));
  EmitBinary(boBitAnd, True);
  if not AType.IsUnsigned and (AType.Kind <> ctBool) and
     (ABitWidth > 0) and (ABitWidth < 64) then
  begin
    Shift := 64 - ABitWidth;
    EmitMoveAccumulatorToLeft;
    EmitLoadImmediate(Shift);
    EmitBinary(boShiftLeft, False);
    EmitMoveAccumulatorToLeft;
    EmitLoadImmediate(Shift);
    EmitBinary(boShiftRight, False);
  end;
end;

procedure TCrossIntegerBackend.EmitLoadBitField(const AType: TCType;
  ABitOffset, ABitWidth: LongInt);
var
  RawType: TCType;
begin
  RawType := AType;
  RawType.IsUnsigned := True;
  EmitLoadAtAddress(RawType);
  EmitExtractBitField(AType, ABitOffset, ABitWidth);
end;

{ Stores the value in the left register into the bit-field whose allocation
  unit address is in the accumulator. The resulting field value is returned
  in the accumulator, matching assignment-expression semantics. }
procedure TCrossIntegerBackend.EmitStoreBitFieldAtAddress(
  const AType: TCType; ABitOffset, ABitWidth: LongInt);
var
  RawType: TCType;
  ValueMask, PositionedMask: QWord;
begin
  ValueMask := CrossBitFieldMask(ABitWidth);
  PositionedMask := ValueMask shl ABitOffset;
  RawType := AType;
  RawType.IsUnsigned := True;

  { Stack layout evolves as [address], [bits,address], then
    [positioned,bits,address]. Every push uses one 16-byte ABI slot. }
  EmitPushResult;
  EmitMoveLeftToAccumulator;
  EmitMoveAccumulatorToLeft;
  EmitLoadImmediate(Int64(ValueMask));
  EmitBinary(boBitAnd, True);
  EmitPushResult;
  if ABitOffset > 0 then
  begin
    EmitMoveAccumulatorToLeft;
    EmitLoadImmediate(ABitOffset);
    EmitBinary(boShiftLeft, True);
  end;
  EmitPushResult;

  EmitLoadStackValue(32);
  EmitLoadAtAddress(RawType);
  EmitMoveAccumulatorToLeft;
  EmitLoadImmediate(Int64(not PositionedMask));
  EmitBinary(boBitAnd, True);
  EmitPopLeft;
  EmitBinary(boBitOr, True);

  EmitMoveAccumulatorToLeft;
  EmitPopAccumulator;
  EmitPopAccumulator;
  EmitStoreAtAddress(RawType);
  EmitMoveLeftToAccumulator;
  EmitExtractBitField(AType, ABitOffset, ABitWidth);
end;

procedure TCrossIntegerBackend.EmitLoadGlobal(AGlobalIndex: LongInt;
  const AType: TCType);
begin
  EmitGlobalAddress(AGlobalIndex);
  EmitLoadAtAddress(AType);
end;

procedure TCrossIntegerBackend.EmitStoreGlobal(AGlobalIndex: LongInt;
  const AType: TCType);
begin
  EmitPushResult;
  EmitGlobalAddress(AGlobalIndex);
  EmitPopLeft;
  EmitStoreAtAddress(AType);
  if FTarget.Architecture = archAArch64 then
    EmitWord($AA0103E0)
  else
    EmitWord(EncodeRISCVI(0, 5, 0, 10, $13));
end;

function TCrossIntegerBackend.AlignUp(AValue, AAlignment: LongInt): LongInt;
begin
  Result := (AValue + AAlignment - 1) and not (AAlignment - 1);
end;

function TCrossIntegerBackend.NewLabel: LongInt;
var
  N: LongInt;
begin
  N := Length(FLabels);
  SetLength(FLabels, N + 1);
  FLabels[N].Offset := -1;
  Result := N;
end;

procedure TCrossIntegerBackend.BindLabel(ALabel: LongInt);
begin
  if (ALabel < 0) or (ALabel > High(FLabels)) or
     (FLabels[ALabel].Offset >= 0) then
    raise ERCCError.Create('internal error: invalid cross-code label binding');
  FLabels[ALabel].Offset := FText.Size;
end;

procedure TCrossIntegerBackend.AddFixup(APatchOffset, ATargetLabel: LongInt;
  AKind: TCrossFixupKind);
var
  N: LongInt;
begin
  N := Length(FFixups);
  SetLength(FFixups, N + 1);
  FFixups[N].PatchOffset := APatchOffset;
  FFixups[N].TargetLabel := ATargetLabel;
  FFixups[N].Kind := AKind;
end;

procedure TCrossIntegerBackend.EmitWord(AInstruction: LongWord);
begin
  FText.Add32(AInstruction);
  Inc(FInstructionCount);
end;

function TCrossIntegerBackend.FindFunctionLabel(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := High(FFunctions) downto 0 do
    if FFunctions[I].Name = AName then Exit(FFunctions[I].LabelID);
  Result := -1;
end;

procedure TCrossIntegerBackend.ReserveFunctionLabels;
var
  I, N: LongInt;
begin
  for I := 0 to High(FProgram.Functions) do
  begin
    if FProgram.Functions[I].IsPrototype then Continue;
    if FindFunctionLabel(FProgram.Functions[I].Name) >= 0 then
      RaiseCompileError(FProgram.Functions[I].Pos,
        'duplicate cross-target function definition');
    N := Length(FFunctions);
    SetLength(FFunctions, N + 1);
    FFunctions[N].Name := FProgram.Functions[I].Name;
    FFunctions[N].LabelID := NewLabel;
  end;
end;

procedure TCrossIntegerBackend.ResolveFixups;
var
  I: LongInt;
  Delta, Scaled: Int64;
  Encoded: LongWord;
begin
  for I := 0 to High(FFixups) do
  begin
    if (FFixups[I].TargetLabel < 0) or
       (FFixups[I].TargetLabel > High(FLabels)) or
       (FLabels[FFixups[I].TargetLabel].Offset < 0) then
      raise ERCCError.Create('internal error: unresolved cross-code label');
    Delta := Int64(FLabels[FFixups[I].TargetLabel].Offset) -
      FFixups[I].PatchOffset;
    case FFixups[I].Kind of
      cfA64Branch, cfA64Call:
        begin
          if ((Delta and 3) <> 0) or
             (Delta < -134217728) or (Delta > 134217724) then
            raise ERCCError.Create('error: AArch64 branch is out of range');
          Scaled := Delta div 4;
          if FFixups[I].Kind = cfA64Call then Encoded := $94000000
          else Encoded := $14000000;
          Encoded := Encoded or (LongWord(Scaled) and $03FFFFFF);
        end;
      cfA64Zero, cfA64NonZero:
        begin
          if ((Delta and 3) <> 0) or
             (Delta < -1048576) or (Delta > 1048572) then
            raise ERCCError.Create('error: AArch64 conditional branch is out of range');
          Scaled := Delta div 4;
          if FFixups[I].Kind = cfA64NonZero then Encoded := $B5000000
          else Encoded := $B4000000;
          Encoded := Encoded or
            ((LongWord(Scaled) and $7FFFF) shl 5);
        end;
      cfRISCVJump:
        Encoded := EncodeRISCVJAL(0, LongInt(Delta));
      cfRISCVCall:
        Encoded := EncodeRISCVJAL(1, LongInt(Delta));
      cfRISCVZero:
        Encoded := EncodeRISCVB(LongInt(Delta), 0, 10, 0);
      cfRISCVNonZero:
        Encoded := EncodeRISCVB(LongInt(Delta), 0, 10, 1);
    end;
    FText.Patch32(FFixups[I].PatchOffset, LongInt(Encoded));
  end;
end;

function TCrossIntegerBackend.CountDeclarations(AStatement: TStmt): LongInt;
var
  I: LongInt;
begin
  Result := 0;
  if AStatement = nil then Exit;
  if AStatement.Kind = skDecl then Inc(Result);
  Result := Result + CountDeclarations(AStatement.InitStmt) +
    CountDeclarations(AStatement.Body) +
    CountDeclarations(AStatement.ElseBody);
  for I := 0 to High(AStatement.Children) do
    Result := Result + CountDeclarations(AStatement.Children[I]);
end;

procedure TCrossIntegerBackend.AddLocal(const AName: string;
  const AType: TCType; out AOffset: LongInt);
var
  N, Size, Alignment: LongInt;
begin
  Size := StorageSize(AType);
  if Size < 1 then Size := 1;
  Alignment := StorageAlign(AType);
  if Alignment < 1 then Alignment := 1;
  if Alignment < 8 then Alignment := 8;
  FNextLocalOffset := AlignUp(FNextLocalOffset, Alignment);
  AOffset := FNextLocalOffset;
  Inc(FNextLocalOffset, AlignUp(Size, 8));
  if FNextLocalOffset > FLocalLimit then
    raise ERCCError.Create('internal error: cross-target frame estimate is too small');
  N := Length(FLocals);
  SetLength(FLocals, N + 1);
  FLocals[N].Name := AName;
  FLocals[N].Offset := AOffset;
  FLocals[N].CType := AType;
  FLocals[N].ScopeDepth := FScopeDepth;
end;

{ Frame space used by expression results that must have an address. }
function TCrossIntegerBackend.CountExpressionTemporaryBytes(
  AExpression: TExpr): LongInt;
var
  I, Size, Alignment: LongInt;
begin
  Result := 0;
  if AExpression = nil then Exit;
  Inc(Result, CountExpressionTemporaryBytes(AExpression.Left));
  Inc(Result, CountExpressionTemporaryBytes(AExpression.Right));
  Inc(Result, CountExpressionTemporaryBytes(AExpression.Third));
  for I := 0 to High(AExpression.Args) do
    Inc(Result, CountExpressionTemporaryBytes(AExpression.Args[I]));
  if AExpression.Kind = ekCompoundLit then
  begin
    Size := StorageSize(AExpression.CType);
    Alignment := StorageAlign(AExpression.CType);
    if Size < 1 then Size := 1;
    if Alignment < 1 then Alignment := 1;
    Inc(Result, AlignUp(Size, 8) + Alignment + 8);
  end
  else if (AExpression.Kind = ekCall) and
          IsAggregateType(AExpression.CType) then
  begin
    Size := StorageSize(AExpression.CType);
    if Size < 8 then Size := 8;
    Inc(Result, AlignUp(Size, 8) + 8);
  end;
  if AExpression.Kind = ekCall then
  begin
    { Calls stage evaluated values in frame-owned storage before assigning ABI
      registers and outgoing stack slots. This preserves values across later
      argument expressions and supports independent GP/FP register banks. }
    Inc(Result, 24); { indirect callee or conservative alignment margin }
    for I := 0 to High(AExpression.Args) do
    begin
      if IsAggregateType(DecayType(AExpression.Args[I].CType)) and
         not IsArrayType(AExpression.Args[I].CType) then
        Size := StorageSize(AExpression.Args[I].CType)
      else
        Size := 8;
      if Size < 8 then Size := 8;
      Inc(Result, AlignUp(Size, 8) + 16);
    end;
  end;
end;

{ Frame space needed by a function body. Aggregates and addressable expression
  temporaries occupy their real size, so counting declarations is not enough. }
function TCrossIntegerBackend.CountLocalBytes(AStatement: TStmt): LongInt;
var
  I, Size: LongInt;
begin
  Result := 0;
  if AStatement = nil then Exit;
  if (AStatement.Kind = skDecl) and not AStatement.IsStatic then
  begin
    Size := StorageSize(AStatement.CType);
    if Size < 8 then Size := 8;
    Inc(Result, AlignUp(Size, 8) + StorageAlign(AStatement.CType) + 8);
  end;
  Inc(Result, CountExpressionTemporaryBytes(AStatement.Expr));
  Inc(Result, CountExpressionTemporaryBytes(AStatement.Expr2));
  for I := 0 to High(AStatement.AsmOutputs) do
    Inc(Result, CountExpressionTemporaryBytes(AStatement.AsmOutputs[I].Expr));
  for I := 0 to High(AStatement.AsmInputs) do
    Inc(Result, CountExpressionTemporaryBytes(AStatement.AsmInputs[I].Expr));
  Inc(Result, CountLocalBytes(AStatement.InitStmt));
  Inc(Result, CountLocalBytes(AStatement.Body));
  Inc(Result, CountLocalBytes(AStatement.ElseBody));
  for I := 0 to High(AStatement.Children) do
    Inc(Result, CountLocalBytes(AStatement.Children[I]));
end;

function TCrossIntegerBackend.FindLocal(const AName: string;
  out AOffset: LongInt; out AType: TCType): Boolean;
var
  I: LongInt;
begin
  for I := High(FLocals) downto 0 do
    if FLocals[I].Name = AName then
    begin
      AOffset := FLocals[I].Offset;
      AType := FLocals[I].CType;
      Exit(True);
    end;
  AOffset := 0;
  AType := MakeType(ctVoid);
  Result := False;
end;

procedure TCrossIntegerBackend.EnterScope;
begin
  Inc(FScopeDepth);
end;

procedure TCrossIntegerBackend.LeaveScope(ASavedCount: LongInt);
begin
  SetLength(FLocals, ASavedCount);
  Dec(FScopeDepth);
end;

procedure TCrossIntegerBackend.PushLoop(ABreakLabel,
  AContinueLabel: LongInt);
var
  N: LongInt;
begin
  N := Length(FBreakLabels);
  SetLength(FBreakLabels, N + 1);
  SetLength(FContinueLabels, N + 1);
  FBreakLabels[N] := ABreakLabel;
  FContinueLabels[N] := AContinueLabel;
end;

procedure TCrossIntegerBackend.PopLoop;
begin
  SetLength(FBreakLabels, Length(FBreakLabels) - 1);
  SetLength(FContinueLabels, Length(FContinueLabels) - 1);
end;

procedure TCrossIntegerBackend.RequireScalar(const AType: TCType;
  const APos: TSourcePos; const AContext: string);
begin
  if not IsIntegerType(AType) and not IsPointerType(AType) then
    RaiseCompileError(APos, AContext +
      ' requires an integer or pointer type in the freestanding cross backend');
  if StorageSize(AType) > 8 then
    RaiseCompileError(APos, AContext + ' exceeds the cross register width');
end;

{ Values the cross backend can hold in its integer-bit accumulator. Floating
  scalars use their IEEE representation there and move through the target FP
  register file only while an arithmetic operation or ABI transfer is active. }
procedure TCrossIntegerBackend.RequireRegisterValue(const AType: TCType;
  const APos: TSourcePos; const AContext: string);
begin
  if AType.Kind = ctVoid then Exit;
  if IsAggregateType(AType) or IsFunctionType(AType) then Exit;
  if IsPointerType(AType) then Exit;
  if IsFloatingType(AType) then
  begin
    if (AType.Kind = ctLongDouble) and (StorageSize(AType) <> 8) then
      RaiseCompileError(APos, AContext +
        ' uses long double, which the cross backend does not support');
    Exit;
  end;
  if not IsIntegerType(AType) then
    RaiseCompileError(APos, AContext +
      ' requires an integer or pointer type in the freestanding cross backend');
  if StorageSize(AType) > 8 then
    RaiseCompileError(APos, AContext + ' exceeds the cross register width');
end;

{ Accumulator := frame pointer + AOffset. }
procedure TCrossIntegerBackend.EmitLocalAddress(AOffset: LongInt);
begin
  if FTarget.Architecture = archAArch64 then
  begin
    { add x0, x29, #offset - the base register field must be written, not
      merged into a template that already encodes sp. }
    if (AOffset >= 0) and (AOffset <= 4095) then
      EmitWord($91000000 or (LongWord(AOffset) shl 10) or (LongWord(29) shl 5))
    else
    begin
      EmitLoadImmediate(AOffset);
      EmitWord($8B0003A0);
    end;
  end
  else
  begin
    if (AOffset >= -2048) and (AOffset <= 2047) then
      EmitWord(EncodeRISCVI(AOffset, 8, 0, 10, $13))
    else
    begin
      EmitLoadImmediate(AOffset);
      EmitWord(EncodeRISCVR(0, 8, 10, 0, 10, $33));
    end;
  end;
end;

{ Accumulator := accumulator + AValue, for displacements of any magnitude. }
procedure TCrossIntegerBackend.EmitAddLargeImmediate(AValue: Int64);
begin
  if AValue = 0 then Exit;
  if (AValue >= -2047) and (AValue <= 2047) then
  begin
    EmitAddImmediate(LongInt(AValue));
    Exit;
  end;
  { Stage the accumulator, materialize the displacement, and add. }
  EmitPushResult;
  EmitLoadImmediate(AValue);
  EmitPopLeft;
  if FTarget.Architecture = archAArch64 then
    EmitWord($8B000020)
  else
    EmitWord(EncodeRISCVR(0, 10, 5, 0, 10, $33));
end;

procedure TCrossIntegerBackend.EmitMoveAccumulatorToLeft;
begin
  if FTarget.Architecture = archAArch64 then
    EmitWord($AA0003E1)
  else
    EmitWord(EncodeRISCVI(0, 10, 0, 5, $13));
end;

function TCrossIntegerBackend.AggregateRegisterCount(
  const AType: TCType): LongInt;
begin
  if StorageSize(AType) <= 8 then Result := 1 else Result := 2;
end;

procedure TCrossIntegerBackend.EmitMoveStackPointerToAccumulator;
begin
  if FTarget.Architecture = archAArch64 then
    EmitWord($910003E0)
  else
    EmitWord(EncodeRISCVI(0, 2, 0, 10, $13));
end;

procedure TCrossIntegerBackend.EmitStackAddress(AOffset: LongInt);
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if (AOffset < 0) or (AOffset > 4095) then
      raise ERCCError.Create('internal error: AArch64 stack offset is too large');
    EmitWord($910003E0 or (LongWord(AOffset) shl 10));
  end
  else
  begin
    if (AOffset < -2048) or (AOffset > 2047) then
      raise ERCCError.Create('internal error: RISC-V stack offset is too large');
    EmitWord(EncodeRISCVI(AOffset, 2, 0, 10, $13));
  end;
end;

{ Adjust SP by AAmount bytes. Positive values release space and negative
  values reserve it. Chunks stay 16-byte aligned so the public ABI invariant
  holds even for unusually wide calls. }
procedure TCrossIntegerBackend.EmitAdjustStack(AAmount: LongInt);
var
  Remaining, Chunk: LongInt;
begin
  if (AAmount and 15) <> 0 then
    raise ERCCError.Create('internal error: cross stack adjustment is unaligned');
  Remaining := AAmount;
  while Remaining <> 0 do
  begin
    if Remaining > 0 then
    begin
      if FTarget.Architecture = archAArch64 then Chunk := 4080 else Chunk := 2032;
      if Chunk > Remaining then Chunk := Remaining;
    end
    else
    begin
      if FTarget.Architecture = archAArch64 then Chunk := -4080 else Chunk := -2032;
      if Chunk < Remaining then Chunk := Remaining;
    end;
    if FTarget.Architecture = archAArch64 then
    begin
      if Chunk > 0 then
        EmitWord($910003FF or (LongWord(Chunk) shl 10))
      else
        EmitWord($D10003FF or (LongWord(-Chunk) shl 10));
    end
    else
      EmitWord(EncodeRISCVI(Chunk, 2, 0, 2, $13));
    Dec(Remaining, Chunk);
  end;
end;

procedure TCrossIntegerBackend.EmitLoadLocalToIntegerRegister(
  AOffset, ARegister: LongInt);
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if (AOffset < 0) or (AOffset > 32760) or ((AOffset and 7) <> 0) then
      raise ERCCError.Create('internal error: invalid AArch64 local argument offset');
    EmitWord($F9400000 or (LongWord(AOffset div 8) shl 10) or
      (LongWord(29) shl 5) or LongWord(ARegister and 31));
  end
  else
  begin
    if (AOffset < -2048) or (AOffset > 2047) then
      raise ERCCError.Create('internal error: invalid RISC-V local argument offset');
    EmitWord(EncodeRISCVI(AOffset, 8, 3, ARegister, $03));
  end;
end;

procedure TCrossIntegerBackend.EmitLoadLocalPartToIntegerRegister(
  AOffset, ARegister, ABitWidth: LongInt);
var
  Size, Scale: LongInt;
  Base, Funct3: LongWord;
begin
  if ABitWidth <= 8 then Size := 1
  else if ABitWidth <= 16 then Size := 2
  else if ABitWidth <= 32 then Size := 4
  else Size := 8;
  if FTarget.Architecture = archAArch64 then
  begin
    Scale := Size;
    case Size of
      1: Base := $39400000;
      2: Base := $79400000;
      4: Base := $B9400000;
    else
      Base := $F9400000;
    end;
    if (AOffset < 0) or ((AOffset mod Scale) <> 0) or
       (AOffset div Scale > 4095) then
      raise ERCCError.Create('internal error: unencodable AArch64 ABI field load');
    EmitWord(Base or (LongWord(AOffset div Scale) shl 10) or
      (LongWord(29) shl 5) or LongWord(ARegister and 31));
  end
  else
  begin
    case Size of
      1: Funct3 := 4;
      2: Funct3 := 5;
      4: Funct3 := 6;
    else
      Funct3 := 3;
    end;
    EmitWord(EncodeRISCVI(AOffset, 8, Funct3, ARegister, $03));
  end;
end;

procedure TCrossIntegerBackend.EmitStoreIntegerRegisterToLocal(
  ARegister, AOffset: LongInt);
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if (AOffset < 0) or (AOffset > 32760) or ((AOffset and 7) <> 0) then
      raise ERCCError.Create('internal error: invalid AArch64 local result offset');
    EmitWord($F9000000 or (LongWord(AOffset div 8) shl 10) or
      (LongWord(29) shl 5) or LongWord(ARegister and 31));
  end
  else
  begin
    if (AOffset < -2048) or (AOffset > 2047) then
      raise ERCCError.Create('internal error: invalid RISC-V local result offset');
    EmitWord(EncodeRISCVS(AOffset, ARegister, 8, 3));
  end;
end;

procedure TCrossIntegerBackend.EmitStoreIntegerRegisterToLocalPart(
  ARegister, AOffset, ABitWidth: LongInt);
var
  Size, Scale: LongInt;
  Base, Funct3: LongWord;
begin
  if ABitWidth <= 8 then Size := 1
  else if ABitWidth <= 16 then Size := 2
  else if ABitWidth <= 32 then Size := 4
  else Size := 8;
  if FTarget.Architecture = archAArch64 then
  begin
    Scale := Size;
    case Size of
      1: Base := $39000000;
      2: Base := $79000000;
      4: Base := $B9000000;
    else
      Base := $F9000000;
    end;
    if (AOffset < 0) or ((AOffset mod Scale) <> 0) or
       (AOffset div Scale > 4095) then
      raise ERCCError.Create('internal error: unencodable AArch64 ABI field store');
    EmitWord(Base or (LongWord(AOffset div Scale) shl 10) or
      (LongWord(29) shl 5) or LongWord(ARegister and 31));
  end
  else
  begin
    case Size of
      1: Funct3 := 0;
      2: Funct3 := 1;
      4: Funct3 := 2;
    else
      Funct3 := 3;
    end;
    EmitWord(EncodeRISCVS(AOffset, ARegister, 8, Funct3));
  end;
end;

procedure TCrossIntegerBackend.EmitLoadLocalToFloatRegister(
  AOffset, ARegister: LongInt; const AType: TCType);
var
  Scale, FPRegister: LongInt;
  Base: LongWord;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then
    begin
      Base := $BD400000;
      Scale := 4;
    end
    else
    begin
      Base := $FD400000;
      Scale := 8;
    end;
    if (AOffset >= 0) and ((AOffset mod Scale) = 0) and
       (AOffset div Scale <= 4095) then
    begin
      EmitWord(Base or (LongWord(AOffset div Scale) shl 10) or
        (LongWord(29) shl 5) or LongWord(ARegister and 31));
      Exit;
    end;
    if (AOffset < 0) or (AOffset > 4095) then
      raise ERCCError.Create('internal error: invalid AArch64 FP argument offset');
    EmitLocalAddress(AOffset);
    EmitLoadAtAddress(AType);
    EmitAccumulatorToFloatRegister(ARegister, AType);
  end
  else
  begin
    if (AOffset < -2048) or (AOffset > 2047) then
      raise ERCCError.Create('internal error: invalid RISC-V FP argument offset');
    FPRegister := 10 + ARegister;
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVI(AOffset, 8, 2, FPRegister, $07))
    else
      EmitWord(EncodeRISCVI(AOffset, 8, 3, FPRegister, $07));
  end;
end;

procedure TCrossIntegerBackend.EmitStoreFloatRegisterToLocal(
  ARegister, AOffset: LongInt; const AType: TCType);
var
  Scale, FPRegister: LongInt;
  Base: LongWord;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then
    begin
      Base := $BD000000;
      Scale := 4;
    end
    else
    begin
      Base := $FD000000;
      Scale := 8;
    end;
    if (AOffset >= 0) and ((AOffset mod Scale) = 0) and
       (AOffset div Scale <= 4095) then
    begin
      EmitWord(Base or (LongWord(AOffset div Scale) shl 10) or
        (LongWord(29) shl 5) or LongWord(ARegister and 31));
      Exit;
    end;
    if (AOffset < 0) or (AOffset > 4095) then
      raise ERCCError.Create('internal error: invalid AArch64 FP result offset');
    EmitFloatRegisterToAccumulator(ARegister, AType);
    EmitMoveAccumulatorToLeft;
    EmitLocalAddress(AOffset);
    EmitStoreAtAddress(AType);
  end
  else
  begin
    if (AOffset < -2048) or (AOffset > 2047) then
      raise ERCCError.Create('internal error: invalid RISC-V FP result offset');
    FPRegister := 10 + ARegister;
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVStore(AOffset, FPRegister, 8, 2, $27))
    else
      EmitWord(EncodeRISCVStore(AOffset, FPRegister, 8, 3, $27));
  end;
end;

procedure TCrossIntegerBackend.EmitCopyLocalToStack(ASourceOffset,
  ADestinationOffset, ASize: LongInt);
begin
  EmitLocalAddress(ASourceOffset);
  EmitMoveAccumulatorToLeft;
  EmitStackAddress(ADestinationOffset);
  EmitCopyBlock(ASize);
end;

{ Copies an aggregate whose address is in the accumulator into a fresh 16-byte
  argument staging slot. Both supported ABIs pass aggregates of at most two
  words in consecutive integer registers. }
procedure TCrossIntegerBackend.EmitPushAggregate(ASize: LongInt);
begin
  EmitMoveAccumulatorToLeft;
  if FTarget.Architecture = archAArch64 then
    EmitWord($D10043FF)
  else
    EmitWord(EncodeRISCVI(-16, 2, 0, 2, $13));
  EmitMoveStackPointerToAccumulator;
  EmitCopyBlock(ASize);
end;

{ Loads a staged aggregate into one or two argument registers. }
procedure TCrossIntegerBackend.EmitPopArgumentPair(AIndex: LongInt);
var
  First, Second: LongInt;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    First := AIndex;
    Second := AIndex + 1;
    EmitWord($F94003E0 or LongWord(First));
    EmitWord($F94007E0 or LongWord(Second));
    EmitWord($910043FF);
  end
  else
  begin
    First := 10 + AIndex;
    Second := 11 + AIndex;
    EmitWord(EncodeRISCVI(0, 2, 3, First, $03));
    EmitWord(EncodeRISCVI(8, 2, 3, Second, $03));
    EmitWord(EncodeRISCVI(16, 2, 0, 2, $13));
  end;
end;

procedure TCrossIntegerBackend.EmitMoveLeftToAccumulator;
begin
  if FTarget.Architecture = archAArch64 then
    EmitWord($AA0103E0)
  else
    EmitWord(EncodeRISCVI(0, 5, 0, 10, $13));
end;

procedure TCrossIntegerBackend.EmitMoveAccumulatorToRegister(
  ARegister: LongInt);
begin
  if FTarget.Architecture = archAArch64 then
    EmitWord($AA0003E0 or LongWord(ARegister and 31))
  else
    EmitWord(EncodeRISCVI(0, 10, 0, ARegister, $13));
end;

procedure TCrossIntegerBackend.EmitPopAccumulator;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    EmitWord($F94003E0);
    EmitWord($910043FF);
  end
  else
  begin
    EmitWord(EncodeRISCVI(0, 2, 3, 10, $03));
    EmitWord(EncodeRISCVI(16, 2, 0, 2, $13));
  end;
end;

{ Byte-wise copy of ASize bytes from the address in the left register to the
  address in the accumulator. Used for aggregate assignment and argument and
  return passing. }
procedure TCrossIntegerBackend.EmitCopyBlock(ASize: LongInt);
var
  I: LongInt;
begin
  if ASize <= 0 then Exit;
  for I := 0 to ASize - 1 do
    if FTarget.Architecture = archAArch64 then
    begin
      { ldrb w9,[x1,#I] ; strb w9,[x0,#I] }
      EmitWord($39400029 or (LongWord(I) shl 10));
      EmitWord($39000009 or (LongWord(I) shl 10));
    end
    else
    begin
      { lbu t1,I(t0) ; sb t1,I(a0) }
      EmitWord(EncodeRISCVI(I, 5, 4, 6, $03));
      EmitWord(EncodeRISCVS(I, 6, 10, 0));
    end;
end;

procedure TCrossIntegerBackend.EmitLoadImmediate(AValue: Int64);
var
  Part: LongWord;
  Shift: LongInt;
  First: Boolean;
  Instruction: LongWord;
  High20, Low12, HighPart, LowPart: Int64;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    First := True;
    for Shift := 0 to 3 do
    begin
      Part := LongWord((QWord(AValue) shr (Shift * 16)) and $FFFF);
      if First or (Part <> 0) then
      begin
        if First then Instruction := $D2800000 else Instruction := $F2800000;
        EmitWord(Instruction or (LongWord(Shift) shl 21) or
          (Part shl 5));
        First := False;
      end;
    end;
    Exit;
  end;

  if (AValue >= -2048) and (AValue <= 2047) then
  begin
    EmitWord(EncodeRISCVI(LongInt(AValue), 0, 0, 10, $13));
    Exit;
  end;
  if (AValue >= Low(LongInt)) and (AValue <= High(LongInt)) then
  begin
    High20 := (AValue + $800) shr 12;
    Low12 := AValue - (High20 shl 12);
    EmitWord((LongWord(High20) and $FFFFF) shl 12 or (10 shl 7) or $37);
    EmitWord(EncodeRISCVI(LongInt(Low12), 10, 0, 10, $13));
    Exit;
  end;

  { Wider constants are built from two 32-bit halves: the high half is placed
    in the upper word and the zero-extended low half is added underneath. }
  HighPart := Int64(LongInt(LongWord(QWord(AValue) shr 32)));
  LowPart := Int64(LongWord(QWord(AValue) and $FFFFFFFF));
  High20 := (HighPart + $800) shr 12;
  Low12 := HighPart - (High20 shl 12);
  EmitWord((LongWord(High20) and $FFFFF) shl 12 or (10 shl 7) or $37);
  EmitWord(EncodeRISCVI(LongInt(Low12), 10, 0, 10, $13));
  EmitWord(EncodeRISCVI(32, 10, 1, 10, $13));
  High20 := (LowPart + $800) shr 12;
  Low12 := LowPart - (High20 shl 12);
  EmitWord((LongWord(High20) and $FFFFF) shl 12 or (6 shl 7) or $37);
  EmitWord(EncodeRISCVI(LongInt(Low12), 6, 0, 6, $13));
  { Clear any sign extension the low half picked up. }
  EmitWord(EncodeRISCVI(32, 6, 1, 6, $13));
  EmitWord(EncodeRISCVI(32, 6, 5, 6, $13));
  EmitWord(EncodeRISCVR(0, 6, 10, 0, 10, $33));
end;

procedure TCrossIntegerBackend.EmitFloatImmediate(AValue: Double;
  const AType: TCType);
var
  SingleValue: Single;
  Bits32: LongWord;
  Bits64: QWord;
begin
  if AType.Kind = ctFloat then
  begin
    SingleValue := AValue;
    Move(SingleValue, Bits32, SizeOf(Bits32));
    EmitLoadImmediate(Int64(Bits32));
  end
  else if AType.Kind in [ctDouble, ctLongDouble] then
  begin
    Move(AValue, Bits64, SizeOf(Bits64));
    EmitLoadImmediate(Int64(Bits64));
  end
  else
    raise ERCCError.Create(
      'internal error: floating immediate has unsupported type');
end;

{ Move the raw IEEE bits in x0/a0 to v0/fa0. }
procedure TCrossIntegerBackend.EmitBitsToFloatAccumulator(
  const AType: TCType);
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then EmitWord($1E270000) { fmov s0,w0 }
    else EmitWord($9E670000);                       { fmov d0,x0 }
  end
  else
  begin
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVR($78, 0, 10, 0, 10, $53)) { fmv.w.x fa0,a0 }
    else
      EmitWord(EncodeRISCVR($79, 0, 10, 0, 10, $53)); { fmv.d.x fa0,a0 }
  end;
end;

procedure TCrossIntegerBackend.EmitAccumulatorToFloatRegister(
  ARegister: LongInt; const AType: TCType);
var
  FPRegister: LongInt;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then
      EmitWord($1E270000 or LongWord(ARegister and 31))
    else
      EmitWord($9E670000 or LongWord(ARegister and 31));
  end
  else
  begin
    FPRegister := 10 + ARegister;
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVR($78, 0, 10, 0, FPRegister, $53))
    else
      EmitWord(EncodeRISCVR($79, 0, 10, 0, FPRegister, $53));
  end;
end;

{ Move v0/fa0 back to the integer-bit accumulator. }
procedure TCrossIntegerBackend.EmitFloatAccumulatorToBits(
  const AType: TCType);
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then EmitWord($1E260000) { fmov w0,s0 }
    else EmitWord($9E660000);                       { fmov x0,d0 }
  end
  else
  begin
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVR($70, 0, 10, 0, 10, $53)) { fmv.x.w a0,fa0 }
    else
      EmitWord(EncodeRISCVR($71, 0, 10, 0, 10, $53)); { fmv.x.d a0,fa0 }
  end;
end;

procedure TCrossIntegerBackend.EmitFloatRegisterToAccumulator(
  ARegister: LongInt; const AType: TCType);
var
  FPRegister: LongInt;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then
      EmitWord($1E260000 or (LongWord(ARegister and 31) shl 5))
    else
      EmitWord($9E660000 or (LongWord(ARegister and 31) shl 5));
  end
  else
  begin
    FPRegister := 10 + ARegister;
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVR($70, 0, FPRegister, 0, 10, $53))
    else
      EmitWord(EncodeRISCVR($71, 0, FPRegister, 0, 10, $53));
  end;
end;

{ Move the raw IEEE bits in x1/t0 to v1/ft1. }
procedure TCrossIntegerBackend.EmitLeftBitsToFloatScratch(
  const AType: TCType);
begin
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then EmitWord($1E270021) { fmov s1,w1 }
    else EmitWord($9E670021);                       { fmov d1,x1 }
  end
  else
  begin
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVR($78, 0, 5, 0, 1, $53)) { fmv.w.x ft1,t0 }
    else
      EmitWord(EncodeRISCVR($79, 0, 5, 0, 1, $53)); { fmv.d.x ft1,t0 }
  end;
end;

procedure TCrossIntegerBackend.EmitFloatingBinary(AOperation: TBinaryOp;
  const AType: TCType);
var
  Base, FormatOffset: LongWord;
begin
  EmitBitsToFloatAccumulator(AType);
  EmitLeftBitsToFloatScratch(AType);
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then FormatOffset := 0
    else FormatOffset := $00400000;
    case AOperation of
      boAdd: Base := $1E202800;
      boSub: Base := $1E203800;
      boMul: Base := $1E200800;
      boDiv: Base := $1E201800;
      boEqual, boNotEqual, boLess, boLessEqual, boGreater,
        boGreaterEqual:
        begin
          { fcmp s1,s0 / d1,d0 }
          EmitWord($1E202020 or FormatOffset);
          case AOperation of
            boEqual: EmitWord($1A9F17E0);       { cset w0,eq }
            boNotEqual: EmitWord($1A9F07E0);    { cset w0,ne }
            boLess: EmitWord($1A9F57E0);        { cset w0,mi; NaN false }
            boLessEqual:
              begin
                EmitWord($1A9F57E0);            { cset w0,mi }
                EmitWord($1A9F17E9);            { cset w9,eq }
                EmitWord($2A090000);            { orr w0,w0,w9 }
              end;
            boGreater: EmitWord($1A9FD7E0);     { cset w0,gt }
            boGreaterEqual: EmitWord($1A9FB7E0); { cset w0,ge }
          else
            ;
          end;
          Exit;
        end;
    else
      raise ERCCError.Create(
        'internal error: invalid AArch64 floating operation');
    end;
    EmitWord(Base or FormatOffset or (LongWord(1) shl 5));
    EmitFloatAccumulatorToBits(AType);
    Exit;
  end;

  if AType.Kind = ctFloat then FormatOffset := 0
  else FormatOffset := 1;
  case AOperation of
    boAdd: Base := 0;
    boSub: Base := 4;
    boMul: Base := 8;
    boDiv: Base := 12;
    boEqual:
      begin
        EmitWord(EncodeRISCVR($50 + FormatOffset, 10, 1, 2, 10, $53));
        Exit;
      end;
    boNotEqual:
      begin
        EmitWord(EncodeRISCVR($50 + FormatOffset, 10, 1, 2, 10, $53));
        EmitWord(EncodeRISCVI(1, 10, 4, 10, $13));
        Exit;
      end;
    boLess:
      begin
        EmitWord(EncodeRISCVR($50 + FormatOffset, 10, 1, 1, 10, $53));
        Exit;
      end;
    boLessEqual:
      begin
        EmitWord(EncodeRISCVR($50 + FormatOffset, 10, 1, 0, 10, $53));
        Exit;
      end;
    boGreater:
      begin
        EmitWord(EncodeRISCVR($50 + FormatOffset, 1, 10, 1, 10, $53));
        Exit;
      end;
    boGreaterEqual:
      begin
        EmitWord(EncodeRISCVR($50 + FormatOffset, 1, 10, 0, 10, $53));
        Exit;
      end;
  else
    raise ERCCError.Create(
      'internal error: invalid RISC-V floating operation');
  end;
  EmitWord(EncodeRISCVR(Base + FormatOffset, 10, 1, 7, 10, $53));
  EmitFloatAccumulatorToBits(AType);
end;

procedure TCrossIntegerBackend.EmitFloatToBool(const AType: TCType);
begin
  EmitBitsToFloatAccumulator(AType);
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.Kind = ctFloat then EmitWord($1E202008) { fcmp s0,#0 }
    else EmitWord($1E602008);                       { fcmp d0,#0 }
    EmitWord($1A9F07E0);                           { cset w0,ne }
  end
  else
  begin
    EmitLoadImmediate(0);
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVR($78, 0, 10, 0, 1, $53))
    else
      EmitWord(EncodeRISCVR($79, 0, 10, 0, 1, $53));
    { fa0 still holds the input; equality with zero is inverted so NaNs are
      true, as required by C scalar truth conversion. }
    if AType.Kind = ctFloat then
      EmitWord(EncodeRISCVR($50, 1, 10, 2, 10, $53))
    else
      EmitWord(EncodeRISCVR($51, 1, 10, 2, 10, $53));
    EmitWord(EncodeRISCVI(1, 10, 4, 10, $13));
  end;
end;

procedure TCrossIntegerBackend.EmitConvertIntegerToFloat(
  const AFromType, AToType: TCType);
var
  Instruction, Funct7, SourceKind: LongWord;
begin
  EmitNormalize(AFromType);
  if FTarget.Architecture = archAArch64 then
  begin
    if AToType.Kind = ctFloat then Instruction := $9E220000
    else Instruction := $9E620000;
    if AFromType.IsUnsigned or (AFromType.Kind = ctBool) or
       IsPointerType(AFromType) then
      Instruction := Instruction or $00010000;
    EmitWord(Instruction);
  end
  else
  begin
    if AToType.Kind = ctFloat then Funct7 := $68 else Funct7 := $69;
    if AFromType.IsUnsigned or (AFromType.Kind = ctBool) or
       IsPointerType(AFromType) then SourceKind := 3 else SourceKind := 2;
    EmitWord(EncodeRISCVR(Funct7, SourceKind, 10, 7, 10, $53));
  end;
  EmitFloatAccumulatorToBits(AToType);
end;

procedure TCrossIntegerBackend.EmitConvertFloatToInteger(
  const AFromType, AToType: TCType);
var
  Instruction, Funct7, DestinationKind: LongWord;
begin
  if AToType.Kind = ctBool then
  begin
    EmitFloatToBool(AFromType);
    Exit;
  end;
  EmitBitsToFloatAccumulator(AFromType);
  if FTarget.Architecture = archAArch64 then
  begin
    if AFromType.Kind = ctFloat then Instruction := $9E380000
    else Instruction := $9E780000;
    if AToType.IsUnsigned or IsPointerType(AToType) then
      Instruction := Instruction or $00010000;
    EmitWord(Instruction);
  end
  else
  begin
    if AFromType.Kind = ctFloat then Funct7 := $60 else Funct7 := $61;
    if AToType.IsUnsigned or IsPointerType(AToType) then
      DestinationKind := 3 else DestinationKind := 2;
    EmitWord(EncodeRISCVR(Funct7, DestinationKind, 10, 1, 10, $53));
  end;
  EmitNormalize(AToType);
end;

procedure TCrossIntegerBackend.EmitConvertFloatWidth(
  const AFromType, AToType: TCType);
begin
  if (AFromType.Kind = AToType.Kind) or
     (StorageSize(AFromType) = StorageSize(AToType)) then Exit;
  EmitBitsToFloatAccumulator(AFromType);
  if FTarget.Architecture = archAArch64 then
  begin
    if (AFromType.Kind = ctFloat) and (AToType.Kind = ctDouble) then
      EmitWord($1E22C000)
    else
      EmitWord($1E624000);
  end
  else
  begin
    if (AFromType.Kind = ctFloat) and (AToType.Kind = ctDouble) then
      EmitWord(EncodeRISCVR($21, 0, 10, 0, 10, $53))
    else
      EmitWord(EncodeRISCVR($20, 1, 10, 7, 10, $53));
  end;
  EmitFloatAccumulatorToBits(AToType);
end;

procedure TCrossIntegerBackend.EmitNormalize(const AType: TCType);
var
  Size, Shift: LongInt;
  Instruction: LongWord;
begin
  if IsPointerType(AType) then Exit;
  if not IsIntegerType(AType) then Exit;
  if AType.Kind = ctBool then
  begin
    if FTarget.Architecture = archAArch64 then
    begin
      EmitWord($F100001F);
      EmitWord($9A9F07E0);
    end
    else
      EmitWord(EncodeRISCVR(0, 10, 0, 3, 10, $33));
    Exit;
  end;
  Size := StorageSize(AType);
  if Size >= 8 then Exit;
  Shift := 64 - Size * 8;
  if FTarget.Architecture = archAArch64 then
  begin
    if AType.IsUnsigned or (AType.Kind = ctBool) then
      Instruction := $D3400000
    else
      Instruction := $93400000;
    Instruction := Instruction or LongWord(Size * 8 - 1) shl 10;
    EmitWord(Instruction);
  end
  else
  begin
    EmitWord(EncodeRISCVI(Shift, 10, 1, 10, $13));
    if AType.IsUnsigned or (AType.Kind = ctBool) then
      EmitWord(EncodeRISCVI(Shift, 10, 5, 10, $13))
    else
      EmitWord(EncodeRISCVI((Shift or $400), 10, 5, 10, $13));
  end;
end;

procedure TCrossIntegerBackend.EmitPushResult;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    EmitWord($D10043FF);
    EmitWord($F90003E0);
  end
  else
  begin
    EmitWord(EncodeRISCVI(-16, 2, 0, 2, $13));
    EmitWord(EncodeRISCVS(0, 10, 2, 3));
  end;
end;

procedure TCrossIntegerBackend.EmitLoadStackValue(AOffset: LongInt);
begin
  if (AOffset < 0) or (AOffset > 2047) then
    raise ERCCError.Create('internal error: cross stack load is out of range');
  if FTarget.Architecture = archAArch64 then
  begin
    if (AOffset and 7) <> 0 then
      raise ERCCError.Create('internal error: unaligned AArch64 stack load');
    EmitWord($F94003E0 or (LongWord(AOffset div 8) shl 10));
  end
  else
    EmitWord(EncodeRISCVI(AOffset, 2, 3, 10, $03));
end;

procedure TCrossIntegerBackend.EmitPopLeft;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    EmitWord($F94003E1);
    EmitWord($910043FF);
  end
  else
  begin
    EmitWord(EncodeRISCVI(0, 2, 3, 5, $03));
    EmitWord(EncodeRISCVI(16, 2, 0, 2, $13));
  end;
end;

procedure TCrossIntegerBackend.EmitPopArgument(AIndex: LongInt);
var
  RegisterNumber: LongInt;
begin
  if (AIndex < 0) or (AIndex > 7) then
    raise ERCCError.Create('error: cross-target call has more than eight arguments');
  if FTarget.Architecture = archAArch64 then
  begin
    RegisterNumber := AIndex;
    EmitWord($F94003E0 or LongWord(RegisterNumber));
    EmitWord($910043FF);
  end
  else
  begin
    RegisterNumber := 10 + AIndex;
    EmitWord(EncodeRISCVI(0, 2, 3, RegisterNumber, $03));
    EmitWord(EncodeRISCVI(16, 2, 0, 2, $13));
  end;
end;

procedure TCrossIntegerBackend.EmitLoadLocal(AOffset: LongInt);
begin
  if FTarget.Architecture = archAArch64 then
    EmitWord($F9400000 or (LongWord(AOffset div 8) shl 10) or
      (LongWord(29) shl 5))
  else
    EmitWord(EncodeRISCVI(AOffset, 8, 3, 10, $03));
end;

procedure TCrossIntegerBackend.EmitStoreLocal(AOffset: LongInt);
begin
  if FTarget.Architecture = archAArch64 then
    EmitWord($F9000000 or (LongWord(AOffset div 8) shl 10) or
      (LongWord(29) shl 5))
  else
    EmitWord(EncodeRISCVS(AOffset, 10, 8, 3));
end;

procedure TCrossIntegerBackend.EmitAddImmediate(AValue: LongInt);
begin
  if (AValue < -2047) or (AValue > 2047) then
    raise ERCCError.Create('internal error: cross add immediate is excessive');
  if FTarget.Architecture = archAArch64 then
  begin
    if AValue >= 0 then
      EmitWord($91000000 or (LongWord(AValue) shl 10))
    else
      EmitWord($D1000000 or (LongWord(-AValue) shl 10));
  end
  else
    EmitWord(EncodeRISCVI(AValue, 10, 0, 10, $13));
end;

procedure TCrossIntegerBackend.EmitBinary(AOperation: TBinaryOp;
  AUnsigned: Boolean);
var
  Condition, InverseCondition: LongWord;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    case AOperation of
      boAdd: EmitWord($8B000020);
      boSub: EmitWord($CB000020);
      boMul: EmitWord($9B007C20);
      boDiv:
        if AUnsigned then EmitWord($9AC00820) else EmitWord($9AC00C20);
      boMod:
        begin
          if AUnsigned then EmitWord($9AC00822) else EmitWord($9AC00C22);
          EmitWord($9B008440);
        end;
      boShiftLeft: EmitWord($9AC02020);
      boShiftRight:
        if AUnsigned then EmitWord($9AC02420) else EmitWord($9AC02820);
      boBitAnd: EmitWord($8A000020);
      boBitOr: EmitWord($AA000020);
      boBitXor: EmitWord($CA000020);
      boEqual, boNotEqual, boLess, boLessEqual, boGreater, boGreaterEqual:
        begin
          EmitWord($EB00003F);
          case AOperation of
            boEqual: Condition := 0;
            boNotEqual: Condition := 1;
            boLess: if AUnsigned then Condition := 3 else Condition := 11;
            boLessEqual: if AUnsigned then Condition := 9 else Condition := 13;
            boGreater: if AUnsigned then Condition := 8 else Condition := 12;
            boGreaterEqual: if AUnsigned then Condition := 2 else Condition := 10;
          else
            Condition := 0;
          end;
          InverseCondition := Condition xor 1;
          EmitWord($9A800400 or (LongWord(31) shl 16) or
            (InverseCondition shl 12) or (LongWord(31) shl 5));
        end;
    else
      raise ERCCError.Create('internal error: unsupported AArch64 binary operation');
    end;
    Exit;
  end;

  case AOperation of
    boAdd: EmitWord(EncodeRISCVR(0, 10, 5, 0, 10, $33));
    boSub: EmitWord(EncodeRISCVR($20, 10, 5, 0, 10, $33));
    boMul: EmitWord(EncodeRISCVR(1, 10, 5, 0, 10, $33));
    boDiv:
      if AUnsigned then EmitWord(EncodeRISCVR(1, 10, 5, 5, 10, $33))
      else EmitWord(EncodeRISCVR(1, 10, 5, 4, 10, $33));
    boMod:
      if AUnsigned then EmitWord(EncodeRISCVR(1, 10, 5, 7, 10, $33))
      else EmitWord(EncodeRISCVR(1, 10, 5, 6, 10, $33));
    boShiftLeft: EmitWord(EncodeRISCVR(0, 10, 5, 1, 10, $33));
    boShiftRight:
      if AUnsigned then EmitWord(EncodeRISCVR(0, 10, 5, 5, 10, $33))
      else EmitWord(EncodeRISCVR($20, 10, 5, 5, 10, $33));
    boBitAnd: EmitWord(EncodeRISCVR(0, 10, 5, 7, 10, $33));
    boBitOr: EmitWord(EncodeRISCVR(0, 10, 5, 6, 10, $33));
    boBitXor: EmitWord(EncodeRISCVR(0, 10, 5, 4, 10, $33));
    boEqual:
      begin
        EmitWord(EncodeRISCVR($20, 10, 5, 0, 10, $33));
        EmitWord(EncodeRISCVI(1, 10, 3, 10, $13));
      end;
    boNotEqual:
      begin
        EmitWord(EncodeRISCVR($20, 10, 5, 0, 10, $33));
        EmitWord(EncodeRISCVR(0, 10, 0, 3, 10, $33));
      end;
    boLess:
      if AUnsigned then EmitWord(EncodeRISCVR(0, 10, 5, 3, 10, $33))
      else EmitWord(EncodeRISCVR(0, 10, 5, 2, 10, $33));
    boGreater:
      if AUnsigned then EmitWord(EncodeRISCVR(0, 5, 10, 3, 10, $33))
      else EmitWord(EncodeRISCVR(0, 5, 10, 2, 10, $33));
    boLessEqual:
      begin
        if AUnsigned then EmitWord(EncodeRISCVR(0, 5, 10, 3, 10, $33))
        else EmitWord(EncodeRISCVR(0, 5, 10, 2, 10, $33));
        EmitWord(EncodeRISCVI(1, 10, 4, 10, $13));
      end;
    boGreaterEqual:
      begin
        if AUnsigned then EmitWord(EncodeRISCVR(0, 10, 5, 3, 10, $33))
        else EmitWord(EncodeRISCVR(0, 10, 5, 2, 10, $33));
        EmitWord(EncodeRISCVI(1, 10, 4, 10, $13));
      end;
  else
    raise ERCCError.Create('internal error: unsupported RISC-V binary operation');
  end;
end;

procedure TCrossIntegerBackend.EmitJump(ALabel: LongInt);
var
  P: LongInt;
begin
  P := FText.Size;
  if FTarget.Architecture = archAArch64 then
  begin EmitWord($14000000); AddFixup(P, ALabel, cfA64Branch); end
  else
  begin EmitWord(EncodeRISCVJAL(0, 0)); AddFixup(P, ALabel, cfRISCVJump); end;
end;

procedure TCrossIntegerBackend.EmitJumpIfZero(ALabel: LongInt);
var
  P: LongInt;
begin
  P := FText.Size;
  if FTarget.Architecture = archAArch64 then
  begin EmitWord($B4000000); AddFixup(P, ALabel, cfA64Zero); end
  else
  begin EmitWord(EncodeRISCVB(0, 0, 10, 0)); AddFixup(P, ALabel, cfRISCVZero); end;
end;

procedure TCrossIntegerBackend.EmitJumpIfNonZero(ALabel: LongInt);
var
  P: LongInt;
begin
  P := FText.Size;
  if FTarget.Architecture = archAArch64 then
  begin EmitWord($B5000000); AddFixup(P, ALabel, cfA64NonZero); end
  else
  begin EmitWord(EncodeRISCVB(0, 0, 10, 1)); AddFixup(P, ALabel, cfRISCVNonZero); end;
end;

procedure TCrossIntegerBackend.EmitCall(ALabel: LongInt);
var
  P: LongInt;
begin
  P := FText.Size;
  if FTarget.Architecture = archAArch64 then
  begin EmitWord($94000000); AddFixup(P, ALabel, cfA64Call); end
  else
  begin EmitWord(EncodeRISCVJAL(1, 0)); AddFixup(P, ALabel, cfRISCVCall); end;
end;

procedure TCrossIntegerBackend.EmitExternalCall(const AName: string);
var
  N: LongInt;
begin
  if not FObjectMode then
    raise ERCCError.Create(
      'internal error: external cross call requested for an executable');
  N := Length(FExternalCalls);
  SetLength(FExternalCalls, N + 1);
  FExternalCalls[N].Name := AName;
  FExternalCalls[N].PatchOffset := FText.Size;
  if FTarget.Architecture = archAArch64 then
    EmitWord($94000000)
  else
    EmitWord(EncodeRISCVJAL(1, 0));
end;

procedure TCrossIntegerBackend.ReserveStaticLocals(AStatement: TStmt);
var
  I, N, G: LongInt;
begin
  if AStatement = nil then Exit;
  if (AStatement.Kind = skDecl) and AStatement.IsStatic then
  begin
    { Literals referenced by the initializer are objects of their own and must
      be laid out before this object's bytes. }
    InternInitializerLiterals(AStatement.CType, AStatement.Expr);
    FData.PadTo(StorageAlign(AStatement.CType));
    G := Length(FGlobals);
    SetLength(FGlobals, G + 1);
    FGlobals[G].Name := FCurrentFunctionName + '.' + AStatement.Name;
    FGlobals[G].Offset := FData.Size;
    FGlobals[G].Size := StorageSize(AStatement.CType);
    FGlobals[G].CType := AStatement.CType;
    FGlobals[G].IsStatic := True;
    EmitGlobalObject(AStatement.CType, AStatement.Expr, AStatement.Pos);
    N := Length(FStaticLocals);
    SetLength(FStaticLocals, N + 1);
    FStaticLocals[N].FunctionName := FCurrentFunctionName;
    FStaticLocals[N].VariableName := AStatement.Name;
    FStaticLocals[N].GlobalIndex := G;
  end;
  ReserveStaticLocals(AStatement.InitStmt);
  ReserveStaticLocals(AStatement.Body);
  ReserveStaticLocals(AStatement.ElseBody);
  for I := 0 to High(AStatement.Children) do
    ReserveStaticLocals(AStatement.Children[I]);
end;

function TCrossIntegerBackend.FindStaticLocal(const AName: string;
  out AGlobalIndex: LongInt; out AType: TCType): Boolean;
var
  I: LongInt;
begin
  for I := High(FStaticLocals) downto 0 do
    if (FStaticLocals[I].VariableName = AName) and
       (FStaticLocals[I].FunctionName = FCurrentFunctionName) then
    begin
      AGlobalIndex := FStaticLocals[I].GlobalIndex;
      AType := FGlobals[AGlobalIndex].CType;
      Exit(True);
    end;
  AGlobalIndex := -1;
  AType := MakeType(ctVoid);
  Result := False;
end;

function TCrossIntegerBackend.CountSwitchSlots(AStatement: TStmt): LongInt;
var
  I: LongInt;
begin
  Result := 0;
  if AStatement = nil then Exit;
  if AStatement.Kind = skSwitch then Inc(Result);
  Inc(Result, CountSwitchSlots(AStatement.InitStmt));
  Inc(Result, CountSwitchSlots(AStatement.Body));
  Inc(Result, CountSwitchSlots(AStatement.ElseBody));
  for I := 0 to High(AStatement.Children) do
    Inc(Result, CountSwitchSlots(AStatement.Children[I]));
end;

function TCrossIntegerBackend.AllocateTemporary(ASize,
  AAlignment: LongInt): LongInt;
begin
  if ASize < 1 then ASize := 1;
  if AAlignment < 1 then AAlignment := 1;
  FNextLocalOffset := AlignUp(FNextLocalOffset, AAlignment);
  Result := FNextLocalOffset;
  Inc(FNextLocalOffset, AlignUp(ASize, 8));
  if FNextLocalOffset > FLocalLimit then
    raise ERCCError.Create('internal error: cross-target frame estimate is too small');
end;

function TCrossIntegerBackend.AllocateTemporarySlot: LongInt;
begin
  Result := AllocateTemporary(8, 8);
end;

procedure TCrossIntegerBackend.EmitZeroLocalBlock(AOffset, ASize: LongInt);
var
  I: LongInt;
begin
  if ASize <= 0 then Exit;
  EmitLoadImmediate(0);
  I := 0;
  while I + 8 <= ASize do
  begin
    EmitStoreLocal(AOffset + I);
    Inc(I, 8);
  end;
  while I < ASize do
  begin
    if FTarget.Architecture = archAArch64 then
      EmitWord($39000000 or (LongWord(AOffset + I) shl 10) or
        (LongWord(29) shl 5))
    else
      EmitWord(EncodeRISCVS(AOffset + I, 10, 8, 0));
    Inc(I);
  end;
end;

{ Fills an aggregate local element by element, mirroring the native backend's
  initializer walk. }
procedure TCrossIntegerBackend.InitializeLocalAt(ABaseOffset,
  AByteOffset: LongInt; const AType: TCType; AInitializer: TExpr;
  const APos: TSourcePos);
var
  I, Count, ElementSize: LongInt;
  ElementType, MemberType: TCType;
  Member: TStructMember;
begin
  if AInitializer = nil then Exit;

  if IsArrayType(AType) then
  begin
    ElementType := ElementTypeOf(AType);
    ElementSize := StorageSize(ElementType);
    if (AInitializer.Kind = ekString) and (ElementType.Kind = ctChar) and
       (ElementType.PointerDepth = 0) then
    begin
      Count := Length(AInitializer.Text);
      if Count >= AType.ArrayLength then Count := LongInt(AType.ArrayLength) - 1;
      for I := 0 to Count - 1 do
      begin
        EmitLoadImmediate(Ord(AInitializer.Text[I + 1]));
        EmitMoveAccumulatorToLeft;
        EmitLocalAddress(ABaseOffset + AByteOffset + I);
        EmitStoreAtAddress(ElementType);
      end;
      Exit;
    end;
    if AInitializer.Kind <> ekCompoundLit then
      RaiseCompileError(APos,
        'array initializer requires braces or a string literal');
    for I := 0 to High(AInitializer.Args) do
    begin
      if I >= AType.ArrayLength then
        RaiseCompileError(APos, 'too many elements in array initializer');
      InitializeLocalAt(ABaseOffset, AByteOffset + I * ElementSize,
        ElementType, AInitializer.Args[I], APos);
    end;
    Exit;
  end;

  if (AType.PointerDepth = 0) and (AType.Kind in [ctStruct, ctUnion]) then
  begin
    if AType.StructInfo = nil then
      RaiseCompileError(APos, 'initializer uses incomplete aggregate type');
    if AInitializer.Kind <> ekCompoundLit then
    begin
      { Copy from another aggregate value, which may be an lvalue or the
        result of a call; either way the expression yields its address. }
      GenExpr(AInitializer);
      EmitMoveAccumulatorToLeft;
      EmitLocalAddress(ABaseOffset + AByteOffset);
      EmitCopyBlock(StorageSize(AType));
      Exit;
    end;
    for I := 0 to High(AInitializer.Args) do
    begin
      if I > High(AType.StructInfo^.Members) then
        RaiseCompileError(APos, 'too many values in aggregate initializer');
      Member := AType.StructInfo^.Members[I];
      if Member.IsBitField then
      begin
        EmitLocalAddress(ABaseOffset + AByteOffset + Member.Offset);
        EmitPushResult;
        GenExpr(AInitializer.Args[I]);
        EmitNormalize(PCType(Member.CType)^);
        EmitMoveAccumulatorToLeft;
        EmitPopAccumulator;
        EmitStoreBitFieldAtAddress(PCType(Member.CType)^,
          Member.BitOffset, Member.BitWidth);
        if AType.Kind = ctUnion then Break;
        Continue;
      end;
      MemberType := PCType(Member.CType)^;
      InitializeLocalAt(ABaseOffset, AByteOffset + Member.Offset,
        MemberType, AInitializer.Args[I], APos);
    end;
    Exit;
  end;

  GenExprConverted(AInitializer, AType);
  EmitMoveAccumulatorToLeft;
  EmitLocalAddress(ABaseOffset + AByteOffset);
  EmitStoreAtAddress(AType);
end;

function TCrossIntegerBackend.FindUserLabel(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(FUserLabels) do
    if FUserLabels[I].Name = AName then Exit(FUserLabels[I].LabelID);
  raise ERCCError.Create('internal error: undefined cross-target label ' + AName);
end;

procedure TCrossIntegerBackend.ReserveUserLabels(AStatement: TStmt);
var
  I, N: LongInt;
begin
  if AStatement = nil then Exit;
  if AStatement.Kind = skLabel then
  begin
    N := Length(FUserLabels);
    SetLength(FUserLabels, N + 1);
    FUserLabels[N].Name := AStatement.Name;
    FUserLabels[N].LabelID := NewLabel;
  end;
  ReserveUserLabels(AStatement.InitStmt);
  ReserveUserLabels(AStatement.Body);
  ReserveUserLabels(AStatement.ElseBody);
  for I := 0 to High(AStatement.Children) do
    ReserveUserLabels(AStatement.Children[I]);
end;

procedure TCrossIntegerBackend.CollectSwitchEntries(AStatement: TStmt;
  var AEntries: TCrossSwitchEntryArray);
var
  I, N: LongInt;
begin
  if AStatement = nil then Exit;
  if AStatement.Kind in [skCase, skDefault] then
  begin
    N := Length(AEntries);
    SetLength(AEntries, N + 1);
    AEntries[N].Statement := AStatement;
    AEntries[N].TargetLabel := -1;
    AEntries[N].IsDefault := AStatement.Kind = skDefault;
    AEntries[N].Value := AStatement.CaseValue;
    if (AStatement.Body <> nil) and
       (AStatement.Body.Kind in [skCase, skDefault]) then
      CollectSwitchEntries(AStatement.Body, AEntries);
    Exit;
  end;
  { A nested switch owns its own labels. }
  if AStatement.Kind = skSwitch then Exit;
  if AStatement.Kind = skBlock then
    for I := 0 to High(AStatement.Children) do
      CollectSwitchEntries(AStatement.Children[I], AEntries);
end;

function TCrossIntegerBackend.SwitchTargetFor(AStatement: TStmt;
  const AEntries: TCrossSwitchEntryArray): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(AEntries) do
    if AEntries[I].Statement = AStatement then Exit(AEntries[I].TargetLabel);
  Result := -1;
end;

{ Emits the switch body in source order, binding each case label where it
  appears so execution falls through between cases. }
procedure TCrossIntegerBackend.GenSwitchBody(AStatement: TStmt;
  const AEntries: TCrossSwitchEntryArray);
var
  I, Target, SavedCount: LongInt;
begin
  if AStatement = nil then Exit;
  if AStatement.Kind in [skCase, skDefault] then
  begin
    Target := SwitchTargetFor(AStatement, AEntries);
    if Target >= 0 then BindLabel(Target);
    GenSwitchBody(AStatement.Body, AEntries);
    Exit;
  end;
  if AStatement.Kind = skBlock then
  begin
    if AStatement.IsDeclarationGroup then
    begin
      for I := 0 to High(AStatement.Children) do
        GenSwitchBody(AStatement.Children[I], AEntries);
      Exit;
    end;
    { The switch body and any braced case body are still blocks, so they scope
      their declarations even though case labels are walked here. }
    SavedCount := Length(FLocals);
    EnterScope;
    for I := 0 to High(AStatement.Children) do
      GenSwitchBody(AStatement.Children[I], AEntries);
    LeaveScope(SavedCount);
    Exit;
  end;
  GenStmt(AStatement);
end;

{ Leaves the address of an lvalue in the accumulator. }
procedure TCrossIntegerBackend.GenAddress(AExpression: TExpr);
var
  Offset, GlobalIndex, Scale, FunctionLabel: LongInt;
  LocalType: TCType;
  Member: TStructMember;
begin
  if AExpression = nil then
    raise ERCCError.Create('internal error: nil cross-target lvalue');
  case AExpression.Kind of
    ekVariable:
      begin
        if AExpression.IsFunctionDesignator then
        begin
          FunctionLabel := FindFunctionLabel(AExpression.Text);
          if FunctionLabel < 0 then
            RaiseCompileError(AExpression.Pos,
              'cross-target address of undefined function ''' +
              AExpression.Text + '''');
          EmitFunctionAddress(FunctionLabel);
          Exit;
        end;
        if FindLocal(AExpression.Text, Offset, LocalType) then
          EmitLocalAddress(Offset)
        else if FindStaticLocal(AExpression.Text, GlobalIndex, LocalType) then
          EmitGlobalAddress(GlobalIndex)
        else if FindGlobal(AExpression.Text, GlobalIndex, LocalType) then
          EmitGlobalAddress(GlobalIndex)
        else
          RaiseCompileError(AExpression.Pos,
            'cross-target variable has no definition: ' + AExpression.Text);
      end;
    ekDeref: GenExpr(AExpression.Left);
    ekIndex:
      begin
        Scale := LongInt(AExpression.IntValue);
        if Scale < 1 then Scale := 1;
        GenExpr(AExpression.Left);
        if (AExpression.Right <> nil) and
           (AExpression.Right.Kind = ekInteger) then
          EmitAddLargeImmediate(AExpression.Right.IntValue * Scale)
        else
        begin
          EmitPushResult;
          GenExpr(AExpression.Right);
          if Scale > 1 then
          begin
            EmitMoveAccumulatorToLeft;
            EmitLoadImmediate(Scale);
            if FTarget.Architecture = archAArch64 then
              EmitWord($9B007C20)
            else
              EmitWord(EncodeRISCVR(1, 10, 5, 0, 10, $33));
          end;
          EmitPopLeft;
          if FTarget.Architecture = archAArch64 then
            EmitWord($8B000020)
          else
            EmitWord(EncodeRISCVR(0, 10, 5, 0, 10, $33));
        end;
      end;
    ekMember:
      begin
        if not FindMember(AExpression.Left.CType, AExpression.Text, Member) then
          RaiseCompileError(AExpression.Pos,
            'unknown aggregate member ''' + AExpression.Text + '''');
        GenAddress(AExpression.Left);
        EmitAddLargeImmediate(Member.Offset);
      end;
    ekArrow:
      begin
        if not FindMember(PointeeType(DecayType(AExpression.Left.CType)),
             AExpression.Text, Member) then
          RaiseCompileError(AExpression.Pos,
            'unknown aggregate member ''' + AExpression.Text + '''');
        GenExpr(AExpression.Left);
        EmitAddLargeImmediate(Member.Offset);
      end;
    ekCompoundLit:
      begin
        Offset := AllocateTemporary(StorageSize(AExpression.CType),
          StorageAlign(AExpression.CType));
        EmitZeroLocalBlock(Offset, StorageSize(AExpression.CType));
        if IsAggregateType(AExpression.CType) then
          InitializeLocalAt(Offset, 0, AExpression.CType, AExpression,
            AExpression.Pos)
        else
        begin
          if Length(AExpression.Args) <> 1 then
            RaiseCompileError(AExpression.Pos,
              'scalar compound literal requires exactly one initializer');
          InitializeLocalAt(Offset, 0, AExpression.CType,
            AExpression.Args[0], AExpression.Pos);
        end;
        EmitLocalAddress(Offset);
      end;
  else
    RaiseCompileError(AExpression.Pos,
      'expression is not an addressable object in the cross backend');
  end;
end;

procedure TCrossIntegerBackend.GenAssignment(AExpression: TExpr);
var
  Operation: TBinaryOp;
  TargetType: TCType;
  Scale: LongInt;
begin
  if AExpression.Left = nil then
    RaiseCompileError(AExpression.Pos,
      'cross-target assignment requires an lvalue');
  TargetType := AExpression.Left.CType;

  if IsAggregateType(TargetType) then
  begin
    if AExpression.AssignOp <> aoAssign then
      RaiseCompileError(AExpression.Pos,
        'compound assignment is invalid for aggregates');
    GenExpr(AExpression.Right);
    EmitPushResult;
    GenAddress(AExpression.Left);
    EmitPopLeft;
    EmitCopyBlock(StorageSize(TargetType));
    Exit;
  end;

  if AExpression.Left.IsBitField then
  begin
    GenAddress(AExpression.Left);
    EmitPushResult;
    if AExpression.AssignOp = aoAssign then
      GenExpr(AExpression.Right)
    else
    begin
      EmitLoadBitField(TargetType, AExpression.Left.BitOffset,
        AExpression.Left.BitWidth);
      EmitPushResult;
      GenExpr(AExpression.Right);
      EmitPopLeft;
      case AExpression.AssignOp of
        aoAdd: Operation := boAdd;
        aoSub: Operation := boSub;
        aoMul: Operation := boMul;
        aoDiv: Operation := boDiv;
        aoMod: Operation := boMod;
        aoBitAnd: Operation := boBitAnd;
        aoBitOr: Operation := boBitOr;
        aoBitXor: Operation := boBitXor;
        aoShiftLeft: Operation := boShiftLeft;
        aoShiftRight: Operation := boShiftRight;
      else
        Operation := boAdd;
      end;
      EmitBinary(Operation, TargetType.IsUnsigned);
    end;
    EmitNormalize(TargetType);
    EmitMoveAccumulatorToLeft;
    EmitPopAccumulator;
    EmitStoreBitFieldAtAddress(TargetType, AExpression.Left.BitOffset,
      AExpression.Left.BitWidth);
    Exit;
  end;

  if IsFloatingType(TargetType) and
     (AExpression.AssignOp <> aoAssign) then
  begin
    GenAddress(AExpression.Left);
    EmitPushResult;
    EmitLoadAtAddress(TargetType);
    EmitPushResult;
    GenExprAsFloating(AExpression.Right, TargetType);
    EmitPopLeft;
    case AExpression.AssignOp of
      aoAdd: Operation := boAdd;
      aoSub: Operation := boSub;
      aoMul: Operation := boMul;
      aoDiv: Operation := boDiv;
    else
      RaiseCompileError(AExpression.Pos,
        'invalid floating compound assignment');
    end;
    EmitFloatingBinary(Operation, TargetType);
    EmitMoveAccumulatorToLeft;
    EmitPopAccumulator;
    EmitStoreAtAddress(TargetType);
    EmitMoveLeftToAccumulator;
    Exit;
  end;

  if AExpression.AssignOp = aoAssign then
  begin
    GenAddress(AExpression.Left);
    EmitPushResult;
    GenExprConverted(AExpression.Right, TargetType);
    EmitMoveAccumulatorToLeft;
    EmitPopAccumulator;
    EmitStoreAtAddress(TargetType);
    EmitMoveLeftToAccumulator;
    Exit;
  end;

  GenAddress(AExpression.Left);
  EmitPushResult;
  EmitLoadAtAddress(TargetType);
  EmitPushResult;
  GenExpr(AExpression.Right);
  { Adding to a pointer advances by whole elements. }
  if IsPointerType(DecayType(TargetType)) and
     (AExpression.AssignOp in [aoAdd, aoSub]) then
  begin
    Scale := StorageSize(PointeeType(DecayType(TargetType)));
    if Scale > 1 then
    begin
      EmitMoveAccumulatorToLeft;
      EmitLoadImmediate(Scale);
      if FTarget.Architecture = archAArch64 then
        EmitWord($9B007C20)
      else
        EmitWord(EncodeRISCVR(1, 10, 5, 0, 10, $33));
    end;
  end;
  EmitPopLeft;
  case AExpression.AssignOp of
    aoAdd: Operation := boAdd;
    aoSub: Operation := boSub;
    aoMul: Operation := boMul;
    aoDiv: Operation := boDiv;
    aoMod: Operation := boMod;
    aoBitAnd: Operation := boBitAnd;
    aoBitOr: Operation := boBitOr;
    aoBitXor: Operation := boBitXor;
    aoShiftLeft: Operation := boShiftLeft;
    aoShiftRight: Operation := boShiftRight;
  else
    Operation := boAdd;
  end;
  EmitBinary(Operation, TargetType.IsUnsigned);
  EmitNormalize(TargetType);
  EmitMoveAccumulatorToLeft;
  EmitPopAccumulator;
  EmitStoreAtAddress(TargetType);
  EmitMoveLeftToAccumulator;
end;

procedure TCrossIntegerBackend.GenIncDec(AExpression: TExpr;
  ADelta: LongInt; APost: Boolean);
var
  TargetType: TCType;
  Delta: LongInt;
begin
  if AExpression.Left = nil then
    RaiseCompileError(AExpression.Pos,
      'cross-target increment requires an lvalue');
  TargetType := AExpression.Left.CType;
  Delta := ADelta;
  if AExpression.IntValue > 1 then Delta := Delta * LongInt(AExpression.IntValue);

  if AExpression.Left.IsBitField then
  begin
    GenAddress(AExpression.Left);
    EmitPushResult;
    EmitLoadBitField(TargetType, AExpression.Left.BitOffset,
      AExpression.Left.BitWidth);
    if APost then EmitPushResult;
    EmitAddLargeImmediate(Delta);
    EmitNormalize(TargetType);
    EmitMoveAccumulatorToLeft;
    if APost then
      EmitLoadStackValue(16)
    else
      EmitPopAccumulator;
    EmitStoreBitFieldAtAddress(TargetType, AExpression.Left.BitOffset,
      AExpression.Left.BitWidth);
    if APost then
    begin
      EmitPopAccumulator;
      EmitMoveAccumulatorToLeft;
      EmitPopAccumulator;
      EmitMoveLeftToAccumulator;
    end;
    Exit;
  end;

  if IsFloatingType(TargetType) then
  begin
    GenAddress(AExpression.Left);
    EmitPushResult;
    EmitLoadAtAddress(TargetType);
    if APost then EmitPushResult;
    EmitPushResult;
    EmitFloatImmediate(1.0, TargetType);
    EmitPopLeft;
    if ADelta >= 0 then
      EmitFloatingBinary(boAdd, TargetType)
    else
      EmitFloatingBinary(boSub, TargetType);
    EmitMoveAccumulatorToLeft;
    if APost then EmitLoadStackValue(16)
    else EmitPopAccumulator;
    EmitStoreAtAddress(TargetType);
    if APost then
    begin
      EmitPopAccumulator;
      EmitMoveAccumulatorToLeft;
      EmitPopAccumulator;
      EmitMoveLeftToAccumulator;
    end
    else
      EmitMoveLeftToAccumulator;
    Exit;
  end;

  GenAddress(AExpression.Left);
  EmitPushResult;
  EmitLoadAtAddress(TargetType);
  EmitAddLargeImmediate(Delta);
  EmitNormalize(TargetType);
  EmitMoveAccumulatorToLeft;
  EmitPopAccumulator;
  EmitStoreAtAddress(TargetType);
  EmitMoveLeftToAccumulator;
  if APost then
  begin
    { The expression yields the value from before the update. }
    EmitAddLargeImmediate(-Delta);
    EmitNormalize(TargetType);
  end;
end;

{ Materializes the run-time address of a function into the accumulator. Text
  addresses are resolved once the image layout is known. }
procedure TCrossIntegerBackend.EmitFunctionAddress(ALabel: LongInt);
var
  N, P: LongInt;
begin
  P := FText.Size;
  if FTarget.Architecture = archAArch64 then
  begin
    EmitWord($D2800000);
    EmitWord($F2A00000);
    EmitWord($F2C00000);
    EmitWord($F2E00000);
  end
  else
  begin
    EmitWord(LongWord(10 shl 7) or $37);
    EmitWord(EncodeRISCVI(0, 10, 0, 10, $13));
  end;
  N := Length(FFunctionAddressFixups);
  SetLength(FFunctionAddressFixups, N + 1);
  FFunctionAddressFixups[N].PatchOffset := P;
  FFunctionAddressFixups[N].GlobalIndex := ALabel;
end;

{ Pops the staged callee address into a scratch register and branches to it.
  A scratch register is required because the accumulator doubles as the first
  argument register. }
procedure TCrossIntegerBackend.EmitIndirectCall;
begin
  if FTarget.Architecture = archAArch64 then
  begin
    EmitWord($F94003E0 or 9);
    EmitWord($910043FF);
    EmitWord($D63F0000 or (LongWord(9) shl 5));
  end
  else
  begin
    EmitWord(EncodeRISCVI(0, 2, 3, 6, $03));
    EmitWord(EncodeRISCVI(16, 2, 0, 2, $13));
    EmitWord(EncodeRISCVI(0, 6, 0, 1, $67));
  end;
end;

procedure TCrossIntegerBackend.GenExprAsFloating(AExpression: TExpr;
  const AType: TCType);
begin
  GenExpr(AExpression);
  if IsFloatingType(AExpression.CType) then
    EmitConvertFloatWidth(AExpression.CType, AType)
  else
    EmitConvertIntegerToFloat(AExpression.CType, AType);
end;

procedure TCrossIntegerBackend.GenExprConverted(AExpression: TExpr;
  const AType: TCType);
begin
  if IsAggregateType(AType) then
  begin
    GenExpr(AExpression);
    Exit;
  end;
  if IsFloatingType(AType) then
    GenExprAsFloating(AExpression, AType)
  else
  begin
    GenExpr(AExpression);
    if IsFloatingType(AExpression.CType) then
      EmitConvertFloatToInteger(AExpression.CType, AType)
    else
      EmitNormalize(AType);
  end;
end;

procedure TCrossIntegerBackend.GenCondition(AExpression: TExpr);
begin
  GenExpr(AExpression);
  if IsFloatingType(AExpression.CType) then
    EmitFloatToBool(AExpression.CType);
end;

function TCrossIntegerBackend.TryGenVariadicBuiltin(
  AExpression: TExpr): Boolean;
var
  RequestedType, PointerType, IntType: TCType;
  Location: TABIValueLocation;
  StateOffset, ScratchOffset, OldOffset, ArgumentOffset,
    ResultOffset, StackLabel, DoneLabel: LongInt;
  I, FieldOffset, Step, Needed, PartSize, PartOffset,
    StackSize, Alignment: LongInt;
  CursorABI, IsAggregate, Indirect, FloatingClass: Boolean;

  procedure LoadStateField(AOffset: LongInt; const AType: TCType);
  begin
    EmitLoadLocal(StateOffset);
    EmitAddLargeImmediate(AOffset);
    EmitLoadAtAddress(AType);
  end;

  procedure StoreAccumulatorToStateField(AOffset: LongInt;
    const AType: TCType);
  begin
    EmitMoveAccumulatorToLeft;
    EmitLoadLocal(StateOffset);
    EmitAddLargeImmediate(AOffset);
    EmitStoreAtAddress(AType);
  end;

  procedure AlignAccumulator(AAlignment: LongInt);
  begin
    if AAlignment <= 1 then Exit;
    EmitAddLargeImmediate(AAlignment - 1);
    EmitMoveAccumulatorToLeft;
    EmitLoadImmediate(-AAlignment);
    EmitBinary(boBitAnd, True);
  end;

  procedure StoreCursorValue;
  begin
    { The cursor ABIs use a scalar pointer va_list. The builtin receives an
      lvalue, so update its storage rather than dereferencing its old value. }
    EmitStoreLocal(ScratchOffset);
    GenAddress(AExpression.Args[0]);
    EmitPushResult;
    EmitLoadLocal(ScratchOffset);
    EmitMoveAccumulatorToLeft;
    EmitPopAccumulator;
    EmitStoreAtAddress(PointerType);
  end;

  procedure FinishValueAtArgumentAddress;
  begin
    if Indirect then
      EmitLoadAtAddress(PointerType)
    else if not IsAggregate then
      EmitLoadAtAddress(RequestedType);
  end;

begin
  Result := False;
  if (AExpression = nil) or
     not ((AExpression.Text = '__builtin_va_start') or
          (AExpression.Text = '__builtin_va_arg') or
          (AExpression.Text = '__builtin_va_copy') or
          (AExpression.Text = '__builtin_va_end')) then Exit;
  Result := True;
  PointerType := MakeType(ctPointer);
  IntType := MakeType(ctInt);
  CursorABI := (FTarget.Architecture = archRISCV64) or
    ((FTarget.Architecture = archAArch64) and
     (FTarget.OperatingSystem = osDarwin));

  if AExpression.Text = '__builtin_va_end' then
  begin
    EmitLoadImmediate(0);
    Exit;
  end;

  ScratchOffset := AllocateTemporary(8, 8);
  if AExpression.Text = '__builtin_va_start' then
  begin
    if not FCurrentIsVariadic then
      RaiseCompileError(AExpression.Pos,
        'va_start is valid only inside a variadic function');
    if CursorABI then
    begin
      if (FTarget.Architecture = archRISCV64) and
         (FCurrentVarArgGPUsed < 8) then
        EmitLocalAddress(FCurrentVarArgSaveOffset)
      else if FTarget.Architecture = archAArch64 then
        EmitLocalAddress(FFrameSize + 16 + FCurrentVarArgStackOffset)
      else
        EmitLocalAddress(FFrameSize + FCurrentVarArgStackOffset);
      StoreCursorValue;
    end
    else
    begin
      StateOffset := ScratchOffset;
      GenExpr(AExpression.Args[0]);
      EmitStoreLocal(StateOffset);

      EmitLocalAddress(FFrameSize + 16 + FCurrentVarArgStackOffset);
      StoreAccumulatorToStateField(0, PointerType);
      EmitLocalAddress(FCurrentVarArgSaveOffset + 64);
      StoreAccumulatorToStateField(8, PointerType);
      EmitLocalAddress(FCurrentVarArgSaveOffset + 192);
      StoreAccumulatorToStateField(16, PointerType);
      EmitLoadImmediate(-8 * (8 - FCurrentVarArgGPUsed));
      StoreAccumulatorToStateField(24, IntType);
      EmitLoadImmediate(-16 * (8 - FCurrentVarArgFPUsed));
      StoreAccumulatorToStateField(28, IntType);
    end;
    EmitLoadImmediate(0);
    Exit;
  end;

  if AExpression.Text = '__builtin_va_copy' then
  begin
    if CursorABI then
    begin
      GenExpr(AExpression.Args[1]);
      StoreCursorValue;
    end
    else
    begin
      StateOffset := ScratchOffset;
      GenExpr(AExpression.Args[1]);
      EmitStoreLocal(StateOffset);
      OldOffset := AllocateTemporary(8, 8);
      GenExpr(AExpression.Args[0]);
      EmitStoreLocal(OldOffset);
      EmitLoadLocal(StateOffset);
      EmitMoveAccumulatorToLeft;
      EmitLoadLocal(OldOffset);
      EmitCopyBlock(32);
    end;
    EmitLoadImmediate(0);
    Exit;
  end;

  { __builtin_va_arg }
  RequestedType := AExpression.CType;
  Location := ClassifyCTypeForABI(RequestedType, FTarget);
  IsAggregate := IsAggregateType(RequestedType);
  Indirect := Location.PassMode = apmIndirect;
  StackSize := StorageSize(RequestedType);
  Alignment := StorageAlign(RequestedType);
  if Indirect then
  begin
    StackSize := 8;
    Alignment := 8;
  end;
  if StackSize < 8 then StackSize := 8;
  StackSize := AlignUp(StackSize, 8);
  if Alignment < 8 then Alignment := 8;
  if Alignment > 16 then Alignment := 16;

  if CursorABI then
  begin
    { RISC-V and Darwin arm64 both expose a simple advancing cursor. Their
      callers have already lowered unnamed arguments to the integer/stack
      convention appropriate for the target. }
    OldOffset := AllocateTemporary(8, 8);
    GenExpr(AExpression.Args[0]);
    AlignAccumulator(Alignment);
    EmitStoreLocal(OldOffset);
    EmitAddLargeImmediate(StackSize);
    StoreCursorValue;
    EmitLoadLocal(OldOffset);
    FinishValueAtArgumentAddress;
    Exit;
  end;

  { AAPCS64 va_list uses independent general- and floating-register cursors,
    with a shared overflow stack cursor. }
  StateOffset := ScratchOffset;
  GenExpr(AExpression.Args[0]);
  EmitStoreLocal(StateOffset);
  OldOffset := AllocateTemporary(8, 8);
  ArgumentOffset := AllocateTemporary(8, 8);
  FloatingClass := (Length(Location.Parts) > 0) and
    (Location.Parts[0].ValueClass in [ascSSE, ascSSEUp]);
  if FloatingClass then
  begin
    FieldOffset := 28;
    Step := 16;
  end
  else
  begin
    FieldOffset := 24;
    Step := 8;
  end;
  Needed := Step * Length(Location.Parts);
  if Indirect then Needed := 8;
  if Needed < Step then Needed := Step;
  StackLabel := NewLabel;
  DoneLabel := NewLabel;

  LoadStateField(FieldOffset, IntType);
  EmitStoreLocal(OldOffset);
  EmitAddLargeImmediate(Needed);
  StoreAccumulatorToStateField(FieldOffset, IntType);
  EmitLoadLocal(OldOffset);
  EmitMoveAccumulatorToLeft;
  EmitLoadImmediate(-Needed);
  EmitBinary(boLessEqual, False);
  EmitJumpIfZero(StackLabel);

  if FloatingClass then FieldOffset := 16 else FieldOffset := 8;
  LoadStateField(FieldOffset, PointerType);
  EmitMoveAccumulatorToLeft;
  EmitLoadLocal(OldOffset);
  EmitBinary(boAdd, True);
  EmitStoreLocal(ArgumentOffset);

  if IsAggregate and not Indirect then
  begin
    ResultOffset := AllocateTemporary(StorageSize(RequestedType),
      StorageAlign(RequestedType));
    for I := 0 to High(Location.Parts) do
    begin
      PartOffset := Location.Parts[I].BitOffset div 8;
      PartSize := (Location.Parts[I].BitWidth + 7) div 8;
      EmitLoadLocal(ArgumentOffset);
      EmitAddLargeImmediate(I * Step);
      EmitMoveAccumulatorToLeft;
      EmitLocalAddress(ResultOffset + PartOffset);
      EmitCopyBlock(PartSize);
    end;
    EmitLocalAddress(ResultOffset);
  end
  else
  begin
    EmitLoadLocal(ArgumentOffset);
    FinishValueAtArgumentAddress;
  end;
  EmitJump(DoneLabel);

  BindLabel(StackLabel);
  LoadStateField(0, PointerType);
  AlignAccumulator(Alignment);
  EmitStoreLocal(ArgumentOffset);
  EmitAddLargeImmediate(StackSize);
  StoreAccumulatorToStateField(0, PointerType);
  EmitLoadLocal(ArgumentOffset);
  FinishValueAtArgumentAddress;
  BindLabel(DoneLabel);
end;

procedure TCrossIntegerBackend.GenExpr(AExpression: TExpr);
var
  I, J, Offset, GlobalIndex, FalseLabel, EndLabel, FunctionLabel,
    FixedArgumentCount, StackBytes, CalleeOffset, ReturnOffset,
    StageSize, PartOffset, RegisterNumber: LongInt;
  LocalType, OperationType, FunctionType, ExpectedType, ReturnType: TCType;
  ParameterTypes: array of TCType;
  StageOffsets: array of LongInt;
  Layout: TABIFunctionLayout;
  Location: TABIValueLocation;
  UnsignedOperation, ExpressionCall, Variadic: Boolean;
  PointerResult, PointerDifference: Boolean;
  Scale: LongInt;
  FunctionDeclaration: TFunction;
begin
  if AExpression = nil then
  begin EmitLoadImmediate(0); Exit; end;
  if AExpression.Kind = ekString then
  begin
    GlobalIndex := AddStringLiteral(AExpression.Text);
    EmitGlobalAddress(GlobalIndex);
    Exit;
  end;
  RequireRegisterValue(AExpression.CType, AExpression.Pos,
    'cross-target expression');
  case AExpression.Kind of
    ekInteger: EmitLoadImmediate(AExpression.IntValue);
    ekFloat: EmitFloatImmediate(AExpression.FloatValue, AExpression.CType);
    ekNullptr: EmitLoadImmediate(0);
    ekVariable:
      begin
        if AExpression.IsFunctionDesignator or
           IsAggregateType(AExpression.CType) then
        begin
          GenAddress(AExpression);
          Exit;
        end;
        if FindLocal(AExpression.Text, Offset, LocalType) then
          EmitLoadLocal(Offset)
        else if FindStaticLocal(AExpression.Text, GlobalIndex, LocalType) then
          EmitLoadGlobal(GlobalIndex, LocalType)
        else if FindGlobal(AExpression.Text, GlobalIndex, LocalType) then
          EmitLoadGlobal(GlobalIndex, LocalType)
        else
          RaiseCompileError(AExpression.Pos,
            'cross-target scalar variable has no definition: ' +
            AExpression.Text);
        EmitNormalize(AExpression.CType);
      end;
    ekAddress: GenAddress(AExpression.Left);
    ekDeref, ekIndex, ekMember, ekArrow:
      begin
        GenAddress(AExpression);
        if AExpression.IsBitField then
          EmitLoadBitField(AExpression.CType, AExpression.BitOffset,
            AExpression.BitWidth)
        else if not IsAggregateType(AExpression.CType) and
           not IsFunctionType(AExpression.CType) then
          EmitLoadAtAddress(AExpression.CType);
      end;
    ekUnary:
      begin
        GenExpr(AExpression.Left);
        if IsFloatingType(AExpression.Left.CType) then
        begin
          case AExpression.UnaryOp of
            uoPositive: ;
            uoNegative:
              begin
                EmitMoveAccumulatorToLeft;
                if AExpression.Left.CType.Kind = ctFloat then
                  EmitLoadImmediate(Int64($80000000))
                else
                  EmitLoadImmediate(Low(Int64));
                EmitBinary(boBitXor, True);
              end;
            uoLogicalNot:
              begin
                EmitFloatToBool(AExpression.Left.CType);
                EmitMoveAccumulatorToLeft;
                EmitLoadImmediate(1);
                EmitBinary(boBitXor, True);
              end;
          else
            RaiseCompileError(AExpression.Pos,
              'bitwise complement is invalid for floating operands');
          end;
          Exit;
        end;
        case AExpression.UnaryOp of
          uoPositive: ;
          uoNegative:
            if FTarget.Architecture = archAArch64 then EmitWord($CB0003E0)
            else EmitWord(EncodeRISCVR($20, 10, 0, 0, 10, $33));
          uoLogicalNot:
            begin
              if FTarget.Architecture = archAArch64 then
              begin
                EmitWord($F100001F);
                EmitWord($9A9F17E0);
              end
              else
                EmitWord(EncodeRISCVI(1, 10, 3, 10, $13));
            end;
          uoBitwiseNot:
            if FTarget.Architecture = archAArch64 then EmitWord($AA2003E0)
            else EmitWord(EncodeRISCVI(-1, 10, 4, 10, $13));
        end;
        EmitNormalize(AExpression.CType);
      end;
    ekBinary:
      begin
        if AExpression.BinaryOp = boLogicalAnd then
        begin
          FalseLabel := NewLabel;
          EndLabel := NewLabel;
          GenCondition(AExpression.Left);
          EmitJumpIfZero(FalseLabel);
          GenCondition(AExpression.Right);
          EmitJumpIfZero(FalseLabel);
          EmitLoadImmediate(1);
          EmitJump(EndLabel);
          BindLabel(FalseLabel);
          EmitLoadImmediate(0);
          BindLabel(EndLabel);
          Exit;
        end;
        if AExpression.BinaryOp = boLogicalOr then
        begin
          FalseLabel := NewLabel;
          EndLabel := NewLabel;
          GenCondition(AExpression.Left);
          EmitJumpIfNonZero(FalseLabel);
          GenCondition(AExpression.Right);
          EmitJumpIfNonZero(FalseLabel);
          EmitLoadImmediate(0);
          EmitJump(EndLabel);
          BindLabel(FalseLabel);
          EmitLoadImmediate(1);
          BindLabel(EndLabel);
          Exit;
        end;
        if IsFloatingType(AExpression.OperationType) or
           IsFloatingType(AExpression.Left.CType) or
           IsFloatingType(AExpression.Right.CType) then
        begin
          OperationType := AExpression.OperationType;
          if not IsFloatingType(OperationType) then
          begin
            if IsFloatingType(AExpression.Left.CType) and
               (AExpression.Left.CType.Kind = ctDouble) then
              OperationType := MakeType(ctDouble)
            else if IsFloatingType(AExpression.Right.CType) and
                    (AExpression.Right.CType.Kind = ctDouble) then
              OperationType := MakeType(ctDouble)
            else
              OperationType := MakeType(ctFloat);
          end;
          GenExprAsFloating(AExpression.Left, OperationType);
          EmitPushResult;
          GenExprAsFloating(AExpression.Right, OperationType);
          EmitPopLeft;
          EmitFloatingBinary(AExpression.BinaryOp, OperationType);
          Exit;
        end;
        { Pointer arithmetic counts in elements, not bytes. }
        PointerResult := IsPointerType(DecayType(AExpression.CType)) and
          (AExpression.BinaryOp in [boAdd, boSub]) and
          (AExpression.IntValue > 0);
        PointerDifference := (AExpression.BinaryOp = boSub) and
          IsPointerType(DecayType(AExpression.Left.CType)) and
          IsPointerType(DecayType(AExpression.Right.CType)) and
          (AExpression.IntValue > 0);
        Scale := LongInt(AExpression.IntValue);
        if Scale < 1 then Scale := 1;

        GenExpr(AExpression.Left);
        EmitPushResult;
        GenExpr(AExpression.Right);
        if PointerResult and not PointerDifference and (Scale > 1) then
        begin
          EmitMoveAccumulatorToLeft;
          EmitLoadImmediate(Scale);
          if FTarget.Architecture = archAArch64 then
            EmitWord($9B007C20)
          else
            EmitWord(EncodeRISCVR(1, 10, 5, 0, 10, $33));
        end;
        EmitPopLeft;
        OperationType := AExpression.OperationType;
        case AExpression.BinaryOp of
          boShiftRight: UnsignedOperation := OperationType.IsUnsigned;
          boLess, boLessEqual, boGreater, boGreaterEqual:
            UnsignedOperation := IsPointerType(OperationType) or
              OperationType.IsUnsigned;
        else
          UnsignedOperation := AExpression.CType.IsUnsigned;
        end;
        EmitBinary(AExpression.BinaryOp, UnsignedOperation);
        if PointerDifference and (Scale > 1) then
        begin
          EmitMoveAccumulatorToLeft;
          EmitLoadImmediate(Scale);
          EmitBinary(boDiv, False);
        end;
        EmitNormalize(AExpression.CType);
      end;
    ekAssign: GenAssignment(AExpression);
    ekCall:
      begin
        if TryGenVariadicBuiltin(AExpression) then Exit;
        ExpressionCall := AExpression.Text = '';
        FunctionDeclaration := nil;
        if ExpressionCall then
        begin
          FunctionType := DecayType(AExpression.Left.CType);
          if IsPointerType(FunctionType) then
            FunctionType := PointeeType(FunctionType);
          if (FunctionType.Kind <> ctFunction) or
             not HasFunctionSignature(FunctionType) then
            RaiseCompileError(AExpression.Pos,
              'cross-target indirect call requires a complete function type');
          ReturnType := FunctionReturnTypeOf(FunctionType);
          FixedArgumentCount := FunctionParameterCount(FunctionType);
          Variadic := FunctionIsVariadic(FunctionType);
        end
        else
        begin
          FunctionDeclaration := FProgram.FindFunction(AExpression.Text);
          if FunctionDeclaration = nil then
            RaiseCompileError(AExpression.Pos,
              'call to undeclared function ''' + AExpression.Text + '''');
          ReturnType := FunctionDeclaration.ReturnType;
          FixedArgumentCount := Length(FunctionDeclaration.Params);
          Variadic := FunctionDeclaration.IsVariadic;
        end;

        SetLength(ParameterTypes, Length(AExpression.Args));
        for I := 0 to High(AExpression.Args) do
        begin
          if I < FixedArgumentCount then
          begin
            if ExpressionCall then
              ParameterTypes[I] := FunctionParameterType(FunctionType, I)
            else
              ParameterTypes[I] := FunctionDeclaration.Params[I].CType;
          end
          else
          begin
            ParameterTypes[I] := DecayType(AExpression.Args[I].CType);
            if (ParameterTypes[I].PointerDepth = 0) and
               (ParameterTypes[I].Kind = ctFloat) then
              ParameterTypes[I] := MakeType(ctDouble)
            else if (ParameterTypes[I].PointerDepth = 0) and
                    (ParameterTypes[I].Kind in
                      [ctBool, ctChar, ctShort, ctEnum]) then
              ParameterTypes[I] := MakeType(ctInt);
          end;
          ParameterTypes[I] := DecayType(ParameterTypes[I]);
        end;

        Layout := BuildFunctionABILayout(ReturnType, ParameterTypes,
          Variadic, FTarget, FixedArgumentCount);
        try
          CalleeOffset := -1;
          if ExpressionCall then
          begin
            CalleeOffset := AllocateTemporary(8, 8);
            GenExpr(AExpression.Left);
            EmitStoreLocal(CalleeOffset);
          end;

          SetLength(StageOffsets, Length(AExpression.Args));
          for I := 0 to High(AExpression.Args) do
          begin
            ExpectedType := ParameterTypes[I];
            if IsAggregateType(ExpectedType) then
            begin
              StageSize := StorageSize(ExpectedType);
              StageOffsets[I] := AllocateTemporary(StageSize,
                StorageAlign(ExpectedType));
              GenExpr(AExpression.Args[I]);
              EmitMoveAccumulatorToLeft;
              EmitLocalAddress(StageOffsets[I]);
              EmitCopyBlock(StageSize);
            end
            else
            begin
              StageOffsets[I] := AllocateTemporary(8, 8);
              GenExprConverted(AExpression.Args[I], ExpectedType);
              EmitStoreLocal(StageOffsets[I]);
            end;
          end;

          ReturnOffset := -1;
          if IsAggregateType(ReturnType) then
            ReturnOffset := AllocateTemporary(StorageSize(ReturnType),
              StorageAlign(ReturnType));

          StackBytes := LongInt(Layout.StackArgumentBytes);
          if StackBytes > 0 then EmitAdjustStack(-StackBytes);

          { Materialize outgoing stack arguments before register arguments;
            all source values live in frame slots and cannot be clobbered. }
          for I := 0 to High(AExpression.Args) do
          begin
            Location := Layout.Parameters[I];
            if Location.PassMode = apmIndirect then
            begin
              if (Length(Location.Parts) = 0) or
                 (Location.Parts[0].StackOffset < 0) then Continue;
              { A by-reference aggregate whose pointer itself overflowed to the
                stack. }
              EmitLocalAddress(StageOffsets[I]);
              EmitMoveAccumulatorToLeft;
              EmitStackAddress(LongInt(Location.Parts[0].StackOffset));
              EmitStoreAtAddress(MakeType(ctPointer));
            end
            else if IsAggregateType(ParameterTypes[I]) then
            begin
              if Location.Kind = alkStack then
                EmitCopyLocalToStack(StageOffsets[I],
                  LongInt(Location.Parts[0].StackOffset),
                  StorageSize(ParameterTypes[I]))
              else
                for J := 0 to High(Location.Parts) do
                  if Location.Parts[J].StackOffset >= 0 then
                  begin
                    StageSize := (Location.Parts[J].BitWidth + 7) div 8;
                    EmitCopyLocalToStack(StageOffsets[I] +
                      Location.Parts[J].BitOffset div 8,
                      LongInt(Location.Parts[J].StackOffset), StageSize);
                  end;
            end
            else
            begin
              if (Length(Location.Parts) = 0) or
                 (Location.Parts[0].StackOffset < 0) then Continue;
              if (FTarget.Architecture = archAArch64) and
                 (FTarget.OperatingSystem = osDarwin) and
                 not (Variadic and (I >= FixedArgumentCount)) then
                StageSize := StorageSize(ParameterTypes[I])
              else
                StageSize := 8;
              EmitCopyLocalToStack(StageOffsets[I],
                LongInt(Location.Parts[0].StackOffset), StageSize);
            end;
          end;

          { AAPCS64's indirect-result register is the dedicated x8. Set it
            before ordinary arguments: computing the address uses x0, while
            subsequent direct argument loads leave x8 intact. }
          if Layout.UsesHiddenReturnPointer and
             (FTarget.Architecture = archAArch64) then
          begin
            EmitLocalAddress(ReturnOffset);
            EmitMoveAccumulatorToRegister(8);
          end;

          for I := 0 to High(AExpression.Args) do
          begin
            Location := Layout.Parameters[I];
            if Location.Kind = alkStack then Continue;
            if Location.PassMode = apmIndirect then
            begin
              EmitLocalAddress(StageOffsets[I]);
              RegisterNumber := Location.Parts[0].RegisterNumber;
              EmitMoveAccumulatorToRegister(RegisterNumber);
              Continue;
            end;
            if IsAggregateType(ParameterTypes[I]) then
            begin
              for J := 0 to High(Location.Parts) do
              begin
                if Location.Parts[J].RegisterNumber < 0 then Continue;
                PartOffset := Location.Parts[J].BitOffset div 8;
                if Location.Parts[J].ValueClass = ascInteger then
                  EmitLoadLocalPartToIntegerRegister(
                    StageOffsets[I] + PartOffset,
                    Location.Parts[J].RegisterNumber,
                    Location.Parts[J].BitWidth)
                else if Location.Parts[J].ValueClass in [ascSSE, ascSSEUp] then
                begin
                  { Homogeneous aggregate classifiers use each member's exact
                    bit width to select the load width. }
                  if Location.Parts[J].BitWidth <= 32 then
                    ExpectedType := MakeType(ctFloat)
                  else
                    ExpectedType := MakeType(ctDouble);
                  EmitLoadLocalToFloatRegister(StageOffsets[I] + PartOffset,
                    Location.Parts[J].RegisterNumber, ExpectedType);
                end
                else
                  RaiseCompileError(AExpression.Pos,
                    'unsupported aggregate ABI class in cross-target call');
              end;
            end
            else if IsFloatingType(ParameterTypes[I]) and
                    (Length(Location.Parts) > 0) and
                    (Location.Parts[0].ValueClass in [ascSSE, ascSSEUp]) then
              EmitLoadLocalToFloatRegister(StageOffsets[I],
                Location.Parts[0].RegisterNumber, ParameterTypes[I])
            else
              EmitLoadLocalToIntegerRegister(StageOffsets[I],
                Location.Parts[0].RegisterNumber);
          end;

          { RISC-V's hidden result pointer occupies a0, which is also the
            expression accumulator used while materializing by-reference
            arguments, so it must be assigned after all ordinary arguments. }
          if Layout.UsesHiddenReturnPointer and
             (FTarget.Architecture = archRISCV64) then
          begin
            EmitLocalAddress(ReturnOffset);
            EmitMoveAccumulatorToRegister(10);
          end;

          FunctionLabel := -1;
          if ExpressionCall then
          begin
            if FTarget.Architecture = archAArch64 then
            begin
              EmitLoadLocalToIntegerRegister(CalleeOffset, 9);
              EmitWord($D63F0120); { blr x9 }
            end
            else
            begin
              EmitLoadLocalToIntegerRegister(CalleeOffset, 6);
              EmitWord(EncodeRISCVI(0, 6, 0, 1, $67)); { jalr ra,t1 }
            end;
          end
          else
          begin
            FunctionLabel := FindFunctionLabel(AExpression.Text);
            if FunctionLabel < 0 then
            begin
              if FObjectMode then EmitExternalCall(AExpression.Text)
              else
                RaiseCompileError(AExpression.Pos,
                  'undefined cross-target function ''' + AExpression.Text + '''');
            end
            else
              EmitCall(FunctionLabel);
          end;

          if StackBytes > 0 then EmitAdjustStack(StackBytes);

          if IsAggregateType(ReturnType) then
          begin
            if not Layout.UsesHiddenReturnPointer then
              for J := 0 to High(Layout.ReturnLocation.Parts) do
              begin
                PartOffset := Layout.ReturnLocation.Parts[J].BitOffset div 8;
                if Layout.ReturnLocation.Parts[J].ValueClass = ascInteger then
                begin
                  if FTarget.Architecture = archAArch64 then
                    RegisterNumber :=
                      Layout.ReturnLocation.Parts[J].RegisterNumber
                  else
                    RegisterNumber := 10 +
                      Layout.ReturnLocation.Parts[J].RegisterNumber;
                  EmitStoreIntegerRegisterToLocalPart(RegisterNumber,
                    ReturnOffset + PartOffset,
                    Layout.ReturnLocation.Parts[J].BitWidth);
                end
                else if Layout.ReturnLocation.Parts[J].ValueClass in
                  [ascSSE, ascSSEUp] then
                begin
                  if Layout.ReturnLocation.Parts[J].BitWidth <= 32 then
                    ExpectedType := MakeType(ctFloat)
                  else
                    ExpectedType := MakeType(ctDouble);
                  EmitStoreFloatRegisterToLocal(
                    Layout.ReturnLocation.Parts[J].RegisterNumber,
                    ReturnOffset + PartOffset, ExpectedType);
                end
                else
                  RaiseCompileError(AExpression.Pos,
                    'unsupported aggregate return ABI class');
              end;
            EmitLocalAddress(ReturnOffset);
            Exit;
          end;
          if IsFloatingType(ReturnType) then
            EmitFloatAccumulatorToBits(ReturnType)
          else
            EmitNormalize(ReturnType);
        finally
          Layout.Free;
        end;
      end;
    ekConditional:
      begin
        FalseLabel := NewLabel;
        EndLabel := NewLabel;
        GenCondition(AExpression.Left);
        EmitJumpIfZero(FalseLabel);
        GenExprConverted(AExpression.Right, AExpression.CType);
        EmitJump(EndLabel);
        BindLabel(FalseLabel);
        GenExprConverted(AExpression.Third, AExpression.CType);
        BindLabel(EndLabel);
        EmitNormalize(AExpression.CType);
      end;
    ekPreInc: GenIncDec(AExpression, 1, False);
    ekPreDec: GenIncDec(AExpression, -1, False);
    ekPostInc: GenIncDec(AExpression, 1, True);
    ekPostDec: GenIncDec(AExpression, -1, True);
    ekCast:
      GenExprConverted(AExpression.Left, AExpression.CType);
    ekComma:
      begin GenExpr(AExpression.Left); GenExpr(AExpression.Right); end;
    ekSizeof, ekAlignof: EmitLoadImmediate(AExpression.IntValue);
    ekCompoundLit:
      begin
        GenAddress(AExpression);
        if not IsAggregateType(AExpression.CType) then
          EmitLoadAtAddress(AExpression.CType);
      end;
  else
    RaiseCompileError(AExpression.Pos,
      'expression form is outside the freestanding integer cross subset');
  end;
end;

procedure TCrossIntegerBackend.GenStmt(AStatement: TStmt);
var
  I, J, Offset, SavedCount, ElseLabel, EndLabel, CondLabel,
    BodyLabel, ContinueLabel, DefaultLabel, PartOffset,
    RegisterNumber: LongInt;
  SwitchEntries: TCrossSwitchEntryArray;
  PartType: TCType;
begin
  if AStatement = nil then Exit;
  case AStatement.Kind of
    skEmpty, skStaticAssert: ;
    skExpr: GenExpr(AStatement.Expr);
    skDecl:
      if not AStatement.IsStatic then
      begin
        AddLocal(AStatement.Name, AStatement.CType, Offset);
        if IsAggregateType(AStatement.CType) then
        begin
          EmitZeroLocalBlock(Offset, StorageSize(AStatement.CType));
          if AStatement.Expr <> nil then
            InitializeLocalAt(Offset, 0, AStatement.CType, AStatement.Expr,
              AStatement.Pos);
        end
        else
        begin
          if AStatement.Expr <> nil then
            GenExprConverted(AStatement.Expr, AStatement.CType)
          else EmitLoadImmediate(0);
          EmitNormalize(AStatement.CType);
          EmitStoreLocal(Offset);
        end;
      end;
    skReturn:
      begin
        if AStatement.Expr <> nil then
          GenExprConverted(AStatement.Expr, FCurrentReturnType)
        else EmitLoadImmediate(0);
        if IsAggregateType(FCurrentReturnType) then
        begin
          { Aggregate expressions yield an address. Large results are copied
            through the ABI's hidden result pointer; register-class results
            are marshaled part by part in reverse order so loading a later
            part cannot destroy x0/a0 after it has been assigned. }
          if FCurrentUsesHiddenReturn then
          begin
            EmitMoveAccumulatorToLeft;
            EmitLoadLocal(FCurrentSRetOffset);
            EmitCopyBlock(StorageSize(FCurrentReturnType));
          end
          else
          begin
            EmitPushResult;
            for J := High(FCurrentReturnLocation.Parts) downto 0 do
            begin
              EmitLoadStackValue(0);
              PartOffset :=
                FCurrentReturnLocation.Parts[J].BitOffset div 8;
              EmitAddLargeImmediate(PartOffset);
              if FCurrentReturnLocation.Parts[J].ValueClass = ascInteger then
              begin
                if FCurrentReturnLocation.Parts[J].BitWidth <= 8 then
                  PartType := MakeType(ctChar, True)
                else if FCurrentReturnLocation.Parts[J].BitWidth <= 16 then
                  PartType := MakeType(ctShort, True)
                else if FCurrentReturnLocation.Parts[J].BitWidth <= 32 then
                  PartType := MakeType(ctInt, True)
                else
                  PartType := MakeType(ctLong, True);
                EmitLoadAtAddress(PartType);
                if FTarget.Architecture = archAArch64 then
                  RegisterNumber :=
                    FCurrentReturnLocation.Parts[J].RegisterNumber
                else
                  RegisterNumber := 10 +
                    FCurrentReturnLocation.Parts[J].RegisterNumber;
                EmitMoveAccumulatorToRegister(RegisterNumber);
              end
              else if FCurrentReturnLocation.Parts[J].ValueClass in
                [ascSSE, ascSSEUp] then
              begin
                if FCurrentReturnLocation.Parts[J].BitWidth <= 32 then
                  PartType := MakeType(ctFloat)
                else
                  PartType := MakeType(ctDouble);
                EmitLoadAtAddress(PartType);
                EmitAccumulatorToFloatRegister(
                  FCurrentReturnLocation.Parts[J].RegisterNumber, PartType);
              end
              else
                RaiseCompileError(AStatement.Pos,
                  'unsupported aggregate return ABI class');
            end;
            EmitAdjustStack(16);
          end;
        end
        else if IsFloatingType(FCurrentReturnType) then
          EmitBitsToFloatAccumulator(FCurrentReturnType)
        else
          EmitNormalize(FCurrentReturnType);
        EmitJump(FEpilogueLabel);
      end;
    skLabel:
      begin
        BindLabel(FindUserLabel(AStatement.Name));
        GenStmt(AStatement.Body);
      end;
    skGoto:
      EmitJump(FindUserLabel(AStatement.Name));
    skCase, skDefault: GenStmt(AStatement.Body);
    skSwitch:
      begin
        EndLabel := NewLabel;
        SetLength(SwitchEntries, 0);
        CollectSwitchEntries(AStatement.Body, SwitchEntries);
        DefaultLabel := -1;
        for I := 0 to High(SwitchEntries) do
        begin
          SwitchEntries[I].TargetLabel := NewLabel;
          if SwitchEntries[I].IsDefault then
            DefaultLabel := SwitchEntries[I].TargetLabel;
        end;
        { The selector lives in a frame slot so each comparison can reload it
          without leaving anything on the expression stack when a case is
          entered by branch. }
        Offset := AllocateTemporarySlot;
        GenCondition(AStatement.Expr);
        EmitStoreLocal(Offset);
        for I := 0 to High(SwitchEntries) do
          if not SwitchEntries[I].IsDefault then
          begin
            EmitLoadLocal(Offset);
            EmitMoveAccumulatorToLeft;
            EmitLoadImmediate(SwitchEntries[I].Value);
            EmitBinary(boEqual, False);
            EmitJumpIfNonZero(SwitchEntries[I].TargetLabel);
          end;
        if DefaultLabel >= 0 then EmitJump(DefaultLabel)
        else EmitJump(EndLabel);
        if Length(FContinueLabels) > 0 then
          PushLoop(EndLabel, FContinueLabels[High(FContinueLabels)])
        else
          PushLoop(EndLabel, -1);
        GenSwitchBody(AStatement.Body, SwitchEntries);
        PopLoop;
        BindLabel(EndLabel);
      end;
    skBlock:
      { A comma declaration such as `int i, s;` is a group of declarations, not
        a nested scope; its names stay visible in the enclosing block. }
      if AStatement.IsDeclarationGroup then
      begin
        for I := 0 to High(AStatement.Children) do
          GenStmt(AStatement.Children[I]);
      end
      else
      begin
        SavedCount := Length(FLocals);
        EnterScope;
        for I := 0 to High(AStatement.Children) do GenStmt(AStatement.Children[I]);
        LeaveScope(SavedCount);
      end;
    skIf:
      begin
        ElseLabel := NewLabel;
        EndLabel := NewLabel;
        GenCondition(AStatement.Expr);
        EmitJumpIfZero(ElseLabel);
        GenStmt(AStatement.Body);
        EmitJump(EndLabel);
        BindLabel(ElseLabel);
        GenStmt(AStatement.ElseBody);
        BindLabel(EndLabel);
      end;
    skWhile:
      begin
        CondLabel := NewLabel;
        EndLabel := NewLabel;
        BindLabel(CondLabel);
        GenCondition(AStatement.Expr);
        EmitJumpIfZero(EndLabel);
        PushLoop(EndLabel, CondLabel);
        GenStmt(AStatement.Body);
        PopLoop;
        EmitJump(CondLabel);
        BindLabel(EndLabel);
      end;
    skDoWhile:
      begin
        BodyLabel := NewLabel;
        ContinueLabel := NewLabel;
        EndLabel := NewLabel;
        BindLabel(BodyLabel);
        PushLoop(EndLabel, ContinueLabel);
        GenStmt(AStatement.Body);
        PopLoop;
        BindLabel(ContinueLabel);
        GenExpr(AStatement.Expr);
        EmitJumpIfNonZero(BodyLabel);
        BindLabel(EndLabel);
      end;
    skFor:
      begin
        SavedCount := Length(FLocals);
        EnterScope;
        GenStmt(AStatement.InitStmt);
        CondLabel := NewLabel;
        ContinueLabel := NewLabel;
        EndLabel := NewLabel;
        BindLabel(CondLabel);
        if AStatement.Expr <> nil then
        begin
          GenCondition(AStatement.Expr);
          EmitJumpIfZero(EndLabel);
        end;
        PushLoop(EndLabel, ContinueLabel);
        GenStmt(AStatement.Body);
        PopLoop;
        BindLabel(ContinueLabel);
        if AStatement.Expr2 <> nil then GenExpr(AStatement.Expr2);
        EmitJump(CondLabel);
        BindLabel(EndLabel);
        LeaveScope(SavedCount);
      end;
    skBreak:
      begin
        if Length(FBreakLabels) = 0 then
          RaiseCompileError(AStatement.Pos, 'break is outside a cross-target loop');
        EmitJump(FBreakLabels[High(FBreakLabels)]);
      end;
    skContinue:
      begin
        if Length(FContinueLabels) = 0 then
          RaiseCompileError(AStatement.Pos, 'continue is outside a cross-target loop');
        EmitJump(FContinueLabels[High(FContinueLabels)]);
      end;
  else
    RaiseCompileError(AStatement.Pos,
      'statement form is outside the freestanding integer cross subset');
  end;
end;

procedure TCrossIntegerBackend.GenFunction(AFunction: TFunction;
  ALabel: LongInt);
var
  I, J, Offset, LocalBytes, IncomingOffset, RegisterNumber,
    PartOffset, PartSize, VarArgSaveBytes: LongInt;
  ParameterTypes: array of TCType;
  Layout: TABIFunctionLayout;
  Location: TABIValueLocation;
  PartType: TCType;
begin
  RequireRegisterValue(AFunction.ReturnType, AFunction.Pos, 'function return');
  FCurrentReturnType := AFunction.ReturnType;
  SetLength(ParameterTypes, Length(AFunction.Params));
  for I := 0 to High(AFunction.Params) do
    ParameterTypes[I] := AFunction.Params[I].CType;
  Layout := BuildFunctionABILayout(AFunction.ReturnType, ParameterTypes,
    AFunction.IsVariadic, FTarget, Length(AFunction.Params));
  FCurrentIsVariadic := AFunction.IsVariadic;
  FCurrentVarArgGPUsed := Layout.IntegerRegistersUsed;
  if FCurrentVarArgGPUsed > 8 then FCurrentVarArgGPUsed := 8;
  FCurrentVarArgFPUsed := Layout.FloatingRegistersUsed;
  if FCurrentVarArgFPUsed > 8 then FCurrentVarArgFPUsed := 8;
  FCurrentVarArgStackOffset := LongInt(Layout.StackArgumentDataBytes);
  VarArgSaveBytes := 0;
  { Parameters, locals (aggregates at full size), switch selectors and a
    margin for alignment padding. }
  LocalBytes := CountLocalBytes(AFunction.Body) +
    CountSwitchSlots(AFunction.Body) * 16 + 64;
  for I := 0 to High(AFunction.Params) do
  begin
    Offset := StorageSize(AFunction.Params[I].CType);
    if Offset < 8 then Offset := 8;
    Inc(LocalBytes, AlignUp(Offset, 8) +
      StorageAlign(AFunction.Params[I].CType) + 8);
  end;
  if AFunction.IsVariadic and
     (FTarget.Architecture = archAArch64) and
     (FTarget.OperatingSystem <> osDarwin) then
    Inc(LocalBytes, 192)
  else if AFunction.IsVariadic and
          (FTarget.Architecture = archRISCV64) then
    VarArgSaveBytes := (8 - FCurrentVarArgGPUsed) * 8;
  if FTarget.Architecture = archAArch64 then
  begin
    FFrameSize := AlignUp(LocalBytes, 16);
    FLocalLimit := FFrameSize;
    FPrologueRAOffset := -1;
    FPrologueFPOffset := -1;
    if FFrameSize > 4080 then
      RaiseCompileError(AFunction.Pos, 'AArch64 cross-target frame is too large');
  end
  else
  begin
    FFrameSize := AlignUp(LocalBytes + 16 + VarArgSaveBytes, 16);
    FPrologueRAOffset := FFrameSize - VarArgSaveBytes - 8;
    FPrologueFPOffset := FPrologueRAOffset - 8;
    FLocalLimit := FPrologueFPOffset;
    if FFrameSize > 2032 then
      RaiseCompileError(AFunction.Pos, 'RISC-V cross-target frame is too large');
  end;
  FNextLocalOffset := 0;
  FCurrentFunctionName := AFunction.Name;
  SetLength(FLocals, 0);
  SetLength(FUserLabels, 0);
  ReserveUserLabels(AFunction.Body);
  FScopeDepth := 0;
  BindLabel(ALabel);
  if FTarget.Architecture = archAArch64 then
  begin
    EmitWord($A9BF7BFD);
    if FFrameSize > 0 then
      EmitWord($D10003FF or (LongWord(FFrameSize) shl 10));
    EmitWord($910003FD);
  end
  else
  begin
    EmitWord(EncodeRISCVI(-FFrameSize, 2, 0, 2, $13));
    EmitWord(EncodeRISCVS(FPrologueRAOffset, 1, 2, 3));
    EmitWord(EncodeRISCVS(FPrologueFPOffset, 8, 2, 3));
    EmitWord(EncodeRISCVI(0, 2, 0, 8, $13));
  end;

  FCurrentVarArgSaveOffset := -1;
  if AFunction.IsVariadic and
     (FTarget.Architecture = archAArch64) and
     (FTarget.OperatingSystem <> osDarwin) then
  begin
    FCurrentVarArgSaveOffset := AllocateTemporary(192, 16);
    { Preserve every incoming argument register before parameter lowering can
      use x0/x1 as scratch registers. FP save slots are 16 bytes apart as
      required by AAPCS64; scalar values occupy their low 4 or 8 bytes. }
    for I := 0 to 7 do
    begin
      EmitStoreIntegerRegisterToLocal(I,
        FCurrentVarArgSaveOffset + I * 8);
      EmitStoreFloatRegisterToLocal(I,
        FCurrentVarArgSaveOffset + 64 + I * 16, MakeType(ctDouble));
    end;
  end
  else if AFunction.IsVariadic and
          (FTarget.Architecture = archRISCV64) and
          (VarArgSaveBytes > 0) then
  begin
    { Put the unused a-registers immediately below the caller's entry stack
      pointer. The resulting sequence is contiguous with stack-passed unnamed
      arguments, matching the psABI's pointer-valued va_list. }
    FCurrentVarArgSaveOffset := FFrameSize - VarArgSaveBytes;
    for I := FCurrentVarArgGPUsed to 7 do
      EmitStoreIntegerRegisterToLocal(10 + I,
        FCurrentVarArgSaveOffset + (I - FCurrentVarArgGPUsed) * 8);
  end;

  FCurrentReturnLocation := Layout.ReturnLocation;
  FCurrentUsesHiddenReturn := Layout.UsesHiddenReturnPointer;
  FCurrentSRetOffset := -1;
  if FCurrentUsesHiddenReturn then
  begin
    AddLocal('$rcc.sret', MakeType(ctPointer), FCurrentSRetOffset);
    if FTarget.Architecture = archAArch64 then
      EmitStoreIntegerRegisterToLocal(8, FCurrentSRetOffset)
    else
      EmitStoreIntegerRegisterToLocal(10, FCurrentSRetOffset);
  end;
  for I := 0 to High(AFunction.Params) do
  begin
    RequireRegisterValue(AFunction.Params[I].CType, AFunction.Pos,
      'function parameter');
    AddLocal(AFunction.Params[I].Name, AFunction.Params[I].CType, Offset);
    Location := Layout.Parameters[I];
    if Location.Kind = alkStack then
    begin
      if FTarget.Architecture = archAArch64 then
        IncomingOffset := FFrameSize + 16 +
          LongInt(Location.Parts[0].StackOffset)
      else
        IncomingOffset := FFrameSize +
          LongInt(Location.Parts[0].StackOffset);
      if Location.PassMode = apmIndirect then
      begin
        EmitLoadLocal(IncomingOffset);
        EmitMoveAccumulatorToLeft;
        EmitLocalAddress(Offset);
        EmitCopyBlock(StorageSize(AFunction.Params[I].CType));
      end
      else if IsAggregateType(AFunction.Params[I].CType) then
      begin
        EmitLocalAddress(IncomingOffset);
        EmitMoveAccumulatorToLeft;
        EmitLocalAddress(Offset);
        EmitCopyBlock(StorageSize(AFunction.Params[I].CType));
      end;
      if not IsAggregateType(AFunction.Params[I].CType) then
      begin
        EmitLocalAddress(IncomingOffset);
        EmitLoadAtAddress(AFunction.Params[I].CType);
        EmitNormalize(AFunction.Params[I].CType);
        EmitStoreLocal(Offset);
      end;
      Continue;
    end;

    if Location.PassMode = apmIndirect then
    begin
      RegisterNumber := Location.Parts[0].RegisterNumber;
      if FTarget.Architecture = archAArch64 then
      begin
        if RegisterNumber <> 0 then
          EmitWord($AA0003E0 or (LongWord(RegisterNumber) shl 16));
      end
      else if RegisterNumber <> 10 then
        EmitWord(EncodeRISCVI(0, RegisterNumber, 0, 10, $13));
      EmitMoveAccumulatorToLeft;
      EmitLocalAddress(Offset);
      EmitCopyBlock(StorageSize(AFunction.Params[I].CType));
      Continue;
    end;

    if IsAggregateType(AFunction.Params[I].CType) then
    begin
      for J := 0 to High(Location.Parts) do
      begin
        PartOffset := Location.Parts[J].BitOffset div 8;
        if Location.Parts[J].RegisterNumber < 0 then
        begin
          { RISC-V may split a two-XLEN aggregate between the final argument
            register and the incoming stack area. Preserve the exact tail
            width so a short final chunk cannot overwrite the next local. }
          if FTarget.Architecture = archAArch64 then
            IncomingOffset := FFrameSize + 16 +
              LongInt(Location.Parts[J].StackOffset)
          else
            IncomingOffset := FFrameSize +
              LongInt(Location.Parts[J].StackOffset);
          PartSize := (Location.Parts[J].BitWidth + 7) div 8;
          EmitLocalAddress(IncomingOffset);
          EmitMoveAccumulatorToLeft;
          EmitLocalAddress(Offset + PartOffset);
          EmitCopyBlock(PartSize);
          Continue;
        end;
        if Location.Parts[J].ValueClass = ascInteger then
          EmitStoreIntegerRegisterToLocalPart(
            Location.Parts[J].RegisterNumber, Offset + PartOffset,
            Location.Parts[J].BitWidth)
        else if Location.Parts[J].ValueClass in [ascSSE, ascSSEUp] then
        begin
          if Location.Parts[J].BitWidth <= 32 then
            PartType := MakeType(ctFloat)
          else
            PartType := MakeType(ctDouble);
          EmitStoreFloatRegisterToLocal(Location.Parts[J].RegisterNumber,
            Offset + PartOffset, PartType);
        end
        else
          RaiseCompileError(AFunction.Pos,
            'unsupported aggregate ABI class in function parameter');
      end;
      Continue;
    end;

    if IsFloatingType(AFunction.Params[I].CType) and
       (Location.Parts[0].ValueClass in [ascSSE, ascSSEUp]) then
      EmitStoreFloatRegisterToLocal(Location.Parts[0].RegisterNumber,
        Offset, AFunction.Params[I].CType)
    else
    begin
      RegisterNumber := Location.Parts[0].RegisterNumber;
      if FTarget.Architecture = archAArch64 then
        EmitStoreIntegerRegisterToLocal(RegisterNumber, Offset)
      else
        EmitStoreIntegerRegisterToLocal(RegisterNumber, Offset);
    end;
  end;
  Layout.Free;

  FEpilogueLabel := NewLabel;
  GenStmt(AFunction.Body);
  EmitLoadImmediate(0);
  BindLabel(FEpilogueLabel);
  if FTarget.Architecture = archAArch64 then
  begin
    EmitWord($910003BF);
    if FFrameSize > 0 then
      EmitWord($910003FF or (LongWord(FFrameSize) shl 10));
    EmitWord($A8C17BFD);
    EmitWord($D65F03C0);
  end
  else
  begin
    EmitWord(EncodeRISCVI(0, 8, 0, 2, $13));
    EmitWord(EncodeRISCVI(FPrologueRAOffset, 2, 3, 1, $03));
    EmitWord(EncodeRISCVI(FPrologueFPOffset, 2, 3, 8, $03));
    EmitWord(EncodeRISCVI(FFrameSize, 2, 0, 2, $13));
    EmitWord($00008067);
  end;
  Inc(FFunctionsEmitted);
end;

procedure TCrossIntegerBackend.EmitStartup;
var
  MainLabel, SyscallRegister, N: LongInt;
  SyscallNumber: LongWord;
begin
  MainLabel := FindFunctionLabel('main');
  if MainLabel < 0 then
    raise ERCCError.Create('error: no main function was defined');
  EmitCall(MainLabel);
  if not TargetSyscallNumber(FTarget, 'exit', SyscallNumber) then
    raise ERCCError.Create('error: target has no direct exit system call ABI');
  if FTarget.Architecture = archAArch64 then
  begin
    if FTarget.OperatingSystem = osNetBSD then
    begin
      N := Length(FSyscallSites);
      SetLength(FSyscallSites, N + 1);
      FSyscallSites[N].TextOffset := QWord(FText.Size);
      FSyscallSites[N].Number := SyscallNumber;
      EmitWord($D4000001 or ((SyscallNumber and $FFFF) shl 5));
    end
    else
    begin
      if SyscallNumber > $FFFF then
        raise ERCCError.Create('error: AArch64 syscall number is too large');
      EmitWord($D2800008 or (SyscallNumber shl 5));
      N := Length(FSyscallSites);
      SetLength(FSyscallSites, N + 1);
      FSyscallSites[N].TextOffset := QWord(FText.Size);
      FSyscallSites[N].Number := SyscallNumber;
      EmitWord($D4000001);
    end;
  end
  else
  begin
    case FTarget.OperatingSystem of
      osLinux: SyscallRegister := 17;
      osFreeBSD, osOpenBSD: SyscallRegister := 5;
      osNetBSD: SyscallRegister := 31;
    else
      raise ERCCError.Create('error: target has no RISC-V syscall ABI');
    end;
    EmitWord(EncodeRISCVI(LongInt(SyscallNumber), 0, 0,
      SyscallRegister, $13));
    N := Length(FSyscallSites);
    SetLength(FSyscallSites, N + 1);
    FSyscallSites[N].TextOffset := QWord(FText.Size);
    FSyscallSites[N].Number := SyscallNumber;
    EmitWord($00000073);
  end;
end;

procedure TCrossIntegerBackend.GenerateFunctions;
var
  I, L: LongInt;
begin
  for I := 0 to High(FProgram.Functions) do
    if not FProgram.Functions[I].IsPrototype then
    begin
      L := FindFunctionLabel(FProgram.Functions[I].Name);
      GenFunction(FProgram.Functions[I], L);
    end;
end;

function TCrossIntegerBackend.FunctionSize(ALabel: LongInt): QWord;
var
  I, StartOffset, EndOffset, Candidate: LongInt;
begin
  StartOffset := FLabels[ALabel].Offset;
  EndOffset := FText.Size;
  for I := 0 to High(FFunctions) do
  begin
    Candidate := FLabels[FFunctions[I].LabelID].Offset;
    if (Candidate > StartOffset) and (Candidate < EndOffset) then
      EndOffset := Candidate;
  end;
  Result := QWord(EndOffset - StartOffset);
end;

procedure TCrossIntegerBackend.WriteObject(const AFileName: string);
var
  Obj: TObjectFile;
  TextIndex, DataIndex, DataSectionSymbol,
    I, L, GlobalIndex, ExternalSymbol: LongInt;
  Binding: TObjectSymbolBinding;
begin
  Obj := TObjectFile.Create(FTarget);
  try
    Obj.SourceName := 'rcc-cross-input.c';
    TextIndex := Obj.AddSection('.text', oskText, [osfAlloc, osfExecute], 16);
    DataIndex := Obj.AddSection('.data', oskData, [osfAlloc, osfWrite], 16);
    Obj.AddSection('.note.GNU-stack', oskCustom, [], 1);
    Obj.AddSymbol('', osbLocal, ostSection, osvDefault,
      TextIndex, 0, 0, True);
    DataSectionSymbol := Obj.AddSymbol('', osbLocal, ostSection, osvDefault,
      DataIndex, 0, 0, True);
    for I := 0 to High(FProgram.Functions) do
      if not FProgram.Functions[I].IsPrototype and
         FProgram.Functions[I].IsStatic then
      begin
        L := FindFunctionLabel(FProgram.Functions[I].Name);
        Obj.AddSymbol(FProgram.Functions[I].Name, osbLocal, ostFunction,
          osvDefault, TextIndex, QWord(FLabels[L].Offset),
          FunctionSize(L), True);
      end;
    for I := 0 to High(FGlobals) do
      if FGlobals[I].IsStatic then
        Obj.AddSymbol(FGlobals[I].Name, osbLocal, ostObject, osvDefault,
          DataIndex, QWord(FGlobals[I].Offset),
          QWord(FGlobals[I].Size), True);
    Binding := osbGlobal;
    for I := 0 to High(FProgram.Functions) do
      if not FProgram.Functions[I].IsPrototype and
         not FProgram.Functions[I].IsStatic then
      begin
        L := FindFunctionLabel(FProgram.Functions[I].Name);
        Obj.AddSymbol(FProgram.Functions[I].Name, Binding, ostFunction,
          osvDefault, TextIndex, QWord(FLabels[L].Offset),
          FunctionSize(L), True);
      end;
    for I := 0 to High(FGlobals) do
      if not FGlobals[I].IsStatic then
        Obj.AddSymbol(FGlobals[I].Name, Binding, ostObject, osvDefault,
          DataIndex, QWord(FGlobals[I].Offset),
          QWord(FGlobals[I].Size), True);
    for I := 0 to High(FGlobalFixups) do
    begin
      GlobalIndex := FGlobalFixups[I].GlobalIndex;
      if (FTarget.Architecture = archAArch64) and
         (FTarget.ObjectFormat = ofMachO64) then
      begin
        L := Obj.FindSymbol(FGlobals[GlobalIndex].Name);
        if L < 0 then
          raise ERCCError.Create(
            'internal error: Mach-O global symbol was not emitted');
        Obj.AddRelocation(TextIndex,
          QWord(FGlobalFixups[I].PatchOffset), L,
          orkPage21, 0, 0);
        Obj.AddRelocation(TextIndex,
          QWord(FGlobalFixups[I].PatchOffset + 4), L,
          orkPageOffset12, 0, 0);
      end
      else if FTarget.Architecture = archAArch64 then
      begin
        Obj.AddRelocation(TextIndex,
          QWord(FGlobalFixups[I].PatchOffset), DataSectionSymbol,
          orkArchitectureSpecific, 263, FGlobals[GlobalIndex].Offset);
        Obj.AddRelocation(TextIndex,
          QWord(FGlobalFixups[I].PatchOffset + 4), DataSectionSymbol,
          orkArchitectureSpecific, 266, FGlobals[GlobalIndex].Offset);
        Obj.AddRelocation(TextIndex,
          QWord(FGlobalFixups[I].PatchOffset + 8), DataSectionSymbol,
          orkArchitectureSpecific, 268, FGlobals[GlobalIndex].Offset);
        Obj.AddRelocation(TextIndex,
          QWord(FGlobalFixups[I].PatchOffset + 12), DataSectionSymbol,
          orkArchitectureSpecific, 269, FGlobals[GlobalIndex].Offset);
      end
      else
      begin
        Obj.AddRelocation(TextIndex,
          QWord(FGlobalFixups[I].PatchOffset), DataSectionSymbol,
          orkArchitectureSpecific, 26, FGlobals[GlobalIndex].Offset);
        Obj.AddRelocation(TextIndex,
          QWord(FGlobalFixups[I].PatchOffset + 4), DataSectionSymbol,
          orkArchitectureSpecific, 27, FGlobals[GlobalIndex].Offset);
      end;
    end;
    for I := 0 to High(FExternalCalls) do
    begin
      ExternalSymbol := Obj.RequireUndefinedSymbol(FExternalCalls[I].Name,
        ostFunction);
      if FTarget.Architecture = archAArch64 then
        Obj.AddRelocation(TextIndex, QWord(FExternalCalls[I].PatchOffset),
          ExternalSymbol, orkCall, 283, 0)
      else
        Obj.AddRelocation(TextIndex, QWord(FExternalCalls[I].PatchOffset),
          ExternalSymbol, orkCall, 17, 0);
    end;
    Obj.Section(TextIndex).Data.Append(FText);
    Obj.Section(DataIndex).Data.Append(FData);
    Obj.Validate;
    WriteRelocatableObject(AFileName, Obj);
  finally
    Obj.Free;
  end;
end;

procedure TCrossIntegerBackend.GenerateExecutable(const AFileName: string;
  out AStats: TCrossCodegenStats);
var
  Layout: TELFImageLayout;
begin
  FillChar(AStats, SizeOf(AStats), 0);
  AStats.Target := FTarget.Triple;
  ReserveFunctionLabels;
  AllocateGlobals;
  EmitStartup;
  GenerateFunctions;
  ResolveFixups;
  Layout := ComputeStaticELFLayout(FTarget, QWord(FText.Size),
    QWord(FData.Size), 0);
  ResolveGlobalFixups(Layout.DataAddress);
  ResolveFunctionAddressFixups(Layout.TextAddress);
  WriteStaticELF64Executable(AFileName, FTarget, FText, FData, 0,
    FSyscallSites);
  AStats.TextBytes := FText.Size;
  AStats.DataBytes := FData.Size;
  AStats.FunctionsEmitted := FFunctionsEmitted + 1;
  AStats.InstructionsEmitted := FInstructionCount;
end;

procedure TCrossIntegerBackend.GenerateObject(const AFileName: string;
  out AStats: TCrossCodegenStats);
begin
  FillChar(AStats, SizeOf(AStats), 0);
  AStats.Target := FTarget.Triple;
  ReserveFunctionLabels;
  AllocateGlobals;
  GenerateFunctions;
  ResolveFixups;
  WriteObject(AFileName);
  AStats.TextBytes := FText.Size;
  AStats.DataBytes := FData.Size;
  AStats.FunctionsEmitted := FFunctionsEmitted;
  AStats.InstructionsEmitted := FInstructionCount;
end;

procedure GenerateCrossIntegerExecutable(AProgram: TProgram;
  const ATarget: TTargetDescriptor; const AFileName: string;
  out AStats: TCrossCodegenStats);
var
  Backend: TCrossIntegerBackend;
begin
  Backend := TCrossIntegerBackend.Create(AProgram, ATarget, False);
  try
    Backend.GenerateExecutable(AFileName, AStats);
  finally
    Backend.Free;
  end;
end;

procedure GenerateCrossIntegerObject(AProgram: TProgram;
  const ATarget: TTargetDescriptor; const AFileName: string;
  out AStats: TCrossCodegenStats);
var
  Backend: TCrossIntegerBackend;
begin
  Backend := TCrossIntegerBackend.Create(AProgram, ATarget, True);
  try
    Backend.GenerateObject(AFileName, AStats);
  finally
    Backend.Free;
  end;
end;

end.
