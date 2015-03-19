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
{$A-,R-,S-,V-,F+,O+}
{.$D+}
{********************************************************}
{                                                        }
{ (C) 1989 NewsMaker Systems.                            }
{ UEDIT - Dos file editor                                }
{                                                        }
{********************************************************}

Unit UEdit;

{$I NDefine.Inc}
{$I MCDEFINE.INC}

{$DEFINE NENEditorKeys}

interface

uses Dos,OpCrt,OpDos,UMsg,
     Ulib,UGlobal,UWindow,UFkey,
     UMenu,UColors,
     QGlobal,QHdrRec,QInput,OpDate,Qnovell,
     OpRoot,OpFrame,OpWindow,OpEntry,OpMemo,OpString,OpMouse,OpCmd,
     OpMenu,OpPick,OpEdit,OpEditor,OpBrowse,OpDrag,OpDialog,OpCtrl,
     OpCol16,OpField,OpKey,
     Ukey,UDialog;

Const
  EditTitle : String[20] = ' Edit ';

  ReadOnly : boolean = False;
  FrameModified : boolean = False;   { if TRUE, EditStatusProc will }
  FrameRedrawAfter : byte = 2;       { Draw the editors frame after }
                                     { FrameRedrawAfter Calls.      }
                                     { Allows clearing of error msgs}
                                     { on frame when cursor is moved}
Type

  TEditorPtr = ^TEditor;
  TEditor = Object(TextEditor)
      procedure GetNextCommand; virtual;
    end;

  HelpProcType = Procedure(HelpIndex: word);

  NENEditorPtr = ^NENEditor;
  NENEditor = Object(TEditor)
    StatWin     : RawWindowPtr;     { Status line save area }
    ExitCommand : word;
    ECP         : DragProcessorPtr;
    FileEdit    : boolean;          { true if editing file, not buffer}

    Constructor OpenEditFileCustom(X1,Y1,X2,Y2: byte;
                                   Path: PathStr;
                                   Title: TitleString;
                                   Cscheme: ColorSetProc);
    Constructor OpenEditBufCustom(X1,Y1,X2,Y2: byte;
                                  Title: TitleString;
                                  Cscheme: ColorSetProc;
                                  BufPtr : Pointer;
                                  Size : word);
    Procedure AddStatusLine(Line: word);
    Destructor Done; virtual;
    procedure RequestHelp(HelpIndex : Word); virtual;
    end;

Procedure CustomizeTextEditor(var TE: TextEditor);
Procedure EditFile(FileName: PathStr);
Procedure EditBuf(var Buf; Size: word);
Procedure ProcessEdit(TE: NENEditorPtr);
Procedure EditFileReadOnly(FileName: PathStr);
Procedure DisplayFile(Path: PathStr);
Procedure DisplayFileCustom(X1,Y1,X2,Y2: byte;Path: PathStr;
                            Title: TitleString;Cscheme: ColorSetProc);
procedure EditWindowStatus(MP : MemoPtr);
Procedure ChooseAndEditFile(Mask: PathStr;Wait: boolean);
Procedure EditSupportFiles;
Procedure EditSaveGetFiles;
Procedure SelectSaveGetFile(var SGFile: PathStr);
Function WhichSaveGetAreaToWrite: Char;
Function WhichSaveGetAreaToRead: Char;
Procedure ErrorProc(UnitCode: byte; var ErrorCode: word; ErrorMsg: String);
function YesNoProc(MsgCode : Word; Prompt : string;
                   Default : Byte; QuitAndAll : Boolean) : Byte;
procedure NilHelpProc(HelpIndex: word);

var
  HelpProc     : HelpProcType;

implementation

var
  DragCommands : DragProcessorPtr;

