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
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
UNIT UHELP;
    {$O+}
{$I OPDEFINE.INC}
{.F+}
{$V-,X+}
{$D+,L+}

    (****************************************************************************)

INTERFACE

CONST
    DIALOGOFFSET   = 200;
    PICKOFFSET     = 300;
    MENUOFFSET     = 400;
    EDITOFFSET     = 500;
    DIROFFSET      = 600;
    SELECTOFFSET   = 800;
    MEMOOFFSET     = 900;
    EDITOROFFSET   = 1000;
    BrowseOFFSET   = 1100;
    MacEdOFFSET    = 1200;
    SEditOFFSET    = 1300;
    CalcOFFSET     = 1400;
    CalOFFSET      = 1500;
    GRAPHOFFSET    = 9000;

    HELPSUFFIX     = 'HLP';
PROCEDURE KHelpProc(UnitCode : BYTE; IdPtr : POINTER; HelpIndex : WORD);

    (****************************************************************************)

IMPLEMENTATION


USES
    UColors,
    UERROR,
    {ShowPCX,}
    OpCrt,
    OpCol16,
    OpRoot,
    OpConst,
    OpHelp,
    OpString,
    OpWindow,
    OpFrame,
    OpPick,
    OpMouse,
    QGlobal,
    UKey;


    PROCEDURE DispError(Strg1, Strg2 : STRING);
        { display an error message inside a bordered window at location (XY) }
        { size the box to fit the string                                     }
    VAR
        MsgWin         : RawWindowPtr;
        Temp           : BOOLEAN;
        X,
        WinWidth,
        WinHeight      : INTEGER;
        WinOpts,
        TTime          : LONGINT;
        EsColors       : ColorSet;
    BEGIN

        GetCScheme(Red_Scheme, EsColors);

        WinOpts := wBordered + wClear + wSaveContents;
        IF LENGTH(Strg1) > LENGTH(Strg2) THEN
            WinWidth := LENGTH(Strg1)
        ELSE
            WinWidth := LENGTH(Strg2);

        X := (ScreenWidth - WinWidth) DIV 2;

        IF LENGTH(Strg2) > 0 THEN
            WinHeight := 2
        ELSE
            WinHeight := 1;

        NEW(MsgWin, InitCustom(X,
                               10,

                               X + WinWidth,
                               10 + WinHeight,

                               EsColors,
                               WinOpts));

        IF MsgWin = NIL THEN
            EXIT;

        WITH MsgWin^ DO BEGIN
            wFrame.AddHeader('ERROR', heTC);
            wFrame.AddShadow(shBR, shSeeThru);
            EnableExplosions(8);
            Draw;
            wFastText(Strg1, 1, 1);
            IF WinHeight = 2 THEN
                wFastText(Strg2, 2, 1);
        END;

        Autopsy(Strg1, Strg2);

        {Beep(TESTFAIL);}

        TTime := KTimer;
        WHILE KTimer - TTime < 300 DO
            KeyWaiting;

        MsgWin^.ERASE;
        MsgWin^.Done;
    END;

    (******************************************************************************)

    PROCEDURE ViewGraphHelp(HelpIndex : INTEGER);
    VAR
        dummy          : WORD;
        SR             : ScreenRect;
    BEGIN
        {$IFDEF ZILCH}
        IF NOT SR.Alloc(1, 1, ScreenWidth, ScreenHeight) THEN
            EXIT;

        SR.CopyFromScreen;
        ShowPicture(ForceExtension(Long2Str(HelpIndex), 'PCX'));
        Dummy := KbdReadKey;
        TextMode(LASTMODE);
        SetBlink(FALSE);
        SR.CopyToScreen;
        SR.Done;
        {$ENDIF}
    END;

    (****************************************************************************)

    FUNCTION Matches(Tname, Name : STRING; Hptr : AbstractHelpWindowPtr) : BOOLEAN; FAR;
        {-case insensitive string match routine}
    BEGIN
        Matches := POS(StUpCase(Name), StUpCase(Trim(Tname))) = 1;
    END;                          {of func Matches}

    (****************************************************************************)

    PROCEDURE KHelpProc(UnitCode : BYTE; IdPtr : POINTER; HelpIndex : WORD);
        {-Central Help handler for this entire mess}
    VAR
        SH             : ScrollingHelpWindow;
        EsColors       : ColorSet;
    BEGIN
        {$IFDEF ZILCH}
        GetCScheme(Cyan_Scheme, EsColors);

        IF NOT SH.InitDeluxe(9, 8, 73, 18,
                             EsColors,
                             DefWindowOptions OR wBordered,
                             ForceExtension(DefaultCmdLine.DefaultLanguage, HELPSUFFIX),
                             PickVertical,
                             hwStaticNameBuffer + hwPickIndex + hwBlockMark)
        THEN BEGIN
            DispError('Error initializing help window: ', 'Status: ' + Long2Str(InitStatus));
            EXIT;
        END;

        {Add some features}
        WITH SH DO BEGIN
            HelpCommands.SetGetKeyProc(KbdReadKey); {set up alternate key reader}
            HelpCommands.SetKeypressedProc(KbdKeyPressed); {to update the status line}
            EnableExplosions(8);
            AddTopicHeader(1, 60, heTC); {make this look pretty}
            wFrame.AddHeader(' Topic Index ', heTC);
            wFrame.AddScrollBar(frRR, 0, MAXLONGINT, EsColors);
            hwFrame.AddScrollBar(frRR, 0, MAXLONGINT, EsColors);
            hwFrame.AddScrollBar(frBB, 0, MAXLONGINT, EsColors);
            hwFrame.AddShadow(shBR, shSeeThru);
            SetBlockAttr($70, $70);
            {$IFDEF DEBUG}
            FastWrite(Long2Str(UnitCode) + ' ' + Long2Str(HelpIndex),
                      ScreenHeight - 1,
                      2,
                      ColorMono(BlackOnBrown, BlackOnWhite));
            {$ENDIF}
            SetTopic(FindTopic('Command Summary', Matches));

            CASE UnitCode OF
                ucNone : SetTopic(FindTopic('Command Summary', Matches));
                ucEntry : BEGIN
                              IF HelpIndex < 500 THEN
                                  SetTopic(HelpIndex)
                              ELSE BEGIN
                                  ViewGraphHelp(HelpIndex);
                                  Done; {poof!}
                                  HideMouse;
                              END;
                          END;
                ucDialog : BEGIN
                               IF HelpIndex < 500 THEN
                                   SetTopic(HelpIndex + DIALOGOFFSET)
                               ELSE BEGIN
                                   ViewGraphHelp(600);
                                   ViewGraphHelp(HelpIndex);
                                   Done; {poof!}
                                   HideMouse;
                                   EXIT;
                               END;
                           END;
                ucPick : SetTopic(HelpIndex + PICKOFFSET);
                ucEdit : SetTopic(HelpIndex + EDITOFFSET);
                ucDir : SetTopic(HelpIndex + DIROFFSET);
                ucMenu : SetTopic(HelpIndex + MENUOFFSET);
                ucSelect : SetTopic(HelpIndex + SELECTOFFSET);
                ucMemo : SetTopic(HelpIndex + MEMOOFFSET);
                ucEditor : SetTopic(HelpIndex + EDITOROFFSET);
                ucBrowse : SetTopic(HelpIndex + BrowseOFFSET);
                ucMacEd : SetTopic(HelpIndex + MacEdOFFSET);
                ucSEdit : SetTopic(HelpIndex + SEditOFFSET);
                ucCalc : SetTopic(HelpIndex + CalcOFFSET);
                ucCal : SetTopic(HelpIndex + CalOFFSET);
            END;                  {case}
            Process;              {display the sucker}
            Done;                 {poof!}
            HideMouse;
        END;                      {with SH}
        {$ENDIF}
    END;

    (****************************************************************************)

    {unit initialization}

END.                              {of unit nhelp}
(****************************************************************************)
(****************************************************************************)



