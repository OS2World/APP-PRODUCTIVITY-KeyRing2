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
{$I OPDEFINE.INC}
{$A-,R-,S-,V-,O+,F+,X+}
UNIT UFKey;                       { Function key help displays }

INTERFACE
USES
    {$IFDEF COMET}
    CrTypes,
{$ENDIF}
    OpCmd,
    OpRoot;


TYPE
    KeyRec         = RECORD
                         Key,
                         Cmd            : WORD;
                         Tag            : STRING[6];
                     END;


    ButtonStyles   = (Bordered, Shadowed);
    KeyLevelT      = (unShift, Shift, Ctrl, Alt);

    Levels         = ARRAY[unShift..Alt] OF STRING[13];

    FKey           = OBJECT(Root)
                         Tags           : ^Levels; { Tag for each function key level }
                         FkeyID         : WORD; { This function key number }
                         Covers         : POINTER; { screen area under function key box }
                         X1, Y1,
                         X2, Y2         : BYTE;
                         CurLevel       : KeyLevelT;
                         KeyShown       : BOOLEAN;
                         Pushed         : BOOLEAN;
                         Scan           : WORD;
                         CONSTRUCTOR Init(Num : WORD; Y : BYTE);
                         DESTRUCTOR Done; virtual;
                         PROCEDURE Clear;
                         PROCEDURE SetKey(Level : KeyLevelT; Tag : STRING);
                         PROCEDURE Show;
                         PROCEDURE Hide;
                         PROCEDURE Push;
                         PROCEDURE Fill;
                         PROCEDURE Empty;
                         {$IFDEF USEMOUSE}
                         FUNCTION MouseOnKey(VAR ScanCode : WORD) : BOOLEAN;
                         {$ENDIF}
                     END;

    FkeyPtr        = ^FKey;
    AllFkeys       = ARRAY[1..10] OF FkeyPtr;

CONST
    FKeysUp        : BOOLEAN = FALSE;
    Shown          : BOOLEAN = FALSE;
    ButtonStyle    : ButtonStyles = Bordered;

CONST
    {$IFDEF COMET}
    FKeyDepth      : BYTE = 3;
{$ELSE}
    FKeyDepth      : BYTE = 2;
    {$ENDIF}

VAR
    FKeys          : AllFkeys;

PROCEDURE OpenFKeyDisplay(Y : BYTE);
PROCEDURE CloseFKeyDisplay;
PROCEDURE SetTag(Key : WORD; Level : KeyLevelT; Tag : STRING);
PROCEDURE SetOPTag(Key : WORD; Tag : STRING);
PROCEDURE SetOPCTag(VAR K : KeyRec; VAR CP : CommandProcessor);
PROCEDURE SetOPCCTag(Key, ExitCmd : WORD; Tag : STRING; VAR CP : CommandProcessor);
PROCEDURE PushKey(Key : WORD);
PROCEDURE ClearFKey(Key : WORD);
PROCEDURE ClearFKeys;
PROCEDURE RedrawFkeys(Level : KeyLevelT);
PROCEDURE HideFKeyDisplay;
PROCEDURE ShowFKeyDisplay;

    {--------}


IMPLEMENTATION

USES
    Dos,
    OpCrt,
    OpDos,
    OpKey,
    {$IFDEF USEMOUSE}
    OpMouse,
    {$ENDIF}
    OpString,
    {$IFDEF COMET}
    MsgMgr,
{$ELSE}
    UGLOBAL,
    ULanguag,
    UMsg,
    {$ENDIF}
    OpCol16;

CONST
    AltFlag        = $08;
    CtrlFlag       = $04;
    ShiftFlag      = $03;