{$IFDEF NENEditorKeys}
const
  {Keystroke to command mapping}
  NENEditorKeyMax = 400;   {last available slot in EditorKeySet}
  {ID string for installation programs}
  NENEditorKeyID : string[18] = 'opeditor key array';
  {default key assignments}
  NENEditorKeySet : array[0..NENEditorKeyMax] of Byte = (
   {length keys         command type      key sequence}
    3,     $00, $3B,    ccHelp,          {F1}
    3,     $00, $3C,    ccBlkWrite,      {F2}
    3,     $00, $3D,    ccBlkBegin,      {F3}
    3,     $00, $3E,    ccBlkEnd,        {F4}
    3,     $00, $41,    ccSaveFile,      {F7}
    3,     $00, $47,    ccHome,          {Home}
    3,     $00, $48,    ccUp,            {Up}
    3,     $00, $49,    ccPageUp,        {PgUp}
    3,     $00, $4B,    ccLeft,          {Left}
    3,     $00, $4D,    ccRight,         {Right}
    3,     $00, $4F,    ccEnd,           {End}
    3,     $00, $50,    ccDown,          {Down}
    3,     $00, $51,    ccPageDn,        {PgDn}
    3,     $00, $52,    ccIns,           {Ins}
    3,     $00, $53,    ccDel,           {Del}
    3,     $00, $73,    ccWordLeft,      {^Left}
    3,     $00, $74,    ccWordRight,     {^Right}
    3,     $00, $75,    ccScreenBot,     {^End}
    3,     $00, $76,    ccEndOfFile,     {^PgDn}
    3,     $00, $77,    ccScreenTop,     {^Home}
    3,     $00, $84,    ccTopOfFile,     {^PgUp}
    2,     $01,         ccWordLeft,      {^A}
    2,     $02,         ccReformatP,     {^B}
    2,     $03,         ccPageDn,        {^C}
    2,     $04,         ccRight,         {^D}
    2,     $05,         ccUp,            {^E}
    2,     $06,         ccWordRight,     {^F}
    2,     $07,         ccDel,           {^G}
    2,     $08,         ccBack,          {^H, Bksp}
    2,     $09,         ccTab,           {^I, Tab}
    2,     $0C,         ccReSearch,      {^L}
    2,     $0D,         ccSelect,        {^M, Enter}
    2,     $0E,         ccInsertLine,    {^N}
    2,     $10,         ccCtrlChar,      {^P}
    2,     $12,         ccPageUp,        {^R}
    2,     $13,         ccLeft,          {^S}
    2,     $14,         ccDelWord,       {^T}
    2,     $16,         ccIns,           {^V}
    2,     $17,         ccScrollUp,      {^W}
    2,     $18,         ccDown,          {^X}
    2,     $19,         ccDelLine,       {^Y}
    2,     $1A,         ccScrollDn,      {^Z}
    2,     $7F,         ccBack,          {^Bksp}
    3,     $0A, $0C,    ccJmpLine,       {^J^L}
    3,     $0B, $02,    ccBlkBegin,      {^K^B}
    3,     $0B, $03,    ccBlkCopy,       {^K^C}
    3,     $0B, $04,    ccSaveSwitch,    {^K^D}
    3,     $0B, $07,    ccReformatG,     {^K^G}
    3,     $0B, $08,    ccBlkToggle,     {^K^H}
    3,     $0B, $09,    ccBlkIndent,     {^K^I}
    3,     $0B, $0B,    ccBlkEnd,        {^K^K}
    3,     $0B, $0D,    ccMarkToggle,    {^K^M}
    3,     $0B, $0E,    ccSaveNamed,     {^K^N}
    3,     $0B, $10,    ccBlkPrint,      {^K^P}
    3,     $0B, $11,    ccAbandonFile,   {^K^Q}
    3,     $0B, $12,    ccBlkRead,       {^K^R}
    3,     $0B, $13,    ccSaveFile,      {^K^S}
    3,     $0B, $14,    ccBlkWord,       {^K^T}
    3,     $0B, $15,    ccBlkUnindent,   {^K^U}
    3,     $0B, $16,    ccBlkMove,       {^K^V}
    3,     $0B, $17,    ccBlkWrite,      {^K^W}
    3,     $0B, $18,    ccSaveExit,      {^K^X}
    3,     $0B, $19,    ccBlkDelete,     {^K^Y}
    3,     $0B, $30,    ccSetMark0,      {^K0}
    3,     $0B, $31,    ccSetMark1,      {^K1}
    3,     $0B, $32,    ccSetMark2,      {^K2}
    3,     $0B, $33,    ccSetMark3,      {^K3}
    3,     $0F, $02,    ccSetIndent,     {^O^B}
    3,     $0F, $03,    ccCenterLine,    {^O^C}
    3,     $0F, $06,    ccTabToggle,     {^O^F}
    3,     $0F, $09,    ccIndent,        {^O^I}
    3,     $0F, $0F,    ccBlkTCase,      {^O^O}
    3,     $0F, $12,    ccRtMargin,      {^O^R}
    3,     $0F, $14,    ccTabSize,       {^O^T}
    3,     $0F, $15,    ccBlkUCase,      {^O^U}
    3,     $0F, $16,    ccBlkLCase,      {^O^V}
    3,     $0F, $17,    ccWordWrap,      {^O^W}
    3,     $11, $01,    ccReplace,       {^Q^A}
    3,     $11, $02,    ccJmpBegin,      {^Q^B}
    3,     $11, $03,    ccEndOfFile,     {^Q^C}
    3,     $11, $04,    ccEnd,           {^Q^D}
    3,     $11, $05,    ccScreenTop,     {^Q^E}
    3,     $11, $06,    ccSearch,        {^Q^F}
    3,     $11, $0B,    ccJmpEnd,        {^Q^K}
    3,     $11, $0C,    ccRestore,       {^Q^L}
    3,     $11, $10,    ccPrevPos,       {^Q^P}
    3,     $11, $12,    ccTopOfFile,     {^Q^R}
    3,     $11, $13,    ccHome,          {^Q^S}
    3,     $11, $18,    ccScreenBot,     {^Q^X}
    3,     $11, $19,    ccDelEol,        {^Q^Y}
    3,     $11, $30,    ccJmpMark0,      {^Q0}
    3,     $11, $31,    ccJmpMark1,      {^Q1}
    3,     $11, $32,    ccJmpMark2,      {^Q2}
    3,     $11, $33,    ccJmpMark3,      {^Q3}
  {$IFDEF UseMouse}
    3,     $00, $EF,    ccMouseSel,      {click left  = mouse select}
    3,     $00, $ED,    ccHelp,          {click both  = help}
  {$ELSE}
             0, 0, 0, 0, 0, 0, 0,        {360}
    0,                                   {370}
  {$ENDIF}
    {-----------pad to end of array----------}
       0, 0, 0, 0, 0, 0, 0, 0, 0,        {370}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,        {380}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,        {390}
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0);       {400}
{.F+}
{$ENDIF}

