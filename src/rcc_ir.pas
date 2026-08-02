unit rcc_ir;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types;

type
  TIRTypeKind = (
    irtVoid,
    irtI1,
    irtI8,
    irtI16,
    irtI32,
    irtI64,
    irtF32,
    irtF64,
    irtF80,
    irtPointer,
    irtAggregate
  );

  TIRType = record
    Kind: TIRTypeKind;
    Bits: LongInt;
    Signed: Boolean;
    AddressSpace: LongInt;
    AggregateSize: QWord;
    AggregateAlign: LongInt;
  end;

  TIROpcode = (
    iroNop,
    iroOpaque,
    iroConstant,
    iroUndef,
    iroParameter,
    iroAlloca,
    iroLoad,
    iroStore,
    iroAddressOfGlobal,
    iroAddressOfFunction,
    iroGetElementPtr,
    iroAdd,
    iroSub,
    iroMul,
    iroSDiv,
    iroUDiv,
    iroSRem,
    iroURem,
    iroShl,
    iroAShr,
    iroLShr,
    iroAnd,
    iroOr,
    iroXor,
    iroNeg,
    iroNot,
    iroLogicalNot,
    iroICmpEQ,
    iroICmpNE,
    iroICmpSLT,
    iroICmpSLE,
    iroICmpSGT,
    iroICmpSGE,
    iroICmpULT,
    iroICmpULE,
    iroICmpUGT,
    iroICmpUGE,
    iroFAdd,
    iroFSub,
    iroFMul,
    iroFDiv,
    iroFNeg,
    iroFCmpOEQ,
    iroFCmpONE,
    iroFCmpOLT,
    iroFCmpOLE,
    iroFCmpOGT,
    iroFCmpOGE,
    iroTrunc,
    iroZExt,
    iroSExt,
    iroBitCast,
    iroPtrToInt,
    iroIntToPtr,
    iroSIToFP,
    iroUIToFP,
    iroFPToSI,
    iroFPToUI,
    iroFPExt,
    iroFPTrunc,
    iroPhi,
    iroSelect,
    iroCopy,
    iroCall,
    iroIntrinsic,
    iroBranch,
    iroCondBranch,
    iroSwitch,
    iroReturn,
    iroUnreachable
  );

  TIRLinkage = (
    irlInternal,
    irlExternal,
    irlWeak,
    irlCommon
  );

  TIRVisibility = (
    irvDefault,
    irvHidden,
    irvProtected
  );

  TIRValue = LongInt;
  TIRBlockID = LongInt;

  TIRValueArray = array of TIRValue;
  TIRBlockIDArray = array of TIRBlockID;

  TIRSwitchCase = record
    Value: Int64;
    TargetBlock: TIRBlockID;
  end;
  TIRSwitchCaseArray = array of TIRSwitchCase;

  TIRInstruction = class
  public
    Opcode: TIROpcode;
    ResultValue: TIRValue;
    ResultType: TIRType;
    Operands: TIRValueArray;
    Immediate: Int64;
    UnsignedImmediate: QWord;
    Symbol: string;
    Text: string;
    TrueBlock: TIRBlockID;
    FalseBlock: TIRBlockID;
    DefaultBlock: TIRBlockID;
    SwitchCases: TIRSwitchCaseArray;
    Position: TSourcePos;
    VolatileAccess: Boolean;
    Alignment: LongInt;
    constructor Create(AOpcode: TIROpcode; const APosition: TSourcePos);
    procedure AddOperand(AValue: TIRValue);
    procedure AddSwitchCase(AValue: Int64; ATarget: TIRBlockID);
    function HasResult: Boolean;
    function IsTerminator: Boolean;
    function HasSideEffects: Boolean;
    function IsCommutative: Boolean;
    function Clone: TIRInstruction;
  end;
  TIRInstructionArray = array of TIRInstruction;

  TIRBasicBlock = class
  public
    ID: TIRBlockID;
    Name: string;
    Instructions: TIRInstructionArray;
    Predecessors: TIRBlockIDArray;
    Successors: TIRBlockIDArray;
    Reachable: Boolean;
    ReversePostOrder: LongInt;
    ImmediateDominator: TIRBlockID;
    LoopDepth: LongInt;
    constructor Create(AID: TIRBlockID; const AName: string);
    destructor Destroy; override;
    procedure AddInstruction(AInstruction: TIRInstruction);
    procedure InsertInstruction(AIndex: LongInt; AInstruction: TIRInstruction);
    procedure DeleteInstruction(AIndex: LongInt);
    procedure AddPredecessor(AID: TIRBlockID);
    procedure AddSuccessor(AID: TIRBlockID);
    procedure ClearEdges;
    function Terminator: TIRInstruction;
    function IsTerminated: Boolean;
  end;
  TIRBasicBlockArray = array of TIRBasicBlock;

  TIRParameter = record
    Name: string;
    Value: TIRValue;
    ValueType: TIRType;
  end;
  TIRParameterArray = array of TIRParameter;

  TIRValueDefinition = record
    ValueType: TIRType;
    DefiningBlock: TIRBlockID;
    DefiningInstruction: LongInt;
    Name: string;
    IsParameter: Boolean;
  end;
  TIRValueDefinitionArray = array of TIRValueDefinition;

  TIRFunction = class
  private
    FNextValue: TIRValue;
    FNextBlock: TIRBlockID;
  public
    Name: string;
    ReturnType: TIRType;
    Parameters: TIRParameterArray;
    Blocks: TIRBasicBlockArray;
    ValueDefinitions: TIRValueDefinitionArray;
    Linkage: TIRLinkage;
    Visibility: TIRVisibility;
    Variadic: Boolean;
    EntryBlock: TIRBlockID;
    Position: TSourcePos;
    constructor Create(const AName: string; const AReturnType: TIRType);
    destructor Destroy; override;
    function NewValue(const AType: TIRType; const AName: string = ''): TIRValue;
    procedure DefineValue(AValue: TIRValue; ABlock: TIRBlockID;
      AInstruction: LongInt; AParameter: Boolean = False);
    function AddParameter(const AName: string;
      const AType: TIRType): TIRValue;
    function AddBlock(const AName: string = ''): TIRBasicBlock;
    function BlockByID(AID: TIRBlockID): TIRBasicBlock;
    function ValueType(AValue: TIRValue): TIRType;
    function ValueName(AValue: TIRValue): string;
    function ValueCount: LongInt;
    procedure RebuildValueDefinitions;
  end;
  TIRFunctionArray = array of TIRFunction;

  TIRGlobal = class
  public
    Name: string;
    ValueType: TIRType;
    Linkage: TIRLinkage;
    Visibility: TIRVisibility;
    ConstantData: array of Byte;
    ZeroFillSize: QWord;
    Alignment: LongInt;
    IsConstant: Boolean;
    IsThreadLocal: Boolean;
    Position: TSourcePos;
  end;
  TIRGlobalArray = array of TIRGlobal;

  TIRModule = class
  public
    TargetTriple: string;
    SourceFiles: rcc_types.TStringArray;
    Functions: TIRFunctionArray;
    Globals: TIRGlobalArray;
    HasOpaqueOperations: Boolean;
    constructor Create(const ATargetTriple: string);
    destructor Destroy; override;
    procedure AddSourceFile(const AFileName: string);
    procedure AddFunction(AFunction: TIRFunction);
    procedure AddGlobal(AGlobal: TIRGlobal);
    function FindFunction(const AName: string): TIRFunction;
    function FindGlobal(const AName: string): TIRGlobal;
  end;

  TIRBuilder = class
  private
    FFunction: TIRFunction;
    FBlock: TIRBasicBlock;
  public
    constructor Create(AFunction: TIRFunction);
    procedure PositionAtEnd(ABlock: TIRBasicBlock);
    function CurrentBlock: TIRBasicBlock;
    function Emit(AOpcode: TIROpcode; const AType: TIRType;
      const APosition: TSourcePos; const AName: string = ''): TIRInstruction;
    function EmitConstant(AValue: Int64; const AType: TIRType;
      const APosition: TSourcePos): TIRValue;
    function EmitUnary(AOpcode: TIROpcode; AOperand: TIRValue;
      const AType: TIRType; const APosition: TSourcePos): TIRValue;
    function EmitBinary(AOpcode: TIROpcode; ALeft, ARight: TIRValue;
      const AType: TIRType; const APosition: TSourcePos): TIRValue;
    function EmitLoad(APointer: TIRValue; const AType: TIRType;
      AAlignment: LongInt; AVolatile: Boolean;
      const APosition: TSourcePos): TIRValue;
    procedure EmitStore(AValue, APointer: TIRValue; AAlignment: LongInt;
      AVolatile: Boolean; const APosition: TSourcePos);
    function EmitCall(const ASymbol: string; const AArguments: TIRValueArray;
      const AType: TIRType; const APosition: TSourcePos): TIRValue;
    procedure EmitBranch(ATarget: TIRBlockID; const APosition: TSourcePos);
    procedure EmitCondBranch(ACondition: TIRValue;
      ATrue, AFalse: TIRBlockID; const APosition: TSourcePos);
    procedure EmitReturn(AValue: TIRValue; const APosition: TSourcePos);
    procedure EmitVoidReturn(const APosition: TSourcePos);
    procedure EmitUnreachable(const APosition: TSourcePos);
  end;

