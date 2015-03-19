{$R-,S-,I-,V-,B-,F+,O+,A-}

{$I OPDEFINE.INC}
{$I BTDEFINE.INC}
{!!.21} {Various changes made for B-Tree Filer 5.2}

{*********************************************************}
{*                   FBROWSE.PAS 5.50                    *}
{*     Copyright (c) TurboPower Software 1990, 1994      *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit FBrowse;
  {-CommandWindow-based data file browser for B-Tree Filer}

interface

uses
  Dos,
  OpInline,
  OpString,
  {$IFDEF OPro12} {!!.40}
  OpConst,        {!!.40}
  {$ENDIF}        {!!.40}
  OpRoot,
  OpCrt,
  {$IFDEF UseMouse}
  OpMouse,
  {$ENDIF}
  OpCmd,
  OpDos,
  OpFrame,
  OpWindow,
  {$IFDEF UseDrag}                      {!!.06}
  OpDrag,                               {!!.06}
  {$ENDIF}                              {!!.06}
  Filer,
  VRec;

  {$I FBROWSE.ICD}  {configuration data}

const
  {option codes}
  fbScrollByPage   = $00000001; {scroll by page?}
  fbMousePage      = $00000002; {clicking on scroll bar scrolls by page}
  fbDrawActive     = $00000004; {Draw and Process leave selected item visible}
  fbUseReadLock    = $00000008; {use read locks while building pages?}
  fbAutoScale      = $00000010; {scale scroll bar based on low/high keys?}
  fbForceUpdate    = $00000020; {force the screen to be updated}
  fbFlushKbd       = $00000040; {flush keyboard buffer at boundaries}
  fbBellOnFlush    = $00000080; {ring bell when flushing?}
  fbBuildOnKey     = $00000100; {build function needs only the key}
  fbCenterCurrent  = $00000200; {center new record in SetCurrentRecord} {!!.07}
  fbProcessZero    = $00000400; {allow Process of zero records}         {!!.22}
  fbSelectOnClick  = $00000800; {implicit Enter on first mouse click}   {!!.40}

  fbChangedItems   = $04000000; {internal flags}                        {!!.40}
  fbFakingOneRec   = $08000000;                                         {!!.22}
  fbLockPending    = $10000000;
  fbForceRedraw    = $20000000;
  fbIsNet          = $40000000;
  fbInProcess      = $80000000;

  DefFBrowserOptions : LongInt =
    {$IFDEF UseDrag} fbSelectOnClick+ {$ENDIF}                          {!!.40}
    fbMousePage+fbDrawActive+fbAutoScale+fbUseReadLock;                 {!!.23}
  BadFBrowserOptions : LongInt =
    fbChangedItems+fbLockPending+fbForceRedraw+fbIsNet+fbInProcess;     {!!.40}

  DefRetriesOnLock : Integer = 50;

type
  ItemRowsArray = array[1..1] of StringPtr; {variably sized}
  ItemRowsPtr = ^ItemRowsArray;
  ItemRec =
    record
      irKey  : IsamKeyStr;
      irRef  : LongInt;
      irLen  : Word;
      irRows : ItemRowsPtr;
    end;
  ItemRecArray = array[1..100] of ItemRec; {size is arbitrary}

type
  FBrowserPtr = ^FBrowser;
  BuildItemProc =
    procedure (Row : Byte; var DatS; Len : Word; RecNum : LongInt;
               Key : IsamKeyStr; var S : string; FBP : FBrowserPtr);
  SpecialTaskProc =
    procedure (RecNum : LongInt; Key : IsamKeyStr; FBP : FBrowserPtr);
  FilterFunc =
    function (RecNum : LongInt; Key : IsamKeyStr; FBP : FBrowserPtr) : Boolean;
  UpdateProc =
    procedure (FBP : FBrowserPtr);
  RefreshFunc =
    function (FBP : FBrowserPtr) : Boolean;

  FBrowser =    {browser for fixed-length record Fileblocks}
    object(CommandWindow)
      {----------------------------Procedure pointers}
      fbPreMove,                  {called before each user-generated command}
      fbTask : SpecialTaskProc;   {user-defined special task hook}
      fbBuildItem : BuildItemProc; {user-supplied function to build an item}
      fbUpdate : UpdateProc;      {called on each screen update}
      fbFilter : FilterFunc;      {record filter}
      fbRefresh : RefreshFunc;    {called to determine if screen refresh needed}
      {----------------------------Fileblock stuff}
      fbIFB : IsamFileBlockPtr;   {file block pointer}
      fbDatPtr : Pointer;         {pointer to record buffer}
      fbKeyNum : Integer;         {key number}
      fbLowKey : IsamKeyStr;      {low key}
      fbHighKey : IsamKeyStr;     {high key}
      fbCurKey : IsamKeyStr;      {current key}
      fbCurRef : LongInt;         {current record number}
      fbRetries : Integer;        {# of retries in case of a lock error}
      {----------------------------Window stuff}
      fbItemRecs : ^ItemRecArray; {array of item records}
      fbMaxItems : Byte;          {maximum items per window}
      fbMaxRows : Byte;           {maximum rows per window}
      fbRowsPerItem : Byte;       {number of rows for each item}
      fbMaxCols : Word;           {maximum columns per row}
      fbCurItem : Byte;           {current item}
      fbColOfs : Word;            {horizontal scrolling factor}
      fbFirstCol : Word;          {first column in memory}
      fbOptions : LongInt;        {option flags}
      fbHDelta : Byte;            {columns to jump--horizontal scroll}
      fbVDelta : Byte;            {rows (items) to jump--vertical scroll}
    {$IFDEF UseAdjustableWindows}
      {----------------------------Other window stuff}
      fbLastHeight : Byte;        {window height on last UpdateContents call}
      {$IFDEF UseScrollBars}
      fbLastWidth : Byte;         {window width on last UpdateContents call}
      {$ENDIF}
    {$ENDIF}
    {$IFDEF UseScrollBars}
      {----------------------------Scroll bar stuff}
      fbBDelta : Byte;            {columns to jump--horizontal scroll (bar)}
      fbScaleLow : Word;          {scroll bar scale--fbLowKey}
    {$ENDIF}
      {----------------------------Colors}
      fbItemColor : Byte;         {unselected items}
      fbItemMono : Byte;
      fbSelColor : Byte;          {selected items}
      fbSelMono : Byte;
      fbDummy   : record end;     {marks end of data fields}
    {$IFDEF UseScrollBars}                                                 {!!.07}
      fbRelPos : Word;            {vertical scroll bar--relative position} {!!.07}
    {$ENDIF}                                                               {!!.07}
      {....methods....}
      constructor Init(X1, Y1, X2, Y2 : Byte;
                       IFBPtr : IsamFileBlockPtr;
                       KeyNum : Integer;
                       var DatS;
                       MaxRows, RowsPerItem : Byte;
                       MaxCols : Word);
        {-Initialize with default window options}
      constructor InitCustom(X1, Y1, X2, Y2 : Byte;
                             var Colors : ColorSet;
                             Options : LongInt;
                             IFBPtr : IsamFileBlockPtr;
                             KeyNum : Integer;
                             var DatS;
                             MaxRows, RowsPerItem : Byte;
                             MaxCols : Word);
        {-Initialize with custom window options}
      destructor Done; virtual;
        {-Deallocate item records}
      procedure ProcessSelf; virtual;
        {-Process browse commands}
      {...}
      procedure fbOptionsOn(OptionFlags : LongInt);
        {-Activate multiple options}
      procedure fbOptionsOff(OptionFlags : LongInt);
        {-Deactivate multiple options}
      function fbOptionsAreOn(OptionFlags : LongInt) : Boolean;
        {-Return True if all specified options are on}
      {...}
      function GetFileBlockPtr : IsamFileBlockPtr;
        {-Get pointer to associated fileblock}
      function GetKeyNumber : Integer;
        {-Get current index key number}
      function GetCurrentItem : Byte;
        {-Get number of currently highlighted item}
      function GetCurrentCol : Word;
        {-Get column currently displayed at left edge of window}
      function GetFirstCol : Word;
        {-Get first column of data to be loaded into memory}
      procedure GetCurrentKeyAndRef(var Key : IsamKeyStr; var Ref : LongInt);
        {-Retrieve current key and record number}
      procedure GetCurrentRecord(var DatS; var DatLen : Word);
        {-Retrieve current record}
      function GetItemString(Item, Row : Byte) : string; virtual; {!!.06}
        {-Get string corresponding to specified Row of specified Item}
      {...}
      procedure SetFileBlockPtr(IFBPtr : IsamFileBlockPtr); {!!.07}
        {-Set pointer to associated fileblock (after rebuild)}
      procedure SetCurrentRecord(Key : IsamKeyStr; Ref : LongInt);
        {-Set the current record}
      procedure SetKeyRange(LowKey, HighKey : IsamKeyStr);
        {-Set subrange of valid keys}
      procedure SetKeyNumber(KeyNum : Integer);
        {-Switch index keys}
      procedure SetRetries(Retries : Integer);
        {-Set number of times to retry on read operations}
      {...}
      procedure SetNormAttr(Color, Mono : Byte);
        {-Set attribute for unselected items}
      procedure SetSelectAttr(Color, Mono : Byte);
        {-Set attribute for selected items}
      {...}
      procedure SetHorizScrollDelta(Delta : Byte);
        {-Set columns to jump when scrolling horizontally}
      procedure SetVertScrollDelta(Delta : Byte);
        {-Set rows (items) to jump when scrolling vertically}
      {$IFDEF UseScrollBars}
      procedure SetHorizScrollBarDelta(Delta : Byte);
        {-Set columns to jump when scrolling horizontally (scroll bar)}
      {$ENDIF}
      {...}
      procedure SetBuildItemProc(BIF : BuildItemProc);
        {-Set procedure to build an item}
      procedure SetFilterFunc(FF : FilterFunc);
        {-Set record filtering function}
      function IsFilteringEnabled : Boolean; virtual;
        {-Return True if filtering is enabled}
      procedure SetSpecialTaskProc(STP : SpecialTaskProc);
        {-Set user-defined special task hook}
      procedure SetPreMoveProc(PMP : SpecialTaskProc);
        {-Set user-defined procedure to call before each command}
      procedure SetScreenUpdateProc(SUP : UpdateProc);
        {-Set user-defined procedure to call on each screen update}
      procedure SetRefreshFunc(RF : RefreshFunc);
        {-Set routine called to determine if screen refresh is needed}
      {...}
      procedure CharHook; virtual;
        {-Called each time a regular character is entered by user}
      procedure CursorLeft; virtual;
        {-Called to process the ccLeft command}
      procedure CursorRight; virtual;
        {-Called to process the ccRight command}
      procedure ScreenUpdate; virtual;
        {-Called on each screen update; when current item/column changes}
      procedure PreMove; virtual;
        {-Called just prior to getting each keyboard command}
      procedure DrawItem(Item : Byte; Highlight : Boolean); virtual;
        {-Draw the specified (relative) Item of the browse window}
      procedure BuildOneItem(Item : Byte; Locked : Boolean); virtual;
        {-Convert specified item to a string}
      procedure BuildOneRow(Row : Byte; var DatS; Len : Word; RecNum : LongInt;
                            Key : IsamKeyStr; var S : string); virtual; {!!.06}
        {-Convert specified row of specified item to a string}          {!!.06}
      function RecordFilter(RecNum : LongInt; Key : IsamKeyStr) : Boolean; virtual;
        {-Return True if this record should be displayed}
      procedure SpecialTask; virtual;
        {-Special task hook}
      function NeedRefresh : Boolean; virtual;
        {-Do we need to refresh the display?}
      procedure GetRecord(Ref : LongInt; var DatS; var Len : Word); virtual;
        {-Low-level routine to read a specific record}
    {$IFDEF UseStreams}
      constructor Load(var S : IdStream);
        {-Load a file browser from a stream}
      procedure Store(var S : IdStream);
        {-Store a file browser in a stream}
    {$ENDIF}
{.Z+}
      {+++ internal methods +++}
    {$IFDEF UseScrollBars}     {!!.06}
      procedure Draw; virtual; {!!.06}
    {$ENDIF}                   {!!.06}
      procedure fbGotError(ErrorCode : Word; ErrorMsg : string); virtual; {!!.22}
      procedure UpdateContents; virtual;
      procedure fbCheckLoadedColumns;
      procedure fbReadLock(Lock : Boolean);
      procedure fbNextKeyPrim(var Ref : LongInt; var Key : IsamKeyStr);
      procedure fbSearchKeyPrim(var Ref : LongInt; var Key : IsamKeyStr);
      procedure fbPrevKeyPrim(var Ref : LongInt; var Key : IsamKeyStr);
      procedure fbFindKeyPrim(var Ref : LongInt; var Key : IsamKeyStr;
                              NFSD : Integer);
      procedure fbNextKey(var Ref : LongInt; var Key : IsamKeyStr);
      procedure fbSearchKey(var Ref : LongInt; var Key : IsamKeyStr);
      procedure fbPrevKey(var Ref : LongInt; var Key : IsamKeyStr);
      procedure fbFindKey(var Ref : LongInt; var Key : IsamKeyStr;
                          NFSD : Integer);
      function  fbKeyInBounds(var Key : IsamKeyStr) : Boolean;
      procedure fbScrollItemRecs(Delta, LastItem : Integer);
      procedure fbBuildCurPage(Desired : Byte);
      function  fbLastValidItem : Byte;
      procedure fbGotoItem(Item : Byte);
      function  fbDisplayItems : Byte;
      function  fbOnePage(LessOne : Boolean) : Integer;
      procedure fbLineUp;
      procedure fbLineDown;
      procedure fbPageUp;
      procedure fbPageDown;
      procedure fbFlushKeyboard;
      procedure fbScrollVert(ScDelta, HiDelta : Integer);
      procedure fbScrollHoriz(Delta : Integer);
      procedure fbFirstRec;
      procedure fbLastRec;
      procedure fbEmptyItemRec(I : Byte);
      procedure fbEmptyBrowScreen;
      function  fbCurRecExists : Boolean;
      procedure fbPositionCursor;
    {$IFDEF UseAdjustableWindows}
      procedure fbAdjustDisplay(NewH, OldH : Byte);
    {$ENDIF}
    {$IFDEF UseScrollBars}
      procedure fbSetupForScrollBars;
      procedure fbUpdateScrollBars(DoVert : Boolean);
    {$ENDIF}
    {$IFDEF UseMouse}
      procedure fbGotoRelPos(P : LongInt);
      function  fbProcessMouseCommand(Cmd : Word) : Boolean; {!!.24}
    {$ENDIF}
{.Z-}
    end;

  VBrowserPtr = ^VBrowser;
  VBrowser =   {browser for variable-length record Fileblocks}
    object(FBrowser)
      procedure GetRecord(Ref : LongInt; var DatS; var Len : Word); virtual;
        {-Low-level routine to read a specific record}
    end;

  {-------------------------------------------------------}

  function NullFilterFunc(RecNum : LongInt; Key : IsamKeyStr;
                          FBP : FBrowserPtr) : Boolean;
    {-Do-nothing record filtering function}

  function NullRefreshFunc(FBP : FBrowserPtr) : Boolean;
    {-Do-nothing refresh function}

  function RefreshAtEachCommand(FBP : FBrowserPtr) : Boolean;
    {-Check for need to refresh before each command if no keystrokes pending}

const
  RefreshPeriod : Word = 18*5;

  function RefreshPeriodically(FBP : FBrowserPtr) : Boolean;
    {-Check for need to refresh every RefreshPeriod clock ticks}

{$IFDEF UseStreams}
{.Z+}
  procedure FBrowserStream(SPtr : IdStreamPtr);
    {-Register all types needed for streams containing file browsers}
  procedure VBrowserStream(SPtr : IdStreamPtr);
    {-Register all types needed for streams containing file browsers}
{.Z-}
{$ENDIF}

var
  {$IFDEF UseDrag}                      {!!.06}
  FBrowserCommands : DragProcessor;     {!!.06}
  {$ELSE}                               {!!.06}
  FBrowserCommands : CommandProcessor;
  {$ENDIF}                              {!!.06}

  {=======================================================================}

implementation

const
  ScaleHigh = 32768;

  {$I FBROWSE.IN1} {mouse, scroll bars, streams, refresh/filter funcs, etc.}

  constructor FBrowser.Init(X1, Y1, X2, Y2 : Byte;
                            IFBPtr : IsamFileBlockPtr;
                            KeyNum : Integer;
                            var DatS;
                            MaxRows, RowsPerItem : Byte;
                            MaxCols : Word);
    {-Initialize with default window options}
  begin
    if not FBrowser.InitCustom(X1, Y1, X2, Y2,
                               DefaultColorSet, DefWindowOptions,
                               IFBPtr, KeyNum, DatS,
                               MaxRows, RowsPerItem, MaxCols) then
      Fail;
  end;

  constructor FBrowser.InitCustom(X1, Y1, X2, Y2 : Byte;
                                  var Colors : ColorSet;
                                  Options : LongInt;
                                  IFBPtr : IsamFileBlockPtr;
                                  KeyNum : Integer;
                                  var DatS;
                                  MaxRows, RowsPerItem : Byte;
                                  MaxCols : Word);
    {-Initialize with custom window options}
  var
    I, J, M, N, C : Word;
  begin
    {in case we fail...}
    fbItemRecs := nil;

    {force wUserContents on}
    SetLongFlag(Options, wUserContents);

    {make sure the Fileblock is indexed}
    if IFBPtr^.NrOfKeys = 0 then begin
      InitStatus := epFatal+ecNoIndex;
      Fail;
    end;

    {initialize the window}
    if not CommandWindow.InitCustom(X1, Y1, X2, Y2, Colors, Options,
                                    FBrowserCommands, ucFBrowser) then
      Fail;

    {calculate rows, columns, etc.}
    if RowsPerItem = 0 then
      RowsPerItem := 1;
    if MaxRows = 0 then
      MaxRows := Height;
    fbMaxRows := MaxRows;
    fbMaxItems := MaxRows div RowsPerItem;
    {make sure window is high enough}
    if (Height < RowsPerItem) or (fbMaxItems = 0) then begin
      InitStatus := epFatal+ecWinTooSmall;
      Done;
      Fail;
    end;
    {$IFDEF UseAdjustableWindows}
    {set the limits to use when resizing the window}
    SetSizeLimits(wMinW, MaxWord(wMinH, RowsPerItem), wMaxW, wMaxH);
    {$ENDIF}
    fbRowsPerItem := RowsPerItem;
    if MaxCols = 0 then
      MaxCols := Width;
    fbMaxCols := MaxCols;

    {initialize data fields}
    fbOptions := DefFBrowserOptions;
    {$IFDEF BTree52}
    if BTIsNetFileBlock(IFBptr) then
    {$ELSE}
    if IsNetFileBlock(IFBptr) then
    {$ENDIF}
      SetLongFlag(fbOptions, fbIsNet)
    else
      ClearLongFlag(fbOptions, fbIsNet);
    fbIFB := IFBPtr;
    fbKeyNum := 1;
    fbDatPtr := @DatS;
  {$IFDEF UseAdjustableWindows}
    fbLastHeight := fbDisplayItems;
    {$IFDEF UseScrollBars}
    fbLastWidth := Width;
    {$ENDIF}
  {$ENDIF}
    fbColOfs := 0;
    fbFirstCol := 1;
    fbCurItem := 1;
    fbCurRef := 1;
    fbHDelta := 1;
    fbVDelta := 1;
  {$IFDEF UseScrollBars}
    fbBDelta := 10;
  {$ENDIF}
    @fbTask  := nil;
    @fbBuildItem := nil;
    fbFilter := NullFilterFunc;
    @fbPreMove := nil;
    @fbUpdate := nil;
    fbRefresh := NullRefreshFunc;
    fbRetries := DefRetriesOnLock;

    {set colors}
    fbItemColor := Colors.TextColor;
    fbItemMono := Colors.TextMono;
    fbSelColor := Colors.SelItemColor;
    fbSelMono := Colors.SelItemMono;

    {select hidden cursor}
    SetCursor(cuHidden);

    {assume that we're out of memory}
    InitStatus := epFatal+ecOutOfMemory;

    {allocate the item records array}
    M := Word(fbMaxItems)*SizeOf(ItemRec);
    if not GetMemCheck(fbItemRecs, M) then begin
      Done;
      Fail;
    end;

    {initialize the array}
    FillChar(fbItemRecs^, M, 0);

    {allocate the string pointers}
    M := MinWord(MaxCols, 255)+1;
    N := RowsPerItem*SizeOf(Pointer);
    for I := 1 to fbMaxItems do
      with fbItemRecs^[I] do begin
        if not GetMemCheck(irRows, N) then begin
          Done;
          Fail;
        end
        else begin
          FillChar(irRows^, N, 0);
          for J := 1 to RowsPerItem do
            if GetMemCheck(irRows^[J], M) then
              {initialize the string}
              FillChar(irRows^[J]^, M, 0)
            else begin
              Done;
              Fail;
            end;
        end;
      end;

    {set key number and default key range}
    SetKeyNumber(KeyNum);
    SetKeyRange('', '');

    {clear InitStatus}   {!!.06}
    InitStatus := 0;     {!!.06}
  end;

  destructor FBrowser.Done;
    {-Deallocate row records}
  var
    I, J : Word;
  begin
    if fbItemRecs <> nil then begin
      {deallocate individual item records}
      for I := 1 to fbMaxItems do
        with fbItemRecs^[I] do
          if irRows <> nil then begin
            {deallocate the individual strings}
            for J := 1 to fbRowsPerItem do
              FreeMemCheck(irRows^[J], MinWord(fbMaxCols, 255)+1);

            {deallocate the array of strings}
            FreeMemCheck(irRows, fbRowsPerItem*SizeOf(Pointer));
          end;

      {deallocate the item records array}
      FreeMemCheck(fbItemRecs, fbMaxItems*SizeOf(ItemRec));
    end;

    {call ancestor's destructor}
    CommandWindow.Done;
  end;

  procedure FBrowser.fbGotError(ErrorCode : Word; ErrorMsg : string); {!!.22}
    {-To be called when an error occurs}
  var                                                                 {!!.42}
    SavedIsamError : integer;                                         {!!.42}
  begin
    SavedIsamError := IsamError;                                      {!!.42}
    fbReadLock(False);
    IsamError := SavedIsamError;                                      {!!.42}
    IsamOk := IsamError = 0;                                          {!!.42}
    GotError(ErrorCode, ErrorMsg);
  end;

  procedure FBrowser.fbOptionsOn(OptionFlags : LongInt);
    {-Activate multiple options}
  begin
    SetLongFlag(fbOptions, OptionFlags and not BadFBrowserOptions);
  end;

  procedure FBrowser.fbOptionsOff(OptionFlags : LongInt);
    {-Deactivate multiple options}
  begin
    ClearLongFlag(fbOptions, OptionFlags and not BadFBrowserOptions);
  end;

  function FBrowser.fbOptionsAreOn(OptionFlags : LongInt) : Boolean;
    {-Return true if all specified options are on}
  begin
    fbOptionsAreOn := (fbOptions and OptionFlags = OptionFlags);
  end;

  procedure FBrowser.SetNormAttr(Color, Mono : Byte);
    {-Set attribute for unselected items}
  begin
    fbItemColor := Color;
    fbItemMono := MapMono(Color, Mono);
  end;

  procedure FBrowser.SetSelectAttr(Color, Mono : Byte);
    {-Set attribute for selected items}
  begin
    fbSelColor := Color;
    fbSelMono := MapMono(Color, Mono);
  end;

  procedure FBrowser.SetBuildItemProc(BIF : BuildItemProc);
    {-Set function to build an item}
  begin
    fbBuildItem := BIF;
  end;

  procedure FBrowser.SetFilterFunc(FF : FilterFunc);
    {-Set record filtering function}
  begin
    fbFilter := FF;
    SetLongFlag(fbOptions, fbForceUpdate);
  end;

  procedure FBrowser.SetSpecialTaskProc(STP : SpecialTaskProc);
    {-Set user-defined special task hook}
  begin
    fbTask := STP;
  end;

  procedure FBrowser.SetPreMoveProc(PMP : SpecialTaskProc);
    {-Set user-defined procedure to call before each command}
  begin
    fbPreMove := PMP;
  end;

  procedure FBrowser.SetScreenUpdateProc(SUP : UpdateProc);
    {-Set user-defined procedure to call on each screen update}
  begin
    fbUpdate := SUP;
  end;

  procedure FBrowser.SetRefreshFunc(RF : RefreshFunc);
    {-Set routine called to determine if screen refresh is needed}
  begin
    fbRefresh := RF;
  end;

  procedure FBrowser.SetHorizScrollDelta(Delta : Byte);
    {-Set columns to jump when scrolling horizontally}
  begin
    fbHDelta := Delta;
  end;

  procedure FBrowser.SetVertScrollDelta(Delta : Byte);
    {-Set rows (items) to jump when scrolling vertically}
  begin
    fbVDelta := Delta;
  end;

{$IFDEF UseScrollBars}
  procedure FBrowser.SetHorizScrollBarDelta(Delta : Byte);
    {-Set columns to jump when scrolling horizontally (scroll bar)}
  begin
    fbBDelta := Delta;
  end;
{$ENDIF}

  function FBrowser.GetFileBlockPtr : IsamFileBlockPtr;
    {-Get pointer to associated fileblock}
  begin
    GetFileBlockPtr := fbIFB;
  end;

  function FBrowser.GetKeyNumber : Integer;
    {-Get current index key number}
  begin
    GetKeyNumber := fbKeyNum;
  end;

  function FBrowser.GetCurrentItem : Byte;
    {-Get number of currently highlighted item}
  begin
    GetCurrentItem := fbCurItem;
  end;

  function FBrowser.GetCurrentCol : Word;
    {-Get column currently displayed at left edge of window}
  begin
    GetCurrentCol := fbColOfs+1;
  end;

  function FBrowser.GetFirstCol : Word;
    {-Get first column of data to be loaded into memory}
  begin
    GetFirstCol := fbFirstCol;
  end;

  function FBrowser.GetItemString(Item, Row : Byte) : string;
    {-Get string corresponding to specified Row of specified Item}
  begin
    GetItemString := fbItemRecs^[Item].irRows^[Row]^;
  end;

  procedure FBrowser.GetCurrentKeyAndRef(var Key : IsamKeyStr; var Ref : LongInt);
    {-Retrieve current key and record number}
  begin
    Key := fbCurKey;
    Ref := fbCurRef;
  end;

  procedure FBrowser.GetCurrentRecord(var DatS; var DatLen : Word);
    {-Retrieve current record}
  var
    RT : Integer;
  begin
    if fbCurRef = 0 then
      DatLen := 0
    else begin
      RT := 0;
      repeat
        if RT <> 0 then                                       {!!.22}
          Delay(30);                                          {!!.22}
        GetRecord(fbCurRef, DatS, DatLen);
        Inc(RT);
      until (RT >= fbRetries) or (ErrorClass <> 2);
    end;
  end;

  procedure FBrowser.SetFileBlockPtr(IFBPtr : IsamFileBlockPtr); {!!.07}
    {-Set pointer to associated fileblock (after rebuild)}
  begin
    fbIFB := IFBptr;
  end;

  procedure FBrowser.SetCurrentRecord(Key : IsamKeyStr; Ref : LongInt);
    {-Set the current record}
  var
    I, DI : Word;
  begin
    if Ref = 0 then                            {!!.07}
      Ref := 1;                                {!!.07}

    if Key < fbLowKey then begin               {!!.06}
      Key := fbLowKey;                         {!!.06}
      Ref := 1;                                {!!.06}
    end                                        {!!.06}
    else if Key > fbHighKey then begin         {!!.06}
      Key := fbHighKey;                        {!!.06}
      Ref := MaxLongInt;                       {!!.06}
    end;                                       {!!.06}

    {is it already displayed?}
    DI := fbDisplayItems;
    if fbItemRecs^[1].irRef <> 0 then
      for I := 1 to DI do
        with fbItemRecs^[I] do
          if (irRef = Ref) and (Key = irKey) then begin
            if I <> fbCurItem then
              fbGotoItem(I);
            Exit;
          end;

    {set current item, etc.}
    if Ref <> fbCurRef then
      if LongFlagIsSet(fbOptions, fbCenterCurrent) then {!!.07}
        fbCurItem := MinWord(Succ(DI div 2), DI)        {!!.07}
      else if Key > fbCurKey then                       {!!.07}
        fbCurItem := DI
      else
        fbCurItem := 1;
    fbCurKey := Key;
    fbCurRef := Ref;

    {mark the screen as empty}
    fbEmptyBrowScreen;

    {update the screen if the window is current}
    if IsCurrent then
      UpdateContents;
  end;

  procedure FBrowser.SetKeyRange(LowKey, HighKey : IsamKeyStr);
    {-Set subrange of valid keys}
  begin
    if HighKey >= LowKey then
      if not LongFlagIsSet(fbOptions, fbInProcess) then begin
        fbLowKey := LowKey;
        fbHighKey := PadCh(HighKey, #$FF, SizeOf(fbHighKey)-1);
        fbCurKey := fbLowKey;
        {$IFDEF UseScrollBars}
        fbScaleLow := $FFFF;
        {$ENDIF}
        fbEmptyBrowScreen;
      end;
  end;

  procedure FBrowser.SetKeyNumber(KeyNum : Integer);
    {-Switch index keys}
  begin
    if not LongFlagIsSet(fbOptions, fbInProcess) then
      if (KeyNum > 0) and (KeyNum <= fbIFB^.NrOfKeys) then begin
        fbKeyNum := KeyNum;
        SetKeyRange('', '');
      end;
  end;

  procedure FBrowser.SetRetries(Retries : Integer);
    {-Set number of times to retry on read operations}
  begin
    fbRetries := Retries;
  end;

  procedure FBrowser.BuildOneRow(Row : Byte; var DatS; Len : Word;    {!!.06}
                                 RecNum : LongInt; Key : IsamKeyStr;
                                 var S : string);
    {-Convert specified row of specified item to a string}
  begin
    if @fbBuildItem <> nil then
      fbBuildItem(Row, DatS, Len, RecNum, Key, S, @Self);
  end;

  procedure FBrowser.BuildOneItem(Item : Byte; Locked : Boolean);
    {-Convert specified item to a string}
  var
    S : string;
    SLen : Byte absolute S;
    R : Word;
    Ref : LongInt;
  begin
    with fbItemRecs^[Item] do begin
      for R := 1 to fbRowsPerItem do
        irRows^[R]^ := '';
      {if @fbBuildItem <> nil then begin}                {!!.06}
      if Locked then
        Ref := -1
      else begin
        Ref := irRef;
        if not LongFlagIsSet(fbOptions, fbBuildOnKey) then begin
          GetRecord(irRef, fbDatPtr^, irLen);
          case ErrorClass of
            0..1 : {ok};
            2    : Ref := -1;
            else begin
              fbGotError(epFatal+ecIsamError, emIsamError);
              Exit;
            end;
          end;
          IsamClearOK;
        end;
      end;

      for R := 1 to fbRowsPerItem do begin
        BuildOneRow(R, fbDatPtr^, irLen, Ref, irKey, S); {!!.06}
        if (ClassifyError(cwGetLastError) = etFatal) or  {!!.06}
           (ErrorClass > 2) then                     {!!.06}
          Exit;                                          {!!.06}
        SLen := MinWord(SLen, MinWord(fbMaxCols, 255));
        irRows^[R]^ := S;
      end;
      {end;}                                             {!!.06}
    end;
  end;

  procedure FBrowser.DrawItem(Item : Byte; Highlight : Boolean);
    {-Draw the specified (relative) Item of the browse window}
  var
    S : String;
    SLen : Byte absolute S;
    Attr : Byte;
    R, FRow, LRow, Start, I, W : Word;
    {$IFDEF UseMouse}
    SaveMouse : Boolean;
    {$ENDIF}
  begin
    {calculate first and last rows}
    FRow := Succ(Pred(Item) * fbRowsPerItem);
    if (Item = 0) or (FRow > Height) then
      Exit;
    Inc(FRow, Pred(wYL));
    LRow := FRow+Pred(fbRowsPerItem);

    {$IFDEF UseMouse}
    HideMousePrim(SaveMouse);
    {$ENDIF}

    {get the string}
    W := Width;
    if Item > fbMaxItems then begin
      Attr := ColorMono(wTextColor, wTextMono);
      for R := FRow to LRow do
        FastFill(W, ' ', R+Pred(wYL), wXL, Attr);
    end
    else begin
      if Highlight then
        Attr := ColorMono(fbSelColor, fbSelMono)
      else
        Attr := ColorMono(fbItemColor, fbItemMono);

      {calculate starting column for the text we want}
      Start := Succ(fbColOfs)-Pred(fbFirstCol);

      for I := 1 to fbRowsPerItem do begin
        {extract the appropriate substring}
        S := Copy(GetItemString(Item, I), Start, W); {!!.06}

        {adjust the string as necessary}
        if SLen < W then begin
          FillChar(S[SLen+1], W-SLen, ' ');
          SLen := W;
        end;

        {draw the string}
        FastWrite(S, FRow+Pred(I), wXL, Attr);
      end;
    end;

    {$IFDEF UseMouse}
    ShowMousePrim(SaveMouse);
    {$ENDIF}
  end;

  procedure FBrowser.fbPositionCursor;
    {-Position the cursor at the start of the current item}
  begin
    {calculate first and last rows}
    GotoXY(1, Succ(Pred(fbCurItem) * fbRowsPerItem));
  end;

  function FBrowser.RecordFilter(RecNum : LongInt; Key : IsamKeyStr) : Boolean;
    {-Return True if this record should be displayed}
  begin
    if not fbKeyInBounds(Key) then                  {!!.24}
      RecordFilter := True                          {!!.24}
    else                                            {!!.24}
      RecordFilter := fbFilter(RecNum, Key, @Self);
  end;

  function FBrowser.IsFilteringEnabled : Boolean;
    {-Return True if filtering is enabled}
  begin
    IsFilteringEnabled := @fbFilter <> @NullFilterFunc;
  end;

  function FBrowser.fbDisplayItems : Byte;
    {-Number of items to be displayed}
  var
    Rows : Byte;
  begin
    if fbMaxRows <= Height then
      Rows := fbMaxRows
    else
      Rows := Height;
    fbDisplayItems := Rows div fbRowsPerItem;
  end;

  procedure FBrowser.fbCheckLoadedColumns;
    {-Make sure the right columns are loaded into memory}
  var
    I, CO, LCN, LCH : Word;
    NewFC : Integer;
  begin
    {nothing to do unless max columns > 255}
    if fbMaxCols <= 255 then
      Exit;

    {calculate last column that we need loaded}
    LCN := fbColOfs{+1} + Width{-1};

    {calculate last column that we have}
    LCH := fbFirstCol+254;

    {do we have the right columns loaded?}
    CO := Succ(fbColOfs);
    if (CO < fbFirstCol) then begin
      NewFC := LCN-254;
      if NewFC < 1 then
        NewFC := 1;
    end
    else if (LCN > LCH) then
      {make current column the first one loaded--we're scrolling right}
      NewFC := CO
    else
      {nothing to do}
      Exit;

    {rebuild the current page}
    fbFirstCol := NewFC;
    fbBuildCurPage(fbCurItem);
  end;

{$IFDEF UseScrollBars}    {!!.06}
  procedure FBrowser.Draw;
    {-Reset scroll bars if fbForceUpdate is set}
  begin
    if LongFlagIsSet(fbOptions, fbForceUpdate) then
      fbScaleLow := $FFFF;
    CommandWindow.Draw;
  end;
{$ENDIF}

  procedure FBrowser.UpdateContents;
    {-Redraw the complete browse window}
  var
    I, DI, FRow : Word;
    Attr : Byte;
    HOK : Boolean;
    MaxCO : Integer;
    {$IFDEF UseMouse}
    SaveMouse : Boolean;
    {$ENDIF}
  begin
    {check for pending errors}
    if cwGetLastError <> 0 then
      Exit;

    {build current page if necessary}
    if LongFlagIsSet(fbOptions, fbForceUpdate+fbLockPending) then begin
      fbBuildCurPage(fbCurItem);
  {$IFNDEF UseAdjustableWindows}
      {make sure the right columns are loaded into memory}
      fbCheckLoadedColumns;
    end;
  {$ELSE}
    end
    {adjust display if window has been resized}
    else begin
      DI := fbDisplayItems;
      if DI <> fbLastHeight then begin
        fbAdjustDisplay(DI, fbLastHeight);
        fbLastHeight := DI;
      end;
    end;

    if cwGetLastError = 0 then
      IsamClearOK
    else
      Exit;

    {see if we need to adjust column offset}
    MaxCO := fbMaxCols-Width;
    if MaxCO < 0 then
      MaxCO := 0;
    fbColOfs := MinWord(fbColOfs, MaxCO);

    {make sure the right columns are loaded into memory}
    fbCheckLoadedColumns;

    {$IFDEF UseScrollBars}
    {we'll need to reset scroll bars if width changed}
    DI := Width;
    if DI <> fbLastWidth then begin
      {request a reset}
      fbScaleLow := $FFFF;
      fbLastWidth := DI;
    end;
    {$ENDIF}
  {$ENDIF}

    {clear update and redraw flags}
    ClearLongFlag(fbOptions, fbForceUpdate+fbForceRedraw);

    {$IFDEF UseMouse}
    HideMousePrim(SaveMouse);
    {$ENDIF}

    {draw one page}
    HOK := LongFlagIsSet(fbOptions, fbDrawActive+fbInProcess);
    DI := fbDisplayItems;
    for I := 1 to DI do
      DrawItem(I, (I = fbCurItem) and HOK);

    {pad remainder of window with blank lines}
    FRow := Succ(DI * fbRowsPerItem);
    Attr := ColorMono(wTextColor, wTextMono);
    for I := FRow to Height do
      FastFill(Width, ' ', I+Pred(wYL), wXL, Attr);

    {$IFDEF UseScrollBars}
    {update scroll bars}
    fbUpdateScrollBars(True);
    {$ENDIF}

    {call user-written screen update routine}
    ScreenUpdate;

    {update child windows, if any}
    StackWindow.UpdateContents;

    {$IFDEF UseMouse}
    ShowMousePrim(SaveMouse);
    {$ENDIF}
  end;

  procedure FBrowser.fbEmptyItemRec(I : Byte);
    {-Empty the specified item record}
  var
    J : Word;
  begin
    with fbItemRecs^[I] do begin
      irKey := '';
      irRef := 0;
      for J := 1 to fbRowsPerItem do
        irRows^[J]^ := '';
      irLen := 0;
    end;
  end;

  procedure FBrowser.fbEmptyBrowScreen;
    {-Mark the browser screen as being empty}
  var
    I : Word;
  begin
    {clear all the item records}
    if fbItemRecs^[1].irRef <> 0 then
      for I := 1 to fbMaxItems do
        fbEmptyItemRec(I);

    {force complete screen update}
    SetLongFlag(fbOptions, fbForceUpdate+fbForceRedraw);
    ClearLongFlag(fbOptions, fbLockPending+fbFakingOneRec); {!!.22}
  end;

  procedure FBrowser.SpecialTask;
    {-Special task hook}
  begin
    if @fbTask = nil then
      cwCmd := ccNone
    else with fbItemRecs^[fbCurItem] do begin
      fbTask(irRef, irKey, @Self);
      if ErrorClass > 1 then
        fbGotError(epFatal+ecIsamError, emIsamError);
    end;
  end;

  function FBrowser.NeedRefresh : Boolean;
    {-Do we need to refresh the display?}
  begin
    NeedRefresh := fbRefresh(@Self);
  end;

  procedure FBrowser.PreMove;
    {-Called just prior to getting each keyboard command}
  begin
    if @fbPreMove <> nil then
      with fbItemRecs^[fbCurItem] do begin
        fbPreMove(irRef, irKey, @Self);
        if ErrorClass > 1 then
          fbGotError(epFatal+ecIsamError, emIsamError);
      end;
  end;

  procedure FBrowser.CharHook;
    {-Called each time a regular character is entered by user}
  begin
  end;

  procedure FBrowser.CursorLeft;
    {-Called to process the ccLeft command}
  begin
    fbScrollHoriz(-fbHDelta);
  end;

  procedure FBrowser.CursorRight;
    {-Called to process the ccRight command}
  begin
    fbScrollHoriz(+fbHDelta);
  end;

  procedure FBrowser.ScreenUpdate;
    {-Called on each screen update; when current row/column changes}
  begin
    if @fbUpdate <> nil then begin
      fbUpdate(@Self);
      if ErrorClass > 1 then
        fbGotError(epFatal+ecIsamError, emIsamError);
    end;
  end;

  function FBrowser.fbKeyInBounds(var Key : IsamKeyStr) : Boolean;
    {-Return True if fbLowKey <= Key <= fbHighKey}
  begin
    fbKeyInBounds := (Key >= fbLowKey) and (Key <= fbHighKey);
  end;

  procedure FBrowser.fbScrollItemRecs(Delta, LastItem : Integer);
    {-Scroll the item records up or down by Delta items}
  var
    I, J, N : Integer;
    IRP : ItemRowsPtr;
  begin
    N := SizeOf(ItemRec)*Pred(LastItem);
    if Delta < 0 then
      for I := 1 to Abs(Delta) do begin
        IRP := fbItemRecs^[1].irRows;
        MoveFast(fbItemRecs^[2], fbItemRecs^[1], N);
        fbItemRecs^[LastItem].irRows := IRP;
        fbEmptyItemRec(LastItem);
      end
    else
      for I := 1 to Delta do begin
        IRP := fbItemRecs^[LastItem].irRows;
        MoveFast(fbItemRecs^[1], fbItemRecs^[2], N);
        fbItemRecs^[1].irRows := IRP;
        fbEmptyItemRec(1);
      end;
  end;

  procedure FBrowser.fbReadLock(Lock : Boolean);
    {-Set or clear a read lock on the current Fileblock}
    {!!.41 retry logic removed}
    {!!.50 check for readlocked rewritten to allow use of DLL}
 {$IFDEF BTree52}
  var
    SavedError : integer;
    SavedOK    : boolean;
    IsLocked   : boolean;
  {$ENDIF}
  begin
    if fbOptionsAreOn(fbUseReadLock+fbIsNet) then begin
      {$IFDEF BTree52}
      SavedOK := IsamOk;
      SavedError := IsamError;
      IsLocked := BTFileBlockIsReadLocked(fbIFB);
      IsamOk := SavedOk;
      IsamError := SavedError;
      if (Lock = IsLocked) then
        Exit;
      if Lock then
        BTReadLockFileBlock(fbIFB)
      else
        BTUnLockFileBlock(fbIFB);
      {$ELSE}
      if Lock = fbIFB^.NSP^.ReadLocked then
        Exit;
      if Lock then
        ReadLockFileBlock(fbIFB)
      else
        UnLockFileBlock(fbIFB);
      {$ENDIF}
    end;
    IsamClearOK;
  end;

  procedure FBrowser.fbBuildCurPage(Desired : Byte); {!!.22} {modified}
    {-Build the current page}
  label
    ExitPoint;
  var
    I, J, DI  : Integer;
    Ref : LongInt;
    Key : IsamKeyStr;

    procedure FakeOneRecord;
    begin
      IsamClearOK;
      SetLongFlag(fbOptions, fbFakingOneRec);
      fbCurRef := 0;
      fbCurItem := 1;
      fbCurKey := fbLowKey; {!!.23}
    end;

  begin
    DI := fbDisplayItems;
    fbEmptyBrowScreen;

    {read-lock the file if desired}
    fbReadLock(True);

    Ref := fbCurRef;
    Key := fbCurKey;
    fbFindKey(Ref, Key, 1);
    case ErrorClass of
      0 : if not fbKeyInBounds(Key) then begin
            Ref := fbCurRef;
            Key := fbCurKey;
            fbFindKey(Ref, Key, -1);
            if not IsamOK then
              if LongFlagIsSet(fbOptions, fbProcessZero) then begin
                FakeOneRecord;
                goto ExitPoint;
              end
              else begin
                fbGotError(epFatal+ecNoKeysFound, emNoKeysFound);
                goto ExitPoint;
              end;
          end;
      1 : if IsamError = 10250 then begin
            Ref := fbCurRef;
            Key := fbCurKey;
            fbFindKey(Ref, Key, -1);
            if not IsamOK then
              if LongFlagIsSet(fbOptions, fbProcessZero) then begin
                FakeOneRecord;
                goto ExitPoint;
              end
              else begin
                fbGotError(epFatal+ecNoKeysFound, emNoKeysFound);
                goto ExitPoint;
              end;
          end
          else begin
            fbNextKey(Ref, Key);
            if not IsamOK then
              if LongFlagIsSet(fbOptions, fbProcessZero) then begin
                FakeOneRecord;
                goto ExitPoint;
              end
              else begin
                fbGotError(epFatal+ecNoKeysFound, emNoKeysFound);
                goto ExitPoint;
              end;
          end;
      2 :
        with fbItemRecs^[1] do begin
          SetLongFlag(fbOptions, fbLockPending);
          irRef := Ref;
          irKey := Key;
          BuildOneItem(1, True);
          fbCurItem := 1;
          fbGotError(epWarning+ecFileBlockLocked, emFileBlockLocked);
          ClearErrors;
          goto ExitPoint;
        end;
      else
        fbGotError(epFatal+ecIsamError, emIsamError);
        goto ExitPoint; {!!.06}
    end;

    I := Desired;
    while (I >= 1) and fbKeyInBounds(Key) and (ErrorClass = 0) do begin
      with fbItemRecs^[I] do begin
        irRef := Ref;
        irKey := Key;
        BuildOneItem(I, False);
        if ClassifyError(cwGetLastError) = etFatal then {!!.06}
          goto ExitPoint;                               {!!.06}
      end;
      Dec(I);
      if (I > 0) and (ErrorClass = 0) then begin
        fbPrevKey(Ref, Key);
        if ErrorClass > 1 then begin
          fbGotError(epFatal+ecIsamError, emIsamError);
          goto ExitPoint;
        end;
      end;
    end;
    if I > 0 then begin
      fbScrollItemRecs(-I, fbDisplayItems);
      Dec(Desired, I);
    end;
    if fbItemRecs^[1].irRef = 0 then begin
      if LongFlagIsSet(fbOptions, fbProcessZero) then
        FakeOneRecord
      else
        fbGotError(epFatal+ecNoKeysFound, emNoKeysFound);
      goto ExitPoint;
    end;
    if Desired = 0 then
      Desired := 1;
    if Desired < DI then begin
      fbFindKey(fbCurRef, fbCurKey, 1);
      if ErrorClass > 1 then begin
        fbGotError(epFatal+ecIsamError, emIsamError);
        goto ExitPoint;
      end;
      if ErrorClass = 0 then begin
        Ref := fbCurRef; {!!.24}
        Key := fbCurKey; {!!.24}
        fbNextKey(Ref, Key);
        I := Succ(Desired);
        while (I <= DI) and fbKeyInBounds(Key) and (ErrorClass = 0) do begin
          with fbItemRecs^[I] do begin
            irRef := Ref;
            irKey := Key;
            BuildOneItem(I, False);
            if ClassifyError(cwGetLastError) = etFatal then {!!.06}
              goto ExitPoint;                               {!!.06}
          end;
          Inc(I);
          if (I <= DI) and (ErrorClass = 0) then
            fbNextKey(Ref, Key);
        end;
      end
      else
        I := Desired;

      if Desired > I then
        fbCurItem := I
      else
        fbCurItem := Desired;
    end
    else
      fbCurItem := Desired;

    with fbItemRecs^[fbCurItem] do begin
      fbCurRef := irRef;
      fbCurKey := irKey;
    end;

    ClearLongFlag(fbOptions, fbForceUpdate);

ExitPoint:
    {release read-lock, preserving IsamError}
    I := IsamError;
    fbReadLock(False);
    IsamError := I;
  end;

  function FBrowser.fbLastValidItem : Byte;
    {-Return last item containing data}
  var
    I, DI : Word;
  begin
    fbLastValidItem := 1;
    DI := fbDisplayItems;
    for I := 2 to DI do
      if fbItemRecs^[I].irRef <> 0 then
        fbLastValidItem := I
      else
        Exit;
  end;

  procedure FBrowser.fbGotoItem(Item : Byte);
    {-Move highlight to the specified item}
  begin
    {don't move beyond last valid row}
    if Item > fbLastValidItem then
      Item := fbLastValidItem;

    {change highlight}
    if (fbCurItem <> Item) and IsCurrent then begin
      DrawItem(fbCurItem, False);
      DrawItem(Item, True);
      ScreenUpdate;
    end;

    {change current row/record}
    fbCurItem := Item;
    with fbItemRecs^[Item] do begin
      fbCurKey := irKey;
      fbCurRef := irRef;
    end;
  end;

  procedure FBrowser.fbFlushKeyboard;
    {-Flush the keyboard if desired}
  var
    K : Word;
  begin
    if LongFlagIsSet(fbOptions, fbFlushKbd) then
      with cwCmdPtr^ do
        while cpKeyPressed do begin
          K := cpGetKey;
          if LongFlagIsSet(fbOptions, fbBellOnFlush) then
            RingBell;
        end;
  end;

  procedure FBrowser.fbScrollVert(ScDelta, HiDelta : Integer);
    {-Scroll window up/down ScDelta items; move highlight by HiDelta items}

    procedure PlaceAtEnd(Ref : LongInt; Key : IsamKeyStr);
      {-Place the specified record at the bottom of the window}
    var
      I, DI : Integer;
    begin
      DI := fbDisplayItems;
      I := fbLastValidItem;
      if I < DI then
        with fbItemRecs^[I] do begin
          irKey := Key;
          irRef := Ref;
          BuildOneItem(I, False);
        end
      else begin
        fbScrollItemRecs(-1, fbDisplayItems);
        with fbItemRecs^[DI] do begin
          irKey := Key;
          irRef := Ref;
          BuildOneItem(DI, False);
        end;
      end;
    end;

    procedure PlaceAtTop(Ref : LongInt; Key : IsamKeyStr);
      {-Place the specified record at the top of the window}
    var
      I : Integer;
    begin
      fbScrollItemRecs(1, fbDisplayItems);
      with fbItemRecs^[1] do begin
        irKey := Key;
        irRef := Ref;
        BuildOneItem(1, False);
      end;
    end;

    procedure FileblockIsLocked;
      {-Can't scroll because the fileblock is locked}
    begin
      fbFlushKeyboard;
      fbGotError(epWarning+ecFileBlockLocked, emFileBlockLocked);
      ClearErrors;
    end;

    procedure BuildNextPage(Nr : Integer);
      {-Build next page}
    var
      I : Integer;
      Ref : LongInt;
      Key : IsamKeyStr;
    begin
      I := fbLastValidItem;
      if I = 0 then
        Exit;
      with fbItemRecs^[I] do begin
        Ref := irRef;
        Key := irKey;
      end;

      fbFindKey(Ref, Key, 0);
      case ErrorClass of
        0..1 : fbNextKey(Ref, Key);
      end;

      case ErrorClass of
        0 : ;
        1 : with fbItemRecs^[I] do begin
              fbCurRef := irRef;
              fbCurKey := irKey;
              fbBuildCurPage(I);
              fbFlushKeyboard;
              Exit;
            end;
        2 : begin
              FileblockIsLocked;
              Exit;
            end;
        else
          fbGotError(epFatal+ecIsamError, emIsamError);
          Exit;
      end;
      I := 1;
      while (I <= Nr) and fbKeyInBounds(Key) and (ErrorClass = 0) do begin
        PlaceAtEnd(Ref, Key);
        if ClassifyError(cwGetLastError) = etFatal then {!!.06}
          Exit;                                         {!!.06}
        Inc(I);
        if (I <= Nr) and (ErrorClass = 0) then begin
          fbNextKey(Ref, Key);
          if ErrorClass > 1 then begin
            fbGotError(epFatal+ecIsamError, emIsamError);
            Exit;
          end;
        end;
      end;

      if (I <= 1) or (HiDelta <> Nr) then
        fbCurItem := Integer(fbLastValidItem)-(Nr-HiDelta)-(Pred(I)-Nr);
    end;

    procedure BuildPrevPage(Nr : Integer);
      {-Build previous page}
    var
      I : Integer;
      Ref : LongInt;
      Key : IsamKeyStr;
    begin
      with fbItemRecs^[1] do begin
        if irRef = 0 then
          Exit;
        Ref := irRef;
        Key := irKey;
      end;

      fbFindKey(Ref, Key, 0);
      case ErrorClass of
        0 : fbPrevKey(Ref, Key);
        1 : fbFindKey(Ref, Key, -1);
      end;

      case ErrorClass of
        0 : ;
        1 : with fbItemRecs^[1] do begin
              fbCurKey := irKey;
              fbCurRef := irRef;
              fbBuildCurPage(1);
              fbFlushKeyboard;
              Exit;
            end;
        2 : begin
              FileblockIsLocked;
              Exit;
            end;
        else
          fbGotError(epFatal+ecIsamError, emIsamError);
          Exit;
      end;
      I := 1;
      while (I <= Nr) and fbKeyInBounds(Key) and (ErrorClass = 0) do begin
        PlaceAtTop(Ref, Key);
        if ClassifyError(cwGetLastError) = etFatal then {!!.06}
          Exit;                                         {!!.06}
        Inc(I);
        if (I <= Nr) and (ErrorClass = 0) then begin
          fbPrevKey(Ref, Key);
          if ErrorClass > 1 then begin
            fbGotError(epFatal+ecIsamError, emIsamError);
            Exit;
          end;
        end;
      end;

      if (I = 1) or (HiDelta <> Nr) then begin
        I := 1+(Nr-HiDelta)-(Nr-Pred(I));
        if I < 1 then
          fbCurItem := 1
        else
          fbCurItem := I;
      end;
    end;

  begin
    HiDelta := Abs(HiDelta);
    if ScDelta = 0 then
      Exit;
    if LongFlagIsSet(fbOptions, fbFakingOneRec) then {!!.22}
      Exit;                                          {!!.22}

    {read-lock the file if desired}
    fbReadLock(True);

    {build a new page}
    if ScDelta > 0 then
      BuildNextPage(ScDelta)
    else
      BuildPrevPage(-ScDelta);

    {release read-lock}
    fbReadLock(False);

    if fbCurItem < 1 then
      fbCurItem := 1
    else if fbCurItem > fbLastValidItem then
      fbCurItem := fbLastValidItem;
    with fbItemRecs^[fbCurItem] do begin
      fbCurKey := irKey;
      fbCurRef := irRef;
    end;

    {set redraw flag}
    SetLongFlag(fbOptions, fbForceRedraw);
  end;

  function FBrowser.fbOnePage(LessOne : Boolean) : Integer;
    {-Number of items to scroll on PgUp/PgDn}
  var
    DI : Word;
  begin
    DI := fbDisplayItems;
    if DI = 1 then
      fbOnePage := 1
    else
      fbOnePage := DI-Ord(LessOne);
  end;

  procedure FBrowser.fbLineUp;
    {-Cursor up one line}
  begin
    {just move highlight if possible}
    if fbCurItem > 1 then
      fbGotoItem(fbCurItem-1)
    else if LongFlagIsSet(fbOptions, fbScrollByPage) then
      fbScrollVert(-fbOnePage(False), -1)
    else
      fbScrollVert(-MinWord(fbVDelta, fbDisplayItems), -1);
  end;

  procedure FBrowser.fbLineDown;
    {-Cursor down one line}
  begin
    if fbCurItem < fbLastValidItem then
      fbGotoItem(fbCurItem+1)
    else if LongFlagIsSet(fbOptions, fbScrollByPage) then
      fbScrollVert(fbOnePage(False), 1)
    else
      fbScrollVert(MinWord(fbVDelta, fbDisplayItems), 1);
  end;

  procedure FBrowser.fbPageUp;
    {-Cursor up one page}
  var
    I : Integer;
  begin
    I := -fbOnePage(True);
    fbScrollVert(I, I);
  end;

  procedure FBrowser.fbPageDown;
    {-Cursor down one page}
  var
    I : Integer;
  begin
    I := fbOnePage(True);
    fbScrollVert(I, I);
  end;

  procedure FBrowser.fbScrollHoriz(Delta : Integer);
    {-Scroll horizontally delta columns}
  var
    NewCO, MaxCO : Integer;
  begin
    MaxCO := fbMaxCols-Width;
    NewCO := fbColOfs+Delta;

    if (NewCO < 0) or (MaxCO <= 0) then
      NewCO := 0
    else if NewCO > MaxCO then
      NewCO := MaxCO;

    if (NewCO <> fbColOfs) then begin
      fbColOfs := NewCO;
      UpdateContents;
    end;
  end;

  procedure FBrowser.fbFirstRec;
    {-Scroll to the first record in the file}
  var                                                {!!.07}
    B : Boolean;                                     {!!.07}
  begin
    if LongFlagIsSet(fbOptions, fbFakingOneRec) then {!!.22}
      Exit;                                          {!!.22}
    B := LongFlagIsSet(fbOptions, fbCenterCurrent);  {!!.07}
    ClearLongFlag(fbOptions, fbCenterCurrent);       {!!.07}
    SetCurrentRecord(fbLowKey, 1);
    if B then                                        {!!.07}
      SetLongFlag(fbOptions, fbCenterCurrent);       {!!.07}
  end;

  procedure FBrowser.fbLastRec;
    {-Scroll to the last record in the file}
  var                                                {!!.07}
    B : Boolean;                                     {!!.07}
  begin
    if LongFlagIsSet(fbOptions, fbFakingOneRec) then {!!.22}
      Exit;                                          {!!.22}
    B := LongFlagIsSet(fbOptions, fbCenterCurrent);  {!!.07}
    ClearLongFlag(fbOptions, fbCenterCurrent);       {!!.07}
    SetCurrentRecord(fbHighKey, MaxLongInt);
    if B then                                        {!!.07}
      SetLongFlag(fbOptions, fbCenterCurrent);       {!!.07}
  end;

  function FBrowser.fbCurRecExists : Boolean;
    {-Return True if currently highlighted record still exists and is
      unlocked}
  var
    Len : Word;
  begin
    fbCurRecExists := True;
    if LongFlagIsSet(fbOptions, fbFakingOneRec) then {!!.22}
      Exit;                                          {!!.22}
    {if LongFlagIsSet(fbOptions, fbIsNet) then begin}  {!!.06}
      GetCurrentRecord(fbDatPtr^, Len);
      if not IsamOK then begin
        {generate warning message and redraw screen}
        if ErrorClass = 2 then
          fbGotError(epWarning+ecRecordLocked, emRecordLocked)
        else
          fbGotError(epWarning+ecRecordGone, emRecordGone);
        ClearErrors;
        SetLongFlag(fbOptions, fbForceUpdate);
        fbCurRecExists := False;
      end;
    {end;}                                             {!!.06}
  end;

  procedure FBrowser.ProcessSelf;
    {-Process browse commands}
  label
    ErrorExit;
  var
    Finished, HaveNextCmd : Boolean;
    SFS : Boolean;
    {$IFDEF UseScrollBars}
    SaveColOfs : Byte;
    SaveRef : LongInt;
    HasBars : Boolean;
    {$ENDIF}
  begin
    {check for pending error}
    cwCmd := ccError;
    if cwGetLastError <> 0 then
      Exit;

    {Clear any other errors as well}
    ClearErrors;

    {Draw initial screen if not already done}
    SetLongFlag(fbOptions, fbInProcess);
    Draw;
    if (RawError <> 0) or (cwGetLastError <> 0) then begin
      ClearLongFlag(fbOptions, fbInProcess);
      Exit;
    end;

    {save SearchForSequential state and enable it}
    {$IFDEF BTree52}
    BTGetSearchForSequential(fbIFB, fbKeyNum, SFS);
    if not SFS then
      BTSetSearchForSequential(fbIFB, fbKeyNum, True);
    {$ELSE}
    TestSearchForSequential(fbIFB, fbKeyNum, SFS);
    if not SFS then
      EnableSearchForSequential(fbIFB, fbKeyNum);
    {$ENDIF}

    {initialize}
    Finished := False;
    HaveNextCmd := False;

    {$IFDEF UseScrollBars}
    HasBars := HasScrollBars;
    if HasBars then begin
      SaveColOfs := fbColOfs;
      SaveRef := fbCurRef;
    end;
    {$ENDIF}

    repeat
      {position the cursor at the start of the current item}
      fbPositionCursor;

      if not HaveNextCmd then begin
        {$IFDEF UseScrollBars}
        if HasBars then
          {update scroll bars if necessary}
          if (SaveColOfs <> fbColOfs) or (SaveRef <> fbCurRef) then begin
            fbUpdateScrollBars(SaveRef <> fbCurRef);
            SaveColOfs := fbColOfs;
            SaveRef := fbCurRef;
          end;
        {$ENDIF}

        {redraw screen if necessary}
        if LongFlagIsSet(fbOptions, fbForceUpdate+fbForceRedraw) then begin
          UpdateContents;
          if cwGetLastError <> 0 then
            goto ErrorExit;
        end;

        {Call user-defined routine prior to each user-generated command}
        PreMove;
        if cwGetLastError <> 0 then
          goto ErrorExit;

        {do we need to refresh the display?}
        if NeedRefresh then
          cwCmd := ccPlus
        else begin
          {get the next command}
          GetNextCommand;

          {is a fileblock lock pending?}
          if LongFlagIsSet(fbOptions, fbLockPending) then begin
            UpdateContents;
            if cwGetLastError <> 0 then
              cwCmd := ccError
            else if LongFlagIsSet(fbOptions, fbLockPending) then
              case cwCmd of
                {$IFDEF UseMouse}
                ccMouseSel,
                  {$IFDEF UseDrag}    {!!.06}
                  ccMouseAuto,        {!!.07}
                  ccMouseDown,        {!!.06}
                  {$ENDIF}            {!!.06}
                {$ENDIF}
                ccLeft, ccRight, ccHome, ccEnd, ccQuit, ccHelp,
                ccTask0..ccTask19, ccUser0..ccUser65335 :
                  {ok} ;
                else
                  {cancel the command}
                  cwCmd := ccNone;
              end;
          end;
        end;
      end;
      HaveNextCmd := False;

      {Execute command}
      case cwCmd of
        ccChar :
          CharHook;
        ccUp :
          fbLineUp;
        ccDown :
          fbLineDown;
        ccPageUp :
          fbPageUp;
        ccPageDn :
          fbPageDown;
        ccLeft :
          CursorLeft;
        ccRight :
          CursorRight;
        ccHome :
          fbScrollHoriz(-fbColOfs);
        ccEnd :
          fbScrollHoriz(fbMaxCols);
        ccFirstRec :
          fbFirstRec;
        ccLastRec :
          fbLastRec;
        ccPlus :
          SetLongFlag(fbOptions, fbForceUpdate);
        ccTask0..ccTask19 :
          begin
            SpecialTask;
            HaveNextCmd := (cwCmd <> ccNone);
          end;
        ccSelect :
          Finished := fbCurRecExists;
        ccQuit,
        ccUser0..ccUser65335 :
          Finished := True;
      {$IFDEF UseMouse}
        {$IFDEF UseDrag}    {!!.06}
        ccMouseAuto,        {!!.07}
        ccMouseDown,        {!!.06}
        {$ENDIF}            {!!.06}
        ccMouseSel :
          if fbProcessMouseCommand(cwCmd) then    {!!.24}
            if cwCmd = ccSelect then
              Finished := fbCurRecExists
            else
              Finished := (cwCmd <> ccMouseAuto); {!!.23}
      {$ENDIF}
        ccHelp :
          RequestHelp(wHelpIndex);
        else if (cwCmd <= 255) and (GetExitCommandPtr <> nil) then
          {Possibly a special exit command defined by a derived object}
          Finished := (cwCmd in GetExitCommandPtr^);
      end;

ErrorExit:
      if cwGetLastError <> 0 then
        cwCmd := ccError;

    until Finished or (cwCmd = ccError);

    {clear flag indicating that Process is active}
    ClearLongFlag(fbOptions, fbInProcess);

    {redraw screen if necessary}
    if LongFlagIsSet(fbOptions, fbForceUpdate+fbForceRedraw) then
      UpdateContents
    {redraw the current row unhighlighted if appropriate}
    else if not LongFlagIsSet(fbOptions, fbDrawActive) then
      DrawItem(fbCurItem, False);

    {restore state of SearchForSequential}
    if not SFS then
    {$IFDEF BTree52}
      BTSetSearchForSequential(fbIFB, fbKeyNum, False);
    {$ELSE}
      DisableSearchForSequential(fbIFB, fbKeyNum);
    {$ENDIF}

    {save window state}
    rwSaveWindowState;
  end;

begin
  {initialize command processor}
  FBrowserCommands.Init(@FBrowserKeySet, FBrowserKeyMax);
end.
