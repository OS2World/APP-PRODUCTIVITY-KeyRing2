{~change:Added vcs header~}
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
{$A-,F+,V-,O+}
{--------------------------------------------------------}
{ C) copyright 1988                                      }
{ UWINDOW Unit.                                          }
{ Provides a Windows and Menu operating environment      }
{ NEN version.                                           }
{--------------------------------------------------------}

UNIT UWindow;
{$I NDEFINE.INC}
INTERFACE

USES
    Dos,
    UMSg,
    OpKey,
    QGlobal,
    UGLOBAL,
    QScreen,
    QInput,
    QUpTime,
    ULib,
    UKey {,UVscreen} ,
{$IFDEF USEIPX}
    UIpxSpx,
    USpxChk,
{$ENDIF}
    UColors,
    OpCol16,
    OpInline,
    OpString,
    OpRoot,
    OpConst,
    OpCrt,
    OpMouse,
    OpCmd,
    OpDrag,
    OpCtrl,
    OpDialog,
    FDialog,
    OpDos,
    OpFrame,
    OpWindow,
    OpField,
    OpEdit,
    OpEditor,
    OpPick,
    OpDir;

PROCEDURE InitScreen(Title : TitleString; Cscheme : ColorSetProc);
PROCEDURE InitWindows;
PROCEDURE OpenWindow(X1, Y1, X2, Y2 : INTEGER;
                     Title : TitleString; Cscheme : ColorSetProc);
PROCEDURE OpenScreen(Border : WORD; Title : TitleString; Cscheme : ColorSetProc);
PROCEDURE CloseWindow;
PROCEDURE WriteWindowTitle(Title : TitleString);
PROCEDURE MoveWin(NewX, NewY : INTEGER);
PROCEDURE MoveWinRel(NewX, NewY : INTEGER);
PROCEDURE SwitchTempWindow(Screen : INTEGER);
PROCEDURE QuarterScreenWindow(Colr : INTEGER; Num : INTEGER; Title : TitleString);
PROCEDURE CentreWindow(Title : TitleString);
    {Procedure ClearBackground;}
PROCEDURE SetWindowEffects(Grow : BOOLEAN; Speed : WORD; Noise : BOOLEAN);
PROCEDURE RestoreWindowEffects;
PROCEDURE SuspendWindowEffects;
PROCEDURE SetBorderType(I : WORD);
PROCEDURE SetBorderChars(SINGLE : BOOLEAN);
PROCEDURE SetPaletteRegister(Reg : BYTE; Color : BYTE);
PROCEDURE SetColorScheme(Scheme : ColorSetProc);
FUNCTION WinX  : WORD;
FUNCTION WinY  : WORD;
PROCEDURE SetBorderColors;
PROCEDURE SetWindowColors;
PROCEDURE SetTitleColors;
PROCEDURE SetMenuColors;
PROCEDURE SetFillColors;
PROCEDURE SetCommentColors;
PROCEDURE WriteCentred(Y : INTEGER; Msg : SType);
FUNCTION Dialog(Msg : SType; Title : TitleString; TitleColor : BYTE;
                Box1 : TitleString; Box2 : TitleString;
                Box3 : TitleString) : INTEGER;
FUNCTION DialogBlink(Msg : SType; Title : TitleString; TitleColor : BYTE;
                     Box1 : TitleString; Box2 : TitleString) : INTEGER;
FUNCTION AskUser(X1, Y1         : INTEGER;
                 Msg            : SType;
                 Title          : TitleString;
                 Cscheme        : ColorSetProc;
                 TitleColor     : BYTE;
                 BoxColor       : BYTE;
                 HighlightColor : BYTE;
                 StringColor    : BYTE;
                 NumBoxes       : INTEGER;
                 VAR Boxes)     : INTEGER;
FUNCTION YesNo(Msg : SType; Title : TitleString; CSheme : ColorSetProc) : BOOLEAN;
PROCEDURE SetClockMode(T : BOOLEAN);
PROCEDURE WaitForKey(VAR EscFlag, FuncFlag : BOOLEAN);
PROCEDURE WaitForEscape;
PROCEDURE UpdateTime(Force : BOOLEAN);
PROCEDURE BuildDirectory(FMask          : BigString;
                         SuppressExt    : BOOLEAN;
                         Attrib         : WORD;
                         VAR Dir;
                         VAR Size       : INTEGER);
PROCEDURE OpenMessage(Msg : SType; Cscheme : ColorSetProc);
PROCEDURE CloseMessage;
FUNCTION UserSaysYes(Msg : SType; EscapeYes : BOOLEAN) : BOOLEAN;
FUNCTION UserYes(Msg : SType; EscapeYes : BOOLEAN) : BOOLEAN;
PROCEDURE SavePrompt;
PROCEDURE RestorePrompt;
PROCEDURE SetPromptLine(P : INTEGER);
PROCEDURE Prompt(Msg : SType);
PROCEDURE SaveAndHideCursor;
PROCEDURE RestoreCursor;
PROCEDURE SaveStatusline;
PROCEDURE RestoreStatusLine;
PROCEDURE CustomizeWindow(VAR CW         : CommandWindow;
                          Title          : STRING;
                          TWidth         : BYTE);
PROCEDURE AddScrollBars(VAR CW : CommandWindow; Bottom : BOOLEAN);
PROCEDURE AddFunctionKeys(VAR CP : CommandProcessor);
PROCEDURE CustomizeCommandProcessor(VAR CP : CommandProcessor);
PROCEDURE SetZoomLimits(CW : CommandWindow; X1, Y1, X2, Y2 : BYTE);
FUNCTION ToggleZoom(VAR CW : CommandWindow) : BOOLEAN;
FUNCTION KeyboardMove(VAR CW : CommandWindow) : BOOLEAN;
FUNCTION KeyboardResize(VAR CW : CommandWindow) : BOOLEAN;


TYPE
    Coord          = ARRAY[1..ScreenMax] OF NENWindowPtr;

VAR
    Coords         : Coord ABSOLUTE NENWindows;

