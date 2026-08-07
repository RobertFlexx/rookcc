unit rcc_gnu_compat;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types;

type
  TGNUExtension = (
    geAlternateKeywords,
    geAttributes,
    geStatementExpressions,
    geTypeof,
    geAlignof,
    geZeroLengthArrays,
    geFlexibleArrayMembers,
    geRangeDesignators,
    geCaseRanges,
    geComputedGoto,
    geNestedFunctions,
    geInlineAssembly,
    geLabelsAsValues,
    geBuiltins,
    geVectorTypes,
    geAtomicBuiltins,
    geThreadLocal,
    geComplexNumbers,
    ge128BitIntegers,
    geTransparentUnions,
    geAnonymousAggregates,
    geDesignatedInitializers,
    geVariadicMacros,
    geBinaryLiterals,
    geHexFloats,
    geOmittedConditionalOperand
  );
  TGNUExtensions = set of TGNUExtension;

  TGNUSupportLevel = (
    gslUnsupported,
    gslParsedAndIgnored,
    gslParsed,
    gslLowered,
    gslComplete
  );

  TGNUAttributeKind = (
    gakUnknown,
    gakAligned,
    gakAlwaysInline,
    gakCold,
    gakConstructor,
    gakDestructor,
    gakDeprecated,
    gakFormat,
    gakHot,
    gakLeaf,
    gakMalloc,
    gakNoInline,
    gakNoReturn,
    gakNonNull,
    gakPacked,
    gakPure,
    gakSection,
    gakSentinel,
    gakUnused,
    gakUsed,
    gakVisibility,
    gakWarnUnusedResult,
    gakWeak,
    gakAlias,
    gakCleanup,
    gakFallthrough,
    gakFlatten,
    gakMayAlias,
    gakNoSanitize,
    gakOptimize,
    gakTarget,
    gakVectorSize,
    gakMode,
    gakMSABI,
    gakSysVABI,
    gakStdCall,
    gakCDecl,
    gakTransparentUnion,
    gakCommon,
    gakNoCommon,
    gakTLSModel,
    gakIFunc,
    gakInterrupt,
    gakNaked
  );

  TGNUAttribute = record
    Kind: TGNUAttributeKind;
    Name: string;
    Arguments: rcc_types.TStringArray;
    SourceText: string;
  end;
  TGNUAttributeArray = array of TGNUAttribute;

function GNUExtensionName(AExtension: TGNUExtension): string;
function GNUSupportLevelName(ALevel: TGNUSupportLevel): string;
function GNUAttributeKindName(AKind: TGNUAttributeKind): string;
function ParseGNUAttributeName(const AName: string): TGNUAttributeKind;
function GNUExtensionSupport(AExtension: TGNUExtension): TGNUSupportLevel;
function EnabledGNUExtensions(AStandard: TCStandard): TGNUExtensions;
function GNUCompatibilityText: string;
function IsGNUAlternateKeyword(const AToken: string;
  out ACanonical: string): Boolean;
function GNUAttributeCanBeIgnored(AKind: TGNUAttributeKind): Boolean;
function GNUAttributeAffectsABI(AKind: TGNUAttributeKind): Boolean;
function GNUAttributeAffectsCodeGeneration(AKind: TGNUAttributeKind): Boolean;
function GNUAttributeSummary(const AAttribute: TGNUAttribute): string;
function NormalizeGNUIdentifier(const AName: string): string;

implementation

function NormalizeGNUIdentifier(const AName: string): string;
begin
  Result := LowerCase(Trim(AName));
  while (Length(Result) >= 4) and
        (Copy(Result, 1, 2) = '__') and
        (Copy(Result, Length(Result) - 1, 2) = '__') do
    Result := Copy(Result, 3, Length(Result) - 4);
end;

