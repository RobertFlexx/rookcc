unit rcc_builtin_catalog;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TBuiltinDescriptor = record
    Name: string;
    Category: string;
    Target: string;
    ConstantFoldable: Boolean;
    Cost: LongInt;
  end;
  TBuiltinDescriptorArray = array of TBuiltinDescriptor;

function BuildBuiltinCatalog: TBuiltinDescriptorArray;
function FindBuiltin(const ACatalog: TBuiltinDescriptorArray;
  const AName: string; out ADescriptor: TBuiltinDescriptor): Boolean;
function BuiltinCatalogText(const ACatalog: TBuiltinDescriptorArray): string;

implementation

procedure AddBuiltin(var AValues: TBuiltinDescriptorArray;
  const AName, ACategory, ATarget: string; AConstantFoldable: Boolean;
  ACost: LongInt);
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N].Name := AName;
  AValues[N].Category := ACategory;
  AValues[N].Target := ATarget;
  AValues[N].ConstantFoldable := AConstantFoldable;
  AValues[N].Cost := ACost;
end;

function BuildBuiltinCatalog: TBuiltinDescriptorArray;
begin
  Result := nil;
  AddBuiltin(Result, '__builtin_offsetof', 'layout', 'native', True, 0);
  AddBuiltin(Result, '__builtin_expect', 'optimization', 'native', True, 0);
  AddBuiltin(Result, '__builtin_expect_with_probability',
    'optimization', 'native', True, 0);
  AddBuiltin(Result, '__builtin_constant_p',
    'compile-time', 'native', True, 0);
  AddBuiltin(Result, '__builtin_choose_expr',
    'compile-time', 'native', True, 0);
  AddBuiltin(Result, '__builtin_trap', 'control', 'x86-64', False, 1);
  AddBuiltin(Result, '__builtin_unreachable', 'control', 'x86-64', False, 1);
  AddBuiltin(Result, '__builtin_va_start', 'variadic', 'x86-64', False, 2);
  AddBuiltin(Result, '__builtin_va_arg', 'variadic', 'x86-64', False, 4);
  AddBuiltin(Result, '__builtin_va_copy', 'variadic', 'x86-64', False, 2);
  AddBuiltin(Result, '__builtin_va_end', 'variadic', 'x86-64', False, 0);
end;

function FindBuiltin(const ACatalog: TBuiltinDescriptorArray;
  const AName: string; out ADescriptor: TBuiltinDescriptor): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if ACatalog[I].Name = AName then
    begin
      ADescriptor := ACatalog[I];
      Exit(True);
    end;
  ADescriptor.Name := '';
  ADescriptor.Category := '';
  ADescriptor.Target := '';
  ADescriptor.ConstantFoldable := False;
  ADescriptor.Cost := 0;
  Result := False;
end;

function BuiltinCatalogText(const ACatalog: TBuiltinDescriptorArray): string;
var
  I, Foldable: LongInt;
begin
  Foldable := 0;
  for I := 0 to High(ACatalog) do
    if ACatalog[I].ConstantFoldable then Inc(Foldable);
  Result := Format('%d implemented native compiler builtins (%d compile-time)',
    [Length(ACatalog), Foldable]);
end;

end.
