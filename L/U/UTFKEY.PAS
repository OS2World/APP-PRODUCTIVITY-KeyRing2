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
* Pure OOP version of UFKEY.  Look Ma!  No globals!
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,R-,S-,V-,O+,F+,X+}

UNIT UTFkey;                      { Function key help displays }

INTERFACE
USES
    OpCmd,
    OpCrt,
    OpRoot,
    OpString;


TYPE
    KeyRec         = RECORD
                         Key,
                         Cmd            : WORD;
                         Tag            : STRING[14];
                     END;


    KeyLevelT      = (UnShift, Shift, Ctrl, Alt);
    Levels         = ARRAY[KeyLevelT] OF StringPtr;
    FKeyMgrP       = ^FKeyMgrT;
    FkeyPtr        = ^FKeyT;
    FKeyT          = OBJECT(Root)
                         CONSTRUCTOR Init(Num : WORD; Y, FKeyDepth : BYTE; MyParent : FKeyMgrP);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE Clear;
                         PROCEDURE SetKey(Level : KeyLevelT; Tag : STRING);
                         PROCEDURE Show;
                         PROCEDURE Hide;
                         PROCEDURE Push;
                         PROCEDURE Fill;
                         PROCEDURE Empty;
                         FUNCTION MouseOnKey(VAR ScanCode : WORD) : BOOLEAN;

                     PRIVATE

                         Tags           : Levels; { Tag for each function key level }
                         FkeyID         : WORD; { This function key number }
                         Covers         : POINTER; { screen area under function key box }
                         X1,
                         Y1,
                         X2,
                         Y2             : BYTE;
                         CurLevel       : KeyLevelT;
                         KeyShown       : BOOLEAN;
                         Pushed         : BOOLEAN;
                         Scan           : WORD;
                         Parent         : FKeyMgrP;
                     END;

    AllFkeys       = ARRAY[1..10] OF FkeyPtr;
    ButtonStyles   = (Bordered, Shadowed);

    FKeyMgrT       = OBJECT(Root)
                         CONSTRUCTOR Init(Y, KeyDepth : BYTE);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE SetTag(K : WORD; Level : KeyLevelT; Tag : STRING);
                         PROCEDURE SetOPTag(K : WORD; Tag : STRING);
                         PROCEDURE SetOPCTag(VAR K : KeyRec; VAR CP : CommandProcessor);
                         FUNCTION SetOPCCTag(K, ExitCmd : WORD; Tag : STRING; VAR CP : CommandProcessor) : BOOLEAN;
                         PROCEDURE PushKey(K : WORD);
                         PROCEDURE ClearFKey(K : WORD);
                         PROCEDURE ClearFKeys;
                         PROCEDURE RedrawFkeys(Level : KeyLevelT);
                         PROCEDURE HideFKeyDisplay;
                         PROCEDURE ShowFKeyDisplay;
                         PROCEDURE SetFKeyDepth(Num : BYTE);
                         FUNCTION MouseOnKey(VAR SC : WORD) : BOOLEAN;

                     PRIVATE

                         Fkeys          : AllFkeys;
                         FKeysUp,
                         Shown          : BOOLEAN;
                         ButtonStyle    : ButtonStyles;
                         FKeyDepth,
                         BoxColor,
                         IDColor,
                         TagColor,
                         STagColor,
                         ATagColor,
                         CTagColor      : BYTE;
                         Flex           : FlexAttrs;

                         PROCEDURE PaintBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
                         PROCEDURE Paint3DBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
                     END;

    (************************)

IMPLEMENTATION
USES
    Dos,
    OpDos,
    OpKey,
    OpMouse,
    OpCol16;

