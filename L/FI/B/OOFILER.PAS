{*********************************************************}
{*                   OOFILER.PAS 5.50                    *}
{*     Copyright (c) TurboPower Software 1991, 1994      *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I BTDEFINE.INC}
{$S-,R-,V-,I-,B-,F+,A-}
{$IFDEF CanAllowOverlays}
  {$O+}
{$ENDIF}
{$IFDEF CanSetOvrflowCheck}
  {$Q-}
{$ENDIF}

{.$DEFINE UseStreams}      {!!.42 define to add OPRO-compatible streams support}

unit OoFiler;
  {-Simple fileblock object}

  {*************************************************************************
  Assumptions:
    - first four bytes of rec are Deletion flag (unless IsDeleted overridden)
    - fileblock locks only (no record locks) are used
    - no operations are done "in spite of" lock
    - application uses OOFILER's locking methods for all locking
    - zero or one keys per record per index
    - records are no longer than $FFF0 bytes

  Features:
    - fixed and variable length operations handled transparently (with OOVREC)
    - single-user and network fileblocks handled transparently
    - high level AddRecord, DeleteRecord, ModifyRecord, Rebuild provided
    - single fileblock locking is handled automatically
    - automatic undo in case of errors while adding, deleting, modifying a
      record
  **************************************************************************}

interface

uses
  {$IFDEF UseStreams}
  OpRoot,
  {$ENDIF}
  Filer;

const
  TooManyRetries = 8100;             {IsamError meaning too many retries}
  RecordModified = 8101;             {Another station modified record}
  RecordDeleted  = 8102;             {Another station deleted record}
  UndoError      = 8103;             {Error undoing changes after another error}
  OutOfMemory    = 8108;             {No memory for a temporary record}

{$IFDEF BTree54}                     {!!.41}
const                                {!!.41}
  IsamReadTimeOut : Word = 768;      {Milliseconds for non-lock timeouts} {!!.41}
{$ENDIF}                             {!!.41}

{$IFDEF UseStreams}
const
  otFileblock = 997;                 {Object type number for streams}
  veFileblock = 00;                  {Object version number for streams}
{$ENDIF}

