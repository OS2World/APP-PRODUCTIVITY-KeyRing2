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
{$B-,E+,I-,N+,O+,R-,D-,V-,A-,F+,X+}
unit UCalc;

interface

uses
   OpString,
   OpCrt,
   OpDrag,
   OpMouse,
   OpCmd,
   OpCtrl,
   OpDialog,
   OpInline,
   OpDos,
   OpRoot,
   OpEnhKbd,
   OpKey,
   OpAbsFld,
   OpField,
   OpFrame,
   OpWindow,
   OpSelect,
   OpCol16;

type
  dgCalculator = object(DialogBox)
    caCurrVal	: Float;
    caPendVal	: Float;
    caMemVal	: Float;
    caCurrDec	: ShortInt;
    caPendDec	: ShortInt;
    caMemDec	: ShortInt;
    caMemInd	: string[3];
    caOpInd   : string[1];
    caResult  : string[28];
    caCounting: boolean;
    caClear   : boolean;
    caPendOp  : word;
    caError   : boolean;

    constructor Init(X1, Y1 : byte);
    constructor InitCustom(X1, Y1 : byte; Colors : ColorSet; Buttons : DialogColorSet);
    procedure ProcessSelf; virtual;
    procedure UpdateContents; virtual;
    destructor Done; virtual;
    procedure caAppendDigit(NumId : word);
    procedure caBackSpace;
    procedure caChangeSign;
    procedure caAddDecimal;
    procedure caClearAll;
    procedure caClearEntry;
    procedure caClearMemory;
    procedure caRecallMemory;
    procedure caStoreMemory;
    procedure caAddToMemory;
    procedure caCalcPending;
    procedure caPushResult;
    procedure caAdd;
    procedure caSubtract;
    procedure caMultiply;
    procedure caDivide;
    procedure caCalcResult;
    procedure caPercent;
    procedure caSquareRoot;
    procedure caReciprocal;
   end;

const
  DialogColors        : ColorSet = (
      TextColor       : BlackOnLtGray; 	TextMono        : BlackOnLtGray;
      CtrlColor       : LtGreenOnCyan;	CtrlMono        : DkGrayOnBlack;
      FrameColor      : WhiteOnLtGray; 	FrameMono       : BlackOnLtGray;
      HeaderColor     : WhiteOnLtGray; 	HeaderMono      : BlackOnLtGray;
      ShadowColor     : DkGrayOnBlack; 	ShadowMono      : BlackOnBlack;
      HighlightColor  : WhiteOnRed;     HighlightMono   : BlackOnLtGray;
      PromptColor     : WhiteOnDkGray; 	PromptMono      : BlackOnLtGray;
      SelPromptColor  : WhiteOnLtGray; 	SelPromptMono   : BlackOnLtGray;
      ProPromptColor  : BlackOnLtGray; 	ProPromptMono   : LtGrayOnBlack;
      FieldColor      : YellowOnBlue;   FieldMono       : LtGrayOnBlack;
      SelFieldColor   : WhiteOnBlue;    SelFieldMono    : WhiteOnBlack;
      ProFieldColor   : BlueOnLtGray;   ProFieldMono    : LtGrayOnBlack;
      ScrollBarColor  : LtGrayOnBlue;   ScrollBarMono   : LtGrayOnBlack;
      SliderColor     : LtGrayOnBlue;   SliderMono      : WhiteOnBlack;
      HotSpotColor    : LtGreenOnLtGray;HotSpotMono     : WhiteOnBlack;
      BlockColor      : YellowOnBlue;   BlockMono       : WhiteOnBlack;
      MarkerColor     : WhiteOnBlue;    MarkerMono      : BlackOnLtGray;
      DelimColor      : YellowOnLtGray; DelimMono       : WhiteOnBlack;
      SelDelimColor   : BlueOnBlue;     SelDelimMono    : WhiteOnBlack;
      ProDelimColor   : YellowOnLtGray;	ProDelimMono    : WhiteOnBlack;
      SelItemColor    : WhiteOnGreen;   SelItemMono     : BlackOnLtGray;
      ProItemColor    : LtGrayOnLtGray;	ProItemMono     : LtGrayOnBlack;
      HighItemColor   : WhiteOnLtGray; 	HighItemMono    : WhiteOnBlack;
      AltItemColor    : WhiteOnCyan;    AltItemMono     : WhiteOnBlack;
      AltSelItemColor : WhiteOnGreen;   AltSelItemMono  : BlackOnLtGray;
      FlexAHelpColor  : WhiteOnLtGray; 	FlexAHelpMono   : WhiteOnBlack;
      FlexBHelpColor  : WhiteOnLtGray; 	FlexBHelpMono   : WhiteOnBlack;
      FlexCHelpColor  : LtCyanOnLtGray; FlexCHelpMono   : BlackOnLtGray;
      UnselXrefColor  : YellowOnLtGray;	UnselXrefMono   : LtBlueOnBlack;
      SelXrefColor    : BlueOnCyan;     SelXrefMono     : BlackOnLtGray;
      MouseColor      : WhiteOnRed;     MouseMono       : BlackOnLtGray);

  ButtonColors : DialogColorSet = (
      HiPromptColor   : BlackOnLtGray;  HiPromptMono    : WhiteOnBlack;
      ButtonColor     : BlackOnGreen;   ButtonMono      : LtGrayOnBlack;
      DefButtonColor  : LtCyanOnGreen;  DefButtonMono   : LtGrayOnBlack;
      HiButtonColor   : YellowOnGreen;  HiButtonMono    : WhiteOnBlack;
      SelButtonColor  : WhiteOnGreen;   SelButtonMono   : WhiteOnBlack;
      ProButtonColor  : BlackOnLtGray;  ProButtonMono   : BlackOnLtGray;
      BtnShadowColor  : BlackOnLtGray;  BtnShadowMono   : BlackOnLtGray;
      ClusterColor    : BlackOnCyan;    ClusterMono     : LtGrayOnBlack;
      ProClusterColor : BlackOnLtGray;  ProClusterMono  : LtGrayOnBlack;
      HiClusterColor  : YellowOnCyan;   HiClusterMono   : WhiteOnBlack;
      SelClusterColor : WhiteOnCyan;    SelClusterMono  : LtGrayOnBlack);

