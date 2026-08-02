unit rcc_warning_catalog;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TWarningSeverity = (wsIgnored, wsRemark, wsWarning, wsError);
  TWarningDescriptor = record
    Name: string;
    Phase: string;
    DefaultSeverity: TWarningSeverity;
    EnabledByDefault: Boolean;
  end;
  TWarningDescriptorArray = array of TWarningDescriptor;

function BuildWarningCatalog: TWarningDescriptorArray;
function FindWarning(const ACatalog: TWarningDescriptorArray;
  const AName: string; out ADescriptor: TWarningDescriptor): Boolean;
function WarningCatalogSummary(const ACatalog: TWarningDescriptorArray): string;

implementation

procedure AddWarning(var AValues: TWarningDescriptorArray;
  const AName, APhase: string; ASeverity: TWarningSeverity;
  AEnabled: Boolean);
var N: LongInt;
begin
  N := Length(AValues); SetLength(AValues, N + 1);
  AValues[N].Name := AName; AValues[N].Phase := APhase;
  AValues[N].DefaultSeverity := ASeverity;
  AValues[N].EnabledByDefault := AEnabled;
end;

function BuildWarningCatalog: TWarningDescriptorArray;
begin
  Result := nil;
  AddWarning(Result,
    'address', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'aggregate-return', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'aggressive-loop-optimizations', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'array-bounds', 'backend',
    wsWarning, True);
  AddWarning(Result,
    'array-parameter', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'attribute-alias', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'attributes', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'bad-function-cast', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'bool-compare', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'builtin-declaration-mismatch', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'cast-align', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'cast-function-type', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'cast-qual', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'char-subscripts', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'clobbered', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'comment', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'conversion', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'conversion-null', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'cpp', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'dangling-else', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'dangling-pointer', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'date-time', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'deprecated-declarations', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'discarded-array-qualifiers', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'discarded-qualifiers', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'div-by-zero', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'double-promotion', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'duplicated-branches', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'duplicated-cond', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'empty-body', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'endif-labels', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'enum-compare', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'enum-conversion', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'error', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'expansion-to-defined', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'extra', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'format', 'frontend',
    wsWarning, True);
  AddWarning(Result,
    'format-extra-args', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'format-nonliteral', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'format-overflow', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'format-security', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'format-signedness', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'format-truncation', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'format-y2k', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'frame-address', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'free-nonheap-object', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'implicit', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'implicit-fallthrough', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'implicit-function-declaration', 'frontend',
    wsWarning, True);
  AddWarning(Result,
    'implicit-int', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'incompatible-pointer-types', 'optimizer',
    wsWarning, True);
  AddWarning(Result,
    'init-self', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'int-conversion', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'int-to-pointer-cast', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'jump-misses-init', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'logical-not-parentheses', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'logical-op', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'main', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'maybe-uninitialized', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'memset-elt-size', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'memset-transposed-args', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'misleading-indentation', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'missing-braces', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'missing-declarations', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'missing-field-initializers', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'missing-include-dirs', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'missing-parameter-type', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'missing-prototypes', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'multistatement-macros', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'nested-externs', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'nonnull', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'nonnull-compare', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'null-dereference', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'old-style-declaration', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'old-style-definition', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'openmp-simd', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'overflow', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'override-init', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'packed', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'packed-bitfield-compat', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'parentheses', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'pointer-arith', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'pointer-compare', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'pointer-sign', 'backend',
    wsWarning, True);
  AddWarning(Result,
    'pragmas', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'redundant-decls', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'restrict', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'return-local-addr', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'return-type', 'frontend',
    wsWarning, True);
  AddWarning(Result,
    'sequence-point', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'shadow', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'shift-count-negative', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'shift-count-overflow', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'shift-negative-value', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'shift-overflow', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'sign-compare', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'sign-conversion', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'sizeof-array-argument', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'sizeof-pointer-div', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'sizeof-pointer-memaccess', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'stack-usage', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'strict-aliasing', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'strict-overflow', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'strict-prototypes', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'string-compare', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'stringop-overflow', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'stringop-truncation', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'switch', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'switch-bool', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'switch-default', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'switch-enum', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'tautological-compare', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'traditional', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'trampolines', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'type-limits', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'undef', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'uninitialized', 'frontend',
    wsWarning, True);
  AddWarning(Result,
    'unknown-pragmas', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'unreachable-code', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'unsafe-loop-optimizations', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'unused', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'unused-but-set-parameter', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'unused-but-set-variable', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'unused-function', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'unused-label', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'unused-local-typedefs', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'unused-macros', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'unused-parameter', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'unused-result', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'unused-value', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'unused-variable', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'varargs', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'variadic-macros', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'vector-operation-performance', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'vla', 'optimizer',
    wsWarning, False);
  AddWarning(Result,
    'vla-parameter', 'backend',
    wsWarning, False);
  AddWarning(Result,
    'volatile-register-var', 'frontend',
    wsWarning, False);
  AddWarning(Result,
    'write-strings', 'sema',
    wsWarning, False);
  AddWarning(Result,
    'zero-length-bounds', 'optimizer',
    wsWarning, False);
end;

function FindWarning(const ACatalog: TWarningDescriptorArray;
  const AName: string; out ADescriptor: TWarningDescriptor): Boolean;
var I: LongInt;
begin
  for I := 0 to High(ACatalog) do if ACatalog[I].Name = AName then
  begin ADescriptor := ACatalog[I]; Exit(True); end;
  ADescriptor.Name := ''; ADescriptor.Phase := '';
  ADescriptor.DefaultSeverity := wsIgnored; ADescriptor.EnabledByDefault := False;
  Result := False;
end;

function WarningCatalogSummary(const ACatalog: TWarningDescriptorArray): string;
var I, Enabled: LongInt;
begin
  Enabled := 0;
  for I := 0 to High(ACatalog) do if ACatalog[I].EnabledByDefault then Inc(Enabled);
  Result := Format('%d warning groups (%d enabled by default)',
    [Length(ACatalog), Enabled]);
end;

end.
