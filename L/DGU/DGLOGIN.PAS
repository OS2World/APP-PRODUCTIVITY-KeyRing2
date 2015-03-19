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
* Operator ID entry screen.  ID is used to generate unique number for company
* and employee records.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
UNIT DGLOGIN;
    {$I OPDEFINE.INC}
    {$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
INTERFACE
USES
    DGCMD,
    OpCRT,
    OpEntry,
    OpString;

TYPE
    PLogin         = ^TLogin;
    TLogin         = OBJECT(EntryScreen)
                         CONSTRUCTOR Init(VAR First, LAST : STRING);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE ProcessSelf; VIRTUAL;
                         PROCEDURE InitUserRecord;

                     PRIVATE

                         MyFirst,
                         MyLast         : StringPtr;
                         LocalCP        : TDGUCommandProcessor;
                     END;

IMPLEMENTATION

    {===========================================================}

USES
    Colors,
    Dos,
    MSGMGR,
    OpInline,
    OpRoot,
    OpCol16,
    {$IFDEF UseMouse}
    OpMouse,
    {$ENDIF}
    OpAbsFld,
    OpCmd,
    OpField,
    OpFrame,
    OpWindow,
    OpSelect;

    {Entry field constants}
CONST
    idFirstName    = 0;
    idLastName     = idFirstName + 1;

    {Help index constants}
CONST
    hiFirstName    = 1;
    hiLastName     = hiFirstName + 1;

    {-----------}

    PROCEDURE TLogin.InitUserRecord;
    BEGIN
        MyFirst^ := '';
        MyLast^ := '';
    END;

    {-----------}

    CONSTRUCTOR TLogin.Init(VAR First, LAST : STRING);
    CONST
        Frame1         = '…»ªºÕÕ∫∫';
        WinOptions     = wBordered + wClear + wUserContents;
    BEGIN
        MyFirst := @First;
        MyLast := @LAST;

        IF NOT InitCustom(23, 12, 56, 13, EsColors, WinOptions) THEN
            FAIL;

        IF NOT LocalCP.Init(@EntryKeySet, EntryKeyMax) THEN
            FAIL;

        wFrame.SetFrameType(Frame1);
        EnableExplosions(6);
        {$IFDEF USESHADOWS}
        wFrame.AddShadow(shBR, shSeeThru);
        {$ENDIF}
        wFrame.AddHeader(' Please Log In ', heTC);
        SetWrapMode(ExitAtBot);

        {idFirstName:}
        esFieldOptionsOn(efClearFirstChar + efBeepOnError + efRequired);
        AddStringField(
            'First Name :', 1, 1,
            CharStr('X', 20), 1, 14, 20,
            hiFirstName, MyFirst^);
        esFieldOptionsOff(efClearFirstChar + efBeepOnError + efRequired);

        {idLastName:}
        esFieldOptionsOn(efClearFirstChar + efRequired);
        AddStringField(
            'Last Name  :', 2, 1,
            CharStr('X', 20), 2, 14, 20,
            hiLastName, MyLast^);
        esFieldOptionsOff(efClearFirstChar + efRequired);

        InitStatus := RawError;
        IF InitStatus <> 0 THEN
            FAIL;
    END;

    {-----------}

    DESTRUCTOR TLogin.Done;
    BEGIN
        LocalCP.Done;
        INHERITED Done;
    END;

    {-----------}

    PROCEDURE TLogin.ProcessSelf;
    BEGIN
        REPEAT
            INHERITED ProcessSelf;
        UNTIL (MyFirst^ <> '') AND (MyLast^ <> '');
    END;

    {-----------}

END.
    {-----------}
    {-----------}
