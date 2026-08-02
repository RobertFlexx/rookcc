unit rcc_ir_verify;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_ir;

type
  TIRVerificationOptions = record
    RequireTerminatedBlocks: Boolean;
    RejectOpaqueOperations: Boolean;
    RequireReachableEntry: Boolean;
    RequireSSAOrder: Boolean;
  end;

function DefaultIRVerificationOptions: TIRVerificationOptions;
procedure VerifyIRModule(AModule: TIRModule; const AStage: string);
procedure VerifyIRModuleWithOptions(AModule: TIRModule;
  const AStage: string; const AOptions: TIRVerificationOptions);

implementation

procedure Fail(const AStage, AMessage: string);
begin
  raise ERCCError.Create('internal error: IR verification failed at ' +
    AStage + ': ' + AMessage);
end;

function DefaultIRVerificationOptions: TIRVerificationOptions;
begin
  Result.RequireTerminatedBlocks := True;
  Result.RejectOpaqueOperations := False;
  Result.RequireReachableEntry := True;
  Result.RequireSSAOrder := False;
end;

function BlockExists(AFunction: TIRFunction; AID: TIRBlockID): Boolean;
begin
  Result := AFunction.BlockByID(AID) <> nil;
end;

procedure VerifyValueUse(AFunction: TIRFunction; AValue: TIRValue;
  const AStage: string; ABlock: TIRBasicBlock; AInstructionIndex: LongInt;
  ARequireOrder: Boolean);
var
  D: TIRValueDefinition;
begin
  if (AValue < 0) or (AValue >= AFunction.ValueCount) then
    Fail(AStage, 'instruction uses invalid value ' + IntToStr(AValue));
  D := AFunction.ValueDefinitions[AValue];
  if D.IsParameter then Exit;
  if D.DefiningBlock < 0 then
    Fail(AStage, 'value ' + IRValueText(AValue) + ' has no definition');
  if ARequireOrder and (D.DefiningBlock = ABlock.ID) and
     (D.DefiningInstruction >= AInstructionIndex) then
    Fail(AStage, 'value ' + IRValueText(AValue) +
      ' is used before its definition');
end;

procedure VerifyInstruction(AFunction: TIRFunction; ABlock: TIRBasicBlock;
  AInstruction: TIRInstruction; AInstructionIndex: LongInt;
  const AStage: string; const AOptions: TIRVerificationOptions);
var
  I: LongInt;
  Def: TIRValueDefinition;
begin
  if AInstruction = nil then Fail(AStage, 'nil instruction');
  if AInstruction.HasResult then
  begin
    if AInstruction.ResultValue >= AFunction.ValueCount then
      Fail(AStage, 'instruction result is outside value table');
    Def := AFunction.ValueDefinitions[AInstruction.ResultValue];
    if (Def.DefiningBlock <> ABlock.ID) or
       (Def.DefiningInstruction <> AInstructionIndex) then
      Fail(AStage, 'value definition table disagrees with instruction');
    if AInstruction.ResultType.Kind = irtVoid then
      Fail(AStage, 'void instruction has a result value');
  end
  else if AInstruction.ResultType.Kind <> irtVoid then
    Fail(AStage, 'typed instruction has no result value');

  for I := 0 to High(AInstruction.Operands) do
    VerifyValueUse(AFunction, AInstruction.Operands[I], AStage,
      ABlock, AInstructionIndex, AOptions.RequireSSAOrder);

  if AOptions.RejectOpaqueOperations and
     (AInstruction.Opcode = iroOpaque) then
    Fail(AStage, 'opaque operation remains in code-generation IR');

  case AInstruction.Opcode of
    iroLoad:
      if Length(AInstruction.Operands) <> 1 then
        Fail(AStage, 'load requires one pointer operand');
    iroStore:
      if Length(AInstruction.Operands) <> 2 then
        Fail(AStage, 'store requires value and pointer operands');
    iroCall:
      begin
        if (AInstruction.Symbol = '') and
           (Length(AInstruction.Operands) < 1) then
          Fail(AStage, 'indirect call requires a callee operand');
      end;
    iroIntrinsic:
      if AInstruction.Symbol = '' then
        Fail(AStage, 'intrinsic requires a name');
    iroBranch:
      begin
        if not BlockExists(AFunction, AInstruction.TrueBlock) then
          Fail(AStage, 'branch targets missing block');
        if Length(AInstruction.Operands) <> 0 then
          Fail(AStage, 'branch has unexpected operands');
      end;
    iroCondBranch:
      begin
        if Length(AInstruction.Operands) <> 1 then
          Fail(AStage, 'conditional branch requires one condition');
        if not BlockExists(AFunction, AInstruction.TrueBlock) or
           not BlockExists(AFunction, AInstruction.FalseBlock) then
          Fail(AStage, 'conditional branch targets missing block');
      end;
    iroSwitch:
      begin
        if Length(AInstruction.Operands) <> 1 then
          Fail(AStage, 'switch requires one selector');
        if not BlockExists(AFunction, AInstruction.DefaultBlock) then
          Fail(AStage, 'switch default target missing');
        for I := 0 to High(AInstruction.SwitchCases) do
          if not BlockExists(AFunction,
            AInstruction.SwitchCases[I].TargetBlock) then
            Fail(AStage, 'switch case target missing');
      end;
    iroReturn:
      begin
        if AFunction.ReturnType.Kind = irtVoid then
        begin
          if Length(AInstruction.Operands) <> 0 then
            Fail(AStage, 'void function returns a value');
        end
        else if Length(AInstruction.Operands) <> 1 then
          Fail(AStage, 'non-void function must return one value');
      end;
    iroUnreachable:
      if Length(AInstruction.Operands) <> 0 then
        Fail(AStage, 'unreachable has operands');
  end;
