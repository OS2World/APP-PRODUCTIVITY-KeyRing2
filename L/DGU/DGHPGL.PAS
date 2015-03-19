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
UNIT DGHPGL;
INTERFACE

USES
    DGHPPRN,
    KERROR,
    LJVAR;

TYPE
    THPGL          = OBJECT(THPPRN)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);
                         PROCEDURE PieWedge(CONST X, Y, Radius : WORD; CONST StartAngle, EndAngle, Fill : REAL); VIRTUAL;
                         PROCEDURE hpglLabel(X, Y : REAL; S : STRING); VIRTUAL;
                         PROCEDURE hpglBox(Lx, Ly, BoxW, Boxh : REAL); VIRTUAL;
                         PROCEDURE hpglLine(L1x, L1y, L2x, L2y, Width : REAL); VIRTUAL;
                         PROCEDURE hpglBlackBox(Lx, Ly, BoxW, Boxh : REAL); VIRTUAL;
                         PROCEDURE hpglWedge(XOrg, YOrg, Radius : WORD; StartAngle, EndAngle, Fill : REAL); VIRTUAL;
                         PROCEDURE hpglPointer(OrgX, OrgY, Angle, BeginAt, PLen : REAL); VIRTUAL;
                         PROCEDURE hpglPW(CONST Width : REAL); VIRTUAL;
                         PROCEDURE GraphicsTransparency(CONST On : BOOLEAN); VIRTUAL;

                     END;

IMPLEMENTATION
USES
    DGPRINT,
    OpString;

    {-------------}

    CONSTRUCTOR THPGL.Init(PrnInfo        : TPrnCfg;
                           VAR MyCOP      : CylonP;
                           Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;
    END;

    {-------------}

    PROCEDURE THPGL.hpglLabel(X, Y : REAL; S : STRING);
    BEGIN
        PutStr('SD1,21,2,1,4,18,5,0,6,0,7,52;');
        PutStr('DT~,1;');
        PutStr('PA' + Real2Str(X * 1016.0, 12, 4) + ',' + Real2Str(Y * 1016.0, 12, 4) + ';');
        PutStr('SS;');
        PutStr('LB' + S + '~');
    END;

    {-----------------}

    PROCEDURE THPGL.hpglBox(Lx, Ly, BoxW, Boxh : REAL);
    BEGIN
        PutStr('PA');
        PutStr(Real2Str(Lx * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(Ly * 1016.0, 12, 4));
        PutStr(';');
        PutStr('EA');
        PutStr(Real2Str((Lx + BoxW) * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str((Ly + Boxh) * 1016.0, 12, 4));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE THPGL.hpglLine(L1x, L1y, L2x, L2y, Width : REAL);
    BEGIN
        hpglPW(Width);
        PutStr('PU;PA');
        PutStr(Real2Str(L1x * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(L1y * 1016.0, 12, 4));
        PutStr('PD;PA');
        PutStr(Real2Str(L2x * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(L2y * 1016.0, 12, 4));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE THPGL.hpglBlackBox(Lx, Ly, BoxW, Boxh : REAL);
    BEGIN
        PutStr('PA');
        PutStr(Real2Str(Lx * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(Ly * 1016.0, 12, 4));
        PutStr(';');
        PutStr('FT1;');
        PutStr('RA');
        PutStr(Real2Str((Lx + BoxW) * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str((Ly + Boxh) * 1016.0, 12, 4));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE THPGL.hpglWedge(XOrg, YOrg, Radius : WORD; StartAngle, EndAngle, Fill : REAL);
    VAR
        Rx             : REAL;
        RY             : REAL;
        RRadius        : REAL;
    BEGIN
        {Fudges to work with GPU small-page origins}
        XOrg := XOrg + 600;
        {
        yorg := yorg + 460;
        }

        {Conversions}
        Rx := (XOrg / 300.0) + 0.75;
        RY := 9.30 - (YOrg / 300.0);
        RRadius := Radius / 300.0;

        PutStr('PA');
        PutStr(Real2Str(Rx * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(RY * 1016.0, 12, 4));
        PutStr(';');
        PutStr('FT10,');
        PutStr(Real2Str(Fill, 12, 4));
        PutStr(';');
        PutStr('WG');
        PutStr(Real2Str(RRadius * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(StartAngle, 12, 4));
        PutStr(',');
        PutStr(Real2Str(EndAngle - StartAngle, 12, 4));
        PutStr(';');
        PutStr('EW');
        PutStr(Real2Str(RRadius * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(StartAngle, 12, 4));
        PutStr(',');
        PutStr(Real2Str(EndAngle - StartAngle, 12, 4));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE THPGL.hpglPointer(OrgX, OrgY, Angle, BeginAt, PLen : REAL);
    CONST
        P180           = PI / 180.0;
    BEGIN
        PutStr('PA');
        PutStr(Real2Str(OrgX * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(OrgY * 1016.0, 12, 4));
        PutStr(';');
        PutStr('PU;');
        PutStr('PR');
        PutStr(Real2Str(COS(P180 * Angle) * BeginAt * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(SIN(P180 * Angle) * BeginAt * 1016.0, 12, 4));
        PutStr(';');
        PutStr('PD;');
        PutStr('PR');
        PutStr(Real2Str(COS(P180 * Angle) * PLen * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(SIN(P180 * Angle) * PLen * 1016.0, 12, 4));
        PutStr(';');
        PutStr('PU;');
    END;

    {-----------------}

    PROCEDURE THPGL.PieWedge(CONST X, Y, Radius : WORD; CONST StartAngle, EndAngle, Fill : REAL);
        {-Print a pie wedge }

        PROCEDURE PutReal(CONST R : REAL; CONST MoreParms : BOOLEAN);
        BEGIN
            PutStr(PrnRealStr(R));
            IF MoreParms THEN
                PutStr(',')
            ELSE
                PutStr(';');
        END;

    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PutStr('PA');
        PutReal(X, TRUE);
        PutReal(Y, FALSE);

        PutStr('FT10,');
        PutReal(Fill, FALSE);

        PutStr('WG');
        PutReal(Radius, TRUE);
        PutReal(StartAngle, TRUE);
        PutReal(EndAngle - StartAngle, FALSE);

        PutStr('EW');
        PutReal(Radius, TRUE);
        PutReal(StartAngle, TRUE);
        PutReal(EndAngle - StartAngle, FALSE);
    END;

    {-----------------}

    PROCEDURE THPGL.hpglPW(CONST Width : REAL);
        {-Set the width of the HPGL/2 pen }
    BEGIN
        PutStr('PW');
        PutStr(PrnRealStr(Width));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE THPGL.GraphicsTransparency(CONST On : BOOLEAN);
        {-Set the HPGL/2 transparency mode on or off }
    BEGIN
        IF On THEN
            PutStr('TR1;')
        ELSE
            PutStr('TR0;');
    END;

    {-----------------}

END.
