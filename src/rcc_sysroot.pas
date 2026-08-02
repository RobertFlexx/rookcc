unit rcc_sysroot;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_arch;

type
  THeaderProfile = (
    hpFreestanding,
    hpISO,
    hpPOSIX,
    hpGNU,
    hpRCC
  );

  THeaderSupport = (
    hsUnavailable,
    hsShim,
    hsNative,
    hsForwarded
  );

  THeaderRecord = record
    IncludeName: string;
    RelativePath: string;
    Profile: THeaderProfile;
    Support: THeaderSupport;
    HostedOnly: Boolean;
    TargetSpecific: Boolean;
    Notes: string;
  end;
  THeaderRecordArray = array of THeaderRecord;

  TSysrootLayout = record
    Root: string;
    ResourceRoot: string;
    GenericIncludeRoot: string;
    TargetIncludeRoot: string;
    RuntimeRoot: string;
    LibraryRoot: string;
    CRTObjectRoot: string;
    DynamicLoader: string;
    Target: TTargetDescriptor;
  end;

function HeaderProfileName(AProfile: THeaderProfile): string;
function HeaderSupportName(ASupport: THeaderSupport): string;
function StandardHeaderCatalog: THeaderRecordArray;
function FindHeaderRecord(const AIncludeName: string;
  out ARecord: THeaderRecord): Boolean;
function ProfileForOptions(const AOptions: TCompilerOptions): THeaderProfile;
function ResolveSysrootLayout(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor): TSysrootLayout;
function ResolveShimHeader(const ALayout: TSysrootLayout;
  const AIncludeName: string; out APath: string): Boolean;
function HeaderAllowed(const ARecord: THeaderRecord;
  AProfile: THeaderProfile; AFreestanding: Boolean): Boolean;
function ValidateHeaderRequest(const AIncludeName: string;
  AProfile: THeaderProfile; AFreestanding: Boolean;
  out AReason: string): Boolean;
function SysrootSearchPaths(const ALayout: TSysrootLayout): rcc_types.TStringArray;
function SysrootLayoutText(const ALayout: TSysrootLayout): string;
function HeaderCatalogText: string;

implementation

procedure AppendString(var AValues: rcc_types.TStringArray; const AValue: string);
var
  N: LongInt;
begin
  if AValue = '' then Exit;
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AValue;
end;

procedure AddHeader(var AHeaders: THeaderRecordArray;
  const AIncludeName, ARelativePath: string; AProfile: THeaderProfile;
  ASupport: THeaderSupport; AHostedOnly, ATargetSpecific: Boolean;
  const ANotes: string);
var
  N: LongInt;
begin
  N := Length(AHeaders);
  SetLength(AHeaders, N + 1);
  AHeaders[N].IncludeName := AIncludeName;
  AHeaders[N].RelativePath := ARelativePath;
  AHeaders[N].Profile := AProfile;
  AHeaders[N].Support := ASupport;
  AHeaders[N].HostedOnly := AHostedOnly;
  AHeaders[N].TargetSpecific := ATargetSpecific;
  AHeaders[N].Notes := ANotes;
end;

function HeaderProfileName(AProfile: THeaderProfile): string;
begin
  case AProfile of
    hpFreestanding: Result := 'freestanding';
    hpISO: Result := 'iso-c';
    hpPOSIX: Result := 'posix';
    hpGNU: Result := 'gnu';
    hpRCC: Result := 'rcc';
  else
    Result := 'unknown';
  end;
end;

function HeaderSupportName(ASupport: THeaderSupport): string;
begin
  case ASupport of
    hsUnavailable: Result := 'unavailable';
    hsShim: Result := 'shim';
    hsNative: Result := 'native';
    hsForwarded: Result := 'forwarded';
  else
    Result := 'unknown';
  end;
end;