VAR
    Key            : WORD;
    BoxColor       : BYTE;
    IDColor        : BYTE;
    TagColor       : BYTE;
    STagColor      : BYTE;
    ATagColor      : BYTE;
    CTagColor      : BYTE;
    Flex           : FlexAttrs;

    PROCEDURE PaintBox(X1, Y1, X2, Y2 : INTEGER; ATR : BYTE; Fill : CHAR);
    VAR
        I,
        J              : INTEGER;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        IF ButtonStyle = Bordered THEN BEGIN
            FastWrite(#$DA, Y1, X1, ATR);
            FOR I := X1 + 1 TO X2 - 1 DO
                FastWrite(#$C4, Y1, I, ATR);
            FastWrite(#$BF, Y1, X2, ATR);
            FOR I := Y1 + 1 TO Y2 - 1 DO
                FastWrite(#$B3, I, X2, ATR);
            FastWrite(#$D9, Y2, X2, ATR);
            FOR I := X2 - 1 DOWNTO X1 + 1 DO
                FastWrite(#$C4, Y2, I, ATR);
            FastWrite(#$C0, Y2, X1, ATR);
            FOR I := Y2 - 1 DOWNTO Y1 + 1 DO
                FastWrite(#$B3, I, X1, ATR);
        END;

        FOR I := X1 + 1 TO X2 - 1 DO
            FOR J := Y1 + 1 TO Y2 - 1 DO
                FastWrite(Fill, J, I, ATR);
    END;

    PROCEDURE Paint3DBox(X1, Y1, X2, Y2 : INTEGER; ATR : BYTE; Fill : CHAR);
    VAR
        I,
        J              : INTEGER;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        IF ButtonStyle = Bordered THEN BEGIN
            FastWrite(#$DA, Y1, X1, ATR); { Top left corner }
            FOR I := X1 + 1 TO X2 - 1 DO { Top edge        }
                FastWrite(#$C4, Y1, I, ATR);
            FastWrite(#$B7, Y1, X2, ATR); { Top right corner }
            FOR I := Y1 + 1 TO Y2 - 1 DO { right edge       }
                FastWrite(#$BA, I, X2, ATR);
            FastWrite(#$BC, Y2, X2, ATR); { Bottom right corner }
            FOR I := X2 - 1 DOWNTO X1 + 1 DO { Bottom edge         }
                FastWrite(#$CD, Y2, I, ATR);
            FastWrite(#$D4, Y2, X1, ATR); { Bottom left corner  }
            FOR I := Y2 - 1 DOWNTO Y1 + 1 DO { Left edge           }
                FastWrite(#$B3, I, X1, ATR);
        END;

        IF ButtonStyle = Shadowed THEN BEGIN
            WINDOW(X1, Y1, X2, Y2);
            TextAttr := ATR;
            ClrScr;
            WINDOW(1, 1, 80, 25);
        END;

        FOR I := X1 + 1 TO X2 - 1 DO { Fill contents       }
            FOR J := Y1 + 1 TO Y2 - 1 DO
                FastWrite(Fill, J, I, ATR);
    END;

    {>>> FKEY Methods --------------------------------}

    CONSTRUCTOR FKey.Init(Num : WORD; Y : BYTE);
    BEGIN
        NEW(Tags);
        IF Tags = NIL THEN
            FAIL;
        FkeyID := Num;
        X1 := ((FkeyID - 1) * 8) + 1;
        X2 := X1 + 7;
        Y1 := Y;
        Y2 := Y + FKeyDepth;
        CurLevel := unShift;
        Pushed := FALSE;
        KeyShown := FALSE;
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        SaveWindow(X1, Y1, X2, Y2, TRUE, Covers);

        BoxColor := ColorMono(BlackOnLtGray, BlackOnLtGray);
        IDColor := ColorMono(BlackOnLtGray, BlackOnLtGray);
        TagColor := ColorMono(RedOnLtGray, BlackOnLtGray);
        ATagColor := ColorMono(RedOnLtGray, BlackOnLtGray);
        STagColor := ColorMono(RedOnLtGray, BlackOnLtGray);
        CTagColor := ColorMono(RedOnLtGray, BlackOnLtGray);
        Flex[0] := ColorMono(BlackOnLtGray, BlackOnLtGray);
        Flex[1] := ColorMono(RedOnLtGray, BlackOnLtGray);
        Flex[2] := ColorMono(WhiteOnLtGray, BlackOnLtGray);
        Flex[3] := ColorMono(BlueOnLtGray, BlackOnLtGray);

        Clear;
        Show;
    END;

    PROCEDURE FKey.Clear;
    VAR
        I              : KeyLevelT;
    BEGIN
        FOR I := LOW(KeyLevelT) TO HIGH(KeyLevelT) DO
            Tags^[I] := CharStr(' ', 6);
    END;

    DESTRUCTOR FKey.Done;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        RestoreWindow(X1, Y1, X2, Y2, TRUE, Covers);
        IF Tags <> NIL THEN
            DISPOSE(Tags);
        KeyShown := FALSE;
    END;

    PROCEDURE FKey.SetKey(Level : KeyLevelT; Tag : STRING);
    BEGIN
        Tags^[Level] := Tag;
    END;

    PROCEDURE FKey.Push;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        PaintBox(X1, Y1, X2, Y2, BoxColor, ' ');
        Pushed := TRUE;
        Fill;
        Delay(100);
        Sound(100);
        Delay(5);
        NOSOUND;
        Pushed := FALSE;
        Show;
    END;

    PROCEDURE FKey.Fill;
    VAR
        FID            : STRING[2];
        KeyName        : STRING[10];
        D              : INTEGER;
        BChar          : CHAR;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        CASE CurLevel OF
            unShift : FID := 'F';
            Shift : FID := 'SF';
            Alt : FID := 'AF';
            Ctrl : FID := 'CF';
        END;
        BChar := #$C4;
        IF Pushed THEN
            BChar := #$C4;
        FastWrite(PadCh(FID + Long2Str(FkeyID), BChar, 3), Y1, X1 + 1, IDColor);
        IF POS('/', Tags^[CurLevel]) = 0 THEN
            FlexWrite(^A + Center(Tags^[CurLevel], (X2 - X1) - 1) + ^A, Y1 + 1, X1 + 1, Flex)
        ELSE BEGIN
            D := POS('/', Tags^[CurLevel]);
            KeyName := Pad(COPY(Tags^[CurLevel], 1, D - 1), (X2 - X1) - 1);
            IF D = LENGTH(Tags^[CurLevel]) THEN
                INSERT(^A, KeyName, 3)
            ELSE
                INSERT(^A, KeyName, 2);
            INSERT(^A, KeyName, 1);
            FlexWrite(KeyName, Y1 + 1, X1 + 1, Flex);
            IF D < LENGTH(Tags^[CurLevel]) THEN BEGIN
                KeyName := Pad(COPY(Tags^[CurLevel], D + 1, LENGTH(Tags^[CurLevel]) - D),
                               (X2 - X1) - 1);
                INSERT(^A, KeyName, 2);
                INSERT(^A, KeyName, 1);
                FlexWrite(KeyName, Y1 + 2, X1 + 1, Flex)
            END;
        END;
        IF FKeyDepth = 5 THEN BEGIN
            FastWrite(Center(Tags^[Alt], (X2 - X1) - 1), Y1 + 2, X1 + 1, ATagColor);
            FastWrite(Center(Tags^[Shift], (X2 - X1) - 1), Y1 + 3, X1 + 1, STagColor);
            FastWrite(Center(Tags^[Alt], (X2 - X1) - 1), Y1 + 4, X1 + 1, CTagColor);
        END;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    PROCEDURE FKey.Empty;
    VAR
        Strg           : STRING;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        Strg := CharStr(' ', 6);
        FastWrite(Strg, Y1 + 1, X1 + 1, TagColor);
        IF FKeyDepth = 5 THEN BEGIN
            FastWrite(Strg, Y1 + 2, X1 + 1, TagColor);
            FastWrite(Strg, Y1 + 3, X1 + 1, TagColor);
            FastWrite(Strg, Y1 + 4, X1 + 1, TagColor);
        END;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    PROCEDURE FKey.Show;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        IF NOT KeyShown THEN
            SaveWindow(X1, Y1, X2, Y2, FALSE, Covers);
        Paint3DBox(X1, Y1, X2, Y2, BoxColor, ' ');
        {    SetMouseHotSpot(x1,y1,x2,y2,$3A00+(FkeyID shl 8));}
        Fill;
        KeyShown := TRUE;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    PROCEDURE FKey.Hide;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        IF KeyShown THEN
            RestoreWindow(X1, Y1, X2, Y2, FALSE, Covers);
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
        KeyShown := FALSE;
    END;

    {$IFDEF USEMOUSE}

    FUNCTION FKey.MouseOnKey(VAR ScanCode : WORD) : BOOLEAN;
    VAR
        Base           : BYTE;
        Kbd            : BYTE;
    BEGIN
        MouseOnKey := FALSE;
        IF (MouseWhereX IN [X1..X2]) AND (MouseWhereY IN [Y1..Y2]) THEN BEGIN
            MouseOnKey := TRUE;
            Base := $3B;
            Kbd := KbdFlags AND $F;
            IF Kbd AND ShiftFlag <> 0 THEN
                Base := $54;
            IF Kbd AND CtrlFlag <> 0 THEN
                Base := $5E;
            IF Kbd AND AltFlag <> 0 THEN
                Base := $68;
            ScanCode := (Base + (FkeyID - 1)) SHL 8;
        END;
    END;
    {$ENDIF}

    {>>> NON-METHOD Procedures ---------------------------}

    PROCEDURE OpenFKeyDisplay(Y : BYTE);
    BEGIN
        {SaveHotSpotState;}
        FOR Key := 1 TO 10 DO
            NEW(FKeys[Key], Init(Key, Y));
        {$IFDEF USEMOUSE}
        FullMouseWindow;
        ShowMouse;
        {$ENDIF}
        FKeysUp := TRUE;
        Shown := TRUE;
        {$IFDEF COMET}
        FKeyDepth := 3;
        {$ELSE}
        FKeyDepth := 2;
        {$ENDIF}
    END;

    PROCEDURE CloseFKeyDisplay;
    BEGIN
        FOR Key := 1 TO 10 DO
            DISPOSE(FKeys[Key], Done);
        {    RestoreHotSpotState;}
        FKeysUp := FALSE;
        Shown := FALSE;
    END;

    PROCEDURE SetTag(Key : WORD; Level : KeyLevelT; Tag : STRING);
    BEGIN
        IF FKeys[Key]^.Tags^[Level] = Tag THEN
            EXIT;
        FKeys[Key]^.SetKey(Level, Tag);
        IF FKeysUp THEN BEGIN
            FKeys[Key]^.Empty;
            FKeys[Key]^.Fill;
        END;
    END;

    {Translate Opro key into ^$@#&*@! newsmaker keys}
    PROCEDURE SetOPTag(Key : WORD; Tag : STRING);
    BEGIN
        {I wrote a Brief macro to do the settag call code - }
        {feel free to get clever and make this a lookup table or
        something more elegant}
        CASE Key OF
            OpKey.F1 : SetTag(1, unShift, Tag);
            OpKey.F2 : SetTag(2, unShift, Tag);
            OpKey.F3 : SetTag(3, unShift, Tag);
            OpKey.F4 : SetTag(4, unShift, Tag);
            OpKey.F5 : SetTag(5, unShift, Tag);
            OpKey.F6 : SetTag(6, unShift, Tag);
            OpKey.F7 : SetTag(7, unShift, Tag);
            OpKey.F8 : SetTag(8, unShift, Tag);
            OpKey.F9 : SetTag(9, unShift, Tag);
            OpKey.F10 : SetTag(10, unShift, Tag);
            OpKey.ShF1 : SetTag(1, Shift, Tag);
            OpKey.ShF2 : SetTag(2, Shift, Tag);
            OpKey.ShF3 : SetTag(3, Shift, Tag);
            OpKey.ShF4 : SetTag(4, Shift, Tag);
            OpKey.ShF5 : SetTag(5, Shift, Tag);
            OpKey.ShF6 : SetTag(6, Shift, Tag);
            OpKey.ShF7 : SetTag(7, Shift, Tag);
            OpKey.ShF8 : SetTag(8, Shift, Tag);
            OpKey.ShF9 : SetTag(9, Shift, Tag);
            OpKey.ShF10 : SetTag(10, Shift, Tag);
            OpKey.CtrlF1 : SetTag(1, Ctrl, Tag);
            OpKey.CtrlF2 : SetTag(2, Ctrl, Tag);
            OpKey.CtrlF3 : SetTag(3, Ctrl, Tag);
            OpKey.CtrlF4 : SetTag(4, Ctrl, Tag);
            OpKey.CtrlF5 : SetTag(5, Ctrl, Tag);
            OpKey.CtrlF6 : SetTag(6, Ctrl, Tag);
            OpKey.CtrlF7 : SetTag(7, Ctrl, Tag);
            OpKey.CtrlF8 : SetTag(8, Ctrl, Tag);
            OpKey.CtrlF9 : SetTag(9, Ctrl, Tag);
            OpKey.CtrlF10 : SetTag(10, Ctrl, Tag);
            OpKey.AltF1 : SetTag(1, Alt, Tag);
            OpKey.AltF2 : SetTag(2, Alt, Tag);
            OpKey.AltF3 : SetTag(3, Alt, Tag);
            OpKey.AltF4 : SetTag(4, Alt, Tag);
            OpKey.AltF5 : SetTag(5, Alt, Tag);
            OpKey.AltF6 : SetTag(6, Alt, Tag);
            OpKey.AltF7 : SetTag(7, Alt, Tag);
            OpKey.AltF8 : SetTag(8, Alt, Tag);
            OpKey.AltF9 : SetTag(9, Alt, Tag);
            OpKey.AltF10 : SetTag(10, Alt, Tag);
            ELSE
                EXIT;             {don't set label if not an Fkey}
        END;
    END;

    {translate, label and add secondary exit command to commandproc}
    {pass a KeyRec containing all the Key info}
    PROCEDURE SetOPCTag(VAR K : KeyRec; VAR CP : CommandProcessor);
    BEGIN
        CP.AddSecondaryCommand(K.Cmd, 1, K.Key, 0);
        {if this beeps, then you have too many exit commands!}
        IF CP.GetLastError <> 0 THEN
            RingBell;
        SetOPTag(K.Key, K.Tag);
    END;

    {translate, label and add secondary exit command to commandproc}
    {use this one if you don't want to pass records}
    {Key = Opro keyconst}
    {ExitCmd = Opro exit cmd ie. ccQuit, ccUser142...}
    {CP = EntryCommands, PickCommands, Etc.}
    PROCEDURE SetOPCCTag(Key, ExitCmd : WORD; Tag : STRING; VAR CP : CommandProcessor);
    BEGIN
        CP.AddSecondaryCommand(ExitCmd, 1, Key, 0);
        {if this beeps, then you have too many exit commands!}
        IF CP.GetLastError <> 0 THEN
            RingBell;
        SetOPTag(Key, Tag);
    END;

    PROCEDURE ClearFKeys;
    BEGIN
        FOR Key := 1 TO 10 DO BEGIN
            FKeys[Key]^.Empty;
            FKeys[Key]^.Clear;
        END;
    END;

    PROCEDURE ClearFKey(Key : WORD);
    BEGIN
        FKeys[Key]^.Empty;
        FKeys[Key]^.Clear;
    END;

    PROCEDURE HideFKeyDisplay;
    BEGIN
        IF NOT Shown THEN
            EXIT;
        FOR Key := 1 TO 10 DO
            FKeys[Key]^.Hide;
        FKeysUp := FALSE;
    END;

    PROCEDURE ShowFKeyDisplay;
    VAR
        Kbd            : BYTE;
    BEGIN
        IF NOT Shown THEN
            EXIT;
        Kbd := KbdFlags AND $F;
        IF (Kbd AND ShiftFlag) <> 0 THEN
            RedrawFkeys(Shift);
        IF (Kbd AND AltFlag) <> 0 THEN
            RedrawFkeys(Alt);
        IF (Kbd AND CtrlFlag) <> 0 THEN
            RedrawFkeys(Ctrl);
        IF Kbd = 0 THEN
            RedrawFkeys(unShift);
        FKeysUp := TRUE;
    END;

    PROCEDURE RedrawFkeys(Level : KeyLevelT);
    BEGIN
        FOR Key := 1 TO 10 DO BEGIN
            FKeys[Key]^.CurLevel := Level;
            FKeys[Key]^.Show;
        END;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    PROCEDURE PushKey(Key : WORD);
    BEGIN
        FKeys[Key]^.Push;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    PROCEDURE SetFKeyDepth(Num : BYTE);
    BEGIN
        FKeyDepth := Num;
    END;

END.
