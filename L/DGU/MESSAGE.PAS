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
* Generic One, two or three button message dialog box object with variable
* number of lines and customizable colors.  Dialog box automatically resizes
* itself, based on the number of text lines and their widths.  Each dialog
* line is color customizable, and text justification can be specified on
* each line.
*
* Buttons can be assigned to "Ok", "Yes", "No", "Cancel", "Help" or none of
* the above.
*
*     B1 is the left button
*     B2 is the middle button
*     B3 is the right button
*
*     B5 is the television show.
*
* Narrow dialogs with two buttons should probably use B1 and B3.
*
* Mapping:
*
*   ctOk     = ccSelect
*   ctYes    = ccSelect
*   ctNo     = ccDone
*   ctCancel = ccQuit
*   ctHelp   = ccHelp
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$I OPDEFINE.INC}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT Message;

INTERFACE
USES
    DGCMD,
    GLOBTYPE,
    OpCRT,
    OpCtrl,
    OpDialog,
    OpHelp,
    OpRoot,
    OpString
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

CONST
    idB1           = 0;
    idB2           = idB1 + 1;
    idB3           = idB2 + 1;

    {---------------}

TYPE
    TConfirmation  = (ctOk, ctYes, ctNo, ctCancel, ctHelp, ctNone);

    {unit private!}
    {container for single line of message dialog text}
    MessageLineP   = ^MessageLineT;
    MessageLineT   = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(Line : STRING; Just : JustT; Col : BYTE);
                         DESTRUCTOR Done; VIRTUAL;
                     PRIVATE

                         MyLine         : StringPtr;
                         MyJust         : JustT;
                         MyCol          : BYTE;
                     END;

    {---------------}
    {unit private!}
    {container for all text lines in message dialog}
    MessageListP   = ^MessageListT;
    MessageListT   = OBJECT(SingleList)
                         CONSTRUCTOR Init;
                         FUNCTION AddLine(Line : STRING; Just : JustT; Col : BYTE) : BOOLEAN;
                         FUNCTION PencilIn(DBP : DialogBoxPtr) : BOOLEAN;

                     PRIVATE

                         MaxWidth       : BYTE;
                     END;

    {---------------}

    {public}
    {message dialog box with up to three buttons}
    {dialog resizes itself to accomodate the #text lines and widths}
    MessageBoxP    = ^MessageBoxT;
    MessageBoxT    = OBJECT(DialogBox)
                         LocalCP        : TDGUCommandProcessor;
                         {use mostly defaults}
                         CONSTRUCTOR Init(
                             Header         : STRING;
                                 {turn buttons on/off}
                             B1,
                             B2,
                             B3             : TConfirmation;
                                 {help topic number}
                             HelpItem       : WORD);

                             {customize colors}
                         CONSTRUCTOR InitCustom(
                             Header         : STRING;
                             B1,
                             B2,
                             B3             : TConfirmation;
                             HelpItem       : WORD;
                                 {text/background colors}
                             CS             : ColorSet;
                                 {button colors}
                             Ds             : DialogColorSet);

                             {customize everything}
                         CONSTRUCTOR InitCustomDeluxe(
                             Header         : STRING;
                             B1,
                             B2,
                             B3             : TConfirmation;
                             HelpItem       : WORD;
                             CS             : ColorSet;
                             Ds             : DialogColorSet;
                                 {force oversized box}
                             X,
                             Y,
                             BoxWidth,
                             Hyt            : BYTE;
                                 {footer message on frame bottom}
                             Footer         : STRING);

                         DESTRUCTOR Done; VIRTUAL;

                             {add a line of text to box - use default colors}
                         FUNCTION AddLine(
                             Line           : STRING; {the text}
                             Just           : JustT {justification}
                             )              : BOOLEAN;

                             {add a line of text to box with color override}
                         FUNCTION AddLineCustom(
                             Line : STRING; Just : JustT; Col : BYTE) : BOOLEAN;
                             {you must call this before process, to stuff all the}
                             {text lines into the dialog}

                         PROCEDURE Draw; VIRTUAL;

                         PROCEDURE InitButtonMsgs(MOk, MNo, MYes, MCancel, MHelp : LONGINT);

                         PROCEDURE ChangeTimeout(TimeoutMS : LONGINT; TimeOutCmd : TConfirmation);

                     PRIVATE
                             {stay outta here!}
                         MyColors       : ColorSet;
                         MydColors      : DialogColorSet;
                         MyHelpItem     : WORD;
                         FullyInit,
                         Virgin         : BOOLEAN;
                         MyB1,
                         MyB2,
                         MyB3           : TConfirmation;
                         MsgWidth,
                         ButtonZone,
                         ButtonWidth,
                         ButtonLine     : BYTE;
                         LineList       : MessageListT;
                         OkMsg,
                         NoMsg,
                         YesMsg,
                         CancelMsg,
                         HelpMsg        : STRING[7];

                         PROCEDURE ProcessSelf; VIRTUAL;

                             {customize everything}
                         FUNCTION fInitCustomDeluxe(
                             Header         : STRING;
                             B1,
                             B2,
                             B3             : TConfirmation;
                             HelpItem       : WORD;
                             CS             : ColorSet;
                             Ds             : DialogColorSet;
                                 {force oversized box}
                             X,
                             Y,
                             BoxWidth,
                             Hyt            : BYTE;
                                 {footer message on frame bottom}
                             Footer         : STRING) : BOOLEAN;
                     END;


    {---------------}

PROCEDURE MessageBox(L1, Hdr : STRING; Y : LONGINT);

FUNCTION YesNoCancel(Hdr,
                     Msg            : STRING;
                     Default        : BOOLEAN;
                     Y,
                     N,
                     C              : LONGINT) : TConfirmation;

FUNCTION YesNoCancelHelp(Hdr,
                         Msg            : STRING;
                         Default        : BOOLEAN;
                         Y,
                         N,
                         C,
                         HelpTopic      : LONGINT;
                         TimeoutSEC     : LONGINT;
                         TimeoutKey     : TConfirmation) : TConfirmation;

IMPLEMENTATION
USES
    Colors,
    DGHELP,
    DGLIB,
    KERROR,
    MSGMGR,
    OpCmd,
    OpCol16,
    OpEdit,
    OpField,
    OpFrame,
    OpInline,
    OpKey,
    {$IFDEF USEMOUSE}
    OpMouse,
    {$ENDIF}
    OpWindow,
    SysMsg,
    UTIAM;

    (**************************)

    {instatiate a line of text object}
    CONSTRUCTOR MessageLineT.Init(Line : STRING; Just : JustT; Col : BYTE);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        MyLine := StringToHeap(Line);
        MyJust := Just;
        MyCol := Col;
    END;

    (**************************)

    {free up memory consumed by this line of text}
    DESTRUCTOR MessageLineT.Done;
    BEGIN
        DisposeString(MyLine);
    END;

    (**************************)

    {instantiate the list of message lines}
    CONSTRUCTOR MessageListT.Init;
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        MaxWidth := 0;
    END;

    (**************************)

    {add a line of text to the linked list.  Record the justification and }
    {colors to use on this line}
    FUNCTION MessageListT.AddLine(Line : STRING; Just : JustT; Col : BYTE) : BOOLEAN;
    VAR
        MLP            : MessageLineP;
    BEGIN
        AddLine := FALSE;

        Line := TruncStr(Line, ScreenWidth - 2);

        NEW(MLP, Init(Line, Just, Col));
        IF MLP <> NIL THEN
            APPEND(MLP)
        ELSE
            EXIT;
        MaxWidth := MaxWord(LENGTH(Line), MaxWidth);
        AddLine := TRUE;
    END;

    (**************************)

    {build a dialog box by creating text fields from the line list nodes}
    FUNCTION MessageListT.PencilIn(DBP : DialogBoxPtr) : BOOLEAN;
    VAR
        MLP            : MessageLineP;
        Strg           : STRING;
        I              : WORD;
        X1,
        X2,
        Y1,
        Y2             : BYTE;
    BEGIN
        PencilIn := FALSE;
        DBP^.Coordinates(X1, Y1, X2, Y2);
        FOR I := 1 TO Size DO BEGIN
            MLP := MessageLineP(Nth(I));
            IF MLP = NIL THEN
                EXIT;
            Strg := StringFromHeap(MLP^.MyLine);
            IF Strg = '' THEN
                CONTINUE;
            WITH DBP^ DO BEGIN
                CASE MLP^.MyJust OF
                    ELEFT :
                        AddTextFieldcustom(Strg, I, 2, MLP^.MyCol, MLP^.MyCol);
                    ERIGHT :
                        AddTextFieldcustom(Strg, I, wXH - wXL - LENGTH(Strg) + 1, MLP^.MyCol, MLP^.MyCol);
                    ECENTER :
                        AddTextFieldcustom(Strg, I, (2 + wXH - wXL - LENGTH(Strg)) DIV 2, MLP^.MyCol, MLP^.MyCol);
                END;
            END;
        END;
        PencilIn := TRUE;
    END;

    (**************************)

    {I hate globals, but I was too lazy to descend a new command processor}
    {object to handle help processing}
VAR
    MsgBoxHelpIndex : WORD;

    (**************************)

    {stuff in the buttons and text lines}
    PROCEDURE MessageBoxT.Draw;
    BEGIN
        MsgBoxHelpIndex := MyHelpItem;
        IF Virgin THEN BEGIN
            SetCursor(cuHidden);

            CASE MyB1 OF
                ctNone : ;
                ctOk :
                    AddPushButton(OkMsg,
                                  ButtonLine,
                                  2,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccSelect,
                                  TRUE);
                ctYes :
                    AddPushButton(YesMsg,
                                  ButtonLine,
                                  2,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccSelect,
                                  TRUE);
                ctNo :
                    AddPushButton(NoMsg,
                                  ButtonLine,
                                  2,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccDone,
                                  TRUE);
                ELSE
                    RingBell;
            END;


            CASE MyB2 OF
                ctNone : ;
                ctCancel :
                    AddPushButton(CancelMsg,
                                  ButtonLine,
                                  ((wXH - wXL) DIV 2) - (ButtonWidth DIV 2),
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccQuit,
                                  FALSE);
                ctHelp :          {!!. 14.10.96}
                    AddPushButton(HelpMsg,
                                  ButtonLine,
                                  ((wXH - wXL) DIV 2) - (ButtonWidth DIV 2),
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccHelp,
                                  FALSE);
                ctNo :
                    AddPushButton(NoMsg,
                                  ButtonLine,
                                  ((wXH - wXL) DIV 2) - (ButtonWidth DIV 2),
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccDone,
                                  FALSE);
                ctYes :
                    AddPushButton(YesMsg,
                                  ButtonLine,
                                  ((wXH - wXL) DIV 2) - (ButtonWidth DIV 2),
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccSelect,
                                  FALSE);
                ELSE
                    RingBell;
            END;


            CASE MyB3 OF
                ctCancel :
                    AddPushButton(CancelMsg,
                                  ButtonLine,
                                  (wXH - wXL) - ButtonWidth,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccQuit,
                                  FALSE);
                ctNo :
                    AddPushButton(NoMsg,
                                  ButtonLine,
                                  (wXH - wXL) - ButtonWidth,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccDone,
                                  FALSE);
                ctHelp :
                    AddPushButton(HelpMsg,
                                  ButtonLine,
                                  (wXH - wXL) - ButtonWidth,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccHelp,
                                  FALSE);
                ctYes :
                    AddPushButton(YesMsg,
                                  ButtonLine,
                                  (wXH - wXL) - ButtonWidth,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccSelect,
                                  FALSE);
                ctNone : ;
                ELSE
                    RingBell;
            END;

            SetNextField(idB1);

            {insert the lines of text}
            LineList.PencilIn(@Self);

            Virgin := FALSE;
        END;

        {now draw/redraw the dialog}
        INHERITED Draw;
    END;

    (**************************)

    PROCEDURE MessageBoxT.InitButtonMsgs(MOk, MNo, MYes, MCancel, MHelp : LONGINT);
    BEGIN
        IF MOk <> BadMsg THEN
            OkMsg := ScnMsgP^.SysMsg(MOk);
        IF MNo <> BadMsg THEN
            NoMsg := ScnMsgP^.SysMsg(MNo);
        IF MYes <> BadMsg THEN
            YesMsg := ScnMsgP^.SysMsg(MYes);
        IF MCancel <> BadMsg THEN
            CancelMsg := ScnMsgP^.SysMsg(MCancel);
        IF MHelp <> BadMsg THEN
            HelpMsg := ScnMsgP^.SysMsg(MHelp);
    END;

    (**************************)

    PROCEDURE MessageBoxT.ChangeTimeout(TimeoutMS : LONGINT; TimeOutCmd : TConfirmation);
    BEGIN
        CASE TimeOutCmd OF
            ctYes,
            ctOk :
                BEGIN
                    LocalCP.AddCommand(ccSelect, 1, PadMinus, 0);
                    LocalCP.ChangeTimeout(TimeoutMS, PadMinus);
                END;
            ctNo :
                BEGIN
                    LocalCP.AddCommand(ccDone, 1, PadPlus, 0);
                    LocalCP.ChangeTimeout(TimeoutMS, PadPlus);
                END;
            ctCancel :
                BEGIN
                    LocalCP.AddCommand(ccQuit, 1, PadStar, 0);
                    LocalCP.ChangeTimeout(TimeoutMS, PadStar);
                END;
            ctHelp :
                LocalCP.ChangeTimeout(TimeoutMS, ccHelp);
        END;
    END;

    (**************************)

    PROCEDURE MessageBoxT.ProcessSelf;
    BEGIN
        {make sure we have instantiated the dialog, then draw it}
        Draw;
        {run the dialog}
        INHERITED ProcessSelf;
    END;

    (**************************)

    {-Display context sensitive help}
    PROCEDURE MessageBoxDisplayHelp(UnitCode : BYTE; IdPtr : POINTER; HelpIndex : WORD); FAR;
    BEGIN
        {$IFDEF DEBUG}
        FastWrite(Pad(Long2Str(MsgBoxHelpIndex) + ':' + Long2Str(UnitCode), 8), ScreenHeight - 1, 1, LtRedOnBlue);
        {$ENDIF}
        DisplayHelp(0, NIL, MsgBoxHelpIndex);
    END;

    {--------------------}

    {customize everything}
    FUNCTION MessageBoxT.fInitCustomDeluxe(
        Header         : STRING;
        B1,
        B2,
        B3             : TConfirmation;
        HelpItem       : WORD;
        CS             : ColorSet;
        Ds             : DialogColorSet;
        {force oversized box}
        X,
        Y,
        BoxWidth,
        Hyt            : BYTE;
        {footer message on frame bottom}
        Footer         : STRING) : BOOLEAN;
    CONST
        WinOptions     = wBordered + wClear;
    VAR
        I              : BYTE;
    BEGIN
        FullyInit := FALSE;
        fInitCustomDeluxe := FALSE;
        MyColors := CS;
        MydColors := Ds;
        MyHelpItem := HelpItem;

        MyB1 := B1;
        MyB2 := B2;
        MyB3 := B3;

        OkMsg := '&Ok';
        NoMsg := '&No';
        YesMsg := '&Yes';
        CancelMsg := '&Cancel';
        HelpMsg := '&Help';

        ButtonLine := Hyt - 4;
        ButtonWidth := 8;
        ButtonZone := 0;
        Virgin := TRUE;

        {instantiate dialog box}
        IF NOT INHERITED InitCustom(X, Y,
                                    X + BoxWidth, Y + Hyt,
                                    MyColors,
                                    WinOptions,
                                    MydColors) THEN
            EXIT;

        IF NOT LineList.Init THEN
            EXIT;

        IF NOT LocalCP.Init(@DialogKeySet, DialogKeyMax) THEN BEGIN
            DispErrorDeluxe('Local command processor failed to init', ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;

        LocalCP.SetHelpProc(DisplayHelp);

        SetCommandProcessor(LocalCP);

        FullyInit := TRUE;

        {make room for headers}
        LineList.MaxWidth := MaxWord(LENGTH(Header) + 2, LENGTH(Footer) + 2);

        {make room for buttons}
        I := 0;

        IF B1 <> ctNone THEN BEGIN
            INC(I, ButtonWidth + 4);
            ButtonZone := 2;
        END;

        IF B2 <> ctNone THEN BEGIN
            INC(I, ButtonWidth + 4);
            ButtonZone := 2;
        END;

        IF B3 <> ctNone THEN BEGIN
            INC(I, ButtonWidth + 4);
            ButtonZone := 2;
        END;

        {hey! This is a dialog.  You gotta have at least one button}
        IF ButtonZone = 0 THEN BEGIN
            WRITELN('No buttons!');
            EXIT;
        END;

        {make sure the box will be wide enough for all the buttons}
        LineList.MaxWidth := MaxWord(LineList.MaxWidth, I);

        WITH wFrame, MyColors DO BEGIN
            {$IFDEF UseShadows}
            AddShadow(shBR, shSeeThru);
            {$ENDIF}

            {$IFDEF UseHotSpots}
            {add hot spot for closing the window}
            AddCustomHeader('[ ]', frTL, + 2, 0, HeaderColor, HeaderMono);
            AddCustomHeader('þ', frTL, + 3, 0, HotSpotColor, HotSpotMono);
            AddHotRegion(frTL, hsRegion3, + 3, 0, 1, 1);
            {$ENDIF}

            {$IFDEF UsingDrag}
            {add hot spot for moving the window}
            AddHotBar(frTT, MoveHotCode);
            {$ENDIF}
            AddHeader(Header, heTC);
            AddHeader(Footer, heBC);
        END;

        EnableExplosions(8);

        dgFieldOptionsOn(efAllowEscape);
        dgSecFieldOptionsOn(sefSwitchCommands);
        DialogCommands.SetHelpProc(MessageBoxDisplayHelp);

        {$IFDEF UseDragAnyway}
        {initialize DragProcessor}
        DragCommands.Init(@DialogKeySet, DialogKeyMax);
        DB.SetCommandProcessor(DragCommands);
        CustomizeCommandProcessor(DragCommands);
        {$ELSE}
        {$IFNDEF UsingDrag}
        {$IFDEF UseMouse}
        IF MouseInstalled THEN
            WITH MyColors DO BEGIN
                {activate mouse cursor}
                SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) SHL 8) +
                                BYTE($4));
                ShowMouse;

                {enable mouse support}
                DialogCommands.cpOptionsOn(cpEnableMouse);
            END;
        {$ENDIF}
        {$ENDIF}
        {$ENDIF}

        InitStatus := RawError;
        IF InitStatus <> 0 THEN
            EXIT;
        fInitCustomDeluxe := TRUE;
    END;

    {customize everything.  Use this guy if you want to create an oversized}
    {dialog that does not shrink wrap the text.}
    CONSTRUCTOR MessageBoxT.InitCustomDeluxe(Header         : STRING;
                                             B1,
                                             B2,
                                             B3             : TConfirmation;
                                             HelpItem       : WORD;
                                             CS             : ColorSet;
                                             Ds             : DialogColorSet;
                                             X, Y, BoxWidth, Hyt : BYTE;
                                             Footer         : STRING);
    BEGIN
        IF NOT fInitCustomDeluxe(Header,
                                 B1,
                                 B2,
                                 B3,
                                 HelpItem,
                                 CS,
                                 Ds,
                                 X,
                                 Y,
                                 BoxWidth,
                                 Hyt,
                                 Footer) THEN
            FAIL;
    END;

    (**************************)

    {use mostly defaults}
    CONSTRUCTOR MessageBoxT.Init(Header         : STRING;
                                 B1,
                                 B2,
                                 B3             : TConfirmation;
                                 HelpItem       : WORD);
    BEGIN
        IF NOT fInitCustomDeluxe(Header,
                                 B1,
                                 B2,
                                 B3,
                                 HelpItem,
                                 FDialogColors,
                                 dColors,
                                 2, 2, ScreenWidth - 4, ScreenHeight - 4,
                                 '') THEN
            FAIL;

    END;

    (**************************)

    {custom colors}
    CONSTRUCTOR MessageBoxT.InitCustom(Header         : STRING;
                                       B1,
                                       B2,
                                       B3             : TConfirmation;
                                       HelpItem       : WORD;
                                       CS             : ColorSet;
                                       Ds             : DialogColorSet);
    BEGIN
        IF NOT fInitCustomDeluxe(Header,
                                 B1,
                                 B2,
                                 B3,
                                 HelpItem,
                                 CS,
                                 Ds,
                                 2, 2, ScreenWidth - 4, ScreenHeight - 4,
                                 '') THEN
            FAIL;

    END;

    {--------------------}

    DESTRUCTOR MessageBoxT.Done;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        INHERITED Done;
        IF FullyInit THEN
            LineList.Done;
        LocalCP.Done;
    END;

    {--------------------}

    {add a line of text to the dialog, using current color set}
    {Just (line justification) can equal ELEFT, ECENTER or ERIGHT}
    FUNCTION MessageBoxT.AddLine(Line : STRING; Just : JustT) : BOOLEAN;
    BEGIN
        AddLine := AddLineCustom(Line, Just, ColorMono(MyColors.TextColor, MyColors.TextMono));
    END;

    {--------------------}

    {add a color customized line of text to the dialog}
    FUNCTION MessageBoxT.AddLineCustom(Line : STRING; Just : JustT; Col : BYTE) : BOOLEAN;
    VAR
        X,
        Y              : BYTE;
    BEGIN
        AddLineCustom := LineList.AddLine(TruncStr(Line, ScreenWidth - 8), Just, Col);
        WITH wFrame DO BEGIN
            X := (ScreenWidth - (LineList.MaxWidth + 2)) DIV 2;
            Y := (ScreenHeight - (LineList.Size + ButtonZone)) DIV 2;
            AdjustWindow(X, Y, X + LineList.MaxWidth + 2, Y + LineList.Size + ButtonZone);
            ButtonLine := wYH - wYL;
        END;
    END;

    {--------------------}

    FUNCTION YesNoCancelHelp(Hdr,
                             Msg            : STRING;
                             Default        : BOOLEAN;
                             Y,
                             N,
                             C,
                             HelpTopic      : LONGINT;
                             TimeoutSEC     : LONGINT;
                             TimeoutKey     : TConfirmation) : TConfirmation;
    VAR
        MBP            : MessageBoxP;
    BEGIN
        IF Default THEN
            NEW(MBP, Init(Hdr,
                          ctYes,
                          ctNo,
                          ctCancel,
                          HelpTopic))
        ELSE
            NEW(MBP, Init(Hdr,
                          ctNo,
                          ctYes,
                          ctCancel,
                          HelpTopic));

        IF MBP = NIL THEN
            EXIT;

        WITH MBP^ DO BEGIN
            InitButtonMsgs(BadMsg, N, Y, C, BadMsg);
            ChangeTimeout(TimeoutSEC * 1000, TimeoutKey);

            AddLine(Msg, ELEFT);
            Process;

            CASE GetLastCommand OF
                ccSelect :
                    YesNoCancelHelp := ctYes;
                ccDone :
                    YesNoCancelHelp := ctNo;
                ccQuit :
                    YesNoCancelHelp := ctCancel;
            END;
        END;

        DISPOSE(MBP, Done);
    END;

    {--------------------}

    FUNCTION YesNoCancel(Hdr, Msg       : STRING;
                         Default        : BOOLEAN;
                         Y,
                         N,
                         C              : LONGINT) : TConfirmation;
    BEGIN
        YesNoCancel := YesNoCancelHelp(Hdr, Msg, Default, Y, N, C, 0, - 1, ctOk);
    END;

    {---------------}

    PROCEDURE MessageBox(L1, Hdr : STRING; Y : LONGINT);
    VAR
        MBP            : MessageBoxP;
    BEGIN
        NEW(MBP, Init(Hdr,
                      ctOk,
                      ctNone,
                      ctNone,
                      0));

        IF MBP = NIL THEN
            EXIT;

        WITH MBP^ DO BEGIN
            InitButtonMsgs(BadMsg, BadMsg, Y, BadMsg, BadMsg);
            AddLine(L1, ELEFT);
            Process;
        END;


        DISPOSE(MBP, Done);
    END;

    {--------------------}

    PROCEDURE NonCriticalError(Msg : STRING; Code : WORD);
    BEGIN
        IF ((Code MOD 10000) = 8) THEN
            MessageBox('Insufficient memory', 'Error', BadMsg)
        ELSE
            MessageBox(Msg + '  The error code is ' + Long2Str(Code) + '.', 'Error', BadMsg);
    END;

    {---------------}

    PROCEDURE CriticalError(Msg : STRING; Code : WORD);
    BEGIN
        MessageBox(Msg + '  ' +
                   'The error code is ' + Long2Str(Code) + '.', 'Error!!', BadMsg);
        {RestoreVideoModeToStartup;}
        HALT;
    END;

    {---------------}

END.
    {--------------------}
    {--------------------}
