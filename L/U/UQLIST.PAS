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
{$F+,O+,X+,A-,V-}
{ UQLIST - (C) 1994 NewsMaker Systems                                   }
{ Non-Platform specific Queue list. No UI code should be in this unit   }

{ Object Hierarchy:                                                     }
{   TWorld - Contains TFileServers, and Root level TDirectories         }
{   TFileServer - Contains TVolumeList, a collection of TVolumes        }
{   TVolume - Locates Queues and adds TDirectoryEntrys to Root TDirectory }
{   TDirectoryEntry - Contains entry, and TDirectory of any sub queues  }

unit UQList;

interface

{$DEFINE SupportMultipleLocalVolumes} { conditional as doesn't work under OS/2 }

uses
  {$IFNDEF Windows}
  Dos,
  OpCrt,
  OpDos,
  OpString,
  {$ELSE}
  WinDos,
  WinSys,
  {$ENDIF}
  QHdrRec,
  QNovell,
  {NetWare,}
  NwBase,
  NwBind,
  Objects;

type
  DirString                     = String[8];
  NameString                    = String[12];

  ServerStr                     = String[40];
  VolumeStr                     = String[40];

  QueueTypes                    = (qtAll, qtNew, qtFolder, qtWire, qtRundown, qtUser,
                                   qtArchive, qtAssignment, qtHighLight);

  ObjectTypes                   = (otLocal, otFileServer, otVolume);

  PBaseObject                   = ^TBaseObject;
  TBaseObject                   = object(TObject)
                                    ObjType                       : ObjectTypes;
                                    Name                          : TnwObjectStr;
                                    Owner                         : TnwObjectStr;
                                    Parent                        : PObject;
                                  end;

  PDirectory                    = ^TDirectory;
  TDirectory                    = object(TSortedCollection)
                                    constructor Init(ALimit, ADelta : Word);
                                    function Compare(key1, key2 : Pointer) : Integer; virtual;
                                    function ListNext(var Index                     : Integer;
                                                      var Server                    : ServerStr;
                                                      var Volume                    : VolumeStr;
                                                      var Path                      : PathStr;
                                                      var Rights                    : Access;
                                                      var qType                     : QueueTypes) : Boolean;
                                    function ListPrev(var Index                     : Integer;
                                                      var Server                    : ServerStr;
                                                      var Volume                    : VolumeStr;
                                                      var Path                      : PathStr;
                                                      var Rights                    : Access;
                                                      var qType                     : QueueTypes) : Boolean;
                                  end;

  PVolumeList                   = ^TVolumeList;
  TVolumeList                   = object(TSortedCollection)
                                    constructor Init(ALimit, ADelta : Word);
                                    function Compare(key1, key2 : Pointer) : Integer; virtual;
                                  end;

  PFileServer                   = ^TFileServer;
  TFileServer                   = object(TBaseObject)
                                    Security                      : Byte;
                                    IsLocal                       : Boolean;
                                    SerialNumber                  : NovellServerNumSt;
                                    NetAddress                    : InterNetNum;
                                    VolumeList                    : PVolumeList;
                                    constructor Init(iParent                       : PObject;
                                                     Server                        : ServerStr;
                                                     iSecurity                     : Byte);
                                    destructor Done; virtual;
                                    function Attach               : Boolean;
                                    function DeAttach             : Boolean;
                                  end;

  PVolume                       = ^TVolume;
  TVolume                       = object(TBaseObject)
                                    HasNENStructure               : Boolean;
                                    Drive                         : Char;
                                    constructor Init(iParent                       : PObject;
                                                     iName                         : VolumeStr;
                                                     iServer                       : ServerStr);
                                    procedure FindQueues;
                                  end;


  PDirectoryEntry               = ^TDirectoryEntry;
  QProcedure                    = procedure(DE : PDirectoryEntry);
  TDirectoryEntry               = object(TObject)
                                    Name                          : DirString;
                                    Extension                     : ExtStr;
                                    qType                         : QueueTypes;
                                    CopyToAccess                  : Boolean;
                                    SwitchToAccess                : Boolean;
                                    Rights                        : Access;
                                    Parent                        : PObject;
                                    SubDirectory                  : PDirectory;
                                    TempDirEntry                  : PDirectoryEntry;
                                    Owner                         : PDirectory;
                                    CopyToIndex                   : Integer;
                                    SwitchToIndex                 : Integer;
                                    constructor Init(iParent : PObject; iOwner : PDirectory; iName : DirString; iExt : ExtStr);
                                    destructor Done; virtual;
                                    procedure FindSubdirectories;
                                    procedure CheckQAccess;
                                    function GetDrive             : Char;
                                    function GetName              : NameString;
                                    function GetType              : QueueTypes;
                                    function HasCopyToQAccess     : Boolean;
                                    function HasSwitchToQAccess   : Boolean;
                                    function GetPath              : PathStr;
                                    function GetDisplayPath       : PathStr;
                                    function GetFullPath          : PathStr;
                                    procedure GetServerVolumeAndPath(var Server                    : ServerStr;
                                                                     var Volume                    : VolumeStr;
                                                                     var Path                      : PathStr);
                                    procedure GetVolAndServer(var Server : ServerStr; var Vol : VolumeStr);
                                    procedure VisitSubQueues(QProc : QProcedure);
                                    function FindSubQueues(Queue                         : DirString;
                                                           var QList                     : PStringCollection) : Integer;
                                  end;

  { TWorld - The known world, all visible file servers, volumes, machines }

  PWorld                        = ^TWorld;
  TWorld                        = object(TSortedCollection)
                                    SwitchToQueues                : PDirectory; { Permanant }
                                    CopyToQueues                  : PDirectory; { Permanant }
                                    CurDirectory                  : PDirectory; { Current, for Next/Prev }
                                    CurIndex                      : Integer;
                                    Mask                          : DirString;
                                    MatchingQueues                : PDirectory; { Temporary, for LQ xxxx }
                                    MatchAnyLevel                 : Boolean;
                                    constructor Init(ALimit, ADelta                : Word;
                                                     ForceRebuildRequest           : Boolean);
                                    destructor Done; virtual;
                                    procedure Build;
                                    function Compare(key1, key2 : Pointer) : Integer; virtual;
                                    procedure VisitAllQueues(AllQ : Boolean; QProc : QProcedure);
                                    function FindQueue(Queue                         : DirString;
                                                       MatchAllLevels                : Boolean;
                                                       SearchAllQueues               : Boolean) : Integer;
                                  end;

  OpenDisplayProc               = procedure;
  UpdateDisplayProc             = procedure(Server : ServerStr; Msg : PathStr);
  CloseDisplayProc              = procedure;

var
  OpenDisplay                   : OpenDisplayProc;
  UpdateDisplay                 : UpdateDisplayProc;
  CloseDisplay                  : CloseDisplayProc;
  TF                            : ^Text;
  SavingList                    : Boolean;
  SkipMapfile                   : Boolean;


  { *****  }
  World                         : PWorld; { Main Data structure }
  { *****  }

  { Exported constants }

const
  All_Queues                    = True;
  Allowed_Queues                = False;

  All_Levels                    = True;
  Bottom_Level                  = False;

  exQueue                       = 'Q'; { 1st character of directory extension }

  exWire                        = 'W'; { 2nd character of directory extension }
  exFolder                      = 'F';
  exRundown                     = 'R';
  exArchive                     = 'I';
  exAssign                      = 'A';
  exHiLite                      = 'H';
  exUser                        = 'U';

  { Match characters for search mask }
  maStart                       = '<'; { <ABC   - Matches any string starting with ABC }
  maEnd                         = '>'; { >XYZ   - Matches any string ending with XYZ   }
  maRemainder                   = '*'; { ABC*   - Matches any remainder (same as < )   }
  maAnywhere                    = '@'; { @ABC   - Matches ABC anywhere within string   }
  maWildcard                    = '?'; { A?C    - Matches any character at position    }
  { Can be used in combination with above e.g.    }
  { K?LA*                                         }
  maQueueType                   = '|'; { |W     - Match Queue type (see ex.. above)    }

  { Fine-Tune constants for collections }
  { The size specifies the number of 32-bit slots in the base collection }
  { The Delta specified the number of entries to grow the collection by  }
  { when an attempt is made to add Size+1 entries. Growing the collection}
  { is less efficient than initially specifying a large enough size      }

  SwitchToQueueSize             : Integer = 300;
  SwitchToQueueDelta            : Integer = 10;

  CopyToQueueSize               : Integer = 300;
  CopyToQueueDelta              : Integer = 10;

  SubQueueSize                  : Integer = 100;
  SubQueueDelta                 : Integer = 10;

implementation

uses
  QScreen, QGlobal, QDrive2, QLog, UWindow, QCmdDsp, UMsg,
  UGlobal, QDrives, Strings, Banner2;

type
  {$IFNDEF Windows}
  TMask                         = PathStr;
  TSearch                       = SearchRec;
  {$ELSE}
  TMask   = Array[0..79] of char;
  TSearch = TSearchRec;
  {$ENDIF}

const
  {$IFNDEF Windows}
  TDirAttr                      = Directory;
  {$ELSE}
  TDirAttr                      = faDirectory;
  {$ENDIF}

  SortOnFullPath                : Boolean = False;

  procedure NilOpenDisplay;
  begin
  end;

  procedure NilCloseDisplay;
  begin
  end;

  procedure NilUpdateDisplay(Server : ServerStr; Msg : PathStr);
  begin
  end;

  function NameIsOK(NameIn : String) : Boolean;
  var IPos                      : Byte;
  begin
  if Pos('.QF', NameIn) > 0 then
    NameIsOK := True;

  NameIsOK := True;
  IPos := Pos('.', NameIn);

  if IPos = 0 then
    Exit;

  NameIsOK := False;

  if Length(NameIn) <> IPos + 2 then
    Exit;

  if Upcase(NameIn[IPos + 1]) <> 'Q' then
    Exit;

  case Upcase(NameIn[IPos + 2]) of
    exWire    : NameIsOK := True;
    exFolder  : NameIsOK := True;
    exRundown : NameIsOK := True;
    exArchive : NameIsOK := True;
    exAssign  : NameIsOK := True;
    exHiLite  : NameIsOK := True;
    exUser    : NameIsOK := True;
    end;                            {Case}
  end;

  function Encrypt(S : Encrypted) : Encrypted;
  var
    i                             : Integer;
    o                             : Encrypted;
  begin
  o := '';
  for i := 1 to Length(S) do
    begin
    o := o + Chr(Ord(S[i]) + 25);
    end;
  Encrypt := o;
  end;

  {-------------------------------------------------}

  function Decrypt(S : Encrypted) : Encrypted;
  var
    i                             : Integer;
    o                             : Encrypted;
  begin
  o := '';
  for i := 1 to Length(S) do
    begin
    o := o + Chr(Ord(S[i]) - 25);
    end;
  Decrypt := o;
  end;

  {-------------------------------------------------}

  function IsALocalDrive(var DriveLetter : Char) : Boolean;
  var scid, dh, stat            : Byte;
      DID                       : String[20];
  begin
  GetDir(0, DID);
  DriveLetter := DID[1];
  GetDriveInfo(DriveLetter, scid, dh, stat);
  IsALocalDrive := stat and NwLocal = NwLocal;
  end;

  {-------------------------------------------------}

  function QueueMatches(DE : PDirectoryEntry; SearchMask, QName, QExtension : DirString) : Boolean;
  var
    I                             : Integer;
  begin
  SearchMask := stUpCase(SearchMask);
  QName := stUpCase(QName);
  { Setup any ? wildcards for match }
  for I := 1 to Length(SearchMask) do
    if SearchMask[I] = maWildcard then
      QName[I] := maWildcard;
  { @abc - Match anywhere in string }
  if SearchMask[1] = maAnywhere then
    begin
    Delete(SearchMask, 1, 1);
    if Pos(SearchMask, QName) > 0 then
      begin
      QueueMatches := True;
      Exit;
      end;
    end;
  { abcd*   - Match any remainder }
  if SearchMask[Length(SearchMask)] = maRemainder then
    begin
    Delete(SearchMask, Length(SearchMask), 1);
    QName := Copy(QName, 1, Length(SearchMask));
    end;
  { <abcd  - Match starting with abcd (for compatibility with SC) }
  if SearchMask[1] = maStart then
    begin
    Delete(SearchMask, 1, 1);
    QName := Copy(QName, 1, Length(SearchMask));
    end;
  { >abcd - Match ending with abcd }
  if SearchMask[1] = maEnd then
    begin
    Delete(SearchMask, 1, 1);
    Delete(QName, 1, Length(QName) - Length(SearchMask));
    end;
  { |t - Match Queue type extension }
  if SearchMask[1] = maQueueType then
    begin
    QueueMatches := False;
    if Upcase(SearchMask[2]) = exFolder then
      QueueMatches := (DE^.qType = qtFolder) or(DE^.SubDirectory <> nil) or
                      (Upcase(QExtension[2]) = exFolder)
    else
      if QExtension <> '' then
        QueueMatches := Upcase(SearchMask[2]) = Upcase(QExtension[2]);
    Exit;
    end;

  QueueMatches := SearchMask = QName;
  end;

  {///// TDirectory - A Sorted collection of all queue names }

  constructor TDirectory.Init(ALimit, ADelta : Word);
  begin
  Inherited Init(ALimit, ADelta);
  Duplicates := True;
  end;

  function TDirectory.Compare(key1, key2 : Pointer) : Integer;
  begin
  if SortOnFullPath then
    Compare := Ord(CompUCString(PDirectoryEntry(key1)^.Name,
                                PDirectoryEntry(key2)^.Name)) - 1
  else
    Compare := Ord(CompUCString(PDirectoryEntry(key1)^.GetPath,
                                PDirectoryEntry(key2)^.GetPath)) - 1;
  end;

  function TDirectory.ListNext(var Index                     : Integer;
                               var Server                    : ServerStr;
                               var Volume                    : VolumeStr;
                               var Path                      : PathStr;
                               var Rights                    : Access;
                               var qType                     : QueueTypes) : Boolean;
  var
    Entry                         : PDirectoryEntry;
  begin
  if Index = Count - 1 then
    begin
    ListNext := False;
    Exit;
    end;
  Inc(Index);
  Entry := PDirectoryEntry(At(Index));
  Entry^.GetServerVolumeAndPath(Server, Volume, Path);
  Rights := Entry^.Rights;
  qType := Entry^.qType;
  ListNext := True;
  end;

  function TDirectory.ListPrev(var Index                     : Integer;
                               var Server                    : ServerStr;
                               var Volume                    : VolumeStr;
                               var Path                      : PathStr;
                               var Rights                    : Access;
                               var qType                     : QueueTypes) : Boolean;
  var
    Entry                         : PDirectoryEntry;
  begin
  if Index = 0 then
    begin
    ListPrev := False;
    Exit;
    end;
  Dec(Index);
  Entry := PDirectoryEntry(At(Index));
  Entry^.GetServerVolumeAndPath(Server, Volume, Path);
  Rights := Entry^.Rights;
  qType := Entry^.qType;
  ListPrev := True;
  end;

  {///// TVolumeList - A Sorted collection of all Volumes in a Server }

  constructor TVolumeList.Init(ALimit, ADelta : Word);
  begin
  Inherited Init(ALimit, ADelta);
  Duplicates := True;
  end;

  function TVolumeList.Compare(key1, key2 : Pointer) : Integer;
  begin
  Compare := Ord(CompUCString(PVolume(key1)^.Name,
                              PVolume(key2)^.Name)) - 1;
  end;

  {///// TDirectoryEntry - A single directory entry }

  constructor TDirectoryEntry.Init(iParent : PObject; iOwner : PDirectory; iName : DirString; iExt : ExtStr);
  begin
  Inherited Init;
  Name := iName;
  Extension := iExt;
  Parent := iParent;
  Owner := iOwner;
  SubDirectory := nil;
  if iName = '..' then Exit;

  if (iExt <> '') and(not NameIsOK(iName + '.' + iExt)) then
    Exit;

  CheckQAccess;

  FindSubdirectories;
  end;

  destructor TDirectoryEntry.Done;
  begin
  if SubDirectory <> nil then
    Dispose(SubDirectory, Done);
  Inherited Done;
  end;

  { GetPath - Path, including extensions and Root directory }

  function TDirectoryEntry.GetDrive : Char;
  var
    P                             : PObject;
  begin
  P := Parent;
  repeat
    if TypeOf(P^) = TypeOf(TDirectoryEntry) then
      begin
      P := PDirectoryEntry(P)^.Parent;
      end
    else
      begin
      GetDrive := PVolume(P)^.Drive;
      P := nil;
      end;
  until P = nil;
  end;

  function TDirectoryEntry.GetPath : PathStr;
  var
    S                             : PathStr;
    P                             : PObject;
  begin
  S := GetName;
  P := Parent;
  repeat
    if TypeOf(P^) = TypeOf(TDirectoryEntry) then
      begin
      System.Insert(PDirectoryEntry(P)^.GetName + '\', S, 1);
      P := PDirectoryEntry(P)^.Parent;
      end
    else
      P := nil;
  until P = nil;
  GetPath := NEN^.RootDir + '\' + S;
  end;

  { GetDisplayPath - No RootDir, No Extensions }

  function TDirectoryEntry.GetDisplayPath : PathStr;
  var
    S                             : PathStr;
    P                             : PObject;
  begin
  S := Name;
  P := Parent;
  repeat
    if TypeOf(P^) = TypeOf(TDirectoryEntry) then
      begin
      System.Insert(PDirectoryEntry(P)^.Name + '\', S, 1);
      P := PDirectoryEntry(P)^.Parent;
      end
    else
      P := nil;
  until P = nil;
  GetDisplayPath := S;
  end;

  { GetFullPath - Path, including Server and Volume }

  function TDirectoryEntry.GetFullPath : PathStr;
  var
    S                             : PathStr;
    P                             : PObject;
  begin
  S := GetName;
  P := Parent;
  repeat
    if TypeOf(P^) = TypeOf(TDirectoryEntry) then
      begin
      System.Insert(PDirectoryEntry(P)^.GetName + '\', S, 1);
      P := PDirectoryEntry(P)^.Parent;
      end
    else
      begin
      System.Insert(NEN^.RootDir + '\', S, 1);
      System.Insert(PVolume(P)^.Name + ':', S, 1);
      System.Insert(PVolume(P)^.Owner + '\', S, 1);
      P := nil;
      end;
  until P = nil;
  GetFullPath := S;
  end;

  procedure TDirectoryEntry.GetServerVolumeAndPath(var Server                    : ServerStr;
                                                   var Volume                    : VolumeStr;
                                                   var Path                      : PathStr);
  var
    S                             : PathStr;
    P                             : PObject;
  begin
  S := GetName;
  P := Parent;
  repeat
    if TypeOf(P^) = TypeOf(TDirectoryEntry) then
      begin
      System.Insert(PDirectoryEntry(P)^.GetName + '\', S, 1);
      P := PDirectoryEntry(P)^.Parent;
      end
    else
      begin
      Path := S;
      Volume := PVolume(P)^.Name;
      Server := PVolume(P)^.Owner;
      P := nil;
      end;
  until P = nil;
  end;

  procedure TDirectoryEntry.GetVolAndServer(var Server : ServerStr; var Vol : VolumeStr);
  var
    P                             : PObject;
  begin
  S := GetName;
  P := Parent;
  repeat
    if TypeOf(P^) = TypeOf(TDirectoryEntry) then
      begin
      P := PDirectoryEntry(P)^.Parent;
      end
    else
      begin
      Vol := PVolume(P)^.Name;
      Server := PVolume(P)^.Owner;
      P := nil;
      end;
  until P = nil;
  end;

  procedure TDirectoryEntry.FindSubdirectories;
  var
    Mask                          : TMask;
    First                         : Boolean;
    SD                            : TSearch;
    Atr                           : Byte;
    Err                           : Word;
    Ext                           : ExtStr;
    Server                        : ServerStr;
    Volume                        : VolumeStr;
    Workname                      : String[20];
    EC                            : Word;
    LocalDrive                    : Boolean;
    DriveLetter                   : Char;
    SubstDriveChar                : Char;

  begin
  LocalDrive := IsALocalDrive(DriveLetter);
  if (LocalDrive) and(Sys^.IgnoreLocalDrives) then
    Exit;

  if (DriveLetter <= 'D') and
     (GetDiskClass(DriveLetter, SubstDriveChar) = NovellDrive) then
    Exit;

  Mask := GetPath + '\*.Q*';
  Atr := TDirAttr;
  First := True;
  repeat
    begin
    if (SavingList) or(LocalDrive) or(SkipMapfile) then
      begin
      if First then
        FindFirst(Mask, Atr, SD)
      else
        FindNext(SD);
      First := False;
      Err := DosError;

      if Err <> 0 then
        begin
        if (not LocalDrive) and(not SkipMapfile) then
          Begin
          WriteLn(TF^, Encrypt('@@@@'));
          End;
        end
      else
        begin
        if (not LocalDrive) and(not SkipMapfile) then
          begin
          Write(TF^, (Encrypt(SD.Name + '||')));
          Str(SD.Attr, Workname);
          WriteLn(TF^, Encrypt(Workname));
          end;
        end;
      end
    else
      begin
      if EoF(TF^) then
        begin
        SD.Name := '@@@@';
        Err := 1;
        end
      else
        begin
        ReadLn(TF^, Workname);
        Workname := Decrypt(Workname);
        if Workname = '@@@@' then
          begin
          Err := 1;
          end
        else
          begin
          SD.Name := Workname;
          if Pos('|', SD.Name) > 0 then
            SD.Name[0] := Chr(Pos('|', SD.Name) - 1);
          if Pos('|', Workname) > 0 then
            Delete(Workname, 1, Pos('|', Workname));
          if Pos('|', Workname) > 0 then
            Delete(Workname, 1, Pos('|', Workname));
          Val(Workname, SD.Attr, EC);
          Err := 0;
          end;
        end;
      end;

    if Err <> 0 then Break;
    if SD.Attr and TDirAttr = 0 then Continue;
    if SD.Name[1] <> '.' then
      begin
      Ext := JustExtension(SD.Name);
      New(TempDirEntry, Init(@Self, nil, JustName(SD.Name), Ext));
      TempDirEntry^.qType := qtAll;
      case Upcase(Ext[2]) of
        exWire    : TempDirEntry^.qType := qtWire;
        exFolder  : TempDirEntry^.qType := qtFolder;
        exRundown : TempDirEntry^.qType := qtRundown;
        exArchive : TempDirEntry^.qType := qtArchive;
        exAssign  : TempDirEntry^.qType := qtAssignment;
        exHiLite  : TempDirEntry^.qType := qtHighLight;
        exUser    : TempDirEntry^.qType := qtUser;
        end;
      qType := qtFolder;          { all queues with subdirs are Folder types }
      if SubDirectory = nil then
        New(SubDirectory, Init(SubQueueSize, SubQueueDelta));
      if SubDirectory = nil then Exit;
      GetVolAndServer(Server, Volume);
      UpdateDisplay(Server, GetPath + '\' + JustName(SD.Name));
      SubDirectory^.Insert(TempDirEntry);
      TempDirEntry^.Owner := SubDirectory;
      TempDirEntry^.CopyToIndex := SubDirectory^.Count - 1;
      TempDirEntry^.SwitchToIndex := SubDirectory^.Count - 1;
      end;
    end;
  until Err <> 0;
  end;

  procedure TDirectoryEntry.CheckQAccess;
  label TheExit;
  var
    DriveBase                     : Byte;
    RightSt                       : String[12];
    DriveLtr                      : Char;
  begin
  if IsALocalDrive(DriveLtr) then
    begin
    SwitchToAccess := True;
    CopyToAccess := True;
    Rights := E_Access;
    Exit;
    end;

  CopyToAccess := False;
  SwitchToAccess := False;

  if (SavingList) or(SkipMapfile) then
    begin
    {$I-}
    ChDir(GetPath);
    {$I+}

    SwitchToAccess := False;
    CopyToAccess := SwitchToAccess;
    Rights := No_Access;

    if IoResult <> 0 then
      goto TheExit;

    Rights := GetMyDirRights(Sys^.TD_Num);

TheExit:

    case Rights of
      P_Access    : RightSt := 'P_ACCESS';
      No_Access   : RightSt := 'NO_ACCESS';
      R_Access    : RightSt := 'R_ACCESS';
      W_Access    : RightSt := 'W_ACCESS';
      E_Access    : RightSt := 'E_ACCESS';
      Zero_Access : RightSt := 'ZERO_ACCESS';
    end;                          {Case}

    if not SkipMapfile then
      Begin
      WriteLn(TF^, Encrypt(RightSt));
      End;
    end
  else
    begin
    ReadLn(TF^, RightSt);
    RightSt := Decrypt(RightSt);
    Rights := Zero_Access;
    if RightSt = 'P_ACCESS' then
      Rights := P_Access;

    if RightSt = 'NO_ACCESS' then
      Rights := No_Access;

    if RightSt = 'R_ACCESS' then
      Rights := R_Access;

    if RightSt = 'W_ACCESS' then
      Rights := W_Access;

    if RightSt = 'E_ACCESS' then
      Rights := E_Access;

    if RightSt = 'ZERO_ACCESS' then
      Rights := Zero_Access;
    end;

  if Sys^.NewSecurityMode then
    begin
    if (Rights = R_Access) or(Rights = W_Access) or
    (Rights = E_Access) then
      SwitchToAccess := True;

    if (Rights = W_Access) or(Rights = E_Access) then
      CopyToAccess := True;
    end
  else
    begin
    if (Rights <> No_Access) and(Rights <> Zero_Access) then
      SwitchToAccess := True;

    if Rights <> Zero_Access then
      CopyToAccess := True;
    end;
  end;

  function TDirectoryEntry.GetName : NameString;
  begin
  if Name = '..' then
    begin
    GetName := '';
    Exit;
    end;
  if Extension = '' then
    GetName := Name
  else
    GetName := Name + '.' + Extension;
  end;

  function TDirectoryEntry.GetType : QueueTypes;
  begin
  GetType := qType;
  end;

  function TDirectoryEntry.HasCopyToQAccess : Boolean;
  begin
  HasCopyToQAccess := CopyToAccess;
  end;

  function TDirectoryEntry.HasSwitchToQAccess : Boolean;
  begin
  HasSwitchToQAccess := SwitchToAccess;
  end;

  procedure TDirectoryEntry.VisitSubQueues(QProc : QProcedure);

    procedure VisitEntry(Item : Pointer); Far;
    var
      DE                            : PDirectoryEntry absolute Item;
    begin
    QProc(DE);
    if DE^.SubDirectory <> nil then
      DE^.VisitSubQueues(QProc);
    end;

  begin
  SubDirectory^.ForEach(@VisitEntry)
  end;

  function TDirectoryEntry.FindSubQueues(Queue                         : DirString;
                                         var QList                     : PStringCollection) : Integer;

    procedure CheckQMatch(Item : Pointer); Far;
    var
      DE                            : PDirectoryEntry absolute Item;
      S                             : ^String;
    begin
    if QueueMatches(@Self, Queue, DE^.Name, DE^.Extension) then
      begin
      New(S);
      S^ := DE^.GetFullPath;
      QList^.Insert(S);
      if DE^.SubDirectory <> nil then
        DE^.FindSubQueues(Queue, QList);
      end;
    end;

  begin
  SubDirectory^.ForEach(@CheckQMatch);
  end;

  {//// TWorld - A sorted collection of visible Servers and Volumes }

  constructor TWorld.Init(ALimit, ADelta                : Word;
                          ForceRebuildRequest           : Boolean);

    function CheckMailQueue       : Boolean;
    var
      FR                            : SearchRec;
    begin
    CheckMailQueue := False;

    FindFirst(NEN^.PrivateDir + '\*.', Directory, FR);
    repeat
      begin
      if FR.Name = Sys^.UsersName then
        begin
        FindFirst(NEN^.PrivateDir + '\' + Sys^.UsersName + '\IN',
                  Directory, FR);
        if DosError <> 0 then Exit;

        FindFirst(NEN^.PrivateDir + '\' + Sys^.UsersName + '\Cabinet',
                  Directory, FR);
        if DosError <> 0 then Exit;

        FindFirst(NEN^.PrivateDir + '\' + Sys^.UsersName + '\Private',
                  Directory, FR);
        if DosError <> 0 then Exit;

        CheckMailQueue := True;
        Exit;
        end;
      FindNext(FR);
      end;
    until DosError <> 0;
    end;

    procedure CreateMailBoxIfNecessary;
    begin
    if not CheckMailQueue then
      begin
       {$I-}
      MkDir(NEN^.PrivateDir + '\' + Sys^.UsersName);
      if IoResult <> 0 then ;

      MkDir(NEN^.PrivateDir + '\' + Sys^.UsersName + '\IN');
      if IoResult <> 0 then ;

      MkDir(NEN^.PrivateDir + '\' + Sys^.UsersName + '\CABINET');
      if IoResult <> 0 then ;

      MkDir(NEN^.PrivateDir + '\' + Sys^.UsersName + '\PRIVATE');
      if IoResult <> 0 then ;

       {$I+}
      end;
    end;

  var CurDrive                  : DriveName;
    SR1                           : SearchRec;
    SR2                           : SearchRec;
    TFIsOpen                      : Boolean;
    Err                           : Integer;
    WorkLine                      : String[10];
    ForceRebuild                  : Boolean;
    LocalFSNames                  : ARRAY[1..16] OF Boolean;
    I                             : Integer;
    FoundServer                   : Boolean;

  label PastRebuild;

  begin
  Inherited Init(ALimit, ADelta);
  New(CopyToQueues, Init(CopyToQueueSize, CopyToQueueDelta));
  New(SwitchToQueues, Init(SwitchToQueueSize, SwitchToQueueDelta));
  New(TF);
  SavingList := False;
  SkipMapfile := False;
  CurDrive := Sys^.CurrentDriveID;
  ChangeDrive(Sys^.SysDrive);
  TFIsOpen := False;
  ForceRebuild := False;
  SavingList := False;
  CreateMailBoxIfNecessary;
  FindFirst(NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.MAP',
            AnyFile, SR2);

  FindFirst(DefaultCmdLine.Serverfile, AnyFile, SR1);

  if (DosError = 0) And (SR1.Time > SR2.Time) then
    begin
    ForceRebuild := True;
    end;

  FindFirst('UPDATE.QS', AnyFile, SR1);

  if DosError <> 0 then
    begin
    SkipMapfile := True;
    goto PastRebuild;
    end;

  if (DosError <> 0) or(SR1.Time > SR2.Time) then
    ForceRebuild := True;

  FillChar (LocalFSNames,SizeOf(LocalFSNames),False);

  Err := 0;
  if not ForceRebuildRequest then
    begin
    Assign(TF^, NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.MAP');
       {$I-}
    Reset(TF^);
       {$I+}
    Err := IoResult;
    if Err = 0 then
      begin
      TFIsOpen := True;
      ReadLn(TF^, WorkLine);
      if Decrypt(WorkLine) <> '*&*&*&B' then
        begin
        Close(TF^);
        TFIsOpen := False;
        ForceRebuild := True;
        ForceRebuildRequest := True;
        end;
      end
      Else
      Begin
      TFIsOpen := False;
      ForceRebuild := True;
      ForceRebuildRequest := True;
      End;

     If TFIsOpen Then
        Begin
        Repeat
          Begin
          ReadLn (TF^,WorkLine);
          FoundServer := False;
          If Decrypt(WorkLine) <> '*&*&--' Then
             Begin
             For I := 1 To 16 Do
                Begin
                If StUpcase(Sys^.FSNames[I]) = StUpcase(Decrypt(WorkLine)) Then
                   Begin
                   LocalFSNames[I] := True;
                   FoundServer := True;
                   End;
                End;

             If Not FoundServer Then
                Begin
                If TFIsOpen Then
                   Close(TF^);
                TFIsOpen := False;
                ForceRebuild := True;
                ForceRebuildRequest := True;
                end;
             End;
          End;
       Until (Not TFIsOpen) Or (Eof(TF^)) Or (Decrypt(WorkLine) = '*&*&--');

       For I := 1 To 16 Do
          If (Sys^.FSNames[I] <> '') And
             (LocalFSNames[I] <> True) Then
             begin
             If TFIsOpen Then
                Close(TF^);
             TFIsOpen := False;
             ForceRebuild := True;
             ForceRebuildRequest := True;
             end;
       end;
     End;

  if (Err <> 0) or(ForceRebuild) and(not ForceRebuildRequest) then
    begin
    if GraphScreenOn then
      begin
      CloseBanner;
      GraphScreenOn := False;
      end;

    if Sys^.RebuildQList then
      begin
      WriteLn(SysMsg(000047) {Rebuilding Q List...} );
      ForceRebuild := True;
      if TFIsOpen then
        begin
        Close(TF^);
        TFIsOpen := False;
        end;
      end
    else
      begin
      NENFlag := False;
      case Dialog(SysMsg(2573), SysMsg(254), LightBlue, SysMsg(64), SysMsg(65),
                  SysMsg(2376) {Cancel} ) of
        0 :
          begin                   {Escape}
          Msg(SysMsg(000234) {'Canceled'} , 0);
          ForceRebuild := False;
          if not TFIsOpen then
            begin
            Assign(TF^, NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.MAP');
            {$I-}
            Reset(TF^);
            {$I+}
            Err := IoResult;
            if Err = 0 then
              begin
              TFIsOpen := True;
              ReadLn(TF^, WorkLine);
              if Decrypt(WorkLine) <> '*&*&*&B' then
                begin
                Close(TF^);
                TFIsOpen := False;
                ForceRebuild := True;
                end;
              end;
            end;
          end;
        1 :
          begin                   {Yes}
          WriteLn(SysMsg(000047) {Rebuilding Q List...} );
          ForceRebuild := True;
          if TFIsOpen then
            begin
            Close(TF^);
            TFIsOpen := False;
            end;
          end;
        2 :
          begin                   {No}
          ForceRebuild := False;
          if not TFIsOpen then
            begin
            Assign(TF^, NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.MAP');
            {$I-}
            Reset(TF^);
            {$I+}
            Err := IoResult;
            if Err = 0 then
              begin
              TFIsOpen := True;
              ReadLn(TF^, WorkLine);
              if Decrypt(WorkLine) <> '*&*&*&B' then
                begin
                Close(TF^);
                TFIsOpen := False;
                ForceRebuild := True;
                end;
              end;
            end;
          end;
        3 :
          begin                   {Cancel}
          Msg(SysMsg(000234) {'Canceled'} , 0);
          ForceRebuild := False;
          if not TFIsOpen then
            begin
            Assign(TF^, NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.MAP');
            {$I-}
            Reset(TF^);
            {$I+}
            Err := IoResult;
            if Err = 0 then
              begin
              TFIsOpen := True;
              ReadLn(TF^, WorkLine);
              if Decrypt(WorkLine) <> '*&*&*&B' then
                begin
                Close(TF^);
                TFIsOpen := False;
                ForceRebuild := True;
                end;
              end;
            end;
          end;
        end;
      end;
    end;


  NENFlag := True;
  if (ForceRebuild) or(ForceRebuildRequest) then
    begin
    Assign(TF^, NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.new');
    {$I-}
    Rewrite(TF^);
    {$I+}
    SavingList := True;
    TFIsOpen := True;
    WorkLine := Encrypt('*&*&*&B');
    {$I-}
    WriteLn(TF^, WorkLine);
    {$I+}
    Err := IoResult;
    if Err <> 0 then
      begin
      If GraphScreenOn Then
         Begin
         CloseBanner;
         GraphScreenOn := False;
         End;

      WriteLn('Unable To Build Map File');
      Halt;
      end;

    For I := 1 To 16 Do
      Begin
      If Sys^.FSNames[I] <> '' Then
        Begin
        WorkLine := Encrypt(Sys^.FSNames[I]);
        {$I-}
        WriteLn(TF^, WorkLine);
        {$I+}
        Err := IoResult;
        if Err <> 0 then
          begin
          If GraphScreenOn Then
            Begin
            CloseBanner;
            GraphScreenOn := False;
            End;

          WriteLn('Unable To Build Map File');
          Halt;
          end;
        End;
      End;

    WorkLine := Encrypt('*&*&--');
    {$I-}
    WriteLn(TF^, WorkLine);
    {$I+}
    end;

PastRebuild:

  ChangeDrive(CurDrive);
  Duplicates := True;
  CurDirectory := nil;
  MatchingQueues := nil;
  Build;
  if TFIsOpen then
    Close(TF^);

  if SavingList then
    begin
    Assign(TF^, NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.MAP');
       {$I-}
    Erase(TF^);
       {$I+}
    Err := IoResult;
    if (Err = 0) or(Err = 2) then
      begin
      Assign(TF^, NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.new');
      {$I-}
      Rename(TF^, NEN^.PrivateDir + '\' + Sys^.UsersName + '\Queue6.MAP');
      {$I+}
      Err := IoResult;
      if Err <> 0 then
        begin
        Msg(SysMsg(002574) {'Unable To Rename Map File '} , 2);
        end;
      end
    else
      begin
      Msg(SysMsg(002574) {'Unable To Rename Map File '} , 2);
      end;

    end;

  Dispose(TF);
  if Count = 0 then
    begin
    Dispose(CopyToQueues, Done);
    SwitchToQueues^.Count := 0;
    Dispose(SwitchToQueues, Done);
    Fail;
    end;
  end;

  destructor TWorld.Done;
  begin
  Dispose(CopyToQueues, Done);
  SwitchToQueues^.Count := 0;     { 'cos we've already freed entries }
  Dispose(SwitchToQueues, Done);
  Inherited Done;
  end;

  procedure TWorld.Build;
  var
    ObjectType                    : Word;
    ObjectName                    : ObjectStr;

    PropName                      : PropertyStr;
    HasProperties                 : Boolean;
    Result                        : Byte;
    ObjectID,
    Sequence                      : LongInt;
    ObjectIsDynamic               : Boolean;
    ObjectSecurity,
    PropFlag,
    PropSec                       : Byte;
    Dum1, Dum2,
    Dum3, Dum4                    : Word;
    I                             : Integer;
    Server                        : PFileServer;
    STXT                          : Text;
    Ix                            : Integer;
    Ch                            : Char;
    DC                            : DiskClass;
  begin
  OpenDisplay;

  if not Sys^.NovellSys then
    ChangeDrive(Sys^.SysDrive);

  {$IFDEF SupportMultipleLocalVolumes}
  if not Sys^.IgnoreLocalDrives then
    begin
    for I := 1 to NumberOfDrives do
      begin
      DC := GetDiskClass(Char(Ord('B') + I), Ch);
      if DC <> HardDisk then Break;
      if DC in[CDRomDisk, NovellDrive] then Break;
      New(Server, Init(@Self, 'LOCAL', I));
      Server^.Attach;
      Insert(Server);
      end;
    end;
  {$ELSE}
    If Not Sys^.IgnoreLocalDrives Then
       begin
       if GetDiskInfo(3, Dum1, Dum2, Dum3, Dum4) then
         begin
           New(Server, Init(@Self, 'LOCAL', 1));
           Server^.Attach;
           Insert(Server);
         end;
       End;
  {$ENDIF}

  For Ix := 1 To 16 Do
     begin
     If Sys^.FSNames[Ix] <> '' Then
        Begin
        ObjectName := Sys^.FSNames[Ix];
        ObjectSecurity := 0;
        New(Server, Init(@Self, ObjectName, ObjectSecurity));
        Server^.Attach;
        Insert(+ Server);
        Server^.DeAttach;
        End;
     end;

  CloseDisplay;
  end;

  function TWorld.Compare(key1, key2 : Pointer) : Integer;
  begin
  Compare := Ord(CompUCString(PBaseObject(key1)^.Name, PBaseObject(key2)^.Name)) - 1;
  end;

  procedure TWorld.VisitAllQueues(AllQ : Boolean; QProc : QProcedure);

    procedure VisitEntry(Item : Pointer); Far;
    var
      DE                            : PDirectoryEntry absolute Item;
    begin
    QProc(DE);
    if DE^.SubDirectory <> nil then
      DE^.VisitSubQueues(QProc);
    end;

  begin
  if AllQ then
    CopyToQueues^.ForEach(@VisitEntry)
  else
    SwitchToQueues^.ForEach(@VisitEntry);
  end;

  procedure CheckQMatch(DE : PDirectoryEntry); Far;
  begin
  if QueueMatches(DE, World^.Mask, DE^.Name, DE^.Extension) then
    begin
    if (World^.MatchAnyLevel) or
    ((not World^.MatchAnyLevel) and(DE^.SubDirectory = nil)) then { Only bottom level queues }
      World^.MatchingQueues^.Insert(DE);
    end;
  end;

  function TWorld.FindQueue(Queue                         : DirString;
                            MatchAllLevels                : Boolean;
                            SearchAllQueues               : Boolean) : Integer;
  var
    DE                            : PDirectoryEntry;

    procedure AddVolumeRootLevels(Item : Pointer); Far;

      procedure AddRootLevel(Item : Pointer); Far;
      begin
      with PVolume(Item)^ do
        begin
        if HasNENStructure then
          begin
          New(DE, Init(PVolume(Item), nil, '..', exQueue + exFolder));
          DE^.qType := qtNew;
          World^.MatchingQueues^.Insert(DE);
          end;
        end;
      end;

    begin
    PFileServer(Item)^.VolumeList^.ForEach(@AddRootLevel);
    end;

  begin
  SortOnFullPath := True;
  World^.Mask := Queue;
  World^.MatchAnyLevel := MatchAllLevels;
  if World^.MatchAnyLevel then
    begin
    World^.ForEach(@AddVolumeRootLevels);
    end;
  VisitAllQueues(SearchAllQueues, CheckQMatch);
  SortOnFullPath := False;
  end;

  {//// TFileServer - A visible File server }

  constructor TFileServer.Init(iParent : PObject; Server : ServerStr; iSecurity : Byte);
  begin
  Inherited Init;
  Name := Server;
  Owner := '';
  Parent := iParent;
  Security := iSecurity;
  New(VolumeList, Init(4, 1));
  if VolumeList = nil then Fail;
  IsLocal := Server = 'LOCAL';
  NetAddress := GetNetAddr(Name);
  ObjType := otFileServer;
  end;

  destructor TFileServer.Done;
  begin
  if VolumeList <> nil then
    Dispose(VolumeList, Done);
  Inherited Done;
  end;

  function TFileServer.Attach   : Boolean;
  var
    VolumeNum                     : Integer;
    VolumeName                    : VolName;
    Volume                        : PVolume;
    ECode                         : Integer;
    SaveDrive                     : DriveName;
    DriveID                       : Char;
    Workname                      : String[40];
  begin
  SaveDrive := Sys^.CurrentDriveID;

  VolumeNum := 0;
  if IsLocal then
    begin
    GetVolumeLabel(Char(Security + Ord('B')), VolumeName);
    If MapToDrive(Sys^.ToDrive, '\', Local, Char(Security + Ord('B'))) Then
       Begin
       ChangeDrive(Sys^.ToDrive);
       New(Volume, Init(@Self, VolumeName, Name));
       VolumeList^.Insert(Volume);
       End
       Else
       Begin
       WriteToLog ('Unable To Map To C:\', LogCommon);
       End;
    end
  else
    begin
    if (SavingList) or(SkipMapfile) then
      begin
      WriteToLog('Processing Server ' + Name, LogCommon);

      if AttachFS(Name, Sys^.ToDrive, 'SYS:'+NEN^.RootDir,
         Sys^.UsersName, Sys^.UsersPassword, ECode) then
        begin
        if not SkipMapfile then
          Begin
          WriteLn(TF^, (Encrypt(Name)));
          End;

        ChangeDrive(Sys^.ToDrive);
        repeat
          begin
          VolumeName := GetVolName(VolumeNum);
          if VolumeName = '' then
            begin
            Break;
            end;
          WriteToLog('Processing Volume ' + VolumeName, LogCommon);

          Inc(VolumeNum);
          if MapToDrive(Sys^.ToDrive, VolumeName + ':', NetWork, DriveID) then
            begin
            ChangeDrive(Sys^.ToDrive);
            if not SkipMapfile then
              Begin
              WriteLn(TF^, (Encrypt(VolumeName)));
              End;
            New(Volume, Init(@Self, VolumeName, Name));
            VolumeList^.Insert(Volume);
            end
            Else
            Begin
            writetolog ('bad map',logcommon);
            end;
          end;
        until VolumeName = '';
        if not SkipMapfile then
          Begin
          WriteLn(TF^, (Encrypt('!!!!')));
          End;
        end
      else
        begin
        WriteToLog('Unable To Attach To ' + Name, LogCommon);
        if (ECode <> 1) then      {Unable To Login}
          SavingList := False;
        end;
      end
    else
      begin
      ReadLn(TF^, Workname);
      Name := Decrypt(Workname);
      WriteToLog('Loading Server ' + Name, LogCommon);
      ReadLn(TF^, Workname);
      Workname := Decrypt(Workname);

      repeat
        begin
        VolumeName := Workname;
        WriteToLog('Loading Volume ' + VolumeName, LogCommon);
        New(Volume, Init(@Self, VolumeName, Name));
        VolumeList^.Insert(Volume);
        ReadLn(TF^, Workname);
        Workname := Decrypt(Workname);
        end;
      until Workname = '!!!!';
      end;
    end;
  ChangeDrive(SaveDrive);
  end;

  function TFileServer.DeAttach;
  begin
  If (Not SavingList) And (Not SkipMapFile) Then
     Begin
     DeAttach := True;
     Exit;
     End;

  DeAttach := False;
  if (Sys^.ToQFS <> Sys^.BaseFS) and
  (Sys^.ToQFS <> Sys^.HomeFS) and
  (Sys^.ToQFS <> FW^.CurrentQFS) and
  (Sys^.ToQFS <> 'LOCAL') and
  (Sys^.ToQFS <> FW^.FwdLink^.CurrentQFS) then
    if ReleaseFileServer(Sys^.ToQFS) then
      begin
      Sys^.ToQFS := '';
      DeAttach := True;
      end
  end;


  {//// TVolume - A single volume within a file server }

  constructor TVolume.Init(iParent : PObject; iName : VolumeStr; iServer : ServerStr);
  begin
  Inherited Init;
  Name := iName;
  Owner := iServer;
  Parent := iParent;
  ObjType := otVolume;
  Drive := ' ';
  if iServer = 'LOCAL' then
    Drive := Char(Ord(PFileServer(Parent)^.Security) + Ord('B'));
  HasNENStructure := False;
  FindQueues;
  end;

  procedure TVolume.FindQueues;
  var
    Mask                          : TMask;
    First                         : Boolean;
    SD                            : TSearch;
    DirEntry                      : PDirectoryEntry;
    Atr                           : Byte;
    Err                           : Word;
    Workname                      : String[20];
    EC                            : Word;
    LocalDrive                    : Boolean;
    DriveLetter                   : Char;
    SubstDriveChar                : Char;

  begin
  LocalDrive := IsALocalDrive(DriveLetter);
  if (LocalDrive) and(Sys^.IgnoreLocalDrives) then
    Exit;

  if (DriveLetter <= 'D') and
  (GetDiskClass(DriveLetter, SubstDriveChar) = NovellDrive) then
    Exit;

  Mask := NEN^.RootDir + '\*.*';
  Atr := TDirAttr;
  First := True;
  repeat
    begin
    if (SavingList) or(LocalDrive) or(SkipMapfile) then
      begin
      if First then
        FindFirst(Mask, Atr, SD)
      else
        FindNext(SD);
      First := False;
      Err := DosError;
      if Err <> 0 then
        begin
        if (not LocalDrive) and(not SkipMapfile) then
          Begin
          WriteLn(TF^, Encrypt('@@@@'));
          End;
        end
      else
        begin
        if (not LocalDrive) and(not SkipMapfile) and
        (NameIsOK(SD.Name)) then
          begin
          Write(TF^, Encrypt(SD.Name + '||'));
          Str(SD.Attr, Workname);
          WriteLn(TF^, Encrypt(Workname));
          end;
        end;
      end
    else
      begin
      if EoF(TF^) then
        begin
        SD.Name := '@@@@';
        Err := 1;
        end
      else
        begin
        ReadLn(TF^, Workname);
        Workname := Decrypt(Workname);
        if Workname = '@@@@' then
          begin
          Err := 1;
          end
        else
          begin
          SD.Name := Workname;
          if Pos('|', SD.Name) > 0 then
            SD.Name[0] := Chr(Pos('|', SD.Name) - 1);
          if Pos('|', Workname) > 0 then
            Delete(Workname, 1, Pos('|', Workname));
          if Pos('|', Workname) > 0 then
            Delete(Workname, 1, Pos('|', Workname));
          Val(Workname, SD.Attr, EC);
          Err := 0;
          end;
        end;
      end;
    if Err <> 0 then Break;
    if SD.Attr and TDirAttr = 0 then Continue;
    if SD.Name[1] <> '.' then
      begin
      New(DirEntry, Init(@Self, nil, JustName(SD.Name), JustExtension(SD.Name)));
      UpdateDisplay(PFileServer(Parent)^.Name, Name + ':' + JustPathname(Mask) + '\' + SD.Name);
      if DirEntry^.HasCopyToQAccess then
        begin
        PWorld(PFileServer(Parent)^.Parent)^.CopyToQueues^.Insert(DirEntry);
        DirEntry^.CopyToIndex := PWorld(PFileServer(Parent)^.Parent)^.CopyToQueues^.Count - 1;
        DirEntry^.Owner := PWorld(PFileServer(Parent)^.Parent)^.CopyToQueues;
        HasNENStructure := True;
        end;

      if DirEntry^.HasSwitchToQAccess then
        begin
        PWorld(PFileServer(Parent)^.Parent)^.SwitchToQueues^.Insert(DirEntry);
        DirEntry^.SwitchToIndex := PWorld(PFileServer(Parent)^.Parent)^.SwitchToQueues^.Count - 1;
        DirEntry^.Owner := PWorld(PFileServer(Parent)^.Parent)^.SwitchToQueues;
        HasNENStructure := True;
        end;

      if (not DirEntry^.HasCopyToQAccess) and
      (not DirEntry^.HasSwitchToQAccess) then
        Dispose(DirEntry, Done);
      end;
    end;
  until Err <> 0;
  end;

begin
OpenDisplay := NilOpenDisplay;
UpdateDisplay := NilUpdateDisplay;
CloseDisplay := NilCloseDisplay;
TF := nil;
SavingList := False;
SkipMapfile := False;
end.

