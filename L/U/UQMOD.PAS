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
Unit UQmod;

interface

uses Dos,OpCrt, QDoMenu, QScreen, QCmddsp,UMsg,
     QGlobal,QHdrRec,QDrives,
     UGlobal,ULib,UWindow,UMenu,UColors,
     OpCol16,OpFrame,OpWindow,OpCmd,OpEntry,OpString,OpDate;

Procedure SetRundownParameters (Var NextQueue : QueueName;
                                Var UserToNotify : UserName;
                                Var RouteToPrinter : Byte);

Procedure SetShowTime(var TimeOfShow, EndTimeOfShow,
                          PriorityTime, UrgentTime: LongInt;
                      var DaysOfTheWeek: byte);

Procedure SetQParameters(var ScriptOrText : SNOptions;
                         var Form: FormNameString;
                         Var ArchiveQName : QueueName;
                         Var PageNumberMethod : Word;
                         Var DefaultStyle : StyleNameString;
                         Var MaximumNumberOfSlugs : Word;
                         Var RundownControl: RCOptions;
                         Var Description: SlugSt;
                         Var Category: byte;
                         Var DoRundownPageBreaks : PBOptions;
                         Var StartPageNumber : Word;
                         Var IcrSegNumberBy : Word);

implementation

var
  ESR : EntryScreenPtr;
  Quit: boolean;
  Days: Array[1..7] of boolean;
  HelpUp: word;
  QT, QType : Byte;
  PT, PType : Byte;
  CT, CType : Byte;
  QC, QCat  : byte;
  PBT, PBType: byte;

const
  DayMask : Array[1..7] of byte = (64,32,16,8,4,2,1);
  QTypes  : Array[0..3] of String[10] = (
            'DEFAULT','SCRIPT','TEXT','ASK');
  QCats   : Array[0..5] of String[10] = (
            'WIRE','USER','RUNDOWN','HILITE','ARCHIVE','ASSIGN');
  PTypes  : Array[0..6] of String[02] = (
            '00','01','02','03','04','05','06');
  CTypes  : Array[0..2] Of String[10] = (
            'PROMPTER','CAPTION','MANUAL');
  PBTypes : Array[0..3] Of String[11] = (
            'DEFAULT','CONTINUOUS', 'FORM FEED','FIT ON PAGE');
{----------------------------------------------------------------------}

Procedure ShowHelp(ESR: EntryScreenPtr);
  begin
    Case ESR^.GetCurrentID of
      0..3  : begin
                if HelpUp = 1 then exit;
                HelpUp := 1;
                PaintBox(43,9,65,12,Attr(DarkGray,LightBlue),' ');
                DrawWideBox(43,9,65,12,Attr(DarkGray,LightBlue));
                WriteStr(45,10,SysMsg(000938){'Enter Time as AM/PM'},Attr(DarkGray,White));
                WriteStr(45,11,SysMsg(000939){'e.g. 05:59:30 PM'},Attr(DarkGray,White));
              end;
      4..10 : begin
                if HelpUp = 2 then exit;
                HelpUp := 2;
                PaintBox(43,9,65,12,Attr(DarkGray,LightBlue),' ');
                DrawWideBox(43,9,65,12,Attr(DarkGray,LightBlue));
                WriteStr(45,10,SysMsg(000940){'Set Day to Y for Yes'},Attr(DarkGray,White));
                WriteStr(45,11,SysMsg(000941){'or         N for No'},Attr(DarkGray,White));
              end;
      end;
  end;

{----------------------------------------------------------------------}

Procedure RundownParamHelp(ESR: EntryScreenPtr);
  begin
    Case ESR^.GetCurrentID of
      0 :  WriteStr(22, 8,Pad('',34),Attr(Red,White));
      1 :  WriteStr(22, 8,Pad('',34),Attr(Red,White));
      2 :  WriteStr(22, 8,Pad('',34),Attr(Red,White));
    end;
  end;

