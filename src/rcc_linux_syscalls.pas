unit rcc_linux_syscalls;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TLinuxSyscallDescriptor = record
    Architecture: string;
    Name: string;
    Number: LongInt;
    Category: string;
  end;
  TLinuxSyscallDescriptorArray = array of TLinuxSyscallDescriptor;

function BuildLinuxSyscallCatalog: TLinuxSyscallDescriptorArray;
function FindLinuxSyscall(const ACatalog: TLinuxSyscallDescriptorArray;
  const AArchitecture, AName: string;
  out ADescriptor: TLinuxSyscallDescriptor): Boolean;
function LinuxSyscallCatalogSummary(
  const ACatalog: TLinuxSyscallDescriptorArray): string;

implementation

uses rcc_arch;

procedure AddSyscall(var AValues: TLinuxSyscallDescriptorArray;
  const AArchitecture, AName: string; ANumber: LongInt;
  const ACategory: string);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N].Architecture := AArchitecture;
  AValues[N].Name := AName;
  AValues[N].Number := ANumber;
  AValues[N].Category := ACategory;
end;

function SyscallCategory(const AName: string): string;
begin
  if (AName = 'read') or (AName = 'write') or (AName = 'open') or
     (AName = 'close') or (AName = 'lseek') or (AName = 'access') then
    Exit('filesystem');
  if (AName = 'mmap') or (AName = 'munmap') then Exit('memory');
  if (AName = 'getpid') or (AName = 'exit') then Exit('process');
  if AName = 'time' then Exit('time');
  Result := 'other';
end;

procedure AddKnownForTarget(var AValues: TLinuxSyscallDescriptorArray;
  const ATriple: string);
const
  Names: array[0..10] of string = (
    'read', 'write', 'open', 'close', 'lseek', 'mmap', 'munmap',
    'access', 'getpid', 'exit', 'time');
var
  D: TTargetDescriptor;
  I: LongInt;
  Number: LongWord;
begin
  D := GetTargetOrRaise(ATriple);
  for I := Low(Names) to High(Names) do
    if TargetSyscallNumber(D, Names[I], Number) then
      AddSyscall(AValues, ArchitectureName(D.Architecture), Names[I],
        LongInt(Number), SyscallCategory(Names[I]));
end;

function BuildLinuxSyscallCatalog: TLinuxSyscallDescriptorArray;
begin
  Result := nil;
  AddKnownForTarget(Result, 'x86_64-unknown-linux-rcc');
  AddKnownForTarget(Result, 'aarch64-unknown-linux-rcc');
  AddKnownForTarget(Result, 'riscv64-unknown-linux-rcc');
end;

function FindLinuxSyscall(const ACatalog: TLinuxSyscallDescriptorArray;
  const AArchitecture, AName: string;
  out ADescriptor: TLinuxSyscallDescriptor): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if SameText(ACatalog[I].Architecture, AArchitecture) and
       SameText(ACatalog[I].Name, AName) then
    begin
      ADescriptor := ACatalog[I];
      Exit(True);
    end;
  ADescriptor := Default(TLinuxSyscallDescriptor);
  Result := False;
end;

function LinuxSyscallCatalogSummary(
  const ACatalog: TLinuxSyscallDescriptorArray): string;
var
  I, X64, A64, RV64: LongInt;
begin
  X64 := 0;
  A64 := 0;
  RV64 := 0;
  for I := 0 to High(ACatalog) do
    if ACatalog[I].Architecture = 'x86_64' then Inc(X64)
    else if ACatalog[I].Architecture = 'aarch64' then Inc(A64)
    else if ACatalog[I].Architecture = 'riscv64' then Inc(RV64);
  Result := Format('%d direct syscall mappings from rcc_arch (x86_64 %d, aarch64 %d, riscv64 %d)',
    [Length(ACatalog), X64, A64, RV64]);
end;

end.
