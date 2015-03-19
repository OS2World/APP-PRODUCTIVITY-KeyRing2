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
{$A-,R-,S-,F+}
{$IFNDEF Windows }
{$O+}
{$ENDIF}

{-------------------------------------------------------------------}
{ (C) 1991 NewsMaker Systems.                                       }
{                                                                   }
{ Drives Uart, Digiboard, and Windows COM I/O via Async Professional}
{                                                                   }
{-------------------------------------------------------------------}

Unit USerial;     { Device independant serial I/O }

interface

{$IFNDEF Windows }
Uses Dos, OpCrt, ApMisc, ApPort, ApUart, OOCom, UWindow;
{$ELSE}
Uses WinDos, Objects, OWindows, ODialogs, WinTypes, WinProcs, Strings, WinSys, BWCC,
     OStdDlgs, UDigibrd;

Type
  ParityType = (NoParity, OddParity, EvenParity, MarkParity, SpaceParity);
  DataBitType = 5..8;
  StopBitType = 1..2;
{$ENDIF}

Type

  SerialPortPtr = ^SerialPort;
  SerialPort = Object
      PortNumber: word;
      Baud      : LongInt;
      Parity    : ParityType;
      Data      : DataBitType;
      Stop      : StopBitType;
      EStat     : boolean;
      Driver    : String[8];
      CharsInBuf: word;        { Chars currently in input buffer }
      CharsFree : word;        { Chars available in output buffer }
      Digiboard : boolean;
      {$IFNDEF Windows}
      APort     : AbstractPortPtr;
      {$ELSE}
      DPort     : DigiPortPtr;
      {$ENDIF}

      {$IFDEF Windows}
      CCDCB      : TDCB;
      ComStat    : TComStat;
      {$ENDIF}

      constructor InitComm(PortNum: word;    { 1-36 }
                           BaudRate: word;   { 50-38400 }
                           RParity: char;    { N, E, O }
                           DataBits: word;   { 5-8 }
                           StopBits: word;   { 1-2 }
                           XonXoff : boolean);
      destructor Done; virtual;   { also closes port }
      Function CommOK: boolean; virtual;
      function WriteChar(Ch: char): boolean; virtual;
      function WriteString(var S: String): boolean;
      function ReadChar(var Ch: char): boolean; virtual;
      procedure GetStatus(var Line, Modem: byte); virtual;
      procedure FlushBuffers; virtual;
      procedure FlushRXBuffer; virtual;
      procedure FlushTXBuffer; virtual;
      function BytesFreeInOutput: word; virtual;
      function BytesInOutputBuffer: word; virtual;
      function BytesInInput: word; virtual;
      procedure GetDriverName; virtual;
      procedure SetSignals(NewSet: byte);
      procedure ClearSignals(NewSet: byte);

    end;

  {$IFNDEF Windows}
  FastDigi14PortPtr = ^FastDigi14Port;
  FastDigi14Port = Object(Digi14Port)
    function InBuffUsed : Word; virtual;
  end;
  {$ENDIF}

Const
  COM_InSize    : word = 1024;
  COM_OutSize   : word = 1024;

  TXAutoWait    : boolean = False;

  HardwareFlowControl : boolean = False;

  UseFastDigi : boolean = True;

implementation

