unit rcc_backend;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, rcc_types, rcc_runtime_catalog, rcc_buffer, rcc_elf64,
  rcc_typeops, rcc_arch, rcc_name_index;

type
  TBackendStats = record
    TextBytes: QWord;
    DataBytes: QWord;
    FunctionsEmitted: QWord;
    RuntimeFunctions: QWord;
    FixupsResolved: QWord;
  end;

  TLabelSection = (lsUnbound, lsText, lsData, lsBss);

  TLabelInfo = record
    Section: TLabelSection;
    Offset: LongInt;
  end;

  TRelFixupKind = (rfRel32, rfJmpNear, rfJccNear, rfJmpShort, rfJccShort);

  TFixup = record
    PatchOffset: LongInt;
    TargetLabel: LongInt;
    Kind: TRelFixupKind;
    Condition: Byte;
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

  { Scalar values kept in fixed registers.  Ordinals 0/1 are the incoming
    SysV rdi/rsi parameter registers; ordinals 2..5 are the callee-saved
    r12..r15 registers used by conservative local promotion. }
  TRegisterLocal = record
    Name: string;
    CType: TCType;
    RegisterOrdinal: LongInt;
    ScopeDepth: LongInt;
  end;

  TRegisterPlan = record
    Name: string;
    CType: TCType;
    RegisterOrdinal: LongInt;
  end;

  TRegisterCandidate = record
    Name: string;
    CType: TCType;
    DeclarationCount: LongInt;
    Score: LongInt;
    LoopScore: LongInt;
    AddressTaken: Boolean;
    Unsafe: Boolean;
    Selected: Boolean;
  end;
  TRegisterCandidateArray = array of TRegisterCandidate;

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
      FTarget: TTargetDescriptor;
      FText: TByteBuffer;
      FData: TByteBuffer;
      { Zero-initialized globals occupy no file bytes; they are reserved past
        the end of the loaded data image. }
      FBssSize: LongInt;
      FBssBase: QWord;
      { Tracks that rax already holds a value normalized to FRaxStateType.
        Only valid while nothing else has been emitted since (the recorded
        text size still matches) and no label has been bound in between. }
      FRaxStateValid: Boolean;
      FRaxStateOffset: LongInt;
      FRaxStateType: TCType;
      FRaxStateIsZero: Boolean;
      FRaxRegisterLocalValid: Boolean;
      FRaxRegisterLocalOffset: LongInt;
      FRaxRegisterLocalOrdinal: LongInt;
      FBlockStart: LongInt;
      FLoopHeads: array of LongInt;
      FLoopHeadCount: LongInt;
      FStaticLocals: array of TNamedLabel;
      FPlainPrintfChecked: Boolean;
      FPlainPrintfSafe: Boolean;
      FCurrentDeclPos: TSourcePos;
      FLabels: array of TLabelInfo;
      FLabelCapacity: LongInt;
      FLabelCount: LongInt;
      FFixups: array of TFixup;
      FFixupCapacity: LongInt;
      FFixupCount: LongInt;
      FDataAddressFixups: array of TDataAddressFixup;
      FDataAddressFixupCapacity: LongInt;
      FDataAddressFixupCount: LongInt;
      FFunctions: array of TNamedLabel;
      FFunctionIndex: TNameIndex;
      FGlobals: array of TNamedLabel;
      FGlobalLabelIndex: TNameIndex;
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
      FRegisterLocals: array of TRegisterLocal;
      FRegisterPlans: array of TRegisterPlan;
      FRegisterSaveCount: LongInt;
      FUsingCalleeSavedLocals: Boolean;
      FCurrentFrameless: Boolean;
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
      FSyscallSites: TTargetSyscallSiteArray;

    function AlignUp(V, A: QWord): QWord;
    procedure GrowLabelList;
    procedure GrowFixupList;
    procedure GrowDataAddressFixupList;
    function FindFunctionLabel(const AName: string): LongInt;
    function NewLabel: LongInt;
    procedure BindTextLabel(ALabel: LongInt);
    procedure BindDataLabel(ALabel: LongInt);
    procedure BindBssLabel(ALabel: LongInt);
    function ReserveBss(ASize, AAlignment: LongInt): LongInt;
    function BssBaseOffset: QWord;
    procedure AddFixup(ALabel, APatchOffset: LongInt;
      AKind: TRelFixupKind = rfRel32; ACondition: Byte = 0);
    procedure AddDataAddressFixup(ALabel, APatchOffset: LongInt);
    procedure EmitRel32(ALabel: LongInt);
    procedure EmitCall(ALabel: LongInt);
    procedure EmitIndirectCall(ALabel: LongInt);
    procedure EmitJump(ALabel: LongInt);
    procedure EmitJcc(AConditionOpcode: Byte; ALabel: LongInt);
    procedure AdjustTextOffsets(AFrom, ADelta: LongInt);
    procedure RelaxJumps;
    function InsertionKeepsShortJumps(AOffset, APad: LongInt): Boolean;
    procedure AlignLoopHeads;
    procedure NoteLoopHead(ALabel: LongInt);
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
    procedure EmitDirectSyscall(const AName: string);

    procedure EmitMovRaxImm(V: Int64);
    procedure EmitMovRcxImm(V: Int64);
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
    procedure EmitLoadMemoryTyped(const AType: TCType; AModRM: Byte;
      ADisplacement: LongInt; ALabel: LongInt);
    procedure EmitLoadLocalTyped(AOffset: LongInt; const AType: TCType);
    procedure EmitLoadGlobalTyped(ALabel: LongInt; const AType: TCType);
    procedure EmitStoreMemoryTyped(const AType: TCType; AModRM: Byte;
      ADisplacement: LongInt; ALabel: LongInt);
    function TryResolveDirectTarget(E: TExpr;
      out ALocalOffset, ALabel: LongInt): Boolean;
    procedure EmitLoadDirectTarget(ALocalOffset, ALabel: LongInt;
      const AType: TCType);
    procedure EmitStoreDirectTarget(ALocalOffset, ALabel: LongInt;
      const AType: TCType);
    procedure NoteRaxNormalized(const AType: TCType);
    procedure InvalidateRaxState;
    function RaxAlreadyNormalized(const AType: TCType): Boolean;
    function TryLoadOperandToRcx(E: TExpr; const ALocalType: TCType): Boolean;
    procedure EmitStoreRaxAtRcx(const AType: TCType);
    procedure EmitAddRaxImmediate(AValue: LongInt);
    procedure EmitScaleRax(AFactor: LongInt);
    procedure EmitAddScaledRcxToRax(AScale: LongInt);
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
    procedure EmitConvertIntegerToFloat(const AFromType, AToType: TCType);
    procedure EmitConvertFloatToInteger(const AFromType, AToType: TCType);
    procedure EmitConvertFloatWidth(const AFromType, AToType: TCType);

    function AddStringLiteral(const S: string): LongInt;
    procedure PreallocateInitializerLiterals(AExpression: TExpr);
    function AddFloatLiteral(AValue: Double; const AType: TCType): LongInt;
    procedure AllocateGlobals;
    procedure ReserveStaticLocals(S: TStmt);
    function FindStaticLocalLabel(const AName: string): LongInt;
    function ResolveNeededLibraryNames: rcc_types.TStringArray;
    procedure PrepareBssBase(const ANeededNames: array of string);
    function ConstantAddressLabel(AExpression: TExpr): LongInt;
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
    procedure PlanRegisterLocals(F: TFunction);
    function FindRegisterPlan(const AName: string;
      out ARegisterOrdinal: LongInt): Boolean;
    procedure AddRegisterLocal(const AName: string; const AType: TCType;
      ARegisterOrdinal: LongInt);
    function FindRegisterLocal(const AName: string; out ARegisterOrdinal: LongInt;
      out AType: TCType): Boolean;
    procedure EmitLoadRegisterLocalToRax(ARegisterOrdinal: LongInt;
      const AType: TCType);
    procedure EmitLoadRegisterLocalToRcx(ARegisterOrdinal: LongInt;
      const AType: TCType);
    procedure EmitStoreRaxToRegisterLocal(ARegisterOrdinal: LongInt;
      const AType: TCType);
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
    function TryEmitComparisonFlags(E: TExpr; out AJccOpcode: Byte): Boolean;
    procedure GenBranch(E: TExpr; ATargetLabel: LongInt;
      ABranchIfTrue: Boolean);
    function TryGenPlainPrintf(E: TExpr): Boolean;
    function PlainPrintfIsSafe: Boolean;
    procedure GenAggregateABICall(E: TExpr; ACallee: TFunction;
      const AFunctionType: TCType);
    procedure GenAggregateReturn(E: TExpr);
    function TryGenVariadicBuiltin(E: TExpr): Boolean;
    procedure GenCall(E: TExpr);
    procedure GenAssignment(E: TExpr);
    procedure GenIncDec(E: TExpr; ADelta: LongInt; APost: Boolean;
      ADiscardResult: Boolean = False);
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
  rcc_library_resolver, rcc_abi, rcc_elf_reader,
  rcc_object_model, rcc_elf_image, rcc_object_writer, rcc_dwarf,
  rcc_elf_debug;

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



function ExprContainsCall(E: TExpr): Boolean;
var
  I: LongInt;
begin
  if E = nil then Exit(False);
  if E.Kind = ekCall then Exit(True);
  if ExprContainsCall(E.Left) or ExprContainsCall(E.Right) or
     ExprContainsCall(E.Third) then Exit(True);
  for I := 0 to High(E.Args) do
    if ExprContainsCall(E.Args[I]) then Exit(True);
  Result := False;
end;

function StmtContainsCallOrAsm(S: TStmt): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(False);
  if S.Kind = skAsm then Exit(True);
  if ExprContainsCall(S.Expr) or ExprContainsCall(S.Expr2) or
     StmtContainsCallOrAsm(S.InitStmt) or StmtContainsCallOrAsm(S.Body) or
     StmtContainsCallOrAsm(S.ElseBody) then Exit(True);
  for I := 0 to High(S.Children) do
    if StmtContainsCallOrAsm(S.Children[I]) then Exit(True);
  Result := False;
end;

function FindRegisterCandidate(const ACandidates: TRegisterCandidateArray;
  const AName: string): LongInt;
var
  I: LongInt;
begin
  for I := 0 to High(ACandidates) do
    if ACandidates[I].Name = AName then Exit(I);
  Result := -1;
end;

procedure CollectRegisterCandidates(S: TStmt;
  var ACandidates: TRegisterCandidateArray);
var
  I, N: LongInt;
begin
  if S = nil then Exit;
  if S.Kind = skDecl then
  begin
    I := FindRegisterCandidate(ACandidates, S.Name);
    if I < 0 then
    begin
      N := Length(ACandidates);
      SetLength(ACandidates, N + 1);
      I := N;
      ACandidates[I].Name := S.Name;
      ACandidates[I].CType := S.CType;
      ACandidates[I].DeclarationCount := 0;
      ACandidates[I].Score := 0;
      ACandidates[I].LoopScore := 0;
      ACandidates[I].AddressTaken := False;
      ACandidates[I].Unsafe := False;
      ACandidates[I].Selected := False;
    end;
    Inc(ACandidates[I].DeclarationCount);
    if S.IsStatic or S.CType.IsVolatile or
       not (IsIntegerType(S.CType) or IsPointerType(S.CType)) then
      ACandidates[I].Unsafe := True;
  end;
  CollectRegisterCandidates(S.InitStmt, ACandidates);
  CollectRegisterCandidates(S.Body, ACandidates);
  CollectRegisterCandidates(S.ElseBody, ACandidates);
  for I := 0 to High(S.Children) do
    CollectRegisterCandidates(S.Children[I], ACandidates);
end;

procedure ScoreRegisterExpr(E: TExpr; ALoopDepth: LongInt;
  var ACandidates: TRegisterCandidateArray);
var
  I, CandidateIndex, Weight: LongInt;
begin
  if E = nil then Exit;
  if ALoopDepth > 5 then ALoopDepth := 5;
  Weight := 1 shl ALoopDepth;
  if (E.Kind = ekAddress) and (E.Left <> nil) and
     (E.Left.Kind = ekVariable) then
  begin
    CandidateIndex := FindRegisterCandidate(ACandidates, E.Left.Text);
    if CandidateIndex >= 0 then ACandidates[CandidateIndex].AddressTaken := True;
  end;
  if E.Kind = ekVariable then
  begin
    CandidateIndex := FindRegisterCandidate(ACandidates, E.Text);
    if CandidateIndex >= 0 then
    begin
      Inc(ACandidates[CandidateIndex].Score, Weight);
      if ALoopDepth > 0 then
        Inc(ACandidates[CandidateIndex].LoopScore, Weight);
    end;
  end;
  ScoreRegisterExpr(E.Left, ALoopDepth, ACandidates);
  ScoreRegisterExpr(E.Right, ALoopDepth, ACandidates);
  ScoreRegisterExpr(E.Third, ALoopDepth, ACandidates);
  for I := 0 to High(E.Args) do
    ScoreRegisterExpr(E.Args[I], ALoopDepth, ACandidates);
end;

procedure ScoreRegisterStmt(S: TStmt; ALoopDepth: LongInt;
  var ACandidates: TRegisterCandidateArray);
var
  I: LongInt;
begin
  if S = nil then Exit;
  if S.Kind = skAsm then
  begin
    { Inline assembly can mention local names textually or impose register
      constraints that the compact native backend does not model yet. }
    for I := 0 to High(ACandidates) do ACandidates[I].Unsafe := True;
  end;
  case S.Kind of
    skWhile, skDoWhile:
      begin
        ScoreRegisterExpr(S.Expr, ALoopDepth + 1, ACandidates);
        ScoreRegisterStmt(S.Body, ALoopDepth + 1, ACandidates);
        Exit;
      end;
    skFor:
      begin
        ScoreRegisterStmt(S.InitStmt, ALoopDepth, ACandidates);
        ScoreRegisterExpr(S.Expr, ALoopDepth + 1, ACandidates);
        ScoreRegisterExpr(S.Expr2, ALoopDepth + 1, ACandidates);
        ScoreRegisterStmt(S.Body, ALoopDepth + 1, ACandidates);
        Exit;
      end;
  end;
  ScoreRegisterExpr(S.Expr, ALoopDepth, ACandidates);
  ScoreRegisterExpr(S.Expr2, ALoopDepth, ACandidates);
  ScoreRegisterStmt(S.InitStmt, ALoopDepth, ACandidates);
  ScoreRegisterStmt(S.Body, ALoopDepth, ACandidates);
  ScoreRegisterStmt(S.ElseBody, ALoopDepth, ACandidates);
  for I := 0 to High(S.Children) do
    ScoreRegisterStmt(S.Children[I], ALoopDepth, ACandidates);
  for I := 0 to High(S.AsmOutputs) do
    ScoreRegisterExpr(S.AsmOutputs[I].Expr, ALoopDepth, ACandidates);
  for I := 0 to High(S.AsmInputs) do
    ScoreRegisterExpr(S.AsmInputs[I].Expr, ALoopDepth, ACandidates);
end;

function ExprRequiresParameterStorage(E: TExpr; const AName: string): Boolean;
var
  I: LongInt;
begin
  if E = nil then Exit(False);
  { A register-resident parameter needs memory only when its address can
    escape.  Assignments and increments are lowered directly back to the
    resident SysV register. }
  if (E.Kind = ekAddress) and (E.Left <> nil) and
     (E.Left.Kind = ekVariable) and (E.Left.Text = AName) then Exit(True);
  if ExprRequiresParameterStorage(E.Left, AName) or
     ExprRequiresParameterStorage(E.Right, AName) or
     ExprRequiresParameterStorage(E.Third, AName) then Exit(True);
  for I := 0 to High(E.Args) do
    if ExprRequiresParameterStorage(E.Args[I], AName) then Exit(True);
  Result := False;
end;

