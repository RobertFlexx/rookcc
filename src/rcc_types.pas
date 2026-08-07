unit rcc_types;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_name_index;

type
  ERCCError = class(Exception);

  TSourcePos = record
    FileName: string;
    Line: LongInt;
    Column: LongInt;
  end;

  TTokenKind = (
    tkEOF,
    tkIdentifier, tkInteger, tkFloat, tkString,
    tkLParen, tkRParen, tkLBrace, tkRBrace,
    tkLBracket, tkRBracket, tkSemicolon, tkComma,
    tkQuestion, tkColon,
    tkPlus, tkMinus, tkStar, tkSlash, tkPercent,
    tkAmp, tkPipe, tkCaret, tkTilde, tkBang,
    tkAssign,
    tkPlusAssign, tkMinusAssign, tkStarAssign,
    tkSlashAssign, tkPercentAssign,
    tkAmpAssign, tkPipeAssign, tkCaretAssign,
    tkShiftLeftAssign, tkShiftRightAssign,
    tkEqual, tkNotEqual, tkLess, tkLessEqual,
    tkGreater, tkGreaterEqual,
    tkLogicalAnd, tkLogicalOr,
    tkShiftLeft, tkShiftRight,
    tkIncrement, tkDecrement,
    tkArrow, tkDot, tkEllipsis,
    kwVoid, kwChar, kwShort, kwInt, kwLong, kwFloat, kwDouble, kwBool,
    kwSigned, kwUnsigned, kwConst, kwVolatile, kwRestrict,
    kwStatic, kwExtern, kwAuto, kwRegister, kwInline,
    kwTypedef, kwStruct, kwUnion, kwEnum,
    kwIf, kwElse, kwWhile, kwDo, kwFor,
    kwSwitch, kwCase, kwDefault,
    kwBreak, kwContinue, kwReturn, kwGoto, kwAsm, kwTypeof,
    kwSizeof, kwAlignof, kwAlignas, kwStaticAssert, kwGeneric, kwNullptr,
    kwGNUAttribute
  );

  TToken = record
    Kind: TTokenKind;
    Text: string;
    IntValue: Int64;
    FloatValue: Double;
    Pos: TSourcePos;
  end;

  TTokenArray = array of TToken;
  TStringArray = array of string;

  TCTypeKind = (
    ctVoid,
    ctChar,
    ctShort,
    ctInt,
    ctLong,
    ctLongLong,
    ctBool,
    ctFloat,
    ctDouble,
    ctLongDouble,
    ctPointer,
    ctArray,
    ctStruct,
    ctUnion,
    ctEnum,
    ctFunction
  );

  TStructMember = record
    Name: string;
    CType: Pointer;
    Offset: LongInt;
    Width: LongInt;
    IsBitField: Boolean;
    BitOffset: LongInt;
    BitWidth: LongInt;
    AlignmentOverride: LongInt;
    IsPacked: Boolean;
  end;
  TStructMemberArray = array of TStructMember;

  PStructMembers = ^TStructMembers;
  TStructMembers = record
    Name: string;
    Members: TStructMemberArray;
    Size: LongInt;
    Align: LongInt;
    IsUnion: Boolean;
    IsPacked: Boolean;
    ExplicitAlign: LongInt;
  end;

  TEnumConstant = record
    Name: string;
    Value: Int64;
  end;
  TEnumConstantArray = array of TEnumConstant;

  TCType = record
    Kind: TCTypeKind;
    IsUnsigned: Boolean;
    IsConst: Boolean;
    IsVolatile: Boolean;
    IsPacked: Boolean;
    AlignmentOverride: LongInt;
    SuppressUnusedWarning: Boolean;
    PreserveForLinker: Boolean;
    PointerDepth: LongInt;
    ArrayLength: LongInt;
    StructInfo: PStructMembers;
    EnumConstants: TEnumConstantArray;
    ReturnType: Pointer;
    ParamTypes: Pointer;
    ParamCount: LongInt;
    IsVariadic: Boolean;
    ElementKind: TCTypeKind;
    ElementUnsigned: Boolean;
    ElementConst: Boolean;
    ElementPointerDepth: LongInt;
    ElementStructInfo: PStructMembers;
    { Full element type for arrays. The flattened Element* fields above cannot
      describe an array of arrays, so nested dimensions live here. }
    ElementRef: Pointer;
  end;
  PCType = ^TCType;





  TFunctionParameterList = record
    Items: array of TCType;
  end;
  PFunctionParameterList = ^TFunctionParameterList;

  TExprKind = (
    ekInteger,
    ekFloat,
    ekString,
    ekVariable,
    ekUnary,
    ekBinary,
    ekAssign,
    ekCall,
    ekConditional,
    ekAddress,
    ekDeref,
    ekPreInc,
    ekPreDec,
    ekPostInc,
    ekPostDec,
    ekMember,
    ekArrow,
    ekCast,
    ekCompoundLit,
    ekComma,
    ekIndex,
    ekSizeof,
    ekAlignof,
    ekGeneric,
    ekNullptr,
    ekTrap
  );

  TUnaryOp = (
    uoPositive,
    uoNegative,
    uoLogicalNot,
    uoBitwiseNot
  );

  TBinaryOp = (
    boAdd, boSub, boMul, boDiv, boMod,
    boShiftLeft, boShiftRight,
    boLess, boLessEqual, boGreater, boGreaterEqual,
    boEqual, boNotEqual,
    boBitAnd, boBitXor, boBitOr,
    boLogicalAnd, boLogicalOr,
    boComma
  );

  TAssignOp = (
    aoAssign,
    aoAdd, aoSub, aoMul, aoDiv, aoMod,
    aoBitAnd, aoBitOr, aoBitXor,
    aoShiftLeft, aoShiftRight
  );

  TExpr = class;
  TStmt = class;
  TFunction = class;
  TGlobal = class;

  TExprArray = array of TExpr;
  TStmtArray = array of TStmt;
  TFunctionArray = array of TFunction;
  TGlobalArray = array of TGlobal;

  TExpr = class
  public
    Kind: TExprKind;
    Pos: TSourcePos;
    IntValue: Int64;
    FloatValue: Double;
    Text: string;
    UnaryOp: TUnaryOp;
    BinaryOp: TBinaryOp;
    AssignOp: TAssignOp;
    Left: TExpr;
    Right: TExpr;
    Third: TExpr;
    Args: TExprArray;
    CType: TCType;
    OperationType: TCType;
    IsLValue: Boolean;
    IsFunctionDesignator: Boolean;
    IsBitField: Boolean;
    { Member named by a designated initializer, kept apart from Text because a
      string literal stores its own value there. }
    Designator: string;
    HasIndexDesignator: Boolean;
    IndexDesignator: Int64;
    BitOffset: LongInt;
    BitWidth: LongInt;
    BitStorageSize: LongInt;
    constructor Create(AKind: TExprKind; const APos: TSourcePos);
    destructor Destroy; override;
  end;

  TAsmOperand = class
  public
    Name: string;
    ConstraintText: string;
    Expr: TExpr;
    IsOutput: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;
  TAsmOperandArray = array of TAsmOperand;

  TStmtKind = (
    skEmpty,
    skBlock,
    skExpr,
    skDecl,
    skReturn,
    skIf,
    skWhile,
    skDoWhile,
    skFor,
    skBreak,
    skContinue,
    skSwitch,
    skCase,
    skDefault,
    skGoto,
    skLabel,
    skAsm,
    skStaticAssert
  );

  TStmt = class
  public
    Kind: TStmtKind;
    Pos: TSourcePos;
    Name: string;
    CType: TCType;
    Expr: TExpr;
    Expr2: TExpr;
    InitStmt: TStmt;
    Body: TStmt;
    ElseBody: TStmt;
    Children: TStmtArray;
    CaseValue: Int64;
    IsDeclarationGroup: Boolean;
    { Set on a local declaration carrying the static storage class, which gives
      it program lifetime instead of a stack slot. }
    IsStatic: Boolean;
    AsmTemplate: string;
    AsmVolatile: Boolean;
    AsmGoto: Boolean;
    AsmOutputs: TAsmOperandArray;
    AsmInputs: TAsmOperandArray;
    AsmClobbers: TStringArray;
    AsmLabels: TStringArray;
    constructor Create(AKind: TStmtKind; const APos: TSourcePos);
    destructor Destroy; override;
  end;

  TParam = record
    Name: string;
    CType: TCType;
  end;

  TParamArray = array of TParam;

  TFunction = class
  public
    Name: string;
    ReturnType: TCType;
    Params: TParamArray;
    Body: TStmt;
    IsPrototype: Boolean;
    IsVariadic: Boolean;
    IsStatic: Boolean;
    Pos: TSourcePos;
    destructor Destroy; override;
  end;

  TGlobal = class
  public
    Name: string;
    CType: TCType;
    HasInitializer: Boolean;
    InitialValue: Int64;
    IsStatic: Boolean;
    IsExtern: Boolean;
    IsTentative: Boolean;
    Initializer: TExpr;
    Pos: TSourcePos;
    destructor Destroy; override;
  end;

  TProgram = class
  private
    FFunctionIndex: TNameIndex;
    FGlobalIndex: TNameIndex;
    FOwnedStructInfos: array of PStructMembers;
    FOwnedMemberTypes: array of PCType;
    FOwnedFunctionParameterLists: array of PFunctionParameterList;
  public
    Functions: TFunctionArray;
    Globals: TGlobalArray;
    StaticAssertions: TStmtArray;
    constructor Create;
    destructor Destroy; override;
    procedure OwnStructInfo(AInfo: PStructMembers);
    procedure OwnMemberType(AType: PCType);
    procedure OwnFunctionParameterList(AList: PFunctionParameterList);
    procedure MoveTypeStorageFrom(ASource: TProgram);
    procedure AddFunction(AFunction: TFunction);
    procedure AddGlobal(AGlobal: TGlobal);
    procedure AddStaticAssertion(AStatement: TStmt);
    procedure RebuildNameIndexes;
    function FindFunctionIndex(const AName: string): LongInt;
    function FindGlobalIndex(const AName: string): LongInt;
    function FindFunction(const AName: string): TFunction;
    function FindGlobal(const AName: string): TGlobal;
  end;

  TColorMode = (cmAuto, cmAlways, cmNever);

  TCStandard = (
    csC90, csC99, csC11, csC17, csC23,
    csGNU99, csGNU11, csGNU17, csGNU23,
    csRCC
  );

  TWarningLevel = (wlDefault, wlAll, wlExtra, wlPedantic);
  TEmitMode = (emExecutable, emAssembly, emIR, emTokens,
    emPreprocessed, emCheck, emObject, emDependencies);

  TCompilerOptions = record
    Inputs: TStringArray;
    OutputFile: string;
    IncludePaths: TStringArray;
    QuoteIncludePaths: TStringArray;
    SystemIncludePaths: TStringArray;
    Defines: TStringArray;
    Undefines: TStringArray;
    LibraryPaths: TStringArray;
    Libraries: TStringArray;
    RPaths: TStringArray;
    ObjectFiles: TStringArray;
    Sysroot: string;
    ResourceDir: string;
    DynamicLinker: string;
    TargetTriple: string;
    TargetCPU: string;
    TargetFeatures: string;
    OptimizationLevel: LongInt;
    OptimizeSize: Boolean;
    { 0 = speed/default, 1 = -Os, 2 = -Oz.  Keep OptimizeSize as a
      compatibility convenience for subsystems that only need a boolean. }
    SizeOptimizationLevel: LongInt;
    OptimizeDebug: Boolean;
    Standard: TCStandard;
    WarningLevel: TWarningLevel;
    DisabledWarnings: TStringArray;
    EmitMode: TEmitMode;
    ColorMode: TColorMode;
    Verbose: Boolean;
    ShowStats: Boolean;
    WarningsAsErrors: Boolean;
    NoStdInc: Boolean;
    Freestanding: Boolean;
    PositionIndependent: Boolean;
    StaticLink: Boolean;
    SharedOutput: Boolean;
    NoDefaultLibraries: Boolean;
    BindNow: Boolean;
    DebugInfo: Boolean;
    DryRun: Boolean;
    RunAfterCompile: Boolean;
    RunArguments: TStringArray;
    LinkOnly: Boolean;
    GenerateDependencies: Boolean;
    SystemDependencies: Boolean;
    PhonyDependencies: Boolean;
    DependencyFile: string;
    DependencyTarget: string;
    ThreadCount: LongInt;
  end;

