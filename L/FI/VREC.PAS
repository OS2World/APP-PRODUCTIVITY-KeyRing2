(**************************************************************)
(*               B-Tree Filer Ver 5.51                        *)
(*   Copyright (C) 1986-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}

{$IFDEF UseFilerDLL}
  {$F-,V-,B-,S-,I-,R-,A-,N+}
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
  VRec;

{$IFDEF UseFilerDLL}
  {$I VREC.PDL}
{$ELSE}
  {$I VREC.PSL}
{$ENDIF}

{$IFDEF UseFilerDLL}
{$ELSE}
Begin
  IsamVRecBufSize := 0;
{$ENDIF}
End.