function GNUExtensionName(AExtension: TGNUExtension): string;
begin
  case AExtension of
    geAlternateKeywords: Result := 'alternate-keywords';
    geAttributes: Result := 'attributes';
    geStatementExpressions: Result := 'statement-expressions';
    geTypeof: Result := 'typeof';
    geAlignof: Result := 'alignof';
    geZeroLengthArrays: Result := 'zero-length-arrays';
    geFlexibleArrayMembers: Result := 'flexible-array-members';
    geRangeDesignators: Result := 'range-designators';
    geCaseRanges: Result := 'case-ranges';
    geComputedGoto: Result := 'computed-goto';
    geNestedFunctions: Result := 'nested-functions';
    geInlineAssembly: Result := 'inline-assembly';
    geLabelsAsValues: Result := 'labels-as-values';
    geBuiltins: Result := 'builtins';
    geVectorTypes: Result := 'vector-types';
    geAtomicBuiltins: Result := 'atomic-builtins';
    geThreadLocal: Result := 'thread-local';
    geComplexNumbers: Result := 'complex-numbers';
    ge128BitIntegers: Result := '128-bit-integers';
    geTransparentUnions: Result := 'transparent-unions';
    geAnonymousAggregates: Result := 'anonymous-aggregates';
    geDesignatedInitializers: Result := 'designated-initializers';
    geVariadicMacros: Result := 'variadic-macros';
    geBinaryLiterals: Result := 'binary-literals';
    geHexFloats: Result := 'hexadecimal-floats';
    geOmittedConditionalOperand: Result := 'omitted-conditional-operand';
  else
    Result := 'unknown';
  end;
end;

function GNUSupportLevelName(ALevel: TGNUSupportLevel): string;
begin
  case ALevel of
    gslUnsupported: Result := 'unsupported';
    gslParsedAndIgnored: Result := 'parsed-ignored';
    gslParsed: Result := 'parsed';
    gslLowered: Result := 'lowered';
    gslComplete: Result := 'complete';
  else
    Result := 'unknown';
  end;
end;

function GNUAttributeKindName(AKind: TGNUAttributeKind): string;
begin
  case AKind of
    gakUnknown: Result := 'unknown';
    gakAligned: Result := 'aligned';
    gakAlwaysInline: Result := 'always_inline';
    gakCold: Result := 'cold';
    gakConstructor: Result := 'constructor';
    gakDestructor: Result := 'destructor';
    gakDeprecated: Result := 'deprecated';
    gakFormat: Result := 'format';
    gakHot: Result := 'hot';
    gakLeaf: Result := 'leaf';
    gakMalloc: Result := 'malloc';
    gakNoInline: Result := 'noinline';
    gakNoReturn: Result := 'noreturn';
    gakNonNull: Result := 'nonnull';
    gakPacked: Result := 'packed';
    gakPure: Result := 'pure';
    gakSection: Result := 'section';
    gakSentinel: Result := 'sentinel';
    gakUnused: Result := 'unused';
    gakUsed: Result := 'used';
    gakVisibility: Result := 'visibility';
    gakWarnUnusedResult: Result := 'warn_unused_result';
    gakWeak: Result := 'weak';
    gakAlias: Result := 'alias';
    gakCleanup: Result := 'cleanup';
    gakFallthrough: Result := 'fallthrough';
    gakFlatten: Result := 'flatten';
    gakMayAlias: Result := 'may_alias';
    gakNoSanitize: Result := 'no_sanitize';
    gakOptimize: Result := 'optimize';
    gakTarget: Result := 'target';
    gakVectorSize: Result := 'vector_size';
    gakMode: Result := 'mode';
    gakMSABI: Result := 'ms_abi';
    gakSysVABI: Result := 'sysv_abi';
    gakStdCall: Result := 'stdcall';
    gakCDecl: Result := 'cdecl';
    gakTransparentUnion: Result := 'transparent_union';
    gakCommon: Result := 'common';
    gakNoCommon: Result := 'nocommon';
    gakTLSModel: Result := 'tls_model';
    gakIFunc: Result := 'ifunc';
    gakInterrupt: Result := 'interrupt';
    gakNaked: Result := 'naked';
  else
    Result := 'unknown';
  end;