{----------------------------------------------------------------------}


Procedure SetRundownParameters (Var NextQueue : QueueName;
                                Var UserToNotify : UserName;
                                Var RouteToPrinter : Byte);
  var I: integer;
      RouteToPrinterW : Word;
    Begin
    HelpUp := 0;

    Copyright_Scheme;
    with NENColorSet do
      begin
        FieldColor := WhiteOnBlue;
        SelFieldColor := WhiteOnMagenta;
        PromptColor := LtCyanOnBlue;
        SelPromptColor := LtCyanOnBlue;
      end;

    New(ESR,InitCustom(22,8,60,11,NENColorSet,DefWindowOptions or wBordered));
    CustomizeWindow(ESR^,' Queue Parameters ',20);


    if ESR = nil then exit;
    CustomizeCommandProcessor(EntryCommands);

    with ESR^,EntryCommands do
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
        AddCommand(ccUser0, 1, $011B, 0);   { F10 }
      end;

    with ESR^ do
      begin
        RouteToPrinterW := RouteToPrinter;
{        SetPreEditProc(RundownParamHelp);                                 }

        AddStringField(SysMsg(001992){'Next Queue       : '} ,2,2,'',2,21,8,2,NextQueue);
        AddStringField(SysMsg(001993){'User To Notify   : '} ,3,2,'',3,21,8,2,UserToNotify);
        AddWordField  (SysMsg(001994){'Route Printout To: '} ,4,2,'99',4,21,5,0,0,RouteToPrinterW);

        Draw;
      end;


    Quit := False;
    While not Quit do
      begin
        ESR^.Process;
        Case ESR^.GetLastCommand of
          ccQuit,
          ccUser0,
          ccDone    : Quit := True;
          end;
      end;

    Dispose(ESR,Done);
    HelpUp := 0;
    RouteToPrinter := RouteToPrinterW;
    End;


{----------------------------------------------------------------------}

Procedure SetShowTime(var TimeOfShow, EndTimeOfShow,
                          PriorityTime, UrgentTime: LongInt;
                      var DaysOfTheWeek: byte);
  var I: integer;
  begin
    HelpUp := 0;
    for I := 1 to 7 do
      Days[I] := (DaysOfTheWeek and DayMask[I] <> 0);

    Copyright_Scheme;
    with NENColorSet do
      begin
        FieldColor := WhiteOnBlue;
        SelFieldColor := WhiteOnMagenta;
        PromptColor := LtCyanOnBlue;
        SelPromptColor := LtCyanOnBlue;
      end;

    New(ESR,InitCustom(12,8,65,14,NENColorSet,DefWindowOptions or wBordered));
    CustomizeWindow(ESR^,' Show Time ',10);
    if ESR = nil then exit;
    CustomizeCommandProcessor(EntryCommands);

    with ESR^,EntryCommands do
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
        AddCommand(ccUser0, 1, $011B, 0);   { F10 }
      end;

    with ESR^ do
      begin
        SetPreEditProc(ShowHelp);
        AddTimeField(SysMsg(000942){'Start    Time: '} ,2,2,SysMsg(000943){'hh:mm:ss te'},2,19, 1,MinTime,MaxTime,
                                                              TimeOfShow);
        AddTimeField(SysMsg(000944){'End      Time: '} ,3,2,SysMsg(000943){'hh:mm:ss te'},3,19, 2,MinTime,MaxTime,
                                                              EndTimeOfShow);
        AddTimeField(SysMsg(000945){'Priority Time: '} ,4,2,SysMsg(000943){'hh:mm:ss te'},4,19, 3,MinTime,MaxTime,
                                                              PriorityTime);
        AddTimeField(SysMsg(000946){'Urgent   Time: '} ,5,2,SysMsg(000943){'hh:mm:ss te'},5,19, 4,MinTime,MaxTime,
                                                              UrgentTime);
        AddYesNoField(SysMsg(000947){'Sun: '},7, 2,'',7, 7,5,Days[1]);
        AddYesNoField(SysMsg(000948){'Mon: '},7, 9,'',7,14,6,Days[2]);
        AddYesNoField(SysMsg(000949){'Tue: '},7,16,'',7,21,7,Days[3]);
        AddYesNoField(SysMsg(000950){'Wed: '},7,23,'',7,28,8,Days[4]);
        AddYesNoField(SysMsg(000951){'Thu: '},7,30,'',7,35,9,Days[5]);
        AddYesNoField(SysMsg(000952){'Fri: '},7,37,'',7,42,10,Days[6]);
        AddYesNoField(SysMsg(000953){'Sat: '},7,44,'',7,49,11,Days[7]);

        Draw;
        WriteStr(12, 8,Pad(SysMsg(000954){' Show Times:'},54),Attr(Blue,Yellow));
        WriteStr(12,13,Pad(SysMsg(000955){' Days of week that show airs:'},54),Attr(Blue,Yellow));
      end;


    Quit := False;
    While not Quit do
      begin
        ESR^.Process;
        Case ESR^.GetLastCommand of
          ccQuit,
          ccUser0,
          ccDone    : Quit := True;
          end;
      end;

    DaysOfTheWeek := 0;
    for I := 1 to 7 do
      if Days[I] then
        DaysOfTheWeek := DaysOfTheWeek or DayMask[I];

    Dispose(ESR,Done);
    HelpUp := 0;
  end;

