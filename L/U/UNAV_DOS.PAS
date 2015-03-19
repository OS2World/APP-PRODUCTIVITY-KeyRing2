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
{$X+,F+,O+}
{ UNAV_DOS (C)1994 NewsMaker Systems.                                   }
{ DOS version of the Queue Navigator, using the Search engine in UQLIST }

unit UNav_DOS;

interface

uses
  Dos, UQlist, QHdrRec;

type
  TitleStr                      = String[20];

function InitDirectoryTree(ShowProgress                  : Boolean;
                           ForceRebuild                  : Boolean) : Boolean;
procedure CloseDirectoryTree;
function ChooseQueue(var oServer                   : ServerStr;
                     var oVolume                   : VolumeStr;
                     var oQueue                    : PathStr;
                     var oRights                   : Access;
                     var oType                     : QueueTypes;
                     var oDrive                    : Char;
                     ShowCopyToQueues              : Boolean;
                     AllLevels                     : Boolean;
                     Title                         : TitleStr) : Boolean;
function NextQueue(var oServer                   : ServerStr;
                   var oVolume                   : VolumeStr;
                   var oQueue                    : PathStr;
                   var oRights                   : Access;
                   var oType                     : QueueTypes) : Boolean;
function PrevQueue(var oServer                   : ServerStr;
                   var oVolume                   : VolumeStr;
                   var oQueue                    : PathStr;
                   var oRights                   : Access;
                   var oType                     : QueueTypes) : Boolean;

implementation

uses
  OpCrt, OpDos, OpPick, OpDrag, OpCmd, OpWindow, OpFrame, OpCol16, Opstring,
  UGlobal, UKey, UWindow, UMenu, UColors, Objects, Banner2, QScreen,
  Netware;

type

  PQueueList                    = ^TQueueList;
  TQueueList                    = object(PickList)
                                    Queue                         : PDirectory;
                                    Level                         : Integer;
                                    PCP                           : DragProcessorPtr;
                                    constructor Init(iQueue : PDirectory; iLevel : Integer; iTitle : TitleStr);
                                    destructor Done; virtual;
                                    function DoProcess(var oServer                   : ServerStr;
                                                       var oVolume                   : VolumeStr;
                                                       var oQueue                    : PathStr;
                                                       var oRights                   : Access;
                                                       var oType                     : QueueTypes;
                                                       var oDrive                    : Char;
                                                       var CurQueue                  : PDirectory;
                                                       var Index                     : Integer) : Boolean;
                                  end;

  PMatchList                    = ^TMatchList;
  TMatchList                    = object(PickList)
                                    Mask                          : PathStr;
                                    AllQ                          : Boolean;
                                    Visible                       : Boolean;
                                    PCP                           : DragProcessorPtr;
                                    constructor Init(iMask : PathStr; iAllQueues : Boolean; iAnyLevel
                                       : Boolean; iTitle : TitleStr);
                                    destructor Done; virtual;
                                    function DoProcess(var oServer                   : ServerStr;
                                                       var oVolume                   : VolumeStr;
                                                       var oQueue                    : PathStr;
                                                       var oRights                   : Access;
                                                       var oType                     : QueueTypes;
                                                       var oDrive                    : Char) : Boolean;
                                  end;

