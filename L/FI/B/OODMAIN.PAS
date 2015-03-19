{$I BTDEFINE.INC}
{$S-,R-,V-,I-,B-,F+,O+,A-}
{$I OPDEFINE.INC}

unit OODMain;
  {-Main unit for OODEMO}

interface

procedure Main;
  {-Run the application}

  {=======================================================================}

implementation

uses
  Dos,                       {Standard DOS unit}
  OpConst,   {!!.40}         {Error codes, etc.}
  OpRoot,                    {Low-level objects, error codes, etc.}
  OpInline,                  {Useful inline macros}
  OpString,                  {String handling}
  OpCrt,                     {Basic screen handling}
  {$IFDEF UseMouse}
  OpMouse,                   {Mouse support}
  {$ENDIF}
  OpCmd,                     {Command processing}
  OpFrame,                   {Window frames}
  OpWindow,                  {Windows}
  OpField,                   {Data entry fields}
  OpSelect,                  {Abstract selector}
  OpEntry,                   {Data entry screens}
  OpMemo,                    {Memo editor}
  OpKey,                     {Keystroke definitions, OPRO BONUS unit}
  {$IFDEF Novell}
  NWBase,                                             {!!.50}
  NWConn,                                             {!!.50}
  NWSema,                    {NetWare Semaphore unit} {!!.50}
  OopSema,                   {OOP Semaphore unit}
  {$ENDIF}
  Filer,                     {Fileblock handling}
  Reorg,                     {Fileblock reorganization}
  Rebuild,                   {Fileblock rebuilding}
  OoFiler,                   {Object-oriented layer around Filer}
  VRec,                      {Variable length records}
  VReorg,                    {Variable length reorganization}
  VRebuild,                  {Variable length rebuild}
  OoVrec,                    {Object-oriented layer around VRec}
  FBrowse;                   {Object-oriented filebrowser}

const
  FName          = 'ADDRESS';   {Root name for database}
  LstDevice      = 'PRN';       {Where printed output goes}
  SectionLength  = 140;         {Each record will use from 1 to 8 sections}
  MaxMemoSize    = 932;         {140*8 = 1120, (7*(140-7))+1 = 932}

  Header         : String[80] = {String used to build display header}
  ' OO Filer Demo Program                                                          ';
  Footer         : String[80] = {String for display footer}
  'F2-Add  F3-Del  F4-Find  F5-Key  F6-Filter  F8-Prn  F9-Info  F10-Purge  Esc-Quit';

