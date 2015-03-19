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
{$A-,R-,S-,V-,O+,F+}

{**********************************************************************}
{ (C) 1990 NewsMaker Systems                                           }
{  Terminal Emulation routines for Ucomm                               }
{  Call CheckEmulation for each character received. All appropriate    }
{  checks will be made, & any control sequences processed.             }
{  On return, pointer will be at next character past terminal          }
{  control sequence.                                                   }
{  Protocols supported:                                                }
{        VT52  - a simple escape sequence for cursor positioning       }
{        VT100 - a more comprehensive protocol                         }
{        ANSI  - same as VT100, with color extensions                  }
{        VuTEXT- special for VuText. TTY but happy face=home,clear     }
{**********************************************************************}

Unit Uterm;

interface

Uses Dos,
     OpCrt,OpMouse,OpColor,
     UGlobal,UColors,Qinput,LctKrnl,LctSupp,Ulib,Uservice,UCommLib;

Const
  VT52seq   : Set of char = [#27,#155];
  VT100seq  : Set of char = [#27];
  ANSIseq   : Set of char = [#27];
  VuTextseq : Set of char = [#2];

Const
  Emulation : word = 0;

Procedure CheckEmulation(ComPort: word;Var IoCh: char);

Procedure VT52  (ComPort: word;Var ioCh: Char);  { Internal protocol routines }
Procedure VT100 (ComPort: word;Var ioCh: Char);
Procedure ANSI  (ComPort: word;Var ioCh: Char);
Procedure VuText(ComPort: word;Var IoCh: Char);

Procedure WriteToScreen(Ch: char);

implementation

Const
  VTLines = 24;
  VT100Resp : String[7] = #27+'[?1;2c';  { VT100 with ATO }

Var   CharIn:  boolean;
      Ch,Ch2:  Char;
      X,Y:     integer;
      Scan:    word;
      XY  :    word;
      Cursor:  word;
      Com   :  word;

Procedure InputChar(Com: word;Var Ch: char);
  var B: byte;
  begin
  if LctGet(Com,b) then
    begin
    Ch := Chr(b);
    end
  else
    Ch := #0;
  end;

Procedure WriteToScreen(Ch: char);
  begin
    with CommWin^ do
      begin
        if Ch = #$0D then
          begin
            Cx := 1;
            wGotoXY(Cx,Cy);
            exit;
          end;
        if Ch = #$0A then
          begin
            inc(Cy);
            wGotoXY(Cx,Cy);
            exit;
          end;
        wFastWrite(Ch,Cy,Cx,CommWin^.Colors.TextColor);
        wGotoXY(Cx,Cy);
        inc(Cx);
        if Cx >= 80 then
          begin
            Cx := 1;
            inc(Cy);
          end;
{          Write(Ch);}
      end;
  end;

{ Utility Char input for Terminal emulation routines }

Procedure GetHostTalk(Com: word;Var CharIn: Boolean; Var Ch: Char);
  Var
    Loop: Word;
    b: byte;
  Begin
  Loop:= 0;
  CharIn:= False;
    While Check4Chars do GetNextChar(Ch,Ch2); {Let's not be bothering the host.}
  Repeat
    Inc(Loop);
    If Loop > 30000 then
      begin
        Ch:= ^G;
        EXIT;
      end;
    InputChar(Com,Ch);
    if Ch <> #0 then CharIn := True else CharIn := False;
    Until CharIn OR ((Loop > 1000) AND Check4Chars);
  If NOT CharIn then
    begin
      While Check4Chars do GetNextChar(Ch,Ch2);
      Ch:= ^G;
    end;
End;

Procedure ClearBeyondCursor;
  Var
    Line: Byte;
  Begin
    with CommWin^,wFrame do
      begin
        wWhereXY(X,Y);
        HideMouse;
        If (X=1) and (Y=1) then begin ClrScr; ShowMouse; EXIT; end;
        ClrEOL;
        If (Y = VTLines) then EXIT;
        Window(frXl+1,Succ(Y),frXh-1,frYh-1);
        ClrScr;
        Window(frXl+1,frYl+1,frXh-1,frYh-1);
        wGoToXY(X,Y);
        ShowMouse;
      end;
End;

Procedure ClearBeforeCursor;
  Var
    Line: Byte;
    I: integer;
  Begin
    with CommWin^,wFrame do
      begin
        wWhereXY(X,Y);
        HideMouse;
        If (X=1) and (Y=1) then begin ClrScr; ShowMouse; EXIT; end;
        If (Y = VTLines) then EXIT;
        Window(frXl+1,frYl+1,frXh-1,Pred(Y));
        ClrScr;
        for I := 1 to X-1 do
          WriteToScreen(' ');
        Window(frXl+1,frYl+1,frXh-1,frYh-1);
        wGoToXY(X,Y);
      end;
  ShowMouse;
End;

Procedure PositionCursor;
Begin
  with CommWin^,wFrame do
    begin
      GetHostTalk(Com,CharIn, Ch);
      If CharIn then
        begin
        Y:= Ord(Ch) - 31;
        GetHostTalk(Com,CharIn, Ch);
        If CharIn then X:= Ord(Ch) - 31 else EXIT;
        wGoToXY(X,Y);
        end;
    end;
End;

Function WhereX: byte;
  var X,Y: integer;
  begin
    CommWin^.wWhereXY(X,Y);
    WhereX := X;
  end;

Function WhereY: byte;
  var X,Y: integer;
  begin
    CommWin^.wWhereXY(X,Y);
    WhereY := Y;
  end;

Procedure GotoXY(X,Y: byte);
  begin
    CommWin^.wGotoXY(X,Y);
  end;

Procedure VT52(ComPort: word;Var ioCh: Char);
  Begin {VT52}
    Com := ComPort;
    Repeat
      GetHostTalk(ComPort,CharIn, ioCh);
      Case ioCh of
        'Y'   :  PositionCursor;
        'J'   :  ClearBeyondCursor;
        ELSE     EXIT;
      end;
      If NOT CharIn then EXIT;
      GetHostTalk(ComPort,CharIn, ioCh);
    until NOT (ioCh IN VT52seq);
  End;

Procedure VT100(ComPort: word;Var ioCh: Char);
  Var Param: String[20];
      Value: array[1..25] of integer;
      VIX  : integer;
      I    : integer;
  Label Top;

    Function Max(Val1,Val2: integer): integer;
      begin
        if Val2 > Val1 then
          Max := Val2 else Max := Val1;
      end;

    Procedure GetParam(var Value: integer;var Term: char);
      begin
        Param := '';
        Repeat
          GetHostTalk(Com,CharIn,IoCh);
          if CharIn then
            if IoCh in ['0'..'9'] then
              Param := Param+IoCh;
          until IoCh in ['A'..'Z','a'..'z',';',#27];
        Term := IoCh;
        Value := 0;
        if Param <> '' then Val(Param,Value,I);
      end;

  Begin {VT100/ANSI}
    Com := ComPort;
    Repeat
      GetHostTalk(Com,CharIn, ioCh);
      FillChar(Value,50,#0);
      Case ioCh of  { Must process all characters up to next command or data char}
        '['   :  begin
                   VIX := 1;
                   GetParam(Value[VIX],IoCh);
                   Top:  { can loop back here }
                   Case IoCh of
                     'A'  :  GotoXY(WhereX,WhereY-Max(1,Value[VIX]));  { Cursor Up }
                     'B'  :  GotoXY(WhereX,WhereY+Max(1,Value[VIX]));  { Cursor Dn }
                     'C'  :  GotoXY(WhereX-Max(1,Value[VIX]),WhereY);  { Cursor Lf }
                     'D'  :  GotoXY(WhereX+Max(1,Value[VIX]),WhereY);  { Cursor Rt }
                     ';'  :  begin                                { Cursor abs}
                               Repeat
                                 inc (VIX);
                                 GetParam(Value[VIX],IoCh);
                                 until IoCh <> ';';
                                 Goto Top;
                             end;
                     'J'  :  begin    { Erase in display }
                               GetCursorState(XY,Cursor);
                               HideMouse;
                               Case Value[VIX] of
                                 0  : ClearBeyondCursor;
                                 1  : ClearBeforeCursor;
                                 2  : ClrScr;
                                 end;
                               ShowMouse;
                               RestoreCursorState(XY,Cursor);
                             end;
                     'H',
                     'f'  :  begin    { Position X,Y }
                               if VIX = 2 then
                                 GotoXY(Max(1,Value[2]),Max(1,Value[1]))
                               else
                                 GotoXY(1,Max(1,Value[1]));
                             end;
                     'K'  :  begin    { Erase in Line }
                               GetCursorState(XY,Cursor);
                               Case Value[1] of
                                 0  : ClrEOL;
                                 1  : for I := 1 to WhereX do
                                        WriteChr(I,WhereY,' ',TextAttr);
                                 2  : begin
                                        GotoXY(1,WhereY);
                                        ClrEOL;
                                      end;
                                 end;
                               RestoreCursorState(XY,Cursor);
                             end;
                     's'  :  GetCursorState(XY,Cursor);
                     'u'  :  RestoreCursorState(XY,Cursor);
                     'm'  :  begin   { Graphic state }
                               with CommWin^.Colors do
                               for I := 1 to VIX do
                                 Case Value[I] of
                                   0  : TextAttr := TextColor;
                                   1  : HighVideo;
                                   5  : TextAttr := TextAttr or Blink;
                                   7  : TextAttr := (TextColor shl 4) or
                                                    (TextColor shr 4);
                                   8  : TextAttr := (TextColor and $F0) or
                                                    (TextColor shr 4);
                                   30 : OpCrt.TextColor(Black); { ANSI extensions }
                                   31 : OpCrt.TextColor(Red);
                                   32 : OpCrt.TextColor(Green);
                                   33 : OpCrt.TextColor(Yellow);
                                   34 : OpCrt.TextColor(Blue);
                                   35 : OpCrt.TextColor(Magenta);
                                   36 : OpCrt.TextColor(Cyan);
                                   37 : OpCrt.TextColor(White);
                                   40 : OpCrt.TextBackground(Black);
                                   41 : OpCrt.TextBackground(Red);
                                   42 : OpCrt.TextBackground(Green);
                                   43 : OpCrt.TextBackground(Brown);
                                   44 : OpCrt.TextBackground(Blue);
                                   45 : OpCrt.TextBackground(Magenta);
                                   46 : OpCrt.TextBackground(Cyan);
                                   47 : OpCrt.TextBackground(LightGray);
                                   end;
                             end;
                     'c'  :  begin   { Who Are you? }
                             if PutStream(Com,VT100Resp[1],Ord(VT100Resp[0]))
                               = 0  then;
                             end;
                     end;
                 end;
        'c'   :  begin   { Reset }
                   GotoXY(1,1);
                   with CommWin^.Colors do
                     TextAttr := TextColor;
                   HideMouse;
                   ClrScr;
                   ShowMouse;
                 end;
        '7'   :  GetCursorState(XY,Cursor);
        '8'   :  RestoreCursorState(XY,Cursor);
        ELSE     exit;
      end; { Case }
      If not CharIn then EXIT;
      if BytesInInput(Com) > 0 then
        GetHostTalk(Com,CharIn, ioCh)
      else
        IoCh := #0;
    until NOT (ioCh IN VT100seq);
  End;

Procedure ANSI(ComPort: word;Var ioCh: Char);
  begin
    VT100(Comport,IoCh);
  end;

Procedure VuText(ComPort: word;Var IoCh: Char);
  begin
    GotoXY(1,1);
    with CommWin^.Colors do
      TextAttr := TextColor;
    HideMouse;
    ClrScr;
    ShowMouse;
    IoCh := #0;
  end;

Procedure CheckEmulation(ComPort: word;Var IoCh: char);
  begin
    if Emulation = 0 then exit;
    Case Emulation of
      VT52Mode :  begin            { if VT52 esc seq }
                    If IoCh in VT52seq then
                      VT52(Service^.ComPort,IoCh);
                  end;
      VT100Mode : begin           { if VT100 esc seq }
                    if IoCh in VT100seq then
                      VT100(Service^.ComPort,IoCh);
                  end;
      ANSIMode  : begin           { if ANSI esc seq }
                    if IoCh in ANSIseq then
                      ANSI(Service^.ComPort,IoCh);
                  end;
      VuTextMode: begin           { if VuTEXT esc seq }
                    if IoCh in VuTEXTseq then
                      VuTEXT(Service^.ComPort,IoCh);
                  end;
      end;

  end;

End.
