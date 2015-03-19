(**************************************************************)
(*         B-Tree Isam EMS Support Ver 5.51                   *)
(*   Copyright (C) 1989-1991 Dipl.Math. Ralf Nagel            *)
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


Unit EMSSupp;

Interface

Uses
  BaseSupp;

Const
  EMSErrorCode = $0FFFF;


  Function AllocateEMSPages ( NrOfPages : Word ) : Word;

  Function DeAllocateEMSHandle ( Handle : Word ) : Boolean;

  Function EMSInstalled : Boolean;

{$IFNDEF DPMIOrWnd}
  Function EmmSigFound : Boolean;
{$ENDIF}

  Function EMSVersion : Byte;

  Function EMSPageFramePtr : Pointer;

  Function EMSPagesAvail : Word;

  Function MapEMSPage ( Handle, LogPage : Word; PhysPage : Byte ): Boolean;
      Inline (
    $58 / $5B / $5A /             {pop ax, bx, dx}
    $B4 / $44 /                   {mov ah, $44 = mappage}
    $CD / $67 /                   {int $67 = ems}
    $08 / $E4 /                   {or ah, ah}
    $B8 / $01 / $00 /             {mov ax, $01}
    $74 / $01 /                   {jz ok}
    $48 );                        {dec ax}
   {ok:}

  Function SaveEmsContext ( Handle : Word ) : Boolean; Inline (
    $5A /                         {pop dx}
    $B4 / $47 /                   {mov ah, $47 = savecont}
    $CD / $67 /                   {int $67 = ems}
    $08 / $E4 /                   {or ah, ah}
    $B8 / $01 / $00 /             {mov ax, $01}
    $74 / $01 /                   {jz ok}
    $48 );                        {dec ax}
   {ok:}

  Function RestoreEmsContext ( Handle : Word ) : Boolean; Inline (
    $5A /                         {pop dx}
    $B4 / $48 /                   {mov ah, $47 = restcont}
    $CD / $67 /                   {int $67 = ems}
    $08 / $E4 /                   {or ah, ah}
    $B8 / $01 / $00 /             {mov ax, $01}
    $74 / $01 /                   {jz ok}
    $48 );                        {dec ax}
   {ok:}


Implementation

Const
  EMSInterrupt = $67;
  DPMIInterrupt = $31;


  Function AllocateEMSPages ( NrOfPages : Word ) : Word;

  Var
    EMSRegs : GenRegisters;

  Begin
    DefaultRegisters ( EMSRegs  );
    With EMSRegs Do Begin
      AH := $43;
      BX := NrOfPages;
      CallIntr ( EMSInterrupt, EMSRegs );
      If AH = 0 Then Begin
        AllocateEMSPages := DX;
      End Else Begin
        AllocateEMSPages := EMSErrorCode;
      End;
    End;
  End;


  Function DeAllocateEMSHandle ( Handle : Word ) : Boolean;

  Var
    EMSRegs : GenRegisters;

  Begin
    DefaultRegisters ( EMSRegs  );
    With EMSRegs Do Begin
      AH := $45;
      DX := Handle;
      CallIntr ( EMSInterrupt, EMSRegs );
      DeAllocateEMSHandle := AH = 0;
    End;
  End;


  Function EMSInstalled : Boolean;

  Var
    F     : File;
    Dummy : Integer;

  Begin
    EmsInstalled := False;
    Assign ( F, 'EMMXXXX0' );
    Reset ( F );
    If IOResult = 0 Then Begin
      EmsInstalled := True;
      Close ( F );
      Dummy := IOResult;
    End;
  End;


{$IFNDEF DPMIOrWnd}
  Function EmmSigFound : Boolean;

  Type
    NameArr = Array [1..8] Of Char;

  Const
    EMMName : NameArr = 'EMMXXXX0';

  Var
    EMMIntPtr : Pointer Absolute $0000:$019C;

  Begin
    If EMMIntPtr = Nil Then Begin
      EmmSigFound := False;
    End Else Begin
      EmmSigFound := EMMName = NameArr (Ptr ( Seg (EMMIntPtr^), $0A )^);
    End;
  End;
{$ENDIF}


  Function EMSVersion : Byte;

  Var
    EMSRegs : GenRegisters;

  Begin
    DefaultRegisters ( EMSRegs  );
    With EMSRegs Do Begin
      AH := $46;
      CallIntr ( EMSInterrupt, EMSRegs );
      If AH = 0 Then Begin
        EMSVersion := AL;
      End Else Begin
        EMSVersion := 0;
      End;
    End;
  End;


  Function EMSPageFramePtr : Pointer;

  Var
    EMSRegs : GenRegisters;

  Begin
    DefaultRegisters ( EMSRegs  );
    With EMSRegs Do Begin
      AH := $41;
      CallIntr ( EMSInterrupt, EMSRegs );
      If AH = 0 Then Begin
        EMSPageFramePtr := Ptr ( BX, 0 );
      End Else Begin
        EMSPageFramePtr := Nil;
      End;
    End;
  End;


  Function EMSPagesAvail : Word;

  Var
    EMSRegs : GenRegisters;

  Begin
    DefaultRegisters ( EMSRegs  );
    With EMSRegs Do Begin
      AH := $42;
      CallIntr ( EMSInterrupt, EMSRegs );
      If AH = 0 Then Begin
        EMSPagesAvail := BX;
      End Else Begin
        EMSPagesAvail := EMSErrorCode;
      End;
    End;
  End;


{$IFDEF InitAllUnits}
Begin
{$ENDIF}
End.
