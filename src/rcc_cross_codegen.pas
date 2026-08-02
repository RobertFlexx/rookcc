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
  rcc_typeops, rcc_elf_image, rcc_object_model;

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
    CType: TCType;
    IsStatic: Boolean;
  end;

  TCrossGlobalFixup = record
    PatchOffset: LongInt;
    GlobalIndex: LongInt;
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
    FGlobalFixups: array of TCrossGlobalFixup;
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
    function FindGlobal(const AName: string; out AIndex: LongInt;
      out AType: TCType): Boolean;
    procedure EmitGlobalAddress(AGlobalIndex: LongInt);
    procedure ResolveGlobalFixups(ADataAddress: QWord);
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

procedure TCrossIntegerBackend.AllocateGlobals;
var
  I, N, Size, J: LongInt;
  Value: Int64;
  Global: TGlobal;
begin
  for I := 0 to High(FProgram.Globals) do
  begin
    Global := FProgram.Globals[I];
    if Global.IsExtern then Continue;
    RequireScalar(Global.CType, Global.Pos, 'global variable');
    Size := StorageSize(Global.CType);
    FData.PadTo(StorageAlign(Global.CType));
    N := Length(FGlobals);
    SetLength(FGlobals, N + 1);
    FGlobals[N].Name := Global.Name;
    FGlobals[N].Offset := FData.Size;
    FGlobals[N].CType := Global.CType;
    FGlobals[N].IsStatic := Global.IsStatic;
    Value := 0;
    if (Global.Initializer <> nil) and
       not EvaluateIntegerConstantExpression(Global.Initializer, Value) then
      RaiseCompileError(Global.Pos,
        'cross-target global initializer must be an integer constant expression');
    Value := ConvertIntegerValue(Value, Global.CType);
    for J := 0 to Size - 1 do
      FData.Add8(Byte(QWord(Value) shr (J * 8)));
  end;
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
  N := Length(FGlobalFixups);
  SetLength(FGlobalFixups, N + 1);
  FGlobalFixups[N].PatchOffset := P;
  FGlobalFixups[N].GlobalIndex := AGlobalIndex;
end;

procedure TCrossIntegerBackend.ResolveGlobalFixups(ADataAddress: QWord);
var
  I, P, Shift: LongInt;
  Address: QWord;
  High20, Low12: Int64;
begin
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
  N: LongInt;
begin
  RequireScalar(AType, Default(TSourcePos), 'local variable');
  AOffset := FNextLocalOffset;
  Inc(FNextLocalOffset, 8);
  if FNextLocalOffset > FFrameSize then
    raise ERCCError.Create('internal error: cross-target frame estimate is too small');
  N := Length(FLocals);
  SetLength(FLocals, N + 1);
  FLocals[N].Name := AName;
  FLocals[N].Offset := AOffset;
  FLocals[N].CType := AType;
  FLocals[N].ScopeDepth := FScopeDepth;
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

procedure TCrossIntegerBackend.EmitLoadImmediate(AValue: Int64);
var
  Part: LongWord;
  Shift: LongInt;
  First: Boolean;
  Instruction: LongWord;
  High20, Low12: Int64;
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
  if (AValue < Low(LongInt)) or (AValue > High(LongInt)) then
    raise ERCCError.Create(
      'error: RISC-V integer code generation requires a signed 32-bit constant');
  High20 := (AValue + $800) shr 12;
  Low12 := AValue - (High20 shl 12);
  EmitWord((LongWord(High20) and $FFFFF) shl 12 or (10 shl 7) or $37);
  EmitWord(EncodeRISCVI(LongInt(Low12), 10, 0, 10, $13));
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

procedure TCrossIntegerBackend.GenAssignment(AExpression: TExpr);
var
  Offset, GlobalIndex: LongInt;
  LocalType: TCType;
  Operation: TBinaryOp;
  IsLocal: Boolean;
