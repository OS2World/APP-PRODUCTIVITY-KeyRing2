{*************************************************************************}
{*                                                                       *}
{*                          DEWDEMO.PAS 5.51                             *}
{*              Copyright (c) TurboPower Software 1992,1994              *}
{*         Portions copyright (c) Enz EDV-Beratung GmbH 1990/91          *}
{*                                                                       *}
{*************************************************************************}

{--Conditional defines and compiler options that affect this program}
{$I BRDEFOPT.INC}
{$X+}
{$M 16384,8192}

program DewDemo;
  {-Demonstration program for Data Entry Workshop and B-Tree Filer}

{$R DEWDEMO.RES}

uses
  WinTypes,
  WinProcs,
  {$IFDEF Ver70}
  Objects,
  OWindows,
  ODialogs,
  {$ELSE}
  WObjects,
  {$ENDIF}
  Strings,
  Filer,
  Rebuild,
  IsamTool,
  LowBrows,
  WBrowser,
  BWCC,
  DewData,
  ooDewCC;

const
  id_Last         = 101;
  id_First        = 102;
  id_Address      = 103;
  id_City         = 104;
  id_State        = 105;
  id_ZipCode      = 106;
  id_Phone        = 107;

  idm_About       = 201;
  idm_New         = 202;
  idm_Delete      = 203;
  idm_Search      = 204;
  idm_Edit        = 205;
  idm_FilterOnOff = 206;
  idm_Status      = 207;

  id_Icon         = 1;

  TheFileBlockName = 'WAddress';

  {validation stuff}
  dwecBadState = dwecFirst+50;  {bad state abbreviation}
  BadStateMsg  = 'Not a valid state abbreviation';
type
  PDemoApp = ^TDemoApp;
  TDemoApp =
    object (TApplication)
      constructor Init(AName : PChar);
      destructor Done; virtual;
      function  InitDataBase : Boolean;
      function  InitBrowser : Boolean;
      procedure InitMainWindow; virtual;
    end;

  PDemoWin = ^TDemoWin;
  TDemoWin =
    object(TBrowserWindow)
      FilterOn : Boolean;

      constructor InitDemo(AParent             : PWindowsObject;
                           ATitle              : PChar;
                           ADrvOrFileBlockPtr  : Pointer;
                           ANumberOfEltsPerRow : Word;
                           ANumberOfRows       : Word;
                           AKeyNr              : Word;
                           ALKey, AHKey        : GenKeyStr);
      destructor Done; virtual;
      function  BuildRow(var RR : RowRec) : Integer; virtual;
      function  PerformFilter(var RR : RowRec;
                              var UseIt : Boolean) : Integer; virtual;
      procedure ShowErrorOccured(Class : Integer); virtual;
      procedure GetWindowClass(var WndClass : TWndClass); virtual;
      function  EditDataRec(ATitle : PChar) : Boolean;
      procedure About(var Msg : TMessage); virtual cm_First+idm_About;
      procedure NewRec(var Msg : TMessage); virtual cm_First+idm_New;
      procedure DelRec(var Msg : TMessage); virtual cm_First+idm_Delete;
      procedure EditRec(var Msg : TMessage); virtual cm_First+idm_Edit;
      procedure Search(var Msg : TMessage); virtual cm_First+idm_Search;
      procedure FilterOnOff(var Msg : TMessage);
        virtual cm_First+idm_FilterOnOff;
      procedure ShowStatus(var Msg : TMessage); virtual cm_First+idm_Status;
      procedure wmQueryEndSession(var Msg : TMessage);
        virtual wm_First+wm_QueryEndSession;
      procedure wmLButtonDblClk(var Msg : TMessage);
        virtual wm_First+wm_LButtonDblClk;
      procedure wmSize(var Msg : TMessage);                    {!!.42}
        virtual wm_First+wm_Size;
    end;

  {Note the Transfer methods in TPhoneField and TZipField are needed primarily
   because we wanted to maintain compatibility with the record format used in
   BTWDEMO. If we were creating a wholly new program, we would have selected
   both the Strip literals and Trim blanks options for the phone and zip
   fields, thereby eliminating the need to override the Transfer method.}

  PPhoneField = ^TPhoneField;
  TPhoneField =
    object(TPictureField)
      function  Transfer(DataPtr : Pointer; TransferFlag : Word) : Word; virtual;
      procedure dwmValidate(var Msg : TMessage); virtual wm_First+dwm_Validate;
    end;

  PZipField = ^TZipField;
  TZipField =
    object(TPictureField)
      function  Transfer(DataPtr : Pointer; TransferFlag : Word) : Word; virtual;
      procedure dwmValidate(var Msg : TMessage); virtual wm_First+dwm_Validate;
    end;

  PStateField = ^TStateField;
  TStateField =
    object(TPictureField)
      procedure dwmValidate(var Msg : TMessage); virtual wm_First+dwm_Validate;
      procedure dwmIncDecValue(var Msg : TMessage); virtual wm_First+dwm_IncDecValue;
    end;

  PEditDialog = ^TEditDialog;
  TEditDialog =
    object(TEntryScreen)
      WName : array[0..20] of Char;

      constructor Init(AParent : PWindowsObject; AName, ATitle : PChar);
      procedure SetupWindow; virtual;
      procedure dwmError(var Msg : TMessage); virtual wm_First+dwm_Error;
    end;

  NetTypeRec =
    record
      NoNet  : Word;
      MsNet  : Word;
      Novell : Word;
    end;
  PNetDialog = ^TNetDialog;
  TNetDialog =
    object(TDialog)
      constructor Init(AParent : PWindowsObject; AName : PChar;
                       var Buffer : NetTypeRec);
    end;

  PersonRec =
    record
      LastName  : array [0..15] of Char;
      FirstName : array [0..15] of Char;
      Address   : array [0..25] of Char;
      City      : array [0..20] of Char;
      State     : array [0..02] of Char;
      Zip       : array [0..10] of Char;
      Phone     : array [0..12] of Char;
      Dummy     : array [0..01] of Char; {needed for compatibility w/ BTWDEMO}
    end;

  PersonDef =
    record
      Dele : LongInt;
      Pers : PersonRec;
    end;

