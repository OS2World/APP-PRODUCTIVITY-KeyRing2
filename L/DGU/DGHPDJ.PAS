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
UNIT DGHPDJ;
INTERFACE
USES
    DGHPPRN,
    LJVAR,
    KERROR;

TYPE
    PHPDJ          = ^THPDJ;
    THPDJ          = OBJECT(THPPRN)
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
    PROCEDURE THPDJ.SelectTray(T : TLetterHeadTray);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {initialize the Letterhead and Blank paper trays }
    {Infer blank tray if not known                   }
    PROCEDURE THPDJ.SetTrays(Ltr, Blnk : TLetterHeadTray);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {select a paper type - letterhead or blank}
    PROCEDURE THPDJ.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {select a text color}
    PROCEDURE THPDJ.SelectTextColor(C : TPrnColors);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {force printer back into black&white text mode}
    PROCEDURE THPDJ.SelectTextMonoChrome;
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    CONSTRUCTOR THPDJ.Init(PrnInfo        : TPrnCfg;
                           VAR MyCOP      : CylonP;
                           Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;

        FILLCHAR(MyWheel, SIZEOF(MyWheel), CHAR(tpcWHITE));

        P1P2[EPrnTxt].TOP := 0.6;
        P1P2[EPrnTxt].Bot := 10.5;
        P1P2[EPrnTxt].LEFT := 0.25;
        P1P2[EPrnTxt].RIGHT := 8.25;
        P1P2[EPrnTxt].Driver := '_DJ';
        P1P2[EPrnGraph].Driver := '_DJ';
        P1P2[EPrnBitMap].Driver := '_DJ';
        FlakeyMixedTextGraph := TRUE;
        IF Mode <> EPrnScreen THEN
            IF NOT DownloadFont(fFootnote,
                                MyFontPath + 'TIR__10H.SFP',
                                10,
                                TRUE) THEN

                EXIT;
    END;

    {-----------------}

    DESTRUCTOR THPDJ.Done;
    BEGIN
        INHERITED Done;
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}
