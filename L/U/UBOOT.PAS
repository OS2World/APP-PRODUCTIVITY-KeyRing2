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
{$F+,O+}
{**********************************************************************}
{* (C) 1993 NewsMaker Systems.                                        *}
{**********************************************************************}

unit Uboot;

interface

procedure ProcessRebootRequest;

const
  AllowReboot    : Boolean = False;

implementation

uses
  DOS,
  OpCrt, OpInline, OpKey, OpString, OpDialog, OpDrag, OpSelect, OpConst,
  OpWindow, OpFrame, OpRoot, OpField, OpFEdit, OpCmd, OpCol16,
  UReboot,
  UColors;

  procedure ProcessRebootRequest;
  var
    FDB            : DialogBoxPtr;
    DCP            : DragProcessorPtr;
    Status         : Word;
    Pic            : Char;
    Y              : Byte;
    Finished       : Boolean;
    RebootFlag     : Boolean;

    function InitDialogBox : Word;
      {-Initialize dialog box}
    const
      WinOptions     = wBordered + wClear + wUserContents;
    begin
    New(FDB, InitCustom(
      27, 8, 54, 13,
      NENColorSet,                {main color set}
      WinOptions,                 {window options}
      NENDialogSet                {dialog box-specific colors}
      ));
    if FDB = nil then 
      begin
      InitDialogBox := InitStatus;
      Exit;
      end;
    New(DCP, Init(@DialogKeySet, DialogKeyMax));
    FDB^.SetCommandProcessor(DCP^);
    FDB^.wFrame.AddShadow(shBR, shSeeThru);
    FDB^.wFrame.AddHeader(' Warning! ', heTC);

    InitDialogBox := FDB^.RawError;
    end;

  begin
  if not RebootRequested then Exit;

  {select alternate scroll bar arrows}
  DefArrows := TriangleArrows;

  Gray_Scheme;
  NENColorSet.HeaderColor := WhiteOnRed;

  {initialize dialog box}
  Status := InitDialogBox;
  if Status <> 0 then
    begin
    WriteLn('Error initializing dialog box: ', Status);
    Exit;
    end;

  Pic := 'X';

  {set field/control options}
  FDB^.dgFieldOptionsOn(efClearFirstChar);

  FDB^.AddCenteredTextField('Reboot Requested', 2);
  if AllowReboot then
    FDB^.AddCenteredTextField('Data May be Lost!', 3)
  else
    FDB^.AddCenteredTextField('Please Exit Normally', 3);

  if AllowReboot then
    begin
    FDB^.AddPushButton('&Continue', 5, 3, 10, 0, ccQuit, True);
    FDB^.AddPushButton('&Reboot  ', 5, 16, 10, 0, ccUser1, False);
    end
  else
    FDB^.AddPushButton('&Continue', 5, 10, 10, 0, ccQuit, True);

  Finished := False;
  RebootFlag := False;
  while not Finished do
    begin
    FDB^.Process;
    case FDB^.GetLastCommand of
      ccMouseDown,
      ccMouseSel :
        {did user click on the hot spot for closing?}
        if HandleMousePress(FDB^) = hsRegion3 then 
          begin
          ClearMouseEvents;
          Finished := True;
          end;
      ccUser1 :
        begin
        Finished := True;
        RebootFlag := True;
        end;
      ccQuit : 
        begin
        Finished := True;
        RebootFlag := False;
        end;
    end;
    end;

  Dispose(FDB, Done);
  Dispose(DCP, Done);

  if RebootFlag then
    begin
    FastWrite('Restarting System..', 1, 1, WhiteOnRed);
    Reboot;
    end
  else
    RebootRequested := False;

  end;

end.

