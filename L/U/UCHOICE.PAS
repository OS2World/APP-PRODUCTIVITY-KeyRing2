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
{ UCHOICE Unit.                                          }
{ Forms part of the UWINDOW family.                      }
{ Provides a Windows and Menu operating environment      }
{ NEN version.                                           }
{--------------------------------------------------------}

Unit UChoice;

interface

Uses DOS,OpCrt,UMsg,
     OpString,OpRoot,OpCmd,OpFrame,OpWindow,OpCtrl,OpDialog,
     OpField,OpFedit,OpMemo,OpEditor,OpDrag,OpMouse,OpCol16,OpPick,OpDir,
     Qglobal,Qscreen,Qinput,QUptime,QNovell,QHdrRec,QCursor,
{     UVscreen,}
     ULib,UGlobal,UColors,UKey,UWindow,UCalndr,
     UMenu;

Procedure GetChoices(Xm1,Ym1: integer;
                     Var MList;
                     MSize: integer;
                     Dsize: integer;
                     Title: TitleString;
                     WColors: ColorSetProc;
                     var Choices;
                     var Escape: boolean);

implementation


Procedure GetChoices(Xm1,Ym1: integer;
                     Var MList;
                     MSize: integer;
                     Dsize: integer;
                     Title: TitleString;
                     WColors: ColorSetProc;
                     var Choices;
                     var Escape: boolean);
  Type
    ChoiceArray = Array[1..999] of boolean;

  Var
    FDB    : DialogBoxPtr;
    DCP    : DragProcessorPtr;
    I,M    : integer;
    Choice : ChoiceArray absolute Choices;
    Item   : BigString;
    Ch     : char;
    List   : ^HugeList;
    Finished : boolean;
    Status : word;
    W,H    : byte;

      function InitDialogBox : Word;
        {-Initialize dialog box}
      const
        WinOptions = wBordered+wClear+wUserContents;
      begin
         New(FDB,InitCustom(
            Xm1,Ym1,Xm1+Dsize+11,Ym1+Msize+4,
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
         CustomizeWindow(FDB^, Title, 10);

         InitDialogBox := FDB^.RawError;
      end;

Begin
  {select alternate scroll bar arrows}
  DefArrows := TriangleArrows;

  Gray_Scheme;

  {initialize dialog box}
  Status := InitDialogBox;
  if Status <> 0 then begin
    WriteLn('Error initializing dialog box: ', Status);
    exit;
  end;

  W := DSize+10;
  H := MSize;

  List := @MList;

  FDB^.AddCheckBoxes('Options',2, 2, 3,2, W, H+1 ,W, 13);
  for i := 1 to MSize do
    FDB^.AddCheckBox('&'+List^[i],Choice[i]);

  FDB^.AddPushButton('&OK',      H+4,   5, 8, 0, ccSelect, True);
  FDB^.AddPushButton(' &CANCEL ',H+4,  15, 8, 0, ccQuit, False);

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
              Escape := True;
            end;
          ccSelect :   begin
                         Finished := true;
                         Escape := False;
                       end;
          ccQuit   :   begin
                         Finished := true;
                         Escape := True;
                       end;
      end;
    end;

  Dispose(FDB,Done);
  Dispose(DCP,Done);

End;

end.
