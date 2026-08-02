unit rcc_arch;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types;

type
  TArchitecture = (
    archUnknown,
    archX86_64,
    archAArch64,
    archRISCV64
  );

  TOperatingSystem = (
    osUnknown,
    osLinux,
    osFreeBSD,
    osOpenBSD,
    osNetBSD,
    osDarwin
  );

  TObjectFormat = (
    ofUnknown,
    ofELF64,
    ofMachO64
  );

  TEndianness = (
    endianLittle,
    endianBig
  );

  TCallingConvention = (
    ccUnknown,
    ccSysVAMD64,
    ccAAPCS64,
    ccRISCVLP64D
  );

  TTargetCapability = (
    tcExecutable,
    tcRelocatableObject,
    tcStaticELF,
    tcDynamicELF,
    tcHostedLibC,
    tcPositionIndependent,
    tcThreadLocalStorage,
    tcFloatingPoint,
    tcVector,
    tcAtomic,
    tcMachO,
    tcCrossCompilation,
    tcNativePlatformLink
  );
  TTargetCapabilities = set of TTargetCapability;

  TTargetSyscallSite = record
    TextOffset: QWord;
    Number: LongWord;
  end;
  TTargetSyscallSiteArray = array of TTargetSyscallSite;

  TRegisterClass = (
    rcInteger,
    rcFloating,
    rcVector,
    rcSpecial
  );

  TRegisterInfo = record
    Name: string;
    Number: LongInt;
    RegClass: TRegisterClass;
    WidthBits: LongInt;
    CallerSaved: Boolean;
    CalleeSaved: Boolean;
    Reserved: Boolean;
  end;
  TRegisterInfoArray = array of TRegisterInfo;

  TDataLayout = record
    PointerBits: LongInt;
    PointerAlign: LongInt;
    CharBits: LongInt;
    ShortBits: LongInt;
    IntBits: LongInt;
    LongBits: LongInt;
    LongLongBits: LongInt;
    FloatBits: LongInt;
    DoubleBits: LongInt;
    LongDoubleBits: LongInt;
    LongDoubleAlign: LongInt;
    StackAlignment: LongInt;
    MaxScalarAlignment: LongInt;
    Endianness: TEndianness;
  end;

  TTargetDescriptor = record
    Triple: string;
    Architecture: TArchitecture;
    OperatingSystem: TOperatingSystem;
    ObjectFormat: TObjectFormat;
    CallingConvention: TCallingConvention;
    ABIName: string;
    CPUName: string;
    CPUFeatures: string;
    ELFMachine: Word;
    ELFFlags: LongWord;
    ELFOSABI: Byte;
    ELFABIVersion: Byte;
    PageSize: QWord;
    PreferredImageBase: QWord;
    SymbolPrefix: string;
    DefaultDynamicLoader: string;
    DefaultLibC: string;
    DataLayout: TDataLayout;
    Capabilities: TTargetCapabilities;
    Registers: TRegisterInfoArray;
  end;

function ArchitectureName(AArchitecture: TArchitecture): string;
function TargetMultiArchName(const ATarget: TTargetDescriptor): string;
function OperatingSystemName(AOperatingSystem: TOperatingSystem): string;
function ObjectFormatName(AObjectFormat: TObjectFormat): string;
function CallingConventionName(AConvention: TCallingConvention): string;
function EndiannessName(AEndianness: TEndianness): string;
function CapabilityName(ACapability: TTargetCapability): string;
function TargetHasCapability(const ATarget: TTargetDescriptor;
  ACapability: TTargetCapability): Boolean;
function TargetCapabilityText(const ATarget: TTargetDescriptor): string;
function TargetDataLayoutText(const ATarget: TTargetDescriptor): string;
function TargetSummaryText(const ATarget: TTargetDescriptor): string;
function TargetDetailedText(const ATarget: TTargetDescriptor): string;

function NormalizeArchitectureAlias(const AValue: string): string;
function NormalizeTargetAlias(const AValue: string): string;
function TryParseArchitecture(const AValue: string;
  out AArchitecture: TArchitecture): Boolean;
function TryGetTarget(const AValue: string;
  out ATarget: TTargetDescriptor): Boolean;
function GetTargetOrRaise(const AValue: string): TTargetDescriptor;
function NativeTargetDescriptor: TTargetDescriptor;
function TargetMatchesNativeHost(const ATarget: TTargetDescriptor): Boolean;
function SupportedTargetTriples: rcc_types.TStringArray;
function SupportedTargetsText: string;
function BuildTargetPredefinedMacros(const ATarget: TTargetDescriptor): rcc_types.TStringArray;

function TargetIntegerArgumentRegister(const ATarget: TTargetDescriptor;
  AIndex: LongInt): LongInt;
function TargetIntegerReturnRegister(const ATarget: TTargetDescriptor): LongInt;
function TargetFramePointerRegister(const ATarget: TTargetDescriptor): LongInt;
function TargetStackPointerRegister(const ATarget: TTargetDescriptor): LongInt;
function TargetLinkRegister(const ATarget: TTargetDescriptor): LongInt;
function FindRegister(const ATarget: TTargetDescriptor;
  const AName: string; out ARegister: TRegisterInfo): Boolean;
