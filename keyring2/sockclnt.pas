unit sockclnt;

{&use32+}
{$i+}
{$h+}

interface

uses
{$ifdef os2}
  OS2Def,
  Os2Base,
{$else}
  Windows,
  Os2Comp,
{$endif}
  SysUtils,
  uTwmSockDef,
  uTwmSocket;

const
  cRetries=5;

type
  eSockClient=class(eSocketErr);

type
  tOnLogLineProc=procedure(_Line: Ansistring) of object;

type
  tSockClient=class
  protected
    fService: AnsiString;
    fHostname: AnsiString;
    fSocket: tSocket;
    fOnLogLine: tOnLogLineProc;
    procedure ConnectSocket; virtual;
    procedure DisconnectSocket; virtual;
    procedure ReadStartupMessage; virtual;
    procedure SignOn; virtual; abstract;
    procedure SignOff; virtual; abstract;
    function GetConnected: boolean; virtual;
    procedure SetConnected(_Connected: boolean); virtual;
    procedure LogLine(_Line: Ansistring); virtual;
    function TransactLn(const _In: Ansistring; var _Out: Ansistring): boolean; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open; virtual;
    procedure Close; virtual;
    property Hostname: Ansistring read fHostname write fHostname;
    property Service: Ansistring read fService write fService;
    property Connected: boolean read GetConnected write SetConnected;
    property OnLogLine: tOnLogLineProc read fOnLogLine write fOnLogLine;
  end;

implementation

constructor tSockClient.Create;
begin
  inherited Create;
  fSocket:=tSocket.Create(AF_INET, SOCK_STREAM, IPPROTO_TCP);
end;

destructor tSockClient.Destroy;
  begin
  fSocket.Free;
  inherited Destroy;
end;

procedure tSockClient.ConnectSocket;
  var
    SAddr: tSockAddr;
    rc: ApiRet;
    Retries: integer;
  begin
  if fHostname='' then
    raise eSockClient.Create('no hostname specified');
  fillchar(SAddr, SizeOf(SAddr), #0);
  rc:=fSocket.GetHostByName(fHostname);
  if rc=$FFFFFFFF then
    raise eSocketErr.Create('Host '+fHostname+' not found.')
  else begin
    SAddr.Sin_Addr.IPAddr:=rc;
    SAddr.Sin_Port:=fSocket.GetServPortByName(fService, 'tcp');
    SAddr.Sin_Family:=AF_INET;
    LogLine(Format('trying to connect to host %s:%s (%s:%d)',
                   [fHostname, fService,
                   fSocket.InetAddrStr(SAddr.Sin_Addr),
                   fSocket.htons(SAddr.Sin_Port)]));
    Retries:=cRetries;
    repeat
      try
        fSocket.Connect(SAddr);
      except
        on e: eSocketErr do
          begin
            Dec(Retries);
            if Retries=0 then
              Raise;
          end;
      end;
    until fSocket.isConnected;
    LogLine(Format('connected to host %s:%s (%s:%d)',
                   [fHostname, fService,
                   fSocket.InetAddrStr(SAddr.Sin_Addr),
                   fSocket.htons(SAddr.Sin_Port)]));
{$ifdef os2}
    try
      LogLine('Trying to set Socket to nonblocking mode...');
      fSocket.Blocking:=false;
    except
      on e: eSocketErr do
        LogLine(e.Message);
    end;
{$endif}
  end;
end;

procedure tSockClient.ReadStartupMessage;
var
  s: AnsiString;
begin
  while not fSocket.DataAvailable do
    DosSleep(10);
  while fSocket.DataAvailable do begin
    fSocket.RecvStrLn(s);
    LogLine('< '+s);
  end;
end;

procedure tSockClient.DisconnectSocket;
  begin
  fSocket.Close;
end;

function tSockClient.GetConnected: boolean;
  begin
  Result:=fSocket.isConnected;
end;

procedure tSockClient.SetConnected(_Connected: boolean);
  begin
  if _Connected<>Connected then begin
    if not Connected then begin
      ConnectSocket;
      ReadStartupMessage;
      try
        SignOn;
      except
        DisconnectSocket;
      end;
    end else begin
      SignOff;
      DisconnectSocket;
    end;
  end;
end;

procedure tSockClient.Open;
  begin
  Connected:=true;
end;

procedure tSockClient.Close;
  begin
  Connected:=false;
end;

function tSockClient.TransactLn(const _In: Ansistring; var _Out: Ansistring): boolean;
begin
  LogLine('> '+_In);
  Result:=fSocket.TransactStrLn(_In, _Out);
  LogLine('< '+_Out);
end;

procedure tSockClient.LogLine(_Line: Ansistring);
  begin
  if Assigned(fOnLogLine) then
    fOnLogLine(_Line);
end;

end.
