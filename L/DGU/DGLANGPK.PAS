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
*
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
UNIT DGLANGPK;

INTERFACE

    {$I OPDEFINE.INC}

    {$X+}
USES
    DEFInfo;

PROCEDURE LangSelector(VAR DFI        : TDefaultInfo;
                       MsgSel,
                       MsgSpc,
                       MsgScn,
                       MsgPrn         : WORD);

IMPLEMENTATION

USES
    Colors,
    Dos,
    OpInline,
    OpString,
    OpRoot,
    OpCRT,
    OpColor,
    {$IFDEF UseMouse}
    OpMouse,
    {$ENDIF}
    OpAbsFld,
    OpCmd,
    OpField,
    OpFrame,
    OpWindow,
    OpSelect,
    OpEntry,
    MSGMGR,
    VARDEC;

    {Entry field constants}
CONST
    idScreenLanguage = 0;
    idPrinterLanguage = idScreenLanguage + 1;

    {Help index constants}
CONST
    hiScreenLanguage = 1;
    hiPrinterLanguage = hiScreenLanguage + 1;

TYPE
    UserRecord =
        RECORD
            ScreenLanguage,
            PrinterLanguage : WORD;
        END;

    {-----------------}
VAR
    LangList       : StringArray;

    {-----------------}

    PROCEDURE BuildList;
    VAR
        SR             : SearchRec;
        F              : FILE;
    BEGIN
        IF NOT LangList.Init(10, 80) THEN
            EXIT;

        FINDFIRST(CommonFilesPath + '*.MSX', Archive, SR);
        WHILE DOSERROR = 0 DO BEGIN
            IF ValidLangFile(CommonFilesPath + SR.Name) THEN BEGIN
                IF LangList.AddString(JustName(SR.Name)) = 0 THEN
                    EXIT;
            END;
            FindNext(SR);
        END;
    END;

    {-----------------}

    PROCEDURE IncLang(VAR Value; FieldID : WORD; Factor : INTEGER; VAR St : STRING); FAR;
    VAR
        Pt             : WORD ABSOLUTE Value;
    BEGIN
        IF (Factor = 1) THEN
            IF (Pt >= LangList.NumStrings) THEN
                Pt := 1
            ELSE
                Pt := SUCC(Pt)
        ELSE IF (Factor = - 1) THEN
            IF (Pt = 1) THEN
                Pt := LangList.NumStrings
            ELSE
                Pt := PRED(Pt);

        St := LangList.GetString(Pt);
    END;

    {-------------}

    FUNCTION InitEntryScreen(VAR ES         : EntryScreen;
                             VAR UR         : UserRecord;
                             VAR EsColors   : ColorSet;
                             MsgSel,
                             MsgSpc,
                             MsgScn,
                             MsgPrn         : WORD) : WORD;
    CONST
        Frame1         = '…»ªºÕÕ∫∫';
        WinOptions     = wBordered + wClear + wUserContents;
    BEGIN
        WITH ES DO BEGIN
            IF NOT InitCustom(17, 11, 63, 14, EsColors, WinOptions) THEN BEGIN
                InitEntryScreen := InitStatus;
                EXIT;
            END;

            wFrame.SetFrameType(Frame1);
            EnableExplosions(6);
            wFrame.AddShadow(shBR, shSeeThru);
            wFrame.AddHeader(ScnMsgP^.SysMsg(MsgSel) { Select Desired Language } , heTC);
            wFrame.AddHeader(ScnMsgP^.SysMsg(MsgSpc) { Press Spacebar to Change Selection } , heBC);
            SetWrapMode(ExitAtBot);

            {idScreenLanguage:}
            AddChoiceField(
                ScnMsgP^.SysMsg(MsgScn) {Screen Language  :} , 2, 3,
                'XXXXXXXX', 2, 22,
                hiScreenLanguage,
                SIZEOF(UR.ScreenLanguage), IncLang, UR.ScreenLanguage);

            {idPrinterLanguage:}
            AddChoiceField(
                ScnMsgP^.SysMsg(MsgPrn) {Printer Language :} , 3, 3,
                'XXXXXXXX', 3, 22,
                hiPrinterLanguage,
                SIZEOF(UR.PrinterLanguage), IncLang, UR.PrinterLanguage);

            InitEntryScreen := RawError;
        END;
    END;

    {-----------------}

    PROCEDURE LangSelector(VAR DFI        : TDefaultInfo;
                           MsgSel,
                           MsgSpc,
                           MsgScn,
                           MsgPrn         : WORD);
    VAR
        ES             : EntryScreen;
        UR             : UserRecord;
        Status         : WORD;
        I              : WORD;
    BEGIN
        {$IFDEF UseMouse}
        IF MouseInstalled THEN
            WITH EsColors DO BEGIN
                {activate mouse cursor}
                SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) SHL 8) +
                                BYTE(MouseChar));
                ShowMouse;
                {enable mouse support}
                EntryCommands.cpOptionsOn(cpEnableMouse);
            END;
        {$ENDIF}

        BuildList;

        {initialize entry screen}
        Status := InitEntryScreen(ES, UR, EsColors, MsgSel,
                                  MsgSpc,
                                  MsgScn,
                                  MsgPrn);
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing entry screen: ', Status);
            HALT(1);
        END;

        FOR I := 1 TO LangList.NumStrings DO BEGIN
            IF LangList.GetString(I) = JustName(DFI.ScreenLang) THEN
                UR.ScreenLanguage := I;
            IF LangList.GetString(I) = JustName(DFI.PrintLang) THEN
                UR.PrinterLanguage := I;
        END;

        ES.Process;
        ES.ERASE;

        {$IFDEF UseMouse}
        HideMouse;
        {$ENDIF}

        DFI.ScreenLang := ForceExtension(LangList.GetString(UR.ScreenLanguage), 'MSX');
        DFI.PrintLang := ForceExtension(LangList.GetString(UR.PrinterLanguage), 'MSX');


        ES.Done;
        LangList.Done;
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}