{----------------------------------------------------------------------}

Procedure QInc(var Value; ID: word; Factor: integer; var S: String);
  var B: byte absolute Value;
  begin
    Case Factor of
       1 : if B < 3 then inc(B) else B := 0;
      -1 : if B > 0 then dec(B) else B := 3;
      end;
    S := QTypes[B];
    QType := B;
  end;

{----------------------------------------------------------------------}

Procedure QCInc(var Value; ID: word; Factor: integer; var S: String);
  var B: byte absolute Value;
  begin
    Case Factor of
       1 : if B < 5 then inc(B) else B := 0;
      -1 : if B > 0 then dec(B) else B := 5;
      end;
    S := QCats[B];
    QCat := B;
  end;

{----------------------------------------------------------------------}

Procedure CInc(var Value; ID: word; Factor: integer; var S: String);
  var B: byte absolute Value;
  begin
    Case Factor of
       1 : if B < 2 then inc(B) else B := 0;
      -1 : if B > 0 then dec(B) else B := 2;
      end;
    S := CTypes[B];
    QCat := B;
  end;

{----------------------------------------------------------------------}
Procedure PInc(var Value; ID: word; Factor: integer; var S: String);
  var B: byte absolute Value;
  begin
    Case Factor of
       1 : if B < 6 then inc(B) else B := 0;
      -1 : if B > 0 then dec(B) else B := 6;
      end;
    S := PTypes[B];
    PType := B;
  end;

{----------------------------------------------------------------------}
Procedure PBInc(var Value; ID: word; Factor: integer; var S: String);
  var B: byte absolute Value;
  begin
    Case Factor of
       1 : if B < 3 then inc(B) else B := 0;
      -1 : if B > 0 then dec(B) else B := 3;
      end;
    S := PBTypes[B];
    PBType := B;
  end;
{----------------------------------------------------------------------}


