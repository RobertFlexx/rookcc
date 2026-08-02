unit rcc_cli;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types;

procedure PrintBanner;
procedure PrintHelp;
function ParseOptions(out AOptions: TCompilerOptions): Boolean;

implementation

uses
  Classes, rcc_build, rcc_target, rcc_paths, rcc_args, rcc_arch,
  rcc_codegen_registry, rcc_gnu_compat,
  rcc_v1_registry, rcc_option_catalog;

procedure PrintBanner;
begin
  WriteLn('rcc ', RCCVersion);
  WriteLn('  native modular C compiler  |  x86-64 / AArch64 / RISC-V64');
end;

procedure PrintHelp;
begin
  PrintBanner;
  WriteLn;
  WriteLn('USAGE');
  WriteLn('  rcc [options] file.c ...');
  WriteLn('  rookcc    [options] file.c ...       long-name alias');
  WriteLn;
  WriteLn('QUICK START');
  WriteLn('  rcc hello.c -O2 -o hello');
  WriteLn('  rcc -run hello.c arg1 arg2');
  WriteLn('  rcc --target aarch64 -ffreestanding tiny.c -o tiny.aarch64');
  WriteLn('  rcc --target x86_64-freebsd -ffreestanding tiny.c -o tiny.freebsd');
  WriteLn('  rcc --target arm64-macos -c source.c -o source.macho.o');
  WriteLn('  rcc --emit-ir -O2 source.c -o source.rir');
  WriteLn;
  WriteLn('OUTPUT');
  WriteLn('  -o FILE                    write output to FILE (default: a.out)');
  WriteLn('  -c                         emit a target ELF or Mach-O relocatable object');
  WriteLn('  -run, --run FILE [ARGS]    compile and execute FILE with arguments');
  WriteLn('  -E                         preprocess only');
  WriteLn('  -S                         emit target machine-code listing when available');
  WriteLn('  --emit-ir                  emit verified target-independent IR');
  WriteLn('  --emit-tokens              emit preprocessed lexer tokens');
  WriteLn('  --check                    preprocess, parse, verify, and optimize only');
  WriteLn;
  WriteLn('LANGUAGE');
  WriteLn('  -std=c90|c99|c11|c17|c23   select an ISO C mode');
  WriteLn('  -std=gnu99|gnu11|gnu17|gnu23 select the GNU-compatible surface');
  WriteLn('  -std=rcc                  C17 plus _RCC_SOURCE');
  WriteLn('  --gnu-source               define _GNU_SOURCE');
  WriteLn('  --posix-source             define _POSIX_C_SOURCE=200809L');
  WriteLn('  --rcc-source              define _RCC_SOURCE');
  WriteLn('  -ffreestanding             disable hosted assumptions');
  WriteLn;
  WriteLn('TARGETS');
  WriteLn('  --target ARCH|TRIPLE       select architecture and Linux/BSD/macOS target');
  WriteLn('  --target-arm               alias for --target aarch64');
  WriteLn('  --target-riscv64           alias for --target riscv64');
  WriteLn('  -march=CPU                 select a CPU within the target');
  WriteLn('  -mattr=FEATURES            set the target feature string');
  WriteLn('  --sysroot DIR              select a target sysroot');
  WriteLn('  --print-targets            list target aliases and maturity');
  WriteLn('  --print-target-info        describe the selected ABI and layout');
  WriteLn('  -print-multiarch           print the GNU multiarch directory name');
  WriteLn('  -print-sysroot             print the configured target sysroot');
  WriteLn('  --print-backends           list backend scope and maturity');
  WriteLn('  -fPIC -c                   emit a PIC x86-64 or Mach-O object');
  WriteLn('  -g                         emit DWARF 4 x86-64 debug data and symbols');
  WriteLn;
  WriteLn('PREPROCESSOR');
  WriteLn('  -I DIR, -IDIR              add a user include directory');
  WriteLn('  -iquote DIR                add a quote-only include directory');
  WriteLn('  -isystem DIR               add a system include directory');
  WriteLn('  -D NAME[=VALUE]            define a macro');
  WriteLn('  -U NAME                    undefine a macro');
  WriteLn('  -nostdinc                  disable bundled headers');
  WriteLn('  --resource-dir DIR         use an alternate RookCC resource tree');
  WriteLn('  --print-search-dirs        show resource and header paths');
  WriteLn('  -M, -MM                    emit Make dependencies');
  WriteLn('  -MD, -MMD                  write a side dependency file');
  WriteLn('  -MF FILE, -MT TARGET       set dependency file and target');
  WriteLn('  @FILE                      read options from a response file');
  WriteLn;
  WriteLn('LINKING');
  WriteLn('  native matching targets    link a runnable executable through the host driver');
  WriteLn('  cross hosted targets       use -c, then link with the target SDK/toolchain');
  WriteLn('  -L DIR, -LDIR              add a shared-library search directory');
  WriteLn('  -l NAME, -lNAME            link a named platform library or archive');
  WriteLn('  PATH/libNAME.so|.dylib     link an explicit platform shared library');
  WriteLn('  -Wl,-rpath,DIR             embed a runtime library search path');
  WriteLn('  -Wl,--dynamic-linker,FILE  select the ELF program interpreter');
  WriteLn('  -R DIR                     embed a runtime library search path');
  WriteLn('  -pthread                   enable thread feature macros and libpthread');
  WriteLn('  -nodefaultlibs             omit the implicit target libc dependency');
  WriteLn('  -static                    emit an interpreter-free executable using archives');
  WriteLn('  -shared                    diagnosed until shared-object output matures');
  WriteLn;
  WriteLn('OPTIMIZATION');
  WriteLn('  -O0 -O1 -O2 -O3           optimization levels');
  WriteLn('  -Og                        debug-oriented optimization');
  WriteLn('  -Os, -Oz                   optimize for compact output');
  WriteLn('  -Ofast                     aggressive integer optimization');
  WriteLn;
  WriteLn('DIAGNOSTICS & INSPECTION');
  WriteLn('  -Wall -Wextra -pedantic    warning policy');
  WriteLn('  -Werror                    promote warnings to errors');
  WriteLn('  -g                         request source-oriented debug metadata');
  WriteLn('  -v, --verbose              print compilation stages');
  WriteLn('  --stats                    print timing, IR, and code statistics');
  WriteLn('  --color=auto|always|never  diagnostic color policy');
  WriteLn('  --print-gnu-compat         show the GNU extension matrix');
  WriteLn('  --print-toolchain          summarize all compiler registries');
  WriteLn('  --print-optimizations      summarize IR and target recipes');
  WriteLn('  --print-conformance        summarize the compatibility-policy inventory');
  WriteLn('  --print-target-features    summarize CPU and instruction catalogs');
  WriteLn('  --print-builtins           summarize compiler builtin coverage');
  WriteLn('  -###                       print the internal compilation plan');
  WriteLn('  -dumpmachine               print the selected target triple');
  WriteLn('  -dumpversion               print the compiler version');
  WriteLn('  --version                  print build and target information');
  WriteLn('  -h, --help                 show this help');
  WriteLn;
  WriteLn('ABOUT');
  WriteLn('  rcc has an internal C frontend, optimizer, machine-code encoders, and');
  WriteLn('  ELF/Mach-O writers. Matching native targets can use the host final linker.');
