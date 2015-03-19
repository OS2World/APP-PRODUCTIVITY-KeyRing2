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
{$A-,R-,S-,V-,F+,X+}
{$O+}
{*********************************************************}
{ (C)1991 NewsMaker Systems.                              }
{ Inter-NEN communication via IPX NetWare services        }
{                                                         }
{ Provides single-channel Sender for NENCON and NEN Count }
{ and a Multi-Tasking, Multi-Channel responder for all    }
{ Programs that call UpTime or UpdateWTime                }
{                                                         }
{ The System task accepts requests on the NewsMaker unique}
{ socket number, and responds accordingly. Because only   }
{ one conversation can take place on that socket at a time}
{ 2-way conversations spawn additional tasks running on   }
{ public sockets.                                         }
{                                                         }
{ Handles both sides of conversation as follows:          }
{ MASTER - Builds list of users from Bindery, & list of   }
{          connections for each user. Each conn is then   }
{          checked for a responding slave on the NewsMaker}
{          Socket ID. Slave can then be queried.          }
{ SLAVE  - Called repeatedly from UpTime, action depends  }
{          on IPXMode variable as follows:                }
{   IDLE     Issues a ListenForConn on NEN Socket & sets  }
{            IPXMode to LISTEN                            }
{   LISTEN   Checks for event complete, acts on message   }
{            type received.                               }
{   RECEIVE  Waits for message to be received             }
{   TRANSMIT Waits for completion of transmit             }
{                                                         }
{*********************************************************}

unit UIPXSPX;                     { IPX/SPX task communication for NEN }
{$I MCDEFINE.INC}

interface

uses
    Dos,
    OpDos,
    OpCrt,
    OpString,
    OpDate,
    OpCol16,
    Nwbase,
    NwBind,
    NWIpxSpx,
    QGlobal,
    QHDrRec,
    QInput,
    QNovell,
    USpxGlo,
    USpxDat,
    UGlobal,
    UDirec,
    UCpuID,
    USpxMsg,
    R_Glo;

type

  AbstractSocketPtr = ^AbstractSocket;
  AbstractSocket = object
                     Packet         : DataPacketPtr;
                     TXEvent        : PipxEventRec;
                     RXEvent        : PipxEventRec;
                     {--------------------------- All dynamically allocated }
                     {                            vars must be above this line }
                     TXSocket       : Word;
                     RXSocket       : Word;
                     ConnNo         : Byte;
                     TaskNo         : Byte;
                     PoolIndex      : Byte;
                     ID             : word;
                     IPXMode        : Modes;
                     EventTime      : LongInt;
                     DisconnectTime : LongInt;
                     PacketSize     : Word;
                     NetAddress     : IPXAddress; { Physical address for IPX }
                     IPXStatus      : Byte;
                     Connected      : Boolean;
                     LastTXTime     : LongInt;
                     LastRXTime     : LongInt;

                     constructor Init(DoAlloc: boolean);
                     destructor Done;
                     function TransmitPacket(PID : word; Len: word): word;
                     function ReceivePacket(PID : word): word;

                   end;

  { LoggedInConnection - Represents one connection for a user }
  {                      These objects belong to LoggedInUser }
  { This object handles communication to & from the connection}

  PLoggedInConnection = ^LoggedInConnection;
  LoggedInConnection = object(AbstractSocket)
                         NextConn       : PLoggedInConnection;
                         ConnID         : ConnIDType; { Responds on NEN socket }
                         UserName       : string;  { Name of logged in user }

                         ProgramInfo    : ProgInfoRec;

                         IsNEN          : Boolean; { If true, we are in NENConnnectionList }

                         constructor Init(ConnAddr       : PLoggedInConnection;
                                          UName          : String;
                                          Lconn          : Byte;
                                          DoAlloc        : boolean);
                         destructor Done;
                         procedure FindID;
                         procedure WhoAreYou;
                         function SendString(PID : word; Data : String): word;
                         function SendMessage(PID : word; var Data; len : Word): word;
                         function SendPacket(PID : word): word;
                         procedure GetResponse(var PID : word);
                         function Connect : Boolean;
                         function Establish2Way : Boolean;
                         function AreYouThere : Boolean;
                         function DirectConnect : Boolean;
                         procedure Disconnect;
                       end;

  { LoggedInUser - represents one logged in user, maintains list }
  {                of connections for user                       }

  LoggedInUserPtr = ^LoggedInUser;
  LoggedInUser   = object(AbstractSocket)
                     NextUser       : LoggedInUserPtr;
                     UserName       : String;  { Name of logged in user }
                     Conns          : ConnectionList; { Connections for this user }
                     ConnList       : PLoggedInConnection;

                     constructor Init(UserAddr : LoggedInUserPtr; LName : ObjectStr);
                     destructor Done;
                     procedure IdentifyConnections(GetInfo : Boolean);
                   end;

  { Conversation - Represents one slave connection                 }
  { One conversation should always be open on the NEN Socket       }
  { Other conversations may be opened in response to ChannelChange }
  { requests on the main socket                                    }

  ConversationPtr = ^Conversation;
  Conversation   = object(AbstractSocket)
                     Active         : Boolean;
                     Destroy        : Boolean; { If TRUE, this object will be killed }
                     { by the task manager                 }
                     RemoteConn     : Byte; { ConnID of connected User            }
                     RemoteUser     : ObjectStr; { User name of remote                 }

                     {    SlaveInfo       : PSlaveInfoRec;}

                     ListenStatus   : Byte;
                     RXEventTime : LongInt;

                     ResponseStatus : Byte;
                     ReceiveTimeOut : LongInt;
                     ReceiveEventTime : LongInt;

                     Transmitter    : Word;
                     MessagePending : Boolean;

                     ItemCount      : Integer;
                     CurItem        : Integer;

                     ParameterReceived : Boolean;
                     IPXParameter   : String[30];

                     constructor Init(TSocket, RSocket : Word; Task : Byte; RCon: word);
                     constructor InitSlave(SlaveNo, TSocket, RSocket : Word; Task : Byte; RCon: word);
                     destructor Done;
                     procedure Check;
                     procedure Process;
                     procedure Disconnect;
                     procedure ReturnString(PID : word; Data : String);
                     procedure ReturnData(PID : word; var Data; len : Word);
                     procedure ReturnPacket(PID : word);
                     function GetParameter(var S : String) : Boolean;
                   end;

  TraceString    = String[80];

  { Hook to debugging trace display procedure }
  TraceDisplayProc = procedure(CR : Boolean; Msg : TraceString);

  { Hook to Ack responder procedure for a task }
  AckHandlerProc = procedure(CItem : ConversationPtr);

  { Hook to procedure to provide list of programs services }
  AdvertizeProc  = procedure(CItem : ConversationPtr;
                             var Services   : ServiceList;
                             var NumServices : Integer);

  { Hook to procedure to process a programs service }
  CommandHandlerProc = procedure(CItem : ConversationPtr;
                                 Command        : ServiceRec);

  { Hook to a procedure to run during timeout loops }
  BackgroundProcessor = procedure;

  { Hook to SendMacro procedure }
  IPXSendMacroProc = procedure(User : ObjectStr; MName : String);

  { Checks all open connections for responding copies of NEN }
function CopiesOfNEN : Word;

  { Process a received message }
procedure HandleIPXMessage;

  { Turns tracing on/off *Debug only* }
procedure SetIPXTrace(OnOff : Boolean);

  { return pointer to connection }
function FindConn(Conn : Word) : PLoggedInConnection;

procedure IPXCommandDone(CItem : ConversationPtr; Command : ServiceRec);

function IpxAvail : Boolean;

procedure InitIPX;
procedure CloseIPX;

  {---Internal routines----}

procedure FindLoggedInUsers(GetInfo : Boolean);
procedure FindLoggedInUsersInGroup(Group : ObjectStr);
function FindConnsForUser(UserName : ObjectStr) : Word;
procedure BuildLoggedInUsersMenu(var Mn; var Size : Integer);
procedure ReleaseUserList;
procedure ReleaseNENList;

  { ACK handlers, send next packet of multi-packet transfer }
