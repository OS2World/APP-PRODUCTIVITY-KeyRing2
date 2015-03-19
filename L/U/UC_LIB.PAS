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

{************************************************************}
{ (C) 1991 NewsMaker Systems                                 }
{ Procedure library for NENCON, the NewsMaker system console }
{************************************************************}

Unit UC_Lib;

interface

Uses NConOvr, Dos, OpCrt, NetWare, NetBind, QGlobal, QInput, QHdrRec,
     OpDos,OpCol16,OpRoot,OpFrame,OpCmd,OpMenu,OpEntry,OpDialog,
     OpWindow,OpDate,OpInt,OpMouse,OpDrag,OpString,OpPick,
     NWIpxSpx,
     USpxDat, USpxGlo, UIpxSpx, USpxChk, USpxMsg, USpxSupp, UGlobal, UColors,
     UMenu, UWindow, UDialog, UDirec, UEdit, UCpuID, R_Glo;

Type LWR = Record
       W1: Word;
       W2: word;
     end;

     NMEnuType = Array[1..100] of BigString;

  DosDirPtr = ^DosDir;

  DirDisplayPtr = ^DirDisplay;
  DirDisplay = Object
    DirList : PickListPtr;
    PCP     : DragProcessorPtr;
    Quit    : boolean;
    P       : PathStr;
    I       : integer;
    Dir     : DirListPtr;
    Count   : integer;
    DR      : DirSpec;

    constructor Init(Direc : DirListPtr; FCount: integer; DRS: DirSpec);
    procedure GetDirLine(Item: integer; var Line: String);
    Procedure Process;
    destructor Done;
    end;

var
  Win     : RawWindow;
  WinOpts : LongInt;

  Logged: boolean;
  Version: word;              { SPX Version          }
  MaxConn: word;              { Maximum SPX Connections }
  AvailConn: word;            { SPX Conns available  }
  Dl,I,J: integer;
  Size: word;
  M: integer;
  CItem : PLoggedInConnection;
  CLine : String[40];
  ConnNo: word;
  NStatus : NENStatusRec;
  NConfig : CpuInfoRec;
  NetW: LongInt;
  LW : LWR;
  W3: word;
  SPXT: Text;
  Covers: pointer;
  NMenu : ^NMenuType;
  DR : DirSpec;
  DirStack : Array[1..5] of DirDisplayPtr;
  LocalDir : Array[1..5] of DosDirPtr;
  D,S: char;
  StatusReturned : boolean;
  PString: String[20];

Const
  LocalMode : boolean = False;

Const
  ConnHead = '    Con User     Program  Description          Version    ';
  UserHead = '         User                       Connections';
  Local : boolean = false;
  Connected: boolean = false;
  SendMode : boolean = False;

  procedure Die(M: String);
  Procedure NTrace(CR: boolean; Msg: TraceString);
  Procedure OpenTraceWindow(TProc : TraceDisplayProc);
  Procedure CloseTraceWindow;
  Procedure DisplayNENStatus;
  procedure showbcd(x: word);
  procedure DisplayConfig;
  procedure SendScanCodes;
  Procedure RetrieveFile(Path: PathStr);
  Procedure EditRemoteFile(Path: PathStr);
  Procedure DoDirectoryDisplay;
  Procedure DoDirectoryGet;
  Procedure DoLocalDirectory(DR: DirSpec);
  Procedure DoServiceMenu(CItem: PLoggedInConnection);
  Procedure ViewRemoteFile(Path: PathStr);
  Procedure DoConnectionMenu(User: ObjectStr);
  Procedure DoDeviceList;
  Procedure RunNENCON;