IMPLEMENTATION
USES
    UERROR,
    UTIAM;

VAR
    StatWin    : RawWindowPtr;

    {-------------------------------------------------------}

    PROCEDURE UpdateTime(Force : BOOLEAN);
    BEGIN
{$IFDEF USEIPX}
        CheckForIPXCall;
        IF IPXMessagePending THEN HandleIPXMessage;
{$ENDIF}
        IF NENFlag THEN BEGIN
            UpTime;
            EXIT;
        END
        ELSE BEGIN
            UpdateWtime(Force);
        END;
    END;

    {------------------------------------------------------------------------}

    PROCEDURE SaveStatusline;
    VAR
        WinOpts    : LONGINT;
    BEGIN
        WinOpts := wClear;
        NEW(StatWin, InitCustom(1, 25, 80, 25, DefaultColorSet, WinOpts));
        StatWin^.Draw;
    END;

    {------------------------------------------------------------------------}

    PROCEDURE RestoreStatusLine;
    BEGIN
        DISPOSE(StatWin, Done);
    END;

    {-------------------------------------------------------}

    PROCEDURE MoveWin(NewX, NewY : INTEGER);
    VAR
        CX, Cy     : INTEGER;
    BEGIN
        HideMouse;
        WITH Coords[ScreenNum]^ DO BEGIN
            MoveWindow(CX, Cy);
            FullMouseWindow;
        END;
        ShowMouse;
    END;

    {-------------------------------------------------------}
    FUNCTION ToggleZoom(VAR CW : CommandWindow) : BOOLEAN;
    {-Toggle zoom status of a window. Returns False if there's insufficient
      memory.}
    BEGIN
        WITH CW DO BEGIN
            IF IsZoomed THEN
                Unzoom
            ELSE
                Zoom;

            IF ClassifyError(GetLastError) = etFatal THEN BEGIN
                {InsufficientMemory;} {!!.03}
                ToggleZoom := FALSE;
            END
            ELSE
                ToggleZoom := TRUE;
        END;
    END;

    {-------------------------------------------------------}
    FUNCTION KeyboardMove(VAR CW : CommandWindow) : BOOLEAN;
    {-Move a window using the keyboard. Returns False if there's insufficient
      memory.}
    VAR
        AllDone        : BOOLEAN;
    BEGIN
        KeyboardMove := TRUE;
        SavePrompt;
        Prompt(' Use cursor keys to move, <Enter> to accept');
        AllDone := FALSE;
        WITH CW DO
        REPEAT
            CASE cwCmdPtr^.cpGetKey OF
                $4700 : MoveWindow(- Step, - Step); {Home}
                $4800 : MoveWindow(0, - Step); {Up arrow}
                $4900 : MoveWindow(Step, - Step); {PgUp}
                $4B00 : MoveWindow(- Step, 0); {Left Arrow}
                $4D00 : MoveWindow(Step, 0); {Right Arrow}
                $4F00 : MoveWindow(- Step, Step); {End}
                $5000 : MoveWindow(0, Step); {Down arrow}
                $5100 : MoveWindow(Step, Step); {PgDn}
                $1C0D : AllDone := TRUE; {Enter}
            END;

            IF ClassifyError(GetLastError) = etFatal THEN BEGIN
                {InsufficientMemory;} {!!.03}
                KeyboardMove := FALSE;
                AllDone := TRUE;
            END;
            ClearErrors;
        UNTIL AllDone;
        RestorePrompt;
    END;

    {-------------------------------------------------------}
    FUNCTION KeyboardResize(VAR CW : CommandWindow) : BOOLEAN;
    {-Resize a window using the keyboard. Returns False if there's insufficient
      memory.}
    VAR
        AllDone        : BOOLEAN;
    BEGIN
        KeyboardResize := TRUE;
        SavePrompt;
        Prompt(' Use cursor keys to resize, <Enter> to accept');
        AllDone := FALSE;
        WITH CW DO
        REPEAT
            CASE cwCmdPtr^.cpGetKey OF
                $4700 : ResizeWindow(- Step, - Step); {Home}
                $4800 : ResizeWindow(0, - Step); {Up}
                $4900 : ResizeWindow(Step, - Step); {PgUp}
                $4B00 : ResizeWindow(- Step, 0); {Left}
                $4D00 : ResizeWindow(Step, 0); {Right}
                $4F00 : ResizeWindow(- Step, Step); {End}
                $5000 : ResizeWindow(0, Step); {Down}
                $5100 : ResizeWindow(Step, Step); {PgDn}
                $1C0D : AllDone := TRUE; {Enter}
            END;

            IF ClassifyError(GetLastError) = etFatal THEN BEGIN
                {InsufficientMemory;} {!!.03}
                KeyboardResize := FALSE;
                AllDone := TRUE;
            END;
            ClearErrors;
        UNTIL AllDone;
        RestorePrompt;
    END;

    {-------------------------------------------------------}
    PROCEDURE MoveWinRel(NewX, NewY : INTEGER);
    BEGIN
        HideMouse;
        WITH Coords[ScreenNum]^ DO BEGIN
            MoveWindow(NewX, NewY);
        END;
        ShowMouse;
    END;

    {-------------------------------------------------------}

    PROCEDURE SaveAndHideCursor;
    BEGIN
        WITH UData^ DO BEGIN
            IF CursorHidden THEN EXIT;
            CursorStart := CursorStartLine;
            CursorEnd := CursorEndLine;
            HiddenCursor;
            CursorHidden := TRUE;
        END;
    END;

    {-------------------------------------------------------}

    PROCEDURE RestoreCursor;
    BEGIN
        WITH UData^ DO BEGIN
            IF CursorHidden THEN
                SetCursorSize(CursorStart, CursorEnd);
            CursorHidden := FALSE;
        END;
    END;

    {-------------------------------------------------------}

    PROCEDURE WriteWindowTitle(Title : TitleString);
    BEGIN
        Coords[ScreenNum]^.ChangeHeader(0, Title);
    END;

    {------------------------------------------------------------------------}

    PROCEDURE CustomizeWindow(VAR CW         : CommandWindow;
                              Title          : STRING;
                              TWidth         : BYTE);
        {-Customize a window (add title, scroll bars, etc.)}
    VAR
        MW             : WORD;
        Mattr          : WORD;
    CONST
        {frame stuff}
        SliderChar     = #$FE {'²'} ;
        ScrollBarChar  = '°';
        BackdropChar   = '±';
        BackdropAttr   = $07;
        TpUiFrame      = 'ÕÔ¸¾ÍÍ³³';
        Step           = 1;

    BEGIN
        IF NOT UData^.BorderOn THEN EXIT;
        WITH UData^, CW, wFrame, NENColorSet DO BEGIN
            IF wOptionsAreOn(wUserContents) THEN
                wOptionsOff(wSaveContents);

            {set limits for window coordinates}
            {    SetPosLimits(ZoomX1, ZoomY1, ZoomX2, ZoomY2);}

            IF wOptionsAreOn(wResizeable) THEN BEGIN
                {set resizing limits, accounting for hot spots}
                MW := MaxWord(wMinW, MinWord(TWidth + 12, Width));
                {SetSizeLimits(MW, wMinH, wMaxW, wMaxH);}
            END;

            {specify shadow type}
            IF BorderOn THEN
                AddShadow(shBR, shSeeThru);

            wOptionsOff(wAltFrame);

            IF wOptionsAreOn(wAltFrame) THEN BEGIN
                aFrame.SetFrameType(SglWindowFrame);
                aFrame.AddShadow(shBR, shSeeThru);
            END;

            IF TWidth = 0 THEN
                EXIT;

            {make the window explode}
            IF Explode THEN
                EnableExplosions(8);

            {add title header and save the number}
            IF Title <> '' THEN BEGIN
                Title := ' ' + Title + ' ';
                AddHeader(Title, heTC);
                IF wOptionsAreOn(wAltFrame) THEN
                    aFrame.AddHeader(Title, heTC);
                AddHotHeader(heTC, MovehotCode, LENGTH(Title)); {Move}
            END;

            {select alternate scroll bar arrows}
            DefArrows := TriangleArrows;

            {add window number/local menu button}
            IF TWidth <> 0 THEN BEGIN
                AddCustomHeader('¸', frTL, + 2, + 0, FrameColor, FrameMono);
                AddCustomHeader('þ', frTL, + 3, + 0, HotSpotColor, HotSpotMono);
                AddCustomHeader('Õ', frTL, + 4, + 0, FrameColor, FrameMono);
                AddHotRegion(frTL, hsRegion3, + 3, + 0, 1, 1); {Local menu}
            END;

            IF wOptionsAreOn(wResizeable) THEN BEGIN
                {add zoom button}
                AddCustomHeader('¸', frTR, - 4, + 0, FrameColor, FrameMono);
                AddCustomHeader(^R, frTR, - 3, + 0, HotSpotColor, HotSpotMono);
                AddCustomHeader('Õ', frTR, - 2, + 0, FrameColor, FrameMono);
                AddHotRegion(frTR, ZoomHotCode, - 3, + 0, 1, 1); {Zoom}

                {add resize button}
                AddCustomHeader('+', frBR, + 0, + 0, HotSpotColor, HotSpotMono);
                AddHotRegion(frBR, ResizeHotCode, + 0, + 0, 1, 1); {Resize}

            END;

        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE AddScrollBars(VAR CW : CommandWindow; Bottom : BOOLEAN);
    VAR
        MW             : WORD;
    CONST
        {frame stuff}
        SliderChar     = '²';
        ScrollBarChar  = '°';
        BackdropChar   = '±';
    BEGIN
        IF NOT UData^.BorderOn THEN EXIT;
        WITH CW, wFrame DO BEGIN
            {add scroll bars}
            IF Bottom THEN
                AddCustomScrollBar(
                    frBB, 0, MAXLONGINT, ((frXH - frXl) DIV 2) + 2, 1, SliderChar, ScrollBarChar, NENColorSet);
            AddCustomScrollBar(
                frRR, 0, MAXLONGINT, 1, 1, SliderChar, ScrollBarChar, NENColorSet);
        END;
    END;

    {------------------------------------------------------------------------}

    PROCEDURE AddFunctionKeys(VAR CP : CommandProcessor);
    BEGIN
        CP.AddCommand(ccUser0, 1, OpKey.F1, 0);
        CP.AddCommand(ccUser1, 1, OpKey.F2, 0);
        CP.AddCommand(ccUser2, 1, OpKey.F3, 0);
        CP.AddCommand(ccUser3, 1, OpKey.F4, 0);
        CP.AddCommand(ccUser4, 1, OpKey.F5, 0);
        CP.AddCommand(ccUser5, 1, OpKey.F6, 0);
        CP.AddCommand(ccUser6, 1, OpKey.F7, 0);
        CP.AddCommand(ccUser7, 1, OpKey.F8, 0);
        CP.AddCommand(ccUser8, 1, OpKey.F9, 0);
        CP.AddCommand(ccUser9, 1, OpKey.F10, 0);
        CP.AddCommand(ccUser10, 1, OpKey.ShF1, 0);
        CP.AddCommand(ccUser11, 1, OpKey.ShF2, 0);
        CP.AddCommand(ccUser12, 1, OpKey.ShF3, 0);
        CP.AddCommand(ccUser13, 1, OpKey.ShF4, 0);
        CP.AddCommand(ccUser14, 1, OpKey.ShF5, 0);
        CP.AddCommand(ccUser15, 1, OpKey.SHF6, 0);
        CP.AddCommand(ccUser16, 1, OpKey.SHF7, 0);
        CP.AddCommand(ccUser17, 1, OpKey.SHF8, 0);
        CP.AddCommand(ccUser18, 1, OpKey.SHF9, 0);
        CP.AddCommand(ccUser19, 1, OpKey.SHF10, 0);
        CP.AddCommand(ccUser20, 1, OpKey.CtrlF1, 0);
        CP.AddCommand(ccUser21, 1, OpKey.CtrlF2, 0);
        CP.AddCommand(ccUser22, 1, OpKey.CtrlF3, 0);
        CP.AddCommand(ccUser23, 1, OpKey.CtrlF4, 0);
        CP.AddCommand(ccUser24, 1, OpKey.CtrlF5, 0);
        CP.AddCommand(ccUser25, 1, OpKey.CtrlF6, 0);
        CP.AddCommand(ccUser26, 1, OpKey.CtrlF7, 0);
        CP.AddCommand(ccUser27, 1, OpKey.CtrlF8, 0);
        CP.AddCommand(ccUser28, 1, OpKey.CtrlF9, 0);
        CP.AddCommand(ccUser29, 1, OpKey.CtrlF10, 0);
        CP.AddCommand(ccUser30, 1, OpKey.AltF1, 0);
        CP.AddCommand(ccUser31, 1, OpKey.AltF2, 0);
        CP.AddCommand(ccUser32, 1, OpKey.AltF3, 0);
        CP.AddCommand(ccUser33, 1, OpKey.AltF4, 0);
        CP.AddCommand(ccUser34, 1, OpKey.AltF5, 0);
        CP.AddCommand(ccUser35, 1, OpKey.AltF6, 0);
        CP.AddCommand(ccUser36, 1, OpKey.AltF7, 0);
        CP.AddCommand(ccUser37, 1, OpKey.AltF8, 0);
        CP.AddCommand(ccUser38, 1, OpKey.AltF9, 0);
        CP.AddCommand(ccUser39, 1, OpKey.AltF10, 0);
    END;

    {------------------------------------------------------------------------}

    PROCEDURE CustomizeCommandProcessor(VAR CP : CommandProcessor);
    VAR
        Mattr      : WORD;
        DP             : DragProcessor ABSOLUTE CP;
    CONST
        AltExits       : CharSet = ['A'..'Z'];
    BEGIN
        WITH DP DO BEGIN
            SetAltKeySet(AltExits);
            cpOptionsOn(cpEnableMouse);
            SetKeypressedProc(UKey.KeyWaiting);
            SetGetKeyProc(UKey.GetKey);
