{*********************************************************}
{*                   NETSEMA.PAS 5.41                    *}
{*        Copyright (c) TurboPower Software 1989.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I BTDefine.Inc}
{$F-,V-,B-,S-,I-,R-}
{$IFDEF CanSetOvrflowCheck}
  {$Q-}
{$ENDIF}

Unit NetSema;
  {-NetWare semaphore API calls}

interface

uses
  {$IFDEF DPMIorWnd}
  WinDPMI,
  WinDos;
  {$ELSE}
  Dos;
  {$ENDIF}
type
  SemaphoreName  = String[127];

function OpenSemaphore(Name : SemaphoreName; InitialValue : ShortInt;
                       var OpenNumber : Byte;
                       var SemaHandle : LongInt) : Boolean;

function ExamineSemaphore(Handle : LongInt; var Value : ShortInt;
                          var OpenNumber : Byte) : Boolean;

function WaitOnSemaphore(Handle : LongInt; TimeOutValue : Word;
                         var TimeOut : Boolean) : Boolean;

function SignalSemaphore(Handle : LongInt; var OverFlow : Boolean) : Boolean;

function CloseSemaphore(Handle : LongInt) : Boolean;

implementation
type
  DoubleWord       = record
                       LoWord  : Word;
                       HiWord  : Word;
                     end;
  {$IFDEF DPMIOrWnd}
  Registers = TRegisters;
  {$ENDIF}

function MakeLong(HiWord,LoWord : Word) : LongInt;
{takes hi and lo words and makes a longint }
Inline(
  $58/    { pop ax ; pop low word into AX }
  $5A);   { pop dx ; pop high word into DX }

function OpenSemaphore(Name : SemaphoreName; InitialValue : ShortInt;
                       var OpenNumber : Byte;
                       var SemaHandle : LongInt) : Boolean;
var
  Regs : Registers;
  {$IFDEF DPMIOrWnd}
  S, P : Pointer;
  {$ENDIF}
begin
  {$IFDEF DPMIOrWnd}
  OpenSemaphore := False;
  if not GetRealModeMem(SizeOf(SemaphoreName), S, P) then Exit;
  Move(Name, P^, Length(Name) + 1);
  {$ENDIF}
  with Regs do begin
    AX := $C500;
    CL := InitialValue;
    {$IFDEF DPMIOrWnd}
    DS := SegOfs(S).Segm;
    DX := SegOfs(S).Ofst;
    WinIntr($21, Regs);
    {$ELSE}
    DS := Seg(Name);
    DX := Ofs(Name);
    MsDos(Regs);
    {$ENDIF}
    if AL = 0 then begin
      OpenNumber := BL;
      SemaHandle := MakeLong(DX, CX);
      OpenSemaphore := True;
    end
    else
      OpenSemaphore := False
  end;
  {$IFDEF DPMIOrWnd}
  FreeRealModeMem(P);
  {$ENDIF}
end;

function ExamineSemaphore(Handle : LongInt; var Value : ShortInt;
                          var OpenNumber : Byte) : Boolean;

var
  Regs : Registers;
begin
  with Regs do begin
    AX := $C501;
    CX := DoubleWord(Handle).LoWord;
    DX := DoubleWord(Handle).HiWord;
    {$IFDEF DPMIOrWnd}
    WinIntr($21, Regs);
    {$ELSE}
    MsDos(Regs);
    {$ENDIF}
    if AL = 0 then begin
      OpenNumber := DL;
      Value := CX;
      ExamineSemaphore := True;
    end
    else
      ExamineSemaphore := False;
  end;
end;

function WaitOnSemaphore(Handle : LongInt; TimeOutValue : Word;
                         var TimeOut : Boolean) : Boolean;
var
  Regs : Registers;

begin
  with Regs do begin
    AX := $C502;
    CX := DoubleWord(Handle).LoWord;
    DX := DoubleWord(Handle).HiWord;
    BP := TimeOutValue;
    {$IFDEF DPMIOrWnd}
    WinIntr($21, Regs);
    {$ELSE}
    MsDos(Regs);
    {$ENDIF}
    TimeOut := False;
    if AL <> 0 then begin
      if AL = $FF then begin
        WaitOnSemaphore := False;
        Exit;
      end
      else
        TimeOut := True;
    end;
    WaitOnSemaphore := True;
  end;
end;

function SignalSemaphore(Handle : LongInt; var OverFlow : Boolean) : Boolean;
var
  Regs : Registers;

begin
  with Regs do begin
    AX := $C503;
    CX := DoubleWord(Handle).LoWord;
    DX := DoubleWord(Handle).HiWord;
    {$IFDEF DPMIOrWnd}
    WinIntr($21, Regs);
    {$ELSE}
    MsDos(Regs);
    {$ENDIF}
    Overflow := False;
    if AL <> 0 then begin
      if AL = $FF then begin
        SignalSemaphore := False;
        Exit;
      end
      else
        Overflow := True;
    end;
  end;
  SignalSemaphore := True;
end;

function CloseSemaphore(Handle : LongInt) : Boolean;
var
  Regs : Registers;

begin
  with Regs do begin
    AX := $C504;
    CX := DoubleWord(Handle).LoWord;
    DX := DoubleWord(Handle).HiWord;
    {$IFDEF DPMIOrWnd}
    WinIntr($21, Regs);
    {$ELSE}
    MsDos(Regs);
    {$ENDIF}
    CloseSemaphore := AL = 0;
  end;
end;

end.
