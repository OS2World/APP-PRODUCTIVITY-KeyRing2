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
{$A-,R-,S-,V-,F+}
{$IFNDEF Windows}
{$O+,X+}
{$ENDIF}
{-----------------------------------------------------------------}
{                                                                 }
{ UDirec (C) 1989 NewsMaker System.                               }
{ Object oriented routines to build and process a Dos directory   }
{ in heap memory. Use Rebuild if disk data has changed            }
{ Declare a variable of type DOSDIR, then control it using        }
{ "dotting" methods e.g.                                          }
{                                                                 }
{       Const Normal : boolean = False;                           }
{             Wide   : boolean = True;                            }
{       Var   Dir    : DosDir;                                    }
{       begin                                                     }
{         Dir.Init('\MyData\*.Dat','N','-');                      }
{         Dir.Print(Normal);                                      }
{         Dir.Close;                                              }
{       end;                                                      }
{                                                                 }
{ Routines are:  Init(Path,SortBy,Direction); Name,Time,Size +-   }
{                Print(Format);   Normal or Wide                  }
{                Rebuild;         New snapshot of directory       }
{                Found := GetNextFileName(Name);                  }
{                Found := GetNextEntry(DirEntry)  See DirRec      }
{                Close;           ** Must be called when Done     }
{                                    to Dealloc Heap space        }
{                                                                 }
{-----------------------------------------------------------------}

Unit UDirec;

interface

{$IFNDEF Windows}
uses Dos,OpString,OpDate;
{$ELSE}
uses WinDos, WinSys, OpString, Strings, UMsg;
{$ENDIF}

const
  MaxDirSize = 1000;
  MonthStr: array[1..12] of string[3] = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
type
  DirPtr   = ^DirRec;
  NameStr  = String[12];
  PathStr  = String[79];
  DStr     = String[80];
  DirRec   = record
               Attr: Byte;
               Time: Longint;
               Size: Longint;
               Name: NameStr;
             end;
  DirList  = array[0..MaxDirSize - 1] of DirPtr;
  DirListPtr = ^DirList;
  CompareFunc = function(X, Y: DirPtr): Boolean;
  WriteLineFunc = procedure(DString: PathStr);

  {>>>>>>>> Object DOSDIR - A Dos Directory <<<<<<<<}
  PDosDir = ^DosDir;
  DosDir = Object
    WideDir: Boolean;     { Switch if Print in Wide format }
    Count  : Integer;     { total dir entries found }
    Next   : integer;     { next entry to retrieve }
    Compare: CompareFunc; { pointer to specified compare function }
    {$IFNDEF Windows}
    FPath  : PathStr;     { path of directory }
    {$ELSE}
    FPath  : Array[0..79] of char;
    {$ENDIF}
    Dir    : DirListPtr;  { pointers to directory entries }
    Empty  : boolean;     { True if no entries found or left }
    SortBy : Char;        { N=Name, T=Time, S=Size }
    UpDown : Char;        { Sort Direction + or - }

           {Init - Sets up object variables }
    Constructor Init(SearchPath: PathStr;Op: Char;Direction: Char);

           {Find - Builds directory as specified by Init }
    procedure Find;

           {Sort - Sorts directory as specified by Init }
    procedure Sort;

           {GetNextFileName - Gets next File Name from list }
    function GetNextFileName(var Name: NameStr): boolean; { False if none left}

           {GetNextPathName - Gets next full Path Name from list }
    function GetNextPathName(var Name: PathStr): boolean; { False if none left}

           {GetNextEntry - Gets next whole entry from list }
    function GetNextEntry(var F: DirRec): boolean;

           {Rebuild - Builds a new directory based on original specification }
    procedure Rebuild;

           { SearchFileName - Scans list for filename & returns entry }
    function SearchFileName(Name: NameStr;var F: DirRec): boolean;

           {Close - Frees all memory allocated by Find ** Always Call ** }
    Destructor Close;

           {Print - Does a Dos-Like print of directory }
    {$IFNDEF Windows}
    procedure Print(Wide: boolean);

           {List - Prints individual entries via procedure variable }
    procedure List;
    {$ENDIF}

           {FileCount - Returns total files found }
    function FileCount: word;

    end;   { of DosDir }