Procedure ParamHelp(ESR: EntryScreenPtr);
  begin
    Case ESR^.GetCurrentID of
      0 :  WriteStr(22, 8,Pad(SysMsg(000956){' Press F1 for List'},34),Attr(Red,White));
      1 :  WriteStr(22, 8,Pad(SysMsg(000956){' Press F1 for List'},34),Attr(Red,White));
      2 :  WriteStr(22, 8,Pad(SysMsg(000957){' Press SPACE for selections'},34),Attr(Red,White));
      3 :  WriteStr(22, 8,Pad(SysMsg(000957){' Press SPACE for selections'},34),Attr(Red,White));
      4 :  WriteStr(22, 8,Pad(SysMsg(000956){' Press F1 for List'},34),Attr(Red,White));
      5 :  WriteStr(22, 8,Pad('',34),Attr(Red,White));
      6 :  WriteStr(22, 8,Pad(SysMsg(000957){' Press SPACE for selections'},34),Attr(Red,White));
      7 :  WriteStr(22, 8,Pad('',34),Attr(Red,White));
      8 :  WriteStr(22, 8,Pad(SysMsg(000957){' Press SPACE for selections'},34),Attr(Red,White));
      9 :  WriteStr(22, 8,Pad(SysMsg(000957){' Press SPACE for selections'},34),Attr(Red,White));
     10 :  WriteStr(22, 8,Pad('',34),Attr(Red,White));
     11 :  WriteStr(22, 8,Pad('',34),Attr(Red,White));
    end;
  end;

{----------------------------------------------------------------------}

Procedure DoHelp(var Form: FormNameString;
                 var ArchiveQName : QueueName);
  var I,DirSize: integer;
        QMsg : AnyString;
        ItemSize : Integer;
        LongestEntry : Integer;
        WorkQueue : PAllowedQueueList;
        StartOffset : Integer;


  begin
    if ESR^.GetCurrentID = 0 then
       Begin
       ChangeDrive (Sys^.SysDrive);
       BuildDirectory(NEN^.FormsDir+'\*.GRP',True,AnyFile,Menu^,DirSize);
       ChangeDrive (CW^.QDrive);
       OpenMenu(32,10,62,20,Menu^,DirSize,8,Sort,'',SysMsg(000009){' Forms '},Yellow_Scheme,I);
       I := GetMenu;
       if I <> 0 then
         GetMenuString(I,Form);
       CloseWindow;
       End;

    if ESR^.GetCurrentID = 1 then
       Begin
       ChangeDrive (CW^.QDrive);

       GetDir (0,CurDir);
       StartOffset := 1;
       WorkQueue := AllKnownQueues;

       If WorkQueue <> Nil Then
          Begin
          DirSize := 1;
          While WorkQueue <> Nil Do
             Begin
             Menu^[DirSize] := WorkQueue^.AllowedQueueName;
             WorkQueue := WorkQueue^.FwdLink;
             If WorkQueue <> Nil Then
                Inc (DirSize);
             End;
          End
          Else
          Begin
          Exit;
          End;

       Sys^.CurrentDriveID := '1';
       ChangeDrive (CW^.QDrive);

       LongestEntry := 1;
       For I := 1 To DirSize Do
          If Length(Menu^[I]) > LongestEntry Then
             LongestEntry := Length(Menu^[I]);

       ItemSize := LongestEntry;
       MenuX1 := 3;
       MenuY1 := 8;
       MenuX2 := 77;
       MenuY2 := 22;
       ItemSize := LongestEntry;

       QMsg := SysMsg(000958){' Please Select Archive Queue '};
       DoMenu(0,DirSize,LongestEntry,QMsg,Parameter,Escape, StartOffset);

       If (Escape) Or (Parameter = '') Then
          Begin
          FinishMenu;
          ChangeDrive (CW^.QDrive);
          DisplayInsert (Insrt);
          Exit;
          End;
       FinishMenu;
       DisplayInsert (Insrt);
       ChangeDrive (CW^.QDrive);
       ArchiveQName := Parameter;
       End;

    if ESR^.GetCurrentID = 2 then
       Begin
       End;

  end;

{----------------------------------------------------------------------}

