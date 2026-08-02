unit rcc_option_catalog;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TOptionSupport = (osAccepted, osIgnoredCompatible, osRejected);
  TOptionDescriptor = record
    Spelling: string;
    GroupName: string;
    Support: TOptionSupport;
    ArgumentCount: LongInt;
  end;
  TOptionDescriptorArray = array of TOptionDescriptor;

function BuildOptionCatalog: TOptionDescriptorArray;
function FindOptionDescriptor(const ACatalog: TOptionDescriptorArray;
  const ASpelling: string; out ADescriptor: TOptionDescriptor): Boolean;
function OptionSupportName(ASupport: TOptionSupport): string;
function OptionCatalogSummary(const ACatalog: TOptionDescriptorArray): string;

implementation

procedure AddOption(var AValues: TOptionDescriptorArray;
  const ASpelling, AGroup: string; ASupport: TOptionSupport;
  AArgumentCount: LongInt);
var N: LongInt;
begin
  N := Length(AValues); SetLength(AValues, N + 1);
  AValues[N].Spelling := ASpelling; AValues[N].GroupName := AGroup;
  AValues[N].Support := ASupport; AValues[N].ArgumentCount := AArgumentCount;
end;

function BuildOptionCatalog: TOptionDescriptorArray;
begin
  Result := nil;
  AddOption(Result,
    '-c', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-S', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-E', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-o', 'codegen',
    osAccepted, 1);
  AddOption(Result,
    '-pipe', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-v', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-###', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-g', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-g0', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-g1', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-g2', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-g3', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ggdb', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-gdwarf-2', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-gdwarf-3', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-gdwarf-4', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-gdwarf-5', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-gstabs', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-feliminate-unused-debug-symbols', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-femit-struct-debug-baseonly', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fdebug-prefix-map', 'codegen',
    osIgnoredCompatible, 1);
  AddOption(Result,
    '-ffile-prefix-map', 'codegen',
    osRejected, 1);
  AddOption(Result,
    '-fmacro-prefix-map', 'codegen',
    osIgnoredCompatible, 1);
  AddOption(Result,
    '-save-temps', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-save-temps=obj', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-dumpmachine', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-dumpversion', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-print-search-dirs', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-print-file-name', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-print-prog-name', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-print-multi-lib', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-print-multi-directory', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-print-sysroot', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-print-sysroot-headers-suffix', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-time', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftime-report', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fstats', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fdiagnostics-color', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fdiagnostics-show-option', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fdiagnostics-show-caret', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fdiagnostics-parseable-fixits', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fmessage-length', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fmax-errors', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fsyntax-only', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-pedantic', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-pedantic-errors', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-w', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-Wall', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wextra', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Werror', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-fstrict-aliasing', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-strict-aliasing', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fomit-frame-pointer', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-omit-frame-pointer', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-finline', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fno-inline', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-finline-functions', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-finline-small-functions', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fearly-inlining', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fipa-cp', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fipa-sra', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fipa-icf', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fipa-reference', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fipa-pure-const', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fipa-modref', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftree-dce', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftree-dominator-opts', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-ftree-sccp', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftree-pre', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftree-loop-optimize', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-ftree-vectorize', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftree-slp-vectorize', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-funroll-loops', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-funroll-all-loops', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fpeel-loops', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-funswitch-loops', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fsplit-loops', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fsplit-paths', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fpredictive-commoning', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fgcse', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fgcse-after-reload', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fcse-follow-jumps', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fcse-skip-blocks', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fexpensive-optimizations', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fdelete-null-pointer-checks', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fthread-jumps', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fcrossjumping', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fif-conversion', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fif-conversion2', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fschedule-insns', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fschedule-insns2', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-frename-registers', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fweb', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-freorder-blocks', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-freorder-functions', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fmerge-constants', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fmerge-all-constants', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-ffunction-sections', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fdata-sections', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fcommon', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fno-common', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fpic', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-fPIC', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-fpie', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-fPIE', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-fplt', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fno-plt', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fsemantic-interposition', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-semantic-interposition', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fvisibility=default', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fvisibility=hidden', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fstack-protector', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fstack-protector-strong', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fstack-protector-all', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fstack-clash-protection', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fcf-protection', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fexceptions', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-exceptions', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-funwind-tables', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fasynchronous-unwind-tables', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-asynchronous-unwind-tables', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fshort-enums', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fshort-wchar', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fsigned-char', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-funsigned-char', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fwrapv', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftrapv', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fstrict-overflow', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-strict-overflow', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ffast-math', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fno-math-errno', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-funsafe-math-optimizations', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ffinite-math-only', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-frounding-math', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fsignaling-nans', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-freciprocal-math', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fassociative-math', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fcx-limited-range', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fexcess-precision=standard', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fexcess-precision=fast', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ffreestanding', 'codegen',
    osAccepted, 0);
  AddOption(Result,
    '-fhosted', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fbuiltin', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-builtin', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-builtin-malloc', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fno-builtin-memcpy', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-builtin-printf', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-builtin-strlen', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fopenmp', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fopenacc', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fsanitize=address', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fsanitize=undefined', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fsanitize=thread', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fsanitize=leak', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fsanitize=memory', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fprofile-arcs', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftest-coverage', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fprofile-generate', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fprofile-use', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-flto', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fno-lto', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ffat-lto-objects', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fwhole-program', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fplugin', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fplugin-arg', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-frecord-gcc-switches', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fno-record-gcc-switches', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fident', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-ident', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fleading-underscore', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-leading-underscore', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fplan9-extensions', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fms-extensions', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-asm', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fgnu89-inline', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fno-gnu89-inline', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-finput-charset', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fexec-charset', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fwide-exec-charset', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fworking-directory', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fno-working-directory', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fpch-preprocess', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fdirectives-only', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fpreprocessed', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fcanonical-system-headers', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-ftrack-macro-expansion', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fmodules', 'codegen',
    osRejected, 0);
  AddOption(Result,
    '-fmodule-header', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-fmodule-mapper', 'codegen',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-Waddress', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Waggregate-return', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Waggressive-loop-optimizations', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Warray-bounds', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Warray-parameter', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wattribute-alias', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wattributes', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wbad-function-cast', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wbool-compare', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wbuiltin-declaration-mismatch', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wcast-align', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wcast-function-type', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wcast-qual', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wchar-subscripts', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wclobbered', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wcomment', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wconversion', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wconversion-null', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wcpp', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wdangling-else', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wdangling-pointer', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wdate-time', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wdeprecated-declarations', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wdiscarded-array-qualifiers', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wdiscarded-qualifiers', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wdiv-by-zero', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wdouble-promotion', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wduplicated-branches', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wduplicated-cond', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wempty-body', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wendif-labels', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wenum-compare', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wenum-conversion', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wexpansion-to-defined', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wformat', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wformat-extra-args', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wformat-nonliteral', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wformat-overflow', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wformat-security', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wformat-signedness', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wformat-truncation', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wformat-y2k', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wframe-address', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wfree-nonheap-object', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wimplicit', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wimplicit-fallthrough', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wimplicit-function-declaration', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wimplicit-int', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wincompatible-pointer-types', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Winit-self', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wint-conversion', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wint-to-pointer-cast', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wjump-misses-init', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wlogical-not-parentheses', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wlogical-op', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmain', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmaybe-uninitialized', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmemset-elt-size', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmemset-transposed-args', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmisleading-indentation', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmissing-braces', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmissing-declarations', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmissing-field-initializers', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmissing-include-dirs', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmissing-parameter-type', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmissing-prototypes', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wmultistatement-macros', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wnested-externs', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wnonnull', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wnonnull-compare', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wnull-dereference', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wold-style-declaration', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wold-style-definition', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wopenmp-simd', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Woverflow', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Woverride-init', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wpacked', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wpacked-bitfield-compat', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wparentheses', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wpointer-arith', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wpointer-compare', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wpointer-sign', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wpragmas', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wredundant-decls', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wrestrict', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wreturn-local-addr', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wreturn-type', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wsequence-point', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wshadow', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wshift-count-negative', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wshift-count-overflow', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wshift-negative-value', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wshift-overflow', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wsign-compare', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wsign-conversion', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wsizeof-array-argument', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wsizeof-pointer-div', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wsizeof-pointer-memaccess', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wstack-usage', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wstrict-aliasing', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wstrict-overflow', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wstrict-prototypes', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wstring-compare', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wstringop-overflow', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wstringop-truncation', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wswitch', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wswitch-bool', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wswitch-default', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wswitch-enum', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wtautological-compare', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wtraditional', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wtrampolines', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wtype-limits', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wundef', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wuninitialized', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunknown-pragmas', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunreachable-code', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunsafe-loop-optimizations', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-but-set-parameter', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-but-set-variable', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-function', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-label', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-local-typedefs', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-macros', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-parameter', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-result', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-value', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wunused-variable', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wvarargs', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wvariadic-macros', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wvector-operation-performance', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wvla', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wvla-parameter', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wvolatile-register-var', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wwrite-strings', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-Wzero-length-bounds', 'diagnostic',
    osAccepted, 0);
  AddOption(Result,
    '-march=', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mcpu=', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mtune=', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mabi=', 'target',
    osRejected, 0);
  AddOption(Result,
    '-m32', 'target',
    osRejected, 0);
  AddOption(Result,
    '-m64', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mx32', 'target',
    osRejected, 0);
  AddOption(Result,
    '-msse', 'target',
    osRejected, 0);
  AddOption(Result,
    '-msse2', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-msse3', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mssse3', 'target',
    osRejected, 0);
  AddOption(Result,
    '-msse4', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-msse4.1', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-msse4.2', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mavx', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mavx2', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mavx512f', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mfma', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mpopcnt', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mlzcnt', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mbmi', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mbmi2', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-maes', 'target',
    osRejected, 0);
  AddOption(Result,
    '-msha', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mcrc', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mneon', 'target',
    osRejected, 0);
  AddOption(Result,
    '-msimd', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-msve', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-msve2', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mlse', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-moutline-atomics', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mstrict-align', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mno-strict-align', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mrelax', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mno-relax', 'target',
    osRejected, 0);
  AddOption(Result,
    '-msave-restore', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mriscv-attribute', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mcmodel=small', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mcmodel=medium', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mcmodel=large', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mtls-dialect=gnu', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mtls-dialect=gnu2', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mred-zone', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mno-red-zone', 'target',
    osRejected, 0);
  AddOption(Result,
    '-mstackrealign', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mpreferred-stack-boundary=', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mincoming-stack-boundary=', 'target',
    osRejected, 0);
  AddOption(Result,
    '-maccumulate-outgoing-args', 'target',
    osIgnoredCompatible, 0);
  AddOption(Result,
    '-mno-accumulate-outgoing-args', 'target',
    osIgnoredCompatible, 0);