var
  Person  : PersonDef;
  BRHeader : BRLRowEltString;
  PersFB  : IsamFileBlockPtr;
  DemoApp : TDemoApp;
  LockEnd : Boolean;

  procedure DbError(S : PChar);
  begin
    BwccMessageBox(
      GetActiveWindow, S, 'Data Base Error', mb_OK or mb_TaskModal);
  end;

  procedure AutoErrorDisplay;
  var
    CharAr : array [0..255] of Char;
  begin
    if IsamError <> 0 then begin
      StrPCopy(CharAr, IsamErrorMessage(IsamError));
      DbError(CharAr);
    end;
  end;

  function YesNo(S : String) : Boolean;
  var
    SZ : array [0..255] of Char;
  begin
    StrPCopy(SZ, S + '?');
    YesNo := BwccMessageBox(
      GetActiveWindow, SZ, 'User Question', mb_YesNo or mb_IconHand) = id_Yes;
  end;

  function Extend(S : String; Nr : Byte) : String;
  var
    S1 : String;
  begin
    S1 := S;
    while Length(S1) < Nr do
      S1 := S1 + ' ';
    Extend := S1;
  end;

{$F+}                                                           {!!.XX}
  function BuildPersKey(var P; KeyNr : Word) : IsamKeyStr;

    function StrToKey(S : String) : String;
    begin
      if Length(S) <> 0 then
        AnsiUpperBuff(@S[1], Length(S));
      StrToKey := S;
    end;

  begin
    with PersonDef(P).Pers do
      case KeyNr of
        1 : BuildPersKey := Copy(StrToKey(StrPas(LastName)), 1, 15);
        else BuildPersKey := '';
      end;
  end;
{$F-}                                                           {!!.XX}

