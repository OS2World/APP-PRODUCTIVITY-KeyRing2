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
{$A-,B-,D-,E-,F+,I-,L+,N-,O+,R-,S-,V-}
{.$M 16384,0,655360}
UNIT UMoveOps;

{ Objects to move around in a rectangle. }

(***************************************)
INTERFACE
(***************************************)

USES
  OpCrt, DOS, UGlobal, UColors, UWindow, ULib, Qinput,Umsg;

TYPE
  Str80 = string[80];

  Rectangle = Object
		x1,y1,x2,y2 : integer;
		Height,Width : Integer;
		PROCEDURE Init(px1,py1,px2,py2 : integer);
	      END;

  ScreenR = object(Rectangle)
		IxNoY1 : LongInt;
		TotalItems : LongInt;     { Total number of items. }
		FirstColumn : Integer;    { First column displayed. }
		Constructor Init(px1,py1,px2,py2 : integer;
			       TotItems : LongInt);
		FUNCTION DTAline(Row : LongInt) : String; virtual;
		{ Returns string at Row }
		PROCEDURE WrScrLn(Y : Integer); virtual;
		{ Write the proper string at SCREEN line Y }
		PROCEDURE PgUp;
		PROCEDURE PgDn;
		PROCEDURE TOFL;
		PROCEDURE EOFL;  virtual;
		PROCEDURE ScrollUp;
		PROCEDURE ScrollDown;
		PROCEDURE MoveLeft(i : Integer);
		PROCEDURE MoveRight(i : Integer);
		PROCEDURE WrScr;   { writes entire screen. }
		PROCEDURE GotoLine(X : LongInt);
                PROCEDURE ChangeBackground;
                PROCEDURE ChangeForeground;
		Destructor Done;
	      END;

  Scroller = object(ScreenR)
		SearchString : string[80];
		CaseSensitive : Boolean;
		Constructor Init(px1,py1,px2,py2 : integer;
			       TotItems : LongInt);
		PROCEDURE ShowStatus; virtual;
		PROCEDURE Help; virtual;
		PROCEDURE AutoScroll;
		FUNCTION ScrollSelect : Char; virtual;
		FUNCTION AskString(prompt : string) : string; virtual;
		PROCEDURE Message(s : str80); Virtual;
		PROCEDURE SearchForward; virtual;
	      END;

  PROCEDURE UpCaseString(var s : string);
  FUNCTION InsensitiveMatch(var s1,s2 : string) : boolean;


(*****************************************************)
implementation
(*****************************************************)

