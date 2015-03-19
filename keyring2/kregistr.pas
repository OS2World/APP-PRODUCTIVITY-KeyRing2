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
* KREGISTR.DLL
* Revenue protection for KeyRing/2
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}

{$IFDEF DLL}
library KREGISTR;
{$ELSE}
unit kregistr;
interface
implementation
{$ENDIF}

USES
    ApMisc,
    OpDate,
    OpString,
    BlowFish,
    DGMath,
    IniMgr,
    KREGUTL,
    Os2Base,
    OS2DEF,
    OS2PMAPI,
    OS2REXX,
    Strings,
    STRCRC,
    {sysmsg}
    SysUtils,
    UREXX,
    USE32,
    VARDEC,
    VPUTILS;

{ note:
  KRFN1 = register product
  KRFN2 = KRShowRegistration
  KRFN3 = KRTestFeatureBits
  KRFN4 = KRStrobeINI
  KRFN5 = KRGetPWXExpireSeconds - not REXX callable
  KRFN6 = KRGetExeDropDead
  KRFN7 = KRGetDaysUntilDropdead - not rexx callable
  KRFN8 = KRGetEXEDropdeaddaysString
  KRFN9 = KRTestRegCode
  KRFN10 = KRGetMaxLicensedRev
}

    {$H+}
    {$CDecl+,OrgName+,I-,S-,Delphi+}
{$IFDEF DLL}
{$LINKER
  DATA MULTIPLE NONSHARED
    DESCRIPTION " Registered to reb james "
  EXPORTS
      KRRLOADFUNCS = KRRLoadFuncs
      KRFN1 = KRFN1
      KRFN2 = KRFN2
      KRFN3 = KRFN3
      KRFN4 = KRFN4
      KRFN5 = KRFN5
      KRFN6 = KRFN6
      KRFN7 = KRFN7
      KRFN8 = KRFN8
      KRFN9 = KRFN9
      KRFN10 = KRFN10
      KRRDROPFUNCS = KRRDropFuncs
}
{$ENDIF}
    {$R KREGISTR.RES}
