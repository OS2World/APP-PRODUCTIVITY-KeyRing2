(* Version:  ~version~
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
* Function key addon to Opro command processor.  Automatically manages
* a bank of function key labels, mouse support, and extended command tables.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************)

{$I OPDEFINE.INC}
{$A-,D+,L+,R-,S-,V-,O+,F+,X+}

UNIT DGFkey;                      { Function key help displays }
INTERFACE
USES
    DGCMD,
    OpCmd,
    OpCRT,
    OpRoot,
    OpString
    {$IFDEF VirtualPascal}
    ,USE32
    {$ENDIF VirtualPascal}
    ;

CONST
    AltFlag        = $08;
    CtrlFlag       = $04;
    ShiftFlag      = $03;


TYPE
    TKeyRec        = RECORD
                         Key,
                         Cmd            : WORD;
                         Tag            : STRING[14];
                     END;


    TKeyLevel      = (KeyModUnShift, KeyModShift, KeyModCtrl, KeyModAlt);
    TLevels        = ARRAY[TKeyLevel] OF StringPtr;
    PFKeyMgr       = ^TFKeyMgr;
    PFkey          = ^TFKey;
    TFKey          = OBJECT(ROOT)
                         CONSTRUCTOR Init(Num : WORD; KeyRowBot, FKeyDepth : BYTE; MyParent : PFKeyMgr);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE Clear;
                         PROCEDURE SetKey(Level : TKeyLevel; Tag : STRING);
                         PROCEDURE Show;
                         PROCEDURE Hide;
                         PROCEDURE PUSH;
                         PROCEDURE Fill;
                         PROCEDURE Empty;
                             {$IFDEF USEMOUSE}
                         FUNCTION MouseOnKey(VAR ScanCode : WORD) : BOOLEAN;
                             {$ENDIF}
                     PRIVATE
                         Tags           : TLevels; { Tag for each function key level }
                         FkeyID         : WORD; { This function key number }
                         Covers         : POINTER; { screen area under function key box }
                         X1,
                         Y1,
                         X2,
                         Y2             : BYTE;
                         CurLevel       : TKeyLevel;
                         KeyShown       : BOOLEAN;
                         Pushed         : BOOLEAN;
                         Scan           : WORD;
                         Parent         : PFKeyMgr;
                     END;

    AllFkeys       = ARRAY[1..10] OF PFkey;
    ButtonStyles   = (Bordered, Shadowed);

    TFKeyMgr       = OBJECT(TDGUCommandProcessor)
                         MouseWasPressed : BOOLEAN;
                         ScanPending,
                         LastMouseKeyWord : WORD;
                         FKeys          : AllFkeys;

                         CONSTRUCTOR Init(KeysPtr        : CmdTablePtr;
                                          MaxIndex       : WORD;
                                          KeyRowBot,
                                          KeyDepth       : BYTE);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE SetTag(K : WORD; Level : TKeyLevel; Tag : STRING);
                         PROCEDURE SetOPTag(K : WORD; Tag : STRING);
                         PROCEDURE AddExitKeyR(VAR K : TKeyRec);
                         FUNCTION AddExitKey(K, ExitCmd : WORD; Tag : STRING) : BOOLEAN;
                         PROCEDURE PushKey(K : WORD);
                         PROCEDURE ClearFKey(K : WORD);
                         PROCEDURE ClearFKeys;
                         PROCEDURE RedrawFkeys(Level : TKeyLevel);
                         PROCEDURE HideFKeyDisplay;
                         PROCEDURE ShowFKeyDisplay;
                         PROCEDURE SetFKeyDepth(Num : BYTE);
                             {$IFDEF USEMOUSE}
                         FUNCTION MouseOnKey(VAR SC : WORD) : BOOLEAN;
                             {$ENDIF}
                         FUNCTION cpKeyPressed : BOOLEAN; VIRTUAL;
                         FUNCTION cpGetKey : WORD; VIRTUAL;
                         FUNCTION cpGetKeyNoWait : WORD;
                         FUNCTION DGUReadKeyOrButton : WORD;
                         FUNCTION DGUReadKeyword : WORD;
                         PROCEDURE UserHook1; VIRTUAL;
                         PROCEDURE UserHook2; VIRTUAL;
                     PRIVATE

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
                         MyMaxIndex     : WORD;
                         CTP            : CmdTablePtr;

                         PROCEDURE PaintBox(X1, Y1, X2, Y2 : INTEGER; ATR : BYTE; Fill : CHAR);
                         PROCEDURE Paint3DBox(X1, Y1, X2, Y2 : INTEGER; ATR : BYTE; Fill : CHAR);
                     END;

    (************************)

