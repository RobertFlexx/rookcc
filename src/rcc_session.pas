unit rcc_session;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;

function CompileWithOptions(const AOptions: TCompilerOptions): LongInt;

implementation

uses
  Classes, SysUtils, rcc_frontend, rcc_opt, rcc_backend,
  rcc_verify, rcc_build, rcc_target, rcc_diag, rcc_feature_policy,
  rcc_sema, rcc_arch, rcc_cross_backend, rcc_pass_manager, rcc_ir,
  rcc_ir_verify, rcc_ir_metrics, rcc_platform, rcc_gnu_tokens,
  rcc_native_linker;

procedure AppendString(var AValues: rcc_types.TStringArray; const AValue: string);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

procedure AppendUniqueString(var AValues: rcc_types.TStringArray; const AValue: string);
var
  I: LongInt;
begin
  for I := 0 to High(AValues) do
    if AValues[I] = AValue then Exit;
  AppendString(AValues, AValue);
end;

function EscapeMakeWord(const AValue: string): string;
var
  I: LongInt;
begin
  Result := '';
  for I := 1 to Length(AValue) do
    case AValue[I] of
      ' ', #9, '#', ':': Result := Result + '\' + AValue[I];
      '$': Result := Result + '$$';
      '\': Result := Result + '\\';
    else
      Result := Result + AValue[I];
    end;
end;

function DependencyTarget(const AOptions: TCompilerOptions): string;
begin
  if AOptions.DependencyTarget <> '' then Exit(AOptions.DependencyTarget);
  if AOptions.EmitMode = emObject then Exit(AOptions.OutputFile);
  if Length(AOptions.Inputs) = 1 then
    Exit(ChangeFileExt(ExtractFileName(AOptions.Inputs[0]), '.o'));
  Result := AOptions.OutputFile;
  if Result = 'a.out' then Result := 'rcc-output';
end;

function BuildDependencyText(const AOptions: TCompilerOptions;
  const ADependencies: rcc_types.TStringArray): string;
var
  Lines: TStringList;
  I: LongInt;
  Line: string;
