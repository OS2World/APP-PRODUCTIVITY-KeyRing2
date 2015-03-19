{***************************************************************************
* Filename: ~modname~
* Version:  ~version~
* Date:     ~date~ @ ~time~
* Group:    ~group~
* Release:  ~release~
* ----------------------------
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer   Description
* ~log~
*
*
* ~notes~
* Description
* -----------
* VXRexx wrapper for KR2 pwx file reader/writer.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}

library KRICON;
USES
    OpString,
    OS2BASE,
    OS2DEF,
    OS2REXX,
    UREXX,
    USE32;
(*
    ApMisc,
    DGLIB,
    DGMath,
    IniMgr,
    MSGMGR,
    {$IFDEF NOPF}
    MMPLAY,
    {$ENDIF}
    OpDate,
    OS2PMAPI,
    Strings,
    KREGUTL,
    KRTree,
    STRCRC,
    SysUtils,
    UTTIMDAT,
    VARDEC;
*)

    {$H+}
    {$CDecl+,OrgName+,I-,S-,Delphi+}
    {$R KRICON.RES}
{$LINKER
  DATA MULTIPLE NONSHARED
  DESCRIPTION      " IDK, Inc. Extra Icons for KeyRing/2 "

  EXPORTS
    KRICLOADFUNCS = KRICLoadFuncs
    KRICDROPFUNCS = KRICDropFuncs
    KRGETICONCOUNT = KRGetIconCount
}

CONST FunctionTable  : ARRAY[0..2] OF PCHAR
    = ('KRICLoadFuncs',
       'KRGetIconCount',
       'KRICDropFuncs');

    FUNCTION KRICLoadFuncs(FuncName       : PCHAR;
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; EXPORT;
    VAR
        J              : INTEGER;
    BEGIN
        SetRet('0', Ret);
        IF ArgC > 0 THEN          { Do not allow parameters }
            Result := 40
        ELSE BEGIN
            FOR J := LOW(FunctionTable) TO HIGH(FunctionTable) DO BEGIN
                RexxRegisterFunctionDLL(FunctionTable[J],
                                        'KRICON',
                                        FunctionTable[J]);
            END;
            SetRet('1', Ret);
            Result := 0;
        END;
        Result := 0;
    END;

    {--------------}

    FUNCTION KRICDropFuncs(FuncName       : PCHAR;
                         ArgC           : ULONG;
                         Args           : pRxString;
                         QueueName      : PCHAR;
                         VAR Ret        : RxString) : ULONG; EXPORT;
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

    FUNCTION KRGetIconCount(FuncName       : PCHAR;
                            ArgC           : ULONG;
                            Args           : pRxString;
                            QueueName      : PCHAR;
                            VAR Ret        : RxString) : ULONG; EXPORT;
    VAR
        Rc             : APIret;
        Module         : HModule;
        PTR            : POINTER;
        Count,
        N              : LONGINT;
        FailedModule   : ARRAY[0..259] OF CHAR;
    BEGIN
        Result := 40;
        N := 671;
        {$IFNDEF DLL}
        Module := NULLHANDLE;
        {$ELSE}
        Rc := DosLoadModule(FailedModule, SIZEOF(FailedModule), 'kricon.dll', Module);
        if Rc <> 0 then
            if Rc <> 87 then
                exit;
        {$ENDIF}
        Rc := DosGetResource(Module, RT_RCDATA, N, PTR);

        IF (Rc <> 0) OR (PTR = NIL) THEN
            EXIT;
        Count := longint(PTR^);
        Rc := DosFreeResource(PTR);
        {$IFDEF DLL}
        if module <> $FFFF then
            DosFreeModule(Module);
        {$ENDIF}

        SetRet(Long2Str(Count), Ret);

        Result := 0;
    END;


    INITIALIZATION
END.

    {--------------}
    {--------------}
