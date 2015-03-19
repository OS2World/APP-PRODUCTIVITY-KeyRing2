(**************************************************************)
(*     B-Tree Isam Low Browser Include Ver 5.51               *)
(*   Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH            *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

Const
  RetriesOnLock = 32;
    {-Number of retries of a read operation on lock error}
  DelayTime     = 30;
    {-Delay between retries of operation on lock error}

  Function BRLBrowser.BrowserCallAllowed : Boolean;

  Begin
    BrowserCallAllowed := True;
  End;


  Function BRLBrowser.BRGetRec ( Var RR       : RowRec;
                                     AskUser,
                                     ReadFull : Boolean ) : Integer;

  Var
    Len    : Word;
    RT     : Word;
    LResult : Integer;                                          {!!.51}

  Begin
    RT := 0;
    Repeat
      If VariableRecs Then Begin
        If ReadFull Then Begin
          Len := MaxVariableRecLength;
        End Else Begin
          Len := VarRecMaxReadLen;
        End;
        BTGetVariableRecPart ( UsedFileBlock, RR.Ref, DataBuffer^, Len );
        If IsamOK Then LastVarRecLen := Len;
      End Else Begin
        BTGetRec ( UsedFileBlock, RR.Ref, DataBuffer^, False );
      End;
      If Not IsamOK Then Begin
        If AskUser And (BTIsamErrorClass = LockError) Then Begin {!!.42mod}
          IsamDelay ( DelayTime );                               {!!.42mod}
        End;                                                     {!!.42mod}
      End;
      Inc (RT);
    Until Not AskUser Or (RT > RetriesOnLock)
        Or (BTIsamErrorClass <> LockError);
    LResult := BTIsamErrorClass;                                {!!.51}
    If LResult = NoError Then Begin                             {!!.51}
      If LongInt (DataBuffer^) <> 0 Then LResult := DialogError;  {!!.51}
        {-Record is deleted}
    End;
    BRGetRec := LResult;                                        {!!.51}
  End;


  Function BRLBrowser.BRNextKey ( Var RR  : RowRec ) : Integer;

  Var
    UseIt  : Boolean;
    LResult : Integer;                                          {!!.51}
    RT     : Word;

  Begin
    With RR Do Begin
      Repeat
        RT := 0;
        Repeat
          If KeyNr = 0 Then Begin                                    {!!.42}
            BTNextRecRef ( UsedFileBlock, Ref );                     {!!.42}
            If IsamError = 10390 Then IsamClearOK;                   {!!.42}
              {-Treat as valid}
          End Else Begin                                             {!!.42}
            BTNextKey ( UsedFileBlock, KeyNr, Ref, IKS );
          End;                                                       {!!.42}
          If Not IsamOK Then Begin
            If BTIsamErrorClass = LockError Then IsamDelay ( DelayTime );
          End;
          Inc (RT);
        Until (RT > RetriesOnLock) Or (BTIsamErrorClass <> LockError);
        If BTIsamErrorClass <> NoError Then Begin
          LResult := BTIsamErrorClass;                          {!!.51}
        End Else Begin
          LResult := BRCallFilter ( RR, UseIt );                {!!.51}
        End;
      Until UseIt Or (LResult <> NoError);                      {!!.51}
    End;
    BRNextKey := LResult;                                       {!!.51}
  End;


  Function BRLBrowser.BRPrevKey ( Var RR  : RowRec ) : Integer;

  Var
    UseIt  : Boolean;
    LResult : Integer;                                          {!!.51}
    RT     : Word;

  Begin
    With RR Do Begin
      Repeat
        RT := 0;
        Repeat
          If KeyNr = 0 Then Begin                                    {!!.42}
            BTPrevRecRef ( UsedFileBlock, Ref );                     {!!.42}
            If IsamError = 10390 Then IsamClearOK;                   {!!.42}
              {-Treat as valid}
          End Else Begin                                             {!!.42}
            BTPrevKey ( UsedFileBlock, KeyNr, Ref, IKS );
          End;                                                       {!!.42}
          If Not IsamOK Then Begin
            If BTIsamErrorClass = LockError Then IsamDelay ( DelayTime );
          End;
          Inc (RT);
        Until (RT > RetriesOnLock) Or (BTIsamErrorClass <> LockError);
        If BTIsamErrorClass <> NoError Then Begin
          LResult := BTIsamErrorClass;                          {!!.51}
        End Else Begin
          LResult := BRCallFilter ( RR, UseIt );                {!!.51}
        End;
      Until UseIt Or (LResult <> NoError);                      {!!.51}
    End;
    BRPrevKey := LResult;                                       {!!.51}
  End;


  Function BRLBrowser.BRFindKeyAndRef ( Var RR   : RowRec;
                                            NFSD : Integer ) : Integer;

  Var
    UseIt  : Boolean;
    LResult : Integer;                                          {!!.51}
    RT     : Word;

  Begin
    With RR Do Begin
      RT := 0;
      Repeat
        If KeyNr = 0 Then Begin                                      {!!.42}
          BTFindRecRef ( UsedFileBlock, Ref, NFSD );                 {!!.42}
          If IsamError = 10390 Then IsamClearOK;                     {!!.42}
            {-Treat as valid}
        End Else Begin                                               {!!.42}
          BTFindKeyAndRef ( UsedFileBlock, KeyNr, Ref, IKS, NFSD );
        End;                                                         {!!.42}
        If Not IsamOK Then Begin
          If BTIsamErrorClass = LockError Then IsamDelay ( DelayTime );
        End;
        Inc (RT);
      Until (RT > RetriesOnLock) Or (BTIsamErrorClass <> LockError);
      If BTIsamErrorClass <> NoError Then Begin
        LResult := BTIsamErrorClass;                            {!!.51}
      End Else Begin
        LResult := BRCallFilter ( RR, UseIt );                  {!!.51}
        If LResult = NoError Then Begin                         {!!.51}
          If Not UseIt Then Begin
            Case NFSD Of
              0: LResult := DialogError;                        {!!.51}
              1: Begin
                LResult := BRNextKey ( RR );                    {!!.51}
              End;
              -1: Begin
                LResult := BRPrevKey ( RR );                    {!!.51}
              End;
            End; {Case}
          End;
        End;
      End;
    End;
    BRFindKeyAndRef := LResult;                                 {!!.51}
  End;


  Function BRLBrowser.BRFindKeyAndRefNoFilter ( Var RR   : RowRec;
                                                    NFSD : Integer )
                                                             : Integer;
                                                                  {!!.42}

  Var
    RT : Word;

  Begin
    With RR Do Begin
      RT := 0;
      Repeat
        If KeyNr = 0 Then Begin                                      {!!.42}
          BTFindRecRef ( UsedFileBlock, Ref, NFSD );                 {!!.42}
          If IsamError = 10390 Then IsamClearOK;                     {!!.42}
            {-Treat as valid}
        End Else Begin                                               {!!.42}
          BTFindKeyAndRef ( UsedFileBlock, KeyNr, Ref, IKS, NFSD );
        End;                                                         {!!.42}
        If Not IsamOK Then Begin
          If BTIsamErrorClass = LockError Then IsamDelay ( DelayTime );
        End;
        Inc (RT);
      Until (RT > RetriesOnLock) Or (BTIsamErrorClass <> LockError);
    End;
    BRFindKeyAndRefNoFilter := BTIsamErrorClass;
  End;


  Function BRLBrowser.BRLLockDetected : Boolean;

  Begin
    BRLLockDetected := BTFileBlockIsReadLocked ( UsedFileBlock )
        Or BTFileBlockIsLocked ( UsedFileBlock );
  End;


  Function BRLBrowser.BRDoReadLock : Integer;

  Var
    RT : Word;

  Begin
    RT := RetriesOnLock - RetriesOnLock Shr 3;
      {-Do only 1/8 of the default retries}
    Repeat
      BTReadLockFileBlock ( UsedFileBlock );
      If Not IsamOK Then Begin
        If BTIsamErrorClass = LockError Then IsamDelay ( DelayTime );
      End;
      Inc (RT);
    Until (RT > RetriesOnLock) Or (BTIsamErrorClass <> LockError);
    BRDoReadLock := BTIsamErrorClass;
  End;


  Function BRLBrowser.BRDoUnLock : Integer;

  Begin
    BTUnLockFileBlock ( UsedFileBlock );
    BRDoUnLock := BTIsamErrorClass;
  End;


  Function BRLBrowser.BRSetReadLockUsage ( Var UseRL : Boolean) : Integer;

  Begin
    BRSetReadLockUsage := NoError;
      {-If fileblock is not valid, UseRL may be fantasy}
    UseRL := BTPeekIsNetFileBlock ( UsedFileBlock );
  End;


  Function BRLBrowser.BRLSaveStatus : Integer;

  Begin
    BRLSaveStatus := NoError;
  End;


  Function BRLBrowser.BRLRestoreStatus : Integer;

  Begin
    BRLRestoreStatus := NoError;
  End;


  Function BRLBrowser.BRLGetApprKeyAndRef (     RelPos     : Word;
                                                Scale      : Word;
                                            Var UserKey    : GenKeyStr;
                                            Var UserDatRef : LongInt )
                                                                 : Integer;

  Begin
    If KeyNr = 0 Then Begin                                        {!!.42}
      BTGetApprRecRef ( UsedFileBlock, RelPos, Scale, UserDatRef );{!!.42}
    End Else Begin                                                 {!!.42}
      BTGetApprKeyAndRef ( UsedFileBlock, KeyNr, RelPos, Scale, UserKey,
          UserDatRef );
    End;                                                           {!!.42}
    BRLGetApprKeyAndRef := BTIsamErrorClass;
  End;


  Function BRLBrowser.BRLGetApprRelPos ( Var RelPos     : Word;
                                             Scale      : Word;
                                             UserKey    : GenKeyStr;
                                             UserDatRef : LongInt )
                                                                 : Integer;

  Begin
    If KeyNr = 0 Then Begin                                        {!!.42}
      BTGetApprRecPos ( UsedFileBlock, RelPos, Scale, UserDatRef );{!!.42}
    End Else Begin                                                 {!!.42}
      BTGetApprRelPos ( UsedFileBlock, KeyNr, RelPos, Scale, UserKey,
          UserDatRef );
    End;                                                           {!!.42}
    BRLGetApprRelPos := BTIsamErrorClass;
  End;


  Function BRLBrowser.BRLUsedKeys ( Var UK : LongInt ) : Integer;

  Begin
    If KeyNr = 0 Then Begin                                        {!!.42}
      UK := BTUsedRecs ( UsedFileBlock );                          {!!.42}
    End Else Begin                                                 {!!.42}
      UK := BTUsedKeys ( UsedFileBlock, KeyNr );
    End;                                                           {!!.42}
    BRLUsedKeys := BTIsamErrorClass;
  End;