begin
  Lines := TStringList.Create;
  try
    Line := EscapeMakeWord(DependencyTarget(AOptions)) + ':';
    for I := 0 to High(ADependencies) do
    begin
      if Length(Line) + Length(ADependencies[I]) > 78 then
      begin
        Lines.Add(Line + ' \');
        Line := '  ';
      end;
      Line := Line + ' ' + EscapeMakeWord(ADependencies[I]);
    end;
    Lines.Add(Line);
    if AOptions.PhonyDependencies then
      for I := 1 to High(ADependencies) do
        Lines.Add(EscapeMakeWord(ADependencies[I]) + ':');
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure WriteDependencyOutput(const AOptions: TCompilerOptions;
  const ADependencies: rcc_types.TStringArray; ADependencyOnly: Boolean);
var
  Text, FileName: string;
  Lines: TStringList;
begin
  Text := BuildDependencyText(AOptions, ADependencies);
  if ADependencyOnly then
  begin
    if AOptions.OutputFile = 'a.out' then
    begin
      Write(Text);
      Exit;
    end;
    FileName := AOptions.OutputFile;
  end
  else
    FileName := AOptions.DependencyFile;
  if FileName = '' then Exit;
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    Lines.SaveToFile(FileName);
  finally
    Lines.Free;
  end;
end;

function CombinedIncludePaths(const AOptions: TCompilerOptions): rcc_types.TStringArray;
var
  I: LongInt;
begin
  Result := nil;
  for I := 0 to High(AOptions.QuoteIncludePaths) do
    AppendString(Result, AOptions.QuoteIncludePaths[I]);
  for I := 0 to High(AOptions.IncludePaths) do
    AppendString(Result, AOptions.IncludePaths[I]);
  for I := 0 to High(AOptions.SystemIncludePaths) do
    AppendString(Result, AOptions.SystemIncludePaths[I]);
end;

procedure MergeProgram(ADestination, ASource: TProgram);
var
  I, N: LongInt;
begin
  ADestination.MoveTypeStorageFrom(ASource);
  for I := 0 to High(ASource.Functions) do
  begin
    N := Length(ADestination.Functions);
    SetLength(ADestination.Functions, N + 1);
    ADestination.Functions[N] := ASource.Functions[I];
    ASource.Functions[I] := nil;
  end;
  for I := 0 to High(ASource.Globals) do
  begin
    N := Length(ADestination.Globals);
    SetLength(ADestination.Globals, N + 1);
    ADestination.Globals[N] := ASource.Globals[I];
    ASource.Globals[I] := nil;
  end;
  for I := 0 to High(ASource.StaticAssertions) do
  begin
    N := Length(ADestination.StaticAssertions);
    SetLength(ADestination.StaticAssertions, N + 1);
    ADestination.StaticAssertions[N] := ASource.StaticAssertions[I];
    ASource.StaticAssertions[I] := nil;
  end;
end;

procedure DumpTokens(const ATokens: TTokenArray; ALines: TStrings);
var
  I: LongInt;
begin
  for I := 0 to High(ATokens) do
  begin
    if ATokens[I].Kind = tkEOF then Break;
    ALines.Add(Format('%s:%d:%d  %-18s %s', [ATokens[I].Pos.FileName,
      ATokens[I].Pos.Line, ATokens[I].Pos.Column,
      TokenKindName(ATokens[I].Kind), ATokens[I].Text]));
  end;
end;

procedure ValidateDriverCapabilities(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor);
var
  NativeLink: Boolean;
begin
  NativeLink := NeedsNativePlatformLink(AOptions, ATarget);
  if (AOptions.EmitMode = emExecutable) and
     not TargetHasCapability(ATarget, tcExecutable) and not NativeLink then
  begin
    if ATarget.ObjectFormat = ofMachO64 then
    begin
      if TargetMatchesNativeHost(ATarget) then
        raise ERCCError.Create(
          'error: native macOS executable linking is a hosted operation; ' +
          'remove -ffreestanding or emit a Mach-O object with -c')
      else
        raise ERCCError.Create(
          'error: cross-target macOS executable linking requires an Apple SDK; ' +
          'emit a Mach-O object with -c, then link it on macOS or with a ' +
          'configured cross toolchain');
    end;
    raise ERCCError.Create('error: target does not support executable output');
  end;
  if (AOptions.EmitMode = emObject) and
     not TargetHasCapability(ATarget, tcRelocatableObject) then
    raise ERCCError.Create('error: target does not support relocatable objects');
  if AOptions.RunAfterCompile and not TargetMatchesNativeHost(ATarget) then
    raise ERCCError.Create(
      'error: -run requires a target matching the host architecture and OS; cross-target ' +
      'outputs must be copied to or emulated on their target system');
  if AOptions.PositionIndependent and not
     (((AOptions.EmitMode = emObject) or NativeLink) and
      ((ATarget.Architecture = archX86_64) or
       (ATarget.ObjectFormat = ofMachO64))) then
    raise ERCCError.Create(
      'error: PIC is supported for x86-64 and Mach-O relocatable objects; ' +
      'PIE executable output is unavailable, so use -c or remove ' +
      '-fPIC/-fPIE/-pie');
  if (AOptions.DynamicLinker <> '') and
     not TargetHasCapability(ATarget, tcDynamicELF) and not NativeLink then
    raise ERCCError.Create(
      'error: dynamic-linker options are unavailable for ' +
      ATarget.Triple + '; use a target linker after emitting an object with -c');
  if (Length(AOptions.RPaths) <> 0) and
     not TargetHasCapability(ATarget, tcDynamicELF) and not NativeLink then
    raise ERCCError.Create(
      'error: runpath options are unavailable for ' + ATarget.Triple +
      '; use a target linker after emitting an object with -c');
  if AOptions.BindNow and (ATarget.ObjectFormat = ofMachO64) then
    raise ERCCError.Create(
      'error: ELF -z now linking is unavailable for Mach-O targets');
  if AOptions.DebugInfo and not
     ((ATarget.Architecture = archX86_64) and
      (ATarget.ObjectFormat = ofELF64) and
      (AOptions.EmitMode in [emObject, emExecutable])) then
    raise ERCCError.Create(
      'error: -g currently emits ELF DWARF for x86-64 objects and ' +
      'executables; Mach-O and cross-architecture debug data are unavailable');
  if AOptions.SharedOutput then
    raise ERCCError.Create(
      'error: -shared output is unsupported; rcc links native ELF shared libraries into x86-64 executables');
  if AOptions.StaticLink and NativeLink and
     (ATarget.OperatingSystem = osDarwin) then
    raise ERCCError.Create(
      'error: native macOS does not provide a static system executable link; ' +
      'remove -static');
  if (Length(AOptions.Libraries) > 0) and not NativeLink and
     not ((ATarget.Architecture = archX86_64) and
       (ATarget.OperatingSystem = osLinux)) then
    raise ERCCError.Create(
      'error: cross-target library linking requires a target linker; ' +
      'emit an object with -c and link it with the target sysroot');
  if (Length(AOptions.ObjectFiles) > 0) and not NativeLink and
     not ((ATarget.Architecture = archX86_64) and
       (ATarget.OperatingSystem = osLinux)) then
    raise ERCCError.Create(
      'error: cross-target object and archive linking requires a target linker; ' +
      'use -c for source compilation and finish the link on the target system');
  if (Length(AOptions.ObjectFiles) > 0) and
     (AOptions.EmitMode <> emExecutable) then
    raise ERCCError.Create(
      'error: relocatable-object and archive inputs require executable output');
  if not TargetHasCapability(ATarget, tcHostedLibC) and
     not AOptions.Freestanding and
     (AOptions.EmitMode = emExecutable) and not NativeLink then
    raise ERCCError.Create(
      'error: hosted cross-target executable linking is unavailable for ' +
      ATarget.Triple + '; use -c with a target linker, or add -ffreestanding ' +
      'for a static syscall-only executable');
  if ((ATarget.Architecture <> archX86_64) or
      (ATarget.ObjectFormat = ofMachO64)) and
     (AOptions.EmitMode = emAssembly) then
    raise ERCCError.Create(
      'error: this target does not provide a textual machine-code listing; ' +
      'emit an executable or relocatable object');
end;

procedure PrintDryRun(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor);
var
  I: LongInt;
begin
  WriteLn('rcc internal pipeline');
  WriteLn('  standard: ', CStandardName(AOptions.Standard));
  WriteLn('  target:   ', ATarget.Triple);
  WriteLn('  cpu:      ', AOptions.TargetCPU);
  WriteLn('  features: ', AOptions.TargetFeatures);
  WriteLn('  optimize: O', AOptions.OptimizationLevel);
  WriteLn('  frontend: internal preprocessor -> lexer -> parser -> semantic analysis');
  WriteLn('  middle:   typed AST -> linear IR -> CFG -> optimization -> liveness');
  if ATarget.Architecture = archX86_64 then
    WriteLn('  backend:  legacy x86-64 encoder + ',
      ObjectFormatName(ATarget.ObjectFormat), ' writer (broadest path)')
  else
    WriteLn('  backend:  ', ArchitectureName(ATarget.Architecture),
      ' integer encoder -> ', ObjectFormatName(ATarget.ObjectFormat),
      ' writer');
  if NeedsNativePlatformLink(AOptions, ATarget) then
    WriteLn('  linker:   native platform driver ',
      NativePlatformLinkerName(ATarget));
  WriteLn('  output:   ', AOptions.OutputFile);
  for I := 0 to High(AOptions.Inputs) do
    WriteLn('  input:    ', AOptions.Inputs[I]);
  for I := 0 to High(AOptions.LibraryPaths) do
    WriteLn('  libpath:  ', AOptions.LibraryPaths[I]);
  for I := 0 to High(AOptions.Libraries) do
    if (Length(AOptions.Libraries[I]) > 1) and
       (AOptions.Libraries[I][1] = '@') then
      WriteLn('  library:  ', Copy(AOptions.Libraries[I], 2, MaxInt))
    else
      WriteLn('  library:  -l', AOptions.Libraries[I]);
  for I := 0 to High(AOptions.RPaths) do
    WriteLn('  runpath:  ', AOptions.RPaths[I]);
  if AOptions.DynamicLinker <> '' then
    WriteLn('  loader:   ', AOptions.DynamicLinker);
end;

function CompileWithOptions(const AOptions: TCompilerOptions): LongInt;
var
  ProgramAll, UnitProgram: TProgram;
  PP: TPreprocessor;
  Lexer: TLexer;
  Parser: TParser;
  Tokens: TTokenArray;
  OutputLines: TStringList;
  Source, TextOut: string;
  Includes, EffectiveDefines, TargetDefines, AllDependencies,
    UnitDependencies, SourceLibraries, UnitLibraries: rcc_types.TStringArray;
  I, DependencyIndex: LongInt;
  StartTime, FrontTime, VerifyTime, OptTime, IRTime, BackTime: QWord;
  OptStats: TOptimizationStats;
  Backend: TX64Backend;
  BackendStats: TBackendStats;
  CrossStats: TCrossBackendStats;
  TargetDescriptor: TTargetDescriptor;
  PassManager: TPassManager;
  IRModule: TIRModule;
  IRMetrics: TIRModuleMetrics;
  NeedFormalIR: Boolean;
  BackendOptions, LinkOptions: TCompilerOptions;
  NativeLink: Boolean;
  GeneratedObjectFile, CodegenOutputFile: string;
begin
  Result := 1;
  TargetDescriptor := GetTargetOrRaise(AOptions.TargetTriple);
  ConfigureCTypeLongDoubleLayout(
    TargetDescriptor.DataLayout.LongDoubleBits div 8,
    TargetDescriptor.DataLayout.LongDoubleAlign);
  ValidateDriverCapabilities(AOptions, TargetDescriptor);
  NativeLink := NeedsNativePlatformLink(AOptions, TargetDescriptor);
  GeneratedObjectFile := '';
  if AOptions.DryRun then
  begin
    PrintDryRun(AOptions, TargetDescriptor);
    Exit(0);
  end;
  FillChar(BackendStats, SizeOf(BackendStats), 0);
  CrossStats.TextBytes := 0;
  CrossStats.DataBytes := 0;
  CrossStats.FunctionsEmitted := 0;
  CrossStats.InstructionsEmitted := 0;
  CrossStats.Target := '';
  PassManager := nil;
  IRModule := nil;
  IRMetrics.Functions := nil;
  IRMetrics.Globals := 0;
  IRMetrics.GlobalBytes := 0;
  IRMetrics.TotalBlocks := 0;
  IRMetrics.TotalInstructions := 0;
  IRMetrics.TotalValues := 0;
  IRMetrics.TotalCalls := 0;
  IRMetrics.TotalCriticalEdges := 0;
  IRMetrics.HasOpaqueOperations := False;
  NeedFormalIR := (AOptions.EmitMode in [emIR, emCheck]) or
    AOptions.ShowStats;

  StartTime := GetTickCount64;
  Includes := CombinedIncludePaths(AOptions);
  EffectiveDefines := BuildPredefinedMacros(AOptions.Standard,
    AOptions.Freestanding);
  TargetDefines := BuildTargetPredefinedMacros(TargetDescriptor);
  for I := 0 to High(TargetDefines) do
    AppendString(EffectiveDefines, TargetDefines[I]);
  SetLength(AllDependencies, 0);
  SetLength(SourceLibraries, 0);
  for I := 0 to High(AOptions.Defines) do
    AppendString(EffectiveDefines, AOptions.Defines[I]);
  ProgramAll := TProgram.Create;
  OutputLines := TStringList.Create;
  try
    for I := 0 to High(AOptions.Inputs) do
    begin
      if AOptions.Verbose then WriteLn(StdErr, 'front  ', AOptions.Inputs[I]);
      if not FileExists(AOptions.Inputs[I]) then
        raise ERCCError.Create('error: input file not found: ' + AOptions.Inputs[I]);
      PP := TPreprocessor.Create(Includes, EffectiveDefines,
        AOptions.Undefines, AOptions.Standard);
      try
        Source := PP.ProcessFile(AOptions.Inputs[I]);
        UnitDependencies := PP.Dependencies;
        for DependencyIndex := 0 to High(UnitDependencies) do
          AppendUniqueString(AllDependencies, UnitDependencies[DependencyIndex]);
        UnitLibraries := PP.LinkLibraries;
        for DependencyIndex := 0 to High(UnitLibraries) do
          AppendUniqueString(SourceLibraries, UnitLibraries[DependencyIndex]);
      finally
        PP.Free;
      end;

      if AOptions.EmitMode = emDependencies then Continue;
      if AOptions.EmitMode = emPreprocessed then
      begin
        OutputLines.Add(Source);
        Continue;
      end;

      Lexer := TLexer.Create(Source, AOptions.Inputs[I]);
      try
        Tokens := Lexer.Tokenize;
        NormalizeGNUTokens(Tokens, AOptions.Standard);
      finally
        Lexer.Free;
      end;

      if AOptions.EmitMode = emTokens then
      begin
        DumpTokens(Tokens, OutputLines);
        Continue;
      end;

      Parser := TParser.Create(Tokens);
      try
        UnitProgram := Parser.ParseProgram;
      finally
        Parser.Free;
      end;
      try
        VerifyProgram(UnitProgram, 'frontend');
        MergeProgram(ProgramAll, UnitProgram);
      finally
        UnitProgram.Free;
      end;
    end;
    FrontTime := GetTickCount64;

    if AOptions.EmitMode = emDependencies then
    begin
      WriteDependencyOutput(AOptions, AllDependencies, True);
      Exit(0);
    end;
    if AOptions.GenerateDependencies then
      WriteDependencyOutput(AOptions, AllDependencies, False);

    if AOptions.EmitMode in [emTokens, emPreprocessed] then
    begin
      if AOptions.OutputFile = 'a.out' then Write(OutputLines.Text)
      else OutputLines.SaveToFile(AOptions.OutputFile);
      Exit(0);
    end;

    VerifyProgram(ProgramAll, 'merged frontend');
    AnalyzeProgram(ProgramAll);
    VerifyProgram(ProgramAll, 'semantic analysis');
    VerifyTime := GetTickCount64;

    if AOptions.Verbose then
      WriteLn(StdErr, 'opt    O', AOptions.OptimizationLevel,
        ' standard=', CStandardName(AOptions.Standard));
    OptimizeProgram(ProgramAll, AOptions.OptimizationLevel,
      AOptions.OptimizeSize, OptStats);
    VerifyProgram(ProgramAll, 'optimization');
    OptTime := GetTickCount64;





    if NeedFormalIR then
    begin
      PassManager := TPassManager.Create(TargetDescriptor,
        AOptions.OptimizationLevel, AOptions.OptimizeSize);
      IRModule := PassManager.Build(ProgramAll);
      VerifyIRModule(IRModule, 'formal IR');
      PassManager.RunAnalysis;
      IRMetrics := MeasureIRModule(IRModule);
      IRTime := GetTickCount64;
    end
    else
      IRTime := OptTime;

    if AOptions.EmitMode = emCheck then
    begin
      if AOptions.Verbose then WriteLn(StdErr, 'check  ok');
      Exit(0);
    end;

    if AOptions.EmitMode = emIR then
    begin
      TextOut := DumpIRModule(IRModule);
      if AOptions.OutputFile = 'a.out' then Write(TextOut)
      else
      begin
        OutputLines.Text := TextOut;
        OutputLines.SaveToFile(AOptions.OutputFile);
      end;
      Exit(0);
    end;

    if AOptions.Verbose then WriteLn(StdErr, 'code   ', TargetDescriptor.Triple);
    BackendOptions := AOptions;
    SetLength(BackendOptions.Libraries, Length(AOptions.Libraries));
    for I := 0 to High(AOptions.Libraries) do
      BackendOptions.Libraries[I] := AOptions.Libraries[I];
    for I := 0 to High(SourceLibraries) do
      AppendUniqueString(BackendOptions.Libraries, SourceLibraries[I]);
    LinkOptions := BackendOptions;
    CodegenOutputFile := AOptions.OutputFile;
    if NativeLink then
    begin
      GeneratedObjectFile := GetTempFileName(GetTempDir(False), 'rcc');
      BackendOptions.EmitMode := emObject;
      CodegenOutputFile := GeneratedObjectFile;
      if AOptions.Verbose then
        WriteLn(StdErr, 'object ', GeneratedObjectFile);
    end;
    if (BackendOptions.EmitMode = emObject) and
       (TargetDescriptor.Architecture <> archX86_64) then
      GenerateCrossTargetObject(ProgramAll, TargetDescriptor,
        CodegenOutputFile, CrossStats)
    else if TargetDescriptor.Architecture = archX86_64 then
    begin
      Backend := TX64Backend.Create(ProgramAll, BackendOptions);
      try
        Backend.Generate(CodegenOutputFile);
        BackendStats := Backend.Stats;
      finally
        Backend.Free;
      end;
    end
    else
      GenerateCrossTargetExecutable(ProgramAll, TargetDescriptor,
        CodegenOutputFile, CrossStats);
    if NativeLink then
      LinkNativeExecutable(LinkOptions, TargetDescriptor, GeneratedObjectFile);
    BackTime := GetTickCount64;

    if AOptions.Verbose then WriteLn(StdErr, 'write  ', AOptions.OutputFile);
    if AOptions.ShowStats then
    begin
      WriteLn(StdErr, 'stats');
      WriteLn(StdErr, '  frontend:       ', FrontTime - StartTime, ' ms');
      WriteLn(StdErr, '  verification:   ', VerifyTime - FrontTime, ' ms');
      WriteLn(StdErr, '  optimization:   ', OptTime - VerifyTime, ' ms');
      WriteLn(StdErr, '  formal IR:      ', IRTime - OptTime, ' ms');
      WriteLn(StdErr, '  backend:        ', BackTime - IRTime, ' ms');
      WriteLn(StdErr, '  constants:      ', OptStats.ConstantsFolded);
      WriteLn(StdErr, '  simplifications:', OptStats.AlgebraicSimplifications:8);
      WriteLn(StdErr, '  branches:       ', OptStats.BranchesSimplified);
      WriteLn(StdErr, '  dead statements:', OptStats.DeadStatementsRemoved:8);
      WriteLn(StdErr, '  opt passes:     ', OptStats.PassesRun);
      WriteLn(StdErr, '  expr visited:   ', OptStats.ExpressionsVisited);
      WriteLn(StdErr, '  stmt visited:   ', OptStats.StatementsVisited);
      WriteLn(StdErr, '  IR functions:   ', Length(IRMetrics.Functions));
      WriteLn(StdErr, '  IR blocks:      ', IRMetrics.TotalBlocks);
      WriteLn(StdErr, '  IR instructions:', IRMetrics.TotalInstructions:8);
      if TargetDescriptor.Architecture = archX86_64 then
      begin
        WriteLn(StdErr, '  text bytes:     ', BackendStats.TextBytes);
        WriteLn(StdErr, '  data bytes:     ', BackendStats.DataBytes);
        WriteLn(StdErr, '  functions:      ', BackendStats.FunctionsEmitted);
        WriteLn(StdErr, '  runtime funcs:  ', BackendStats.RuntimeFunctions);
        WriteLn(StdErr, '  fixups:         ', BackendStats.FixupsResolved);
      end
      else
      begin
        WriteLn(StdErr, '  text bytes:     ', CrossStats.TextBytes);
        WriteLn(StdErr, '  instructions:   ', CrossStats.InstructionsEmitted);
        WriteLn(StdErr, '  cross backend:  ', CrossStats.Target);
      end;
    end;
    Result := 0;
  finally
    if (GeneratedObjectFile <> '') and FileExists(GeneratedObjectFile) then
      DeleteFile(GeneratedObjectFile);
    PassManager.Free;
    OutputLines.Free;
    ProgramAll.Free;
  end;
end;

end.
