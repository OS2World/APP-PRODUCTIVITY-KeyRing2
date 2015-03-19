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
{$O+,F+}
unit UNotePad;

{$I NDEFINE.INC}

interface

uses
  Dos,
  Objects,
  OpEditor, OpWindow, OpDrag, OpDate{,
  MaEdit};

type
  TitleStr                      = String[40];
  Str20                         = String[20];

  IOBuff                        = array[1..$FFF0] OF CHAR;
  IOBuffPtr                     = ^IOBuff;

  Callers                       = (caNotepad, caUrgent, caMail, caOther);

  PNote                         = ^TNote;
  TNote                         = object(TextEditor)
                                    StatWin                       : RawWindowPtr; { Status line save area }
                                    ExitCommand                   : Word;
                                    ECP                           : DragProcessorPtr;
                                    FileEdit                      : Boolean; { true if editing file, not buffer}
                                    Path                          : PathStr;
                                    FileSize                      : LongInt;
                                    AllDone                       : Boolean;
                                    Modified                      : Boolean;
                                    NewFile                       : Boolean;
                                    Title                         : TitleStr;
                                    RemapKeys                     : Boolean;
                                    DateTime                      : Str20;
                                    IsReadOnly                    : boolean;
                                    Caller                        : Callers;
                                    constructor Init(FPath : PathStr; Level : Word);
                                    constructor InitDeluxe(x1, y1, x2, y2                : Byte;
                                                           NTitle                        : TitleStr;
                                                           FPath                         : PathStr;
                                                           CallerID                      : Callers;
                                                           MapKeys                       : Boolean;
                                                           ReadOnly                      : Boolean);
                                    destructor Done; virtual;
                                    procedure Execute;
                                    procedure SetTitle(NewTitle : TitleStr; NewDateTime : Str20);
                                    procedure UpdateDateTime(NewDateTime : Str20);
                                    procedure UpdateTitle(NewTitle : TitleStr);
                                    procedure LoadFile(FPath : PathStr);
                                    procedure PrintNote;
                                    procedure PrintUrgent;
                                  end;

  ProcessStates                 = (npPick, npNew, npEdit, npQuit);

  PEntry                        = ^TEntry;
  TEntry                        = object(TObject)
                                    Title                         : Str20;
                                    Path                          : PathStr;
                                    EntryDate                     : Date;
                                    EntryTime                     : Time;
                                    HasTitle                      : Boolean;
                                    constructor Init(S : String);
                                    destructor Done; virtual;
                                    function GetTitle             : Str20;
                                    function GetTitleForHeader    : Str20;
                                    function GetDate              : Str20;
                                    function GetTime              : Str20;
                                    function SortDate             : Str20;
                                    function GetPath              : PathStr;
                                    function GetHeader            : TitleStr;
                                    procedure ParseLine(S : String);
                                    function CreateLine           : String;
                                    procedure ChangeTitle(var S : String; var S2 : String);
                                    procedure ChangeDateTime;
                                  end;

  PIndexCollection              = ^TIndexCollection;
  TIndexCollection              = object(TSortedCollection)
                                    constructor Init(ALimit, ADelta : Integer);
                                    function Compare(Key1, Key2 : Pointer) : Integer; virtual;
                                  end;

  function ProcessNotePads(Note: PathStr; IndexOnly: boolean): boolean;
  Function InsertNote(Title: TitleStr; IoBuf: IoBuffPtr; BufLen: word): integer;

implementation

Uses
  OpCrt, OpDos, OpString, OpMenu, OpFrame, OpConst, OpMouse,
  OpMemo, OpPick, OpKey, OpCmd, OpRoot, OpCol16,
  OpDialog, FDialog, UQlist, UNav_DOS,
  QGlobal, QHdrRec, QFKeySet, QInput, QNovell, QCS,
  UTPrint, UTIam, UError,
  NetWare, QDrives, QDrive2,
  MaMHS, MaMSGNOD, MaNEN, MaPATH, MaMAINT,
  SECrypt, SEQuery,UMessage,
  UGlobal, UMsg, UColors, UMenu, UWindow, UEdit, UDialog, UFkey, ULanguag,
  QCstLib, UQCopy, UMail;

type
  PString                       = String[20];

  SortTypes                     = (so_None, so_ByTitle, so_ByDateTime);

var
  Index                         : PIndexCollection;
  State                         : ProcessStates;

const
  NotepadPickList               : PickListPtr = nil;
  PCP                           : DragProcessorPtr = nil;

  UntitledString                = 'Untitled';
  TitleFlag                     = 'T';

  SDX                           : Integer = 5;
  SDY                           : Integer = 5;

  Popup                         : Boolean = False;

  FileWasModified               : Boolean = False;

  ColorFlex                     : FlexAttrs = (BlackOnLtGray, WhiteOnLtGray,
                                               YellowOnLtGray, BlueOnLtGray);

  MonoFlex                      : FlexAttrs = (YellowOnBlue, LtGreenOnBlue,
                                               LtMagentaOnBlue, LtRedOnBlue or Blink);

  SortOrder                     : SortTypes = so_ByDateTime;
  Ascending                     : Boolean = False;

  ShowIndex                     : Boolean = False;

  seLI                          : Word = OpKey.F1;
  seDB                          : Word = OpKey.F3;
  seDE                          : Word = OpKey.F4;
  seSU                          : Word = OpKey.F7;
  seSP                          : Word = OpKey.ShF10;
  seSC                          : Word = OpKey.F5;
  seTM                          : Word = OpKey.F8;
  spLI                          : Word = OpKey.F1;
  spDB                          : Word = OpKey.F3;
  spDE                          : Word = OpKey.F4;
  spRP                          : Word = OpKey.ShF10;
  spSP                          : Word = OpKey.ShF10;
  spSD                          : Word = OpKey.ShF5;
  spSN                          : Word = OpKey.ShF9;

