
{$IFDEF DLL}
library REXCRYPT;
{$ELSE}
UNIT REXCRYPT;
INTERFACE
    {$ENDIF}
USES
    ApMisc,
    DGLIB,
    DGMath,
    OpDate,
    OpString,
    OS2DEF,
    OS2PMAPI,
    OS2REXX,
    Strings,
    STRCRC,
    SysUtils,
    USE32,
    UTTIMDAT;

    {$H+}
{$IFDEF DLL}
{$CDecl+,OrgName+,I-,S-,Delphi+}
{$LINKER
  DATA MULTIPLE NONSHARED
  DESCRIPTION      " IDK, Inc. Rexx Crypter functions "

  EXPORTS
    RCLOADFUNCS = RCLoadFuncs
    RCDROPFUNCS = RCDropFuncs
    RCCRYPTINIT = RCCryptInit
    RCCRYPTBLOCK = RCCryptBlock
    RCDECRYPTBLOCK = RCDeCryptBlock
    RCGETCRYPTTYPE = RCGetCryptType
}
{$ELSE}
IMPLEMENTATION
    {$ENDIF}

    {&OrgName+}
    {$IFNDEF USEUNIT}
    PROCEDURE CryptInit(Password : STRING); EXTERNAL 'krypton' Name 'CryptInit';
    FUNCTION CryptBlock(Block : STRING) : STRING; EXTERNAL 'krypton' Name 'CryptBlock';
    FUNCTION DeCryptBlk(Block : STRING) : STRING; EXTERNAL 'krypton' Name 'DeCryptBlk';
    FUNCTION GetCryptType : STRING; EXTERNAL 'krypton' Name 'GetCryptType';
    {$ENDIF}

VAR
    Buff           : AnsiString;
    PrivKey        : ULONG;
CONST
    FunctionTable  : ARRAY[0..4] OF PCHAR =
    (
        'RCDropFuncs',
        'RCCryptInit',
        'RCCryptBlock',
        'RCDecryptBlock',
        'RCGetCryptType'
    );

    EscChar        = #0;

    {----------------}

    PROCEDURE SetRet(Strg : AnsiString; VAR Ret : RxString);
    BEGIN
        Ret.StrLength := LENGTH(Strg);
        IF Strg = NIL THEN
            Buff := #0
        ELSE
            Buff := Strg + #0;

        Ret.StrPtr := PCHAR(Buff);
    END;

    {--------------}

    FUNCTION RCLoadFuncs(FuncName       : PCHAR;
                         ArgC           : ULONG;
                         Args           : pRxString;
                         QueueName      : PCHAR;
                         VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    VAR
        J              : INTEGER;
    BEGIN
        SetRet('0', Ret);
        IF ArgC > 0 THEN          { Do not allow parameters }
            Result := 40
        ELSE BEGIN
            FOR J := LOW(FunctionTable) TO HIGH(FunctionTable) DO BEGIN
                RexxRegisterFunctionDLL(FunctionTable[J],
                                        'REXCRYPT',
                                        FunctionTable[J]);
            END;
            SetRet('1', Ret);
            Result := 0;
        END;
        Result := 0;
    END;

    {--------------}

    FUNCTION RCDropFuncs(FuncName       : PCHAR;
                         ArgC           : ULONG;
                         Args           : pRxString;
                         QueueName      : PCHAR;
                         VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    VAR
        J              : INTEGER;
    BEGIN
        SetRet('0', Ret);
        IF ArgC > 0 THEN          { Do not allow parameters }
            Result := 40
        ELSE BEGIN
            FOR J := LOW(FunctionTable) TO HIGH(FunctionTable) DO
                RexxDeregisterFunction(FunctionTable[J]);
            Result := 0;
        END;
        SetRet('1', Ret);
    END;

    {--------------}

    FUNCTION GetNthArgString(Args : pRxString; N : WORD) : STRING;
    BEGIN
        INC(Args, N - 1);
        Result := StrPas(Args^.StrPtr);
    END;

    {--------------}

    FUNCTION GetNthArgLong(Args : pRxString; N : WORD) : LONGINT;
    BEGIN
        Str2Long(GetNthArgString(Args, N), Result);
    END;

    {--------------}

    FUNCTION GetNthArgReal(Args : pRxString; N : WORD) : REAL;
    VAR
        R              : Float;
    BEGIN
        Str2Real(GetNthArgString(Args, N), R);
        Result := R;
    END;

    {--------------}

    FUNCTION RCCryptInit(Name           : PCHAR; { PROCEDURE RCCryptInit(Password, PrivKey:STRING) }
                       ArgC           : ULONG;
                       Args           : pRxString;
                       QueueName      : PCHAR;
                       VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    VAR
        Pw : STRING;
    BEGIN
        RANDOMIZE;

        SetRet('0', Ret);
        Result := 40;
        if argc <> 2 then
            exit;

        Pw := GetNthArgString(Args, 1);
        if pw = '' then {missing parameter - crash rexx}
             exit;

        PrivKey := GetNthArgLong(Args, 2);

        Result := 0;

        if LENGTH(Pw) < 4 THEN begin
            SetRet('2', Ret); {malformed password - must be greater than or equal to 4 chars long}
            EXIT;
        END;
        SetRet('1', Ret);
        CryptInit(Pw);
    END;

    {--------------}

    FUNCTION RCCryptBlock(Name           : PCHAR; { FUNCTION RCCryptBlock(Block:STRING):STRING }
                       ArgC           : ULONG;
                       Args           : pRxString;
                       QueueName      : PCHAR;
                       VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    var
        Strg : STRING;
        PubKey : ULONG;
    begin
        Strg := RLECompress(GetNthArgString(Args, 1), EscChar); {compress the line}

        WHILE (LENGTH(Strg) MOD 8) <> 0 DO
            Strg := Strg + ' ';

        PubKey := RANDOM($10000);
        Strg := EncodeStrg(Strg, PubKey, PrivKey);

        SetRet(CryptBlock(Strg), Ret);
        Result := 0;
    end;

    {--------------}

    FUNCTION RCDeCryptBlock(Name           : PCHAR; { FUNCTION RCDeCryptBlock(Block:STRING):STRING }
                       ArgC           : ULONG;
                       Args           : pRxString;
                       QueueName      : PCHAR;
                       VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    var
        Buff : STRING;
    begin

        Buff := DecodeStrg(DeCryptBlk(), PubKey, PrivKey);
        Line := TrimTrail(RLEDecompress(Buff, EscChar));

        SetRet(DeCryptBlk(GetNthArgString(Args, 1)), Ret);
        Result := 0;
    end;

    {--------------}

    FUNCTION RCGetCryptType(Name           : PCHAR; { FUNCTION RCGetCryptType : STRING }
                       ArgC           : ULONG;
                       Args           : pRxString;
                       QueueName      : PCHAR;
                       VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    begin
        SetRet(GetCryptType, Ret);
        Result := 0;
    end;

    {--------------}

INITIALIZATION
END.

    {--------------}
    {--------------}