IMPLEMENTATION
USES
    Dos,
    KERROR,
    OpDos,
    OpKey,
    {$IFDEF USEMOUSE}
    OpMouse,
    {$ENDIF}
    OpCol16
    {$IFDEF VirtualPascal}
    ,OS2BASE
    {$ENDIF VirtualPascal}
    ;

    (************************)

    FUNCTION TFKeyMgr.DGUReadKeyOrButton : WORD;
    BEGIN
        IF ScanPending <> 0 THEN
            DGUReadKeyOrButton := ScanPending
        ELSE
            DGUReadKeyOrButton := ReadKeyOrButton;
        ScanPending := 0;
    END;

    (************************)

    FUNCTION TFKeyMgr.DGUReadKeyword : WORD;
    BEGIN
        IF ScanPending <> 0 THEN
            DGUReadKeyword := ScanPending
        ELSE
            DGUReadKeyword := readkeyword;
        ScanPending := 0;
    END;

    (************************)

    FUNCTION TFKeyMgr.cpGetKey : WORD;
    VAR
        Scan,
        I              : WORD;
    BEGIN
        REPEAT
            IF cpKeyPressed THEN
                BREAK;
        UNTIL FALSE;
        IF MouseWasPressed THEN BEGIN
            cpGetKey := LastMouseKeyWord;
            LastMouseKeyWord := 0;
            MouseWasPressed := FALSE;
            EXIT;
        END;

        {$IFDEF USEMOUSE}
        cpGetKey := DGUReadKeyOrButton;
        {$ELSE}
        cpGetKey := DGUReadKeyword;
        {$ENDIF}
    END;

    {-----------}

    FUNCTION TFKeyMgr.cpGetKeyNoWait : WORD;
    BEGIN
        IF MouseWasPressed THEN BEGIN
            cpGetKeyNoWait := LastMouseKeyWord;
            LastMouseKeyWord := 0;
            MouseWasPressed := FALSE;
            EXIT;
        END;

        {$IFDEF USEMOUSE}
        cpGetKeyNoWait := DGUReadKeyOrButton;
        {$ELSE}
        cpGetKeyNoWait := DGUReadKeyword;
        {$ENDIF}
    END;

    {-----------}

    PROCEDURE TFKeyMgr.UserHook1;
    BEGIN
        {do nothing - you must override this}
    END;

    {-----------}

    PROCEDURE TFKeyMgr.UserHook2;
    BEGIN
        {do nothing - you must override this}
    END;

    {-----------}

    FUNCTION TFKeyMgr.cpKeyPressed : BOOLEAN;
    VAR
        Prs            : BOOLEAN;
        Scan,
        I,
        Kbd            : WORD;
    CONST
        LastFlg        : WORD = 0;
    BEGIN
        cpKeyPressed := FALSE;

        CurrentClockProc;
        UserHook1;
        UserHook2;

        Kbd := KbdFlags AND $F;

        IF Kbd <> LastFlg THEN BEGIN
            IF (Kbd AND ShiftFlag) <> 0 THEN
                RedrawFkeys(KeyModShift);
            IF (Kbd AND AltFlag) <> 0 THEN
                RedrawFkeys(KeyModAlt);
            IF (Kbd AND CtrlFlag) <> 0 THEN
                RedrawFkeys(KeyModCtrl);
            IF Kbd = 0 THEN
                RedrawFkeys(KeyModUnShift);
            LastFlg := Kbd;
        END;

        MouseWasPressed := FALSE;
        {$IFDEF USEMOUSE}
        IF MousePressed THEN BEGIN
            WaitForButtonRelease := TRUE;
            LastMouseKeyWord := MouseKeyword;
            IF LastMouseKeyWord = MouseLft THEN
                FOR I := 1 TO 10 DO
                    IF FKeys[I]^.MouseOnKey(Scan) THEN BEGIN
                        ScanPending := Scan;
                        {$IFNDEF VirtualPascal}
                        StuffKey(Scan);
                        {$ENDIF }
                        EXIT;
                    END;
            cpKeyPressed := TRUE; {mouse clicked, but not on Fkey}
            MouseWasPressed := TRUE;
            EXIT;
        END;
        {$ENDIF}

        {$IFDEF USEMOUSE}
        Prs := KeyOrButtonPressed OR (ScanPending <> 0);
        {$ELSE}
        Prs := KeyPressed or (ScanPending <> 0);
        {$ENDIF}

        IF NOT Prs THEN
            {$IFNDEF VirtualPascal}
            INLINE($CD / $28);    { Allow TSRs to pop up }
        {$ELSE}
            DosSleep(50);
            {$ENDIF}

        cpKeyPressed := Prs;
    END;

    (************************)

    PROCEDURE TFKeyMgr.PaintBox(X1, Y1, X2, Y2 : INTEGER; ATR : BYTE; Fill : CHAR);
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

    (************************)

    PROCEDURE TFKeyMgr.Paint3DBox(X1, Y1, X2, Y2 : INTEGER; ATR : BYTE; Fill : CHAR);
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

    {>>> TFKey Methods --------------------------------}

    CONSTRUCTOR TFKey.Init(Num : WORD; KeyRowBot, FKeyDepth : BYTE; MyParent : PFKeyMgr);
    BEGIN
        FILLCHAR(Tags, SIZEOF(Tags), #0);
        Parent := MyParent;
        FkeyID := Num;
        X1 := ((FkeyID - 1) * 8) + 1;
        X2 := X1 + 7;
        Y1 := KeyRowBot - FKeyDepth - 1;
        Y2 := KeyRowBot;
        CurLevel := KeyModUnShift;
        Pushed := FALSE;
        KeyShown := FALSE;
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        SaveWindow(X1, Y1, X2, Y2, TRUE, Covers);
        CurrentClockProc := TpUpdateClock;

        Clear;
        Show;
    END;

    (************************)

    PROCEDURE TFKey.Clear;
    VAR
        I              : TKeyLevel;
    BEGIN
        FOR I := LOW(TKeyLevel) TO HIGH(TKeyLevel) DO BEGIN
            IF Tags[I] <> NIL THEN
                DisposeString(Tags[I]);
            Tags[I] := StringToHeap(CharStr(' ', 6));
        END;
    END;

    (************************)

    DESTRUCTOR TFKey.Done;
    VAR
        I              : TKeyLevel;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        RestoreWindow(X1, Y1, X2, Y2, TRUE, Covers);
        FOR I := LOW(TKeyLevel) TO HIGH(TKeyLevel) DO
            DisposeString(Tags[I]);
        KeyShown := FALSE;
    END;

    (************************)

    PROCEDURE TFKey.SetKey(Level : TKeyLevel; Tag : STRING);
    BEGIN
        IF Tags[Level] <> NIL THEN
            DisposeString(Tags[Level]);
        Tags[Level] := StringToHeap(Tag);
    END;

    (************************)

    PROCEDURE TFKey.PUSH;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        WITH Parent^ DO
            PaintBox(X1, Y1, X2, Y2, BoxColor, ' ');
        Pushed := TRUE;
        Fill;
        {$IFNDEF VirtualPascal}
        Delay(100);
        Sound(1000);
        Delay(3);
        NOSOUND;
        {$ELSE}
        DosSleep(100);
        PlaySound(1000,3);
        {$ENDIF VirtualPascal}
        Pushed := FALSE;
        Show;
    END;

    (************************)

    PROCEDURE TFKey.Fill;
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
            KeyModUnShift :
                FID := 'F';
            KeyModShift :
                FID := 'SF';
            KeyModAlt :
                FID := 'AF';
            KeyModCtrl :
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
            FastWrite(Center(StringFromHeap(Tags[KeyModAlt]), (X2 - X1) - 1), Y1 + 2, X1 + 1, Parent^.ATagColor);
            FastWrite(Center(StringFromHeap(Tags[KeyModShift]), (X2 - X1) - 1), Y1 + 3, X1 + 1, Parent^.STagColor);
            FastWrite(Center(StringFromHeap(Tags[KeyModAlt]), (X2 - X1) - 1), Y1 + 4, X1 + 1, Parent^.CTagColor);
        END;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    (************************)

    PROCEDURE TFKey.Empty;
    VAR
        Strg           : STRING;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        Strg := CharStr(' ', 6);
        FastWrite(Strg, Y1 + 1, X1 + 1, Parent^.TagColor);
        WITH Parent^ DO BEGIN
            IF FKeyDepth = 4 THEN BEGIN
                FastWrite(Strg, Y1 + 2, X1 + 1, TagColor);
                FastWrite(Strg, Y1 + 3, X1 + 1, TagColor);
                FastWrite(Strg, Y1 + 4, X1 + 1, TagColor);
            END;
        END;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    (************************)

    PROCEDURE TFKey.Show;
    BEGIN
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        IF NOT KeyShown THEN
            SaveWindow(X1, Y1, X2, Y2, FALSE, Covers);
        Parent^.Paint3DBox(X1, Y1, X2, Y2, Parent^.BoxColor, ' ');
        {    SetMouseHotSpot(x1,y1,x2,y2,$3A00+(FkeyID shl 8));}
        Fill;
        KeyShown := TRUE;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    (************************)

    PROCEDURE TFKey.Hide;
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

    (************************)

    {$IFDEF USEMOUSE}
    FUNCTION TFKey.MouseOnKey(VAR ScanCode : WORD) : BOOLEAN;
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

    (************************)

    CONSTRUCTOR TFKeyMgr.Init(KeysPtr        : CmdTablePtr;
                              MaxIndex       : WORD;
                              KeyRowBot,
                              KeyDepth       : BYTE);
    VAR
        K              : BYTE;
    BEGIN
        IF NOT INHERITED Init(KeysPtr, MaxIndex) THEN
            FAIL;
        IF NOT GetMemCheck(CTP, MaxIndex) THEN BEGIN
            INHERITED Done;
            FAIL;
        END;

        MyMaxIndex := MaxIndex;
        ScanPending := 0;

        FILLCHAR(CTP^, MaxIndex, #0);

        SetSecondaryKeyPtr(CTP, MaxIndex);
        cpOptionsOn(cpSwitchPriority);
        MouseWasPressed := FALSE;

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
            NEW(FKeys[K], Init(K, KeyRowBot, FKeyDepth, @Self));
            IF FKeys[K] = NIL THEN
                FAIL;
        END;
        {$IFDEF USEMOUSE}
        cpOptionsOn(cpEnableMouse);
        FullMouseWindow;
        ShowMouse;
        {$ENDIF}
        FKeysUp := TRUE;
        Shown := TRUE;
    END;

    (************************)

    DESTRUCTOR TFKeyMgr.Done;
    VAR
        K              : BYTE;
    BEGIN
        FOR K := 1 TO 10 DO BEGIN
            IF FKeys[K] <> NIL THEN
                DISPOSE(FKeys[K], Done);
            FKeys[K] := NIL;
        END;
        {    RestoreHotSpotState;}
        FKeysUp := FALSE;
        Shown := FALSE;
        FREEMEM(CTP, MyMaxIndex);
        INHERITED Done;
    END;

    (************************)

    PROCEDURE TFKeyMgr.SetTag(K : WORD; Level : TKeyLevel; Tag : STRING);
    BEGIN
        IF FKeys[K] = NIL THEN BEGIN
            RingBell;
            EXIT;
        END;

        IF StringFromHeap(FKeys[K]^.Tags[Level]) = Tag THEN
            EXIT;
        FKeys[K]^.SetKey(Level, Tag);
        IF FKeysUp THEN BEGIN
            FKeys[K]^.Empty;
            FKeys[K]^.Fill;
        END;
    END;

    (************************)

    {Translate Opro key into ^$@#&*@! newsmaker keys}
    PROCEDURE TFKeyMgr.SetOPTag(K : WORD; Tag : STRING);
    BEGIN
        {I wrote a Brief macro to do the settag call code - }
        {feel free to get clever and make this a lookup table or
        something more elegant}
        CASE K OF
            OpKey.F1 :
                SetTag(1, KeyModUnShift, Tag);
            OpKey.F2 :
                SetTag(2, KeyModUnShift, Tag);
            OpKey.F3 :
                SetTag(3, KeyModUnShift, Tag);
            OpKey.F4 :
                SetTag(4, KeyModUnShift, Tag);
            OpKey.F5 :
                SetTag(5, KeyModUnShift, Tag);
            OpKey.F6 :
                SetTag(6, KeyModUnShift, Tag);
            OpKey.F7 :
                SetTag(7, KeyModUnShift, Tag);
            OpKey.F8 :
                SetTag(8, KeyModUnShift, Tag);
            OpKey.F9 :
                SetTag(9, KeyModUnShift, Tag);
            OpKey.F10 :
                SetTag(10, KeyModUnShift, Tag);
            OpKey.ShF1 :
                SetTag(1, KeyModShift, Tag);
            OpKey.ShF2 :
                SetTag(2, KeyModShift, Tag);
            OpKey.ShF3 :
                SetTag(3, KeyModShift, Tag);
            OpKey.ShF4 :
                SetTag(4, KeyModShift, Tag);
            OpKey.ShF5 :
                SetTag(5, KeyModShift, Tag);
            OpKey.SHF6 :
                SetTag(6, KeyModShift, Tag);
            OpKey.SHF7 :
                SetTag(7, KeyModShift, Tag);
            OpKey.SHF8 :
                SetTag(8, KeyModShift, Tag);
            OpKey.SHF9 :
                SetTag(9, KeyModShift, Tag);
            OpKey.SHF10 :
                SetTag(10, KeyModShift, Tag);
            OpKey.CtrlF1 :
                SetTag(1, KeyModCtrl, Tag);
            OpKey.CtrlF2 :
                SetTag(2, KeyModCtrl, Tag);
            OpKey.CtrlF3 :
                SetTag(3, KeyModCtrl, Tag);
            OpKey.CtrlF4 :
                SetTag(4, KeyModCtrl, Tag);
            OpKey.CtrlF5 :
                SetTag(5, KeyModCtrl, Tag);
            OpKey.CtrlF6 :
                SetTag(6, KeyModCtrl, Tag);
            OpKey.CtrlF7 :
                SetTag(7, KeyModCtrl, Tag);
            OpKey.CtrlF8 :
                SetTag(8, KeyModCtrl, Tag);
            OpKey.CtrlF9 :
                SetTag(9, KeyModCtrl, Tag);
            OpKey.CtrlF10 :
                SetTag(10, KeyModCtrl, Tag);
            OpKey.AltF1 :
                SetTag(1, KeyModAlt, Tag);
            OpKey.AltF2 :
                SetTag(2, KeyModAlt, Tag);
            OpKey.AltF3 :
                SetTag(3, KeyModAlt, Tag);
            OpKey.AltF4 :
                SetTag(4, KeyModAlt, Tag);
            OpKey.AltF5 :
                SetTag(5, KeyModAlt, Tag);
            OpKey.AltF6 :
                SetTag(6, KeyModAlt, Tag);
            OpKey.AltF7 :
                SetTag(7, KeyModAlt, Tag);
            OpKey.AltF8 :
                SetTag(8, KeyModAlt, Tag);
            OpKey.AltF9 :
                SetTag(9, KeyModAlt, Tag);
            OpKey.AltF10 :
                SetTag(10, KeyModAlt, Tag);
            ELSE
                EXIT;             {don't set label if not an Fkey}
        END;
    END;

    (************************)

    {translate, label and add secondary exit command to commandproc}
    {pass a TKeyRec containing all the Key info}
    PROCEDURE TFKeyMgr.AddExitKeyR(VAR K : TKeyRec);
    BEGIN
        AddSecondaryCommand(K.Cmd, 1, K.Key, 0);
        {if this beeps, then you probably have too many exit commands!}
        IF GetLastError <> 0 THEN
            RingBell;
        SetOPTag(K.Key, K.Tag);
    END;

    (************************)

    {translate, label and add secondary exit command to commandproc}
    {use this one if you don't want to pass records}
    {Key = Opro keyconst}
    {ExitCmd = Opro exit cmd ie. ccQuit, ccUser142...}
    {CP = EntryCommands, PickCommands, Etc.}
    FUNCTION TFKeyMgr.AddExitKey(K, ExitCmd : WORD; Tag : STRING) : BOOLEAN;
    BEGIN
        AddExitKey := TRUE;
        AddSecondaryCommand(ExitCmd, 1, K, 0);
        {if this beeps, then you probably have too many exit commands!}
        IF GetLastError <> 0 THEN BEGIN
            RingBell;
            AddExitKey := FALSE;
        END;
        SetOPTag(K, Tag);
    END;

    (************************)

    PROCEDURE TFKeyMgr.ClearFKeys;
    VAR
        K              : BYTE;
    BEGIN
        FOR K := 1 TO 10 DO BEGIN
            FKeys[K]^.Empty;
            FKeys[K]^.Clear;
        END;
    END;

    (************************)

    PROCEDURE TFKeyMgr.ClearFKey(K : WORD);
    BEGIN
        FKeys[K]^.Empty;
        FKeys[K]^.Clear;
    END;

    (************************)

    PROCEDURE TFKeyMgr.HideFKeyDisplay;
    VAR
        K              : BYTE;
    BEGIN
        IF NOT Shown THEN
            EXIT;
        FOR K := 1 TO 10 DO
            FKeys[K]^.Hide;
        FKeysUp := FALSE;
    END;

    (************************)

    PROCEDURE TFKeyMgr.ShowFKeyDisplay;
    VAR
        Kbd            : BYTE;
    BEGIN
        IF NOT Shown THEN
            EXIT;
        Kbd := KbdFlags AND $F;
        IF (Kbd AND ShiftFlag) <> 0 THEN
            RedrawFkeys(KeyModShift);
        IF (Kbd AND AltFlag) <> 0 THEN
            RedrawFkeys(KeyModAlt);
        IF (Kbd AND CtrlFlag) <> 0 THEN
            RedrawFkeys(KeyModCtrl);
        IF Kbd = 0 THEN
            RedrawFkeys(KeyModUnShift);
        FKeysUp := TRUE;
    END;

    (************************)

    PROCEDURE TFKeyMgr.RedrawFkeys(Level : TKeyLevel);
    VAR
        K              : BYTE;
    BEGIN
        FOR K := 1 TO 10 DO BEGIN
            FKeys[K]^.CurLevel := Level;
            FKeys[K]^.Show;
        END;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    (************************)

    {$IFDEF USEMOUSE}
    FUNCTION TFKeyMgr.MouseOnKey(VAR SC : WORD) : BOOLEAN;
    VAR
        K              : BYTE;
    BEGIN
        MouseOnKey := FALSE;
        FOR K := 1 TO 10 DO BEGIN
            IF FKeys[K]^.MouseOnKey(SC) THEN BEGIN
                MouseOnKey := TRUE;
                EXIT;
            END;
        END;
    END;
    {$ENDIF}

    (************************)

    PROCEDURE TFKeyMgr.PushKey(K : WORD);
    BEGIN
        FKeys[K]^.PUSH;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
    END;

    (************************)

    PROCEDURE TFKeyMgr.SetFKeyDepth(Num : BYTE);
    BEGIN
        FKeyDepth := Num;
    END;

END.
(************************)
(************************)

