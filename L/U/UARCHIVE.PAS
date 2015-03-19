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
{$A-,O+,F+,V-}

{.$DEFINE DbRebuild}              { Make sure this is Undefined for production }

{----------------------------------------------------------}
{ (C) NewsMaker Systems.                                   }
{ UARCHIVE - Provides support routines for the NEN system  }
{ archive. Uses Object oriented routines in UBtree for     }
{ database access.                                         }
{                                                          }
{----------------------------------------------------------}

unit UArchive;

interface

uses 
  Dos, 
  OpCrt, 
  OpString, 
  UMSg,
  QGlobal, 
  QHdrRec, 
  QScreen, 
  QDrives,
  UGLOBAL, 
  UBtree, 
  UMatrix, 
  UWindow, 
  ULib, 
  UINI, 
  UColors,
  Filer, 
  VReorg, 
  NumKeys, 
  VReindex;

type
  DateString                    = String[8];
  KeyString                     = String[40];
  KeyWordArray                  = array[1..8] of String[15];

const
  Max_Archives                  = 10; { Maximum open Database files }

  LowestDate                    : Date = (Year : 1980; Month : 1; Day : 1);
  HighestDate                   : Date = (Year : 9999; Month : 1; Day : 1);
  MatrixSearch                  : Boolean = False;

  I_Date                        : Byte = 1;
  I_ReverseDate                 : Byte = 2;
  I_TapeNumber                  : Byte = 0;
  I_FirstKeyword                : Byte = 3;

var
  Archive                       : array[1..Max_Archives] of ^DBtree; { Archive Database objects }
  AIX                           : Word; { Current Archive object }

  {----------------------------------------------------------}
  { NEN Archive Specific routines                            }

function Archive_Create(ArcName : PathStr) : Boolean;
function Archive_Put(Hdr : RunDownRec) : Boolean; { * }
procedure Archive_PutKeywords(OldKeys, NewKeys : KeyString);
function Archive_PutBuffer(Hdr : RunDownRec; var Buf; TextLen : Word) : Boolean;
function Archive_Get(K                             : Integer;
                     Key                           : SType;
                     var Hdr                       : RunDownRec) : Boolean;
function Archive_Exists(ArcName : PathStr) : Boolean;
function Archive_Update(Hdr : RunDownRec) : Boolean;
function Archive_Delete(Hdr : RunDownRec; Keys : KeyString) : Boolean;
function Archive_SetSearchCriteria(Low, High : Date; Keys : KeyString) : LongInt;
procedure Archive_ClearSearchCriteria;
function Archive_GetFirst(var Hdr : RunDownRec) : Boolean; { * }
function Archive_GetNext(var Hdr : RunDownRec) : Boolean; { * }
function Archive_GetText(Hdr : RunDownRec; var Tex) : Boolean; { * }
function Archive_Open(ArcName : PathStr; var ID : Word) : Boolean;
procedure Archive_Close(Num : Word); { * }
procedure Archive_Select(Num : Word); { * }
procedure Archive_SelectIndex(Num : Word);
function ArchiveIsOpen        : Boolean;
function Archive_Where        : LongInt;
procedure Archive_Rebuild(ArcName : PathStr);
procedure ReformatDate(InDate : Date; var Out : DateString);

implementation


var
  AMatrix                       : array[1..Max_Archives] of SearchPtr; { Search matrices }
  DataRec                       : RunDownRec; { One record       }
  LowDate                       : Date; { Iyear,Bmonth,Bday }
  HighDate                      : Date;
  LowSt                         : DateString;
  HighSt                        : DateString;
  WorkS                         : SType;
  KeyWords                      : KeyWordArray;
  Hits                          : Word;

  CurElement                    : Word;
  DateRangeSet                  : Boolean;
  KeywordCount                  : Word;
  KeysSpecified                 : Word;
  IID                           : IsamIndDescr;

