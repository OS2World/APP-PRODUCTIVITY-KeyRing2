{*********************************************************}
{*                   WINDPMI.PAS 1.00                    *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}
  {$F-,V-,B-,S-,I-,R-}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}

{$IFNDEF DPMIOrWnd}
  ** Error ** This file is for TPW or DPMI only
{$ENDIF}

unit WinDPMI;
  {DPMI services}

interface

uses
  {$IFDEF Windows}
  WinTypes,
  WinProcs,
  WinDos;
  {$ELSE}
  Dos,
  WinApi;
  {$ENDIF}

type
  SegOfs =                   {structure of a pointer}
   record
      Ofst, Segm : Word;
    end;
  DoubleWord       = record
                       LoWord  : Word;
                       HiWord  : Word;
                     end;
  DPMIRegisters =
    record
      DI : LongInt;
      SI : LongInt;
      BP : LongInt;
      Reserved : LongInt;
      BX : LongInt;
      DX : LongInt;
      CX : LongInt;
      AX : LongInt;
      Flags : Word;
      ES : Word;
      DS : Word;
      FS : Word;
      GS : Word;
      IP : Word;
      CS : Word;
      SP : Word;
      SS : Word;
    end;

  {$IFNDEF Windows}
  TRegisters = Registers;
  {$ENDIF}

  TGetRealModeMem = function (Size : LongInt;
                              var RealPtr : Pointer;
                              var ProtectedPtr : Pointer) : Boolean;
    {-Gets real mode addressable memory (paragraph aligned) and returns both
      a pointer for real and protected mode. Returns True if successful. Size
      is the number of bytes to allocate.}

  TFreeRealModeMem = procedure (ProtectedPtr : Pointer);
    {-Free memory previously allocated with GetRealModeMem.}

var
  IntrProc : Pointer;

procedure WinIntr(IntNo : Byte; var Regs);
  Inline($FF/$1E/>INTRPROC);    {call dword ptr \[\>IntrProc\]}

function InRealMode : Boolean;
function CallFarRealModeProc(StackWords : Word;
                             var Regs : DPMIRegisters) : Word;
function SimulateRealModeInt(IntNo : Byte; StackWords : Word;
                             var Regs : DPMIRegisters) : Word;
procedure GetRealModeIntVector(IntNo : Byte; var Vector : Pointer);
function AllocDosMem(SizeInParas : Word;
                     var RealModeSeg : Word;
                     var ProtModeSel : Word) : Word;
function FreeDosMem(ProtModeSel : Word) : Word;
function AllocLDTDescriptors(NumOfDesc : Word; var BaseSelector : Word) : Word;
function SetSegmentBaseAddr(Selector : Word; LinearBase : LongInt) : Word;
function SetSegmentLimit(Selector : Word; Limit : LongInt) : Word;
function GetSelectorIncrement : Word;
function FreeLDTDescriptor(Selector : Word) : Word;
procedure AllocateRealModeCallbackAddr(CallbackProc : Pointer;
                                      var Regs : DPMIRegisters;
                                      var Callback : Pointer);
function FreeRealModeCallbackAddr(P : Pointer) : Word;
procedure GetProtectedModeInt(IntNo : Byte; var Handler : Pointer);
function SetProtectedModeInt(IntNo : Byte; Handler : Pointer) : Word;

function GetSelectorForRealMem(RealPtr : Pointer; Size : LongInt; var Selector : Word) : Word;
function GetCPUFlags : Byte;
function Linear(P : Pointer) : LongInt;

function DefGetRealModeMem(Size : LongInt;
                           var RealPtr : Pointer;
                           var ProtectedPtr : Pointer) : Boolean;
  {-Gets real mode addressable memory (paragraph aligned) and returns both a
    pointer for real and protected mode. Returns True if successful. Size is
    the number of bytes to allocate.}

procedure DefFreeRealModeMem(ProtectedPtr : Pointer);
  {-Free memory previously allocated with GetRealModeMem.}

const
  GetRealModeMem : TGetRealModeMem = DefGetRealModeMem;
  FreeRealModeMem : TFreeRealModeMem = DefFreeRealModeMem;

