unit rcc_frontend;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, rcc_types, rcc_typeops;

type
  TMacro = record
    Name: string;
    Value: string;
    IsFunctionLike: Boolean;
    ParamNames: array of string;
    HasVariadic: Boolean;
  end;

  TMacroArray = array of TMacro;

  TCondition = record
    ParentActive: Boolean;
    ThisActive: Boolean;
    BranchTaken: Boolean;
    ElseSeen: Boolean;
  end;

  TTypedefEntry = record
    Name: string;
    CType: TCType;
  end;

  TIntegerConstantEntry = record
    Name: string;
    Value: Int64;
  end;

  TDeclaredTypeEntry = record
    Name: string;
    CType: TCType;
    ScopeDepth: LongInt;
    IsFunction: Boolean;
  end;

  TPreprocessor = class
  private
    FMacros: TMacroArray;
    FMacroIndex: array of LongInt;
    FMacroIndexDirty: Boolean;
    FIncludePaths: array of string;
    FConditions: array of TCondition;
    FIncludeDepth: LongInt;
    FDependencies: rcc_types.TStringArray;
    FPragmaOnceFiles: rcc_types.TStringArray;
    FLinkLibraries: rcc_types.TStringArray;
    FMacroNeedsContinuation: Boolean;
    procedure AddDependency(const AFileName: string);
    function IsPragmaOnceFile(const AFileName: string): Boolean;
    procedure AddPragmaOnceFile(const AFileName: string);
    procedure AddLinkLibrary(const AName, AFileName: string; ALine: LongInt);
    procedure ProcessPragma(const AText, AFileName: string; ALine: LongInt);
    function FindMacro(const AName: string): LongInt;
    procedure RebuildMacroIndex;
    procedure MarkMacroIndexDirty;
    procedure DefineMacro(const AName, AValue: string);
    procedure DefineFunctionMacro(const AName, AValue: string;
      const AParamNames: array of string; AVariadic: Boolean);
    procedure UndefineMacro(const AName: string);
    function ExpandMacrosOnce(const ALine: string): string;
    function ExpandMacros(const ALine: string): string;
    function IsActive: Boolean;
    function EvaluateCondition(const AText, ACurrentDir: string): Boolean;
    function ResolveInclude(const AName, ACurrentDir: string;
      AAngled: Boolean): string;
    function IsBuiltinHeader(const AName: string): Boolean;
    function BuiltinHeaderText(const AName: string): string;
    procedure ProcessFileInternal(const AFileName: string;
      AOutput: TStringList);
  public
    constructor Create(const AIncludePaths, ADefines, AUndefines: array of string;
      AStandard: TCStandard);
    function ProcessFile(const AFileName: string): string;
    function Dependencies: rcc_types.TStringArray;
    function LinkLibraries: rcc_types.TStringArray;
  end;

  TLexer = class
  private
    FSource: string;
    FFileName: string;
    FIndex: LongInt;
    FLine: LongInt;
    FColumn: LongInt;
    FTokenCount: LongInt;
    FTokenCapacity: LongInt;
    function Current: Char;
    function Peek(AOffset: LongInt = 1): Char;
    procedure Advance;
    procedure SkipWhitespaceAndComments;
    function Position: TSourcePos;
    function ReadIdentifier: string;
    function ReadNumber(out AValue: Int64; out AFloatValue: Double;
      out AIsFloat: Boolean): string;
    function ReadQuoted(AQuote: Char; out AValue: string): string;
    function KeywordKind(const AText: string): TTokenKind;
    procedure AddToken(var ATokens: TTokenArray; AKind: TTokenKind;
      const AText: string; AValue: Int64; AFloatValue: Double;
      const APos: TSourcePos);
  public
    constructor Create(const ASource, AFileName: string);
    function Tokenize: TTokenArray;
  end;

  TParser = class
  private
    FTokens: TTokenArray;
    FIndex: LongInt;
    FTypedefs: array of TTypedefEntry;
    FIntegerConstants: array of TIntegerConstantEntry;
    FDeclaredTypes: array of TDeclaredTypeEntry;
    FScopeDepth: LongInt;
    FStructs: array of TStructMembers;
    FOwnedStructInfos: array of PStructMembers;
    FOwnedMemberTypes: array of PCType;
    FOwnedFunctionParameterLists: array of PFunctionParameterList;
    FSwitchLabels: array of Int64;
    FSwitchHasDefault: Boolean;
    { Records whether the storage class of the most recently parsed declaration
      specifier list included `static`. }
    FLastTypeWasStatic: Boolean;
    FInSwitch: LongInt;
    FBreakableDepth: LongInt;
    FContinueableDepth: LongInt;
    function Current: TToken;
    function Peek(AOffset: LongInt = 1): TToken;
    function At(AKind: TTokenKind): Boolean;
    function Match(AKind: TTokenKind): Boolean;
    function Expect(AKind: TTokenKind; const AWhat: string = ''): TToken;
    function IsTypeStart: Boolean;
    function FindTypedef(const AName: string; out ACType: TCType): Boolean;
    procedure AddTypedef(const AName: string; const ACType: TCType);
    function FindIntegerConstant(const AName: string; out AValue: Int64): Boolean;
    procedure AddIntegerConstant(const AName: string; AValue: Int64;
      const APos: TSourcePos);
    function FindDeclaredType(const AName: string; out ACType: TCType;
      out AIsFunction: Boolean): Boolean;
    procedure AddDeclaredType(const AName: string; const ACType: TCType;
      AScopeDepth: LongInt; AIsFunction: Boolean = False);
    procedure EnterScope;
    procedure LeaveScope;
    function InferParserExpressionType(E: TExpr; out ACType: TCType): Boolean;
    function EvaluateParserIntegerConstant(E: TExpr; out AValue: Int64): Boolean;
    function FindStruct(const AName: string; out AInfo: PStructMembers): Boolean;
    function ParseDeclarator(var CType: TCType; out AName: string): Boolean;
    function ParseTypeofType: TCType;
    function ParseType(out AWasTypedef: Boolean): TCType;
    procedure ParsePointerTail(var CType: TCType);
    function ParsePrimary: TExpr;
    function ParseBuiltinOffsetof: TExpr;
    function ParseGenericSelection: TExpr;
    function ParsePostfix: TExpr;
    function ParseUnary: TExpr;
    function ParseMultiplicative: TExpr;
    function ParseAdditive: TExpr;
    function ParseShift: TExpr;
    function ParseRelational: TExpr;
    function ParseEquality: TExpr;
    function ParseBitAnd: TExpr;
    function ParseBitXor: TExpr;
    function ParseBitOr: TExpr;
    function ParseLogicalAnd: TExpr;
    function ParseLogicalOr: TExpr;
    function ParseConditional: TExpr;
    function ParseAssignment: TExpr;
    function ParseExpression: TExpr;
    function ParseDeclarationStatement(AConsumeSemicolon: Boolean): TStmt;
    function ParseStaticAssertion: TStmt;
    function ParseAsmStatement: TStmt;
    function ParseStatement: TStmt;
    function ParseBlock: TStmt;
    function ParseStructBody(AIsUnion: Boolean): PStructMembers;
    function ParseEnumBody: TEnumConstantArray;
    procedure ParseExternal(AProgram: TProgram);
    function NewOwnedStructInfo: PStructMembers;
    function NewOwnedMemberType: PCType;
    function NewOwnedFunctionParameterList: PFunctionParameterList;
    procedure TransferTypeStorage(AProgram: TProgram);
  public
    constructor Create(const ATokens: TTokenArray);
    destructor Destroy; override;
    function ParseProgram: TProgram;
  end;

implementation

function IsIdentStart(C: Char): Boolean; inline;
begin
  Result := (C = '_') or (C in ['A'..'Z']) or (C in ['a'..'z']);
end;

function IsIdentPart(C: Char): Boolean; inline;
begin
  Result := IsIdentStart(C) or (C in ['0'..'9']);
end;

function StripPreprocessingComments(const ALine: string;
  var AInBlockComment: Boolean): string;
var
  I: LongInt;
  C, Quote: Char;
