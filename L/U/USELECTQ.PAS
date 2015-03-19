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
{$A-,V-,F+,O+}
{---------------------------------------------------------}
{ (C)1991 NewsMaker Systems                               }
{ SAA Dialog box Select queue                             }
{---------------------------------------------------------}

Unit USelectQ;

interface

Uses Dos,UMsg,
     OpCrt,OpString,OpRoot,OpCmd,OpFrame,OpWindow,OpCtrl,OpDialog,
     OpField,OpFedit,OpMemo,OpEditor,OpDrag,OpMouse,OpCol16,OpPick,OpDir,
     QNovell,QGlobal,QHdrRec,QSignin,OpKey,QScreen,OpInline,FDialog,
     UGlobal,UColors,UWindow,UKey,UIpxSpx,UDialog;

  Procedure ChooseQueue(var SelectedQueue: DirStr; AllQs: boolean;
                        var Escape: boolean; HighlightCurrentQ: boolean);

implementation

Type
  QListType = Array[1..100] of PAllowedQueueList;
  PQListType = ^QListType;

Var
  WireQList : PQListType;
  ShowQList : PQListType;
  RestQList : PQListType;
  Queue     : DirStr;
  Net       : NameStr;
  NetTemp   : NameStr;
  FDB       : DialogBoxPtr;

