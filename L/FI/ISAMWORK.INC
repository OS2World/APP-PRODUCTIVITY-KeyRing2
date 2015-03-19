(**************************************************************)
(*          B-Tree Isam Include Ver 5.51                      *)
(*   Copyright (C) 1986-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

{$IFDEF LengthByteKeys}
  Procedure IsamMakeStrZ ( Var UserKey, UserKeyZ : IsamKeyStr );

  Begin
    Move ( UserKey, UserKeyZ, Succ (Word (Length (UserKey))) );
  End;


  Procedure IsamMakeStr ( Var UserKeyZ, UserKey : IsamKeyStr );

  Begin
    Move ( UserKeyZ, UserKey, Succ (Word (Length (UserKeyZ))) );
  End;
{$ENDIF}

{$IFDEF ASCIIZeroKeys}
  Procedure IsamMakeStrZ ( Var UserKey, UserKeyZ : IsamKeyStr );

  Var
    L : Word;

  Begin
    L := Length (UserKey);
    If L > MaxKeyLen Then L := MaxKeyLen;
    Move ( UserKey [1], UserKeyZ, L );
    UserKeyZ [L] := #0;
  End;


  Procedure IsamMakeStr ( Var UserKeyZ, UserKey : IsamKeyStr );

  Var
    L : Word;

  Begin
    L := 0;
    While UserKeyZ [L] <> #0 Do Begin
      Inc (L);
    End;
    If L <> 0 Then Begin
      Move ( UserKeyZ, UserKey [1], L );
    End;
    UserKey [0] := Chr (L);
  End;
{$ENDIF}

  Procedure IsamPack ( Var Page : IsamPage; KeyL : Word );

  Var
    I, K, S : Word;
    P       : Array [0..0] Of Byte absolute Page; {Real bounds [0..65535]}

  Begin
    K := KeyL + 9;
    S := K + 6;
    If KeyL <> MaxKeyLen Then Begin
      For I := 2 To Page.ItemsOnPage Do Begin
        Move ( Page.ItemArray [I], P [S], K );
        Inc (S, K);
      End;
    End;
  End;


  Procedure IsamUnPack ( Var Page : IsamPage; KeyL : Word );

  Var
    I, K, S : Word;
    P       : Array [0..0] Of Byte absolute Page; {Real bounds [0..65535]}

  Begin
    K := KeyL + 9;
    S := Pred (Page.ItemsOnPage) * K + 6;
    If KeyL <> MaxKeyLen Then Begin
      For I := Page.ItemsOnPage Downto 2 Do Begin
        Move ( P [S], Page.ItemArray [I], K );
        S := S - K;
      End;
    End;
  End;


  Function IsamFirstFreeChanged ( IFBPtr : IsamFileBlockPtr;
                                  Ind    : Word          ) : Boolean;

  Begin
    IsamFirstFreeChanged := IFBPtr^.DIDPtr^[Ind]^.FirstFreeChanged;
  End;


  Procedure IsamGetInfoRec (     IFBPtr    : IsamFileBlockPtr;
                                 KeyNr     : Word;
                             Var IndFopen  : Boolean );

  Var
    IR : IsamInfoRec;

  Begin
    IsamClearOK;
    With IFBPtr^, DIDPtr^[KeyNr]^, IR, InfoRec Do Begin
      If KeyNr = 0 Then Begin
        IsamGetBlock ( DatF, 0, SizeOf (IsamSmallInfoRec), IR );
      End Else Begin
        IsamGetBlock ( IndF, BlockOfs, SizeOf (IsamInfoRec), IR );
      End;
      If Not IsamOK Then Exit;
      FirstFree := Gener [1];
      NumberFree := Gener [2];
      NumRec := Gener [3];
      LenRec := Gener [4];
      If KeyNr = 0 Then Begin
        NrOfKeys := ILI (Gener [5]).Lo;
        IndFopen := ADK;
      End Else Begin
        RootRef := Gener [5];
        AllowDupKeys := ADK;
        NumKeys := KeysUsed;
        UsedPageSize := PageSizeUsed;                                {!!.42}
        If UsedPageSize = 0 Then UsedPageSize := CreatePageSize;     {!!.42}
      End;
    End;
  End;


  Procedure IsamCopyInfoRecToIR (     IFBPtr : IsamFileBlockPtr;
                                      KeyNr  : Word;
                                  Var IR     : IsamInfoRec );

  Begin
    With IFBPtr^, DIDPtr^[KeyNr]^, IR, InfoRec Do Begin
      Gener [1] := FirstFree;
      Gener [2] := NumberFree;
      Gener [3] := NumRec;
      Gener [4] := LenRec;
      If KeyNr = 0 Then Begin
        Gener [5] := NrOfKeys;
        ADK := False;
      End Else Begin
        Gener [5] := RootRef;
        ADK := AllowDupKeys;
        KeysUsed := NumKeys;
        PageSizeUsed := UsedPageSize;                                {!!.42}
      End;
    End;
  End;


  Procedure IsamPutInfoRec ( IFBPtr      : IsamFileBlockPtr;
                             KeyNr       : Word;
                             IndFDamaged : Boolean );

  Var
    IR   : IsamInfoRec;

  Begin
    IsamClearOK;
    With IFBPtr^, DIDPtr^[KeyNr]^ Do Begin
      IsamCopyInfoRecToIR ( IFBPtr, KeyNr, IR );
      If KeyNr = 0 Then Begin
        IR.InfoRec.ADK := IndFDamaged;
        IsamPutBlock ( DatF, 0, SizeOf (IsamSmallInfoRec), IR );
      End Else Begin
        IsamPutBlock ( IndF, BlockOfs, SizeOf (IsamInfoRec), IR );
      End;
    End;
  End;


  Procedure IsamSaveGivenInfoRec ( IFBPtr        : IsamFileBlockPtr;
                                   Ind           : Word;
                                   IR            : IsamInfoRec;
                                   SaveFirstFree : LongInt );

  Var
    Buffer : IsamSaveInfoRecBuffer;

  Begin
    With IFBPtr^, Buffer Do Begin
      IST := 1000;               {Sign for info rec}
      IndNr := Ind;
      BIR := IR;
      SFF := SaveFirstFree;
      IsamBlockWrite ( DiaF, Buffer, SizeOf (Buffer) );
    End;
  End;


  Function IsamRBufPtrToPgPtr ( RBufPtr : IsamRingBufferRecPtr ) : IsamPagePtr;
    {-Map of page will and can already be done}
  Begin
  {$IFDEF UseEMSHeap}
    With RBufPtr^ Do Begin
      If EMSEntry Then Begin
        If EMSHeapIsUsed Then Begin
          If UserSaveEMSHandle = 0 Then Begin
            UserSaveEMSHandle := SaveEMSCtxt;
          {$IFDEF EMSDisturbance}
            RestoreEMSCtxt ( OwnSaveEMSHandle );
          {$ENDIF}
          End;
        End;
        IsamRBufPtrToPgPtr := MapEMSPtr ( RBufPtr^.PageEntryPtr );
      End Else Begin
        IsamRBufPtrToPgPtr := IsamPagePtr (RBufPtr^.PageEntryPtr);
      End;
    End;
  {$ELSE}
    IsamRBufPtrToPgPtr := IsamPagePtr (RBufPtr^.PageEntryPtr);
  {$ENDIF}
  End;


  Function IsamPagePtrToRBufPtr ( PgPtr : IsamPagePtr ) : IsamRingBufferRecPtr;
    {-Map of page must already be done}
  Begin
    IsamPagePtrToRBufPtr := IsamPageEntryPtr (PgPtr)^.RingBufferPtr;
  End;


  Procedure IsamSavePage ( Var Pg : IsamPage );

  Var
    IRBPtr : IsamRingBufferRecPtr;
    IPEPtr : IsamPageEntryPtr;
    P      : Array [0..4] Of Byte Absolute Pg; {May reference 0..65535}
    K      : Word;
    TempLI : LongInt;

  Begin
    IRBPtr := IsamPagePtrToRBufPtr ( Addr (Pg) );
    IPEPtr := Addr (Pg);
      {-Map must be already done, so another map is not necessary}
    With IRBPtr^, IFBlPtr^, IPEPtr^, Page Do Begin
      IsamPack ( Page, DIDPtr^[KeyNr]^.KeyLen );
      TempLI := BckwPageRef;

    {--Calculate length of packed page}
      K := ItemsOnPage * ( DIDPtr^[KeyNr]^.KeyLen + 9 ) + 6;
      Move ( KeyNr, P [2], 2 );       {over BckwPageRef}

    {--Write beyond the end of the packed page (2x)}
      Move ( PageRef, P [K], 4 );
      Move ( TempLI, P [K + 4], 4 );  {BckwPageRef at end}
      IsamBlockWrite ( IFBlPtr^.DiaF, Pg, K + 8 );

      BckwPageRef := TempLI;
      IsamUnPack ( Page, DIDPtr^[KeyNr]^.KeyLen );
      SaveBuffered := True;
    End;
  End;


  Procedure IsamOnlyFlushDOSDat ( IFBPtr : IsamFileBlockPtr );

  Var
    Dummy : Boolean;

  Begin
    IsamFlush ( IFBPtr^.DatF, Dummy,
        (IFBPtr^.NSP <> Nil) And (IsamInitializedNet <> NoNet) );
  End;


  Procedure IsamFlushDOSDat ( IFBPtr : IsamFileBlockPtr );

  Begin
    With IFBPtr^ Do Begin
      If DIDPtr^[0]^.InfoRecChanged Or Not SaveFB Then Begin
        DIDPtr^[0]^.InfoRecChanged := False;
        DIDPtr^[0]^.IRChangedSaveN := True;
        IsamPutInfoRec ( IFBPtr, 0, False );
        If Not IsamOK Then Exit;
      End;
    End;
    IsamOnlyFlushDOSDat ( IFBPtr );
  End;


  Procedure IsamFlushDOSIx ( IFBPtr : IsamFileBlockPtr );

  Var
    Dummy : Boolean;

  Begin
    IsamFlush ( IFBPtr^.IndF, Dummy,
        (IFBPtr^.NSP <> Nil) And (IsamInitializedNet <> NoNet) );
  End;


  Procedure IsamFlushDOSDia ( IFBPtr : IsamFileBlockPtr; Continue : Boolean );

  Var
    WithDUP : Boolean;
    Dummy   : LongInt;

  Begin
    With IFBPtr^ Do Begin
      IsamFlush ( DiaF, WithDUP,
          (NSP <> Nil) And (IsamInitializedNet <> NoNet) );
      If Not IsamOK Then Exit;
      If Continue And Not WithDUP Then IsamLongSeekEOF ( DiaF, Dummy );
    End;
  End;


  Procedure IsamMakeDiaFile ( Var F : IsamFile );

  Var
    Dummy : Char;

  Begin
    IsamRewrite ( F );
    If Not IsamOK Then Exit;
    IsamBlockWrite ( F, Dummy, 1 );
  End;


  Procedure IsamReduceDiaFile ( IFBPtr : IsamFileBlockPtr );

  Var
    Dummy : Char;

  Begin
    IsamPutBlock ( IFBPtr^.DiaF, 1, 0, Dummy );
    If Not IsamOK Then Exit;
    If ( IFBPtr^.NSP = Nil ) Or IsamNetEmu Then Begin
      IsamFlushDOSDia ( IFBPtr, True );
    End;
  End;


  Procedure IsamSetDataBufferedFlag ( IFBPtr : IsamFileBlockPtr );

  Begin
    With IFBPtr^ Do Begin
      If DataBuffered Then Exit;
      DataBuffered := True;
      If SaveFB Then Exit;
      IsamPutBlock ( DatF, 20, 1, DataBuffered );
      If IsamForceFlushOfMark And (IsamNetEmu Or (NSP = Nil)) Then Begin
        IsamOnlyFlushDOSDat ( IFBPtr );
      End;
    End;
  End;


  Function IsamGetNextUsedAddRecRef ( IFBPtr : IsamFileBlockPtr ) : LongInt;

  Begin
    IsamGetNextUsedAddRecRef := 0;
    With IFBPtr^, DIDPtr^[0]^ Do Begin
      If FirstFree <> -1 Then Begin
        If (FirstFree <= 0) Or (FirstFree > NumRec) Then Begin
          IsamError := 10170;
          IsamOK := False;
          Exit;
        End;
        IsamGetNextUsedAddRecRef := FirstFree;
      End Else Begin
        IsamGetNextUsedAddRecRef := Succ (NumRec);
      End;
    End;
  End;


  Function IsamGetAfterNextUsedAddRecRef ( IFBPtr : IsamFileBlockPtr )
                                                                : LongInt;

  Var
    NextFree : LongInt;

  Begin
    IsamGetAfterNextUsedAddRecRef := 0;
    With IFBPtr^, DIDPtr^[0]^ Do Begin
      If FirstFree <> -1 Then Begin
        NextFree := FirstFree;
        If (NextFree <= 0) Or (NextFree > NumRec) Then Begin
          IsamError := 10170;
          IsamOK := False;
          Exit;
        End;
        IsamGetBlock ( DatF, NextFree * LenRec, SizeOf (LongInt), NextFree );
        If Not IsamOK Then Exit;
        If (NextFree = 0) Or (NextFree > NumRec) Or (NextFree < -1)
            Then Begin
          IsamError := 10170;
          IsamOK := False;
          Exit;
        End;
        If NextFree <> -1 Then Begin
          IsamGetAfterNextUsedAddRecRef := NextFree;
        End Else Begin
          IsamGetAfterNextUsedAddRecRef := Succ (NumRec);
        End;
      End Else Begin
        IsamGetAfterNextUsedAddRecRef := NumRec + 2;
      End;
    End;
  End;


  Procedure IsamNewRec (     IFBPtr : IsamFileBlockPtr;
                         Var RefNr  : LongInt;
                             Ind    : Word );

  Var
    NextFree : LongInt;

  Begin
    With IFBPtr^, DIDPtr^[Ind]^ Do Begin
      InfoRecChanged := True;
      If FirstFree <> -1 Then Begin
        If (FirstFree <= 0) Or (FirstFree > NumRec) Then Begin
          IsamError := 10170;
          IsamOK := False;
          Exit;
        End;
        RefNr := FirstFree;
        If Ind = 0 Then Begin
          IsamGetBlock ( DatF, RefNr * LenRec, SizeOf (LongInt), NextFree );
        End Else Begin
          IsamGetBlock ( IndF, RefNr * BlockLen + BlockOfs, SizeOf (LongInt),
              NextFree );
        End;
        If Not IsamOK Then Exit;
        If (NextFree = 0) Or (NextFree > NumRec) Or (NextFree < -1) Then Begin
          IsamError := 10170;
          IsamOK := False;
          Exit;
        End;
        FirstFree := NextFree;
        FirstFreeChanged := True;
        Dec (NumberFree);
      End Else Begin
        FirstFreeChanged := False;
        Inc (NumRec);
        RefNr := NumRec;
        If (Ind <> 0) And (NumRec > MaxPages) Then Begin
          IsamPutDummyBlock ( IndF, Succ (MaxPages) * BlockLen, BlockLen );
          If Not IsamOK Then Begin
            Dec (NumRec);
            Exit;
          End;
          Inc (MaxPages);
        End;
      End;
    End;
  End;


  Procedure IsamDeleteRecOrPage ( IFBPtr : IsamFileBlockPtr;
                                  RefNr  : LongInt;
                                  Ind    : Word );

  Begin
    With IFBPtr^, DIDPtr^[Ind]^ Do Begin
      InfoRecChanged := True;
      If Ind = 0 Then Begin
        IsamPutBlock ( DatF, RefNr * LenRec, SizeOf (LongInt), FirstFree );
      End Else Begin
        IsamPutBlock ( IndF, RefNr * BlockLen + BlockOfs, SizeOf (LongInt),
            FirstFree );
      End;
      If Not IsamOK Then Exit;
      FirstFree := RefNr;
      Inc (NumberFree);
    End;
  End;


  Function IsamAvailable ( Mem : LongInt ) : Boolean;

  Begin
    IsamAvailable := MaxAvail >= Mem;
  End;


  Procedure IsamAddToOpenFileBlockList ( IFBPtr : IsamFileBlockPtr );

  Var
    T1Ptr,
    T2Ptr : IsamOpenFileBlockListPtr;

  Begin
    IsamClearOK;
    If Not IsamAvailable ( SizeOf (IsamOpenFileBlockList) ) Then Begin
      IsamOK := False;
      IsamError := 10100;
      Exit;
    End;
    GetMem ( T1Ptr, SizeOf (IsamOpenFileBlockList) );
    If IsamOFBLPtr <> Nil Then Begin
      T2Ptr := IsamOFBLPtr;
      While T2Ptr^.Next <> Nil Do Begin
        T2Ptr := T2Ptr^.Next;
      End;
      T2Ptr^.Next := T1Ptr;
    End Else Begin
      IsamOFBLPtr := T1Ptr;
    End;
    T1Ptr^.Next := Nil;
    T1Ptr^.OIFBPtr := IFBPtr;
  End;


  Procedure IsamRemoveFromOpenFileBlockList ( IFBPtr : IsamFileBlockPtr );

  Var
    T1Ptr,
    T2Ptr : IsamOpenFileBlockListPtr;
    Found : Boolean;

  Begin
    IsamClearOK;
    T1Ptr := IsamOFBLPtr;
    If T1Ptr = Nil Then Exit;
    If T1Ptr^.OIFBPtr = IFBPtr Then Begin
      IsamOFBLPtr := T1Ptr^.Next;
    End Else Begin
      T2Ptr := T1Ptr;
      T1Ptr := T1Ptr^.Next;
      Found := False;
      While (T1Ptr <> Nil) And Not Found Do Begin
        Found := T1Ptr^.OIFBPtr = IFBPtr;
        If Not Found Then Begin
          T2Ptr := T1Ptr;
          T1Ptr := T1Ptr^.Next;
        End;
      End;
      If Not Found Then Exit;
      T2Ptr^.Next := T1Ptr^.Next;
    End;
    FreeMem ( T1Ptr, SizeOf (IsamOpenFileBlockList) );
  End;


  Function IsamFileBlockIsInOpenList ( IFBPtr : IsamFileBlockPtr ) : Boolean;

  Var
    TPtr : IsamOpenFileBlockListPtr;

  Begin
    IsamFileBlockIsInOpenList := True;
    TPtr := IsamOFBLPtr;
    While TPtr <> Nil Do Begin
      If TPtr^.OIFBPtr = IFBPtr Then Exit;
      TPtr := TPtr^.Next;
    End;
    IsamFileBlockIsInOpenList := False;
  End;


  Procedure IsamFreeKeyDescrMem ( IFBPtr : IsamFileBlockPtr; Nr : Integer );

  Var
    I : Integer;

  Begin
    With IFBPtr^ Do Begin
      For I := Nr DownTo 0 Do Begin
        FreeMem ( DIDPtr^[I], SizeOf (IsamDatIndDescr) );
      End;
      FreeMem ( DIDPtr, SizeOf (IsamDatIndDescrPtr) * Succ (NrOfKeys) );
    End;
  End;


  Procedure IsamGetKeyDescrMem ( IFBPtr : IsamFileBlockPtr; Nr : Integer );

  Var
    I : Integer;

  Begin
    IsamOK := False;
    IsamError := 10030;
    If Not IsamAvailable ( Succ (Nr) * SizeOf (IsamDatIndDescrPtr) ) Then Exit;
    GetMem ( IFBPtr^.DIDPtr, SizeOf (IsamDatIndDescrPtr) * Succ (Nr) );
    For I := 0 To Nr Do Begin
      If IsamAvailable ( SizeOf (IsamDatIndDescr) ) Then Begin
        GetMem ( IFBPtr^.DIDPtr^[I], SizeOf (IsamDatIndDescr) );
      End Else Begin
        IsamFreeKeyDescrMem ( IFBPtr, Pred (I) );
        Exit;
      End;
    End;
    IsamClearOK;
  End;


  Procedure IsamLast ( IRBRPtr : IsamRingBufferRecPtr );      {!!.42mod}

  Begin
    If IRBRPtr <> IsamRBR1Ptr^.Prev Then Begin
      If IRBRPtr = IsamRBR1Ptr Then Begin
        IsamRBR1Ptr := IsamRBR1Ptr^.Next
      End Else Begin
        IRBRPtr^.Prev^.Next := IRBRPtr^.Next;
        IRBRPtr^.Next^.Prev := IRBRPtr^.Prev;
        IRBRPtr^.Next := IsamRBR1Ptr;
        IRBRPtr^.Prev := IsamRBR1Ptr^.Prev;
        IsamRBR1Ptr^.Prev^.Next := IRBRPtr;
        IsamRBR1Ptr^.Prev := IRBRPtr;
      End;
    End;
  End;


  Procedure IsamOptimizePageBuffer;

  Var
    TPtr,
    TBPtr : IsamRingBufferRecPtr;
    W     : Word;

  Begin
    TPtr := IsamRBR1Ptr;
    For W := 1 To IsamNrOfRingBufferRecs Do Begin
      TBPtr := TPtr^.Next;
      If TPtr^.IFBlPtr <> Nil Then IsamLast ( TPtr );
      TPtr := TBPtr;
    End;
  End;


  Procedure IsamResetSaveBuffered;

  Var
    TPtr : IsamRingBufferRecPtr;

  Begin
    TPtr := IsamRBR1Ptr;
    Repeat
      With TPtr^ Do Begin
        SaveBuffered := False;
        TPtr := Next;
      End;
    Until TPtr = IsamRBR1Ptr;
  End;


  Procedure IsamPutPage ( IPgPtr      : IsamPagePtr;
                          Destructive : Boolean );

  Begin
    With IsamPageEntryPtr (IPgPtr)^, RingBufferPtr^, IFBlPtr^,
        DIDPtr^[KeyNr]^ Do Begin
      If SaveFB Then Begin
        If ((NSP = Nil) Or IsamNetEmu) And SaveBuffered Then Begin
          IsamFlushDOSDia ( IFBlPtr , True );
          If Not IsamOK Then Exit;
          IsamResetSaveBuffered;
        End;
      End;
      UpDated := False;
      IsamPack ( Page, KeyLen );
      IsamPutBlock ( IndF, PageRef * BlockLen + BlockOfs,
          LongInt (6) + LongInt (KeyLen + 9) * LongInt (Page.ItemsOnPage),
          Page );
      If Not Destructive Then IsamUnPack ( Page, KeyLen );
    End;
  End;


  Procedure IsamGetPage (     IFBPtr : IsamFileBlockPtr;
                              PRef   : LongInt;
                              Key    : Word;
                          Var IPgPtr : IsamPagePtr );

  Var
    TPtr  : IsamRingBufferRecPtr;
    Found : Boolean;

  Begin
    TPtr := IsamRBR1Ptr;
    Found := False;
    Repeat
      TPtr := TPtr^.Prev;
      With TPtr^ Do Begin
        If PageRef = PRef Then Begin
          If KeyNr = Key Then Begin
            If IFBlPtr = IFBPtr Then Begin
              Found := True;
              IPgPtr := IsamRBufPtrToPgPtr ( TPtr );
            End;
          End;
        End;
      End;
    Until Found Or (TPtr = IsamRBR1Ptr);
    If Not Found Then Begin
      TPtr := IsamRBR1Ptr;
      IPgPtr := IsamRBufPtrToPgPtr ( TPtr );
      With TPtr^ Do Begin
        If UpDated Then Begin
          IsamPutPage ( IPgPtr, True );
          If Not IsamOK Then Exit;
        End;
        With IFBPtr^, DIDPtr^[Key]^ Do Begin
          IsamGetBlock ( IndF, PRef * BlockLen + BlockOfs, LenRec, IPgPtr^ );
          If Not IsamOK Then Exit;
          IsamUnPack ( IPgPtr^, KeyLen );
          IFBlPtr := IFBPtr;
          PageRef := PRef;
          UpDated := False;
          KeyNr := Key;
        End;
      End;
    End;
    IsamLast ( TPtr );
  End;


  Procedure IsamNewPage (     IFBPtr : IsamFileBlockPtr;
                          Var PRef   : LongInt;
                          Var IPgPtr : IsamPagePtr;
                              Key    : Word );

  Begin
    IsamClearOK;
    IPgPtr := IsamRBufPtrToPgPtr ( IsamRBR1Ptr );
    With IsamRBR1Ptr^ Do Begin
      If UpDated Then Begin
        IsamPutPage ( IPgPtr, True );
        If Not IsamOK Then Exit;
      End;
      IsamNewRec ( IFBPtr, PRef, Key );
      IFBlPtr := IFBPtr;
      PageRef := PRef;
      KeyNr := Key;
      UpDated := False;
    End;
    IsamLast ( IsamRBR1Ptr );
  End;


  Procedure IsamUpdatePage ( PgPtr : IsamPagePtr );

  Begin
    IsamPagePtrToRBufPtr ( PgPtr )^.UpDated := True;
  End;


  Procedure IsamReturnPage ( Var PgPtr : IsamPagePtr );

  Begin
    With IsamPagePtrToRBufPtr ( PgPtr )^ Do Begin
      IsamDeleteRecOrPage ( IFBlPtr, PageRef, KeyNr );
      IFBlPtr := Nil;
      UpDated := False;
      IsamOptimizePageBuffer;
    End;
  End;


{$IFDEF LengthByteKeys}
  Function IsamCompKeys ( Var Key1, Key2 : IsamKeyStr;
                              DatRef1,
                              DatRef2    : LongInt;
                              Dup        : Boolean    ) : Integer;

  Var
    C,
    Len  : Integer;


    Function Sgn ( X : LongInt ) : Integer;

    Begin
      If X = LongInt (0) Then Begin
        Sgn := 0;
      End Else Begin
        If X < 0 Then Begin
          Sgn := -1;
        End Else Begin
          Sgn := 1;
        End;
      End;
    End;


  Begin
    Len := Length (Key1);
    If Length (Key2) < Len Then Len := Length (Key2);
    Inline (
               $8C / $DA /                    { Mov DX, DS }
               $C4 / $BE / Key1 /             { Les DI, Key1 [BP] }
               $C5 / $B6 / Key2 /             { Lds SI, Key2 [BP] }
               $47 /                          { Inc DI }
               $46 /                          { Inc SI }
               $8B / $8E / Len /              { Mov CX, [BP+Ofs(Len)] }
               $FC /                          { Cld }
               $31 / $C0 /                    { Xor AX, AX }
               $F3 /                          { Repz }
               $A6 /                          { Cmpsb }
               $74 / $05 /                    { Jz OK }
               $40 /                          { Inc AX }
               $72 / $02 /                    { Jc OK }
               $F7 / $D8 /                    { Neg AX }
       { OK: } $8E / $DA /                    { Mov DS, DX }
               $89 / $86 / C                  { Mov [BP+Ofs(C)], AX }
                                                                       );
    IsamCompKeys := C;
    If C <> 0 Then Exit;
    If Length (Key1) = Length (Key2) Then Begin
      If Dup Then Begin
        IsamCompKeys := Sgn ( DatRef1 - DatRef2 );
      End;
    End Else Begin
      If Length (Key1) > Length (Key2) Then Begin
        IsamCompKeys := 1;
      End Else Begin
        IsamCompKeys := -1;
      End;
    End;
  End;
{$ENDIF}

{$IFDEF ASCIIZeroKeys}
  Function IsamCompKeys ( Var Key1, Key2 : IsamKeyStr;
                              DatRef1,
                              DatRef2    : LongInt;
                              Dup        : Boolean    ) : Integer;

  Var
    C : Integer;

    Function Sgn ( X : LongInt ) : Integer;

    Begin
      If X = LongInt (0) Then Begin
        Sgn := 0;
      End Else Begin
        If X < LongInt (0) Then Begin
          Sgn := -1;
        End Else Begin
          Sgn := 1;
        End;
      End;
    End;

  Begin
    Inline (
             $C4 / $BE / Key1 /             { Les DI, Key1 [BP] }
             $B9 / >MaxKeyLen /             { Mov CX, MaxKeyLen }
             $41 /                          { Inc CX }
             $89 / $FB /                    { Mov BX, DI }
             $FC /                          { Cld }
             $31 / $C0 /                    { Xor AX, AX }
             $F2 /                          { Repnz }
             $AE /                          { Scasb }
             $29 / $DF /                    { Sub DI, BX }
             $4F /                          { Dec DI }
             $89 / $FB /                    { Mov BX, DI }
             $89 / $D9 /                    { Mov CX, BX }
             $8C / $DA /                    { Mov DX, DS }
             $C4 / $BE / Key1 /             { Les DI, Key1 [BP] }
             $C5 / $B6 / Key2 /             { Lds SI, Key2 [BP] }
             $8A / $18 /                    { Mov BL, [SI+BX] }
             $30 / $FF /                    { Xor BH, BH }
             $F3 /                          { Repz }
             $A6 /                          { Cmpsb }
             $75 / $07 /                    { Jnz Cont }
             $39 / $D8 /                    { Cmp AX, BX }
             $74 / $08 /                    { Jz OK }
             $48 /                          { Dec AX }
             $EB / $05 /                    { Jmp OK }
   { Cont: } $40 /                          { Inc AX }
             $72 / $02 /                    { Jc OK }
             $F7 / $D8 /                    { Neg AX }
     { OK: } $8E / $DA /                    { Mov DS, DX }
             $89 / $86 / C                  { Mov [BP+Ofs(C)], AX }
                                                                     );
    IsamCompKeys := C;
    If (C = 0) And Dup Then Begin
      IsamCompKeys := Sgn ( DatRef1 - DatRef2 );
    End;
  End;
{$ENDIF}

  Procedure IsamFlushPageBuffer ( IFBPtr      : IsamFileBlockPtr;
                                  Destructive : Boolean );

  Var
    TPtr : IsamRingBufferRecPtr;

  Begin
    IsamClearOK;
    TPtr := IsamRBR1Ptr;
    Repeat
      With TPtr^ Do Begin
        If IFBlPtr = IFBPtr Then Begin
          With IFBPtr^ Do Begin
            If UpDated Then Begin
              IsamPutPage ( IsamRBufPtrToPgPtr ( TPtr ), Destructive );
              If Not IsamOK Then Exit;
            End;
          End;
          If Destructive Then IFBlPtr := Nil;
        End;
      End;
      TPtr := TPtr^.Next;
    Until TPtr = IsamRBR1Ptr;
    If Destructive Then IsamOptimizePageBuffer;
  End;


  Procedure IsamFlushPageInfo ( IFBPtr      : IsamFileBlockPtr;
                                Destructive : Boolean );

  Var
    I : Integer;

  Begin
    With IFBPtr^ Do Begin
      IsamFlushPageBuffer ( IFBPtr, Destructive );
      If Not IsamOK Then Exit;
      For I := 1 To NrOfKeys Do Begin
        With DIDPtr^[I]^ Do Begin
          If InfoRecChanged Then Begin
            InfoRecChanged := False;
            IRChangedSaveN := True;
            IsamPutInfoRec ( IFBPtr, I, False );
            If Not IsamOK Then Exit;
          End;
        End;
      End;
    End;
  End;


  Procedure IsamDestroyPages ( IFBPtr : IsamFileBlockPtr );

  Var
    TPtr : IsamRingBufferRecPtr;

  Begin
    TPtr := IsamRBR1Ptr;
    Repeat
      With TPtr^ Do Begin
        If IFBlPtr = IFBPtr Then Begin
          SaveBuffered := False;
          UpDated := False;
          IFBlPtr := Nil;
        End;
      End;
      TPtr := TPtr^.Next;
    Until TPtr = IsamRBR1Ptr;
  End;


  Procedure IsamDestroyPagesOfKeyNr ( IFBPtr : IsamFileBlockPtr;
                                      Key    : Word );

  Var
    TPtr : IsamRingBufferRecPtr;

  Begin
    TPtr := IsamRBR1Ptr;
    Repeat
      With TPtr^ Do Begin
        If IFBlPtr = IFBPtr Then Begin
          If KeyNr = Key Then Begin
            SaveBuffered := False;
            UpDated := False;
            IFBlPtr := Nil;
          End;
        End;
      End;
      TPtr := TPtr^.Next;
    Until TPtr = IsamRBR1Ptr;
  End;


  Procedure IsamRepairFileBlock ( IFBPtr : IsamFileBlockPtr );


  Const
    RepError = 10180;

  Var
    FrameAlreadySaved : Boolean;


    Procedure Repair;

    Var
      IST : Word;


      Procedure RestoreInfoRec;

      Var
        Buffer : IsamSaveInfoRecBuffer;

      Begin
        IsamBlockRead ( IFBPtr^.DiaF, Buffer.IndNr,
            SizeOf (Buffer) - SizeOf (Word) );
        If Not IsamOK Then Exit;
        With Buffer, BIR, InfoRec, IFBPtr^, DIDPtr^[IndNr]^ Do Begin
          If SFF <> -2 Then Begin
            FirstFree := SFF;
            IsamDeleteRecOrPage ( IFBPtr, Gener [1], IndNr );
            If Not IsamOK Then Exit;
          End;
          FirstFree := Gener [1];
          NumberFree := Gener [2];
          NumRec := Gener [3];
          LenRec := Gener [4];
          If IndNr = 0 Then Begin
            NrOfKeys := ILI (Gener [5]).Lo;
          End Else Begin
            RootRef := Gener [5];
            AllowDupKeys := ADK;
            NumKeys := KeysUsed;
          End;
          IsamPutInfoRec ( IFBPtr, IndNr, False );
          InfoRecChanged := False;
        End;
      End;


      Procedure RestorePage;

      Type
        P = Array [0..4] Of Byte;    {May reference [0..65535]}

      Var
        PEPtr  : IsamPageEntryPtr;
        IPgPtr : IsamPagePtr;
        K      : Word;
        PPtr   : ^P;

      Begin
        IPgPtr := IsamRBufPtrToPgPtr ( IsamRBR1Ptr );
        PEPtr := IsamPageEntryPtr (IPgPtr);
        PPtr := Addr (PEPtr^);
        With IsamRBR1Ptr^, PEPtr^ Do Begin
          If UpDated Then Begin
            IsamPutPage ( IPgPtr, True );
            If Not IsamOK Then Exit;
          End;
          IFBlPtr := Nil;
          IsamBlockRead ( IFBPtr^.DiaF, PPtr^ [2], 2 );
          If Not IsamOK Then Exit;
          Move ( PPtr^ [2], KeyNr, 2 );  {Extract KeyNr}
          Page.ItemsOnPage := IST;       {Extract ItemsOnPage}
          K := Page.ItemsOnPage * ( IFBPtr^.DIDPtr^[KeyNr]^.KeyLen + 9 ) + 6;
          IsamBlockRead ( IFBPtr^.DiaF, PPtr^ [4], K + 4 ); {Read rest}
          If Not IsamOK Then Exit;
          Move ( PPtr^ [K], PageRef, 4 );
          Move ( PPtr^ [K+4], Page.BckwPageRef, 4 );
          IFBlPtr := IFBPtr;
          SaveBuffered := False;
          UpDated := False;
          IsamUnPack ( Page, IFBPtr^.DIDPtr^[KeyNr]^.KeyLen );
          IsamPutPage ( IPgPtr, True );
          IFBlPtr := Nil;
        End;
      End;


    Begin {Repair}
      IsamClearOK;
      IsamDestroyPages ( IFBPtr );
      With IFBPtr^ Do Begin
        IsamLongSeek ( DiaF, 0 );
        If Not IsamOK Then Begin
          IsamError := RepError;
          Exit;
        End;
        IsamBlockWrite ( DiaF, IST, 1 );
        If Not IsamOK Then Begin
          IsamError := RepError;
          Exit;
        End;
        Repeat
          IST := 0;
          IsamBlockRead ( DiaF, IST, 2 );
          If Not IsamOK Then Exit;
          Case IST Of
            1..MaxPageSize : RestorePage;                            {!!.42}
            1000           : RestoreInfoRec;
            2000           : Exit;
            Else Begin
              IsamOK := False;
              IsamError := RepError;
              Exit;
            End;
          End; {Case}
          If Not IsamOK Then Exit;
        Until False;
      End;
    End;

  Begin {IsamRepairFileBlock}
    If IFBPtr^.ReadOnlyFB Then Begin
      IsamOK := False;
      IsamError := 10430;
      Exit
    End;
  {$IFDEF UseEMSHeap}
    If EMSHeapIsUsed Then Begin
      FrameAlreadySaved := True;
      If UserSaveEMSHandle = 0 Then Begin
        FrameAlreadySaved := False;
        UserSaveEMSHandle := SaveEMSCtxt;
      {$IFDEF EMSDisturbance}
        RestoreEMSCtxt ( OwnSaveEMSHandle );
      {$ENDIF}
      End;
    End;
  {$ENDIF}
    Repair;
  {$IFDEF UseEMSHeap}
    If EMSHeapIsUsed Then Begin
      If Not FrameAlreadySaved Then Begin
       {$IFDEF EMSDisturbance}
        OwnSaveEMSHandle := SaveEMSCtxt;
      {$ENDIF}
        RestoreEMSCtxt ( UserSaveEMSHandle );
        UserSaveEMSHandle := 0;
      End;
    End;
  {$ENDIF}
    If IsamError = 0 Then Begin
      If (IFBPtr^.NSP = Nil) Or IsamNetEmu Then Begin
        IsamFlushDOSDat ( IFBPtr );
        If Not IsamOK Then Begin
          IsamError := RepError;
          Exit;
        End;
        If IFBPtr^.NrOfKeys > 0 Then Begin
          IsamFlushDOSIx ( IFBPtr );
          If Not IsamOK Then Begin
            IsamError := RepError;
            Exit;
          End;
        End;
      End;
      IsamReduceDiaFile ( IFBPtr );
    End Else Begin
      If IsamError = 10070 Then Begin
        IsamClearOK;
        IsamReduceDiaFile ( IFBPtr );
      End Else Begin
        IsamError := RepError;
      End;
    End;
  End;


  Procedure IsamFindKey (     IFBPtr     : IsamFileBlockPtr;
                              Key        : Word;
                          Var UserDatRef : LongInt;
                          Var UserKey    : IsamKeyStr         );

  Var
    RefNr   : LongInt;
    C,K,L,R : {Integer}longint;
    IPgPtr  : IsamPagePtr;
    OK      : Boolean;

  Begin
    With IFBPtr^, DIDPtr^[Key]^ Do Begin
      SequentialOK := False;
      OK := False;
      PathInd := 0;
      RefNr := RootRef;
      While (RefNr <> 0) And (Not OK) Do Begin
        Inc (PathInd);
        Path [PathInd].PageRef := RefNr;
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
            UserDatRef := ItemArray [K].DataRef;
            R := K;
            OK := True;
          End Else Begin
            If R = 0 Then Begin
              RefNr := BckwPageRef;
            End Else Begin
              RefNr := ItemArray [R].PageRef;
            End;
          End;
        End;
        Path [PathInd].ItemArrInd := R;
      End;
      If Not OK Then Begin
        While (PathInd > 0) And (Path [PathInd].ItemArrInd = 0) Do Begin
          Dec ( PathInd );
        End;
      End;
      SequentialOK := True;
    End;
    IsamOK := OK;
  End;


  Procedure IsamAddKey (     IFBPtr     : IsamFileBlockPtr;
                             Key        : Word;
                             UserDatRef : LongInt;
                         Var UserKey    : IsamKeyStr         );

  Var
    IPgRef1,
    IPgRef2  : LongInt;
    C, K, L  : Integer;
    OverRun,
    OK, ADK  : Boolean;
    IPgPtr1,
    IPgPtr2  : IsamPagePtr;
    IItem1,
    IItem2   : IsamItem;
    IR       : IsamInfoRec;
    RefList  : Array [1..30] Of LongInt;  {At least 3 * (MaxHeigth + 1)}


    Procedure InitRefList;

    Begin
      RefList [1] := 0;
    End;


    Function IsInRefList ( Ref : LongInt ) : Boolean;

    Var
      I : Integer;

    Begin
      IsInRefList := True;
      I := 1;
      While RefList [I] <> 0 Do Begin
        If Ref = RefList [I] Then Exit;
        Inc (I);
      End;
      RefList [Succ (I)] := 0;
      RefList [I] := Ref;
      IsInRefList := False;
    End;


    Procedure Search ( IPgRef1 : LongInt; RV : Integer; IPgRef1V : LongInt );

    Var
      R : Integer;

      Function BalanceDone : Boolean;

      Var
        IPgRef3           : LongInt;
        IPgPtr1V, IPgPtr3 : IsamPagePtr;
        right             : Boolean;

        Procedure Balance;

        Var
          TRef        : LongInt;
          I, K, M, N  : Integer;
          CurPageSize : Word;                                        {!!.42}

        Begin
          CurPageSize := IFBPtr^.DIDPtr^[Key]^.UsedPageSize;         {!!.42}
          With IPgPtr1^ Do Begin
            If right Then Begin
              Inc (RV);
              Inc (R);
              TRef := IPgPtr1V^.ItemArray [RV].PageRef;
              IPgPtr1V^.ItemArray [RV].PageRef := IPgPtr3^.BckwPageRef;
              K := 2 + CurPageSize + IPgPtr3^.ItemsOnPage;           {!!.42}
              M := Succ ( K Shr 1 );
              K := K - M - IPgPtr3^.ItemsOnPage;
              For I := IPgPtr3^.ItemsOnPage DownTo 1 Do Begin
                IPgPtr3^.ItemArray [I+K] := IPgPtr3^.ItemArray [I];
              End;
              IPgPtr3^.ItemArray [K] := IPgPtr1V^.ItemArray [RV];
              If M = R Then Begin
                For I := R To CurPageSize Do Begin                   {!!.42}
                  IPgPtr3^.ItemArray [Succ (I-R)] := ItemArray [I];
                End;
                IPgPtr1V^.ItemArray [RV] := IItem1;
              End Else Begin
                If M > R Then Begin
                  For I := M To CurPageSize Do Begin                 {!!.42}
                    IPgPtr3^.ItemArray [Succ (I-M)] := ItemArray [I];
                  End;
                  IPgPtr1V^.ItemArray [RV] := ItemArray [Pred (M)];
                  For I := M-2 DownTo R Do Begin
                    ItemArray [Succ (I)] := ItemArray [I];
                  End;
                  ItemArray [R] := IItem1;
                End Else Begin
                  For I := R To CurPageSize Do Begin                 {!!.42}
                    IPgPtr3^.ItemArray [Succ (I-M)] := ItemArray [I];
                  End;
                  IPgPtr3^.ItemArray [R-M] := IItem1;
                  For I := Succ (M) To Pred (R) Do Begin
                    IPgPtr3^.ItemArray [I-M] := ItemArray [I];
                  End;
                  IPgPtr1V^.ItemArray [RV] := ItemArray [M];
                End;
              End;
              IPgPtr3^.BckwPageRef := IPgPtr1V^.ItemArray [RV].PageRef;
              IPgPtr1V^.ItemArray [RV].PageRef := TRef;
              ItemsOnPage := Pred (M);
              Inc (IPgPtr3^.ItemsOnPage, K);
            End Else Begin
              Inc (R);
              TRef := IPgPtr1V^.ItemArray [RV].PageRef;
              IPgPtr1V^.ItemArray [RV].PageRef := BckwPageRef;
              N := Succ (IPgPtr3^.ItemsOnPage);
              M := (2 + CurPageSize + N) Shr 1;                      {!!.42}
              K := M - N;
              IPgPtr3^.ItemArray [N] := IPgPtr1V^.ItemArray [RV];
              If K = R Then Begin
                For I := 1 To Pred (K) Do Begin
                  IPgPtr3^.ItemArray [I+N] := ItemArray [I];
                End;
                For I := R To CurPageSize Do Begin                   {!!.42}
                  ItemArray [Succ (I-R)] := ItemArray [I];
                End;
                IPgPtr1V^.ItemArray [RV] := IItem1;
              End Else Begin
                If K < R Then Begin
                  For I := 1 To Pred (K) Do Begin
                    IPgPtr3^.ItemArray [I+N] := ItemArray [I];
                  End;
                  IPgPtr1V^.ItemArray [RV] := ItemArray [K];
                  For I := Succ (K) To Pred (R) Do Begin
                    ItemArray [I-K] := ItemArray [I];
                  End;
                  ItemArray [R-K] := IItem1;
                  For I := R To CurPageSize Do Begin                 {!!.42}
                    ItemArray [Succ (I-K)] := ItemArray [I];
                  End;
                End Else Begin
                  For I := 1 To Pred (R) Do Begin
                    IPgPtr3^.ItemArray [I+N] := ItemArray [I];
                  End;
                  IPgPtr3^.ItemArray [R+N] := IItem1;
                  For I := R To K-2 Do Begin
                    IPgPtr3^.ItemArray [Succ (I+N)] := ItemArray [I];
                  End;
                  IPgPtr1V^.ItemArray [RV] := ItemArray [Pred (K)];
                  For I := K To CurPageSize Do Begin                 {!!.42}
                    ItemArray [Succ (I-K)] := ItemArray [I];
                  End;
                End;
              End;
              IPgPtr1^.BckwPageRef := IPgPtr1V^.ItemArray [RV].PageRef;
              IPgPtr1V^.ItemArray [RV].PageRef := TRef;
              ItemsOnPage := CurPageSize - Pred (K);                 {!!.42}
              Inc (IPgPtr3^.ItemsOnPage, K);
            End;
          End;
        End;

      Begin
        BalanceDone := False;
        If RV = -1 Then Exit;
        IsamGetPage ( IFBPtr, IPgRef1V, Key, IPgPtr1V );
        If Not IsamOK Then Exit;
        With IPgPtr1V^ Do Begin
          right := RV < ItemsOnPage;
          If right Then Begin
            IPgRef3 := ItemArray [Succ (RV)].PageRef;
          End Else Begin
            If RV > 1 Then Begin
              IPgRef3 := ItemArray [Pred (RV)].PageRef;
            End Else Begin
              IPgRef3 := BckwPageRef;
            End;
          End;
          IsamGetPage ( IFBPtr, IPgRef3, Key, IPgPtr3 );
          If Not IsamOK Then Exit;
          If IPgPtr3^.ItemsOnPage =
              IFBPtr^.DIDPtr^[Key]^.UsedPageSize Then Exit;          {!!.42}
        End;
        If IFBPtr^.SaveFB Then Begin
          If Not IsInRefList ( IPgRef1V ) Then Begin
            IsamSavePage ( IPgPtr1V^ );
            If Not IsamOK Then Exit;
          End;
          If Not IsInRefList ( IPgRef3 ) Then Begin
            IsamSavePage ( IPgPtr3^ );
            If Not IsamOK Then Exit;
          End;
        End;
        Balance;
        IsamUpDatePage ( IPgPtr3 );
        IsamUpDatePage ( IPgPtr1V );
        OverRun := False;
        BalanceDone := True;
      End;


      Procedure Insert;

      Type
        IsamItemInAr = Array [0..0] Of IsamItem;

      Var
        I           : Integer;
        CurPageSize : Word;                                          {!!.42}

      Begin
        CurPageSize := IFBPtr^.DIDPtr^[Key]^.UsedPageSize;           {!!.42}
        IsamGetPage ( IFBPtr, IPgRef1, Key, IPgPtr1 );
        If Not IsamOK Then Exit;
        With IPgPtr1^ Do Begin
          If IFBPtr^.SaveFB Then Begin
            If Not IsInRefList ( IPgRef1 ) Then Begin
              IsamSavePage ( IPgPtr1^ );
              If Not IsamOK Then Exit;
            End;
          End;
          If ItemsOnPage < CurPageSize Then Begin                    {!!.42}
            Inc (ItemsOnPage);
            Move ( ItemArray [Succ(R)], ItemArray [R+2],
                (ItemsOnPage - Succ (R)) * SizeOf (IsamItemInAr) );
            ItemArray [Succ (R)] := IItem1;
            OverRun := False;
          End Else Begin
            If Not BalanceDone Then Begin
              If Not IsamOK Then Exit;
              With IFBPtr^ Do Begin
                IsamNewPage ( IFBPtr, IPgRef2, IPgPtr2, Key );
                If Not IsamOK Then Exit;
                If SaveFB Then Begin
                  If Not IsInRefList ( -2 ) Then Begin
                    If IsamFirstFreeChanged ( IFBPtr, Key ) Then Begin
                      IsamSaveGivenInfoRec ( IFBPtr, Key, IR,
                          DIDPtr^[Key]^.FirstFree );
                    End Else Begin
                      IsamSaveGivenInfoRec ( IFBPtr, Key, IR, -2 );
                    End;
                    If Not IsamOK Then Exit;
                  End;
                End;
              End;
              If R <= (CurPageSize Shr 1) Then Begin                 {!!.42}
                If R = CurPageSize Shr 1 Then Begin                  {!!.42}
                  IItem2 := IItem1;
                End Else Begin
                  IItem2 := ItemArray [CurPageSize Shr 1];           {!!.42}
                  For I := CurPageSize Shr 1 Downto R + 2 Do Begin   {!!.42}
                    ItemArray [I] := ItemArray [Pred (I)];
                  End;
                  ItemArray [Succ (R)] := IItem1;
                End;
                For I := 1 To CurPageSize Shr 1 Do Begin             {!!.42}
                  IPgPtr2^.ItemArray [I] :=
                      ItemArray [I + CurPageSize Shr 1];             {!!.42}
                End;
              End Else Begin
                R := R - CurPageSize Shr 1;                          {!!.42}
                IItem2 := ItemArray [Succ (CurPageSize Shr 1)];      {!!.42}
                For I := 1 To Pred (R) Do Begin
                  IPgPtr2^.ItemArray [I] :=
                      ItemArray [Succ (I + CurPageSize Shr 1)];      {!!.42}
                End;
                IPgPtr2^.ItemArray [R] := IItem1;
                For I := Succ (R) To CurPageSize Shr 1 Do Begin      {!!.42}
                  IPgPtr2^.ItemArray [I] :=
                      ItemArray [I + CurPageSize Shr 1];             {!!.42}
                End;
              End;
              ItemsOnPage := CurPageSize Shr 1;                      {!!.42}
              IPgPtr2^.ItemsOnPage := CurPageSize Shr 1;             {!!.42}
              IPgPtr2^.BckwPageRef := IItem2.PageRef;
              IItem2.PageRef := IPgRef2;
              IItem1 := IItem2;
              IsamUpdatePage ( IPgPtr2 );
            End;
          End;
        End;
        IsamUpdatePage ( IPgPtr1 );
      End;


    Begin {Search}
      If IPgRef1 = 0 Then Begin
        OverRun := True;
        With IItem1 Do Begin
          Move ( UserKey, KeyStr, SizeOf (IsamKeyStr) );
          DataRef := UserDatRef;
          PageRef := 0;
        End;
      End Else Begin
        IsamGetPage ( IFBPtr, IPgRef1, Key, IPgPtr1 );
        If Not IsamOK Then Exit;
        With IPgPtr1^ Do Begin
          L := 1;
          R := ItemsOnPage;
          ADK := IFBPtr^.DIDPtr^[Key]^.AllowDupKeys;
          Repeat
            K := (L + R) Shr 1;
            C := IsamCompKeys ( UserKey,
                                ItemArray [K].KeyStr,
                                UserDatRef,
                                ItemArray [K].DataRef,
                                ADK                   );
            If C <= 0 Then R := Pred (K);
            If C >= 0 Then L := Succ (K);
          Until R < L;
          If L - R > 1 Then Begin
            OK := False;
            OverRun := False;
          End Else Begin
            If R = 0 Then Begin
              Search ( BckwPageRef, R, IPgRef1 );
            End Else Begin
              Search ( ItemArray [R].PageRef, R, IPgRef1 );
            End;
            If Not IsamOK Then Exit;
            If OverRun Then Insert;
          End;
        End;
      End;
    End; {Search}


  Begin {IsamAddKey}
    InitRefList;
    IsamSetDataBufferedFlag ( IFBPtr );
    If Not IsamOK Then Exit;
    With IFBPtr^, DIDPtr^[Key]^ Do Begin
      If SaveFB Then IsamCopyInfoRecToIR ( IFBPtr, Key, IR );
      SequentialOK := False;
      OK := True;
      Search ( RootRef, -1, 0 );
      If Not IsamOK Then Exit;
      If OverRun Then Begin
        IPgRef1 := RootRef;
        IsamNewPage ( IFBPtr, RootRef, IPgPtr1, Key );
        If Not IsamOK Then Exit;
        If SaveFB Then Begin
          If Not IsInRefList ( -2 ) Then Begin
            If IsamFirstFreeChanged ( IFBPtr, Key ) Then Begin
              IsamSaveGivenInfoRec ( IFBPtr, Key, IR,
                  DIDPtr^[Key]^.FirstFree );
            End Else Begin
              IsamSaveGivenInfoRec ( IFBPtr, Key, IR, -2 );
            End;
            If Not IsamOK Then Exit;
          End;
        End;
        With IPgPtr1^ Do Begin
          ItemsOnPage := 1;
          BckwPageRef := IPgRef1;
          ItemArray [1] := IItem1;
        End;
        IsamUpdatePage ( IPgPtr1 );
      End;
      If SaveFB Then Begin
        If Not IsInRefList ( -2 ) Then Begin
          {-If not yet stored, no change was made up to now}
          IsamSaveGivenInfoRec ( IFBPtr, Key, IR, -2 );
          If Not IsamOK Then Exit;
        End;
        If (NSP = Nil) Or IsamNetEmu Then Begin
          IsamFlushDOSDia ( IFBPtr, False );
          If Not IsamOK Then Exit;
          IsamResetSaveBuffered;
        End;
        If OK Then Begin
          Inc (NumKeys);
          InfoRecChanged := True;
        End;
        IsamFlushPageInfo ( IFBPtr, False );
        If Not IsamOK Then Exit;
        If (NSP = Nil) Or IsamNetEmu Then Begin
          IsamFlushDOSIx ( IFBPtr );
          If Not IsamOK Then Exit;
        End;
      End Else Begin
        If OK Then Begin
          Inc (NumKeys);
          InfoRecChanged := True;
        End;
      End;
    End;
    IsamOK := OK;
  End;


  Procedure IsamDeleteKey (     IFBPtr     : IsamFileBlockPtr;
                                Key        : Word;
                                UserDatRef : LongInt;
                            Var UserKey    : IsamKeyStr     );

  Var
    OK,
    UnderRun : Boolean;
    IPgPtr   : IsamPagePtr;
    RefList  : Array [1..30] Of LongInt;  {At least 3 * (MaxHeigth + 1)}
    IR       : IsamInfoRec;


    Procedure InitRefList;

    Begin
      RefList [1] := 0;
    End;


    Function IsInRefList ( Ref : LongInt ) : Boolean;

    Var
      I : Integer;

    Begin
      IsInRefList := True;
      I := 1;
      While RefList [I] <> 0 Do Begin
        If Ref = RefList [I] Then Exit;
        Inc (I);
      End;
      RefList [Succ (I)] := 0;
      RefList [I] := Ref;
      IsInRefList := False;
    End;


    Procedure Delete2 ( RefNr : LongInt );

    Type
      IsamItemInAr = Array [0..0] Of IsamItem;

    Var
      C, K, L, R : Integer;
      IPgRef00   : LongInt;
      IPgPtr     : IsamPagePtr;
      ADK        : Boolean;


      Procedure UnderFlow ( RefNr, IPgRef2 : LongInt; R : Integer );

      Var
        I, K, IItem0             : Integer;
        IPgRef0                  : LongInt;
        IPgPtr, IPgPtr2, IPgPtr0 : IsamPagePtr;
        CurPageSize              : Word;                                          {!!.42}

      Begin
        CurPageSize := IFBPtr^.DIDPtr^[Key]^.UsedPageSize;           {!!.42}
        IsamGetPage ( IFBPtr, RefNr, Key, IPgPtr );
        If Not IsamOK Then Exit;
        IsamGetPage ( IFBPtr, IPgRef2, Key, IPgPtr2 );
        If Not IsamOK Then Exit;
        If R < IPgPtr^.ItemsOnPage Then Begin
          Inc (R);
          IPgRef0 :=  IPgPtr^.ItemArray [R].PageRef;
          IsamGetPage ( IFBPtr, IPgRef0, Key, IPgPtr0 );
          If Not IsamOK Then Exit;
          If IFBPtr^.SaveFB Then Begin
            If Not IsInRefList ( RefNr ) Then Begin
              IsamSavePage ( IPgPtr^ );
              If Not IsamOK Then Exit;
            End;
            If Not IsInRefList ( IPgRef2 ) Then Begin
              IsamSavePage ( IPgPtr2^ );
              If Not IsamOK Then Exit;
            End;
            If Not IsInRefList ( IPgRef0 ) Then Begin
              IsamSavePage ( IPgPtr0^ );
              If Not IsamOK Then Exit;
            End;
          End;
          K := (Succ (IPgPtr0^.ItemsOnPage - CurPageSize Shr 1))     {!!.42}
              Shr 1;
          IPgPtr2^.ItemArray [CurPageSize Shr 1] :=                  {!!.42}
              IPgPtr^.ItemArray [R];
          IPgPtr2^.ItemArray [CurPageSize Shr 1].PageRef :=          {!!.42}
              IPgPtr0^.BckwPageRef;
          If K > 0 Then Begin
            For I := 1 To Pred (K) Do Begin
              IPgPtr2^.ItemArray [I + CurPageSize Shr 1] :=          {!!.42}
                  IPgPtr0^.ItemArray [I];
            End;
            IPgPtr^.ItemArray [R] := IPgPtr0^.ItemArray [K];
            IPgPtr^.ItemArray [R].PageRef := IPgRef0;
            IPgPtr0^.BckwPageRef := IPgPtr0^.ItemArray [K].PageRef;
            IPgPtr0^.ItemsOnPage := IPgPtr0^.ItemsOnPage - K;
            For I := 1 To IPgPtr0^.ItemsOnPage Do Begin
              IPgPtr0^.ItemArray [I] := IPgPtr0^.ItemArray [I+K];
            End;
            IPgPtr2^.ItemsOnPage := Pred (CurPageSize Shr 1 + K);    {!!.42}
            UnderRun := False;
            IsamUpdatePage (IPgPtr0);
          End Else Begin
            For I := 1 To CurPageSize Shr 1 Do Begin                 {!!.42}
              IPgPtr2^.ItemArray [I + CurPageSize Shr 1] :=          {!!.42}
                  IPgPtr0^.ItemArray [I];
            End;
            For I := R To Pred ( IPgPtr^.ItemsOnPage ) Do Begin
              IPgPtr^.ItemArray [I] := IPgPtr^.ItemArray [Succ(I)];
            End;
            IPgPtr2^.ItemsOnPage := CurPageSize;                     {!!.42}
            Dec (IPgPtr^.ItemsOnPage);
            IsamReturnPage (IPgPtr0);
            If Not IsamOK Then Exit;
            UnderRun := IPgPtr^.ItemsOnPage < CurPageSize Shr 1;     {!!.42}
          End;
          IsamUpdatePage ( IPgPtr2 );
        End Else Begin
          If R = 1 Then Begin
            IPgRef0 := IPgPtr^.BckwPageRef;
          End Else Begin
            IPgRef0 := IPgPtr^.ItemArray [Pred(R)].PageRef;
          End;
          IsamGetPage ( IFBPtr, IPgRef0, Key, IPgPtr0 );
          If Not IsamOK Then Exit;
          If IFBPtr^.SaveFB Then Begin
            If Not IsInRefList ( RefNr ) Then Begin
              IsamSavePage ( IPgPtr^ );
              If Not IsamOK Then Exit;
            End;
            If Not IsInRefList ( IPgRef2 ) Then Begin
              IsamSavePage ( IPgPtr2^ );
              If Not IsamOK Then Exit;
            End;
            If Not IsInRefList ( IPgRef0 ) Then Begin
              IsamSavePage ( IPgPtr0^ );
              If Not IsamOK Then Exit;
            End;
          End;
          IItem0 := Succ (IPgPtr0^.ItemsOnPage);
          K := (IItem0 - CurPageSize Shr 1) Shr 1;                   {!!.42}
          If K > 0 Then Begin
            For I := Pred (CurPageSize Shr 1) Downto 1 Do Begin      {!!.42}
              IPgPtr2^.ItemArray [I+K] := IPgPtr2^.ItemArray [I];
            End;
            IPgPtr2^.ItemArray [K] := IPgPtr^.ItemArray [R];
            IPgPtr2^.ItemArray [K].PageRef := IPgPtr2^.BckwPageRef;
            Dec (IItem0, K);
            For I := Pred (K) Downto 1 Do Begin
              IPgPtr2^.ItemArray [I] := IPgPtr0^.ItemArray [I+IItem0];
            End;
            IPgPtr2^.BckwPageRef := IPgPtr0^.ItemArray [IItem0].PageRef;
            IPgPtr^.ItemArray [R] := IPgPtr0^.ItemArray [IItem0];
            IPgPtr^.ItemArray [R].PageRef := IPgRef2;
            IPgPtr0^.ItemsOnPage := Pred (IItem0);
            IPgPtr2^.ItemsOnPage := Pred (CurPageSize Shr 1 + K);    {!!.42}
            UnderRun := False;
            IsamUpdatePage ( IPgPtr2 );
          End Else Begin
            IPgPtr0^.ItemArray [IItem0] := IPgPtr^.ItemArray [R];
            IPgPtr0^.ItemArray [IItem0].PageRef := IPgPtr2^.BckwPageRef;
            For I := 1 To Pred (CurPageSize Shr 1) Do Begin          {!!.42}
              IPgPtr0^.ItemArray [I+IItem0] := IPgPtr2^.ItemArray [I];
            End;
            IPgPtr0^.ItemsOnPage := CurPageSize;                     {!!.42}
            Dec (IPgPtr^.ItemsOnPage);
            IsamReturnPage ( IPgPtr2 );
            If Not IsamOK Then Exit;
            UnderRun := IPgPtr^.ItemsOnPage < CurPageSize Shr 1;     {!!.42}
          End;
          IsamUpdatePage (IPgPtr0);
        End;
        IsamUpdatePage ( IPgPtr );
      End;   (* UnderFlow *)


      Procedure Delete1 ( IPgRef2 : LongInt );

      Var
        C        : Integer;
        IPgRef00 : LongInt;
        IPgPtr2  : IsamPagePtr;

      Begin
        IsamGetPage ( IFBPtr, IPgRef2, Key, IPgPtr2 );
        If Not IsamOK Then Exit;
        With IPgPtr2^ Do Begin
          IPgRef00 := ItemArray [ItemsOnPage].PageRef;
          If IPgRef00 <> 0 Then Begin
            C := ItemsOnPage;
            Delete1 ( IPgRef00 );
            If Not IsamOK Then Exit;
            If UnderRun Then UnderFlow ( IPgRef2, IPgRef00, C );
          End Else Begin
            IsamGetPage ( IFBPtr, RefNr, Key, IPgPtr );
            If Not IsamOK Then Exit;
            If IFBPtr^.SaveFB Then Begin
              If Not IsInRefList ( RefNr ) Then Begin
                IsamSavePage ( IPgPtr^ );
                If Not IsamOK Then Exit;
              End;
              If Not IsInRefList ( IPgRef2 ) Then Begin
                IsamSavePage ( IPgPtr2^ );
                If Not IsamOK Then Exit;
              End;
            End;
            ItemArray [ItemsOnPage].PageRef :=
                IPgPtr^.ItemArray [K].PageRef;
            IPgPtr^.ItemArray [K] := ItemArray [ItemsOnPage];
            Dec (ItemsOnPage);
            UnderRun := ItemsOnPage <
                IFBPtr^.DIDPtr^[Key]^.UsedPageSize Shr 1;            {!!.42}
            IsamUpdatePage ( IPgPtr );
            IsamUpdatePage ( IPgPtr2 );
          End;
        End;
      End;  (* Delete1 *)

    Begin  (* Delete2 *)
      If RefNr = 0 Then Begin
        OK := False;
        UnderRun := False;
      End Else Begin
        IsamGetPage ( IFBPtr, RefNr, Key, IPgPtr );
        If Not IsamOK Then Exit;
        With IPgPtr^ Do Begin
          L := 1;
          R := ItemsOnPage;
          ADK := IFBPtr^.DIDPtr^[Key]^.AllowDupKeys;
          Repeat
            K := (L + R) Shr 1;
            C := IsamCompKeys ( UserKey,
                                ItemArray [K].KeyStr,
                                UserDatRef,
                                ItemArray [K].DataRef,
                                ADK                   );
            If C <= 0 Then R := Pred (K);
            If C >= 0 Then L := Succ (K);
          Until L > R;
          If R = 0 Then Begin
            IPgRef00 := BckwPageRef;
          End Else Begin
            IPgRef00 := ItemArray [R].PageRef;
          End;
          If L - R > 1 Then Begin
            UserDatRef := ItemArray [K].DataRef;
            If IPgRef00 = 0 Then Begin
              If IFBPtr^.SaveFB Then Begin
                If Not IsInRefList ( RefNr ) Then Begin
                  IsamSavePage ( IPgPtr^ );
                  If Not IsamOK Then Exit;
                End;
              End;
              Dec (ItemsOnPage);
              UnderRun := ItemsOnPage <                              {!!.42}
                  IFBPtr^.DIDPtr^[Key]^.UsedPageSize Shr 1;
              Move ( ItemArray [Succ (K)], ItemArray [K],
                  ( ItemsOnPage - Pred (K) ) * SizeOf (IsamItemInAr) );
              IsamUpdatePage ( IPgPtr );
            End Else Begin
              Delete1 ( IPgRef00 );
              If Not IsamOK Then Exit;
              If UnderRun Then UnderFlow ( RefNr, IPgRef00, R );
            End;
          End Else Begin
            Delete2 ( IPgRef00 );
            If Not IsamOK Then Exit;
            If UnderRun Then UnderFlow ( RefNr, IPgRef00, R );
          End;
        End;
      End;
    End;   (* Delete2 *)

  Begin   (* DeleteKey *)
    InitRefList;
    IsamSetDataBufferedFlag ( IFBPtr );
    If Not IsamOK Then Exit;
    With IFBPtr^, DIDPtr^[Key]^ Do Begin
      If SaveFB Then Begin
        If Not IsInRefList ( -2 ) Then Begin   {Always True}
          IsamCopyInfoRecToIR ( IFBPtr, Key, IR );
          IsamSaveGivenInfoRec ( IFBPtr, Key, IR, -2 );
          If Not IsamOK Then Exit;
        End;
      End;
      SequentialOK := False;
      OK := True;
      Delete2 ( RootRef );
      If Not IsamOK Then Exit;
      If UnderRun Then Begin
        IsamGetPage ( IFBPtr, RootRef, Key, IPgPtr );
        If Not IsamOK Then Exit;
        If IPgPtr^.ItemsOnPage = 0 Then Begin
          If SaveFB Then Begin
            If Not IsInRefList ( RootRef ) Then Begin
              IsamSavePage ( IPgPtr^ );
              If Not IsamOK Then Exit;
            End;
          End;
          RootRef := IPgPtr^.BckwPageRef;
          IsamReturnPage ( IPgPtr );
          If Not IsamOK Then Exit;
        End;
      End;
      If SaveFB Then Begin
        If (NSP = Nil) Or IsamNetEmu Then Begin
          IsamFlushDOSDia ( IFBPtr, False );
          If Not IsamOK Then Exit;
          IsamResetSaveBuffered;
        End;
        If OK Then Begin
          Dec (NumKeys);
          InfoRecChanged := True;
        End;
        IsamFlushPageInfo ( IFBPtr, False );
        If Not IsamOK Then Exit;
        If (NSP = Nil) Or IsamNetEmu Then Begin
          IsamFlushDOSIx ( IFBPtr );
          If Not IsamOK Then Exit;
        End;
      End Else Begin
        If OK Then Begin
          Dec (NumKeys);
          InfoRecChanged := True;
        End;
      End;
    End;
    IsamOK := OK;
  End;