function TargetRegisterText(const ATarget: TTargetDescriptor): string;
function TargetIsBSD(const ATarget: TTargetDescriptor): Boolean;
function TargetIsELF(const ATarget: TTargetDescriptor): Boolean;
function TargetSyscallNumber(const ATarget: TTargetDescriptor;
  const AName: string; out ANumber: LongWord): Boolean;

implementation

const
  EM_X86_64 = 62;
  EM_AARCH64 = 183;
  EM_RISCV = 243;

procedure AppendString(var AValues: rcc_types.TStringArray; const AValue: string);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

procedure AddRegister(var ARegisters: TRegisterInfoArray;
  const AName: string; ANumber: LongInt; AClass: TRegisterClass;
  AWidth: LongInt; ACallerSaved, ACalleeSaved, AReserved: Boolean);
var
  N: LongInt;
begin
  N := Length(ARegisters);
  SetLength(ARegisters, N + 1);
  ARegisters[N].Name := AName;
  ARegisters[N].Number := ANumber;
  ARegisters[N].RegClass := AClass;
  ARegisters[N].WidthBits := AWidth;
  ARegisters[N].CallerSaved := ACallerSaved;
  ARegisters[N].CalleeSaved := ACalleeSaved;
  ARegisters[N].Reserved := AReserved;
end;

function ArchitectureName(AArchitecture: TArchitecture): string;
begin
  case AArchitecture of
    archX86_64: Result := 'x86_64';
    archAArch64: Result := 'aarch64';
    archRISCV64: Result := 'riscv64';
  else
    Result := 'unknown';
  end;
end;

function TargetMultiArchName(const ATarget: TTargetDescriptor): string;
begin
  if ATarget.OperatingSystem = osLinux then
    case ATarget.Architecture of
      archX86_64: Exit('x86_64-linux-gnu');
      archAArch64: Exit('aarch64-linux-gnu');
      archRISCV64: Exit('riscv64-linux-gnu');
    end;
  if TargetIsBSD(ATarget) then
    Exit(ArchitectureName(ATarget.Architecture) + '-' +
      OperatingSystemName(ATarget.OperatingSystem));
  if ATarget.OperatingSystem = osDarwin then
    Exit(ArchitectureName(ATarget.Architecture) + '-apple-darwin');
  Result := '';
end;

function TargetIsBSD(const ATarget: TTargetDescriptor): Boolean;
begin
  Result := ATarget.OperatingSystem in [osFreeBSD, osOpenBSD, osNetBSD];
end;

function TargetIsELF(const ATarget: TTargetDescriptor): Boolean;
begin
  Result := ATarget.ObjectFormat = ofELF64;
end;

function TargetSyscallNumber(const ATarget: TTargetDescriptor;
  const AName: string; out ANumber: LongWord): Boolean;
var
  Name: string;
begin
  Name := LowerCase(AName);
  ANumber := 0;
  case ATarget.OperatingSystem of
    osLinux:
      begin
        if ATarget.Architecture = archX86_64 then
        begin
          if Name = 'read' then ANumber := 0
          else if Name = 'write' then ANumber := 1
          else if Name = 'open' then ANumber := 2
          else if Name = 'close' then ANumber := 3
          else if Name = 'lseek' then ANumber := 8
          else if Name = 'mmap' then ANumber := 9
          else if Name = 'munmap' then ANumber := 11
          else if Name = 'access' then ANumber := 21
          else if Name = 'getpid' then ANumber := 39
          else if Name = 'exit' then ANumber := 60
          else if Name = 'time' then ANumber := 201
          else Exit(False);
        end
        else
        begin
          { AArch64 and RISC-V Linux both use the asm-generic table. }
          if Name = 'read' then ANumber := 63
          else if Name = 'write' then ANumber := 64
          else if Name = 'close' then ANumber := 57
          else if Name = 'lseek' then ANumber := 62
          else if Name = 'exit' then ANumber := 93
          else if Name = 'getpid' then ANumber := 172
          else if Name = 'munmap' then ANumber := 215
          else if Name = 'mmap' then ANumber := 222
          else Exit(False);
        end;
      end;
    osFreeBSD, osOpenBSD, osNetBSD:
      begin
        if Name = 'exit' then ANumber := 1
        else if Name = 'read' then ANumber := 3
        else if Name = 'write' then ANumber := 4
        else if Name = 'open' then ANumber := 5
        else if Name = 'close' then ANumber := 6
        else if Name = 'getpid' then ANumber := 20
        else if Name = 'access' then ANumber := 33
        else if Name = 'munmap' then ANumber := 73
        else if Name = 'lseek' then
        begin
          if ATarget.OperatingSystem = osFreeBSD then ANumber := 478
          else ANumber := 199;
        end
        else Exit(False);
      end;
  else
    Exit(False);
  end;
  Result := True;
end;

function OperatingSystemName(AOperatingSystem: TOperatingSystem): string;
begin
  case AOperatingSystem of
    osLinux: Result := 'linux';
    osFreeBSD: Result := 'freebsd';
    osOpenBSD: Result := 'openbsd';
    osNetBSD: Result := 'netbsd';
    osDarwin: Result := 'macos';
  else
    Result := 'unknown';
  end;
end;

