unit rcc_libc_catalog;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TLibCSymbolDescriptor = record
    Name: string;
    Category: string;
    LibraryName: string;
    DynamicallyImportable: Boolean;
  end;
  TLibCSymbolDescriptorArray = array of TLibCSymbolDescriptor;

function BuildLibCSymbolCatalog: TLibCSymbolDescriptorArray;
function FindLibCSymbol(const ACatalog: TLibCSymbolDescriptorArray;
  const AName: string; out ADescriptor: TLibCSymbolDescriptor): Boolean;
function LibCSymbolCatalogSummary(const ACatalog: TLibCSymbolDescriptorArray): string;

implementation

uses rcc_runtime_catalog;

procedure AddSymbol(var AValues: TLibCSymbolDescriptorArray;
  const AName, ACategory, ALibrary: string; AImportable: Boolean);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N].Name := AName;
  AValues[N].Category := ACategory;
  AValues[N].LibraryName := ALibrary;
  AValues[N].DynamicallyImportable := AImportable;
end;

function SymbolCategory(const AName: string): string;
begin
  if (AName = 'read') or (AName = 'write') or (AName = 'close') or
     (AName = 'open') or (AName = 'lseek') or (AName = 'access') then
    Exit('io');
  if (AName = 'malloc') or (AName = 'calloc') or (AName = 'realloc') or
     (AName = 'reallocarray') or (AName = 'free') then Exit('memory');
  if (AName = 'memcpy') or (AName = 'memmove') or (AName = 'memset') or
     (AName = 'memcmp') then Exit('memory');
  if (AName = 'strlen') or (AName = 'strcmp') or (AName = 'strncmp') or
     (AName = 'strcpy') or (AName = 'strncpy') or (AName = 'strchr') or
     (AName = 'strrchr') or (AName = 'strnlen') then Exit('string');
  if (AName = 'isdigit') or (AName = 'isspace') or (AName = 'isalpha') or
     (AName = 'isalnum') or (AName = 'islower') or (AName = 'isupper') or
     (AName = 'isxdigit') or (AName = 'isprint') or (AName = 'isgraph') or
     (AName = 'iscntrl') or (AName = 'ispunct') or (AName = 'tolower') or
     (AName = 'toupper') then Exit('ctype');
  if (AName = 'puts') or (AName = 'putchar') or (AName = 'getchar') then
    Exit('stdio');
  if (AName = 'atoi') or (AName = 'atol') or (AName = 'abs') or
     (AName = 'labs') then Exit('stdlib');
  if (AName = 'exit') or (AName = '_Exit') or (AName = '_exit') or
     (AName = 'abort') or (AName = 'atexit') or (AName = 'assert') then
    Exit('process');
  if (AName = 'getpid') or (AName = 'getpagesize') or (AName = 'time') then
    Exit('system');
  Result := 'runtime';
end;

function IsInternalRuntimeSymbol(const AName: string): Boolean;
begin
  Result := (Pos('__rcc_', AName) = 1) or (AName = 'print_int') or
    (AName = '__rcc_parse_decimal');
end;

function BuildLibCSymbolCatalog: TLibCSymbolDescriptorArray;
var
  I: LongInt;
  Name: string;
  Internal: Boolean;
begin
  Result := nil;
  for I := 0 to RuntimeSymbolCount - 1 do
  begin
    Name := RuntimeSymbolName(I);
    Internal := IsInternalRuntimeSymbol(Name);
    if Internal then
      AddSymbol(Result, Name, SymbolCategory(Name), 'rcc-runtime', False)
    else
      AddSymbol(Result, Name, SymbolCategory(Name), 'libc', True);
  end;
end;

function FindLibCSymbol(const ACatalog: TLibCSymbolDescriptorArray;
  const AName: string; out ADescriptor: TLibCSymbolDescriptor): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if ACatalog[I].Name = AName then
    begin
      ADescriptor := ACatalog[I];
      Exit(True);
    end;
  ADescriptor := Default(TLibCSymbolDescriptor);
  Result := False;
end;

function LibCSymbolCatalogSummary(const ACatalog: TLibCSymbolDescriptorArray): string;
var
  I, Importable, Internal: LongInt;
begin
  Importable := 0;
  Internal := 0;
  for I := 0 to High(ACatalog) do
    if ACatalog[I].DynamicallyImportable then Inc(Importable)
    else Inc(Internal);
  Result := Format('%d runtime-facing symbols (%d libc candidates, %d rcc runtime helpers)',
    [Length(ACatalog), Importable, Internal]);
end;

end.