end;

function ParseGNUAttributeName(const AName: string): TGNUAttributeKind;
var
  N: string;
begin
  N := NormalizeGNUIdentifier(AName);
  if N = 'aligned' then Result := gakAligned
  else if N = 'always_inline' then Result := gakAlwaysInline
  else if N = 'cold' then Result := gakCold
  else if N = 'constructor' then Result := gakConstructor
  else if N = 'destructor' then Result := gakDestructor
  else if N = 'deprecated' then Result := gakDeprecated
  else if N = 'format' then Result := gakFormat
  else if N = 'hot' then Result := gakHot
  else if N = 'leaf' then Result := gakLeaf
  else if N = 'malloc' then Result := gakMalloc
  else if N = 'noinline' then Result := gakNoInline
  else if N = 'noreturn' then Result := gakNoReturn
  else if N = 'nonnull' then Result := gakNonNull
  else if N = 'packed' then Result := gakPacked
  else if N = 'pure' then Result := gakPure
  else if N = 'section' then Result := gakSection
  else if N = 'sentinel' then Result := gakSentinel
  else if N = 'unused' then Result := gakUnused
  else if N = 'used' then Result := gakUsed
  else if N = 'visibility' then Result := gakVisibility
  else if N = 'warn_unused_result' then Result := gakWarnUnusedResult
  else if N = 'weak' then Result := gakWeak
  else if N = 'alias' then Result := gakAlias
  else if N = 'cleanup' then Result := gakCleanup
  else if N = 'fallthrough' then Result := gakFallthrough
  else if N = 'flatten' then Result := gakFlatten
  else if N = 'may_alias' then Result := gakMayAlias
  else if Pos('no_sanitize', N) = 1 then Result := gakNoSanitize
  else if N = 'optimize' then Result := gakOptimize
  else if N = 'target' then Result := gakTarget
  else if N = 'vector_size' then Result := gakVectorSize
  else if N = 'mode' then Result := gakMode
  else if N = 'ms_abi' then Result := gakMSABI
  else if N = 'sysv_abi' then Result := gakSysVABI
  else if N = 'stdcall' then Result := gakStdCall
  else if N = 'cdecl' then Result := gakCDecl
  else if N = 'transparent_union' then Result := gakTransparentUnion
  else if N = 'common' then Result := gakCommon
  else if N = 'nocommon' then Result := gakNoCommon
  else if N = 'tls_model' then Result := gakTLSModel
  else if N = 'ifunc' then Result := gakIFunc
  else if N = 'interrupt' then Result := gakInterrupt
  else if N = 'naked' then Result := gakNaked
  else Result := gakUnknown;
end;

function GNUExtensionSupport(AExtension: TGNUExtension): TGNUSupportLevel;
begin
  case AExtension of
    geAlternateKeywords: Result := gslParsed;
    geAttributes: Result := gslLowered;
    geStatementExpressions: Result := gslUnsupported;
    geTypeof: Result := gslLowered;
    geAlignof: Result := gslParsed;
    geZeroLengthArrays: Result := gslParsed;
    geFlexibleArrayMembers: Result := gslParsed;
    geRangeDesignators: Result := gslUnsupported;
    geCaseRanges: Result := gslUnsupported;
    geComputedGoto: Result := gslUnsupported;
    geNestedFunctions: Result := gslUnsupported;
    geInlineAssembly: Result := gslLowered;
    geLabelsAsValues: Result := gslUnsupported;
    geBuiltins: Result := gslParsed;
    geVectorTypes: Result := gslUnsupported;
    geAtomicBuiltins: Result := gslUnsupported;
    geThreadLocal: Result := gslUnsupported;
    geComplexNumbers: Result := gslUnsupported;
    ge128BitIntegers: Result := gslUnsupported;
    geTransparentUnions: Result := gslUnsupported;
    geAnonymousAggregates: Result := gslParsed;
    geDesignatedInitializers: Result := gslParsed;
    geVariadicMacros: Result := gslLowered;
    geBinaryLiterals: Result := gslParsed;
    geHexFloats: Result := gslComplete;
    geOmittedConditionalOperand: Result := gslUnsupported;
  else
    Result := gslUnsupported;
  end;
