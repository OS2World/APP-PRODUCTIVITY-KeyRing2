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
{$A-,V-,F+,O+}
{*******************************************************************}
{ (C)1992 NewsMaker Systems                                         }
{ UHDR - Utility routine for performing repeated actions on each    }
{ header in a NEN QHDR file, or for Queue in a chain                }
{*******************************************************************}

Unit UHdr;

interface

Uses
  Dos, OpCrt, QGlobal, QHdrRec, QHdrIo, QInput, UWindow, UColors,
  OpDate, OpString, OpCol16, B_ATime;

{ To use ForEachHeader, you must write your own procedure with the }
{ following parameter list. The routine must be FAR and Global     }
{ You then pass the name of your routine as the first parameter to }
{ ForEachHeader, together with the name of the Queue and a boolean }
{ to indicate read/write .vs. Read only.                           }
{ ForEachHeader will call this procedure once per header, passing  }
{ the header directory and current Hdr as parameters. Once you have}
{ finished with the header, set the Update parameter if you wish   }
{ the header to be written back, and Quit if you want to end the   }
{ process, close the QHdr and exit.                                }

Type
  { HeaderProc. A routine matching this template is called once for each }
  { Header in a queue by ForEachHeader                                   }

  HeaderProc = Procedure(HdrDirectory: RundownRec;   { Directory, Record 0 }
                         var Hdr     : RundownRec;   { Current Hdr }
                         HdrNum      : Integer;      { Header Number }
                         var Update  : boolean;      { If true, write back }
                         var Quit    : boolean);     { if True, quit now }

  { QueueProc. A routine matching this template is called once for each }
  { Queue in a chain of queues by ForEachQueue                          }

  QueueProc = Procedure(QueueName : NameStr;          { DOS Name of Queue }
                        var HdrDirectory: RundownRec; { Directory, Record 0}
                        var Update      : boolean;    { If true, write back }
                        var Quit        : boolean);   { If true, quit now }

{ ForEachHeader. Calls DoHeaderProc for each header in queue }

procedure ForEachHeader(DoHeaderProc: HeaderProc;  { Procedure to call }
                        Queue       : NameStr;     { queue to process  }
                        ReadWrite   : boolean;     { open for write   }
                        var Result  : integer);    { returned status  }

{ ForEachQueue. Calls DoQueueProc for each queue in chain }

procedure ForEachQueue(DoQueueProc  : QueueProc;   { Procedure to call }
                       StartQueue   : NameStr;     { start of queue chain }
                       ReadWrite    : boolean;     { open for write }
                       var Result   : integer);    { returned status }

procedure ClearAllAiredFlags(Queue: NameStr);
procedure SelectQBasedOnTime(StartQueue: NameStr; var Queue: NameStr);

const
  CheckForPutHdrInProgress : boolean = True;
  CorrectPutHdrInProgress  : boolean = True;
  AbortOnKeystroke         : boolean = False;
  QueueDrive               : char = 'F';
  ChainedQueues            : boolean = True;

implementation

var
  Q: NameStr;
  A_Now,
  A_StartOfShow,
  A_EndOfShow       : LongInt;
  DOW: integer;

procedure ForEachHeader(DoHeaderProc: HeaderProc;
                        Queue: NameStr;
                        ReadWrite: boolean;
                        var Result: integer);
var
  WorkHdr      : ^RundownRec;
  HdrDirectory : ^RundownRec;
  WorkHdrAdr,I : integer;
  Update, Quit : boolean;
