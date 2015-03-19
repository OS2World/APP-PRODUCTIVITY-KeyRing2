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
{$A-,F+}
{$IFNDEF Windows }
{$O+}
{$ENDIF}

unit UGLOBAL;

{.$DEFINE SmallMenu }

{$I MCDEFINE.INC}

interface

uses
  Dos,
  OpCrt,
  OpCol16,
  QGlobal,
  OpFrame,
  OpWindow,
  OpCtrl,
  OpDialog,
  OpCmd,
  OpInline,
  OpDate,
  OpDrag,
  UMSg;

const
  SecurityClearance : Byte = 3;
  ScreenMax      = 15;
  {$IFDEF SmallMenu }
  BigListLength = 10;
  MaxMenuSize : word = 10;
  {$ELSE}
  BigListLength  = 50;
  MaxMenuSize    : Word = 200;
  {$ENDIF}

type
  TitleString    = String[30];
  SType          = String[100];
  {$IFDEF SmallMenu }
  BigString   = String[10];
  {$ELSE }
  BigString      = String[70];
  {$ENDIF }
  Cstring        = String[30];

  PsaveRec       = record
                     Psave          : array[1..80] of Char; { Prompt line Save/Get area }
                     Pattr          : array[1..80] of Byte;
                   end;

  Time           = record
                     Hour           : Word;
                     Minute         : Word;
                     Second         : Word;
                     Sec100         : Word;
                   end;


  SerialPortRec  = record
                     Baud           : Word;
                     Parity         : Char;
                     Data           : Byte;
                     Stop           : Byte;
                     XonXoff        : Boolean;
                     CharDelay      : Word;
                   end;

  BigList        = array[1..BigListLength] of BigString;
  HugeList       = array[1..800] of BigString;
  BiggerList     = array[1..800] of Cstring;
  BigRef         = array[1..BigListLength] of Byte;
  HugeRef        = array[1..800] of Word;
  RefPtr         = ^HugeRef;
  ListPtr        = ^HugeList;

type
  ColorSetProc   = procedure;

  NENWindowPtr   = ^NENWindow;
  NENWindow      = object(CommandWindow)
                     L25            : Pointer; { Just line 25 (Prompt) }
                     SetColors      : ColorSetProc;
                     Colors         : ColorSet;
                     WCP            : DragProcessorPtr;
                     FillCharacter  : Char;
                     Quadrant       : Byte;
                     OrigX1, OrigY1 : Byte;
                     OrigX2, OrigY2 : Byte;
                     constructor InitCustom(X1, Y1, X2, Y2 : Byte;
                                            var NColors    : ColorSet;
                                            Options        : LongInt);
                     procedure Draw; virtual;
                     destructor Done; virtual;
                   end;

const
  Null           = #00;
  CursorRight    = #77;
  CursorLeft     = #75;
  CursorUp       = #72;
  CursorDown     = #80;
  CtrlRight      = #116;
  CtrlLeft       = #115;
  Home           = #71;
  EndKey         = #79;
  PgUp           = #73;
  PgDn           = #81;
  Enter          = #$0D;
  Esc            = #27;
  DelKey         = #83;
  BackSp         = #8;
  InS            = #82;
  TabRight       = #9;
  TabLeft        = #15;
  F1             = #59;           { Function key codes (preceded by a null #0) }
  F2             = #60;
  F3             = #61;
  F4             = #62;
  F5             = #63;
  F6             = #64;
  F7             = #65;
  F8             = #66;
  F9             = #67;
  F10            = #68;
  SF1            = #84;
  SF2            = #85;
  SF3            = #86;
  SF4            = #87;
  SF5            = #88;
  SF6            = #89;
  SF7            = #90;
  SF8            = #91;
  SF9            = #92;
  SF10           = #93;

  MenuAccept     : Char = Enter;

  FullBorder     = LightBlue;
  FullBack       = Black;
  FullText       = Yellow;
  QuarterBorder  = White;
  QuarterBack    = Blue;
  QuarterText    = Yellow;
  CentreBorder   = Black;
  CentreBack     = Red;
  CentreText     = White;
  MenuBorder     = White;
  MenuBack       = Blue;
  MenuUnselected = Blue;
  MenuSelected   = Magenta;
  MenuText1      = Yellow;
  MenuText2      = LightCyan;
  UpDownColor    = LightRed;
  SpeedTypingBackground = Cyan;
  SpeedtypingForeground = Blue + Blink;
  Sort           = True;
  NoSort         = False;
  NextMenu       = True;
  PrevMenu       = False;
  EscapeMeansYes = True;
  EscapemeansNo  = False;
  DragSpeed      = 10;            { Milliseconds between screen moves }
  DragMode       = True;
  MoveMode       = False;
  FirstletterHighlight : Boolean = False;
  NoBorder       = 0;
  SingleLine     = 1;             { for SetBorderType }
  DoubleLine     = 2;
  DoubleSingle   = 3;
  EnableFunctionKeyExit : Boolean = False;