{-------- Rectangle -------------}

  PROCEDURE Rectangle.Init(px1,py1,px2,py2 : integer);
  BEGIN
    x1 := px1;
    y1 := py1;
    x2 := px2;
    y2 := py2;
    height := y2-y1+1;
    width := x2-x1+1;
  END;

  Constructor ScreenR.Init(px1,py1,px2,py2 : integer;
			TotItems : LongInt);
  BEGIN
    Rectangle.Init(px1,py1,px2,py2);
    TotalItems := TotItems;
    IxNoY1 := 1;
    FirstColumn := 1;
  END;

  Destructor ScreenR.Done;  BEGIN  END;

  FUNCTION ScreenR.DTAline(Row : LongInt) : String;
  { responsible for returning line at 'Row'.  }
  { If Row < 1 or > TotalItems, returns '' blank string. }
  BEGIN
    runerror(211);
  END;

  PROCEDURE ScreenR.WrScrLn(Y : Integer);
  VAR
    s : string;
  BEGIN 		     { WrScrLn }
    s := DTALine(Pred(Y + IxnoY1));
    s := copy(s, FirstColumn, width);
    if length(s) < width then BEGIN
      fillchar(s[length(s)+1], width-length(s), ' ');
      s[0] := char(width);
    END;
    gotoxy(x1, pred(Y+y1));
    if wherey = 25
    then dec(s[0]);     { avoid scrolling the window writing at last column }
    write(s)
  END;

  PROCEDURE ScreenR.WrScr;
  VAR
    cy	    : Integer;
  BEGIN
    FOR cy := 1 TO Height
    DO WrScrLn(cy);
  END;

  PROCEDURE ScreenR.ScrollUp;
  var
   r : registers;
  BEGIN
    IF Pred(IxNoY1+Height) < TotalItems THEN BEGIN
      Inc(IxNoY1);
      IF Height > 1 then with r do BEGIN
	ax := $0601;  { scroll window, 1 line. }
	bh := textattr;
	ch := pred(y1);
	cl := pred(x1);
	dh := pred(y2);
	dl := pred(x2);
	intr($10,r);
      END;
      WrScrLn(Height);
    END;
  END;

  PROCEDURE ScreenR.ScrollDown;
  var
    r : registers;
  BEGIN
    IF IxNoY1 <> 1 THEN BEGIN
      Dec(IxNoY1);
      IF Height > 1 then with r do BEGIN
	ax := $0701;  { scroll window, 1 line. }
	bh := textattr;
	ch := pred(y1);
	cl := pred(x1);
	dh := pred(y2);
	dl := pred(x2);
	intr($10,r);
      END;
      WrScrLn(1);
    END;
  END;

  PROCEDURE ScreenR.MoveLeft(i : Integer);
  BEGIN
    Dec(FirstColumn,i);
    If FirstColumn < 1
    Then FirstColumn := 1;
    WrScr;
  END;

  PROCEDURE ScreenR.MoveRight(i : Integer);
  BEGIN
    Inc(FirstColumn,i);
    If FirstColumn > 255-width
    Then Firstcolumn := 255-width;
    WrScr;
  END;

  PROCEDURE ScreenR.TOFL;	     { ^A }
  BEGIN
    IxNoY1 := 1;
    FirstColumn := 1;
    WrScr;
  END;

  PROCEDURE ScreenR.EoFL;
  BEGIN
    IF TotalItems >= Height
    THEN IxnoY1 := Succ(TotalItems-Height)
    ELSE IxnoY1 := 1;
    WrScr;
  END;

  PROCEDURE ScreenR.PgUp;
  BEGIN	     { PgUp }
    IF IxNoY1 > Height
    THEN Dec(IxNoY1, Height)
    ELSE IxnoY1 := 1;
    WrScr;
  END;

  PROCEDURE ScreenR.PgDn;
  BEGIN	     { PgDn }
    IF Pred(IxNoY1)+(Height*2) <= Pred(TotalItems) THEN BEGIN
      Inc(IxNoY1, Height);
      WrScr;
    END ELSE EOFl;
  END;

  PROCEDURE ScreenR.GotoLine(X : LongInt);
  BEGIN
    IxnoY1 := X;
    wrscr;
  END;

