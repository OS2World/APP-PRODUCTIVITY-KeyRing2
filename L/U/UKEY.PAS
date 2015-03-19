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
{$A-,V-,O+,F+,X+}                 { Do NOT overlay }

{$IFDEF DPMI}
{$C FIXED PERMANENT}
{$ENDIF}

{ Key/Mouse get for Turbo-Power routines, so that we can }
{ perform our background processing }

unit UKey;

interface

uses
  Dos,
  OpCrt, OpCol16, OpString, OpMouse,
  QGlobal, QInput, QUpTime,
  UGLOBAL, ULib;

type
  BackgroundTask                = procedure;

function KeyWaiting           : Boolean;
function GetKey               : Word; { exclusively for TurboPower routines }
procedure DisableControlC;
procedure EnableControlC;
procedure WaitUntilButtonReleased;
procedure RegisterBackgroundTask(Task : BackgroundTask);
procedure DeRegisterBackgroundTask;
function KbdKeyPressed        : Boolean;

var
  RunBackground                 : BackgroundTask;

implementation

  procedure NilBackground;
  begin
  end;

  {-------------------------------------------------------}

  function KeyWaiting           : Boolean;
  begin
  KeyWaiting := Check4Chars;
  if NENFlag then
    UpTime
  else
    UpdateWtime(False);
  RunBackground;
  end;

  {-------------------------------------------------------}
  {OPRO Version of above}
  function KbdKeyPressed        : Boolean;
    {- check kbd buffer for pending keystrokes}
  begin
  if KeyOrButtonPressed then
    KbdKeyPressed := True
  else 
  begin
  inline($CD / $28);              {allow TSRs to pop up}
  if NENFlag then
    UpTime
  else
    UpdateWtime(False);
  KbdKeyPressed := KeyOrButtonPressed;
  end;
  end;

  (****************************************************************************)

  function GetKey               : Word;
  var
    I                             : Word;
    Ch1, Ch2                      : Char;
    Scan                          : Word;
  begin
  I := $FFFF;
  repeat
    if not KeyWaiting then
      begin
      inline($CD / $28);            { Allow TSRs to pop up }
      end
    else
      begin
      I := GetNextChar(Ch1, Ch2);
      LastCharTime := CurrentTime;
      end;
  until I <> $FFFF;
  GetKey := I;
  end;

  procedure RegisterBackgroundTask(Task : BackgroundTask);
  begin
  RunBackground := Task;
  end;

  procedure DeRegisterBackgroundTask;
  begin
  RunBackground := NilBackground;
  end;

  procedure DisableControlC;
  begin
  with UData^ do 
  begin
  Regs.AH := $33;                 { Disable ^C }
  Regs.AL := 1;
  Regs.DL := 0;
  MSDOS(Regs);
  CheckBreak := False;            { Disable ^Break }
  end;
  end;

  procedure EnableControlC;
  begin
  with UData^ do 
  begin
  Regs.AH := $33;
  Regs.AL := 1;
  Regs.DL := 1;
  MSDOS(Regs);
  CheckBreak := True;
  end;
  end;

  {***************************************************}
  { WaitUntilButtonReleased                           }
  {***************************************************}

  procedure WaitUntilButtonReleased;
  begin
  while MousePressed do
    if NENFlag then
      UpTime
    else
      UpdateWtime(False);
  end;

begin
RunBackground := NilBackground;
end.
