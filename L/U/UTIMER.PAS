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
UNIT UTIMER;

INTERFACE

CONST
    TimerVisible   : BOOLEAN = FALSE;


PROCEDURE ResetTimer;
PROCEDURE DrawTimer;
PROCEDURE StartTimer;
PROCEDURE StopTimer;
PROCEDURE ReStartTimer;
PROCEDURE EraseTimer;

    {--------------------------------------------------------------------}
IMPLEMENTATION

USES
    OpCrt,
    UColors,
    UGLOBAL,
    ULib,
    UMSg,
    UWindow;
    {--------------------------------------------------------------------}


    PROCEDURE ResetTimer;
    BEGIN
        WITH UData^ DO BEGIN
            IF SecurityClearance < 2 THEN EXIT;
            TimerWindowMode := 1;
            SeedTime := GetCurrTime;
            Timer := GetCurrTime;
            IF TimerWindowUp THEN
                UpdateTimeWindow;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DrawTimer;
    VAR 
        Atr        : BYTE;
    BEGIN
        WITH UData^ DO BEGIN
            IF SecurityClearance < 2 THEN EXIT;
            Atr := TextAttr;
            OpenWindow(40, 18, 70, 20, SysMsg(1916) {'Search Time'} , Gray_Scheme);
            PaintBox(40, 18, 70, 20, Attr(Black, Green), #$20);
            IF CurrentDisplay = MonoHerc THEN
                DrawWideBox(40, 18, 70, 20, Attr(Mono_Black, Mono_White))
            ELSE
                DrawWideBox(40, 18, 70, 20, Attr(Black, DarkGray));
            TimerBack := Black;
            TimerColor := LightRed;
            SetTimerXY(51, 19);
            TimerWindowMode := 1;
            TimeFormat := 0;
            Timer := 0;
            TimerWindowUp := FALSE;
            TimerVisible := TRUE;
            TimerFunc := #$20;
            ResetTimer;
            TextAttr := Atr;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE StartTimer;
    BEGIN
        WITH UData^ DO BEGIN
            IF SecurityClearance < 2 THEN EXIT;
            TimerWindowMode := 1;
            TimeFormat := 0;
            TimerFunc := #$18;
            SeedTime := GetCurrTime;
            Timer := GetCurrTime;
            TimerWindowUp := TRUE;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE StopTimer;
    BEGIN
        WITH UData^ DO BEGIN
            IF SecurityClearance < 2 THEN EXIT;
            TimerFunc := #$20;
            IF TimerWindowUp THEN
                UpdateTimeWindow;
            TimerWindowUp := FALSE;
            TimerWindowMode := 1;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ReStartTimer;
    BEGIN
        WITH UData^ DO BEGIN
            IF SecurityClearance < 2 THEN EXIT;
            TimerWindowMode := 1;
            TimeFormat := 0;
            TimerFunc := #$18;
            TimerWindowUp := TRUE;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE EraseTimer;
    BEGIN
        WITH UData^ DO BEGIN
            IF NOT TimerVisible THEN EXIT;
            TimerWindowUp := FALSE;
            TimerVisible := FALSE;
            CloseWindow;
        END;
    END;

END.
{--------------------------------------------------------------------}
{--------------------------------------------------------------------}

