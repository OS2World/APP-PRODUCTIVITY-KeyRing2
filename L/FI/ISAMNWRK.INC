(**************************************************************)
(*          B-Tree Isam Include Ver 5.51                      *)
(*   Copyright (C) 1987-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

  Procedure IsamResetIRChangedSaveN ( IFBPtr : IsamFileBlockPtr );

  Var
    I : Integer;

  Begin
    With IFBPtr^ Do Begin
      For I := 0 To NrOfKeys Do Begin
        DIDPtr^[I]^.IRChangedSaveN := False;
      End;
    End;
  End;


  Function IsamAddLockToReadLock ( IFBPtr : IsamFileBlockPtr ) : Boolean;

  Var
    Dummy : Boolean;

  Begin
    IsamAddLockToReadLock := False;
    With IFBPtr^, NSP^ Do Begin
      If LocalWSNr > 0 Then Begin
        If Not IsamLockRecord ( 3, LocalWSNr * SetLen,
            DiaF.Handle, 0, 0 ) Then Exit;
      End;
      If LocalWSNr < SupNrOfWS Then Begin
        If Not IsamLockRecord ( Succ (LocalWSNr) * SetLen + 3,
            (SupNrOfWS - LocalWSNr) * SetLen, DiaF.Handle, 0, 0 )
            Then Begin
          If LocalWSNr > 0 Then Begin
            Dummy := IsamUnLockRecord ( 3, LocalWSNr * SetLen,
                DiaF.Handle );
          End;
          Exit;
        End;
      End;
    End;
    IsamAddLockToReadLock := True;
  End;


  Procedure IsamSubLockFromReadLock ( IFBPtr : IsamFileBlockPtr );

  Var
    Dummy : Boolean;

  Begin
    With IFBPtr^, NSP^ Do Begin
      If LocalWSNr < SupNrOfWS Then Begin
        Dummy := IsamUnLockRecord ( Succ (LocalWSNr) * SetLen + 3,
            (SupNrOfWS - LocalWSNr) * SetLen, DiaF.Handle );
      End;
      If LocalWSNr > 0 Then Begin
        Dummy := IsamUnLockRecord ( 3, LocalWSNr * SetLen, DiaF.Handle );
      End;
    End;
  End;


  Procedure IsamIsInLockList (     FirstLEntryPtr : IsamLockEntryRecPtr;
                                   Ref            : LongInt;
                               Var RefPtr         : LongPtr;
                                   SearchEnd      : Boolean;
                               Var LEntryPtr      : IsamLockEntryRecPtr;
                               Var PrevPtr        : IsamLockEntryRecPtr );
                                                                   {!!.42}
  Var
    Found,
    Stop  : Boolean;
    I     : Integer;

  Begin
    RefPtr := Nil;
    LEntryPtr := FirstLEntryPtr;                                    {!!.42}
    PrevPtr := Nil;
    Found := False;
    Repeat
      With LEntryPtr^ Do Begin
        I := 1;
        While (I <= Count) And Not Found Do Begin
          Found := EntryArr [I] = Ref;
          If Found Then Begin
            RefPtr := @EntryArr [I];
          End Else Begin
            Inc (I);
          End;
        End;
      End;
      Stop := LEntryPtr^.Next = Nil;
      If Not (Stop Or Found) Then Begin
        PrevPtr := LEntryPtr;
        LEntryPtr := LEntryPtr^.Next;
      End;
    Until Found Or Stop;
    If Stop Or Not (Found And SearchEnd) Then Exit;
    Repeat
      Stop := LEntryPtr^.Next = Nil;
      If Not Stop Then Begin
        PrevPtr := LEntryPtr;
        LEntryPtr := LEntryPtr^.Next;
      End;
    Until Stop;
  End;


  Function IsamAddToLockList ( FirstLEntryPtr : IsamLockEntryRecPtr;
                               Ref            : LongInt ) : Boolean;
                                                                    {!!.42}
  Var
    DummyPtr,
    ILERPtr  : IsamLockEntryRecPtr;
    RefPtr   : LongPtr;

  Begin
    IsamAddToLockList := False;
    IsamIsInLockList ( FirstLEntryPtr, Ref, RefPtr, False, ILERPtr,
        DummyPtr );                                                 {!!.42}
    If RefPtr <> Nil Then Exit;
    If ILERPtr^.Count < MaxLockEntries Then Begin
      Inc (ILERPtr^.Count);
    End Else Begin
      If Not IsamAvailable ( SizeOf (IsamLockEntryRec) ) Then Begin
        IsamOK := False;
        IsamError := 10337;
        Exit;
      End;
      GetMem ( ILERPtr^.Next, SizeOf (IsamLockEntryRec) );
      ILERPtr := ILERPtr^.Next;
      ILERPtr^.Count := 1;
      ILERPtr^.Next := Nil;
    End;
    ILERPtr^.EntryArr [ILERPtr^.Count] := Ref;
    IsamAddToLockList := True;
  End;


  Function IsamRemoveFromLockList ( FirstLEntryPtr : IsamLockEntryRecPtr;
                                    Ref            : LongInt ) : Boolean;
                                                                    {!!.42}
  Var
    PrevPtr,
    ILERPtr : IsamLockEntryRecPtr;
    RefPtr  : LongPtr;

  Begin
    IsamRemoveFromLockList := False;
    IsamIsInLockList ( FirstLEntryPtr, Ref, RefPtr, True, ILERPtr,
        PrevPtr );                                                  {!!.42}
    If RefPtr = Nil Then Exit;
    With ILERPtr^ Do Begin
      RefPtr^ := EntryArr [Count];
      Dec (Count);
      If (Count = 0) And (PrevPtr <> Nil) Then Begin
        PrevPtr^.Next := Nil;
        FreeMem ( ILERPtr, SizeOf (IsamLockEntryRec) );
      End;
    End;
    IsamRemoveFromLockList := True;
  End;


  Procedure ISLockRec ( IFBPtr : IsamFileBlockPtr; Ref : LongInt );

  Begin
    With IFBPtr^, DIDPtr^[0]^ Do Begin
      If Not IsamAddToLockList ( @IFBPtr^.NSP^.LockEntryRec, Ref )
          Then Exit;                                                {!!.42}
        {-Either record is already locked or heap space doen't suffice}
      IsamOK := IsamLockRecord ( Ref * LenRec, SizeOf (LongInt),
          DatF.Handle, IsamLockTimeOut, IsamDelayBetwLocks );
      If Not IsamOK Then Begin
        If IsamRemoveFromLockList ( @IFBPtr^.NSP^.LockEntryRec, Ref )
            Then;                                                   {!!.42}
        IsamError := 10335;
      End;
    End;
  End;


  Procedure ISUnLockRec ( IFBPtr : IsamFileBlockPtr; Ref : LongInt );

  Begin
    With IFBPtr^, DIDPtr^[0]^ Do Begin
      If Not IsamRemoveFromLockList ( @IFBPtr^.NSP^.LockEntryRec, Ref )
          Then Exit;                                                {!!.42}
        {-Already unlocked}
      IsamOK := IsamUnLockRecord ( Ref * LenRec, SizeOf (LongInt),
          DatF.Handle );
      If Not IsamOK Then IsamError := 10345;
        {-No attempt is made to mark the lock again, the system forgot this
          lock, what is an hard error}
    End;
  End;


  Procedure IsamUnLockAllRecs ( IFBPtr : IsamFileBlockPtr );

  Begin
    With IFBPtr^, NSP^, LockEntryRec Do Begin
      While Count > 0 Do Begin
        ISUnLockRec ( IFBPtr, EntryArr [1] );
        If Not IsamOK Then Exit;
      End;
    End;
  End;


  Function IsamLockAllFlagSets ( IFBPtr : IsamFileBlockPtr ) : Boolean;

  Begin
    IsamLockAllFlagSets := IsamLockRecord ( 3, IFBPtr^.NSP^.DiaLenM3,
        IFBPtr^.DiaF.Handle, IsamLockTimeOut * IsamFBLockTimeOutFactor,
        IsamDelayBetwLocks );
  End;


  Function IsamUnLockAllFlagSets ( IFBPtr : IsamFileBlockPtr ) : Boolean;

  Begin
    IsamUnLockAllFlagSets := IsamUnLockRecord ( 3, IFBPtr^.NSP^.DiaLenM3,
        IFBPtr^.DiaF.Handle );
  End;


  Procedure IsamLockMyFlagSet ( IFBPtr : IsamFileBlockPtr );

  Begin
    With IFBPtr^, NSP^ Do Begin
      IsamOK := IsamLockRecord ( LongInt (LocalWSNr) * LongInt (SetLen)
          + LongInt (3), SetLen, DiaF.Handle, IsamLockTimeOut,
          IsamDelayBetwLocks );
      If Not IsamOK Then IsamError := 10140;
    End;
  End;


  Function IsamUnLockMyFlagSet ( IFBPtr : IsamFileBlockPtr ) : Boolean;

  Begin
    With IFBPtr^, NSP^ Do Begin
      IsamUnLockMyFlagSet := IsamUnLockRecord
          ( LongInt (LocalWSNr) * LongInt (SetLen) + LongInt (3),
          SetLen, DiaF.Handle );
    End;
  End;


  Procedure IsamFillFlagSet (     IFBPtr  : IsamFileBlockPtr;
                              Var FlagSet : IsamFlagSet );

  Begin
    FillChar ( FlagSet, IFBPtr^.NSP^.SetLen, $FF );
  End;


  Procedure IsamResetMyFlagSet ( IFBPtr : IsamFileBlockPtr );

  Var
    FlagSet : IsamFlagSet;

  Begin
    With IFBPtr^, NSP^ Do Begin
      FillChar ( FlagSet, SetLen, 0 );
      IsamPutBlock ( DiaF,
          LongInt (LocalWSNr) * LongInt (SetLen) + LongInt (3),
          SetLen, FlagSet );
    End;
  End;


  Procedure IsamBuildFlagSet (     IFBPtr  : IsamFileBlockPtr;
                               Var FlagSet : IsamFlagSet    );

  Var
    I : Integer;

  Begin
    With IFBPtr^, NSP^ Do Begin
      If SaveFileBlockRepaired Then Begin
        SaveFileBlockRepaired := False;
        IsamFillFlagSet ( IFBPtr, FlagSet );
        Exit;
      End;
      If DataBuffered Then Begin
        FlagSet := [Succ (NrOfKeys)];
        For I := 0 To NrOfKeys Do Begin
          With DIDPtr^[I]^ Do Begin
            If InfoRecChanged Or IRChangedSaveN Then FlagSet := FlagSet + [I];
          End;
        End;
      End Else Begin
        FlagSet := [];
      End;
    End;
  End;


  Procedure IsamPutFlagSet (     IFBPtr  : IsamFileBlockPtr;
                             Var FlagSet : IsamFlagSet    );

  Var
    BufRec : Record
      IST    : Integer;
      Buffer : Array [0..512] Of Byte;
    End;
    I,
    BufInd,
    MaxBuf,
    AktWs,
    RestWs     : Word;
    FSComp,
    EndOfPut,
    StartOfPut : Boolean;
    BufCont,
    DiaPos     : LongInt;
    FS         : Array [0..31] Of Byte Absolute FlagSet;


    Function FlagSetComplete : Boolean;

    Var
      I : Integer;

    Begin
      FlagSetComplete := False;
      For I := 0 To IFBPtr^.NrOfKeys Do Begin
        If Not (I In FlagSet) Then Exit;
      End;
      FlagSetComplete := True;
    End;


  Begin
    With IFBPtr^, NSP^, BufRec Do Begin
      IST := 2000;       {net info}
      Buffer [0] := 0;   {net emulation}
      BufInd := SetLen;  {at least 1 Byte free}
      StartOfPut := True;
      EndOfPut := False;
      MaxBuf := SizeOf (Buffer) Div SetLen;
      AktWs := 1;
      DiaPos := 3;
      RestWs := Succ (SupNrOfWS);
      FSComp := FlagSetComplete;
      Repeat
        If RestWs > MaxBuf Then Begin
          BufCont := LongInt (MaxBuf) * LongInt (SetLen);
        End Else Begin
          BufCont := LongInt (RestWs) * LongInt (SetLen);
          EndOfPut := True;
        End;
        If Not FSComp Then Begin
          IsamGetBlock ( DiaF, DiaPos, BufCont, Buffer );
          If Not IsamOK Then Exit;
        End;
        While BufInd < ILI (BufCont).Lo Do Begin
          If AktWs = LocalWSNr Then Begin
            FillChar ( Buffer [BufInd], SetLen, 0 );
          End Else Begin
            For I := BufInd To Pred ( BufInd + SetLen ) Do Begin
              Buffer [I] := Buffer [I] Or FS [I-BufInd];
            End;
          End;
          BufInd := BufInd + SetLen;
          Inc (AktWs);
        End;
        BufInd := 0;
        If StartOfPut Then Begin
          StartOfPut := False;
          IsamPutBlock ( DiaF, 1, BufCont + 2, IST );
        End Else Begin
          IsamPutBlock ( DiaF, DiaPos, BufCont, Buffer );
        End;
        If EndOfPut Or Not IsamOK Then Exit;
        DiaPos := DiaPos + BufCont;
        RestWs := RestWs - MaxBuf;
      Until False;
    End;
  End;


  Procedure IsamBuildAndPutFlagSetFlushNewData ( IFBPtr  : IsamFileBlockPtr );

  Var
    FlagSet : IsamFlagSet;
    ModMark : Boolean;

  Begin
    With IFBPtr^ Do Begin
      If SaveFB Then Begin
        IsamFillFlagSet ( IFBPtr, FlagSet );
        DIDPtr^[0]^.InfoRecChanged := False;
      End Else Begin
        If Not DataBuffered Then Exit;
        IsamBuildFlagSet ( IFBPtr, FlagSet );
        IsamFlushPageInfo ( IFBPtr, False );
        If Not IsamOK Then Exit;
        If DIDPtr^[0]^.InfoRecChanged Or DIDPtr^[0]^.IRChangedSaveN Then Begin
          IsamPutInfoRec ( IFBPtr, 0, False );
          If Not IsamOK Then Exit;
          DIDPtr^[0]^.InfoRecChanged := False;
        End Else Begin
          ModMark := False;
          IsamPutBlock ( DatF, 20, 1, ModMark );
          If Not IsamOK Then Exit;
        End;
      End;
    End;
    IsamPutFlagSet ( IFBPtr, FlagSet );
  End;


  Procedure IsamGetFlagSet ( Var IFBPtr   : IsamFileBlockPtr;
                             Var FlagSet  : IsamFlagSet;
                             Var Valid    : Boolean;
                                 ReadOnce : Boolean );

  Var
    Buffer : Record
      Dummy : Byte;
      Value : Word;
      Buf   : Array [0..508] Of Byte;
    End;
    NrToRead : Word;

  Begin
    With IFBPtr^, NSP^ Do Begin
      If ReadOnce Then Begin
        NrToRead := Succ (LongInt(LocalWSNr)) * LongInt (SetLen)
            + LongInt (3);
        If NrToRead <= SizeOf (Buffer) Then Begin
          IsamGetBlock ( DiaF, 0, NrToRead, Buffer );
          If Not IsamOK Then Exit;
          Valid := Buffer.Value = 2000;
          If Not Valid Then Exit;
          Move ( Buffer.Buf [LongInt (LocalWSNr) * LongInt (SetLen)],
              FlagSet, SetLen );
        End Else Begin
          ReadOnce := False;
        End;
      End;
      If Not ReadOnce Then Begin
        IsamGetBlock ( DiaF, 0, 3, Buffer );
        If Not IsamOK Then Exit;
        Valid := Buffer.Value = 2000;
        If Not Valid Then Exit;
        IsamGetBlock ( DiaF, LongInt (LocalWSNr) * LongInt (SetLen)
            + LongInt (3), SetLen, FlagSet );
      End;
    End;
  End;


  Procedure IsamLockAndGetFlagSet (     IFBPtr  : IsamFileBlockPtr;
                                    Var FlagSet : IsamFlagSet;
                                    Var Valid   : Boolean     );

  Begin
    IsamLockMyFlagSet ( IFBPtr );
    If Not IsamOK Then Exit;
    IsamGetFlagSet ( IFBPtr, FlagSet, Valid, False );
  End;


  Procedure IsamReactOnFlagSet (     IFBPtr  : IsamFileBlockPtr;
                                 Var FlagSet : IsamFlagSet );

  Var
    Dummy : Boolean;
    I     : Integer;

  Begin
    With IFBPtr^ Do Begin
      If Not (Succ (NrOfKeys) In FlagSet) Then Exit;
      If Not ReadOnlyFB Then IsamResetMyFlagSet ( IFBPtr );
      If Not IsamOK Then Begin
        NSP^.ReloadAll := True;
        Exit;
      End;
      For I := 0 To NrOfKeys Do Begin
        If I In FlagSet Then Begin
          IsamGetInfoRec ( IFBPtr, I, Dummy );
          If Not IsamOK Then Begin
            NSP^.ReloadAll := True;
            Exit;
          End;
          If I > 0 Then Begin
            With DIDPtr^[I]^ Do Begin
              SequentialOK := False;
              If NumRec > MaxPages Then Begin
                MaxPages := NumRec;
              End;
            End;
            IsamDestroyPagesOfKeyNr ( IFBPtr, I );
          End;
        End;
      End;
    End;
  End;


  Procedure IsamReadNetPrefix ( IFBPtr : IsamFileBlockPtr;
                                Locked : Boolean   );

  Var
    Dummy,
    Valid   : Boolean;
    FlagSet : IsamFlagSet;


    Procedure UnDo ( Error : Integer );

    Begin
      If Not Locked Then Begin
        Dummy := IsamUnLockMyFlagSet ( IFBPtr );
        IsamSubLockFromReadLock ( IFBPtr );
      End;
      IsamOK := False;
      IsamError := Error;
    End;


  Begin
    If Locked Then Begin
      IsamGetFlagSet ( IFBPtr, FlagSet, Valid, True );
    End Else Begin
      IsamLockAndGetFlagSet ( IFBPtr, FlagSet, Valid );
    End;
    If IsamError = 10140 Then Begin
      UnDo ( IsamError );
      Exit;
    End;
    If Not (Valid And IsamOK) Then Begin
      IsamClearOK;
      If Not Locked Then Begin
        If Not IsamAddLockToReadLock ( IFBPtr ) Then Begin
          UnDo ( 10330 );
          Exit;
        End;
      End;
      IsamRepairFileBlock ( IFBPtr );
      If Not IsamOK Then Begin
        UnDo ( IsamError );
        Exit;
      End;
      IsamFillFlagSet ( IFBPtr, FlagSet );
      IsamReactOnFlagSet ( IFBPtr, FlagSet );
      If Not IsamOK Then Begin
        UnDo ( IsamError );
        Exit;
      End;
      If Locked And IFBPtr^.SaveFB Then Begin
        IFBPtr^.NSP^.SaveFileBlockRepaired := True;
      End Else Begin
        IsamPutFlagSet ( IFBPtr, FlagSet );
        If Not IsamOK Then Begin
          UnDo ( IsamError );
          Exit;
        End;
      End;
      If Not Locked Then IsamSubLockFromReadLock ( IFBPtr );
      Exit;
    End;
    With IFBPtr^.NSP^ Do Begin
      If ReloadAll Then Begin
        IsamFillFlagSet ( IFBPtr, FlagSet );
        ReloadAll := False;
      End;
    End;
    IsamReactOnFlagSet ( IFBPtr, FlagSet );
  End;


  Procedure ISReadLockFileBlock ( IFBPtr : IsamFileBlockPtr );

  Begin
    If IFBPtr^.NSP <> Nil Then Begin
      With IFBPtr^, NSP^ Do Begin
        If Not AllStationsReadOnly Then Begin
          If Not ReadLocked Then Begin
            If Locked Then Begin
              If Not ReadOnlyFB Then Begin
                IsamBuildAndPutFlagSetFlushNewData ( IFBPtr );
              End;
              If IsamOK Then Begin
                IsamOK := IsamUnLockAllFlagSets ( IFBPtr );
                If Not IsamOK Then Begin
                  IsamError := 10340;
                End Else Begin
                  Locked := False;
                  If Not IsamNetEmu Then DataBuffered := False;
                End;
              End;
            End;
            If IsamOK And Not Locked Then Begin
              IsamReadNetPrefix ( IFBPtr, False );
              If IsamOK Then Begin
                ReadLocked := True;
              End Else Begin
                If IsamError = 10140 Then IsamError := 10332;
              End;
            End;
          End;
        End;
      End;
    End;
  End;


  Procedure ISLockFileBlock ( IFBPtr : IsamFileBlockPtr );

  Var
    Dummy : Boolean;

  Begin
    If IFBPtr^.NSP <> Nil Then Begin
      With IFBPtr^, NSP^ Do Begin
        If Not AllStationsReadOnly Then Begin
          If Not Locked Then Begin
            If ReadLocked Then Begin
              If IsamUnLockMyFlagSet ( IFBPtr ) Then Begin
                ReadLocked := False;
              End Else Begin
                IsamOK := False;
                IsamError := 10340;
              End;
            End;
            If IsamOK And Not ReadLocked Then Begin
              If IsamLockAllFlagSets ( IFBPtr ) Then Begin
                IsamReadNetPrefix ( IFBPtr, True );
                If Not IsamOK Then Begin
                  Dummy := IsamUnLockAllFlagSets ( IFBPtr );
                End;
              End Else Begin
                IsamOK := False;
                IsamError := 10330;
              End;
            End;
            If IsamOK Then Begin
              If SaveFB Then Begin
                IsamReduceDiaFile ( IFBPtr );
                If Not IsamOK Then Begin
                  Dummy := IsamUnLockAllFlagSets ( IFBPtr );
                End;
              End;
              If IsamOK Then Begin
                Locked := True;
                IsamResetIRChangedSaveN ( IFBPtr );
              End;
            End;
          End;
        End;
      End;
    End;
  End;


  Procedure ISUnLockFileBlock ( IFBPtr : IsamFileBlockPtr );

  Begin
    If IFBPtr^.NSP <> Nil Then Begin
      With IFBPtr^, NSP^ Do Begin
        If Not AllStationsReadOnly Then Begin
          If Not Locked Then Begin
            If ReadLocked Then Begin
              If IsamUnLockMyFlagSet ( IFBPtr ) Then Begin
                ReadLocked := False;
              End Else Begin
                IsamOK := False;
                IsamError := 10340;
              End;
            End;
          End Else Begin
            If Not ReadOnlyFB Then Begin
              IsamBuildAndPutFlagSetFlushNewData ( IFBPtr );
            End;
            If IsamOK Then Begin
              If IsamUnLockAllFlagSets ( IFBPtr ) Then Begin
                Locked := False;
                If Not IsamNetEmu Then DataBuffered := False;
              End Else Begin
                IsamOK := False;
                IsamError := 10340;
              End;
            End;
          End;
        End;
      End;
    End;
  End;


  Procedure ISUnLockAllOpenFileBlocks;

  Var
    TPtr : IsamOpenFileBlockListPtr;
    Err  : Integer;
    OK   : Boolean;

  Begin
    OK := True;
    TPtr := IsamOFBLPtr;
    While TPtr <> Nil Do Begin
      ISUnLockFileBlock ( TPtr^.OIFBPtr );
      If Not IsamOK Then Err := IsamError;
      OK := OK And IsamOK;
      TPtr := TPtr^.Next;
    End;
    If Not OK Then Begin
      IsamOK := False;
      IsamError := Err;
    End;
  End;


  Procedure IsamReleaseLocalWSNr ( FHandle,
                                   LocalWSNr : Word );

  Const
    StartPos = $7FFFFFFF;

  Begin
    If Not IsamUnLockRecord ( StartPos - LocalWSNr, 1, FHandle ) Then Begin
      IsamOK := False;
      IsamError := 10341;
    End;
  End;


  Procedure IsamDetermineLocalWSNr (     FHandle   : Word;
                                     Var LocalWSNr : Word;
                                         SupNrOfWS : Word );        {!!.42}

  Const
    StartPos = $7FFFFFFF;

  Var
    FirstPos : Word;

  Begin
    If SupNrOfWS <> 0 Then Begin                                    {!!.42}
      Randomize;
      FirstPos := Succ (Random (SupNrOfWS));                        {!!.42}
      LocalWSNr := FirstPos;
      Repeat
        If IsamLockRecord ( StartPos - LocalWSNr, 1, FHandle, 0, 0 ) Then Exit;
        Dec (LocalWSNr);
        If LocalWSNr = 0 Then LocalWSNr := SupNrOfWS;               {!!.42}
      Until LocalWSNr = FirstPos;
    End;
    IsamOK := False;
    IsamError := 10306;
  End;


  Function IsamEnsureOnlyWS ( FHandle : Word ) : Boolean;           {!!.42}

  Const
    StartPos = $7FFFFFFF;
    MaxWS    = $FFFE;

  Var
    OnlyWS : Boolean;

  Begin
    OnlyWS := IsamLockRecord ( StartPos - MaxWS, Succ (MaxWS),
        FHandle, 0, 0 );
    If OnlyWS Then If IsamUnLockRecord ( StartPos - MaxWS, Succ (MaxWS),
        FHandle ) Then;
    IsamEnsureOnlyWS := OnlyWS;
  End;