begin
  {$I-}
  Result := 0;
  ChDir(NEN^.RootDir+'\'+Queue);
  if Ioresult <> 0 then
    begin
      Result := 1;
      exit;
    end;
  {$I+}
  if ReadWrite then
    begin
      If not HdrOpenWrite(i) Then
        begin
          ChDir (NEN^.SysDir);
          Result := 2;
          Exit;
        end;
      end
    else
      begin
        If not HdrOpenRead Then
          begin
            ChDir (NEN^.SysDir);
            Result := 3;
            Exit;
          end;
      end;
  New(HdrDirectory);
  If Not ReadHdr (HdrDirectory^, 0) Then
    Begin
      Dispose(HdrDirectory);
      CloseHdr;
      ChDir (NEN^.SysDir);
      Result := 4;
      exit;
    End;
  New(WorkHdr);
  WorkHdrAdr := HdrDirectory^.FirstLink;
  While WorkHdrAdr <> 0 do
    begin
      If Not ReadHdr(WorkHdr^, WorkHdrAdr) Then
        Begin
          CloseHdr;
          ChDir (NEN^.SysDir);
          Dispose(WorkHdr);
          Dispose(HdrDirectory);
          Result := 5;
          exit;
        End;

      DoHeaderProc(HdrDirectory^, WorkHdr^, WorkHdrAdr, Update, Quit);

      if (AbortOnKeystroke) and (Check4Chars) then
        Quit := True;

      if (ReadWrite) and (Update) then
        If not WriteHdr (WorkHdr^, WorkHdrAdr) then
          Begin
            CloseHdr;
            Dispose(WorkHdr);
            Dispose(HdrDirectory);
            ChDir (NEN^.SysDir);
            Result := 6;
            exit;
          End;
      WorkHdrAdr := WorkHdr^.NextLink;
      if Quit then
        WorkHdrAdr := 0;
    end;
  CloseHdr;
  Dispose(WorkHdr);
  Dispose(HdrDirectory);
  ChDir (NEN^.SysDir);
end;

procedure ForEachQueue(DoQueueProc  : QueueProc;   { Procedure to call }
                       StartQueue   : NameStr;     { start of queue chain }
                       ReadWrite    : boolean;     { open for write }
                       var Result   : integer);    { returned status }
var
  HdrDirectory : ^RundownRec;
  NextQueue    : NameStr;
  Update, Quit : boolean;
  I            : integer;

  { Returned Codes: 0 = OK                                      }
  {                 1 = Cannot switch to Directory              }
  {                 2 = Cannot open header for write            }
  {                 3 = Cannot open header for read             }
  {                 4 = Cannot read Header Directory (record 0) }
  {                 5 = PutHdrInProgress flag is set            }
  {                 6 = Cannot write header                     }
  {                 7 = PutHdrInProgress flag was corrected     }
  {               999 = Aborted on Keystroke                    }

begin
  NextQueue := StartQueue;
  New(HdrDirectory);
  Result := 0;
  Repeat
    {$I-}
    ChDir(QueueDrive+':');
    ChDir (NEN^.RootDir+'\'+NextQueue);
    if Ioresult <> 0 then
      begin
        Dispose(HdrDirectory);
        Result := 1;
        exit;
      end;
    {$I+}
    if ReadWrite then
      begin
        If not HdrOpenWrite(i) Then
          begin
            Dispose(HdrDirectory);
            ChDir (NEN^.SysDir);
            Result := 2;
            Exit;
          end;
      end
    else
      begin
        If not HdrOpenRead Then
          begin
            Dispose(HdrDirectory);
            ChDir (NEN^.SysDir);
            Result := 3;
            Exit;
          end;
      end;
    If Not ReadHdr (HdrDirectory^, 0) Then
      Begin
        Dispose(HdrDirectory);
        CloseHdr;
        ChDir(NEN^.SysDir);
        Result := 4;
        exit;
      End;

    if (CheckForPutHdrInProgress) and
       (HdrDirectory^.QFlags and Q_PutHdrInProgress = Q_PutHdrInProgress) then
      begin
        CloseHdr;
        Result := 5;
        if CorrectPutHdrInProgress then
          if HdrOpenWrite(i) then
            begin
              if ReadHdr(HdrDirectory^, 0) then
                begin
                  HdrDirectory^.QFlags := HdrDirectory^.QFlags and (not Q_PutHdrInProgress);
                  WriteHdr(HdrDirectory^, 0);
                  Result := 7;
                end;
              CloseHdr;
            end;
        Dispose(HdrDirectory);
        ChDir(NEN^.SysDir);
        exit;
      end;

    if not ReadWrite then
      CloseHdr;

    DoQueueProc(NextQueue, HdrDirectory^, Update, Quit);

    if (AbortOnKeystroke) and (Check4Chars) then
      begin
        Quit := True;
        Result := 999;
      end;

    if (ReadWrite) and (Update) then
      begin
        If not WriteHdr(HdrDirectory^, 0) then
          Begin
            CloseHdr;
            Dispose(HdrDirectory);
            ChDir(NEN^.SysDir);
            Result := 6;
            exit;
          End;
      end;

    NextQueue := HdrDirectory^.NextQueue;
    if not ChainedQueues then
      NextQueue := '';

    if ReadWrite then
      CloseHdr;
  Until (Quit) or (NextQueue = StartQueue) or (NextQueue = '');
  Dispose(HdrDirectory);
  ChDir(QueueDrive+':');
  ChDir (NEN^.SysDir);
end;

{------------------------------------------------------------------}
{ Example procedures. Clears the AIRED flag from the BStatus field }
{------------------------------------------------------------------}

{ Called once per header }

Procedure ClearAiredFlag(HdrDirectory: RundownRec;
                         var Hdr: RundownRec;
                         HdrNum : integer;
                         var Update, Quit: boolean);
begin
  Update := False;
  Quit := False;
  if (Hdr.BStatus and S_Aired) = S_Aired then
    begin
      Hdr.BStatus := Hdr.BStatus and (not S_Aired);
      Update := True;
    end;
end;

{ Called once per Queue }

procedure ClearAllAiredFlags(Queue: NameStr);
var
  Result: integer;
begin
  ForEachHeader(ClearAiredFlag, Queue, True, Result);
end;

{------------------------------------------------------------------}

procedure CheckQueueTime(Queue: NameStr; var HdrDirectory: RundownRec;
                         var Update, Quit: boolean);
const
  Days : Array[0..6] of byte = (64,32,16,8,4,2,1);
begin
  WriteCentred(3,Pad(Queue,8));
  A_Now := AbsoluteTime(GetToDay, OpDate.CurrentTime);
  Update := False;
  Quit := False;
  Q := '';
  With HdrDirectory do
    begin
      A_StartOfShow     := AbsoluteTime(GetQDay(DaysOfTheWeek), TimeOfShow);
      DOW := GetQDay(DaysOfTheWeek);
      if EndTimeOfShow < TimeOfShow then
        inc(DOW);
      if DOW > 7 then DOW := 1;
      A_EndOfShow := AbsoluteTime(DOW, EndTimeOfShow);
      if (A_Now >= A_StartOfShow) and (A_Now <= A_EndOfShow) then
{      if DaysOfTheWeek and Days[Ord(DayOfWeek(Today))] <> 0 then
        if (OpDate.CurrentTime >= TimeOfShow) and (OpDate.CurrentTime <= EndTimeOfShow) then}
          begin
            Q := Queue;
            Quit := True;
          end;
    end;
end;

procedure SelectQBasedOnTime(StartQueue: NameStr; var Queue: NameStr);
var
  Result: integer;
begin
  OpenMessage('Locating Current Queue',BrightYellow_Scheme);
  CheckForPutHdrInProgress := False;

  ForEachQueue(CheckQueueTime, StartQueue, False, Result);

  CheckForPutHdrInProgress := True;
  CloseMessage;
  Queue := Q;
end;

End.