var
  WriteLine : WriteLineFunc;

function NumStr(N, D: Integer): String;

implementation

{$IFNDEF Windows}
Const
faDirectory = Directory;
faReadOnly  = ReadOnly;
faArchive   = Archive;
{$ELSE}
Type
Searchrec = TSearchRec;
{$ENDIF}

{>>>>>> General Non-method procedures & functions }

{-------------------------------------------------------------}
function NumStr(N, D: Integer): String;
begin
  NumStr[0] := Chr(D);
  while D > 0 do
  begin
    NumStr[D] := Chr(N mod 10 + Ord('0'));
    N := N div 10;
    Dec(D);
  end;
end;

{-------------------------------------------------------------}
function LessName(X, Y: DirPtr): Boolean;
begin
  LessName := X^.Name < Y^.Name;
end;

{-------------------------------------------------------------}
function LessSize(X, Y: DirPtr): Boolean;
begin
  LessSize := X^.Size < Y^.Size;
end;

{-------------------------------------------------------------}
function LessTime(X, Y: DirPtr): Boolean;
begin
  LessTime := X^.Time > Y^.Time;
end;

{-------------------------------------------------------------}
function LessTimeAndName(X, Y: DirPtr): Boolean;
begin
  LessTimeAndName := (Long2Str(X^.Time)+X^.Name > Long2Str(Y^.Time)+Y^.Name);
end;

{-------------------------------------------------------------}
function MoreName(X, Y: DirPtr): Boolean;
begin
  MoreName := X^.Name > Y^.Name;
end;

{-------------------------------------------------------------}
function MoreSize(X, Y: DirPtr): Boolean;
begin
  MoreSize := X^.Size > Y^.Size;
end;

{-------------------------------------------------------------}
function MoreTime(X, Y: DirPtr): Boolean;
begin
  MoreTime := X^.Time < Y^.Time;
end;

{-------------------------------------------------------------}
function MoreTimeAndName(X, Y: DirPtr): Boolean;
begin
  MoreTimeAndName := (Long2Str(X^.Time)+X^.Name < Long2Str(Y^.Time)+Y^.Name);
end;

{>>>>>> DosDir METHODS <<<<<<< }
{-------------------------------------------------------------}
Constructor DosDir.Init(SearchPath: PathStr;Op: Char;Direction: Char);
var
  I,J: Integer;
  Attr: Word;
  F: File;
  S: PathStr;
  {$IFNDEF WIndows}
  D: DirStr;
  N: NameStr;
  E: ExtStr;
  {$ELSE}
  WS: Array[0..79] of char;
  D,N,E: Array[0..50] of char;
  {$ENDIF}
