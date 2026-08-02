unit rcc_target_feature_catalog;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TTargetFeatureDescriptor = record
    Architecture: string;
    CPU: string;
    Feature: string;
    VectorWidth: LongInt;
    Latency: LongInt;
    ReciprocalThroughput: LongInt;
    RequiredByBaseline: Boolean;
  end;
  TTargetFeatureDescriptorArray = array of TTargetFeatureDescriptor;

function BuildTargetFeatureCatalog: TTargetFeatureDescriptorArray;
function TargetFeatureSummary(const ACatalog: TTargetFeatureDescriptorArray;
  const AArchitecture: string): string;
function TargetSupportsFeature(const ACatalog: TTargetFeatureDescriptorArray;
  const AArchitecture, ACPU, AFeature: string): Boolean;

implementation

procedure AddFeature(var AValues: TTargetFeatureDescriptorArray;
  const AArchitecture, ACPU, AFeature: string; AVectorWidth, ALatency,
  AReciprocalThroughput: LongInt; ARequired: Boolean);
var N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N].Architecture := AArchitecture;
  AValues[N].CPU := ACPU;
  AValues[N].Feature := AFeature;
  AValues[N].VectorWidth := AVectorWidth;
  AValues[N].Latency := ALatency;
  AValues[N].ReciprocalThroughput := AReciprocalThroughput;
  AValues[N].RequiredByBaseline := ARequired;
end;

