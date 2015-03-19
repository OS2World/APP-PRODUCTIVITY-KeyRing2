{*********************************************************}
{*                    OOVREC.PAS 5.50                    *}
{*     Copyright (c) TurboPower Software 1991, 1994.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$S-,R-,V-,I-,B-,F+,A-}
{$IFNDEF Windows} {!!.24}
  {$O+}           {!!.24}
{$ENDIF}          {!!.24}

unit OoVrec;
  {-Simple variable length record fileblock object}

  {*************************************************************************
  Assumptions:
    - same as in OOFILER
    - there is a deterministic way to get length of record once read
      into memory (provided by RecLen method)
  **************************************************************************}

interface

uses
  Filer,
  OOFiler;

type
  VFileblockPtr = ^VFileblock;
  VFileblock =
    object(Fileblock)
      constructor Reorganize(FName : IsamFileBlockName;
                             OldSectionLen, NewSectionLen : LongInt;
                             NewNrOfIndexes : Word;
                             var NewIID : IsamIndDescr;
                             MaxDiffBytes : Word;
                             AddNull : Boolean;
                             ReadOnly, AllReadOnly, Save, Net : Boolean); {!!.23}
         {-Reorganize a data file leaving a new, opened fileblock}

      {---- must be overridden ----}
      function RecLen(var Rec) : Word; virtual;
        {-Return the length of a record in memory}

      {---- override Fileblock methods for variable length action ----}
      {.Z+}
      function GetRecLen(RefNr : LongInt) : Word; virtual;
        {-Return the length of an existing record on disk}
      procedure GetRecAndLen(RefNr : LongInt; var Rec; var Len : Word); virtual;
        {-Read record, returning length}
      procedure PutRec(RefNr : LongInt; var Rec); virtual;
        {-Update a record without updating keys}
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
      {.Z-}
    end;

{.Z+}
function ChangeDatVar(var OldRec, NewRec; var Len : Word) : Boolean; {!!.23}
  {-ChangeDat function called during reorg, for variable length fileblocks}
{.Z-}

  {======================================================================}

implementation

uses
  VRec,
  VReorg,
  VRebuild;

function ChangeDatVar(var OldRec, NewRec; var Len : Word) : Boolean; {!!.23}
begin
  ChangeDatVar := CurSelfPtr^.ConvertRec(OldRec, NewRec, Len);
end;

constructor VFileblock.Reorganize(FName : IsamFileBlockName;
                                  OldSectionLen, NewSectionLen : LongInt;
                                  NewNrOfIndexes : Word;
                                  var NewIID : IsamIndDescr;
                                  MaxDiffBytes : Word;
                                  AddNull : Boolean;
                                  ReadOnly, AllReadOnly, Save, Net : Boolean); {!!.23}
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
  ReorgPrim(NewSectionLen, NewNrOfIndexes, NewIID, OldSectionLen, MaxDiffBytes);

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

function VFileblock.RecLen(var Rec) : Word;
begin
  Abstract('RecLen');
end;

function VFileblock.GetRecLen(RefNr : LongInt) : Word;
var
  Len : Word;
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0; {!!.24}
  repeat
    BTGetVariableRecLength(IFB, RefNr, Len);
  until not LockError;
  if IsamOK then
    GetRecLen := Len
  else
    GetRecLen := 0;
end;

procedure VFileblock.GetRecAndLen(RefNr : LongInt; var Rec; var Len : Word);
begin
  if not AssureFileblockOpen then
    Exit;
  Tries := 0; {!!.24}
  repeat
    BTGetVariableRec(IFB, RefNr, Rec, Len);
  until not LockError;
end;

procedure VFileblock.PutRec(RefNr : LongInt; var Rec);
begin
  if not AssureFileblockOpen then {!!.24}
    Exit;                         {!!.24}
  Lock;
  if not IsamOK then
    Exit;
  BTPutVariableRec(IFB, RefNr, Rec, RecLen(Rec));
  if not IsamOK then
    HardError;
  Unlock;
end;

procedure VFileblock.AddRec(var RefNr : LongInt; var Rec);
begin
  Lock;
  if not IsamOK then
    Exit;
  BTAddVariableRec(IFB, RefNr, Rec, RecLen(Rec));
  if not IsamOK then
    HardError;
  Unlock;
end;

procedure VFileblock.DelRec(RefNr : LongInt);
begin
  Lock;
  if not IsamOK then
    Exit;
  BTDeleteVariableRec(IFB, RefNr);
  if not IsamOK then
    HardError;
  Unlock;
end;

procedure VFileblock.RebuildPrim(RecordLen : LongInt; NrOfIndexes : Word;
                                 var IID : IsamIndDescr);
begin
  RebuildVFileBlock(OrigName, RecordLen, NrOfIndexes, IID, @KeyBuild);
  if not IsamOK then
    HardError;
end;

procedure VFileblock.ReorgPrim(NewLen : LongInt;
                               NewNrOfIndexes : Word;
                               var NewIID : IsamIndDescr;
                               OldLen : LongInt;
                               MaxDiffBytes : Word); {!!.23}
begin
  ReorgVFileBlock(OrigName, NewLen, NewNrOfIndexes,
                  NewIID, OldLen, MaxDiffBytes,
                  @KeyBuild, @ChangeDatVar);
  if not IsamOK then
    HardError;
end;

end.
