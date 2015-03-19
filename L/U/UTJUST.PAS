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
UNIT UTJUST;
INTERFACE

TYPE
    JustT          = (ELEFT, ECENTER, ERIGHT);
    JustVT         = (ETOP, EVCENTER, EBOT);
CONST
    JustHNames     : ARRAY[JustT] OF STRING[6] =
    (
        'LEFT',
        'CENTER',
        'RIGHT'
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
