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
* Generic user-challenge password object.  When user runs this object, a
* "challenge" is issued to the customer.  The customer must call
* Customer Support and give both the "challenge" and "UserName" to the support
* person.  The support person enters both fields and the object will create
* a "reply".  The reply is told to the customer who types it into his reply
* field.  If everything was typed in O.K., this unit will verify that the
* reply matches the name/challenge and let the customer proceed.
*
* Includes both the end-user and customer support entrypoints.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
}

UNIT REVENUE;

INTERFACE

    {$I OPDEFINE.INC}
    {$A-,B-,D+,E+,F+,G+,I+,L+,N-,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

USES
    Dos,
    OpDate,
    OpEntry;

TYPE
    CloneRec       = RECORD
                         R1L            : LONGINT;
                         TDDD           : DateTimeRec;
                         R2L            : LONGINT;
                         R3L            : LONGINT;
                         IDDD           : DateTimeRec;
                         R4B            : BYTE;
                         LU             : DateTimeRec;
                         R5L            : LONGINT;
                         CS             : LONGINT;
                     END;

CONST
    CloneID        : STRING[5] = 'N6EKI';
    CloneData      : CloneRec =
    (R1L            : 0;
     TDDD           : (D : 144000; T : 0);
               R2L            : 0;
               R3L            : 0;
               IDDD           : (D : 144000; T : 0);
                         R4B            : 0;
                         LU             : (D : 144000; T : 0);
                                     R5L            : 0;
                                     CS             : - 2002217851
                                     );
    MaxFullName    = 41;


TYPE

    DateStatT      = (DateOk, DATEWARN, DATEFAIL);
    ReplyStatT     = (ETDGValid, EIDKValid, EInvalid);
    RevenueModeT   = (EUSER, ESUPPORT, EStamp);

    RevenueChallengeP = ^RevenueChallengeT;
    RevenueChallengeT = OBJECT(EntryScreen)
                            {for user entry}
                            CONSTRUCTOR Init;

                            {constructor for support program only!}
                            CONSTRUCTOR InitDeluxe;

                            CONSTRUCTOR InitStamp(ExeName : PathStr);

                            FUNCTION OkToRun : BOOLEAN;

                        PRIVATE

                            FullName       : STRING[MaxFullName];
                            Challenge      : LONGINT;
                            REPLY          : STRING[25];
                            OkToRunFlag    : BOOLEAN;
                            ModeFlg        : RevenueModeT;
                            TDDead,
                            IDDead         : Date;

                            PROCEDURE ProcessSelf; VIRTUAL;

                                {verify user challenge/reply.  TRUE if ok, FALSE}
                                {if not verified                                }
                            FUNCTION CheckReply : ReplyStatT;
                                {create 32bit random challenge}
                            PROCEDURE CreateChallenge;
                                {calculate crc of users name}
                            FUNCTION CalcNameCRC : LONGINT;
                                {screen help}
                            PROCEDURE esPreEdit; VIRTUAL;
                                {calc entry screen fields}
                            PROCEDURE esPostEdit; VIRTUAL;
                                {generic ES builder}
                            FUNCTION InitES : BOOLEAN;
                                {calc the valid reply to name/challenge}
                            FUNCTION CalcReply(Mode : ReplyStatT) : STRING;

                            FUNCTION DecodeStrg(S : STRING; PubKey, PrivKey : WORD) : STRING;

                            FUNCTION CalcCRC(T : LONGINT; VAR D; DSize : BYTE) : LONGINT;
                            FUNCTION CalcStringCRC(Strg : STRING) : LONGINT;
                            FUNCTION CalcCloneCRC : LONGINT;
                            FUNCTION CheckCloneCRC : BOOLEAN;
                            FUNCTION CheckDropDead(DTR1 : DateTimeRec) : DateStatT;
                            FUNCTION UpdateCloneData(Mode : ReplyStatT) : BOOLEAN;
                            FUNCTION Rand32 : LONGINT;
                            FUNCTION StampCloneData : BOOLEAN;
                        END;

    {===========================================================}

IMPLEMENTATION

USES
    ApMisc,
    Colors,
    KERROR,
    OpAbsFld,
    OpClone,
    OpCmd,
    OpColor,
    OpCrt,
    OpField,
    OpFrame,
    OpInline,
    OpRoot,
    OpSelect,
    OpString,
    OpWindow,
    SECONST,
    UTTIMDAT;

    {Entry field constants}
CONST
    idFullName     = 0;
    idChallenge    = idFullName + 1;
    idTDDate       = idChallenge + 1;
    idIDDate       = idTDDate + 1;
    idReply        = idIDDate + 1;

    {Stop working on this date}
    SW1n           = 6163;
    SW1p           = 133;
    SW1s           = '≤∂S@©¥È_É ﬁÛQ'#123'HË’h·'#41'ƒzMu';

    {Stop working on this IDK date}
    SESTR16N       = 46128;
    SESTR16P       = 212;
    SESTR16S       = '˙Z©˝åºﬁÇΩÈ÷3fÚiíÌ'#41'Ü∑î ∂eW7»©';

    {Access failure.  Contact support!}
    SESTR13N       = 19784;
    SESTR13P       = 146;
    SESTR13S       = '¿M8/D¯'#123'zó≠É±Ù∂'#125'Üé•J¸5∞eCƒPbh';

    {$IFDEF IDK}
    {IDK, Inc.}
    SESTR15N = 27760;
    SESTR15P = 234;
    SESTR15S = '∏m– gáx';
    {$ELSE}
    {The Design Group}
    SESTR15N       = 21315;
    SESTR15P       = 234;
    SESTR15S       = 'bËKÍÕå<’√¡'#41'â9';
    {$ENDIF}

    {Enter number supplied by Support}
    SESTR18N       = 23806;
    SESTR18P       = 225;
    SESTR18S       = '£ëÙ<∆Œb¯¥!Ï∏”Ôb˚*9´“GoŸ¨‰…/üá';

    {Help index constants}
CONST
    hiFullName     = 1;
    hiChallenge    = hiFullName + 1;
    hiDDate        = hiChallenge + 1;
    hiReply        = hiDDate + 1;

    SEPT_1_95      = 144514;

    (***************************)

    {Function very similar to the one above, with the exception that untyped}
    {constants can be used for the input string, avoiding the use of dgroup }
    FUNCTION RevenueChallengeT.DecodeStrg(S : STRING; PubKey, PrivKey : WORD) : STRING;
    VAR
        Strg           : STRING;
        I              : BYTE;
        ORS            : LONGINT;
    BEGIN
        ORS := RANDSEED;
        RANDSEED := PubKey;
        Strg[0] := S[0];
        FOR I := 1 TO LENGTH(S) DO
            Strg[I] := CHAR(ORD(S[I]) XOR RANDOM($FF) XOR PrivKey);
        DecodeStrg := Strg;
        RANDSEED := ORS;
    END;

    {--------------}
    {crc -tddd-IDDD-reply   }
    {KKKK-KKKK-KKKK-KKKKKKKK}

CONST
    SESTR11N       = 61338;
    SESTR11P       = 165;
    SESTR11S       = #41'”'#41'UKsJ†`gÕ>1bó…ÛBÍôY6';

    {Drop Dead :}

CONST
    SESTR12N       = 57574;
    SESTR12P       = 222;
    SESTR12S       = '0ÒÒV±âåaçˇ';

    {Stamp Executable}

CONST
    SESTR17N       = 14731;
    SESTR17P       = 198;
    SESTR17S       = '‘R_…¥Õïè%TïdÑße·';

    {-----------------}

    FUNCTION RevenueChallengeT.InitES : BOOLEAN;
    CONST
        Frame1         = '…»ªºÕÕ∫∫';
        WinOptions     = wBordered + wClear + wUserContents;
    BEGIN
        InitES := FALSE;
        CASE ModeFlg OF
            ESUPPORT :
                BEGIN
                    TDDead := Today + 30;
                    IDDead := TDDead + 30;
                END;
            EStamp :
                BEGIN
                    TDDead := CloneData.TDDD.D;
                    IDDead := CloneData.IDDD.D;
                END;
        END;

        IF NOT INHERITED InitCustom(10, 12, 68, 14, EsColors, WinOptions) THEN
            EXIT;

        REPLY := '';
        Challenge := 0;
        FullName := '';

        wFrame.SetFrameType(Frame1);
        EnableExplosions(6);
        wFrame.AddShadow(shBR, shSeeThru);

        CASE ModeFlg OF
            ESUPPORT :
                BEGIN
                    {Refresh Key}
                    wFrame.AddHeader(DecodeStrg(SECON35S, SECON35N, SECON35P), heTR);
                    {The Design Group} {IDK, Inc.}
                    wFrame.AddHeader(DecodeStrg(SESTR15S, SESTR15N, SESTR15P), heTL);
                END;
            EStamp :
                BEGIN
                    {Stamp Executable}
                    wFrame.AddHeader(DecodeStrg(SESTR17S, SESTR17N, SESTR17P), heTR);
                    {The Design Group} {IDK, Inc.}
                    wFrame.AddHeader(DecodeStrg(SESTR15S, SESTR15N, SESTR15P), heTL);
                END;
            EUSER :
                BEGIN
                    {Call customer support!}
                    wFrame.AddHeader(DecodeStrg(SECON38S, SECON38N, SECON38P), heTR);
                    {The Design Group} {IDK, Inc.}
                    wFrame.AddHeader(DecodeStrg(SESTR15S, SESTR15N, SESTR15P), heTL);
                END;
        END;

        wFrame.AddHeader(' ', heBC);

        SetWrapMode(ExitAtBot);

        IF ModeFlg = EStamp THEN
            esFieldOptionsOn(efHidden);

        {idFullName:}
        esFieldOptionsOn(efClearFirstChar + efRequired);
        AddStringField(
            DecodeStrg(SECON32S, SECON32N, SECON32P), 1, 1,
            CharStr('!', MaxFullName), 1, 13, MaxFullName,
            hiFullName, FullName);
        esFieldOptionsOff(efClearFirstChar + efRequired);

        {idChallenge:}
        CASE ModeFlg OF
            ESUPPORT,
            EStamp :
                esFieldOptionsOn(efClearFirstChar);
            EUSER :
                esFieldOptionsOn(efProtected + efClearFirstChar);
        END;

        AddLongField(
            DecodeStrg(SECON33S, SECON33N, SECON33P), 2, 1,
            DecodeStrg(SECON36S, SECON36N, SECON36P), 2, 13,
            hiChallenge, $80000000, $7FFFFFFF, Challenge);

        esFieldOptionsOff(efHidden + efProtected + efClearFirstChar);


        {idDDate}
        CASE ModeFlg OF
            ESUPPORT,
            EStamp :
                esFieldOptionsOff(efHidden);
            EUSER :
                esFieldOptionsOn(efHidden);
        END;


        {support/stamp}
        AddDateField(
            {          Drop dead : }
            DecodeStrg(SESTR12S, SESTR12N, SESTR12P), 2, 37,
            'mm/dd/yyyy', 2, 49,
            hiDDate, Today, MinDate, TDDead);

        CASE ModeFlg OF
            EStamp :
                esFieldOptionsOff(efHidden);
            {$IFDEF IDK}
            ESUPPORT :
                esFieldOptionsOff(efHidden);
            EUSER :
                esFieldOptionsOn(efHidden);
            {$ELSE}
            ESUPPORT,
            EUSER :
                esFieldOptionsOn(efHidden);
            {$ENDIF}
        END;

        {stamp only}
        AddDateField(
            {          Drop dead : }
            DecodeStrg(SESTR12S, SESTR12N, SESTR12P), 3, 37,
            'mm/dd/yyyy', 3, 49,
            hiDDate, Today, MinDate, IDDead);
        esFieldOptionsOff(efHidden);

        {idReply:}
        CASE ModeFlg OF
            ESUPPORT :
                BEGIN
                    esFieldOptionsOn(efProtected + efClearFirstChar);
                    AddStringField(
                        {Reply     :}
                        DecodeStrg(SECON34S, SECON34N, SECON34P), 3, 1,
                        {crc -tddd-IDDD-reply   }
                        {KKKK-KKKK-KKKK-KKKKKKKK}
                        DecodeStrg(SESTR11S, SESTR11N, SESTR11P), 3, 13, 23,
                        hiReply, REPLY);
                END;
            EStamp : ;
            EUSER :
                BEGIN
                    esFieldOptionsOn(efClearFirstChar);
                    AddStringField(
                        {Reply     :}
                        DecodeStrg(SECON34S, SECON34N, SECON34P), 3, 1,
                        {crc -tddd-IDDD-reply   }
                        {KKKK-KKKK-KKKK-KKKKKKKK}
                        DecodeStrg(SESTR11S, SESTR11N, SESTR11P), 3, 13, 23,
                        hiReply, REPLY);
                END;
        END;

        esFieldOptionsOff(efProtected + efClearFirstChar);

        InitStatus := RawError;
        InitES := InitStatus = 0;

    END;

    (***************************)

    {init the entry screen for customer use}
    CONSTRUCTOR RevenueChallengeT.Init;
    BEGIN
        ModeFlg := EUSER;
        OkToRunFlag := TRUE;

        IF NOT InitES THEN
            FAIL;
    END;

    (***************************)

    {init the entry screen for support use}
    CONSTRUCTOR RevenueChallengeT.InitDeluxe;
    BEGIN
        ModeFlg := ESUPPORT;
        IF NOT InitES THEN
            FAIL;
    END;

    (***************************)

    CONSTRUCTOR RevenueChallengeT.InitStamp(ExeName : PathStr);
    VAR
        C              : Cloner;
    BEGIN
        IF NOT C.InitCustom(ExeName, UpdateNone, $7FFF) THEN BEGIN
            DispErrorDeluxe('Cloner Init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        IF NOT C.FindDefaultsEnd(CloneID, SIZEOF(CloneID), 0) THEN BEGIN
            DispErrorDeluxe('Cloner failed to find defaults', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        C.LoadDefaults(C.GetPos, CloneID, SIZEOF(CloneRec) + SIZEOF(CloneID));

        InitStatus := C.GetLastError;

        IF InitStatus <> 0 THEN BEGIN
            DispErrorDeluxe('Cloner failed to store defaults', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        C.Done;

        ModeFlg := EStamp;
        IF NOT InitES THEN BEGIN
            DispErrorDeluxe('Stamper ES init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;
    END;

    (***************************)

    {display appropriate help msg}
    PROCEDURE RevenueChallengeT.esPreEdit;
    VAR
        S              : STRING;
    BEGIN
        S := '';
        CASE ModeFlg OF
            ESUPPORT,
            EStamp :
                BEGIN
                    CASE GetCurrentID OF
                        idFullName :
                            {Enter the users EXACT name}
                            S := DecodeStrg(SECON49S, SECON49N, SECON49P);
                        idChallenge :
                            {Enter users challenge password}
                            S := DecodeStrg(SECON50S, SECON50N, SECON50P);
                        idReply :
                            {Tell the user the new Hex reply and have him type it in}
                            S := DecodeStrg(SECON48S, SECON48N, SECON48P);
                        idTDDate :
                            {Stop working on this date}
                            S := DecodeStrg(SW1s, SW1n, SW1p);
                        idIDDate :
                            {Stop working on this IDK date}
                            S := DecodeStrg(SESTR16S, SESTR16N, SESTR16P);
                    END;
                END
            ELSE BEGIN
                CASE GetCurrentID OF
                    idFullName :
                        {Enter your name}
                        S := DecodeStrg(SECON37S, SECON37N, SECON37P);
                    idChallenge :
                        {Enter user challenge}
                        S := DecodeStrg(SECON39S, SECON39N, SECON39P);
                    idReply :
                        {Enter number supplied by Support}
                        S := DecodeStrg(SESTR18S, SESTR18N, SESTR18P);
                    idTDDate,
                    idIDDate : ;
                END;
            END;
        END;

        ChangeHeader(2, ' ' + S + ' ');
    END;

    (***************************)

    {calc ES field values for both modes}
    PROCEDURE RevenueChallengeT.esPostEdit;
    VAR
        EFP            : EntryFieldPtr;
        FID            : WORD;
        T              : LONGINT;
        S              : STRING;
    BEGIN
        FID := GetCurrentID;
        CASE ModeFlg OF
            ESUPPORT :
                BEGIN
                    {$IFDEF IDK}
                    REPLY := CalcReply(EIDKValid);
                    {$ELSE}
                    REPLY := CalcReply(ETDGValid);
                    {$ENDIF}
                    DrawField(idReply);
                END;
            EStamp,
            EUSER : ;

        END;
        CASE FID OF
            idFullName :
                BEGIN
                    CASE ModeFlg OF
                        EUSER :
                            BEGIN
                                CreateChallenge;
                                DrawField(idChallenge);
                            END;
                        ESUPPORT :
                            DrawField(idReply);
                    END;
                END;
            idTDDate,
            idIDDate,
            idChallenge : ;
            idReply : ;
        END;
    END;


    (***************************)

    FUNCTION RevenueChallengeT.Rand32 : LONGINT;
    VAR
        T              : LONGINT;
    BEGIN
        RANDOMIZE;
        T := RANDOM($FFFF);
        T := (T SHL 16) + RANDOM($FFFF);
        Rand32 := T;
    END;

    (***************************)

    {create a 32bit random number and stuff it into ES field}
    PROCEDURE RevenueChallengeT.CreateChallenge;
    BEGIN
        Challenge := Rand32;
    END;

    (***************************)

    {compare customer reply with calculated reply}
    FUNCTION RevenueChallengeT.CheckReply : ReplyStatT;
    VAR
        Strg           : STRING;
        Crc            : LONGINT;
    BEGIN
        CheckReply := EInvalid;

        IF REPLY = '' THEN
            EXIT;

        {get the TDDead date}
        IF NOT Str2Long('$' + COPY(REPLY, 6, 4), TDDead) THEN
            EXIT;

        TDDead := LoWord(Challenge XOR TDDead) + SEPT_1_95;

        {get the IDDead date}
        IF NOT Str2Long('$' + COPY(REPLY, 11, 4), IDDead) THEN
            EXIT;

        IDDead := LoWord(Challenge XOR IDDead) + SEPT_1_95;

        {calc checksum of user reply}
        Strg := COPY(HexL(CalcStringCRC(COPY(REPLY, 6, $FF)) AND $FFFF), 5, 4);

        {compare checksum with typed in checksum}
        IF POS(Strg, REPLY) <> 1 THEN {checksum fail}
            EXIT;

        {12345678901234567890123}
        {crc -tddd-IDDD-reply   }
        {KKKK-KKKK-KKKK-KKKKKKKK}

        {are we in IDK mode?}
        IF POS(CalcReply(EIDKValid), REPLY) = 16 THEN BEGIN
            CheckReply := EIDKValid;
            OkToRunFlag := TRUE;
        END                       {are we in TDG mode?}
        ELSE IF POS(CalcReply(ETDGValid), REPLY) = 16 THEN BEGIN
            OkToRunFlag := TRUE;
            IDDead := CloneData.IDDD.D;
            CheckReply := ETDGValid;
        END
        ELSE BEGIN                {must be invalid Reply}
            CheckReply := EInvalid;
            OkToRunFlag := FALSE;
        END;
    END;

    (***************************)

    FUNCTION RevenueChallengeT.CalcStringCRC(Strg : STRING) : LONGINT;
    VAR
        T              : LONGINT;
        I              : BYTE;
    BEGIN
        T := 0;
        FOR I := 1 TO LENGTH(Strg) DO
            T := UpdateCrc32(ORD(Strg[I]), T);
        CalcStringCRC := T;
    END;

    (***************************)

    {calc a 32bit crc of customer name}
    FUNCTION RevenueChallengeT.CalcNameCRC : LONGINT;
    BEGIN
        CalcNameCRC := CalcStringCRC(FullName);
    END;

    (***************************)

    {calculate 32bit reply from name crc and current challenge}
    FUNCTION RevenueChallengeT.CalcReply(Mode : ReplyStatT) : STRING;
    VAR
        Crc,
        TDate,
        TReply         : LONGINT;
        DD,
        I              : WORD;
        S,
        Strg           : STRING;
    BEGIN
        {crc -tddd-IDDD-reply   }
        {KKKK-KKKK-KKKK-KKKKKKKK}

        CASE Mode OF
            ETDGValid :
                TReply := CalcNameCRC XOR Challenge;
            EIDKValid :
                TReply := CalcNameCRC XOR Challenge XOR 4921533;
        END;

        CASE ModeFlg OF
            ESUPPORT,
            EStamp :
                BEGIN
                    {calc TDDead string}
                    DD := LoWord(Challenge XOR (TDDead - SEPT_1_95));
                    S := hexw(DD) + '-';

                    {calc IDDead string}
                    DD := LoWord(Challenge XOR (IDDead - SEPT_1_95));
                    {prepend the IDDead and append the Reply}
                    S := S + hexw(DD) + '-' + HexL(TReply);

                    {calculate and prepend the CRC string}
                    Crc := CalcStringCRC(S);
                    Strg := COPY(HexL(Crc), 5, 4) + '-' + S;
                END;
            ELSE
                Strg := HexL(TReply);
        END;
        CalcReply := Strg;
    END;

    (***************************)

    FUNCTION RevenueChallengeT.CalcCRC(T : LONGINT; VAR D; DSize : BYTE) : LONGINT;
    VAR
        B              : BYTE;
        I              : BYTE;
        DArray         : ARRAY[1..$FF] OF BYTE ABSOLUTE D;
    BEGIN
        FOR I := 1 TO DSize DO
            T := UpdateCrc32(DArray[I], T);
        CalcCRC := T;
    END;

    (***************************)

    FUNCTION RevenueChallengeT.CalcCloneCRC : LONGINT;
    VAR
        T              : LONGINT;
    BEGIN
        T := 0;
        WITH CloneData DO BEGIN
            T := CalcCRC(T, R1L, SIZEOF(R1L));
            T := CalcCRC(T, TDDD, SIZEOF(TDDD));
            T := CalcCRC(T, R2L, SIZEOF(R2L));
            T := CalcCRC(T, R3L, SIZEOF(R3L));
            T := CalcCRC(T, IDDD, SIZEOF(IDDD));
            T := CalcCRC(T, R4B, SIZEOF(R4B));
            T := CalcCRC(T, LU, SIZEOF(LU));
            T := CalcCRC(T, R5L, SIZEOF(R5L));
        END;
        CalcCloneCRC := T;
    END;

    (***************************)

    FUNCTION RevenueChallengeT.CheckCloneCRC : BOOLEAN;
    BEGIN
        CheckCloneCRC := CalcCloneCRC = CloneData.CS;
    END;

    (***************************)

    FUNCTION RevenueChallengeT.CheckDropDead(DTR1 : DateTimeRec) : DateStatT;
    VAR
        DTR2           : DateTimeRec;
        T              : LONGINT;
    BEGIN
        DTRNow(DTR2);

        {check if dropdead is before now}
        T := DateTimeDiffSecsSigned(DTR1, DTR2);

        IF T > 0 THEN
            CheckDropDead := DATEFAIL
        ELSE IF T > (SecondsInDay * - 3) THEN
            CheckDropDead := DATEWARN
        ELSE
            CheckDropDead := DateOk;
    END;

    (***************************)

    FUNCTION RevenueChallengeT.UpdateCloneData(Mode : ReplyStatT) : BOOLEAN;
    VAR
        C              : Cloner;
    BEGIN
        UpdateCloneData := FALSE;
        RANDOMIZE;
        WITH CloneData DO BEGIN
            R5L := Rand32;
            R1L := Rand32;
            R3L := Rand32;
            R2L := Rand32;
            R4B := RANDOM($FF);
            DTRNow(LU);

            CASE Mode OF
                EIDKValid :
                    BEGIN
                        IDDD.D := IDDead;
                        TDDD.D := TDDead;
                    END;
                ETDGValid :
                    TDDD.D := TDDead;
                EInvalid : ;
            END;

            IDDD.T := Rand32 MOD SecondsInDay;
            TDDD.T := Rand32 MOD SecondsInDay;

            CS := CalcCloneCRC;
        END;

        IF NOT C.InitCustom(PARAMSTR(0), UpdateNone, $7FFF) THEN
            EXIT;

        IF NOT C.FindDefaultsEnd(CloneID, SIZEOF(CloneID), 0) THEN
            EXIT;

        C.StoreDefaults(C.GetPos, CloneID, SIZEOF(CloneRec) + SIZEOF(CloneID));

        IF C.GetLastError = 0 THEN
            UpdateCloneData := TRUE;
        C.Done;
    END;

    (***************************)

    FUNCTION RevenueChallengeT.StampCloneData : BOOLEAN;
    VAR
        C              : Cloner;
    BEGIN
        StampCloneData := FALSE;
        RANDOMIZE;
        WITH CloneData DO BEGIN
            R5L := Rand32;
            R1L := Rand32;
            R3L := Rand32;
            R2L := Rand32;
            R4B := RANDOM($FF);
            DTRNow(LU);

            IDDD.D := IDDead;
            TDDD.D := TDDead;

            IDDD.T := Rand32 MOD SecondsInDay;
            TDDD.T := Rand32 MOD SecondsInDay;

            CS := CalcCloneCRC;
        END;

        IF NOT C.InitCustom(PARAMSTR(1), UpdateNone, $7FFF) THEN
            EXIT;

        IF NOT C.FindDefaultsEnd(CloneID, SIZEOF(CloneID), 0) THEN
            EXIT;

        C.StoreDefaults(C.GetPos, CloneID, SIZEOF(CloneRec) + SIZEOF(CloneID));

        IF C.GetLastError = 0 THEN
            StampCloneData := TRUE;

        C.Done;
    END;

    (***************************)


    FUNCTION RevenueChallengeT.OkToRun : BOOLEAN;
    BEGIN
        OkToRun := OkToRunFlag;
        IF NOT OkToRunFlag THEN
            {Access failure.  Contact support!}
            DispErrorDeluxe(DecodeStrg(SESTR13S, SESTR13N, SESTR13P), '', TRUE, NIL);
    END;

    (***************************)

    PROCEDURE RevenueChallengeT.ProcessSelf;
    VAR
        DTR1,
        DTR2           : DateTimeRec;
        T,
        R,
        X,
        DeltaT         : LONGINT;
        Flag           : BOOLEAN;
    BEGIN
        Flag := FALSE;

        CASE ModeFlg OF
            EUSER :
                BEGIN
                    {check internal data integrity}
                    IF NOT CheckCloneCRC THEN BEGIN
                        {Call customer support!}
                        DispErrorDeluxe(DecodeStrg(SECON38S, SECON38N, SECON38P), '', TRUE, NIL);
                        HALT(1);
                    END;

                    {rtc tamper check}
                    DTRNow(DTR1);
                    DeltaT := DateTimeDiffSecsSigned(CloneData.LU, DTR1);

                    {backwards more than 2 days = bomb}
                    IF (DeltaT / SecondsInDay < - 2) THEN BEGIN
                        InitStatus := epFatal + ecOutOfRange;
                        {Access Failure}
                        DispErrorDeluxe(DecodeStrg(SECON30S, SECON30N, SECON30P), '', TRUE, NIL);
                        HALT(1);
                    END;


                    {dropdead check}

                    {read RTC}
                    DTRNow(DTR2);

                    {check if dropdead is before now}
                    IF CheckDropDead(CloneData.TDDD) = DATEFAIL THEN
                        Flag := TRUE;

                    IF CheckDropDead(CloneData.IDDD) = DATEFAIL THEN
                        Flag := TRUE;
                END;
        END;

        IF (Flag OR (ModeFlg <> EUSER)) THEN BEGIN
            REPEAT
                INHERITED ProcessSelf;
                CASE GetLastCommand OF
                    ccQuit :
                        BEGIN
                            DispErrorDeluxe('Operator abort', '', FALSE, Iam);
                            OkToRunFlag := FALSE;
                            EXIT;
                        END;
                    ccError :
                        BEGIN
                            DispErrorDeluxe('ES error', ErrorMessage(InitStatus), TRUE, Iam);
                            EXIT;
                        END;
                    ELSE
                        BREAK;
                END;              {case}
            UNTIL FALSE;
        END;

        IF ModeFlg = EStamp THEN
            StampCloneData
        ELSE BEGIN
            UpdateCloneData(CheckReply);

            {check if dropdead is still before now}
            IF CheckDropDead(CloneData.TDDD) = DATEFAIL THEN
                OkToRunFlag := FALSE;

            IF CheckDropDead(CloneData.IDDD) = DATEFAIL THEN
                OkToRunFlag := FALSE;
        END;
    END;

    (***************************)

END.

    (***************************)
    (***************************)
