unit rcc_args;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;




procedure LoadCommandLineArguments(out AArguments: rcc_types.TStringArray);

implementation

uses
  Classes, SysUtils;

procedure AppendArgument(var AArguments: rcc_types.TStringArray; const AValue: string);
var
  N: LongInt;
begin
  N := Length(AArguments);
  SetLength(AArguments, N + 1);
  AArguments[N] := AValue;
end;

procedure TokenizeResponse(const AText: string; AOutput: TStrings);
var
  I: LongInt;
  C, Quote: Char;
  Token: string;
  InToken: Boolean;
begin
  I := 1;
  Quote := #0;
  Token := '';
  InToken := False;
  while I <= Length(AText) do
  begin
    C := AText[I];
    if Quote <> #0 then
    begin
      if C = Quote then
        Quote := #0
      else if (C = '\') and (I < Length(AText)) then
      begin
        Inc(I);
        Token := Token + AText[I];
      end
      else
        Token := Token + C;
      InToken := True;
    end
    else if (C = '''') or (C = '"') then
    begin
      Quote := C;
      InToken := True;
    end
    else if C in [' ', #9, #10, #13] then
    begin
      if InToken then
      begin
        AOutput.Add(Token);
        Token := '';
        InToken := False;
      end;
    end
    else if (C = '#') and not InToken then
    begin
      while (I <= Length(AText)) and not (AText[I] in [#10, #13]) do Inc(I);
      Continue;
    end
    else if (C = '\') and (I < Length(AText)) then
    begin
      Inc(I);
      Token := Token + AText[I];
      InToken := True;
    end
    else
    begin
      Token := Token + C;
      InToken := True;
    end;
    Inc(I);
  end;
  if Quote <> #0 then
    raise ERCCError.Create('error: unterminated quote in response file');
  if InToken then AOutput.Add(Token);
end;

procedure ExpandArgument(const AValue: string; var AArguments: rcc_types.TStringArray;
  ADepth: LongInt);
var
  Path, Text: string;
  Stream: TStringList;
  Tokens: TStringList;
  I: LongInt;
begin
  if ADepth > 16 then
    raise ERCCError.Create('error: response-file nesting exceeds 16 levels');
  if (Length(AValue) >= 2) and (AValue[1] = '@') then
  begin
    if AValue[2] = '@' then
    begin
      AppendArgument(AArguments, Copy(AValue, 2, MaxInt));
      Exit;
    end;
    Path := Copy(AValue, 2, MaxInt);
    if not FileExists(Path) then
      raise ERCCError.Create('error: response file not found: ' + Path);
    Stream := TStringList.Create;
    Tokens := TStringList.Create;
    try
      Stream.LoadFromFile(Path);
      Text := Stream.Text;
      TokenizeResponse(Text, Tokens);
      for I := 0 to Tokens.Count - 1 do
        ExpandArgument(Tokens[I], AArguments, ADepth + 1);
    finally
      Tokens.Free;
      Stream.Free;
    end;
    Exit;
  end;
  AppendArgument(AArguments, AValue);
end;

procedure LoadCommandLineArguments(out AArguments: rcc_types.TStringArray);
var
  I: LongInt;
begin
  SetLength(AArguments, 1);
  AArguments[0] := '';
  for I := 1 to ParamCount do
    ExpandArgument(ParamStr(I), AArguments, 0);
end;

end.
