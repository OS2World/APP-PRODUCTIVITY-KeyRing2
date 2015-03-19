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
{$A-,B-,D-,E-,F+,I-,L+,N-,O+,R-,S-,V-}
{.$M 16384,0,655360}
UNIT UReaders;

(*******************************************************)
  interface
(*******************************************************)

USES
  DOS, OpCrt, Umoveops, URLine, UWindow, UDialog, UMsg;

TYPE
  ViewPtr = ^Reader;
  Reader = Object(Scroller)
    FO : FileOfLines;
    CONSTRUCTOR Init(FN : String; FileBufSize : Word;
		     px1,py1,px2,py2 : integer);
    DESTRUCTOR Done;
    PROCEDURE Help; virtual;

    FUNCTION DTAline(Row : LongInt) : String; virtual;
    PROCEDURE GotoLine(X : LongInt); virtual;

    PROCEDURE CheckRFerror;
    PROCEDURE ShowStatus; virtual;
    PROCEDURE Message(s : str80); virtual;
    FUNCTION AskString(prompt : string) : string; virtual;
  END;

(*******************************************************)
  implementation
(*******************************************************)

  CONSTRUCTOR Reader.Init(FN : string; FileBufSize : word;
		     px1,py1,px2,py2 : integer);
  BEGIN
    IF FO.Init(FN, FileBufSize)
    THEN BEGIN
      checkrferror;
      Scroller.Init(px1,py1,px2,py2,FO.TotalLines)
    END ELSE Fail;
  END;

  PROCEDURE Reader.CheckRFerror;
  BEGIN
    With FO Do BEGIN
      if (RFerror <> 0) and (RFerror <> $FFFF) THEN BEGIN
	Writeln(RFerrorString);
	Halt(1);
      END;
    END;
  END;


  DESTRUCTOR Reader.Done;
  BEGIN
    FO.Done;
    Scroller.Done;
  END;

  FUNCTION Reader.DTAline(Row : LongInt) : String;
  CONST
    Blanks : string[8] = '        ';
  VAR
    i : Integer;
  BEGIN
    With FO DO BEGIN
      SeekLine(Row);
      IF RFerror = 0 THEN BEGIN
        i := pos(^I,LastLine);		{ Expand existing tabs }
        while i > 0 do BEGIN
	  LastLine[i] := ' ';
	  Blanks[0] := chr(i mod 8);
	  if blanks[0] > #0
          then blanks[0] := chr(8 - ord(blanks[0]));
	  insert(blanks, LastLine, i);
	  i := pos(^I,LastLine);
        END;
        DTAline := LastLine;
      END ELSE BEGIN
        DTAline := '';
        RFerror := 0;
      END;
    END;
  END;

  PROCEDURE Reader.GotoLine(X : LongInt);
  BEGIN
    IF x <= TotalItems
    THEN Scroller.GotoLine(x)
    ELSE Message(SysMsg(000914){'Attempted to GotoLine past End Of File.'});
  END;

  TYPE
    Helper = object(Scroller)
      FUNCTION DTAline(Row : Longint) : String; virtual;
    END;

  CONST
    NHelpers = 17;

{$F+}
   FUNCTION Helper.DTAline(Row : Longint) : String;
   Var
     Hstrings : array[1..NHelpers] of String[32];
     I: integer;
   BEGIN
      HStrings[1] := SysMsg(000915){' F          Find text'};
      HStrings[2] := SysMsg(000916){' C          Case-sensitive find'};
      HStrings[3] := SysMsg(000917){' N          Find next'};
      HStrings[4] := SysMsg(000918){' A          Auto-Scroll'};
      HStrings[5] := SysMsg(000919){' 0..9       Adjust scroll speed'};
      HStrings[6] := SysMsg(000920){'PgUp/PgDn   Page up and down'};
      HStrings[7] := SysMsg(000921){'Home        Top of file'};
      HStrings[8] := SysMsg(000922){'End         Bottom of file'};
      HStrings[9] := SysMsg(000923){'Up arrow    Move up'};
      HStrings[10] := SysMsg(000924){'Down arrow  Move down'};
      HStrings[11] := SysMsg(000925){'Right arrow Scroll right'};
      HStrings[12] := SysMsg(000926){'Left arrow  Scroll Left'};
      HStrings[13] := SysMsg(000927){'Ctrl-Right  Scroll 8 chars right'};
      HStrings[14] := SysMsg(000928){'Ctrl-Left   Go to first column'};
      HStrings[15] := SysMsg(000929){'ESCape      Exit to DOS'};
      HStrings[16] := '';
      HStrings[17] := SysMsg(000930){'  Press ESCape now to return'};
     if Row <= NHelpers
     THEN DTAline := Hstrings[Row]
     ELSE DTAline := '';
   END;
{$F-}

  PROCEDURE Reader.Help;
  var
    H : Helper;
  BEGIN
    H.Init(x1,y1,x2,y2,NHelpers);
    H.WrScr;
    while H.scrollselect <> #27 do ;
    H.Done;
    wrscr;
  END;

  FUNCTION Reader.AskString(prompt : string) : string;
  var
    s : string[40];
    Escape: boolean;
  BEGIN
    AskString := '';
    GetInput(SysMsg(000931){'Search For Word'},
             SysMsg(000932){'View File'},Magenta,
             SysMsg(000933){'Search for: '},20,s,Escape);
{    gotoxy(1,2);
    clreol;
    write(prompt, ' ');
    readln(s);}
    AskString := s;
  END;

  PROCEDURE Reader.ShowStatus;
  var i : integer;
      At: byte;
  BEGIN
    At := TextAttr;
    TextColor(White);
    gotoxy(1,2);
    write(fo.filename, SysMsg(000934){'   Line '},IxNoY1,
          SysMsg(000844){' of '}, TotalItems, SysMsg(000935){'.  Col: '});
    TextAttr := At;
    clreol;
{    gotoxy(1,2);
    clreol;}
  END;

  PROCEDURE Reader.Message(s : str80);
  BEGIN
    gotoxy(1,2);
    write('> ', s);
    clreol;
  END;

END.