CONST
    AltFlag        = $08;
    CtrlFlag       = $04;
    ShiftFlag      = $03;


    (************************)

    PROCEDURE FKeyMgrT.PaintBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
    VAR
        I,
        J              : INTEGER;
    BEGIN
        HideMouse;
        IF ButtonStyle = Bordered THEN BEGIN
            FastWrite(#$DA, Y1, X1, Atr);
            FOR I := X1 + 1 TO X2 - 1 DO
                FastWrite(#$C4, Y1, I, Atr);
            FastWrite(#$BF, Y1, X2, Atr);
            FOR I := Y1 + 1 TO Y2 - 1 DO
                FastWrite(#$B3, I, X2, Atr);
            FastWrite(#$D9, Y2, X2, Atr);
            FOR I := X2 - 1 DOWNTO X1 + 1 DO
                FastWrite(#$C4, Y2, I, Atr);
            FastWrite(#$C0, Y2, X1, Atr);
            FOR I := Y2 - 1 DOWNTO Y1 + 1 DO
                FastWrite(#$B3, I, X1, Atr);
        END;

        FOR I := X1 + 1 TO X2 - 1 DO
            FOR J := Y1 + 1 TO Y2 - 1 DO
                FastWrite(Fill, J, I, Atr);
    END;

    (************************)

    PROCEDURE FKeyMgrT.Paint3DBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
    VAR
        I,
        J              : INTEGER;
    BEGIN
        HideMouse;
        IF ButtonStyle = Bordered THEN BEGIN
            FastWrite(#$DA, Y1, X1, Atr); { Top left corner }
            FOR I := X1 + 1 TO X2 - 1 DO { Top edge        }
                FastWrite(#$C4, Y1, I, Atr);
            FastWrite(#$B7, Y1, X2, Atr); { Top right corner }
            FOR I := Y1 + 1 TO Y2 - 1 DO { right edge       }
                FastWrite(#$BA, I, X2, Atr);
            FastWrite(#$BC, Y2, X2, Atr); { Bottom right corner }
            FOR I := X2 - 1 DOWNTO X1 + 1 DO { Bottom edge         }
                FastWrite(#$CD, Y2, I, Atr);
            FastWrite(#$D4, Y2, X1, Atr); { Bottom left corner  }
            FOR I := Y2 - 1 DOWNTO Y1 + 1 DO { Left edge           }
                FastWrite(#$B3, I, X1, Atr);
        END;

        IF ButtonStyle = Shadowed THEN BEGIN
            Window(X1, Y1, X2, Y2);
            TextAttr := Atr;
            ClrScr;
            Window(1, 1, 80, 25);
        END;

        FOR I := X1 + 1 TO X2 - 1 DO { Fill contents       }
            FOR J := Y1 + 1 TO Y2 - 1 DO
                FastWrite(Fill, J, I, Atr);
    END;

    {>>> FKeyT Methods --------------------------------}

    CONSTRUCTOR FKeyT.Init(Num : WORD; Y, FKeyDepth : BYTE; MyParent : FKeyMgrP);
    BEGIN
        FILLCHAR(Tags, SIZEOF(Tags), #0);
        Parent := MyParent;
        FkeyID := Num;
        X1 := ((FkeyID - 1) * 8) + 1;
        X2 := X1 + 7;
        Y1 := Y;
        Y2 := Y + FKeyDepth + 1;
        CurLevel := UnShift;
        Pushed := FALSE;
        KeyShown := FALSE;
        HideMouse;
        SaveWindow(X1, Y1, X2, Y2, TRUE, Covers);


        Clear;
        Show;
    END;

    (************************)

    PROCEDURE FKeyT.Clear;
    VAR
        I              : KeyLevelT;
    BEGIN
        FOR I := LOW(KeyLevelT) TO HIGH(KeyLevelT) DO BEGIN
            IF Tags[I] <> NIL THEN
                DisposeString(Tags[I]);
            Tags[I] := StringToHeap(CharStr(' ', 6));
        END;
    END;

    (************************)

    DESTRUCTOR FKeyT.Done;
    VAR
        I              : KeyLevelT;
    BEGIN
        HideMouse;
        RestoreWindow(X1, Y1, X2, Y2, TRUE, Covers);
        FOR I := LOW(KeyLevelT) TO HIGH(KeyLevelT) DO
            DisposeString(Tags[I]);
        KeyShown := FALSE;
    END;

    (************************)

    PROCEDURE FKeyT.SetKey(Level : KeyLevelT; Tag : STRING);
    BEGIN
        IF Tags[Level] <> NIL THEN
            DisposeString(Tags[Level]);
        Tags[Level] := StringToHeap(Tag);
    END;

    (************************)

    PROCEDURE FKeyT.Push;
    BEGIN
        HideMouse;
        WITH Parent^ DO
            PaintBox(X1, Y1, X2, Y2, BoxColor, ' ');
        Pushed := TRUE;
        Fill;
        Delay(100);
        Sound(1000);
        Delay(3);
        NOSOUND;
        Pushed := FALSE;
        Show;
    END;

    (************************)

    PROCEDURE FKeyT.Fill;
    VAR
        FID            : STRING[2];
        KeyName        : STRING[10];
        D              : INTEGER;
        BChar          : CHAR;
    BEGIN
        HideMouse;
        CASE CurLevel OF
            UnShift :
                FID := 'F';
            Shift :
                FID := 'SF';
            Alt :
                FID := 'AF';
            Ctrl :
                FID := 'CF';
        END;
        BChar := #$C4;
        IF Pushed THEN
            BChar := #$C4;
        FastWrite(PadCh(FID + Long2Str(FkeyID), BChar, 3), Y1, X1 + 1, Parent^.IDColor);
        IF POS('/', StringFromHeap(Tags[CurLevel])) = 0 THEN
            FlexWrite(^A + Center(StringFromHeap(Tags[CurLevel]), (X2 - X1) - 1) + ^A, Y1 + 1, X1 + 1, Parent^.Flex)
        ELSE BEGIN
            D := POS('/', StringFromHeap(Tags[CurLevel]));
            KeyName := Pad(COPY(StringFromHeap(Tags[CurLevel]), 1, D - 1), (X2 - X1) - 1);
            IF D = LENGTH(StringFromHeap(Tags[CurLevel])) THEN
                INSERT(^A, KeyName, 3)
            ELSE
                INSERT(^A, KeyName, 2);
            INSERT(^A, KeyName, 1);
            FlexWrite(KeyName, Y1 + 1, X1 + 1, Parent^.Flex);
            IF D < LENGTH(StringFromHeap(Tags[CurLevel])) THEN BEGIN
                KeyName := Pad(COPY(StringFromHeap(Tags[CurLevel]), D + 1, LENGTH(StringFromHeap(Tags[CurLevel])) - D),
                               (X2 - X1) - 1);
                INSERT(^A, KeyName, 2);
                INSERT(^A, KeyName, 1);
                FlexWrite(KeyName, Y1 + 2, X1 + 1, Parent^.Flex)
            END;
        END;
        IF Parent^.FKeyDepth = 4 THEN BEGIN
            FastWrite(Center(StringFromHeap(Tags[Alt]), (X2 - X1) - 1), Y1 + 2, X1 + 1, Parent^.ATagColor);
            FastWrite(Center(StringFromHeap(Tags[Shift]), (X2 - X1) - 1), Y1 + 3, X1 + 1, Parent^.STagColor);
            FastWrite(Center(StringFromHeap(Tags[Alt]), (X2 - X1) - 1), Y1 + 4, X1 + 1, Parent^.CTagColor);
        END;
        ShowMouse;
    END;

    (************************)

    PROCEDURE FKeyT.Empty;
    VAR
        Strg           : STRING;
    BEGIN
        HideMouse;
        Strg := CharStr(' ', 6);
        FastWrite(Strg, Y1 + 1, X1 + 1, Parent^.TagColor);
        WITH Parent^ DO BEGIN
            IF FKeyDepth = 4 THEN BEGIN
                FastWrite(Strg, Y1 + 2, X1 + 1, TagColor);
                FastWrite(Strg, Y1 + 3, X1 + 1, TagColor);
                FastWrite(Strg, Y1 + 4, X1 + 1, TagColor);
            END;
        END;
        ShowMouse;
    END;

    (************************)

    PROCEDURE FKeyT.Show;
    BEGIN
        HideMouse;
        IF NOT KeyShown THEN
            SaveWindow(X1, Y1, X2, Y2, FALSE, Covers);
        Parent^.Paint3DBox(X1, Y1, X2, Y2, Parent^.BoxColor, ' ');
        {    SetMouseHotSpot(x1,y1,x2,y2,$3A00+(FkeyID shl 8));}
        Fill;
        KeyShown := TRUE;
        ShowMouse;
    END;

    (************************)

    PROCEDURE FKeyT.Hide;
    BEGIN
        HideMouse;
        IF KeyShown THEN
            RestoreWindow(X1, Y1, X2, Y2, FALSE, Covers);
        ShowMouse;
        KeyShown := FALSE;
    END;

    (************************)

    FUNCTION FKeyT.MouseOnKey(VAR ScanCode : WORD) : BOOLEAN;
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

    (************************)

    CONSTRUCTOR FKeyMgrT.Init(Y, KeyDepth : BYTE);
    VAR
        K              : BYTE;
    BEGIN
        {SaveHotSpotState;}
        FKeysUp := FALSE;
        Shown := FALSE;
        FKeyDepth := KeyDepth;
        ButtonStyle := Bordered;
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

        FOR K := 1 TO 10 DO BEGIN
            NEW(Fkeys[K], Init(K, Y, FKeyDepth, @Self));
            IF Fkeys[K] = NIL THEN
                FAIL;
        END;
        FullMouseWindow;
        ShowMouse;
        FKeysUp := TRUE;
        Shown := TRUE;
    END;

    (************************)

    DESTRUCTOR FKeyMgrT.Done;
    VAR
        K              : BYTE;
    BEGIN
        FOR K := 1 TO 10 DO BEGIN
            IF Fkeys[K] <> NIL THEN
                DISPOSE(Fkeys[K], Done);
            Fkeys[K] := NIL;
        END;
        {    RestoreHotSpotState;}
        FKeysUp := FALSE;
        Shown := FALSE;
    END;

    (************************)

    PROCEDURE FKeyMgrT.SetTag(K : WORD; Level : KeyLevelT; Tag : STRING);
    BEGIN
        IF Fkeys[K] = NIL THEN BEGIN
            RingBell;
            EXIT;
        END;

        IF StringFromHeap(Fkeys[K]^.Tags[Level]) = Tag THEN
            EXIT;
        Fkeys[K]^.SetKey(Level, Tag);
        IF FKeysUp THEN BEGIN
            Fkeys[K]^.Empty;
            Fkeys[K]^.Fill;
        END;
    END;

    (************************)

    {Translate Opro key into ^$@#&*@! newsmaker keys}
    PROCEDURE FKeyMgrT.SetOPTag(K : WORD; Tag : STRING);
    BEGIN
        {I wrote a Brief macro to do the settag call code - }
        {feel free to get clever and make this a lookup table or
        something more elegant}
        CASE K OF
            OpKey.F1 :
                SetTag(1, UnShift, Tag);
            OpKey.F2 :
                SetTag(2, UnShift, Tag);
            OpKey.F3 :
                SetTag(3, UnShift, Tag);
            OpKey.F4 :
                SetTag(4, UnShift, Tag);
            OpKey.F5 :
                SetTag(5, UnShift, Tag);
            OpKey.F6 :
                SetTag(6, UnShift, Tag);
            OpKey.F7 :
                SetTag(7, UnShift, Tag);
            OpKey.F8 :
                SetTag(8, UnShift, Tag);
            OpKey.F9 :
                SetTag(9, UnShift, Tag);
            OpKey.F10 :
                SetTag(10, UnShift, Tag);
            OpKey.ShF1 :
                SetTag(1, Shift, Tag);
            OpKey.ShF2 :
                SetTag(2, Shift, Tag);
            OpKey.ShF3 :
                SetTag(3, Shift, Tag);
            OpKey.ShF4 :
                SetTag(4, Shift, Tag);
            OpKey.ShF5 :
                SetTag(5, Shift, Tag);
            OpKey.SHF6 :
                SetTag(6, Shift, Tag);
            OpKey.SHF7 :
                SetTag(7, Shift, Tag);
            OpKey.SHF8 :
                SetTag(8, Shift, Tag);
            OpKey.SHF9 :
                SetTag(9, Shift, Tag);
            OpKey.SHF10 :
                SetTag(10, Shift, Tag);
            OpKey.CtrlF1 :
                SetTag(1, Ctrl, Tag);
            OpKey.CtrlF2 :
                SetTag(2, Ctrl, Tag);
            OpKey.CtrlF3 :
                SetTag(3, Ctrl, Tag);
            OpKey.CtrlF4 :
                SetTag(4, Ctrl, Tag);
            OpKey.CtrlF5 :
                SetTag(5, Ctrl, Tag);
            OpKey.CtrlF6 :
                SetTag(6, Ctrl, Tag);
            OpKey.CtrlF7 :
                SetTag(7, Ctrl, Tag);
            OpKey.CtrlF8 :
                SetTag(8, Ctrl, Tag);
            OpKey.CtrlF9 :
                SetTag(9, Ctrl, Tag);
            OpKey.CtrlF10 :
                SetTag(10, Ctrl, Tag);
            OpKey.AltF1 :
                SetTag(1, Alt, Tag);
            OpKey.AltF2 :
                SetTag(2, Alt, Tag);
            OpKey.AltF3 :
                SetTag(3, Alt, Tag);
            OpKey.AltF4 :
                SetTag(4, Alt, Tag);
            OpKey.AltF5 :
                SetTag(5, Alt, Tag);
            OpKey.AltF6 :
                SetTag(6, Alt, Tag);
            OpKey.AltF7 :
                SetTag(7, Alt, Tag);
            OpKey.AltF8 :
                SetTag(8, Alt, Tag);
            OpKey.AltF9 :
                SetTag(9, Alt, Tag);
            OpKey.AltF10 :
                SetTag(10, Alt, Tag);
            ELSE
                EXIT;             {don't set label if not an Fkey}
        END;
    END;

    (************************)

    {translate, label and add secondary exit command to commandproc}
    {pass a KeyRec containing all the Key info}
    PROCEDURE FKeyMgrT.SetOPCTag(VAR K : KeyRec; VAR CP : CommandProcessor);
    BEGIN
        CP.AddSecondaryCommand(K.Cmd, 1, K.Key, 0);
        {if this beeps, then you probably have too many exit commands!}
        IF CP.GetLastError <> 0 THEN
            RingBell;
        SetOPTag(K.Key, K.Tag);
    END;

    (************************)

    {translate, label and add secondary exit command to commandproc}
    {use this one if you don't want to pass records}
    {Key = Opro keyconst}
    {ExitCmd = Opro exit cmd ie. ccQuit, ccUser142...}
    {CP = EntryCommands, PickCommands, Etc.}
    FUNCTION FKeyMgrT.SetOPCCTag(K, ExitCmd : WORD; Tag : STRING; VAR CP : CommandProcessor) : BOOLEAN;
    BEGIN
        SetOPCCTag := TRUE;
        CP.AddSecondaryCommand(ExitCmd, 1, K, 0);
        {if this beeps, then you probably have too many exit commands!}
        IF CP.GetLastError <> 0 THEN BEGIN
            RingBell;
            SetOPCCTag := FALSE;
        END;
        SetOPTag(K, Tag);
    END;

    (************************)

    PROCEDURE FKeyMgrT.ClearFKeys;
    VAR
        K              : BYTE;
    BEGIN
        FOR K := 1 TO 10 DO BEGIN
            Fkeys[K]^.Empty;
            Fkeys[K]^.Clear;
        END;
    END;

    (************************)

    PROCEDURE FKeyMgrT.ClearFKey(K : WORD);
    BEGIN
        Fkeys[K]^.Empty;
        Fkeys[K]^.Clear;
    END;

    (************************)

    PROCEDURE FKeyMgrT.HideFKeyDisplay;
    VAR
        K              : BYTE;
    BEGIN
        IF NOT Shown THEN
            EXIT;
        FOR K := 1 TO 10 DO
            Fkeys[K]^.Hide;
        FKeysUp := FALSE;
    END;

    (************************)

    PROCEDURE FKeyMgrT.ShowFKeyDisplay;
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
            RedrawFkeys(UnShift);
        FKeysUp := TRUE;
    END;

    (************************)

    PROCEDURE FKeyMgrT.RedrawFkeys(Level : KeyLevelT);
    VAR
        K              : BYTE;
    BEGIN
        FOR K := 1 TO 10 DO BEGIN
            Fkeys[K]^.CurLevel := Level;
            Fkeys[K]^.Show;
        END;
        ShowMouse;
    END;

    (************************)

    FUNCTION FKeyMgrT.MouseOnKey(VAR SC : WORD) : BOOLEAN;
    VAR
        K              : BYTE;
    BEGIN
        MouseOnKey := FALSE;
        FOR K := 1 TO 10 DO BEGIN
            IF Fkeys[K]^.MouseOnKey(SC) THEN BEGIN
                MouseOnKey := TRUE;
                EXIT;
            END;
        END;
    END;

    (************************)

    PROCEDURE FKeyMgrT.PushKey(K : WORD);
    BEGIN
        Fkeys[K]^.Push;
        ShowMouse;
    END;

    (************************)

    PROCEDURE FKeyMgrT.SetFKeyDepth(Num : BYTE);
    BEGIN
        FKeyDepth := Num;
    END;

END.
(************************)
(************************)