end;

procedure AppendString(var AValues: rcc_types.TStringArray; const AValue: string);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

procedure AppendUniqueString(var AValues: rcc_types.TStringArray;
  const AValue: string);
var
  I: LongInt;
begin
  if AValue = '' then Exit;
  for I := 0 to High(AValues) do
    if AValues[I] = AValue then Exit;
  AppendString(AValues, AValue);
end;


function IsSharedLibraryPath(const AValue: string): Boolean;
var
  Base, LowerBase, Extension: string;
  Marker: LongInt;
begin
  Base := ExtractFileName(AValue);
  LowerBase := LowerCase(Base);
  Extension := LowerCase(ExtractFileExt(LowerBase));
  if (Extension = '.dylib') or (Extension = '.tbd') then Exit(True);
  Marker := Pos('.so', LowerBase);
  Result := (Marker > 0) and
    ((Marker + 2 = Length(LowerBase)) or
     ((Marker + 2 < Length(LowerBase)) and
      (LowerBase[Marker + 3] = '.')));
end;

function IsObjectOrArchivePath(const AValue: string): Boolean;
var
  Extension: string;
begin
  Extension := LowerCase(ExtractFileExt(AValue));
  Result := (Extension = '.o') or (Extension = '.a');
end;

procedure InitializeOptions(out AOptions: TCompilerOptions);
begin
  SetLength(AOptions.Inputs, 0);
  SetLength(AOptions.IncludePaths, 0);
  SetLength(AOptions.QuoteIncludePaths, 0);
  SetLength(AOptions.SystemIncludePaths, 0);
  SetLength(AOptions.Defines, 0);
  SetLength(AOptions.Undefines, 0);
  SetLength(AOptions.LibraryPaths, 0);
  SetLength(AOptions.Libraries, 0);
  SetLength(AOptions.RPaths, 0);
  SetLength(AOptions.ObjectFiles, 0);
  SetLength(AOptions.RunArguments, 0);
  AOptions.OutputFile := 'a.out';
  AOptions.Sysroot := '';
  AOptions.ResourceDir := '';
  AOptions.DynamicLinker := '';
  AOptions.TargetTriple := NativeTargetDescriptor.Triple;
  AOptions.TargetCPU := 'generic';
  AOptions.TargetFeatures := '';
  AOptions.OptimizationLevel := 1;
  AOptions.OptimizeSize := False;
  AOptions.OptimizeDebug := False;
  AOptions.Standard := csGNU17;
  AOptions.WarningLevel := wlDefault;
  AOptions.EmitMode := emExecutable;
  AOptions.ColorMode := cmAuto;
  AOptions.Verbose := False;
  AOptions.ShowStats := False;
  AOptions.WarningsAsErrors := False;
  AOptions.NoStdInc := False;
  AOptions.Freestanding := False;
  AOptions.PositionIndependent := False;
  AOptions.StaticLink := False;
  AOptions.SharedOutput := False;
  AOptions.NoDefaultLibraries := False;
  AOptions.BindNow := False;
  AOptions.DebugInfo := False;
  AOptions.DryRun := False;
  AOptions.RunAfterCompile := False;
  AOptions.LinkOnly := False;
  AOptions.GenerateDependencies := False;
  AOptions.SystemDependencies := False;
  AOptions.PhonyDependencies := False;
  AOptions.DependencyFile := '';
  AOptions.DependencyTarget := '';
  AOptions.ThreadCount := 1;