function StandardHeaderCatalog: THeaderRecordArray;
begin
  Result := nil;
  SetLength(Result, 0);
  AddHeader(Result, 'stddef.h', 'stddef.h', hpFreestanding, hsNative,
    False, False, 'core types plus native offsetof lowering');
  AddHeader(Result, 'stdint.h', 'stdint.h', hpFreestanding, hsNative,
    False, True, 'target-width integer types');
  AddHeader(Result, 'stdbool.h', 'stdbool.h', hpFreestanding, hsNative,
    False, False, 'C boolean macros');
  AddHeader(Result, 'stdalign.h', 'stdalign.h', hpFreestanding, hsShim,
    False, False, 'alignment spelling aliases');
  AddHeader(Result, 'stdarg.h', 'stdarg.h', hpFreestanding, hsNative,
    False, True, 'native SysV AMD64 variadic register and overflow traversal');
  AddHeader(Result, 'limits.h', 'limits.h', hpISO, hsNative,
    False, True, 'integer limits from the target data layout');
  AddHeader(Result, 'float.h', 'float.h', hpISO, hsUnavailable,
    False, True, 'requires complete floating-point semantics');
  AddHeader(Result, 'assert.h', 'assert.h', hpISO, hsShim,
    False, False, 'assert macro and failure hook');
  AddHeader(Result, 'errno.h', 'errno.h', hpISO, hsShim,
    True, True, 'hosted errno declaration');
  AddHeader(Result, 'ctype.h', 'ctype.h', hpISO, hsNative,
    True, False, 'ASCII-compatible character classification runtime');
  AddHeader(Result, 'string.h', 'string.h', hpISO, hsNative,
    True, False, 'memory and string routines');
  AddHeader(Result, 'stdlib.h', 'stdlib.h', hpISO, hsNative,
    True, False, 'allocation, conversion, process helpers, hosted atexit bridge');
  AddHeader(Result, 'stdio.h', 'stdio.h', hpISO, hsShim,
    True, False, 'limited stream and formatted-output surface');
  AddHeader(Result, 'time.h', 'time.h', hpISO, hsShim,
    True, True, 'hosted calendar and POSIX clock declarations');
  AddHeader(Result, 'signal.h', 'signal.h', hpISO, hsShim,
    True, True, 'portable signal constants and sig_atomic_t');
  AddHeader(Result, 'locale.h', 'locale.h', hpISO, hsShim,
    True, False, 'locale categories and hosted libc locale declarations');
  AddHeader(Result, 'wchar.h', 'wchar.h', hpISO, hsShim,
    True, True, 'wide-character strings and multibyte conversion declarations');
  AddHeader(Result, 'wctype.h', 'wctype.h', hpISO, hsShim,
    True, True, 'wide-character classification and conversion declarations');
  AddHeader(Result, 'setjmp.h', 'setjmp.h', hpISO, hsUnavailable,
    True, True, 'non-local control transfer incomplete');
  AddHeader(Result, 'math.h', 'math.h', hpISO, hsShim,
    True, False, 'float/double C17 libm surface; long double remains unavailable');
  AddHeader(Result, 'unistd.h', 'unistd.h', hpPOSIX, hsNative,
    True, True, 'selected Linux/POSIX syscall wrappers');
  AddHeader(Result, 'fcntl.h', 'fcntl.h', hpPOSIX, hsNative,
    True, True, 'selected open flags and file operations');
  AddHeader(Result, 'sys/types.h', 'sys/types.h', hpPOSIX, hsShim,
    True, True, 'POSIX scalar typedef shim');
  AddHeader(Result, 'sys/time.h', 'sys/time.h', hpPOSIX, hsShim,
    True, True, 'hosted Linux timeval layout and gettimeofday declaration');
  AddHeader(Result, 'sys/socket.h', 'sys/socket.h', hpPOSIX, hsShim,
    True, True, 'hosted Linux socket types and libc declarations');
  AddHeader(Result, 'netinet/in.h', 'netinet/in.h', hpPOSIX, hsShim,
    True, True, 'IPv4 address types and byte-order declarations');
  AddHeader(Result, 'arpa/inet.h', 'arpa/inet.h', hpPOSIX, hsShim,
    True, True, 'hosted IPv4 text conversion declarations');
  AddHeader(Result, 'sys/stat.h', 'sys/stat.h', hpPOSIX, hsShim,
    True, True, 'Linux x86-64 stat layout and hosted libc declarations');
  AddHeader(Result, 'sys/mman.h', 'sys/mman.h', hpPOSIX, hsShim,
    True, True, 'hosted Linux memory-mapping constants and libc declarations');
  AddHeader(Result, 'sys/wait.h', 'sys/wait.h', hpPOSIX, hsShim,
    True, True, 'hosted wait macros and libc declarations');
  AddHeader(Result, 'pthread.h', 'pthread.h', hpPOSIX, hsShim,
    True, True, 'hosted Linux pthread declarations and -pthread linking');
  AddHeader(Result, 'dirent.h', 'dirent.h', hpPOSIX, hsShim,
    True, True, 'hosted directory stream and dirent declarations');
  AddHeader(Result, 'poll.h', 'poll.h', hpPOSIX, hsShim,
    True, True, 'hosted poll descriptor ABI and libc declaration');
  AddHeader(Result, 'getopt.h', 'getopt.h', hpGNU, hsShim,
    True, False, 'getopt/getopt_long declarations backed by hosted libc');
  AddHeader(Result, 'dlfcn.h', 'dlfcn.h', hpGNU, hsShim,
    True, False, 'dlopen/dlsym/dlclose/dlerror and GNU dladdr declarations');
  AddHeader(Result, 'ncurses.h', 'ncurses.h', hpGNU, hsShim,
    True, True, 'wide ncurses forwarding header');
  AddHeader(Result, 'ncursesw/ncurses.h', 'ncursesw/ncurses.h', hpGNU, hsShim,
    True, True, 'wide ncurses ABI declarations for hosted Linux targets');
  AddHeader(Result, 'execinfo.h', 'execinfo.h', hpGNU, hsUnavailable,
    True, False, 'GNU backtrace API incomplete');
  AddHeader(Result, 'malloc.h', 'malloc.h', hpGNU, hsShim,
    True, False, 'GNU allocation compatibility declarations');
  AddHeader(Result, 'rcc.h', 'rcc.h', hpRCC, hsNative,
    False, False, 'portable rcc convenience API');
  AddHeader(Result, 'rcc/features.h', 'rcc/features.h', hpRCC, hsNative,
    False, False, 'feature-test policy');
  AddHeader(Result, 'rcc/version.h', 'rcc/version.h', hpRCC, hsNative,
    False, False, 'compiler and resource version contract');
  AddHeader(Result, 'rcc/capabilities.h', 'rcc/capabilities.h', hpRCC,
    hsNative, False, True, 'machine-readable capability matrix');