begin
  WideDir := False;
  @Compare := nil;
  {$IFNDEF Windows}
  FPath := '';
  {$ELSE}
  StrPCopy(WS, SearchPath);
  FPath[0]  := #0;
  {$ENDIF}
  New(Dir);
  if Dir = nil then exit;
  for I := 0 to MaxDirSize-1 do
    Dir^[I] := nil;
  SortBy := Op;
  UpDown := Direction;
  if Direction = '-' then
    begin
    case Op of
      'N': Compare := MoreName; { assigns address of actual function to Compare }
      'S': Compare := MoreSize;
      'T': Compare := MoreTime;
      'D': Compare := MoreTimeAndName;
      end;
    end
  Else
    begin
    case Op of
      'N': Compare := LessName; { assigns address of actual function to Compare }
      'S': Compare := LessSize;
      'T': Compare := LessTime;
      'D': Compare := LessTimeAndName;
      end;
    end;

  {$IFNDEF Windows}
  FPath := FExpand(SearchPath);
  {$ELSE}
  FileExpand(WS, FPath);
  {$ENDIF}
  if FPath[Length(FPath)] <> '\' then
  begin
    {$I-}
    Assign(F, FPath);
    GetFAttr(F, Attr);
    {$IFNDEF Windows}
    if (DosError = 0) and (Attr and faDirectory <> 0) then
      FPath := FPath + '\';
    {$ELSE}
    if (DosError = 0) and (Attr and faDirectory <> 0) then
      StrCat(FPath,'\');
    {$ENDIF}
    {$I+}
  end;
  {$IFNDEF Windows}
  FSplit(FPath, D, N, E);
  if N = '' then N := '*';
  if E = '' then E := '.*';
  FPath := D + N + E;
  {$ELSE}
  FileSplit(FPath, D, N, E);
  if StrLen(N) = 0 then StrCopy(N,'*');
  if StrLen(E) = 0 then StrCopy(E,'.*');
  StrCopy(FPath, D);
  StrCat(FPath,N);
  StrCat(FPath,E);
  {$ENDIF}
  Find;    { Build Heap Directory }
  Sort;    { Sort it              }
end;

{-------------------------------------------------------------}
function DosDir.FileCount: word;
begin
FileCount := Count;
end;

{-------------------------------------------------------------}
destructor DosDir.Close;
var
  I: integer;
begin
if Count = 0 then exit;
for I := 0 to Count-1 do
  if Dir^[I] <> nil then
    begin
    FreeMem(Dir^[I],Length(Dir^[I]^.Name) + 10);
    Dir^[I] := nil;
    end;
Dispose(Dir);
Dir := nil;
end;

{-------------------------------------------------------------}
procedure DosDir.Find;
var
  F: SearchRec;
  I: integer;
begin
  if Dir = nil then
    begin
      New(Dir);
      for I := 0 to MaxDirSize-1 do
        Dir^[I] := nil;
    end;
  Count := 0;
  FindFirst(FPath, faReadOnly + faDirectory + faArchive, F);
  while (DosError = 0) and (Count < MaxDirSize) do
  begin
    GetMem(Dir^[Count], Length(F.Name) + 10);
    Move(F.Attr, Dir^[Count]^, Length(F.Name) + 10);
    Inc(Count);
    FindNext(F);
  end;
if Count = 0 then
  Empty := true
else
  Empty := false;
if Count > MaxDirSize then
  Count := MaxDirSize;
Next := 0;
end;

{-------------------------------------------------------------}
procedure DosDir.Sort;

  procedure QuickSort(L, R: Integer);
  var
    I, J: Integer;
    X, Y: DirPtr;
  begin
    I := L;
    J := R;
    X := Dir^[(L + R) div 2];
    repeat
      while Compare(Dir^[I], X) do Inc(I);
      while Compare(X, Dir^[J]) do Dec(J);
      if I <= J then
      begin
        Y := Dir^[I];
        Dir^[I] := Dir^[J];
        Dir^[J] := Y;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J);
    if I < R then QuickSort(I, R);
  end;

begin
  if (Count <> 0) and (@Compare <> nil) then   { Compare is pointer to function }
    QuickSort(0, Count - 1);
end;

{-------------------------------------------------------------}
function DosDir.GetNextFileName(var Name: NameStr): boolean;
begin
if (Empty) or (Next >= Count) then
  begin
  GetNextFileName := False;
  exit;
  end;
Name := Dir^[Next]^.Name;
inc(Next);
GetNextFileName := true;
end;

{-------------------------------------------------------------}
function DosDir.GetNextPathName(var Name: PathStr): boolean;
begin
if (Empty) or (Next >= Count) then
  begin
  GetNextPathName := False;
  exit;
  end;
Name := JustPathname(FPath)+'\'+Dir^[Next]^.Name;
inc(Next);
GetNextPathName := true;
end;

{-------------------------------------------------------------}
function DosDir.GetNextEntry(var F: DirRec): boolean;
begin
if (Empty) or (Next >= Count) then
  begin
  GetNextEntry := False;
  exit;
  end;
F := Dir^[Next]^;
inc(Next);
GetNextEntry := True;
end;

