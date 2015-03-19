{~change:Added vcs header~}
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
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,R-,S-,V-,O+,F+}
{*****************************************************}
{ (C) NewsMaker Systems.                              }
{ Routines for connecting to the DAVIS Weatherlink    }
{*****************************************************}

Unit UWlink;

interface

Uses Dos, OpCrt, OpDOS, ULib, UWindow, USerial, OpString,
     QGlobal, QHdrRec,HexConv,UGlobal,QNovell,UColors,
     UHdr,
     OpFrame, OpWindow, OpCol16, OpDate;

Type

  WeatherRec = Record
    StartOfBlock     : byte;
    InsideTemp       : word;
    OutsideTemp      : word;
    WindSpeed        : byte;
    WindDirection    : word;
    Barometer        : word;
    InsideHumidity   : byte;
    OutsideHumidity  : byte;
    TotalRain        : word;
    NotUsed          : word;
    Checksum         : word;
  end;

  WLErrors = (WL_OK, WL_WriteError, WL_TimeOut, WL_BadCommand);

  TitleStr = String[20];
  TCString = String[8];
  CommandType = Array[1..18] of char;

  PWeatherWindow = ^TWeatherWindow;
  TWeatherWindow = Object(StackWindow)
    x1,y1,
    x2,y2     : word;
    Attrib    : byte;
    Title     : TitleStr;
    Colors    : ColorSet;
    Port      : SerialPortPtr;
    Frequency : LongInt;
    LastCheck : LongInt;
    WeatherData : WeatherRec;
    Status    : WLErrors;
    Command     : ^CommandType;

    constructor Init(px1,py1,px2,py2: word; Header: TitleStr; WColors: ColorSet; Interval: LongInt);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure Erase; virtual;
    procedure Update; virtual;
    procedure WriteChars(x,y: word; var Buf; Len: word; Atr: byte);
    procedure WriteString(x,y: word; Str: String; Atr: byte);
    Procedure OpenLink(PortNum: integer);
    Procedure CloseLink;
    Function GetWeatherData(var Stat: WLErrors): boolean;
  end;

  PLogWindow = ^TLogWindow;
  TLogWindow = Object(StackWindow)
    LastX : integer;
    LastY : integer;
    constructor Init;
    procedure Update(S: String; Attr: byte);
    procedure UpdateCh(Ch: Char; Attr: byte);
    procedure Draw; Virtual;
  end;

  FKeyRec = record
    NumStrings : integer;
    Strings    : Array[1..50] of StringPtr;
    Title      : String[6];
  end;

var
  CGPort   : SerialPortPtr;
  TCReader : SerialPortPtr;

  InitStrings    : Array[1..50] of StringPtr;
  SetTimeStrings : Array[1..50] of StringPtr;
  TempStrings    : Array[1..50] of StringPtr;

  FStrings      : Array[1..10] of FKeyRec;
  GPIStrings    : Array[1..4] of FKeyRec;

  NumInitStrings : integer;
  NumSetTimeStrings : integer;
  NumTempStrings : integer;

  CGPortData : SerialPortRec;
  TCPortData : SerialPortRec;
  WLPortData : SerialPortRec;
  LinkPort   : integer;

  SyncFromNet : boolean;

  LWin : PLogWindow;
  LogLevel : integer;
  WWin : PWeatherWindow;

const
  OverrideTemp : String[3] = '000';
  UseGPIs      : boolean = False;

Function RoundUp(IVal: word; Divisor: word): word;
Procedure OpenCG(Port: integer);
procedure CloseCG;
procedure SetCGTime;
procedure SendFileToCG(Name: PathStr);
Procedure OpenTCReader(Port: integer);
procedure CloseTCReader;
procedure SetTimeFromReader;
procedure GetTimeCode(var TCode: TCString);
procedure InitializeCG;
procedure SendFKeyStrings(N: integer);
procedure SendGPIStrings(N: integer);
procedure Log(S: String);
procedure LogError(S: String);

