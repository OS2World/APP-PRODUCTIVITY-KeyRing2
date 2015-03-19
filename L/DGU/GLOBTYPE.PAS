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
* Global types.  Do not put vars here!
*
* ~notesend~
*
***************************************************************************

}
{$A+,B-,D+,E+,F-,G-,I+,N-,O+,P-,Q+,T-,V+,X+,Y+}
UNIT GLOBTYPE;
INTERFACE

TYPE
    JustT          = (ELEFT,      {left justify para}
                      ECENTER,    {center justify para}
                      ERIGHT,     {right justify para}
                      ESPACEPAD,
                      ELEFTRIGHT, {non-ragged margins}
                      ELEFTRIGHTINDENT); {non-ragged margins, indent first line}


    {dont change order or add anything before ETOP!}
    JustVT         = (EBOT, EVCENTER, ETOP);

CONST
    JustHNames     : ARRAY[JustT] OF STRING[6] =
    (
        'LEFT',
        'CENTER',
        'RIGHT',
        'PADDED',
        'LR',
        'LRIND'
        );
    JustVNames     : ARRAY[JustVT] OF STRING[7] =
    (
        'TOP',
        'VCENTER',
        'BOT'
        );
IMPLEMENTATION
END.
