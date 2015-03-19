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
UNIT PRINTERS;

INTERFACE
USES
    DGPRINT,
    DL6400U,
    DGHPLJ2,
    DGHPLJ3,
    DGHPLJ4,
    DGHPDJ,
    DGDJ1200,
    DG1600C,
    DGDJ5XXC,
    DGDJC,
    DG855C,
    DG8x0C,
    DGHPPRN,
    {$IFDEF ALLOWDMPRINT}
    DGEPSON,
    DGOKI,
    DGSEIK,
    {$ENDIF}
    DGHPGL,
    DGSCREEN,
    LJVAR,
    KERROR;

FUNCTION OpenPrinter(PrnInfo        : TPrnCfg;
                     VAR MyCOP      : CylonP;
                     Mode           : TxtGraf) : PPrinter;

IMPLEMENTATION

    FUNCTION OpenPrinter(PrnInfo        : TPrnCfg;
                         VAR MyCOP      : CylonP;
                         Mode           : TxtGraf) : PPrinter;
    VAR
        PP             : PPrinter;
    BEGIN
        OpenPrinter := NIL;

        CASE PrnInfo.PType OF
            NONE :
                DispErrorDeluxe('No printer selected!', 'Use config menu', FALSE, NIL);
            HPLJ2 :
                OpenPrinter := NEW(PHPLJ2, Init(PrnInfo, MyCOP, Mode));
            HPLJ3 :
                OpenPrinter := NEW(PHPLJ3, Init(PrnInfo, MyCOP, Mode));
            HPLJ4 :
                OpenPrinter := NEW(PHPLJ4, Init(PrnInfo, MyCOP, Mode));
            HPLJ4MP :
                OpenPrinter := NEW(PHPLJ4, Init(PrnInfo, MyCOP, Mode));
            {$IFDEF ALLOWDUPLEX}
            HPLJ4Dplx :
                begin
                    PP := NEW(PHPLJ4, Init(PrnInfo, MyCOP, Mode));
                    if PP <> NIL THEN
                       PP^.SetDuplexMode(TRUE);
                    OpenPrinter := PP;
                end;
            {$ENDIF}
            HPDJ :
                OpenPrinter := NEW(PHPDJ, Init(PrnInfo, MyCOP, Mode));
            HPDJC :
                OpenPrinter := NEW(PDJC, Init(PrnInfo, MyCOP, Mode));
            HPDJ5xxC :
                OpenPrinter := NEW(PDJ5XXC, Init(PrnInfo, MyCOP, Mode));
            DL6400 :
                OpenPrinter := NEW(PDl6400, Init(PrnInfo, MyCOP, Mode));
            HPDJ1200 :
                OpenPrinter := NEW(PDJ1200, Init(PrnInfo, MyCOP, Mode));
            HP1600C :
                OpenPrinter := NEW(PDJ1600, Init(PrnInfo, MyCOP, Mode));
            HP855C :
                OpenPrinter := NEW(P855C, Init(PrnInfo, MyCOP, Mode));
            HP8x0C :
                OpenPrinter := NEW(P8x0C, Init(PrnInfo, MyCOP, Mode));
            {$IFDEF ALLOWDMPRINT}
            Okidata :
                OpenPrinter := NEW(POKI, Init(PrnInfo, MyCOP, Mode));
            Epson :
                OpenPrinter := NEW(PEpson, Init(PrnInfo, MyCOP, Mode));
            Seikosha :
                OpenPrinter := NEW(PSeikosha, Init(PrnInfo, MyCOP, Mode));
            {$ENDIF}
            Screen :
                OpenPrinter := NEW(PScrnPrn, Init(PrnInfo, MyCOP, Mode));
        END;
    END;

    {--------}

END.

{--------}
{--------}