begin
  Result := '';
  I := 1;
  Quote := #0;
  while I <= Length(ALine) do
  begin
    C := ALine[I];
    if AInBlockComment then
    begin
      if (C = '*') and (I < Length(ALine)) and (ALine[I + 1] = '/') then
      begin
        AInBlockComment := False;
        Inc(I, 2);
      end
      else
        Inc(I);
      Continue;
    end;
    if Quote <> #0 then
    begin
      Result := Result + C;
      if (C = '\') and (I < Length(ALine)) then
      begin
        Inc(I);
        Result := Result + ALine[I];
      end
      else if C = Quote then
        Quote := #0;
      Inc(I);
      Continue;
    end;
    if (C = '''') or (C = '"') then
    begin
      Quote := C;
      Result := Result + C;
      Inc(I);
      Continue;
    end;
    if (C = '/') and (I < Length(ALine)) then
    begin
      if ALine[I + 1] = '/' then Break;
      if ALine[I + 1] = '*' then
      begin
        if (Result = '') or not (Result[Length(Result)] in [' ', #9]) then
          Result := Result + ' ';
        AInBlockComment := True;
        Inc(I, 2);
        Continue;
      end;
    end;
    Result := Result + C;
    Inc(I);
  end;
end;



constructor TPreprocessor.Create(const AIncludePaths, ADefines,
  AUndefines: array of string; AStandard: TCStandard);
var
  I, P: LongInt;
  Name, Value: string;
begin
  inherited Create;
  SetLength(FIncludePaths, Length(AIncludePaths));
  for I := 0 to High(AIncludePaths) do
    FIncludePaths[I] := AIncludePaths[I];
  FIncludeDepth := 0;
  SetLength(FDependencies, 0);
  SetLength(FPragmaOnceFiles, 0);
  SetLength(FLinkLibraries, 0);
  DefineMacro('__has_include', '__has_include');




  for I := 0 to High(ADefines) do
  begin
    P := Pos('=', ADefines[I]);
    if P > 0 then
    begin
      Name := Copy(ADefines[I], 1, P - 1);
      Value := Copy(ADefines[I], P + 1, MaxInt);
    end
    else
    begin
      Name := ADefines[I];
      Value := '1';
    end;
    DefineMacro(Trim(Name), Value);
  end;
  for I := 0 to High(AUndefines) do
    UndefineMacro(Trim(AUndefines[I]));
end;

procedure TPreprocessor.AddDependency(const AFileName: string);
var
  I, N: LongInt;
  Expanded: string;
begin
  Expanded := ExpandFileName(AFileName);
  for I := 0 to High(FDependencies) do
    if FDependencies[I] = Expanded then Exit;
  N := Length(FDependencies);
  SetLength(FDependencies, N + 1);
  FDependencies[N] := Expanded;
end;

function TPreprocessor.Dependencies: rcc_types.TStringArray;
var
  I: LongInt;
begin
  Result := nil;
  SetLength(Result, Length(FDependencies));
  for I := 0 to High(FDependencies) do Result[I] := FDependencies[I];
end;

function TPreprocessor.LinkLibraries: rcc_types.TStringArray;
var
  I: LongInt;
begin
  Result := nil;
  SetLength(Result, Length(FLinkLibraries));
  for I := 0 to High(FLinkLibraries) do Result[I] := FLinkLibraries[I];
end;

function TPreprocessor.IsPragmaOnceFile(const AFileName: string): Boolean;
var
  I: LongInt;
  Expanded: string;
begin
  Expanded := ExpandFileName(AFileName);
  for I := 0 to High(FPragmaOnceFiles) do
    if FPragmaOnceFiles[I] = Expanded then Exit(True);
  Result := False;
end;

procedure TPreprocessor.AddPragmaOnceFile(const AFileName: string);
var
  N: LongInt;
begin
  if IsPragmaOnceFile(AFileName) then Exit;
  N := Length(FPragmaOnceFiles);
  SetLength(FPragmaOnceFiles, N + 1);
  FPragmaOnceFiles[N] := ExpandFileName(AFileName);
end;

procedure TPreprocessor.AddLinkLibrary(const AName, AFileName: string;
  ALine: LongInt);
var
  I, N: LongInt;
begin
  if AName = '' then
    raise ERCCError.CreateFmt(
      '%s:%d: error: #pragma rcc link requires a library name',
      [AFileName, ALine]);
  if not (AName[1] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
    raise ERCCError.CreateFmt(
      '%s:%d: error: invalid library name in #pragma rcc link',
      [AFileName, ALine]);
  for I := 1 to Length(AName) do
    if not (AName[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '+', '.', '-']) then
      raise ERCCError.CreateFmt(
        '%s:%d: error: invalid library name in #pragma rcc link',
        [AFileName, ALine]);
  for I := 0 to High(FLinkLibraries) do
    if FLinkLibraries[I] = AName then Exit;
  N := Length(FLinkLibraries);
  SetLength(FLinkLibraries, N + 1);
  FLinkLibraries[N] := AName;
end;

procedure TPreprocessor.ProcessPragma(const AText, AFileName: string;
  ALine: LongInt);
var
  P: LongInt;
  Text, NamespaceName, CommandName, LibraryName: string;
begin
  Text := Trim(AText);
  if LowerCase(Text) = 'once' then
  begin
    AddPragmaOnceFile(AFileName);
    Exit;
  end;

  P := 1;
  while (P <= Length(Text)) and IsIdentPart(Text[P]) do Inc(P);
  NamespaceName := LowerCase(Copy(Text, 1, P - 1));
  if NamespaceName <> 'rcc' then Exit;
  Text := TrimLeft(Copy(Text, P, MaxInt));
  P := 1;
  while (P <= Length(Text)) and IsIdentPart(Text[P]) do Inc(P);
  CommandName := LowerCase(Copy(Text, 1, P - 1));
  Text := Trim(Copy(Text, P, MaxInt));
  if CommandName <> 'link' then
    raise ERCCError.CreateFmt('%s:%d: error: unsupported #pragma rcc command',
      [AFileName, ALine]);

  LibraryName := Text;
  if (Length(LibraryName) >= 2) and (LibraryName[1] = '"') and
    (LibraryName[Length(LibraryName)] = '"') then
    LibraryName := Copy(LibraryName, 2, Length(LibraryName) - 2);
  AddLinkLibrary(LibraryName, AFileName, ALine);
end;

procedure TPreprocessor.MarkMacroIndexDirty;
begin
  FMacroIndexDirty := True;
end;

procedure TPreprocessor.RebuildMacroIndex;
var
  N, I: LongInt;

  procedure QSort(ALo, AHi: LongInt);
  var
    I, J, Pivot, T: LongInt;
    PN: string;
  begin
    I := ALo;
    J := AHi;
    Pivot := FMacroIndex[(ALo + AHi) shr 1];
    PN := FMacros[Pivot].Name;
    repeat
      while FMacros[FMacroIndex[I]].Name < PN do Inc(I);
      while FMacros[FMacroIndex[J]].Name > PN do Dec(J);
      if I <= J then
      begin
        T := FMacroIndex[I];
        FMacroIndex[I] := FMacroIndex[J];
        FMacroIndex[J] := T;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if ALo < J then QSort(ALo, J);
    if I < AHi then QSort(I, AHi);
  end;

begin
  N := Length(FMacros);
  SetLength(FMacroIndex, N);
  for I := 0 to N - 1 do FMacroIndex[I] := I;
  if N > 1 then QSort(0, N - 1);
  FMacroIndexDirty := False;
end;

function TPreprocessor.FindMacro(const AName: string): LongInt;
var
  Lo, Hi, Mid, Idx: LongInt;
begin
  if FMacroIndexDirty then RebuildMacroIndex;
  Lo := 0;
  Hi := High(FMacroIndex);
  while Lo <= Hi do
  begin
    Mid := (Lo + Hi) shr 1;
    Idx := FMacroIndex[Mid];
    if FMacros[Idx].Name = AName then Exit(Idx);
    if FMacros[Idx].Name < AName then Lo := Mid + 1
    else Hi := Mid - 1;
  end;
  Result := -1;
end;

procedure TPreprocessor.DefineMacro(const AName, AValue: string);
var
  I, N: LongInt;
begin
  if AName = '' then Exit;
  I := FindMacro(AName);
  if I >= 0 then
  begin
    FMacros[I].Value := AValue;
    FMacros[I].IsFunctionLike := False;
    SetLength(FMacros[I].ParamNames, 0);
    FMacros[I].HasVariadic := False;
    Exit;
  end;
  N := Length(FMacros);
  SetLength(FMacros, N + 1);
  FMacros[N].Name := AName;
  FMacros[N].Value := AValue;
  FMacros[N].IsFunctionLike := False;
  SetLength(FMacros[N].ParamNames, 0);
  FMacros[N].HasVariadic := False;
  MarkMacroIndexDirty;
end;

procedure TPreprocessor.DefineFunctionMacro(const AName, AValue: string;
  const AParamNames: array of string; AVariadic: Boolean);
var
  MacroIndex, ParamIndex, N: LongInt;
begin
  if AName = '' then Exit;
  MacroIndex := FindMacro(AName);
  if MacroIndex < 0 then
  begin
    N := Length(FMacros);
    SetLength(FMacros, N + 1);
    MacroIndex := N;
    FMacros[MacroIndex].Name := AName;
    MarkMacroIndexDirty;
  end;
  FMacros[MacroIndex].Value := AValue;
  FMacros[MacroIndex].IsFunctionLike := True;
  N := Length(AParamNames);
  SetLength(FMacros[MacroIndex].ParamNames, N);
  for ParamIndex := 0 to N - 1 do
    FMacros[MacroIndex].ParamNames[ParamIndex] := AParamNames[ParamIndex];
  FMacros[MacroIndex].HasVariadic := AVariadic;
end;

procedure TPreprocessor.UndefineMacro(const AName: string);
var
  I, J: LongInt;
begin
  I := FindMacro(AName);
  if I < 0 then Exit;
  for J := I to High(FMacros) - 1 do
    FMacros[J] := FMacros[J + 1];
  SetLength(FMacros, Length(FMacros) - 1);
  MarkMacroIndexDirty;
end;

function TPreprocessor.ExpandMacrosOnce(const ALine: string): string;
var
  I, J, K, StartPos, MacroIndex, Depth, ArgStart: LongInt;
  C, Quote: Char;
  Name, Replacement, ArgText: string;
  Args: rcc_types.TStringArray;
  Macro: TMacro;

  procedure AddArgument(const AValue: string);
  var
    N: LongInt;
  begin
    N := Length(Args);
    SetLength(Args, N + 1);
    Args[N] := Trim(AValue);
  end;

  function ParamIndex(const AName: string): LongInt;
  var
    P: LongInt;
  begin
    for P := 0 to High(Macro.ParamNames) do
      if Macro.ParamNames[P] = AName then Exit(P);
    Result := -1;
  end;

  function EscapedQuoted(const AValue: string): string;
  var
    P: LongInt;
  begin
    Result := '"';
    for P := 1 to Length(AValue) do
    begin
      if AValue[P] in ['"', '\'] then Result := Result + '\';
      Result := Result + AValue[P];
    end;
    Result := Result + '"';
  end;

  function ArgumentForParam(AParam: LongInt; AExpand: Boolean): string;
  var
    P: LongInt;
  begin
    Result := '';
    if Macro.HasVariadic and (AParam = High(Macro.ParamNames)) then
    begin
      for P := AParam to High(Args) do
      begin
        if P > AParam then Result := Result + ', ';
        Result := Result + Args[P];
      end;
    end
    else if AParam <= High(Args) then
      Result := Args[AParam];



    if AExpand and (Result <> '') then
      Result := ExpandMacros(Result);
  end;

  function SubstituteParameters(const ATemplate: string): string;
  var
    P, Q, Scan, TokenStart, Param: LongInt;
    Token: string;
    Stringify, PasteNext, PasteAfter: Boolean;
  begin
    Result := '';
    P := 1;
    PasteNext := False;
    while P <= Length(ATemplate) do
    begin
      if (ATemplate[P] = '#') and (P < Length(ATemplate)) and
        (ATemplate[P + 1] = '#') then
      begin
        Inc(P, 2);
        while (P <= Length(ATemplate)) and (ATemplate[P] in [' ', #9]) do Inc(P);
        while (Length(Result) > 0) and (Result[Length(Result)] in [' ', #9]) do
          Delete(Result, Length(Result), 1);
        PasteNext := True;
        Continue;
      end;
      Stringify := False;
      if ATemplate[P] = '#' then
      begin
        Q := P + 1;
        while (Q <= Length(ATemplate)) and (ATemplate[Q] in [' ', #9]) do Inc(Q);
        if (Q <= Length(ATemplate)) and IsIdentStart(ATemplate[Q]) then
        begin
          Stringify := True;
          P := Q;
        end;
      end;
      if IsIdentStart(ATemplate[P]) then
      begin
        TokenStart := P;
        Inc(P);
        while (P <= Length(ATemplate)) and IsIdentPart(ATemplate[P]) do Inc(P);
        Token := Copy(ATemplate, TokenStart, P - TokenStart);
        Param := ParamIndex(Token);

        Scan := P;
        while (Scan <= Length(ATemplate)) and
          (ATemplate[Scan] in [' ', #9]) do Inc(Scan);
        PasteAfter := (Scan < Length(ATemplate)) and
          (ATemplate[Scan] = '#') and (ATemplate[Scan + 1] = '#');

        if Param >= 0 then
        begin
          if Stringify then
            Result := Result + EscapedQuoted(ArgumentForParam(Param, False))
          else
            Result := Result + ArgumentForParam(Param,
              not (PasteNext or PasteAfter));
        end
        else
        begin
          if Stringify then Result := Result + '#';
          Result := Result + Token;
        end;
        PasteNext := False;
        Continue;
      end;
      Result := Result + ATemplate[P];
      if not (ATemplate[P] in [' ', #9]) then PasteNext := False;
      Inc(P);
    end;
  end;

begin
  Result := '';
  I := 1;
  Quote := #0;
  while I <= Length(ALine) do
  begin
    C := ALine[I];
    if Quote <> #0 then
    begin
      Result := Result + C;
      if (C = '\') and (I < Length(ALine)) then
      begin
        Inc(I);
        Result := Result + ALine[I];
      end
      else if C = Quote then
        Quote := #0;
      Inc(I);
      Continue;
    end;
    if (C = '''') or (C = '"') then
    begin
      Quote := C;
      Result := Result + C;
      Inc(I);
      Continue;
    end;
    if IsIdentStart(C) then
    begin
      StartPos := I;
      Inc(I);
      while (I <= Length(ALine)) and IsIdentPart(ALine[I]) do Inc(I);
      Name := Copy(ALine, StartPos, I - StartPos);
      MacroIndex := FindMacro(Name);
      if MacroIndex < 0 then
      begin
        Result := Result + Name;
        Continue;
      end;
      Macro := FMacros[MacroIndex];
      if not Macro.IsFunctionLike then
      begin
        Result := Result + Macro.Value;
        Continue;
      end;

      J := I;
      while (J <= Length(ALine)) and (ALine[J] in [' ', #9]) do Inc(J);
      if (J > Length(ALine)) or (ALine[J] <> '(') then
      begin
        Result := Result + Name;
        Continue;
      end;

      SetLength(Args, 0);
      Depth := 1;
      K := J + 1;
      ArgStart := K;
      Quote := #0;
      while (K <= Length(ALine)) and (Depth > 0) do
      begin
        C := ALine[K];
        if Quote <> #0 then
        begin
          if (C = '\') and (K < Length(ALine)) then Inc(K)
          else if C = Quote then Quote := #0;
        end
        else if (C = '''') or (C = '"') then Quote := C
        else if C = '(' then Inc(Depth)
        else if C = ')' then
        begin
          Dec(Depth);
          if Depth = 0 then
          begin
            ArgText := Copy(ALine, ArgStart, K - ArgStart);
            if (Trim(ArgText) <> '') or (Length(Args) > 0) then AddArgument(ArgText);
            Break;
          end;
        end
        else if (C = ',') and (Depth = 1) then
        begin
          AddArgument(Copy(ALine, ArgStart, K - ArgStart));
          ArgStart := K + 1;
        end;
        Inc(K);
      end;
      Quote := #0;
      if Depth <> 0 then
      begin
        FMacroNeedsContinuation := True;
        Result := Result + Name;
        I := J;
        Continue;
      end;
      if (not Macro.HasVariadic) and (Length(Args) <> Length(Macro.ParamNames)) then
        raise ERCCError.CreateFmt('error: macro %s expects %d arguments, got %d',
          [Name, Length(Macro.ParamNames), Length(Args)]);
      if Macro.HasVariadic and
        (Length(Args) < Length(Macro.ParamNames) - 1) then
        raise ERCCError.CreateFmt('error: macro %s expects at least %d arguments, got %d',
          [Name, Length(Macro.ParamNames) - 1, Length(Args)]);
      Replacement := SubstituteParameters(Macro.Value);
      Result := Result + Replacement;
      I := K + 1;
      Continue;
    end;
    Result := Result + C;
    Inc(I);
  end;
end;

function TPreprocessor.ExpandMacros(const ALine: string): string;
var
  I: LongInt;
  Next: string;
begin
  FMacroNeedsContinuation := False;
  Result := ALine;
  for I := 1 to 64 do
  begin
    Next := ExpandMacrosOnce(Result);
    if Next = Result then Exit;
    Result := Next;
  end;
end;

function TPreprocessor.IsActive: Boolean;
begin
  if Length(FConditions) = 0 then
    Exit(True);
  Result := FConditions[High(FConditions)].ParentActive and
    FConditions[High(FConditions)].ThisActive;
end;

function TPreprocessor.EvaluateCondition(const AText,
  ACurrentDir: string): Boolean;

  function StripOuterParens(const AValue: string): string;
  var
    I, Depth: LongInt;
    Balanced: Boolean;
  begin
    Result := Trim(AValue);
    while (Length(Result) >= 2) and (Result[1] = '(') and
      (Result[Length(Result)] = ')') do
    begin
      Depth := 0;
      Balanced := True;
      for I := 1 to Length(Result) do
      begin
        if Result[I] = '(' then Inc(Depth)
        else if Result[I] = ')' then Dec(Depth);
        if (Depth = 0) and (I < Length(Result)) then
        begin
          Balanced := False;
          Break;
        end;
        if Depth < 0 then
        begin
          Balanced := False;
          Break;
        end;
      end;
      if not Balanced or (Depth <> 0) then Break;
      Result := Trim(Copy(Result, 2, Length(Result) - 2));
    end;
  end;

  function FindTopLevelOperator(const AValue, AOperator: string): LongInt;
  var
    I, Depth: LongInt;
  begin
    Depth := 0;
    I := 1;
    while I <= Length(AValue) - Length(AOperator) + 1 do
    begin
      if AValue[I] = '(' then Inc(Depth)
      else if AValue[I] = ')' then Dec(Depth)
      else if (Depth = 0) and
        (Copy(AValue, I, Length(AOperator)) = AOperator) then
        Exit(I);
      Inc(I);
    end;
    Result := 0;
  end;

  function FindTopLevelOperatorRight(const AValue,
    AOperator: string): LongInt;
  var
    I, Depth: LongInt;
    Quote: Char;
  begin
    Result := 0;
    Depth := 0;
    Quote := #0;
    I := 1;
    while I <= Length(AValue) - Length(AOperator) + 1 do
    begin
      if Quote <> #0 then
      begin
        if (AValue[I] = '\') and (I < Length(AValue)) then Inc(I)
        else if AValue[I] = Quote then Quote := #0;
      end
      else if (AValue[I] = '''') or (AValue[I] = '"') then
        Quote := AValue[I]
      else if AValue[I] = '(' then
        Inc(Depth)
      else if AValue[I] = ')' then
        Dec(Depth)
      else if (Depth = 0) and
        (Copy(AValue, I, Length(AOperator)) = AOperator) then
        Result := I;
      Inc(I);
    end;
  end;

  function EvalInteger(const AValue: string; out AInteger: Int64): Boolean;
  var
    S, LeftText, RightText: string;
    P, I, Digit: LongInt;
    LeftValue, RightValue: Int64;
    Bits: QWord;
  begin
    S := StripOuterParens(ExpandMacros(StripOuterParens(AValue)));

    P := FindTopLevelOperatorRight(S, '|');
    if (P > 0) and
       ((P = 1) or (S[P - 1] <> '|')) and
       ((P = Length(S)) or (S[P + 1] <> '|')) then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 1, MaxInt);
      Result := EvalInteger(LeftText, LeftValue) and
        EvalInteger(RightText, RightValue);
      if Result then AInteger := Int64(QWord(LeftValue) or QWord(RightValue));
      Exit;
    end;
    P := FindTopLevelOperatorRight(S, '^');
    if P > 0 then
    begin
      Result := EvalInteger(Copy(S, 1, P - 1), LeftValue) and
        EvalInteger(Copy(S, P + 1, MaxInt), RightValue);
      if Result then AInteger := Int64(QWord(LeftValue) xor QWord(RightValue));
      Exit;
    end;
    P := FindTopLevelOperatorRight(S, '&');
    if (P > 0) and
       ((P = 1) or (S[P - 1] <> '&')) and
       ((P = Length(S)) or (S[P + 1] <> '&')) then
    begin
      Result := EvalInteger(Copy(S, 1, P - 1), LeftValue) and
        EvalInteger(Copy(S, P + 1, MaxInt), RightValue);
      if Result then AInteger := Int64(QWord(LeftValue) and QWord(RightValue));
      Exit;
    end;
    P := FindTopLevelOperatorRight(S, '<<');
    if P = 0 then P := FindTopLevelOperatorRight(S, '>>');
    if P > 0 then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 2, MaxInt);
      Result := EvalInteger(LeftText, LeftValue) and
        EvalInteger(RightText, RightValue) and
        (RightValue >= 0) and (RightValue < 64);
      if Result then
      begin
        if Copy(S, P, 2) = '<<' then
          AInteger := Int64(QWord(LeftValue) shl RightValue)
        else
          AInteger := LeftValue shr RightValue;
      end;
      Exit;
    end;
    P := FindTopLevelOperatorRight(S, '+');
    if P = 0 then P := FindTopLevelOperatorRight(S, '-');
    if P > 1 then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 1, MaxInt);
      Result := EvalInteger(LeftText, LeftValue) and
        EvalInteger(RightText, RightValue);
      if Result then
      begin
        if S[P] = '+' then AInteger := LeftValue + RightValue
        else AInteger := LeftValue - RightValue;
      end;
      Exit;
    end;
    P := FindTopLevelOperatorRight(S, '*');
    if P = 0 then P := FindTopLevelOperatorRight(S, '/');
    if P = 0 then P := FindTopLevelOperatorRight(S, '%');
    if P > 0 then
    begin
      Result := EvalInteger(Copy(S, 1, P - 1), LeftValue) and
        EvalInteger(Copy(S, P + 1, MaxInt), RightValue);
      if Result then
      begin
        case S[P] of
          '*': AInteger := LeftValue * RightValue;
          '/':
            begin
              if RightValue = 0 then Exit(False);
              AInteger := LeftValue div RightValue;
            end;
          '%':
            begin
              if RightValue = 0 then Exit(False);
              AInteger := LeftValue mod RightValue;
            end;
        end;
      end;
      Exit;
    end;
    if (S <> '') and (S[1] in ['+', '-', '~']) then
    begin
      Result := EvalInteger(Copy(S, 2, MaxInt), RightValue);
      if not Result then Exit;
      case S[1] of
        '+': AInteger := RightValue;
        '-': AInteger := -RightValue;
        '~': AInteger := Int64(not QWord(RightValue));
      end;
      Exit(True);
    end;
    while (Length(S) > 0) and (S[Length(S)] in ['u', 'U', 'l', 'L']) do
      Delete(S, Length(S), 1);
    S := Trim(S);
    if (Length(S) > 2) and (S[1] = '0') and (S[2] in ['x', 'X']) then
    begin
      Result := TryStrToQWord('$' + Copy(S, 3, MaxInt), Bits);
      if Result then AInteger := Int64(Bits);
      Exit;
    end;
    if (Length(S) > 1) and (S[1] = '0') then
    begin
      Bits := 0;
      for I := 2 to Length(S) do
      begin
        if not (S[I] in ['0'..'7']) then Exit(False);
        Digit := Ord(S[I]) - Ord('0');
        Bits := Bits * 8 + QWord(Digit);
      end;
      AInteger := Int64(Bits);
      Exit(True);
    end;
    Result := TryStrToInt64(S, AInteger);
    if not Result and (S <> '') and IsIdentStart(S[1]) then
    begin
      I := 2;
      while (I <= Length(S)) and IsIdentPart(S[I]) do Inc(I);
      if I > Length(S) then
      begin
        AInteger := 0;
        Exit(True);
      end;
    end;
  end;

  function Eval(const AValue: string): Boolean;
  var
    S, Name, LeftText, RightText, HeaderOperand, HeaderName: string;
    P, Q: LongInt;
    V, LeftValue, RightValue: Int64;
    Angled: Boolean;
  begin
    S := StripOuterParens(AValue);
    P := FindTopLevelOperator(S, '||');
    if P > 0 then
      Exit(Eval(Copy(S, 1, P - 1)) or
        Eval(Copy(S, P + 2, MaxInt)));
    P := FindTopLevelOperator(S, '&&');
    if P > 0 then
      Exit(Eval(Copy(S, 1, P - 1)) and
        Eval(Copy(S, P + 2, MaxInt)));

    P := FindTopLevelOperator(S, '==');
    if P > 0 then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 2, MaxInt);
      if EvalInteger(LeftText, LeftValue) and EvalInteger(RightText, RightValue) then
        Exit(LeftValue = RightValue);
    end;
    P := FindTopLevelOperator(S, '!=');
    if P > 0 then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 2, MaxInt);
      if EvalInteger(LeftText, LeftValue) and EvalInteger(RightText, RightValue) then
        Exit(LeftValue <> RightValue);
    end;
    P := FindTopLevelOperator(S, '>=');
    if P > 0 then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 2, MaxInt);
      if EvalInteger(LeftText, LeftValue) and EvalInteger(RightText, RightValue) then
        Exit(LeftValue >= RightValue);
    end;
    P := FindTopLevelOperator(S, '<=');
    if P > 0 then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 2, MaxInt);
      if EvalInteger(LeftText, LeftValue) and EvalInteger(RightText, RightValue) then
        Exit(LeftValue <= RightValue);
    end;
    P := FindTopLevelOperator(S, '>');
    if P > 0 then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 1, MaxInt);
      if EvalInteger(LeftText, LeftValue) and EvalInteger(RightText, RightValue) then
        Exit(LeftValue > RightValue);
    end;
    P := FindTopLevelOperator(S, '<');
    if P > 0 then
    begin
      LeftText := Copy(S, 1, P - 1);
      RightText := Copy(S, P + 1, MaxInt);
      if EvalInteger(LeftText, LeftValue) and EvalInteger(RightText, RightValue) then
        Exit(LeftValue < RightValue);
    end;
    if (S <> '') and (S[1] = '!') then
      Exit(not Eval(Copy(S, 2, MaxInt)));
    if Pos('defined', S) = 1 then
    begin
      S := Trim(Copy(S, 8, MaxInt));
      if (S <> '') and (S[1] = '(') then
      begin
        Q := Pos(')', S);
        if Q = 0 then Exit(False);
        Name := Trim(Copy(S, 2, Q - 2));
      end
      else
        Name := Trim(S);
      Exit(FindMacro(Name) >= 0);
    end;
    if Pos('__has_include', S) = 1 then
    begin
      P := Pos('(', S);
      Q := Length(S);
      if (P = 0) or (Q <= P) or (S[Q] <> ')') then Exit(False);
      HeaderOperand := Trim(Copy(S, P + 1, Q - P - 1));
      if (HeaderOperand = '') or
         not (HeaderOperand[1] in ['<', '"']) then
        HeaderOperand := Trim(ExpandMacros(HeaderOperand));
      Angled := (HeaderOperand <> '') and (HeaderOperand[1] = '<');
      if Angled then
      begin
        Q := Pos('>', HeaderOperand);
        if Q = 0 then Exit(False);
        HeaderName := Copy(HeaderOperand, 2, Q - 2);
      end
      else if (HeaderOperand <> '') and (HeaderOperand[1] = '"') then
      begin
        Q := PosEx('"', HeaderOperand, 2);
        if Q = 0 then Exit(False);
        HeaderName := Copy(HeaderOperand, 2, Q - 2);
      end
      else
        Exit(False);
      Exit(ResolveInclude(HeaderName, ACurrentDir, Angled) <> '');
    end;
    Result := EvalInteger(S, V) and (V <> 0);
  end;

begin
  Result := Eval(AText);
end;

function TPreprocessor.IsBuiltinHeader(const AName: string): Boolean;
const
  Headers: array[0..15] of string = (
    'stdio.h', 'stdlib.h', 'stdint.h', 'stddef.h', 'stdbool.h',
    'string.h', 'limits.h', 'assert.h', 'errno.h', 'ctype.h',
    'inttypes.h', 'unistd.h', 'stdarg.h', 'float.h', 'stdalign.h',
    'time.h'
  );
var
  I: LongInt;
begin
  for I := Low(Headers) to High(Headers) do
    if Headers[I] = AName then Exit(True);
  Result := False;
end;

