unit rcc_backend;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, rcc_types, rcc_runtime_catalog, rcc_buffer, rcc_elf64, rcc_typeops;

type
  TBackendStats = record
    TextBytes: QWord;
    DataBytes: QWord;
    FunctionsEmitted: QWord;
    RuntimeFunctions: QWord;
    FixupsResolved: QWord;
  end;

  TLabelSection = (lsUnbound, lsText, lsData);

  TLabelInfo = record
    Section: TLabelSection;
    Offset: LongInt;
  end;

  TFixup = record
    PatchOffset: LongInt;
    TargetLabel: LongInt;
  end;

  TDataAddressFixup = record
    PatchOffset: LongInt;
    TargetLabel: LongInt;
  end;

  TNamedLabel = record
    Name: string;
    LabelID: LongInt;
  end;

  TExternalDefinition = record
    Name: string;
    LabelID: LongInt;
    SymbolType: Byte;
    Weak: Boolean;
  end;

  TExternalRelocation = record
    PatchSection: TLabelSection;
    PatchOffset: LongInt;
    TargetLabel: LongInt;
    TargetName: string;
    TargetSymbolType: Byte;
    TargetWeak: Boolean;
    TargetAbsolute: Boolean;
    AbsoluteValue: QWord;
    RelocationType: LongWord;
    Addend: Int64;
    SourceName: string;
  end;

  TExternalGOTEntry = record
    TargetLabel: LongInt;
    GOTLabel: LongInt;
  end;

  TGeneratedObjectRelocation = record
    PatchSection: TLabelSection;
    PatchOffset: LongInt;
    TargetLabel: LongInt;
    RelocationType: LongWord;
    Addend: Int64;
  end;

  TStringLabel = record
    Value: string;
    LabelID: LongInt;
  end;

  TLocal = record
    Name: string;
    Offset: LongInt;
    Size: LongInt;
    Align: LongInt;
    CType: TCType;
    IsIndirectObject: Boolean;
    ScopeDepth: LongInt;
  end;

  TSwitchEntry = record
    Statement: TStmt;
    TargetLabel: LongInt;
    MatchLabel: LongInt;
    IsDefault: Boolean;
    Value: Int64;
  end;
  TSwitchEntryArray = array of TSwitchEntry;

  TX64Backend = class
  private
    FProgram: TProgram;
      FOptions: TCompilerOptions;
      FText: TByteBuffer;
      FData: TByteBuffer;
      FLabels: array of TLabelInfo;
      FFixups: array of TFixup;
      FDataAddressFixups: array of TDataAddressFixup;
      FFunctions: array of TNamedLabel;
      FGlobals: array of TNamedLabel;
      FExternalDefinitions: array of TExternalDefinition;
      FExternalRelocations: array of TExternalRelocation;
      FExternalThunks: array of TNamedLabel;
      FExternalGOTEntries: array of TExternalGOTEntry;
      FObjectUndefined: array of TExternalDefinition;
      FGeneratedObjectRelocations: array of TGeneratedObjectRelocation;
      FRuntime: array of TNamedLabel;
      FRuntimeUsed: array of Boolean;
      FImports: TDynamicImportArray;
      FStrings: array of TStringLabel;
      FLocals: array of TLocal;
      FScopeDepth: LongInt;
      FNextLocalSlot: LongInt;
      FStackDepth: LongInt;
      FEpilogueLabel: LongInt;
      FEntryLabel: LongInt;
      FCurrentReturnType: TCType;
      FCurrentUsesSRet: Boolean;
      FCurrentSRetOffset: LongInt;
      FCurrentIsVariadic: Boolean;
      FCurrentVarArgSaveOffset: LongInt;
      FCurrentVarArgGPOffset: LongInt;
      FCurrentVarArgFPOffset: LongInt;
      FCurrentVarArgStackOffset: LongInt;
      FBreakLabels: array of LongInt;
      FContinueLabels: array of LongInt;
      FUserLabels: array of TNamedLabel;
      FListing: TStringList;
      FStats: TBackendStats;

    function AlignUp(V, A: QWord): QWord;
    function NewLabel: LongInt;
    procedure BindTextLabel(ALabel: LongInt);
    procedure BindDataLabel(ALabel: LongInt);
    procedure AddFixup(ALabel, APatchOffset: LongInt);
    procedure AddDataAddressFixup(ALabel, APatchOffset: LongInt);
    procedure EmitRel32(ALabel: LongInt);
    procedure EmitCall(ALabel: LongInt);
    procedure EmitIndirectCall(ALabel: LongInt);
    procedure EmitJump(ALabel: LongInt);
    procedure EmitJcc(AConditionOpcode: Byte; ALabel: LongInt);
    procedure ResolveFixups(ATextVA, ADataVA: QWord);
    function FindNamedLabel(const AList: array of TNamedLabel;
      const AName: string): LongInt;
    function ResolveCallable(const AName: string; const APos: TSourcePos;
      out AIndirect: Boolean): LongInt;
    function EnsureHostedFunctionImport(const AName: string): LongInt;
    function EnsureExternalImport(const AName: string;
      const APos: TSourcePos): LongInt;
    function EnsureExternalObject(const AName: string;
      const APos: TSourcePos): LongInt;
    function FindImport(const AName: string): LongInt;
    function FindExternalDefinition(const AName: string;
      ASymbolType: Byte = 0): LongInt;
    function FindLinkDefinition(const AName: string;
      ASymbolType: Byte): LongInt;
    function EnsureHostedObjectImport(const AName: string): LongInt;
    function EnsureExternalFunctionThunk(const AName: string): LongInt;
    function EnsureLocalGOTEntry(ATargetLabel: LongInt): LongInt;
    function EnsureObjectUndefined(const AName: string;
      ASymbolType: Byte): LongInt;
    procedure AddGeneratedObjectRelocation(ASection: TLabelSection;
      APatchOffset, ATargetLabel: LongInt; ARelocationType: LongWord;
      AAddend: Int64);
    procedure EmitObjectGOTLoad(ATargetLabel: LongInt);
    procedure LoadExternalInputs;
    procedure PrepareExternalRelocations;
    procedure ResolveExternalRelocations(ATextVA, ADataVA: QWord);

    procedure EmitMovRaxImm(V: Int64);
    procedure EmitMovR8Imm(V: QWord);
    procedure EmitPushRax;
    procedure EmitPopRcx;
    procedure EmitLoadLocal(AOffset: LongInt);
    procedure EmitStoreLocal(AOffset: LongInt);
    procedure EmitAddressLocal(AOffset: LongInt);
    procedure EmitLoadGlobal(ALabel: LongInt);
    procedure EmitStoreGlobal(ALabel: LongInt);
    procedure EmitAddressGlobal(ALabel: LongInt);
    procedure EmitLoadAtRax(const AType: TCType);
    procedure EmitStoreRaxAtRcx(const AType: TCType);
    procedure EmitAddRaxImmediate(AValue: LongInt);
    procedure EmitScaleRax(AFactor: LongInt);
    procedure EmitLeaRsiData(ALabel: LongInt);
    procedure EmitNormalizeBool;
    procedure EmitNormalizeInteger(const AType: TCType);
    procedure EmitNormalizeBitFieldResult(const AType: TCType;
      ABitWidth: LongInt);
    procedure EmitLoadBitField(const AType: TCType;
      ABitOffset, ABitWidth: LongInt);
    procedure EmitStoreBitFieldAtRcx(const AType: TCType;
      ABitOffset, ABitWidth: LongInt);
    procedure EmitSetCC(AOpcode: Byte);
    procedure EmitBinaryOperation(AOp: TBinaryOp; AUnsigned: Boolean);
    procedure EmitImmediateOperation(AOp: TBinaryOp; V: Int64;
      AUnsigned: Boolean; out AHandled: Boolean);
    procedure EmitMoveRaxToArg(AIndex: LongInt);
    procedure EmitPopArg(AIndex: LongInt);
    procedure EmitStoreArgToLocal(AIndex, AOffset: LongInt);
    procedure EmitStoreXmmArgToLocal(AIndex, AOffset: LongInt;
      const AType: TCType);
    procedure EmitLoadXmmFromStack(AIndex, AStackOffset: LongInt;
      const AType: TCType);
    procedure EmitPushXmm0(const AType: TCType);
    procedure EmitPopXmm1(const AType: TCType);
    procedure EmitFloatToBool(const AType: TCType);
    procedure EmitFloatingBinary(AOp: TBinaryOp; const AType: TCType);
    procedure EmitConvertIntegerToFloat(const AType: TCType);
    procedure EmitConvertFloatToInteger(const AType: TCType);
    procedure EmitConvertFloatWidth(const AFromType, AToType: TCType);

    function AddStringLiteral(const S: string): LongInt;
    procedure PreallocateInitializerLiterals(AExpression: TExpr);
    function AddFloatLiteral(AValue: Double; const AType: TCType): LongInt;
    procedure AllocateGlobals;
    procedure EmitGlobalObject(const AType: TCType; AInitializer: TExpr;
      const APos: TSourcePos);
    procedure ReserveFunctionLabels;
    procedure ReserveRuntimeLabels;
    procedure EmitStartup;
    procedure EmitRuntime;
    procedure EmitRuntimeRead;
    procedure EmitRuntimeWrite;
    procedure EmitRuntimeClose;
    procedure EmitRuntimeOpen;
    procedure EmitRuntimeLseek;
    procedure EmitRuntimeGetPid;
    procedure EmitRuntimeGetPageSize;
    procedure EmitRuntimeAccess;
    procedure EmitRuntimeTime;
    procedure EmitRuntimeExit(const AName: string);
    procedure EmitRuntimeAbort;
    procedure EmitRuntimeAtexit;
    procedure EmitRuntimeStrlen;
    procedure EmitRuntimePuts;
    procedure EmitRuntimePutchar;
    procedure EmitRuntimeGetchar;
    procedure EmitRuntimePrintInt;
    procedure EmitRuntimePrintString;
    procedure EmitRuntimePrintIntRaw;
    procedure EmitRuntimeMalloc;
    procedure EmitRuntimeCalloc;
    procedure EmitRuntimeRealloc;
    procedure EmitRuntimeReallocArray;
    procedure EmitRuntimeFree;
    procedure EmitRuntimeMemcpy;
    procedure EmitRuntimeMemmove;
    procedure EmitRuntimeMemset;
    procedure EmitRuntimeMemcmp;
    procedure EmitRuntimeStrcmp;
    procedure EmitRuntimeStrncmp;
    procedure EmitRuntimeStrcpy;
    procedure EmitRuntimeStrncpy;
    procedure EmitRuntimeStrchr;
    procedure EmitRuntimeStrrchr;
    procedure EmitRuntimeStrnlen;
    procedure EmitRuntimeParseDecimal;
    procedure EmitRuntimeAtoi(const AName: string);
    procedure EmitRuntimeAssert;
    procedure EmitRuntimeIsDigit;
    procedure EmitRuntimeIsSpace;
    procedure EmitRuntimeIsAlpha;
    procedure EmitRuntimeIsAlnum;
    procedure EmitRuntimeIsLower;
    procedure EmitRuntimeIsUpper;
    procedure EmitRuntimeIsXDigit;
    procedure EmitRuntimeIsPrint;
    procedure EmitRuntimeIsGraph;
    procedure EmitRuntimeIsCntrl;
    procedure EmitRuntimeIsPunct;
    procedure EmitRuntimeToLower;
    procedure EmitRuntimeToUpper;
    procedure EmitRuntimeAbs(const AName: string; ALong: Boolean);

    function CountLocalBytes(S: TStmt): LongInt;
    function CountExpressionSpillBytes(E: TExpr): LongInt;
    procedure ReserveTemporary(ASize, AAlignment: LongInt;
      out AOffset: LongInt);
    procedure AddLocal(const AName: string; const AType: TCType;
      AIndirectObject: Boolean; out AOffset: LongInt);
    function FindLocal(const AName: string; out AOffset: LongInt;
      out AType: TCType; out AIndirectObject: Boolean): Boolean;
    function FindGlobalLabel(const AName: string): LongInt;
    function FindGlobal(const AName: string): TGlobal;
    procedure InitializeLocalAt(AOffset, AByteOffset: LongInt;
      const AType: TCType; AInitializer: TExpr; const APos: TSourcePos);
    procedure InitializeLocal(AOffset: LongInt; const AType: TCType;
      AInitializer: TExpr; const APos: TSourcePos);
    procedure EnterScope;
    procedure LeaveScope(ASavedCount: LongInt);
    procedure PushLoop(ABreakLabel, AContinueLabel: LongInt);
    procedure PopLoop;
    procedure PushBreak(ABreakLabel: LongInt);
    procedure PopBreak;
    procedure ReserveUserLabels(S: TStmt);
    function FindUserLabel(const AName: string): LongInt;
    procedure CollectSwitchEntries(S: TStmt; var AEntries: TSwitchEntryArray);
    function SwitchTargetFor(S: TStmt;
      const AEntries: TSwitchEntryArray): LongInt;
    procedure GenSwitchBody(S: TStmt; const AEntries: TSwitchEntryArray);

    procedure GenAddress(E: TExpr);
    procedure GenExpr(E: TExpr);
    procedure GenExprAsFloating(E: TExpr; const ATargetType: TCType);
    procedure GenCondition(E: TExpr);
    function TryGenPlainPrintf(E: TExpr): Boolean;
    procedure GenAggregateABICall(E: TExpr; ACallee: TFunction;
      const AFunctionType: TCType);
    procedure GenAggregateReturn(E: TExpr);
    function TryGenVariadicBuiltin(E: TExpr): Boolean;
    procedure GenCall(E: TExpr);
    procedure GenAssignment(E: TExpr);
    procedure GenIncDec(E: TExpr; ADelta: LongInt; APost: Boolean);
    procedure GenInlineAsm(S: TStmt);
    procedure GenStmt(S: TStmt);
    procedure GenFunction(F: TFunction; ALabel: LongInt);
    procedure GenerateCode;
    procedure BuildAssemblyListing;
    procedure WriteELF(const AFileName: string);
    procedure WriteObject(const AFileName: string);
  public
    constructor Create(AProgram: TProgram; const AOptions: TCompilerOptions);
    destructor Destroy; override;
    procedure Generate(const AFileName: string);
    function AssemblyListing: string;
    property Stats: TBackendStats read FStats;
  end;

implementation

uses
  rcc_arch, rcc_library_resolver, rcc_abi, rcc_elf_reader,
  rcc_object_model, rcc_elf_image, rcc_dwarf, rcc_elf_debug;

const
  ELF_STB_GLOBAL = Byte(1);
  ELF_STB_WEAK = Byte(2);
  ELF_STT_NOTYPE = Byte(0);
  ELF_STT_OBJECT = Byte(1);
  ELF_STT_FUNC = Byte(2);
  ELF_STT_SECTION = Byte(3);
  R_X86_64_NONE = LongWord(0);
  R_X86_64_64 = LongWord(1);
  R_X86_64_PC32 = LongWord(2);
  R_X86_64_PLT32 = LongWord(4);
  R_X86_64_GOTPCREL = LongWord(9);
  R_X86_64_32 = LongWord(10);
  R_X86_64_32S = LongWord(11);
  R_X86_64_16 = LongWord(12);
  R_X86_64_PC16 = LongWord(13);
  R_X86_64_8 = LongWord(14);
  R_X86_64_PC8 = LongWord(15);
  R_X86_64_PC64 = LongWord(24);
  R_X86_64_GOTPCRELX = LongWord(41);
  R_X86_64_REX_GOTPCRELX = LongWord(42);



constructor TX64Backend.Create(AProgram: TProgram;
  const AOptions: TCompilerOptions);
begin
  inherited Create;
  FProgram := AProgram;
  FOptions := AOptions;
  FText := TByteBuffer.Create;
  FData := TByteBuffer.Create;
  FListing := TStringList.Create;
  FCurrentIsVariadic := False;
  FCurrentVarArgSaveOffset := 0;
  FCurrentVarArgGPOffset := 0;
  FCurrentVarArgFPOffset := 48;
  FCurrentVarArgStackOffset := 0;
end;

destructor TX64Backend.Destroy;
begin
  FListing.Free;
  FData.Free;
  FText.Free;
  inherited Destroy;
end;

function TX64Backend.AlignUp(V, A: QWord): QWord;
begin
  Result := (V + A - 1) and not (A - 1);
end;

function TX64Backend.NewLabel: LongInt;
var
  N: LongInt;
begin
  N := Length(FLabels);
  SetLength(FLabels, N + 1);
  FLabels[N].Section := lsUnbound;
  FLabels[N].Offset := -1;
  Result := N;
end;

procedure TX64Backend.BindTextLabel(ALabel: LongInt);
begin
  if FLabels[ALabel].Section <> lsUnbound then
    raise ERCCError.Create('internal error: label bound twice');
  FLabels[ALabel].Section := lsText;
  FLabels[ALabel].Offset := FText.Size;
end;

procedure TX64Backend.BindDataLabel(ALabel: LongInt);
begin
  if FLabels[ALabel].Section <> lsUnbound then
    raise ERCCError.Create('internal error: label bound twice');
  FLabels[ALabel].Section := lsData;
  FLabels[ALabel].Offset := FData.Size;
end;

procedure TX64Backend.AddFixup(ALabel, APatchOffset: LongInt);
var
  N: LongInt;
begin
  N := Length(FFixups);
  SetLength(FFixups, N + 1);
  FFixups[N].PatchOffset := APatchOffset;
  FFixups[N].TargetLabel := ALabel;
end;

procedure TX64Backend.AddDataAddressFixup(ALabel, APatchOffset: LongInt);
var
  N: LongInt;
begin
  N := Length(FDataAddressFixups);
  SetLength(FDataAddressFixups, N + 1);
  FDataAddressFixups[N].PatchOffset := APatchOffset;
  FDataAddressFixups[N].TargetLabel := ALabel;
end;

procedure TX64Backend.EmitRel32(ALabel: LongInt);
var
  P: LongInt;
begin
  P := FText.Size;
  FText.Add32(0);
  AddFixup(ALabel, P);
end;

procedure TX64Backend.EmitCall(ALabel: LongInt);
begin
  FText.Add8($E8);
  EmitRel32(ALabel);
end;

procedure TX64Backend.EmitIndirectCall(ALabel: LongInt);
begin
  FText.AddBytes([$FF, $15]);
  EmitRel32(ALabel);
end;

procedure TX64Backend.EmitJump(ALabel: LongInt);
begin
  FText.Add8($E9);
  EmitRel32(ALabel);
end;

procedure TX64Backend.EmitJcc(AConditionOpcode: Byte; ALabel: LongInt);
begin
  FText.Add8($0F);
  FText.Add8(AConditionOpcode);
  EmitRel32(ALabel);
end;

procedure TX64Backend.ResolveFixups(ATextVA, ADataVA: QWord);
var
  I: LongInt;
  TargetVA, NextVA: Int64;
  L: TLabelInfo;
  Disp: Int64;
begin
  for I := 0 to High(FFixups) do
  begin
    L := FLabels[FFixups[I].TargetLabel];
    if L.Section = lsUnbound then
      raise ERCCError.Create('internal error: unresolved backend label');
    if L.Section = lsText then TargetVA := Int64(ATextVA) + L.Offset
    else TargetVA := Int64(ADataVA) + L.Offset;
    NextVA := Int64(ATextVA) + FFixups[I].PatchOffset + 4;
    Disp := TargetVA - NextVA;
    if (Disp < Low(LongInt)) or (Disp > High(LongInt)) then
      raise ERCCError.Create('internal error: x86-64 relative relocation overflow');
    FText.Patch32(FFixups[I].PatchOffset, LongInt(Disp));
    Inc(FStats.FixupsResolved);
  end;
  for I := 0 to High(FDataAddressFixups) do
  begin
    L := FLabels[FDataAddressFixups[I].TargetLabel];
    if L.Section = lsUnbound then
      raise ERCCError.Create('internal error: unresolved data address label');
    if L.Section = lsText then TargetVA := Int64(ATextVA) + L.Offset
    else TargetVA := Int64(ADataVA) + L.Offset;
    FData.Patch64(FDataAddressFixups[I].PatchOffset, QWord(TargetVA));
    Inc(FStats.FixupsResolved);
  end;
end;