var
  IResult: integer;

      constructor SerialPort.InitComm(PortNum: word;    { 1-n }
                                      BaudRate: word;   { 110-9600}
                                      RParity: char;    { N, E, O }
                                      DataBits: word;   { 5-8 }
                                      StopBits: word;   { 1-2 }
                                      XonXoff : boolean);
      var
          {$IFDEF WINDOWS}
          Temp: Array[0..60] of char;
          T2 : Array[0..10] of char;
          {$ENDIF}
          i : integer;
        begin
          PortNumber := PortNum;
          Baud   := BaudRate;
          if Baud = 384 then
            Baud := 38400;
          Case UpCase(RParity) of
            'N'  : Parity := NoParity;
            'O'  : Parity := OddParity;
            'E'  : Parity := EvenParity;
            'M'  : Parity := MarkParity;
            'S'  : Parity := SpaceParity;
          end;
          Data   := DataBits;
          Stop   := StopBits;
          Case PortNumber of
            1..4  : begin
                     Digiboard := False;
                     {$IFNDEF Windows}
                     Estat := True;
                     APort := New(UartPortPtr,
                                  InitCustom(ComNameType(Ord(PortNumber-1)),
                                             Baud, Parity, Data, Stop,
                                             COM_InSize, COM_OutSize, DefPortOptions));
                     if AsyncStatus <> ecOk then begin
                       WriteLn('Failed to open port: ', AsyncStatus);
                       Estat := False;
                       Fail;
                     end;
                     if XonXoff then
                       APort^.SWFlowEnable(Round(COM_InSize * 0.75),
                                           Round(COM_InSize * 0.25));
                     if HardwareFlowControl then
                       APort^.HWFlowEnable(Round(COM_InSize * 0.75),
                                           Round(COM_InSize * 0.25),
                                           hfUseDTR or hfRequireDSR or
                                           hfUseRTS or hfRequireCTS);
                     {$ELSE}
                     if PortNumber > 0 then
                       begin
                         StrCopy(Temp, 'COM');
                         StrCat(Temp, Long2Str(T2, PortNumber));
                         StrCat(Temp,':');
                         StrCat(Temp,Long2Str(T2, Baud));
                         StrCat(Temp,',');
                         StrCat(Temp, CharStr(T2, RParity,1));
                         StrCat(Temp,',');
                         StrCat(Temp,Long2Str(T2, Data));
                         StrCat(Temp,',');
                         StrCat(Temp,Long2Str(T2, Stop));
                         StrCat(Temp,',R');
                         BuildCommDCB(Temp, CCDCB);
                         with CCDCB do
                           begin
                             Baudrate := Baud;
{                             StopBits := OneStopBit;}
                             CtsTimeout := 20;
                             XonChar := #$11;
                             XoffChar := #$13;
                             XonLim := 1;
                             XoffLim := 1;
                           end;
                         StrCopy(Temp,'COM');
                         StrCat(Temp, Long2Str(T2, PortNumber));
                         IResult := OpenComm(Temp, COM_InSize, COM_OutSize);
                         if IResult < 0 then
                           begin
                             Case IResult of
                               ie_BadID   : BWCCMessageBox(0,'IE_BADID','OpenComm',mb_IconHand);
                               ie_BaudRate: BWCCMessageBox(0,'IE_BAUDRATE','OpenComm',mb_IconHand);
                               ie_ByteSize: BWCCMessageBox(0,'IE_BYTESIZE','OpenComm',mb_IconHand);
                               ie_Default : BWCCMessageBox(0,'IE_DEFAULT','OpenComm',mb_IconHand);
                               ie_Hardware: BWCCMessageBox(0,'IE_HARDWARE','OpenComm',mb_IconHand);
                               ie_Memory  : BWCCMessageBox(0,'IE_MEMORY','OpenComm',mb_IconHand);
                               ie_NOpen   : BWCCMessageBox(0,'IE_NOPEN','OpenComm',mb_IconHand);
                               ie_Open    : BWCCMessageBox(0,'IE_OPEN','OpenComm',mb_IconHand);
                             end;
                             BWCCMessageBox(0, 'Cannot Init Port ','OpenComm',mb_OK+mb_IconExclamation);
                             EStat := False;
                             exit;
                           end;
                         SetCommState(CCDCB);
                         EStat := True;
                       end;
                     {$ENDIF}
                    end;
            5..36 : begin
                      Digiboard := True;
                      Estat := True;
                      {$IFNDEF Windows}
                      if UseFastDigi then
                        APort := New(FastDigi14PortPtr,
                                     InitCustom(ComNameType(Ord(PortNumber-1)),
                                                Baud, Parity, Data, Stop,
                                                COM_InSize, COM_OutSize, DefPortOptions))
                      else
                        APort := New(Digi14PortPtr,
                                     InitCustom(ComNameType(Ord(PortNumber-1)),
                                                Baud, Parity, Data, Stop,
                                                COM_InSize, COM_OutSize, DefPortOptions));
                      if AsyncStatus <> ecOk then begin
                        WriteLn('Failed to open port: ', AsyncStatus);
                        Estat := False;
                        Fail;
                      end;
                      if XonXoff then
                        APort^.SWFlowEnable(Round(COM_InSize * 0.75),
                                            Round(COM_InSize * 0.25));
                      if HardwareFlowControl then
                        APort^.HWFlowEnable(Round(COM_InSize * 0.75),
                                            Round(COM_InSize * 0.25),
                                            hfUseDTR or hfRequireDSR or
                                            hfUseRTS or hfRequireCTS);
                      {$ELSE}
                      New(DPort, InitComm(PortNumber, Baud, RParity,
                                          Data, Stop, XonXoff));
                      {$ENDIF}
                    end;
            end;
        end;

      destructor SerialPort.Done;    { also closes port }
        var i: integer;
        begin
          {$IFNDEF Windows}
          Dispose(APort, Done);
          {$ELSE}
          if Digiboard then
            Dispose(DPort, Done)
          else
            begin
            for i := 1 to 1000 do;    { This is really unsociable, but I need }
            CloseComm(CCDCB.ID);      { to give the last char time to xmit    }
            end;
          {$ENDIF}
        end;

      Function SerialPort.CommOK: boolean;
        begin
          CommOK := Estat;
        end;

      function SerialPort.WriteChar(Ch: char): boolean;
        begin
          {$IFNDEF Windows}
          APort^.PutChar(Ch);
          WriteChar := APort^.TransReady;
          if TXAutoWait then
            While BytesInOutputBuffer > 0 do;
          {$ELSE}
          if Digiboard then
            WriteChar := DPort^.WriteChar(Ch)
          else
            begin
            While TransmitCommChar(CCDCB.Id, Ch) <> 0 do;
            WriteChar := True;
            end;
          {$ENDIF}
        end;

      function SerialPort.WriteString(var S: String): boolean;
      var
        i: integer;
        begin
          {$IFNDEF Windows }
          for i := 1 to Length(S) do
            APort^.PutChar(S[i]);
          WriteString := APort^.TransReady;
          {$ELSE}
          if Digiboard then
            begin
            for i := 1 to length(S) do
              DPort^.WriteChar(S[i]);
            end
          else
            begin
            for i := 1 to length(S) do
              While TransmitCommChar(CCDCB.Id, S[i]) <> 0 do;
            end;
          WriteString := True;
          {$ENDIF}
        end;

      function SerialPort.ReadChar(var Ch: char): boolean;
        begin
          {$IFNDEF Windows}
          if APort^.CharReady then
            begin
            APort^.GetChar(Ch);
            ReadChar := True;
            end
          else
            ReadChar := False;
          {$ELSE}
          if Digiboard then
            ReadChar := DPort^.ReadChar(Ch)
          else
            ReadChar := ReadComm(CCDCB.Id, PChar(Ch), 1) > 0;
          {$ENDIF}
        end;

      procedure SerialPort.GetStatus(var Line, Modem: byte);
        begin
          {$IFNDEF Windows}
          Modem := APort^.GetModemStatus;
          Line  := APort^.GetLineStatus;
          {$ELSE}
          if Digiboard then
            begin
            Line := DPort^.Linestat;
            Modem := DPort^.ModemStat;
            end
          else
            Line := 0;
          {$ENDIF}
        end;

      procedure SerialPort.FlushBuffers;
        begin
          {$IFNDEF Windows}
          APort^.FlushInBuffer;
          APort^.FlushOutBuffer;
          {$ELSE}
          if Digiboard then
            DPort^.FlushBuffers
          else
            begin
            FlushComm(CCDCB.Id, 0);
            FlushComm(CCDCB.Id, 1);
            end;
          {$ENDIF}
        end;

      procedure SerialPort.FlushRXBuffer;
        begin
          {$IFNDEF Windows}
          APort^.FlushInBuffer;
          {$ELSE}
          if Digiboard then
            DPort^.FlushRXBuffer
          else
            FlushComm(CCDCB.Id, 1);
          {$ENDIF}
          EStat := True;
        end;

      procedure SerialPort.FlushTXBuffer;
        begin
          {$IFNDEF Windows}
          APort^.FlushOutBuffer;
          {$ELSE}
          if Digiboard then
            DPort^.FlushTXBuffer
          else
            FlushComm(CCDCB.Id, 1);
          {$ENDIF}
          EStat := True;
        end;

      function SerialPort.BytesFreeInOutput: word;
        begin
          {$IFNDEF Windows}
          BytesFreeInOutput := APort^.OutBuffFree;
          {$ELSE}
          if Digiboard then
            BytesFreeInOutput := DPort^.BytesFreeInOutput
          else
            BytesFreeInOutput := 0;
          {$ENDIF}
        end;

      function SerialPort.BytesInOutputBuffer: word;
        begin
          {$IFNDEF Windows}
          BytesInOutputBuffer := APort^.OutBuffUsed;
          {$ELSE}
          if Digiboard then
            BytesInOutputBuffer := Dport^.TxSize-BytesFreeInOutput
          else
            BytesInOutputBuffer := 0;
          {$ENDIF}
        end;

      function SerialPort.BytesInInput: word;
        begin
          {$IFNDEF Windows}
          BytesInInput := APort^.InBuffUsed;
          {$ELSE}
          if Digiboard then
            DPort^.BytesInInput
          else
            BytesInInput := 0;  { No Windows function for this }
          {$ENDIF}
        end;

      procedure SerialPort.GetDriverName;
        begin
          Driver := 'COMM';
        end;

      procedure SerialPort.SetSignals(NewSet: byte);
      const
        DTR = $01;                         (* Data Terminal Ready *)
        RTS = $02;                         (* Request TO Send *)
        begin
          {$IFNDEF Windows}
          APort^.SetModem(Newset and DTR = DTR, Newset and RTS = RTS);
          {$ELSE}
          if Digiboard then
            DPort^.SetHandshakeLines;
          {$ENDIF}
        end;

      procedure SerialPort.ClearSignals(NewSet: byte);
      const
        DTR = $01;                         (* Data Terminal Ready *)
        RTS = $02;                         (* Request TO Send *)
        begin
          {$IFNDEF Windows}
          APort^.SetModem(not (Newset and DTR = DTR), not (Newset and RTS = RTS));
          {$ENDIF}
        end;

      {$IFNDEF Windows}
      function FastDigi14Port.InBuffUsed : Word;
      var Regs: Registers;
      begin
        with PR^, Regs do begin
          AH := $15;     { Uses 15h service instead of 0Ah }
          DX := Ord(PortName);
          Intr($14, Regs);
          if DH = $FF then begin
            InBuffUsed := 0;
          end else begin
            InBuffUsed := AX;
          end;
        end;
      end;
      {$ENDIF}


End.
