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
{$I OPDEFINE.INC}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT DGHELP;
INTERFACE
USES
    DGCMD,
    Dos,
    OpHelp
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

TYPE
    PDGScrollingHelpWindow = ^TPDGScrollingHelpWindow;
    TPDGScrollingHelpWindow = OBJECT(ScrollingHelpWindow)
                                  LocalCP        : TDGUCommandProcessor;
                                  CONSTRUCTOR Init(Name : STRING; Pu, PD, Pud, Tit, Ind, Keyhlp : LONGINT);
                                  DESTRUCTOR Done; VIRTUAL;
                              END;

FUNCTION HelpInit(Name : PathStr; PageUp, PageDown, PageUpDown, Title, Index, Keyhelp : LONGINT) : BOOLEAN;

PROCEDURE DisplayHelp(UnitCode : BYTE; IdPtr : POINTER; HelpIndex : WORD); FAR;

PROCEDURE ChangeHelpFile(Name : PathStr);
PROCEDURE DisposeHelp;

VAR
    SHP            : PDGScrollingHelpWindow;

IMPLEMENTATION

USES
    Colors,
    KERROR,
    MSGMGR,
    OpCol16,
    OpCmd,
    OpCRT,
    OpFrame,
    {$IFDEF UseMouse}
    OpMouse,
    {$ENDIF}
    OpPick,
    OpRoot,
    OpString,
    OpWindow,
    Message,
    UTIAM;

VAR
    CurHelpName    : PathStr;
    MyPageUp,
    MyPageDown,
    MyPageUpDown,
    MyTitle,
    MyIndex,
    MyKeyhelp      : LONGINT;

    {-----------------}

    CONSTRUCTOR TPDGScrollingHelpWindow.Init(Name : STRING; Pu, PD, Pud, Tit, Ind, Keyhlp : LONGINT);
    VAR
        Strg           : STRING;
    BEGIN
        IF NOT LocalCP.Init(@HelpKeySet, HelpKeyMax) THEN
            FAIL;

        CurHelpName := ForceExtension(Name, 'HLP');
        {set up help window}
        IF NOT InitDeluxe(2, 8, 78, ScreenHeight - 3,
                          HelpColors,
                          DefWindowOptions OR wBordered,
                          CurHelpName,
                          PickVertical,
                          hwStaticNameBuffer + hwPickIndex + hwHighlightXref) THEN BEGIN
            DispErrorDeluxe('Unable to initialize help window: ', CurHelpName + ': ' + ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;


        SetCommandProcessor(LocalCP);
        AddMoreHelpHeader(ScnMsgP^.SysMsg(Pud) { PgUp/PgDn for more } , heBR, ScnMsgP^.SysMsg(Pu) {PgUp} ,
                          ScnMsgP^.SysMsg(PD) {PgDn} , '/', 2, 7, 6);
        Strg := ' PrgVer : ' + ProgramRevision;
        hwFrame.AddHeader(Strg, heTR);
        {$IFDEF USESHADOWS}
        wFrame.AddShadow(shBR, shSeeThru);
        {$ENDIF}
        AddTopicHeader(1, 60, heTC);
        wFrame.AddHeader(ScnMsgP^.SysMsg(Ind) { Help Topics Index } , heTC);
        wFrame.AddScrollBar(frRR, 0, MAXLONGINT, DefaultColorSet);
        hwFrame.AddScrollBar(frRR, 0, MAXLONGINT, DefaultColorSet);
        {$IFDEF USESHADOWS}
        hwFrame.AddShadow(shBR, shSeeThru);
        {$ENDIF}
        hwFrame.AddHeader(ScnMsgP^.SysMsg(Tit) { Help: } , heTL);
        hwFrame.AddHeader(ScnMsgP^.SysMsg(Keyhlp) { Press F1 for Help Index; Alt-F1 for Previous Topic } , heBL);
        EnableExplosions(6);
        {$IFDEF UseMouse}
        IF MouseInstalled THEN BEGIN
            WITH HelpColors DO
                SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) SHL 8) +
                                BYTE(MouseChar));
            HelpCommands.cpOptionsOn(cpEnableMouse);
            hwFrame.AddHotspot(frTL, #4, HelpColors);
            SetPrevTopicHotSpot(hsSpot, frTL);
        END;
        {$ENDIF}
    END;

    {-----------------}

    DESTRUCTOR TPDGScrollingHelpWindow.Done;
    BEGIN
        LocalCP.Done;
        INHERITED Done;
    END;

    {-----------------}

    PROCEDURE ChangeHelpFile(Name : PathStr);
    BEGIN
        CurHelpName := ForceExtension(Name, 'HLP');
    END;

    {-----------------}

    {-Display context sensitive help}
    PROCEDURE DisplayHelp(UnitCode : BYTE; IdPtr : POINTER; HelpIndex : WORD);
    BEGIN
        IF SHP = NIL THEN BEGIN
            HelpInit(CurHelpName, MyPageUp, MyPageDown, MyPageUpDown, MyTitle, MyIndex, MyKeyhelp);
            IF SHP = NIL THEN BEGIN
                DispErrorDeluxe('Problem starting help engine: ' +
                                CurHelpName,
                                ErrorMessage(InitStatus),
                                TRUE,
                                Iam);
                EXIT;
            END;
        END;
        {$IFDEF DEBUG}
        FastWrite(Pad(Long2Str(HelpIndex) + ':' + Long2Str(UnitCode), 8), ScreenHeight - 1, 1, LtRedOnBlue);
        {$ENDIF}
        SHP^.SetTopic(HelpIndex);
        SHP^.Process;
        SHP^.ERASE;
        DISPOSE(SHP, Done);
        SHP := NIL;
    END;

    {-----------------}

    FUNCTION HelpInit(Name : PathStr; PageUp, PageDown, PageUpDown, Title, Index, Keyhelp : LONGINT) : BOOLEAN;
    BEGIN
        NEW(SHP, Init(Name, PageUp, PageDown, PageUpDown, Title, Index, Keyhelp));

        MyPageUp := PageUp;
        MyPageDown := PageDown;
        MyPageUpDown := PageUpDown;
        MyTitle := Title;
        MyIndex := Index;
        MyKeyhelp := Keyhelp;

        HelpInit := SHP <> NIL;
    END;

    {-----------------}

    PROCEDURE DisposeHelp;
    BEGIN
        IF SHP <> NIL THEN
            DISPOSE(SHP, Done);
        SHP := NIL;
    END;

BEGIN
    CurHelpName := ForceExtension(PARAMSTR(0), 'HLP');
    SHP := NIL;
END.

    {-----------------}
    {-----------------}