const
  Delims                        : set of Char = [' ', '-', ',', '/']; { For ExtractWord }
  DateIndex                     : Integer = 2; { Initial default index for list }
  Zero                          : LongInt = 0;

  {----------------------------------------------------------}
  function Archive_Open(ArcName : PathStr; var ID : Word) : Boolean;
  var 
    I                             : Integer;
  label 
    TryAgain;
  begin
{$IFDEF TESTMODE}
ArcName := 'H:\WSYX\NEN';
{$ENDIF}
  if ID > 0 then 
  begin
  if Archive[ID] <> nil then
    if Archive[ID]^.DbFileName = ArcName then
      Exit;                       { This ones already open }
  end;
TryAgain:
  I := 0;
  AutoAllocate := True;
  ReserveHeapSpace(MemAvail - 40000);
  repeat
    Inc(I);
  until (I >= Max_Archives) or(Archive[I] = nil);
  if I > Max_Archives then 
  begin
  Archive_Open := False;
  Exit;
  end;
  AIX := I;
  DatExtension := 'ARH';
  if Archive[AIX] = nil then
    New(Archive[AIX], Init);
  Archive[AIX]^.Open(ArcName, VariableRecs);
  Archive_Open := Archive[AIX]^.IsOpen;
  if Archive[AIX]^.LastBTstatus = 10010 then  begin
      Dialog(SysMsg(001962) {'Archive Damaged, Rebuild with ARCHIVE utility'} , 'ARCHIVE', Red, 'OK', '','');
{      Archive_Rebuild(ArcName);
      Goto TryAgain;}
  Archive_Open := False;
  Exit;
  end;
  ID := AIX;
  New(AMatrix[AIX]);
  AMatrix[AIX]^.Init;
  AMatrix[AIX]^.Reset;
  Filer.DatExtension := 'DBF';
  end;

  {----------------------------------------------------------}
  procedure Archive_Close(Num : Word);
  begin
  if Archive[Num] <> nil then 
  begin
  Archive[Num]^.Close;
  Dispose(Archive[Num], Done);
  end;
  Archive[Num] := nil;
  AMatrix[Num]^.Done;
  Dispose(AMatrix[Num]);
  end;

  {----------------------------------------------------------}
  procedure Archive_Select(Num : Word);
  begin
  if Archive[Num] <> nil then
    AIX := Num;
  end;

  {----------------------------------------------------------}
  procedure Archive_SelectIndex(Num : Word);
  begin
  if Num in[1..2] then 
  begin
  DateIndex := Num;
  end;
  end;

  {----------------------------------------------------------}

  function Archive_Exists(ArcName : PathStr) : Boolean;
  begin
  Archive_Exists := DatabaseExists(ArcName);
  end;

  {----------------------------------------------------------}
  function ArchiveIsOpen        : Boolean;
  begin
  if (Archive[AIX] = nil) or(UBtree.NumDBs = 0) then 
  begin
  ArchiveIsOpen := False;
  Exit;
  end;
  if Archive[AIX]^.IsOpen then
    ArchiveIsOpen := True
  else
    ArchiveIsOpen := False;
  end;

  {----------------------------------------------------------}
  procedure ReformatDate(InDate : Date; var Out : DateString);
  begin
  Out := Long2Str(InDate.Year) + LeftPadCh(Long2Str(InDate.Month), '0', 2) +
         LeftPadCh(Long2Str(InDate.Day), '0', 2);
  if not((Out >= '00000000') and(Out < '20501231')) then
    Out := '';
  end;

  {----------------------------------------------------------}
  procedure ConvertToDescendingIndex;
  var
    RDate                         : LongInt;
    Work                          : DateString;
  begin
  if DateIndex = I_ReverseDate then { Descending index }
    begin
    ReformatDate(LowDate, Work);
    if Str2Long(Work, RDate) then ;
    RDate := MaxLongInt - RDate;
    HighSt := LongToKey(RDate);
    ReformatDate(HighDate, Work);
    if Str2Long(Work, RDate) then ;
    RDate := MaxLongInt - RDate;
    LowSt := LongToKey(RDate);
    end;
  end;

  {----------------------------------------------------------}
  function Archive_SetSearchCriteria(Low, High : Date; Keys : KeyString) : LongInt;
  var 
    First                         : Boolean;
    I, J                          : LongInt;
    RecNo                         : LongInt;
    RDate                         : LongInt;
    TodaysDate                    : DateString;
  begin
  KeysSpecified := 0;
  DateRangeSet := False;
  MatrixSearch := False;
  LowDate := Low;
  HighDate := High;
  ReformatDate(LowDate, LowSt);
  ReformatDate(HighDate, HighSt);

  ReformatDate(CurrentDate, TodaysDate);
  if HighSt > TodaysDate then
    HighDate := CurrentDate;
  ReformatDate(LowDate, LowSt);
  ReformatDate(HighDate, HighSt);
  {was 19800101}
  if ((LowSt = '00000000') and(HighSt = TodaysDate)) then 
  begin
  DateRangeSet := False;
  AMatrix[AIX]^.Reset;
  ConvertToDescendingIndex;
  if Trim(Keys) = '' then
    Exit;
  end
  else 
  begin
  DateRangeSet := True;
  ConvertToDescendingIndex;
  AMatrix[AIX]^.Reset;
  end;

  if DateRangeSet then Inc(KeysSpecified);

  if Trim(Keys) <> '' then 
  begin
  for I := 1 to WordCount(Keys, Delims) do
    KeyWords[I] := StUpCase(ExtractWord(I, Keys, Delims));
  KeywordCount := WordCount(Keys, Delims);
  Inc(KeysSpecified, KeywordCount);
  end;

  First := True;
  FilterMode := False;
  if DateRangeSet then 
  begin
  repeat
    if First then
      Archive[AIX]^.Search(LowSt, DateIndex)
    else
      Archive[AIX]^.Next;
    Archive[AIX]^.LastKey := StUpCase(Trim(Archive[AIX]^.LastKey));
    First := False;
    if (Archive[AIX]^.LastBTstatus = 0) and(Archive[AIX]^.LastKey <= HighSt) then 
    begin
    AMatrix[AIX]^.Add(Archive[AIX]^.RecordPos);
    end;
  until (Archive[AIX]^.LastKey > HighSt) or(Archive[AIX]^.LastBTstatus <> 0);
  end;

  if AMatrix[AIX]^.Found > 0 then
    FilterMode := True;

  if KeywordCount > 0 then 
  begin
  for I := 1 to KeywordCount do 
  begin
  for J := I_FirstKeyword to 10 do 
  begin
  First := True;
  repeat
    if First then
      Archive[AIX]^.Search(StUpCase(KeyWords[I]), J)
    else
      Archive[AIX]^.Next;
    Archive[AIX]^.LastKey := StUpCase(Trim(Archive[AIX]^.LastKey));
    First := False;
    if (Archive[AIX]^.LastBTstatus = 0) and
    (Copy(Archive[AIX]^.LastKey, 1, Length(KeyWords[I])) = KeyWords[I]) then
      AMatrix[AIX]^.Add(Archive[AIX]^.RecordPos);
  until (Archive[AIX]^.LastBTstatus <> 0) or
  (Copy(Archive[AIX]^.LastKey, 1, Length(KeyWords[I])) <> KeyWords[I]);
              {if AMatrix[AIX]^.Found > 0 then
                FilterMode := true;}
  end;
  end;
  end;

  J := 0;
  for I := 1 to AMatrix[AIX]^.Found do 
  begin
  AMatrix[AIX]^.GetElement(I, RecNo, Hits);
  if Hits = KeysSpecified then Inc(J);
  end;

  MatrixSearch := True;
  Archive_SetSearchCriteria := J;
  end;

  {----------------------------------------------------------}
  procedure Archive_ClearSearchCriteria;
  var
    RDate                         : LongInt;
    Work                          : DateString;
  begin
  DateRangeSet := False;
  LowDate := LowestDate;
  HighDate := HighestDate;
  KeywordCount := 0;
  MatrixSearch := False;
  ConvertToDescendingIndex;
  end;

  {----------------------------------------------------------}
  function Archive_Put(Hdr : RunDownRec) : Boolean;
  var 
    D                             : Pointer;
    T                             : Pointer;
    TextFile                      : PathStr;
    TF                            : file;
    TextLen                       : Word;
    TextL                         : LongInt;
    WorkS                         : String[10];
  begin
  if not Archive[AIX]^.IsOpen then Exit;
  with Hdr do 
  begin
  TextLen := 0;
  Hdr.NextUpdate := 0;
  if DOSScriptFile > 0 then 
  begin
  Str(DOSScriptFile, TextFile);
  TextFile := 'Q' + TextFile;
    {$I-}
  Assign(TF, TextFile);
  Reset(TF, 1);
  D := nil;
  TextLen := FileSize(TF);
  Hdr.NextUpdate := TextLen;      { Put text size into header        }
  GetMem(D, SizeOf(Hdr) + TextLen); { get a big buffer for header+text }
  if D = nil then 
  begin
  Archive_Put := False;
  Exit;
  end;
  if TextLen > 0 then 
  begin
  T := Ptr(Seg(D^), Ofs(D^) + SizeOf(Hdr)); { Read text into buffer beyond header }
  BlockRead(TF, T^, TextLen);
  end;
  Close(TF);
    {$I-}
  Hdr.DOSScriptFile := TextLen;   { So we will know length of variable portion }
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Move(WorkS[1], Hdr.PastUpdate, 4);
  Move(Zero, Hdr, 4);
  Hdr.PastLink := 0;
  Hdr.NextLink := 0;
  Move(Hdr, D^, SizeOf(Hdr));
  Archive[AIX]^.AddRecord(D^, TextLen + SizeOf(Hdr));
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  Archive[AIX]^.AddIndex(1, WorkS);
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Archive[AIX]^.AddIndex(2, WorkS);
  Archive[AIX]^.UnlockFile;
  FreeMem(D, SizeOf(Hdr) + TextLen);
  end
  else 
  begin
  Hdr.DOSScriptFile := TextLen;   { So we will know length of variable portion }
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Move(WorkS[1], Hdr.PastUpdate, 4);
  Move(Zero, Hdr, 4);
  Hdr.PastLink := 0;
  Hdr.NextLink := 0;
  Archive[AIX]^.AddRecord(Hdr, SizeOf(Hdr));
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  Archive[AIX]^.AddIndex(1, WorkS);
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Archive[AIX]^.AddIndex(2, WorkS);

  if I_TapeNumber <> 0 then 
  begin
  if Hdr.TapeNum <> '' then
    Archive[AIX]^.AddIndex(I_TapeNumber, Hdr.TapeNum);
  end;

  Archive[AIX]^.UnlockFile;
  end;
  end;
  Archive_Put := True;
  end;

  {----------------------------------------------------------}
  procedure Archive_PutKeywords(OldKeys, NewKeys : KeyString);
  var 
    I                             : Integer;
    WC                            : Integer;
  begin
  if OldKeys <> '' then           { Delete old keyword indexes }
    begin
    for I := 1 to WordCount(OldKeys, Delims) do 
    begin
    Archive[AIX]^.DeleteIndex(I + (I_FirstKeyword - 1), StUpCase(Trim(ExtractWord(I, OldKeys, Delims))));
    end;
    end;
  if NewKeys = '' then Exit;
  WC := WordCount(NewKeys, Delims);
  if WC > 8 then
    WC := 8;
  if not Archive[AIX]^.LockFile then Exit;
  for I := 1 to WordCount(NewKeys, Delims) do 
  begin
  Archive[AIX]^.AddIndex(I + (I_FirstKeyword - 1), StUpCase(Trim(ExtractWord(I, NewKeys, Delims))));
  end;
  Archive[AIX]^.UnlockFile;
  end;

  {----------------------------------------------------------}
  function Archive_PutBuffer(Hdr : RunDownRec; var Buf; TextLen : Word) : Boolean;
  var 
    D                             : Pointer;
    T                             : Pointer;
    TextL                         : LongInt;
    WorkS                         : String[10];
  begin
  if not Archive[AIX]^.IsOpen then Exit;
  with Hdr do 
  begin
  Hdr.NextUpdate := 0;
  if DOSScriptFile > 0 then 
  begin
  Hdr.NextUpdate := TextLen;      { Put text size into header        }
  GetMem(D, SizeOf(Hdr) + TextLen); { get a big buffer for header+text }
  if D = nil then 
  begin
  Archive_PutBuffer := False;
  Exit;
  end;
  if TextLen > 0 then 
  begin
  T := Ptr(Seg(D^), Ofs(D^) + SizeOf(Hdr)); { Read text into buffer beyond header }
  Move(Buf, T^, TextLen);
  end;
  Hdr.DOSScriptFile := TextLen;   { So we will know length of variable portion }
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Move(WorkS[1], Hdr.PastUpdate, 4);
  Move(Zero, Hdr, 4);
  Hdr.PastLink := 0;
  Hdr.NextLink := 0;
  Move(Hdr, D^, SizeOf(Hdr));
  Archive[AIX]^.AddRecord(D^, TextLen + SizeOf(Hdr));
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  Archive[AIX]^.AddIndex(1, WorkS);
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Archive[AIX]^.AddIndex(2, WorkS);
  if I_TapeNumber <> 0 then 
  begin
  if Hdr.TapeNum <> '' then
    Archive[AIX]^.AddIndex(I_TapeNumber, Hdr.TapeNum);
  end;

  Archive[AIX]^.UnlockFile;
  FreeMem(D, SizeOf(Hdr) + TextLen);
  end
  else 
  begin
  Hdr.DOSScriptFile := TextLen;   { So we will know length of variable portion }
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Move(WorkS[1], Hdr.PastUpdate, 4);
  Move(Zero, Hdr, 4);
  Hdr.PastLink := 0;
  Hdr.NextLink := 0;
  Archive[AIX]^.AddRecord(Hdr, SizeOf(Hdr));
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  Archive[AIX]^.AddIndex(1, WorkS);
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Archive[AIX]^.AddIndex(2, WorkS);
  if I_TapeNumber <> 0 then 
  begin
  if Hdr.TapeNum <> '' then
    Archive[AIX]^.AddIndex(I_TapeNumber, Hdr.TapeNum);
  end;

  Archive[AIX]^.UnlockFile;
  end;
  end;
  Archive_PutBuffer := True;
  end;

  {----------------------------------------------------------}
  function Archive_Update(Hdr : RunDownRec) : Boolean;
  var 
    D                             : Pointer;
    T                             : Pointer;
    TextLen                       : Word;
    TextFile                      : PathStr;
    TF                            : file;
    TextL                         : LongInt;
    RecNum                        : LongInt;
    I                             : Integer;
  begin
  if not Archive[AIX]^.IsOpen then Exit;
  Move(Hdr.PastLink, RecNum, 4);
  Archive[AIX]^.Seek(RecNum);
  TextLen := Archive[AIX]^.GetSize;
  with Hdr do 
  begin
  GetMem(D, TextLen);             { get a big buffer for header+text }
  if D = nil then 
  begin
  Archive_Update := False;
  Exit;
  end;
  Archive[AIX]^.GetLocked(TextLen, D^);
  Move(Zero, Hdr, 4);
  Hdr.PastLink := 0;
  Hdr.NextLink := 0;
  Move(Hdr, D^, SizeOf(Hdr) - 4); { Filer uses last 4 bytes }
  Archive[AIX]^.LastReadLen := TextLen;
  Archive[AIX]^.Update(D^, TextLen);
  Archive[AIX]^.UnLockRecord;
  end;
  FreeMem(D, TextLen);
  Archive_Update := True;
  end;

  {----------------------------------------------------------}
  function Archive_Delete(Hdr : RunDownRec; Keys : KeyString) : Boolean;
  var 
    RecNum                        : LongInt;
    RDate                         : LongInt;
    I                             : Integer;
  begin
  Move(Hdr.PastLink, RecNum, 4);
  Archive[AIX]^.Seek(RecNum);
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  Archive[AIX]^.DeleteIndex(1, WorkS);
  if Str2Long(WorkS, RDate) then ;
  RDate := MaxLongInt - RDate;
  WorkS := LongToKey(RDate);
  Archive[AIX]^.DeleteIndex(2, WorkS);
  if I_TapeNumber <> 0 then 
  begin
  Archive[AIX]^.DeleteIndex(I_TapeNumber, Hdr.TapeNum);
  end;
  for I := 1 to WordCount(Keys, Delims) do 
  begin
  Archive[AIX]^.DeleteIndex(I + (I_FirstKeyword - 1), ExtractWord(I, Keys, Delims));
  end;
  Archive[AIX]^.DeleteRecord;
  Archive[AIX]^.UnlockFile;
  end;

  {----------------------------------------------------------}
  function Archive_Get(K                             : Integer;
                       Key                           : SType;
                       var Hdr                       : RunDownRec) : Boolean;
  begin
  Archive[AIX]^.Search(Key, K);
  if Archive[AIX]^.LastBTstatus = 0 then
    Archive[AIX]^.GetReadOnly(SizeOf(Hdr), Hdr);
  if (Archive[AIX]^.LastBTstatus = 0) then { N.B. We get only FIXED portion }
    Archive_Get := True
  else
    Archive_Get := False;
  end;

  {----------------------------------------------------------}
  function Archive_GetText(Hdr : RunDownRec; var Tex) : Boolean;
  var 
    Tsize                         : Word;
    Tptr                          : Pointer;
    RecNum                        : LongInt;
  begin
  Move(Hdr.PastLink, RecNum, 4);
  Archive[AIX]^.Seek(RecNum);
  Tsize := Archive[AIX]^.GetSize;
  GetMem(Tptr, Tsize);
  if Tptr = nil then Exit;
  if Tsize - SizeOf(Hdr) > 0 then
    Archive[AIX]^.GetReadOnly(Tsize, Tptr^);
  Move(Ptr(Seg(Tptr^), Ofs(Tptr^) + SizeOf(Hdr))^, Tex, Tsize - SizeOf(Hdr));
  FreeMem(Tptr, Tsize);
  if Archive[AIX]^.LastBTstatus = 0 then
    Archive_GetText := True
  else
    Archive_GetText := False;
  end;

  {----------------------------------------------------------}
  function Archive_GetFirst(var Hdr : RunDownRec) : Boolean;
  var 
    RecNum                        : LongInt;
  begin
  if not MatrixSearch then
    Archive[AIX]^.Search(LowSt, DateIndex)
  else 
  begin
  CurElement := 0;
  repeat
    Inc(CurElement);
    AMatrix[AIX]^.GetElement(CurElement, RecNum, Hits);
  until (Hits = KeysSpecified) or(CurElement > AMatrix[AIX]^.Found);
  Archive[AIX]^.Seek(RecNum);
  Archive[AIX]^.Status := True;
  end;

  if Archive[AIX]^.LastBTstatus = 0 then 
  begin
  Archive[AIX]^.GetReadOnly(SizeOf(Hdr), Hdr);
  RecNum := Archive_Where;
  Move(RecNum, Hdr.PastLink, 4);
  Archive_GetFirst := True;
  end
  else
    Archive_GetFirst := False;
  end;

  {----------------------------------------------------------}
  function Archive_GetNext(var Hdr : RunDownRec) : Boolean;
  var 
    RecNum                        : LongInt;
  begin
  if not MatrixSearch then 
  begin
  Archive[AIX]^.Next;
  Archive[AIX]^.LastKey := StUpCase(Trim(Archive[AIX]^.LastKey));
  end
  else 
  begin
  if CurElement > AMatrix[AIX]^.Found then 
  begin
  Archive_GetNext := False;
  Exit;
  end;
  repeat
    Inc(CurElement);
    AMatrix[AIX]^.GetElement(CurElement, RecNum, Hits);
  until (Hits = KeysSpecified) or(CurElement > AMatrix[AIX]^.Found);
  Archive[AIX]^.Seek(RecNum);
  Archive[AIX]^.Status := True;
  if (CurElement > AMatrix[AIX]^.Found) or(Hits <> KeysSpecified) then 
  begin
  Archive_GetNext := False;
  Exit;
  end;
  end;

  if Archive[AIX]^.LastBTstatus = 0 then 
  begin
  Archive[AIX]^.GetReadOnly(SizeOf(Hdr), Hdr);
  RecNum := Archive_Where;
  Move(RecNum, Hdr.PastLink, 4);
  end;
  if DateRangeSet then 
  begin
  if Compare2Dates(Hdr.LastEditUpdateDate, HighDate) = Greater_Than then 
  begin
  Archive_GetNext := False;
  Exit;
  end;
  end;
  if Archive[AIX]^.LastBTstatus = 0 then 
  begin
  Archive_GetNext := True;
  end
  else
    Archive_GetNext := False;
  end;

  {----------------------------------------------------------}
  function Archive_Where        : LongInt;
  begin
  Archive_Where := Archive[AIX]^.RecordPos;
  end;

  {----------------------------------------------------------}
  { Creates & opens new archive file }
  function Archive_Create(ArcName : PathStr) : Boolean;
  var 
    H                             : Word;
    Len                           : Word;
  begin
  { Create New Archive header file }
  Inc(AIX);
  AutoAllocate := True;
  ReserveHeapSpace(MemAvail - 30000); { Only give Btree 20K }
  Filer.DatExtension := 'ARH';
  New(Archive[AIX], Init);
  with Archive[AIX]^ do 
  begin
  Len := SizeOf(RunDownRec);
  DefineKey(1, 8, AllowDuplicates); { 8 byte date YYYYMMDD }
  DefineKey(2, 4, AllowDuplicates); { 4 byte longint date MaxLongInt-date }
  DefineKey(3, 15, AllowDuplicates); { Keywords           }
  DefineKey(4, 15, AllowDuplicates); { Keywords           }
  DefineKey(5, 15, AllowDuplicates); { Keywords           }
  DefineKey(6, 15, AllowDuplicates); { Keywords           }
  DefineKey(7, 15, AllowDuplicates); { Keywords           }
  DefineKey(8, 15, AllowDuplicates); { Keywords           }
  DefineKey(9, 15, AllowDuplicates); { Keywords           }
  DefineKey(10, 15, AllowDuplicates); { Keywords           }
  Create(ArcName, Len, 10, VariableRecs);
  if LastBTstatus <> 0 then 
  begin
  Beep(OLDBEEP);
  Archive_Create := False;
  Exit;
  end
  else
    Archive_Create := True;
  Close;
  end;
  Dispose(Archive[AIX], Done);
  Archive[AIX] := nil;
  Filer.DatExtension := 'DBF';
  end;

