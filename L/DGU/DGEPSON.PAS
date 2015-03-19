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
{$A+,B-,D+,E+,F-,G-,I+,N-,O+,P-,Q+,T-,V+,X+,Y+}
UNIT DGEPSON;

INTERFACE
USES
    DGPRINT,
    KERROR,
    LJVAR;

TYPE
    PEpson         = ^TEpson;
    TEpson         = OBJECT(TPrinter)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);

                         DESTRUCTOR Done; VIRTUAL;

                         FUNCTION GetDevName : STRING; VIRTUAL;

                             {-Enter HPGL/2 graphics mode }
                         PROCEDURE GoHPGL; VIRTUAL;

                             {-Return to PCL command mode }
                         PROCEDURE GoPCL; VIRTUAL;

                             {-Reset the printer}
                         PROCEDURE ResetPrn; VIRTUAL;

                             {-Update the cursor position...X and Y specified in inches }
                         FUNCTION PrnGotoXY(CONST X, Y : REAL) : BOOLEAN; VIRTUAL;

                             {-Update the horizontal cursor position }
                         FUNCTION PrnGotoX(CONST X : REAL) : BOOLEAN; VIRTUAL;

                             {-Update the vertical cursor position }
                         FUNCTION PrnGotoY(CONST Y : REAL) : BOOLEAN; VIRTUAL;

                             {-Advance the Y cursor by Delta inches }
                         FUNCTION PrnAdvanceY(CONST Delta : REAL) : BOOLEAN; VIRTUAL;

                         PROCEDURE SelectTrayDeluxe(Tray : TPaperStyle); VIRTUAL;

                             {select a text color}
                         PROCEDURE SelectTextColor(C : TPrnColors); VIRTUAL;

                             {force printer back into black&white text mode}
                         PROCEDURE SelectTextMonoChrome; VIRTUAL;

                         PROCEDURE SetFormLen(CONST L : LONGINT); VIRTUAL;

                     END;

IMPLEMENTATION
USES
    OpString;

