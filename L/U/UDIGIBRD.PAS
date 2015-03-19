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
{$A-,R-,S-,F+}
{$IFNDEF Windows }
{$O+}
{$ENDIF}

{$DEFINE ExtendedInit}   { Use new extended initialization }

{-------------------------------------------------------------------}
{ (C)1991 NewsMaker Systems.                                        }
{ Digiboard COM/xi driver interface routines.                       }
{-------------------------------------------------------------------}

{  ** Important ** The digiboard interface is different as of driver   }
{  version XIDOS5. This interface is no longer compatible with drivers }
{ of XIM232 vintage.                                                   }

Unit UDigibrd;

interface

{$IFNDEF Windows }
Uses Dos, OpCrt, OpString;
{$ELSE}
Uses WinDos, OpString;
{$ENDIF}

Const
  DXBase = 4;     {!!!!! Driver must be configured to use DX = 4 }

{ Interface object for Digiboard Com/Xi driver XIDOSx }

Type

  DigiPortPtr = ^DigiPort;
  DigiPort = Object
      Port      : word;
      Baud      : word;
      Parity    : char;
      Data      : word;
      Stop      : word;
      Config    : byte;        { Bit pattern for Baud, Data, Stop, Parity }
      LineStat  : byte;
      ModemStat : byte;
      Driver    : String[8];
      Error     : ShortInt;
      EStat     : boolean;
      TXSize    : word;
      RXSize    : word;
      TXWMark   : word;
      CharsInBuf: word;        { Chars currently in input buffer }
      CharsFree : word;        { Chars available in output buffer }

      procedure Int14(FCode: byte; var AX_Reg: word);

      constructor InitComm(PortNum: word;    { 1-8 }
                           BaudRate: word;   { 110-9600}
                           RParity: char;    { N, E, O }
                           DataBits: word;   { 5-8 }
                           StopBits: word;   { 1-2 }
                           XonXoff : boolean);
      destructor Done;    { also closes port }
      Function CommOK: boolean; virtual;
      procedure SetProtocol(XonXoff: boolean);
      function WriteChar(Ch: char): boolean; virtual;
      function ReadChar(var Ch: char): boolean; virtual;
      procedure GetStatus(var Line, Modem: byte); virtual;
      procedure FlushBuffers; virtual;
      procedure FlushRXBuffer; virtual;
      procedure FlushTXBuffer; virtual;
      function BytesFreeInOutput: word; virtual;
      function BytesInInput: word; virtual;
      procedure GetDriverName; virtual;
      procedure SetPauseStatus(OnOff: boolean);
      procedure SetTXLowWaterMark(M: integer);
      procedure GetBufferSize(var TXMark: word; var Buffer: word);
      procedure SetBufferMode(OnOff: boolean);
      procedure SetHandshakeLines;

    end;

  function DigiboardPresent: boolean;

implementation

