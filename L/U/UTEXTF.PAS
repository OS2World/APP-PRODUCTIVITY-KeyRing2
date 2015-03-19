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
{$A-,F+,V-,R-,S-,O+}
{.$D-}
{--------------------------------------------------------}
{ C) copyright 1988                                      }
{ UTEXT Unit.                                            }
{ Forms part of the UWINDOW family.                      }
{ Provides a Windows and Menu operating environment      }
{ NEN version.                                           }
{--------------------------------------------------------}

Unit UTEXT;

interface

Uses DOS,OpCrt,Qglobal,Qscreen,Qinput,QUptime,QNovell,QHdrRec,UMsg,UColors,
     ULib,UGlobal,OpWindow,UWindow,UMenu,Umouse,OpEdit,OpString;

Const ForceUpperCase = True;
      AllowLowerCase = False;

Procedure DisplayTextFile(X1,Y1,X2,Y2: word;
                          FileName: PathStr;
                          Title: TitleString;
                          Format: word;
                          ColorScheme: ColorSetProc);
Procedure DisplayHelpText(FileName: PathStr; Search: BigString;FrameColor,TextColor: byte);
Procedure PascalWordReplace(Filename: PathStr;
                            Search: String;
                            Replace: String;
                            ListByFile: boolean;
                            ListOnly: boolean;
                            NoBAK: boolean);
Procedure ResetListFile;

implementation

Const
  LadderBack = #$B0;
  LadderChar = #$B1;
  MaxLines = 32767;

Type
  FileTab = Array[1..100] of LongInt;
  LineMapArray = Array[1..MaxLines] of Word;
  LineMapPtr = ^LineMapArray;

