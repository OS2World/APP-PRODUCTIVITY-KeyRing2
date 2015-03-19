(**************************************************************)
(*     B-Tree Isam Fileblock Reindexing Ver 5.51              *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
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


Unit ReIndex;                                                        {!!.50}

Interface

Uses
  Filer,     {!!.TP}
  VRec,      {!!.TP}
  BufRecIO;

Type
  FuncBuildKey = Function  ( Var DatS;
                                 KeyNr : Word ) : IsamKeyStr;


  Procedure ReIndexFileBlock (     FBlName        : IsamFileBlockName;
                                   NumberOfKeys   : Word;
                                   IID            : IsamIndDescr;
                                   VarRec         : Boolean;
                                   BuildKeyFunc   : FuncBuildKey;
                                   DelRecDupKey   : Boolean;
                               Var MsgFileCreated : Boolean;
                                   CharConvProc   : ProcBTCharConvert;
                                   CCHookPtr      : Pointer );

    {-Reindexes a fileblock with variable or fixed record lengths by
      creating a new index file}


Implementation

  Type
    IsamSmallInfoRec = Record               {!!!to remove later}
      Gener : Array [1..5] Of LongInt;
      ADK   : Boolean;
    End;

  Procedure ReIndexFileBlock (     FBlName        : IsamFileBlockName;
                                   NumberOfKeys   : Word;
                                   IID            : IsamIndDescr;
                                   VarRec         : Boolean;
                                   BuildKeyFunc   : FuncBuildKey;
                                   DelRecDupKey   : Boolean;
                               Var MsgFileCreated : Boolean;
                                   CharConvProc   : ProcBTCharConvert;
                                   CCHookPtr      : Pointer );

  Var
    FNameTemp,
    FNameD,
    FNameI      : IsamFileBlockName;
    IFBPtr      : IsamFileBlockPtr;
    BufPtr      : Pointer;
    BufLen      : Word;
    MsgFile     : Text;
    DataRecLen  : LongInt;
    IORes       : Integer;

    Procedure ReXUserRoutine (     UserRoutine : Pointer;
                                   KeyNr       : Word;
                                   DatSNrR     : LongInt;
                                   DatSNrW     : LongInt;
                               Var DatS;
                                   Len         : Word );

      Procedure CallUserRoutine (     KeyNr   : Word;
                                      DatSNrR,
                                      DatSNrW : LongInt;
                                  Var DatS;
                                      Len     : Word ); Inline
        {-Call UserRoutine with an action code}
        ( $FF / $5E / <UserRoutine ); {call far dword ptr [bp+<UserRoutine]}

    Begin
      CallUserRoutine ( KeyNr, DatSNrR, DatSNrW, DatS, Len );
    End;


    Procedure CheckDatF ( Var DatSLen : LongInt );

    Var
      F       : IsamFile;
      Header  : IsamSmallInfoRec;
      DosSize : LongInt;
      NumRec  : LongInt;
      FFree   : LongInt;


      Procedure UnDo ( Err : Integer );

      Begin
        IsamClose ( F );
        IsamOK := Err <> 0;
        IsamError := Err;
      End;


    Begin
      DatSLen := 0;
      IsamAssign ( F, IsamForceExtension ( FNameD, DatExtension ) );
      IsamReset ( F, False, False );
      If Not IsamOK Then Exit;

      IsamLongSeekEOF ( F, DosSize );
      If Not IsamOK Then Begin
        UnDo ( IsamError );
        Exit;
      End;

      IsamGetBlock ( F, 0, SizeOf (Header), Header );
      If Not IsamOK Then Begin
        UnDo ( IsamError );
        Exit;
      End;

      If Header.Gener [4] {LenRec} = 0 Then Begin
        UnDo ( 10215 );
        Exit;
      End;

      NumRec := DosSize Div Header.Gener [4] {LenRec};
      If NumRec * Header.Gener [4] {LenRec} <> DosSize Then Begin
        UnDo ( 10215 );
        Exit;
      End;
      DatSLen := Header.Gener [4] {LenRec};

      If Pred (NumRec) <> Header.Gener [3] {NumRec} Then Begin
        UnDo ( 10215 );
        Exit;
      End;

      If Header.Gener [1] {FirstFree} <> -1 Then Begin
        If Header.Gener [1] {FirstFree} > 0 Then Begin
          IsamGetBlock ( F, Header.Gener [1] {FirstFree},
              SizeOf (FFree), FFree );
          If Not IsamOK Then Begin
            UnDo ( IsamError );
            Exit;
          End;
        End Else Begin
          FFree := 0;
        End;
        If FFree = 0 Then Begin
          UnDo ( 10215 );
          Exit;
        End;
      End;

      DatSLen := Header.Gener [4] {LenRec};
      IsamClose ( F );
    End;


    Procedure CreateNewIndexFile;

    Var
      F       : IsamFile;
      SaveExt : String [3];

    Begin
      SaveExt := DatExtension;
      DatExtension := MsgExtension;

    {--Create a fileblock with a data file name equal to message file name;
       so we do not (!) overwrite the data file}
      BTCreateFileBlock ( FNameD + ';' + FNameI, DataRecLen, NumberOfKeys,
          IID );

      DatExtension := SaveExt;
      If Not IsamOK Then Exit;

      IsamAssign ( F, IsamForceExtension ( FNameD, MsgExtension ) );
      IsamDelete ( F );
    End;


    Procedure SetNewHeader;

    Var
      F      : IsamFile;
      Header : IsamSmallInfoRec;


      Procedure UnDo ( Err : Integer );

      Begin
        IsamClose ( F );
        IsamOK := Err <> 0;
        IsamError := Err;
      End;


    Begin
    {--Open the data file to read the headerd}
      IsamAssign ( F, IsamForceExtension ( FNameD, DatExtension ) );
      IsamReset ( F, False, False );
      If Not IsamOK Then Exit;

      IsamGetBlock ( F, 0, SizeOf (Header), Header );
      If Not IsamOK Then Begin
        UnDo ( IsamError );
        Exit;
      End;

    {--Set the (potentially different) number of keys in the header}
      Header.Gener [5] := NumberOfKeys;

    {--Clear the data buffered flag}
      Header.ADK := False;

    {--Write the header back to the data file and close it}
      IsamPutBlock ( F, 0, SizeOf (Header), Header );
      If Not IsamOK Then Begin
        UnDo ( IsamError );
        Exit;
      End;
      IsamClose ( F );
    End;


    Procedure UnDo ( Level : Word; Error : Integer );

    Begin
      If BufPtr <> Nil Then Begin
        FreeMem ( BufPtr, BufLen );
      End;

      If MsgFileCreated Then Close ( MsgFile );

      If Level >= 2 Then Begin
        DoneRecBuffers;
      End;

      If Level >= 1 Then Begin
        BTCloseFileBlock ( IFBPtr );
      End;

      IsamOK := False;
      IsamError := Error;
    End;


    Function AdjustBuffer ( ToSize : Word ) : Boolean;
      {-Called only when variable recs are used}


      Function Alloc ( Var P : Pointer; Size : Word ) : Boolean;

      Begin
        Alloc := False;
        While MaxAvail < Size Do Begin
          If Not DecreaseBufferMem Then Exit;
        End;
        GetMem ( P, Size );
        Alloc := True;
      End;


    Begin
      AdjustBuffer := False;

      If BufPtr <> Nil Then Begin
        FreeMem ( BufPtr, BufLen );
        BufPtr := Nil;
      End;

      If Not Alloc ( BufPtr, ToSize ) Then Exit;
      BufLen := ToSize;

      AdjustBuffer := True;
    End;


    Procedure DumpToMessageFile ( Nr   : Word;
                                  Ref : LongInt;
                                  IKS : IsamKeyStr );

    Var
      PC : ^Char;
      W  : Word;

    Begin
      If Not MsgFileCreated Then Begin
        Assign ( MsgFile, IsamForceExtension ( FNameD, MsgExtension ) );
        Rewrite ( MsgFile );
        IORes := IOResult;
        If IORes <> 0 Then Exit;
        MsgFileCreated := True;
      End;

      Writeln ( MsgFile, 'Key:<', IKS, '>', ' KeyNr: ', Nr, ' Ref: ', Ref,
        ' not added' );
      IORes := IOResult;
      If IORes <> 0 Then Exit;

      If DelRecDupKey Then Begin
        WriteLn ( MsgFile, 'Data record deleted - Dump follows');
        PC := @BufPtr^;
        For W := 1 To DataRecLen Do Begin
          Write ( MsgFile, PC^);
          Inc (LongInt (PC));
        End;
        Writeln ( MsgFile, ^M^J);
        IORes := IOResult;
      End;
    End;


  Var
    I, J,
    MaxSize,
    CurRecLen    : Word;
    Stop,
    RetryRead,
    WasRead      : Boolean;
    CurrentRef,
    DatSRead,
    DatSWritten  : LongInt;
    IKS          : IsamKeyStr;

  Begin
    IsamClearOK;

  {--Set buffer pointers to Nil and reference return value to no}
    BufPtr := Nil;
    MsgFileCreated := False;

  {--Get file names for data and index file}
    IsamExtractFileNames ( FBlName, FNameD, FNameTemp );
    IsamExtractFileNames ( FNameTemp, FNameI, FNameTemp {dummy} );

  {--Check data file and return record length}
    CheckDatF ( DataRecLen );
    If Not IsamOK Then Exit;

  {--Check record lengths}
    If VarRec Then Begin
      MaxSize := MaxVariableRecLength;
    End Else Begin
      MaxSize := $FFFF;
    End;
    If DataRecLen > MaxSize Then Begin
      UnDo ( 0, 10412 );
      Exit;
    End;

  {--Adjust buffer for variable recs}
    If VarRec Then Begin
      If Not BTAdjustVariableRecBuffer ( DataRecLen ) Then Begin
        UnDo ( 0, 10411 );
        Exit;
      End;
    End;

  {--Create a new and empty index file}
    CreateNewIndexFile;
    If Not IsamOK Then Begin
      UnDo ( 0, IsamError );
      Exit;
    End;

  {--Modify the header of the data file}
    SetNewHeader;
    If Not IsamOK Then Begin
      UnDo ( 0, IsamError );
      Exit;
    End;

  {--The fileblock is now prepared to be opened; so open the fileblock}
    BTOpenFileBlock ( IFBPtr, FNameD + ';' + FNameI, False, False, False,
        False );
    If Not IsamOK Then Begin
      UnDo ( 0, IsamError );
      Exit;
    End;

  {--Get buffer for data read (no write)}
    CreateRecBuffers ( DataRecLen, Nil );

  {--Get buffer for a single record}
    If Not AdjustBuffer ( DataRecLen ) Then Begin
      UnDo ( 2, 10411 );
      Exit;
    End;

  {--Reindexing loop}
    For I := 1 To NumberOfKeys Do Begin
      RewindReadBuffer;

    {--Initialize status and control data}
      CurRecLen := DataRecLen;
      CurrentRef := 0;
      DatSRead := 0;
      DatSWritten := 0;
      Stop := False;

      Repeat
      {--Read record}
        If VarRec Then Begin
          Repeat
            RetryRead := False;
            BufGetVariableRecRebuilt ( IFBPtr^.DatF, DataRecLen, CurrentRef,
                BufPtr, BufLen, WasRead, CurRecLen );
            If Not IsamOK Then Begin
              If (IsamError = 10415) Or (IsamError = 10070) Then Begin
                {-A fractal record was read, skip it and retry}
                IsamClearOK;
                RetryRead := True;
              End Else Begin
                {-A serious error occured}
                UnDo ( 2, IsamError );
                Exit;
              End;
            End Else Begin
              If Not WasRead Then Begin
                If CurRecLen = 0 Then Begin
                  {-No more data}
                  Stop := True;
                End Else Begin
                  {-Buffer was too small}
                  If AdjustBuffer ( CurRecLen ) Then Begin
                    {-Buffer adjusted, so try it again}
                    RetryRead := True;
                  End Else Begin
                    {-No more memory for buffer}
                    UnDo ( 2, 10411 );
                    Exit;
                  End;
                End;
              End;
            End;
          Until Not RetryRead;
        End Else Begin
          Repeat
            Inc (CurrentRef);
            BufGetBlock ( IFBPtr^.DatF, CurrentRef * DataRecLen, DataRecLen,
                BufPtr^ );
            If Not IsamOk Then Begin
              If IsamError = 10070 Then Begin
                IsamClearOK;
                Stop := True;
              End Else Begin
                UnDo ( 4, IsamError );
                Exit;
              End;
            End;
          Until Stop Or (LongInt (BufPtr^) = 0);
        End;

        If Not Stop Then Begin
          Inc (DatSRead);
          CharConvProc ( BufPtr, CurRecLen, True, CCHookPtr );
          IKS := BuildKeyFunc ( BufPtr^, I );
          If Not IsamOK Then Begin
            UnDo ( 2, 10470 );
            Exit;
          End;
          If AddNullKeys Or (IKS <> '') Then Begin
            BTAddKey ( IFBPtr, I, CurrentRef, IKS );
            If Not IsamOK Then Begin
              If IsamError = 10230 Then Begin
                DumpToMessageFile ( I, CurrentRef, IKS );
                IsamClearOK;
                If IORes <> 0 Then Begin
                  UnDo ( 2, 9500 + IORes );
                  Exit;
                End;
                If DelRecDupKey Then Begin
                  For J := 1 To Pred (I) Do Begin
                    BTDeleteKey ( IFBPtr, J, CurrentRef,
                        BuildKeyFunc ( BufPtr^, J ) );
                  End;
                  If VarRec Then Begin
                    BTDeleteVariableRec ( IFBPtr, CurrentRef );
                  End Else Begin
                    BTDeleteRec ( IFBPtr, CurrentRef );
                  End;
                  MarkReadBufRecDeleted ( CurrentRef );
                End;
              End Else Begin
                UnDo ( 2, IsamError );
                Exit;
              End;
            End Else Begin
              Inc (DatSWritten);
            End;
          End;
          If IsamReXUserProcPtr <> Nil Then Begin
            ReXUserRoutine ( IsamReXUserProcPtr, I, DatSRead, DatSWritten,
                BufPtr^, CurRecLen );
            If Not IsamOK Then Begin
              UnDo ( 2, 10460 );
              Exit;
            End;
          End;
        End;
      Until Stop;
    End;

    FreeMem ( BufPtr, BufLen );
    DoneRecBuffers;
      {-Cannot result in an error}
    If MsgFileCreated Then Close ( MsgFile );
    I := IOResult;
      {-Not really an error, if it may not be clossed correctly}
    BTCloseFileBlock ( IFBPtr );
  End;


{$IFDEF InitAllUnits}
Begin
{$ENDIF}
End.
