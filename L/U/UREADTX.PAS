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
{$A-,R-,S-,V-,O+,F+}

Unit UReadTx;

interface

uses
  OpCrt,
  Umoveops,
  Urline,
  UReaders;

Procedure ReadFile(FileName: String);

implementation

CONST
  FileBufSize = 4096 * 2;

VAR
  V : Reader;
  Fn : string[66];


Procedure ReadFile(FileName: String);
BEGIN
  Window(1,2,80,25);
  clrscr;
  Window(1,1,80,25);
  Fn := FileName;

  if not v.init(Fn,FileBufSize,1,3,80,25)
  then BEGIN
    halt(1);
  END;

  with v do BEGIN
    checkrferror;
    tofl;
    while scrollselect <> #27 do;
    done;
    clrscr;
  END;
End;

END.
