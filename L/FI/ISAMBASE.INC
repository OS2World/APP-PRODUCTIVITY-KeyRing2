(**************************************************************)
(*          B-Tree Isam Include Ver 5.51                      *)
(*   Copyright (C) 1986-1991 Dipl.Math. Ralf Nagel            *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

  Function IsamCheckLockError : Boolean;

  Begin
    IsamCheckLockError := False;
    If IsamDriveNotReadyError Or (IOResult = 152) Then Begin
      IsamDriveNotReadyError := False;
      IsamLockError := False;
      IsamOK := False;
      IsamError := 10110;
      IsamCheckLockError := True;
      Exit;
    End;
    If IsamLockError Then Begin
      IsamLockError := False;
      IsamOK := False;
      IsamError := 10140;
      IsamCheckLockError := True;
    End;
  End;


  Procedure IsamClearOK;

  Begin
    IsamOK := True;
    IsamError := 0;
    IsamLockError := False;
    IsamDriveNotReadyError := False;
    IsamDOSError := 0;
    IsamDOSFunc := 0;
  End;


  Procedure SaveErrorStat ( Var ErrSt : ErrStatSaveRec );

  Begin
    With ErrSt Do Begin
      OK := IsamOK;
      Error := IsamError;
      DError := IsamDOSError;
      DFunc := IsamDOSFunc;
    End;
  End;


  Procedure RestoreErrorStat ( ErrSt : ErrStatSaveRec );

  Begin
    With ErrSt Do Begin
      IsamOK := OK;
      IsamError := Error;
      IsamDOSError := DError;
      IsamDOSFunc := DFunc;
    End;
  End;


  Function IsamSetDosRetry ( NrOfRetries, WaitTime : Integer ) : Boolean;

  Var
    IRR : GenRegisters;

  Begin
    DefaultRegisters ( IRR );
    With IRR Do Begin
      AX := $440B;
      BX := NrOfRetries;
      CX := WaitTime;
      DX := NrOfRetries;
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos ( IRR );
      If Odd (Flags) And (IsamDOSError = 0) Then IsamDOSError := AX;
      IsamSetDosRetry := Not Odd (Flags);
    End;
  End;


  Procedure IsamAssign ( Var F : IsamFile; FName : IsamFileName );

  Var
    L : Word;

  Begin
    With F Do Begin
      L := Length (FName);
      If L > Pred (SizeOf (Name)) Then L := Pred (SizeOf (Name));
      Move ( FName [1], Name, L );
      Name [L] := #0;
      Handle := 65535;
    End;
  End;


  Function IsamGetFileName ( Var F : IsamFile ) : IsamFileName;

  Var
    FName : IsamFileName;

  Begin
    FName [0] := Char (Pred (SizeOf (IsamFileName)));
    Move ( F.Name, FName [1], Byte (FName [0]));
    FName [0] := Char (Pred (Pos (#0, FName)));
    IsamGetFileName := FName;
  End;


  Function IsamExistsIsamFile ( Var IsamF : IsamFile ) : Boolean;

  Var
    IRR : GenRegisters;

  Begin
    DefaultRegisters ( IRR );
    With IRR, IsamF Do Begin
      AX := $4300;           {get file attribute}
      DS := Seg (Name);
      DX := Ofs (Name);
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos ( IRR );
      IsamExistsIsamFile := False;
      If IsamCheckLockError Then Exit;
      If Odd (Flags) And (IsamDOSError = 0) Then IsamDOSError := AX;
      IsamExistsIsamFile := Not Odd (Flags);
    End;
  End;


  Function IsamExists ( Name : IsamFileName ) : Boolean;

  Var
    IsamF : IsamFile;

  Begin
    IsamAssign ( IsamF, Name );
    IsamExists := IsamExistsIsamFile ( IsamF );
  End;


  Procedure IsamRewrite ( Var F : IsamFile );

  Var
    IRR : GenRegisters;

  Begin
    DefaultRegisters ( IRR );
    With IRR Do Begin
      AX := $3C00;
      CX := 0;
      DS := Seg (F.Name);
      DX := Ofs (F.Name);
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos ( IRR );
      If IsamCheckLockError Then Exit;
      If Odd (Flags) Then Begin
        If IsamDOSError = 0 Then IsamDOSError := AX;
        IsamOK := False;
        Case AX Of
          3 : IsamError := 9900;
          4 : IsamError := 9901;
          Else IsamError := 10140;
        End;
        Exit;
      End;
      F.Handle := AX;
    End;
  End;


  Procedure IsamClose ( Var F : IsamFile );

  Var
    IRR : GenRegisters;

  Begin
    DefaultRegisters ( IRR );
    With IRR Do Begin
      AX := $3E00;
      BX := F.Handle;
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos ( IRR );
      If IsamCheckLockError Then Exit;
      If Odd (Flags) Then Begin
        If IsamDOSError = 0 Then IsamDOSError := AX;
        IsamOK := False;
        Case AX Of
          6 : IsamError := 9904;
          Else IsamError := 10140;
        End;
        Exit;
      End;
      F.Handle := 65535;
    End;
  End;


  Procedure IsamDelete ( Var F : IsamFile );

  Var
    IRR : GenRegisters;

  Begin
    DefaultRegisters ( IRR );
    With IRR Do Begin
      AX := $4100;
      DS := Seg (F.Name);
      DX := Ofs (F.Name);
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos ( IRR );
      If IsamCheckLockError Then Exit;
      If Odd (Flags) Then Begin
        If IsamDOSError = 0 Then IsamDOSError := AX;
        IsamOK := False;
        Case AX Of
          2 : IsamError := 9903;
          3 : IsamError := 9900;
          Else IsamError := 10140;
        End;
      End;
    End;
  End;


  Procedure IsamRename ( Var F : IsamFile; FName : IsamFileName );

  Var
    IRR : GenRegisters;
    Nam : Array [0..64] Of Char;

  Begin
    DefaultRegisters ( IRR );
    With IRR Do Begin
      AX := $5600;
      DS := Seg (F.Name);
      DX := Ofs (F.Name);
      Move ( FName [1], Nam, Length (FName) );
      Nam [Length (FName)] := #0;
      ES := Seg (Nam);
      DI := Ofs (Nam);
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos ( IRR );
      If IsamCheckLockError Then Exit;
      If Odd (Flags) Then Begin
        If IsamDOSError = 0 Then IsamDOSError := AX;
        IsamOK := False;
        Case AX Of
          2  : IsamError := 9903;
          3,
          17 : IsamError := 9900;
          Else IsamError := 10140;
        End;
      End;
    End;
  End;


  Procedure IsamLongSeek ( Var F : IsamFile; Ref : LongInt );

  Var
    OK,
    Result : Word;

  Begin
    Inline (
      $B8 / $00 / $42 /                              {MOV AX, $4200}
      $C4 / $7E / < F /                              {LES DI, [BP+F]}
      $26 / $8B / $1D /                              {ES: MOV BX, [DI] (Handle)}
      $8B / $4E / < Ref+2 /                          {MOV CX, [BP+Hi(Ref)]}
      $8B / $56 / < Ref /                            {MOV DX, [BP+Lo(Ref)]}
      $CD / $21 /                                    {INT $21}
      $9C /                                          {PUSHF}
      $5B /                                          {POP BX}
      $89 / $46 / < Result /                         {MOV [BP+Result], AX}
      $89 / $5E / < OK                               {MOV [BP+OK], BX}
    );
    If IsamDOSError = 0 Then IsamDOSFunc := $4200;
    If IsamCheckLockError Then Exit;
    If Odd (OK) Then Begin
      If IsamDOSError = 0 Then IsamDOSError := Result;
      IsamOK := False;
      Case Result Of
        6 : IsamError := 9904;
        Else IsamError := 10140;
      End;
    End;
  End;


  Procedure IsamLongSeekEOF ( Var F : IsamFile; Var Len : LongInt );

  Var
    IRR : GenRegisters;
    L   : Record
      Lo, Hi : Word;
    End absolute Len;

  Begin
    DefaultRegisters ( IRR );
    With IRR Do Begin
      AX := $4202;
      BX := F.Handle;
      CX := 0;
      DX := 0;
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos ( IRR );
      If IsamCheckLockError Then Exit;
      L.Lo := AX;
      L.Hi := DX;
      If Odd (Flags) Then Begin
        If IsamDOSError = 0 Then IsamDOSError := AX;
        IsamOK := False;
        Case AX Of
          6 : IsamError := 9904;
          Else IsamError := 10140;
        End;
      End;
    End;
  End;


  Procedure IsamBlockReadRetLen ( Var F         : IsamFile;
                                  Var Dest;
                                      Len       : Word;
                                  Var BytesRead : Word );

  Var
    OK,
    Result : Word;

  Begin
    Inline (
      $1E /                                          {PUSH DS}
      $B8 / $00 / $3F /                              {MOV AX, $3F00}
      $C4 / $7E / < F /                              {LES DI, [BP+F]}
      $26 / $8B / $1D /                              {ES: MOV BX,[DI](Handle)}
      $8B / $4E / < Len /                            {MOV CX, [BP+Len]}
      $8B / $56 / < Dest /                           {MOV DX, [BP+Lo(Dest)]}
      $8E / $5E / < Dest+2 /                         {MOV DS, [BP+Hi(Dest)]}
      $CD / $21 /                                    {INT $21}
      $1F /                                          {POP DS}
      $9C /                                          {PUSHF}
      $5B /                                          {POP BX}
      $89 / $46 / < Result /                         {MOV [BP+Result], AX}
      $89 / $5E / < OK                               {MOV [BP+OK], BX}
    );
    If IsamDOSError = 0 Then IsamDOSFunc := $3F00;
    If IsamCheckLockError Then Exit;
    If Odd (OK) Then Begin
      If IsamDOSError = 0 Then IsamDOSError := Result;
      IsamOK := False;
      Case Result Of
        6 : IsamError := 9904;
        Else IsamError := 10140;
      End;
    End Else Begin
      BytesRead := Result;
    End;
  End;


  Procedure IsamBlockRead ( Var F    : IsamFile;
                            Var Dest;
                                Len  : Word );

  Var
    BytesRead : Word;

  Begin
    IsamBlockReadRetLen ( F, Dest, Len, BytesRead );
    If IsamOK Then Begin
      If BytesRead <> Len Then Begin
        IsamOK := False;
        IsamError := 10070;
      End;
    End;
  End;


  Procedure IsamBlockWrite ( Var F       : IsamFile;
                             Var Source;
                                 Len     : Word );

  Var
    OK,
    Result : Word;

  Begin
    Inline (
      $1E /                                          {PUSH DS}
      $B8 / $00 / $40 /                              {MOV AX, $4000}
      $C4 / $7E / < F /                              {LES DI, [BP+F]}
      $26 / $8B / $1D /                              {ES: MOV BX, [DI] (Handle)}
      $8B / $4E / < Len /                            {MOV CX, [BP+Len]}
      $8B / $56 / < Source /                         {MOV DX, [BP+Lo(Source)]}
      $8E / $5E / < Source+2 /                       {MOV DS, [BP+Hi(Source)]}
      $CD / $21 /                                    {INT $21}
      $1F /                                          {POP DS}
      $9C /                                          {PUSHF}
      $5B /                                          {POP BX}
      $89 / $46 / < Result /                         {MOV [BP+Result], AX}
      $89 / $5E / < OK                               {MOV [BP+OK], BX}
    );
    If IsamDOSError = 0 Then IsamDOSFunc := $4000;
    If IsamCheckLockError Then Exit;
    If Odd (OK) Then Begin
      If IsamDOSError = 0 Then IsamDOSError := Result;
      IsamOK := False;
      Case Result Of
        6 : IsamError := 9904;
        Else IsamError := 10140;
      End;
      Exit;
    End Else Begin
      If Len <> Result Then Begin
        IsamOK := False;
        IsamError := 10075;
      End;
    End;
  End;


  Procedure IsamReset ( Var F : IsamFile; NetUsed, ReadOnly : Boolean );

  Var
    IRR : GenRegisters;

  Begin
    DefaultRegisters ( IRR );
    With IRR Do Begin
      AH := $3D;
      If ReadOnly Then Begin
        AL := 0;
      End Else Begin
        AL := 2;
      End;
      If Not InheritFileHandles Then AL := AL Or $80;              {!!.41}
      If NetUsed Then Begin                                        {!!.42}
        AL := AL Or 64;    {DenyNone}                              {!!.42}
      End Else Begin                                               {!!.42}
        AL := AL Or 16;    {DenyBoth}                              {!!.42}
      End;                                                         {!!.42}
      DS := Seg (F.Name);
      DX := Ofs (F.Name);
      If IsamDOSError = 0 Then IsamDOSFunc := AX;
      CallMsDos ( IRR );
      If IsamCheckLockError Then Exit;
      If Odd (Flags) Then Begin
        If IsamDOSError = 0 Then IsamDOSError := AX;
        IsamOK := False;
        Case AX Of
          2  : IsamError := 9903;
          3  : IsamError := 9900;
          4  : IsamError := 9901;
          12 : IsamError := 9908;
          Else IsamError := 10140;
        End;
        Exit;
      End;
      F.Handle := AX;
    End;
  End;


  Function IsamAddWordToSeg ( P : Pointer; Incr : Word ) : Pointer;

  Type
    SegOfs = Record
      Dummy, S : Word;
    End;

  Begin
    Inc (SegOfs (P).S, Incr);
    IsamAddWordToSeg := P;
  End;


  Procedure IsamGetBlock ( Var F : IsamFile; Ref, Len : LongInt; Var Dest );

  Var
  {$IFDEF DPMIOrWnd}                                                {!!.42}
    DestPtr : PChar;                                                {!!.42}
   {$IFDEF Ver15}                                                   {!!.50}
    TempPtr : Pointer;                                              {!!.50}
   {$ENDIF}                                                         {!!.50}
  {$ELSE}                                                           {!!.42}
    DestPtr : ^Byte;
  {$ENDIF}                                                          {!!.42}

  Const
    LIMaxInt     = $FFF0;  {must be a multiple of 16}
    LIRestMaxInt = $FFFF - LIMaxInt + 1;                            {!!.42}

  Begin
    DestPtr := Addr (Dest);
    IsamLongSeek ( F, Ref );
    If Not IsamOK Then Exit;
    While Len > LIMaxInt Do Begin
      IsamBlockRead ( F, DestPtr^, LIMaxInt );
      If Not IsamOK Then Exit;
      Len := Len - LIMaxInt;
    {$IFDEF DPMIOrWnd}                                              {!!.42}
      If Len > LIRestMaxInt Then Begin                              {!!.42}
      {$IFDEF Ver15}                                                {!!.50}
        TempPtr := Ptr ( Seg (DestPtr^), Ofs (DestPtr^)             {!!.50}
            + Pred (LIRestMaxInt) );                                {!!.50}
        IsamBlockRead ( F, TempPtr^, LIRestMaxInt );                {!!.50}
      {$ELSE}                                                       {!!.50}
        IsamBlockRead ( F, (DestPtr + Pred (LIRestMaxInt))^,        {!!.42}
            LIRestMaxInt );                                         {!!.42}
      {$ENDIF}                                                      {!!.50}
        If Not IsamOK Then Exit;                                    {!!.42}
        Len := Len - LIRestMaxInt;                                  {!!.42}
      {$IFDEF Ver15}                                                {!!.50}
        DestPtr := IsamAddWordToSeg ( DestPtr, 8 );                 {!!.50}
      {$ELSE}                                                       {!!.50}
        DestPtr := IsamAddWordToSeg ( DestPtr, SelectorInc );       {!!.42}
      {$ENDIF}                                                      {!!.50}
      End Else Begin                                                {!!.42}
      {$IFDEF Ver15}                                                {!!.50}
        DestPtr := Ptr ( Seg (DestPtr^), Ofs (DestPtr^)             {!!.50}
            + LIMaxInt );                                           {!!.50}
      {$ELSE}                                                       {!!.50}
        DestPtr := DestPtr + LIMaxInt;                              {!!.42}
      {$ENDIF}                                                      {!!.50}
      End;                                                          {!!.42}
    {$ELSE}                                                         {!!.42}
      DestPtr := IsamAddWordToSeg ( DestPtr, LIMaxInt Shr 4 );
    {$ENDIF}                                                        {!!.42}
    End;
    IsamBlockRead ( F, DestPtr^, Word (Len) );
  End;


  Procedure IsamPutBlock ( Var F : IsamFile; Ref, Len : LongInt; Var Source );

  Var
  {$IFDEF DPMIOrWnd}                                                {!!.42}
    SourcePtr : PChar;                                              {!!.42}
   {$IFDEF Ver15}                                                   {!!.50}
    TempPtr : Pointer;                                              {!!.50}
   {$ENDIF}                                                         {!!.50}
  {$ELSE}                                                           {!!.42}
    SourcePtr : ^Byte;
  {$ENDIF}                                                          {!!.42}

  Const
    LIMaxInt = $FFF0;  { must be a multiple of 16 }
    LIRestMaxInt = $FFFF - LIMaxInt + 1;                            {!!.42}

  Begin
    SourcePtr := Addr (Source);
    IsamLongSeek ( F, Ref );
    If Not IsamOK Then Exit;
    While Len > LIMaxInt Do Begin
      IsamBlockWrite ( F, SourcePtr^, LIMaxInt );
      If Not IsamOK Then Exit;
      Len := Len - LIMaxInt;
    {$IFDEF DPMIOrWnd}                                              {!!.42}
      If Len > LIRestMaxInt Then Begin                              {!!.42}
      {$IFDEF Ver15}                                                {!!.50}
        TempPtr := Ptr ( Seg (SourcePtr^), Ofs (SourcePtr^)         {!!.50}
            + Pred (LIRestMaxInt) );                                {!!.50}
        IsamBlockWrite ( F, TempPtr^, LIRestMaxInt );               {!!.50}
      {$ELSE}                                                       {!!.50}
        IsamBlockWrite ( F, (SourcePtr + Pred (LIRestMaxInt))^,     {!!.42}
            LIRestMaxInt );                                         {!!.42}
      {$ENDIF}                                                      {!!.50}
        If Not IsamOK Then Exit;                                    {!!.42}
        Len := Len - LIRestMaxInt;                                  {!!.42}
      {$IFDEF Ver15}                                                {!!.50}
        SourcePtr := IsamAddWordToSeg ( SourcePtr, 8 );             {!!.50}
      {$ELSE}                                                       {!!.50}
        SourcePtr := IsamAddWordToSeg ( SourcePtr, SelectorInc );   {!!.42}
      {$ENDIF}                                                      {!!.50}
      End Else Begin                                                {!!.42}
      {$IFDEF Ver15}                                                {!!.50}
        SourcePtr := Ptr ( Seg (SourcePtr^), Ofs (SourcePtr^)       {!!.50}
            + LIMaxInt );                                           {!!.50}
      {$ELSE}                                                       {!!.50}
        SourcePtr := SourcePtr + LIMaxInt;                          {!!.42}
      {$ENDIF}                                                      {!!.50}
      End;                                                          {!!.42}
    {$ELSE}                                                         {!!.42}
      SourcePtr := IsamAddWordToSeg ( SourcePtr, LIMaxInt Shr 4 );
    {$ENDIF}                                                        {!!.42}
    End;
    IsamBlockWrite ( F, SourcePtr^, Word (Len) );
  End;


  Procedure IsamPutDummyBlock ( Var F : IsamFile; Ref, Len : LongInt );

  Const
    EmptyArrLen = 1024;                                           {!!.42mod}

  Var
    EmptyArr  : Array [1..EmptyArrLen] Of Char;
    BufPtr    : Pointer;                                             {!!.42}
    Allocated : Boolean;                                             {!!.42}

  Begin
    Allocated := (Len < $FFF0) And (Len < MaxAvail)                  {!!.42}
        And (Len > EmptyArrLen);                                     {!!.42}
    If Allocated Then Begin                                          {!!.42}
      GetMem ( BufPtr, Len );                                        {!!.42}
      FillChar ( BufPtr^, Len, 0 );                                  {!!.42}
      IsamPutBlock ( F, Ref, Len, BufPtr^ );                         {!!.42}
      FreeMem ( BufPtr, Len );                                       {!!.42}
    End Else Begin                                                   {!!.42}
      FillChar ( EmptyArr, SizeOf (EmptyArr), 0 );
      IsamLongSeek ( F, Ref );
      If Not IsamOK Then Exit;
      While Len > EmptyArrLen Do Begin
        IsamBlockWrite ( F, EmptyArr, SizeOf (EmptyArr) );
        If Not IsamOK Then Exit;
        Len := Len - SizeOf (EmptyArr);
      End;
      IsamBlockWrite ( F, EmptyArr, Word (Len) );
    End;                                                             {!!.42}
  End;


  Procedure IsamFlush ( Var F        : IsamFile;
                        Var WithDUP  : Boolean;
                            NetUsed  : Boolean );

  Var
    Regs     : GenRegisters;
    Flush33  : Boolean;

  Begin
    DefaultRegisters ( Regs );
    With Regs Do Begin
      Flush33  := IsamFlushDOS33;
      If IsamFlushDOS33 Then Begin
        {-Try DOS 3.3 flush call}
        AH := $68;
        BX := F.Handle;
        CallMsDos ( Regs );   {Flush the handle}
        Flush33 := Not Odd (Flags);
        If Flush33 Then Begin
          WithDup := True;
          Exit;
        End;
      End;
      If Not Flush33 Then Begin
        AH := $45;
        BX := F.Handle;
        If IsamDOSError = 0 Then IsamDOSFunc := AX;
        CallMsDos ( Regs );   {DUP the handle}
        If Not Odd (Flags) Then Begin
          WithDUP := True;
          BX := AX;
          AH := $3E;
          If IsamDOSError = 0 Then IsamDOSFunc := AX;
          CallMsDos (Regs);   {Close the DUP handle}
          If Odd (Flags) Then Begin
            If IsamDOSError = 0 Then IsamDOSError := AX;
            IsamOK := False;
            If AX = 6 Then Begin
              IsamError := 9904;
            End Else Begin
              IsamError := 10140;
            End;
          End;
        End Else Begin
          WithDUP := False;
          If NetUsed Then Begin
            If IsamDOSError = 0 Then IsamDOSError := AX;
            IsamOK := False;
            IsamError := 10150;
          End Else Begin
            IsamClose ( F );
            If Not IsamOK Then Exit;
            IsamReset ( F, False, False );
          End;
        End;
      End;
    End;
  End;


  Procedure IsamExtractFileNames (     FNameComp : IsamFileBlockName;
                                   Var FNameD,
                                       FNameI    : IsamFileBlockName );

  Var
    SP : Word;


    Procedure Trim ( Var S : IsamFileBlockName );

    Var
      P : Word;

    Begin
      While True Do Begin
        P := Pos ( ' ', S );
        If P = 0 Then Exit;
        Delete ( S, P, 1 );
      End;
    End;


  Begin
    Trim ( FNameComp );
    SP := Pos ( ';', FNameComp );
    If SP = 0 Then Begin
      FNameD := FNameComp;
      FNameI := FNameComp;
    End Else Begin
      FNameD := Copy ( FNameComp, 1, Pred (SP) );
      FNameI := Copy ( FNameComp, Succ (SP), Length (FNameComp) - SP );
    End;
  End;


  Procedure IsamCopyFile ( Source,
                           Dest                  : IsamFileBlockName;
                           DeleteSourceAfterCopy : Boolean );

  Var
    SourceF,
    DestF     : IsamFile;
    BufPtr    : Pointer;
    BufSize,
    BytesRead : Word;


    Procedure UnDo ( Err : Integer; All : Boolean );

    Begin
      If All Then FreeMem ( BufPtr, BufSize );
      IsamClose ( SourceF );
      IsamClose ( DestF );
      IsamOK := False;
      IsamError := Err;
    End;


    Function DetermineBufferSize : Boolean;

    Const
      MinBufSize = 1024;                                          {!!.43mod}
      MaxBufSize = 32766;                                         {!!.42mod}

    Var
      MaxFree : LongInt;
      Nr      : Word;

    Begin
      DetermineBufferSize := True;
      MaxFree := MaxAvail;
      If MaxFree >= MaxBufSize Then Begin
        BufSize := MaxBufSize;
        Exit;
      End;
      If MaxFree < MinBufSize Then Begin
        DetermineBufferSize := False;
        Exit;
      End;
      Nr := MaxFree Div MinBufSize;
      BufSize := Nr * MinBufSize;
    End;


  Begin
    IsamAssign ( SourceF, Source );
    IsamAssign ( DestF, Dest );
    IsamReset ( SourceF, False, True );
    If Not IsamOK Then Exit;
    IsamRewrite ( DestF );
    If Not IsamOK Then Begin
      UnDo ( IsamError, False );
      Exit;
    End;
    If DetermineBufferSize Then Begin
      GetMem ( BufPtr, BufSize );
    End Else Begin
      UnDo ( 10420, False );
      Exit;
    End;
    Repeat
      IsamBlockReadRetLen ( SourceF, BufPtr^, BufSize, BytesRead );
      If BytesRead <> 0 Then Begin
        IsamBlockWrite ( DestF, BufPtr^, BytesRead );
        If Not IsamOK Then Begin
          UnDo ( IsamError, True );
          Exit;
        End;
      End;
    Until BytesRead = 0;
    FreeMem ( BufPtr, BufSize );
    IsamClose ( SourceF );
    If Not IsamOK Then Begin
      UnDo ( IsamError, False );
      Exit;
    End;
    IsamClose ( DestF );
    If Not IsamOK Then Begin
      UnDo ( IsamError, False );
      Exit;
    End;
    If DeleteSourceAfterCopy Then IsamDelete ( SourceF );
  End;


  Function IsamForceExtension ( Name, Ext : IsamFileName ) : IsamFileName;

  Var
    DotPos : Word;


    Function HasExtension ( Name : IsamFileBlockName; Var DotPos : Word )
        : Boolean;

    Var
      W : Word;

    Begin
      DotPos := 0;
      For W := Length (Name) DownTo 1 Do Begin
        If (Name [W] = '.') And (DotPos = 0) Then Begin
          DotPos := W;
        End;
      End;
      HasExtension := (DotPos > 0) And
          (Pos ('\', Copy (Name, Succ (DotPos), 255)) = 0);
    End;


  Begin
    If HasExtension ( Name, DotPos ) Then Begin
      IsamForceExtension := Copy ( Name, 1, DotPos ) + Ext;
    End Else Begin
      IsamForceExtension := Name + '.' + Ext;
    End;
  End;


{$IFDEF Heap6}
  Function RoundToGranul ( Value : Word ) : Word;
    {-Rounds Value up to the next multiple of 8}
  Begin
    RoundToGranul := (Value + 7) And $FFF8;
  End;
{$ENDIF}

  Procedure IsamDelay ( MilliSecs : LongInt );
    {-Delays for MilliSecs milliseconds using a DOS call, not the CRT unit}
  Const
    NoCallCounter = -1;
    CallCounter : LongInt = NoCallCounter;
    MilliSecsInOneHour = 3600000;
    MilliSecsInOneDay = 86400000;

  Var
    StartTime,
    EndTime,
    ThisTime,
    ToCall,
    Counter   : LongInt;
    Init      : Boolean;

    Function TimeCountFromDOS : LongInt;

    Var
      IRR : GenRegisters;

    Begin
      DefaultRegisters ( IRR );
      With IRR Do Begin
        AH := $2C;
        CallMsDos ( IRR );
        TimeCountFromDOS := 10 * LongInt (DL) + 1000 *
            (LongInt (DH) + 60 * (LongInt (CL) + 60 * LongInt (CH)));
      End;
    End;

    Function EndTimeIsLessThan ( CompareTime : LongInt ) : Boolean;{!!.41}

    Begin                                                          {!!.41}
      If EndTime >= MilliSecsInOneDay Then Begin                   {!!.41}
        If CompareTime > StartTime Then Begin                      {!!.41}
          EndTimeIsLessThan := False;                              {!!.41}
        End Else Begin                                             {!!.41}
          EndTimeIsLessThan :=                                     {!!.41}
              (EndTime - MilliSecsInOneDay) < CompareTime;         {!!.41}
        End;                                                       {!!.41}
      End Else Begin                                               {!!.41}
        EndTimeIsLessThan := EndTime < CompareTime;                {!!.41}
      End;                                                         {!!.41}
    End;                                                           {!!.41}


  Begin
    If MilliSecs > MilliSecsInOneHour Then Begin                   {!!.41}
      MilliSecs := MilliSecsInOneHour;                             {!!.41}
        {-No Delay beyond one hour}                                {!!.41}
    End;                                                           {!!.41}
    Init := CallCounter = NoCallCounter;
    If (MilliSecs <= 0) And Not Init Then Exit;

    StartTime := TimeCountFromDOS;

    If Init Then Begin
      Millisecs := 80;
        {-Not more than 2 timer ticks}
      Repeat
        ThisTime := TimeCountFromDOS;
      Until StartTime <> ThisTime;
        {-Exit right after a time change}
      StartTime := ThisTime;
    End;

    EndTime := StartTime + MilliSecs;

    If Init Then Begin
      Counter := 0;
      Repeat
        Inc (Counter);
        If Counter >= CallCounter Then;
          {-Dummy to adjust speed}
      Until EndTimeIsLessThan ( TimeCountFromDOS );                {!!.41}
      CallCounter := Counter;
    End Else Begin
      If Millisecs > 1000 Then Begin
        Repeat                                                     {!!.41}
        Until EndTimeIsLessThan ( TimeCountFromDOS );              {!!.41}
      End Else Begin
        ToCall := (Millisecs * CallCounter) Div 110;
        Counter := 0;
        Repeat
          Inc (Counter);
          If EndTimeIsLessThan ( TimeCountFromDOS ) Then;          {!!.41}
            {-Dummy to delay}
        Until Counter >= ToCall;
      End;
    End;
  End;