{TPhoneField}

  function TPhoneField.Transfer(DataPtr : Pointer; TransferFlag : Word) : Word;
  var
    I : Word;
  begin
    Transfer := TEntryField.Transfer(DataPtr, TransferFlag);
    if TransferFlag = tf_GetData then begin
      I := StrLen(PChar(DataPtr));

      {trim trailing blanks}
      while (I <> 0) and (PChar(DataPtr)[I-1] = ' ') do begin
        PChar(DataPtr)[I-1] := #0;
        Dec(I);
      end;

      {trim '-' if appropriate}
      if (I <> 0) and (PChar(DataPtr)[I-1] = '-') then
        begin                                                   {!!.42}
          PChar(DataPtr)[I-1] := #0;
          dec(I);                                               {!!.42}
        end;                                                    {!!.42}

      {trim trailing blanks}
      while (I <> 0) and (PChar(DataPtr)[I-1] = ' ') do begin
        PChar(DataPtr)[I-1] := #0;
        Dec(I);
      end;

      {trim '-' if appropriate}
      if (I <> 0) and (PChar(DataPtr)[I-1] = '-') then
        begin                                                   {!!.42}
          PChar(DataPtr)[I-1] := #0;
          dec(I);                                               {!!.42}
        end;                                                    {!!.42}

      {trim trailing blanks}                                    {!!.42}
      while (I <> 0) and (PChar(DataPtr)[I-1] = ' ') do begin
        PChar(DataPtr)[I-1] := #0;
        Dec(I);
      end;

    end;
  end;

  procedure TPhoneField.dwmValidate(var Msg : TMessage);
  begin
    DefWndProc(Msg);
    if Msg.Result = 0 then
      Msg.Result := ValidateSubfields(@Self, 'ppp-uuu-uuuu');
  end;

{TZipField}

  function TZipField.Transfer(DataPtr : Pointer; TransferFlag : Word) : Word;
  var
    I : Word;
  begin
    Transfer := TEntryField.Transfer(DataPtr, TransferFlag);
    if TransferFlag = tf_GetData then begin
      {trim trailing blanks}
      I := StrLen(PChar(DataPtr));
      while (I <> 0) and (PChar(DataPtr)[I-1] = ' ') do begin
        PChar(DataPtr)[I-1] := #0;
        Dec(I);
      end;

      {trim final '-' if appropriate}
      if (I <> 0) and (PChar(DataPtr)[I-1] = '-') then
        PChar(DataPtr)[I-1] := #0;
    end;
  end;

  procedure TZipField.dwmValidate(var Msg : TMessage);
  begin
    DefWndProc(Msg);
    if Msg.Result = 0 then
      Msg.Result := ValidateSubfields(@Self, 'uuuuu-pppp');
  end;

{TStateField}

const
  MaxStates = 51;
  StateAbbrevs : array[1..MaxStates] of array[0..2] of Char = (
    {01} 'AK', {02} 'AL', {03} 'AR', {04} 'AZ', {05} 'CA', {06} 'CO',
    {07} 'CT', {08} 'DC', {09} 'DE', {10} 'FL', {11} 'GA', {12} 'HI',
    {13} 'IA', {14} 'ID', {15} 'IL', {16} 'IN', {17} 'KS', {18} 'KY',
    {19} 'LA', {20} 'MA', {21} 'MD', {22} 'ME', {23} 'MI', {24} 'MN',
    {25} 'MO', {26} 'MS', {27} 'MT', {28} 'NC', {29} 'ND', {30} 'NE',
    {31} 'NH', {32} 'NJ', {33} 'NM', {34} 'NV', {35} 'NY', {36} 'OH',
    {37} 'OK', {38} 'OR', {39} 'PA', {40} 'RI', {41} 'SC', {42} 'SD',
    {43} 'TN', {44} 'TX', {45} 'UT', {46} 'VA', {47} 'VT', {48} 'WA',
    {49} 'WI', {50} 'WV', {51} 'WY');

  function FindState(P : PChar) : Integer;
  var
    I : Integer;
  begin
    for I := 1 to MaxStates do
      if StrComp(P, StateAbbrevs[I]) = 0 then begin
        FindState := I;
        Exit;
      end;
    FindState := -1;
  end;

  procedure TStateField.dwmValidate(var Msg : TMessage);
  var
    CurState : array[0..2] of Char;
  begin
    DefWndProc(Msg);
    if Msg.Result = 0 then begin
      {get the current value of the field}
      Transfer(@CurState, tf_GetData);
      if CurState[0] <> #0 then
        if FindState(CurState) = -1 then
          Msg.Result := dwecBadState;
    end;
  end;

  procedure TStateField.dwmIncDecValue(var Msg : TMessage);
  var
    CurState : array[0..2] of Char;
    I : Integer;
  begin
    {get the current value of the field}
    Transfer(@CurState, tf_GetData);

    if CurState[0] = #0 then
      if Msg.wParam = 1 then
        I := MaxStates
      else
        I := 1
    else
      {look for the state}
      I := FindState(CurState);

    if I <> -1 then begin
      if Integer(Msg.wParam) = -1 then
        if I = 1 then
          I := MaxStates
        else
          Dec(I)
      else
        if I = MaxStates then
          I := 1
        else
          Inc(I);
      if Transfer(@StateAbbrevs[I], tf_SetData) <> 0 then
        SendMessage(hWindow, dwm_Updated, 0, 0);
    end;
  end;