function MakeType(AKind: TCTypeKind; AUnsigned: Boolean = False;
  APointerDepth: LongInt = 0): TCType;
function TokenKindName(AKind: TTokenKind): string;
procedure RaiseCompileError(const APos: TSourcePos; const AMessage: string);
function TypesEqual(const A, B: TCType): Boolean;
function CTypeSize(const AType: TCType): Int64;
function CTypeAlign(const AType: TCType): LongInt;
function ArrayElementType(const AType: TCType): TCType;
procedure ConfigureCTypeLongDoubleLayout(ASize, AAlignment: LongInt);
function IsArithmeticType(const AType: TCType): Boolean;
function IsIntegerType(const AType: TCType): Boolean;
function IsScalarType(const AType: TCType): Boolean;
function CStandardName(AStandard: TCStandard): string;
function CStandardVersion(AStandard: TCStandard): string;
function CStandardRevision(AStandard: TCStandard): LongInt;
function CStandardAtLeast(AStandard: TCStandard; ARevision: LongInt): Boolean;
function IsGNUStandard(AStandard: TCStandard): Boolean;

implementation

var
  ActiveLongDoubleSize: LongInt = 16;
  ActiveLongDoubleAlignment: LongInt = 16;

procedure ConfigureCTypeLongDoubleLayout(ASize, AAlignment: LongInt);
begin
  if not (ASize in [8, 16]) then
    raise ERCCError.Create('internal error: unsupported long double size');
  if (AAlignment <= 0) or ((AAlignment and (AAlignment - 1)) <> 0) then
    raise ERCCError.Create('internal error: invalid long double alignment');
  ActiveLongDoubleSize := ASize;
  ActiveLongDoubleAlignment := AAlignment;
