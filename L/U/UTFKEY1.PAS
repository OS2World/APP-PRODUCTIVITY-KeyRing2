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
{$A-,R-,S-,V-,O+,F+,X+}

UNIT UTFkey;                       { Function key help displays }

INTERFACE
USES
    {$IFDEF COMET}
    CrTypes,
    {$ENDIF}
    OpCmd;


TYPE
    FkeyTag        = STRING[13];

    KeyRec = RECORD
                 Key,
                 Cmd : WORD;
                 Tag : STRING[6];
             END;


    ButtonStyles   = (Bordered, Shadowed);
    KeyLevelT =(UnShift,Shift,Ctrl,Alt);

    Levels         = ARRAY[UnShift..Alt] OF FkeyTag;

    FKey           = OBJECT
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
                         DESTRUCTOR Done;
                         PROCEDURE Clear;
                         PROCEDURE SetKey(Level : KeyLevelT; Tag : FkeyTag);
                         PROCEDURE Show;
                         PROCEDURE Hide;
                         PROCEDURE Push;
                         PROCEDURE Fill;
                         PROCEDURE Empty;
                         FUNCTION MouseOnKey(VAR ScanCode : WORD) : BOOLEAN;
                     END;

    FkeyPtr        = ^FKey;
    AllFkeys       = ARRAY[1..10] OF FkeyPtr;

CONST
    FKeysUp        : BOOLEAN = FALSE;
    Shown          : BOOLEAN = FALSE;

    ButtonStyle    : ButtonStyles = Bordered;

CONST
    FKeyDepth      : BYTE = 2;

VAR
    Fkeys          : AllFkeys;

PROCEDURE OpenFKeyDisplay(Y : BYTE);
PROCEDURE CloseFKeyDisplay;
PROCEDURE SetTag(Key : WORD; Level : KeyLevelT; Tag : FkeyTag);
PROCEDURE SetOPTag(Key : WORD; Tag : FkeyTag);
PROCEDURE SetOPCTag(VAR K : KeyRec; VAR CP : CommandProcessor);
PROCEDURE SetOPCCTag(Key, ExitCmd : WORD; Tag : STRING; VAR CP : CommandProcessor);
PROCEDURE PushKey(Key : WORD);
PROCEDURE ClearFKey(Key : WORD);
PROCEDURE ClearFKeys;
PROCEDURE RedrawFkeys(Level : KeyLevelT);
PROCEDURE HideFKeyDisplay;
PROCEDURE ShowFKeyDisplay;
{12.12.95}
procedure SetFKeyLevel(Level: KeyLevelT; Cmds: crKeysArray;
                       var CP: CommandProcessor);
procedure SaveFKeyLevel(Level: KeyLevelT; var Buffer:crTagsArray);
procedure RestoreFKeyLevel(Level: KeyLevelT; Buffer:crTagsArray);

IMPLEMENTATION