implementation

Var
  PortNo : integer;
  S: String;
  I: Integer;
  T: LongInt;
  w: word;
  ThisPollOK: boolean;
  WData : WeatherRec;
  TargetSlug : String[20];
  SlugSent : boolean;

Const
  Loop : Array[1..7] of char = ('L','O','O','P',' ',' ',#$0D);


Function RoundUp(IVal: word; Divisor: word): word;
var I: word;
begin
  if IVal = 0 then
    begin
      RoundUp := IVal;
      Exit;
    end;
  I := IVal div Divisor;
  if (IVal mod Divisor) > (Divisor div 2) then
    inc(I);
  RoundUp := I;
end;

Procedure OpenTCReader(Port: integer);
begin
  with TCPortData do
    New(TCReader, InitComm(Port, Baud, Parity,Data,Stop,XonXoff));
end;

procedure CloseTCReader;
begin
  Dispose(TCReader, Done);
end;

procedure GetTimeCode(var TCode: TCString);
var TC: String[10];
    Ch : Char;
    TOut : LongInt;
    H,M,S,S100,e: word;
begin
  if TCReader = nil then exit;
  TCReader^.FlushBuffers;
  TOut := TimeMS;
  Repeat
    TCReader^.ReadChar(Ch);
  Until (Ch = #$0D) or (TimeOut(TOut, 1000));
  TC := '';
  ch := ' ';
  TOut := TimeMS;
  Repeat
    if TCReader^.BytesInInput > 0 then
      if TCReader^.ReadChar(Ch) then
        begin
          TC := TC+Ch;
        end;
  Until (Ch = #$0D) or (TimeOut(TOut, 1000));
  TC[0] := #8;
  TCode := TC;
end;

procedure SetTimeFromReader;
var TC: String[10];
    Ch : Char;
    H,M,S,S100,e: word;
begin
  GetTimeCode(TC);
  Log('Resync with House Time Code: '+TC);
  Val(Copy(TC,1,2),H,e);
  Val(Copy(TC,3,2),M,e);
  Val(Copy(TC,5,2),S,e);
  Val(Copy(TC,7,2),S100,e);
  S100 := S100*3;
  SetTime(H,M,S,S100);
end;

Procedure OpenCG(Port: integer);
begin
  with CGPortData do
    New(CGPort, InitComm(Port, Baud, Parity,Data,Stop,XonXoff));
end;

procedure CloseCG;
begin
  Dispose(CGPort, Done);
end;

procedure SendScriptToCG(Name: PathStr);
type
    FBuf = Array[1..1024] of char;
var Font: File;
    Buf : ^FBuf;
    S: String[20];
    Numread: Integer;
    I,J,K : LongInt;
    Ch: Char;
    InHidden : boolean;
begin
  {$I-}
  Assign(Font, Name);
  Reset(Font, 1);
  Seek(Font, 0);
  InHidden := False;
  if IoResult <> 0 then exit;
  New(Buf);
  j := 0;
  Repeat
    BlockRead(Font, Buf^, 1024, NumRead);
    inc(J,NumRead);
    Log('Read '+Long2Str(j)+' bytes');
    for i := 1 to NumRead do
      begin
      if Buf^[i] = #8 then
        InHidden := True;
      if not InHidden then
        begin
        if Buf^[i] = #$0D then
          Buf^[i] := ' ';

        if not (Buf^[i] in [#$1A, #$0A]) then
          begin
          CGPort^.WriteChar(Buf^[i]);

          if LogLevel >= 3 then
            if not (Buf^[i] in ['A'..'Z',' ']) then
              begin
              S := HexB(byte(Buf^[i]));
              for k := 1 to length(S) do
                LWin^.UpdateCh(S[k], LtCyanOnBlack);
              end
            else
              LWin^.UpdateCh(Buf^[i], CyanOnBlack);

          end;
        end;
      if Buf^[i] = #9 then
        InHidden := False;
      end;
    While CGPort^.BytesFreeInOutput < 1024 do;
  Until NumRead < 1024;
  Delay(100);
  While CGPort^.BytesInInput <> 0 do
    begin
      CGPort^.ReadChar(Ch);
    end;
  Close(Font);
  Dispose(Buf);
  {$I+}
  if LogLevel >= 3 then
    LWin^.Update('',TextAttr);
end;

Procedure ProcessHdr(HdrDirectory: RundownRec;   { Directory, Record 0 }
                     var Hdr     : RundownRec;   { Current Hdr }
                     HdrNum      : Integer;      { Header Number }
                     var Update  : boolean;      { If true, write back }
                     var Quit    : boolean);     { if True, quit now }
var
  FileName: PathStr;
  QFile : Text;
begin
  Quit := False;
  if Hdr.Slug = TargetSlug then
    begin
    FileName := 'Q'+Long2Str(Hdr.DosScriptFile);
    {$I-}
    FileMode := $40;
    Log('Sending: '+TargetSlug+' File: '+FileName);
    SendScriptToCG(FileName);
    SlugSent := True;
    {$I+}
    Quit := True;
    end;
end;

procedure DoSlugSend(Path: PathStr);
var
  Hdr: RundownRec;
  Result: integer;
begin
  TargetSlug := StUpCase(Trim(ExtractWord(2,Path,[','])));
  SlugSent := False;
  ForEachHeader(ProcessHdr, ExtractWord(1,Path,[',']), False, Result);
  if not SlugSent then
    LogError('Slug '+TargetSlug+' Not found!');
end;

procedure SendCG(CS: String);
var
  i,e: integer;
  l : LongInt;
  Cmd: String[20];
  Param: PathStr;
  Scan: word;

  procedure DoSend(TS: String);
  var t: integer;
  begin
    if LogLevel >= 2 then
      LWin^.Update(TS, CyanOnBlack);
    for t := 1 to length(TS) do
      CGPort^.WriteChar(TS[t]);
  end;

begin
  if CS[1] = '$' then
    begin
    Cmd := StUpCase(ExtractWord(1, CS, ['(',')']));
    Param := ExtractWord(2, CS, ['(',')']);
    if Cmd = '$SENDFILE' then
      begin
      Log('Sending '+Param);
      SendFileToCG(Param);
      end;
    if Cmd = '$DELAY' then
      begin
      Log('Delay '+Param);
      Val(Param, i, e);
      Delay(i);
      end;
    if Cmd = '$PAUSE' then
      begin
      Log('Waiting for Keystroke');
      While not CheckKBD(Scan) do
        UpdateWTime(False);
      FastWrite(Pad('',80),21,1,LtGreenOnBlue);
      end;
    if Cmd = '$DEC' then
      begin
      Val(Param, i, e);
      CGPort^.WriteChar(Char(byte(i)));
      end;
    if Cmd = '$HEX' then
      begin
      HexVal(Param, l, e);
      CGPort^.WriteChar(Char(byte(l)));
      end;
    if Cmd = '$CR' then
      begin
      CGPort^.WriteChar(#$0D);
      end;
    if Cmd = '$LF' then
      begin
      CGPort^.WriteChar(#$0A);
      end;
    if Cmd = '$CRLF' then
      begin
      CGPort^.WriteChar(#$0D);
      CGPort^.WriteChar(#$0A);
      end;
    if Cmd = '$CURRENTTIME' Then
      begin
      S := CurrentTimeString(Param);
      DoSend(S);
      end;
    if Cmd = '$CURRENTDATE' Then
      begin
      S := TodayString(Param);
      DoSend(S);
      end;
    if Cmd = '$TEMPERATURE' Then
      begin
      DoSend(LeftPad(Long2Str(RoundUp(WData.OutsideTemp,10)),3));
      end;
    if Cmd = '$BAROMETER' Then
      begin
      DoSend(Long2Str(WData.Barometer div 1000)+'.'+
             Long2Str(WData.Barometer mod 1000));
      end;
    if Cmd = '$WINDSPEED' Then
      begin
      DoSend(Long2Str(WData.WindSpeed));
      end;
    if Cmd = '$WINDDIRECTION' Then
      begin
      DoSend(Long2Str(WData.WindSpeed));
      end;
    if Cmd = '$HUMIDITY' Then
      begin
      DoSend(Long2Str(WData.OutsideHumidity));
      end;
    if Cmd = '$RAINFALL' Then
      begin
      DoSend(Long2Str(WData.TotalRain));
      end;
    if Cmd = '$RESETCG' Then
      begin
      InitializeCG;
      end;
    if Cmd = '$RESETWEATHER' Then
      begin
      FillChar(WData, SizeOf(WeatherRec), 0);
      FillChar(WWin^.WeatherData, SizeOf(WeatherRec), 0);
      WWin^.LastCheck := 0;
      end;
    if Cmd = '$SENDSLUG' then
      begin
      DoSlugSend(Param);
      end;
    end
  else
    DoSend(CS);
end;

procedure InitializeCG;
var
  i: integer;
begin
  for i := 1 to NumInitStrings do
    SendCG(StringFromHeap(InitStrings[i]));
end;

procedure SendFKeyStrings(N: integer);
var
  i: integer;
begin
  if FStrings[N].NumStrings = 0 then exit;
  Log('Sending Function key '+Long2Str(N));
  for i := 1 to FStrings[N].NumStrings do
    SendCG(StringFromHeap(FStrings[N].Strings[i]));
end;

procedure SendGPIStrings(N: integer);
var
  i: integer;
begin
  if GPIStrings[N].NumStrings = 0 then exit;
  Log('Sending GPI '+Long2Str(N));
  for i := 1 to GPIStrings[N].NumStrings do
    SendCG(StringFromHeap(GPIStrings[N].Strings[i]));
end;

procedure SetCGTime;
var S: String;
    i: integer;
begin
  if SyncFromNet then
    begin
    Log('Downloading Time from Server');
    SetWorkstationTimeFromServer;
    end
  else
    if TCReader <> nil then
      begin
      Log('Reading House Timecode');
      SetTimeFromReader;
      end;
  Log('Sending Time to CG');
  FastWrite(TimeToTimeString('hh:mm:ss',TimeMS div 1000),6,53,YellowOnBlue);
  for i := 1 to NumSetTimeStrings do
    SendCG(StringFromHeap(SetTimeStrings[i]));
end;

Procedure UpdateCG(var WData: WeatherRec);
begin
  Log('Sending Update to CG');
  for i := 1 to NumTempStrings do
    SendCG(StringFromHeap(TempStrings[i]));
end;

procedure SendFileToCG(Name: PathStr);
type
    FBuf = Array[1..1024] of char;
var Font: File;
    Buf : ^FBuf;
    S: String[20];
    Numread: Integer;
    I,J : LongInt;
    Ch: Char;
begin
  {$I-}
  Assign(Font, Name);
  Reset(Font, 1);
  Seek(Font, 0);
  if IoResult <> 0 then exit;
  New(Buf);
  j := 0;
  Repeat
    BlockRead(Font, Buf^, 1024, NumRead);
    inc(J,NumRead);
    Log('Read '+Long2Str(j)+' bytes');
    for i := 1 to NumRead do
      CGPort^.WriteChar(Buf^[i]);
    While CGPort^.BytesFreeInOutput < 1024 do;
  Until NumRead < 1024;
  CGPort^.WriteChar(#$0D);
  Delay(100);
  While CGPort^.BytesInInput <> 0 do
    begin
      CGPort^.ReadChar(Ch);
    end;
  Close(Font);
  Dispose(Buf);
  {$I+}
end;

constructor TWeatherWindow.Init(px1,py1,px2,py2: word; Header: TitleStr; WColors: ColorSet;
                                Interval: LongInt);
begin
  X1 := Px1;
  Y1 := Py1;
  X2 := Px2;
  Y2 := Py2;
  Colors := WColors;
  Title := Header;
  StackWindow.InitCustom(x1,y1,x2,y2, Colors, DefWindowOptions or wBordered);
{  FillChar(WeatherData, SizeOf(WeatherRec), 0);}
  LastCheck := 0;
  Frequency := Interval;
  Command := @WeatherData;

  wFrame.SetFrameType(sglWindowFrame);
  OpenLink(LinkPort);
end;

destructor TWeatherWindow.Done;
begin
  CloseLink;
  StackWindow.Done;
end;

procedure TWeatherWindow.Draw;
begin
  wFrame.AddHeader(Title, heTL);
  StackWindow.Draw;
  WriteString(1,1,'Temperature: ',LtGrayOnBlue);
  WriteString(1,2,'Humidity   : ',LtGrayOnBlue);
  WriteString(1,3,'Wind Speed : ',LtGrayOnBlue);
  WriteString(1,4,'Wind Direc.: ',LtGrayOnBlue);
  WriteString(1,5,'Barometer  : ',LtGrayOnBlue);
  WriteString(1,6,'Total Rain : ',LtGrayOnBlue);
  WriteString(30,1,'Last Weather Update : ',LtGrayOnBlue);
  WriteString(30,2,'Next Weather Update : ',LtGrayOnBlue);
  WriteString(30,3,'Last CG Update      : ',LtGrayOnBlue);
  WriteString(30,4,'Last Time Update    : ',LtGrayOnBlue);
end;

procedure TWeatherWindow.Erase;
begin
  StackWindow.Erase;
end;

procedure TWeatherWindow.Update;
var
  WD : WeatherRec;
begin
  if not Timeout(LastCheck,Frequency) then
    begin
      WriteString(52,2,TimeToTimeString('hh:mm:ss',((Frequency-(TimeMS-LastCheck))+1000) div 1000),YellowOnBlue);
      exit;
    end;
  Move(WeatherData, WD, SizeOf(WeatherRec));
  if GetWeatherData(Status) then
    LastCheck := TimeMS;
  WriteString(52,1,TimeToTimeString('hh:mm:ss',LastCheck div 1000),YellowOnBlue);

  if (Status = WL_OK) then
    begin
      WriteString(14,1,Pad(Long2Str(RoundUp(WeatherData.OutsideTemp,10)),4),YellowOnBlue);
      WriteString(14,2,Pad(Long2Str(WeatherData.OutsideHumidity)+'%',4),YellowOnBlue);
      WriteString(14,3,Pad(Long2Str(WeatherData.WindSpeed),3)+'mph',YellowOnBlue);
      WriteString(14,4,Pad(Long2Str(WeatherData.WindDirection),4),YellowOnBlue);
      WriteString(14,5,Pad(Long2Str(WeatherData.Barometer div 1000)+'.'+
                           Long2Str(RoundUp(WeatherData.Barometer mod 1000,10))+'"',6),YellowOnBlue);
      WriteString(14,6,Pad(Long2Str(WeatherData.TotalRain)+'"',6),YellowOnBlue);

      Move(WeatherData, WData, SizeOf(WeatherRec));
      WriteString(52,3,TimeToTimeString('hh:mm:ss',TimeMS div 1000),YellowOnBlue);
      if (WD.OutsideTemp <> WeatherData.OutsideTemp) or
         (WD.OutsideHumidity <> WeatherData.OutsideHumidity) or
         (WD.Barometer <> WeatherData.Barometer) then
        UpdateCG(WeatherData)
      else
        Log('No CG Update, Data not changed');
    end
   else
     begin
     Case Status of
       WL_WriteError : LogError('Write Error');
       WL_Timeout    : LogError('Timeout Error');
       WL_BadCommand : LogError('Bad Command');
       end;
     end;
end;

procedure TWeatherWindow.WriteChars(x,y: word; var Buf; Len: word; Atr: byte);
var Chars: Array[1..50] of char absolute Buf;
    i: integer;
begin
  for i := 1 to Len do
    FastWrite(Chars[i], (y1-1)+y, (x1-1)+(x+(i-1)), Atr);
end;

procedure TWeatherWindow.WriteString(x,y: word; Str: String; Atr: byte);
begin
  FastWrite(Str, (y1-1)+y, (x1-1)+x, Atr);
end;

Procedure TWeatherWindow.OpenLink(PortNum: integer);
begin
  PortNo := PortNum;
  if PortNo = 0 then exit;
  with WLPortData do
    New(Port, InitComm(PortNo, Baud, Parity,Data,Stop,XonXoff));
  While Port^.BytesInInput <> 0 do;
end;

Procedure TWeatherWindow.CloseLink;
begin
  if PortNo = 0 then exit;
  if Port <> nil then
    Dispose(Port, Done);
  Port := nil;
end;

Function TWeatherWindow.GetWeatherData(var Stat: WLErrors): boolean;
var i: integer;
    w: word;
    Ch: Char;
    t: LongInt;
begin
  Log('Downloading Weather Data');
  if PortNo = 0 then
    begin
    LogError('Port number Invalid');
    exit;
    end;
  { Flush any old data in serial buffer }

  Port^.FlushBuffers;
{  While Port^.BytesInInput <> 0 do;}

  { Request one packet of data from the weather station }

  w := word($FFFF);
  Move(w, Loop[5],2);
  for i := 1 to 7 do
    if not Port^.WriteChar(Loop[i]) then
      begin
        Stat := WL_WriteError;
        GetWeatherData := False;
        exit;
      end;

  While Port^.BytesFreeInOutput < 1024 do;

  t := TimeMS;
  i := 0;
  While Port^.BytesInInput = 0 do
    begin
      UpdateTime(False);
      if Abs(TimeMS-t) > 5000 then
        begin
          Stat := WL_TimeOut;
          GetWeatherData := False;
          exit;
        end;
    end;

  T := TimeMS;
  While Port^.BytesInInput > 0 do
    begin
      if abs(TimeMS-t) > 5000 then
        begin
          Stat := WL_TimeOut;
          GetWeatherData := False;
          exit;
        end;
      inc(i);
      Port^.ReadChar(Ch);
      if i = 1 then
        begin
          if Ch = '!' then
            begin
              Stat := WL_BadCommand;
              GetWeatherData := False;
              exit;
            end;
          if Ch = #6 then
            Delay(1500);    { Time for rest of packet to arrive }
        end
      else
        begin
          Command^[i-1] := ch;
        end;
    end;

  GetWeatherData := True;
  Stat := WL_OK;
end;

constructor TLogWindow.Init;
begin
  Black_Scheme;
  StackWindow.InitCustom(2,11,79,20, NENColorSet, DefWindowOptions or wBordered);
  LastX := 1;
  LastY := 1;
end;

procedure TLogWindow.Draw;
begin
  wFrame.AddHeader('Log', heTL);
  StackWindow.Draw;
end;

procedure TLogWindow.Update(S: String; Attr: byte);
begin
  Window(2, 11, 78, 20);
  TextAttr := Attr;
  GotoXY(LastX, LastY);
  WriteLn(S);
  LastX := WhereX;
  LastY := WhereY;
end;

procedure TLogWindow.UpdateCh(Ch: Char; Attr: byte);
begin
  Window(2, 11, 78, 20);
  TextAttr := Attr;
  GotoXY(LastX, LastY);
  Write(Ch);
  LastX := WhereX;
  LastY := WhereY;
end;

procedure Log(S: String);
begin
  LWin^.Update(CurrentTimeString('hh:mm:ss')+' '+S,WhiteOnBlack);
end;

procedure LogError(S: String);
begin
  LWin^.Update(CurrentTimeString('hh:mm:ss')+' '+S,LtRedOnBlack);
end;

begin
  TCReader := nil;
end.