{TEditDialog}

  constructor TEditDialog.Init(AParent : PWindowsObject;
                               AName, ATitle : PChar);
  var
    CP : PControl;
  begin
    TEntryScreen.Init(AParent, AName, Person.Pers);
    StrCopy(WName, ATitle);

    CP := New(PPictureField, InitResource(@Self, id_Last));
    CP := New(PPictureField, InitResource(@Self, id_First));
    CP := New(PPictureField, InitResource(@Self, id_Address));
    CP := New(PPictureField, InitResource(@Self, id_City));
    CP := New(PStateField,   InitResource(@Self, id_State));
    CP := New(PZipField,     InitResource(@Self, id_ZipCode));
    CP := New(PPhoneField,   InitResource(@Self, id_Phone));
  end;

  procedure TEditDialog.SetupWindow;
  begin
    TEntryScreen.SetupWindow;
    SetWindowText(hWindow, WName);
  end;

  procedure TEditDialog.dwmError(var Msg : TMessage);
  begin
    if Msg.wParam = dwecBadState then
      Msg.lParam := LongInt(PChar(BadStateMsg));

    TEntryScreen.dwmError(Msg);
  end;

{TNetDialog}

  constructor TNetDialog.Init(AParent : PWindowsObject; AName : PChar;
                              var Buffer : NetTypeRec);
  var
    P : PRadioButton;
  begin
    TDialog.Init(AParent, AName);
    TransferBuffer := @Buffer;

    New(P, InitResource(@Self, 101));
    New(P, InitResource(@Self, 102));
    New(P, InitResource(@Self, 103));
  end;