procedure GetVideoScreen(CItem : ConversationPtr);
procedure SendDirectory(CItem : ConversationPtr);
procedure SendDeviceList(CItem : ConversationPtr);
procedure SendFile(CItem : ConversationPtr);
procedure ReceiveFile(CItem : ConversationPtr);
procedure SendServices(CItem : ConversationPtr);

  { Slave machine control routines }
procedure AssignDevice(CItem : ConversationPtr; Dev : DDFTable);
procedure ReleaseDevice(CItem : ConversationPtr; DevName : ObjectStr);
procedure SendRemoteMacro(CItem : ConversationPtr; var Macro : String);

procedure NullBackgroundProcessor;

const
  UserList       : LoggedInUserPtr = nil; { Linked list of Users (from Bindery) }
  LastUser       : LoggedInUserPtr = nil;
  NENList        : PLoggedInConnection = nil;

  DoTraceLogFile : Boolean = False;

  NEN_TXSocket   : Word = $80E3;  { NewsMaker Systems unique, assigned by Novell }
  NEN_RXSocket   : Word = $0000;  { must be different, take a chance }

  MaxConversations = 10;          { Max simultaneous open sockets/2 }
                                  { (2 sockets per conversation)    }

  IPXRetries : word = 10;         { Max retries on SendPacket }

var
  NENUserCount   : Word;
  Services       : ^ServiceList;

  BuildStatus    : BuildStatusProc; { Points to user supplied status routine }
  { should pack status into a 512 byte rec }
  TraceDisplay   : TraceDisplayProc; { Write data to trace display            }

  AckHandler     : AckHandlerProc; { Called on ACK receipt }

  GetServices    : AdvertizeProc; { User supplied routine to list services}

  HandleCommand  : CommandHandlerProc; { user supplied routine to process service }

  Background     : BackgroundProcessor; { user supplied background processor }

  IPXSendMacro   : IPXSendMacroProc; { User supplied SendMacro procedure }

  Sub_Channel    : array[0..MaxConversations] of ConversationPtr;
  SYS_Channel    : ConversationPtr absolute Sub_Channel;

  OurNetAddress  : IPXAddress;
  OurConnNo      : Word;
  OurUserName    : String[20];
  IPXAvailable   : Boolean;