{------------------------------------------------------------------------}

Procedure DisplayFileCustom(X1,Y1,X2,Y2: byte;Path: PathStr;
                            Title: TitleString;Cscheme: ColorSetProc);
{var
  B : BrowserPtr;
  DCP : DragProcessorPtr;
  Status : Word;
  Finished : Boolean;}
begin
  EditFile(Path);
(*  CScheme;
  New(B,InitCustom(X1,Y1,X2,Y2,   {Coordinates}
                      NENColorSet,                   {ColorSet}
                      DefWindowOptions or wBordered, {Window options}
                      MaxAvail));                    {Max heap space to use}
  if B = nil
  then begin
    WriteLn('Failed to init Browser. Status = ', InitStatus);
    Exit;
  end;
  CustomizeWindow(B^,Title,Length(Title));

  {initialize DragProcessor}
  New(DCP,Init(@BrowseKeySet, BrowseKeyMax));
  CustomizeCommandProcessor(DCP^);
  B^.SetCommandProcessor(DCP^);

  B^.OpenFile(Path);

  Status := B^.GetLastError;
  if Status <> 0 then begin
    B^.Erase;
    Dispose(B,Done);
    Dispose(DCP,Done);
    exit;
  end;

  {use built-in status routine}
  OpBrowse.StatusRow := 25;
  OpBrowse.StatusColor := BlueOnLtGray;
  B^.SetStatusProc(BrowseStatus);
  SaveStatusLine;
  FastWrite('<CtrlH> Toggles HEX/ASCII',25,20,BlueOnLtGray);

  Finished := False;
  repeat
    B^.Process;
    case B^.GetLastCommand of
      ccMouseDown,
      ccMouseSel :
        {did user click on the hot spot for closing?}
        if HandleMousePress(B^) = hsRegion3 then begin
          ClearMouseEvents;
          Finished := True;
        end;
      ccQuit,ccDone, ccError: Finished := True;
      {...user exit commands...}
    end;
  until Finished;
  B^.Erase;
  Dispose(B,Done);
  Dispose(DCP, Done);
  RestoreStatusLine;  *)
end;

{------------------------------------------------------------------------}
Procedure DisplayFile(Path: PathStr);
  begin
    DisplayFileCustom(4, 5, ScreenWidth-5, ScreenHeight-4,Path,' View ',TextColors);
  end;