function IRType(AKind: TIRTypeKind; ABits: LongInt = 0;
  ASigned: Boolean = False): TIRType;
function IRVoidType: TIRType;
function IRBoolType: TIRType;
function IRPointerType: TIRType;
function CTypeToIRType(const AType: TCType): TIRType;
function IRTypeName(const AType: TIRType): string;
function IROpcodeName(AOpcode: TIROpcode): string;
function IRLinkageName(ALinkage: TIRLinkage): string;
function IRVisibilityName(AVisibility: TIRVisibility): string;
function IRValueText(AValue: TIRValue): string;
function DumpIRInstruction(AFunction: TIRFunction;
  AInstruction: TIRInstruction): string;
function DumpIRFunction(AFunction: TIRFunction): string;
function DumpIRModule(AModule: TIRModule): string;

implementation

procedure AppendString(var AValues: rcc_types.TStringArray; const AValue: string);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

procedure AppendValue(var AValues: TIRValueArray; AValue: TIRValue);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

procedure AppendBlockID(var AValues: TIRBlockIDArray; AValue: TIRBlockID);
var
  I, N: LongInt;
begin
  for I := 0 to High(AValues) do
    if AValues[I] = AValue then Exit;
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

function IRType(AKind: TIRTypeKind; ABits: LongInt;
  ASigned: Boolean): TIRType;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Kind := AKind;
  Result.Bits := ABits;
  Result.Signed := ASigned;
  Result.AddressSpace := 0;
  Result.AggregateAlign := 1;