function ObjectFormatName(AObjectFormat: TObjectFormat): string;
begin
  case AObjectFormat of
    ofELF64: Result := 'ELF64';
    ofMachO64: Result := 'Mach-O 64-bit';
  else
    Result := 'unknown';
  end;
end;

function CallingConventionName(AConvention: TCallingConvention): string;
begin
  case AConvention of
    ccSysVAMD64: Result := 'System V AMD64';
    ccAAPCS64: Result := 'AAPCS64';
    ccRISCVLP64D: Result := 'RISC-V LP64D';
  else
    Result := 'unknown';
  end;
end;

function EndiannessName(AEndianness: TEndianness): string;
begin
  case AEndianness of
    endianLittle: Result := 'little';
    endianBig: Result := 'big';
  else
    Result := 'unknown';
  end;
end;

function CapabilityName(ACapability: TTargetCapability): string;
begin
  case ACapability of
    tcExecutable: Result := 'executable';
    tcRelocatableObject: Result := 'relocatable-object';
    tcStaticELF: Result := 'static-elf';
    tcDynamicELF: Result := 'dynamic-elf';
    tcHostedLibC: Result := 'hosted-libc';
    tcPositionIndependent: Result := 'position-independent';
    tcThreadLocalStorage: Result := 'thread-local-storage';
    tcFloatingPoint: Result := 'floating-point';
    tcVector: Result := 'vector';
    tcAtomic: Result := 'atomic';
    tcMachO: Result := 'mach-o';
    tcCrossCompilation: Result := 'cross-compilation';
    tcNativePlatformLink: Result := 'native-platform-link';
  else
    Result := 'unknown';
  end;
end;

function TargetHasCapability(const ATarget: TTargetDescriptor;
  ACapability: TTargetCapability): Boolean;
begin
  Result := ACapability in ATarget.Capabilities;
end;

function TargetCapabilityText(const ATarget: TTargetDescriptor): string;
var
  C: TTargetCapability;
begin
  Result := '';
  for C := Low(TTargetCapability) to High(TTargetCapability) do
    if C in ATarget.Capabilities then
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + CapabilityName(C);
    end;
end;

function TargetDataLayoutText(const ATarget: TTargetDescriptor): string;
begin
  Result := Format(
    'e=%s,p=%d:%d,c=%d,s=%d,i=%d,l=%d,ll=%d,f=%d,d=%d,ld=%d:%d,stack=%d',
    [EndiannessName(ATarget.DataLayout.Endianness),
     ATarget.DataLayout.PointerBits,
     ATarget.DataLayout.PointerAlign,
     ATarget.DataLayout.CharBits,
     ATarget.DataLayout.ShortBits,
     ATarget.DataLayout.IntBits,
     ATarget.DataLayout.LongBits,
     ATarget.DataLayout.LongLongBits,
     ATarget.DataLayout.FloatBits,
     ATarget.DataLayout.DoubleBits,
     ATarget.DataLayout.LongDoubleBits,
     ATarget.DataLayout.LongDoubleAlign,
     ATarget.DataLayout.StackAlignment]);
end;

function TargetSummaryText(const ATarget: TTargetDescriptor): string;
begin
  Result := ATarget.Triple + ' (' + ObjectFormatName(ATarget.ObjectFormat) +
    ', ' + CallingConventionName(ATarget.CallingConvention) + ')';
end;

function TargetDetailedText(const ATarget: TTargetDescriptor): string;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('triple:        ' + ATarget.Triple);
    Lines.Add('architecture:  ' + ArchitectureName(ATarget.Architecture));
    Lines.Add('operating sys: ' + OperatingSystemName(ATarget.OperatingSystem));
    Lines.Add('object format: ' + ObjectFormatName(ATarget.ObjectFormat));
    Lines.Add('ABI:           ' + ATarget.ABIName);
    Lines.Add('CPU:           ' + ATarget.CPUName);
    Lines.Add('features:      ' + ATarget.CPUFeatures);
    if TargetIsELF(ATarget) then
    begin
      Lines.Add('ELF machine:   ' + IntToStr(ATarget.ELFMachine));
      Lines.Add('ELF OSABI:     ' + IntToStr(ATarget.ELFOSABI));
    end;
    Lines.Add('endianness:    ' + EndiannessName(ATarget.DataLayout.Endianness));
    Lines.Add('data layout:   ' + TargetDataLayoutText(ATarget));
    Lines.Add('capabilities:  ' + TargetCapabilityText(ATarget));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function NormalizeArchitectureAlias(const AValue: string): string;
var
  V: string;
begin
  V := LowerCase(Trim(AValue));
  V := StringReplace(V, '_', '-', [rfReplaceAll]);
  if (V = 'amd64') or (V = 'x64') or (V = 'x86-64') or
     (V = 'x86-64-v1') or (V = 'x86-64-v2') then
    Exit('x86_64');
  if (V = 'arm') or (V = 'arm64') or (V = 'aarch64') or
     (V = 'aarch64-linux') then
    Exit('aarch64');
  if (V = 'rv64') or (V = 'rv64gc') or (V = 'riscv') or
     (V = 'risc-v') or (V = 'riscv64') then
    Exit('riscv64');
  Result := V;
end;

function NormalizeTargetAlias(const AValue: string): string;
var
  V, A, OSName, Vendor: string;