function TX64Backend.FindNamedLabel(const AList: array of TNamedLabel;
  const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := High(AList) downto 0 do
    if AList[I].Name = AName then Exit(AList[I].LabelID);
  Result := -1;
end;

function TX64Backend.FindImport(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := High(FImports) downto 0 do
    if FImports[I].Name = AName then Exit(I);
  Result := -1;
end;

function TX64Backend.FindExternalDefinition(const AName: string;
  ASymbolType: Byte): LongInt;
var
  I: LongInt;
begin
  for I := High(FExternalDefinitions) downto 0 do
    if (FExternalDefinitions[I].Name = AName) and
       ((ASymbolType = ELF_STT_NOTYPE) or
        (FExternalDefinitions[I].SymbolType = ASymbolType) or
        (FExternalDefinitions[I].SymbolType = ELF_STT_NOTYPE)) then
      Exit(FExternalDefinitions[I].LabelID);
  Result := -1;
end;

function TX64Backend.FindLinkDefinition(const AName: string;
  ASymbolType: Byte): LongInt;
var
  I: LongInt;
begin
  if ASymbolType <> ELF_STT_OBJECT then
  begin
    Result := FindNamedLabel(FFunctions, AName);
    if Result >= 0 then Exit;
  end;
  if ASymbolType <> ELF_STT_FUNC then
  begin
    Result := FindNamedLabel(FGlobals, AName);
    if Result >= 0 then Exit;
  end;
  Result := FindExternalDefinition(AName, ASymbolType);
  if Result >= 0 then Exit;
  if ASymbolType <> ELF_STT_OBJECT then
    for I := 0 to High(FRuntime) do
      if FRuntime[I].Name = AName then
      begin
        FRuntimeUsed[I] := True;
        Exit(FRuntime[I].LabelID);
      end;
  Result := -1;
end;

function TX64Backend.EnsureHostedObjectImport(const AName: string): LongInt;
var
  I, N, L: LongInt;
begin
  I := FindImport(AName);
  if I >= 0 then
  begin
    if FImports[I].Kind <> dikObject then
      raise ERCCError.Create('error: external symbol kind mismatch for ''' +
        AName + '''');
    Exit(FImports[I].GOTLabel);
  end;
  L := NewLabel;
  BindDataLabel(L);
  N := Length(FImports);
  SetLength(FImports, N + 1);
  FImports[N].Name := AName;
  FImports[N].GOTOffset := QWord(FData.Size);
  FImports[N].GOTLabel := L;
  FImports[N].Kind := dikObject;
  FData.Add64(0);
  Result := L;
end;

function TX64Backend.EnsureExternalFunctionThunk(const AName: string): LongInt;
var
  Existing, GOTLabel, N, L: LongInt;
begin
  Existing := FindNamedLabel(FExternalThunks, AName);
  if Existing >= 0 then Exit(Existing);
  GOTLabel := EnsureHostedFunctionImport(AName);
  L := NewLabel;
  BindTextLabel(L);
  FText.AddBytes([$FF, $25]);
  EmitRel32(GOTLabel);
  N := Length(FExternalThunks);
  SetLength(FExternalThunks, N + 1);
  FExternalThunks[N].Name := AName;
  FExternalThunks[N].LabelID := L;
  Result := L;
end;

function TX64Backend.EnsureLocalGOTEntry(ATargetLabel: LongInt): LongInt;
var
  I, N, L: LongInt;
begin
  for I := 0 to High(FExternalGOTEntries) do
    if FExternalGOTEntries[I].TargetLabel = ATargetLabel then
      Exit(FExternalGOTEntries[I].GOTLabel);
  FData.PadTo(8);
  L := NewLabel;
  BindDataLabel(L);
  AddDataAddressFixup(ATargetLabel, FData.Size);
  FData.Add64(0);
  N := Length(FExternalGOTEntries);
  SetLength(FExternalGOTEntries, N + 1);
  FExternalGOTEntries[N].TargetLabel := ATargetLabel;
  FExternalGOTEntries[N].GOTLabel := L;
  Result := L;
end;

function TX64Backend.EnsureObjectUndefined(const AName: string;
  ASymbolType: Byte): LongInt;
var
  I, N, L: LongInt;
begin
  for I := 0 to High(FObjectUndefined) do
    if FObjectUndefined[I].Name = AName then
    begin
      if (FObjectUndefined[I].SymbolType <> ASymbolType) and
         (FObjectUndefined[I].SymbolType <> ELF_STT_NOTYPE) and
         (ASymbolType <> ELF_STT_NOTYPE) then
        raise ERCCError.Create('error: external symbol kind mismatch for ''' +
          AName + '''');
      Exit(FObjectUndefined[I].LabelID);
    end;
  L := NewLabel;
  N := Length(FObjectUndefined);
  SetLength(FObjectUndefined, N + 1);
  FObjectUndefined[N].Name := AName;
  FObjectUndefined[N].LabelID := L;
  FObjectUndefined[N].SymbolType := ASymbolType;
  FObjectUndefined[N].Weak := False;
  Result := L;
end;

procedure TX64Backend.AddGeneratedObjectRelocation(
  ASection: TLabelSection; APatchOffset, ATargetLabel: LongInt;
  ARelocationType: LongWord; AAddend: Int64);
var
  N: LongInt;
begin
  N := Length(FGeneratedObjectRelocations);
  SetLength(FGeneratedObjectRelocations, N + 1);
  FGeneratedObjectRelocations[N].PatchSection := ASection;
  FGeneratedObjectRelocations[N].PatchOffset := APatchOffset;
  FGeneratedObjectRelocations[N].TargetLabel := ATargetLabel;
  FGeneratedObjectRelocations[N].RelocationType := ARelocationType;
  FGeneratedObjectRelocations[N].Addend := AAddend;
end;

procedure TX64Backend.EmitObjectGOTLoad(ATargetLabel: LongInt);
var
  PatchOffset: LongInt;
begin
  FText.AddBytes([$48, $8B, $05]);
  PatchOffset := FText.Size;
  FText.Add32(0);
  AddGeneratedObjectRelocation(lsText, PatchOffset, ATargetLabel,
    R_X86_64_REX_GOTPCRELX, -4);
end;

procedure TX64Backend.LoadExternalInputs;
var
  Objects: TELFRelocatableArray;
  InputPaths, Directories: TLibraryStringArray;
  SectionLabels, SectionStarts, SymbolLabels: array of LongInt;
  SectionKinds: array of TLabelSection;
  ObjectIndex, I, J, N, L: LongInt;
  Obj: TELFRelocatable;
  Sec: TELFInputSection;
  Sym: TELFInputSymbol;
  Rel: TELFInputRelocation;
  Buffer: TByteBuffer;
  Alignment, Remaining: LongInt;
  Target: TTargetDescriptor;
  Request, LibraryFile, MultiArch: string;
  Selected: array of Boolean;
  Needed, Defined: TStringList;
  ArchiveStart, ArchiveFinish: LongInt;
  Changed: Boolean;

  procedure AppendInputPath(const APath: string);
  var
    K, Count: LongInt;
  begin
    for K := 0 to High(InputPaths) do
      if InputPaths[K] = APath then Exit;
    Count := Length(InputPaths);
    SetLength(InputPaths, Count + 1);
    InputPaths[Count] := APath;
  end;

  procedure AddDefinition(const AName: string; ALabel: LongInt;
    ASymbolType: Byte; AWeak: Boolean);
  var
    K, DefinitionCount: LongInt;
  begin
    if AName = '' then Exit;
    if (FindNamedLabel(FFunctions, AName) >= 0) or
       (FindNamedLabel(FGlobals, AName) >= 0) then
    begin
      if AWeak then Exit;
      raise ERCCError.Create('error: duplicate definition of ''' + AName +
        ''' in ' + Obj.SourceName);
    end;
    K := -1;
    for DefinitionCount := 0 to High(FExternalDefinitions) do
      if FExternalDefinitions[DefinitionCount].Name = AName then
      begin
        K := DefinitionCount;
        Break;
      end;
    if K >= 0 then
    begin
      if FExternalDefinitions[K].Weak and not AWeak then
      begin
        FExternalDefinitions[K].LabelID := ALabel;
        FExternalDefinitions[K].SymbolType := ASymbolType;
        FExternalDefinitions[K].Weak := False;
        Exit;
      end;
      if AWeak then Exit;
      raise ERCCError.Create('error: duplicate external definition of ''' +
        AName + ''' in ' + Obj.SourceName);
    end;
    DefinitionCount := Length(FExternalDefinitions);
    SetLength(FExternalDefinitions, DefinitionCount + 1);
    FExternalDefinitions[DefinitionCount].Name := AName;
    FExternalDefinitions[DefinitionCount].LabelID := ALabel;
    FExternalDefinitions[DefinitionCount].SymbolType := ASymbolType;
    FExternalDefinitions[DefinitionCount].Weak := AWeak;
  end;

  function IsBuiltInDefinition(const AName: string): Boolean;
  var
    K: LongInt;
  begin
    if (FindNamedLabel(FFunctions, AName) >= 0) or
       (FindNamedLabel(FGlobals, AName) >= 0) then Exit(True);
    for K := 0 to High(FRuntime) do
      if FRuntime[K].Name = AName then Exit(True);
    Result := False;
  end;

  procedure AddNeededSymbol(const AName: string);
  begin
    if (AName = '') or IsBuiltInDefinition(AName) or
       (Defined.IndexOf(AName) >= 0) then Exit;
    Needed.Add(AName);
  end;

  procedure ScanExpression(E: TExpr); forward;

  procedure ScanStatement(S: TStmt);
  var
    K: LongInt;
  begin
    if S = nil then Exit;
    ScanExpression(S.Expr);
    ScanExpression(S.Expr2);
    ScanStatement(S.InitStmt);
    ScanStatement(S.Body);
    ScanStatement(S.ElseBody);
    for K := 0 to High(S.Children) do ScanStatement(S.Children[K]);
    for K := 0 to High(S.AsmOutputs) do
      ScanExpression(S.AsmOutputs[K].Expr);
    for K := 0 to High(S.AsmInputs) do
      ScanExpression(S.AsmInputs[K].Expr);
  end;

  procedure ScanExpression(E: TExpr);
  var
    K: LongInt;
    GlobalDecl: TGlobal;
  begin
    if E = nil then Exit;
    if (E.Kind = ekCall) and (E.Text <> '') then
      AddNeededSymbol(E.Text)
    else if (E.Kind = ekVariable) and E.IsFunctionDesignator then
      AddNeededSymbol(E.Text)
    else if E.Kind = ekVariable then
    begin
      GlobalDecl := FProgram.FindGlobal(E.Text);
      if (GlobalDecl <> nil) and GlobalDecl.IsExtern then
        AddNeededSymbol(E.Text);
    end;
    ScanExpression(E.Left);
    ScanExpression(E.Right);
    ScanExpression(E.Third);
    for K := 0 to High(E.Args) do ScanExpression(E.Args[K]);
  end;

  procedure RecordObjectDefinitions(AObject: TELFRelocatable);
  var
    K, NeededIndex: LongInt;
    ObjectSymbol: TELFInputSymbol;
  begin
    for K := 0 to High(AObject.Symbols) do
    begin
      ObjectSymbol := AObject.Symbols[K];
      if not ObjectSymbol.IsDefined or ObjectSymbol.IsAbsolute or
         not (ObjectSymbol.Binding in [ELF_STB_GLOBAL, ELF_STB_WEAK]) or
         (ObjectSymbol.Name = '') then Continue;
      Defined.Add(ObjectSymbol.Name);
      NeededIndex := Needed.IndexOf(ObjectSymbol.Name);
      if NeededIndex >= 0 then Needed.Delete(NeededIndex);
    end;
  end;

  procedure RecordObjectReferences(AObject: TELFRelocatable);
  var
    K: LongInt;
    ObjectSymbol: TELFInputSymbol;
  begin
    for K := 0 to High(AObject.Symbols) do
    begin
      ObjectSymbol := AObject.Symbols[K];
      if ObjectSymbol.IsDefined or (ObjectSymbol.Binding = ELF_STB_WEAK) then
        Continue;
      AddNeededSymbol(ObjectSymbol.Name);
    end;
  end;

  function DefinesNeededSymbol(AObject: TELFRelocatable): Boolean;
  var
    K: LongInt;
    ObjectSymbol: TELFInputSymbol;
  begin
    for K := 0 to High(AObject.Symbols) do
    begin
      ObjectSymbol := AObject.Symbols[K];
      if ObjectSymbol.IsDefined and not ObjectSymbol.IsAbsolute and
         (ObjectSymbol.Binding in [ELF_STB_GLOBAL, ELF_STB_WEAK]) and
         (Needed.IndexOf(ObjectSymbol.Name) >= 0) then Exit(True);
    end;
    Result := False;
  end;

  procedure SelectArchiveMembers;
  var
    K, FunctionIndex, GlobalIndex: LongInt;
  begin
    SetLength(Selected, Length(Objects));
    Needed := TStringList.Create;
    Defined := TStringList.Create;
    Needed.Sorted := True;
    Needed.Duplicates := dupIgnore;
    Defined.Sorted := True;
    Defined.Duplicates := dupIgnore;
    try


      for K := 0 to High(Objects) do
        if Objects[K].ArchiveName = '' then
        begin
          Selected[K] := True;
          RecordObjectDefinitions(Objects[K]);
        end;

      for FunctionIndex := 0 to High(FProgram.Functions) do
        if not FProgram.Functions[FunctionIndex].IsPrototype then
          ScanStatement(FProgram.Functions[FunctionIndex].Body);
      for GlobalIndex := 0 to High(FProgram.Globals) do
        ScanExpression(FProgram.Globals[GlobalIndex].Initializer);
      for K := 0 to High(Objects) do
        if Selected[K] then RecordObjectReferences(Objects[K]);
      if Defined.IndexOf('main') < 0 then AddNeededSymbol('main');

      ArchiveStart := 0;
      while ArchiveStart <= High(Objects) do
      begin
        if Objects[ArchiveStart].ArchiveName = '' then
        begin
          Inc(ArchiveStart);
          Continue;
        end;
        ArchiveFinish := ArchiveStart;
        while (ArchiveFinish < High(Objects)) and
          (Objects[ArchiveFinish + 1].ArchiveName =
           Objects[ArchiveStart].ArchiveName) do Inc(ArchiveFinish);
        repeat
          Changed := False;
          for K := ArchiveStart to ArchiveFinish do
            if not Selected[K] and DefinesNeededSymbol(Objects[K]) then
            begin
              Selected[K] := True;
              RecordObjectDefinitions(Objects[K]);
              RecordObjectReferences(Objects[K]);
              Changed := True;
            end;
        until not Changed;
        ArchiveStart := ArchiveFinish + 1;
      end;
    finally
      Defined.Free;
      Needed.Free;
      Defined := nil;
      Needed := nil;
    end;
  end;

begin
  SetLength(InputPaths, 0);
  for I := 0 to High(FOptions.ObjectFiles) do
    AppendInputPath(FOptions.ObjectFiles[I]);
  Target := GetTargetOrRaise(FOptions.TargetTriple);
  MultiArch := TargetMultiArchName(Target);
  BuildLibrarySearchDirectories(FOptions.LibraryPaths, FOptions.Sysroot,
    MultiArch, Target.Architecture = archX86_64, Directories);
  for I := 0 to High(FOptions.Libraries) do
  begin
    Request := FOptions.Libraries[I];
    LibraryFile := '';
    if (Length(Request) > 1) and (Request[1] = '@') then
    begin
      LibraryFile := ExpandFileName(Copy(Request, 2, MaxInt));
      if FOptions.StaticLink and
         (LowerCase(ExtractFileExt(LibraryFile)) <> '.a') then
        raise ERCCError.Create('error: -static library input must be an ar archive: ' +
          LibraryFile);
    end
    else if FOptions.StaticLink then
    begin
      if not FindStaticLibraryFile(Directories, Request, LibraryFile) then
        raise ERCCError.Create('error: cannot find static library -l' + Request);
    end
    else
      FindLibraryFile(Directories, Request, LibraryFile);
    if (LibraryFile <> '') and
       (LowerCase(ExtractFileExt(LibraryFile)) = '.a') then
      AppendInputPath(LibraryFile);
  end;
  if Length(InputPaths) = 0 then Exit;
  ReadRelocatableInputs(InputPaths, Target.ELFMachine, Objects);
  try
    SelectArchiveMembers;
    for ObjectIndex := 0 to High(Objects) do
    begin
      if not Selected[ObjectIndex] then Continue;
      Obj := Objects[ObjectIndex];
      SetLength(SectionLabels, Length(Obj.Sections));
      SetLength(SectionStarts, Length(Obj.Sections));
      SetLength(SectionKinds, Length(Obj.Sections));
      for I := 0 to High(SectionLabels) do
      begin
        SectionLabels[I] := -1;
        SectionStarts[I] := -1;
        SectionKinds[I] := lsUnbound;
      end;

      for I := 1 to High(Obj.Sections) do
      begin
        Sec := Obj.Sections[I];
        if not Sec.IsAllocated then Continue;
        if Sec.Alignment > QWord(High(LongInt)) then
          raise ERCCError.Create('error: excessive section alignment in ' +
            Obj.SourceName + ': ' + Sec.Name);
        Alignment := LongInt(Sec.Alignment);
        if Alignment < 1 then Alignment := 1;
        if Sec.IsExecutable then
        begin
          Buffer := FText;
          SectionKinds[I] := lsText;
        end
        else
        begin
          Buffer := FData;
          SectionKinds[I] := lsData;
        end;
        Buffer.PadTo(Alignment);
        SectionStarts[I] := Buffer.Size;
        L := NewLabel;
        if SectionKinds[I] = lsText then BindTextLabel(L)
        else BindDataLabel(L);
        SectionLabels[I] := L;
        Buffer.Append(Sec.Data);
        if Sec.MemorySize > QWord(High(LongInt)) then
          raise ERCCError.Create('error: external section is too large in ' +
            Obj.SourceName + ': ' + Sec.Name);
        Remaining := LongInt(Sec.MemorySize) - Sec.Data.Size;
        if Remaining < 0 then
          raise ERCCError.Create('error: external section size mismatch in ' +
            Obj.SourceName + ': ' + Sec.Name);
        for J := 1 to Remaining do Buffer.Add8(0);
      end;

      SetLength(SymbolLabels, Length(Obj.Symbols));
      for I := 0 to High(SymbolLabels) do SymbolLabels[I] := -1;
      for I := 0 to High(Obj.Symbols) do
      begin
        Sym := Obj.Symbols[I];
        if not Sym.IsDefined or Sym.IsAbsolute then Continue;
        if Sym.IsCommon then
        begin
          if Sym.Value > QWord(High(LongInt)) then
            raise ERCCError.Create('error: excessive common-symbol alignment in ' +
              Obj.SourceName);
          Alignment := LongInt(Sym.Value);
          if Alignment < 1 then Alignment := 1;
          FData.PadTo(Alignment);
          L := NewLabel;
          BindDataLabel(L);
          if Sym.Size > QWord(High(LongInt) - FData.Size) then
            raise ERCCError.Create('error: common symbol is too large in ' +
              Obj.SourceName);
          for J := 1 to LongInt(Sym.Size) do FData.Add8(0);
          SymbolLabels[I] := L;
        end
        else
        begin
          if (Sym.SectionIndex > High(SectionLabels)) or
             (SectionLabels[Sym.SectionIndex] < 0) then Continue;
          if Sym.Value > Obj.Sections[Sym.SectionIndex].MemorySize then
            raise ERCCError.Create('error: symbol offset outside section in ' +
              Obj.SourceName + ': ' + Sym.Name);
          L := NewLabel;
          FLabels[L].Section := SectionKinds[Sym.SectionIndex];
          FLabels[L].Offset := SectionStarts[Sym.SectionIndex] +
            LongInt(Sym.Value);
          SymbolLabels[I] := L;
        end;
        if (Sym.Binding = ELF_STB_GLOBAL) or
           (Sym.Binding = ELF_STB_WEAK) then
          AddDefinition(Sym.Name, SymbolLabels[I], Sym.SymbolType,
            Sym.Binding = ELF_STB_WEAK);
      end;

      for I := 0 to High(Obj.Relocations) do
      begin
        Rel := Obj.Relocations[I];
        if (Rel.SectionIndex > LongWord(High(SectionStarts))) or
           (SectionStarts[Rel.SectionIndex] < 0) then Continue;
        Sym := Obj.Symbols[Rel.SymbolIndex];
        N := Length(FExternalRelocations);
        SetLength(FExternalRelocations, N + 1);
        FExternalRelocations[N].PatchSection := SectionKinds[Rel.SectionIndex];
        FExternalRelocations[N].PatchOffset :=
          SectionStarts[Rel.SectionIndex] + LongInt(Rel.Offset);
        FExternalRelocations[N].TargetLabel := SymbolLabels[Rel.SymbolIndex];
        FExternalRelocations[N].TargetName := Sym.Name;
        FExternalRelocations[N].TargetSymbolType := Sym.SymbolType;
        FExternalRelocations[N].TargetWeak := Sym.Binding = ELF_STB_WEAK;
        FExternalRelocations[N].TargetAbsolute := Sym.IsAbsolute;
        FExternalRelocations[N].AbsoluteValue := Sym.Value;
        FExternalRelocations[N].RelocationType := Rel.RelocationType;
        FExternalRelocations[N].Addend := Rel.Addend;
        FExternalRelocations[N].SourceName := Obj.SourceName;
        if (FExternalRelocations[N].TargetLabel < 0) and
           Sym.IsDefined and not Sym.IsAbsolute then
          raise ERCCError.Create('error: relocation targets a non-allocated section in ' +
            Obj.SourceName + ': ' + Sym.Name);
      end;
    end;
  finally
    FreeRelocatableInputs(Objects);
  end;
end;

procedure TX64Backend.PrepareExternalRelocations;
var
  I, L: LongInt;
  IsGOT, IsFunction: Boolean;
begin
  for I := 0 to High(FExternalRelocations) do
  begin
    if FExternalRelocations[I].RelocationType = R_X86_64_NONE then Continue;
    IsGOT := FExternalRelocations[I].RelocationType in
      [R_X86_64_GOTPCREL, R_X86_64_GOTPCRELX,
       R_X86_64_REX_GOTPCRELX];
    if FExternalRelocations[I].TargetAbsolute then Continue;
    L := FExternalRelocations[I].TargetLabel;
    if L < 0 then
      L := FindLinkDefinition(FExternalRelocations[I].TargetName,
        FExternalRelocations[I].TargetSymbolType);
    if L >= 0 then
    begin
      if IsGOT then L := EnsureLocalGOTEntry(L);
      FExternalRelocations[I].TargetLabel := L;
      Continue;
    end;
    if FExternalRelocations[I].TargetWeak then
    begin
      FExternalRelocations[I].TargetAbsolute := True;
      FExternalRelocations[I].AbsoluteValue := 0;
      Continue;
    end;
    if FOptions.Freestanding or FOptions.StaticLink then
      raise ERCCError.Create('error: undefined external symbol ''' +
        FExternalRelocations[I].TargetName + ''' in ' +
        FExternalRelocations[I].SourceName);
    IsFunction :=
      (FExternalRelocations[I].TargetSymbolType = ELF_STT_FUNC) or
      (FExternalRelocations[I].RelocationType = R_X86_64_PLT32);
    if IsGOT then
    begin
      if IsFunction then
        L := EnsureHostedFunctionImport(FExternalRelocations[I].TargetName)
      else
        L := EnsureHostedObjectImport(FExternalRelocations[I].TargetName);
    end
    else if IsFunction then
      L := EnsureExternalFunctionThunk(FExternalRelocations[I].TargetName)
    else
      raise ERCCError.Create('error: dynamic object symbol ''' +
        FExternalRelocations[I].TargetName + ''' in ' +
        FExternalRelocations[I].SourceName +
        ' requires a GOT-relative relocation');
    FExternalRelocations[I].TargetLabel := L;
  end;
end;

procedure TX64Backend.ResolveExternalRelocations(ATextVA, ADataVA: QWord);
var
  I: LongInt;
  Rel: TExternalRelocation;
  Buffer: TByteBuffer;
  PatchVA, TargetVA: QWord;
  Value: Int64;

  function LabelAddress(ALabel: LongInt): QWord;
  begin
    if (ALabel < 0) or (ALabel > High(FLabels)) or
       (FLabels[ALabel].Section = lsUnbound) then
      raise ERCCError.Create('internal error: unresolved external relocation label');
    if FLabels[ALabel].Section = lsText then
      Result := ATextVA + QWord(FLabels[ALabel].Offset)
    else
      Result := ADataVA + QWord(FLabels[ALabel].Offset);
  end;

  procedure RequireSignedRange(AValue, AMinimum, AMaximum: Int64;
    const AKind: string);
  begin
    if (AValue < AMinimum) or (AValue > AMaximum) then
      raise ERCCError.Create('error: ' + AKind + ' relocation overflow in ' +
        Rel.SourceName);
  end;

begin
  for I := 0 to High(FExternalRelocations) do
  begin
    Rel := FExternalRelocations[I];
    if Rel.RelocationType = R_X86_64_NONE then Continue;
    if Rel.PatchSection = lsText then
    begin
      Buffer := FText;
      PatchVA := ATextVA + QWord(Rel.PatchOffset);
    end
    else
    begin
      Buffer := FData;
      PatchVA := ADataVA + QWord(Rel.PatchOffset);
    end;
    if Rel.TargetAbsolute then TargetVA := Rel.AbsoluteValue
    else TargetVA := LabelAddress(Rel.TargetLabel);
    case Rel.RelocationType of
      R_X86_64_64:
        Buffer.Patch64(Rel.PatchOffset,
          QWord(Int64(TargetVA) + Rel.Addend));
      R_X86_64_PC32, R_X86_64_PLT32, R_X86_64_GOTPCREL,
      R_X86_64_GOTPCRELX, R_X86_64_REX_GOTPCRELX:
        begin
          Value := Int64(TargetVA) + Rel.Addend - Int64(PatchVA);
          RequireSignedRange(Value, Low(LongInt), High(LongInt), '32-bit PC-relative');
          Buffer.Patch32(Rel.PatchOffset, LongInt(Value));
        end;
      R_X86_64_32:
        begin
          Value := Int64(TargetVA) + Rel.Addend;
          RequireSignedRange(Value, 0, High(LongWord), 'unsigned 32-bit');
          Buffer.Patch32(Rel.PatchOffset, LongInt(LongWord(Value)));
        end;
      R_X86_64_32S:
        begin
          Value := Int64(TargetVA) + Rel.Addend;
          RequireSignedRange(Value, Low(LongInt), High(LongInt), 'signed 32-bit');
          Buffer.Patch32(Rel.PatchOffset, LongInt(Value));
        end;
      R_X86_64_16:
        begin
          Value := Int64(TargetVA) + Rel.Addend;
          RequireSignedRange(Value, 0, High(Word), 'unsigned 16-bit');
          Buffer.Patch16(Rel.PatchOffset, Word(Value));
        end;
      R_X86_64_PC16:
        begin
          Value := Int64(TargetVA) + Rel.Addend - Int64(PatchVA);
          RequireSignedRange(Value, Low(SmallInt), High(SmallInt), '16-bit PC-relative');
          Buffer.Patch16(Rel.PatchOffset, Word(SmallInt(Value)));
        end;
      R_X86_64_8:
        begin
          Value := Int64(TargetVA) + Rel.Addend;
          RequireSignedRange(Value, 0, High(Byte), 'unsigned 8-bit');
          Buffer.Patch8(Rel.PatchOffset, Byte(Value));
        end;
      R_X86_64_PC8:
        begin
          Value := Int64(TargetVA) + Rel.Addend - Int64(PatchVA);
          RequireSignedRange(Value, Low(ShortInt), High(ShortInt), '8-bit PC-relative');
          Buffer.Patch8(Rel.PatchOffset, Byte(ShortInt(Value)));
        end;
      R_X86_64_PC64:
        Buffer.Patch64(Rel.PatchOffset,
          QWord(Int64(TargetVA) + Rel.Addend - Int64(PatchVA)));
    else
      raise ERCCError.Create('error: unsupported x86-64 relocation type ' +
        IntToStr(Rel.RelocationType) + ' in ' + Rel.SourceName);
    end;
    Inc(FStats.FixupsResolved);
  end;
end;

function TX64Backend.EnsureHostedFunctionImport(const AName: string): LongInt;
var
  I, N, L: LongInt;
begin
  I := FindImport(AName);
  if I >= 0 then
  begin
    if FImports[I].Kind <> dikFunction then
      raise ERCCError.Create('internal error: hosted symbol kind mismatch for ''' +
        AName + '''');
    Exit(FImports[I].GOTLabel);
  end;

  L := NewLabel;
  BindDataLabel(L);
  N := Length(FImports);
  SetLength(FImports, N + 1);
  FImports[N].Name := AName;
  FImports[N].GOTOffset := QWord(FData.Size);
  FImports[N].GOTLabel := L;
  FImports[N].Kind := dikFunction;
  FData.Add64(0);
  Result := L;
end;

function TX64Backend.EnsureExternalImport(const AName: string;
  const APos: TSourcePos): LongInt;
var
  I: LongInt;
  Declared: Boolean;
begin
  if FOptions.EmitMode = emObject then
  begin
    Declared := False;
    for I := 0 to High(FProgram.Functions) do
      if FProgram.Functions[I].Name = AName then
      begin
        Declared := True;
        Break;
      end;
    if not Declared then
    begin
      RaiseCompileError(APos, 'call to undeclared function ''' + AName + '''');
      Exit(-1);
    end;
    Exit(EnsureObjectUndefined(AName, ELF_STT_FUNC));
  end;
  I := FindImport(AName);
  if I >= 0 then
  begin
    Result := FImports[I].GOTLabel;
    Exit;
  end;

  if FOptions.Freestanding or FOptions.StaticLink then
  begin
    if FOptions.StaticLink then
      RaiseCompileError(APos, 'undefined function ''' + AName +
        ''' in static link')
    else
      RaiseCompileError(APos, 'undefined function ''' + AName +
        ''' in freestanding mode');
    Result := -1;
    Exit;
  end;

  Declared := False;
  for I := 0 to High(FProgram.Functions) do
    if FProgram.Functions[I].Name = AName then
    begin
      Declared := True;
      Break;
    end;
  if not Declared then
  begin
    RaiseCompileError(APos, 'call to undeclared function ''' + AName + '''');
    Result := -1;
    Exit;
  end;

  Result := EnsureHostedFunctionImport(AName);
end;

function TX64Backend.EnsureExternalObject(const AName: string;
  const APos: TSourcePos): LongInt;
var
  I, N, L: LongInt;
  GlobalDecl: TGlobal;
begin
  L := FindExternalDefinition(AName, ELF_STT_OBJECT);
  if L >= 0 then Exit(L);
  if FOptions.EmitMode = emObject then
    Exit(EnsureObjectUndefined(AName, ELF_STT_OBJECT));
  I := FindImport(AName);
  if I >= 0 then
  begin
    if FImports[I].Kind <> dikObject then
      RaiseCompileError(APos, 'symbol kind mismatch for ''' + AName + '''');
    Exit(FImports[I].GOTLabel);
  end;
  if FOptions.Freestanding or FOptions.StaticLink then
  begin
    if FOptions.StaticLink then
      RaiseCompileError(APos, 'undefined object ''' + AName +
        ''' in static link')
    else
      RaiseCompileError(APos, 'undefined object ''' + AName +
        ''' in freestanding mode');
  end;
  GlobalDecl := FindGlobal(AName);
  if (GlobalDecl = nil) or not GlobalDecl.IsExtern then
    RaiseCompileError(APos, 'use of undeclared external object ''' + AName + '''');
  L := NewLabel;
  BindDataLabel(L);
  N := Length(FImports);
  SetLength(FImports, N + 1);
  FImports[N].Name := AName;
  FImports[N].GOTOffset := QWord(FData.Size);
  FImports[N].GOTLabel := L;
  FImports[N].Kind := dikObject;
  FData.Add64(0);
  Result := L;
end;

function TX64Backend.ResolveCallable(const AName: string;
  const APos: TSourcePos; out AIndirect: Boolean): LongInt;
var
  I: LongInt;
begin
  AIndirect := False;
  Result := FindNamedLabel(FFunctions, AName);
  if Result >= 0 then Exit;
  Result := FindExternalDefinition(AName, ELF_STT_FUNC);
  if Result >= 0 then Exit;
  if FOptions.EmitMode = emObject then
    Exit(EnsureObjectUndefined(AName, ELF_STT_FUNC));
  for I := 0 to High(FRuntime) do
    if FRuntime[I].Name = AName then
    begin
      FRuntimeUsed[I] := True;
      Exit(FRuntime[I].LabelID);
    end;
  AIndirect := True;
  Result := EnsureExternalImport(AName, APos);
end;

procedure TX64Backend.EmitMovRaxImm(V: Int64);
begin
  if (V >= 0) and (QWord(V) <= High(LongWord)) then
  begin
    FText.Add8($B8);
    FText.Add32(LongWord(V));
  end
  else if (V >= Low(LongInt)) and (V <= High(LongInt)) then
  begin
    FText.AddBytes([$48, $C7, $C0]);
    FText.AddI32(LongInt(V));
  end
  else
  begin
    FText.AddBytes([$48, $B8]);
    FText.Add64(QWord(V));
  end;
end;

procedure TX64Backend.EmitMovR8Imm(V: QWord);
begin
  FText.AddBytes([$49, $B8]);
  FText.Add64(V);
end;

function BitFieldMask(AWidth: LongInt): QWord;
begin
  if AWidth <= 0 then Exit(0);
  if AWidth >= 64 then Exit(not QWord(0));
  Result := (QWord(1) shl AWidth) - 1;
end;

procedure TX64Backend.EmitPushRax;
begin
  FText.Add8($50);
  Inc(FStackDepth, 8);
end;

procedure TX64Backend.EmitPopRcx;
begin
  FText.Add8($59);
  Dec(FStackDepth, 8);
end;

procedure TX64Backend.EmitLoadLocal(AOffset: LongInt);
begin
  FText.AddBytes([$48, $8B, $85]);
  FText.AddI32(-AOffset);
end;

procedure TX64Backend.EmitStoreLocal(AOffset: LongInt);
begin
  FText.AddBytes([$48, $89, $85]);
  FText.AddI32(-AOffset);
end;

procedure TX64Backend.EmitAddressLocal(AOffset: LongInt);
begin
  FText.AddBytes([$48, $8D, $85]);
  FText.AddI32(-AOffset);
end;

procedure TX64Backend.EmitLoadGlobal(ALabel: LongInt);
begin
  FText.AddBytes([$48, $8B, $05]);
  EmitRel32(ALabel);
end;

procedure TX64Backend.EmitStoreGlobal(ALabel: LongInt);
begin
  FText.AddBytes([$48, $89, $05]);
  EmitRel32(ALabel);
end;

procedure TX64Backend.EmitAddressGlobal(ALabel: LongInt);
begin
  FText.AddBytes([$48, $8D, $05]);
  EmitRel32(ALabel);
end;

procedure TX64Backend.EmitLoadAtRax(const AType: TCType);
var
  Size: LongInt;
begin
  if IsAggregateType(AType) or IsFunctionType(AType) then Exit;
  if IsFloatingType(AType) then
  begin
    case AType.Kind of
      ctFloat: FText.AddBytes([$F3, $0F, $10, $00]);
      ctDouble: FText.AddBytes([$F2, $0F, $10, $00]);
    else
      raise ERCCError.Create('long double scalar loads are unsupported by the x86-64 backend');
    end;
    Exit;
  end;
  Size := StorageSize(AType);
  case Size of
    1:
      if AType.IsUnsigned or (AType.Kind = ctBool) then
        FText.AddBytes([$0F, $B6, $00])
      else
        FText.AddBytes([$48, $0F, $BE, $00]);
    2:
      if AType.IsUnsigned then
        FText.AddBytes([$0F, $B7, $00])
      else
        FText.AddBytes([$48, $0F, $BF, $00]);
    4:
      if AType.IsUnsigned then FText.AddBytes([$8B, $00])
      else FText.AddBytes([$48, $63, $00]);
    8: FText.AddBytes([$48, $8B, $00]);
  else
    raise ERCCError.Create('internal error: unsupported scalar load width ' +
      IntToStr(Size));
  end;
end;

procedure TX64Backend.EmitStoreRaxAtRcx(const AType: TCType);
var
  Size: LongInt;
begin
  if IsFloatingType(AType) then
  begin
    case AType.Kind of
      ctFloat: FText.AddBytes([$F3, $0F, $11, $01]);
      ctDouble: FText.AddBytes([$F2, $0F, $11, $01]);
    else
      raise ERCCError.Create('long double scalar stores are unsupported by the x86-64 backend');
    end;
    Exit;
  end;
  Size := StorageSize(AType);
  case Size of
    1: FText.AddBytes([$88, $01]);
    2: FText.AddBytes([$66, $89, $01]);
    4: FText.AddBytes([$89, $01]);
    8: FText.AddBytes([$48, $89, $01]);
  else
    raise ERCCError.Create('internal error: unsupported scalar store width ' +
      IntToStr(Size));
  end;
end;

procedure TX64Backend.EmitAddRaxImmediate(AValue: LongInt);
begin
  if AValue = 0 then Exit;
  if (AValue >= -128) and (AValue <= 127) then
    FText.AddBytes([$48, $83, $C0, Byte(LongWord(AValue) and $FF)])
  else
  begin
    FText.AddBytes([$48, $05]);
    FText.AddI32(AValue);
  end;
end;

procedure TX64Backend.EmitScaleRax(AFactor: LongInt);
begin
  if AFactor <= 1 then Exit;
  FText.AddBytes([$48, $69, $C0]);
  FText.AddI32(AFactor);
end;

procedure TX64Backend.EmitLeaRsiData(ALabel: LongInt);
begin
  FText.AddBytes([$48, $8D, $35]);
  EmitRel32(ALabel);
end;

procedure TX64Backend.EmitNormalizeBool;
begin
  FText.AddBytes([$48, $85, $C0]);
  FText.AddBytes([$0F, $95, $C0]);
  FText.AddBytes([$48, $0F, $B6, $C0]);
end;

procedure TX64Backend.EmitNormalizeInteger(const AType: TCType);
begin
  if IsPointerType(AType) or not IsIntegerType(AType) then Exit;
  if AType.Kind = ctBool then
  begin
    EmitNormalizeBool;
    Exit;
  end;
  case StorageSize(AType) of
    1:
      if AType.IsUnsigned then FText.AddBytes([$0F, $B6, $C0])
      else FText.AddBytes([$48, $0F, $BE, $C0]);
    2:
      if AType.IsUnsigned then FText.AddBytes([$0F, $B7, $C0])
      else FText.AddBytes([$48, $0F, $BF, $C0]);
    4:
      if AType.IsUnsigned then FText.AddBytes([$89, $C0])
      else FText.AddBytes([$48, $63, $C0]);
    8: ;
  else
    raise ERCCError.Create('internal error: unsupported integer width');
  end;
end;

procedure TX64Backend.EmitNormalizeBitFieldResult(const AType: TCType;
  ABitWidth: LongInt);
var
  Shift: LongInt;
begin
  if AType.Kind = ctBool then
  begin
    EmitNormalizeBool;
    Exit;
  end;
  if AType.IsUnsigned or (ABitWidth >= 64) then Exit;
  Shift := 64 - ABitWidth;
  if Shift > 0 then
  begin
    FText.AddBytes([$48, $C1, $E0, Byte(Shift)]);
    FText.AddBytes([$48, $C1, $F8, Byte(Shift)]);
  end;
end;

procedure TX64Backend.EmitLoadBitField(const AType: TCType;
  ABitOffset, ABitWidth: LongInt);
var
  RawType: TCType;
begin
  RawType := AType;
  RawType.IsUnsigned := True;
  EmitLoadAtRax(RawType);
  if ABitOffset > 0 then
    FText.AddBytes([$48, $C1, $E8, Byte(ABitOffset)]);
  EmitMovR8Imm(BitFieldMask(ABitWidth));
  FText.AddBytes([$4C, $21, $C0]);
  EmitNormalizeBitFieldResult(AType, ABitWidth);
end;

procedure TX64Backend.EmitStoreBitFieldAtRcx(const AType: TCType;
  ABitOffset, ABitWidth: LongInt);
var
  RawType: TCType;
  ValueMask, PositionedMask: QWord;
begin
  ValueMask := BitFieldMask(ABitWidth);
  PositionedMask := ValueMask shl ABitOffset;
  FText.AddBytes([$48, $89, $C2]);
  EmitMovR8Imm(ValueMask);
  FText.AddBytes([$4C, $21, $C2]);
  if ABitOffset > 0 then
    FText.AddBytes([$48, $C1, $E2, Byte(ABitOffset)]);

  RawType := AType;
  RawType.IsUnsigned := True;
  FText.AddBytes([$48, $89, $C8]);
  EmitLoadAtRax(RawType);
  EmitMovR8Imm(not PositionedMask);
  FText.AddBytes([$4C, $21, $C0]);
  FText.AddBytes([$48, $09, $D0]);
  EmitStoreRaxAtRcx(RawType);

  FText.AddBytes([$48, $89, $D0]);
  if ABitOffset > 0 then
    FText.AddBytes([$48, $C1, $E8, Byte(ABitOffset)]);
  EmitNormalizeBitFieldResult(AType, ABitWidth);
end;

procedure TX64Backend.EmitSetCC(AOpcode: Byte);
begin
  FText.AddBytes([$0F, AOpcode, $C0]);
  FText.AddBytes([$48, $0F, $B6, $C0]);
end;

procedure TX64Backend.EmitBinaryOperation(AOp: TBinaryOp; AUnsigned: Boolean);
begin
  case AOp of
    boAdd: FText.AddBytes([$48, $01, $C8]);
    boSub: FText.AddBytes([$48, $29, $C8]);
    boMul: FText.AddBytes([$48, $0F, $AF, $C1]);
    boDiv:
      begin
        if AUnsigned then
        begin
          FText.AddBytes([$31, $D2]);
          FText.AddBytes([$48, $F7, $F1]);
        end
        else
        begin
          FText.AddBytes([$48, $99]);
          FText.AddBytes([$48, $F7, $F9]);
        end;
      end;
    boMod:
      begin
        if AUnsigned then
        begin
          FText.AddBytes([$31, $D2]);
          FText.AddBytes([$48, $F7, $F1]);
        end
        else
        begin
          FText.AddBytes([$48, $99]);
          FText.AddBytes([$48, $F7, $F9]);
        end;
        FText.AddBytes([$48, $89, $D0]);
      end;
    boShiftLeft: FText.AddBytes([$48, $D3, $E0]);
    boShiftRight:
      if AUnsigned then FText.AddBytes([$48, $D3, $E8])
      else FText.AddBytes([$48, $D3, $F8]);
    boBitAnd: FText.AddBytes([$48, $21, $C8]);
    boBitXor: FText.AddBytes([$48, $31, $C8]);
    boBitOr: FText.AddBytes([$48, $09, $C8]);
    boEqual:
      begin FText.AddBytes([$48, $39, $C8]); EmitSetCC($94); end;
    boNotEqual:
      begin FText.AddBytes([$48, $39, $C8]); EmitSetCC($95); end;
    boLess:
      begin
        FText.AddBytes([$48, $39, $C8]);
        if AUnsigned then EmitSetCC($92) else EmitSetCC($9C);
      end;
    boLessEqual:
      begin
        FText.AddBytes([$48, $39, $C8]);
        if AUnsigned then EmitSetCC($96) else EmitSetCC($9E);
      end;
    boGreater:
      begin
        FText.AddBytes([$48, $39, $C8]);
        if AUnsigned then EmitSetCC($97) else EmitSetCC($9F);
      end;
    boGreaterEqual:
      begin
        FText.AddBytes([$48, $39, $C8]);
        if AUnsigned then EmitSetCC($93) else EmitSetCC($9D);
      end;
  else
    raise ERCCError.Create('internal error: invalid eager binary operation');
  end;
end;

function IsPowerOfTwo(V: Int64; out Shift: Byte): Boolean;
var
  U: QWord;
begin
  if V <= 0 then Exit(False);
  U := QWord(V);
  Result := (U and (U - 1)) = 0;
  Shift := 0;
  if Result then
    while U > 1 do begin U := U shr 1; Inc(Shift); end;
end;

procedure TX64Backend.EmitImmediateOperation(AOp: TBinaryOp; V: Int64;
  AUnsigned: Boolean; out AHandled: Boolean);
var
  Shift: Byte;
begin
  AHandled := False;
  if (V < Low(LongInt)) or (V > High(LongInt)) then Exit;
  case AOp of
    boAdd:
      begin
        if FOptions.OptimizeSize and (V >= -128) and (V <= 127) then
          FText.AddBytes([$48, $83, $C0, Byte(LongWord(V) and $FF)])
        else
        begin
          FText.AddBytes([$48, $05]);
          FText.AddI32(LongInt(V));
        end;
        AHandled := True;
      end;
    boSub:
      begin
        if FOptions.OptimizeSize and (V >= -128) and (V <= 127) then
          FText.AddBytes([$48, $83, $E8, Byte(LongWord(V) and $FF)])
        else
        begin
          FText.AddBytes([$48, $2D]);
          FText.AddI32(LongInt(V));
        end;
        AHandled := True;
      end;
    boBitAnd:
      begin
        if FOptions.OptimizeSize and (V >= -128) and (V <= 127) then
          FText.AddBytes([$48, $83, $E0, Byte(LongWord(V) and $FF)])
        else
        begin
          FText.AddBytes([$48, $25]);
          FText.AddI32(LongInt(V));
        end;
        AHandled := True;
      end;
    boBitOr:
      begin
        if FOptions.OptimizeSize and (V >= -128) and (V <= 127) then
          FText.AddBytes([$48, $83, $C8, Byte(LongWord(V) and $FF)])
        else
        begin
          FText.AddBytes([$48, $0D]);
          FText.AddI32(LongInt(V));
        end;
        AHandled := True;
      end;
    boBitXor:
      begin
        if FOptions.OptimizeSize and (V >= -128) and (V <= 127) then
          FText.AddBytes([$48, $83, $F0, Byte(LongWord(V) and $FF)])
        else
        begin
          FText.AddBytes([$48, $35]);
          FText.AddI32(LongInt(V));
        end;
        AHandled := True;
      end;
    boMul:
      begin
        if (FOptions.OptimizationLevel >= 2) and IsPowerOfTwo(V, Shift) then
        begin
          if Shift > 0 then FText.AddBytes([$48, $C1, $E0, Shift]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 3) and (V = -1) then
        begin
          FText.AddBytes([$48, $F7, $D8]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 3) and (V = 3) then
        begin
          FText.AddBytes([$48, $8D, $04, $40]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 3) and (V = 5) then
        begin
          FText.AddBytes([$48, $8D, $04, $80]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 3) and (V = 9) then
        begin
          FText.AddBytes([$48, $8D, $04, $C0]);
          AHandled := True;
        end
        else
        begin
          FText.AddBytes([$48, $69, $C0]);
          FText.AddI32(LongInt(V));
          AHandled := True;
        end;
      end;
    boDiv:
      begin
        if (FOptions.OptimizationLevel >= 2) and AUnsigned and
           IsPowerOfTwo(V, Shift) then
        begin
          if Shift > 0 then FText.AddBytes([$48, $C1, $E8, Shift]);
          AHandled := True;
        end;
      end;
    boMod:
      begin
        if (FOptions.OptimizationLevel >= 2) and AUnsigned and
           IsPowerOfTwo(V, Shift) then
        begin
          if V = 1 then FText.AddBytes([$31, $C0])
          else if (V - 1) <= 127 then
            FText.AddBytes([$48, $83, $E0, Byte(V - 1)])
          else
          begin
            FText.AddBytes([$48, $25]);
            FText.AddI32(LongInt(V - 1));
          end;
          AHandled := True;
        end;
      end;
    boShiftLeft:
      begin FText.AddBytes([$48, $C1, $E0, Byte(V and 63)]); AHandled := True; end;
    boShiftRight:
      begin
        if AUnsigned then FText.AddBytes([$48, $C1, $E8, Byte(V and 63)])
        else FText.AddBytes([$48, $C1, $F8, Byte(V and 63)]);
        AHandled := True;
      end;
    boEqual, boNotEqual, boLess, boLessEqual, boGreater, boGreaterEqual:
      begin
        FText.AddBytes([$48, $3D]);
        FText.AddI32(LongInt(V));
        case AOp of
          boEqual: EmitSetCC($94);
          boNotEqual: EmitSetCC($95);
          boLess:
            if AUnsigned then EmitSetCC($92) else EmitSetCC($9C);
          boLessEqual:
            if AUnsigned then EmitSetCC($96) else EmitSetCC($9E);
          boGreater:
            if AUnsigned then EmitSetCC($97) else EmitSetCC($9F);
          boGreaterEqual:
            if AUnsigned then EmitSetCC($93) else EmitSetCC($9D);
        end;
        AHandled := True;
      end;
  end;
end;

procedure TX64Backend.EmitMoveRaxToArg(AIndex: LongInt);
begin
  case AIndex of
    0: FText.AddBytes([$48, $89, $C7]);
    1: FText.AddBytes([$48, $89, $C6]);
    2: FText.AddBytes([$48, $89, $C2]);
    3: FText.AddBytes([$48, $89, $C1]);
    4: FText.AddBytes([$49, $89, $C0]);
    5: FText.AddBytes([$49, $89, $C1]);
  else
    raise ERCCError.Create('internal error: unsupported argument register');
  end;
end;

procedure TX64Backend.EmitPopArg(AIndex: LongInt);
begin
  case AIndex of
    0: FText.Add8($5F);
    1: FText.Add8($5E);
    2: FText.Add8($5A);
    3: FText.Add8($59);
    4: FText.AddBytes([$41, $58]);
    5: FText.AddBytes([$41, $59]);
  else
    raise ERCCError.Create('internal error: unsupported argument register');
  end;
  Dec(FStackDepth, 8);
end;

procedure TX64Backend.EmitStoreArgToLocal(AIndex, AOffset: LongInt);
begin
  case AIndex of
    0: FText.AddBytes([$48, $89, $BD]);
    1: FText.AddBytes([$48, $89, $B5]);
    2: FText.AddBytes([$48, $89, $95]);
    3: FText.AddBytes([$48, $89, $8D]);
    4: FText.AddBytes([$4C, $89, $85]);
    5: FText.AddBytes([$4C, $89, $8D]);
  else
    raise ERCCError.Create('internal error: unsupported parameter register');
  end;
  FText.AddI32(-AOffset);
end;


procedure TX64Backend.EmitStoreXmmArgToLocal(AIndex, AOffset: LongInt;
  const AType: TCType);
var
  Prefix: Byte;
begin
  if AIndex < 0 then
    raise ERCCError.Create('internal error: invalid SSE argument register');
  if AIndex > 7 then
    raise ERCCError.Create('internal error: SSE argument register overflow');
  if AType.Kind = ctFloat then Prefix := $F3 else Prefix := $F2;
  FText.Add8(Prefix);
  FText.AddBytes([$0F, $11, Byte($85 or (AIndex shl 3))]);
  FText.AddI32(-AOffset);
end;

procedure TX64Backend.EmitLoadXmmFromStack(AIndex, AStackOffset: LongInt;
  const AType: TCType);
var
  Prefix: Byte;
begin
  if (AIndex < 0) or (AIndex > 7) then
    raise ERCCError.Create('internal error: invalid SSE argument register');
  if AType.Kind = ctFloat then Prefix := $F3 else Prefix := $F2;
  FText.Add8(Prefix);
  if (AStackOffset >= -128) and (AStackOffset <= 127) then
  begin
    FText.AddBytes([$0F, $10, Byte($44 or (AIndex shl 3)), $24,
      Byte(AStackOffset)]);
  end
  else
  begin
    FText.AddBytes([$0F, $10, Byte($84 or (AIndex shl 3)), $24]);
    FText.AddI32(AStackOffset);
  end;
end;

procedure TX64Backend.EmitPushXmm0(const AType: TCType);
var
  Prefix: Byte;
begin
  if AType.Kind = ctLongDouble then
    raise ERCCError.Create('long double code generation is unsupported by the x86-64 backend');
  if AType.Kind = ctFloat then Prefix := $F3 else Prefix := $F2;
  FText.AddBytes([$48, $83, $EC, $08]);
  FText.Add8(Prefix);
  FText.AddBytes([$0F, $11, $04, $24]);
  Inc(FStackDepth, 8);
end;

procedure TX64Backend.EmitPopXmm1(const AType: TCType);
var
  Prefix: Byte;
begin
  if AType.Kind = ctFloat then Prefix := $F3 else Prefix := $F2;
  FText.Add8(Prefix);
  FText.AddBytes([$0F, $10, $0C, $24]);
  FText.AddBytes([$48, $83, $C4, $08]);
  Dec(FStackDepth, 8);
end;

procedure TX64Backend.EmitFloatToBool(const AType: TCType);
begin
  if AType.Kind = ctFloat then
  begin
    FText.AddBytes([$0F, $57, $C9]);
    FText.AddBytes([$0F, $2E, $C1]);
  end
  else
  begin
    FText.AddBytes([$66, $0F, $57, $C9]);
    FText.AddBytes([$66, $0F, $2E, $C1]);
  end;
  FText.AddBytes([$0F, $95, $C0]);
  FText.AddBytes([$0F, $9A, $C2]);
  FText.AddBytes([$08, $D0, $0F, $B6, $C0]);
end;

procedure TX64Backend.EmitFloatingBinary(AOp: TBinaryOp;
  const AType: TCType);
var
  Prefix, Opcode, SetOpcode: Byte;
  Comparison, OrderedMask: Boolean;
begin
  if AType.Kind = ctLongDouble then
    raise ERCCError.Create('long double code generation is unsupported by the x86-64 backend');
  Prefix := $F2;
  if AType.Kind = ctFloat then Prefix := $F3;
  Comparison := AOp in [boLess, boLessEqual, boGreater, boGreaterEqual,
    boEqual, boNotEqual];
  if Comparison then
  begin
    if AType.Kind = ctDouble then FText.Add8($66);
    FText.AddBytes([$0F, $2E, $C8]);
    OrderedMask := False;
    case AOp of
      boEqual: begin SetOpcode := $94; OrderedMask := True; end;
      boNotEqual: SetOpcode := $95;
      boLess: begin SetOpcode := $92; OrderedMask := True; end;
      boLessEqual: begin SetOpcode := $96; OrderedMask := True; end;
      boGreater: SetOpcode := $97;
      boGreaterEqual: SetOpcode := $93;
    else
      SetOpcode := $95;
    end;
    FText.AddBytes([$0F, SetOpcode, $C0]);
    if OrderedMask then
    begin
      FText.AddBytes([$0F, $9B, $C2]);
      FText.AddBytes([$20, $D0]);
    end
    else if AOp = boNotEqual then
    begin
      FText.AddBytes([$0F, $9A, $C2]);
      FText.AddBytes([$08, $D0]);
    end;
    FText.AddBytes([$0F, $B6, $C0]);
    Exit;
  end;

  case AOp of
    boAdd: Opcode := $58;
    boSub: Opcode := $5C;
    boMul: Opcode := $59;
    boDiv: Opcode := $5E;
  else
    raise ERCCError.Create('this floating operator is unsupported by the x86-64 backend');
  end;
  FText.Add8(Prefix);
  FText.AddBytes([$0F, Opcode, $C8]);
  FText.Add8(Prefix);
  FText.AddBytes([$0F, $10, $C1]);
end;

procedure TX64Backend.EmitConvertIntegerToFloat(const AType: TCType);
begin
  if AType.Kind = ctFloat then FText.Add8($F3) else FText.Add8($F2);
  FText.AddBytes([$48, $0F, $2A, $C0]);
end;

procedure TX64Backend.EmitConvertFloatToInteger(const AType: TCType);
begin
  if AType.Kind = ctFloat then FText.Add8($F3) else FText.Add8($F2);
  FText.AddBytes([$48, $0F, $2C, $C0]);
end;

procedure TX64Backend.EmitConvertFloatWidth(const AFromType, AToType: TCType);
begin
  if AFromType.Kind = AToType.Kind then Exit;
  if (AFromType.Kind = ctFloat) and (AToType.Kind = ctDouble) then
    FText.AddBytes([$F3, $0F, $5A, $C0])
  else if (AFromType.Kind = ctDouble) and (AToType.Kind = ctFloat) then
    FText.AddBytes([$F2, $0F, $5A, $C0])
  else if (AFromType.Kind = ctLongDouble) or (AToType.Kind = ctLongDouble) then
    raise ERCCError.Create('long double conversion is unsupported by the x86-64 backend');
end;

function TX64Backend.AddStringLiteral(const S: string): LongInt;
var
  I, N: LongInt;
begin
  for I := 0 to High(FStrings) do
    if FStrings[I].Value = S then Exit(FStrings[I].LabelID);
  Result := NewLabel;
  BindDataLabel(Result);
  FData.AddStringZ(S);
  N := Length(FStrings);
  SetLength(FStrings, N + 1);
  FStrings[N].Value := S;
  FStrings[N].LabelID := Result;
end;

procedure TX64Backend.PreallocateInitializerLiterals(AExpression: TExpr);
var
  I: LongInt;
begin
  if AExpression = nil then Exit;
  if AExpression.Kind = ekString then
    AddStringLiteral(AExpression.Text);
  PreallocateInitializerLiterals(AExpression.Left);
  PreallocateInitializerLiterals(AExpression.Right);
  PreallocateInitializerLiterals(AExpression.Third);
  for I := 0 to High(AExpression.Args) do
    PreallocateInitializerLiterals(AExpression.Args[I]);
end;


function TX64Backend.AddFloatLiteral(AValue: Double;
  const AType: TCType): LongInt;
var
  Bits64: QWord;
  Bits32: LongWord;
  SingleValue: Single;
begin
  Result := NewLabel;
  if AType.Kind = ctFloat then
  begin
    FData.PadTo(4);
    BindDataLabel(Result);
    SingleValue := AValue;
    Move(SingleValue, Bits32, SizeOf(Bits32));
    FData.Add32(Bits32);
  end
  else
  begin
    if AType.Kind = ctLongDouble then
      raise ERCCError.Create('long double literal emission is unsupported by the x86-64 backend');
    FData.PadTo(8);
    BindDataLabel(Result);
    Move(AValue, Bits64, SizeOf(Bits64));
    FData.Add64(Bits64);
  end;
end;

procedure TX64Backend.EmitGlobalObject(const AType: TCType;
  AInitializer: TExpr; const APos: TSourcePos);
var
  I, J, Count, Size, StartOffset, TargetOffset, GroupOffset,
    GroupSize: LongInt;
  Value: Int64;
  PackedValue, MemberValue, Mask: QWord;
  FloatValue: Double;
  FloatBits64: QWord;
  FloatBits32: LongWord;
  SingleValue: Single;
  ElementType, MemberType: TCType;
  Member: TStructMember;
  InitializerExpr: TExpr;

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

  function IntegerInitializer(AExpr: TExpr): QWord;
  var
    ConstantValue: Int64;
  begin
    if AExpr = nil then Exit(0);
    if not EvaluateIntegerConstantExpression(AExpr, ConstantValue) then
      RaiseCompileError(AExpr.Pos,
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
  if AType.Kind = ctArray then
  begin
    ElementType := ElementTypeOf(AType);
    StartOffset := FData.Size;
    if (AInitializer <> nil) and (AInitializer.Kind = ekString) and
      (ElementType.Kind = ctChar) and (ElementType.PointerDepth = 0) then
    begin
      Count := Length(AInitializer.Text);
      if Count >= AType.ArrayLength then Count := LongInt(AType.ArrayLength) - 1;
      for I := 1 to Count do FData.Add8(Byte(Ord(AInitializer.Text[I])));
      if FData.Size - StartOffset < AType.ArrayLength then FData.Add8(0);
    end
    else if (AInitializer <> nil) and (AInitializer.Kind = ekCompoundLit) then
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

  if AType.Kind in [ctStruct, ctUnion] then
  begin
    StartOffset := FData.Size;
    if AType.StructInfo = nil then
      RaiseCompileError(APos, 'cannot allocate incomplete aggregate type');
    if AType.Kind = ctUnion then
    begin
      if Length(AType.StructInfo^.Members) > 0 then
      begin
        Member := AType.StructInfo^.Members[0];
        MemberType := PCType(Member.CType)^;
        InitializerExpr := nil;
        if (AInitializer <> nil) and (AInitializer.Kind = ekCompoundLit) and
          (Length(AInitializer.Args) > 0) then
          InitializerExpr := AInitializer.Args[0];
        if Member.IsBitField then
        begin
          Mask := BitFieldMask(Member.BitWidth);
          PackedValue := (IntegerInitializer(InitializerExpr) and Mask)
            shl Member.BitOffset;
          AddPackedInteger(PackedValue, Member.Width);
        end
        else
          EmitGlobalObject(MemberType, InitializerExpr, APos);
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
            InitializerExpr := nil;
            if (AInitializer <> nil) and
              (AInitializer.Kind = ekCompoundLit) and
              (J <= High(AInitializer.Args)) then
              InitializerExpr := AInitializer.Args[J];
            MemberValue := IntegerInitializer(InitializerExpr);
            Mask := BitFieldMask(Member.BitWidth);
            PackedValue := PackedValue or
              ((MemberValue and Mask) shl Member.BitOffset);
            Inc(J);
          end;
          TargetOffset := StartOffset + GroupOffset;
          while FData.Size < TargetOffset do FData.Add8(0);
          if FData.Size <> TargetOffset then
            RaiseCompileError(APos, 'overlapping aggregate initialization layout');
          AddPackedInteger(PackedValue, GroupSize);
          I := J;
          Continue;
        end;

        TargetOffset := StartOffset + Member.Offset;
        while FData.Size < TargetOffset do FData.Add8(0);
        if FData.Size <> TargetOffset then
          RaiseCompileError(APos, 'overlapping aggregate initialization layout');
        MemberType := PCType(Member.CType)^;
        InitializerExpr := nil;
        if (AInitializer <> nil) and (AInitializer.Kind = ekCompoundLit) and
          (I <= High(AInitializer.Args)) then
          InitializerExpr := AInitializer.Args[I];
        EmitGlobalObject(MemberType, InitializerExpr, APos);
        Inc(I);
      end;
    end;
    while FData.Size - StartOffset < Size do FData.Add8(0);
    if FData.Size - StartOffset > Size then
      RaiseCompileError(APos, 'aggregate initializer exceeds object size');
    Exit;
  end;

  Value := 0;
  FloatValue := 0.0;
  if IsFloatingType(AType) then
  begin
    if AInitializer <> nil then
    begin
      if AInitializer.Kind = ekFloat then FloatValue := AInitializer.FloatValue
      else if AInitializer.Kind = ekInteger then FloatValue := AInitializer.IntValue
      else RaiseCompileError(APos,
        'global floating initializer is not a constant expression');
    end;
    case AType.Kind of
      ctFloat:
        begin
          SingleValue := FloatValue;
          Move(SingleValue, FloatBits32, SizeOf(FloatBits32));
          FData.Add32(FloatBits32);
        end;
      ctDouble:
        begin
          Move(FloatValue, FloatBits64, SizeOf(FloatBits64));
          FData.Add64(FloatBits64);
        end;
    else
      RaiseCompileError(APos, 'long double global initialization is unsupported by the x86-64 backend');
    end;
    Exit;
  end;
  if AInitializer <> nil then
  begin
    if (AInitializer.Kind = ekString) and
       ((AType.PointerDepth > 0) or (AType.Kind = ctPointer)) then
    begin
      I := AddStringLiteral(AInitializer.Text);
      AddDataAddressFixup(I, FData.Size);
      FData.Add64(0);
      Exit;
    end;
    if not EvaluateIntegerConstantExpression(AInitializer, Value) then
      RaiseCompileError(AInitializer.Pos,
        'global initializer is not an integer constant expression');
  end;
  Value := ConvertIntegerValue(Value, AType);
  case Size of
    1: FData.Add8(Byte(QWord(Value)));
    2: FData.Add16(Word(QWord(Value)));
    4: FData.Add32(LongWord(QWord(Value)));
    8: FData.Add64(QWord(Value));
    16:
      begin
        FData.Add64(QWord(Value));
        FData.Add64(0);
      end;
  else
    AddZeros(Size);
  end;
end;

procedure TX64Backend.AllocateGlobals;
var
  I, N, L: LongInt;
  G: TGlobal;
begin
  for I := 0 to High(FProgram.Globals) do
  begin
    G := FProgram.Globals[I];
    if G.IsExtern then Continue;
    if FindNamedLabel(FGlobals, G.Name) >= 0 then
      RaiseCompileError(G.Pos, 'duplicate global ''' + G.Name + '''');
    FData.PadTo(StorageAlign(G.CType));
    L := NewLabel;
    BindDataLabel(L);
    EmitGlobalObject(G.CType, G.Initializer, G.Pos);
    N := Length(FGlobals);
    SetLength(FGlobals, N + 1);
    FGlobals[N].Name := G.Name;
    FGlobals[N].LabelID := L;
  end;
end;

procedure TX64Backend.ReserveFunctionLabels;
var
  I, N, L, Existing: LongInt;
  F: TFunction;
begin
  for I := 0 to High(FProgram.Functions) do
  begin
    F := FProgram.Functions[I];
    if F.IsPrototype then Continue;
    Existing := FindNamedLabel(FFunctions, F.Name);
    if Existing >= 0 then
      RaiseCompileError(F.Pos, 'duplicate function definition ''' + F.Name + '''');
    L := NewLabel;
    N := Length(FFunctions);
    SetLength(FFunctions, N + 1);
    FFunctions[N].Name := F.Name;
    FFunctions[N].LabelID := L;
  end;
end;

procedure TX64Backend.ReserveRuntimeLabels;
var
  I, N: LongInt;
begin
  SetLength(FRuntimeUsed, RuntimeSymbolCount);
  for I := 0 to RuntimeSymbolCount - 1 do
  begin
    N := Length(FRuntime);
    SetLength(FRuntime, N + 1);
    FRuntime[N].Name := RuntimeSymbolName(I);
    FRuntime[N].LabelID := NewLabel;
    FRuntimeUsed[N] := False;
  end;
end;

procedure TX64Backend.EmitStartup;
var
  I, MainLabel, ExitImportLabel: LongInt;
  ExplicitLibC, UseHostedExit: Boolean;
  LibraryRequest: string;
begin
  MainLabel := FindNamedLabel(FFunctions, 'main');
  if MainLabel < 0 then
    MainLabel := FindExternalDefinition('main', ELF_STT_FUNC);
  if MainLabel < 0 then
    raise ERCCError.Create('error: no main function was defined');





  ExplicitLibC := False;
  for I := 0 to High(FOptions.Libraries) do
  begin
    LibraryRequest := LowerCase(FOptions.Libraries[I]);
    if (LibraryRequest = 'c') or (Pos(':libc.so', LibraryRequest) = 1) or
       ((Length(LibraryRequest) > 1) and (LibraryRequest[1] = '@') and
        (Pos('libc.so', LowerCase(ExtractFileName(
          Copy(LibraryRequest, 2, MaxInt)))) = 1)) then
    begin
      ExplicitLibC := True;
      Break;
    end;
  end;
  UseHostedExit := (Length(FImports) > 0) and not FOptions.Freestanding and
    not FOptions.StaticLink and
    (not FOptions.NoDefaultLibraries or ExplicitLibC);
  if UseHostedExit then ExitImportLabel := EnsureHostedFunctionImport('exit')
  else ExitImportLabel := -1;

  FEntryLabel := NewLabel;
  BindTextLabel(FEntryLabel);
  FListing.Add('section .text');
  FListing.Add('global _start');
  FListing.Add('_start:');
  FText.AddBytes([$31, $ED]);
  FText.AddBytes([$48, $8B, $3C, $24]);
  FText.AddBytes([$48, $8D, $74, $24, $08]);
  FText.AddBytes([$48, $83, $E4, $F0]);
  EmitCall(MainLabel);
  FListing.Add('  call main');
  FText.AddBytes([$89, $C7]);
  FListing.Add('  mov edi, eax');
  if ExitImportLabel >= 0 then
  begin
    EmitIndirectCall(ExitImportLabel);
    FListing.Add('  call [exit@GOT]');
  end
  else
  begin
    FText.AddBytes([$B8, $3C, $00, $00, $00]);
    FText.AddBytes([$0F, $05]);
    FListing.Add('  mov eax, 60');
    FListing.Add('  syscall');
  end;
  FText.AddBytes([$0F, $0B]);
  FListing.Add('');
end;

procedure TX64Backend.EmitRuntimeRead;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'read'); BindTextLabel(L);
  FText.AddBytes([$31, $C0, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeWrite;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'write'); BindTextLabel(L);
  FText.AddBytes([$B8, $01, $00, $00, $00, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeClose;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'close'); BindTextLabel(L);
  FText.AddBytes([$B8, $03, $00, $00, $00, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeOpen;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'open'); BindTextLabel(L);
  FText.AddBytes([$B8, $02, $00, $00, $00, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeLseek;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'lseek'); BindTextLabel(L);
  FText.AddBytes([$B8, $08, $00, $00, $00, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeGetPid;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'getpid'); BindTextLabel(L);
  FText.AddBytes([$B8, $27, $00, $00, $00, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeGetPageSize;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'getpagesize'); BindTextLabel(L);
  FText.AddBytes([$B8, $00, $10, $00, $00, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeAccess;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'access'); BindTextLabel(L);
  FText.AddBytes([$B8, $15, $00, $00, $00, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeTime;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'time'); BindTextLabel(L);
  FText.AddBytes([$B8, $C9, $00, $00, $00, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeExit(const AName: string);
var
  L, ImportLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, AName); BindTextLabel(L);
  if (AName = 'exit') and not FOptions.Freestanding then
  begin

    ImportLabel := EnsureHostedFunctionImport('exit');
    FText.AddBytes([$48, $83, $EC, $08]);
    EmitIndirectCall(ImportLabel);
    FText.AddBytes([$0F, $0B]);
  end
  else
    FText.AddBytes([$B8, $3C, $00, $00, $00, $0F, $05, $0F, $0B]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeAbort;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'abort'); BindTextLabel(L);
  FText.AddBytes([$BF, $86, $00, $00, $00]);
  FText.AddBytes([$B8, $3C, $00, $00, $00, $0F, $05, $0F, $0B]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeAtexit;
var
  L, ImportLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'atexit'); BindTextLabel(L);
  if FOptions.Freestanding then
    raise ERCCError.Create(
      'error: atexit is unavailable in freestanding mode');



  ImportLabel := EnsureHostedFunctionImport('__cxa_atexit');
  FText.AddBytes([$31, $F6]);
  FText.AddBytes([$31, $D2]);
  FText.AddBytes([$48, $83, $EC, $08]);
  EmitIndirectCall(ImportLabel);
  FText.AddBytes([$48, $83, $C4, $08, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeStrlen;
var
  L, LoopLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'strlen'); BindTextLabel(L);
  LoopLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$48, $31, $C0]);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$80, $3C, $07, $00]);
  EmitJcc($84, DoneLabel);
  FText.AddBytes([$48, $FF, $C0]);
  EmitJump(LoopLabel);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimePuts;
var
  L, StrlenLabel, NewlineLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'puts'); BindTextLabel(L);
  StrlenLabel := FindNamedLabel(FRuntime, 'strlen');
  NewlineLabel := AddStringLiteral(#10);
  FText.Add8($57);
  EmitCall(StrlenLabel);
  FText.AddBytes([$48, $89, $C2]);
  FText.Add8($5E);
  FText.AddBytes([$BF, $01, $00, $00, $00]);
  FText.AddBytes([$B8, $01, $00, $00, $00]);
  FText.AddBytes([$0F, $05]);
  EmitLeaRsiData(NewlineLabel);
  FText.AddBytes([$BA, $01, $00, $00, $00]);
  FText.AddBytes([$BF, $01, $00, $00, $00]);
  FText.AddBytes([$B8, $01, $00, $00, $00]);
  FText.AddBytes([$0F, $05]);
  FText.AddBytes([$31, $C0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimePutchar;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'putchar'); BindTextLabel(L);
  FText.AddBytes([$48, $83, $EC, $08]);
  FText.AddBytes([$40, $88, $3C, $24]);
  FText.AddBytes([$48, $89, $E6]);
  FText.AddBytes([$BA, $01, $00, $00, $00]);
  FText.AddBytes([$BF, $01, $00, $00, $00]);
  FText.AddBytes([$B8, $01, $00, $00, $00]);
  FText.AddBytes([$0F, $05]);
  FText.AddBytes([$48, $83, $C4, $08, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeGetchar;
var
  L, EofLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'getchar'); BindTextLabel(L);
  EofLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$48, $83, $EC, $08]);
  FText.AddBytes([$31, $FF]);
  FText.AddBytes([$48, $89, $E6]);
  FText.AddBytes([$BA, $01, $00, $00, $00]);
  FText.AddBytes([$31, $C0, $0F, $05]);
  FText.AddBytes([$48, $83, $F8, $01]);
  EmitJcc($85, EofLabel);
  FText.AddBytes([$0F, $B6, $04, $24]);
  EmitJump(DoneLabel);
  BindTextLabel(EofLabel);
  FText.AddBytes([$B8, $FF, $FF, $FF, $FF]);
  BindTextLabel(DoneLabel);
  FText.AddBytes([$48, $83, $C4, $08, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimePrintInt;
var
  L, PositiveLabel, ConvertLabel, LoopLabel, WriteLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'print_int'); BindTextLabel(L);
  PositiveLabel := NewLabel;
  ConvertLabel := NewLabel;
  LoopLabel := NewLabel;
  WriteLabel := NewLabel;
  FText.AddBytes([$55, $48, $89, $E5, $48, $83, $EC, $30]);
  FText.AddBytes([$48, $89, $F8]);
  FText.AddBytes([$48, $8D, $75, $FF]);
  FText.AddBytes([$C6, $06, $0A]);
  FText.AddBytes([$48, $C7, $C1, $01, $00, $00, $00]);
  FText.AddBytes([$45, $31, $C0]);
  FText.AddBytes([$48, $85, $C0]);
  EmitJcc($89, PositiveLabel);
  FText.AddBytes([$48, $F7, $D8]);
  FText.AddBytes([$41, $B8, $01, $00, $00, $00]);
  BindTextLabel(PositiveLabel);
  EmitJump(ConvertLabel);
  BindTextLabel(ConvertLabel);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$48, $31, $D2]);
  FText.AddBytes([$49, $C7, $C2, $0A, $00, $00, $00]);
  FText.AddBytes([$49, $F7, $F2]);
  FText.AddBytes([$80, $C2, $30]);
  FText.AddBytes([$48, $FF, $CE]);
  FText.AddBytes([$88, $16]);
  FText.AddBytes([$48, $FF, $C1]);
  FText.AddBytes([$48, $85, $C0]);
  EmitJcc($85, LoopLabel);
  FText.AddBytes([$45, $85, $C0]);
  EmitJcc($84, WriteLabel);
  FText.AddBytes([$48, $FF, $CE]);
  FText.AddBytes([$C6, $06, $2D]);
  FText.AddBytes([$48, $FF, $C1]);
  BindTextLabel(WriteLabel);
  FText.AddBytes([$BF, $01, $00, $00, $00]);
  FText.AddBytes([$48, $89, $CA]);
  FText.AddBytes([$B8, $01, $00, $00, $00, $0F, $05]);
  FText.AddBytes([$C9, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimePrintString;
var
  L, StrlenLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, '__rcc_print_string'); BindTextLabel(L);
  StrlenLabel := FindNamedLabel(FRuntime, 'strlen');
  FText.Add8($57);
  EmitCall(StrlenLabel);
  FText.AddBytes([$48, $89, $C2]);
  FText.Add8($5E);
  FText.AddBytes([$BF, $01, $00, $00, $00]);
  FText.AddBytes([$B8, $01, $00, $00, $00, $0F, $05, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimePrintIntRaw;
var
  L, PositiveLabel, LoopLabel, WriteLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, '__rcc_print_int_raw'); BindTextLabel(L);
  PositiveLabel := NewLabel; LoopLabel := NewLabel; WriteLabel := NewLabel;
  FText.AddBytes([$55, $48, $89, $E5, $48, $83, $EC, $30]);
  FText.AddBytes([$48, $89, $F8]);
  FText.AddBytes([$48, $8D, $75, $00]);
  FText.AddBytes([$48, $31, $C9]);
  FText.AddBytes([$45, $31, $C0]);
  FText.AddBytes([$48, $85, $C0]);
  EmitJcc($89, PositiveLabel);
  FText.AddBytes([$48, $F7, $D8]);
  FText.AddBytes([$41, $B8, $01, $00, $00, $00]);
  BindTextLabel(PositiveLabel);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$48, $31, $D2]);
  FText.AddBytes([$49, $C7, $C2, $0A, $00, $00, $00]);
  FText.AddBytes([$49, $F7, $F2]);
  FText.AddBytes([$80, $C2, $30]);
  FText.AddBytes([$48, $FF, $CE]);
  FText.AddBytes([$88, $16]);
  FText.AddBytes([$48, $FF, $C1]);
  FText.AddBytes([$48, $85, $C0]);
  EmitJcc($85, LoopLabel);
  FText.AddBytes([$45, $85, $C0]);
  EmitJcc($84, WriteLabel);
  FText.AddBytes([$48, $FF, $CE, $C6, $06, $2D, $48, $FF, $C1]);
  BindTextLabel(WriteLabel);
  FText.AddBytes([$BF, $01, $00, $00, $00]);
  FText.AddBytes([$48, $89, $CA]);
  FText.AddBytes([$B8, $01, $00, $00, $00, $0F, $05]);
  FText.AddBytes([$C9, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeMalloc;
var
  L, SizeLabel, FailLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'malloc'); BindTextLabel(L);
  SizeLabel := NewLabel; FailLabel := NewLabel;
  FText.AddBytes([$48, $85, $FF]);
  EmitJcc($85, SizeLabel);
  FText.AddBytes([$BF, $01, $00, $00, $00]);
  BindTextLabel(SizeLabel);


  FText.AddBytes([$48, $83, $C7, $10, $57, $48, $89, $FE, $31, $FF]);
  FText.AddBytes([$BA, $03, $00, $00, $00]);
  FText.AddBytes([$41, $BA, $22, $00, $00, $00]);
  FText.AddBytes([$49, $C7, $C0, $FF, $FF, $FF, $FF]);
  FText.AddBytes([$45, $31, $C9]);
  FText.AddBytes([$B8, $09, $00, $00, $00, $0F, $05, $59]);
  FText.AddBytes([$48, $3D, $01, $F0, $FF, $FF]);
  EmitJcc($83, FailLabel);
  FText.AddBytes([$48, $89, $08, $48, $83, $C0, $10, $C3]);
  BindTextLabel(FailLabel);
  FText.AddBytes([$31, $C0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeCalloc;
var
  L, MallocLabel, MemsetLabel, FailLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'calloc'); BindTextLabel(L);
  MallocLabel := FindNamedLabel(FRuntime, 'malloc');
  MemsetLabel := FindNamedLabel(FRuntime, 'memset');
  FailLabel := NewLabel; DoneLabel := NewLabel;
  FText.Add8($53);



  FText.AddBytes([$48, $89, $F8]);
  FText.AddBytes([$48, $F7, $E6]);
  FText.AddBytes([$48, $85, $D2]);
  EmitJcc($85, FailLabel);
  FText.AddBytes([$48, $89, $C3]);
  FText.AddBytes([$48, $89, $DF]);
  EmitCall(MallocLabel);
  FText.AddBytes([$48, $85, $C0]);
  EmitJcc($84, DoneLabel);
  FText.AddBytes([$48, $89, $C7, $31, $F6, $48, $89, $DA]);
  EmitCall(MemsetLabel);
  EmitJump(DoneLabel);
  BindTextLabel(FailLabel);
  FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel);
  FText.AddBytes([$5B, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeRealloc;
var
  L, MallocLabel, MemcpyLabel, FreeLabel: LongInt;
  AllocateLabel, ReleaseLabel, CountReadyLabel, CleanupLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'realloc'); BindTextLabel(L);
  MallocLabel := FindNamedLabel(FRuntime, 'malloc');
  MemcpyLabel := FindNamedLabel(FRuntime, 'memcpy');
  FreeLabel := FindNamedLabel(FRuntime, 'free');
  AllocateLabel := NewLabel; ReleaseLabel := NewLabel;
  CountReadyLabel := NewLabel; CleanupLabel := NewLabel;
  FText.AddBytes([$48, $85, $FF]);
  EmitJcc($84, AllocateLabel);
  FText.AddBytes([$48, $85, $F6]);
  EmitJcc($84, ReleaseLabel);
  FText.AddBytes([$53, $41, $54, $41, $55]);
  FText.AddBytes([$48, $89, $FB, $49, $89, $F4, $45, $31, $ED]);
  FText.AddBytes([$48, $89, $F7]);
  EmitCall(MallocLabel);
  FText.AddBytes([$48, $85, $C0]);
  EmitJcc($84, CleanupLabel);
  FText.AddBytes([$49, $89, $C5]);
  FText.AddBytes([$48, $8B, $4B, $F0, $48, $83, $E9, $10]);
  FText.AddBytes([$4C, $39, $E1]);
  EmitJcc($86, CountReadyLabel);
  FText.AddBytes([$4C, $89, $E1]);
  BindTextLabel(CountReadyLabel);
  FText.AddBytes([$4C, $89, $EF, $48, $89, $DE, $48, $89, $CA]);
  EmitCall(MemcpyLabel);
  FText.AddBytes([$48, $89, $DF]);
  EmitCall(FreeLabel);
  BindTextLabel(CleanupLabel);
  FText.AddBytes([$4C, $89, $E8, $41, $5D, $41, $5C, $5B, $C3]);
  BindTextLabel(AllocateLabel);
  FText.AddBytes([$48, $89, $F7]);
  EmitJump(MallocLabel);
  BindTextLabel(ReleaseLabel);
  FText.AddBytes([$48, $83, $EC, $08]);
  EmitCall(FreeLabel);
  FText.AddBytes([$48, $83, $C4, $08, $31, $C0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeReallocArray;
var
  L, ReallocLabel, FailLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'reallocarray'); BindTextLabel(L);
  ReallocLabel := FindNamedLabel(FRuntime, 'realloc');
  FailLabel := NewLabel;


  FText.AddBytes([$48, $89, $F0]);
  FText.AddBytes([$48, $F7, $E2]);
  FText.AddBytes([$48, $85, $D2]);
  EmitJcc($85, FailLabel);
  FText.AddBytes([$48, $89, $C6]);
  FText.AddBytes([$48, $83, $EC, $08]);
  EmitCall(ReallocLabel);
  FText.AddBytes([$48, $83, $C4, $08, $C3]);
  BindTextLabel(FailLabel);
  FText.AddBytes([$31, $C0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeFree;
var
  L, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'free'); BindTextLabel(L);
  DoneLabel := NewLabel;
  FText.AddBytes([$48, $85, $FF]);
  EmitJcc($84, DoneLabel);
  FText.AddBytes([$48, $83, $EF, $10, $48, $8B, $37]);
  FText.AddBytes([$B8, $0B, $00, $00, $00, $0F, $05]);
  BindTextLabel(DoneLabel);
  FText.AddBytes([$31, $C0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeMemcpy;
var
  L, LoopLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'memcpy'); BindTextLabel(L);
  LoopLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$48, $89, $F8]);
  FText.AddBytes([$48, $85, $D2]);
  EmitJcc($84, DoneLabel);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$8A, $0E]);
  FText.AddBytes([$88, $0F]);
  FText.AddBytes([$48, $FF, $C6, $48, $FF, $C7, $48, $FF, $CA]);
  EmitJcc($85, LoopLabel);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeMemmove;
var
  L, ForwardLabel, ForwardLoop, BackwardLoop, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'memmove'); BindTextLabel(L);
  ForwardLabel := NewLabel; ForwardLoop := NewLabel;
  BackwardLoop := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$48, $89, $F8, $48, $85, $D2]);
  EmitJcc($84, DoneLabel);
  FText.AddBytes([$48, $39, $F7]);
  EmitJcc($82, ForwardLabel);
  FText.AddBytes([$48, $39, $FE]);
  EmitJcc($84, DoneLabel);
  FText.AddBytes([$48, $8D, $74, $16, $FF]);
  FText.AddBytes([$48, $8D, $7C, $17, $FF]);
  BindTextLabel(BackwardLoop);
  FText.AddBytes([$8A, $0E, $88, $0F]);
  FText.AddBytes([$48, $FF, $CE, $48, $FF, $CF, $48, $FF, $CA]);
  EmitJcc($85, BackwardLoop);
  EmitJump(DoneLabel);
  BindTextLabel(ForwardLabel);
  BindTextLabel(ForwardLoop);
  FText.AddBytes([$8A, $0E, $88, $0F]);
  FText.AddBytes([$48, $FF, $C6, $48, $FF, $C7, $48, $FF, $CA]);
  EmitJcc($85, ForwardLoop);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeMemset;
var
  L, LoopLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'memset'); BindTextLabel(L);
  LoopLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$48, $89, $F8]);
  FText.AddBytes([$48, $85, $D2]);
  EmitJcc($84, DoneLabel);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$40, $88, $37]);
  FText.AddBytes([$48, $FF, $C7, $48, $FF, $CA]);
  EmitJcc($85, LoopLabel);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeMemcmp;
var
  L, LoopLabel, DifferenceLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'memcmp'); BindTextLabel(L);
  LoopLabel := NewLabel; DifferenceLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$31, $C0, $48, $85, $D2]);
  EmitJcc($84, DoneLabel);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$0F, $B6, $0F, $44, $0F, $B6, $06]);
  FText.AddBytes([$44, $39, $C1]);
  EmitJcc($85, DifferenceLabel);
  FText.AddBytes([$48, $FF, $C7, $48, $FF, $C6, $48, $FF, $CA]);
  EmitJcc($85, LoopLabel);
  EmitJump(DoneLabel);
  BindTextLabel(DifferenceLabel);
  FText.AddBytes([$89, $C8, $44, $29, $C0]);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeStrcmp;
var
  L, LoopLabel, DifferenceLabel, EqualLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'strcmp'); BindTextLabel(L);
  LoopLabel := NewLabel; DifferenceLabel := NewLabel; EqualLabel := NewLabel;
  BindTextLabel(LoopLabel);
  FText.AddBytes([$0F, $B6, $07, $0F, $B6, $0E, $39, $C8]);
  EmitJcc($85, DifferenceLabel);
  FText.AddBytes([$85, $C0]);
  EmitJcc($84, EqualLabel);
  FText.AddBytes([$48, $FF, $C7, $48, $FF, $C6]);
  EmitJump(LoopLabel);
  BindTextLabel(DifferenceLabel);
  FText.AddBytes([$29, $C8, $C3]);
  BindTextLabel(EqualLabel);
  FText.AddBytes([$31, $C0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeStrncmp;
var
  L, LoopLabel, DifferenceLabel, EqualLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'strncmp'); BindTextLabel(L);
  LoopLabel := NewLabel; DifferenceLabel := NewLabel; EqualLabel := NewLabel;
  FText.AddBytes([$48, $85, $D2]);
  EmitJcc($84, EqualLabel);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$0F, $B6, $07, $0F, $B6, $0E, $39, $C8]);
  EmitJcc($85, DifferenceLabel);
  FText.AddBytes([$85, $C0]);
  EmitJcc($84, EqualLabel);
  FText.AddBytes([$48, $FF, $C7, $48, $FF, $C6, $48, $FF, $CA]);
  EmitJcc($85, LoopLabel);
  BindTextLabel(EqualLabel);
  FText.AddBytes([$31, $C0, $C3]);
  BindTextLabel(DifferenceLabel);
  FText.AddBytes([$29, $C8, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeStrcpy;
var
  L, LoopLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'strcpy'); BindTextLabel(L);
  LoopLabel := NewLabel;
  FText.AddBytes([$48, $89, $F8]);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$8A, $0E, $88, $0F, $48, $FF, $C6, $48, $FF, $C7]);
  FText.AddBytes([$84, $C9]);
  EmitJcc($85, LoopLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeStrncpy;
var
  L, CopyLoop, PadLoop, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'strncpy'); BindTextLabel(L);
  CopyLoop := NewLabel; PadLoop := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$48, $89, $F8, $48, $85, $D2]);
  EmitJcc($84, DoneLabel);
  BindTextLabel(CopyLoop);
  FText.AddBytes([$8A, $0E, $88, $0F, $48, $FF, $C7, $48, $FF, $CA]);
  FText.AddBytes([$84, $C9]);
  EmitJcc($84, PadLoop);
  FText.AddBytes([$48, $FF, $C6, $48, $85, $D2]);
  EmitJcc($85, CopyLoop);
  EmitJump(DoneLabel);
  BindTextLabel(PadLoop);
  FText.AddBytes([$48, $85, $D2]);
  EmitJcc($84, DoneLabel);
  FText.AddBytes([$C6, $07, $00, $48, $FF, $C7, $48, $FF, $CA]);
  EmitJump(PadLoop);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeStrchr;
var
  L, LoopLabel, FoundLabel, MissingLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'strchr'); BindTextLabel(L);
  LoopLabel := NewLabel; FoundLabel := NewLabel; MissingLabel := NewLabel;
  FText.AddBytes([$89, $F1, $0F, $B6, $C9]);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$8A, $07, $38, $C8]);
  EmitJcc($84, FoundLabel);
  FText.AddBytes([$84, $C0]);
  EmitJcc($84, MissingLabel);
  FText.AddBytes([$48, $FF, $C7]);
  EmitJump(LoopLabel);
  BindTextLabel(FoundLabel);
  FText.AddBytes([$48, $89, $F8, $C3]);
  BindTextLabel(MissingLabel);
  FText.AddBytes([$31, $C0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeStrrchr;
var
  L, LoopLabel, SkipLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'strrchr'); BindTextLabel(L);
  LoopLabel := NewLabel; SkipLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$89, $F1, $0F, $B6, $C9, $31, $C0]);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$8A, $17, $38, $CA]);
  EmitJcc($85, SkipLabel);
  FText.AddBytes([$48, $89, $F8]);
  BindTextLabel(SkipLabel);
  FText.AddBytes([$84, $D2]);
  EmitJcc($84, DoneLabel);
  FText.AddBytes([$48, $FF, $C7]);
  EmitJump(LoopLabel);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeStrnlen;
var
  L, LoopLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'strnlen'); BindTextLabel(L);
  LoopLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$48, $31, $C0, $48, $85, $F6]);
  EmitJcc($84, DoneLabel);
  BindTextLabel(LoopLabel);
  FText.AddBytes([$80, $3C, $07, $00]);
  EmitJcc($84, DoneLabel);
  FText.AddBytes([$48, $FF, $C0, $48, $39, $F0]);
  EmitJcc($82, LoopLabel);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeParseDecimal;
var
  L, SkipLoop, SkipAdvance, SignLabel, PlusLabel, DigitLoop,
  DoneLabel, ReturnLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, '__rcc_parse_decimal'); BindTextLabel(L);
  SkipLoop := NewLabel; SkipAdvance := NewLabel; SignLabel := NewLabel;
  PlusLabel := NewLabel; DigitLoop := NewLabel; DoneLabel := NewLabel;
  ReturnLabel := NewLabel;
  FText.AddBytes([$48, $31, $C0, $31, $C9]);
  BindTextLabel(SkipLoop);
  FText.AddBytes([$8A, $17, $80, $FA, $20]);
  EmitJcc($84, SkipAdvance);
  FText.AddBytes([$80, $FA, $09]);
  EmitJcc($82, SignLabel);
  FText.AddBytes([$80, $FA, $0D]);
  EmitJcc($86, SkipAdvance);
  EmitJump(SignLabel);
  BindTextLabel(SkipAdvance);
  FText.AddBytes([$48, $FF, $C7]);
  EmitJump(SkipLoop);
  BindTextLabel(SignLabel);
  FText.AddBytes([$80, $FA, $2D]);
  EmitJcc($85, PlusLabel);
  FText.AddBytes([$B9, $01, $00, $00, $00, $48, $FF, $C7]);
  EmitJump(DigitLoop);
  BindTextLabel(PlusLabel);
  FText.AddBytes([$80, $FA, $2B]);
  EmitJcc($85, DigitLoop);
  FText.AddBytes([$48, $FF, $C7]);
  BindTextLabel(DigitLoop);
  FText.AddBytes([$0F, $B6, $17, $83, $EA, $30, $83, $FA, $09]);
  EmitJcc($87, DoneLabel);
  FText.AddBytes([$48, $6B, $C0, $0A, $48, $01, $D0, $48, $FF, $C7]);
  EmitJump(DigitLoop);
  BindTextLabel(DoneLabel);
  FText.AddBytes([$85, $C9]);
  EmitJcc($84, ReturnLabel);
  FText.AddBytes([$48, $F7, $D8]);
  BindTextLabel(ReturnLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeAtoi(const AName: string);
var
  L, ParserLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, AName); BindTextLabel(L);
  ParserLabel := FindNamedLabel(FRuntime, '__rcc_parse_decimal');
  EmitJump(ParserLabel);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeAssert;
var
  L, OkLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'assert');
  BindTextLabel(L);
  OkLabel := NewLabel;
  FText.AddBytes([$48, $85, $FF]);
  EmitJcc($85, OkLabel);
  FText.AddBytes([$BF, $86, $00, $00, $00]);
  FText.AddBytes([$B8, $3C, $00, $00, $00]);
  FText.AddBytes([$0F, $05, $0F, $0B]);
  BindTextLabel(OkLabel);
  FText.AddBytes([$31, $C0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsDigit;
var
  L, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'isdigit');
  BindTextLabel(L);
  FalseLabel := NewLabel;
  DoneLabel := NewLabel;
  FText.AddBytes([$83, $FF, $30]);
  EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $39]);
  EmitJcc($8F, FalseLabel);
  FText.AddBytes([$B8, $01, $00, $00, $00]);
  EmitJump(DoneLabel);
  BindTextLabel(FalseLabel);
  FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsSpace;
var
  L, TrueLabel, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'isspace');
  BindTextLabel(L);
  TrueLabel := NewLabel;
  FalseLabel := NewLabel;
  DoneLabel := NewLabel;
  FText.AddBytes([$83, $FF, $20]);
  EmitJcc($84, TrueLabel);
  FText.AddBytes([$83, $FF, $09]);
  EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $0D]);
  EmitJcc($8F, FalseLabel);
  BindTextLabel(TrueLabel);
  FText.AddBytes([$B8, $01, $00, $00, $00]);
  EmitJump(DoneLabel);
  BindTextLabel(FalseLabel);
  FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsAlpha;
var
  L, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'isalpha');
  BindTextLabel(L);
  FalseLabel := NewLabel;
  DoneLabel := NewLabel;
  FText.AddBytes([$89, $F8]);
  FText.AddBytes([$83, $C8, $20]);
  FText.AddBytes([$83, $F8, $61]);
  EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $F8, $7A]);
  EmitJcc($8F, FalseLabel);
  FText.AddBytes([$B8, $01, $00, $00, $00]);
  EmitJump(DoneLabel);
  BindTextLabel(FalseLabel);
  FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsAlnum;
var
  L, TrueLabel, DigitLabel, FalseResultLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'isalnum'); BindTextLabel(L);
  TrueLabel := NewLabel; DigitLabel := NewLabel;
  FalseResultLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$89, $F8, $83, $C8, $20, $83, $F8, $61]);
  EmitJcc($8C, DigitLabel);
  FText.AddBytes([$83, $F8, $7A]);
  EmitJcc($8E, TrueLabel);
  BindTextLabel(DigitLabel);
  FText.AddBytes([$83, $FF, $30]);
  EmitJcc($8C, FalseResultLabel);
  FText.AddBytes([$83, $FF, $39]);
  EmitJcc($8F, FalseResultLabel);
  BindTextLabel(TrueLabel);
  FText.AddBytes([$B8, $01, $00, $00, $00]);
  EmitJump(DoneLabel);
  BindTextLabel(FalseResultLabel);
  FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsLower;
var L, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'islower'); BindTextLabel(L);
  FalseLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$83, $FF, $61]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $7A]); EmitJcc($8F, FalseLabel);
  FText.AddBytes([$B8, $01, $00, $00, $00]); EmitJump(DoneLabel);
  BindTextLabel(FalseLabel); FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel); FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsUpper;
var L, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'isupper'); BindTextLabel(L);
  FalseLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$83, $FF, $41]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $5A]); EmitJcc($8F, FalseLabel);
  FText.AddBytes([$B8, $01, $00, $00, $00]); EmitJump(DoneLabel);
  BindTextLabel(FalseLabel); FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel); FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsXDigit;
var L, AlphaLabel, FalseLabel, TrueLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'isxdigit'); BindTextLabel(L);
  AlphaLabel := NewLabel; FalseLabel := NewLabel; TrueLabel := NewLabel;
  DoneLabel := NewLabel;
  FText.AddBytes([$89, $F8, $83, $F8, $30]); EmitJcc($8C, AlphaLabel);
  FText.AddBytes([$83, $F8, $39]); EmitJcc($8E, TrueLabel);
  BindTextLabel(AlphaLabel);
  FText.AddBytes([$83, $C8, $20, $83, $F8, $61]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $F8, $66]); EmitJcc($8F, FalseLabel);
  BindTextLabel(TrueLabel); FText.AddBytes([$B8, $01, $00, $00, $00]);
  EmitJump(DoneLabel);
  BindTextLabel(FalseLabel); FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel); FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsPrint;
var L, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'isprint'); BindTextLabel(L);
  FalseLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$83, $FF, $20]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $7E]); EmitJcc($8F, FalseLabel);
  FText.AddBytes([$B8, $01, $00, $00, $00]); EmitJump(DoneLabel);
  BindTextLabel(FalseLabel); FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel); FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsGraph;
var L, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'isgraph'); BindTextLabel(L);
  FalseLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$83, $FF, $21]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $7E]); EmitJcc($8F, FalseLabel);
  FText.AddBytes([$B8, $01, $00, $00, $00]); EmitJump(DoneLabel);
  BindTextLabel(FalseLabel); FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel); FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsCntrl;
var L, TrueLabel, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'iscntrl'); BindTextLabel(L);
  TrueLabel := NewLabel; FalseLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$85, $FF]); EmitJcc($88, FalseLabel);
  FText.AddBytes([$83, $FF, $1F]); EmitJcc($8E, TrueLabel);
  FText.AddBytes([$83, $FF, $7F]); EmitJcc($84, TrueLabel);
  EmitJump(FalseLabel);
  BindTextLabel(TrueLabel); FText.AddBytes([$B8, $01, $00, $00, $00]);
  EmitJump(DoneLabel);
  BindTextLabel(FalseLabel); FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel); FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeIsPunct;
var L, TrueLabel, FalseLabel, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'ispunct'); BindTextLabel(L);
  TrueLabel := NewLabel; FalseLabel := NewLabel; DoneLabel := NewLabel;
  FText.AddBytes([$83, $FF, $21]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $2F]); EmitJcc($8E, TrueLabel);
  FText.AddBytes([$83, $FF, $3A]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $40]); EmitJcc($8E, TrueLabel);
  FText.AddBytes([$83, $FF, $5B]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $60]); EmitJcc($8E, TrueLabel);
  FText.AddBytes([$83, $FF, $7B]); EmitJcc($8C, FalseLabel);
  FText.AddBytes([$83, $FF, $7E]); EmitJcc($8F, FalseLabel);
  BindTextLabel(TrueLabel); FText.AddBytes([$B8, $01, $00, $00, $00]);
  EmitJump(DoneLabel);
  BindTextLabel(FalseLabel); FText.AddBytes([$31, $C0]);
  BindTextLabel(DoneLabel); FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeToLower;
var
  L, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'tolower'); BindTextLabel(L);
  DoneLabel := NewLabel;
  FText.AddBytes([$89, $F8, $83, $F8, $41]);
  EmitJcc($8C, DoneLabel);
  FText.AddBytes([$83, $F8, $5A]);
  EmitJcc($8F, DoneLabel);
  FText.AddBytes([$83, $C0, $20]);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeToUpper;
var
  L, DoneLabel: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'toupper'); BindTextLabel(L);
  DoneLabel := NewLabel;
  FText.AddBytes([$89, $F8, $83, $F8, $61]);
  EmitJcc($8C, DoneLabel);
  FText.AddBytes([$83, $F8, $7A]);
  EmitJcc($8F, DoneLabel);
  FText.AddBytes([$83, $E8, $20]);
  BindTextLabel(DoneLabel);
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeAbs(const AName: string; ALong: Boolean);
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, AName); BindTextLabel(L);
  if ALong then
    FText.AddBytes([$48, $89, $F8, $48, $99, $48, $31, $D0,
      $48, $29, $D0, $C3])
  else
    FText.AddBytes([$89, $F8, $99, $31, $D0, $29, $D0, $C3]);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntime;
var
  I, J, DependencyIndex: LongInt;
  Dependency: string;
  Changed: Boolean;
begin
  repeat
    Changed := False;
    for I := 0 to High(FRuntime) do
      if FRuntimeUsed[I] then
        for J := 0 to RuntimeDependencyCount(FRuntime[I].Name) - 1 do
        begin
          Dependency := RuntimeDependencyName(FRuntime[I].Name, J);
          DependencyIndex := 0;
          while (DependencyIndex <= High(FRuntime)) and
            (FRuntime[DependencyIndex].Name <> Dependency) do
            Inc(DependencyIndex);
          if (DependencyIndex <= High(FRuntime)) and
            (not FRuntimeUsed[DependencyIndex]) then
          begin
            FRuntimeUsed[DependencyIndex] := True;
            Changed := True;
          end;
        end;
  until not Changed;

  for I := 0 to High(FRuntime) do
  begin
    if not FRuntimeUsed[I] then Continue;
    if FRuntime[I].Name = 'read' then EmitRuntimeRead
    else if FRuntime[I].Name = 'write' then EmitRuntimeWrite
    else if FRuntime[I].Name = 'close' then EmitRuntimeClose
    else if FRuntime[I].Name = 'open' then EmitRuntimeOpen
    else if FRuntime[I].Name = 'lseek' then EmitRuntimeLseek
    else if FRuntime[I].Name = 'getpid' then EmitRuntimeGetPid
    else if FRuntime[I].Name = 'getpagesize' then EmitRuntimeGetPageSize
    else if FRuntime[I].Name = 'access' then EmitRuntimeAccess
    else if FRuntime[I].Name = 'time' then EmitRuntimeTime
    else if FRuntime[I].Name = 'exit' then EmitRuntimeExit('exit')
    else if FRuntime[I].Name = '_Exit' then EmitRuntimeExit('_Exit')
    else if FRuntime[I].Name = '_exit' then EmitRuntimeExit('_exit')
    else if FRuntime[I].Name = 'abort' then EmitRuntimeAbort
    else if FRuntime[I].Name = 'atexit' then EmitRuntimeAtexit
    else if FRuntime[I].Name = 'strlen' then EmitRuntimeStrlen
    else if FRuntime[I].Name = 'puts' then EmitRuntimePuts
    else if FRuntime[I].Name = 'putchar' then EmitRuntimePutchar
    else if FRuntime[I].Name = 'getchar' then EmitRuntimeGetchar
    else if FRuntime[I].Name = 'print_int' then EmitRuntimePrintInt
    else if FRuntime[I].Name = '__rcc_print_string' then EmitRuntimePrintString
    else if FRuntime[I].Name = '__rcc_print_int_raw' then EmitRuntimePrintIntRaw
    else if FRuntime[I].Name = 'malloc' then EmitRuntimeMalloc
    else if FRuntime[I].Name = 'calloc' then EmitRuntimeCalloc
    else if FRuntime[I].Name = 'realloc' then EmitRuntimeRealloc
    else if FRuntime[I].Name = 'reallocarray' then EmitRuntimeReallocArray
    else if FRuntime[I].Name = 'free' then EmitRuntimeFree
    else if FRuntime[I].Name = 'memcpy' then EmitRuntimeMemcpy
    else if FRuntime[I].Name = 'memmove' then EmitRuntimeMemmove
    else if FRuntime[I].Name = 'memset' then EmitRuntimeMemset
    else if FRuntime[I].Name = 'memcmp' then EmitRuntimeMemcmp
    else if FRuntime[I].Name = 'strcmp' then EmitRuntimeStrcmp
    else if FRuntime[I].Name = 'strncmp' then EmitRuntimeStrncmp
    else if FRuntime[I].Name = 'strcpy' then EmitRuntimeStrcpy
    else if FRuntime[I].Name = 'strncpy' then EmitRuntimeStrncpy
    else if FRuntime[I].Name = 'strchr' then EmitRuntimeStrchr
    else if FRuntime[I].Name = 'strrchr' then EmitRuntimeStrrchr
    else if FRuntime[I].Name = 'strnlen' then EmitRuntimeStrnlen
    else if FRuntime[I].Name = '__rcc_parse_decimal' then EmitRuntimeParseDecimal
    else if FRuntime[I].Name = 'atoi' then EmitRuntimeAtoi('atoi')
    else if FRuntime[I].Name = 'atol' then EmitRuntimeAtoi('atol')
    else if FRuntime[I].Name = 'assert' then EmitRuntimeAssert
    else if FRuntime[I].Name = 'isdigit' then EmitRuntimeIsDigit
    else if FRuntime[I].Name = 'isspace' then EmitRuntimeIsSpace
    else if FRuntime[I].Name = 'isalpha' then EmitRuntimeIsAlpha
    else if FRuntime[I].Name = 'isalnum' then EmitRuntimeIsAlnum
    else if FRuntime[I].Name = 'islower' then EmitRuntimeIsLower
    else if FRuntime[I].Name = 'isupper' then EmitRuntimeIsUpper
    else if FRuntime[I].Name = 'isxdigit' then EmitRuntimeIsXDigit
    else if FRuntime[I].Name = 'isprint' then EmitRuntimeIsPrint
    else if FRuntime[I].Name = 'isgraph' then EmitRuntimeIsGraph
    else if FRuntime[I].Name = 'iscntrl' then EmitRuntimeIsCntrl
    else if FRuntime[I].Name = 'ispunct' then EmitRuntimeIsPunct
    else if FRuntime[I].Name = 'tolower' then EmitRuntimeToLower
    else if FRuntime[I].Name = 'toupper' then EmitRuntimeToUpper
    else if FRuntime[I].Name = 'abs' then EmitRuntimeAbs('abs', False)
    else if FRuntime[I].Name = 'labs' then EmitRuntimeAbs('labs', True);
  end;
end;

function TX64Backend.CountExpressionSpillBytes(E: TExpr): LongInt;
var
  I, Size, Alignment: LongInt;
begin
  if E = nil then Exit(0);
  Result := CountExpressionSpillBytes(E.Left) +
    CountExpressionSpillBytes(E.Right) +
    CountExpressionSpillBytes(E.Third);
  for I := 0 to High(E.Args) do
    Inc(Result, CountExpressionSpillBytes(E.Args[I]));
  if E.Kind <> ekCall then Exit;




  for I := 0 to High(E.Args) do
  begin
    if IsAggregateType(E.Args[I].CType) then
    begin
      Size := LongInt(AlignUp(QWord(StorageSize(E.Args[I].CType)), 8));
      Alignment := StorageAlign(E.Args[I].CType);
    end
    else
    begin
      Size := 8;
      Alignment := 8;
    end;
    Inc(Result, Size + Alignment - 1);
  end;
  if IsAggregateType(E.CType) then
  begin
    Size := LongInt(AlignUp(QWord(StorageSize(E.CType)), 8));
    Alignment := StorageAlign(E.CType);
    Inc(Result, Size + Alignment - 1);
  end;
  if E.Text = '' then Inc(Result, 15);
end;

function TX64Backend.CountLocalBytes(S: TStmt): LongInt;
var
  I, Size, Alignment: LongInt;
begin
  if S = nil then Exit(0);
  Result := 0;
  if S.Kind = skDecl then
  begin
    Size := StorageSize(S.CType);
    if IsAggregateType(S.CType) then
      Size := LongInt(AlignUp(QWord(Size), 8))
    else if Size < 8 then
      Size := 8;
    Alignment := StorageAlign(S.CType);
    Inc(Result, Size + Alignment - 1);
  end;
  Inc(Result, CountExpressionSpillBytes(S.Expr));
  Inc(Result, CountExpressionSpillBytes(S.Expr2));
  for I := 0 to High(S.AsmOutputs) do
    Inc(Result, CountExpressionSpillBytes(S.AsmOutputs[I].Expr));
  for I := 0 to High(S.AsmInputs) do
    Inc(Result, CountExpressionSpillBytes(S.AsmInputs[I].Expr));
  Inc(Result, CountLocalBytes(S.InitStmt));
  Inc(Result, CountLocalBytes(S.Body));
  Inc(Result, CountLocalBytes(S.ElseBody));
  for I := 0 to High(S.Children) do
    Inc(Result, CountLocalBytes(S.Children[I]));
end;

procedure TX64Backend.ReserveTemporary(ASize, AAlignment: LongInt;
  out AOffset: LongInt);
begin
  if ASize < 1 then ASize := 1;
  if AAlignment < 1 then AAlignment := 1;
  FNextLocalSlot := LongInt(AlignUp(QWord(FNextLocalSlot),
    QWord(AAlignment)));
  Inc(FNextLocalSlot, ASize);
  AOffset := FNextLocalSlot;
end;

procedure TX64Backend.AddLocal(const AName: string; const AType: TCType;
  AIndirectObject: Boolean; out AOffset: LongInt);
var
  I, N, Size, Alignment: LongInt;
begin
  for I := High(FLocals) downto 0 do
    if (FLocals[I].Name = AName) and
      (FLocals[I].ScopeDepth = FScopeDepth) then
      raise ERCCError.Create('error: duplicate local variable ''' + AName + '''');
  Size := StorageSize(AType);
  Alignment := StorageAlign(AType);
  if AIndirectObject then
  begin
    Size := 8;
    Alignment := 8;
  end;
  if IsAggregateType(AType) then
    Size := LongInt(AlignUp(QWord(Size), 8));
  FNextLocalSlot := LongInt(AlignUp(QWord(FNextLocalSlot), QWord(Alignment)));
  if (not IsAggregateType(AType)) and (Size < 8) then
    Inc(FNextLocalSlot, 8)
  else
    Inc(FNextLocalSlot, Size);
  AOffset := FNextLocalSlot;
  N := Length(FLocals);
  SetLength(FLocals, N + 1);
  FLocals[N].Name := AName;
  FLocals[N].Offset := AOffset;
  FLocals[N].Size := Size;
  FLocals[N].Align := Alignment;
  FLocals[N].CType := AType;
  FLocals[N].IsIndirectObject := AIndirectObject;
  FLocals[N].ScopeDepth := FScopeDepth;
end;

function TX64Backend.FindLocal(const AName: string; out AOffset: LongInt;
  out AType: TCType; out AIndirectObject: Boolean): Boolean;
var
  I: LongInt;
begin
  for I := High(FLocals) downto 0 do
    if FLocals[I].Name = AName then
    begin
      AOffset := FLocals[I].Offset;
      AType := FLocals[I].CType;
      AIndirectObject := FLocals[I].IsIndirectObject;
      Exit(True);
    end;
  AOffset := 0;
  AType := MakeType(ctVoid);
  AIndirectObject := False;
  Result := False;
end;

function TX64Backend.FindGlobalLabel(const AName: string): LongInt;
begin
  Result := FindNamedLabel(FGlobals, AName);
  if Result < 0 then
    Result := FindExternalDefinition(AName, ELF_STT_OBJECT);
end;

function TX64Backend.FindGlobal(const AName: string): TGlobal;
var
  I: LongInt;
begin
  for I := High(FProgram.Globals) downto 0 do
    if FProgram.Globals[I].Name = AName then Exit(FProgram.Globals[I]);
  Result := nil;
end;

procedure TX64Backend.EnterScope;
begin
  Inc(FScopeDepth);
end;

procedure TX64Backend.LeaveScope(ASavedCount: LongInt);
begin
  SetLength(FLocals, ASavedCount);
  Dec(FScopeDepth);
end;

procedure TX64Backend.PushLoop(ABreakLabel, AContinueLabel: LongInt);
var N: LongInt;
begin
  N := Length(FBreakLabels);
  SetLength(FBreakLabels, N + 1);
  SetLength(FContinueLabels, N + 1);
  FBreakLabels[N] := ABreakLabel;
  FContinueLabels[N] := AContinueLabel;
end;

procedure TX64Backend.PopLoop;
begin
  SetLength(FBreakLabels, Length(FBreakLabels) - 1);
  SetLength(FContinueLabels, Length(FContinueLabels) - 1);
end;

procedure TX64Backend.PushBreak(ABreakLabel: LongInt);
var
  N: LongInt;
begin
  N := Length(FBreakLabels);
  SetLength(FBreakLabels, N + 1);
  FBreakLabels[N] := ABreakLabel;
end;

procedure TX64Backend.PopBreak;
begin
  if Length(FBreakLabels) = 0 then
    raise ERCCError.Create('internal error: break-label stack underflow');
  SetLength(FBreakLabels, Length(FBreakLabels) - 1);
end;

procedure TX64Backend.ReserveUserLabels(S: TStmt);
var
  I, N: LongInt;
begin
  if S = nil then Exit;
  if S.Kind = skLabel then
  begin
    if FindUserLabel(S.Name) >= 0 then
      RaiseCompileError(S.Pos, 'duplicate label ' + S.Name);
    N := Length(FUserLabels);
    SetLength(FUserLabels, N + 1);
    FUserLabels[N].Name := S.Name;
    FUserLabels[N].LabelID := NewLabel;
  end;
  ReserveUserLabels(S.InitStmt);
  ReserveUserLabels(S.Body);
  ReserveUserLabels(S.ElseBody);
  for I := 0 to High(S.Children) do ReserveUserLabels(S.Children[I]);
end;

function TX64Backend.FindUserLabel(const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(FUserLabels) do
    if FUserLabels[I].Name = AName then Exit(FUserLabels[I].LabelID);
  Result := -1;
end;

procedure TX64Backend.CollectSwitchEntries(S: TStmt;
  var AEntries: TSwitchEntryArray);
var
  I, J, N: LongInt;
begin
  if S = nil then Exit;
  if S.Kind in [skCase, skDefault] then
  begin
    for J := 0 to High(AEntries) do
    begin
      if (S.Kind = skDefault) and AEntries[J].IsDefault then
        RaiseCompileError(S.Pos, 'duplicate default label in switch');
      if (S.Kind = skCase) and (not AEntries[J].IsDefault) and
        (AEntries[J].Value = S.CaseValue) then
        RaiseCompileError(S.Pos, 'duplicate case value in switch');
    end;
    N := Length(AEntries);
    SetLength(AEntries, N + 1);
    AEntries[N].Statement := S;
    AEntries[N].TargetLabel := NewLabel;
    AEntries[N].MatchLabel := -1;
    AEntries[N].IsDefault := S.Kind = skDefault;
    AEntries[N].Value := S.CaseValue;

    if (S.Body <> nil) and (S.Body.Kind in [skCase, skDefault]) then
      CollectSwitchEntries(S.Body, AEntries);
    Exit;
  end;
  if S.Kind = skSwitch then Exit;
  if S.Kind = skBlock then
    for I := 0 to High(S.Children) do
      CollectSwitchEntries(S.Children[I], AEntries);
end;

function TX64Backend.SwitchTargetFor(S: TStmt;
  const AEntries: TSwitchEntryArray): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(AEntries) do
    if AEntries[I].Statement = S then Exit(AEntries[I].TargetLabel);
  Result := -1;
end;

procedure TX64Backend.GenSwitchBody(S: TStmt;
  const AEntries: TSwitchEntryArray);
var
  I, L: LongInt;
begin
  if S = nil then Exit;
  case S.Kind of
    skBlock:
      for I := 0 to High(S.Children) do
        GenSwitchBody(S.Children[I], AEntries);
    skCase, skDefault:
      begin
        L := SwitchTargetFor(S, AEntries);
        if L < 0 then
          RaiseCompileError(S.Pos,
            'case label placement is not supported by the current backend');
        BindTextLabel(L);
        GenSwitchBody(S.Body, AEntries);
      end;
  else
    GenStmt(S);
  end;
end;

procedure TX64Backend.InitializeLocalAt(AOffset, AByteOffset: LongInt;
  const AType: TCType; AInitializer: TExpr; const APos: TSourcePos);
var
  I, Count, ElementSize, MemberIndex: LongInt;
  ElementType, MemberType: TCType;
  Member: TStructMember;
begin
  if AInitializer = nil then Exit;
  if AType.Kind = ctArray then
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
        EmitAddressLocal(AOffset);
        EmitAddRaxImmediate(AByteOffset + I);
        FText.AddBytes([$48, $89, $C1]);
        EmitMovRaxImm(Ord(AInitializer.Text[I + 1]));
        EmitStoreRaxAtRcx(ElementType);
      end;
      Exit;
    end;
    if AInitializer.Kind <> ekCompoundLit then
      RaiseCompileError(APos, 'array initializer requires braces or string literal');
    for I := 0 to High(AInitializer.Args) do
    begin
      if I >= AType.ArrayLength then
        RaiseCompileError(APos, 'too many elements in array initializer');
      InitializeLocalAt(AOffset, AByteOffset + I * ElementSize,
        ElementType, AInitializer.Args[I], APos);
    end;
    Exit;
  end;

  if (AType.PointerDepth = 0) and (AType.Kind in [ctStruct, ctUnion]) then
  begin
    if AType.StructInfo = nil then
      RaiseCompileError(APos, 'initializer uses incomplete aggregate type');
    if AInitializer.Kind <> ekCompoundLit then
      RaiseCompileError(APos, 'aggregate initializer requires braces');
    for I := 0 to High(AInitializer.Args) do
    begin
      MemberIndex := I;
      if MemberIndex > High(AType.StructInfo^.Members) then
        RaiseCompileError(APos, 'too many values in aggregate initializer');
      Member := AType.StructInfo^.Members[MemberIndex];
      MemberType := PCType(Member.CType)^;
      if Member.IsBitField then
      begin
        GenExpr(AInitializer.Args[I]);
        EmitNormalizeInteger(MemberType);
        EmitPushRax;
        EmitAddressLocal(AOffset);
        EmitAddRaxImmediate(AByteOffset + Member.Offset);
        FText.AddBytes([$48, $89, $C1]);
        FText.Add8($58);
        Dec(FStackDepth, 8);
        EmitStoreBitFieldAtRcx(MemberType,
          Member.BitOffset, Member.BitWidth);
      end
      else
        InitializeLocalAt(AOffset, AByteOffset + Member.Offset,
          MemberType, AInitializer.Args[I], APos);
      if AType.Kind = ctUnion then Break;
    end;
    Exit;
  end;

  if IsFloatingType(AType) then
  begin
    GenExprAsFloating(AInitializer, AType);
    EmitAddressLocal(AOffset);
    EmitAddRaxImmediate(AByteOffset);
    FText.AddBytes([$48, $89, $C1]);
    EmitStoreRaxAtRcx(AType);
  end
  else
  begin
    GenExpr(AInitializer);
    EmitNormalizeInteger(AType);
    EmitPushRax;
    EmitAddressLocal(AOffset);
    EmitAddRaxImmediate(AByteOffset);
    FText.AddBytes([$48, $89, $C1]);
    FText.Add8($58);
    Dec(FStackDepth, 8);
    EmitStoreRaxAtRcx(AType);
  end;
end;

procedure TX64Backend.InitializeLocal(AOffset: LongInt; const AType: TCType;
  AInitializer: TExpr; const APos: TSourcePos);
var
  L, Pad: LongInt;
  Indirect: Boolean;
begin
  if AInitializer = nil then Exit;
  if IsAggregateType(AType) and
     (AInitializer.Kind <> ekCompoundLit) and
     not ((AType.Kind = ctArray) and (AInitializer.Kind = ekString)) then
  begin


    GenExpr(AInitializer);
    FText.AddBytes([$48, $89, $C6]);
    EmitAddressLocal(AOffset);
    FText.AddBytes([$48, $89, $C7]);
    EmitMovRaxImm(StorageSize(AType));
    FText.AddBytes([$48, $89, $C1]);
    FText.AddBytes([$F3, $A4]);
    Exit;
  end;
  if IsAggregateType(AType) then
  begin
    EmitAddressLocal(AOffset);
    EmitMoveRaxToArg(0);
    EmitMovRaxImm(0);
    EmitMoveRaxToArg(1);
    EmitMovRaxImm(StorageSize(AType));
    EmitMoveRaxToArg(2);
    L := ResolveCallable('memset', APos, Indirect);
    Pad := 0;
    if (FStackDepth and 15) <> 0 then
    begin
      FText.AddBytes([$48, $83, $EC, $08]);
      Inc(FStackDepth, 8);
      Pad := 8;
    end;
    if Indirect then EmitIndirectCall(L) else EmitCall(L);
    if Pad <> 0 then
    begin
      FText.AddBytes([$48, $83, $C4, $08]);
      Dec(FStackDepth, 8);
    end;
  end;
  InitializeLocalAt(AOffset, 0, AType, AInitializer, APos);
end;

procedure TX64Backend.GenAddress(E: TExpr);
var
  Offset, L: LongInt;
  LocalType: TCType;
  GlobalDecl: TGlobal;
  IndirectLocal: Boolean;
begin
  if E = nil then raise ERCCError.Create('internal error: nil lvalue');
  case E.Kind of
    ekVariable:
      begin
        if FindLocal(E.Text, Offset, LocalType, IndirectLocal) then
        begin
          if IndirectLocal then EmitLoadLocal(Offset)
          else EmitAddressLocal(Offset);
        end
        else
        begin
          L := FindGlobalLabel(E.Text);
          if L >= 0 then EmitAddressGlobal(L)
          else
          begin
            GlobalDecl := FindGlobal(E.Text);
            if (GlobalDecl = nil) or not GlobalDecl.IsExtern then
              RaiseCompileError(E.Pos, 'unknown variable ''' + E.Text + '''');
            L := EnsureExternalObject(E.Text, E.Pos);
            if FOptions.EmitMode = emObject then EmitObjectGOTLoad(L)
            else EmitLoadGlobal(L);
          end;
        end;
      end;
    ekDeref: GenExpr(E.Left);
    ekIndex:
      begin
        GenExpr(E.Left);
        EmitPushRax;
        GenExpr(E.Right);
        EmitScaleRax(LongInt(E.IntValue));
        FText.AddBytes([$48, $89, $C1]);
        FText.Add8($58);
        Dec(FStackDepth, 8);
        FText.AddBytes([$48, $01, $C8]);
      end;
    ekMember:
      begin
        GenAddress(E.Left);
        EmitAddRaxImmediate(LongInt(E.IntValue));
      end;
    ekArrow:
      begin
        GenExpr(E.Left);
        EmitAddRaxImmediate(LongInt(E.IntValue));
      end;
  else
    RaiseCompileError(E.Pos, 'expression is not assignable');
  end;
end;


procedure TX64Backend.GenExprAsFloating(E: TExpr;
  const ATargetType: TCType);
begin
  GenExpr(E);
  if IsFloatingType(E.CType) then
    EmitConvertFloatWidth(E.CType, ATargetType)
  else
    EmitConvertIntegerToFloat(ATargetType);
end;


procedure TX64Backend.GenCondition(E: TExpr);
begin
  GenExpr(E);
  if IsFloatingType(E.CType) then EmitFloatToBool(E.CType)
  else EmitNormalizeBool;
end;

procedure TX64Backend.GenAssignment(E: TExpr);
var
  Op: TBinaryOp;
  L, Pad, Scale: LongInt;
  Indirect: Boolean;
begin
  if E.Left.IsBitField then
  begin
    GenAddress(E.Left);
    EmitPushRax;
    if E.AssignOp = aoAssign then
      GenExpr(E.Right)
    else
    begin
      EmitLoadBitField(E.Left.CType, E.Left.BitOffset, E.Left.BitWidth);
      EmitPushRax;
      GenExpr(E.Right);
      FText.AddBytes([$48, $89, $C1]);
      FText.Add8($58);
      Dec(FStackDepth, 8);
      case E.AssignOp of
        aoAdd: Op := boAdd; aoSub: Op := boSub; aoMul: Op := boMul;
        aoDiv: Op := boDiv; aoMod: Op := boMod;
        aoBitAnd: Op := boBitAnd; aoBitOr: Op := boBitOr;
        aoBitXor: Op := boBitXor; aoShiftLeft: Op := boShiftLeft;
        aoShiftRight: Op := boShiftRight;
      else
        Op := boAdd;
      end;
      EmitBinaryOperation(Op, E.Left.CType.IsUnsigned);
    end;
    EmitNormalizeInteger(E.Left.CType);
    EmitPopRcx;
    EmitStoreBitFieldAtRcx(E.Left.CType,
      E.Left.BitOffset, E.Left.BitWidth);
    Exit;
  end;

  if IsAggregateType(E.Left.CType) then
  begin
    if E.AssignOp <> aoAssign then
      RaiseCompileError(E.Pos, 'compound assignment is invalid for aggregates');
    GenAddress(E.Left);
    EmitPushRax;
    GenExpr(E.Right);
    EmitMoveRaxToArg(1);
    FText.Add8($58);
    Dec(FStackDepth, 8);
    EmitMoveRaxToArg(0);
    EmitMovRaxImm(StorageSize(E.Left.CType));
    EmitMoveRaxToArg(2);
    L := ResolveCallable('memcpy', E.Pos, Indirect);
    Pad := 0;
    if (FStackDepth and 15) <> 0 then
    begin
      FText.AddBytes([$48, $83, $EC, $08]);
      Inc(FStackDepth, 8);
      Pad := 8;
    end;
    if Indirect then EmitIndirectCall(L) else EmitCall(L);
    if Pad <> 0 then
    begin
      FText.AddBytes([$48, $83, $C4, $08]);
      Dec(FStackDepth, 8);
    end;
    Exit;
  end;

  if IsFloatingType(E.Left.CType) then
  begin
    GenAddress(E.Left);
    EmitPushRax;
    if E.AssignOp = aoAssign then
      GenExprAsFloating(E.Right, E.Left.CType)
    else
    begin
      FText.AddBytes([$48, $8B, $04, $24]);
      EmitLoadAtRax(E.Left.CType);
      EmitPushXmm0(E.Left.CType);
      GenExprAsFloating(E.Right, E.Left.CType);
      EmitPopXmm1(E.Left.CType);
      case E.AssignOp of
        aoAdd: Op := boAdd;
        aoSub: Op := boSub;
        aoMul: Op := boMul;
        aoDiv: Op := boDiv;
      else
        RaiseCompileError(E.Pos,
          'floating compound assignment only supports +=, -=, *=, and /=');
      end;
      EmitFloatingBinary(Op, E.Left.CType);
    end;
    EmitPopRcx;
    EmitStoreRaxAtRcx(E.Left.CType);
    Exit;
  end;

  GenAddress(E.Left);
  EmitPushRax;
  if E.AssignOp = aoAssign then
  begin
    GenExpr(E.Right);
    EmitNormalizeInteger(E.Left.CType);
    EmitPopRcx;
    EmitStoreRaxAtRcx(E.Left.CType);
    Exit;
  end;
  EmitLoadAtRax(E.Left.CType);
  EmitPushRax;
  GenExpr(E.Right);
  Scale := 1;
  if IsPointerType(DecayType(E.Left.CType)) and
    (E.AssignOp in [aoAdd, aoSub]) then
  begin
    Scale := StorageSize(PointeeType(DecayType(E.Left.CType)));
    EmitScaleRax(Scale);
  end;
  FText.AddBytes([$48, $89, $C1]);
  FText.Add8($58);
  Dec(FStackDepth, 8);
  case E.AssignOp of
    aoAdd: Op := boAdd; aoSub: Op := boSub; aoMul: Op := boMul;
    aoDiv: Op := boDiv; aoMod: Op := boMod;
    aoBitAnd: Op := boBitAnd; aoBitOr: Op := boBitOr;
    aoBitXor: Op := boBitXor; aoShiftLeft: Op := boShiftLeft;
    aoShiftRight: Op := boShiftRight;
  else
    Op := boAdd;
  end;
  EmitBinaryOperation(Op, E.Left.CType.IsUnsigned);
  EmitNormalizeInteger(E.Left.CType);
  EmitPopRcx;
  EmitStoreRaxAtRcx(E.Left.CType);
end;

procedure TX64Backend.GenIncDec(E: TExpr; ADelta: LongInt; APost: Boolean);
var
  Delta: LongInt;
  OneType: TCType;
begin
  if E.Left.IsBitField then
  begin
    GenAddress(E.Left);
    EmitPushRax;
    EmitLoadBitField(E.Left.CType, E.Left.BitOffset, E.Left.BitWidth);
    if APost then EmitPushRax;
    EmitAddRaxImmediate(ADelta);
    EmitNormalizeInteger(E.Left.CType);
    if APost then
    begin
      FText.AddBytes([$48, $8B, $4C, $24, $08]);
      EmitStoreBitFieldAtRcx(E.Left.CType,
        E.Left.BitOffset, E.Left.BitWidth);
      FText.Add8($58);
      Dec(FStackDepth, 8);
      FText.AddBytes([$48, $83, $C4, $08]);
      Dec(FStackDepth, 8);
    end
    else
    begin
      EmitPopRcx;
      EmitStoreBitFieldAtRcx(E.Left.CType,
        E.Left.BitOffset, E.Left.BitWidth);
    end;
    Exit;
  end;

  if IsFloatingType(E.Left.CType) then
  begin
    GenAddress(E.Left);
    EmitPushRax;
    FText.AddBytes([$48, $8B, $04, $24]);
    EmitLoadAtRax(E.Left.CType);
    if APost then EmitPushXmm0(E.Left.CType);
    EmitPushXmm0(E.Left.CType);
    EmitMovRaxImm(1);
    OneType := E.Left.CType;
    EmitConvertIntegerToFloat(OneType);
    EmitPopXmm1(OneType);
    if ADelta > 0 then EmitFloatingBinary(boAdd, OneType)
    else EmitFloatingBinary(boSub, OneType);
    if APost then
    begin
      FText.AddBytes([$48, $8B, $4C, $24, $08]);
      EmitStoreRaxAtRcx(E.Left.CType);
      EmitPopXmm1(E.Left.CType);
      if E.Left.CType.Kind = ctFloat then
        FText.AddBytes([$F3, $0F, $10, $C1])
      else
        FText.AddBytes([$F2, $0F, $10, $C1]);
      FText.AddBytes([$48, $83, $C4, $08]);
      Dec(FStackDepth, 8);
    end
    else
    begin
      EmitPopRcx;
      EmitStoreRaxAtRcx(E.Left.CType);
    end;
    Exit;
  end;

  GenAddress(E.Left);
  FText.AddBytes([$48, $89, $C1]);
  EmitLoadAtRax(E.Left.CType);
  if APost then FText.AddBytes([$48, $89, $C2]);
  Delta := ADelta;
  if E.IntValue > 1 then Delta := Delta * LongInt(E.IntValue);
  EmitAddRaxImmediate(Delta);
  EmitNormalizeInteger(E.Left.CType);
  EmitStoreRaxAtRcx(E.Left.CType);
  if APost then FText.AddBytes([$48, $89, $D0]);
end;

function TX64Backend.TryGenPlainPrintf(E: TExpr): Boolean;
var
  I, LiteralStart, ArgumentIndex, L, CallLabel, Pad: LongInt;
  Text, LiteralText: string;
  Specifier: Char;
  Indirect: Boolean;

  procedure EmitAlignedCall(ALabel: LongInt; AIndirect: Boolean);
  begin
    Pad := 0;
    if (FStackDepth and 15) <> 0 then
    begin
      FText.AddBytes([$48, $83, $EC, $08]);
      Inc(FStackDepth, 8);
      Pad := 8;
    end;
    if AIndirect then EmitIndirectCall(ALabel)
    else EmitCall(ALabel);
    if Pad <> 0 then
    begin
      FText.AddBytes([$48, $83, $C4, $08]);
      Dec(FStackDepth, 8);
    end;
  end;

  procedure EmitLiteral(const AValue: string);
  begin
    if AValue = '' then Exit;
    L := AddStringLiteral(AValue);
    EmitMovRaxImm(1);
    EmitMoveRaxToArg(0);
    EmitAddressGlobal(L);
    EmitMoveRaxToArg(1);
    EmitMovRaxImm(Length(AValue));
    EmitMoveRaxToArg(2);
    CallLabel := ResolveCallable('write', E.Pos, Indirect);
    EmitAlignedCall(CallLabel, Indirect);
  end;

  procedure RequireArgument;
  begin
    if ArgumentIndex > High(E.Args) then
      RaiseCompileError(E.Pos, 'printf format requires more arguments');
  end;

begin
  Result := False;
  if E.Text <> 'printf' then Exit;
  if (Length(E.Args) = 0) or (E.Args[0] = nil) or
    (E.Args[0].Kind <> ekString) then Exit;

  Text := E.Args[0].Text;




  I := 1;
  while I <= Length(Text) do
  begin
    if Text[I] <> '%' then begin Inc(I); Continue; end;
    Inc(I);
    if I > Length(Text) then Exit(False);
    if Text[I] = '%' then begin Inc(I); Continue; end;
    if Text[I] in ['-', '+', ' ', '#', '0', '.', '1'..'9', '*'] then
      Exit(False);
    if Text[I] in ['h', 'l', 'j', 'z', 't', 'L'] then Exit(False);
    if not (Text[I] in ['d', 'i', 's', 'c']) then Exit(False);
    Inc(I);
  end;

  Result := True;
  I := 1;
  LiteralStart := 1;
  ArgumentIndex := 1;
  while I <= Length(Text) do
  begin
    if Text[I] <> '%' then
    begin
      Inc(I);
      Continue;
    end;

    LiteralText := Copy(Text, LiteralStart, I - LiteralStart);
    EmitLiteral(LiteralText);
    Inc(I);
    if I > Length(Text) then
      RaiseCompileError(E.Pos, 'unterminated printf conversion');
    if Text[I] = '%' then
    begin
      EmitLiteral('%');
      Inc(I);
      LiteralStart := I;
      Continue;
    end;

    if Text[I] in ['-', '+', ' ', '#', '0', '.', '1'..'9', '*'] then
      RaiseCompileError(E.Pos,
        'printf width, precision, and flags require a hosted libc call');
    while (I <= Length(Text)) and
      (Text[I] in ['h', 'l', 'j', 'z', 't']) do Inc(I);
    if I > Length(Text) then
      RaiseCompileError(E.Pos, 'unterminated printf conversion');
    Specifier := Text[I];
    RequireArgument;
    case Specifier of
      'd', 'i':
        begin
          GenExpr(E.Args[ArgumentIndex]);
          EmitMoveRaxToArg(0);
          CallLabel := ResolveCallable('__rcc_print_int_raw', E.Pos, Indirect);
          EmitAlignedCall(CallLabel, Indirect);
        end;
      's':
        begin
          GenExpr(E.Args[ArgumentIndex]);
          EmitMoveRaxToArg(0);
          CallLabel := ResolveCallable('__rcc_print_string', E.Pos, Indirect);
          EmitAlignedCall(CallLabel, Indirect);
        end;
      'c':
        begin
          GenExpr(E.Args[ArgumentIndex]);
          EmitMoveRaxToArg(0);
          CallLabel := ResolveCallable('putchar', E.Pos, Indirect);
          EmitAlignedCall(CallLabel, Indirect);
        end;
    else
      RaiseCompileError(E.Pos,
        'printf conversion %' + Specifier + ' requires a hosted libc call');
    end;
    Inc(ArgumentIndex);
    Inc(I);
    LiteralStart := I;
  end;
  EmitLiteral(Copy(Text, LiteralStart, MaxInt));
  if ArgumentIndex <= High(E.Args) then
    RaiseCompileError(E.Pos, 'printf has more arguments than conversions');
  EmitMovRaxImm(0);
end;

procedure TX64Backend.GenAggregateABICall(E: TExpr; ACallee: TFunction;
  const AFunctionType: TCType);
type
  TCTypeVector = array of TCType;
  TOffsetVector = array of LongInt;
var
  ParameterTypes: TCTypeVector;
  StageOffsets: TOffsetVector;
  Layout: TABIFunctionLayout;
  Location: TABIValueLocation;
  I, J, Size, Alignment, ReturnOffset, StackBytes, Pad, TotalStack,
    StackOffset, RegisterOrdinal, L, IntegerReturnIndex,
    SSEReturnIndex, CalleeOffset, FixedParameterCount: LongInt;
  Indirect, ExpressionCall, Variadic: Boolean;
  ExpectedType, ReturnType: TCType;

  function GPRegisterOrdinal(ARegisterNumber: LongInt): LongInt;
  begin
    case ARegisterNumber of
      7: Result := 0;
      6: Result := 1;
      2: Result := 2;
      1: Result := 3;
      8: Result := 4;
      9: Result := 5;
    else
      raise ERCCError.Create('internal error: invalid SysV integer argument register');
    end;
  end;

  procedure EmitLoadXmmFromLocal(ARegister, AOffset: LongInt;
    const AType: TCType);
  var
    Prefix: Byte;
  begin
    if (ARegister < 0) or (ARegister > 7) then
      raise ERCCError.Create('internal error: invalid SysV SSE argument register');
    if AType.Kind = ctFloat then Prefix := $F3 else Prefix := $F2;
    FText.Add8(Prefix);
    FText.AddBytes([$0F, $10, Byte($85 or (ARegister shl 3))]);
    FText.AddI32(-AOffset);
  end;

  procedure EmitLoadAggregateXmm(ARegister, AOffset,
    APartOffset: LongInt);
  begin
    if (ARegister < 0) or (ARegister > 7) then
      raise ERCCError.Create('internal error: invalid aggregate SSE register');
    FText.Add8($F3);
    FText.AddBytes([$0F, $7E, Byte($85 or (ARegister shl 3))]);
    FText.AddI32(-AOffset + APartOffset);
  end;

  procedure EmitStoreReturnXmm(ARegister, AOffset,
    APartOffset: LongInt);
  begin
    if (ARegister < 0) or (ARegister > 1) then
      raise ERCCError.Create('internal error: invalid aggregate SSE return register');
    FText.Add8($66);
    FText.AddBytes([$0F, $D6, Byte($85 or (ARegister shl 3))]);
    FText.AddI32(-AOffset + APartOffset);
  end;

  procedure EmitStackAddress(AOffset: LongInt);
  begin
    if (AOffset >= 0) and (AOffset <= 127) then
      FText.AddBytes([$48, $8D, $44, $24, Byte(AOffset)])
    else
    begin
      FText.AddBytes([$48, $8D, $84, $24]);
      FText.AddI32(AOffset);
    end;
  end;

  procedure EmitStoreRaxToStack(AOffset: LongInt);
  begin
    if (AOffset >= 0) and (AOffset <= 127) then
      FText.AddBytes([$48, $89, $44, $24, Byte(AOffset)])
    else
    begin
      FText.AddBytes([$48, $89, $84, $24]);
      FText.AddI32(AOffset);
    end;
  end;

  procedure EmitCopyRaxToLocal(ADestinationOffset, ASize: LongInt);
  begin
    FText.AddBytes([$48, $89, $C6]);
    EmitAddressLocal(ADestinationOffset);
    FText.AddBytes([$48, $89, $C7]);
    EmitMovRaxImm(ASize);
    FText.AddBytes([$48, $89, $C1]);
    FText.AddBytes([$F3, $A4]);
  end;

  procedure EmitCopyLocalToStack(ASourceOffset, ADestinationOffset,
    ASize: LongInt);
  begin
    EmitAddressLocal(ASourceOffset);
    FText.AddBytes([$48, $89, $C6]);
    EmitStackAddress(ADestinationOffset);
    FText.AddBytes([$48, $89, $C7]);
    EmitMovRaxImm(ASize);
    FText.AddBytes([$48, $89, $C1]);
    FText.AddBytes([$F3, $A4]);
  end;

begin
  ExpressionCall := ACallee = nil;
  if ExpressionCall then
  begin
    if not HasFunctionSignature(AFunctionType) then
      raise ERCCError.Create(
        'internal error: indirect call reached the backend without a function signature');
    ReturnType := FunctionReturnTypeOf(AFunctionType);
    FixedParameterCount := FunctionParameterCount(AFunctionType);
    Variadic := FunctionIsVariadic(AFunctionType);
    ReserveTemporary(8, 8, CalleeOffset);
    GenExpr(E.Left);
    EmitStoreLocal(CalleeOffset);
  end
  else
  begin
    ReturnType := ACallee.ReturnType;
    FixedParameterCount := Length(ACallee.Params);
    Variadic := ACallee.IsVariadic;
    CalleeOffset := 0;
  end;
  SetLength(ParameterTypes, Length(E.Args));
  for I := 0 to High(E.Args) do
  begin
    if I < FixedParameterCount then
    begin
      if ExpressionCall then
        ParameterTypes[I] := FunctionParameterType(AFunctionType, I)
      else
        ParameterTypes[I] := ACallee.Params[I].CType;
    end
    else
      ParameterTypes[I] := E.Args[I].CType;
    ParameterTypes[I] := DecayType(ParameterTypes[I]);
    if Variadic and (I >= FixedParameterCount) and
      (ParameterTypes[I].Kind = ctFloat) and
      (ParameterTypes[I].PointerDepth = 0) then
      ParameterTypes[I] := MakeType(ctDouble);
  end;
  Layout := BuildFunctionABILayout(ReturnType, ParameterTypes,
    Variadic, NativeTargetDescriptor);
  try
    SetLength(StageOffsets, Length(E.Args));
    for I := 0 to High(E.Args) do
    begin
      ExpectedType := ParameterTypes[I];
      if IsAggregateType(ExpectedType) then
      begin
        Size := LongInt(AlignUp(QWord(StorageSize(ExpectedType)), 8));
        Alignment := StorageAlign(ExpectedType);
      end
      else
      begin
        Size := 8;
        Alignment := 8;
      end;
      ReserveTemporary(Size, Alignment, StageOffsets[I]);
    end;
    ReturnOffset := 0;
    if IsAggregateType(ReturnType) then
    begin
      Size := LongInt(AlignUp(QWord(StorageSize(ReturnType)), 8));
      ReserveTemporary(Size, StorageAlign(ReturnType), ReturnOffset);
    end;




    for I := 0 to High(E.Args) do
    begin
      ExpectedType := ParameterTypes[I];
      if IsAggregateType(ExpectedType) then
      begin
        GenExpr(E.Args[I]);
        EmitCopyRaxToLocal(StageOffsets[I], StorageSize(ExpectedType));
      end
      else if IsFloatingType(ExpectedType) then
      begin
        GenExprAsFloating(E.Args[I], ExpectedType);
        EmitAddressLocal(StageOffsets[I]);
        FText.AddBytes([$48, $89, $C1]);
        EmitStoreRaxAtRcx(ExpectedType);
      end
      else
      begin
        GenExpr(E.Args[I]);
        EmitStoreLocal(StageOffsets[I]);
      end;
    end;

    StackBytes := LongInt(Layout.StackArgumentBytes);
    Pad := (16 - ((FStackDepth + StackBytes) and 15)) and 15;
    TotalStack := StackBytes + Pad;
    if TotalStack > 0 then
    begin
      if TotalStack <= 127 then
        FText.AddBytes([$48, $83, $EC, Byte(TotalStack)])
      else
      begin
        FText.AddBytes([$48, $81, $EC]);
        FText.AddI32(TotalStack);
      end;
      Inc(FStackDepth, TotalStack);
    end;


    for I := 0 to High(E.Args) do
    begin
      Location := Layout.Parameters[I];
      if Location.Kind <> alkStack then Continue;
      StackOffset := LongInt(Location.Parts[0].StackOffset);
      if IsAggregateType(ParameterTypes[I]) then
        EmitCopyLocalToStack(StageOffsets[I], StackOffset,
          StorageSize(ParameterTypes[I]))
      else
      begin
        EmitLoadLocal(StageOffsets[I]);
        EmitStoreRaxToStack(StackOffset);
      end;
    end;

    if Layout.UsesHiddenReturnPointer then
    begin
      EmitAddressLocal(ReturnOffset);
      EmitMoveRaxToArg(0);
    end;

    for I := 0 to High(E.Args) do
    begin
      Location := Layout.Parameters[I];
      if Location.Kind = alkStack then Continue;
      if IsAggregateType(ParameterTypes[I]) then
      begin
        for J := 0 to High(Location.Parts) do
          if Location.Parts[J].ValueClass = ascInteger then
          begin
            EmitAddressLocal(StageOffsets[I]);
            EmitAddRaxImmediate(J * 8);
            FText.AddBytes([$48, $8B, $00]);
            RegisterOrdinal := GPRegisterOrdinal(
              Location.Parts[J].RegisterNumber);
            EmitMoveRaxToArg(RegisterOrdinal);
          end
          else if Location.Parts[J].ValueClass in [ascSSE, ascSSEUp] then
            EmitLoadAggregateXmm(Location.Parts[J].RegisterNumber,
              StageOffsets[I], J * 8)
          else
            raise ERCCError.Create('internal error: unsupported aggregate ABI class');
      end
      else if IsFloatingType(ParameterTypes[I]) then
        EmitLoadXmmFromLocal(Location.Parts[0].RegisterNumber,
          StageOffsets[I], ParameterTypes[I])
      else
      begin
        EmitLoadLocal(StageOffsets[I]);
        RegisterOrdinal := GPRegisterOrdinal(
          Location.Parts[0].RegisterNumber);
        EmitMoveRaxToArg(RegisterOrdinal);
      end;
    end;

    if ExpressionCall then
    begin
      FText.AddBytes([$4C, $8B, $9D]);
      FText.AddI32(-CalleeOffset);
      FText.Add8($B8);
      FText.Add32(LongWord(Layout.FloatingRegistersUsed));
      FText.AddBytes([$41, $FF, $D3]);
    end
    else
    begin
      FText.Add8($B8);
      FText.Add32(LongWord(Layout.FloatingRegistersUsed));
      L := ResolveCallable(ACallee.Name, E.Pos, Indirect);
      if Indirect then EmitIndirectCall(L) else EmitCall(L);
    end;

    if TotalStack > 0 then
    begin
      if TotalStack <= 127 then
        FText.AddBytes([$48, $83, $C4, Byte(TotalStack)])
      else
      begin
        FText.AddBytes([$48, $81, $C4]);
        FText.AddI32(TotalStack);
      end;
      Dec(FStackDepth, TotalStack);
    end;

    if IsAggregateType(ReturnType) then
    begin
      if not Layout.UsesHiddenReturnPointer then
      begin
        IntegerReturnIndex := 0;
        SSEReturnIndex := 0;
        for J := 0 to High(Layout.ReturnLocation.Parts) do
          if Layout.ReturnLocation.Parts[J].ValueClass = ascInteger then
          begin
            if IntegerReturnIndex = 0 then
              FText.AddBytes([$48, $89, $85])
            else
              FText.AddBytes([$48, $89, $95]);
            FText.AddI32(-ReturnOffset + J * 8);
            Inc(IntegerReturnIndex);
          end
          else if Layout.ReturnLocation.Parts[J].ValueClass in
            [ascSSE, ascSSEUp] then
          begin
            EmitStoreReturnXmm(SSEReturnIndex, ReturnOffset, J * 8);
            Inc(SSEReturnIndex);
          end;
      end;
      EmitAddressLocal(ReturnOffset);
    end;
  finally
    Layout.Free;
  end;
end;

procedure TX64Backend.GenAggregateReturn(E: TExpr);
var
  Location: TABIValueLocation;
  J, IntegerIndex, SSEIndex: LongInt;
begin
  if E = nil then
    raise ERCCError.Create('internal error: aggregate return requires a value');
  GenExpr(E);
  if FCurrentUsesSRet then
  begin
    FText.AddBytes([$48, $89, $C6]);
    EmitLoadLocal(FCurrentSRetOffset);
    FText.AddBytes([$48, $89, $C7]);
    EmitMovRaxImm(StorageSize(FCurrentReturnType));
    FText.AddBytes([$48, $89, $C1]);
    FText.AddBytes([$F3, $A4]);
    EmitLoadLocal(FCurrentSRetOffset);
    Exit;
  end;

  Location := ClassifyCTypeForABI(FCurrentReturnType,
    NativeTargetDescriptor);
  FText.AddBytes([$48, $89, $C1]);
  IntegerIndex := 0;
  SSEIndex := 0;
  for J := 0 to High(Location.Parts) do
    if Location.Parts[J].ValueClass = ascInteger then
    begin
      if IntegerIndex = 0 then
        FText.AddBytes([$48, $8B, $81])
      else
        FText.AddBytes([$48, $8B, $91]);
      FText.AddI32(J * 8);
      Inc(IntegerIndex);
    end
    else if Location.Parts[J].ValueClass in [ascSSE, ascSSEUp] then
    begin
      FText.Add8($F3);
      FText.AddBytes([$0F, $7E, Byte($81 or (SSEIndex shl 3))]);
      FText.AddI32(J * 8);
      Inc(SSEIndex);
    end
    else
      raise ERCCError.Create('internal error: unsupported aggregate return class');
end;

function TX64Backend.TryGenVariadicBuiltin(E: TExpr): Boolean;
var
  RequestedType: TCType;
  Location: TABIValueLocation;
  StateOffset, SourceOffset, ReturnOffset, StackLabel, DoneLabel: LongInt;
  I, NeededGP, NeededFP, GPLimit, FPLimit, StackSlot, Alignment: LongInt;
  IsAggregate, RegisterEligible: Boolean;

  procedure LoadStatePointer;
  begin
    EmitLoadLocal(StateOffset);
    FText.AddBytes([$48, $89, $C1]);
  end;

  procedure EmitAddRdxImmediate(AValue: LongInt);
  begin
    if AValue = 0 then Exit;
    if (AValue >= -128) and (AValue <= 127) then
      FText.AddBytes([$48, $83, $C2, Byte(LongWord(AValue) and $FF)])
    else
    begin
      FText.AddBytes([$48, $81, $C2]);
      FText.AddI32(AValue);
    end;
  end;

  procedure EmitRegisterPartAddress(AClass: TABIScalarClass);
  begin
    LoadStatePointer;
    if AClass in [ascSSE, ascSSEUp] then
    begin
      FText.AddBytes([$8B, $51, $04]);
      FText.AddBytes([$83, $41, $04, $10]);
    end
    else
    begin
      FText.AddBytes([$8B, $11]);
      FText.AddBytes([$83, $01, $08]);
    end;
    FText.AddBytes([$48, $8B, $41, $10]);
    FText.AddBytes([$48, $01, $D0]);
  end;

  procedure EmitOverflowAddress;
  begin
    LoadStatePointer;
    FText.AddBytes([$48, $8B, $41, $08]);
    Alignment := StorageAlign(RequestedType);
    if Alignment > 8 then
    begin
      EmitAddRaxImmediate(Alignment - 1);
      FText.AddBytes([$48, $83, $E0,
        Byte(LongWord(-Alignment) and $FF)]);
    end;
    FText.AddBytes([$48, $89, $C2]);
    StackSlot := LongInt(AlignUp(QWord(StorageSize(RequestedType)), 8));
    EmitAddRdxImmediate(StackSlot);
    FText.AddBytes([$48, $89, $51, $08]);
  end;

begin
  Result := False;
  if (E = nil) or not ((E.Text = '__builtin_va_start') or
     (E.Text = '__builtin_va_arg') or
     (E.Text = '__builtin_va_copy') or
     (E.Text = '__builtin_va_end')) then Exit;
  Result := True;

  if E.Text = '__builtin_va_start' then
  begin
    if not FCurrentIsVariadic then
      RaiseCompileError(E.Pos,
        'va_start is valid only inside a variadic function');
    GenExpr(E.Args[0]);
    FText.AddBytes([$48, $89, $C1]);
    FText.AddBytes([$C7, $01]);
    FText.Add32(LongWord(FCurrentVarArgGPOffset));
    FText.AddBytes([$C7, $41, $04]);
    FText.Add32(LongWord(FCurrentVarArgFPOffset));
    FText.AddBytes([$48, $8D, $85]);
    FText.AddI32(16 + FCurrentVarArgStackOffset);
    FText.AddBytes([$48, $89, $41, $08]);
    EmitAddressLocal(FCurrentVarArgSaveOffset);
    FText.AddBytes([$48, $89, $41, $10]);
    EmitMovRaxImm(0);
    Exit;
  end;

  if E.Text = '__builtin_va_copy' then
  begin
    ReserveTemporary(8, 8, SourceOffset);
    GenExpr(E.Args[1]);
    EmitStoreLocal(SourceOffset);
    GenExpr(E.Args[0]);
    FText.AddBytes([$48, $89, $C7]);
    EmitLoadLocal(SourceOffset);
    FText.AddBytes([$48, $89, $C6]);
    EmitMovRaxImm(24);
    FText.AddBytes([$48, $89, $C1]);
    FText.AddBytes([$F3, $A4]);
    EmitMovRaxImm(0);
    Exit;
  end;

  if E.Text = '__builtin_va_end' then
  begin
    GenExpr(E.Args[0]);
    EmitMovRaxImm(0);
    Exit;
  end;

  RequestedType := E.CType;
  IsAggregate := IsAggregateType(RequestedType);
  Location := ClassifyCTypeForABI(RequestedType, NativeTargetDescriptor);
  ReserveTemporary(8, 8, StateOffset);
  GenExpr(E.Args[0]);
  EmitStoreLocal(StateOffset);

  NeededGP := 0;
  NeededFP := 0;
  RegisterEligible := Location.Kind <> alkStack;
  for I := 0 to High(Location.Parts) do
    if Location.Parts[I].ValueClass in [ascSSE, ascSSEUp] then
      Inc(NeededFP)
    else if Location.Parts[I].ValueClass = ascInteger then
      Inc(NeededGP)
    else
      RegisterEligible := False;

  ReturnOffset := 0;
  if IsAggregate and RegisterEligible then
    ReserveTemporary(LongInt(AlignUp(QWord(StorageSize(RequestedType)), 8)),
      StorageAlign(RequestedType), ReturnOffset);

  if RegisterEligible then
  begin
    StackLabel := NewLabel;
    DoneLabel := NewLabel;
    GPLimit := 48 - NeededGP * 8;
    FPLimit := 176 - NeededFP * 16;
    LoadStatePointer;
    if NeededGP > 0 then
    begin
      FText.AddBytes([$83, $39, Byte(GPLimit)]);
      EmitJcc($87, StackLabel);
    end;
    if NeededFP > 0 then
    begin
      FText.AddBytes([$81, $79, $04]);
      FText.AddI32(FPLimit);
      EmitJcc($87, StackLabel);
    end;

    if IsAggregate then
    begin
      for I := 0 to High(Location.Parts) do
      begin
        EmitRegisterPartAddress(Location.Parts[I].ValueClass);
        FText.AddBytes([$48, $8B, $00]);
        EmitStoreLocal(ReturnOffset - I * 8);
      end;
      EmitAddressLocal(ReturnOffset);
    end
    else
    begin
      EmitRegisterPartAddress(Location.Parts[0].ValueClass);
      EmitLoadAtRax(RequestedType);
    end;
    EmitJump(DoneLabel);
    BindTextLabel(StackLabel);
    EmitOverflowAddress;
    if not IsAggregate then EmitLoadAtRax(RequestedType);
    BindTextLabel(DoneLabel);
  end
  else
  begin
    EmitOverflowAddress;
    if not IsAggregate then EmitLoadAtRax(RequestedType);
  end;
end;

procedure TX64Backend.GenCall(E: TExpr);
var
  I, L, Pad, StackArgs, RegisterArgs, Cleanup, CalleeOffset: LongInt;
  GPCount, FPCount, StagedBytes, ArgOffset: LongInt;
  Indirect, ExpressionCall, UseMixedABI, ExpectedFloating: Boolean;
  CalleeDecl: TFunction;
  ExpectedType: TCType;

  procedure GenerateArgument(AIndex: LongInt);
  begin
    if (CalleeDecl <> nil) and (AIndex <= High(CalleeDecl.Params)) and
      IsAggregateType(CalleeDecl.Params[AIndex].CType) then
      GenAddress(E.Args[AIndex])
    else
      GenExpr(E.Args[AIndex]);
  end;

  function ExpectedArgumentType(AIndex: LongInt): TCType;
  begin
    if (CalleeDecl <> nil) and (AIndex <= High(CalleeDecl.Params)) then
      Result := CalleeDecl.Params[AIndex].CType
    else
      Result := E.Args[AIndex].CType;

    Result := DecayType(Result);

    if (CalleeDecl <> nil) and CalleeDecl.IsVariadic and
      (AIndex > High(CalleeDecl.Params)) and (Result.Kind = ctFloat) and
      (Result.PointerDepth = 0) then
      Result := MakeType(ctDouble);
  end;

  procedure LoadGPArgument(ARegisterIndex, AOffset: LongInt);
  begin
    if (AOffset >= -128) and (AOffset <= 127) then
      FText.AddBytes([$48, $8B, $44, $24, Byte(AOffset)])
    else
    begin
      FText.AddBytes([$48, $8B, $84, $24]);
      FText.AddI32(AOffset);
    end;
    EmitMoveRaxToArg(ARegisterIndex);
  end;

  procedure GenerateMixedArgument(AIndex: LongInt);
  begin
    ExpectedType := ExpectedArgumentType(AIndex);
    if IsAggregateType(ExpectedType) then
      GenAddress(E.Args[AIndex])
    else if IsFloatingType(ExpectedType) then
      GenExprAsFloating(E.Args[AIndex], ExpectedType)
    else
      GenExpr(E.Args[AIndex]);
  end;

begin
  if TryGenVariadicBuiltin(E) then Exit;
  if TryGenPlainPrintf(E) then Exit;
  CalleeDecl := nil;
  if E.Text <> '' then
    for I := High(FProgram.Functions) downto 0 do
      if FProgram.Functions[I].Name = E.Text then
      begin
        CalleeDecl := FProgram.Functions[I];
        Break;
      end;
  if CalleeDecl <> nil then
  begin
    GenAggregateABICall(E, CalleeDecl, MakeType(ctVoid));
    Exit;
  end;
  ExpressionCall := E.Text = '';
  if ExpressionCall then
  begin
    ExpectedType := DecayType(E.Left.CType);
    if IsPointerType(ExpectedType) then
      ExpectedType := PointeeType(ExpectedType);
    if (ExpectedType.Kind = ctFunction) and
      HasFunctionSignature(ExpectedType) then
    begin
      GenAggregateABICall(E, nil, ExpectedType);
      Exit;
    end;
  end;

  UseMixedABI := False;
  for I := 0 to High(E.Args) do
  begin
    ExpectedFloating := False;
    if (CalleeDecl <> nil) and (I <= High(CalleeDecl.Params)) then
      ExpectedFloating := IsFloatingType(CalleeDecl.Params[I].CType);
    if IsFloatingType(E.Args[I].CType) or ExpectedFloating then
      UseMixedABI := True;
  end;

  if UseMixedABI then
  begin
    if ExpressionCall then
    begin
      GenExpr(E.Left);
      EmitPushRax;
    end;





    Pad := 0;
    StagedBytes := Length(E.Args) * 8;
    if ((FStackDepth + StagedBytes) and 15) <> 0 then
    begin
      FText.AddBytes([$48, $83, $EC, $08]);
      Inc(FStackDepth, 8);
      Pad := 8;
    end;
    for I := High(E.Args) downto 0 do
    begin
      ExpectedType := ExpectedArgumentType(I);
      GenerateMixedArgument(I);
      if IsFloatingType(ExpectedType) then EmitPushXmm0(ExpectedType)
      else EmitPushRax;
    end;

    GPCount := 0;
    FPCount := 0;
    for I := 0 to High(E.Args) do
    begin
      ExpectedType := ExpectedArgumentType(I);
      ArgOffset := I * 8;
      if IsFloatingType(ExpectedType) then
      begin
        if FPCount >= 8 then
          RaiseCompileError(E.Pos,
            'calls with more than eight SSE register arguments exceed the current ABI lowering limit');
        EmitLoadXmmFromStack(FPCount, ArgOffset, ExpectedType);
        Inc(FPCount);
      end
      else
      begin
        if GPCount >= 6 then
          RaiseCompileError(E.Pos,
            'mixed floating calls with stack-class integer arguments exceed the current ABI lowering limit');
        LoadGPArgument(GPCount, ArgOffset);
        Inc(GPCount);
      end;
    end;




    FText.Add8($B8);
    FText.Add32(LongWord(FPCount));

    if ExpressionCall then
    begin
      CalleeOffset := StagedBytes + Pad;
      if CalleeOffset <= 127 then
        FText.AddBytes([$4C, $8B, $5C, $24, Byte(CalleeOffset)])
      else
      begin
        FText.AddBytes([$4C, $8B, $9C, $24]);
        FText.AddI32(CalleeOffset);
      end;
      FText.AddBytes([$41, $FF, $D3]);
      Indirect := True;
    end
    else
    begin
      L := ResolveCallable(E.Text, E.Pos, Indirect);
      if Indirect then EmitIndirectCall(L) else EmitCall(L);
    end;

    Cleanup := StagedBytes + Pad;
    if ExpressionCall then Inc(Cleanup, 8);
    if Cleanup > 0 then
    begin
      if Cleanup <= 127 then
        FText.AddBytes([$48, $83, $C4, Byte(Cleanup)])
      else
      begin
        FText.AddBytes([$48, $81, $C4]);
        FText.AddI32(Cleanup);
      end;
      Dec(FStackDepth, Cleanup);
    end;
    Exit;
  end;


  if ExpressionCall then
  begin
    GenExpr(E.Left);
    EmitPushRax;
  end;

  StackArgs := Length(E.Args) - 6;
  if StackArgs < 0 then StackArgs := 0;
  RegisterArgs := Length(E.Args);
  if RegisterArgs > 6 then RegisterArgs := 6;

  Pad := 0;
  if ((FStackDepth + StackArgs * 8) and 15) <> 0 then
  begin
    FText.AddBytes([$48, $83, $EC, $08]);
    Inc(FStackDepth, 8);
    Pad := 8;
  end;

  for I := High(E.Args) downto 6 do
  begin
    GenerateArgument(I);
    EmitPushRax;
  end;

  for I := 0 to RegisterArgs - 1 do
  begin
    GenerateArgument(I);
    EmitPushRax;
  end;
  for I := RegisterArgs - 1 downto 0 do EmitPopArg(I);

  if ExpressionCall then
  begin
    CalleeOffset := StackArgs * 8 + Pad;
    if CalleeOffset <= 127 then
      FText.AddBytes([$4C, $8B, $5C, $24, Byte(CalleeOffset)])
    else
    begin
      FText.AddBytes([$4C, $8B, $9C, $24]);
      FText.AddI32(CalleeOffset);
    end;
    FText.AddBytes([$31, $C0]);
    FText.AddBytes([$41, $FF, $D3]);
    Indirect := True;
  end
  else
  begin
    L := ResolveCallable(E.Text, E.Pos, Indirect);
    if Indirect then
    begin
      FText.AddBytes([$31, $C0]);
      EmitIndirectCall(L);
    end
    else
      EmitCall(L);
  end;

  Cleanup := StackArgs * 8 + Pad;
  if ExpressionCall then Inc(Cleanup, 8);
  if Cleanup > 0 then
  begin
    if Cleanup <= 127 then
      FText.AddBytes([$48, $83, $C4, Byte(Cleanup)])
    else
    begin
      FText.AddBytes([$48, $81, $C4]);
      FText.AddI32(Cleanup);
    end;
    Dec(FStackDepth, Cleanup);
  end;
end;

procedure TX64Backend.GenExpr(E: TExpr);
var
  Offset, L, FalseLabel, EndLabel, I, Scale: LongInt;
  Handled, IsPointerResult, IsPointerDifference, UnsignedOperation: Boolean;
  LocalType: TCType;
  GlobalDecl: TGlobal;
  IndirectLocal: Boolean;
begin
  if E = nil then
  begin
    EmitMovRaxImm(0);
    Exit;
  end;
  case E.Kind of
    ekInteger: EmitMovRaxImm(E.IntValue);
    ekTrap:
      begin
        FText.AddBytes([$0F, $0B]);
      end;
    ekFloat:
      begin
        L := AddFloatLiteral(E.FloatValue, E.CType);
        EmitAddressGlobal(L);
        EmitLoadAtRax(E.CType);
      end;
    ekString:
      begin
        L := AddStringLiteral(E.Text);
        EmitAddressGlobal(L);
      end;
    ekVariable:
      begin
        if E.IsFunctionDesignator then
        begin
          L := FindNamedLabel(FFunctions, E.Text);
          if L >= 0 then
          begin
            EmitAddressGlobal(L);
            Exit;
          end;
          for I := 0 to High(FRuntime) do
            if FRuntime[I].Name = E.Text then
            begin
              FRuntimeUsed[I] := True;
              EmitAddressGlobal(FRuntime[I].LabelID);
              Exit;
            end;
          L := EnsureExternalImport(E.Text, E.Pos);
          if FOptions.EmitMode = emObject then EmitObjectGOTLoad(L)
          else EmitLoadGlobal(L);
          Exit;
        end;
        if FindLocal(E.Text, Offset, LocalType, IndirectLocal) then
        begin
          if IndirectLocal then EmitLoadLocal(Offset)
          else EmitAddressLocal(Offset);
          if not IsAggregateType(E.CType) then EmitLoadAtRax(E.CType);
        end
        else
        begin
          L := FindGlobalLabel(E.Text);
          if L >= 0 then
            EmitAddressGlobal(L)
          else
          begin
            GlobalDecl := FindGlobal(E.Text);
            if (GlobalDecl = nil) or not GlobalDecl.IsExtern then
              RaiseCompileError(E.Pos, 'unknown variable ''' + E.Text + '''');
            L := EnsureExternalObject(E.Text, E.Pos);
            if FOptions.EmitMode = emObject then EmitObjectGOTLoad(L)
            else EmitLoadGlobal(L);
          end;
          if not IsAggregateType(E.CType) then EmitLoadAtRax(E.CType);
        end;
      end;
    ekAddress: GenAddress(E.Left);
    ekDeref, ekIndex, ekMember, ekArrow:
      begin
        GenAddress(E);
        if E.IsBitField then
          EmitLoadBitField(E.CType, E.BitOffset, E.BitWidth)
        else if not IsAggregateType(E.CType) and not IsFunctionType(E.CType) then
          EmitLoadAtRax(E.CType);
      end;
    ekUnary:
      begin
        GenExpr(E.Left);
        if IsFloatingType(E.Left.CType) then
        begin
          case E.UnaryOp of
            uoPositive: ;
            uoNegative:
              begin
                if E.Left.CType.Kind = ctFloat then
                begin
                  FText.AddBytes([$0F, $57, $C9]);
                  FText.AddBytes([$F3, $0F, $5C, $C8]);
                  FText.AddBytes([$F3, $0F, $10, $C1]);
                end
                else
                begin
                  FText.AddBytes([$66, $0F, $57, $C9]);
                  FText.AddBytes([$F2, $0F, $5C, $C8]);
                  FText.AddBytes([$F2, $0F, $10, $C1]);
                end;
              end;
            uoLogicalNot:
              begin
                EmitFloatToBool(E.Left.CType);
                FText.AddBytes([$83, $F0, $01]);
              end;
          else
            RaiseCompileError(E.Pos,
              'bitwise complement is invalid for floating operands');
          end;
        end
        else
          case E.UnaryOp of
            uoPositive: ;
            uoNegative: FText.AddBytes([$48, $F7, $D8]);
            uoLogicalNot:
              begin
                FText.AddBytes([$48, $85, $C0]);
                EmitSetCC($94);
              end;
            uoBitwiseNot: FText.AddBytes([$48, $F7, $D0]);
          end;
        EmitNormalizeInteger(E.CType);
      end;
    ekBinary:
      begin
        if E.BinaryOp = boComma then
        begin
          GenExpr(E.Left);
          GenExpr(E.Right);
          Exit;
        end;
        if E.BinaryOp = boLogicalAnd then
        begin
          FalseLabel := NewLabel; EndLabel := NewLabel;
          GenCondition(E.Left);
          FText.AddBytes([$48, $85, $C0]);
          EmitJcc($84, FalseLabel);
          GenCondition(E.Right);
          EmitJump(EndLabel);
          BindTextLabel(FalseLabel);
          EmitMovRaxImm(0);
          BindTextLabel(EndLabel);
          Exit;
        end;
        if E.BinaryOp = boLogicalOr then
        begin
          EndLabel := NewLabel;
          FalseLabel := NewLabel;
          GenCondition(E.Left);
          FText.AddBytes([$48, $85, $C0]);
          EmitJcc($84, FalseLabel);
          EmitMovRaxImm(1);
          EmitJump(EndLabel);
          BindTextLabel(FalseLabel);
          GenCondition(E.Right);
          BindTextLabel(EndLabel);
          Exit;
        end;

        if IsFloatingType(E.Left.CType) or IsFloatingType(E.Right.CType) then
        begin
          if IsFloatingType(E.Left.CType) and
            (E.Left.CType.Kind in [ctDouble, ctLongDouble]) then
            LocalType := E.Left.CType
          else if IsFloatingType(E.Right.CType) and
            (E.Right.CType.Kind in [ctDouble, ctLongDouble]) then
            LocalType := E.Right.CType
          else
            LocalType := MakeType(ctFloat);
          GenExprAsFloating(E.Left, LocalType);
          EmitPushXmm0(LocalType);
          GenExprAsFloating(E.Right, LocalType);
          EmitPopXmm1(LocalType);
          EmitFloatingBinary(E.BinaryOp, LocalType);
          Exit;
        end;

        IsPointerResult := IsPointerType(DecayType(E.CType)) and
          (E.BinaryOp in [boAdd, boSub]) and (E.IntValue > 0);
        IsPointerDifference := (E.BinaryOp = boSub) and
          IsPointerType(DecayType(E.Left.CType)) and
          IsPointerType(DecayType(E.Right.CType)) and (E.IntValue > 0);
        Scale := LongInt(E.IntValue);
        if Scale < 1 then Scale := 1;





        LocalType := E.OperationType;
        case E.BinaryOp of
          boShiftRight:
            UnsignedOperation := LocalType.IsUnsigned;
          boEqual, boNotEqual:
            UnsignedOperation := False;
          boLess, boLessEqual, boGreater, boGreaterEqual:
            UnsignedOperation := IsPointerType(LocalType) or
              LocalType.IsUnsigned;
        else
          UnsignedOperation := E.CType.IsUnsigned;
        end;

        if (FOptions.OptimizationLevel >= 1) and
          (E.Right <> nil) and (E.Right.Kind = ekInteger) and
          not IsPointerDifference and
          (not IsIntegerType(LocalType) or
            ((StorageSize(E.Right.CType) = StorageSize(LocalType)) and
             (E.Right.CType.IsUnsigned = LocalType.IsUnsigned))) then
        begin
          GenExpr(E.Left);
          if IsIntegerType(LocalType) then EmitNormalizeInteger(LocalType);
          if IsPointerResult then
            EmitImmediateOperation(E.BinaryOp, E.Right.IntValue * Scale,
              UnsignedOperation, Handled)
          else
            EmitImmediateOperation(E.BinaryOp, E.Right.IntValue,
              UnsignedOperation, Handled);
          if Handled then
          begin
            EmitNormalizeInteger(E.CType);
            Exit;
          end;
        end;
        GenExpr(E.Left);
        if IsIntegerType(LocalType) then EmitNormalizeInteger(LocalType);
        EmitPushRax;
        GenExpr(E.Right);
        if IsIntegerType(LocalType) and
          not (E.BinaryOp in [boShiftLeft, boShiftRight]) then
          EmitNormalizeInteger(LocalType);
        if IsPointerResult then EmitScaleRax(Scale);
        FText.AddBytes([$48, $89, $C1]);
        FText.Add8($58);
        Dec(FStackDepth, 8);
        EmitBinaryOperation(E.BinaryOp, UnsignedOperation);
        if IsPointerDifference and (Scale > 1) then
        begin
          FText.AddBytes([$48, $C7, $C1]);
          FText.AddI32(Scale);
          FText.AddBytes([$48, $99, $48, $F7, $F9]);
        end;
        EmitNormalizeInteger(E.CType);
      end;
    ekAssign: GenAssignment(E);
    ekCall:
      begin
        GenCall(E);
        EmitNormalizeInteger(E.CType);
      end;
    ekConditional:
      begin
        FalseLabel := NewLabel; EndLabel := NewLabel;
        GenCondition(E.Left);
        FText.AddBytes([$48, $85, $C0]);
        EmitJcc($84, FalseLabel);
        GenExpr(E.Right);
        EmitJump(EndLabel);
        BindTextLabel(FalseLabel);
        GenExpr(E.Third);
        BindTextLabel(EndLabel);
        EmitNormalizeInteger(E.CType);
      end;
    ekPreInc: GenIncDec(E, 1, False);
    ekPreDec: GenIncDec(E, -1, False);
    ekPostInc: GenIncDec(E, 1, True);
    ekPostDec: GenIncDec(E, -1, True);
    ekCast:
      begin
        GenExpr(E.Left);
        if IsFloatingType(E.CType) then
        begin
          if IsFloatingType(E.Left.CType) then
            EmitConvertFloatWidth(E.Left.CType, E.CType)
          else
            EmitConvertIntegerToFloat(E.CType);
        end
        else if IsFloatingType(E.Left.CType) then
        begin
          EmitConvertFloatToInteger(E.Left.CType);
          if E.CType.Kind = ctBool then EmitNormalizeBool;
        end
        else if not IsAggregateType(E.CType) then
          EmitNormalizeInteger(E.CType);
      end;
    ekComma:
      begin
        GenExpr(E.Left);
        GenExpr(E.Right);
      end;
    ekSizeof: EmitMovRaxImm(E.IntValue);
    ekCompoundLit:
      RaiseCompileError(E.Pos,
        'compound literal values require object materialization');
  else
    RaiseCompileError(E.Pos,
      'expression form is unsupported by the x86-64 backend');
  end;
end;

procedure TX64Backend.GenInlineAsm(S: TStmt);
var
  SlotCount, StackBytes, I, RefIndex, DestSlot, SrcSlot, L,
    TargetLabel: LongInt;
  Lines: TStringList;
  Line, Op, LeftText, RightText, Token, LabelName: string;
  Value: Int64;
  ConditionOpcode, InverseConditionOpcode: Byte;

  procedure EmitStackAddressed(const AOpcode8: array of Byte;
    AOpcode32: Byte; AOffset: LongInt);
  var
    K: LongInt;
  begin
    if (AOffset >= 0) and (AOffset <= 127) then
    begin
      for K := Low(AOpcode8) to High(AOpcode8) do FText.Add8(AOpcode8[K]);
      FText.Add8(Byte(AOffset));
    end
    else
    begin
      FText.Add8(AOpcode32);
      FText.AddI32(AOffset);
    end;
  end;

  procedure StoreRaxToSlot(ASlot: LongInt);
  var Offset: LongInt;
  begin
    Offset := ASlot * 8;
    if Offset <= 127 then
      FText.AddBytes([$48, $89, $44, $24, Byte(Offset)])
    else
    begin
      FText.AddBytes([$48, $89, $84, $24]);
      FText.AddI32(Offset);
    end;
  end;

  procedure LoadRaxFromSlot(ASlot: LongInt);
  var Offset: LongInt;
  begin
    Offset := ASlot * 8;
    if Offset <= 127 then
      FText.AddBytes([$48, $8B, $44, $24, Byte(Offset)])
    else
    begin
      FText.AddBytes([$48, $8B, $84, $24]);
      FText.AddI32(Offset);
    end;
  end;

  procedure LoadRcxFromSlot(ASlot: LongInt);
  var Offset: LongInt;
  begin
    Offset := ASlot * 8;
    if Offset <= 127 then
      FText.AddBytes([$48, $8B, $4C, $24, Byte(Offset)])
    else
    begin
      FText.AddBytes([$48, $8B, $8C, $24]);
      FText.AddI32(Offset);
    end;
  end;

  function OperandSlot(const AText: string): LongInt;
  var
    Name, Digits: string;
    K, N: LongInt;
  begin
    Result := -1;
    Token := Trim(AText);
    while (Token <> '') and (Token[1] in ['%', '$']) do Delete(Token, 1, 1);


    if (Length(Token) >= 2) and
       (Token[1] in ['b', 'w', 'k', 'q', 'c', 'n']) and
       ((Token[2] in ['0'..'9']) or (Token[2] = '[')) then
      Delete(Token, 1, 1);
    if (Length(Token) >= 3) and (Token[1] = '[') and
       (Token[Length(Token)] = ']') then
    begin
      Name := Copy(Token, 2, Length(Token) - 2);
      for K := 0 to High(S.AsmOutputs) do
        if S.AsmOutputs[K].Name = Name then Exit(K);
      for K := 0 to High(S.AsmInputs) do
        if S.AsmInputs[K].Name = Name then
          Exit(Length(S.AsmOutputs) + K);
      Exit(-1);
    end;
    Digits := '';
    for K := 1 to Length(Token) do
      if Token[K] in ['0'..'9'] then Digits := Digits + Token[K]
      else Break;
    if (Digits <> '') and TryStrToInt(Digits, N) then Result := N;
  end;

  function ImmediateValue(const AText: string; out AValue: Int64): Boolean;
  var
    T: string;
    Slot: LongInt;
    OperandExpression: TExpr;
  begin
    T := Trim(AText);
    if (T <> '') and (T[1] = '$') then Delete(T, 1, 1);
    if Pos('%', T) > 0 then Slot := OperandSlot(T) else Slot := -1;
    if Slot >= 0 then
    begin
      OperandExpression := nil;
      if Slot >= Length(S.AsmOutputs) then
      begin
        Slot := Slot - Length(S.AsmOutputs);
        if Slot <= High(S.AsmInputs) then
          OperandExpression := S.AsmInputs[Slot].Expr;
      end;
      Result := (OperandExpression <> nil) and
        (OperandExpression.Kind = ekInteger);
      if Result then AValue := OperandExpression.IntValue else AValue := 0;
      Exit;
    end;
    if (Length(T) > 2) and (Copy(T, 1, 2) = '0x') then
      Result := TryStrToInt64('$' + Copy(T, 3, MaxInt), AValue)
    else
      Result := TryStrToInt64(T, AValue);
  end;

  procedure SplitInstruction(const ALine: string; out AMnemonic,
    ALeft, ARight: string);
  var
    SpacePos, CommaPos: LongInt;
    Args: string;
  begin
    AMnemonic := '';
    ALeft := '';
    ARight := '';
    SpacePos := Pos(' ', Trim(ALine));
    if SpacePos = 0 then
    begin
      AMnemonic := LowerCase(Trim(ALine));
      Exit;
    end;
    AMnemonic := LowerCase(Copy(Trim(ALine), 1, SpacePos - 1));
    Args := Trim(Copy(Trim(ALine), SpacePos + 1, MaxInt));
    CommaPos := Pos(',', Args);
    if CommaPos = 0 then ALeft := Trim(Args)
    else
    begin
      ALeft := Trim(Copy(Args, 1, CommaPos - 1));
      ARight := Trim(Copy(Args, CommaPos + 1, MaxInt));
    end;
  end;

  procedure EmitRawDirective(const ALine, ADirective: string;
    AWidth: LongInt);
  var
    Args, Part: string;
    CommaPos: LongInt;
    RawValue: Int64;
  begin
    Args := Trim(Copy(ALine, Length(ADirective) + 1, MaxInt));
    repeat
      CommaPos := Pos(',', Args);
      if CommaPos = 0 then
      begin
        Part := Trim(Args);
        Args := '';
      end
      else
      begin
        Part := Trim(Copy(Args, 1, CommaPos - 1));
        Delete(Args, 1, CommaPos);
      end;
      if not ImmediateValue(Part, RawValue) then
        RaiseCompileError(S.Pos, 'invalid inline assembly data value ' + Part);
      case AWidth of
        1: FText.Add8(Byte(RawValue));
        2: FText.Add16(Word(RawValue));
        4: FText.Add32(LongWord(RawValue));
        8: FText.Add64(QWord(RawValue));
      end;
    until Args = '';
  end;

  procedure ReleaseAsmStack;
  begin
    if StackBytes <= 0 then Exit;
    if StackBytes <= 127 then
      FText.AddBytes([$48, $83, $C4, Byte(StackBytes)])
    else
    begin
      FText.AddBytes([$48, $81, $C4]);
      FText.AddI32(StackBytes);
    end;
    Dec(FStackDepth, StackBytes);
  end;

  procedure StoreOutputs;
  var
    OutputIndex: LongInt;
  begin
    for OutputIndex := 0 to High(S.AsmOutputs) do
    begin
      if (S.AsmOutputs[OutputIndex].Expr = nil) or
         not S.AsmOutputs[OutputIndex].Expr.IsLValue then
        RaiseCompileError(S.Pos, 'inline assembly output requires an lvalue');
      GenAddress(S.AsmOutputs[OutputIndex].Expr);
      FText.AddBytes([$48, $89, $C1]);
      LoadRaxFromSlot(OutputIndex);
      EmitStoreRaxAtRcx(S.AsmOutputs[OutputIndex].Expr.CType);
    end;
  end;

  procedure RequireImmediate32(AValue: Int64; const AInstruction: string);
  begin
    if (AValue < Low(LongInt)) or (AValue > High(LongInt)) then
      RaiseCompileError(S.Pos, AInstruction +
        ' inline assembly immediate is outside signed 32-bit range');
  end;

  procedure EmitAsmMove(const AMnemonic, ASource, ADestination: string);
  var
    SourceSlot, DestinationSlot: LongInt;
    Immediate: Int64;
  begin
    DestinationSlot := OperandSlot(ADestination);
    if DestinationSlot < 0 then
      RaiseCompileError(S.Pos, 'unknown inline assembly operand ' +
        ADestination);
    if ImmediateValue(ASource, Immediate) then
      EmitMovRaxImm(Immediate)
    else
    begin
      SourceSlot := OperandSlot(ASource);
      if SourceSlot < 0 then
        RaiseCompileError(S.Pos, 'unknown inline assembly operand ' + ASource);
      LoadRaxFromSlot(SourceSlot);
    end;
    if AMnemonic = 'movl' then FText.AddBytes([$89, $C0]);
    StoreRaxToSlot(DestinationSlot);
  end;

  procedure EmitAsmBinary(const AMnemonic, ASource,
    ADestination: string);
  var
    SourceSlot, DestinationSlot: LongInt;
    Immediate: Int64;
    Is64: Boolean;
  begin
    DestinationSlot := OperandSlot(ADestination);
    if DestinationSlot < 0 then
      RaiseCompileError(S.Pos, 'unknown inline assembly operand ' +
        ADestination);
    Is64 := (AMnemonic <> '') and
      (AMnemonic[Length(AMnemonic)] = 'q');
    if ImmediateValue(ASource, Immediate) then
    begin
      RequireImmediate32(Immediate, AMnemonic);
      LoadRaxFromSlot(DestinationSlot);
      if Is64 then FText.Add8($48);
      if Pos('add', AMnemonic) = 1 then FText.AddBytes([$81, $C0])
      else if Pos('sub', AMnemonic) = 1 then FText.AddBytes([$81, $E8])
      else if Pos('and', AMnemonic) = 1 then FText.AddBytes([$81, $E0])
      else if Pos('or', AMnemonic) = 1 then FText.AddBytes([$81, $C8])
      else if Pos('xor', AMnemonic) = 1 then FText.AddBytes([$81, $F0])
      else if Pos('imul', AMnemonic) = 1 then FText.AddBytes([$69, $C0])
      else
        RaiseCompileError(S.Pos,
          'unsupported inline assembly binary operation ' + AMnemonic);
      FText.AddI32(LongInt(Immediate));
    end
    else
    begin
      SourceSlot := OperandSlot(ASource);
      if SourceSlot < 0 then
        RaiseCompileError(S.Pos, 'unknown inline assembly operand ' + ASource);
      LoadRcxFromSlot(SourceSlot);
      LoadRaxFromSlot(DestinationSlot);
      if Is64 then FText.Add8($48);
      if Pos('add', AMnemonic) = 1 then FText.AddBytes([$01, $C8])
      else if Pos('sub', AMnemonic) = 1 then FText.AddBytes([$29, $C8])
      else if Pos('and', AMnemonic) = 1 then FText.AddBytes([$21, $C8])
      else if Pos('or', AMnemonic) = 1 then FText.AddBytes([$09, $C8])
      else if Pos('xor', AMnemonic) = 1 then FText.AddBytes([$31, $C8])
      else if Pos('imul', AMnemonic) = 1 then FText.AddBytes([$0F, $AF, $C1])
      else
        RaiseCompileError(S.Pos,
          'unsupported inline assembly binary operation ' + AMnemonic);
    end;
    if not Is64 then FText.AddBytes([$89, $C0]);
    StoreRaxToSlot(DestinationSlot);
  end;

  procedure EmitAsmShift(const AMnemonic, ACount,
    ADestination: string);
  var
    DestinationSlot: LongInt;
    Count: Int64;
    Is64: Boolean;
    ModRM: Byte;
    Mask: QWord;
  begin
    DestinationSlot := OperandSlot(ADestination);
    if DestinationSlot < 0 then
      RaiseCompileError(S.Pos, 'unknown inline assembly operand ' +
        ADestination);
    if not ImmediateValue(ACount, Count) then
      RaiseCompileError(S.Pos,
        'native inline assembly shifts require an immediate count');
    Is64 := AMnemonic[Length(AMnemonic)] = 'q';
    if Is64 then Mask := 63 else Mask := 31;
    LoadRaxFromSlot(DestinationSlot);
    if Is64 then FText.Add8($48);
    if (Pos('shl', AMnemonic) = 1) or
       (Pos('sal', AMnemonic) = 1) then ModRM := $E0
    else if Pos('shr', AMnemonic) = 1 then ModRM := $E8
    else ModRM := $F8;
    FText.AddBytes([$C1, ModRM, Byte(QWord(Count) and Mask)]);
    if not Is64 then FText.AddBytes([$89, $C0]);
    StoreRaxToSlot(DestinationSlot);
  end;

  procedure EmitAsmUnary(const AMnemonic, AOperand: string);
  var
    DestinationSlot: LongInt;
    Is64: Boolean;
    Opcode, ModRM: Byte;
  begin
    DestinationSlot := OperandSlot(AOperand);
    if DestinationSlot < 0 then
      RaiseCompileError(S.Pos, 'unknown inline assembly operand ' + AOperand);
    Is64 := AMnemonic[Length(AMnemonic)] = 'q';
    LoadRaxFromSlot(DestinationSlot);
    if Is64 then FText.Add8($48);
    if Pos('inc', AMnemonic) = 1 then
    begin Opcode := $FF; ModRM := $C0; end
    else if Pos('dec', AMnemonic) = 1 then
    begin Opcode := $FF; ModRM := $C8; end
    else if Pos('neg', AMnemonic) = 1 then
    begin Opcode := $F7; ModRM := $D8; end
    else
    begin Opcode := $F7; ModRM := $D0; end;
    FText.AddBytes([Opcode, ModRM]);
    if not Is64 then FText.AddBytes([$89, $C0]);
    StoreRaxToSlot(DestinationSlot);
  end;

  procedure EmitAsmCompare(const AMnemonic, ASource,
    ADestination: string);
  var
    SourceSlot, DestinationSlot: LongInt;
    Immediate: Int64;
    Is64, IsTest: Boolean;
  begin
    DestinationSlot := OperandSlot(ADestination);
    if DestinationSlot < 0 then
      RaiseCompileError(S.Pos, 'unknown inline assembly operand ' +
        ADestination);
    Is64 := AMnemonic[Length(AMnemonic)] = 'q';
    IsTest := Pos('test', AMnemonic) = 1;
    if ImmediateValue(ASource, Immediate) then
    begin
      RequireImmediate32(Immediate, AMnemonic);
      LoadRaxFromSlot(DestinationSlot);
      if Is64 then FText.Add8($48);
      if IsTest then FText.AddBytes([$F7, $C0])
      else FText.AddBytes([$81, $F8]);
      FText.AddI32(LongInt(Immediate));
    end
    else
    begin
      SourceSlot := OperandSlot(ASource);
      if SourceSlot < 0 then
        RaiseCompileError(S.Pos, 'unknown inline assembly operand ' + ASource);
      LoadRcxFromSlot(SourceSlot);
      LoadRaxFromSlot(DestinationSlot);
      if Is64 then FText.Add8($48);
      if IsTest then FText.AddBytes([$85, $C8])
      else FText.AddBytes([$39, $C8]);
    end;
  end;

  function SetConditionOpcode(const AMnemonic: string;
    out AOpcode: Byte): Boolean;
  begin
    Result := True;
    if (AMnemonic = 'sete') or (AMnemonic = 'setz') then AOpcode := $94
    else if (AMnemonic = 'setne') or (AMnemonic = 'setnz') then AOpcode := $95
    else if AMnemonic = 'setl' then AOpcode := $9C
    else if AMnemonic = 'setle' then AOpcode := $9E
    else if AMnemonic = 'setg' then AOpcode := $9F
    else if AMnemonic = 'setge' then AOpcode := $9D
    else if (AMnemonic = 'setb') or (AMnemonic = 'setc') then AOpcode := $92
    else if AMnemonic = 'setbe' then AOpcode := $96
    else if AMnemonic = 'seta' then AOpcode := $97
    else if (AMnemonic = 'setae') or (AMnemonic = 'setnc') then AOpcode := $93
    else Result := False;
  end;

  procedure EmitAsmSetCondition(const AMnemonic, AOperand: string);
  var
    DestinationSlot: LongInt;
    Opcode: Byte;
  begin
    if not SetConditionOpcode(AMnemonic, Opcode) then
      RaiseCompileError(S.Pos, 'unknown inline assembly condition ' + AMnemonic);
    DestinationSlot := OperandSlot(AOperand);
    if DestinationSlot < 0 then
      RaiseCompileError(S.Pos, 'unknown inline assembly operand ' + AOperand);
    FText.AddBytes([$0F, Opcode, $C0]);
    FText.AddBytes([$0F, $B6, $C0]);
    StoreRaxToSlot(DestinationSlot);
  end;

  function JumpConditionOpcode(const AMnemonic: string;
    out AOpcode, AInverseOpcode: Byte): Boolean;
  begin
    Result := True;
    if (AMnemonic = 'jz') or (AMnemonic = 'je') then
    begin AOpcode := $84; AInverseOpcode := $85; end
    else if (AMnemonic = 'jnz') or (AMnemonic = 'jne') then
    begin AOpcode := $85; AInverseOpcode := $84; end
    else if AMnemonic = 'jl' then
    begin AOpcode := $8C; AInverseOpcode := $8D; end
    else if AMnemonic = 'jge' then
    begin AOpcode := $8D; AInverseOpcode := $8C; end
    else if AMnemonic = 'jle' then
    begin AOpcode := $8E; AInverseOpcode := $8F; end
    else if AMnemonic = 'jg' then
    begin AOpcode := $8F; AInverseOpcode := $8E; end
    else if (AMnemonic = 'jb') or (AMnemonic = 'jc') then
    begin AOpcode := $82; AInverseOpcode := $83; end
    else if (AMnemonic = 'jae') or (AMnemonic = 'jnc') then
    begin AOpcode := $83; AInverseOpcode := $82; end
    else if AMnemonic = 'jbe' then
    begin AOpcode := $86; AInverseOpcode := $87; end
    else if AMnemonic = 'ja' then
    begin AOpcode := $87; AInverseOpcode := $86; end
    else Result := False;
  end;

  function IsDeclaredAsmLabel(const AName: string): Boolean;
  var
    LabelIndex: LongInt;
  begin
    for LabelIndex := 0 to High(S.AsmLabels) do
      if S.AsmLabels[LabelIndex] = AName then Exit(True);
    Result := False;
  end;

  procedure EmitAsmGotoCondition(const AMnemonic, AOperand: string);
  var
    Opcode, InverseOpcode: Byte;
  begin
    if not JumpConditionOpcode(AMnemonic, Opcode, InverseOpcode) then
      RaiseCompileError(S.Pos, 'unknown inline assembly branch ' + AMnemonic);
    LabelName := Trim(AOperand);
    if Pos('%l[', LabelName) = 1 then
      LabelName := Copy(LabelName, 4, Length(LabelName) - 4)
    else if Pos('%l', LabelName) = 1 then
      Delete(LabelName, 1, 2);
    if not S.AsmGoto or not IsDeclaredAsmLabel(LabelName) then
      RaiseCompileError(S.Pos,
        'inline assembly branch target is not declared in asm goto: ' +
        LabelName);
    TargetLabel := FindUserLabel(LabelName);
    if TargetLabel < 0 then
      RaiseCompileError(S.Pos, 'undefined asm goto label ' + LabelName);
    L := NewLabel;
    EmitJcc(InverseOpcode, L);
    StoreOutputs;
    ReleaseAsmStack;
    EmitJump(TargetLabel);
    BindTextLabel(L);
    if StackBytes > 0 then Inc(FStackDepth, StackBytes);
  end;

  procedure EmitAsmAlignment(const AMnemonic, AArgument: string);
  var
    AlignmentValue, Alignment: Int64;
  begin
    if not ImmediateValue(AArgument, AlignmentValue) then
      RaiseCompileError(S.Pos, 'invalid inline assembly alignment');
    if AMnemonic = '.p2align' then
    begin
      if (AlignmentValue < 0) or (AlignmentValue > 20) then
        RaiseCompileError(S.Pos, 'inline assembly power alignment is excessive');
      Alignment := Int64(1) shl AlignmentValue;
    end
    else
      Alignment := AlignmentValue;
    if (Alignment <= 0) or ((Alignment and (Alignment - 1)) <> 0) or
       (Alignment > 1048576) then
      RaiseCompileError(S.Pos,
        'inline assembly alignment must be a bounded power of two');
    while (FText.Size and (LongInt(Alignment) - 1)) <> 0 do FText.Add8($90);
  end;

begin
  SlotCount := Length(S.AsmOutputs) + Length(S.AsmInputs);
  StackBytes := SlotCount * 8;
  if StackBytes > 0 then
  begin
    if StackBytes <= 127 then
      FText.AddBytes([$48, $83, $EC, Byte(StackBytes)])
    else
    begin
      FText.AddBytes([$48, $81, $EC]);
      FText.AddI32(StackBytes);
    end;
    Inc(FStackDepth, StackBytes);
  end;



  for I := 0 to High(S.AsmOutputs) do
  begin
    if Pos('+', S.AsmOutputs[I].ConstraintText) > 0 then
      GenExpr(S.AsmOutputs[I].Expr)
    else
      EmitMovRaxImm(0);
    StoreRaxToSlot(I);
  end;
  for I := 0 to High(S.AsmInputs) do
  begin
    GenExpr(S.AsmInputs[I].Expr);
    StoreRaxToSlot(Length(S.AsmOutputs) + I);
    Token := Trim(S.AsmInputs[I].ConstraintText);
    if (Token <> '') and (Token[1] in ['0'..'9']) and
       TryStrToInt(Token, RefIndex) and
       (RefIndex >= 0) and (RefIndex < Length(S.AsmOutputs)) then
      StoreRaxToSlot(RefIndex);
  end;

  Lines := TStringList.Create;
  try
    Line := StringReplace(S.AsmTemplate, #13, #10, [rfReplaceAll]);
    Line := StringReplace(Line, ';', #10, [rfReplaceAll]);
    Lines.Text := Line;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(StringReplace(Lines[I], #9, ' ', [rfReplaceAll]));
      if Line = '' then Continue;
      SplitInstruction(Line, Op, LeftText, RightText);

      if Op = 'nop' then FText.Add8($90)
      else if Op = 'pause' then FText.AddBytes([$F3, $90])
      else if Op = 'lfence' then FText.AddBytes([$0F, $AE, $E8])
      else if Op = 'mfence' then FText.AddBytes([$0F, $AE, $F0])
      else if Op = 'sfence' then FText.AddBytes([$0F, $AE, $F8])
      else if Op = 'ud2' then FText.AddBytes([$0F, $0B])
      else if Op = 'int3' then FText.Add8($CC)
      else if Op = '.byte' then EmitRawDirective(Line, '.byte', 1)
      else if (Op = '.word') or (Op = '.short') then
        EmitRawDirective(Line, Op, 2)
      else if (Op = '.long') or (Op = '.int') then
        EmitRawDirective(Line, Op, 4)
      else if (Op = '.quad') then EmitRawDirective(Line, '.quad', 8)
      else if (Op = '.p2align') or (Op = '.balign') or
              (Op = '.align') then
        EmitAsmAlignment(Op, LeftText)
      else if (Op = 'xorl') and (LeftText = '%%eax') and
              (RightText = '%%eax') then
        FText.AddBytes([$45, $31, $DB])
      else if (Op = 'addl') and (RightText = '%%eax') and
              ImmediateValue(LeftText, Value) then
      begin
        FText.AddBytes([$41, $81, $C3]);
        FText.AddI32(LongInt(Value));
      end
      else if (Op = 'movl') and (LeftText = '%%eax') then
      begin
        DestSlot := OperandSlot(RightText);
        if DestSlot < 0 then
          RaiseCompileError(S.Pos, 'unknown inline assembly operand ' + RightText);
        FText.AddBytes([$44, $89, $D8]);
        StoreRaxToSlot(DestSlot);
      end
      else if (Op = 'movl') and (RightText = '%%eax') then
      begin
        if ImmediateValue(LeftText, Value) then EmitMovRaxImm(Value)
        else
        begin
          SrcSlot := OperandSlot(LeftText);
          if SrcSlot < 0 then RaiseCompileError(S.Pos,
            'unknown inline assembly operand ' + LeftText);
          LoadRaxFromSlot(SrcSlot);
        end;
        FText.AddBytes([$41, $89, $C3]);
      end
      else if (Op = 'movl') or (Op = 'movq') then
        EmitAsmMove(Op, LeftText, RightText)
      else if (Op = 'addl') or (Op = 'addq') or
              (Op = 'subl') or (Op = 'subq') or
              (Op = 'andl') or (Op = 'andq') or
              (Op = 'orl') or (Op = 'orq') or
              (Op = 'xorl') or (Op = 'xorq') or
              (Op = 'imull') or (Op = 'imulq') then
        EmitAsmBinary(Op, LeftText, RightText)
      else if (Op = 'shll') or (Op = 'shlq') or
              (Op = 'sall') or (Op = 'salq') or
              (Op = 'shrl') or (Op = 'shrq') or
              (Op = 'sarl') or (Op = 'sarq') then
        EmitAsmShift(Op, LeftText, RightText)
      else if (Op = 'incl') or (Op = 'incq') or
              (Op = 'decl') or (Op = 'decq') or
              (Op = 'negl') or (Op = 'negq') or
              (Op = 'notl') or (Op = 'notq') then
        EmitAsmUnary(Op, LeftText)
      else if (Op = 'cmpl') or (Op = 'cmpq') or
              (Op = 'testl') or (Op = 'testq') then
        EmitAsmCompare(Op, LeftText, RightText)
      else if SetConditionOpcode(Op, ConditionOpcode) then
        EmitAsmSetCondition(Op, LeftText)
      else if JumpConditionOpcode(Op, ConditionOpcode,
              InverseConditionOpcode) then
        EmitAsmGotoCondition(Op, LeftText)
      else
        RaiseCompileError(S.Pos,
          'native inline assembler does not recognize instruction: ' + Line);
    end;
    StoreOutputs;
  finally
    Lines.Free;
  end;

  ReleaseAsmStack;
end;

procedure TX64Backend.GenStmt(S: TStmt);
var
  I, Offset, ElseLabel, EndLabel, CondLabel, BodyLabel, ContinueLabel,
    NoMatchLabel, DefaultLabel, L: LongInt;
  SavedCount: LongInt;
  SwitchEntries: TSwitchEntryArray;
begin
  if S = nil then Exit;
  case S.Kind of
    skEmpty: ;
    skExpr: GenExpr(S.Expr);
    skAsm: GenInlineAsm(S);
    skDecl:
      begin
        AddLocal(S.Name, S.CType, False, Offset);
        InitializeLocal(Offset, S.CType, S.Expr, S.Pos);
      end;
    skReturn:
      begin
        if S.Expr <> nil then
        begin
          if IsAggregateType(FCurrentReturnType) then
            GenAggregateReturn(S.Expr)
          else if IsFloatingType(FCurrentReturnType) then
            GenExprAsFloating(S.Expr, FCurrentReturnType)
          else
          begin
            GenExpr(S.Expr);
            if IsFloatingType(S.Expr.CType) then
              EmitConvertFloatToInteger(S.Expr.CType);
            EmitNormalizeInteger(FCurrentReturnType);
          end;
        end
        else EmitMovRaxImm(0);
        EmitJump(FEpilogueLabel);
      end;
    skBlock:
      begin
        if S.IsDeclarationGroup then
        begin
          for I := 0 to High(S.Children) do GenStmt(S.Children[I]);
        end
        else
        begin
          SavedCount := Length(FLocals);
          EnterScope;
          for I := 0 to High(S.Children) do GenStmt(S.Children[I]);
          LeaveScope(SavedCount);
        end;
      end;
    skIf:
      begin
        ElseLabel := NewLabel; EndLabel := NewLabel;
        GenCondition(S.Expr);
        FText.AddBytes([$48, $85, $C0]);
        EmitJcc($84, ElseLabel);
        GenStmt(S.Body);
        EmitJump(EndLabel);
        BindTextLabel(ElseLabel);
        GenStmt(S.ElseBody);
        BindTextLabel(EndLabel);
      end;
    skWhile:
      begin
        CondLabel := NewLabel; EndLabel := NewLabel;
        BindTextLabel(CondLabel);
        GenCondition(S.Expr);
        FText.AddBytes([$48, $85, $C0]);
        EmitJcc($84, EndLabel);
        PushLoop(EndLabel, CondLabel);
        GenStmt(S.Body);
        PopLoop;
        EmitJump(CondLabel);
        BindTextLabel(EndLabel);
      end;
    skDoWhile:
      begin
        BodyLabel := NewLabel; ContinueLabel := NewLabel; EndLabel := NewLabel;
        BindTextLabel(BodyLabel);
        PushLoop(EndLabel, ContinueLabel);
        GenStmt(S.Body);
        PopLoop;
        BindTextLabel(ContinueLabel);
        GenCondition(S.Expr);
        FText.AddBytes([$48, $85, $C0]);
        EmitJcc($85, BodyLabel);
        BindTextLabel(EndLabel);
      end;
    skFor:
      begin
        SavedCount := Length(FLocals);
        EnterScope;
        GenStmt(S.InitStmt);
        CondLabel := NewLabel; ContinueLabel := NewLabel; EndLabel := NewLabel;
        BindTextLabel(CondLabel);
        if S.Expr <> nil then
        begin
          GenCondition(S.Expr);
          FText.AddBytes([$48, $85, $C0]);
          EmitJcc($84, EndLabel);
        end;
        PushLoop(EndLabel, ContinueLabel);
        GenStmt(S.Body);
        PopLoop;
        BindTextLabel(ContinueLabel);
        if S.Expr2 <> nil then GenExpr(S.Expr2);
        EmitJump(CondLabel);
        BindTextLabel(EndLabel);
        LeaveScope(SavedCount);
      end;
    skSwitch:
      begin
        SetLength(SwitchEntries, 0);
        CollectSwitchEntries(S.Body, SwitchEntries);
        EndLabel := NewLabel;
        DefaultLabel := EndLabel;
        for I := 0 to High(SwitchEntries) do
          if SwitchEntries[I].IsDefault then
            DefaultLabel := SwitchEntries[I].TargetLabel
          else
            SwitchEntries[I].MatchLabel := NewLabel;

        GenExpr(S.Expr);
        EmitPushRax;
        for I := 0 to High(SwitchEntries) do
          if not SwitchEntries[I].IsDefault then
          begin
            EmitMovRaxImm(SwitchEntries[I].Value);
            FText.AddBytes([$48, $89, $C1]);
            FText.AddBytes([$48, $8B, $04, $24]);
            FText.AddBytes([$48, $39, $C8]);
            EmitJcc($84, SwitchEntries[I].MatchLabel);
          end;
        NoMatchLabel := NewLabel;
        EmitJump(NoMatchLabel);
        for I := 0 to High(SwitchEntries) do
          if not SwitchEntries[I].IsDefault then
          begin
            BindTextLabel(SwitchEntries[I].MatchLabel);
            FText.AddBytes([$48, $83, $C4, $08]);
            Dec(FStackDepth, 8);
            EmitJump(SwitchEntries[I].TargetLabel);
            Inc(FStackDepth, 8);
          end;
        BindTextLabel(NoMatchLabel);
        FText.AddBytes([$48, $83, $C4, $08]);
        Dec(FStackDepth, 8);
        EmitJump(DefaultLabel);
        PushBreak(EndLabel);
        GenSwitchBody(S.Body, SwitchEntries);
        PopBreak;
        BindTextLabel(EndLabel);
      end;
    skGoto:
      begin
        L := FindUserLabel(S.Name);
        if L < 0 then RaiseCompileError(S.Pos, 'undefined label ' + S.Name);
        EmitJump(L);
      end;
    skLabel:
      begin
        L := FindUserLabel(S.Name);
        if L < 0 then
          RaiseCompileError(S.Pos, 'internal error: label was not reserved');
        BindTextLabel(L);
      end;
    skCase, skDefault:
      RaiseCompileError(S.Pos, 'case/default label is not inside a switch body');
    skBreak:
      begin
        if Length(FBreakLabels) = 0 then
          RaiseCompileError(S.Pos, 'break statement is not inside a loop');
        EmitJump(FBreakLabels[High(FBreakLabels)]);
      end;
    skContinue:
      begin
        if Length(FContinueLabels) = 0 then
          RaiseCompileError(S.Pos, 'continue statement is not inside a loop');
        EmitJump(FContinueLabels[High(FContinueLabels)]);
      end;
  else
    RaiseCompileError(S.Pos,
      'statement form is unsupported by the x86-64 backend');
  end;
end;

procedure TX64Backend.GenFunction(F: TFunction; ALabel: LongInt);
type
  TCTypeVector = array of TCType;
var
  I, Offset, LocalBytes, ParameterBytes, Size, Alignment,
    FrameSize, StackOffset, J, RegisterOrdinal, FixedStackEnd,
    CandidateStackEnd: LongInt;
  ParameterTypes: TCTypeVector;
  Layout: TABIFunctionLayout;
  Location: TABIValueLocation;
  DoubleType: TCType;

  function GPRegisterOrdinal(ARegisterNumber: LongInt): LongInt;
  begin
    case ARegisterNumber of
      7: Result := 0;
      6: Result := 1;
      2: Result := 2;
      1: Result := 3;
      8: Result := 4;
      9: Result := 5;
    else
      raise ERCCError.Create('internal error: invalid SysV parameter register');
    end;
  end;
begin
  SetLength(ParameterTypes, Length(F.Params));
  for I := 0 to High(F.Params) do ParameterTypes[I] := F.Params[I].CType;
  Layout := BuildFunctionABILayout(F.ReturnType, ParameterTypes,
    F.IsVariadic, NativeTargetDescriptor);
  try
  FixedStackEnd := 0;
  for I := 0 to High(F.Params) do
  begin
    Location := Layout.Parameters[I];
    if (Location.Kind = alkStack) and (Length(Location.Parts) > 0) then
    begin
      CandidateStackEnd := LongInt(Location.Parts[0].StackOffset) +
        LongInt(AlignUp(Location.Size, 8));
      if CandidateStackEnd > FixedStackEnd then
        FixedStackEnd := CandidateStackEnd;
    end;
  end;
  BindTextLabel(ALabel);
  FListing.Add(F.Name + ':');
  FText.AddBytes([$55, $48, $89, $E5]);
  ParameterBytes := 0;
  if Layout.UsesHiddenReturnPointer then Inc(ParameterBytes, 15);
  if F.IsVariadic then Inc(ParameterBytes, 191);
  for I := 0 to High(F.Params) do
  begin
    Location := Layout.Parameters[I];
    if IsAggregateType(F.Params[I].CType) and (Location.Kind = alkStack) then
    begin
      Size := 8;
      Alignment := 8;
    end
    else
    begin
      Size := StorageSize(F.Params[I].CType);
      if IsAggregateType(F.Params[I].CType) then
        Size := LongInt(AlignUp(QWord(Size), 8))
      else if Size < 8 then
        Size := 8;
      Alignment := StorageAlign(F.Params[I].CType);
    end;
    Inc(ParameterBytes, Size + Alignment - 1);
  end;
  LocalBytes := CountLocalBytes(F.Body);
  FrameSize := LongInt(AlignUp(QWord(ParameterBytes + LocalBytes), 16));
  if FrameSize > 0 then
  begin
    FText.AddBytes([$48, $81, $EC]);
    FText.AddI32(FrameSize);
  end;
  SetLength(FLocals, 0);
  SetLength(FUserLabels, 0);
  ReserveUserLabels(F.Body);
  FScopeDepth := 0;
  FNextLocalSlot := 0;
  FStackDepth := 0;
  FEpilogueLabel := NewLabel;
  FCurrentReturnType := F.ReturnType;
  FCurrentUsesSRet := Layout.UsesHiddenReturnPointer;
  FCurrentSRetOffset := 0;
  FCurrentIsVariadic := F.IsVariadic;
  FCurrentVarArgSaveOffset := 0;
  FCurrentVarArgGPOffset := Layout.IntegerRegistersUsed * 8;
  FCurrentVarArgFPOffset := 48 + Layout.FloatingRegistersUsed * 16;
  FCurrentVarArgStackOffset := FixedStackEnd;
  if FCurrentIsVariadic then
  begin
    ReserveTemporary(176, 16, FCurrentVarArgSaveOffset);
    for I := 0 to 5 do
      EmitStoreArgToLocal(I, FCurrentVarArgSaveOffset - I * 8);
    DoubleType := MakeType(ctDouble);
    for I := 0 to 7 do
      EmitStoreXmmArgToLocal(I,
        FCurrentVarArgSaveOffset - (48 + I * 16), DoubleType);
  end;
  if FCurrentUsesSRet then
  begin
    AddLocal('$rcc.sret', MakeType(ctPointer), False, FCurrentSRetOffset);
    EmitStoreArgToLocal(0, FCurrentSRetOffset);
  end;
  for I := 0 to High(F.Params) do
  begin
    if F.Params[I].Name = '' then
      RaiseCompileError(F.Pos, 'parameter names are required in function definitions');
    Location := Layout.Parameters[I];
    if IsAggregateType(F.Params[I].CType) then
    begin
      if Location.Kind = alkStack then
      begin


        AddLocal(F.Params[I].Name, F.Params[I].CType, True, Offset);
        StackOffset := 16 + LongInt(Location.Parts[0].StackOffset);
        FText.AddBytes([$48, $8D, $85]);
        FText.AddI32(StackOffset);
        EmitStoreLocal(Offset);
      end
      else
      begin
        AddLocal(F.Params[I].Name, F.Params[I].CType, False, Offset);
        for J := 0 to High(Location.Parts) do
          if Location.Parts[J].ValueClass = ascInteger then
          begin
            RegisterOrdinal := GPRegisterOrdinal(
              Location.Parts[J].RegisterNumber);
            EmitStoreArgToLocal(RegisterOrdinal, Offset - J * 8);
          end
          else if Location.Parts[J].ValueClass in [ascSSE, ascSSEUp] then
          begin
            FText.Add8($66);
            FText.AddBytes([$0F, $D6,
              Byte($85 or (Location.Parts[J].RegisterNumber shl 3))]);
            FText.AddI32(-Offset + J * 8);
          end
          else
            raise ERCCError.Create('internal error: unsupported aggregate parameter class');
      end;
    end
    else
    begin
      AddLocal(F.Params[I].Name, F.Params[I].CType, False, Offset);
      if Location.Kind = alkStack then
      begin
        StackOffset := 16 + LongInt(Location.Parts[0].StackOffset);
        if IsFloatingType(F.Params[I].CType) then
        begin
          FText.AddBytes([$48, $8D, $85]);
          FText.AddI32(StackOffset);
          EmitLoadAtRax(F.Params[I].CType);
          EmitStoreXmmArgToLocal(0, Offset, F.Params[I].CType);
        end
        else
        begin
          FText.AddBytes([$48, $8B, $85]);
          FText.AddI32(StackOffset);
          EmitStoreLocal(Offset);
        end;
      end
      else if IsFloatingType(F.Params[I].CType) then
        EmitStoreXmmArgToLocal(Location.Parts[0].RegisterNumber,
          Offset, F.Params[I].CType)
      else
      begin
        RegisterOrdinal := GPRegisterOrdinal(
          Location.Parts[0].RegisterNumber);
        EmitStoreArgToLocal(RegisterOrdinal, Offset);
      end;
    end;
  end;
  GenStmt(F.Body);
  EmitMovRaxImm(0);
  BindTextLabel(FEpilogueLabel);
  FText.AddBytes([$C9, $C3]);
  FListing.Add('  ; native x86-64 body: ' + IntToStr(FText.Size) + ' bytes so far');
  FListing.Add('  leave');
  FListing.Add('  ret');
  FListing.Add('');
  if FStackDepth <> 0 then
    raise ERCCError.Create('internal error: unbalanced expression stack in ' + F.Name);
  if FNextLocalSlot > FrameSize then
    raise ERCCError.Create('internal error: local frame estimate was too small in ' +
      F.Name);
  Inc(FStats.FunctionsEmitted);
  finally
    Layout.Free;
  end;
end;

procedure TX64Backend.GenerateCode;
var
  I, L: LongInt;
begin
  FillChar(FStats, SizeOf(FStats), 0);
  ReserveFunctionLabels;
  if FOptions.EmitMode <> emObject then ReserveRuntimeLabels;
  for I := 0 to High(FProgram.Globals) do
    PreallocateInitializerLiterals(FProgram.Globals[I].Initializer);
  AllocateGlobals;
  if FOptions.EmitMode <> emObject then
  begin
    LoadExternalInputs;
    PrepareExternalRelocations;
  end;
  for I := 0 to High(FProgram.Functions) do
    if not FProgram.Functions[I].IsPrototype then
    begin
      L := FindNamedLabel(FFunctions, FProgram.Functions[I].Name);
      GenFunction(FProgram.Functions[I], L);
    end;
  if FOptions.EmitMode = emObject then Exit;
  EmitRuntime;



  EmitStartup;
end;

procedure TX64Backend.BuildAssemblyListing;
var
  Layout: TELFExecutableLayout;

  procedure DumpBuffer(const AName: string; Buffer: TByteBuffer;
    BaseAddress: QWord);
  var
    I, J, LastIndex: LongInt;
    LineText: string;
  begin
    FListing.Add('section .' + AName);
    I := 0;
    while I < Buffer.Size do
    begin
      LastIndex := I + 15;
      if LastIndex >= Buffer.Size then LastIndex := Buffer.Size - 1;
      LineText := '  ; ' + IntToHex(BaseAddress + QWord(I), 16) + '  db ';
      for J := I to LastIndex do
      begin
        if J > I then LineText := LineText + ', ';
        LineText := LineText + '$' + IntToHex(Buffer.ByteAt(J), 2);
      end;
      FListing.Add(LineText);
      I := LastIndex + 1;
    end;
    if Buffer.Size = 0 then FListing.Add('  ; empty');
    FListing.Add('');
  end;

begin
  Layout := ComputeELFExecutableLayout(QWord(FText.Size), QWord(FData.Size),
    QWord(FLabels[FEntryLabel].Offset));
  ResolveFixups(Layout.TextVA, Layout.DataVA);
  ResolveExternalRelocations(Layout.TextVA, Layout.DataVA);
  FListing.Clear;
  FListing.Add('; rcc resolved Linux x86-64 machine-code listing');
  FListing.Add('; no assembler or linker is used to produce the executable');
  FListing.Add('; entry virtual address: $' +
    IntToHex(Layout.EntryVA, 16));
  FListing.Add('');
  DumpBuffer('text', FText, Layout.TextVA);
  DumpBuffer('data', FData, Layout.DataVA);
end;

procedure TX64Backend.WriteObject(const AFileName: string);
var
  Target: TTargetDescriptor;
  Obj: TObjectFile;
  TextIndex, DataIndex, TextSectionSymbol, DataSectionSymbol: LongInt;
  UndefinedSymbolIndices: array of LongInt;
  I, SymbolIndex, BaseAddend, SectionIndex: LongInt;
  Fixup: TFixup;
  DataFixup: TDataAddressFixup;
  GeneratedRelocation: TGeneratedObjectRelocation;
  LabelInfo: TLabelInfo;
  DebugFunctions: TObjectDebugFunctionArray;
  DebugSourceName: string;

  function ObjectSymbolType(ASymbolType: Byte): TObjectSymbolType;
  begin
    case ASymbolType of
      ELF_STT_OBJECT: Result := ostObject;
      ELF_STT_FUNC: Result := ostFunction;
      ELF_STT_SECTION: Result := ostSection;
    else
      Result := ostNoType;
    end;
  end;

  function FunctionSize(ALabel: LongInt): QWord;
  var
    J, StartOffset, EndOffset, Candidate: LongInt;
  begin
    StartOffset := FLabels[ALabel].Offset;
    EndOffset := FText.Size;
    for J := 0 to High(FFunctions) do
    begin
      Candidate := FLabels[FFunctions[J].LabelID].Offset;
      if (Candidate > StartOffset) and (Candidate < EndOffset) then
        EndOffset := Candidate;
    end;
    Result := QWord(EndOffset - StartOffset);
  end;

  procedure AddDefinedSymbols(AStatic: Boolean);
  var
    J, LabelID: LongInt;
    Binding: TObjectSymbolBinding;
    F: TFunction;
    G: TGlobal;
  begin
    if AStatic then Binding := osbLocal else Binding := osbGlobal;
    for J := 0 to High(FProgram.Functions) do
    begin
      F := FProgram.Functions[J];
      if F.IsPrototype or (F.IsStatic <> AStatic) then Continue;
      LabelID := FindNamedLabel(FFunctions, F.Name);
      Obj.AddSymbol(F.Name, Binding, ostFunction, osvDefault,
        TextIndex, QWord(FLabels[LabelID].Offset), FunctionSize(LabelID), True);
    end;
    for J := 0 to High(FProgram.Globals) do
    begin
      G := FProgram.Globals[J];
      if G.IsExtern or (G.IsStatic <> AStatic) then Continue;
      LabelID := FindNamedLabel(FGlobals, G.Name);
      Obj.AddSymbol(G.Name, Binding, ostObject, osvDefault,
        DataIndex, QWord(FLabels[LabelID].Offset),
        QWord(StorageSize(G.CType)), True);
    end;
  end;

  function UndefinedIndexForLabel(ALabel: LongInt): LongInt;
  var
    J: LongInt;
  begin
    for J := 0 to High(FObjectUndefined) do
      if FObjectUndefined[J].LabelID = ALabel then
        Exit(UndefinedSymbolIndices[J]);
    raise ERCCError.Create(
      'internal error: object relocation has an unnamed undefined label');
  end;

  function UndefinedTypeForLabel(ALabel: LongInt): Byte;
  var
    J: LongInt;
  begin
    for J := 0 to High(FObjectUndefined) do
      if FObjectUndefined[J].LabelID = ALabel then
        Exit(FObjectUndefined[J].SymbolType);
    Result := ELF_STT_NOTYPE;
  end;

  procedure RelocationTarget(ALabel: LongInt; out ASymbolIndex,
    ABaseAddend: LongInt);
  begin
    if (ALabel < 0) or (ALabel > High(FLabels)) then
      raise ERCCError.Create('internal error: invalid object relocation label');
    LabelInfo := FLabels[ALabel];
    case LabelInfo.Section of
      lsText:
        begin
          ASymbolIndex := TextSectionSymbol;
          ABaseAddend := LabelInfo.Offset;
        end;
      lsData:
        begin
          ASymbolIndex := DataSectionSymbol;
          ABaseAddend := LabelInfo.Offset;
        end;
      lsUnbound:
        begin
          ASymbolIndex := UndefinedIndexForLabel(ALabel);
          ABaseAddend := 0;
        end;
    end;
  end;

begin
  Target := GetTargetOrRaise(FOptions.TargetTriple);
  if Target.Architecture <> archX86_64 then
    raise ERCCError.Create('internal error: x86 object writer selected for ' +
      ArchitectureName(Target.Architecture));
  Obj := TObjectFile.Create(Target);
  try
    if Length(FOptions.Inputs) > 0 then
      Obj.SourceName := ExtractFileName(FOptions.Inputs[0])
    else
      Obj.SourceName := 'rcc-input.c';
    TextIndex := Obj.AddSection('.text', oskText,
      [osfAlloc, osfExecute], 16);
    DataIndex := Obj.AddSection('.data', oskData,
      [osfAlloc, osfWrite], 16);
    Obj.AddSection('.note.GNU-stack', oskCustom, [], 1);


    TextSectionSymbol := Obj.AddSymbol('', osbLocal, ostSection, osvDefault,
      TextIndex, 0, 0, True);
    DataSectionSymbol := Obj.AddSymbol('', osbLocal, ostSection, osvDefault,
      DataIndex, 0, 0, True);
    AddDefinedSymbols(True);
    AddDefinedSymbols(False);

    SetLength(UndefinedSymbolIndices, Length(FObjectUndefined));
    for I := 0 to High(FObjectUndefined) do
      UndefinedSymbolIndices[I] := Obj.AddSymbol(FObjectUndefined[I].Name,
        osbGlobal, ObjectSymbolType(FObjectUndefined[I].SymbolType),
        osvDefault, 0, 0, 0, False);

    for I := 0 to High(FFixups) do
    begin
      Fixup := FFixups[I];
      LabelInfo := FLabels[Fixup.TargetLabel];
      if LabelInfo.Section = lsText then
      begin
        FText.Patch32(Fixup.PatchOffset,
          LabelInfo.Offset - (Fixup.PatchOffset + 4));
        Inc(FStats.FixupsResolved);
        Continue;
      end;
      RelocationTarget(Fixup.TargetLabel, SymbolIndex, BaseAddend);
      if LabelInfo.Section = lsUnbound then
      begin
        if UndefinedTypeForLabel(Fixup.TargetLabel) = ELF_STT_FUNC then
          Obj.AddRelocation(TextIndex, QWord(Fixup.PatchOffset), SymbolIndex,
            orkPLT, R_X86_64_PLT32, -4)
        else
          Obj.AddRelocation(TextIndex, QWord(Fixup.PatchOffset), SymbolIndex,
            orkPCRelative32, R_X86_64_PC32, -4);
      end
      else
        Obj.AddRelocation(TextIndex, QWord(Fixup.PatchOffset), SymbolIndex,
          orkPCRelative32, R_X86_64_PC32, Int64(BaseAddend) - 4);
    end;

    for I := 0 to High(FDataAddressFixups) do
    begin
      DataFixup := FDataAddressFixups[I];
      RelocationTarget(DataFixup.TargetLabel, SymbolIndex, BaseAddend);
      Obj.AddRelocation(DataIndex, QWord(DataFixup.PatchOffset), SymbolIndex,
        orkAbsolute64, R_X86_64_64, BaseAddend);
    end;

    for I := 0 to High(FGeneratedObjectRelocations) do
    begin
      GeneratedRelocation := FGeneratedObjectRelocations[I];
      RelocationTarget(GeneratedRelocation.TargetLabel, SymbolIndex,
        BaseAddend);
      if GeneratedRelocation.PatchSection = lsText then
        SectionIndex := TextIndex
      else if GeneratedRelocation.PatchSection = lsData then
        SectionIndex := DataIndex
      else
        raise ERCCError.Create(
          'internal error: generated relocation has no output section');
      Obj.AddRelocation(SectionIndex,
        QWord(GeneratedRelocation.PatchOffset), SymbolIndex, orkGOT,
        GeneratedRelocation.RelocationType,
        GeneratedRelocation.Addend + BaseAddend);
    end;

    if FOptions.DebugInfo then
    begin
      SetLength(DebugFunctions, 0);
      for I := 0 to High(FProgram.Functions) do
        if not FProgram.Functions[I].IsPrototype then
        begin
          SectionIndex := Length(DebugFunctions);
          SetLength(DebugFunctions, SectionIndex + 1);
          SymbolIndex := FindNamedLabel(FFunctions,
            FProgram.Functions[I].Name);
          DebugFunctions[SectionIndex].Name := FProgram.Functions[I].Name;
          DebugFunctions[SectionIndex].FileName :=
            FProgram.Functions[I].Pos.FileName;
          DebugFunctions[SectionIndex].Line := FProgram.Functions[I].Pos.Line;
          DebugFunctions[SectionIndex].TextOffset :=
            QWord(FLabels[SymbolIndex].Offset);
          DebugFunctions[SectionIndex].TextSize := FunctionSize(SymbolIndex);
          DebugFunctions[SectionIndex].IsExternal :=
            not FProgram.Functions[I].IsStatic;
        end;
      if Length(FOptions.Inputs) > 0 then
        DebugSourceName := FOptions.Inputs[0]
      else
        DebugSourceName := Obj.SourceName;
      AddDWARF4ObjectSections(Obj, DebugSourceName, FOptions.Standard,
        TextSectionSymbol, QWord(FText.Size), DebugFunctions);
    end;

    Obj.Section(TextIndex).Data.Append(FText);
    Obj.Section(DataIndex).Data.Append(FData);
    Obj.Validate;
    WriteELF64Relocatable(AFileName, Obj);
    FStats.TextBytes := FText.Size;
    FStats.DataBytes := FData.Size;
  finally
    Obj.Free;
  end;
end;

procedure TX64Backend.WriteELF(const AFileName: string);
var
  Layout: TELFExecutableLayout;
  Target: TTargetDescriptor;
  ResolvedLibraries: TResolvedLibraryArray;
  NeededNames, ImportNames: TLibraryStringArray;
  MultiArch, DynamicLinker: string;
  I, DebugTextIndex, DebugDataIndex, DebugTextSymbol,
    LabelID: LongInt;
  DebugObject: TObjectFile;
  DebugFunctions: TObjectDebugFunctionArray;
  FunctionDecl: TFunction;
  GlobalDecl: TGlobal;
  Binding: TObjectSymbolBinding;
  DebugSourceName: string;

  function DebugFunctionSize(ALabel: LongInt): QWord;
  var
    J, StartOffset, EndOffset, Candidate: LongInt;
  begin
    StartOffset := FLabels[ALabel].Offset;
    EndOffset := FText.Size;
    for J := 0 to High(FFunctions) do
    begin
      Candidate := FLabels[FFunctions[J].LabelID].Offset;
      if (Candidate > StartOffset) and (Candidate < EndOffset) then
        EndOffset := Candidate;
    end;
    Result := QWord(EndOffset - StartOffset);
  end;

  procedure AddExecutableDebugDefinitions(AStatic: Boolean);
  var
    J: LongInt;
  begin
    if AStatic then Binding := osbLocal else Binding := osbGlobal;
    for J := 0 to High(FProgram.Functions) do
    begin
      FunctionDecl := FProgram.Functions[J];
      if FunctionDecl.IsPrototype or
         (FunctionDecl.IsStatic <> AStatic) then Continue;
      LabelID := FindNamedLabel(FFunctions, FunctionDecl.Name);
      DebugObject.AddSymbol(FunctionDecl.Name, Binding, ostFunction,
        osvDefault, DebugTextIndex, QWord(FLabels[LabelID].Offset),
        DebugFunctionSize(LabelID), True);
    end;
    for J := 0 to High(FProgram.Globals) do
    begin
      GlobalDecl := FProgram.Globals[J];
      if GlobalDecl.IsExtern or (GlobalDecl.IsStatic <> AStatic) then Continue;
      LabelID := FindNamedLabel(FGlobals, GlobalDecl.Name);
      DebugObject.AddSymbol(GlobalDecl.Name, Binding, ostObject, osvDefault,
        DebugDataIndex, QWord(FLabels[LabelID].Offset),
        QWord(StorageSize(GlobalDecl.CType)), True);
    end;
  end;

  procedure BuildExecutableDebugObject;
  var
    J, N: LongInt;
  begin
    DebugObject := TObjectFile.Create(Target);
    if Length(FOptions.Inputs) > 0 then
      DebugObject.SourceName := ExtractFileName(FOptions.Inputs[0])
    else
      DebugObject.SourceName := 'rcc-input.c';
    DebugTextIndex := DebugObject.AddSection('.text', oskText,
      [osfAlloc, osfExecute], 16);
    DebugDataIndex := DebugObject.AddSection('.data', oskData,
      [osfAlloc, osfWrite], 16);
    DebugTextSymbol := DebugObject.AddSymbol('', osbLocal, ostSection,
      osvDefault, DebugTextIndex, 0, 0, True);
    DebugObject.AddSymbol('', osbLocal, ostSection, osvDefault,
      DebugDataIndex, 0, 0, True);
    AddExecutableDebugDefinitions(True);
    AddExecutableDebugDefinitions(False);
    SetLength(DebugFunctions, 0);
    for J := 0 to High(FProgram.Functions) do
    begin
      FunctionDecl := FProgram.Functions[J];
      if FunctionDecl.IsPrototype then Continue;
      N := Length(DebugFunctions);
      SetLength(DebugFunctions, N + 1);
      LabelID := FindNamedLabel(FFunctions, FunctionDecl.Name);
      DebugFunctions[N].Name := FunctionDecl.Name;
      DebugFunctions[N].FileName := FunctionDecl.Pos.FileName;
      DebugFunctions[N].Line := FunctionDecl.Pos.Line;
      DebugFunctions[N].TextOffset := QWord(FLabels[LabelID].Offset);
      DebugFunctions[N].TextSize := DebugFunctionSize(LabelID);
      DebugFunctions[N].IsExternal := not FunctionDecl.IsStatic;
    end;
    if Length(FOptions.Inputs) > 0 then DebugSourceName := FOptions.Inputs[0]
    else DebugSourceName := DebugObject.SourceName;
    AddDWARF4ObjectSections(DebugObject, DebugSourceName,
      FOptions.Standard, DebugTextSymbol, QWord(FText.Size), DebugFunctions);
    DebugObject.Validate;
  end;
begin
  DebugObject := nil;
  Layout := ComputeELFExecutableLayout(QWord(FText.Size), QWord(FData.Size),
    QWord(FLabels[FEntryLabel].Offset));
  ResolveFixups(Layout.TextVA, Layout.DataVA);
  ResolveExternalRelocations(Layout.TextVA, Layout.DataVA);

  Target := GetTargetOrRaise(FOptions.TargetTriple);
  try
    MultiArch := TargetMultiArchName(Target);
    if FOptions.StaticLink then
    begin
      if Length(FImports) <> 0 then
        raise ERCCError.Create(
          'internal error: static output retained dynamic imports');
      SetLength(ResolvedLibraries, 0);
    end
    else
      ResolveDynamicLibraries(FOptions.LibraryPaths, FOptions.Libraries,
        FOptions.Sysroot, MultiArch, Target.DefaultLibC,
        ArchitectureName(Target.Architecture), Target.ELFMachine,
        Target.Architecture = archX86_64,
        (Length(FImports) <> 0) or (Length(FOptions.Libraries) <> 0),
        FOptions.NoDefaultLibraries, FOptions.Freestanding,
        ResolvedLibraries);
    NeededNames := ResolvedNeededNames(ResolvedLibraries);
    SetLength(ImportNames, Length(FImports));
    for I := 0 to High(FImports) do ImportNames[I] := FImports[I].Name;
    ValidateDynamicSymbolProviders(ImportNames, ResolvedLibraries,
      Target.ELFMachine);
    DynamicLinker := FOptions.DynamicLinker;
    if DynamicLinker = '' then DynamicLinker := Target.DefaultDynamicLoader;
    if FOptions.DebugInfo then BuildExecutableDebugObject;
    WriteELF64Executable(AFileName, FText, FData,
      QWord(FLabels[FEntryLabel].Offset), FImports, NeededNames,
      FOptions.RPaths, FOptions.BindNow, DynamicLinker);
    if DebugObject <> nil then
      AppendELF64DebugSections(AFileName, DebugObject,
        Layout.TextOffset, Layout.TextVA, QWord(FText.Size),
        Layout.DataOffset, Layout.DataVA, QWord(FData.Size));
    FStats.TextBytes := FText.Size;
    FStats.DataBytes := FData.Size;
  finally
    DebugObject.Free;
  end;
end;

procedure TX64Backend.Generate(const AFileName: string);
begin
  GenerateCode;
  if FOptions.EmitMode = emObject then
    WriteObject(AFileName)
  else if FOptions.EmitMode = emAssembly then
  begin
    BuildAssemblyListing;
    FListing.SaveToFile(AFileName);
  end
  else
    WriteELF(AFileName);
end;

function TX64Backend.AssemblyListing: string;
begin
  Result := FListing.Text;
end;

end.
