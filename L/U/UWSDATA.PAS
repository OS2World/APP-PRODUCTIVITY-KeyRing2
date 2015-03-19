{~change:Added vcs header~}
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
{$A-,R-,S-,V-,O+,F+}
Unit UWsData;

{----------------------------------------------------------------------}
{ (C) 1990 NewsMaker Systems                                           }
{ Workstations specific configuration data management                  }
{ Workstation is identified by the node address of its network adapter }
{----------------------------------------------------------------------}

interface

Uses
    Dos,
    InstGlo,
    NetWare,
    NWIPXSPX,
    OpCmd,
    OpCrt,
    OpEntry,
    OpFrame,
    OpMouse,
    OpString,
    OpWindow,
    QHdrRec,
    QGlobal,
    UGlobal,
    ULib,
    UMenu,
    UMsg,
    UColors,
    UWindow;

Type
  NameStr     = String[30];
  CGName      = String[10];
  PrinterName = String[10];
  VideoName   = String[10];
  SourceName  = String[5];

  InOutType   = (InputOnly, OutputOnly, InputOutput);

  Device = Object    { abstract type, for inheritance only }
      Installed: boolean;                    { True, false}
      DevType  : InOutType;
      HelpProc : esUserProc;
      DevName  : String[15];
      Constructor Init;
      procedure SetDefault; Virtual;
      procedure Edit; Virtual;
      function  MatchDevice(DType: InOutType; var DName: NameStr): boolean;
    end;

  SerialPort = Object(Device)
      ComPort  : word;         { 1..4       }
      Baud     : word;         { 300..19200 }
      Parity   : word;         { N, E, O    }
      DataBits : word;         { 7,8        }
      StopBits : word;         { 1,2        }
      XonXoff  : boolean;      { true, False}
      Constructor Init;
      procedure SetDefault; Virtual;
      procedure Edit; Virtual;
    end;

  PrinterPort = Object(SerialPort)
      IsParallel : boolean;      { True=Parallel, False=Serial }
      Parallel   : word;         { 1=Lpt1, 2=Lpt2, 3=Lpt3 }
      Driver     : PrinterName;  { Name, corresponds to Driver in PRINTER.SYS }
      Constructor Init;
      procedure SetDefault; Virtual;
      procedure Edit; Virtual;
    end;

  CharacterGenerator = Object(SerialPort)
      Driver    : CGName;        { DUBNER, CHYRON4 etc. corresponds to driver name}
      DriverNum : word;          { Corresponding number (for Choice field) }
      Constructor Init;
      procedure SetDefault; Virtual;
      procedure Edit; Virtual;
    end;

  VideoAdapter = Object(Device)
      Name      : VideoName;     { TARGA, VIDEOLOGIC etc. }
      Constructor Init;
      procedure SetDefault; Virtual;
      procedure Edit; Virtual;
    end;

  VideoSource = Object(Device)
      SourceType: SourceName;    { VTR, CD etc. }
      Model     : VideoName;     { Corresponds to Driver name }
      Constructor Init;
      procedure SetDefault; Virtual;
      procedure Edit; Virtual;
    end;

{----------------------------------------------------------------------}
{ Workstation configuration record                                     }

  DeviceArray = Array[1..5] of ^Device;

  WSConfigPtr = ^WSConfig;
  WSConfig = Record
      ID     :  PhysicalNodeAddress;    { Unique address from Network card }
      Name   :  NameStr;                { Description of workstation       }
      Floppy :  boolean;                { WS has a floppy drive A          }
      HDisk  :  boolean;                { WS has a hard disk               }
      CPU    :  word;                   { 186, 286, 386, 486 etc.          }
      Filler :  Array[1..128] of byte;
      Modem  :  SerialPort;             { Modem configuration, if any      }
      Printer:  PrinterPort;            { Printer description              }
      CG     :  CharacterGenerator;     { CG description                   }
      Video  :  VideoAdapter;           { Full-motion video board          }
      Source :  VideoSource;            { SONYVTR, CD etc.                 }
    end;

  Procedure InitWorkstation;
  Procedure GetWorkstationInfo(var WSData: WsConfig);
  Procedure PutWorkstationInfo(WS: WSConfig);
  Procedure EditWorkstationInfo(var WS: WSConfig);
  Procedure SelectWorkstation;
  Procedure MaintainWorkstations;
  Procedure PickDriver(DevType: InOutType; var Driver: NameStr);

