unit rcc_machine_ir;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_arch, rcc_ir;

type
  TMachineOperandKind = (
    mokNone,
    mokVirtualRegister,
    mokPhysicalRegister,
    mokImmediate,
    mokFloatingImmediate,
    mokFrameIndex,
    mokGlobalSymbol,
    mokExternalSymbol,
    mokBasicBlock,
    mokMemory,
    mokRegisterMask
  );

  TMachineRegisterClass = (
    mrcInvalid,
    mrcGPR8,
    mrcGPR16,
    mrcGPR32,
    mrcGPR64,
    mrcFPR32,
    mrcFPR64,
    mrcVector128,
    mrcFlags
  );

  TMachineOperand = record
    Kind: TMachineOperandKind;
    RegisterClass: TMachineRegisterClass;
    RegisterNumber: LongInt;
    Immediate: Int64;
    UnsignedImmediate: QWord;
    Symbol: string;
    BlockID: LongInt;
    FrameIndex: LongInt;
    BaseRegister: LongInt;
    IndexRegister: LongInt;
    Scale: LongInt;
    Displacement: Int64;
    IsDefinition: Boolean;
    IsImplicit: Boolean;
    IsKill: Boolean;
    IsDead: Boolean;
  end;
  TMachineOperandArray = array of TMachineOperand;

  TMachineOpcode = (
    mopInvalid,
    mopPseudoCopy,
    mopPseudoPhi,
    mopPseudoLoadImmediate,
    mopPseudoLoadAddress,
    mopPseudoCall,
    mopPseudoReturn,
    mopPseudoPrologue,
    mopPseudoEpilogue,
    mopMove,
    mopLoad,
    mopStore,
    mopAdd,
    mopSub,
    mopMul,
    mopSignedDivide,
    mopUnsignedDivide,
    mopSignedRemainder,
    mopUnsignedRemainder,
    mopAnd,
    mopOr,
    mopXor,
    mopShiftLeft,
    mopShiftRightLogical,
    mopShiftRightArithmetic,
    mopCompare,
    mopSetCondition,
    mopBranch,
    mopBranchCondition,
    mopCall,
    mopReturn,
    mopSyscall,
    mopTrap,
    mopNop
  );

  TMachineInstruction = class
  public
    Opcode: TMachineOpcode;
    Operands: TMachineOperandArray;
    Position: TSourcePos;
    Comment: string;
    EncodedSize: LongInt;
    constructor Create(AOpcode: TMachineOpcode; const APosition: TSourcePos);
    procedure AddOperand(const AOperand: TMachineOperand);
    procedure AddRegister(ARegister: LongInt; AClass: TMachineRegisterClass;
      ADefinition: Boolean = False);
    procedure AddImmediate(AValue: Int64);
    procedure AddSymbol(const AName: string; AExternal: Boolean);
    procedure AddBlock(ABlockID: LongInt);
    function HasSideEffects: Boolean;
    function IsTerminator: Boolean;
    function IsCall: Boolean;
    function Clone: TMachineInstruction;
  end;
  TMachineInstructionArray = array of TMachineInstruction;

  TMachineBasicBlock = class
  public
    ID: LongInt;
    Name: string;
    Instructions: TMachineInstructionArray;
    Predecessors: array of LongInt;
    Successors: array of LongInt;
    Alignment: LongInt;
    AddressTaken: Boolean;
    Frequency: QWord;
    constructor Create(AID: LongInt; const AName: string);
    destructor Destroy; override;
    procedure AddInstruction(AInstruction: TMachineInstruction);
    procedure InsertInstruction(AIndex: LongInt;
      AInstruction: TMachineInstruction);
    procedure DeleteInstruction(AIndex: LongInt);
    function Terminator: TMachineInstruction;
  end;
  TMachineBasicBlockArray = array of TMachineBasicBlock;

  TMachineFrameObject = record
    Index: LongInt;
    Size: QWord;
    Alignment: LongInt;
    Offset: Int64;
    IsSpill: Boolean;
    IsFixed: Boolean;
    IsVariableSized: Boolean;
    Name: string;
  end;
  TMachineFrameObjectArray = array of TMachineFrameObject;

  TMachineFunction = class
  private
    FNextVirtualRegister: LongInt;
    FNextBlock: LongInt;
  public
    Name: string;
    Target: TTargetDescriptor;
    Blocks: TMachineBasicBlockArray;
    FrameObjects: TMachineFrameObjectArray;
    StackSize: QWord;
    StackAlignment: LongInt;
    HasCalls: Boolean;
    HasDynamicAlloca: Boolean;
    UsesFramePointer: Boolean;
    Variadic: Boolean;
    constructor Create(const AName: string;
      const ATarget: TTargetDescriptor);
    destructor Destroy; override;
    function NewVirtualRegister(AClass: TMachineRegisterClass): LongInt;
    function AddBlock(const AName: string): TMachineBasicBlock;
    function BlockByID(AID: LongInt): TMachineBasicBlock;
    function AddFrameObject(ASize: QWord; AAlignment: LongInt;
      const AName: string; ASpill: Boolean = False): LongInt;
    procedure LayoutFrame;
    function InstructionCount: QWord;
  end;

  TMachineModule = class
  public
    Target: TTargetDescriptor;
    Functions: array of TMachineFunction;
    constructor Create(const ATarget: TTargetDescriptor);
    destructor Destroy; override;
    procedure AddFunction(AFunction: TMachineFunction);
    function FindFunction(const AName: string): TMachineFunction;
  end;