begin
  V := LowerCase(Trim(AValue));
  if (V = '') or (V = 'native') or (V = 'host') then
    Exit(NativeTargetDescriptor.Triple);
  A := NormalizeArchitectureAlias(V);
  if A = 'x86_64' then Exit('x86_64-unknown-linux-rcc');
  if A = 'aarch64' then Exit('aarch64-unknown-linux-rcc');
  if A = 'riscv64' then Exit('riscv64-unknown-linux-rcc');
  V := StringReplace(V, '_', '-', [rfReplaceAll]);

  if (Pos('x86-64', V) > 0) or (Pos('amd64', V) > 0) or
     (Pos('x64', V) > 0) then A := 'x86_64'
  else if (Pos('aarch64', V) > 0) or (Pos('arm64', V) > 0) then
    A := 'aarch64'
  else if (Pos('riscv64', V) > 0) or (Pos('rv64', V) > 0) then
    A := 'riscv64'
  else
    A := '';

  if Pos('freebsd', V) > 0 then OSName := 'freebsd'
  else if Pos('openbsd', V) > 0 then OSName := 'openbsd'
  else if Pos('netbsd', V) > 0 then OSName := 'netbsd'
  else if (Pos('darwin', V) > 0) or (Pos('macos', V) > 0) or
          (Pos('macosx', V) > 0) then OSName := 'darwin'
  else if Pos('linux', V) > 0 then OSName := 'linux'
  else OSName := '';

  if (A = '') and (OSName <> '') then A := 'x86_64';
  if (A <> '') and (OSName = '') then OSName := 'linux';
  if (A <> '') and (OSName <> '') then
  begin
    if OSName = 'darwin' then Vendor := 'apple' else Vendor := 'unknown';
    Exit(A + '-' + Vendor + '-' + OSName + '-rcc');
  end;
  Result := V;
end;

function TryParseArchitecture(const AValue: string;
  out AArchitecture: TArchitecture): Boolean;
var
  V: string;
begin
  V := NormalizeArchitectureAlias(AValue);
  Result := True;
  if V = 'x86_64' then AArchitecture := archX86_64
  else if V = 'aarch64' then AArchitecture := archAArch64
  else if V = 'riscv64' then AArchitecture := archRISCV64
  else
  begin
    AArchitecture := archUnknown;
    Result := False;
  end;
end;

procedure FillLP64Layout(out ALayout: TDataLayout;
  ALongDoubleBits, AStackAlignment: LongInt);
begin
  ALayout.PointerBits := 64;
  ALayout.PointerAlign := 8;
  ALayout.CharBits := 8;
  ALayout.ShortBits := 16;
  ALayout.IntBits := 32;
  ALayout.LongBits := 64;
  ALayout.LongLongBits := 64;
  ALayout.FloatBits := 32;
  ALayout.DoubleBits := 64;
  ALayout.LongDoubleBits := ALongDoubleBits;
  if ALongDoubleBits <= 64 then ALayout.LongDoubleAlign := 8
  else ALayout.LongDoubleAlign := 16;
  ALayout.StackAlignment := AStackAlignment;
  ALayout.MaxScalarAlignment := 16;
  ALayout.Endianness := endianLittle;
end;

procedure FillX86Registers(out ARegisters: TRegisterInfoArray);
const
  Names: array[0..15] of string = (
    'rax', 'rcx', 'rdx', 'rbx', 'rsp', 'rbp', 'rsi', 'rdi',
    'r8', 'r9', 'r10', 'r11', 'r12', 'r13', 'r14', 'r15');
var
  I: LongInt;
  Caller, Callee, Reserved: Boolean;
begin
  SetLength(ARegisters, 0);
  for I := 0 to 15 do
  begin
    Caller := I in [0, 1, 2, 6, 7, 8, 9, 10, 11];
    Callee := I in [3, 5, 12, 13, 14, 15];
    Reserved := I in [4, 5];
    AddRegister(ARegisters, Names[I], I, rcInteger, 64,
      Caller, Callee, Reserved);
  end;
  for I := 0 to 15 do
    AddRegister(ARegisters, 'xmm' + IntToStr(I), I, rcFloating, 128,
      True, False, False);
end;

procedure FillAArch64Registers(out ARegisters: TRegisterInfoArray);
var
  I: LongInt;
  Caller, Callee, Reserved: Boolean;
begin
  SetLength(ARegisters, 0);
  for I := 0 to 30 do
  begin
    Caller := (I <= 18) or (I = 30);
    Callee := (I >= 19) and (I <= 29);
    Reserved := I in [18, 29, 30];
    AddRegister(ARegisters, 'x' + IntToStr(I), I, rcInteger, 64,
      Caller, Callee, Reserved);
  end;
  AddRegister(ARegisters, 'sp', 31, rcSpecial, 64, False, False, True);
  for I := 0 to 31 do
    AddRegister(ARegisters, 'v' + IntToStr(I), I, rcVector, 128,
      (I <= 7) or (I >= 16), (I >= 8) and (I <= 15), False);
end;

