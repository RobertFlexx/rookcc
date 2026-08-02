unit rcc_ir_lower;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_ir, rcc_typeops;

type
  TIRLoweringStats = record
    FunctionsLowered: QWord;
    GlobalsLowered: QWord;
    BlocksCreated: QWord;
    InstructionsCreated: QWord;
    OpaqueExpressions: QWord;
    OpaqueStatements: QWord;
  end;

function LowerProgramToIR(AProgram: TProgram; const ATargetTriple: string;
  out AStats: TIRLoweringStats): TIRModule;

implementation

type
  TLocalBinding = record
    Name: string;
    AddressValue: TIRValue;
    ValueType: TIRType;
    ScopeDepth: LongInt;
  end;
  TLocalBindingArray = array of TLocalBinding;

  TNamedBlock = record
    Name: string;
    BlockID: TIRBlockID;
  end;
  TNamedBlockArray = array of TNamedBlock;

  TIRLowerer = class
  private
    FProgram: TProgram;
    FModule: TIRModule;
    FFunction: TIRFunction;
    FBuilder: TIRBuilder;
    FCurrentBlock: TIRBasicBlock;
    FLocals: TLocalBindingArray;
    FScopeDepth: LongInt;
    FBreakBlocks: TIRBlockIDArray;
    FContinueBlocks: TIRBlockIDArray;
    FLabels: TNamedBlockArray;
    FStats: TIRLoweringStats;
    procedure SetBlock(ABlock: TIRBasicBlock);
    function NewBlock(const AName: string): TIRBasicBlock;
    procedure MarkOpaque(const AText: string; const APosition: TSourcePos;
      AStatement: Boolean);
    procedure EnterScope;
    procedure LeaveScope;
    procedure AddLocal(const AName: string; AAddress: TIRValue;
      const AType: TIRType);
    function FindLocal(const AName: string; out ABinding: TLocalBinding): Boolean;
    procedure PushBreak(AID: TIRBlockID);
    procedure PopBreak;
    procedure PushContinue(AID: TIRBlockID);
    procedure PopContinue;
    function CurrentBreak: TIRBlockID;
    function CurrentContinue: TIRBlockID;
    function RequireLabel(const AName: string): TIRBlockID;
    procedure ReserveLabels(AStatement: TStmt);
    function LowerLValue(AExpression: TExpr): TIRValue;
    function LowerExpression(AExpression: TExpr): TIRValue;
    function LowerBoolean(AExpression: TExpr): TIRValue;
    procedure LowerStatement(AStatement: TStmt);
    procedure LowerFunction(AFunction: TFunction);
    procedure LowerGlobal(AGlobal: TGlobal);
  public
    constructor Create(AProgram: TProgram; const ATargetTriple: string);
    destructor Destroy; override;
    function Lower: TIRModule;
    property Stats: TIRLoweringStats read FStats;
  end;

procedure AppendBlockID(var AValues: TIRBlockIDArray; AValue: TIRBlockID);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

function UnaryOpcode(AOperation: TUnaryOp): TIROpcode;
begin
  case AOperation of
    uoPositive: Result := iroCopy;
    uoNegative: Result := iroNeg;
    uoLogicalNot: Result := iroLogicalNot;
    uoBitwiseNot: Result := iroNot;
  else
    Result := iroOpaque;
  end;
end;

function BinaryOpcode(AOperation: TBinaryOp; AUnsigned: Boolean): TIROpcode;
begin
  case AOperation of
    boAdd: Result := iroAdd;
    boSub: Result := iroSub;
    boMul: Result := iroMul;
    boDiv: if AUnsigned then Result := iroUDiv else Result := iroSDiv;
    boMod: if AUnsigned then Result := iroURem else Result := iroSRem;
    boShiftLeft: Result := iroShl;
    boShiftRight: if AUnsigned then Result := iroLShr else Result := iroAShr;
    boLess: if AUnsigned then Result := iroICmpULT else Result := iroICmpSLT;
    boLessEqual: if AUnsigned then Result := iroICmpULE else Result := iroICmpSLE;
    boGreater: if AUnsigned then Result := iroICmpUGT else Result := iroICmpSGT;
    boGreaterEqual: if AUnsigned then Result := iroICmpUGE else Result := iroICmpSGE;
    boEqual: Result := iroICmpEQ;
    boNotEqual: Result := iroICmpNE;
    boBitAnd: Result := iroAnd;
    boBitXor: Result := iroXor;
    boBitOr: Result := iroOr;
  else
    Result := iroOpaque;
  end;
end;