end;

function FindOptionDescriptor(const ACatalog: TOptionDescriptorArray;
  const ASpelling: string; out ADescriptor: TOptionDescriptor): Boolean;
var I: LongInt;
begin
  for I := 0 to High(ACatalog) do if ACatalog[I].Spelling = ASpelling then
  begin ADescriptor := ACatalog[I]; Exit(True); end;
  ADescriptor.Spelling := ''; ADescriptor.GroupName := '';
  ADescriptor.Support := osRejected; ADescriptor.ArgumentCount := 0;
  Result := False;
end;

function OptionSupportName(ASupport: TOptionSupport): string;
begin
  case ASupport of
    osAccepted: Result := 'accepted';
    osIgnoredCompatible: Result := 'accepted-no-op';
    osRejected: Result := 'rejected';
  else Result := 'unknown'; end;
end;

function OptionCatalogSummary(const ACatalog: TOptionDescriptorArray): string;
var I, Accepted, Compatible, Rejected: LongInt;
begin
  Accepted := 0; Compatible := 0; Rejected := 0;
  for I := 0 to High(ACatalog) do case ACatalog[I].Support of
    osAccepted: Inc(Accepted);
    osIgnoredCompatible: Inc(Compatible);
    osRejected: Inc(Rejected);
  end;
  Result := Format('%d CLI options (%d active, %d compatible no-op, %d rejected)',
    [Length(ACatalog), Accepted, Compatible, Rejected]);
end;

end.