type
  FileblockPtr = ^Fileblock;
  Fileblock =
    {$IFDEF UseStreams}
    object(Root)
    {$ELSE}
    object
    {$ENDIF}
      IFB         : IsamFileBlockPtr;{The low-level fileblock variable}
      OrigName    : IsamFileBlockName;{File name passed to constructor}
      LockLev     : Integer;         {Positive when write locked}
      ReadLockLev : Integer;         {Positive when read locked}
      AddNulls    : Boolean;         {True to add null keys}
      Tries       : LongInt;         {Number of retries for locking}
      TempRecPtr  : Pointer;         {Pointer to temporary record}
      TempRecSize : Word;            {Size of buffer for temporary record}

      {---- constructors and destructors ----}
      constructor Create(FName : IsamFileBlockName;
                         RecordLen : LongInt;
                         NrOfIndexes : Word;
                         var IID : IsamIndDescr;
                         ReadOnly, AllReadOnly, Save, Net : Boolean);
        {-Create new fileblock and open it in the specified mode}
      constructor Init(FName : IsamFileBlockName;
                       ReadOnly, AllReadOnly, Save, Net : Boolean);
        {-Open an existing fileblock in the specified mode}
      constructor Recover(FName : IsamFileBlockName;
                          RecordLen : LongInt;
                          NrOfIndexes : Word;
                          var IID : IsamIndDescr;
                          AddNull : Boolean;
                          ReadOnly, AllReadOnly, Save, Net : Boolean);
         {-Open an existing fileblock that has a corrupted index}
      constructor Reorganize(FName : IsamFileBlockName;
                             OldRecordLen, NewRecordLen : LongInt;
                             NewNrOfIndexes : Word;
                             var NewIID : IsamIndDescr;
                             AddNull : Boolean;
                             ReadOnly, AllReadOnly, Save, Net : Boolean); {!!.23}
         {-Reorganize a data file leaving a new, opened fileblock}
      destructor Done; virtual;
        {-Close an open fileblock}
      destructor Delete;
        {-Close fileblock and erase its files}

      {---- options ----}
      procedure NullKeys(Add : Boolean);
        {-Enable or disable addition of null key strings}
      procedure AllocTempRec(Size : Word);
        {-Allocate a permanent temporary record buffer}

      {---- must be overridden ----}
      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
        {-Return key string for given record and index number}
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
        {-Return True if two records are considered to be the same}
      function RecLen(var Rec) : Word; virtual;
        {-Return the length of a record in memory (only for VREC)}
      function ConvertRec(var OldRec, NewRec; var Len : Word) : Boolean; virtual; {!!.23}
        {-Convert old record to new record (only for Reorganize constructor)}

      {---- may be overridden but are not usually called directly ----}
      function LockError : Boolean; virtual;
        {-Called to test whether last operation failed because of lock error}
      procedure RebuildStatus(KeyNr : Word;
                              RecsRead, RecsWritten : LongInt;
                              var Rec; Len : Word); virtual;
        {-Called during rebuild and reorg for status reporting}
      procedure HardError; virtual;
        {-Called when error of class 3 or 4 occurs}
      procedure FileblockIsOpen; virtual;
        {-Called when Fileblock has been opened successfully}
      procedure FileblockIsClosed; virtual;
        {-Called when Fileblock has been closed successfully}
      function AssureFileblockOpen : Boolean; virtual;
        {-Called on entry to each public routine that assumes an open Fileblock}

      {---- may be overridden and/or called directly ----}
      function IsDeleted(var Rec) : Boolean; virtual;
        {-Return True if the record is deleted}
      function GetRecLen(RefNr : LongInt) : Word; virtual;
        {-Return the length of an existing record on disk}
      procedure GetRecAndLen(RefNr : LongInt; var Rec; var Len : Word); virtual;
        {-Read record, returning length}
      procedure Lock; virtual;
        {-Lock the fileblock for exclusive write access}
      procedure ReadLock; virtual;
        {-Prevent other stations from modifying fileblock}
      procedure Unlock; virtual;
        {-Remove read or write locks}
      function IsLocked : Boolean; virtual;
        {-Return True if fileblock locked for write access}
      function IsReadLocked : Boolean; virtual;
        {-Return True if fileblock is read-locked}

      {---- high level routines ----}
      procedure AddRecord(var RefNr : LongInt; var Rec);
        {-Add a record Rec and its keys, returning reference number}
      procedure DeleteRecord(RefNr : LongInt; var Rec);
        {-Delete record with reference number RefNr and data Rec}
      procedure ModifyRecord(RefNr : LongInt; var OldRec, NewRec);
        {-Modify record with reference number RefNr. OldRec is the previous
          data of the record. NewRec is the new data. These are used to
          validate that another workstation hasn't modified the record in
          the meantime and to verify that changes were made before going
          to the effort of the fileblock update}
      procedure Rebuild;
        {-Rebuild the fileblock}

      {---- shells around FILER procedures ----}
      procedure GetRec(RefNr : LongInt; var Rec);
        {-Read record, not returning length}
      procedure PutRec(RefNr : LongInt; var Rec); virtual;
        {-Update a record without updating keys}
      procedure Flush;
        {-Assure that all data and index info goes to disk}

      function DataName : IsamFileName;
        {-Return data file's name}
      function IndexName : IsamFileName;
        {-Return index file's name}
      function IsNet : Boolean;
        {-Return True if network fileblock}
      function IsSave : Boolean;
        {-Return True if fileblock opened in save mode}
      function IsReadOnly : Boolean;
        {-Return True if fileblock opened in read-only mode}
      function UsedRecs : LongInt;
        {-Return number of valid records in data file}
      function FreeRecs : LongInt;
        {-Return number of deleted records in data file}
      function TotalRecs : LongInt;
        {-Return total number of records in data file}
      function UsedKeys(KeyNr : Word) : LongInt;
        {-Return number of keys in index KeyNr}
      function IndexCount : Word;
        {-Return number of indexes}
      function SectSize : Word;
        {-Returns size of each data record or section}

      procedure ClearKey(KeyNr : Word);
        {-Reset sequential pointer for specified index}
      procedure NextKey(KeyNr : Word; var RefNr : LongInt;
                        var KeyStr : IsamKeyStr);
        {-Advance sequential pointer, returning key and reference}
      procedure PrevKey(KeyNr : Word; var RefNr : LongInt;
                        var KeyStr : IsamKeyStr);
        {-Decrement sequential pointer, returning key and reference}
      procedure FindKey(KeyNr : Word; var RefNr : LongInt;
                        KeyStr : IsamKeyStr);
        {-Find matching key string, returning reference number}
      procedure SearchKey(KeyNr : Word; var RefNr : LongInt;
                          var KeyStr : IsamKeyStr);
        {-Find matching key string, or next larger, returning both
          reference number and key string}
      procedure FindKeyAndRef(KeyNr : Word; var RefNr : LongInt;
                              var KeyStr : IsamKeyStr;
                              Search : Integer);
        {-Position sequential pointer at specified key string and
          reference number; if not found, search up if Search is positive,
          search down if Search is negative,
          or quit with error if Search is zero}
      function KeyExists(KeyNr : Word; RefNr : LongInt;
                         KeyStr : IsamKeyStr) : Boolean;
        {-Return True if specified key string and reference is in index}
      procedure NextDiffKey(KeyNr : Word; var RefNr : LongInt;
                            var KeyStr : IsamKeyStr);
        {-Advance sequential pointer to next different key string,
          returning key and reference}
      procedure PrevDiffKey(KeyNr : Word; var RefNr : LongInt;
                            var KeyStr : IsamKeyStr);
        {-Decrement sequential pointer to previous different key string,
          returning key and reference}

      {$IFDEF UseStreams}
      {---- Stream support ----}
      constructor Load(var S: IdStream);
      procedure Store(var S: IdStream);
      {$ENDIF}

      {---- for internal use ----}
      {.Z+}
      procedure AddRec(var RefNr : LongInt; var Rec); virtual;
        {-Add a new record without updating keys}
      procedure DelRec(RefNr : LongInt); virtual;
        {-Delete a record without deleting keys}
      procedure RebuildPrim(RecordLen : LongInt; NrOfIndexes : Word;
                            var IID : IsamIndDescr); virtual;
        {-Call rebuild routine}
      procedure ReorgPrim(NewLen : LongInt;
                          NewNrOfIndexes : Word;
                          var NewIID : IsamIndDescr;
                          OldLen : LongInt;
                          MaxDiffBytes : Word); virtual; {!!.23}
        {-Call reorg routine}
      procedure GetRecBuf(var P : Pointer; Len : Word);
        {-Return pointer to temporary record buffer}
      procedure FreeRecBuf(var P : Pointer; Len : Word);
        {-Deallocate temporary record buffer}
      procedure LockAndReread(RefNr : LongInt;
                              var P : Pointer; var Len : Word);
        {-Lock fileblock, allocate temp heap space, read record}
      {.Z-}
    end;

{.Z+}
procedure Abstract(RoutineName : String);
  {-Call to generate runtime error 211 for abstract method}

function KeyBuild(var Rec; KeyNr : Integer) : IsamKeyStr;
  {-BuildKey function called during a rebuild}

function ChangeDatFixed(var OldRec, NewRec; Len : Word) : Boolean; {!!.23}
  {-ChangeDat function called during reorg, for fixed length fileblocks}

procedure RebuildStat(KeyNr : Integer; DatSNrR, DatSNrW : LongInt;
                      var DatS; Len : Word);
  {-User status function called during a rebuild}
{.Z-}

{$IFDEF UseStreams}
procedure FileblockStream(SPtr: IdStreamPtr);
{$ENDIF}

var
  {Holds address of current self to interface with procedure variables}
  CurSelfPtr : FileblockPtr; {!!.23 interfaced}

  {======================================================================}

implementation

uses
  Reorg,
  Rebuild;

{!!.41 IsamRetriesForLock deleted}

function KeyBuild(var Rec; KeyNr : Integer) : IsamKeyStr;
begin
  KeyBuild := CurSelfPtr^.BuildKey(Rec, KeyNr);
end;

function ChangeDatFixed(var OldRec, NewRec; Len : Word) : Boolean; {!!.23}
begin
  ChangeDatFixed := CurSelfPtr^.ConvertRec(OldRec, NewRec, Len);
end;

procedure RebuildStat(KeyNr : Integer; DatSNrR, DatSNrW : LongInt;
                      var DatS; Len : Word);
begin
  CurSelfPtr^.RebuildStatus(KeyNr, DatSNrR, DatSNrW, DatS, Len);
end;

procedure Abstract(RoutineName : String);
begin
  {$IFNDEF Windows}                              {!!.24}
    WriteLn(RoutineName, ' must be overridden'); {!!.24}
  {$ENDIF}                                       {!!.24}
  RunError(211);
end;

  {--------------------------------------------------------------------}

constructor Fileblock.Create(FName : IsamFileBlockName;
                             RecordLen : LongInt;
                             NrOfIndexes : Word;
                             var IID : IsamIndDescr;
                             ReadOnly, AllReadOnly, Save, Net : Boolean);
begin
  BTCreateFileBlock(FName, RecordLen, NrOfIndexes, IID);
  if not IsamOK then
    Fail;
  if not Fileblock.Init(FName, ReadOnly, AllReadOnly, Save, Net) then
    Fail;
end;

constructor Fileblock.Init(FName : IsamFileBlockName;
                           ReadOnly, AllReadOnly, Save, Net : Boolean);
begin
  OrigName := FName;
  LockLev := 0;
  ReadLockLev := 0;
  AddNulls := True;
  TempRecPtr := nil;
  TempRecSize := 0;
  Tries := 0;
  repeat
    BTOpenFileBlock(IFB, FName, ReadOnly, AllReadOnly, Save, Net);
    if not IsamOK then                               {!!.23}
      case BTIsamErrorClass of                       {!!.23}
        3, 4 : Fail; {Hard error, fail constructor}  {!!.23}
      end;                                           {!!.23}
  until not LockError;
  if not IsamOK then
    Fail;
  {Notify related routine that Fileblock has been opened}
  FileblockIsOpen;
end;

constructor Fileblock.Recover(FName : IsamFileBlockName;
                              RecordLen : LongInt;
                              NrOfIndexes : Word;
                              var IID : IsamIndDescr;
                              AddNull : Boolean;
                              ReadOnly, AllReadOnly, Save, Net : Boolean);
var
  SaveAddNull : Boolean;
  SaveUserProcPtr : Pointer;
  SaveCurSelfPtr : FileblockPtr;
begin
  {Save and assign global variables}
  SaveCurSelfPtr := CurSelfPtr;
  CurSelfPtr := @Self;
  SaveAddNull := AddNullKeys;
  AddNullKeys := AddNull;
  SaveUserProcPtr := IsamReXUserProcPtr;
  IsamReXUserProcPtr := @RebuildStat;

  {Do the rebuild}
  OrigName := FName;
  RebuildPrim(RecordLen, NrOfIndexes, IID);

  {Restore global variables}
  CurSelfPtr := SaveCurSelfPtr;
  AddNullKeys := SaveAddNull;
  IsamReXUserProcPtr := SaveUserProcPtr;

  if not IsamOK then
    Fail;

  {Open the fileblock normally}
  if not Fileblock.Init(FName, ReadOnly, AllReadOnly, Save, Net) then
    Fail;

  AddNulls := AddNull;
end;

constructor Fileblock.Reorganize(FName : IsamFileBlockName; {!!.23}
                                 OldRecordLen, NewRecordLen : LongInt;
                                 NewNrOfIndexes : Word;
                                 var NewIID : IsamIndDescr;
                                 AddNull : Boolean;
                                 ReadOnly, AllReadOnly, Save, Net : Boolean);
var
  SaveAddNull : Boolean;
  SaveUserProcPtr : Pointer;
  SaveCurSelfPtr : FileblockPtr;
begin
  {Save and assign global variables}
  SaveCurSelfPtr := CurSelfPtr;
  CurSelfPtr := @Self;
  SaveAddNull := AddNullKeys;
  AddNullKeys := AddNull;
  SaveUserProcPtr := IsamReXUserProcPtr;
  IsamReXUserProcPtr := @RebuildStat;

  {Do the reorganization}
  OrigName := FName;
  ReorgPrim(NewRecordLen, NewNrOfIndexes, NewIID, OldRecordLen, 0);

  {Restore global variables}
  CurSelfPtr := SaveCurSelfPtr;
  AddNullKeys := SaveAddNull;
  IsamReXUserProcPtr := SaveUserProcPtr;

  if not IsamOK then
    Fail;

  {Open the fileblock normally}
  if not Fileblock.Init(FName, ReadOnly, AllReadOnly, Save, Net) then
    Fail;

  AddNulls := AddNull;
end;

destructor Fileblock.Done;
begin
  if TempRecSize <> 0 then
    FreeMem(TempRecPtr, TempRecSize);
  Tries := 0; {!!.24}
  repeat
    BTCloseFileBlock(IFB);
  until not LockError;
  if IsamOK then
    FileblockIsClosed;
end;

destructor Fileblock.Delete;
begin
  Done;
  if IsamOK then
    BTDeleteFileBlock(OrigName);
end;

procedure Fileblock.NullKeys(Add : Boolean);
begin
  AddNulls := Add;
end;

procedure Fileblock.AllocTempRec(Size : Word);
begin
  if MaxAvail < Size then begin
    IsamOK := False;
    IsamError := OutOfMemory;
    HardError;
    Exit;
  end;
  TempRecSize := Size;
  GetMem(TempRecPtr, Size);
end;

function Fileblock.BuildKey(var Rec; KeyNr : Word) : IsamKeyStr;
begin
  Abstract('BuildKey');
end;

function Fileblock.EqualRec(var Rec1, Rec2) : Boolean;
begin
  Abstract('EqualRec');
end;

function Fileblock.ConvertRec(var OldRec, NewRec; var Len : Word) : Boolean; {!!.23}
begin
  Abstract('ConvertRec');
end;

function Fileblock.LockError : Boolean;
{$IFDEF BTree54}  {!!.41}
var               {!!.41}
  Delay : Word;   {!!.41}
{$ENDIF}          {!!.41}
begin
  LockError := False;
  if not IsamOK then begin
    {Some kind of IsamError}
    case BTIsamErrorClass of
      1 : {Warning}
        {Let it pass} ;
      2 : {Locking error}
        begin
          {$IFDEF BTree54} {!!.41 begin}
          if Tries < IsamReadTimeOut then begin
            Delay := Random(IsamDelayBetwLocks)+1;
            if Tries+Delay > IsamReadTimeOut then
              Delay := IsamReadTimeOut-Tries;
            IsamDelay(Delay);
            inc(Tries, Delay);
            LockError := True;
          end else begin
            {Too many retries, convert to a hard error}
            IsamError := TooManyRetries;
            HardError;
          end;
          {$ELSE}          {!!.41 end}
          inc(Tries);
          if Tries > IsamRetriesForLock then begin
            {Too many retries, convert to a hard error}
            IsamError := TooManyRetries;
            HardError;
          end else begin
            if IsamDelayBetwLocks > 0 then
              IsamDelay(Random(IsamDelayBetwLocks)+1);
            LockError := True;
          end;
          {$ENDIF}
        end;
    else  {Severe error}
      HardError;
    end;
  end;
end;

procedure Fileblock.PutRec(RefNr : LongInt; var Rec);
begin
  if not AssureFileblockOpen then
    Exit;
  Lock;
  if not IsamOK then
    Exit;
  BTPutRec(IFB, RefNr, Rec, False);
  if not IsamOK then
    HardError;
  Unlock;
end;

procedure Fileblock.AddRec(var RefNr : LongInt; var Rec);
begin
  Lock;
  if not IsamOK then
    Exit;
  BTAddRec(IFB, RefNr, Rec);
  if not IsamOK then
    HardError;
  Unlock;
end;

procedure Fileblock.DelRec(RefNr : LongInt);
begin
  Lock;
  if not IsamOK then
    Exit;
  BTDeleteRec(IFB, RefNr);
  if not IsamOK then
    HardError;
  Unlock;
end;

function Fileblock.IsDeleted(var Rec) : Boolean;
begin
  IsDeleted := (LongInt(Rec) <> 0);
end;

function Fileblock.GetRecLen(RefNr : LongInt) : Word;
begin
  GetRecLen := SectSize;
end;

function Fileblock.RecLen(var Rec) : Word;
begin
  RecLen := SectSize;
end;

procedure Fileblock.GetRecAndLen(RefNr : LongInt; var Rec; var Len : Word);
begin
  if not AssureFileblockOpen then
    Exit;
  Len := SectSize;
  Tries := 0; {!!.24}
  repeat
    BTGetRec(IFB, RefNr, Rec, False);
  until not LockError;
end;

procedure Fileblock.RebuildStatus(KeyNr : Word;
                                  RecsRead, RecsWritten : LongInt;
                                  var Rec; Len : Word);
begin
  {Does nothing by default}
end;

procedure Fileblock.HardError;
begin
  {Does nothing by default}
end;

procedure Fileblock.FileblockIsOpen;
begin
  {Does nothing by default}
end;

procedure Fileblock.FileblockIsClosed;
begin
  {Does nothing by default}
end;

function Fileblock.AssureFileblockOpen : Boolean;
begin
  AssureFileblockOpen := True;
end;

procedure Fileblock.RebuildPrim(RecordLen : LongInt; NrOfIndexes : Word;
                                var IID : IsamIndDescr);
begin
  RebuildFileBlock(OrigName, RecordLen, NrOfIndexes, IID, @KeyBuild);
  if not IsamOK then
    HardError;
end;

procedure Fileblock.ReorgPrim(NewLen : LongInt;
                              NewNrOfIndexes : Word;
                              var NewIID : IsamIndDescr;
                              OldLen : LongInt;
                              MaxDiffBytes : Word); {!!.23}
begin
  ReorgFileBlock(OrigName, NewLen, NewNrOfIndexes,
                 NewIID, OldLen, @KeyBuild, @ChangeDatFixed);
  if not IsamOK then
    HardError;
end;

procedure Fileblock.Rebuild;
var
  KeyNr : Word;
  Count : Word;
  Size : Word;
  ReadOnly : Boolean;
  AllReadOnly : Boolean;
  Save : Boolean;
  Net : Boolean;
  SaveAddNull : Boolean;
  SaveUserProcPtr : Pointer;
  SaveCurSelfPtr : FileblockPtr;
  IID : IsamIndDescr;
begin
  if not AssureFileblockOpen then
    Exit;

  {Build an IID for the rebuild}
  for KeyNr := 1 to IndexCount do
    with IID[KeyNr], IFB^.DIDPtr^[KeyNr]^ do begin
      KeyL := KeyLen;
      AllowDupK := AllowDupKeys;
    end;

  {Save variables that will be lost when fileblock is closed}
  Count := IndexCount;
  Size := SectSize;
  ReadOnly := IFB^.ReadOnlyFB;
  AllReadOnly := False; {Must be false or a rebuild is impossible}
  Save := IsSave;
  Net := IsNet;

  {Close the fileblock temporarily}
  Tries := 0;
  repeat
    BTCloseFileBlock(IFB);
  until not LockError;
  if not IsamOK then
    Exit;
  FileblockIsClosed;

  {Save and assign global variables}
  SaveCurSelfPtr := CurSelfPtr;
  CurSelfPtr := @Self;
  SaveAddNull := AddNullKeys;
  AddNullKeys := AddNulls;
  SaveUserProcPtr := IsamReXUserProcPtr;
  IsamReXUserProcPtr := @RebuildStat;

  {Do the rebuild}
  RebuildPrim(Size, Count, IID);

  {Restore global variables}
  CurSelfPtr := SaveCurSelfPtr;
  AddNullKeys := SaveAddNull;
  IsamReXUserProcPtr := SaveUserProcPtr;

  if IsamOK then begin
    {Reopen fileblock}
    Tries := 0;
    repeat
      BTOpenFileBlock(IFB, OrigName, ReadOnly, AllReadOnly, Save, Net);
    until not LockError;
    if IsamOK then
      FileblockIsOpen;
  end;
end;

procedure Fileblock.AddRecord(var RefNr : LongInt; var Rec);
var
  KeyNr : Word;
  KeyStr : IsamKeyStr;

  procedure Undo(LastKey : Word);
  label
    ExitPoint;
  var
    K : Word;
    SaveError : Integer;
  begin
    SaveError := IsamError;
    IsamClearOK; {!!.22}
    for K := 1 to LastKey do begin
      IsamClearOK; {!!.42}
      KeyStr := BuildKey(Rec, K); {!!.23}
      if not IsamOK then begin
        {Too many errors, don't try to continue with indexes}
        SaveError := UndoError;
        goto ExitPoint;
      end;
      BTDeleteKey(IFB, K, RefNr, KeyStr);
      if (not IsamOK) and (IsamError <> 10220) then begin
        {Too many errors, don't try to continue with indexes}
        SaveError := UndoError;
        goto ExitPoint;
      end;
    end;
ExitPoint:
    BTDeleteRec(IFB, RefNr);
    if not IsamOK then
      SaveError := UndoError;
    Unlock;
    IsamOK := False;
    IsamError := SaveError;
    HardError;
  end;

begin
  if not AssureFileblockOpen then
    Exit;
  Lock;
  if not IsamOK then
    Exit;
  AddRec(RefNr, Rec);
  if not IsamOK then
    Exit;
  for KeyNr := 1 to IndexCount do begin
    IsamClearOK; {!!.42}
    KeyStr := BuildKey(Rec, KeyNr);
    {BuildKey can indicate failure by setting IsamOK to False}
    if not IsamOK then begin
      Undo(KeyNr-1);
      Exit;
    end;
    if AddNulls or (Length(KeyStr) <> 0) then begin
      BTAddKey(IFB, KeyNr, RefNr, KeyStr);
      if not IsamOK then begin
        {Undo the addition}
        Undo(KeyNr-1);
        Exit;
      end;
    end;
  end;
  Unlock;
end;

procedure Fileblock.GetRecBuf(var P : Pointer; Len : Word);
begin
  if TempRecSize >= Len then
    P := TempRecPtr
  else if (TempRecSize <> 0) or (Len > MaxAvail) then
    P := nil
  else
    GetMem(P, Len);
end;

procedure Fileblock.FreeRecBuf(var P : Pointer; Len : Word);
begin
  if TempRecSize = 0 then
    FreeMem(P, Len);
end;

procedure Fileblock.LockAndReread(RefNr : LongInt;
                                  var P : Pointer; var Len : Word);
var
  SaveError : LongInt;
begin
  Lock;
  if not IsamOK then
    Exit;

  {Assure space for a temporary record}
  Len := GetRecLen(RefNr);
  if not IsamOK then begin
    HardError;
    Exit;
  end;
  GetRecBuf(P, Len);
  if P = nil then begin
    {Not enough memory or preallocated buffer too small}
    Unlock;
    IsamOK := False;
    IsamError := OutOfMemory;
    HardError;
    Exit;
  end;

  {Reread the record}
  GetRec(RefNr, P^);
  if not IsamOK then begin
    SaveError := IsamError;
    FreeRecBuf(P, Len);
    Unlock;
    IsamOK := False;
    IsamError := SaveError;
    Exit;
  end;
end;

procedure Fileblock.DeleteRecord(RefNr : LongInt; var Rec);
var
  Len : Word;
  KeyNr : Word;
  P : Pointer;
  KeyStr : IsamKeyStr;

  procedure Undo(LastKey : Word);
  label
    ExitPoint;
  var
    K : Word;
    SaveError : Integer;
  begin
    SaveError := IsamError;
    IsamClearOK; {!!.22}
    for K := 1 to LastKey do begin
      IsamClearOK; {!!.42}
      KeyStr := BuildKey(Rec, K);
      if not IsamOK then begin
        {Too many errors, don't try to continue}
        SaveError := UndoError;
        goto ExitPoint;
      end;
      if AddNulls or (Length(KeyStr) <> 0) then begin
        BTAddKey(IFB, K, RefNr, KeyStr);
        if not IsamOK then begin
          {Too many errors, don't try to continue}
          SaveError := UndoError;
          goto ExitPoint;
        end;
      end;
    end;
ExitPoint:
    Unlock;
    IsamOK := False;
    IsamError := SaveError;
    HardError;
  end;

begin
  if not AssureFileblockOpen then
    Exit;

  {Lock fileblock, get buffer, reread record into buffer}
  LockAndReread(RefNr, P, Len);
  if not IsamOK then
    Exit;

  {Check whether record was already deleted. That's not an error}
  if IsDeleted(P^) then begin
    FreeRecBuf(P, Len);
    Unlock;
    Exit;
  end;

  {It's an error if record was modified by another station}
  if not EqualRec(Rec, P^) then begin
    FreeRecBuf(P, Len);
    Unlock;
    IsamOK := False;
    IsamError := RecordModified;
    HardError;
    Exit;
  end;

  {Get rid of record buffer now}
  FreeRecBuf(P, Len);

  {Delete the keys}
  for KeyNr := 1 to IndexCount do begin
    IsamClearOK; {!!.42}
    KeyStr := BuildKey(Rec, KeyNr);
    if not IsamOK then begin
      Undo(KeyNr-1);
      Exit;
    end;
    {if AddNulls or (Length(KeyStr) <> 0) then begin} {!!.41}
      BTDeleteKey(IFB, KeyNr, RefNr, KeyStr);
      if (not IsamOK) and (IsamError <> 10220) then begin
        {Key already deleted is OK}
        Undo(KeyNr-1);
        Exit;
      end;
    {end;}                                            {!!.41}
  end;

  {Delete the record}
  DelRec(RefNr);
  if not IsamOK then begin
    Undo(IndexCount);
    Exit;
  end;

  Unlock;
end;

procedure Fileblock.ModifyRecord(RefNr : LongInt; var OldRec, NewRec);
var
  Len : Word;
  KeyNr : Word;
  P : Pointer;
  KeyStr : IsamKeyStr;
  OldStr : IsamKeyStr;

  procedure Undo(LastKey : Word; DeleteLastAdd : Boolean); {!!.24}
  label
    ExitPoint;
  var
    K : Word;
    SaveError : Integer;
  begin
    SaveError := IsamError;
    {IsamClearOK;} {!!.22} {!!.42}
    for K := 1 to LastKey do begin
      IsamClearOK; {!!.42}
      KeyStr := BuildKey(NewRec, K);
      if IsamOK then
        OldStr := BuildKey(OldRec, K);
      if not IsamOK then begin
        {Too many errors, don't try to continue}
        SaveError := UndoError;
        goto ExitPoint;
      end;
      if KeyStr <> OldStr then begin
        if (K < LastKey) or DeleteLastAdd then begin {!!.24}
          {Delete the new key}
          BTDeleteKey(IFB, K, RefNr, KeyStr);
          if (not IsamOK) and (IsamError <> 10220) then begin
            {New key not found is OK}
            {Otherwise, too many errors, don't try to continue}
            SaveError := UndoError;
            goto ExitPoint;
          end;
        end;                                         {!!.24}
        {Add the old key}
        if AddNulls or (Length(OldStr) <> 0) then begin
          BTAddKey(IFB, K, RefNr, OldStr);
          if not IsamOK then begin
            {Too many errors, don't try to continue}
            SaveError := UndoError;
            goto ExitPoint;
          end;
        end;
      end;
    end;
ExitPoint:
    Unlock;
    IsamOK := False;
    IsamError := SaveError;
    HardError;
  end;

begin
  {Don't do any work if old and new are the same}
  IsamClearOK;
  if EqualRec(OldRec, NewRec) then
    Exit;

  if not AssureFileblockOpen then
    Exit;

  {Lock fileblock, allocate buffer, reread record into buffer}
  LockAndReread(RefNr, P, Len);
  if not IsamOK then
    Exit;

  {It's an error if record was already deleted}
  if IsDeleted(P^) then begin
    FreeRecBuf(P, Len);
    Unlock;
    IsamOK := False;
    IsamError := RecordDeleted;
    HardError;
    Exit;
  end;

  {It's an error if record was modified by another station}
  if not EqualRec(OldRec, P^) then begin
    FreeRecBuf(P, Len);
    Unlock;
    IsamOK := False;
    IsamError := RecordModified;
    HardError;
    Exit;
  end;

  {Get rid of record buffer now}
  FreeRecBuf(P, Len);

  {Modify the keys}
  for KeyNr := 1 to IndexCount do begin
    IsamClearOK; {!!.42}
    KeyStr := BuildKey(NewRec, KeyNr);
    if IsamOK then
      OldStr := BuildKey(OldRec, KeyNr);
    if not IsamOK then begin
      Undo(KeyNr-1, True); {!!.24}
      Exit;
    end;
    if KeyStr <> OldStr then begin
      BTDeleteKey(IFB, KeyNr, RefNr, OldStr);
      if (not IsamOK) and (IsamError <> 10220) then begin
        {Key already deleted is OK}
        Undo(KeyNr-1, True); {!!.24}
        Exit;
      end;
      if AddNulls or (Length(KeyStr) <> 0) then begin
        BTAddKey(IFB, KeyNr, RefNr, KeyStr);
        if not IsamOK then begin
          Undo(KeyNr, False); {!!.24}
          Exit;
        end;
      end;
    end;
  end;

  {Update the record}
  PutRec(RefNr, NewRec);
  if not IsamOK then begin
    Undo(IndexCount, True); {!!.24}
    Exit;
  end;

  Unlock;
end;

procedure Fileblock.Lock;
begin
  if not AssureFileblockOpen then
    Exit;
  IsamClearOK;
  if not IsNet then
    Exit;
  if LockLev > 0 then
    {Already locked}
    IsamClearOK
  else begin                    {!!.41} {!!.42}
    {Try to lock now}
    BTLockFileBlock(IFB);
    {Access error hooks, no retries}    {!!.42}
    Tries := $FFFF;                     {!!.42}
    if LockError then ;                 {!!.42}
  end;                                  {!!.42}
  if IsamOK then
    inc(LockLev)
  else
    LockLev := 0;
  ReadLockLev := 0;
end;

procedure Fileblock.ReadLock;
begin
  if not AssureFileblockOpen then
    Exit;
  IsamClearOK;
  if not IsNet then
    Exit;
  if ReadLockLev > 0 then
    {Already read-locked}
    IsamClearOK
  else begin                    {!!.41} {!!.42}
    {Try to read-lock now}
    BTReadLockFileBlock(IFB);
    {Access error hooks, no retries}    {!!.42}
    Tries := $FFFF;                     {!!.42}
    if LockError then ;                 {!!.42}
  end;                                  {!!.42}
  if IsamOK then
    inc(ReadLockLev)
  else
    ReadLockLev := 0;
  LockLev := 0;
end;

procedure Fileblock.Unlock;
var
  SaveOK : Boolean;
  SaveError : Integer;
begin
  {This routine preserves the state of IsamError unless
   IsamError was previously zero and an error occurs while unlocking}
  if not IsNet then
    Exit;
  SaveOK := IsamOK;
  SaveError := IsamError;
  if not AssureFileblockOpen then
    Exit;
  if (ReadLockLev = 1) or (LockLev = 1) then
    BTUnlockFileBlock(IFB);
  if not IsamOK then
    HardError
  else begin
    if ReadLockLev > 0 then
      dec(ReadLockLev);
    if LockLev > 0 then
      dec(LockLev);
  end;
  if (SaveError <> 0) or IsamOK then begin
    {Restore previous error state}
    IsamOK := SaveOK;
    IsamError := SaveError;
  end;
end;

function Fileblock.IsLocked : Boolean;
begin
  if not AssureFileblockOpen then begin
    IsLocked := False;
    Exit;
  end;
  IsLocked := BTFileBlockIsLocked(IFB);
end;

function Fileblock.IsReadLocked : Boolean;
begin
  if not AssureFileblockOpen then begin
    IsReadLocked := False;
    Exit;
  end;
  IsReadLocked := BTFileBlockIsReadLocked(IFB);
end;

procedure Fileblock.Flush;
begin
  if not AssureFileblockOpen then
    Exit;
  Lock;
  if not IsamOK then
    Exit;
  BTFlushFileBlock(IFB);
  if not IsamOK then
    HardError;
  Unlock;
end;

procedure Fileblock.GetRec(RefNr : LongInt; var Rec);
var
  Len : Word;
begin
  {GetRecAndLen assures fileblock is open}
  GetRecAndLen(RefNr, Rec, Len);
end;

function Fileblock.DataName : IsamFileName;
begin
  if not AssureFileblockOpen then begin
    DataName := '';
    Exit;
  end;
  DataName := BTDataFileName(IFB);
end;

function Fileblock.IndexName : IsamFileName;
begin
  if not AssureFileblockOpen then begin
    IndexName := '';
    Exit;
  end;
  IndexName := BTIndexFileName(IFB);
end;

function Fileblock.IsNet : Boolean;
begin
  if not AssureFileblockOpen then begin
    IsNet := False;
    Exit;
  end;
  IsNet := BTIsNetFileBlock(IFB);
end;

function Fileblock.IsSave : Boolean;
begin
  if not AssureFileblockOpen then begin
    IsSave := False;
    Exit;
  end;
  IsSave := IFB^.SaveFB;
end;

function Fileblock.IsReadOnly : Boolean;
begin
  if not AssureFileblockOpen then begin
    IsReadOnly := False;
    Exit;
  end;
  IsReadOnly := IFB^.ReadOnlyFB;
end;

function Fileblock.UsedRecs : LongInt;
begin
  if not AssureFileblockOpen then begin
    UsedRecs := 0;
    Exit;
  end;
  Tries := 0;
  repeat
    UsedRecs := BTUsedRecs(IFB);
  until not LockError;
end;

function Fileblock.FreeRecs : LongInt;
begin
  if not AssureFileblockOpen then begin
    FreeRecs := 0;
    Exit;
  end;
  Tries := 0;
  repeat
    FreeRecs := BTFreeRecs(IFB);
  until not LockError;
end;

function Fileblock.TotalRecs : LongInt;
begin
  if not AssureFileblockOpen then begin
    TotalRecs := 0;
    Exit;
  end;
  Tries := 0;
  repeat
    TotalRecs := BTFileLen(IFB);
  until not LockError;
end;

function Fileblock.UsedKeys(KeyNr : Word) : LongInt;
begin
  if not AssureFileblockOpen then begin
    UsedKeys := 0;
    Exit;
  end;
  Tries := 0;
  repeat
    UsedKeys := BTUsedKeys(IFB, KeyNr);
  until not LockError;
end;

function Fileblock.IndexCount : Word;
begin
  if not AssureFileblockOpen then begin
    IndexCount := 0;
    Exit;
  end;
  IndexCount := BTNrOfKeys(IFB);
end;

function Fileblock.SectSize : Word;
begin
  if not AssureFileblockOpen then begin
    SectSize := 0;
    Exit;
  end;
  SectSize := BTDatRecordSize(IFB);
end;

procedure Fileblock.ClearKey(KeyNr : Word);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0;
  repeat
    BTClearKey(IFB, KeyNr);
  until not LockError;
end;

procedure Fileblock.NextKey(KeyNr : Word; var RefNr : LongInt;
                            var KeyStr : IsamKeyStr);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0;
  repeat
    BTNextKey(IFB, KeyNr, RefNr, KeyStr);
  until not LockError;
end;

procedure Fileblock.PrevKey(KeyNr : Word; var RefNr : LongInt;
                            var KeyStr : IsamKeyStr);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0;
  repeat
    BTPrevKey(IFB, KeyNr, RefNr, KeyStr);
  until not LockError;
end;

procedure Fileblock.FindKey(KeyNr : Word; var RefNr : LongInt;
                            KeyStr : IsamKeyStr);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0;
  repeat
    BTFindKey(IFB, KeyNr, RefNr, KeyStr);
  until not LockError;
end;

procedure Fileblock.SearchKey(KeyNr : Word; var RefNr : LongInt;
                              var KeyStr : IsamKeyStr);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0;
  repeat
    BTSearchKey(IFB, KeyNr, RefNr, KeyStr);
  until not LockError;
end;

procedure Fileblock.FindKeyAndRef(KeyNr : Word; var RefNr : LongInt;
                                  var KeyStr : IsamKeyStr;
                                  Search : Integer);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0;
  repeat
    BTFindKeyAndRef(IFB, KeyNr, RefNr, KeyStr, Search);
  until not LockError;
end;

function Fileblock.KeyExists(KeyNr : Word; RefNr : LongInt;
                             KeyStr : IsamKeyStr) : Boolean;
begin
  if not AssureFileblockOpen then begin
    KeyExists := False;
    Exit;
  end;
  Tries := 0;
  repeat
    KeyExists := BTKeyExists(IFB, KeyNr, RefNr, KeyStr);
  until not LockError;
end;

procedure Fileblock.NextDiffKey(KeyNr : Word; var RefNr : LongInt;
                                var KeyStr : IsamKeyStr);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0;
  repeat
    BTNextDiffKey(IFB, KeyNr, RefNr, KeyStr);
  until not LockError;
end;

procedure Fileblock.PrevDiffKey(KeyNr : Word; var RefNr : LongInt;
                                var KeyStr : IsamKeyStr);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0;
  repeat
    BTPrevDiffKey(IFB, KeyNr, RefNr, KeyStr);
  until not LockError;
end;

{$IFDEF UseStreams}
constructor Fileblock.Load(var S: IdStream);
var
  KeyNr : Word;
  Count : Word;
  Size : Word;
  ReadOnly : Boolean;
  AllReadOnly : Boolean;
  Save : Boolean;
  Net : Boolean;
  SaveAddNull : Boolean;
  OName : IsamFileBlockName;
  IID : IsamIndDescr;
begin
  if not Root.Init then
    Fail;

  OName := S.ReadString;
  S.Read(Count, SizeOf(Count));
  S.Read(Size, SizeOf(Size));
  S.Read(ReadOnly, SizeOf(ReadOnly));
  S.Read(AllReadOnly, SizeOf(AllReadOnly));
  S.Read(Save, SizeOf(Save));
  S.Read(Net, SizeOf(Net));
  S.Read(SaveAddNull, SizeOf(SaveAddNull));
  S.Read(IID, SizeOf(IsamIndDescr));

  if not Fileblock.Init(OName, ReadOnly, AllReadOnly, Save, Net) then
    if IsamError = 9903 then begin
      {Data file not found, create it}
      if not Fileblock.Create(OName, Size, Count, IID,
                              ReadOnly, AllReadOnly, Save, Net) then
        Fail;
    end else
      Fail;

  AddNulls := SaveAddNull;
end;

procedure Fileblock.Store(var S: IdStream);
var
  KeyNr : Word;
  Count : Word;
  Size : Word;
  ReadOnly : Boolean;
  AllReadOnly : Boolean;
  Save : Boolean;
  Net : Boolean;
  SaveAddNull : Boolean;
  IID : IsamIndDescr;
begin
  if not AssureFileblockOpen then
    Exit;

  {Build an IID to store in stream}
  for KeyNr := 1 to IndexCount do
    with IID[KeyNr], IFB^.DIDPtr^[KeyNr]^ do begin
      KeyL := KeyLen;
      AllowDupK := AllowDupKeys;
    end;

  {Get variables to store in stream}
  Count := IndexCount;
  Size := SectSize;
  ReadOnly := IFB^.ReadOnlyFB;
  Save := IsSave;
  Net := IsNet;
  if Net then
    AllReadOnly := IFB^.NSP^.AllStationsReadOnly
  else
    AllReadOnly := False;
  SaveAddNull := AddNulls;

  S.WriteString(OrigName);
  S.Write(Count, SizeOf(Count));
  S.Write(Size, SizeOf(Size));
  S.Write(ReadOnly, SizeOf(ReadOnly));
  S.Write(AllReadOnly, SizeOf(AllReadOnly));
  S.Write(Save, SizeOf(Save));
  S.Write(Net, SizeOf(Net));
  S.Write(SaveAddNull, SizeOf(SaveAddNull));
  S.Write(IID, SizeOf(IsamIndDescr));
end;

procedure FileblockStream(SPtr: IdStreamPtr);
begin
  with SPtr^ do
    RegisterType(otFileblock, veFileblock,
                 TypeOf(Fileblock),
                 @Fileblock.Store, @Fileblock.Load);
end;
{$ENDIF}
end.