function StmtRequiresParameterStorage(S: TStmt; const AName: string): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(False);
  if S.Kind = skAsm then Exit(True);
  if ExprRequiresParameterStorage(S.Expr, AName) or
     ExprRequiresParameterStorage(S.Expr2, AName) or
     StmtRequiresParameterStorage(S.InitStmt, AName) or
     StmtRequiresParameterStorage(S.Body, AName) or
     StmtRequiresParameterStorage(S.ElseBody, AName) then Exit(True);
  for I := 0 to High(S.Children) do
    if StmtRequiresParameterStorage(S.Children[I], AName) then Exit(True);
  Result := False;
end;

function ExprSafeForRegisterParameters(E: TExpr): Boolean;
var
  I: LongInt;
begin
  if E = nil then Exit(True);
  if IsFloatingType(E.CType) or IsAggregateType(E.CType) then Exit(False);
  case E.Kind of
    ekInteger, ekVariable, ekUnary, ekBinary, ekAssign, ekConditional,
    ekCast, ekComma, ekSizeof, ekAlignof, ekNullptr, ekPreInc, ekPreDec,
    ekPostInc, ekPostDec:
      ;
  else
    Exit(False);
  end;
  if not ExprSafeForRegisterParameters(E.Left) or
     not ExprSafeForRegisterParameters(E.Right) or
     not ExprSafeForRegisterParameters(E.Third) then Exit(False);
  for I := 0 to High(E.Args) do
    if not ExprSafeForRegisterParameters(E.Args[I]) then Exit(False);
  Result := True;
end;

function StmtSafeForRegisterParameters(S: TStmt): Boolean;
var
  I: LongInt;
begin
  if S = nil then Exit(True);
  if S.Kind = skAsm then Exit(False);
  if (S.Kind = skDecl) and
     not (IsIntegerType(S.CType) or IsPointerType(S.CType)) then Exit(False);
  if not ExprSafeForRegisterParameters(S.Expr) or
     not ExprSafeForRegisterParameters(S.Expr2) or
     not StmtSafeForRegisterParameters(S.InitStmt) or
     not StmtSafeForRegisterParameters(S.Body) or
     not StmtSafeForRegisterParameters(S.ElseBody) then Exit(False);
  for I := 0 to High(S.Children) do
    if not StmtSafeForRegisterParameters(S.Children[I]) then Exit(False);
  Result := True;
end;

constructor TX64Backend.Create(AProgram: TProgram;
  const AOptions: TCompilerOptions);
begin
  inherited Create;
  FProgram := AProgram;
  FOptions := AOptions;
  FTarget := GetTargetOrRaise(AOptions.TargetTriple);
  FText := TByteBuffer.Create;
  FData := TByteBuffer.Create;
  FListing := TStringList.Create;
  FFunctionIndex := TNameIndex.Create(128);
  FGlobalLabelIndex := TNameIndex.Create(128);
  FCurrentIsVariadic := False;
  FCurrentVarArgSaveOffset := 0;
  FCurrentVarArgGPOffset := 0;
  FCurrentVarArgFPOffset := 48;
  FCurrentVarArgStackOffset := 0;
end;

destructor TX64Backend.Destroy;
begin
  FGlobalLabelIndex.Free;
  FFunctionIndex.Free;
  FListing.Free;
  FData.Free;
  FText.Free;
  inherited Destroy;
end;

function TX64Backend.AlignUp(V, A: QWord): QWord;
begin
  Result := (V + A - 1) and not (A - 1);
end;

procedure TX64Backend.EmitDirectSyscall(const AName: string);
var
  Target: TTargetDescriptor;
  Number: LongWord;
  N: LongInt;
begin
  Target := GetTargetOrRaise(FOptions.TargetTriple);
  if not TargetSyscallNumber(Target, AName, Number) then
    raise ERCCError.Create('error: direct ' + AName +
      ' syscall runtime is unavailable for ' + Target.Triple);
  FText.Add8($B8);
  FText.Add32(Number);
  N := Length(FSyscallSites);
  SetLength(FSyscallSites, N + 1);
  FSyscallSites[N].TextOffset := QWord(FText.Size);
  FSyscallSites[N].Number := Number;
  FText.AddBytes([$0F, $05]);
end;

procedure TX64Backend.GrowLabelList;
begin
  if FLabelCount < FLabelCapacity then Exit;
  if FLabelCapacity = 0 then FLabelCapacity := 1024
  else FLabelCapacity := FLabelCapacity * 2;
  SetLength(FLabels, FLabelCapacity);
end;

procedure TX64Backend.GrowFixupList;
begin
  if FFixupCount < FFixupCapacity then Exit;
  if FFixupCapacity = 0 then FFixupCapacity := 2048
  else FFixupCapacity := FFixupCapacity * 2;
  SetLength(FFixups, FFixupCapacity);
end;

procedure TX64Backend.GrowDataAddressFixupList;
begin
  if FDataAddressFixupCount < FDataAddressFixupCapacity then Exit;
  if FDataAddressFixupCapacity = 0 then FDataAddressFixupCapacity := 1024
  else FDataAddressFixupCapacity := FDataAddressFixupCapacity * 2;
  SetLength(FDataAddressFixups, FDataAddressFixupCapacity);
end;

function TX64Backend.NewLabel: LongInt;
begin
  Result := FLabelCount;
  GrowLabelList;
  FLabels[Result].Section := lsUnbound;
  FLabels[Result].Offset := -1;
  Inc(FLabelCount);
end;

procedure TX64Backend.BindTextLabel(ALabel: LongInt);
begin
  if FLabels[ALabel].Section <> lsUnbound then
    raise ERCCError.Create('internal error: label bound twice');
  FLabels[ALabel].Section := lsText;
  FLabels[ALabel].Offset := FText.Size;
  { Control can reach this point from elsewhere, so nothing is known about
    what the preceding instruction left in rax. }
  FBlockStart := FText.Size;
  FRaxStateValid := False;
  FRaxRegisterLocalValid := False;
end;

procedure TX64Backend.InvalidateRaxState;
begin
  FRaxStateValid := False;
  FRaxStateIsZero := False;
  FRaxRegisterLocalValid := False;
end;

procedure TX64Backend.NoteRaxNormalized(const AType: TCType);
begin
  FRaxStateIsZero := False;
  if IsPointerType(AType) or not IsIntegerType(AType) then
  begin
    FRaxStateValid := False;
    Exit;
  end;
  FRaxStateValid := True;
  FRaxStateOffset := FText.Size;
  FRaxStateType := AType;
end;

function TX64Backend.RaxAlreadyNormalized(const AType: TCType): Boolean;
var
  RecordedSize, WantedSize: LongInt;
begin
  Result := False;
  if not FRaxStateValid then Exit;
  { Any later emission moves the text size, which invalidates the note without
    every emitter having to clear it explicitly. }
  if FRaxStateOffset <> FText.Size then Exit;
  if FRaxStateOffset < FBlockStart then Exit;
  if IsPointerType(AType) or not IsIntegerType(AType) then Exit;
  { Zero is already the normalized representation at every integer type. }
  if FRaxStateIsZero then Exit(True);
  RecordedSize := StorageSize(FRaxStateType);
  WantedSize := StorageSize(AType);
  if RecordedSize = WantedSize then
    Exit(FRaxStateType.IsUnsigned = AType.IsUnsigned);
  if RecordedSize > WantedSize then Exit;
  { A zero-extended narrower value is already valid at any wider type; a
    sign-extended one only stays valid while the wider type is also signed. }
  if FRaxStateType.IsUnsigned then Exit(True);
  Result := not AType.IsUnsigned;
end;

procedure TX64Backend.BindDataLabel(ALabel: LongInt);
begin
  if FLabels[ALabel].Section <> lsUnbound then
    raise ERCCError.Create('internal error: label bound twice');
  FLabels[ALabel].Section := lsData;
  FLabels[ALabel].Offset := FData.Size;
end;

procedure TX64Backend.BindBssLabel(ALabel: LongInt);
begin
  if FLabels[ALabel].Section <> lsUnbound then
    raise ERCCError.Create('internal error: label bound twice');
  FLabels[ALabel].Section := lsBss;
  FLabels[ALabel].Offset := FBssSize;
end;

function TX64Backend.ReserveBss(ASize, AAlignment: LongInt): LongInt;
begin
  if AAlignment < 1 then AAlignment := 1;
  while (FBssSize mod AAlignment) <> 0 do Inc(FBssSize);
  Result := FBssSize;
  if ASize < 0 then
    raise ERCCError.Create('internal error: negative zero-fill reservation');
  Inc(FBssSize, ASize);
end;

function TX64Backend.BssBaseOffset: QWord;
begin
  if FBssBase <> 0 then Exit(FBssBase);
  Result := AlignUp(QWord(FData.Size), RCCELFBssAlignment);
end;

procedure TX64Backend.AddFixup(ALabel, APatchOffset: LongInt;
  AKind: TRelFixupKind; ACondition: Byte);
begin
  GrowFixupList;
  FFixups[FFixupCount].PatchOffset := APatchOffset;
  FFixups[FFixupCount].TargetLabel := ALabel;
  FFixups[FFixupCount].Kind := AKind;
  FFixups[FFixupCount].Condition := ACondition;
  Inc(FFixupCount);
end;

procedure TX64Backend.AddDataAddressFixup(ALabel, APatchOffset: LongInt);
begin
  GrowDataAddressFixupList;
  FDataAddressFixups[FDataAddressFixupCount].PatchOffset := APatchOffset;
  FDataAddressFixups[FDataAddressFixupCount].TargetLabel := ALabel;
  Inc(FDataAddressFixupCount);
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
var
  P: LongInt;
begin
  FText.Add8($E9);
  P := FText.Size;
  FText.Add32(0);
  AddFixup(ALabel, P, rfJmpNear);
end;

procedure TX64Backend.EmitJcc(AConditionOpcode: Byte; ALabel: LongInt);
var
  P: LongInt;
begin
  FText.Add8($0F);
  FText.Add8(AConditionOpcode);
  P := FText.Size;
  FText.Add32(0);
  AddFixup(ALabel, P, rfJccNear, AConditionOpcode);
end;

procedure TX64Backend.AdjustTextOffsets(AFrom, ADelta: LongInt);
var
  I: LongInt;
begin
  for I := 0 to FLabelCount - 1 do
    if (FLabels[I].Section = lsText) and (FLabels[I].Offset >= AFrom) then
      Inc(FLabels[I].Offset, ADelta);
  for I := 0 to FFixupCount - 1 do
    if FFixups[I].PatchOffset >= AFrom then
      Inc(FFixups[I].PatchOffset, ADelta);
  for I := 0 to High(FGeneratedObjectRelocations) do
    if (FGeneratedObjectRelocations[I].PatchSection = lsText) and
       (FGeneratedObjectRelocations[I].PatchOffset >= AFrom) then
      Inc(FGeneratedObjectRelocations[I].PatchOffset, ADelta);
  for I := 0 to High(FExternalRelocations) do
    if (FExternalRelocations[I].PatchSection = lsText) and
       (FExternalRelocations[I].PatchOffset >= AFrom) then
      Inc(FExternalRelocations[I].PatchOffset, ADelta);
  for I := 0 to High(FSyscallSites) do
    if LongInt(FSyscallSites[I].TextOffset) >= AFrom then
      FSyscallSites[I].TextOffset :=
        QWord(LongInt(FSyscallSites[I].TextOffset) + ADelta);
end;

procedure TX64Backend.NoteLoopHead(ALabel: LongInt);
begin
  if FOptions.OptimizeSize or (FOptions.OptimizationLevel < 2) then Exit;
  if FLoopHeadCount >= Length(FLoopHeads) then
    SetLength(FLoopHeads, (FLoopHeadCount + 1) * 2);
  FLoopHeads[FLoopHeadCount] := ALabel;
  Inc(FLoopHeadCount);
end;

procedure TX64Backend.RelaxJumps;
var
  I, OpcodeOffset, Shrink, DeleteAt, TargetOffset: LongInt;
  NearDisp, ShortDisp: Int64;
  Changed: Boolean;
  L: TLabelInfo;
begin
  repeat
    Changed := False;
    for I := 0 to FFixupCount - 1 do
    begin
      if not (FFixups[I].Kind in [rfJmpNear, rfJccNear]) then Continue;
      L := FLabels[FFixups[I].TargetLabel];
      if L.Section <> lsText then Continue;
      TargetOffset := L.Offset;
      if FFixups[I].Kind = rfJmpNear then
      begin
        OpcodeOffset := FFixups[I].PatchOffset - 1;
        if (OpcodeOffset < 0) or (FText.ByteAt(OpcodeOffset) <> $E9) then
          raise ERCCError.Create('internal error: corrupt near jmp fixup');
        NearDisp := Int64(TargetOffset) - (Int64(FFixups[I].PatchOffset) + 4);
        if TargetOffset >= OpcodeOffset + 5 then
          ShortDisp := NearDisp
        else
          ShortDisp := NearDisp + 3;
        if (ShortDisp < -128) or (ShortDisp > 127) then Continue;
        FText.Patch8(OpcodeOffset, $EB);
        DeleteAt := OpcodeOffset + 2;
        Shrink := 3;
        FFixups[I].Kind := rfJmpShort;
      end
      else
      begin
        OpcodeOffset := FFixups[I].PatchOffset - 2;
        if (OpcodeOffset < 0) or (FText.ByteAt(OpcodeOffset) <> $0F) or
           (FText.ByteAt(OpcodeOffset + 1) <> FFixups[I].Condition) then
          raise ERCCError.Create('internal error: corrupt near jcc fixup');
        NearDisp := Int64(TargetOffset) - (Int64(FFixups[I].PatchOffset) + 4);
        if TargetOffset >= OpcodeOffset + 6 then
          ShortDisp := NearDisp
        else
          ShortDisp := NearDisp + 4;
        if (ShortDisp < -128) or (ShortDisp > 127) then Continue;
        FText.Patch8(OpcodeOffset, Byte(FFixups[I].Condition - $10));
        DeleteAt := OpcodeOffset + 2;
        Shrink := 4;
        FFixups[I].Kind := rfJccShort;
        FFixups[I].PatchOffset := OpcodeOffset + 1;
      end;
      FText.DeleteBytes(DeleteAt, Shrink);
      { Offsets at or past the removed bytes are rewritten in place, so the
        scan can carry on from here rather than restarting. }
      AdjustTextOffsets(DeleteAt + Shrink, -Shrink);
      Changed := True;
    end;
  until not Changed;
end;

{ Multi-byte no-ops, indexed by length. Padding inserted ahead of a loop head
  is reached by fall-through, so it has to be executable. }
function NopPadding(ALength: LongInt): TBytes;
begin
  case ALength of
    1: Result := [$90];
    2: Result := [$66, $90];
    3: Result := [$0F, $1F, $00];
    4: Result := [$0F, $1F, $40, $00];
    5: Result := [$0F, $1F, $44, $00, $00];
    6: Result := [$66, $0F, $1F, $44, $00, $00];
    7: Result := [$0F, $1F, $80, $00, $00, $00, $00];
    8: Result := [$0F, $1F, $84, $00, $00, $00, $00, $00];
    9: Result := [$66, $0F, $1F, $84, $00, $00, $00, $00, $00];
    10: Result := [$66, $66, $0F, $1F, $84, $00, $00, $00, $00, $00];
    11: Result := [$66, $66, $66, $0F, $1F, $84, $00, $00, $00, $00, $00];
  else
    Result := nil;
  end;
end;

{ True when growing the text at AOffset by APad keeps every already-shortened
  branch inside its one-byte displacement. }
function TX64Backend.InsertionKeepsShortJumps(AOffset, APad: LongInt): Boolean;
var
  I, Site, Target: LongInt;
  Displacement: Int64;
