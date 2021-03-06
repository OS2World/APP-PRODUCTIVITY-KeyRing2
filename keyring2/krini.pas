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
{$IFDEF DLL}
library KRINI;
{$ELSE}
unit KRINI;
interface
{$ENDIF}
USES
    ApMisc,
    DGLIB,
    DGMath,
    IniMgr,
    MSGMGR,
    {$IFDEF NOPF}
    MMPLAY,
    {$ENDIF}
    OpDate,
    OpRoot,
    OpString,
    OS2DEF,
    OS2PMAPI,
    OS2REXX,
    Strings,
    KREGUTL,
    KRTree,
    STRCRC,
    SysUtils,
    UREXX,
    USE32,
    UTTIMDAT,
    VARDEC;
{
       Rectypes
       --------------------------
        1 = app
        2 = www
        3 = pin
        4 = combo
        5 = other1
        6 = other2

       Fields
       --------------------------
        1 = Icon resource
        2 = Description (multiline)
        3 = Password
        4 = Username/id
        5 = Serial number
        6 = Last update
        7 = exp date
        8 = url
        9 = note
}

    {$H+}
    {$CDecl+,OrgName+,I-,S-,Delphi+}
{$IFDEF DLL}
{$LINKER
  DATA MULTIPLE NONSHARED
  DESCRIPTION      " IDK, Inc. INI file functions for KeyRing/2 "

  EXPORTS
    QUERYSTAT = QueryStat
    KRTEST = KRTest
    KRILOADFUNCS = KRILoadFuncs
    KRIMPORT = KRImport
    KRSAVEINI = KRSaveINI
    KRDISPOSEINI = KRDisposeINI
    KRGETNTHFIELD = KRGetNthField
    KRCHANGENTHFIELD = KRChangeNthField
    KRGETRECCOUNT = KRGetRecCount
    KRDELREC = KRDelRec
    KRGETREC = KRGetRec
    KRPUTREC = KRPutRec
    KRKILLBRANCH = KRKillBranch
    KRMAKEPASSWORD = KRMakePassword
    KRGETCRYPTTYPE = KRGetCryptType
    KRGETTIME = KRGetTime
    KRCALCDATE = KRCalcDate
    KRCALCDMYOFFSET = KRCalcDMYOffset
    KRDMY2DATE = KRDMY2Date
    KRDate2DMY = KRDate2DMY
    KRGetToday = KRGetToday
    KRGetTodayJulian = KRGetTodayJulian
    KRDMY2Julian = KRDMY2Julian
    KRJulian2DMY = KRJulian2DMY
    KRDROPFUNCS = KRDropFuncs

    KRGETPAGENAME = KRGetPageName
    KRGETPAGEHINT = KRGetPageHint
    KRGETPAGEICON = KRGetPageIcon
    KRGETColumnEnable = KRGetColumnEnable
    KRPUTColumnEnable = KRPutColumnEnable
    KRGETCOLUMNNAME = KRGetColumnName
    KRGETFieldVal = KRGetFieldVal

    KRGETPAGEORDENB = KRGetPageOrdEnb

    KRGETPAGEINDEX = KRGetPageIndex
    KRGETPAGEENABLE = KRGetPageEnable

    KRPUTPAGENAME = KRPutPageName
    KRPUTPAGEHINT = KRPutPageHint
    KRPUTPAGEICON = KRPutPageIcon
    KRPUTCOLUMNNAME = KRPutColumnName

    KRGETEXPIREDREC = KRGetExpiredRec

    KRPLAYINTRO = KRPlayIntro
    KRKILLINTRO = KRKillIntro

    KRGETDEFAULTORDER = KRGetDefaultOrder
    KRSETCHALLENGEA = KRSetChallengeA
    KROPENINI=KROpenINI
}
{$IFDEF NOPF}
{$ENDIF NOPF}
{$ELSE DLL}
implementation
{$ENDIF DLL}
VAR
    Buff           : AnsiString;
    KRIniTree      : PTreeReader; {INI file (if any) containing encrypted data}