end;

function ParseStandard(const AValue: string; out AStandard: TCStandard): Boolean;
var
  V: string;
begin
  V := LowerCase(AValue);
  Result := True;
  if (V = 'c89') or (V = 'c90') or (V = 'iso9899:1990') then
    AStandard := csC90
  else if (V = 'c99') or (V = 'iso9899:1999') then
    AStandard := csC99
  else if V = 'c11' then AStandard := csC11
  else if (V = 'c17') or (V = 'c18') then AStandard := csC17
  else if (V = 'c23') or (V = 'c2x') then AStandard := csC23
  else if V = 'gnu99' then AStandard := csGNU99
  else if V = 'gnu11' then AStandard := csGNU11
  else if (V = 'gnu17') or (V = 'gnu18') then AStandard := csGNU17
  else if (V = 'gnu23') or (V = 'gnu2x') then AStandard := csGNU23
  else if (V = 'rcc') or (V = 'rcc17') then AStandard := csRCC
  else Result := False;
end;

function OptionValue(const AOption, APrefix: string): string;
begin
  Result := Copy(AOption, Length(APrefix) + 1, MaxInt);
end;

function ParseOptions(out AOptions: TCompilerOptions): Boolean;
var
  I: LongInt;
  A, V: string;
  PrintSearchDirs, PrintResourceDir, PrintTargetInfo: Boolean;
  Target: TTargetInfo;
  TargetDescriptor: TTargetDescriptor;
  Arguments: rcc_types.TStringArray;
  CompatibilityOptions: TOptionDescriptorArray;
  CompatibilityDescriptor: TOptionDescriptor;

  procedure NeedValue(const AOption: string);
  begin
    Inc(I);
    if I > High(Arguments) then
      raise ERCCError.Create('error: ' + AOption + ' requires an argument');
  end;

  function TryCompatibilityOption(const AOption: string): Boolean;
  var
    Lookup: string;
    EqualsAt: LongInt;
  begin
    Lookup := AOption;
    EqualsAt := Pos('=', Lookup);
    if EqualsAt > 0 then Lookup := Copy(Lookup, 1, EqualsAt - 1);
    Result := FindOptionDescriptor(CompatibilityOptions, Lookup,
      CompatibilityDescriptor);
    if not Result then Exit;
    case CompatibilityDescriptor.Support of
      osAccepted, osIgnoredCompatible:
        begin
          if (CompatibilityDescriptor.ArgumentCount > 0) and
             (EqualsAt = 0) then NeedValue(AOption);
        end;
      osRejected:
        raise ERCCError.Create('error: option ''' + AOption +
          ''' is unsupported by rcc');
    end;
  end;


  procedure ParseLinkerArguments(const AValue: string);
  var
    Parts: TStringList;
    J: LongInt;
    Token, Value: string;
  begin
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True;
      Parts.Delimiter := ',';
      Parts.DelimitedText := AValue;
      J := 0;
      while J < Parts.Count do
      begin
        Token := Parts[J];
        if (Token = '-rpath') or (Token = '--rpath') then
        begin
          Inc(J);
          if J >= Parts.Count then
            raise ERCCError.Create('error: linker option ' + Token +
              ' requires a path');
          AppendUniqueString(AOptions.RPaths, Parts[J]);
        end
        else if (Copy(Token, 1, 7) = '-rpath=') then
        begin
          Value := Copy(Token, 8, MaxInt);
          if Value = '' then
            raise ERCCError.Create('error: linker option -rpath requires a path');
          AppendUniqueString(AOptions.RPaths, Value);
        end
        else if (Copy(Token, 1, 8) = '--rpath=') then
        begin
          Value := Copy(Token, 9, MaxInt);
          if Value = '' then
            raise ERCCError.Create('error: linker option --rpath requires a path');
          AppendUniqueString(AOptions.RPaths, Value);
        end
        else if (Token = '--dynamic-linker') or
          (Token = '-dynamic-linker') then
        begin
          Inc(J);
          if J >= Parts.Count then
            raise ERCCError.Create('error: linker option ' + Token +
              ' requires a file name');
          if Parts[J] = '' then
            raise ERCCError.Create('error: ELF dynamic linker cannot be empty');
          AOptions.DynamicLinker := Parts[J];
        end
        else if Copy(Token, 1, 17) = '--dynamic-linker=' then
        begin
          Value := Copy(Token, 18, MaxInt);
          if Value = '' then
            raise ERCCError.Create('error: ELF dynamic linker cannot be empty');
          AOptions.DynamicLinker := Value;
        end
        else if Copy(Token, 1, 16) = '-dynamic-linker=' then
        begin
          Value := Copy(Token, 17, MaxInt);
          if Value = '' then
            raise ERCCError.Create('error: ELF dynamic linker cannot be empty');
          AOptions.DynamicLinker := Value;
        end
        else if (Token = '-R') then
        begin
          Inc(J);
          if J >= Parts.Count then
            raise ERCCError.Create('error: linker option -R requires a path');
          AppendUniqueString(AOptions.RPaths, Parts[J]);
        end
        else if (Length(Token) > 2) and (Copy(Token, 1, 2) = '-R') then
          AppendUniqueString(AOptions.RPaths, Copy(Token, 3, MaxInt))
        else if (Token = '-L') or (Token = '--library-path') then
        begin
          Inc(J);
          if J >= Parts.Count then
            raise ERCCError.Create('error: linker option ' + Token +
              ' requires a directory');
          AppendString(AOptions.LibraryPaths, Parts[J]);
        end
        else if (Length(Token) > 2) and (Copy(Token, 1, 2) = '-L') then
          AppendString(AOptions.LibraryPaths, Copy(Token, 3, MaxInt))
        else if Copy(Token, 1, 15) = '--library-path=' then
        begin
          Value := Copy(Token, 16, MaxInt);
          if Value = '' then
            raise ERCCError.Create(
              'error: linker option --library-path requires a directory');
          AppendString(AOptions.LibraryPaths, Value);
        end
        else if (Token = '-l') or (Token = '--library') then
        begin
          Inc(J);
          if J >= Parts.Count then
            raise ERCCError.Create('error: linker option ' + Token +
              ' requires a library');
          AppendUniqueString(AOptions.Libraries, Parts[J]);
        end
        else if (Length(Token) > 2) and (Copy(Token, 1, 2) = '-l') then
          AppendUniqueString(AOptions.Libraries, Copy(Token, 3, MaxInt))
        else if Copy(Token, 1, 10) = '--library=' then
        begin
          Value := Copy(Token, 11, MaxInt);
          if Value = '' then
            raise ERCCError.Create(
              'error: linker option --library requires a library');
          AppendUniqueString(AOptions.Libraries, Value);
        end
        else if IsSharedLibraryPath(Token) then
          AppendUniqueString(AOptions.Libraries, '@' + Token)
        else if Token = '--enable-new-dtags' then
        begin

        end
        else if Token = '--disable-new-dtags' then
          raise ERCCError.Create('error: legacy DT_RPATH emission is not supported')
        else if Token = '-z' then
        begin
          Inc(J);
          if J >= Parts.Count then
            raise ERCCError.Create('error: linker option -z requires a keyword');
          Value := LowerCase(Parts[J]);
          if Value = 'now' then AOptions.BindNow := True
          else if (Value = 'noexecstack') or (Value = 'norelro') then
          begin


          end
          else if Value = 'relro' then
            raise ERCCError.Create('error: -z relro is not available until ' +
              'RookCC emits a dedicated read-only-after-relocation segment')
          else
            raise ERCCError.Create('error: unsupported linker -z keyword ''' +
              Parts[J] + '''');
        end
        else if Token = '--no-undefined' then
        begin


        end
        else if (Token = '--as-needed') or (Token = '--no-as-needed') then
        begin



        end
        else if (Token = '--gc-sections') or (Token = '-O1') or
          (Token = '-O2') then
        begin


        end
        else if Token <> '' then
          raise ERCCError.Create('error: unsupported linker option ''' +
            Token + '''');
        Inc(J);
      end;
    finally
      Parts.Free;
    end;
  end;

begin
  InitializeOptions(AOptions);
  CompatibilityOptions := BuildOptionCatalog;
  LoadCommandLineArguments(Arguments);
  PrintSearchDirs := False;
  PrintResourceDir := False;
  PrintTargetInfo := False;
  Result := False;
  I := 1;
  while I <= High(Arguments) do
  begin
    A := Arguments[I];
    if (A = '-h') or (A = '--help') then
    begin
      PrintHelp;
      Exit(False);
    end
    else if A = '--version' then
    begin
      PrintBanner;
      Target := NativeTarget;
      WriteLn('target: ', TargetSummary(Target));
      WriteLn('resource layout: ', RCCResourceLayoutVersion);
      Exit(False);
    end
    else if A = '-dumpversion' then
    begin
      WriteLn(RCCVersion);
      Exit(False);
    end
    else if (A = '-dumpmachine') or (A = '--print-target') then
    begin
      WriteLn(AOptions.TargetTriple);
      Exit(False);
    end
    else if A = '--print-targets' then
    begin
      Write(SupportedTargetsText);
      Exit(False);
    end
    else if (A = '--print-multiarch') or (A = '-print-multiarch') then
    begin
      TargetDescriptor := GetTargetOrRaise(AOptions.TargetTriple);
      WriteLn(TargetMultiArchName(TargetDescriptor));
      Exit(False);
    end
    else if (A = '--print-sysroot') or (A = '-print-sysroot') then
    begin
      WriteLn(AOptions.Sysroot);
      Exit(False);
    end
    else if A = '--print-backends' then
    begin
      Write(BackendRegistryText);
      Exit(False);
    end
    else if A = '--print-gnu-compat' then
    begin
      Write(GNUCompatibilityText);
      Exit(False);
    end
    else if A = '--print-toolchain' then
    begin
      Write(ToolchainRegistrySummary);
      Exit(False);
    end
    else if A = '--print-optimizations' then
    begin
      Write(OptimizationCatalogText);
      Exit(False);
    end
    else if A = '--print-conformance' then
    begin
      Write(ConformanceCatalogText);
      Exit(False);
    end
    else if A = '--print-target-features' then
    begin
      Write(TargetFeatureCatalogText);
      Exit(False);
    end
    else if A = '--print-builtins' then
    begin
      Write(BuiltinRegistryText);
      Exit(False);
    end
    else if A = '--print-target-info' then PrintTargetInfo := True
    else if A = '--print-search-dirs' then PrintSearchDirs := True
    else if A = '--print-resource-dir' then PrintResourceDir := True
    else if A = '--' then
    begin
      Inc(I);
      while I <= High(Arguments) do
      begin
        if IsSharedLibraryPath(Arguments[I]) then
          AppendString(AOptions.Libraries, '@' + Arguments[I])
        else if IsObjectOrArchivePath(Arguments[I]) then
          AppendString(AOptions.ObjectFiles, Arguments[I])
        else
          AppendString(AOptions.Inputs, Arguments[I]);
        Inc(I);
      end;
      Break;
    end
    else if (A = '-run') or (A = '--run') then
    begin
      if AOptions.RunAfterCompile then
        raise ERCCError.Create('error: -run may be specified only once');
      AOptions.RunAfterCompile := True;
      NeedValue(A);
      AppendString(AOptions.Inputs, Arguments[I]);
      Inc(I);
      while I <= High(Arguments) do
      begin
        AppendString(AOptions.RunArguments, Arguments[I]);
        Inc(I);
      end;
      Break;
    end
    else if A = '-o' then
    begin
      NeedValue('-o');
      AOptions.OutputFile := Arguments[I];
    end
    else if (Length(A) > 2) and (Copy(A, 1, 2) = '-o') then
      AOptions.OutputFile := Copy(A, 3, MaxInt)
    else if A = '-E' then AOptions.EmitMode := emPreprocessed
    else if A = '-S' then AOptions.EmitMode := emAssembly
    else if A = '--check' then AOptions.EmitMode := emCheck
    else if A = '--emit-ir' then AOptions.EmitMode := emIR
    else if A = '--emit-tokens' then AOptions.EmitMode := emTokens
    else if A = '-c' then AOptions.EmitMode := emObject
    else if (A = '-O0') then AOptions.OptimizationLevel := 0
    else if (A = '-O') or (A = '-O1') then AOptions.OptimizationLevel := 1
    else if A = '-O2' then AOptions.OptimizationLevel := 2
    else if A = '-O3' then AOptions.OptimizationLevel := 3
    else if A = '-Og' then
    begin
      AOptions.OptimizationLevel := 1;
      AOptions.OptimizeDebug := True;
    end
    else if (A = '-Os') or (A = '-Oz') then
    begin
      AOptions.OptimizationLevel := 2;
      AOptions.OptimizeSize := True;
    end
    else if A = '-Ofast' then AOptions.OptimizationLevel := 3
    else if (A = '-v') or (A = '--verbose') then AOptions.Verbose := True
    else if A = '--stats' then AOptions.ShowStats := True
    else if A = '-Werror' then AOptions.WarningsAsErrors := True
    else if A = '-Wall' then AOptions.WarningLevel := wlAll
    else if A = '-Wextra' then AOptions.WarningLevel := wlExtra
    else if (A = '-pedantic') or (A = '-pedantic-errors') then
      AOptions.WarningLevel := wlPedantic
    else if Copy(A, 1, 5) = '-Wno-' then

    else if Copy(A, 1, 8) = '--color=' then
    begin
      V := LowerCase(OptionValue(A, '--color='));
      if V = 'auto' then AOptions.ColorMode := cmAuto
      else if V = 'always' then AOptions.ColorMode := cmAlways
      else if V = 'never' then AOptions.ColorMode := cmNever
      else raise ERCCError.Create('error: unknown color mode ''' + V + '''');
    end
    else if A = '-I' then
    begin
      NeedValue('-I');
      AppendString(AOptions.IncludePaths, Arguments[I]);
    end
    else if (Length(A) > 2) and (Copy(A, 1, 2) = '-I') then
      AppendString(AOptions.IncludePaths, Copy(A, 3, MaxInt))
    else if A = '-iquote' then
    begin
      NeedValue('-iquote');
      AppendString(AOptions.QuoteIncludePaths, Arguments[I]);
    end
    else if A = '-isystem' then
    begin
      NeedValue('-isystem');
      AppendString(AOptions.SystemIncludePaths, Arguments[I]);
    end
    else if A = '-D' then
    begin
      NeedValue('-D');
      AppendString(AOptions.Defines, Arguments[I]);
    end
    else if (Length(A) > 2) and (Copy(A, 1, 2) = '-D') then
      AppendString(AOptions.Defines, Copy(A, 3, MaxInt))
    else if A = '-U' then
    begin
      NeedValue('-U');
      AppendString(AOptions.Undefines, Arguments[I]);
    end
    else if (Length(A) > 2) and (Copy(A, 1, 2) = '-U') then
      AppendString(AOptions.Undefines, Copy(A, 3, MaxInt))
    else if A = '-L' then
    begin
      NeedValue('-L');
      AppendString(AOptions.LibraryPaths, Arguments[I]);
    end
    else if (Length(A) > 2) and (Copy(A, 1, 2) = '-L') then
      AppendString(AOptions.LibraryPaths, Copy(A, 3, MaxInt))
    else if A = '-l' then
    begin
      NeedValue('-l');
      AppendUniqueString(AOptions.Libraries, Arguments[I]);
    end
    else if (Length(A) > 2) and (Copy(A, 1, 2) = '-l') then
      AppendUniqueString(AOptions.Libraries, Copy(A, 3, MaxInt))
    else if Copy(A, 1, 4) = '-Wl,' then
      ParseLinkerArguments(Copy(A, 5, MaxInt))
    else if A = '-R' then
    begin
      NeedValue('-R');
      AppendUniqueString(AOptions.RPaths, Arguments[I]);
    end
    else if (Length(A) > 2) and (Copy(A, 1, 2) = '-R') then
      AppendUniqueString(AOptions.RPaths, Copy(A, 3, MaxInt))
    else if A = '--dynamic-linker' then
    begin
      NeedValue('--dynamic-linker');
      if Arguments[I] = '' then
        raise ERCCError.Create('error: ELF dynamic linker cannot be empty');
      AOptions.DynamicLinker := Arguments[I];
    end
    else if Copy(A, 1, 17) = '--dynamic-linker=' then
    begin
      V := Copy(A, 18, MaxInt);
      if V = '' then
        raise ERCCError.Create('error: ELF dynamic linker cannot be empty');
      AOptions.DynamicLinker := V;
    end
    else if A = '-static' then AOptions.StaticLink := True
    else if A = '-shared' then AOptions.SharedOutput := True
    else if A = '-nodefaultlibs' then AOptions.NoDefaultLibraries := True
    else if A = '-nostdlib' then
      AOptions.NoDefaultLibraries := True
    else if A = '-M' then
    begin
      AOptions.EmitMode := emDependencies;
      AOptions.SystemDependencies := True;
    end
    else if A = '-MM' then
    begin
      AOptions.EmitMode := emDependencies;
      AOptions.SystemDependencies := False;
    end
    else if A = '-MD' then
    begin
      AOptions.GenerateDependencies := True;
      AOptions.SystemDependencies := True;
    end
    else if A = '-MMD' then
    begin
      AOptions.GenerateDependencies := True;
      AOptions.SystemDependencies := False;
    end
    else if A = '-MP' then AOptions.PhonyDependencies := True
    else if A = '-MF' then
    begin
      NeedValue('-MF');
      AOptions.DependencyFile := Arguments[I];
    end
    else if (Length(A) > 3) and (Copy(A, 1, 3) = '-MF') then
      AOptions.DependencyFile := Copy(A, 4, MaxInt)
    else if (A = '-MT') or (A = '-MQ') then
    begin
      NeedValue(A);
      AOptions.DependencyTarget := Arguments[I];
    end
    else if A = '-nostdinc' then AOptions.NoStdInc := True
    else if A = '-ffreestanding' then AOptions.Freestanding := True
    else if A = '-fhosted' then AOptions.Freestanding := False
    else if (A = '-fPIC') or (A = '-fpic') or (A = '-fPIE') or
      (A = '-fpie') then AOptions.PositionIndependent := True
    else if (A = '-g') or (Copy(A, 1, 2) = '-g') then AOptions.DebugInfo := True
    else if (A = '-pipe') or (A = '-fno-common') or
      (A = '-ffunction-sections') or (A = '-fdata-sections') or
      (A = '-fno-plt') or (A = '-fno-strict-aliasing') then

    else if A = '-pthread' then
    begin
      AppendUniqueString(AOptions.Defines, '_REENTRANT=1');
      AppendUniqueString(AOptions.Defines, '_THREAD_SAFE=1');
      AppendUniqueString(AOptions.Libraries, 'pthread');
    end
    else if A = '--gnu-source' then AppendString(AOptions.Defines, '_GNU_SOURCE=1')
    else if A = '--posix-source' then
    begin
      AppendString(AOptions.Defines, '_POSIX_SOURCE=1');
      AppendString(AOptions.Defines, '_POSIX_C_SOURCE=200809L');
    end
    else if A = '--rcc-source' then AppendString(AOptions.Defines, '_RCC_SOURCE=1')
    else if A = '-###' then AOptions.DryRun := True
    else if A = '-x' then
    begin
      NeedValue('-x');
      V := LowerCase(Arguments[I]);
      if (V <> 'c') and (V <> 'none') then
        raise ERCCError.Create('error: unsupported input language ''' + V + '''');
    end
    else if Copy(A, 1, 5) = '-std=' then
    begin
      V := OptionValue(A, '-std=');
      if not ParseStandard(V, AOptions.Standard) then
        raise ERCCError.Create('error: unsupported language mode ''' + V + '''');
    end
    else if A = '--target' then
    begin
      NeedValue('--target');
      V := Arguments[I];
      if not TargetIsSupported(V) then
        raise ERCCError.Create('error: unsupported target ' + V);
      AOptions.TargetTriple := NormalizeTargetTriple(V);
    end
    else if Copy(A, 1, 9) = '--target=' then
    begin
      V := OptionValue(A, '--target=');
      if not TargetIsSupported(V) then
        raise ERCCError.Create('error: unsupported target ' + V);
      AOptions.TargetTriple := NormalizeTargetTriple(V);
    end
    else if (A = '--target-arm') or (A = '--target-arm64') or
      (A = '--target-aarch64') then
      AOptions.TargetTriple := NormalizeTargetTriple('aarch64')
    else if (A = '--target-riscv') or (A = '--target-riscv64') then
      AOptions.TargetTriple := NormalizeTargetTriple('riscv64')
    else if (A = '--target-x86') or (A = '--target-x86_64') then
      AOptions.TargetTriple := NormalizeTargetTriple('x86_64')
    else if (A = '--sysroot') or (A = '-isysroot') then
    begin
      NeedValue(A);
      AOptions.Sysroot := Arguments[I];
    end
    else if Copy(A, 1, 10) = '--sysroot=' then
      AOptions.Sysroot := OptionValue(A, '--sysroot=')
    else if A = '--resource-dir' then
    begin
      NeedValue('--resource-dir');
      AOptions.ResourceDir := Arguments[I];
    end
    else if Copy(A, 1, 15) = '--resource-dir=' then
      AOptions.ResourceDir := OptionValue(A, '--resource-dir=')
    else if Copy(A, 1, 7) = '-march=' then
    begin
      V := LowerCase(OptionValue(A, '-march='));
      if V = '' then
        raise ERCCError.Create('error: -march requires a CPU name');
      AOptions.TargetCPU := V;
    end
    else if Copy(A, 1, 7) = '-mattr=' then
      AOptions.TargetFeatures := OptionValue(A, '-mattr=')
    else if Copy(A, 1, 7) = '-mtune=' then

    else if A = '-pie' then AOptions.PositionIndependent := True
    else if A = '-no-pie' then

    else if (A <> '') and (A[1] = '-') then
    begin
      if not TryCompatibilityOption(A) then
        raise ERCCError.Create('error: unknown option ''' + A + '''');
    end
    else if IsSharedLibraryPath(A) then
      AppendString(AOptions.Libraries, '@' + A)
    else if IsObjectOrArchivePath(A) then
      AppendString(AOptions.ObjectFiles, A)
    else
      AppendString(AOptions.Inputs, A);
    Inc(I);
  end;

  if AOptions.Standard = csRCC then
    AppendString(AOptions.Defines, '_RCC_SOURCE=1');
  AddDefaultIncludePaths(AOptions);

  if PrintTargetInfo then
  begin
    TargetDescriptor := GetTargetOrRaise(AOptions.TargetTriple);
    Write(TargetDetailedText(TargetDescriptor));
    Exit(False);
  end;
  if PrintResourceDir then
  begin
    WriteLn(AOptions.ResourceDir);
    Exit(False);
  end;
  if PrintSearchDirs then
  begin
    Write(SearchDirectoriesText(AOptions));
    Exit(False);
  end;

  if (Length(AOptions.Inputs) = 0) and
     (Length(AOptions.ObjectFiles) = 0) then
    raise ERCCError.Create('rcc: fatal error: no input files' + LineEnding +
      'compilation terminated.');
  if AOptions.RunAfterCompile and
     (AOptions.EmitMode <> emExecutable) then
    raise ERCCError.Create('error: -run requires executable output');
  if (AOptions.OutputFile = 'a.out') and (AOptions.EmitMode = emAssembly) then
    AOptions.OutputFile := 'a.s';
  if (AOptions.EmitMode = emObject) and (AOptions.OutputFile = 'a.out') and
    (Length(AOptions.Inputs) = 1) then
    AOptions.OutputFile := ChangeFileExt(ExtractFileName(AOptions.Inputs[0]), '.o');
  if AOptions.GenerateDependencies and (AOptions.DependencyFile = '') then
  begin
    if AOptions.OutputFile <> 'a.out' then
      AOptions.DependencyFile := ChangeFileExt(AOptions.OutputFile, '.d')
    else if Length(AOptions.Inputs) = 1 then
      AOptions.DependencyFile := ChangeFileExt(ExtractFileName(AOptions.Inputs[0]), '.d')
    else
      AOptions.DependencyFile := 'rcc.d';
  end;
  Result := True;
end;

end.