function MachineOperandKindName(AKind: TMachineOperandKind): string;
function MachineRegisterClassName(AClass: TMachineRegisterClass): string;
function MachineOpcodeName(AOpcode: TMachineOpcode): string;
function EmptyMachineOperand: TMachineOperand;
function RegisterOperand(ARegister: LongInt; AClass: TMachineRegisterClass;
  ADefinition: Boolean): TMachineOperand;
function ImmediateOperand(AValue: Int64): TMachineOperand;
function SymbolOperand(const AName: string;
  AExternal: Boolean): TMachineOperand;
function BlockOperand(ABlockID: LongInt): TMachineOperand;
function FrameIndexOperand(AIndex: LongInt): TMachineOperand;
function MachineInstructionText(AInstruction: TMachineInstruction): string;
function MachineFunctionText(AFunction: TMachineFunction): string;
function LowerIRTypeRegisterClass(const AType: TIRType): TMachineRegisterClass;
function BuildMachineSkeleton(AModule: TIRModule;
  const ATarget: TTargetDescriptor): TMachineModule;

implementation

function AlignUp(AValue: QWord; AAlignment: LongInt): QWord;
var
  Mask: QWord;
begin
  if AAlignment <= 1 then Exit(AValue);
  Mask := QWord(AAlignment - 1);
  Result := (AValue + Mask) and not Mask;
end;

function MachineOperandKindName(AKind: TMachineOperandKind): string;
begin
  case AKind of
    mokNone: Result := 'none';
    mokVirtualRegister: Result := 'vreg';
    mokPhysicalRegister: Result := 'preg';
    mokImmediate: Result := 'imm';
    mokFloatingImmediate: Result := 'fpimm';
    mokFrameIndex: Result := 'frame';
    mokGlobalSymbol: Result := 'global';
    mokExternalSymbol: Result := 'external';
    mokBasicBlock: Result := 'block';
    mokMemory: Result := 'memory';
    mokRegisterMask: Result := 'regmask';
  else
    Result := 'unknown';
  end;
end;

function MachineRegisterClassName(AClass: TMachineRegisterClass): string;
begin
  case AClass of
    mrcInvalid: Result := 'invalid';
    mrcGPR8: Result := 'gpr8';
    mrcGPR16: Result := 'gpr16';
    mrcGPR32: Result := 'gpr32';
    mrcGPR64: Result := 'gpr64';
    mrcFPR32: Result := 'fpr32';
    mrcFPR64: Result := 'fpr64';
    mrcVector128: Result := 'vec128';
    mrcFlags: Result := 'flags';
  else
    Result := 'unknown';
  end;
end;