end;

function FindHeaderRecord(const AIncludeName: string;
  out ARecord: THeaderRecord): Boolean;
var
  Headers: THeaderRecordArray;
  I: LongInt;
begin
  Headers := StandardHeaderCatalog;
  for I := 0 to High(Headers) do
    if Headers[I].IncludeName = AIncludeName then
    begin
      ARecord := Headers[I];
      Exit(True);
    end;
  ARecord.IncludeName := '';
  ARecord.RelativePath := '';
  ARecord.Profile := hpFreestanding;
  ARecord.Support := hsUnavailable;
  ARecord.HostedOnly := False;
  ARecord.TargetSpecific := False;
  ARecord.Notes := '';
  Result := False;
end;

function ProfileRank(AProfile: THeaderProfile): LongInt;
begin
  case AProfile of
    hpFreestanding: Result := 0;
    hpISO: Result := 1;
    hpPOSIX: Result := 2;
    hpGNU: Result := 3;
    hpRCC: Result := 4;
  else
    Result := -1;
  end;
end;

function ProfileForOptions(const AOptions: TCompilerOptions): THeaderProfile;
var
  I: LongInt;
  D: string;
begin
  if AOptions.Freestanding then Exit(hpFreestanding);
  if AOptions.Standard = csRCC then Exit(hpRCC);
  Result := hpISO;
  if IsGNUStandard(AOptions.Standard) then Result := hpGNU;
  for I := 0 to High(AOptions.Defines) do
  begin
    D := AOptions.Defines[I];
    if Pos('_RCC_SOURCE', D) = 1 then Exit(hpRCC);
    if Pos('_GNU_SOURCE', D) = 1 then Result := hpGNU
    else if (Pos('_POSIX_SOURCE', D) = 1) or
            (Pos('_POSIX_C_SOURCE', D) = 1) then
      if ProfileRank(Result) < ProfileRank(hpPOSIX) then Result := hpPOSIX;
  end;
end;

function ResolveSysrootLayout(const AOptions: TCompilerOptions;
  const ATarget: TTargetDescriptor): TSysrootLayout;
var
  Root: string;
begin
  Result.Target := ATarget;
  Result.ResourceRoot := ExpandFileName(AOptions.ResourceDir);
  Root := AOptions.Sysroot;
  if Root = '' then Root := Result.ResourceRoot;
  if Root <> '' then Root := ExcludeTrailingPathDelimiter(ExpandFileName(Root));
  Result.Root := Root;
  if Result.ResourceRoot <> '' then
    Result.GenericIncludeRoot := IncludeTrailingPathDelimiter(
      Result.ResourceRoot) + 'include'
  else Result.GenericIncludeRoot := '';
  if Result.ResourceRoot <> '' then
    Result.TargetIncludeRoot := IncludeTrailingPathDelimiter(
      Result.ResourceRoot) + 'targets' + PathDelim + ATarget.Triple +
      PathDelim + 'include'
  else Result.TargetIncludeRoot := '';
  if Root <> '' then
  begin
    Result.RuntimeRoot := IncludeTrailingPathDelimiter(Root) + 'runtime' +
      PathDelim + ATarget.Triple;
    Result.LibraryRoot := IncludeTrailingPathDelimiter(Root) + 'lib' +
      PathDelim + ATarget.Triple;
    Result.CRTObjectRoot := IncludeTrailingPathDelimiter(Root) + 'crt' +
      PathDelim + ATarget.Triple;
  end
  else
  begin
    Result.RuntimeRoot := '';
    Result.LibraryRoot := '';
    Result.CRTObjectRoot := '';
  end;
  Result.DynamicLoader := ATarget.DefaultDynamicLoader;
