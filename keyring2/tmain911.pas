{$R-,S-,I-,V-,B-}

program TMAIN911;

{$I OPDEFINE.INC}

uses
  Dos,
  OpInline,
  OpString,
  OpRoot,
  OpCrt,
  OpColor,
  {$IFDEF UseMouse}
  OpMouse,
  {$ENDIF}
  OpAbsFld,
  OpCmd,
  OpField,
  OpFrame,
  OpWindow,
  OpSelect,
  OpEntry,
  MAIN911;

  {$IFDEF UseMouse}
const
  MouseChar  : Char = #04;
  {$ENDIF}

{Color set used by entry screen}
const
  EsColors : ColorSet = (
    TextColor       : YellowOnBlue;       TextMono        : WhiteOnBlack;
    CtrlColor       : YellowOnBlue;       CtrlMono        : WhiteOnBlack;
    FrameColor      : CyanOnBlue;         FrameMono       : LtGrayOnBlack;
    HeaderColor     : WhiteOnCyan;        HeaderMono      : BlackOnLtGray;
    ShadowColor     : DkGrayOnBlack;      ShadowMono      : WhiteOnBlack;
    HighlightColor  : WhiteOnRed;         HighlightMono   : BlackOnLtGray;
    PromptColor     : LtGrayOnBlue;       PromptMono      : LtGrayOnBlack;
    SelPromptColor  : LtGrayOnBlue;       SelPromptMono   : LtGrayOnBlack;
    ProPromptColor  : LtGrayOnBlue;       ProPromptMono   : LtGrayOnBlack;
    FieldColor      : YellowOnBlue;       FieldMono       : LtGrayOnBlack;
    SelFieldColor   : BlueOnCyan;         SelFieldMono    : WhiteOnBlack;
    ProFieldColor   : LtGrayOnBlue;       ProFieldMono    : LtGrayOnBlack;
    ScrollBarColor  : CyanOnBlue;         ScrollBarMono   : LtGrayOnBlack;
    SliderColor     : CyanOnBlue;         SliderMono      : WhiteOnBlack;
    HotSpotColor    : BlackOnCyan;        HotSpotMono     : BlackOnLtGray;
    BlockColor      : YellowOnCyan;       BlockMono       : WhiteOnBlack;
    MarkerColor     : WhiteOnCyan;        MarkerMono      : BlackOnLtGray;
    DelimColor      : YellowOnBlue;       DelimMono       : WhiteOnBlack;
    SelDelimColor   : BlueOnCyan;         SelDelimMono    : WhiteOnBlack;
    ProDelimColor   : YellowOnBlue;       ProDelimMono    : WhiteOnBlack;
    SelItemColor    : YellowOnCyan;       SelItemMono     : BlackOnLtGray;
    ProItemColor    : LtGrayOnBlue;       ProItemMono     : LtGrayOnBlack;
    HighItemColor   : WhiteOnBlue;        HighItemMono    : WhiteOnBlack;
    AltItemColor    : WhiteOnBlue;        AltItemMono     : WhiteOnBlack;
    AltSelItemColor : WhiteOnCyan;        AltSelItemMono  : BlackOnLtGray;
    FlexAHelpColor  : WhiteOnBlue;        FlexAHelpMono   : WhiteOnBlack;
    FlexBHelpColor  : WhiteOnBlue;        FlexBHelpMono   : WhiteOnBlack;
    FlexCHelpColor  : LtCyanOnBlue;       FlexCHelpMono   : BlackOnLtGray;
    UnselXrefColor  : YellowOnBlue;       UnselXrefMono   : LtBlueOnBlack;
    SelXrefColor    : WhiteOnCyan;        SelXrefMono     : BlackOnLtGray;
    MouseColor      : WhiteOnRed;         MouseMono       : BlackOnLtGray
  );

var
  ES     : EntryScreen;
  UR     : UserRecord;
  Status : Word;

{$F+}
procedure PreEdit(ESP : EntryScreenPtr);
  {-Called just before a field is edited}
begin
  with ESP^ do
    case GetCurrentID of
      idFName                : ;
      idPW                   : ;
    end;
end;

procedure PostEdit(ESP : EntryScreenPtr);
  {-Called just after a field has been edited}
begin
  with ESP^ do
    case GetCurrentID of
      idFName                : ;
      idPW                   : ;
    end;
end;

procedure ErrorHandler(UnitCode : Byte; var ErrCode : Word; Msg : string);
  {-Report errors}
begin
  RingBell;
end;

procedure DisplayHelp(UnitCode : Byte; IdPtr : Pointer; HelpIndex : Word);
  {-Display context sensitive help}
begin
end;
{$F-}

begin
  ClrScr;

  {$IFDEF UseMouse}
  if MouseInstalled then
    with EsColors do begin
      {activate mouse cursor}
      SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) shl 8)+
                             Byte(MouseChar));
      ShowMouse;
      {enable mouse support}
      EntryCommands.cpOptionsOn(cpEnableMouse);
    end;
  {$ENDIF}

  {initialize user record}
  InitUserRecord(UR);

  {initialize entry screen}
  Status := InitEntryScreen(ES, UR, EsColors);
  if Status <> 0 then begin
    WriteLn('Error initializing entry screen: ', Status);
    Halt(1);
  end;

  {set up user hooks}
  ES.SetPreEditProc(PreEdit);
  ES.SetPostEditProc(PostEdit);
  ES.SetErrorProc(ErrorHandler);
  EntryCommands.SetHelpProc(DisplayHelp);

  {test entry screen}
  ES.Process;
  ES.Erase;

  {$IFDEF UseMouse}
  HideMouse;
  {$ENDIF}

  {show exit command}
  WriteLn('Exit command = ', ES.GetLastCommand);
  ES.Done;
end.