function MachineOpcodeName(AOpcode: TMachineOpcode): string;
begin
  case AOpcode of
    mopInvalid: Result := 'invalid';
    mopPseudoCopy: Result := 'pseudo.copy';
    mopPseudoPhi: Result := 'pseudo.phi';
    mopPseudoLoadImmediate: Result := 'pseudo.li';
    mopPseudoLoadAddress: Result := 'pseudo.la';
    mopPseudoCall: Result := 'pseudo.call';
    mopPseudoReturn: Result := 'pseudo.ret';
    mopPseudoPrologue: Result := 'pseudo.prologue';
    mopPseudoEpilogue: Result := 'pseudo.epilogue';
    mopMove: Result := 'move';
    mopLoad: Result := 'load';
    mopStore: Result := 'store';
    mopAdd: Result := 'add';
    mopSub: Result := 'sub';
    mopMul: Result := 'mul';
    mopSignedDivide: Result := 'sdiv';
    mopUnsignedDivide: Result := 'udiv';
    mopSignedRemainder: Result := 'srem';
    mopUnsignedRemainder: Result := 'urem';
    mopAnd: Result := 'and';
    mopOr: Result := 'or';
    mopXor: Result := 'xor';
    mopShiftLeft: Result := 'shl';
    mopShiftRightLogical: Result := 'lshr';
    mopShiftRightArithmetic: Result := 'ashr';
    mopCompare: Result := 'cmp';
    mopSetCondition: Result := 'setcc';
    mopBranch: Result := 'br';
    mopBranchCondition: Result := 'brcc';
    mopCall: Result := 'call';
    mopReturn: Result := 'ret';
    mopSyscall: Result := 'syscall';
    mopTrap: Result := 'trap';
    mopNop: Result := 'nop';
  else
    Result := 'unknown';
  end;
end;

function EmptyMachineOperand: TMachineOperand;
begin


  Result.Kind := mokNone;
  Result.RegisterClass := mrcInvalid;
  Result.RegisterNumber := -1;
  Result.Immediate := 0;
  Result.UnsignedImmediate := 0;
  Result.Symbol := '';
  Result.BlockID := -1;
  Result.FrameIndex := -1;
  Result.BaseRegister := -1;
  Result.IndexRegister := -1;
  Result.Scale := 1;
  Result.Displacement := 0;
  Result.IsDefinition := False;
  Result.IsImplicit := False;
  Result.IsKill := False;
  Result.IsDead := False;
end;

function RegisterOperand(ARegister: LongInt; AClass: TMachineRegisterClass;
  ADefinition: Boolean): TMachineOperand;
begin
  Result := EmptyMachineOperand;
  if ARegister >= 1024 then Result.Kind := mokVirtualRegister
  else Result.Kind := mokPhysicalRegister;
  Result.RegisterNumber := ARegister;
  Result.RegisterClass := AClass;
  Result.IsDefinition := ADefinition;
end;

function ImmediateOperand(AValue: Int64): TMachineOperand;
begin
  Result := EmptyMachineOperand;
  Result.Kind := mokImmediate;
  Result.Immediate := AValue;
  Result.UnsignedImmediate := QWord(AValue);
end;

function SymbolOperand(const AName: string;
  AExternal: Boolean): TMachineOperand;
begin
  Result := EmptyMachineOperand;
  if AExternal then Result.Kind := mokExternalSymbol
  else Result.Kind := mokGlobalSymbol;
  Result.Symbol := AName;
end;

function BlockOperand(ABlockID: LongInt): TMachineOperand;
begin
  Result := EmptyMachineOperand;
  Result.Kind := mokBasicBlock;
  Result.BlockID := ABlockID;
end;

function FrameIndexOperand(AIndex: LongInt): TMachineOperand;
begin
  Result := EmptyMachineOperand;
  Result.Kind := mokFrameIndex;
  Result.FrameIndex := AIndex;
end;

constructor TMachineInstruction.Create(AOpcode: TMachineOpcode;
  const APosition: TSourcePos);
begin
  inherited Create;
  Opcode := AOpcode;
  Position := APosition;
  Comment := '';
  EncodedSize := 0;
  SetLength(Operands, 0);
