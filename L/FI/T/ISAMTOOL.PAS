(**************************************************************)
(*             B-Tree Isam Tools Ver 5.51                     *)
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

{--Definition of possible languages for error messages of IsamErrormessage }
{ $DEFINE GermanMessage}
{$DEFINE EnglishMessage}
  {-Adding a space before the $ sign of the DEFINE deactivates the error
    messages of this language}

Unit
  IsamTool;

{$IFDEF UseFilerDLL}
  {$I ISAMTOOL.PDL}
{$ELSE}
  {$I ISAMTOOL.PSL}
{$ENDIF}


{$IFDEF UseFilerDLL}
Begin
  UseErrorMessage :=
{$IFDEF EnglishMessage}
  English;
{$ELSE}
  {$IFDEF GermanMessage}
    German;
  {$ELSE}
    NoMsg;
  {$ENDIF}
{$ENDIF}
{$ELSE}
{$IFDEF InitAllUnits}
Begin
{$ENDIF}
{$ENDIF}
End.
