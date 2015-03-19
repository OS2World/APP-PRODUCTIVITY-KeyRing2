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
UNIT DGHPLJ4;

INTERFACE
USES
    DGHPPRN,
    LJVAR,
    KERROR;

TYPE
    PHPLJ4         = ^THPLJ4;
    THPLJ4         = OBJECT(THPPRN)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE SelectTextColor(C : TPrnColors); VIRTUAL;
                         PROCEDURE SelectTextMonoChrome; VIRTUAL;
                         PROCEDURE SetDuplexMode(Mode : BOOLEAN); VIRTUAL;
                     END;

IMPLEMENTATION

    {select a text color}
    PROCEDURE THPLJ4.SelectTextColor(C : TPrnColors);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {force printer back into black&white text mode}
    PROCEDURE THPLJ4.SelectTextMonoChrome;
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    CONSTRUCTOR THPLJ4.Init(PrnInfo        : TPrnCfg;
                            VAR MyCOP      : CylonP;
                            Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;
        FILLCHAR(MyWheel, SIZEOF(MyWheel), CHAR(tpcWHITE));

        P1P2[EPrnTxt].TOP := 0.5;
        P1P2[EPrnTxt].Bot := 10.5;
        P1P2[EPrnTxt].LEFT := 0.25;
        P1P2[EPrnTxt].RIGHT := 8.25;
        ljCanBox := TRUE;
        ljCanHpgl := TRUE;
        P1P2[EPrnTxt].Driver := '_LJ4';
        P1P2[EPrnGraph].Driver := '_HGL2';
        P1P2[EPrnBitMap].Driver := '_LJ';
        PrnPlot := EPlotOrient;

        PutStr(#27'%-12345X');
        PutStr('@PJL USTATUSOFF'#13#10);
        PutStr('@PJL DEFAULT TIMEOUT = 60'#13#10);
        PutStr('@PJL DEFAULT LANGUAGE = PCL'#13#10);
        PutStr('@PJL RESET'#13#10);
        PutStr('@PJL ENTER LANGUAGE = PCL'#13#10);
        PutStr(#27'%-12345X'#13#10);

        IF Mode <> EPrnScreen THEN
            IF NOT AddFont(fFootnote,
                           10,
                           MyFontPath + 'TRR0000S.CWD',
                           #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                EXIT;
    END;

    {-----------------}

    PROCEDURE THPLJ4.SetDuplexMode(Mode : BOOLEAN);
    BEGIN
        IF Mode THEN
            PutStr(#27'&l1S')
        ELSE
            PutStr(#27'&l0S');
        ljDuplex := Mode;
    END;

    {-----------------}

    DESTRUCTOR THPLJ4.Done;
    BEGIN
        INHERITED Done;
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}