(*            AddCommand(ccUser8, 1, OpKey.F9, 0); { Local menu }*)
            AddCommand(ccQuit, 1, OpKey.Esc, 0); { Escape     }
            AddCommand(ccUser40, 1, OpKey.AltM, 0); { Move }
            AddCommand(ccUser41, 1, OpKey.AltZ, 0); { Zoom }
            AddCommand(ccUser42, 1, OpKey.AltR, 0); { Resize }
            IF MouseInstalled THEN BEGIN
                Mattr :=
                    WORD(ColorMono(NENColorSet.MouseColor, NENColorSet.MouseMono)) SHL 8;
                SetMouseCursor(
                    Mattr OR $04, Mattr OR $12, Mattr OR $1D);
            END;
        END;
    END;

    {------------------------------------------------------------------------}

    PROCEDURE SetZoomLimits(CW : CommandWindow; X1, Y1, X2, Y2 : BYTE);
    BEGIN
        {set limits for window coordinates}
        CW.SetPosLimits(X1, Y1, X2, Y2);
    END;

    {-------------------------------------------------------}
    { Opens a new window as current }
    PROCEDURE OpenWindow(X1, Y1, X2, Y2 : INTEGER;
                         Title : TitleString; Cscheme : ColorSetProc);
                    VAR
                        Opts       : LONGINT;
    BEGIN
        INC(ScreenNum);
        Cscheme;

        Opts := wSaveContents;
        IF (X1 <> 1) AND(UData^.BorderOn) THEN
            Opts := Opts OR wBordered OR wAltFrame;
{    with Command DO BEGIN
        cpOptionsOn(cpEnableMouse+cpUpcase);
        SetGetKeyProc(GetKey);
        SetKeyPressedProc(KeyWaiting);
        AddCommand(ccQuit,1,$011B,0);
      end;}

        Coords[ScreenNum] := NEW(NENWindowPtr,
                                 InitCustom(X1, Y1, X2, Y2, NENColorSet, Opts));

        CustomizeWindow(Coords[ScreenNum]^, Title, 8);
        CustomizeCommandProcessor(Coords[ScreenNum]^.WCP^);

        WITH Coords[ScreenNum]^ DO BEGIN
            SetColors := Cscheme;
            FillCharacter := NENFillChar;
            {specify shadow type}
            IF (X2 < 78) AND(UData^.BorderOn) THEN
                wFrame.AddShadow(shBR, shSeeThru);

            {make the window explode}
            IF Explode THEN
                EnableExplosions(8);
            Draw;
            Select;
        END;
        FullMouseWindow;
        SaveAndHideCursor;
        HiddenCursor;
    END;

    {-------------------------------------------------------}
    { Erases the current window and pops to the previous window }
    PROCEDURE CloseWindow;
    BEGIN
        HideMouse;
        IF NENWindows[ScreenNum] <> NIL THEN
            DISPOSE(NENWindows[ScreenNum], Done);
        DEC(ScreenNum);           { Pop previous window }
        IF ScreenNum = 0 THEN BEGIN
            FullMouseWindow;
            MouseGotoXY(40, 12);
            EXIT;
        END;
        {RestoreHotSpotState;  }  { Restore Mouse hot spots & window }
        FullMouseWindow;
        RestoreCursor;

    END;

    {-------------------------------------------------------}
    PROCEDURE OpenScreen(Border : WORD; Title : TitleString; Cscheme : ColorSetProc);
    VAR 
        BorderSave : BOOLEAN;
    BEGIN
        WITH UData^ DO BEGIN
            BorderSave := BorderOn;
            SetBorderType(Border);
            SuspendWindowEffects;
            IF Border = NoBorder THEN
                OpenWindow(1, 1, 80, 24, Title, Cscheme)
            ELSE
                OpenWindow(2, 2, 79, 23, Title, Cscheme);
            RestoreWindowEffects;
            FullMouseWindow;
            BorderOn := BorderSave;
        END;
    END;

    {-------------------------------------------------------}
    { Initializes screen variables for non Windows oriented programs }

    PROCEDURE InitWindows;
    VAR
        Alloc      : BOOLEAN;
    BEGIN
        WITH UData^ DO BEGIN
            ScreenNum := 0;
            ClockAttr := NENColorSet.HeaderColor;
            ClockOn := FALSE;
            PromptLine := 25;
            WindowsMode := FALSE;
            SetBorderChars(FALSE);
            SetBorderType(2);
            BorderOn := TRUE;
            SetWindowEffects(TRUE, 5, FALSE); { Exploding windows, 5ms, No noise }
        END;
    END;

    {-------------------------------------------------------}
    { Initializes screen with the first window }

    PROCEDURE InitScreen(Title : TitleString; Cscheme : ColorSetProc);
    VAR 
        Alloc      : BOOLEAN;
    BEGIN
        WITH UData^ DO BEGIN
            ScreenNum := 0;
            SetBorderChars(FALSE);
            SetBorderType(2);
            BorderOn := TRUE;
            SetWindowEffects(TRUE, 5, FALSE); { Exploding windows, 5ms, No noise }
            SuspendWindowEffects;
            OpenWindow(2, 2, 79, 24, Title, Cscheme);
            RestoreWindowEffects;
            ClockAttr := NENColorSet.HeaderColor;
            UpdateTime(TRUE);
            PromptLine := 25;
            WindowsMode := TRUE;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE SwitchTempWindow(Screen : INTEGER);
    BEGIN
        WITH Coords[Screen]^ DO BEGIN
            FullMouseWindow;
            SetColors;
            Select;
        END;
    END;

    {-------------------------------------------------------}
    { Opens a quarter screen window in the specified quadrant }
    { 1=top left, 2=top right, 3=bottom left, 4=bottom right }
    PROCEDURE QuarterScreenWindow(Colr : INTEGER; Num : INTEGER; Title : TitleString);
    TYPE
        OneWin         = ARRAY[1..4] OF INTEGER;
    CONST
        Win            : ARRAY[1..4] OF OneWin =
        ((2, 2, 39, 12), (40, 2, 78, 12), (2, 13, 39, 22), (40, 13, 78, 22));
    BEGIN
        OpenWindow(Win[Num, 1], Win[Num, 2], Win[Num, 3], Win[Num, 4], Title, Green_Scheme);
    END;

    {-------------------------------------------------------}
    { Opens a window centred in the screen }
    PROCEDURE CentreWindow(Title : TitleString);
    BEGIN
        OpenWindow(20, 6, 60, 18, Title, White_Scheme);
    END;

    {-------------------------------------------------------}
{Procedure ClearBackground;
Var
    X,Y,Xx1,Yy2: integer;
      Chw,B,ofb: word;
  begin
  with Coords[ScreenNum]^ DO BEGIN
    if FillCharacter <> #0 THEN BEGIN
      SetFillColors;
      wBackChar := FillCharacter;
      wTextColor := TextAttr;
      end
    else
      SetWindowColors;
    ClearContents;
    end;
  end;
}
    {-------------------------------------------------------}
    PROCEDURE SetColorScheme(Scheme : ColorSetProc);
    BEGIN
        Scheme;
    END;

    {-------------------------------------------------------}
    FUNCTION WinX  : WORD;
    BEGIN
        WinX := Coords[ScreenNum]^.wFrame.frXl;
    END;

    {-------------------------------------------------------}
    FUNCTION WinY  : WORD;
    BEGIN
        WinY := Coords[ScreenNum]^.wFrame.frYL;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetBorderColors;
    BEGIN
        TextAttr := NENColorSet.FrameColor;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetWindowColors;
    BEGIN
        TextAttr := NENColorSet.TextColor;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetTitleColors;
    BEGIN
        TextAttr := NENColorSet.HeaderColor;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetMenuColors;
    BEGIN
        TextAttr := NENColorSet.FieldColor;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetFillColors;
    BEGIN
        TextAttr := NENColorSet.BlockColor;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetCommentColors;
    BEGIN
        TextAttr := NENColorSet.PromptColor;
    END;

    {-------------------------------------------------------}
    PROCEDURE WriteCentred(Y : INTEGER; Msg : SType);
    VAR 
        Xm, Ym, Xm1, Xm2 : INTEGER;
        I              : INTEGER;
    BEGIN
        Coords[ScreenNum]^.wFastCenter(Msg, Y, TextAttr);
        LastCharTime := CurrentTime;
    END;

    {-------------------------------------------------------}
    PROCEDURE WriteCentredAbs(Y : INTEGER; Msg : SType);
    VAR 
        Xm, Ym, Xm1, Xm2 : INTEGER;
        I              : INTEGER;
    BEGIN
        Xm1 := 1;
        Xm2 := 80;
        Ym := Y;
        IF LENGTH(Msg) > (Xm2 - Xm1) THEN BEGIN
            Xm := Xm1 + 1;
            FOR I := 1 TO Xm2 - Xm1 - 1 DO
                WriteChr(Xm + I, Ym, Msg[I], TextAttr);
        END
        ELSE BEGIN
            Xm := (Xm1 + ((Xm2 - Xm1) - LENGTH(Msg)) DIV 2) - 1;
            FOR I := 1 TO LENGTH(Msg) DO
                WriteChr(Xm + I, Ym, Msg[I], TextAttr);
        END;
        LastCharTime := CurrentTime;
    END;

    {-------------------------------------------------------}
    PROCEDURE Prompt(Msg : SType);
    VAR 
        I          : INTEGER;
    BEGIN
        WITH UData^ DO BEGIN
            IF PromptLine = 0 THEN EXIT;
            TextColor(PromptFore);
            TextBackground(PromptBack);
            {      DeactivateVirtualScreen;}
            WriteStr(1, PromptLine, PadCh('', #$B2, 80), TextAttr);
            TextBackground(PromptBack);
            TextColor(PromptText);
            WriteCentredAbs(PromptLine, Msg);
            {      ReactivateVirtualScreen;}
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE BuildDirectory(FMask          : BigString;
                             SuppressExt    : BOOLEAN;
                             Attrib         : WORD;
                             VAR Dir;
                             VAR Size       : INTEGER);
                            VAR
                                I, L       : INTEGER;
        Att            : WORD;
        FileAttr       : WORD;
        DosErr         : INTEGER;
        FR             : SearchRec;
        Direc          : HugeList ABSOLUTE Dir;
    BEGIN
        Att := Attrib;
        IF Att = 0 THEN
            Att := AnyFile;
        IF Att = AnyFile THEN
            Att := (AnyFile AND NOT(VolumeID + Directory + SysFile));
        I := 0;
        FindFirst(FMask, Att, FR);
        IF DOSERROR <> 0 THEN     { was = 2 }
        BEGIN
            Size := 0;
            EXIT;
        END;
        FileAttr := FR.Attr AND $3F;
        IF FileAttr = 0 THEN
            FileAttr := $3F;
        IF (FR.Name[1] <> '.') AND(FileAttr AND Attrib <> 0) THEN BEGIN
            INC(I);
            Direc[I] := FR.Name;
            IF SuppressExt THEN BEGIN
                L := POS('.', Direc[I]);
                IF L <> 0 THEN
                    DELETE(Direc[I], L, LENGTH(Direc[I]) - L + 1);
            END;
        END;
        DosErr := 0;
        REPEAT
            BEGIN
                FindNext(FR);
                DosErr := DOSERROR;
                IF DosErr = 0 THEN BEGIN
                    FileAttr := FR.Attr;
                    IF FileAttr = 0 THEN
                        FileAttr := $3F;
                    IF (FR.Name[1] <> '.') AND(FileAttr AND Attrib <> 0) THEN BEGIN
                        IF I <= MaxMenuSize THEN
                            INC(I);
                        IF I <= MaxMenuSize THEN
                            Direc[I] := FR.Name;
                        IF SuppressExt THEN BEGIN
                            L := POS('.', Direc[I]);
                            IF L <> 0 THEN
                                DELETE(Direc[I], L, LENGTH(Direc[I]) - L + 1);
                        END;
                    END;
                END;
            END;
        UNTIL DosErr <> 0;
        Size := I;
    END;

    {-------------------------------------------------}
    PROCEDURE SavePrompt;
    VAR 
        I          : INTEGER;
    BEGIN
        WITH UData^ DO BEGIN
            IF PS = ScreenMax THEN
                EXIT;
            INC(PS);
            FOR I := 1 TO 80 DO
                GetChr(I, 25, PSaveStack[PS].Psave[I], PSaveStack[PS].Pattr[I]);
        END;
    END;

    {-------------------------------------------------}
    PROCEDURE RestorePrompt;
    VAR 
        I          : INTEGER;
    BEGIN
        WITH UData^ DO BEGIN
            IF PS <= 0 THEN EXIT;
            FOR I := 1 TO 80 DO
                WriteChr(I, 25, PSaveStack[PS].Psave[I], PSaveStack[PS].Pattr[I]);
            DEC(PS);
            IF PS < 0 THEN
                PS := 0;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetPromptLine(P : INTEGER);
    BEGIN
        UData^.PromptLine := P;
    END;

    {-------------------------------------------------------}
    FUNCTION Dialog(Msg : SType; Title : TitleString; TitleColor : BYTE;
                    Box1 : TitleString; Box2 : TitleString;
                    Box3 : TitleString) : INTEGER;
                VAR
                    I          : INTEGER;
        H, T           : BYTE;
        Boxes          : ARRAY[1..3] OF BigString;
    BEGIN
        WITH UData^ DO BEGIN
            I := 3;
            IF Box3 = '' THEN
               Begin
               DEC(I);
               IF Box2 = '' THEN
                  Begin
                  DEC(I);
                  End;
               End;

            Boxes[1] := Box1;
            Boxes[2] := Box2;
            Boxes[3] := Box3;

            CASE TitleColor AND $7 OF
                Black : BEGIN H := Yellow; T := LightGray; END;
                Blue : BEGIN H := LightCyan; T := Cyan; END;
                Green : BEGIN H := Yellow; T := White; END;
                Cyan : BEGIN H := Magenta; T := Blue; END;
                Red : BEGIN H := LightCyan; T := White; END;
                Magenta : BEGIN H := LightCyan; T := LightGray; END;
                Brown : BEGIN H := LightBlue; T := Blue; END;
                LightGray : BEGIN H := Red; T := Black; END;
            END;
            Dialog := AskUser(26, 10, Msg, Title, White_Scheme, TitleColor,
                              TitleColor AND 7,
                              H,
                              T,
                              I, Boxes);
        END;
    END;

    {-------------------------------------------------------}
    FUNCTION DialogBlink(Msg : SType; Title : TitleString; TitleColor : BYTE;
                         Box1 : TitleString; Box2 : TitleString) : INTEGER;
                    VAR
                        I          : INTEGER;
        H, T           : BYTE;
        Boxes          : ARRAY[1..2] OF BigString;
    BEGIN
        WITH UData^ DO BEGIN
            I := 2;
            IF Box2 = '' THEN
                DEC(I);
            Boxes[1] := Box1;
            Boxes[2] := Box2;
            CASE TitleColor AND $7 OF
                Black : BEGIN H := Yellow; T := LightGray; END;
                Blue : BEGIN H := LightCyan; T := Cyan; END;
                Green : BEGIN H := Yellow; T := White; END;
                Cyan : BEGIN H := Magenta; T := Blue; END;
                Red : BEGIN H := LightCyan; T := White; END;
                Magenta : BEGIN H := LightCyan; T := LightGray; END;
                Brown : BEGIN H := LightBlue; T := Blue; END;
                LightGray : BEGIN H := Red; T := Black; END;
            END;
            DialogBlink := AskUser(26, 10, Msg, Title, Gray_Scheme, TitleColor,
                                   TitleColor AND 7,
                                   H,
                                   T,
                                   I, Boxes);
        END;
    END;

    {-------------------------------------------------------}

    FUNCTION AskUser(X1, Y1         : INTEGER;
                     Msg            : SType;
                     Title          : TitleString;
                     Cscheme        : ColorSetProc;
                     TitleColor     : BYTE;
                     BoxColor       : BYTE;
                     HighlightColor : BYTE;
                     StringColor    : BYTE;
                     NumBoxes       : INTEGER;
                     VAR Boxes)     : INTEGER;
    VAR
        FDB            : DialogBoxPtr;
        Status         : WORD;
        I, J           : INTEGER;
        Wid            : INTEGER;
        X2, Y2         : INTEGER;
        CurX           : INTEGER;
        Spacing        : INTEGER;
        TextAtr        : BYTE;
        Box            : HugeList ABSOLUTE Boxes;

        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            X2 := X1 + J;
            Y2 := Y1 + 4;
            X2 := X1 + J + 4;
            IF (X2 - X1) < 20 THEN
                X2 := X1 + 20;
            NEW(FDB, InitCustom(
                X1, Y1, X2, Y2,   {top left corner (X,Y)}
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            CustomizeWindow(FDB^, Title, 10);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN
        J := 3;
        FOR I := 1 TO NumBoxes DO
            J := J + (LENGTH(Box[I]) + 3); { Text + 2 spaces + shadow }

        IF LENGTH(Msg) > J THEN J := LENGTH(Msg);

        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        Cscheme;

        NENDialogSet.ButtonColor := (BoxColor AND $F) SHL 4;
        NENDialogSet.HiButtonColor := (NENDialogSet.ButtonColor AND $F0) OR HighlightColor;
        NENDialogSet.SelButtonColor := (NENDialogSet.ButtonColor AND $F0) OR HighlightColor;
        NENDialogSet.ButtonColor := (NENDialogSet.ButtonColor AND $F0) OR StringColor;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            HALT(1);
        END;

        DialogCommands.Init(@DialogKeySet, DialogKeyMax);
        CustomizeCommandProcessor(DialogCommands);

        TextAtr := FDB^.wTextColor;
        FDB^.wTextColor := (TitleColor SHL 4) OR White;
        FDB^.AddTextField(CenterCh('', ' ', (X2 - X1) + 1), 1, 1);
        FDB^.AddTextField(CenterCh(Msg, 'Ä', (X2 - X1) + 1), 2, 1);
        FDB^.AddTextField(CenterCh('', 'Ü', (X2 - X1) + 1), 3, 1);

        FDB^.wTextColor := TextAtr;

        Spacing := (((X2 - X1 + 2) - J + 1) DIV NumBoxes) + 1;
        IF NumBoxes = 2 THEN
            Spacing := (X2 - (LENGTH(Box[2]) + 3)) - (X1 + 3) - LENGTH(Box[1]);
        IF Spacing < 2 THEN
            Spacing := 2;
        CurX := X1;
        IF NumBoxes = 1 THEN
            CurX := X1 + ((X2 - X1) DIV 2) - (LENGTH(Box[1]) + 2 DIV 2);

        FOR I := 1 TO NumBoxes DO BEGIN
            Wid := LENGTH(Box[I]) + 2;
            FDB^.AddPushButton(Pad(' &' + Box[I], Wid), 4, (CurX - X1) + 2, Wid, 0, ccUser0 + I, I = 1);
            CurX := CurX + Wid + Spacing;
        END;

        FDB^.Process;
        CASE FDB^.GetLastCommand OF
            ccQuit : BEGIN
                         AskUser := 0;
                     END;
            ccUser1..ccUser9 : AskUser := ORD(FDB^.GetLastCommand) - ORD(ccUser0);
        END;

        DISPOSE(FDB, Done);

    END;

    {-------------------------------------------------------}
    FUNCTION YesNo(Msg : SType; Title : TitleString; CSheme : ColorSetProc) : BOOLEAN;
    BEGIN
        CASE Dialog(Msg, Title, NENColorSet.TextColor, SysMsg(64), SysMsg(65),
                    SysMsg(2376){Cancel}) OF
            0 : YesNo := FALSE;   { Escape means NO}
            1 : YesNo := TRUE;    { 'Yes' }
            2 : YesNo := FALSE;   { 'No' }
            3 : YesNo := FALSE;   { 'Cancel' }
        END;
    END;

    {-------------------------------------------------------}
    FUNCTION Yes(Msg : SType) : BOOLEAN;
    BEGIN
        Yes := YesNo(Msg, SysMsg(000665) {' STOP! '} , Alarm_Colors);
    END;

    {-------------------------------------------------------}
    FUNCTION Yes2(Msg : SType) : BOOLEAN;
    BEGIN
        Yes2 := YesNo(Msg, SysMsg(000666) {' WARNING! '} , Blue_scheme);
    END;

    {-------------------------------------------------------}
    FUNCTION UserSaysYes(Msg : SType; EscapeYes : BOOLEAN) : BOOLEAN;
    BEGIN
        Menu^[1] := SysMsg(64);
        Menu^[2] := SysMsg(65);
        CASE AskUser(27, 9,       { x1,y1,x2,y2 }
                     Msg,
                     SysMsg(000254) {' CAUTION! '} , { as for Dialog }
                     White_Scheme, { main colors }
                     Blue,        { Title background }
                     Brown,       { Box background }
                     LightBlue,   { First letter }
                     Blue,        { Remaining letters }
                     2,           { Number of items }
                     Menu^) OF    { item list }
                    0 : IF EscapeYes THEN UserSaysYes := TRUE ELSE UserSaysYes := FALSE; { Escape }
            1 : UserSaysYes := TRUE; { 'Yes' }
            2 : UserSaysYes := FALSE; { 'No' }
        END;
    END;

    {-------------------------------------------------------}
    FUNCTION UserYes(Msg : SType; EscapeYes : BOOLEAN) : BOOLEAN;
    BEGIN
        SetBorderType(3);
        CASE Dialog(Msg, SysMsg(000254) {' CAUTION! '} , LightGray, SysMsg(000064) {'YES '} , SysMsg(000065) {'NO  '},
                    SysMsg(2376){Cancel}) OF
            0 : IF EscapeYes THEN UserYes := TRUE ELSE UserYes := FALSE; { Escape }
            1 : UserYes := TRUE;  { 'Yes' }
            2 : UserYes := FALSE; { 'No' }
            3 : IF EscapeYes THEN UserYes := TRUE ELSE UserYes := FALSE; { Cancel }
        END;
        SetBorderType(1);
    END;

    {-------------------------------------------------------}
    PROCEDURE OpenMessage(Msg : SType; Cscheme : ColorSetProc);
    VAR 
        Ch         : CHAR;
        EscFlag, FuncFlag : BOOLEAN;
    BEGIN
        WITH UData^ DO BEGIN
            Explode := FALSE;
            OpenWindow(22, 11, 58, 14, '', Cscheme);
            Explode := TRUE;
            WriteCentred(2, Msg);
            MessageUp := TRUE;
        END;
    END;

    {-------------------------------------------------}
    PROCEDURE CloseMessage;
    BEGIN
        WITH UData^ DO BEGIN
            IF MessageUp THEN
                CloseWindow;
            MessageUp := FALSE;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE WaitForEscape;
    LABEL GetAnotherKey, Done;
    VAR 
        Minst      : BOOLEAN;
        Ch, Ch2        : CHAR;
        C              : INTEGER;
    BEGIN
GetAnotherKey:
        WHILE (NOT Check4Chars) DO BEGIN
            UpdateTime(FALSE);
        END;
        GetNextChar(Ch, Ch2);

        IF (Ch <> Esc) THEN BEGIN
            GOTO GetAnotherKey;
        END;
        WHILE Check4Chars DO      { Flush any remaining keys & mouse clicks }
            GetNextChar(Ch, Ch2);
Done:
        Ch := ' ';
    END;

    {-------------------------------------------------------}
    PROCEDURE WaitForKey(VAR EscFlag, FuncFlag : BOOLEAN);
    VAR 
        Ch         : CHAR;
        Scan           : WORD;
    BEGIN
        EscFlag := FALSE;
        FuncFlag := FALSE;
        WHILE NOT CheckKbd(Scan) DO
            UpdateTime(FALSE);
        Ch := CHR(Scan AND $FF);
        IF (Ch = Esc) THEN BEGIN
            IF KeyPending(Scan) THEN ;
            EscFlag := TRUE;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetWindowEffects(Grow : BOOLEAN; Speed : WORD; Noise : BOOLEAN);
    BEGIN
        WITH UData^ DO BEGIN
            Explode := Grow;
            SoundFlagW := Noise;
            ExplodeDelay := Speed;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetClockMode(T : BOOLEAN);
    BEGIN
        UData^.ClockOn := T;
    END;

    {-------------------------------------------------------}
    PROCEDURE SuspendWindowEffects;
    BEGIN
        WITH UData^ DO BEGIN
            GwSave := Explode;
            NwSave := SoundFlagW;
            Explode := FALSE;
            SoundFlagW := FALSE;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE RestoreWindowEffects;
    BEGIN
        WITH UData^ DO BEGIN
            Explode := GwSave;
            SoundFlagW := NwSave;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetPaletteRegister(Reg : BYTE; Color : BYTE);
    BEGIN
        WITH UData^, Regs DO BEGIN
            AH := $10;
            AL := 0;
            BH := Color;
            Bl := Reg;
            Intr($10, Regs);
        END;
    END;

    {-------------------------------------------------------}
    { Sets border character values depending on character set selected }
    PROCEDURE SetBorderChars(SINGLE : BOOLEAN);
    BEGIN
        WITH UData^ DO BEGIN
            IF SINGLE THEN BEGIN
                UpperLeft := #$DA; { 'É' } { Border components }
                UpperRight := #$BF; { '»' }
                LowLeft := #$C0;  { 'È' }
                LowRight := #$D9; { '¼' }
                HorizontalChar := #$C4; { 'Í' }
                VerticalChar := #$B3; { 'º' }
                TConnect := #$C2; { 'Ë' }
                RConnect := #$B4; { '¹' }
                LConnect := #$C3; { 'Ì' }
                LRConnect := #188; { '¼' }
                UConnect := #162;
            END
            ELSE BEGIN
                UpperLeft := #201; { 'É' } { Border components }
                UpperRight := #187; { '»' }
                LowLeft := #200;  { 'È' }
                LowRight := #188; { '¼' }
                HorizontalChar := #205; { 'Í' }
                VerticalChar := #186; { 'º' }
                TConnect := #203; { 'Ë' }
                RConnect := #185; { '¹' }
                LConnect := #204; { 'Ì' }
                LRConnect := #188; { '¼' }
                UConnect := #162;
            END;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetBorderType(I : WORD);
    BEGIN
        WITH UData^ DO BEGIN
            BorderOn := TRUE;
            CASE I OF
                0 : BorderOn := FALSE;
                1 : BEGIN
                        (*      SetFrameChars(#$B3,#$C4,#$D9,#$BF,#$C0,#$DA);   { Single line }*)
                        RConnect := #$B4;
                        LConnect := #$C3;
                    END;
                2 : BEGIN
                        (*      SetFrameChars(#186,#205,#188,#187,#200,#201);   { Double line }*)
                        RConnect := #$B9;
                        LConnect := #$CC;
                    END;
                3 : BEGIN
                        {      FrameChars := 'ÕÔ¸¾Í³'; } { Double top, single side }
                        RConnect := #$B5;
                        LConnect := #$C6;
                    END;
                4 : BEGIN
                        {      FrameChars := '      '; } { Blank }
                        RConnect := #$20;
                        LConnect := #$20;
                    END;
            END;
        END;
    END;

    { Unit Initialization }
END.

