(**************************************************************)
(*          B-Tree Isam Include Ver 5.51                      *)
(*   Copyright (C) 1986-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

  Function BTInitIsam ( ExpectedNet      : NetSupportType;
                        Free             : LongInt;
                        NrOfEMSTreePages : Word ) : LongInt;
    {-Initializes B-Tree Isam;
      high word of LResult: pages on EMS heap;
      low word: pages on normal heap}
  Var
    Dummy  : Boolean;
    LResult : LongInt;                                          {!!.51}

  Begin
    If IsamIsInitialized Then Begin
      IsamOK := False;
      IsamError := 10450;
      Exit;
    End;
    ISInitIsam;
    BTInitIsam := 0;
  {$IFDEF NoNet}
    ExpectedNet := NoNet;
    IsamNetEmu := False;
  {$ELSE}
    If Not IsamInitNet ( ExpectedNet ) Then Begin
      If IsamOK Then Begin
        {-Do not overwrite any error code}
        IsamOK := False;
        IsamError := 10310;
      End;
      Exit;
    End;
    IsamNetEmu := ExpectedNet = NoNet;
  {$ENDIF}
    IsamInitializedNet := ExpectedNet;
  {$IFDEF UseEMSHeap}
    If Not EMSHeapInitialized Then Begin
      NrOfEMSTreePages := 0;
    End;
  {$ELSE}
    NrOfEMSTreePages := 0;
  {$ENDIF}
  {$IFDEF UseEMSHeap}
    If NrOfEMSTreePages > 0 Then Begin
      If SizeOf (IsamPageEntry) > 16384 Then Begin
      {$IFNDEF NoNet}
        Dummy := IsamExitNet;
      {$ENDIF}
        IsamOK := False;
        IsamError := 10435;
        Exit;
      End;
      UserSaveEMSHandle := SaveEMSCtxt;
    End;
  {$ENDIF}
    If Free < 0 Then Free := 0;
    LResult := IsamGetPageBuffer ( Free, NrOfEMSTreePages );    {!!.51}
    BTInitIsam := LResult;                                      {!!.51}
    If Not IsamOK Then Begin
    {$IFDEF UseEMSHeap}
      If NrOfEMSTreePages > 0 Then Begin
        RestoreEMSCtxt ( UserSaveEMSHandle );
        UserSaveEMSHandle := 0;
      End;
    {$ENDIF}
    {$IFNDEF NoNet}
      Dummy := IsamExitNet;
    {$ENDIF}
      Exit;
    End;
  {$IFDEF UseEMSHeap}
    EMSHeapIsUsed := ILI (LResult).Hi <> 0;                     {!!.51}
   {$IFDEF EMSDisturbance}
    If EMSHeapIsUsed Then OwnSaveEMSHandle := SaveEMSCtxt;
   {$ENDIF}
    If NrOfEMSTreePages > 0 Then Begin
      RestoreEMSCtxt ( UserSaveEMSHandle );
      UserSaveEMSHandle := 0;
    End;
  {$ELSE}
    EMSHeapIsUsed := False;
  {$ENDIF}
    IsamIsInitialized := True;
  End;


  Procedure BTExitIsam;
    {-Exits use of B-Tree Isam}
  Begin
    IsamClearOK;
    If Not IsamIsInitialized Then Begin
      IsamOK := False;
      IsamError := 10455;
      Exit;
    End;
    IsamCloseAllFileBlocks;
    If Not IsamOK Then Exit;
  {$IFDEF UseEMSHeap}
    If EMSHeapIsUsed Then Begin
      UserSaveEMSHandle := SaveEMSCtxt;
    {$IFDEF EMSDisturbance}
      RestoreEMSCtxt ( OwnSaveEMSHandle );
    {$ENDIF}
    End;
  {$ENDIF}
    IsamIsInitialized := False;
    IsamReleasePageBuffer;
  {$IFNDEF NoNet}
    If Not IsamExitNet Then Begin
      IsamOK := False;
      IsamError := 10315;
    End;
  {$ENDIF}
  {$IFDEF UseEMSHeap}
    If EMSHeapIsUsed Then RestoreEMSCtxt ( UserSaveEMSHandle );
  {$ENDIF}
  End;


  Function BTIsamErrorClass : Integer;
    {-Evaluates IsamError in error classes 0..4}
  Begin
    Case IsamError Of
      0 : Begin
        BTIsamErrorClass := 0;
      End;

      9903,
      10200..10299,
      10410 : Begin
        BTIsamErrorClass := 1;
      End;

      9900,
      10065,
      10110,
      10306,
      10330,
      10332,
      10335,
      10355,
      10360,                                                         {!!.42}
      10390,                                                         {!!.42}
      10397,
      10399 : Begin
        BTIsamErrorClass := 2;
      End;

      10001..10009 : Begin
        BTIsamErrorClass := 3;
      End;

      Else Begin
        BTIsamErrorClass := 4;
      End;
    End; {Case}
  End;


  Function BTNoNetCompiled : Boolean;
    {-Returns True, if B-Tree Isam was compiled without network support}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
  {$IFDEF NoNet}
    BTNoNetCompiled := True;
  {$ELSE}
    BTNoNetCompiled := False;
  {$ENDIF}
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Function BTPeekNoNetCompiled : Boolean;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekNoNetCompiled := BTNoNetCompiled;
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTNetSupported : NetSupportType;
    {-Returns the currently supported network}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    BTNetSupported := IsamInitializedNet;
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Function BTPeekNetSupported : NetSupportType;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekNetSupported := BTNetSupported;
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTFileBlockIsOpen ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Returns True, if the fileblock is currently open}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    BTFileBlockIsOpen := IsamFileBlockIsInOpenList ( IFBPtr );
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Function BTPeekFileBlockIsOpen ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekFileBlockIsOpen := BTFileBlockIsOpen ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTIsNetFileBlock ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Returns True, if the fileblock is a net fileblock}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
  {$IFDEF NoNet}
    BTIsNetFileBlock := False;
  {$ELSE}
    BTIsNetFileBlock := IFBPtr^.NSP <> Nil;
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekIsNetFileBlock ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekIsNetFileBlock := BTIsNetFileBlock ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTFileBlockIsLocked ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Returns True, if the fileblock is currently locked}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    BTFileBlockIsLocked := False;
  {$IFNDEF NoNet}
    If IFBPtr^.NSP <> Nil Then BTFileBlockIsLocked := IFBPtr^.NSP^.Locked;
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekFileBlockIsLocked ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekFileBlockIsLocked := BTFileBlockIsLocked ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTFileBlockIsReadLocked ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Returns True, if the fileblock is currently readlocked}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    BTFileBlockIsReadLocked := False;
  {$IFNDEF NoNet}
    If IFBPtr^.NSP <> Nil Then
        BTFileBlockIsReadLocked := IFBPtr^.NSP^.ReadLocked;
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekFileBlockIsReadLocked ( IFBPtr : IsamFileBlockPtr )
                                                                 : Boolean;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekFileBlockIsReadLocked := BTFileBlockIsReadLocked ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Procedure BTReadLockFileBlock ( IFBPtr : IsamFileBlockPtr );
    {-Readlocks the fileblock IFBPtr^}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
  {$IFNDEF NoNet}
    If IsamOK Then ISReadLockFileBlock ( IFBPtr );
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTLockFileBlock ( IFBPtr : IsamFileBlockPtr );
    {-Locks the fileblock IFBPtr^}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
  {$IFNDEF NoNet}
    If IsamOK Then ISLockFileBlock ( IFBPtr );
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTUnLockFileBlock ( IFBPtr : IsamFileBlockPtr );
    {-Unlocks the fileblock IFBPtr^}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
  {$IFNDEF NoNet}
    If IsamOK Then ISUnLockFileBlock ( IFBPtr );
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTUnLockAllOpenFileBlocks;
    {-Unlocks all open fileblocks}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
  {$IFNDEF NoNet}
    If IsamOK Then ISUnLockAllOpenFileBlocks;
  {$ENDIF}
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTReadLockAllOpenFileBlocks;
    {-Readlocks all open fileblocks}
  Var
    TPtr : IsamOpenFileBlockListPtr;
    Err  : Integer;

  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
  {$IFNDEF NoNet}
    If IsamOK Then Begin
      TPtr := IsamOFBLPtr;
      While (TPtr <> Nil) And IsamOK Do Begin
        ISReadLockFileBlock ( TPtr^.OIFBPtr );
        If Not IsamOK Then Begin
          Err := IsamError;
          ISUnLockAllOpenFileBlocks;
          IsamOK := False;
          IsamError := Err;
        End;
        TPtr := TPtr^.Next;
      End;
    End;
  {$ENDIF}
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTLockAllOpenFileBlocks;
    {-Locks all open fileblocks}
  Var
    TPtr : IsamOpenFileBlockListPtr;
    Err  : Integer;

  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
  {$IFNDEF NoNet}
    If IsamOK Then Begin
      TPtr := IsamOFBLPtr;
      While (TPtr <> Nil) And IsamOK Do Begin
        ISLockFileBlock ( TPtr^.OIFBPtr );
        If Not IsamOK Then Begin
          Err := IsamError;
          ISUnLockAllOpenFileBlocks;
          IsamOK := False;
          IsamError := Err;
        End;
        TPtr := TPtr^.Next;
      End;
    End;
  {$ENDIF}
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTGetRecordInfo (     IFBPtr     : IsamFileBlockPtr;
                                  Ref        : LongInt;
                              Var Start, Len : LongInt;
                              Var Handle     : Word );
    {-Returns information about record Ref}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then Begin
      With IFBPtr^, DIDPtr^[0]^ Do Begin
        Start := Ref * LenRec;
        Len := LenRec;
        Handle := DatF.Handle;
      End;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTPeekGetRecordInfo (     IFBPtr     : IsamFileBlockPtr;
                                      Ref        : LongInt;
                                  Var Start, Len : LongInt;
                                  Var Handle     : Word );
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTGetRecordInfo ( IFBPtr, Ref, Start, Len, Handle );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Procedure BTLockRec ( IFBPtr : IsamFileBlockPtr; Ref : LongInt );
    {-Locks record Ref}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
  {$IFNDEF NoNet}
    If IsamOK And (IFBPtr^.NSP <> Nil) Then ISLockRec ( IFBPtr, Ref );
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTUnLockRec ( IFBPtr : IsamFileBlockPtr; Ref : LongInt );
    {-Unlocks record Ref}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
  {$IFNDEF NoNet}
    If IsamOK And (IFBPtr^.NSP <> Nil) Then ISUnLockRec ( IFBPtr, Ref );
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTUnLockAllRecs ( IFBPtr : IsamFileBlockPtr );
    {-Unlocks all locked records of IFBPtr^}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
  {$IFNDEF NoNet}
    If IsamOK And (IFBPtr^.NSP <> Nil) Then IsamUnLockAllRecs ( IFBPtr );
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Function BTRecIsLocked ( IFBPtr : IsamFileBlockPtr; Ref : LongInt )
                                                                    : Boolean;
    {-Returns whether the record Ref is locked}
  Var
    RefPtr    : LongPtr;
    Dummy1Ptr,
    Dummy2Ptr : IsamLockEntryRecPtr;

  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    BTRecIsLocked  := False;
  {$IFNDEF NoNet}
    If IsamOK And (IFBPtr^.NSP <> Nil) Then Begin
      IsamIsInLockList ( @IFBPtr^.NSP^.LockEntryRec, Ref, RefPtr,
          False, Dummy1Ptr, Dummy2Ptr );                            {!!.42}
      BTRecIsLocked := RefPtr <> Nil;
    End;
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekRecIsLocked ( IFBPtr : IsamFileBlockPtr; Ref : LongInt )
                                                                    : Boolean;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekRecIsLocked := BTRecIsLocked ( IFBPtr, Ref );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTaRecIsLocked ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Returns whether a record is locked}

  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    BTaRecIsLocked  := False;
  {$IFNDEF NoNet}
    If IsamOK And (IFBPtr^.NSP <> Nil) Then Begin
      BTaRecIsLocked  := IFBPtr^.NSP^.LockEntryRec.Count > 0;
    End;
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekaRecIsLocked ( IFBPtr : IsamFileBlockPtr ) : Boolean;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekaRecIsLocked := BTaRecIsLocked ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Procedure BTInformTTSAbortSuccessful ( IFBPtr : IsamFileBlockPtr );
    {-Resets all internal data to nothing buffered and no lock at all}

  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
  {$IFNDEF NoNet}
    If IsamOK And (IFBPtr^.NSP <> Nil) Then Begin
      With IFBPtr^.NSP^ Do Begin
        If Locked Then Begin
          If IsamUnLockAllFlagSets ( IFBPtr ) Then;
          Locked := False;
        End;
        If ReadLocked Then Begin
          If IsamUnLockMyFlagSet ( IFBPtr ) Then;
          ReadLocked := False;
        End;
        While LockEntryRec.Count > 0 Do Begin
          ISUnLockRec ( IFBPtr, LockEntryRec.EntryArr [1] );
          IsamClearOK;
        End;
        ReloadAll := True;
      End;
    End;
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Function BTSetDosRetry ( NrOfRetries, WaitTime : Integer ) : Boolean;
    {-Sets number of retries and delay time between on locks and accesses
      in a MicroSoft compatible network}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
  {$IFDEF NoNet}
    BTSetDosRetry := IsamOK;
  {$ELSE}
    BTSetDosRetry := IsamSetDosRetry ( NrOfRetries, WaitTime );
  {$ENDIF}
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTForceWritingMark ( FFM : Boolean );
    {-Forces to write the "modify mark" to disk}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    IsamForceFlushOfMark := FFM;
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTForceNetBufferWriteThrough ( DoIt : Boolean );
    {-With DoIt = True the save mode tries to suppress all buffering in a
      network or multitasking environment}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    IsamNetEmu := DoIt;
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTGetRec (     IFBPtr  : IsamFileBlockPtr;
                           RefNr   : LongInt;
                       Var Dest;
                           ISOLock : Boolean );
    {-Gets the specified record from the given reference}
  Var
    Options : Word;

  Begin
    If ISOLock Then Begin
      Options := NoOptions;
    End Else Begin
      Options := OptReadPrefix;
    End;
    IsamEntryCode ( IFBPtr, Options );
    If IsamOK Then IsamGetRec ( IFBPtr, RefNr, Dest );
    If IsamOK Then Begin                                             {!!.50}
      IFBPtr^.CharConvProc ( @Dest, IFBPtr^.DIDPtr^[0]^.LenRec,      {!!.50}
          True, IFBPtr^.CCHookPtr );                                 {!!.50}
    End;                                                             {!!.50}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTGetRecReadOnly (     IFBPtr  : IsamFileBlockPtr;
                                   RefNr   : LongInt;
                               Var Dest              );
    {-Gets the specified record from the given reference even if it's locked}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then IsamGetRecReadOnly ( IFBPtr, RefNr, Dest );
    If IsamOK Or (IsamError = 10205) Then Begin                      {!!.50}
      IFBPtr^.CharConvProc ( @Dest, IFBPtr^.DIDPtr^[0]^.LenRec,      {!!.50}
          True, IFBPtr^.CCHookPtr );                                 {!!.50}
    End;                                                             {!!.50}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTGetStartingLong (     IFBPtr  : IsamFileBlockPtr;      {!!.42}
                                    RefNr   : LongInt;
                                Var Dest    : LongInt );
    {-Gets the first four bytes of the specified record with the given
      reference}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then IsamGetStartingLong ( IFBPtr, RefNr, Dest );
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTPutRec (     IFBPtr  : IsamFileBlockPtr;
                           RefNr   : LongInt;
                       Var Source;
                           ISOLock : Boolean );
    {-Puts the specified record at the given reference}
  Var
    Options : Word;

  Begin
    If ISOLock Then Begin
      Options := OptWriteRoutine;                                    {!!.41}
    End Else Begin
      Options := OptCheckLock Or OptWriteRoutine;                    {!!.41}
    End;
    IsamEntryCode ( IFBPtr, Options );
    If IsamOK Then Begin
      IFBPtr^.CharConvProc ( @Source, IFBPtr^.DIDPtr^[0]^.LenRec,    {!!.50}
          False, IFBPtr^.CCHookPtr );                                {!!.50}
      IsamPutRec ( IFBPtr, RefNr, Source );                          {!!.50}
      If Not IFBPtr^.CCDestrWrite Then Begin                         {!!.50}
        IFBPtr^.CharConvProc ( @Source, IFBPtr^.DIDPtr^[0]^.LenRec,  {!!.50}
            True, IFBPtr^.CCHookPtr );                               {!!.50}
      End;                                                           {!!.50}
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTAddRec (     IFBPtr : IsamFileBlockPtr;
                       Var RefNr  : LongInt;
                       Var Source                );
    {-Adds a record to the given fileblock and returns the reference}
  Begin
    IsamEntryCode ( IFBPtr, OptCheckLock Or OptWriteRoutine );       {!!.41}
    If IsamOK Then Begin
      IFBPtr^.CharConvProc ( @Source, IFBPtr^.DIDPtr^[0]^.LenRec,    {!!.50}
          False, IFBPtr^.CCHookPtr );                                {!!.50}
      IsamAddRec ( IFBPtr, RefNr, Source );
      If Not IFBPtr^.CCDestrWrite Then Begin                         {!!.50}
        IFBPtr^.CharConvProc ( @Source, IFBPtr^.DIDPtr^[0]^.LenRec,  {!!.50}
            True, IFBPtr^.CCHookPtr );                               {!!.50}
      End;                                                           {!!.50}
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTDeleteRec ( IFBPtr : IsamFileBlockPtr; RefNr : LongInt );
    {-Deletes the record with reference RefNr}
  Begin
    IsamEntryCode ( IFBPtr, OptCheckLock Or OptWriteRoutine );       {!!.41}
    If IsamOK Then IsamDeleteRec ( IFBPtr, RefNr );
    IsamExitCode ( IFBPtr );
  End;


  Function BTUsedRecs ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Returns the number of currently used records}
  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix );
    If IsamOK Then Begin
      With IFBPtr^.DIDPtr^[0]^ Do Begin
        BTUsedRecs := NumRec - NumberFree;
      End;
    End Else Begin
      BTUsedRecs := 0;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTFreeRecs ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Returns the number of currently not used records}
  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix );
    If IsamOK Then Begin
      BTFreeRecs := IFBPtr^.DIDPtr^[0]^.NumberFree;
    End Else Begin
      BTFreeRecs := 0;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTFileLen ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Returns the number of currently occupied records by this fileblock}
  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix );
    If IsamOK Then Begin
      BTFileLen := Succ (IFBPtr^.DIDPtr^[0]^.NumRec);
    End Else Begin
      BTFileLen := 0;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTUsedKeys ( IFBPtr : IsamFileBlockPtr; Key : Word ) : LongInt;
    {-Returns the number of currently used keys of the specified number}
  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix Or OptKeyRoutine Or Key);
    If IsamOK Then Begin
      BTUsedKeys := IFBPtr^.DIDPtr^[Key]^.NumKeys;
    End Else Begin
      BTUsedKeys := 0;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTNrOfKeys ( IFBPtr : IsamFileBlockPtr ) : Word;
    {-Returns the number of defined keys}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then Begin
      BTNrOfKeys := IFBPtr^.NrOfKeys;
    End Else Begin
      BTNrOfKeys := 0;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekNrOfKeys ( IFBPtr : IsamFileBlockPtr ) : Word;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekNrOfKeys := BTNrOfKeys ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTDatRecordSize ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Returns the lenght of a data record}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then Begin
      BTDatRecordSize := IFBPtr^.DIDPtr^[0]^.LenRec;
    End Else Begin
      BTDatRecordSize := 0;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekDatRecordSize ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekDatRecordSize := BTDatRecordSize ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTKeyRecordSize ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Returns the maximum number of bytes used for a following key adding}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then Begin
      BTKeyRecordSize := IFBPtr^.BlockLen;
    End Else Begin
      BTKeyRecordSize := 0;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekKeyRecordSize ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekKeyRecordSize := BTKeyRecordSize ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTMinimumDatKeys ( IFBPtr : IsamFileBlockPtr; Space : LongInt )
                                                                 : LongInt;
    {-Returns the minimum number of data (including keys), that can be placed
      on a disk having Space bytes free Space}
  Var
    Nr,
    BL,
    LR : LongInt;
    PS : Word;

  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then Begin
      With IFBPtr^ Do Begin                                          {!!.42}
        BL := BlockLen;
        LR := DIDPtr^[0]^.LenRec;                                    {!!.42}
        If NrOfKeys > 0 Then Begin                                   {!!.42}
          PS := DIDPtr^[1]^.UsedPageSize;                            {!!.42}
        End Else Begin                                               {!!.42}
          PS := CreatePageSize;                                      {!!.42}
        End;                                                         {!!.42}
      End;
      Nr := (Space - 2 * BL - LR)                                    {!!.42}
          Div (LR + BL Div LongInt (PS Shr 1));
      If Nr < 0 Then Begin
        BTMinimumDatKeys := 0;
      End Else Begin
        BTMinimumDatKeys := Nr;
      End;
    End Else Begin
      BTMinimumDatKeys := 0;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekMinimumDatKeys ( IFBPtr : IsamFileBlockPtr;
                                  Space  : LongInt ) : LongInt;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekMinimumDatKeys := BTMinimumDatKeys ( IFBPtr, Space );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Procedure BTSetSearchForSequential ( IFBPtr : IsamFileBlockPtr;
                                       Key    : Word;
                                       ToOn  : Boolean ); {!!.TP}
    {-Enables search mode in sequential key operations}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or Key);
    If IsamOK Then IFBPtr^.DIDPtr^[Key]^.SearchForSequentialEnabled := ToOn; {!!.TP}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTGetSearchForSequential (     IFBPtr : IsamFileBlockPtr;
                                           Key    : Word;
                                       Var SFS    : Boolean );
    {-Tests search mode for sequential key operations}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or Key);
    If IsamOK Then SFS := IFBPtr^.DIDPtr^[Key]^.SearchForSequentialEnabled;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTFindRecRef (     IFBPtr                  : IsamFileBlockPtr;
                           Var UserDatRef              : LongInt;
                               NotFoundSearchDirection : Integer );  {!!.42}

  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix );
    If IsamOK Then Begin
      IsamFindRecRef ( IFBPtr, UserDatRef, NotFoundSearchDirection );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTNextRecRef (     IFBPtr     : IsamFileBlockPtr;
                           Var UserDatRef : LongInt );               {!!.42}

  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix );
    If IsamOK Then Begin
      Inc (UserDatRef);
      IsamFindRecRef ( IFBPtr, UserDatRef, 1 );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTPrevRecRef (     IFBPtr     : IsamFileBlockPtr;
                           Var UserDatRef : LongInt );               {!!.42}

  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix );
    If IsamOK Then Begin
      Dec (UserDatRef);
      IsamFindRecRef ( IFBPtr, UserDatRef, -1 );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTGetApprRecPos (     IFBPtr     : IsamFileBlockPtr;
                              Var RelPos     : Word;
                                  Scale      : Word;
                                  UserDatRef : LongInt );            {!!.42}

  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix );
    If IsamOK Then Begin
      IsamGetApprRecPos ( IFBPtr, RelPos, Scale, UserDatRef );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTGetApprRecRef (     IFBPtr     : IsamFileBlockPtr;
                                  RelPos     : Word;
                                  Scale      : Word;
                              Var UserDatRef : LongInt );            {!!.42}

  Begin
    IsamEntryCode ( IFBPtr, OptReadPrefix );
    If IsamOK Then Begin
      IsamGetApprRecRef ( IFBPtr, RelPos, Scale, UserDatRef );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTClearKey ( IFBPtr : IsamFileBlockPtr; Key : Word );
    {-Places the internal sequential pointer to a null position}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then IsamClearKey ( IFBPtr, Key );
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTNextKey (     IFBPtr     : IsamFileBlockPtr;
                            Key        : Word;
                        Var UserDatRef : LongInt;
                        Var UserKey    : IsamKeyStr    );
    {-Returns in UserKey / UserDatRef the value and reference number of the
      next key}

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then Begin                                          {!!.41}
      If IFBPtr^.DIDPtr^[Key]^.PathInd = 0 Then Begin             {!!.41}
        {-Key was cleared by a previous operation}                {!!.41}
        IsamClearKey ( IFBPtr, Key );                             {!!.41}
          {-Clear it again to allow sequential access}            {!!.41}
      End;                                                        {!!.41}
      IsamNextKey ( IFBPtr, Key, UserDatRef, UserKey );
    End;                                                          {!!.41}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTPrevKey (     IFBPtr     : IsamFileBlockPtr;
                            Key        : Word;
                        Var UserDatRef : LongInt;
                        Var UserKey    : IsamKeyStr       );
    {-Returns in UserKey / UserDatRef the value and reference number of the
      previous key}

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then Begin                                          {!!.41}
      If IFBPtr^.DIDPtr^[Key]^.PathInd = 0 Then Begin             {!!.41}
        {-Key was cleared by a previous operation}                {!!.41}
        IsamClearKey ( IFBPtr, Key );                             {!!.41}
          {-Clear it again to allow sequential access}            {!!.41}
      End;                                                        {!!.41}
      IsamPrevKey ( IFBPtr, Key, UserDatRef, UserKey );
    End;                                                          {!!.41}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTFindKey (     IFBPtr     : IsamFileBlockPtr;
                            Key        : Word;
                        Var UserDatRef : LongInt;
                            UserKey    : IsamKeyStr       );
    {-Returns in UserDatRef the reference number of the specified key}
  Var
    TempKey  : IsamKeyStr;
  {$IFDEF ASCIIZeroKeys}
    TempKeyZ : IsamKeyStr;
  {$ENDIF}
  {$IFDEF LengthByteKeys}
    TempKeyZ : IsamKeyStr absolute UserKey;
  {$ENDIF}

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then Begin
    {$IFDEF ASCIIZeroKeys}
      IsamMakeStrZ ( UserKey, TempKeyZ );
    {$ENDIF}
      UserDatRef := 0;
      IsamFindKey ( IFBPtr, Key, UserDatRef, TempKeyZ );
      If (Not IsamOK) And (IsamError = 0)
          And IFBPtr^.DIDPtr^[Key]^.AllowDupKeys Then Begin
        IsamClearOK;
        IsamNextKey ( IFBPtr, Key, UserDatRef, TempKey );
        IsamOK := IsamOK And (UserKey = TempKey);
      End;
      If Not IsamOK Then Begin
        Case IsamError Of
          0, 10200..10299 : IsamError := 10200;
        End; {Case}
      End;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTSearchKey (     IFBPtr     : IsamFileBlockPtr;
                              Key        : Word;
                          Var UserDatRef : LongInt;
                          Var UserKey    : IsamKeyStr    );
    {-Returns in UserKey / UserDatRef the value and reference number of the
      via UserKey specified or the following key}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then IsamSearchKey ( IFBPtr, Key, UserDatRef, UserKey );
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTFindKeyAndRef (     IFBPtr                  : IsamFileBlockPtr;
                                  Key                     : Word;
                              Var UserDatRef              : LongInt;
                              Var UserKey                 : IsamKeyStr;
                                  NotFoundSearchDirection : Integer );
    {-Returns in UserKey / UserDatRef the value and reference number of the
      via UserKey / UserDatRef specified combination.
      NotFoundSearchDirection determines whether and where to search for a
      result in case nothing was found}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then IsamFindKeyAndRef ( IFBPtr, Key, UserDatRef, UserKey,
        NotFoundSearchDirection );
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTSearchKeyAndRef (     IFBPtr     : IsamFileBlockPtr;
                                    Key        : Word;
                                Var UserDatRef : LongInt;
                                Var UserKey    : IsamKeyStr );
    {-Returns in UserKey / UserDatRef the value and reference number of the
      via UserKey / UserDatRef specified combination.
      In case nothing was found a following result is searched. If this does
      not exist, a previous combination is searched}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then Begin
      IsamFindKeyAndRef ( IFBPtr, Key, UserDatRef, UserKey, 1 );
      If IsamError = 10250 Then Begin
        IsamClearOK;
        IsamPrevKey ( IFBPtr, Key, UserDatRef, UserKey );
      End;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTKeyExists ( IFBPtr     : IsamFileBlockPtr;
                         Key        : Word;
                         UserDatRef : LongInt;
                         UserKey    : IsamKeyStr    ) : Boolean;
    {-Returns True, if the combination UserKey / UserDatRef exists}
  Var
    C, K, L, R : Integer;
    IPgPtr     : IsamPagePtr;
    ADK        : Boolean;
  {$IFDEF ASCIIZeroKeys}
    TempKeyZ : IsamKeyStr;
  {$ENDIF}
  {$IFDEF LengthByteKeys}
    TempKeyZ : IsamKeyStr absolute UserKey;
  {$ENDIF}


    Procedure Search ( PRef : LongInt );

    Begin
      If PRef = 0 Then Begin
        Exit;
      End Else Begin
        IsamGetPage ( IFBPtr, PRef, Key, IPgPtr );
        If Not IsamOK Then Exit;
        With IPgPtr^ Do Begin
          L := 1;
          R := ItemsOnPage;
          ADK := IFBPtr^.DIDPtr^[Key]^.AllowDupKeys;
          Repeat
            K := ( L + R ) Shr 1;
            C := IsamCompKeys ( TempKeyZ,
                                ItemArray [K].KeyStr,
                                UserDatRef,
                                ItemArray [K].DataRef,
                                (UserDatRef <> 0) And ADK );
              {-UserDatRef=0 means search independent of the data reference,
                even if ADK is true}
            If C <= 0 Then R := Pred (K);
            If C >= 0 Then L := Succ (K);
          Until L > R;
          If L - R > 1 Then Begin
            BTKeyExists := True;
          End Else Begin
            If R = 0 Then Begin
              Search ( BckwPageRef );
            End Else Begin
              Search ( ItemArray [R].PageRef );
            End;
          End;
        End;
      End;
    End;


  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    BTKeyExists := False;
    If IsamOK Then Begin
    {$IFDEF ASCIIZeroKeys}
      IsamMakeStrZ ( UserKey, TempKeyZ );
    {$ENDIF}
      Search ( IFBPtr^.DIDPtr^[Key]^.RootRef );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTNextDiffKey (     IFBPtr     : IsamFileBlockPtr;
                                Key        : Word;
                            Var UserDatRef : LongInt;
                            Var UserKey    : IsamKeyStr    );
    {-Returns in UserKey / UserDatRef the value and reference number of the
      next from UserKey different key}
  Var
    I : Integer;

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then Begin
    {$IFDEF LengthByteKeys}
      If Length ( UserKey ) < IFBPtr^.DIDPtr^[Key]^.KeyLen Then Begin
        UserKey := UserKey + #0;
      End Else Begin
        I := IFBPtr^.DIDPtr^[Key]^.KeyLen;
        Repeat
          UserKey [I] := Succ ( UserKey [I] );
          Dec (I);
        Until ( I = 0 ) Or ( UserKey [Succ (I)] <> #0 );
        If UserKey [Succ (I)] = #0 Then Begin
          IsamClearKey ( IFBPtr, Key );
          IsamOK := False;
          IsamError := 10240;
        End;
      End;
    {$ENDIF}
    {$IFDEF ASCIIZeroKeys}
      If Length ( UserKey ) < IFBPtr^.DIDPtr^[Key]^.KeyLen Then Begin
        UserKey := UserKey + #1;
      End Else Begin
        I := IFBPtr^.DIDPtr^[Key]^.KeyLen;
        Repeat
          Inc ( UserKey [I] );
          If UserKey [I] = #0 Then Inc (UserKey [I]);
          I := Pred (I);
        Until ( I = 0 ) Or ( UserKey [Succ (I)] <> #1 );
        If UserKey [Succ (I)] = #1 Then Begin
          IsamClearKey ( IFBPtr, Key );
          IsamOK := False;
          IsamError := 10240;
          Exit;
        End;
      End;
    {$ENDIF}
    End;
    If IsamOK Then Begin
      IsamSearchKey ( IFBPtr, Key, UserDatRef, UserKey );
      If Not IsamOK Then Begin
        Case IsamError Of
          0, 10200..10299 : IsamError := 10240;
        End; {Case}
      End;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTPrevDiffKey (     IFBPtr     : IsamFileBlockPtr;
                                Key        : Word;
                            Var UserDatRef : LongInt;
                            Var UserKey    : IsamKeyStr    );
    {-Returns in UserKey / UserDatRef the value and reference number of the
      privious from UserKey different key}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then Begin
      IsamSearchKey ( IFBPtr, Key, UserDatRef, UserKey );
      Case IsamError Of
        0, 10200..10299 : Begin
          IsamClearOK;
          IsamPrevKey ( IFBPtr, Key, UserDatRef, UserKey );
          If IsamError = 10260 Then IsamError := 10245;
        End;
      End; {Case}
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTAddKey ( IFBPtr     : IsamFileBlockPtr;
                       Key        : Word;
                       UserDatRef : LongInt;
                       UserKey    : IsamKeyStr    );
    {-Adds the combination UserKey / UserDatRef to the tree}
  Var
  {$IFDEF ASCIIZeroKeys}
    TempKeyZ : IsamKeyStr;
  {$ENDIF}
  {$IFDEF LengthByteKeys}
    TempKeyZ : IsamKeyStr absolute UserKey;
  {$ENDIF}

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptCheckLock Or Key
        Or OptWriteRoutine );                                    {!!.41}
    If IsamOK Then Begin
      If Length ( UserKey ) <= IFBPtr^.DIDPtr^[Key]^.KeyLen Then Begin
      {$IFDEF ASCIIZeroKeys}
        IsamMakeStrZ ( UserKey, TempKeyZ );
      {$ENDIF}
        IsamAddKey ( IFBPtr, Key, UserDatRef, TempKeyZ );
        If IFBPtr^.SaveFB Then Begin
          If IsamError = 0 Then Begin
            IsamReduceDiaFile ( IFBPtr );
          End Else Begin
            IsamRepairFileBlock ( IFBPtr );
            If IsamOK Then Begin
              IsamOK := False;
              IsamError := 10003;
            End;
          End;
          IsamResetSaveBuffered;
        End;
        If Not IsamOK And (IsamError = 0) Then IsamError := 10230;
      End Else Begin
        IsamOK := False;
        IsamError := 10125;
      End;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTDeleteKey ( IFBPtr     : IsamFileBlockPtr;
                          Key        : Word;
                          UserDatRef : LongInt;
                          UserKey    : IsamKeyStr    );
    {-Deletes the combination UserKey / UserDatRef in the tree}
  Var
  {$IFDEF ASCIIZeroKeys}
    TempKeyZ : IsamKeyStr;
  {$ENDIF}
  {$IFDEF LengthByteKeys}
    TempKeyZ : IsamKeyStr absolute UserKey;
  {$ENDIF}

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptCheckLock Or Key
        Or OptWriteRoutine );                                    {!!.41}
    If IsamOK Then Begin
    {$IFDEF ASCIIZeroKeys}
      IsamMakeStrZ ( UserKey, TempKeyZ );
    {$ENDIF}
      IsamDeleteKey ( IFBPtr, Key, UserDatRef, TempKeyZ );
      If IFBPtr^.SaveFB Then Begin
        If IsamError = 0 Then Begin
          IsamReduceDiaFile ( IFBPtr );
        End Else Begin
          IsamRepairFileBlock ( IFBPtr );
          If IsamOK Then Begin
            IsamOK := False;
            IsamError := 10004;
          End;
        End;
        IsamResetSaveBuffered;
      End;
      If Not IsamOK And (IsamError = 0) Then IsamError := 10220;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTDeleteAllKeys ( IFBPtr : IsamFileBlockPtr; Key : Word );
    {-Deletes all keys with number Key}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptCheckLock Or Key
        Or OptWriteRoutine );                                    {!!.41}
    If IsamOK Then Begin
      IsamDeleteAllKeys ( IFBPtr, Key );
      If IFBPtr^.SaveFB Then Begin
        If IsamOK Then Begin
          IsamReduceDiaFile ( IFBPtr );
        End Else Begin
          IsamRepairFileBlock ( IFBPtr );
          If IsamOK Then Begin
            IsamOK := False;
            IsamError := 10005;
          End;
        End;
      End;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTOtherWSChangedKey ( IFBPtr : IsamFileBlockPtr;
                                 Key    : Word ) : Boolean;
    {-Returns True, if it is definite, that a key of number Key was changed
      by another workstation}
  Var
    FlagSet : IsamFlagSet;
    Dummy,
    Valid   : Boolean;
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or Key );
    BTOtherWSChangedKey := False;
  {$IFNDEF NoNet}
    If IsamOK Then Begin
      If IFBPtr^.NSP <> Nil Then Begin
        With IFBPtr^.NSP^ Do Begin
          If Not (Locked Or ReadLocked) Then Begin
            IsamLockAndGetFlagSet ( IFBPtr, FlagSet, Valid );
            If IsamOK And Valid Then Begin
              BTOtherWSChangedKey  := Key In FlagSet;
              Dummy := IsamUnLockMyFlagSet ( IFBPtr );
            End;
          End;
        End;
      End;
    End;
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTGetApprRelPos (     IFBPtr     : IsamFileBlockPtr;
                                  Key        : Word;
                              Var RelPos     : Word;
                                  Scale      : Word;
                                  UserKey    : IsamKeyStr;
                                  UserDatRef : LongInt );
    {-Returns in RelPos the approximate relative position of the combination
      UserKey / UserDatRef in 0..Scale}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then
        IsamGetApprRelPos ( IFBPtr, Key, RelPos, Scale, UserKey, UserDatRef );
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTGetApprKeyAndRef (     IFBPtr     : IsamFileBlockPtr;
                                     Key,
                                     RelPos     : Word;
                                     Scale      : Word;
                                 Var UserKey    : IsamKeyStr;
                                 Var UserDatRef : LongInt );
    {-Returns the combination UserKey / UserDatRef, that is approximately
      at the position RelPos in 0..Scale}
  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or OptReadPrefix Or Key );
    If IsamOK Then Begin
      IsamGetApprKeyAndRef ( IFBPtr, Key, RelPos, Scale, UserKey, UserDatRef );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTFlushAllFileBlocks;
    {-Flushes all new data of all fileblocks to disk}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    If IsamOK Then IsamFlushAllFileBlocks;
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTFlushFileBlock ( IFBPtr : IsamFileBlockPtr );
    {-Flushes all new data of this fileblocks to disk}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then IsamFlushFileBlock ( IFBPtr );
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTDeleteFileBlock ( FName : IsamFileBlockName );
    {-Deletes a fileblock}

  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    If IsamOK Then IsamDeleteFileBlock ( FName );
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTCreateFileBlock ( FName        : IsamFileBlockName;
                                DatSLen      : LongInt;
                                NumberOfKeys : Word;
                                IID          : IsamIndDescr );
    {-Creates a closed fileblock}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    If IsamOK Then
        IsamCreateFileBlock ( FName, DatSLen, NumberOfKeys, IID );
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTOpenFileBlock ( Var IFBPtr      : IsamFileBlockPtr;
                                  FName       : IsamFileBlockName;
                                  ReadOnly,
                                  AllReadOnly,
                                  Save,
                                  Net         : Boolean );
    {-Opens a fileblock}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    If IsamOK Then
        IsamOpenFileBlock ( IFBPtr, FName, ReadOnly, AllReadOnly, Save,
        Net );
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTCloseFileBlock ( Var IFBPtr : IsamFileBlockPtr );
    {-Closes a fileblock}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then IsamCloseFileBlock ( IFBPtr );
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Procedure BTCloseAllFileBlocks;
    {-Closes all open fileblocks}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    If IsamOK Then IsamCloseAllFileBlocks;
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Function BTDataFileName ( IFBPtr : IsamFileBlockPtr ) : IsamFileName;
    {-Returns the name of the data file including path and extension}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then Begin
      BTDataFileName := IsamGetFileName ( IFBPtr^.DatF );
    End Else Begin
      BTDataFileName := '';
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekDataFileName ( IFBPtr : IsamFileBlockPtr ) : IsamFileName;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekDataFileName := BTDataFileName ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTIndexFileName ( IFBPtr : IsamFileBlockPtr ) : IsamFileName;
    {-Returns the name of the index file including path and extension}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    BTIndexFileName := '';
    If IsamOK Then Begin
      If IFBPtr^.NrOfKeys > 0 Then Begin
        BTIndexFileName := IsamGetFileName ( IFBPtr^.IndF );
      End;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTPeekIndexFileName ( IFBPtr : IsamFileBlockPtr ) : IsamFileName;
    {-Just like the routine without "Peek", but not destroying the previous
      error on success}
  Var
    ErrSt : ErrStatSaveRec;

  Begin
    SaveErrorStat ( ErrSt );
    BTPeekIndexFileName := BTIndexFileName ( IFBPtr );
    If IsamOK Then RestoreErrorStat ( ErrSt );
  End;


  Function BTGetNextUsedAddRecRef ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Returns the data reference, that is used for adding the next record;
      this function is of a more internal nature}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    BTGetNextUsedAddRecRef := 0;
    If IsamOK Then Begin
      BTGetNextUsedAddRecRef :=
          IsamGetNextUsedAddRecRef ( IFBPtr );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTGetAfterNextUsedAddRecRef ( IFBPtr : IsamFileBlockPtr ) : LongInt;
    {-Returns the data reference, that is used after adding the next record;
      this function is of a more internal nature}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    BTGetAfterNextUsedAddRecRef := 0;
    If IsamOK Then Begin
      BTGetAfterNextUsedAddRecRef :=
          IsamGetAfterNextUsedAddRecRef ( IFBPtr );
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTGetInternalDialogID ( IFBPtr : IsamFileBlockPtr ) : Word;
    {-Returns the internal ID used by network accesss to this fileblock}

  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    BTGetInternalDialogID := 0;
  {$IFNDEF NoNet}
    If IsamOK Then Begin                                             {!!.42}
      If IFBPtr^.NSP <> Nil Then Begin
        BTGetInternalDialogID := IFBPtr^.NSP^.LocalWSNr;
      End;
    End;                                                             {!!.42}
  {$ENDIF}
    IsamExitCode ( IFBPtr );
  End;


  Function BTGetAllowDupKeys ( IFBPtr : IsamFileBlockPtr;            {!!.50}
                               KeyNr  : Word ) : Boolean;

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or KeyNr );
    BTGetAllowDupKeys := False;
    If IsamOK Then Begin
      BTGetAllowDupKeys := IFBPtr^.DIDPtr^[KeyNr]^.AllowDupKeys;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTGetKeyLen ( IFBPtr : IsamFileBlockPtr;                  {!!.50}
                         KeyNr  : Word ) : Word;

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or KeyNr );
    BTGetKeyLen := 0;
    If IsamOK Then BTGetKeyLen := IFBPtr^.DIDPtr^[KeyNr]^.KeyLen;
    IsamExitCode ( IFBPtr );
  End;


  Procedure BTNoCharConvert ( DataPtr  : Pointer;                    {!!.50}
                              DataLen  : LongInt;
                              PostRead : Boolean;
                              HookPtr  : Pointer );

  Begin
  End;


  Procedure BTSetCharConvert ( IFBPtr     : IsamFileBlockPtr;        {!!.50}
                               CCProc     : ProcBTCharConvert;
                               HookPtr    : Pointer;
                               DestrWrite : Boolean );

  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    If IsamOK Then Begin
      With IFBPtr^ Do Begin
        CharConvProc := CCProc;
        CCHookPtr := HookPtr;
        CCDestrWrite := DestrWrite;
      End;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function BTIsInitialized : Boolean;                                {!!.50}

  Begin
    BTIsInitialized := IsamIsInitialized;
  End;