{------------------------------------------------------------------------}

function EditProc(MsgCode : Word;
                  Prompt : string;
                  ForceUp : Boolean;
                  TrimBlanks : Boolean;
                  MaxLen : Byte;
                  var S : string) : Boolean;
var
  FDB : DialogBoxPtr;
  DCP : DragProcessorPtr;
  Status : word;
  Pic : Char;

    function InitDialogBox : Word;
      {-Initialize dialog box}
    const
      WinOptions = wBordered+wClear+wUserContents;
    begin
       New(FDB,InitCustom(
          11, 9, 64, 15,   {top left corner (X,Y)}
          NENColorSet,     {main color set}
          WinOptions,      {window options}
          NENDialogSet     {dialog box-specific colors}
          ));
         if FDB = nil then begin
            InitDialogBox := InitStatus;
            Exit;
          end;
       CustomizeWindow(FDB^, '', 38);

       New(DCP,Init(@DialogKeySet, DialogKeyMax));
       CustomizeCommandProcessor(DCP^);
       FDB^.SetCommandProcessor(DCP^);

     InitDialogBox := FDB^.RawError;
    end;

    begin

      {select alternate scroll bar arrows}
      DefArrows := TriangleArrows;
      FileColors;

      {initialize dialog box}
      Status := InitDialogBox;
      if Status <> 0 then begin
        WriteLn('Error initializing dialog box: ', Status);
        Exit;
      end;

    FDB^.AddTextFieldCustom('Enter Text',2, 5,YellowOnBlue, $07);

    Pic := 'X';
    if ForceUp then Pic := '!';

    FDB^.AddSimpleEditControl(Prompt, 4,  5, Pic,
                                      4,  6+Length(Prompt),
                                      30-Length(Prompt), MaxLen,4, S);
    {set field/control options}
    FDB^.dgFieldOptionsOn(efClearFirstChar);

    FDB^.AddPushButton('&OK',       6,  5, 8, 0, ccSelect, True);
    FDB^.AddPushButton('&CANCEL ',  6, 20, 8, 0, ccQuit, False);


    FDB^.Process;
    Case FDB^.GetLastCommand of
      ccSelect :   EditProc := true;
      ccQuit   :   EditProc := False;
    else
      EditProc := True;
    end;

    Dispose(FDB,Done);
    if TrimBlanks then
      S := Trim(S);

  end;

{------------------------------------------------------------------------}

function YesNoProc(MsgCode : Word; Prompt : string;
                   Default : Byte; QuitAndAll : Boolean) : Byte;
var
  FDB : DialogBoxPtr;
  DCP : DragProcessorPtr;
  Status : word;

    function InitDialogBox : Word;
      {-Initialize dialog box}
    const
      WinOptions = wBordered+wClear+wUserContents;
    begin
       New(FDB,InitCustom(
          21, 9, 59, 15,   {top left corner (X,Y)}
          NENColorSet,     {main color set}
          WinOptions,      {window options}
          NENDialogSet     {dialog box-specific colors}
          ));
         if FDB = nil then begin
            InitDialogBox := InitStatus;
            Exit;
          end;
       CustomizeWindow(FDB^, 'Select ', 38);
       New(DCP,Init(@DialogKeySet, DialogKeyMax));
       CustomizeCommandProcessor(DCP^);
       FDB^.SetCommandProcessor(DCP^);

       InitDialogBox := FDB^.RawError;
    end;

    begin
      {select alternate scroll bar arrows}
      DefArrows := TriangleArrows;

      FileColors;
      {initialize dialog box}
      Status := InitDialogBox;
      if Status <> 0 then begin
        WriteLn('Error initializing dialog box: ', Status);
        exit;
      end;

    FDB^.AddCenteredTextField(Prompt,2);

    FDB^.AddPushButton('&Yes',  4,  5, 8, 0, 1, True);
    FDB^.AddPushButton('&No ',  4, 15, 8, 0, 2, False);
    FDB^.AddPushButton('&Quit ',4 ,25, 8, 0, 4, False);
    if QuitAndAll then
      FDB^.AddPushButton('&All ', 6 ,15, 8, 0, 3, False);

    FDB^.Process;
    Case FDB^.GetLastCommand of
      1 :   YesNoProc := teYES;
      2 :   YesNoProc := teNO;
      3 :   YesNoProc := teALL;
      4 :   YesNoProc := teQUIT;
      end;
    Dispose(FDB,Done);

  end;