function FloatingBinaryOpcode(AOperation: TBinaryOp): TIROpcode;
begin
  case AOperation of
    boAdd: Result := iroFAdd;
    boSub: Result := iroFSub;
    boMul: Result := iroFMul;
    boDiv: Result := iroFDiv;
    boLess: Result := iroFCmpOLT;
    boLessEqual: Result := iroFCmpOLE;
    boGreater: Result := iroFCmpOGT;
    boGreaterEqual: Result := iroFCmpOGE;
    boEqual: Result := iroFCmpOEQ;
    boNotEqual: Result := iroFCmpONE;
  else
    Result := iroOpaque;
  end;
end;

function IRTypeIsFloat(const AType: TIRType): Boolean;
begin
  Result := AType.Kind in [irtF32, irtF64, irtF80];
end;

constructor TIRLowerer.Create(AProgram: TProgram; const ATargetTriple: string);
begin
  inherited Create;
  FProgram := AProgram;
  FModule := TIRModule.Create(ATargetTriple);
  FFunction := nil;
  FBuilder := nil;
  FCurrentBlock := nil;
  SetLength(FLocals, 0);
  SetLength(FBreakBlocks, 0);
  SetLength(FContinueBlocks, 0);
  SetLength(FLabels, 0);
  FillChar(FStats, SizeOf(FStats), 0);
end;

destructor TIRLowerer.Destroy;
begin
  FBuilder.Free;
  FModule.Free;
  inherited Destroy;
end;

procedure TIRLowerer.SetBlock(ABlock: TIRBasicBlock);
begin
  FCurrentBlock := ABlock;
  FBuilder.PositionAtEnd(ABlock);
end;

function TIRLowerer.NewBlock(const AName: string): TIRBasicBlock;
begin
  Result := FFunction.AddBlock(AName);
  Inc(FStats.BlocksCreated);
end;

procedure TIRLowerer.MarkOpaque(const AText: string;
  const APosition: TSourcePos; AStatement: Boolean);
var
  I: TIRInstruction;
begin
  if (FCurrentBlock = nil) or FCurrentBlock.IsTerminated then Exit;
  I := FBuilder.Emit(iroOpaque, IRVoidType, APosition);
  I.Text := AText;
  FModule.HasOpaqueOperations := True;
  if AStatement then Inc(FStats.OpaqueStatements)
  else Inc(FStats.OpaqueExpressions);
  Inc(FStats.InstructionsCreated);
end;

procedure TIRLowerer.EnterScope;
begin
  Inc(FScopeDepth);
end;

procedure TIRLowerer.LeaveScope;
var
  N: LongInt;
begin
  N := Length(FLocals);
  while (N > 0) and (FLocals[N - 1].ScopeDepth >= FScopeDepth) do Dec(N);
  SetLength(FLocals, N);
  Dec(FScopeDepth);
end;

procedure TIRLowerer.AddLocal(const AName: string; AAddress: TIRValue;
  const AType: TIRType);
var
  N: LongInt;
begin
  N := Length(FLocals);
  SetLength(FLocals, N + 1);
  FLocals[N].Name := AName;
  FLocals[N].AddressValue := AAddress;
  FLocals[N].ValueType := AType;
  FLocals[N].ScopeDepth := FScopeDepth;
end;

function TIRLowerer.FindLocal(const AName: string;
  out ABinding: TLocalBinding): Boolean;
var
  I: LongInt;
begin
  for I := High(FLocals) downto 0 do
    if FLocals[I].Name = AName then
    begin
      ABinding := FLocals[I];
      Exit(True);
    end;
  ABinding.Name := '';
  ABinding.AddressValue := -1;
  ABinding.ValueType := IRVoidType;
  ABinding.ScopeDepth := -1;
  Result := False;
end;

procedure TIRLowerer.PushBreak(AID: TIRBlockID);
begin
  AppendBlockID(FBreakBlocks, AID);
end;

procedure TIRLowerer.PopBreak;
begin
  if Length(FBreakBlocks) > 0 then
    SetLength(FBreakBlocks, Length(FBreakBlocks) - 1);
end;

procedure TIRLowerer.PushContinue(AID: TIRBlockID);
begin
  AppendBlockID(FContinueBlocks, AID);
end;

procedure TIRLowerer.PopContinue;
begin
  if Length(FContinueBlocks) > 0 then
    SetLength(FContinueBlocks, Length(FContinueBlocks) - 1);
end;

function TIRLowerer.CurrentBreak: TIRBlockID;
begin
  if Length(FBreakBlocks) = 0 then Result := -1
  else Result := FBreakBlocks[High(FBreakBlocks)];
end;

function TIRLowerer.CurrentContinue: TIRBlockID;
begin
  if Length(FContinueBlocks) = 0 then Result := -1
  else Result := FContinueBlocks[High(FContinueBlocks)];
end;

function TIRLowerer.RequireLabel(const AName: string): TIRBlockID;
var
  I, N: LongInt;
  B: TIRBasicBlock;
