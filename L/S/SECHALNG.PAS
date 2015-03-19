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

UNIT SECHALNG;

INTERFACE

    {$I OPDEFINE.INC}
    {$A+,B-,D+,E+,F+,G+,I+,L+,N-,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

USES
    OpEntry,
    SEQUERY;
TYPE

    RefreshKeyP    = ^RefreshKeyT;
    RefreshKeyT    = OBJECT(EntryScreen)
                         {for user entry}
                         CONSTRUCTOR Init;
                         {constructor for support program only!}
                         CONSTRUCTOR InitDeluxe;
                             {verify user challenge/reply.  TRUE if ok, FALSE}
                             {if not verified                                }
                         FUNCTION CheckReply : BOOLEAN;

                     PRIVATE

                         FullName       : STRING[25];
                         Challenge      : LONGINT;
                         REPLY          : LONGINT;
                         DeluxeFlg      : BOOLEAN;

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
                         FUNCTION CalcReply : LONGINT;

                     END;

    {===========================================================}

IMPLEMENTATION

USES
    ApMisc,
    Dos,
    OpAbsFld,
    OpCmd,
    OpColor,
    OpCrt,
    OpDate,
    OpField,
    OpFrame,
    OpInline,
    OpRoot,
    OpSelect,
    OpString,
    OpWindow,
    SECONST,
    SECRPTLO,
    UColors;

    {Entry field constants}
CONST
    idFullName     = 0;
    idChallenge    = idFullName + 1;
    idReply        = idChallenge + 1;

    {Help index constants}
CONST
    hiFullName     = 1;
    hiChallenge    = hiFullName + 1;
    hiReply        = hiChallenge + 1;

    (***************************)

    FUNCTION RefreshKeyT.InitES : BOOLEAN;
    CONST
        Frame1         = '…»ªºÕÕ∫∫';
        WinOptions     = wBordered + wClear + wUserContents;
    VAR
        EsColors       : ColorSet;
    BEGIN
        InitES := FALSE;

        GetCScheme(Gray_Scheme, EsColors);
        IF NOT INHERITED InitCustom(22, 12, 58, 14, EsColors, WinOptions) THEN
            EXIT;

        REPLY := 0;
        Challenge := 0;
        FullName := '';

        wFrame.SetFrameType(Frame1);
        EnableExplosions(6);
        wFrame.AddShadow(shBR, shSeeThru);
        wFrame.AddHeader(DecodeStrg(SECON35S, SECON35N, SECON35P), heTC);
        wFrame.AddHeader(' ', heBC);
        SetWrapMode(ExitAtBot);

        {idFullName:}
        esFieldOptionsOn(efClearFirstChar + efRequired);
        AddStringField(
            DecodeStrg(SECON32S, SECON32N, SECON32P), 1, 1,
            CharStr('!', 25), 1, 13, 25,
            hiFullName, FullName);
        esFieldOptionsOff(efClearFirstChar + efRequired);

        {idChallenge:}
        IF DeluxeFlg THEN
            esFieldOptionsOn(efClearFirstChar)
        ELSE
            esFieldOptionsOn(efProtected + efClearFirstChar);

        AddLongField(
            DecodeStrg(SECON33S, SECON33N, SECON33P), 2, 1,
            DecodeStrg(SECON36S, SECON36N, SECON36P), 2, 13,
            hiChallenge, $80000000, $7FFFFFFF, Challenge);
        esFieldOptionsOff(efProtected + efClearFirstChar);

        {idReply:}
        IF DeluxeFlg THEN
            esFieldOptionsOn(efProtected + efClearFirstChar)
        ELSE
            esFieldOptionsOn(efClearFirstChar);

        AddLongField(
            DecodeStrg(SECON34S, SECON34N, SECON34P), 3, 1,
            DecodeStrg(SECON36S, SECON36N, SECON36P), 3, 13,
            hiReply, $80000000, $7FFFFFFF, REPLY);
        esFieldOptionsOff(efProtected + efClearFirstChar);

        InitStatus := RawError;
        InitES := InitStatus = 0;

    END;

    (***************************)

    {init the entry screen for customer use}
    CONSTRUCTOR RefreshKeyT.Init;
    BEGIN
        DeluxeFlg := FALSE;
        IF NOT InitES THEN
            FAIL;
    END;

    (***************************)

    {init the entry screen for support use}
    CONSTRUCTOR RefreshKeyT.InitDeluxe;
    BEGIN
        DeluxeFlg := TRUE;
        IF NOT InitES THEN
            FAIL;
    END;

    (***************************)

    {display appropriate help msg}
    PROCEDURE RefreshKeyT.esPreEdit;
    VAR
        S              : STRING;
    BEGIN
        S := '';
        IF DeluxeFlg THEN BEGIN
            CASE GetCurrentID OF
                idFullName :
                    S := DecodeStrg(SECON49S, SECON49N, SECON49P);
                idChallenge :
                    S := DecodeStrg(SECON50S, SECON50N, SECON50P);
                idReply :
                    S := DecodeStrg(SECON48S, SECON48N, SECON48P);
            END;
        END
        ELSE BEGIN
            CASE GetCurrentID OF
                idFullName :
                    S := DecodeStrg(SECON37S, SECON37N, SECON37P);
                idChallenge :
                    S := DecodeStrg(SECON39S, SECON39N, SECON39P);
                idReply :
                    S := DecodeStrg(SECON38S, SECON38N, SECON38P);
            END;
        END;
        ChangeHeader(1, ' ' + S + ' ');
    END;

    (***************************)

    {calc ES field values for both modes}
    PROCEDURE RefreshKeyT.esPostEdit;
    VAR
        EFP            : EntryFieldPtr;
        FID            : WORD;
        T              : LONGINT;
        S              : STRING;
    BEGIN
        FID := GetCurrentID;
        CASE FID OF
            idFullName :
                BEGIN
                    IF NOT DeluxeFlg THEN BEGIN
                        CreateChallenge;
                        DrawField(idChallenge);
                    END;
                END;
            idChallenge :
                BEGIN
                    IF DeluxeFlg THEN BEGIN
                        REPLY := CalcReply;
                        DrawField(idReply);
                    END;
                END;
            idReply : ;
        END;
    END;


    (***************************)

    {create a 32bit random number and stuff it into ES field}
    PROCEDURE RefreshKeyT.CreateChallenge;
    VAR
        T              : LONGINT;
        I              : BYTE;
    BEGIN
        RANDOMIZE;
        T := RANDOM($FFFF);
        T := (T SHL 16) + RANDOM($FFFF);
        Challenge := T;
    END;

    (***************************)

    {compare customer reply with calculated reply}
    FUNCTION RefreshKeyT.CheckReply : BOOLEAN;
    BEGIN
        {$IFNDEF DEBUG}
        CheckReply := REPLY = CalcReply;
        {$ELSE}
        CheckReply := TRUE;
        {$ENDIF}
    END;

    (***************************)

    {calc a 32bit crc of customer name}
    FUNCTION RefreshKeyT.CalcNameCRC : LONGINT;
    VAR
        T              : LONGINT;
        I              : BYTE;
    BEGIN
        T := 0;
        FOR I := 1 TO LENGTH(FullName) DO
            T := UpdateCRC32(ORD(FullName[I]), T);
        CalcNameCRC := T;
    END;

    (***************************)

    {calculate 32bit reply from name crc and current challenge}
    FUNCTION RefreshKeyT.CalcReply : LONGINT;
    BEGIN
        CalcReply := CalcNameCRC XOR Challenge;
    END;

    (***************************)

END.

    (***************************)
    (***************************)
