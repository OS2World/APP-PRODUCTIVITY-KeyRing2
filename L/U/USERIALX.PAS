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
{ Acts as a front end for serial port (COM1-COM4) I/O via LiteComm  }
{ and Digiboard (COM5-COMn) via UDIGIBRD. Simply directs I/O to the }
{ appropriate driver based on COM number.                           }
{ Also supports COM1-COM4 under Windows using DBDCD API calls       }
{ SerialPort object is descended from DigiPort, only LiteComm code  }
{ needs to be called directly from this object.                     }
{                                                                   }
{-------------------------------------------------------------------}

Unit USerial;     { Device independant serial I/O }

interface

{$IFNDEF Windows }
Uses Dos,OpCrt, LctKrnl, LctSupp, LctHayes, UDigibrd, UWindow;
{$ELSE}
Uses WinDos, Objects, OWindows, ODialogs, WinTypes, WinProcs, Strings, WinSys, BWCC,
     OStdDlgs, UDigiBrd;
{$ENDIF}

Type

  SerialPortPtr = ^SerialPort;
  SerialPort = Object(DigiPort)
      Digiboard : boolean;

      {$IFDEF Windows}
      CCDCB      : TDCB;
      ComStat    : TComStat;
      {$ENDIF}

      constructor InitComm(PortNum: word;    { 1-36 }
                           BaudRate: word;   { 110-9600}
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

Const
  COM_InSize    : integer = 1024;
  COM_OutSize   : integer = 1024;

  HardwareFlowControl : boolean = False;

implementation

var
  IResult: integer;

      constructor SerialPort.InitComm(PortNum: word;    { 1-n }
                                      BaudRate: word;   { 110-9600}
                                      RParity: char;    { N, E, O }
                                      DataBits: word;   { 5-8 }
                                      StopBits: word;   { 1-2 }
                                      XonXoff : boolean);
      var Temp: Array[0..60] of char;
          T2 : Array[0..10] of char;
          i : integer;
        begin
          Port   := PortNum;
          Baud   := BaudRate;
          if Baud = 384 then
            Baud := 38400;
          Parity := UpCase(RParity);
          Data   := DataBits;
          Stop   := StopBits;
          Case Port of
            1..4  : begin
                     Digiboard := False;
                     {$IFNDEF Windows}
                     Estat := CommOpen(Port,Baud,Parity,Data,Stop,
                                       COM_InSize, COM_OutSize, True);
                     Delay(10);
                     if XonXoff then
                       if EnableXon(Port,XonXoff) then;
                     {$ELSE}
                     if Port > 0 then
                       begin
                         StrCopy(Temp, 'COM');
                         StrCat(Temp, Long2Str(T2, Port));
                         StrCat(Temp,':');
                         StrCat(Temp,Long2Str(T2, Baud));
                         StrCat(Temp,',');
                         StrCat(Temp, CharStr(T2, Parity,1));
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
                         StrCat(Temp, Long2Str(T2, Port));
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
                      COM_OutSize := 8191;
                      DigiPort.InitComm(PortNum-4,Baud,RParity,
                                        DataBits,StopBits,XonXoff);
                      EStat := Error >= 0;
                    end;
            end;
        end;

      destructor SerialPort.Done;    { also closes port }
        var i: integer;
        begin
          if Digiboard then
            DigiPort.Done else
            begin
            {$IFNDEF Windows}
            CommClose(Port, True);
            {$ELSE}
            for i := 1 to 1000 do;    { This is really unsociable, but I need }
            CloseComm(CCDCB.ID);    { to give the last char time to xmit    }
            {$ENDIF}
            end;
        end;

      Function SerialPort.CommOK: boolean;
        begin
          if Digiboard then
            CommOK := DigiPort.CommOK else
            CommOK := Estat;
        end;

      function SerialPort.WriteChar(Ch: char): boolean;
        begin
          if Digiboard then
            WriteChar := DigiPort.WriteChar(Ch) else
              begin
                {$IFNDEF Windows }
                if HardwareFlowControl then
                  While ModemStatus(Port) and CTS <> CTS do;
                WriteChar := LctPut(Port, byte(Ch));
                {$ELSE}
                While TransmitCommChar(CCDCB.Id, Ch) <> 0 do;
                WriteChar := True;
                {$ENDIF}
              end;
        end;

      function SerialPort.WriteString(var S: String): boolean;
      var
        i: integer;
        begin
          if Digiboard then
            begin
            for i := 1 to Length(S) do
              WriteString := DigiPort.WriteChar(S[i]);
            end
          else
            begin
              {$IFNDEF Windows }
              if HardwareFlowControl then
                While ModemStatus(Port) and CTS <> CTS do;
              WriteString := PutStream(Port, S[1], Length(S)) > 0;
              {$ELSE}
              for i := 1 to length(S) do
                While TransmitCommChar(CCDCB.Id, S[i]) <> 0 do;
              WriteString := True;
              {$ENDIF}
            end;
        end;

      function SerialPort.ReadChar(var Ch: char): boolean;
        begin
          if Digiboard then
            ReadChar := DigiPort.ReadChar(Ch) else
              begin
                {$IFNDEF Windows}
                ReadChar := LctGet(Port, byte(Ch));
                {$ELSE}
                ReadChar := ReadComm(CCDCB.Id, PChar(Ch), 1) > 0;
                {$ENDIF}
              end;
        end;

      procedure SerialPort.GetStatus(var Line, Modem: byte);
        begin
          if Digiboard then
            DigiPort.GetStatus(Line, Modem) else
            begin
              {$IFNDEF Windows}
              Modem := ModemStatus(Port);
              {$ENDIF}
              Line := 0;
            end;
        end;

      procedure SerialPort.FlushBuffers;
        begin
          if Digiboard then
            DigiPort.FlushBuffers else
            begin
              {$IFNDEF Windows}
              Estat := PurgeRXBuff(Port);
              Estat := PurgeTXBuff(Port);
              {$ELSE}
              FlushComm(CCDCB.Id, 0);
              FlushComm(CCDCB.Id, 1);
              {$ENDIF}
            end;
        end;

      procedure SerialPort.FlushRXBuffer;
        begin
          if Digiboard then
            DigiPort.FlushRXBuffer else
            begin
              {$IFNDEF Windows}
              Estat := PurgeRXBuff(Port);
              {$ELSE}
              FlushComm(CCDCB.Id, 1);
              EStat := True;
              {$ENDIF}
            end;
        end;

      procedure SerialPort.FlushTXBuffer;
        begin
          if Digiboard then
            DigiPort.FlushTXBuffer else
            begin
              {$IFNDEF Windows}
              Estat := PurgeTXBuff(Port);
              {$ELSE}
              FlushComm(CCDCB.Id, 1);
              EStat := True;
              {$ENDIF}
            end;
        end;

      function SerialPort.BytesFreeInOutput: word;
        begin
          if Digiboard then
            BytesFreeInOutput := DigiPort.BytesFreeInOutput else
              begin
                {$IFNDEF Windows}
                BytesFreeInOutput := COM_OutSize - BytesInOutput(Port);
                {$ELSE}
                BytesFreeInOutput := 0;
                {$ENDIF}
              end;
        end;

      function SerialPort.BytesInOutputBuffer: word;
        begin
          if Digiboard then
            BytesInOutputBuffer := 8192-DigiPort.BytesFreeInOutput else
              begin
                {$IFNDEF Windows}
                BytesInOutputBuffer := BytesInOutput(Port);
                {$ELSE}
                BytesInOutputBuffer := 0;
                {$ENDIF}
              end;
        end;

      function SerialPort.BytesInInput: word;
        begin
          if Digiboard then
            BytesInInput := DigiPort.BytesInInput else
              begin
                {$IFNDEF Windows}
                BytesInInput := LctSupp.BytesInInput(Port);
                {$ELSE}
                BytesInInput := 0;  { No Windows function for this }
                {$ENDIF}
              end;
        end;

      procedure SerialPort.GetDriverName;
        begin
          if Digiboard then
            DigiPort.GetDriverName else
            Driver := 'COMM';
        end;

      procedure SerialPort.SetSignals(NewSet: byte);
        begin
          {$IFNDEF Windows}
          if not Digiboard then
            SetModemSignals(Port, NewSet);
          {$ENDIF}
        end;

      procedure SerialPort.ClearSignals(NewSet: byte);
        begin
          {$IFNDEF Windows}
          if not Digiboard then
            ClearModemSignals(Port, NewSet);
          {$ENDIF}
        end;

End.