{TDemoWin}

  constructor TDemoWin.InitDemo(AParent             : PWindowsObject;
                                ATitle              : PChar;
                                ADrvOrFileBlockPtr  : Pointer;
                                ANumberOfEltsPerRow : Word;
                                ANumberOfRows       : Word;
                                AKeyNr              : Word;
                                ALKey, AHKey        : GenKeyStr);
  begin
    if not TBrowserWindow.Init(AParent, ATitle) then
      Fail;
    FilterOn := False;

    BRHeader :=
      Extend(
        Extend('Last name'+', '+'First name', 30)+' '+
        Extend('Address', 25)+' '+
        Extend('City', 15)+' '+
        Extend('St', 2)+' '+
        Extend('Zip code', 10)+' '+
        Extend('Phone number', 12), MaxCols);

    if not ConnectLowBrowser(
        New(PLowWinBrowser,
          Init(True, ADrvOrFileBlockPtr, ANumberOfEltsPerRow, ANumberOfRows,
               AKeyNr, ALKey, AHKey, Person, False)), BRHeader, '') then
      Fail;

    {Attach its menu system}
    Attr.Menu := LoadMenu(hInstance, 'MAINMENU');
  end;

  destructor TDemoWin.Done;
  begin
   if BTNetSupported <> NoNet then
     KillTimer(hWindow, 1);
    TBrowserWindow.Done;
  end;

  function TDemoWin.BuildRow(var RR : RowRec) : Integer;
  begin
    BuildRow := NoError;
    with Person.Pers do
      if RR.Status <> NoError then
        RR.Row := Extend('****  ' + RR.IKS, MaxCols)
      else
        RR.Row := Extend(
          Extend(StrPas(LastName) + ', ' + StrPas(FirstName), 30)+' '+
          Extend(StrPas(Address), 25)+' '+
          Extend(StrPas(City), 15)+' '+
          Extend(StrPas(State), 2)+' '+
          Extend(StrPas(Zip), 10)+' '+
          Extend(StrPas(Phone), 12), MaxCols);
  end;

  function TDemoWin.PerformFilter(var RR : RowRec; var UseIt : Boolean) : Integer;
  begin
    PerformFilter := NoError;
    if FilterOn then
      UseIt := (Length(RR.IKS) > 8)
    else
      UseIt := True;
  end;

  procedure TDemoWin.ShowErrorOccured(Class : Integer);
  begin
    MessageBeep(0);
    if Class > 1 then
      if YesNo('Abort program') then
        Halt
      else
        {suspend timer events until a next action is done}
        SetSuppressTimer(True);
  end;

  function TDemoWin.EditDataRec(ATitle : PChar) : Boolean;
  var
    Dialog : PEditDialog;
  begin
    Dialog := New(PEditDialog, Init(@Self, 'DATAENTRY', ATitle));
    EditDataRec := Application^.ExecDialog(Dialog) = id_OK;
  end;

  procedure TDemoWin.About(var Msg: TMessage);
  begin
    Application^.ExecDialog(New(PDialog, Init(@Self, 'ABOUT')));
  end;

  procedure TDemoWin.wmLButtonDblClk(var Msg: TMessage);
  begin
    EditRec(Msg);
  end;

  procedure ShowMessage(S, Title : PChar);
  begin
    BwccMessageBox(GetActiveWindow, S, Title, mb_OK or mb_TaskModal);
  end;

  function CreateTheFile : Boolean;
  var
    IID : IsamIndDescr;
  begin
    IID[1].Keyl := 20;
    IID[1].AllowDupK := True;
    BTCreateFileBlock(TheFileBlockName, SizeOf(PersonDef), 1, IID);
    CreateTheFile := IsamOK;
  end;

  function RebuildTheFile : Boolean;
  var
    IID : IsamIndDescr;
  begin
    IID[1].Keyl := 20;
    IID[1].AllowDupK := True;
    RebuildFileBlock(
      TheFileBlockName, SizeOf(PersonDef), 1, IID, @BuildPersKey);
    RebuildTheFile := IsamOK;
  end;

  function OpenTheFile : Boolean;
  var
    OK, OK1 : Boolean;
  begin
    OpenTheFile := False;
    OK := False;
    repeat
      BTOpenFileBlock(
        PersFB, TheFileBlockName, False, False, False, True);
      OK := IsamOK;
      if not OK then begin
        OK1 := False;
        if IsamError = 10010 then begin
          if YesNo('Index defective. Rebuild') then
            OK1 := RebuildTheFile;
        end
        else if IsamError = 9903 then begin
          if YesNo('Data file does not exist. Create') then begin
            OK1 := CreateTheFile;
            if not OK1 then
              Exit;
          end
          else
            Exit;
        end
        else
          Exit;
      end;
    until OK;
    OpenTheFile := True;
  end;

  function IsLockError : Boolean;
  begin
    IsLockError := BTIsamErrorClass = 2;
  end;

  function LockAbort : Boolean;
  begin
    LockEnd := IsLockError;
    if not LockEnd then
      LockAbort := False
    else
      LockAbort := YesNo('A lock prevents this operation. Abort');
  end;

  function AddData(P : PersonDef; var Ref : LongInt) : Boolean;
  begin
    AddData := False;
    repeat
      BTAddRec(PersFB, Ref, P);
      if LockAbort then
        Exit;
    until not LockEnd;
    AddData := IsamOK;
  end;

  function ChangeData(P : PersonDef; Ref : LongInt) : Boolean;
  begin
    ChangeData := False;
    repeat
      BTPutRec(PersFB, Ref, P, False);
      if LockAbort then
        Exit;
    until not LockEnd;
    ChangeData := IsamOK;
  end;

  function DeleteData(Ref : LongInt) : Boolean;
  begin
    DeleteData := False;
    repeat
      BTDeleteRec(PersFB, Ref);
      if LockAbort then
        Exit;
    until not LockEnd;
    DeleteData := IsamOK;
  end;

  function AddAKey(K : IsamKeyStr; Ref : LongInt; KeyNr : Integer) : Boolean;
  Begin
    AddAKey := False;
    repeat
      BTAddKey(PersFB, KeyNr, Ref, K);
      if LockAbort then
        Exit;
    until not LockEnd;
    AddAKey := IsamOK;
  end;

  function DeleteAKey(K : IsamKeyStr; Ref : LongInt; KeyNr : Integer) : Boolean;
  begin
    DeleteAKey := False;
    repeat
      BTDeleteKey(PersFB, KeyNr, Ref, K);
      if LockAbort then
        Exit;
    until not LockEnd;
    DeleteAKey := IsamOK;
  end;

  function ChangeAKey(OldK, NewK : IsamKeyStr; Ref : LongInt;
                      KeyNr : Integer) : Boolean;
  begin
    if DeleteAKey(OldK, Ref, KeyNr) then
      ChangeAKey := AddAKey(NewK, Ref, KeyNr )
    else
      ChangeAKey := False;
  end;

  function AddRecAndKeys(var Key : IsamKeyStr; var Ref : LongInt) : Boolean;
  var
    OK : Boolean;
  begin
    AddRecAndKeys := False;
    repeat
      BTLockFileBlock(PersFB);
      if not IsamOK then
        if YesNo('Unable to lock file. Abort') then
          Exit;
    until IsamOK;
    OK := AddData(Person, Ref);
    if OK then begin
      Key := BuildPersKey(Person, 1);
      OK := AddAKey(Key, Ref, 1);
    end;
    BTUnlockFileBlock(PersFB);
    AddRecAndKeys := IsamOK and OK;
  end;

  function ChangeRecAndKeys(var OldPerson : PersonDef;
                            Ref : LongInt) : Boolean;
  var
    CurrentPerson : PersonDef;
    OK : Boolean;

    function CompStruc(Var S1, S2; Len : Word ) : Integer;
    var
      A1 : Array [1..$FFFF] of Byte absolute S1;
      A2 : Array [1..$FFFF] of Byte absolute S2;
      I  : Word;
    Begin
      for I := 1 To Len do
        if A1[I] < A2[I] then begin
          CompStruc := -1;
          Exit;
        end
        else if A1[I] > A2[I] then begin
          CompStruc := 1;
          Exit;
        end;

      CompStruc := 0;
    end;

  begin
    ChangeRecAndKeys := True;
    if CompStruc(Person, OldPerson, SizeOf(PersonDef)) = 0 then
      Exit;
    ChangeRecAndKeys := False;
    repeat
      BTLockFileBlock(PersFB);
      if not IsamOK then
        if YesNo('Unable to lock file. Abort') then
          Exit;
    until IsamOK;
    BTGetRec(PersFB, Ref, CurrentPerson, False);
    if not IsamOK or (CurrentPerson.Dele <> 0) then begin
      BTUnLockFileBlock(PersFB);
      Exit;
    end;
    if CompStruc(CurrentPerson, OldPerson, SizeOf(PersonDef)) <> 0 then begin
      BTUnLockFileBlock(PersFB);
      ShowMessage('The record has been changed in the meantime.', 'User Message');
      Exit;
    end;
    OK := ChangeData(Person, Ref);
    if OK then
      if BuildPersKey(CurrentPerson, 1) <> BuildPersKey(Person, 1) then
        OK := ChangeaKey(
          BuildPersKey(CurrentPerson, 1), BuildPersKey(Person, 1), Ref, 1);
    BTUnLockFileBlock(PersFB);
    ChangeRecAndKeys := IsamOK and OK;
  end;

  function DeleteRecAndKeys(Ref : LongInt) : Boolean;
  var
    OK : Boolean;
  begin
    DeleteRecAndKeys := False;
    repeat
      BTLockFileBlock(PersFB);
      if not IsamOK then
        if YesNo('Unable to lock file. Abort') then
          Exit;
    until IsamOK;
    OK := DeleteAKey(BuildPersKey(Person, 1), Ref, 1);
    if OK then
      OK := DeleteData(Ref);
    BTUnlockFileBlock(PersFB);
    DeleteRecAndKeys := IsamOK and OK;
  end;

  function SearchForKey(var Key : IsamKeyStr; var DatRef : LongInt) : Boolean;
  begin
    SearchForKey := False;
    repeat
      BTSearchKey(PersFB, 1, DatRef, Key);
      if LockAbort then
        Exit;
    until not LockEnd;
    SearchForKey := IsamOK;
  end;

  procedure TDemoWin.NewRec(var Msg: TMessage);
  var
    Key : IsamKeyStr;
    Ref : LongInt;
  begin
    FillChar(Person, SizeOf(Person), 0);
    if EditDataRec('New') then
      if not AddRecAndKeys(Key, Ref) then
        DbError('Error adding record')
      else
        SetAndUpdateBrowserScreen(Key, Ref);
  end;

  procedure TDemoWin.EditRec(var Msg : TMessage);
  var
    SavePerson : PersonDef;
    Match : Boolean; {!!.42}
  begin
    if GetCurrentRec(Match) > 0 then {!!.42}
      Exit;
    SavePerson := Person;
    if EditDataRec('Edit') then
      if not ChangeRecAndKeys(SavePerson, GetCurrentDatRef) then
        DbError('Error updating record')
      else
        SetAndUpdateBrowserScreen(BuildPersKey(Person, 1), GetCurrentDatRef);
  end;

  procedure TDemoWin.DelRec(var Msg : TMessage);
  var
    SavePerson : PersonDef;
    Match : Boolean; {!!.42}
  begin
    if GetCurrentRec(Match) > 0 then {!!.42}
      Exit;
    SavePerson := Person;
    if EditDataRec('Delete') then begin
      Person := SavePerson;
      if not DeleteRecAndKeys(GetCurrentDatRef) then
        DbError('Error deleting record')
      else
        UpdateBrowserScreen;
    end;
  end;

  procedure TDemoWin.Search(var Msg : TMessage);
  var
    Key : IsamKeyStr;
    Ref : LongInt;
  begin
    FillChar(Person, SizeOf(Person), 0);
    if EditDataRec('Search') then begin
      Key := BuildPersKey(Person, 1);
      if not SearchForKey(Key, Ref) then
        DbError('Search error')
      else
        SetAndUpdateBrowserScreen(Key, Ref);
    end;
  end;

  procedure TDemoWin.FilterOnOff(var Msg : TMessage);
  begin
    FilterOn := not FilterOn;
    UpdateBrowserScreen;
  end;

  procedure TDemoWin.ShowStatus(var Msg : TMessage);
  var
    Result : Integer;
    UK     : LongInt;
    S, T   : String;
    Buffer : array [0..255] of Char;
  begin
    SetSuppressTimer(True);
    UK := BTUsedKeys(PersFB, GetCurrentKeyNr);
    Result := BTIsamErrorClass;
    if Result = NoError then begin
      Str(UK : 0, S);
      Str(BTGetInternalDialogID(PersFB): 0, T);
      S := 'Records : '+S+'    Task : '+T;
      StrPCopy(Buffer, S);
      BwccMessageBox(GetActiveWindow, @Buffer, 'Status', mb_OK or mb_TaskModal);
    end;
    SetSuppressTimer(False);
  end;

  procedure TDemoWin.WMQueryEndSession(var Msg : TMessage);
  begin
    DbError('First close the database application');
    DefWndProc(Msg);
    Msg.Result := 0;
  end;

  procedure TDemoWin.GetWindowClass(var WndClass : TWndClass);
  begin
    TWindow.GetWindowClass(WndClass);
    WndClass.Style := cs_DblClks;
    WndClass.hIcon := LoadIcon(hInstance, PChar(id_Icon));
  end;

  Procedure TDemoWin.wmSize(var Msg : TMessage);      {!!.42}
    var
      LineNr : word;
      DC     : HDC;
      S : string;
    begin
      TBrowserWindow.wmSize(Msg);
      {Paint the final partial line - better this way than the flicker with
       erasing the background}
      S := GetFooter;
      if (S <> '') then LineNr := FullPage+2
      else              LineNr := FullPage+1;
      S := '';
      DC := GetDC(HWindow);
      WriteStringOut(S, LineNr, DC, 0);
      ReleaseDC(HWindow, DC);
    end;