function BuildTargetFeatureCatalog: TTargetFeatureDescriptorArray;
begin
  Result := nil;
  AddFeature(Result, 'x86_64', 'generic',
    'baseline', 8, 8, 3, true);
  AddFeature(Result, 'x86_64', 'generic',
    'sse2', 64, 11, 4, true);
  AddFeature(Result, 'x86_64', 'generic',
    'sse3', 32, 3, 5, false);
  AddFeature(Result, 'x86_64', 'generic',
    'ssse3', 64, 6, 1, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sse4.1', 128, 9, 2, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sse4.2', 256, 1, 3, false);
  AddFeature(Result, 'x86_64', 'generic',
    'avx', 512, 4, 4, false);
  AddFeature(Result, 'x86_64', 'generic',
    'avx2', 8, 7, 5, false);
  AddFeature(Result, 'x86_64', 'generic',
    'fma', 16, 10, 1, false);
  AddFeature(Result, 'x86_64', 'generic',
    'bmi1', 32, 2, 2, false);
  AddFeature(Result, 'x86_64', 'generic',
    'bmi2', 64, 5, 3, false);
  AddFeature(Result, 'x86_64', 'generic',
    'popcnt', 128, 8, 4, false);
  AddFeature(Result, 'x86_64', 'generic',
    'lzcnt', 256, 11, 5, false);
  AddFeature(Result, 'x86_64', 'generic',
    'aes', 512, 3, 1, false);
  AddFeature(Result, 'x86_64', 'generic',
    'pclmul', 8, 6, 2, false);
  AddFeature(Result, 'x86_64', 'generic',
    'avx512f', 16, 9, 3, false);
  AddFeature(Result, 'x86_64', 'generic',
    'avx512bw', 32, 1, 4, false);
  AddFeature(Result, 'x86_64', 'generic',
    'avx512dq', 64, 4, 5, false);
  AddFeature(Result, 'x86_64', 'generic',
    'avx512vl', 128, 7, 1, false);
  AddFeature(Result, 'x86_64', 'core2',
    'baseline', 256, 6, 1, true);
  AddFeature(Result, 'x86_64', 'core2',
    'sse2', 64, 9, 2, true);
  AddFeature(Result, 'x86_64', 'core2',
    'sse3', 8, 1, 3, false);
  AddFeature(Result, 'x86_64', 'core2',
    'ssse3', 16, 4, 4, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sse4.1', 32, 7, 5, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sse4.2', 64, 10, 1, false);
  AddFeature(Result, 'x86_64', 'core2',
    'avx', 128, 2, 2, false);
  AddFeature(Result, 'x86_64', 'core2',
    'avx2', 256, 5, 3, false);
  AddFeature(Result, 'x86_64', 'core2',
    'fma', 512, 8, 4, false);
  AddFeature(Result, 'x86_64', 'core2',
    'bmi1', 8, 11, 5, false);
  AddFeature(Result, 'x86_64', 'core2',
    'bmi2', 16, 3, 1, false);
  AddFeature(Result, 'x86_64', 'core2',
    'popcnt', 32, 6, 2, false);
  AddFeature(Result, 'x86_64', 'core2',
    'lzcnt', 64, 9, 3, false);
  AddFeature(Result, 'x86_64', 'core2',
    'aes', 128, 1, 4, false);
  AddFeature(Result, 'x86_64', 'core2',
    'pclmul', 256, 4, 5, false);
  AddFeature(Result, 'x86_64', 'core2',
    'avx512f', 512, 7, 1, false);
  AddFeature(Result, 'x86_64', 'core2',
    'avx512bw', 8, 10, 2, false);
  AddFeature(Result, 'x86_64', 'core2',
    'avx512dq', 16, 2, 3, false);
  AddFeature(Result, 'x86_64', 'core2',
    'avx512vl', 32, 5, 4, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'baseline', 8, 8, 3, true);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sse2', 64, 11, 4, true);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sse3', 32, 3, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'ssse3', 64, 6, 1, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sse4.1', 128, 9, 2, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sse4.2', 256, 1, 3, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'avx', 512, 4, 4, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'avx2', 8, 7, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'fma', 16, 10, 1, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'bmi1', 32, 2, 2, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'bmi2', 64, 5, 3, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'popcnt', 128, 8, 4, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'lzcnt', 256, 11, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'aes', 512, 3, 1, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'pclmul', 8, 6, 2, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'avx512f', 16, 9, 3, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'avx512bw', 32, 1, 4, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'avx512dq', 64, 4, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'avx512vl', 128, 7, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'baseline', 128, 1, 2, true);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sse2', 64, 4, 3, true);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sse3', 512, 7, 4, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'ssse3', 8, 10, 5, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sse4.1', 16, 2, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sse4.2', 32, 5, 2, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'avx', 64, 8, 3, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'avx2', 128, 11, 4, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'fma', 256, 3, 5, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'bmi1', 512, 6, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'bmi2', 8, 9, 2, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'popcnt', 16, 1, 3, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'lzcnt', 32, 4, 4, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'aes', 64, 7, 5, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'pclmul', 128, 10, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'avx512f', 256, 2, 2, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'avx512bw', 512, 5, 3, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'avx512dq', 8, 8, 4, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'avx512vl', 16, 11, 5, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'baseline', 8, 8, 3, true);
  AddFeature(Result, 'x86_64', 'haswell',
    'sse2', 64, 11, 4, true);
  AddFeature(Result, 'x86_64', 'haswell',
    'sse3', 32, 3, 5, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'ssse3', 64, 6, 1, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sse4.1', 128, 9, 2, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sse4.2', 256, 1, 3, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'avx', 512, 4, 4, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'avx2', 8, 7, 5, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'fma', 16, 10, 1, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'bmi1', 32, 2, 2, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'bmi2', 64, 5, 3, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'popcnt', 128, 8, 4, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'lzcnt', 256, 11, 5, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'aes', 512, 3, 1, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'pclmul', 8, 6, 2, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'avx512f', 16, 9, 3, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'avx512bw', 32, 1, 4, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'avx512dq', 64, 4, 5, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'avx512vl', 128, 7, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'baseline', 8, 8, 3, true);
  AddFeature(Result, 'x86_64', 'skylake',
    'sse2', 64, 11, 4, true);
  AddFeature(Result, 'x86_64', 'skylake',
    'sse3', 32, 3, 5, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'ssse3', 64, 6, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sse4.1', 128, 9, 2, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sse4.2', 256, 1, 3, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'avx', 512, 4, 4, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'avx2', 8, 7, 5, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'fma', 16, 10, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'bmi1', 32, 2, 2, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'bmi2', 64, 5, 3, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'popcnt', 128, 8, 4, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'lzcnt', 256, 11, 5, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'aes', 512, 3, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'pclmul', 8, 6, 2, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'avx512f', 16, 9, 3, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'avx512bw', 32, 1, 4, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'avx512dq', 64, 4, 5, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'avx512vl', 128, 7, 1, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'baseline', 512, 7, 2, true);
  AddFeature(Result, 'x86_64', 'znver1',
    'sse2', 64, 10, 3, true);
  AddFeature(Result, 'x86_64', 'znver1',
    'sse3', 16, 2, 4, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'ssse3', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sse4.1', 64, 8, 1, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sse4.2', 128, 11, 2, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'avx', 256, 3, 3, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'avx2', 512, 6, 4, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'fma', 8, 9, 5, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'bmi1', 16, 1, 1, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'bmi2', 32, 4, 2, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'popcnt', 64, 7, 3, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'lzcnt', 128, 10, 4, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'aes', 256, 2, 5, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'pclmul', 512, 5, 1, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'avx512f', 8, 8, 2, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'avx512bw', 16, 11, 3, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'avx512dq', 32, 3, 4, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'avx512vl', 64, 6, 5, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'baseline', 512, 7, 2, true);
  AddFeature(Result, 'x86_64', 'znver2',
    'sse2', 64, 10, 3, true);
  AddFeature(Result, 'x86_64', 'znver2',
    'sse3', 16, 2, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'ssse3', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sse4.1', 64, 8, 1, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sse4.2', 128, 11, 2, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'avx', 256, 3, 3, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'avx2', 512, 6, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'fma', 8, 9, 5, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'bmi1', 16, 1, 1, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'bmi2', 32, 4, 2, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'popcnt', 64, 7, 3, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'lzcnt', 128, 10, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'aes', 256, 2, 5, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'pclmul', 512, 5, 1, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'avx512f', 8, 8, 2, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'avx512bw', 16, 11, 3, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'avx512dq', 32, 3, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'avx512vl', 64, 6, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'baseline', 512, 7, 2, true);
  AddFeature(Result, 'x86_64', 'znver3',
    'sse2', 64, 10, 3, true);
  AddFeature(Result, 'x86_64', 'znver3',
    'sse3', 16, 2, 4, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'ssse3', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sse4.1', 64, 8, 1, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sse4.2', 128, 11, 2, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'avx', 256, 3, 3, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'avx2', 512, 6, 4, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'fma', 8, 9, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'bmi1', 16, 1, 1, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'bmi2', 32, 4, 2, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'popcnt', 64, 7, 3, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'lzcnt', 128, 10, 4, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'aes', 256, 2, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'pclmul', 512, 5, 1, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'avx512f', 8, 8, 2, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'avx512bw', 16, 11, 3, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'avx512dq', 32, 3, 4, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'avx512vl', 64, 6, 5, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'baseline', 512, 7, 2, true);
  AddFeature(Result, 'x86_64', 'znver4',
    'sse2', 64, 10, 3, true);
  AddFeature(Result, 'x86_64', 'znver4',
    'sse3', 16, 2, 4, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'ssse3', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sse4.1', 64, 8, 1, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sse4.2', 128, 11, 2, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'avx', 256, 3, 3, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'avx2', 512, 6, 4, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'fma', 8, 9, 5, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'bmi1', 16, 1, 1, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'bmi2', 32, 4, 2, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'popcnt', 64, 7, 3, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'lzcnt', 128, 10, 4, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'aes', 256, 2, 5, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'pclmul', 512, 5, 1, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'avx512f', 8, 8, 2, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'avx512bw', 16, 11, 3, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'avx512dq', 32, 3, 4, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'avx512vl', 64, 6, 5, false);
  AddFeature(Result, 'aarch64', 'generic',
    'base', 64, 8, 3, true);
  AddFeature(Result, 'aarch64', 'generic',
    'fp', 16, 11, 4, true);
  AddFeature(Result, 'aarch64', 'generic',
    'asimd', 32, 3, 5, false);
  AddFeature(Result, 'aarch64', 'generic',
    'crc', 64, 6, 1, false);
  AddFeature(Result, 'aarch64', 'generic',
    'crypto', 128, 9, 2, false);
  AddFeature(Result, 'aarch64', 'generic',
    'lse', 256, 1, 3, false);
  AddFeature(Result, 'aarch64', 'generic',
    'rdm', 512, 4, 4, false);
  AddFeature(Result, 'aarch64', 'generic',
    'fp16', 8, 7, 5, false);
  AddFeature(Result, 'aarch64', 'generic',
    'dotprod', 16, 10, 1, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sve', 32, 2, 2, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sve2', 64, 5, 3, false);
  AddFeature(Result, 'aarch64', 'generic',
    'pauth', 128, 8, 4, false);
  AddFeature(Result, 'aarch64', 'generic',
    'bti', 256, 11, 5, false);
  AddFeature(Result, 'aarch64', 'generic',
    'mte', 512, 3, 1, false);
  AddFeature(Result, 'aarch64', 'generic',
    'rcpc', 8, 6, 2, false);
  AddFeature(Result, 'aarch64', 'generic',
    'i8mm', 16, 9, 3, false);
  AddFeature(Result, 'aarch64', 'generic',
    'bf16', 32, 1, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'base', 64, 11, 1, true);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'fp', 128, 3, 2, true);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'asimd', 256, 6, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'crc', 512, 9, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'crypto', 8, 1, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'lse', 16, 4, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'rdm', 32, 7, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'fp16', 64, 10, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'dotprod', 128, 2, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sve', 256, 5, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sve2', 512, 8, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'pauth', 8, 11, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'bti', 16, 3, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'mte', 32, 6, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'rcpc', 64, 9, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'i8mm', 128, 1, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'bf16', 256, 4, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'base', 64, 11, 1, true);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'fp', 128, 3, 2, true);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'asimd', 256, 6, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'crc', 512, 9, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'crypto', 8, 1, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'lse', 16, 4, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'rdm', 32, 7, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'fp16', 64, 10, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'dotprod', 128, 2, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sve', 256, 5, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sve2', 512, 8, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'pauth', 8, 11, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'bti', 16, 3, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'mte', 32, 6, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'rcpc', 64, 9, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'i8mm', 128, 1, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'bf16', 256, 4, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'base', 64, 11, 1, true);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'fp', 128, 3, 2, true);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'asimd', 256, 6, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'crc', 512, 9, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'crypto', 8, 1, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'lse', 16, 4, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'rdm', 32, 7, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'fp16', 64, 10, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'dotprod', 128, 2, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sve', 256, 5, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sve2', 512, 8, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'pauth', 8, 11, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'bti', 16, 3, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'mte', 32, 6, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'rcpc', 64, 9, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'i8mm', 128, 1, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'bf16', 256, 4, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'base', 64, 11, 1, true);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'fp', 128, 3, 2, true);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'asimd', 256, 6, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'crc', 512, 9, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'crypto', 8, 1, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'lse', 16, 4, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'rdm', 32, 7, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'fp16', 64, 10, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'dotprod', 128, 2, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sve', 256, 5, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sve2', 512, 8, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'pauth', 8, 11, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'bti', 16, 3, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'mte', 32, 6, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'rcpc', 64, 9, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'i8mm', 128, 1, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'bf16', 256, 4, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'base', 64, 1, 2, true);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'fp', 256, 4, 3, true);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'asimd', 512, 7, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'crc', 8, 10, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'crypto', 16, 2, 1, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'lse', 32, 5, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'rdm', 64, 8, 3, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'fp16', 128, 11, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'dotprod', 256, 3, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sve', 512, 6, 1, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sve2', 8, 9, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'pauth', 16, 1, 3, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'bti', 32, 4, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'mte', 64, 7, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'rcpc', 128, 10, 1, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'i8mm', 256, 2, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'bf16', 512, 5, 3, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'base', 64, 1, 2, true);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'fp', 256, 4, 3, true);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'asimd', 512, 7, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'crc', 8, 10, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'crypto', 16, 2, 1, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'lse', 32, 5, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'rdm', 64, 8, 3, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'fp16', 128, 11, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'dotprod', 256, 3, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sve', 512, 6, 1, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sve2', 8, 9, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'pauth', 16, 1, 3, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'bti', 32, 4, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'mte', 64, 7, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'rcpc', 128, 10, 1, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'i8mm', 256, 2, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'bf16', 512, 5, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'base', 64, 9, 4, true);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'fp', 32, 1, 5, true);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'asimd', 64, 4, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'crc', 128, 7, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'crypto', 256, 10, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'lse', 512, 2, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'rdm', 8, 5, 5, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'fp16', 16, 8, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'dotprod', 32, 11, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sve', 64, 3, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sve2', 128, 6, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'pauth', 256, 9, 5, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'bti', 512, 1, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'mte', 8, 4, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'rcpc', 16, 7, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'i8mm', 32, 10, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'bf16', 64, 2, 5, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'base', 64, 9, 4, true);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'fp', 32, 1, 5, true);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'asimd', 64, 4, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'crc', 128, 7, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'crypto', 256, 10, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'lse', 512, 2, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'rdm', 8, 5, 5, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'fp16', 16, 8, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'dotprod', 32, 11, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sve', 64, 3, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sve2', 128, 6, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'pauth', 256, 9, 5, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'bti', 512, 1, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'mte', 8, 4, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'rcpc', 16, 7, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'i8mm', 32, 10, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'bf16', 64, 2, 5, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'i', 64, 4, 5, true);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'm', 16, 7, 1, true);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'a', 32, 10, 2, true);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'f', 64, 2, 3, true);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'd', 128, 5, 4, true);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'c', 256, 8, 5, true);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'zicsr', 512, 11, 1, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'zifencei', 8, 3, 2, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'zba', 16, 6, 3, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'zbb', 32, 9, 4, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'zbc', 64, 1, 5, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'zbs', 128, 4, 1, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'v', 256, 7, 2, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'zfh', 512, 10, 3, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'zicond', 8, 2, 4, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'ztso', 16, 5, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'i', 64, 11, 1, true);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'm', 128, 3, 2, true);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'a', 256, 6, 3, true);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'f', 512, 9, 4, true);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'd', 8, 1, 5, true);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'c', 16, 4, 1, true);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'zicsr', 32, 7, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'zifencei', 64, 10, 3, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'zba', 128, 2, 4, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'zbb', 256, 5, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'zbc', 512, 8, 1, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'zbs', 8, 11, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'v', 16, 3, 3, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'zfh', 32, 6, 4, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'zicond', 64, 9, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'ztso', 128, 1, 1, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'i', 64, 1, 2, true);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'm', 256, 4, 3, true);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'a', 512, 7, 4, true);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'f', 8, 10, 5, true);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'd', 16, 2, 1, true);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'c', 32, 5, 2, true);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'zicsr', 64, 8, 3, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'zifencei', 128, 11, 4, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'zba', 256, 3, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'zbb', 512, 6, 1, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'zbc', 8, 9, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'zbs', 16, 1, 3, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'v', 32, 4, 4, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'zfh', 64, 7, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'zicond', 128, 10, 1, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'ztso', 256, 2, 2, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'i', 64, 11, 1, true);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'm', 128, 3, 2, true);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'a', 256, 6, 3, true);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'f', 512, 9, 4, true);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'd', 8, 1, 5, true);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'c', 16, 4, 1, true);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'zicsr', 32, 7, 2, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'zifencei', 64, 10, 3, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'zba', 128, 2, 4, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'zbb', 256, 5, 5, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'zbc', 512, 8, 1, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'zbs', 8, 11, 2, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'v', 16, 3, 3, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'zfh', 32, 6, 4, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'zicond', 64, 9, 5, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'ztso', 128, 1, 1, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'i', 64, 2, 3, true);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'm', 512, 5, 4, true);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'a', 8, 8, 5, true);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'f', 16, 11, 1, true);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'd', 32, 3, 2, true);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'c', 64, 6, 3, true);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'zicsr', 128, 9, 4, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'zifencei', 256, 1, 5, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'zba', 512, 4, 1, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'zbb', 8, 7, 2, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'zbc', 16, 10, 3, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'zbs', 32, 2, 4, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'v', 64, 5, 5, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'zfh', 128, 8, 1, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'zicond', 256, 11, 2, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'ztso', 512, 3, 3, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:integer-alu', 64, 2, 2, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:integer-mul', 64, 14, 2, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:integer-div', 128, 3, 3, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:branch', 128, 7, 5, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:load', 32, 1, 3, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:store', 64, 2, 6, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:address-gen', 64, 6, 4, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:scalar-fp', 64, 14, 2, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:vector-fp', 128, 3, 1, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:vector-int', 256, 20, 4, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:shuffle', 64, 14, 6, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:crypto', 64, 18, 2, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:atomic', 64, 2, 2, false);
  AddFeature(Result, 'x86_64', 'generic',
    'sched:system', 64, 2, 6, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:integer-alu', 256, 4, 2, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:integer-mul', 256, 16, 2, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:integer-div', 32, 5, 3, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:branch', 32, 9, 5, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:load', 128, 3, 3, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:store', 256, 4, 6, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:address-gen', 256, 8, 4, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:scalar-fp', 256, 16, 2, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:vector-fp', 32, 5, 1, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:vector-int', 64, 2, 4, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:shuffle', 256, 16, 6, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:crypto', 256, 20, 2, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:atomic', 256, 4, 2, false);
  AddFeature(Result, 'x86_64', 'core2',
    'sched:system', 256, 4, 6, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:integer-alu', 128, 19, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:integer-mul', 128, 11, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:integer-div', 256, 20, 6, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:branch', 256, 4, 2, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:load', 64, 18, 6, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:store', 128, 19, 3, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:address-gen', 128, 3, 1, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:scalar-fp', 128, 11, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:vector-fp', 256, 20, 4, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:vector-int', 32, 17, 1, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:shuffle', 128, 11, 3, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:crypto', 128, 15, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:atomic', 128, 19, 5, false);
  AddFeature(Result, 'x86_64', 'nehalem',
    'sched:system', 128, 19, 3, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:integer-alu', 32, 13, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:integer-mul', 32, 5, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:integer-div', 64, 14, 2, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:branch', 64, 18, 4, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:load', 256, 12, 2, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:store', 32, 13, 5, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:address-gen', 32, 17, 3, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:scalar-fp', 32, 5, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:vector-fp', 64, 14, 6, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:vector-int', 128, 11, 3, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:shuffle', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:crypto', 32, 9, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:atomic', 32, 13, 1, false);
  AddFeature(Result, 'x86_64', 'sandybridge',
    'sched:system', 32, 13, 5, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:integer-alu', 32, 1, 3, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:integer-mul', 32, 13, 3, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:integer-div', 64, 2, 4, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:branch', 64, 6, 6, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:load', 256, 20, 4, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:store', 32, 1, 1, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:address-gen', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:scalar-fp', 32, 13, 3, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:vector-fp', 64, 2, 2, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:vector-int', 128, 19, 5, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:shuffle', 32, 13, 1, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:crypto', 32, 17, 3, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:atomic', 32, 1, 3, false);
  AddFeature(Result, 'x86_64', 'haswell',
    'sched:system', 32, 1, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:integer-alu', 32, 5, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:integer-mul', 32, 17, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:integer-div', 64, 6, 2, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:branch', 64, 10, 4, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:load', 256, 4, 2, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:store', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:address-gen', 32, 9, 3, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:scalar-fp', 32, 17, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:vector-fp', 64, 6, 6, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:vector-int', 128, 3, 3, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:shuffle', 32, 17, 5, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:crypto', 32, 1, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:atomic', 32, 5, 1, false);
  AddFeature(Result, 'x86_64', 'skylake',
    'sched:system', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:integer-alu', 128, 3, 3, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:integer-mul', 128, 15, 3, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:integer-div', 256, 4, 4, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:branch', 256, 8, 6, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:load', 64, 2, 4, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:store', 128, 3, 1, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:address-gen', 128, 7, 5, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:scalar-fp', 128, 15, 3, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:vector-fp', 256, 4, 2, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:vector-int', 32, 1, 5, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:shuffle', 128, 15, 1, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:crypto', 128, 19, 3, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:atomic', 128, 3, 3, false);
  AddFeature(Result, 'x86_64', 'znver1',
    'sched:system', 128, 3, 1, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:integer-alu', 256, 4, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:integer-mul', 256, 16, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:integer-div', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:branch', 32, 9, 1, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:load', 128, 3, 5, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:store', 256, 4, 2, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:address-gen', 256, 8, 6, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:scalar-fp', 256, 16, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:vector-fp', 32, 5, 3, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:vector-int', 64, 2, 6, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:shuffle', 256, 16, 2, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:crypto', 256, 20, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:atomic', 256, 4, 4, false);
  AddFeature(Result, 'x86_64', 'znver2',
    'sched:system', 256, 4, 2, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:integer-alu', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:integer-mul', 32, 17, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:integer-div', 64, 6, 6, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:branch', 64, 10, 2, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:load', 256, 4, 6, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:store', 32, 5, 3, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:address-gen', 32, 9, 1, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:scalar-fp', 32, 17, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:vector-fp', 64, 6, 4, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:vector-int', 128, 3, 1, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:shuffle', 32, 17, 3, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:crypto', 32, 1, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:atomic', 32, 5, 5, false);
  AddFeature(Result, 'x86_64', 'znver3',
    'sched:system', 32, 5, 3, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:integer-alu', 64, 6, 6, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:integer-mul', 64, 18, 6, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:integer-div', 128, 7, 1, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:branch', 128, 11, 3, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:load', 32, 5, 1, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:store', 64, 6, 4, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:address-gen', 64, 10, 2, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:scalar-fp', 64, 18, 6, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:vector-fp', 128, 7, 5, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:vector-int', 256, 4, 2, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:shuffle', 64, 18, 4, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:crypto', 64, 2, 6, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:atomic', 64, 6, 6, false);
  AddFeature(Result, 'x86_64', 'znver4',
    'sched:system', 64, 6, 4, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:integer-alu', 256, 8, 2, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:integer-mul', 256, 20, 2, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:integer-div', 32, 9, 3, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:branch', 32, 13, 5, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:load', 128, 7, 3, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:store', 256, 8, 6, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:address-gen', 256, 12, 4, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:scalar-fp', 256, 20, 2, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:vector-fp', 32, 9, 1, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:vector-int', 64, 6, 4, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:shuffle', 256, 20, 6, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:crypto', 256, 4, 2, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:atomic', 256, 8, 2, false);
  AddFeature(Result, 'aarch64', 'generic',
    'sched:system', 256, 8, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:integer-alu', 64, 2, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:integer-mul', 64, 14, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:integer-div', 128, 3, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:branch', 128, 7, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:load', 32, 1, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:store', 64, 2, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:address-gen', 64, 6, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:scalar-fp', 64, 14, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:vector-fp', 128, 3, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:vector-int', 256, 20, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:shuffle', 64, 14, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:crypto', 64, 18, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:atomic', 64, 2, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a53',
    'sched:system', 64, 2, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:integer-alu', 64, 6, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:integer-mul', 64, 18, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:integer-div', 128, 7, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:branch', 128, 11, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:load', 32, 5, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:store', 64, 6, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:address-gen', 64, 10, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:scalar-fp', 64, 18, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:vector-fp', 128, 7, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:vector-int', 256, 4, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:shuffle', 64, 18, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:crypto', 64, 2, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:atomic', 64, 6, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a57',
    'sched:system', 64, 6, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:integer-alu', 128, 3, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:integer-mul', 128, 15, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:integer-div', 256, 4, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:branch', 256, 8, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:load', 64, 2, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:store', 128, 3, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:address-gen', 128, 7, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:scalar-fp', 128, 15, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:vector-fp', 256, 4, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:vector-int', 32, 1, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:shuffle', 128, 15, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:crypto', 128, 19, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:atomic', 128, 3, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a72',
    'sched:system', 128, 3, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:integer-alu', 128, 7, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:integer-mul', 128, 19, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:integer-div', 256, 8, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:branch', 256, 12, 4, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:load', 64, 6, 2, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:store', 128, 7, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:address-gen', 128, 11, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:scalar-fp', 128, 19, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:vector-fp', 256, 8, 6, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:vector-int', 32, 5, 3, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:shuffle', 128, 19, 5, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:crypto', 128, 3, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:atomic', 128, 7, 1, false);
  AddFeature(Result, 'aarch64', 'cortex-a76',
    'sched:system', 128, 7, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:integer-alu', 64, 10, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:integer-mul', 64, 2, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:integer-div', 128, 11, 3, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:branch', 128, 15, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:load', 32, 9, 3, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:store', 64, 10, 6, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:address-gen', 64, 14, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:scalar-fp', 64, 2, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:vector-fp', 128, 11, 1, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:vector-int', 256, 8, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:shuffle', 64, 2, 6, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:crypto', 64, 6, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:atomic', 64, 10, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-n1',
    'sched:system', 64, 10, 6, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:integer-alu', 64, 18, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:integer-mul', 64, 10, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:integer-div', 128, 19, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:branch', 128, 3, 1, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:load', 32, 17, 5, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:store', 64, 18, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:address-gen', 64, 2, 6, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:scalar-fp', 64, 10, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:vector-fp', 128, 19, 3, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:vector-int', 256, 16, 6, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:shuffle', 64, 10, 2, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:crypto', 64, 14, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:atomic', 64, 18, 4, false);
  AddFeature(Result, 'aarch64', 'neoverse-v1',
    'sched:system', 64, 18, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:integer-alu', 256, 8, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:integer-mul', 256, 20, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:integer-div', 32, 9, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:branch', 32, 13, 5, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:load', 128, 7, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:store', 256, 8, 6, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:address-gen', 256, 12, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:scalar-fp', 256, 20, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:vector-fp', 32, 9, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:vector-int', 64, 6, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:shuffle', 256, 20, 6, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:crypto', 256, 4, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:atomic', 256, 8, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m1',
    'sched:system', 256, 8, 6, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:integer-alu', 32, 9, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:integer-mul', 32, 1, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:integer-div', 64, 10, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:branch', 64, 14, 6, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:load', 256, 8, 4, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:store', 32, 9, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:address-gen', 32, 13, 5, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:scalar-fp', 32, 1, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:vector-fp', 64, 10, 2, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:vector-int', 128, 7, 5, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:shuffle', 32, 1, 1, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:crypto', 32, 5, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:atomic', 32, 9, 3, false);
  AddFeature(Result, 'aarch64', 'apple-m2',
    'sched:system', 32, 9, 1, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:integer-alu', 32, 13, 3, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:integer-mul', 32, 5, 3, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:integer-div', 64, 14, 4, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:branch', 64, 18, 6, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:load', 256, 12, 4, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:store', 32, 13, 1, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:address-gen', 32, 17, 5, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:scalar-fp', 32, 5, 3, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:vector-fp', 64, 14, 2, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:vector-int', 128, 11, 5, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:shuffle', 32, 5, 1, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:crypto', 32, 9, 3, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:atomic', 32, 13, 3, false);
  AddFeature(Result, 'riscv64', 'generic-rv64gc',
    'sched:system', 32, 13, 1, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:integer-alu', 64, 10, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:integer-mul', 64, 2, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:integer-div', 128, 11, 3, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:branch', 128, 15, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:load', 32, 9, 3, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:store', 64, 10, 6, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:address-gen', 64, 14, 4, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:scalar-fp', 64, 2, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:vector-fp', 128, 11, 1, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:vector-int', 256, 8, 4, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:shuffle', 64, 2, 6, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:crypto', 64, 6, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:atomic', 64, 10, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-u74',
    'sched:system', 64, 10, 6, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:integer-alu', 128, 15, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:integer-mul', 128, 7, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:integer-div', 256, 16, 6, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:branch', 256, 20, 2, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:load', 64, 14, 6, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:store', 128, 15, 3, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:address-gen', 128, 19, 1, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:scalar-fp', 128, 7, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:vector-fp', 256, 16, 4, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:vector-int', 32, 13, 1, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:shuffle', 128, 7, 3, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:crypto', 128, 11, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:atomic', 128, 15, 5, false);
  AddFeature(Result, 'riscv64', 'sifive-p670',
    'sched:system', 128, 15, 3, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:integer-alu', 128, 11, 5, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:integer-mul', 128, 3, 5, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:integer-div', 256, 12, 6, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:branch', 256, 16, 2, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:load', 64, 10, 6, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:store', 128, 11, 3, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:address-gen', 128, 15, 1, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:scalar-fp', 128, 3, 5, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:vector-fp', 256, 12, 4, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:vector-int', 32, 9, 1, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:shuffle', 128, 3, 3, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:crypto', 128, 7, 5, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:atomic', 128, 11, 5, false);
  AddFeature(Result, 'riscv64', 'thead-c910',
    'sched:system', 128, 11, 3, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:integer-alu', 256, 16, 4, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:integer-mul', 256, 8, 4, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:integer-div', 32, 17, 5, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:branch', 32, 1, 1, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:load', 128, 15, 5, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:store', 256, 16, 2, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:address-gen', 256, 20, 6, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:scalar-fp', 256, 8, 4, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:vector-fp', 32, 17, 3, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:vector-int', 64, 14, 6, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:shuffle', 256, 8, 2, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:crypto', 256, 12, 4, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:atomic', 256, 16, 4, false);
  AddFeature(Result, 'riscv64', 'spacemit-x60',
    'sched:system', 256, 16, 2, false);
end;

function TargetFeatureSummary(const ACatalog: TTargetFeatureDescriptorArray;
  const AArchitecture: string): string;
var I, Count, Baseline: LongInt;
begin
  Count := 0;
  Baseline := 0;
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Architecture, AArchitecture) then
    begin
      Inc(Count);
      if ACatalog[I].RequiredByBaseline then Inc(Baseline);
    end;
  Result := Format('%s: %d feature/scheduling records (%d baseline)',
    [AArchitecture, Count, Baseline]);
end;

function TargetSupportsFeature(const ACatalog: TTargetFeatureDescriptorArray;
  const AArchitecture, ACPU, AFeature: string): Boolean;
var I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Architecture, AArchitecture) and
       SameText(ACatalog[I].CPU, ACPU) and
       SameText(ACatalog[I].Feature, AFeature) then Exit(True);
  Result := False;
end;

end.
