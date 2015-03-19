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
* Seikosha in IBM Proprinter mode
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F-,G-,I+,N-,O+,P-,Q+,T-,V+,X+,Y+}
UNIT DGSEIK;

INTERFACE
USES
    DGPRINT,
    KERROR,
    LJVAR;

TYPE
    PSeikosha      = ^TSeikosha;
    TSeikosha      = OBJECT(TPrinter)
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

    CONSTRUCTOR TSeikosha.Init(PrnInfo        : TPrnCfg;
                               VAR MyCOP      : CylonP;
                               Mode           : TxtGraf);
    CONST
        Rst            = #27'@'#27'R'#0;
        Ul             = $80;
        IT             = $40;
        DW             = $20;
        Ds             = $10;
        EM             = $8;
        CD             = $4;
        PR             = $2;
        EL             = $1;

        MD             = #27'!';
        CPI5           = DW;
        CPI10          = 0;
        CPI12          = EL;
        CPI17          = CD;
        CPI20          = EL + CD;

        tULOn          = #27'-1';
        tULOff         = #27'-0';
        tBoldOn        = #27'E';
        tBoldOff       = #27'F';
        tItalOn        = '';      {cant do italic with control chars }
        tItalOff       = '';      {gotta use escape bang n           }
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;

        P1P2[EPrnTxt].TOP := 0.5;
        P1P2[EPrnTxt].Bot := 10.5;
        P1P2[EPrnTxt].LEFT := 0.25;
        P1P2[EPrnTxt].RIGHT := 8.25;
        P1P2[EPrnTxt].Driver := '_ESCP2';
        P1P2[EPrnGraph].Driver := '_ESCP2';
        P1P2[EPrnBitMap].Driver := '_ESCP2';
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
                       MyFontPath + 'seikmed.cwd', MD + CHAR(CPI12)) THEN
            EXIT;

        IF NOT AddFont(fSmall, 3.6,
                       MyFontPath + 'seiksml.cwd', MD + CHAR(CPI20)) THEN
            EXIT;

        IF NOT AddFont(fMain, 7.2,
                       MyFontPath + 'seikmed.cwd', MD + CHAR(CPI10)) THEN
            EXIT;

        IF NOT AddFont(fItalic, 7.2,
                       MyFontPath + 'seikmed.cwd', MD + CHAR(CPI10 + IT)) THEN
            EXIT;

        IF NOT AddFont(fBoldItalic, 7.2,
                       MyFontPath + 'seikmed.cwd', MD + CHAR(CPI10 + EM + IT)) THEN
            EXIT;

        IF NOT AddFont(fBold, 7.2,
                       MyFontPath + 'seikmed.cwd', MD + CHAR(CPI10 + EM)) THEN
            EXIT;

        IF NOT AddFont(fTable, 4.2352,
                       MyFontPath + 'seiksml.cwd', MD + CHAR(CPI17)) THEN
            EXIT;

        IF NOT AddFont(fHuge, 14.4,
                       MyFontPath + 'seiklrg.cwd', MD + CHAR(CPI5)) THEN
            EXIT;


        IF NOT AddFont(fHugeItalic, 14.4,
                       MyFontPath + 'seiklrg.cwd', MD + CHAR(CPI5 + IT)) THEN
            EXIT;

        IF NOT AddFont(fMainMedium, 4.2352,
                       MyFontPath + 'seiksml.cwd', MD + CHAR(CPI17)) THEN
            EXIT;

        IF NOT AddFont(fItalicMedium, 4.2352,
                       MyFontPath + 'seiksml.cwd',
                       MD + CHAR(CPI17 + IT)) THEN
            EXIT;

        IF NOT AddFont(fBoldMedium, 4.2352,
                       MyFontPath + 'seiksml.cwd', MD + CHAR(CPI17 + EM)) THEN
            EXIT;

        IF NOT AddFont(fCourier, 7.2,
                       MyFontPath + 'seikmed.cwd', MD + CHAR(CPI10)) THEN
            EXIT;

        ljActiveFont := FindFontByID(fMain);
    END;

    {----------}

    DESTRUCTOR TSeikosha.Done;
    BEGIN
        INHERITED Done;
    END;

    {----------}

    FUNCTION TSeikosha.GetDevName : STRING;
    BEGIN
        GetDevName := '';
    END;

    {----------}

    {-Enter HPGL/2 graphics mode }
    PROCEDURE TSeikosha.GoHPGL;
    BEGIN
    END;

    {----------}

    {-Return to PCL command mode }
    PROCEDURE TSeikosha.GoPCL;
    BEGIN
    END;

    {----------}

    {-Reset the printer}
    PROCEDURE TSeikosha.ResetPrn;
    BEGIN
        PutStr(ljInitStr^);
    END;

    {----------}

    {-Update the cursor position...X and Y specified in inches }
    FUNCTION TSeikosha.PrnGotoXY(CONST X, Y : REAL) : BOOLEAN;
    BEGIN
        PrnGotoXY := FALSE;
        IF NOT PrnGotoY(Y) THEN
            EXIT;
        PrnGotoXY := PrnGotoX(X);
    END;

    {----------}

    {-Update the horizontal cursor position }
    FUNCTION TSeikosha.PrnGotoX(CONST X : REAL) : BOOLEAN;
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
    FUNCTION TSeikosha.PrnGotoY(CONST Y : REAL) : BOOLEAN;
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
    FUNCTION TSeikosha.PrnAdvanceY(CONST Delta : REAL) : BOOLEAN;
    BEGIN
        PrnAdvanceY := PrnGotoY(Delta + CurRow);
    END;

    {----------}

    PROCEDURE TSeikosha.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        {do nothing function}
    END;

    {----------}

    {select a text color}
    PROCEDURE TSeikosha.SelectTextColor(C : TPrnColors);
    BEGIN
    END;

    {----------}

    {force printer back into black&white text mode}
    PROCEDURE TSeikosha.SelectTextMonoChrome;
    BEGIN
    END;

    {----------}

    PROCEDURE TSeikosha.SetFormLen(CONST L : LONGINT);
    BEGIN
        PutStr(#27'C' + CHR(L));
    END;

END.
    {-----------}
    {-----------}
