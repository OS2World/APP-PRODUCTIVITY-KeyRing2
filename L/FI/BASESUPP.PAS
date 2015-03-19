(**************************************************************)
(*         B-Tree Isam Base Support Ver 5.51                  *)
(*   Copyright (C) 1987-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
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


Unit BaseSupp;

InterFace

Uses
{$IFDEF Windows}
  WinProcs                                                  {!!.41}
 {$IFNDEF VER80}                                            {!!.51}
  , WinDos                                                  {!!.51}
 {$ENDIF};                                                  {!!.51}
{$ELSE}
 {$IFDEF DPMI}
  WinAPI,                                                   {!!.41}
 {$ENDIF}
  Dos;
{$ENDIF}

Type
  GenRegisters = Record
    Case Integer Of
      0: (AX, BX, CX, DX, BP, SI, DI, DS, ES, Flags: Word);
      1: (AL, AH, BL, BH, CL, CH, DL, DH: Byte);
  End;

Var
  AdrMsDos,
  AdrIntr,
  AdrDPMIRealModeIntr,
  AdrDosVersion,
  AdrSetIntVec,
  AdrGetIntVec,
  AdrGetTime,
  AdrGetDate    : Pointer;


  Procedure CallMsDos ( Var Regs : GenRegisters ); Inline
      ( $FF / $1E / AdrMsDos ); {call far dword ptr [AdrMsDos]}
    {-Call MsDos via AdrMsDos and allows to use type GenRegisters}


  Procedure CallIntr ( IntNo : Byte; Var Regs : GenRegisters ); Inline
      ( $FF / $1E / AdrIntr ); {call far dword ptr [AdrIntr]}
    {-Call Intr via AdrMsDos and allows to use type GenRegisters}


  Procedure CallDPMIRealModeIntr (     IntNo : Byte;
                                   Var Regs  : GenRegisters ); Inline
      ( $FF / $1E / AdrDPMIRealModeIntr );
        {-call far dword ptr [AdrDPMIRealModeIntr]}
    {-Call Intr via AdrDPMIRealModeIntr and allows to use type GenRegisters}


  Function CallDosVersion : Word; Inline
      ( $FF / $1E / AdrDosVersion ); {call far dword ptr [AdrDosVersion]}
    {-Call DosVersion via AdrDosVersion}


  Procedure CallSetIntVec ( IntNo : Byte; Vector : Pointer ); Inline
      ( $FF / $1E / AdrSetIntVec ); {call far dword ptr [AdrSetIntVec]}
    {-Call SetIntVec via AdrSetIntVec}


  Procedure CallGetIntVec ( IntNo : Byte; Var Vector : Pointer ); Inline
      ( $FF / $1E / AdrGetIntVec ); {call far dword ptr [AdrGetIntVec]}
    {-Call GetIntVec via AdrGetIntVec}


  Procedure CallGetTime ( Var Hour, Minute, Second, Sec100 : Word ); Inline
      ( $FF / $1E / AdrGetTime ); {call far dword ptr [AdrGetTime]}
    {-Call GetTime via AdrGetTime}


  Procedure CallGetDate ( Var Year, Month, Day, DayOfWeek : Word ); Inline
      ( $FF / $1E / AdrGetDate ); {call far dword ptr [AdrGetDate]}
    {-Call GetDate via AdrGetDate}


  Procedure DefaultRegisters ( Var Regs : GenRegisters );

  {DefaultZeroedRegisters deleted}                          {!!.41}

  Function CallAllocRealModeMem (     Size         : Word;  {!!.41}
                                  Var RealModePtr,
                                      ProtModePtr  : Pointer ) : Boolean;

  Procedure CallFreeRealModeMem ( Size        : Word;       {!!.41}
                                  ProtModePtr : Pointer );


Implementation

{$IFDEF VER80}                                                  {!!.51}
uses DosSupp;                                                   {!!.51}
{$ENDIF}                                                        {!!.51}

  Procedure DefaultRegisters ( Var Regs : GenRegisters );

  Begin
    FillChar ( Regs, SizeOf (Regs), 0 );
    Regs.DS := DSeg;
    Regs.ES := DSeg;
  End;


{$IFDEF DPMIOrWnd}                                          {!!.41}
  Procedure DPMIRealModeIntr ( IntNr : Byte; Var Regs : GenRegisters ); Far;

  Var
    DPMIRegs : Record
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
    End;

    DPMIError : Word;

  Begin
    DPMIError := 0;
    FillChar ( DPMIRegs, SizeOf (DPMIRegs), 0 );
    With DPMIRegs Do Begin
      AX := Regs.AX;
      BX := Regs.BX;
      CX := Regs.CX;
      DX := Regs.DX;
      BP := Regs.BP;
      SI := Regs.SI;
      DI := Regs.DI;
      DS := Regs.DS;
      ES := Regs.ES;
      Flags := Regs.Flags;
    End;

    Asm
      MOV     AX, 0300H
      MOV     BL, IntNr
      MOV     BH, 0
      MOV     CX, 0
      PUSH    SS
      POP     ES
      LEA     DI, [BP+OFFSET DPMIRegs]
      INT     31H
      JNC     @@EndPoint
      MOV     DPMIError, AX
    @@EndPoint:
    End;

    With DPMIRegs Do Begin
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
    End;
  End;
{$ENDIF}


  Function CallAllocRealModeMem (     Size         : Word;  {!!.41}
                                  Var RealModePtr,
                                      ProtModePtr  : Pointer ) : Boolean;

  Var
    L : LongInt;

  Begin
    CallAllocRealModeMem := False;

  {$IFDEF DPMIOrWnd}
    L := GlobalDosAlloc ( Size );
    If L <> 0 Then Begin                             {!!.51}
      RealModePtr := Ptr ( L Shr 16, 0);
      ProtModePtr := Ptr ( L And $FFFF, 0);
    End Else Begin
      Exit;
    End;
  {$ELSE}
    If MaxAvail < Size Then Exit;
    GetMem ( RealModePtr, Size );
    ProtModePtr := RealModePtr;
  {$ENDIF}

    CallAllocRealModeMem := True;
  End;


  Procedure CallFreeRealModeMem ( Size        : Word;       {!!.41}
                                  ProtModePtr : Pointer );

  Begin
  {$IFDEF DPMIOrWnd}
    If GlobalDosFree ( LongInt (ProtModePtr) Shr 16 ) = 0 Then;
  {$ELSE}
    FreeMem ( ProtModePtr, Size );
  {$ENDIF}
  End;



Begin
  AdrMsDos := @MsDos;
  AdrIntr := @Intr;
{$IFDEF DPMIOrWnd}                                          {!!.41}
  AdrDPMIRealModeIntr := @DPMIRealModeIntr;
{$ELSE}
  AdrDPMIRealModeIntr := @Intr;
{$ENDIF}
  AdrDosVersion := @DosVersion;
  AdrSetIntVec := @SetIntVec;
  AdrGetIntVec := @GetIntVec;
  AdrGetTime := @GetTime;
  AdrGetDate := @GetDate;
End.