end;

function EnabledGNUExtensions(AStandard: TCStandard): TGNUExtensions;
var
  E: TGNUExtension;
begin
  Result := [];
  if not IsGNUStandard(AStandard) then Exit;
  for E := Low(TGNUExtension) to High(TGNUExtension) do
    if GNUExtensionSupport(E) <> gslUnsupported then Include(Result, E);
end;

function IsGNUAlternateKeyword(const AToken: string;
  out ACanonical: string): Boolean;
var
  T: string;
begin
  T := LowerCase(AToken);
  ACanonical := '';
  if (T = '__const') or (T = '__const__') then ACanonical := 'const'
  else if (T = '__inline') or (T = '__inline__') then ACanonical := 'inline'
  else if (T = '__restrict') or (T = '__restrict__') then ACanonical := 'restrict'
  else if (T = '__signed') or (T = '__signed__') then ACanonical := 'signed'
  else if (T = '__volatile') or (T = '__volatile__') then ACanonical := 'volatile'
  else if (T = '__typeof') or (T = '__typeof__') then ACanonical := 'typeof'
  else if T = '__alignof__' then ACanonical := '_Alignof'
  else if T = '__asm__' then ACanonical := 'asm';
  Result := ACanonical <> '';
end;

function GNUAttributeCanBeIgnored(AKind: TGNUAttributeKind): Boolean;
begin
  Result := AKind in [gakCold, gakDeprecated, gakFormat,
    gakHot, gakLeaf, gakMalloc, gakNoInline, gakNoReturn, gakNonNull,
    gakPure, gakSentinel, gakUnused, gakWarnUnusedResult, gakFallthrough,
    gakFlatten, gakNoSanitize];
end;

function GNUAttributeAffectsABI(AKind: TGNUAttributeKind): Boolean;
begin
  Result := AKind in [gakVisibility, gakWeak, gakAlias, gakMayAlias,
    gakVectorSize, gakMode, gakMSABI, gakSysVABI, gakStdCall, gakCDecl,
    gakTransparentUnion, gakCommon, gakNoCommon, gakTLSModel, gakIFunc];
end;

function GNUAttributeAffectsCodeGeneration(AKind: TGNUAttributeKind): Boolean;
begin
  Result := AKind in [gakAlwaysInline, gakConstructor, gakDestructor,
    gakNoInline, gakNoReturn, gakSection, gakUsed, gakCleanup, gakFlatten,
    gakOptimize, gakTarget, gakInterrupt, gakNaked];
end;

function GNUAttributeSummary(const AAttribute: TGNUAttribute): string;
var
  I: LongInt;
begin
  Result := GNUAttributeKindName(AAttribute.Kind);
  if Length(AAttribute.Arguments) > 0 then
  begin
    Result := Result + '(';
    for I := 0 to High(AAttribute.Arguments) do
    begin
      if I <> 0 then Result := Result + ', ';
      Result := Result + AAttribute.Arguments[I];
    end;
    Result := Result + ')';
  end;
end;

function GNUCompatibilityText: string;
var
  Lines: TStringList;
  E: TGNUExtension;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('GNU C compatibility surface');
    for E := Low(TGNUExtension) to High(TGNUExtension) do
      Lines.Add(Format('  %-30s %s', [GNUExtensionName(E),
        GNUSupportLevelName(GNUExtensionSupport(E))]));
    Lines.Add('');
    Lines.Add('Inline assembly templates in the documented x86-64 subset are');
    Lines.Add('parsed and encoded directly.  Unsupported instructions, operands,');
    Lines.Add('constraints, and modifiers are rejected with diagnostics.');
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
