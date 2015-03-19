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
{$A-,F+,V-,R-,S-,O+}
{.$D+}
{--------------------------------------------------------}
{ C) copyright 1988                                      }
{ UMENU Unit.                                            }
{ Forms part of the UWINDOW family.                      }
{ Provides a Windows and Menu operating environment      }
{ NEN version.                                           }
{--------------------------------------------------------}

{$DEFINE SCROLLBARS}

Unit UMENU;

interface

Uses DOS,UMsg,
     Qglobal,Qscreen,Qinput,QUptime,ULib,UKey,{UVscreen,}
     UColors,UWindow,UFkey,URLine,
     OpInline,
     OpString,
     OpConst,
     OpRoot,
     OpCrt,
     OpMouse,
     OpCmd,
     OpDrag,
     OpDialog,
     FDialog,
     OpDos,
     OpFrame,
     OpWindow,
     OpField,
     OpEdit,
     OpEditor,
     OpMenu,
     OpPick,
     OpDir,
     UGlobal;

Type
  WordString = String[80];

  NENMenuPtr = ^NENMenu;
  NENMenu = Object(PickList)
      List    : ListPtr;       { Items }
      Ref     : RefPtr;        { item # after sort }
      Size    : word;          { # of items }
      Choice  : word;          { Selected item number }
      Title   : TitleString;
      SupplyString : pkStringProc;
      ItemNames : FileOfLinesPtr;
      Comment : Stype;         { Sub heading text }
      CommentRow : byte;       { frame relative row }
      CommentCol : byte;       { frame relative Column }
      Sorted  : boolean;       { if menu sorted }
      SortAscending : boolean; { Sort direction }
      Sort1   : integer;       { Sort col 1 }
      Sort2   : integer;       { Sort Col 2 }
      aWidth  : word;          { Actual width of items }
      Memory  : word;          { Heap allocated for BigList }
      LastCmd : word;          { Last returned command }
      LastKey : word;          { Last returned key }
      Colors  : ColorSet;      { this menus colour scheme }
      PrevColors : ColorSet;   { Color scheme when called }
      Fill    : Char;
      Escape  : boolean;       { Escape Pressed }
      Quadrant: byte;
      MCP     : DragProcessorPtr;

      Constructor Init(Xm1,Ym1,Xm2,Ym2: integer;
                       Var MList;
                       MSize: integer;
                       Dsize: integer;
                       Sort:  boolean;
                       UserComment: BigString;
                       UserTitle: TitleString;
                       CScheme: ColorSetProc;
                       VAR Err: integer);
      Constructor InitFile(Xm1,Ym1,Xm2,Ym2: integer;
                           FName : PathStr;
                           Dsize: integer;
                           UserComment: BigString;
                           UserTitle: TitleString;
                           CScheme: ColorSetProc;
                           VAR Err: integer);
      procedure SortMenu;
      function  EscapePressed: boolean;
      procedure ForceEscape;
      procedure ClearEscape;
      procedure AddComment(UserComment: BigString;  Col, Row: byte);
      procedure UpdateContents; Virtual;
      destructor Done; virtual;
    end;

  MenuArray = Array[1..ScreenMax] of NENMenuPtr;

Var
  Menus : MenuArray absolute NENWindows;
  USupplyString : pkStringProc;


Function GetVmenu(Wnum:integer;Flist:string): integer;
Procedure OpenMenu(Xm1,Ym1,Xm2,Ym2: integer;
                   Var MList;
                   MSize: integer;
                   Dsize: integer;
                   Sort:  boolean;
                   Comment: BigString;
                   Title: TitleString;
                   CScheme: ColorSetProc;
                   VAR Err: integer);
Procedure OpenMenuFile(Xm1,Ym1,Xm2,Ym2: integer;
                       FName: PathStr;
                       Dsize: integer;
                       Comment: BigString;
                       Title: TitleString;
                       CScheme: ColorSetProc;
                       VAR Err: integer);
procedure SetupSort(order: boolean; Pos1,Pos2: integer);
Procedure SetFieldMode(OnOff: boolean);
Function GetMenu: integer;
Function EscapePressed: boolean;
Procedure ForceEscape;
Procedure ClearEscape;
Procedure ChangeMenuItem(I: integer;Item: BigString);
Procedure GetMenuXY(I: integer;var X,Y: word);
Procedure DeleteItem(Item: integer);
Procedure DeleteCurrentItem;
Procedure RedisplayCurrentItem;
Procedure TurnOffMenuHighlight;
Procedure ReDisplayMenu;
Procedure ScrollCurrentMenu(Next: boolean);
Procedure GetMenuString(Indx: integer;VAR Ret: Stype);
Procedure GetMenuIndex(Indx: integer;VAR IX: integer);
Procedure MoveSelection(item: integer);
Procedure MarkItemAsSelected;
Procedure BounceWindow(Speed: integer;DragMode: boolean);
Procedure WaitAndReadKey(Var Ch,Ch2: Char);
procedure SetMenuAction(p: pointer);
Procedure LoadMenuFromTextFile(X1,Y1,X2,Y2: byte;
                               Fname: PathStr;
                               Title: TitleString;
                               VAR ResultString: Anystring;
                               VAR Result: integer);
Procedure LoadMenuFromBigTextFile(X1,Y1,X2,Y2: byte;
                                  Fname: PathStr;
                                  Width : integer;
                                  Title: TitleString;
                                  VAR ResultString: Anystring;
                                  VAR Result: integer);
function GetLocalMenuCmd(var CW : CommandWindow; var Choice : Word) : Byte;
procedure EraseLocalMenu;
function PickStringSelect(P: PickListPtr): boolean;

Const VirtualMenu : boolean = False;  { if false, someone else is controlling }
                                     { The virtual screen }

implementation

Const
  SortOrder : boolean = true;
  Sort1     : integer = 1;
  Sort2     : integer = 99;
  ChildWinOptions = wClear+wUserContents+wNoCoversBuffer;

var
  LocalMenu : OpMenu.Menu;

{-------------------------------------------------------}
  procedure GoExternalFunc;
    {-Execute procedure pointed to by ProcedureFunc}
  inline($FF/$1E/>ProcedureFunc);    {CALL DWORD PTR [>ProcedureFunc]}

{-------------------------------------------------------}
  procedure SetMenuAction(p: pointer);
  begin
  ProcedureFunc := p;
  end;

{-------------------------------------------------------}
  function PickStringSearchExit(P : PickListPtr) : Boolean;
    {-String searching mode}
  var
    Ch : Char;
    SItem : Word;
    S : BigString;
  begin
    with P^ do begin
      PickStringSearchExit := False; {Can't exit pick by searching in this mode}
      Ch := Upcase(Char(cwKey));
      if Ch >= #32 then
        if Length(pkSearchStr) < pkMaxSearchLen then begin
          inc(pkSearchStr[0]);
          pkSearchStr[Length(pkSearchStr)] := Ch;
          {Update status header}
          pkUpdateSearch;
          SItem := pkChoice;
          If Length(PKSearchStr) = 1 Then
             SItem := 1;

          if pkScanForMatch(SItem) then begin
            {Set current choice to the match}
            S := StUpCase(GetItemString(SItem+1));
            if (SItem < pkItems) and
               (Copy(S,1,Length(pkSearchStr)) <> pkSearchStr) then
                 begin
                   PickStringSearchExit := True;
                   cwCmd := ccSelect;
                 end;
            pkSetCurrent(SItem, pkFirst, P);
            Exit;
          end;
        end;
      {Clear previous match, if any}
      pkResetSearchStr;
    end;
  end;

{-------------------------------------------------------}
  function GetItemName(Item: integer; ItemNames : FileOfLinesPtr): String;
  begin
    with ItemNames^ do
      begin
        GetItemName := '';
        SeekLine(Item);
        if RFError = 0 then
          GetItemName := LastLine;
      end;
  end;

{-------------------------------------------------------}
  Procedure MenuSupplyString(Item: word; Mode: pkMode;
                             var IType: pkItemType;
                             var IString: String;
                             PickPtr: PickListPtr);
    var CurCol: byte;
    begin
      IType := pkNormal;
      with NENMenuPtr(PickPtr)^ do
        Case Mode of
            pkDisplay  : begin  { pretty, with flexwrite chars }
                           if Item = GetLastChoice then
                             IString := ''+List^[Item]
                           else
                             IString := ' '+List^[Item]
                         end;
            pkSearch   : begin  { no extra characters }
                           IString := List^[Item];
                         end;
            pkGetType  : begin
                         end;
          end;
    end;

{-------------------------------------------------------}
  Procedure FileSupplyString(Item: word; Mode: pkMode;
                             var IType: pkItemType;
                             var IString: String;
                             PickPtr: PickListPtr);
    var CurCol: byte;
    begin
      IType := pkNormal;
      with NENMenuPtr(PickPtr)^ do
        Case Mode of
            pkDisplay  : begin  { pretty, with flexwrite chars }
                           if Item = GetLastChoice then
                             IString := ''+GetItemName(Item,ItemNames)
                           else
                             IString := ' '+GetItemName(Item,ItemNames)
                         end;
            pkSearch   : begin  { no extra characters }
                           IString := GetItemName(Item,ItemNames);
                         end;
            pkGetType  : begin
                         end;
          end;
    end;

{-------------------------------------------------------}
  function InitLocalMenu(var CW : CommandWindow; var Choice : Word) : Boolean;
    {-Initialize the basic local menu}
  Const
    SglSubWindowFrame    : FrameArray = #$C2+'À'+#$C2+'ÙÄÄ³³';
  begin
    InitLocalMenu := False;

    with LocalMenu do begin
      {initialize the menu}
      if not InitCustom(2, 2, 9, 9, NENColorSet,
                        DefWindowOptions or wBordered or wAltFrame, Vertical) then
        Exit;
{      CustomizeWindow(LocalMenu, '', 6);}
      wFrame.SetFrameType(CW.wFrame.frChars);

      {add menu items}
      AddItem('Close',            01, 1, 01);
      AddSeparator('Ã', 'Ä', '´', 02);
      AddItem('Move  ',    03, 1, 02);
      AddItem('Resize',    04, 1, 03);
      AddItem('Zoom   ',   05, 1, 04);
      AddSeparator('Ã', 'Ä', '´', 06);
      AddItem('Cut',              07, 1, 05);
      AddItem('Paste',            08, 1, 06);
      AddShadows(True, shBR, shSeeThru);
      ItemsDone;

      {is window zoomable/resizeable?}
      if not CW.wOptionsAreOn(wResizeable) then begin
        {don't allow resize or zoom}
        ProtectItem(3);
        ProtectItem(4);
      end;

      ProtectItem(5);
      ProtectItem(6);

      {move the window}
      MoveWindow(CW.wFrame.frXL+1, CW.wFrame.frYL-1);

      {check for errors}
      if ClassifyError(GetLastError) = etFatal then begin
        Done;
        Exit;
      end;

      with MenuCommands do
        begin
          cpOptionsOn(cpEnableMouse);
          SetKeypressedProc(Ukey.KeyWaiting);
          SetGetKeyProc(Ukey.GetKey);
        end;

      {display the menu}
      DefaultPath(Choice);
      Draw;

      {check for errors}
      if ClassifyError(GetLastError) = etFatal then
        Done
      else
        InitLocalMenu := True;
    end;
  end;

{-------------------------------------------------------}
  function GetLocalMenuCmd(var CW : CommandWindow; var Choice : Word) : Byte;
    {-Get next menu choice; initialize and draw menu if necessary}
  begin
    Choice := 0;
    {is the menu already on screen?}
    if (wStack.TopWindow <> @LocalMenu) then
      {initialize and display it}
      if not InitLocalMenu(CW, Choice) then begin
        GetLocalMenuCmd := ccError;
        Exit;
      end;

    with LocalMenu do begin
      {get the next menu command}
      Process;
      case GetLastCommand of
           ccMouseDown,
           ccMouseSel :
                      {did user click on the hot spot for closing?}
                      if HandleMousePress(CW) = hsRegion3 then begin
                        WaitForButtonUp;
                        ClearMouseEvents;
                      end;
        end;
      if GetLastCommand = ccSelect then
      Choice := MenuChoice;
      if GetLastCommand = ccQuit then
        Choice := 0;
      GetLocalMenuCmd := GetLastCommand;
    end;
  end;

{-------------------------------------------------------}
  procedure EraseLocalMenu;
    {-Erase LocalMenu}
  begin
    LocalMenu.Erase;
    LocalMenu.Done;
  end;

function PickStringSelect(P: PickListPtr): boolean;
  begin
    PickStringSelect := PickStringSearchExit(P);
  end;

{-------------------------------------------------------}
{ NENMENU Methods }

Constructor NENMenu.Init(Xm1,Ym1,Xm2,Ym2: integer;
                         Var MList;
                         MSize: integer;
                         Dsize: integer;
                         Sort:  boolean;
                         UserComment: BigString;
                         UserTitle: TitleString;
                         CScheme: ColorSetProc;
                         VAR Err: integer);

  Var Opts: LongInt;
      PickOpts : LongInt;
      I,Slen,xx2,yy2,Indent,VDent: integer;
      TotalWidth,MaxColumns: word;
      Orientation : pkGenlProc;
      MenuList : HugeList absolute Mlist;
      Y : byte;

  Begin
    PrevColors := NENColorSet;
    CScheme;    { activate color scheme }

    ItemNames := nil;

    HideMouse;
    if ym1+Msize+2 < Ym2 then
      YY2 := Ym1+Msize+3
    else
      YY2 := Ym2+1;
    if (FkeysUp) and (YY2 > 21) then
      YY2 := 21;
    XX2 := Xm2;

    if ((xx2-xm1+1) mod 2) <> 0 then
      inc(xx2);

    Memory := SizeOf(BigString) * Msize;
    GetMemCheck(List,Memory);
    if List = nil then
      begin
        exit;
      end;

    GetMemCheck(Ref,(Msize * 2));

    AWidth := 0;
    For I := 1 to Msize do
      begin
      List^[I] := '';
      List^[I] := Copy(MenuList[I],1,Dsize);
      Slen := Length(List^[I]);
      if Slen > aWidth then
        aWidth := Slen;
      Ref^[I] := I;
      end;

    Title := UserTitle;
    Comment := UserComment;
    CommentRow := 1;
    CommentCol := 1;
    Size := MSize;
    Escape := False;

    Orientation := PickVertical;
    if (xx2-xm1 > ((aWidth+2) * 2)) and ((yy2-ym1-4) <= Msize) and
       (MSize > 10) then
      begin
        Orientation := PickSnaking;
        Indent := 3;
      end
    else
      begin
{        xx2 := Xm1 + (aWidth+2) + 4;}
        Indent := ((xx2-xm1) - (aWidth)) div 2;
      end;
    VDent := 2;
    PickOpts := DefPickOptions or pkProcessZero;

    if not UData^.BorderOn then
      begin
        Indent := 0;
        VDent := 0;
        Orientation := PickSnaking;
        PickOpts := PickOpts xor pkMinHeight;
        yy2 := ym2+3;
      end;

    Opts := DefWindowOptions or wResizeable or wAltFrame;
    if UData^.BorderOn then Opts := Opts or wBordered;

    USupplyString := MenuSupplyString;
    SupplyString := USupplyString;

    InitDeluxe(xm1+Indent, ym1+VDent, xx2-Indent, yy2-VDent ,NENColorSet,
               Opts,
               aWidth+2,Msize,SupplyString,Orientation,SingleChoice,
               PickOpts);

    Fill := NENFillChar;
    Colors := NENColorSet;

    { figure optimum dimensions for outer frame }

    if xx2-xm1 < Length(Title)+10 then
      begin
        repeat
          if xm1 > 2 then
            dec(xm1);
          if xx2 < 78 then
            inc(xx2);
        until xx2-xm1 >= Length(Title)+10;
      end;

    Y := ym1+{pkItemRows}pkHeight+3;
    if FkeysUp then
      begin
        if Y > 21 then
          Y := 21;
      end
    else
      begin
        if Y > 23 then
          Y := 23;
      end;
    AdjustFrameCoords(xm1,ym1,xx2,Y);

    CustomizeWindow(Self,Title,6);

    AddScrollBars(Self, GetOrientation <> pkVertical);

    SetSearchMode(PickStringSelect);
    AddSearchHeader(7, heBL);

    SetPadSize(0,1);

    Y := 2;
    if NENFlag then
      Y := 3;
    if FkeysUp then
      begin
        SetPosLimits(1,Y,80,22);
        SetSizeLimits(1,Y,80,22);
      end
    else
      begin
        SetPosLimits(1,Y,80,25);
        SetSizeLimits(1,Y,80,25);
      end;

    OptimizeSize;

    New(MCP,Init(@PickKeySet, PickKeyMax));
    CustomizeCommandProcessor(MCP^);
    SetCommandProcessor(MCP^);

    with MCP^ do
      begin
        AddCommand(ccUser0 , 1,     OpKey.F1 , 0);
        AddCommand(ccUser1 , 1,     OpKey.F2 , 0);
        AddCommand(ccUser2 , 1,     OpKey.F3 , 0);
        AddCommand(ccUser3 , 1,     OpKey.F4 , 0);
        AddCommand(ccUser4 , 1,     OpKey.F5 , 0);
        AddCommand(ccUser5 , 1,     OpKey.F6 , 0);
        AddCommand(ccUser6 , 1,     OpKey.F7 , 0);
        AddCommand(ccUser7 , 1,     OpKey.F8 , 0);
        AddCommand(ccUser8 , 1,     OpKey.F9 , 0);
        AddCommand(ccUser9 , 1,     OpKey.F10, 0);
        AddCommand(ccToggle, 1,     OpKey.Space,0);
      end;

    Colors := NENColorSet;
    Fill := NENFillChar;

    Size := Msize;

    Sorted := Sort;
    Sort1 := Sort1;
    Sort2 := Sort2;
    if Sort2 > Dsize then
      Sort2 := Dsize;
    SortAscending := SortOrder;
    SortOrder := true;
    Sort1 := 1;
    Sort2 := 99;

    if Sorted then SortMenu;

    Draw;
    Select;


    ClearMouseEvents;

end;

{-------------------------------------------------------}
{ NENMENU Methods }

Constructor NENMenu.InitFile(Xm1,Ym1,Xm2,Ym2: integer;
                             FName : PathStr;
                             Dsize: integer;
                             UserComment: BigString;
                             UserTitle: TitleString;
                             CScheme: ColorSetProc;
                             VAR Err: integer);

  Var Opts: LongInt;
      PickOpts : LongInt;
      I,Slen,xx2,yy2,Indent,VDent: integer;
      TotalWidth,MaxColumns: word;
      Orientation : pkGenlProc;
      Y : byte;
      MSize : LongInt;

  Begin
    PrevColors := NENColorSet;
    CScheme;    { activate color scheme }

    FileMode := 0;
    New(ItemNames,Init(FName,512));
    FileMode := 2;
    if ItemNames^.RFError <> 0 then
      begin
        Dialog('Cannot Open '+FName,'OpenMenu',Red,'OK','','');
        exit;
      end;
    MSize := ItemNames^.TotalLines;

    USupplyString := FileSupplyString;
    SupplyString := USupplyString;

    List := nil;
    Ref := nil;

    HideMouse;
    if ym1+Msize+2 < Ym2 then
      YY2 := Ym1+Msize+3
    else
      YY2 := Ym2+1;
    if (FkeysUp) and (YY2 > 21) then
      YY2 := 21;
    XX2 := Xm2;

    if ((xx2-xm1+1) mod 2) <> 0 then
      inc(xx2);

    aWidth := DSize;

    Title := UserTitle;
    Comment := UserComment;
    CommentRow := 1;
    CommentCol := 1;
    Size := MSize;
    Escape := False;

    Orientation := PickVertical;
    if (xx2-xm1 > ((aWidth+2) * 2)) and ((yy2-ym1-4) <= Msize) and
       (MSize > 10) then
      begin
        Orientation := PickSnaking;
        Indent := 3;
      end
    else
      begin
{        xx2 := Xm1 + (aWidth+2) + 4;}
        Indent := ((xx2-xm1) - (aWidth)) div 2;
      end;
    VDent := 2;
    PickOpts := DefPickOptions or pkProcessZero;

    if not UData^.BorderOn then
      begin
        Indent := 0;
        VDent := 0;
        Orientation := PickSnaking;
        PickOpts := PickOpts xor pkMinHeight;
        yy2 := ym2+3;
      end;

    Opts := DefWindowOptions or wResizeable or wAltFrame;
    if UData^.BorderOn then Opts := Opts or wBordered;

    SupplyString := USupplyString;

    InitDeluxe(xm1+Indent, ym1+VDent, xx2-Indent, yy2-VDent ,NENColorSet,
               Opts,
               aWidth+2,Msize,SupplyString,Orientation,SingleChoice,
               PickOpts);

    Fill := NENFillChar;
    Colors := NENColorSet;

    { figure optimum dimensions for outer frame }

    if xx2-xm1 < Length(Title)+10 then
      begin
        repeat
          if xm1 > 2 then
            dec(xm1);
          if xx2 < 78 then
            inc(xx2);
        until xx2-xm1 >= Length(Title)+10;
      end;

    Y := ym1+{pkItemRows}pkHeight+3;
    if FkeysUp then
      begin
        if Y > 21 then
          Y := 21;
      end
    else
      begin
        if Y > 23 then
          Y := 23;
      end;
    AdjustFrameCoords(xm1,ym1,xx2,Y);

    CustomizeWindow(Self,Title,6);

    AddScrollBars(Self, GetOrientation <> pkVertical);

    SetSearchMode(PickStringSelect);
    AddSearchHeader(7, heBL);

    SetPadSize(0,1);

    Y := 2;
    if NENFlag then
      Y := 3;
    if FkeysUp then
      begin
        SetPosLimits(1,Y,80,22);
        SetSizeLimits(1,Y,80,22);
      end
    else
      begin
        SetPosLimits(1,Y,80,25);
        SetSizeLimits(1,Y,80,25);
      end;

    OptimizeSize;

    New(MCP,Init(@PickKeySet, PickKeyMax));
    CustomizeCommandProcessor(MCP^);
    SetCommandProcessor(MCP^);

    with MCP^ do
      begin
        AddCommand(ccUser0 , 1,     OpKey.F1 , 0);
        AddCommand(ccUser1 , 1,     OpKey.F2 , 0);
        AddCommand(ccUser2 , 1,     OpKey.F3 , 0);
        AddCommand(ccUser3 , 1,     OpKey.F4 , 0);
        AddCommand(ccUser4 , 1,     OpKey.F5 , 0);
        AddCommand(ccUser5 , 1,     OpKey.F6 , 0);
        AddCommand(ccUser6 , 1,     OpKey.F7 , 0);
        AddCommand(ccUser7 , 1,     OpKey.F8 , 0);
        AddCommand(ccUser8 , 1,     OpKey.F9 , 0);
        AddCommand(ccUser9 , 1,     OpKey.F10, 0);
        AddCommand(ccToggle, 1,     OpKey.Space,0);
      end;

    Colors := NENColorSet;
    Fill := NENFillChar;

    Size := Msize;

    Sorted := Sort;
    Sort1 := Sort1;
    Sort2 := Sort2;
    if Sort2 > Dsize then
      Sort2 := Dsize;
    SortAscending := SortOrder;
    SortOrder := true;
    Sort1 := 1;
    Sort2 := 99;

{    if Sorted then SortMenu;}

    Draw;
    Select;


    ClearMouseEvents;

end;

{-------------------------------------------------------}

Function GetMenu: integer;
  var Finished: boolean;
      LocalChoice: word;
      Y : byte;
      M : NENMenuPtr;
  begin
    Finished := False;
    M := Menus[ScreenNum];
    M^.Escape := False;
    M^.Choice := 0;
    with M^ do
      begin
        While not Finished do
          begin
          ClearMouseEvents;
          Process;
          LastCmd := GetLastCommand;
          LastKey := GetLastKey;
          if LastKey = 0 then
            begin
              LastKey := 0;   { breakpoint for debugger }
            end;
          Case LastCmd of
              ccMouseDown,
              ccMouseSel :
                         {did user click on the hot spot for closing?}
                         if HandleMousePress(M^) = hsRegion3 then begin
                           WaitForButtonUp;
                           ClearMouseEvents;
                           Choice := 0;
                           GetMenu := Choice;
                           Finished := True;
                           if GetItemCols > 1 then
                             ChangeOrientation(PickSnaking)
                           else
                             ChangeOrientation(PickVertical);
                         end;
              ccQuit,
              ccDone   : begin
                           Finished := True;
                           Escape := True;
                           Choice := 0;
                           GetMenu := Choice;
                         end;
              ccToggle,
              ccSelect : begin
                           if LastKey <> 0 then
                             begin
                               Choice := Ref^[GetLastChoice];
                               GetMenu := Choice;
                               Finished := True;
                             end;
                         end;
              ccUser40 : if not KeyboardMove(M^) Then RingBell;
              ccUser41 : begin
                           if not ToggleZoom(M^) then RingBell;
                           if GetItemCols > 1 then
                             ChangeOrientation(PickSnaking)
                           else
                             ChangeOrientation(PickVertical);
                         end;
              ccUser42 : begin
                           if not KeyboardResize(M^) then RingBell;
                           if GetItemCols > 1 then
                             ChangeOrientation(PickSnaking)
                           else
                             ChangeOrientation(PickVertical);
                         end;
              ccUser43 : begin
                            Case Font8X8Selected of
                              True : SelectFont8X8(False);
                              false: SelectFont8X8(True);
                            end;
                            M^.UpdateScreenSize;
                         end;
              ccUser8  : begin
                           if GetLocalMenuCmd(M^, LocalChoice) = ccSelect then;
                           EraseLocalMenu;
                           Case LocalChoice of
                               1 : Finished := True;
                               2 : if KeyboardMove(M^) Then;
                               3 : begin
                                     if KeyboardResize(M^) then;
                                     if GetItemCols > 1 then
                                       ChangeOrientation(PickSnaking)
                                     else
                                       ChangeOrientation(PickVertical);
                                   end;
                               4 : begin
                                     if ToggleZoom(M^) then;
                                     if GetItemCols > 1 then
                                       ChangeOrientation(PickSnaking)
                                     else
                                       ChangeOrientation(PickVertical);
                                   end;
                             end;
                         end;
            end;
          end;
      end;
  end;

{-------------------------------------------------------}

Procedure NENMenu.SortMenu;
  var I,CurCell: integer;
      Lswap: BigString;
      Iswap: integer;
  begin
    if Size < 2 then
      exit;
    For CurCell := 1 to Size-1 do
      begin
      For I := CurCell+1 to Size do
        begin
         if ((SortAscending)     and (Copy(List^[CurCell],Sort1,Sort2) >
                                      Copy(List^[I],Sort1,Sort2))) or
            ((not SortAscending) and (Copy(List^[CurCell],Sort1,Sort2) <
                                      Copy(List^[I],Sort1,Sort2))) then
          Begin
          Lswap := List^[I];
          List^[I] := List^[CurCell];
          List^[CurCell] := Lswap;
          Iswap := Ref^[I];
          Ref^[I] := Ref^[CurCell];
          Ref^[CurCell] := Iswap;
          End;
        end;
    end;
  end;

{-------------------------------------------------------}

Function NENMenu.EscapePressed: boolean;
  begin
    UpdateTime(False);
    if Escape then
      EscapePressed := True
    else
      EscapePressed := False;
    Escape := False;
  end;

{-------------------------------------------------------}

Procedure NENMenu.ForceEscape;
  begin
    Escape := True;
  end;

{-------------------------------------------------------}

Procedure NENMenu.ClearEscape;
  begin
    Escape := False;
  end;

{-------------------------------------------------------}

Destructor NENMenu.Done;
  begin
    Picklist.Erase;
    if ItemNames <> nil then
      Dispose(ItemNames, Done);
    if List <> nil then
      FreeMemCheck(List,Memory);
    if Ref <> nil then
      FreeMemCheck(Ref,(Size * 2));
    NENColorSet := PrevColors;
    Picklist.Done;
    Dispose(MCP,Done);
  end;

{-------------------------------------------------------}
  procedure NENMenu.UpdateContents;
    var Mon: boolean;
    begin
      HideMousePrim(MOn);
      ActivateWrite;
      with wFrame do
        OpCrt.ClearWindow(frXL+1, frYL+1, frXH-1, frYH-1, Fill, Colors.BlockColor);
      PickList.UpdateContents;
      if Comment <> '' then
        if CommentCol <> 0 then
          fFastWrite(Comment, CommentRow, CommentCol, Colors.CtrlColor)
        else
          fFastCenter(Comment, CommentRow, Colors.CtrlColor);
      ShowMousePrim(MOn);
      DeactivateWrite;
    end;

{-------------------------------------------------------}
  procedure NENMenu.AddComment(UserComment: BigString; Col, Row: byte);
    begin
      if UserComment <> '' then
        Comment := UserComment;
      CommentCol := Col;
      CommentRow := Row;
      UpdateContents;
    end;

{-------------------------------------------------------}

{ Vertical menu handler. Opens a window, writes menu choices and }
{ allows user to select by moving the cursor and pressing Enter or}
{ speed typing. Allows context sensitive help with F1             }
Function GetVmenu(Wnum:integer;Flist:string): integer;
  Var I,J,Items: integer;
      Flen,MaxLen: integer;
      ch: char;
      ItemName: String[30];
      Xm,Ym: integer;
  begin
    Items := 0;
    MaxLen := 0;
    Flen := 0;
    For I := 1 to length(Flist) do
      begin
        Inc(Flen);
        if Flist[I] = '|' then
          begin
            if FLen > MaxLen then
              MaxLen := FLen;
            Flen := 0;
            Inc(Items);
          end;
      end;
    Dec(MaxLen);
    if Maxlen < 10 then
      MaxLen := 10;
    Case Wnum of
      1   : begin
              Xm := 38;
              Ym := 11;
            end;
      2   : begin
              Xm := 74;
              Ym := 11;
            end;
      3   : begin
              Xm := 38;
              Ym := 21;
            end;
      4   : begin
              Xm := 74;
              Ym := 21;
            end;
      5   : begin
              Xm := 76;
              Ym := 23;
            end;
      6   : begin
              Xm := 53;
              Ym := 16;
            end;
      end;
    if Items = 0 then exit;
    ItemName := '';
    J := 1;
    For I := 1 to Items do
      Begin
      Repeat
        begin
         Ch := Flist[J];
         ItemName := ItemName+ch;
         Inc(J);
        end;
        Until ch = '|';
      Delete(ItemName,Length(ItemName),1);
      Menu^[I] := ItemName;
      ItemName := '';
      end;
    I := MaxLen;
    if xm-(xm-Maxlen-6) < 22 then
      I := 22;
    OpenMenu(Xm-I-6,Ym-Items-2,Xm,Ym,Menu^,Items,MaxLen,NoSort,'',SysMsg(000675){' Select '},
             Copyright_Scheme,I);
    GetVMenu := GetMenu;
    CloseWindow;
  end;

{-------------------------------------------------------}

Procedure OpenMenu(Xm1,Ym1,Xm2,Ym2: integer;
                   Var MList;
                   MSize: integer;
                   Dsize: integer;
                   Sort:  boolean;
                   Comment: BigString;
                   Title: TitleString;
                   CScheme: ColorSetProc;
                   VAR Err: integer);
  begin
    inc(ScreenNum);
    New(Menus[ScreenNum],Init(Xm1-1,Ym1-1,Xm2+1,Ym2+1,
                              MList,
                              MSize,
                              Dsize,
                              Sort,
                              Comment,
                              Title,
                              CScheme,
                              Err));

  end;

{-------------------------------------------------------}

Procedure OpenMenuFile(Xm1,Ym1,Xm2,Ym2: integer;
                       FName: PathStr;
                       Dsize: integer;
                       Comment: BigString;
                       Title: TitleString;
                       CScheme: ColorSetProc;
                       VAR Err: integer);
  begin
    inc(ScreenNum);
    New(Menus[ScreenNum],InitFile(Xm1-1,Ym1-1,Xm2+1,Ym2+1,
                                  FName,
                                  Dsize,
                                  Comment,
                                  Title,
                                  CScheme,
                                  Err));

  end;

{-------------------------------------------------------}

Procedure SetFieldMode(OnOff: boolean);
  begin
    UData^.FieldMode := OnOff;
  end;

{-------------------------------------------------------}

procedure SetupSort(order: boolean; Pos1,Pos2: integer);
  begin
    with UData^ do
      begin
        SortOrder := Order;
        Sort1 := Pos1;
        Sort2 := Pos2;
      end;
  end;

{-------------------------------------------------------}

Procedure WaitAndReadKey(Var Ch,Ch2: Char);
  begin
    While not Check4Chars do
      UpdateTime(False);
    GetNextChar(Ch,Ch2);
  end;

{-------------------------------------------------------}

Procedure LoadMenuFromTextFile(X1,Y1,X2,Y2: byte;
                               Fname: PathStr;
                               Title: TitleString;
                               VAR ResultString: Anystring;
                               VAR Result: integer);
Var I,W,D: integer;
    F: Text;
begin
  with UData^ do
    begin
      Result := 0;
      Assign(F,Fname);
      {$I-}
      Reset(F);
      {$I+}
      if IoResult <> 0 then
        begin
        Dialog(SysMsg(000429){Unable To Load }+FName,'Warning',Red,'OK','','');
        exit;
        end;
      I := 1;
      W := 0;
      While not EOF(F) do
        begin
        ReadLn(F,S);
        S := TrimTrail(S);
        if S <> '' then
          begin
          if I <= BigListLength then
            Menu^[I] := S;
          if Length(S) > W then
            W := Length(S);
          Inc(I);
          end;
        end;
      Close(F);
      if W > 30 then
        W := 30;
      OpenMenu(X1,Y1,X2,Y2,Menu^,I-1,W,Sort,'',Title,DarkYellow_Scheme,I);
      Result := GetMenu;
      if Result <> 0 then
        GetMenuString(Result,ResultString);
      CloseWindow;
  end;
end;

{-------------------------------------------------------}

Procedure LoadMenuFromBigTextFile(X1,Y1,X2,Y2: byte;
                                  Fname: PathStr;
                                  Width : integer;
                                  Title: TitleString;
                                  VAR ResultString: Anystring;
                                  VAR Result: integer);
Var I,W,D: integer;
    F: Text;
begin
  with UData^ do
    begin
      Result := 0;
      OpenMenuFile(X1,Y1,X2,Y2,FName,Width,'',Title,DarkYellow_Scheme,I);
      I := GetMenu;
      if I <> 0 then
        GetMenuString(I,ResultString);
      CloseWindow;
      Result := I;
  end;
end;

{-------------------------------------------------------}

Procedure BounceWindow(Speed: integer;DragMode: boolean);
Var oldX,OldY,newX,newY,NewX2,NewY2,Spd: integer;
begin
With UData^,NENMenuPtr(Coords[ScreenNum])^ do
  begin
  OldX := wFrame.frXl;
  OldY := wFrame.frYl;
  Randomize;
  Repeat
    begin
    UpdateTime(False);
    NewX := Random(78-(wFrame.frXh-wFrame.frXl));
    NewY := Random(23-(wFrame.frYh-wFrame.frYl));
    if NewX < 3 then
      NewX := 3;
    if NewY < 3 then
      NewY := 3;
    if DragMode then
      begin
      Spd := Random(50);
      if KeyboardMove(NENMenuPtr(Coords[ScreenNum])^) then;
      end
    else
      begin
      MoveWin(NewX,NewY);
      RedisplayMenu;
      Delay(Speed);
      end;
    end;
    until Check4Chars;
  GetNextChar(Ch,Ch2);
  MoveWin(OldX,OldY);
  RedisplayMenu;
  end;
end;

{ Routines below are for compatibility with pre-object }
{ programs                                             }

{-------------------------------------------------------}
Function EscapePressed: boolean;
  begin
    EscapePressed := Menus[ScreenNum]^.EscapePressed;
  end;

{-------------------------------------------------------}
Procedure ForceEscape;
  begin
    Menus[ScreenNum]^.ForceEscape;
  end;

{-------------------------------------------------------}
Procedure ClearEscape;
  begin
    Menus[ScreenNum]^.ClearEscape;
  end;

Procedure ChangeMenuItem(I: integer;Item: BigString);
  begin
    with Menus[ScreenNum]^ do
      begin
        List^[I] := Item;
      end;
  end;

Procedure GetMenuXY(I: integer;var X,Y: word);
  begin
    with Menus[ScreenNum]^ do
      begin
        X := PkCol;
        Y := PkRow;
      end;
  end;

Procedure DeleteItem(Item: integer);
  var I: integer;
  begin
    with Menus[ScreenNum]^ do
      begin
        For I := Item to Size-1 do
          begin
            List^[I] := List^[I+1];
            Ref^[I] := Ref^[I+1];
          end;
        Dec(Size);
        ChangeNumItems(Size);
      end;
  end;

Procedure DeleteCurrentItem;
  var I: integer;
  begin
    with Menus[ScreenNum]^ do
      begin
      if pkChoice = Size then
        begin
          Dec(Size);
          ChangeNumItems(Size);
          exit;
        end;
      For I := pkChoice to Size-1 do
        begin
          List^[I] := List^[I+1];
          Ref^[I] := Ref^[I+1];
        end;
      Dec(Size);
      ChangeNumItems(Size);
      if IsActive then
        RedisplayMenu;
      end;
  end;

Procedure RedisplayCurrentItem;
  begin
    with Menus[ScreenNum]^ do
      begin
        RedisplayMenu;
      end;
  end;

Procedure TurnOffMenuHighlight;
  begin
    with Menus[ScreenNum]^ do
      begin
      end;
  end;

Procedure ReDisplayMenu;
  begin
    with Menus[ScreenNum]^ do
      begin
        if IsCurrent then
          UpdateContents;
      end;
  end;

Procedure ScrollCurrentMenu(Next: boolean);
  begin
    with Menus[ScreenNum]^ do
      begin
        ScrollCurrentMenu(Next);
      end;
  end;

Procedure GetMenuString(Indx: integer;VAR Ret: Stype);
  begin
    with Menus[ScreenNum]^ do
      begin
        Ret := GetLastChoiceString;
      end;
  end;

Procedure GetMenuIndex(Indx: integer;VAR IX: integer);
  begin
    with Menus[ScreenNum]^ do
      begin
        if Sorted then
          IX := Ref^[Indx]
        else
          IX := Indx;
      end;
  end;

Procedure MoveSelection(item: integer);
  begin
    with Menus[ScreenNum]^ do
      begin
        SetChoice(Item,1);
        UpdateContents;
      end;
  end;

Procedure MarkItemAsSelected;
  begin
    with Menus[ScreenNum]^ do
      begin
        SelectItem(pkChoice);
        UpdateContents;
      end;
  end;

{-------------------------------------------------------}

Procedure SetZoomSize(NewX1,NewY1,NewX2,NewY2: byte);
  begin
    with UData^ do
      begin
        ZoomX1 := NewX1;
        ZoomX2 := NewX2;
        ZoomY1 := NewY1;
        ZoomY2 := NewY2;
      end;
  end;

{-------------------------------------------------------}

Procedure WriteSelectionBox(X,Y: byte;Data: AnyString;Highlight: byte);
  begin
    SetBorderColors;
    DrawBox(X,Y,X+Length(Data)+1,Y+2,TextAttr);
    TextColor(Highlight);
    WriteChr(X+1,Y+1,Data[1],TextAttr);
    SetBorderColors;
    WriteStr(X+2,Y+1,Copy(Data,2,Length(Data)-1),TextAttr);
  end;

Begin
  USupplyString := MenuSupplyString;
end.