implementation

  function Linear(P : Pointer) : LongInt;
    {-Converts a pointer to a linear address to allow differences in addresses
      to be calculated. The pointer must be in the range $0:$0 to $FFFF:$000F.}
  begin
    with SegOfs(P) do
      Linear := (LongInt(Segm) shl 4)+LongInt(Ofst);
  end;

  function CallFarRealModeProc(StackWords : Word;
                               var Regs : DPMIRegisters) : Word; Assembler;
  asm
    xor     bx,bx
    mov     cx,StackWords
    les     di,Regs
    mov     ax,0301h
    int     31h
    jc      @@ExitPoint
    xor     ax,ax
  @@ExitPoint:
  end;

  function SimulateRealModeInt(IntNo : Byte; StackWords : Word;
                               var Regs : DPMIRegisters) : Word; Assembler;
  asm
    xor     bx,bx
    mov     bl,IntNo
    mov     cx,StackWords
    les     di,Regs
    mov     ax,0300h
    int     31h
    jc      @@ExitPoint
    xor     ax,ax
  @@ExitPoint:
  end;

  procedure GetRealModeIntVector(IntNo : Byte; var Vector : Pointer); Assembler;
  asm
    mov     ax,0200h
    mov     bl,IntNo
    int     31h
    les     di,Vector
    mov     word ptr es:[di],dx
    mov     word ptr es:[di+2],cx
  end;

  function GetCPUFlags : Byte; Assembler;
  asm
    lahf
    mov     al,ah
  end;

  function InRealMode : Boolean;
  begin
    {$IFDEF Windows}
    InRealMode := GetWinFlags and wf_PMode = 0;
    {$ELSE}
      {$IFDEF DPMI}
      InRealMode := False;
      {$ELSE}
      InRealMode := True;
      {$ENDIF}
    {$ENDIF}
  end;

  function AllocDosMem(SizeInParas : Word;
                       var RealModeSeg : Word;
                       var ProtModeSel : Word) : Word; Assembler;
  asm
    mov     bx,SizeInParas
    mov     ax,0100h
    int     31h
    jc      @@ExitPoint
    les     di,RealModeSeg
    mov     es:[di],ax
    les     di,ProtModeSel
    mov     es:[di],dx
    xor     ax,ax
  @@ExitPoint:
  end;

  function FreeDosMem(ProtModeSel : Word) : Word; Assembler;
  asm
    mov     ax,0101h
    mov     dx,ProtModeSel
    int     31h
    jc      @@ExitPoint
    xor     ax,ax
  @@ExitPoint:
  end;

  function AllocLDTDescriptors(NumOfDesc : Word; var BaseSelector : Word) : Word; Assembler;
  asm
    mov     cx,NumOfDesc
    xor     ax,ax
    int     31h
    jc      @@ExitPoint
    les     di,BaseSelector
    mov     es:[di],ax
    xor     ax,ax
  @@ExitPoint:
  end;

  function SetSegmentBaseAddr(Selector : Word; LinearBase : LongInt) : Word; Assembler;
  asm
    mov     bx,Selector
    mov     dx,word ptr LinearBase
    mov     cx,word ptr LinearBase+2
    mov     ax,0007h
    int     31h
    jc      @@ExitPoint
    xor     ax,ax
  @@ExitPoint:
  end;

  function SetSegmentLimit(Selector : Word; Limit : LongInt) : Word; Assembler;
  asm
    mov     bx,Selector
    mov     dx,word ptr Limit
    mov     cx,word ptr Limit+2
    mov     ax,0008h
    int     31h
    jc      @@ExitPoint
    xor     ax,ax
  @@ExitPoint:
  end;

  function FreeLDTDescriptor(Selector : Word) : Word; Assembler;
  asm
    mov     bx,Selector
    mov     ax,0001h
    int     31h
    jc      @@ExitPoint
    xor     ax,ax
  @@ExitPoint:
  end;

  function GetSelectorIncrement : Word; Assembler;
  asm
    mov     ax,0003h
    int     31h
  end;

  function GetSelectorForRealMem(RealPtr : Pointer; Size : LongInt; var Selector : Word) : Word;

    procedure FreeSele;
    begin
      if FreeLDTDescriptor(Selector) = 0 then ;  {!!.41}
    end;

  var
    ErrorCode : Word;

  begin
    ErrorCode := AllocLDTDescriptors(1, Selector);
    if ErrorCode = 0 then begin
      ErrorCode := SetSegmentBaseAddr(Selector, Linear(RealPtr));
      if ErrorCode = 0 then begin
        ErrorCode := SetSegmentLimit(Selector, Size);
        if ErrorCode <> 0 then
          FreeSele;
      end
      else
        FreeSele;
    end;
    GetSelectorForRealMem := ErrorCode;
  end;

  procedure AllocateRealModeCallbackAddr(CallbackProc : Pointer;
                                        var Regs : DPMIRegisters;
                                        var Callback : Pointer); Assembler;
  asm
    push    ds
    lds     si,CallbackProc
    les     di,Regs
    mov     ax,0303h
    int     31h
    jnc     @@Exitpoint
    xor     cx,cx
    xor     dx,dx
  @@ExitPoint:
    les     di,Callback
    mov     word ptr es:[di],dx
    mov     word ptr es:[di+2],cx
    pop     ds
  end;

  function FreeRealModeCallbackAddr(P : Pointer) : Word; Assembler;
  asm
    mov     cx,word ptr P+2
    mov     dx,word ptr P
    mov     ax,0304h
    int     31h
    jc      @@ExitPoint
    xor     ax,ax
  @@ExitPoint:
  end;

  procedure GetProtectedModeInt(IntNo : Byte; var Handler : Pointer); Assembler;
  asm
    mov     ax,0204h
    mov     bl,IntNo
    int     31h
    les     di,Handler
    mov     word ptr es:[di],dx
    mov     word ptr es:[di+2],cx
  end;

  function SetProtectedModeInt(IntNo : Byte; Handler : Pointer) : Word; Assembler;
  asm
    mov     bl,IntNo
    mov     dx,word ptr Handler
    mov     cx,word ptr Handler+2
    mov     ax,0205h
    int     31h
    jnc     @@ExitPoint
    xor     ax,ax
  @@ExitPoint:
  end;

  procedure DPMIIntr(IntNo : Byte; var Regs : TRegisters); Far;
    {-DPMI compliant call to an interrupt service}
  var
    DPMIRegs : DPMIRegisters;
  begin
    FillChar(DPMIRegs, SizeOf(DPMIRegs), 0);
    with DPMIRegs do begin
      AX := Regs.AX;
      BX := Regs.BX;
      CX := Regs.CX;
      DX := Regs.DX;
      BP := Regs.BP;
      SI := Regs.SI;
      DI := Regs.DI;
      DS := Regs.DS;
      ES := Regs.ES;
      Flags := GetCPUFlags;
    end;
    SimulateRealModeInt(IntNo, 0, DPMIRegs);
    with DPMIRegs do begin
      Regs.AX := AX;
      Regs.BX := BX;
      Regs.CX := CX;
      Regs.DX := DX;
      Regs.BP := BP;
      Regs.SI := SI;
      Regs.DI := DI;
      Regs.DS := DS;
      Regs.ES := ES;
      Regs.Flags := Flags;
    end;
  end;

  function DefGetRealModeMem(Size : LongInt;
                             var RealPtr : Pointer;
                             var ProtectedPtr : Pointer) : Boolean;
    {-Gets real mode addressable memory (paragraph aligned) and returns both a
      pointer for real and protected mode. Returns True if successful. Size is
      the number of bytes to allocate.}
  var
    L : LongInt;
  begin
    L := GlobalDosAlloc(Size);
    if L > 0 then begin
      RealPtr := Ptr(DoubleWord(L).HiWord, 0);
      ProtectedPtr := Ptr(DoubleWord(L).LoWord, 0);
      DefGetRealModeMem := True;
    end
    else
      DefGetRealModeMem := False;
  end;

  procedure DefFreeRealModeMem(ProtectedPtr : Pointer);
    {-Free memory previously allocated with GetRealModeMem.}
  begin
    GlobalDosFree(SegOfs(ProtectedPtr).Segm);
  end;

begin
  if InRealMode then
    {$IFDEF Windows}
    IntrProc := @WinDos.Intr
    {$ELSE}
    IntrProc := @Dos.Intr
    {$ENDIF}
  else
    IntrProc := @DPMIIntr;
end.