(*
const
  FunctionKeyMax = 160;

  FunctionKeySet : array[0..FunctionKeyMax] of Byte =
  (
    3, $00, $3B, ccUser0,         {  F1}
    3, $00, $3C, ccUser1,         {  F2}
    3, $00, $3D, ccUser2,         {  F3}
    3, $00, $3E, ccUser3,         {  F4}
    3, $00, $3F, ccUser4,         {  F5}
    3, $00, $40, ccUser5,         {  F6}
    3, $00, $41, ccUser6,         {  F7}
    3, $00, $42, ccUser7,         {  F8}
    3, $00, $43, ccUser8,         {  F9}
    3, $00, $44, ccUser9,         {  F10}
    3, $00, $54, ccUser10,        {shF1}
    3, $00, $55, ccUser11,        {shF2}
    3, $00, $56, ccUser12,        {shF3}
    3, $00, $57, ccUser13,        {shF4}
    3, $00, $58, ccUser14,        {shF5}
    3, $00, $59, ccUser15,        {shF6}
    3, $00, $5A, ccUser16,        {shF7}
    3, $00, $5B, ccUser17,        {shF8}
    3, $00, $5C, ccUser18,        {shF9}
    3, $00, $5D, ccUser19,        {shF10}
    3, $00, $5E, ccUser20,        {ctF1}
    3, $00, $5F, ccUser21,        {ctF2}
    3, $00, $60, ccUser22,        {ctF3}
    3, $00, $61, ccUser23,        {ctF4}
    3, $00, $62, ccUser24,        {ctF5}
    3, $00, $63, ccUser25,        {ctF6}
    3, $00, $64, ccUser26,        {ctF7}
    3, $00, $65, ccUser27,        {ctF8}
    3, $00, $66, ccUser28,        {ctF9}
    3, $00, $67, ccUser29,        {ctF10}
    3, $00, $68, ccUser30,        {alF1}
    3, $00, $69, ccUser31,        {alF2}
    3, $00, $6A, ccUser32,        {alF3}
    3, $00, $6B, ccUser33,        {alF4}
    3, $00, $6C, ccUser34,        {alF5}
    3, $00, $6D, ccUser35,        {alF6}
    3, $00, $6E, ccUser36,        {alF7}
    3, $00, $6F, ccUser37,        {alF8}
    3, $00, $70, ccUser38,        {alF9}
    3, $00, $71, ccUser39,        {alF10}
    0);
*)
const
  ForceUpperCase = True;
  AllowLowerCase = False;
  NENFlag        : Boolean = False; { True if called from NEN }

  FullMemoryDisplay : Boolean = False;

const
  BaudRates      : array[1..6] of Integer = (384, 1200, 2400, 4800, 9600, 19200);
  Parities       : array[1..5] of Char = ('N', 'O', 'E', 'M', 'S');

