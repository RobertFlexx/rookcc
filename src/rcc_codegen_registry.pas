unit rcc_codegen_registry;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, rcc_types, rcc_arch, rcc_ir;

type
  TBackendMaturity = (
    bmUnavailable,
    bmBootstrap,
    bmExperimental,
    bmSupported
  );

  TBackendOutput = (
    boExecutable,
    boObject,
    boAssemblyListing
  );
  TBackendOutputs = set of TBackendOutput;

  TBackendFeature = (
    bfIntegerScalar,
    bfPointer,
    bfAggregate,
    bfFloatingPoint,
    bfVariadic,
    bfFunctionPointer,
    bfAtomic,
    bfTLS,
    bfPIC,
    bfDynamicLink,
    bfInlineAssembly,
    bfDebugInfo,
    bfUnwindInfo
  );
  TBackendFeatures = set of TBackendFeature;

  TBackendDescriptor = record
    Name: string;
    Architecture: TArchitecture;
    Maturity: TBackendMaturity;
    Outputs: TBackendOutputs;
    Features: TBackendFeatures;
    Description: string;
  end;
  TBackendDescriptorArray = array of TBackendDescriptor;

function BackendMaturityName(AMaturity: TBackendMaturity): string;
function BackendOutputName(AOutput: TBackendOutput): string;
function BackendFeatureName(AFeature: TBackendFeature): string;
function RegisteredBackends: TBackendDescriptorArray;
function FindBackend(AArchitecture: TArchitecture;
  out ABackend: TBackendDescriptor): Boolean;
function BackendSupportsOutput(const ABackend: TBackendDescriptor;
  AOutput: TBackendOutput): Boolean;
function BackendSupportsFeature(const ABackend: TBackendDescriptor;
  AFeature: TBackendFeature): Boolean;
function ValidateBackendRequest(const ABackend: TBackendDescriptor;
  AOutput: TBackendOutput; AModule: TIRModule; out AReason: string): Boolean;
function BackendRegistryText: string;
function BackendDetailedText(const ABackend: TBackendDescriptor): string;
function EmitModeBackendOutput(AEmitMode: TEmitMode): TBackendOutput;

implementation

procedure AddBackend(var ABackends: TBackendDescriptorArray;
  const AName: string; AArchitecture: TArchitecture;
  AMaturity: TBackendMaturity; AOutputs: TBackendOutputs;
  AFeatures: TBackendFeatures; const ADescription: string);
var
  N: LongInt;
begin
  N := Length(ABackends);
  SetLength(ABackends, N + 1);
  ABackends[N].Name := AName;
  ABackends[N].Architecture := AArchitecture;
  ABackends[N].Maturity := AMaturity;
  ABackends[N].Outputs := AOutputs;
  ABackends[N].Features := AFeatures;
  ABackends[N].Description := ADescription;
end;

function BackendMaturityName(AMaturity: TBackendMaturity): string;
begin
  case AMaturity of
    bmUnavailable: Result := 'unavailable';
    bmBootstrap: Result := 'bootstrap';
    bmExperimental: Result := 'experimental';
    bmSupported: Result := 'supported';
  else
    Result := 'unknown';
  end;
end;

function BackendOutputName(AOutput: TBackendOutput): string;
begin
  case AOutput of
    boExecutable: Result := 'executable';
    boObject: Result := 'object';
    boAssemblyListing: Result := 'machine-listing';
  else
    Result := 'unknown';
  end;
end;

function BackendFeatureName(AFeature: TBackendFeature): string;
begin
  case AFeature of
    bfIntegerScalar: Result := 'integer-scalar';
    bfPointer: Result := 'pointer';
    bfAggregate: Result := 'aggregate';
    bfFloatingPoint: Result := 'floating-point';
    bfVariadic: Result := 'variadic';
    bfFunctionPointer: Result := 'function-pointer';
    bfAtomic: Result := 'atomic';
    bfTLS: Result := 'tls';
    bfPIC: Result := 'pic';
    bfDynamicLink: Result := 'dynamic-link';
    bfInlineAssembly: Result := 'inline-assembly';
    bfDebugInfo: Result := 'debug-info';
    bfUnwindInfo: Result := 'unwind-info';
  else
    Result := 'unknown';
  end;
end;

