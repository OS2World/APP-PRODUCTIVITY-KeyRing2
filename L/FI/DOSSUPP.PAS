(**************************************************************)
(*           B-Tree Filer DOS Support Ver 5.51                *)
(*       Copyright (C) 1995 TurboPower Software Co.           *)
(**************************************************************)

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}
  {$F-,V-,B-,S-,I-,R-}
  {$IFDEF CanAllowOverlays}
    {$O+,F+}
  {$ENDIF}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}

unit DosSupp;

interface

uses
  BaseSupp,
  SysUtils,
  WinProcs,
  WinTypes;

procedure Intr(IntNo : Byte; var Regs: GenRegisters);
procedure MsDos(var Regs: GenRegisters);
function  DosVersion: Word;
procedure GetIntVec(IntNo: Byte; var Vector: Pointer);
procedure SetIntVec(IntNo: Byte; Vector: Pointer);
procedure GetDate(var Year, Month, Day, DayOfWeek: Word);
procedure GetTime(var Hour, Minute, Second, Sec100: Word);

implementation

var
  IntrSelector : word;

procedure Intr(IntNo : Byte; var Regs: GenRegisters); assembler;
asm
  push ds

  mov ax, IntrSelector
  mov ds, ax
  lea di, @@IntrCall
  mov al, IntNo
  mov [di+1], al

  lds si, Regs                     {set up the registers from the}
  mov ax, [si].GenRegisters.&SI    {  GenRegisters structure }
  push ax
  mov ax, [si].GenRegisters.&DS
  or ax, ax
  jnz @@SetDS
  mov ax, ds

  @@SetDS:
  push ax
  mov di, [si].GenRegisters.&DI
  mov bp, [si].GenRegisters.&BP
  mov bx, [si].GenRegisters.&BX
  mov dx, [si].GenRegisters.&DX
  mov cx, [si].GenRegisters.&CX
  mov ax, [si].GenRegisters.&AX
  mov si, [si].GenRegisters.&ES
  or si, si
  jnz @@SetES
  mov si, es

  @@SetES:
  mov es, si
  pop ds
  pop si

  @@IntrCall:
  int 0                          {do the interrupt}

  push ds                        {get ready for setting the}
  pushf                          {  GenRegisters structure}
  push bp
  push si
  mov bp, sp                     {restore our stack frame}
  add bp, 10
  lds si, Regs                   {set up the GenRegisters structure}
  mov [si].GenRegisters.&DI, di
  mov [si].GenRegisters.&BX, bx
  mov [si].GenRegisters.&DX, dx
  mov [si].GenRegisters.&CX, cx
  mov [si].GenRegisters.&AX, ax
  mov [si].GenRegisters.&ES, es
  pop ax
  mov [si].GenRegisters.&SI, ax
  pop ax
  mov [si].GenRegisters.&BP, ax
  pop ax
  mov [si].GenRegisters.&Flags, ax
  pop ax
  mov [si].GenRegisters.&DS, ax

  pop ds
  mov ax, IntrSelector
  mov es, ax
  lea di, @@IntrCall
  xor al, al
  mov es:[di+1], al
end;

procedure MsDos(var Regs: GenRegisters);
begin
  Intr($21, Regs);
end;

function DosVersion: Word; assembler;
asm
  mov ax, $3000
  int $21
end;

procedure GetIntVec(IntNo: Byte; var Vector: Pointer); assembler;
asm
  mov ah, $35
  mov al, IntNo
  int $21
  mov ax, es
  les di, Vector
  mov es:[di], bx
  mov es:[di+2], ax
end;

procedure SetIntVec(IntNo: Byte; Vector: Pointer); assembler;
asm
  push ds
  mov ah, $25
  mov al, IntNo
  lds dx, Vector
  int $21
  pop ds
end;

procedure GetDate(var Year, Month, Day, DayOfWeek: Word);
begin
  DecodeDate(Date, Year, Month, Day);
  DayOfWeek := SysUtils.DayOfWeek(Date);
end;

procedure GetTime(var Hour, Minute, Second, Sec100: Word);
begin
  DecodeTime(Time, Hour, Minute, Second, Sec100);
end;

procedure DoneDosSupp; far;
var
  Dummy : word;
begin
  if (IntrSelector <> 0) then
    Dummy := FreeSelector(IntrSelector);
end;

initialization
  IntrSelector := AllocSelector(CSeg);
  PrestoChangoSelector(CSeg, IntrSelector);
  AddExitProc(DoneDosSupp);
end.