end;

function IRVoidType: TIRType;
begin
  Result := IRType(irtVoid, 0, False);
end;

function IRBoolType: TIRType;
begin
  Result := IRType(irtI1, 1, False);
end;

function IRPointerType: TIRType;
begin
  Result := IRType(irtPointer, 64, False);
end;

function CTypeToIRType(const AType: TCType): TIRType;
var
  Size: Int64;
begin
  if (AType.PointerDepth > 0) or (AType.Kind in [ctPointer, ctFunction]) then
    Exit(IRPointerType);
  case AType.Kind of
    ctVoid: Result := IRVoidType;
    ctBool: Result := IRBoolType;
    ctChar: Result := IRType(irtI8, 8, not AType.IsUnsigned);
    ctShort: Result := IRType(irtI16, 16, not AType.IsUnsigned);
    ctInt, ctEnum: Result := IRType(irtI32, 32, not AType.IsUnsigned);
    ctLong, ctLongLong: Result := IRType(irtI64, 64, not AType.IsUnsigned);
    ctFloat: Result := IRType(irtF32, 32, True);
    ctDouble: Result := IRType(irtF64, 64, True);
    ctLongDouble: Result := IRType(irtF80, 80, True);
    ctArray, ctStruct, ctUnion:
      begin
        Result := IRType(irtAggregate, 0, False);
        Size := CTypeSize(AType);
        if Size < 0 then Size := 0;
        Result.AggregateSize := QWord(Size);
        Result.AggregateAlign := CTypeAlign(AType);
      end;
  else
    Result := IRType(irtI64, 64, True);
  end;
end;

function IRTypeName(const AType: TIRType): string;
begin
  case AType.Kind of
    irtVoid: Result := 'void';
    irtI1: Result := 'i1';
    irtI8: Result := 'i8';
    irtI16: Result := 'i16';
    irtI32: Result := 'i32';
    irtI64: Result := 'i64';
    irtF32: Result := 'f32';
    irtF64: Result := 'f64';
    irtF80: Result := 'f80';
    irtPointer: Result := 'ptr';
    irtAggregate: Result := Format('agg<%d,%d>',
      [AType.AggregateSize, AType.AggregateAlign]);
  else
    Result := 'invalid';
  end;
end;