Const
  idWire = 1;
  idShow = 2;
  idRest = 3;

  LeftWindowFrame    : FrameArray = 'ÚÀÂÁÄÄ³³';
  MiddleWindowFrame  : FrameArray = 'ÄÄÂÁÄÄ ³';
  RightWindowFrame   : FrameArray = 'ÄÄ¿ÙÄÄ ³';

  Procedure SetQueueNameAndNet(QList: PAllowedQueueList;
                               Mode : pkMode;
                               var IString: String);
    var I: integer;
    begin
      Queue := QList^.AllowedQueueName;
      if Pos('@',Istring) > 0 then
        Istring := ExtractWord(1,Istring,[' ','@']);
      if Pos('@',Queue) > 0 then
        begin
          I := Pos('@',Queue);
          Net := StUpcase(Trim(Copy(Queue,I+1,Length(Queue))));
          Queue := Trim(Copy(Queue,1,I-1));
        end
      else
        begin
          Net := 'LOCAL';
        end;
      FDB^.DrawField(0);
      FDB^.DrawField(1);
    end;

  Procedure DressString(QList: PAllowedQueueList;
                        var IString: String);
    var Queue: DirStr;
        I : integer;
        S : String[1];
    begin
      Queue := QList^.AllowedQueueName;
      I := Pos('@',QList^.AllowedQueueName);
      if I = 0 then
        NetTemp := 'LOCAL'
      else
        NetTemp := StUpcase(Trim(Copy
                   (Queue,I+1,Length(Queue))));
      if (NetTemp = 'LOCAL') then
        Istring := ^C+Istring
      else
        Istring := ^B+Istring;
      Istring := Copy(IString,1,2)+^A+Copy(Istring,3,Length(IString));
    end;

  Procedure SortQList(var QList: PQListType; QCount: word);
    var RootElement, CurrentElement: word;
        RootString,  CurrentString: SlugSt;
        Swap : PAllowedQueueList;
    begin
      for RootElement := 1 to QCount-1 do
        for CurrentElement := RootElement+1 to QCount do
          begin
            RootString := QList^[RootElement]^.Description;
            if RootString = '' then
              RootString := QList^[RootElement]^.AllowedQueueName;
            CurrentString := QList^[CurrentElement]^.Description;
            if CurrentString = '' then
              CurrentString := QList^[CurrentElement]^.AllowedQueueName;
          if CompUCString(RootString,CurrentString) = Greater then
            begin
              Swap := QList^[CurrentElement];
              QList^[CurrentElement] := QList^[RootElement];
              QList^[RootElement] := Swap;
            end;
          end;
    end;

  Procedure WireSupplyString(Item: word; Mode: pkMode;
                             var IType: pkItemType;
                             var IString: String;
                             PickPtr: PickListPtr);
    var CurCol: byte;
        I : integer;
    begin
      IType := pkNormal;
      with PickPtr^ do
        Case Mode of
            pkDisplay  : begin  { pretty, with flexwrite chars }
                           if WireQList^[Item]^.Description <> '' then
                             IString := WireQList^[Item]^.Description
                           else
                             IString := WireQList^[Item]^.AllowedQueueName;
                         end;
            pkSearch   : begin  { no extra characters }
                           if WireQList^[Item]^.Description <> '' then
                             IString := WireQList^[Item]^.Description
                           else
                             IString := WireQList^[Item]^.AllowedQueueName;
                         end;
            pkGetType  : begin
                           exit;
                         end;
          end;
      if PickPtr^.pkChoice = Item then
        SetQueueNameAndNet(WireQList^[Item], Mode, IString)
      else
        if Mode = pkDisplay then
          DressString(WireQList^[Item], IString);
    end;

  Procedure ShowSupplyString(Item: word; Mode: pkMode;
                             var IType: pkItemType;
                             var IString: String;
                             PickPtr: PickListPtr);
    var CurCol: byte;
        I : integer;
    begin
      IType := pkNormal;
      with PickPtr^ do
        Case Mode of
            pkDisplay  : begin  { pretty, with flexwrite chars }
                           if ShowQList^[Item]^.Description <> '' then
                             IString := ShowQList^[Item]^.Description
                           else
                             IString := ShowQList^[Item]^.AllowedQueueName;
                         end;
            pkSearch   : begin  { no extra characters }
                           if ShowQList^[Item]^.Description <> '' then
                             IString := ShowQList^[Item]^.Description
                           else
                             IString := ShowQList^[Item]^.AllowedQueueName;
                         end;
            pkGetType  : begin
                         end;
          end;
      if PickPtr^.pkChoice = Item then
        SetQueueNameAndNet(ShowQList^[Item], Mode, IString)
      else
        if Mode = pkDisplay then
          DressString(ShowQList^[Item], IString);
    end;

  Procedure RestSupplyString(Item: word; Mode: pkMode;
                             var IType: pkItemType;
                             var IString: String;
                             PickPtr: PickListPtr);
    var CurCol: byte;
        I : integer;
    begin
      IType := pkNormal;
      with PickPtr^ do
        Case Mode of
            pkDisplay  : begin  { pretty, with flexwrite chars }
                           if RestQList^[Item]^.Description <> '' then
                             IString := RestQList^[Item]^.Description
                           else
                             IString := RestQList^[Item]^.AllowedQueueName;
                         end;
            pkSearch   : begin  { no extra characters }
                           if RestQList^[Item]^.Description <> '' then
                             IString := RestQList^[Item]^.Description
                           else
                             IString := RestQList^[Item]^.AllowedQueueName;
                         end;
            pkGetType  : begin
                         end;
          end;
      if PickPtr^.pkChoice = Item then
        SetQueueNameAndNet(RestQList^[Item], Mode, IString)
      else
        if Mode = pkDisplay then
          DressString(RestQList^[Item], IString);
    end;

  Procedure ChooseQueue(var SelectedQueue: DirStr; AllQs: boolean;
                        var Escape: boolean; HighlightCurrentQ: boolean);
    var
      WireList : PickListPtr;
      ShowList : PickListPtr;
      RestList : PickListPtr;
      DCP      : DragProcessorPtr;
      PCP      : DragProcessorPtr;
      QMsg     : String[30];
      Status   : word;
      Finished : boolean;
      WorkQueue: PAllowedQueueList;
      WireQueueCount: word;
      ShowQueueCount: word;
      RestQueueCount: word;
      Flex : FlexAttrs;

      function InitDialogBox : Word;
        {-Initialize dialog box}
      const
        WinOptions = wBordered+wClear+wUserContents;
      begin
         New(FDB,InitCustom(
            8, 5,73,22,
            NENColorSet,     {main color set}
            WinOptions,      {window options}
            NENDialogSet     {dialog box-specific colors}
            ));
           if FDB = nil then begin
              InitDialogBox := InitStatus;
              Exit;
            end;
         New(DCP,Init(@DialogKeySet, DialogKeyMax));
         CustomizeCommandProcessor(DCP^);
         FDB^.SetCommandProcessor(DCP^);
         If AllQs Then
            QMsg := SysMsg(000333){' Select Destination Queue '} Else
            QMsg := SysMsg(000334){' Please Select New Queue '};

         CustomizeWindow(FDB^, QMsg, Length(QMsg)+4);

         InitDialogBox := FDB^.RawError;
      end;

    begin
      {select alternate scroll bar arrows}
      DefArrows := TriangleArrows;

      Gray_Scheme;

      {initialize dialog box}
      Status := InitDialogBox;
      if Status <> 0 then begin
        WriteLn('Error initializing dialog box: ', Status);
        exit;
      end;

    {set field/control options}
    FDB^.dgFieldOptionsOn(efClearFirstChar);
    FDB^.dgControlOptionsOff(dcButtonBox);

    Queue := '';
    Net := 'Local';

    New(PCP,Init(@PickKeySet, PickKeyMax));
    CustomizeCommandProcessor(PCP^);

    New(WireQList);
    New(ShowQList);
    New(RestQList);

    WireQueueCount := 0;
    ShowQueueCount := 0;
    RestQueueCount := 0;

    if AllQs then
      WorkQueue := AllowedQueues
    else
      WorkQueue := AllKnownQueues;

    While WorkQueue <> nil do
      begin
        Case WorkQueue^.QueueCategory of
          0     : begin
                    inc(WireQueueCount);
                    WireQList^[WireQueueCount] := WorkQueue;
                  end;
          2     : begin
                    inc(ShowQueueCount);
                    ShowQList^[ShowQueueCount] := WorkQueue;
                  end;
          1,3..5: begin
                    inc(RestQueueCount);
                    RestQList^[RestQueueCount] := WorkQueue;
                  end;
          end;
        WorkQueue := WorkQueue^.FwdLink;
      end;

    SortQList(WireQList, WireQueueCount);
    SortQList(ShowQList, ShowQueueCount);
    SortQList(RestQList, RestQueueCount);

    Black_Scheme;

    NENColorSet.ScrollBarColor := LtGrayOnBlue;
    NENColorSet.SliderColor    := LtCyanOnWhite;
    NENColorSet.HotSpotColor   := LtGreenOnBlack;
    NENColorSet.AltItemColor   := LtBlueOnBlack;
    NENColorSet.AltSelItemColor:= BlackOnLtCyan;

    New(WireList,
        InitDeluxe(5,5,24,15,NENColorset,
                   wClear or wUserContents or wNoCoversBuffer or
                   wBordered,
                   20,
                   WireQueueCount,
                   WireSupplyString,
                   PickVertical,
                   SingleChoice,
                   DefPickOptions-PkMinHeight));

    WireList^.SetCommandProcessor(PCP^);

    Flex[0] := WhiteOnBlack;      { Normal }
    Flex[1] := WhiteOnBlack;      { ^A     }
    Flex[2] := LtCyanOnBlack;     { ^B     }
    Flex[3] := LtGreenOnBlack;    { ^C     }

    AddScrollBars(WireList^,False);
    with WireList^ do
      begin
        wFrame.SetFrameType(LeftWindowFrame);
        pkOptionsOff(pkMinHeight);
        SetSearchMode(PickAltStringSearch);
        pkOptionsOn(pkAltCurrent+pkProcessZero);
        pkOptionsOff(pkDrawActive);
        SetPickFlex(pkNormal, True,  Flex, Flex);
        SetPickFlex(pkNormal, False,  Flex, Flex);
      end;

    New(ShowList,
        InitDeluxe(5,5,24,15,NENColorset,
                   wClear or wUserContents or wNoCoversBuffer or
                   wBordered,
                   20,
                   ShowQueueCount,
                   ShowSupplyString,
                   PickVertical,
                   SingleChoice,
                   DefPickOptions-PkMinHeight));

    ShowList^.SetCommandProcessor(PCP^);

    AddScrollBars(ShowList^,False);
    with ShowList^ do
      begin
        wFrame.SetFrameType(MiddleWindowFrame);
        pkOptionsOff(pkMinHeight);
        SetSearchMode(PickAltStringSearch);
        pkOptionsOn(pkAltCurrent+pkProcessZero);
        pkOptionsOff(pkDrawActive);
        SetPickFlex(pkNormal, True,   Flex, Flex);
        SetPickFlex(pkNormal, False,  Flex, Flex);
      end;

    New(RestList,
        InitDeluxe(5,5,24,15,NENColorset,
                   wClear or wUserContents or wNoCoversBuffer or
                   wBordered,
                   20,
                   RestQueueCount,
                   RestSupplyString,
                   PickVertical,
                   SingleChoice,
                   DefPickOptions-PkMinHeight));

    RestList^.SetCommandProcessor(PCP^);

    AddScrollBars(RestList^,False);
    with RestList^ do
      begin
        wFrame.SetFrameType(RightWindowFrame);
        pkOptionsOff(pkMinHeight);
        SetSearchMode(PickAltStringSearch);
        pkOptionsOn(pkAltCurrent+pkProcessZero);
        pkOptionsOff(pkDrawActive);
        SetPickFlex(pkNormal, True,   Flex, Flex);
        SetPickFlex(pkNormal, False,  Flex, Flex);
      end;

    with FDB^ do
      begin
        dgSecFieldOptionsOn(sefSwitchCommands);
        dgFieldOptionsOn(efProtected);
        AddSimpleEditControl('&Queue: ', 2,  2, 'X',
                                         2,  10,
                                         8, 8,4, Queue);
        AddSimpleEditControl('&Net: ', 2,  19, 'X',
                                       2,  24,
                                       8, 8,5, Net);
        dgFieldOptionsOff(efProtected);
        AddWindowControl('&Wires',4, 2,  5, 1,  idWire,  ccSelect, WireList^);
        AddWindowControl('&Shows',4, 24, 5, 23, idShow,  ccSelect, ShowList^);
        AddWindowControl('&Other',4, 46, 5, 45, idRest,  ccSelect, RestList^);

        AddTextFieldCustom(' Key: ' ,   18,  1, LtGrayOnBlack,  $07);
        AddTextFieldCustom('NETWORK             ', 18,  7, Flex[2], $07);
        AddTextFieldCustom('LOCAL             ', 18, 17, Flex[3], $07);
        AddTextFieldCustom('SELECTED', 18, 25, NENColorSet.AltSelItemColor, $07);
        AddTextFieldCustom('    DEFAULT                       ',
                                                 18, 33, NENColorSet.AltItemColor,  $07);

        AddPushButton('&OK',      2,  46, 8, 0, ccSelect, True);
        AddPushButton(' &CANCEL ',2,  56, 8, 0, ccQuit, False);
      end;

    Finished := false;
    While not Finished do
      begin
        FDB^.Process;
        Case FDB^.GetLastCommand of
            ccMouseDown,
            ccMouseSel :
              {did user click on the hot spot for closing?}
              if HandleMousePress(FDB^) = hsRegion3 then begin
                ClearMouseEvents;
                Finished := True;
              end;
            ccSelect :   begin
                           Finished := true;
                           SelectedQueue := Queue+' @ '+Net;
                           Escape := False;
                         end;
            ccQuit   :   begin
                           Finished := true;
                           Queue := '';
                           SelectedQueue := Queue;
                           Escape := True;
                         end;
        end;
      end;

    FDB^.Erase;
    FDB^.RemoveChild(WireList);
    Dispose(WireList, Done);
    FDB^.RemoveChild(ShowList);
    Dispose(ShowList, Done);
    FDB^.RemoveChild(RestList);
    Dispose(RestList, Done);
    Dispose(FDB,Done);
    Dispose(DCP,Done);
    Dispose(PCP,Done);

    Dispose(WireQList);
    Dispose(ShowQList);
    Dispose(RestQList);

    end;

End.
