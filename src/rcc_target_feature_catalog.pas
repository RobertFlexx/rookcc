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

uses rcc_arch;

procedure AddFeature(var AValues: TTargetFeatureDescriptorArray;
  const AArchitecture, ACPU, AFeature: string; AVectorWidth: LongInt;
  ARequired: Boolean);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N].Architecture := AArchitecture;
  AValues[N].CPU := ACPU;
  AValues[N].Feature := AFeature;
  AValues[N].VectorWidth := AVectorWidth;
  AValues[N].Latency := 0;
  AValues[N].ReciprocalThroughput := 0;
  AValues[N].RequiredByBaseline := ARequired;
end;

function FeatureWidth(const AArchitecture, AFeature: string): LongInt;
begin
  Result := 0;
  if SameText(AArchitecture, 'x86_64') and
     (SameText(AFeature, 'sse') or SameText(AFeature, 'sse2')) then
    Result := 128
  else if SameText(AArchitecture, 'aarch64') and SameText(AFeature, 'simd') then
    Result := 128;
end;

procedure AddTargetFeatures(var AValues: TTargetFeatureDescriptorArray;
  const ATriple: string);
var
  D: TTargetDescriptor;
  S, Item: string;
  P: LongInt;
begin
  D := GetTargetOrRaise(ATriple);
  AddFeature(AValues, ArchitectureName(D.Architecture), D.CPUName,
    'baseline', 0, True);
  S := D.CPUFeatures;
  while S <> '' do
  begin
    P := Pos(',', S);
    if P = 0 then
    begin
      Item := S;
      S := '';
    end
    else
    begin
      Item := Copy(S, 1, P - 1);
      Delete(S, 1, P);
    end;
    Item := Trim(Item);
    while Item <> '' do
    begin
      if (Item[1] = '+') or (Item[1] = '-') then Delete(Item, 1, 1)
      else Break;
    end;
    if Item <> '' then
      AddFeature(AValues, ArchitectureName(D.Architecture), D.CPUName,
        Item, FeatureWidth(ArchitectureName(D.Architecture), Item), True);
  end;
end;

function BuildTargetFeatureCatalog: TTargetFeatureDescriptorArray;
begin
  Result := nil;
  AddTargetFeatures(Result, 'x86_64-unknown-linux-rcc');
  AddTargetFeatures(Result, 'aarch64-unknown-linux-rcc');
  AddTargetFeatures(Result, 'riscv64-unknown-linux-rcc');
end;

function TargetFeatureSummary(const ACatalog: TTargetFeatureDescriptorArray;
  const AArchitecture: string): string;
var
  I, Count: LongInt;
  CPU: string;
begin
  Count := 0;
  CPU := '';
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Architecture, AArchitecture) then
    begin
      Inc(Count);
      if CPU = '' then CPU := ACatalog[I].CPU;
    end;
  Result := Format('%s: %d compiler baseline features for %s',
    [AArchitecture, Count, CPU]);
end;

function TargetSupportsFeature(const ACatalog: TTargetFeatureDescriptorArray;
  const AArchitecture, ACPU, AFeature: string): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Architecture, AArchitecture) and
       SameText(ACatalog[I].CPU, ACPU) and
       SameText(ACatalog[I].Feature, AFeature) then Exit(True);
  Result := False;
end;

end.