(*****************************************************************************)
{--Compatibility calls}
  Function BTIsamLockRecord ( Start,
                              Len       : LongInt;
                              Handle ,
                              TimeOut,
                              DelayTime : Word ) : Boolean;
    {-Locks bytes Start to Start - Len + 1 in the file
      with handle Handle}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    BTIsamLockRecord := True;
  {$IFNDEF NoNet}
    If IsamOK Then Begin
      BTIsamLockRecord := IsamLockRecord ( Start, Len, Handle,
          TimeOut, DelayTime );
    End;
  {$ENDIF}
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Function BTIsamUnLockRecord ( Start,
                                Len    : LongInt;
                                Handle : Word     ) : Boolean;
    {-Unlocks bytes Start to Start - Len + 1 in the file
      with handle Handle}
  Begin
    IsamEntryCode ( Pointer (NotAFileBlockPtr), NoOptions );
    BTIsamUnLockRecord := True;
  {$IFNDEF NoNet}
    If IsamOK Then BTIsamUnLockRecord := IsamUnLockRecord ( Start, Len,
        Handle );
  {$ENDIF}
    IsamExitCode ( Pointer (NotAFileBlockPtr) );
  End;


  Function BTIsamGetSequentialOK ( IFBPtr : IsamFileBlockPtr;        {!!.50}
                                   KeyNr  : Word ) : Boolean;

  Begin
    IsamEntryCode ( IFBPtr, OptKeyRoutine Or KeyNr );
    BTIsamGetSequentialOK := False;
    If IsamOK Then Begin
      BTIsamGetSequentialOK := IFBPtr^.DIDPtr^[KeyNr]^.SequentialOK;
    End;
    IsamExitCode ( IFBPtr );
  End;


  Function IsamGetNumRecAddress ( IFBPtr : IsamFileBlockPtr ) : Pointer;
                                                                     {!!.50}
  Begin
    IsamEntryCode ( IFBPtr, NoOptions );
    IsamGetNumRecAddress := Nil;
    If IsamOK Then Begin
      IsamGetNumRecAddress := @IFBPtr^.DIDPtr^[0]^.NumRec;
    End;
    IsamExitCode ( IFBPtr );
  End;