{$F+}
  {--------------------------------------------------------------------}
  function BuildaKey(var DatS; KeyNr : Integer) : IsamKeyStr;
  var 
    Drec                          : RunDownRec absolute DatS;
    Keys                          : IsamKeyStr;
    KeyS2                         : IsamKeyStr;
    WorkS                         : String[10];
    TextL                         : LongInt;
    I                             : Integer;
  begin
  case KeyNr of
    1 : 
    begin
        ReformatDate(Drec.LastEditUpdateDate, Keys);
        BuildaKey := Keys;
        end;
    2 : 
    begin
        ReformatDate(Drec.LastEditUpdateDate, WorkS);
        if WorkS = '' then 
        begin
        BuildaKey := '';
        Exit;
        end;
        if Str2Long(WorkS, TextL) then ;
        TextL := MaxLongInt - TextL;
        Move(WorkS[1], Hdr.PastUpdate, 4);
        Keys := WorkS;
        BuildaKey := LongToKey(TextL);
        end;
    else
      {3..10 :} begin
      if WordCount(Drec.KeyWords, Delims) >= KeyNr - (I_FirstKeyword - 1) then 
      begin
      Keys := StUpCase(Trim(ExtractWord(KeyNr - (I_FirstKeyword - 1), Drec.KeyWords, Delims)));
      KeyS2 := '';
      for I := 1 to Length(Keys) do
        if Keys[I]in['A'..'Z', '0'..'9', 'a'..'z'] then
          KeyS2 := KeyS2 + Upcase(Keys[I]);
      BuildaKey := Copy(KeyS2, 1, 15);
      end
      else 
      begin
      Keys := '';
      BuildaKey := Keys;
      end;
      end;
  end;
  WriteCentred(2, Pad(SysMsg(001188) {'Index '} + Pad(Long2Str(KeyNr), 2) + ' ' + Pad(Keys, 20), 34));
  end;