begin
  if (AExpression.Left = nil) or (AExpression.Left.Kind <> ekVariable) then
    RaiseCompileError(AExpression.Pos,
      'cross-target assignment requires a scalar variable');
  IsLocal := FindLocal(AExpression.Left.Text, Offset, LocalType);
  if not IsLocal and
     not FindGlobal(AExpression.Left.Text, GlobalIndex, LocalType) then
    RaiseCompileError(AExpression.Pos,
      'cross-target assignment has no storage for ''' +
      AExpression.Left.Text + '''');
  if AExpression.AssignOp = aoAssign then
    GenExpr(AExpression.Right)
  else
  begin
    if IsLocal then EmitLoadLocal(Offset)
    else EmitLoadGlobal(GlobalIndex, LocalType);
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
    EmitBinary(Operation, LocalType.IsUnsigned);
  end;
  EmitNormalize(LocalType);
  if IsLocal then EmitStoreLocal(Offset)
  else EmitStoreGlobal(GlobalIndex, LocalType);
end;

procedure TCrossIntegerBackend.GenIncDec(AExpression: TExpr;
  ADelta: LongInt; APost: Boolean);
var
  Offset, GlobalIndex: LongInt;
  LocalType: TCType;
  IsLocal: Boolean;
begin
  if (AExpression.Left = nil) or (AExpression.Left.Kind <> ekVariable) then
    RaiseCompileError(AExpression.Pos,
      'cross-target increment requires a scalar variable');
  IsLocal := FindLocal(AExpression.Left.Text, Offset, LocalType);
  if not IsLocal and
     not FindGlobal(AExpression.Left.Text, GlobalIndex, LocalType) then
    RaiseCompileError(AExpression.Pos,
      'cross-target increment has no storage for ''' +
      AExpression.Left.Text + '''');
  if IsLocal then EmitLoadLocal(Offset)
  else EmitLoadGlobal(GlobalIndex, LocalType);
  if APost then EmitPushResult;
  EmitAddImmediate(ADelta);
  EmitNormalize(LocalType);
  if IsLocal then EmitStoreLocal(Offset)
  else EmitStoreGlobal(GlobalIndex, LocalType);
  if APost then
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
end;

procedure TCrossIntegerBackend.GenExpr(AExpression: TExpr);
var
  I, Offset, GlobalIndex, FalseLabel, EndLabel, FunctionLabel: LongInt;
  LocalType, OperationType: TCType;
  UnsignedOperation: Boolean;
begin
  if AExpression = nil then
  begin EmitLoadImmediate(0); Exit; end;
  RequireScalar(AExpression.CType, AExpression.Pos, 'cross-target expression');
  case AExpression.Kind of
    ekInteger: EmitLoadImmediate(AExpression.IntValue);
    ekVariable:
      begin
        if FindLocal(AExpression.Text, Offset, LocalType) then
          EmitLoadLocal(Offset)
        else if FindGlobal(AExpression.Text, GlobalIndex, LocalType) then
          EmitLoadGlobal(GlobalIndex, LocalType)
        else
          RaiseCompileError(AExpression.Pos,
            'cross-target scalar variable has no definition: ' +
            AExpression.Text);
        EmitNormalize(AExpression.CType);
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
        GenExpr(AExpression.Left);
        EmitPushResult;
        GenExpr(AExpression.Right);
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
        EmitNormalize(AExpression.CType);
      end;
    ekAssign: GenAssignment(AExpression);
    ekCall:
      begin
        if AExpression.Text = '' then
          RaiseCompileError(AExpression.Pos,
            'cross-target function-pointer calls require the native x86 backend');
        if Length(AExpression.Args) > 8 then
          RaiseCompileError(AExpression.Pos,
            'cross-target integer calls support up to eight register arguments');
        for I := High(AExpression.Args) downto 0 do
        begin
          GenExpr(AExpression.Args[I]);
          EmitPushResult;
        end;
        for I := 0 to High(AExpression.Args) do EmitPopArgument(I);
        FunctionLabel := FindFunctionLabel(AExpression.Text);
        if FunctionLabel < 0 then
          RaiseCompileError(AExpression.Pos,
            'undefined cross-target function ''' + AExpression.Text + '''');
        EmitCall(FunctionLabel);
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
    BodyLabel, ContinueLabel: LongInt;
begin
  if AStatement = nil then Exit;
  case AStatement.Kind of
    skEmpty, skStaticAssert: ;
    skExpr: GenExpr(AStatement.Expr);
    skDecl:
      begin
        AddLocal(AStatement.Name, AStatement.CType, Offset);
        if AStatement.Expr <> nil then GenExpr(AStatement.Expr)
        else EmitLoadImmediate(0);
        EmitNormalize(AStatement.CType);
        EmitStoreLocal(Offset);
      end;
    skReturn:
      begin
        if AStatement.Expr <> nil then GenExpr(AStatement.Expr)
        else EmitLoadImmediate(0);
        EmitNormalize(FCurrentReturnType);
        EmitJump(FEpilogueLabel);
      end;
    skBlock:
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
  I, Offset, LocalBytes: LongInt;
begin
  RequireScalar(AFunction.ReturnType, AFunction.Pos, 'function return');
  FCurrentReturnType := AFunction.ReturnType;
  if AFunction.IsVariadic then
    RaiseCompileError(AFunction.Pos,
      'variadic functions require a hosted target backend');
  if Length(AFunction.Params) > 8 then
    RaiseCompileError(AFunction.Pos,
      'cross-target integer functions support up to eight parameters');
  LocalBytes := (Length(AFunction.Params) +
    CountDeclarations(AFunction.Body)) * 8;
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
  SetLength(FLocals, 0);
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

  for I := 0 to High(AFunction.Params) do
  begin
    RequireScalar(AFunction.Params[I].CType, AFunction.Pos,
      'function parameter');
    AddLocal(AFunction.Params[I].Name, AFunction.Params[I].CType, Offset);
    if FTarget.Architecture = archAArch64 then
    begin
      if I <> 0 then
        EmitWord($AA0003E0 or (LongWord(I) shl 16));
    end
    else if I <> 0 then
      EmitWord(EncodeRISCVI(0, 10 + I, 0, 10, $13));
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
  MainLabel: LongInt;
begin
  MainLabel := FindFunctionLabel('main');
  if MainLabel < 0 then
    raise ERCCError.Create('error: no main function was defined');
  EmitCall(MainLabel);
  if FTarget.Architecture = archAArch64 then
  begin
    EmitWord($D2800BA8);
    EmitWord($D4000001);
  end
  else
  begin
    EmitWord(EncodeRISCVI(93, 0, 0, 17, $13));
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
    I, L, GlobalIndex: LongInt;
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
          QWord(StorageSize(FGlobals[I].CType)), True);
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
          QWord(StorageSize(FGlobals[I].CType)), True);
    for I := 0 to High(FGlobalFixups) do
    begin
      GlobalIndex := FGlobalFixups[I].GlobalIndex;
      if FTarget.Architecture = archAArch64 then
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
    Obj.Section(TextIndex).Data.Append(FText);
    Obj.Section(DataIndex).Data.Append(FData);
    Obj.Validate;
    WriteELF64Relocatable(AFileName, Obj);
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
  WriteStaticELF64Executable(AFileName, FTarget, FText, FData, 0);
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