end;

procedure VerifyFunction(AFunction: TIRFunction; const AStage: string;
  const AOptions: TIRVerificationOptions);
var
  I, J: LongInt;
  B: TIRBasicBlock;
begin
  if AFunction = nil then Fail(AStage, 'nil function');
  if AFunction.Name = '' then Fail(AStage, 'unnamed function');
  if Length(AFunction.Blocks) = 0 then Exit;
  if not BlockExists(AFunction, AFunction.EntryBlock) then
    Fail(AStage, 'function entry block is missing');
  for I := 0 to High(AFunction.Blocks) do
  begin
    B := AFunction.Blocks[I];
    if B = nil then Fail(AStage, 'nil basic block');
    if B.ID < 0 then Fail(AStage, 'negative basic block ID');
    if AOptions.RequireTerminatedBlocks and not B.IsTerminated then
      Fail(AStage, 'block ' + B.Name + ' is not terminated');
    for J := 0 to High(B.Instructions) do
    begin
      if B.Instructions[J].IsTerminator and
         (J <> High(B.Instructions)) then
        Fail(AStage, 'terminator is not last in block ' + B.Name);
      VerifyInstruction(AFunction, B, B.Instructions[J], J,
        AStage, AOptions);
    end;
  end;
end;

procedure VerifyIRModuleWithOptions(AModule: TIRModule;
  const AStage: string; const AOptions: TIRVerificationOptions);
var
  I, J: LongInt;
begin
  if AModule = nil then Fail(AStage, 'nil module');
  if AModule.TargetTriple = '' then Fail(AStage, 'module has no target triple');
  for I := 0 to High(AModule.Functions) do
  begin
    for J := I + 1 to High(AModule.Functions) do
      if AModule.Functions[I].Name = AModule.Functions[J].Name then
        Fail(AStage, 'duplicate function @' + AModule.Functions[I].Name);
    VerifyFunction(AModule.Functions[I], AStage, AOptions);
  end;
  for I := 0 to High(AModule.Globals) do
  begin
    if AModule.Globals[I] = nil then Fail(AStage, 'nil global');
    if AModule.Globals[I].Name = '' then Fail(AStage, 'unnamed global');
    for J := I + 1 to High(AModule.Globals) do
      if AModule.Globals[I].Name = AModule.Globals[J].Name then
        Fail(AStage, 'duplicate global @' + AModule.Globals[I].Name);
  end;
end;

procedure VerifyIRModule(AModule: TIRModule; const AStage: string);
var
  Options: TIRVerificationOptions;
begin
  Options := DefaultIRVerificationOptions;
  VerifyIRModuleWithOptions(AModule, AStage, Options);
end;

end.
