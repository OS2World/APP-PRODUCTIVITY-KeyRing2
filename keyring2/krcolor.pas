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
UNIT KRColor;


INTERFACE

USES
    OpCtrl,
    OpCol16,
    OpCrt;

CONST
    BoxColors      : ColorSet = (
             TextColor      : YellowOnCyan; TextMono : WhiteOnBlack;
             CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
             FrameColor     : BlackOnCyan; FrameMono : LtGrayOnBlack;
             HeaderColor    : WhiteOnBlack; HeaderMono : BlackOnLtGray;
             ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
             HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
             PromptColor    : LtGrayOnBlue; PromptMono : LtGrayOnBlack;
             SelPromptColor : LtGrayOnBlue; SelPromptMono : LtGrayOnBlack;
             ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
             FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
             SelFieldColor  : BlueOnCyan; SelFieldMono : WhiteOnBlack;
             ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
             ScrollBarColor : CyanOnBlue; ScrollBarMono : LtGrayOnBlack;
             SliderColor    : CyanOnBlue; SliderMono : WhiteOnBlack;
             HotSpotColor   : BlackOnCyan; HotSpotMono : BlackOnLtGray;
             BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
             MarkerColor    : WhiteOnCyan; MarkerMono : BlackOnLtGray;
             DelimColor     : YellowOnBlue; DelimMono : WhiteOnBlack;
             SelDelimColor  : BlueOnCyan; SelDelimMono : WhiteOnBlack;
             ProDelimColor  : YellowOnBlue; ProDelimMono : WhiteOnBlack;
             SelItemColor   : WhiteOnBlue; SelItemMono : BlackOnLtGray;
             ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
             HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
             AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
             AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
             FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
             FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
             FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
             UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
             SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
             MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
             );


    {3/1/93: Changed Text Color to LtCyanOnBlue}
    TargetDefaultColors : ColorSet = (
        TextColor      : LtCyanOnBlue; TextMono : LtGrayOnBlack;
        CtrlColor      : YellowOnCyan; CtrlMono : BlackOnLtGray;
        FrameColor     : WhiteOnBlue; FrameMono : WhiteOnBlack;
        HeaderColor    : YellowOnCyan; HeaderMono : BlackOnLtGray;
        ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnLtGray;
        HighlightColor : YellowOnRed; HighlightMono : WhiteOnBlack;
        PromptColor    : LtCyanOnBlue; PromptMono : LtGrayOnBlack;
        SelPromptColor : WhiteOnBlue; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : LtCyanOnBlue; ProPromptMono : LtGrayOnBlack;
        FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
        SelFieldColor  : YellowOnCyan; SelFieldMono : BlackOnLtGray;
        ProFieldColor  : YellowOnBlue; ProFieldMono : LtGrayOnBlack;
        {ProFieldColor   : YellowOnGreen;  ProFieldMono   : BlackOnLtGray;}
        ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
        SliderColor    : LtGrayOnBlue; SliderMono : LtGrayOnBlack;
        HotSpotColor   : BlueOnLtGray; HotSpotMono : LtGrayOnBlack;
        BlockColor     : WhiteOnBlack; BlockMono : WhiteOnBlack;
        MarkerColor    : WhiteOnBlack; MarkerMono : BlackOnLtGray;
        DelimColor     : LtCyanOnBlue; DelimMono : LtGrayOnBlack;
        SelDelimColor  : LtCyanOnBlue; SelDelimMono : LtGrayOnBlack;
        {ProDelimColor   : LtCyanOnBlue;   ProDelimMono   : LtGrayOnBlack;}
        ProDelimColor  : BlueOnBlue; ProDelimMono : BlackOnBlack;
        SelItemColor   : YellowOnCyan; SelItemMono : BlackOnLtGray;
        ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
        HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
        AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
        AltSelItemColor : WhiteOnGreen; AltSelItemMono : BlackOnLtGray;
        FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
        FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
        FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
        UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
        SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
        MouseColor     : LtGreenOnRed; MouseMono : BlackOnLtGray
        );

    AltColors      : ColorSet = (
             TextColor      : YellowOnGreen; TextMono : WhiteOnBlack;
             CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
             FrameColor     : WhiteOnGreen; FrameMono : LtGrayOnBlack;
             HeaderColor    : BlackOnLtGray; HeaderMono : BlackOnLtGray;
             ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
             HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
             PromptColor    : YellowOnGreen; PromptMono : LtGrayOnBlack;
             SelPromptColor : YellowOnGreen; SelPromptMono : LtGrayOnBlack;
             ProPromptColor : YellowOnGreen; ProPromptMono : LtGrayOnBlack;
             FieldColor     : YellowOnGreen; FieldMono : LtGrayOnBlack;
             SelFieldColor  : YellowOnCyan; SelFieldMono : WhiteOnBlack;
             ProFieldColor  : YellowOnGreen; ProFieldMono : LtGrayOnBlack;
             ScrollBarColor : CyanOnBlue; ScrollBarMono : LtGrayOnBlack;
             SliderColor    : CyanOnBlue; SliderMono : WhiteOnBlack;
             HotSpotColor   : BlackOnCyan; HotSpotMono : BlackOnLtGray;
             BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
             MarkerColor    : WhiteOnCyan; MarkerMono : BlackOnLtGray;
             DelimColor     : YellowOnGreen; DelimMono : WhiteOnBlack;
             SelDelimColor  : YellowOnGreen; SelDelimMono : WhiteOnBlack;
             ProDelimColor  : YellowOnGreen; ProDelimMono : WhiteOnBlack;
             SelItemColor   : YellowOnCyan; SelItemMono : BlackOnLtGray;
             ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
             HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
             AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
             AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
             FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
             FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
             FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
             UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
             SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
             MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
             );
    TargetNormalColors : ColorSet = (
        TextColor      : YellowOnBlue; TextMono : LtGrayOnBlack;
        CtrlColor      : YellowOnCyan; CtrlMono : BlackOnLtGray;
        FrameColor     : WhiteOnBlue; FrameMono : WhiteOnBlack;
        HeaderColor    : YellowOnCyan; HeaderMono : BlackOnLtGray;
        ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnLtGray;
        HighlightColor : YellowOnRed; HighlightMono : WhiteOnBlack;
        PromptColor    : LtCyanOnBlue; PromptMono : LtGrayOnBlack;
        SelPromptColor : LtCyanOnBlue; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : LtCyanOnBlue; ProPromptMono : LtGrayOnBlack;
        FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
        SelFieldColor  : YellowOnCyan; SelFieldMono : BlackOnLtGray;
        ProFieldColor  : YellowOnBlue; ProFieldMono : LtGrayOnBlack;
        {ProFieldColor   : YellowOnGreen;  ProFieldMono   : BlackOnLtGray;}
        ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
        SliderColor    : LtGrayOnBlue; SliderMono : LtGrayOnBlack;
        HotSpotColor   : BlueOnLtGray; HotSpotMono : LtGrayOnBlack;
        BlockColor     : WhiteOnBlack; BlockMono : WhiteOnBlack;
        MarkerColor    : WhiteOnBlack; MarkerMono : BlackOnLtGray;
        DelimColor     : LtCyanOnBlue; DelimMono : LtGrayOnBlack;
        SelDelimColor  : LtCyanOnBlue; SelDelimMono : LtGrayOnBlack;
        {ProDelimColor   : LtCyanOnBlue;   ProDelimMono   : LtGrayOnBlack;}
        ProDelimColor  : BlueOnBlue; ProDelimMono : BlackOnBlack;
        SelItemColor   : YellowOnCyan; SelItemMono : BlackOnLtGray;
        ProItemColor   : YellowOnBlue; ProItemMono : LtGrayOnBlack;
        HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
        AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
        AltSelItemColor : WhiteOnGreen; AltSelItemMono : BlackOnLtGray;
        FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
        FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
        FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
        UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
        SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
        MouseColor     : LtGreenOnRed; MouseMono : BlackOnLtGray
        );
    FbColors2      : ColorSet = (
             TextColor      : WhiteOnCyan; TextMono : LtGrayOnBlack;
             CtrlColor      : YellowOnCyan; CtrlMono : BlackOnLtGray;
             FrameColor     : WhiteOnGreen; FrameMono : WhiteOnBlack;
             HeaderColor    : YellowOnCyan; HeaderMono : BlackOnLtGray;
             ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnLtGray;
             HighlightColor : YellowOnRed; HighlightMono : WhiteOnBlack;
             PromptColor    : LtCyanOnBlue; PromptMono : LtGrayOnBlack;
             SelPromptColor : LtCyanOnBlue; SelPromptMono : LtGrayOnBlack;
             ProPromptColor : LtCyanOnBlue; ProPromptMono : LtGrayOnBlack;
             FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
             SelFieldColor  : YellowOnCyan; SelFieldMono : BlackOnLtGray;
             ProFieldColor  : YellowOnBlue; ProFieldMono : LtGrayOnBlack;
             {ProFieldColor   : YellowOnGreen;  ProFieldMono   : BlackOnLtGray;}
             ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
             SliderColor    : LtGrayOnBlue; SliderMono : LtGrayOnBlack;
             HotSpotColor   : BlueOnLtGray; HotSpotMono : LtGrayOnBlack;
             BlockColor     : WhiteOnBlack; BlockMono : WhiteOnBlack;
             MarkerColor    : WhiteOnBlack; MarkerMono : BlackOnLtGray;
             DelimColor     : LtCyanOnBlue; DelimMono : LtGrayOnBlack;
             SelDelimColor  : LtCyanOnBlue; SelDelimMono : LtGrayOnBlack;
             {ProDelimColor   : LtCyanOnBlue;   ProDelimMono   : LtGrayOnBlack;}
             ProDelimColor  : BlueOnBlue; ProDelimMono : BlackOnBlack;
             SelItemColor   : WhiteOnBlue; SelItemMono : BlackOnLtGray;
             ProItemColor   : YellowOnBlue; ProItemMono : LtGrayOnBlack;
             HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
             AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
             AltSelItemColor : WhiteOnGreen; AltSelItemMono : BlackOnLtGray;
             FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
             FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
             FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
             UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
             SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
             MouseColor     : LtGreenOnRed; MouseMono : BlackOnLtGray
             );

    ErrorColors    : ColorSet = (
           TextColor      : YellowOnBlue; TextMono : WhiteOnBlack;
           CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
           FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
           HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
           ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
           HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
           PromptColor    : YellowOnBlue; PromptMono : LtGrayOnBlack;
           SelPromptColor : YellowOnBlue; SelPromptMono : LtGrayOnBlack;
           ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
           FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
           SelFieldColor  : BlueOnCyan; SelFieldMono : WhiteOnBlack;
           ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
           ScrollBarColor : CyanOnBlue; ScrollBarMono : LtGrayOnBlack;
           SliderColor    : CyanOnBlue; SliderMono : WhiteOnBlack;
           HotSpotColor   : BlackOnCyan; HotSpotMono : BlackOnLtGray;
           BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
           MarkerColor    : WhiteOnCyan; MarkerMono : BlackOnLtGray;
           DelimColor     : YellowOnBlue; DelimMono : WhiteOnBlack;
           SelDelimColor  : BlueOnCyan; SelDelimMono : WhiteOnBlack;
           ProDelimColor  : YellowOnBlue; ProDelimMono : WhiteOnBlack;
           SelItemColor   : YellowOnCyan; SelItemMono : BlackOnLtGray;
           ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
           HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
           AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
           AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
           FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
           FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
           FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
           UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
           SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
           MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
           );
IMPLEMENTATION

END.
