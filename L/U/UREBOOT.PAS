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
{$F+,O-}
{**********************************************************************}
{* (C) 1993 NewsMaker Systems.                                        *}
{* Ctrl+Alt+Del trap                                                  *}
{* Thanks to Kim Kokkonen at TurboPower software for the basic method *}
{*                                                                    *}
{* Added debugger interrupt trap - goes into infinite loop on INT 1,  *}
{* INT 2, or INT 3  KGM 9-93                                          *}
{**********************************************************************}

unit UReboot;
{$I NDEFINE.INC}
interface

procedure DisableReboot;
procedure EnableReboot;

const
  RebootRequested : Boolean = False; { Set if Ctrl+Alt+Del pressed }
  SecretReboot    : Boolean = True;  { Enables Backdoor reboot     }

implementation

uses
  Dos,
  OpCol16,
  OpCrt,
  OpInline,
  OpInt;

var
  PreExitProc    : Pointer;
  SaveInt09      : Pointer;
  Scan           : Word;

const
  ISRInstalled   : Boolean = False;
  AltFlag        = $08;
  CtrlFlag       = $04;
  ShiftFlag      = $02;
  CtrlAlt        = AltFlag + CtrlFlag;
  CtrlAltShift   = AltFlag + CtrlFlag + ShiftFlag;

                  { \ }
  Backdoor       = $2B;      { Ctrl+Alt+Shift+BackdoorScan hot reboot }

  procedure NoCtrlAltDel; Interrupt; { Portions Courtesy Kim K. at TurboPower }
  var
    KbdFlags       : Byte absolute $0040 : $0017;
    Scan           : Byte;
    BackDoor       : Byte;

    procedure IgnoreKeystroke;
    begin
    Scan := Port[$61];
    Port[$61] := Scan or $80;
    Port[$61] := Scan;
    Port[$20] := $20;
    end;

  begin
  { Check for secret reboot sequence Ctrl+Alt+Shift+Backdoor }

  if SecretReboot then
    if KbdFlags and CtrlAltShift = CtrlAltShift then
      begin
      Scan := Port[$60];
      if Scan and $7F = BackDoor then
        begin
        FastWrite('Restarting System..', 1,1, WhiteOnRed);
        Reboot;
        end;
      end;

  { Check for Ctrl-C }

  if KbdFlags and CtrlAlt = CtrlFlag then
    begin
    {Ctrl pressed }
    Scan := Port[$60];
    if Scan and $7F = $2E then
      begin
      { Ctrl-C pressed. Ignore }
      IgnoreKeystroke;
      Exit;
      end;
    end;

  { Check for Ctrl+Alt+Del }

  if KbdFlags and CtrlAlt = CtrlAlt then
    begin
    {Ctrl and Alt depressed}
    Scan := Port[$60];
    if Scan and $7F = $53 then
      begin
      {Del pressed or released. Ignore keystroke}
      IgnoreKeystroke;
      RebootRequested := True;
      Exit;
      end;
    end;

  asm       { Chain to previous Keyboard handler }
    pushf
    call    dword ptr SaveInt09
    end;
  end;

    PROCEDURE DisableControlC;
    VAR
        Regs       : Registers;
    BEGIN
        Regs.AH := $33;                 { Disable ^C }
        Regs.AL := 1;
        Regs.DL := 0;
        MsDos(Regs);
        CheckBreak := False;            { Disable ^Break }
    END;

  procedure EnableControlC;
  var Regs       : Registers;
  begin
  Regs.AH := $33;
  Regs.AL := 1;
  Regs.DL := 1;
  MsDos(Regs);
  CheckBreak := True;
  end;

  procedure InstallVector;
  begin
  GetIntVec($09, SaveInt09);
  SetIntVec($09, @NoCtrlAltDel);
  end;

  procedure RemoveVector;
  begin
  SetIntVec($09, SaveInt09);
  end;

  procedure ReEnableReboot; Far;  {ExitProc }
  begin
  if ISRInstalled then
    begin
    ExitProc := PreExitProc;      {Point ExitProc to next  }
    RemoveVector;                 {Return old Int 9 Vector }
    ISRInstalled := False;
    end;
  end;

  (**************************************************)
    {$IFDEF SECUREPGM}
    {$IFNDEF DEBUG}
    {Debuggers check in, but they dont check out}
    {This function goes into non-breakable infinite loop when this }
    {interrupt handler gets called by an unsuspecting debugger     }
    {hacker/user}
    PROCEDURE RoachHotel(BP : WORD); INTERRUPT;
    LABEL
        Hell;
    BEGIN
        Hell :;
        GOTO Hell;
    END;

    {$ENDIF}
    {$ENDIF}

  (**************************************************)

  procedure DisableReboot;
  begin
      {$IFNDEF DEBUG}
      {This stuff crashes the IDE when you hit Ctrl-C, so shut it off }
      {during development KGM-11/94                                   }
      if not ISRInstalled then begin
          DisableControlC;              {Disable CtrlC/Break           }
          InstallVector;                {Point Intr 9 to ISR, save old }
          PreExitProc := ExitProc;      {Save old ExitProc             }
          ExitProc := @ReEnableReboot;  {Link in ExitProc              }
          ISRInstalled := True;
      end;
    {$ENDIF}
  end;

  procedure EnableReboot;
  begin
  {$IFNDEF DEBUG}
  EnableControlC;
  ReEnableReboot;
  {$ENDIF}
  end;

    {$IFDEF SECUREPGM}
    {$IFNDEF DEBUG}
    {- revectors debugger ISR to our little black hole - RoachMotel}
    PROCEDURE ECM;
    VAR
        H : BYTE;
    BEGIN
        H := 1;
        WHILE NOT InitVector($03, H, @RoachHotel) DO
            INC(H);
        INC(H);
        WHILE NOT InitVector($02, H, @RoachHotel) DO
            INC(H);
        INC(H);
        WHILE NOT InitVector($01, H, @RoachHotel) DO
            INC(H);
    END;
    {$ENDIF}
    {$ENDIF}

BEGIN
    {$IFDEF SECUREPGM}
    {$IFNDEF DEBUG}
    {a little landmine for hackers using debuggers}
    ECM;
    WRITELN(PARAMSTR(0));
    DELAY(500);
    {$ENDIF}
    {$ENDIF}

end.