Var
  FirstRec,LastRec: LongInt;   { First & last Records in Text buffer }
  FirstScr,LastScr: LongInt;   { First & last Records on screen      }
  MaxRec,CurRec: LongInt;      { Last record in file, Current Record }
  NumRecs: word;               { Records read in last blockread }
  BufPtr: ^Char;               { Pointer to current char in Text buffer }
  LineMap: LineMapPtr;         { Record # of start of each line }
  EndOfFile : boolean;         { EndOfFile encountered on last read }
  TextBufferSize: word;        { Size of Text buffer }
  FileTable : FileTab;
  FileTablePtr : word;
  TextFile: File;
  TextFileName: PathStr;
  WindowCapacity,WindowPos: word;
  LastX,LastY: word;
  LadderTop,Ladderbottom,Ladderleft,LadderRight,LadderCol,
  LadderUnit,LastLadderY,LastLadderX: word;
  LadderAttr,LadderPosAttr: byte;
  Display: boolean;
  Keywords: word;
  KeywordMode: boolean;
  Keywidth: word;
  KeySwitch: word;
  Keytable: Array[1..50] of LongInt;
  MaxLine: word;               { total lines in file }
  Line : word;
  FirstLine: word;             { First line on screen }
  LastLine: word;              { Last line on screen }
  CurLine: integer;
  StartLine: Word;             { First Line to display }
  LineWidth: word;
  FirstColumn: word;
  LastColumn: word;
  LinesPerWindow: word;
  TextFileOpen: boolean;
  Page: word;
  EditLine : Array[1..80] of Char;
  Psave: Array[1..80] of Char;
  Pattr: Array[1..80] of byte;
  InsertMode : boolean;

Const
  SearchKey: BigString = '';
  ListFileRead : boolean = False ;

{----------------------------------------------------------}
Procedure FillTextBuffer(var FirstRec,LastRec: LongInt; var EndOfFile: boolean);
Begin
EndOfFile := False;
CurRec := FirstRec;
Seek(TextFile,FirstRec);
Fillchar(Menu^,TextBufferSize,' ');
BlockRead(TextFile,Menu^,TextBufferSize,NumRecs);
LastRec := FirstRec+NumRecs;
if Numrecs < TextBufferSize then
  EndOfFile := True;
end;
{----------------------------------------------------------}
Procedure UpdateLadder;
var L: word;
    S: Stype;
begin
end;

{----------------------------------------------------------}
    { This is the main engine for getting characters       }
    { The file has been opened with a record size of 1,    }
    { meaning that each character is a record. Characters  }
    { are thus referenced by their File position. This     }
    { routine determines if the record is in the buffer and}
    { returns it, reading data from the file if necessary. }
Function GetRecord(RecNo: LongInt): Char;
begin
With Menus[ScreenNum]^ do
  begin
  if RecNo > MaxRec then
    begin
    GetRecord := #2; {EOT}
    exit;
    end;
  if (RecNo >= FirstRec) and (RecNo <= LastRec) then
    begin
    BufPtr := Ptr(Seg(Menu^),Ofs(Menu^)+(RecNo-FirstRec));
    GetRecord := BufPtr^;
    end
  else
    begin
    FirstRec := RecNo;
    FillTextBuffer(FirstRec,LastRec,EndOfFile);
    BufPtr := Ptr(Seg(Menu^),Ofs(Menu^));
    GetRecord := BufPtr^;
    end;
  end;
end;
{----------------------------------------------------------}
Procedure PreScanFile;
var M: word;
    Offset: word;
    R: LongInt;
    ch: char;
    S : Stype;
Begin
M := 0;
LineWidth := 0;
Keywords := 0;
Keywidth := 0;
StartLine := 1;
Page := 0;
GetMemCheck(LineMap,SizeOf(LineMapArray));
if LineMap = nil then exit;
Line := 1;
LineMap^[1] := 0;
GotoXY(1,1);
WriteLn(SysMsg(000713){'Scanning File Format'});
if KeywordMode then
  WriteLn(SysMsg(000714){'Keyword mode Selected'});
R := 0;
Repeat
  begin
  Ch := GetRecord(R);
  if KeywordMode then
    begin
    if Ch = '`' then            { keyword check }
      begin
      S := '';
      inc(M);
      Keytable[M] := Line;
      Repeat
        inc(R);
        Ch := GetRecord(R);
        if ch <> '~' then
          S := S+ch;
      until ch in ['~',#$0A,#$0D];
      if S <> '' then
        begin
        Caps(S);
        Menu^[M] := S;
        if SearchKey = S then
          StartLine := Line;
        if length(S) > Keywidth then
          Keywidth := length(S);
        end;
      end;
    end;
  if Ch in [#$0D,#2] then           { Line-end check }
    begin
    inc(Line);
    Offset := 1;
    if GetRecord(R+1) = #$0A then   { Ignore Linefeeds }
      inc(Offset);
    LineMap^[Line] := R+Offset;
    if (R+Offset)-LineMap^[Line-1]-1 > LineWidth then
      LineWidth := (R+Offset)-LineMap^[Line-1]-1;
    end;
  inc(R);
  end;
  Until R >= MaxRec;
MaxLine := Line;
WriteLn(MaxLine,SysMsg(000715){' Lines found'});
Line := 1;
Keywords := M;
WriteLn(M,SysMsg(000716){' Keywords found'});
end;
{----------------------------------------------------------}
Function FindLine(Rec: LongInt): word;
var I,R: word;
begin
R := Rec;
For I := 1 to MaxLines do
  begin
  if R < LineMap^[I] then
    begin
    FindLine := I-1;
    exit;
    end;
  end;
end;
{----------------------------------------------------------}
Procedure DisplayLine(Y: word;LineNum: word);
var Crec: LongInt;
    I: integer;
    Ch: char;
    X: word;
    LastByte: word;
    Skip: boolean;
Begin
if LineNum > MaxLine then exit;
Crec := LineMap^[LineNum];
X := 1;
GotoXY(X,Y);
LastByte := LastColumn;
For I := 1 to LineWidth do
  begin
  Skip := false;
  Ch := GetRecord(Crec);
  inc(Crec);
  Case Ch of
   #$0A,#$0D,#2 :  begin
                   SetWindowColors;
                   exit;
                   end;
   '`'          :  begin
                   if KeywordMode then
                     begin
                     Skip := true;
                     end;
                   end;
   '~'          :  begin
                   if KeywordMode then
                     begin
                     SetWindowColors;
                     Skip := true;
                     end;
                   end;
   #$1A         :  Skip := true;
   end;
  if I >= FirstColumn then
    begin
    With Menus[ScreenNum]^ do
      begin
      if X > LastX then exit;
      if not Skip then
        begin
        WriteChr(wFrame.frXl+X-1,wFrame.frYl+Y-1,Ch,TextAttr);
        inc(X);
        end
      else
        inc(LastByte);
      end;
    if I > LineWidth then exit;
    end;
  end;
end;
{----------------------------------------------------------}
Procedure FillWindow(var EndOfFile: boolean);
var
  Ch: char;
  I: integer;
Begin
SetWindowColors;
ClrScr;
SetWindowColors;
WindowPos := 1;
FirstScr := CurRec;
FirstLine := CurLine;
For I := 1 to LastY do
  begin
  DisplayLine(I,CurLine);
  inc(CurLine);
  end;
LastLine := CurLine;
UpdateLadder;
end;
{----------------------------------------------------------}
Procedure FormatWindow;
var I: integer;
begin
With Menus[ScreenNum]^ do
  begin
  end;
end;
{----------------------------------------------------------}
Procedure DisplayTextFile(X1,Y1,X2,Y2: word;
                          FileName: PathStr;
                          Title: TitleString;
                          Format: word;
                          ColorScheme: ColorSetProc);
var
  Quit: boolean;
  Ch,Ch2: char;
  Fkey: boolean;
  M,I: integer;
  Begin
  TextFileName := FileName;
  KeywordMode := False;
  I := Pos('.',FileName);
  if I <> 0 then
    begin
    S := Copy(FileName,I,Length(FileName)-(I-1));
    Caps(S);
    if (S = '.HLP') or (S = '.DOC') then
      KeywordMode := true;
    end;
  Assign(TextFile,FileName);
  {$I-}
  Reset(TextFile,1);
  if IoResult <> 0 then
    begin
    if Dialog(SysMsg(000717){'Cannot find '}+TextFileName,SysMsg(000718){' Menu Help '},Red,'OK','') = 0 then
      begin
      end;
    exit;
    end;
  {$I-}
  MaxRec := FileSize(TextFile);
  TextFileOpen := True;
  HiddenCursor;
  UData^.BorderOn := True;
  SetBorderType(DoubleLine);
  SavePrompt;
  Prompt(SysMsg(000719){'View: PgUp PgDn '}+
         #24+#25+#26+#27+'^'+#26+'^'+#27+
         SysMsg(000720){' HOME,END. F1-Index, F4-Zoom'});
  OpenWindow(X1,Y1,X2,Y2,Title,ColorScheme);
  Menus[ScreenNum]^.Quadrant := 1;
  KeySwitch := 0;
  SetWindowColors;
  With Menus[ScreenNum]^ do
    begin
    TextBufferSize := 16384;
    GetMemCheck(Menu,TextBufferSize);
    if menu = nil then
      begin
      beep;
      CloseWindow;
      RestorePrompt;
      exit;
      end;
    FirstRec := 0;
    FileTablePtr := 1;
    FillChar(FileTable,SizeOf(FileTable),#0);
    Display := True;
    CurRec := 0;
    CurLine := 1;
    FillTextBuffer(FirstRec,LastRec,EndOfFile);
    PreScanFile;
    if LineMap = nil then
      begin
      beep;
      CloseWindow;
      RestorePrompt;
      exit;
      end;
    if MaxRec <= TextBufferSize then
      begin
      Close(TextFile);
      TextFileOpen := false;
      end;
    FormatWindow;
    CurLine := StartLine;
    FillWindow(EndOfFile);
    Quit := False;
    While not Quit do
      begin
      While not Check4Chars do    { Wait for a key to be pressed }
        UpdateTime(False);
      Fkey := False;
      GetNextChar(Ch,Ch2);
      if Ch = #0 then
        begin
        Fkey := true;
        Ch := Ch2;
        end;
      Case Ch of
        Esc    : Quit := True;
        PgDn   : begin
                 if LastLine < MaxLine then
                   begin
                   CurLine := LastLine;
                   if CurLine > MaxLine then
                     CurLine := MaxLine-LinesPerWindow-1;
                   FillWindow(EndOfFile);
                   end;
                 end;
        PgUp   : begin
                 if FirstLine > 1 then
                   begin
                   CurLine := FirstLine-LinesPerWindow;
                   if CurLine < 1 then
                     CurLine := 1;
                   FillWindow(EndOfFile);
                   end;
                 end;
     CursorDown: begin
                 if LastLine < MaxLine then
                   begin
                   CurLine := FirstLine+1;
                   if CurLine < MaxLine then
                     FillWindow(EndOfFile);
                   end;
                 end;
     CursorUp  : begin
                 if FirstLine > 1 then
                   begin
                   CurLine := FirstLine-1;
                   if CurLine < 1 then
                     CurLine := 1;
                   FillWindow(EndOfFile);
                   end;
                 end;
    CursorRight: begin
                 CurLine := FirstLine;
                 if LastColumn < LineWidth then
                   begin
                   Inc(FirstColumn);
                   Inc(LastColumn);
                   FillWindow(EndOfFile);
                   end;
                 end;
    CursorLeft : begin
                 CurLine := FirstLine;
                 if FirstColumn > 1 then
                   begin
                   Dec(FirstColumn);
                   Dec(LastColumn);
                   FillWindow(EndOfFile);
                   end;
                 end;
     CtrlRight : begin
                 if LastColumn < LineWidth then
                   begin
                   LastColumn := LineWidth;
                   FirstColumn := LastColumn-LastX;
                   CurLine := FirstLine;
                   FillWindow(EndOfFile);
                   end;
                 end;
     CtrlLeft  : begin
                 if FirstColumn > 1 then
                   begin
                   FirstColumn := 1;
                   LastColumn := LastX;
                   CurLine := FirstLine;
                   FillWindow(EndOfFile);
                   end;
                 end;
        Home   : begin
                 CurLine := 1;
                 FirstColumn := 1;
                 LastColumn := LastX;
                 FillWindow(EndOfFile);
                 end;
        EndKey : begin
                 CurLine := MaxLine-LinesPerWindow;
                 FillWindow(EndOfFile);
                 end;
        F1 :    begin
                if Keywords > 0 then
                  begin
                  OpenMenu(WinX+4,WinY+2,WinX+10+(KeyWidth*2),20,UGlobal.Menu^,
                           Keywords,Keywidth,Sort,'',SysMsg(000721){' Index '},White_Scheme,I);
                  M := GetMenu;
                  CloseWindow;
                  if M <> 0 then
                    begin
                    CurLine := KeyTable[M];
                    FillWindow(EndOfFile);
                    end;
                  end;
                end;
        end; { case }
      end; { While not Quit }
    FreeMemCheck(Menu,TextBufferSize);
    Menu := nil;
    FreeMemCheck(LineMap,SizeOf(LineMapArray));
    end;
  if TextFileOpen then
    Close(TextFile);
  CloseWindow;
  RestorePrompt;
  SearchKey := '';
  end;

{-------------------------------------------------------}
Procedure DisplayHelpText(FileName: PathStr; Search: BigString;FrameColor,TextColor: byte);
begin
SearchKey := Search;
end;

{-------------------------------------------------}
  procedure ReplaceWord(N : Byte; var S : string; R : String;
                       WordDelims : CharSet);
    {-Given a set of word delimiters, replace the N'th word in S}
  var
    I, Count, Len : Byte;
    Start: byte;
    EndWord: byte;
    SLen : Byte absolute S;
  begin
    Count := 0;
    I := 1;
    Len := 0;
    while (I <= SLen) and (Count <> N) do begin
      {skip over delimiters}
      while (I <= SLen) and (S[I] in WordDelims) do
        Inc(I);
      {if we're not beyond end of S, we're at the start of a word}
      if I <= SLen then
        Inc(Count);
      Start := I;
      Len := 0;
      {find the end of the current word}
      while (I <= SLen) and not(S[I] in WordDelims) do begin
        {if this is the N'th word, add the I'th character to Tmp}
        if Count = N then begin
        Inc(Len);
        end;
        Inc(I);
      end;
      if Count = N then
        begin
        Delete(S,Start,Len);
        System.Insert(R,S,Start);
        end;
    end;
  end;
{-------------------------------------------------}
{ Pascal oriented Word search/replace             }
{ Searches for & replaces whole words only, not   }
{ substrings e.g. replace OpCrt with OpCrt would    }
{ replace Uses OpCrt, but not SetCRTborder          }
{ Works either from supplied strings, or via an   }
{ external file of changes (ListByFile = True)    }
{ in which case, the filename is in Search.       }
Procedure PascalWordReplace(Filename: PathStr;
                            Search: String;
                            Replace: String;
                            ListByFile: boolean;
                            ListOnly: boolean;
                            NoBAK: boolean);
Type
    SWtype = String[40];
    StPtr = ^Stype;
    Stype = Record
      SearchS : SWtype;
      RepS    : SWtype;
      Next    : StPtr;
      end;
Const
    Delims : Set of Char = [' ',',','.',';','}'];
var Ip     : Text;
    Op     : Text;
    List   : Text;
    F,B    : File;
    Y      : byte;
    Num    : integer;
    IoErr  : integer;
    Line   : ^String;
    CurWord: ^SWtype;
    Words,W: byte;
    Found  : boolean;
    BakFile: PathStr;
    WList  : StPtr;
    WL     : StPtr;
    WN     : StPtr;
    Changed: boolean;
    NumS   : String[6];
  function CheckIo: boolean;
    begin
    IoErr := IoResult;
    if IoErr <> 0 then
      begin
      CheckIo := false;
      end
    else
      CheckIo := true;
    end;
   procedure CheckWord;
     begin
      if not ListByFile then
        begin
        if Search = StUpcase(ExtractWord(W,Line^,Delims)) then
          begin
          ReplaceWord(W,Line^,Replace,Delims);
          Found := true;
          Changed := True;
          end;
        end
      else
        begin
        WL := WList;
        Repeat
          begin
          if WL^.SearchS = StUpcase(ExtractWord(W,Line^,Delims)) then
            begin
            ReplaceWord(W,Line^,WL^.RepS,Delims);
            Found := true;
            Changed := True;
            end;
          WL := WL^.Next;
          end;
          Until WL = Nil;
        end;
      end;
begin
{$I-}
if not ListFileRead then
  WList := nil;
Found := False;
HighVideo;
WriteLn(FileName);
Y := WhereY-1;
Num := 0;
NormVideo;
Assign(Ip,FileName);
Reset(Ip);
if not CheckIO then exit;
if not ListOnly then
  begin
  Assign(Op,'SR$$$.PAS');
  Rewrite(Op);
  if not CheckIO then exit;
  end;
GetMemCheck(Line,255);
GetMemCheck(CurWord,255);
if ListByFile then    { if using list file, Search string contains Filename }
  begin
  if not ListFileRead then
    begin
    Assign(List,Search);
    Reset(List);
    While not EOF(List) do
      begin
      ReadLn(List,Line^);
      if WList = nil then
        begin
        GetMemCheck(WList,SizeOf(Stype));
        WN := Wlist;
        WN^.Next := nil;
        WL := WN;
        end
      else
        begin
        GetMemCheck(WN,SizeOf(Stype));
        WL^.Next := WN;
        WL := WN;
        end;
      WL^.Next := nil;
      WL^.SearchS := ExtractWord(1,Line^,[' ']);
      WL^.RepS    := ExtractWord(2,Line^,[' ',#$0A,#$0D]);
      WL^.SearchS := StUpCase(WL^.SearchS);
      end;
    ListFileRead := true;
    Close(List);
    end;
  end;
Search := StUpcase(Search);
While not EOF(Ip) do
  begin
  ReadLn(Ip,Line^);
  inc(Num);
  if Line^ <> '' then
    begin
    Words := WordCount(Line^,Delims);
    if Words > 0 then
      begin
      Changed := False;
      for W := 1 to Words do
        begin
        CheckWord;
        end;
      if Changed then
        WriteLn(Line^);
      end;
    end;
  if not ListOnly then
    WriteLn(Op,Line^);
  end; { while }
Close(Ip);
if not ListOnly then
  Close(Op);
if (Found) and not ListOnly then
  begin
  Assign(F,FileName);
  BakFile := FileName;
  if Pos('.',BakFile) <> 0 then
    BakFile := Copy(BakFile,1,Pos('.',BakFile)-1);
  BakFile := BakFile+'.BAK';
  Assign(B,BakFile);
  Reset(B);
  if IoResult = 0 then
    begin
    Close(B);
    Erase(B);
    end;
  if not NoBAK then
    Rename(F,BakFile)
  else
    Erase(F);
  if not CheckIo then ;
  Assign(F,'SR$$$.PAS');
  Rename(F,FileName);
  if not CheckIo then ;
  end
else
  if not ListOnly then
    Erase(Op);
FreeMemCheck(Line,SizeOf(Line));
FreeMemCheck(CurWord,SizeOf(CurWord));
if not CheckIo then ;
{$I-}
end;
{-------------------------------------------------}
Procedure ResetListFile;
begin
ListFileRead := False;
end;
{-------------------------------------------------}
Procedure DisplayInsertMode;
begin
If InsertMode then
  begin
  SetFillColors;
  WriteStr(76,25,'Ins',TextAttr);
  end
else
  begin
  SetFillColors;
  WriteStr(76,25,'Ovs',TextAttr);
  end;
end;

End.
