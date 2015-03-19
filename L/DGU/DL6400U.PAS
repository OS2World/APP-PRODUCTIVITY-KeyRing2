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
UNIT DL6400U;

INTERFACE
USES
    DGHPPRN,
    LJVAR,
    KERROR;

TYPE
    PDl6400        = ^TDL6400;
    TDL6400        = OBJECT(THPPRN)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE SelectTray(T : TLetterHeadTray); VIRTUAL;
                         PROCEDURE SetTrays(Ltr, Blnk : TLetterHeadTray); VIRTUAL;
                         PROCEDURE SelectTrayDeluxe(Tray : TPaperStyle); VIRTUAL;
                         PROCEDURE SelectTextColor(C : TPrnColors); VIRTUAL;
                         PROCEDURE SelectTextMonoChrome; VIRTUAL;
                     END;

IMPLEMENTATION

    {low level tray selection.  At this level we dont know which     }
    {tray or source has letterhead / blank paper.  Abstraction layer }
    {is in methods found below...                                    }
    PROCEDURE TDL6400.SelectTray(T : TLetterHeadTray);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {initialize the Letterhead and Blank paper trays }
    {Infer blank tray if not known                   }
    PROCEDURE TDL6400.SetTrays(Ltr, Blnk : TLetterHeadTray);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {select a paper type - letterhead or blank}
    PROCEDURE TDL6400.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {select a text color}
    PROCEDURE TDL6400.SelectTextColor(C : TPrnColors);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {force printer back into black&white text mode}
    PROCEDURE TDL6400.SelectTextMonoChrome;
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    CONSTRUCTOR TDL6400.Init(PrnInfo        : TPrnCfg;
                             VAR MyCOP      : CylonP;
                             Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;

        P1P2[EPrnTxt].TOP := 0.5;
        P1P2[EPrnTxt].Bot := 10.5;
        P1P2[EPrnTxt].LEFT := 0.25;
        P1P2[EPrnTxt].RIGHT := 8.25;
        P1P2[EPrnTxt].Driver := '_LJ';
        P1P2[EPrnGraph].Driver := '_LJ';
        P1P2[EPrnBitMap].Driver := '_LJ';
        ljCanBox := TRUE;
        IF Mode <> EPrnScreen THEN
            IF NOT AddFont(fFootnote,
                           10,
                           MyFontPath + 'TRR0000S.CWD',
                           #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                EXIT;

        SetupGD(tpcWHITE, 2);
    END;

    {-----------------}

    DESTRUCTOR TDL6400.Done;
    BEGIN
        INHERITED Done;
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}
