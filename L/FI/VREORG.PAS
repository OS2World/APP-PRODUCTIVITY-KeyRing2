(**************************************************************)
(*    B-Tree Isam Variable Records Reorg Ver 5.51             *)
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
{$ELSE}
  {$F-,V-,B-,S-,I-,R-}
  {$IFDEF CanAllowOverlays}
    {$O+,F+}
  {$ENDIF}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}
{$ENDIF}

Unit
  VReOrg;

{$IFDEF UseFilerDLL}
  {$I VREORG.PDL}
{$ELSE}
  {$I VREORG.PSL}
{$ENDIF}


{$IFDEF UseFilerDLL}
{$ELSE}
{$IFDEF InitAllUnits}
Begin
{$ENDIF}
{$ENDIF}
End.