CONST
    HPI            = 60.0;        {X}
    HPMAX          = $FFFF;

    VPI            = 216.0;       {Y}
    VPMAX          = $FF;

    {------------}

    CONSTRUCTOR TEpson.Init(PrnInfo        : TPrnCfg;
                            VAR MyCOP      : CylonP;
                            Mode           : TxtGraf);
    CONST
        Rst            = #27'@'#27'R'#0#27'6'#27't'#1;
        CPI5           = #27'P'#18#27'W'#1; {pica,wide}
        CPI10          = #27'P'#18#27'W'#0; {pica norm}
        CPI12          = #27'M'#18#27'W'#0; {elite norm}
        CPI17          = #27'P'#15#27'W'#0; {pica condensed}
        CPI20          = #27'M'#15#27'W'#0; {elite condensed}
        tULOn          = #27'-1';
        tULOff         = #27'-0';
        tBoldOn        = #27'E';
        tBoldOff       = #27'F';
        tItalOn        = #27'4';
        tItalOff       = #27'5';
        AllOff         = tULOff + tBoldOff + tItalOff;

    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;

        P1P2[EPrnTxt].TOP := 0.5;
        P1P2[EPrnTxt].Bot := 10.5;
        P1P2[EPrnTxt].LEFT := 0.25;
        P1P2[EPrnTxt].RIGHT := 8.25;
        P1P2[EPrnTxt].Driver := '_FX';
        P1P2[EPrnGraph].Driver := '_FX';
        P1P2[EPrnBitMap].Driver := '_FX';
        SetupGD(tpcWHITE, 2);

        ljInitStr := StringToHeap(Rst);
        ljULOn := StringToHeap(tULOn);
        ljULOff := StringToHeap(tULOff);
        ljBoldOn := StringToHeap(tBoldOn);
        ljBoldOff := StringToHeap(tBoldOff);
        ljItalOn := StringToHeap(tItalOn);
        ljItalOff := StringToHeap(tItalOff);
        ljNewPage := StringToHeap(^L);

        IF NOT AddFont(fLinePrint, 6.0,
                       MyFontPath + 'seikmed.cwd', CPI12 + AllOff) THEN
            EXIT;

        IF NOT AddFont(fSmall, 3.6,
                       MyFontPath + 'seiksml.cwd', CPI20 + AllOff) THEN
            EXIT;

        IF NOT AddFont(fMain, 7.2,
                       MyFontPath + 'seikmed.cwd', CPI10 + AllOff) THEN
            EXIT;

        IF NOT AddFont(fItalic, 7.2,
                       MyFontPath + 'seikmed.cwd', CPI10 + AllOff + ljItalOn^) THEN
            EXIT;

        IF NOT AddFont(fBoldItalic, 7.2,
                       MyFontPath + 'seikmed.cwd', CPI10 + AllOff + ljItalOn^) THEN
            EXIT;

        IF NOT AddFont(fBold, 7.2,
                       MyFontPath + 'seikmed.cwd', CPI10 + AllOff + ljBoldOn^) THEN
            EXIT;

        IF NOT AddFont(fTable, 4.2352,
                       MyFontPath + 'seiksml.cwd', CPI17 + AllOff) THEN
            EXIT;

        IF NOT AddFont(fHuge, 14.4,
                       MyFontPath + 'seiklrg.cwd', CPI5 + AllOff) THEN
            EXIT;


        IF NOT AddFont(fHugeItalic, 14.4,
                       MyFontPath + 'seiklrg.cwd', CPI5 + AllOff + ljItalOn^) THEN
            EXIT;

        IF NOT AddFont(fMainMedium, 4.2352,
                       MyFontPath + 'seiksml.cwd', CPI17 + AllOff) THEN
            EXIT;

        IF NOT AddFont(fItalicMedium, 4.2352,
                       MyFontPath + 'seiksml.cwd',
                       CPI17 + ljItalOn^) THEN
            EXIT;

        IF NOT AddFont(fBoldMedium, 4.2352,
                       MyFontPath + 'seiksml.cwd', CPI17 + AllOff + ljBoldOn^) THEN
            EXIT;

        IF NOT AddFont(fCourier, 7.2,
                       MyFontPath + 'seikmed.cwd', CPI10 + AllOff) THEN
            EXIT;

        ljActiveFont := FindFontByID(fMain);
    END;

    {----------}

    DESTRUCTOR TEpson.Done;
    BEGIN
        INHERITED Done;
    END;

    {----------}

    FUNCTION TEpson.GetDevName : STRING;
    BEGIN
        GetDevName := '';
    END;

    {----------}

    {-Enter HPGL/2 graphics mode }
    PROCEDURE TEpson.GoHPGL;
    BEGIN
    END;

    {----------}

    {-Return to PCL command mode }
    PROCEDURE TEpson.GoPCL;
    BEGIN
    END;

    {----------}

    {-Reset the printer}
    PROCEDURE TEpson.ResetPrn;
    BEGIN
        PutStr(ljInitStr^);
    END;

    {----------}

    {-Update the cursor position...X and Y specified in inches }
    FUNCTION TEpson.PrnGotoXY(CONST X, Y : REAL) : BOOLEAN;
    BEGIN
        PrnGotoXY := FALSE;
        IF NOT PrnGotoY(Y) THEN
            EXIT;
        PrnGotoXY := PrnGotoX(X);
    END;

    {----------}

    {-Update the horizontal cursor position }
    FUNCTION TEpson.PrnGotoX(CONST X : REAL) : BOOLEAN;
    VAR
        Delta          : REAL;
        Strg           : STRING;
    BEGIN
        Delta := X;
        Delta := Delta * HPI;
        Strg := '';
        PrnGotoX := TRUE;
        IF Delta > 0 THEN BEGIN
            WHILE Delta >= 0 DO BEGIN
                IF Delta <= HPMAX THEN BEGIN
                    Strg := #27'$' + CHAR(ROUND(Delta) MOD 255) + CHAR(ROUND(Delta) DIV 255);
                    PrnGotoX := PutStr(Strg);
                    BREAK;
                END
                ELSE BEGIN
                    Strg := #27'$' + CHAR($FF) + CHAR($FF);
                    PrnGotoX := PutStr(Strg);
                    Delta := Delta - VPMAX;
                END;
            END;
        END;
        CurColumn := X;
    END;

    {----------}

    {-Update the vertical cursor position }
    FUNCTION TEpson.PrnGotoY(CONST Y : REAL) : BOOLEAN;
    VAR
        Delta          : REAL;
        Strg           : STRING;
    BEGIN
        IF ABS(Y - CurRow) < 0.001 THEN
            EXIT;

        Delta := Y - CurRow;
        Delta := Delta * VPI;
        Strg := '';
        PrnGotoY := FALSE;
        IF Delta > 0 THEN BEGIN
            {move paper forewards}
            WHILE Delta >= 0 DO BEGIN
                IF Delta <= VPMAX THEN BEGIN
                    Strg := ' '#27'J' + CHAR(ROUND(Delta));
                    PrnGotoY := PutStr(Strg);
                    BREAK;
                END
                ELSE BEGIN
                    Strg := ' '#27'J' + CHAR(VPMAX);
                    PrnGotoY := PutStr(Strg);
                    Delta := Delta - VPMAX;
                END;
            END;
        END
        ELSE BEGIN
            {move paper backwards}
            WHILE Delta < 0 DO BEGIN
                IF ABS(Delta) <= VPMAX THEN BEGIN
                    Strg := ' '#27'j' + CHAR(ROUND(Delta));
                    PrnGotoY := PutStr(Strg);
                    BREAK;
                END
                ELSE BEGIN
                    Strg := ' '#27'j' + CHAR(VPMAX);
                    PrnGotoY := PutStr(Strg);
                    Delta := Delta + VPMAX;
                END;
            END;
        END;
        CurRow := Y;
    END;

    {----------}

    {-Advance the Y cursor by Delta inches }
    FUNCTION TEpson.PrnAdvanceY(CONST Delta : REAL) : BOOLEAN;
    BEGIN
        PrnAdvanceY := PrnGotoY(Delta + CurRow);
    END;

    {----------}

    PROCEDURE TEpson.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        {do nothing function}
    END;

    {----------}

    {select a text color}
    PROCEDURE TEpson.SelectTextColor(C : TPrnColors);
    BEGIN
    END;

    {----------}

    {force printer back into black&white text mode}
    PROCEDURE TEpson.SelectTextMonoChrome;
    BEGIN
    END;

    {----------}

    PROCEDURE TEpson.SetFormLen(CONST L : LONGINT);
    BEGIN
        PutStr(#27'C' + CHR(L));
    END;

END.
    {-----------}
    {-----------}