{------------------------------------------------------------------------}

Procedure ErrorProc(UnitCode: byte; var ErrorCode: word; ErrorMsg: String);
var
  FDB : DialogBoxPtr;
  DCP : DragProcessorPtr;
  Status : word;

    function InitDialogBox : Word;
      {-Initialize dialog box}
    const
      WinOptions = wBordered+wClear+wUserContents;
    begin
       New(FDB,InitCustom(
          26, 9, 54, 13,   {top left corner (X,Y)}
          NENColorset,      {main color set}
          WinOptions,      {window options}
          NENDialogSet     {dialog box-specific colors}
          ));
         if FDB = nil then begin
            InitDialogBox := InitStatus;
            Exit;
          end;
       CustomizeWindow(FDB^, '', 5);
       New(DCP,Init(@DialogKeySet, DialogKeyMax));
       CustomizeCommandProcessor(DCP^);
       FDB^.SetCommandProcessor(DCP^);

       InitDialogBox := FDB^.RawError;
    end;

    begin
      {select alternate scroll bar arrows}
      DefArrows := TriangleArrows;

      ErrorColors;

      {initialize dialog box}
      Status := InitDialogBox;
      if Status <> 0 then begin
        WriteLn('Error initializing dialog box: ', Status);
        exit;
      end;

    if ErrorMsg = '' then
      FDB^.AddCenteredTextField('Error '+Long2Str(ErrorCode),2)
    else
      FDB^.AddCenteredTextField(ErrorMsg,2);

    FDB^.AddPushButton('&OK ',  4, 12, 8, 0, ccQuit, True);
    SHowMouse;

    FDB^.Process;
    Case FDB^.GetLastCommand of
      ccQuit : begin end;
      end;

    Dispose(FDB,Done);
    ShowMouse;

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
    with MP^ do begin
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
{      Pc := Trunc((meTotalBytes*100.0)/(meBufSize-2));}

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
          Case Pc of
            0..24   : ChangeAttribute(2,frYH,frXl+16,
                              (frFrameColor and $F) or Green      shl 4);
            25..49  : ChangeAttribute(2,frYH,frXl+16,
                              (frFrameColor and $F) or Brown      shl 4);
            50..74  : ChangeAttribute(2,frYH,frXl+16,
                              (frFrameColor and $F) or Yellow     shl 4);
            75..90  : ChangeAttribute(2,frYH,frXl+16,
                              (frFrameColor and $F) or Red        shl 4);
            91..100 : ChangeAttribute(2,frYH,frXl+16,
                              (frFrameColor and $F) or LightRed   shl 4);
            end;
        end;

      ShowMousePrim(SaveMouse);
    end;
  end;

procedure NilHelpProc(HelpIndex: word);
begin
end;

{------------------------------------------------------------------------}

Procedure CustomizeTextEditor(var TE: TextEditor);
  begin
    with TE do
      begin
        SetErrorProc(ErrorProc);
        SetGetFileProc(GetFileProc);
        SetYesNoProc(YesNoProc);
        SetEditProc(EditProc);
        SetStatusProc(EditWindowStatus);
        HelpProc := NilHelpProc;
        GetCommandProcessor^.AddCommand(ccBlkWrite, 1, AltC, 0);
        GetCommandProcessor^.AddCommand(ccBlkRead , 1, AltP, 0);
      end;
  end;

{------------------------------------------------------------------------}