{$F+}
  {--------------------------------------------------------------------}
  function ConvertRec(var DatSold; var DatSnew; var Len : Word) : Boolean;
  var 
    Hdr                           : RunDownRec absolute DatSold;
    WorkS                         : String[10];
    TextL                         : LongInt;
  begin
  ReformatDate(Hdr.LastEditUpdateDate, WorkS);
  if WorkS = '' then 
  begin
  ConvertRec := False;
  Exit;
  end;
  if Str2Long(WorkS, TextL) then ;
  TextL := MaxLongInt - TextL;
  WorkS := LongToKey(TextL);
  Move(WorkS[1], Hdr.PastUpdate, 4);
  if Hdr.KeyWords = '' then
    Hdr.KeyWords := Hdr.Slug;
  Move(DatSold, DatSnew, Len);
  TextAttr := Attr(Yellow, Black);
  WriteCentred(2, Pad(SysMsg(000854) {'Adding   '} + Pad(Hdr.Slug, 20), 34));
  ConvertRec := True;
  end;

  {----------------------------------------------------------}
  procedure Archive_Rebuild(ArcName : PathStr);
  var 
    Size                          : LongInt;
  begin
    {$IFDEF DbRebuild}
    Filer.DatExtension := 'ARH';
    OpenMessage(SysMsg(000858){'Rebuilding..Please Wait'},Yellow_Scheme);
    With Archive[AIX]^ DO BEGIN
      DefineKey(1,8,AllowDuplicates);     { 8 byte date YYYYMMDD }
      DefineKey(2,4,AllowDuplicates);     { 4 byte longint date MaxLongInt-date }
      DefineKey(3,15,AllowDuplicates);    { Keywords           }
      DefineKey(4,15,AllowDuplicates);    { Keywords           }
      DefineKey(5,15,AllowDuplicates);    { Keywords           }
      DefineKey(6,15,AllowDuplicates);    { Keywords           }
      DefineKey(7,15,AllowDuplicates);    { Keywords           }
      DefineKey(8,15,AllowDuplicates);    { Keywords           }
      DefineKey(9,15,AllowDuplicates);    { Keywords           }
      DefineKey(10,15,AllowDuplicates);   { Keywords           }
    end;
    IID := Archive[AIX]^.IID;
{    Move(Archive[AIX]^.IID,IID,SizeOf(IsamIndDescr));}
    if not Archive[AIX]^.IsOpen then
        Dialog(SysMsg(001189){'File not Open!'},
               SysMsg(000256){'ARCHIVE'},Red,'OK','','');
    AutoAllocate := False;
    Size := SizeOf(RundownRec);
    Filer.DatExtension := 'ARH';
    Case Dialog('Rebuild Type','Q-REBUILD',Green,'ReIndex','Rebuild','') of
    1 : begin
        AutoAllocate := False;
        Archive[AIX]^.Close;
        ReIndexVFileBlock(ArcName,
                          Size,
                          10,
                          IID,
                          @BuildaKey);
        if IsamError <> 0 then
        end;
    2 : begin
        AutoAllocate := False;
        Archive[AIX]^.Close;
        ReorgVFileBlock(ArcName,
                        Size,
                        10,
                        IID,
                        Size,
                        0,
                        @BuildaKey,
                        @ConvertRec);
        end;
    end;

    CloseMessage;
    Filer.DatExtension := 'DBF';
    {$ENDIF}
  end;

  procedure LoadArchiveINI;
  begin
  if not OpenINIFile( {NEN^.SysDir +} 'NEN.INI') then Exit;
  I_Date := FindKeyValueSection('DATE', 'INDEX', 'ARCHIVE', 1);
  I_ReverseDate := FindKeyValueSection('REVERSE', 'INDEX', 'ARCHIVE', 2);
  I_TapeNumber := FindKeyValueSection('TAPE', 'INDEX', 'ARCHIVE', 0);
  I_FirstKeyword := FindKeyValueSection('FIRST', 'KEYWORD', 'ARCHIVE', 3);
  CloseIniFIle;
  end;

begin
LoadArchiveINI;
DateRangeSet := False;
LowDate.Year := 1967;
LowDate.Month := 01;
LowDate.Day := 01;
HighDate.Year := 9999;
HighDate.Month := 12;
HighDate.Day := 31;
KeywordCount := 0;
ReformatDate(LowDate, HighSt);    { Backwards because of index 2 }
ReformatDate(HighDate, LowSt);
for AIX := 1 to Max_Archives do
  Archive[AIX] := nil;
AIX := 0;
end.

