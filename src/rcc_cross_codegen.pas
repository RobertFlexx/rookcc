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
  rcc_typeops, rcc_elf_image, rcc_object_model, rcc_object_writer;

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
    FEpilogueLabel: LongInt;
    FCurrentReturnType: TCType;
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
    function CountLocalBytes(AStatement: TStmt): LongInt;
    procedure EmitLocalAddress(AOffset: LongInt);
    procedure EmitAddLargeImmediate(AValue: Int64);
    procedure EmitMoveAccumulatorToLeft;
    procedure EmitMoveLeftToAccumulator;
    procedure EmitMoveStackPointerToAccumulator;
    procedure EmitPushAggregate(ASize: LongInt);
    procedure EmitPopArgumentPair(AIndex: LongInt);
    function AggregateRegisterCount(const AType: TCType): LongInt;
    procedure EmitPopAccumulator;
    procedure EmitCopyBlock(ASize: LongInt);
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
    procedure EmitNormalize(const AType: TCType);
    procedure EmitPushResult;
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
  Size, Count, I, StartOffset, TargetOffset, GlobalIndex, N: LongInt;
  ElementType, MemberType: TCType;
  Value: Int64;
  Member: TStructMember;
  ItemInitializer: TExpr;

  procedure AddZeros(AAmount: LongInt);
  var
    Z: LongInt;
  begin
    for Z := 1 to AAmount do FData.Add8(0);
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
    for I := 0 to High(AType.StructInfo^.Members) do
    begin
      Member := AType.StructInfo^.Members[I];
      if Member.IsBitField then
        RaiseCompileError(APos,
          'static bit-field initialization is unsupported in the cross backend');
      TargetOffset := StartOffset + Member.Offset;
      while FData.Size < TargetOffset do FData.Add8(0);
      MemberType := PCType(Member.CType)^;
      if I <= High(AInitializer.Args) then
        ItemInitializer := AInitializer.Args[I]
      else
        ItemInitializer := nil;
      EmitGlobalObject(MemberType, ItemInitializer, APos);
      if AType.Kind = ctUnion then Break;
    end;
    while FData.Size - StartOffset < Size do FData.Add8(0);
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
    if IsFloatingType(Global.CType) then
      RaiseCompileError(Global.Pos,
        'floating-point globals are not implemented in the cross backend');
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
  if FNextLocalOffset > FFrameSize then
    raise ERCCError.Create('internal error: cross-target frame estimate is too small');
  N := Length(FLocals);
  SetLength(FLocals, N + 1);
  FLocals[N].Name := AName;
  FLocals[N].Offset := AOffset;
  FLocals[N].CType := AType;
  FLocals[N].ScopeDepth := FScopeDepth;
end;

{ Frame space needed by a function body. Aggregates occupy their real size, so
  counting declarations is not enough. }
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

{ Values the cross backend can hold in the accumulator. Aggregates are handled
  by address and so are allowed to flow through expressions; floating point is
  the remaining gap. }
procedure TCrossIntegerBackend.RequireRegisterValue(const AType: TCType;
  const APos: TSourcePos; const AContext: string);
begin
  if AType.Kind = ctVoid then Exit;
  if IsAggregateType(AType) or IsFunctionType(AType) then Exit;
  if IsPointerType(AType) then Exit;
  if IsFloatingType(AType) then
    RaiseCompileError(APos, AContext +
      ' uses floating point, which the cross backend does not implement yet');
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