var
  {$IFNDEF Windows }
  Regs: Registers;
  {$ELSE}
  Regs: TRegisters;
  {$ENDIF}
  AX  : word;
  B   : byte;
  OldDriver: boolean;

  function DigiboardPresent: boolean;
    var f: file;
        ir: integer;
    begin
      OldDriver := False;
      {$I-}
      Assign(f, '~XIM232~');           { Old driver }
      Reset(F);
      ir := Ioresult;
      if ir = 0 then
        begin
          DigiboardPresent := True;
          OldDriver := True;
          exit;
        end;
      Assign(f, 'DIGIFEP5');          { current driver }
      Reset(F);
      ir := Ioresult;
      if ir = 0 then
        begin
          DigiboardPresent := True;
          exit;
        end;
      {$I+}
      DigiboardPresent := False;
    end;

  { Function 00h - Initialize port }

  constructor DigiPort.InitComm(PortNum: word;    { 1-8 }
                                BaudRate: word;   { 110-9600}
                                RParity: char;    { N, E, O }
                                DataBits: word;   { 5-8 }
                                StopBits: word;   { 1-2 }
                                XonXoff : boolean);
    begin
      AX := 0;
      Port   := PortNum;
      Baud   := BaudRate;
      Parity := UpCase(RParity);
      Data   := DataBits;
      Stop   := StopBits;
  {$IFNDEF ExtendedInit}
      Case Data of
          5   : AX := AX or 0;
          6   : AX := AX or 1;
          7   : AX := AX or 2;
          8   : AX := AX or 3;
        end;
      Case Stop of
          1   : AX := AX or (0 shl 2);
          2   : AX := AX or (1 shl 2);
        end;
      Case Parity of
          'N'   : AX := AX or (0 shl 3);
          'O'   : AX := AX or (1 shl 3);
          'E'   : AX := AX or (3 shl 3);
        end;
      Case Baud of
          110   : AX := AX or (0 shl 5);
          150   : AX := AX or (1 shl 5);
          300   : AX := AX or (2 shl 5);
          600   : AX := AX or (3 shl 5);
          1200  : AX := AX or (4 shl 5);
          2400  : AX := AX or (5 shl 5);
          4800  : AX := AX or (6 shl 5);
          9600  : AX := AX or (7 shl 5);
        end;
      AX := AX and $FF;
      Config := Lo(AX);
      Int14($00, AX);
  {$ELSE}
      with Regs do
        begin
          Al := 0;          { no break }
          Case Parity of
              'N' : Bh := 0;
              'O' : Bh := 1;
              'E' : Bh := 2;
            end;
          Case Stop of
            1 : Bl := 0;
            2 : Bl := 1;
            end;
          Case Data of
            5 : Ch := 0;
            6 : Ch := 1;
            7 : Ch := 2;
            8 : Ch := 3;
            end;
          Case baud of
            110   : Cl := $0;
            150   : Cl := $1;
            300   : Cl := $2;
            600   : Cl := $3;
            1200  : Cl := $4;
            2400  : Cl := $5;
            4800  : Cl := $6;
            9600  : Cl := $7;
            19200 : Cl := $8;
            38400 : Cl := $9;
            57600 : Cl := $0A;
 {           76800 : Cl := $0B;
            115200: Cl := $0C;}
            50    : Cl := $0D;
            75    : Cl := $0E;
            134   : Cl := $0F;
            200   : Cl := $10;
            1800  : Cl := $11;
            end;
        end;
      Int14($04, AX);
  {$ENDIF}
      Error := (AX shr 8) and $FF;
      If Error >= 0 then
        begin
{          GetDriverName;
          GetStatus(b,b);}
          SetProtocol(XonXoff);
          GetBufferSize(TXWMark, TXSize);
        end;
    end;

  function DigiPort.CommOK: boolean;
    begin
      CommOK := Error >= 0;
    end;

    { Function 01h - Write Character }

  function DigiPort.WriteChar(Ch: char): boolean;
    begin
      AX := Ord(Ch);
      Int14($01, AX);
      WriteChar := (AX shr 8) and $FF >= 0;
      CharsFree := BytesFreeInOutput+1;
      While CharsFree < TXSize do
        CharsFree := BytesFreeInOutput+1;
    end;

    { Function 02h - Read Character }

  function DigiPort.ReadChar(var Ch: char): boolean;
    begin
      if BytesInInput = 0 then
        begin
          ReadChar := False;
          exit;
        end;
      AX := 0;
      Int14($02, AX);
      ReadChar := (AX shr 8) and $FF >= 0;
      Ch := Char(Regs.AL);
    end;

    { Function 03h - Get Line and Modem status }

  procedure DigiPort.GetStatus(var Line, Modem: byte);
    begin
      AX := 0;
      Int14($03, AX);
      LineStat := Regs.AH;
      ModemStat := Regs.AL;
      Line := LineStat and $7F;
      Modem := ModemStat;
    end;

    { Function 1Eh - Set Protocol (Flow control) }

  procedure DigiPort.SetProtocol(XonXoff: boolean);
    begin
      regs.BX := 0;
      if XonXoff then
        Regs.Bh := 3
      else
        Regs.Bl := $A;    { bits 1+4 = RTS/CTS protocol }
      Int14($1E, AX);
      Regs.BX := 0;
      SetHandshakeLines;
    end;

    { Function 06h - Get DOS Driver name }

  procedure DigiPort.GetDriverName;
    var P: Pointer;
        W : Array[1..2] of word absolute P;
    begin
      AX := $FF;       { sub-function ff = driver name }
      Int14($06, AX);
      Move(Regs.ES, W[1], 2);
      Move(Regs.BX, W[2], 2);
      Move(P^,Driver[1],8);
      Driver[0] := #8;
      Driver := Trim(Driver);
    end;

    { Function 09h - Flush both buffers }

  procedure DigiPort.FlushBuffers;
    begin
      AX := 0;
      Int14($09, AX);
    end;

    { Function 0Ah - Close port ** does not exist in XIDOS5 }

  destructor DigiPort.Done;    { also closes port }
    begin
    end;

    { Function 10h - Flush RX buffer }

  procedure DigiPort.FlushRXBuffer;
    begin
      AX := 0;
      Int14($10, AX);
    end;

    { Function 11h - Flush TX buffer }

  procedure DigiPort.FlushTXBuffer;
    begin
      AX := 0;
      Int14($11, AX);
    end;

    { Function 12h - Bytes available in output buffer }

  function DigiPort.BytesFreeInOutput: word;
    begin
      AX := 0;
      Int14($12, AX);
      BytesFreeInOutput := AX;
    end;

    { Function 0Ah - Bytes in input buffer }

  function DigiPort.BytesInInput: word;
    begin
      AX := 0;
      if OldDriver then
        Int14($15, AX)
      else
        Int14($15, AX);    { should be 0A according to documentation }
      BytesInInput := AX;
    end;

  procedure DigiPort.SetPauseStatus(OnOff: boolean);
    begin
      AX := 1;
      Int14($17, AX);
    end;

  procedure DigiPort.SetTXLowWaterMark(M: integer);
    begin
      AX := 0;         { Set TX mark }
      Regs.BX := M;    { Mark value }
      Int14($1C, AX);
      AX := 2;
      Int14($1F, AX);
    end;

  procedure DigiPort.GetBufferSize(var TXMark: word; var Buffer: word);
    begin
      AX := 0;         { Get TX mark  }
      Int14($1B, AX);
      TXMark := Regs.AX;
      Buffer := Regs.BX;
    end;

  procedure DigiPort.SetBufferMode(OnOff: boolean);
    begin
      AX := 1;
      Regs.Cx := 0;
      Int14($FF, AX);
    end;

  procedure DigiPort.SetHandshakeLines;
    begin
      AX := 1;
      Regs.Cx := 0;
      Int14($13, AX);
    end;

    { Utility routine to set registers, and call Interrupt 14 }
    { DX is Port number-1 (0=Port1), AH contains function code}
    { AL contains parameter. Data is returned in AX           }

  procedure DigiPort.Int14(FCode: byte; var AX_Reg: word);
    begin
      with Regs do
        begin
          DX := DXBase + (Port-1);   { Base 0 }
          AX := AX_Reg;
          AH := FCode;
        end;
      Intr($14, Regs);
      AX_Reg := Regs.AX;
    end;

Begin
  if DigiBoardPresent then;
End.