USES
    Dos,
    OpCrt,
    OpDos,
    OpKey,
    OpMouse,
    OpString,
    {UGLOBAL,
    ULanguag,
    UMsg,}
    OPCOL16;

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

    PROCEDURE PaintBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
    VAR 
        I, 
        J       : INTEGER;
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

    PROCEDURE Paint3DBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
    VAR 
        I, 
        J       : INTEGER;
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
        CurLevel := UnShift;
        Pushed := FALSE;
        KeyShown := FALSE;
        HideMouse;
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
        I : KeyLevelT;
    BEGIN
        FOR I := Low(KeyLevelT) TO High(KeyLevelT) DO
            Tags^[I] := CharStr(' ',6);
    END;

    DESTRUCTOR FKey.Done;
    BEGIN
        HideMouse;
        RestoreWindow(X1, Y1, X2, Y2, TRUE, Covers);
        IF Tags <> NIL THEN
            DISPOSE(Tags);
        KeyShown := FALSE;
    END;

    PROCEDURE FKey.SetKey(Level : KeyLevelT; Tag : FkeyTag);
    BEGIN
        Tags^[Level] := Tag;
    END;

    PROCEDURE FKey.Push;
    BEGIN
        HideMouse;
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
        HideMouse;
        CASE CurLevel OF
            UnShift : FID := 'F';
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
        ShowMouse;
    END;

    PROCEDURE FKey.Empty;
    VAR
        Strg : STRING;
    BEGIN
        HideMouse;
        Strg := CharStr(' ', 6);
        FastWrite(Strg, Y1 + 1, X1 + 1, TagColor);
        IF FKeyDepth = 5 THEN BEGIN
            FastWrite(Strg, Y1 + 2, X1 + 1, TagColor);
            FastWrite(Strg, Y1 + 3, X1 + 1, TagColor);
            FastWrite(Strg, Y1 + 4, X1 + 1, TagColor);
        END;
        ShowMouse;
    END;

    PROCEDURE FKey.Show;
    BEGIN
        HideMouse;
        IF NOT KeyShown THEN
            SaveWindow(X1, Y1, X2, Y2, FALSE, Covers);
        Paint3DBox(X1, Y1, X2, Y2, BoxColor, ' ');
        {    SetMouseHotSpot(x1,y1,x2,y2,$3A00+(FkeyID shl 8));}
        Fill;
        KeyShown := TRUE;
        ShowMouse;
    END;

    PROCEDURE FKey.Hide;
    BEGIN
        HideMouse;
        IF KeyShown THEN
            RestoreWindow(X1, Y1, X2, Y2, FALSE, Covers);
        ShowMouse;
        KeyShown := FALSE;
    END;

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

    {>>> NON-METHOD Procedures ---------------------------}

    PROCEDURE OpenFKeyDisplay(Y : BYTE);
    BEGIN
        {SaveHotSpotState;}
        FOR Key := 1 TO 10 DO
            NEW(Fkeys[Key], Init(Key, Y));
        FullMouseWindow;
        ShowMouse;
        FKeysUp := TRUE;
        Shown := TRUE;
        FKeyDepth := 2;
    END;

    PROCEDURE CloseFKeyDisplay;
    BEGIN
        FOR Key := 1 TO 10 DO BEGIN
            IF FKeys[Key] <> NIL THEN
                DISPOSE(Fkeys[Key], Done);
        END;
        FILLCHAR(FKeys, SizeOf(Fkeys), #0);
        {    RestoreHotSpotState;}
        FKeysUp := FALSE;
        Shown := FALSE;
    END;

    PROCEDURE SetTag(Key : WORD; Level : KeyLevelT; Tag : FkeyTag);
    BEGIN
        IF Fkeys[Key]^.Tags^[Level] = Tag THEN
            EXIT;
        Fkeys[Key]^.SetKey(Level, Tag);
        IF FKeysUp THEN BEGIN
            Fkeys[Key]^.Empty;
            Fkeys[Key]^.Fill;
        END;
    END;

{12.12.95}
procedure SetFKeyLevel(Level: KeyLevelT; Cmds: crKeysArray;
                       var CP: CommandProcessor);
var
   i   : Integer;
   K   : Word;
begin
   for i := 1 to 10 do
      if Cmds[i].Cmd <> ccNone then
         begin
         case Level of
            UnShift:
               K := OpKey.F1;
            Shift:
               K := OpKey.ShF1;
            Ctrl:
               K := OpKey.CtrlF1;
            Alt:
               K := OpKey.AltF1;
         end; {CASE}
         K := K + $100 * (i - 1);
         CP.AddCommand(Cmds[i].Cmd, 1, K, 0);
         IF CP.GetLastError <> 0 THEN
            RingBell;
         SetTag(i, Level, ScnMsgP^.SysMsg(Cmds[i].MsgNr));
         end
      else
         SetTag(i, Level, ' / ');
end;

procedure SaveFKeyLevel(Level: KeyLevelT; var Buffer:crTagsArray);
var
   i : Integer;
begin
   for i := 1 to 10 do
      Buffer[i] := Fkeys[i]^.Tags^[Level];
end;

procedure RestoreFKeyLevel(Level: KeyLevelT; Buffer:crTagsArray);
var
   i : Integer;
begin
   for i := 1 to 10 do
      SetTag(i, Level, Buffer[i]);
end;
{--------}


    {Translate Opro key into ^$@#&*@! newsmaker keys}
    PROCEDURE SetOPTag(Key : WORD; Tag : FkeyTag);
    BEGIN
        {I wrote a Brief macro to do the settag call code - }
        {feel free to get clever and make this a lookup table or
        something more elegant}
        CASE Key OF
        OpKey.F1 : SetTag(1, UnShift, Tag);
        OpKey.F2 : SetTag(2 , UnShift, Tag);
        OpKey.F3 : SetTag(3 , UnShift, Tag);
        OpKey.F4 : SetTag(4 , UnShift, Tag);
        OpKey.F5 : SetTag(5 , UnShift, Tag);
        OpKey.F6 : SetTag(6 , UnShift, Tag);
        OpKey.F7 : SetTag(7 , UnShift, Tag);
        OpKey.F8 : SetTag(8 , UnShift, Tag);
        OpKey.F9 : SetTag(9 , UnShift, Tag);
        OpKey.F10 : SetTag(10 , UnShift, Tag);
        OpKey.ShF1 : SetTag(1 , Shift, Tag);
        OpKey.ShF2 : SetTag(2 , Shift, Tag);
        OpKey.ShF3 : SetTag(3 , Shift, Tag);
        OpKey.ShF4 : SetTag(4 , Shift, Tag);
        OpKey.ShF5 : SetTag(5 , Shift, Tag);
        OpKey.ShF6 : SetTag(6 , Shift, Tag);
        OpKey.ShF7 : SetTag(7 , Shift, Tag);
        OpKey.ShF8 : SetTag(8 , Shift, Tag);
        OpKey.ShF9 : SetTag(9 , Shift, Tag);
        OpKey.ShF10 : SetTag(10 , Shift, Tag);
        OpKey.CtrlF1 : SetTag(1 , Ctrl, Tag);
        OpKey.CtrlF2 : SetTag(2 , Ctrl, Tag);
        OpKey.CtrlF3 : SetTag(3 , Ctrl, Tag);
        OpKey.CtrlF4 : SetTag(4 , Ctrl, Tag);
        OpKey.CtrlF5 : SetTag(5 , Ctrl, Tag);
        OpKey.CtrlF6 : SetTag(6 , Ctrl, Tag);
        OpKey.CtrlF7 : SetTag(7 , Ctrl, Tag);
        OpKey.CtrlF8 : SetTag(8 , Ctrl, Tag);
        OpKey.CtrlF9 : SetTag(9 , Ctrl, Tag);
        OpKey.CtrlF10 : SetTag(10 , Ctrl, Tag);
        OpKey.AltF1 : SetTag(1 , Alt, Tag);
        OpKey.AltF2 : SetTag(2 , Alt, Tag);
        OpKey.AltF3 : SetTag(3 , Alt, Tag);
        OpKey.AltF4 : SetTag(4 , Alt, Tag);
        OpKey.AltF5 : SetTag(5 , Alt, Tag);
        OpKey.AltF6 : SetTag(6 , Alt, Tag);
        OpKey.AltF7 : SetTag(7 , Alt, Tag);
        OpKey.AltF8 : SetTag(8 , Alt, Tag);
        OpKey.AltF9 : SetTag(9 , Alt, Tag);
        OpKey.AltF10 : SetTag(10 , Alt, Tag);
        ELSE
            EXIT; {don't set label if not an Fkey}
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
    PROCEDURE SetOPCCTag(Key, ExitCmd:WORD; Tag:STRING; VAR CP : CommandProcessor);
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
            Fkeys[Key]^.Empty;
            Fkeys[Key]^.Clear;
        END;
    END;

    PROCEDURE ClearFKey(Key : WORD);
    BEGIN
        Fkeys[Key]^.Empty;
        Fkeys[Key]^.Clear;
    END;

    PROCEDURE HideFKeyDisplay;
    BEGIN
        IF NOT Shown THEN 
            EXIT;
        FOR Key := 1 TO 10 DO
            Fkeys[Key]^.Hide;
        FKeysUp := FALSE;
    END;

    PROCEDURE ShowFKeyDisplay;
    VAR 
        Kbd        : BYTE;
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

    PROCEDURE RedrawFkeys(Level : KeyLevelT);
    BEGIN
        FOR Key := 1 TO 10 DO BEGIN
            Fkeys[Key]^.CurLevel := Level;
            Fkeys[Key]^.Show;
        END;
        ShowMouse;
    END;

    PROCEDURE PushKey(Key : WORD);
    BEGIN
        Fkeys[Key]^.Push;
        ShowMouse;
    END;

    PROCEDURE SetFKeyDepth(Num : BYTE);
    BEGIN
        FKeyDepth := Num;
    END;

END.