Var
  WS          : WsConfigPtr;
  WorkStation : WsConfigPtr Absolute WS;   { Pseudonym }

implementation

const
  WsFilename = 'NEN.WSC';

  NumCGs    = 3;
  CGDrivers : Array[1..NumCGs]of CGName = ('CHYRON4',
                                           'DUBNER20K',
                                           'INFINIT!');
  B_Chyron4   = 1;
  B_Dubner20K = 2;
  B_Infinti   = 3;

type
  PrinterListType = Array[1..MaxPrinters] of PrinterName;
  PrinterListPtr  = ^PrinterListType;

var
  WSFile  : File of WsConfig;
  WSTemp  : ^WsConfig;
  InterNet: IPXaddress;
  WSID    : PhysicalNodeAddress;
  EM      : EntryScreenPtr;        { Main entry screen   }
  ER      : EntryScreenPtr;        { Device entry screen }
  ID      : integer;
  StartX  : byte;
  StartY  : byte;
  Changed : boolean;
  RecNo   : integer;

  PrinterFile   : File Of PrintSeqRec;
  PrinterRec    : PrintSeqRec;
  PrinterList   : PrinterListPtr;
  NumPrinters   : integer;

{----------------------------------------------------------------------}
{ Set a workstation record to Default values                           }

  Procedure WSDefault;
    Const Default : String[6] = 'LOCAL ';
    begin
      Move(Default[1],WS^.ID,6);
      WS^.Name := SysMsg(000627){'STANDARD WORKSTATION'};
      WS^.Printer.Installed := false;
      WS^.CG.Installed := False;
      WS^.Video.Installed := false;
      WS^.Source.Installed := false;
      WS^.Floppy := False;
      WS^.HDisk := false;
      WS^.CPU := 286;
      WS^.Modem.SetDefault;
      WS^.Printer.SetDefault;
      WS^.CG.SetDefault;
      WS^.Video.SetDefault;
      WS^.Source.SetDefault;
    end;

{----------------------------------------------------------------------}
{ Get information for this workstation                                 }

  Procedure GetWorkstationInfo(var WSData: WsConfig);
    begin
      WsData := WS^;
    end;