function TCrossIntegerBackend.AllocateTemporarySlot: LongInt;
begin
  FNextLocalOffset := AlignUp(FNextLocalOffset, 8);
  Result := FNextLocalOffset;
  Inc(FNextLocalOffset, 8);
  if FNextLocalOffset > FFrameSize then
    raise ERCCError.Create('internal error: cross-target frame estimate is too small');
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
        RaiseCompileError(APos,
          'bit-field initialization is unsupported in the cross backend');
      MemberType := PCType(Member.CType)^;
      InitializeLocalAt(ABaseOffset, AByteOffset + Member.Offset,
        MemberType, AInitializer.Args[I], APos);
    end;
    Exit;
  end;

  GenExpr(AInitializer);
  EmitNormalize(AType);
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
        if Member.IsBitField or AExpression.IsBitField then
          RaiseCompileError(AExpression.Pos,
            'bit-field access is not implemented in the cross backend');
        GenAddress(AExpression.Left);
        EmitAddLargeImmediate(Member.Offset);
      end;
    ekArrow:
      begin
        if not FindMember(PointeeType(DecayType(AExpression.Left.CType)),
             AExpression.Text, Member) then
          RaiseCompileError(AExpression.Pos,
            'unknown aggregate member ''' + AExpression.Text + '''');
        if Member.IsBitField or AExpression.IsBitField then
          RaiseCompileError(AExpression.Pos,
            'bit-field access is not implemented in the cross backend');
        GenExpr(AExpression.Left);
        EmitAddLargeImmediate(Member.Offset);
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
    GenAddress(AExpression.Right);
    EmitPushResult;
    GenAddress(AExpression.Left);
    EmitPopLeft;
    EmitCopyBlock(StorageSize(TargetType));
    Exit;
  end;

  if AExpression.AssignOp = aoAssign then
  begin
    GenAddress(AExpression.Left);
    EmitPushResult;
    GenExpr(AExpression.Right);
    EmitNormalize(TargetType);
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

procedure TCrossIntegerBackend.GenExpr(AExpression: TExpr);
var
  I, Offset, GlobalIndex, FalseLabel, EndLabel, FunctionLabel,
    FixedArgumentCount, VariadicArgumentCount, StackArgumentCount,
    RegisterIndex, SourceOffset, DestinationOffset: LongInt;
  LocalType, OperationType: TCType;
  UnsignedOperation, DarwinVariadicCall: Boolean;
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
        if not IsAggregateType(AExpression.CType) and
           not IsFunctionType(AExpression.CType) then
          EmitLoadAtAddress(AExpression.CType);
      end;
    ekUnary:
      begin
        GenExpr(AExpression.Left);
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
          GenExpr(AExpression.Left);
          EmitJumpIfZero(FalseLabel);
          GenExpr(AExpression.Right);
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
          GenExpr(AExpression.Left);
          EmitJumpIfNonZero(FalseLabel);
          GenExpr(AExpression.Right);
          EmitJumpIfNonZero(FalseLabel);
          EmitLoadImmediate(0);
          EmitJump(EndLabel);
          BindLabel(FalseLabel);
          EmitLoadImmediate(1);
          BindLabel(EndLabel);
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
        if AExpression.Text = '' then
        begin
          { Indirect call: stage the callee address below the arguments so
            evaluating them cannot clobber it. }
          if Length(AExpression.Args) > 8 then
            RaiseCompileError(AExpression.Pos,
              'cross-target indirect calls support up to eight arguments');
          GenExpr(AExpression.Left);
          EmitPushResult;
          for I := High(AExpression.Args) downto 0 do
          begin
            GenExpr(AExpression.Args[I]);
            EmitPushResult;
          end;
          for I := 0 to High(AExpression.Args) do EmitPopArgument(I);
          EmitIndirectCall;
          EmitNormalize(AExpression.CType);
          Exit;
        end;
        FunctionDeclaration := FProgram.FindFunction(AExpression.Text);
        DarwinVariadicCall :=
          (FTarget.Architecture = archAArch64) and
          (FTarget.OperatingSystem = osDarwin) and
          (FunctionDeclaration <> nil) and FunctionDeclaration.IsVariadic;
        if DarwinVariadicCall then
        begin
          FixedArgumentCount := Length(FunctionDeclaration.Params);
          if FixedArgumentCount > 8 then
            RaiseCompileError(AExpression.Pos,
              'Darwin arm64 calls support up to eight fixed register arguments');
          if FixedArgumentCount > Length(AExpression.Args) then
            RaiseCompileError(AExpression.Pos,
              'Darwin arm64 variadic call is missing a fixed argument');
          if Length(AExpression.Args) > 32 then
            RaiseCompileError(AExpression.Pos,
              'Darwin arm64 variadic calls support up to 32 scalar arguments');
        end
        else
        begin
          FixedArgumentCount := Length(AExpression.Args);
          if FixedArgumentCount > 8 then FixedArgumentCount := 8;
        end;
        for I := High(AExpression.Args) downto 0 do
        begin
          GenExpr(AExpression.Args[I]);
          { An array argument decays to a pointer; only struct and union
            values are passed by copy. }
          if IsAggregateType(AExpression.Args[I].CType) and
             not IsArrayType(AExpression.Args[I].CType) then
          begin
            if StorageSize(AExpression.Args[I].CType) > 16 then
              RaiseCompileError(AExpression.Pos,
                'aggregate arguments larger than two words are not implemented ' +
                'in the cross backend');
            EmitPushAggregate(StorageSize(AExpression.Args[I].CType));
          end
          else
            EmitPushResult;
        end;
        RegisterIndex := 0;
        for I := 0 to FixedArgumentCount - 1 do
        begin
          if IsAggregateType(AExpression.Args[I].CType) and
             not IsArrayType(AExpression.Args[I].CType) and
             (AggregateRegisterCount(AExpression.Args[I].CType) = 2) then
          begin
            if RegisterIndex + 1 > 7 then
              RaiseCompileError(AExpression.Pos,
                'aggregate argument does not fit the cross register set');
            EmitPopArgumentPair(RegisterIndex);
            Inc(RegisterIndex, 2);
          end
          else
          begin
            EmitPopArgument(RegisterIndex);
            Inc(RegisterIndex);
          end;
        end;
        StackArgumentCount := Length(AExpression.Args) - FixedArgumentCount;
        if not DarwinVariadicCall and (StackArgumentCount > 0) then
        begin
          { Arguments past the registers are staged in 16-byte slots so the
            stack stays aligned; the ABI wants them packed at the stack
            pointer, so compact them in place before the call. }
          for I := 0 to StackArgumentCount - 1 do
            if FTarget.Architecture = archAArch64 then
            begin
              EmitWord($F94003E0 or (LongWord(I * 2) shl 10) or 9);
              EmitWord($F90003E0 or (LongWord(I) shl 10) or 9);
            end
            else
            begin
              EmitWord(EncodeRISCVI(I * 16, 2, 3, 6, $03));
              EmitWord(EncodeRISCVS(I * 8, 6, 2, 3));
            end;
        end;
        VariadicArgumentCount := Length(AExpression.Args) - FixedArgumentCount;
        if DarwinVariadicCall and (VariadicArgumentCount > 1) then
          for I := 1 to VariadicArgumentCount - 1 do
          begin
            { Apple arm64 places every variadic argument in consecutive stack
              slots.  Expressions are initially staged in 16-byte slots so
              SP remains aligned; compact them in place with x9 as scratch. }
            SourceOffset := I * 16;
            DestinationOffset := I * 8;
            EmitWord($F94003E0 or
              (LongWord(SourceOffset div 8) shl 10) or 9);
            EmitWord($F90003E0 or
              (LongWord(DestinationOffset div 8) shl 10) or 9);
          end;
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
        if DarwinVariadicCall and (VariadicArgumentCount > 0) then
          EmitWord($910003FF or
            (LongWord(VariadicArgumentCount * 16) shl 10))
        else if StackArgumentCount > 0 then
        begin
          if FTarget.Architecture = archAArch64 then
            EmitWord($910003FF or (LongWord(StackArgumentCount * 16) shl 10))
          else
            EmitWord(EncodeRISCVI(StackArgumentCount * 16, 2, 0, 2, $13));
        end;
        if IsAggregateType(AExpression.CType) then
        begin
          { Spill the returned words into a frame slot so the result behaves
            like any other aggregate, which is addressed rather than held. }
          Offset := AllocateTemporarySlot;
          if AggregateRegisterCount(AExpression.CType) = 2 then
            Offset := AllocateTemporarySlot - 8;
          if FTarget.Architecture = archAArch64 then
          begin
            EmitWord($F9000000 or (LongWord(Offset div 8) shl 10) or
              (LongWord(29) shl 5));
            if AggregateRegisterCount(AExpression.CType) = 2 then
              EmitWord($F9000001 or (LongWord((Offset + 8) div 8) shl 10) or
                (LongWord(29) shl 5));
          end
          else
          begin
            EmitWord(EncodeRISCVS(Offset, 10, 8, 3));
            if AggregateRegisterCount(AExpression.CType) = 2 then
              EmitWord(EncodeRISCVS(Offset + 8, 11, 8, 3));
          end;
          EmitLocalAddress(Offset);
          Exit;
        end;
        EmitNormalize(AExpression.CType);
      end;
    ekConditional:
      begin
        FalseLabel := NewLabel;
        EndLabel := NewLabel;
        GenExpr(AExpression.Left);
        EmitJumpIfZero(FalseLabel);
        GenExpr(AExpression.Right);
        EmitJump(EndLabel);
        BindLabel(FalseLabel);
        GenExpr(AExpression.Third);
        BindLabel(EndLabel);
        EmitNormalize(AExpression.CType);
      end;
    ekPreInc: GenIncDec(AExpression, 1, False);
    ekPreDec: GenIncDec(AExpression, -1, False);
    ekPostInc: GenIncDec(AExpression, 1, True);
    ekPostDec: GenIncDec(AExpression, -1, True);
    ekCast:
      begin GenExpr(AExpression.Left); EmitNormalize(AExpression.CType); end;
    ekComma:
      begin GenExpr(AExpression.Left); GenExpr(AExpression.Right); end;
    ekSizeof, ekAlignof: EmitLoadImmediate(AExpression.IntValue);
  else
    RaiseCompileError(AExpression.Pos,
      'expression form is outside the freestanding integer cross subset');
  end;
end;

procedure TCrossIntegerBackend.GenStmt(AStatement: TStmt);
var
  I, Offset, SavedCount, ElseLabel, EndLabel, CondLabel,
    BodyLabel, ContinueLabel, DefaultLabel: LongInt;
  SwitchEntries: TCrossSwitchEntryArray;
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
          if AStatement.Expr <> nil then GenExpr(AStatement.Expr)
          else EmitLoadImmediate(0);
          EmitNormalize(AStatement.CType);
          EmitStoreLocal(Offset);
        end;
      end;
    skReturn:
      begin
        if AStatement.Expr <> nil then GenExpr(AStatement.Expr)
        else EmitLoadImmediate(0);
        if IsAggregateType(FCurrentReturnType) then
        begin
          { The accumulator holds the aggregate's address; the ABI returns its
            words in the first one or two result registers. }
          EmitMoveAccumulatorToLeft;
          if FTarget.Architecture = archAArch64 then
          begin
            if AggregateRegisterCount(FCurrentReturnType) = 2 then
              EmitWord($F9400421);
            EmitWord($F9400020);
          end
          else
          begin
            if AggregateRegisterCount(FCurrentReturnType) = 2 then
              EmitWord(EncodeRISCVI(8, 5, 3, 11, $03));
            EmitWord(EncodeRISCVI(0, 5, 3, 10, $03));
          end;
        end
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
        GenExpr(AStatement.Expr);
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
        GenExpr(AStatement.Expr);
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
        GenExpr(AStatement.Expr);
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
          GenExpr(AStatement.Expr);
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
  I, Offset, LocalBytes, IncomingOffset, RegisterIndex: LongInt;
begin
  RequireRegisterValue(AFunction.ReturnType, AFunction.Pos, 'function return');
  FCurrentReturnType := AFunction.ReturnType;
  if AFunction.IsVariadic then
    RaiseCompileError(AFunction.Pos,
      'variadic functions require a hosted target backend');
  { Parameters, locals (aggregates at full size), switch selectors and a
    margin for alignment padding. }
  LocalBytes := Length(AFunction.Params) * 16 +
    CountLocalBytes(AFunction.Body) + CountSwitchSlots(AFunction.Body) * 16 + 64;
  if FTarget.Architecture = archAArch64 then
  begin
    FFrameSize := AlignUp(LocalBytes, 16);
    if FFrameSize > 4080 then
      RaiseCompileError(AFunction.Pos, 'AArch64 cross-target frame is too large');
  end
  else
  begin
    FFrameSize := AlignUp(LocalBytes + 16, 16);
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
    EmitWord(EncodeRISCVS(FFrameSize - 8, 1, 2, 3));
    EmitWord(EncodeRISCVS(FFrameSize - 16, 8, 2, 3));
    EmitWord(EncodeRISCVI(0, 2, 0, 8, $13));
  end;

  RegisterIndex := 0;
  for I := 0 to High(AFunction.Params) do
  begin
    RequireRegisterValue(AFunction.Params[I].CType, AFunction.Pos,
      'function parameter');
    AddLocal(AFunction.Params[I].Name, AFunction.Params[I].CType, Offset);
    if IsAggregateType(AFunction.Params[I].CType) then
    begin
      if StorageSize(AFunction.Params[I].CType) > 16 then
        RaiseCompileError(AFunction.Pos,
          'aggregate parameters larger than two words are not implemented ' +
          'in the cross backend');
      { The incoming words are spilled straight into the parameter's slot. }
      if FTarget.Architecture = archAArch64 then
        EmitWord($F9000000 or (LongWord(Offset div 8) shl 10) or
          (LongWord(29) shl 5) or LongWord(RegisterIndex))
      else
        EmitWord(EncodeRISCVS(Offset, 10 + RegisterIndex, 8, 3));
      Inc(RegisterIndex);
      if AggregateRegisterCount(AFunction.Params[I].CType) = 2 then
      begin
        if FTarget.Architecture = archAArch64 then
          EmitWord($F9000000 or (LongWord((Offset + 8) div 8) shl 10) or
            (LongWord(29) shl 5) or LongWord(RegisterIndex))
        else
          EmitWord(EncodeRISCVS(Offset + 8, 10 + RegisterIndex, 8, 3));
        Inc(RegisterIndex);
      end;
      Continue;
    end;
    if RegisterIndex < 8 then
    begin
      if FTarget.Architecture = archAArch64 then
      begin
        if RegisterIndex <> 0 then
          EmitWord($AA0003E0 or (LongWord(RegisterIndex) shl 16));
      end
      else if RegisterIndex <> 0 then
        EmitWord(EncodeRISCVI(0, 10 + RegisterIndex, 0, 10, $13));
      Inc(RegisterIndex);
    end
    else
    begin
      { Arguments past the registers were placed by the caller just above this
        frame. }
      if FTarget.Architecture = archAArch64 then
        IncomingOffset := FFrameSize + 16 + (RegisterIndex - 8) * 8
      else
        IncomingOffset := FFrameSize + (RegisterIndex - 8) * 8;
      EmitLoadLocal(IncomingOffset);
      Inc(RegisterIndex);
    end;
    EmitNormalize(AFunction.Params[I].CType);
    EmitStoreLocal(Offset);
  end;

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
    EmitWord(EncodeRISCVI(FFrameSize - 8, 2, 3, 1, $03));
    EmitWord(EncodeRISCVI(FFrameSize - 16, 2, 3, 8, $03));
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