procedure FillRISCVRegisters(out ARegisters: TRegisterInfoArray);
const
  Names: array[0..31] of string = (
    'zero', 'ra', 'sp', 'gp', 'tp', 't0', 't1', 't2',
    's0', 's1', 'a0', 'a1', 'a2', 'a3', 'a4', 'a5',
    'a6', 'a7', 's2', 's3', 's4', 's5', 's6', 's7',
    's8', 's9', 's10', 's11', 't3', 't4', 't5', 't6');
var
  I: LongInt;
  Caller, Callee, Reserved: Boolean;
begin
  SetLength(ARegisters, 0);
  for I := 0 to 31 do
  begin
    Caller := I in [1, 5, 6, 7, 10, 11, 12, 13, 14, 15, 16, 17,
      28, 29, 30, 31];
    Callee := I in [8, 9, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27];
    Reserved := I in [0, 2, 3, 4, 8];
    AddRegister(ARegisters, Names[I], I, rcInteger, 64,
      Caller, Callee, Reserved);
  end;
  for I := 0 to 31 do
    AddRegister(ARegisters, 'f' + IntToStr(I), I, rcFloating, 64,
      not (I in [8, 9, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27]),
      I in [8, 9, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27], False);
end;

function MakeTarget(AArchitecture: TArchitecture;
  AOperatingSystem: TOperatingSystem): TTargetDescriptor;
var
  ArchPart, OSPart, VendorPart: string;
  LongDoubleBits: LongInt;
begin
  Result := Default(TTargetDescriptor);
  Result.Architecture := AArchitecture;
  Result.OperatingSystem := AOperatingSystem;
  Result.ELFOSABI := 0;
  Result.ELFABIVersion := 0;
  Result.PageSize := 4096;
  Result.PreferredImageBase := $400000;
  Result.SymbolPrefix := '';
  Result.Capabilities := [tcRelocatableObject, tcCrossCompilation];

  ArchPart := ArchitectureName(AArchitecture);
  VendorPart := 'unknown';
  case AOperatingSystem of
    osLinux:
      begin
        OSPart := 'linux';
        Result.ObjectFormat := ofELF64;
        Result.Capabilities := Result.Capabilities +
          [tcExecutable, tcStaticELF];
      end;
    osFreeBSD:
      begin
        OSPart := 'freebsd';
        Result.ObjectFormat := ofELF64;
        Result.ELFOSABI := 9;
        Result.DefaultDynamicLoader := '/libexec/ld-elf.so.1';
        Result.DefaultLibC := 'libc.so.7';
        Result.Capabilities := Result.Capabilities +
          [tcExecutable, tcStaticELF];
      end;
    osOpenBSD:
      begin
        OSPart := 'openbsd';
        Result.ObjectFormat := ofELF64;
        Result.ELFOSABI := 12;
        Result.DefaultDynamicLoader := '/usr/libexec/ld.so';
        Result.DefaultLibC := 'libc.so';
        Result.Capabilities := Result.Capabilities +
          [tcExecutable, tcStaticELF];
      end;
    osNetBSD:
      begin
        OSPart := 'netbsd';
        Result.ObjectFormat := ofELF64;
        { NetBSD's current LLVM toolchain emits generic System V ELF
          branding, including for NetBSD triples.  Match that interoperable
          convention instead of the largely unused ELFOSABI_NETBSD value. }
        Result.ELFOSABI := 0;
        Result.DefaultDynamicLoader := '/libexec/ld.elf_so';
        Result.DefaultLibC := 'libc.so.12';
        Result.Capabilities := Result.Capabilities +
          [tcExecutable, tcStaticELF];
      end;
    osDarwin:
      begin
        OSPart := 'darwin';
        VendorPart := 'apple';
        Result.ObjectFormat := ofMachO64;
        Result.SymbolPrefix := '_';
        Result.DefaultDynamicLoader := '/usr/lib/dyld';
        Result.DefaultLibC := 'libSystem.B.dylib';
        Result.Capabilities := Result.Capabilities +
          [tcMachO, tcPositionIndependent];
      end;
  else
    OSPart := 'unknown';
    Result.ObjectFormat := ofUnknown;
  end;
  Result.Triple := ArchPart + '-' + VendorPart + '-' + OSPart + '-rcc';
  LongDoubleBits := 128;
  case AArchitecture of
    archX86_64:
      begin
        Result.CallingConvention := ccSysVAMD64;
        if AOperatingSystem = osDarwin then
          Result.ABIName := 'Darwin x86-64 ABI'
        else
          Result.ABIName := 'System V AMD64';
        Result.CPUName := 'x86-64';
        Result.CPUFeatures := 'sse2';
        Result.ELFMachine := EM_X86_64;
        Result.ELFFlags := 0;
        Result.Capabilities := Result.Capabilities +
          [tcFloatingPoint, tcPositionIndependent];
        FillX86Registers(Result.Registers);
      end;
    archAArch64:
      begin
        Result.CallingConvention := ccAAPCS64;
        if AOperatingSystem = osDarwin then
        begin
          Result.ABIName := 'Darwin arm64 ABI';
          Result.PageSize := 16384;
          LongDoubleBits := 64;
        end
        else
          Result.ABIName := 'AAPCS64 / ELF for the Arm 64-bit Architecture';
        Result.CPUName := 'generic-armv8-a';
        Result.CPUFeatures := '+fp,+simd';
        Result.ELFMachine := EM_AARCH64;
        Result.ELFFlags := 0;
        FillAArch64Registers(Result.Registers);
      end;
    archRISCV64:
      begin
        Result.CallingConvention := ccRISCVLP64D;
        Result.ABIName := 'RISC-V ELF psABI LP64D';
        Result.CPUName := 'generic-rv64gc';
        Result.CPUFeatures := '+i,+m,+a,+f,+d,+c';
        Result.ELFMachine := EM_RISCV;
        Result.ELFFlags := 5;
        Result.PreferredImageBase := $10000;
        FillRISCVRegisters(Result.Registers);
      end;
  end;
  FillLP64Layout(Result.DataLayout, LongDoubleBits, 16);

  if AOperatingSystem = osLinux then
    case AArchitecture of
      archX86_64:
        begin
          Result.DefaultDynamicLoader := '/lib64/ld-linux-x86-64.so.2';
          Result.DefaultLibC := 'libc.so.6';
          Result.Capabilities := Result.Capabilities +
            [tcDynamicELF, tcHostedLibC];
        end;
      archAArch64:
        begin
          Result.DefaultDynamicLoader := '/lib/ld-linux-aarch64.so.1';
          Result.DefaultLibC := 'libc.so.6';
        end;
      archRISCV64:
        begin
          Result.DefaultDynamicLoader :=
            '/lib/ld-linux-riscv64-lp64d.so.1';
          Result.DefaultLibC := 'libc.so.6';
        end;
    end;
  if (AOperatingSystem = osDarwin) or
     (AOperatingSystem in [osFreeBSD, osOpenBSD, osNetBSD]) or
     ((AOperatingSystem = osLinux) and (AArchitecture <> archX86_64)) then
    Result.Capabilities := Result.Capabilities + [tcNativePlatformLink];
