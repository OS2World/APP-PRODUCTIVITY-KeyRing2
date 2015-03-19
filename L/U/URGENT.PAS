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
{$X+,F+,O+}
Unit Urgent;

interface

Uses
  {$IFDEF MSDOS}
  Dos,
  {$ELSE}
  WinDOS,
  {$ENDIF}
  QHdrRec, QUptime;

  {$IFNDEF MSDOS}
  Type
    NameStr = String[14];
    PathStr = String[79];
  {$ENDIF}


procedure InstallUrgents;

  { Check4Urgents - Returns TRUE if file updated since last check }
function Check4Urgents: boolean;

  { Show Urgents, Display picklist of last n Urgents }
procedure ShowUrgents;

  { return first Urgent }
function FirstUrgent: String;

(*
  { UpdateUrgentFile - For use by NENWIRE }
function UpdateUrgentFile(var Hdr: RundownRec;
                          OutputQ: NameStr;
                          OutputFile: PathStr): boolean;
*)
Const
  TotalUrgents = 50;  { Total maintained in file }
  UrgentSound : boolean = True;
  UrgentFilename : NameStr = 'URGENTS';

implementation
{$IFNDEF NOTNEN}
Uses
  QGlobal, QDrive2, QLog, QDrives,
  OpCrt, OpString, OpDos, OpDate, OpEditor, OpWindow, OpFrame,
  OpConst, OpPick, OpDrag, OpCmd, OpCol16,
  UTPrint,
  {$IFNDEF MSDOS}
  Strings,
  {$ENDIF}
  UGlobal, UDialog, UMsg, ULib, UWindow, UFKey,
  UMenu, UKey, UEdit, UColors, UNotePad;


Type
{  PUrgentEditor = ^TUrgentEditor;
  TUrgentEditor = Object(TNote)
    procedure Print;
  end;}

  UrgentString = String[100];

  PUrgentList = ^TUrgentList;
  TUrgentList = Array[1..50] of UrgentString;

Const
  LastUrgent : LongInt = 0;

  UHeader = '   Slug                 C P Queue    Time     Date      ';

  ColorFlex : FlexAttrs = (BlackOnLtGray,
                           BlackOnLtGray,   { Category }
                           BlackOnLtGray,   { Queue    }
                           BlueOnLtGray);   { Slug     }
  MonoFlex  : FlexAttrs = (YellowOnBlue, LtGreenOnBlue,
                           LtMagentaOnBlue, LtRedOnBlue or Blink);

Var
{  UF              : Text;}
  NumUrgents      : word;
  IoRes           : integer;
  LastUrgentCheck : LongInt;
  CurrDrive       : DriveName;
  SaveFileMode    : integer;
  UrgentList      : PickListPtr;
  PCP             : DragProcessorPtr;

Const
  ListOfUrgents   : PUrgentList = Nil;

procedure InstallUrgents;
begin
  SetUrgentCallbacks(Check4Urgents, FirstUrgent);
end;

function InitUrgents: boolean;
var i: integer;
begin
  if ListOfUrgents = Nil then
    New(ListOfUrgents);
  if ListOfUrgents = Nil then exit;
  if ListOfUrgents <> nil then
    for i := 1 to TotalUrgents do
      ListOfUrgents^[i] := '';
  InitUrgents := ListOfUrgents <> nil;
end;

function UrgentFile: PathStr;
begin
  UrgentFile := NEN^.PublicDir+'\'+UrgentFilename;
end;

function Check4Urgents: boolean;
  {$IFDEF MSDOS}
  var
    TS: SearchRec;
  const
    AF = AnyFile;
  {$ELSE}
  var
    TS: TSearchRec;
    UF: Array[0..79] of Char;
  const
    AF = faAnyFile;
  {$ENDIF}
Var
   CurrDrive : DriveName;