const
  IPXMessagePending : Boolean = False;

  { Timeout values }

  EventTimeout   : LongInt = 2000; { General }
  MinRXTimeout   : LongInt = 10;
  MaxRXTimeout   : LongInt = 1000;
  ReceiveEventTimeout   : LongInt = 1000;
  ListenTimeOut  : LongInt = 5000; { Listening on public socket # }
  DTime          : LongInt = 150; { Min. time between disconnect & connect }
  SendReceiveTimeout : LongInt = 3000;
  LastIPXCheck   : LongInt = 0;
  MsBetweenChecks : LongInt = 00; { Milliseconds between checks }

implementation

var
  Logged         : Boolean;       { This WS is logged in }
  Version        : Word;          { SPX Version          }
  MaxConn        : Word;          { Maximum SPX Connections }
  AvailConn      : Word;          { SPX Conns available  }


const
  MessageType    : Byte = 1;

  Alloc   = True;
  NoAlloc = False;

var
  VOffset        : Word;          { for use in screen moves }
  AckFirst       : Boolean;
  Path           : PathStr;
  Direc          : ^DosDir;
  DRSpec         : DirSpec;
  F              : file;
{  DDF            : DDFTable;}

const
  TransferInProgress : Boolean = False;

  procedure InterruptsOn; Assembler;
  asm
    sti                           { $FB }
  end;

  procedure InterruptsOff; Assembler;
  asm
    cli                           { $FA }
  end;

  procedure DefaultDisplay(CR : Boolean; Msg : TraceString);
  var
    F              : Text;
  begin
    if IPXTraceLine25 then
      begin
      GotoXY(1,24);
      FastWrite(Pad('',79),24,1,WhiteOnBlue);
      TextColor(White);
      end;
    if CR then
      WriteLn(Msg)
    else
      Write(Msg);
    if DoTraceLogFile then
      begin
        Assign(F, 'IPXR.LOG');
          {$I-}
        Append(F);
        if IoResult <> 0 then
          Rewrite(F);
        if CR then
          WriteLn(F, Msg)
        else
          Write(F, Msg);
        Close(F);
        if IoResult <> 0 then ;
          {$I+}
      end;
  end;

  function Timeout(LastTime, TimeoutVal : LongInt) : Boolean;
  var
    LT             : LongInt;
    CT             : LongInt;
  begin
    CT := TimeMS;
    if CT < LastTime then
      LT := 86400000 - LastTime   { accounts for midnight rollover }
    else
      LT := LastTime;
    Timeout := CT - LT > TimeoutVal;
  end;

  procedure Trace(CPtr : AbstractSocketPtr; Msg : String);
  const IPXM     : array[0..4] of String[4] = ('IDLE', 'LSTN', 'RCVE', 'XMIT', 'EXIT');
  var
    C, T           : Byte;
    S              : Word;
    R              : Word;
  begin
    if SYS^.ProgInfo.ProgName = 'NENCON' then
      FastWrite(#$0D, 1, 80, $1C);
    C := TextAttr;
    T := 0;
    S := NEN_TXSocket;
    R := NEN_RXSocket;
    if CPtr <> nil then
      begin
        T := CPtr^.TaskNo;
        S := CPtr^.TXSocket;
        R := CPtr^.RXSocket;
      end;
    if T < 255 then
      TraceDisplay(False, 'Task ' + Long2Str(T) + ' ' + HexW(S) + '/' + HexW(R) +
                   ' ' + CurrentTimeString('hh:mm:ss')+' ')
    else
      TraceDisplay(False, 'Master ' + HexW(S) + '/' + HexW(R) +
                   ' ' + CurrentTimeString('hh:mm:ss')+' ');
    if CPtr <> nil then TraceDisplay(False, Pad(IPXM[Ord(CPtr^.IPXMode)], 5));
    if Msg[1] = '[' then
      TextColor(Yellow);
    if Msg[1] = '!' then
      TextColor(Red);
    if Msg[1] = '@' then
      begin
        TextColor(Green);
        Delete(Msg, 1, 1);
      end;
    if Msg[1] = '~' then
      begin
        TextColor(LightCyan);
        Delete(Msg, 1, 1);
      end;
    if Msg[1] = '&' then
      begin
        TextColor(LightCyan);
        Delete(Msg, 1, 1);
      end;
    TraceDisplay(True, Msg);
    TextAttr := C;
    if SYS^.ProgInfo.ProgName = 'NENCON' then
      FastWrite(#$20, 1, 80, $11);
  end;

  constructor AbstractSocket.Init(DoAlloc: boolean);
  begin
    TXEvent := IPXAllocEventRec(IPXDoNothingESR);
    RXEvent := IPXAllocEventRec(IPXDoNothingESR);
    PacketSize := SizeOf(DataPacket);
    Packet  := IPXAllocPacket(PacketSize);
    if IPXTrace then
      Trace(@Self, 'Packet Size: '+Long2Str(PacketSize));
  end;

  destructor AbstractSocket.Done;
  begin
    IPXFreeEventRec(TXEvent);
    IPXFreeEventRec(RXEvent);
    IPXFreePacket(Packet);
  end;

  function AbstractSocket.TransmitPacket(PID : word; Len: word): word;
  var
    Retries : word;
    OK      : boolean;
    TotalTime : LongInt;
  begin
    Packet^.Source := OurConnNo;
    Packet^.ID := PID;
    Retries := 0;
    OK := False;
    TotalTime := TimeMS;

    While not OK do
      begin
      IPXSend(TXEvent, NetAddress, TXSocket, False, Len, Packet);
      EventTime := TimeMS;
      LastTXTime := EventTime;
      while not IPXEventComplete(TXEvent, IPXStatus) do
        begin
          Background;
          if Timeout(EventTime, EventTimeout) then
            begin
              inc(Retries);
              if Retries < IPXRetries then
                Continue
              else
                begin
                if IPXTrace then
                  Trace(@Self, '!Timeout on Send Packet');
                Connected := False;
                TransmitPacket := neTimeout;
                Exit;
                end;
            end;
        end;
      if IPXTrace then
        if IPXStatus = IPXSuccess then
          Trace(@Self, '[IPXSend ID: '+Long2Str(Packet^.ID)+' on '+
                        HexW(TXSocket)+' Conn: '+Long2Str(ConnNo)+
                        ' '+Long2Str(Retries)+' Retries]')
          else
          Trace(@Self, '!IPXSend Failed ID: '+Long2Str(Packet^.ID)+' on '+
                        HexW(TXSocket)+' Conn: '+Long2Str(ConnNo)+
                        ' '+Long2Str(Retries)+' Retries');
      PID := ReceivePacket(ID);
      OK := PID <> neNoResponse;
      if TimeOut(TotalTime, 5000) then
        begin
          OK := True;
          PID := neNoResponse;
          if IPXTrace then
            Trace(@Self, '!Timeout on Send/Receive Packet');
          Break;
        end;
      end;

    TransmitPacket := PID;
  end;

  function AbstractSocket.ReceivePacket(PID : word): word;
  var
    RXT : LongInt;
  begin
    if not Connected then
      begin
        PID := neNoResponse;
        ReceivePacket := PID;
        Exit;
      end;
    IPXStatus := IPXListen(RXEvent, RXSocket, false, PacketSize, Packet);
    EventTime := TimeMS;
    While not IPXEventComplete(RXEvent, IPXStatus) do
      begin
      if TimeOut(EventTime, ReceiveEventTimeout) then
        begin
        if IPXTrace then
          Trace(@Self, '!Timeout on Get Response');
        PID := neNoResponse;
        ReceivePacket := PID;
        exit;
        end;
      end;

    LastRXTime := TimeMS;
    RXT := LastRXTime-LastTXTime;
    if (RXT * 2) <> ReceiveEventTimeout then
      begin
      if (RXT >= MinRXTimeout) and (RXT <= MaxRXTimeout) then
        begin
        ReceiveEventTimeout := RXT * 2;
        if IPXTrace then
          Trace(@Self, 'Packet Response '+Long2Str(RXT)+'ms, Timeout = '+Long2Str(ReceiveEventTimeout)+'ms');
        end;
      end;

    if IPXStatus <> IPXSuccess then
      begin
      if IPXTrace then
        Trace(@Self, '!Receive Error '+HexB(IPXStatus));
      PID := neNoResponse;
      end
    else
      begin
      PID := Packet^.ID;
      ID := PID;
      if IPXTrace then
        Trace(@Self, '[Packet Received, ID: '+Long2Str(PID)+']');
      end;
    ReceivePacket := PID;
  end;

  {>>>> LoggedInConnection methods                         }

  constructor LoggedInConnection.Init(ConnAddr       : PLoggedInConnection;
                                      UName          : ObjectStr;
                                      Lconn          : Byte;
                                      DoAlloc        : boolean);
  begin
    if DoAlloc then
      FillChar(TXSocket, SizeOf(LoggedInConnection), #0);
    Inherited Init(DoAlloc);
    ConnNo := Lconn;
    NextConn := ConnAddr;
    ConnID := Unknown;
    UserName := UName;
    {DataPtr  := nil;}
    TXSocket := NEN_TXSocket;
    RXSocket := NEN_RXSocket;
    DisconnectTime := TimeMS;
    Connected := False;
    TaskNo := 255;
    IPXMode := Idle;
    IsNEN := False;
    GetInternetAddress(ConnNo, NetAddress);
    if IPXTrace then
      Trace(@Self, 'Creating connection: ' + Long2Str(ConnNo));
  end;

  destructor LoggedInConnection.Done;
  begin
    if IPXTrace then
      Trace(@Self, 'Deleting ' + Long2Str(ConnNo));
    Inherited Done;
  end;

  function LoggedInConnection.Connect : Boolean;
  var
    TX: word;
  begin
    if Connected then
      begin
      Connect := True;
      if IPXTrace then
        Trace(@Self, 'Already Connected');
      exit;
      end;
    if IPXTrace then
      Trace(@Self, '[Calling ' + Long2Str(ConnNo) + ' on ' + HexW(TXSocket) + '/' + HexW(RXSocket) + ']');
    if ConnNo > 100 then
      begin
        Connect := False;         { CHECK THIS OUT SOMETIME!!! }
        Exit;
      end;

    { Get a unique pair of sockets to use }
    IPXOpenUniqueSocket(Packet^.Sockets[1], True);
    IPXOpenUniqueSocket(Packet^.Sockets[2], True);
    RXSocket := Packet^.Sockets[1];
    Packet^.Source := OurConnNo;
    Packet^.ID := neConnect;
    if IPXTrace then
      Trace(@Self, '[Switching Sockets ' + HexW(Packet^.Sockets[2]) + '/' +
                     HexW(Packet^.Sockets[1]) + ']');

    Connect := True;
    Connected := True;
    TX := Packet^.Sockets[2];

    { Now send a Message to the other station on 80E3, with the socket#s to use }
    GetInternetAddress(ConnNo, NetAddress);
    if SendPacket(neConnect)= neNoResponse then
      begin
        Connect := False;
        Exit;
      end;
    TXSocket := TX;

    IPXCloseSocket(NEN_TXSocket);

    Delay(50);      { give other side time to open new task & post listen }
    Establish2Way;
  end;

  function LoggedInConnection.Establish2Way : Boolean;
  var
    RM             : RemoteInfoRec;
  begin
    RM.ConnNo := OurConnNo;
    RM.User := OurUserName;
    Packet^.Remote := RM;
    ID := SendPacket(neRemoteInfo);
  end;

  procedure LoggedInConnection.FindID;
  var
    IDString   : String[10];
    Temp       : PLoggedInConnection;
  begin
    if CompStruct(OurNetAddress,
                  NetAddress, SizeOf(IPXAddress)) = Equal then
      begin
        ConnID := Ourself;        { Exclude ourself from the list }
        Exit;
      end;
    ConnID := Unknown;
    if Connect then
      begin
        ConnID := NEN_Family;
        Inc(NENUserCount);
        if IPXTrace then
          Trace(@Self, 'Found NEN at ' + Long2Str(ConnNo));
        Delay(50);
        Disconnect;
        { Here comes the fun part. Disconnect ourselves from the users }
        { connection list to the NEN connection list.           !!!.01A}
        NENList := New(PLoggedInConnection, Init(NENList, UserName, ConnNo, NoAlloc));
        if IPXTrace then
          Trace(@Self, 'Allocating PLoggedInConnection ' + Long2Str(SizeOf(NENList^)));

        Temp := NENList^.NextConn;
        Move(TXSocket, NENList^.TXSocket, SizeOf(LoggedInConnection));
        NENList^.NextConn := Temp;
{        NENList^.IsNEN := True;}
      end
    else
      begin
        if IPXTrace then
          Trace(@Self, 'Disposing of Packet/Event buffers');
      end;
  end;

  procedure LoggedInConnection.WhoAreYou;
  begin
    if ConnID <> NEN_Family then Exit;
    if (Connect) then
      begin
        if IPXTrace then
          Trace(@Self, 'Who Are you? ' + Long2Str(ConnNo));
        ID := SendMessage(neWhoAreYou, ConnNo, 2);
        Move(Packet^.PrInfo, ProgramInfo, SizeOf(ProgInfoRec));
        Disconnect;
      end;
  end;

  function LoggedInConnection.AreYouThere : Boolean;
  begin
    if not Connected then
      begin
        AreYouThere := False;
        Exit;
      end;
    ID := SendMessage(neAreYouThere, ConnNo, 2);
    AreYouThere := ID = neACK;
  end;

  function LoggedInConnection.DirectConnect : Boolean;
  var
    OK             : Boolean;
  begin
    OK := False;
    if ConnID <> NEN_Family then Exit;
    if (Connect) then
      begin
        Delay(50);
        ID := SendMessage(neDirect, ConnNo, 2);
        if ID = neACK then
          OK := True;
        if not OK then Disconnect;
      end;
    DirectConnect := OK;
  end;

  function LoggedInConnection.SendString(PID : word; Data : String): word;
  begin
    Packet^.SData := Data;
    SendString := SendPacket(PID);
  end;

  function LoggedInConnection.SendMessage(PID : word; var Data; len : Word): word;
  begin
    Move(Data, Packet^.PData, len);
    PID := SendPacket(PID);
    SendMessage := PID;
  end;

  function LoggedInConnection.SendPacket(PID : word): word;
  var
    Retries : word;
    OK      : boolean;
  begin
    PID := TransmitPacket(PID, PacketSize);
    SendPacket := PID;
  end;

  procedure LoggedInConnection.GetResponse(var PID : word);
  begin
    if not Connected then
      begin
        PID := neNoResponse;
        Exit;
      end;
{    FillChar(Packet^, SizeOf(DataPacket), 0);}
    IPXStatus := IPXListen(RXEvent, RXSocket, false, PacketSize, Packet);
    EventTime := TimeMS;
    While not IPXEventComplete(RXEvent, IPXStatus) do
      begin
      if TimeOut(EventTime, EventTimeout) then
        begin
        if IPXTrace then
          Trace(@Self, '!Timeout on Get Response');
        PID := neNoResponse;
        exit;
        end;
      end;
    if IPXStatus <> IPXSuccess then
      begin
      if IPXTrace then
        Trace(@Self, '!Receive Error '+HexB(IPXStatus));
      PID := neNoResponse;
      end
    else
      begin
      PID := Packet^.ID;
      ID := PID;
      if IPXTrace then
        Trace(@Self, '[Packet Received, ID: '+Long2Str(PID)+']');
      end;
  end;

  procedure LoggedInConnection.Disconnect;
  var I          : Integer;
  begin
    if Connected then
      begin
        if TXSocket <> NEN_TXSocket then
          Delay(10);
        SendMessage(neDisconnect, i, 2);
      end;
    IPXCloseSocket(TXSocket);
    IPXCloseSocket(RXSocket);
    Connected := False;
    if IPXTrace then
      Trace(@Self, '[Disconnecting from ' + Long2Str(ConnNo) +
            ' ' + HexW(TXSocket) + '/' + HexW(RXSocket) + ']');
    TXSocket := NEN_TXSocket;
    RXSocket := NEN_RXSocket;
    DisconnectTime := TimeMS;
  end;

  {>>>> LoggedInUser methods                            }

  constructor LoggedInUser.Init(UserAddr : LoggedInUserPtr; LName : ObjectStr);
  var I          : Integer;
  begin
    Inherited Init(False);
    UserName := LName;
    NextUser := UserAddr;
    ConnList := nil;
    TaskNo := 255;
    IPXMode := Idle;
    TXSocket := 0;
    RXSocket := 0;
    GetObjConnNumbers(UserName, NWBoUser, Conns);
    if Conns.Count > 0 then
      begin
        if IPXTrace then
          Trace(@Self, 'User: ' + UserName + ', ' + Long2Str(Conns.Count) + ' Conns');
        for I := 1 to Conns.Count do
          begin
            New(ConnList, Init(ConnList, UserName, Conns.List[I], Alloc));
            if IPXTrace then
              Trace(@Self, 'Allocating ConnList ' + Long2Str(SizeOf(ConnList^)));
          end;
      end;
  end;

  procedure LoggedInUser.IdentifyConnections(GetInfo : Boolean);
  var I          : Integer;
    CList        : PLoggedInConnection;
  begin
    CList := ConnList;
    while CList <> nil do
      begin
        Background;
        CList^.FindID;
        if GetInfo then
          if CList^.ConnID = NEN_Family then
            NENList^.WhoAreYou;
        CList := CList^.NextConn;
        if IPXTrace then
          Trace(@Self, 'Identify 1');
      end;
  end;

  destructor LoggedInUser.Done;
  var
    CList          : PLoggedInConnection;
    PList          : PLoggedInConnection;
  begin
    if IPXTrace then
      Trace(@Self, 'Deleting User: ' + UserName);
    CList := ConnList;
    while CList <> nil do
      begin
        PList := CList^.NextConn;
        Dispose(CList, Done);
        CList := PList;
      end;
    ConnList := nil;
  end;

  { Conversation methods - Handles slave side of a connection }

  constructor Conversation.Init(TSocket, RSocket : Word; Task : Byte; RCon: word);
  begin
    Inherited Init(True);
    TXSocket := RSocket;
    RXSocket := TSocket;
    Active := False;
    Destroy := False;
    TaskNo := Task;
    IPXMode := Idle;
    MessagePending := False;
    RemoteConn := RCon;
    RemoteUser := '';
{    RXEvent := SPXAllocEventRec(8, sizeof(DataPacket));
    TXEvent := SPXAllocEventRec(2, sizeof(DataPacket));}
    if TaskNo = 0 then
      ReceiveTimeOut := 1000
    else
      ReceiveTimeOut := 64000;
    GetInternetAddress(RCon, NetAddress);

    if TaskNo > 0 then
      ReturnData(neACK, Task, 2);

    Check;
  end;

  constructor Conversation.InitSlave(SlaveNo, TSocket, RSocket : Word; Task : Byte; RCon: word);
  var b          : Byte;
  begin
    Inherited Init(True);
    TXSocket := RSocket;
    RXSocket := TSocket;
    RemoteConn := RCon;
    RemoteUser := '';
    ReceiveTimeOut := 30000;      { 30 seconds }
    if DebugMode then ReceiveTimeOut := MaxLongInt;
    if Task = 0 then
      begin
        ReceiveTimeOut := 64000;
{        TXSocket := NEN_TXSocket;
        RXSocket := NEN_RXSocket;}
      end;
    Active := False;
    Destroy := False;
    TaskNo := Task;
    IPXMode := Idle;
    MessagePending := False;
    GetInternetAddress(RCon, NetAddress);

    if TaskNo > 0 then
      ReturnData(neACK, Task, 2);

    Check;
  end;

  destructor Conversation.Done;
  begin
    if Active then
      Disconnect;
    IPXCloseSocket(TxSocket);
    IPXCloseSocket(RxSocket);
    if IPXTrace then
      Trace(@Self, '@Terminating task ' + Long2Str(TaskNo));
    Inherited Done;
  end;

  procedure Conversation.ReturnString(PID : word; Data : String);
  begin
    Packet^.SData := Data;
    ReturnPacket(PID);
  end;

  procedure Conversation.ReturnData(PID : word; var Data; len : Word);
  begin
    if len > 0 then
      Move(Data, Packet^.PData, len);
    ReturnPacket(PID);
  end;

  procedure Conversation.ReturnPacket(PID : word);
  begin
    Packet^.ID := PID;
    IPXSend(TXEvent, NetAddress, TXSocket, False, PacketSize, Packet);
    if IPXTrace then
      Trace(@Self, '[Sending ID: '+Long2Str(Packet^.ID)+', '+
                   Long2Str(PacketSize)+' bytes to '+Long2Str(RemoteConn)+']');
    IPXMode := Transmitting;
  end;

  procedure Conversation.Check;
  var I,C,T        : Integer;
    TaskOK         : Boolean;
  begin
    IPXRelinquish;
    case IPXMode of
      Listening :
        begin
          if (TaskNo > 0) and (not DebugMode) and
             (Timeout(RXEventTime, ListenTimeOut)) then
            begin
              if IPXTrace then
                Trace(@Self, '!Timeout on Listen');
              IPXMode := Terminating;
              Destroy := True;
              Exit;
            end;
          if not IPXEventComplete(RXEvent,
                                  ListenStatus) then Exit;
          if ListenStatus <> 0 then
            begin
            if IPXTrace then
              Trace(@Self, '!Packet Error '+HexW(ListenStatus));
            IPXMode := Idle;
            MessagePending := False;
            exit;
            end;
          if IPXTrace then
            Trace(@Self, 'Message Received: ' + Long2Str(MessageType) +
                  ' ' + Long2Str(ListenStatus));
          MessageType := neConnect;
          Packet^.ID := MessageType;
          if IPXTrace then
            Trace(@Self, '[Connected with '+Long2Str(Packet^.Source)+']');
          MessagePending := False;
          if IPXTrace then
            Trace(@Self, '[Channel Change to ' +
                  HexW(Packet^.Sockets[1]) + '/' +
                  HexW(Packet^.Sockets[2]) + ']');
          Disconnect;
          TaskOK := False;
          for C := 1 to MaxConversations do
            begin
              if (not TaskOK) and(Sub_Channel[C] = nil) then
                begin
                  TaskOK := True;
                  T := C;
                  if IPXTrace then
                    Trace(@Self, '@Opening Task ' + Long2Str(T));
                  if ThisIsMachineControlSlave then
                    New(Sub_Channel[T], InitSlave(SlaveNumber,
                                                  Packet^.Sockets[2],
                                                  Packet^.Sockets[1],
                                                  T,
                                                  Packet^.Source))
                  else
                    New(Sub_Channel[T], Init(Packet^.Sockets[2],
                                             Packet^.Sockets[1],
                                             T,
                                             Packet^.Source));
                  if Sub_Channel[T] = nil then
                    if IPXTrace then
                      Trace(@Self, '!Not enough memory for task');
                end;
            end;
          if not TaskOK then
            begin
              if IPXTrace then
                Trace(@Self, '!Task table full');
            end;
        end;
      Transmitting :
        begin
          if not IPXEventComplete(TXEvent,
                                  ResponseStatus) then Exit;
          if IPXTrace then
            begin
              Trace(@Self, '&Xmit complete: ID: ' +
                    Pad(Long2Str(Packet^.ID), 3) +
                    ' Stat: ' + HexB(ResponseStatus) +
                    ' Conn: ' + Long2Str(RemoteConn));
            end;
          IPXListen(RXEvent, RXSocket, False, PacketSize, Packet);
          IPXMode := Receiving;
          ReceiveEventTime := TimeMS;
        end;
      Receiving : begin
                    if IPXEventComplete(RXEvent, ListenStatus) then
                      begin
                        if ListenStatus = IPXSuccess then
                          begin
                          MessagePending := True;
{                          Move(DataPtr^, Packet^, SizeOf(DataPacket));}
                          MessageType := Packet^.ID;
                          if IPXTrace then
                              Trace(@Self, '~Receive complete: ID: ' +
                                    Pad(Long2Str(MessageType), 3) +
                                    ' Stat: ' + Long2Str(ListenStatus));
                          end
                        else
                          begin
                            MessagePending := False;
                            MessageType := neNoResponse;
                            IPXMode := Idle;
                            if IPXTrace then
                              Trace(@Self, 'Bad Packet Received'+
                                    ' Stat: ' + HexW(ListenStatus));
                          end;
                      end
                    else
                      begin
                        if Timeout(ReceiveEventTime, ReceiveTimeOut) and
                           (not DebugMode) then
                          begin
                            IPXCloseSocket(RXSocket);
                            IPXMessagePending := False;
                            IPXMode := Idle;
                            if IPXTrace then
                              Trace(@Self, '!Receive Timeout, Resetting channel');
                            if ThisIsMachineControlSlave then
                              begin
                                for I := 1 to NumDDFItems do
                                  if RemoteUser = DDTable^[I].InUseBy then
                                    begin
                                      DDTable^[I].InUse := False;
                                      DDTable^[I].Alias := '';
                                      DDTable^[I].InUseBy := RemoteUser;
                                      DDTable^[I].InUseSince := 0;
                                      DDTable^[I].LastUse := 0;
                                    end;
                              end;
                          end;
                      end;
                  end;
      Idle :
        begin
          ListenStatus := IPXListen(RXEvent,
                                    RXSocket,
                                    False,
                                    PacketSize,
                                    Packet);
          IPXMode := Listening;
          MessagePending := False;
          if IPXTrace then
            Trace(@Self, 'Listening on: ' + HexW(RXSocket));
          RXEventTime := TimeMS;
        end;
      Terminating :
        begin
          if TaskNo = 0 then
            IPXMode := Idle;      { SYS Task keeps running }
        end;
    end;

    TransferInProgress := IPXMode <> Idle;
    IPXRelinquish;

  end;

  function Conversation.GetParameter(var S : String) : Boolean;
  begin
    GetParameter := ParameterReceived;
    S := IPXParameter;
  end;

  procedure Conversation.Disconnect;
  begin
    IPXCloseSocket(TXSocket);
    IPXCloseSocket(RXSocket);
    if IPXTrace then
      Trace(@Self, '[Disconnect]');
    IPXMode := Terminating;
    Active := False;
    Destroy := True;
  end;

  procedure Conversation.Process;
  var
    C, T           : Integer;
    b              : Byte;
    TaskOK         : Boolean;
    NewSockets     : array[1..2] of Word;
    DDF            : DDFTable;
  begin
    if not MessagePending then Exit;
    if IPXMode = Receiving then
      begin
        if Packet^.ID <> neConnect then
          begin
            ReceiveEventTime := TimeMS;
          end;
      end;

    case Packet^.ID of
      neACK :
        begin
          AckHandler(@Self);
        end;
      neLastMessage :
        begin
          AckHandler(@Self);
        end;
      neConnect :
        begin
          if IPXTrace then
            Trace(@Self, '[Connect]');
          ReceiveEventTime := TimeMS;
          NetAddress := RXEvent^.Header.Source;
          IPXMode := Receiving;
          Active := True;
        end;
      neDisconnect :
        begin
          ReturnString(neACK, 'ACK');
          Disconnect;
        end;
      neStatus :
        begin
          BuildStatus(Packet^.PData);
          ReturnPacket(neLastMessage);
          if IPXTrace then
            Trace(@Self, '[Status Request]');
        end;
      neGetConfig :
        begin
          {$IFNDEF NOTNEN}
          GetCPUInfo(Packet^.Config);
          {$ENDIF}
          ReturnPacket(neLastMessage);
          if IPXTrace then
            Trace(@Self, '[Config Request]');
        end;
      ne2Way :
        begin
          ReturnString(neACK, 'ACK');
          if IPXTrace then
            Trace(@Self, '[Establishing 2-way]');
        end;
      neWhoAreYou :
        begin
          Move(SYS^.ProgInfo, Packet^.PData, SizeOf(ProgInfoRec));
          ReturnPacket(neLastMessage);
          if IPXTrace then
            Trace(@Self, '[Who Are You?]');
        end;
      neAreYouThere :
        begin
          ReturnString(neACK, 'ACK');
          if IPXTrace then
            Trace(@Self, '[Are you still there?]');
          PollingActive := True;
        end;
      neSuspendPoll :
        begin
          ReturnString(neACK, 'ACK');
          if IPXTrace then
            Trace(@Self, '[Suspend Polling]');
          PollingActive := False;
          ReceiveTimeOut := MaxLongInt;
        end;
      neResumePoll : 
        begin
          ReturnString(neACK, 'ACK');
          if IPXTrace then
            Trace(@Self, '[Resume Polling]');
          PollingActive := True;
          ReceiveTimeOut := 30000; { 30 seconds }
        end;
      nePeek :
        begin
          ReturnData(neACK, Packet^.Peek.Address^, Packet^.Peek.len);
          if IPXTrace then
            Trace(@Self, '[Peek RQ]');
        end;
      neDirect : 
        begin
          ReturnData(neACK, T, 0);
          if IPXTrace then
            Trace(@Self, '[Direct Connect Initiated]');
          ReceiveTimeOut := MaxLongInt {30000} ; { 30 seconds }
        end;
      neScanCode : 
        begin
          ReturnString(neACK, 'ACK');
          if IPXTrace then
            Trace(@Self, '[Scancode Code ' + HexW(Packet^.WData) + ']')
          else
            StuffKey(Packet^.WData);
        end;
{        neScanList   :   begin
                           if IPXTrace then
                             Trace(@Self,'[Scancode list]');
                           C := 1;
                           Repeat
                             Inc(C);
                             if Packet^.Scan[C] <> 0 then
                               begin
                                 if IPXTrace then
                                   Trace(@Self,'[Key: '+HexW(Packet^.Scan[C])+']');
                                 PushScanCode(Packet^.Scan[C]);
                               end;
                           until Packet^.Scan[C] = 0;
                         end;}
      neGetScreen :
        begin
          if IPXTrace then
            Trace(@Self, '[Get Video Screen]');
          VOffset := 0;
          AckHandler := GetVideoScreen;
          AckHandler(@Self);
        end;
      neGetDirec : 
        begin
          DRSpec := Packet^.Dir;
          DRSpec.Path := StUpCase(Trim(DRSpec.Path));
          if IPXTrace then
            Trace(@Self, '[Get Directory of ' + DRSpec.Path + ']');
          AckFirst := True;
          AckHandler := SendDirectory;
          AckHandler(@Self);
        end;
      neListDevices :
        begin
          if IPXTrace then
            Trace(@Self, '[Get Slave Device List]');
          if not ThisIsMachineControlSlave then
            begin
              if IPXTrace then
                Trace(@Self, '!Error, Not Slave machine');
              ReturnString(neNACK, 'NACK');
            end
          else
            begin
              AckFirst := True;
              AckHandler := SendDeviceList;
              AckHandler(@Self);
            end;
        end;
      neAssignDevice :
        begin
          DDF := Packet^.DDF;
{          ReturnString(neACK, 'ACK');}
          if IPXTrace then
            Trace(@Self, '[Assign Device ' + DDF.DeviceName + ']');
          AssignDevice(@Self, DDF);
        end;
      neReleaseDevice :
        begin
          DDF := Packet^.DDF;
{          ReturnString(neACK, 'ACK');}
          if IPXTrace then
            Trace(@Self, '[Release Device ' + DDF.DeviceName + ']');
          ReleaseDevice(@Self, DDF.DeviceName);
        end;
      neRunMacro :
        begin
          if IPXTrace then
            Trace(@Self, '[Run Macro ' + Packet^.SData + ']');
          ReturnData(neACK, T, 0);
          MessagePending := False; { fix recursion problem }
          IPXAvailable := False;
          SendRemoteMacro(@Self, Packet^.SData);
          IPXAvailable := True;
        end;
      neGetFile : 
        begin
          Path := Packet^.SData;
          if IPXTrace then
            Trace(@Self, '[Get File ' + Path + ']');
          AckFirst := True;
          AckHandler := SendFile;
          AckHandler(@Self);
        end;
      neSendFile :
        begin
          Path := Packet^.SData;
          if IPXTrace then
            Trace(@Self, '[Receive File ' + Path + ']');
          if ExistFile(Path) then
            ReturnData(neConfirm, T, 0)
          else
            ReturnData(neACK, T, 0);
          AckFirst := True;
          AckHandler := ReceiveFile;
        end;
      neGetServices : 
        begin
          if IPXTrace then
            Trace(@Self, '[Get Services]');
          AckFirst := True;
          AckHandler := SendServices;
          AckHandler(@Self);
        end;
      neCommand :
        begin
          ReturnString(neACK, 'ACK');
          if IPXTrace then
            Trace(@Self, '[Command: ' + Long2Str(Packet^.Service.Number) + ']');
          HandleCommand(@Self, Packet^.Service);
        end;
      neRemoteInfo : 
        begin
          ReturnData(neACK, T, 0);
          if IPXTrace then
            Trace(@Self, '[Remote Info: ' + Packet^.Remote.User +
                  ' on Conn: ' + Long2Str(Packet^.Remote.ConnNo) + ']');
          RemoteUser := Packet^.Remote.User;
          RemoteConn := Packet^.Remote.ConnNo;
        end;
      neChannel :
        begin
        end;
      else
        begin
          if IPXTrace then
            Trace(@Self, '!Unknown Function Request ' + Long2Str(Packet^.ID));
          ReturnData(neUnknown, C, 0);
        end;
    end;
    MessagePending := False;
    if IPXMode = Receiving then
      begin
        if Packet^.ID <> neConnect then
          begin
            Packet^.ID := neNull;
          end;
      end;
  end;

  {--------------------------------}
  { General, non-method procedures }
  {--------------------------------}

  function FindConnsForUser(UserName : ObjectStr) : Word;
  begin
    New(UserList, Init(UserList, UserName));
    UserList^.IdentifyConnections(True);
    FindConnsForUser := UserList^.Conns.Count;
    if UserList <> nil then
      Dispose(UserList, Done);    { NEN connections are in NENList }
    UserList := nil;
  end;

  { Build list of logged in users }

  procedure FindLoggedInUsers(GetInfo : Boolean);
  var
    ObjectType     : Word;
    ObjectName     : ObjectStr;

    PropName       : PropertyStr;
    Result         : Byte;
    ObjectID,
    Sequence       : LongInt;
    ObjectIsDynamic: boolean;
    ObjectSecurity,
    PropFlag,
    PropSec        : Byte;
    I              : Integer;

    HasProperties,
    HasValue,
    Done           : Boolean;
    ConnList       : ConnectionList;

  begin
    if not IpxAvail then Exit;
    NENUserCount := 0;
    if UserList <> nil then
      ReleaseUserList;
    ObjectID := - 1;
    repeat
      ObjectType := NWBoUser;
      ObjectName := '*';
      Result := ScanObject(ObjectType, ObjectName, ObjectID, ObjectIsDynamic,
                           ObjectSecurity, HasProperties);
      GetObjConnNumbers(ObjectName, NWboUser, ConnList);
      if Result = 0 then
        if ConnList.Count > 0 then
          begin
            FindConnsForUser(ObjectName);
          end;
      Done := (Result <> 0);
    until Done;
  end;

  procedure FindLoggedInUsersInGroup(Group : ObjectStr);
  var
    ObjectType     : Word;
    ObjectName     : ObjectStr;

    PropName       : PropertyStr;
    Result         : Byte;
    ObjectID,
    Sequence       : LongInt;
    ObjectIsDynamic: boolean;
    ObjectSecurity,
    PropFlag,
    PropSec        : Byte;
    I              : Integer;

    HasProperties,
    HasValue,
    Done           : Boolean;
    ConnList       : ConnectionList;

  begin
    if not IpxAvail then Exit;
    NENUserCount := 0;
    if UserList <> nil then
      ReleaseUserList;
    ObjectID := - 1;

    repeat
      ObjectType := NWboUser;
      ObjectName := '*';
      Result := ScanObject(ObjectType, ObjectName, ObjectID, ObjectIsDynamic,
                           ObjectSecurity, HasProperties);
      FastWrite('Scanning '+ObjectName+' '+Long2Str(TimeMS),23,1,RedOnBrown);
      GetObjConnNumbers(ObjectName, NWboUser, ConnList);
      if Result = 0 then
        if ConnList.Count > 0 then
          begin
            if IsObjectInSet(NWboGroup, Group, GroupMembersSt,
                             NWboUser, ObjectName) = 0 then
              begin
                 FastWrite(ObjectName, 23,60, RedOnBrown);
                 FindConnsForUser(ObjectName);
                 Break;
              end;
          end;
      Done := (Result <> 0);
    until Done;
FastWrite('Done Finding Users', 23,1, RedOnBrown);
  end;

  { Build Menu of logged in users }

  procedure BuildLoggedInUsersMenu(var Mn; var Size : Integer);
  var
    ObjectType     : Word;
    ObjectName     : ObjectStr;

    PropName       : PropertyStr;
    Result         : Byte;
    ObjectID,
    Sequence       : LongInt;
    ObjectIsDynamic: boolean;
    ObjectSecurity,
    PropFlag,
    PropSec        : Byte;
    I              : Integer;
    NMenu          : HugeList absolute Mn;

    HasProperties,
    HasValue,
    Done           : Boolean;
    ConnList       : ConnectionList;

  begin
    if not IpxAvail then Exit;
    NENUserCount := 0;
    ObjectID := - 1;
    repeat
      ObjectType := NWboUser;
      ObjectName := '*';
      Result := ScanObject(ObjectType, ObjectName, ObjectID, ObjectIsDynamic,
                           ObjectSecurity, HasProperties);
      GetObjConnNumbers(ObjectName, NWboUser, ConnList);
      if Result = 0 then
        if ConnList.Count > 0 then
          begin
            Inc(NENUserCount);
            NMenu[NENUserCount] := Pad(ObjectName, 30) + ' ' +
                                   Long2Str(ConnList.Count);
          end;
      Done := (Result <> 0);
    until Done;
    Size := NENUserCount;
  end;

  { Release User list built by FindLoggedInUsers }

  procedure ReleaseUserList;
  var UList      : LoggedInUserPtr;
    PList          : LoggedInUserPtr;
  begin
    if not IpxAvail then Exit;
    UList := UserList;
    while UList <> nil do
      begin
        PList := UList^.NextUser;
        {          Dispose(UList^.ConnList, Done);} {!! 1.08}
        Dispose(UList, Done);
        UList := PList;
      end;
    UserList := nil;
  end;

  { Release NEN Connection list built by FindLoggedInUsers }

  procedure ReleaseNENList;
  var UList      : PLoggedInConnection;
    PList          : PLoggedInConnection;
  begin
    if not IpxAvail then Exit;
    UList := NENList;
    while UList <> nil do
      begin
        PList := UList^.NextConn;
        Dispose(UList, Done);
        UList := PList;
      end;
    NENList := nil;
  end;

  function FindUser(User : ObjectStr) : LoggedInUserPtr;
  var UList      : LoggedInUserPtr;
  begin
    if not IpxAvail then Exit;
    UList := UserList;
    while UList <> nil do
      begin
        Background;
        if StUpCase(UList^.UserName) = StUpCase(User) then
          begin
            FindUser := UList;
            Exit;
          end;
        UList := UList^.NextUser;
      end;
    FindUser := nil;
  end;

  function FindConnection(UList : PLoggedInConnection; Conn : Word) : PLoggedInConnection;
  var CList      : PLoggedInConnection;
  begin
    if not IpxAvail then Exit;
    CList := UList;
    while CList <> nil do
      begin
        Background;
        if CList^.ConnNo = Conn then
          begin
            FindConnection := CList;
            Exit;
          end;
        CList := CList^.NextConn;
      end;
    FindConnection := nil;
  end;

  function FindConn(Conn : Word) : PLoggedInConnection;
  var UList      : LoggedInUserPtr;
    CItem          : PLoggedInConnection;
  begin
    if not IpxAvail then Exit;
    CItem := FindConnection(NENList, Conn);
    if CItem <> nil then
      begin
        FindConn := CItem;
        Exit;
      end;
    FindConn := nil;
  end;

  function CopiesOfNEN : Word;
  begin
    FindLoggedInUsers(False);
    ReleaseUserList;
    CopiesOfNEN := NENUserCount;
  end;

  function IpxAvail : Boolean;
  begin
    if not NetwareLoaded(Logged) then
      begin
        IpxAvail := False;
        Exit;
      end;
    if not Logged then
      begin
        IpxAvail := False;
        Exit;
      end;
    IpxAvail := IPXServicesAvail;
  end;

  procedure SetIPXTrace(OnOff : Boolean);
  begin
    IPXTrace := OnOff;
  end;

  procedure HandleIPXMessage;
  var Peek       : PeekRec;
    C              : Integer;
  begin
    if not IPXMessagePending then Exit;
    for C := 0 to MaxConversations do
      if Sub_Channel[C] <> nil then
        Sub_Channel[C]^.Process;
  end;

  { ACK Handlers. Called on receipt of an ACK to supply next    }
  { packet. After last packet, set AckHandler to NullAckHandler }

  procedure NullAckHandler(CItem : ConversationPtr);
  begin
  end;

  procedure GetVideoScreen(CItem : ConversationPtr);
  begin
    with CItem^ do
      begin
        MoveScreen(Mem[VideoSegment:VOffset], Packet^.WData, 256);
        if IPXTrace then
          Trace(CItem, '[XMit ofs:' + Long2Str(VOffset) + ']');
        Inc(VOffset, 512);
        if VOffset < 4000 then
          ReturnPacket(neMore)
        else
          begin
            ReturnPacket(neLastMessage);
            AckHandler := NullAckHandler;
          end;
      end;
  end;

  procedure SendDirectory(CItem : ConversationPtr);
  var ECode      : Byte;
    DEntry         : DirRec;
    S, D           : Char;
  begin
    with CItem^ do
      begin
        if AckFirst then
          begin
            Direc := nil;
            with DRSpec do
              begin
                case Sort of
                  1 : S := 'N';
                  2 : S := 'T';
                  3 : S := 'S';
                end;
                D := '+';
                if not UpDown then
                  D := '-';
                if Path[2] <> ':' then
                  Path := 'C:' + Path;
                if not ValidDrive(Path[1]) then
                  begin
                    ECode := 3;
                    if IPXTrace then Trace(CItem, '!Invalid Drive');
                    ReturnData(neNACK, ECode, 1);
                    AckHandler := NullAckHandler;
                    Exit;
                  end;
              end;
            New(Direc, Init(DRSpec.Path, S, D));
            if Direc = nil then
              begin
                ECode := 1;
                if IPXTrace then Trace(CItem, '!Not enough Memory');
                ReturnData(neNACK, ECode, 1);
                AckHandler := NullAckHandler;
                Exit;
              end;
            AckFirst := False;
            if Direc^.Count = 0 then
              begin
                ECode := 2;
                Dispose(Direc, Close);
                Direc := nil;
                if IPXTrace then Trace(CItem, '!No matching items');
                ReturnData(neNACK, ECode, 1);
                AckHandler := NullAckHandler;
                Exit;
              end
            else
              begin
                ECode := Direc^.Count;
                if IPXTrace then
                  Trace(CItem, 'Found ' + Long2Str(ECode) + ' entries');
              end;
            ReturnData(neACK, ECode, 1);
            Exit;
          end;
        if Direc^.GetNextEntry(DEntry) then
          begin
            ReturnData(neMore, DEntry, SizeOf(DirRec));
            if IPXTrace then
              Trace(CItem, '[Dir Entry: ' + DEntry.Name + ']');
          end
        else
          begin
            ReturnData(neLastMessage, DEntry, SizeOf(DirRec));
            AckHandler := NullAckHandler;
            Dispose(Direc, Close);
            if IPXTrace then
              Trace(CItem, '[Directory Complete]');
          end;
      end;
  end;

  procedure SendFile(CItem : ConversationPtr);
  var ECode      : Byte;
    S, D           : Char;
    ID, Count      : Word;
    Savemode       : Byte;
  begin
    with CItem^ do
      begin
        if AckFirst then
          begin
            Savemode := FileMode;
            FileMode := 0;
            Assign(F, Path);
              {$I-}
            Reset(F, 1);
            FileMode := Savemode;
            ECode := IoResult;
            if ECode <> 0 then
              begin
                if IPXTrace then Trace(CItem, '!File open error ' + Long2Str(ECode));
                ReturnData(neNACK, ECode, 1);
                AckHandler := NullAckHandler;
                Exit;
              end;
            ReturnData(neACK, ECode, 1);
            AckFirst := False;
            Exit;
          end;
        BlockRead(F, Packet^.BFile.Data, 500, Count);
        Packet^.BFile.Count := Count;
        if (Packet^.BFile.Count < 500) or(EoF(F)) then
          ID := neLastMessage
        else
          ID := neMore;
        ReturnPacket(ID);
        if IPXTrace then
          Trace(CItem, '[File packet Sent: ' + Long2Str( {CItem^.} Packet^.BFile.Count) + ' bytes]');
        if ID = neLastMessage then
          begin
            Close(F);
            AckHandler := NullAckHandler;
            if IPXTrace then
              Trace(CItem, '[File Send Complete]');
          end;
          {$I+}
      end;
  end;

  procedure ReceiveFile(CItem : ConversationPtr);
  var ECode      : Byte;
    S, D           : Char;
    ID, Count      : Word;
    Savemode       : Byte;
  begin
    with CItem^ do
      begin
        if AckFirst then
          begin
            Assign(F, Path);
              {$I-}
            Rewrite(F, 1);
            ECode := IoResult;
            if ECode <> 0 then
              begin
                if IPXTrace then Trace(CItem, '!File open error ' + Long2Str(ECode));
                ReturnData(neNACK, ECode, 1);
                AckHandler := NullAckHandler;
                Exit;
              end;
            AckFirst := False;
            if IPXTrace then
              Trace(CItem, '[File Created]');
            ReturnData(neACK, ECode, 1);
            Exit;
          end;
        if IPXTrace then
          Trace(CItem, '[File packet Received: ' + Long2Str(Packet^.BFile.Count) + ' bytes]');
        BlockWrite(F, Packet^.BFile.Data, Packet^.BFile.Count, Count);
          {$I+}
        ID := Packet^.ID;
        ReturnData(neACK, ECode, 1);
        if ID = neLastMessage then
          begin
            Close(F);
            AckHandler := NullAckHandler;
            if IPXTrace then
              Trace(CItem, '[File Receive Complete]');
          end;
      end;
  end;

  procedure SendServices(CItem : ConversationPtr);
  var ECode      : Byte;
    S, D           : Char;
    ID             : Word;
    Savemode       : Byte;
  begin
    with CItem^ do
      begin
        if AckFirst then
          begin
            New(Services);
            GetServices(CItem, Services^, ItemCount);
            AckFirst := False;
            CurItem := 0;
            if IPXTrace then
              Trace(CItem, '[' + Long2Str(ItemCount) + ' Services available]');
            if ItemCount = 0 then
              begin
                ReturnData(neNACK, ItemCount, 2);
                AckHandler := NullAckHandler;
                Dispose(Services);
              end
            else
              ReturnData(neACK, ItemCount, 2);
            Exit;
          end;
        Inc(CurItem);
        Packet^.Service := Services^[CurItem];
        if CurItem >= ItemCount then
          ID := neLastMessage
        else
          ID := neMore;
        ReturnPacket(ID);
        if IPXTrace then
          Trace(CItem, '[Service packet Sent: ' + Packet^.SData + ']');
        if ID = neLastMessage then
          begin
            AckHandler := NullAckHandler;
            Dispose(Services);
            if IPXTrace then
              Trace(CItem, '[Services Complete]');
          end;
      end;
  end;

  procedure SendDeviceList(CItem : ConversationPtr);
  var ECode      : Byte;
    S, D           : Char;
  begin
    with CItem^ do
      begin
        if AckFirst then
          begin
            CurItem := 0;
            ReturnData(neACK, NumDDFItems, 2);
            AckFirst := False;
            Exit;
          end;
        Inc(CurItem);
        if CurItem < NumDDFItems then
          begin
            ReturnData(neMore, DDTable^[CurItem], SizeOf(DDFTable));
            if IPXTrace then
              Trace(CItem, '[DDF Entry: ' + DDTable^[CurItem].DeviceName + ']');
          end
        else
          begin
            ReturnData(neLastMessage, DDTable^[CurItem], SizeOf(DDFTable));
            AckHandler := NullAckHandler;
            if IPXTrace then
              Trace(CItem, '[DDF Entry: ' + DDTable^[CurItem].DeviceName + ']');
            if IPXTrace then
              Trace(CItem, '[Device List Complete]');
          end;
      end;
  end;

  procedure AssignDevice(CItem : ConversationPtr; Dev : DDFTable);
  var I          : Integer;
    b              : Byte;
    Device         : Integer;
  begin
    with CItem^ do
      begin
        if (DDTable = nil) or(NumDDFItems = 0) then
          begin
            b := 1;
            ReturnData(neNACK, b, 1);
            if IPXTrace then
              Trace(CItem, '!Error, Not Slave machine');
            Exit;
          end;
        Device := 0;
        for I := 1 to NumDDFItems do
          if Dev.DeviceName = DDTable^[I].DeviceName then
            Device := I;
        if Device = 0 then
          begin
            b := 2;
            ReturnData(neNACK, b, 1);
            if IPXTrace then
              Trace(CItem, '!Error, Device not on this Slave');
            Exit;
          end;
        if DDTable^[Device].InUse then
          begin
            if RemoteUser <> DDTable^[Device].InUseBy then
              begin
                b := 3;
                ReturnData(neNACK, b, 1);
                if IPXTrace then
                  Trace(CItem, '!Error, Device in Use elswhere');
                Exit;
              end;
          end;
        DDTable^[Device].InUse := True;
        DDTable^[Device].Alias := StUpCase(Dev.Alias);
        DDTable^[Device].InUseBy := RemoteUser;
        DDTable^[Device].InUseSince := OpDate.CurrentTime;
        DDTable^[Device].LastUse := OpDate.CurrentTime;
        ReturnData(neACK, b, 1);
      end;
  end;

  procedure ReleaseDevice(CItem : ConversationPtr; DevName : ObjectStr);
  var I          : Integer;
    b              : Byte;
    Device         : Integer;
  begin
    with CItem^ do
      begin
        Device := 0;
        for I := 1 to NumDDFItems do
          if DevName = DDTable^[I].DeviceName then
            Device := I;
        if Device = 0 then
          begin
            b := 2;
            ReturnData(neNACK, b, 1);
            if IPXTrace then
              Trace(CItem, '!Error, Device not on this Slave');
            Exit;
          end;
        if not DDTable^[Device].InUse then
          begin
            b := 3;
            ReturnData(neNACK, b, 1);
            if IPXTrace then
              Trace(CItem, '!Error, Device not Assigned');
            Exit;
          end;
        DDTable^[Device].InUse := False;
        DDTable^[Device].Alias := '';
        DDTable^[Device].InUseBy := RemoteUser;
        DDTable^[Device].InUseSince := 0;
        DDTable^[Device].LastUse := 0;
        ReturnData(neACK, b, 1);
      end;
  end;

  procedure SendRemoteMacro(CItem : ConversationPtr; var Macro : String);
  begin
    IPXSendMacro(CItem^.RemoteUser, Macro);
  end;

  procedure IPXCommandDone(CItem : ConversationPtr; Command : ServiceRec);
  var I          : Integer;
  begin
    CItem^.ReturnData(neACK, Command, SizeOf(ServiceRec));
  end;

  { Null Status build procedure }

  procedure BuildNullStatus(var Data : StatusData);
  var NoStatus   : String[9];
  begin
    NoStatus := 'NO STATUS';
    Move(NoStatus, Data, 10);
  end;

  procedure NullAdvertize(CItem          : ConversationPtr;
                          var Services   : ServiceList;
                          var NumServices : Integer);
  begin
    NumServices := 0;
    Services[1].Description := 'Testing 1 2 3';
    Services[1].ParamRequest := prOK;
    Services[1].Prompt := 'Test';
    Services[1].Number := 1;
    Services[2].Description := 'Testing 4 5 6';
    Services[2].ParamRequest := prOK;
    Services[2].Prompt := 'Test';
    Services[2].Number := 2;
  end;

  procedure NullCommandHandler(CItem          : ConversationPtr;
                               Command        : ServiceRec);
  begin
    IPXCommandDone(CItem, Command);
  end;

  procedure NullBackgroundProcessor;
  begin
  end;

procedure InitIPX;
var I          : Integer;
begin
  if NetwareLoaded(Logged) then
    begin
      OurConnNo := GetConnNo;
      GetInternetAddress(OurConnNo, OurNetAddress);
      OurUserName := GetUsersName;
      SYS_Channel := nil;
      if IPXActive then
        New(SYS_Channel, Init(NEN_TXSocket, NEN_RXSocket, 0, 0));
      for I := 1 to MaxConversations do
        Sub_Channel[I] := nil;
    end;
  BuildStatus := BuildNullStatus; { Default Status build routine }
  TraceDisplay := DefaultDisplay;
  AckHandler := NullAckHandler;
  GetServices := NullAdvertize;
  HandleCommand := NullCommandHandler;
  Background := NullBackgroundProcessor;
  IPXAvailable := IpxAvail;
end;

procedure CloseIPX;
begin
  if SYS_Channel <> nil then
    Dispose(SYS_Channel, Done);
end;

Begin
  If IPXActive Then
     InitIPX;
end.