function RegisteredBackends: TBackendDescriptorArray;
begin
  Result := nil;
  SetLength(Result, 0);
  AddBackend(Result, 'x86_64-direct', archX86_64, bmSupported,
    [boExecutable, boObject, boAssemblyListing],
    [bfIntegerScalar, bfPointer, bfAggregate, bfFloatingPoint, bfVariadic,
     bfFunctionPointer, bfPIC, bfDynamicLink, bfInlineAssembly, bfDebugInfo],
    'supported x86-64 backend with ELF executables and ELF/Mach-O objects');
  AddBackend(Result, 'aarch64-integer', archAArch64, bmExperimental,
    [boExecutable, boObject], [bfIntegerScalar],
    'freestanding AAPCS64 integer locals/globals and ELF/Mach-O objects');
  AddBackend(Result, 'riscv64-integer', archRISCV64, bmExperimental,
    [boExecutable, boObject], [bfIntegerScalar],
    'freestanding RV64IM integer locals/globals, calls, and BSD/Linux ELF');
end;

function FindBackend(AArchitecture: TArchitecture;
  out ABackend: TBackendDescriptor): Boolean;
var
  B: TBackendDescriptorArray;
  I: LongInt;
begin
  B := RegisteredBackends;
  for I := 0 to High(B) do
    if B[I].Architecture = AArchitecture then
    begin
      ABackend := B[I];
      Exit(True);
    end;
  ABackend.Name := '';
  ABackend.Architecture := archUnknown;
  ABackend.Maturity := bmUnavailable;
  ABackend.Outputs := [];
  ABackend.Features := [];
  ABackend.Description := '';
  Result := False;
end;

function BackendSupportsOutput(const ABackend: TBackendDescriptor;
  AOutput: TBackendOutput): Boolean;
begin
  Result := AOutput in ABackend.Outputs;
end;

function BackendSupportsFeature(const ABackend: TBackendDescriptor;
  AFeature: TBackendFeature): Boolean;
begin
  Result := AFeature in ABackend.Features;
end;

function ModuleUsesOpaqueOperations(AModule: TIRModule): Boolean;
begin
  Result := (AModule <> nil) and AModule.HasOpaqueOperations;
end;

function ValidateBackendRequest(const ABackend: TBackendDescriptor;
  AOutput: TBackendOutput; AModule: TIRModule; out AReason: string): Boolean;
begin
  AReason := '';
  if ABackend.Maturity = bmUnavailable then
  begin
    AReason := 'backend is unavailable';
    Exit(False);
  end;
  if not BackendSupportsOutput(ABackend, AOutput) then
  begin
    AReason := 'backend cannot emit ' + BackendOutputName(AOutput);
    Exit(False);
  end;
  if (ABackend.Maturity = bmBootstrap) and ModuleUsesOpaqueOperations(AModule) then
  begin
    AReason := 'bootstrap backend cannot lower opaque IR operations';
    Exit(False);
  end;
  Result := True;
end;

function EmitModeBackendOutput(AEmitMode: TEmitMode): TBackendOutput;
begin
  case AEmitMode of
    emObject: Result := boObject;
    emAssembly: Result := boAssemblyListing;
  else
    Result := boExecutable;
  end;
end;

function BackendDetailedText(const ABackend: TBackendDescriptor): string;
var
  Lines: TStringList;
  O: TBackendOutput;
  F: TBackendFeature;
begin
  Lines := TStringList.Create;
  try
    Lines.Add(Format('%s (%s)', [ABackend.Name,
      ArchitectureName(ABackend.Architecture)]));
    Lines.Add('  maturity: ' + BackendMaturityName(ABackend.Maturity));
    Lines.Add('  description: ' + ABackend.Description);
    Lines.Add('  outputs:');
    for O := Low(TBackendOutput) to High(TBackendOutput) do
      if O in ABackend.Outputs then Lines.Add('    ' + BackendOutputName(O));
    Lines.Add('  features:');
    for F := Low(TBackendFeature) to High(TBackendFeature) do
      if F in ABackend.Features then Lines.Add('    ' + BackendFeatureName(F));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function BackendRegistryText: string;
var
  Backends: TBackendDescriptorArray;
  Lines: TStringList;
  I: LongInt;
begin
  Backends := RegisteredBackends;
  Lines := TStringList.Create;
  try
    for I := 0 to High(Backends) do
      Lines.Add(Format('%-24s %-12s %-13s %s',
        [Backends[I].Name, ArchitectureName(Backends[I].Architecture),
         BackendMaturityName(Backends[I].Maturity), Backends[I].Description]));
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
