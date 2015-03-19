(**************************************************************)
(*               B-Tree Isam Ver 5.51                         *)
(*   Copyright (C) 1986-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}

{$IFDEF UseFilerDLL}
  {$F-,V-,B-,S-,I-,R-,X+,A-,N+}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}
  {$IFDEF DPMI}
    {$K+}
  {$ENDIF}
{$ELSE}
  {$F-,V-,B-,S-,I-,R-}
  {$IFDEF DPMIOrWnd}                                                 {!!.42}
    {$X+}                                                            {!!.42}
  {$ENDIF}                                                           {!!.42}
  {$IFDEF CanAllowOverlays}
    {$O+,F+}
  {$ENDIF}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}
{$ENDIF}

Unit
  Filer;

{$IFDEF UseFilerDLL}
  {$I Filer.PDL}
{$ELSE}
  {$I Filer.PSL}
{$ENDIF}


{$IFDEF UseFilerDLL}
Begin
  IsamEntryProc;
{$ELSE}
Begin
  IsamDelay ( 0 );
    {-Initialization call with dummy parameter}
{$IFNDEF DPMIOrWnd}
  IsamInstallInt24DNRHandler;
{$ENDIF}
  IsamIsInitialized := False;
  IsamCompiledNets := []
{$IFDEF NoNet}
      + [NoNet]
{$ELSE}
  {$IFDEF Novell}
      + [Novell]
  {$ENDIF}
  {$IFDEF MsNet}
      + [MsNet]
  {$ENDIF}
{$ENDIF}
  ;
  SaveExitProc := ExitProc;
  ExitProc := @IsamExitProc;
{$ENDIF}
End.
