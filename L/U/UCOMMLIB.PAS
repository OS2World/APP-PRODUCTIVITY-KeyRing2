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
{$A-,V-,R-,S-,O+,F+}
{.$D+}

{ Odd routines for Ucomm that cannot be overlaid, generally because }
{ their address is passed as a parameter, & the overlay system then }
{ would move them.                                                  }


Unit UCommLib;

Interface

Uses OpCrt,OpFrame,OpWindow;

Type
CommWindowPtr = ^CommWindow;
CommWindow = Object(CommandWindow)
    Cx,Cy : byte;
    Colors: ColorSet;

    procedure Process; virtual;
  end;

Procedure Multi(var Value;ID: word;Factor: integer;var S: String);

var
  CommWin : CommWindowPtr;

implementation

{----------------------------------------------------------------}
{ Multiple choice field processor for EditService                }

Procedure Multi(var Value;ID: word;Factor: integer;var S: String);
  var Bval: byte absolute Value;
      Wval: word absolute Value;
  Const
      ValidPorts : Array[1..4] of String[4] =
                   ('COM1','COM2','COM3','COM4');
      ValidBaud  : Array[1..5] of String[4] =
                   ('300','1200','2400','4800','9600');
      ValidData  : Array[7..8] of String[1] =
                   ('7','8');
      ValidStop  : Array[1..2] of String[1] =
                   ('1','2');
      ValidParity: Array[1..3] of String[1] =
                   ('N','E','O');
      ValidTerm  : Array[1..5] of String[5] =
                   ('TTY','VT52','VT100','ANSI','VTEXT');

  begin
    Case ID of
      1 :  begin    { COM port }
             Case Factor of
                 1 : if Wval = 4 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 4 else dec(Wval);
               end;
               S := ValidPorts[Wval];
           end;
      3 :  begin    { Baud Rate }
             Case Factor of
                 1 : if Wval = 5 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 5 else dec(Wval);
               end;
               S := ValidBaud[Wval];
           end;
      4 :  begin    { Parity }
             Case Factor of
                 1 : if Wval = 3 then
                      Wval := 1 else inc(Wval);
                -1 : if Wval = 1 then
                      Wval := 3 else dec(Wval);
               end;
             S := ValidParity[Wval];
           end;
      5 :  begin    { Data bits }
             Case Factor of
                 1 : if Wval = 8 then
                      Wval := 7 else inc(Wval);
                -1 : if Wval = 8 then
                      Wval := 7 else dec(Wval);
               end;
             S := ValidData[Wval];
           end;
      6 :  begin    { Stop bits }
             Case Factor of
                 1 : if Wval = 2 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 2 else dec(Wval);
               end;
               S := ValidStop[Wval];
           end;
      7 :  begin    { Terminal type }
             Case Factor of
                 1 : if Wval = 5 then
                      Wval := 1 else inc(Wval);
                -1 : if Wval = 1 then
                      Wval := 5 else dec(Wval);
               end;
               S := ValidTerm[Wval];
           end;
      end;
  end;

  Procedure CommWindow.Process;
    begin
      CommandWindow.Process;
    end;

End.
