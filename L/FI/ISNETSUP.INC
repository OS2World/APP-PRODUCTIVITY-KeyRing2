(**************************************************************)
(*          B-Tree Isam Include Ver 5.51                      *)
(*   Copyright (C) 1987-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

{$IFNDEF DPMIOrWnd}
  Type
    IsamINT24HandlerDef = Record
      PushAXBX,
      PushCXDX,
      PushBPSI,
      PushDIDS,
      PushESF        : Word;
      AndDIFF1       : LongInt;
      CmpDI02        : LongInt;
      Jz1DoOldINT    : Word;                               {!!.41 mod}
      CmpDI09        : LongInt;                            {!!.41}
      Jz2DoOldINT    : Word;                               {!!.41}
      MovAHExtErr    : Word;
      NopMovBX       : Word;
      Level          : Word;
      Int21          : Word;
      JcDoOldINT     : Word;
      CmpBH, LockNop : Word;
      JzMyTurn       : Word;
      Cmp1BH         : Word;
      InterLockNop   : Word;
      Jz1MyTurn      : Word;
  { DoOldINT : }
      PopFES1,
      PopDSDI1,
      PopSIBP1,
      PopDXCX1,
      PopBXAX1       : Word;
      NopJmpFar      : Word;
      OldINT24Addr   : Pointer;
  { MyTurn : }
      NopMovAX       : Word;
      SegLockError   : Word;
      MovDSAX        : Word;
      MovByte        : Word;
      OfsLockError   : Word;
      ConstTrueNop   : Word;
      PopFES2,
      PopDSDI2,
      PopSIBP2,
      PopDXCX2,
      PopBXAX2       : Word;
      MovALFail      : Word;
      IRetNop        : Word;
    End;

  Const
    IsamINT24Handler : IsamINT24HandlerDef = (
      PushAXBX : $5350;
      PushCXDX : $5251;
      PushBPSI : $5655;
      PushDIDS : $1E57;
      PushESF : $9C06;
      AndDIFF1 : $00FFE781;
      CmpDI02 : $0002FF81;                                 
      Jz1DoOldINT : $1674;                                 {!!.41 mod}
      CmpDI09 : $0009FF81;                                 {!!.41}
      Jz2DoOldINT : $1074;                                 {!!.41}
      MovAHExtErr: $59B4;
      NopMovBX : $BB90;
      Level : $0000;
      Int21 : $21CD;
      JcDoOldINT : $0672;
      CmpBH : $FF80;
      LockNop : $9002;
      JzMyTurn : $1674;
      Cmp1BH : $FF80;
      InterLockNop : $900A;
      Jz1MyTurn : $1074;

      PopFES1 : $079D;
      PopDSDI1 : $5F1F;
      PopSIBP1 : $5D5E;
      PopDXCX1 : $595A;
      PopBXAX1 : $585B;
      NopJmpFar : $EA90;
      OldINT24Addr : Nil;

      NopMovAX : $B890;
      SegLockError : $FFFF;
      MovDSAX : $D88E;
      MovByte : $06C6;
      OfsLockError : $FFFF;
      ConstTrueNop : $9000;
      PopFES2 : $079D;
      PopDSDI2 : $5F1F;
      PopSIBP2 : $5D5E;
      PopDXCX2 : $595A;
      PopBXAX2 : $585B;
      MovALFail : $03B0;
      IRetNop : $90CF);


  Procedure IsamInstallInt24Handler;

  Begin
    With IsamINT24Handler Do Begin
      CallGetIntVec ( $24, OldINT24Addr );
      SegLockError := Seg (IsamLockError);
      OfsLockError := Ofs (IsamLockError);
      ConstTrueNop := ConstTrueNop + Ord (True);
    End;
    CallSetIntVec ( $24, @ IsamINT24Handler );
  End;


  Procedure IsamRemoveInt24Handler;

  Begin
    CallSetIntVec ( $24, IsamINT24Handler.OldINT24Addr );
  End;
{$ENDIF}


(*****************************************************************************)

{--Start of NoNet definition}
{$IFDEF XXFPlusOptXX}
  {$UNDEF XXFPlusOptXX}
{$ENDIF}
{$IFOPT F+}
  {$DEFINE XXFPlusOptXX}
{$ENDIF}
{$F+}
  Function NoNetLockRecord  ( Start,
                              Len       : LongInt;
                              Handle,
                              TimeOut,
                              DelayTime : Word ) : Boolean;

  Begin
    NoNetLockRecord := True;
  End;


  Function NoNetUnLockRecord  ( Start,
                                Len    : LongInt;
                                Handle : Word ) : Boolean;

  Begin
    NoNetUnLockRecord := True;
  End;


  Function NoNetExitNet : Boolean;

  Begin
  {$IFNDEF DPMIOrWnd}
    IsamRemoveInt24Handler;
  {$ENDIF}
    NoNetExitNet := True;
  End;
{$IFNDEF XXFPlusOptXX}
  {$F-}
{$ELSE}
  {$UNDEF XXFPlusOptXX}
{$ENDIF}


  Function NoNetInitNet : Boolean;

  Begin
    IsamDefNrOfWS := 0;
  {$IFNDEF DPMIOrWnd}
    IsamInstallInt24Handler;
  {$ENDIF}
    IsamLockRecord := NoNetLockRecord;
    IsamUnLockRecord := NoNetUnLockRecord;
    IsamExitNet := NoNetExitNet;
    NoNetInitNet := True;
  End;


{--NoNet definition finished}

(*****************************************************************************)

{$IFDEF Novell}

{$IFDEF SupportVLM} {!!.TP}
function NovellLockRecord(Start,
                          Len       : LongInt;
                          Handle,
                          TimeOut,
                          DelayTime : Word ) : Boolean; far;
  var
    Status : word;
    TimeCount : word;
  begin
    Status := nwLockRecord(Handle, Start, Len, TimeOut div 55); {!!.51}
    if ((Lo(Status) = $FF) and (TimeOut <> 0)) then
      begin
        {-Call has failed without waiting for timeout; this occurs only
          if a region is attempted to be locked which is already locked
          by another task of the same machine; so give preemptive
          multitasking a chance by reapeating the call with delays.}
        TimeCount := DelayTime;
        while (Status <> 0) and (TimeCount < TimeOut) do
          begin
            Status := nwLockRecord(Handle, Start, Len, 0);
            inc(TimeCount, DelayTime);
            if (Status <> 0) and (TimeCount < TimeOut) then
              IsamDelay(DelayTime);
          end;
      end;
    if (Status <> 0) and (IsamDOSError = 0) then
      begin
        if (nwShellType = nsVLM) then
             IsamDOSFunc := $1A01
        else IsamDOSFunc := $BC01;
        IsamDOSError := Status;
      end;
    NovellLockRecord := (Status = 0);
  end;

function NovellUnLockRecord(Start,
                            Len    : LongInt;
                            Handle : Word ) : Boolean; far;
  var
    Status : word;
  begin
    Status := nwUnlockRecord(Handle, Start, Len);
    if (Status <> 0) then
      begin
        if (IsamDOSError = 0) then
          begin
            if (nwShellType = nsVLM) then
                 IsamDOSFunc := $1E00
            else IsamDOSFunc := $BE00;
            IsamDOSError := Status;
          end;
        NovellUnlockRecord := False;
      end
    else
      NovellUnlockRecord := True;
  end;

function NovellExitNet : Boolean; far;
  begin
    {$IFNDEF DPMIOrWnd}
    IsamRemoveInt24Handler;
    {$ENDIF}
    NovellExitNet := True;
  end;

{$ELSE}

{$IFDEF XXFPlusOptXX}
  {$UNDEF XXFPlusOptXX}
{$ENDIF}
{$IFOPT F+}
  {$DEFINE XXFPlusOptXX}
{$ENDIF}
{$F+}
  Function NovellLockRecord  ( Start,
                               Len       : LongInt;
                               Handle,
                               TimeOut,
                               DelayTime : Word ) : Boolean;
  Var
    IRR       : GenRegisters;
    TimeCount : Word;

  Begin
    DefaultRegisters ( IRR );                              {!!.41}
    With IRR Do Begin
      BX := Handle;
      CX := ILI (Start).Hi;
      DX := ILI (Start).Lo;
      SI := ILI (Len).Hi;
      DI := ILI (Len).Lo;
      BP := TimeOut Div 55;
      AH := $BC;
      AL := $01;
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
    {$IFDEF DPMI}
      CallDPMIRealModeIntr ( $21, IRR );
    {$ELSE}
      CallMsDos ( IRR );
    {$ENDIF}
      If IsamDOSError = 0 Then IsamDOSError := AL;
      If (AL = $FF) And (TimeOut <> 0) Then Begin
        {-Call is failed without waiting for timeout; this occurs only, if a
          region is attempted to be locked, which is already locked by
          another task of the same machine; so give preemptive multitasking
          a chance by reapeating the call with delays}
        TimeCount := DelayTime;
        While (AL <> 0) And (TimeCount < TimeOut) Do Begin
          DefaultRegisters ( IRR );                        {!!.41}
          BX := Handle;
          CX := ILI (Start).Hi;
          DX := ILI (Start).Lo;
          SI := ILI (Len).Hi;
          DI := ILI (Len).Lo;
          BP := 0;
            {-No timeout; it doesn't work anyway}
          AH := $BC;
          AL := $01;
          If IsamDOSError = 0 Then IsamDOSFunc := AX;
        {$IFDEF DPMI}
          CallDPMIRealModeIntr ( $21, IRR );
        {$ELSE}
          CallMsDos ( IRR );
        {$ENDIF}
          If IsamDOSError = 0 Then IsamDOSError := AX;
          Inc (TimeCount, DelayTime);
          If (AL <> 0) And (TimeCount < TimeOut) Then Begin
            IsamDelay ( DelayTime );
          End;
        End;
      End;
      NovellLockRecord := AL = 0;
    End;
  End;

  Function NovellUnLockRecord  ( Start,
                                 Len    : LongInt;
                                 Handle : Word ) : Boolean;

  Var
    IRR : GenRegisters;

  Begin
    DefaultRegisters ( IRR );                                {!!.41}
    With IRR Do Begin
      BX := Handle;
      CX := ILI (Start).Hi;
      DX := ILI (Start).Lo;
      SI := ILI (Len).Hi;                                    {!!.41}
      DI := ILI (Len).Lo;                                    {!!.41}
      AX := $BE00;
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
    {$IFDEF DPMI}
      CallDPMIRealModeIntr ( $21, IRR );
    {$ELSE}
      CallMsDos ( IRR );
    {$ENDIF}
      If IsamDOSError = 0 Then IsamDOSError := AL;
      NovellUnLockRecord := AL = 0;
    End;
  End;


  Function NovellExitNet : Boolean;

  Begin
  {$IFNDEF DPMIOrWnd}
    IsamRemoveInt24Handler;
  {$ENDIF}
    NovellExitNet := True;
  End;
{$IFNDEF XXFPlusOptXX}
  {$F-}
{$ELSE}
  {$UNDEF XXFPlusOptXX}
{$ENDIF}

{$ENDIF}

  Function NovellInitNet : Boolean;

    Function NovellInstalled : Boolean;                        {!!.41}

{$IFDEF SupportVLM} {!!.TP}
    begin
      NovellInstalled := (nwShellType <> nsNone);
    end;
{$ELSE}

      Function ServerInfoAvailable : Boolean;

      Type
        TRequestBuf = Record
          BufLen  : Word;
          SubFunc : Byte;
        End;

        TServerInfo = Record
          BufLen              : Word;
          ServerNameStartChar : Char;
          NotUsedSpace        : Array [1..127] Of Byte;
        End;

      Var
        RequestBufPtr : ^TRequestBuf;
        ServerInfoPtr : ^TServerInfo;
        IRR           : GenRegisters;
        RealModePtr,
        ProtModePtr   : Pointer;

      Begin
        ServerInfoAvailable := False;

        If Not CallAllocRealModeMem ( SizeOf (TRequestBuf)
            + SizeOf (TServerInfo), RealModePtr, ProtModePtr ) Then Exit;

        RequestBufPtr := ProtModePtr;
        ServerInfoPtr := ProtModePtr;
        Inc (Word (ServerInfoPtr), SizeOf (TRequestBuf));
        FillChar ( ServerInfoPtr^, SizeOf (TServerInfo), 0 );
        With RequestBufPtr^ Do Begin
          BufLen := 1;
          SubFunc := $11;
        End;

        ServerInfoPtr^.BufLen := SizeOf (TServerInfo) - 2;

        DefaultRegisters ( IRR );
        With IRR Do Begin
          AX := $E300;
          DS := LongInt (RealModePtr) Shr 16;
          SI := LongInt (RealModePtr) And $FFFF;
          ES := DS;
          DI := SI + SizeOf (TRequestBuf);
        End;
        CallDPMIRealModeIntr ( $21, IRR );

        ServerInfoAvailable := ServerInfoPtr^.ServerNameStartChar <> #0;

        CallFreeRealModeMem ( SizeOf (TRequestBuf)
            + SizeOf (TServerInfo), ProtModePtr );
      End;


    Begin
      NovellInstalled := ServerInfoAvailable;
    End;

{$ENDIF}

  Begin
    NovellInitNet := False;                                    {!!.41}
    If TestNetExistance Then Begin                             {!!.41}
      If Not NovellInstalled Then Exit;                        {!!.41}
    End;                                                       {!!.41}
    IsamDefNrOfWS := MaxNrOfWorkStations;
  {$IFNDEF DPMIOrWnd}
    IsamInstallInt24Handler;
  {$ENDIF}
    IsamLockRecord := NovellLockRecord;
    IsamUnLockRecord := NovellUnLockRecord;
    IsamExitNet := NovellExitNet;
    NovellInitNet := True;                                     {!!.41}
  End;

{$ENDIF}    {Novell definition finished}

(*****************************************************************************)

{$IFDEF MsNet}

{$IFDEF XXFPlusOptXX}
  {$UNDEF XXFPlusOptXX}
{$ENDIF}
{$IFOPT F+}
  {$DEFINE XXFPlusOptXX}
{$ENDIF}
{$F+}
  Function MsNetLockRecord  ( Start,
                              Len       : LongInt;
                              Handle,
                              TimeOut,
                              DelayTime : Word ) : Boolean;

  Var
    IRR       : GenRegisters;
    TimeCount : Word;
    OK        : Boolean;

  Begin
    DefaultRegisters ( IRR );
    TimeCount := 0;
    With IRR Do Begin
      Repeat
        Inc (TimeCount, DelayTime);
        AX := $5C00;
        BX := Handle;
        CX := ILI (Start).Hi;
        DX := ILI (Start).Lo;
        SI := ILI (Len).Hi;
        DI := ILI (Len).Lo;
        If IsamDOSError = 0 Then IsamDOSFunc := AX;
        CallMsDos (IRR);
        If Odd (Flags) And (IsamDOSError = 0) Then IsamDOSError := AX;
        OK := Not Odd (Flags);
        If Not OK And (TimeCount < TimeOut) Then Begin
          IsamDelay ( DelayTime );
        End;
      Until OK Or (TimeCount >= TimeOut);
      MsNetLockRecord := OK;
    End;
  End;


  Function MsNetUnLockRecord  ( Start,
                                Len    : LongInt;
                                Handle : Word ) : Boolean;

  Var
    IRR : GenRegisters;

  Begin
    DefaultRegisters ( IRR );
    With IRR Do Begin
      AX := $5C01;
      BX := Handle;
      CX := ILI (Start).Hi;
      DX := ILI (Start).Lo;
      SI := ILI (Len).Hi;
      DI := ILI (Len).Lo;
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos (IRR);
      If Odd (Flags) And (IsamDOSError = 0) Then IsamDOSError := AX;
      MsNetUnLockRecord := Not Odd (Flags);
    End;
  End;


  Function MsNetExitNet : Boolean;

  Begin
  {$IFNDEF DPMIOrWnd}
    IsamRemoveInt24Handler;
  {$ENDIF}
    MsNetExitNet := True;
  End;
{$IFNDEF XXFPlusOptXX}
  {$F-}
{$ELSE}
  {$UNDEF XXFPlusOptXX}
{$ENDIF}


  Function MsNetInitNet : Boolean;


    Function MSNetInstalled : Boolean;                         {!!.41}


      Function LockCallDefined : Boolean;

      Var
        IRR : GenRegisters;

      Begin
        LockCallDefined := False;
        If Swap (CallDosVersion) < $030A Then Exit;
          {-Call not allowed before version 3.1}
        DefaultRegisters ( IRR );
        With IRR Do Begin
          AX := $5C00;
          BX := 0;
            {-Use handle 0, so is in general not shareable}
          CX := 0;
          DX := 0;
            {-Start is 0}
          SI := 0;
          DI := 0;
            {-Length is 0, so is invalid}
          CallMsDos ( IRR );
          If Not Odd (Flags) Then Exit;
            {-Carry must be set because of parameters;
              if not, hands off and assume call failed}
          If AX = 1 Then Exit;
            {-If invalid function call then test failed}
        End;
        LockCallDefined := True;
      End;


      Function ADriveIsRemote : Boolean;


        Function DriveIsRemote ( Drive : Byte ) : Boolean;

        Var
          IRR : GenRegisters;

        Begin
          DriveIsRemote := False;
          If Swap (CallDosVersion) < $030A Then Exit;
            {-Call not allowed before version 3.1}
          DefaultRegisters ( IRR );
          With IRR Do Begin
            AX := $4409;
            BL := Drive;
            CallMsDos ( IRR );
            If Odd (Flags) Then Exit;
            If DX And $1000 = 0 Then Exit;
              {-The drive is remote if bit 12 of DX is set}
          End;
          DriveIsRemote := True;
        End;


      Var
        B : Byte;

      Begin
        ADriveIsRemote := True;
        For B := 1 To Succ (Ord ( 'Z' ) - Ord ( 'A' )) Do Begin
          If DriveIsRemote ( B ) Then Exit;
        End;
        ADriveIsRemote := False;
      End;


    Begin
      MSNetInstalled := False;
      If Not LockCallDefined Then Begin
        If Not ADriveIsRemote Then Exit;
      End;
      MSNetInstalled := True;
    End;


  Begin
    MsNetInitNet := False;
    If Not IsamSetDosRetry ( 1, 0 ) Then {Exit};               {!!.51}
    If TestNetExistance Then Begin                             {!!.41}
      If Not MSNetInstalled Then Exit;                         {!!.41}
    End;                                                       {!!.41}
    IsamDefNrOfWS := MaxNrOfWorkStations;
  {$IFNDEF DPMIOrWnd}
    IsamInstallInt24Handler;
  {$ENDIF}
    IsamLockRecord := MsNetLockRecord;
    IsamUnLockRecord := MsNetUnLockRecord;
    IsamExitNet := MsNetExitNet;
    MsNetInitNet := True;
  End;


{$ENDIF}    {MsNet definition finished}


  {--Additional net interfaces insert here}

(*****************************************************************************)
(*****************************************************************************)

  Function IsamInitNet ( ExpectedNet : NetSupportType ) : Boolean;

  Begin
    Case ExpectedNet Of
      NoNet :
        IsamInitNet := NoNetInitNet;

  {$IFDEF Novell}
      Novell :
        IsamInitNet := NovellInitNet;
  {$ENDIF}

  {$IFDEF MsNet}
      MsNet :
        IsamInitNet := MsNetInitNet;
  {$ENDIF}

      Else Begin
        IsamInitNet := False;
      End;
    End; {Case}
  End;