function IROpcodeName(AOpcode: TIROpcode): string;
begin
  case AOpcode of
    iroNop: Result := 'nop';
    iroOpaque: Result := 'opaque';
    iroConstant: Result := 'const';
    iroUndef: Result := 'undef';
    iroParameter: Result := 'param';
    iroAlloca: Result := 'alloca';
    iroLoad: Result := 'load';
    iroStore: Result := 'store';
    iroAddressOfGlobal: Result := 'global.addr';
    iroAddressOfFunction: Result := 'function.addr';
    iroGetElementPtr: Result := 'gep';
    iroAdd: Result := 'add';
    iroSub: Result := 'sub';
    iroMul: Result := 'mul';
    iroSDiv: Result := 'sdiv';
    iroUDiv: Result := 'udiv';
    iroSRem: Result := 'srem';
    iroURem: Result := 'urem';
    iroShl: Result := 'shl';
    iroAShr: Result := 'ashr';
    iroLShr: Result := 'lshr';
    iroAnd: Result := 'and';
    iroOr: Result := 'or';
    iroXor: Result := 'xor';
    iroNeg: Result := 'neg';
    iroNot: Result := 'not';
    iroLogicalNot: Result := 'lnot';
    iroICmpEQ: Result := 'icmp.eq';
    iroICmpNE: Result := 'icmp.ne';
    iroICmpSLT: Result := 'icmp.slt';
    iroICmpSLE: Result := 'icmp.sle';
    iroICmpSGT: Result := 'icmp.sgt';
    iroICmpSGE: Result := 'icmp.sge';
    iroICmpULT: Result := 'icmp.ult';
    iroICmpULE: Result := 'icmp.ule';
    iroICmpUGT: Result := 'icmp.ugt';
    iroICmpUGE: Result := 'icmp.uge';
    iroFAdd: Result := 'fadd';
    iroFSub: Result := 'fsub';
    iroFMul: Result := 'fmul';
    iroFDiv: Result := 'fdiv';
    iroFNeg: Result := 'fneg';
    iroFCmpOEQ: Result := 'fcmp.oeq';
    iroFCmpONE: Result := 'fcmp.one';
    iroFCmpOLT: Result := 'fcmp.olt';
    iroFCmpOLE: Result := 'fcmp.ole';
    iroFCmpOGT: Result := 'fcmp.ogt';
    iroFCmpOGE: Result := 'fcmp.oge';
    iroTrunc: Result := 'trunc';
    iroZExt: Result := 'zext';
    iroSExt: Result := 'sext';
    iroBitCast: Result := 'bitcast';
    iroPtrToInt: Result := 'ptrtoint';
    iroIntToPtr: Result := 'inttoptr';
    iroSIToFP: Result := 'sitofp';
    iroUIToFP: Result := 'uitofp';
    iroFPToSI: Result := 'fptosi';
    iroFPToUI: Result := 'fptoui';
    iroFPExt: Result := 'fpext';
    iroFPTrunc: Result := 'fptrunc';
    iroPhi: Result := 'phi';
    iroSelect: Result := 'select';
    iroCopy: Result := 'copy';
    iroCall: Result := 'call';
    iroIntrinsic: Result := 'intrinsic';
    iroBranch: Result := 'br';
    iroCondBranch: Result := 'cbr';
    iroSwitch: Result := 'switch';
    iroReturn: Result := 'ret';
    iroUnreachable: Result := 'unreachable';
  else
    Result := 'invalid';
  end;
end;

function IRLinkageName(ALinkage: TIRLinkage): string;
begin
  case ALinkage of
    irlInternal: Result := 'internal';
    irlExternal: Result := 'external';
    irlWeak: Result := 'weak';
    irlCommon: Result := 'common';
  else
    Result := 'unknown';
  end;
end;

function IRVisibilityName(AVisibility: TIRVisibility): string;
begin
  case AVisibility of
    irvDefault: Result := 'default';
    irvHidden: Result := 'hidden';
    irvProtected: Result := 'protected';
  else
    Result := 'unknown';
  end;
end;

function IRValueText(AValue: TIRValue): string;
begin
  if AValue < 0 then Result := 'void'
  else Result := '%' + IntToStr(AValue);
end;

constructor TIRInstruction.Create(AOpcode: TIROpcode;
  const APosition: TSourcePos);
begin
  inherited Create;
  Opcode := AOpcode;
  ResultValue := -1;
  ResultType := IRVoidType;
  SetLength(Operands, 0);
  SetLength(SwitchCases, 0);
  Immediate := 0;
  UnsignedImmediate := 0;
  Symbol := '';
  Text := '';
  TrueBlock := -1;
  FalseBlock := -1;
  DefaultBlock := -1;
  Position := APosition;
  VolatileAccess := False;
  Alignment := 0;
end;

procedure TIRInstruction.AddOperand(AValue: TIRValue);
begin
  AppendValue(Operands, AValue);
end;

procedure TIRInstruction.AddSwitchCase(AValue: Int64; ATarget: TIRBlockID);
var
  N: LongInt;
begin
  N := Length(SwitchCases);
  SetLength(SwitchCases, N + 1);
  SwitchCases[N].Value := AValue;
  SwitchCases[N].TargetBlock := ATarget;
end;

function TIRInstruction.HasResult: Boolean;
begin
  Result := ResultValue >= 0;
end;

function TIRInstruction.IsTerminator: Boolean;
begin
  Result := Opcode in [iroBranch, iroCondBranch, iroSwitch,
    iroReturn, iroUnreachable];
end;

function TIRInstruction.HasSideEffects: Boolean;
begin
  Result := Opcode in [iroOpaque, iroStore, iroCall, iroIntrinsic,
    iroBranch, iroCondBranch, iroSwitch, iroReturn, iroUnreachable];
  if (Opcode = iroLoad) and VolatileAccess then Result := True;
end;

function TIRInstruction.IsCommutative: Boolean;
begin
  Result := Opcode in [iroAdd, iroMul, iroFAdd, iroFMul,
    iroAnd, iroOr, iroXor, iroICmpEQ, iroICmpNE, iroFCmpOEQ, iroFCmpONE];
end;

function TIRInstruction.Clone: TIRInstruction;
var
  I: LongInt;