implementation

  procedure Die(M: String);
    begin
      if M[1] = '!' then
        TextColor(LightRed);
      WriteLn(M);
      TextColor(LightGray);
      WriteLn('Done');
      Halt;
    end;

  Procedure NTrace(CR: boolean; Msg: TraceString);
    begin
      if CR then
        WriteLn(SPXT,Msg)
      else
        Write(SPXT, Msg);
      FastWrite(Pad(Msg,80), 24,1, LtGreenOnBlue);
    end;

  Procedure OpenTraceWindow(TProc : TraceDisplayProc);
    begin
      Assign(SPXT,'IPX.TXT');
      Rewrite(SPXT);
      TraceDisplay := TProc;
      SetIPXTrace(True);
    end;

  Procedure CloseTraceWindow;
    begin
      Close(SPXT);
      SetIPXTrace(False);
      EditFile('IPX.TXT');
    end;

  Procedure DisplayNENStatus;
    begin
      if not GetStatus(CItem, NStatus) then exit;
      OpenWindow(5,16,76,23,CItem^.ProgramInfo.ProgDesc,Gray_Scheme);
      TextBackground(LightGray);
      ClrScr;

      with CItem^, NetAddress, NStatus do
        begin
        TextAttr := BlackOnLtGray;
        Move(Network,LW,4);
        W3 := LW.W1;
        LW.W1 := swap(LW.W2);
        LW.W2 := swap(W3);
        Move(LW,NetW,4);
        WriteLn;
        WriteLn('   Conn: ',ConnNo,
                ' Net:  ',HexL(NetW),
                ' Node: ',Node[1]+Node[2]+Node[3]+
                          Node[4]+Node[5]+Node[6],
                ' Socket: ',HexW(Swap(Socket)));
        TextAttr := WhiteOnLtGray;
        WriteLn('   ',Version,' ',StationID,', ',Location,', Lic: ',License);
        TextAttr := BlackOnLtGray;
        WriteLn('              Queue          Form          File      Mode       Status');
        TextAttr := WhiteOnLtGray;
        Write  ('   [Window 1] ');
        TextAttr := LtCyanOnLtGray;
        Write  (Pad(W1Queue,8),'       ',Pad(W1Form,8));
        if W1File <> '' then
          begin
            if W1FileLock then
              Write('      ',Pad(W1File,8),'  Locked   ')
            else
              Write('      ',Pad(W1File,8),'  Read Only');
            if W1FileMod then
              begin
                TextAttr := LtRedOnLtGray;
                Write(' *Changed');
              end;
          end;
        WriteLn;
        TextAttr := WhiteOnLtGray;
        Write  ('   [Window 2] ');
        TextAttr := LtCyanOnLtGray;
        WRite  (Pad(W2Queue,8),'       ',Pad(W2Form,8));
        if W2File <> '' then
          begin
            if W2FileLock then
              Write('      ',Pad(W2File,8),'  Locked   ')
            else
              Write('      ',Pad(W2File,8),'  Read Only');
            if W2FileMod then
              begin
                TextAttr := LtRedOnLtGray;
                Write(' *Changed');
              end;
          end;
        WriteLn;
        TextAttr := BlueOnLtGray;
        WriteLn('    Memory Avail: ',FreeMemory);
        end;
      WaitForEscape;
      CloseWindow;
    end;

  procedure showbcd(x: word);
    var
      c: char;

    begin
    c:=Chr((x shr 12) + 48);
    if c <> '0' then
      Write(c);
    Write(Chr(((x and $0F00) shr 8) + 48), '.',
      Chr(((x and $00F0) shr 4) + 48), Chr((x and $000F) + 48))
    end; {showbcd}

  procedure DisplayConfig;
    Const
      Head = LightCyan;
      Tag  = LightGray;
      Data = Yellow;
    begin
      if not GetConfig(CItem, NConfig) then exit;
      OpenWindow(8,8,58,20,'Workstation Hardware',Copyright_Scheme);
      TextBackground(Blue);
      ClrScr;

      with NConfig do
        begin
          TextColor(Head);
          WriteLn('   CPU');
          TextColor(Tag);
          Write  ('   Processor:     ');
          TextColor(Data);
          WriteLn(CPU);
          TextColor(Tag);
          Write  ('   Co-Processor:  ');
          TextColor(Data);
          WriteLn(NDP);
          TextColor(Tag);
          Write  ('   Type:          ');
          TextColor(Data);
          WriteLn(CpuType);
          TextColor(Head);
          WriteLn('   Memory         Max  Free    Ver   Mgr');
          TextColor(Tag);
          Write  ('   Conventional: ');
          TextColor(Data);
          WriteLn                   (RAM:4,'   ',Avail div 1000:4);
          TextColor(Tag);
          Write  ('   Expanded:     ');
          TextColor(Data);
          if XMSMax > 0 then
            begin
              Write(XMSMax div 10:4,'   ',XMSAvail:4,'   ');
              ShowBCD(XMSVers);
              Write('  ');
              ShowBCD(XMMVers);
              WriteLn;
            end
          else
            WriteLn('None');
        end;

      WaitForEscape;
      CloseWindow;
    end;

  procedure SendScanCodes;
    var i: integer;
        Scan: word;
        ID: byte;
        D,L: word;
    const
      CtrlAlt = $C;
    begin
      While CheckKBD(Scan) do Scan := ReadKeyWord;
      with CItem^ do
        begin
          if not DirectConnect then
            begin
              if Dialog('Cannot Direct Connect!','NENCON',Red,'OK','')=0 then;
              exit;
            end;
          OpenMessage('Type keys, Ctrl+Alt to Quit', BrightYellow_Scheme);
          I := 1;
          ID := neACK;
          Repeat
            CheckForIPXCall;
            if IPXMessagePending then  { make sure we can answer }
              HandleIPXMessage;
            if CheckKBD(Scan) then
              begin
                inc(I);
                Scan := ReadKeyWord;
                WriteCentred(3,HexW(Scan));
                SendMessage(neScanCode, Scan, 2);
                CheckForIPXCall;
                if IPXMessagePending then  { make sure we can answer }
                  HandleIPXMessage;
              end;
          Until ((KbdFlags and CtrlAlt) = CtrlAlt) or (ID <> neACK);
          Disconnect;
          CloseMessage;
        end;
    end;

  Procedure RetrieveFile(Path: PathStr);
    var LocalPath: PathStr;
        Esc: boolean;
    begin
      LocalPath := Path;
      GetInput('Local FileName','NENCON',Green,'To File:',40,
               LocalPath, Esc);
      if Esc then exit;
      if GetFile(CItem, Path, LocalPath, False) then;
    end;

  Procedure EditRemoteFile(Path: PathStr);
    var F: File;
    begin
      if GetFile(CItem, Path, 'NENCON.TMP', True) then
        EditFile('NENCON.TMP');
      if UserSaysYes('Save Changes to Remote?',EscapeMeansNo) then
        SendFileToRemote(CItem, Path, 'NENCON.TMP', True);
      Assign(F,'NENCON.TMP');
      {$I-}
      Erase(F);
      {$I+}
    end;

  Procedure ViewRemoteFile(Path: PathStr);
    var F: File;
    begin
      if GetFile(CItem, Path, 'NENCON.TMP', True) then
        DisplayFile('NENCON.TMP');
      Assign(F,'NENCON.TMP');
      {$I-}
      Erase(F);
      {$I+}
    end;

  Procedure DoDeviceList;
    var i: integer;
       Stat: ObjectStr;
    Const DHeader = '      Device       Description                Assigned to';
    begin
      New(DDTable);
      OpenMessage('Receiving Device List',BrightYellow_Scheme);
      if not GetDeviceList(CItem, 0, True) then
        begin
          CloseMessage;
          exit;
        end;
      CloseMessage;
      if NumDDFItems > 0 then
        begin
          for i := 1 to NumDDFItems do
            begin
              Stat := '--Free--';
              if DDTable^[i].InUse then
                Stat := DDTable^[i].InUseBy;
              Menu^[i] := Pad(DDTable^[i].DeviceName,13)+
                          Pad(DDTable^[i].Description,27)+
                          Stat;
            end;
          OpenMenu(WinX+2,WinY+2,WinX+60,WinY+10,Menu^,NumDDFItems,55,NoSort,
                   DHeader,'Device List',White_Scheme,i);
          i := GetMenu;
          if not EscapePressed then
            begin
              DDTable^[i].Alias := 'CG1';
              AssignSlaveDevice(CItem, DDTable^[i]);
            end;
          CloseWindow;
        end;
      Dispose(DDTable);
    end;

  Procedure ConvertDirSpec(DR: DirSpec; var S,D: char);
    begin
      with DR do
        begin
          Case Sort of
              1 : S := 'N';
              2 : S := 'T';
              3 : S := 'S';
            end;
          D := '+';
          if not UpDown then
            D := '-';
        end;
    end;

  Procedure DoLocalDirectory(DR: DirSpec);
    var S,D: char;
    begin
      ConvertDirSpec(DR, S,D);
      inc(DirLevel);
      New(LocalDir[DirLevel], Init(DR.Path, S, D));
      New(DirStack[DirLevel],
         Init(LocalDir[Dirlevel]^.Dir,
              LocalDir[DirLevel]^.Count,
              DR));
      DirStack[DirLevel]^.Process;
      Dispose(LocalDir[DirLevel], Close);
      Dispose(DirStack[DirLevel], Done);
    end;

  Procedure DoRemoteDirectory(DR: DirSpec);
    begin
      if DirLevel = 5 then exit;
      inc(DirLevel);
      OpenMessage('Receiving Directory',BrightYellow_Scheme);
      if not GetDirectory(CItem, DR) then
        begin
          CloseMessage;
          exit;
        end;
      CloseMessage;
      New(DirStack[DirLevel],
         Init(RemoteDir[Dirlevel],
              DirSize[DirLevel],
              DR));
      DirStack[DirLevel]^.Process;
      ReleaseDirectory;
      Dispose(DirStack[DirLevel], Done);
    end;

  procedure DirDisplay.GetDirLine(Item: integer; var Line: String);
  var
    Ps: Integer;
    Total: Longint;
    T: DateTime;
    N: NameStr;
    E: ExtStr;
    begin
      with Dir^[Item-1]^ do
      begin
        Ps := Pos('.', Name);
        if Ps > 1 then
        begin
          N := Copy(Name, 1, Ps - 1);
          E := Copy(Name, Ps + 1, 3);
        end else
        begin
          N := Name;
          E := '';
        end;
        Line := Pad(N+Pad(' ',9 - Length(N))+E+Pad(' ',4-Length(E)),12);
        if Attr and DOS.Directory <> 0 then
          Line := Pad(Trim(Line),12)+' <DIR>     '
        else
          Line := Line + LeftPad(Long2Str(Size),8)+'  ';
        UnpackTime(Time, T);
        Line := Line+
          LeftPadCh(Long2Str(T.Day),'0',2)+'-'+
          MonthStr[T.Month]+'-'+
          LeftPadCh(Long2Str(T.Year mod 100),'0', 2)+'  '+
          LeftPadCh(Long2Str(T.Hour), '0', 2)+':'+
          LeftpadCh(Long2Str(T.Min), '0', 2);
      end;
  end;

  Procedure SupplyString(Item: word; Mode: pkMode;
                         var IType: pkItemType;
                         var IString: String;
                         PickPtr: PickListPtr);
    var CurCol: byte;
    begin
      with CItem^ do
        begin
          IType := pkNormal;
          with PickPtr^ do
            Case Mode of
                pkDisplay  : begin  { pretty, with flexwrite chars }
                               DirStack[DirLevel]^.GetDirLine(Item, IString);
                             end;
                pkSearch   : begin  { no extra characters }
                               DirStack[DirLevel]^.GetDirLine(Item, IString);
                             end;
                pkGetType  : begin
                             end;
              end;
      end;
    end;

  constructor DirDisplay.Init(Direc : DirListPtr; FCount: integer; DRS: DirSpec);
    begin
      Dir := Direc;
      Count := FCount;
      DR := DRS;
      White_Scheme;
      NENColorSet.HeaderColor := BlackOnLtCyan;
{      NENColorSet.TextColor := WhiteOnBlack;
      NENColorSet.SelItemColor := BlackOnLtCyan;}
      New(DirList,
          InitDeluxe(WinX+DirLevel+1,WinY+DirLevel+1,48+DirLevel,22,NENColorset,
                     wClear or wUserContents or wResizeable or
                     wBordered,
                     40,
                     Count,
                     SupplyString,
                     PickVertical,
                     SingleChoice,
                     DefPickOptions));

      New(PCP,Init(@PickKeySet, PickKeyMax));
      CustomizeCommandProcessor(PCP^);
      DirList^.SetCommandProcessor(PCP^);

      CustomizeWindow(DirList^, DR.Path, 20);

      AddScrollBars(DirList^,False);
      with DirList^ do
        begin
          pkOptionsOn(pkProcessZero);
          SetPadSize(1,1);
        end;

      SetZoomLimits(DirList^, 2,3,79,24);

    end;

  procedure DirDisplay.Process;
    var DR2: DirSpec;
    begin
      Quit := False;
      with DirList^ do
        While not Quit do
          begin
            Process;
            Case GetLastCommand of
                ccMouseDown,
                ccMouseSel :
                  {did user click on the hot spot for closing?}
                  if HandleMousePress(DirList^) = hsRegion3 then begin
                    ClearMouseEvents;
                    Quit := True;
                  end;
                ccSelect     : begin
                                 with Dir^[GetLastChoice-1]^ do
                                   begin
                                     if Attr and DOS.Directory = 0 then
                                       begin
                                         I := 2;
                                         Menu^[1] := 'Read File';
                                         Menu^[2] := 'Edit File';
                                         if not Local then
                                           begin
                                             Menu^[3] := 'Retrieve File';
                                             I := 3;
                                           end;
                                         if (SendMode) or ((Local) and (Connected)) then
                                           begin
                                             Menu^[3] := 'Send File';
                                             I := 3;
                                           end;
                                         OpenMenu(WinX+DirLevel+2,WinY+DirLevel+2,
                                                  WinX+DirLevel+20,WinY+DirLevel+3+I,
                                                  Menu^,I,15,NoSort,'',Name,
                                                  White_Scheme,I);
                                         P := JustPathName(DR.Path);
                                         if (P <> '') and (P[Length(P)] <> '\') then
                                           P := P+'\';
                                         P := P+Name;
                                         Case GetMenu of
                                             1 : if Local then DisplayFile(P)
                                                 else ViewRemoteFile(P);
                                             2 : if Local then EditFile(P)
                                                 else EditRemoteFile(P);
                                             3 : if (SendMode) or ((Local) and (Connected)) then
                                                   SendFileToRemote(CItem,P,P,False)
                                                 else
                                                   if not Local then
                                                     RetrieveFile(P);
                                           end;
                                         CloseWindow;
                                       end
                                     else
                                       begin
                                         if Local then
                                           begin
                                             DR2 := DR;
                                             P := JustPathName(DR2.Path);
                                             if (P <> '') and (P[Length(P)] <> '\') then
                                               P := P+'\';
                                             P := P+Name+'\';
                                             DR2.Path := P;
                                             DoLocalDirectory(DR2);
                                           end
                                         else
                                           begin
                                             DR2 := DR;
                                             P := JustPathName(DR2.Path);
                                             if (P <> '') and (P[Length(P)] <> '\') then
                                               P := P+'\';
                                             P := P+Name+'\';
                                             DR2.Path := P;
                                             DoRemoteDirectory(DR2);
                                           end;
                                       end;
                                   end;
                               end;
                ccQuit,
                ccDone       : Quit := True;
                ccUser40 : if not KeyboardMove(DirList^) Then RingBell;
                ccUser41 : begin
                             if not ToggleZoom(DirList^) then RingBell;
                           end;
                ccUser42 : begin
                             if not KeyboardResize(DirList^) then RingBell;
                           end;
            end;
          end;
    end;

  Destructor DirDisplay.Done;
    begin
      DirList^.erase;
      Dispose(PCP, Done);
      Dispose(DirList, Done);
      Dec(DirLevel);
    end;

  Procedure DoDirectoryDisplay;
    begin
      New(DirStack[Dirlevel], Init(RemoteDir[DirLevel], DirSize[DirLevel], DR));
      DirStack[DirLevel]^.Process;
      ReleaseDirectory;
      Dispose(DirStack[DirLevel], Done);
    end;

  Procedure DoDirectoryGet;
    var Path: PathStr;
        Esc: boolean;
    begin
      DR.Path := '';
      GetDirSpec(DR);
      Esc := DR.Path = '';
      if not Esc then
        begin
          if DirLevel = 5 then exit;
          inc(DirLevel);
          OpenMessage('Receiving Directory',BrightYellow_Scheme);
          if not GetDirectory(CItem, DR) then
            begin
              CloseMessage;
              exit;
            end;
          CloseMessage;
          DoDirectoryDisplay;
        end;
    end;

  Procedure DoServiceMenu(CItem: PLoggedInConnection);
    var I,J: integer;
    begin
      With CItem^ do
        begin
          New(Services);
          if GetServiceList(Citem, Services^, I) then
            begin
              for j := 1 to I do
                Menu^[j] := Services^[j].Description;
              OpenMenu(WinX+2,WinY+2,WinX+44,WinY+14,Menu^,I,30,NoSort,
                       '',ProgramInfo.ProgName+' Services ',White_Scheme,I);
              While not EscapePressed do
                begin
                  I := GetMenu;
                  With Services^[I] do
                    Case ParamRequest of
                        prOK    : begin
                                  NumParameter := Dialog(Prompt,
                                                         'NENCON',
                                                         Blue,
                                                         'OK','');
                                  Escape := NumParameter = 0;
                                  end;
                        prYesNo : begin
                                  NumParameter := Dialog(Prompt,
                                                         'NENCON',
                                                         Blue,
                                                         'Yes','No');
                                  Escape := NumParameter = 0;
                                  end;
                        prString: GetInput('Remote Data','NENCON',Blue,
                                           Prompt,30,Parameter,Escape);
                      end;
                  SendCommand(CItem, Services^[I]);
                  ChangeMenuItem(I, Services^[I].Description);
                  if Services^[I].Instruction <> neACK then
                    Case Services^[I].Instruction of
                        neViewFile : ViewRemoteFile(Services^[I].Parameter);
                      end;
                end;
              CloseWindow;
            end
          else
            if Dialog('No Services Available',
                      'NENCON',
                      Green,'OK','') = 0 then;
          Dispose(Services);
        end;
    end;

Procedure NConBackground;  { Gets called during timeout loops }
begin
  UpdateTime(False);
end;

Procedure RunNENCON;
var I: integer;
    UName: ObjectStr;
    Esc: boolean;
    Count: word;
  begin
    With SYS^.ProgInfo do
      begin
        ProgName := 'NENCON';
        ProgDesc := 'NewsMaker Console';
        ProgVer  := 'V1.13 12 May 93';
        ProgCopy := '(C)1993, NewsMaker Systems';
        TextColor(White);
        Write(ProgDesc+' '+ProgVer,' ');
        TextColor(LightGray);
        WriteLn(ProgCopy);
      end;
    for I := 1 to ParamCount do
      begin
        PString := Trim(StUpCase(ParamStr(I)));
        if PString = '?' then
          begin
            WriteLn('Command Line options:');
            WriteLn('   /LOCAL  - Local operation only (Does not require shell)');
            WriteLn('   /Txxxx  - Event Timeout in milliseconds (Default 2000)');
            WriteLn('   /Lxxxx  - Listen Timeout in milliseconds (Default 5000)');
            WriteLn('   /Dxxxx  - Socket change delay in milliseconds (Default 5000)');
            WriteLn('   /I      - Shell information');
            WriteLn('   /Sx     - Machine control slave mode, Slave number x');
            WriteLn('   /LOG    - Writes Responder log to disk');
            Halt;
          end;
        if PString <> '/LOCAL' then
          begin
            LocalMode := True;
          end;
        if Copy(PString,1,2) = '/T' then
          begin
          if Length(PString) > 2 then
            Val(Copy(PString,3,Length(PString)-2),EventTimeout,J);
          end;
        if Copy(PString,1,2) = '/L' then
          begin
          if Length(PString) > 2 then
            Val(Copy(PString,3,Length(PString)-2),ListenTimeout,J);
          end;
        if Copy(PString,1,2) = '/D' then
          begin
          if Length(PString) > 2 then
            Val(Copy(PString,3,Length(PString)-2),DTime,J);
          end;
        if PString = '/I' then
          begin
            SPXServicesAvail(Version, MaxConn, AvailConn);
            WriteLn('SPX Version: ',Version shr 8,'.',
                    LeftPadCh(Long2Str(Version and $FF),'0',2));
            WriteLn('Max Connect: ',MaxConn);
            WriteLn('Available:   ',AvailConn);
            WriteLn;
            Halt;
          end;
        if Copy(PString,1,2) = '/S' then
          begin
          if Length(PString) > 2 then
            Val(Copy(PString,3,Length(PString)-2),SlaveNumber,J);
          New(Sys_Channel, InitSlave(SlaveNumber, 0, 0, 0, 0));
          ThisIsMachineControlSlave := True;
          end;
        if PString = '/LOG' then
          DoTraceLogFile := True;
      end;

    if not LocalMode then
      begin
        if not NetwareLoaded(Logged) then
          Die('!IPX/NetWare Shell not loaded');
        if not Logged then
          Die('!Not logged in');
         if not IPXServicesAvail then
           Die('!IPX not available');
{        if not SPXServicesAvail(Version, MaxConn, AvailConn) then
           Die('!SPX not available');}
         if not ConsolePriv then
           Die('! You do not have Console Access');
      end;

    WinOpts := wClear;
    if not Win.InitCustom( 1, 1, 80, 25, DefaultColorSet, WinOpts) then begin
      Writeln('Failed to initialize RawWindow, Status ', InitStatus);
      Halt;
    end;

    SetBlink(False);
    SetPaletteRegister(6,38);
    Win.Draw;

    New(NMenu);

    TextChar := #$B0;
    TextBackground(Black);
    TextColor(LightGray);
    UData^.ClockAttr := LtGreenOnBlue;
    UData^.RConnect := ' ';
    UData^.LConnect := ' ';
    UData^.MemX := 62;
    UData^.MemoryWindowUp := True;
    UData^.MemAttr := LtBlueOnBlue;
    UData^.SPXDisplayUp := True;
    UData^.SPXAttr := LtRedOnBlue;
    ClrScr;
    Connected := False;

    with DR do
      begin
        Path := '';
        Sort := 1;
        UpDown := True;
      end;
    with SYS^.ProgInfo do
      begin
        FastWrite(Center(ProgDesc,80),1,1,YellowOnBlue);
        FastWrite(ProgName,1,1,LtCyanOnBlue);
        FastWrite(LeftPad(ProgCopy,80),25,1,LtGrayOnBlue);
        FastWrite(ProgVer,25,1,LtCyanOnBlue);
        if ThisIsMachineControlSlave then
          FastWrite('NENSLAVE'+Long2Str(SlaveNumber)+' '+HexW(NEN_TXSocket),
                    1,10,LtRedOnBlue);
        if not LocalMode then
          FastWrite(OurUserName+' on Connection '+Long2Str(OurConnNo),25,26,LtRedOnBlue)
        else
          FastWrite('Not on Network',25,26,LtRedOnBlue);
      end;

    Background := NConBackground;

    Menu^[1] := 'Find User Connections';
    Menu^[2] := 'Scan All Connections';
    Menu^[3] := 'Set Trace Options';
    Menu^[4] := 'Local Disk Functions';
    OpenMenu(5,5,30,20,Menu^,4,25, NoSort, '', 'Choices',
             White_Scheme, I);
    While not EscapePressed do
      begin
        Case GetMenu of
          1 : begin
                UpdateTime(False);
                UName := '';
                BuildLoggedInUsersMenu(NMenu^, I);
                OpenMenu(6,6,55,11,NMenu^,I,45,Sort,UserHead,' Logged in Users, '+Long2Str(I)+' Found',White_Scheme,I);
                While not EscapePressed do
                  begin
                    I := GetMenu;
                    if I > 0 then
                      begin
                        GetMenuString(I, UName);
                        UName := Trim(StUpCase(ExtractWord(1,UName,[':',' '])));
                        OpenMessage('Polling Workstations..',BrightYellow_Scheme);
                        Count := FindConnsForUser(UName);

                        BuildUserList(NMenu^, Size);
                        CloseMessage;
                        if Size = 0 then
                          begin
                            Dialog('No NewsMaker Connections','NENCON',Blue,'OK','');
                            ClearEscape;
                          end
                        else
                          begin
                            DoConnectionMenu(UName);
                          end;
                      ReleaseNENList;
                      ReleaseUserList;
                    end;
                end;
              Connected := False;
              CloseWindow;
            end;
          2 : begin
                OpenMessage('Polling Workstations..',BrightYellow_Scheme);
                UpdateTime(False);
                FindLoggedInUsers(True);

                BuildUserList(NMenu^, Size);
                CloseMessage;
                if Size = 0 then
                  begin
                    Dialog('No NewsMaker Connections','NENCON',Blue,'OK','');
                    ClearEscape;
                  end
                else
                  begin
                    DoConnectionMenu('');
                  end;
              Connected := False;
              ReleaseUserList;
              ReleaseNENList;
            end;
        3 : begin
              Menu^[1] := 'Trace Log On';
              Menu^[2] := 'Trace Log off/View';
              Menu^[3] := 'Responder Trace';
              OpenMenu(6,6,30,11,Menu^,3,18,NoSort,'',' Option ',White_Scheme,I);
              Case GetMenu of
                  1 : OpenTraceWindow(NTrace);
                  2 : CloseTraceWindow;
                  3 : begin
                        OpenWindow(3,3,78,23,'Responder Mode',Black_Scheme);
                        TextBackground(Black);
                        TextColor(White);
                        ClrScr;
                        SetIPXTrace(True);
                        While not Keypressed do
                          begin
                          UpdateTime(False);
                          CheckForIPXCall;
                          if IPXMessagePending then
                            HandleIPXMessage;
                          end;
                        While Keypressed do if ReadKey = ' ' then;
                        SetIPXTrace(False);
                        CloseWindow;
                      end;
                end;
              CloseWindow;
            end;
        4 : begin
              Menu^[1] := 'Directory';
              Menu^[2] := 'Edit File';
              OpenMenu(6,6,30,11,Menu^,2,18,NoSort,'',' Local ',White_Scheme,I);
              Local := True;
              While not EscapePressed do
                Case GetMenu of
                  1 : begin
                        DR.Path := '';
                        GetDirSpec(DR);
                        if DR.Path <> '' then
                          begin
                            DoLocalDirectory(DR);
                          end;
                      end;
                  2 : Begin
                        ChooseAndEditFile('*.*',True);
                      end;
                end;
              CloseWindow;
              Local := False;
            end;
        end;
    end;
    CloseWindow;

    Dispose(NMenu);
    Win.Done;
    Background := NullBackgroundProcessor;
    SetBlink(True);
  end;

Procedure DoConnectionMenu(User: ObjectStr);
begin
  if User <> '' then
    OpenMenu(WinX+2,WinY+2,WinX+67,WinY+17,NMenu^,Size,60, Sort, ConnHead, 'Connections for '+User,
             White_Scheme, I)
  else
    OpenMenu(WinX+2,WinY+2,WinX+67,WinY+17,NMenu^,Size,60, Sort, ConnHead, 'NewsMaker Connections',
             White_Scheme, I);
  While not EscapePressed do
    begin
      M := GetMenu;
      if M <> 0 then
        begin
          GetMenuString(M, CLine);
          Val(ExtractWord(1,Cline,[' ']),ConnNo,I);
          Connected := True;
          if StUpCase(Trim(Copy(Cline,14,17))) <> 'NON-' then
            begin
              CItem := FindConn(ConnNo);
              Menu^[1] := 'Status';
              Menu^[2] := 'Configuration';
              Menu^[3] := 'Directory';
              Menu^[4] := 'Send Files';
              Menu^[5] := 'Control Keyboard';
              Menu^[6] := 'Screen Snapshot';
              Menu^[7] := 'Program Services';
              Menu^[8] := 'Slave Device List';
              OpenMenu(WinX+3,WinY+2,WinX+38,WinY+17,Menu^,8,20, NoSort,
                       '', ' Action: '+Trim(Copy(CLine,1,12))+' '+
                             CItem^.ProgramInfo.Progname,
                       White_Scheme, I);
              While not EscapePressed do
                begin
                  Case GetMenu of
                    1 : begin
                        if CItem <> nil then
                          begin
                            StatusReturned := False;
                            if CItem^.ProgramInfo.ProgName = 'NEN' then
                              begin
                                DisplayNENStatus;
                                StatusReturned := True;
                              end;
                            if not StatusReturned then
                              if Dialog('Status not available',
                                        CItem^.ProgramInfo.Progname,
                                        Green,'OK','')
                                        =0 then;
                          end;
                        end;
                    2 : begin
                          if CItem <> nil then
                            begin
                              DisplayConfig;
                            end;
                        end;
                    3 : begin
                          DoDirectoryGet;
                        end;
                    4 : begin
                          DR.Path := '';
                          GetDirSpec(DR);
                          if DR.Path <> '' then
                            begin
                              SendMode := True;
                              DoLocalDirectory(DR);
                              SendMode := False;
                            end;
                        end;
                    5 : begin
                          SendScanCodes;
                        end;
                    6 : begin
                          if SaveWindow(1,1,80,25,True,Covers) then;
                          UData^.ClockOn := False;
                          UData^.MemoryWindowUp := False;
                          HiddenCursor;
                          if GetScreen(CItem) then
                            WaitForEscape;
                          RestoreWindow(1,1,80,25,True,Covers);
                          NormalCursor;
                          UData^.ClockOn := True;
                          UData^.MemoryWindowUp := True;
                        end;
                    7 : begin
                          DoServiceMenu(CItem);
                        end;
                    8 : begin
                          DoDeviceList;
                        end;
                    End; {Case }
                end; { While }
              CloseWindow;
            end; { While }
        end; { If M <> 0 }
    end; { While }
  CloseWindow;
end;

End.