Constructor NENEditor.OpenEditFileCustom(X1,Y1,X2,Y2: byte;Path: PathStr;
                                         Title: TitleString;
                                         Cscheme: ColorSetProc);
  var
    FSize : LongInt;
    Len   : word;
    AllDone : Boolean;
  begin
    {instantiate a TextEditor with a bordered window}
    Cscheme;
    if not InitCustom(x1,y1,x2,y2,                   {Window coordinates}
                      NENColorSet,                   {ColorSet}
                      DefWindowOptions or wBordered
                      or wAltFrame or wResizeable,   {Window options}
                      65521) then                    {Buffer size}
      begin
        WriteLn('Failed to init TextEditor. Status = ', InitStatus);
        exit;
      end;

    Explode := True;
    CustomizeWindow(Self,Title,Len);
    AddScrollBars(Self, True);

    SetErrorProc(ErrorProc);
    SetGetFileProc(GetFileProc);
    SetYesNoProc(YesNoProc);
    SetEditProc(EditProc);
    SetStatusProc(EditWindowStatus);
    HelpProc := NilHelpProc;

    if Title = '' then
      Title := ' Edit ';

    Len := 5;
    if Length(Title) > Len then Len := Length(Title);

    if FKeysUp then
      SetPosLimits(1,3,ScreenWidth, 22)
    else
      SetPosLimits(1,3,ScreenWidth, 24);

    StatWin := nil;
    FileEdit := True;

    {$IFDEF NENEditorKeys}
    New(ECP,Init(@NENEditorKeySet, NENEditorKeyMax));
    {$ELSE}
    New(ECP,Init(@EditorKeySet, EditorKeyMax));
    {$ENDIF}
    CustomizeCommandProcessor(ECP^);
    with ECP^ do
      begin
        AddCommand(ccUser0   ,     1,     OpKey.F10,   0);
        AddCommand(ccUser7   ,     1,     OpKey.F8,    0);
        AddCommand(ccBlkRead ,     1,     OpKey.AltF2, 0);
        AddCommand(ccAbandonFile,  1,     OpKey.Esc,   0);
      end;
    SetCommandProcessor(ECP^);


    {Create/read in a text file}
    ReadFile(Path, FSize);

  end;

{------------------------------------------------------------------------}

Constructor NENEditor.OpenEditBufCustom(X1,Y1,X2,Y2: byte;
                                        Title: TitleString;
                                        Cscheme: ColorSetProc;
                                        BufPtr : Pointer;
                                        Size : word);
  var
    FSize : LongInt;
    Len   : word;
    AllDone : Boolean;
  begin
    {instantiate a TextEditor with a bordered window}
    Cscheme;
    if not InitBufCustom(x1,y1,x2,y2,                   {Window coordinates}
                         NENColorSet,                   {ColorSet}
                         DefWindowOptions or wBordered
                         or wAltFrame or wResizeable,   {Window options}
                         Size,                          {Buffer size}
                         BufPtr) then                   {Buffer address}
      begin
        WriteLn('Failed to init TextEditor. Status = ', InitStatus);
        Exit;
      end;

    if Title = '' then
      Title := ' Edit ';

    Len := Length(Title);
    CustomizeWindow(Self,Title,Len);
    AddScrollBars(Self, True);

    SetErrorProc(ErrorProc);
    SetGetFileProc(GetFileProc);
    SetYesNoProc(YesNoProc);
    SetEditProc(EditProc);
    SetStatusProc(EditWindowStatus);
    HelpProc := NilHelpProc;

    Len := 5;
    if Length(Title) > Len then Len := Length(Title);

    if FKeysUp then
      SetPosLimits(1,3,ScreenWidth, 22)
    else
      SetPosLimits(1,3,ScreenWidth, 24);

    StatWin := nil;
    FileEdit := False;

    New(ECP,Init(@EditorKeySet, EditorKeyMax));
    CustomizeCommandProcessor(ECP^);
    with ECP^ do
      begin
        AddSecondaryCommand(ccUser0   ,     1,     OpKey.F10,   0);
        AddSecondaryCommand(ccUser7   ,     1,     OpKey.F8,    0);
        AddSecondaryCommand(ccUser6   ,     1,     OpKey.F6,    0);
        AddSecondaryCommand(ccAbandonFile,  1,     OpKey.Esc,   0);
      end;
    SetCommandProcessor(ECP^);

  end;

Procedure NENEditor.AddStatusLine(Line: word);
  var WinOpts: LongInt;
  begin
    WinOpts := wClear;
    New(StatWin,InitCustom( 1, Line, 80, Line, DefaultColorSet, WinOpts));
    StatWin^.Draw;
    StatWin^.wFastWrite(Center(SysMsg(1936),ScreenWidth),1, 1,RedOnCyan);
  end;

procedure NENEditor.RequestHelp(HelpIndex: word);
begin
  if @HelpProc <> @NilHelpProc then
    HelpProc(HelpIndex);
end;

