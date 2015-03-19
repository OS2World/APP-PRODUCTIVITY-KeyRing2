{***************************************************************************
* Filename: ~modname~
* Version:  ~version~
* Date:     ~date~ @ ~time~
* Group:    ~group~
* Release:  ~release~
* ----------------------------
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer   Description
* ~log~
*
*
* ~notes~
* Description
* -----------
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$X+,F+,O+}
{******************************************************************}
{ (C)1994 NewsMaker Systems                                        }
{ Simple Messaging subsystem for the NewsMaker Electronic Newsroom }
{******************************************************************}
{Need to check MessageReceivePrim exit freemems}
Unit UMessage;

interface

Uses
  {$IFDEF MSDOS}
  Dos,
  {$ELSE}
  WinDOS,
  {$ENDIF}
  ULanguag,
  OpDate,
  Strings, Objects,
  QHdrRec, QUptime;

  Type

  {$IFNDEF MSDOS}
    PathStr = String[79];
    NameStr = String[14];
  {$ENDIF}

  MsgNameStr = String[24]; {was 14}

Const
  MsgSize     = 512;
  MsgListSize : word = 20;

Type
  TBuf = Array[1..MsgSize] of Char;

  FileModes = (fmReadOnly, fmReadWrite);

  MessageRecTypes = (mtDirectory, mtMessage);

  TMessageRec = Record
    Case RecordType: MessageRecTypes of
    mtDirectory : (
                   MessagesWaiting   : Boolean;
                   NumUnreadMessages : word;
                   LastMessageSeen   : DateTimeRec;
                  );
    mtMessage   : (
                   From     : NameStr;
                   Time     : DateTimeRec;
                   Read     : boolean;
                   Replied  : boolean;
                   Message  : TBuf;
                   Size     : word;
                  );
  end;

  PNENMessage = ^TNENMessage;
  TNENMessage = Object(TObject)
    Contents : TMessageRec;
    constructor Init(iContents: TMessageRec);
  end;

  PMessageList = ^TMessageList;
  TMessageList = Object(TSortedCollection)
    fMode      : FileModes;
    SaveMode   : integer;
    MsgFile    : File of TMessageRec;
    FileName   : PathStr;
    IoErr      : integer;
    TotalNew   : byte;
    TotalRead  : byte;
    UserName   : NameStr;
    constructor Init(User: NameStr; mode: FileModes);
    destructor Done; virtual;
    function Compare(key1, key2 : Pointer) : Integer; virtual;
    function Load: boolean;
    function Store(NeedToOpen: boolean; HasNewMessages: boolean;
                   NeedToErase: boolean): boolean;
    function Create: boolean;
    procedure UpdateTotals;
  end;

  Procedure NewMessage (Drive2Use : DriveName);
  procedure ReadMessages (Drive2Use : DriveName);
  procedure CreateMessageFile;
  function MessageWaiting: boolean;
  procedure InstallMessages;
  function SendMessage(Destination: MsgNameStr; MsgBuf:
                       TBuf; MsgSize: word;
                       Attach2Drive : DriveName): boolean;

implementation

Uses
  QGlobal, QLog, QNovell, QDrives, QDrive2,QCmdDsp, QLib,
  OpCrt, OpString, OpDos, OpMemo, OpWindow, OpFrame, OpEntry, OpDir,
  OpConst, OpPick, OpDrag, OpCmd, OpCol16, OpSelect, OpDialog, OpField,
  UGlobal, UMsg, UFKey, UWindow, UMenu,
  UKey, UEdit, UColors;

