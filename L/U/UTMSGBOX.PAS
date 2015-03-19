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
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$I OPDEFINE.INC}
{$A+,B-,D+,E+,F+,G+,I-,L+,N-,O+,P-,Q-,T-,V-,X+,Y+}
UNIT utmsgbox;
INTERFACE

USES
    OpCrt,
    OpCtrl,
    OpDialog,
    OpHelp,
    OpRoot,
    OpString,
    UTJUST;

CONST
    idB1           = 0;
    idB2           = idB1 + 1;
    idB3           = idB2 + 1;


VAR
    SHP            : ScrollingHelpWindowPtr;

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
                             Cs             : ColorSet;
                                 {button colors}
                             Ds             : DialogColorSet);

                             {customize everything}
                         CONSTRUCTOR InitCustomDeluxe(
                             Header         : STRING;
                             B1,
                             B2,
                             B3             : TConfirmation;
                             HelpItem       : WORD;
                             Cs             : ColorSet;
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

                     PRIVATE
                             {stay outta here!}
                         MyColors       : ColorSet;
                         MydColors      : DialogColorSet;
                         MyHelpItem     : WORD;
                         Virgin         : BOOLEAN;
                         MyB1,
                         MyB2,
                         MyB3           : TConfirmation;
                         MsgWidth,
                         ButtonZone,
                         ButtonWidth,
                         ButtonLine     : BYTE;
                         LineList       : MessageListT;

                         PROCEDURE ProcessSelf; VIRTUAL;
                     END;


    {---------------}


IMPLEMENTATION
USES
    UERROR,
    OpCmd,
    OpCol16,
    OpEdit,
    OpField,
    OpFrame,
    OpInline,
    {$IFDEF USEMOUSE}
    OpMouse,
    {$ENDIF}
    OpWindow,
    UColors,
    UWindow;

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
                        AddTextFieldCustom(Strg, I, 2, MLP^.MyCol, MLP^.MyCol);
                    ERIGHT :
                        AddTextFieldCustom(Strg, I, wXH - wXL - LENGTH(Strg) + 1, MLP^.MyCol, MLP^.MyCol);
                    ECENTER :
                        AddTextFieldCustom(Strg, I, (2 + wXH - wXL - LENGTH(Strg)) DIV 2, MLP^.MyCol, MLP^.MyCol);
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
                    AddPushButton('&Ok',
                                  ButtonLine,
                                  2,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccDone,
                                  TRUE);
                ctYes :
                    AddPushButton('&Yes',
                                  ButtonLine,
                                  2,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccDone,
                                  TRUE);
                ctNo :
                    AddPushButton('&No',
                                  ButtonLine,
                                  2,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccQuit,
                                  TRUE);
                ELSE
                    RingBell;
            END;


            CASE MyB2 OF
                ctNone : ;
                ctCancel :
                    AddPushButton('&Cancel',
                                  ButtonLine,
                                  ((wXH - wXL) DIV 2) - (ButtonWidth DIV 2),
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccQuit,
                                  FALSE);
                ctNo :
                    AddPushButton('&No',
                                  ButtonLine,
                                  ((wXH - wXL) DIV 2) - (ButtonWidth DIV 2),
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccQuit,
                                  FALSE);
                ctYes :
                    AddPushButton('&Yes',
                                  ButtonLine,
                                  ((wXH - wXL) DIV 2) - (ButtonWidth DIV 2),
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccDone,
                                  FALSE);
                ELSE
                    RingBell;
            END;


            CASE MyB3 OF
                ctCancel :
                    AddPushButton('&Cancel',
                                  ButtonLine,
                                  (wXH - wXL) - ButtonWidth,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccQuit,
                                  FALSE);
                ctNo :
                    AddPushButton('&No',
                                  ButtonLine,
                                  (wXH - wXL) - ButtonWidth,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccQuit,
                                  FALSE);
                ctHelp :
                    AddPushButton('&Help',
                                  ButtonLine,
                                  (wXH - wXL) - ButtonWidth,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccHelp,
                                  FALSE);
                ctYes :
                    AddPushButton('&Yes',
                                  ButtonLine,
                                  (wXH - wXL) - ButtonWidth,
                                  ButtonWidth,
                                  MyHelpItem,
                                  ccDone,
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
        RingBell;
        IF SHP = NIL THEN
            EXIT;
        {$IFDEF DEBUG}
        FastWrite(Pad(Long2Str(MsgBoxHelpIndex) + ':' + Long2Str(UnitCode), 8), ScreenHeight - 1, 1, LtRedOnBlue);
        {$ENDIF}
        SHP^.SetTopic(MsgBoxHelpIndex);
        SHP^.Process;
        SHP^.ERASE;
    END;

    {--------------------}

    {customize everything.  Use this guy if you want to create an oversized}
    {dialog that does not shrink wrap the text.}
    CONSTRUCTOR MessageBoxT.InitCustomDeluxe(Header         : STRING;
                                             B1,
                                             B2,
                                             B3             : TConfirmation;
                                             HelpItem       : WORD;
                                             Cs             : ColorSet;
                                             Ds             : DialogColorSet;
                                             X, Y, BoxWidth, Hyt : BYTE;
                                             Footer         : STRING);
    CONST
        WinOptions     = wBordered + wClear;
    VAR
        I              : BYTE;
    BEGIN
        MyColors := Cs;
        MydColors := Ds;
        MyHelpItem := HelpItem;

        MyB1 := B1;
        MyB2 := B2;
        MyB3 := B3;

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
            FAIL;

        IF NOT LineList.Init THEN
            FAIL;

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
            FAIL;
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
        CustomizeCommandProcessor(DialogCommands);
        {$ENDIF}

        InitStatus := RawError;
        IF InitStatus <> 0 THEN
            FAIL;
    END;

    (**************************)

    {use mostly defaults}
    CONSTRUCTOR MessageBoxT.Init(Header         : STRING;
                                 B1,
                                 B2,
                                 B3             : TConfirmation;
                                 HelpItem       : WORD);
    VAR
        MessageBoxColors : ColorSet;
        dColors        : DialogColorSet;
    BEGIN
        GetScheme(OproDialog_Scheme, MessageBoxColors, dColors);
        IF NOT InitCustomDeluxe(Header,
                                B1,
                                B2,
                                B3,
                                HelpItem,
                                MessageBoxColors,
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
                                       Cs             : ColorSet;
                                       Ds             : DialogColorSet);
    BEGIN
        IF NOT InitCustomDeluxe(Header,
                                B1,
                                B2,
                                B3,
                                HelpItem,
                                Cs,
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
        LineList.Done;
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
        AddLineCustom := LineList.AddLine(Line, Just, Col);
        WITH wFrame DO BEGIN
            X := (ScreenWidth - (LineList.MaxWidth + 2)) DIV 2;
            Y := (ScreenHeight - (LineList.Size + ButtonZone)) DIV 2;
            AdjustWindow(X, Y, X + LineList.MaxWidth + 2, Y + LineList.Size + ButtonZone);
            ButtonLine := wYH - wYL;
        END;
    END;

    {--------------------}


BEGIN
    SHP := NIL;
END.
    {--------------------}
    {--------------------}
