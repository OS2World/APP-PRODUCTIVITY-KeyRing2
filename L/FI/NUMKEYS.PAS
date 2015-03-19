{*********************************************************}
{*                   NUMKEYS.PAS 5.51                    *}
{*     Copyright (c) TurboPower Software 1989, 1994.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}

{$IFDEF UseFilerDLL}
  {$F-,V-,B-,S-,I-,R-,X+,A-,N+}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}
  {$IFDEF UseSymFlex}
    {$N+}
  {$ENDIF}
{$ELSE}
  {$F-,V-,B-,S-,I-,R-}
  {$IFDEF CanAllowOverlays}
    {$F+,O+,A-}
  {$ENDIF}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}
  {$IFDEF UseSymFlex}
    {$N+}
  {$ENDIF}
{$ENDIF}

Unit
  Numkeys;

{$IFDEF UseFilerDLL}
  {$I NUMKEYS.PDL}
{$ELSE}
  {$I NUMKEYS.PSL}
{$ENDIF}


{$IFDEF UseFilerDLL}
{$ELSE}
{$IFDEF InitAllUnits}
Begin
{$ENDIF}
{$ENDIF}
End.
