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
UNIT DGHPLJ2;

INTERFACE
USES
    DL6400U,
    KERROR,
    LJVAR;

TYPE
    PHPLJ2         = ^THPLJ2;
    THPLJ2         = OBJECT(TDL6400)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);
                         DESTRUCTOR Done; VIRTUAL;
                     END;

IMPLEMENTATION

    CONSTRUCTOR THPLJ2.Init(PrnInfo        : TPrnCfg;
                            VAR MyCOP      : CylonP;
                            Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;

    END;

    {-----------}

    DESTRUCTOR THPLJ2.Done;
    BEGIN
        INHERITED Done;
    END;

    {-----------}

END.

    {-----------}
    {-----------}
