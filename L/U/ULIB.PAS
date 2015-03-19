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
{$A+,B-,E+,F+,G-,I+,N-,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

UNIT ULIB;

{$I NDEFINE.INC}

INTERFACE

USES
    DOS,
    OpCrt,
    OpDos,
    OpString,
    QInput,
    UGLOBAL,
    OpDate,
{$IFNDEF NOTNEN}
    QGlobal,
{$ENDIF}
{$IFDEF USEIPX}
    USPXGlo,
    UIpxSpx,
    USpxChk,
{$ENDIF}
    UMSG;


TYPE
    BeepType =
    (
        OLDBEEP,
        TRIPLE,
        BADKEY,
        OprError,
        TESTFAIL,
        TESTPASS,
        RANDBEEP,
        ATNBEEP
        );


    Stype          = STRING[100];
    HMStype        = STRING[2];
    Time           = RECORD
                         Hour           : WORD;
                         Minute         : WORD;
                         Second         : WORD;
                         Sec100         : WORD;
                     END;
    CallBackProc   = PROCEDURE;

FUNCTION CheckBeta(DropDeadDate : OpDate.Date) : BOOLEAN;
PROCEDURE UpdateWtime(Force : BOOLEAN);
PROCEDURE WriteChr(X, Y : INTEGER; Ch : CHAR; Atr : BYTE);
PROCEDURE GetChr(X, Y : INTEGER; VAR Ch : CHAR; VAR Atr : BYTE);
PROCEDURE WriteStr(X, Y : INTEGER; St : Stype; Atr : BYTE);
PROCEDURE TextColor(Colr : BYTE); { Replaces OpCrt unit routine }
PROCEDURE TextBackground(Colr : BYTE); { Replaces OpCrt unit routine }
PROCEDURE DrawBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE);
PROCEDURE DrawShadowBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; SAtr : BYTE);
PROCEDURE DrawDoubleBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE);
PROCEDURE DrawWideBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE);
PROCEDURE PaintBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
PROCEDURE Paint3DBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
PROCEDURE UpdateTimeWindow;
PROCEDURE DecodeTime(Time : LONGINT; VAR H, M, S, Sec100 : WORD);
PROCEDURE EncodeTime(Hours, Minutes, Seconds, Sec100 : WORD; VAR Time : LONGINT);
PROCEDURE ConvertTime(Time : LONGINT; VAR Hours, Minutes, Seconds, Sec100 : HMStype);
FUNCTION GetCurrTime : LONGINT;
PROCEDURE DisplayTime;
PROCEDURE CheckAlarm;
PROCEDURE SetTimerXY(TX, TY : INTEGER);
FUNCTION Attr(Back, Fore : BYTE) : BYTE;
PROCEDURE SetScreenBorder(Colr : BYTE);
FUNCTION PrinterStatus : BYTE;
PROCEDURE GetEquipment(VAR HasFloppy  : BOOLEAN;
                       VAR NumFloppys : INTEGER;
                       VAR NumSerial  : INTEGER;
                       VAR NumPrinters : INTEGER);
PROCEDURE SetFont(Num : BYTE);
FUNCTION FileAge(D : LONGINT) : LONGINT; {Age of file in minutes}
FUNCTION Hot(S : Stype) : WORD;
FUNCTION HiItem(InItem : Stype) : Stype;
FUNCTION Timeout(LastTime, TimeoutVal : LONGINT) : BOOLEAN;
PROCEDURE Beep(Tone : BeepType);
PROCEDURE UpdateMemoryWindow;
PROCEDURE SetUPWCallBack(CallBack : CallBackProc);
PROCEDURE NilUPProc;
FUNCTION PasStr(Strg : STRING) : PCHAR;
FUNCTION PadTrim(Strg : STRING; Len : BYTE) : STRING;
FUNCTION EraseFile(Name : PathStr) : WORD;
FUNCTION ResetAndWaitForUnlock(FName:PathStr;
                               VAR F:FILE;
                               RecSize,
                               MyFileMode,
                               MaxWait:WORD;
                               VAR Result:WORD) : BOOLEAN;