end;

constructor TExpr.Create(AKind: TExprKind; const APos: TSourcePos);
begin
  inherited Create;
  Kind := AKind;
  Pos := APos;
  Left := nil;
  Right := nil;
  Third := nil;
  SetLength(Args, 0);
  IntValue := 0;
  FloatValue := 0.0;
  CType := MakeType(ctInt);
  OperationType := MakeType(ctInt);
  IsLValue := False;
  IsFunctionDesignator := False;
  IsBitField := False;
  Designator := '';
  HasIndexDesignator := False;
  IndexDesignator := 0;
  BitOffset := 0;
  BitWidth := 0;
  BitStorageSize := 0;
end;

destructor TExpr.Destroy;
var
  I: LongInt;
begin
  Left.Free;
  Right.Free;
  Third.Free;
  for I := 0 to High(Args) do
    Args[I].Free;
  inherited Destroy;
end;

constructor TAsmOperand.Create;
begin
  inherited Create;
  Expr := nil;
  IsOutput := False;
end;

destructor TAsmOperand.Destroy;
begin
  Expr.Free;
  inherited Destroy;
end;

constructor TStmt.Create(AKind: TStmtKind; const APos: TSourcePos);
begin
  inherited Create;
  Kind := AKind;
  Pos := APos;
  Expr := nil;
  Expr2 := nil;
  InitStmt := nil;
  Body := nil;
  ElseBody := nil;
  SetLength(Children, 0);
  SetLength(AsmOutputs, 0);
  SetLength(AsmInputs, 0);
  SetLength(AsmClobbers, 0);
  SetLength(AsmLabels, 0);
  AsmVolatile := False;
  AsmGoto := False;