Procedure SetQParameters(var ScriptOrText : SNOptions;
                         var Form: FormNameString;
                         Var ArchiveQName : QueueName;
                         Var PageNumberMethod : Word;
                         Var DefaultStyle : StyleNameString;
                         Var MaximumNumberOfSlugs : Word;
                         Var RundownControl: RCOptions;
                         Var Description: SlugSt;
                         Var Category: byte;
                         Var DoRundownPageBreaks : PBOptions;
                         Var StartPageNumber : Word;
                         Var IcrSegNumberBy : Word);

Var MaxSlugs : String[5];
    IMax, IErr : Integer;
  begin
    White_Scheme;

    New(ESR,InitCustom(18,8,58,22,NENColorSet,DefWindowOptions or wBordered));
    CustomizeWindow(ESR^,' Queue Parameters ',20);
    if ESR = nil then exit;

    CustomizeCommandProcessor(EntryCommands);
    with ESR^,EntryCommands do
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
        AddCommand(ccUser0, 1, $011B, 0);   { F10 }
      end;

    with ESR^ do
      begin
        SetPreEditProc(ParamHelp);

        QT := Ord(ScriptOrText);
        QType := QT;
        QCat := Category;
        CT := Ord(RundownControl);
        if CT > 2 then
          CT := 0;
        CType := CT;
        if Length(Description) > 20 then
          Description := '';
        PT := Ord(PageNumberMethod);
        If PT > 6 Then
           PT := 0;
        PType := PT;
        PBT := Ord(DoRundownPageBreaks);
        if PBT > 3 then
          PBT := 0;
        PBType := PBT;
        AddStringField(SysMsg(000959){'Form       : '} ,2,2,'',2,15,8,2,Form);
        AddStringField(SysMsg(000960){'Archive Q  : '} ,3,2,'',3,15,8,2,ArchiveQName);
        AddChoiceField(SysMsg(000961){'File Format: '}, 4,2,'!!!!!!!',4,15,1,1,Qinc,QType);
        AddChoiceField(SysMsg(001958){'Page Method: '}, 5,2,'XX',5,15,1,1,PInc,PType);
        AddStringField(SysMsg(001954){'Style      : '} ,6,2,'',6,15,8,2,DefaultStyle);
        AddWordField  (SysMsg(001955){'Max # Slugs: '} ,7,2,'9999',7,15,5,0,0,MaximumNumberOfSlugs);
        AddChoiceField(SysMsg(001957){'Control by : '} ,8,2,'!!!!!!!!',8,15,1,1,CInc,CType);
        AddStringField(SysMsg(000760){'Description: '} ,9,2,'',9,15,20,2,Description);
        AddChoiceField(SysMsg(001959){'Desktop    : '},10,2,'!!!!!!!',10,15,5,1,QCinc,QCat);
        AddChoiceField(SysMsg(001970){'Breaks     : '},11,2,'!!!!!!!!!!!',11,15,5,1,
                                                       PBinc,PBType);
        AddWordField  (SysMsg(002000){'Start Page #:'},12,2,'9999',12,15,5,0,0,StartPageNumber);
        AddWordField  (SysMsg(002043){'Seg Icr By  :'},13,2,'999',13,15,5,0,0,IcrSegNumberBy);
        Draw;
      end;

    Quit := False;
    While not Quit do
      begin
        ESR^.Process;
        Case ESR^.GetLastCommand of
          ccQuit,
          ccUser0,
          ccDone    : Quit := True;
          ccUser1   : begin
                        DoHelp(Form,ArchiveQName);
                      end;
          end;
      end;

    ScriptOrText := SNOptions(QType);
    PageNumberMethod := PType;
    Val (MaxSlugs, IMax, IErr);
    If (IErr = 0) And (IMax < 255) Then
       MaximumNumberOfSlugs := IMax;
    If TrimTrail (MaxSlugs) = '' Then
       MaximumNumberOfSlugs := 0;
    Category := QCat;
    RundownControl := RCOptions(CType);
    DoRundownPageBreaks := PBOptions(PBType);

    Dispose(ESR,Done);
  end;


End.