Const
  ColorFlex : FlexAttrs = (BlackOnWhite,  RedOnWhite,
                           BlueOnWhite, GreenOnWhite);
  MonoFlex  : FlexAttrs = (YellowOnBlue, LtGreenOnBlue,
                           LtMagentaOnBlue, LtRedOnBlue or Blink);

  JustSetNameFromMenu : boolean = False;

  HeaderStr =  '   From        Time  Date      Status   ';

  LastMessage : LongInt = 0;
  LastChoice  : integer = -1;

  Var
   Error       : String[45];
   SMDP        : DialogBoxPtr;
   RMDP        : DialogBoxPtr;
   Destination : MsgNameStr;
   MsgList     : PMessageList;
   MsgPickList : PickListPtr;
   SMsgEdit    : MemoPtr;
   SMsgBuf     : ^TBuf;
   RMsgEdit    : MemoPtr;
   RMsgBuf     : ^TBuf;
   PassDrive   : DriveName;

  Function FindSysVol (Var Attach2Drive : DriveName) : Boolean;
  Var

   VolCount : Integer;
   WorkVol : VolName;
   CurDrive : Char;

      Begin
      FindSysVol := False;
      VolCount := -1;
      Repeat
         Begin
         VolCount := VolCount + 1;
         WorkVol := GetVolname(VolCount);
         If (WorkVol <> '') And
            (MapToDrive (Attach2Drive,WorkVol+':'+
            NEN^.SysDir,Network,CurDrive)) Then
            Begin
            FindSysVol := True;
            Exit;
            End;
         End;
      Until (WorkVol = '') Or (VolCount > 256);
      End;
  constructor TNENMessage.Init(iContents: TMessageRec);
  begin
    Move(iContents, Contents, SizeOf(TMessageRec));
  end;

  constructor TMessageList.Init(User: NameStr; mode: FileModes);
  begin
    Inherited Init(MsgListSize, 5);
    UserName := StUpCase(User);
    Duplicates := True;
    fMode := mode;
    TotalRead := 0;
    TotalNew := 0;
    FileName := NEN^.MessageDir+'\'+ForceExtension(User,'MES');
    if not ExistFile(FileName) then
      if not Create then Fail;
    if not Load then Fail;
    if User <> Sys^.UsersName then
      UpdateTotals;
  end;

  destructor TMessageList.Done;
  begin
    {$I-}
    Close (MsgFile);
    {$I+}
    If IOResult <> 0 Then ;
    Inherited Done;
  end;

  function TMessageList.Compare(key1, key2 : Pointer) : Integer;
  begin
    Compare := 0;
    if PNENMessage(key1)^.Contents.Time.D > PNENMessage(key2)^.Contents.Time.D then Compare := -1;
    if PNENMessage(key1)^.Contents.Time.D < PNENMessage(key2)^.Contents.Time.D then Compare := 1;
    if PNENMessage(key1)^.Contents.Time.D = PNENMessage(key2)^.Contents.Time.D then
      begin
      Compare := 0;
      if PNENMessage(key1)^.Contents.Time.T > PNENMessage(key2)^.Contents.Time.T then Compare := -1;
      if PNENMessage(key1)^.Contents.Time.T < PNENMessage(key2)^.Contents.Time.T then Compare := 1;
      end;
  end;

  function TMessageList.Load: boolean;
  var
    TR    : TMessageRec;
    TM    : PNENMessage;
  begin
    Load := False;
    {$I-}
    Assign(MsgFile, FileName);
    SaveMode := FileMode;
    Case FMode of
      fmReadOnly  : FileMode := $40;
      fmReadWrite : FileMode := $22;
      end;
    Reset(MsgFile);
    IoErr := IoResult;
    if IoErr <> 0 then exit;
    While not EOF(MsgFile) do
      begin
        Read(MsgFile, TR);
        IoErr := IoResult;
        if IoErr <> 0 then
          begin
            Close(MsgFile);
            exit;
          end;
        if TR.RecordType = mtMessage then
          begin
            New(TM, Init(TR));
            Insert(TM);
          end;
        if TR.RecordType = mtDirectory then
          begin
            if UserName <> Sys^.UsersName then
              Sys^.MessagePending := TR.NumUnreadMessages;
          end;
      end;
    if FMode = fmReadOnly then
      begin
        Close(MsgFile);
{        FileMode := $12;
        Reset(MsgFile);
        TRDir.RecordType := mtDirectory;
        TRDir.MessagesWaiting := False;
        Write(MsgFile, TR);
        Close(MsgFile);
        FileMode := SaveMode; }
      end;
    Load := True;
  end;

  function TMessageList.Store(NeedToOpen: boolean; HasNewMessages: boolean;
                              NeedToErase: boolean): boolean;
  var
    TR: TMessageRec;

    procedure WriteMessage(Item: pointer); far;
    begin
      if (IndexOf(Item) > MsgListSize) and
         (PNENMessage(Item)^.Contents.Read) then exit;
      PNENMessage(Item)^.Contents.RecordType := mtMessage;
      Write(MsgFile, PNENMessage(Item)^.Contents);
    end;

    procedure CountUnreadMessages(Item: pointer); far;
    begin
      if not (PNENMessage(Item)^.Contents.Read) then inc(TR.NumUnreadMessages);
    end;

  begin
    if NeedToErase then
      begin
        Close(MsgFile);
        IoErr := IoResult;
        Create;
        NeedToOpen := True;
      end;
    if NeedToOpen then
      begin
        Assign(MsgFile, FileName);
        SaveMode := FileMode;
        FileMode := $22;
        Reset(MsgFile);
        IoErr := IoResult;
        if IoErr <> 0 then exit;
      end;
    TR.NumUnreadMessages := 0;
    ForEach(@CountUnreadMessages);
    Seek(MsgFile, 0);
    TR.RecordType := mtDirectory;
    TR.MessagesWaiting := HasNewMessages;
    Write(MsgFile, TR);
    ForEach(@WriteMessage);
    Close(MsgFile);
    FileMode := SaveMode;
    {$I+}
  end;

  function TMessageList.Create;
  var
    TR: TMessageRec;
  begin
    {$I-}
    Assign(MsgFile, FileName);
    Rewrite(MsgFile);
    TR.RecordType := mtDirectory;
    TR.MessagesWaiting := False;
    TR.NumUnreadMessages := 0;
    Write(MsgFile, TR);
    Create := IoResult <> 0;
    Close(MsgFile);
    {$I+}
  end;

  procedure TMessageList.UpdateTotals;

    procedure CountMessage(Item: pointer); far;
    begin
      if PNENMessage(Item)^.Contents.RecordType = mtMessage then
        if PNENMessage(Item)^.Contents.Read then
          inc(TotalRead)
        else
          inc(TotalNew);
    end;

  begin
    TotalRead := 0;
    TotalNew := 0;
    ForEach(@CountMessage);
  end;

  function SendMessage(Destination: MsgNameStr; MsgBuf:
                       TBuf; MsgSize: word;
                       Attach2Drive : DriveName): boolean;
  var
   AMsg     : TMessageRec;
   TMsg    : PNENMessage;
   DT      : DateTimeRec;
   SaveDrive : DriveName;
   IOffset : Byte;
   FoundDrive : Boolean;
   ECode : Integer;
   MsgServer : FSName;
   Msg2Name : MsgNameStr;
   GroupName : NetObject;
   First : Boolean;
   TempNameOfUser : AnyString;
   NameOfUser : UserName;
   FileName : PathStr;
   SentMsg : Boolean;

