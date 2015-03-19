{ÛßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßÛ}
{Û                                                       Û}
{Û      Virtual Pascal v2.0                              Û}
{Û      Execute child process and redirect output        Û}
{Û      ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÛ}
{Û      Copyright (C) 1996-98 fPrint UK Ltd              Û}
{Û                                                       Û}
{ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß}
{ This unit is provided on an as-is basis and has been made}
{ available due to popular demand.}

{ It implements a class, which can be used to execute a}
{ program that writes output to StdOut or StdErr.  This}
{ output is catched and is returned to the calling program,}
{ which can use it in any way it sees fit.}

Unit Os2Exec;

{$Delphi+,X+,T-}

interface

uses
  USE32,
  Os2Base,
  VPUtils,
  SysUtils,
  Classes;


const
  MsgBufSize = 512;

type
  MsgCharResult = (mcrTimeOut, mcrReady, mcrEOF);

  tRedirExec = class( tObject )
  private
    { Variables used internally by the class}
    fReadHandle  : Longint;
    fWriteHandle : Longint;
    fMsgBufPtr   : LongInt;
    fBytesRead   : LongInt;
    fReadSem     : HEv;
    fMsgReady    : Boolean;
    fMsgBuffer   : array [0..MsgBufSize-1] of Char;
    fMessageChar : Char;

    { Fields published as properties}
    fMessageLine : String;
    fTerminated  : Boolean;
    fReturnCode  : Longint;
    fOnTerminate : TNotifyEvent;
    fOnCharReady : TNotifyEvent;
    fOnLineReady : TNotifyEvent;
  protected
    function ReadMessageChar: MsgCharResult;
    function GetMessageReady: Boolean;
    function GetMessage: String;
    property MessageChar: Char read fMessageChar write fMessageChar;
  published
    constructor create;
    destructor Destroy; override;
    function Execute(const S: ShortString; CmdLine: PChar; Env: PChar): Boolean;
    FUNCTION ExecutePM(ExeName : STRING; CmdLine : PCHAR; Env : PCHAR) : BOOLEAN;

    property Terminated: Boolean read fTerminated;
    property MessageReady: Boolean read GetMessageReady;
    property ReturnCode: Longint read fReturnCode;
    property Message: String read GetMessage;

    property OnTerminate: TNotifyEvent read fOnTerminate write fOnTerminate;
    property OnCharReady: TNotifyEvent read fOnCharReady write fOnCharReady;
    property OnLineReady: TNotifyEvent read fOnLineReady write fOnLineReady;
  end;

implementation
USES
    DOS,
    OpString,
    os2def;

const
  StdOut = 1;     { Standard output file handle}
  StdErr = 2;     { Standard error file handle}

constructor tRedirExec.create;
begin
  inherited create;

  DosCreateEventSem(nil, fReadSem, dc_Sem_Shared, False); { Create event semaphore}
  fTerminated := True;
  fMsgReady := False;
end;

function tRedirExec.Execute(const S: ShortString; CmdLine: PChar; Env: PChar): Boolean;
var
  NewOut    : Longint;                   { File handles}
  OldOut    : Longint;
  OldErr    : Longint;
  NewErr    : Longint;
  ExecErr   : Longint;
  PostCount : Longint;
  FPid      : smallword;
  Tms       : longint;
  Strg,
  PipeName  : String;                    { Name of pipe used to communicate}
  Action    : Longint;                   { Action taken by DosOpen}
  ExecRes   : ResultCodes;
  Os2Args   : PChar;
  Args      : array [0..1024*2] of Char;
  PrgName   : array [0..259] of Char;
  FailedObj : array [0..259] of Char;

begin
  Result := False;
  If not fTerminated then               { Process already running - exit}
    Exit;

  { Create Named Pipe with a unique name, so several instances of the}
  { program can run without interfering by embedding a timer count into}
  { the pipe name.}
  { The server (read) handle of the pipe is used by the program, while the}
  { client (write) handle is redirected to be the STDOUT handle for the}
  { program to execute.}

  //PipeName := Format( '\PIPE\VPX%.4x%.8x'#0, [ FPid, TMs ] );
  PipeName := '\PIPE\VPX'+HexW(GetForegroundProcessID)+HexL(GetTimeMSec);
  if DosCreateNPipe(@PipeName[1], fReadHandle, np_Access_InBound,
    np_NoWait + 1, 0, 4*1024, 0) <> 0 then
    exit;                               { Fail if pipe creation fails}

  DosConnectNPipe(fReadHandle);         { Connect to pipe}
  DosOpen(@PipeName[1], fWriteHandle, Action, 0, file_Normal, file_Open,
    open_access_WriteOnly+open_share_DenyNone, nil);

  DosResetEventSem(fReadSem, PostCount);{ Reset read event semaphore}
  DosSetNPipeSem(fReadHandle, HSem(fReadSem), 0);         { Associate with pipe}

  OldOut := $FFFFFFFF;                  { Save original StdOut to OldOut}
  DosDupHandle(StdOut,OldOut);
  NewOut := StdOut;                     { Redirect StdOut to Write pipe handle}
  DosDupHandle(fWriteHandle,NewOut);

  OldErr := $FFFFFFFF;                  { Save original StdErr to OldErr}
  DosDupHandle(StdErr,OldErr);
  NewErr := StdErr;                     { Redirect StdErr to Write pipe handle}
  DosDupHandle(fWriteHandle,NewErr);

  DosClose(fWriteHandle);               { Close write pipe end to sense EOF on read}

