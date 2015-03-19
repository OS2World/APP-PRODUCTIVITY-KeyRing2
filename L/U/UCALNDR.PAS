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
{$A-,V-,O+,F+}

UNIT UCalndr;

INTERFACE
USES
    UGlobal;


PROCEDURE Draw_Calendar(Y, M, D : INTEGER; X, Z : BYTE);
PROCEDURE SelectDate(X, Y           : BYTE;
                     VAR Iyer, Imth, Iday : WORD;
                     Cscheme        : ColorSetProc);
PROCEDURE CloseCalendar;

CONST EraseCalendarWhenDone : BOOLEAN = TRUE;

IMPLEMENTATION

USES
    Dos,
    OpCrt,
    OpString,
    OpFrame,
    OpWindow,
    OpCmd,
    OpDrag,
    OpDate,
    OpCal,
    UCOLORS,
    UWindow;

CONST
    Calndr         : CalendarPtr = NIL;
VAR
    CalOpts        : LONGINT;

    PROCEDURE Draw_Calendar(Y, M, D : INTEGER; X, Z : BYTE);
    BEGIN
        NEW(Calndr, InitCustom(X, Z, DefLeftTee, DefCrossbar, DefRightTee,
                               NENColorSet, CalOpts));
        IF Calndr = NIL THEN
            EXIT;
        WITH Calndr^ DO BEGIN
            IF Y <> 0 THEN
                SetCurrentDMY(D, M, Y);
        END;
        CustomizeWindow(Calndr^, ' Calendar ', 10);
        AddScrollBars(Calndr^, TRUE);
        CustomizeCommandProcessor(CalCommands);
        Calndr^.Draw;
    END;

    PROCEDURE SelectDate(X, Y           : BYTE;
                         VAR Iyer, Imth, Iday : WORD;
                         Cscheme        : ColorSetProc);
    VAR
        Quit       : BOOLEAN;
    BEGIN
        CalOpts := DefWindowOptions OR wAltFrame OR wResizeable;
        Cscheme;
        IF Calndr = NIL THEN
            Draw_Calendar(Iyer, Imth, Iday, X, Y);

        IF Calndr = NIL THEN BEGIN
            Iyer := 0;
            EXIT;
        END;

        WITH Calndr^ DO BEGIN
            Quit := FALSE;
            WHILE NOT Quit DO BEGIN
                Process;
                CASE GetLastCommand OF
                    ccMouseDown,
                    ccMouseSel :
                        {did user click on the hot spot for closing?}
                        IF HandleMousePress(Calndr^) = hsRegion3 THEN BEGIN
                            WaitForButtonUp;
                            ClearMouseEvents;
                            Iyer := 0;
                            Quit := TRUE;
                        END;
                    ccSelect : BEGIN
                                   DateToDMY(GetCurrentDate,
                                             INTEGER(Iday), INTEGER(Imth), INTEGER(Iyer));
                                   Quit := TRUE;
                               END;
                    ccError,
                    ccQuit : BEGIN
                                 Iyer := 0;
                                 Quit := TRUE;
                             END;
                    ccUser40 : IF NOT KeyboardMove(Calndr^) THEN RingBell;
                    ccUser41 : BEGIN
                                   IF NOT ToggleZoom(Calndr^) THEN RingBell;
                               END;
                    ccUser42 : BEGIN
                                   IF NOT KeyboardResize(Calndr^) THEN RingBell;
                               END;
                END;
            END;
        END;
        IF EraseCalendarWhenDone THEN
            CloseCalendar;
    END;

    PROCEDURE CloseCalendar;
    BEGIN
        Calndr^.ERASE;
        DISPOSE(Calndr, Done);
        Calndr := NIL;
        Window(1, 1, 80, 25);
    END;

END.


