unit rcc_runtime_catalog;

{$mode objfpc}{$H+}

interface

function RuntimeSymbolCount: LongInt;
function RuntimeSymbolName(AIndex: LongInt): string;
function RuntimeDependencyCount(const AName: string): LongInt;
function RuntimeDependencyName(const AName: string; AIndex: LongInt): string;

implementation

const
  RuntimeNames: array[0..55] of string = (
    'read',
    'write',
    'close',
    'open',
    'lseek',
    'getpid',
    'getpagesize',
    'access',
    'time',
    'exit',
    '_Exit',
    '_exit',
    'abort',
    'atexit',
    'strlen',
    'puts',
    'putchar',
    'getchar',
    'print_int',
    '__rcc_print_string',
    '__rcc_print_int_raw',
    'malloc',
    'calloc',
    'realloc',
    'reallocarray',
    'free',
    'memcpy',
    'memmove',
    'memset',
    'memcmp',
    'strcmp',
    'strncmp',
    'strcpy',
    'strncpy',
    'strchr',
    'strrchr',
    'strnlen',
    '__rcc_parse_decimal',
    'atoi',
    'atol',
    'assert',
    'isdigit',
    'isspace',
    'isalpha',
    'isalnum',
    'islower',
    'isupper',
    'isxdigit',
    'isprint',
    'isgraph',
    'iscntrl',
    'ispunct',
    'tolower',
    'toupper',
    'abs',
    'labs'
  );

function RuntimeSymbolCount: LongInt;
begin
  Result := Length(RuntimeNames);
end;

function RuntimeSymbolName(AIndex: LongInt): string;
begin
  if (AIndex < Low(RuntimeNames)) or (AIndex > High(RuntimeNames)) then
    Result := ''
  else
    Result := RuntimeNames[AIndex];
end;

function RuntimeDependencyCount(const AName: string): LongInt;
begin
  if (AName = 'puts') or (AName = '__rcc_print_string') then Result := 1
  else if AName = 'calloc' then Result := 2
  else if AName = 'realloc' then Result := 3
  else if AName = 'reallocarray' then Result := 1
  else if (AName = 'atoi') or (AName = 'atol') then Result := 1
  else Result := 0;
end;

function RuntimeDependencyName(const AName: string; AIndex: LongInt): string;
begin
  Result := '';
  if ((AName = 'puts') or (AName = '__rcc_print_string')) and (AIndex = 0) then
    Result := 'strlen'
  else if AName = 'calloc' then
  begin
    if AIndex = 0 then Result := 'malloc'
    else if AIndex = 1 then Result := 'memset';
  end
  else if AName = 'realloc' then
  begin
    if AIndex = 0 then Result := 'malloc'
    else if AIndex = 1 then Result := 'memcpy'
    else if AIndex = 2 then Result := 'free';
  end
  else if (AName = 'reallocarray') and (AIndex = 0) then
    Result := 'realloc'
  else if ((AName = 'atoi') or (AName = 'atol')) and (AIndex = 0) then
    Result := '__rcc_parse_decimal';
end;

end.