end;

function MakeX86Target: TTargetDescriptor;
begin
  Result := MakeTarget(archX86_64, osLinux);
end;

function MakeAArch64Target: TTargetDescriptor;
begin
  Result := MakeTarget(archAArch64, osLinux);
end;

function MakeRISCVTarget: TTargetDescriptor;
begin
  Result := MakeTarget(archRISCV64, osLinux);
end;

function TryGetTarget(const AValue: string;
  out ATarget: TTargetDescriptor): Boolean;
var
  V: string;
begin
  V := NormalizeTargetAlias(AValue);
  Result := True;
  if V = 'x86_64-unknown-linux-rcc' then ATarget := MakeX86Target
  else if V = 'aarch64-unknown-linux-rcc' then ATarget := MakeAArch64Target
  else if V = 'riscv64-unknown-linux-rcc' then ATarget := MakeRISCVTarget
  else if V = 'x86_64-unknown-freebsd-rcc' then
    ATarget := MakeTarget(archX86_64, osFreeBSD)
  else if V = 'aarch64-unknown-freebsd-rcc' then
    ATarget := MakeTarget(archAArch64, osFreeBSD)
  else if V = 'riscv64-unknown-freebsd-rcc' then
    ATarget := MakeTarget(archRISCV64, osFreeBSD)
  else if V = 'x86_64-unknown-openbsd-rcc' then
    ATarget := MakeTarget(archX86_64, osOpenBSD)
  else if V = 'aarch64-unknown-openbsd-rcc' then
    ATarget := MakeTarget(archAArch64, osOpenBSD)
  else if V = 'riscv64-unknown-openbsd-rcc' then
    ATarget := MakeTarget(archRISCV64, osOpenBSD)
  else if V = 'x86_64-unknown-netbsd-rcc' then
    ATarget := MakeTarget(archX86_64, osNetBSD)
  else if V = 'aarch64-unknown-netbsd-rcc' then
    ATarget := MakeTarget(archAArch64, osNetBSD)
  else if V = 'riscv64-unknown-netbsd-rcc' then
    ATarget := MakeTarget(archRISCV64, osNetBSD)
  else if V = 'x86_64-apple-darwin-rcc' then
    ATarget := MakeTarget(archX86_64, osDarwin)
  else if V = 'aarch64-apple-darwin-rcc' then
    ATarget := MakeTarget(archAArch64, osDarwin)
  else
  begin
    ATarget.Triple := '';
    ATarget.Architecture := archUnknown;
    ATarget.OperatingSystem := osUnknown;
    ATarget.ObjectFormat := ofUnknown;
    ATarget.CallingConvention := ccUnknown;
    ATarget.ABIName := '';
    ATarget.CPUName := '';
    ATarget.CPUFeatures := '';
    ATarget.ELFMachine := 0;
    ATarget.ELFFlags := 0;
    ATarget.ELFOSABI := 0;
    ATarget.ELFABIVersion := 0;
    ATarget.PageSize := 0;
    ATarget.PreferredImageBase := 0;
    ATarget.SymbolPrefix := '';
    ATarget.DefaultDynamicLoader := '';
    ATarget.DefaultLibC := '';
    FillChar(ATarget.DataLayout, SizeOf(ATarget.DataLayout), 0);
    ATarget.Capabilities := [];
    SetLength(ATarget.Registers, 0);
    Result := False;
  end;
end;