{TDemoApp}

  constructor TDemoApp.Init(AName : PChar);
  begin
    if not TApplication.Init(AName) then
      Fail;
    if not InitBrowser then
      Fail;
  end;

  destructor TDemoApp.Done;
  begin
    TApplication.Done;
      {-Order must be this way because Isam or Shell are called indirectly}
    BTCloseFileBlock(PersFB);
    BTExitIsam;
  end;

  procedure TDemoApp.InitMainWindow;
  begin
    {Initially, the main window is a hidden dummy window}
    CmdShow := sw_Hide;
    MainWindow := New(PWindow, Init(nil, ''));

    {Initialize Filer and open the fileblock}
    if not InitDataBase then begin
      DbError('Fileblock could not be initialized.');
      Halt;
    end;
  end;

  function TDemoApp.InitDataBase : Boolean;
  var
    NTR : NetTypeRec;
    NetType : NetSupportType;
  begin
    InitDataBase := False;

    NTR.NoNet := bf_Checked;
    NTR.MsNet := bf_Unchecked;
    NTR.Novell := bf_Unchecked;

    if not BTNoNetCompiled then
      if ExecDialog(New(PNetDialog, Init(nil, 'NETTYPE', NTR))) = id_Cancel then
        Halt;

    if NTR.MsNet = bf_Checked then
      NetType := MSNet
    else if NTR.Novell = bf_Checked then
      NetType := Novell
    else
      NetType := NoNet;

    BTInitIsam(NetType, MemAvail - 500000, 0);
    if IsamOK then
      InitDataBase := OpenTheFile
    else
      InitDataBase := False;
  end;

  function TDemoApp.InitBrowser : Boolean;
  var
    PD : PDemoWin;
    SW : PWindowsObject;
  begin
    InitBrowser := False;

    {Restore CmdShow}
    CmdShow := sw_Show;

    {Now create the browser window}
    PD := New(PDemoWin,
      InitDemo(nil, 'B-Tree Filer and DEW Demo', PersFB, 1, 50, 1, '', ''));
    if PD = nil then
      Exit;


    {Get its window handle, etc.}
    PD^.Create;

    {Get rid of previous dummy MainWindow}
    SW := Application^.MainWindow;
    Application^.MainWindow := PD;
    Dispose(SW, Done);

    {Show the browser window}
    PD^.Show(sw_Show);
    PD^.SetAndUpdateBrowserScreen('', 0);

    {Set a timer for refreshing screen in multi-user situations}
    if BTNetSupported <> NoNet then
       SetTimer(MainWindow^.hWindow, 1, 10000, nil);

    InitBrowser := True;
  end;

var
  SaveExitProc : Pointer;

  procedure DemoExitProc; far;
  begin
    AutoErrorDisplay;
    ExitProc := SaveExitProc;
  end;

begin
  if DemoApp.Init('Dew Demo') then begin
    SaveExitProc := ExitProc;
    ExitProc := @DemoExitProc;

    DemoApp.Run;
    DemoApp.Done;
  end;
end.
 