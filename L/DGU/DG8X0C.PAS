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
UNIT DG8x0C;

INTERFACE
USES
    DGHPPRN,
    LJVAR,
    KERROR;

TYPE
    P8x0C          = ^T8x0C;
    T8x0C          = OBJECT(THPPRN)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE SelectTray(T : TLetterHeadTray); VIRTUAL;
                         PROCEDURE SetTrays(Ltr, Blnk : TLetterHeadTray); VIRTUAL;
                         PROCEDURE SelectTrayDeluxe(Tray : TPaperStyle); VIRTUAL;
                     END;

IMPLEMENTATION

    {low level tray selection.  At this level we dont know which     }
    {tray or source has letterhead / blank paper.  Abstraction layer }
    {is in methods found below...                                    }
    PROCEDURE T8x0C.SelectTray(T : TLetterHeadTray);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {initialize the Letterhead and Blank paper trays }
    {Infer blank tray if not known                   }
    PROCEDURE T8x0C.SetTrays(Ltr, Blnk : TLetterHeadTray);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {select a paper type - letterhead or blank}
    PROCEDURE T8x0C.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    CONSTRUCTOR T8x0C.Init(PrnInfo        : TPrnCfg;
                           VAR MyCOP      : CylonP;
                           Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;

        ljIsColor := TRUE;
        FlakeyMixedTextGraph := TRUE;
        P1P2[EPrnTxt].TOP := 0.5;
        P1P2[EPrnTxt].Bot := 10.25; {10.5 zzzz 09011998}
        P1P2[EPrnTxt].LEFT := 0.25;
        P1P2[EPrnTxt].RIGHT := 8.25;
        P1P2[EPrnTxt].Driver := '_LJ4';
        P1P2[EPrnGraph].Driver := '_DJC';
        P1P2[EPrnBitMap].Driver := '_DJC';

        IF Mode <> EPrnScreen THEN
            IF NOT DownloadFont(fFootnote,
                                MyFontPath + 'TIR__10H.SFP',
                                10,
                                TRUE) THEN
                EXIT;
        SetupGD(tpcWHITE, 0);
    END;

    {-----------------}

    DESTRUCTOR T8x0C.Done;
    BEGIN
        INHERITED Done;
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}
