(**************************************************************)
(*     B-Tree Isam dBASE III & IV Import / Export Ver 5.51    *)
(*   Copyright (C) 1986-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}

{$IFDEF UseFilerDLL}
  {$IFDEF UseSymFlex}
    {$I DDDefine.Inc}
  {$ENDIF}
  {$F-,V-,B-,S-,I-,R-,X+,A-,N+}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}
  {$IFDEF DPMI}
    {$K+}
  {$ENDIF}
{$ELSE}
  {$IFDEF UseSymFlex}
    {$I DDDefine.Inc}
  {$ENDIF}
  {$F-,V-,B-,S-,I-,R-}
  {$IFDEF CanAllowOverlays}
    {$O+,F+}
  {$ENDIF}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}
{$ENDIF}

Unit
  DBImpExp;

{$IFDEF UseFilerDLL}
  {$I DBIMPEXP.PDL}
{$ELSE}
  {$I DBIMPEXP.PSL}
{$ENDIF}


{$IFDEF UseFilerDLL}
Begin
  DBaseEntryProc;
{$ELSE}
Begin
  ProcErrorHandler := NoErrorHandler;                              {!!.42}
{$ENDIF}
End.