Procedure ProcessEdit(TE: NENEditorPtr);
  var
    AllDone : Boolean;
    LocalChoice: word;
  begin
    AllDone := False;
    with TE^ do
      begin
        repeat
          TE^.Process;
          ExitCommand := TE^.GetLastCommand;
          case ExitCommand of
            ccMouseDown,
            ccMouseSel :
              {did user click on the hot spot for closing?}
              if HandleMousePress(TE^) = hsRegion3 then begin
                ClearMouseEvents;
                AllDone := True;
              end;
            ccSaveExit,            {Save and exit -- file already saved}
            ccError :              {Fatal error}
              AllDone := True;
            ccAbandonFile:         {Abandon file}
                       begin
                         if (TE^.teOptionsAreOn(meModified)) and
                            (not TE^.teOptionsAreOn(teReadOnly)) and
                            (FileEdit) then
                           if UserSaysYes(SysMsg(000986){'File modified, Save?'},EscapemeansNo) then
                             TE^.SaveFile;
                         AllDone := True;
                       end;
            {...user exit commands..}
             ccUser8 : begin
                         if GetLocalMenuCmd(TE^, LocalChoice) = ccSelect then;
                         EraseLocalMenu;
                         Case LocalChoice of
                             1 : AllDone := True;
                             2 : if KeyboardMove(TE^) Then;
                             3 : begin
                                   if KeyboardResize(TE^) then;
                                 end;
                             4 : begin
                                   if ToggleZoom(TE^) then;
                                 end;
                           end;
                       end;
            ccUser0..
            ccUser39 : if ExitCommand <> ccUser8 then exit;
            ccUser40 : if KeyboardMove(TE^) then;
            ccUser41 : if ToggleZoom(TE^) then;
            ccUser42 : if KeyboardResize(TE^) then;
          end;
        until AllDone;
        if IsActive then
          EraseHidden;
      end;
  end;

Destructor NENEditor.Done;
  begin
    if StatWin <> nil then
      begin
        StatWin^.Erase;
        Dispose(StatWin,Done);
        StatWin := nil;
      end;
    SetPosLimits(1,3,ScreenWidth, 24);
    Dispose(ECP,Done);
    TextEditor.Done;
  end;

Procedure EditFile(FileName: PathStr);
  var TE : NENEditorPtr;
  begin
    New(TE,OpenEditFileCustom(11, 8, ScreenWidth-11, ScreenHeight-6,FileName,
                              EditTitle,
                              TextColors));
    CustomizeWindow(TE^,EditTitle,10);
    with TE^ do
      begin
        AddStatusLine(25);
        ProcessEdit(TE);
      end;
    Dispose(TE,Done);
  end;

Procedure EditFileReadOnly(FileName: PathStr);
  var TE : NENEditorPtr;
  begin
    New(TE,OpenEditFileCustom(11, 8, ScreenWidth-11, ScreenHeight-6,FileName,
                              EditTitle,
                              TextColors));
    CustomizeWindow(TE^,EditTitle,10);
    with TE^ do
      begin
        teOptionsOn(teReadOnly);
        AddStatusLine(25);
        ProcessEdit(TE);
      end;
    Dispose(TE,Done);
  end;

Procedure EditBuf(var Buf; Size: word);
  var TE : NENEditorPtr;
  begin
    New(TE,OpenEditBufCustom(11, 8, ScreenWidth-11, ScreenHeight-6,
                              EditTitle,
                              TextColors,
                              @Buf, Size));
    CustomizeWindow(TE^,EditTitle,10);
    with TE^ do
      begin
        AddStatusLine(25);
        ProcessEdit(TE);
      end;
    Dispose(TE,Done);
  end;

Procedure ChooseAndEditFile(Mask: PathStr;Wait: boolean);
  var Path: PathStr;
  begin
    with UData^ do
      begin
        LastFilePath := Mask;
        WaitForFilePrompt := Wait;
        GetFileName(Mask,Path);
        WaitForFilePrompt := True;
        if Path <> '' then
          EditFile(Path);
      end;
  end;

Procedure EditSupportFiles;
  var I: integer;
  begin
    UGlobal.Menu^[1] := SysMsg(001039){'Read Rate Table'};
    UGlobal.Menu^[2] := SysMsg(001040){'Prefill Tables'};
    UGlobal.Menu^[3] := SysMsg(001041){'Dos File'};
    OpenMenu(28,8,63,18,UGlobal.Menu^,3,15,NoSort,'',SysMsg(000653){'Edit'},Yellow_Scheme,I);
    While not EscapePressed do
      begin
        Case GetMenu of
            1 : EditFile(NEN^.SysDir+'\TALENT.RR');
            2 : ChooseAndEditFile(NEN^.SysDir+'\*.PF',False);
            3 : ChooseAndEditFile(NEN^.SysDir+'\*.*',True);
          end;
      end;
    CloseWindow;
  end;

