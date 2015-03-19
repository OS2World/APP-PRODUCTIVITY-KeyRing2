{$I-,V-,S-,R-,F-,B-}

{*********************************************************}
{*                   FBDMAIN.PAS 5.50                    *}
{*     Copyright (c) TurboPower Software 1990, 1994.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I BTDEFINE.INC}
{$I OPDEFINE.INC}
{!!.21} {Various changes made for compatibility with Filer 5.2}
{!!.22} {Various changes made to take advantage of fbProcessZero option}
{!!.50} {Various changes made due to changes in semaphore units}

{$IFDEF DynamicNet}
 {$DEFINE Novell}
{$ENDIF}

{.$DEFINE TestStream}  {enable this define to test streams support}

unit FbdMain;
  {-Main program block}

{!!.50 the check for UseOPCRT in BTDEFINE.INC has been removed}

interface

uses
  {.......................... Turbo Pascal units}
  Dos,                       {standard DOS unit}
  {.......................... Object Professional units}
  OpConst, {!!.40}           {error codes, etc.}
  OpRoot,                    {low-level objects, error codes, etc.}
  OpInline,                  {useful inline macros}
  OpString,                  {string handling}
  OpCrt,                     {basic screen handling}
  {$IFDEF UseMouse}
  OpMouse,
  {$ENDIF}
  OpCmd,                     {command processing}
  OpFrame,                   {window frames}
  OpWindow,                  {windows}
  OpField,                   {data entry fields}
  OpSelect,                  {abstract selector}
  OpEntry,                   {data entry screens}
  OpMemo,                    {memo editor}
  {.......................... Optional NetWare support}
  {$IFDEF Novell}
  NWBase,                    {NetWare access unit} {!!.50}
  NWConn,
  NWSema,                    {NetWare Semaphore unit}
  OopSema,                   {OOP Semaphore unit}
  {$ENDIF}
  {.......................... B-Tree Filer units}
  Filer,                     {database management}
  VRec,                      {variable length records}
  VRebuild,                  {database repair--variable length records}
  FBrowse;                   {object-oriented database browser}

procedure FBDemoMain;
  {-Main body of FBDEMO}

  {=======================================================================}

implementation

const
  {increase this to see an example of what multi-line items look like}
  RowsPerItem    = 1;        {number of rows per browser item}

  Key1Len        = 30;       {Uppercase last name+first name}
  Key2Len        = 5;        {First five digits of zip}
  MaxCols        = 101;      {length of one row}

  FName          = 'ADDRESS'; {Root name for database}
  LstDevice      = 'PRN';    {Where printed output goes}

  Header         : String[80] = {Basic string used to build display header}
  ' B-Tree Filer Demo Program                                                      ';

  F1             = $3B00;    {Keycodes for function keys}
  F2             = $3C00;
  F3             = $3D00;
  F4             = $3E00;
  F5             = $3F00;
  F6             = $4000;
  F7             = $4100;
  F8             = $4200;
  F9             = $4300;
  F10            = $4400;
  AltR           = $1300;
  AltM           = $3200;
  AltZ           = $2C00;

  SectionLength  = 140;      {each record will use from 1 to 8 sections}
  MaxMemoSize    = 932;      {140*8 = 1120, (7*(140-7))+1 = 932}
type
  CharSet        = set of Char;
  OpenMode       = (NormalMode, SaveMode);
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
      Notes          : MemoField;    {memo field: 1..MaxMemoSize bytes}
    end;                             {1065 bytes maximum, 134 minimum}

var
  PS             : LongInt;          {Pages in page stack}
  Pf             : IsamFileBlockPtr; {Isam management variable}

  Person         : PersonDef;        {Currently selected record}
  PersonFilter   : PersonDef;        {used for filtering}
  ActRec         : LongInt;          {Record number currently selected}
  ActKeyNr       : Integer;          {Active key number, 1 or 2}
  ActKey         : IsamKeyStr;       {Active key string}

  DatLen         : Word;
  BrowExit       : Word;
  AC             : Char;
  Mode           : OpenMode;
  Locked         : Boolean;

  {colors}
  HeadFootAttr   : Byte;
  SaveAttr       : Byte;

  {$IFDEF BTree52}
  DynamicNetType : NetSupportType;
  {$ENDIF}

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

  {data entry stuff}
const
  PhoneMask      : String[12] = '999-999-9999';
  ValidPhone     : String[12] = 'ppp-uuu-uuuu';
  ZipMask        : String[10] = '99999-9999';
  ValidZip       : String[10] = 'uuuuu-pppp';
  ValidationOff  : Boolean = False;

  {field IDs}
  idFirstName    = 0;
  idLastName     = 1;
  idCompany      = 2;
  idAddress      = 3;
  idCity         = 4;
  idState        = 5;
  idZipCode      = 6;
  idPhone        = 7;
  idNotes        = 8;

  {coordinates for entry screen and memo field windows}
  EntryXL        = 29;
  EntryYL        = 04;
  EntryXH        = 78;
  EntryYH        = 12;
  MemoXL         = 29;
  MemoYL         = 15;
  MemoXH         = 78;
  MemoYH         = 22;
var
  VB             : VBrowser;    {variable-length record data file browser}
  ES             : EntryScreen; {for entry screens}
  M              : Memo;        {for memo fields}
  ScrapPerson    : PersonDef;   {used for editing}
  VRecLen        : Word;
  {$IFDEF Novell}
  Sync           : TFilerSemaphore;
  {$ENDIF}

