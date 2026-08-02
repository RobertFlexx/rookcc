unit rcc_target;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, rcc_types, rcc_build, rcc_arch;

type
  TTargetInfo = record
    Triple: string;
    Architecture: string;
    OperatingSystem: string;
    ObjectFormat: string;
    ABI: string;
    PointerBits: LongInt;
    LittleEndian: Boolean;
    SupportsPIC: Boolean;
    SupportsObjects: Boolean;
    SupportsDynamicLinking: Boolean;
    Maturity: string;
  end;

function NativeTarget: TTargetInfo;
function TargetInfoFor(const AValue: string): TTargetInfo;
function NormalizeTargetTriple(const AValue: string): string;
function TargetIsSupported(const AValue: string): Boolean;
function TargetSummary(const AInfo: TTargetInfo): string;
function TargetDescriptorFor(const AValue: string): TTargetDescriptor;

implementation

function DescriptorToInfo(const D: TTargetDescriptor): TTargetInfo;
begin
  Result.Triple := D.Triple;
  Result.Architecture := ArchitectureName(D.Architecture);
  Result.OperatingSystem := OperatingSystemName(D.OperatingSystem);
  Result.ObjectFormat := ObjectFormatName(D.ObjectFormat);
  Result.ABI := D.ABIName;
  Result.PointerBits := D.DataLayout.PointerBits;
  Result.LittleEndian := D.DataLayout.Endianness = endianLittle;
  Result.SupportsPIC := TargetHasCapability(D, tcPositionIndependent);
  Result.SupportsObjects := TargetHasCapability(D, tcRelocatableObject);
  Result.SupportsDynamicLinking := TargetHasCapability(D, tcDynamicELF);
  if (D.Architecture = archX86_64) and
     (D.OperatingSystem = osLinux) then
    Result.Maturity := 'supported'
  else if D.Architecture in [archX86_64, archAArch64, archRISCV64] then
    Result.Maturity := 'experimental'
  else
    Result.Maturity := 'unavailable';
end;

function NativeTarget: TTargetInfo;
begin
  Result := DescriptorToInfo(NativeTargetDescriptor);
end;

function TargetInfoFor(const AValue: string): TTargetInfo;
begin
  Result := DescriptorToInfo(GetTargetOrRaise(AValue));
end;

function NormalizeTargetTriple(const AValue: string): string;
begin
  Result := NormalizeTargetAlias(AValue);
end;

function TargetIsSupported(const AValue: string): Boolean;
var
  D: TTargetDescriptor;
begin
  Result := TryGetTarget(AValue, D);
end;

function TargetSummary(const AInfo: TTargetInfo): string;
begin
  Result := AInfo.Triple + ' (' + AInfo.ObjectFormat + ', ' + AInfo.ABI +
    ', ' + AInfo.Maturity + ')';
end;

function TargetDescriptorFor(const AValue: string): TTargetDescriptor;
begin
  Result := GetTargetOrRaise(AValue);
end;

end.