end;

procedure TMachineInstruction.AddOperand(const AOperand: TMachineOperand);
var
  N: LongInt;
begin
  N := Length(Operands);
  SetLength(Operands, N + 1);
  Operands[N] := AOperand;
end;

procedure TMachineInstruction.AddRegister(ARegister: LongInt;
  AClass: TMachineRegisterClass; ADefinition: Boolean);
begin
  AddOperand(RegisterOperand(ARegister, AClass, ADefinition));
end;

procedure TMachineInstruction.AddImmediate(AValue: Int64);
begin
  AddOperand(ImmediateOperand(AValue));
end;

procedure TMachineInstruction.AddSymbol(const AName: string;
  AExternal: Boolean);
begin
  AddOperand(SymbolOperand(AName, AExternal));
end;

procedure TMachineInstruction.AddBlock(ABlockID: LongInt);
begin
  AddOperand(BlockOperand(ABlockID));
end;

function TMachineInstruction.HasSideEffects: Boolean;
begin
  Result := Opcode in [mopStore, mopPseudoCall, mopCall, mopReturn,
    mopPseudoReturn, mopSyscall, mopTrap, mopBranch, mopBranchCondition];
end;

function TMachineInstruction.IsTerminator: Boolean;
begin
  Result := Opcode in [mopBranch, mopBranchCondition, mopReturn,
    mopPseudoReturn, mopTrap];
end;

function TMachineInstruction.IsCall: Boolean;
begin
  Result := Opcode in [mopPseudoCall, mopCall];
end;

function TMachineInstruction.Clone: TMachineInstruction;
var
  I: LongInt;
begin
  Result := TMachineInstruction.Create(Opcode, Position);
  Result.Comment := Comment;
  Result.EncodedSize := EncodedSize;
  SetLength(Result.Operands, Length(Operands));
  for I := 0 to High(Operands) do Result.Operands[I] := Operands[I];
end;

constructor TMachineBasicBlock.Create(AID: LongInt; const AName: string);
begin
  inherited Create;
  ID := AID;
  Name := AName;
  SetLength(Instructions, 0);
  SetLength(Predecessors, 0);
  SetLength(Successors, 0);
  Alignment := 1;
  AddressTaken := False;
  Frequency := 1;
end;

destructor TMachineBasicBlock.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(Instructions) do Instructions[I].Free;
  inherited Destroy;
end;

procedure TMachineBasicBlock.AddInstruction(
  AInstruction: TMachineInstruction);
var
  N: LongInt;
begin
  if AInstruction = nil then
    raise ERCCError.Create('internal error: nil machine instruction');
  N := Length(Instructions);
  SetLength(Instructions, N + 1);
  Instructions[N] := AInstruction;
end;

procedure TMachineBasicBlock.InsertInstruction(AIndex: LongInt;
  AInstruction: TMachineInstruction);
var
  I, N: LongInt;
begin
  if (AIndex < 0) or (AIndex > Length(Instructions)) then
    raise ERCCError.Create('internal error: machine insert index invalid');
  N := Length(Instructions);
  SetLength(Instructions, N + 1);
  for I := N downto AIndex + 1 do Instructions[I] := Instructions[I - 1];
  Instructions[AIndex] := AInstruction;
end;

procedure TMachineBasicBlock.DeleteInstruction(AIndex: LongInt);
var
  I, N: LongInt;
begin
  N := Length(Instructions);
  if (AIndex < 0) or (AIndex >= N) then
    raise ERCCError.Create('internal error: machine delete index invalid');
  Instructions[AIndex].Free;
  for I := AIndex to N - 2 do Instructions[I] := Instructions[I + 1];
  SetLength(Instructions, N - 1);
end;

function TMachineBasicBlock.Terminator: TMachineInstruction;
begin
  if Length(Instructions) = 0 then Exit(nil);
  if Instructions[High(Instructions)].IsTerminator then
    Result := Instructions[High(Instructions)]
  else Result := nil;
end;

constructor TMachineFunction.Create(const AName: string;
  const ATarget: TTargetDescriptor);