type
  UDataRecPtr    = ^UDataRec;
  UDataRec       = record
                     WindowsMode    : Boolean;
                     ClockOn        : Boolean;
                     TimerWindowUp  : Boolean;
                     MemoryWindowUp : Boolean;
                     SPXDisplayUp   : Boolean;
                     ClockX         : Integer;
                     ClockY         : Integer;
                     ClockBack      : Integer;
                     ClockColor     : Integer;
                     ClockBorder    : Integer;
                     ClockAttr      : Byte;
                     BorderAttr     : Byte;
                     MemX           : Integer;
                     MemY           : Integer;
                     MemAttr        : Byte;
                     SPXAttr        : Byte;
                     LastSeconds    : Word;
                     UpperLeft      : Char;
                     UpperRight     : Char;
                     LowLeft        : Char;
                     LowRight       : Char;
                     HorizontalChar : Char;
                     VerticalChar   : Char;
                     TConnect       : Char;
                     RConnect       : Char;
                     LConnect       : Char;
                     LRConnect      : Char;
                     UConnect       : Char;
                     AlarmTime      : LongInt;
                     OrigTime       : LongInt;
                     SeedTime       : LongInt;
                     Timer          : LongInt;
                     InitialTime    : LongInt;
                     TimerWindowMode : Integer;
                     TimeRollover   : Boolean;
                     TimerFunc      : String[10];
                     DateMode       : Boolean;
                     TimeFormat     : Integer;
                     LastCalcSelection : Integer;
                     TimerBack      : Byte;
                     TimerColor     : Byte;
                     BorderOn       : Boolean;
                     DataFlag       : Boolean; { GetMenu exits after each movement }
                     WorkS          : SType;
                     Stx, Sty       : Integer; { Speed typing window coords }
                     ZoomX1, ZoomY1,
                     ZoomX2, ZoomY2 : Integer;
                     SaveTopChar    : Char;
                     SaveBottomChar : Char;
                     SaveTopAttr    : Byte;
                     SaveBottomAttr : Byte;
                     PromptFore     : Byte;
                     PromptBack     : Byte;
                     PromptText     : Byte;
                     PromptLine     : Word;
                     PSaveStack     : array[1..ScreenMax] of PsaveRec;
                     PS             : Word; { Index to PsaveStack }
                     Ch, Ch2        : Char; { scratch char registers }
                     Regs           : Registers;
                     GwSave         : Boolean; { Grow/explode window save state }
                     NwSave         : Boolean; { Noisy explode window save state }
                     SHSave         : Boolean; { Window shadow save state }
                     IconsRegistered : Integer;
                     MenuHighlight  : Boolean;
                     FieldMode      : Boolean;
                     MouseFlag      : Integer;
                     EscapeFlag     : Boolean;
                     OrigX, OrigY   : Word;
                     OriginalScreen : Pointer;
                     LastFilePath   : PathStr;
                     CursorStart    : Byte;
                     CursorEnd      : Byte;
                     CursorHidden   : Boolean;
                     WaitForFilePrompt : Boolean;
                     MessageUp      : Boolean;
                     FKey           : Boolean;
                     dt             : DateTime;
                     FDT            : DateTimeRec;
                     CDT            : DateTimeRec;
                     Days           : Word;
                     Secs           : LongInt;
                     HelpLine       : Byte; {ZZZZ KGM}
                     SuperUser      : Boolean; {ZZZZ KGM}
                   end;

const OffHook  = 'ATH1';          { HAYES 'AT' commands }
  OnHook         = 'ATH0';
  ToneDial       = 'ATDT';        { Tone-Dial }
  PulseDial      = 'ATDP';        { Pulse-Dial }
  Speaker        = 'ATM1';        { Speaker ON until Carrier detect }
  Loud           = 'ATL3';        { Speaker Volume high }
  ModemReset     = 'ATZ0';        { Reset default settings }
  NoEcho         = 'ATE0';
  ResultOn       = 'ATQ0';        { 0 = results, 1 = No results }
  Result         = 'ATV1';        { 0 = Numeric results, 1= strings }
  OnLineMode     = 'ATO';         { Switch modem to Online mode }
  CmdMode        = '+++';         { Switch modem from online to command state }

