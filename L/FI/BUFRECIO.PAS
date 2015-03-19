(**************************************************************)
(*      B-Tree Isam Buffered Record IO Ver 5.51               *)
(*      Copyright (C) 1994 ENZ EDV-Beratung GmbH              *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

{--Conditional defines and compiler options}
  {$I BTDefine.Inc}
  {$F-,V-,B-,S-,I-,R-}
  {$IFDEF CanAllowOverlays}
    {$O+,F+}
  {$ENDIF}
  {$IFDEF CanSetOvrflowCheck}
    {$Q-}
  {$ENDIF}


Unit BufRecIO;                                                       {!!.50}

Interface

Uses
  Filer,     {!!.TP}
  VRec;      {!!.TP}


  Procedure CreateRecBuffers ( ReadDatSLen : Word;
                               AddIFBPtr   : IsamFileBlockPtr );
    {-Allocates memory (if available) for the buffers and initializes
      private data}

  Procedure DoneRecBuffers;
    {-Flushes all write buffered data to disk and deallocates memory}

  Function DecreaseBufferMem : Boolean;
    {-Returns True, if memory consumption could be decreased}

  Procedure BufGetBlock ( Var F : IsamFile; Ref, Len : LongInt; Var Dest );
    {-Acts like IsamGetBlock, but can use a buffer}

  Procedure BufAddRec (     IFBPtr  : IsamFileBlockPtr;
                        Var Source );
    {-Acts like BTAddRec, but can use a buffer and doesn't return a
      reference}

  Procedure BufGetVariableRecRebuilt ( Var F        : IsamFile;
                                           DatSLen  : Word;
                                       Var RefNr    : LongInt;
                                           DestPtr  : Pointer;
                                           DestSize : Word;
                                       Var RecRead  : Boolean;
                                       Var Len      : Word );
    {-Reads the next (following to RefNr) variable record into the buffer
      pointed to by DestPtr; if an error 10070 or 10415 occurs, RefNr is set
      appropriately to read the next record; other errors mean abort
      reading; if no error occurs and Len returnes 0, there is no more
      record to read; if no error occurs and RecRead contains False, then
      the buffer was not large enough to hold the record; in this case Len
      contains the needed buffer size}

  Procedure BufAddVariableRecRebuilt ( IFBPtr    : IsamFileBlockPtr;
                                       SourcePtr : Pointer;
                                       Len       : Word );
    {-Acts like BTAddVariableRec, but can use a buffer and doesn't return a
      reference}

  Procedure MarkReadBufRecDeleted ( Ref : LongInt );
    {-Marks the reference Ref as deleted, if it's present in the buffer}

  Procedure RewindReadBuffer;
    {-Forces the read buffer to start at 1}

Implementation

  Const
    MaxBufferedRecLen = 16383;
    MaxBufferSize = 32766;
    MinRecsInBuffer = 2;

  Type
    ReadBufferDescr = Record
      DatSLen      : Word;
      BufPtr       : Pointer;
      BufSize      : Word;
      LogBufSize   : Word;
        {-Number of records that can be stored in the buffer}
      LogBufStart  : LongInt;
        {-The reference belonging to the first record in the buffer}
      LogBufEnd    : Word;
        {-The number (zero based) of the first not filled record in the
          buffer; if LogBufEnd = LogBufSize, the buffer is full;
          if LogBufEnd = 0, the buffer is empty}
        {-LogBufStart + LogBufEnd is the reference of the first record
          not present in the buffer}
    End;

    AddBufferDescr = Record
      IFBPtr       : IsamFileBlockPtr;
        {-Used to store header information}
      DatSLen      : Word;
      BufPtr       : Pointer;
      BufSize      : Word;
      LogBufSize   : Word;
        {-Number of records that can be stored in the buffer}
      LogBufStart  : LongInt;
        {-The reference belonging to the first record in the buffer}
      LogBufPos    : Word;
        {-The number (zero based) of the next free record in the buffer;
          if LogBufPos = LogBufSize, the buffer is full;
          if LogBufPos = 0, the buffer is empty}
    End;

  Const
    ReadBufDescrPtr : ^ReadBufferDescr = Nil;
    AddBufDescrPtr  : ^AddBufferDescr  = Nil;


  Procedure FlushAddBuffer;

  Type
    PLongInt = ^LongInt;                               {!!!to remove later}

  Var
    LPtr : PLongInt;                                   {!!!to remove later}

  Begin
    If AddBufDescrPtr^.LogBufPos > 0 Then Begin
      IsamPutBlock ( AddBufDescrPtr^.IFBPtr^.DatF,
          AddBufDescrPtr^.LogBufStart * AddBufDescrPtr^.DatSLen,
          AddBufDescrPtr^.DatSLen * AddBufDescrPtr^.LogBufPos,
          AddBufDescrPtr^.BufPtr^ );
      If IsamOK Then Begin
        LPtr := IsamGetNumRecAddress ( AddBufDescrPtr^.IFBPtr );{!!!to remove later}
        If Not IsamOK Then Exit;                       {!!!to remove later}
        LPtr^:= LPtr^ + AddBufDescrPtr^.LogBufPos;     {!!!to remove later}
(*        AddBufDescrPtr^.IFBPtr^.DIDPtr^[0]^.NumRec :=
            AddBufDescrPtr^.IFBPtr^.DIDPtr^[0]^.NumRec
            + AddBufDescrPtr^.LogBufPos; *)            {!!!replaces above}
        AddBufDescrPtr^.LogBufStart := AddBufDescrPtr^.LogBufStart
            + AddBufDescrPtr^.LogBufPos;
        AddBufDescrPtr^.LogBufPos := 0;
      End;
    End;
  End;


  Procedure CreateRecBuffers ( ReadDatSLen : Word;
                               AddIFBPtr   : IsamFileBlockPtr );

  Var
    AddDatSLen : LongInt;
    NrRecs     : Word;
    AvailMem   : LongInt;

  Begin
    If AddIFBPtr <> Nil Then Begin
      AddDatSLen := BTDatRecordSize ( AddIFBPtr );
      If IsamOK And (AddDatSLen <= MaxBufferedRecLen)
          And (AddDatSLen > 0) And (BTFileLen ( AddIFBPtr ) = 1) Then Begin
        If MaxAvail >= SizeOf (AddBufferDescr) Then Begin
          GetMem ( AddBufDescrPtr, SizeOf (AddBufferDescr) );
          AvailMem := MaxAvail;
          If AvailMem > MaxBufferSize Then AvailMem := MaxBufferSize;
          NrRecs := AvailMem Div AddDatSLen;
          If NrRecs >= MinRecsInBuffer Then Begin
            AddBufDescrPtr^.BufSize := NrRecs * AddDatSLen;
            GetMem ( AddBufDescrPtr^.BufPtr, AddBufDescrPtr^.BufSize );
            AddBufDescrPtr^.IFBPtr := AddIFBPtr;
            AddBufDescrPtr^.DatSLen := AddDatSLen;
            AddBufDescrPtr^.LogBufSize := NrRecs;
            AddBufDescrPtr^.LogBufStart := 1;
            AddBufDescrPtr^.LogBufPos := 0;
          End Else Begin
            FreeMem ( AddBufDescrPtr, SizeOf (AddBufferDescr) );
            AddBufDescrPtr := Nil;
          End;
        End;
      End;
    End;

    If ReadDatSLen > 0 Then Begin
      If MaxAvail >= SizeOf (ReadBufferDescr) Then Begin
        GetMem ( ReadBufDescrPtr, SizeOf (ReadBufferDescr) );
        AvailMem := MaxAvail;
        If AvailMem > MaxBufferSize Then AvailMem := MaxBufferSize;
        NrRecs := AvailMem Div ReadDatSLen;
        If NrRecs >= MinRecsInBuffer Then Begin
          ReadBufDescrPtr^.BufSize := NrRecs * ReadDatSLen;
          GetMem ( ReadBufDescrPtr^.BufPtr, ReadBufDescrPtr^.BufSize );
          ReadBufDescrPtr^.DatSLen := ReadDatSLen;
          ReadBufDescrPtr^.LogBufSize := NrRecs;
          ReadBufDescrPtr^.LogBufStart := 1;
          ReadBufDescrPtr^.LogBufEnd := 0;
        End Else Begin
          FreeMem ( ReadBufDescrPtr, SizeOf (ReadBufferDescr) );
          ReadBufDescrPtr := Nil;
        End;
      End;
    End;
  End;


  Procedure DoneRecBuffers;

  Begin
    IsamClearOK;
    If ReadBufDescrPtr <> Nil Then Begin
      FreeMem ( ReadBufDescrPtr^.BufPtr, ReadBufDescrPtr^.BufSize );
      FreeMem ( ReadBufDescrPtr, SizeOf (ReadBufferDescr) );
      ReadBufDescrPtr := Nil;
    End;
    If AddBufDescrPtr <> Nil Then Begin
      FlushAddBuffer;
      FreeMem ( AddBufDescrPtr^.BufPtr, AddBufDescrPtr^.BufSize );
      FreeMem ( AddBufDescrPtr, SizeOf (AddBufferDescr) );
      AddBufDescrPtr := Nil;
    End;
  End;


  Function DecreaseBufferMem : Boolean;

  Const
    MinDecrease = 1024;

  Var
    NrRecs : Word;

  Begin
    DecreaseBufferMem := True;
    IsamClearOK;
    If ReadBufDescrPtr <> Nil Then Begin
      NrRecs := Succ (Pred (MinDecrease) Div ReadBufDescrPtr^.DatSLen);
        {-Number of records to decrease}
      If (LongInt (ReadBufDescrPtr^.LogBufSize) - NrRecs)
          * ReadBufDescrPtr^.DatSLen < MinDecrease Then Begin
        {-Too less buffer left}
        NrRecs := ReadBufDescrPtr^.LogBufSize;
      End;
      NrRecs := ReadBufDescrPtr^.LogBufSize - NrRecs;
        {-Number of records to newly allocate}
      If NrRecs < MinRecsInBuffer Then NrRecs := 0;
      FreeMem ( ReadBufDescrPtr^.BufPtr, ReadBufDescrPtr^.BufSize );
      If NrRecs > 0 Then Begin
        Inc (ReadBufDescrPtr^.LogBufStart,
            Succ (ReadBufDescrPtr^.LogBufSize - NrRecs));
          {-Ensure we will not loose contact}
        ReadBufDescrPtr^.BufSize := NrRecs * ReadBufDescrPtr^.DatSLen;
        GetMem ( ReadBufDescrPtr^.BufPtr, ReadBufDescrPtr^.BufSize );
        ReadBufDescrPtr^.LogBufSize := NrRecs;
        ReadBufDescrPtr^.LogBufEnd := 0;
      End Else Begin
        FreeMem ( ReadBufDescrPtr, SizeOf (ReadBufferDescr) );
        ReadBufDescrPtr := Nil;
          {-Free all}
      End;
    End Else Begin
      If AddBufDescrPtr <> Nil Then Begin
        FlushAddBuffer;
        If Not IsamOK Then Exit;
        NrRecs := Succ (Pred (MinDecrease) Div AddBufDescrPtr^.DatSLen);
          {-Number of records to decrease}
        If (LongInt (AddBufDescrPtr^.LogBufSize) - NrRecs)
            * AddBufDescrPtr^.DatSLen < MinDecrease Then Begin
          {-Too less buffer left}
          NrRecs := AddBufDescrPtr^.LogBufSize;
        End;
        NrRecs := AddBufDescrPtr^.LogBufSize - NrRecs;
          {-Number of records to newly allocate}
        If NrRecs < MinRecsInBuffer Then NrRecs := 0;
        FreeMem ( AddBufDescrPtr^.BufPtr, AddBufDescrPtr^.BufSize );
        If NrRecs > 0 Then Begin
          AddBufDescrPtr^.BufSize := NrRecs * AddBufDescrPtr^.DatSLen;
          GetMem ( AddBufDescrPtr^.BufPtr, AddBufDescrPtr^.BufSize );
          AddBufDescrPtr^.LogBufSize := NrRecs;
        End Else Begin
          FreeMem ( AddBufDescrPtr, SizeOf (AddBufferDescr) );
          AddBufDescrPtr := Nil;
            {-Free all}
        End;
      End Else Begin
        DecreaseBufferMem := False;
      End;
    End;
  End;


  Procedure BufGetBlock ( Var F : IsamFile; Ref, Len : LongInt; Var Dest );

  Var
    ReadBuffered : Boolean;
    BytesRead,
    ReqLen,
    ReadLen      : Word;

  Begin
    IsamClearOK;
    ReadBuffered := ReadBufDescrPtr <> Nil;
    If ReadBuffered Then Begin
    {--Do we have it in the buffer?}
      If ReadBufDescrPtr^.LogBufStart * ReadBufDescrPtr^.DatSLen <= Ref
          Then Begin
        {-May be there or loadable}
        If (ReadBufDescrPtr^.LogBufStart + ReadBufDescrPtr^.LogBufEnd)
            * ReadBufDescrPtr^.DatSLen > Ref Then Begin
          {-The start of the required block is in the buffer}
          If (ReadBufDescrPtr^.LogBufStart + ReadBufDescrPtr^.LogBufEnd)
              * ReadBufDescrPtr^.DatSLen <= (Ref + Len) Then Begin
            {-The end of the required block is not in the buffer; so we
              cannot have this part and the needed following part in the
              buffer at the same time; this does normally not occure;
              else everything is ok}
            ReadBuffered := False;
          End;
        End Else Begin
          {-The start of the required block is not in the buffer}
          {--Will the start of the required block be in the next buffer?}
          If (ReadBufDescrPtr^.LogBufStart + ReadBufDescrPtr^.LogBufEnd
              + ReadBufDescrPtr^.LogBufSize)
              * ReadBufDescrPtr^.DatSLen <= Ref Then Begin
            {-No, so read from disk without forwarding the buffer}
            ReadBuffered := False;
          End Else Begin
            {-Yes, so forward the buffer}
            IsamLongSeek ( F, (ReadBufDescrPtr^.LogBufStart
                + ReadBufDescrPtr^.LogBufEnd) * ReadBufDescrPtr^.DatSLen );
            If Not IsamOK Then Exit;
            ReqLen := ReadBufDescrPtr^.BufSize;
            IsamBlockReadRetLen ( F, ReadBufDescrPtr^.BufPtr^, ReqLen,
                BytesRead );
            If Not IsamOK Then Exit;
            Inc (ReadBufDescrPtr^.LogBufStart, ReadBufDescrPtr^.LogBufEnd);
            ReadBufDescrPtr^.LogBufEnd := BytesRead
                Div ReadBufDescrPtr^.DatSLen;
            If (ReadBufDescrPtr^.LogBufStart + ReadBufDescrPtr^.LogBufEnd)
                * ReadBufDescrPtr^.DatSLen < (Ref + Len) Then Begin
              {-The end of the required block is not in the buffer; so we
                failed to fill the buffer with the required data; this does
                normally only occure at the end of the file; so let the
                original reading routine set any errors;
                else everything is ok}
              ReadBuffered := False;
            End;
          End;
        End;
      End Else Begin
        {-Since we do not fill the buffer by reading backward,
          read the record from disk}
        ReadBuffered := False;
      End;
    End;
    If ReadBuffered Then Begin
      Move ( Ptr ( Seg ( ReadBufDescrPtr^.BufPtr^ ),
          Ofs ( ReadBufDescrPtr^.BufPtr^ ) + Ref
          - ReadBufDescrPtr^.LogBufStart * ReadBufDescrPtr^.DatSLen )^,
          Dest, Len );
    End Else Begin
      IsamGetBlock ( F, Ref, Len, Dest );
    End;
  End;


  Procedure BufAddRec (    IFBPtr  : IsamFileBlockPtr;
                       Var Source );

  Var
    DummyRef : LongInt;

  Begin
    If AddBufDescrPtr <> Nil Then Begin
      IsamClearOK;
      If AddBufDescrPtr^.LogBufPos = AddBufDescrPtr^.LogBufSize Then Begin
        {-Buffer is full}
        FlushAddBuffer;
        If Not IsamOK Then Exit;
      End;
      Move ( Source, Ptr ( Seg ( AddBufDescrPtr^.BufPtr^ ),
          Ofs ( AddBufDescrPtr^.BufPtr^ )
          + AddBufDescrPtr^.LogBufPos * AddBufDescrPtr^.DatSLen )^,
          AddBufDescrPtr^.DatSLen );
      Inc (AddBufDescrPtr^.LogBufPos);
    End Else Begin
      IsamAddRec ( IFBPtr, DummyRef, Source );
    End;
  End;


  Procedure BufGetVariableRecRebuilt ( Var F        : IsamFile;
                                           DatSLen  : Word;
                                       Var RefNr    : LongInt;
                                           DestPtr  : Pointer;
                                           DestSize : Word;
                                       Var RecRead  : Boolean;
                                       Var Len      : Word );


    Function FindNextValidRecStart ( Var NRef : LongInt ) : Boolean;

    Var
      DelMark : LongInt;

    Begin
      FindNextValidRecStart := False;
      Repeat
        Inc (NRef);
        BufGetBlock ( F, NRef * DatSLen, SizeOf (LongInt), DelMark );
        If Not IsamOK Then Begin
          If IsamError = 10070 Then IsamClearOK;
          Exit;
        End;
      Until DelMark = 0;
      FindNextValidRecStart := True;
    End;


  Var
    Pos,
    NrOfRecs,
    IVRBPos,
    MaxRecs  : Word;
    CPtr     : ^Word;
    LPtr     : ^LongInt;
    TRef     : LongInt;

  Begin
    IsamClearOK;
    RecRead := False;

    TRef := RefNr;
    If Not FindNextValidRecStart ( TRef ) Then Begin
      {-No further data or error}
      Len := 0;
      Exit;
    End;

    RecRead := True;

    RefNr := Pred (TRef);
      {-In case we fail because of too less memory, the next trial starts
        at the best position}

    CPtr := @IVRBPtr^ [DatSLen-6];
    LPtr := @IVRBPtr^ [DatSLen-4];
    MaxRecs := (MaxVariableRecLengthM1 - (DatSLen - 6))
        Div (DatSLen - 6) + 2;
    NrOfRecs := 0;
    Pos := 0;
    LPtr^ := TRef;
    IVRBPos := 0;

    Repeat
      BufGetBlock ( F, LPtr^ * DatSLen, DatSLen, IVRBPtr^ );
      If Not IsamOK Then Begin
        If IsamError = 10070 Then RefNr := TRef;
        Exit;
      End;
      If (LongInt (Pos) + CPtr^) > DestSize Then RecRead := False;
      If RecRead Then Move ( IVRBPtr^ [IVRBPos],
          PIsamVRecBuf (DestPtr)^ [Pos], CPtr^ );
      If Pos = 0 Then Inc (IVRBPos);
      Inc (Pos, CPtr^);
      Inc (NrOfRecs);
    Until (LPtr^ = 0) Or (NrOfRecs > MaxRecs);

    If (NrOfRecs > MaxRecs) Or (Pos = 0) Then Begin
      IsamOK := False;
      IsamError := 10415;
      RefNr := TRef;
      Exit;
    End;
    Len := Pos;
    If RecRead Then RefNr := TRef;
  End;


  Procedure BufAddVariableRecRebuilt ( IFBPtr    : IsamFileBlockPtr;
                                       SourcePtr : Pointer;
                                       Len       : Word );


    Function GetNextNewLogRecNr : LongInt;

    Begin
      If AddBufDescrPtr <> Nil Then Begin
        GetNextNewLogRecNr := AddBufDescrPtr^.LogBufStart
            + AddBufDescrPtr^.LogBufPos;
      End Else Begin
        GetNextNewLogRecNr := BTFileLen ( IFBPtr );
      End;
    End;


    Function GetDatSLen : Word;

    Begin
      If AddBufDescrPtr <> Nil Then Begin
        GetDatSLen := AddBufDescrPtr^.DatSLen;
      End Else Begin
        GetDatSLen := BTDatRecordSize ( IFBPtr );
      End;
    End;


  Var
    NextLogRec : LongInt;
    Pos,
    CurCont,
    IVRBPos,
    AddDatSLen : Word;
    CPtr       : ^Word;
    LPtr       : ^LongInt;

  Begin
    IsamClearOK;

    AddDatSLen := GetDatSLen;
    If Not IsamOK Then Exit;

    CPtr := @IVRBPtr^ [AddDatSLen-6];
    LPtr := @IVRBPtr^ [AddDatSLen-4];
    Pos := 0;
    IVRBPos := 0;

    While Len > 0 Do Begin
      If Pos = 0 Then Begin
        CurCont := AddDatSLen - 6;
      End Else Begin
        CurCont := AddDatSLen - 7;
        IVRBPtr^ [0] := 1;
      End;
      If CurCont > Len Then CurCont := Len;
      Move ( PIsamVRecBuf (SourcePtr)^ [Pos], IVRBPtr^ [IVRBPos], CurCont );
      CPtr^ := CurCont;
      Dec (Len, CurCont);
      If Len = 0 Then Begin
        LPtr^ := 0;
      End Else Begin
        LPtr^ := Succ (GetNextNewLogRecNr);
        If Not IsamOK Then Exit;
      End;

      BufAddRec ( IFBPtr, IVRBPtr^ );
      If Not IsamOK Then Exit;

      If Pos = 0 Then Inc (IVRBPos);
      Inc (Pos, CurCont);
    End;
  End;


  Procedure MarkReadBufRecDeleted ( Ref : LongInt );

  Type
    PByte = ^Byte;

  Begin
    If ReadBufDescrPtr <> Nil Then Begin
      If (Ref >= ReadBufDescrPtr^.LogBufStart)
          And (Ref < (ReadBufDescrPtr^.LogBufStart
          + ReadBufDescrPtr^.LogBufEnd)) Then Begin
        {-The record is buffered}
        PByte (Ptr ( Seg ( ReadBufDescrPtr^.BufPtr^ ),
            Ofs ( ReadBufDescrPtr^.BufPtr^ ) + (Ref
            - ReadBufDescrPtr^.LogBufStart) * ReadBufDescrPtr^.DatSLen ))^
            := 1;
      End;
    End;
  End;


  Procedure RewindReadBuffer;

  Begin
    If ReadBufDescrPtr <> Nil Then Begin
      If ReadBufDescrPtr^.LogBufStart <> 1 Then Begin
        ReadBufDescrPtr^.LogBufStart := 1;
        ReadBufDescrPtr^.LogBufEnd := 0;
      End
    End;
  End;


{$IFDEF InitAllUnits}
Begin
{$ENDIF}
End.
