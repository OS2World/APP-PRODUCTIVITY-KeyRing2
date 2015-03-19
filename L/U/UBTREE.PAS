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
{$A-,R-,S-,V-,F+,O+}
{.$D+}
{----------------------------------------------------}
{ (C) NewsMaker Systems Inc.                         }
{ Procedure Library for B-Tree Filer (TurboPower/ENZ)}
{                                                    }
{ Provides an Object (See OOP guide TP5.5) named     }
{ DBtree, which represents one BTFILER Database.     }
{ For each database, declare a variable e.g.         }
{   Var TestDB : ^DBtree;                            }
{ Then, call routines using "dotting" techniques e.g }
{   New(TestDB,Init);                                }
{   TestDB^.Open('Test.Dat',FixedRecs);              }
{   TestDB^.Close;                                   }
{   Dispose(TestDB,Done);                            }
{                                                    }
{----------------------------------------------------}

Unit UBtree;

interface

Uses
    Dos,
    OpCrt,
    OpDos,
    QGlobal,
    QHdrRec,
    OpString,
    Filer,
    Vrec,
    QNovell,
    UWindow;

Type
  DBFtype         = String[14];
  Stype           = String[100];
  KeyString       = String[80];

  {>>>> DBTREE Object - This represents one Btree database         }
  { it is a simple static object with no virtual methods, although }
  { a Constructor & Destructor are used to allocate/deallocate heap}

  DBtree = Object
    { Data }
    DbOpen       : boolean;                { True if File Open }
    FB           : IsamFileBlockPtr;       { File Specs        }
    IID          : IsamIndDescr;           { index descriptor record for Create }
    Fixed_Len    : integer;                { Data length (Fixed portion) }
    Variable     : boolean;                { True if record has Variable recs }
    Total_Len    : word;                   { Total size, (Fixed+variable) }
    Status       : boolean;                { Last IsamOK status }
    Error        : integer;                { Last error code }
    DbFileName   : DbFtype;                { Physical file name }
    DbFilePath   : PathStr;                { Fully qualified path to file }
    LastReadLen  : integer;                { Bytes read in last retrieve }
    LastKeyPath  : integer;                { For Get Next/Previous }
    LastKey      : KeyString;              { Actual key supplied }
    Position     : LongInt;                { Physical record address }
    RecordLocked : boolean;                { Current record is locked to us }
    FileLocked   : boolean;                { whole file is locked to us }
    ReadOnly     : boolean;                { Open mode }

    { Methods }
    Constructor Init;                      { Allocates Heap buffers        }
    Procedure   Start;                     { As Init, when not Heap resdnt.}
    Procedure Open(FileName: PathStr;      { Opens a BtFiler file          }
                   VarFlag : boolean);
    Procedure SetOpenMode(ROnly: boolean); { Set mode to open in }
    Procedure Close;                       { Closes the current file       }
    Procedure Create(Filename: PathStr;    { Create a new Database         }
                     DataLen : Word;
                     NumKeys : integer;
                     VarRecs : boolean);
    Procedure Delete;                      { Deletes the current file      }
    Procedure DefineKey(KeyNum   : integer;{ Sets up Key params for Create }
                        KeyLen   : integer;
                        KeyType  : boolean);
    Function  LastBTstatus: integer;       { Result of last call           }
    Function  RecordPos: LongInt;          { Current Record byte offset    }
    Function  IsOpen: boolean;             { True if a file is open        }
    Function  NumRecs: LongInt;            { Total records in file         }
    Procedure Find(KeySt: IsamKeyStr;      { Find exact matching record    }
                   KeyNum: integer);
    Procedure Search(KeySt: IsamKeyStr;    { Find matching or higher rec   }
                     KeyNum: integer);
    Procedure Next;                        { Next, via current Keypath     }
    Procedure Prev;                        { Prev, via current Keypath     }
    Function  GetSize: word;               { Get size of current record    }
    Procedure GetLocked(Size: word;        { Get 'size' of current record  }
                        VAR Rec);          { and lock record               }
    Procedure GetReadOnly(Size: word;      { Get 'size' of current record  }
                          VAR Rec);        { Read only mode                }
    Procedure FindRef(KeySt: IsamKeyStr;   { Find record with key & Rec#   }
                      KeyNum: integer;
                      Ref: LongInt);
    Function  LockRecord: boolean;         { Locks current record          }
    Procedure UnlockRecord;                { Unlocks current record & file }
    Function  LockFile: boolean;           { Locks entire database file    }
    Procedure UnlockFile;                  { Unlocks database              }
    Procedure AddRecord(var Rec;           { Adds a new record to the file }
                        Len: integer);
    Procedure AddIndex(KeyNum: integer;    { Adds a string to the index    }
                       KeySt: KeyString);
    Procedure Update(var Rec;Size: word);  { Update current record         }
    Procedure DeleteRecord;                { Delete current record         }
    Procedure DeleteIndex(KeyNum: integer; { Deletes a string from index   }
                          KeySt: KeyString);
    Procedure Seek(RecNum: LongInt);       { Sets absolute record address  }
    Destructor Done;                       { Deallocates buffer space      }
    Procedure  Finish;                     { As Done, when not heap Resdnt.}
    Procedure GetStatus(var Free: LongInt; { Various statistics            }
                        var Used: LongInt;
                        var RecSize: LongInt;
                        var NumKeys: byte);
    Function  IndexCount(Index: integer):
                                 LongInt;  { Num entries in index }
  End;  { DBtree }

Const
  BtreeFailure : boolean = False;  { if True, Init failed }

  AutoAllocate : boolean = True ;  { if True, allocates buffers automatically }

  SaveMode     : boolean = False;  { if true, opens DB in SAVE mode, safe but slow}

  AllowDuplicates = True;          { Exported constants }
  Unique          = False;
  VariableRecs    = True;
  FixedRecs       = False;

  Trace       : boolean = False;    { Normally False }

  MinimizeHeap : boolean = True;    { True under NEN }

Const
  NumDBs   : word = 0;         { Total databases open }
                               { Used for auto-alloc/dealloc of page buffers }

  TimeOutValue = 2000;         { Timeout on lock, in milliseconds }

Var
  MaxBefore: word;
  MaxAfter : word;
  InitStatus: boolean;
  InitError : Integer;

Function  InitBtree: boolean;   { Called once, when first DB init'ed }
Procedure CloseBTree;           { Called once, when last DB closed   }
Function  DatabaseExists(ArcName: PathStr): boolean;
Procedure ReserveHeapSpace(H: LongInt);
Function  BtreeInitialized: boolean; { True if InitBtree has run OK }
Procedure GetMemoryUsage(var RAM,EMS: integer);

implementation

Const
  FreeHeap : LongInt = 80000;  { Bytes to reserve for application }

  PageStack: LongInt = 0;        { Size of allocated page stack }
  RAMPages : integer = 0;
  EMSPages : integer = 0;
  VarInit  : boolean = False;    { True if Variable rec buf has been created }

{>>>>> DBtree object methods <<<<< }

{----------------------------------------------------------}
Constructor DBtree.Init;    { Called if allocated on heap with NEW }
begin
  Start;
end;

{----------------------------------------------------------}
Procedure DBtree.Start;     { Called if regular variable   }
begin
  Status := False;
  DbOpen := False;
  Position := 0;
  ReadOnly := False;
  FB := nil;
  RecordLocked := False;
  FileLocked   := False;
  if PageStack = 0 then
    if AutoAllocate then
      if not InitBtree then BtreeFailure := True;
  if not BtreeFailure then
    begin
    inc(NumDBs);
    SearchForSequentialDefault := True;
    end;
end;

{----------------------------------------------------------}
Destructor DBtree.Done;
begin
  Finish;
end;

{----------------------------------------------------------}
Procedure DBtree.Finish;
begin
  if NumDBs > 0 then
    Dec(NumDBs);
  if NumDBs = 0 then
    if AutoAllocate then
      CloseBtree;
end;

{----------------------------------------------------------}
Procedure DBtree.Open(FileName: PathStr; VarFlag: boolean);
Begin
  DbOpen := False;
  if BtreeFailure then exit;   { Major problem }
  Variable := VarFlag;
  BTOpenFileBlock(FB,FileName,ReadOnly,False,SaveMode,True);
  Status := IsamOk;
  Error  := IsamError;
  if LastBtStatus = 0 then
    DbOpen := True
  else
    exit;
  if Variable then
    if not VarInit then
      begin
        VarInit := BTCreateVariableRecBuffer(FB);
        Status := IsamOk;
        Error  := IsamError;
      end;
end;

{----------------------------------------------------------}
Procedure DBtree.SetOpenMode(ROnly: boolean);
begin
  ReadOnly := ROnly;
end;

{----------------------------------------------------------}
Procedure DBtree.Close;
begin
  if DbOpen then
    begin
      BTFlushFileBlock(FB);
      BTCloseFileBlock(FB);
    end;
  Status := IsamOk;
  Error  := IsamError;
  DbOpen := False;
end;

{----------------------------------------------------------}
{  Must be preceded by calls to DefineKey                  }
Procedure DBtree.Create(Filename: PathStr;
                        DataLen : Word;
                        NumKeys : integer;
                        VarRecs : boolean);
begin
  BTCreateFileBlock(FileName,LongInt(DataLen),NumKeys,IID);
  Fixed_Len := DataLen;
  Status := IsamOk;
  Error  := IsamError;
  Variable := VarRecs;
  Open(FileName,Variable);
  DbOpen := True;
end;

{----------------------------------------------------------}
{ Delete an entire database file-set                       }
Procedure DBtree.Delete;
  begin
    if not DbOpen then exit;
    Close;
    BTDeleteFileBlock(DbFileName);
    Status := IsamOk;
    Error  := IsamError;
  end;

{----------------------------------------------------------}
Procedure DBtree.DefineKey(KeyNum   : integer;
                           KeyLen   : integer;
                           KeyType  : boolean);
Begin
  IID[KeyNum].KeyL := KeyLen;
  IID[KeyNum].AllowDupK := KeyType;
End;

{----------------------------------------------------------}
Procedure DBtree.Update(var Rec;Size: word);
begin
  if not DbOpen then exit;
  Status := False;
  if not LockFile then exit;
  if not Variable then
    BTPutRec(FB,Position,Rec,False)
  else
    BTPutVariableRec(FB,Position,Rec,Size);
  Status := IsamOk;
  Error  := IsamError;
  UnlockFile;
end;

{----------------------------------------------------------}
Procedure DBtree.DeleteRecord;
begin
  if not DbOpen then exit;
  Status := False;
  if not FileLocked then exit;  { S/B locked by DeleteIndex }
  if not Variable then
    BTDeleteRec(FB,Position)
  else
    BTDeleteVariableRec(FB,Position);
  Status := IsamOk;
  Error  := IsamError;
  UnlockFile;
end;

{----------------------------------------------------------}
Function  DBtree.NumRecs: LongInt;
Begin
  NumRecs := BTFileLen(FB);
end;

{----------------------------------------------------------}
Procedure DBtree.Seek(RecNum: LongInt);
  Begin
    Position := RecNum;
    Error := 0;
    Status := True;
  end;

{----------------------------------------------------------}
Function  DBtree.LastBTstatus: integer;
begin
  if Status = True then
    LastBTStatus := 0
  else
    LastBTstatus := Error;
end;

{----------------------------------------------------------}
Function  DBtree.IsOpen: boolean;
begin
  if NumDBs = 0 then
    begin
      IsOpen := false;
      exit;
    end;
  IsOpen := DbOpen;
end;

{----------------------------------------------------------}
Function  DBtree.RecordPos: longInt;
begin
  RecordPos := Position;
end;

{----------------------------------------------------------}
Function  DBtree.LockRecord: boolean;
  var Timeout: LongInt;
  begin
    Timeout := TimeMS;
    if not RecordLocked then
      repeat
        BTLockRec(FB,Position);
      until (IsamOK) or (TimeMS - Timeout  >= TimeOutValue);
    RecordLocked := IsamOK;
    Error := ISamError;
    LockRecord := RecordLocked;
    if (Trace) and (not RecordLocked) then
        Dialog('Record Lock Failure '+Long2Str(Error),
                'UBTREE',
                Red,
                'OK',
                '',
                '');
  end;

{----------------------------------------------------------}
Procedure DBtree.UnlockRecord;
  var Timeout: word;
  begin
    UnlockFile;
    Timeout := 0;
    if RecordLocked then
      Repeat
        BTUnLockRec(FB,Position);
        inc(Timeout);
      until (IsamOK) or (TimeOut = 100);
    RecordLocked := False;
  end;

{----------------------------------------------------------}
Function  DBtree.LockFile: boolean;
  var Timeout: LongInt;
  begin
    Timeout := TimeMS;
    if not FileLocked then
      Repeat
        BTLockFileBlock(FB);
      until (IsamOK) or (abs(TimeMS-TimeOut) >= TimeOutValue);
    FileLocked := IsamOK;
    Recordlocked := IsamOK;
    Error := IsamError;
    LockFile := FileLocked;
    if (Trace) and (not FileLocked) then
        Dialog('File Lock Failure '+Long2Str(Error),'UBTREE',Red,'OK','','');
  end;

{----------------------------------------------------------}
Procedure DBtree.UnlockFile;
  begin
    if FileLocked then
      BTUnLockFileBlock(FB);
    BTUnlockAllRecs(FB);
    FileLocked := False;
    RecordLocked := False;
  end;

{----------------------------------------------------------}
Procedure DBtree.Find(KeySt: IsamKeyStr; KeyNum: integer);
  begin
    if RecordLocked then UnlockRecord;
    BTSetSearchForSequential(FB,KeyNum,True);
    LastKeyPath := KeyNum;
    LastKey     := KeySt;
    BTFindKey(FB,Keynum,Position,LastKey);
    Status := IsamOK;
    Error  := IsamError;
  end;

{----------------------------------------------------------}
Procedure DBtree.FindRef(KeySt: IsamKeyStr; KeyNum: integer; Ref: LongInt);
  begin
    if RecordLocked then UnlockRecord;
    BTSetSearchForSequential(FB,KeyNum,True);
    LastKeyPath := KeyNum;
    LastKey     := KeySt;
    BTFindKeyAndRef(FB,Keynum,Ref,LastKey,0);
    Status := IsamOK;
    Error  := IsamError;
  end;

{----------------------------------------------------------}
Procedure DBtree.Search(KeySt: IsamKeyStr; KeyNum: integer);
  begin
    if RecordLocked then UnlockRecord;
    BTSetSearchForSequential(FB,KeyNum,True);
    LastKeyPath := KeyNum;
    LastKey     := KeySt;
    BTSearchKey(FB,Keynum,Position,LastKey);
    Status := IsamOK;
    Error  := IsamError;
  end;

{----------------------------------------------------------}
Procedure DBtree.Next;
  var Savepos: LongInt;
  begin
    if RecordLocked then UnlockRecord;
    Savepos := Position;
    BTNextKey(FB,LastKeyPath,Position,LastKey);
{    LastKey := StUpCase(Trim(LastKey));}
    Status := IsamOK;
    Error  := IsamError;
    if Error = 10260 then Position := SavePos; { no next key }
  end;

{----------------------------------------------------------}
Procedure DBtree.Prev;
  var Savepos: LongInt;
  begin
    if RecordLocked then UnlockRecord;
    Savepos := Position;
    BTPrevKey(FB,LastKeyPath,Position,LastKey);
    Status := IsamOK;
    Error  := IsamError;
    if Error = 10250 then Position := SavePos; { no prev key }
  end;

{----------------------------------------------------------}
Procedure DBtree.GetLocked(Size: word;var Rec);
begin

  Status := False;
  if not Variable then
    BTGetRec(FB,Position,Rec,False)
  else
    begin
      BTGetVariableRecPart(FB,Position,Rec,Size);
    end;
  Status := IsamOk;
  Error  := IsamError;
  if not LockRecord then ;
end;

{----------------------------------------------------------}
Procedure DBtree.GetReadOnly(Size: word;var Rec);
begin
  if not DbOpen then exit;
  UnlockRecord;
  Repeat
    if not Variable then
      BTGetRecReadOnly(FB,Position,Rec)
    else
      begin
        BTGetVariableRecPart(FB,Position,Rec,Size);
        BTUnlockAllRecs(FB);
      end;
  Until LastBTStatus = 0;
  RecordLocked := False;
  Status := IsamOk;
  Error  := IsamError;
end;

{----------------------------------------------------------}
Function  DBTree.GetSize: word;
  begin
    BTGetVariableRecLength(FB,Position,Total_Len);
    GetSize := Total_Len;
  end;

{----------------------------------------------------------}
Procedure DBtree.AddRecord(var Rec; Len: integer);
Begin
  Status := False;
  if not LockFile then exit;
  if not Variable then
    BTAddRec(FB,Position,Rec)
  else
    BTAddVariableRec(FB,Position,Rec,Len);
  Status := IsamOk;
  Error  := IsamError;
  if (Trace) and (not Status) then
      Dialog('Add Record Failure '+Long2Str(Error),'UBTREE',Red,'OK','','');
end;

{----------------------------------------------------------}
Procedure DBtree.AddIndex(KeyNum: integer;KeySt: KeyString);
Begin
  if not FileLocked then exit;
  BTAddKey(FB,KeyNum,Position,KeySt);
  Status := IsamOk;
  Error  := IsamError;
  if Error = 0 then
    BTClearKey(FB,KeyNum);
  if (Trace) and (not Status) then
     Dialog('Add Index Failure '+Long2Str(Error),'UBTREE',Red,'OK','','');
end;

{----------------------------------------------------------}
Procedure DBtree.DeleteIndex(KeyNum: integer;KeySt: KeyString);
var
    Len: byte;
    Savepos: LongInt;
Begin
  Status := False;
  if not LockFile then exit;
  SavePos := Position;
  BTDeleteKey(FB,KeyNum,Position,KeySt);
  Position := SavePos;
  Status := IsamOk;
  Error  := IsamError;
  if Error = 0 then
    BTClearKey(FB,KeyNum);
end;

{----------------------------------------------------------}
Procedure DBTree.GetStatus(var Free: LongInt; { Various statistics            }
                           var Used: LongInt;
                           var RecSize: LongInt;
                           var NumKeys: byte);
var I: integer;
begin
  Free := BTFreeRecs(FB);
  Used := BTUsedRecs(FB);
  RecSize := BTDatRecordSize(FB);
  NumKeys := 0;
  for I := 1 to 100 do
    begin
      if BTUsedKeys(FB,I) = 0 then;
      if IsamOK then
        inc(NumKeys)
      else
        exit;
    end;
end;


{----------------------------------------------------------}
Function  DBTree.IndexCount(Index: integer): LongInt;
begin
  IndexCount := BTUsedKeys(FB,Index);
end;

{**********************************************************}
{ Non-Method Init & DeInit routines.                       }
{**********************************************************}

{----------------------------------------------------------}
Function InitBtree: boolean;
  var Pages: Array[1..2] of integer absolute PageStack;
      Net : NetSupportType;
  begin
    InitBtree := False;
    BtreeFailure := True;
    if PageStack <> 0 then
      begin
        InitBtree := True;
        BtreeFailure := False;
        exit;
      end;
    MaxBefore := MaxAvail;
    Net := NoNet;
    if SYS^.NovellSys then
      Net := Novell;
    if MinimizeHeap then
      PageStack := BTInitIsam(Net, FreeHeap+MinimizeUseOfNormalHeap, 300)
    else
      PageStack := BTInitIsam(Net, 150000, 300);
    RAMPages := Pages[2];
    EMSPages := Pages[1];
    InitStatus := IsamOK;
    InitError := IsamError;
    InitBTree := PageStack <> 0;
    MaxAfter := MaxAvail;
    BtreeFailure := False;
  end;

{----------------------------------------------------------}
Procedure CloseBTree;
  begin
    if VarInit then
      BTReleaseVariableRecBuffer;
    VarInit := false;
    PageStack := 0;
    BTExitIsam;
  end;

{----------------------------------------------------------}

Function BtreeInitialized: boolean;
  begin
    BTreeInitialized := PageStack <> 0;
  end;

{----------------------------------------------------------}

Function DatabaseExists(ArcName: PathStr): boolean;
  begin
    DatabaseExists := IsamExists(ArcName+'.'+DatExtension);
  end;

{----------------------------------------------------------}

Procedure ReserveHeapSpace(H: LongInt);
  begin
    FreeHeap := H;
  end;

{----------------------------------------------------------}

Procedure GetMemoryUsage(var RAM,EMS: integer);
  begin
    RAM := RAMpages;
    EMS := EMSpages;
  end;

End.
