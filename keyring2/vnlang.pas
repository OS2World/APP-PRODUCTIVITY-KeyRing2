
{$IFDEF DLL}
library VNLANG;
{$ELSE}
UNIT VNLANG;
INTERFACE
    {$ENDIF}
USES
    ApMisc,
    DGLIB,
    DGMath,
    MSGMGR,
    OpDate,
    OpString,
    OS2DEF,
    OS2PMAPI,
    OS2REXX,
    Strings,
    SysMsg,
    KRTree,
    STRCRC,
    SysUtils,
    USE32,
    UTTIMDAT,
    VARDEC;

    {$H+}
    {$IFDEF DLL}
{$CDecl+,OrgName+,I-,S-,Delphi+}
{.$R KRINI.RES}
{$LINKER
  DATA MULTIPLE NONSHARED
  DESCRIPTION      " IDK, Inc. Language Internationalization Utilities "

  EXPORTS
    VNLOADFUNCS = VNLoadFuncs
    VNEXTRACT = VNExtract
    VNOPENVRP = VNOpenVRP
    VNDOGUIEXTRACT = VNDoGUIExtract
    VNSEARCHFORSTRING = VNSearchForString
    VNDROPFUNCS = VNDropFuncs
}
{$ELSE}
IMPLEMENTATION
{$ENDIF}

VAR
    Buff           : AnsiString;
CONST
    FunctionTable  : ARRAY[0..5] OF PCHAR =
    (
        'VNLoadFuncs',
        'VNExtract',
        'VNOpenVRP',
        'VNDoGUIExtract',
        'VNSearchForString',
        'VNDropFuncs'
    );

    {--------------}

    PROCEDURE LogIt(FileName, Line2Log : STRING);
    VAR
        T              : TEXT;
    BEGIN
        CreateOrAppendTxt(FileName, T);
        WRITELN(T, NowStringDeluxe(TRUE, TRUE));
        WRITELN(T, Line2Log);
        CLOSE(T);
    END;

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

    FUNCTION VNLoadFuncs(FuncName       : PCHAR;
                         ArgC           : ULONG;
                         Args           : pRxString;
                         QueueName      : PCHAR;
                         VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    VAR
        J              : INTEGER;
    BEGIN
        VarDecInit;
        SetRet('0', Ret);
        IF ArgC > 0 THEN          { Do not allow parameters }
            Result := 40
        ELSE BEGIN
            FOR J := LOW(FunctionTable) TO HIGH(FunctionTable) DO BEGIN
                RexxRegisterFunctionDLL(FunctionTable[J],
                                        'VNLANG',
                                        FunctionTable[J]);
            END;
            SetRet('1', Ret);
            Result := 0;
        END;
        Result := 0;
    END;

    {--------------}

    FUNCTION VNDropFuncs(FuncName       : PCHAR;
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
        IF KRIniTree = NIL THEN
            EXIT;
        DISPOSE(KRIniTree, Done);
        KRIniTree := NIL;
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

CONST
    FieldSep       = 'þ';

    FUNCTION CatStr(S1, S2 : AnsiString) : AnsiString;
    BEGIN
        Result := S1 + S2;
    END;

    {---------------}


    FUNCTION VNExtract(Name           : PCHAR; {KRDelRec(RecType: LONGINT) : BOOLEAN}
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    var
        Strg : STRING;
    BEGIN
        Result := 0;
        IF ScnMsgP = NIL THEN BEGIN
            MsgMgrInit('kr2', 'kr2', ScnMsgP, PrnMsgP);
            if ScnMsgP = nil then begin
                SetRet('Missing KR2.MSG', Ret);
                EXIT;
            END;
        END;
        SetRet(ScnMsgP^.SysMsg(GetNthArgLong(Args, 1)), Ret);
    END;

    {--------------}

    FUNCTION VNOpenVRP(Name           : PCHAR; {KRDelRec(RecType: LONGINT) : BOOLEAN}
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    var
        Strg : STRING;
    BEGIN
        Result := 0;
        IF ScnMsgP = NIL THEN BEGIN
            MsgMgrInit('kr2', 'kr2', ScnMsgP, PrnMsgP);
            if ScnMsgP = nil then begin
                SetRet('Missing KR2.MSG', Ret);
                EXIT;
            END;
        END;
        SetRet(ScnMsgP^.SysMsg(GetNthArgLong(Args, 1)), Ret);
    END;

    {--------------}

    FUNCTION VNDoGUIExtract(Name           : PCHAR; {KRDelRec(RecType: LONGINT) : BOOLEAN}
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    var
        Strg : STRING;
    BEGIN
        Result := 0;
        IF ScnMsgP = NIL THEN BEGIN
            MsgMgrInit('kr2', 'kr2', ScnMsgP, PrnMsgP);
            if ScnMsgP = nil then begin
                SetRet('Missing KR2.MSG', Ret);
                EXIT;
            END;
        END;
        SetRet(ScnMsgP^.SysMsg(GetNthArgLong(Args, 1)), Ret);
    END;

    {--------------}

    FUNCTION VNSearchForString(Name           : PCHAR; {KRDelRec(RecType: LONGINT) : BOOLEAN}
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    var
        Strg : STRING;
    BEGIN
        Result := 0;
        IF ScnMsgP = NIL THEN BEGIN
            MsgMgrInit('kr2', 'kr2', ScnMsgP, PrnMsgP);
            if ScnMsgP = nil then begin
                SetRet('Missing KR2.MSG', Ret);
                EXIT;
            END;
        END;
        SetRet(ScnMsgP^.SysMsg(GetNthArgLong(Args, 1)), Ret);
    END;

    {--------------}

    FUNCTION KRSysMsg(Name           : PCHAR; {KRDelRec(RecType: LONGINT) : BOOLEAN}
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT ; {$ENDIF}
    var
        Strg : STRING;
    BEGIN
        Result := 0;
        IF ScnMsgP = NIL THEN BEGIN
            MsgMgrInit('kr2', 'kr2', ScnMsgP, PrnMsgP);
            if ScnMsgP = nil then begin
                SetRet('Missing KR2.MSG', Ret);
                EXIT;
            END;
        END;
        SetRet(ScnMsgP^.SysMsg(GetNthArgLong(Args, 1)), Ret);
    END;

    {--------------}

    INITIALIZATION
END.

    {--------------}
    {--------------}