CONST
    FunctionTable  : ARRAY[0..8] OF PCHAR
    = ('KRRLoadFuncs',
       'KRFN1',
       'KRFN2',
       'KRFN3',
       'KRFN4',
       'KRFN8',
       'KRFN9',
       'KRFN10',
       'KRRDropFuncs'
       );

    FUNCTION KRRLoadFuncs(FuncName       : PCHAR;
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT; {$ENDIF}
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
                                        'KREGISTR',
                                        FunctionTable[J]);
            END;
            SetRet('1', Ret);
            Result := 0;
        END;
        Result := 0;
    END;

    {--------------}

    FUNCTION KRFN1(FuncName       : PCHAR; {register product}
                   ArgC           : ULONG;
                   Args           : pRxString;
                   QueueName      : PCHAR;
                   VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 40;
        IF ArgC <> 1 THEN
            EXIT;
        Result := 0;
        IF RegisterProduct(GetNthArgString(Args, 1)) THEN
            SetRet('1', Ret)
        ELSE
            SetRet('0', Ret);
    END;

    {--------------}

    FUNCTION KRFN2(FuncName       : PCHAR; {ShowRegistration}
                   ArgC           : ULONG;
                   Args           : pRxString;
                   QueueName      : PCHAR;
                   VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Strg           : ANSISTRING;
    BEGIN
        Result := 40;
        IF ArgC <> 0 THEN
            EXIT;
        Result := 0;
        Strg := ShowRegistration;
        SetRet(Strg, Ret);
    END;

    {--------------}

    FUNCTION KRFN3(FuncName       : PCHAR; {TestFeatureBits}
                   ArgC           : ULONG;
                   Args           : pRxString;
                   QueueName      : PCHAR;
                   VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 40;
        IF ArgC <> 1 THEN
            EXIT;
        SetRet(Long2Str(LONGINT(TestFeatureBits(GetNthArgLong(Args, 1)))), Ret);
        Result := 0;
    END;

    {--------------}

    {this needs to be called every 60-90 seconds or the crypter will die}
    FUNCTION KRFN4(FuncName       : PCHAR; {KRStrobeINI}
                   ArgC           : ULONG;
                   Args           : pRxString;
                   QueueName      : PCHAR;
                   VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Strg           : STRING;
    BEGIN
        Result := 40;
        IF ArgC <> 0 THEN
            EXIT;
        Result := 0;
        StrobeINI;
        SetRet('1', Ret);
    END;

    {--------------}

    FUNCTION KRFN5 : LONGINT;     {KRGetPWXExpireSeconds - not REXX callable}
    BEGIN
        Result := GetPWXExpireSeconds;
    END;

    {--------------}

    FUNCTION KRRDropFuncs(FuncName       : PCHAR;
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
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

    FUNCTION KRFN6 : BOOLEAN; {$IFDEF DLL}EXPORT; {KRGetExeDropDead not rexx callable}{$ENDIF}
    BEGIN
        Result := Today > GetExeExpirationDate;
    END;

    {--------------}

    FUNCTION KRFN7 : LONGINT; {$IFDEF DLL}EXPORT; {KRGetDaysUntilDropdead - not rexx callable}{$ENDIF}
    BEGIN
        Result := GetExeExpirationDate - Today;
    END;

    {--------------}

CONST
    {Product expires in }

    SESTRS100      = '?míï7'#39'ðà9…´“?ù\ººNÎ';
    SESTRN100      = 50626;
    SESTRP100      = 20427;

    {days: }

    SESTRS101      = 'JŽ';
    SESTRN101      = 54411;
    SESTRP101      = 41995;

    {Sorry!  This product has expired.  Please contact IDK, Inc.}
    SESTRS102      = '6YDÓ]Ò¼'#40'e8n›'#13'Ê-‰øè'#9'u_p&ê½!òrÜ›†ãkCÏÊçsÎÁöbx¾x‡Š¹ô÷~';
    SESTRN102      = 18263;
    SESTRP102      = 15730;

    {--------------}

    FUNCTION KRFN8(FuncName       : PCHAR; {KRGetEXEDropdeaddaysString}
                   ArgC           : ULONG;
                   Args           : pRxString;
                   QueueName      : PCHAR;
                   VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Days           : LONGINT;
        Strg           : STRING;
    BEGIN
        Result := 40;
        IF ArgC <> 0 THEN
            EXIT;
        Result := 0;
        IF TestFeatureBits(PWXDDFEATUREBIT) = EBAD THEN BEGIN
            SetRet(DecodeStrg(SESTRS103, SESTRN103, SESTRP103) + ' - ' + DecodeStrg(SESTRS104, SESTRN104, SESTRP104), Ret); {Demo Mode invalid registration code}
            EXIT;
        END;
        Days := KRFN7;
        IF Days < 90 THEN BEGIN
            IF Days < 0 THEN BEGIN
                Strg := Strg + DecodeStrg(SESTRS102, SESTRN102, SESTRP102);
            END
            ELSE BEGIN
                Strg := Strg +
                        DecodeStrg(SESTRS100, SESTRN100, SESTRP100) +
                        Long2Str(Days) +
                        ' ' +
                        DecodeStrg(SESTRS101, SESTRN101, SESTRP101)
            END;
        END;
        SetRet(Strg, Ret);
    END;

    {--------------}

    FUNCTION KRFN9(FuncName       : PCHAR; {KRTestRegCode}
                   ArgC           : ULONG;
                   Args           : pRxString;
                   QueueName      : PCHAR;
                   VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Days           : LONGINT;
        Strg           : STRING;
    BEGIN
        Result := 40;
        SetRet('0', Ret);
        IF ArgC <> 0 THEN
            EXIT;
        Result := 0;
        IF TestRegCode THEN
            SetRet('1', Ret);
    END;

    {--------------}

    FUNCTION KRFN10(FuncName       : PCHAR; {TestFeatureBits}
                   ArgC           : ULONG;
                   Args           : pRxString;
                   QueueName      : PCHAR;
                   VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 40;
        IF ArgC <> 1 THEN
            EXIT;
        SetRet(Long2Str(LONGINT(TestMaxLicense(GetNthArgLong(Args, 1)))), Ret);
        Result := 0;
    END;

    {--------------}


    INITIALIZATION
END.

    {--------------}
    {--------------}