//  StrPCopy(PrgName,S);                  { Set up DosExecPgm parameters}
  move(S[1], PrgName, BYTE(S[0]));
  PrgName[LENGTH(S)+1] := #0;
  Os2Args := Args;
  { Work around OS/2 bug: Argument to ExecPgm must not cross 64K boundary}
  if ((Longint(Os2Args) + 1024) and $FFFF) < 1024 then
    Inc(Os2Args, 1024);
  StrCat(StrCat(StrCopy(Os2Args, PrgName), ' '), CmdLine);
  Os2Args[StrLen(Os2Args)+1] := #0;     { #0#0 at the end }
  Os2Args[Length(S)] := #0;             { #0 after program name }
  ExecErr := DosExecPgm(FailedObj, SizeOf(FailedObj), exec_AsyncResult, Os2Args, Env, ExecRes, PrgName);

  { Restore Handles before returning}
  DosDupHandle(OldOut,NewOut);          { Restore StdOut to original meaning}
  DosClose(OldOut);                     { Close duplicate of StdOut}
  DosDupHandle(OldErr,NewErr);          { Restore StdErr to original meaning}
  DosClose(OldErr);                     { Close duplicate of StdErr}

  if ExecErr <> 0 then                  { If execution failed, exit}
    exit;

  fMsgBufPtr  := 0;                     { Reset state variables}
  fBytesRead   := 0;
  fTerminated  := False;
  fMessageLine := '';
  Result       := True;