function TPreprocessor.BuiltinHeaderText(const AName: string): string;
begin
  Result := '';
  if AName = 'stdio.h' then
  begin
    DefineMacro('EOF', '(-1)');
    DefineMacro('NULL', '0');
    DefineMacro('BUFSIZ', '8192');
    Result :=
      'typedef unsigned long size_t;' + LineEnding +
      'typedef long ssize_t;' + LineEnding +
      'typedef unsigned long FILE;' + LineEnding +
      'extern FILE *stdin;' + LineEnding +
      'extern FILE *stdout;' + LineEnding +
      'extern FILE *stderr;' + LineEnding +
      'int puts(const char *s);' + LineEnding +
      'int putchar(int c);' + LineEnding +
      'int getchar(void);' + LineEnding +
      'int printf(const char *fmt, ...);' + LineEnding +
      'int sprintf(char *buf, const char *fmt, ...);' + LineEnding +
      'int snprintf(char *buf, unsigned long n, const char *fmt, ...);' + LineEnding;
  end
  else if AName = 'stdlib.h' then
  begin
    DefineMacro('NULL', '0');
    DefineMacro('EXIT_SUCCESS', '0');
    DefineMacro('EXIT_FAILURE', '1');
    DefineMacro('RAND_MAX', '32767');
    Result :=
      'typedef unsigned long size_t;' + LineEnding +
      'void *malloc(size_t size);' + LineEnding +
      'void *calloc(size_t nmemb, size_t size);' + LineEnding +
      'void *realloc(void *ptr, size_t size);' + LineEnding +
      'void free(void *ptr);' + LineEnding +
      'void exit(int status);' + LineEnding +
      'void _Exit(int status);' + LineEnding +
      'void abort(void);' + LineEnding +
      'int atoi(const char *nptr);' + LineEnding +
      'long strtol(const char *nptr, char **endptr, int base);' + LineEnding +
      'int abs(int j);' + LineEnding +
      'long labs(long j);' + LineEnding;
  end
  else if AName = 'stdint.h' then
    Result :=
      'typedef signed char int8_t;' + LineEnding +
      'typedef unsigned char uint8_t;' + LineEnding +
      'typedef short int16_t;' + LineEnding +
      'typedef unsigned short uint16_t;' + LineEnding +
      'typedef int int32_t;' + LineEnding +
      'typedef unsigned int uint32_t;' + LineEnding +
      'typedef long int64_t;' + LineEnding +
      'typedef unsigned long uint64_t;' + LineEnding +
      'typedef long intptr_t;' + LineEnding +
      'typedef unsigned long uintptr_t;' + LineEnding
  else if AName = 'stddef.h' then
  begin
    DefineMacro('NULL', '0');
    Result :=
      'typedef unsigned long size_t;' + LineEnding +
      'typedef long ptrdiff_t;' + LineEnding +
      'typedef long double max_align_t;' + LineEnding +
      '#define offsetof(type, member) __builtin_offsetof(type, member)' + LineEnding;
  end
  else if AName = 'stdbool.h' then
  begin
    DefineMacro('bool', '_Bool');
    DefineMacro('true', '1');
    DefineMacro('false', '0');
    DefineMacro('__bool_true_false_are_defined', '1');
  end
  else if AName = 'string.h' then
    Result :=
      'typedef unsigned long size_t;' + LineEnding +
      'size_t strlen(const char *s);' + LineEnding +
      'void *memcpy(void *dst, const void *src, size_t n);' + LineEnding +
      'void *memmove(void *dst, const void *src, size_t n);' + LineEnding +
      'void *memset(void *dst, int value, size_t n);' + LineEnding +
      'int memcmp(const void *s1, const void *s2, size_t n);' + LineEnding +
      'char *strcpy(char *dst, const char *src);' + LineEnding +
      'char *strncpy(char *dst, const char *src, size_t n);' + LineEnding +
      'int strcmp(const char *s1, const char *s2);' + LineEnding +
      'int strncmp(const char *s1, const char *s2, size_t n);' + LineEnding +
      'char *strchr(const char *s, int c);' + LineEnding +
      'char *strrchr(const char *s, int c);' + LineEnding
  else if AName = 'limits.h' then
  begin
    DefineMacro('CHAR_BIT', '8');
    DefineMacro('SCHAR_MIN', '(-128)');
    DefineMacro('SCHAR_MAX', '127');
    DefineMacro('UCHAR_MAX', '255');
    DefineMacro('CHAR_MIN', '0');
    DefineMacro('CHAR_MAX', '255');
    DefineMacro('SHRT_MIN', '(-32768)');
    DefineMacro('SHRT_MAX', '32767');
    DefineMacro('USHRT_MAX', '65535');
    DefineMacro('INT_MIN', '(-2147483647-1)');
    DefineMacro('INT_MAX', '2147483647');
    DefineMacro('UINT_MAX', '4294967295U');
    DefineMacro('LONG_MIN', '(-9223372036854775807L-1)');
    DefineMacro('LONG_MAX', '9223372036854775807L');
    DefineMacro('ULONG_MAX', '18446744073709551615UL');
    DefineMacro('LLONG_MIN', '(-9223372036854775807LL-1)');
    DefineMacro('LLONG_MAX', '9223372036854775807LL');
    DefineMacro('ULLONG_MAX', '18446744073709551615ULL');
  end
  else if AName = 'assert.h' then
    Result := 'void assert(int condition);' + LineEnding
  else if AName = 'unistd.h' then
    Result :=
      'typedef long ssize_t;' + LineEnding +
      'typedef unsigned long size_t;' + LineEnding +
      'ssize_t write(int fd, const void *buffer, size_t count);' + LineEnding +
      'ssize_t read(int fd, void *buffer, size_t count);' + LineEnding +
      'int close(int fd);' + LineEnding
  else if AName = 'inttypes.h' then
    Result := BuiltinHeaderText('stdint.h')
  else if AName = 'ctype.h' then
    Result :=
      'int isalnum(int c);' + LineEnding +
      'int isalpha(int c);' + LineEnding +
      'int isdigit(int c);' + LineEnding +
      'int islower(int c);' + LineEnding +
      'int isupper(int c);' + LineEnding +
      'int isspace(int c);' + LineEnding +
      'int isxdigit(int c);' + LineEnding +
      'int isprint(int c);' + LineEnding +
      'int isgraph(int c);' + LineEnding +
      'int iscntrl(int c);' + LineEnding +
      'int ispunct(int c);' + LineEnding +
      'int tolower(int c);' + LineEnding +
      'int toupper(int c);' + LineEnding
  else if AName = 'errno.h' then
  begin
    DefineMacro('errno', '(*__errno_location())');
    DefineMacro('EDOM', '33');
    DefineMacro('ERANGE', '34');
    DefineMacro('EINVAL', '22');
    DefineMacro('ENOMEM', '12');
    Result := 'int *__errno_location(void);' + LineEnding;
  end
  else if AName = 'stdarg.h' then
    Result :=
      'typedef __builtin_va_list va_list;' + LineEnding +
      '#define va_start(v, l) __builtin_va_start(v, l)' + LineEnding +
      '#define va_arg(v, t) __builtin_va_arg(v, t)' + LineEnding +
      '#define va_copy(d, s) __builtin_va_copy(d, s)' + LineEnding +
      '#define va_end(v) __builtin_va_end(v)' + LineEnding
  else if AName = 'float.h' then
  begin
    DefineMacro('FLT_RADIX', '2');
    DefineMacro('FLT_MANT_DIG', '24');
    DefineMacro('DBL_MANT_DIG', '53');
    DefineMacro('FLT_DIG', '6');
    DefineMacro('DBL_DIG', '15');
    DefineMacro('FLT_MIN', '1.175494351e-38F');
    DefineMacro('DBL_MIN', '2.2250738585072014e-308');
    DefineMacro('FLT_MAX', '3.402823466e+38F');
    DefineMacro('DBL_MAX', '1.7976931348623157e+308');
  end
  else if AName = 'stdalign.h' then
    Result :=
      '#define alignas _Alignas' + LineEnding +
      '#define alignof _Alignof' + LineEnding +
      '#define __alignas_is_defined 1' + LineEnding +
      '#define __alignof_is_defined 1' + LineEnding
  else if AName = 'time.h' then
    Result :=
      'typedef unsigned long size_t;' + LineEnding +
      'typedef long time_t;' + LineEnding +
      'time_t time(time_t *t);' + LineEnding;
end;

function TPreprocessor.ResolveInclude(const AName, ACurrentDir: string;
  AAngled: Boolean): string;
var
  I: LongInt;
  Candidate: string;
begin
  if not AAngled then
  begin
    Candidate := ExpandFileName(IncludeTrailingPathDelimiter(ACurrentDir) + AName);
    if FileExists(Candidate) then Exit(Candidate);
  end;
  for I := 0 to High(FIncludePaths) do
  begin
    Candidate := ExpandFileName(IncludeTrailingPathDelimiter(FIncludePaths[I]) + AName);
    if FileExists(Candidate) then Exit(Candidate);
  end;
  Result := '';
end;

procedure TPreprocessor.ProcessFileInternal(const AFileName: string;
  AOutput: TStringList);
var
  Lines: TStringList;
  I, P, Q, N, SourceLine: LongInt;
  Line, Directive, Rest, Name, Value, IncludeName, Resolved, ParamName,
    ParamText, ContinuedLine, ExpandedLine: string;
  CurrentDir, NormalizedFileName: string;
  Angled, Parent, Cond, InBlockComment: Boolean;
  C: TCondition;
  ParamNames: array of string;
  IsFuncLike, HasVariadic: Boolean;
