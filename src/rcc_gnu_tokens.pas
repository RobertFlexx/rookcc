unit rcc_gnu_tokens;

{$mode objfpc}{$H+}

interface

uses
  rcc_types;

procedure NormalizeGNUTokens(var ATokens: TTokenArray;
  AStandard: TCStandard);

implementation

uses
  SysUtils, rcc_gnu_compat;

procedure AppendToken(var ADestination: TTokenArray; var ACount,
  ACapacity: LongInt; const AToken: TToken);
begin
  if ACount >= ACapacity then
  begin
    if ACapacity = 0 then ACapacity := 4096
    else ACapacity := ACapacity * 2;
    SetLength(ADestination, ACapacity);
  end;
  ADestination[ACount] := AToken;
  Inc(ACount);
end;

function CanonicalKeywordKind(const ACanonical: string;
  out AKind: TTokenKind): Boolean;
begin
  Result := True;
  if ACanonical = 'const' then AKind := kwConst
  else if ACanonical = 'inline' then AKind := kwInline
  else if ACanonical = 'restrict' then AKind := kwRestrict
  else if ACanonical = 'signed' then AKind := kwSigned
  else if ACanonical = 'volatile' then AKind := kwVolatile
  else if ACanonical = '_Alignof' then AKind := kwAlignof
  else if ACanonical = 'asm' then AKind := kwAsm
  else if ACanonical = 'typeof' then AKind := kwTypeof
  else Result := False;
end;

function IsIdentifierNamed(const AToken: TToken;
  const AName: string): Boolean;
begin
  Result := (AToken.Kind = tkIdentifier) and
    (LowerCase(AToken.Text) = LowerCase(AName));
end;

function SkipBalancedParentheses(const ATokens: TTokenArray;
  AStart: LongInt): LongInt;
var
  Depth, I: LongInt;
begin
  Result := AStart;
  if (AStart > High(ATokens)) or
     (ATokens[AStart].Kind <> tkLParen) then Exit;
  Depth := 0;
  I := AStart;
  while I <= High(ATokens) do
  begin
    if ATokens[I].Kind = tkLParen then Inc(Depth)
    else if ATokens[I].Kind = tkRParen then
    begin
      Dec(Depth);
      if Depth = 0 then Exit(I + 1);
    end
    else if ATokens[I].Kind = tkEOF then Exit(I);
    Inc(I);
  end;
  Result := I;
end;


function SkipAttributeInvocation(const ATokens: TTokenArray;
  AIndex: LongInt): LongInt;
var
  I: LongInt;
begin
  I := AIndex + 1;
  while (I <= High(ATokens)) and
        (ATokens[I].Kind = tkLParen) do
    I := SkipBalancedParentheses(ATokens, I);
  Result := I;
end;

procedure NormalizeGNUTokens(var ATokens: TTokenArray;
  AStandard: TCStandard);
var
  ResultTokens: TTokenArray;
  I, J, Count, Capacity, AttrEnd: LongInt;
  Canonical: string;
  Kind: TTokenKind;
  Token: TToken;
begin
  SetLength(ResultTokens, 0);
  Count := 0;
  Capacity := 0;
  I := 0;
  while I <= High(ATokens) do
  begin
    Token := ATokens[I];



    if IsIdentifierNamed(Token, '__extension__') then
    begin
      Inc(I);
      Continue;
    end;






    if IsIdentifierNamed(Token, '__attribute__') or
       IsIdentifierNamed(Token, '__attribute') or
       IsIdentifierNamed(Token, '__declspec') then
    begin
      AttrEnd := SkipAttributeInvocation(ATokens, I);
      Token.Kind := kwGNUAttribute;
      Token.Text := '__attribute__';
      AppendToken(ResultTokens, Count, Capacity, Token);
      J := I + 1;
      while J < AttrEnd do
      begin
        AppendToken(ResultTokens, Count, Capacity, ATokens[J]);
        Inc(J);
      end;
      I := AttrEnd;
      Continue;
    end;

    if IsGNUStandard(AStandard) and
       (Token.Kind = tkIdentifier) and
       IsGNUAlternateKeyword(Token.Text, Canonical) and
       CanonicalKeywordKind(Canonical, Kind) then
    begin
      Token.Kind := Kind;
      Token.Text := Canonical;
    end;

    AppendToken(ResultTokens, Count, Capacity, Token);
    Inc(I);
  end;

  if (Count = 0) or
     (ResultTokens[Count - 1].Kind <> tkEOF) then
  begin
    Token.Kind := tkEOF;
    Token.Text := '';
    Token.IntValue := 0;
    Token.FloatValue := 0.0;
    Token.Pos.FileName := '';
    Token.Pos.Line := 0;
    Token.Pos.Column := 0;
    AppendToken(ResultTokens, Count, Capacity, Token);
  end;
  SetLength(ResultTokens, Count);
  ATokens := ResultTokens;
end;

end.
