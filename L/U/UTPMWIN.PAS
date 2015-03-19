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
* Global types and constants for windows and Pmode.  Do not put typed
* constants, startup code, vars or non-essential unit dependencies here!
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
UNIT UTPMWIN;
INTERFACE
    {$IFDEF WINDOWS}
    {$DEFINE DPMIorWIN}
{$ENDIF}
    {$IFDEF DPMI}
    {$DEFINE DPMIorWIN}
{$ENDIF}
    {$IFDEF DPMIorWIN}
    TYPE
        PathStr = STRING[79];
{$ENDIF}
IMPLEMENTATION
END.