begin
  NormalizedFileName := ExpandFileName(AFileName);
  if IsPragmaOnceFile(NormalizedFileName) then Exit;
  AddDependency(NormalizedFileName);
  if FIncludeDepth >= 64 then
    raise ERCCError.Create('error: include nesting exceeds 64 files');
  Inc(FIncludeDepth);
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(NormalizedFileName);
    CurrentDir := ExtractFileDir(NormalizedFileName);
    InBlockComment := False;
    I := 0;
    while I < Lines.Count do
    begin
      Line := Lines[I];
      while (Length(Line) > 0) and (Line[Length(Line)] = '\') and
        (I + 1 < Lines.Count) do
      begin
        Delete(Line, Length(Line), 1);
        Inc(I);
        Line := Line + Lines[I];
      end;
      Inc(I);
      SourceLine := I;
      Line := StripPreprocessingComments(Line, InBlockComment);
      DefineMacro('__FILE__', '"' +
        StringReplace(NormalizedFileName, '"', '\"', [rfReplaceAll]) + '"');
      DefineMacro('__LINE__', IntToStr(I));
      Rest := TrimLeft(Line);
      if (Rest <> '') and (Rest[1] = '#') then
      begin
        Delete(Rest, 1, 1);
        Rest := TrimLeft(Rest);
        P := 1;
        while (P <= Length(Rest)) and IsIdentPart(Rest[P]) do Inc(P);
        Directive := LowerCase(Copy(Rest, 1, P - 1));
        Rest := TrimLeft(Copy(Rest, P, MaxInt));

        if Directive = 'if' then
        begin
          Parent := IsActive;
          Cond := EvaluateCondition(Rest, CurrentDir);
          N := Length(FConditions);
          SetLength(FConditions, N + 1);
          FConditions[N].ParentActive := Parent;
          FConditions[N].ThisActive := Cond;
          FConditions[N].BranchTaken := Cond;
          FConditions[N].ElseSeen := False;
          Continue;
        end;
        if Directive = 'ifdef' then
        begin
          Parent := IsActive;
          Cond := FindMacro(Trim(Rest)) >= 0;
          N := Length(FConditions);
          SetLength(FConditions, N + 1);
          FConditions[N].ParentActive := Parent;
          FConditions[N].ThisActive := Cond;
          FConditions[N].BranchTaken := Cond;
          FConditions[N].ElseSeen := False;
          Continue;
        end;
        if Directive = 'ifndef' then
        begin
          Parent := IsActive;
          Cond := FindMacro(Trim(Rest)) < 0;
          N := Length(FConditions);
          SetLength(FConditions, N + 1);
          FConditions[N].ParentActive := Parent;
          FConditions[N].ThisActive := Cond;
          FConditions[N].BranchTaken := Cond;
          FConditions[N].ElseSeen := False;
          Continue;
        end;
        if Directive = 'elif' then
        begin
          if Length(FConditions) = 0 then
            raise ERCCError.Create(AFileName + ': error: unmatched #elif');
          C := FConditions[High(FConditions)];
          if C.ElseSeen then
            raise ERCCError.Create(AFileName + ': error: #elif after #else');
          if C.BranchTaken then
            C.ThisActive := False
          else
          begin
            C.ThisActive := EvaluateCondition(Rest, CurrentDir);
            if C.ThisActive then C.BranchTaken := True;
          end;
          FConditions[High(FConditions)] := C;
          Continue;
        end;
        if Directive = 'else' then
        begin
          if Length(FConditions) = 0 then
            raise ERCCError.Create(AFileName + ': error: unmatched #else');
          C := FConditions[High(FConditions)];
          if C.ElseSeen then
            raise ERCCError.Create(AFileName + ': error: duplicate #else');
          C.ThisActive := not C.BranchTaken;
          C.BranchTaken := True;
          C.ElseSeen := True;
          FConditions[High(FConditions)] := C;
          Continue;
        end;
        if Directive = 'endif' then
        begin
          if Length(FConditions) = 0 then
            raise ERCCError.Create(AFileName + ': error: unmatched #endif');
          SetLength(FConditions, Length(FConditions) - 1);
          Continue;
        end;
        if not IsActive then Continue;

        if Directive = 'define' then
        begin
          P := 1;
          while (P <= Length(Rest)) and IsIdentPart(Rest[P]) do Inc(P);
          Name := Copy(Rest, 1, P - 1);
          if Name = '' then
            raise ERCCError.Create(AFileName + ': error: #define requires a macro name');



          IsFuncLike := (P <= Length(Rest)) and (Rest[P] = '(');
          Rest := Copy(Rest, P, MaxInt);
          if IsFuncLike then
          begin
            Delete(Rest, 1, 1);
            Q := Pos(')', Rest);
            if Q = 0 then
              raise ERCCError.Create(AFileName +
                ': error: missing ) in macro parameter list');
            ParamText := Trim(Copy(Rest, 1, Q - 1));
            Value := TrimLeft(Copy(Rest, Q + 1, MaxInt));
            SetLength(ParamNames, 0);
            HasVariadic := False;
            while ParamText <> '' do
            begin
              P := Pos(',', ParamText);
              if P > 0 then
              begin
                ParamName := Trim(Copy(ParamText, 1, P - 1));
                ParamText := Trim(Copy(ParamText, P + 1, MaxInt));
              end
              else
              begin
                ParamName := Trim(ParamText);
                ParamText := '';
              end;
              if ParamName = '...' then
              begin
                if ParamText <> '' then
                  raise ERCCError.Create(AFileName +
                    ': error: variadic marker must be the final macro parameter');
                HasVariadic := True;
                N := Length(ParamNames);
                SetLength(ParamNames, N + 1);
                ParamNames[N] := '__VA_ARGS__';
                Break;
              end;
              if (Length(ParamName) > 3) and
                 (Copy(ParamName, Length(ParamName) - 2, 3) = '...') then
              begin
                if ParamText <> '' then
                  raise ERCCError.Create(AFileName +
                    ': error: variadic macro parameter must be final');
                Delete(ParamName, Length(ParamName) - 2, 3);
                ParamName := Trim(ParamName);
                P := 1;
                while (P <= Length(ParamName)) and IsIdentPart(ParamName[P]) do
                  Inc(P);
                if (ParamName = '') or not IsIdentStart(ParamName[1]) or
                   (P <= Length(ParamName)) then
                  raise ERCCError.Create(AFileName +
                    ': error: invalid variadic macro parameter ' + ParamName);
                HasVariadic := True;
                N := Length(ParamNames);
                SetLength(ParamNames, N + 1);
                ParamNames[N] := ParamName;
                Break;
              end;
              P := 1;
              while (P <= Length(ParamName)) and IsIdentPart(ParamName[P]) do
                Inc(P);
              if (ParamName = '') or not IsIdentStart(ParamName[1]) or
                (P <= Length(ParamName)) then
                raise ERCCError.Create(AFileName +
                  ': error: invalid macro parameter ' + ParamName);
              N := Length(ParamNames);
              SetLength(ParamNames, N + 1);
              ParamNames[N] := ParamName;
            end;
            DefineFunctionMacro(Name, Value, ParamNames, HasVariadic);
          end
          else
          begin
            Value := TrimLeft(Rest);
            DefineMacro(Name, Value);
          end;
          Continue;
        end;
        if Directive = 'undef' then
        begin
          UndefineMacro(Trim(Rest));
          Continue;
        end;
        if Directive = 'include' then
        begin
          Rest := Trim(Rest);
          if (Rest = '') or not (Rest[1] in ['<', '"']) then
            Rest := Trim(ExpandMacros(Rest));
          Angled := (Rest <> '') and (Rest[1] = '<');
          if Angled then
          begin
            Q := Pos('>', Rest);
            if Q = 0 then
              raise ERCCError.Create(AFileName + ': error: malformed #include');
            IncludeName := Copy(Rest, 2, Q - 2);
          end
          else if (Rest <> '') and (Rest[1] = '"') then
          begin
            Q := PosEx('"', Rest, 2);
            if Q = 0 then
              raise ERCCError.Create(AFileName + ': error: malformed #include');
            IncludeName := Copy(Rest, 2, Q - 2);
          end
          else
            raise ERCCError.Create(AFileName + ': error: malformed #include');

          Resolved := ResolveInclude(IncludeName, CurrentDir, Angled);
          if (Resolved = '') and Angled and IsBuiltinHeader(IncludeName) then
          begin
            AOutput.Add(BuiltinHeaderText(IncludeName));
            Continue;
          end;
          if Resolved = '' then
            raise ERCCError.CreateFmt('%s: error: include file not found: %s',
              [AFileName, IncludeName]);
          ProcessFileInternal(Resolved, AOutput);
          Continue;
        end;
        if Directive = 'error' then
          raise ERCCError.CreateFmt('%s: error: %s', [AFileName, Rest]);
        if Directive = 'pragma' then
        begin
          ProcessPragma(Rest, NormalizedFileName, I);
          Continue;
        end;
        if Directive = 'warning' then
        begin
          Continue;
        end;
        Continue;
      end;
if IsActive then
          begin
            ExpandedLine := ExpandMacros(Line);
            while FMacroNeedsContinuation do
            begin
              if I >= Lines.Count then
                raise ERCCError.CreateFmt(
                  '%s:%d: error: unterminated function-like macro invocation',
                  [AFileName, SourceLine]);
              ContinuedLine := Lines[I];
              while (Length(ContinuedLine) > 0) and
                (ContinuedLine[Length(ContinuedLine)] = '\') and
                (I + 1 < Lines.Count) do
              begin
                Delete(ContinuedLine, Length(ContinuedLine), 1);
                Inc(I);
                ContinuedLine := ContinuedLine + Lines[I];
              end;
              Inc(I);
              ContinuedLine := StripPreprocessingComments(ContinuedLine,
                InBlockComment);
              Rest := TrimLeft(ContinuedLine);
              if (Rest <> '') and (Rest[1] = '#') then
                raise ERCCError.CreateFmt(
                  '%s:%d: error: preprocessing directive inside macro invocation',
                  [AFileName, I]);
              Line := Line + LineEnding + ContinuedLine;
              ExpandedLine := ExpandMacros(Line);
            end;
            AOutput.Add('#line ' + IntToStr(SourceLine) + LineEnding + ExpandedLine);
          end;
    end;
    if InBlockComment then
      raise ERCCError.Create(AFileName + ': error: unterminated block comment');
  finally
    Lines.Free;
    Dec(FIncludeDepth);
  end;
end;

function TPreprocessor.ProcessFile(const AFileName: string): string;
var
  Output: TStringList;
begin
  SetLength(FConditions, 0);
  Output := TStringList.Create;
  try
    ProcessFileInternal(ExpandFileName(AFileName), Output);
    Result := Output.Text;
  finally
    Output.Free;
  end;
  if Length(FConditions) <> 0 then
    raise ERCCError.Create(AFileName + ': error: unterminated conditional directive');
end;



constructor TLexer.Create(const ASource, AFileName: string);
begin
  inherited Create;
  FSource := ASource;
  FFileName := AFileName;
  FIndex := 1;
  FLine := 1;
  FColumn := 1;
end;

function TLexer.Current: Char;
begin
  if FIndex > Length(FSource) then Result := #0
  else Result := FSource[FIndex];
end;

function TLexer.Peek(AOffset: LongInt): Char;
begin
  if FIndex + AOffset > Length(FSource) then Result := #0
  else Result := FSource[FIndex + AOffset];
end;

procedure TLexer.Advance;
begin
  if Current = #0 then Exit;
  if Current = #10 then
  begin
    Inc(FLine);
    FColumn := 1;
  end
  else
    Inc(FColumn);
  Inc(FIndex);
end;

function TLexer.Position: TSourcePos;
begin
  Result.FileName := FFileName;
  Result.Line := FLine;
  Result.Column := FColumn;
end;

procedure TLexer.SkipWhitespaceAndComments;
begin
  while True do
  begin
    while Current in [' ', #9, #10, #13, #12] do Advance;
    if (Current = '/') and (Peek = '/') then
    begin
      while not (Current in [#0, #10]) do Advance;
      Continue;
    end;
    if (Current = '/') and (Peek = '*') then
    begin
      Advance;
      Advance;
      while not ((Current = '*') and (Peek = '/')) do
      begin
        if Current = #0 then
          RaiseCompileError(Position, 'unterminated block comment');
        Advance;
      end;
      Advance;
      Advance;
      Continue;
    end;
    Break;
  end;
end;

function TLexer.ReadIdentifier: string;
var
  Start: LongInt;
begin
  Start := FIndex;
  while IsIdentPart(Current) do Advance;
  Result := Copy(FSource, Start, FIndex - Start);
end;

function DigitValue(C: Char): LongInt;
begin
  if C in ['0'..'9'] then Result := Ord(C) - Ord('0')
  else if C in ['a'..'f'] then Result := 10 + Ord(C) - Ord('a')
  else if C in ['A'..'F'] then Result := 10 + Ord(C) - Ord('A')
  else Result := -1;
end;

function TLexer.ReadNumber(out AValue: Int64; out AFloatValue: Double;
  out AIsFloat: Boolean): string;
var
  Start, Base, D, Digits, SequenceDigits, SuffixStart: LongInt;
  Accumulator: QWord;
  P: TSourcePos;
  HasDot, HasExponent: Boolean;
  LiteralText, NumericText, SuffixText: string;
  FormatSettings: TFormatSettings;

  function IsBaseDigit(C: Char; ABase: LongInt): Boolean;
  var
    Value: LongInt;
  begin
    Value := DigitValue(C);
    Result := (Value >= 0) and (Value < ABase);
  end;

  procedure ConsumeDigitSeparator(ABase, ASequenceDigits: LongInt);
  begin
    if (ASequenceDigits = 0) or not IsBaseDigit(Peek, ABase) then
      RaiseCompileError(Position,
        'digit separator must appear between digits');
    Advance;
  end;

begin
  Start := FIndex;
  P := Position;
  Base := 10;
  Digits := 0;
  HasDot := False;
  HasExponent := False;
  AValue := 0;
  AFloatValue := 0.0;
  AIsFloat := False;




  if (Current = '0') and ((Peek = 'x') or (Peek = 'X')) then
  begin
    Base := 16;
    Advance;
    Advance;
  end
  else if (Current = '0') and ((Peek = 'b') or (Peek = 'B')) then
  begin
    Base := 2;
    Advance;
    Advance;
  end
  else
  begin
    SequenceDigits := 0;
    while (Current in ['0'..'9']) or (Current = '''') do
    begin
      if Current = '''' then
        ConsumeDigitSeparator(10, SequenceDigits)
      else
      begin
        Inc(SequenceDigits);
        Advance;
      end;
    end;
    if Current = '.' then
    begin
      HasDot := True;
      Advance;
      SequenceDigits := 0;
      while (Current in ['0'..'9']) or (Current = '''') do
      begin
        if Current = '''' then
          ConsumeDigitSeparator(10, SequenceDigits)
        else
        begin
          Inc(SequenceDigits);
          Advance;
        end;
      end;
    end;
    if Current in ['e', 'E'] then
    begin
      HasExponent := True;
      Advance;
      if Current in ['+', '-'] then Advance;
      SequenceDigits := 0;
      while (Current in ['0'..'9']) or (Current = '''') do
      begin
        if Current = '''' then
          ConsumeDigitSeparator(10, SequenceDigits)
        else
        begin
          Inc(SequenceDigits);
          Advance;
        end;
      end;
      if SequenceDigits = 0 then
        RaiseCompileError(P, 'floating exponent requires decimal digits');
    end;
    if HasDot or HasExponent then
    begin
      if Current in ['f', 'F', 'l', 'L'] then Advance;
      LiteralText := Copy(FSource, Start, FIndex - Start);
      NumericText := LiteralText;
      while (NumericText <> '') and
        (NumericText[Length(NumericText)] in ['f', 'F', 'l', 'L']) do
        Delete(NumericText, Length(NumericText), 1);
      NumericText := StringReplace(NumericText, '''', '', [rfReplaceAll]);
      FormatSettings := DefaultFormatSettings;
      FormatSettings.DecimalSeparator := '.';
      if not TryStrToFloat(NumericText, AFloatValue, FormatSettings) then
        RaiseCompileError(P, 'invalid floating literal ' + LiteralText);
      AIsFloat := True;
      Result := LiteralText;
      Exit;
    end;

    FIndex := Start;
    FLine := P.Line;
    FColumn := P.Column;
    if (Current = '0') and
      ((Peek in ['0'..'9']) or
       ((Peek = '''') and (Peek(2) in ['0'..'9']))) then
      Base := 8;
  end;

  Accumulator := 0;
  SequenceDigits := 0;
  while True do
  begin
    D := DigitValue(Current);
    if (D >= 0) and (D < Base) then
    begin
      if Accumulator > (High(QWord) - QWord(D)) div QWord(Base) then
        RaiseCompileError(P, 'integer literal exceeds 64 bits');
      Accumulator := Accumulator * QWord(Base) + QWord(D);
      Inc(Digits);
      Inc(SequenceDigits);
      Advance;
      Continue;
    end;
    if Current = '''' then
    begin
      ConsumeDigitSeparator(Base, SequenceDigits);
      SequenceDigits := 0;
      Continue;
    end;
    Break;
  end;
  if Digits = 0 then
    RaiseCompileError(P, 'integer literal has no digits');
  if (Base = 8) and (Current in ['8', '9']) then
    RaiseCompileError(P, 'invalid digit in octal integer literal');
  if (Base = 2) and (Current in ['2'..'9']) then
    RaiseCompileError(P, 'invalid digit in binary integer literal');

  SuffixStart := FIndex;
  while Current in ['u', 'U', 'l', 'L'] do Advance;
  SuffixText := LowerCase(Copy(FSource, SuffixStart, FIndex - SuffixStart));
  if (SuffixText <> '') and (SuffixText <> 'u') and
    (SuffixText <> 'l') and (SuffixText <> 'ul') and
    (SuffixText <> 'lu') and (SuffixText <> 'll') and
    (SuffixText <> 'ull') and (SuffixText <> 'llu') then
    RaiseCompileError(P, 'invalid integer suffix ' + SuffixText);

  AValue := Int64(Accumulator);
  Result := Copy(FSource, Start, FIndex - Start);
end;

function DecodeEscape(C: Char): Char;
begin
  case C of
    'n': Result := #10;
    'r': Result := #13;
    't': Result := #9;
    '0': Result := #0;
    '\': Result := '\';
    '''': Result := '''';
    '"': Result := '"';
    'a': Result := #7;
    'b': Result := #8;
    'f': Result := #12;
    'v': Result := #11;
  else
    Result := C;
  end;
end;

function TLexer.ReadQuoted(AQuote: Char; out AValue: string): string;
var
  Start: LongInt;
  C: Char;
  OctalDigits: LongInt;
  OctalVal: LongInt;
begin
  Start := FIndex;
  AValue := '';
  Advance;
  while (Current <> AQuote) and (Current <> #0) do
  begin
    if Current in [#10, #13] then
      RaiseCompileError(Position, 'newline in literal');
    if Current = '\' then
    begin
      Advance;
      if Current = #0 then Break;
      if Current in ['0'..'7'] then
      begin
        OctalVal := 0;
        OctalDigits := 0;
        while (Current in ['0'..'7']) and (OctalDigits < 3) do
        begin
          OctalVal := OctalVal * 8 + (Ord(Current) - Ord('0'));
          Advance;
          Inc(OctalDigits);
        end;
        AValue := AValue + Chr(OctalVal);
      end
      else if Current = 'x' then
      begin
        Advance;
        OctalVal := 0;
        OctalDigits := 0;
        while (DigitValue(Current) >= 0) and (DigitValue(Current) <= 15) and (OctalDigits < 2) do
        begin
          OctalVal := OctalVal * 16 + DigitValue(Current);
          Advance;
          Inc(OctalDigits);
        end;
        AValue := AValue + Chr(OctalVal);
      end
      else
      begin
        C := DecodeEscape(Current);
        AValue := AValue + C;
        Advance;
      end;
    end
    else
    begin
      AValue := AValue + Current;
      Advance;
    end;
  end;
  if Current <> AQuote then
    RaiseCompileError(Position, 'unterminated literal');
  Advance;
  Result := Copy(FSource, Start, FIndex - Start);
end;

function TLexer.KeywordKind(const AText: string): TTokenKind;
begin
  if AText = 'void' then Exit(kwVoid);
  if AText = 'char' then Exit(kwChar);
  if AText = 'short' then Exit(kwShort);
  if AText = 'int' then Exit(kwInt);
  if AText = 'long' then Exit(kwLong);
  if AText = 'float' then Exit(kwFloat);
  if AText = 'double' then Exit(kwDouble);
  if AText = '_Bool' then Exit(kwBool);
  if AText = 'signed' then Exit(kwSigned);
  if AText = 'unsigned' then Exit(kwUnsigned);
  if AText = 'const' then Exit(kwConst);
  if AText = 'volatile' then Exit(kwVolatile);
  if AText = 'restrict' then Exit(kwRestrict);
  if AText = 'static' then Exit(kwStatic);
  if AText = 'extern' then Exit(kwExtern);
  if AText = 'auto' then Exit(kwAuto);
  if AText = 'register' then Exit(kwRegister);
  if AText = 'inline' then Exit(kwInline);
  if AText = 'typedef' then Exit(kwTypedef);
  if AText = 'struct' then Exit(kwStruct);
  if AText = 'union' then Exit(kwUnion);
  if AText = 'enum' then Exit(kwEnum);
  if AText = 'if' then Exit(kwIf);
  if AText = 'else' then Exit(kwElse);
  if AText = 'while' then Exit(kwWhile);
  if AText = 'do' then Exit(kwDo);
  if AText = 'for' then Exit(kwFor);
  if AText = 'switch' then Exit(kwSwitch);
  if AText = 'case' then Exit(kwCase);
  if AText = 'default' then Exit(kwDefault);
  if AText = 'break' then Exit(kwBreak);
  if AText = 'continue' then Exit(kwContinue);
  if AText = 'return' then Exit(kwReturn);
  if AText = 'goto' then Exit(kwGoto);
  if (AText = 'asm') or (AText = '__asm') or (AText = '__asm__') then Exit(kwAsm);
  if (AText = 'typeof') or (AText = '__typeof') or (AText = '__typeof__') then Exit(kwTypeof);
  if AText = 'sizeof' then Exit(kwSizeof);
  if (AText = '_Alignof') or (AText = '__alignof__') then Exit(kwAlignof);
  if AText = '_Alignas' then Exit(kwAlignas);
  if AText = '_Static_assert' then Exit(kwStaticAssert);
  if AText = '_Generic' then Exit(kwGeneric);
  if AText = 'nullptr' then Exit(kwNullptr);
  Result := tkIdentifier;
end;

procedure TLexer.AddToken(var ATokens: TTokenArray; AKind: TTokenKind;
  const AText: string; AValue: Int64; AFloatValue: Double;
  const APos: TSourcePos);
begin
  if FTokenCount >= FTokenCapacity then
  begin
    if FTokenCapacity = 0 then FTokenCapacity := 4096
    else FTokenCapacity := FTokenCapacity * 2;
    SetLength(ATokens, FTokenCapacity);
  end;
  ATokens[FTokenCount].Kind := AKind;
  ATokens[FTokenCount].Text := AText;
  ATokens[FTokenCount].IntValue := AValue;
  ATokens[FTokenCount].FloatValue := AFloatValue;
  ATokens[FTokenCount].Pos := APos;
  Inc(FTokenCount);
end;

function TLexer.Tokenize: TTokenArray;
var
  P: TSourcePos;
  S, Decoded: string;
  V: Int64;
  FV: Double;
  IsFloat: Boolean;
  K: TTokenKind;
  C: Char;
  N: Int64;

  procedure Simple(AKind: TTokenKind; ACount: LongInt = 1);
  var
    J: LongInt;
  begin
    S := Copy(FSource, FIndex, ACount);
    for J := 1 to ACount do Advance;
    AddToken(Result, AKind, S, 0, 0.0, P);
  end;

begin
  SetLength(Result, 0);
  FTokenCount := 0;
  FTokenCapacity := 0;
  while True do
  begin
    SkipWhitespaceAndComments;
    P := Position;
    C := Current;
    if C = '#' then
    begin



      Advance;
      while Current in [' ', #9] do Advance;
      if not IsIdentStart(Current) then
        RaiseCompileError(P, 'unexpected character ''#''');
      S := ReadIdentifier;
      if S <> 'line' then
        RaiseCompileError(P, 'unexpected character ''#''');
      while Current in [' ', #9] do Advance;
      N := 0;
      while (Current >= '0') and (Current <= '9') do
      begin
        N := N * 10 + (Ord(Current) - Ord('0'));
        Advance;
      end;
      if N <= 0 then RaiseCompileError(P, 'malformed #line marker');
      FLine := N - 1;
      FColumn := 1;
      while not (Current in [#0, #10]) do Advance;
      Continue;
    end;
    if C = #0 then
    begin
      AddToken(Result, tkEOF, '', 0, 0.0, P);
      Break;
    end;
    if IsIdentStart(C) then
    begin
      S := ReadIdentifier;
      K := KeywordKind(S);
      AddToken(Result, K, S, 0, 0.0, P);
      Continue;
    end;
    if (C in ['0'..'9']) or ((C = '.') and (Peek in ['0'..'9'])) then
    begin
      S := ReadNumber(V, FV, IsFloat);
      if IsFloat then AddToken(Result, tkFloat, S, 0, FV, P)
      else AddToken(Result, tkInteger, S, V, 0.0, P);
      Continue;
    end;
    if C = '"' then
    begin
      S := ReadQuoted('"', Decoded);
      AddToken(Result, tkString, Decoded, 0, 0.0, P);
      Continue;
    end;
    if C = '''' then
    begin
      S := ReadQuoted('''', Decoded);
      if Decoded = '' then V := 0 else V := Ord(Decoded[1]);
      AddToken(Result, tkInteger, S, V, 0.0, P);
      Continue;
    end;

    case C of
      '(': Simple(tkLParen);
      ')': Simple(tkRParen);
      '{': Simple(tkLBrace);
      '}': Simple(tkRBrace);
      '[': Simple(tkLBracket);
      ']': Simple(tkRBracket);
      ';': Simple(tkSemicolon);
      ',': Simple(tkComma);
      '?': Simple(tkQuestion);
      ':': Simple(tkColon);
      '~': Simple(tkTilde);
      '.': if Peek = '.' then
           begin
             if Peek(2) = '.' then Simple(tkEllipsis, 3)
             else Simple(tkDot);
           end
           else Simple(tkDot);
      '+': if Peek = '+' then Simple(tkIncrement, 2)
           else if Peek = '=' then Simple(tkPlusAssign, 2)
           else Simple(tkPlus);
      '-': if Peek = '-' then Simple(tkDecrement, 2)
           else if Peek = '=' then Simple(tkMinusAssign, 2)
           else if Peek = '>' then Simple(tkArrow, 2)
           else Simple(tkMinus);
      '*': if Peek = '=' then Simple(tkStarAssign, 2) else Simple(tkStar);
      '/': if Peek = '=' then Simple(tkSlashAssign, 2) else Simple(tkSlash);
      '%': if Peek = '=' then Simple(tkPercentAssign, 2) else Simple(tkPercent);
      '&': if Peek = '&' then Simple(tkLogicalAnd, 2)
           else if Peek = '=' then Simple(tkAmpAssign, 2)
           else Simple(tkAmp);
      '|': if Peek = '|' then Simple(tkLogicalOr, 2)
           else if Peek = '=' then Simple(tkPipeAssign, 2)
           else Simple(tkPipe);
      '^': if Peek = '=' then Simple(tkCaretAssign, 2) else Simple(tkCaret);
      '!': if Peek = '=' then Simple(tkNotEqual, 2) else Simple(tkBang);
      '=': if Peek = '=' then Simple(tkEqual, 2) else Simple(tkAssign);
      '<': if (Peek = '<') and (Peek(2) = '=') then Simple(tkShiftLeftAssign, 3)
           else if Peek = '<' then Simple(tkShiftLeft, 2)
           else if Peek = '=' then Simple(tkLessEqual, 2)
           else Simple(tkLess);
      '>': if (Peek = '>') and (Peek(2) = '=') then Simple(tkShiftRightAssign, 3)
           else if Peek = '>' then Simple(tkShiftRight, 2)
           else if Peek = '=' then Simple(tkGreaterEqual, 2)
           else Simple(tkGreater);
    else
      RaiseCompileError(P, 'unexpected character ''' + C + '''');
    end;
  end;
  SetLength(Result, FTokenCount);
end;



constructor TParser.Create(const ATokens: TTokenArray);
begin
  inherited Create;
  FTokens := ATokens;
  FIndex := 0;
  FInSwitch := 0;
  FBreakableDepth := 0;
  FContinueableDepth := 0;
  FScopeDepth := 0;
  SetLength(FDeclaredTypes, 0);
end;

destructor TParser.Destroy;
var
  I: LongInt;
begin
  for I := 0 to High(FOwnedStructInfos) do
    if FOwnedStructInfos[I] <> nil then
      Dispose(FOwnedStructInfos[I]);
  for I := 0 to High(FOwnedMemberTypes) do
    if FOwnedMemberTypes[I] <> nil then
      Dispose(FOwnedMemberTypes[I]);
  for I := 0 to High(FOwnedFunctionParameterLists) do
    if FOwnedFunctionParameterLists[I] <> nil then
      Dispose(FOwnedFunctionParameterLists[I]);
  inherited Destroy;
end;

function TParser.NewOwnedStructInfo: PStructMembers;
var
  N: LongInt;
begin
  New(Result);
  N := Length(FOwnedStructInfos);
  SetLength(FOwnedStructInfos, N + 1);
  FOwnedStructInfos[N] := Result;
end;

function TParser.NewOwnedMemberType: PCType;
var
  N: LongInt;
begin
  New(Result);
  N := Length(FOwnedMemberTypes);
  SetLength(FOwnedMemberTypes, N + 1);
  FOwnedMemberTypes[N] := Result;
end;

function TParser.NewOwnedFunctionParameterList: PFunctionParameterList;
var
  N: LongInt;
begin
  New(Result);
  N := Length(FOwnedFunctionParameterLists);
  SetLength(FOwnedFunctionParameterLists, N + 1);
  FOwnedFunctionParameterLists[N] := Result;
end;

procedure TParser.TransferTypeStorage(AProgram: TProgram);
var
  I: LongInt;
begin
  for I := 0 to High(FOwnedStructInfos) do
  begin
    AProgram.OwnStructInfo(FOwnedStructInfos[I]);
    FOwnedStructInfos[I] := nil;
  end;
  for I := 0 to High(FOwnedMemberTypes) do
  begin
    AProgram.OwnMemberType(FOwnedMemberTypes[I]);
    FOwnedMemberTypes[I] := nil;
  end;
  for I := 0 to High(FOwnedFunctionParameterLists) do
  begin
    AProgram.OwnFunctionParameterList(FOwnedFunctionParameterLists[I]);
    FOwnedFunctionParameterLists[I] := nil;
  end;
  SetLength(FOwnedStructInfos, 0);
  SetLength(FOwnedMemberTypes, 0);
  SetLength(FOwnedFunctionParameterLists, 0);
end;

function TParser.Current: TToken;
begin
  if FIndex > High(FTokens) then Result := FTokens[High(FTokens)]
  else Result := FTokens[FIndex];
end;

function TParser.Peek(AOffset: LongInt): TToken;
var
  I: LongInt;
begin
  I := FIndex + AOffset;
  if I > High(FTokens) then I := High(FTokens);
  Result := FTokens[I];
end;

function TParser.At(AKind: TTokenKind): Boolean;
begin
  Result := Current.Kind = AKind;
end;

function TParser.Match(AKind: TTokenKind): Boolean;
begin
  Result := At(AKind);
  if Result then Inc(FIndex);
end;

function TParser.Expect(AKind: TTokenKind; const AWhat: string): TToken;
var
  Expected: string;
begin
  if not At(AKind) then
  begin
    if AWhat <> '' then Expected := AWhat
    else Expected := TokenKindName(AKind);
    RaiseCompileError(Current.Pos, 'expected ' + Expected + ', found ' +
      TokenKindName(Current.Kind));
  end;
  Result := Current;
  Inc(FIndex);
end;

function TParser.FindTypedef(const AName: string; out ACType: TCType): Boolean;
var
  I: LongInt;
begin
  for I := High(FTypedefs) downto 0 do
    if FTypedefs[I].Name = AName then
    begin
      ACType := FTypedefs[I].CType;
      Exit(True);
    end;
  Result := False;
end;

procedure TParser.AddTypedef(const AName: string; const ACType: TCType);
var
  N: LongInt;
begin
  N := Length(FTypedefs);
  SetLength(FTypedefs, N + 1);
  FTypedefs[N].Name := AName;
  FTypedefs[N].CType := ACType;
end;

function TParser.FindIntegerConstant(const AName: string;
  out AValue: Int64): Boolean;
var
  I: LongInt;
begin
  for I := High(FIntegerConstants) downto 0 do
    if FIntegerConstants[I].Name = AName then
    begin
      AValue := FIntegerConstants[I].Value;
      Exit(True);
    end;
  Result := False;
end;

procedure TParser.AddIntegerConstant(const AName: string; AValue: Int64;
  const APos: TSourcePos);
var
  I, N: LongInt;
begin
  for I := High(FIntegerConstants) downto 0 do
    if FIntegerConstants[I].Name = AName then
      RaiseCompileError(APos, 'redefinition of enumerator ''' + AName + '''');
  N := Length(FIntegerConstants);
  SetLength(FIntegerConstants, N + 1);
  FIntegerConstants[N].Name := AName;
  FIntegerConstants[N].Value := AValue;
end;


function TParser.FindDeclaredType(const AName: string; out ACType: TCType;
  out AIsFunction: Boolean): Boolean;
var
  I: LongInt;
begin
  for I := High(FDeclaredTypes) downto 0 do
    if FDeclaredTypes[I].Name = AName then
    begin
      ACType := FDeclaredTypes[I].CType;
      AIsFunction := FDeclaredTypes[I].IsFunction;
      Exit(True);
    end;
  AIsFunction := False;
  Result := False;
end;

procedure TParser.AddDeclaredType(const AName: string; const ACType: TCType;
  AScopeDepth: LongInt; AIsFunction: Boolean);
var
  N: LongInt;
begin
  if AName = '' then Exit;
  N := Length(FDeclaredTypes);
  SetLength(FDeclaredTypes, N + 1);
  FDeclaredTypes[N].Name := AName;
  FDeclaredTypes[N].CType := ACType;
  FDeclaredTypes[N].ScopeDepth := AScopeDepth;
  FDeclaredTypes[N].IsFunction := AIsFunction;
end;

procedure TParser.EnterScope;
begin
  Inc(FScopeDepth);
end;

procedure TParser.LeaveScope;
var
  N: LongInt;
begin
  N := Length(FDeclaredTypes);
  while (N > 0) and (FDeclaredTypes[N - 1].ScopeDepth >= FScopeDepth) do
    Dec(N);
  SetLength(FDeclaredTypes, N);
  if FScopeDepth > 0 then Dec(FScopeDepth);
end;

function TParser.InferParserExpressionType(E: TExpr;
  out ACType: TCType): Boolean;
var
  LeftType, RightType, ThirdType, BaseType: TCType;
  IsFunction: Boolean;
  Member: TStructMember;

  function ArithmeticType(const A, B: TCType): TCType;
  var
    LeftSize, RightSize: LongInt;
  begin
    if IsFloatingType(A) or IsFloatingType(B) then
    begin
      if (A.Kind = ctLongDouble) or (B.Kind = ctLongDouble) then
        Exit(MakeType(ctLongDouble));
      if (A.Kind = ctDouble) or (B.Kind = ctDouble) then
        Exit(MakeType(ctDouble));
      Exit(MakeType(ctFloat));
    end;
    LeftSize := StorageSize(A);
    RightSize := StorageSize(B);
    if LeftSize > RightSize then Exit(A);
    if RightSize > LeftSize then Exit(B);
    Result := A;
    Result.IsUnsigned := A.IsUnsigned or B.IsUnsigned;
  end;

begin
  Result := False;
  ACType := MakeType(ctInt);
  if E = nil then Exit;
  case E.Kind of
    ekInteger:
      begin
        ACType := MakeType(ctInt);
        if Pos('ll', LowerCase(E.Text)) > 0 then ACType.Kind := ctLongLong
        else if Pos('l', LowerCase(E.Text)) > 0 then ACType.Kind := ctLong;
        ACType.IsUnsigned := Pos('u', LowerCase(E.Text)) > 0;
        Exit(True);
      end;
    ekFloat:
      begin
        if (E.Text <> '') and (E.Text[Length(E.Text)] in ['f', 'F']) then
          ACType := MakeType(ctFloat)
        else if (E.Text <> '') and (E.Text[Length(E.Text)] in ['l', 'L']) then
          ACType := MakeType(ctLongDouble)
        else
          ACType := MakeType(ctDouble);
        Exit(True);
      end;
    ekString:
      begin
        ACType := MakeArrayType(MakeType(ctChar), Length(E.Text) + 1);
        Exit(True);
      end;
    ekNullptr:
      begin
        ACType := MakeType(ctVoid, False, 1);
        Exit(True);
      end;
    ekTrap:
      begin
        ACType := MakeType(ctVoid);
        Exit(True);
      end;
    ekVariable:
      Exit(FindDeclaredType(E.Text, ACType, IsFunction));
    ekCast:
      begin
        ACType := E.CType;
        Exit(True);
      end;
    ekAddress:
      begin
        if not InferParserExpressionType(E.Left, LeftType) then Exit;
        ACType := PointerTo(LeftType);
        Exit(True);
      end;
    ekDeref:
      begin
        if not InferParserExpressionType(E.Left, LeftType) then Exit;
        LeftType := DecayType(LeftType);
        if not IsPointerType(LeftType) then Exit;
        ACType := PointeeType(LeftType);
        Exit(True);
      end;
    ekIndex:
      begin
        if InferParserExpressionType(E.Left, LeftType) then
          BaseType := DecayType(LeftType)
        else if InferParserExpressionType(E.Right, RightType) then
          BaseType := DecayType(RightType)
        else
          Exit;
        if not IsPointerType(BaseType) then
        begin
          if not InferParserExpressionType(E.Right, RightType) then Exit;
          BaseType := DecayType(RightType);
        end;
        if not IsPointerType(BaseType) then Exit;
        ACType := PointeeType(BaseType);
        Exit(True);
      end;
    ekMember:
      begin
        if not InferParserExpressionType(E.Left, BaseType) then Exit;
        if not FindMember(BaseType, E.Text, Member) then Exit;
        ACType := PCType(Member.CType)^;
        Exit(True);
      end;
    ekArrow:
      begin
        if not InferParserExpressionType(E.Left, BaseType) then Exit;
        BaseType := DecayType(BaseType);
        if not IsPointerType(BaseType) then Exit;
        BaseType := PointeeType(BaseType);
        if not FindMember(BaseType, E.Text, Member) then Exit;
        ACType := PCType(Member.CType)^;
        Exit(True);
      end;
    ekUnary, ekPreInc, ekPreDec, ekPostInc, ekPostDec:
      begin
        if not InferParserExpressionType(E.Left, ACType) then Exit;
        if (E.Kind = ekUnary) and (E.UnaryOp = uoLogicalNot) then
          ACType := MakeType(ctInt);
        Exit(True);
      end;
    ekBinary:
      begin
        if not InferParserExpressionType(E.Left, LeftType) or
          not InferParserExpressionType(E.Right, RightType) then Exit;
        case E.BinaryOp of
          boLess, boLessEqual, boGreater, boGreaterEqual,
          boEqual, boNotEqual, boLogicalAnd, boLogicalOr:
            ACType := MakeType(ctInt);
          boComma:
            ACType := RightType;
          boAdd, boSub:
            begin
              LeftType := DecayType(LeftType);
              RightType := DecayType(RightType);
              if IsPointerType(LeftType) and IsIntegerType(RightType) then
                ACType := LeftType
              else if (E.BinaryOp = boAdd) and IsIntegerType(LeftType) and
                IsPointerType(RightType) then
                ACType := RightType
              else if IsPointerType(LeftType) and IsPointerType(RightType) then
                ACType := MakeType(ctLong)
              else
                ACType := ArithmeticType(LeftType, RightType);
            end;
        else
          ACType := ArithmeticType(LeftType, RightType);
        end;
        Exit(True);
      end;
    ekAssign:
      begin
        if not InferParserExpressionType(E.Left, ACType) then Exit;
        Exit(True);
      end;
    ekConditional:
      begin
        if not InferParserExpressionType(E.Right, RightType) or
          not InferParserExpressionType(E.Third, ThirdType) then Exit;
        if TypesEqual(RightType, ThirdType) then ACType := RightType
        else ACType := ArithmeticType(RightType, ThirdType);
        Exit(True);
      end;
    ekCall:
      begin
        if (E.Left <> nil) and (E.Left.Kind = ekVariable) and
          FindDeclaredType(E.Left.Text, ACType, IsFunction) then
        begin
          if IsFunction then Exit(True);
          ACType := DecayType(ACType);
          if IsPointerType(ACType) then
          begin
            LeftType := PointeeType(ACType);
            if LeftType.Kind = ctFunction then
            begin
              if HasFunctionSignature(LeftType) then
                ACType := FunctionReturnTypeOf(LeftType)
              else
                ACType := MakeType(ctInt);
              Exit(True);
            end;
          end;
        end;
        Exit(False);
      end;
    ekSizeof, ekAlignof:
      begin
        ACType := MakeType(ctLong, True);
        Exit(True);
      end;
    ekCompoundLit:
      begin
        ACType := E.CType;
        Exit(True);
      end;
  end;
end;

function TParser.EvaluateParserIntegerConstant(E: TExpr;
  out AValue: Int64): Boolean;
var
  LeftValue, RightValue, NamedValue: Int64;
  LeftBits, RightBits: QWord;
begin
  Result := False;
  AValue := 0;
  if E = nil then Exit;
  case E.Kind of
    ekInteger:
      begin
        AValue := E.IntValue;
        Exit(True);
      end;
    ekVariable:
      begin
        if not FindIntegerConstant(E.Text, NamedValue) then Exit;
        AValue := NamedValue;
        Exit(True);
      end;
    ekUnary:
      begin
        if not EvaluateParserIntegerConstant(E.Left, LeftValue) then Exit;
        case E.UnaryOp of
          uoPositive: AValue := LeftValue;
          uoNegative: AValue := Int64(QWord(0) - QWord(LeftValue));
          uoLogicalNot:
            if LeftValue = 0 then AValue := 1 else AValue := 0;
          uoBitwiseNot: AValue := Int64(not QWord(LeftValue));
        end;
        Exit(True);
      end;
    ekBinary:
      begin
        if not EvaluateParserIntegerConstant(E.Left, LeftValue) then Exit;
        if E.BinaryOp = boLogicalAnd then
        begin
          if LeftValue = 0 then
          begin
            AValue := 0;
            Exit(True);
          end;
        end
        else if E.BinaryOp = boLogicalOr then
        begin
          if LeftValue <> 0 then
          begin
            AValue := 1;
            Exit(True);
          end;
        end;
        if not EvaluateParserIntegerConstant(E.Right, RightValue) then Exit;
        LeftBits := QWord(LeftValue);
        RightBits := QWord(RightValue);
        case E.BinaryOp of
          boAdd: AValue := Int64(LeftBits + RightBits);
          boSub: AValue := Int64(LeftBits - RightBits);
          boMul: AValue := Int64(LeftBits * RightBits);
          boDiv:
            begin
              if RightValue = 0 then Exit;
              if (LeftValue = Low(Int64)) and (RightValue = -1) then Exit;
              AValue := LeftValue div RightValue;
            end;
          boMod:
            begin
              if RightValue = 0 then Exit;
              if (LeftValue = Low(Int64)) and (RightValue = -1) then
                AValue := 0
              else
                AValue := LeftValue mod RightValue;
            end;
          boShiftLeft:
            begin
              if (RightValue < 0) or (RightValue >= 64) then Exit;
              AValue := Int64(LeftBits shl RightValue);
            end;
          boShiftRight:
            begin
              if (RightValue < 0) or (RightValue >= 64) then Exit;
              AValue := LeftValue shr RightValue;
            end;
          boLess: if LeftValue < RightValue then AValue := 1 else AValue := 0;
          boLessEqual: if LeftValue <= RightValue then AValue := 1 else AValue := 0;
          boGreater: if LeftValue > RightValue then AValue := 1 else AValue := 0;
          boGreaterEqual: if LeftValue >= RightValue then AValue := 1 else AValue := 0;
          boEqual: if LeftValue = RightValue then AValue := 1 else AValue := 0;
          boNotEqual: if LeftValue <> RightValue then AValue := 1 else AValue := 0;
          boBitAnd: AValue := Int64(LeftBits and RightBits);
          boBitXor: AValue := Int64(LeftBits xor RightBits);
          boBitOr: AValue := Int64(LeftBits or RightBits);
          boLogicalAnd: if RightValue <> 0 then AValue := 1 else AValue := 0;
          boLogicalOr: if RightValue <> 0 then AValue := 1 else AValue := 0;
          boComma: AValue := RightValue;
        else
          Exit;
        end;
        Exit(True);
      end;
    ekConditional:
      begin
        if not EvaluateParserIntegerConstant(E.Left, LeftValue) then Exit;
        if LeftValue <> 0 then
          Result := EvaluateParserIntegerConstant(E.Right, AValue)
        else
          Result := EvaluateParserIntegerConstant(E.Third, AValue);
      end;
    ekCast:
      begin
        if not EvaluateParserIntegerConstant(E.Left, LeftValue) then Exit;
        if IsIntegerType(E.CType) then
          AValue := ConvertIntegerValue(LeftValue, E.CType)
        else
          AValue := LeftValue;
        Exit(True);
      end;
    ekSizeof, ekAlignof:
      begin
        if E.IntValue <= 0 then Exit;
        AValue := E.IntValue;
        Exit(True);
      end;
  end;
end;

function TParser.FindStruct(const AName: string; out AInfo: PStructMembers): Boolean;
var
  I: LongInt;
begin
  for I := High(FStructs) downto 0 do
    if FStructs[I].Name = AName then
    begin
      AInfo := @FStructs[I];
      Exit(True);
    end;
  Result := False;
end;

function TParser.IsTypeStart: Boolean;
var
  Dummy: TCType;
begin
  case Current.Kind of
    kwVoid, kwChar, kwShort, kwInt, kwLong, kwFloat, kwDouble, kwBool,
    kwSigned, kwUnsigned, kwConst, kwVolatile, kwRestrict,
    kwStatic, kwExtern, kwAuto, kwRegister, kwInline,
    kwTypedef, kwStruct, kwUnion, kwEnum, kwTypeof: Exit(True);
    tkIdentifier: Exit(FindTypedef(Current.Text, Dummy));
  end;
  Result := False;
end;

function TParser.ParseDeclarator(var CType: TCType; out AName: string): Boolean;
var
  ArrayLength: Int64;
  ElementType, ReturnValueType, ParamType: TCType;
  Expr: TExpr;
  PointerDepth, FunctionPointerDepth, GroupedPointerDepth, N: LongInt;
  ParamName: string;
  ParamWasTypedef: Boolean;
  ParamList: PFunctionParameterList;
  FunctionVariadic: Boolean;
  Dimensions: array of Int64;
  DimensionCount, DimensionIndex: LongInt;
begin
  AName := '';
  PointerDepth := CType.PointerDepth;
  while Match(tkStar) do
  begin
    Inc(PointerDepth);
    while Current.Kind in [kwConst, kwVolatile, kwRestrict] do Inc(FIndex);
  end;
  CType.PointerDepth := PointerDepth;



  GroupedPointerDepth := 0;
  if Match(tkLParen) then
  begin
    if Match(tkStar) then
    begin


      ReturnValueType := CType;
      FunctionPointerDepth := 1;
      while Match(tkStar) do Inc(FunctionPointerDepth);
      while Current.Kind in [kwConst, kwVolatile, kwRestrict] do Inc(FIndex);
      if At(tkIdentifier) then
      begin
        AName := Current.Text;
        Inc(FIndex);
      end;
      Expect(tkRParen);
      if Match(tkLParen) then
      begin
        ParamList := NewOwnedFunctionParameterList;
        SetLength(ParamList^.Items, 0);
        FunctionVariadic := False;
        if At(kwVoid) and (Peek.Kind = tkRParen) then
          Inc(FIndex)
        else if not At(tkRParen) then
        begin
          repeat
            if Match(tkEllipsis) then
            begin
              FunctionVariadic := True;
              Break;
            end;
            ParamType := ParseType(ParamWasTypedef);
            ParamName := '';
            ParseDeclarator(ParamType, ParamName);
            if ParamType.Kind = ctArray then ParamType := DecayType(ParamType);
            N := Length(ParamList^.Items);
            SetLength(ParamList^.Items, N + 1);
            ParamList^.Items[N] := ParamType;
          until not Match(tkComma);
        end;
        Expect(tkRParen);
        CType := MakeType(ctFunction, False, FunctionPointerDepth);
        CType.ReturnType := NewOwnedMemberType;
        PCType(CType.ReturnType)^ := ReturnValueType;
        CType.ParamTypes := ParamList;
        CType.ParamCount := Length(ParamList^.Items);
        CType.IsVariadic := FunctionVariadic;
        Exit(True);
      end;
      { In `int (*m)[3]` the grouped pointer applies to whatever the suffix
        below builds, so the pointer level is added after the dimensions. }
      GroupedPointerDepth := FunctionPointerDepth;
    end
    else
    begin
      ParseDeclarator(CType, AName);
      Expect(tkRParen);
    end;
  end
  else if At(tkIdentifier) then
  begin
    AName := Current.Text;
    Inc(FIndex);
  end;

  { `int a[4][5]` is an array of 4 arrays of 5 ints, so the dimensions have to
    be applied innermost-first: collect them left to right, then wrap in
    reverse. }
  DimensionCount := 0;
  SetLength(Dimensions, 0);
  while Match(tkLBracket) do
  begin
    ArrayLength := 0;
    if not At(tkRBracket) then
    begin
      Expr := ParseConditional;
      try
        if not EvaluateParserIntegerConstant(Expr, ArrayLength) then
          RaiseCompileError(Expr.Pos,
            'array bound must be an integer constant expression');
      finally
        Expr.Free;
      end;
      if ArrayLength < 0 then
        RaiseCompileError(Current.Pos, 'array bound must not be negative');
    end;
    Expect(tkRBracket);
    if DimensionCount >= Length(Dimensions) then
      SetLength(Dimensions, (DimensionCount + 1) * 2);
    Dimensions[DimensionCount] := ArrayLength;
    Inc(DimensionCount);
  end;
  for DimensionIndex := DimensionCount - 1 downto 0 do
  begin
    ElementType := CType;
    CType := MakeArrayType(ElementType, Dimensions[DimensionIndex]);
  end;
  Inc(CType.PointerDepth, GroupedPointerDepth);

  Result := True;
end;

function TParser.ParseTypeofType: TCType;
var
  P: TSourcePos;
  Expr: TExpr;
  DummyWasTypedef: Boolean;
  SavedIndex: LongInt;
begin
  P := Expect(kwTypeof).Pos;
  Expr := nil;
  if Match(tkLParen) then
  begin
    SavedIndex := FIndex;
    if IsTypeStart then
    begin
      Result := ParseType(DummyWasTypedef);
      ParsePointerTail(Result);
      Expect(tkRParen);
      Exit;
    end;
    FIndex := SavedIndex;
    Expr := ParseExpression;
    Expect(tkRParen);
  end
  else
    Expr := ParseUnary;
  try
    if not InferParserExpressionType(Expr, Result) then
      RaiseCompileError(P,
        'cannot determine the type of this typeof expression');
  finally
    Expr.Free;
  end;
end;

function TParser.ParseType(out AWasTypedef: Boolean): TCType;
var
  UnsignedSeen, SignedSeen, BaseSeen: Boolean;
  LongCount: LongInt;
  T: TCType;
  StructInfo: PStructMembers;
  EnumVals: TEnumConstantArray;
  I, N: LongInt;
  StructFound: Boolean;

  procedure CompleteOwnedStructInfos(const AInfo: TStructMembers);
  var
    OwnedIndex: LongInt;
  begin
    if (AInfo.Name = '') or (Length(AInfo.Members) = 0) then Exit;
    for OwnedIndex := 0 to High(FOwnedStructInfos) do
      if (FOwnedStructInfos[OwnedIndex] <> nil) and
         (FOwnedStructInfos[OwnedIndex]^.Name = AInfo.Name) and
         (FOwnedStructInfos[OwnedIndex]^.IsUnion = AInfo.IsUnion) then
        FOwnedStructInfos[OwnedIndex]^ := AInfo;
  end;
begin
  AWasTypedef := False;
  FLastTypeWasStatic := False;
  UnsignedSeen := False;
  SignedSeen := False;
  BaseSeen := False;
  LongCount := 0;
  Result := MakeType(ctInt);

  while True do
  begin
    case Current.Kind of
      kwConst:
        begin
          Result.IsConst := True;
          Inc(FIndex);
        end;
      kwVolatile:
        begin
          Result.IsVolatile := True;
          Inc(FIndex);
        end;
      kwRestrict, kwExtern, kwAuto, kwRegister:
        Inc(FIndex);
      kwStatic:
        begin
          FLastTypeWasStatic := True;
          Inc(FIndex);
        end;
      kwInline:
        Inc(FIndex);
      kwTypedef:
        begin
          AWasTypedef := True;
          Inc(FIndex);
        end;
      kwUnsigned:
        begin
          UnsignedSeen := True;
          Inc(FIndex);
        end;
      kwSigned:
        begin
          SignedSeen := True;
          Inc(FIndex);
        end;
      kwVoid:
        begin
          Result.Kind := ctVoid;
          BaseSeen := True;
          Inc(FIndex);
        end;
      kwBool:
        begin
          Result.Kind := ctBool;
          BaseSeen := True;
          Inc(FIndex);
        end;
      kwChar:
        begin
          Result.Kind := ctChar;
          BaseSeen := True;
          Inc(FIndex);
        end;
      kwShort:
        begin
          Result.Kind := ctShort;
          BaseSeen := True;
          Inc(FIndex);
        end;
      kwInt:
        begin
          if LongCount = 0 then Result.Kind := ctInt;
          BaseSeen := True;
          Inc(FIndex);
        end;
      kwLong:
        begin
          Inc(LongCount);
          if BaseSeen and (Result.Kind = ctDouble) then
            Result.Kind := ctLongDouble
          else if LongCount >= 2 then Result.Kind := ctLongLong
          else Result.Kind := ctLong;
          BaseSeen := True;
          Inc(FIndex);
        end;
      kwFloat:
        begin
          Result.Kind := ctFloat;
          BaseSeen := True;
          Inc(FIndex);
        end;
      kwDouble:
        begin
          if LongCount > 0 then Result.Kind := ctLongDouble
          else Result.Kind := ctDouble;
          BaseSeen := True;
          Inc(FIndex);
        end;
      kwStruct:
        begin
          Inc(FIndex);
          StructInfo := ParseStructBody(False);
          StructFound := False;
          if StructInfo^.Name <> '' then
          begin
            for I := 0 to High(FStructs) do
              if FStructs[I].Name = StructInfo^.Name then
              begin
                StructFound := True;
                if Length(StructInfo^.Members) > 0 then
                  FStructs[I] := StructInfo^
                else
                  StructInfo^ := FStructs[I];
                Break;
              end;
            if not StructFound then
            begin
              N := Length(FStructs);
              SetLength(FStructs, N + 1);
              FStructs[N] := StructInfo^;
            end;
            CompleteOwnedStructInfos(StructInfo^);
          end;
          Result.StructInfo := NewOwnedStructInfo;
          Result.StructInfo^ := StructInfo^;
          Dispose(StructInfo);
          Result.Kind := ctStruct;
          BaseSeen := True;
        end;
      kwUnion:
        begin
          Inc(FIndex);
          StructInfo := ParseStructBody(True);
          StructFound := False;
          if StructInfo^.Name <> '' then
          begin
            for I := 0 to High(FStructs) do
              if FStructs[I].Name = StructInfo^.Name then
              begin
                StructFound := True;
                if Length(StructInfo^.Members) > 0 then
                  FStructs[I] := StructInfo^
                else
                  StructInfo^ := FStructs[I];
                Break;
              end;
            if not StructFound then
            begin
              N := Length(FStructs);
              SetLength(FStructs, N + 1);
              FStructs[N] := StructInfo^;
            end;
            CompleteOwnedStructInfos(StructInfo^);
          end;
          Result.StructInfo := NewOwnedStructInfo;
          Result.StructInfo^ := StructInfo^;
          Dispose(StructInfo);
          Result.Kind := ctUnion;
          BaseSeen := True;
        end;
      kwEnum:
        begin
          Inc(FIndex);
          EnumVals := ParseEnumBody;
          SetLength(Result.EnumConstants, Length(EnumVals));
          for I := 0 to High(EnumVals) do
            Result.EnumConstants[I] := EnumVals[I];
          Result.Kind := ctEnum;
          BaseSeen := True;
        end;
      kwTypeof:
        begin
          T := ParseTypeofType;
          T.IsConst := T.IsConst or Result.IsConst;
          T.IsVolatile := T.IsVolatile or Result.IsVolatile;
          Result := T;
          BaseSeen := True;
        end;
      tkIdentifier:
        begin
          if (not BaseSeen) and FindTypedef(Current.Text, T) then
          begin
            Result := T;
            BaseSeen := True;
            Inc(FIndex);
          end
          else if (not BaseSeen) and FindStruct(Current.Text, StructInfo) then
          begin
            Result.StructInfo := NewOwnedStructInfo;
            Result.StructInfo^ := StructInfo^;
            if StructInfo^.IsUnion then Result.Kind := ctUnion
            else Result.Kind := ctStruct;
            BaseSeen := True;
            Inc(FIndex);
          end
          else
            Break;
        end;
    else
      Break;
    end;
  end;

  if not BaseSeen then
  begin
    if UnsignedSeen or SignedSeen then Result.Kind := ctInt
    else RaiseCompileError(Current.Pos, 'expected a type name');
  end;
  if UnsignedSeen and SignedSeen then
    RaiseCompileError(Current.Pos, 'both signed and unsigned were specified');
  if UnsignedSeen then Result.IsUnsigned := True;
end;

{ Trailing part of an abstract declarator, as used by sizeof, alignof and
  casts: pointer stars followed by array bounds, e.g. `int *[4]`. }
procedure TParser.ParsePointerTail(var CType: TCType);
var
  Dimensions: array of Int64;
  DimensionCount, DimensionIndex: LongInt;
  ArrayLength: Int64;
  Expr: TExpr;
  ElementType: TCType;
begin
  while Match(tkStar) do
  begin
    Inc(CType.PointerDepth);
    while Current.Kind in [kwConst, kwVolatile, kwRestrict] do Inc(FIndex);
  end;

  DimensionCount := 0;
  SetLength(Dimensions, 0);
  while At(tkLBracket) do
  begin
    Inc(FIndex);
    ArrayLength := 0;
    if not At(tkRBracket) then
    begin
      Expr := ParseConditional;
      try
        if not EvaluateParserIntegerConstant(Expr, ArrayLength) then
          RaiseCompileError(Expr.Pos,
            'array bound must be an integer constant expression');
      finally
        Expr.Free;
      end;
      if ArrayLength < 0 then
        RaiseCompileError(Current.Pos, 'array bound must not be negative');
    end;
    Expect(tkRBracket);
    if DimensionCount >= Length(Dimensions) then
      SetLength(Dimensions, (DimensionCount + 1) * 2);
    Dimensions[DimensionCount] := ArrayLength;
    Inc(DimensionCount);
  end;
  for DimensionIndex := DimensionCount - 1 downto 0 do
  begin
    ElementType := CType;
    CType := MakeArrayType(ElementType, Dimensions[DimensionIndex]);
  end;
end;

function TParser.ParseStructBody(AIsUnion: Boolean): PStructMembers;
var
  Name: string;
  TotalSize, MaxAlign, FieldAlign, FieldSize, Offset: LongInt;
  UnitOffset, UnitSize, UnitAlign, UnitBitsUsed: LongInt;
  Members: TStructMemberArray;
  WasTypedef: Boolean;
  BaseMemberType, MemberType: TCType;
  MemberName: string;
  I: LongInt;
  MemberTypePtr: PCType;
  IsBitField: Boolean;
  BitWidthValue: Int64;
  BitWidthExpr: TExpr;
  BitOffset: LongInt;
begin
  New(Result);
  Result^.Name := '';
  SetLength(Result^.Members, 0);
  Result^.Size := 0;
  Result^.Align := 1;
  Result^.IsUnion := AIsUnion;

  if At(tkIdentifier) then
  begin
    Name := Current.Text;
    Inc(FIndex);
    Result^.Name := Name;
    if not At(tkLBrace) then Exit;
  end;

  Expect(tkLBrace);
  SetLength(Members, 0);
  TotalSize := 0;
  MaxAlign := 1;
  UnitOffset := -1;
  UnitSize := 0;
  UnitAlign := 1;
  UnitBitsUsed := 0;

  while not At(tkRBrace) do
  begin
    BaseMemberType := ParseType(WasTypedef);
    repeat
      MemberType := BaseMemberType;
      MemberName := '';
      if not At(tkColon) then ParseDeclarator(MemberType, MemberName);
      IsBitField := Match(tkColon);
      BitOffset := 0;
      BitWidthValue := 0;

      if IsBitField then
      begin
        if not IsIntegerType(MemberType) or (MemberType.PointerDepth <> 0) then
          RaiseCompileError(Current.Pos,
            'bit-field base type must be an integer type');
        BitWidthExpr := ParseConditional;
        try
          if not EvaluateParserIntegerConstant(BitWidthExpr, BitWidthValue) then
            RaiseCompileError(BitWidthExpr.Pos,
              'bit-field width must be an integer constant expression');
        finally
          BitWidthExpr.Free;
        end;
        FieldSize := StorageSize(MemberType);
        FieldAlign := StorageAlign(MemberType);
        if (BitWidthValue < 0) or (BitWidthValue > FieldSize * 8) then
          RaiseCompileError(Current.Pos, 'bit-field width exceeds its base type');
        if (BitWidthValue = 0) and (MemberName <> '') then
          RaiseCompileError(Current.Pos, 'named bit-field has zero width');
        if FieldAlign > MaxAlign then MaxAlign := FieldAlign;

        if AIsUnion then
        begin
          Offset := 0;
          BitOffset := 0;
          if FieldSize > TotalSize then TotalSize := FieldSize;
        end
        else if BitWidthValue = 0 then
        begin
          TotalSize := ((TotalSize + FieldAlign - 1) div FieldAlign) * FieldAlign;
          UnitOffset := -1;
          UnitSize := 0;
          UnitAlign := 1;
          UnitBitsUsed := 0;
          Offset := TotalSize;
        end
        else
        begin
          if (UnitOffset < 0) or (UnitSize <> FieldSize) or
            (UnitAlign <> FieldAlign) or
            (UnitBitsUsed + BitWidthValue > UnitSize * 8) then
          begin
            TotalSize := ((TotalSize + FieldAlign - 1) div FieldAlign) * FieldAlign;
            UnitOffset := TotalSize;
            UnitSize := FieldSize;
            UnitAlign := FieldAlign;
            UnitBitsUsed := 0;
            Inc(TotalSize, FieldSize);
          end;
          Offset := UnitOffset;
          BitOffset := UnitBitsUsed;
          Inc(UnitBitsUsed, LongInt(BitWidthValue));
        end;


        if MemberName = '' then Continue;
      end
      else
      begin
        if (MemberName = '') and
           not (MemberType.Kind in [ctStruct, ctUnion]) then
          RaiseCompileError(Current.Pos, 'expected a struct or union member name');
        UnitOffset := -1;
        UnitSize := 0;
        UnitAlign := 1;
        UnitBitsUsed := 0;
        FieldSize := StorageSize(MemberType);
        FieldAlign := StorageAlign(MemberType);
        if FieldAlign > MaxAlign then MaxAlign := FieldAlign;
        if AIsUnion then
          Offset := 0
        else
          Offset := ((TotalSize + FieldAlign - 1) div FieldAlign) * FieldAlign;
        if AIsUnion then
        begin
          if FieldSize > TotalSize then TotalSize := FieldSize;
        end
        else
          TotalSize := Offset + FieldSize;
      end;

      I := Length(Members);
      SetLength(Members, I + 1);
      Members[I].Name := MemberName;
      MemberTypePtr := NewOwnedMemberType;
      MemberTypePtr^ := MemberType;
      Members[I].CType := MemberTypePtr;
      Members[I].Offset := Offset;
      Members[I].Width := FieldSize;
      Members[I].IsBitField := IsBitField;
      Members[I].BitOffset := BitOffset;
      Members[I].BitWidth := LongInt(BitWidthValue);
    until not Match(tkComma);
    Expect(tkSemicolon);
  end;
  Expect(tkRBrace);

  if TotalSize > 0 then
    TotalSize := ((TotalSize + MaxAlign - 1) div MaxAlign) * MaxAlign;

  SetLength(Result^.Members, Length(Members));
  for I := 0 to High(Members) do
    Result^.Members[I] := Members[I];
  Result^.Size := TotalSize;
  Result^.Align := MaxAlign;
end;

function TParser.ParseEnumBody: TEnumConstantArray;
var
  I: LongInt;
  EnumVal, ExplicitValue: Int64;
  Name: string;
  ValueExpr: TExpr;
  NamePos: TSourcePos;
begin
  Result := nil;
  EnumVal := 0;
  if At(tkIdentifier) and (Peek.Kind in [tkLBrace, tkIdentifier]) then
    Inc(FIndex);
  if At(tkLBrace) then
  begin
    Inc(FIndex);
    while not At(tkRBrace) do
    begin
      NamePos := Current.Pos;
      Name := Expect(tkIdentifier, 'enumerator name').Text;
      if Match(tkAssign) then
      begin
        ValueExpr := ParseConditional;
        try
          if not EvaluateParserIntegerConstant(ValueExpr, ExplicitValue) then
            RaiseCompileError(ValueExpr.Pos,
              'enumerator value must be an integer constant expression');
          EnumVal := ExplicitValue;
        finally
          ValueExpr.Free;
        end;
      end;
      I := Length(Result);
      SetLength(Result, I + 1);
      Result[I].Name := Name;
      Result[I].Value := EnumVal;
      AddIntegerConstant(Name, EnumVal, NamePos);
      Inc(EnumVal);
      if not Match(tkComma) then Break;
      if At(tkRBrace) then Break;
    end;
    Expect(tkRBrace);
  end;
end;

function TParser.ParseGenericSelection: TExpr;
var
  P: TSourcePos;
  Association, ValueExpr: TExpr;
  AssociationType: TCType;
  WasTypedef: Boolean;
  N: LongInt;
begin
  P := Current.Pos;
  Expect(kwGeneric);
  Expect(tkLParen);
  Result := TExpr.Create(ekGeneric, P);
  try
    Result.Left := ParseAssignment;
    Expect(tkComma);
    repeat
      Association := TExpr.Create(ekCast, Current.Pos);
      try
        if Match(kwDefault) then
          Association.Text := 'default'
        else
        begin
          AssociationType := ParseType(WasTypedef);
          ParsePointerTail(AssociationType);
          Association.CType := AssociationType;
        end;
        Expect(tkColon);
        ValueExpr := ParseAssignment;
        Association.Left := ValueExpr;
        N := Length(Result.Args);
        SetLength(Result.Args, N + 1);
        Result.Args[N] := Association;
        Association := nil;
      finally
        Association.Free;
      end;
    until not Match(tkComma);
    Expect(tkRParen);
  except
    Result.Free;
    raise;
  end;
end;

function TParser.ParseBuiltinOffsetof: TExpr;
var
  P: TSourcePos;
  WasTypedef: Boolean;
  CurrentType, ElementType: TCType;
  Member: TStructMember;
  MemberName: string;
  OffsetValue, IndexValue: Int64;
  IndexExpr: TExpr;
begin
  P := Current.Pos;
  Inc(FIndex);
  Expect(tkLParen);
  CurrentType := ParseType(WasTypedef);
  ParsePointerTail(CurrentType);
  Expect(tkComma);
  OffsetValue := 0;

  while True do
  begin
    MemberName := Expect(tkIdentifier, 'member designator').Text;
    if not (CurrentType.Kind in [ctStruct, ctUnion]) or
      (CurrentType.StructInfo = nil) then
      RaiseCompileError(P,
        '__builtin_offsetof member designator requires an aggregate type');
    if not FindMember(CurrentType, MemberName, Member) then
      RaiseCompileError(P, 'aggregate has no member ''' + MemberName + '''');
    if Member.IsBitField then
      RaiseCompileError(P, '__builtin_offsetof cannot name a bit-field');
    Inc(OffsetValue, Member.Offset);
    CurrentType := PCType(Member.CType)^;

    while Match(tkLBracket) do
    begin
      IndexExpr := ParseConditional;
      try
        if not EvaluateParserIntegerConstant(IndexExpr, IndexValue) then
          RaiseCompileError(IndexExpr.Pos,
            '__builtin_offsetof array index must be an integer constant expression');
      finally
        IndexExpr.Free;
      end;
      if IndexValue < 0 then
        RaiseCompileError(P, '__builtin_offsetof array index cannot be negative');
      if CurrentType.Kind <> ctArray then
        RaiseCompileError(P, '__builtin_offsetof subscript requires array member');
      ElementType := ElementTypeOf(CurrentType);
      Inc(OffsetValue, IndexValue * StorageSize(ElementType));
      CurrentType := ElementType;
      Expect(tkRBracket);
    end;

    if not Match(tkDot) then Break;
  end;
  Expect(tkRParen);
  Result := TExpr.Create(ekInteger, P);
  Result.IntValue := OffsetValue;
  Result.Text := 'UL';
end;

function TParser.ParsePrimary: TExpr;
var
  Tok: TToken;
  CompoundExpr: TExpr;
  IntegerConstantValue: Int64;
  N: LongInt;
  DesignatorName: string;
begin
  Tok := Current;
  if At(kwGeneric) then Exit(ParseGenericSelection);
  if Match(kwNullptr) then
  begin
    Result := TExpr.Create(ekNullptr, Tok.Pos);
    Exit;
  end;
  if Match(tkInteger) then
  begin
    Result := TExpr.Create(ekInteger, Tok.Pos);
    Result.IntValue := Tok.IntValue;
    Result.Text := Tok.Text;
    Exit;
  end;
  if Match(tkFloat) then
  begin
    Result := TExpr.Create(ekFloat, Tok.Pos);
    Result.FloatValue := Tok.FloatValue;
    Result.Text := Tok.Text;
    Exit;
  end;
  if Match(tkString) then
  begin
    Result := TExpr.Create(ekString, Tok.Pos);
    Result.Text := Tok.Text;



    while At(tkString) do
    begin
      Result.Text := Result.Text + Current.Text;
      Inc(FIndex);
    end;
    Exit;
  end;
  if At(tkIdentifier) and (Tok.Text = '__builtin_offsetof') then
    Exit(ParseBuiltinOffsetof);
  if Match(tkIdentifier) then
  begin



    if FindIntegerConstant(Tok.Text, IntegerConstantValue) then
    begin
      Result := TExpr.Create(ekInteger, Tok.Pos);
      Result.IntValue := IntegerConstantValue;
      Result.Text := '';
      Exit;
    end;
    Result := TExpr.Create(ekVariable, Tok.Pos);
    Result.Text := Tok.Text;
    Exit;
  end;
  if Match(tkLParen) then
  begin



    Result := ParseExpression;
    Expect(tkRParen);
    Exit;
  end;
  if Match(tkLBrace) then
  begin
    Result := TExpr.Create(ekCompoundLit, Tok.Pos);
    while not At(tkRBrace) and not At(tkEOF) do
    begin
      if Match(tkDot) then
      begin
        { Designated member initializer; sema resolves the name and reorders. }
        DesignatorName := Expect(tkIdentifier, 'initializer member').Text;
        Expect(tkAssign);
        CompoundExpr := ParseAssignment;
        CompoundExpr.Designator := DesignatorName;
      end
      else
        CompoundExpr := ParseAssignment;
      N := Length(Result.Args);
      SetLength(Result.Args, N + 1);
      Result.Args[N] := CompoundExpr;
      if not Match(tkComma) then Break;
    end;
    Expect(tkRBrace);
    Exit;
  end;
  RaiseCompileError(Tok.Pos, 'expected expression');
  Result := nil;
end;

function TParser.ParsePostfix: TExpr;
var
  Base, IndexExpr, Node, Arg, Selected: TExpr;
  N: LongInt;
  MemberName, CalleeName: string;
  DeclaredType, VaArgumentType: TCType;
  DeclaredIsFunction: Boolean;
  VaTypeWasTypedef: Boolean;
  VaTypeName: string;
  ConstantValue: Int64;
  CallPos: TSourcePos;

  procedure RequireBuiltinArguments(const AName: string;
    AExpected: LongInt; ACall: TExpr);
  begin
    if Length(ACall.Args) <> AExpected then
      RaiseCompileError(ACall.Pos, AName + ' expects ' +
        IntToStr(AExpected) + ' argument(s)');
  end;

  function DetachArgument(ACall: TExpr; AIndex: LongInt): TExpr;
  begin
    Result := ACall.Args[AIndex];
    ACall.Args[AIndex] := nil;
  end;

begin
  Base := ParsePrimary;
  while True do
  begin
    if Match(tkLParen) then
    begin
      CallPos := Base.Pos;
      CalleeName := '';
      if Base.Kind = ekVariable then CalleeName := Base.Text;
      Node := TExpr.Create(ekCall, CallPos);
      Node.Left := Base;
      if Base.Kind = ekVariable then
      begin





        if FindDeclaredType(Base.Text, DeclaredType, DeclaredIsFunction) then
        begin
          if DeclaredIsFunction then Node.Text := Base.Text
          else Node.Text := '';
        end
        else
          Node.Text := Base.Text;
      end
      else
        Node.Text := '';
      if CalleeName = '__builtin_va_arg' then
      begin
        if At(tkRParen) then
          RaiseCompileError(CallPos,
            '__builtin_va_arg expects a list and a type');
        Arg := ParseAssignment;
        N := Length(Node.Args);
        SetLength(Node.Args, N + 1);
        Node.Args[N] := Arg;
        Expect(tkComma, ''','' before variadic argument type');
        VaArgumentType := ParseType(VaTypeWasTypedef);
        VaTypeName := '';
        ParseDeclarator(VaArgumentType, VaTypeName);
        if VaTypeName <> '' then
          RaiseCompileError(CallPos,
            '__builtin_va_arg requires a type name, not a declaration');
        Expect(tkRParen);
        Node.OperationType := VaArgumentType;
        Base := Node;
        Continue;
      end;
      if not At(tkRParen) then
      repeat
        Arg := ParseAssignment;
        N := Length(Node.Args);
        SetLength(Node.Args, N + 1);
        Node.Args[N] := Arg;
      until not Match(tkComma);
      Expect(tkRParen);




      if CalleeName = '__builtin_expect' then
      begin
        RequireBuiltinArguments(CalleeName, 2, Node);
        if not EvaluateParserIntegerConstant(Node.Args[1], ConstantValue) then
          RaiseCompileError(Node.Args[1].Pos,
            '__builtin_expect prediction must be an integer constant expression');
        Selected := DetachArgument(Node, 0);
        Node.Free;
        Base := Selected;
        Continue;
      end;
      if CalleeName = '__builtin_expect_with_probability' then
      begin
        RequireBuiltinArguments(CalleeName, 3, Node);
        if not EvaluateParserIntegerConstant(Node.Args[1], ConstantValue) then
          RaiseCompileError(Node.Args[1].Pos,
            '__builtin_expect_with_probability prediction must be an integer constant expression');
        if not (Node.Args[2].Kind in [ekInteger, ekFloat]) then
          RaiseCompileError(Node.Args[2].Pos,
            '__builtin_expect_with_probability probability must be constant');
        if ((Node.Args[2].Kind = ekInteger) and
            ((Node.Args[2].IntValue < 0) or (Node.Args[2].IntValue > 1))) or
           ((Node.Args[2].Kind = ekFloat) and
            ((Node.Args[2].FloatValue < 0.0) or
             (Node.Args[2].FloatValue > 1.0))) then
          RaiseCompileError(Node.Args[2].Pos,
            '__builtin_expect_with_probability probability must be between 0 and 1');
        Selected := DetachArgument(Node, 0);
        Node.Free;
        Base := Selected;
        Continue;
      end;
      if CalleeName = '__builtin_constant_p' then
      begin
        RequireBuiltinArguments(CalleeName, 1, Node);
        if EvaluateParserIntegerConstant(Node.Args[0], ConstantValue) then
          ConstantValue := 1
        else
          ConstantValue := 0;
        Node.Free;
        Base := TExpr.Create(ekInteger, CallPos);
        Base.IntValue := ConstantValue;
        Base.Text := '';
        Continue;
      end;
      if CalleeName = '__builtin_choose_expr' then
      begin
        RequireBuiltinArguments(CalleeName, 3, Node);
        if not EvaluateParserIntegerConstant(Node.Args[0], ConstantValue) then
          RaiseCompileError(Node.Args[0].Pos,
            '__builtin_choose_expr condition must be an integer constant expression');
        if ConstantValue <> 0 then
          Selected := DetachArgument(Node, 1)
        else
          Selected := DetachArgument(Node, 2);
        Node.Free;
        Base := Selected;
        Continue;
      end;
      if (CalleeName = '__builtin_trap') or
         (CalleeName = '__builtin_unreachable') then
      begin
        RequireBuiltinArguments(CalleeName, 0, Node);
        Node.Left.Free;
        Node.Left := nil;
        Node.Kind := ekTrap;
        Node.Text := CalleeName;
        Base := Node;
        Continue;
      end;

      Base := Node;
      Continue;
    end;
    if Match(tkLBracket) then
    begin
      IndexExpr := ParseExpression;
      Expect(tkRBracket);
      Node := TExpr.Create(ekIndex, Base.Pos);
      Node.Left := Base;
      Node.Right := IndexExpr;
      Base := Node;
      Continue;
    end;
    if Match(tkDot) then
    begin
      Node := TExpr.Create(ekMember, Base.Pos);
      Node.Left := Base;
      MemberName := Expect(tkIdentifier, 'member name').Text;
      Node.Text := MemberName;
      Base := Node;
      Continue;
    end;
    if Match(tkArrow) then
    begin
      Node := TExpr.Create(ekArrow, Base.Pos);
      Node.Left := Base;
      MemberName := Expect(tkIdentifier, 'member name').Text;
      Node.Text := MemberName;
      Base := Node;
      Continue;
    end;
    if Match(tkIncrement) then
    begin
      Node := TExpr.Create(ekPostInc, Base.Pos);
      Node.Left := Base;
      Base := Node;
      Continue;
    end;
    if Match(tkDecrement) then
    begin
      Node := TExpr.Create(ekPostDec, Base.Pos);
      Node.Left := Base;
      Base := Node;
      Continue;
    end;
    Break;
  end;
  Result := Base;
end;

function TParser.ParseUnary: TExpr;
var
  Tok: TToken;
  Node: TExpr;
  ParsedType: TCType;
  DummyWasTypedef: Boolean;
  SavedIndex: LongInt;
begin
  Result := nil;
  Tok := Current;

  if At(tkLParen) then
  begin
    SavedIndex := FIndex;
    Inc(FIndex);
    if IsTypeStart then
    begin
      ParsedType := ParseType(DummyWasTypedef);
      ParsePointerTail(ParsedType);
      Expect(tkRParen);
      Result := Self.ParseUnary();
      if Result <> nil then
      begin
        Node := TExpr.Create(ekCast, Tok.Pos);
        Node.Left := Result;
        Node.CType := ParsedType;
        Exit(Node);
      end;
    end;
    FIndex := SavedIndex;
  end;

  if Match(tkPlus) then
  begin
    Node := TExpr.Create(ekUnary, Tok.Pos);
    Node.UnaryOp := uoPositive;
    Node.Left := Self.ParseUnary();
    Exit(Node);
  end;
  if Match(tkMinus) then
  begin
    Node := TExpr.Create(ekUnary, Tok.Pos);
    Node.UnaryOp := uoNegative;
    Node.Left := Self.ParseUnary();
    Exit(Node);
  end;
  if Match(tkBang) then
  begin
    Node := TExpr.Create(ekUnary, Tok.Pos);
    Node.UnaryOp := uoLogicalNot;
    Node.Left := Self.ParseUnary();
    Exit(Node);
  end;
  if Match(tkTilde) then
  begin
    Node := TExpr.Create(ekUnary, Tok.Pos);
    Node.UnaryOp := uoBitwiseNot;
    Node.Left := Self.ParseUnary();
    Exit(Node);
  end;
  if Match(tkAmp) then
  begin
    Node := TExpr.Create(ekAddress, Tok.Pos);
    Node.Left := Self.ParseUnary();
    Exit(Node);
  end;
  if Match(tkStar) then
  begin
    Node := TExpr.Create(ekDeref, Tok.Pos);
    Node.Left := Self.ParseUnary();
    Exit(Node);
  end;
  if Match(tkIncrement) then
  begin
    Node := TExpr.Create(ekPreInc, Tok.Pos);
    Node.Left := Self.ParseUnary();
    Exit(Node);
  end;
  if Match(tkDecrement) then
  begin
    Node := TExpr.Create(ekPreDec, Tok.Pos);
    Node.Left := Self.ParseUnary();
    Exit(Node);
  end;
  if Match(kwSizeof) then
  begin
    if At(tkLParen) then
    begin
      SavedIndex := FIndex;
      Inc(FIndex);
      if IsTypeStart then
      begin
        ParsedType := ParseType(DummyWasTypedef);
        ParsePointerTail(ParsedType);
        Expect(tkRParen);
        Result := TExpr.Create(ekInteger, Tok.Pos);
        Result.IntValue := CTypeSize(ParsedType);
        Result.Text := 'UL';
        Exit;
      end;
      FIndex := SavedIndex;
    end;
    Node := TExpr.Create(ekSizeof, Tok.Pos);
    Node.Left := Self.ParseUnary();
    if InferParserExpressionType(Node.Left, ParsedType) then
      Node.IntValue := CTypeSize(ParsedType);
    Result := Node;
    Exit;
  end;
  if Match(kwAlignof) then
  begin
    if At(tkLParen) then
    begin
      SavedIndex := FIndex;
      Inc(FIndex);
      if IsTypeStart then
      begin
        ParsedType := ParseType(DummyWasTypedef);
        ParsePointerTail(ParsedType);
        Expect(tkRParen);
        Result := TExpr.Create(ekInteger, Tok.Pos);
        Result.IntValue := CTypeAlign(ParsedType);
        Result.Text := 'UL';
        Exit;
      end;
      FIndex := SavedIndex;
    end;
    Node := TExpr.Create(ekAlignof, Tok.Pos);
    Node.Left := Self.ParseUnary();
    if InferParserExpressionType(Node.Left, ParsedType) then
      Node.IntValue := CTypeAlign(ParsedType);
    Result := Node;
    Exit;
  end;
  Result := ParsePostfix;
end;

function MakeBinary(AOp: TBinaryOp; ALeft, ARight: TExpr): TExpr;
begin
  Result := TExpr.Create(ekBinary, ALeft.Pos);
  Result.BinaryOp := AOp;
  Result.Left := ALeft;
  Result.Right := ARight;
end;

function TParser.ParseMultiplicative: TExpr;
var
  R: TExpr;
begin
  Result := ParseUnary;
  while Current.Kind in [tkStar, tkSlash, tkPercent] do
  begin
    if Match(tkStar) then R := MakeBinary(boMul, Result, ParseUnary)
    else if Match(tkSlash) then R := MakeBinary(boDiv, Result, ParseUnary)
    else begin Expect(tkPercent); R := MakeBinary(boMod, Result, ParseUnary); end;
    Result := R;
  end;
end;

function TParser.ParseAdditive: TExpr;
begin
  Result := ParseMultiplicative;
  while Current.Kind in [tkPlus, tkMinus] do
    if Match(tkPlus) then Result := MakeBinary(boAdd, Result, ParseMultiplicative)
    else begin Expect(tkMinus); Result := MakeBinary(boSub, Result, ParseMultiplicative); end;
end;

function TParser.ParseShift: TExpr;
begin
  Result := ParseAdditive;
  while Current.Kind in [tkShiftLeft, tkShiftRight] do
    if Match(tkShiftLeft) then Result := MakeBinary(boShiftLeft, Result, ParseAdditive)
    else begin Expect(tkShiftRight); Result := MakeBinary(boShiftRight, Result, ParseAdditive); end;
end;

function TParser.ParseRelational: TExpr;
begin
  Result := ParseShift;
  while Current.Kind in [tkLess, tkLessEqual, tkGreater, tkGreaterEqual] do
  begin
    if Match(tkLess) then Result := MakeBinary(boLess, Result, ParseShift)
    else if Match(tkLessEqual) then Result := MakeBinary(boLessEqual, Result, ParseShift)
    else if Match(tkGreater) then Result := MakeBinary(boGreater, Result, ParseShift)
    else begin Expect(tkGreaterEqual); Result := MakeBinary(boGreaterEqual, Result, ParseShift); end;
  end;
end;

function TParser.ParseEquality: TExpr;
begin
  Result := ParseRelational;
  while Current.Kind in [tkEqual, tkNotEqual] do
    if Match(tkEqual) then Result := MakeBinary(boEqual, Result, ParseRelational)
    else begin Expect(tkNotEqual); Result := MakeBinary(boNotEqual, Result, ParseRelational); end;
end;

function TParser.ParseBitAnd: TExpr;
begin
  Result := ParseEquality;
  while Match(tkAmp) do Result := MakeBinary(boBitAnd, Result, ParseEquality);
end;

function TParser.ParseBitXor: TExpr;
begin
  Result := ParseBitAnd;
  while Match(tkCaret) do Result := MakeBinary(boBitXor, Result, ParseBitAnd);
end;

function TParser.ParseBitOr: TExpr;
begin
  Result := ParseBitXor;
  while Match(tkPipe) do Result := MakeBinary(boBitOr, Result, ParseBitXor);
end;

function TParser.ParseLogicalAnd: TExpr;
begin
  Result := ParseBitOr;
  while Match(tkLogicalAnd) do Result := MakeBinary(boLogicalAnd, Result, ParseBitOr);
end;

function TParser.ParseLogicalOr: TExpr;
begin
  Result := ParseLogicalAnd;
  while Match(tkLogicalOr) do Result := MakeBinary(boLogicalOr, Result, ParseLogicalAnd);
end;

function TParser.ParseConditional: TExpr;
var
  Node: TExpr;
begin
  Result := ParseLogicalOr;
  if Match(tkQuestion) then
  begin
    Node := TExpr.Create(ekConditional, Result.Pos);
    Node.Left := Result;
    Node.Right := ParseExpression;
    Expect(tkColon);
    Node.Third := Self.ParseConditional();
    Result := Node;
  end;
end;

function TParser.ParseAssignment: TExpr;
var
  LeftExpr, Node: TExpr;
  Op: TAssignOp;
begin
  LeftExpr := ParseConditional;
  case Current.Kind of
    tkAssign: Op := aoAssign;
    tkPlusAssign: Op := aoAdd;
    tkMinusAssign: Op := aoSub;
    tkStarAssign: Op := aoMul;
    tkSlashAssign: Op := aoDiv;
    tkPercentAssign: Op := aoMod;
    tkAmpAssign: Op := aoBitAnd;
    tkPipeAssign: Op := aoBitOr;
    tkCaretAssign: Op := aoBitXor;
    tkShiftLeftAssign: Op := aoShiftLeft;
    tkShiftRightAssign: Op := aoShiftRight;
  else
    Exit(LeftExpr);
  end;
  Inc(FIndex);
  Node := TExpr.Create(ekAssign, LeftExpr.Pos);
  Node.AssignOp := Op;
  Node.Left := LeftExpr;
  Node.Right := Self.ParseAssignment();
  Result := Node;
end;

function TParser.ParseExpression: TExpr;
begin
  Result := ParseAssignment;
  while Match(tkComma) do
    Result := MakeBinary(boComma, Result, ParseAssignment);
end;

function TParser.ParseDeclarationStatement(AConsumeSemicolon: Boolean): TStmt;
var
  Pos: TSourcePos;
  WasTypedef, DeclarationIsStatic: Boolean;
  BaseType, DeclType, ElementType: TCType;
  DeclName: string;
  Container, Decl: TStmt;
  N: LongInt;

  function ParseInitializer(const AType: TCType): TExpr;
  var
    Item: TExpr;
    ItemCount: LongInt;
    MemberName: string;
  begin
    if not Match(tkAssign) then Exit(nil);
    if not Match(tkLBrace) then Exit(ParseAssignment);
    Result := TExpr.Create(ekCompoundLit, Pos);
    Result.CType := AType;
    while not At(tkRBrace) and not At(tkEOF) do
    begin


      if Match(tkDot) then
      begin
        MemberName := Expect(tkIdentifier, 'initializer member').Text;
        Expect(tkAssign);
        Item := ParseAssignment;
        Item.Designator := MemberName;
      end
      else
        Item := ParseAssignment;
      ItemCount := Length(Result.Args);
      SetLength(Result.Args, ItemCount + 1);
      Result.Args[ItemCount] := Item;
      if not Match(tkComma) then Break;
      if At(tkRBrace) then Break;
    end;
    Expect(tkRBrace);
  end;

begin
  Pos := Current.Pos;
  BaseType := ParseType(WasTypedef);
  DeclarationIsStatic := FLastTypeWasStatic;
  Container := TStmt.Create(skBlock, Pos);
  Container.IsDeclarationGroup := True;
  try
    repeat
      DeclType := BaseType;
      DeclName := '';
      ParseDeclarator(DeclType, DeclName);
      if DeclName = '' then
        RaiseCompileError(Current.Pos, 'declaration requires an identifier');

      if WasTypedef then
      begin
        AddTypedef(DeclName, DeclType);
        Decl := TStmt.Create(skEmpty, Pos);
      end
      else
      begin
        Decl := TStmt.Create(skDecl, Pos);
        Decl.Name := DeclName;
        Decl.CType := DeclType;
        Decl.IsStatic := DeclarationIsStatic;
        AddDeclaredType(DeclName, DeclType, FScopeDepth, False);
        Decl.Expr := ParseInitializer(DeclType);

        if (Decl.CType.Kind = ctArray) and (Decl.CType.ArrayLength = 0) then
        begin
          if (Decl.Expr <> nil) and (Decl.Expr.Kind = ekCompoundLit) then
            Decl.CType.ArrayLength := Length(Decl.Expr.Args)
          else if (Decl.Expr <> nil) and (Decl.Expr.Kind = ekString) and
            (Decl.CType.ElementKind = ctChar) and
            (Decl.CType.ElementPointerDepth = 0) then
            Decl.CType.ArrayLength := Length(Decl.Expr.Text) + 1
          else
            RaiseCompileError(Pos,
              'incomplete local array requires an initializer');
        end;

        AddDeclaredType(DeclName, Decl.CType, FScopeDepth, False);

        if Decl.CType.Kind = ctArray then
        begin
          ElementType := ElementTypeOf(Decl.CType);
          if StorageSize(ElementType) <= 0 then
            RaiseCompileError(Pos, 'array has incomplete element type');
        end;
      end;

      N := Length(Container.Children);
      SetLength(Container.Children, N + 1);
      Container.Children[N] := Decl;
    until not Match(tkComma);

    if AConsumeSemicolon then Expect(tkSemicolon);
    if Length(Container.Children) = 1 then
    begin
      Result := Container.Children[0];
      Container.Children[0] := nil;
      SetLength(Container.Children, 0);
      Container.Free;
    end
    else
      Result := Container;
  except
    Container.Free;
    raise;
  end;
end;

function TParser.ParseStaticAssertion: TStmt;
var
  P: TSourcePos;
begin
  P := Current.Pos;
  Expect(kwStaticAssert);
  Expect(tkLParen);
  Result := TStmt.Create(skStaticAssert, P);
  try
    Result.Expr := ParseAssignment;
    if Match(tkComma) then
      Result.Name := Expect(tkString, 'static assertion message').Text;
    Expect(tkRParen);
    Expect(tkSemicolon);
  except
    Result.Free;
    raise;
  end;
end;

function TParser.ParseBlock: TStmt;
var
  S: TStmt;
  N: LongInt;
  P: TSourcePos;
begin
  P := Expect(tkLBrace).Pos;
  Result := TStmt.Create(skBlock, P);
  EnterScope;
  try
    while not At(tkRBrace) do
    begin
      if At(tkEOF) then RaiseCompileError(Current.Pos, 'unterminated block');
      S := ParseStatement;
      N := Length(Result.Children);
      SetLength(Result.Children, N + 1);
      Result.Children[N] := S;
    end;
    Expect(tkRBrace);
  finally
    LeaveScope;
  end;
end;

function TParser.ParseAsmStatement: TStmt;
var
  P: TSourcePos;
  Operand: TAsmOperand;
  N: LongInt;

  function ParseTemplateText: string;
  begin
    Result := '';
    if not At(tkString) then
      RaiseCompileError(Current.Pos, 'inline assembly requires a string template');
    while At(tkString) do
    begin
      Result := Result + Current.Text;
      Inc(FIndex);
    end;
  end;

  procedure AppendStringValue(var AValues: rcc_types.TStringArray;
    const AValue: string);
  var
    Count: LongInt;
  begin
    Count := Length(AValues);
    SetLength(AValues, Count + 1);
    AValues[Count] := AValue;
  end;

  function ParseOperand(AIsOutput: Boolean): TAsmOperand;
  begin
    Result := TAsmOperand.Create;
    try
      Result.IsOutput := AIsOutput;
      if Match(tkLBracket) then
      begin
        Result.Name := Expect(tkIdentifier, 'assembly operand name').Text;
        Expect(tkRBracket);
      end;
      Result.ConstraintText := Expect(tkString,
        'assembly operand constraint').Text;
      Expect(tkLParen);
      Result.Expr := ParseAssignment;
      Expect(tkRParen);
    except
      Result.Free;
      raise;
    end;
  end;

  procedure ParseOperandList(var AOperands: TAsmOperandArray;
    AIsOutput: Boolean);
  begin
    if At(tkColon) or At(tkRParen) then Exit;
    repeat
      Operand := ParseOperand(AIsOutput);
      N := Length(AOperands);
      SetLength(AOperands, N + 1);
      AOperands[N] := Operand;
    until not Match(tkComma);
  end;

  procedure ParseStringList(var AValues: rcc_types.TStringArray);
  begin
    if At(tkColon) or At(tkRParen) then Exit;
    repeat
      AppendStringValue(AValues, Expect(tkString,
        'assembly clobber name').Text);
    until not Match(tkComma);
  end;

  procedure ParseLabelList(var AValues: rcc_types.TStringArray);
  begin
    if At(tkRParen) then Exit;
    repeat
      AppendStringValue(AValues, Expect(tkIdentifier,
        'asm goto label').Text);
    until not Match(tkComma);
  end;

begin
  P := Expect(kwAsm).Pos;
  Result := TStmt.Create(skAsm, P);
  try
    while Current.Kind in [kwVolatile, kwInline, kwGoto] do
    begin
      if Current.Kind = kwVolatile then Result.AsmVolatile := True;
      if Current.Kind = kwGoto then Result.AsmGoto := True;
      Inc(FIndex);
    end;
    Expect(tkLParen);
    Result.AsmTemplate := ParseTemplateText;
    if Match(tkColon) then
    begin
      ParseOperandList(Result.AsmOutputs, True);
      if Match(tkColon) then
      begin
        ParseOperandList(Result.AsmInputs, False);
        if Match(tkColon) then
        begin
          ParseStringList(Result.AsmClobbers);
          if Match(tkColon) then
            ParseLabelList(Result.AsmLabels);
        end;
      end;
    end;
    Expect(tkRParen);
    Expect(tkSemicolon);
    if Result.AsmGoto and (Length(Result.AsmLabels) = 0) then
      RaiseCompileError(P, 'asm goto requires at least one target label');
  except
    Result.Free;
    raise;
  end;
end;

function TParser.ParseStatement: TStmt;
var
  P: TSourcePos;
  CaseVal: Int64;
  CaseExpr: TExpr;
begin
  P := Current.Pos;
  if At(tkLBrace) then Exit(ParseBlock);
  if Match(tkSemicolon) then Exit(TStmt.Create(skEmpty, P));
  if At(kwStaticAssert) then Exit(ParseStaticAssertion);
  if At(kwAsm) then Exit(ParseAsmStatement);
  if IsTypeStart then Exit(ParseDeclarationStatement(True));
  if Match(kwReturn) then
  begin
    Result := TStmt.Create(skReturn, P);
    if not At(tkSemicolon) then Result.Expr := ParseExpression;
    Expect(tkSemicolon);
    Exit;
  end;
  if Match(kwIf) then
  begin
    Result := TStmt.Create(skIf, P);
    Expect(tkLParen);
    Result.Expr := ParseExpression;
    Expect(tkRParen);
    Result.Body := Self.ParseStatement();
    if Match(kwElse) then Result.ElseBody := Self.ParseStatement();
    Exit;
  end;
  if Match(kwWhile) then
  begin
    Result := TStmt.Create(skWhile, P);
    Expect(tkLParen);
    Result.Expr := ParseExpression;
    Expect(tkRParen);
    Inc(FBreakableDepth);
    Inc(FContinueableDepth);
    Result.Body := Self.ParseStatement();
    Dec(FContinueableDepth);
    Dec(FBreakableDepth);
    Exit;
  end;
  if Match(kwDo) then
  begin
    Result := TStmt.Create(skDoWhile, P);
    Inc(FBreakableDepth);
    Inc(FContinueableDepth);
    Result.Body := Self.ParseStatement();
    Dec(FContinueableDepth);
    Dec(FBreakableDepth);
    Expect(kwWhile);
    Expect(tkLParen);
    Result.Expr := ParseExpression;
    Expect(tkRParen);
    Expect(tkSemicolon);
    Exit;
  end;
  if Match(kwFor) then
  begin
    Result := TStmt.Create(skFor, P);
    Expect(tkLParen);
    Inc(FBreakableDepth);
    Inc(FContinueableDepth);
    if IsTypeStart then
      Result.InitStmt := ParseDeclarationStatement(True)
    else if Match(tkSemicolon) then
      Result.InitStmt := nil
    else
    begin
      Result.InitStmt := TStmt.Create(skExpr, Current.Pos);
      Result.InitStmt.Expr := ParseExpression;
      Expect(tkSemicolon);
    end;
    if not At(tkSemicolon) then Result.Expr := ParseExpression;
    Expect(tkSemicolon);
    if not At(tkRParen) then Result.Expr2 := ParseExpression;
    Expect(tkRParen);
    Result.Body := Self.ParseStatement();
    Dec(FContinueableDepth);
    Dec(FBreakableDepth);
    Exit;
  end;
  if Match(kwSwitch) then
  begin
    Result := TStmt.Create(skSwitch, P);
    SetLength(FSwitchLabels, 0);
    FSwitchHasDefault := False;
    Inc(FInSwitch);
    Inc(FBreakableDepth);
    Expect(tkLParen);
    Result.Expr := ParseExpression;
    Expect(tkRParen);
    Result.Body := Self.ParseStatement();
    Dec(FBreakableDepth);
    Dec(FInSwitch);
    Exit;
  end;
  if Match(kwCase) then
  begin
    if FInSwitch = 0 then
      RaiseCompileError(P, 'case label not within switch');
    Result := TStmt.Create(skCase, P);
    CaseExpr := ParseConditional;
    try
      if not EvaluateParserIntegerConstant(CaseExpr, CaseVal) then
        RaiseCompileError(CaseExpr.Pos,
          'case value must be an integer constant expression');
    finally
      CaseExpr.Free;
    end;
    Result.CaseValue := CaseVal;
    Expect(tkColon);
    Result.Body := Self.ParseStatement();
    Exit;
  end;
  if Match(kwDefault) then
  begin
    if FInSwitch = 0 then
      RaiseCompileError(P, 'default label not within switch');
    FSwitchHasDefault := True;
    Expect(tkColon);
    Result := TStmt.Create(skDefault, P);
    Result.Body := Self.ParseStatement();
    Exit;
  end;
  if Match(kwBreak) then
  begin
    Expect(tkSemicolon);
    if FBreakableDepth = 0 then
      RaiseCompileError(P, 'break statement not within loop or switch');
    Exit(TStmt.Create(skBreak, P));
  end;
  if Match(kwContinue) then
  begin
    Expect(tkSemicolon);
    if FContinueableDepth = 0 then
      RaiseCompileError(P, 'continue statement not within loop');
    Exit(TStmt.Create(skContinue, P));
  end;
  if Match(kwGoto) then
  begin
    Result := TStmt.Create(skGoto, P);
    Result.Name := Expect(tkIdentifier, 'label name').Text;
    Expect(tkSemicolon);
    Exit;
  end;
  if At(tkIdentifier) and (Peek.Kind = tkColon) then
  begin
    Result := TStmt.Create(skLabel, P);
    Result.Name := Current.Text;
    Inc(FIndex, 2);
    Exit;
  end;
  Result := TStmt.Create(skExpr, P);
  Result.Expr := ParseExpression;
  Expect(tkSemicolon);
end;

procedure TParser.ParseExternal(AProgram: TProgram);
var
  WasTypedef, DummyTypedef: Boolean;
  BaseType, DeclType, ReturnType, ParamType: TCType;
  Func: TFunction;
  Global: TGlobal;
  Param: TParam;
  N, SavedIndex: LongInt;
  IsStatic, IsExtern: Boolean;
  DeclName, FunctionName, ParamName: string;
  FunctionPos: TSourcePos;

  procedure AddParameter(AFunction: TFunction);
  begin
    ParamType := ParseType(DummyTypedef);
    ParamName := '';
    ParseDeclarator(ParamType, ParamName);
    if ParamType.Kind = ctArray then ParamType := DecayType(ParamType);
    Param.Name := ParamName;
    Param.CType := ParamType;
    N := Length(AFunction.Params);
    SetLength(AFunction.Params, N + 1);
    AFunction.Params[N] := Param;
  end;

  procedure ParseParameterList(AFunction: TFunction);
  begin
    AFunction.IsVariadic := False;
    if At(tkRParen) then Exit;
    if At(kwVoid) and (Peek.Kind = tkRParen) then
    begin
      Inc(FIndex);
      Exit;
    end;
    repeat
      if Match(tkEllipsis) then
      begin
        AFunction.IsVariadic := True;
        Break;
      end;
      AddParameter(AFunction);
    until not Match(tkComma);
  end;

  function ParseGlobalInitializer(const AType: TCType): TExpr;
  begin
    if not Match(tkAssign) then Exit(nil);



    if At(tkLBrace) then Result := ParsePrimary
    else Result := ParseAssignment;
    if Result.Kind <> ekCast then
      Result.CType := AType;
  end;

  procedure AddGlobalDeclaration(const AType: TCType; const AName: string;
    const APos: TSourcePos);
  begin
    Global := TGlobal.Create;
    Global.Name := AName;
    Global.CType := AType;
    Global.Pos := APos;
    Global.IsStatic := IsStatic;
    Global.IsExtern := IsExtern;
    Global.IsTentative := not IsExtern;
    AddDeclaredType(AName, AType, 0, False);
    Global.Initializer := ParseGlobalInitializer(AType);
    Global.HasInitializer := Global.Initializer <> nil;
    if Global.HasInitializer and (Global.Initializer.Kind = ekInteger) then
      Global.InitialValue := Global.Initializer.IntValue;
    if Global.HasInitializer then Global.IsTentative := False;
    if (Global.CType.Kind = ctArray) and (Global.CType.ArrayLength = 0) then
    begin
      if (Global.Initializer <> nil) and
        (Global.Initializer.Kind = ekCompoundLit) then
        Global.CType.ArrayLength := Length(Global.Initializer.Args)
      else if (Global.Initializer <> nil) and
        (Global.Initializer.Kind = ekString) and
        (Global.CType.ElementKind = ctChar) then
        Global.CType.ArrayLength := Length(Global.Initializer.Text) + 1
      else if not IsExtern then
        RaiseCompileError(APos, 'incomplete global array requires an initializer');
    end;
    AddDeclaredType(AName, Global.CType, 0, False);
    AProgram.AddGlobal(Global);
  end;

begin
  if At(kwStaticAssert) then
  begin
    AProgram.AddStaticAssertion(ParseStaticAssertion);
    Exit;
  end;

  IsStatic := False;
  IsExtern := False;
  while Current.Kind in [kwStatic, kwExtern, kwInline] do
  begin
    if Current.Kind = kwStatic then IsStatic := True;
    if Current.Kind = kwExtern then IsExtern := True;
    Inc(FIndex);
  end;

  BaseType := ParseType(WasTypedef);
  if Match(tkSemicolon) then Exit;


  SavedIndex := FIndex;
  ReturnType := BaseType;
  while Match(tkStar) do
  begin
    Inc(ReturnType.PointerDepth);
    while Current.Kind in [kwConst, kwVolatile, kwRestrict] do Inc(FIndex);
  end;
  FunctionName := '';
  FunctionPos := Current.Pos;
  if At(tkIdentifier) then
  begin
    FunctionName := Current.Text;
    FunctionPos := Current.Pos;
    Inc(FIndex);
  end;

  { A parenthesized function name is a direct declarator too.  System
    headers commonly spell declarations such as `int (name)(int)` to
    prevent a function-like macro named `name` from being invoked. }
  if (FunctionName = '') and Match(tkLParen) then
  begin
    if At(tkIdentifier) and (Peek.Kind = tkRParen) then
    begin
      FunctionName := Current.Text;
      FunctionPos := Current.Pos;
      Inc(FIndex);
      Expect(tkRParen);
    end
    else
      FIndex := SavedIndex;
  end;

  if (not WasTypedef) and (FunctionName <> '') and Match(tkLParen) then
  begin
    AddDeclaredType(FunctionName, ReturnType, 0, True);
    Func := TFunction.Create;
    Func.Name := FunctionName;
    Func.ReturnType := ReturnType;
    Func.Pos := FunctionPos;
    Func.IsStatic := IsStatic;
    try
      ParseParameterList(Func);
      Expect(tkRParen);
      if Match(tkSemicolon) then
      begin
        Func.IsPrototype := True;
        AProgram.AddFunction(Func);
        Exit;
      end;
      Func.IsPrototype := False;
      for N := 0 to High(Func.Params) do
        AddDeclaredType(Func.Params[N].Name, Func.Params[N].CType,
          FScopeDepth + 1, False);
      Func.Body := ParseBlock;
      AProgram.AddFunction(Func);
    except
      Func.Free;
      raise;
    end;
    Exit;
  end;
  FIndex := SavedIndex;


  repeat
    DeclType := BaseType;
    DeclName := '';
    FunctionPos := Current.Pos;
    ParseDeclarator(DeclType, DeclName);
    if DeclName = '' then
      RaiseCompileError(Current.Pos, 'declaration requires an identifier');
    if WasTypedef then
    begin


      AddTypedef(DeclName, DeclType);
    end
    else
      AddGlobalDeclaration(DeclType, DeclName, FunctionPos);
  until not Match(tkComma);
  Expect(tkSemicolon);
end;

function TParser.ParseProgram: TProgram;
begin
  Result := TProgram.Create;
  try
    while not At(tkEOF) do ParseExternal(Result);
    TransferTypeStorage(Result);
  except
    Result.Free;
    raise;
  end;
end;

end.