begin
  CurrDrive := Sys^.CurrentDriveID;
  ChangeDrive (Sys^.SysDrive);

  Check4Urgents := false;
  {$IFDEF MSDOS}
  FindFirst(UrgentFile, AF, TS);
  {$ELSE}
  StrPCopy(UF, UrgentFile);
  FindFirst(UF, AF, TS);
  {$ENDIF}
  ChangeDrive (CurrDrive);
  if DosError <> 0 then
    exit;

  if LastUrgent = 0 then     { First call since startup, just prime value }
    begin
    LastUrgent := TS.Time;
    exit;
    end;
  Check4Urgents := LastUrgent <> TS.Time;
  LastUrgent := TS.Time;
end;

Procedure ViewUrgent(Slug: PathStr; Queue: NameStr; WFile: PathStr);
var
  TE        : PNote;
  Filename  : PathStr;
  CurrDrive : DriveName;
  Y         : integer;

begin
  CurrDrive := Sys^.CurrentDriveID;
  if (WFile[1] = 'Q') and (Pos('\',WFile) = 0) then
    FileName := NEN^.RootDir+'\'+Trim(Queue)+'\'+Trim(WFile)  { NEN5 }
  else
    begin
      FileName := Trim(WFile);                                { NEN6 }
      if FileName[2] = ':' then
        Delete(FileName,1,2);
    end;
{  dialog(Filename,'Testing',Red,'OK','','');}
  If (Sys^.NovellSys) And (Not MapToDrive (Sys^.ToDrive,
     Sys^.LastUrgentVolume+':'+ NEN^.RootDir, NetWork,' ')) Then
     Begin
     ChangeDrive (CurrDrive);
     Dialog(SysMsg(000470){Unable To Map To }+Sys^.LastUrgentVolume+':'+
        NEN^.RootDir,Slug,Red,'OK','','');
     Exit;
     End;

  ChangeDrive (Sys^.ToDrive);
  if not ExistFile(FileName) then
    begin
    ChangeDrive (CurrDrive);
    Dialog('Story No longer in System',Slug,Red,'OK','','');
    Exit;
    end;

  OpenFKeyDisplay(23);
  Y := CW^.WindowY+1;
  if Y <= 0 then
    Y := 5;
  New(TE,InitDeluxe(2, Y, 79, 21,
                    Trim(Slug),
                    FileName,
                    caUrgent,
                    True,
                    True));
  if TE = Nil then exit;
{  TE^.wFrame.AddHeader('ShF10-Print',heTR);}
  TE^.DateTime := '';
  TE^.Execute;
  ChangeDrive (CurrDrive);
  CloseFKeyDisplay;
  Dispose(TE,Done);
end;

procedure LoadUrgentList;
var
  UF: Text;
begin
  CurrDrive := Sys^.CurrentDriveID;
  ChangeDrive (Sys^.SysDrive);
  {$I-}
  SaveFileMode := FileMode;
  Filemode := $40;
  Assign(UF, UrgentFile);
  Reset(UF);
  if IoResult <> 0 then
    Begin
    FileMode := SaveFileMode;
    ChangeDrive (CurrDrive);
    exit;
    End;
  NumUrgents := 0;
  While not EOF(UF) do
    begin
    inc(NumUrgents);
    if NumUrgents <= MaxUrgents then
      ReadLn(UF, ListOfUrgents^[NumUrgents])
    else
      Break;
    end;
  Close(UF);
  FileMode := SaveFileMode;
  if NumUrgents > MaxUrgents then
    Dec(NumUrgents);
  {$I+}
end;

Function CheckUrgentUpdate: boolean;
begin
  if Timeout(LastUrgentCheck, 1000) then
    begin
    if Check4Urgents then
      begin
      LoadUrgentList;
      UrgentList^.ChangeNumItems(NumUrgents);
      UrgentList^.UpdateContents;
      if UrgentSound then
        begin
        Sound(2400);
        Delay(100);
        Sound(1600);
        Delay(100);
        end;
      NoSound;
      end;
    LastUrgentCheck := TimeMS;
    end;
  CheckUrgentUpdate := UKey.KeyWaiting;
end;

Procedure SupplyUrgentString(Item: word; Mode: pkMode;
                             var IType: pkItemType;
                             var IString: String;
                             PickPtr: PickListPtr);
begin
  Case Mode of
    pkDisplay  : begin  { pretty, with flexwrite chars }
                 IString := ^C+Copy(ListOfUrgents^[Item],1,20)+^C+' '+
                            ^A+ListOfUrgents^[Item][22]+^A+
                            ' '+ListOfUrgents^[Item][24]+' '+
                            ^B+Pad(JustName(Copy(ListOfUrgents^[Item],26,8)),8)+^B+
                            Copy(ListOfUrgents^[Item],34,50);
                 end;
    pkSearch   : begin
                 IString := ListOfUrgents^[Item];
                 end;
    pkGetType  : begin
                 end;
    end;
end;

procedure ShowUrgents;

 Const
    Exits                         : Set Of Byte = [ccuser6];

var
  TOut         : LongInt;
  i            : integer;
  Y            : integer;
  Quit         : boolean;
begin
  if not InitUrgents then exit;
  LastUrgentCheck := TimeMS;
  LoadUrgentList;
  Gray_Scheme;

  Y := CW^.WindowY+2;
  if Y <= 0 then
    Y := 6;
  New(UrgentList,
      InitDeluxe(2,Y,57,21,NENColorset,
                 wClear or wUserContents or wBordered,
                 54,
                 NumUrgents,
                 SupplyUrgentString,
                 PickVertical,
                 SingleChoice,
                 DefPickOptions));
  if UrgentList = nil then
    begin
    Dispose(ListOfUrgents);
    ListOfUrgents := nil;
    exit;
    end;
  UrgentList^.AdjustFrameCoords(1,Y-2,58,22);

  CustomizeWindow(UrgentList^, 'Urgents', 8);
  AddScrollBars(UrgentList^, False);

  with UrgentList^ do
    begin
    SetPickFlex(pkNormal,False,
                ColorFlex, MonoFlex);
    pkOptionsOff(pkMinHeight);
    pkOptionsOn(pkProcessZero);
    pkOptionsOn(pkFlexWrite);
    SetPadSize(3,0);
    AddMoreHeader(' || for more ', heBR, #24, #25, '', 2, 3, 0);
    Draw;
    ChangeHeader(0,'Last '+Long2Str(NumUrgents)+' Urgents');
    wFrame.UpdateFrame;
    fFastWrite(UHeader,1,1,DkGrayOnLtGray);
    end;

  New(PCP,Init(@PickKeySet, PickKeyMax));
  CustomizeCommandProcessor(PCP^);
  PCP^.SetKeypressedProc(CheckUrgentUpdate);
  PCP^.SetGetKeyProc(UKey.GetKey);
  UrgentList^.SetCommandProcessor(PCP^);

  Quit := False;
  While not Quit do
    with UrgentList^ do
      begin
      Process;
      Case GetLastCommand of
        ccSelect:
                  begin
                  i := GetLastChoice;
                  ViewUrgent(Copy(ListOfUrgents^[i],1,20),Copy(ListOfUrgents^[i],26,8),
                             Copy(ListOfUrgents^[i],Pos('|',ListOfUrgents^[i])+1,$FF));
                  end;
        ccQuit  : Quit := True;
        end;
      end;
  Dispose(PCP, Done);
  UrgentList^.Erase;
  Dispose(UrgentList, Done);
  Dispose(ListOfUrgents);
  ListOfUrgents := nil;
  ChangeDrive (CurrDrive);
end;

function FirstUrgent: String;
var
  UF           : Text;
  NumUrgents   : word;
  IoRes        : integer;
  TOut         : LongInt;
  i            : integer;
  CurrDrive    : DriveName;
  SaveFileMode : integer;
  Urgent       : BigString;
  TS           : LongInt;
  OutQName     : QueueName;

begin
  CurrDrive := Sys^.CurrentDriveID;
  ChangeDrive (Sys^.SysDrive);
  FirstUrgent := '';
  {$I-}
  SaveFileMode := FileMode;
  Filemode := $40;
  Assign(UF, UrgentFile);
  Reset(UF);
  IoRes := IoResult;
  if IoRes <> 0 then
    Begin
    FileMode := SaveFileMode;
    WriteToLog(UrgentFileName+' File Error (Reset) '+Long2Str(IoRes),1);
    ChangeDrive (CurrDrive);
    exit;
    End;
  Urgent := '';
  ReadLn(UF, Urgent);
  IoRes := IoResult;
  if IoRes <> 0 then
    Begin
    FileMode := SaveFileMode;
    WriteToLog(UrgentFileName+' File Error (ReadLn) '+Long2Str(IoRes),1);
    WriteToLog(Urgent,1);
    ChangeDrive (CurrDrive);
    exit;
    End;
  Close(UF);
  {$I+}
  FileMode := SaveFileMode;

{

AM-AmtrakDerailment  A U WH.QW    16:20:59 10-09-95 |\APPS\NEWS\NEN\WI
}

  OutQName := Copy (Urgent,26,8);
  If Pos ('.', OutQName) > 0 Then
     OutQName[0] := Chr(Pos('.',OutQName)-1);

  FirstUrgent := 'URGENT: '+Copy(Urgent,1,20)+' In '+OutQName;
  if CurrDrive <> 'ZZ' then
    ChangeDrive (CurrDrive);
  WriteToLog(Urgent,2);
end;
(*   -- Moved to W_URGENT
{ UpdateUrgentFile - Called by NENWIRE to update the file }

function UpdateUrgentFile(var Hdr: RundownRec;
                          OutputQ: NameStr;
                          OutputFile: PathStr): boolean;
var
  UF : Text;
  NumUrgents : word;
  IoRes : integer;
  TOut  : LongInt;
  i     : integer;
begin
  UpdateUrgentFile := False;
  if not InitUrgents then
    begin
    Dispose(ListOfUrgents);
    ListOfUrgents := nil;
    exit;
    end;

  { If first time ever, create Urgents file }

  if not ExistFile(UrgentFile) then
    begin
    {$I-}
    Assign(UF, UrgentFile);
    Rewrite(UF);
    IoRes := IoResult;
    Close(UF);
    IoRes := IoResult;
    {$I+}
    end;

  { Try and open file until we get it Read/Write/Non-Exclusive }

  {$I-}
  if SYS^.NovellSys then
    FileMode := $22
  else
    Filemode := $2;
  IoRes := -1;
  Assign(UF, UrgentFile);
  TOut := TimeMS;
  While (IoRes <> 0) and (not Timeout(TOut, 4000)) do
    begin
    UpdateWTime(False);
    Reset(UF);
    IoRes := IoResult;
    end;
  if IoRes <> 0 then
    begin
    Dispose(ListOfUrgents);
    ListOfUrgents := nil;
    Exit;
    end;

  { Read existing file contents to items 2 thru MaxUrgents }

  NumUrgents := 0;
  While not EOF(UF) do
    begin
    inc(NumUrgents);
    if NumUrgents < TotalUrgents then
      ReadLn(UF, ListOfUrgents^[NumUrgents+1]);
    end;
  Close(UF);

  ListOfUrgents^[1] := Pad(Trim(Hdr.Slug),20)+
                  ' '+Hdr.Category+
                  ' '+Hdr.Priority+
                  ' '+Pad(OutputQ,8)+
                  ' '+CurrentTimeString('hh:mm:ss')+
                  ' '+TodayString(InternationalDate(False,True))+
                  ' |'+OutputFile;

  Rewrite(UF);
  for i := 1 to TotalUrgents do
    if ListOfUrgents^[i] <> '' then
      begin
      WriteLn(UF, ListOfUrgents^[i]);
      end;

  Close(UF);
  FileMode := 2;
  {$I+}

{  Dispose(ListOfUrgents);
  ListOfUrgents := nil;}
  UpdateUrgentFile := True;
end;
*)
{$ELSE}
USES
    OpRoot;

procedure InstallUrgents;
BEGIN
    Abstract;
END;

  { Check4Urgents - Returns TRUE if file updated since last check }
function Check4Urgents: boolean;
BEGIN
    Abstract;
END;

  { Show Urgents, Display picklist of last n Urgents }
procedure ShowUrgents;
BEGIN
    Abstract;
END;

  { return first Urgent }
function FirstUrgent: String;
BEGIN
    Abstract;
END;

{$ENDIF}
End.
