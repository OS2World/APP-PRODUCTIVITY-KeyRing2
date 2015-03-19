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
{$O+,F+}
Unit UNav;

interface

Uses
  Dos,
  OpString, OpCrt, OpRoot, OpCmd, OpFrame, OpWindow,
  OpPick, OpDir, OpCol16, OpMouse, OpDrag,
  UColors, UGlobal, UMenu, UWindow;

Type
  PDirList = ^TDirList;
  TDirList = Object(DirList)
    Mask : PathStr;
    procedure UpdateContents; virtual;
    procedure ProcessSelf; virtual;
  end;

  procedure SelectQueue(var Queue: PathStr);

implementation

Const
  ColorFlex : FlexAttrs = (BlackOnCyan , YellowOnCyan,
                           WhiteOnCyan, WhiteOnRed);
  MonoFlex : FlexAttrs = (YellowOnBlue, LtGreenOnBlue,
                          LtMagentaOnBlue, LtRedOnBlue or Blink);

  procedure TDirList.UpdateContents;
  var Mon: boolean;
  begin
    HideMousePrim(MOn);
    ActivateWrite;
    with wFrame do
      OpCrt.ClearWindow(frXL+1, frYL+1, frXH-1, frYH-1, NENFillChar, NENColorSet.BlockColor);
    PickList.UpdateContents;
    ShowMousePrim(MOn);
    DeactivateWrite;
  end;

  procedure TDirList.ProcessSelf;
  begin
    DirList.ProcessSelf;
  end;

  function RejectBadFiles(var D : DirRec; DirPtr : DirListPtr) : Boolean;
  begin
    RejectBadFiles := False;
    if (D.Attr <> Directory) then
      RejectBadFiles := True;
    if (D.Name = '.') then
      RejectBadFiles := True;
    if (D.Name = '..') then
      if PDirList(DirPtr)^.Mask = PDirList(DirPtr)^.diMask then
        RejectBadFiles := True;
  end;

  Procedure FormatEntry(var X : DirRec; var pkCat : Byte;
                        var S : String; D : DirListPtr);
  begin
    S := JustName(X.Name);
    if X.Name = '..' then
      S := ^A'  '+#17+#17+'  '^A;
  end;

  procedure SelectQueue(var Queue: PathStr);
  var
    Dir : TDirList;
    Finished : Boolean;
  begin
    Cyan_Scheme;
    NENColorSet.SelItemColor := BlackOnLtCyan;
    NENColorSet.BlockColor   := CyanOnYellow;
    if not Dir.InitCustom(22, 7, 57, 22,                 {Window coordinates}
                          NENColorSet,                   {ColorSet}
                          DefWindowOptions or wBordered, {Window options}
                          MaxAvail,                      {Heap space for files}
                          PickSnaking,                   {Pick orientation}
                          SingleFile)                    {Command handler}
    then begin
      WriteLn('Failed to Init DirList,  Status = ', InitStatus);
      Halt;
    end;
    Dir.AdjustFrameCoords(19,5,60,24);

    {Set desired DirList features}
    Dir.SetPosLimits(1, 1, ScreenWidth, ScreenHeight-1);
    Dir.SetPadSize(1, 1);
    Dir.diOptionsOn(diOptimizeSize+diDirsUpCase+diExitIfOne);
    Dir.AddMaskHeader(True, 1, 30, heTC);
    Dir.SetSortOrder(SortName);
    Dir.SetUserFormat(8, FormatEntry);
    Dir.SetRejectFunc(RejectBadFiles);

    Dir.Mask := FullPathname('\NEN\*.');
    Dir.SetMask(Dir.Mask, Directory);

    Dir.SetPickFlex(pkNormal,False,
                    ColorFlex, MonoFlex);
    Dir.SetSearchMode(PickStringSelect);
    CustomizeWindow(Dir, '', 10);
    AddScrollBars(Dir, Dir.GetOrientation <> pkVertical);
    Dir.wFrame.AddShadow(shBR, shSeeThru);
    Dir.EnableExplosions(8);

    {Pick a file}
    Finished := False;
    repeat
      Dir.Process;
      case Dir.GetLastCommand of
        ccMouseDown,
        ccMouseSel :
                   {did user click on the hot spot for closing?}
                   if HandleMousePress(Dir) = hsRegion3 then begin
                     WaitForButtonUp;
                     ClearMouseEvents;
                     if Dir.GetItemCols > 1 then
                       Dir.ChangeOrientation(PickSnaking)
                     else
                       Dir.ChangeOrientation(PickVertical);
                   end;
        ccSelect :
          FastWrite(Pad('Selected: '+Dir.GetSelectedPath, ScreenWidth),
                    ScreenHeight, 1, TextAttr);
        ccError  :
          begin
            FastWrite('Error '+Long2Str(Dir.RawError),
                      ScreenHeight, 1, TextAttr);
            Finished := True;
          end;
        ccQuit   :
          Finished := True;
        {Process other exit commands}
      end;
    until Finished;
    Dir.Done;
  end;

End.
