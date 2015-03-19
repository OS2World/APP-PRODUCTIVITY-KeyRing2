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
UNIT DG1600C;

INTERFACE
USES
    DGHPPRN,
    LJVAR,
    KERROR;

TYPE
    PDJ1600        = ^TDJ1600;
    TDJ1600        = OBJECT(THPPRN)
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
    PROCEDURE TDJ1600.SelectTray(T : TLetterHeadTray);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {initialize the Letterhead and Blank paper trays }
    {Infer blank tray if not known                   }
    PROCEDURE TDJ1600.SetTrays(Ltr, Blnk : TLetterHeadTray);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    {select a paper type - letterhead or blank}
    PROCEDURE TDJ1600.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        {this printer does not support this feature}
    END;

    {-----------------}

    CONSTRUCTOR TDJ1600.Init(PrnInfo        : TPrnCfg;
                             VAR MyCOP      : CylonP;
                             Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;

        ljIsColor := TRUE;
        P1P2[EPrnTxt].TOP := 0.6;
        P1P2[EPrnTxt].Bot := 10.5;
        P1P2[EPrnTxt].LEFT := 0.25;
        P1P2[EPrnTxt].RIGHT := 8.25;
        P1P2[EPrnTxt].Driver := '_DJC';
        P1P2[EPrnGraph].Driver := '_HGL2';
        P1P2[EPrnBitMap].Driver := '_DJC';
        PrnPlot := EPlotOrient;
        PutStr(#27'%-12345X');
        PutStr('@PJL USTATUSOFF'#13#10);
        PutStr('@PJL DEFAULT TIMEOUT = 60'#13#10);
        PutStr('@PJL DEFAULT LANGUAGE = PCL'#13#10);
        PutStr('@PJL RESET'#13#10);
        PutStr('@PJL ENTER LANGUAGE = PCL'#13#10);
        PutStr(#27'%-12345X'#13#10);
        InitJob;
        IF Mode <> EPrnScreen THEN
            IF NOT DownloadFont(fFootnote,
                                MyFontPath + 'TIR__10H.SFP',
                                10,
                                TRUE) THEN
                EXIT;
        SetupGD(tpcWHITE, 0);
    END;

    {-----------------}

    DESTRUCTOR TDJ1600.Done;
    BEGIN
        INHERITED Done;
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}