end;

destructor TStmt.Destroy;
var
  I: LongInt;
begin
  Expr.Free;
  Expr2.Free;
  InitStmt.Free;
  Body.Free;
  ElseBody.Free;
  for I := 0 to High(Children) do
    Children[I].Free;
  for I := 0 to High(AsmOutputs) do
    AsmOutputs[I].Free;
  for I := 0 to High(AsmInputs) do
    AsmInputs[I].Free;
  inherited Destroy;
end;

destructor TFunction.Destroy;
begin
  Body.Free;
  inherited Destroy;
end;

destructor TGlobal.Destroy;
begin
  Initializer.Free;
  inherited Destroy;
end;

constructor TProgram.Create;
begin
  inherited Create;
  FFunctionIndex := TNameIndex.Create;
  FGlobalIndex := TNameIndex.Create;
end;

destructor TProgram.Destroy;
var
  I: LongInt;
begin
  FFunctionIndex.Free;
  FGlobalIndex.Free;
  for I := 0 to High(Functions) do
    Functions[I].Free;
  for I := 0 to High(Globals) do
    Globals[I].Free;
  for I := 0 to High(StaticAssertions) do
    StaticAssertions[I].Free;
  for I := 0 to High(FOwnedStructInfos) do
    if FOwnedStructInfos[I] <> nil then
      Dispose(FOwnedStructInfos[I]);
  for I := 0 to High(FOwnedMemberTypes) do
    if FOwnedMemberTypes[I] <> nil then
      Dispose(FOwnedMemberTypes[I]);
  for I := 0 to High(FOwnedFunctionParameterLists) do
    if FOwnedFunctionParameterLists[I] <> nil then
      Dispose(FOwnedFunctionParameterLists[I]);
  inherited Destroy;
end;

procedure TProgram.OwnStructInfo(AInfo: PStructMembers);
var
  N: LongInt;
begin
  if AInfo = nil then Exit;
  N := Length(FOwnedStructInfos);
  SetLength(FOwnedStructInfos, N + 1);
  FOwnedStructInfos[N] := AInfo;
end;

procedure TProgram.OwnMemberType(AType: PCType);
var
  N: LongInt;
begin
  if AType = nil then Exit;
  N := Length(FOwnedMemberTypes);
  SetLength(FOwnedMemberTypes, N + 1);
  FOwnedMemberTypes[N] := AType;
end;

procedure TProgram.OwnFunctionParameterList(AList: PFunctionParameterList);
var
  N: LongInt;
begin
  if AList = nil then Exit;
  N := Length(FOwnedFunctionParameterLists);
  SetLength(FOwnedFunctionParameterLists, N + 1);
  FOwnedFunctionParameterLists[N] := AList;
end;