{$I FBDMAIN.IN1} {misc. screen stuff, semaphores, move/zoom/resize,
                  validation/conversion routines}

  procedure ClearPerson(var Person : PersonDef);
    {-Set up for a new person record}
  begin
    FillChar(Person, SizeOf(PersonDef), 0);
    Person.NotesLen := 1;
    Person.Notes[1] := ^Z;
  end;

  function CompPerson(var P1, P2 : PersonDef) : Boolean;
    {-Compare two person records}
  begin
    CompPerson := False;
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

    {compare memo fields quickly using routine in OPSTRING}
    if CompStruct(P1.Notes, P2.Notes, P1.NotesLen) <> Equal then
      Exit;

    CompPerson := True;
  end;

  procedure FixHeader(Header : String; RecNum : LongInt);
    {-Fix the entry screen's header}
  var
    Redraw : Boolean;
  begin
    {fix the header}
    if RecNum <> 0 then
      Header := Header+' Record # '+Long2Str(RecNum);
    with ES, wFrame do
      ChangeHeaderString(0, ' '+Header+' ', Redraw);
  end;

  procedure DisplayMemoField;
    {-Display the memo field}
  begin
    {reinitialize}
    M.ReinitBuffer;
    ScrapPerson.NotesLen := M.meTotalBytes;

    {display the contents of the memo}
    M.Draw;
  end;

  procedure EraseWindows;
    {-Erase the two windows}
  begin
    if ES.IsCurrent then
      ES.Erase;
    if M.IsCurrent then
      M.Erase;
    if ES.IsCurrent then
      ES.Erase;
  end;

  procedure DisplayMemoPrompt;
    {-Display prompt at bottom of screen while editing}
  begin
    WriteFooter(
      Center('Press <^Enter> when done editing notes to return to entry screen',
             ScreenWidth));
  end;

  procedure DisplayPerson(var Person : PersonDef; Header : String;
                          RecNum : LongInt);
    {-Show data about person}
  begin
    {copy into our scrap record}
    ScrapPerson := Person;

    {change the entry screen's header}
    FixHeader(Header, RecNum);

    {display entry screen}
    ES.Draw;

    {display memo field if appropriate}
    if RecNum <> 0 then
      DisplayMemoField;
  end;

  procedure EditMemoField;
    {-Edit the memo field}
  begin
    {display prompt}
    DisplayMemoPrompt;

    {do the editing}
    M.Select;
    M.Process;

    {save the number of bytes in the buffer}
    ScrapPerson.NotesLen := M.meTotalBytes;
  end;

  function GetPerson(var Person : PersonDef; NameRequired : Boolean;
                     Header : String; RecNum : LongInt) : Boolean;
    {-Edit a person record}
  var
    Done : Boolean;
  begin
    {copy into our scrap record}
    ScrapPerson := Person;

    {need special validation?}
    ValidationOff := not NameRequired;

    {set required status for last name}
    ES.ChangeRequired(idLastName, NameRequired);

    {hide Notes field if searching}
    ES.ChangeHidden(idNotes, not NameRequired);

    {change the entry screen's header}
    FixHeader(Header, RecNum);

    {draw the memo window if not searching}
    if NameRequired then
      DisplayMemoField;

    {start editing on first field}
    ES.SetNextField(idFirstName);

    Done := False;
    repeat
      {start editing}
      ES.Process;

      {see if we need to edit another record}
      case ES.GetLastCommand of
        ccDone :             {^Enter, ^KD, or ^KQ}
          begin
            Done := True;
            GetPerson := True;
          end;
        ccError,             {fatal error}
        ccQuit :             {Esc}
          begin
            Done := True;
            GetPerson := False;
          end;
        ccNested :
          {edit the notes field}
          if NameRequired then begin
            EditMemoField;
            ES.Select;
          end;
      end;
    until Done;

    {erase the two windows}
    EraseWindows;

    {return modified record, even if <Esc> was pressed--caller will ignore
     changes if appropriate}
    Person := ScrapPerson;

    {clear the prompt line}
    WriteFooter('');
  end;

  function CreateFile : Boolean;
    {-Create the database fileblock}
  var
    IID : IsamIndDescr;
  begin
    IID[1].KeyL := Key1Len;
    IID[1].AllowDupK := False;
    IID[2].KeyL := Key2Len;
    IID[2].AllowDupK := True;
    {$IFDEF BTree52}
    BTCreateFileBlock(FName, SectionLength, 2, IID);
    {$ELSE}
    MakeNetFileBlock(Pf, FName, SectionLength, 2, IID);
    {$ENDIF}
    CreateFile := IsamOK;
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

  {$F+} {the next three routines are called indirectly}

  function BuildKey(var P; KeyNr : Integer) : IsamKeyStr;
    {-Return the key string for either of the two indexes}
  begin
    with PersonDef(P) do
      case KeyNr of
        1 : BuildKey := Extend(StUpCase(Trim(Name)),20)+
                        Extend(StUpCase(Trim(FirstName)),10);
        2 : BuildKey := Copy(Zip, 1, 5);
      end;
  end;

  procedure BuildRow(Row : Byte; var DatS; DatLen : Word; Ref : LongInt;
                     Key : IsamKeyStr; var S : string; FBP : FBrowserPtr);
    {-Return one row of an item to the browser}
  var
    P : PersonDef absolute DatS;
    SLen : Byte absolute S;
  begin
    if Row > 1 then
      S := '----- row '+Long2Str(row)+' of record '+Long2Str(Ref)
    else if Ref <> -1 then
      S := PersonLine(P)
    else begin
      {Record is locked, indicate it on screen}
      S := '';
      while SLen < MaxCols do
        S := S+'**   ';
      SLen := MaxCols;
    end;
  end;

  procedure UpdateScreen(FBP : FBrowserPtr);
    {-Called by FBROWSE on each screen update}
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
    with fbColors, FBP^ do
      {Write the header line now}
      fFastWrite(
        Extend(Copy(Header, GetCurrentCol, Width), Width), 1, 1,
        ColorMono(HighlightColor, HighlightMono));
  end;

  {$F-}

  function AddStructure(var P : PersonDef; var Rec : LongInt) : Boolean;
    {-Add a new record}
  begin
    AddStructure := False;
    repeat
      {$IFDEF BTree52}
      BTAddVariableRec(Pf, Rec, P, P.NotesLen+SizeOf(PersonDef)-SizeOf(MemoField));
      {$ELSE}
      AddVariableRec(Pf, Rec, P, P.NotesLen+SizeOf(PersonDef)-SizeOf(MemoField));
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    if not IsamOK then
      IsamErrorNum(IsamError)
    else begin
      VB.fbOptionsOn(fbForceUpdate);
      AddStructure := True;
    end;
  end;

  function ModStructure(var P : PersonDef; Rec : LongInt) : Boolean;
    {-Write record over previous version}
  begin
    ModStructure := False;
    repeat
      {$IFDEF BTree52}
      BTPutVariableRec( {was BTAddVariableRec} {!!.22}
        Pf, Rec, P, P.NotesLen+SizeOf(PersonDef)-SizeOf(MemoField));
      {$ELSE}
      PutVariableRec(
        Pf, Rec, P, P.NotesLen+SizeOf(PersonDef)-SizeOf(MemoField), Normal);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    if not IsamOK then
      IsamErrorNum(IsamError)
    else begin
      VB.fbOptionsOn(fbForceUpdate);
      ModStructure := True;
    end;
  end;

  function DelStructure(var Rec : LongInt) : Boolean;
    {-Delete record}
  begin
    DelStructure := False;
    repeat
      {$IFDEF BTree52}
      BTDeleteVariableRec(Pf, Rec);
      {$ELSE}
      DeleteVariableRec(Pf, Rec);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    if not IsamOK then
      IsamErrorNum(IsamError)
    else begin
      VB.fbOptionsOn(fbForceUpdate);
      DelStructure := True;
    end;
  end;

  function AddKey(K : IsamKeyStr; Rec : LongInt; KeyNr : Integer) : Boolean;
    {-Add new key}
  begin
    AddKey := False;
    repeat
      {$IFDEF BTree52}
      BTAddKey(Pf, KeyNr, Rec, K);
      {$ELSE}
      AddNetKey(Pf, KeyNr, Rec, K);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    if not IsamOK then
      IsamErrorNum(IsamError)
    else
      AddKey := True;
  end;

  function EraseKey(K : IsamKeyStr; Rec : LongInt; KeyNr : Integer) : Boolean;
    {-Remove a key}
  begin
    EraseKey := False;
    repeat
      {$IFDEF BTree52}
      BTDeleteKey(Pf, KeyNr, Rec, K);
      {$ELSE}
      DeleteNetKey(Pf, KeyNr, Rec, K);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    if not IsamOK then
      IsamErrorNum(IsamError)
    else
      EraseKey := True;
  end;

  function ModKey(AltK, NeuK : IsamKeyStr; Rec : LongInt; KeyNr : Integer) : Boolean;
    {-Replace a key}
  begin
    ModKey := False;
    if EraseKey(AltK, Rec, KeyNr) then
      if AddKey(NeuK, Rec, KeyNr) then
        ModKey := True;
  end;

  procedure Reposition(UserKey : IsamKeyStr);
    {-Set sequential file pointer to another key}
  var
    Rec : LongInt;
  begin
    repeat
      {$IFDEF BTree52}
      BTFindKey(Pf, 1, Rec, UserKey);
      {$ELSE}
      FindNetKey(Pf, 1, Rec, UserKey);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    if not IsamOK then
      ActRec := 0;
  end;

  function LockAll : Boolean;
    {-Lock all open files, returning true if successful}
  var
    OK : Boolean;
  begin
    LockAll := False;
    repeat
      {$IFDEF BTree52}
      BTLockAllOpenFileBlocks;
      {$ELSE}
      LockAllOpenFileBlocks;
      {$ENDIF}
      if not IsamOK then begin
        if not YesNo('The file is presently in use. Try again?', 'Y') then
          Exit;
        OK := False;
      end
      else
        OK := True;
    until OK;
    LockAll := True;
  end;

  procedure NewStructure;
    {-Prompt for and add new record}
  label
    Retry;
  var
    PersonTemp : PersonDef;
    Key1, Key2 : IsamKeyStr;
    Rec : LongInt;
    KExists, OK : Boolean;
  begin
    WriteHeader(' New Entry ', True);
    ClearPerson(PersonTemp);

Retry:
    {Get the new record}
    if not GetPerson(PersonTemp, True, 'Add Record', 0) then
      Exit;

    {make the index keys}
    Key1 := BuildKey(PersonTemp, 1);
    Key2 := BuildKey(PersonTemp, 2);

    {Lock the database in order to safely add the record}
    if not LockAll then
      Exit;

    {Assure it's not a duplicate key}
    repeat
      {$IFDEF BTree52}
      KExists := BTKeyExists(Pf, 1, Rec, Key1);
      {$ELSE}
      KExists := NetKeyExists(Pf, 1, Rec, Key1);
      {$ENDIF}
      if LockAbort then begin
        {$IFDEF BTree52}
        BTUnLockAllOpenFileBlocks;
        {$ELSE}
        UnLockAllOpenFileBlocks;
        {$ENDIF}
        Exit;
      end;
    until not Locked;
    if KExists then begin
      {$IFDEF BTree52}
      BTUnLockAllOpenFileBlocks;
      {$ELSE}
      UnLockAllOpenFileBlocks;
      {$ENDIF}
      if not YesNo('The name already exists. Try again?', 'Y') then
        Exit
      else
        goto Retry;
    end;

    {Add the record and its keys}
    OK := AddStructure(PersonTemp, Rec);
    if OK then
      OK := AddKey(Key1, Rec, 1);
    if OK then
      OK := AddKey(Key2, Rec, 2);

    {$IFDEF Novell}
    {$IFDEF BTree52}
    if BTNetSupported = Novell then begin
    {$ELSE}
    if NetSupported = Novell then begin
    {$ENDIF}
      Sync.IndicateDirty(1);
      Sync.IndicateDirty(2);
    end;
    {$ENDIF}

    {Save global pointers to the current record}
    if OK then begin
      ActRec := Rec;
      case ActKeyNr of
        1 : ActKey := Key1;
        2 : ActKey := Key2;
      end;
      VB.SetCurrentRecord(ActKey, ActRec);
    end;

    {$IFDEF BTree52}
    BTUnLockAllOpenFileBlocks;
    {$ELSE}
    UnLockAllOpenFileBlocks;
    {$ENDIF}
  end;

  procedure Modify;
    {-Modify an existing record}
  label
    Retry;
  var
    PersonTemp : PersonDef;
    PersonTemp1 : PersonDef;
    KExists, OK : Boolean;
    Rec : LongInt;
    Escaped : Boolean;
    NoChanges : Boolean;
  begin
    WriteHeader(' Modify ', True);
    PersonTemp := Person;

Retry:
    Escaped := not GetPerson(PersonTemp, True, 'Modifying', ActRec);
    NoChanges := CompPerson(Person, PersonTemp);
    if Escaped and not NoChanges then
      NoChanges := YesNo('Ignore changes to record?', 'N');
    if NoChanges then begin
      DispMessageTemp('Files not changed.', 250);
      Exit;
    end;

    {Lock the database in order to safely modify the record}
    if not LockAll then
      Exit;

    if BuildKey(PersonTemp, 1) <> BuildKey(Person, 1) then begin
      {$IFDEF Btree52}
      KExists := BTKeyExists(Pf, 1, ActRec, BuildKey(PersonTemp, 1));
      {$ELSE}
      KExists := NetKeyExists(Pf, 1, ActRec, BuildKey(PersonTemp, 1));
      {$ENDIF}
      if not IsamOK then begin
        {$IFDEF BTree52}
        BTUnLockAllOpenFileBlocks;
        {$ELSE}
        UnLockAllOpenFileBlocks;
        {$ENDIF}
        IsamErrorNum(IsamError);
        Exit;
      end;
      if KExists then begin
        {$IFDEF BTree52}
        BTUnLockAllOpenFileBlocks;
        {$ELSE}
        UnLockAllOpenFileBlocks;
        {$ENDIF}
        if not YesNo('The name already exists. Try again?', 'Y') then
          Exit
        else
          goto Retry;
      end;
    end;

    Rec := ActRec;
    {Read actual disk data}
    {$IFDEF Btree52}
    BTGetVariableRec(Pf, Rec, PersonTemp1, VRecLen);
    {$ELSE}
    GetVariableRec(Pf, Rec, PersonTemp1, VRecLen, Normal);
    {$ENDIF}
    if not IsamOK then begin
      {$IFDEF BTree52}
      BTUnLockAllOpenFileBlocks;
      {$ELSE}
      UnLockAllOpenFileBlocks;
      {$ENDIF}
      DispMessageTemp('Record could not be read from disk.', 1000);
      Exit;
    end;

    if PersonTemp1.Dele <> LongInt(0) then begin
      {$IFDEF BTree52}
      BTUnLockAllOpenFileBlocks;
      {$ELSE}
      UnLockAllOpenFileBlocks;
      {$ENDIF}
      DispMessageTemp('The record has been erased in the meantime.', 1000);
      Exit;
    end;

    if not CompPerson(PersonTemp1, Person) then begin
      {$IFDEF BTree52}
      BTUnLockAllOpenFileBlocks;
      {$ELSE}
      UnLockAllOpenFileBlocks;
      {$ENDIF}
      DispMessageTemp('The record has been changed in the meantime.', 1000);
      Person := PersonTemp1;
      Exit;
    end;

    OK := ModStructure(PersonTemp, ActRec);
    if OK then
      if BuildKey(PersonTemp, 1) <> BuildKey(Person, 1) then begin
        OK := ModKey(BuildKey(Person, 1), BuildKey(PersonTemp, 1), ActRec, 1);
        if OK then
          Reposition(BuildKey(PersonTemp, 1));
      end;
    if OK then
      if BuildKey(PersonTemp, 2) <> BuildKey(Person, 2) then
        OK := ModKey(BuildKey(Person, 2), BuildKey(PersonTemp, 2), ActRec, 2);

    {$IFDEF BTree52}
    BTUnLockAllOpenFileBlocks;
    {$ELSE}
    UnLockAllOpenFileBlocks;
    {$ENDIF}
    if OK then begin
      Person := PersonTemp;
      VB.SetCurrentRecord(BuildKey(Person, ActKeyNr), ActRec);
      {$IFDEF Novell}
      {$IFDEF BTree52}
      if BTNetSupported = Novell then begin
      {$ELSE}
      if NetSupported = Novell then begin
      {$ENDIF}
        Sync.IndicateDirty(1);
        Sync.IndicateDirty(2);
      end;
      {$ENDIF}
    end;
  end;

  procedure Delete;
    {-Prompt for and delete a record}
  var
    Key1, Key2 : IsamKeyStr;
    OK, Del : Boolean;
  begin
    WriteHeader(' Deleting ', True);
    DisplayPerson(Person, 'Deleting', ActRec);
    Del := YesNo('Should the record really be deleted?', 'N');
    EraseWindows;
    if not Del then
      Exit;

    Key1 := BuildKey(Person, 1);
    Key2 := BuildKey(Person, 2);

    {Lock the database}
    if not LockAll then
      Exit;

    OK := EraseKey(Key1, ActRec, 1);
    if OK then
      OK := EraseKey(Key2, ActRec, 2);
    if OK then
      OK := DelStructure(ActRec);
    if not OK then
      IsamErrorNum(IsamError);

    {$IFDEF Novell}
    {$IFDEF BTree52}
    if OK and (BTNetSupported = Novell) then begin
    {$ELSE}
    if OK and (NetSupported = Novell) then begin
    {$ENDIF}
      Sync.IndicateDirty(1);
      Sync.IndicateDirty(2);
    end;
    {$ENDIF}

    {$IFDEF BTree52}
    BTUnLockAllOpenFileBlocks;
    {$ELSE}
    UnLockAllOpenFileBlocks;
    {$ENDIF}
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
    {-Compare two person records}
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

  function GetNextRec(var Fptr       : IsamFileBlockPtr;
                      var Data       : PersonDef;
                      KeyNr          : Integer;
                      var Rec        : LongInt;
                      var UserKey    : IsamKeyStr) : Boolean;
    {-Get next record in index order}
  begin
    GetNextRec := False;

    {Get next sequential key}
    repeat
      {$IFDEF Btree52}
      BTNextKey(Fptr, KeyNr, Rec, UserKey);
      {$ELSE}
      NextNetKey(Fptr, KeyNr, Rec, UserKey);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;

    if not IsamOK and (IsamError = 10250) then
      {At end of list, try once more to wrap to beginning}
      repeat
        {$IFDEF Btree52}
        BTNextKey(Fptr, KeyNr, Rec, UserKey);
        {$ELSE}
        NextNetKey(Fptr, KeyNr, Rec, UserKey);
        {$ENDIF}
        if LockAbort then
          Exit;
      until not Locked
    else
      GetNextRec := True;
    if not IsamOK then
      Exit;

    {Get associated data}
    repeat
      {$IFDEF Btree52}
      BTGetVariableRec(Fptr, Rec, Data, VRecLen);
      {$ELSE}
      GetVariableRec(Fptr, Rec, Data, VRecLen, Normal);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
  end;

  procedure Search;
    {-Search for a record}
  var
    R : LongInt;
    SearchKey : Integer;
    OK : Boolean;
    Found : Boolean;
    Key : IsamKeyStr;
    PersonGoal : PersonDef;
    PersonTemp : PersonDef;

    procedure NotFoundMessage;
    begin
      DispMessage('No matching record found', True, True);
    end;

  begin
    WriteHeader(' Search Key ', True);
    ClearPerson(PersonGoal);
    ClearPerson(PersonTemp);

    {Get search target}
    ValidationOff := True;
    if not GetPerson(PersonGoal, False, 'Search', 0) or
    CompPerson(PersonTemp, PersonGoal) then
      {Nothing entered}
      Exit;

    WriteFooter('Searching... ');

    {See which key to search on, if any}
    if Length(PersonGoal.Name) <> 0 then
      SearchKey := 1
    else if Length(PersonGoal.Zip) <> 0 then
      SearchKey := 2
    else
      SearchKey := 0;

    if SearchKey <> 0 then begin
      {Use the index system to position to the nearest record}
      Key := BuildKey(PersonGoal, SearchKey);
      repeat
        {$IFDEF BTree52}
        BTSearchKey(Pf, SearchKey, R, Key);
        {$ELSE}
        SearchNetKey(Pf, SearchKey, R, Key);
        {$ENDIF}
        if LockAbort then
          Exit;
      until not Locked;
      if not IsamOK then begin
        if IsamError = 10210 then
          NotFoundMessage
        else
          IsamErrorNum(IsamError);
        Exit;
      end;

      {Get the record}
      repeat
        {$IFDEF BTree52}
        BTGetVariableRec(Pf, R, PersonTemp, VRecLen);
        {$ELSE}
        GetVariableRec(Pf, R, PersonTemp, VRecLen, Normal);
        {$ENDIF}
        if LockAbort then
          Exit;
      until not Locked;

      {Position current record pointer at least near to the goal}
      ActRec := R;
      ActKey := BuildKey(PersonTemp, ActKeyNr);

      {Does it match the goal?}
      Found := MatchPerson(PersonGoal, PersonTemp);
      if Found and VB.IsFilteringEnabled then
        Found := MatchPerson(PersonFilter, PersonTemp);
    end
    else begin
      {Start sequential search at the currently active record}
      R := ActRec;
      {$IFDEF BTree52}
      BTFindKeyAndRef(Pf, ActKeyNr, R, ActKey, 0);
      {$ELSE}
      FindNetKeyAndRef(Pf, ActKeyNr, R, ActKey, 0);
      {$ENDIF}
      Found := False;
    end;

    if not Found then begin
      {Sequential search, starting one beyond current position}
      if SearchKey = 0 then
        SearchKey := ActKeyNr;
      repeat
        OK := GetNextRec(Pf, PersonTemp, SearchKey, R, Key);
        if not IsamOK then
          Exit;
        Found := MatchPerson(PersonGoal, PersonTemp);
        if Found and VB.IsFilteringEnabled then
          Found := MatchPerson(PersonFilter, PersonTemp);
      until Found or (R = ActRec);
    end;

    if Found then begin
      ActRec := R;
      ActKey := BuildKey(PersonTemp, ActKeyNr);
      VB.SetCurrentRecord(ActKey, ActRec);
    end
    else
      NotFoundMessage;
  end;

  procedure Status;
    {-Show the number of records}
  const
    ModeSt : array[OpenMode] of string[6] = ('Normal', 'Save');
  var
    F, U, K : LongInt;
  begin
    WriteHeader(' Status ', True);
    repeat
      {$IFDEF BTree52}
      U := BTUsedRecs(Pf);
      {$ELSE}
      U := UsedNetRecs(Pf);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;

    repeat
      {$IFDEF BTree52}
      F := BTFreeRecs(Pf);
      {$ELSE}
      F := FreeNetRecs(Pf);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    {$IFNDEF UseFiler500}
    repeat
      {$IFDEF BTree52}
      K := BTUsedKeys(Pf, 1);
      {$ELSE}
      K := UsedNetKeys(Pf, 1);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    {$ELSE}
    K := U;
    {$ENDIF}
    DispMessage(
      'Records:'+Long2Str(K)+
      ', Sections:'+Long2Str(U)+
      ', Deleted:'+Long2Str(F)+
      ', Mode:'+ModeSt[Mode]+
      {$IFDEF Btree54}                                   {!!.40}
      ', Station:'+Long2Str(BTGetInternalDialogID(Pf)),  {!!.40}
      {$ELSE}                                            {!!.40}
      ', Station:'+Long2Str(IsamWSNr),                   {!!.40}
      {$ENDIF}                                           {!!.40}
      True, False);
  end;

  procedure List;
    {-List all records to printer}
  var
    T     : LongInt;
    Rec   : LongInt;
    KeyNr : Integer;
    Key   : IsamKeyStr;
    OK    : Boolean;
    C     : Char;
    Lst   : Text;
    S     : String;
    SLen  : Byte absolute S;
  begin
    WriteHeader(' List ', True);

    {Assure there are records to print}
    repeat
      {$IFDEF BTree52}
      T := BTUsedRecs(Pf);
      {$ELSE}
      T := UsedNetRecs(Pf);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    if T = 0 then begin
      DispMessage('No records available', True, True);
      Exit;
    end;

    {See what order to print in -- provide chance to abort}
    C := Menu('NZA', 'Sort by  N)ame Z)ipcode A)bort');
    case C of
      'A' : Exit;
      'N' : KeyNr := 1;
      'Z' : KeyNr := 2;
    end;

    {Position over first record}
    repeat
      {$IFDEF BTree52}
      BTClearKey(Pf, KeyNr);
      {$ELSE}
      ClearNetKey(Pf, KeyNr);
      {$ENDIF}
      if LockAbort then
        Exit;
    until not Locked;
    Rec := 0;
    Key := '';
    if IsamOK then begin
      OK := GetNextRec(Pf, Person, KeyNr, Rec, Key);
      if Locked then
        Exit;

      {Print all the records}
      Assign(Lst, LstDevice);
      Rewrite(Lst);
      if IoResult <> 0 then begin
        DispMessage('Error attempting to write to '+LstDevice,True,True);
        Exit;
      end;

      AbortPrintMessage;
      repeat
        {get displayable string and trim checkmarks and blanks}
        S := PersonLine(Person);
        if S[SLen] = #251 then
          Dec(SLen);
        while S[SLen] = ' ' do
          Dec(SLen);

        WriteLn(Lst, S);
        OK := (IoResult = 0);
        if OK then
          OK := not Aborting
        else
          DispMessage('Printer error', True, True);
        if OK then
          OK := GetNextRec(Pf, Person, KeyNr, Rec, Key);
        if Locked then
          OK := False;
      until not(IsamOK and OK);
      Close(Lst);
      if IoResult <> 0 then ;   {clear IoResult}
    end;
  end;

  function Long2StrDigits(L : LongInt; NumDigits : Byte) : String;
  {-Convert a longint to a string, right justified to NumDigits}
  var
    S : String;
  begin
    Str(L:NumDigits,S);
    Long2StrDigits := S;
  end;

  {$F+}
  procedure UserStatusRoutine(KeyNr : Integer;
                              NumRecsRead,
                              NumRecsWritten : LongInt;
                              var Data;
                              Len : Word);
  {-Display information while rebuilding database}
  var
    StatStr : String[80];
  begin
    StatStr := 'Working on key --> '+Long2StrDigits(KeyNr,1)+
               '   records read --> '+Long2StrDigits(NumRecsRead,6)+
               '   written --> '+Long2StrDigits(NumRecsWritten,6);
    WriteFooter(StatStr);
  end;
  {$F-}

  function Reconstruct : Boolean;
    {-Reconstruct the database from the datafile}
  var
    IID : IsamIndDescr;
  begin
    IID[1].KeyL := Key1Len;
    IID[1].AllowDupK := False;
    IID[2].KeyL := Key2Len;
    IID[2].AllowDupK := True;
    {$IFNDEF UseFiler500}
    IsamRexUserProcPtr := @UserStatusRoutine;  {set user status procedure}
    {$ENDIF}
    RebuildVFileBlock(FName, SectionLength, 2, IID, @BuildKey);
    Reconstruct := IsamOK;
  end;

  function OpenedFiles : Boolean;
    {-Try to open existing database files}
  var
    OK, OK1 : Boolean;
  begin
    OpenedFiles := False;
    repeat
      {$IFDEF BTree52}
      BTOpenFileBlock(Pf, FName, False, False, (Mode = SaveMode),
        BTNetSupported <> NoNet);                                 {!!.22}
      {$ELSE}
      if Mode = NormalMode then
        OpenNetFileBlock(Pf, FName)
      else
        OpenSaveNetFileBlock(Pf, FName);
      {$ENDIF}
      OK := IsamOK;
      if not IsamOK then begin
        if IsamError = 10010 then begin
          if YesNo('Index file defective. Rebuild it?', 'Y') then
            OK1 := Reconstruct
          else
            Exit;
        end
        else if IsamError = 9903 then begin
          if YesNo('Data file does not exist. Create new one?', 'Y') then begin
            if not CreateFile then
              Exit;
            {$IFNDEF BTree52}
            CloseNetFileBlock(Pf);
            {$ENDIF}
          end
          else
            Exit;
        end
        else begin
          if YesNo('Data error '+Long2Str(IsamError)+'. Attempt rebuild?', 'Y') then
            OK1 := Reconstruct
          else
            Exit;
        end;
      end;
    until OK;
    OpenedFiles := True;
  end;

  procedure SwitchKeys;
    {-Make the other key active}
  begin
    ActKeyNr := (ActKeyNr and 1)+1;
    ActKey := BuildKey(Person, ActKeyNr);
    VB.SetKeyNumber(ActKeyNr);
    VB.SetCurrentRecord(ActKey, ActRec);
  end;

  {---------------------------filtering hooks-----------------------------
    The following routine is used to implement the special filtering
    capabilities of FBDEMO. When the F6 key is pressed, the user is
    prompted for information to be used to determine what records should
    appear in the browser.
  ------------------------------------------------------------------------}
  {$F+}
  function ValidatePerson(Ref : LongInt; Key : IsamKeyStr;
                          FBP : FBrowserPtr) : Boolean;
    {-Validate a data record against the current Browser filter}
  begin
    FBP^.GetRecord(Ref, Person, DatLen);
    if not IsamOK then
      ValidatePerson := False
    else
      {is it a match?}
      ValidatePerson := MatchPerson(PersonFilter, Person);
  end;
  {$F-}

  procedure Filter;
    {-Prompt for information used by Browser filtering routines}
  var
    PersonGoal, PersonTemp : PersonDef;
  begin
    WriteHeader(' Filtering Info ', True);

    {cancel existing filter}
    VB.SetFilterFunc(NullFilterFunc);

    ClearPerson(PersonTemp);
    ClearPerson(PersonGoal);

    {get filtering information}
    if GetPerson(PersonGoal, False, 'Filter', 0) then
      {did user enter anything?}
      if not CompPerson(PersonTemp, PersonGoal) then
        {confirm that user desires filtering}
        if YesNo('Enable filtering with this information?', 'Y') then begin
          PersonFilter := PersonGoal;
          VB.SetFilterFunc(ValidatePerson);
        end;
  end;

  procedure RebuildData;
    {-Purge deleted records and rebuild indices}
  begin
    WriteHeader(' Rebuild ', True);
    WriteFooter('Please wait... ');
    {$IFDEF BTree52}
    BTCloseFileBlock(Pf);
    {$ELSE}
    CloseNetFileBlock(Pf);
    {$ENDIF}
    if not IsamOK then begin
      IsamErrorNum(IsamError);
      Halt;
    end;
    if not Reconstruct then begin
      DispMessage('Unable to rebuild data files', True, True);
      Halt;
    end;
    if not OpenedFiles then begin
      IsamErrorNum(IsamError);
      Halt;
    end;
    {$IFNDEF BTree52}
    EnableSearchForSequential(Pf, 1);
    EnableSearchForSequential(Pf, 2);
    {$ENDIF}
    ActRec := 0;
    ActKeyNr := 1;
    ActKey := '';

    {reset file block pointer in Browser, in case it changed} {!!.07}
    VB.SetFileBlockPtr(Pf);                                   {!!.07}
  end;

{$F+}
  procedure ErrorHandler(UnitCode : Byte; var ErrCode : Word; Msg : String);
    {-Display messages for errors reported by OPENTRY/OPMEMO/FBROWSE}
  var
    P : Pointer;
  begin
    {try to save underlying text}
    if not SaveWindow(1, ScreenHeight, ScreenWidth, ScreenHeight, True, P) then begin
      RingBell;
      Exit;
    end;

    if Msg = '' then
      Msg := 'Unknown error: '+Long2Str(ErrCode);

    {display the error message}
    if ErrCode = epFatal+ecIsamError then
      IsamErrorNum(IsamError)
    else
      DispMessage(Msg, True, True);

    {restore underlying text}
    RestoreWindow(1, ScreenHeight, ScreenWidth, ScreenHeight, True, P);
  end;

  procedure PreEdit(ESP : EntryScreenPtr);
    {-Display a help prompt for the current field}
  var
    S : String[40];
  begin
    case ESP^.GetCurrentID of
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

  procedure MemoFieldStatus(MP : MemoPtr);
    {-Display status line for memo field}
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
    with FbColors, MP^ do begin
      {insert line number}
      S := Long2Str(meCurLine);
      S := Pad(S, 3);
      Move(S[1], StatusLine[8], 3);

      {insert column number}
      S := Long2Str(meCurCol);
      S := Pad(S, 3);
      Move(S[1], StatusLine[20], 3);

      {insert percentage of buffer used}
      S := Real2Str(Trunc((meTotalBytes*100.0)/(meBufSize-2)), 3, 0);
      Move(S[1], StatusLine[24], 3);

      {plug in state stuff}
      Move(InsertSt[meOptionsAreOn(meInsert)][1], StatusLine[30], 6);
      Move(IndentSt[meOptionsAreOn(meIndent)][1], StatusLine[37], 6);
      Move(WrapSt[meOptionsAreOn(meWordWrap)][1], StatusLine[44], 4);

      {$IFDEF UseMouse}
      HideMousePrim(SaveMouse);
      {$ENDIF}

      {display status line}
      FastWrite(
        StatusLine, MemoYH+1, MemoXL+1, ColorMono(PromptColor, PromptMono));

      {$IFDEF UseMouse}
      ShowMousePrim(SaveMouse);
      {$ENDIF}
    end;
  end;

{$F-}

  procedure InitEntryScreen;
    {-Set up for data entry screens}
  const
    Options     = wClear+wBordered;
    NameMask    = 'xxxxxxxxxxxxxxx';
    CompanyMask = 'xxxxxxxxxxxxxxxxxxxxxxxxx';
    NotesMsg    : string[1] = #14;
  begin
    {clear the scrap record used for editing}
    ClearPerson(ScrapPerson);

    {.F-}
    {initialize the entry screen}
    if not ES.InitCustom(EntryXL,          {left column of window}
                         EntryYL,          {top row of window}
                         EntryXH,          {right column of window}
                         EntryYH,          {bottom row of window}
                         FbColors,         {color set}
                         Options)          {window options}
    then
      Abort;

    {add dummy header}
    ES.wFrame.AddHeader(' dummy ', heTC);

    {set field delimiters}
    ES.SetDelimiters('[', ']');

    {set entry screen options}
    ES.SetWrapMode(WrapAtEdges);

    {set field editing options}
    ES.esFieldOptionsOn(efBeepOnError+efClearFirstChar);

    {add each of the edit fields in order: left to right, top to bottom}
    {               Prompt               ---Field--- Help              }
    { Prompt        Row Col Picture      Row Col Len Index     Variable}

    ES.AddStringField(
      'First name', 01, 05, NameMask,    01, 21, 15, 00, ScrapPerson.FirstName);

    ES.AddStringField(
      'Last name',  02, 05, NameMask,    02, 21, 15, 01, ScrapPerson.Name);

    ES.AddStringField(
      'Company',    03, 05, CompanyMask, 03, 21, 25, 02, ScrapPerson.Company);

    ES.AddStringField(
      'Address',    04, 05, CompanyMask, 04, 21, 25, 03, ScrapPerson.Address);

    ES.AddStringField(
      'City',       05, 05, NameMask,    05, 21, 15, 04, ScrapPerson.City);

    ES.AddStringField(
      'State',      06, 05, 'AA',        06, 21, 02, 05, ScrapPerson.State);
    ES.ChangeValidation(idState, ValidateState);

    ES.AddStringField(
      'Zip',        07, 05, ZipMask,     07, 21, 10, 06, ScrapPerson.Zip);
    ES.ChangeConversion(idZipCode, PhoneZipConversion);
    ES.ChangeValidation(idZipCode, ValidateZip);

    ES.AddStringField(
      'Telephone',  08, 05, PhoneMask,   08, 21, 12, 07, ScrapPerson.Telephone);
    ES.ChangeConversion(idPhone, PhoneZipConversion);
    ES.ChangeValidation(idPhone, ValidatePhone);

    ES.esFieldOptionsOff(efMapCtrls);
    ES.AddNestedStringField(
      'Notes',      09, 05, '',          09, 21, 01, 08, NotesMsg);
    {.F+}

    {install user-written event handlers}
    ES.SetPreEditProc(PreEdit);
    ES.SetErrorProc(ErrorHandler);

    {check for error}
    if ES.GetLastError <> 0 then
      Abort;
  end;

  procedure InitMemoFields;
    {-Set up for memo fields}
  const
    Options = wClear+wBordered;
  begin
    {deactivate <Esc>, use <^Enter> instead}
    MemoCommands.AddCommand(ccNone, 1, Ord(^[), 0);
    MemoCommands.AddCommand(ccQuit, 1, Ord(^J), 0);

    {.F-}
    {initialize the memo}
    if not M.InitCustom(MemoXL,                {left column of window}
                        MemoYL,                {top row of window}
                        MemoXH,                {right column of window}
                        MemoYH,                {bottom row of window}
                        FbColors,              {color set}
                        Options,               {window options}
                        SizeOf(MemoField),     {size of edit buffer}
                        @ScrapPerson.Notes)    {edit buffer}
    then
      Abort;
    {.F+}

    {add dummy header}
    M.wFrame.AddHeader(' Notes ', heTC);

    {set right margin}
    M.SetRightMargin(MemoXH-MemoXL);

    {install user-written event handlers}
    M.SetStatusProc(MemoFieldStatus);
    M.SetErrorProc(ErrorHandler);

    {check for error}
    if M.GetLastError <> 0 then
      Abort;
  end;

  procedure InitBrowser;
    {-Set up for browsing}
  const
    {$IFDEF UseAdjustableWindows}
    Options = wClear+wBordered+wResizeable+wSetMouse;
    {$ELSE}
    Options = wClear+wBordered;
    {$ENDIF}
  {$IFDEF TestStream}
  var
    S : BufIdStream;
  {$ENDIF}

  {$IFDEF TestStream}
    procedure RegisterTypes;
      {-Register necessary types}
    begin
      S.RegisterHier(VBrowserStream);                {! required !}
      S.RegisterPointer(1000, Pf);                   {! required !}
      S.RegisterPointer(1001, @Person);              {! required !}
      S.RegisterPointer(1002, @BuildRow);            {v optional v}
      S.RegisterPointer(1003, @UpdateScreen);
      S.RegisterPointer(1004, @ErrorHandler);
      S.RegisterPointer(1005, @RefreshPeriodically);
    end;
  {$ENDIF}

  begin
    {add user-defined exit commands}
    with FBrowserCommands do begin
      AddCommand(ccUser2,  1, F2,   0); {add record}
      AddCommand(ccUser3,  1, F3,   0); {delete record}
      AddCommand(ccUser4,  1, F4,   0); {search}
      AddCommand(ccUser5,  1, F5,   0); {switch keys}
      AddCommand(ccUser6,  1, F6,   0); {filter}
      AddCommand(ccUser8,  1, F8,   0); {print records}
      AddCommand(ccUser9,  1, F9,   0); {show status}
      AddCommand(ccUser10, 1, F10,  0); {purge}
      {$IFDEF UseAdjustableWindows}
      AddCommand(ccUser11, 1, AltR, 0); {resize window}
      AddCommand(ccUser12, 1, AltM, 0); {move window}
      AddCommand(ccUser13, 1, AltZ, 0); {zoom window}
      {$ENDIF}
    end;

    {initialize the browser}
    if not VB.InitCustom(3,              {left column of window}
                         5,              {top row of window}
                       {$IFDEF UseShadows}
                         ScreenWidth-3,  {right column of window}
                       {$ELSE}
                         ScreenWidth-2,  {right column of window}
                       {$ENDIF}
                         ScreenHeight-3, {bottom row of window}
                         FbColors,       {color set}
                         Options,        {window options}
                         Pf,             {fileblock}
                         ActKeyNr,       {key number}
                         Person,         {scrap variable}
                         ScreenHeight-5, {maximum rows}
                         RowsPerItem,    {rows per item}
                         MaxCols)        {maximum columns}
    then
      Abort;

    {adjust frame coordinates}
    with VB do begin
      {$IFDEF UseAdjustableWindows}
      {set the limits to use when moving/zooming/resizing the window}
      SetPosLimits(1, 2, ScreenWidth, ScreenHeight-1);
      {$ENDIF}

      with wFrame do begin
        AdjustFrameCoords(frXL, frYL-1, frXH, frYH);

        {$IFDEF UseScrollBars}
        {add scroll bars}
        AddCustomScrollBar(frBB, 0, MaxLongInt, 1, 1, #178, #176, fbColors);
        AddCustomScrollBar(frRR, 0, MaxLongInt, 1, 1, #178, #176, fbColors);
        {$ENDIF}

        {add headers}
        AddCustomHeader(#181, frTL,  1, 0, $1F, $0F);       {1}
        AddCustomHeader(#7,   frTL,  2, 0, $71, $70);       {2}
        AddCustomHeader(#198, frTL,  3, 0, $1F, $0F);       {3}
        AddCustomHeader(#181, frTR, -3, 0, $1F, $0F);       {4}
        AddCustomHeader(#24,  frTR, -2, 0, $71, $70);       {5}
        AddCustomHeader(#198, frTR, -1, 0, $1F, $0F);       {6}
        AddCustomHeader('+',  frBR,  0, 0, $17, $07);       {7}

        {$IFDEF UseHotSpots}
        {add hot spots}
        AddHotRegion(frTL, hsRegion0, 2, 0, 1, 1);          {Close}
        AddHotRegion(frTR, hsRegion1, -2, 0, 1, 1);         {Zoom}
        AddHotBar(frTT,    hsRegion2);                      {Move}
        AddHotRegion(frBR, hsRegion3, 0, 0, 1, 1);          {Resize}
        {$ENDIF}

        {$IFDEF UseShadows}
        AddShadow(shBR, shSeeThru);
        {$ENDIF}
      end;
    end;

    {install user-written event handlers}
    VB.SetBuildItemProc(BuildRow);
    VB.SetScreenUpdateProc(UpdateScreen);
    VB.SetErrorProc(ErrorHandler);

    {$IFDEF Novell}
    {$IFDEF BTree52}
    if BTNetSupported = Novell then begin
    {$ELSE}
    if NetSupported = Novell then begin
    {$ENDIF}
      VB.SetRefreshFunc(SemaphoreRefresh);
      RefreshPeriod := 18 div 2;
    end
    else
      VB.SetRefreshFunc(RefreshPeriodically);
    {$ELSE}
    VB.SetRefreshFunc(RefreshPeriodically);
    {$ENDIF}

    {options}
    VB.fbOptionsOn(fbFlushKbd+fbProcessZero);

    {you might want to try uncommenting one or more of the following:}
    { VB.fbOptionsOn(fbBellOnFlush); }
    { VB.SetKeyRange('C'#0, 'K'#255); }
    { VB.fbOptionsOff(fbAutoScale); }
    { VB.fbOptionsOff(fbDrawActive); }
    { VB.fbOptionsOn(fbScrollByPage); }
    { VB.SetHorizScrollDelta(10); }
    { VB.SetVertScrollDelta(5); }
    { VB.fbOptionsOn(fbCenterCurrent); }

    VB.fbOptionsOff(fbSelectOnClick); {!!.40}

    {check for error}
    if VB.GetLastError <> 0 then
      Abort;

  {$IFDEF TestStream}
    {create stream file}
    S.Init('FBDEMO.STM', SCreate, 4096);

    {register types and store the entry screen}
    RegisterTypes;
    S.Put(VB);
    if S.GetStatus <> 0 then begin
      WriteLn('Store error');
      Halt(2);
    end;
    S.Done;
    VB.Done;

    {reopen stream file}
    S.Init('FBDEMO.STM', SOpen, 4096);

    {register types and load the entry screen}
    RegisterTypes;
    S.Get(VB);
    if S.GetStatus <> 0 then begin
      WriteLn('Load error');
      Halt(3);
    end;
    S.Done;
  {$ENDIF}

  end;

  procedure GetOptionsFromCommandLine;
    {-Get the network type (and station number if necessary) from Command line}
  type
    Str128 = String[128];
  var
    Opt : Str128;
  const
    {$IFDEF DynamicNet}
    ParamNum = 2;
    {$ELSE}
    ParamNum = 1;
    {$ENDIF}

    procedure ShowHelp;
      {-Display help message and halt}
    begin
      WriteLn('Usage: FBDEMO /opt');
      WriteLn;
      WriteLn('where opt is:');
      {$IFNDEF Btree54}
      WriteLn('  /B     - MS-Net compatible with NetBIOS machine name support');
      WriteLn('  /C     - CBIS'' Network-OS');
      {$ENDIF}
      WriteLn('  /D     - Single-user DOS, no network');
      {$IFDEF Btree54}
      WriteLn('  /M     - MS-Net or compatible');
      {$ELSE}
      WriteLn('  /M wn  - MS-Net or compatible. wn is the workstation number');
      {$ENDIF}
      WriteLn('  /N     - Novell''s Advanced NetWare');
      {$IFNDEF Btree54}
      WriteLn('  /P     - Software Link''s PC-MOS 386');
      {$IFDEF BTree52}
      WriteLn('  /Q     - DesqView with SHARE');
      {$ENDIF}
      WriteLn('  /V     - Banyan''s Vines');
      WriteLn('  /X     - Alloy''s NTNX');
      {$ENDIF}
      Halt;
    end;

    procedure InvalidOption(Opt : Str128);
      {-Display invalid option message, show help, and halt}
    begin
      WriteLn('Invalid Option: ',Opt);
      WriteLn;
      ShowHelp;
    end;

  begin
    {$IFDEF NoNet}
    DynamicNetType := NoNet;
    {$ELSE}
    if ParamCount = 0 then
      ShowHelp
    else begin
      Opt := ParamStr(1);
      if Length(Opt) < 2 then
        InvalidOption(Opt);
    end;
    case UpCase(Opt[2]) of
      '?' : ShowHelp;
      'D' : DynamicNetType := NoNet;
      'M' : DynamicNetType := MsNet;
      'N' : DynamicNetType := Novell;
      {$IFNDEF Btree54}
      'B' : DynamicNetType := MsNetMachName;
      'C' : DynamicNetType := CBISNet;
      'P' : DynamicNetType := PCMos386;
      {$IFDEF BTree52}
      'Q' : DynamicNetType := DesqView;
      {$ENDIF}
      'V' : DynamicNetType := VinesNet;
      'X' : DynamicNetType := NTNXNet;
      {$ENDIF}
      else InvalidOption(Opt);
    end; {case}
    {$ENDIF}

    {$IFNDEF Btree54}
    {Get the workstation number}
    case DynamicNetType of
      NoNet :
        {do nothing} ;
      Novell, MsNetMachName, CBISNet
      {$IFNDEF UseFiler500}
      , NTNXNet, VinesNet
      {$ENDIF}
      {$IFDEF BTree52}
      , DesqView
      {$ENDIF}
        : {These automatically determine the workstation number} ;
      {PCMOS386 also automatically determines the workstation number}
      PcMos386 :
        {$IFDEF BTree52}
        if not BTSetDosRetry(1, 1) then
        {$ELSE}
        if not SetDosRetry(1, 1) then
        {$ENDIF}
          Halt;
      else
        begin
          if ParamCount <> 2 then begin
            Write('The /M option requires the workstation number as ');
            WriteLn('the second parameter, as in:');
            WriteLn('FBDEMO /M 2');
            Halt;
          end;
          {$IFDEF BTree52}
          if not Str2Word(ParamStr(ParamNum), IsamWSNr) then begin
          {$ELSE}
          if not Str2Int(ParamStr(ParamNum), IsamWSNr) then begin
          {$ENDIF}
            WriteLn('The workstation number must be an integer');
            Halt;
          end;
          if (IsamWSNr < 1) or (IsamWSNr > MaxNrOfWorkStations) then begin
            WriteLn('Invalid workstation number. Must be in range 1..',
                    MaxNrOfWorkStations);
            Halt;
          end;
        end;
    end;
    {$ENDIF}
  end;

  function Delta(I : Integer) : Integer;
  begin
    if I < -4 then
      Delta := -1
    else if I > 4 then
      Delta := 1
    else
      Delta := 0;
  end;

  procedure FBDemoMain;
    {-Main body of FBDEMO}
  var
    BP : LongInt;
    MicH : Integer;
    MicV : Integer;
    Free : LongInt;
    FP : FramePosType;
    XAbs : Byte;
    YAbs : Byte;
    HC : Byte;
    Clicked : Boolean;
  begin
    {parse the command line}
    GetOptionsFromCommandLine;

    with FbColors do
      HeadFootAttr := ColorMono(FrameColor, FrameMono); {!!.07}

    {initialize screen}
    InitEntryScreen;
    InitMemoFields;
    SaveAttr := TextAttr;

    {clear the screen}
    TextChar := #178;
    TextAttr := $07;
    ClrScr;

    CheckBreak := False;

    {other initialization}
    ActRec := 0;
    ActKeyNr := 1;
    ActKey := '';

    WriteHeader(' Initializing ', False);

    {allocate a buffer for variable length records}
    {$IFDEF BTree52}
    if not BTSetVariableRecBuffer(SectionLength) then begin
    {$ELSE}
    if not SetVariableRecBuffer(SectionLength) then begin
    {$ENDIF}
      DispMessageTemp('Insufficient memory. Program aborting.', 2000);
      Halt;
    end;

    {Limit the number of index buffers}          {!!.40}
    Free := 25000+(400*ScreenHeight);            {!!.40}
    if MemAvail-Free > 200000 then               {!!.40}
      Free := MemAvail-200000;                   {!!.40}
    {$IFDEF BTree52}
    PS := BTInitIsam(DynamicNetType, Free, 0);   {!!.40}
    {$ELSE}
    InitNetIsam(NetSupported <> NoNet);
    {$ENDIF}
    if not IsamOK then begin
      IsamErrorNum(IsamError);
      Halt;
    end;

    {$IFNDEF BTree52}
    PS := GetPageStack(Free);                    {!!.40}
    if not IsamOK then begin
      DispMessageTemp('Insufficient memory. Program aborting.', 2000);
      Halt;
    end;
    {$ENDIF}

    if YesNo('Should the files be handled using Save mode?', 'N') then
      Mode := SaveMode
    else
      Mode := NormalMode;

    if not OpenedFiles then begin
      DispMessageTemp('Files could not be opened. Aborting.', 2000);
      Halt;
    end;

    {$IFDEF Novell}
    {$IFDEF BTree52}
    if BTNetSupported = Novell then
    {$ELSE}
    if NetSupported = Novell then
    {$ENDIF}
      if Sync.Init(nwDefaultServer, FName, 2) then
        RefreshPeriod := 9            {check every half of a second}
      else begin
        DispMessageTemp('Error initializing semaphore object. Aborting.', 2000);
        Halt;
      end;
    {$ENDIF}

    {$IFNDEF BTree52}
    EnableSearchForSequential(Pf, 1);
    EnableSearchForSequential(Pf, 2);
    {$ENDIF}

    {$IFDEF UseMouse}
    if MouseInstalled then begin
      {use a red diamond for our mouse cursor}
      with fbColors do
        SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) shl 8)+$04);
      ShowMouse;

      {enable mouse support}
      EntryCommands.cpOptionsOn(cpEnableMouse);
      MemoCommands.cpOptionsOn(cpEnableMouse);
      FBrowserCommands.cpOptionsOn(cpEnableMouse);
    end;
    {$ENDIF}

    {initialize file browser}
    InitBrowser;

    repeat
      {Update the screen and browse around the records}
      WriteHeader(' Main Menu ', True);
      WriteFooter('F2-Add  F3-Del  F4-Find  F5-Key  F6-Filter  F8-Prn  F9-Info  F10-Purge  Esc-Quit');

      {process commands}
      VB.Process;
      BrowExit := VB.GetLastCommand;
      WriteFooter('');

      {Check for errors}
      case VB.GetLastError of
        0 :
          if (BrowExit <> ccQuit) and (BrowExit <> ccError) then begin
            {get current key and reference}
            VB.GetCurrentKeyAndRef(ActKey, ActRec);

            {Person already contains current record on ccSelect}
            if (BrowExit <> ccSelect) and (ActRec <> 0) then
              {get current record}
              VB.GetCurrentRecord(Person, DatLen);

            {check for error}
            if not IsamOK then begin
              IsamErrorNum(IsamError);
              BrowExit := ccNone;
            end;
          end;
        epFatal+ecNoKeysFound :
          begin
            if VB.IsFilteringEnabled then begin
              VB.SetFilterFunc(NullFilterFunc);
              BrowExit := ccNone;
            end;
            VB.ClearErrors;
          end;
        else
          DispMessageTemp('Aborting.', 2000);
          BrowExit := ccError;
      end;

      {Handle requests for action}
      case BrowExit of
        ccSelect : if ActRec = 0 then
                     NewStructure
                   else
                     Modify;
        ccUser2  : NewStructure;
        ccUser3  : if ActRec <> 0 then
                     Delete;
        ccUser4  : if ActRec <> 0 then
                     Search;
        ccUser5  : SwitchKeys;
        ccUser6  : Filter;
        ccUser8  : if ActRec <> 0 then
                     List;
        ccUser9  : Status;
        ccUser10 : RebuildData;
        {$IFDEF UseAdjustableWindows}
        ccUser11 : ResizeBrowseWindow;
        ccUser12 : MoveBrowseWindow;
        ccUser13 : ToggleZoom;
        {$ENDIF}
        {$IFDEF UseMouse}
        ccMouseSel :
          with VB do begin
            XAbs := MouseLastX+MouseXLo;
            YAbs := MouseLastY+MouseYLo;
            EvaluatePos(XAbs, YAbs);
            BP := PosResults(FP, HC);
            if FP <> frOutsideFrame then
              case HC of
                hsRegion0 : {Close}
                  BrowExit := ccQuit;

                hsRegion1 : {Zoom}
                  ToggleZoom;

                hsRegion2 : {Move}
                  if not IsZoomed then begin
                    WriteFooter(' Drag window to new location, then click left mouse button');
                    HideMouse;
                    Dec(XAbs, wFrame.frXL);
                    Dec(YAbs, wFrame.frYL);
                    GetMickeyCount(MicH, MicV);
                    repeat
                      GetMickeyCount(MicH, MicV);
                      MoveWindow(Delta(MicH), Delta(MicV));
                      if ClassifyError(GetLastError) = etFatal then
                        Abort;
                      if MousePressed then
                        Clicked := (MouseKeyWord = MouseLft)
                      else
                        Clicked := False;
                    until Clicked;
                    Inc(XAbs, wFrame.frXL);
                    Inc(YAbs, wFrame.frYL);
                    MouseGoToXY(XAbs, YAbs);
                    WriteFooter('');
                    ShowMouse;
                  end;

                hsRegion3 : {Resize}
                  if not IsZoomed then begin    {!!.01}
                    WriteFooter(' Move mouse to resize window, then click left mouse button');
                    HideMouse;
                    GetMickeyCount(MicH, MicV);
                    repeat
                      GetMickeyCount(MicH, MicV);
                      ResizeWindow(Delta(MicH), Delta(MicV));
                      if ClassifyError(GetLastError) = etFatal then
                        Abort;
                      if MousePressed then
                        Clicked := (MouseKeyWord = MouseLft)
                      else
                        Clicked := False;
                    until Clicked;
                    MouseGoToXY(wFrame.frXH, wFrame.frYH);
                    WriteFooter('');
                    ShowMouse;
                  end;
              end;
          end;
        {$ENDIF}
        ccQuit   : if not YesNo('Quit program?', 'N') then
                     BrowExit := ccNone;
      end;
    until (BrowExit = ccQuit) or (BrowExit = ccError);

    {Close up the database}
    {$IFDEF BTree52}
    BTCloseFileBlock(Pf);
    {$ELSE}
    CloseNetFileBlock(Pf);
    {$ENDIF}
    if not IsamOK then
      DispMessageTemp('Data may be corrupt.', 2000);
    {$IFDEF BTree52}
    BTExitIsam;
    BTReleaseVariableRecBuffer;
    {$ELSE}
    ReleasePageStack;
    ExitNetIsam;
    ReleaseVariableRecBuffer;
    {$ENDIF}

    {$IFDEF UseMouse}
    HideMouse;
    {$ENDIF}

    {clear the screen}
    VB.Erase;
    TextAttr := SaveAttr;
    ClrScr;
    {$IFDEF Novell}
    {$IFDEF BTree52}
    if BTNetSupported = Novell then
    {$ELSE}
    if NetSupported = Novell then
    {$ENDIF}
      Sync.Done;
    {$ENDIF}
  end;

end.