Procedure SelectSaveGetFile(var SGFile: PathStr);
  var I,DirSize: integer;
      Ext: String[3];
  begin
    BuildDirectory(NEN^.PrivateDir+'\GLOBAL.*',False,AnyFile,
                   UGlobal.Menu^,DirSize);
    BuildDirectory(NEN^.PrivateDir+'\'+Sys^.UsersName+'\Private\SAVEGET.*',False,AnyFile,
                   UGlobal.Menu^[DirSize+1],I);
    DirSize := DirSize+I;
    if DirSize = 0 then
      begin
        I := Dialog(SysMsg(001043){'No Save/Get Files'},SysMsg(001044){'Edit Save/Get'},LightRed,'Ok','','');
        exit;
      end;
    for I := 1 to DirSize do
      begin
        UGlobal.Menu^[I] := JustExtension(UGlobal.Menu^[I]);
      end;
    OpenMenu(15,8,62,12,UGlobal.Menu^,DirSize,3,Sort,'',SysMsg(001045){'Save/Get Areas'},Red_Scheme,I);
    I := GetMenu;
    if I <> 0 then
      begin
        GetMenuString(I,Ext);
        SGFile := NEN^.PrivateDir+'\'+Sys^.UsersName+'\Private\SaveGet.'+Ext;
      end;
    CloseWindow;
  end;

Procedure EditSaveGetFiles;
  var I,DirSize: integer;
      Ext: String[3];
  begin
    BuildDirectory(NEN^.PrivateDir+'\GLOBAL.*',False,AnyFile,
                   UGlobal.Menu^,DirSize);
    BuildDirectory(NEN^.PrivateDir+'\'+Sys^.UsersName+'\Private\SaveGet.*',False,AnyFile,
                   UGlobal.Menu^[DirSize+1],I);
    DirSize := DirSize+I;
    if DirSize = 0 then
      begin
        I := Dialog(SysMsg(001043){'No Save/Get Files'},SysMsg(001044){'Edit Save/Get'},LightRed,'Ok','','');
        exit;
      end;
    for I := 1 to DirSize do
      begin
        UGlobal.menu^[I] := JustExtension(UGlobal.Menu^[I]);
      end;
    OpenMenu(22,8,57,18,UGlobal.Menu^,DirSize,3,Sort,'',SysMsg(001045){'Save/Get Areas'},Yellow_Scheme,I);
    While not EscapePressed do
      begin
        I := GetMenu;
        if I <> 0 then
          begin
            GetMenuString(I,Ext);
            EditTitle := SysMsg(001046){'Save Area '}+Ext;
            EditFile(NEN^.PrivateDir+'\'+Sys^.UsersName+'\Private\SaveGet.'+Ext);
            EditTitle := ' Edit ';
          end
        else
          ForceEscape;
      end;
    CloseWindow;
  end;

Function WhichSaveGetAreaToWrite: Char;
  var I: integer;
  begin
    for I := 1 to 10 do
      UGlobal.Menu^[I] := Char(I+(Ord('0')-1));
    for I := 1 to 26 do
      UGlobal.Menu^[I+10] := Char(I+(Ord('A')-1));
    I := GetMenu;
    if I > 0 then
      begin
        if I < 11 then
          WhichSaveGetAreaToWrite := Char((Ord('0')-1)+I)
        else
          WhichSaveGetAreaToWrite := Char((Ord('A')-1)+(I-10))
      end
    else
      WhichSaveGetAreaToWrite := #0;
    CloseWindow;
  end;

Function WhichSaveGetAreaToRead: Char;
  var I: integer;
  begin
    SelectSaveGetFile(MsgString);
    MsgString := JustExtension(MsgString);
    WhichSaveGetAreaToRead := MsgString[1];
  end;

  Procedure TEditor.GetNextCommand;
    begin
      TextEditor.GetNextCommand;
      Case GetLastCommand of
        ccSearch,
        ccReplace : GetSearchOptions(Self);
        end;
    end;

end.