begin
  inherited Create;
  Name := AName;
  Target := ATarget;
  SetLength(Blocks, 0);
  SetLength(FrameObjects, 0);
  StackSize := 0;
  StackAlignment := ATarget.DataLayout.StackAlignment;
  HasCalls := False;
  HasDynamicAlloca := False;
  UsesFramePointer := False;
  Variadic := False;
  FNextVirtualRegister := 1024;
  FNextBlock := 0;
end;

destructor TMachineFunction.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(Blocks) do Blocks[I].Free;
  inherited Destroy;
end;

function TMachineFunction.NewVirtualRegister(
  AClass: TMachineRegisterClass): LongInt;
begin
  if AClass = mrcInvalid then
    raise ERCCError.Create('internal error: virtual register needs class');
  Result := FNextVirtualRegister;
  Inc(FNextVirtualRegister);
end;

function TMachineFunction.AddBlock(const AName: string): TMachineBasicBlock;
var
  N: LongInt;
begin
  Result := TMachineBasicBlock.Create(FNextBlock, AName);
  Inc(FNextBlock);
  N := Length(Blocks);
  SetLength(Blocks, N + 1);
  Blocks[N] := Result;
end;

function TMachineFunction.BlockByID(AID: LongInt): TMachineBasicBlock;
var
  I: LongInt;
begin
  for I := 0 to High(Blocks) do
    if Blocks[I].ID = AID then Exit(Blocks[I]);
  Result := nil;
end;

function TMachineFunction.AddFrameObject(ASize: QWord;
  AAlignment: LongInt; const AName: string; ASpill: Boolean): LongInt;
var
  N: LongInt;
begin
  if AAlignment <= 0 then AAlignment := 1;
  N := Length(FrameObjects);
  SetLength(FrameObjects, N + 1);
  FrameObjects[N].Index := N;
  FrameObjects[N].Size := ASize;
  FrameObjects[N].Alignment := AAlignment;
  FrameObjects[N].Offset := 0;
  FrameObjects[N].IsSpill := ASpill;
  FrameObjects[N].IsFixed := False;
  FrameObjects[N].IsVariableSized := False;
  FrameObjects[N].Name := AName;
  Result := N;
end;

procedure TMachineFunction.LayoutFrame;
var
  I: LongInt;
  Offset: QWord;
begin
  Offset := 0;
  for I := 0 to High(FrameObjects) do
  begin
    if FrameObjects[I].IsFixed then Continue;
    Offset := AlignUp(Offset, FrameObjects[I].Alignment);
    Inc(Offset, FrameObjects[I].Size);
    FrameObjects[I].Offset := -Int64(Offset);
  end;
  StackSize := AlignUp(Offset, StackAlignment);
end;

function TMachineFunction.InstructionCount: QWord;
var
  I: LongInt;
begin
  Result := 0;
  for I := 0 to High(Blocks) do Inc(Result, Length(Blocks[I].Instructions));
end;

constructor TMachineModule.Create(const ATarget: TTargetDescriptor);
begin
  inherited Create;
  Target := ATarget;
  SetLength(Functions, 0);
end;

destructor TMachineModule.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(Functions) do Functions[I].Free;
  inherited Destroy;
end;

procedure TMachineModule.AddFunction(AFunction: TMachineFunction);
var
  N: LongInt;
begin
  if AFunction = nil then
    raise ERCCError.Create('internal error: nil machine function');
  N := Length(Functions);
  SetLength(Functions, N + 1);
  Functions[N] := AFunction;
end;

function TMachineModule.FindFunction(const AName: string): TMachineFunction;
var
  I: LongInt;
begin
  for I := 0 to High(Functions) do
    if Functions[I].Name = AName then Exit(Functions[I]);
  Result := nil;
end;

function LowerIRTypeRegisterClass(const AType: TIRType): TMachineRegisterClass;
begin
  case AType.Kind of
    irtI1, irtI8: Result := mrcGPR8;
    irtI16: Result := mrcGPR16;
    irtI32: Result := mrcGPR32;
    irtI64, irtPointer: Result := mrcGPR64;
    irtF32: Result := mrcFPR32;
    irtF64, irtF80: Result := mrcFPR64;
  else
    Result := mrcInvalid;
  end;