procedure TProgram.MoveTypeStorageFrom(ASource: TProgram);
var
  I: LongInt;
begin
  if ASource = nil then Exit;
  for I := 0 to High(ASource.FOwnedStructInfos) do
  begin
    OwnStructInfo(ASource.FOwnedStructInfos[I]);
    ASource.FOwnedStructInfos[I] := nil;
  end;
  for I := 0 to High(ASource.FOwnedMemberTypes) do
  begin
    OwnMemberType(ASource.FOwnedMemberTypes[I]);
    ASource.FOwnedMemberTypes[I] := nil;
  end;
  for I := 0 to High(ASource.FOwnedFunctionParameterLists) do
  begin
    OwnFunctionParameterList(ASource.FOwnedFunctionParameterLists[I]);
    ASource.FOwnedFunctionParameterLists[I] := nil;
  end;
  SetLength(ASource.FOwnedStructInfos, 0);
  SetLength(ASource.FOwnedMemberTypes, 0);
  SetLength(ASource.FOwnedFunctionParameterLists, 0);
end;

procedure TProgram.AddFunction(AFunction: TFunction);
var
  N, Previous: LongInt;
begin
  Previous := -1;
  if (AFunction <> nil) and (AFunction.Name <> '') then
    Previous := FindFunctionIndex(AFunction.Name);
  if Previous >= 0 then
  begin
    AFunction.ReturnType.PreserveForLinker :=
      AFunction.ReturnType.PreserveForLinker or
      Functions[Previous].ReturnType.PreserveForLinker;
    Functions[Previous].ReturnType.PreserveForLinker :=
      AFunction.ReturnType.PreserveForLinker;
  end;
  N := Length(Functions);
  SetLength(Functions, N + 1);
  Functions[N] := AFunction;
  if (AFunction <> nil) and (AFunction.Name <> '') and
     ((Previous < 0) or Functions[Previous].IsPrototype or
      not AFunction.IsPrototype) then
    FFunctionIndex.Put(AFunction.Name, N);
end;

procedure TProgram.AddGlobal(AGlobal: TGlobal);
var
  N, Previous: LongInt;
begin
  Previous := -1;
  if (AGlobal <> nil) and (AGlobal.Name <> '') then
    Previous := FindGlobalIndex(AGlobal.Name);
  if Previous >= 0 then
  begin
    AGlobal.CType.PreserveForLinker :=
      AGlobal.CType.PreserveForLinker or
      Globals[Previous].CType.PreserveForLinker;
    Globals[Previous].CType.PreserveForLinker :=
      AGlobal.CType.PreserveForLinker;
  end;
  N := Length(Globals);
  SetLength(Globals, N + 1);
  Globals[N] := AGlobal;
  if (AGlobal <> nil) and (AGlobal.Name <> '') and
     ((Previous < 0) or Globals[Previous].IsExtern or
      (Globals[Previous].IsTentative and not AGlobal.IsTentative) or
      AGlobal.HasInitializer) then
    FGlobalIndex.Put(AGlobal.Name, N);
end;

procedure TProgram.AddStaticAssertion(AStatement: TStmt);
var
  N: LongInt;
begin
  N := Length(StaticAssertions);
  SetLength(StaticAssertions, N + 1);
  StaticAssertions[N] := AStatement;
end;

procedure TProgram.RebuildNameIndexes;
var
  I, Previous: LongInt;
begin
  FFunctionIndex.Clear;
  FGlobalIndex.Clear;
  for I := 0 to High(Functions) do
    if (Functions[I] <> nil) and (Functions[I].Name <> '') then
    begin
      Previous := FFunctionIndex.GetOrDefault(Functions[I].Name, -1);
      if (Previous < 0) or Functions[Previous].IsPrototype or
         not Functions[I].IsPrototype then
        FFunctionIndex.Put(Functions[I].Name, I);
    end;
  for I := 0 to High(Globals) do
    if (Globals[I] <> nil) and (Globals[I].Name <> '') then
    begin
      Previous := FGlobalIndex.GetOrDefault(Globals[I].Name, -1);
      if (Previous < 0) or Globals[Previous].IsExtern or
         (Globals[Previous].IsTentative and not Globals[I].IsTentative) or
         Globals[I].HasInitializer then
        FGlobalIndex.Put(Globals[I].Name, I);
    end;
end;

function TProgram.FindFunction(const AName: string): TFunction;
var
  I: LongInt;
begin
  I := FindFunctionIndex(AName);
  if I >= 0 then
    Exit(Functions[I]);
  Result := nil;
end;

function TProgram.FindFunctionIndex(const AName: string): LongInt;
begin
  if not FFunctionIndex.TryGet(AName, Result) or
     (Result < 0) or (Result >= Length(Functions)) then
    Result := -1;
