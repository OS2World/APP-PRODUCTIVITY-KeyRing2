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
{$A-,V-,O+,F+}

UNIT UTime;

INTERFACE

USES Dos, OpCrt, QGlobal, QInput, QScreen, QUpTime, QNovell, QHdrRec, OpEdit,
    { UVscreen,} UMSg, UColors,
    UMENU, ULib, UGLOBAL, UKey, OpWindow, UWindow, UCalndr, OpMouse, OpString;

PROCEDURE GetNewTime(OldTime : LONGINT; VAR NewTime : LONGINT; Format : INTEGER; Mode : INTEGER);
PROCEDURE GetNewMinSec(OldTime : WORD; VAR NewTime : WORD);
PROCEDURE GetTimeResult(VAR OH, OM, OS, OS100 : WORD; Format : INTEGER);
FUNCTION GetTimeFromUser : LONGINT;

IMPLEMENTATION

    {-------------------------------------------------------}

    PROCEDURE GetTimeValue(Title : TitleString; VAR Result : LONGINT);
    VAR 
        H, M, S, S100 : HMStype;
        Hw, MW, Sw, Sw100 : WORD;
        I              : INTEGER;
        Save3D         : BOOLEAN;
        CurDigit       : INTEGER;
        MaxDigit       : INTEGER;
        FKey, Quit     : BOOLEAN;
        WorkT          : ARRAY[1..6] OF CHAR;
        Check          : ARRAY[1..6] OF CHAR;

        PROCEDURE DisplayTimeValue;
        VAR 
            I          : INTEGER;
            Temp           : LONGINT;
        BEGIN
            MOVE(WorkT[1], H[1], 2);
            MOVE(WorkT[3], M[1], 2);
            MOVE(WorkT[5], S[1], 2);
            VAL(H, Hw, I);
            VAL(M, MW, I);
            VAL(S, Sw, I);
            Sw100 := 0;
            IF UData^.DateMode THEN BEGIN
                Sw100 := Sw;
                Sw := 0;
            END;
            EncodeTime(Hw, MW, Sw, Sw100, Temp);
            ConvertTime(Temp, H, M, S, S100);
            IF UData^.DateMode THEN
                S := S100;
            MOVE(H[1], WorkT[1], 2);
            MOVE(M[1], WorkT[3], 2);
            MOVE(S[1], WorkT[5], 2);
            I := 0;
            TextBackground(UData^.TimerBack);
            TextColor(White);
            IF CurDigit = 1 THEN
                TextBackground(Cyan);
            WriteChr(36 + I, 15, WorkT[1], TextAttr);
            INC(I);
            TextBackground(UData^.TimerBack);
            IF CurDigit = 2 THEN
                TextBackground(Cyan);
            WriteChr(36 + I, 15, WorkT[2], TextAttr);
            INC(I, 2);
            TextBackground(UData^.TimerBack);
            IF CurDigit = 3 THEN
                TextBackground(Cyan);
            WriteChr(36 + I, 15, WorkT[3], TextAttr);
            INC(I);
            TextBackground(UData^.TimerBack);
            IF CurDigit = 4 THEN
                TextBackground(Cyan);
            WriteChr(36 + I, 15, WorkT[4], TextAttr);
            IF MaxDigit = 4 THEN EXIT;
            INC(I, 2);
            TextBackground(UData^.TimerBack);
            IF CurDigit = 5 THEN
                TextBackground(Cyan);
            WriteChr(36 + I, 15, WorkT[5], TextAttr);
            INC(I);
            TextBackground(UData^.TimerBack);
            IF CurDigit = 6 THEN
                TextBackground(Cyan);
            WriteChr(36 + I, 15, WorkT[6], TextAttr);
        END;
    BEGIN
        ConvertTime(Result, H, M, S, S100);
        IF UData^.DateMode THEN BEGIN
            S := S100;
            Check[1] := '1';
            Check[2] := '9';
            Check[3] := '3';
            Check[4] := '9';
            Check[5] := '9';
            Check[6] := '9';
        END
        ELSE BEGIN
            Check[1] := '2';
            Check[2] := '9';
            Check[3] := '6';
            Check[4] := '9';
            Check[5] := '6';
            Check[6] := '9';
        END;
        MOVE(H[1], WorkT[1], 2);
        MOVE(M[1], WorkT[3], 2);
        MOVE(S[1], WorkT[5], 2);
        CurDigit := 6;
        MaxDigit := 6;
        SuspendWindowEffects;
        UData^.BorderOn := FALSE;
        OpenWindow(25, 14, 55, 16, Title, PlainWhite_Scheme);
        RestoreWindowEffects;
        SetBorderColors;
        UData^.BorderOn := TRUE;
        TextBackground(UData^.TimerBack);
        PaintBox(25, 14, 55, 16, TextAttr, #$20);
        TextColor(LightGray);
        DrawWideBox(25, 14, 55, 16, TextAttr);
        TextBackground(UData^.TimerBack);
        TextColor(White);
        IF UData^.DateMode THEN
            WriteStr(36, 15, H + '/' + M + '/' + S, TextAttr)
        ELSE
            IF UData^.TimeFormat = 3 THEN BEGIN
                WriteStr(36, 15, H + ':' + M, TextAttr);
                MaxDigit := 4;
                CurDigit := 1;
            END
        ELSE
            WriteStr(36, 15, H + ':' + M + ':' + S, TextAttr);
        DisplayTimeValue;
        Quit := FALSE;
        WHILE NOT Quit DO
            WITH UData^ DO BEGIN
                FKey := FALSE;
                WHILE NOT Check4Chars DO
                    UpdateTime(FALSE);
                GetNextChar(Ch, Ch2);
                IF Ch = #0 THEN BEGIN
                    FKey := TRUE;
                    Ch := Ch2;
                END;
                CASE Ch OF
                    Esc : BEGIN EscapeFlag := TRUE; Quit := TRUE; END;
                    CursorUp : BEGIN
                                   IF WorkT[CurDigit] < Check[CurDigit] THEN
                                       INC(WorkT[CurDigit])
                                   ELSE BEGIN
                                       IF (CurDigit MOD 2) = 0 THEN BEGIN
                                           WorkT[CurDigit] := '0';
                                           INC(WorkT[CurDigit - 1]);
                                       END;
                                   END;
                                   DisplayTimeValue;
                               END;
                    CursorDown : BEGIN
                                     IF WorkT[CurDigit] > '0' THEN
                                         DEC(WorkT[CurDigit])
                                     ELSE BEGIN
                                         IF (CurDigit MOD 2) <> 0 THEN BEGIN
                                             WorkT[CurDigit] := '0';
                                             INC(CurDigit);
                                         END;
                                     END;
                                     DisplayTimeValue;
                                 END;
                    CursorLeft : BEGIN
                                     IF CurDigit > 1 THEN
                                         DEC(CurDigit);
                                     DisplayTimeValue;
                                 END;
                    CursorRight : BEGIN
                                      IF CurDigit < MaxDigit THEN
                                          INC(CurDigit);
                                      DisplayTimeValue;
                                  END;
                    '0'..'9' : BEGIN
                                   IF Ch <= Check[CurDigit] THEN BEGIN
                                       WorkT[CurDigit] := Ch;
                                       IF CurDigit < MaxDigit THEN
                                           INC(CurDigit);
                                   END;
                                   DisplayTimeValue;
                               END;
                    #$0D : BEGIN
                               Quit := TRUE;
                               MOVE(WorkT[1], H[1], 2);
                               MOVE(WorkT[3], M[1], 2);
                               MOVE(WorkT[5], S[1], 2);
                               VAL(H, Hw, I);
                               VAL(M, MW, I);
                               VAL(S, Sw, I);
                               EncodeTime(Hw, MW, Sw, 0, Result);
                           END;
                    Esc : Quit := TRUE;
                    ELSE
                        Beep(OLDBEEP);
                END;
            END;
        CloseWindow;
    END;

    {-------------------------------------------------------}

    PROCEDURE DoTimeCalculation(VAR Result : LONGINT; Mode : INTEGER);
    VAR 
        M, I       : INTEGER;
        TimeVal        : LONGINT;
    BEGIN
        WITH UData^ DO BEGIN
            Menu^[1] := 'Add';
            Menu^[2] := SysMsg(000668) {'Subtract'} ;
            Menu^[3] := SysMsg(000669) {'Multiply'} ;
            Menu^[4] := SysMsg(000670) {'Divide'} ;
            Menu^[5] := SysMsg(000671) {'Value Set'} ;
            Menu^[6] := SysMsg(000672) {'Get Time'} ;
            Menu^[7] := SysMsg(000673) {'Format'} ;
            Menu^[8] := SysMsg(000674) {'Restore'} ;
            IF Mode = 0 THEN BEGIN
                OpenMenu(WinX + 14,
                         WinY,
                         WinX + 21,
                         WinY + 9,
                         Menu^,
                         8, 11,
                         NoSort, '',
                         SysMsg(000675) {' Select '} , Green_Scheme, I);
                IF LastCalcSelection <> 0 THEN
                    MoveSelection(LastCalcSelection);
                M := GetMenu;
                CloseWindow;
            END
            ELSE
                M := Mode;
            IF M > 0 THEN
                LastCalcSelection := M;
            CASE M OF
                1 : BEGIN
                        TimeVal := 0;
                        GetTimeValue(SysMsg(000676) {' + Plus '} , TimeVal);
                        Result := Timer + TimeVal;
                    END;
                2 : BEGIN
                        TimeVal := 0;
                        GetTimeValue(SysMsg(000677) {' - Minus '} , TimeVal);
                        Result := Timer - TimeVal;
                    END;
                3 : BEGIN
                        TimeVal := 0;
                        GetTimeValue(SysMsg(000678) {' Times '} , TimeVal);
                        Result := Timer * (TimeVal DIV 100);
                    END;
                4 : BEGIN
                        TimeVal := 0;
                        GetTimeValue(SysMsg(000679) {' Divided by '} , TimeVal);
                        IF TimeVal > 0 THEN
                            Result := Timer DIV(TimeVal DIV 100);
                    END;
                5 : BEGIN
                        TimeVal := 0;
                        GetTimeValue(SysMsg(000680) {' Set Value as '} , TimeVal);
                        Result := TimeVal;
                        IF Mode <> 0 THEN
                            ForceEscape;
                    END;
                6 : BEGIN
                        Result := GetCurrTime;
                    END;
                7 : BEGIN
                        Menu^[1] := 'HH:MM:SS.TT';
                        Menu^[2] := 'HH:MM:SS';
                        Menu^[3] := 'MM:SS';
                        Menu^[4] := 'HH:MM';
                        Menu^[5] := SysMsg(000681) {'24Hr Roll On'} ;
                        Menu^[6] := SysMsg(000682) {'24Hr Roll Off'} ;
                        OpenMenu(WinX + 21, WinY + 1, WinX + 35, WinY + 8, Menu^, 6, 13, NoSort, '',
                                 SysMsg(000683) {' Time Format '} , Orange_Scheme, I);
                        CASE GetMenu OF
                            1 : TimeFormat := 0;
                            2 : TimeFormat := 1;
                            3 : TimeFormat := 2;
                            4 : TimeFormat := 3;
                            5 : TimeRollover := TRUE;
                            6 : TimeRollover := FALSE;
                        END;
                        CloseWindow;
                        Result := Timer;
                    END;
                8 : BEGIN
                        Result := InitialTime;
                    END;
            END;
        END;
    END;

    {-------------------------------------------------------}

    PROCEDURE DoAlarmFunctions;
    VAR 
        M, I       : INTEGER;
        CTime          : LONGINT;
        LastLap        : LONGINT;
    BEGIN
        WITH UData^ DO BEGIN
            Menu^[1] := SysMsg(000684) {'Set Alarm'} ;
            Menu^[2] := SysMsg(000685) {'Clear Alarm'} ;
            Menu^[3] := SysMsg(000686) {'Countdown'} ;
            OpenMenu(WinX + 18,
            WinY + 2,
            WinX + 25,
            WinY + 9,
            Menu^,
            3, 11,
            NoSort, '',
            SysMsg(000687) {' Function '} ,
            Green_Scheme, I);
            M := GetMenu;
            CloseWindow;
            CASE M OF
                1 : BEGIN
                        IF AlarmTime = 0 THEN
                            CTime := GetCurrTime
                        ELSE
                            CTime := AlarmTime;
                        LastLap := CTime;
                        GetTimeValue(SysMsg(000688) {' Alarm Time '} , CTime);
                        IF LastLap <> CTime THEN BEGIN
                            AlarmTime := CTime;
                            TimerWindowMode := 3;
                            TimeFormat := 0;
                            TimerFunc := #$19;
                            TimerWindowUp := TRUE;
                        END;
                        DisplayTime;
                    END;
                2 : BEGIN
                        AlarmTime := 0;
                        DisplayTime;
                    END;
                3 : BEGIN
                        CTime := 0;
                        GetTimeValue(SysMsg(000688) {' Alarm Time '} , CTime);
                        IF CTime <> 0 THEN BEGIN
                            AlarmTime := GetCurrTime + CTime;
                            TimerWindowMode := 3;
                            TimeFormat := 0;
                            TimerFunc := #$19;
                            TimerWindowUp := TRUE;
                        END;
                    END;
            END;
        END;
    END;

    {-------------------------------------------------------}
    { GetNewTime is the Engine for all Time functions       }
    { parameters are encoded in 100th seconds. Routines in  }
    { ULib provide encode and decode functions. Format is }
    { the Display mode: 0 = HH:MM:SS.TT where TT is 100ths  }
    {                   1 = HH:MM:SS                        }
    {                   2 = MM:SS                           }
    {                   3 = HH:MM                           }
    {-------------------------------------------------------}

    PROCEDURE GetNewTime(OldTime : LONGINT; VAR NewTime : LONGINT; Format : INTEGER; Mode : INTEGER);

    VAR 
        Done, Save3D, SaveGrow : BOOLEAN;
        OH, OM, OS, OS100 : WORD;
        Yr, Mo, Da, DW, Year : WORD;
        H, Min, S, S100 : HMStype;
        ML, SL         : LONGINT;
        I, M, R        : INTEGER;
        CTime, SaveTime, LastLap : LONGINT;
        SubWindowUp    : BOOLEAN;
        FirstMode      : INTEGER;
        Quit           : BOOLEAN;
        Ch, Ch2        : CHAR;
        SetFormat      : INTEGER;

        PROCEDURE OpenSubWindow(Title : TitleString);
        BEGIN
            SetBorderType(3);
            SuspendWindowEffects;
            UData^.BorderOn := FALSE;
            OpenWindow(25, 14, 55, 16, Title, SubWindow_Scheme);
            RestoreWindowEffects;
            SetBorderType(DoubleLine);
            UData^.BorderOn := TRUE;
            SubWindowUp := TRUE;
        END;

    BEGIN
        WITH UData^ DO BEGIN
            TimeFormat := Format;
            SetFormat := Format;
            FirstMode := Mode;
            LastCalcSelection := 0;
            TimeRollover := TRUE;
            SetTimerXY(37, 11);
            OrigTime := GetCurrTime;
            SeedTime := OrigTime;
            SubWindowUp := FALSE;
            OpenWindow(21, 9, 59, 17, SysMsg(000689) {' Time Calculator '} , White_Scheme);
            SetBorderColors;
            TextBackground(TimerBack);
            PaintBox(25, 10, 55, 12, TextAttr, #$20);
            TextColor(LightGray);
            DrawWideBox(25, 10, 55, 12, TextAttr);
            TimerWindowUp := FALSE; { This triggers update by UpdateTime }
            IF AlarmTime <> 0 THEN
                IF OldTime = 0 THEN BEGIN
                    TimerWindowUp := TRUE;
                    TimeFormat := 0;
                END;
            Timer := OldTime;
            InitialTime := Timer;
            NewTime := OldTime;
            DisplayTime;
            Done := FALSE;
            Menu^[1] := SysMsg(000690) {'Calculate'} ;
            Menu^[2] := SysMsg(000691) {'Stopwatch'} ;
            Menu^[3] := SysMsg(000692) {'Time/Chrono'} ;
            Menu^[4] := SysMsg(000693) {'Alarm'} ;
            Menu^[5] := SysMsg(000694) {'Set Time'} ;
            Menu^[6] := SysMsg(000695) {'Set Date'} ;
            SuspendWindowEffects;
            BorderOn := FALSE;
            OpenMenu(28, 15, 58, 15, Menu^, 6, 11, NoSort, '', '', PlainWhite_Scheme, I);
            RestoreWindowEffects;
            BorderOn := TRUE;
            SaveTime := Timer;
            WHILE NOT EscapePressed DO BEGIN
                IF FirstMode <> 0 THEN BEGIN
                    M := FirstMode;
                    FirstMode := 0;
                END
                ELSE
                    M := GetMenu;
                TimerFunc := '';
                IF (TimerWindowMode = 3) AND(TimerWindowUp) THEN BEGIN
                    IF M <> 0 THEN
                        TimerWindowMode := 1;
                    TimerWindowUp := FALSE;
                END;
                DisplayTime;
                CASE M OF
                    0 : BEGIN
                            IF SubWindowUp THEN BEGIN
                                CloseWindow;
                                ClearEscape;
                                SubWindowUp := FALSE;
                                TimerWindowUp := FALSE;
                            END;
                            Timer := SaveTime;
                            TimerFunc := '';
                            DisplayTime;
                        END;
                    1 : BEGIN     { Calculate }
                            TimerWindowUp := FALSE;
                            {        TimeFormat := SetFormat;}
                            CTime := InitialTime;
                            DisplayTime;
                            I := 0;
                            IF Mode = 1 THEN I := 5;
                            DoTimeCalculation(CTime, I);
                            Timer := CTime;
                            NewTime := Timer;
                            TimerFunc := SysMsg(000696) {'Result'} ;
                            DisplayTime;
                            IF Mode = 1 THEN
                                ForceEscape;
                        END;
                    2 : BEGIN     { Stopwatch }
                            TimerWindowMode := 1;
                            TimerWindowUp := FALSE;
                            TimeFormat := 0;
                            OpenSubWindow(SysMsg(000697) {' StopWatch '} );
                            SeedTime := GetCurrTime;
                            LastLap := 0;
                            Timer := 0;
                            TimerFunc := #$18;
                            DisplayTime;
                            TextBackground(White);
                            TextColor(Red);
                            WriteCentred(1, SysMsg(000698) {'Space Bar = Start/Stop'} );
                            WriteCentred(2, SysMsg(000699) {'ENTER = Lap,  Esc=Quit'} );
                            Quit := FALSE;
                            WHILE NOT Quit DO BEGIN
                                WHILE NOT Check4Chars DO
                                    UpdateTime(FALSE);
                                GetNextChar(Ch, Ch2);
                                IF Ch = #0 THEN
                                    Ch := Ch2;
                                CASE Ch OF
                                    Esc : BEGIN
                                              Quit := TRUE;
                                              ClearEscape;
                                              CloseWindow;
                                              SubWindowUp := FALSE;
                                              TimerWindowUp := FALSE;
                                              TimerFunc := '';
                                          END;
                                    ' ' : BEGIN
                                              IF TimerWindowUp THEN BEGIN
                                                  TimerWindowUp := FALSE;
                                              END
                                              ELSE BEGIN
                                                  SeedTime := GetCurrTime;
                                                  Timer := GetCurrTime;
                                                  LastLap := 0;
                                                  TimerWindowUp := TRUE;
                                              END;
                                          END;
                                    #$0D : BEGIN
                                               ConvertTime(Timer - LastLap, H, Min, S, S100);
                                               LastLap := Timer;
                                               WriteCentred(0,
                                               SysMsg(000700) {'Lap: '} +
                                               H + ':' +
                                               Min + ':' +
                                               S + '.' + S100);
                                           END;
                                END;
                            END;
                            TimerWindowUp := FALSE;
                            Timer := SaveTime;
                            TimeFormat := SetFormat;
                        END;
                    3 : BEGIN     { Chronograph }
                            TimerWindowMode := 2;
                            TimeFormat := 0;
                            TimerFunc := SysMsg(000701) {'Time'} ;
                            TimerWindowUp := TRUE;
                        END;
                    4 : BEGIN     { Alarm }
                            IF AlarmTime <> 0 THEN BEGIN
                                TimerWindowUp := TRUE;
                                TimeFormat := 0;
                                TimerWindowMode := 3;
                            END;
                            DoAlarmFunctions;
                        END;
                    5 : BEGIN     { Set Time }
                            IF Sys^.NovellSys THEN BEGIN
                                Menu^[1] := SysMsg(000702) {'Set Local Workstation Time'} ;
                                Menu^[2] := SysMsg(000703) {'Download Date/Time from Server'} ;
                                Menu^[3] := SysMsg(000704) {'Upload Date/Time To Server'} ;
                                OpenMenu(WinX + 6,
                                WinY + 1,
                                WinX + 42,
                                WinY + 8,
                                Menu^, 3, 30,
                                NoSort, '', '',
                                Green_Scheme, I);
                                R := GetMenu;
                                CloseWindow;
                            END
                            ELSE
                                R := 1;
                            CASE R OF
                                1 : BEGIN
                                        CTime := GetCurrTime;
                                        EscapeFlag := FALSE;
                                        GetTimeValue(SysMsg(000705) {' Workstation Time '} , CTime);
                                        IF NOT EscapeFlag THEN BEGIN
                                            DecodeTime(CTime, OH, OM, OS, OS100);
                                            SetTime(OH, OM, OS, OS100);
                                        END;
                                    END;
                                2 : BEGIN
                                        GetServerDateAndTime(Yr, Mo, Da, DW, OH, OM, OS);
                                        OS100 := 0;
                                        SetTime(OH, OM, OS, OS100);
                                        SetDate(Yr, Mo, Da);
                                    END;
                                3 : BEGIN
                                        IF NOT SetServerTimeFromWorkstation THEN
                                            I := Dialog(SysMsg(000706) {'Not a Console Operator!'} ,
                                                        SysMsg(000707) {'Set Server Time'} , Red, SysMsg(00070), '','');
                                    END;
                            END;
                        END;
                    6 : BEGIN     { Set Date }
                            TimerWindowUp := FALSE;
                            Yr := 0;
                            SelectDate(WinX - 18, WinY - 7, Yr, Mo, Da, BrightYellow_Scheme);
                            IF Yr <> 0 THEN { 0 means escape pressed }
                            BEGIN
                                BEGIN
                                    SetDate(Yr, Mo, Da);
                                    GetDate(Yr, Mo, Da, DW);
                                END;
                            END;
                        END;
                END;
            END;
            TimerWindowUp := FALSE; { This triggers update by UpdateTime }
            CloseWindow;
            CloseWindow;
            FullMouseWindow;
            NormalCursor;
        END;
    END;

    {-------------------------------------------------------}

    PROCEDURE GetNewMinSec(OldTime : WORD; VAR NewTime : WORD);
    VAR
        OH, OM, OS, OS100 : WORD;
        ML, SL         : LONGINT;
        OldT, NewT     : LONGINT;
    BEGIN
        OH := 0;
        OM := OldTime DIV 60;
        OS := OldTime MOD 60;
        ML := OM;
        SL := OS;
        OS100 := 0;
        OldT := (ML * 6000) + (SL * 100);
        GetNewTime(OldT, NewT, 2, 0); { HH:MM }
        DecodeTime(NewT, OH, OM, OS, OS100);
        NewTime := (OM * 60) + OS;
    END;

    {-------------------------------------------------------}

    PROCEDURE GetTimeResult(VAR OH, OM, OS, OS100 : WORD; Format : INTEGER);
    VAR
        OldT, NewT     : LONGINT;
    BEGIN
        EncodeTime(OH, OM, OS, OS100, OldT);
        GetNewTime(OldT, NewT, Format, 0);
        DecodeTime(NewT, OH, OM, OS, OS100);
    END;

    {-------------------------------------------------------}

    FUNCTION GetTimeFromUser : LONGINT;
    VAR
        OH, OM, OS, OS100 : WORD;
        LH, LM, LS, LS100 : LONGINT;
        OldT, NewT     : LONGINT;
    BEGIN
        EncodeTime(OH, OM, OS, OS100, OldT);
        OldT := 0;
        GetNewTime(OldT, NewT, 1, 1);
        DecodeTime(NewT, OH, OM, OS, OS100);
        LH := OH;
        LM := OM;
        LS := OS;
        NewT := (LH * 3600) + (LM * 60) + (LS);
        GetTimeFromUser := NewT;
    END;

END.

