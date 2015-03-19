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
{.$D+}

{**********************************************************************}
{ (C) 1990 NewsMaker Systems                                           }
{**********************************************************************}

Unit UService;

interface

Uses Dos,UMsg,
     UGlobal,UColors,UWindow,UMenu,ULib,UCommLib,UKey,
     OpCrt,OpCol16,OpRoot,OpSelect,OpFrame,OpWindow,OpCmd,OpEntry,OpMouse,
     OpMenu,OpKey,OpField,
     Qinput;

Type
  Titlestring = String[20];
  ResultString= String[40];
  PhoneString = String[20];

  ServicePtr  = ^ServiceType;
  ServiceType = Record
      Title    : TitleString;
      Spare    : String[59];
      Number   : PhoneString;
      ComPort  : Word;
      Baud     : Word;
      Parity   : word;
      Databits : word;
      StopBits : word;
      XonXoff  : boolean;
      HostTag  : ResultString;
      Host     : ResultString;
      Connect  : ResultString;
      IDtag    : ResultString;
      ID       : ResultString;
      PassTag  : ResultString;
      Password : ResultString;
      PromptCh : ResultString;
      UserTag  : Array[1..5] of ResultString;
      UserSt   : Array[1..5] of ResultString;
      ExitTag  : ResultString;
      ExitSt   : ResultString;
      NoCarrier: ResultString;
      ExitSeq  : ResultString;
      Prompts  : word;
      UserTags : word;
      TermType : word;
      UpperCase: boolean;
      Pad      : String;    { 255 byte expansion area }
    end;

Const
  SFileName = 'SERVICE.DAT';

Var
  Service        : ServicePtr;
  CurrentService : word;
  TopMenu        : MenuPtr;

Const
  NumServices    : word = 0;
  ServiceOpen    : boolean = False;    { Service File is open }
  ServiceSet     : boolean = False;    { Service record has been primed }

Procedure SetupService(ID: word);            { Load specified Service  }
Procedure EditService(Var SV: ServiceType);  { Edit Service record     }
Procedure SelectService(VAR Num: word);      { Select from service list}
Procedure AddNewService;                     { Add a new service rec   }
Procedure CloseService;                      { Close Service file      }
Procedure BuildServiceMenu;                  { Build service Sub-menu  }
Procedure BlankService(Var SV: ServiceType); { Create empty service    }
Function  FindService(Name: TitleString): Word; { Find service by name }

implementation

Const
  OnHook = 'ATH0';

Var
  SFile: File of ServiceType;

{--------------------------------------------------------}

