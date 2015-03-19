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
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,R-,S-,V-,O+,F+}

Unit ULng;   { Select & Load Language file }

interface

Uses
  Dos,QGlobal,OpCrt,OpString,OpDos,QHdrRec,
  UGlobal,UColors,UMsg,UWindow,UMenu,ULanguag;

Procedure SelectLanguage;

implementation

Procedure SelectLanguage;
  var Size: integer;
      I: integer;
      LFile: NameStr;
  begin
    BuildDirectory(NEN^.RootDir+'\*.CMD',True,AnyFile, Menu^, Size);
    if Size = 0 then exit;
    OpenMenu(20,10,40,14,Menu^,Size,8,Sort,'',' Languages ',Orange_Scheme,I);
    I := GetMenu;
    if I <> 0 then
      begin
        GetMenuString(I, LFile);
        if LoadLanguage(NEN^.RootDir+'\'+LFile) then;
      end;
    CloseWindow;
  end;

End.