begin
  for I := 0 to FFixupCount - 1 do
  begin
    if not (FFixups[I].Kind in [rfJmpShort, rfJccShort]) then Continue;
    if FLabels[FFixups[I].TargetLabel].Section <> lsText then Continue;
    Site := FFixups[I].PatchOffset + 1;
    Target := FLabels[FFixups[I].TargetLabel].Offset;
    if Site >= AOffset then Inc(Site, APad);
    if Target >= AOffset then Inc(Target, APad);
    Displacement := Int64(Target) - Int64(Site);
    if (Displacement < -128) or (Displacement > 127) then Exit(False);
  end;
  Result := True;
end;

{ Pads loop entry points onto a 16-byte boundary. Runs after relaxation so the
  padding is not invalidated by branches shrinking afterwards. }
procedure TX64Backend.AlignLoopHeads;
var
  I, Offset, Pad: LongInt;
  Padding: TBytes;
begin
  for I := 0 to FLoopHeadCount - 1 do
  begin
    if FLabels[FLoopHeads[I]].Section <> lsText then Continue;
    Offset := FLabels[FLoopHeads[I]].Offset;
    Pad := (16 - (Offset mod 16)) mod 16;
    if (Pad = 0) or (Pad > 11) then Continue;
    if not InsertionKeepsShortJumps(Offset, Pad) then Continue;
    Padding := NopPadding(Pad);
    if Padding = nil then Continue;
    FText.InsertBytes(Offset, Padding);
    AdjustTextOffsets(Offset, Pad);
  end;
end;

procedure TX64Backend.ResolveFixups(ATextVA, ADataVA: QWord);
var
  I: LongInt;
  TargetVA, NextVA: Int64;
  L: TLabelInfo;
  Disp: Int64;
  DispSize: LongInt;
begin
  for I := 0 to FFixupCount - 1 do
  begin
    L := FLabels[FFixups[I].TargetLabel];
    if L.Section = lsUnbound then
      raise ERCCError.Create('internal error: unresolved backend label');
    if L.Section = lsText then TargetVA := Int64(ATextVA) + L.Offset
    else if L.Section = lsBss then
      TargetVA := Int64(ADataVA) + Int64(BssBaseOffset) + L.Offset
    else TargetVA := Int64(ADataVA) + L.Offset;
    if FFixups[I].Kind in [rfJmpShort, rfJccShort] then DispSize := 1
    else DispSize := 4;
    NextVA := Int64(ATextVA) + FFixups[I].PatchOffset + DispSize;
    Disp := TargetVA - NextVA;
    if DispSize = 1 then
    begin
      if (Disp < -128) or (Disp > 127) then
        raise ERCCError.Create('internal error: short jump displacement out of range');
      FText.Patch8(FFixups[I].PatchOffset, Byte(LongWord(Disp) and $FF));
    end
    else
    begin
      if (Disp < Low(LongInt)) or (Disp > High(LongInt)) then
        raise ERCCError.Create('internal error: x86-64 relative relocation overflow');
      FText.Patch32(FFixups[I].PatchOffset, LongInt(Disp));
    end;
    Inc(FStats.FixupsResolved);
  end;
  for I := 0 to FDataAddressFixupCount - 1 do
  begin
    L := FLabels[FDataAddressFixups[I].TargetLabel];
    if L.Section = lsUnbound then
      raise ERCCError.Create('internal error: unresolved data address label');
    if L.Section = lsText then TargetVA := Int64(ATextVA) + L.Offset
    else if L.Section = lsBss then
      TargetVA := Int64(ADataVA) + Int64(BssBaseOffset) + L.Offset
    else TargetVA := Int64(ADataVA) + L.Offset;
    FData.Patch64(FDataAddressFixups[I].PatchOffset, QWord(TargetVA));
    Inc(FStats.FixupsResolved);
  end;
end;

function TX64Backend.FindFunctionLabel(const AName: string): LongInt;
begin
  Result := FFunctionIndex.GetOrDefault(AName, -1);
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
    Result := FindFunctionLabel(AName);
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
    if (FindFunctionLabel(AName) >= 0) or
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
    if (FindFunctionLabel(AName) >= 0) or
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
    if (ALabel < 0) or (ALabel >= FLabelCount) or
       (FLabels[ALabel].Section = lsUnbound) then
      raise ERCCError.Create('internal error: unresolved external relocation label');
    if FLabels[ALabel].Section = lsText then
      Result := ATextVA + QWord(FLabels[ALabel].Offset)
    else if FLabels[ALabel].Section = lsBss then
      Result := ADataVA + BssBaseOffset + QWord(FLabels[ALabel].Offset)
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
  { Function declarations are indexed by TProgram.  This path is reached for
    every unresolved call while emitting a translation unit, so a linear scan
    here turned external-call-heavy files into another avoidable O(n^2) case. }
  Declared := FProgram.FindFunctionIndex(AName) >= 0;
  if FOptions.EmitMode = emObject then
  begin
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
  Result := FindFunctionLabel(AName);
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
  if V = 0 then
  begin
    FText.AddBytes([$31, $C0]);
    FRaxStateValid := True;
    FRaxStateOffset := FText.Size;
    FRaxStateIsZero := False;
    FRaxStateValid := False;
    Exit;
  end;
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

procedure TX64Backend.EmitMovRcxImm(V: Int64);
begin
  if (V >= Low(LongInt)) and (V <= High(LongInt)) then
  begin
    FText.AddBytes([$48, $C7, $C1]);
    FText.AddI32(LongInt(V));
  end
  else
  begin
    FText.AddBytes([$48, $B9]);
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
  NoteRaxNormalized(AType);
end;

{ Emits the same widening load as EmitLoadAtRax but straight from a memory
  operand, so a variable read costs one instruction instead of an address
  computation followed by a dereference. AModRM selects the operand form and
  ADisplacement its 32-bit displacement. }
procedure TX64Backend.EmitLoadMemoryTyped(const AType: TCType; AModRM: Byte;
  ADisplacement: LongInt; ALabel: LongInt);
var
  Size: LongInt;

  procedure Operand(const APrefix: array of Byte);
  begin
    FText.AddBytes(APrefix);
    FText.Add8(AModRM);
    if ALabel >= 0 then EmitRel32(ALabel)
    else FText.AddI32(ADisplacement);
  end;

begin
  if IsAggregateType(AType) or IsFunctionType(AType) then Exit;
  if IsFloatingType(AType) then
  begin
    case AType.Kind of
      ctFloat: Operand([$F3, $0F, $10]);
      ctDouble: Operand([$F2, $0F, $10]);
    else
      raise ERCCError.Create('long double scalar loads are unsupported by the x86-64 backend');
    end;
    Exit;
  end;
  Size := StorageSize(AType);
  case Size of
    1:
      if AType.IsUnsigned or (AType.Kind = ctBool) then Operand([$0F, $B6])
      else Operand([$48, $0F, $BE]);
    2:
      if AType.IsUnsigned then Operand([$0F, $B7])
      else Operand([$48, $0F, $BF]);
    4:
      if AType.IsUnsigned then Operand([$8B])
      else Operand([$48, $63]);
    8: Operand([$48, $8B]);
  else
    raise ERCCError.Create('internal error: unsupported scalar load width ' +
      IntToStr(Size));
  end;
  NoteRaxNormalized(AType);
end;

procedure TX64Backend.EmitLoadLocalTyped(AOffset: LongInt;
  const AType: TCType);
begin
  EmitLoadMemoryTyped(AType, $85, -AOffset, -1);
end;

procedure TX64Backend.EmitLoadGlobalTyped(ALabel: LongInt;
  const AType: TCType);
begin
  EmitLoadMemoryTyped(AType, $05, 0, ALabel);
end;

{ Counterpart of EmitStoreRaxAtRcx that writes straight to a memory operand,
  so storing to a plain variable needs no address register. }
procedure TX64Backend.EmitStoreMemoryTyped(const AType: TCType; AModRM: Byte;
  ADisplacement: LongInt; ALabel: LongInt);
var
  Size: LongInt;

  procedure Operand(const APrefix: array of Byte);
  begin
    FText.AddBytes(APrefix);
    FText.Add8(AModRM);
    if ALabel >= 0 then EmitRel32(ALabel)
    else FText.AddI32(ADisplacement);
  end;

begin
  if IsFloatingType(AType) then
  begin
    case AType.Kind of
      ctFloat: Operand([$F3, $0F, $11]);
      ctDouble: Operand([$F2, $0F, $11]);
    else
      raise ERCCError.Create('long double scalar stores are unsupported by the x86-64 backend');
    end;
    Exit;
  end;
  Size := StorageSize(AType);
  case Size of
    1: Operand([$88]);
    2: Operand([$66, $89]);
    4: Operand([$89]);
    8: Operand([$48, $89]);
  else
    raise ERCCError.Create('internal error: unsupported scalar store width ' +
      IntToStr(Size));
  end;
end;

{ Recognizes destinations that live at a fixed address: a non-indirect local
  slot or a global defined in this translation unit. }
function TX64Backend.TryResolveDirectTarget(E: TExpr;
  out ALocalOffset, ALabel: LongInt): Boolean;
var
  LocalType: TCType;
  IndirectLocal: Boolean;
begin
  Result := False;
  ALocalOffset := 0;
  ALabel := -1;
  if (E = nil) or (E.Kind <> ekVariable) then Exit;
  if E.IsFunctionDesignator or E.IsBitField then Exit;
  if IsAggregateType(E.CType) or IsFunctionType(E.CType) then Exit;
  if FindLocal(E.Text, ALocalOffset, LocalType, IndirectLocal) then
  begin
    if IndirectLocal then Exit;
    Exit(True);
  end;
  ALabel := FindStaticLocalLabel(E.Text);
  if ALabel < 0 then ALabel := FindNamedLabel(FGlobals, E.Text);
  Result := ALabel >= 0;
end;

procedure TX64Backend.EmitLoadDirectTarget(ALocalOffset, ALabel: LongInt;
  const AType: TCType);
begin
  if ALabel >= 0 then EmitLoadGlobalTyped(ALabel, AType)
  else EmitLoadLocalTyped(ALocalOffset, AType);
end;

procedure TX64Backend.EmitStoreDirectTarget(ALocalOffset, ALabel: LongInt;
  const AType: TCType);
begin
  if ALabel >= 0 then EmitStoreMemoryTyped(AType, $05, 0, ALabel)
  else EmitStoreMemoryTyped(AType, $85, -ALocalOffset, -1);
end;

{ Loads a plain variable operand straight into rcx, letting a binary operation
  skip the push/pop round trip through the stack. Only used when the variable's
  own width and signedness already match the operation type, so the widening
  load also performs the normalization the stack path would have done. }
function TX64Backend.TryLoadOperandToRcx(E: TExpr;
  const ALocalType: TCType): Boolean;
var
  TargetOffset, TargetLabel, RegisterOrdinal: LongInt;
  RegisterType, ExistingType: TCType;
  ImmediateValue: Int64;
  ShiftCount: Byte;
  IndirectLocal: Boolean;
begin
  Result := False;
  if FOptions.OptimizationLevel < 1 then Exit;
  if E = nil then Exit;
  if (E.Kind = ekBinary) and
     (E.BinaryOp in [boShiftLeft, boShiftRight]) and
     (E.Right <> nil) and (E.Right.Kind = ekInteger) and
     (StorageSize(E.CType) = 8) and
     (StorageSize(E.Left.CType) = 8) and
     (StorageSize(ALocalType) = 8) and
     TryLoadOperandToRcx(E.Left, ALocalType) then
  begin
    ShiftCount := Byte(QWord(E.Right.IntValue) and 63);
    if E.BinaryOp = boShiftLeft then
      FText.AddBytes([$48, $C1, $E1, ShiftCount])
    else if E.OperationType.IsUnsigned then
      FText.AddBytes([$48, $C1, $E9, ShiftCount])
    else
      FText.AddBytes([$48, $C1, $F9, ShiftCount]);
    InvalidateRaxState;
    Exit(True);
  end;
  if (E.Kind = ekInteger) and IsIntegerType(ALocalType) then
  begin
    ImmediateValue := ConvertIntegerValue(E.IntValue, ALocalType);
    EmitMovRcxImm(ImmediateValue);
    InvalidateRaxState;
    Exit(True);
  end;
  if IsFloatingType(E.CType) or IsFloatingType(ALocalType) then Exit;
  if StorageSize(E.CType) <> StorageSize(ALocalType) then Exit;
  if E.CType.IsUnsigned <> ALocalType.IsUnsigned then Exit;
  if E.CType.Kind = ctBool then Exit;
  if E.Kind = ekVariable then
  begin
    { A stack local may shadow a register-resident parameter. }
    if not FindLocal(E.Text, TargetOffset, ExistingType, IndirectLocal) and
       FindRegisterLocal(E.Text, RegisterOrdinal, RegisterType) then
    begin
      if StorageSize(RegisterType) <> 8 then Exit(False);
      EmitLoadRegisterLocalToRcx(RegisterOrdinal, RegisterType);
      Exit(True);
    end;
  end;
  if not TryResolveDirectTarget(E, TargetOffset, TargetLabel) then Exit;
  if TargetLabel >= 0 then EmitLoadMemoryTyped(E.CType, $0D, 0, TargetLabel)
  else EmitLoadMemoryTyped(E.CType, $8D, -TargetOffset, -1);
  { The widening load wrote rcx, not rax. }
  InvalidateRaxState;
  Result := True;
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

{ rax := rax + rcx * AScale, using a scaled-index lea where the hardware
  supports the factor directly. }
procedure TX64Backend.EmitAddScaledRcxToRax(AScale: LongInt);
begin
  case AScale of
    1: FText.AddBytes([$48, $8D, $04, $08]);
    2: FText.AddBytes([$48, $8D, $04, $48]);
    4: FText.AddBytes([$48, $8D, $04, $88]);
    8: FText.AddBytes([$48, $8D, $04, $C8]);
  else
    begin
      FText.AddBytes([$48, $69, $C9]);
      FText.AddI32(AScale);
      FText.AddBytes([$48, $01, $C8]);
    end;
  end;
  InvalidateRaxState;
end;

procedure TX64Backend.EmitScaleRax(AFactor: LongInt);
var
  Shift: Byte;
  Remaining: LongWord;
begin
  if AFactor <= 1 then Exit;
  if (LongWord(AFactor) and LongWord(AFactor - 1)) = 0 then
  begin
    Shift := 0;
    Remaining := LongWord(AFactor);
    while Remaining > 1 do
    begin
      Remaining := Remaining shr 1;
      Inc(Shift);
    end;
    FText.AddBytes([$48, $C1, $E0, Shift]);
    Exit;
  end;
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
  if RaxAlreadyNormalized(AType) then Exit;
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
  NoteRaxNormalized(AType);
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

function RotateOperandSafe(E: TExpr): Boolean;
begin
  if E = nil then Exit(True);
  if E.CType.IsVolatile then Exit(False);
  case E.Kind of
    ekInteger:
      Result := True;
    ekVariable:
      Result := not E.CType.IsVolatile;
    ekUnary, ekCast:
      Result := RotateOperandSafe(E.Left);
    ekBinary:
      Result := RotateOperandSafe(E.Left) and RotateOperandSafe(E.Right);
  else
    { Calls, assignments, increments, dereferences and address expressions can
      observe state, produce side effects, or access volatile storage. }
    Result := False;
  end;
end;

function SameRotateOperand(A, B: TExpr): Boolean;
begin
  if (A = nil) or (B = nil) then Exit(A = B);
  if not RotateOperandSafe(A) or not RotateOperandSafe(B) then Exit(False);
  if (A.Kind <> B.Kind) or not TypesEqual(A.CType, B.CType) then Exit(False);
  case A.Kind of
    ekInteger:
      Result := A.IntValue = B.IntValue;
    ekVariable:
      Result := A.Text = B.Text;
    ekUnary:
      Result := (A.UnaryOp = B.UnaryOp) and
        SameRotateOperand(A.Left, B.Left);
    ekBinary:
      Result := (A.BinaryOp = B.BinaryOp) and
        SameRotateOperand(A.Left, B.Left) and
        SameRotateOperand(A.Right, B.Right);
    ekCast:
      Result := SameRotateOperand(A.Left, B.Left);
  else
    Result := False;
  end;