type
  MemoField      = array[1..MaxMemoSize] of Char;

  PersonDef =                        {Definition of the database record}
    record
      Dele           : LongInt;
      FirstName      : String[15];
      Name           : String[15];
      Company        : String[25];
      Address        : String[25];
      City           : String[15];
      State          : String[2];
      Zip            : String[10];
      Telephone      : String[12];
      NotesLen       : Word;         {<-- 133 bytes to here}
      Notes          : MemoField;    {Memo field: 1..MaxMemoSize bytes}
    end;                             {1065 bytes maximum, 134 minimum}

  PersonMemoPtr = ^PersonMemo;
  PersonMemo =
    object(Memo)
      constructor Init(Buffer : Pointer; BufSize : Word);
        {-Initialize a PersonMemo editor}
      procedure meShowStatus; virtual;
        {-Display status line}
    end;

  PersonEntryPtr = ^PersonEntry;
  PersonEntry =
    object(EntryScreen)
      ScrapPerson : PersonDef;       {Scrap variable used for editing}
      PM          : MemoPtr;         {Memo field}

      constructor Init;
        {-Initialize a PersonEntry editor}
      destructor Done; virtual;
        {-Clean up}
      procedure esPreEdit; virtual;
        {-Pre-edit routine}

      {---- functions specific to a PersonEntry screen ----}
      procedure FixHeader(Header : String; RecNum : LongInt);
        {-Fix the entry screen's header}
      procedure DisplayPerson(Header : String; RecNum : LongInt);
        {-Show data about person}
      procedure EditMemoField;
        {-Edit the memo field}
      procedure EraseEditors;
        {-Erase entry screen and memo field}
      procedure EditScrapPerson(NameRequired : Boolean;
                                Header : String; RecNum : LongInt);
        {-Edit the entry field}
    end;

  PersonBrowserPtr = ^PersonBrowser;
  PersonBrowser =
    object(VBrowser)
      Filtering : Boolean;          {True when filtering is enabled}
      PersonFilter : PersonDef;     {Mask used for filtering}

      constructor Init(IFB : IsamFileBlockPtr;
                       KeyNr : Word;
                       var Person : PersonDef);
        {-Initialize a PersonBrowser}
      function IsFilteringEnabled : Boolean; virtual;
        {-Return True if filtering is enabled}
      procedure BuildOneRow(Row : Byte; var DatS; Len : Word; RecNum : LongInt;
                            Key : IsamKeyStr; var S : string); virtual;
        {-Convert specified row of specified item to a string}
      procedure ScreenUpdate; virtual;
        {-Called on each screen update; when current item/column changes}
      function RecordFilter(RecNum : LongInt; Key : IsamKeyStr) : Boolean; virtual;
        {-Return True if this record should be displayed}
    end;

  PersonFile =
    object(VFileblock)
      CurPerson      : PersonDef;        {Currently selected record}
      CurLen         : Word;             {Length of current record}
      CurRefNr       : LongInt;          {Record number currently selected}
      CurKeyNr       : Word;             {Active key number, 1 or 2}
      CurKeyStr      : IsamKeyStr;       {Active key string}
      ES             : PersonEntryPtr;   {Entry screen for the fileblock}
      VB             : PersonBrowserPtr; {Browser for the fileblock}
      ExitCmd        : Word;             {Last exit command from VB}

      constructor Init(FName : IsamFileBlockName);
        {-Initialize a PersonFile}
      destructor Done; virtual;
        {-Close up fileblock}

      {---- required implementations of abstract methods ----}
      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
        {-Return key string for given record and index number}
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
        {-Return True if two records are considered to be the same}
      function RecLen(var Rec) : Word; virtual;
        {-Return the length of a record in memory}

      {---- customize virtual methods ----}
      function LockError : Boolean; virtual;
        {-Called to test whether last operation failed because of lock error}
      procedure RebuildStatus(KeyNr : Word;
                              RecsRead, RecsWritten : LongInt;
                              var Rec; Len : Word); virtual;
        {-Called during rebuild for status reporting}

      {---- low-level functions specific to a PersonFile ----}
      function RetryAfterError : Boolean;
        {-Display error messages and return True to handle a Retry}
      procedure UpdateCurPerson(RefNr : LongInt);
        {-Update instance variables when current person changes}
      procedure IndicateDirty;
        {-Indicate fileblock changed via Novell semaphore}

      {---- high-level functions specific to a PersonFile ----}
      procedure Modify;
        {-Modify current record}
      procedure Add;
        {-Add a new record}
      procedure Delete;
        {-Delete current record}
      procedure Search;
        {-Search for a record}
      procedure SwitchKeys;
        {-Change browse order}
      procedure Filter;
        {-Set up a filter mask}
      procedure List;
        {-Print all records}
      procedure Status;
        {-Show fileblock status}
      procedure Purge;
        {-Rebuild the fileblock}
      {$IFDEF UseAdjustableWindows}
      procedure ResizeVB;
        {-Resize the browse window}
      procedure MoveVB;
        {-Move the browse window}
      procedure ZoomVB;
        {-Toggle zoom of the browse window}
      {$ENDIF}
      {$IFDEF UseMouse}
      procedure MouseCmd;
        {-Handle mouse hotspots}
      {$ENDIF}
      procedure Run;
        {-Browse, edit, add, modify, etc.}
    end;

const
  FbColors : ColorSet = (
    TextColor       : $1E; TextMono       : $07;
    CtrlColor       : $3E; CtrlMono       : $70;
    FrameColor      : $1F; FrameMono      : $0F;
    HeaderColor     : $3E; HeaderMono     : $70;
    ShadowColor     : $08; ShadowMono     : $70;
    HighlightColor  : $4E; HighlightMono  : $0F;
    PromptColor     : $1B; PromptMono     : $07;
    SelPromptColor  : $1B; SelPromptMono  : $07;
    ProPromptColor  : $1B; ProPromptMono  : $07;
    FieldColor      : $1E; FieldMono      : $07;
    SelFieldColor   : $3E; SelFieldMono   : $70;
    ProFieldColor   : $1E; ProFieldMono   : $07;
    ScrollBarColor  : $17; ScrollBarMono  : $07;
    SliderColor     : $17; SliderMono     : $07;
    HotSpotColor    : $71; HotSpotMono    : $07;
    BlockColor      : $0F; BlockMono      : $0F;
    MarkerColor     : $0F; MarkerMono     : $70;
    DelimColor      : $1B; DelimMono      : $07;
    SelDelimColor   : $1B; SelDelimMono   : $07;
    ProDelimColor   : $1B; ProDelimMono   : $07;
    SelItemColor    : $3E; SelItemMono    : $70;
    ProItemColor    : $1E; ProItemMono    : $07;
    HighItemColor   : $1F; HighItemMono   : $0F;
    AltItemColor    : $1F; AltItemMono    : $0F;
    AltSelItemColor : $3E; AltSelItemMono : $70;
    FlexAHelpColor  : $1F; FlexAHelpMono  : $0F;
    FlexBHelpColor  : $1F; FlexBHelpMono  : $0F;
    FlexCHelpColor  : $1B; FlexCHelpMono  : $70;
    UnselXrefColor  : $1E; UnselXrefMono  : $09;
    SelXrefColor    : $5F; SelXrefMono    : $70;
    MouseColor      : $4A; MouseMono      : $70
  );

  {Data entry stuff}
const
  {Field IDs}
  idFirstName    = 0;
  idLastName     = 1;
  idCompany      = 2;
  idAddress      = 3;
  idCity         = 4;
  idState        = 5;
  idZipCode      = 6;
  idPhone        = 7;
  idNotes        = 8;

var
  PF             : PersonFile;    {Fileblock object}
  HeadFootAttr   : Byte;          {Attribute for header/footer}
  SaveAttr       : Byte;          {Attribute of DOS screen}
  SaveMode       : Boolean;       {True for save mode}
  ValidationOff  : Boolean;       {True when entryscreen doesn't validate}
  ReqdNetType    : NetSupportType;{Requested network type}
  {$IFDEF Novell}
  MyServer       : TnwServer;       {Server for semaphores}
  Sync           : TFilerSemaphore; {Manage refresh function}
  {$ENDIF}

  {--------------------------------------------------------------------}

function Extend(S : String; Len : Byte) : String;
  {-Pad or truncate string to specified length}
var
  SLen : Byte absolute S;
begin
  if SLen >= Len then begin
    SLen := Len;
    Extend := S;
  end else
    Extend := Pad(S, Len);
end;

procedure WriteHeader(Prompt : String; ShowFilter : Boolean);
  {-Write header and bottom divider}
const
  FilterOn : array[Boolean] of string[8] = ('        ', '®Filter¯');
var
  S : String;
  I, J, L : Integer;
  {$IFDEF UseMouse}
  SaveMouse : Boolean;
  {$ENDIF}
begin
  {$IFDEF UseMouse}
  HideMousePrim(SaveMouse);
  {$ENDIF}

  {Draw header}
  S := Header;
  L := Length(Prompt);
  if L > ScreenWidth then
    L := ScreenWidth;
  J := 40-(L shr 1);
  for I := 1 to L do
    S[J+I] := Prompt[I];
  FastWrite(S, 1, 1, HeadFootAttr);

  {Indicate whether filtering is enabled}
  if ShowFilter then
    FastWrite(FilterOn[PF.VB^.IsFilteringEnabled], 1, 50, HeadFootAttr);

  {Display active key}
  if PF.CurKeyNr = 1 then
    S := ' Key: Last Name '
  else
    S := ' Key: Zip Code ';
  FastWrite(S, 1, 62, HeadFootAttr);

  {$IFDEF UseMouse}
  ShowMousePrim(SaveMouse);
  {$ENDIF}
end;

procedure WriteFooter(Prompt : String);
  {-Write a footer on the menu line}
{$IFDEF UseMouse}
var
  SaveMouse : Boolean;
{$ENDIF}
begin
  {$IFDEF UseMouse}
  HideMousePrim(SaveMouse);
  {$ENDIF}

  FastWrite(Extend(Prompt, ScreenWidth), ScreenHeight, 1, HeadFootAttr);
  GotoXYabs(Length(Prompt)+2, ScreenHeight);

  {$IFDEF UseMouse}
  ShowMousePrim(SaveMouse);
  {$ENDIF}
end;

function Menu(Selection, Prompt : String) : Char;
  {-Draw a bar menu and get a selection in the CharSet}
var
  ChWord : Word;
  Ch  : Char absolute ChWord;
  CursorSL, CursorXY : Word;
begin
  {Save the cursor position and shape}
  GetCursorState(CursorXY, CursorSL);
  NormalCursor;

  {Display prompt}
  WriteFooter(Prompt);

  {Flush keyboard buffer}
  while KeyPressed do
    Ch := ReadKey;

  {Wait for valid key}
  repeat
    ChWord := ReadKeyWord;
    Ch := Upcase(Ch);
  until Pos(Ch, Selection) <> 0;

  {Restore cursor position and shape}
  RestoreCursorState(CursorXY, CursorSL);

  {Clear prompt line}
  WriteFooter('');

  Menu := Ch;
end;

procedure DispMessage(Prompt : String; SoundBell : Boolean);
  {-Display a message on the menu line,
    waiting for keystroke and ringing bell}
var
  C  : Word;
begin
  if Prompt[Length(Prompt)] <> '.' then
    Prompt := Prompt+'.';
  WriteFooter(' '+Prompt+' Press any key...');
  if SoundBell then
    RingBell;
  C := ReadKeyWord;
end;

procedure IsamErrorNum(F : Integer);
  {-Display Isam error number and wait for key}
begin
  DispMessage('IsamError: '+Long2Str(F), True);
end;

function YesNo(Prompt : String; Default : Char) : Boolean;
  {-Display Yes/No prompt}
var
  Ch : Char;
begin
  Ch := Menu('YN'^M, Prompt+' ['+Default+']');
  if Ch = ^M then
    Ch := Default;
  YesNo := (Ch = 'Y');
end;

procedure DispMessageTemp(Prompt : String; Time : Word);
  {-Display a timed message}
begin
  WriteFooter(Prompt);
  Delay(Time);
  WriteFooter('');
end;

procedure Abort(Msg : String);
begin
  DispMessage(Msg, True);
  NormalCursor;
  TextAttr := SaveAttr;
  ClrScr;
  Halt(1);
end;

procedure InsufficientMemory;
  {-Abort the program with an out-of-memory error message}
begin
  Abort(emInsufficientMemory);
end;

procedure ClearPerson(var Person : PersonDef);
  {-Set up for a new person record}
begin
  FillChar(Person, SizeOf(PersonDef), 0);
  Person.NotesLen := 1;
  Person.Notes[1] := ^Z;
end;

function MatchString(var SG, ST : String) : Boolean;
  {-Return true if SG and ST match}
begin
  if Length(SG) = 0 then
    {Nothing to match against}
    MatchString := True
  else
    {Match if ST starts with SG}
    MatchString := (Pos(StUpCase(SG), StUpCase(ST)) = 1);
end;

function MatchPerson(var PG, PT : PersonDef) : Boolean;
begin
  MatchPerson := False;
  if PT.Dele <> 0 then
    Exit;
  if not MatchString(PG.FirstName, PT.FirstName) then
    Exit;
  if not MatchString(PG.Name, PT.Name) then
    Exit;
  if not MatchString(PG.Company, PT.Company) then
    Exit;
  if not MatchString(PG.Address, PT.Address) then
    Exit;
  if not MatchString(PG.City, PT.City) then
    Exit;
  if not MatchString(PG.State, PT.State) then
    Exit;
  if not MatchString(PG.Zip, PT.Zip) then
    Exit;
  if not MatchString(PG.Telephone, PT.Telephone) then
    Exit;
  MatchPerson := True;
end;

function PersonLine(var Person : PersonDef) : String;
  {-Return a string representing Person}
const
  HaveNotes : array[Boolean] of Char = (' ', #251);
begin
  with Person do
    PersonLine :=
      Extend(Zip, 5)+' '+
      Extend(Trim(Name)+', '+Trim(FirstName), 19)+' '+
      Extend(Company, 19)+' '+
      Extend(Address, 19)+' '+
      Extend(City, 13)+' '+
      Extend(State, 2)+' '+
      Extend(Telephone, 12)+' '+
      HaveNotes[NotesLen > 1];
end;

  {--------------------------------------------------------------------}

{$IFDEF Novell}
{$F+}
function SemaphoreRefresh(FBP : FBrowserPtr) : Boolean;
var
  Ticks : LongInt absolute $40:$6C;
  T : LongInt;
begin
  {assume false}
  SemaphoreRefresh := False;

  with FBP^ do
    {do nothing if this is a single-user fileblock}
    if LongFlagIsSet(fbOptions, fbIsNet) then begin
      {save tick count}
      T := Ticks;

      {loop while key not pressed}
      while not cwCmdPtr^.cpKeyPressed do
        {is it time to check again?}
        if (Ticks-T) >= RefreshPeriod then
          {check to see if page stack has been invalidated}
          if Sync.IsDirty(GetKeyNumber) then begin
            {we need to refresh the display}
            SemaphoreRefresh := True;
            Exit;
          end
          else
            {save the current tick count}
            T := Ticks;
    end;
end;
{$F-}
{$ENDIF}

{$F+}
procedure ErrorHandler(UnitCode : Byte; var ErrCode : Word; Msg : String);
  {-Display messages for errors reported by OPENTRY/OPMEMO/FBROWSE}
var
  P : Pointer;
begin
  {Try to save underlying text}
  if not SaveWindow(1, ScreenHeight, ScreenWidth, ScreenHeight, True, P) then begin
    RingBell;
    Exit;
  end;

  if Msg = '' then
    Msg := 'Unknown error: '+Long2Str(ErrCode);

  {Display the error message}
  if ErrCode = epFatal+ecIsamError then
    IsamErrorNum(IsamError)
  else
    DispMessage(Msg, True);

  {Restore underlying text}
  RestoreWindow(1, ScreenHeight, ScreenWidth, ScreenHeight, True, P);
end;
{$F-}

  {--------------------------------------------------------------------}

constructor PersonMemo.Init(Buffer : Pointer; BufSize : Word);
const
  Options        = wClear+wBordered;
  MemoXL         = 29;
  MemoYL         = 15;
  MemoXH         = 78;
  MemoYH         = 22;
begin
  {Deactivate <Esc>, use <^Enter> instead}
  MemoCommands.AddCommand(ccNone, 1, Ord(^[), 0);
  MemoCommands.AddCommand(ccQuit, 1, Ord(^J), 0);
  {$IFDEF UseMouse}
  MemoCommands.cpOptionsOn(cpEnableMouse);
  {$ENDIF}

  {.F-}
  {Initialize the memo}
  if not Memo.InitCustom(MemoXL,                {Left column of window}
                         MemoYL,                {Top row of window}
                         MemoXH,                {Right column of window}
                         MemoYH,                {Bottom row of window}
                         FbColors,              {Color set}
                         Options,               {Window options}
                         BufSize,               {Size of edit buffer}
                         Buffer)                {Edit buffer}
  then
    Fail;
  {.F+}

  {Set right margin}
  SetRightMargin(MemoXH-MemoXL);

  {Install error handler}
  SetErrorProc(ErrorHandler);

  {Add dummy header}
  wFrame.AddHeader(' Notes ', heTC);

  {Check for error}
  if GetLastError <> 0 then
    Fail;
end;

procedure PersonMemo.meShowStatus;
const
  StatusLine : String[48] =
  {         1         2         3         4        }
  {123456789012345678901234567890123456789012345678}
  ' Line: xxx Column: xxx 100%  Insert Indent Wrap ';
  InsertSt : array[Boolean] of String[6] = (' Over ', 'Insert');
  IndentSt : array[Boolean] of String[6] = ('      ', 'Indent');
  WrapSt   : array[Boolean] of String[4] = ('    ', 'Wrap');
var
  S  : String[5];
  {$IFDEF UseMouse}
  SaveMouse : Boolean;
  {$ENDIF}
begin
  if not IsCurrent or (VirtualSegment <> VideoSegment) then
    Exit;

  {Insert line number}
  S := Long2Str(meCurLine);
  S := Pad(S, 3);
  Move(S[1], StatusLine[8], 3);

  {Insert column number}
  S := Long2Str(meCurCol);
  S := Pad(S, 3);
  Move(S[1], StatusLine[20], 3);

  {Insert percentage of buffer used}
  S := Real2Str(Trunc((meTotalBytes*100.0)/(meBufSize-2)), 3, 0);
  Move(S[1], StatusLine[24], 3);

  {Plug in state stuff}
  Move(InsertSt[meOptionsAreOn(meInsert)][1], StatusLine[30], 6);
  Move(IndentSt[meOptionsAreOn(meIndent)][1], StatusLine[37], 6);
  Move(WrapSt[meOptionsAreOn(meWordWrap)][1], StatusLine[44], 4);

  {$IFDEF UseMouse}
  HideMousePrim(SaveMouse);
  {$ENDIF}

  {Display status line}
  FastWrite(
    StatusLine, wYH+1, wXL+1,
    ColorMono(FbColors.PromptColor, FbColors.PromptMono));

  {$IFDEF UseMouse}
  ShowMousePrim(SaveMouse);
  {$ENDIF}
end;

  {--------------------------------------------------------------------}

{$F+}
function ValidateState(EFP : EntryFieldPtr; var Err : Word;
                       var ErrSt : StringPtr) : Boolean;
  {-Validate a state entry}
const
  StateStrings   : array[1..51] of array[1..2] of Char = (
    'AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC', 'DE', 'FL', 'GA', 'HI',
    'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN',
    'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH',
    'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA',
    'WI', 'WV', 'WY');
  BadState : String[36] = 'Not a valid abbreviation for a state';
var
  I  : Word;
  S  : String[2];
begin
  ValidateState := True;

  S := Trim(EFP^.efEditSt^);
  if not ValidationOff then
    case Length(S) of
      1 :                  {No 1-character abbreviations}
        begin
          Err := ecPartialEntry;    {Standard error code}
          ErrSt := @emPartialEntry; {Standard error message}
          ValidateState := False;
        end;
      2 :                  {Check list of valid abbreviations}
        begin
          for I := 1 to 51 do
            if S = StateStrings[I] then
              Exit;
          Err := 1; {Arbitrary}
          ErrSt := @BadState;
          ValidateState := False;
        end;
    end;
end;

function ValidatePhone(EFP : EntryFieldPtr; var Err : Word;
                       var ErrSt : StringPtr) : Boolean;
  {-Validate a phone number}
const
  ValidPhone     : String[12] = 'ppp-uuu-uuuu';
begin
  if ValidationOff then
    ValidatePhone := True
  else
    ValidatePhone := ValidateSubfields(ValidPhone, EFP, Err, ErrSt);
end;

function ValidateZip(EFP : EntryFieldPtr; var Err : Word;
                     var ErrSt : StringPtr) : Boolean;
  {-Validate a zip code}
const
  ValidZip       : String[10] = 'uuuuu-pppp';
begin
  if ValidationOff then
    ValidateZip := True
  else
    ValidateZip := ValidateSubfields(ValidZip, EFP, Err, ErrSt);
end;

procedure PhoneZipConversion(EFP : EntryFieldPtr; PostEdit : Boolean);
  {-Conversion routine for phone numbers and zip codes.}
  {-Special note: This special conversion routine is needed to meet the
    demands of the Search routine, which allows searches based on partial
    zip codes and phone numbers. The ValidationOff flag used in the three
    validation routines shown above is needed for the same reason.}
var
  S : String[20];
  SLen : Byte absolute S;
  AllDone : Boolean;
begin
  with EFP^ do
    if PostEdit then begin
      S := efEditSt^;
      AllDone := False;
      repeat
        {Trim trailing blanks and hyphens}
        case S[SLen] of
          ' ', '-' :
            Dec(SLen);
          else
            AllDone := True;
        end;
      until AllDone;
      String(efVarPtr^) := S;
    end
    else begin
      {Is string too long? if so, truncate it}
      if Byte(efVarPtr^) > efMaxLen then
        Byte(efVarPtr^) := efMaxLen;

      {Initialize the edit string}
      efEditSt^ := String(efVarPtr^);

      {Merge picture mask characters if necessary}
      if Length(efEditSt^) < efMaxLen then
        MergePicture(efEditSt^, efEditSt^);
    end;
end;
{$F-}

constructor PersonEntry.Init;
const
  Options        = wClear+wBordered;
  NameMask       = 'xxxxxxxxxxxxxxx';
  CompanyMask    = 'xxxxxxxxxxxxxxxxxxxxxxxxx';
  NotesMsg       : string[1] = #14;
  PhoneMask      : String[12] = '999-999-9999';
  ZipMask        : String[10] = '99999-9999';
  EntryXL        = 29;
  EntryYL        = 04;
  EntryXH        = 78;
  EntryYH        = 12;
begin
  {$IFDEF UseMouse}
  EntryCommands.cpOptionsOn(cpEnableMouse);
  {$ENDIF}

  {.F-}
  {Initialize the entry screen}
  if not EntryScreen.InitCustom(EntryXL,          {Left column of window}
                                EntryYL,          {Top row of window}
                                EntryXH,          {Right column of window}
                                EntryYH,          {Bottom row of window}
                                FbColors,         {Color set}
                                Options)          {Window options}
  then
    Fail;

  {Add dummy header}
  wFrame.AddHeader(' dummy ', heTC);

  {Set field delimiters}
  SetDelimiters('[', ']');

  {Set entry screen options}
  SetWrapMode(WrapAtEdges);

  {Set field editing options}
  esFieldOptionsOn(efBeepOnError+efClearFirstChar);

  {Add each of the edit fields in order: left to right, top to bottom}
  {               Prompt               ---Field--- Help              }
  { Prompt        Row Col Picture      Row Col Len Index     Variable}

  AddStringField(
    'First name', 01, 05, NameMask,    01, 21, 15, 00, ScrapPerson.FirstName);
  AddStringField(
    'Last name',  02, 05, NameMask,    02, 21, 15, 01, ScrapPerson.Name);
  AddStringField(
    'Company',    03, 05, CompanyMask, 03, 21, 25, 02, ScrapPerson.Company);
  AddStringField(
    'Address',    04, 05, CompanyMask, 04, 21, 25, 03, ScrapPerson.Address);
  AddStringField(
    'City',       05, 05, NameMask,    05, 21, 15, 04, ScrapPerson.City);

  AddStringField(
    'State',      06, 05, 'AA',        06, 21, 02, 05, ScrapPerson.State);
  ChangeValidation(idState, ValidateState);

  AddStringField(
    'Zip',        07, 05, ZipMask,     07, 21, 10, 06, ScrapPerson.Zip);
  ChangeConversion(idZipCode, PhoneZipConversion);
  ChangeValidation(idZipCode, ValidateZip);

  AddStringField(
    'Telephone',  08, 05, PhoneMask,   08, 21, 12, 07, ScrapPerson.Telephone);
  ChangeConversion(idPhone, PhoneZipConversion);
  ChangeValidation(idPhone, ValidatePhone);

  esFieldOptionsOff(efMapCtrls);
  AddNestedStringField(
    'Notes',      09, 05, '',          09, 21, 01, 08, NotesMsg);
  {.F+}

  {Install error handler}
  SetErrorProc(ErrorHandler);

  {Check for error}
  if GetLastError <> 0 then
    Fail;

  {Clear the scrap record used for editing}
  ClearPerson(ScrapPerson);

  {Initialize the memo field}
  PM := New(PersonMemoPtr, Init(@ScrapPerson.Notes, SizeOf(MemoField)));
  if PM = nil then
    Fail;

  {Set global validation flag}
  ValidationOff := False;
end;

destructor PersonEntry.Done;
begin
  Dispose(PM, Done);
  EntryScreen.Done;
end;

procedure PersonEntry.esPreEdit;
var
  S : String[40];
begin
  case GetCurrentID of
    idFirstName : S := 'Enter first name';
    idLastName  : S := 'Enter last name';
    idCompany   : S := 'Enter company name';
    idAddress   : S := 'Enter street address';
    idCity      : S := 'Enter city of residence';
    idState     : S := 'Enter state of residence';
    idZipCode   : S := 'Enter a 5- or 9-digit zip code';
    idPhone     : S := 'Enter phone number';
    idNotes     : S := 'Press <Enter> to edit memo field';
  end;
  WriteFooter(' <^Enter> Done  <Esc> Abort  '+S);
end;

procedure PersonEntry.FixHeader(Header : String; RecNum : LongInt);
var
  Redraw : Boolean;
begin
  {Fix the header}
  if RecNum <> 0 then
    Header := Header+' Record # '+Long2Str(RecNum);
  wFrame.ChangeHeaderString(0, ' '+Header+' ', Redraw);
end;

procedure PersonEntry.DisplayPerson(Header : String; RecNum : LongInt);
begin
  FixHeader(Header, RecNum);
  Draw;
  if RecNum <> 0 then begin
    PM^.ReinitBuffer;
    ScrapPerson.NotesLen := PM^.meTotalBytes;
    PM^.Draw;
  end;
end;

procedure PersonEntry.EditMemoField;
begin
  WriteFooter(
    Center('Press <^Enter> when done editing notes to return to entry screen',
           ScreenWidth));

  {Do the editing}
  PM^.Select;
  PM^.Process;

  {Save the number of bytes in the buffer}
  ScrapPerson.NotesLen := PM^.meTotalBytes;

  Select;
end;

procedure PersonEntry.EraseEditors;
begin
  if IsCurrent then
    Erase;
  if PM^.IsCurrent then
    PM^.Erase;
  if IsCurrent then
    Erase;
end;

procedure PersonEntry.EditScrapPerson(NameRequired : Boolean;
                                      Header : String; RecNum : LongInt);
var
  Fini : Boolean;
begin
  {Need special validation?}
  ValidationOff := not NameRequired;

  {Set required status for last name}
  ChangeRequired(idLastName, NameRequired);

  {Hide Notes field if searching}
  ChangeHidden(idNotes, not NameRequired);

  {Change the entry screen's header}
  FixHeader(Header, RecNum);

  {Draw the memo window if not searching}
  if NameRequired then begin
    PM^.ReinitBuffer;
    ScrapPerson.NotesLen := PM^.meTotalBytes;
    PM^.Draw;
  end;

  {Start editing on first field}
  SetNextField(idFirstName);

  Fini := False;
  repeat
    {Start editing}
    Process;

    {See if we need to edit another record}
    case GetLastCommand of
      ccDone,              {^Enter, ^KD, or ^KQ}
      ccQuit :             {Esc}
        Fini := True;
      ccError :             {Fatal error}
        Abort('Fatal error in EntryScreen');
      ccNested :
        {Edit the notes field}
        if NameRequired then
          EditMemoField;
    end;
  until Fini;

  {Erase the two windows}
  EraseEditors;

  {Clear the prompt line}
  WriteFooter('');
end;

  {--------------------------------------------------------------------}

constructor PersonBrowser.Init(IFB : IsamFileBlockPtr;
                               KeyNr : Word;
                               var Person : PersonDef);
const
  RowsPerItem    = 1;        {Number of rows per browser item}
  MaxCols        = 101;      {Length of one row}
  {$IFDEF UseAdjustableWindows}
  Options = wClear+wBordered+wResizeable;
  {$ELSE}
  Options = wClear+wBordered;
  {$ENDIF}
begin
  {Add user-defined exit commands}
  with FBrowserCommands do begin
    AddCommand(ccUser2,  1, F2,   0); {Add record}
    AddCommand(ccUser3,  1, F3,   0); {Delete record}
    AddCommand(ccUser4,  1, F4,   0); {Search}
    AddCommand(ccUser5,  1, F5,   0); {Switch keys}
    AddCommand(ccUser6,  1, F6,   0); {Filter}
    AddCommand(ccUser8,  1, F8,   0); {Print records}
    AddCommand(ccUser9,  1, F9,   0); {Show status}
    AddCommand(ccUser10, 1, F10,  0); {Purge}
    {$IFDEF UseAdjustableWindows}
    AddCommand(ccUser11, 1, AltR, 0); {Resize window}
    AddCommand(ccUser12, 1, AltM, 0); {Move window}
    AddCommand(ccUser13, 1, AltZ, 0); {Zoom window}
    {$ENDIF}
    {$IFDEF UseMouse}
    FBrowserCommands.cpOptionsOn(cpEnableMouse);
    {$ENDIF}
  end;

  {Initialize the browser}
  if not VBrowser.InitCustom(3,              {Left column of window}
                             5,              {Top row of window}
                             {$IFDEF UseShadows}
                             ScreenWidth-3,  {Right column of window}
                             {$ELSE}
                             ScreenWidth-2,  {Right column of window}
                             {$ENDIF}
                             ScreenHeight-3, {Bottom row of window}
                             FbColors,       {Color set}
                             Options,        {Window options}
                             IFB,            {Fileblock}
                             KeyNr,          {Key number}
                             Person,         {Scrap variable}
                             ScreenHeight-5, {Maximum rows}
                             RowsPerItem,    {Rows per item}
                             MaxCols)        {Maximum columns}
  then
    Fail;

  {Not filtering initially}
  Filtering := False;

  {Adjust frame coordinates}
  {$IFDEF UseAdjustableWindows}
  {Set the limits to use when moving/zooming/resizing the window}
  SetPosLimits(1, 2, ScreenWidth, ScreenHeight-1);
  {$ENDIF}

  with wFrame do begin
    AdjustFrameCoords(frXL, frYL-1, frXH, frYH);

    {$IFDEF UseScrollBars}
    {Add scroll bars}
    AddCustomScrollBar(frBB, 0, MaxLongInt, 1, 1, #178, #176, fbColors);
    AddCustomScrollBar(frRR, 0, MaxLongInt, 1, 1, #178, #176, fbColors);
    {$ENDIF}

    {Add headers}
    AddCustomHeader(#181, frTL,  1, 0, $1F, $0F);       {1}
    AddCustomHeader(#7,   frTL,  2, 0, $71, $70);       {2}
    AddCustomHeader(#198, frTL,  3, 0, $1F, $0F);       {3}
    AddCustomHeader(#181, frTR, -3, 0, $1F, $0F);       {4}
    AddCustomHeader(#24,  frTR, -2, 0, $71, $70);       {5}
    AddCustomHeader(#198, frTR, -1, 0, $1F, $0F);       {6}
    AddCustomHeader('+',  frBR,  0, 0, $17, $07);       {7}

    {$IFDEF UseHotSpots}
    {Add hot spots}
    AddHotRegion(frTL, hsRegion0, 2, 0, 1, 1);          {Close}
    {$IFDEF UseAdjustableWindows}
    AddHotRegion(frTR, hsRegion1, -2, 0, 1, 1);         {Zoom}
    AddHotBar(frTT,    hsRegion2);                      {Move}
    AddHotRegion(frBR, hsRegion3, 0, 0, 1, 1);          {Resize}
    {$ENDIF}
    {$ENDIF}

    {$IFDEF UseShadows}
    AddShadow(shBR, shSeeThru);
    {$ENDIF}
  end;

  {Install error handler}
  SetErrorProc(ErrorHandler);

  {Options}
  fbOptionsOn(fbFlushKbd);

  if GetLastError <> 0 then
    Fail;

  {Set up automatic screen refresh}
  {$IFDEF Novell}
  if BTNetSupported = Novell then
    SetRefreshFunc(SemaphoreRefresh)
  else
    SetRefreshFunc(RefreshPeriodically);
  {$ELSE}
  SetRefreshFunc(RefreshPeriodically);
  {$ENDIF}
end;

function PersonBrowser.IsFilteringEnabled : Boolean;
begin
  IsFilteringEnabled := Filtering;
end;

procedure PersonBrowser.BuildOneRow(Row : Byte; var DatS; Len : Word;
                                    RecNum : LongInt;
                                    Key : IsamKeyStr; var S : string);
var
  P : PersonDef absolute DatS;
  SLen : Byte absolute S;
begin
  if Row > 1 then
    S := '----- row '+Long2Str(row)+' of record '+Long2Str(RecNum)
  else if RecNum <> -1 then
    S := PersonLine(P)
  else begin
    {Record is locked, indicate it on screen}
    S := '';
    while SLen < fbMaxCols do
      S := S+'**   ';
    SLen := fbMaxCols;
  end;
end;

procedure PersonBrowser.ScreenUpdate;
{
         1         2         3         4         5         6         7         8         9         1
1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
 Zip   Name                Company             Address             City         St  Phone       Notes
zzzzz nnnnnnnnnnnnnnnnnnn ccccccccccccccccccc aaaaaaaaaaaaaaaaaaa ccccccccccccc ss ppp-ppp-pppp n
}
const
  Header =
  ' Zip   Name                Company             Address             City         St  Phone       Notes';
begin
  {Write the header line now}
  fFastWrite(
    Extend(Copy(Header, GetCurrentCol, Width), Width), 1, 1,
    ColorMono(fbColors.HighlightColor, fbColors.HighlightMono));
end;

function PersonBrowser.RecordFilter(RecNum : LongInt;
                                    Key : IsamKeyStr) : Boolean;
  {-Return True if this record should be displayed}
var
  DatLen : Word;
  PersonTest : PersonDef;
begin
  if Filtering then begin
    GetRecord(RecNum, PersonTest, DatLen);
    RecordFilter := MatchPerson(PersonFilter, PersonTest);
  end else
    RecordFilter := True;
end;

  {--------------------------------------------------------------------}

constructor PersonFile.Init(FName : IsamFileBlockName);
  {-Initialize a PersonFile}
label
  ExitPoint;
var
  NetMode : Boolean;
  IID : IsamIndDescr;

  procedure InitIID;
  begin
    IID[1].KeyL := 30;
    IID[1].AllowDupK := False;
    IID[2].KeyL := 5;
    IID[2].AllowDupK := True;
  end;

begin
  InitStatus := 0;
  NetMode := (BTNetSupported <> NoNet);

  if VFileblock.Init(FName, False, False, SaveMode, NetMode) then
    {Opened existing file}
    goto ExitPoint;

  case IsamError of
     9903 : {Data file not found}
       begin
         InitIID;
         if VFileblock.Create(FName, SectionLength, 2, IID,
                              False, False, SaveMode, NetMode) then
           goto ExitPoint;
       end;

    10010 : {Fileblock corrupt}
      if YesNo('Index file defective. Rebuild it?', 'Y') then begin
        InitIID;
        if VFileblock.Recover(FName, SectionLength, 2, IID, True,
                              False, False, SaveMode, NetMode) then
          goto ExitPoint;
      end;

  else
    if YesNo('Error '+Long2Str(IsamError)+'. Attempt rebuild?', 'Y') then begin
      InitIID;
      if VFileblock.Recover(FName, SectionLength, 2, IID, True,
                            False, False, SaveMode, NetMode) then
        goto ExitPoint;
    end;
  end;

  {Couldn't open, create, or rebuild fileblock if we get here}
  InitStatus := epFatal+ecIsamError;
  Fail;

ExitPoint:
  AllocTempRec(SizeOf(PersonDef));
  if TempRecPtr = nil then
    Fail;

  {Initialize other fields of the PersonFile}
  CurRefNr := 0;
  CurKeyNr := 1;
  CurKeyStr := '';
  CurLen := 0;
  ExitCmd := ccNone;
  ClearPerson(CurPerson);

  ES := New(PersonEntryPtr, Init);
  if ES = nil then
    Fail;
  VB := New(PersonBrowserPtr, Init(IFB, CurKeyNr, CurPerson));
  if VB = nil then
    Fail;
end;

destructor PersonFile.Done;
  {-Close up fileblock}
begin
  Dispose(VB, Done);
  Dispose(ES, Done);
  VFileblock.Done;
end;

function PersonFile.BuildKey(var Rec; KeyNr : Word) : IsamKeyStr;
begin
  with PersonDef(Rec) do
    case KeyNr of
      1 : BuildKey := Extend(StUpCase(Trim(Name)),20)+
                      Extend(StUpCase(Trim(FirstName)),10);
      2 : BuildKey := Copy(Zip, 1, 5);
    end;
end;

function PersonFile.EqualRec(var Rec1, Rec2) : Boolean;
var
  P1 : PersonDef absolute Rec1;
  P2 : PersonDef absolute Rec2;
begin
  EqualRec := False;
  if P1.Dele <> P2.Dele then
    Exit;
  if P1.FirstName <> P2.FirstName then
    Exit;
  if P1.Name <> P2.Name then
    Exit;
  if P1.Company <> P2.Company then
    Exit;
  if P1.Address <> P2.Address then
    Exit;
  if P1.City <> P2.City then
    Exit;
  if P1.State <> P2.State then
    Exit;
  if P1.Zip <> P2.Zip then
    Exit;
  if P1.Telephone <> P2.Telephone then
    Exit;
  if P1.NotesLen <> P2.NotesLen then
    Exit;
  if CompStruct(P1.Notes, P2.Notes, P1.NotesLen) <> Equal then
    Exit;
  EqualRec := True;
end;

function PersonFile.RecLen(var Rec) : Word;
begin
  with PersonDef(Rec) do
    RecLen := SizeOf(PersonDef)-SizeOf(MemoField)+NotesLen;
end;

function PersonFile.LockError : Boolean;
var
  LE : Boolean;
begin
  LE := VFileblock.LockError;
  if (not IsamOK) and (IsamError = TooManyRetries) then
    if YesNo('A lock prevents access. Try again?', 'Y') then begin
      Tries := 0;
      LE := True;
    end;
  LockError := LE;
end;

procedure PersonFile.RebuildStatus(KeyNr : Word;
                                   RecsRead, RecsWritten : LongInt;
                                   var Rec; Len : Word);
var
  StatStr : String[80];

  function Long2StrDigits(L : LongInt; NumDigits : Byte) : String;
    {-Convert a longint to a string, right justified to NumDigits}
  var
    S : String;
  begin
    Str(L:NumDigits,S);
    Long2StrDigits := S;
  end;

begin
  StatStr := 'Working on key --> '+Long2StrDigits(KeyNr,1)+
             '   records read --> '+Long2StrDigits(RecsRead,6)+
             '   written --> '+Long2StrDigits(RecsWritten,6);
  WriteFooter(StatStr);
end;

function PersonFile.RetryAfterError : Boolean;
begin
  RetryAfterError := False;
  case IsamError of
    RecordModified :
      DispMessageTemp('The record has been changed by another station', 2000);
    RecordDeleted :
      DispMessageTemp('The record has been erased by another station', 2000);
    UndoError :
      Abort('Severe error while trying to undo modifications');
    10230 : {Duplicate key}
      if YesNo('The name already exists. Try again?', 'Y') then
        RetryAfterError := True;
  else
    IsamErrorNum(IsamError);
  end;
end;

procedure PersonFile.UpdateCurPerson(RefNr : LongInt);
begin
  CurRefNr := RefNr;
  CurPerson := ES^.ScrapPerson;
  CurKeyStr := BuildKey(CurPerson, CurKeyNr);
  VB^.SetCurrentRecord(CurKeyStr, CurRefNr);
  VB^.fbOptionsOn(fbForceUpdate);
end;

procedure PersonFile.IndicateDirty;
begin
  {$IFDEF Novell}
  if BTNetSupported = Novell then begin
    Sync.IndicateDirty(1);
    Sync.IndicateDirty(2);
  end;
  {$ENDIF}
end;

procedure PersonFile.Modify;
label
  Retry;
var
  Equal : Boolean;
begin
  WriteHeader(' Modify ', True);
Retry:
  {Edit the current person}
  ES^.ScrapPerson := CurPerson;
  ES^.EditScrapPerson(True, 'Modifying', CurRefNr);
  Equal := EqualRec(ES^.ScrapPerson, CurPerson);
  if (ES^.GetLastCommand <> ccDone) and not Equal then
    Equal := YesNo('Ignore changes to record?', 'N');
  if Equal then begin
    DispMessageTemp('Files not changed', 1000);
    Exit;
  end;

  {Modify the fileblock}
  IndicateDirty;
  ModifyRecord(CurRefNr, CurPerson, ES^.ScrapPerson);
  if not IsamOK then
    if RetryAfterError then
      goto Retry
    else
      Exit;

  {Update self for the modified person}
  UpdateCurPerson(CurRefNr);
end;

procedure PersonFile.Add;
label
  Retry;
var
  RefNr : LongInt;
  Empty : Boolean;
begin
  WriteHeader(' New Entry ', True);

  {Get a new person record}
  ClearPerson(CurPerson);
  ES^.ScrapPerson := CurPerson;
Retry:
  ES^.EditScrapPerson(True, 'Add Record', 0);
  Empty := EqualRec(ES^.ScrapPerson, CurPerson);
  if (ES^.GetLastCommand <> ccDone) and not Empty then
    Empty := YesNo('Ignore data entered?', 'N');
  if Empty then begin
    DispMessageTemp('Files not changed', 500);
    Exit;
  end;

  {Add record to the fileblock}
  IndicateDirty;
  AddRecord(RefNr, ES^.ScrapPerson);
  if not IsamOK then
    if RetryAfterError then
      goto Retry
    else
      Exit;

  {Update self for the modified person}
  UpdateCurPerson(RefNr);
end;

procedure PersonFile.Delete;
var
  Del : Boolean;
begin
  WriteHeader(' Deleting ', True);

  {Display the current person to confirm the deletion}
  ES^.ScrapPerson := CurPerson;
  ES^.DisplayPerson('Deleting', CurRefNr);
  Del := YesNo('Should the record really be deleted?', 'N');
  ES^.EraseEditors;
  if not Del then
    Exit;

  {Delete the record}
  IndicateDirty;
  DeleteRecord(CurRefNr, CurPerson);
  if not IsamOK then begin
    if RetryAfterError then ;
    Exit;
  end;

  {The browser will figure out who the new current person is}
  VB^.fbOptionsOn(fbForceUpdate);
end;

procedure PersonFile.Search;
var
  SKeyNr : Integer;
  RefNr : LongInt;
  Found : Boolean;
  KeyStr : IsamKeyStr;

  procedure NotFoundMessage;
  begin
    DispMessage('No matching record found', True);
  end;

begin
  WriteHeader(' Search ', True);

  {Get a search mask}
  ClearPerson(ES^.ScrapPerson);
  move(ES^.ScrapPerson, TempRecPtr^, SizeOf(PersonDef));
  ES^.EditScrapPerson(False, 'Search mask', 0);
  if (ES^.GetLastCommand <> ccDone) or EqualRec(ES^.ScrapPerson, TempRecPtr^) then
    Exit;

  WriteFooter('Searching... ');

  {Use indexed search if possible}
  if Length(ES^.ScrapPerson.Name) <> 0 then
    SKeyNr := 1
  else if Length(ES^.ScrapPerson.Zip) <> 0 then
    SKeyNr := 2
  else
    SKeyNr := 0;

  {Use a read lock to improve speed and reliability of the search}
  ReadLock;
  if not IsamOK then begin
    DispMessage('Unable to place read-lock', True);
    Exit;
  end;

  if SKeyNr <> 0 then begin
    {Position to closest key}
    KeyStr := BuildKey(ES^.ScrapPerson, SKeyNr);
    SearchKey(SKeyNr, RefNr, KeyStr);
    if not IsamOK then begin
      if IsamError = 10210 then
        NotFoundMessage
      else
        IsamErrorNum(IsamError);
      Unlock;
      Exit;
    end;
    {Get the corresponding record}
    GetRec(RefNr, TempRecPtr^);
    if not IsamOK then begin
      IsamErrorNum(IsamError);
      Unlock;
      Exit;
    end;
    {Position current fields near to goal in case rest of search fails}
    {UpdateCurPerson(RefNr);}                    {!!.24}
    CurRefNr := RefNr;                           {!!.24}
    CurPerson := PersonDef(TempRecPtr^);         {!!.24}
    CurKeyStr := BuildKey(CurPerson, CurKeyNr);  {!!.24}

    {Does it match the goal?}
    Found := MatchPerson(ES^.ScrapPerson, PersonDef(TempRecPtr^));
    if Found and VB^.Filtering then
      Found := MatchPerson(VB^.PersonFilter, PersonDef(TempRecPtr^));
  end else begin
    {Start sequential search at the current record}
    FindKeyAndRef(CurKeyNr, CurRefNr, CurKeyStr, 0);
    if not IsamOK then begin
      IsamErrorNum(IsamError);
      Unlock;
      Exit;
    end;
    Found := False;
  end;

  if not Found then begin
    {Sequential search in index order, starting one beyond current position}
    if SKeyNr = 0 then
      SKeyNr := CurKeyNr;
    repeat
      {Move to the next key}
      NextKey(SKeyNr, RefNr, KeyStr);
      if not IsamOK then begin
        if IsamError = 10250 then
          {Loop around to first key}
          NextKey(SKeyNr, RefNr, KeyStr);
        if not IsamOK then begin
          IsamErrorNum(IsamError);
          Unlock;
          Exit;
        end;
      end;
      {Get the corresponding record}
      GetRec(RefNr, TempRecPtr^);
      if not IsamOK then begin
        IsamErrorNum(IsamError);
        Unlock;
        Exit;
      end;
      Found := MatchPerson(ES^.ScrapPerson, PersonDef(TempRecPtr^));
      if Found and VB^.Filtering then
        Found := MatchPerson(VB^.PersonFilter, PersonDef(TempRecPtr^));
    until Found or (RefNr = CurRefNr);
  end;

  Unlock;

  if Found then begin
    ES^.ScrapPerson := PersonDef(TempRecPtr^);   {!!.24}
    UpdateCurPerson(RefNr);
  end else begin                                 {!!.24}
    VB^.SetCurrentRecord(CurKeyStr, CurRefNr);   {!!.24}
    NotFoundMessage;
  end;                                           {!!.24}
end;

procedure PersonFile.SwitchKeys;
begin
  CurKeyNr := (CurKeyNr and 1)+1;
  CurKeyStr := BuildKey(CurPerson, CurKeyNr);
  VB^.SetKeyNumber(CurKeyNr);
  VB^.SetCurrentRecord(CurKeyStr, CurRefNr);
end;

procedure PersonFile.Filter;
begin
  WriteHeader(' Filtering Info ', True);

  {Cancel existing filter}
  VB^.Filtering := False;
  ClearPerson(VB^.PersonFilter);
  VB^.fbOptionsOn(fbForceUpdate);

  {Get a filter mask}
  ClearPerson(ES^.ScrapPerson);
  ES^.EditScrapPerson(False, 'Filter mask', 0);
  if (ES^.GetLastCommand <> ccDone) or
     EqualRec(ES^.ScrapPerson, VB^.PersonFilter) then
    Exit;

  {Confirm filtering}
  if YesNo('Enable filtering with this information?', 'Y') then begin
    VB^.Filtering := True;
    VB^.PersonFilter := ES^.ScrapPerson;
  end;
end;

procedure PersonFile.List;
var
  RefNr : LongInt;
  KeyNr : Word;
  Ch : Char;
  OK : Boolean;
  KeyStr : IsamKeyStr;
  S : String;
  SLen  : Byte absolute S;
  Lst : Text;

  function Aborting : Boolean;
    {-Check for a keypress during printing, and offer a chance to quit}
  var
    C  : Char;
  begin
    Aborting := False;
    if KeyPressed then begin
      repeat
        C := ReadKey;
      until not KeyPressed;
      if YesNo('Do you really wish to quit?', 'N') then
        Aborting := True;
    end;
  end;

begin
  WriteHeader(' List ', True);

  {Assure there are records to print}
  RefNr := UsedRecs;
  if not IsamOK or (RefNr = 0) then begin
    DispMessage('No records available', True);
    Exit;
  end;

  {See what order to print in -- provide chance to abort}
  Ch := Menu('NZA', 'Sort by  N)ame Z)ipcode A)bort');
  case Ch of
    'N' : KeyNr := 1;
    'Z' : KeyNr := 2;
    'A' : Exit;
  end;

  {Open the printer}
  Assign(Lst, LstDevice);
  Rewrite(Lst);
  if IoResult <> 0 then begin
    DispMessage('Error attempting to write to '+LstDevice, True);
    Exit;
  end;
  WriteFooter('Press any key to abort print ');

  {Don't let anyone modify the fileblock while printing}
  ReadLock;
  if not IsamOK then begin
    DispMessage('Unable to place read-lock', True);
    Exit;
  end;

  {Position over first record}
  ClearKey(KeyNr);
  if not IsamOK then begin
    IsamErrorNum(IsamError);
    Unlock;
    Exit;
  end;

  repeat
    {Move to the next key}
    NextKey(KeyNr, RefNr, KeyStr);
    OK := IsamOK;
    if OK then begin
      {Get the corresponding record}
      GetRec(RefNr, TempRecPtr^);
      OK := IsamOK;
      if OK then begin
        {Format for printing}
        S := PersonLine(PersonDef(TempRecPtr^));
        if S[SLen] = #251 then
          Dec(SLen);
        while S[SLen] = ' ' do
          Dec(SLen);
        {Print record}
        WriteLn(Lst, S);
        OK := (IoResult = 0);
        if OK then
          OK := not Aborting
        else
          DispMessage('Printer error', True);
      end;
    end;
  until not OK;

  Unlock;
end;

procedure PersonFile.Status;
const
  ModeSt : array[Boolean] of string[6] = ('Normal', 'Save');
var
  F, U, K : LongInt;
  OK : Boolean;
begin
  WriteHeader(' Status ', True);

  U := UsedRecs;
  OK := IsamOK;
  if OK then begin
    F := FreeRecs;
    OK := OK and IsamOK;
    if OK then begin
      K := UsedKeys(1);
      OK := OK and IsamOK;
    end;
  end;
  if not OK then begin
    IsamErrorNum(IsamError);
    Exit;
  end;

  DispMessage(
    'Records:'+Long2Str(K)+
    ', Sections:'+Long2Str(U)+
    ', Deleted:'+Long2Str(F)+
    ', Mode:'+ModeSt[SaveMode]+
    {$IFDEF Btree54}                                   {!!.40}
    ', Station:'+Long2Str(BTGetInternalDialogID(IFB)), {!!.40}
    {$ELSE}                                            {!!.40}
    ', Station:'+Long2Str(IsamWSNr),                   {!!.40}
    {$ENDIF}                                           {!!.40}
    False);
end;

procedure PersonFile.Purge;
begin
  WriteHeader(' Rebuild ', True);
  WriteFooter('Please wait... ');

  Rebuild;
  if not IsamOK then begin
    DispMessage('Unable to rebuild data and index', True);
    Halt;
  end;

  {The fileblock pointer may have changed since it was closed and reopened}
  VB^.SetFileBlockPtr(IFB);

  {Reset to the top of the fileblock}
  ClearPerson(CurPerson);
  CurLen := 0;
  CurRefNr := 0;
  CurKeyStr := '';
  VB^.SetCurrentRecord(CurKeyStr, CurRefNr);
end;

{$IFDEF UseAdjustableWindows}
procedure PersonFile.ResizeVB;
const
  Step = 1;
var
  Finished : Boolean;
begin
  if VB^.IsZoomed then
    Exit;
  WriteFooter(' Use cursor keys to resize, <Enter> to accept');
  Finished := False;
  with VB^ do
    repeat
      case ReadKeyWord of
        Home  : ResizeWindow(-Step, -Step);
        Up    : ResizeWindow(0, -Step);
        PgUp  : ResizeWindow(Step, -Step);
        Left  : ResizeWindow(-Step, 0);
        Right : ResizeWindow(Step, 0);
        EndKey: ResizeWindow(-Step, Step);
        Down  : ResizeWindow(0, Step);
        PgDn  : ResizeWindow(Step, Step);
        Enter : Finished := True;
      end;
      if ClassifyError(GetLastError) = etFatal then
        InsufficientMemory;
    until Finished;

  WriteFooter('');
end;

procedure PersonFile.MoveVB;
const
  Step = 1;
var
  Finished : Boolean;
begin
  if VB^.IsZoomed then
    Exit;
  WriteFooter(' Use cursor keys to move, <Enter> to accept');
  Finished := False;
  with VB^ do
    repeat
      case ReadKeyWord of
        Home  : MoveWindow(-Step, -Step);
        Up    : MoveWindow(0, -Step);
        PgUp  : MoveWindow(Step, -Step);
        Left  : MoveWindow(-Step, 0);
        Right : MoveWindow(Step, 0);
        EndKey: MoveWindow(-Step, Step);
        Down  : MoveWindow(0, Step);
        PgDn  : MoveWindow(Step, Step);
        Enter : Finished := True;
      end;
      if ClassifyError(GetLastError) = etFatal then
        InsufficientMemory;
    until Finished;

  WriteFooter('');
end;

procedure PersonFile.ZoomVB;
begin
  if VB^.IsZoomed then
    VB^.Unzoom
  else
    VB^.Zoom;
  if VB^.ClassifyError(VB^.GetLastError) = etFatal then
    InsufficientMemory;
end;
{$ENDIF}

{$IFDEF UseMouse}
procedure PersonFile.MouseCmd;
var
  FP : FramePosType;
  HC : Byte;
  BP : LongInt;
  XAbs : Byte;
  YAbs : Byte;

  {$IFDEF UseAdjustableWindows}
  function Delta(I : Integer) : Integer;
  begin
    if I < -4 then
      Delta := -1
    else if I > 4 then
      Delta := 1
    else
      Delta := 0;
  end;

  procedure MoveResize(MoveIt : Boolean; Prompt : String);
  var
    MicH : Integer;
    MicV : Integer;
    Clicked : Boolean;
  begin
    if not VB^.IsZoomed then begin
      WriteFooter(Prompt);
      HideMouse;
      Dec(XAbs, VB^.wFrame.frXL);
      Dec(YAbs, VB^.wFrame.frYL);
      GetMickeyCount(MicH, MicV);
      repeat
        GetMickeyCount(MicH, MicV);
        if MoveIt then
          VB^.MoveWindow(Delta(MicH), Delta(MicV))
        else
          VB^.ResizeWindow(Delta(MicH), Delta(MicV));
        if VB^.ClassifyError(VB^.GetLastError) = etFatal then
          InsufficientMemory;
        if MousePressed then
          Clicked := (MouseKeyWord = MouseLft)
        else
          Clicked := False;
      until Clicked;
      Inc(XAbs, VB^.wFrame.frXL);
      Inc(YAbs, VB^.wFrame.frYL);
      if MoveIt then
        MouseGoToXY(XAbs, YAbs)
      else
        MouseGoToXY(VB^.wFrame.frXH, VB^.wFrame.frYH);
      WriteFooter('');
      ShowMouse;
    end;
  end;
  {$ENDIF}

begin
  XAbs := MouseLastX+MouseXLo;
  YAbs := MouseLastY+MouseYLo;
  VB^.EvaluatePos(XAbs, YAbs);
  BP := VB^.PosResults(FP, HC);
  if FP <> frOutsideFrame then
    case HC of
      hsRegion0 : {Close}
        ExitCmd := ccQuit;
      {$IFDEF UseAdjustableWindows}
      hsRegion1 : {Zoom}
        ZoomVB;
      hsRegion2 : {Move}
        MoveResize(True,
                   ' Drag window to new location, then click left mouse button');
      hsRegion3 : {Resize}
        MoveResize(False,
                   ' Move mouse to resize window, then click left mouse button');
      {$ENDIF}
    end;
end;
{$ENDIF}

procedure PersonFile.Run;
begin
  repeat
    if UsedRecs = 0 then begin
      {There must be at least one record to browse}
      if YesNo('There are no records. Add one?', 'Y') then
        ExitCmd := ccUser2
      else
        ExitCmd := ccQuit;

    end else begin
      {Update the screen and browse around the records}
      WriteHeader(' Main Menu ', True);
      WriteFooter(Footer);

      {Process commands}
      VB^.Process;
      ExitCmd := VB^.GetLastCommand;
      WriteFooter('');

      {Check for errors}
      case VB^.GetLastError of
        0 : {No error in browser}
          if (ExitCmd <> ccQuit) and (ExitCmd <> ccError) then begin
            {Get current key and reference}
            VB^.GetCurrentKeyAndRef(CurKeyStr, CurRefNr);

            {CurPerson already contains current record on ccSelect}
            if ExitCmd <> ccSelect then
              {Get current record}
              VB^.GetCurrentRecord(PF.CurPerson, PF.CurLen);

            {Check for error}
            if not IsamOK then begin
              IsamErrorNum(IsamError);
              ExitCmd := ccNone;
            end;
          end;

        epFatal+ecNoKeysFound : {Filtering was too strict}
          begin
            if VB^.IsFilteringEnabled then begin
              VB^.Filtering := False;
              ExitCmd := ccNone;
            end;
            VB^.ClearErrors;
          end;

      else
        DispMessage('Browser error. Aborting', True);
        ExitCmd := ccError;
      end;
    end;

    {Handle requests for action}
    case ExitCmd of
      ccSelect : Modify;
      ccUser2  : Add;
      ccUser3  : Delete;
      ccUser4  : Search;
      ccUser5  : SwitchKeys;
      ccUser6  : Filter;
      ccUser8  : List;
      ccUser9  : Status;
      ccUser10 : Purge;
      {$IFDEF UseAdjustableWindows}
      ccUser11 : ResizeVB;
      ccUser12 : MoveVB;
      ccUser13 : ZoomVB;
      {$ENDIF}
      {$IFDEF UseMouse}
      ccMouseSel : MouseCmd;
      {$ENDIF}
      ccQuit   : if not YesNo('Quit program?', 'N') then
                   ExitCmd := ccNone;
    end;
  until (ExitCmd = ccQuit) or (ExitCmd = ccError);
end;

  {--------------------------------------------------------------------}

procedure GetOptionsFromCommandLine;
  {-Get the network type (and station number if necessary) from Command line}
var
  Opt : ComStr;

  procedure ShowHelp;
    {-Display help message and halt}
  begin
    WriteLn('Usage: OODEMO /opt');
    WriteLn;
    WriteLn('where opt is:');
    {$IFNDEF Btree54}
    WriteLn('  /B     - MS-Net compatible with NetBIOS machine name support');
    WriteLn('  /C     - CBIS Network-OS');
    {$ENDIF}
    WriteLn('  /D     - Single-user DOS, no network');
    {$IFDEF Btree54}
    WriteLn('  /M     - MS-Net compatible');
    {$ELSE}
    WriteLn('  /M wn  - MS-Net compatible. wn is the workstation number');
    {$ENDIF}
    WriteLn('  /N     - Novell Advanced NetWare');
    {$IFNDEF Btree54}
    WriteLn('  /P     - Software Link PC-MOS/386');
    WriteLn('  /Q     - DesqView with SHARE');
    WriteLn('  /V     - Banyan Vines');
    WriteLn('  /X     - Alloy NTNX');
    {$ENDIF}
    Halt;
  end;

  procedure InvalidOption;
    {-Display invalid option message, show help, and halt}
  begin
    WriteLn('Invalid Option: ',Opt);
    WriteLn;
    ShowHelp;
  end;

begin
  {$IFDEF NoNet}
  ReqdNetType := NoNet;

  {$ELSE}
  if ParamCount = 0 then
    {Show help and halt}
    ShowHelp;
  Opt := ParamStr(1);
  if Length(Opt) <> 2 then
    InvalidOption;
  case UpCase(Opt[2]) of
    '?' : ShowHelp;
    {$IFNDEF Btree54}
    'B' : ReqdNetType := MsNetMachName;
    'C' : ReqdNetType := CBISNet;
    'P' : ReqdNetType := PCMos386;
    'Q' : ReqdNetType := DesqView;
    'V' : ReqdNetType := VinesNet;
    'X' : ReqdNetType := NTNXNet;
    {$ENDIF}
    'D' : ReqdNetType := NoNet;
    'M' : ReqdNetType := MsNet;
    'N' : ReqdNetType := Novell;
  else
    InvalidOption;
  end;

  {$IFNDEF Btree54}
  {Get the workstation number}
  case ReqdNetType of
    NoNet, Novell, MsNetMachName, CBISNet, NTNXNet, VinesNet, DesqView :
      {Automatically determine the workstation number or don't need one} ;

    {PCMOS386 also automatically determines the workstation number}
    PcMos386 :
      if not BTSetDosRetry(1, 1) then begin
        WriteLn('Error setting DOS retry');
        Halt;
      end;
  else
    if ParamCount <> 2 then begin
      WriteLn('The /M option requires a workstation number, e.g., OODEMO /M 2');
      Halt;
    end;
    if not Str2Word(ParamStr(2), IsamWSNr) then begin
      WriteLn('The workstation number must be an integer');
      Halt;
    end;
    if (IsamWSNr < 1) or (IsamWSNr > MaxNrOfWorkStations) then begin
      WriteLn('Workstation number must be in range 1..', MaxNrOfWorkStations);
      Halt;
    end;
  end;
  {$ENDIF}
  {$ENDIF}
end;

procedure Initialize;
var               {!!.40}
  Free : LongInt; {!!.40}
begin
  {Get network type from command line}
  GetOptionsFromCommandLine;

  {Initialize CRT}
  CheckBreak := False;
  SaveAttr := TextAttr;
  TextChar := #178;
  TextAttr := $07;
  HeadFootAttr := ColorMono(FbColors.FrameColor, FbColors.FrameMono);
  ClrScr;
  WriteHeader(' Initializing ', False);

  {Initialize Filer}
  {Limit the number of index buffers}          {!!.40}
  Free := 50000+(400*ScreenHeight);            {!!.40}
  if MemAvail-Free > 200000 then               {!!.40}
    Free := MemAvail-200000;                   {!!.40}
  if BTInitIsam(ReqdNetType, Free, 0) = 0 then {!!.40}
    {Error returned in IsamError} ;
  if not IsamOK then
    Abort('Fatal error '+Long2Str(IsamError)+' initializing Filer');
  SaveMode := YesNo('Should the files be handled using Save mode?', 'N');

  {Initialize variable record buffer} {!!.50 moved here}
  if not BTSetVariableRecBuffer(SectionLength) then
    InsufficientMemory;

  {$IFDEF Novell}
  {Initialize synchronization semaphore for Novell}
  if BTNetSupported = Novell then begin                  {!!.50}
    MyServer := nwDefaultServer;                         {!!.50}
    if Sync.Init(MyServer, FName, 2) then
      RefreshPeriod := 9            {check every half of a second}
    else
      Abort('Error initializing semaphore object. Aborting');
  end;                                                   {!!.50}
  {$ENDIF}

  {Initialize PersonFile}
  if not PF.Init(FName) then
    if InitStatus = epFatal+ecIsamError then
      Abort('Unable to open fileblock')
    else
      InsufficientMemory;

  {$IFDEF UseMouse}
  if MouseInstalled then begin
    {Use a red diamond for our mouse cursor}
    SoftMouseCursor($0000, (ColorMono(fbColors.MouseColor,
                                      fbColors.MouseMono) shl 8)+$04);
    ShowMouse;
  end;
  {$ENDIF}
end;

procedure Cleanup;
begin
  {Close the fileblock and deallocate its editors}
  PF.Done;
  if not IsamOK then
    DispMessage('Data may be corrupt', True);

  {Shut down B-Tree Filer}
  BTExitIsam;
  BTReleaseVariableRecBuffer;

  {$IFDEF UseMouse}
  HideMouse;
  {$ENDIF}

   TextAttr := SaveAttr;
  ClrScr;
end;

procedure Main;
begin
  Initialize;
  PF.Run;
  Cleanup;
end;

end.