begin
  Result := TIRInstruction.Create(Opcode, Position);
  Result.ResultValue := ResultValue;
  Result.ResultType := ResultType;
  Result.Immediate := Immediate;
  Result.UnsignedImmediate := UnsignedImmediate;
  Result.Symbol := Symbol;
  Result.Text := Text;
  Result.TrueBlock := TrueBlock;
  Result.FalseBlock := FalseBlock;
  Result.DefaultBlock := DefaultBlock;
  Result.VolatileAccess := VolatileAccess;
  Result.Alignment := Alignment;
  SetLength(Result.Operands, Length(Operands));
  for I := 0 to High(Operands) do Result.Operands[I] := Operands[I];
  SetLength(Result.SwitchCases, Length(SwitchCases));
  for I := 0 to High(SwitchCases) do
    Result.SwitchCases[I] := SwitchCases[I];
end;

constructor TIRBasicBlock.Create(AID: TIRBlockID; const AName: string);
begin
  inherited Create;
  ID := AID;
  if AName = '' then Name := 'bb' + IntToStr(AID) else Name := AName;
  SetLength(Instructions, 0);
  SetLength(Predecessors, 0);
  SetLength(Successors, 0);
  Reachable := False;
  ReversePostOrder := -1;
  ImmediateDominator := -1;
  LoopDepth := 0;
end;

destructor TIRBasicBlock.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(Instructions) do Instructions[I].Free;
  inherited Destroy;
end;

procedure TIRBasicBlock.AddInstruction(AInstruction: TIRInstruction);
var
  N: LongInt;
begin
  if AInstruction = nil then
    raise ERCCError.Create('internal error: nil IR instruction');
  if IsTerminated then
    raise ERCCError.Create('internal error: instruction after IR terminator');
  N := Length(Instructions);
  SetLength(Instructions, N + 1);
  Instructions[N] := AInstruction;
end;

procedure TIRBasicBlock.InsertInstruction(AIndex: LongInt;
  AInstruction: TIRInstruction);
var
  I, N: LongInt;
begin
  if (AIndex < 0) or (AIndex > Length(Instructions)) then
    raise ERCCError.Create('internal error: invalid IR insertion index');
  N := Length(Instructions);
  SetLength(Instructions, N + 1);
  for I := N downto AIndex + 1 do Instructions[I] := Instructions[I - 1];
  Instructions[AIndex] := AInstruction;
end;

procedure TIRBasicBlock.DeleteInstruction(AIndex: LongInt);
var
  I, N: LongInt;
begin
  N := Length(Instructions);
  if (AIndex < 0) or (AIndex >= N) then
    raise ERCCError.Create('internal error: invalid IR deletion index');
  Instructions[AIndex].Free;
  for I := AIndex to N - 2 do Instructions[I] := Instructions[I + 1];
  SetLength(Instructions, N - 1);
end;

procedure TIRBasicBlock.AddPredecessor(AID: TIRBlockID);
begin
  AppendBlockID(Predecessors, AID);
end;

procedure TIRBasicBlock.AddSuccessor(AID: TIRBlockID);
begin
  AppendBlockID(Successors, AID);
end;

procedure TIRBasicBlock.ClearEdges;
begin
  SetLength(Predecessors, 0);
  SetLength(Successors, 0);
end;

function TIRBasicBlock.Terminator: TIRInstruction;
begin
  if (Length(Instructions) > 0) and
     Instructions[High(Instructions)].IsTerminator then
    Result := Instructions[High(Instructions)]
  else
    Result := nil;
end;

function TIRBasicBlock.IsTerminated: Boolean;
begin
  Result := Terminator <> nil;
end;

constructor TIRFunction.Create(const AName: string;
  const AReturnType: TIRType);
begin
  inherited Create;
  Name := AName;
  ReturnType := AReturnType;
  SetLength(Parameters, 0);
  SetLength(Blocks, 0);
  SetLength(ValueDefinitions, 0);
  Linkage := irlExternal;
  Visibility := irvDefault;
  Variadic := False;
  EntryBlock := -1;
  FNextValue := 0;
  FNextBlock := 0;
end;

destructor TIRFunction.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(Blocks) do Blocks[I].Free;
  inherited Destroy;
end;

function TIRFunction.NewValue(const AType: TIRType;
  const AName: string): TIRValue;
var
  N: LongInt;
begin
  Result := FNextValue;
  Inc(FNextValue);
  N := Length(ValueDefinitions);
  SetLength(ValueDefinitions, N + 1);
  ValueDefinitions[N].ValueType := AType;
  ValueDefinitions[N].DefiningBlock := -1;
  ValueDefinitions[N].DefiningInstruction := -1;
  ValueDefinitions[N].Name := AName;
  ValueDefinitions[N].IsParameter := False;
end;

procedure TIRFunction.DefineValue(AValue: TIRValue; ABlock: TIRBlockID;
  AInstruction: LongInt; AParameter: Boolean);
begin
  if (AValue < 0) or (AValue > High(ValueDefinitions)) then
    raise ERCCError.Create('internal error: invalid IR value definition');
  ValueDefinitions[AValue].DefiningBlock := ABlock;
  ValueDefinitions[AValue].DefiningInstruction := AInstruction;
  ValueDefinitions[AValue].IsParameter := AParameter;
