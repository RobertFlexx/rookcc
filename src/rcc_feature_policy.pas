unit rcc_feature_policy;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;




function BuildPredefinedMacros(AStandard: TCStandard;
  AFreestanding: Boolean): rcc_types.TStringArray;

implementation

uses
  SysUtils, rcc_build;

procedure AddDefine(var AValues: rcc_types.TStringArray; const AName: string;
  const AValue: string = '1');
var
  N: LongInt;
begin
  N := Length(AValues);
  SetLength(AValues, N + 1);
  AValues[N] := AName + '=' + AValue;
end;

function BuildPredefinedMacros(AStandard: TCStandard;
  AFreestanding: Boolean): rcc_types.TStringArray;
var
  StandardVersion: string;
begin
  Result := nil;
  AddDefine(Result, '__ROOKCC__');
  AddDefine(Result, '__ROOKCC_VERSION__', IntToStr(RCCVersionNumber));
  AddDefine(Result, '__ROOKCC_MAJOR__', '4');
  AddDefine(Result, '__ROOKCC_MINOR__', '0');
  AddDefine(Result, '__ROOKCC_PATCH__', '0');
  AddDefine(Result, '__ROOKCC_TARGET__', '1');

  AddDefine(Result, '__STDC__');
  StandardVersion := CStandardVersion(AStandard);
  if StandardVersion <> '' then
    AddDefine(Result, '__STDC_VERSION__', StandardVersion);
  if IsGNUStandard(AStandard) then
    AddDefine(Result, '__RCC_GNU_DIALECT__')
  else
    AddDefine(Result, '__STRICT_ANSI__');
  if AStandard = csRCC then
  begin
    AddDefine(Result, '_RCC_SOURCE');
    AddDefine(Result, '__RCC_SOURCE__');
  end;

  if AFreestanding then AddDefine(Result, '__STDC_HOSTED__', '0')
  else AddDefine(Result, '__STDC_HOSTED__', '1');

  AddDefine(Result, '__BYTE_ORDER__', '1234');
  AddDefine(Result, '__ORDER_LITTLE_ENDIAN__', '1234');
  AddDefine(Result, '__ORDER_BIG_ENDIAN__', '4321');
  AddDefine(Result, '__CHAR_BIT__', '8');
  AddDefine(Result, '__SIZEOF_SHORT__', '2');
  AddDefine(Result, '__SIZEOF_INT__', '4');
  AddDefine(Result, '__SIZEOF_LONG__', '8');
  AddDefine(Result, '__SIZEOF_LONG_LONG__', '8');
  AddDefine(Result, '__SIZEOF_POINTER__', '8');
  AddDefine(Result, '__SIZEOF_SIZE_T__', '8');
  AddDefine(Result, '__SIZEOF_PTRDIFF_T__', '8');
  AddDefine(Result, '__SIZE_TYPE__', 'unsigned long');
  AddDefine(Result, '__PTRDIFF_TYPE__', 'long');
  AddDefine(Result, '__INTPTR_TYPE__', 'long');
  AddDefine(Result, '__UINTPTR_TYPE__', 'unsigned long');
end;

end.
