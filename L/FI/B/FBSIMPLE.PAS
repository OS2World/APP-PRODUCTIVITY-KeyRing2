{$I BTDEFINE.INC}
program FbSimple;
uses
  OpCrt, OpCmd, OpFrame, OpWindow, Filer, VRec, FBrowse;
const
  SectionLength = 140;
type
  PersonDef =
    record
      Dele             : LongInt;
      FirstName, Name  : String[15];
      Company, Address : String[25];
      City             : String[15];
      State            : String[2];
      Zip              : String[10];
      Telephone        : String[12];
      NotesLen         : Word;
      Notes            : array[1..932] of Char;
    end;
var
  PS     : LongInt;
  Pf     : IsamFileBlockPtr;
  Person : PersonDef;
  VB     : VBrowser;
  DatLen : Word;

  {$F+}
  procedure BuildItem(Row : Byte;
                      var DatS;
                      DatLen : Word;
                      Ref : LongInt;
                      Key : IsamKeyStr;
                      var S : String;
                      FBP : FBrowserPtr);
    {-Return one row of an item to the browser in S}
  var
    P : PersonDef absolute DatS;
  begin
    {for this simple demo, just return the key}
    S := Key;
  end;

begin
  {allocate buffer for variable-length records}
  {$IFDEF BTree52}
  if not BTSetVariableRecBuffer(SectionLength) then
  {$ELSE}
  if not SetVariableRecBuffer(SectionLength) then
  {$ENDIF}
    Halt;

  {allocate page stack}
  {$IFDEF BTree52}
  PS := BTInitIsam(NoNet, 20000, 0);
  {$ELSE}
  PS := GetPageStack(20000);
  {$ENDIF}
  if not IsamOK then
    Halt;

  {open file block}
  {$IFDEF BTree52}
  BTOpenFileBlock(Pf, 'ADDRESS', False, False, False, False);
  {$ELSE}
  OpenFileBlock(Pf, 'ADDRESS');
  {$ENDIF}
  if not IsamOK then
    Halt;

  {initialize browser}
  if not VB.Init(1, 1, 80, 25,  {window coordinates}
                 Pf,            {fileblock pointer}
                 1,             {key number}
                 Person,        {record buffer}
                 0,             {maximum number of rows in window}
                 1,             {number of rows per item}
                 30) then       {maximum number of columns per row}
    Halt;
  VB.SetBuildItemProc(BuildItem);
  VB.fbOptionsOn(fbBuildOnKey);

  repeat
    {process commands}
    VB.Process;

    {read the current record}
    case VB.GetLastCommand of
      ccSelect, ccQuit, ccError : {ok} ;
      else VB.GetCurrentRecord(Person, DatLen);
    end;
  until (VB.GetLastCommand = ccQuit) or (VB.GetLastCommand = ccError);

  {erase and destroy the browse window}
  VB.Erase;
  VB.Done;

  {close file block}
  {$IFDEF BTree52}
  BTCloseFileBlock(Pf);
  {$ELSE}
  CloseFileBlock(Pf);
  {$ENDIF}
end.
