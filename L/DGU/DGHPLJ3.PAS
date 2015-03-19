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
UNIT DGHPLJ3;

INTERFACE
USES
    DGHPPRN,
    LJVAR,
    KERROR;

TYPE
    PHPLJ3         = ^THPLJ3;
    THPLJ3         = OBJECT(THPPRN)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE SelectTextColor(C : TPrnColors); VIRTUAL;
                         PROCEDURE SelectTextMonoChrome; VIRTUAL;
                     END;

IMPLEMENTATION

    {select a text color}
    PROCEDURE THPLJ3.SelectTextColor(C : TPrnColors);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {force printer back into black&white text mode}
    PROCEDURE THPLJ3.SelectTextMonoChrome;
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    CONSTRUCTOR THPLJ3.Init(PrnInfo        : TPrnCfg;
                            VAR MyCOP      : CylonP;
                            Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;
        P1P2[EPrnTxt].TOP := 0.5;
        P1P2[EPrnTxt].Bot := 10.5;
        P1P2[EPrnTxt].LEFT := 0.25;
        P1P2[EPrnTxt].RIGHT := 8.25;
        P1P2[EPrnTxt].Driver := '_LJ3R';
        P1P2[EPrnGraph].Driver := '_HGL2';
        P1P2[EPrnBitMap].Driver := '_LJ';
        ljCanBox := TRUE;
        PrnPlot := EPlotOrient;

        IF Mode <> EPrnScreen THEN
            IF NOT AddFont(fFootnote,
                           10,
                           MyFontPath + 'TRR0000S.CWD',
                           #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                EXIT;
        SetupGD(tpcWHITE, 2);
    END;

    {-----------------}

    DESTRUCTOR THPLJ3.Done;
    BEGIN
        INHERITED Done;
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}