FUNCTION IsLoggedIn : BOOLEAN;
FUNCTION ForceDrive(Path : PathStr; Drive : STRING) : PathStr;
{$IFNDEF NOTNEN}
FUNCTION NenTimeToString(InTime : LONGINT) : STRING;
    {-Returns formatted string from NEN time}

FUNCTION NenDateToString(InDate : QGlobal.Date) : STRING;
    {-Returns formatted string from NEN date}
{$ENDIF}
    (****************************************************************************)

IMPLEMENTATION
USES
    OpCmd,
    nwbase,
    {$IFNDEF NOTNEN}
    QScrF,
    QScrV,
    {$ENDIF}
    QNovell,
    UDIALOG,
    UERROR;

VAR
    CurrTime       : Time;
    Mesg           : STRING[30];
    Lch            : CHAR;

CONST
    TimerX         : INTEGER = 37;
    TimerY         : INTEGER = 11;

    {-------------------------------------------------------------}
VAR
    CurCallBack    : CallBackProc;


    (********************************************************)

    {Turns a pascal string into a pchar - reciprocal function}
    {for StrPas                                              }
    {Make sure that Strg is long enough for a NULL term char }
    {or all hell might break loose!                          }
    FUNCTION PasStr(Strg : STRING) : PCHAR;
    VAR
        A              : ARRAY[0..$FF] OF CHAR ABSOLUTE Strg;
    BEGIN
        A[LENGTH(Strg) + 1] := #0; {this is a potential stack muncher}
        PasStr := @A[1];
    END;

    (****************************************************************************)

    {pad or truncate a string to Len chars}
    FUNCTION PadTrim(Strg : STRING; Len : BYTE) : STRING;
    BEGIN
        Strg := Pad(Strg, Len);
        Strg[0] := CHAR(Len);
        PadTrim := Strg;
    END;

    (****************************************************************************)

    {stuff a drive letter into a path}
    FUNCTION ForceDrive(Path : PathStr; Drive : STRING) : PathStr;
    VAR
        Strg           : STRING;
    BEGIN
        ForceDrive := Path;

        IF LENGTH(Path) < 2 THEN
            EXIT;

        IF LENGTH(Drive) = 0 THEN
            EXIT;

        IF NOT(UPCASE(Drive[1]) IN ['A'..'Z']) THEN
            EXIT;

        IF (LENGTH(Drive) > 1) AND (Drive[2] <> ':') THEN
            EXIT;

        Drive[0] := #1;

        IF Path[2] = ':' THEN BEGIN
            Path[1] := Drive[1];
            ForceDrive := Path;
            EXIT;
        END;

        ForceDrive := Drive + ':' + Path;
    END;

    (****************************************************************************)

    PROCEDURE NilUPProc;
    BEGIN
    END;

    (********************************************************)


    PROCEDURE SetUPWCallBack(CallBack : CallBackProc);
    BEGIN
        CurCallBack := CallBack;
    END;

    (********************************************************)

    PROCEDURE UpdateMemoryWindow;
    CONST
        LastMem        : LONGINT = 0;
    VAR
        CurMemA,
        CurMemM        : LONGINT;
    BEGIN
        WITH UData^ DO BEGIN
            IF NOT MemoryWindowUp THEN
                EXIT;
            CurMemA := MEMAVAIL;
            CurMemM := MAXAVAIL;
            {$IFDEF DEBUG}
            WriteStr(MemX-8,MemY,LeftPad(Long2Str(CurMemA),6)+':'+Pad(Long2Str(CurMemM),6), ClockAttr);
            IF CurMemA <> LastMem THEN
                SetBlink(FALSE); {get rid of migrane inducing flashing screen chars during debug}
            {$ELSE}
            IF CurMemA = LastMem THEN
                EXIT;
            WriteStr(MemX, MemY, LeftPad(Long2Str(CurMemA DIV 1000) + 'K', 5), ClockAttr);
            {$ENDIF}
            LastMem := CurMemA;
        END;
    END;

    {-------------------------------------------------------}

    { Finds the 'Hot' letter in item, i.e. first Upper case       }
    FUNCTION Hot(S : Stype) : WORD;
    VAR
        I              : INTEGER;
    BEGIN
        Hot := 1;
        FOR I := 1 TO LENGTH(S) DO
            IF S[I] IN ['A'..'Z'] THEN BEGIN
                Hot := I;
                EXIT;
            END
    END;

    {---------------------------------------------------}
    FUNCTION HiItem(InItem : Stype) : Stype;
    VAR
        TString        : Stype;
    BEGIN
        System.INSERT('&', InItem, Hot(InItem));
        TString := StLoCase(InItem);
        IF TString[1] = '&' THEN
            TString[2] := UPCASE(TString[2])
        ELSE
            TString[1] := UPCASE(TString[1]);
        HiItem := TString;
    END;

    {-------------------------------------------------------}
    PROCEDURE SetScreenBorder(Colr : BYTE);
    VAR 
        Regs           : Registers;
    BEGIN
        WITH Regs DO BEGIN
            AH := $10;
            AL := 01;
            BH := Colr;
            Intr($10, Regs);
        END;
    END;

    {-------------------------------------------------------}

    {ever hear of a string function?}
    PROCEDURE FormatTime(VAR CurrentTime : Time; VAR S1 : STRING);
    VAR
        Cycle          : CHAR;
        S2             : STRING[10];
    BEGIN
        UpCaseTime := TRUE;
        S1 := TimeToTimeString(InternationalTime(TRUE, FALSE, FALSE, TRUE),
                               HMStoTime(CurrentTime.Hour,
                                         CurrentTime.Minute,
                                         CurrentTime.Second));
{      Cycle := 'A';
      IF (CurrentTime.Hour >= 12) AND (CurrentTime.Hour < 24) THEN BEGIN
          Cycle := 'P';
        END;
      IF CurrentTime.Hour > 12 THEN BEGIN
          CurrentTime.Hour := CurrentTime.Hour-12;
        END;
      IF CurrentTime.Hour = 0 THEN BEGIN
          CurrentTime.Hour := 12;
        END;
      Str(CurrentTime.Hour, S1);
      IF CurrentTime.Hour < 10 THEN S1 := ' '+S1;
      Str(CurrentTime.Minute, S2);
      IF CurrentTime.Minute < 10 THEN S2 := '0'+S2;
      S1 := S1+':'+S2;
      Str(CurrentTime.Second, S2);
      IF CurrentTime.Second < 10 THEN S2 := '0'+S2;
      S1 := S1+'.'+S2;
      S1 := S1+Cycle;}
    END;

    {-------------------------------------------------------}

    PROCEDURE UpdateWtime(Force : BOOLEAN);
    VAR
        Ch             : CHAR;
    LABEL
        Done;
    BEGIN
        WITH UData^ DO BEGIN
            IF Check4Chars THEN ;
            CurCallBack;
            {$IFDEF USEIPX}
            CheckForIPXCall;
            IF IPXMessagePending THEN
                HandleIPXMessage;
            {$ENDIF}
            WITH CurrTime DO
                GetTime(Hour, Minute, Second, Sec100);
            IF TimerWindowUp THEN
                UpdateTimeWindow;
            IF MemoryWindowUp THEN
                UpdateMemoryWindow;
            IF NOT ClockOn THEN GOTO Done;
            CASE CurrTime.Sec100 OF
                0..25 : Ch := ' ';
                26..50 : Ch := ':';
                51..75 : Ch := ' ';
                76..100 : Ch := ':';
            END;
{        Case CurrTime.Sec100 of
          0..25  :  ch := #$F9;
          26..50 :  ch := ':';
          51..75 :  ch := #$F9;
          76..100:  ch := ':';
          end;}
{        Case CurrTime.Sec100 of
          0..25  :  ch := '|';
          26..50 :  ch := '/';
          51..75 :  ch := '-';
          76..100:  ch := '\';
          end;}
            IF Ch <> Lch THEN
                WriteChr(ClockX + 3, ClockY, Ch, ClockAttr);
            Lch := Ch;
            IF (CurrTime.Second <> LastSeconds) OR (Force) THEN BEGIN
                FormatTime(CurrTime, Mesg);
                IF ClockY < 25 THEN
                    IF RConnect <> ' ' THEN
                        WriteChr(ClockX, ClockY, RConnect, BorderAttr);
                WriteStr(ClockX + 1, ClockY, COPY(Mesg, 1, 2), ClockAttr);
                WriteStr(ClockX + 4, ClockY, COPY(Mesg, 4, 6), ClockAttr);
                IF ClockY < 25 THEN
                    IF LConnect <> ' ' THEN
                        WriteChr(ClockX + 10, ClockY, LConnect, BorderAttr);
            END;
