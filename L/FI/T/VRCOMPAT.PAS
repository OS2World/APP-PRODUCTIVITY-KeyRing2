(**************************************************************)
(*     B-Tree Isam Compatibility Calls Ver 5.51               *)
(*   Copyright (C) 1987-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1992 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*    Modified and used under license by TurboPower Software  *)
(**************************************************************)

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}
  {$F-,V-,B-,S-,I-,R-}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}

Unit VRCompat;

Interface

Uses
  Filer,
  VRec;

var
  VRecBufSize : Word absolute IsamVRecBufSize;

type
  IsamAccessMode = (Normal, InSpiteOfLock, ReadOnly);

  Function CreateVariableRecBuffer ( IFBPtr : IsamFileBlockPtr ) : BOOLEAN;

  Procedure ReleaseVariableRecBuffer;

  Function SetVariableRecBuffer ( Size : Word ) : Boolean;

  Procedure AddVariableRec (     IFBPtr : IsamFileBlockPtr;
                             Var RefNr  : LongInt;
                             Var Source;
                                 Len    : Word);

  Procedure DeleteVariableRec ( IFBPtr : IsamFileBlockPtr;
                                RefNr  : LongInt );


  Procedure PutVariableRec (     IFBPtr : IsamFileBlockPtr;
                                 RefNr  : LongInt;
                             Var Source;
                                 Len    : Word;
                                 Mode : IsamAccessMode );

  Procedure GetVariableRecPart (     IFBPtr : IsamFileBlockPtr;
                                     RefNr  : LongInt;
                                 Var Dest;
                                 Var Len    : Word;
                                     Mode   : IsamAccessMode );

  Procedure GetVariableRec (     IFBPtr : IsamFileBlockPtr;
                                 RefNr  : LongInt;
                             Var Dest;
                             Var Len    : Word;
                                 Mode   : IsamAccessMode );

  Procedure GetVariableRecLength (     IFBPtr : IsamFileBlockPtr;
                                       RefNr  : LongInt;
                                   Var Len    : Word );

(*Procedure GetVariableRecRebuilt ( Var F       : IsamFile;
                                        DatSLen : Word;
                                    Var RefNr   : LongInt;
                                        OnlyLen : Boolean;
                                    Var Dest;
                                    Var Len     : Word );*)   {!!.50}

Implementation

  Function CreateVariableRecBuffer ( IFBPtr : IsamFileBlockPtr ) : Boolean;
  Begin
    CreateVariableRecBuffer := BTCreateVariableRecBuffer ( IFBPtr );
  End;

  Procedure ReleaseVariableRecBuffer;
  Begin
    BTReleaseVariableRecBuffer;
  End;

  Function SetVariableRecBuffer ( Size : Word ) : Boolean;
  Begin
    SetVariableRecBuffer := BTSetVariableRecBuffer ( Size );
  End;

  Procedure AddVariableRec (     IFBPtr : IsamFileBlockPtr;
                             Var RefNr  : LongInt;
                             Var Source;
                                 Len    : Word);
  Begin
    BTAddVariableRec ( IFBPtr, RefNr, Source, Len );
  End;

  Procedure DeleteVariableRec ( IFBPtr : IsamFileBlockPtr;
                                RefNr  : LongInt );
  Begin
    BTDeleteVariableRec ( IFBPtr, RefNr );
  End;


  Procedure PutVariableRec (     IFBPtr : IsamFileBlockPtr;
                                 RefNr  : LongInt;
                             Var Source;
                                 Len    : Word;
                                 Mode : IsamAccessMode );
  Begin
    BTPutVariableRec ( IFBPtr, RefNr, Source, Len );
  End;

  Procedure GetVariableRecPart (     IFBPtr : IsamFileBlockPtr;
                                     RefNr  : LongInt;
                                 Var Dest;
                                 Var Len    : Word;
                                     Mode   : IsamAccessMode );
  Begin
    BTGetVariableRecPart ( IFBPtr, RefNr, Dest, Len );
  End;

  Procedure GetVariableRec (     IFBPtr : IsamFileBlockPtr;
                                 RefNr  : LongInt;
                             Var Dest;
                             Var Len    : Word;
                                 Mode   : IsamAccessMode );
  Begin
    BTGetVariableRec ( IFBPtr, RefNr, Dest, Len );
  End;

  Procedure GetVariableRecLength (     IFBPtr : IsamFileBlockPtr;
                                       RefNr  : LongInt;
                                   Var Len    : Word );
  Begin
    BTGetVariableRecLength ( IFBPtr, RefNr, Len );
  End;

(*Procedure GetVariableRecRebuilt ( Var F       : IsamFile;
                                        DatSLen : Word;
                                    Var RefNr   : LongInt;
                                        OnlyLen : Boolean;
                                    Var Dest;
                                    Var Len     : Word );
  Begin
    BTGetVariableRecRebuilt ( F, DatSLen, RefNr, OnlyLen, Dest, Len, $FFFF );
  End;
*) {!!.50}

Begin
  VRecBufSize := 0;
End.
