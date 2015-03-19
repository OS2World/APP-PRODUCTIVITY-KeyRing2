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
{$A-,R-,S-,V-,F+,X+,O-}

{ Shared global definitions for SPX transfers }

Unit USPXGlo;

interface

{$IFDEF Windows}
Uses QGlobal, USpxMsg, UDirec, R_Glo;
{$ELSE}
Uses Dos, USpxDat, UDirec, UGlobal, QGlobal, R_Glo, Nwbase;
{$ENDIF}

  { Message Types }
Const
  neNoResponse    = $FF;
  neACK           = 01;  { Acknowledge good packet }
  neNACK          = 02;  { No-Acknowledge bad packet }
  neStatus        = 03;  { Return NEN status record }
  neChannel       = 04;  { Start a conversation on new socket }
  ne2Way          = 05;  { Pass IDs for 2-way conversation }
  neWhoAreYou     = 06;  { Get NEN program family info }
  nePeek          = 07;  { Get memory location for n bytes }
  neGetDirec      = 08;  { Get directory of path specified }
  neGetFile       = 09;  { Get file }
  neSendFile      = 10;  { Send File }
  neLastMessage   = 11;  { Last of a series of messages }
  neMore          = 12;  { More messages to follow }
  neScanList      = 13;  { Scan code list }
  neScanCode      = 14;  { Scan code }
  neDirect        = 15;  { Direct, dialog type connect }
  neGetScreen     = 16;  { Get Screen array }
  neGetConfig     = 17;  { Get hardware configuration }
  neUnknown       = 18;  { Request unknown }
  neConfirm       = 19;  { Ask other side for confirmation }
  neGetServices   = 20;  { Ask for list of services }
  neCommand       = 21;  { Perform Service }
  neGetParam      = 22;  { Remote request for user parameter }
  neViewFile      = 23;  { View file }
  neMasterInfo    = 24;  { Details about controlling machine }
  neRunMacro      = 25;  { Run this macro }
  neRemoteInfo    = 26;  { User name and Conn Number of remote }
  neDeviceStatus  = 27;  { Availability of, or owner of device }
  neListDevices   = 28;  { Get List of devices }
  neAssignDevice  = 29;  { Assign control of a slave device }
  neReleaseDevice = 30;  { Release assigned device }
  neAreYouThere   = 31;  { Just checking! }
  neSuspendPoll   = 32;  { Disable timeout if polling }
  neResumePoll    = 33;  { resume polling }
  neConnect       = 100; { No Data, just requesting connect }
  neTimeout       = 200;

  neDisconnect    = 254; { Terminate this connection }
  neNull          = 255; { !!Note SPX needs $FE and $FF itself }

Type
  {$IFDEF Windows}
  PathStr = String[79];
  {$ENDIF}

   PeekRec = Record       { One packet for memory address peek }
       Address : Pointer;
       Len     : word;
     end;

   DirSpec = Record       { One packet for directory entry }
     Path  : PathStr;
     Sort  : word;
     UpDown: boolean;
     end;

   ScanCodeRec = Array[1..256] of word; { One packet for scan code list }

   FileSpec = Record               { One packet for file transfer }
       Count  : word;
       Data   : Array[1..500] of byte
     end;

   {$IFDEF Windows}
   Type
     BigString = String;
   {$ENDIF}

   ParamType = (prNone, prYesNo, prString, prOK);

   ServiceRec = Record
       Description  : Bigstring;   { Name to appear in menu }
       ParamRequest : ParamType;   { True if NENCON should collect param }
       Prompt       : String[20];  { Prompt for Param input dialog }
       Parameter    : String[50];  { Returned parameter data }
       NumParameter : word;        { Returned numeric parameter data }
       Escape       : boolean;     { Escape pressed on dialog }
       Number       : word;        { Command number }
       Instruction  : word;        { Command to execute next }
     end;
   ServiceList = Array[1..30] of ServiceRec;

  RemoteInfoRec = Record
    ConnNo : Byte;
    User   : String[20];
  end;

  DeviceInfoRec = Record
    DeviceName : String[5];
  end;

   DatapacketPtr = ^DataPacket;
   DataPacket = Record
     Source : word;          { Connection ID of sender }
     ID     : word;          { Message type (See below) }
     Case byte of
{$IFNDEF Windows}
       1 : ( PData  : StatusData );
{$ENDIF}
       2 : ( SData  : String );
       3 : ( Peek   : Peekrec );
       4 : ( WData  : word );
       5 : ( BData  : byte );
       6 : ( LData  : LongInt );
       7 : ( IData  : Integer );
       8 : ( Scan   : ScanCodeRec );
{$IFNDEF Windows}
{       9 : ( Config : CpuInfoRec );}
{$ENDIF}
      10 : ( Direc  : DirRec );
      11 : ( Dir    : DirSpec);
      12 : ( BFile  : FileSpec);
      13 : ( Service: ServiceRec );
      14 : ( Sockets: Array[1..2] of word);
      15 : ( PrInfo : ProgInfoRec);
      16 : ( Remote : RemoteInfoRec );
      17 : ( DDF    : DDFTable);
     end;

  Modes = (Idle, Listening, Receiving, Transmitting, Terminating);

  ConnIDType = (Unknown, NEN_Family, Other, OurSelf);

Const
  PollingActive : boolean = False;
  IPXTrace       : Boolean = False;
  IPXTraceLine25 : Boolean = False;
  SlaveGroup : TnwObjectStr = 'NEN_SLAVE';

implementation

End.