end;

function TryMatchRotate(E: TExpr; out AValue: TExpr;
  out ACount: Byte; out ARotateLeft: Boolean): Boolean;
var
  LeftShift, RightShift: TExpr;
  LeftCount, RightCount, Width: Int64;
begin
  Result := False;
  AValue := nil;
  ACount := 0;
  ARotateLeft := True;
  if (E = nil) or (E.Kind <> ekBinary) or
     not (E.BinaryOp in [boBitOr, boBitXor]) then Exit;
  Width := StorageSize(E.CType) * 8;
  if (Width <> 32) and (Width <> 64) then Exit;

  if (E.Left <> nil) and (E.Left.Kind = ekBinary) and
     (E.Left.BinaryOp = boShiftLeft) and
     (E.Right <> nil) and (E.Right.Kind = ekBinary) and
     (E.Right.BinaryOp = boShiftRight) then
  begin
    LeftShift := E.Left;
    RightShift := E.Right;
    ARotateLeft := True;
  end
  else if (E.Left <> nil) and (E.Left.Kind = ekBinary) and
          (E.Left.BinaryOp = boShiftRight) and
          (E.Right <> nil) and (E.Right.Kind = ekBinary) and
          (E.Right.BinaryOp = boShiftLeft) then
  begin
    RightShift := E.Left;
    LeftShift := E.Right;
    ARotateLeft := False;
  end
  else
    Exit;

  if (LeftShift.Right = nil) or (RightShift.Right = nil) or
     (LeftShift.Right.Kind <> ekInteger) or
     (RightShift.Right.Kind <> ekInteger) or
     not SameRotateOperand(LeftShift.Left, RightShift.Left) or
     not RightShift.OperationType.IsUnsigned then Exit;
  LeftCount := LeftShift.Right.IntValue mod Width;
  RightCount := RightShift.Right.IntValue mod Width;
  if LeftCount < 0 then Inc(LeftCount, Width);
  if RightCount < 0 then Inc(RightCount, Width);
  if (LeftCount = 0) or (RightCount = 0) or
     (LeftCount + RightCount <> Width) then Exit;

  AValue := LeftShift.Left;
  if ARotateLeft then ACount := Byte(LeftCount)
  else ACount := Byte(RightCount);
  Result := True;
end;

procedure TX64Backend.EmitImmediateOperation(AOp: TBinaryOp; V: Int64;
  AUnsigned: Boolean; out AHandled: Boolean);
var
  Shift: Byte;
  Divisor, Mask: Int64;
  NegativeDivisor: Boolean;
begin
  AHandled := False;
  if (V < Low(LongInt)) or (V > High(LongInt)) then Exit;
  case AOp of
    boAdd:
      begin
        if V = 0 then
        begin
          { Identity operation: emit nothing. }
        end
        else if (V >= -128) and (V <= 127) then
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
        if V = 0 then
        begin
          { Identity operation: emit nothing. }
        end
        else if (V >= -128) and (V <= 127) then
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
        if V = -1 then
        begin
          { Identity operation: emit nothing. }
        end
        else if V = 0 then
          FText.AddBytes([$31, $C0])
        else if (V >= -128) and (V <= 127) then
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
        if V = 0 then
        begin
          { Identity operation: emit nothing. }
        end
        else if (V >= -128) and (V <= 127) then
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
        if V = 0 then
        begin
          { Identity operation: emit nothing. }
        end
        else if V = -1 then
          FText.AddBytes([$48, $F7, $D0])
        else if (V >= -128) and (V <= 127) then
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
        if (FOptions.OptimizationLevel >= 1) and (V = 0) then
        begin
          FText.AddBytes([$31, $C0]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 1) and (V = 1) then
          AHandled := True
        else if (FOptions.OptimizationLevel >= 1) and IsPowerOfTwo(V, Shift) then
        begin
          if Shift > 0 then FText.AddBytes([$48, $C1, $E0, Shift]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 1) and (V = -1) then
        begin
          FText.AddBytes([$48, $F7, $D8]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 1) and (V = 3) then
        begin
          FText.AddBytes([$48, $8D, $04, $40]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 1) and (V = 5) then
        begin
          FText.AddBytes([$48, $8D, $04, $80]);
          AHandled := True;
        end
        else if (FOptions.OptimizationLevel >= 1) and (V = 9) then
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
        if FOptions.OptimizationLevel < 1 then Exit;
        if AUnsigned then
        begin
          if IsPowerOfTwo(V, Shift) then
          begin
            if Shift > 0 then FText.AddBytes([$48, $C1, $E8, Shift]);
            AHandled := True;
          end;
          Exit;
        end;
        if V = -1 then
        begin
          FText.AddBytes([$48, $F7, $D8]);
          AHandled := True;
          Exit;
        end;
        NegativeDivisor := V < 0;
        if NegativeDivisor then Divisor := -V else Divisor := V;
        if not IsPowerOfTwo(Divisor, Shift) then Exit;
        if Shift > 0 then
        begin
          Mask := Divisor - 1;
          FText.AddBytes([$48, $89, $C2]);       { mov rdx,rax }
          FText.AddBytes([$48, $C1, $FA, $3F]); { sar rdx,63 }
          if Mask <= 127 then
            FText.AddBytes([$48, $83, $E2, Byte(Mask)])
          else
          begin
            FText.AddBytes([$48, $81, $E2]);
            FText.AddI32(LongInt(Mask));
          end;
          FText.AddBytes([$48, $01, $D0]);       { add rax,rdx }
          FText.AddBytes([$48, $C1, $F8, Shift]);
        end;
        if NegativeDivisor then FText.AddBytes([$48, $F7, $D8]);
        AHandled := True;
      end;
    boMod:
      begin
        if FOptions.OptimizationLevel < 1 then Exit;
        if AUnsigned then
        begin
          if IsPowerOfTwo(V, Shift) then
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
          Exit;
        end;
        if V < 0 then Divisor := -V else Divisor := V;
        if not IsPowerOfTwo(Divisor, Shift) then Exit;
        if Shift = 0 then
          FText.AddBytes([$31, $C0])
        else
        begin
          Mask := Divisor - 1;
          FText.AddBytes([$48, $89, $C2]);       { original in rdx }
          FText.AddBytes([$48, $89, $C1]);       { bias source in rcx }
          FText.AddBytes([$48, $C1, $F9, $3F]); { sar rcx,63 }
          if Mask <= 127 then
            FText.AddBytes([$48, $83, $E1, Byte(Mask)])
          else
          begin
            FText.AddBytes([$48, $81, $E1]);
            FText.AddI32(LongInt(Mask));
          end;
          FText.AddBytes([$48, $01, $C8]);       { add rax,rcx }
          FText.AddBytes([$48, $C1, $F8, Shift]);
          FText.AddBytes([$48, $C1, $E0, Shift]);
          FText.AddBytes([$48, $29, $C2]);       { sub rdx,rax }
          FText.AddBytes([$48, $89, $D0]);       { mov rax,rdx }
        end;
        AHandled := True;
      end;
    boShiftLeft:
      begin
        if (V and 63) <> 0 then
          FText.AddBytes([$48, $C1, $E0, Byte(V and 63)]);
        AHandled := True;
      end;
    boShiftRight:
      begin
        if (V and 63) <> 0 then
          if AUnsigned then FText.AddBytes([$48, $C1, $E8, Byte(V and 63)])
          else FText.AddBytes([$48, $C1, $F8, Byte(V and 63)]);
        AHandled := True;
      end;
    boEqual, boNotEqual, boLess, boLessEqual, boGreater, boGreaterEqual:
      begin
        if V = 0 then
          FText.AddBytes([$48, $85, $C0])
        else if (V >= -128) and (V <= 127) then
          FText.AddBytes([$48, $83, $F8, Byte(LongWord(V) and $FF)])
        else
        begin
          FText.AddBytes([$48, $3D]);
          FText.AddI32(LongInt(V));
        end;
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

procedure TX64Backend.EmitConvertIntegerToFloat(const AFromType,
  AToType: TCType);
var
  NormalLabel, DoneLabel: LongInt;

  procedure EmitSignedConversion;
  begin
    if AToType.Kind = ctFloat then FText.Add8($F3) else FText.Add8($F2);
    FText.AddBytes([$48, $0F, $2A, $C0]);
  end;

begin
  if AToType.Kind = ctLongDouble then
    raise ERCCError.Create(
      'long double conversion is unsupported by the x86-64 backend');

  { CVTSI2SS/CVTSI2SD interprets its 64-bit source as signed.  Values of
    unsigned types narrower than 64 bits are already zero-extended and fit in
    that signed domain.  For a full-width unsigned value, halve-and-round,
    convert, then double; this is the standard exact lowering used to cover
    the upper half of the uint64_t range without an out-of-range signed
    conversion. }
  if AFromType.IsUnsigned and (StorageSize(AFromType) = 8) and
     not IsPointerType(AFromType) then
  begin
    NormalLabel := NewLabel;
    DoneLabel := NewLabel;
    FText.AddBytes([$48, $85, $C0]);       { test rax, rax }
    EmitJcc($89, NormalLabel);             { jns normal }
    FText.AddBytes([$48, $89, $C1]);       { mov rcx, rax }
    FText.AddBytes([$48, $D1, $E8]);       { shr rax, 1 }
    FText.AddBytes([$83, $E1, $01]);       { and ecx, 1 }
    FText.AddBytes([$48, $09, $C8]);       { or rax, rcx }
    EmitSignedConversion;
    if AToType.Kind = ctFloat then FText.Add8($F3) else FText.Add8($F2);
    FText.AddBytes([$0F, $58, $C0]);       { addss/addsd xmm0, xmm0 }
    EmitJump(DoneLabel);
    BindTextLabel(NormalLabel);
    EmitSignedConversion;
    BindTextLabel(DoneLabel);
  end
  else
    EmitSignedConversion;
end;

procedure TX64Backend.EmitConvertFloatToInteger(const AFromType,
  AToType: TCType);
var
  SmallLabel, DoneLabel, ThresholdLabel: LongInt;

  procedure EmitSignedConversion;
  begin
    if AFromType.Kind = ctFloat then FText.Add8($F3) else FText.Add8($F2);
    FText.AddBytes([$48, $0F, $2C, $C0]);
  end;

begin
  if AFromType.Kind = ctLongDouble then
    raise ERCCError.Create(
      'long double conversion is unsupported by the x86-64 backend');

  if AToType.Kind = ctBool then
  begin
    EmitFloatToBool(AFromType);
    Exit;
  end;

  { CVTTSS2SI/CVTTSD2SI also has only a signed 64-bit destination.  Split
    an in-range uint64_t conversion at 2^63: values below the boundary use the
    normal conversion, while values above it subtract the exactly
    representable boundary and restore the high bit afterwards. }
  if AToType.IsUnsigned and (StorageSize(AToType) = 8) and
     not IsPointerType(AToType) then
  begin
    ThresholdLabel := AddFloatLiteral(9223372036854775808.0, AFromType);
    if AFromType.Kind = ctFloat then
      FText.AddBytes([$F3, $0F, $10, $0D])
    else
      FText.AddBytes([$F2, $0F, $10, $0D]);
    EmitRel32(ThresholdLabel);              { xmm1 := 2^63 }
    if AFromType.Kind = ctDouble then FText.Add8($66);
    FText.AddBytes([$0F, $2E, $C1]);        { ucomiss/ucomisd xmm0, xmm1 }
    SmallLabel := NewLabel;
    DoneLabel := NewLabel;
    EmitJcc($82, SmallLabel);               { jb small }
    if AFromType.Kind = ctFloat then FText.Add8($F3) else FText.Add8($F2);
    FText.AddBytes([$0F, $5C, $C1]);        { subss/subsd xmm0, xmm1 }
    EmitSignedConversion;
    FText.AddBytes([$48, $0F, $BA, $E8, $3F]); { bts rax, 63 }
    EmitJump(DoneLabel);
    BindTextLabel(SmallLabel);
    EmitSignedConversion;
    BindTextLabel(DoneLabel);
  end
  else
    EmitSignedConversion;
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

{ Label of the object or function whose address a constant initializer denotes,
  or -1 when the initializer is not an address constant. }
function TX64Backend.ConstantAddressLabel(AExpression: TExpr): LongInt;
var
  CastValue: Int64;
begin
  Result := -1;
  if AExpression = nil then Exit;
  case AExpression.Kind of
    ekCast:
      begin
        { A null pointer constant such as `(void *)0` is an integer constant
          wearing a cast, not an address. }
        if EvaluateIntegerConstantExpression(AExpression.Left, CastValue) then
          Exit(-1);
        Exit(ConstantAddressLabel(AExpression.Left));
      end;
    ekAddress: Exit(ConstantAddressLabel(AExpression.Left));
    ekString: Exit(AddStringLiteral(AExpression.Text));
    ekVariable:
      begin
        if AExpression.IsFunctionDesignator then
          Exit(FindFunctionLabel(AExpression.Text));
        if IsArrayType(AExpression.CType) or
           IsAggregateType(AExpression.CType) then
          Exit(FindNamedLabel(FGlobals, AExpression.Text));
      end;
  end;
end;

{ Folds the constant floating expressions permitted in a static initializer:
  literals, casts, unary sign and the basic arithmetic operators. }
function TryEvaluateConstantFloat(E: TExpr; out AValue: Double): Boolean;
var
  Left, Right: Double;
  IntegerValue: Int64;
