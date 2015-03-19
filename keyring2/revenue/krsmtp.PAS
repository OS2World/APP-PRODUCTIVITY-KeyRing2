program KRSMTP;

{$i+} // raise exceptions

{&use32+}

uses
  uTwmSockdef,
  uTwmSmtpClient,
  dos,
  sysutils,
  VpSysLow,
  vputils,
{$ifdef os2}
  OS2Def,
  OS2Base,
{$else}
  Windows,
{$endif}
  crt,
  uTwmDos,
  uTwmStringS;

{$L IBMTCPIP.LIB} // zzzz removed .
{$ifndef os2}
type
  ApiRet=LongInt;

procedure DosSleep(_Timeout: longint);
begin
  Sleep(_Timeout);
end;
{$endif}

const
  cHostname: ShortString='';
  cSourceDir: ShortString='';
  cDestDir: ShortString='';
  cReadLogFile: ShortString='';
  cWriteLogFile: ShortString='';
  cKillSent: boolean=false;

type
  eFileMessageErr=class(exception);
  eFileNotFound=class(eFileMessageErr);
  eReadError=class(eFileMessageErr);

type
  tFileMessage=class(tSmtpMessage)
    fFile: text;
    constructor Create(_Filename: string);
    procedure Reset; override;
    function EOM: boolean; override;
    function GetNextLine: ShortString; override;
    destructor Destroy; override;
  end;

constructor tFileMessage.Create(_Filename: string);
  begin
  inherited Create;
  Assign(fFile, _Filename);
  System.Reset(fFile);
end;

destructor tFileMessage.Destroy;
  begin
  if tTextRec(fFile).Mode<>fmClosed then
    Close(fFile);
  inherited Destroy;
end;

procedure tFileMessage.Reset;
begin
  Close(fFile);
  System.Reset(fFile);
end;

function tFileMessage.EOM: boolean;
  begin
  Result:=EOF(fFile);
end;

function tFileMessage.GetNextLine: ShortString;
begin
  if EOF(fFile) then
    raise eReadError.Create('Tried to read beyond end of file.');
  ReadLn(fFile, Result);
end;

// main program

function CheckForMsgsToSend: boolean;
  var
    rc: integer;
    sr: tSearchRec;
  begin
  rc:=SysUtils.FindFirst(AddBackslash(cSourceDir)+'*.MSG', AnyFile, sr);
  SysUtils.FindClose(sr);
  Result:=(rc=0);
end;

procedure SendMessages;
  var
    rc: integer;
    sr: tSearchRec;
    Src, Dst: AnsiString;
    SmtpClient: tSmtpClient;
    Msg: tFileMessage;
  begin
  SmtpClient:=tSmtpClient.CreateEx(cHostname);
  try
    SmtpClient.Open;
    try
      rc:=SysUtils.FindFirst(AddBackslash(cSourceDir)+'*.MSG', AnyFile, sr);
      try
        while rc=0 do begin
          try
            Msg:=tFileMessage.Create(AddBackslash(cSourceDir)+sr.Name);
            try
              SmtpClient.SendMessage(Msg);
            finally
              Msg.Free;
            end;
            if not cKillSent then
              begin
                Src:=AddBackslash(cSourceDir)+sr.Name;
                Dst:=AddBackslash(cDestDir)+sr.Name;
                if not SysFileCopy(pChar(Src), pChar(Dst), false) then // zzzz was syscopyfile
                  raise exception.CreateFmt('error copying %s to %s', [sr.Name, cDestDir]);
                WriteLn('File copied.');
              end;
            if SysUtils.DeleteFile(AddBackslash(cSourceDir)+sr.Name) then
              WriteLn('File deleted')
            else
              raise exception.Create('error deleting file '+sr.Name);
          except
            on e: Exception do
              WriteLn(e.Message);
          end;
          rc:=SysUtils.FindNext(sr);
        end;
      finally
        SysUtils.FindClose(sr);
      end;
    finally
      SmtpClient.Close
    end;
  finally
    SmtpClient.Free;
  end;
end;

procedure PutTheMail;
  begin
  if not CheckForMsgsToSend then
    WriteLn('No messages to send, terminating.')
  else
    SendMessages;
end;

procedure Usage;
  begin
  WriteLn('usage:');
  WriteLn;
  WriteLn('PutSmtp [options] <smtp server> <sourcedir> [<destdir>]');
  WriteLn('where');
  WriteLn('<smtp server> = name of the smtp server');
  WriteLn('<sourcedir>   = directory from which to send *.MSG files');
  WriteLn('<destdir>     = directory to which to save sent MSG files (see -D option)');
  WriteLn('options:');
  WriteLn('  -R<readlogfile>  = write all incoming data to <readlogfile>');
  WriteLn('  -W<writelogfile> = write all outgoing data to <writelogfile>');
  WriteLn('  -D          = delete all sent MSG files');
  WriteLn('Either the -D option or the <destdir> paramter must be specified.');
  Halt;
end;

procedure GetParams;
  var
    i: integer;
  begin
  i:=1;
  while (i<ParamCount) and (LeftStr(ParamStr(i), 1)='-') do begin
    case UpCase(NthCharOf(ParamStr(i), 2)) of
      'R': cReadLogFile:=Trim(TailStr(ParamStr(i),3));
      'W': cWriteLogFile:=Trim(TailStr(ParamStr(i),3));
      'D': cKillSent:=true;
    end;
    Inc(i);
  end;
  if (ParamCount<i+1) or (ParamCount>i+2)
     or ((ParamCount=i+2) and cKillSent)
     or ((ParamCount=i+1) and not cKillSent) then
    Usage;
  cHostname:=ParamStr(i);
  cSourceDir:=ParamStr(i+1);
  if not cKillSent then
    cDestDir:=AddBackslash(ParamStr(i+2));
end;

procedure Main;
  begin
  popuperrors:=false;
  try
    WriteLn;
    WriteLn('PutSmtp v1.01.000 (c) 1998 by Thomas W. Mueller');
    WriteLn;
    WriteLn('Send emails to a smtp server.');
    WriteLn('Written with Virtual Pascal v2.0');
    WriteLn;
    GetParams;
    PutTheMail;
  except
    on e: Exception do begin
      WriteLn;
      WriteLn('an exception ', e.ClassName, ' has occured. Message:');
      WriteLn(e.Message);
    end;
  end;
  WriteLn;
end;

begin
  Main;
end.