end;

function TIRFunction.AddParameter(const AName: string;
  const AType: TIRType): TIRValue;
var
  N: LongInt;
begin
  Result := NewValue(AType, AName);
  N := Length(Parameters);
  SetLength(Parameters, N + 1);
  Parameters[N].Name := AName;
  Parameters[N].Value := Result;
  Parameters[N].ValueType := AType;
  DefineValue(Result, -1, N, True);
end;

function TIRFunction.AddBlock(const AName: string): TIRBasicBlock;
var
  N: LongInt;
begin
  Result := TIRBasicBlock.Create(FNextBlock, AName);
  Inc(FNextBlock);
  N := Length(Blocks);
  SetLength(Blocks, N + 1);
  Blocks[N] := Result;
  if EntryBlock < 0 then EntryBlock := Result.ID;
end;

function TIRFunction.BlockByID(AID: TIRBlockID): TIRBasicBlock;
var
  I: LongInt;
begin
  for I := 0 to High(Blocks) do
    if Blocks[I].ID = AID then Exit(Blocks[I]);
  Result := nil;
end;

function TIRFunction.ValueType(AValue: TIRValue): TIRType;
begin
  if (AValue < 0) or (AValue > High(ValueDefinitions)) then
    raise ERCCError.Create('internal error: invalid IR value lookup');
  Result := ValueDefinitions[AValue].ValueType;
end;

function TIRFunction.ValueName(AValue: TIRValue): string;
begin
  if (AValue < 0) or (AValue > High(ValueDefinitions)) then Exit('');
  Result := ValueDefinitions[AValue].Name;
end;

function TIRFunction.ValueCount: LongInt;
begin
  Result := Length(ValueDefinitions);
end;

procedure TIRFunction.RebuildValueDefinitions;
var
  I, J, V: LongInt;
begin
  for V := 0 to High(ValueDefinitions) do
    if not ValueDefinitions[V].IsParameter then
    begin
      ValueDefinitions[V].DefiningBlock := -1;
      ValueDefinitions[V].DefiningInstruction := -1;
    end;
  for I := 0 to High(Blocks) do
    for J := 0 to High(Blocks[I].Instructions) do
      if Blocks[I].Instructions[J].HasResult then
      begin
        V := Blocks[I].Instructions[J].ResultValue;
        if (V < 0) or (V > High(ValueDefinitions)) then
          raise ERCCError.Create(
            'internal error: IR instruction result outside value table');
        ValueDefinitions[V].DefiningBlock := Blocks[I].ID;
        ValueDefinitions[V].DefiningInstruction := J;
        ValueDefinitions[V].IsParameter := False;
      end;
end;

constructor TIRModule.Create(const ATargetTriple: string);
begin
  inherited Create;
  TargetTriple := ATargetTriple;
  SetLength(SourceFiles, 0);
  SetLength(Functions, 0);
  SetLength(Globals, 0);
  HasOpaqueOperations := False;
end;

destructor TIRModule.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(Functions) do Functions[I].Free;
  for I := 0 to High(Globals) do Globals[I].Free;
  inherited Destroy;
end;

procedure TIRModule.AddSourceFile(const AFileName: string);
var
  I: LongInt;
begin
  for I := 0 to High(SourceFiles) do
    if SourceFiles[I] = AFileName then Exit;
  AppendString(SourceFiles, AFileName);
end;

procedure TIRModule.AddFunction(AFunction: TIRFunction);
var
  N: LongInt;