function GetTargetOrRaise(const AValue: string): TTargetDescriptor;
begin
  if not TryGetTarget(AValue, Result) then
    raise ERCCError.Create('error: unsupported target ''' + AValue + '''');
end;

function NativeTargetDescriptor: TTargetDescriptor;
var
  Architecture: TArchitecture;
  OperatingSystem: TOperatingSystem;
{$ifdef RCC_DRIVER_TESTING}
  TestTarget: string;
{$endif}
begin
{$ifdef RCC_DRIVER_TESTING}
  TestTarget := GetEnvironmentVariable('RCC_TEST_NATIVE_TARGET');
  if TestTarget <> '' then
  begin
    if not TryGetTarget(TestTarget, Result) then
      raise ERCCError.Create('error: invalid RCC_TEST_NATIVE_TARGET ''' +
        TestTarget + '''');
    Exit;
  end;
{$endif}

{$if defined(CPUX86_64)}
  Architecture := archX86_64;
{$elseif defined(CPUAARCH64) or defined(CPUARM64)}
  Architecture := archAArch64;
{$elseif defined(CPURISCV64)}
  Architecture := archRISCV64;
{$else}
  Architecture := archUnknown;
{$endif}

{$if defined(DARWIN)}
  OperatingSystem := osDarwin;
{$elseif defined(FREEBSD)}
  OperatingSystem := osFreeBSD;
{$elseif defined(OPENBSD)}
  OperatingSystem := osOpenBSD;
{$elseif defined(NETBSD)}
  OperatingSystem := osNetBSD;
{$elseif defined(LINUX)}
  OperatingSystem := osLinux;
{$else}
  OperatingSystem := osUnknown;
{$endif}

  if Architecture = archUnknown then
    raise ERCCError.Create(
      'error: rcc was built for an unsupported host architecture');
  if OperatingSystem = osUnknown then
    raise ERCCError.Create(
      'error: rcc was built for an unsupported host operating system');
  Result := MakeTarget(Architecture, OperatingSystem);
end;

function TargetMatchesNativeHost(const ATarget: TTargetDescriptor): Boolean;
var
  Native: TTargetDescriptor;
begin
  Native := NativeTargetDescriptor;
  Result := (ATarget.Architecture = Native.Architecture) and
    (ATarget.OperatingSystem = Native.OperatingSystem);
end;

function SupportedTargetTriples: rcc_types.TStringArray;
begin
  Result := nil;
  SetLength(Result, 14);
  Result[0] := 'x86_64-unknown-linux-rcc';
  Result[1] := 'aarch64-unknown-linux-rcc';
  Result[2] := 'riscv64-unknown-linux-rcc';
  Result[3] := 'x86_64-unknown-freebsd-rcc';
  Result[4] := 'aarch64-unknown-freebsd-rcc';
  Result[5] := 'riscv64-unknown-freebsd-rcc';
  Result[6] := 'x86_64-unknown-openbsd-rcc';
  Result[7] := 'aarch64-unknown-openbsd-rcc';
  Result[8] := 'riscv64-unknown-openbsd-rcc';
  Result[9] := 'x86_64-unknown-netbsd-rcc';
  Result[10] := 'aarch64-unknown-netbsd-rcc';
  Result[11] := 'riscv64-unknown-netbsd-rcc';
  Result[12] := 'x86_64-apple-darwin-rcc';
  Result[13] := 'aarch64-apple-darwin-rcc';
end;

function SupportedTargetsText: string;
var
  Targets: rcc_types.TStringArray;
  I: LongInt;
  T: TTargetDescriptor;
begin
  Result := '';
  Targets := SupportedTargetTriples;
  for I := 0 to High(Targets) do
  begin
    T := GetTargetOrRaise(Targets[I]);
    Result := Result + '  ' + TargetSummaryText(T) + LineEnding;
  end;
end;

function BuildTargetPredefinedMacros(const ATarget: TTargetDescriptor): rcc_types.TStringArray;
begin
  Result := nil;
  SetLength(Result, 0);
  AppendString(Result, '__RCC_TARGET_TRIPLE__="' + ATarget.Triple + '"');
  AppendString(Result, '__RCC_POINTER_WIDTH__=' +
    IntToStr(ATarget.DataLayout.PointerBits));
  AppendString(Result, '__SIZEOF_LONG_DOUBLE__=' +
    IntToStr(ATarget.DataLayout.LongDoubleBits div 8));
  AppendString(Result, '__RCC_LITTLE_ENDIAN__=1');
  if ATarget.OperatingSystem <> osDarwin then
  begin
    AppendString(Result, '__unix__=1');
    AppendString(Result, '__unix=1');
  end;
  if TargetIsELF(ATarget) then AppendString(Result, '__ELF__=1');
  case ATarget.OperatingSystem of
    osLinux:
      begin
        AppendString(Result, '__linux__=1');
        AppendString(Result, '__linux=1');
        AppendString(Result, 'linux=1');
      end;
    osFreeBSD:
      begin
        { Clang uses 8 for an unversioned FreeBSD target triple. }
        AppendString(Result, '__FreeBSD__=8');
        AppendString(Result, '__FreeBSD_cc_version=800001');
        AppendString(Result, '__freebsd__=1');
      end;
    osOpenBSD:
      begin
        AppendString(Result, '__OpenBSD__=1');
        AppendString(Result, '__openbsd__=1');
      end;
    osNetBSD:
      begin
        AppendString(Result, '__NetBSD__=1');
        AppendString(Result, '__netbsd__=1');
      end;
    osDarwin:
      begin
        AppendString(Result, '__APPLE__=1');
        AppendString(Result, '__APPLE_CC__=6000');
        AppendString(Result, '__MACH__=1');
        AppendString(Result, '__DYNAMIC__=1');
        AppendString(Result,
          '__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__=110000');
      end;
  end;
  AppendString(Result, '_LP64=1');
  case ATarget.Architecture of
    archX86_64:
      begin
        AppendString(Result, '__x86_64=1');
        AppendString(Result, '__x86_64__=1');
        AppendString(Result, '__amd64=1');
        AppendString(Result, '__amd64__=1');
        AppendString(Result, '__LP64__=1');
      end;
    archAArch64:
      begin
        AppendString(Result, '__aarch64__=1');
        if ATarget.OperatingSystem = osDarwin then
        begin
          AppendString(Result, '__arm64=1');
          AppendString(Result, '__arm64__=1');
        end;
        AppendString(Result, '__ARM_ARCH=8');
        AppendString(Result, '__ARM_ARCH_ISA_A64=1');
        AppendString(Result, '__ARM_ARCH_PROFILE=''A''');
        AppendString(Result, '__ARM_ARCH_8A=1');
        AppendString(Result, '__LP64__=1');
      end;
    archRISCV64:
      begin
        AppendString(Result, '__riscv=1');
        AppendString(Result, '__riscv_xlen=64');
        AppendString(Result, '__riscv_float_abi_double=1');
        AppendString(Result, '__LP64__=1');
      end;
  end;
