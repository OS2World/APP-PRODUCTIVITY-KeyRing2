(**************************************************************)
(*          B-Tree Isam Include Ver 5.51                      *)
(*   Copyright (C) 1986-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

  Procedure ISInitIsam;

  Begin
    IsamClearOK;
    IsamIsCriticalActive := False;
    IsamOFBLPtr := Nil;
    IsamForceFlushOfMark := False;
    IsamReXUserProcPtr := Nil;
    UserSaveEMSHandle := 0;
    If Swap (CallDosVersion) < $031E Then IsamFlushDOS33 := False;
      {-Set IsamFlushDOS33 to False if not DOS Version 3.3 or higher}
  End;


  Procedure IsamAddRec (     IFBPtr : IsamFileBlockPtr;
                         Var RefNr  : LongInt;
                         Var Source );

    Procedure AddRec1;

    Var
      IR           : IsamInfoRec;
      OldFirstFree : LongInt;

    Begin
      IsamSetDataBufferedFlag ( IFBPtr );
      If Not IsamOK Then Exit;
      With IFBPtr^ Do Begin
        If SaveFB Then IsamCopyInfoRecToIR ( IFBPtr, 0, IR );
        With DIDPtr^[0]^ Do Begin
          OldFirstFree := FirstFree;
          IsamNewRec ( IFBPtr, RefNr, 0 );
          If Not IsamOK Then Exit;
          If SaveFB Then Begin
            If IsamFirstFreeChanged ( IFBPtr, 0 ) Then Begin
              IsamSaveGivenInfoRec ( IFBPtr, 0, IR, FirstFree );
            End Else Begin
              IsamSaveGivenInfoRec ( IFBPtr, 0, IR, -2 );
              If Not IsamOK Then Dec (NumRec);
            End;
            If Not IsamOK Then Exit;
            If (NSP = Nil) Or IsamNetEmu
                Then IsamFlushDOSDia ( IFBPtr, False );
          End;
          IsamPutBlock ( DatF, RefNr * LenRec, LenRec, Source );
          If Not IsamOK Then Begin
            If IsamFirstFreeChanged (IFBPtr, 0) Then Begin
              FirstFree := OldFirstFree;
              Inc (NumberFree);
            End Else Begin
              Dec (NumRec);
            End;
            Exit;
          End;
        End;
        If SaveFB Then Begin
          If (NSP = Nil) Or IsamNetEmu Then Begin
            IsamFlushDOSDat ( IFBPtr );
          End Else Begin
            IsamPutInfoRec ( IFBPtr, 0, False );
          End;
        End;
      End;
    End;

  Begin
    IsamClearOK;
    AddRec1;
    If IFBPtr^.SaveFB Then Begin
      If IsamOK Then Begin
        IsamReduceDiaFile ( IFBPtr );
      End Else Begin
        IsamRepairFileBlock ( IFBPtr );
        If IsamOK Then Begin
          IsamOK := False;
          IsamError := 10001;
        End;
      End;
    End;
  End;


  Procedure IsamDeleteRec ( IFBPtr : IsamFileBlockPtr; RefNr : LongInt );

    Procedure DeleteRec1;

    Var
      IR : IsamInfoRec;

    Begin
      IsamSetDataBufferedFlag ( IFBPtr );
      If Not IsamOK Then Exit;
      With IFBPtr^ Do Begin
        If SaveFB Then Begin
          IsamCopyInfoRecToIR ( IFBPtr, 0, IR );
          If IsamFirstFreeChanged ( IFBPtr, 0 ) Then Begin
            IsamSaveGivenInfoRec ( IFBPtr, 0, IR, DIDPtr^[0]^.FirstFree );
          End Else Begin
            IsamSaveGivenInfoRec ( IFBPtr, 0, IR, -2 );
          End;
          If Not IsamOK Then Exit;
          If (NSP = Nil) Or IsamNetEmu Then IsamFlushDOSDia ( IFBPtr, False );
        End;
        IsamDeleteRecOrPage ( IFBPtr, RefNr, 0 );
        If Not IsamOK Then Exit;
        If SaveFB Then Begin
          If (NSP = Nil) Or IsamNetEmu Then Begin
            IsamFlushDOSDat ( IFBPtr );
          End Else Begin
            IsamPutInfoRec ( IFBPtr, 0, False );
          End;
        End;
      End;
    End;

  Begin
    IsamClearOK;
    If (RefNr <= 0) Or (RefNr > IFBPtr^.DIDPtr^[0]^.NumRec) Then Begin
      IsamOK := False;
      IsamError := 10135;
      Exit;
    End;
    DeleteRec1;
    If IFBPtr^.SaveFB Then Begin
      If IsamOK Then Begin
        IsamReduceDiaFile ( IFBPtr );
      End Else Begin
        IsamRepairFileBlock ( IFBPtr );
        If IsamOK Then Begin
          IsamOK := False;
          IsamError := 10002;
        End;
      End;
    End;
  End;


  Procedure IsamPutRec (     IFBPtr : IsamFileBlockPtr;              {!!.50}
                             RefNr  : LongInt;
                         Var Source );

  Begin
    If RefNr <> 0 Then Begin
      With IFBPtr^, DIDPtr^[0]^ Do Begin
        IsamPutBlock ( DatF, RefNr * LenRec, LenRec, Source );
        If IsamOK Then Begin
          If SaveFB And ( (NSP = Nil) Or IsamNetEmu ) Then Begin
            IsamOnlyFlushDOSDat ( IFBPtr );
          End;
        End;
      End;
    End Else Begin
      IsamOK := False;
      IsamError := 10130;
    End;
  End;


  Procedure IsamGetRec (     IFBPtr : IsamFileBlockPtr;              {!!.50}
                             RefNr  : LongInt;
                         Var Dest );

  Var
    RefPtr     : LongPtr;
    Dummy1Ptr,
    Dummy2Ptr  : IsamLockEntryRecPtr;
    IsToUnLock : Boolean;

  Begin
  {$IFDEF LockBeforeRead}
    IsToUnLock := False;
    With IFBPtr^, DIDPtr^[0]^ Do Begin
      If IsamOK And (NSP <> Nil) Then Begin
        IsamIsInLockList ( @IFBPtr^.NSP^.LockEntryRec, RefNr, RefPtr,
            False, Dummy1Ptr, Dummy2Ptr );                           {!!.42}
        IsToUnLock := RefPtr = Nil;
        If IsToUnLock Then Begin
          IsamOK := IsamLockRecord ( RefNr * LenRec, SizeOf (LongInt),
              DatF.Handle, 0, 0 );
          If Not IsamOK Then IsamError := 10140;
          IsToUnLock := IsamOK;
        End;
      End;
    End;
  {$ENDIF}
    If IsamOK Then Begin
      With IFBPtr^, DIDPtr^[0]^ Do Begin
        IsamGetBlock ( DatF, RefNr * LenRec, LenRec, Dest );
      End;
    End;
  {$IFDEF LockBeforeRead}
    If IsToUnLock Then Begin
      With IFBPtr^, DIDPtr^[0]^ Do Begin
        If Not IsamUnLockRecord ( RefNr * LenRec, SizeOf (LongInt),
            DatF.Handle ) Then Begin
          IsamOK := False;
          IsamError := 10341;
        End;
      End;
    End;
  {$ENDIF}
  End;


  Procedure IsamGetRecReadOnly (     IFBPtr  : IsamFileBlockPtr;     {!!.50}
                                     RefNr   : LongInt;
                                 Var Dest              );

  Var
    TPtr       : ^Byte;
    RefPtr     : LongPtr;
    Dummy1Ptr,
    Dummy2Ptr  : IsamLockEntryRecPtr;
    IsToUnLock : Boolean;

  Begin
  {$IFDEF LockBeforeRead}
    IsToUnLock := False;
    With IFBPtr^, DIDPtr^[0]^ Do Begin
      If IsamOK And (NSP <> Nil) Then Begin
        IsamIsInLockList ( @IFBPtr^.NSP^.LockEntryRec, RefNr, RefPtr,
            False, Dummy1Ptr, Dummy2Ptr );                           {!!.42}
        IsToUnLock := RefPtr = Nil;
        If IsToUnLock Then Begin
          IsamOK := IsamLockRecord ( RefNr * LenRec, SizeOf (LongInt),
              DatF.Handle, 0, 0 );
        End;
        If IsamOK Then Begin
          IsamGetBlock ( DatF, RefNr * LenRec, LenRec, Dest );
        End Else Begin
          IsamClearOK;
          TPtr := Ptr ( Seg (Dest), Ofs (Dest) + SizeOf (LongInt) );
          IsamGetBlock ( DatF, RefNr * LenRec + SizeOf (LongInt),
              LenRec - SizeOf (LongInt), TPtr^ );
          If IsamOK Then Begin
            IsamOK := False;
            IsamError := 10205;
          End;
        End;
        If IsToUnLock Then Begin
          If Not IsamUnLockRecord ( RefNr * LenRec, SizeOf (LongInt),
              DatF.Handle ) Then Begin
          End;
        End;
      End Else Begin
        If IsamOK Then Begin
          IsamGetBlock ( DatF, RefNr * LenRec, LenRec, Dest );
        End;
      End;
    End;
  {$ELSE}
    If IsamOK Then Begin
      With IFBPtr^, DIDPtr^[0]^ Do Begin
        IsamGetBlock ( DatF, RefNr * LenRec, LenRec, Dest );
        If IsamError = 10140 Then Begin
          IsamClearOK;
          TPtr := Ptr ( Seg (Dest), Ofs (Dest) + SizeOf (LongInt) );
          IsamGetBlock ( DatF, RefNr * LenRec + SizeOf (LongInt),
              LenRec - SizeOf (LongInt), TPtr^ );
          If IsamOK Then Begin
            IsamOK := False;
            IsamError := 10205;
          End;
        End;
      End;
    End;
  {$ENDIF}
  End;


  Procedure IsamReleasePageBuffer;

  Var
    T1Ptr,
    T2Ptr,
    T3Ptr : IsamRingBufferRecPtr;

  Begin
    If IsamRBR1Ptr = Nil Then Exit;
    T1Ptr := IsamRBR1Ptr^.Next;
    Repeat
      T2Ptr := T1Ptr;
      T3Ptr := T1Ptr;
      T1Ptr := T1Ptr^.Next;
      With T3Ptr^ Do Begin
      {$IFDEF UseEMSHeap}
        If EMSEntry Then Begin
          FreeEMSMem ( EMSPointer (PageEntryPtr), SizeOf (IsamPageEntry) );
        End Else Begin
      {$ENDIF}
          FreeMem ( PageEntryPtr, SizeOf (IsamPageEntry) );
      {$IFDEF UseEMSHeap}
        End;
      {$ENDIF}
        IFBlPtr := Nil;
        UpDated := False;
      End;
      FreeMem ( T3Ptr, SizeOf (IsamRingBufferRec) );
    Until T2Ptr = IsamRBR1Ptr;
    IsamRBR1Ptr := Nil;
  End;


  Function IsamGetPageBuffer ( Free             : LongInt;
                               NrOfEMSTreePages : Word ) : LongInt;

  Var
    SaveEMSHeapErrorFuncPtr : Pointer;
    UseMinimumNormalHeap    : Boolean;
    MaxNrOfNormalHeapRecs   : Word;
    LResult                 : LongInt;                          {!!.51}


    Procedure InitAndInsertInRing ( Var RBRPtr     : IsamRingBufferRecPtr;
                                        IsEMSEntry : Boolean;
                                        PEPtr      : IsamPageEntryPtr );

    Begin
      GetMem ( RBRPtr, SizeOf (IsamRingBufferRec) );
      Inc (IsamNrOfRingBufferRecs);
      With RBRPtr^ Do Begin
        IFBlPtr := Nil;
        EMSEntry := IsEMSEntry;
        UpDated := False;
        SaveBuffered := False;
        PageEntryPtr := PEPtr;
      End;
      If IsamNrOfRingBufferRecs = 1 Then Begin
        IsamRBR1Ptr := RBRPtr;
        With IsamRBR1Ptr^ Do Begin
          Prev := IsamRBR1Ptr;
          Next := IsamRBR1Ptr;
        End;
      End Else Begin
        RBRPtr^.Prev := IsamRBR1Ptr;
        With IsamRBR1Ptr^ Do Begin
          RBRPtr^.Next := Next;
          Next^.Prev := RBRPtr;
          Next := RBRPtr;
        End;
      End;
    End;

  {$IFDEF UseEMSHeap}
    Procedure GetEMSPageBuffer;

    Var
      T1Ptr : EMSPointer;
      T2Ptr : IsamRingBufferRecPtr;
      T3Ptr : IsamPageEntryPtr;

    Begin
      While (MemAvail > (LongInt (RoundToGranul ( SizeOf (IsamRingBufferRec) ))
          + Free))
          And IsamAvailable ( SizeOf (IsamRingBufferRec) )
          And (IsamNrOfRingBufferRecs < NrOfEMSTreePages) Do Begin
        GetEMSMem ( T1Ptr, SizeOf (IsamPageEntry) );
        If T1Ptr = Nil Then Exit;
        InitAndInsertInRing ( T2Ptr, True, T1Ptr );
        T3Ptr := IsamPageEntryPtr (IsamRBufPtrToPgPtr ( T2Ptr ));
        FillChar ( T3Ptr^, SizeOf (IsamPageEntry), 0 );
        T3Ptr^.RingBufferPtr := T2Ptr;
      End;
    End;
  {$ENDIF}

    Procedure GetPageBuffer ( MaxNrOfRecs : Word );

    Var
      T1Ptr : IsamPageEntryPtr;
      T2Ptr : IsamRingBufferRecPtr;

    Begin
      Inc (MaxNrOfRecs, IsamNrOfRingBufferRecs);
      While (MemAvail >= (LongInt (RoundToGranul ( SizeOf (IsamRingBufferRec) )
          + RoundToGranul ( SizeOf (IsamPageEntry) )) + Free))
          And IsamAvailable ( SizeOf (IsamPageEntry) )
          And (IsamNrOfRingBufferRecs < MaxNrOfRecs) Do Begin
        GetMem ( T1Ptr, SizeOf (IsamPageEntry) );
        If Not IsamAvailable ( SizeOf (IsamRingBufferRec) ) Then Begin
          FreeMem ( T1Ptr, SizeOf (IsamPageEntry) );
          Exit;
        End;
        InitAndInsertInRing ( T2Ptr, False, T1Ptr );
        FillChar ( T1Ptr^, SizeOf (IsamPageEntry), 0 );
        T1Ptr^.RingBufferPtr := T2Ptr;
      End;
    End;


  Begin
    IsamNrOfRingBufferRecs := 0;
    IsamRBR1Ptr := Nil;
    UseMinimumNormalHeap := Free >= MinimizeUseOfNormalHeap;
    If UseMinimumNormalHeap Then Begin
      Free := Free - MinimizeUseOfNormalHeap;
    End;
  {$IFDEF UseEMSHeap}
    If NrOfEMSTreePages > 0 Then Begin
      SaveEMSHeapErrorFuncPtr := EMSHeapErrorFuncPtr;
      EMSHeapErrorFuncPtr := Nil;
        {-Set default handling for not to use EMSMaxAvail}
      GetEMSPageBuffer;
      EMSHeapErrorFuncPtr := SaveEMSHeapErrorFuncPtr;
    End;
  {$ENDIF}
    LResult := 0;                                               {!!.51}
    ILI (LResult).Hi := IsamNrOfRingBufferRecs;                 {!!.51}
    If UseMinimumNormalHeap Then Begin
      If IsamNrOfRingBufferRecs < MaxHeight Then Begin
        MaxNrOfNormalHeapRecs := MaxHeight - IsamNrOfRingBufferRecs;
      End Else Begin
        MaxNrOfNormalHeapRecs := 0;
      End;
    End Else Begin
      MaxNrOfNormalHeapRecs := 65535 - IsamNrOfRingBufferRecs;
    End;
    GetPageBuffer ( MaxNrOfNormalHeapRecs );
    ILI (LResult).Lo := IsamNrOfRingBufferRecs - ILI (LResult).Hi;  {!!.51}
    IsamGetPageBuffer := LResult;                                   {!!.51}
    If IsamNrOfRingBufferRecs < MaxHeight Then Begin
      IsamReleasePageBuffer;
      IsamOK := False;
      IsamError := 10000;
    End;
  End;


  Procedure IsamGetStartingLong (     IFBPtr  : IsamFileBlockPtr;    {!!.42}
                                      RefNr   : LongInt;
                                  Var Dest    : LongInt );

  Var
    RefPtr     : LongPtr;
    Dummy1Ptr,
    Dummy2Ptr  : IsamLockEntryRecPtr;
    IsToUnLock : Boolean;

  Begin
  {$IFDEF LockBeforeRead}
    IsToUnLock := False;
    With IFBPtr^, DIDPtr^[0]^ Do Begin
      If NSP <> Nil Then Begin
        IsamIsInLockList ( @IFBPtr^.NSP^.LockEntryRec, RefNr, RefPtr,
            False, Dummy1Ptr, Dummy2Ptr );                          {!!.42}
        IsToUnLock := RefPtr = Nil;
        If IsToUnLock Then Begin
          IsamOK := IsamLockRecord ( RefNr * LenRec, SizeOf (LongInt),
              DatF.Handle, 0, 0 );
          If Not IsamOK Then IsamError := 10140;
          IsToUnLock := IsamOK;
        End;
      End;
    End;
  {$ENDIF}
    If IsamOK Then Begin
      With IFBPtr^, DIDPtr^[0]^ Do Begin
        IsamGetBlock ( DatF, RefNr * LenRec, SizeOf (LongInt), Dest );
      End;
    End;
  {$IFDEF LockBeforeRead}
    If IsToUnLock Then Begin
      With IFBPtr^, DIDPtr^[0]^ Do Begin
        If Not IsamUnLockRecord ( RefNr * LenRec, SizeOf (LongInt),
            DatF.Handle ) Then Begin
          IsamOK := False;
          IsamError := 10341;
        End;
      End;
    End;
  {$ENDIF}
  End;


  Procedure IsamFindRecRef (     IFBPtr                  : IsamFileBlockPtr;
                             Var UserDatRef              : LongInt;
                                 NotFoundSearchDirection : Integer );{!!.42}

  Var
    LongDest : LongInt;
    Found    : Boolean;

  Begin
    Found := False;
    If NotFoundSearchDirection = 0 Then Begin
      IsamGetStartingLong ( IFBPtr, UserDatRef, LongDest );
      If IsamOK Then Begin
        Found := LongDest = 0;
      End;
    End Else Begin
      If NotFoundSearchDirection > 0 Then Begin
        If UserDatRef < 1 Then Begin
          UserDatRef := 0;
        End Else Begin
          Dec (UserDatRef);
        End;
        Repeat
          Inc (UserDatRef);
          IsamGetStartingLong ( IFBPtr, UserDatRef, LongDest );
          If IsamOK Then Begin
            Found := LongDest = 0;
          End;
        Until Found Or Not IsamOK
            Or (UserDatRef = IFBPtr^.DIDPtr^[0]^.NumRec);
      End Else Begin
        If UserDatRef > IFBPtr^.DIDPtr^[0]^.NumRec Then Begin
          UserDatRef := Succ (IFBPtr^.DIDPtr^[0]^.NumRec);
        End Else Begin
          Inc (UserDatRef);
        End;
        If UserDatRef > 1 Then Begin
          Repeat
            Dec (UserDatRef);
            IsamGetStartingLong ( IFBPtr, UserDatRef, LongDest );
            If IsamOK Then Begin
              Found := LongDest = 0;
            End;
          Until Found Or Not IsamOK Or (UserDatRef = 1);
        End;
      End;
    End;
    If IsamError <> 10140 Then Begin
      If IsamError <> 9904 Then Begin
        IsamClearOK;
        If Not Found Then Begin
          IsamOK := False;
          IsamError := 10275;
        End;
      End;
    End Else Begin
      IsamError := 10390;
    End;
  End;


  Function IsamLongIntLessEqualHighBit ( L         : LongInt;       {!!.42}
                                         IsLongInt : Boolean ) : Word;

  Var
    LResult : Word;                                             {!!.51}

  Begin
    If IsLongInt Then Begin
      LResult := 33;                                            {!!.51}
    End Else Begin
      LResult := 17;                                            {!!.51}
      L := L Shl 16;
    End;
    Repeat
      If (L And $80000000) = $80000000 Then Begin
        IsamLongIntLessEqualHighBit := LResult;                 {!!.51}
        Exit;
      End;
      L := L Shl 1;
      Dec (LResult);                                            {!!.51}
    Until LResult = 0;                                          {!!.51}
    IsamLongIntLessEqualHighBit := 0;
  End;


  Procedure IsamGetApprRecPos (     IFBPtr     : IsamFileBlockPtr;
                                Var RelPos     : Word;
                                    Scale      : Word;
                                    UserDatRef : LongInt );          {!!.42}

  Var
    N          : LongInt;
    HighBitSum : Word;

  Begin
    If Scale = 0 Then Begin
      IsamOK := False;
      IsamError := 10425;
      Exit;
    End;
    N := Succ (IFBPtr^.DIDPtr^[0]^.NumRec);
    If UserDatRef < 0 Then UserDatRef := 0;
    If UserDatRef > N Then UserDatRef := N;
    HighBitSum := IsamLongIntLessEqualHighBit ( UserDatRef, True ) +
        IsamLongIntLessEqualHighBit ( Succ (Scale), False );
    If HighBitSum > 31 Then Begin
      UserDatRef := UserDatRef Shr (HighBitSum - 31 );
      N := N Shr (HighBitSum - 31 );
    End;
    RelPos := UserDatRef * Succ (Scale) Div N;
  End;


  Procedure IsamGetApprRecRef (     IFBPtr     : IsamFileBlockPtr;
                                    RelPos     : Word;
                                    Scale      : Word;
                                Var UserDatRef : LongInt );          {!!.42}

  Var
    N,
    D  : LongInt;

  Begin
    If (Scale = 0) Or (RelPos > Scale) Then Begin
      IsamOK := False;
      IsamError := 10420;
      Exit;
    End;
    N := Succ (IFBPtr^.DIDPtr^[0]^.NumRec);
    If (IsamLongIntLessEqualHighBit ( N, True ) +
        IsamLongIntLessEqualHighBit ( RelPos, False )) > 31 Then Begin
      D := (N Div Succ (Scale)) * RelPos;
    End Else Begin
      D := (N * RelPos) Div Succ (Scale);
    End;
    UserDatRef := D + N Div Succ (Scale) - (N Div Succ (Scale)) Shr 1;
  End;


  Procedure IsamClearKey ( IFBPtr : IsamFileBlockPtr; Key : Integer );

  Begin
    With IFBPtr^.DIDPtr^[Key]^ Do Begin
      PathInd := 0;
      SequentialOK := True;
    End;
  End;


  Procedure IsamNextKey (     IFBPtr     : IsamFileBlockPtr;
                              Key        : Word;
                          Var UserDatRef : LongInt;
                          Var UserKey    : IsamKeyStr         );

  Var
    RefNr  : LongInt;
    IPgPtr : IsamPagePtr;
  {$IFDEF ASCIIZeroKeys}
    TempKeyZ : IsamKeyStr;
  {$ENDIF}
  {$IFDEF LengthByteKeys}
    TempKeyZ : IsamKeyStr absolute UserKey;
  {$ENDIF}

  Begin
    With IFBPtr^, DIDPtr^[Key]^ Do Begin
      If Not SequentialOK Then Begin
        If SearchForSequentialEnabled Then Begin
        {$IFDEF ASCIIZeroKeys}
          IsamMakeStrZ ( UserKey, TempKeyZ );
        {$ENDIF}
          IsamFindKey ( IFBPtr, Key, UserDatRef, TempKeyZ );
          If IsamError = 0 Then Begin
            IsamClearOK;
          End Else Begin
            Exit;
          End;
        End Else Begin
          IsamOK := False;
          IsamError := 10255;
          Exit;
        End;
      End;
      SequentialOK := False;
      If PathInd = 0 Then Begin
        RefNr := RootRef;
      End Else Begin
        With Path [PathInd] Do Begin
          IsamGetPage ( IFBPtr, PageRef, Key, IPgPtr );
          If Not IsamOK Then Exit;
          RefNr := IPgPtr^.ItemArray [ItemArrInd].PageRef;
        End;
      End;
      While RefNr <> 0 Do Begin
        Inc (PathInd);
        With Path [PathInd] Do Begin
          PageRef := RefNr;
          ItemArrInd := 0;
        End;
        IsamGetPage ( IFBPtr, RefNr, Key, IPgPtr );
        If Not IsamOK Then Exit;
        RefNr := IPgPtr^.BckwPageRef;
      End;
      If PathInd <> 0 Then Begin
        While (PathInd > 1) And
            (Path [PathInd].ItemArrInd = IPgPtr^.ItemsOnPage) Do Begin
          Dec (PathInd);
          IsamGetPage ( IFBPtr, Path [PathInd].PageRef, Key, IPgPtr);
          If Not IsamOK Then Exit;
        End;
        If Path [PathInd].ItemArrInd < IPgPtr^.ItemsOnPage Then Begin
          With Path [PathInd] Do Begin
            Inc (ItemArrInd);
            With IPgPtr^.ItemArray [ItemArrInd] Do Begin
              IsamMakeStr ( KeyStr, UserKey);
              UserDatRef := DataRef;
            End;
          End;
        End Else Begin
          PathInd := 0;
        End;
      End;
      IsamOK := PathInd <> 0;
      If Not IsamOK Then IsamError := 10250;
      SequentialOK := True;
    End;
  End;


  Procedure IsamFindKeyAndRef (     IFBPtr                  : IsamFileBlockPtr;
                                    Key                     : Word;
                                Var UserDatRef              : LongInt;
                                Var UserKey                 : IsamKeyStr;
                                    NotFoundSearchDirection : Integer );

  Var
    IPgPtr   : IsamPagePtr;
  {$IFDEF ASCIIZeroKeys}
    TempKeyZ : IsamKeyStr;
  {$ENDIF}
  {$IFDEF LengthByteKeys}
    TempKeyZ : IsamKeyStr absolute UserKey;
  {$ENDIF}

  Begin
  {$IFDEF ASCIIZeroKeys}
    IsamMakeStrZ ( UserKey, TempKeyZ );
  {$ENDIF}
    IsamFindKey ( IFBPtr, Key, UserDatRef, TempKeyZ );
    If Not IsamOK And (IsamError = 0) Then Begin
      IsamClearOK;
      If NotFoundSearchDirection > 0 Then Begin
        IsamNextKey ( IFBPtr, Key, UserDatRef, UserKey );
      End Else Begin
        If NotFoundSearchDirection < 0 Then Begin
          With IFBPtr^, DIDPtr^[Key]^ Do Begin
            If PathInd = 0 Then Begin
              IsamOK := False;
              IsamError := 10260;
            End Else Begin
              With Path [PathInd] Do Begin
                IsamGetPage ( IFBPtr, PageRef, Key, IPgPtr );
                If Not IsamOK Then Exit;
                With IPgPtr^.ItemArray [ItemArrInd] Do Begin
                  UserDatRef := DataRef;
                  IsamMakeStr ( KeyStr, UserKey );
                End;
              End;
            End;
          End;
        End Else Begin
          IsamOK := False;
          IsamError := 10270;
        End;
      End;
    End;
  End;


  Procedure IsamPrevKey (     IFBPtr     : IsamFileBlockPtr;
                              Key        : Word;
                          Var UserDatRef : LongInt;
                          Var UserKey    : IsamKeyStr            );

  Var
    RefNr  : LongInt;
    IPgPtr : IsamPagePtr;

  Begin
    With IFBPtr^, DIDPtr^[Key]^ Do Begin
      If Not SequentialOK Then Begin
        If SearchForSequentialEnabled Then Begin
          IsamFindKeyAndRef ( IFBPtr, Key, UserDatRef, UserKey, 0 );
          If Not IsamOK Then Begin
            If IsamError = 10270 Then Begin
              IsamClearOK;
              IsamFindKeyAndRef ( IFBPtr, Key, UserDatRef, UserKey, -1 );
            End;
            Exit;
          End;
        End Else Begin
          IsamOK := False;
          IsamError := 10265;
          Exit;
        End;
      End;
      SequentialOK := False;
      If PathInd = 0 Then Begin
        RefNr := RootRef;
      End Else Begin
        With Path [PathInd] Do Begin
          IsamGetPage ( IFBPtr, PageRef, Key, IPgPtr );
          If Not IsamOK Then Exit;
          Dec (ItemArrInd);
          If ItemArrInd = 0 Then Begin
            RefNr := IPgPtr^.BckwPageRef;
          End Else Begin
            RefNr := IPgPtr^.ItemArray [ItemArrInd].PageRef;
          End;
        End;
      End;
      While RefNr <> 0 Do Begin
        IsamGetPage ( IFBPtr, RefNr, Key, IPgPtr );
        If Not IsamOK Then Exit;
        Inc (PathInd);
        With Path [PathInd] Do Begin
          PageRef := RefNr;
          ItemArrInd := IPgPtr^.ItemsOnPage;
        End;
        With IPgPtr^ Do Begin
          RefNr := ItemArray [ItemsOnPage].PageRef;
        End;
      End;
      If PathInd <> 0 Then Begin
        While (PathInd > 1) And (Path [PathInd].ItemArrInd = 0) Do Begin
          Dec (PathInd);
          IsamGetPage ( IFBPtr, Path [PathInd].PageRef, Key, IPgPtr );
          If Not IsamOK Then Exit;
        End;
        If Path [PathInd].ItemArrInd > 0 Then Begin
          With IPgPtr^.ItemArray [Path [PathInd].ItemArrInd] Do Begin
            IsamMakeStr ( KeyStr, UserKey );
            UserDatRef := DataRef;
          End;
        End Else Begin
          PathInd := 0;
        End;
      End;
      IsamOK := PathInd <> 0;
      If Not IsamOK Then IsamError := 10260;
      SequentialOK := True;
    End;
  End;


  Procedure IsamSearchKey (     IFBPtr     : IsamFileBlockPtr;
                                Key        : Word;
                            Var UserDatRef : LongInt;
                            Var UserKey    : IsamKeyStr        );

  Var
  {$IFDEF ASCIIZeroKeys}
    TempKeyZ : IsamKeyStr;
  {$ENDIF}
  {$IFDEF LengthByteKeys}
    TempKeyZ : IsamKeyStr absolute UserKey;
  {$ENDIF}

  Begin
  {$IFDEF ASCIIZeroKeys}
    IsamMakeStrZ ( UserKey, TempKeyZ );
  {$ENDIF}
    UserDatRef := 0;
    IsamFindKey ( IFBPtr, Key, UserDatRef, TempKeyZ );
    If Not IsamOK And (IsamError = 0) Then Begin
      IsamClearOK;
      IsamNextKey ( IFBPtr, Key, UserDatRef, UserKey );
    End;
    If Not IsamOK Then Begin
      Case IsamError Of
        0, 10200..10299 : IsamError := 10210;
      End; {Case}
    End;
  End;


  Procedure IsamDeleteAllKeys ( IFBPtr : IsamFileBlockPtr; Key : Word );

  Var
    IR : IsamInfoRec;

  Begin
    IsamSetDataBufferedFlag ( IFBPtr );
    If Not IsamOK Then Exit;
    With IFBPtr^ Do Begin
      If SaveFB Then Begin
        IsamCopyInfoRecToIR ( IFBPtr, Key, IR );
        IsamSaveGivenInfoRec ( IFBPtr, Key, IR, -2 );
        If Not IsamOK Then Exit;
        If (NSP = Nil) Or IsamNetEmu Then Begin
          IsamFlushDOSDia ( IFBPtr, False );
          If Not IsamOK Then Exit;
        End;
      End;
      IsamDestroyPagesOfKeyNr ( IFBPtr, Key );
      With DIDPtr^[Key]^ Do Begin
        NumKeys := 0;
        FirstFree := -1;
        NumberFree := 0;
        NumRec := 0;
        RootRef := 0;
        PathInd := 0;
        FirstFreeChanged := True;
        InfoRecChanged := True;
      End;
      If SaveFB Then Begin
        IsamPutInfoRec ( IFBPtr, Key, False );
        If Not IsamOK Then Exit;
        If (NSP = Nil) Or IsamNetEmu Then IsamFlushDOSIx ( IFBPtr );
      End;
    End;
  End;


  Procedure IsamGetApprRelPos (     IFBPtr     : IsamFileBlockPtr;
                                    Key        : Word;
                                Var RelPos     : Word;
                                    Scale      : Word;
                                    UserKey    : IsamKeyStr;
                                    UserDatRef : LongInt );

  Var
    TempL,
    RefNr               : LongInt;
    C, K, L, R          : Integer;
    IPgPtr              : IsamPagePtr;
    Stop                : Boolean;
    EstEltNr,
    EstNrOfElts,
    RootItemNr,
    ItemNrOnSecPage,
    NrOfItemsOnRoot,
    NrOfItemsOnSecPage,
    AvgPageSizeSecLevel : Word;

  Begin
    If Scale = 0 Then Begin
      IsamOK := False;
      IsamError := 10425;
      Exit;
    End;
    With IFBPtr^, DIDPtr^[Key]^ Do Begin
      If RootRef = 0 Then Begin
        IsamOK := False;
        IsamError := 10285;
        Exit;
      End;
      AvgPageSizeSecLevel := UsedPageSize - (UsedPageSize Shr 2);
       {-75% of real page contents assumed}
      NrOfItemsOnSecPage := AvgPageSizeSecLevel;
      RootItemNr := $FFFF;
      ItemNrOnSecPage := 0;
      IsamMakeStrZ ( UserKey, UserKey );
      Stop := False;
      RefNr := RootRef;
      While (RefNr <> 0) And (Not Stop) Do Begin
        IsamGetPage ( IFBPtr, RefNr, Key, IPgPtr );
        If Not IsamOK Then Exit;
        With IPgPtr^ Do Begin
          L := 1;
          R := ItemsOnPage;
          Repeat
            K := (L + R) Shr 1;
            C := IsamCompKeys ( UserKey, ItemArray [K].KeyStr,
                                UserDatRef, ItemArray [K].DataRef,
                                AllowDupKeys );
            If C <= 0 Then R := Pred (K);
            If C >= 0 Then L := Succ (K);
          Until R < L;
          If L - R > 1 Then Begin
            Stop := True;
          End Else Begin
            If R = 0 Then Begin
              RefNr := BckwPageRef;
            End Else Begin
              RefNr := ItemArray [R].PageRef;
            End;
          End;
          If RootItemNr = $FFFF Then Begin
            NrOfItemsOnRoot := ItemsOnPage;
            If L - R > 1 Then Begin
              RootItemNr := K;
            End Else Begin
              RootItemNr := R;
            End;
          End Else Begin
            NrOfItemsOnSecPage := ItemsOnPage;
            If L - R > 1 Then Begin
              ItemNrOnSecPage := K;
            End Else Begin
              ItemNrOnSecPage := R;
            End;
            Stop := True;
          End;
        End;
      End;
    End;
    EstNrOfElts := Succ (AvgPageSizeSecLevel) * Succ (NrOfItemsOnRoot);
      {-Includes backward references on second level (<=> 0''/items on root)}
    If (ItemNrOnSecPage = 1) And (RootItemNr = 0) Then Begin
      {-Prevent zero position from growing}
      EstEltNr := 1;
    End Else Begin
      TempL := ((LongInt (ItemNrOnSecPage)
          * LongInt (Succ (AvgPageSizeSecLevel))) Shl 1)
          Div LongInt (NrOfItemsOnSecPage);
      EstEltNr := RootItemNr * Succ (AvgPageSizeSecLevel)
          + (TempL - TempL Shr 1);
    End;
    RelPos := Word ((LongInt (EstEltNr) * Succ (LongInt (Scale)))
        Div LongInt (EstNrOfElts));
    If RelPos > Scale Then RelPos := Scale;
      {-Slighly unsymethric, but simple}
  End;


  Procedure IsamGetApprKeyAndRef (     IFBPtr     : IsamFileBlockPtr;
                                       Key,
                                       RelPos     : Word;
                                       Scale      : Word;
                                   Var UserKey    : IsamKeyStr;
                                   Var UserDatRef : LongInt );

  Var
    EstNrOfElts,
    EstEltNr,
    EstRootItemNr,
    EstItemNrOnSecPage,
    CorItemNrOnSecPage,
    AvgPageSizeSecLevel : Word;
    IPgPtr              : IsamPagePtr;
    TempL               : LongInt;


  Begin
    If (Scale = 0) Or (RelPos > Scale) Then Begin
      IsamOK := False;
      IsamError := 10420;
      Exit;
    End;
    With IFBPtr^, DIDPtr^[Key]^ Do Begin
      If RootRef = 0 Then Begin
        IsamOK := False;
        IsamError := 10280;
        Exit;
      End;
      IsamGetPage ( IFBPtr, RootRef, Key, IPgPtr );
      If Not IsamOK Then Exit;
      AvgPageSizeSecLevel := UsedPageSize - (UsedPageSize Shr 2);    {!!.42}
       {-75% of real page contents assumed}
    End;
    With IPgPtr^ Do Begin
      If BckwPageRef = 0 Then Begin
        {-No second level available}
        AvgPageSizeSecLevel := 0;
      End;                                                           {!!.42}
      EstNrOfElts := Succ (AvgPageSizeSecLevel) * Succ (ItemsOnPage);
        {-Includes backward references on second level (<=> 0''/items on root)}
      EstEltNr := (LongInt (EstNrOfElts) * LongInt (RelPos))
          Div Succ (LongInt (Scale))
          + EstNrOfElts Div Scale - (EstNrOfElts Div Scale) Shr 1;
        {-Numbering starts at zero}
      If EstEltNr >= EstNrOfElts Then EstEltNr := Pred (EstNrOfElts);
        {-Correct estimate error}
      EstRootItemNr := EstEltNr Div (Succ (AvgPageSizeSecLevel));
      EstItemNrOnSecPage := EstEltNr Mod (Succ (AvgPageSizeSecLevel));
      If (BckwPageRef = 0) Or (EstItemNrOnSecPage = 0) Then Begin
        {-No second level available}
        If EstRootItemNr = 0 Then Begin
          {-Build the smallest key}
          UserKey := '';
          UserDatRef := 0;
        End Else Begin
          With ItemArray [EstRootItemNr] Do Begin
            IsamMakeStr ( KeyStr, UserKey);
            UserDatRef := DataRef;
          End;
        End;
        Exit;
      End;
      If EstRootItemNr = 0 Then Begin
        IsamGetPage ( IFBPtr, BckwPageRef, Key, IPgPtr );
      End Else Begin
        IsamGetPage ( IFBPtr, ItemArray [EstRootItemNr].PageRef, Key,
            IPgPtr );
      End;
    End;
    If Not IsamOK Then Exit;
    With IPgPtr^ Do Begin
      {-Prevent RelPos one from decreasing}
      If (EstItemNrOnSecPage = 2) And (EstRootItemNr = 0) Then Begin
        CorItemNrOnSecPage := 2;
      End Else Begin
        TempL := ((LongInt (EstItemNrOnSecPage) * LongInt (ItemsOnPage)) Shl 1)
            Div LongInt (AvgPageSizeSecLevel);
        CorItemNrOnSecPage := TempL - TempL Shr 1;
      End;
      If CorItemNrOnSecPage = 0 Then Inc (CorItemNrOnSecPage);
        {-Slighly unsymethric, but simple}
      With ItemArray [CorItemNrOnSecPage] Do Begin
        IsamMakeStr ( KeyStr, UserKey);
        UserDatRef := DataRef;
      End;
    End;
  End;


  Procedure IsamFlushFileBlock ( IFBPtr : IsamFileBlockPtr );

  Var
    DoIt : Boolean;

  Begin
    With IFBPtr^ Do Begin
      If SaveFB Or ReadOnlyFB Then Exit;                          {!!.50mod}
        {-A save fileblock and a read only fileblock
          never have data buffered}
      If NSP = Nil Then Begin
        DoIt := True;
      End Else Begin
        DoIt := NSP^.Locked;
      End;
      If DoIt Then Begin
        If NSP = Nil Then Begin
          If DataBuffered
              Then IsamFlushPageInfo ( IFBPtr, False );           {!!.50mod}
          If Not IsamOK Then Exit;
          IsamFlushDOSDat ( IFBPtr );
      {$IFNDEF NoNet}
        End Else Begin
          If DataBuffered Then Begin                                 {!!.50}
            IsamBuildAndPutFlagSetFlushNewData ( IFBPtr );
            If Not IsamOK Then Exit;
          End;                                                       {!!.50}
          IsamOnlyFlushDOSDat ( IFBPtr );
          If Not IsamOK Then Exit;
          If DataBuffered                                         {!!.50mod}
              Then IsamFlushDOSDia ( IFBPtr, False );             {!!.50mod}
      {$ENDIF}
        End;
        If Not IsamOK Then Exit;
        If (NrOfKeys > 0) And DataBuffered Then Begin             {!!.50mod}
          IsamFlushDOSIx ( IFBPtr );
          If Not IsamOK Then Exit;
        End;
        DataBuffered := False;
      End;
    End;
  End;


  Procedure IsamFlushAllFileBlocks;

  Var
    TPtr  : IsamOpenFileBlockListPtr;

  Begin
    TPtr := IsamOFBLPtr;
    While TPtr <> Nil Do Begin
      IsamFlushFileBlock ( TPtr^.OIFBPtr );
      If Not IsamOK Then Exit;
      TPtr := TPtr^.Next;
    End;
  End;


  Procedure IsamDeleteFileBlock ( FName  : IsamFileBlockName );

  Var
    TF        : IsamFile;
    DummyStr,
    FNameD,
    FNameI    : IsamFileBlockName;

  Begin
    IsamExtractFileNames ( FName, FNameD, FNameI );
    IsamExtractFileNames ( FNameI, FNameI, DummyStr );
    IsamAssign ( TF, IsamForceExtension ( FNameI, IxExtension ) );
    IsamDelete ( TF );
    IsamClearOK;
    IsamAssign ( TF, IsamForceExtension ( FNameD, DiaExtension ) );
    IsamDelete ( TF );
    IsamClearOK;
    IsamAssign ( TF, IsamForceExtension ( FNameD, DatExtension ) );
    IsamDelete ( TF );
  End;


  Procedure IsamCreateFileBlock ( FName        : IsamFileBlockName;
                                  DatSLen      : LongInt;
                                  NumberOfKeys : Word;
                                  IID          : IsamIndDescr  );

  Var
    TIFBPtr  : IsamFileBlockPtr;
    I        : Integer;
    DummyStr,
    FNameD,
    FNameI   : IsamFileBlockName;


    Procedure UnDo ( UnDoLevel : Word; Err : Integer );

    Begin
      With TIFBPtr^ Do Begin
        If UnDoLevel >= 3 Then Begin
          IsamClose ( IndF );
          IsamDelete ( IndF );
        End;
        If UnDoLevel >= 2 Then Begin
          IsamClose ( DatF );
          IsamDelete ( DatF );
        End;
        If UnDoLevel >= 1 Then Begin
          IsamFreeKeyDescrMem ( TIFBPtr, NumberOfKeys );
          FreeMem ( TIFBPtr, SizeOf (TIFBPtr^) );
        End;
        IsamOK := Err = 0;
        IsamError := Err;
      End;
    End;


  Begin
    If DatSLen < SizeOf (IsamSmallInfoRec) Then IsamError := 10020;
    If ( NumberOfKeys > MaxNrOfKeys ) Or ( NumberOfKeys < 0 ) Then
        IsamError := 10050;
    If Not IsamAvailable ( SizeOf (TIFBPtr^) ) Then
        IsamError := 10090;
    If IsamError <> 0 Then Begin
      IsamOK := False;
      Exit;
    End;
    IsamDeleteFileBlock ( FName );
    IsamClearOK;
    GetMem ( TIFBPtr, SizeOf (TIFBPtr^) );
    TIFBPtr^.NrOfKeys := NumberOfKeys;
      {-For possible IsamFreeKeyDescrMem below}
    IsamGetKeyDescrMem ( TIFBPtr, NumberOfKeys );
    If Not IsamOK Then Begin
      FreeMem ( TIFBPtr, SizeOf (TIFBPtr^) );
      Exit;
    End;
    IsamExtractFileNames ( FName, FNameD, FNameI );
    IsamExtractFileNames ( FNameI, FNameI, DummyStr );
    With TIFBPtr^ Do Begin
      IsamAssign ( DatF, IsamForceExtension ( FNameD, DatExtension ) );
      IsamRewrite ( DatF );
      If Not IsamOK Then Begin
        UnDo ( 1, IsamError );
        Exit;
      End;
      With DIDPtr^[0]^ Do Begin
        FirstFree := -1;
        NumberFree := 0;
        NumRec := 0;
        LenRec := DatSLen;
        InfoRecChanged := True;
      End;
      IsamPutDummyBlock ( DatF, 0, DIDPtr^[0]^.LenRec );
      If IsamOK Then IsamPutInfoRec ( TIFBPtr, 0, False );
      If Not IsamOK Then Begin
        UnDo ( 2, IsamError );
        Exit;
      End;
      IsamClose ( DatF );
      If Not IsamOK Then Begin
        UnDo ( 2, IsamError );
        Exit;
      End;
      If NumberOfKeys > 0 Then Begin
        IsamAssign ( IndF, IsamForceExtension ( FNameI, IxExtension ) );
        IsamRewrite ( IndF );
        If Not IsamOK Then Begin
          UnDo ( 2, IsamError );
          Exit;
        End;
        MaxPages := 0;
        BlockLen := 0;
        For I := 1 To NumberOfKeys Do Begin
          With DIDPtr^[I]^ Do Begin
            KeyLen := IID [I].KeyL;
            If ( KeyLen < 1 ) Or ( KeyLen > MaxKeyLen ) Then Begin
              UnDo ( 3, 10055 );
              Exit;
            End;
            LenRec := LongInt (9 + KeyLen) * LongInt (CreatePageSize){!!.42}
                + LongInt (6);
            BlockOfs := BlockLen;
            BlockLen := BlockLen + LenRec;
            NumKeys := 0;
            UsedPageSize := CreatePageSize;                          {!!.42}
            FirstFree := -1;
            NumberFree := 0;
            NumRec := 0;
            RootRef := 0;
            AllowDupKeys := IID [I].AllowDupK;
            InfoRecChanged := True;
          End;
        End;
        IsamPutDummyBlock ( IndF, 0, BlockLen );
        If IsamOK Then IsamFlushPageInfo ( TIFBPtr, False );
        If IsamOK Then IsamClose ( IndF );
        If Not IsamOK Then Begin
          UnDo ( 3, IsamError );
          Exit;
        End;
      End;
      UnDo ( 1, 0 );
    End;
  End;


  Procedure IsamOpenRawFileBlock ( Var IFBPtr   : IsamFileBlockPtr;
                                       FNameD,
                                       FNameI   : IsamFileBlockName;
                                       RealNet,
                                       ReadOnly : Boolean );

  Var
    I                  : Integer;
    IDID               : IsamDatIndDescr;
    IDIDPtr            : IsamDatIndDescrPtr;
    HeadOrIndCorrupted,
    Dummy              : Boolean;
    CalcKeyL           : LongInt;


    Procedure UnDo ( Level : Word; Error : Integer );

    Begin
      With IFBPtr^ Do Begin
        If Level >= 4 Then Begin
          If NrOfKeys > 0 Then IsamClose ( IndF );
        End;
        If Level >= 3 Then Begin
          IsamFreeKeyDescrMem ( IFBPtr, NrOfKeys );
        End;
        If Level >= 2 Then IsamClose ( DatF );
        If Level >= 1 Then FreeMem ( IFBPtr, SizeOf (IFBPtr^) );
      End;
      IsamError := Error;
      IsamOK := IsamError = 0;
    End;


  Begin
    If Not IsamAvailable ( SizeOf (IFBPtr^) ) Then Begin
      IsamOK := False;
      IsamError := 10100;
      Exit;
    End;
    GetMem ( IFBPtr, SizeOf (IFBPtr^) );
    With IFBPtr^ Do Begin
      IsamAssign ( DatF, IsamForceExtension ( FNameD, DatExtension ) );
      IsamReset ( DatF, RealNet, ReadOnly );
      If Not IsamOK Then Begin
        UnDo ( 1, IsamError );
        Exit;
      End;
      IDIDPtr := Addr (IDID);
      DIDPtr := Addr (IDIDPtr);
        {-First hold info lokally}
      IsamGetInfoRec ( IFBPtr, 0, HeadOrIndCorrupted );
      If Not IsamOK Then Begin
        UnDo ( 2, IsamError );
        Exit;
      End;
      If NrOfKeys > MaxNrOfKeys Then Begin
        UnDo ( 2, 10060 );
        Exit;
      End;
      IsamGetKeyDescrMem ( IFBPtr, NrOfKeys );
      If Not IsamOK Then Begin
        UnDo ( 2, IsamError );
        Exit;
      End;
      If NrOfKeys > 0 Then Begin
        IsamAssign ( IndF, IsamForceExtension ( FNameI, IxExtension ) );
        IsamReset ( IndF, RealNet, ReadOnly );
        If Not IsamOK Then Begin
          If (IsamError <> 9901) And (IsamError <> 10110)
              Then IsamError := 10010;
            {-Index file may be ok, if out of handles or drive not ready}
          UnDo ( 3, IsamError );
          Exit;
        End;
      End;
      MaxPages := 0;
      BlockLen := 0;
      IDID.FirstFreeChanged := False;
      IDID.InfoRecChanged := False;
      DIDPtr^[0]^ := IDID;
        {-Copy lokal info to real}
      For I := 1 To NrOfKeys Do Begin
        With DIDPtr^[I]^ Do Begin
          BlockOfs := BlockLen;
          IsamGetInfoRec ( IFBPtr, I, Dummy );
          If Not IsamOK Then Begin
            UnDo ( 4, IsamError );
            Exit;
          End;
          If UsedPageSize > MaxPageSize Then Begin                   {!!.42}
            UnDo ( 4, 10122 );                                       {!!.42}
            Exit;                                                    {!!.42}
          End;                                                       {!!.42}
          CalcKeyL := (LenRec * LongInt (10000) - LongInt (60000))   {!!.42}
              Div LongInt (UsedPageSize) - LongInt (90000);
          If (((CalcKeyL Div LongInt (10000)) * LongInt (10000)) <> CalcKeyL)
              Then Begin
            UnDo ( 4, 10120 );
            Exit;
          End;
          If (CalcKeyL > (LongInt (MaxKeylen) * LongInt (10000)))
              Or (CalcKeyL < LongInt (10000)) Then Begin
            UnDo ( 4, 10121 );
            Exit;
          End;
          KeyLen := Word (CalcKeyL Div LongInt (10000));
          BlockLen := BlockLen + LenRec;
          If NumRec > MaxPages Then MaxPages := NumRec;
          PathInd := 0;
          InfoRecChanged := False;
          FirstFreeChanged := False;
          SearchForSequentialEnabled := SearchForSequentialDefault;
          SequentialOK := False;
        End;
      End;
      If HeadOrIndCorrupted Then Begin
        UnDo ( 4, 10010 );
        Exit;
      End;
      DataBuffered := False;
      CharConvProc := BTNoCharConvert;                               {!!.50}
      CCHookPtr := Nil;                                              {!!.50}
      CCDestrWrite := True;                                          {!!.50}
      IsamAddToOpenFileBlockList ( IFBPtr );
      If Not IsamOK Then Begin
        UnDo ( 4, 10100 );
        Exit;
      End;
    End;
  End;


  Procedure IsamCloseRawFileBlock ( Var IFBPtr : IsamFileBlockPtr );

  Begin
    With IFBPtr^ Do Begin
      IsamDestroyPages ( IFBPtr );
      If NrOfKeys > 0 Then IsamClose ( IndF );
      IsamClose ( DatF );
      IsamFreeKeyDescrMem ( IFBPtr, NrOfKeys );
      IsamRemoveFromOpenFileBlockList ( IFBPtr );
      ValidSign := 0;
      FreeMem ( IFBPtr, SizeOf (IFBPtr^) );
      IFBPtr := Nil;
    End;
  End;


  Procedure IsamOpenFileBlock ( Var IFBPtr      : IsamFileBlockPtr;
                                    FName       : IsamFileBlockName;
                                    ReadOnly,
                                    AllReadOnly,
                                    Save,
                                    Net         : Boolean );

  Type
    DialogFileState = ( Correct, Raw, ToRepair );

  Var
    DiaFileState : DialogFileState;
    DiaFile      : IsamFile;
    DiaFOpened,
    DiaFExisted  : Boolean;
    FlagSet      : IsamFlagSet;
    FlagSetLen   : Word;                                            {!!.42}
    DiaFileLen   : LongInt;
    Ok,
    Dummy,
    UseDiaFile,
    UseLock,
    RealNet      : Boolean;
    DummyStr,
    FNameD,
    FNameI       : IsamFileBlockName;
    TIFBPtr      : IsamFileBlockPtr;


    Procedure UnDo ( Level : Word; Error : Integer );

    Var
      Dummy : Boolean;

    Begin
      If Level >= 4 Then Begin
        If Net Then FreeMem ( TIFBPtr^.NSP, SizeOf (IsamNetSupport) );
      End;
      If Level >= 3 Then Begin
        IsamCloseRawFileBlock ( TIFBPtr );
      End;
    {$IFNDEF NoNet}
      If Level >= 2 Then Begin
        If UseLock Then Dummy := IsamUnLockRecord ( 3, 1, DiaFile.Handle );
      End;
    {$ENDIF}
      If Level >= 1 Then Begin
        If DiaFOpened Then IsamClose ( DiaFile );
      End;
      If Not DiaFExisted Then Begin
        IsamDelete ( DiaFile );
      End;
      If Net Then Begin                                         {!!.42mod}
        If Error = 10140 Then Error := 10355;
      End;
      IsamError := Error;
      IsamOK := IsamError = 0;
    End;


    Function CheckDiaFile : DialogFileState;

    Var
      Len    : LongInt;
      Value  : Word;
      TestNr : Word;                                                {!!.42}
      Ok     : Boolean;                                             {!!.42}

    Begin
      CheckDiaFile := ToRepair;                                     {!!.31}
      IsamLongSeekEOF ( DiaFile, Len );
      If Not IsamOK Then Exit;
      If Len = 1 Then Begin
        CheckDiaFile := Raw;
      End Else Begin
        Value := 0;                                                 {!!.42}
        IsamGetBlock ( DiaFile, 1, SizeOf (Word), Value );          {!!.42}
        If IsamOK And (Value = 2000) Then Begin                     {!!.42}
        {--Is Len correct?}                                         {!!.42}
          TestNr := (Len - 3) Div FlagSetLen;                       {!!.42}
          If RealNet Then Begin                                     {!!.42}
            Ok := TestNr > 1;                                       {!!.42}
          End Else Begin                                            {!!.42}
            Ok := TestNr = 1;                                     {!!!!.42}
          End;                                                      {!!.42}
          If Ok Then Begin                                          {!!.42}
            If LongInt (TestNr) * FlagSetLen = (Len - 3) Then Begin {!!.42}
              CheckDiaFile := Correct;                              {!!.42}
              DiaFileLen := Len;                                    {!!.42}
              Exit;                                                 {!!.42}
            End;                                                    {!!.42}
          End;                                                      {!!.42}
        End;                                                        {!!.42}
      End;
      If ReadOnly And (UseDiaFile Or (Len <> 1)) Then Begin
        {-To use a dialog file in read only mode it must be correct;
          if it is used in read only mode, it's length has to be 1 (can
          only occur in single user mode "$Define NoNet")}
        IsamOK := False;
        IsamError := 10440;
      End;
    End;


  Begin
  {--Correct parameters}
    If AllReadOnly Then ReadOnly := True;
    If ReadOnly Then Save := False;
  {$IFDEF NoNet}
    Net := False;
  {$ENDIF}

  {--Set controlling values}
    RealNet := (IsamInitializedNet <> NoNet) And Net;
    UseLock := RealNet And Not AllReadOnly;
    If Net Then Begin
      UseDiaFile := Not AllReadOnly;
    End Else Begin
      UseDiaFile := Save;
    End;

  {--Set local values}
    IsamExtractFileNames ( FName, FNameD, FNameI );
    IsamExtractFileNames ( FNameI, FNameI, DummyStr );

  {--Open dialog file in specified mode}
    IsamAssign ( DiaFile, IsamForceExtension ( FNameD, DiaExtension ) );
    DiaFExisted := True;
    Repeat
      Ok := True;
      IsamReset ( DiaFile, RealNet, ReadOnly );
      DiaFOpened := IsamOK;
      If Not IsamOK Then Begin
        If IsamError = 9903 Then Begin
          DiaFExisted := False;
          IsamClearOK;
          If UseDiaFile Then Begin
            Ok := False;
            If ReadOnly Then Begin
              UnDo ( 0, 10440 );
              Exit;
            End Else Begin
              IsamMakeDiaFile ( DiaFile );
              If IsamOK Then IsamClose ( DiaFile );
              If Not IsamOK Then Begin
                UnDo ( 0, IsamError );
                Exit;
              End;
            End;
          End;
        End Else Begin
          UnDo ( 0, IsamError );
          Exit;
        End;
      End;
    Until Ok;

  {--Set lock on dialog file station 0 during open}
  {$IFNDEF NoNet}
    If UseLock Then Begin
      If Not IsamLockRecord ( 3, 1, DiaFile.Handle,
          IsamLockTimeOut * IsamFBLockTimeOutFactor,
          IsamDelayBetwLocks ) Then Begin
        UnDo ( 1, 10355 );
        Exit;
      End;
      If IsamLockRecord ( 3, 1, DiaFile.Handle, 0, 0 ) Then Begin    {!!.42}
        UnDo ( 2, 10480 );                                           {!!.42}
        Exit;                                                        {!!.42}
      End;                                                           {!!.42}
    End;                                                             {!!.42}
  {$ENDIF}

  {--Open data and index files and read headers}
    IsamOpenRawFileBlock ( TIFBPtr, FNameD, FNameI, RealNet, ReadOnly );
    If Not IsamOK Then Begin
      UnDo ( 2, IsamError );
      Exit;
    End;

  {--Set additional local values}
    FlagSetLen := Succ (Succ (TIFBPtr^.NrOfKeys) Shr 3);
    DiaFileLen :=
        LongInt (FlagSetLen) * Succ (LongInt (IsamDefNrOfWS)) + 3;  {!!.42}

  {--Check dialog file}
    If DiaFExisted Then Begin
      DiaFileState := CheckDiaFile;
      If Not IsamOK Then Begin
        UnDo ( 3, IsamError );
        Exit;
      End;
    End Else Begin
      If UseDiaFile Then Begin
        DiaFileState := Raw;
      End Else Begin
        DiaFileState := Correct;
      End;
    End;

  {--If we open a net fileblock with corrupted dialog file,
     then ensure that we are alone}
  {$IFNDEF NoNet}
    If (DiaFileState <> Correct) And UseLock Then Begin             {!!.42}
      If Not IsamEnsureOnlyWS ( DiaFile.Handle ) Then Begin         {!!.42}
        UnDo ( 3, 10360 );                                          {!!.42}
        Exit;                                                       {!!.42}
      End;                                                          {!!.42}
    End;                                                            {!!.42}
  {$ENDIF}

  {--Set fileblock and net support data}
    With TIFBPtr^ Do Begin
      DiaF := DiaFile;
      ReadOnlyFB := ReadOnly;
      SaveFB := Save;
      NSP := Nil;
    {$IFNDEF NoNet}
      If Net Then Begin
        If Not IsamAvailable ( SizeOf (IsamNetSupport) ) Then Begin
          UnDo ( 3, 10356 );
          Exit;
        End;
        GetMem ( NSP, SizeOf (IsamNetSupport) );
        With NSP^ Do Begin
          Locked := False;
          ReadLocked := False;
            {-FlagSetReadLocked only set or read by Isam(Entry/Exit)Code}
          FlagSetReadLocked := false;                               {!!.51}
          AllStationsReadOnly := AllReadOnly;
          ReloadAll := False;
          SaveFileBlockRepaired := False;
          DiaLenM3 := DiaFileLen - 3;
          SetLen := FlagSetLen;
          SupNrOfWS := Pred (DiaLenM3 Div SetLen);                  {!!.42}
          If RealNet And Not AllStationsReadOnly Then Begin
            IsamDetermineLocalWSNr ( DiaF.Handle, LocalWSNr,
                SupNrOfWS );                                        {!!.42}
            If Not IsamOK Then Begin
              UnDo ( 4, IsamError );
              Exit;
            End;
          End Else Begin
            LocalWSNr := 0;
          End;
          With LockEntryRec Do Begin
            Count := 0;
            Next := Nil;
          End;
        End;
      End;
    {$ENDIF}
    End;

  {--Repair fileblock and/or fill up flag sets if necessary}
    If DiaFileState <> Correct Then Begin
                                                                 {del!!.42}
    {--Repair fileblock if necessary}
      If DiaFileState = ToRepair Then Begin
        IsamRepairFileBlock ( TIFBPtr );
        If Not IsamOK Then Begin
                                                                 {del!!.42}
          UnDo ( 4, IsamError );
          Exit;
        End;
        DiaFileState := Raw;
      End;

    {--Fill up flag sets if necessary}
    {$IFNDEF NoNet}
      If Net Then Begin
        If DiaFileState = Raw Then Begin
          IsamFillFlagSet ( TIFBPtr, FlagSet );
          IsamPutFlagSet ( TIFBPtr, FlagSet );
          If IsamOK And Save And ((Not Net) Or IsamNetEmu) Then
              IsamFlushDOSDia ( TIFBPtr, False );
          If Not IsamOK Then Begin
                                                                 {del!!.42}
            UnDo ( 4, IsamError );
            Exit;
          End;
        End;
      End;
                                                                 {del!!.42}
    {$ENDIF}
  End;

  {--Release lock on dialog file}
  {$IFNDEF NoNet}
    If UseLock Then Begin
      If Not IsamUnLockRecord ( 3, 1, TIFBPtr^.DiaF.Handle ) Then Begin
        UnDo ( 4, 10342 );
        Exit;
      End;
    End;
  {$ENDIF}

  {--Close opened and not used dialog file}
    If Not UseDiaFile And DiaFOpened Then Begin
      IsamClose ( DiaFile );
    End;

  {--Delete dialog file if not necessary}
    If Not (UseDiaFile Or ReadOnly) And DiaFExisted Then Begin
      IsamDelete ( DiaFile );
    End;

  {--Final assigns of fileblock pointer}
    IFBPtr := TIFBPtr;
    IFBPtr^.ValidSign := IsamFBValidSign;
  End;


  Procedure IsamCloseFileBlock ( Var IFBPtr : IsamFileBlockPtr );

  Var
    Ok,
    UseDiaFile : Boolean;

  Begin
    If Not IsamFileBlockIsInOpenList ( IFBPtr ) Then Begin
      IsamOK := False;
      IsamError := 10080;
      Exit;
    End;
    With IFBPtr^ Do Begin
    {$IFNDEF NoNet}
      If NSP <> Nil Then Begin
        IsamUnLockAllRecs ( IFBPtr );
        If Not IsamOK Then Begin
          IsamError := 10323;
          Exit;
        End;
        With NSP^ Do Begin
          If Locked Or ReadLocked Then Begin
            ISUnLockFileBlock ( IFBPtr );
            If Not IsamOK Then Begin
              IsamError := 10322;
              Exit;
            End;
          End;
        End;
      End;
    {$ENDIF}
      If ((NSP = Nil) Or (IsamInitializedNet = NoNet)) And
          (Not (SaveFB Or ReadOnlyFB)) Then Begin
        {-Only real net and save fileblocks don't buffer}
        If NrOfKeys > 0 Then Begin
          IsamFlushPageInfo ( IFBPtr, True );
          If Not IsamOK Then Exit;
        End;
        IsamPutInfoRec ( IFBPtr, 0, False );
        If Not IsamOK Then Exit;
      End;

    {--Point of no return}

      Ok := True;
      If NSP <> Nil Then Begin
      {$IFNDEF NoNet}
        With NSP^ Do Begin
          If LocalWSNr <> 0 Then Begin
            IsamReleaseLocalWSNr ( DiaF.Handle, LocalWSNr );
            Ok := Ok And IsamOK;
          End;
          UseDiaFile := Not AllStationsReadOnly;
        End;
        FreeMem ( NSP, SizeOf (IsamNetSupport) );
      {$ENDIF}
      End Else Begin
        UseDiaFile := SaveFB;
      End;
      If UseDiaFile Then Begin
        IsamClose ( DiaF );
        Ok := Ok And IsamOK;
      End;
    End;
    IsamCloseRawFileBlock ( IFBPtr );
    IsamOK := Ok And IsamOK;
    If Not IsamOK Then IsamError := 10160;
  End;


  Procedure IsamCloseAllFileBlocks;

  Var
    T1Ptr,
    TPtr   : IsamOpenFileBlockListPtr;
    TFBPtr : IsamFileBlockPtr;
    Err    : Integer;

  Begin
    TPtr := IsamOFBLPtr;
    Err := 0;
    While TPtr <> Nil Do Begin
      With TPtr^ Do Begin
        T1Ptr := Next;
        TFBPtr := OIFBPtr;
        {-Must (!) be copied for TP6 heap manager compatibility;
          the open fileblock list entry is removed, so the field OIFBPtr is
          no longer valid afterwards (overwritten by heap internal data)}
        IsamCloseFileBlock ( TFBPtr );
        If Err = 0 Then Err := IsamError;
        IsamClearOK;
        TPtr := T1Ptr;
      End;
    End;
    IsamError := Err;
    IsamOK := IsamError = 0;
  End;


  Procedure IsamEntryCode ( IFBPtr : IsamFileBlockPtr; Options : Word );

  Var
    KeyNr : Byte;

  Begin
    IsamClearOK;
    If Not IsamIsInitialized Then Begin
      IsamOK := False;
      IsamError := 10455;
      Exit;
    End;
    If IsamIsCriticalActive Then Begin
      IsamOK := False;
      IsamError := 10446;
      Exit;
    End;
    If IFBPtr = Nil Then Begin
      IsamOK := False;
      IsamError := 10445;
      Exit;
    End;
    If IFBPtr <> Pointer (NotAFileBlockPtr) Then Begin
      With IFBPtr^ Do Begin
        If ValidSign <> IsamFBValidSign Then Begin
          IsamOK := False;
          IsamError := 10445;
          Exit;
        End;
        If ((Options And OptWriteRoutine) <> 0)                    {!!.41}
            And ReadOnlyFB Then Begin                              {!!.41}
          IsamOK := False;                                         {!!.41}
          IsamError := 10065;                                      {!!.41}
          Exit;                                                    {!!.41}
        End;                                                       {!!.41}
      {$IFNDEF NoNet}
        If (Options And OptCheckLock) <> 0 Then Begin
          If NSP <> Nil Then Begin
            If Not NSP^.Locked Then Begin
              IsamOK := False;
              IsamError := 10398;
              Exit;
            End;
          End;
        End;
      {$ENDIF}
        If (Options And OptKeyRoutine) <> 0 Then Begin
          KeyNr := Options And $00FF;
          If (KeyNr < 1) Or (KeyNr > NrOfKeys) Then Begin
            IsamOK := False;
            IsamError := 10164;
            Exit;
          End;
        End;
      {$IFNDEF NoNet}
        If NSP <> Nil Then Begin
          With NSP^ Do Begin
            FlagSetReadLocked := False;
            If (Options And OptReadPrefix) <> 0 Then Begin
              If Not (Locked Or ReadLocked Or AllStationsReadOnly) Then Begin
                IsamReadNetPrefix ( IFBPtr, False );
                If Not IsamOK Then Begin
                  If IsamError = 10140 Then IsamError := 10399;
                  Exit;
                End;
                FlagSetReadLocked := True;
              End;
            End;
          End;
        End;
      {$ENDIF}
      End;
    End;
  {$IFDEF UseEMSHeap}                                              {!!.41}
    If EMSHeapIsUsed Then Begin
      If IsamOK Then IsamIsCriticalActive := True;
    End;
  {$ENDIF}                                                         {!!.41}
  End;


  Procedure IsamExitCode ( IFBPtr : IsamFileBlockPtr );

  Begin
    If Not IsamIsInitialized Then Exit;
    If IsamError = 10445 Then Exit;
  {$IFDEF UseEMSHeap}
    If EMSHeapIsUsed Then Begin
      If UserSaveEMSHandle <> 0 Then Begin
      {$IFDEF EMSDisturbance}
        OwnSaveEMSHandle := SaveEMSCtxt;
      {$ENDIF}
        RestoreEMSCtxt ( UserSaveEMSHandle );
        UserSaveEMSHandle := 0;
      End;
    End;
  {$ENDIF}
    IsamIsCriticalActive := False;
    If IFBPtr <> Pointer (NotAFileBlockPtr) Then Begin
      If IsamError = 10140 Then Begin
        If IFBPtr^.ReadOnlyFB Then IsamError := 10397;
      End;
    {$IFNDEF NoNet}
      If IFBPtr^.NSP <> Nil Then Begin
        If IsamError = 10140 Then IsamError := 10397;
        With IFBPtr^.NSP^ Do Begin
          If FlagSetReadLocked Then Begin
            If Not IsamUnLockMyFlagSet ( IFBPtr ) Then Begin
              IsamOK := False;
              IsamError := 10341;
              Exit;
            End;
            FlagSetReadLocked := False;
          End;
        End;
      End;
    {$ENDIF}
    End;
  End;