begin
  if AFunction = nil then
    raise ERCCError.Create('internal error: nil IR function');
  if FindFunction(AFunction.Name) <> nil then
    raise ERCCError.Create('internal error: duplicate IR function ''' +
      AFunction.Name + '''');
  N := Length(Functions);
  SetLength(Functions, N + 1);
  Functions[N] := AFunction;
end;

procedure TIRModule.AddGlobal(AGlobal: TIRGlobal);
var
  N: LongInt;
begin
  if AGlobal = nil then
    raise ERCCError.Create('internal error: nil IR global');
  if FindGlobal(AGlobal.Name) <> nil then
    raise ERCCError.Create('internal error: duplicate IR global ''' +
      AGlobal.Name + '''');
  N := Length(Globals);
  SetLength(Globals, N + 1);
  Globals[N] := AGlobal;
end;

function TIRModule.FindFunction(const AName: string): TIRFunction;
var
  I: LongInt;
begin
  for I := 0 to High(Functions) do
    if Functions[I].Name = AName then Exit(Functions[I]);
  Result := nil;
end;

function TIRModule.FindGlobal(const AName: string): TIRGlobal;
var
  I: LongInt;
begin
  for I := 0 to High(Globals) do
    if Globals[I].Name = AName then Exit(Globals[I]);
  Result := nil;
end;

constructor TIRBuilder.Create(AFunction: TIRFunction);
begin
  inherited Create;
  if AFunction = nil then
    raise ERCCError.Create('internal error: nil IR builder function');
  FFunction := AFunction;
  FBlock := nil;
end;

procedure TIRBuilder.PositionAtEnd(ABlock: TIRBasicBlock);
begin
  if ABlock = nil then
    raise ERCCError.Create('internal error: nil IR insertion block');
  FBlock := ABlock;
end;

function TIRBuilder.CurrentBlock: TIRBasicBlock;
begin
  Result := FBlock;
end;

function TIRBuilder.Emit(AOpcode: TIROpcode; const AType: TIRType;
  const APosition: TSourcePos; const AName: string): TIRInstruction;
var
  Index: LongInt;
begin
  if FBlock = nil then
    raise ERCCError.Create('internal error: IR builder has no insertion block');
  Result := TIRInstruction.Create(AOpcode, APosition);
  Result.ResultType := AType;
  if AType.Kind <> irtVoid then
    Result.ResultValue := FFunction.NewValue(AType, AName);
  Index := Length(FBlock.Instructions);
  FBlock.AddInstruction(Result);
  if Result.ResultValue >= 0 then
    FFunction.DefineValue(Result.ResultValue, FBlock.ID, Index);
end;

function TIRBuilder.EmitConstant(AValue: Int64; const AType: TIRType;
  const APosition: TSourcePos): TIRValue;
var
  I: TIRInstruction;
begin
  I := Emit(iroConstant, AType, APosition);
  I.Immediate := AValue;
  Result := I.ResultValue;
end;

function TIRBuilder.EmitUnary(AOpcode: TIROpcode; AOperand: TIRValue;
  const AType: TIRType; const APosition: TSourcePos): TIRValue;
var
  I: TIRInstruction;
begin
  I := Emit(AOpcode, AType, APosition);
  I.AddOperand(AOperand);
  Result := I.ResultValue;
end;

function TIRBuilder.EmitBinary(AOpcode: TIROpcode; ALeft, ARight: TIRValue;
  const AType: TIRType; const APosition: TSourcePos): TIRValue;
var
  I: TIRInstruction;
begin
  I := Emit(AOpcode, AType, APosition);
  I.AddOperand(ALeft);
  I.AddOperand(ARight);
  Result := I.ResultValue;
end;

function TIRBuilder.EmitLoad(APointer: TIRValue; const AType: TIRType;
  AAlignment: LongInt; AVolatile: Boolean;
  const APosition: TSourcePos): TIRValue;
var
  I: TIRInstruction;
begin
  I := Emit(iroLoad, AType, APosition);
  I.AddOperand(APointer);
  I.Alignment := AAlignment;
  I.VolatileAccess := AVolatile;
  Result := I.ResultValue;
end;

procedure TIRBuilder.EmitStore(AValue, APointer: TIRValue;
  AAlignment: LongInt; AVolatile: Boolean; const APosition: TSourcePos);
var
  I: TIRInstruction;
begin
  I := Emit(iroStore, IRVoidType, APosition);
  I.AddOperand(AValue);
  I.AddOperand(APointer);
  I.Alignment := AAlignment;
  I.VolatileAccess := AVolatile;
end;

function TIRBuilder.EmitCall(const ASymbol: string;
  const AArguments: TIRValueArray; const AType: TIRType;
  const APosition: TSourcePos): TIRValue;
var
  I: TIRInstruction;
  N: LongInt;
begin
  I := Emit(iroCall, AType, APosition);
  I.Symbol := ASymbol;
  for N := 0 to High(AArguments) do I.AddOperand(AArguments[N]);
  Result := I.ResultValue;
end;

procedure TIRBuilder.EmitBranch(ATarget: TIRBlockID;
  const APosition: TSourcePos);
var
  I: TIRInstruction;
begin
  I := Emit(iroBranch, IRVoidType, APosition);
  I.TrueBlock := ATarget;
end;

procedure TIRBuilder.EmitCondBranch(ACondition: TIRValue;
  ATrue, AFalse: TIRBlockID; const APosition: TSourcePos);
var
  I: TIRInstruction;
begin
  I := Emit(iroCondBranch, IRVoidType, APosition);
  I.AddOperand(ACondition);
  I.TrueBlock := ATrue;
  I.FalseBlock := AFalse;
end;

procedure TIRBuilder.EmitReturn(AValue: TIRValue;
  const APosition: TSourcePos);
var
  I: TIRInstruction;
begin
  I := Emit(iroReturn, IRVoidType, APosition);
  I.AddOperand(AValue);
end;

procedure TIRBuilder.EmitVoidReturn(const APosition: TSourcePos);
begin
  Emit(iroReturn, IRVoidType, APosition);
end;

procedure TIRBuilder.EmitUnreachable(const APosition: TSourcePos);
begin
  Emit(iroUnreachable, IRVoidType, APosition);
end;

function DumpIRInstruction(AFunction: TIRFunction;
  AInstruction: TIRInstruction): string;
var
  I: LongInt;
  Prefix, Ops: string;
begin
  Prefix := '';
  if AInstruction.HasResult then
    Prefix := IRValueText(AInstruction.ResultValue) + ' = ';
  Ops := '';
  for I := 0 to High(AInstruction.Operands) do
  begin
    if Ops <> '' then Ops := Ops + ', ';
    Ops := Ops + IRValueText(AInstruction.Operands[I]);
  end;
  Result := Prefix + IROpcodeName(AInstruction.Opcode);
  case AInstruction.Opcode of
    iroConstant: Result := Result + ' ' +
      IRTypeName(AInstruction.ResultType) + ' ' +
      IntToStr(AInstruction.Immediate);
    iroAddressOfGlobal, iroAddressOfFunction, iroCall, iroIntrinsic:
      begin
        if AInstruction.Symbol <> '' then Result := Result + ' @' +
          AInstruction.Symbol;
        if Ops <> '' then Result := Result + '(' + Ops + ')';
      end;
    iroBranch:
      Result := Result + ' bb' + IntToStr(AInstruction.TrueBlock);
    iroCondBranch:
      Result := Result + ' ' + Ops + ', bb' +
        IntToStr(AInstruction.TrueBlock) + ', bb' +
        IntToStr(AInstruction.FalseBlock);
    iroSwitch:
      begin
        Result := Result + ' ' + Ops + ', default bb' +
          IntToStr(AInstruction.DefaultBlock);
        for I := 0 to High(AInstruction.SwitchCases) do
          Result := Result + ' [' + IntToStr(AInstruction.SwitchCases[I].Value) +
            ':bb' + IntToStr(AInstruction.SwitchCases[I].TargetBlock) + ']';
      end;
    iroReturn:
      if Ops <> '' then Result := Result + ' ' + Ops;
    iroOpaque:
      Result := Result + ' "' + StringReplace(AInstruction.Text, '"',
        '\"', [rfReplaceAll]) + '"';
  else
    begin
      if AInstruction.HasResult then
        Result := Result + ' ' + IRTypeName(AInstruction.ResultType);
      if Ops <> '' then Result := Result + ' ' + Ops;
    end;
  end;
  if AInstruction.Alignment > 0 then
    Result := Result + ', align ' + IntToStr(AInstruction.Alignment);
  if AInstruction.VolatileAccess then Result := Result + ', volatile';
end;

function DumpIRFunction(AFunction: TIRFunction): string;
var
  Lines: TStringList;
  I, J: LongInt;
  Params: string;
begin
  Lines := TStringList.Create;
  try
    Params := '';
    for I := 0 to High(AFunction.Parameters) do
    begin
      if Params <> '' then Params := Params + ', ';
      Params := Params + IRTypeName(AFunction.Parameters[I].ValueType) + ' ' +
        IRValueText(AFunction.Parameters[I].Value);
      if AFunction.Parameters[I].Name <> '' then
        Params := Params + ' ; ' + AFunction.Parameters[I].Name;
    end;
    if AFunction.Variadic then
    begin
      if Params <> '' then Params := Params + ', ';
      Params := Params + '...';
    end;
    Lines.Add('function ' + IRLinkageName(AFunction.Linkage) + ' ' +
      IRTypeName(AFunction.ReturnType) + ' @' + AFunction.Name +
      '(' + Params + ') {');
    for I := 0 to High(AFunction.Blocks) do
    begin
      Lines.Add(AFunction.Blocks[I].Name + ':');
      for J := 0 to High(AFunction.Blocks[I].Instructions) do
        Lines.Add('  ' + DumpIRInstruction(AFunction,
          AFunction.Blocks[I].Instructions[J]));
    end;
    Lines.Add('}');
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function DumpIRModule(AModule: TIRModule): string;
var
  Lines: TStringList;
  I, J: LongInt;
  Bytes: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('module target "' + AModule.TargetTriple + '"');
    for I := 0 to High(AModule.SourceFiles) do
      Lines.Add('source "' + AModule.SourceFiles[I] + '"');
    Lines.Add('');
    for I := 0 to High(AModule.Globals) do
    begin
      Bytes := '';
      for J := 0 to High(AModule.Globals[I].ConstantData) do
        Bytes := Bytes + IntToHex(AModule.Globals[I].ConstantData[J], 2);
      Lines.Add('global ' + IRLinkageName(AModule.Globals[I].Linkage) + ' @' +
        AModule.Globals[I].Name + ' : ' +
        IRTypeName(AModule.Globals[I].ValueType) + ' align ' +
        IntToStr(AModule.Globals[I].Alignment) + ' data=' + Bytes +
        ' zero=' + IntToStr(AModule.Globals[I].ZeroFillSize));
    end;
    if Length(AModule.Globals) > 0 then Lines.Add('');
    for I := 0 to High(AModule.Functions) do
    begin
      Lines.Add(DumpIRFunction(AModule.Functions[I]));
      Lines.Add('');
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