end;

function TProgram.FindGlobal(const AName: string): TGlobal;
var
  I: LongInt;
begin
  I := FindGlobalIndex(AName);
  if I >= 0 then
    Exit(Globals[I]);
  Result := nil;
end;

function TProgram.FindGlobalIndex(const AName: string): LongInt;
begin
  if not FGlobalIndex.TryGet(AName, Result) or
     (Result < 0) or (Result >= Length(Globals)) then
    Result := -1;
end;

function MakeType(AKind: TCTypeKind; AUnsigned: Boolean;
  APointerDepth: LongInt): TCType;
begin
  Result.Kind := AKind;
  Result.IsUnsigned := AUnsigned;
  Result.IsConst := False;
  Result.IsVolatile := False;
  Result.IsPacked := False;
  Result.AlignmentOverride := 0;
  Result.SuppressUnusedWarning := False;
  Result.PreserveForLinker := False;
  Result.PointerDepth := APointerDepth;
  Result.ArrayLength := 0;
  Result.StructInfo := nil;
  SetLength(Result.EnumConstants, 0);
  Result.ReturnType := nil;
  Result.ParamTypes := nil;
  Result.ParamCount := 0;
  Result.IsVariadic := False;
  Result.ElementKind := ctVoid;
  Result.ElementUnsigned := False;
  Result.ElementConst := False;
  Result.ElementPointerDepth := 0;
  Result.ElementStructInfo := nil;
  Result.ElementRef := nil;
end;

function TokenKindName(AKind: TTokenKind): string;
begin
  case AKind of
    tkEOF: Result := 'end of file';
    tkIdentifier: Result := 'identifier';
    tkInteger: Result := 'integer';
    tkFloat: Result := 'floating literal';
    tkString: Result := 'string';
    tkLParen: Result := '''(''';
    tkRParen: Result := ''')''';
    tkLBrace: Result := '''{''';
    tkRBrace: Result := '''}''';
    tkLBracket: Result := '''[''';
    tkRBracket: Result := ''']''';
    tkSemicolon: Result := ''';''';
    tkComma: Result := ''',''';
    tkQuestion: Result := '''?''';
    tkColon: Result := ''':''';
    tkPlus: Result := '''+''';
    tkMinus: Result := '''-''';
    tkStar: Result := '''*''';
    tkSlash: Result := '''/''';
    tkPercent: Result := '''%''';
    tkAmp: Result := '''&''';
    tkPipe: Result := '''|''';
    tkCaret: Result := '''^''';
    tkTilde: Result := '''~''';
    tkBang: Result := '''!''';
    tkAssign: Result := '''=''';
    tkEqual: Result := '''==''';
    tkNotEqual: Result := '''!=''';
    tkLess: Result := '''<''';
    tkLessEqual: Result := '''<=''';
    tkGreater: Result := '''>''';
    tkGreaterEqual: Result := '''>=''';
    tkLogicalAnd: Result := '''&&''';
    tkLogicalOr: Result := '''||''';
    tkShiftLeft: Result := '''<<''';
    tkShiftRight: Result := '''>>''';
    tkIncrement: Result := '''++''';
    tkDecrement: Result := '''--''';
    tkArrow: Result := '''->''';
    tkDot: Result := '''.''';
    tkEllipsis: Result := '''...''';
  else
    Result := 'token';
  end;
end;

procedure RaiseCompileError(const APos: TSourcePos; const AMessage: string);
begin
  if APos.FileName <> '' then
    raise ERCCError.CreateFmt('%s:%d:%d: error: %s',
      [APos.FileName, APos.Line, APos.Column, AMessage])
  else
    raise ERCCError.Create('error: ' + AMessage);
end;

function TypesEqual(const A, B: TCType): Boolean;
var
  I: LongInt;
  AParams, BParams: PFunctionParameterList;
