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
{$X+,V-,B-,E-,N-,R-,S-,F-,O-,A+,G-,P-,I-,T-}

UNIT Colors;

INTERFACE

USES
    OpCol16,
    OpCRT,
    OpCtrl;

CONST
    MouseChar      : CHAR = #04;

    HelpColors     : ColorSet = (
            TextColor      : WhiteOnMagenta; TextMono : WhiteOnBlack;
            CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
            FrameColor     : WhiteOnMagenta; FrameMono : LtGrayOnBlack;
            HeaderColor    : BlackOnLtGray; HeaderMono : BlackOnLtGray;
            ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
            HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
            PromptColor    : LtGrayOnBlue; PromptMono : LtGrayOnBlack;
            SelPromptColor : LtGrayOnBlue; SelPromptMono : LtGrayOnBlack;
            ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
            FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
            SelFieldColor  : BlueOnCyan; SelFieldMono : WhiteOnBlack;
            ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
            ScrollBarColor : BlackOnMagenta; ScrollBarMono : LtGrayOnBlack;
            SliderColor    : BlackOnMagenta; SliderMono : WhiteOnBlack;
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
            SelXrefColor   : BlueOnYellow; SelXRefMono : BlackOnLtGray;
            MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
            );

    EsColorsMagenta : ColorSet = (
        TextColor      : YellowOnMagenta; TextMono : WhiteOnBlack;
        CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
        FrameColor     : YellowOnMagenta; FrameMono : LtGrayOnBlack;
        HeaderColor    : LtBlueOnLtGray; HeaderMono : BlackOnLtGray;
        ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
        HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
        PromptColor    : YellowOnMagenta; PromptMono : LtGrayOnBlack;
        SelPromptColor : LtGreenOnMagenta; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : YellowOnMagenta; ProPromptMono : LtGrayOnBlack;
        FieldColor     : WhiteOnMagenta; FieldMono : LtGrayOnBlack;
        SelFieldColor  : BlueOnCyan; SelFieldMono : WhiteOnBlack;
        ProFieldColor  : LtGrayOnMagenta; ProFieldMono : LtGrayOnBlack;
        ScrollBarColor : LtBlueOnLtGray; ScrollBarMono : LtGrayOnBlack;
        SliderColor    : DkGrayOnGreen; SliderMono : WhiteOnBlack;
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
        SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
        MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
        );

    RecPrtColors   : ColorSet = (
          TextColor      : WhiteOnMagenta; TextMono : WhiteOnBlack;
          CtrlColor      : LtRedOnBlue; CtrlMono : LtGrayOnBlack;
          FrameColor     : LtRedOnMagenta; FrameMono : LtGrayOnBlack;
          HeaderColor    : LtRedOnMagenta; HeaderMono : LtGrayOnBlack;
          ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnLtGray;
          HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
          PromptColor    : CyanOnBlue; PromptMono : LtGrayOnBlack;
          SelPromptColor : LtCyanOnBlue; SelPromptMono : LtGrayOnBlack;
          ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
          FieldColor     : CyanOnBlue; FieldMono : WhiteOnBlack;
          SelFieldColor  : YellowOnBlack; SelFieldMono : WhiteOnBlack;
          ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
          ScrollBarColor : CyanOnBlack; ScrollBarMono : LtGrayOnBlack;
          SliderColor    : CyanOnBlack; SliderMono : WhiteOnBlack;
          HotSpotColor   : BlackOnLtGray; HotSpotMono : BlackOnLtGray;
          BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
          MarkerColor    : WhiteOnMagenta; MarkerMono : BlackOnLtGray;
          DelimColor     : CyanOnBlue; DelimMono : WhiteOnBlack;
          SelDelimColor  : YellowOnBlue; SelDelimMono : WhiteOnBlack;
          ProDelimColor  : LtGrayOnBlue; ProDelimMono : WhiteOnBlack;
          SelItemColor   : YellowOnCyan; SelItemMono : BlackOnLtGray;
          ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
          HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
          AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
          AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
          FlexAHelpColor : LtRedOnBlue; FlexAHelpMono : WhiteOnBlack;
          FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
          FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
          UnselXrefColor : WhiteOnBlue; UnselXrefMono : LtBlueOnBlack;
          SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
          MouseColor : WhiteOnRed; MouseMono : BlackOnLtGray);

    EsColors       : ColorSet = (
              TextColor      : LtCyanOnBlue; TextMono : WhiteOnBlack;
              CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
              FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
              HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
              ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
              HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
              PromptColor    : YellowOnBlue {LtGrayOnBlue} ; PromptMono : WhiteOnBlack;
              SelPromptColor : YellowOnBlue {LtGrayOnBlue} ; SelPromptMono : WhiteOnBlack;
              ProPromptColor : {YellowOnBlue} LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
              FieldColor     : WhiteOnBlue {YellowOnBlue} ; FieldMono : LtGrayOnBlack;
              SelFieldColor  : BlueOnCyan {YellowOnCyan} ; SelFieldMono : WhiteOnBlack;
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

    FundCalcColors : ColorSet = (
        TextColor      : YellowOnCyan; TextMono : WhiteOnBlack;
        CtrlColor      : YellowOnCyan; CtrlMono : WhiteOnBlack;
        FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
        HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
        ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
        HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
        PromptColor    : YellowOnCyan; PromptMono : LtGrayOnBlack;
        SelPromptColor : YellowOnCyan; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : DkGrayOnCyan; ProPromptMono : LtGrayOnBlack;
        FieldColor     : WhiteOnCyan; FieldMono : LtGrayOnBlack;
        SelFieldColor  : WhiteOnGreen; SelFieldMono : WhiteOnBlack;
        ProFieldColor  : DkGrayOnCyan; ProFieldMono : LtGrayOnBlack;
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
        SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
        MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
        );

    Level1EntryColors : ColorSet = (
        TextColor      : YellowOnBlue; TextMono : LtGrayOnBlack;
        CtrlColor      : LtRedOnBlue; CtrlMono : WhiteOnBlack;
        FrameColor     : LtCyanOnBlue; FrameMono : LtGrayOnBlack;
        HeaderColor    : LtCyanOnBlue; HeaderMono : LtGrayOnBlack;
        ShadowColor    : LtGrayOnBlack; ShadowMono : LtGrayOnBlack;
        HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
        PromptColor    : WhiteOnBlue; PromptMono : WhiteOnBlack;
        SelPromptColor : WhiteOnBlue; SelPromptMono : WhiteOnBlack;
        ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
        FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
        SelFieldColor  : BlueOnCyan; SelFieldMono : BlackOnLtGray;
        ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
        ScrollBarColor : LtGrayOnBlack; ScrollBarMono : LtGrayOnBlack;
        SliderColor    : LtGrayOnBlack; SliderMono : LtGrayOnBlack;
        HotSpotColor   : BlackOnLtGray; HotSpotMono : LtGrayOnBlack;
        BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
        MarkerColor    : WhiteOnRed; MarkerMono : BlackOnLtGray;
        DelimColor     : WhiteOnBlack; DelimMono : WhiteOnBlack;
        SelDelimColor  : BlackOnLtGray; SelDelimMono : BlackOnLtGray;
        ProDelimColor  : LtGrayOnBlack; ProDelimMono : LtGrayOnBlack;
        SelItemColor   : WhiteOnGreen; SelItemMono : BlackOnLtGray;
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

    Level2EntryColors : ColorSet = (
        TextColor      : YellowOnMagenta; TextMono : WhiteOnBlack;
        CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
        FrameColor     : WhiteOnMagenta; FrameMono : LtGrayOnBlack;
        HeaderColor    : WhiteOnMagenta; HeaderMono : WhiteOnBlack;
        ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
        HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
        PromptColor    : YellowOnMagenta; PromptMono : LtGrayOnBlack;
        SelPromptColor : WhiteOnMagenta; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
        FieldColor     : WhiteOnMagenta; FieldMono : LtGrayOnBlack;
        SelFieldColor  : BlackOnLtGray; SelFieldMono : WhiteOnBlack;
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
        SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
        MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
        );

    Level1PickColors : ColorSet = (
        TextColor      : WhiteOnGreen; TextMono : WhiteOnBlack;
        CtrlColor      : YellowOnGreen; CtrlMono : WhiteOnBlack;
        FrameColor     : WhiteOnGreen; FrameMono : LtGrayOnBlack;
        HeaderColor    : WhiteOnGreen; HeaderMono : BlackOnLtGray;
        ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
        HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
        PromptColor    : YellowOnBlue; PromptMono : LtGrayOnBlack;
        SelPromptColor : YellowOnBlue; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
        FieldColor     : BlackOnCyan; FieldMono : LtGrayOnBlack;
        SelFieldColor  : YellowOnCyan; SelFieldMono : WhiteOnBlack;
        ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
        ScrollBarColor : LtGrayOnBlack; ScrollBarMono : LtGrayOnBlack;
        SliderColor    : LtGrayOnBlack; SliderMono : WhiteOnBlack;
        HotSpotColor   : LtGrayOnBlack; HotSpotMono : BlackOnLtGray;
        BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
        MarkerColor    : WhiteOnCyan; MarkerMono : BlackOnLtGray;
        DelimColor     : YellowOnBlue; DelimMono : WhiteOnBlack;
        SelDelimColor  : BlueOnCyan; SelDelimMono : WhiteOnBlack;
        ProDelimColor  : YellowOnBlue; ProDelimMono : WhiteOnBlack;
        SelItemColor   : BlackOnLtGray; SelItemMono : BlackOnLtGray;
        ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
        HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
        AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
        AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
        FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
        FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
        FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
        UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
        SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
        MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
        );

    Level1BrowserColors : ColorSet = (
        TextColor      : WhiteOnGreen; TextMono : WhiteOnBlack;
        CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
        FrameColor     : WhiteOnGreen; FrameMono : LtGrayOnBlack;
        HeaderColor    : WhiteOnGreen; HeaderMono : BlackOnLtGray;
        ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
        HighlightColor : WhiteOnGreen; HighlightMono : BlackOnLtGray;
        PromptColor    : YellowOnBlue; PromptMono : LtGrayOnBlack;
        SelPromptColor : YellowOnBlue; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
        FieldColor     : BlackOnCyan; FieldMono : LtGrayOnBlack;
        SelFieldColor  : YellowOnCyan; SelFieldMono : WhiteOnBlack;
        ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
        ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
        SliderColor    : LtGrayOnBlue; SliderMono : WhiteOnBlack;
        HotSpotColor   : BlueOnLtGray; HotSpotMono : BlackOnLtGray;
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
        SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
        MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
        );

    Level2BrowserColors : ColorSet = (
        TextColor      : WhiteOnMagenta; TextMono : WhiteOnBlack;
        CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
        FrameColor     : WhiteOnRed; FrameMono : LtGrayOnBlack;
        HeaderColor    : WhiteOnGreen; HeaderMono : BlackOnLtGray;
        ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
        HighlightColor : WhiteOnGreen; HighlightMono : BlackOnLtGray;
        PromptColor    : YellowOnBlue; PromptMono : LtGrayOnBlack;
        SelPromptColor : YellowOnBlue; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
        FieldColor     : BlackOnCyan; FieldMono : LtGrayOnBlack;
        SelFieldColor  : YellowOnCyan; SelFieldMono : WhiteOnBlack;
        ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
        ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
        SliderColor    : LtGrayOnBlue; SliderMono : WhiteOnBlack;
        HotSpotColor   : BlueOnLtGray; HotSpotMono : BlackOnLtGray;
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
        SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
        MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
        );

    MessageBoxColors : ColorSet = (
        TextColor      : YellowOnCyan; TextMono : WhiteOnBlack;
        CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
        FrameColor     : BlackOnCyan; FrameMono : LtGrayOnBlack;
        HeaderColor    : WhiteOnBlack; HeaderMono : BlackOnLtGray;
        ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
        HighlightColor : WhiteOnGreen; HighlightMono : BlackOnLtGray;
        PromptColor    : YellowOnBlue; PromptMono : LtGrayOnBlack;
        SelPromptColor : YellowOnCyan; SelPromptMono : LtGrayOnBlack;
        ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
        FieldColor     : BlackOnCyan; FieldMono : LtGrayOnBlack;
        SelFieldColor  : BlueOnCyan; SelFieldMono : WhiteOnBlack;
        ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
        ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
        SliderColor    : BlueOnLtGray; SliderMono : WhiteOnBlack;
        HotSpotColor   : BlueOnLtGray; HotSpotMono : BlackOnLtGray;
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
        SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
        MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
        );

    MenuColors     : ColorSet = (
            TextColor      : YellowOnBlue; TextMono : WhiteOnBlack;
            CtrlColor      : LtRedOnBlue; CtrlMono : LtGrayOnBlack;
            FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
            HeaderColor    : LtCyanOnBlue; HeaderMono : LtGrayOnBlack;
            ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnLtGray;
            HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
            PromptColor    : CyanOnBlue; PromptMono : LtGrayOnBlack;
            SelPromptColor : LtCyanOnBlue; SelPromptMono : LtGrayOnBlack;
            ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
            FieldColor     : CyanOnBlue; FieldMono : WhiteOnBlack;
            SelFieldColor  : YellowOnBlack; SelFieldMono : WhiteOnBlack;
            ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
            ScrollBarColor : CyanOnBlue; ScrollBarMono : LtGrayOnBlack;
            SliderColor    : CyanOnBlue; SliderMono : WhiteOnBlack;
            HotSpotColor   : BlackOnCyan; HotSpotMono : BlackOnLtGray;
            BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
            MarkerColor    : WhiteOnMagenta; MarkerMono : BlackOnLtGray;
            DelimColor     : CyanOnBlue; DelimMono : WhiteOnBlack;
            SelDelimColor  : YellowOnBlue; SelDelimMono : WhiteOnBlack;
            ProDelimColor  : LtGrayOnBlue; ProDelimMono : WhiteOnBlack;
            SelItemColor   : YellowOnCyan; SelItemMono : BlackOnLtGray;
            ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
            HighItemColor  : LtRedOnBlue; HighItemMono : WhiteOnBlack;
            AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
            AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
            FlexAHelpColor : LtRedOnBlue; FlexAHelpMono : WhiteOnBlack;
            FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
            FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
            UnselXrefColor : WhiteOnBlue; UnselXrefMono : LtBlueOnBlack;
            SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
            MouseColor : WhiteOnRed; MouseMono : BlackOnLtGray);


    {GAMP colorset}
    GampColorSet   : ColorSet = (
          TextColor      : YellowOnBlue; TextMono : LtGrayOnBlack;
          CtrlColor      : LtRedOnBlue; CtrlMono : WhiteOnBlack;
          FrameColor     : LtCyanOnBlue; FrameMono : LtGrayOnBlack;
          HeaderColor    : WhiteOnGreen; HeaderMono : BlackOnLtGray;
          ShadowColor    : LtGrayOnBlack; ShadowMono : LtGrayOnBlack;
          HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
          PromptColor    : WhiteOnBlue; PromptMono : WhiteOnBlack;
          SelPromptColor : WhiteOnBlue; SelPromptMono : WhiteOnBlack;
          ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
          FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
          SelFieldColor  : BlueOnCyan; SelFieldMono : BlackOnLtGray;
          ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
          ScrollBarColor : LtGrayOnBlack; ScrollBarMono : LtGrayOnBlack;
          SliderColor    : LtGrayOnBlack; SliderMono : LtGrayOnBlack;
          HotSpotColor   : BlackOnLtGray; HotSpotMono : LtGrayOnBlack;
          BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
          MarkerColor    : WhiteOnRed; MarkerMono : BlackOnLtGray;
          DelimColor     : WhiteOnBlack; DelimMono : WhiteOnBlack;
          SelDelimColor  : BlackOnLtGray; SelDelimMono : BlackOnLtGray;
          ProDelimColor  : LtGrayOnBlack; ProDelimMono : LtGrayOnBlack;
          SelItemColor   : WhiteOnGreen; SelItemMono : BlackOnLtGray;
          ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
          HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
          AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
          AltSelItemColor : WhiteOnGreen; AltSelItemMono : BlackOnLtGray;
          FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
          FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
          FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
          UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
          SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
          MouseColor     : WhiteOnCyan; MouseMono : BlackOnLtGray
          );

    PopupColorSet  : ColorSet = (
         TextColor      : YellowOnCyan; TextMono : WhiteOnBlack;
         CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
         FrameColor     : BlackOnCyan; FrameMono : LtGrayOnBlack;
         HeaderColor    : BlackOnCyan; HeaderMono : BlackOnLtGray;
         ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
         HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
         PromptColor    : WhiteOnCyan; PromptMono : LtGrayOnBlack;
         SelPromptColor : WhiteOnCyan; SelPromptMono : LtGrayOnBlack;
         ProPromptColor : DkGrayOnCyan; ProPromptMono : LtGrayOnBlack;
         FieldColor     : YellowOnCyan; FieldMono : LtGrayOnBlack;
         SelFieldColor  : YellowOnBlue; SelFieldMono : WhiteOnBlack;
         ProFieldColor  : DkGrayOnCyan; ProFieldMono : LtGrayOnBlack;
         ScrollBarColor : CyanOnBlue; ScrollBarMono : LtGrayOnBlack;
         SliderColor    : CyanOnBlue; SliderMono : WhiteOnBlack;
         HotSpotColor   : BlackOnCyan; HotSpotMono : BlackOnLtGray;
         BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
         MarkerColor    : WhiteOnCyan; MarkerMono : BlackOnLtGray;
         DelimColor     : YellowOnBlue; DelimMono : WhiteOnBlack;
         SelDelimColor  : BlueOnCyan; SelDelimMono : WhiteOnBlack;
         ProDelimColor  : YellowOnBlue; ProDelimMono : WhiteOnBlack;
         SelItemColor   : YellowOnBlue; SelItemMono : BlackOnLtGray;
         ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
         HighItemColor  : WhiteOnCyan; HighItemMono : WhiteOnBlack;
         AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
         AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
         FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
         FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
         FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
         UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
         SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
         MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
         );

    FDialogColors  : ColorSet = (
         TextColor      : BlackOnLtGray; TextMono : BlackOnLtGray;
         CtrlColor      : LtGreenOnCyan; CtrlMono : DkGrayOnBlack;
         FrameColor     : WhiteOnLtGray; FrameMono : BlackOnLtGray;
         HeaderColor    : WhiteOnLtGray; HeaderMono : BlackOnLtGray;
         ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnBlack;
         HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
         PromptColor    : BlackOnLtGray; PromptMono : BlackOnLtGray;
         SelPromptColor : WhiteOnLtGray; SelPromptMono : BlackOnLtGray;
         ProPromptColor : BlackOnLtGray; ProPromptMono : BlackOnLtGray;
         FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
         SelFieldColor  : WhiteOnBlue; SelFieldMono : WhiteOnBlack;
         ProFieldColor  : BlackOnLtGray; ProFieldMono : BlackOnLtGray;
         ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
         SliderColor    : LtGrayOnBlue; SliderMono : WhiteOnBlack;
         HotSpotColor   : LtGrayOnBlue; HotSpotMono : WhiteOnBlack;
         BlockColor     : YellowOnBlue; BlockMono : WhiteOnBlack;
         MarkerColor    : WhiteOnBlue; MarkerMono : BlackOnLtGray;
         DelimColor     : WhiteOnLtGray; DelimMono : WhiteOnBlack;
         SelDelimColor  : BlueOnBlue; SelDelimMono : WhiteOnBlack;
         ProDelimColor  : WhiteOnLtGray; ProDelimMono : WhiteOnBlack;
         SelItemColor   : WhiteOnGreen; SelItemMono : BlackOnLtGray;
         ProItemColor   : LtGrayOnLtGray; ProItemMono : LtGrayOnBlack;
         HighItemColor  : WhiteOnLtGray; HighItemMono : WhiteOnBlack;
         AltItemColor   : YellowOnCyan; AltItemMono : WhiteOnBlack;
         AltSelItemColor : WhiteOnGreen; AltSelItemMono : BlackOnLtGray;
         FlexAHelpColor : WhiteOnLtGray; FlexAHelpMono : WhiteOnBlack;
         FlexBHelpColor : WhiteOnLtGray; FlexBHelpMono : WhiteOnBlack;
         FlexCHelpColor : LtCyanOnLtGray; FlexCHelpMono : BlackOnLtGray;
         UnselXrefColor : WhiteOnLtGray; UnselXrefMono : LtBlueOnBlack;
         SelXrefColor   : WhiteOnLtBlue; SelXRefMono : BlackOnLtGray;
         MouseColor : WhiteOnRed; MouseMono : BlackOnLtGray);

    {blue scheme dialog}
    EDialogColors  : ColorSet = (
         TextColor      : WhiteOnBlue; TextMono : BlackOnLtGray;
         CtrlColor      : LtGreenOnCyan; CtrlMono : DkGrayOnBlack;
         FrameColor     : CyanOnBlue; FrameMono : BlackOnLtGray;
         HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
         ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnBlack;
         HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
         PromptColor    : YellowOnBlue; PromptMono : BlackOnLtGray;
         SelPromptColor : WhiteOnBlue; SelPromptMono : BlackOnLtGray;
         ProPromptColor : DkGrayOnBlue; ProPromptMono : BlackOnLtGray;
         FieldColor     : WhiteOnCyan; FieldMono : LtGrayOnBlack;
         SelFieldColor  : BlackOnLtCyan; SelFieldMono : WhiteOnBlack;
         ProFieldColor  : DkGrayOnCyan; ProFieldMono : BlackOnLtGray;
         ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
         SliderColor    : LtGrayOnBlue; SliderMono : WhiteOnBlack;
         HotSpotColor   : LtGrayOnBlue; HotSpotMono : WhiteOnBlack;
         BlockColor     : YellowOnBlue; BlockMono : WhiteOnBlack;
         MarkerColor    : WhiteOnBlue; MarkerMono : BlackOnLtGray;
         DelimColor     : WhiteOnLtGray; DelimMono : WhiteOnBlack;
         SelDelimColor  : BlueOnBlue; SelDelimMono : WhiteOnBlack;
         ProDelimColor  : WhiteOnLtGray; ProDelimMono : WhiteOnBlack;
         SelItemColor   : WhiteOnGreen; SelItemMono : BlackOnLtGray;
         ProItemColor   : LtGrayOnLtGray; ProItemMono : LtGrayOnBlack;
         HighItemColor  : WhiteOnRed; HighItemMono : WhiteOnBlack;
         AltItemColor   : YellowOnCyan; AltItemMono : WhiteOnBlack;
         AltSelItemColor : WhiteOnGreen; AltSelItemMono : BlackOnLtGray;
         FlexAHelpColor : WhiteOnRed; FlexAHelpMono : WhiteOnBlack;
         FlexBHelpColor : WhiteOnRed; FlexBHelpMono : WhiteOnBlack;
         FlexCHelpColor : LtCyanOnLtGray; FlexCHelpMono : BlackOnLtGray;
         UnselXrefColor : WhiteOnLtGray; UnselXrefMono : LtBlueOnBlack;
         SelXrefColor   : WhiteOnLtBlue; SelXRefMono : BlackOnLtGray;
         MouseColor : WhiteOnRed; MouseMono : BlackOnLtGray);

    {blue scheme dialog}
    dEColors       : DialogColorSet = (
              HiPromptColor  : WhiteOnRed; HiPromptMono : WhiteOnBlack;
              ButtonColor    : BlackOnGreen; ButtonMono : LtGrayOnBlack;
              DefButtonColor : LtCyanOnGreen; DefButtonMono : LtGrayOnBlack;
              HiButtonColor  : YellowOnGreen; HiButtonMono : WhiteOnBlack;
              SelButtonColor : WhiteOnGreen; SelButtonMono : WhiteOnBlack;
              ProButtonColor : BlackOnLtGray; ProButtonMono : BlackOnLtGray;
              BtnShadowColor : BlackOnBlue; BtnShadowMono : BlackOnLtGray;
              ClusterColor   : BlackOnCyan; ClusterMono : LtGrayOnBlack;
              ProClusterColor : DkGrayOnCyan; ProClusterMono : LtGrayOnBlack; {!! 06.10.96}
              HiClusterColor : YellowOnCyan; HiClusterMono : WhiteOnBlack;
              SelClusterColor : WhiteOnCyan; SelClusterMono : WhiteOnBlack);

    YesNoColors    : ColorSet = (
           TextColor      : YellowOnBlue; TextMono : WhiteOnBlack;
           CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
           FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
           HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
           ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
           HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
           PromptColor    : YellowOnBlue; PromptMono : LtGrayOnBlack;
           SelPromptColor : YellowOnBlue; SelPromptMono : LtGrayOnBlack;
           ProPromptColor : YellowOnBlue; ProPromptMono : LtGrayOnBlack;
           FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
           SelFieldColor  : YellowOnBlue; SelFieldMono : WhiteOnBlack;
           ProFieldColor  : YellowOnBlue; ProFieldMono : LtGrayOnBlack;
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
           SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
           MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
           );

    esPLColors     : ColorSet = (
            TextColor      : YellowOnBlue; TextMono : WhiteOnBlack;
            CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
            FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
            HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
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
            SelItemColor   : YellowOnCyan; SelItemMono : BlackOnLtGray;
            ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
            HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
            AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
            AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
            FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
            FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
            FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
            UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
            SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
            MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
            );

    esPruColors    : ColorSet = (
           TextColor      : YellowOnBlue; TextMono : WhiteOnBlack;
           CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
           FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
           HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
           ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
           HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
           PromptColor    : LtGrayOnBlue; PromptMono : LtGrayOnBlack;
           SelPromptColor : LtGrayOnBlue; SelPromptMono : LtGrayOnBlack;
           ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
           FieldColor     : YellowOnCyan; FieldMono : LtGrayOnBlack;
           SelFieldColor  : BlackOnCyan; SelFieldMono : WhiteOnBlack;
           ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
           ScrollBarColor : CyanOnBlue; ScrollBarMono : LtGrayOnBlack;
           SliderColor    : CyanOnBlue; SliderMono : WhiteOnBlack;
           HotSpotColor   : BlackOnCyan; HotSpotMono : BlackOnLtGray;
           BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
           MarkerColor    : WhiteOnCyan; MarkerMono : BlackOnLtGray;
           DelimColor     : YellowOnBlue; DelimMono : WhiteOnBlack;
           SelDelimColor  : YellowOnBlue; SelDelimMono : WhiteOnBlack;
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

    esEmpColors    : ColorSet = (
           TextColor      : YellowOnBlue; TextMono : WhiteOnBlack;
           CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
           FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
           HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
           ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
           HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
           PromptColor    : LtGrayOnBlue; PromptMono : LtGrayOnBlack;
           SelPromptColor : LtGrayOnBlue; SelPromptMono : LtGrayOnBlack;
           ProPromptColor : LtCyanOnBlue; ProPromptMono : LtGrayOnBlack;
           FieldColor     : YellowOnBlue; FieldMono : LtGrayOnBlack;
           SelFieldColor  : BlueOnCyan; SelFieldMono : WhiteOnBlack;
           ProFieldColor  : LtCyanOnBlue; ProFieldMono : LtGrayOnBlack;
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
           SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
           MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
           );

    esInvColors    : ColorSet = (
           TextColor      : YellowOnBlue; TextMono : WhiteOnBlack;
           CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
           FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
           HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
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
             ProItemColor   : RedOnCyan; ProItemMono : LtGrayOnBlack;
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

    FbColors3      : ColorSet = (
             TextColor      : WhiteOnMagenta; TextMono : LtGrayOnBlack;
             CtrlColor      : YellowOnCyan; CtrlMono : BlackOnLtGray;
             FrameColor     : WhiteOnRed; FrameMono : WhiteOnBlack;
             HeaderColor    : YellowOnCyan; HeaderMono : BlackOnLtGray;
             ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnLtGray;
             HighlightColor : YellowOnRed; HighlightMono : WhiteOnBlack;
             PromptColor    : LtCyanOnBlue; PromptMono : LtGrayOnBlack;
             SelPromptColor : LtCyanOnBlue; SelPromptMono : LtGrayOnBlack;
             ProPromptColor : WhiteOnMagenta; ProPromptMono : LtGrayOnBlack;
             FieldColor     : WhiteOnMagenta; FieldMono : LtGrayOnBlack;
             SelFieldColor  : BlackOnCyan; SelFieldMono : BlackOnLtGray;
             ProFieldColor  : YellowOnMagenta; ProFieldMono : LtGrayOnBlack;
             {ProFieldColor   : YellowOnGreen;  ProFieldMono   : BlackOnLtGray;}
             ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
             SliderColor    : LtGrayOnBlue; SliderMono : LtGrayOnBlack;
             HotSpotColor   : BlueOnLtGray; HotSpotMono : LtGrayOnBlack;
             BlockColor     : WhiteOnBlack; BlockMono : WhiteOnBlack;
             MarkerColor    : WhiteOnBlack; MarkerMono : BlackOnLtGray;
             DelimColor     : YellowOnMagenta; DelimMono : LtGrayOnBlack;
             SelDelimColor  : YellowOnMagenta; SelDelimMono : LtGrayOnBlack;
             {ProDelimColor   : LtCyanOnBlue;   ProDelimMono   : LtGrayOnBlack;}
             ProDelimColor  : YellowOnMagenta; ProDelimMono : BlackOnBlack;
             SelItemColor   : WhiteOnBlue; SelItemMono : BlackOnLtGray;
             ProItemColor   : YellowOnBlue; ProItemMono : LtGrayOnBlack;
             HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
             AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
             AltSelItemColor : WhiteOnMagenta; AltSelItemMono : BlackOnLtGray;
             FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
             FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
             FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
             UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
             SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
             MouseColor     : LtGreenOnRed; MouseMono : BlackOnLtGray
             );

    FBColors4      : ColorSet = (
             TextColor      : WhiteOnMagenta; TextMono : LtGrayOnBlack;
             CtrlColor      : YellowOnCyan; CtrlMono : BlackOnLtGray;
             FrameColor     : WhiteOnMagenta; FrameMono : WhiteOnBlack;
             HeaderColor    : WhiteOnMagenta; HeaderMono : BlackOnLtGray;
             ShadowColor    : DkGrayOnBlack; ShadowMono : BlackOnLtGray;
             HighlightColor : YellowOnRed; HighlightMono : WhiteOnBlack;
             PromptColor    : LtCyanOnBlue; PromptMono : LtGrayOnBlack;
             SelPromptColor : LtCyanOnBlue; SelPromptMono : LtGrayOnBlack;
             ProPromptColor : WhiteOnMagenta; ProPromptMono : LtGrayOnBlack;
             FieldColor     : WhiteOnBlue; FieldMono : LtGrayOnBlack;
             SelFieldColor  : BlackOnCyan; SelFieldMono : BlackOnLtGray;
             ProFieldColor  : LtMagentaOnMagenta; ProFieldMono : LtGrayOnBlack;
             {ProFieldColor   : YellowOnGreen;  ProFieldMono   : BlackOnLtGray;}
             ScrollBarColor : LtGrayOnBlue; ScrollBarMono : LtGrayOnBlack;
             SliderColor    : LtGrayOnBlue; SliderMono : LtGrayOnBlack;
             HotSpotColor   : BlueOnLtGray; HotSpotMono : LtGrayOnBlack;
             BlockColor     : WhiteOnBlack; BlockMono : WhiteOnBlack;
             MarkerColor    : WhiteOnBlack; MarkerMono : BlackOnLtGray;
             DelimColor     : YellowOnMagenta; DelimMono : LtGrayOnBlack;
             SelDelimColor  : YellowOnMagenta; SelDelimMono : LtGrayOnBlack;
             {ProDelimColor   : LtCyanOnBlue;   ProDelimMono   : LtGrayOnBlack;}
             ProDelimColor  : YellowOnMagenta; ProDelimMono : BlackOnBlack;
             SelItemColor   : WhiteOnBlue; SelItemMono : BlackOnLtGray;
             ProItemColor   : YellowOnBlue; ProItemMono : LtGrayOnBlack;
             HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
             AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
             AltSelItemColor : WhiteOnMagenta; AltSelItemMono : BlackOnLtGray;
             FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
             FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
             FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
             UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
             SelXrefColor   : WhiteOnMagenta; SelXRefMono : BlackOnLtGray;
             MouseColor     : LtGreenOnRed; MouseMono : BlackOnLtGray
             );

    esCmpColors    : ColorSet = (
           TextColor      : YellowOnBlue; TextMono : WhiteOnBlack;
           CtrlColor      : YellowOnBlue; CtrlMono : WhiteOnBlack;
           FrameColor     : CyanOnBlue; FrameMono : LtGrayOnBlack;
           HeaderColor    : WhiteOnCyan; HeaderMono : BlackOnLtGray;
           ShadowColor    : DkGrayOnBlack; ShadowMono : WhiteOnBlack;
           HighlightColor : WhiteOnRed; HighlightMono : BlackOnLtGray;
           PromptColor    : LtGrayOnBlue; PromptMono : LtGrayOnBlack;
           SelPromptColor : LtGrayOnBlue; SelPromptMono : LtGrayOnBlack;
           ProPromptColor : LtGrayOnBlue; ProPromptMono : LtGrayOnBlack;
           FieldColor     : BlackOnCyan; FieldMono : LtGrayOnBlack;
           SelFieldColor  : YellowOnCyan; SelFieldMono : WhiteOnBlack;
           ProFieldColor  : LtGrayOnBlue; ProFieldMono : LtGrayOnBlack;
           ScrollBarColor : CyanOnBlue; ScrollBarMono : LtGrayOnBlack;
           SliderColor    : CyanOnBlue; SliderMono : WhiteOnBlack;
           HotSpotColor   : BlackOnCyan; HotSpotMono : BlackOnLtGray;
           BlockColor     : YellowOnCyan; BlockMono : WhiteOnBlack;
           MarkerColor    : WhiteOnCyan; MarkerMono : BlackOnLtGray;
           DelimColor     : YellowOnBlue; DelimMono : WhiteOnBlack;
           SelDelimColor  : YellowOnBlue; SelDelimMono : WhiteOnBlack;
           ProDelimColor  : YellowOnBlue; ProDelimMono : WhiteOnBlack;
           SelItemColor   : YellowOnBlue; SelItemMono : BlackOnLtGray;
           ProItemColor   : LtGrayOnBlue; ProItemMono : LtGrayOnBlack;
           HighItemColor  : WhiteOnBlue; HighItemMono : WhiteOnBlack;
           AltItemColor   : WhiteOnBlue; AltItemMono : WhiteOnBlack;
           AltSelItemColor : WhiteOnCyan; AltSelItemMono : BlackOnLtGray;
           FlexAHelpColor : WhiteOnBlue; FlexAHelpMono : WhiteOnBlack;
           FlexBHelpColor : WhiteOnBlue; FlexBHelpMono : WhiteOnBlack;
           FlexCHelpColor : LtCyanOnBlue; FlexCHelpMono : BlackOnLtGray;
           UnselXrefColor : YellowOnBlue; UnselXrefMono : LtBlueOnBlack;
           SelXrefColor   : WhiteOnCyan; SelXRefMono : BlackOnLtGray;
           MouseColor     : WhiteOnRed; MouseMono : BlackOnLtGray
           );

    NormalColors   : ColorSet = (
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

    dColors        : DialogColorSet = (
               HiPromptColor  : WhiteOnLtGray; HiPromptMono : WhiteOnBlack;
               ButtonColor    : BlackOnGreen; ButtonMono : LtGrayOnBlack;
               DefButtonColor : LtCyanOnGreen; DefButtonMono : LtGrayOnBlack;
               HiButtonColor  : YellowOnGreen; HiButtonMono : WhiteOnBlack;
               SelButtonColor : WhiteOnGreen; SelButtonMono : WhiteOnBlack;
               ProButtonColor : BlackOnLtGray; ProButtonMono : BlackOnLtGray;
               BtnShadowColor : BlackOnLtGray; BtnShadowMono : BlackOnLtGray;
               ClusterColor   : BlackOnCyan; ClusterMono : LtGrayOnBlack;
               ProClusterColor : DkGrayOnCyan {BlackOnLtGray} ; ProClusterMono : LtGrayOnBlack; {!! 06.10.96}
               HiClusterColor : YellowOnCyan; HiClusterMono : WhiteOnBlack;
               SelClusterColor : WhiteOnCyan; SelClusterMono : WhiteOnBlack);


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
    (*
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
    *)
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
