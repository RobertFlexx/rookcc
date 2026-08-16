unit rcc_v1_registry;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types;

function ToolchainRegistrySummary: string;
function OptimizationCatalogText: string;
function ConformanceCatalogText: string;
function TargetFeatureCatalogText: string;
function BuiltinRegistryText: string;
function SystemCatalogText: string;
function CompilerOptionCatalogText: string;

implementation

uses
  rcc_builtin_catalog, rcc_linux_syscalls, rcc_libc_catalog,
  rcc_option_catalog, rcc_warning_catalog, rcc_optimization_catalog,
  rcc_target_feature_catalog, rcc_conformance_catalog,
  rcc_x64_patterns, rcc_aarch64_patterns, rcc_riscv_patterns;

function BuiltinRegistryText: string;
var
  Catalog: TBuiltinDescriptorArray;
begin
  Catalog := BuildBuiltinCatalog;
  Result := BuiltinCatalogText(Catalog) + LineEnding;
end;

function SystemCatalogText: string;
var
  Syscalls: TLinuxSyscallDescriptorArray;
  Symbols: TLibCSymbolDescriptorArray;
begin
  Syscalls := BuildLinuxSyscallCatalog;
  Symbols := BuildLibCSymbolCatalog;
  Result := LinuxSyscallCatalogSummary(Syscalls) + LineEnding +
    LibCSymbolCatalogSummary(Symbols) + LineEnding;
end;

function CompilerOptionCatalogText: string;
var
  Options: TOptionDescriptorArray;
  Warnings: TWarningDescriptorArray;
begin
  Options := BuildOptionCatalog;
  Warnings := BuildWarningCatalog;
  Result := OptionCatalogSummary(Options) + LineEnding +
    WarningCatalogSummary(Warnings) + LineEnding;
end;

function OptimizationCatalogText: string;
var
  Catalog: TOptimizationRecipeArray;
begin
  Catalog := BuildOptimizationRecipeCatalog;
  Result := OptimizationRecipeSummary(Catalog) + LineEnding;
end;

function ConformanceCatalogText: string;
var
  Catalog: TConformanceCaseArray;
begin
  Catalog := BuildConformanceCatalog;
  Result := ConformanceCatalogSummary(Catalog) + LineEnding;
end;

function TargetFeatureCatalogText: string;
var
  Catalog: TTargetFeatureDescriptorArray;
  X64Patterns: rcc_x64_patterns.TInstructionPatternArray;
  AArch64Patterns: rcc_aarch64_patterns.TInstructionPatternArray;
  RISCVPatterns: rcc_riscv_patterns.TInstructionPatternArray;
begin
  Catalog := BuildTargetFeatureCatalog;
  X64Patterns := BuildX64PatternCatalog;
  AArch64Patterns := BuildAArch64PatternCatalog;
  RISCVPatterns := BuildRISCV64PatternCatalog;
  Result := TargetFeatureSummary(Catalog, 'x86_64') + LineEnding +
    TargetFeatureSummary(Catalog, 'aarch64') + LineEnding +
    TargetFeatureSummary(Catalog, 'riscv64') + LineEnding +
    X64PatternSummary(X64Patterns) + LineEnding +
    AArch64PatternSummary(AArch64Patterns) + LineEnding +
    RISCV64PatternSummary(RISCVPatterns) + LineEnding;
end;

function ToolchainRegistrySummary: string;
begin
  Result := 'RookCC 1.0 toolchain registries' + LineEnding +
    '-------------------------------' + LineEnding +
    BuiltinRegistryText + SystemCatalogText + CompilerOptionCatalogText +
    OptimizationCatalogText + TargetFeatureCatalogText +
    ConformanceCatalogText;
end;

end.