begin
  Result := False;
  AValue := 0.0;
  if E = nil then Exit;
  case E.Kind of
    ekFloat:
      begin
        AValue := E.FloatValue;
        Exit(True);
      end;
    ekInteger:
      begin
        AValue := E.IntValue;
        Exit(True);
      end;
    ekCast:
      begin
        if not TryEvaluateConstantFloat(E.Left, AValue) then Exit;
        if IsIntegerType(E.CType) and not IsPointerType(E.CType) then
          AValue := Trunc(AValue)
        else if E.CType.Kind = ctFloat then
          AValue := Single(AValue);
        Exit(True);
      end;
    ekUnary:
      begin
        if not TryEvaluateConstantFloat(E.Left, Left) then Exit;
        case E.UnaryOp of
          uoPositive: AValue := Left;
          uoNegative: AValue := -Left;
        else
          Exit;
        end;
        Exit(True);
      end;
    ekBinary:
      begin
        if not TryEvaluateConstantFloat(E.Left, Left) then Exit;
        if not TryEvaluateConstantFloat(E.Right, Right) then Exit;
        case E.BinaryOp of
          boAdd: AValue := Left + Right;
          boSub: AValue := Left - Right;
          boMul: AValue := Left * Right;
          boDiv:
            begin
              if Right = 0 then Exit;
              AValue := Left / Right;
            end;
        else
          Exit;
        end;
        Exit(True);
      end;
  end;
  if EvaluateIntegerConstantExpression(E, IntegerValue) then
  begin
    AValue := IntegerValue;
    Result := True;
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
  if IsArrayType(AType) then
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
      if not TryEvaluateConstantFloat(AInitializer, FloatValue) then
        RaiseCompileError(APos,
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
    if IsPointerType(AType) then
    begin
      { A static pointer may name a function or another object; both resolve
        to an address that is only known once the image is laid out. }
      I := ConstantAddressLabel(AInitializer);
      if I >= 0 then
      begin
        AddDataAddressFixup(I, FData.Size);
        FData.Add64(0);
        Exit;
      end;
    end;
    if not EvaluateIntegerConstantExpression(AInitializer, Value) then
    begin
      { Accept a null pointer constant written with a cast. }
      if not ((AInitializer.Kind = ekCast) and
              EvaluateIntegerConstantExpression(AInitializer.Left, Value)) then
        RaiseCompileError(AInitializer.Pos,
          'global initializer is not an integer constant expression');
    end;
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

{ Static locals have program lifetime, so they are laid out like globals and
  initialized once at load time rather than on entry to the enclosing block. }
procedure TX64Backend.ReserveStaticLocals(S: TStmt);
var
  I, L, N: LongInt;
begin
  if S = nil then Exit;
  if (S.Kind = skDecl) and S.IsStatic then
  begin
    { String literals in the initializer become objects of their own, so they
      have to be interned before this object's bytes are laid out. }
    PreallocateInitializerLiterals(S.Expr);
    L := NewLabel;
    if S.Expr = nil then
    begin
      BindBssLabel(L);
      FLabels[L].Offset := ReserveBss(StorageSize(S.CType),
        StorageAlign(S.CType));
    end
    else
    begin
      FData.PadTo(StorageAlign(S.CType));
      BindDataLabel(L);
      EmitGlobalObject(S.CType, S.Expr, S.Pos);
    end;
    N := Length(FStaticLocals);
    SetLength(FStaticLocals, N + 1);
    FStaticLocals[N].Name := S.Name;
    FStaticLocals[N].LabelID := L;
  end;
  ReserveStaticLocals(S.InitStmt);
  ReserveStaticLocals(S.Body);
  ReserveStaticLocals(S.ElseBody);
  for I := 0 to High(S.Children) do ReserveStaticLocals(S.Children[I]);
end;

function TX64Backend.FindStaticLocalLabel(const AName: string): LongInt;
begin
  Result := FindNamedLabel(FStaticLocals, AName);
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
    if FGlobalLabelIndex.GetOrDefault(G.Name, -1) >= 0 then
      RaiseCompileError(G.Pos, 'duplicate global ''' + G.Name + '''');
    L := NewLabel;
    if G.Initializer = nil then
    begin
      { No initializer means an all-zero object: reserve address space for it
        instead of writing the zeros into the output file. }
      BindBssLabel(L);
      FLabels[L].Offset := ReserveBss(StorageSize(G.CType),
        StorageAlign(G.CType));
    end
    else
    begin
      FData.PadTo(StorageAlign(G.CType));
      BindDataLabel(L);
      EmitGlobalObject(G.CType, G.Initializer, G.Pos);
    end;
    N := Length(FGlobals);
    SetLength(FGlobals, N + 1);
    FGlobals[N].Name := G.Name;
    FGlobals[N].LabelID := L;
    FGlobalLabelIndex.Put(G.Name, L);
  end;
end;

procedure TX64Backend.ReserveFunctionLabels;
var
  I, N, L: LongInt;
  F: TFunction;
begin
  for I := 0 to High(FProgram.Functions) do
  begin
    F := FProgram.Functions[I];
    if F.IsPrototype then Continue;
    if FFunctionIndex.GetOrDefault(F.Name, -1) >= 0 then
      RaiseCompileError(F.Pos, 'duplicate function definition ''' + F.Name + '''');
    L := NewLabel;
    N := Length(FFunctions);
    SetLength(FFunctions, N + 1);
    FFunctions[N].Name := F.Name;
    FFunctions[N].LabelID := L;
    FFunctionIndex.Put(F.Name, L);
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
  MainLabel := FindFunctionLabel('main');
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
    EmitDirectSyscall('exit');
    FListing.Add('  mov eax, target_exit_syscall');
    FListing.Add('  syscall');
  end;
  FText.AddBytes([$0F, $0B]);
  FListing.Add('');
end;

procedure TX64Backend.EmitRuntimeRead;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'read'); BindTextLabel(L);
  EmitDirectSyscall('read');
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeWrite;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'write'); BindTextLabel(L);
  EmitDirectSyscall('write');
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeClose;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'close'); BindTextLabel(L);
  EmitDirectSyscall('close');
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeOpen;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'open'); BindTextLabel(L);
  EmitDirectSyscall('open');
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeLseek;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'lseek'); BindTextLabel(L);
  EmitDirectSyscall('lseek');
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeGetPid;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'getpid'); BindTextLabel(L);
  EmitDirectSyscall('getpid');
  FText.Add8($C3);
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
  EmitDirectSyscall('access');
  FText.Add8($C3);
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeTime;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'time'); BindTextLabel(L);
  EmitDirectSyscall('time');
  FText.Add8($C3);
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
  begin
    EmitDirectSyscall('exit');
    FText.AddBytes([$0F, $0B]);
  end;
  Inc(FStats.RuntimeFunctions);
end;

procedure TX64Backend.EmitRuntimeAbort;
var L: LongInt;
begin
  L := FindNamedLabel(FRuntime, 'abort'); BindTextLabel(L);
  FText.AddBytes([$BF, $86, $00, $00, $00]);
  EmitDirectSyscall('exit');
  FText.AddBytes([$0F, $0B]);
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
  EmitDirectSyscall('write');
  EmitLeaRsiData(NewlineLabel);
  FText.AddBytes([$BA, $01, $00, $00, $00]);
  FText.AddBytes([$BF, $01, $00, $00, $00]);
  EmitDirectSyscall('write');
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
  EmitDirectSyscall('write');
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
  EmitDirectSyscall('read');
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
  EmitDirectSyscall('write');
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
  EmitDirectSyscall('write');
  FText.Add8($C3);
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
  EmitDirectSyscall('write');
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
  EmitDirectSyscall('mmap');
  FText.Add8($59);
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
  EmitDirectSyscall('munmap');
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
  EmitDirectSyscall('exit');
  FText.AddBytes([$0F, $0B]);
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
  if E.Kind = ekCompoundLit then
  begin
    Size := StorageSize(E.CType);
    if IsAggregateType(E.CType) then
      Size := LongInt(AlignUp(QWord(Size), 8))
    else if Size < 8 then
      Size := 8;
    Alignment := StorageAlign(E.CType);
    Inc(Result, Size + Alignment - 1);
    Exit;
  end;
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
  if (S.Kind = skDecl) and not S.IsStatic and
     not FindRegisterPlan(S.Name, I) then
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
      RaiseCompileError(FCurrentDeclPos,
        'duplicate local variable ''' + AName + '''');
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

procedure TX64Backend.PlanRegisterLocals(F: TFunction);
var
  Candidates: TRegisterCandidateArray;
  I, J, BestIndex, BestScore, N, MaxPlans, MinimumScore: LongInt;
  ParameterConflict: Boolean;
begin
  SetLength(FRegisterPlans, 0);
  FRegisterSaveCount := 0;
  FUsingCalleeSavedLocals := False;
  if (F = nil) or (FOptions.OptimizationLevel < 1) or
     FOptions.DebugInfo or F.IsVariadic then Exit;
  if FOptions.SizeOptimizationLevel > 0 then
  begin
    MaxPlans := 2;
    MinimumScore := 10;
  end
  else if FOptions.OptimizationLevel = 1 then
  begin
    MaxPlans := 3;
    MinimumScore := 5;
  end
  else
  begin
    MaxPlans := 4;
    MinimumScore := 3;
  end;

  SetLength(Candidates, 0);
  CollectRegisterCandidates(F.Body, Candidates);
  ScoreRegisterStmt(F.Body, 0, Candidates);
  for I := 0 to High(Candidates) do
  begin
    ParameterConflict := False;
    for J := 0 to High(F.Params) do
      if F.Params[J].Name = Candidates[I].Name then
      begin
        ParameterConflict := True;
        Break;
      end;
    if ParameterConflict then Candidates[I].Unsafe := True;
  end;

  { r12-r15 are callee-saved under the SysV ABI and are otherwise unused by
    the compact expression emitter.  A weighted use count favors induction
    variables and loop-carried state without requiring a full SSA allocator. }
  for J := 0 to MaxPlans - 1 do
  begin
    BestIndex := -1;
    BestScore := MinimumScore - 1;
    for I := 0 to High(Candidates) do
      if not Candidates[I].Selected and not Candidates[I].Unsafe and
         not Candidates[I].AddressTaken and
         (Candidates[I].DeclarationCount = 1) and
         (Candidates[I].Score > BestScore) and
         (((FOptions.SizeOptimizationLevel > 0) and
           (Candidates[I].LoopScore > 0) and
           (Candidates[I].Score >= MinimumScore)) or
          ((FOptions.SizeOptimizationLevel = 0) and
           ((Candidates[I].Score >= MinimumScore) or
            ((FOptions.OptimizationLevel >= 2) and
             (Candidates[I].LoopScore > 0) and
             (Candidates[I].Score > 1))))) then
      begin
        BestIndex := I;
        BestScore := Candidates[I].Score;
      end;
    if BestIndex < 0 then Break;
    Candidates[BestIndex].Selected := True;
    N := Length(FRegisterPlans);
    SetLength(FRegisterPlans, N + 1);
    FRegisterPlans[N].Name := Candidates[BestIndex].Name;
    FRegisterPlans[N].CType := Candidates[BestIndex].CType;
    FRegisterPlans[N].RegisterOrdinal := 2 + N;
  end;
  if Length(FRegisterPlans) > 0 then
  begin
    if Length(FRegisterPlans) <= 2 then FRegisterSaveCount := 2
    else FRegisterSaveCount := 4;
  end;
  FUsingCalleeSavedLocals := FRegisterSaveCount > 0;
end;

function TX64Backend.FindRegisterPlan(const AName: string;
  out ARegisterOrdinal: LongInt): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(FRegisterPlans) do
    if FRegisterPlans[I].Name = AName then
    begin
      ARegisterOrdinal := FRegisterPlans[I].RegisterOrdinal;
      Exit(True);
    end;
  ARegisterOrdinal := -1;
  Result := False;
end;

procedure TX64Backend.AddRegisterLocal(const AName: string;
  const AType: TCType; ARegisterOrdinal: LongInt);
var
  I, N: LongInt;
begin
  for I := High(FRegisterLocals) downto 0 do
    if (FRegisterLocals[I].Name = AName) and
       (FRegisterLocals[I].ScopeDepth = FScopeDepth) then
      RaiseCompileError(FCurrentDeclPos,
        'duplicate local variable ''' + AName + '''');
  N := Length(FRegisterLocals);
  SetLength(FRegisterLocals, N + 1);
  FRegisterLocals[N].Name := AName;
  FRegisterLocals[N].CType := AType;
  FRegisterLocals[N].RegisterOrdinal := ARegisterOrdinal;
  FRegisterLocals[N].ScopeDepth := FScopeDepth;
end;

function TX64Backend.FindRegisterLocal(const AName: string;
  out ARegisterOrdinal: LongInt; out AType: TCType): Boolean;
var
  I: LongInt;
begin
  for I := High(FRegisterLocals) downto 0 do
    if FRegisterLocals[I].Name = AName then
    begin
      ARegisterOrdinal := FRegisterLocals[I].RegisterOrdinal;
      AType := FRegisterLocals[I].CType;
      Exit(True);
    end;
  ARegisterOrdinal := -1;
  AType := MakeType(ctInt);
  Result := False;
end;

procedure TX64Backend.EmitLoadRegisterLocalToRax(ARegisterOrdinal: LongInt;
  const AType: TCType);
begin
  if FRaxRegisterLocalValid and
     (FRaxRegisterLocalOffset = FText.Size) and
     (FRaxRegisterLocalOffset >= FBlockStart) and
     (FRaxRegisterLocalOrdinal = ARegisterOrdinal) then
  begin
    NoteRaxNormalized(AType);
    Exit;
  end;
  case ARegisterOrdinal of
    0: FText.AddBytes([$48, $89, $F8]); { mov rax,rdi }
    1: FText.AddBytes([$48, $89, $F0]); { mov rax,rsi }
    2: FText.AddBytes([$4C, $89, $E0]); { mov rax,r12 }
    3: FText.AddBytes([$4C, $89, $E8]); { mov rax,r13 }
    4: FText.AddBytes([$4C, $89, $F0]); { mov rax,r14 }
    5: FText.AddBytes([$4C, $89, $F8]); { mov rax,r15 }
  else
    raise ERCCError.Create('internal error: unsupported resident register');
  end;
  EmitNormalizeInteger(AType);
end;

procedure TX64Backend.EmitLoadRegisterLocalToRcx(ARegisterOrdinal: LongInt;
  const AType: TCType);
begin
  case ARegisterOrdinal of
    0: FText.AddBytes([$48, $89, $F9]); { mov rcx,rdi }
    1: FText.AddBytes([$48, $89, $F1]); { mov rcx,rsi }
    2: FText.AddBytes([$4C, $89, $E1]); { mov rcx,r12 }
    3: FText.AddBytes([$4C, $89, $E9]); { mov rcx,r13 }
    4: FText.AddBytes([$4C, $89, $F1]); { mov rcx,r14 }
    5: FText.AddBytes([$4C, $89, $F9]); { mov rcx,r15 }
  else
    raise ERCCError.Create('internal error: unsupported resident register');
  end;
  { Register locals are normalized when written. }
  InvalidateRaxState;
end;

procedure TX64Backend.EmitStoreRaxToRegisterLocal(ARegisterOrdinal: LongInt;
  const AType: TCType);
begin
  EmitNormalizeInteger(AType);
  case ARegisterOrdinal of
    0: FText.AddBytes([$48, $89, $C7]); { mov rdi,rax }
    1: FText.AddBytes([$48, $89, $C6]); { mov rsi,rax }
    2: FText.AddBytes([$49, $89, $C4]); { mov r12,rax }
    3: FText.AddBytes([$49, $89, $C5]); { mov r13,rax }
    4: FText.AddBytes([$49, $89, $C6]); { mov r14,rax }
    5: FText.AddBytes([$49, $89, $C7]); { mov r15,rax }
  else
    raise ERCCError.Create('internal error: unsupported resident register');
  end;
  { The assignment expression still yields the normalized value in rax. }
  FRaxRegisterLocalValid := True;
  FRaxRegisterLocalOffset := FText.Size;
  FRaxRegisterLocalOrdinal := ARegisterOrdinal;
  NoteRaxNormalized(AType);
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
  Result := FGlobalLabelIndex.GetOrDefault(AName, -1);
  if Result < 0 then
    Result := FindExternalDefinition(AName, ELF_STT_OBJECT);
end;

function TX64Backend.FindGlobal(const AName: string): TGlobal;
begin
  Result := FProgram.FindGlobal(AName);
end;

procedure TX64Backend.EnterScope;
begin
  Inc(FScopeDepth);
end;

procedure TX64Backend.LeaveScope(ASavedCount: LongInt);
begin
  SetLength(FLocals, ASavedCount);
  while (Length(FRegisterLocals) > 0) and
        (FRegisterLocals[High(FRegisterLocals)].ScopeDepth >= FScopeDepth) do
    SetLength(FRegisterLocals, Length(FRegisterLocals) - 1);
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
  I, L, SavedCount: LongInt;
begin
  if S = nil then Exit;
  case S.Kind of
    skBlock:
      if S.IsDeclarationGroup then
        for I := 0 to High(S.Children) do
          GenSwitchBody(S.Children[I], AEntries)
      else
      begin
        { The switch body and any braced case body are still blocks, so they
          scope their declarations even though case labels are walked here
          rather than through GenStmt. }
        SavedCount := Length(FLocals);
        EnterScope;
        for I := 0 to High(S.Children) do
          GenSwitchBody(S.Children[I], AEntries);
        LeaveScope(SavedCount);
      end;
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
     not (IsArrayType(AType) and (AInitializer.Kind = ekString)) then
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
  Offset, L, Scale: LongInt;
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
          if FindRegisterLocal(E.Text, L, LocalType) then
            RaiseCompileError(E.Pos,
              'internal error: addressable parameter was kept in a register');
          L := FindStaticLocalLabel(E.Text);
          if L < 0 then L := FindGlobalLabel(E.Text);
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
        Scale := LongInt(E.IntValue);
        if Scale < 1 then Scale := 1;
        if (FOptions.OptimizationLevel >= 1) and (E.Right <> nil) and
           (E.Right.Kind = ekInteger) and
           (Abs(E.Right.IntValue) < High(LongInt) div Scale) then
        begin
          { A constant subscript folds into the base address. }
          GenExpr(E.Left);
          EmitAddRaxImmediate(LongInt(E.Right.IntValue) * Scale);
        end
        else
        begin
          if (FOptions.OptimizationLevel >= 1) and
             (E.Left <> nil) and (E.Left.Kind = ekVariable) then
          begin
            { A plain base variable cannot clobber rcx. Evaluate the dynamic
              subscript first and retain it there, avoiding the push/pop pair
              otherwise needed to preserve the base address. C leaves the
              evaluation order of the two subscript operands unspecified. }
            GenExpr(E.Right);
            EmitNormalizeInteger(E.Right.CType);
            FText.AddBytes([$48, $89, $C1]);
            GenExpr(E.Left);
            EmitAddScaledRcxToRax(Scale);
          end
          else
          begin
            GenExpr(E.Left);
            if TryLoadOperandToRcx(E.Right, E.Right.CType) then
              EmitAddScaledRcxToRax(Scale)
            else
            begin
              EmitPushRax;
              GenExpr(E.Right);
              EmitScaleRax(Scale);
              FText.AddBytes([$48, $89, $C1]);
              FText.Add8($58);
              Dec(FStackDepth, 8);
              FText.AddBytes([$48, $01, $C8]);
            end;
          end;
        end;
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
    ekCompoundLit:
      begin
        ReserveTemporary(StorageSize(E.CType), StorageAlign(E.CType), Offset);
        if IsAggregateType(E.CType) then
          InitializeLocal(Offset, E.CType, E, E.Pos)
        else
        begin
          if Length(E.Args) <> 1 then
            RaiseCompileError(E.Pos,
              'scalar compound literal requires exactly one initializer');
          InitializeLocal(Offset, E.CType, E.Args[0], E.Pos);
        end;
        EmitAddressLocal(Offset);
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
    EmitConvertIntegerToFloat(E.CType, ATargetType);
end;


procedure TX64Backend.GenCondition(E: TExpr);
begin
  GenExpr(E);
  if IsFloatingType(E.CType) then EmitFloatToBool(E.CType)
  else EmitNormalizeBool;
end;

{ Emits an integer comparison and reports the Jcc opcode that tests it, so a
  branch can consume the flags directly instead of materializing a 0/1 value
  and testing that. }
function TX64Backend.TryEmitComparisonFlags(E: TExpr;
  out AJccOpcode: Byte): Boolean;
var
  LocalType, RegisterType, ExistingType: TCType;
  RegisterOrdinal, LocalOffset: LongInt;
  IndirectLocal: Boolean;
  Unsigned: Boolean;
  Value: Int64;
begin
  Result := False;
  AJccOpcode := 0;
  if (E = nil) or (E.Kind <> ekBinary) then Exit;
  if not (E.BinaryOp in [boEqual, boNotEqual, boLess, boLessEqual,
    boGreater, boGreaterEqual]) then Exit;
  if (E.Left = nil) or (E.Right = nil) then Exit;
  if IsFloatingType(E.Left.CType) or IsFloatingType(E.Right.CType) then Exit;

  LocalType := E.OperationType;
  if IsFloatingType(LocalType) then Exit;
  case E.BinaryOp of
    boEqual, boNotEqual: Unsigned := False;
  else
    Unsigned := IsPointerType(LocalType) or LocalType.IsUnsigned;
  end;
  case E.BinaryOp of
    boEqual: AJccOpcode := $84;
    boNotEqual: AJccOpcode := $85;
    boLess: if Unsigned then AJccOpcode := $82 else AJccOpcode := $8C;
    boLessEqual: if Unsigned then AJccOpcode := $86 else AJccOpcode := $8E;
    boGreater: if Unsigned then AJccOpcode := $87 else AJccOpcode := $8F;
    boGreaterEqual: if Unsigned then AJccOpcode := $83 else AJccOpcode := $8D;
  end;

  if (FOptions.OptimizationLevel >= 1) and (E.Right.Kind = ekInteger) then
  begin
    if IsIntegerType(LocalType) then
      Value := ConvertIntegerValue(E.Right.IntValue, LocalType)
    else
      Value := E.Right.IntValue;
    if (E.Left.Kind = ekVariable) and
       (StorageSize(LocalType) = 8) and
       (Value >= Low(LongInt)) and (Value <= High(LongInt)) and
       not FindLocal(E.Left.Text, LocalOffset, ExistingType, IndirectLocal) and
       FindRegisterLocal(E.Left.Text, RegisterOrdinal, RegisterType) and
       (StorageSize(RegisterType) = 8) then
    begin
      if (Value >= -128) and (Value <= 127) then
      begin
        case RegisterOrdinal of
          0: FText.AddBytes([$48, $83, $FF]);
          1: FText.AddBytes([$48, $83, $FE]);
          2: FText.AddBytes([$49, $83, $FC]);
          3: FText.AddBytes([$49, $83, $FD]);
          4: FText.AddBytes([$49, $83, $FE]);
          5: FText.AddBytes([$49, $83, $FF]);
        else
          Exit(False);
        end;
        FText.Add8(Byte(LongWord(Value) and $FF));
      end
      else
      begin
        case RegisterOrdinal of
          0: FText.AddBytes([$48, $81, $FF]);
          1: FText.AddBytes([$48, $81, $FE]);
          2: FText.AddBytes([$49, $81, $FC]);
          3: FText.AddBytes([$49, $81, $FD]);
          4: FText.AddBytes([$49, $81, $FE]);
          5: FText.AddBytes([$49, $81, $FF]);
        else
          Exit(False);
        end;
        FText.AddI32(LongInt(Value));
      end;
      InvalidateRaxState;
      Exit(True);
    end;
    if (Value >= Low(LongInt)) and (Value <= High(LongInt)) then
    begin
      GenExpr(E.Left);
      if IsIntegerType(LocalType) then EmitNormalizeInteger(LocalType);
      if Value = 0 then
        FText.AddBytes([$48, $85, $C0])
      else if (Value >= -128) and (Value <= 127) then
        FText.AddBytes([$48, $83, $F8, Byte(LongWord(Value) and $FF)])
      else
      begin
        FText.AddBytes([$48, $3D]);
        FText.AddI32(LongInt(Value));
      end;
      Exit(True);
    end;
  end;

  GenExpr(E.Left);
  if IsIntegerType(LocalType) then EmitNormalizeInteger(LocalType);
  if not TryLoadOperandToRcx(E.Right, LocalType) then
  begin
    EmitPushRax;
    GenExpr(E.Right);
    if IsIntegerType(LocalType) then EmitNormalizeInteger(LocalType);
    FText.AddBytes([$48, $89, $C1]);
    FText.Add8($58);
    Dec(FStackDepth, 8);
  end;
  FText.AddBytes([$48, $39, $C8]);
  Result := True;
end;

procedure TX64Backend.GenBranch(E: TExpr; ATargetLabel: LongInt;
  ABranchIfTrue: Boolean);
var
  JccOpcode: Byte;
  SkipLabel: LongInt;
  Value: Int64;
begin
  if E = nil then Exit;

  if (E.Kind = ekUnary) and (E.UnaryOp = uoLogicalNot) and
     not IsFloatingType(E.Left.CType) then
  begin
    GenBranch(E.Left, ATargetLabel, not ABranchIfTrue);
    Exit;
  end;

  if (E.Kind = ekInteger) and (FOptions.OptimizationLevel >= 1) then
  begin
    Value := E.IntValue;
    if (Value <> 0) = ABranchIfTrue then EmitJump(ATargetLabel);
    Exit;
  end;

  if (E.Kind = ekBinary) and (E.BinaryOp = boLogicalAnd) then
  begin
    if ABranchIfTrue then
    begin
      SkipLabel := NewLabel;
      GenBranch(E.Left, SkipLabel, False);
      GenBranch(E.Right, ATargetLabel, True);
      BindTextLabel(SkipLabel);
    end
    else
    begin
      GenBranch(E.Left, ATargetLabel, False);
      GenBranch(E.Right, ATargetLabel, False);
    end;
    Exit;
  end;

  if (E.Kind = ekBinary) and (E.BinaryOp = boLogicalOr) then
  begin
    if ABranchIfTrue then
    begin
      GenBranch(E.Left, ATargetLabel, True);
      GenBranch(E.Right, ATargetLabel, True);
    end
    else
    begin
      SkipLabel := NewLabel;
      GenBranch(E.Left, SkipLabel, True);
      GenBranch(E.Right, ATargetLabel, False);
      BindTextLabel(SkipLabel);
    end;
    Exit;
  end;

  if TryEmitComparisonFlags(E, JccOpcode) then
  begin
    if not ABranchIfTrue then JccOpcode := JccOpcode xor 1;
    EmitJcc(JccOpcode, ATargetLabel);
    Exit;
  end;

  GenExpr(E);
  if IsFloatingType(E.CType) then
  begin
    EmitFloatToBool(E.CType);
    FText.AddBytes([$48, $85, $C0]);
  end
  else
    FText.AddBytes([$48, $85, $C0]);
  if ABranchIfTrue then EmitJcc($85, ATargetLabel)
  else EmitJcc($84, ATargetLabel);
end;

procedure TX64Backend.GenAssignment(E: TExpr);
var
  Op: TBinaryOp;
  L, Pad, Scale, TargetOffset, TargetLabel, RegisterOrdinal,
    LocalOffset: LongInt;
  ImmediateValue, ShiftValue: Int64;
  Indirect, Direct, IndirectLocal, Handled: Boolean;
  LocalType, RegisterType: TCType;

  function CompoundBinaryOp: TBinaryOp;
  begin
    case E.AssignOp of
      aoAdd: Result := boAdd;
      aoSub: Result := boSub;
      aoMul: Result := boMul;
      aoDiv: Result := boDiv;
      aoMod: Result := boMod;
      aoBitAnd: Result := boBitAnd;
      aoBitOr: Result := boBitOr;
      aoBitXor: Result := boBitXor;
      aoShiftLeft: Result := boShiftLeft;
      aoShiftRight: Result := boShiftRight;
    else
      Result := boAdd;
    end;
  end;
begin
  if (E.Left.Kind = ekVariable) and
     not FindLocal(E.Left.Text, LocalOffset, LocalType, IndirectLocal) and
     FindRegisterLocal(E.Left.Text, RegisterOrdinal, RegisterType) then
  begin
    if E.AssignOp = aoAssign then
      GenExpr(E.Right)
    else
    begin
      Op := CompoundBinaryOp;
      { Fold x op= (x shift constant) without staging either operand.  This is
        the common xorshift/bit-mixing form and remains valid for all promoted
        non-volatile integer locals because the left object is evaluated once. }
      if IsIntegerType(E.Left.CType) and
         (E.AssignOp in [aoAdd, aoSub, aoBitAnd, aoBitOr, aoBitXor]) and
         (E.Right <> nil) and (E.Right.Kind = ekBinary) and
         (E.Right.BinaryOp in [boShiftLeft, boShiftRight]) and
         (E.Right.Left <> nil) and (E.Right.Left.Kind = ekVariable) and
         (E.Right.Left.Text = E.Left.Text) and
         (E.Right.Right <> nil) and (E.Right.Right.Kind = ekInteger) then
      begin
        EmitLoadRegisterLocalToRax(RegisterOrdinal, RegisterType);
        FText.AddBytes([$48, $89, $C1]); { mov rcx,rax }
        ShiftValue := E.Right.Right.IntValue and 63;
        if ShiftValue <> 0 then
          if E.Right.BinaryOp = boShiftLeft then
            FText.AddBytes([$48, $C1, $E1, Byte(ShiftValue)])
          else if E.Right.OperationType.IsUnsigned then
            FText.AddBytes([$48, $C1, $E9, Byte(ShiftValue)])
          else
            FText.AddBytes([$48, $C1, $F9, Byte(ShiftValue)]);
        EmitBinaryOperation(Op, E.Left.CType.IsUnsigned);
        EmitStoreRaxToRegisterLocal(RegisterOrdinal, E.Left.CType);
        Exit;
      end;

      EmitLoadRegisterLocalToRax(RegisterOrdinal, RegisterType);
      Scale := 1;
      if IsPointerType(DecayType(E.Left.CType)) and
         (E.AssignOp in [aoAdd, aoSub]) then
      begin
        { Pointer increments still require pointee scaling before combination. }
        EmitPushRax;
        GenExpr(E.Right);
        Scale := StorageSize(PointeeType(DecayType(E.Left.CType)));
        EmitScaleRax(Scale);
        FText.AddBytes([$48, $89, $C1]);
        FText.Add8($58);
        Dec(FStackDepth, 8);
        EmitBinaryOperation(Op, E.Left.CType.IsUnsigned);
      end
      else
      begin
        Handled := False;
        if (E.Right <> nil) and (E.Right.Kind = ekInteger) and
           IsIntegerType(E.Left.CType) then
        begin
          if Op in [boShiftLeft, boShiftRight] then
            ImmediateValue := E.Right.IntValue
          else
            ImmediateValue := ConvertIntegerValue(E.Right.IntValue,
              E.Left.CType);
          EmitImmediateOperation(Op, ImmediateValue,
            E.Left.CType.IsUnsigned, Handled);
        end;
        if not Handled then
        begin
          if not TryLoadOperandToRcx(E.Right, E.Left.CType) then
          begin
            EmitPushRax;
            GenExpr(E.Right);
            FText.AddBytes([$48, $89, $C1]);
            FText.Add8($58);
            Dec(FStackDepth, 8);
          end;
          EmitBinaryOperation(Op, E.Left.CType.IsUnsigned);
        end;
      end;
    end;
    EmitStoreRaxToRegisterLocal(RegisterOrdinal, E.Left.CType);
    Exit;
  end;

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

  Direct := TryResolveDirectTarget(E.Left, TargetOffset, TargetLabel);

  if Direct and (E.AssignOp = aoAssign) then
  begin
    GenExpr(E.Right);
    EmitNormalizeInteger(E.Left.CType);
    EmitStoreDirectTarget(TargetOffset, TargetLabel, E.Left.CType);
    Exit;
  end;

  if not Direct then
  begin
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
  end
  else
    EmitLoadDirectTarget(TargetOffset, TargetLabel, E.Left.CType);
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
  if Direct then
    EmitStoreDirectTarget(TargetOffset, TargetLabel, E.Left.CType)
  else
  begin
    EmitPopRcx;
    EmitStoreRaxAtRcx(E.Left.CType);
  end;
end;

procedure TX64Backend.GenIncDec(E: TExpr; ADelta: LongInt; APost: Boolean;
  ADiscardResult: Boolean);
var
  Delta, TargetOffset, TargetLabel, RegisterOrdinal, LocalOffset: LongInt;
  OneType, LocalType, RegisterType: TCType;
  IndirectLocal: Boolean;
begin
  if (E.Left.Kind = ekVariable) and
     not FindLocal(E.Left.Text, LocalOffset, LocalType, IndirectLocal) and
     FindRegisterLocal(E.Left.Text, RegisterOrdinal, RegisterType) then
  begin
    Delta := ADelta;
    if E.IntValue > 1 then Delta := Delta * LongInt(E.IntValue);
    if (FOptions.OptimizationLevel >= 1) and
       (StorageSize(RegisterType) = 8) then
    begin
      if APost and not ADiscardResult then
        EmitLoadRegisterLocalToRax(RegisterOrdinal, RegisterType);
      if (Delta >= -128) and (Delta <= 127) then
      begin
        case RegisterOrdinal of
          0: FText.AddBytes([$48, $83, $C7]);
          1: FText.AddBytes([$48, $83, $C6]);
          2: FText.AddBytes([$49, $83, $C4]);
          3: FText.AddBytes([$49, $83, $C5]);
          4: FText.AddBytes([$49, $83, $C6]);
          5: FText.AddBytes([$49, $83, $C7]);
        else
          raise ERCCError.Create('internal error: unsupported resident register');
        end;
        FText.Add8(Byte(LongWord(Delta) and $FF));
      end
      else
      begin
        case RegisterOrdinal of
          0: FText.AddBytes([$48, $81, $C7]);
          1: FText.AddBytes([$48, $81, $C6]);
          2: FText.AddBytes([$49, $81, $C4]);
          3: FText.AddBytes([$49, $81, $C5]);
          4: FText.AddBytes([$49, $81, $C6]);
          5: FText.AddBytes([$49, $81, $C7]);
        else
          raise ERCCError.Create('internal error: unsupported resident register');
        end;
        FText.AddI32(Delta);
      end;
      InvalidateRaxState;
      if not ADiscardResult and not APost then
        EmitLoadRegisterLocalToRax(RegisterOrdinal, RegisterType);
      Exit;
    end;
    EmitLoadRegisterLocalToRax(RegisterOrdinal, RegisterType);
    if APost then FText.AddBytes([$48, $89, $C2]); { mov rdx,rax }
    EmitAddRaxImmediate(Delta);
    EmitStoreRaxToRegisterLocal(RegisterOrdinal, E.Left.CType);
    if APost then FText.AddBytes([$48, $89, $D0]); { mov rax,rdx }
    Exit;
  end;

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
    EmitConvertIntegerToFloat(E.Left.CType, OneType);
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

  Delta := ADelta;
  if E.IntValue > 1 then Delta := Delta * LongInt(E.IntValue);

  if TryResolveDirectTarget(E.Left, TargetOffset, TargetLabel) then
  begin
    EmitLoadDirectTarget(TargetOffset, TargetLabel, E.Left.CType);
    if APost then FText.AddBytes([$48, $89, $C2]);
    EmitAddRaxImmediate(Delta);
    EmitNormalizeInteger(E.Left.CType);
    EmitStoreDirectTarget(TargetOffset, TargetLabel, E.Left.CType);
    if APost then FText.AddBytes([$48, $89, $D0]);
    Exit;
  end;

  GenAddress(E.Left);
  FText.AddBytes([$48, $89, $C1]);
  EmitLoadAtRax(E.Left.CType);
  if APost then FText.AddBytes([$48, $89, $C2]);
  EmitAddRaxImmediate(Delta);
  EmitNormalizeInteger(E.Left.CType);
  EmitStoreRaxAtRcx(E.Left.CType);
  if APost then FText.AddBytes([$48, $89, $D0]);
end;

{ True when a printf format uses only the conversions the direct-write path can
  render itself. }
function PlainPrintfFormat(const AText: string): Boolean;
var
  I: LongInt;
begin
  Result := False;
  I := 1;
  while I <= Length(AText) do
  begin
    if AText[I] <> '%' then begin Inc(I); Continue; end;
    Inc(I);
    if I > Length(AText) then Exit;
    if AText[I] = '%' then begin Inc(I); Continue; end;
    if AText[I] in ['-', '+', ' ', '#', '0', '.', '1'..'9', '*'] then Exit;
    if AText[I] in ['h', 'l', 'j', 'z', 't', 'L'] then Exit;
    if not (AText[I] in ['d', 'i', 's', 'c']) then Exit;
    Inc(I);
  end;
  Result := True;
end;

function PlainPrintfCallsOnly(E: TExpr): Boolean; forward;

function PlainPrintfCallsOnlyStmt(S: TStmt): Boolean;
var
  I: LongInt;
begin
  Result := True;
  if S = nil then Exit;
  if not PlainPrintfCallsOnly(S.Expr) then Exit(False);
  if not PlainPrintfCallsOnly(S.Expr2) then Exit(False);
  if not PlainPrintfCallsOnlyStmt(S.InitStmt) then Exit(False);
  if not PlainPrintfCallsOnlyStmt(S.Body) then Exit(False);
  if not PlainPrintfCallsOnlyStmt(S.ElseBody) then Exit(False);
  for I := 0 to High(S.Children) do
    if not PlainPrintfCallsOnlyStmt(S.Children[I]) then Exit(False);
end;

function PlainPrintfCallsOnly(E: TExpr): Boolean;
var
  I: LongInt;
begin
  Result := True;
  if E = nil then Exit;
  if (E.Kind = ekCall) and (E.Text = 'printf') then
  begin
    if (Length(E.Args) = 0) or (E.Args[0] = nil) or
       (E.Args[0].Kind <> ekString) then Exit(False);
    if not PlainPrintfFormat(E.Args[0].Text) then Exit(False);
  end;
  if not PlainPrintfCallsOnly(E.Left) then Exit(False);
  if not PlainPrintfCallsOnly(E.Right) then Exit(False);
  if not PlainPrintfCallsOnly(E.Third) then Exit(False);
  for I := 0 to High(E.Args) do
    if not PlainPrintfCallsOnly(E.Args[I]) then Exit(False);
end;

{ The direct-write printf path bypasses libc's buffered stdout, so it may only
  be used when no other printf in the program falls back to libc; otherwise the
  two output paths interleave and the program's output comes out reordered. }
function TX64Backend.PlainPrintfIsSafe: Boolean;
var
  I: LongInt;
begin
  if not FPlainPrintfChecked then
  begin
    FPlainPrintfChecked := True;
    FPlainPrintfSafe := True;
    for I := 0 to High(FProgram.Functions) do
      if not FProgram.Functions[I].IsPrototype then
        if not PlainPrintfCallsOnlyStmt(FProgram.Functions[I].Body) then
        begin
          FPlainPrintfSafe := False;
          Break;
        end;
  end;
  Result := FPlainPrintfSafe;
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
  if not PlainPrintfIsSafe then Exit;
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
  Indirect, ExpressionCall, Variadic, DirectSingleGP,
    DirectCalleeRegister: Boolean;
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
    CalleeOffset := 0;
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
    Variadic, FTarget, FixedParameterCount);
  try
    DirectSingleGP := False;
    if (Length(E.Args) = 1) and not Variadic and
       not Layout.UsesHiddenReturnPointer then
      DirectSingleGP := not IsAggregateType(ParameterTypes[0]) and
        not IsFloatingType(ParameterTypes[0]) and
        (Layout.Parameters[0].Kind <> alkStack) and
        (Length(Layout.Parameters[0].Parts) = 1) and
        (Layout.Parameters[0].Parts[0].ValueClass = ascInteger);
    { Preserve a simple indirect target in caller-scratch r11 while lowering a
      call-free single argument.  This removes two frame accesses from common
      function-table and callback dispatch without changing evaluation order. }
    DirectCalleeRegister := ExpressionCall and DirectSingleGP and
      not ExprContainsCall(E.Args[0]);
    if ExpressionCall then
    begin
      GenExpr(E.Left);
      if DirectCalleeRegister then
        FText.AddBytes([$49, $89, $C3]) { mov r11,rax }
      else
      begin
        ReserveTemporary(8, 8, CalleeOffset);
        EmitStoreLocal(CalleeOffset);
      end;
    end;
    SetLength(StageOffsets, Length(E.Args));
    for I := 0 to High(E.Args) do
    begin
      if DirectSingleGP then Continue;
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




    if DirectSingleGP then
    begin
      GenExpr(E.Args[0]);
      RegisterOrdinal := GPRegisterOrdinal(
        Layout.Parameters[0].Parts[0].RegisterNumber);
      EmitMoveRaxToArg(RegisterOrdinal);
    end
    else
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
      if DirectSingleGP then Continue;
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
      if not DirectCalleeRegister then
      begin
        FText.AddBytes([$4C, $8B, $9D]);
        FText.AddI32(-CalleeOffset);
      end;
      if Variadic then
      begin
        FText.Add8($B8);
        FText.Add32(LongWord(Layout.FloatingRegistersUsed));
      end;
      FText.AddBytes([$41, $FF, $D3]);
    end
    else
    begin
      if Variadic then
      begin
        FText.Add8($B8);
        FText.Add32(LongWord(Layout.FloatingRegistersUsed));
      end;
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

  Location := ClassifyCTypeForABI(FCurrentReturnType, FTarget);
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
  Location := ClassifyCTypeForABI(RequestedType, FTarget);
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
    CalleeDecl := FProgram.FindFunction(E.Text);
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

  if RegisterArgs = 1 then
  begin
    { With one register argument there is no later argument evaluation that
      can clobber it, so avoid the stage-to-stack/push/pop sequence. }
    GenerateArgument(0);
    EmitMoveRaxToArg(0);
  end
  else
  begin
    for I := 0 to RegisterArgs - 1 do
    begin
      GenerateArgument(I);
      EmitPushRax;
    end;
    for I := RegisterArgs - 1 downto 0 do EmitPopArg(I);
  end;

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
  RotateLeft: Boolean;
  LocalType: TCType;
  RotateValue: TExpr;
  RotateCount: Byte;
  GlobalDecl: TGlobal;
  IndirectLocal: Boolean;
  ImmediateValue: Int64;
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
          L := FindFunctionLabel(E.Text);
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
          if not IndirectLocal and not IsAggregateType(E.CType) then
            EmitLoadLocalTyped(Offset, E.CType)
          else
          begin
            if IndirectLocal then EmitLoadLocal(Offset)
            else EmitAddressLocal(Offset);
            if not IsAggregateType(E.CType) then EmitLoadAtRax(E.CType);
          end;
        end
        else if FindRegisterLocal(E.Text, L, LocalType) then
          EmitLoadRegisterLocalToRax(L, E.CType)
        else
        begin
          L := FindStaticLocalLabel(E.Text);
          if L < 0 then L := FindGlobalLabel(E.Text);
          if L >= 0 then
          begin
            if IsAggregateType(E.CType) then EmitAddressGlobal(L)
            else EmitLoadGlobalTyped(L, E.CType);
          end
          else
          begin
            GlobalDecl := FindGlobal(E.Text);
            if (GlobalDecl = nil) or not GlobalDecl.IsExtern then
              RaiseCompileError(E.Pos, 'unknown variable ''' + E.Text + '''');
            L := EnsureExternalObject(E.Text, E.Pos);
            if FOptions.EmitMode = emObject then EmitObjectGOTLoad(L)
            else EmitLoadGlobal(L);
            if not IsAggregateType(E.CType) then EmitLoadAtRax(E.CType);
          end;
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
          GenBranch(E.Left, FalseLabel, False);
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
          GenBranch(E.Left, FalseLabel, False);
          EmitMovRaxImm(1);
          EmitJump(EndLabel);
          BindTextLabel(FalseLabel);
          GenCondition(E.Right);
          BindTextLabel(EndLabel);
          Exit;
        end;

        if (FOptions.OptimizationLevel >= 1) and
           TryMatchRotate(E, RotateValue, RotateCount, RotateLeft) then
        begin
          GenExpr(RotateValue);
          if StorageSize(E.CType) = 8 then
          begin
            if RotateLeft then
              FText.AddBytes([$48, $C1, $C0, RotateCount])
            else
              FText.AddBytes([$48, $C1, $C8, RotateCount]);
          end
          else
          begin
            if RotateLeft then
              FText.AddBytes([$C1, $C0, RotateCount])
            else
              FText.AddBytes([$C1, $C8, RotateCount]);
          end;
          EmitNormalizeInteger(E.CType);
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
          not IsPointerDifference then
        begin
          if IsPointerResult then
            ImmediateValue := E.Right.IntValue * Scale
          else if E.BinaryOp in [boShiftLeft, boShiftRight] then
            ImmediateValue := E.Right.IntValue
          else if IsIntegerType(LocalType) then
            ImmediateValue := ConvertIntegerValue(E.Right.IntValue, LocalType)
          else
            ImmediateValue := E.Right.IntValue;
          GenExpr(E.Left);
          if IsIntegerType(LocalType) then EmitNormalizeInteger(LocalType);
          EmitImmediateOperation(E.BinaryOp, ImmediateValue,
            UnsignedOperation, Handled);
          if not Handled then
          begin
            { The left operand has already been evaluated, and re-evaluating it
              would run its side effects twice, so finish with the general form
              using the constant materialized in rcx. }
            EmitMovRcxImm(ImmediateValue);
            EmitBinaryOperation(E.BinaryOp, UnsignedOperation);
          end;
          EmitNormalizeInteger(E.CType);
          Exit;
        end;
        GenExpr(E.Left);
        if IsIntegerType(LocalType) then EmitNormalizeInteger(LocalType);
        if not IsPointerResult and not IsPointerDifference and
           TryLoadOperandToRcx(E.Right, LocalType) then
        begin
          { rax already holds the left operand and rcx now holds the right. }
        end
        else
        begin
          EmitPushRax;
          GenExpr(E.Right);
          if IsIntegerType(LocalType) and
            not (E.BinaryOp in [boShiftLeft, boShiftRight]) then
            EmitNormalizeInteger(LocalType);
          if IsPointerResult then EmitScaleRax(Scale);
          FText.AddBytes([$48, $89, $C1]);
          FText.Add8($58);
          Dec(FStackDepth, 8);
        end;
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
        GenBranch(E.Left, FalseLabel, False);
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
            EmitConvertIntegerToFloat(E.Left.CType, E.CType);
        end
        else if IsFloatingType(E.Left.CType) then
        begin
          EmitConvertFloatToInteger(E.Left.CType, E.CType);
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
      begin
        GenAddress(E);
        if not IsAggregateType(E.CType) then EmitLoadAtRax(E.CType);
      end;
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
type
  TIntArray = array of LongInt;
var
  I, Offset, ElseLabel, EndLabel, CondLabel, BodyLabel, ContinueLabel,
    NoMatchLabel, DefaultLabel, L: LongInt;
  SavedCount: LongInt;
  SwitchEntries: TSwitchEntryArray;
  SwitchOrder: TIntArray;
  SwitchUnsigned: Boolean;

  function SwitchValueLess(A, B: Int64): Boolean;
  begin
    if SwitchUnsigned then Result := QWord(A) < QWord(B)
    else Result := A < B;
  end;

  procedure SortSwitchOrder;
  var
    A, B, Key: LongInt;
  begin
    for A := 1 to High(SwitchOrder) do
    begin
      Key := SwitchOrder[A];
      B := A - 1;
      while B >= 0 do
      begin
        if not SwitchValueLess(SwitchEntries[Key].Value,
          SwitchEntries[SwitchOrder[B]].Value) then Break;
        SwitchOrder[B + 1] := SwitchOrder[B];
        Dec(B);
      end;
      SwitchOrder[B + 1] := Key;
    end;
  end;

  procedure EmitSwitchCompare(AValue: Int64);
  begin
    FText.AddBytes([$48, $8B, $04, $24]);
    if (AValue >= Low(LongInt)) and (AValue <= High(LongInt)) then
    begin
      FText.AddBytes([$48, $3D]);
      FText.AddI32(LongInt(AValue));
    end
    else
    begin
      EmitMovRcxImm(AValue);
      FText.AddBytes([$48, $39, $C8]);
    end;
  end;

  procedure EmitSwitchTree(AFirst, ALast, ADefaultLabel: LongInt);
  var
    Mid, EntryIndex, LessLabel: LongInt;
  begin
    if AFirst > ALast then
    begin
      EmitJump(ADefaultLabel);
      Exit;
    end;
    Mid := AFirst + (ALast - AFirst) div 2;
    EntryIndex := SwitchOrder[Mid];
    EmitSwitchCompare(SwitchEntries[EntryIndex].Value);
    EmitJcc($84, SwitchEntries[EntryIndex].MatchLabel);
    if AFirst = ALast then
    begin
      EmitJump(ADefaultLabel);
      Exit;
    end;
    LessLabel := NewLabel;
    if SwitchUnsigned then EmitJcc($82, LessLabel)
    else EmitJcc($8C, LessLabel);
    EmitSwitchTree(Mid + 1, ALast, ADefaultLabel);
    BindTextLabel(LessLabel);
    EmitSwitchTree(AFirst, Mid - 1, ADefaultLabel);
  end;

begin
  if S = nil then Exit;
  case S.Kind of
    skEmpty: ;
    skExpr:
      if (FOptions.OptimizationLevel >= 1) and (S.Expr <> nil) then
        case S.Expr.Kind of
          ekPreInc: GenIncDec(S.Expr, 1, False, True);
          ekPreDec: GenIncDec(S.Expr, -1, False, True);
          ekPostInc: GenIncDec(S.Expr, 1, True, True);
          ekPostDec: GenIncDec(S.Expr, -1, True, True);
        else
          GenExpr(S.Expr);
        end
      else
        GenExpr(S.Expr);
    skAsm: GenInlineAsm(S);
    skDecl:
      { A static local was laid out and initialized before the body was
        generated, so reaching the declaration does nothing at run time. }
      if not S.IsStatic then
      begin
        FCurrentDeclPos := S.Pos;
        if FindRegisterPlan(S.Name, L) then
        begin
          AddRegisterLocal(S.Name, S.CType, L);
          if S.Expr <> nil then
          begin
            GenExpr(S.Expr);
            EmitStoreRaxToRegisterLocal(L, S.CType);
          end;
        end
        else
        begin
          AddLocal(S.Name, S.CType, False, Offset);
          InitializeLocal(Offset, S.CType, S.Expr, S.Pos);
        end;
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
              EmitConvertFloatToInteger(S.Expr.CType, FCurrentReturnType);
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
        if S.ElseBody = nil then
        begin
          EndLabel := NewLabel;
          GenBranch(S.Expr, EndLabel, False);
          GenStmt(S.Body);
          BindTextLabel(EndLabel);
        end
        else
        begin
          ElseLabel := NewLabel; EndLabel := NewLabel;
          GenBranch(S.Expr, ElseLabel, False);
          GenStmt(S.Body);
          EmitJump(EndLabel);
          BindTextLabel(ElseLabel);
          GenStmt(S.ElseBody);
          BindTextLabel(EndLabel);
        end;
      end;
    skWhile:
      begin
        CondLabel := NewLabel; EndLabel := NewLabel;
        BindTextLabel(CondLabel);
        NoteLoopHead(CondLabel);
        GenBranch(S.Expr, EndLabel, False);
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
        NoteLoopHead(BodyLabel);
        PushLoop(EndLabel, ContinueLabel);
        GenStmt(S.Body);
        PopLoop;
        BindTextLabel(ContinueLabel);
        GenBranch(S.Expr, BodyLabel, True);
        BindTextLabel(EndLabel);
      end;
    skFor:
      begin
        SavedCount := Length(FLocals);
        EnterScope;
        GenStmt(S.InitStmt);
        CondLabel := NewLabel; ContinueLabel := NewLabel; EndLabel := NewLabel;
        BindTextLabel(CondLabel);
        NoteLoopHead(CondLabel);
        if S.Expr <> nil then GenBranch(S.Expr, EndLabel, False);
        PushLoop(EndLabel, ContinueLabel);
        GenStmt(S.Body);
        PopLoop;
        BindTextLabel(ContinueLabel);
        if S.Expr2 <> nil then
          case S.Expr2.Kind of
            ekPreInc: GenIncDec(S.Expr2, 1, False, True);
            ekPreDec: GenIncDec(S.Expr2, -1, False, True);
            ekPostInc: GenIncDec(S.Expr2, 1, True, True);
            ekPostDec: GenIncDec(S.Expr2, -1, True, True);
          else
            GenExpr(S.Expr2);
          end;
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
        NoMatchLabel := NewLabel;
        SetLength(SwitchOrder, 0);
        for I := 0 to High(SwitchEntries) do
          if not SwitchEntries[I].IsDefault then
          begin
            L := Length(SwitchOrder);
            SetLength(SwitchOrder, L + 1);
            SwitchOrder[L] := I;
          end;
        SwitchUnsigned := S.Expr.CType.IsUnsigned;
        if Length(SwitchOrder) >= 8 then
        begin
          SortSwitchOrder;
          EmitSwitchTree(0, High(SwitchOrder), NoMatchLabel);
        end
        else
        begin
          for I := 0 to High(SwitchOrder) do
          begin
            L := SwitchOrder[I];
            EmitSwitchCompare(SwitchEntries[L].Value);
            EmitJcc($84, SwitchEntries[L].MatchLabel);
          end;
          EmitJump(NoMatchLabel);
        end;
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
  RegisterResident: array of Boolean;
  CallFree, CanUseRegisterParameters: Boolean;
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
    F.IsVariadic, FTarget);
  try
  PlanRegisterLocals(F);
  CallFree := not StmtContainsCallOrAsm(F.Body);
  CanUseRegisterParameters := (FOptions.OptimizationLevel >= 1) and
    not FOptions.DebugInfo and CallFree and not F.IsVariadic and
    not Layout.UsesHiddenReturnPointer and
    StmtSafeForRegisterParameters(F.Body);
  SetLength(RegisterResident, Length(F.Params));
  if CanUseRegisterParameters then
    for I := 0 to High(F.Params) do
    begin
      Location := Layout.Parameters[I];
      if (Location.Kind <> alkStack) and (Length(Location.Parts) = 1) and
         (Location.Parts[0].ValueClass = ascInteger) and
         (IsIntegerType(F.Params[I].CType) or IsPointerType(F.Params[I].CType)) and
         not F.Params[I].CType.IsVolatile and
         not StmtRequiresParameterStorage(F.Body, F.Params[I].Name) then
      begin
        RegisterOrdinal := GPRegisterOrdinal(Location.Parts[0].RegisterNumber);
        RegisterResident[I] := RegisterOrdinal <= 1;
      end;
    end;
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
  ParameterBytes := 0;
  if Layout.UsesHiddenReturnPointer then Inc(ParameterBytes, 15);
  if F.IsVariadic then Inc(ParameterBytes, 191);
  for I := 0 to High(F.Params) do
  begin
    if RegisterResident[I] then Continue;
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
  FCurrentFrameless := CanUseRegisterParameters and (FrameSize = 0) and
    not FUsingCalleeSavedLocals;
  if not FCurrentFrameless then
    FText.AddBytes([$55, $48, $89, $E5]);
  if FrameSize > 0 then
  begin
    if FrameSize <= 127 then
      FText.AddBytes([$48, $83, $EC, Byte(FrameSize)])
    else
    begin
      FText.AddBytes([$48, $81, $EC]);
      FText.AddI32(FrameSize);
    end;
  end;
  if FUsingCalleeSavedLocals then
  begin
    { Save an even number of registers so the stack stays 16-byte aligned
      at every call site without an additional dynamic alignment fixup. }
    case FRegisterSaveCount of
      2: FText.AddBytes([$41, $54, $41, $55]);
      4: FText.AddBytes([$41, $54, $41, $55, $41, $56, $41, $57]);
    else
      raise ERCCError.Create('internal error: invalid register save count');
    end;
  end;
  SetLength(FLocals, 0);
  SetLength(FRegisterLocals, 0);
  SetLength(FUserLabels, 0);
  SetLength(FStaticLocals, 0);
  ReserveStaticLocals(F.Body);
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
    if RegisterResident[I] then
    begin
      RegisterOrdinal := GPRegisterOrdinal(Location.Parts[0].RegisterNumber);
      AddRegisterLocal(F.Params[I].Name, F.Params[I].CType, RegisterOrdinal);
      Continue;
    end;
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
  if FUsingCalleeSavedLocals then
    case FRegisterSaveCount of
      2: FText.AddBytes([$41, $5D, $41, $5C]);
      4: FText.AddBytes([$41, $5F, $41, $5E, $41, $5D, $41, $5C]);
    else
      raise ERCCError.Create('internal error: invalid register restore count');
    end;
  if FCurrentFrameless then
  begin
    FText.Add8($C3);
    FListing.Add('  ret');
  end
  else
  begin
    FText.AddBytes([$C9, $C3]);
    FListing.Add('  leave');
  end;
  FListing.Add('  ; native x86-64 body: ' + IntToStr(FText.Size) + ' bytes so far');
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
      L := FindFunctionLabel(FProgram.Functions[I].Name);
      GenFunction(FProgram.Functions[I], L);
    end;
  if FOptions.EmitMode = emObject then
  begin
    RelaxJumps;
    AlignLoopHeads;
    Exit;
  end;
  EmitRuntime;



  EmitStartup;
  RelaxJumps;
  AlignLoopHeads;
end;

{ The needed-library set decides how much dynamic metadata the ELF writer will
  append, which in turn fixes where the zero-fill region starts. Both the
  executable writer and the resolved listing have to agree on it. }
function TX64Backend.ResolveNeededLibraryNames: rcc_types.TStringArray;
var
  Target: TTargetDescriptor;
  ResolvedLibraries: TResolvedLibraryArray;
begin
  Result := nil;
  SetLength(ResolvedLibraries, 0);
  Target := GetTargetOrRaise(FOptions.TargetTriple);
  if Target.OperatingSystem <> osLinux then Exit;
  if FOptions.StaticLink then Exit;
  ResolveDynamicLibraries(FOptions.LibraryPaths, FOptions.Libraries,
    FOptions.Sysroot, TargetMultiArchName(Target), Target.DefaultLibC,
    ArchitectureName(Target.Architecture), Target.ELFMachine,
    Target.Architecture = archX86_64,
    (Length(FImports) <> 0) or (Length(FOptions.Libraries) <> 0),
    FOptions.NoDefaultLibraries, FOptions.Freestanding, ResolvedLibraries);
  Result := ResolvedNeededNames(ResolvedLibraries);
end;

procedure TX64Backend.PrepareBssBase(const ANeededNames: array of string);
begin
  FBssBase := AlignUp(ELF64DataPayloadSize(FText, FData, FImports,
    ANeededNames, FOptions.RPaths, FOptions.BindNow), RCCELFBssAlignment);
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
  PrepareBssBase(ResolveNeededLibraryNames);
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
  TextIndex, DataIndex, BssIndex: LongInt;
  TextSectionSymbol, DataSectionSymbol, BssSectionSymbol: LongInt;
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
      LabelID := FindFunctionLabel(F.Name);
      Obj.AddSymbol(F.Name, Binding, ostFunction, osvDefault,
        TextIndex, QWord(FLabels[LabelID].Offset), FunctionSize(LabelID), True);
    end;
    for J := 0 to High(FProgram.Globals) do
    begin
      G := FProgram.Globals[J];
      if G.IsExtern or (G.IsStatic <> AStatic) then Continue;
      LabelID := FindNamedLabel(FGlobals, G.Name);
      if FLabels[LabelID].Section = lsBss then
        Obj.AddSymbol(G.Name, Binding, ostObject, osvDefault,
          BssIndex, QWord(FLabels[LabelID].Offset),
          QWord(StorageSize(G.CType)), True)
      else
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
    if (ALabel < 0) or (ALabel >= FLabelCount) then
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
      lsBss:
        begin
          ASymbolIndex := BssSectionSymbol;
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
    BssIndex := Obj.AddSection('.bss', oskBSS, [osfAlloc, osfWrite], 16);
    Obj.Section(BssIndex).VirtualSize := QWord(FBssSize);
    Obj.AddSection('.note.GNU-stack', oskCustom, [], 1);


    TextSectionSymbol := Obj.AddSymbol('', osbLocal, ostSection, osvDefault,
      TextIndex, 0, 0, True);
    DataSectionSymbol := Obj.AddSymbol('', osbLocal, ostSection, osvDefault,
      DataIndex, 0, 0, True);
    BssSectionSymbol := Obj.AddSymbol('', osbLocal, ostSection, osvDefault,
      BssIndex, 0, 0, True);
    AddDefinedSymbols(True);
    AddDefinedSymbols(False);

    SetLength(UndefinedSymbolIndices, Length(FObjectUndefined));
    for I := 0 to High(FObjectUndefined) do
      UndefinedSymbolIndices[I] := Obj.AddSymbol(FObjectUndefined[I].Name,
        osbGlobal, ObjectSymbolType(FObjectUndefined[I].SymbolType),
        osvDefault, 0, 0, 0, False);

    for I := 0 to FFixupCount - 1 do
    begin
      Fixup := FFixups[I];
      LabelInfo := FLabels[Fixup.TargetLabel];
      if LabelInfo.Section = lsText then
      begin
        if Fixup.Kind in [rfJmpShort, rfJccShort] then
          FText.Patch8(Fixup.PatchOffset,
            Byte(LongWord(LabelInfo.Offset - (Fixup.PatchOffset + 1)) and $FF))
        else
          FText.Patch32(Fixup.PatchOffset,
            LabelInfo.Offset - (Fixup.PatchOffset + 4));
        Inc(FStats.FixupsResolved);
        Continue;
      end;
      if Fixup.Kind in [rfJmpShort, rfJccShort] then
        raise ERCCError.Create(
          'internal error: short jump requires a local text label');
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

    for I := 0 to FDataAddressFixupCount - 1 do
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
          SymbolIndex := FindFunctionLabel(
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
    WriteRelocatableObject(AFileName, Obj);
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
      LabelID := FindFunctionLabel(FunctionDecl.Name);
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
      LabelID := FindFunctionLabel(FunctionDecl.Name);
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
  Target := GetTargetOrRaise(FOptions.TargetTriple);
  Layout := ComputeELFExecutableLayout(QWord(FText.Size), QWord(FData.Size),
    QWord(FLabels[FEntryLabel].Offset));

  try
    if Target.OperatingSystem <> osLinux then
    begin
      if Target.ObjectFormat <> ofELF64 then
        raise ERCCError.Create(
          'internal error: x86 ELF executable writer selected for ' +
          ObjectFormatName(Target.ObjectFormat));
      if (Length(FImports) <> 0) or (Length(FOptions.Libraries) <> 0) or
         (Length(FOptions.ObjectFiles) <> 0) then
        raise ERCCError.Create(
          'error: BSD direct executable output is currently static and ' +
          'freestanding; emit an object with -c to use a target system linker');
      FBssBase := AlignUp(QWord(FData.Size), RCCELFBssAlignment);
      ResolveFixups(Layout.TextVA, Layout.DataVA);
      ResolveExternalRelocations(Layout.TextVA, Layout.DataVA);
      if FOptions.DebugInfo then BuildExecutableDebugObject;
      WriteStaticELF64Executable(AFileName, Target, FText, FData,
        QWord(FLabels[FEntryLabel].Offset), FSyscallSites, QWord(FBssSize));
      if DebugObject <> nil then
        AppendELF64DebugSections(AFileName, DebugObject,
          Layout.TextOffset, Layout.TextVA, QWord(FText.Size),
          Layout.DataOffset, Layout.DataVA, QWord(FData.Size));
      FStats.TextBytes := FText.Size;
      FStats.DataBytes := FData.Size;
      Exit;
    end;
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
    { Zero-initialized objects sit past the dynamic linking metadata that the
      ELF writer appends, so their addresses can only be resolved once the
      needed-library set is known. }
    PrepareBssBase(NeededNames);
    ResolveFixups(Layout.TextVA, Layout.DataVA);
    ResolveExternalRelocations(Layout.TextVA, Layout.DataVA);
    if FOptions.DebugInfo then BuildExecutableDebugObject;
    WriteELF64Executable(AFileName, FText, FData,
      QWord(FLabels[FEntryLabel].Offset), FImports, NeededNames,
      FOptions.RPaths, FOptions.BindNow, DynamicLinker, QWord(FBssSize));
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