{----------------------------------------------------------------------}
{ Set information for this workstation                                 }

  Procedure PutWorkstationInfo(WS: WSConfig);
    begin
      if Changed then
        begin
        if not UserSaysYes(SysMsg(000628){'Update Workstation Table?'},EscapeMeansNo) then
          exit;
        end
      else
        exit;
      New(WSTemp);
      {$I-}
      Assign(WsFile,NEN^.SysDir+'\'+WsFilename);
      Reset(WsFile);
      if IoResult <> 0 then
        begin
          ReWrite(WsFile);
        end;
      RecNo := 0;
      While not EOF(WsFile) do
        begin
          Read(WsFile,WStemp^);
          if CompStruct(WSTemp^.ID,WS.ID,6) = Equal then
            begin
              Seek(WsFile,RecNo);
              Write(WsFile,WS);
              Close(WsFile);
              Dispose(WSTemp);
              exit;
            end;
          inc(RecNo);
        end;
      Seek(WsFile,FileSize(WsFile));
      Write(WsFile,WS);
      Close(WsFile);
      Dispose(WSTemp);
    end;

{---------------------------------------------------}
Procedure WriteHelp(Msg: String);
  begin
    WriteStr(StartX+2,StartY+1,Pad(Msg,27),Attr(Yellow,Red));
  end;

{---------------------------------------------------}
Procedure CGHelp(ESR: EntryScreenPtr);
  begin
    Case ESR^.GetCurrentID of
        0,2..5 : WriteHelp(SysMsg(000629){'Press SPACE for options'});
        1      : WriteHelp(SysMsg(000630){'Y or N'});
      end;
  end;

{---------------------------------------------------}
Procedure SerialHelp(ESR: EntryScreenPtr);
  begin
    Case ESR^.GetCurrentID of
        0,2..5 : WriteHelp(SysMsg(000629){'Press SPACE for options'});
        1      : WriteHelp(SysMsg(000630){'Y or N'});
      end;
  end;

{---------------------------------------------------}
Procedure PrinterHelp(ESR: EntryScreenPtr);
  begin
    Case ESR^.GetCurrentID of
        0,2..5 : WriteHelp(SysMsg(000629){'Press SPACE for options'});
        1      : WriteHelp(SysMsg(000630){'Y or N'});
      end;
  end;

{----------------------------------------------------------------------}
{ Locate and load unique information for this workstation              }

  Procedure InitWorkstation;
    Const Local : String[6] = 'LOCAL ';
    Var   LoggedIn: boolean;
    begin
      RecNo := 0;
      Changed := False;
      New(WS);
      if NetwareLoaded(LoggedIn) then
        begin
          GetInternetAddress(GetConnNo,InterNet);
          WSID := InterNet.Node;
        end
      else
        Move(Local[1],WSID,6);
      {$I-}
      Assign(WsFile,NEN^.SysDir+'\'+WsFilename);
      Reset(WsFile);
      if IoResult = 0 then
        begin
          While not EOF(WsFile) do
            begin
              inc(RecNo);
              Read(WsFile,WS^);
              if CompStruct(WS^.ID,WSID,6) = Equal then
                begin
                  Close(WsFile);
                  exit;
                end;
            end;
        end
      else
        begin
          WriteLn('Cannot load Workstation File ',NEN^.SysDir+'\'+WsFilename);
        end;
      Close(WsFile);     { No workstation record found }
      if IoResult = 0 then;
      {$I+}
      WS^.Modem.Init;
      WS^.Printer.Init;
      WS^.CG.Init;
      WS^.Video.Init;
      WS^.Source.Init;
      WSDefault;
    end;

{---------------------------------------------------}
Procedure CHelp(ESR: EntryScreenPtr);
  begin
    Case ESR^.GetCurrentID of
        0    : WriteStr(14,5,Pad(SysMsg(000631){'Workstation Description'},30),Attr(Blue,LightGreen));
        1..7 : WriteStr(14,5,Pad(SysMsg(000632){'Press F1 to Edit Information'},30),Attr(Blue,LightGreen));
      end;
  end;

{----------------------------------------------------------------------}
Procedure InitMainEntryScreen;
  Type
    IDType = Array[1..6] of Char;
  begin
    Copyright_Scheme;

    New(EM,InitCustom(12,4,70,19,NENColorSet,DefWindowOptions or wBordered));
    CustomizeWindow(EM^,' Workstation ',10);
    if EM = nil then exit;

    CustomizeCommandProcessor(EntryCommands);
    with EM^,EntryCommands do
      begin
        AddCommand(ccUser1, 1, $3B00, 0);   { F1 }
        AddCommand(ccUser2, 1, $3C00, 0);   { F2 }
        AddCommand(ccUser3, 1, $3D00, 0);   { F3 }
        AddCommand(ccUser4, 1, $3E00, 0);   { F4 }
        AddCommand(ccUser5, 1, $3F00, 0);   { F5 }
        AddCommand(ccUser6, 1, $4000, 0);   { F6 }
        AddCommand(ccUser7, 1, $4100, 0);   { F7 }
        AddCommand(ccUser8, 1, $4200, 0);   { F8 }
        AddCommand(ccUser9, 1, $4300, 0);   { F9 }
        AddCommand(ccUser0, 1, $4400, 0);   { F10}
      end;

    with EM^ do
      begin
        SetPreEditProc(Chelp);

        StartX := WinX+22;
        StartY := WinY+3;

        AddStringField(SysMsg(000633){'Name             '},2,2,'',2,21,30,1,WS^.Name);
        AddYesNoField (SysMsg(000634){'Modem            '},4,2,'',4,21  ,2, WS^.Modem.Installed);
        AddYesNoField (SysMsg(000635){'Printer          '},5,2,'',5,21  ,3, WS^.Printer.Installed);
        AddYesNoField (SysMsg(000636){'Char. Generator  '},6,2,'',6,21  ,4, WS^.CG.Installed);
        AddYesNoField (SysMsg(000637){'Full Motion Video'},7,2,'',7,21  ,5, WS^.Video.Installed);
        AddYesNoField (SysMsg(000638){'VTR/CD Source    '},8,2,'',8,21  ,6, WS^.Source.Installed);
        AddYesNoField (SysMsg(000639){'Floppy Drive     '},9,2,'',9,21  ,7, WS^.Floppy);
        AddYesNoField (SysMsg(000640){'Hard Drive       '},10,2,'',10,21,8, WS^.HDisk);
        AddArrayField (SysMsg(000641){'ID: '},             11,2,'',11, 6,6, 9,IdType(WS^.ID));
    end;
    OpenWindow(StartX+1,StartY+1,66,16,'',BrightYellow_Scheme);
    ClrScr;
    WriteStr(14,7,Pad(SysMsg(000642){'Equipment:'},20),Attr(Brown,Black));
  end;

{----------------------------------------------------------------------}
Procedure InitWSEntryScreen(Width,Depth: word; HelpProc: esUserProc);
  begin
    Copyright_Scheme;

    New(ER,InitCustom(StartX,StartY,67,17,NENColorSet,DefWindowOptions or wBordered));
    CustomizeWindow(ER^,'',10);
    if ER = nil then exit;

    CustomizeCommandProcessor(EntryCommands);
    with ER^,EntryCommands do
      begin
        AddCommand(ccUser1, 1, $3B00, 0);   { F1 }
        AddCommand(ccUser2, 1, $3C00, 0);   { F2 }
        AddCommand(ccUser3, 1, $3D00, 0);   { F3 }
        AddCommand(ccUser4, 1, $3E00, 0);   { F4 }
        AddCommand(ccUser5, 1, $3F00, 0);   { F5 }
        AddCommand(ccUser6, 1, $4000, 0);   { F6 }
        AddCommand(ccUser7, 1, $4100, 0);   { F7 }
        AddCommand(ccUser8, 1, $4200, 0);   { F8 }
        AddCommand(ccUser9, 1, $4300, 0);   { F9 }
        AddCommand(ccUser0, 1, $4400, 0);   { F10}
        cpOptionsOn(cpEnableMouse);
        SetKeyPressedProc(Ukey.Keywaiting);
        SetGetKeyProc(UKey.GetKey);
      end;

    with EM^ do
      begin
        SetPreEditProc(HelpProc);
      end;

  end;

{----------------------------------------------------------------------}
Procedure ProcessEntryScreen;
  var Done: boolean;
  begin
    Done := false;
    ID := 0;
    While not Done do
      begin
        ER^.Process;
        HideMouse;
        case ER^.GetLastCommand of
          ccUser7   : begin
                        Done := True;
                      end;
          ccDone,
          ccQuit    : Done := true;
          end;
      end;

    Dispose(ER,Done);
    Changed := True;
  end;

{----------------------------------------------------------------}
{ Multiple choice field processor for Serial EntryScreen         }

Procedure SerialInfo(var Value;ID: word;Factor: integer;var S: String);
  var Bval: byte absolute Value;
      Wval: word absolute Value;
  Const
      ValidPorts : Array[1..4] of String[4] =
                   ('COM1','COM2','COM3','COM4');
      ValidBaud  : Array[1..5] of String[4] =
                   ('300','1200','2400','4800','9600');
      ValidData  : Array[7..8] of String[1] =
                   ('7','8');
      ValidStop  : Array[1..2] of String[1] =
                   ('1','2');
      ValidParity: Array[1..3] of String[1] =
                   ('N','E','O');
      ValidTerm  : Array[1..5] of String[5] =
                   ('TTY','VT52','VT100','ANSI','VTEXT');

  begin
    Case ID of
      0 :  begin    { COM port }
             Case Factor of
                 1 : if Wval = 4 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 4 else dec(Wval);
               end;
               S := ValidPorts[Wval];
           end;
      2 :  begin    { Baud Rate }
             Case Factor of
                 1 : if Wval = 5 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 5 else dec(Wval);
               end;
               S := ValidBaud[Wval];
           end;
      3 :  begin    { Parity }
             Case Factor of
                 1 : if Wval = 3 then
                      Wval := 1 else inc(Wval);
                -1 : if Wval = 1 then
                      Wval := 3 else dec(Wval);
               end;
             S := ValidParity[Wval];
           end;
      4 :  begin    { Data bits }
             Case Factor of
                 1 : if Wval = 8 then
                      Wval := 7 else inc(Wval);
                -1 : if Wval = 8 then
                      Wval := 7 else dec(Wval);
               end;
             S := ValidData[Wval];
           end;
      5 :  begin    { Stop bits }
             Case Factor of
                 1 : if Wval = 2 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 2 else dec(Wval);
               end;
               S := ValidStop[Wval];
           end;
      6 :  begin    { Terminal type }
             Case Factor of
                 1 : if Wval = 5 then
                      Wval := 1 else inc(Wval);
                -1 : if Wval = 1 then
                      Wval := 5 else dec(Wval);
               end;
               S := ValidTerm[Wval];
           end;
      end;
  end;

{----------------------------------------------------------------}
{ Multiple choice field processor for CG EntryScreen         }

Procedure CGInfo(var Value;ID: word;Factor: integer;var S: String);
  var Bval: byte absolute Value;
      Wval: word absolute Value;
  Const
      ValidPorts : Array[1..4] of String[4] =
                   ('COM1','COM2','COM3','COM4');
      ValidBaud  : Array[1..5] of String[4] =
                   ('300','1200','2400','4800','9600');
      ValidData  : Array[7..8] of String[1] =
                   ('7','8');
      ValidStop  : Array[1..2] of String[1] =
                   ('1','2');
      ValidParity: Array[1..3] of String[1] =
                   ('N','E','O');

  begin
    Case ID of
      0 :  begin    { COM port }
             Case Factor of
                 1 : if Wval = 4 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 4 else dec(Wval);
               end;
               S := ValidPorts[Wval];
           end;
      2 :  begin    { Baud Rate }
             Case Factor of
                 1 : if Wval = 5 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 5 else dec(Wval);
               end;
               S := ValidBaud[Wval];
           end;
      3 :  begin    { Parity }
             Case Factor of
                 1 : if Wval = 3 then
                      Wval := 1 else inc(Wval);
                -1 : if Wval = 1 then
                      Wval := 3 else dec(Wval);
               end;
             S := ValidParity[Wval];
           end;
      4 :  begin    { Data bits }
             Case Factor of
                 1 : if Wval = 8 then
                      Wval := 7 else inc(Wval);
                -1 : if Wval = 8 then
                      Wval := 7 else dec(Wval);
               end;
             S := ValidData[Wval];
           end;
      5 :  begin    { Stop bits }
             Case Factor of
                 1 : if Wval = 2 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 2 else dec(Wval);
               end;
               S := ValidStop[Wval];
           end;
      6 :  begin    { Driver type }
             Case Factor of
                 1 : if Wval = NumCGs then
                      Wval := 1 else inc(Wval);
                -1 : if Wval = 1 then
                      Wval := NumCGs else dec(Wval);
               end;
               S := CGDrivers[Wval];
           end;
      end;
  end;

{----------------------------------------------------------------}
{ Multiple choice field processor for Serial EntryScreen         }

Procedure PrinterInfo(var Value;ID: word;Factor: integer;var S: String);
  var Bval: byte absolute Value;
      Wval: word absolute Value;
  Const
      ValidPorts : Array[1..7] of String[4] =
                   ('COM1','COM2','COM3','COM4','LPT1','LPT2','LPT3');
      ValidBaud  : Array[1..5] of String[4] =
                   ('300','1200','2400','4800','9600');
      ValidData  : Array[7..8] of String[1] =
                   ('7','8');
      ValidStop  : Array[1..2] of String[1] =
                   ('1','2');
      ValidParity: Array[1..3] of String[1] =
                   ('N','E','O');
      ValidTerm  : Array[1..5] of String[5] =
                   ('TTY','VT52','VT100','ANSI','VTEXT');

  begin
    Case ID of
      0 :  begin    { COM port }
             Case Factor of
                 1 : if Wval = 7 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 7 else dec(Wval);
               end;
               S := ValidPorts[Wval];
           end;
      2 :  begin    { Baud Rate }
             Case Factor of
                 1 : if Wval = 5 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 5 else dec(Wval);
               end;
               S := ValidBaud[Wval];
           end;
      3 :  begin    { Parity }
             Case Factor of
                 1 : if Wval = 3 then
                      Wval := 1 else inc(Wval);
                -1 : if Wval = 1 then
                      Wval := 3 else dec(Wval);
               end;
             S := ValidParity[Wval];
           end;
      4 :  begin    { Data bits }
             Case Factor of
                 1 : if Wval = 8 then
                      Wval := 7 else inc(Wval);
                -1 : if Wval = 8 then
                      Wval := 7 else dec(Wval);
               end;
             S := ValidData[Wval];
           end;
      5 :  begin    { Stop bits }
             Case Factor of
                 1 : if Wval = 2 then
                      Wval := 1 else inc(Wval);
                -1 : if Bval = 1 then
                      Wval := 2 else dec(Wval);
               end;
               S := ValidStop[Wval];
           end;
      6 :  begin    { Driver type }
             Case Factor of
                 1 : if Wval = NumPrinters then
                      Wval := 1 else inc(Wval);
                -1 : if Wval = 1 then
                      Wval := NumPrinters else dec(Wval);
               end;
               S := PrinterList^[Wval];
           end;
      end;
  end;

{------------------------------------------------------------------------}
{ empty Template base-object methods, will be overridden by real methods }

    Constructor Device.Init;
      begin
      end;

    procedure Device.SetDefault;
      begin
      end;

    procedure Device.Edit;
      begin
      end;

    function Device.MatchDevice(Dtype: InOutType; var DName: NameStr): boolean;
      begin
        MatchDevice := False;
        if not Installed then exit;
        if DevType = DType then
          begin
            DName := Devname;
            MatchDevice := True;
          end;
      end;

{----------------------------------------------------------------------}
{ Data handler methods for SerialPort                                  }

    Constructor SerialPort.Init;
      begin
        Device.Init;
      end;

    procedure SerialPort.SetDefault;
      begin
        Installed := false;
        DevName := 'Serial Port';
        DevType := InputOutput;
        ComPort   := 1;
        Baud      := B1200;
        DataBits  := 8;
        Parity    := 1;
        StopBits  := 1;
      end;

    procedure SerialPort.Edit;
      begin
        InitWSEntryScreen(30,5,SerialHelp);
        with ER^ do
          begin
          AddChoiceField (SysMsg(000643){'Com Port    '},2,2,'XXXX',2,15,2,2,SerialInfo,ComPort);
          AddYesNoField  (SysMsg(000644){'Flow Control'},3,2,''    ,3,15,3,              XonXoff);
          AddChoiceField (SysMsg(000645){'Baud Rate   '},4,2,'XXXX',4,15,4,2,SerialInfo,Baud);
          AddChoiceField (SysMsg(000646){'Parity      '},5,2,'X'   ,5,15,5,2,SerialInfo,Parity);
          AddChoiceField (SysMsg(000647){'Data Bits   '},6,2,'X'   ,6,15,6,2,SerialInfo,DataBits);
          AddChoiceField (SysMsg(000648){'Stop Bits   '},7,2,'X'   ,7,15,7,2,SerialInfo,StopBits);
          end;
        ProcessEntryScreen;
      end;

{----------------------------------------------------------------------}
{ Data handler methods for PrinterPort                                 }

    Constructor PrinterPort.Init;
      begin
        SerialPort.Init;
      end;

    procedure PrinterPort.SetDefault;
      begin
        Installed := false;
        DevType   := OutputOnly;
        IsParallel := True;
        DevName := 'Printer';
        Parallel := 1;          { LPT1 }
        ComPort   := 1;
        Baud      := B1200;
        DataBits  := 8;
        Parity    := 1;
        StopBits  := 1;
      end;

    procedure PrinterPort.Edit;
      var I,DNum: integer;
      begin
        Assign(PrinterFile,NEN^.SysDir+'\PRINTER.SYS');
        {$I-}
        Reset(PrinterFile);
        if IoResult <> 0 then exit;
        InitWSEntryScreen(30,5,PrinterHelp);
        New(PrinterList);
        I := 0;
        While not EOF(PrinterFile) do
          begin
            inc(I);
            Read(PrinterFile,PrinterRec);
            PrinterList^[I] := PrinterRec.PrinterName;
          end;
        NumPrinters := I;
        Close(PrinterFile);
        {$I+}

        DNum := 0;
        for I := 1 to NumPrinters do
          if PrinterList^[I] = Driver then
            DNum := I;

        with ER^ do
          begin
          AddChoiceField (SysMsg(000649){'Port        '},2,2,'XXXX',2,15,2,2,PrinterInfo,ComPort);
          AddYesNoField  (SysMsg(000644){'Flow Control'},3,2,''    ,3,15,3,               XonXoff);
          AddChoiceField (SysMsg(000645){'Baud Rate   '},4,2,'XXXX',4,15,4,2,PrinterInfo,Baud);
          AddChoiceField (SysMsg(000646){'Parity      '},5,2,'X'   ,5,15,5,2,PrinterInfo,Parity);
          AddChoiceField (SysMsg(000647){'Data Bits   '},6,2,'X'   ,6,15,6,2,PrinterInfo,DataBits);
          AddChoiceField (SysMsg(000648){'Stop Bits   '},7,2,'X'   ,7,15,7,2,PrinterInfo,StopBits);
          AddChoiceField (SysMsg(000650){'Driver      '},8,2,'XXXXXXXXXX'   ,8,15,8,2,PrinterInfo,DNum);
          end;
        ProcessEntryScreen;
        if ComPort  > 4 then
          begin
            IsParallel := True;
            Parallel := ComPort-4;
          end
        else
          IsParallel := False;
        Driver := PrinterList^[DNum];
        Dispose(PrinterList);
      end;

{----------------------------------------------------------------------}
{ Data handler methods for CharacterGenerator                          }

    Constructor CharacterGenerator.Init;
      begin
        SerialPort.Init;
      end;

    procedure CharacterGenerator.SetDefault;
      begin
        Installed := false;
        DevType   := OutputOnly;
        DevName := 'Character Gen.';
        ComPort   := 1;
        Baud      := B1200;
        DataBits  := 8;
        Parity    := 1;
        StopBits  := 1;
        DriverNum := B_CHYRON4;
      end;

    procedure CharacterGenerator.Edit;
      begin
        InitWSEntryScreen(30,5,CGHelp);
        with ER^ do
          begin
          AddChoiceField (SysMsg(000643){'Com Port    '},2,2,'XXXX',2,15,2,2,CGInfo,ComPort);
          AddYesNoField  (SysMsg(000644){'Flow Control'},3,2,''    ,3,15,3,          XonXoff);
          AddChoiceField (SysMsg(000645){'Baud Rate   '},4,2,'XXXX',4,15,4,2,CGInfo,Baud);
          AddChoiceField (SysMsg(000646){'Parity      '},5,2,'X'   ,5,15,5,2,CGInfo,Parity);
          AddChoiceField (SysMsg(000647){'Data Bits   '},6,2,'X'   ,6,15,6,2,CGInfo,DataBits);
          AddChoiceField (SysMsg(000648){'Stop Bits   '},7,2,'X'   ,7,15,7,2,CGInfo,StopBits);
          AddChoiceField (SysMsg(000650){'Driver      '},8,2,'XXXXXXXXXX',8,15,8,2,CGInfo,DriverNum);
          end;
        ProcessEntryScreen;
        Driver := CGDrivers[DriverNum];
        DevName := CGDrivers[DriverNum];
      end;

{----------------------------------------------------------------------}
{ Data handler methods for VideoAdapter                                }

    Constructor VideoAdapter.Init;
      begin
        Device.Init;
      end;

    procedure VideoAdapter.SetDefault;
      begin
        Installed := false;
        DevType := InputOnly;
      end;

    procedure VideoAdapter.Edit;
      begin
        Device.Edit;
      end;

{----------------------------------------------------------------------}
{ Data handler methods for VideoSource                                 }

    Constructor VideoSource.Init;
      begin
        Device.Init;
      end;

    procedure VideoSource.SetDefault;
      begin
        Installed := false;
        DevType := InputOnly;
      end;

    procedure VideoSource.Edit;
      begin
        Device.Edit;
      end;

{----------------------------------------------------------------------}
Function Install(Title: TitleString;var Stat: boolean): integer;
  var Status: integer;
  begin
    Menu^[1] := SysMsg(000651){'Install'};
    Menu^[2] := SysMsg(000652){'DeInstall'};
    Menu^[3] := SysMsg(000653){'Edit'};
    Status :=  AskUser(StartX-10,StartY,
                       SysMsg(000654){'Select Action'},
                       TITLE,               { as for Dialog }
                       White_Scheme,          { main colors }
                       Blue,                  { Title background }
                       Brown,                 { Box background }
                       LightBlue,             { First letter }
                       Blue,                  { Remaining letters }
                       3,                     { Number of items }
                       Menu^);
    Install := Status;
    if Status <> 0 then
      Stat := Status in [1,3];
  end;

{----------------------------------------------------------------------}
{ Edit a Device, VMT will point to appropriate object                  }

  Procedure EditDevice(var Dev: Device);
    begin
      if Install(SysMsg(000655){'DEVICE'},Dev.Installed) = 1 then
        begin
          Dev.SetDefault;
          Dev.Installed := true;
        end;
      if Dev.Installed then
        Dev.Edit;
    end;

{----------------------------------------------------------------------}
{ Edit information for this workstation                                }

  Procedure EditWorkstationInfo(var WS: WSConfig);
  var Done: boolean;
      ID: integer;
  begin
    InitMainEntryScreen;
    Done := false;
    Changed := false;
    While not Done do
      begin
        EM^.Process;
        HideMouse;
        case EM^.GetLastCommand of
          ccUser1   : begin
                        Case EM^.GetCurrentID of
                          1 : EditDevice(WS.Modem);
                          2 : EditDevice(WS.Printer);
                          3 : EditDevice(WS.CG);
                          4 : EditDevice(WS.Video);
                          5 : EditDevice(WS.Source);
                          end;
                      end;
          ccDone,
          ccQuit    : Done := true;
          end;
        ClrScr;
      end;
    PutWorkstationInfo(WS);

    Dispose(EM,Done);
    end;

{----------------------------------------------------------------------}
{ Select a workstation for editing                                     }

  Procedure SelectWorkstation;
    Type
        WSListType = Array[1..100] of BigString;
    var WSR : ^WsConfig;
        I   : integer;
        WSList : ^WSListType;
    begin
      New(WSR);
      New(WSList);
      {$I-}
      Assign(WsFile,NEN^.SysDir+'\'+WsFilename);
      Reset(WsFile);
      if IoResult <> 0 then
        begin
          Dispose(WSR);
          Dispose(WSList);
          exit;
        end;
      I := 0;
      While not EOF(WsFile) do
        begin
          Read(WsFile,WSR^);
          Inc(I);
          WSList^[I] := WSR^.Name;
        end;
      if I = 0 then
        begin
          Close(WsFile);
          if Dialog(SysMsg(000656){'No Workstation Records'},'',Green,'OK','', '') = 0 then;
          Dispose(WSR);
          Dispose(WSList);
          exit;
        end;
      OpenMenu(10,6,50,18,WSList^,I,30,Sort,'',SysMsg(000657){'WorkStations'},Red_Scheme,I);
      While not EscapePressed do
        begin
          I := GetMenu;
          if I > 0 then
            begin
              Seek(WsFile,I-1);
              Read(WsFile,WSR^);
              WSR^.Modem.Init;
              WSR^.Printer.Init;
              WSR^.CG.Init;
              WSR^.Video.Init;
              WSR^.Source.Init;
              EditWorkstationInfo(WSR^);
            end;
        end;
      CloseWindow;
      Close(WsFile);
      Dispose(WSR);
      Dispose(WSList);

    end;

{----------------------------------------------------------------------}
{ Add a new Workstation                                                }

  Procedure AddWorkstation;
    var
      WSR : WSConfigPtr;
    begin
      New(WSR);
      WSR^ := WS^;
      WS^.Modem.Init;
      WS^.Printer.Init;
      WS^.CG.Init;
      WS^.Video.Init;
      WS^.Source.Init;
      WSDefault;
      WS^.ID := WSID;
      EditWorkstationInfo(WS^);
      {$I-}
      Assign(WsFile,NEN^.SysDir+'\'+WsFilename);
      Reset(WsFile);
      if IoResult <> 0 then
        begin
          Seek(WsFile,FileSize(WsFile));
          Write(WsFile,WSR^);
        end;
      Close(WsFile);
      WS^ := WSR^;
      Dispose(WSR);
    end;

{----------------------------------------------------------------------}
Procedure PickDriver(DevType: InOutType; var Driver: NameStr);
  var I: integer;
      DName : NameStr;
  begin
    I := 0;
    Driver := '';
    with WS^ do
      begin
        if Modem.MatchDevice(DevType,DName) then
          begin
            inc(I);
            Menu^[I] := Dname;
          end;
        if Printer.MatchDevice(DevType,DName) then
          begin
            inc(I);
            Menu^[I] := Dname;
          end;
        if CG.MatchDevice(DevType,DName) then
          begin
            inc(I);
            Menu^[I] := Dname;
          end;
        if Video.MatchDevice(DevType,DName) then
          begin
            inc(I);
            Menu^[I] := Dname;
          end;
        if Source.MatchDevice(DevType,DName) then
          begin
            inc(I);
            Menu^[I] := Dname;
          end;
      end;
    if I = 0 then exit;
    OpenMenu(20,8,55,14,Menu^,I,30,Sort,'','Select Device',Copyright_Scheme,I);
    I := GetMenu;
    CloseWindow;
    if I > 0 then
      GetMenuString(I,Driver);
  end;

{----------------------------------------------------------------------}
{ Maintain workstation File                                            }

  Procedure MaintainWorkstations;
    var I: integer;
    begin
      Menu^[1] := SysMsg(000658){'Edit Workstations'};
      Menu^[2] := SysMsg(000659){'Add  Workstation'};
      Menu^[3] := SysMsg(000660){'Quit'};
      OpenMenu(10,5,40,10,Menu^,3,18,NoSort,'',SysMsg(661),Orange_Scheme,I);
      While not EscapePressed do
        begin
          I := GetMenu;
          Case I of
              1 : SelectWorkstation;
              2 : AddWorkstation;
              3 : ForceEscape;
            end;
        end;
      CloseWindow;
    end;

End.