begin
  if A.Kind <> B.Kind then Exit(False);
  if A.IsUnsigned <> B.IsUnsigned then Exit(False);
  if A.PointerDepth <> B.PointerDepth then Exit(False);
  if A.Kind = ctArray then
  begin
    if A.ArrayLength <> B.ArrayLength then Exit(False);
    if A.ElementKind <> B.ElementKind then Exit(False);
    if A.ElementUnsigned <> B.ElementUnsigned then Exit(False);
    if A.ElementPointerDepth <> B.ElementPointerDepth then Exit(False);
    if A.ElementStructInfo <> B.ElementStructInfo then Exit(False);
    if (A.ElementRef <> nil) or (B.ElementRef <> nil) then
    begin
      if (A.ElementRef = nil) or (B.ElementRef = nil) then Exit(False);
      if not TypesEqual(PCType(A.ElementRef)^, PCType(B.ElementRef)^) then
        Exit(False);
    end;
  end;
  if (A.Kind in [ctStruct, ctUnion]) and
    (A.StructInfo <> B.StructInfo) then
  begin
    { Each translation unit parses its own copy of a header, so the same tagged
      type has a different record in every unit. Merged units must still see
      those as one type. }
    if (A.StructInfo = nil) or (B.StructInfo = nil) then Exit(False);
    if A.StructInfo^.Name = '' then Exit(False);
    if A.StructInfo^.Name <> B.StructInfo^.Name then Exit(False);
    if A.StructInfo^.IsUnion <> B.StructInfo^.IsUnion then Exit(False);
    if A.StructInfo^.Size <> B.StructInfo^.Size then Exit(False);
    if A.StructInfo^.Align <> B.StructInfo^.Align then Exit(False);
    if A.StructInfo^.IsPacked <> B.StructInfo^.IsPacked then Exit(False);
    if A.StructInfo^.ExplicitAlign <> B.StructInfo^.ExplicitAlign then Exit(False);
    if Length(A.StructInfo^.Members) <> Length(B.StructInfo^.Members) then
      Exit(False);
    for I := 0 to High(A.StructInfo^.Members) do
    begin
      if A.StructInfo^.Members[I].Name <> B.StructInfo^.Members[I].Name then
        Exit(False);
      if A.StructInfo^.Members[I].Offset <> B.StructInfo^.Members[I].Offset then
        Exit(False);
      if A.StructInfo^.Members[I].Width <> B.StructInfo^.Members[I].Width then
        Exit(False);
      if A.StructInfo^.Members[I].IsBitField <>
         B.StructInfo^.Members[I].IsBitField then Exit(False);
      if A.StructInfo^.Members[I].BitOffset <>
         B.StructInfo^.Members[I].BitOffset then Exit(False);
      if A.StructInfo^.Members[I].BitWidth <>
         B.StructInfo^.Members[I].BitWidth then Exit(False);
      if A.StructInfo^.Members[I].AlignmentOverride <>
         B.StructInfo^.Members[I].AlignmentOverride then Exit(False);
      if A.StructInfo^.Members[I].IsPacked <>
         B.StructInfo^.Members[I].IsPacked then Exit(False);
      if (A.StructInfo^.Members[I].CType = nil) <>
         (B.StructInfo^.Members[I].CType = nil) then Exit(False);
      if (A.StructInfo^.Members[I].CType <> nil) and
         (B.StructInfo^.Members[I].CType <> nil) then
      begin
        { Compare the member's immediate representation without descending into
          tagged aggregate definitions, which may be self-referential through
          pointers. The enclosing tag/layout checks above catch ABI conflicts. }
        if PCType(A.StructInfo^.Members[I].CType)^.Kind <>
           PCType(B.StructInfo^.Members[I].CType)^.Kind then Exit(False);
        if PCType(A.StructInfo^.Members[I].CType)^.PointerDepth <>
           PCType(B.StructInfo^.Members[I].CType)^.PointerDepth then Exit(False);
        if PCType(A.StructInfo^.Members[I].CType)^.IsUnsigned <>
           PCType(B.StructInfo^.Members[I].CType)^.IsUnsigned then Exit(False);
      end;
    end;
  end;
  if A.Kind = ctFunction then
  begin
    if (A.ReturnType = nil) <> (B.ReturnType = nil) then Exit(False);
    if (A.ParamTypes = nil) <> (B.ParamTypes = nil) then Exit(False);
    if A.ParamCount <> B.ParamCount then Exit(False);
    if A.IsVariadic <> B.IsVariadic then Exit(False);
    if (A.ReturnType <> nil) and
      not TypesEqual(PCType(A.ReturnType)^, PCType(B.ReturnType)^) then
      Exit(False);
    if A.ParamTypes <> nil then
    begin
      AParams := PFunctionParameterList(A.ParamTypes);
      BParams := PFunctionParameterList(B.ParamTypes);
      if Length(AParams^.Items) <> Length(BParams^.Items) then Exit(False);
      for I := 0 to High(AParams^.Items) do
        if not TypesEqual(AParams^.Items[I], BParams^.Items[I]) then
          Exit(False);
    end;
  end;
  Result := True;
end;

function ArrayElementType(const AType: TCType): TCType;
begin
  if AType.ElementRef <> nil then Exit(PCType(AType.ElementRef)^);
  Result := MakeType(AType.ElementKind, AType.ElementUnsigned,
    AType.ElementPointerDepth);
  Result.IsConst := AType.ElementConst;
  Result.StructInfo := AType.ElementStructInfo;
end;