end;

    {-----------------}

    {execute any sort of DOS, OS2PM or OS2VIO program.  Probably works with windoze programs too}
    FUNCTION tRedirExec.ExecutePM(ExeName:STRING; CmdLine:PCHAR; Env:PCHAR):BOOLEAN;
    VAR
        Sdata :     StartData;
        procID:     Pid;
        sessID:     ULONG;
        Rc:         APIret;
        PCmdLin:    ARRAY[0..255] OF CHAR;
        achObjBuf:  ARRAY[0..255] OF CHAR;

    BEGIN
        procID := 0;
        sessID := 0;
        FILLCHAR(Sdata, SIZEOF(StartData), 0);
        FILLCHAR(PCmdLin, SIZEOF(PCmdLin), #0);
        StrCat(PCmdLin, ' /C ');
        ExeName := Fexpand(ExeName) + ' '; {put delimiters around program name}
        StrMove(StrEnd(PCmdLin), @ExeName[1], LENGTH(ExeName)); {copy /c Exename.exe to Cmdlin}
        StrCat(PCmdLin, CmdLine); {now append the command line params}
        Sdata.PgmInputs := PCmdLin;

        with SData do begin
            Length   := sizeof(StartData);
            Related  := SSF_RELATED_INDEPENDENT; //zzzz ssf_Related_Child;       // start a dependent session
            FgBg     := ssf_Fgbg_Back;           // start session in background
            TraceOpt := ssf_TraceOpt_None;       // No trace
            // Start an OS/2 session using 'CMD.EXE /K'
            PgmTitle := 'Spawned Session';
            PgmName := 'CMD.EXE';
            TermQ := nil;                        // No termination queue
            Environment := nil;                  // No environment string
            InheritOpt := ssf_InhertOpt_Shell;   // Inherit shell's environ.
            SessionType := ssf_Type_WindowableVio; // Windowed VIO session
            IconFile := nil;                     // No icon association
            PgmHandle := 0;
            PgmControl := ssf_Control_Visible Or ssf_Control_Maximize;
            InitXPos  := 30;     // Initial window coordinates
            InitYPos  := 40;
            InitXSize := 200;    // Initial window size
            InitYSize := 140;
            Reserved := 0;
            ObjectBuffer  := achObjBuf; // Contains info if DosExecPgm fails
            ObjectBuffLen := sizeof(achObjBuf);
        end;

        //sd.SessionType := PROG_SEAMLESSCOMMON; { original}
        //sd.SessionType := ssf_Type_WindowableVio; { ZZZZ changed by KGM 3 - 29 - 98}

        //sd.Related := SSF_RELATED_INDEPENDENT;
        //sd.FgBg := SSF_FGBG_FORE;
        //sd.TraceOpt := SSF_TRACEOPT_NONE;
        //sd.TermQ := NIL;
        //sd.Environment := NIL;

        //sd.InheritOpt := ssf_InhertOpt_Shell; { Inherit shell 's environ. ZZZZ added}

        //sd.PgmControl := SSF_CONTROL_VISIBLE OR {SSF_CONTROL_SETPOS} ssf_Control_Minimize;
        //sd.PgmControl := SSF_CONTROL_VISIBLE OR SSF_CONTROL_SETPOS;
        //sd.InitXPos := 50;
        //sd.InitYPos := 50;
        //sd.InitXSize := 400;
        //sd.InitYSize := 600;
        //sd.Reserved := 0;
        //sd.ObjectBuffer := achObjBuf;
        //sd.ObjectBuffLen := sizeof(achObjBuf);

        fReturnCode := DosStartSession(Sdata,
                              sessID,
                              procID);

        rc := DosSelectSession(sessID);

        ExecutePM := fReturnCode = 0;
    END;

{ Returns next message character if available }

function tRedirExec.ReadMessageChar: MsgCharResult;
var
  PostCount : Longint;
  PipeState : Longint;
  RCWait    : Longint;
  Avail     : AvailData;
begin
  if fMsgBufPtr = fBytesRead then
    begin
      fMsgBufPtr := 0;
      fBytesRead := 0;
      RCWait := DosWaitEventSem(fReadSem, 1);   { Wait 1 msec for posting sem}
      DosPeekNPipe(fReadHandle, fMsgBuffer, 1, fBytesRead, Avail, PipeState);
      if fBytesRead = 0 then                   { No data available...}
        begin
          if PipeState = np_State_Closing then { If exiting, return EOF}
            begin
              ReadMessageChar := mcrEOF;
              Exit;
            end;
          if RCWait <> 0 then                  { If error, return timeout}
            begin
              ReadMessageChar := mcrTimeOut;
              Exit;
            end;
        end;
      DosResetEventSem(fReadSem, PostCount);    { Reset semaphore}
      DosRead( fReadHandle, fMsgBuffer,        { Read data from pipe}
               SizeOf(fMsgBuffer), fBytesRead);
      if fBytesRead = 0 then                   { If no data was read...}
        begin
          ReadMessageChar := mcrTimeOut;       { Return timout}
          Exit;
        end;
    end;
  ReadMessageChar := mcrReady;                 { Character ready}
  fMessageChar := fMsgBuffer[fMsgBufPtr];      { Fill buffer}
  Inc(fMsgBufPtr);
end;

{ Checks state of pipe, and returns True if a full line is available }

Function tRedirExec.GetMessageReady : Boolean;
var
  Len     : Longint;
  MsgInx  : Longint;
  RetPID  : Longint;
  ExecRes : ResultCodes;

begin
  If fMsgReady then
    begin
      Result := True;
      exit;
    end;

  Result := False;
  Len := Length(fMessageLine);

  for MsgInx := 0 to MsgBufSize-1 do
    case ReadMessageChar of
      mcrEOF:                                  { EOF reached}
        begin
          DosClose(fReadHandle);               { Close handle}
          DosWaitChild(dcwa_Process, dcww_Wait, ExecRes, RetPID, 0);
          fReturnCode := ExecRes.codeResult;   { Save return code}
          fTerminated := True;
          If Assigned( fOnTerminate ) then     { Execute OnTerminate method}
            OnTerminate( Self );
          Exit;
        end;

      mcrReady:                                { Character is received}
        begin
          if Assigned( fOnCharReady ) then     { Execute OnCharReady method}
            OnCharReady( Self );

          if (fMessageChar = #10) and (fMessageLine <> '') then
            begin
              Result := True;                  { End-of-line}
              fMsgReady := True;
              if Assigned( fOnLineReady ) then { Execute OnLineReady method}
                OnLineReady( Self );
              Exit;
            end;

          if MessageChar >= ' ' then           { Filter printable chars}
            begin
              Inc(Len);                        { Append char to string}
              fMessageLine[Len] := MessageChar;
              SetLength( fMessageLine, Len );
            end;
        end;

      mcrTimeOut: Exit;                        { Timeout: Exit}
    end;

end;

{ Returns a message, if one is ready.  Otherwise, the empty string is returned }

Function tRedirExec.GetMessage : string;
begin
  if MessageReady then                 { If a message is ready}
    begin
      Result := fMessageLine;          { Return message}
      fMessageLine := '';
      fMsgReady := False;
    end
  else
    Result := '';                      { else return blank line}
end;

destructor tRedirExec.Destroy;
begin
  DosDisConnectNPipe(fReadHandle);     { Disconnect from pipe}
  DosCloseEventSem(fReadSem);          { Close event semaphore}

  inherited destroy;
end;

end.