{ SCROLLER ------------------------------------------------------}

  Constructor Scroller.Init(px1,py1,px2,py2 : integer;
			TotItems : LongInt);
  BEGIN
    ScreenR.Init(px1,py1,px2,py2,TotItems);
    SearchString := '';
    CaseSensitive := false;
  END;

  FUNCTION Scroller.AskString(prompt : string) : string;
  BEGIN
    AskString := '';
  END;

  PROCEDURE Scroller.ShowStatus;  BEGIN END;
  PROCEDURE Scroller.Message(s : Str80); BEGIN END;
  PROCEDURE Scroller.Help;  BEGIN END;

  PROCEDURE UpCaseString(var s : string);
  var
    i : integer;
  BEGIN
    for i := 1 to length(s) do s[i] := upcase(s[i]);
  END;

  FUNCTION InsensitiveMatch(var s1,s2 : string) : boolean;
  { s1 should be upper cased. }
  var
    i, j, k : integer;
    len : integer;
  BEGIN
    i := pos(s1[1],s2);
    j := pos(chr(ord(s1[1])+32), s2);
    IF (i or j) <> 0 THEN BEGIN
      if ((i > 0) and (i < j)) or (j = 0)
      then j := i;
      for i := j to length(s2)-length(s1)+1 do
	if upcase(s2[i]) = s1[1] then BEGIN
	  j := 2;
	  k := succ(i);
	  while (j <= length(s1)) and (s1[j] = upcase(s2[k])) do BEGIN
	    inc(k);
	    inc(j);
	  END;
	  if j > length(s1) then BEGIN
	    InsensitiveMatch := true;
	    Exit;
	  END;
	END;
    END;
    InsensitiveMatch := false;
  END;

  PROCEDURE Scroller.SearchForward;
  var
   i : longint;
   s2 : string;
   j,k : integer;
  BEGIN
    if length(SearchString) = 0 then Exit;
    Message(SysMsg(000962){'Searching forward for "'}+searchstring+'"');
    if not casesensitive then BEGIN
      for i := IxnoY1+1 to totalitems do BEGIN
	s2 := dtaline(i);
	if InsensitiveMatch(SearchString,s2) then BEGIN
	  GotoLine(i);
	  Exit;
	END;
      END;
    END ELSE BEGIN { case sensitive }
      for i := Ixnoy1+1 to totalitems do BEGIN
	if pos(SearchString,dtaline(i)) <> 0 then BEGIN
	  GotoLine(i);
	  Exit;
	END;
      END;
    END;
    Message('"'+SearchString+SysMsg(000963){'" Not Found.  Press any key'});
    while not Check4Chars do UpdateTime(False);
  END;


  PROCEDURE Scroller.AutoScroll;
  Const
    DelayMul = 150;
    Dlay : Integer = 5 * DelayMul;
  Var
    Finished : Boolean;
    ch,Ch2 : char;
    i : integer;
  BEGIN
    Finished := False;
    While Not Finished AND (IxnoY1 < TotalItems-Height) Do BEGIN
      UpdateTime(False);
      If Check4Chars Then BEGIN
        GetNextChar(Ch,Ch2);
	i := pos(Ch, '0123456789');
	if i > 0
	Then Dlay := i * DelayMul
	Else Finished := True;
      End Else BEGIN
        ScrollUp;
        ShowStatus;
	Delay(Dlay);
      END;
    END;
  END;

  Procedure ScreenR.ChangeBackground;
    var i: integer;
    begin
      With NENColorSet do
        begin
          for I := 2 to 25 do
            ChangeAttribute(80,I,1,
              TextAttr);
        end;
    end;

  Procedure ScreenR.ChangeForeground;
    var i: integer;
    begin
      With NENColorSet do
        begin
          for I := 2 to 25 do
            ChangeAttribute(80,I,1,
              TextAttr);
        end;
    end;

  FUNCTION Scroller.ScrollSelect : Char;
  { scroll through file until an invalid key is pressed. }
  VAR
    Ch,Ch2 : Char;
    Finished : Boolean;
  BEGIN
    Finished := False;
    REPEAT
      ShowStatus;
      Ch := #32;
      While not Check4Chars do
        UpdateTime(False);
      GetNextChar(Ch,Ch2);
      If Ch = #0 Then BEGIN
        Ch := Ch2;
	Case Ch OF
	  #59  : Help;
	  #80 : ScrollUp;
	  #72 : ScrollDown;
	  #77 : MoveRight(1);
	  #75 : MoveLeft(1);
	  #115 : MoveLeft(8);
	  #116 : MoveRight(8);
	  #73 : PgUp;
	  #81 : PgDn;
	  #71 : TOFL;
	  #79 : EOFl;
          F5  : ChangeBackground;
          F6  : ChangeForeGround;
          #27 : Finished := True;
	END;
      END ELSE CASE UpCase(Ch) OF
	'F','C' : BEGIN
		    CaseSensitive := Ch in ['C','c'];
		    IF Not CaseSensitive
		    THEN UpCaseString(SearchString);
		    SearchForward;
		  END;
	'N' : SearchForward;
	'A' : AutoScroll;
        #27 : Finished := True;
      END;
    UNTIL Finished;
    ScrollSelect := Ch;
  END;

END.