Label BottomOfLoop;

   Function SendPrim (Var NameOfUser : MsgNameStr) : Boolean;
      Begin
      New(MsgList, Init(NameOfUser, fmReadWrite));
      if MsgList = nil then
        begin
          Dialog('Cannot Open Message file','SendMessage',Red,'OK','','');
          Exit;
        end;
      OpenMessage('Sending to '+NameOfUser, BrightYellow_Scheme);
      AMsg.From := Sys^.UsersName;
      DT.T := OpDate.CurrentTime;
      DT.D := Today;
      AMsg.Time := DT;
      Move(MsgBuf, AMsg.Message, MsgSize);
      AMsg.Size := MsgSize;
      AMsg.Read := False;
      AMsg.Replied := False;
      New(TMsg, Init(AMsg));
      MsgList^.Insert(TMsg);
      MsgList^.Store(False, True, False);
      Dispose(MsgList, Done);
      CloseMessage;
      End;


    begin
    SaveDrive := Sys^.CurrentDriveID;
    ChangeDrive (Sys^.SysDrive);

    SendMessage := False;
    SentMsg := False;

    For IOffset := 1 To 16 Do
       Begin
       If Sys^.FSNames[IOffset] <> '' Then
          Begin
          FoundDrive := False;
          Ecode := 0;
          If (Not FoundDrive) And (Sys^.FSNames[IOffset] = Sys^.HomeFS) Then
             Begin
             FoundDrive := True;
             ChangeDrive (Sys^.HomeDrive);
             MsgServer := Sys^.FSNames[IOffset];
             If Not FindSysVol (Attach2Drive) Then
                Begin
                GoTo BottomOfLoop;
                End;
             End;

          If (Not FoundDrive) And (Sys^.FSNames[IOffset] = FW^.CurrentQFS) Then
             Begin
             FoundDrive := True;
             ChangeDrive (FW^.QDrive);
             MsgServer := Sys^.FSNames[IOffset];
             If Not FindSysVol (Attach2Drive) Then
                Begin
                GoTo BottomOfLoop;
                End;
             End;

          If (Not FoundDrive) And (Sys^.FSNames[IOffset] =
             FW^.FwdLink^.CurrentQFS) Then
             Begin
             FoundDrive := True;
             ChangeDrive (FW^.FwdLink^.QDrive);
             MsgServer := Sys^.FSNames[IOffset];
             If Not FindSysVol (Attach2Drive) Then
                Begin
                GoTo BottomOfLoop;
                End;
             End;

          If (Not FoundDrive) And (Sys^.FSNames[IOffset] = Sys^.BaseFS) Then
             Begin
             FoundDrive := True;
             ChangeDrive (Sys^.BaseDrive);
             MsgServer := Sys^.FSNames[IOffset];
             If Not FindSysVol (Attach2Drive) Then
                Begin
                GoTo BottomOfLoop;
                End;
             End;

          If Not FoundDrive Then
             Begin
             If (Sys^.FSNames[IOffset] <> Sys^.HomeFS) And
                (Sys^.FSNames[IOffset] <> Fw^.CurrentQFS) And
                (Sys^.FSNames[IOffset] <> FW^.FwdLink^.CurrentQFS) And
                (Sys^.FSNames[IOffset] <> Sys^.BaseFS) Then
                Begin
                If AttachFS (Sys^.FSNames[IOffset],Attach2Drive,
                   'SYS:\', Sys^.UsersName,Sys^.UsersPassword, Ecode) Then
                      Begin
                      ChangeDrive(Attach2Drive);
                      MsgServer := Sys^.FSNames[IOffset];
                      If Not FindSysVol (Attach2Drive) Then
                         Begin
                         GoTo BottomOfLoop;
                         End;
                      End
                      Else
                      Begin
writeln ('bad attach',logcommon);
                      GoTo BottomOfLoop;
                      End;
                End
                Else
                Begin
                GoTo BottomOfLoop;
                End;
             End;

          If Destination[1] = '@' Then
             Begin
             First := True;
             GroupName := Destination;
             Delete (GroupName,1,1);
             Repeat
                Begin
                NextUserName(First,TempNameOfUser);
                NameOfUser := TempNameOfUser;
                First := False;

                If (NameOfUser <> '') And
                   (UserInGroup (GroupName, NameOfUser)) Then
                   Begin
                   FileName := NEN^.MessageDir+'\'+
                      ForceExtension(Destination,'MES');
                   if ExistFile(FileName) then
                      Begin
                      SendPrim (NameOfUser);
                      SentMsg := True;
                      End;
                   End;
                End;
             Until NameOfUser = '';
             End
             Else
             Begin
             FileName := NEN^.MessageDir+'\'+ForceExtension(Destination,'MES');
             if ExistFile(FileName) then
                begin
                SendPrim (Destination);
                SentMsg := True;
                End
                Else
                begin
                End;
             End;

BottomOfLoop:

       ChangeDrive (Sys^.SysDrive);
       If (MsgServer <> '') And
          (MsgServer <> Sys^.BaseFS) And
          (MsgServer <> Sys^.HomeFS) And
          (MsgServer <> FW^.CurrentQFS) And
          (MsgServer <> FW^.FwdLink^.CurrentQFS) And
          (MsgServer <> Sys^.ToQFS) And
          (MsgServer <> FW^.AliasQFS) And
          (MsgServer <> FW^.FwdLink^.AliasQFS) Then
            If Not ReleaseFileServer (MsgServer) Then
               Msg (SysMsg(000043){Unable To Release FS } + MsgServer,2);
          End;
       End;

    ChangeDrive (SaveDrive);
    SendMessage := SentMsg;
  end;


  Procedure ShowHelp(DP: DialogBoxPtr);
  begin
    Case DP^.GetCurrentID of
    0 : begin
          DP^.wFastWrite('F1 for List                              ',1,3, BlueOnLtGray);
          JustSetNameFromMenu := False;
        end;
    1 : begin
          DP^.wFastWrite('F4 or Alt-S to Send, Alt-T to change Name',1,3, BlueOnLtGray);
          JustSetNameFromMenu := False;
        end;
    else
      DP^.wFastWrite('F1 for List                              ',1,3, BlueOnLtGray);
    end;
  end;

  Function MessageWaiting: boolean;
  {$IFDEF MSDOS}
  var
    TS: SearchRec;
  const
    AF = AnyFile;
  {$ELSE}
  var
    TS: TSearchRec;
    UF: Array[0..79] of Char;
  const
    AF = faAnyFile;
  {$ENDIF}
  Var
    CurrDrive : DriveName;
    FileName: PathStr;
    TR: TMessageRec;
    MsgFile: File of TMessageRec;
    SaveMode: byte;
  begin
    MessageWaiting := False;
    CurrDrive := Sys^.CurrentDriveID;
    ChangeDrive(Sys^.SysDrive);
    FileName := NEN^.MessageDir+'\'+ForceExtension(Sys^.UsersName,'MES');

    {$IFDEF MSDOS}
    FindFirst(FileName, AF, TS);
    {$ELSE}
    StrPCopy(UF, FileName);
    FindFirst(UF, AF, TS);
    {$ENDIF}
    if DosError <> 0 then
      Begin
      ChangeDrive(CurrDrive);
      exit;
      End;

    if (LastMessage = 0) or (LastMessage <> TS.Time) then
      begin
      LastMessage := TS.Time;
      {$I-}
      Assign(MsgFile, FileName);
      SaveMode := FileMode;
      FileMode := $40;
      Reset(MsgFile);
      if IoResult <> 0 then exit;
      Read(MsgFile, TR);
      if IoResult <> 0 then
        begin
          Close(MsgFile);
          ChangeDrive(CurrDrive);
          exit;
        end;
      Close(MsgFile);
      FileMode := SaveMode;
      MessageWaiting := TR.MessagesWaiting;
      Sys^.MessagePending := 0;
      If TR.MessagesWaiting Then
         Sys^.MessagePending := TR.NumUnreadMessages;
      ChangeDrive(CurrDrive);
      exit;
      end;
    MessageWaiting := LastMessage <> TS.Time;
    LastMessage := TS.Time;
    ChangeDrive(CurrDrive);
  end;

  procedure NoExtFormat(var X : DirRec; var PkCat : byte;
                        var S : STRING; D : DirListPtr);
  begin
    S := StUpCase(Pad(JustName(X.Name), 8));
  end;

  procedure ShowUserList(UnitCode : Byte; IdPtr : Pointer; HelpIndex : Word);
  var
    Quit: boolean;
    PCP: DragProcessorPtr;
    UserList : DirListPtr;
    IOffset : Integer;
    FoundDrive : Boolean;
    ECode : Integer;
    MsgServer : FSName;
    First : Boolean;


  begin
    White_Scheme;

    New(UserList, InitCustom(SMDP^.wFrame.frXL+7,  SMDP^.wFrame.frYL+3,
                             SMDP^.wFrame.frXL+19, SMDP^.wFrame.frYL+8,
                             NENColorSet,
                             wClear or wUserContents or  wBordered,
                             8192, PickVertical, SingleFile));
    New(PCP, Init(@PickKeySet, PickKeyMax));
    CustomizeCommandProcessor(PCP^);
    UserList^.SetCommandProcessor(PCP^);

    AddScrollBars(UserList^, FALSE);
    with UserList^ do
      begin
        SetSearchMode(PickStringSelect);
        pkOptionsOn(pkMinHeight);
        SetPadSize(1,1);
        wFrame.SetFrameType(SglWindowFrame);
        SetUserFormat(8, NoExtFormat);
        wFrame.AddShadow(shBR, shSeeThru);
        diOptionsOn(diExitIfOne);
        pkOptionsOn(pkProcessZero);
        SetSortOrder(SortName);


        {$IFDEF MSDOS}
        SetMask(NEN^.MessageDir+'\*.MES', AnyFile - Directory);
        {$ELSE}
        SetMask(NEN^.MessageDir+'\*.MES', faAnyFile - faDirectory);
        {$ENDIF}
        PreLoadDirList;
      end;

      Quit := False;
      While not Quit do
        with UserList^ do
          begin
            Process;
            Case GetLastCommand of
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    if HandleMousePress(UserList^) = hsRegion3 then begin
                        ClearMouseEvents;
                        Quit := True;
                    end;
                ccSelect : begin
                             Destination := GetLastChoiceString;
                             Destination := trim(Destination);
                             JustSetNameFromMenu := True;
                             with SMDP^ do
                               begin
                                 FindControl(0)^.efEditSt^ := Destination;
                                 DrawField(0);
                                 StuffKey(OpKey.Tab);
                               end;
                             Quit := True;
                           end;
                ccQuit   : Quit := True;
            end;
          end;

      UserList^.Erase;
      Dispose(PCP, Done);
      Dispose(UserList, Done);
  end;

  procedure DisplayError(Msg: String);
  begin
    {display the error message}
    SMDP^.wFastWrite(Pad(Msg,25) ,1,3, RedOnLtGray);
    Sound(880);
    Delay(50);
    NoSound;
    Delay(1500);
    ShowHelp(SMDP);
  end;

  procedure ErrorHandler(UnitCode : Byte; var ErrCode : Word; Msg : string);
  begin
    {display the error message}
    DisplayError(Msg);
  end;

  function ValidateDestination(EFP : EntryFieldPtr; var ErrCode : Word;
                               var ErrorSt : StringPtr) : Boolean;
  var
    User: MsgNameStr;
    TestGroup : AnyString;
    OK : Boolean;
    ILoop : Integer;
    FirstTime : Boolean;

     Procedure ReleaseFS (Var MsgServer : FSName);
        Begin
        ChangeDrive (Sys^.SysDrive);
        If (MsgServer <> '') And
           (MsgServer <> Sys^.BaseFS) And
           (MsgServer <> Sys^.HomeFS) And
           (MsgServer <> FW^.CurrentQFS) And
           (MsgServer <> FW^.FwdLink^.CurrentQFS) And
           (MsgServer <> Sys^.ToQFS) And
           (MsgServer <> FW^.AliasQFS) And
           (MsgServer <> FW^.FwdLink^.AliasQFS) Then
             If Not ReleaseFileServer (MsgServer) Then
                Msg (SysMsg(000043){Unable To Release FS } + MsgServer,2);
        End;


    Function NextFS (Var TheFSName : FSName) : Boolean;
 Var
    FoundDrive : Boolean;
    ECode : Integer;
    MsgServer : FSName;

       Begin
       NextFS := False;
       If TheFSName = '' Then
          Exit;

       FoundDrive := False;
       Ecode := 0;
       If (Not FoundDrive) And (TheFSName = Sys^.HomeFS) Then
          Begin
          FoundDrive := True;
          ChangeDrive (Sys^.HomeDrive);
          MsgServer := TheFSName;
          If Not FindSysVol (PassDrive) Then
             Begin
             Exit;
             End;
          End;

       If (Not FoundDrive) And (TheFSName = FW^.CurrentQFS) Then
          Begin
          FoundDrive := True;
          ChangeDrive (FW^.QDrive);
          MsgServer := TheFSName;
          If Not FindSysVol (PassDrive) Then
             Begin
             Exit;
             End;
          End;

       If (Not FoundDrive) And (TheFSName = FW^.FwdLink^.CurrentQFS) Then
          Begin
          FoundDrive := True;
          ChangeDrive (FW^.FwdLink^.QDrive);
          MsgServer := TheFSName;
          If Not FindSysVol (PassDrive) Then
             Begin
             Exit;
             End;
          End;

       If (Not FoundDrive) And (TheFSName = Sys^.BaseFS) Then
          Begin
          FoundDrive := True;
          ChangeDrive (Sys^.BaseDrive);
          MsgServer := TheFSName;
          If Not FindSysVol (PassDrive) Then
             Begin
             Exit;
             End;
          End;

       If Not FoundDrive Then
          Begin
          If (TheFSName <> Sys^.HomeFS) And
             (TheFSName <> Fw^.CurrentQFS) And
             (TheFSName <> FW^.FwdLink^.CurrentQFS) And
             (TheFSName <> Sys^.BaseFS) Then
             Begin
             If AttachFS (TheFSName,PassDrive,
                'SYS:\', Sys^.UsersName,Sys^.UsersPassword, Ecode) Then
                   Begin
                   ChangeDrive(PassDrive);
                   MsgServer := TheFSName;
                   If Not FindSysVol (PassDrive) Then
                      Begin
                      ReleaseFS (TheFSName);
                      Exit;
                      End;
                   End
                   Else
                   Begin
                   Exit;
                   End;
             End
             Else
             Begin
             Exit;
             End;
          End;
       NextFS := True;
       End;

  begin
    with EFP^ do
      begin
        if (JustSetNameFromMenu) and (Destination <> '') then
          efEditSt^ := Destination;
        User := efEditSt^;
        If User[1] = '@' Then
           Begin
           Delete (User,1,1);
           FirstTime := True;
           TestGroup := 'xxx';
           ValidateDestination := False;
           OK := False;
           For ILoop := 1 To 16 Do
              Begin
              If NextFS (Sys^.FSNames[ILoop]) Then
                 Begin
                 While (Not OK) And (TestGroup <> '') Do
                    Begin
                    NextGroupName(FirstTime, TestGroup);
                    If StUpCase(TestGroup) = StUpCase(User) Then
                       begin
                       ValidateDestination := True;
                       OK := True;
                       End;
                    FirstTime := False;
                    End;
                 ReleaseFS (Sys^.FSNames[ILoop]);
                 End;
              End;

           If Not OK Then
              Begin
              Error := 'Group '+User+' Not Found!';
              ErrorSt := @Error;
              ErrCode := 100;
              End;
           End
           Else
           Begin
           OK := False;
           For ILoop := 1 To 16 Do
              Begin
              If (Not OK) And (NextFS (Sys^.FSNames[ILoop])) Then
                 Begin
                 if ExistFile(NEN^.MessageDir+'\'+ForceExtension(User,'MES')) then
                    OK := True;
                 ReleaseFS (Sys^.FSNames[ILoop]);
                 End;
              End;


           If Not OK Then
              Begin
              Error := 'User '+User+' Not Found!';
              ErrorSt := @Error;
              ErrCode := 100;
              ValidateDestination := False;
              end
              else
              Begin
              ValidateDestination := True;
              End;
           End;
      end;
  end;

  Procedure MessageSendPrim(IX, IY: word; Dest: MsgNameStr; Title: String;
                            Drive2Use : DriveName);
  var
    MsgSendDlg : DialogBoxPtr;
    DialogCP   : DragProcessorPtr;
    EditCP     : DragProcessorPtr;
    WinOptions : LongInt;
    Quit       : Boolean;
    SaveShadowH,
    SaveShadowV: Char;
    CurDrive   : DriveName;
    IsReply    : boolean;

  begin
    IsReply := IY = 14;
    CurDrive := SYS^.CurrentDriveID;
    ChangeDrive (Sys^.SysDrive);
    Gray_Scheme;
    NENColorset.PromptColor := DkGrayOnWhite;
    NENColorset.SelPromptColor := DkGrayOnWhite;
    NENColorset.FieldColor := BlackOnWhite;
    NENColorset.SelFieldColor := BlackOnWhite;
    NENDialogset.HiPromptColor := BlueOnWhite;

    New(SMsgBuf);
    if SMsgBuf = nil then
      Begin
      ChangeDrive (CurDrive);
      exit;
      End;
    FillChar(SMsgBuf^, SizeOf(SMsgBuf^), 0);

    { Init Dialog box }

    WinOptions := wBordered+wClear+wUserContents;
    New(MsgSendDlg,
        InitCustom(
          IX, IY, IX+42, IY+8,
          NENColorSet,     {main color set}
          WinOptions,      {window options}
          NENDialogSet     {dialog box-specific colors}
        ));
    if MsgSendDlg = nil then
      begin
        ChangeDrive (CurDrive);
        Dispose(SMsgBuf);
        Exit;
      end;
    SMDP := MsgSendDlg;

    New(DialogCP,Init(@DialogKeySet, DialogKeyMax));
    CustomizeCommandProcessor(DialogCP^);
    DialogCP^.cpOptionsOn(cpEnableMouse);

    with DialogCP^ do
      begin
        AddCommand(ccUser43 , 1,     OpKey.F4 , 0);
        AddCommand(ccUser44 , 1,     OpKey.F5 , 0);
        AddCommand(ccUser45 , 1,     OpKey.F6 , 0);
        AddCommand(ccUser46 , 1,     OpKey.F7 , 0);
        AddCommand(ccUser47 , 1,     OpKey.F8 , 0);
        AddCommand(ccUser48 , 1,     OpKey.F9 , 0);
        AddCommand(ccUser49 , 1,     OpKey.F10, 0);
        SetHelpProc(ShowUserList);
      end;

    PassDrive := Drive2Use;
    MsgSendDlg^.SetCommandProcessor(DialogCP^);

    CustomizeWindow(MsgSendDlg^, Title, 18);

    White_Scheme;
    NENColorSet.ShadowColor := LtGrayOnBlack;

    New(SMsgEdit,
        InitCustom(31,9,71,12,                     {Window coordinates}
                   NENColorSet,                    {ColorSet}
                   DefWindowOptions or wBordered,
                   SizeOf(SMsgBuf^),
                   SMsgBuf));
    if SMsgEdit = nil then
      begin
        Dispose(DialogCP, Done);
        Dispose(MsgSendDlg, Done);
        Dispose(SMsgBuf);
        Exit;
      end;
    AddScrollBars(SMsgEdit^,False);
    with SMsgEdit^ do
      begin
        wFrame.SetFrameType(SglWindowFrame);
        SaveShadowH := DefShadowCharH;
        SaveShadowV := DefShadowCharV;
        DefShadowCharH := 'Ü';
        DefShadowCharV := ' ';
        meOptionsOff(meReadOnly);
        meOptionsOff(meMapCtrls);
        meOptionsOn(meWordWrap);
        SetRightMargin(40);
      end;

    New(EditCP,Init(@MemoKeySet, MemoKeyMax));
    CustomizeCommandProcessor(EditCP^);
    EditCP^.cpOptionsOn(cpEnableMouse);

    with EditCP^ do
      begin
        AddCommand(ccUser43 , 1,     OpKey.F4 , 0);
      end;

    SMsgEdit^.SetCommandProcessor(EditCP^);

    with MsgSendDlg^ do
      begin
        SetPreFocusProc(ShowHelp);
        Destination := Dest;
        AddSimpleEditControl('&To: ',2,3,'!',2,7, 12,
           SizeOf(Destination)-1,1,  Destination);
        ChangeValidation(0, ValidateDestination);
        AddTextField(PadCh('', 'ß', 17), 3, 3);
        AddTextField('Ü', 2, 19);
        AddWindowControl('',        4,18,  4,1, 100, ccSelect, SMsgEdit^);
{        if not IsReply then
          begin}
          AddPushButton('&Send'     , 2,25, 7, 8, ccSelect , True);
          AddPushButton('&Cancel'   , 2,35, 7, 9, ccQuit   , false);
{          end
        else
          begin
          AddPushButton('&Send'     , 2,21, 7, 8, ccSelect , True);
          AddPushButton('&Cancel'   , 2,30, 7, 9, ccQuit   , false);
          AddPushButton('&Up'       , 2,37, 3,10, ccUser50 ,false);
          AddPushButton('&Dn'       , 2,37, 2,11, ccUser51 ,false);
          end;}
        SetEnterToTab(True);
        SetErrorProc(ErrorHandler);
      end;

    if Destination <> '' then
      StuffKey(OpKey.Tab);

    Quit := False;
    With MsgSendDlg^ do
      While not Quit do
        begin
          MsgSendDlg^.Process;
          Case GetLastCommand of
              ccMouseDown,
              ccMouseSel :
                {did user click on the hot spot for closing?}
                if HandleMousePress(MsgSendDlg^) = hsRegion3 then begin
                  ClearMouseEvents;
                  Quit := True;
                end;
              ccSelect,
              ccUser43..ccUser49
                           : begin
                               if (Destination <> '') and (SMsgEdit^.meTotalBytes > 1) then
                                 begin
                                 Quit := True;
                                 SendMessage(Destination, SMsgBuf^,
                                    SMsgEdit^.meTotalBytes,
                                    Drive2Use);
                                 end
                               else
                                 begin
                                 Quit := False;
                                 if Destination = '' then
                                   DisplayError('Must have a destination name')
                                 else
                                   DisplayError('Message empty!');
                                 end;
                             end;
              ccQuit       : begin
                               if (Destination <> '') and (SMsgEdit^.meTotalBytes > 1) then
                                 begin
                                   Case Dialog('Send Message?',Title,Blue,'Yes','No','Cancel') of
                                     1 : begin
                                           Quit := True;
                                           SendMessage(Destination, SMsgBuf^,
                                              SMsgEdit^.meTotalBytes,
                                              Drive2Use);
                                         end;
                                     2 : begin
                                           Quit := True;
                                         end;
                                     3 : Quit := False;
                                   end;
                                 end
                               else
                                 Quit := True;
                             end;
          end;
        end;

    DefShadowCharH := SaveShadowH;
    DefShadowCharV := SaveShadowV;
    MsgSendDlg^.Erase;
    Dispose(SMsgBuf);
    Dispose(EditCP, Done);
    MsgSendDlg^.RemoveChild(SMsgEdit);
    Dispose(SMsgEdit, Done);
    Dispose(DialogCP, Done);
    Dispose(MsgSendDlg, Done);
    ChangeDrive (CurDrive);
  end;

  procedure MsgListMoveProc(P: PickListPtr);
  var
    PE                            : PNENMessage;
    S                             : String;
  begin
    if P^.GetLastChoice = LastChoice then exit;
    PE := PNENMessage(MsgList^.At(P^.GetLastChoice - 1));
    Move(PE^.Contents.Message, RMsgBuf^, SizeOf(RMsgBuf^));
    S := Pad(PE^.Contents.From,12)+
         Pad(TimeToTimeString('hh:mm',PE^.Contents.Time.T),6)+
         Pad(DateToDateString('mm-dd-yy',PE^.Contents.Time.D),9);
    RMsgEdit^.ChangeHeader(0, S);
    RMsgEdit^.ReInitBuffer;
    RMsgEdit^.UpdateContents;
    MsgList^.UpdateTotals;
    MsgPickList^.ChangeHeader(1, '  '+Long2Str(MsgList^.TotalNew)+' New, '+Long2Str(MsgList^.TotalRead)+' Read');
    PE^.Contents.Read := True;
    LastChoice := P^.GetLastChoice;
  end;

  procedure SupplyMsgString(Item                          : Word;
                            Mode                          : pkMode;
                            var IType                     : pkItemType;
                            var IString                   : String;
                            PickPtr                       : PickListPtr);
  var CurCol                      : Byte;
    S                             : String[5];
    Attr                          : Char;
    Attr2                         : Char;
    PE                            : PNENMessage;
  begin
    with MsgList^ do
      begin
        IType := pkNormal;
        with PickPtr^ do
          case Mode of
            pkDisplay :
                        begin { pretty, with flexwrite chars }
                          S := ^C'New'^C;
                          PE := PNENMessage(MsgList^.At(Item - 1));
                          if PE^.Contents.Read then
                            S := ^A#$FB^A;
                          IString := ' '+Pad(PE^.Contents.From,12)+^B+
                                         Pad(TimeToTimeString('hh:mm',PE^.Contents.Time.T),6)+
                                         Pad(DateToDateString('mm-dd-yy',PE^.Contents.Time.D),9)+
                                         ^B+' '+S;
                          if Item = GetLastChoice then
                            IString[1] := '';
                        end;
            pkSearch :
                        begin { no extra characters }
                        end;
            pkGetType :
                        begin
                        end;
          end; {case }
      end; {with }
  end;

  procedure MessageReceivePrim (Drive2Use : DriveName);
  const
    Exits : Set of byte = [ccUser50,ccUser51,ccSelect,ccUser52,ccUser53];
  var
    MsgRcvDlg  : DialogBoxPtr;
    DialogCP   : DragProcessorPtr;
    EditCP     : DragProcessorPtr;
    PCP        : DragProcessorPtr;
    WinOptions : LongInt;
    Quit       : Boolean;
    ReplyName  : MsgNameStr;
    SaveShadowH,
    SaveShadowV: Char;
    EditID     : word;
    ReplyID    : word;
    CurDrive   : DriveName;
  begin
    LastChoice := -1;
    CurDrive := Sys^.CurrentDriveID;
    ChangeDrive(Sys^.SysDrive);
    New(MsgList, Init(Sys^.UsersName, fmReadOnly));
    if MsgList = nil then
       Begin
        ChangeDrive(CurDrive);
        Exit;
       End;
    if MsgList^.Count = 0 then
      begin
        Msg (SysMsg(002575){No Messages Have Been Received },2);
        ChangeDrive(CurDrive);
        Dispose(MsgList, Done);
        exit;
      end;
    White_Scheme;
    NENColorset.PromptColor := DkGrayOnWhite;
    NENColorset.SelPromptColor := DkGrayOnWhite;
    NENColorset.FieldColor := BlackOnWhite;
    NENColorset.SelFieldColor := BlackOnWhite;
    NENColorset.HeaderColor := DkGrayOnWhite;
    NENDialogset.HiPromptColor := BlueOnWhite;

    New(RMsgBuf);
    if RMsgBuf = nil then
       Begin
{        Dispose(MsgList, Done);} {Added by !!!DLK ?????}
        ChangeDrive (CurDrive);
        exit;
       End;
    FillChar(RMsgBuf^, SizeOf(RMsgBuf^), 0);

    { Init Dialog box }

    WinOptions := wBordered+wClear+wUserContents;
    New(MsgRcvDlg,
        InitCustom(
          19, 7, 61, 20,   {top left corner (X,Y)}
          NENColorSet,     {main color set}
          WinOptions,      {window options}
          NENDialogSet     {dialog box-specific colors}
        ));
    if MsgRcvDlg = nil then
      begin
        ChangeDrive (CurDrive);
        Dispose(RMsgBuf);
        Exit;
      end;
    RMDP := MsgRcvDlg;

    New(DialogCP,Init(@DialogKeySet, DialogKeyMax));
    CustomizeCommandProcessor(DialogCP^);
    DialogCP^.cpOptionsOn(cpEnableMouse);

    with DialogCP^ do
      begin
        AddCommand(ccTopOfFile{ccUser50} , 1,     OpKey.CtrlUp   , 0);
        AddCommand(ccEndOfFile{ccUser51} , 1,     OpKey.CtrlDown , 0);
        AddCommand(ccUser43 , 1,     OpKey.F4 , 0);
        AddCommand(ccUser44 , 1,     OpKey.F5 , 0);
        AddCommand(ccUser45 , 1,     OpKey.F6 , 0);
        AddCommand(ccUser46 , 1,     OpKey.F7 , 0);
        AddCommand(ccUser47 , 1,     OpKey.F8 , 0);
        AddCommand(ccUser48 , 1,     OpKey.F9 , 0);
        AddCommand(ccUser49 , 1,     OpKey.F10, 0);
        SetHelpProc(ShowUserList);
      end;

    PassDrive := Drive2Use;
    MsgRcvDlg^.SetCommandProcessor(DialogCP^);

    CustomizeWindow(MsgRcvDlg^, 'Messages for '+Sys^.UsersName, 18);

    NENColorSet.ShadowColor := LtGrayOnBlack;

    NENColorSet.HeaderColor := LtGrayOnWhite;

    New(RMsgEdit,
        InitCustom(31,9,71,12,                     {Window coordinates}
                   NENColorSet,                    {ColorSet}
                   DefWindowOptions or wBordered,
                   SizeOf(RMsgBuf^),
                   RMsgBuf));
    if RMsgEdit = nil then
      begin
        Dispose(DialogCP, Done);
        Dispose(MsgRcvDlg, Done);
        Dispose(RMsgBuf);
        ChangeDrive(CurDrive);
        Exit; {!!!DLK Added}
      end;
    AddScrollBars(RMsgEdit^,False);
    with RMsgEdit^ do
      begin
        wFrame.SetFrameType(SglWindowFrame);
        SaveShadowH := DefShadowCharH;
        SaveShadowV := DefShadowCharV;
        DefShadowCharH := 'Ü';
        DefShadowCharV := ' ';
        wFrame.AddHeader('', heTL);
        meOptionsOn(meReadOnly);
        meOptionsOff(meMapCtrls);
        meOptionsOn(meWordWrap);
        SetRightMargin(40);
        SetExitCommands(@Exits);
      end;

    New(EditCP,Init(@MemoKeySet, MemoKeyMax));
    CustomizeCommandProcessor(EditCP^);
    EditCP^.cpOptionsOn(cpEnableMouse);

    with EditCP^ do
      begin
        AddCommand(ccUser43 , 1,     OpKey.F4 , 0);
      end;

    RMsgEdit^.SetCommandProcessor(EditCP^);

    NENColorSet.HeaderColor := DkGrayOnWhite;

    New(MsgPickList,
        InitDeluxe(2, 5, 42, 8,
                   NENColorSet,
                   wClear or wUserContents or wBordered,
                   45,
                   MsgList^.Count,
                   SupplyMsgString,
                   PickVertical,
                   SingleChoice,
                   DefPickOptions - pkMinHeight + pkFlexWrite));
    if MsgPickList = nil then
      begin
        ChangeDrive(CurDrive);
        Exit;
      end;

    with MsgPickList^ do
      begin
        wFrame.SetFrameType(NoWindowFrame);
        wOptionsOff(wResizeable);
        pkOptionsOn(pkProcessZero);
        pkOptionsOff(pkMinHeight);
        pkOptionsOn(pkFlexWrite);
        SetMoveProc(MsgListMoveProc);
        SetPickFlex(pkNormal, False,
                    ColorFlex, MonoFlex);
        SetSearchMode(PickStringSearch);
        SetPadSize(1, 1);
        EnableExplosions(4);
        wFrame.AddHeader(HeaderStr, heTL);
        wFrame.AddHeader('                      ',heBL);
        AddMoreHeader(' || for more ', heBR, #24, #25, '', 2, 3, 0);
        ChangeHeader(1, '  '+Long2Str(MsgList^.TotalNew)+' New, '+Long2Str(MsgList^.TotalRead)+' Read');
        SetExitCommands(@Exits);
      end;

    AddScrollBars(MsgPickList^, False);

    New(PCP, Init(@PickKeySet, PickKeyMax));
    CustomizeCommandProcessor(PCP^);
    with PCP^ do
      begin
        AddCommand(ccUser52 , 1,     OpKey.CtrlUp   , 0);
        AddCommand(ccUser53 , 1,     OpKey.CtrlDown , 0);
        SetKeypressedProc(Ukey.KeyWaiting);
        SetGetKeyProc(Ukey.GetKey);
      end;
    MsgPickList^.SetCommandProcessor(PCP^);

    with MsgRcvDlg^ do
      begin
        AddWindowControl('',        7,1 , 7, 1, 101, ccSelect, MsgPickList^);
        AddWindowControl('',        7,1 , 1, 1, 100, ccNone  , RMsgEdit^);
        EditID := GetCurrentID;
        AddPushButton('&Reply'    ,13,2 , 7, 8,      ccSelect ,True);
        ReplyID := GetCurrentID;
        AddPushButton('&Kill'     ,13,11, 7, 8,      ccUser52 ,False);
        AddPushButton('&Cancel'   ,13,20, 8, 9,      ccQuit   ,false);
        AddPushButton('&Up'       ,13,31, 4,10,      ccUser50 ,false);
        AddPushButton('&Dn'       ,13,37, 4,11,      ccUser51 ,false);
        SetErrorProc(ErrorHandler);
        SetExitCommands(@Exits);
      end;

    if Destination <> '' then
      StuffKey(OpKey.Tab);

    Quit := False;
    With MsgRcvDlg^ do
      While not Quit do
        begin
          MsgRcvDlg^.Process;
          Case GetLastCommand of
              ccMouseDown,
              ccMouseSel :
                {did user click on the hot spot for closing?}
                if HandleMousePress(MsgRcvDlg^) = hsRegion3 then begin
                  ClearMouseEvents;
                  Quit := True;
                end;
              ccUser50     : begin
                               RMsgEdit^.meScrollUp;
                               SetNextField(ReplyID);
                               StuffKey(OpKey.Tab);
                               StuffKey(OpKey.Tab);
                             end;
              ccUser51     : begin
                               RMsgEdit^.meScrollDown;
                               SetNextField(ReplyID);
                               StuffKey(OpKey.Tab);
                             end;
              ccSelect,
              ccUser43..ccUser49
                           : begin
                               ReplyName := PNENMessage(
                                 MsgList^.At(MsgPickList^.GetLastChoice - 1))^.Contents.From;
                               MsgList^.Store(True, False, False);
                               Dispose(MsgList, Done);
                               MessageSendPrim(19, 14, ReplyName,'Reply To '+ReplyName,Drive2Use);
                               New(MsgList, Init(Sys^.UsersName, fmReadOnly));
                               MsgPickList^.ChangeNumItems(MsgList^.Count);
                               MsgPickList^.UpdateContents;
                               LastChoice := -1;
                               MsgListMoveProc(MsgPickList);
                             end;
              ccUser52     : begin
                               ReplyName := PNENMessage(
                                 MsgList^.At(MsgPickList^.GetLastChoice - 1))^.Contents.From;
                               if Dialog('Delete Message from '+ReplyName, 'Delete',Blue, 'Yes','No','') = 1 then
                                 begin
                                   MsgList^.AtDelete(MsgPickList^.GetLastChoice - 1);
                                   MsgList^.Store(False, False, True);
                                   MsgList^.UpdateTotals;
                                   if MsgList^.Count > 0 then
                                     begin
                                       MsgPickList^.ChangeNumItems(MsgList^.Count);
                                       MsgPickList^.UpdateContents;
                                       LastChoice := -1;
                                       MsgListMoveProc(MsgPickList);
                                       StuffKey(OpKey.Tab);
                                       StuffKey(OpKey.Tab);
                                       StuffKey(OpKey.Tab);
                                       StuffKey(OpKey.Tab);
                                     end
                                   else
                                     Quit := True;
                                 end;
                               end;
              ccQuit       : begin
                               Quit := True;
                             end;
          end;
        end;

    OpenMessage('Updating Message Flags',BrightYellow_Scheme);
    MsgList^.Store(True, False, False);
    CloseMessage;

    DefShadowCharH := SaveShadowH;
    DefShadowCharV := SaveShadowV;
    MsgRcvDlg^.Erase;
    Dispose(RMsgBuf);
    Dispose(EditCP, Done);
    MsgRcvDlg^.RemoveChild(RMsgEdit);
    Dispose(RMsgEdit, Done);
    Dispose(DialogCP, Done);
    Dispose(MsgRcvDlg, Done);
    Dispose(MsgList, Done);
    ChangeDrive (CurDrive);
  end;

  Procedure NewMessage (Drive2Use : DriveName);
  begin
    MessageSendPrim(19, 8, '', 'New Message', Drive2Use);
  end;

  procedure ReadMessages (Drive2Use : DriveName);
  begin
    MessageReceivePrim (Drive2Use);
  end;

  procedure CreateMessageFile;
  begin
    New(MsgList, Init(Sys^.UsersName, fmReadWrite));
    if MsgList <> nil then
      Dispose(MsgList, Done);
  end;

  procedure InstallMessages;
  begin
    SetCheck4Messages(MessageWaiting);
  end;

End.