var
  NumItemsHeader                : Integer;
  SortHeader                    : Integer;
  CurEditor                     : PNote;

  constructor TIndexCollection.Init(ALimit, ADelta : Integer);
  begin
    Inherited Init(ALimit, ADelta);
    Duplicates := True;
  end;

  function TIndexCollection.Compare(Key1, Key2 : Pointer) : Integer;
  begin
    case SortOrder of
      so_None       : Compare := 0;
      so_ByTitle    : if Ascending then
                        Compare := Ord(CompUCString(PEntry(Key1)^.GetTitle, PEntry(Key2)^.GetTitle)) - 1
                      else
                        Compare := Ord(CompUCString(PEntry(Key2)^.GetTitle, PEntry(Key1)^.GetTitle)) - 1;
      so_ByDateTime :
                      begin
                        if Ascending then
                          Compare := Ord(CompString(PEntry(Key1)^.SortDate,
                                                    PEntry(Key2)^.SortDate)) - 1
                        else
                          Compare := Ord(CompString(PEntry(Key2)^.SortDate,
                                                    PEntry(Key1)^.SortDate)) - 1
                      end;
    end;
  end;

  function MakePath(FileName : PathStr) : PathStr;
  var
    UName                         : NameStr;
    Drive                         : Char;
  begin
    FileName := JustFileName(FileName);
    UName := 'NEN';
    Drive := 'C';
    if SYS^.NovellSys then
      begin
        UName := Sys^.UsersName;
        Drive := 'I';
      end;
    MakePath := Drive + ':' + NEN^.PrivateDir + '\' + UName + '\PRIVATE\' + FileName;
  end;

  procedure CreateFile(var NP : PathStr);
  begin
    Randomize;
    NP := MakePath(ForceExtension('N' + Long2Str(Random(65534)), 'NPE'));
    while ExistFile(NP) do
      NP := MakePath(ForceExtension('N' + Long2Str(Random(65534)), 'NPE'));
  end;

  procedure CreateNotepadName(var NPName : TitleStr);
  begin
    NPName := ' ' + #1 +
              ' ' + #1 +
              TodayString('yymmdd') + #1 +
              CurrentTimeString('hhmmss') + #1;
  end;

  function GetListKeyForCommand(Cmd : NameStr; var FKey : Integer; var Level : KeyLevelT; var Scan : Word) : Boolean;
  var
    FN                            : String[20];
    i, e                          : Integer;
    GetKey                        : Boolean;
  begin
    GetListKeyForCommand := False;
    GetKey := FindListKeyForCommand(Cmd, FN, Scan);
    if not GetKey then
      Exit
    else
      GetListKeyForCommand := True;
    FN := Trim(FN);
    case FN[1] of
      'F' : Level := UnShift;
      'S' : Level := Shift;
      'C' : Level := Ctrl;
      'A' : Level := Alt;
      else
        Level := UnShift;
    end;
    Val(CleanupCommand(FN), FKey, e);
  end;

  function GetEditKeyForCommand(Cmd : NameStr; var FKey : Integer; var Level : KeyLevelT; var Scan : Word) : Boolean;
  var
    FN                            : String[20];
    i, e                          : Integer;
    GetKey                        : Boolean;
  begin
    GetEditKeyForCommand := False;
    GetKey := FindEditKeyForCommand(Cmd, FN, Scan);
    if not GetKey then
      Exit
    else
      GetEditKeyForCommand := True;
    FN := Trim(FN);
    case FN[1] of
      'F' : Level := UnShift;
      'S' : Level := Shift;
      'C' : Level := Ctrl;
      'A' : Level := Alt;
      else
        Level := UnShift;
    end;
    Val(CleanupCommand(FN), FKey, e);
  end;

  procedure SetEditorFKeys(Caller: Callers);
  var
    Key                           : Integer;
    Level                         : KeyLevelT;
    Scan                          : Word;
  begin
    ClearFKeys;
    If Sys^.DoCBSNews Then
       Begin
       If Caller = caUrgent Then
         Begin
         SetTag(6, UnShift, 'Q Msg');
         SetTag(7, UnShift, 'Quit');
         SetTag(8, UnShift, 'Print');
         SetTag(9, UnShift, 'Mail');
         SetTag(10, UnShift, 'Zip');
         SetTag(8, Shift, 'Queue');
         SetTag(4, Alt, 'Begin');
         SetTag(5, Alt, 'End');
         Exit;
         End
       Else
         Begin
         SetTag(3, UnShift, 'TCode');
         SetTag(5, UnShift, 'List');
         SetTag(6, UnShift, 'Title');
         SetTag(7, UnShift, 'Quit');
         SetTag(8, UnShift, 'Print');
         SetTag(9, UnShift, 'Mail');
         SetTag(10, UnShift, 'Save');
         SetTag(8, Shift, 'Queue');
         SetTag(4, Alt, 'Begin');
         SetTag(5, Alt, 'End');
         Exit;
         End;
       End;

    SetTag(2, UnShift, 'TCode');
    if Caller = caNotepad then
      SetTag(6, UnShift, 'Title');
    if GetEditKeyForCommand('DB', Key, Level, seDB) then
      SetTag(Key, Level, 'Begin')
    else
      SetTag(3, UnShift, 'Begin');
    if GetEditKeyForCommand('DE', Key, Level, seDE) then
      SetTag(Key, Level, 'End')
    else
      SetTag(4, UnShift, 'End');
    if Caller <> caUrgent then
      if GetEditKeyForCommand('SU', Key, Level, seSU) then
        SetTag(Key, Level, 'Save')
      else
        SetTag(7, UnShift, 'Save');
    if GetEditKeyForCommand('SP', Key, Level, seSP) then
      SetTag(Key, Level, 'Print')
    else
      SetTag(10, Shift, 'Print');
{    if GetEditKeyForCommand('LI', Key, Level, seLI) then
      SetTag(Key, Level, 'List')
    else}
      SetTag(10, UnShift, 'List');
    {$IFDEF MailInNotepad}
    if GetListKeyForCommand('SC', Key, Level, seSC) then
      SetTag(Key, Level, 'Queue')
    else
      SetTag(10, UnShift, 'Queue');
    if GetListKeyForCommand('TM', Key, Level, seTM) then
      SetTag(Key, Level, 'Mail')
    else
      SetTag(8, UnShift, 'Mail');
    {$ENDIF}
{    SetTag(3, Alt, 'Import');}
  end;

  procedure SetPicklistFKeys(Caller: Callers);
  var
    Key                           : Integer;
    Level                         : KeyLevelT;
    Scan                          : Word;
  begin
    ClearFKeys;
    {  SetTag( 5,    UnShift, 'Delete');}
    SetTag(9, UnShift, 'New');
    SetTag(2, UnShift, 'Alpha');
    SetTag(3, UnShift, 'Time');
    SetTag(4, UnShift, '+ or -');

    If Sys^.DoCBSNews Then
      Begin
      SetTag(7, UnShift, 'Quit');
      SetTag(8, UnShift, 'Print');
      SetTag(5, UnShift, 'Delete');
      End
      Else
      Begin
      if GetListKeyForCommand('RP', Key, Level, spRP) then
        SetTag(Key, Level, 'Print')
      else
        SetTag(10, Shift, 'Print');
      if GetListKeyForCommand('SD', Key, Level, spSD) then
        SetTag(Key, Level, 'Delete')
      else
        SetTag(5, UnShift, 'Delete');
      if GetListKeyForCommand('SN', Key, Level, spSN) then
        SetTag(Key, Level, 'New')
      else
        SetTag(9, UnShift, 'New');
      End;
  end;

  procedure ReSortIndex;
  var
    NI                            : PIndexCollection;
    TE                            : String;
    PE                            : PEntry;
    i                             : Integer;
  begin
    if Index = nil then Exit;
    NotepadPickList^.ChangeHeader(SortHeader, 'Sorting..');
    New(NI, Init(40, 10));
    for i := 1 to Index^.Count do
      begin
        PE := PEntry(Index^.At(i - 1));
        TE := PE^.CreateLine;
        New(PE, Init(TE));
        NI^.Insert(PE);
      end;
    Dispose(Index, Done);
    Index := NI;
  end;

  { // One entry in the Index // }

  constructor TEntry.Init(S : String);
  begin
    EntryDate := Today;
    EntryTime := OpDate.CurrentTime;
    Title := UntitledString;
    HasTitle := False;
    CreateFile(Path);
    if S <> '' then
      ParseLine(S);
  end;

  destructor TEntry.Done;
  begin
  end;

  procedure TEntry.ParseLine(S : String);
  const
    Delim                         = [#1];
  begin
    HasTitle := ExtractWord(1, S, Delim) = TitleFlag;
    Title := Trim(ExtractWord(2, S, Delim));
    if Title = '' then Title := UntitledString;
    EntryDate := DateStringToDate('yymmdd', ExtractWord(3, S, Delim));
    EntryTime := TimeStringToTime('hhmmss', ExtractWord(4, S, Delim));
    Path := ExtractWord(5, S, Delim);
  end;

  function TEntry.CreateLine: String;
  var
    Flag                          : Char;
  begin
    Flag := ' ';
    if HasTitle then
      Flag := 'T';
    CreateLine := Flag + #1 + Title + #1 + DateToDateString('yymmdd', EntryDate) + #1 +
                  TimeToTimeString('hhmmss', EntryTime) + #1 + Path;
  end;

  function TEntry.GetTitle: Str20;
  begin
    GetTitle := Title;
  end;

  function TEntry.GetTitleForHeader : Str20;
  begin
    if HasTitle then
      GetTitleForHeader := Title
    else
      GetTitleForHeader := UntitledString;
  end;

  function TEntry.GetPath: PathStr;
  begin
    GetPath := Path;
  end;

  function TEntry.GetDate: Str20;
  begin
    GetDate := DateToDateString(InternationalDate(False, True), EntryDate);
  end;

  function TEntry.GetTime: Str20;
  begin
    GetTime := TimeToTimeString('hh:mm:ss', EntryTime);
  end;

  function TEntry.GetHeader: TitleStr;
  begin
    GetHeader := GetTitle + ' ' + GetDate + ' ' + GetTime;
  end;

  function TEntry.SortDate: Str20;
  begin
    SortDate := DateToSortString(EntryDate) + TimeToSortString(EntryTime);
  end;

  procedure TEntry.ChangeTitle(var S : String; var S2 : String);
  begin
    if Trim(S2) = '' then S2 := UntitledString;
    if (not HasTitle) and(S = UntitledString) then
      S := Copy(S2, 1, 20)
    else
      HasTitle := True;
    Title := S;
  end;

  procedure TEntry.ChangeDateTime;
  begin
    EntryDate := Today;
    EntryTime := OpDate.CurrentTime;
  end;

  function GetYesNo(MsgCode : Word; Prompt : string;
                    Default : Byte; QuitAndAll : Boolean) : Byte;
  begin
    Case Dialog(SysMsg(000986) {'File modified, Save?'},'Notepad',Blue,'Yes','No','') of
      0  : GetYesNo := teQuit;
      1  : GetYesNo := teYES;
      2  : GetYesNo := teNO;
      end;
  end;

  procedure GetNewFileName(Mask : DirStr; var FileName : PathStr);
  var
    FDB                           : FileDialogPtr;
    Cmd, Status                   : Word;
    Finished                      : Boolean;
    FName                         : PathStr;
    DragCommands                  : DragProcessor;

    function InitDialogBox        : Word;
      {-Initialize dialog box}
    const
      WinOptions                    = wBordered + wClear + wUserContents;
    begin
      New(FDB, InitCustom(
        17, 6,                    {top left corner (X,Y)}
        NENColorSet,              {main color set}
        WinOptions,               {window options}
        NENDialogSet,             {dialog box-specific colors}
        hProtected,               {help button: *protected*, hidden, or visible}
        Mask                      {file mask}
        ));
      if FDB = nil then 
      begin
        InitDialogBox := InitStatus;
        Exit;
      end;
      CustomizeWindow(FDB^, 'Select File', 49);

      InitDialogBox := FDB^.RawError;
    end;

  begin
    {select alternate scroll bar arrows}
    DefArrows := TriangleArrows;

    FileName := '';

    Gray_Scheme;

    {initialize dialog box}
    Status := InitDialogBox;
    if Status <> 0 then 
    begin
      WriteLn('Error initializing dialog box: ', Status);
      Halt(1);
    end;

    {initialize DragProcessor}
    DragCommands.Init(@DialogKeySet, DialogKeyMax);
    CustomizeCommandProcessor(DragCommands);
    FDB^.SetCommandProcessor(DragCommands);

    Finished := False;
    FName := '';
    {    StuffKey(Tab);}
    repeat
      {process commands}
      FDB^.Process;

      Cmd := FDB^.GetLastCommand;
      case Cmd of
        ccMouseDown,
        ccMouseSel :
          {did user click on the hot spot for closing?}
          if HandleMousePress(FDB^) = hsRegion3 then 
          begin
            ClearMouseEvents;
            Finished := True;
          end;
        ccSelect :
          begin
            FileName := FDB^.GetFileName;
            Finished := True;
          end;
        ccUser40 : if KeyboardMove(FDB^) then ;
        ccQuit, ccError :
          Finished := True;
      end;
    until Finished;

    FDB^.Erase;
    Dispose(FDB, Done);
  end;

{$F+}
  function GetNewFileProc(MsgCode : Word; Prompt : String;
                          ForceUp, TrimBlanks, Writing, MustExist : Boolean;
                          MaxLen                        : Byte; DefExt : ExtStr;
                          var S                         : String) : Boolean;
  var
    LastCommand                   : Word;
  begin
    GetNewFileProc := False;
    if ChildEditorPtr <> nil then
      LastCommand := ChildEditorPtr^.GetLastCommand
    else
      LastCommand := CommandWindowPtr(wStack.TopWindow)^.GetLastCommand;
    case LastCommand of
      ccBlkWrite : PickSaveFile(S);
      ccBlkRead  : PickGetFile(S);
      else
        begin
          if DefExt = '' then
            DefExt := '*';
          GetNewFileName('*.*', S);
        end;
    end;
    if S <> '' then
      GetNewFileProc := True;
  end;

  procedure EditWindowStatus(MP : MemoPtr);
    {-Display status line}
  const
    Save : array[Boolean] of Char = (' ', #$FB);
    InsMode: array[Boolean] of Char = ('O','I');
    StatusLine : string[14] =
      'xxxxx:xxx I '+#$FB+' ';
  var
    S : string[5];
    Indent: word;
    Pc: Integer;
    SaveMouse : Boolean;
  begin
    with MP^ do
      begin
      if FrameModified then
        begin
          Dec(FrameRedrawAfter);
          if FrameRedrawAfter = 0 then
            begin
              wFrame.Draw;
              FrameRedrawAfter := 2;
              FrameModified := false;
            end;
        end;
      {insert line number}
      S := Long2Str(meCurLine);
      Indent := 5-Length(S);
      S := LeftPadCh(S,wFrame.frChars[5],5);
      MoveFast(S[1], StatusLine[6-Length(S)], Length(S));

      {insert column number}
      S := Long2Str(meCurCol);
      S := Pad(S, 3);
      MoveFast(S[1], StatusLine[7], 3);

      {insert percentage of buffer used}
      Pc := Trunc((meTotalBytes*100.0)/(meBufSize-2));

      {insert remaining fields}
      MoveFast(InsMode[meOptionsAreOn(meInsert)], StatusLine[11], 1);
      MoveFast(Save[meOptionsAreOn(meModified)], StatusLine[13], 1);

      HideMousePrim(SaveMouse);

      {display status line}
      with wFrame do
        begin
          FastWrite(StatusLine, frYH, frXl+2, frFrameColor);
          ChangeAttribute(12, frYH, frXl+2+Indent, frHeaderColor);
          ChangeAttribute(1, frYH, frXl+14, (frFrameColor and $F0) or LightRed );
          FastWrite(LeftPad(Long2Str(Pc),3)+'%', frYH, frXl+16, (frFrameColor and $F0) or LightGreen);
        end;

      if (FileWasModified) and (not meOptionsAreOn(meModified)) then
        begin
          OpenMessage('Done ' , Gray_Scheme);
          Delay (2000);
          CloseMessage;
        end;
      FileWasModified := meOptionsAreOn(meModified);

      ShowMousePrim(SaveMouse);
    end;
  end;

  { // A Note editor // }
  constructor TNote.InitDeluxe(x1, y1, x2, y2                : Byte;
                               NTitle                        : TitleStr;
                               FPath                         : PathStr;
                               CallerID                      : Callers;
                               MapKeys                       : Boolean;
                               ReadOnly                      : Boolean);
  var
    Key                           : Integer;
    Lev                           : Word;
    Scan                          : Word;
  Const
    Exits                         : Set Of Byte = [ccSaveFile];
  begin
    Path := FPath;
    AllDone := False;
    Copyright_Scheme;
    RemapKeys := MapKeys;
    IsReadOnly := ReadOnly;
    Caller := CallerID;
    NENColorSet.FrameColor := DkGrayOnBlue;
    NENColorSet.HeaderColor := LtGreenOnBlue;
    NENColorSet.BlockColor := BlackOnYellow;
    NENColorSet.ScrollBarColor := BlackOnCyan;
    NENColorSet.HotSpotColor := LtRedOnBlue;
    NENColorSet.TextColor := YellowOnBlue;
    if not InitCustom(x1, y1, x2, y2, {Window coordinates}
                      NENColorSet, {ColorSet}
                      DefWindowOptions or wBordered
                      or wAltFrame or wResizeable, {Window options}
                      32767) then {Buffer size}
      begin
        WriteLn('Failed to init TextEditor. Status = ', InitStatus);
        Fail;
      end;

    Explode := True;
    Title := NTitle;
    CustomizeWindow(Self, Title, 20);
    AddScrollBars(Self, True);

    SetErrorProc(ErrorProc);
    If Caller <> caUrgent Then
       SetGetFileProc(GetNewFileProc);
    teOptionsOff(teMakeBackups);
    SetYesNoProc(GetYesNo);
    SetEditProc(EditProc);
    SetStatusProc(EditWindowStatus);
    HelpProc := NilHelpProc;
{    if ReadOnly then
      teOptionsOn(teReadOnly);}

    if FKeysUp then
      SetPosLimits(1, 5, ScreenWidth, 22)
    else
      SetPosLimits(1, 5, ScreenWidth, 24);

    StatWin := nil;
    FileEdit := True;

    New(ECP, InitCustom(@EditorKeySet, EditorKeyMax, @FunctionKeySet, FunctionKeyMax, DefCmdOptions));
    with ECP^ do
      begin
{        SetSecondaryKeyPtr(@FunctionKeySet, FunctionKeyMax);}
        If Sys^.DoCBSNews Then
          Begin
          If Caller = caUrgent Then
            Begin
            AddCommand(ccAbandonFile, 1, OpKey.Esc,   0);
            AddCommand(ccBlkBegin,    1, OpKey.AltF4, 0);
            AddCommand(ccBlkEnd,      1, OpKey.AltF5, 0);
            AddCommand(ccUser2,    1, 0,        0);
            AddCommand(ccUser3,    1, 0,        0);
            AddCommand(ccUser4,    1, 0,        0);
{             AddCommand(ccSaveFile,    1, 0,        0)}
            AddCommand(ccUser16,      1, Opkey.F9,    0);          {Mail}
            AddSecondaryCommand(ccUser14,      1, OPkey.ShF8,  0); {Queue}
            AddCommand(ccAbandonFile, 1, OpKey.F7,   0);           {Save/exit}
            AddCommand(ccUser19,      1, Opkey.F8,    0); {Print}
            AddCommand(ccUser21,      1, Opkey.F10,    0); {Push To Zip}
            AddCommand(ccUser22,      1, Opkey.F6,    0);  {Push To QMsg}
            End
          Else
            Begin
            AddCommand(ccAbandonFile, 1, OpKey.Esc,   0);
            AddCommand(ccBlkBegin,    1, OpKey.AltF4, 0);
            AddCommand(ccBlkEnd,      1, OpKey.AltF5, 0);
            AddCommand(ccSaveFile,    1, OpKey.F10,  0);
            AddCommand(ccUser16,      1, Opkey.F9,    0);          {Mail}
            AddSecondaryCommand(ccUser14,      1, OPkey.ShF8,  0); {Queue}
            AddSecondaryCommand(ccUser15,      1, OpKey.F6,    0); {Title}
            AddCommand(ccUser17,      1, OpKey.F5,   0);           {Save/exit}
            AddCommand(ccAbandonFile, 1, OpKey.F7,   0);           {Save/exit}
            AddCommand(ccUser19,      1, Opkey.F8,    0); {Print}
            AddCommand(ccUser20,      1, Opkey.F3,    0); {TimeCode}
{!!mo          AddCommand(ccUser21,      1, Opkey.F10,    0);} {Push To Zip}
{!!mo          AddCommand(ccUser22,      1, Opkey.F6,    0);} {Push To QMsg}
            End;
          cpOptionsOn(cpEnableMouse);
          SetKeypressedProc(Ukey.KeyWaiting);
          SetGetKeyProc(Ukey.GetKey);
          SetExitCommands (@Exits);
          End
          Else
          Begin
  {        SetSecondaryKeyPtr(@FunctionKeySet, FunctionKeyMax);}
          AddCommand(ccAbandonFile, 1, OpKey.Esc,   0);
          AddCommand(ccBlkBegin,    1, seDB,        0);
          AddCommand(ccBlkEnd,      1, seDE,        0);
          if Caller = caUrgent then
            Begin
            AddCommand(ccSaveFile,    1, 0,        0);
            AddCommand(ccUser21,      1, Opkey.F10,    0); {Push To Zip}
            AddCommand(ccUser22,      1, Opkey.F6,    0); {Push To QMsg}
            End
          else
            begin
            AddCommand(ccSaveFile,    1, seSU,        0);
            End;
          AddCommand(ccUser16,      1, seTM,        0);
  {        AddSecondaryCommand(ccNewFile,     1, OpKey.AltF3, 0);}
          AddSecondaryCommand(ccUser14,      1, seSC,        0);
          AddSecondaryCommand(ccUser15,      1, OpKey.F6,    0);
          AddSecondaryCommand(ccUser17,      1, OpKey.F10{seLI},        0);
          AddSecondaryCommand(ccUser19,      1, seSP,        0);
          AddCommand(ccUser20,      1, Opkey.F2,    0); {TimeCode}
          cpOptionsOn(cpEnableMouse);
          SetKeypressedProc(Ukey.KeyWaiting);
          SetGetKeyProc(Ukey.GetKey);
          SetExitCommands (@Exits);
          End;
      end;
    SetCommandProcessor(ECP^);

    Modified := False;
    AllDone := False;

    ReadFile(FPath, FileSize);
  end;

  constructor TNote.Init(FPath : PathStr; Level : Word);
  var
    Y                             : Integer;
  begin
    Y := CW^.WindowY + 1;
    if Y <= 0 then
      Y := 4;
    InitDeluxe(2, Y, 79, 21, 'Unknown', FPath, caNotepad, True, False);
  end;

  destructor TNote.Done;
  begin
    if StatWin <> nil then
      begin
        StatWin^.Erase;
        Dispose(StatWin, Done);
        StatWin := nil;
      end;
    SetPosLimits(1, 5, ScreenWidth, 21);
    Dispose(ECP, Done);
    Inherited Done;
  end;

  procedure TNote.SetTitle(NewTitle : TitleStr; NewDateTime : Str20);
  begin
    Title := NewTitle;
    DateTime := NewDateTime;
    ChangeHeader(0, Title + ' ' + DateTime);
  end;

  procedure TNote.UpdateTitle(NewTitle : TitleStr);
  begin
    Title := Trim(NewTitle);
    ChangeHeader(0, Title + ' ' + DateTime);
  end;

  procedure TNote.UpdateDateTime(NewDateTime : Str20);
  begin
    DateTime := NewDateTime;
  end;

  procedure TNote.LoadFile(FPath : PathStr);
  begin
    ReadFile(FPath, FileSize);
    teOptionsOff(teModified);
  end;

  procedure TNote.PrintNote;
  var
    PQL                           : QueueListPtr;
    COP                           : CylonObjPtr;
    S                             : String;
    CurPrn                        : Integer;
    CurCopy                       : Integer;
    CurLine                       : Integer;
    OK                            : Boolean;
    Local                         : Boolean;
  begin
    S := '';
    COP := Nil;
    if EditProc(0, 'Enter Printer Numbers', True, True, $FE, S) then
      begin
        New(PQL, Init(AddBackSlash(NEN^.SysDir) + 'NENPRINT.INI', Other));
        if PQL <> nil then
          begin
            if PQL^.DumbSelect(S) then
              begin
                New(COP, Init(SysMsg(2403) {Printing in progress} , 10));
                if COP = nil then
                  begin
                    Dispose(PQL, Done);
                    Exit;
                  end;
                COP^.Draw;

                OK := True;
                for CurPrn := 1 to PQL^.Size do
                  begin
                    if PQL^.IsPicked(CurPrn, PickByPos) then
                      begin
                        Local := PQL^.GetServer(CurPrn) = 'LOCAL';
                        if PQL^.Capture(CurPrn) then
                          begin
                            for CurCopy := 1 to PQL^.GetCopies(CurPrn) do
                              begin
                                COP^.Update;
                                OK := False;

                                with PQL^ do
                                  begin
                                    if not PQL^.SendAttr(CurPrn, TOP) then Break;
                                    if not SendAttr(CurPrn, BOLD) then Break;
                                    if not QWriteLn(Pad(Title, 62) + DateTime) then Break;
                                    if not QWriteLn(PadCh('', '-', 79)) then Break;
                                    if not SendAttr(CurPrn, NORM) then Break;
                                    for CurLine := 1 to meTotalLines do
                                      begin
                                        meGetLine(S, CurLine);
                                        QWriteLn(S);
                                        COP^.Update;
                                      end;
                                    if not SendAttr(CurPrn, EOJ) then Break;
                                  end;

                                OK := True;
                              end;
                          end;
                        PQL^.EndCap(CurPrn);
                      end;
                    if not OK then Break;
                  end;
              end;
            if COP <> nil then
              Dispose(COP);
            Dispose(PQL, Done);
          end;
      end;
  OpenMessage('Done ' , Gray_Scheme);
  Delay (1000);
  CloseMessage;
  end;

  procedure TNote.PrintUrgent;
  var
    PQL     : QueueListPtr;
    COP     : CylonObjPtr;
    S       : String;
    CurPrn  : Integer;
    CurCopy : Integer;
    CurLine : Integer;
    OK      : boolean;
    Local   : boolean;
    CurDrive : DriveName;

  begin
    CurDrive := Sys^.CurrentDriveID;
    ChangeDrive (Sys^.SysDrive);
    S := '';
    COP := Nil;
    if EditProc(0, SysMsg(2299) {'Enter Printer Numbers'} , True, True, $FE, S) Then
      Begin
      New(PQL, Init(AddBackSlash(NEN^.SysDir)+'NENPRINT.INI',Other));
      if PQL <> nil then
        begin
        if PQL^.DumbSelect(S) then
          begin
          New(COP, Init(SysMsg(2403) {Printing in progress} , 10));
          IF Cop = nil then
            begin
            Dispose(PQL, Done);
            ChangeDrive (CurDrive);
            Exit;
            end;
          Cop^.Draw;

          OK := True;
          For CurPrn := 1 TO PQL^.Size do
            begin
            if PQL^.IsPicked(CurPrn, PickByPos) Then
              begin
              Local := PQL^.GetServer(CurPrn) = 'LOCAL';
              if PQL^.Capture(CurPrn) Then
                begin
                For CurCopy := 1 TO PQL^.GetCopies(CurPrn) do
                  begin
                  COP^.Update;
                  OK := False;
                  With PQL^ do
                    begin
                    if not PQL^.SendAttr(CurPrn, TOP)  Then Break;
                    if not SendAttr(CurPrn, BOLD) Then Break;
                    S := 'URGENT - Printed ' + TodayString('dd/nnn/yyyy') +
                       ' at ' + CurrentTimeString('hh:mm:ss te');
                   if not QWriteLn(Pad(S,62)+DateTime) Then Break;
                    if not QWriteLn(PadCh('','-',79)) Then Break;
                    if not SendAttr(CurPrn, NORM) Then Break;
                    For CurLine := 1 to meTotalLines do
                      begin
                      meGetLine(S, CurLine);
                      QWriteLn(S);
                      COP^.Update;
                      end;
                    if not SendAttr(CurPrn, EOJ) Then Break;
                    end;

                  OK := True;
                  end;
                end;
                PQL^.EndCap(CurPrn);
              end;
            if not OK then Break;
            end;
          end;
        if COP <> nil then
          Dispose(COP);
        Dispose(PQL, Done);
        End;
      End;
  ChangeDrive (CurDrive);
  OpenMessage('Done ' , Gray_Scheme);
  Delay (1000);
  CloseMessage;
  end;

  procedure TNote.Execute;
  var
    Parent                        : ParentRecP;
    LocalChoice                   : Word;
    BytesAtStart                  : Word;
    S                             : String;
    i                             : Integer;
    Escape                        : Boolean;
    ErrorCode                     : Word;
    AllQs                         : Boolean;
    Queue                         : AnyString;
    MNP                           : MsgNodeP;
    IoBuf                         : IoBuffPtr;
    Server                        : ServerStr;
    Volume                        : VolumeStr;
    QPath                         : PathStr;
    QRights                       : Access;
    AllLevels                     : Boolean;
    QDrive                        : Char;
    QType                         : QueueTypes;
    ExitKey                       : word;
    IOB                           : IOBuffPtr;
    Hour24TimeMask                : String[8];
    S1                            : String[20];
    Bufflen                       : Word;
    MsgBuf                        : TBuf;
    UserToNotify                  : String[25];

    procedure ShutDown;
    begin
        if GetPathP <> nil then
            dispose(GetPathP, Done);
        GetPathP := nil;
        if MNP <> nil then
            dispose(MNP, Done);
        MNP := nil;
        If Parent <> Nil Then
           DISPOSE(Parent);
    end;

  Procedure StripControlChars;
  Var I : Integer;
     Begin
     For I := 1 To Self.meTotalBytes Do
        Begin
        If (Self.meBufPtr^[I] < ' ') And
           (Self.meBufPtr^[I] <> #$0D) And
           (Self.meBufPtr^[I] <> #$0A) Then
           Begin
           Move (Self.meBufPtr^[I+1], Self.meBufPtr^[I],
              Self.meTotalBytes - I);
           Self.meBufPtr^[Self.meTotalBytes] := ' ';
           I := I - 1;
           End;
        End;
     End;

  begin
    BytesAtStart := meTotalBytes;
    if RemapKeys then
      SetEditorFKeys(Caller);
    Popup := False;
    If Caller = caUrgent Then
       StripControlChars;

    repeat
      Select;
      KeyCapture := True;
      Process;
      ExitCommand := GetLastCommand;
      ExitKey     := GetLastKey;
      ErrorCode := GetLastError;
      case ExitCommand of
        ccMouseDown,
        ccMouseSel :
          {did user click on the hot spot for closing?}
          if HandleMousePress(Self) = hsRegion3 then
          begin
            ClearMouseEvents;
            AllDone := True;
          end;
        ccSaveExit,               {Save and exit -- file already saved}
        ccError :                 {Fatal error}
          begin
            AllDone := True;
            Modified := (teOptionsAreOn(meModified)) or
                        (meTotalBytes > 1);
          end;
        ccSaveFile:
          begin
            Sound(880);
            Delay(100);
            Nosound;
          end;
        ccNewFile :
          begin
            if (not IsReadOnly) and (teOptionsAreOn(teModified)) then
              if UserSaysYes(SysMsg(000986) {'File modified, Save?'} , EscapemeansNo) then
                begin
                  SaveFile;
                  Modified := False;
                end;
            GetFileName('*.*', Path);
            LoadFile(Path);
          end;
        {$IFDEF MailInNotepad}
        ccUser14 :                { Send to Queue }
          begin
            Server := '';
            Volume := '';
            Path := '';
            AllQs := False;
            AllLevels := False;
            QType := qtAll;
            Server := '';
            Volume := '';
            QPath := '';

            if Not ChooseQueue(Server, Volume, QPath, QRights, QType,
                               QDrive, AllQs, AllLevels, 'Select Queue') then
              Continue;
            NENFlag := False;
            OpenMessage('Sending ' + Title + ' to ' + QPath, Gray_Scheme);
            CopyEditBufferToQueue(Self, Server, Volume, QPath, QDrive, Title);
            CloseMessage;
            NENFlag := True;
          end;
        ccUser22 :
           Begin
           Bufflen := Self.meTotalBytes;
           If Bufflen > SizeOf(MsgBuf)-1 Then
              Bufflen := SizeOf(MsgBuf)-1;
           FillChar (MsgBuf, SizeOf(MsgBuf), ' ');
           Move (Self.meBufPtr^, MsgBuf, BuffLen);
           Bufflen := Bufflen + 1;
           MsgBuf[Bufflen] := #$1A;
           S := '';
           if EditProc(0, 'Enter Destination Name', True, True, $FE, S) then
              Begin
              UserToNotify := S;

              If SendMessage(UserToNotify, MsgBuf, Bufflen,
                     Sys^.ToDrive) Then
                 Begin
                 OpenMessage('Done ' , Gray_Scheme);
                 Delay (1000);
                 CloseMessage;
                 End;
              End;
           End;
        ccUser21 :
           begin
           Bufflen := Self.meTotalBytes;

           GetMem (IoBuf, Bufflen);
           If IOBuf <> Nil Then
              Begin
              Move (Self.meBufPtr^, IOBuf^, BuffLen);
              IOBuf^[BuffLen+1] := #$1A;
              IOBuf^[BuffLen+2] := #$1A;
              BuffLen := BuffLen + 2;
              If InsertNote(Title, IoBuf, BuffLen) = 0 Then
                 Begin
                 OpenMessage('Done ' , Gray_Scheme);
                 Delay (1000);
                 CloseMessage;
                 End;
              Freemem (IoBuf, BuffLen-2);
              End;
           end;
        ccUser16 :                { Send to Mail }
          begin
            If Sys^.WordPerfectMail Then
              Begin
              If Caller = caNotepad Then
                OutputNotePadWPMail(Self, NotePad);
              If Caller = caUrgent Then
                OutputNotePadWPMail(Self, Urgent);
              End
            Else
              Begin
              {set up nen/mhs paths}
              if GetPathP = nil then
                  InitMailDeliveryMode;

              New(Parent);
              if Parent = nil then
                 begin
                 DispErrorDeluxe('Unable to Create Parent', 'MailScript', TRUE, Iam);
                 ShutDown;
                 exit;
                 end;

              FillChar(Parent^, SizeOf(ParentRecT), #0);
              {Parent^.IsDummy := TRUE;}

              {create the appropriate polymorphic message node}
              Case GetPathP^.GetDeliveryMode of
                  EMHSMail :
                      MNP := New(MHSMsgNodeP, Init(true, '', 99, ENONE,
                         EGOODSEC, Parent));
                  ENENMail :
                      MNP := New(NENMsgNodeP, Init(true, '', 99, FALSE, ENONE,
                         EGOODSEC, Parent));
              end;

              if MNP = nil then
                begin
                  DispErrorDeluxe('Error in MailNote', ErrorMessage(InitStatus), TRUE, Iam);
                  ShutDown;
                  exit;
                end;

              {substitute the external buffer for the [unallocated] one internal}
              {to the message node}
              IoBuf := IoBuffPtr(meBufPtr);
              MNP^.StuffBuff(IoBuf, meBufSize);

              MNP^.ToDialog('', ETO);

              if GetPathP <> nil then
                Dispose(GetPathP, Done);
              GetPathP := nil;
              if MNP <> nil THEN
                  Dispose(MNP, Done);
              MNP := nil;
              If Parent <> Nil Then
                 DISPOSE(Parent);
            if RemapKeys then
              SetEditorFKeys(Caller);
            end;
          End;
        {$ENDIF}
        ccUser17,
        ccHelp,
        ccAbandonFile :           {Abandon file}
          begin
            if ExitCommand = ccUser17 then
              ShowIndex := True;
            if (not IsReadOnly) and(teOptionsAreOn(teModified)) then
              if UserSaysYes('File modified, Save?' , EscapemeansNo) then
                begin
                  OpenMessage('Saving ' + Title, Gray_Scheme);
                  SaveFile;
                  CloseMessage;
                  OpenMessage('Done ' , Gray_Scheme);
                  Delay (1000);
                  CloseMessage;
                  Modified := True;
                end
              else
                meTotalBytes := BytesAtStart;
            if (meTotalBytes > BytesAtStart) then
              Modified := True;
            AllDone := True;
          end;
        ccUser15 :
                   begin
                     S := '';
                     GetInput('Enter Title for Note', 'NotePad', WhiteOnRed,
                              'Title:', 20, S, Escape);
                     if not Escape then
                       begin
                         UpdateTitle(S);
                         Modified := True;
                       end;
                   end;
        ccUser19 :
                   begin
                     Case Caller of
                       caUrgent : PrintUrgent;
                       caNotepad: PrintNote;
                     end;
                   end;
        ccUser20 :
                   begin
                   Hour24TimeMask := 'HH:MM:SS';

                   S1 := TimeToTimeString(Hour24TimeMask, QGlobal.CurrentTime);
                   While Pos (' ', S1) > 0 Do
                      S1[Pos (' ',S1)] := '0';

                   PushScanCode (7181);
                   PushScanCode (7181);

                   S1 := S1 + ' - ';
                   For I := 1 To Length(S1) Do
                      Begin
                      Case S1[I] Of
                         '0' : PushScanCode (2864);
                         '1' : PushScanCode (561);
                         '2' : PushScanCode (818);
                         '3' : PushScanCode (1075);
                         '4' : PushScanCode (1332);
                         '5' : PushScanCode (1589);
                         '6' : PushScanCode (1846);
                         '7' : PushScanCode (2103);
                         '8' : PushScanCode (2360);
                         '9' : PushScanCode (2617);
                         ' ' : PushScanCode (14624);
                         ':' : PushScanCode (10042);
                         '-' : PushScanCode (3117);
                         End; {Case}
                      End;
                   end;
        ccUser40 : if KeyboardMove(Self) then ;
        ccUser41 : if ToggleZoom(Self) then ;
        ccUser42 : if KeyboardResize(Self) then ;
      end;
    until AllDone;
    if IsActive then
      EraseHidden;
  end;

  { // Notepad Pick list // }

  procedure SupplyString(Item                          : Word;
                         Mode                          : pkMode;
                         var IType                     : pkItemType;
                         var IString                   : String;
                         PickPtr                       : PickListPtr);
  var CurCol                    : Byte;
    S                             : String[100];
    Attr                          : Char;
    Attr2                         : Char;
    PE                            : PEntry;
  begin
    with Index^ do
      begin
        IType := pkNormal;
        with PickPtr^ do
          case Mode of
            pkDisplay : 
            begin { pretty, with flexwrite chars }
                          Attr := ^A;
                          PE := PEntry(Index^.At(Item - 1));
                          S := PE^.GetTitle;
                          if not PE^.HasTitle then
                            Attr := ^C;
                          IString := ' ' + Attr + Pad(S, 22) + Attr +
                                     PE^.GetDate + ' ' + PE^.GetTime;
                          if Item = GetLastChoice then
                            IString[1] := '';
                        end;
            pkSearch : 
            begin { no extra characters }
                         IString := ' ' + Pad(S, 22) +
                                    PE^.GetDate + ' ' + PE^.GetTime;
                       end;
            pkGetType : 
            begin
                        end;
          end;
      end;
  end;

  procedure SetNumberOfItems(Num : Integer);
  var
    S                             : String[20];
  begin
    with NotepadPickList^ do
      begin
        ChangeNumItems(Index^.Count);
        ChangeHeader(NumItemsHeader, LeftPad(Long2Str(Num), 3));
        case SortOrder of
          so_None : S := 'Unsorted';
          so_ByTitle : S := 'By Title';
          so_ByDateTime : S := 'By Date/Time';
        end;
        if SortOrder <> so_None then
          if Ascending then
            S := S + ' + '
          else
            S := S + ' - ';
        ChangeHeader(SortHeader, S);
      end;
  end;

  procedure InitNotepadPicklist;
  var
    Y                             : Integer;
 Const
    Exits1                         : Set Of Byte = [ccuser6];
    Exits2                         : Set Of Byte = [ccuser0];
  begin
    if NotepadPickList = nil then
      begin
        Gray_Scheme;
        NENColorSet.HeaderColor := RedOnLtGray;

        Y := CW^.WindowY + 3;
        if Y <= 0 then
          Y := 6;
        New(NotepadPickList,
            InitDeluxe(2, Y, 54, 17,
                       NENColorSet,
                       wClear or wUserContents or wBordered,
                       45,
                       Index^.Count,
                       SupplyString,
                       PickVertical,
                       SingleChoice,
                       DefPickOptions - pkMinHeight + pkFlexWrite));
        if NotepadPickList = nil then Exit;

        with NotepadPickList^ do
          begin
            wOptionsOn(wResizeable);
            pkOptionsOn(pkProcessZero);
            pkOptionsOn(pkMinHeight);
            pkOptionsOn(pkFlexWrite);
            SetPickFlex(pkNormal, False,
                        ColorFlex, MonoFlex);
            SetSearchMode(PickStringSearch);
            SetPosLimits(1, Y - 3, 79, 21);
            AdjustFrameCoords(1, Y - 3, 55, 18);
            SetPadSize(1, 1);
            wFrame.AddShadow(shBR, shSeeThru);
            EnableExplosions(4);
            wFrame.AddHeader(' Zippad List ', heTC);
            wFrame.AddHeader('   0', heBL);
            NumItemsHeader := wFrame.GetLastHeaderIndex;
            wFrame.AddHeader('              ', heBR);
            SortHeader := wFrame.GetLastHeaderIndex;
            OptimizeSize;
          end;

        AddScrollBars(NotepadPickList^, False);

        New(PCP, Init(@PickKeySet, PickKeyMax));
        CustomizeCommandProcessor(PCP^);
        with PCP^ do
          begin
            SetSecondaryKeyPtr(@FunctionKeySet, FunctionKeyMax);
            If Sys^.DoCBSNews Then
               NotepadPickList^.SetExitCommands (@Exits1)
                  Else
               NotepadPickList^.SetExitCommands (@Exits2);
            SetKeypressedProc(Ukey.KeyWaiting);
            SetGetKeyProc(Ukey.GetKey);
          end;
        NotepadPickList^.SetCommandProcessor(PCP^);

      end;
  end;

  function PickNotepad(var NoteFile                  : PathStr;
                       var IndexEntry                : PEntry) : Boolean;
  var
    Quit                          : Boolean;
    i                             : Integer;
    Entry                         : PEntry;
    LC,LS                         : Word;
    NPI                           : Text;
    NotepadIndexFile              : PathStr;
  begin
    SetPicklistFKeys(caNotepad);

    Quit := False;
    while not Quit do
      begin
        with NotepadPickList^ do
          begin
            OptimizeSize;
            Draw;
            fFastWrite(Pad('  Title                 Date     Time', 45), 1, 1, DkGrayOnLtGray);
            fFastWrite(Pad('  컴컴컴컴컴컴컴컴컴컴� 컴컴컴컴 컴컴컴컴', 45), 2, 1, DkGrayOnLtGray);
            Process;
            LC := GetLastCommand;
            LS := GetLastKey;
            case GetLastCommand of
              ccMouseDown,
              ccMouseSel :
                {did user click on the hot spot for closing?}
                if HandleMousePress(NotepadPickList^) = hsRegion3 then
                begin
                  ClearMouseEvents;
                  Quit := True;
                end;
              ccSelect :
                         begin
                           NotepadPickList^.Erase;
                           Quit := True;
                           i := GetLastChoice;
                           NoteFile := PEntry(Index^.At(GetLastChoice - 1))^.Path;
                           PickNotepad := True;
                           IndexEntry := PEntry(Index^.At(GetLastChoice - 1));
                         end;
              ccUser0,
              ccUser6,
              ccDone,
              ccQuit :
                       begin
                         NotepadPickList^.Erase;
                         Quit := True;
                         PickNotepad := False;
                       end;
              ccUser4 :
                        begin
                          Entry := PEntry(Index^.At(GetLastChoice - 1));
                          if UserSaysYes('Delete ' + Entry^.GetTitle + '?', EscapemeansNo) then
                            begin
                              Index^.Delete(Entry);
                              ReSortIndex;
                              SetNumberOfItems(Index^.Count);
                              UpdateContents;
                              if Index^.Count = 0 then
                                begin { just deleted last note }
                                  NotepadIndexFile := MakePath('NOTEPAD.NPI');
                                  Assign(NPI, NotepadIndexFile);
                                  Rewrite(NPI);
                                  Close(NPI);
                                  Quit := True;
                                  NotepadPickList^.Erase;
                                  PickNotepad := False;
                                end;
                            end;
                        end;
              ccUser8 :
                        begin
                          NotepadPickList^.Erase;
                          NoteFile := '';
                          Quit := True;
                          PickNotepad := True;
                        end;
              ccUser1 :
                        begin
                          SortOrder := so_ByTitle;
                          Ascending := True;
                          ReSortIndex;
                          SetNumberOfItems(Index^.Count);
                          UpdateContents;
                        end;
              ccUser2 :
                        begin
                          SortOrder := so_ByDateTime;
                          Ascending := False;
                          ReSortIndex;
                          SetNumberOfItems(Index^.Count);
                          UpdateContents;
                        end;
              ccUser3 :
                        begin
                          Ascending := not Ascending;
                          ReSortIndex;
                          SetNumberOfItems(Index^.Count);
                          UpdateContents;
                        end;
            end;
          end;
      end;
  end;

  procedure OpenNotepad(NP : PathStr; var Entry : PEntry);
  var
    NewEntry                      : PEntry;
    NPName                        : TitleStr;
    IsNew                         : Boolean;
  begin
    if (CurEditor <> nil) and(CurEditor^.Modified) then
      if UserSaysYes(SysMsg(000986) {'File modified, Save?'} , EscapemeansNo) then
        CurEditor^.SaveFile;
    IsNew := NP = '';
    if IsNew then
      begin
        New(Entry, Init(''));
        CreateFile(NP);
      end;
    if CurEditor = nil then
      New(CurEditor, Init(NP, 1))
    else
      CurEditor^.LoadFile(NP);
    if CurEditor = nil then
      Dialog('Not Enough Memory!', 'Notepad', Red, 'OK', '','')
    else
      begin
        CurEditor^.NewFile := IsNew;
        if not CurEditor^.NewFile then
          NPName := Entry^.CreateLine
        else
          CreateNotepadName(NPName);
        CurEditor^.SetTitle(Entry^.GetTitleForHeader, Entry^.GetDate + ' ' + Entry^.GetTime);
        if CurEditor^.NewFile then
          begin
            New(NewEntry, Init(NPName + NP));
            Index^.Insert(NewEntry);
          end
        else
          NewEntry := Entry;
        if IsNew then
          Dispose(Entry, Done);
        Entry := NewEntry;
        SetNumberOfItems(Index^.Count);
      end;
  end;

  function ProcessNotePads(Note: PathStr; IndexOnly: boolean): boolean;
  var
    i                             : Integer;
    NotepadIndexFile              : PathStr;
    NP                            : PathStr;
    IX                            : Word;
    NPI                           : Text;
    IoR                           : Word;
    Entry                         : PEntry;
    IndexFileOpen                 : Boolean;
    Line                          : String;
    Quit                          : Boolean;
    NPName                        : TitleStr;
    S                             : String;
  label
    Finish;
  begin
    Index := nil;
    NotepadIndexFile := MakePath('NOTEPAD.NPI');

  {$I-}
    IndexFileOpen := False;
    if ExistFile(NotepadIndexFile) then
      begin
        Assign(NPI, NotepadIndexFile);
        Reset(NPI);
        IoR := IoResult;
        if IoR <> 0 then
          begin
            Dialog('Cannot Open ' + NotepadIndexFile + ', Error ' + Long2Str(IoR), 'Notepad', Red, 'OK', '','');
            Exit;
          end;
        IndexFileOpen := True;
      end;
  {$I+}

    OpenFKeyDisplay(23);

    { Init TCollections for Index and Editors }

    New(Index, Init(40, 10));
    if Index = nil then
      begin
        Dialog('No Memory - Index', 'Notepad', Red, 'OK', '','');
        Exit;
      end;
    CurEditor := nil;

    Entry := nil;

    if IndexFileOpen then
      begin
        while not EoF(NPI) do
          begin
            ReadLn(NPI, Line);
            New(Entry, Init(Line));
            Index^.Insert(Entry);
          end;
        Close(NPI);
      end;

    ProcessNotepads := False;
    ShowIndex := IndexOnly;
    if (ShowIndex) and ((not (IndexFileOpen)) or (Index^.Count = 0)) then
      Goto Finish;

    InitNotepadPicklist;          { Create, but don't activate picklist }
    if NotepadPickList = nil then goto Finish;

    ProcessNotepads := True;

    State := npNew;
    if ShowIndex then State := npPick;

    while State <> npQuit do
      case State of
        npNew :
                begin
                  OpenNotepad(Note, Entry);
                  State := npEdit;
                end;
        npPick :
                begin
                   if PickNotepad(NP, Entry) then
                     begin
                       OpenNotepad(NP, Entry);
                       State := npEdit;
                     end
                   else
                     if Popup then
                       State := npEdit
                   else
                     State := npQuit;
                 end;
        npEdit : 
                 begin
                   CurEditor^.Execute;
                   i := 0;
                   repeat
                     Inc(i);
                     CurEditor^.meGetLine(S, i);
                     S := Trim(S);
                   until (S <> '') or (i > CurEditor^.meTotalLines);
                   Entry^.ChangeTitle(CurEditor^.Title, S);
                   if CurEditor^.Modified then
                     begin
                       Entry^.ChangeDateTime;
                       ReSortIndex;
                       SetNumberOfItems(Index^.Count);
                     end;
                   if not Popup then
                     if (CurEditor^.NewFile) and (not CurEditor^.Modified) then
                       begin
                         Index^.Delete(Entry);
                         ReSortIndex;
                         SetNumberOfItems(Index^.Count);
                       end;
                   if CurEditor^.AllDone then
                     begin
                       Dispose(CurEditor, Done);
                       CurEditor := nil;
                     end;
                   State := npPick;
                   if not ShowIndex then
                     State := npQuit;
                 end;
      end;

    if Index^.Count > 0 then
      begin
        Assign(NPI, NotepadIndexFile);
        Rewrite(NPI);
        for i := 1 to Index^.Count do
          WriteLn(NPI, PEntry(Index^.At(i - 1))^.CreateLine);
        Close(NPI)
      end;

Finish:

    Dispose(Index, Done);
    Index := nil;
    {  Dispose(Entry, Done);}

    if NotepadPickList <> nil then
      begin
        Dispose(NotepadPickList, Done);
        Dispose(PCP, Done);
        NotepadPickList := nil;
        PCP := nil;
      end;

    CloseFKeyDisplay;

  end;

  Function InsertNote(Title: TitleStr; IoBuf: IoBuffPtr; BufLen: word): integer;
  var
    NP                            : PathStr;
    F                             : File;
    IoErr                         : integer;
    NotepadIndexFile              : PathStr;
    IX                            : Word;
    NPI                           : Text;
    Entry                         : PEntry;
    Line                          : String;
  begin
    InsertNote := 0;
    CreateFile(NP);
    {$I-}
    Assign(F, NP);
    Rewrite(F,1);
    IoErr := IoResult;
    if IoErr <> 0 then
      begin
        InsertNote := IoErr;
        Exit;
      end;
    BlockWrite(F, IoBuf^, BufLen);
    IoErr := IoResult;
    if IoErr <> 0 then
      begin
        InsertNote := IoErr;
        Close(F);
        Exit;
      end;
    Close(F);
    Index := nil;
    NotepadIndexFile := MakePath('NOTEPAD.NPI');

    {$I-}
    if ExistFile(NotepadIndexFile) then
      begin
        Assign(NPI, NotepadIndexFile);
        Append(NPI);
        IoErr := IoResult;
        if IoErr <> 0 then
          begin
            InsertNote := IoErr;
            Exit;
          end;
      end;

    Line := 'T' + #1 + Title + #1 + DateToDateString('yymmdd', Today) + #1 +
            TimeToTimeString('hhmmss', OpDate.CurrentTime) + #1 + NP;

    WriteLn(NPI, Line);
    Close(NPI);

    {$I+}
  end;

end.