end;

function ResolveShimHeader(const ALayout: TSysrootLayout;
  const AIncludeName: string; out APath: string): Boolean;
var
  H: THeaderRecord;
  Candidate: string;
begin
  APath := '';
  if not FindHeaderRecord(AIncludeName, H) then Exit(False);
  if H.Support = hsUnavailable then Exit(False);
  if H.TargetSpecific and (ALayout.TargetIncludeRoot <> '') then
  begin
    Candidate := IncludeTrailingPathDelimiter(ALayout.TargetIncludeRoot) +
      H.RelativePath;
    if FileExists(Candidate) then
    begin
      APath := Candidate;
      Exit(True);
    end;
  end;
  if ALayout.GenericIncludeRoot <> '' then
  begin
    Candidate := IncludeTrailingPathDelimiter(ALayout.GenericIncludeRoot) +
      H.RelativePath;
    if FileExists(Candidate) then
    begin
      APath := Candidate;
      Exit(True);
    end;
  end;
  Result := False;
end;

function HeaderAllowed(const ARecord: THeaderRecord;
  AProfile: THeaderProfile; AFreestanding: Boolean): Boolean;
begin
  if ARecord.Support = hsUnavailable then Exit(False);
  if AFreestanding and ARecord.HostedOnly then Exit(False);
  if ARecord.Profile = hpRCC then
    Exit(AProfile = hpRCC);
  Result := ProfileRank(AProfile) >= ProfileRank(ARecord.Profile);
end;

function ValidateHeaderRequest(const AIncludeName: string;
  AProfile: THeaderProfile; AFreestanding: Boolean;
  out AReason: string): Boolean;
var
  H: THeaderRecord;
begin
  AReason := '';
  if not FindHeaderRecord(AIncludeName, H) then
  begin
    AReason := 'header is not present in the RookCC shim catalog';
    Exit(False);
  end;
  if H.Support = hsUnavailable then
  begin
    AReason := H.Notes;
    Exit(False);
  end;
  if AFreestanding and H.HostedOnly then
  begin
    AReason := 'header requires hosted compilation';
    Exit(False);
  end;
  if not HeaderAllowed(H, AProfile, AFreestanding) then
  begin
    AReason := 'header requires the ' + HeaderProfileName(H.Profile) +
      ' feature profile';
    Exit(False);
  end;
  Result := True;
end;

function SysrootSearchPaths(const ALayout: TSysrootLayout): rcc_types.TStringArray;
begin
  Result := nil;
  SetLength(Result, 0);
  if ALayout.TargetIncludeRoot <> '' then
    AppendString(Result, ALayout.TargetIncludeRoot);
  if ALayout.GenericIncludeRoot <> '' then
    AppendString(Result, ALayout.GenericIncludeRoot);
  if ALayout.Root <> '' then
  begin
    AppendString(Result, IncludeTrailingPathDelimiter(ALayout.Root) +
      'usr' + PathDelim + 'include' + PathDelim + ALayout.Target.Triple);
    AppendString(Result, IncludeTrailingPathDelimiter(ALayout.Root) +
      'usr' + PathDelim + 'include');
  end;
end;

function SysrootLayoutText(const ALayout: TSysrootLayout): string;
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('target: ' + ALayout.Target.Triple);
    Lines.Add('root: ' + ALayout.Root);
    Lines.Add('resource: ' + ALayout.ResourceRoot);
    Lines.Add('generic include: ' + ALayout.GenericIncludeRoot);
    Lines.Add('target include: ' + ALayout.TargetIncludeRoot);
    Lines.Add('runtime: ' + ALayout.RuntimeRoot);
    Lines.Add('libraries: ' + ALayout.LibraryRoot);
    Lines.Add('crt objects: ' + ALayout.CRTObjectRoot);
    Lines.Add('dynamic loader: ' + ALayout.DynamicLoader);
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function HeaderCatalogText: string;
var
  Headers: THeaderRecordArray;
  Lines: TStringList;
  I: LongInt;
begin
  Headers := StandardHeaderCatalog;
  Lines := TStringList.Create;
  try
    for I := 0 to High(Headers) do
      Lines.Add(Format('%-24s %-13s %-12s %s',
        [Headers[I].IncludeName, HeaderProfileName(Headers[I].Profile),
         HeaderSupportName(Headers[I].Support), Headers[I].Notes]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