CONST
    AllTrue        = '111111111';
    AllFalse       = '000000000';
    KRTF           : ARRAY[BOOLEAN] OF CHAR = ('0', '1');

    FunctionTable  : ARRAY[0..43] OF PCHAR
    = ('KRILoadFuncs',
       'KRTest',
       'KRImport',
       'KRSaveINI',
       'KRGetRecCount',

       'KRGetNthField',
       'KRChangeNthField',
       'KRDelRec',
       'KRPutRec',
       'KRGetTime',
       'KRCalcDate',
       'KRCalcDMYOffset',
       'KRDMY2Date',
       'KRDate2DMY',
       'KRGetToday',
       'KRGetTodayJulian',
       'KRDMY2Julian',
       'KRJulian2DMY',
       'KRKillBranch',
       'KRGetRec',
       'KRMakePassword',
       'KRDisposeINI',
       'KRGetCryptType',

       'KRGetPageName',
       'KRGetColumnName',
       'KRGetFieldVal',
       'KRGetPageHint',
       'KRGetPageIcon',
       'KRGetColumnEnable',

       'KRGetPageOrdEnb',

       'KRGetPageIndex',          {this really returns the life remaining (days) of current PWX}
       'KRGetPageEnable',         {this really returns the time}

       'KRPutPageName',
       'KRPutColumnName',
       'KRPutPageHint',
       'KRPutPageIcon',
       'KRPutColumnEnable',

       'KRGetExpiredRec',

       'KRGetDefaultOrder',

       'KRPlayIntro',
       'KRKillIntro',
       'KRSetChallengeA',
       'KROpenINI',

       'KRDropFuncs');

    {--------------}

    FUNCTION QuoteEqual(Strg : STRING) : STRING;
    var
        I : BYTE;
    begin
        for I := 1 to length(Strg) do begin
            if Strg[i] = '=' then
                Strg[i] := FieldSep;
        end;
        Result := Strg;
    end;

    {--------------}

    FUNCTION UnQuoteEqual(Strg : STRING) : STRING;
    var
        I : BYTE;
    begin
        for I := 1 to length(Strg) do begin
            if Strg[i] = FieldSep then
                Strg[i] := '=';
        end;
        Result := Strg;
    end;

    {--------------}

    FUNCTION GetTotalRecCount : LONGINT;
    VAR
        Ct             : LONGINT;
        I              : TRecType;
    BEGIN
        Ct := 0;
        FOR I := LOW(I) TO HIGH(I) DO
            INC(Ct, KRIniTree^.GetRecCount(I));
        Result := Ct;
    END;

    {----------------}

    FUNCTION KRILoadFuncs(FuncName       : PCHAR;
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
                                        'KRINI',
                                        FunctionTable[J]);
            END;
            SetRet('1', Ret);
            Result := 0;
        END;
        Result := 0;
    END;

    {--------------}

    FUNCTION KRDropFuncs(FuncName       : PCHAR;
                         ArgC           : ULONG;
                         Args           : pRxString;
                         QueueName      : PCHAR;
                         VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT; {$ENDIF}
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

    FUNCTION MakeExt(FName : STRING; Generation : BYTE) : STRING;
    VAR
        Ext            : STRING;
    BEGIN
        IF Generation = 0 THEN BEGIN
            Ext := JustExtension(FName);
            EXIT;
        END;
        Ext := LeftPadCh(JustExtension(FName), '0', 3);
        Result := COPY(Ext, 1, 2) + Long2Str(Generation);
    END;

    {--------------}

    FUNCTION MakeGen(FName : STRING; Gen : BYTE) : STRING;
    BEGIN
        Result := ForceExtension(FName, MakeExt(FName, Gen));
    END;

    {--------------}

    PROCEDURE RollGenerations(FName : STRING; MaxGenerations : BYTE);
    VAR
        I              : BYTE;
    BEGIN
        {bail if the guy just wants to overwrite}
        IF MaxGenerations = 0 THEN
            EXIT;

        {clear off end of queue (oldest), if any}
        FOR I := 9 DOWNTO MaxGenerations DO
            RMFile(MakeGen(FName, I));

        {shift file extensions up by 1}
        FOR I := MaxGenerations - 1 DOWNTO 1 DO
            ReNameFile(MakeGen(FName, I), MakeGen(FName, I + 1));

        {rename the current file to fname.pw1}
        ReNameFile(FName, MakeGen(FName, 1));
    END;

    {--------------}

    {this really returns PWX life remaining days }
    FUNCTION KRGetPageIndex(Name           : PCHAR;
                            ArgC           : ULONG;
                            Args           : pRxString;
                            QueueName      : PCHAR;
                            VAR Ret        : RxString) : ULONG; {$IFDEF DLL} EXPORT; {$ENDIF}
    BEGIN
        SetRet(Long2Str(CalcPWXLifetimeLeft(CurrInceptDate)), Ret);
        Result := 0;
    END;

    {--------------}

    {this really returns the time}
    FUNCTION KRGetPageEnable(Name           : PCHAR;
                             ArgC           : ULONG;
                             Args           : pRxString;
                             QueueName      : PCHAR;
                             VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        SetRet(Long2Str(CurrentTime), Ret);
        Result := 0;
    END;

    FUNCTION KRTest(Name           : PCHAR;
                    ArgC           : ULONG;
                    Args           : pRxString;
                    QueueName      : PCHAR;
                    VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        StemName : STRING;
        Value : AnsiString;
        MyStrings : array[0..200] of AnsiString;
        I,
        Elements : WORD;
    BEGIN
        SetRet(Long2Str(CurrentTime), Ret);
        Erasefile('junk.tmp');
        Result := 0;
        StemName := GetNthArgString(Args, 1);
        Value := GetNthArgString(Args, 2);
        SetRet(long2str(SetRexxVariable(StemName, '.2', Value)), Ret);

        FetchRexxVariable(StemName, '.0', Value);
        FetchRexxVariable(StemName, '.1', Value);
        FetchRexxVariable(StemName, '.2', Value);

        Str2Long(Value, Elements);

        SetRet(Value, Ret);
        exit;

        StemToArray(StemName, MyStrings, Elements);
        Value := '';
        for I := 1 to Elements do begin
            Value := Value + '!' + MyStrings[i];
        end;
        SetRet(Value, Ret);
    END;


    {--------------}

    {save mem copy of ini file as}
    FUNCTION KRSaveINI(Name           : PCHAR; { FUNCTION KRSaveINI(Name, Password : STRING; EnableCrypt:BOOLEAN; MaxGenerations:BYTE) : BOOLEAN }
                       ArgC           : ULONG;
                       Args           : pRxString;
                       QueueName      : PCHAR;
                       VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Generations    : BYTE;
        StrobeOK       : BOOLEAN;
    BEGIN
        Result := 40;
        StrobeOK := TestStrobe;
        SetRet('0', Ret);

        IF ArgC <> 4 THEN
            EXIT;

        Result := 0;

        IF GetNthArgString(Args, 1) = '' THEN
            EXIT;

        IF GetNthArgString(Args, 2) = '' THEN
            EXIT;

        Generations := GetNthArgLong(Args, 4);

        RollGenerations(GetNthArgString(Args, 1), Generations);

        IF KRIniTree = NIL THEN BEGIN
            NEW(KRIniTree, InitWrite(GetNthArgString(Args, 1))); {create empty INI if none exists}
            IF KRIniTree = NIL THEN
                EXIT;
            IF NOT KRIniTree^.CreateBranch(DecodeStrg(SESTRS1, SESTRN1, SESTRP1) {'>:SecretStuff'} ) THEN
                EXIT;
        END;

        IF KRIniTree^.WriteINI(GetNthArgString(Args, 1), GetNthArgString(Args, 2), (GetNthArgLong(Args, 3) > 0)) THEN
            SetRet('1', Ret);

        IF NOT StrobeOK THEN BEGIN
            DISPOSE(KRIniTree, Done);
            KRIniTree := NIL;
            SetRet('0', Ret);
        END;
    END;

    {--------------}

    FUNCTION KRGetRecCount(Name           : PCHAR; {KRGetRecCount(RecType : LONGINT):longint}
                           ArgC           : ULONG;
                           Args           : pRxString;
                           QueueName      : PCHAR;
                           VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 40;
        IF KRIniTree = NIL THEN
            EXIT;
        SetRet(Long2Str(KRIniTree^.GetRecCount(TRecType(GetNthArgLong(Args, 1)))), Ret);
        Result := 0;
    END;

    {--------------}

    FUNCTION KRMakePassword(Name           : PCHAR; {KRMakePassword(PassMode:TPassMode; PassCase:TPassCase):STRING}
                            ArgC           : ULONG;
                            Args           : pRxString;
                            QueueName      : PCHAR;
                            VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        S,
        Strg           : STRING;
        C              : CHAR;
        I              : BYTE;
        CS             : CharSet;
    BEGIN
        Result := 0;

        CASE GetNthArgLong(Args, 2) OF
            1 : BEGIN             {lower}
                    CASE GetNthArgLong(Args, 1) OF
                        1 :
                            CS := ['a'..'z']; {alpha}
                        2 :
                            CS := ['0'..'9']; {numeric}
                        3 :
                            CS := ['a'..'z', '0'..'9']; {alphanumeric}
                        4 :
                            CS := ['a'..'z', ' '..'/', '0'..'9']; {alphanumeric+punct}
                        ELSE
                            CS := ['a'..'z', ' '..'/', '0'..'9']; {alphanumeric+punct}
                    END;
                END;
            2 : BEGIN             {upper}
                    CASE GetNthArgLong(Args, 1) OF
                        1 :
                            CS := ['A'..'Z'];
                        2 :
                            CS := ['0'..'9'];
                        3 :
                            CS := ['A'..'Z', '0'..'9'];
                        4 :
                            CS := ['A'..'Z', ' '..'/', '0'..'9'];
                        ELSE
                            CS := ['A'..'Z', ' '..'/', '0'..'9'];
                    END;
                END;
            3 : BEGIN             {mixed case}
                    CASE GetNthArgLong(Args, 1) OF
                        1 :
                            CS := ['A'..'Z', 'a'..'z'];
                        2 :
                            CS := ['0'..'9'];
                        3 :
                            CS := ['A'..'Z', 'a'..'z', '0'..'9'];
                        4 :
                            CS := ['A'..'Z', 'a'..'z', ' '..'/', '0'..'9'];
                        ELSE
                            CS := ['A'..'Z', 'a'..'z', ' '..'/', '0'..'9'];
                    END;
                END;
        END;

        SetRet(RandStringLimited(10, 20, CS), Ret);
    END;

    {--------------}

    FUNCTION KRGetNthField(Name           : PCHAR; {KRGetNthField(RecType, RecNum, Field, VarInstnce : ULONG):STRING}
                           ArgC           : ULONG;
                           Args           : pRxString;
                           QueueName      : PCHAR;
                           VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 40;
        IF KRIniTree = NIL THEN
            EXIT;
        SetRet(KRIniTree^.GetNthField(TRecType(GetNthArgLong(Args, 1)), {1..6}
                                      GetNthArgLong(Args, 2), {1..Nth record}
                                      TField(GetNthArgLong(Args, 3)), {1..9th field}
                                      GetNthArgLong(Args, 4)),
               Ret);              {value instance}
        Result := 0;
    END;

    {--------------}

    FUNCTION KRChangeNthField(Name           : PCHAR; {KRChangeNthField(NewValue:STRING; RecType, RecNum, Field, ValInstance):BOOLEAN}
                              ArgC           : ULONG;
                              Args           : pRxString;
                              QueueName      : PCHAR;
                              VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 40;
        IF KRIniTree = NIL THEN
            EXIT;
        SetRet('0', Ret);
        IF KRIniTree^.ChangeNthField(GetNthArgString(Args, 1), {new value}
                                     TRecType(GetNthArgLong(Args, 2)), {1..6 rectype}
                                     GetNthArgLong(Args, 3), {1..Nth recnum}
                                     TField(GetNthArgLong(Args, 4)), {1..9th field}
                                     GetNthArgLong(Args, 5)) {value instance} THEN
            SetRet('1', Ret);
        Result := 0;
    END;

    {--------------}

    FUNCTION KRDelRec(Name           : PCHAR; {KRDelRec(RecType, RecNum : LONGINT) : BOOLEAN}
                      ArgC           : ULONG;
                      Args           : pRxString;
                      QueueName      : PCHAR;
                      VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 40;
        SetRet('0', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        IF KRIniTree^.DelRec(TRecType(GetNthArgLong(Args, 1)), {1..6}
                             GetNthArgLong(Args, 2)) {1..Nth record} THEN
            SetRet('1', Ret);
        Result := 0;
    END;

    {--------------}

    FUNCTION CatStr(S1, S2 : AnsiString) : AnsiString;
    BEGIN
        Result := S1 + S2 + FieldSep;
    END;

    {--------------}

    FUNCTION StuffCR(Strg : STRING) : STRING;
    VAR
        I : BYTE;
    BEGIN
        for I := 1 to length(Strg) do begin
            if Strg[i] = '^' then
                Strg[i] := #$0A;
        end;
        Result := Strg
    END;

    {--------------}


    {for internal use}
    FUNCTION BuildDelimitedRecStrg(Args : pRxString; Rec : TDataRec; HandleOffset : BYTE; VAR Strg : AnsiString) : LONGINT;
    VAR
        I              : BYTE;
        Flag           : shortSTRING;
    BEGIN
        Result := 0;
        {do the boilerplate stuff first}
        Strg := CatStr(FieldSep, StuffCR(Rec.Description)); {iconview caption}
        Strg := CatStr(Strg, Rec.Icon); {iconview icon}
        Strg := CatStr(Strg, ''); {top - unused}
        Strg := CatStr(Strg, ''); {left- unused}

        DEC(HandleOffset);        {fix off-by-one in forloop below}

        Flag := GetNthArgString(Args, HandleOffset); {get order flags (always one param to the left of the handles)}
        FOR I := 1 TO LENGTH(Flag) DO BEGIN
            CASE Flag[I] OF
                'I' :
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {iconfield}
                        Strg := CatStr(Strg, Rec.Icon);
                    END;
                'D' :             {2 desc}
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {descfield}
                        Strg := CatStr(Strg, Rec.Description);
                    END;
                'N' :             {3 userid}
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {userfield}
                        Strg := CatStr(Strg, Rec.UserID);
                    END;
                'P' :             {4 password}
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {passwordfield}
                        Strg := CatStr(Strg, Rec.Password);
                    END;
                'S' :             {5 serial num}
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {serialfield}
                        Strg := CatStr(Strg, Rec.SerialNum);
                    END;
                'L' :             {6 last update}
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {updatefield}
                        Strg := CatStr(Strg, Rec.LastUpdate);
                    END;
                'E' :             {7 expire date}
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {Expfield}
                        Strg := CatStr(Strg, Rec.Expire);
                    END;
                'U' :             {8 url}
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {URLfield}
                        Strg := CatStr(Strg, Rec.URL);
                    END;
                'W' :             {9 note}
                    BEGIN
                        Strg := CatStr(Strg, GetNthArgString(Args, I + HandleOffset)); {Notefield}
                        Strg := CatStr(Strg, Rec.Note);
                    END;
                'O' : ;           {this one is always last, so ignore it for now}
                ELSE BEGIN
                    Result := 40; {invalid flag, so bomb}
                    EXIT;
                END;
            END;
        END;

        Strg := CatStr(Strg, GetNthArgString(Args, 10 + HandleOffset)); {10 Orderfield}
        Strg := CatStr(Strg, Flag); {concatenate order flag}
    END;

    {--------------}

    {Get a record                                       1        2                 3         4        5        6        7      8      9          10      11      12       13          }
    FUNCTION KRGetRec(Name           : PCHAR; {KRGetRec(RecType, RecNum : LONGINT; FldOrder, IconFID, DescFID, UserFID, PWFID, SNFID, UpdateFID, ExpFID, URLFID, NoteFID, OrdID:STRING) : STRING}
                      ArgC           : ULONG;
                      Args           : pRxString;
                      QueueName      : PCHAR;
                      VAR Ret        : RxString) : ULONG;
    VAR
        Rec            : TDataRec;
        Strg           : AnsiString;
        Flag           : shortSTRING;
        I,
        J              : BYTE;
    BEGIN
        Result := 40;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        IF ArgC <> 13 THEN
            EXIT;
        Result := 0;

        IF NOT KRIniTree^.GetRec(TRecType(GetNthArgLong(Args, 1)), {1..6}
                                 GetNthArgLong(Args, 2), {1..Nth record}
                                 Rec) THEN
            EXIT;

        with Rec do begin
            Description := UnQuoteEqual(Description);
            UserID := UnQuoteEqual(UserID);
            Password := UnQuoteEqual(Password);
            SerialNum := UnQuoteEqual(SerialNum);
            URL := UnQuoteEqual(URL);
            Note := UnQuoteEqual(Note);
            I := pos('KRINI', StUpCase(Icon)); // look for old style KRINI.DLL icon resources
            IF I > 0 THEN
                Icon := COPY(Icon, 1, I-1) + 'KRICON.DLL'; // replace with KRICON resources
//            I := pos('$ ', Icon); // find old style "$ 123:KRINI.DLL" syntax
//            IF I > 0 THEN
//                DELETE(Icon, I+1, 1); // replace it with "$123:KRINI.DLL"
        end;

        Result := BuildDelimitedRecStrg(Args, Rec, 4, Strg);

        SetRet(Strg, Ret);
    END;

    {--------------}

    FUNCTION KRGetFieldVal(Name           : PCHAR; {KRGetRec(RecType, RecNum : LONGINT; FldFlag:STRING): STRING}
                      ArgC           : ULONG;
                      Args           : pRxString;
                      QueueName      : PCHAR;
                      VAR Ret        : RxString) : ULONG;
    VAR
        Rec            : TDataRec;
        Strg           : AnsiString;
        Flag           : shortSTRING;
        I,
        J              : BYTE;
    BEGIN
        Result := 40;
        SetRet('', Ret);

        IF KRIniTree = NIL THEN
            EXIT;

        IF ArgC <> 3 THEN
            EXIT;

        Result := 0;

        IF NOT KRIniTree^.GetRec(TRecType(GetNthArgLong(Args, 1)), {1..6}
                                 GetNthArgLong(Args, 2), {1..Nth record}
                                 Rec) THEN
            EXIT;

        with Rec do begin
            Description := UnQuoteEqual(Description);
            UserID := UnQuoteEqual(UserID);
            Password := UnQuoteEqual(Password);
            SerialNum := UnQuoteEqual(SerialNum);
            URL := UnQuoteEqual(URL);
            Note := UnQuoteEqual(Note);
        end;

        Flag := StUpCase(GetNthArgString(Args, 3));

            CASE Flag[1] OF
                'I' :
                        Strg := Rec.Icon;
                'D' :             {2 desc}
                        Strg := Rec.Description;
                'N' :             {3 userid}
                        Strg := Rec.UserID;
                'P' :             {4 password}
                        Strg := Rec.Password;
                'S' :             {5 serial num}
                        Strg := Rec.SerialNum;
                'L' :             {6 last update}
                        Strg := Rec.LastUpdate;
                'E' :             {7 expire date}
                        Strg := Rec.Expire;
                'U' :             {8 url}
                        Strg := Rec.URL;
                'W' :             {9 note}
                        Strg := Rec.Note;
                'O' : ;           {this one is always last, so ignore it for now}
                ELSE BEGIN
                    Result := 40; {invalid flag, so bomb}
                    EXIT;
                END;
            END;

        Result := 0;

        SetRet(Strg, Ret);
    END;

    {--------------}

VAR
    RecPage,
    RecIndx        : WORD;
    {returns:
        0                                = alldone
        3�asdf�very�long�formatted�string" = pgnumber plus expired record fields
    }
    {Get an expired record                                            1             2        3        4        5        6      7      8          9       10      11       12       13    14              }
    FUNCTION KRGetExpiredRec(Name           : PCHAR; {KRGetExpiredRec(Init:BOOLEAN; FldOrder IconFID, DescFID, UserFID, PWFID, SNFID, UpdateFID, ExpFID, URLFID, NoteFID, OrderId, PgId, IndxID : STRING;) : STRING}
                             ArgC           : ULONG;
                             Args           : pRxString;
                             QueueName      : PCHAR;
                             VAR Ret        : RxString) : ULONG;
    VAR
        Rec            : TDataRec;
        Strg           : AnsiString;
        DTR,
        Now            : DateTimeRec;

    BEGIN
        Result := 40;
        SetRet('0', Ret);


        IF KRIniTree = NIL THEN
            EXIT;


        IF ArgC <> 14 THEN
            EXIT;


        Result := 0;

        IF GetNthArgBool(Args, 1) THEN BEGIN
            RecPage := 1;
            RecIndx := 1;
        END;

        {search forward until we find an expired rec}
        REPEAT
            IF KRIniTree^.GetRecCount(TRecType(RecPage)) < RecIndx THEN BEGIN
                {completed current page, so increment to the next one}
                INC(RecPage);
                {reset record counter}
                RecIndx := 1;
            END
            ELSE BEGIN
                IF NOT KRIniTree^.GetRec(TRecType(RecPage), {1..6} RecIndx, {1..Nth record} Rec) THEN
                    EXIT;         {should never get here, but bail with retval of "0" if badrec}
                INC(RecIndx);     {got a valid record so bump to the next one}

                {test the expiration date- has it expired?}
                IF Rec.Expire = '' THEN
                    CONTINUE;     {no expiration date}

                NowStringToDTR(Rec.Expire, TRUE, TRUE, DTR); {translate string into DTR}
                DTRNow(Now);

                IF DTRCompare(Now, DTR) <> Greater THEN
                    {not expired so continue}
                    CONTINUE;
                BREAK;            {found an expired record, so break loop and process below}
            END;

            {did we hit the end of pages?}
            IF RecPage > ORD(HIGH(TRecType)) THEN BEGIN
                {hit end of db, so return alldone flag}
                EXIT;
            END;
        UNTIL FALSE;

         with Rec do begin
            Description := UnQuoteEqual(Description);
            UserID := UnQuoteEqual(UserID);
            Password := UnQuoteEqual(Password);
            SerialNum := UnQuoteEqual(SerialNum);
            URL := UnQuoteEqual(URL);
            Note := UnQuoteEqual(Note);
        end;

        Result := BuildDelimitedRecStrg(Args, Rec, 3, Strg);

        Strg := CatStr(Strg, GetNthArgString(Args, 13)); {Pgfield}
        Strg := CatStr(Strg, Long2Str(RecPage));

        Strg := CatStr(Strg, GetNthArgString(Args, 14)); {Indxfield}
        Strg := CatStr(Strg, Long2Str(RecIndx - 1)); {rollback index to point to *this* object, not the next one}

        SetRet(Strg, Ret);
    END;

    {--------------}


    {                                                   1        2                 3         4    5     6     7   8   9       10   11   12}
    FUNCTION KRPutRec(Name           : PCHAR; {KRGetRec(RecType, RecNum : LONGINT; FldOrder, Ico, Desc, User, Pw, Sn, Update, Exp, Url, Note : STRING) : BOOLEAN}
                      ArgC           : ULONG;
                      Args           : pRxString;
                      QueueName      : PCHAR;
                      VAR Ret        : RxString) : ULONG;
    VAR
        I              : BYTE;
        Rec            : TDataRec;
        Flag,
        Strg           : STRING;
    CONST
        HandleOffset   = 4;
    BEGIN
        Result := 40;
        SetRet('0', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        IF ArgC <> 12 THEN
            EXIT;

        Result := 0;

        Flag := GetNthArgString(Args, HandleOffset - 1); {get order flags (always one param to the left of the handles)}
        FOR I := 1 TO LENGTH(Flag) DO BEGIN
            CASE Flag[I] OF
                'I' :
                    Rec.Icon := GetNthArgString(Args, I + HandleOffset - 1);
                'D' :             {2 desc}
                    Rec.Description := QuoteEqual(GetNthArgString(Args, I + HandleOffset - 1));
                'N' :             {3 userid}
                    Rec.UserID := QuoteEqual(GetNthArgString(Args, I + HandleOffset - 1));
                'P' :             {4 password}
                    Rec.Password := QuoteEqual(GetNthArgString(Args, I + HandleOffset - 1));
                'S' :             {5 serial num}
                    Rec.SerialNum := QuoteEqual(GetNthArgString(Args, I + HandleOffset - 1));
                'L' :             {6 last update}
                    Rec.LastUpdate := GetNthArgString(Args, I + HandleOffset - 1);
                'E' :             {7 expire date}
                    Rec.Expire := GetNthArgString(Args, I + HandleOffset - 1);
                'U' :             {8 url}
                    Rec.URL := QuoteEqual(GetNthArgString(Args, I + HandleOffset - 1));
                'W' :             {9 note}
                    Rec.Note := QuoteEqual(GetNthArgString(Args, I + HandleOffset - 1));
                'O' : ;           {just ignore it}
                ELSE BEGIN
                    Result := 40; {invalid flag, so bomb}
                    EXIT;
                END;
            END;
        END;
        IF NOT KRIniTree^.PutRec(TRecType(GetNthArgLong(Args, 1)) {1..6} , GetNthArgLong(Args, 2), Rec) THEN
            EXIT;

        SetRet('1', Ret);
    END;

    {--------------}

    FUNCTION KRDisposeINI(Name           : PCHAR;
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 0;
        IF KRIniTree = NIL THEN
            EXIT;
        DISPOSE(KRIniTree, Done);
        IF ScnMsgP <> NIL THEN BEGIN
            DISPOSE(ScnMsgP, Done);
            ScnMsgP := NIL;
        END;
        KRIniTree := NIL;
        SetRet('1', Ret);
        Result := 0;
    END;

    {--------------}

    FUNCTION KRGetCryptType(Name           : PCHAR;
                            ArgC           : ULONG;
                            Args           : pRxString;
                            QueueName      : PCHAR;
                            VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 0;
        SetRet(GetCrypter, Ret);
    END;

    {--------------}

    FUNCTION KRGetTime(Name           : PCHAR;
                       ArgC           : ULONG;
                       Args           : pRxString;
                       QueueName      : PCHAR;
                       VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 0;
        SetRet(NowStringDeluxe(TRUE, TRUE), Ret);
    END;

    {--------------}

    FUNCTION KRCalcDate(Name           : PCHAR; {KRCalcDate(OldDate:STRING; IncDays:LONGINT):STRING}
                        ArgC           : ULONG;
                        Args           : pRxString;
                        QueueName      : PCHAR;
                        VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        DTR            : DateTimeRec;
        OldDate        : STRING;
        IncDays        : LONGINT;
    BEGIN
        Result := 0;

        OldDate := GetNthArgString(Args, 1); {get old date if any}
        IF OldDate = '' THEN
            OldDate := NowStringDeluxe(TRUE, TRUE); {default to now}

        NowStringToDTR(OldDate, TRUE, TRUE, DTR); {translate string into DTR}
        DTR.T := 0;
        IncDays := GetNthArgLong(Args, 2);
        IF IncDays > 0 THEN BEGIN
            INC(DTR.D, IncDays);  {increment DTR by # days}
        END
        ELSE
            DTR.D := Today + 1;

        SetRet(DTRtoStringDeluxe(DTR, TRUE, TRUE), Ret); {return new date string}
    END;

    {--------------}

    FUNCTION KRGetToday(Name           : PCHAR; {KRGetToday(Mode:LONGINT):STRING}
                        ArgC           : ULONG;
                        Args           : pRxString;
                        QueueName      : PCHAR;
                        VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Day,
        Month,
        Year : Integer;
    BEGIN
        Result := 0;

        DateToDMY(Today, Day, Month, Year); // get today's date in dmy

        case GetNthArgLong(Args, 1) of // get the mode and return the requested d/m/y value
            1 : {day}
                SetRet(Long2Str(Day), Ret);
            2 : {Month}
                SetRet(Long2Str(Month), Ret);
            3 : {Year}
                SetRet(Long2Str(Year), Ret);
            else
                Result := 40; // invalid mode - crash
        end; {case}
    END;

    {--------------}

    FUNCTION KRGetTodayJulian(Name           : PCHAR; {KRGetTodayJulian():STRING}
                              ArgC           : ULONG;
                              Args           : pRxString;
                              QueueName      : PCHAR;
                              VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 0;
        SetRet(Long2Str(Today), Ret);
    END;

    {--------------}

    FUNCTION KRJulian2DMY(Name           : PCHAR; {KRGetToday(Mode:LONGINT):STRING}
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Date : LONGINT;
        Day,
        Month,
        Year : Integer;
    BEGIN
        Result := 0;

        DateToDMY(GetNthArgLong(Args, 1), Day, Month, Year); // get dmy from julian date

        case GetNthArgLong(Args, 2) of // get the mode and return the requested d/m/y value
            1 : {day}
                SetRet(Long2Str(Day), Ret);
            2 : {Month}
                SetRet(Long2Str(Month), Ret);
            3 : {Year}
                SetRet(Long2Str(Year), Ret);
            else
                Result := 40; // invalid mode - crash
        end; {case}
    END;

    {--------------}


    FUNCTION KRDMY2Julian(Name           : PCHAR; {KRGetToday(Mode:LONGINT):STRING}
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Day,
        Month,
        Year : Longint;
        Julian : LONGINT;
    BEGIN
        Result := 0;

        Day := GetNthArgLong(Args, 1);
        Month := GetNthArgLong(Args, 2);
        Year := GetNthArgLong(Args, 3);
        ForceValidDate(Day, Month, Year);

        Julian := DMYtoDate(Day, Month, Year);

        SetRet(Long2Str(Julian), Ret);
    END;

    {--------------}

    {calc #days between DMY date and today}
    FUNCTION KRCalcDMYOffset(Name           : PCHAR; {KRCalcDMYOffset(D, M, Y:LONGINT):LONGINT}
                             ArgC           : ULONG;
                             Args           : pRxString;
                             QueueName      : PCHAR;
                             VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        DTR,
        DTRN           : DateTimeRec;
        OldDate        : STRING;
        Days : LONGINT;
        D,
        M,
        Y              : INTEGER;
    BEGIN
        Result := 0;
        DTRNow(DTRN);

        DTR.T := 0;
        DTR.D := DMYtoDate(GetNthArgLong(Args, 1), GetNthArgLong(Args, 2), GetNthArgLong(Args, 3));
        Days := DTR.d - DTRN.d;
        SetRet(Long2Str(Days), Ret); {return difference in days from today}
    END;

    {--------------}

    {Translate DMY to date string}
    FUNCTION KRDMY2Date(Name           : PCHAR; {KRDMY2Date(D, M, Y:LONGINT):STRING}
                        ArgC           : ULONG;
                        Args           : pRxString;
                        QueueName      : PCHAR;
                        VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        DTR            : DateTimeRec;
        D,
        M,
        Y : INTEGER;
    BEGIN
        Result := 0;
        DTR.T := 0;

        D := GetNthArgLong(Args, 1);
        M := GetNthArgLong(Args, 2);
        Y := GetNthArgLong(Args, 3);
        ForceValidDate(D,M,Y);

        DTR.D := DMYtoDate(D, M, Y);

        SetRet(copy(DTRtoStringDeluxe(DTR, TRUE, TRUE),1,10), Ret); {return new date string}
    END;

    {--------------}

    {Return either Day, Month or Year of Date, given string date and the desired mode}
    FUNCTION KRDate2DMY(Name           : PCHAR; {KRDate2DMY(Date:STRING; Mode:TDMYMode):LONGINT}
                        ArgC           : ULONG;
                        Args           : pRxString;
                        QueueName      : PCHAR;
                        VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        DTR            : DateTimeRec;
        OldDate        : STRING;
        D,
        M,
        Y              : INTEGER;
    BEGIN
        Result := 0;

        OldDate := GetNthArgString(Args, 1); {get old date if any}
        IF OldDate = '' THEN
            OldDate := NowStringDeluxe(TRUE, TRUE) {default to now}
        ELSE
            OldDate := OldDate + ' 00:00:00';

        DTR.T := 0;
        NowStringToDTR(OldDate, TRUE, TRUE, DTR); {translate string into DTR}
        if dtr.d = baddate then begin {this should not happen, but for paranoias sake...}
            Result := 40;
            exit;
        end;

        DateToDMY(DTR.D, D, M, Y);

        case GetNthArgLong(Args, 2) of
            1 : {day}
                SetRet(Long2Str(D), Ret);
            2 : {Month}
                SetRet(Long2Str(M), Ret);
            3 : {Year}
                SetRet(Long2Str(Y), Ret);
            else
                Result := 40;
        end; {case}
    END;

    {--------------}

    FUNCTION KRKillBranch(Name           : PCHAR; {KRDelRec(RecType: LONGINT) : BOOLEAN}
                          ArgC           : ULONG;
                          Args           : pRxString;
                          QueueName      : PCHAR;
                          VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 0;
        SetRet('0', Ret);

        IF KRIniTree = NIL THEN
            EXIT;

        IF KRIniTree^.DelBranch(DecodeStrg(SESTRS2, SESTRN2, SESTRP2) {'>:SecretStuff:'} + RecTypeNames[TRecType(GetNthArgLong(Args, 1))]) THEN
            SetRet('1', Ret);
    END;

    {--------------}

    {returns:
        99  - expired product
        200 - invalid file or bad password

        Note: Password is superfluous - use by future crypt in application only
    }
    FUNCTION KRImport(Name           : PCHAR; { PROCEDURE KRImport(PWCName, Password:STRING):ULONG }
                      ArgC           : ULONG;
                      Args           : pRxString;
                      QueueName      : PCHAR;
                      VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    var
        PMale : PTreeReader;
    BEGIN
        Result := 40;
        RANDOMIZE;
        SetRet(DecodeStrg(SESTRS36, SESTRN36, SESTRP36) {0} , Ret);
{$IFDEF BLOWOFFOLD}
        {close the file if it is already open - no save!}
        IF KRIniTree <> NIL THEN BEGIN
            DISPOSE(KRIniTree, Done);
        END;
        KRIniTree := NIL;
        IF FileExists(GetNthArgString(Args, 1)) THEN BEGIN
            NEW(KRIniTree, InitRead(GetNthArgString(Args, 1), GetNthArgString(Args, 2), FALSE)); {read clear text import file, if any}
            IF KRIniTree = NIL THEN BEGIN {bad pw or missing file}
                SetRet(DecodeStrg(SESTRS38, SESTRN38, SESTRP38) {200} , Ret);
                Result := 0;
                EXIT;
            END;
            SetRet(DecodeStrg(SESTRS35, SESTRN35, SESTRP35) {1} , Ret); {success!}
        END;
        Result := 0;
        IF KRIniTree^.PWXLifetimeExpired THEN BEGIN
            DISPOSE(KRIniTree, Done);
            KRIniTree := NIL;
            SetRet(DecodeStrg(SESTRS37, SESTRN37, SESTRP37) {99} , Ret); {dropdead expired}
        END;
{$ELSE}
        IF FileExists(GetNthArgString(Args, 1)) THEN BEGIN
            NEW(PMale, InitRead(GetNthArgString(Args, 1), GetNthArgString(Args, 2), FALSE)); {read clear text import file, if any}
            IF PMale = NIL THEN BEGIN {bad pw or missing file}
                SetRet(DecodeStrg(SESTRS38, SESTRN38, SESTRP38) {200} , Ret);
                Result := 0;
                EXIT;
            END;
        END;
        Result := 0;
        IF PMale^.PWXLifetimeExpired THEN BEGIN
            DISPOSE(KRIniTree, Done);
            KRIniTree := NIL;
            SetRet(DecodeStrg(SESTRS37, SESTRN37, SESTRP37) {99} , Ret); {dropdead expired}
            EXIT;
        END;
        IF NOT KRIniTree^.MergeTree(PMale) THEN BEGIN
            SetRet(DecodeStrg(SESTRS38, SESTRN38, SESTRP38) {200} , Ret);
            DISPOSE(PMale, Done);
            Result := 0;
            EXIT;
        END
        else
            SetRet(DecodeStrg(SESTRS35, SESTRN35, SESTRP35) {1} , Ret); {success!}

        DISPOSE(PMale, Done);
        Result := 0;
{$ENDIF}
    END;

    {--------------}

    FUNCTION KRGetPageName(Name           : PCHAR; { FUNCTION KRGetPageName(Num : WORD) : STRING }
                           ArgC           : ULONG;
                           Args           : pRxString;
                           QueueName      : PCHAR;
                           VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        N              : WORD;
    BEGIN
        Result := 0;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        N := GetNthArgLong(Args, 1);
        IF (N < 1) OR (N > 7) THEN BEGIN {allow boss page (7) lookup on this one}
            Result := 40;
            EXIT;
        END;
        SetRet(KRIniTree^.GetPageName(N), Ret);
    END;

    {--------------}

    FUNCTION KRGetPageHint(Name           : PCHAR; { FUNCTION KRGetPageHint(Num : WORD) : STRING }
                           ArgC           : ULONG;
                           Args           : pRxString;
                           QueueName      : PCHAR;
                           VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        N              : WORD;
    BEGIN
        Result := 0;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        N := GetNthArgLong(Args, 1);
        IF (N < 1) OR (N > 6) THEN BEGIN
            Result := 40;
            EXIT;
        END;
        SetRet(KRIniTree^.GetPageHint(N), Ret);
    END;

    {--------------}

    FUNCTION KRGetPageIcon(Name           : PCHAR; { FUNCTION KRGetPageIcon(Num : WORD) : STRING }
                           ArgC           : ULONG;
                           Args           : pRxString;
                           QueueName      : PCHAR;
                           VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        N              : WORD;
    BEGIN
        Result := 0;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        N := GetNthArgLong(Args, 1);
        IF (N < 1) OR (N > 6) THEN BEGIN
            Result := 40;
            EXIT;
        END;
        SetRet(KRIniTree^.GetPageIcon(N), Ret);
    END;

    {--------------}

    FUNCTION KRGetPageOrdEnb(Name           : PCHAR; { FUNCTION KRGetPageOrdEnb(PgNum : WORD) : STRING "0�U" }
                             ArgC           : ULONG;
                             Args           : pRxString;
                             QueueName      : PCHAR;
                             VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        PG             : BYTE;
    CONST
        AllOff =
        '0' + FieldSep + 'I' +
        '0' + FieldSep + 'D' +
        '0' + FieldSep + 'N' +
        '0' + FieldSep + 'P' +
        '0' + FieldSep + 'S' +
        '0' + FieldSep + 'L' +
        '0' + FieldSep + 'E' +
        '0' + FieldSep + 'U' +
        '0' + FieldSep + 'W';
    BEGIN
        Result := 0;

        {set up error condition return val}
        SetRet(AllOff, Ret);

        {bail if non-init database}
        IF KRIniTree = NIL THEN
            EXIT;

        {check the arg count}
        IF ArgC <> 1 THEN BEGIN
            Result := 40;
            EXIT;
        END;

        {get the page number}
        PG := GetNthArgLong(Args, 1);

        {make sure the page number is valid}
        IF (PG < 1) OR (PG > 6) THEN BEGIN
            Result := 40;
            EXIT;
        END;

        {look up flag and enabled status of this page}
        SetRet(KRIniTree^.GetPageOrdEnb(PG), Ret);
    END;

    {--------------}

    FUNCTION KRGetColumnEnable(Name           : PCHAR; { FUNCTION KRGetColumnEnable(PgNum, FldNum : WORD) : STRING "0�U�urlhinthinthint�abbrev" }
                               ArgC           : ULONG;
                               Args           : pRxString;
                               QueueName      : PCHAR;
                               VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        Fld            : BYTE;
        PG             : WORD;
        Abbrev,
        Hint,
        Enb,
        Flag           : shortSTRING;
    BEGIN
        Result := 0;
        {set up error condition return val}
        SetRet('0' + FieldSep, Ret);

        {bail if non-init database}
        IF KRIniTree = NIL THEN
            EXIT;

        {check the arg count}
        IF ArgC <> 2 THEN
            EXIT;

        {get the page number}
        PG := GetNthArgLong(Args, 1);

        {make sure the page number is valid}
        IF (PG < 1) OR (PG > 7) THEN BEGIN
            Result := 40;
            EXIT;
        END;

        {get the column/field number}
        Fld := GetNthArgLong(Args, 2); {1..9}
        {validate the field number}
        IF (Fld < 1) OR (Fld > 9) THEN BEGIN
            Result := 40;
            EXIT;
        END;

        IF PG = 7 THEN BEGIN
            {if boss page, then return disabled column flag for all fields}
            SetRet('0' + FieldSep + DefaultFlg[Fld] + FieldSep + '' + Fieldsep + '', Ret);
            EXIT;
        END;

        {look up flag and enabled status of this field}
        IF NOT KRIniTree^.GetColumnEnable(PG, Fld, Enb, Flag, Hint, Abbrev) THEN BEGIN
            {not found in the database tree, so add a default entry to the tree (enabled)}
            KRIniTree^.PutColumnEnable(PG, Fld, '1', DefaultFlg[Fld], '', '');
            {return the default field status - enabled with natural order flag, no hint}
            SetRet('1' + FieldSep + DefaultFlg[Fld] + FieldSep, Ret);
            EXIT;
        END;

        IF Flag = '' THEN BEGIN
            Flag := DefaultFlg[Fld]; {something died - set to defaults}
            KRIniTree^.PutColumnEnable(PG, Fld, '1', Flag, '', Abbrev);
        END;

        {found the entry in tree, so return the enabled status concatenated with the flag value}
        SetRet(Enb + FieldSep + Flag + FieldSep + Hint + fieldsep + abbrev, Ret);
    END;

    {--------------}

    {return the column name for this field, or an empty string if not found}
    FUNCTION KRGetColumnName(Name           : PCHAR; { FUNCTION KRGetColumnName(Pg, Colnum : WORD) : STRING}
                             ArgC           : ULONG;
                             Args           : pRxString;
                             QueueName      : PCHAR;
                             VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        P,
        C              : WORD;
    BEGIN
        Result := 40;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        P := GetNthArgLong(Args, 1);
        IF (P < 1) OR (P > 6) THEN
            EXIT;
        C := GetNthArgLong(Args, 2);
        IF (C < 1) OR (C > 9) THEN
            EXIT;
        Result := 0;
        SetRet(KRIniTree^.GetColName(P, C), Ret);
    END;

    {--------------}

    FUNCTION KRPutPageName(Name           : PCHAR; { FUNCTION KRPutPageName(Num : WORD; Name : STRING) : BOOLEAN }
                           ArgC           : ULONG;
                           Args           : pRxString;
                           QueueName      : PCHAR;
                           VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        P              : WORD;
    BEGIN
        Result := 40;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        IF ArgC <> 2 THEN
            EXIT;
        P := GetNthArgLong(Args, 1);
        IF (P < 1) OR (P > 6) THEN
            EXIT;
        IF KRIniTree^.PutPageName(P, GetNthArgString(Args, 2)) THEN
            Result := 0;
    END;

    {--------------}

    FUNCTION KRPutPageHint(Name           : PCHAR; { FUNCTION KRPutPageHint(Num : WORD; Hint : STRING) : BOOLEAN }
                           ArgC           : ULONG;
                           Args           : pRxString;
                           QueueName      : PCHAR;
                           VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        P              : WORD;
    BEGIN
        Result := 40;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        IF ArgC <> 2 THEN
            EXIT;
        P := GetNthArgLong(Args, 1);
        IF (P < 1) OR (P > 6) THEN
            EXIT;
        IF KRIniTree^.PutPageHint(P, GetNthArgString(Args, 2)) THEN
            Result := 0;
    END;

    {--------------}

    FUNCTION KRPutPageIcon(Name           : PCHAR; { FUNCTION KRPutPageIcon(Num : WORD; Icon : STRING) : BOOLEAN }
                           ArgC           : ULONG;
                           Args           : pRxString;
                           QueueName      : PCHAR;
                           VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        P              : WORD;
    BEGIN
        Result := 40;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        IF ArgC <> 2 THEN
            EXIT;
        P := GetNthArgLong(Args, 1);
        IF (P < 1) OR (P > 6) THEN
            EXIT;
        IF KRIniTree^.PutPageIcon(P, GetNthArgString(Args, 2)) THEN
            Result := 0;
    END;

    {--------------}

    FUNCTION KRPutColumnEnable(Name           : PCHAR; { FUNCTION KRPutColumnEnable(Pg, Fld : WORD; Enb : STRING; Flag : STRING, Hint:STRING; Abbrev:STRING) : BOOLEAN }
                               ArgC           : ULONG;
                               Args           : pRxString;
                               QueueName      : PCHAR;
                               VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        C,
        P              : WORD;
        Abbrev,
        Hint,
        Enb,
        Flag           : STRING;
    BEGIN
        Result := 40;
        SetRet('0', Ret);

        IF KRIniTree = NIL THEN
            EXIT;

        IF ArgC <> 6 THEN
            EXIT;

        P := GetNthArgLong(Args, 1); {get the page number}
        IF (P < 1) OR (P > 6) THEN
            EXIT;

        C := GetNthArgLong(Args, 2);
        IF (C < 1) OR (C > 9) THEN
            EXIT;


        Enb := GetNthArgString(Args, 3);
        Flag := GetNthArgString(Args, 4);
        Hint := GetNthArgString(Args, 5);
        Abbrev := GetNthArgString(Args, 6);
        Result := 0;

        IF KRIniTree^.PutColumnEnable(P, C, Enb, Flag, Hint, Abbrev) THEN {update the tree}
            SetRet('1', Ret);
    END;

    {--------------}

    FUNCTION KRPutColumnName(Name           : PCHAR; { FUNCTION KRPutColumnName(Pg, Colnum : WORD; ColName:STRING) : STRING}
                             ArgC           : ULONG;
                             Args           : pRxString;
                             QueueName      : PCHAR;
                             VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        P,
        C              : WORD;
    BEGIN
        Result := 40;
        SetRet('', Ret);
        IF KRIniTree = NIL THEN
            EXIT;
        IF ArgC <> 3 THEN
            EXIT;
        P := GetNthArgLong(Args, 1);
        IF (P < 1) OR (P > 6) THEN
            EXIT;
        C := GetNthArgLong(Args, 2);
        IF (C < 1) OR (C > 9) THEN
            EXIT;
        IF KRIniTree^.PutColName(P, C, GetNthArgString(Args, 3)) THEN
            Result := 0;
    END;

    {--------------}
{$IFDEF NOPF}
VAR
    TSP            : TSoundPlayer;

    FUNCTION KRPlayIntro(Name           : PCHAR; { PROCEDURE KRPlayIntro(MIDIName : STRING);}
                         ArgC           : ULONG;
                         Args           : pRxString;
                         QueueName      : PCHAR;
                         VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        FName          : STRING;
    BEGIN
        Result := 0;
        FName := GetNthArgString(Args, 1);
        IF NOT FileExists(FName) THEN
            EXIT;

        TSP := TSoundPlayer.Create;
        TSP.AddSong(FName);
        TSP.PlayBackGround(0);
    END;

    {--------------}
{$ENDIF NOPF}

VAR
    DTR1           : DateTimeRec;

    FUNCTION QueryStat(DTR : DateTimeRec) : BOOLEAN; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        J,
        I              : LONGINT;
    BEGIN
        Result := TRUE;
        EXIT;
        J := 0;
        FOR I := 1 TO 30 DO BEGIN
            CASE I OF
                1..5 :
                    BEGIN
                        DTRNow(DTR1);
                        INC(J, DateTimeDiffSecs(DTR, DTR1));
                    END;
                6..10 :
                    BEGIN
                        DEC(J, DateTimeDiffSecs(DTR, DTR1));
                    END;
                11..30 :
                    BEGIN
                        DTRNow(DTR1);
                        INC(J, DateTimeDiffSecs(DTR, DTR1));
                    END;
            END;
        END;
        Result := TRUE;
    END;

    {--------------}
{$IFDEF NOPF}
    FUNCTION KRKillIntro(Name           : PCHAR; { PROCEDURE KRKillIntro(MIDIName : STRING);}
                         ArgC           : ULONG;
                         Args           : pRxString;
                         QueueName      : PCHAR;
                         VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        Result := 0;
        IF TSP = NIL THEN
            EXIT;
        TSP.AbortAll;
        TSP.Destroy;
        TSP := NIL;
    END;
{$ENDIF NOPF}
    {--------------}

    FUNCTION KRGetDefaultOrder(Name           : PCHAR; { FUNCTION KRGetDefaultOrder() : STRING}
                               ArgC           : ULONG;
                               Args           : pRxString;
                               QueueName      : PCHAR;
                               VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        I              : BYTE;
        Strg           : STRING;
    BEGIN
        Result := 0;              {cant fail, no params}
        Strg := '';
        FOR I := LOW(DefaultFlg) TO HIGH(DefaultFlg) DO
            Strg := Strg + DefaultFlg[I];
        SetRet(Strg, Ret);
    END;

    {--------------}

VAR
    curchallenge   : LONGINT;

    FUNCTION KRSetChallengeA(FuncName       : PCHAR;
                             ArgC           : ULONG;
                             Args           : pRxString;
                             QueueName      : PCHAR;
                             VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    BEGIN
        RANDOMIZE;
        curchallenge := RandPosLong;
        SetRet(Long2Str(curchallenge), Ret);
        Result := 0;
    END;

    {--------------}

    { PROCEDURE KROpenINI(Name, Password:STRING):ULONG }
    {returns:
        99  - expired product
        100 - new pwx created (filename did not exist)
        200 - invalid file or bad password
        207 - PWX lifetime expired
    }
    FUNCTION KROpenINI(Name           : PCHAR;
                       ArgC           : ULONG;
                       Args           : pRxString;
                       QueueName      : PCHAR;
                       VAR Ret        : RxString) : ULONG; {$IFDEF DLL}EXPORT;{$ENDIF}
    VAR
        StrobeOK       : BOOLEAN;
    BEGIN
        Result := 40;
        ChangeInternationalDateFmt(TRUE, TRUE);
        RANDOMIZE;
        SetRet(DecodeStrg(SESTRS36, SESTRN36, SESTRP36) {0} , Ret);
        {close the file if it is already open - no save!}
        IF KRIniTree <> NIL THEN BEGIN
            DISPOSE(KRIniTree, Done);
        END;
        KRIniTree := NIL;
        StrobeOK := TestStrobe;
        IF FileExists(GetNthArgString(Args, 1)) THEN BEGIN
            NEW(KRIniTree, InitRead(GetNthArgString(Args, 1), GetNthArgString(Args, 2), TRUE)); {read group addresses, if ini exists}
            IF KRIniTree = NIL THEN BEGIN {bad pw or missing file}
                SetRet(DecodeStrg(SESTRS38, SESTRN38, SESTRP38) {200} , Ret);
                Result := 0;
                EXIT;
            END;
            SetRet(DecodeStrg(SESTRS35, SESTRN35, SESTRP35) {1} , Ret); {success!}
            {$IFDEF DLL}
            IF KRIniTree^.EXEDropDeadExpired THEN BEGIN
                SetRet(DecodeStrg(SESTRS37, SESTRN37, SESTRP37) {99} , Ret); {dropdead expired}
                LogIt(DecodeStrg(SESTRS43, SESTRN43, SESTRP43) {KEYRING2.ERR}, DecodeStrg(SESTRS46, SESTRN46, SESTRP46) {EXE dropdead fail} );
            END;
            {$ENDIF}
            END
        ELSE BEGIN
            DTRNow(CurrInceptDate); {reset incept to now, since we are creating a new file}
            NEW(KRIniTree, InitWrite(GetNthArgString(Args, 1))); {create empty INI if none exists}
            IF KRIniTree = NIL THEN
                EXIT;
            IF NOT KRIniTree^.CreateBranch(DecodeStrg(SESTRS1, SESTRN1, SESTRP1) {'>:SecretStuff'} ) THEN
                EXIT;
            KRIniTree^.SetRoot(DecodeStrg(SESTRS1, SESTRN1, SESTRP1) {'>:SecretStuff'} );
            SetRet(DecodeStrg(SESTRS39, SESTRN39, SESTRP39) {100} , Ret); {new pwx created}
        END;
        Result := 0;
        IF NOT StrobeOK THEN BEGIN
            DISPOSE(KRIniTree, Done);
            LogIt(DecodeStrg(SESTRS43, SESTRN43, SESTRP43){KEYRING2.ERR}, DecodeStrg(SESTRS44, SESTRN44, SESTRP44) {strobe fail} );
            KRIniTree := NIL;
            SetRet(DecodeStrg(SESTRS42, SESTRN42, SESTRP42) {207} , Ret); {PWX expired}
            EXIT;
        END;
        IF KRIniTree^.PWXLifetimeExpired THEN BEGIN
            DISPOSE(KRIniTree, Done);
            KRIniTree := NIL;
            LogIt(DecodeStrg(SESTRS43, SESTRN43, SESTRP43){KEYRING2.ERR}, DecodeStrg(SESTRS45, SESTRN45, SESTRP45) {pwxlifetime fail} );
            SetRet(DecodeStrg(SESTRS42, SESTRN42, SESTRP42) {207} , Ret); {PWX expired}
            EXIT;
        END;
        {$IFDEF DLL}
        IF KRIniTree^.EXEDropDeadExpired THEN BEGIN
            SetRet(DecodeStrg(SESTRS37, SESTRN37, SESTRP37) {99} , Ret); {dropdead expired}
            LogIt(DecodeStrg(SESTRS43, SESTRN43, SESTRP43){KEYRING2.ERR}, DecodeStrg(SESTRS46, SESTRN46, SESTRP46) {EXE dropdead fail} );
            DISPOSE(KRIniTree, Done);
            KRIniTree := NIL;
            EXIT;
        END;
        {$ENDIF}
    END;

    {--------------}

    INITIALIZATION
END.

    {--------------}
    {--------------}