end;

function OperandText(const AOperand: TMachineOperand): string;
begin
  case AOperand.Kind of
    mokVirtualRegister: Result := '%v' + IntToStr(AOperand.RegisterNumber);
    mokPhysicalRegister: Result := '%r' + IntToStr(AOperand.RegisterNumber);
    mokImmediate: Result := '$' + IntToStr(AOperand.Immediate);
    mokFrameIndex: Result := 'fi#' + IntToStr(AOperand.FrameIndex);
    mokGlobalSymbol: Result := '@' + AOperand.Symbol;
    mokExternalSymbol: Result := '@extern(' + AOperand.Symbol + ')';
    mokBasicBlock: Result := 'bb.' + IntToStr(AOperand.BlockID);
    mokMemory: Result := '[r' + IntToStr(AOperand.BaseRegister) + '+r' +
      IntToStr(AOperand.IndexRegister) + '*' + IntToStr(AOperand.Scale) +
      '+' + IntToStr(AOperand.Displacement) + ']';
  else
    Result := MachineOperandKindName(AOperand.Kind);
  end;
  if AOperand.IsDefinition then Result := Result + '(def)';
end;

function MachineInstructionText(AInstruction: TMachineInstruction): string;
var
  I: LongInt;
begin
  if AInstruction = nil then Exit('<nil>');
  Result := MachineOpcodeName(AInstruction.Opcode);
  for I := 0 to High(AInstruction.Operands) do
  begin
    if I = 0 then Result := Result + ' ' else Result := Result + ', ';
    Result := Result + OperandText(AInstruction.Operands[I]);
  end;
  if AInstruction.Comment <> '' then Result := Result + ' ; ' + AInstruction.Comment;
end;

function MachineFunctionText(AFunction: TMachineFunction): string;
var
  Lines: TStringList;
  I, J: LongInt;
begin
  if AFunction = nil then Exit('<nil machine function>');
  Lines := TStringList.Create;
  try
    Lines.Add('machine function @' + AFunction.Name + ' target=' +
      AFunction.Target.Triple);
    Lines.Add('  stack=' + IntToStr(AFunction.StackSize) +
      ' align=' + IntToStr(AFunction.StackAlignment));
    for I := 0 to High(AFunction.Blocks) do
    begin
      Lines.Add('bb.' + IntToStr(AFunction.Blocks[I].ID) + ' ' +
        AFunction.Blocks[I].Name + ':');
      for J := 0 to High(AFunction.Blocks[I].Instructions) do
        Lines.Add('  ' + MachineInstructionText(
          AFunction.Blocks[I].Instructions[J]));
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function BuildMachineSkeleton(AModule: TIRModule;
  const ATarget: TTargetDescriptor): TMachineModule;
var
  I, J: LongInt;
  IRFunction: TIRFunction;
  MF: TMachineFunction;
  MB: TMachineBasicBlock;
  MI: TMachineInstruction;
  P: TSourcePos;
begin
  Result := TMachineModule.Create(ATarget);
  if AModule = nil then Exit;
  P.FileName := '';
  P.Line := 0;
  P.Column := 0;
  for I := 0 to High(AModule.Functions) do
  begin
    IRFunction := AModule.Functions[I];
    MF := TMachineFunction.Create(IRFunction.Name, ATarget);
    MF.Variadic := IRFunction.Variadic;
    for J := 0 to High(IRFunction.Blocks) do
      MF.AddBlock(IRFunction.Blocks[J].Name);
    if Length(MF.Blocks) = 0 then MF.AddBlock('entry');
    MB := MF.Blocks[0];
    MI := TMachineInstruction.Create(mopPseudoPrologue, P);
    MB.AddInstruction(MI);
    MI := TMachineInstruction.Create(mopPseudoReturn, P);
    MI.Comment := 'instruction selection has not lowered this body yet';
    MB.AddInstruction(MI);
    MF.LayoutFrame;
    Result.AddFunction(MF);
  end;
end;

end.
