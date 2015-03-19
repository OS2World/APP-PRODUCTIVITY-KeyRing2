(**************************************************************)
(*     B-Tree Isam ReX Utilities DLL Call Hooks               *)
(*      C-BTree Isam Ver 3.5 Pascal Interface                 *)
(*   Copyright (C) 1988-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}
  {$F-,V-,B-,S-,I-,R-,A-}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}
  {$IFDEF DPMI}
    {$K+}
  {$ENDIF}


Unit ReXCHook;

Interface

Uses
{$IFDEF Windows}
  WinTypes,
  WinProcs,
{$ENDIF}
  Filer;     {!!.TP}

  Var
    CHBuildKeyUserProcInst,
    CHReXUserProcInst,
    CHChangeDatsProcInst,
    CHVChangeDatsProcInst  : Pointer;


Implementation

  Type
    BuildKeyFunc = Function ( Var DatS;
                                  KeyNr : Word ) : IsamKeyStr;

    ReXUserProc = Procedure (     KeyNr   : Word;
                                  DatSNrR : LongInt;
                                  DatSNrW : LongInt;
                              Var DatS;
                                  Len     : Word );

    ChangeDatSFunc = Function ( Var DatSOld;
                                Var DatSNew;
                                    Len      : Word ) : Boolean;

    VChangeDatSFunc = Function ( Var DatSOld;
                                 Var DatSNew;
                                 Var Len      : Word ) : Boolean;

  Procedure CallHookBuildKey ( Var DatS;
                                   KeyNr    : Word;
                               Var KeyStr   : IsamKeyStr;
                                   HookFunc : Pointer ); Export;

  Begin
    KeyStr := BuildKeyFunc (HookFunc) ( DatS, KeyNr );
    {!!!If Not IsamOK Then IsamError := -1;}
  End;


  Procedure CallHookReXUser (     KeyNr    : Word;
                                  DatSNrR  : LongInt;
                                  DatSNrW  : LongInt;
                              Var DatS;
                                  Len      : Word;
                                  HookProc : Pointer ); Export;

  Begin
    If HookProc <> Nil Then Begin
      ReXUserProc (HookProc) ( KeyNr, DatSNrR, DatSNrW, DatS, Len );
      If Not IsamOK Then IsamError := -1;
    End;
  End;


  Function CallHookChangeDatS ( Var DatSOld;
                                Var DatSNew;
                                Var Len      : Word;
                                    HookFunc : Pointer ) : Boolean; Export;

  Begin
    CallHookChangeDatS := ChangeDatSFunc (HookFunc) ( DatSOld, DatSNew,
        Len );
  End;


  Function CallHookVChangeDatS ( Var DatSOld;
                                 Var DatSNew;
                                 Var Len      : Word;
                                     HookFunc : Pointer ) : Boolean; Export;

  Begin
    CallHookVChangeDatS := VChangeDatSFunc (HookFunc) ( DatSOld, DatSNew,
        Len );
  End;



  Var
    SaveExitProc : Pointer;

  Procedure ReXCHookExitProc; Far;

  Begin
    ExitProc := SaveExitProc;
  {$IFDEF Windows}
    FreeProcInstance ( CHBuildKeyUserProcInst );
    FreeProcInstance ( CHReXUserProcInst );
    FreeProcInstance ( CHChangeDatsProcInst );
    FreeProcInstance ( CHVChangeDatsProcInst );
  {$ENDIF}
  End;


  Procedure ReXCHookEntryProc;

  Begin
  {$IFDEF Windows}
    CHBuildKeyUserProcInst := MakeProcInstance ( @CallHookBuildKey,
        HInstance );
    CHReXUserProcInst := MakeProcInstance ( @CallHookReXUser,
        HInstance );
    CHChangeDatsProcInst := MakeProcInstance ( @CallHookChangeDatS,
        HInstance );
    CHVChangeDatsProcInst := MakeProcInstance ( @CallHookVChangeDatS,
        HInstance );
  {$ELSE}
    CHBuildKeyUserProcInst := @CallHookBuildKey;
    CHReXUserProcInst := @CallHookReXUser;
    CHChangeDatsProcInst := @CallHookChangeDatS;
    CHVChangeDatsProcInst := @CallHookVChangeDatS;
  {$ENDIF}

    SaveExitProc := ExitProc;
    ExitProc := @ReXCHookExitProc;
  End;


Begin
  ReXCHookEntryProc;
End.