function CTypeSize(const AType: TCType): Int64;
var
  ElementType: TCType;
begin
  if AType.PointerDepth > 0 then Exit(8);
  case AType.Kind of
    ctVoid: Result := 1;
    ctChar, ctBool: Result := 1;
    ctShort: Result := 2;
    ctInt: Result := 4;
    ctLong: Result := 8;
    ctLongLong: Result := 8;
    ctFloat: Result := 4;
    ctDouble: Result := 8;
    ctLongDouble: Result := ActiveLongDoubleSize;
    ctPointer: Result := 8;
    ctArray:
      begin
        if AType.ArrayLength <= 0 then Exit(0);
        ElementType := ArrayElementType(AType);
        Result := CTypeSize(ElementType) * AType.ArrayLength;
      end;
    ctStruct, ctUnion:
      if AType.StructInfo <> nil then Result := AType.StructInfo^.Size
      else Result := 0;
    ctEnum: Result := 4;
    ctFunction: Result := 0;
  else
    Result := 8;
  end;
end;

function CTypeAlign(const AType: TCType): LongInt;
var
  ElementType: TCType;
  NaturalAlign: LongInt;
begin
  if AType.PointerDepth > 0 then
    NaturalAlign := 8
  else
    case AType.Kind of
      ctVoid, ctChar, ctBool: NaturalAlign := 1;
      ctShort: NaturalAlign := 2;
      ctInt, ctFloat, ctEnum: NaturalAlign := 4;
      ctLong, ctLongLong, ctDouble, ctPointer: NaturalAlign := 8;
      ctLongDouble: NaturalAlign := ActiveLongDoubleAlignment;
      ctArray:
        begin
          ElementType := ArrayElementType(AType);
          NaturalAlign := CTypeAlign(ElementType);
        end;
      ctStruct, ctUnion:
        if AType.StructInfo <> nil then NaturalAlign := AType.StructInfo^.Align
        else NaturalAlign := 1;
      ctFunction: NaturalAlign := 1;
    else
      NaturalAlign := 8;
    end;

  if AType.IsPacked then NaturalAlign := 1;
  if AType.AlignmentOverride > NaturalAlign then
    NaturalAlign := AType.AlignmentOverride;
  Result := NaturalAlign;
end;

function IsArithmeticType(const AType: TCType): Boolean;
begin
  if AType.PointerDepth > 0 then Exit(False);
  Result := AType.Kind in [ctChar, ctShort, ctInt, ctLong, ctLongLong,
    ctBool, ctFloat, ctDouble, ctLongDouble, ctEnum];
end;

function IsIntegerType(const AType: TCType): Boolean;
begin
  if AType.PointerDepth > 0 then Exit(False);
  Result := AType.Kind in [ctChar, ctShort, ctInt, ctLong, ctLongLong,
    ctBool, ctEnum];
end;

function IsScalarType(const AType: TCType): Boolean;
begin
  Result := (AType.PointerDepth > 0) or IsArithmeticType(AType) or
    (AType.Kind = ctFunction) or (AType.Kind = ctPointer);
end;

function CStandardName(AStandard: TCStandard): string;
begin
  case AStandard of
    csC90: Result := 'c90';
    csC99: Result := 'c99';
    csC11: Result := 'c11';
    csC17: Result := 'c17';
    csC23: Result := 'c23';
    csGNU99: Result := 'gnu99';
    csGNU11: Result := 'gnu11';
    csGNU17: Result := 'gnu17';
    csGNU23: Result := 'gnu23';
    csRCC: Result := 'rcc';
  else
    Result := 'c17';
  end;
end;

function CStandardVersion(AStandard: TCStandard): string;
begin
  case AStandard of
    csC90: Result := '';
    csC99, csGNU99: Result := '199901L';
    csC11, csGNU11: Result := '201112L';
    csC17, csGNU17, csRCC: Result := '201710L';
    csC23, csGNU23: Result := '202311L';
  else
    Result := '201710L';
  end;
end;

function CStandardRevision(AStandard: TCStandard): LongInt;
begin
  case AStandard of
    csC90: Result := 1990;
    csC99, csGNU99: Result := 1999;
    csC11, csGNU11: Result := 2011;
    csC17, csGNU17: Result := 2017;
    csC23, csGNU23: Result := 2023;
    csRCC: Result := 2017;
  else
    Result := 2017;
  end;
end;

function CStandardAtLeast(AStandard: TCStandard; ARevision: LongInt): Boolean;
begin
  Result := CStandardRevision(AStandard) >= ARevision;
end;

function IsGNUStandard(AStandard: TCStandard): Boolean;
begin
  Result := AStandard in [csGNU99, csGNU11, csGNU17, csGNU23, csRCC];
end;

end.
