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
{$A-,V-,O+,F+}

Unit UPickCol;

interface

uses
   OpCrt,
   OpInline,
   OpRoot,
   OpPick,
   OpCmd,
   OpFrame,
   OpMouse,
   OpDrag,
   OpWindow,
   UColors,
   UWindow;

Function GetColorSelection: byte;

implementation

const
  csHeight = 18;
  ColorStr : String[3] = ' * ';
type
  ColorSelectorPtr = ^ColorSelector;
  ColorSelector =
    object(CommandWindow)
      csMax  : Byte;
      csMax0 : Byte;
      csWidth : Byte;
      csColor : Byte;
      csBoxColor : Byte;
      csBoxMono : Byte;
      csBoxAttr : Byte;

      constructor InitCustom(X1, Y1 : Byte;
                             var Colors : ColorSet;
                             Options : LongInt);
       {-Initialize the color selector with custom colors and options}
      procedure UpdateContents; virtual;
        {-Redraw the color selector}
      procedure ProcessSelf; virtual;
        {-Select a color}
      {...}
      procedure SetColor(Color : Byte);
        {-Set default color choice}
      function GetColor : Byte;
        {-Get last color choice}
      procedure SetBoxAttr(Color, Mono : Byte);
        {-Set color for selection box}

      {+++internal methods+++}
      procedure csCalcRowCol(Attr : Byte; var Row, Col : Byte);
      function  csCalcColor(Row, Col : Byte) : Byte;
    end;

  {------------ ColorSelector methods ----------}

  constructor ColorSelector.InitCustom(X1, Y1 : Byte;
                                       var Colors : ColorSet;
                                       Options : LongInt);
   {-Initialize the color selector with custom colors and options}
  var
    X2, Y2 : Byte;
  begin
    {are we displaying attributes > $7F?}
    csMax := $7F;
    csMax0 := $70;
    csWidth := 26;

    {calculate X2 and Y2}
    X2 := X1+csWidth-1;
    Y2 := Y1+csHeight-1;

    {adjust options}
    ClearLongFlag(Options, wResizeable);
    SetLongFlag(Options, wClear+wUserContents+wBordered);

    {initialize the window}
    if not CommandWindow.InitCustom(X1, Y1, X2, Y2, Colors, Options,
                                    PickCommands, 0) then
      Fail;

    wFrame.AddHeader(' Selection ', heTC);
    {set attribute for box}
    SetBoxAttr(Colors.FrameColor, Colors.FrameMono);
  end;

  procedure ColorSelector.SetBoxAttr(Color, Mono : Byte);
    {-Set color for selection box}
  begin
    csBoxColor := Color;
    csBoxMono := MapMono(Color, Mono);
    csBoxAttr := ColorMono(csBoxColor, csBoxMono);
  end;

  function ColorSelector.csCalcColor(Row, Col : Byte) : Byte;
    {-Return the video attribute to use at Row,Col}
  begin
    Dec(Row, wYL);
    Dec(Col, wXL);
    if (Row = 0) or (Col = 0) or (Row = csHeight-1) or (Col = csWidth-1) then
      csCalcColor := csBoxAttr
    else
      csCalcColor := (((Col-1) div 3) shl 4)+(csBoxAttr and $0F);
      {                 background    shl 4 +    foreground    }
  end;

  procedure ColorSelector.csCalcRowCol(Attr : Byte; var Row, Col : Byte);
    {-Calculate the row and column for an attribute}
  begin
    {calculate row}
    Row := Succ(wYL)+(Attr and $F);

    {calculate column}
    Col := Succ(wXL)+((Attr shr 4)*3);
  end;

  procedure ColorSelector.UpdateContents;
    {-Redraw the inner window of the color selector}
  var
    I, Row, Col, A : Byte;
    SaveMouse : Boolean;
  begin
    HideMousePrim(SaveMouse);

    for A := 0 to csMax do begin
      csCalcRowCol(A, Row, Col);
      FastWrite(ColorStr, Row, Col, A);
    end;

    ShowMousePrim(SaveMouse);
    StackWindow.UpdateContents; {!!.01}
  end;

  procedure ColorSelector.SetColor(Color : Byte);
    {-Set default color choice}
  begin
    csColor := Color;
  end;

  function ColorSelector.GetColor : Byte;
    {-Get last color choice}
  begin
    GetColor := csColor;
  end;

  procedure ColorSelector.ProcessSelf;
    {-Select a color}
  const
    BoxCharArray : array[-1..1, -2..2] of Char = (
      ('Ú', 'Ä', 'Ä', 'Ä', '¿'),
      ('³', ' ', '*', ' ', '³'),
      ('À', 'Ä', 'Ä', 'Ä', 'Ù'));
  var
    SaveAttr, Attr : Byte;
    AllDone        : Boolean;
    BoxBuffer      : array[-1..1, -2..2] of Word;
    BoxBufferPtr   : Pointer;
    SaveXL, SaveYL,
    SaveXH, SaveYH : Byte;
    WinXL, WinYL,
    WinXH, WinYH	 : Byte;
    MRow, MCol		 : Byte;
    {$IFDEF UseMouse}
    SaveMouse : Boolean;
    {$ENDIF}

    procedure DrawAttributeBox(Attr, Row, Col : Byte);
      {-Draw box around current selection}
    const
      S : String[1] = ' ';
    var
      A : Byte;
      X, Y, RowDelta, ColDelta : Integer;
    begin
      for RowDelta := -1 to 1 do begin
        Y := Row+RowDelta;
        for ColDelta := -2 to 2 do begin
          X := Col+ColDelta;

          {leave the attribute of ' * ' alone}
          if (RowDelta = 0) and (Abs(ColDelta) < 2) then
            A := Attr
          else
            A := csCalcColor(Y, X);

          S[1] := BoxCharArray[RowDelta, ColDelta];
          FastWrite(S, Y, X, A);
        end;
      end;
    end;

    procedure ShowChoice(FirstCall : Boolean);
      {-Show the currently selected attribute}
    var
      Row, Col : Byte;
      Redraw : Boolean;
      SaveMouse : boolean;
    begin
      HideMousePrim(SaveMouse);
      {remove the previous box, if any}
      if not FirstCall then
        RestoreWindow(SaveXL, SaveYL, SaveXH, SaveYH, False, BoxBufferPtr);

      {calculate the row and column for the new one}
      csCalcRowCol(Attr, Row, Col);

      {save the portion of the screen that will be overwritten}
      SaveXL := Pred(Col);
      SaveYL := Pred(Row);
      SaveXH := Col+3;
      SaveYH := Succ(Row);
      if SaveWindow(SaveXL, SaveYL, SaveXH, SaveYH, False, BoxBufferPtr) then ;

      {draw the box that marks the current attribute}
      DrawAttributeBox(Attr, Row, Succ(Col));

      ShowMousePrim(SaveMouse);
    end;

  begin
    {Draw initial screen if not already done}
    ClearErrors;          {!!.01}
    Draw;
    if RawError <> 0 then {!!.01}
      Exit;               {!!.01}

    {hide the cursor}
    SetCursor(cuHidden);

    {initialize}
    BoxBufferPtr := @BoxBuffer;

    {get choices}
    AllDone := False;
    Attr := csColor and csMax;
    ShowChoice(True);
    repeat
      {get the next command}
      GetNextCommand;

      SaveAttr := Attr;
      case cwCmd of
        ccUp :
          if (Attr and $0F) = 0 then
            Inc(Attr, $0F)
          else
            Dec(Attr);
        ccDown :
          if (Attr and $0F) = $0F then
            Dec(Attr, $0F)
          else
            Inc(Attr);
        ccBackTab,
        ccLeft :
          if Attr <= $0F then
            Inc(Attr, csMax0)
          else
            Dec(Attr, $10);
        ccTab,
        ccRight :
          if Attr >= csMax0 then
            Dec(Attr, csMax0)
          else
            Inc(Attr, $10);
        ccUpLeft  :
          begin
            if (Attr and $0F) <> 0 then
              Dec(Attr);
            if Attr > $0F then
              Dec(Attr, $10);
          end;
        ccDownLeft  :
          begin
            if (Attr and $0F) <> $0F then
              Inc(Attr);
            if Attr > $0F then
              Dec(Attr, $10);
          end;
        ccUpRight :
          begin
            if (Attr and $0F) <> 0 then
              Dec(Attr);
            if Attr < csMax0 then
              Inc(Attr, $10);
          end;
        ccDownRight :
          begin
            if (Attr and $0F) <> $0F then
              Inc(Attr);
            if Attr < csMax0 then
              Inc(Attr, $10);
          end;
        ccHome :
          Attr := Attr and $0F;
        ccEnd :
          Attr := (Attr and $0F)+csMax0;
        ccPageUp :
          Attr := Attr and csMax0;
        ccPageDn :
          Attr := (Attr and csMax0)+$0F;
		  ccMouseSel :
          begin
          {select attribute with mouse}
          CommandWindow.Coordinates(WinXL, WinYL, WinXH, WinYH);
          if MouseInWindow(WinXL+1, WinYL+1, WinXH-1, WinYH-1) then
            begin
            MRow := MouseWhereYabs - wYL;
            MCol := MouseWhereXabs - wXL;
            Attr := (((MCol - 1) div 3) shl 4) + (MRow - 1);
            if SaveAttr = Attr then
              begin
              csColor := Attr;
              AllDone := True;
              end;
            end;
			 end;
        ccSelect :
          begin
            csColor := Attr;
            AllDone := True;
          end;
        ccQuit :
          begin
            Attr := csColor;
            AllDone := True;
          end;
        ccHelp :
          RequestHelp(wHelpIndex);
        else
          cwCmd := ccNone;
      end;

      {draw new choice}
      if (Attr <> SaveAttr) then
        ShowChoice(False);

    until AllDone;

    {restore screen beneath box}
    RestoreWindow(SaveXL, SaveYL, SaveXH, SaveYH, False, BoxBufferPtr);

  end;


var
   ColorSel	: ColorSelectorPtr;
   PCP          : DragProcessorPtr;
   Attr		: byte;

Function GetColorSelection: byte;
begin
  Attr := TextAttr;
  Macro_Scheme;
  New(ColorSel,InitCustom(32, 5, NENColorSet, DefWindowOptions));
  if InitStatus <> 0 then exit;
  New(PCP,Init(@PickKeySet, PickKeyMax));
  CustomizeCommandProcessor(PCP^);
  CustomizeWindow(ColorSel^, ' Select ', 10);
  with ColorSel^ do
    begin
      SetCommandProcessor(PCP^);
      SetColor(Attr);
      HideMouse;
      Process;
      ShowMouse;
      GetColorSelection := GetColor;
      Erase;
    end;
  Dispose(ColorSel,Done);
  Dispose(PCP,Done);
end;


end.