{-------------------------------------------------------------}
function DosDir.SearchFileName(Name: NameStr;var F: DirRec): boolean;
var I: integer;
begin
  for I := 0 to Count-1 do
    if Dir^[I]^.Name = Name then
      begin
        F := Dir^[I]^;
        SearchFileName := True;
        exit;
      end;
  SearchFileName := False;
end;

{-------------------------------------------------------------}
Procedure DosDir.Rebuild;
begin
  Close;    { Free any space used  }
  Find;     { Build heap directory }
  Sort;     { & Sort it            }
end;

{$IFNDEF Windows}

procedure DefaultWriteLine(DString: PathStr);
begin
  WriteLn(DString);
end;

{-------------------------------------------------------------}
procedure DosDir.Print(Wide: boolean);
var
  I, P: Integer;
  Total: Longint;
  T: DateTime;
  N: NameStr;
  E: ExtStr;
  DirecLine: PathStr;
begin
  WideDir := Wide;
  WriteLn('Directory of ', FPath);
  if Count = 0 then
  begin
    WriteLn('No matching files');
    Exit;
  end;
  Total := 0;
  for I := 0 to Count-1 do
  with Dir^[I]^ do
  begin
    P := Pos('.', Name);
    if P > 1 then
    begin
      N := Copy(Name, 1, P - 1);
      E := Copy(Name, P + 1, 3);
    end else
    begin
      N := Name;
      E := '';
    end;
    Write(N, ' ': 9 - Length(N), E, ' ': 4 - Length(E));
    if WideDir then
    begin
      if Attr and Directory <> 0 then
        Write(' DIR')
      else
        begin
        Write((Size + 1023) shr 10: 3, 'k');
        end;
      if I and 3 <> 3 then
        Write(' ': 3)
      else
        WriteLn;
    end else
    begin
      if Attr and Directory <> 0 then
        DirecLine :='<DIR>   '
      else
        DirecLine := LeftPad(Long2Str(Size), 8);
      UnpackTime(Time, T);
      DirecLine := DirecLine+
                   ' '+DMYToDateString('dd-nnn-yy',T.Day,T.Month,T.Year mod 100)+
                   ' '+
                   TimeToTimeString('hh:mm',HMSToTime(T.Hour,T.Min,0));
      WriteLine(DirecLine);
{      WriteLn(T.Day: 4, '-',
        MonthStr[T.Month], '-',
        NumStr(T.Year mod 100, 2),
        T.Hour: 4, ':',
        NumStr(T.Min, 2));}
    end;
    Inc(Total, Size);
  end;
  if WideDir and (Count and 3 <> 0) then WriteLn;
  WriteLn(Count, ' files, ', Total, ' bytes, ',
          DiskFree(Ord(FPath[1])-64), ' bytes free');
end;

{-------------------------------------------------------------}
procedure DosDir.List;
var
  I, P: Integer;
  Total: Longint;
  T: DateTime;
  N: NameStr;
  E: ExtStr;
  DirecLine: DStr;
begin
  WriteLine('Directory of '+FPath);
  if Count = 0 then
  begin
    WriteLine('No matching files');
    Exit;
  end;
  Total := 0;
  for I := 0 to Count-1 do
  with Dir^[I]^ do
  begin
    P := Pos('.', Name);
    if P > 1 then
    begin
      N := Copy(Name, 1, P - 1);
      E := Copy(Name, P + 1, 3);
    end else
    begin
      N := Name;
      E := '';
    end;
    if Attr and Directory <> 0 then
      DirecLine := Pad(N,9)+Pad(E,4)+'<DIR>   '
    else
      DirecLine := Pad(N,9)+Pad(E,4)+LeftPad(Long2Str(Size), 8);
    UnpackTime(Time, T);
    DirecLine := DirecLine+
                 ' '+DMYToDateString('dd-nnn-yy',T.Day,T.Month,T.Year mod 100)+
                 ' '+
                 TimeToTimeString('hh:mm',HMSToTime(T.Hour,T.Min,0));
    WriteLine(DirecLine);
    Inc(Total, Size);
  end;
end;
{$ENDIF}

begin
  {$IFNDEF WINDOWS}
  WriteLine := DefaultWriteLine;
  {$ENDIF}
end.