begin
  for I := 0 to High(FLabels) do
    if FLabels[I].Name = AName then Exit(FLabels[I].BlockID);
  B := NewBlock('label.' + AName);
  N := Length(FLabels);
  SetLength(FLabels, N + 1);
  FLabels[N].Name := AName;
  FLabels[N].BlockID := B.ID;
  Result := B.ID;
end;

procedure TIRLowerer.ReserveLabels(AStatement: TStmt);
var
  I: LongInt;
begin
  if AStatement = nil then Exit;
  if AStatement.Kind = skLabel then RequireLabel(AStatement.Name);
  ReserveLabels(AStatement.InitStmt);
  ReserveLabels(AStatement.Body);
  ReserveLabels(AStatement.ElseBody);
  for I := 0 to High(AStatement.Children) do
    ReserveLabels(AStatement.Children[I]);
end;

function TIRLowerer.LowerLValue(AExpression: TExpr): TIRValue;
var
  Binding: TLocalBinding;
  I: TIRInstruction;
  Base, IndexValue, ScaleValue, OffsetValue: TIRValue;
  PointerType: TIRType;
begin
  Result := -1;
  if AExpression = nil then Exit;
  PointerType := IRPointerType;
  case AExpression.Kind of
    ekVariable:
      begin
        if FindLocal(AExpression.Text, Binding) then
          Exit(Binding.AddressValue);
        I := FBuilder.Emit(iroAddressOfGlobal, PointerType,
          AExpression.Pos, AExpression.Text + '.addr');
        I.Symbol := AExpression.Text;
        Inc(FStats.InstructionsCreated);
        Exit(I.ResultValue);
      end;
    ekDeref:
      Exit(LowerExpression(AExpression.Left));
    ekIndex:
      begin
        Base := LowerExpression(AExpression.Left);
        IndexValue := LowerExpression(AExpression.Right);
        ScaleValue := FBuilder.EmitConstant(CTypeSize(AExpression.CType),
          IRType(irtI64, 64, True), AExpression.Pos);
        Inc(FStats.InstructionsCreated);
        OffsetValue := FBuilder.EmitBinary(iroMul, IndexValue, ScaleValue,
          IRType(irtI64, 64, True), AExpression.Pos);
        Inc(FStats.InstructionsCreated);
        Result := FBuilder.EmitBinary(iroAdd, Base, OffsetValue,
          PointerType, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
        Exit;
      end;
    ekMember, ekArrow:
      begin
        if AExpression.Kind = ekArrow then Base := LowerExpression(AExpression.Left)
        else Base := LowerLValue(AExpression.Left);
        I := FBuilder.Emit(iroGetElementPtr, PointerType, AExpression.Pos);
        I.AddOperand(Base);
        I.Immediate := AExpression.IntValue;
        I.Symbol := AExpression.Text;
        Inc(FStats.InstructionsCreated);
        Exit(I.ResultValue);
      end;
  end;
  MarkOpaque('unsupported lvalue', AExpression.Pos, False);
end;

function TIRLowerer.LowerBoolean(AExpression: TExpr): TIRValue;
var
  V, Zero: TIRValue;
  T: TIRType;
begin
  V := LowerExpression(AExpression);
  T := IRBoolType;
  if V < 0 then
  begin
    Result := FBuilder.EmitConstant(0, T, AExpression.Pos);
    Inc(FStats.InstructionsCreated);
    Exit;
  end;
  if FFunction.ValueType(V).Kind = irtI1 then Exit(V);
  Zero := FBuilder.EmitConstant(0, FFunction.ValueType(V), AExpression.Pos);
  Inc(FStats.InstructionsCreated);
  Result := FBuilder.EmitBinary(iroICmpNE, V, Zero, T, AExpression.Pos);
  Inc(FStats.InstructionsCreated);
end;

function TIRLowerer.LowerExpression(AExpression: TExpr): TIRValue;
var
  L, R, T, AddressValue, Value, OldValue, OneValue: TIRValue;
  Op: TIROpcode;
  IRResultType: TIRType;
  Binding: TLocalBinding;
  I: TIRInstruction;
  Args: TIRValueArray;
  N: LongInt;
  SelectInstruction: TIRInstruction;
begin
  Result := -1;
  if AExpression = nil then Exit;
  IRResultType := CTypeToIRType(AExpression.CType);
  case AExpression.Kind of
    ekTrap:
      begin
        I := FBuilder.Emit(iroIntrinsic, IRVoidType, AExpression.Pos,
          'builtin.trap');
        if AExpression.Text = '__builtin_unreachable' then
          I.Symbol := 'unreachable'
        else
          I.Symbol := 'trap';
        Result := -1;
        Inc(FStats.InstructionsCreated);
      end;
    ekInteger:
      begin
        Result := FBuilder.EmitConstant(AExpression.IntValue,
          IRResultType, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
      end;
    ekFloat:
      begin
        I := FBuilder.Emit(iroConstant, IRResultType, AExpression.Pos,
          'fp.constant');
        Move(AExpression.FloatValue, I.UnsignedImmediate,
          SizeOf(AExpression.FloatValue));
        Result := I.ResultValue;
        Inc(FStats.InstructionsCreated);
      end;
    ekString:
      begin
        I := FBuilder.Emit(iroAddressOfGlobal, IRPointerType,
          AExpression.Pos, 'str.addr');
        I.Symbol := '.str.' + IntToHex(PtrUInt(Pointer(AExpression)), 1);
        I.Text := AExpression.Text;
        Result := I.ResultValue;
        Inc(FStats.InstructionsCreated);
      end;
    ekVariable:
      begin
        if FindLocal(AExpression.Text, Binding) then
        begin
          Result := FBuilder.EmitLoad(Binding.AddressValue,
            Binding.ValueType, CTypeAlign(AExpression.CType),
            AExpression.CType.IsVolatile, AExpression.Pos);
          Inc(FStats.InstructionsCreated);
        end
        else if AExpression.IsFunctionDesignator then
        begin
          I := FBuilder.Emit(iroAddressOfFunction, IRPointerType,
            AExpression.Pos, AExpression.Text + '.fn');
          I.Symbol := AExpression.Text;
          Result := I.ResultValue;
          Inc(FStats.InstructionsCreated);
        end
        else
        begin
          AddressValue := LowerLValue(AExpression);
          Result := FBuilder.EmitLoad(AddressValue, IRResultType,
            CTypeAlign(AExpression.CType), AExpression.CType.IsVolatile,
            AExpression.Pos);
          Inc(FStats.InstructionsCreated);
        end;
      end;
    ekUnary:
      begin
        L := LowerExpression(AExpression.Left);
        if IRTypeIsFloat(IRResultType) and
          (AExpression.UnaryOp = uoNegative) then Op := iroFNeg
        else Op := UnaryOpcode(AExpression.UnaryOp);
        Result := FBuilder.EmitUnary(Op, L,
          IRResultType, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
      end;
    ekBinary:
      begin
        if AExpression.BinaryOp = boComma then
        begin
          LowerExpression(AExpression.Left);
          Result := LowerExpression(AExpression.Right);
          Exit;
        end;
        if AExpression.BinaryOp in [boLogicalAnd, boLogicalOr] then
        begin
          L := LowerBoolean(AExpression.Left);
          R := LowerBoolean(AExpression.Right);
          if AExpression.BinaryOp = boLogicalAnd then Op := iroAnd
          else Op := iroOr;
          Result := FBuilder.EmitBinary(Op, L, R, IRBoolType,
            AExpression.Pos);
          Inc(FStats.InstructionsCreated);
          Exit;
        end;
        L := LowerExpression(AExpression.Left);
        R := LowerExpression(AExpression.Right);
        if IsFloatingType(AExpression.Left.CType) or
          IsFloatingType(AExpression.Right.CType) then
          Op := FloatingBinaryOpcode(AExpression.BinaryOp)
        else
          Op := BinaryOpcode(AExpression.BinaryOp,
            AExpression.CType.IsUnsigned);
        if Op = iroOpaque then
        begin
          MarkOpaque('unsupported binary operation', AExpression.Pos, False);
          Exit;
        end;
        if Op in [iroICmpEQ, iroICmpNE, iroICmpSLT, iroICmpSLE,
          iroICmpSGT, iroICmpSGE, iroICmpULT, iroICmpULE,
          iroICmpUGT, iroICmpUGE, iroFCmpOEQ, iroFCmpONE,
          iroFCmpOLT, iroFCmpOLE, iroFCmpOGT, iroFCmpOGE] then
          T := -1 else T := 0;
        if T = -1 then IRResultType := IRBoolType;
        Result := FBuilder.EmitBinary(Op, L, R, IRResultType,
          AExpression.Pos);
        Inc(FStats.InstructionsCreated);
      end;
    ekAssign:
      begin
        AddressValue := LowerLValue(AExpression.Left);
        Value := LowerExpression(AExpression.Right);
        if AExpression.AssignOp <> aoAssign then
        begin
          OldValue := FBuilder.EmitLoad(AddressValue,
            CTypeToIRType(AExpression.Left.CType),
            CTypeAlign(AExpression.Left.CType),
            AExpression.Left.CType.IsVolatile, AExpression.Pos);
          Inc(FStats.InstructionsCreated);
          case AExpression.AssignOp of
            aoAdd: Op := iroAdd;
            aoSub: Op := iroSub;
            aoMul: Op := iroMul;
            aoDiv: if AExpression.CType.IsUnsigned then Op := iroUDiv
                   else Op := iroSDiv;
            aoMod: if AExpression.CType.IsUnsigned then Op := iroURem
                   else Op := iroSRem;
            aoBitAnd: Op := iroAnd;
            aoBitOr: Op := iroOr;
            aoBitXor: Op := iroXor;
            aoShiftLeft: Op := iroShl;
            aoShiftRight: if AExpression.CType.IsUnsigned then Op := iroLShr
                          else Op := iroAShr;
          else
            Op := iroOpaque;
          end;
          if Op = iroOpaque then
            MarkOpaque('unsupported compound assignment', AExpression.Pos, False)
          else
          begin
            Value := FBuilder.EmitBinary(Op, OldValue, Value,
              IRResultType, AExpression.Pos);
            Inc(FStats.InstructionsCreated);
          end;
        end;
        FBuilder.EmitStore(Value, AddressValue,
          CTypeAlign(AExpression.Left.CType),
          AExpression.Left.CType.IsVolatile, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
        Result := Value;
      end;
    ekAddress:
      Result := LowerLValue(AExpression.Left);
    ekDeref, ekIndex, ekMember, ekArrow:
      begin
        AddressValue := LowerLValue(AExpression);
        Result := FBuilder.EmitLoad(AddressValue, IRResultType,
          CTypeAlign(AExpression.CType), AExpression.CType.IsVolatile,
          AExpression.Pos);
        Inc(FStats.InstructionsCreated);
      end;
    ekPreInc, ekPreDec, ekPostInc, ekPostDec:
      begin
        AddressValue := LowerLValue(AExpression.Left);
        OldValue := FBuilder.EmitLoad(AddressValue, IRResultType,
          CTypeAlign(AExpression.CType), AExpression.CType.IsVolatile,
          AExpression.Pos);
        Inc(FStats.InstructionsCreated);
        OneValue := FBuilder.EmitConstant(1, IRResultType, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
        if AExpression.Kind in [ekPreInc, ekPostInc] then Op := iroAdd
        else Op := iroSub;
        Value := FBuilder.EmitBinary(Op, OldValue, OneValue,
          IRResultType, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
        FBuilder.EmitStore(Value, AddressValue, CTypeAlign(AExpression.CType),
          AExpression.CType.IsVolatile, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
        if AExpression.Kind in [ekPostInc, ekPostDec] then Result := OldValue
        else Result := Value;
      end;
    ekCall:
      begin
        if AExpression.Text = '' then
        begin
          I := FBuilder.Emit(iroCall, IRResultType, AExpression.Pos,
            'indirect.call');
          I.Symbol := '';
          I.AddOperand(LowerExpression(AExpression.Left));
          for N := 0 to High(AExpression.Args) do
            I.AddOperand(LowerExpression(AExpression.Args[N]));
          Result := I.ResultValue;
        end
        else
        begin
          SetLength(Args, Length(AExpression.Args));
          for N := 0 to High(AExpression.Args) do
            Args[N] := LowerExpression(AExpression.Args[N]);
          Result := FBuilder.EmitCall(AExpression.Text, Args,
            IRResultType, AExpression.Pos);
        end;
        Inc(FStats.InstructionsCreated);
      end;
    ekConditional:
      begin


        L := LowerBoolean(AExpression.Left);
        if (AExpression.Right <> nil) and (AExpression.Third <> nil) then
        begin
          R := LowerExpression(AExpression.Right);
          T := LowerExpression(AExpression.Third);
          SelectInstruction := FBuilder.Emit(iroSelect, IRResultType,
            AExpression.Pos);
          SelectInstruction.AddOperand(L);
          SelectInstruction.AddOperand(R);
          SelectInstruction.AddOperand(T);
          Result := SelectInstruction.ResultValue;
          Inc(FStats.InstructionsCreated);
        end
        else
          MarkOpaque('malformed conditional expression', AExpression.Pos, False);
      end;
    ekCast:
      begin
        L := LowerExpression(AExpression.Left);
        if IRTypeIsFloat(IRResultType) then
        begin
          if IRTypeIsFloat(FFunction.ValueType(L)) then
          begin
            if IRResultType.Bits > FFunction.ValueType(L).Bits then Op := iroFPExt
            else if IRResultType.Bits < FFunction.ValueType(L).Bits then Op := iroFPTrunc
            else Op := iroBitCast;
          end
          else if FFunction.ValueType(L).Signed then Op := iroSIToFP
          else Op := iroUIToFP;
        end
        else if IRTypeIsFloat(FFunction.ValueType(L)) then
        begin
          if IRResultType.Signed then Op := iroFPToSI else Op := iroFPToUI;
        end
        else case IRResultType.Kind of
          irtPointer:
            if FFunction.ValueType(L).Kind = irtPointer then Op := iroBitCast
            else Op := iroIntToPtr;
          irtI1, irtI8, irtI16, irtI32, irtI64:
            if FFunction.ValueType(L).Kind = irtPointer then Op := iroPtrToInt
            else if IRResultType.Bits < FFunction.ValueType(L).Bits then Op := iroTrunc
            else if IRResultType.Bits > FFunction.ValueType(L).Bits then
              if FFunction.ValueType(L).Signed then Op := iroSExt
              else Op := iroZExt
            else Op := iroBitCast;
        else
          Op := iroBitCast;
        end;
        Result := FBuilder.EmitUnary(Op, L, IRResultType, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
      end;
    ekComma:
      begin
        LowerExpression(AExpression.Left);
        Result := LowerExpression(AExpression.Right);
      end;
    ekSizeof:
      begin
        Result := FBuilder.EmitConstant(AExpression.IntValue,
          IRResultType, AExpression.Pos);
        Inc(FStats.InstructionsCreated);
      end;
    ekCompoundLit:
      begin
        MarkOpaque('compound literal retained for legacy AST code generation', AExpression.Pos, False);
        Result := FBuilder.Emit(iroUndef, IRResultType, AExpression.Pos).ResultValue;
        Inc(FStats.InstructionsCreated);
      end;
  else
    begin
      MarkOpaque('unknown expression kind', AExpression.Pos, False);
      Result := FBuilder.Emit(iroUndef, IRResultType, AExpression.Pos).ResultValue;
      Inc(FStats.InstructionsCreated);
    end;
  end;
end;

procedure TIRLowerer.LowerStatement(AStatement: TStmt);
var
  I, SavedLocalCount: LongInt;
  AddressValue, InitValue, Condition: TIRValue;
  ThenBlock, ElseBlock, MergeBlock, HeaderBlock, BodyBlock,
    ContinueBlock, ExitBlock, LabelBlock: TIRBasicBlock;
  BreakID, ContinueID: TIRBlockID;
  AllocaInstruction: TIRInstruction;
begin
  if (AStatement = nil) or (FCurrentBlock = nil) then Exit;
  if FCurrentBlock.IsTerminated and not
     (AStatement.Kind in [skLabel, skCase, skDefault]) then Exit;
  case AStatement.Kind of
    skEmpty, skAsm: ;
    skExpr:
      LowerExpression(AStatement.Expr);
    skDecl:
      begin
        AllocaInstruction := FBuilder.Emit(iroAlloca, IRPointerType,
          AStatement.Pos, AStatement.Name + '.addr');
        AllocaInstruction.UnsignedImmediate := CTypeSize(AStatement.CType);
        AllocaInstruction.Alignment := CTypeAlign(AStatement.CType);
        AddressValue := AllocaInstruction.ResultValue;
        Inc(FStats.InstructionsCreated);
        AddLocal(AStatement.Name, AddressValue, CTypeToIRType(AStatement.CType));
        if AStatement.Expr <> nil then
        begin
          InitValue := LowerExpression(AStatement.Expr);
          FBuilder.EmitStore(InitValue, AddressValue,
            CTypeAlign(AStatement.CType), AStatement.CType.IsVolatile,
            AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
      end;
    skBlock:
      begin
        if AStatement.IsDeclarationGroup then
        begin
          for I := 0 to High(AStatement.Children) do
            LowerStatement(AStatement.Children[I]);
        end
        else
        begin
          SavedLocalCount := Length(FLocals);
          EnterScope;
          for I := 0 to High(AStatement.Children) do
            LowerStatement(AStatement.Children[I]);
          SetLength(FLocals, SavedLocalCount);
          LeaveScope;
        end;
      end;
    skReturn:
      begin
        if AStatement.Expr = nil then FBuilder.EmitVoidReturn(AStatement.Pos)
        else FBuilder.EmitReturn(LowerExpression(AStatement.Expr),
          AStatement.Pos);
        Inc(FStats.InstructionsCreated);
      end;
    skIf:
      begin
        ThenBlock := NewBlock('if.then');
        MergeBlock := NewBlock('if.end');
        if AStatement.ElseBody <> nil then ElseBlock := NewBlock('if.else')
        else ElseBlock := MergeBlock;
        Condition := LowerBoolean(AStatement.Expr);
        FBuilder.EmitCondBranch(Condition, ThenBlock.ID, ElseBlock.ID,
          AStatement.Pos);
        Inc(FStats.InstructionsCreated);
        SetBlock(ThenBlock);
        LowerStatement(AStatement.Body);
        if not FCurrentBlock.IsTerminated then
        begin
          FBuilder.EmitBranch(MergeBlock.ID, AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
        if AStatement.ElseBody <> nil then
        begin
          SetBlock(ElseBlock);
          LowerStatement(AStatement.ElseBody);
          if not FCurrentBlock.IsTerminated then
          begin
            FBuilder.EmitBranch(MergeBlock.ID, AStatement.Pos);
            Inc(FStats.InstructionsCreated);
          end;
        end;
        SetBlock(MergeBlock);
      end;
    skWhile:
      begin
        HeaderBlock := NewBlock('while.cond');
        BodyBlock := NewBlock('while.body');
        ExitBlock := NewBlock('while.end');
        FBuilder.EmitBranch(HeaderBlock.ID, AStatement.Pos);
        Inc(FStats.InstructionsCreated);
        SetBlock(HeaderBlock);
        Condition := LowerBoolean(AStatement.Expr);
        FBuilder.EmitCondBranch(Condition, BodyBlock.ID, ExitBlock.ID,
          AStatement.Pos);
        Inc(FStats.InstructionsCreated);
        PushBreak(ExitBlock.ID);
        PushContinue(HeaderBlock.ID);
        SetBlock(BodyBlock);
        LowerStatement(AStatement.Body);
        if not FCurrentBlock.IsTerminated then
        begin
          FBuilder.EmitBranch(HeaderBlock.ID, AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
        PopContinue;
        PopBreak;
        SetBlock(ExitBlock);
      end;
    skDoWhile:
      begin
        BodyBlock := NewBlock('do.body');
        ContinueBlock := NewBlock('do.cond');
        ExitBlock := NewBlock('do.end');
        FBuilder.EmitBranch(BodyBlock.ID, AStatement.Pos);
        Inc(FStats.InstructionsCreated);
        PushBreak(ExitBlock.ID);
        PushContinue(ContinueBlock.ID);
        SetBlock(BodyBlock);
        LowerStatement(AStatement.Body);
        if not FCurrentBlock.IsTerminated then
        begin
          FBuilder.EmitBranch(ContinueBlock.ID, AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
        SetBlock(ContinueBlock);
        Condition := LowerBoolean(AStatement.Expr);
        FBuilder.EmitCondBranch(Condition, BodyBlock.ID, ExitBlock.ID,
          AStatement.Pos);
        Inc(FStats.InstructionsCreated);
        PopContinue;
        PopBreak;
        SetBlock(ExitBlock);
      end;
    skFor:
      begin
        if AStatement.InitStmt <> nil then LowerStatement(AStatement.InitStmt);
        HeaderBlock := NewBlock('for.cond');
        BodyBlock := NewBlock('for.body');
        ContinueBlock := NewBlock('for.step');
        ExitBlock := NewBlock('for.end');
        FBuilder.EmitBranch(HeaderBlock.ID, AStatement.Pos);
        Inc(FStats.InstructionsCreated);
        SetBlock(HeaderBlock);
        if AStatement.Expr = nil then
          Condition := FBuilder.EmitConstant(1, IRBoolType, AStatement.Pos)
        else
          Condition := LowerBoolean(AStatement.Expr);
        FBuilder.EmitCondBranch(Condition, BodyBlock.ID, ExitBlock.ID,
          AStatement.Pos);
        Inc(FStats.InstructionsCreated);
        PushBreak(ExitBlock.ID);
        PushContinue(ContinueBlock.ID);
        SetBlock(BodyBlock);
        LowerStatement(AStatement.Body);
        if not FCurrentBlock.IsTerminated then
        begin
          FBuilder.EmitBranch(ContinueBlock.ID, AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
        SetBlock(ContinueBlock);
        if AStatement.Expr2 <> nil then LowerExpression(AStatement.Expr2);
        if not FCurrentBlock.IsTerminated then
        begin
          FBuilder.EmitBranch(HeaderBlock.ID, AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
        PopContinue;
        PopBreak;
        SetBlock(ExitBlock);
      end;
    skBreak:
      begin
        BreakID := CurrentBreak;
        if BreakID < 0 then MarkOpaque('break outside loop/switch',
          AStatement.Pos, True)
        else
        begin
          FBuilder.EmitBranch(BreakID, AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
      end;
    skContinue:
      begin
        ContinueID := CurrentContinue;
        if ContinueID < 0 then MarkOpaque('continue outside loop',
          AStatement.Pos, True)
        else
        begin
          FBuilder.EmitBranch(ContinueID, AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
      end;
    skGoto:
      begin
        FBuilder.EmitBranch(RequireLabel(AStatement.Name), AStatement.Pos);
        Inc(FStats.InstructionsCreated);
      end;
    skLabel:
      begin
        LabelBlock := FFunction.BlockByID(RequireLabel(AStatement.Name));
        if not FCurrentBlock.IsTerminated then
        begin
          FBuilder.EmitBranch(LabelBlock.ID, AStatement.Pos);
          Inc(FStats.InstructionsCreated);
        end;
        SetBlock(LabelBlock);
        LowerStatement(AStatement.Body);
      end;
    skSwitch, skCase, skDefault:
      MarkOpaque('switch lowering is preserved in typed AST backend',
        AStatement.Pos, True);
  else
    MarkOpaque('unknown statement kind', AStatement.Pos, True);
  end;
end;

procedure TIRLowerer.LowerFunction(AFunction: TFunction);
var
  I: LongInt;
  Entry: TIRBasicBlock;
  ParamValue, AddressValue: TIRValue;
  AllocaInstruction: TIRInstruction;
begin



  if AFunction.IsPrototype or (AFunction.Body = nil) then Exit;
  FFunction := TIRFunction.Create(AFunction.Name,
    CTypeToIRType(AFunction.ReturnType));
  FFunction.Position := AFunction.Pos;
  FFunction.Variadic := AFunction.IsVariadic;
  if AFunction.IsStatic then FFunction.Linkage := irlInternal
  else FFunction.Linkage := irlExternal;
  FModule.AddFunction(FFunction);
  Inc(FStats.FunctionsLowered);
  FBuilder.Free;
  FBuilder := TIRBuilder.Create(FFunction);
  SetLength(FLocals, 0);
  SetLength(FBreakBlocks, 0);
  SetLength(FContinueBlocks, 0);
  SetLength(FLabels, 0);
  FScopeDepth := 0;
  Entry := NewBlock('entry');
  SetBlock(Entry);
  for I := 0 to High(AFunction.Params) do
  begin
    ParamValue := FFunction.AddParameter(AFunction.Params[I].Name,
      CTypeToIRType(AFunction.Params[I].CType));
    AllocaInstruction := FBuilder.Emit(iroAlloca, IRPointerType,
      AFunction.Pos, AFunction.Params[I].Name + '.addr');
    AllocaInstruction.UnsignedImmediate := CTypeSize(AFunction.Params[I].CType);
    AllocaInstruction.Alignment := CTypeAlign(AFunction.Params[I].CType);
    AddressValue := AllocaInstruction.ResultValue;
    Inc(FStats.InstructionsCreated);
    AddLocal(AFunction.Params[I].Name, AddressValue,
      CTypeToIRType(AFunction.Params[I].CType));
    FBuilder.EmitStore(ParamValue, AddressValue,
      CTypeAlign(AFunction.Params[I].CType), False, AFunction.Pos);
    Inc(FStats.InstructionsCreated);
  end;
  ReserveLabels(AFunction.Body);
  LowerStatement(AFunction.Body);
  if not FCurrentBlock.IsTerminated then
  begin
    if FFunction.ReturnType.Kind = irtVoid then
      FBuilder.EmitVoidReturn(AFunction.Pos)
    else
      FBuilder.EmitReturn(FBuilder.EmitConstant(0, FFunction.ReturnType,
        AFunction.Pos), AFunction.Pos);
    Inc(FStats.InstructionsCreated);
  end;
  FFunction := nil;
  FCurrentBlock := nil;
end;

procedure TIRLowerer.LowerGlobal(AGlobal: TGlobal);
var
  G: TIRGlobal;
  V: Int64;
  I, Size: LongInt;
begin


  if AGlobal.IsExtern and not AGlobal.HasInitializer then Exit;
  G := TIRGlobal.Create;
  G.Name := AGlobal.Name;
  G.ValueType := CTypeToIRType(AGlobal.CType);
  if AGlobal.IsStatic then G.Linkage := irlInternal
  else if AGlobal.IsExtern then G.Linkage := irlExternal
  else G.Linkage := irlExternal;
  G.Visibility := irvDefault;
  G.Alignment := CTypeAlign(AGlobal.CType);
  G.IsConstant := AGlobal.CType.IsConst;
  G.IsThreadLocal := False;
  G.Position := AGlobal.Pos;
  Size := LongInt(CTypeSize(AGlobal.CType));
  if Size < 0 then Size := 0;
  G.ZeroFillSize := QWord(Size);
  if AGlobal.HasInitializer and (AGlobal.Initializer <> nil) and
     (AGlobal.Initializer.Kind = ekInteger) then
  begin
    V := AGlobal.Initializer.IntValue;
    SetLength(G.ConstantData, Size);
    for I := 0 to Size - 1 do
      if I < 8 then G.ConstantData[I] := Byte(QWord(V) shr (I * 8))
      else G.ConstantData[I] := 0;
    G.ZeroFillSize := 0;
  end;
  FModule.AddGlobal(G);
  Inc(FStats.GlobalsLowered);
end;

function TIRLowerer.Lower: TIRModule;
var
  I: LongInt;
begin
  for I := 0 to High(FProgram.Globals) do LowerGlobal(FProgram.Globals[I]);
  for I := 0 to High(FProgram.Functions) do LowerFunction(FProgram.Functions[I]);
  Result := FModule;
  FModule := nil;
end;

function LowerProgramToIR(AProgram: TProgram; const ATargetTriple: string;
  out AStats: TIRLoweringStats): TIRModule;
var
  Lowerer: TIRLowerer;
begin
  Lowerer := TIRLowerer.Create(AProgram, ATargetTriple);
  try
    Result := Lowerer.Lower;
    AStats := Lowerer.Stats;
  finally
    Lowerer.Free;
  end;
end;

end.