const
  ColorFlex                     : FlexAttrs = (BlackOnLtGray, BlackOnLtGray,
                                               YellowOnLtGray, BlueOnLtGray);
  MonoFlex                      : FlexAttrs = (YellowOnBlue, LtGreenOnBlue,
                                               LtMagentaOnBlue, LtRedOnBlue or Blink);

  QueueList                     : PQueueList = nil; { top level queue }

  MatchList                     : PMatchList = nil; { for LQ xxxxx match }

  CurLevel                      : Integer = 0;

  procedure QLPathMoveProc(P : PickListPtr); Far;
  var
    Entry                         : PDirectoryEntry;
    Server,
    Volume                        : VolumeStr;
    QT                            : String[9];
  begin
  with PQueueList(P)^ do
    begin
    Entry := PDirectoryEntry(Queue^.At(GetLastChoice - 1));
    QT := '(Queue)';
    case Entry^.qType of
      qtWire       : QT := '(Wire)';
      qtFolder     : QT := '(Folder)';
      qtRundown    : QT := '(Rundown)';
      qtAssignment : QT := '(Assign)';
      qtHighlight  : QT := '(HiLite)';
      qtArchive    : QT := '(Archive)';
      end;
    if Entry^.SubDirectory <> nil then
      QT := '(Folder)';
    Entry^.GetVolAndServer(Server, Volume);
    fFastWrite(Pad('  ' + Entry^.Name + ' on ' + Server + '\' + Volume + ' ' + QT, 34), 1, 1, WhiteOnLtGray);
    end;
  end;

  procedure QLSupplyQueueString(Item : Word; Mode : pkMode;
                                var IType                     : pkItemType;
                                var IString                   : String;
                                PickPtr                       : PickListPtr);
  var
    Entry                         : PDirectoryEntry;
    Atr                           : Char;
  begin
  with PQueueList(PickPtr)^ do
    begin
    IString := '';
    IType := pkNormal;
    if Item > Queue^.Count then Exit;
    Entry := PDirectoryEntry(Queue^.At(Item - 1));
    Atr := ^A;
    if Entry^.SubDirectory <> nil then
      Atr := ^B;
    case Mode of
      pkDisplay : 
                  begin
                  IString := ' ' + Atr + Entry^.Name + Atr;
                  if Item = GetLastChoice then
                    IString[1] := '';
                  end;
      pkSearch :
                 begin
                 IString := Entry^.Name;
                 end;
      pkGetType :
                  begin
                  end;
      end;
    end;
  end;

  constructor TQueueList.Init(iQueue : PDirectory; iLevel : Integer; iTitle : TitleStr);
  begin
  Queue := iQueue;
  Level := iLevel;
  Gray_Scheme;
  InitDeluxe(22 + Level, 8 + Level, 54 + Level, 16 + Level, NENColorset,
             wClear or wUserContents or wBordered,
             10,
             Queue^.Count,
             QLSupplyQueueString,
             PickSnaking,
             SingleChoice,
             DefPickOptions + pkMinHeight);

  AdjustFrameCoords(20 + Level, 6 + Level, 55 + Level, 17 + Level);

  CustomizeWindow(Self, iTitle, 8);
  AddScrollBars(Self, False);

  SetPickFlex(pkNormal, False,
              ColorFlex, MonoFlex);
  pkOptionsOn(pkMinHeight);
  pkOptionsOn(pkProcessZero);
  pkOptionsOn(pkFlexWrite);
  SetPadSize(0, 0);
  AddMoreHeader(' || for more ', heBR, #24, #25, '', 2, 3, 0);
  SetSearchMode(PickStringSelect);
  AddSearchHeader(7, heBL);
  SetMoveProc(QLPathMoveProc);

  New(PCP, Init(@PickKeySet, PickKeyMax));
  CustomizeCommandProcessor(PCP^);
  PCP^.SetKeypressedProc(UKey.KeyWaiting);
  PCP^.SetGetKeyProc(UKey.GetKey);
  SetCommandProcessor(PCP^);
  end;

  destructor TQueueList.Done;
  begin
  if PCP <> nil then
    Dispose(PCP, Done);
  Inherited Done;
  end;

  function TQueueList.DoProcess(var oServer                   : ServerStr;
                                var oVolume                   : VolumeStr;
                                var oQueue                    : PathStr;
                                var oRights                   : Access;
                                var oType                     : QueueTypes;
                                var oDrive                    : Char;
                                var CurQueue                  : PDirectory;
                                var Index                     : Integer) : Boolean;
  var
    Quit                          : Boolean;
    SubQueueList                  : PQueueList;
    Entry                         : PDirectoryEntry;
    SQ                            : Boolean;
  begin
  Quit := False;
  while not Quit do
    begin
    Process;
    case GetLastCommand of
      ccSelect :
                 begin
                 Index := GetLastChoice - 1;
                 Entry := PDirectoryEntry(Queue^.At(Index));
                 if Entry^.SubDirectory <> nil then
                   begin
                   Inc(CurLevel);
                   New(SubQueueList, Init(Entry^.SubDirectory, CurLevel, Entry^.Name));
                   if SubQueueList = nil then
                     Exit;

                   SQ := SubQueueList^.DoProcess(oServer, oVolume, oQueue, oRights,
                                                 oType, oDrive, CurQueue, Index);

                   SubQueueList^.Erase;
                   Dispose(SubQueueList, Done);
                   Dec(CurLevel);
                   if CurLevel < 0 then
                     CurLevel := 0;
                   if SQ then     { if selection made at sub-level, quit }
                     begin
                     Quit := True;
                     DoProcess := True;
                     end;
                   end
                 else
                   begin
                   Entry^.GetServerVolumeAndPath(oServer, oVolume, oQueue);
                   oDrive := Entry^.GetDrive;
                   oRights := Entry^.Rights;
                   oType := Entry^.qType;
                   CurQueue := Queue;
                   Quit := True;
                   DoProcess := True;
                   end;
                 end;
      ccQuit : 
               begin
               DoProcess := False;
               Quit := True;
               end;
      end;
    end;
  end;

  procedure MLPathMoveProc(P : PickListPtr); Far;
  var
    Entry                         : PDirectoryEntry;
    Server,
    Volume                        : VolumeStr;
    Drive                         : Char;
    QT                            : String[9];
  begin
  with World^, PQueueList(P)^ do
    begin
    Entry := PDirectoryEntry(MatchingQueues^.At(GetLastChoice - 1));
    if Entry^.Name = '..' then
      begin
      Entry^.GetVolAndServer(Server, Volume);
      Drive := Entry^.GetDrive;
      if Drive <> ' ' then
        fFastWrite(Pad('  Root Level on ' + Server + '\' + Volume + ' Drive ' + Drive, 34), 1, 1, WhiteOnLtGray)
      else
        fFastWrite(Pad('  Root Level on ' + Server + '\' + Volume, 34), 1, 1, WhiteOnLtGray);
      Exit;
      end;
    QT := '(Queue)';
    case Entry^.qType of
      qtWire       : QT := '(Wire)';
      qtFolder     : QT := '(Folder)';
      qtRundown    : QT := '(Rundown)';
      qtAssignment : QT := '(Assign)';
      qtHighlight  : QT := '(HiLite)';
      qtArchive    : QT := '(Archive)';
      end;
    if Entry^.SubDirectory <> nil then
      QT := '(Folder)';
    Entry^.GetVolAndServer(Server, Volume);
    fFastWrite(Pad('  ' + Entry^.Name + ' on ' + Server + '\' + Volume + ' ' + QT, 44), 1, 1, WhiteOnLtGray);
    end;
  end;

  procedure MLSupplyQueueString(Item : Word; Mode : pkMode;
                                var IType                     : pkItemType;
                                var IString                   : String;
                                PickPtr                       : PickListPtr);
  var
    Entry                         : PDirectoryEntry;
    Atr                           : Char;
    Server                        : ServerStr;
    Volume                        : VolumeStr;
  begin
  with World^, PQueueList(PickPtr)^ do
    begin
    Entry := PDirectoryEntry(MatchingQueues^.At(Item - 1));
    case Mode of
      pkDisplay :
                  begin
                  if Entry^.Name = '..' then
                    begin
                    Entry^.GetVolAndServer(Server, Volume);
                    IString := ' ' + ^C + '\' + Server + '\' + Volume + ':' + ^C;
                    end
                  else
                    IString := ' ' + Entry^.GetDisplayPath;
                  if Item = GetLastChoice then
                    IString[1] := '';
                  end;
      pkSearch : 
                 begin
                 if Entry^.Name = '..' then
                   IString := '.. Root Level'
                 else
                   IString := Entry^.GetDisplayPath;
                 end;
      pkGetType :
                  begin
                  end;
      end;
    end;
  end;

  constructor TMatchList.Init(iMask : PathStr; iAllQueues : Boolean; iAnyLevel : Boolean; iTitle : TitleStr);
  begin
  Mask := iMask;
  AllQ := iAllQueues;
  PCP := nil;
  Visible := False;

  with World^ do
    begin
    New(MatchingQueues, Init(50, 10));
    if MatchingQueues = nil then Fail;
    end;

  World^.FindQueue(Mask, iAnyLevel, AllQ);
  if World^.MatchingQueues^.Count < 2 then Exit;

  Gray_Scheme;
  NENColorset.HeaderColor := DkGrayOnLtGray;

  InitDeluxe(17, 8, 64, 16, NENColorset,
             wClear or wUserContents or wBordered,
             79,
             World^.MatchingQueues^.Count,
             MLSupplyQueueString,
             PickVertical,
             SingleChoice,
             DefPickOptions + pkMinHeight);

  AdjustFrameCoords(15, 6, 65, 17);

  CustomizeWindow(Self, iTitle, 8);
  AddScrollBars(Self, False);

  SetPickFlex(pkNormal, False,
              ColorFlex, MonoFlex);
  pkOptionsOn(pkMinHeight);
  pkOptionsOn(pkProcessZero);
  pkOptionsOn(pkFlexWrite);
  SetPadSize(0, 0);
  AddMoreHeader(' || for more ', heBR, #24, #25, '', 2, 3, 0);
  SetSearchMode(PickStringSelect);
  AddSearchHeader(7, heTR);
  if Mask = maQueueType + exFolder then
    wFrame.AddHeader(' ' + Long2Str(World^.MatchingQueues^.Count) + ' Folders Found', heBL)
  else
    wFrame.AddHeader(' ' + Long2Str(World^.MatchingQueues^.Count) + ' Matches on ' + Mask + ' ', heBL);
  SetMoveProc(MLPathMoveProc);

  New(PCP, Init(@PickKeySet, PickKeyMax));
  CustomizeCommandProcessor(PCP^);
  PCP^.SetKeypressedProc(UKey.KeyWaiting);
  PCP^.SetGetKeyProc(UKey.GetKey);
  SetCommandProcessor(PCP^);
  Visible := True;
  end;

  destructor TMatchList.Done;
  begin
  if PCP <> nil then
    Dispose(PCP, Done);
  if World^.MatchingQueues <> nil then
    begin
    World^.MatchingQueues^.Count := 0;
    Dispose(World^.MatchingQueues, Done);
    end;
  end;

  function TMatchList.DoProcess(var oServer                   : ServerStr;
                                var oVolume                   : VolumeStr;
                                var oQueue                    : PathStr;
                                var oRights                   : Access;
                                var oType                     : QueueTypes;
                                var oDrive                    : Char) : Boolean;

    procedure SetResult(i : Integer);
    var
      DE                            : PDirectoryEntry;
    begin
    DE := PDirectoryEntry(World^.MatchingQueues^.At(i));
    DE^.GetServerVolumeAndPath(oServer, oVolume, oQueue);
    oDrive := DE^.GetDrive;
    oRights := DE^.Rights;
    oType := DE^.qType;
    oDrive := DE^.GetDrive;
    World^.CurDirectory := DE^.Owner;
    if AllQ then
      World^.CurIndex := DE^.CopyToIndex
    else
      World^.CurIndex := DE^.SwitchToIndex
    end;

  var
    Quit                          : Boolean;
    Index                         : Integer;
  begin
  oServer := '';
  oVolume := '';
  oQueue := '';
  if World^.MatchingQueues^.Count = 0 then
    begin
    DoProcess := False;
    Exit;
    end;
  if World^.MatchingQueues^.Count = 1 then
    begin
    DoProcess := True;
    SetResult(0);
    Exit;
    end;

  if GraphScreenOn then
    begin
    CloseBanner;
    GraphScreenOn := False;
    end;

  Quit := False;
  while not Quit do
    begin
    Process;
    case GetLastCommand of
      ccSelect :
                 begin
                 Index := GetLastChoice - 1;
                 SetResult(Index);
                 Quit := True;
                 DoProcess := True;
                 end;
      ccQuit :
               begin
               DoProcess := False;
               Quit := True;
               end;
      end;
    end;
  end;

  function ChooseQueue(var oServer                   : ServerStr;
                       var oVolume                   : VolumeStr;
                       var oQueue                    : PathStr;
                       var oRights                   : Access;
                       var oType                     : QueueTypes;
                       var oDrive                    : Char;
                       ShowCopyToQueues              : Boolean;
                       AllLevels                     : Boolean;
                       Title                         : TitleStr) : Boolean;
  var
    i                             : Integer;
    Quit                          : Boolean;
  begin
  if oQueue = '' then
    begin
    with World^ do
      begin
      if ShowCopyToQueues then
        New(QueueList, Init(CopyToQueues, 0, Title))
      else
        New(QueueList, Init(SwitchToQueues, 0, Title));
      if QueueList = nil then
        Exit;

      ChooseQueue := QueueList^.DoProcess(oServer, oVolume, oQueue,
                                          oRights, oType, oDrive,
                                          CurDirectory, CurIndex);
      QueueList^.Erase;
      Dispose(QueueList, Done);
      end;
    end
  else
    begin
    New(MatchList, Init(oQueue, ShowCopyToQueues, AllLevels, Title));
    if MatchList = nil then Exit;
    ChooseQueue := MatchList^.DoProcess(oServer, oVolume, oQueue,
                                        oRights, oType, oDrive);
    if MatchList^.Visible then
      MatchList^.Erase;
    Dispose(MatchList, Done);
    end;
  end;

  function NextQueue(var oServer                   : ServerStr;
                     var oVolume                   : VolumeStr;
                     var oQueue                    : PathStr;
                     var oRights                   : Access;
                     var oType                     : QueueTypes) : Boolean;
  begin
  with World^ do
    NextQueue := CurDirectory^.ListNext(CurIndex, oServer, oVolume, oQueue, oRights, oType);
  end;

  function PrevQueue(var oServer                   : ServerStr;
                     var oVolume                   : VolumeStr;
                     var oQueue                    : PathStr;
                     var oRights                   : Access;
                     var oType                     : QueueTypes) : Boolean;
  begin
  with World^ do
    PrevQueue := CurDirectory^.ListPrev(CurIndex, oServer, oVolume, oQueue, oRights, oType);
  end;

  procedure DosOpenDisplay;
  begin
  OpenMessage('Scanning Servers', Gray_Scheme);
  end;

  procedure DosCloseDisplay;
  begin
  CloseMessage;
  end;

  procedure DosUpdateDisplay(Server : ServerStr; Msg : PathStr);
  begin
  WriteCentred(2, Pad('', 40));
  WriteCentred(2, 'Scanning Server ' + Server);
  WriteCentred(3, Pad('', 40));
  WriteCentred(3, Msg);
  end;

  function InitDirectoryTree(ShowProgress                  : Boolean;
                             ForceRebuild                  : Boolean) : Boolean;
  begin
  if ShowProgress then
    begin
    OpenDisplay := DosOpenDisplay;
    UpdateDisplay := DosUpdateDisplay;
    CloseDisplay := DosCloseDisplay;
    end;
  New(World, Init(17, 1, ForceRebuild));
  InitDirectoryTree := World <> nil;
  end;

  procedure CloseDirectoryTree;
  begin
  if World <> nil then
    Dispose(World, Done);
  end;

end.