const
  ccBackSp      = ccUser37;
  ccCls         = ccUser38;
  ccClEntry     = ccUser39;
  ccMemClear    = ccUser40;
  ccMemRestore  = ccUser41;
  ccMemSave     = ccUser42;
  ccMemAdd      = ccUser43;
  ccChangeSign  = ccUser44;
  ccDecimalPt   = ccUser45;
  ccDivide      = ccUser46;
  ccMultiply    = ccUser47;
  ccSubtract    = ccUser48;
  ccAdd         = ccUser49;
  ccSquareRoot  = ccUser50;
  ccPercent     = ccUser51;
  ccReciprocal  = ccUser52;
  ccEqual       = ccUser53;
  ccDigit       = ccUser54;

const
  {Keystroke to command mapping}
  dgCalcKeyMax	= 62;   {last available slot in dgCalcKeySet}
  {ID string for installation programs}
  dgCalcKeyID	: string[13] = 'dgcalc keys';
  {default key assignments}
  dgCalcKeySet	: array[0..dgCalcKeyMax] of Byte = (
   {length keys         command type      key sequence}
    3,     $00, $00,    ccQuit,          {^Break}
    3,     $00, $3B,    ccHelp,          {F1}
    3,     $00, $53,    ccBackSp,        {Del}
    2,     $07,         ccBackSp,        {^G}
    2,     $08,         ccBackSp,        {^H, Bksp}
    2,     $0D,         ccEqual,         {^M, Enter}
    2,     $1B,         ccQuit,          {Esc}
    2,     $7F,         ccBackSp,        {^Bksp}
    3,     $00, $EE,    ccQuit,          {click right  = ESC}
    3,     $00, $EF,    ccMouseSel,      {click left   = mouse selection}

    {-----------pad to end of array----------}
   0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

const
  dgCalcCfgEnd : Byte = 0;

const
  ucDialogCalc = 6000;

var
  dgCalcCommands : DragProcessorPtr;

procedure DoCalculator;

implementation

const
  caWidth  = 25;
  emMemory = 'Mem';

constructor dgCalculator.Init(X1, Y1 : byte);
begin
end;


constructor dgCalculator.InitCustom(X1, Y1 : byte; Colors : ColorSet; Buttons : DialogColorSet);
const
  idEqual    = 26;
  WinOptions = wBordered+wClear+wUserContents;
begin
if not DialogBox.InitCustom(X1, Y1, X1+33, Y1+12, Colors, WinOptions, Buttons) then
	Fail;

New(dgCalcCommands, Init(@dgCalcKeySet, dgCalcKeyMax));
SetCommandProcessor(dgCalcCommands^);

caMemInd := '';
caOpInd	 := '';
caResult := '';

caCurrVal := 0;
caPendVal := 0;
caMemVal  := 0;

caCurrDec := 0;
caPendDec := 0;
caMemDec  := 0;

caCounting := false;
caClear    := false;
caPendOp   := ccNone;

AddPushButton('&0',   12,  8, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&1',   10,  8, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&2',   10, 13, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&3',   10, 18, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&4',    8,  8, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&5',    8, 13, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&6',    8, 18, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&7',    6,  8, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&8',    6, 13, 3, ucDialogCalc, ccDigit,      false);
AddPushButton('&9',    6, 18, 3, ucDialogCalc, ccDigit,      false);

AddPushButton('C&L',   4,  2, 6, ucDialogCalc, ccCls,        false);
AddPushButton('C&E',   4, 10, 6, ucDialogCalc, ccClEntry,    false);
AddPushButton('&BkSp', 4, 18, 6, ucDialogCalc, ccBackSp,     false);

AddPushButton('M&C',   6,  2, 4, ucDialogCalc, ccMemClear,   false);
AddPushButton('M&R',   8,  2, 4, ucDialogCalc, ccMemRestore, false);
AddPushButton('M&S',  10,  2, 4, ucDialogCalc, ccMemSave,    false);
AddPushButton('&M+',  12,  2, 4, ucDialogCalc, ccMemAdd,     false);

AddPushButton('&/',    6, 23, 3, ucDialogCalc, ccDivide,     false);
AddPushButton('&*',    8, 23, 3, ucDialogCalc, ccMultiply,   false);
AddPushButton('&-',   10, 23, 3, ucDialogCalc, ccSubtract,   false);
AddPushButton('&+',   12, 23, 3, ucDialogCalc, ccAdd,        false);

AddPushButton('S&qt',  6, 28, 5, ucDialogCalc, ccSquareRoot, false);
AddPushButton('&%',    8, 28, 5, ucDialogCalc, ccPercent,    false);
AddPushButton('1/&x', 10, 28, 5, ucDialogCalc, ccReciprocal, false);
AddPushButton('C&hs', 12, 13, 3, ucDialogCalc, ccChangeSign, false);
AddPushButton('&.',   12, 18, 3, ucDialogCalc, ccDecimalPt,  false);

AddPushButton('&=',   12, 28, 5, ucDialogCalc, ccEqual,      true);

dgFieldOptionsOn(efProtected+efRightJustify);
AddSimpleEditControl('', 4, 29, 'X', 4, 29,  3,  3, 0, caMemInd);
AddSimpleEditControl('', 2,  4, 'X', 2,  4,  1,  1, 0, caOpInd);
AddSimpleEditControl('', 2,  7, '#', 2,  7, 25, 25, 0, caResult);
dgFieldOptionsOff(efProtected);

AddBoxFieldCustom(SglWindowFrame, 2, 1, 33, 3, Colors.TextColor, Colors.TextMono);

SetNextField(idEqual);
SetFieldLinks(idEqual, idEqual, idEqual);

end;


procedure dgCalculator.ProcessSelf;
const
  NumLockBit = $20;
var
  KeyboardFlags	: Byte absolute $40:$17;
  SaveNumLock   : Boolean;
  Quit          : boolean;
begin
{save NumLock state and force it on}
SaveNumLock := ByteFlagIsSet(KeyboardFlags, NumLockBit);
SetByteFlag(KeyboardFlags, NumLockBit);

Quit := false;
repeat
   DialogBox.ProcessSelf;
   caResult := TrimSpaces(caResult);
   case GetLastCommand of
     ccDigit      :  caAppendDigit(GetCurrentId);
     ccEqual      :  caCalcResult;
     ccBackSp     :  caBackSpace;
     ccAdd        :  caAdd;
     ccSubtract   :  caSubtract;
     ccMultiply   :  caMultiply;
     ccDivide     :  caDivide;
     ccDecimalPt  :  caAddDecimal;
     ccChangeSign :  caChangeSign;
     ccSquareRoot :  caSquareRoot;
     ccPercent    :  caPercent;
     ccReciprocal :  caReciprocal;
     ccCls        :  caClearAll;
     ccClEntry    :  caClearEntry;
     ccMemClear   :  caClearMemory;
     ccMemRestore :  caRecallMemory;
     ccMemSave    :  if not caError then
                       caStoreMemory;
     ccMemAdd     :  if not caError then
                       caAddToMemory;
     ccQuit,
     ccError      :  Quit := True;
   else
     Quit := true;
   end;
until Quit;
{restore previous NumLock state}
if SaveNumLock then
  SetByteFlag(KeyboardFlags, NumLockBit)
else
  ClearByteFlag(KeyboardFlags, NumLockBit);
end;


procedure dgCalculator.UpdateContents;
begin
caResult := TrimSpaces(caResult);
if caResult = '' then
  caResult := '0';
caResult := LeftPad(caResult, caWidth);
if not Str2Real(caResult, caCurrVal) then
  begin
    caCurrVal := 0;
    caCurrDec := 0;
    caPendVal := 0;
    caPendDec := 0;
    caPendOp := ccNone;
    caOpInd := '';
   end;
if caMemVal <> 0 then
  caMemInd := emMemory
else
  caClearMemory;
DialogBox.UpdateContents;
end;

destructor dgCalculator.Done;
begin
Dispose(dgCalcCommands, Done);
DialogBox.Done;
end;


procedure dgCalculator.caAppendDigit(NumId : word);
begin
if caClear or (caResult = '0') then
  begin
    caResult := '';
    caCurrVal := 0;
    caCurrDec := 0;
    caCounting := false;
    caOpInd := '';
    caError := false;
  end;
caClear := false;
if caCounting then
  Inc(caCurrDec);
caResult := caResult + Chr(Ord('0')+NumId);
end;


procedure dgCalculator.caBackSpace;
begin
if caCounting and (caCurrDec > 0) then
  Dec(caCurrDec);
if caCurrDec = 0 then
  caCounting := false;
Delete(caResult, byte(caResult[0]), 1);
if caResult = '' then
  caResult := '0';
end;


procedure dgCalculator.caChangeSign;
begin
if caResult <> '0' then
  begin
    if caResult[1] = '-' then
      Delete(caResult, 1, 1)
   else
     caResult := '-' + caResult;
   end;
end;


procedure dgCalculator.caAddDecimal;
begin
if Pos('.', caResult) = 0 then
  begin
    caResult := caResult + '.';
    caCounting := true;
  end;
end;


procedure dgCalculator.caClearAll;
begin
caClearEntry;
caPendVal := 0;
caPendDec := 0;
caPendOp := ccNone;
caOpInd := '';
end;


procedure dgCalculator.caClearEntry;
begin
caResult := '0';
caCurrVal := 0;
caCurrDec := 0;
caError := false;
end;


procedure dgCalculator.caClearMemory;
begin
caMemInd := '';
caMemVal := 0;
caMemDec := 0;
end;


procedure dgCalculator.caRecallMemory;
begin
caClear := true;
caOpInd := '';
caCurrVal := caMemVal;
caCurrDec := caMemDec;
caResult := Real2Str(caCurrVal, caWidth, caCurrDec);
end;


procedure dgCalculator.caStoreMemory;
begin
caClear := true;
caOpInd := '';
Str2Real(caResult, caMemVal);
if caMemVal <> 0 then
  caMemDec := caCurrDec;
end;


procedure dgCalculator.caAddToMemory;
var
  InterMem  : Float;
begin
caClear := true;
caOpInd := '';
Str2Real(caResult, InterMem);
caMemVal := caMemVal + InterMem;
if caMemVal <> 0 then
	MaxWord(caMemDec, caCurrDec);
end;


procedure dgCalculator.caCalcPending;
begin
case caPendOp of
	ccAdd       : caCurrVal := caPendVal + caCurrVal;
  ccSubtract  : caCurrVal := caPendVal - caCurrVal;
  ccMultiply  : caCurrVal := caPendVal * caCurrVal;
  ccDivide    : if caCurrVal <> 0 then
                  begin
                    caCurrVal := caPendVal / caCurrVal;
                    { **** decimal point kludge **** }
                    if (Frac(caCurrVal) <> 0) and (caCurrDec = 0) then
                      caCurrDec := 2;
                  end;
	end;
if (caCurrVal = 0) and (caPendOp = ccDivide) then
	begin
    caResult := 'Divide by zero error';
    caError := true;
  end
{ **** overflow kludge **** }
else
  if (caCurrVal >=1.0E25) then
    begin
      caResult := 'Overflow';
      caError := true;
    end
  else
    caResult := Real2Str(caCurrVal, caWidth, MaxWord(caCurrDec, caPendDec));
end;


procedure dgCalculator.caPushResult;
begin
if Str2Real(caResult, caPendVal) then
	caPendDec := caCurrDec;
end;


procedure dgCalculator.caAdd;
begin
caClear := true;
if Str2Real(caResult, caCurrVal) then
	caCalcPending;
caOpInd := '+';
caPendOp := ccAdd;
caPushResult;
end;


procedure dgCalculator.caSubtract;
begin
caClear := true;
if Str2Real(caResult, caCurrVal) then
	caCalcPending;
caOpInd := '-';
caPendOp := ccSubtract;
caPushResult;
end;


procedure dgCalculator.caMultiply;
begin
caClear := true;
if Str2Real(caResult, caCurrVal) then
	caCalcPending;
caOpInd := '*';
caPendOp := ccMultiply;
caPushResult;
end;


procedure dgCalculator.caDivide;
begin
caClear := true;
if Str2Real(caResult, caCurrVal) then
	caCalcPending;
caOpInd := '/';
caPendOp := ccDivide;
caPushResult;
end;


procedure dgCalculator.caCalcResult;
begin
caClear := true;
if Str2Real(caResult, caCurrVal) then
	caCalcPending;
caOpInd := '';
caPendOp := ccNone;
end;


procedure dgCalculator.caPercent;
begin
caClear := true;
if Str2Real(caResult, caCurrVal) then
	begin
    caCurrVal := caPendVal * (caCurrVal / 100);
    if caPendOp in [ccMultiply, ccDivide] then
      begin
        caPendVal := 0;
        caPendDec := 0;
        caPendOp  := ccNone;
      end;
	{ **** decimal point kludge **** }
   if (Frac(caCurrVal) <> 0) and (caCurrDec = 0) then
     caCurrDec := 2;
   caCalcPending;
   caOpInd := '=';
 end;
end;


procedure dgCalculator.caSquareRoot;
var
	N	: Float;
begin
caClear := true;
if Str2Real(caResult, N) then
  begin
    if N < 0 then
      begin
        caResult := 'Result is undefined';
        caError := true;
      end
    else
      begin
        N := Sqrt(N);
        if (Frac(N) <> 0) and (caCurrDec < 2) then
          Inc(caCurrDec, 2);
        caResult := Real2Str(N, caWidth, caCurrDec);
      end;
   end;
end;


procedure dgCalculator.caReciprocal;
var
  N	: Float;
begin
caClear := true;
if Str2Real(caResult, N) then
  begin
    if N = 0 then
      begin
        caResult := 'Divide by zero error';
        caError := true;
      end
    else
      begin
        N := 1 / N;
        if (Frac(N) <> 0) and (caCurrDec < 2) then
          Inc(caCurrDec, 2);
        caResult := Real2Str(N, caWidth, caCurrDec);
      end;
   end;
end;

procedure DoCalculator;
var
  Calc  : dgCalculator;
  Cmd   : word;
  Quit  : boolean;
begin
Quit := false;
if Calc.InitCustom(10, 5, DialogColors, ButtonColors) then
  begin
    with Calc, wFrame, DialogColors do
      begin
        AddHeader(' Calculator ', heTC);
        AddShadow(shBR, shSeeThru);

        {add hot spot for closing the window}
        AddCustomHeader('[ ]', frTL, +2, 0, HeaderColor, HeaderMono);
        AddCustomHeader('þ',   frTL, +3, 0, HotSpotColor, HeaderMono);
        AddHotRegion(frTL, hsRegion3, +3, 0, 1, 1);

        {add hot spot for moving the window}
        AddHotBar(frTT, MoveHotCode);
      end;

    repeat
      Calc.Process;
      Cmd := Calc.GetLastCommand;
      case Cmd of
        ccMouseAuto,
        ccMouseDown,
        ccMouseSel : begin
                      {did user click on the hot spot for closing?}
                       if HandleMousePress(Calc) = hsRegion3 then
                         begin
                           ClearMouseEvents;
                           Quit := True;
                         end;
                     end;
        ccQuit,
        ccError :  Quit := true;
      	end;
    until Quit;
  Calc.Done;
  end;
end;

end.