Done:
            LastSeconds := CurrTime.Second;
            CheckMsgFile;
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE WriteChr(X, Y : INTEGER; Ch : CHAR; Atr : BYTE);
    VAR 
        S              : STRING[2];
    BEGIN
        S := Ch;
        FastWrite(S, Y, X, Atr);
    END;

    {-------------------------------------------------------}
    PROCEDURE WriteStr(X, Y : INTEGER; St : Stype; Atr : BYTE);
    BEGIN
        FastWrite(St, Y, X, Atr);
    END;

    {-------------------------------------------------------}
    PROCEDURE GetChr(X, Y : INTEGER; VAR Ch : CHAR; VAR Atr : BYTE);
    VAR
        O              : WORD;
    BEGIN
        O := (((Y - 1) * 80 + (X - 1)) * 2); { Offset in Screen memory }
        Ch := CHR(MEM[VideoSegment:O]);
        INC(O);
        Atr := MEM[VideoSegment:O];
    END;

    {-------------------------------------------------------}
    PROCEDURE TextColor(Colr : BYTE); { Replaces OpCrt unit routine }
    BEGIN
        TextAttr := (TextAttr AND $F0) + Colr;
    END;

    {-------------------------------------------------------}
    PROCEDURE TextBackground(Colr : BYTE); { Replaces OpCrt unit routines }
    BEGIN                         { because of use of EGA/VGA  }
        TextAttr := (Colr SHL 4) + (TextAttr AND $0F);
        IF CurrentDisplay = CGA THEN
            TextAttr := TextAttr AND $7F;
    END;

    {-------------------------------------------------}
    PROCEDURE DrawBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE);
    VAR 
        I              : INTEGER;
    BEGIN
        WriteChr(X1, Y1, #$DA, Atr);
        FOR I := X1 + 1 TO X2 - 1 DO
            WriteChr(I, Y1, #$C4, Atr);
        WriteChr(X2, Y1, #$BF, Atr);
        FOR I := Y1 + 1 TO Y2 - 1 DO
            WriteChr(X2, I, #$B3, Atr);
        WriteChr(X2, Y2, #$D9, Atr);
        FOR I := X2 - 1 DOWNTO X1 + 1 DO
            WriteChr(I, Y2, #$C4, Atr);
        WriteChr(X1, Y2, #$C0, Atr);
        FOR I := Y2 - 1 DOWNTO Y1 + 1 DO
            WriteChr(X1, I, #$B3, Atr);
    END;

    {-------------------------------------------------}
    PROCEDURE DrawShadowBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; SAtr : BYTE);
    VAR 
        I, J           : INTEGER;
    BEGIN
        IF CurrentDisplay = MonoHerc THEN BEGIN
            Atr := Attr(Mono_Bright, Mono_Black);
            SAtr := Attr(Mono_White, Mono_Black);
        END;
        FOR I := X1 TO X2 DO
            FOR J := Y1 TO Y2 DO
                WriteChr(I, J, #$20, Atr);
        FOR I := X1 + 1 TO X2 + 1 DO
            WriteChr(I, Y2 + 1, #$DF, SAtr);
        FOR I := Y1 TO Y2 DO
            WriteChr(X2 + 1, I, #$DC, SAtr);
    END;

    {-------------------------------------------------}
    PROCEDURE PaintBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
    VAR 
        I, J           : INTEGER;
    BEGIN
        WriteChr(X1, Y1, #$DA, Atr);
        FOR I := X1 + 1 TO X2 - 1 DO
            WriteChr(I, Y1, #$C4, Atr);
        WriteChr(X2, Y1, #$BF, Atr);
        FOR I := Y1 + 1 TO Y2 - 1 DO
            WriteChr(X2, I, #$B3, Atr);
        WriteChr(X2, Y2, #$D9, Atr);
        FOR I := X2 - 1 DOWNTO X1 + 1 DO
            WriteChr(I, Y2, #$C4, Atr);
        WriteChr(X1, Y2, #$C0, Atr);
        FOR I := Y2 - 1 DOWNTO Y1 + 1 DO
            WriteChr(X1, I, #$B3, Atr);
        FOR I := X1 + 1 TO X2 - 1 DO
            FOR J := Y1 + 1 TO Y2 - 1 DO
                WriteChr(I, J, Fill, Atr);
    END;

    {-------------------------------------------------}
    PROCEDURE Paint3DBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE; Fill : CHAR);
    VAR 
        I, J           : INTEGER;
    BEGIN
        WriteChr(X1, Y1, #$D5, Atr);
        FOR I := X1 + 1 TO X2 - 1 DO
            WriteChr(I, Y1, #$CD, Atr);
        WriteChr(X2, Y1, #$BB, Atr);
        FOR I := Y1 + 1 TO Y2 - 1 DO
            WriteChr(X2, I, #$BA, Atr);
        WriteChr(X2, Y2, #$BD, Atr);
        FOR I := X2 - 1 DOWNTO X1 + 1 DO
            WriteChr(I, Y2, #$C4, Atr);
        WriteChr(X1, Y2, #$C0, Atr);
        FOR I := Y2 - 1 DOWNTO Y1 + 1 DO
            WriteChr(X1, I, #$B3, Atr);
        FOR I := X1 + 1 TO X2 - 1 DO
            FOR J := Y1 + 1 TO Y2 - 1 DO
                WriteChr(I, J, Fill, Atr);
    END;

    {-------------------------------------------------}
    PROCEDURE DrawDoubleBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE);
    VAR 
        I              : INTEGER;
    BEGIN
        WriteChr(X1, Y1, #$C9, Atr);
        FOR I := X1 + 1 TO X2 - 1 DO
            WriteChr(I, Y1, #$CD, Atr);
        WriteChr(X2, Y1, #$BB, Atr);
        FOR I := Y1 + 1 TO Y2 - 1 DO
            WriteChr(X2, I, #$BA, Atr);
        WriteChr(X2, Y2, #$BC, Atr);
        FOR I := X2 - 1 DOWNTO X1 + 1 DO
            WriteChr(I, Y2, #$CD, Atr);
        WriteChr(X1, Y2, #$C8, Atr);
        FOR I := Y2 - 1 DOWNTO Y1 + 1 DO
            WriteChr(X1, I, #$BA, Atr);
    END;

    {-------------------------------------------------}
    PROCEDURE DrawWideBox(X1, Y1, X2, Y2 : INTEGER; Atr : BYTE);
    VAR 
        I              : INTEGER;
    BEGIN
        TextAttr := Atr;
        FOR I := X1 TO X2 DO      { Top Line }
            WriteChr(I, Y1, #$DF, TextAttr);
        FOR I := X2 DOWNTO X1 DO  { Bottom Line }
            WriteChr(I, Y2, #$DC, TextAttr);
        FOR I := Y1 TO Y2 DO      { Right Side }
            WriteChr(X2, I, #$DB, TextAttr);
        FOR I := Y2 DOWNTO Y1 DO  { Left Side }
            WriteChr(X1, I, #$DB, TextAttr);
    END;

    {-------------------------------------------------------}
    PROCEDURE DecodeTime(Time : LONGINT; VAR H, M, S, Sec100 : WORD);
    VAR 
        T              : LONGINT;
    BEGIN
        T := Time;
        IF T > 0 THEN BEGIN
            H := T DIV 360000;
            M := (T MOD 360000) DIV 6000;
            S := ((T MOD 360000) MOD 6000) DIV 100;
            Sec100 := ((T MOD 360000) MOD 6000) MOD 100;
        END
        ELSE BEGIN
            H := 0;
            M := 0;
            S := 0;
            Sec100 := 0;
        END;
        IF UData^.TimeRollover THEN
            IF H > 24 THEN
                H := H - 24;
    END;

    {-------------------------------------------------------}
    PROCEDURE EncodeTime(Hours, Minutes, Seconds, Sec100 : WORD; VAR Time : LONGINT);
    VAR 
        T, H, M, S, S100 : LONGINT;
    BEGIN
        T := 0;
        H := Hours;
        M := Minutes;
        S := Seconds;
        S100 := Sec100;
        T := (H * 360000) + (M * 6000) + (S * 100) + S100;
        Time := T;
    END;

    {-------------------------------------------------------}
    PROCEDURE ConvertTime(Time : LONGINT; VAR Hours, Minutes, Seconds, Sec100 : HMStype);
    VAR 
        H, M, S, S100  : WORD;
        T              : LONGINT;
    BEGIN
        DecodeTime(Time, H, M, S, S100);
        STR(H:2, Hours);
        IF Hours[1] = ' ' THEN Hours[1] := '0';
        STR(M:2, Minutes);
        IF Minutes[1] = ' ' THEN Minutes[1] := '0';
        STR(S:2, Seconds);
        IF Seconds[1] = ' ' THEN Seconds[1] := '0';
        STR(S100:2, Sec100);
        IF Sec100[1] = ' ' THEN Sec100[1] := '0';
    END;

    {-------------------------------------------------}
    PROCEDURE DisplayTime;
    VAR
        Hours, Minutes, Seconds, Sec100 : HMStype;
        Sep            : CHAR;
        Atr            : BYTE;
    BEGIN
        WITH UData^ DO BEGIN
            Atr := TextAttr;
            ConvertTime(Timer, Hours, Minutes, Seconds, Sec100);
            TextBackground(TimerBack);
            TextColor(TimerColor);
            Sep := ':';
            IF DateMode THEN BEGIN
                Sep := '/';
                Seconds := Sec100;
            END;
            CASE TimeFormat OF
                0 :
                    WriteStr(TimerX, TimerY, Hours + Sep + Minutes + Sep + Seconds + '.' + Sec100, TextAttr);
                1 :
                    WriteStr(TimerX, TimerY, Hours + Sep + Minutes + Sep + Seconds + '   ', TextAttr);
                2 :
                    WriteStr(TimerX, TimerY, Minutes + Sep + Seconds + '      ', TextAttr);
                3 :
                    WriteStr(TimerX, TimerY, Hours + Sep + Minutes + '      ', TextAttr);
            END;
            IF TimerFunc <> '' THEN BEGIN
                TextColor(GREEN);
                WriteStr(TimerX - 10, TimerY, TimerFunc, TextAttr);
            END
            ELSE
                WriteStr(TimerX - 10, TimerY, '         ', TextAttr);
            TextColor(Yellow);
            IF AlarmTime <> 0 THEN
                WriteChr(TimerX + 16, TimerY, #$0D, TextAttr)
            ELSE
                WriteChr(TimerX + 16, TimerY, #$20, TextAttr);
            TextAttr := Atr;
        END;
    END;

    {-------------------------------------------------}

    PROCEDURE SetTimerXY(TX, TY : INTEGER);
    BEGIN
        TimerX := TX;
        TimerY := TY;
    END;

    {-------------------------------------------------}
    FUNCTION GetCurrTime : LONGINT;
    VAR
        OH, OM, OS, OS100 : WORD;
        Timer          : LONGINT;
    BEGIN
        GetTime(OH, OM, OS, OS100);
        EncodeTime(OH, OM, OS, OS100, Timer);
        GetCurrTime := Timer;
    END;

    {-------------------------------------------------------}

    PROCEDURE SoundAlarm;
    VAR
        Ch, Ch2        : CHAR;
    BEGIN
        UData^.AlarmTime := 0;
        WHILE NOT Check4Chars DO BEGIN
            UpdateWtime(FALSE);
            Beep(TRIPLE);
            Delay(100);
        END;
        WHILE Check4Chars DO
            GetNextChar(Ch, Ch2);
    END;

    {-------------------------------------------------}
    PROCEDURE CheckAlarm;
    BEGIN
        IF UData^.AlarmTime <> 0 THEN
            IF (UData^.AlarmTime DIV 100) = (GetCurrTime DIV 100) THEN { To the nearest second }
                SoundAlarm;
    END;

    {-------------------------------------------------}
    PROCEDURE UpdateTimeWindow;
    BEGIN
        WITH UData^ DO BEGIN
            IF TimerWindowMode = 1 THEN BEGIN
                Timer := GetCurrTime;
                Timer := Timer - SeedTime;
                DisplayTime;
            END;
            IF TimerWindowMode = 2 THEN BEGIN
                Timer := GetCurrTime;
                DisplayTime;
            END;
            IF TimerWindowMode = 3 THEN BEGIN
                Timer := AlarmTime - GetCurrTime;
                IF Timer < 0 THEN
                    Timer := 0;
                DisplayTime;
            END;
            CheckAlarm;
        END;
    END;

    {-------------------------------------------------}
    FUNCTION Attr(Back, Fore : BYTE) : BYTE;
    BEGIN
        Attr := (Back SHL 4) + (Fore AND $F);
    END;

    {-------------------------------------------------}
    FUNCTION PrinterStatus : BYTE;
    BEGIN
        WITH UData^, Regs DO BEGIN
            AH := 2;
            dx := 0;
            Intr($17, Regs);
            PrinterStatus := AH;
        END;
    END;

    {-------------------------------------------------}
    PROCEDURE GetEquipment(VAR HasFloppy  : BOOLEAN;
                           VAR NumFloppys : INTEGER;
                           VAR NumSerial  : INTEGER;
                           VAR NumPrinters : INTEGER);
    VAR
        Equip          : WORD;
        NumF           : BYTE;
    BEGIN
        Equip := MEMW[$0000:$0410];
        WRITELN(BinaryB(Equip));
        HasFloppy := (Equip AND 1) <> 0;
        NumF := ((Equip SHR 6) AND 3);
        CASE NumF OF
            0 :
                NumFloppys := 1;
            2 :
                NumFloppys := 2;
            1 :
                NumFloppys := 3;
            3 :
                NumFloppys := 4;
        END;
        NumSerial := (Equip SHR 9) AND 7;
        NumPrinters := (Equip SHR 14) AND 3;
    END;

    {-------------------------------------------------}

    PROCEDURE SetFont(Num : BYTE);
    BEGIN
        WITH UData^, Regs DO BEGIN
            AH := $11;
            AL := Num;
            Bx := 0;
            Intr($10, Regs);
        END;
    END;

    {-------------------------------------------------}

    FUNCTION FileAge(D : LONGINT) : LONGINT; {Age of file in seconds}
    BEGIN
        WITH UData^ DO BEGIN
            UnPackTime(D, Dt);
            FDT.D := DMYtoDate(Dt.Day, Dt.Month, Dt.Year);
            FDT.T := HMStoTime(Dt.Hour, Dt.Min, Dt.Sec);
            CDT.D := Today;
            CDT.T := CurrentTime;
            DateTimeDiff(FDT, CDT, Days, Secs);
            FileAge := (Days * 1440) + (Secs DIV 60);
        END;
    END;

    {-------------------------------------------------}

    FUNCTION Timeout(LastTime, TimeoutVal : LONGINT) : BOOLEAN;
    VAR
        LT             : LONGINT;
        CT             : LONGINT;
    BEGIN
        CT := TimeMS;
        IF CT < LastTime THEN
            LT := 86400000 - LastTime { accounts for midnight rollover }
        ELSE
            LT := LastTime;
        Timeout := CT - LT > TimeoutVal;
    END;

    {-------------------------------------------------}

    PROCEDURE Beep(Tone : BeepType);
    VAR
        J,
        I              : INTEGER;
        Dummy          : BOOLEAN;
    BEGIN
        NoSound;

        CASE Tone OF
            TRIPLE :
                BEGIN
                    FOR I := 1 TO 3 DO BEGIN
                        Sound(4000);
                        Delay(40);
                        NoSound;
                        Delay(40);
                    END;
                END;
            OLDBEEP :
                BEGIN
                    Sound(880);
                    Delay(100);
                    NoSound;
                END;
            ATNBEEP :
                BEGIN
                    Sound(2000);
                    Delay(100);
                    NoSound;
                    Delay(100);
                    Sound(2000);
                    Delay(300);
                    NoSound;
                END;
            BADKEY :
                BEGIN
                    Sound(2000);
                    Delay(100);
                    NoSound;
                END;
            OprError :
                BEGIN
                    FOR I := 1 TO 2 DO BEGIN
                        Sound(2500);
                        Delay(100);
                        NoSound;
                        Delay(100);
                    END;
                END;
            TESTFAIL :
                BEGIN
                    FOR I := 500 DOWNTO 1 DO BEGIN
                        Sound(2000 + I);
                        Delay(1);
                    END;
                    FOR I := 1 TO 75 DO BEGIN
                        Sound(RANDOM(1000));
                        Delay(5);
                    END;
                    NoSound;
                END;
            TESTPASS :
                BEGIN
                    FOR J := 1 TO 3 DO BEGIN
                        FOR I := 1 TO 200 DO BEGIN
                            Sound(2000 + I);
                            Delay(1);
                        END;
                    END;
                    NoSound;
                END;
            RANDBEEP :
                BEGIN
                    FOR I := 1 TO 20 DO BEGIN
                        Sound(RANDOM(4000));
                        Delay(RANDOM(200));
                        NoSound;
                    END;
                END;
        END;
    END;

    {-------------------------------------------------}

    FUNCTION ResetAndWaitForUnlock(FName:PathStr;
                               VAR F:FILE;
                               RecSize,
                               MyFileMode,
                               MaxWait:WORD;
                               VAR Result:WORD) : BOOLEAN;
    VAR
        OldFileMode : WORD;
        T           : LONGINT;
        COP         : CylonP;
    BEGIN
         OldFileMode := FileMode;
         FileMode := MyFileMode;
         {3 second delay before cylon comes up}
         NEW(COP, InitCFD('Waiting for '+JustFileName(FName)+' unlock', 10, 3));
         COP^.Draw;
         {$I-}
         T := Timer;
         ASSIGN(F, FName);
         Result := IORESULT;
         REPEAT
             RESET(F, RecSize);
             IF COP <> NIL THEN
                 COP^.Update;
             Result := IORESULT;
             IF ABS(Timer-T) > (MaxWait * 100) THEN
                 BREAK;
         UNTIL Result <> 162;
         {$I+}
         IF COP <> NIL THEN
             DISPOSE(COP, Done);
         ResetAndWaitForUnlock := Result = 0;
         FileMode := OldFileMode;
    END;

    {-------------------------------------------------}

    FUNCTION EraseFile(Name : PathStr) : WORD;
    VAR
        F              : FILE;
    BEGIN
        ASSIGN(F, Name);
        {$I-}
        ERASE(F);
        {$I+}
        EraseFile := IORESULT;
    END;

    {-------------------------------------------------}

    {Timebomb with 30 day warning}
    FUNCTION CheckBeta(DropDeadDate : OpDate.Date) : BOOLEAN;
    BEGIN
        IF Today > (DropDeadDate - 30) THEN BEGIN
            RingBell;
            IF Today > DropDeadDate THEN BEGIN
                DispError('Beta Version Expired!', PARAMSTR(0), TRUE);
                Beep(TESTFAIL);
                CheckBeta := FALSE;
                EXIT;
            END;

            DispError('Warning: Beta Version Expires in ' +
                      Long2Str(DropDeadDate - Today) + ' Days',
                      PARAMSTR(0), FALSE);
            Delay(2000);
        END;

    END;

    (****************************************************************************)

    FUNCTION IsLoggedIn : BOOLEAN;
    VAR
        IsLogged       : BOOLEAN;
    BEGIN
        IsLoggedIn := FALSE;
        IF NetwareLoaded(IsLogged) THEN
            IsLoggedIn := IsLogged;
    END;

    (****************************************************************************)

    {$IFNDEF NOTNEN}
    FUNCTION NenTimeToString(InTime : LONGINT) : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        FormatLongTime(InTime, Strg);
        NenTimeToString := Strg;
    END;

    (****************************************************************************)

    FUNCTION NenDateToString(InDate : QGlobal.Date) : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        FormatDate(InDate, Strg);
        NenDateToString := Strg;
    END;
    {$ENDIF}
    (****************************************************************************)


BEGIN
    CurCallBack := NilUPProc;

END.
(****************************************************************************)
(****************************************************************************)