end;

function TargetIntegerArgumentRegister(const ATarget: TTargetDescriptor;
  AIndex: LongInt): LongInt;
const
  X86Args: array[0..5] of LongInt = (7, 6, 2, 1, 8, 9);
begin
  case ATarget.Architecture of
    archX86_64:
      if (AIndex >= 0) and (AIndex <= High(X86Args)) then
        Exit(X86Args[AIndex]);
    archAArch64:
      if (AIndex >= 0) and (AIndex <= 7) then Exit(AIndex);
    archRISCV64:
      if (AIndex >= 0) and (AIndex <= 7) then Exit(10 + AIndex);
  end;
  Result := -1;
end;

function TargetIntegerReturnRegister(const ATarget: TTargetDescriptor): LongInt;
begin
  case ATarget.Architecture of
    archX86_64: Result := 0;
    archAArch64: Result := 0;
    archRISCV64: Result := 10;
  else
    Result := -1;
  end;
end;

function TargetFramePointerRegister(const ATarget: TTargetDescriptor): LongInt;
begin
  case ATarget.Architecture of
    archX86_64: Result := 5;
    archAArch64: Result := 29;
    archRISCV64: Result := 8;
  else
    Result := -1;
  end;
end;

function TargetStackPointerRegister(const ATarget: TTargetDescriptor): LongInt;
begin
  case ATarget.Architecture of
    archX86_64: Result := 4;
    archAArch64: Result := 31;
    archRISCV64: Result := 2;
  else
    Result := -1;
  end;
end;

function TargetLinkRegister(const ATarget: TTargetDescriptor): LongInt;
begin
  case ATarget.Architecture of
    archX86_64: Result := -1;
    archAArch64: Result := 30;
    archRISCV64: Result := 1;
  else
    Result := -1;
  end;
end;

function FindRegister(const ATarget: TTargetDescriptor;
  const AName: string; out ARegister: TRegisterInfo): Boolean;
var
  I: LongInt;
  V: string;
begin
  V := LowerCase(Trim(AName));
  for I := 0 to High(ATarget.Registers) do
    if LowerCase(ATarget.Registers[I].Name) = V then
    begin
      ARegister := ATarget.Registers[I];
      Exit(True);
    end;
  ARegister.Name := '';
  ARegister.Number := -1;
  ARegister.RegClass := rcSpecial;
  ARegister.WidthBits := 0;
  ARegister.CallerSaved := False;
  ARegister.CalleeSaved := False;
  ARegister.Reserved := True;
  Result := False;
end;

function TargetRegisterText(const ATarget: TTargetDescriptor): string;
var
  I: LongInt;
  ClassName, Flags: string;
begin
  Result := '';
  for I := 0 to High(ATarget.Registers) do
  begin
    case ATarget.Registers[I].RegClass of
      rcInteger: ClassName := 'integer';
      rcFloating: ClassName := 'floating';
      rcVector: ClassName := 'vector';
      rcSpecial: ClassName := 'special';
    else
      ClassName := 'unknown';
    end;
    Flags := '';
    if ATarget.Registers[I].CallerSaved then Flags := Flags + ' caller';
    if ATarget.Registers[I].CalleeSaved then Flags := Flags + ' callee';
    if ATarget.Registers[I].Reserved then Flags := Flags + ' reserved';
    Result := Result + Format('  %-6s #%2d %-8s %3d-bit%s',
      [ATarget.Registers[I].Name,
       ATarget.Registers[I].Number,
       ClassName,
       ATarget.Registers[I].WidthBits,
       Flags]) + LineEnding;
  end;
end;

end.