Procedure SetupService(ID: word);
  var I: integer;
  begin
    Service^.Prompts := 0;
    FillChar(Service,SizeOf(Service^),#0);
    if NumServices = 0 then
      begin
        Assign(Sfile,SFileName);
        Reset(Sfile);
      end;
    Seek(Sfile,ID-1);
    Read(SFile,Service^);
    Service^.NoCarrier := '+++'+OnHook;
    Service^.ExitSt := '~OFFLINE';
    Service^.UserTags := 0;
    For I := 1 to 4 do
      if Service^.UserTag[I] <> '' then
        inc(Service^.UserTags);
    CurrentService := ID-1;
    ServiceSet := true;
  end;

{--------------------------------------------------------}

Procedure BlankService(Var SV: ServiceType);
  begin
    FillChar(SV,SizeOf(Service^),#0);
    With SV do
      begin
        if ComPort  = 0 then ComPort  := COM1;
        if Baud     = 0 then baud     := B1200;
        if DataBits = 0 then Databits := Data8;
        if Parity   = 0 then Parity   := NoParity;
        if Stopbits = 0 then StopBits := Stop1;
        if TermType = 0 then TermType := VT100Mode;
        PromptCh := ' ';
      end;
    SV.NoCarrier := '+++'+OnHook;
    SV.ExitSt := '~OFFLINE';
  end;

{--------------------------------------------------------}

Procedure EditService(Var SV: ServiceType);
  var ER          : ScrollingEntryScreenPtr;
      Done        : boolean;
      ID          : integer;
      Temp        : boolean;
      Y2          : integer;
      Loop        : word;
  Const
      InColor  = BlackOnLtGray;
      OutColor = RedOnLtGray;
  begin
    ER := nil;
    Gray_Scheme;
    Temp := false;
    if SV.Title = SysMsg(000872){'**Temporary**'} then
      Temp := true;
    Y2 := 22;
    if Temp then Y2 := 8;
    Gray_Scheme;
    New(ER,InitCustom(12,3,68,Y2,NENColorSet,DefWindowOptions or wBordered));

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
        AddCommand(ccUser0, 1, $4400, 0);   { F10 }
        cpOptionsOn(cpEnableMouse);
        SetKeyPressedProc(Ukey.Keywaiting);
        SetGetKeyProc(UKey.GetKey);
        SetWrapMode(StopAtEdges);
      end;

    with ER^ do
      begin
        esFieldOptionsOn(efProtected);
        AddStringField (SysMsg(000873){'Title '} ,1,2,  ''    ,1,8,20,1,SV.Title);
        esFieldOptionsOff(efProtected);
        AddChoiceField (SysMsg(000874){'Port  '} ,1,30, 'XXXX',1,35,  2, 2,Multi,SV.ComPort);
        AddYesNoField  (SysMsg(000644){'Flow Control'},1,41,'',1,54  ,3,          SV.XonXoff);
        AddChoiceField (SysMsg(000875){'Baud  '} ,2,2,  'XXXX',2,8   ,4, 2,Multi,SV.Baud);
        AddChoiceField (SysMsg(000876){'Parity '},2,14, 'X'   ,2,21  ,5, 2,Multi,SV.Parity);
        AddChoiceField (SysMsg(000877){'Data '}  ,2,23, 'X'   ,2,28  ,6, 2,Multi,SV.DataBits);
        AddChoiceField (SysMsg(000878){'Stop '}  ,2,30, 'X'   ,2,35  ,7, 2,Multi,SV.StopBits);
        AddChoiceField (SysMsg(000879){'Term '}  ,2,39,'XXXXX',2,44  ,8 ,2,Multi,SV.TermType);
        AddStringField (SysMsg(000880){'TelNo'}  ,3,2,  ''    ,3,8,20,9         ,SV.Number);
        esFieldOptionsOff(efRequired);
        AddStringField (SysMsg(000270){'Prompt'} ,3,30,  'X'  ,3,37  ,10,1,   SV.PromptCh);
        AddYesNoField  (SysMsg(000881){'Upper Case'},3,39,'',     3,50  ,11,         SV.UpperCase);
        if not Temp then
          begin
          SetFieldAttr(OutColor, $07);
          AddStringField (SysMsg(000882){'Connect'}    ,4,2,  ''    ,4,10,40,14,SV.Connect);
          SetFieldAttr(InColor, $07);
          AddStringField (SysMsg(000883){'Exit'}    ,5,2,  ''    ,5,11,40,12,SV.ExitTag);
          SetFieldAttr(InColor, $07);
          AddStringField (SysMsg(000884){'Host In '}    ,6,2,  ''    ,6,11,40 ,13,SV.HostTag);
          SetFieldAttr(OutColor, $07);
          AddStringField (SysMsg(000885){'Host Out'}    ,7,2,  ''    ,7,11,40 ,14,SV.Host);
          SetFieldAttr(InColor, $07);
          AddStringField (SysMsg(000886){'ID In'} ,8,2,  ''    ,8,11,40  ,15,SV.IDTag);
          SetFieldAttr(OutColor, $07);
          AddStringField (SysMsg(000887){'ID Out'}    ,9,2,  ''    ,9,11,40, 16,SV.ID);
          SetFieldAttr(InColor, $07);
          SetPasswordChar('#');
          AddStringField (SysMsg(000888){'Pass In'} ,10,2, ''    ,10,11,40 ,17,SV.PassTag);
          SetFieldAttr(OutColor, $07);
          esFieldOptionsOn(efPasswordMode);
          AddStringField (SysMsg(000889){'Pass Out'} ,11,2, ''    ,11,11,40 ,17,SV.Password);
          esFieldOptionsOff(efPasswordMode);
          SetFieldAttr(InColor, $07);
          AddStringField ('In '    ,12,2, ''    ,12,11,40,19,SV.UserTag[1]);
          SetFieldAttr(OutColor, $07);
          AddStringField ('Out'    ,13,2, ''    ,13,11,40,20,SV.UserSt[1]);
          SetFieldAttr(InColor, $07);
          AddStringField ('In '    ,14,2, ''    ,14,11,40,21,SV.UserTag[2]);
          SetFieldAttr(OutColor, $07);
          AddStringField ('Out'    ,15,2, ''    ,15,11,40,22,SV.UserSt[2]);
          SetFieldAttr(InColor, $07);
          AddStringField ('In '    ,16,2, ''    ,16,11,40,23,SV.UserTag[3]);
          SetFieldAttr(OutColor, $07);
          AddStringField ('Out'    ,17,2, ''    ,17,11,40,24,SV.UserSt[3]);
          SetFieldAttr(InColor, $07);
          AddStringField ('In '    ,18,2, ''    ,18,11,40,25,SV.UserTag[4]);
          SetFieldAttr(OutColor, $07);
          AddStringField ('Out'    ,19,2, ''    ,19,11,40,26,SV.UserSt[4]);
          end;
      end;

    ER^.AllocateScreen;

    if ER^.GetLastError <> 0 then exit;

    Done := false;
    ID := 0;
    if Temp then
      ID := 8;
    Loop := 0;
    While not Done do
      begin
        if Loop > 3000 then Done := true;
        ER^.Process;
        HideMouse;
        case ER^.GetLastCommand of
          ccUser7   : begin
                      if ServiceOpen then
                        begin
                          if CurrentService <> $FFFF then
                            begin
                              Seek(SFile,CurrentService);
                              Write(Sfile,Service^);
                            end;
                        end
                      else
                        Done := True;
                      end;
          ccDone,
          ccQuit    : Done := true;
          ccNone    : Inc(Loop);
          end;
      end;

    Dispose(ER,Done);
  end;

{--------------------------------------------------------}

Procedure SelectService(VAR Num: word);
  var I: integer;
  begin
    if not ServiceOpen then
      begin
        Assign(Sfile,SFileName);
        {$I-}
        Reset(Sfile);
        if IoResult <> 0 then exit;
        {$I+}
      end;
    ServiceOpen := true;
    Seek(Sfile,0);
    NumServices := 0;
    While not EOF(Sfile) do
      begin
        Read(Sfile,Service^);
        inc(NumServices);
        UGlobal.Menu^[NumServices] := Service^.Title;
      end;
    SetBorderType(3);
    OpenMenu(23,5,39,17,UGlobal.Menu^,NumServices,20,Sort,'','',
             Gray_Scheme,I);
    Num := GetMenu;
    CloseWindow;
    SetBorderType(1);
  end;

{--------------------------------------------------------}

Function  FindService(Name: TitleString): Word;
  var I: integer;
  begin
    if not ServiceOpen then
      begin
        Assign(Sfile,SFileName);
        {$I-}
        Reset(Sfile);
        if IoResult <> 0 then exit;
        {$I+}
      end;
    ServiceOpen := true;
    Seek(Sfile,0);
    NumServices := 0;
    While not EOF(Sfile) do
      begin
        Read(Sfile,Service^);
        inc(NumServices);
        if Service^.Title = Name then
          begin
            FindService := NumServices;
            exit;
          end;
      end;
    FindService := 0;
  end;

{--------------------------------------------------------}

Procedure AddNewService;
  begin
    if not ServiceOpen then
      begin
        Assign(Sfile,SfileName);
        {$I-}
        Reset(Sfile);
        if IoResult <> 0 then
          ReWrite(Sfile);
      end;
    if IoResult = 0 then
      ServiceOpen := true;
    {$I-}
    FillChar(Service,SizeOf(Service^),#0);
    with Service^ do
      begin
        ComPort  := 1;
        Baud     := 2;
        Databits := 8;
        Stopbits := 1;
        Parity   := 1;
        TermType := 1;
      end;
    Seek(SFile,FileSize(SFile));
    Write(Sfile,Service^);
    inc(NumServices);
    SetupService(NumServices);
    CurrentService := NumServices;
    EditService(Service^);
  end;

{--------------------------------------------------------}

Procedure CloseService;
  begin
    if ServiceOpen then
      Close(Sfile);
    ServiceOpen := false;
    NumServices := 0;
  end;

{--------------------------------------------------------}

Procedure BuildServiceMenu;
  begin
    if not ServiceOpen then
      begin
        Assign(Sfile,SFileName);
        {$I-}
        Reset(SFile);
        if IoResult = 0 then
          ServiceOpen := true;
        {$I+}
      end;
    if ServiceOpen then
      begin
        NumServices := 0;
        Seek(Sfile,0);
        While not EOF(Sfile) do
          begin
            inc(NumServices);
            Read(SFile,Service^);
            TopMenu^.AddItem(Service^.Title,NumServices,1,21+NumServices);
          end;
      end;
    BlankService(Service^);
  end;

Begin
  New(Service);
End.