const
  ChTimes        : Word = 4;      { # of char times before timeout & script check }

  InBufSize      = 1100;          { 1100 to accomodate Ymodem 1024+CRC block size }
  OutBufSize     = 1100;

  P_ASCII        = 1;
  P_XMODEM       = 2;
  P_XMODEM1K     = 3;
  P_YMODEM       = 4;

  CParity        : array[1..3] of Char = ('N', 'E', 'O');
  CBaud          : array[1..5] of Word = (300, 1200, 2400, 4800, 9600);

  IntReg1        = $3F8;
  IntReg2        = $2F8;
  IntReg3        = $3E8;
  IntReg4        = $2E8;

  Vector1        = $0C;
  Vector2        = $0B;
  Vector3        = $0C;
  Vector4        = $0B;

  Step           = 1;

type
  ResultString   = String[40];
  ModemString    = String[80];
  PhoneString    = String[20];

const
  COM1           = 1;
  COM2           = 2;
  COM3           = 3;
  COM4           = 4;

  TTYMode        = 1;             { TTY mode, no functions supported }
  VT52mode       = 2;             { VT52 escape protocol       }
  VT100Mode      = 3;             { VT100/ANSI escape protocol }
  ANSImode       = 4;             { ANSI, just calls VT100     }
  VuTextmode     = 5;             { modified TTY mode for ViewText}

  B300           = 1;
  B1200          = 2;
  B2400          = 3;
  B4800          = 4;
  B9600          = 5;

  Stop1          = 1;
  Stop2          = 2;

  Data7          = 7;
  Data8          = 8;

  NoParity       = 1;
  EvenParity     = 2;
  OddParity      = 3;

const
  Mono_Black     = 0;             { Monochrome Adapter constants }
  Mono_White     = 7;
  Mono_Underline = 1;
  Mono_Bright    = $F;
  Mono_Blink     = 8;             { in 4-bit attr, 128 in 8 bit byte }
  Sand           = Brown;

  Explode        : Boolean = True;
  SoundFlagW     : Boolean = False;
  ExplodeDelay   : Word = 8;

  BackgroundOn   : boolean = True;

var
  UData          : UDataRecPtr;
  ScreenNum      : Word;          { Index to WIN }
  Menu           : ^BigList;
  NENWindows     : array[1..ScreenMax] of CommandWindowPtr;
  ProcedureFunc  : Pointer;       { pointer to a procedure }
  TimeMask       : String[15];

implementation

  constructor NENWindow.InitCustom(X1, Y1, X2, Y2 : Byte;
                                   var NColors    : ColorSet;
                                   Options        : LongInt);
  begin
  if SaveWindow(1, 25, 80, 25, True, L25) then ;
  New(WCP, Init(@DialogKeySet, DialogKeyMax));
  CommandWindow.InitCustom(X1, Y1, X2, Y2, NColors, Options, WCP^, 0);
  wFrame.AddShadow(shBR, shSeeThru);
  Colors := NColors;
  end;

  procedure NENWindow.Draw;
  begin
  SetBackChar(FillCharacter);
  wTextColor := Colors.BlockColor;
  CommandWindow.Draw;
  ClearContents;
  end;

  destructor NENWindow.Done;
  begin
  if L25 <> nil then              { restore line 25, if stored }
    RestoreWindow(1, 25, 80, 25, True, L25);
  L25 := nil;
  Erase;                          { Erase, & release the window }
  Dispose(WCP, Done);
  CommandWindow.Done;
  end;

begin
New(UData);
FillChar(UData^, SizeOf(UDataRec), 0);
TimeMask := InternationalTime(True, False, False, True);
with UData^ do
begin
TimerWindowUp := False;
MemoryWindowUp := False;
WindowsMode := False;
SPXDisplayUp := False;
LastFilePath := '';
WaitForFilePrompt := True;
MessageUp := False;
GetMem(Menu, SizeOf(BigList));
BorderOn := True;
if CurrentDisplay <> MonoHerc then 
begin
TimerBack := DarkGray;
TimerColor := LightGreen;
end
else 
begin
TimerBack := Mono_Black;
TimerColor := Mono_Bright;
end;
MenuHighlight := True;
FieldMode := False;
IconsRegistered := 0;
MouseFlag := 0;
DateMode := False;
AlarmTime := 0;
TimerFunc := '';
ProcedureFunc := nil;

PromptBack := Cyan;
PromptFore := Black;
PromptText := Red;
PromptLine := 25;
if CurrentDisplay = MonoHerc then 
begin
PromptBack := Mono_White;
PromptFore := Mono_Black;
PromptText := Mono_Black;
end;
ScreenNum := 0;
NENFlag := False;
DataFlag := False;
ClockBack := LightGray;
ClockColor := Blue;
ClockBorder := Black;
ClockAttr := LightGray shl 4 + Blue;
MemAttr := LightGray shl 4 + Blue;
BorderAttr := ClockBack shl 4 + ClockBorder;
SPXAttr := Blue shl 4 + LightMagenta;
ClockX := 68;
ClockY := 1;
MemX := 58;
MemY := 1;
ClockOn := True;
PromptLine := 25;
ZoomX1 := 1;
ZoomY1 := 4;
ZoomX2 := 80;
ZoomY2 := 25;

OriginalScreen := nil;
CursorHidden := False;
PS := 0;
end;

end.
