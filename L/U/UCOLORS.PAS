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
{$A-,V-,F+,O+}
UNIT UColors;

    {------------------------------------------------------------------}
    { (C) 1990 NewsMaker Systems                                       }
    { Defines Color schemes for NEN Windows. Each Color procedure sets }
    { the contents of NENColorSet, NENDialogSet and NENFillChar.       }
    { Note that only Color values are set, Monochrome values are set   }
    { during unit initialization.                                      }
    {------------------------------------------------------------------}

INTERFACE

USES
    OpCtrl,
    OpCRT,
    OpCol16                       {,
                                                QGlobal} ;

VAR
    NENColorSet    : ColorSet;    { Basic Window color set      }
    NENDialogSet   : DialogColorSet; { Dialog box color extensions }
    NENFillChar    : CHAR;        { Window Fill character       }

TYPE
    DisplayType    = (Color, Mono, LCD, Plasma);

CONST
    MouseChar      : CHAR = #04;
    DisplayMode    : DisplayType = Color; { UColors will remap other modes }


TYPE
    SchemeProc     = PROCEDURE;

PROCEDURE GetScheme(Scheme         : SchemeProc;
                    VAR Colors     : ColorSet;
                    VAR dColors    : DialogColorSet);
PROCEDURE GetCScheme(Scheme         : SchemeProc;
                     VAR Colors     : ColorSet);
PROCEDURE GetDScheme(Scheme         : SchemeProc;
                     VAR dColors    : DialogColorSet);


PROCEDURE White_Scheme;
PROCEDURE Green_Scheme;
PROCEDURE Cyan_Scheme;
PROCEDURE Red_Scheme;
PROCEDURE Black_Scheme;
PROCEDURE Gray_Scheme;
PROCEDURE Mauve_Scheme;
PROCEDURE Orange_Scheme;
PROCEDURE PlainWhite_Scheme;
PROCEDURE Yellow_Scheme;
PROCEDURE BrightYellow_Scheme;
PROCEDURE DarkYellow_Scheme;
PROCEDURE Copyright_Scheme;
PROCEDURE Calculator_Scheme;
PROCEDURE SubWindow_Scheme;
PROCEDURE Dialog_Scheme;
PROCEDURE Help_Scheme;
PROCEDURE Alarm_Colors;
PROCEDURE Blue_scheme;
PROCEDURE MenuColors;
PROCEDURE TextColors;
PROCEDURE FileColors;
PROCEDURE ErrorColors;
PROCEDURE Default_Scheme;
PROCEDURE Forms_Scheme;
PROCEDURE Mail_Scheme;
PROCEDURE Reply_Scheme;
PROCEDURE Macro_Scheme;
PROCEDURE Style_Scheme;
PROCEDURE Debug_Scheme;
PROCEDURE Comm_Scheme;
PROCEDURE Device_Scheme;
PROCEDURE Installation_Scheme;
PROCEDURE MainMenu_Scheme;
PROCEDURE SubMenu_Scheme;
PROCEDURE Install_Scheme;
PROCEDURE Copy_Scheme;
PROCEDURE Message_Scheme;
PROCEDURE Server_Scheme;
PROCEDURE VTRCart_Scheme;
PROCEDURE RedDialog_Scheme;
PROCEDURE OproDialog_Scheme;
PROCEDURE DropBox_Scheme;
PROCEDURE KBlue_Scheme;
PROCEDURE KGreen_Scheme;
PROCEDURE KCyan_Scheme;
PROCEDURE KRed_Scheme;
PROCEDURE KMagenta_Scheme;
PROCEDURE KBrown_Scheme;
PROCEDURE KLtGray_Scheme;

IMPLEMENTATION

CONST Gold     = Brown;

    PROCEDURE LCD_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := LtGrayOnBlack;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnBlue;
            HeaderColor := BlackOnWhite;
            ShadowColor := LtBlueOnBrown;
            HighlightColor := RedOnBlack;
            PromptColor := LtGrayOnBlack;
            SelPromptColor := RedOnBlack;
            ProPromptColor := BlueOnBlack;
            FieldColor := BlueOnBlack;
            SelFieldColor := RedOnBlack;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := LtBlueOnWhite;
            HotSpotColor := BlackOnBlue;

            BlockColor := BlackOnWhite;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := WhiteOnBlack;
            ButtonColor := BlueOnCyan;
            DefButtonColor := BlackOnCyan;
            HiButtonColor := BlackOnCyan;
            SelButtonColor := BlackOnWhite;
            ProButtonColor := LtGrayOnCyan;
            BtnShadowColor := LtBlueOnBlack;
            ClusterColor := BlackOnWhite;
            ProClusterColor := LtGrayOnWhite;
            HiClusterColor := BlackOnWhite;
            SelClusterColor := BlackOnLtCyan;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Plasma_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlueOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := LtBlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnWhite;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := LtRedOnWhite;
            ButtonColor := WhiteOnCyan;
            DefButtonColor := YellowOnCyan;
            HiButtonColor := YellowOnCyan;
            SelButtonColor := YellowOnCyan;
            ProButtonColor := LtGrayOnCyan;
            BtnShadowColor := DkGrayOnWhite;
            ClusterColor := BlackOnWhite;
            ProClusterColor := LtGrayOnWhite;
            HiClusterColor := BlackOnWhite;
            SelClusterColor := BlackOnLtCyan;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE Mono_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlueOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := LtBlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnWhite;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := LtRedOnWhite;
            ButtonColor := WhiteOnCyan;
            DefButtonColor := YellowOnCyan;
            HiButtonColor := YellowOnCyan;
            SelButtonColor := YellowOnCyan;
            ProButtonColor := LtGrayOnCyan;
            BtnShadowColor := DkGrayOnWhite;
            ClusterColor := BlackOnWhite;
            ProClusterColor := LtGrayOnWhite;
            HiClusterColor := BlackOnWhite;
            SelClusterColor := BlackOnLtCyan;
        END;
        NENFillChar := #$0;
    END;

    FUNCTION NonStandardDisplay : BOOLEAN;
    BEGIN
        CASE DisplayMode OF
            LCD : LCD_Scheme;
            Plasma : Plasma_Scheme;
            Mono : Mono_Scheme;
        END;
        NonStandardDisplay := DisplayMode <> Color;
    END;

    PROCEDURE White_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := LtGrayOnWhite;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlueOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := LtBlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnWhite;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := LtRedOnWhite;
            ButtonColor := WhiteOnCyan;
            DefButtonColor := YellowOnCyan;
            HiButtonColor := YellowOnCyan;
            SelButtonColor := YellowOnCyan;
            ProButtonColor := LtGrayOnCyan;
            BtnShadowColor := DkGrayOnWhite;
            ClusterColor := BlackOnWhite;
            ProClusterColor := LtGrayOnWhite;
            HiClusterColor := BlackOnWhite;
            SelClusterColor := BlackOnLtCyan;
        END;
        NENFillChar := #$0;
    END;


    PROCEDURE Green_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnGreen;
            CtrlColor := YellowOnGreen;
            FrameColor := BlackOnGreen;
            HeaderColor := WhiteOnGreen;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := YellowOnGreen;
            PromptColor := DkGrayOnGreen;
            SelPromptColor := BlackOnGreen;
            ProPromptColor := LtGrayOnGreen;
            FieldColor := BlackOnGreen;
            SelFieldColor := BlackOnLtGreen;
            ProFieldColor := DkGrayOnGreen;
            ScrollBarColor := BlackOnGreen;
            SliderColor := YellowOnGreen;
            HotSpotColor := LtRedOnGreen;

            BlockColor := GreenOnYellow;
            MarkerColor := YellowOnGreen;
            DelimColor := BlackOnGreen;
            SelDelimColor := RedOnGreen;
            ProDelimColor := DkGrayOnGreen;
            SelItemColor := BlackOnLtGreen;
            ProItemColor := DkGrayOnGreen;
            HighItemColor := RedOnGreen;
            AltItemColor := BlackOnGreen;
            AltSelItemColor := LtCyanOnGreen;
            FlexAHelpColor := BlueOnGreen;
            FlexBHelpColor := GreenOnGreen;
            FlexCHelpColor := RedOnGreen;
            UnselXrefColor := BlueOnGreen;
            SelXrefColor := GreenOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnLtGray;
            DefButtonColor := YellowOnLtGray;
            HiButtonColor := WhiteOnLtGray;
            SelButtonColor := YellowOnLtGray;
            ProButtonColor := LtGreenOnLtGray;
            BtnShadowColor := BlackOnGreen;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Cyan_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnCyan;
            CtrlColor := CyanOnBlack;
            FrameColor := BlackOnCyan;
            HeaderColor := BlueOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnCyan;
            SelPromptColor := BlackOnCyan;
            ProPromptColor := BlackOnCyan;
            FieldColor := BlackOnCyan;
            SelFieldColor := BlackOnMagenta;
            ProFieldColor := WhiteOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := LtCyanOnBlack;
            HotSpotColor := LtRedOnCyan;

            BlockColor := BlackOnCyan;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := DkGrayOnCyan;
            SelItemColor := WhiteOnMagenta;
            ProItemColor := DkGrayOnCyan;
            HighItemColor := RedOnCyan;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := LtCyanOnCyan;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := YellowOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := WhiteOnCyan;
            SelXrefColor := WhiteOnMagenta;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := LtGrayOnBlue;
            DefButtonColor := YellowOnBlue;
            HiButtonColor := WhiteOnBlue;
            SelButtonColor := YellowOnBlue;
            ProButtonColor := LtBlueOnBlue;
            BtnShadowColor := BlackOnCyan;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Device_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnCyan;
            CtrlColor := CyanOnBlack;
            FrameColor := BlackOnCyan;
            HeaderColor := BlueOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := BlackOnCyan;
            SelPromptColor := WhiteOnCyan;
            ProPromptColor := BlackOnCyan;
            FieldColor := WhiteOnBlue;
            SelFieldColor := YellowOnBlue;
            ProFieldColor := WhiteOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := LtCyanOnBlack;
            HotSpotColor := LtRedOnCyan;

            BlockColor := BlackOnCyan;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := BlackOnCyan;
            SelItemColor := BlackOnBrown;
            ProItemColor := BlackOnCyan;
            HighItemColor := RedOnCyan;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := BlackOnBrown;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := GreenOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := BlueOnCyan;
            SelXrefColor := CyanOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnCyan;
            ButtonColor := LtGrayOnBlue;
            DefButtonColor := YellowOnBlue;
            HiButtonColor := WhiteOnBlue;
            SelButtonColor := YellowOnBlue;
            ProButtonColor := LtBlueOnBlue;
            BtnShadowColor := BlackOnCyan;
            ClusterColor := BlackOnLtGray;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnLtGray;
            SelClusterColor := YellowOnLtGray;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Red_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := WhiteOnRed;
            CtrlColor := LtCyanOnRed;
            FrameColor := LtGrayOnRed;
            HeaderColor := WhiteOnLtRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnRed;
            SelPromptColor := BlackOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := WhiteOnRed;
            SelFieldColor := RedOnYellow;
            ProFieldColor := DkGrayOnRed;
            ScrollBarColor := BlackOnRed;
            SliderColor := YellowOnRed;
            HotSpotColor := LtGreenOnRed;

            BlockColor := BlackOnRed;
            MarkerColor := YellowOnRed;
            DelimColor := BlackOnRed;
            SelDelimColor := WhiteOnRed;
            ProDelimColor := DkGrayOnRed;
            SelItemColor := BlackOnYellow;
            ProItemColor := DkGrayOnRed;
            HighItemColor := YellowOnRed;
            AltItemColor := BlackOnRed;
            AltSelItemColor := LtCyanOnRed;
            FlexAHelpColor := BlueOnRed;
            FlexBHelpColor := GreenOnRed;
            FlexCHelpColor := WhiteOnRed;
            UnselXrefColor := BlueOnRed;
            SelXrefColor := RedOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnWhite;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE Black_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := CyanOnBlack;
            CtrlColor := LtCyanOnBlack;
            FrameColor := WhiteOnBlack;
            HeaderColor := YellowOnBlack;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := YellowOnBlack;
            PromptColor := DkGrayOnBlack;
            SelPromptColor := WhiteOnBlack;
            ProPromptColor := WhiteOnBlack;
            FieldColor := WhiteOnBlack;
            SelFieldColor := BlackOnLtCyan;
            ProFieldColor := WhiteOnBlack;
            ScrollBarColor := BlueOnBlack;
            SliderColor := RedOnBlack;
            HotSpotColor := RedOnBlack;

            BlockColor := BlueOnBlack;
            MarkerColor := YellowOnBlack;
            DelimColor := WhiteOnBlack;
            SelDelimColor := RedOnBlack;
            ProDelimColor := DkGrayOnBlack;
            SelItemColor := WhiteOnMagenta;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := YellowOnBlack;
            AltItemColor := YellowOnBlack;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnWhite;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE Gray_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnLtGray;
            CtrlColor := WhiteOnLtGray;
            FrameColor := BlackOnLtGray;
            HeaderColor := BlackOnLtGray;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := RedOnLtGray;
            PromptColor := BlackOnLtGray;
            SelPromptColor := WhiteOnLtGray;
            ProPromptColor := BlackOnLtGray;
            FieldColor := BlackOnGreen;
            SelFieldColor := WhiteOnGreen;
            ProFieldColor := BlueOnLtGray;
            ScrollBarColor := BlackOnCyan;
            SliderColor := WhiteOnCyan;
            HotSpotColor := RedOnLtGray;

            BlockColor := BlackOnLtGray;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnGreen;
            ProItemColor := DkGrayOnLtGray;
            HighItemColor := RedOnLtGray;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := DkGrayOnCyan;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := YellowOnCyan;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE Mauve_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := LtCyanOnBlue;
            CtrlColor := CyanOnBlack;
            FrameColor := BlackOnCyan;
            HeaderColor := BlackOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := LtCyanOnCyan;
            PromptColor := DkGrayOnCyan;
            SelPromptColor := BlackOnCyan;
            ProPromptColor := LtGrayOnCyan;
            FieldColor := BlackOnCyan;
            SelFieldColor := BlackOnYellow;
            ProFieldColor := DkGrayOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := MagentaOnCyan;
            HotSpotColor := RedOnCyan;

            BlockColor := CyanOnMagenta;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := DkGrayOnCyan;
            SelItemColor := LtCyanOnMagenta;
            ProItemColor := DkGrayOnCyan;
            HighItemColor := RedOnCyan;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := LtCyanOnCyan;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := GreenOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := BlueOnCyan;
            SelXrefColor := CyanOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := CyanOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnCyan;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := CyanOnCyan;
            SelClusterColor := CyanOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Orange_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnCyan;
            CtrlColor := CyanOnBlack;
            FrameColor := BlackOnCyan;
            HeaderColor := WhiteOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnCyan;
            SelPromptColor := BlackOnCyan;
            ProPromptColor := LtGrayOnCyan;
            FieldColor := BlackOnCyan;
            SelFieldColor := BlackOnMagenta;
            ProFieldColor := DkGrayOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := WhiteOnCyan;
            HotSpotColor := RedOnCyan;

            BlockColor := YellowOnRed;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := DkGrayOnCyan;
            SelItemColor := BlackOnMagenta;
            ProItemColor := DkGrayOnCyan;
            HighItemColor := RedOnCyan;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := LtCyanOnCyan;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := GreenOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := BlueOnCyan;
            SelXrefColor := CyanOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := CyanOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnCyan;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := CyanOnCyan;
            SelClusterColor := CyanOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE PlainWhite_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlueOnWhite;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlackOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlackOnWhite;
            SelFieldColor := BlackOnGreen;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := BlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := WhiteOnBlack;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnWhite;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE Yellow_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnCyan;
            CtrlColor := YellowOnBlack;
            FrameColor := BlackOnCyan;
            HeaderColor := YellowOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnYellow;
            SelPromptColor := BlackOnYellow;
            ProPromptColor := LtGrayOnYellow;
            FieldColor := BlackOnCyan;
            SelFieldColor := BlackOnMagenta;
            ProFieldColor := DkGrayOnYellow;
            ScrollBarColor := BlackOnCyan;
            SliderColor := WhiteOnCyan;
            HotSpotColor := RedOnCyan;

            BlockColor := CyanOnYellow;
            MarkerColor := YellowOnYellow;
            DelimColor := BlackOnYellow;
            SelDelimColor := RedOnYellow;
            ProDelimColor := DkGrayOnYellow;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnYellow;
            HighItemColor := RedOnYellow;
            AltItemColor := BlackOnYellow;
            AltSelItemColor := LtCyanOnYellow;
            FlexAHelpColor := BlueOnYellow;
            FlexBHelpColor := GreenOnYellow;
            FlexCHelpColor := RedOnYellow;
            UnselXrefColor := BlueOnYellow;
            SelXrefColor := YellowOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnYellow;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := YellowOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE BrightYellow_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnYellow;
            CtrlColor := YellowOnBlack;
            FrameColor := BlackOnYellow;
            HeaderColor := BlackOnYellow;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnYellow;
            SelPromptColor := BlackOnYellow;
            ProPromptColor := LtGrayOnYellow;
            FieldColor := BlackOnYellow;
            SelFieldColor := BlackOnLtRed;
            ProFieldColor := DkGrayOnYellow;
            ScrollBarColor := BlackOnYellow;
            SliderColor := RedOnYellow;
            HotSpotColor := RedOnYellow;

            BlockColor := BlackOnYellow;
            MarkerColor := YellowOnYellow;
            DelimColor := BlackOnYellow;
            SelDelimColor := RedOnYellow;
            ProDelimColor := DkGrayOnYellow;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnYellow;
            HighItemColor := RedOnYellow;
            AltItemColor := BlackOnYellow;
            AltSelItemColor := LtCyanOnYellow;
            FlexAHelpColor := BlueOnYellow;
            FlexBHelpColor := GreenOnYellow;
            FlexCHelpColor := RedOnYellow;
            UnselXrefColor := BlueOnYellow;
            SelXrefColor := YellowOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnYellow;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := YellowOnMagenta;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE DarkYellow_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnBrown;
            CtrlColor := BrownOnBlack;
            FrameColor := BlackOnBrown;
            HeaderColor := BlueOnYellow;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnBrown;
            SelPromptColor := BlackOnBrown;
            ProPromptColor := LtGrayOnBrown;
            FieldColor := BlackOnBrown;
            SelFieldColor := BlackOnYellow;
            ProFieldColor := DkGrayOnBrown;
            ScrollBarColor := BlackOnBrown;
            SliderColor := WhiteOnBrown;
            HotSpotColor := RedOnBrown;

            BlockColor := BlackOnBrown;
            MarkerColor := YellowOnBrown;
            DelimColor := BlackOnBrown;
            SelDelimColor := RedOnBrown;
            ProDelimColor := DkGrayOnBrown;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnBrown;
            HighItemColor := RedOnBrown;
            AltItemColor := BlackOnBrown;
            AltSelItemColor := LtCyanOnBrown;
            FlexAHelpColor := BlueOnBrown;
            FlexBHelpColor := GreenOnBrown;
            FlexCHelpColor := RedOnBrown;
            UnselXrefColor := BlueOnBrown;
            SelXrefColor := BrownOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := BrownOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnBrown;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := BrownOnCyan;
            SelClusterColor := BrownOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Copyright_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := WhiteOnBlue;
            CtrlColor := WhiteOnBlack;
            FrameColor := WhiteOnBlue;
            HeaderColor := YellowOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnBlue;
            PromptColor := LtGrayOnBlue;
            SelPromptColor := LtGreenOnBlue;
            ProPromptColor := LtGrayOnBlue;
            FieldColor := WhiteOnGreen;
            SelFieldColor := YellowOnGreen;
            ProFieldColor := WhiteOnBlack;
            ScrollBarColor := LtGrayOnBlue;
            SliderColor := WhiteOnBlue;
            HotSpotColor := RedOnBlue;

            BlockColor := BlackOnBlue;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := LtGrayOnBlue;
            HighItemColor := YellowOnBlue;
            AltItemColor := YellowOnBlue;
            AltSelItemColor := BlackOnYellow;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnBlue;
            ClusterColor := LtGrayOnBlue;
            ProClusterColor := BlackOnBlue;
            HiClusterColor := WhiteOnBlue;
            SelClusterColor := YellowOnBlue;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE Calculator_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlackOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := BlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnLtCyan;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnWhite;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Comm_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlackOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := BlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnLtCyan;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnWhite;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE SubWindow_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlackOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := BlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnLtCyan;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnWhite;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Dialog_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlackOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := BlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnLtCyan;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnWhite;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Help_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := WhiteOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlackOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := BlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnLtCyan;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnWhite;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Blue_scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnCyan;
            CtrlColor := CyanOnBlack;
            FrameColor := BlackOnCyan;
            HeaderColor := BlackOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnCyan;
            SelPromptColor := BlackOnCyan;
            ProPromptColor := LtGrayOnCyan;
            FieldColor := BlackOnCyan;
            SelFieldColor := BlackOnMagenta;
            ProFieldColor := DkGrayOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := WhiteOnCyan;
            HotSpotColor := RedOnCyan;

            BlockColor := LtBlueOnCyan;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := DkGrayOnCyan;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnCyan;
            HighItemColor := RedOnCyan;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := LtCyanOnCyan;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := GreenOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := BlueOnCyan;
            SelXrefColor := CyanOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := CyanOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnCyan;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := CyanOnCyan;
            SelClusterColor := CyanOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Default_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnCyan;
            CtrlColor := CyanOnBlack;
            FrameColor := BlackOnCyan;
            HeaderColor := BlackOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnCyan;
            SelPromptColor := BlackOnCyan;
            ProPromptColor := LtGrayOnCyan;
            FieldColor := BlueOnCyan;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := BlueOnCyan;
            HotSpotColor := RedOnCyan;

            BlockColor := BlackOnLtCyan;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := DkGrayOnCyan;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnCyan;
            HighItemColor := RedOnCyan;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := LtCyanOnCyan;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := GreenOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := BlueOnCyan;
            SelXrefColor := CyanOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := CyanOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnCyan;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := CyanOnCyan;
            SelClusterColor := CyanOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Forms_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnCyan;
            CtrlColor := CyanOnBlack;
            FrameColor := BlackOnCyan;
            HeaderColor := BlackOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnCyan;
            SelPromptColor := BlackOnCyan;
            ProPromptColor := LtGrayOnCyan;
            FieldColor := BlueOnCyan;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := BlueOnCyan;
            HotSpotColor := RedOnCyan;

            BlockColor := BlackOnCyan;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := DkGrayOnCyan;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnCyan;
            HighItemColor := RedOnCyan;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := LtCyanOnCyan;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := GreenOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := BlueOnCyan;
            SelXrefColor := CyanOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := CyanOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnCyan;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := CyanOnCyan;
            SelClusterColor := CyanOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Macro_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnBlue;
            CtrlColor := WhiteOnBlue;
            FrameColor := WhiteOnBlue;
            HeaderColor := LtGreenOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := LtGrayOnBlue;
            SelPromptColor := WhiteOnBlue;
            ProPromptColor := LtGrayOnBlue;
            FieldColor := WhiteOnCyan;
            SelFieldColor := BlackOnYellow;
            ProFieldColor := YellowOnBlue;
            ScrollBarColor := BlueOnCyan;
            SliderColor := WhiteOnBlue;
            HotSpotColor := LtRedOnBlue;

            BlockColor := BlackOnYellow;
            MarkerColor := YellowOnBlue;
            DelimColor := BlackOnBlue;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnBlue;
            SelItemColor := BlackOnYellow;
            ProItemColor := DkGrayOnBlue;
            HighItemColor := RedOnBlue;
            AltItemColor := WhiteOnBlue;
            AltSelItemColor := YellowOnBlue;
            FlexAHelpColor := BrownOnBlue;
            FlexBHelpColor := GreenOnBlue;
            FlexCHelpColor := RedOnBlue;
            UnselXrefColor := WhiteOnBlue;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnBlue;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE VTRCart_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnBlue;
            CtrlColor := WhiteOnBlue;
            FrameColor := LtCyanOnBlue;
            HeaderColor := LtGreenOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := LtGrayOnBlue;
            SelPromptColor := WhiteOnBlue;
            ProPromptColor := LtGrayOnBlue;
            FieldColor := WhiteOnCyan;
            SelFieldColor := BlackOnYellow;
            ProFieldColor := YellowOnBlue;
            ScrollBarColor := BlueOnCyan;
            SliderColor := WhiteOnBlue;
            HotSpotColor := LtRedOnBlue;

            BlockColor := BlackOnYellow;
            MarkerColor := YellowOnBlue;
            DelimColor := BlackOnBlue;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnBlue;
            SelItemColor := BlackOnYellow;
            ProItemColor := DkGrayOnBlue;
            HighItemColor := RedOnBlue;
            AltItemColor := WhiteOnBlue;
            AltSelItemColor := YellowOnBlue;
            FlexAHelpColor := BrownOnBlue;
            FlexBHelpColor := GreenOnBlue;
            FlexCHelpColor := RedOnBlue;
            UnselXrefColor := WhiteOnBlue;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnBlue;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Style_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnBlue;
            CtrlColor := WhiteOnBlue;
            FrameColor := WhiteOnBlue;
            HeaderColor := LtGreenOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := LtGrayOnBlue;
            SelPromptColor := WhiteOnBlue;
            ProPromptColor := LtGrayOnBlue;
            FieldColor := WhiteOnCyan;
            SelFieldColor := BlackOnYellow;
            ProFieldColor := YellowOnBlue;
            ScrollBarColor := BlueOnCyan;
            SliderColor := WhiteOnBlue;
            HotSpotColor := LtRedOnBlue;

            BlockColor := BlackOnYellow;
            MarkerColor := YellowOnBlue;
            DelimColor := BlackOnBlue;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnBlue;
            SelItemColor := BlackOnYellow;
            ProItemColor := DkGrayOnBlue;
            HighItemColor := RedOnBlue;
            AltItemColor := WhiteOnBlue;
            AltSelItemColor := YellowOnBlue;
            FlexAHelpColor := BrownOnBlue;
            FlexBHelpColor := GreenOnBlue;
            FlexCHelpColor := RedOnBlue;
            UnselXrefColor := WhiteOnBlue;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnCyan;
            DefButtonColor := YellowOnCyan;
            HiButtonColor := WhiteOnCyan;
            SelButtonColor := LtMagentaOnCyan;
            ProButtonColor := LtCyanOnCyan;
            BtnShadowColor := BlackOnBlue;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Server_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnLtGray;
            CtrlColor := WhiteOnLtGray;
            FrameColor := BlackOnLtGray;
            HeaderColor := BlackOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := RedOnLtGray;
            PromptColor := BlackOnLtGray;
            SelPromptColor := WhiteOnLtGray;
            ProPromptColor := BlackOnLtGray;
            FieldColor := BlackOnGreen;
            SelFieldColor := WhiteOnGreen;
            ProFieldColor := BlackOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := WhiteOnCyan;
            HotSpotColor := RedOnLtGray;

            BlockColor := BlackOnLtGray;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnGreen;
            ProItemColor := DkGrayOnLtGray;
            HighItemColor := RedOnLtGray;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnLtGray;
            DefButtonColor := WhiteOnLtGray;
            HiButtonColor := YellowOnLtGray;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := DkGrayOnCyan;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := YellowOnCyan;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE Debug_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnLtGray;
            CtrlColor := YellowOnCyan;
            FrameColor := BlackOnLtGray;
            HeaderColor := BlackOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := RedOnLtGray;
            PromptColor := BlackOnLtGray;
            SelPromptColor := WhiteOnLtGray;
            ProPromptColor := BlackOnLtGray;
            FieldColor := BlackOnGreen;
            SelFieldColor := WhiteOnGreen;
            ProFieldColor := BlackOnCyan;
            ScrollBarColor := BlackOnCyan;
            SliderColor := WhiteOnCyan;
            HotSpotColor := RedOnLtGray;

            BlockColor := BlackOnLtGray;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnGreen;
            ProItemColor := DkGrayOnLtGray;
            HighItemColor := RedOnLtGray;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := DkGrayOnCyan;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := YellowOnCyan;
        END;
        NENFillChar := #$0;
    END;

    PROCEDURE Mail_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := WhiteOnBlack;
            CtrlColor := CyanOnBlack;
            FrameColor := YellowOnBlack;
            HeaderColor := LtGreenOnBlack;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := LtGreenOnBlack;
            PromptColor := LtGrayOnBlack;
            SelPromptColor := WhiteOnBlack;
            ProPromptColor := LtGrayOnBlack;
            FieldColor := YellowOnBlack;
            SelFieldColor := YellowOnBlack;
            ProFieldColor := YellowOnBlack;
            ScrollBarColor := CyanOnBlack;
            SliderColor := WhiteOnBlue;
            HotSpotColor := LtGreenOnBlack;

            BlockColor := BlackOnYellow;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := DkGrayOnCyan;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnCyan;
            HighItemColor := YellowOnBlack;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := LtCyanOnCyan;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := GreenOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := BlueOnCyan;
            SelXrefColor := CyanOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := LtGreenOnBlack;
            ButtonColor := BlackOnCyan;
            DefButtonColor := WhiteOnCyan;
            HiButtonColor := YellowOnCyan;
            SelButtonColor := WhiteOnCyan;
            ProButtonColor := LtCyanOnCyan;
            BtnShadowColor := DkGrayOnBlack;
            ClusterColor := WhiteOnBlack;
            ProClusterColor := DkGrayOnBlack;
            HiClusterColor := LtGreenOnBlack;
            SelClusterColor := WhiteOnBlack;
        END;
        NENFillChar := #$20;
    END;


    PROCEDURE Reply_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := WhiteOnBlack;
            CtrlColor := CyanOnBlack;
            FrameColor := LtGreenOnBlack;
            HeaderColor := YellowOnBlack;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := YellowOnBlack;
            PromptColor := LtGrayOnBlack;
            SelPromptColor := WhiteOnBlack;
            ProPromptColor := LtGrayOnBlack;
            FieldColor := LtGreenOnBlack;
            SelFieldColor := LtGreenOnBlack;
            ProFieldColor := GreenOnBlack;
            ScrollBarColor := CyanOnBlack;
            SliderColor := WhiteOnBlue;
            HotSpotColor := LtRedOnBlack;

            BlockColor := BlackOnYellow;
            MarkerColor := YellowOnCyan;
            DelimColor := BlackOnCyan;
            SelDelimColor := RedOnCyan;
            ProDelimColor := DkGrayOnCyan;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnCyan;
            HighItemColor := LtGreenOnBlack;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := LtCyanOnCyan;
            FlexAHelpColor := BlueOnCyan;
            FlexBHelpColor := GreenOnCyan;
            FlexCHelpColor := RedOnCyan;
            UnselXrefColor := BlueOnCyan;
            SelXrefColor := CyanOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlack;
            ButtonColor := BlackOnGreen;
            DefButtonColor := WhiteOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := LtCyanOnGreen;
            BtnShadowColor := DkGrayOnBlack;
            ClusterColor := WhiteOnBlack;
            ProClusterColor := DkGrayOnBlack;
            HiClusterColor := LtGreenOnBlack;
            SelClusterColor := WhiteOnBlack;
        END;
        NENFillChar := #$20;
    END;

    PROCEDURE Alarm_Colors;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnRed;
            CtrlColor := RedOnBlack;
            FrameColor := BlackOnRed;
            HeaderColor := BlackOnRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnRed;
            SelPromptColor := BlackOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := BlueOnRed;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnRed;
            ScrollBarColor := BlackOnRed;
            SliderColor := BlueOnRed;
            HotSpotColor := RedOnRed;

            BlockColor := BlackOnLtCyan;
            MarkerColor := YellowOnRed;
            DelimColor := BlackOnRed;
            SelDelimColor := RedOnRed;
            ProDelimColor := DkGrayOnRed;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnRed;
            HighItemColor := RedOnRed;
            AltItemColor := BlackOnRed;
            AltSelItemColor := LtCyanOnRed;
            FlexAHelpColor := BlueOnRed;
            FlexBHelpColor := GreenOnRed;
            FlexCHelpColor := RedOnRed;
            UnselXrefColor := BlueOnRed;
            SelXrefColor := RedOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := RedOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnBlue;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := RedOnCyan;
            SelClusterColor := RedOnCyan;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE MenuColors;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnWhite;
            CtrlColor := RedOnBlack;
            FrameColor := BlackOnWhite;
            HeaderColor := BlackOnWhite;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := BlackOnLtCyan;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := BlackOnWhite;
            ProPromptColor := LtGrayOnWhite;
            FieldColor := BlueOnWhite;
            SelFieldColor := BlueOnLtCyan;
            ProFieldColor := DkGrayOnWhite;
            ScrollBarColor := BlackOnWhite;
            SliderColor := BlueOnWhite;
            HotSpotColor := RedOnWhite;

            BlockColor := BlackOnLtCyan;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnBlue;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE TextColors;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnBlue;
            CtrlColor := WhiteOnBlue;
            FrameColor := WhiteOnBlue;
            HeaderColor := LtGreenOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := DkGrayOnBlue;
            SelPromptColor := LtGrayOnBlue;
            ProPromptColor := LtGrayOnBlue;
            FieldColor := LtGrayOnBlue;
            SelFieldColor := YellowOnBlue;
            ProFieldColor := LtGreenOnBlue;
            ScrollBarColor := BlueOnCyan;
            SliderColor := WhiteOnBlue;
            HotSpotColor := LtRedOnBlue;

            BlockColor := BlackOnYellow;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := YellowOnBlue;
            AltItemColor := BlackOnBlue;
            AltSelItemColor := LtCyanOnBlue;
            FlexAHelpColor := BlueOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := BlueOnWhite;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnBlue;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE FileColors;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnBlue;
            CtrlColor := WhiteOnBlue;
            FrameColor := WhiteOnBlue;
            HeaderColor := LtGreenOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := LtGrayOnBlue;
            SelPromptColor := WhiteOnBlue;
            ProPromptColor := LtGrayOnBlue;
            FieldColor := LtGrayOnBlue;
            SelFieldColor := YellowOnBlue;
            ProFieldColor := LtGreenOnBlue;
            ScrollBarColor := BlueOnCyan;
            SliderColor := WhiteOnBlue;
            HotSpotColor := LtRedOnBlue;

            BlockColor := BlackOnBlue;
            MarkerColor := YellowOnBlue;
            DelimColor := BlackOnBlue;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnBlue;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnBlue;
            HighItemColor := RedOnBlue;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := BlackOnYellow;
            FlexAHelpColor := BrownOnBlue;
            FlexBHelpColor := GreenOnBlue;
            FlexCHelpColor := RedOnBlue;
            UnselXrefColor := WhiteOnBlue;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnBlue;
            ClusterColor := BlueOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE ErrorColors;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnRed;
            CtrlColor := WhiteOnRed;
            FrameColor := WhiteOnRed;
            HeaderColor := LtGreenOnRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := LtGrayOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := LtGrayOnRed;
            SelFieldColor := YellowOnRed;
            ProFieldColor := LtGreenOnRed;
            ScrollBarColor := RedOnCyan;
            SliderColor := WhiteOnRed;
            HotSpotColor := LtGreenOnRed;

            BlockColor := BlackOnRed;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := RedOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := RedOnWhite;
            SelXrefColor := WhiteOnRed;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnRed;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := YellowOnGreen;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnRed;
            ClusterColor := RedOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Installation_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnRed;
            CtrlColor := WhiteOnRed;
            FrameColor := WhiteOnRed;
            HeaderColor := LtGreenOnRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := LtGrayOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := LtGrayOnRed;
            SelFieldColor := YellowOnRed;
            ProFieldColor := LtGreenOnRed;
            ScrollBarColor := RedOnCyan;
            SliderColor := WhiteOnRed;
            HotSpotColor := LtGreenOnRed;

            BlockColor := BlackOnRed;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := RedOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := RedOnWhite;
            SelXrefColor := WhiteOnRed;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnRed;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnRed;
            ClusterColor := RedOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE MainMenu_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnRed;
            CtrlColor := WhiteOnRed;
            FrameColor := WhiteOnRed;
            HeaderColor := LtGreenOnRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := LtGrayOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := LtGrayOnRed;
            SelFieldColor := YellowOnRed;
            ProFieldColor := LtGreenOnRed;
            ScrollBarColor := RedOnCyan;
            SliderColor := WhiteOnRed;
            HotSpotColor := LtGreenOnRed;

            BlockColor := BlackOnRed;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := RedOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := RedOnWhite;
            SelXrefColor := WhiteOnRed;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnRed;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnRed;
            ClusterColor := RedOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE SubMenu_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnRed;
            CtrlColor := WhiteOnRed;
            FrameColor := WhiteOnRed;
            HeaderColor := LtGreenOnRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := LtGrayOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := LtGrayOnRed;
            SelFieldColor := YellowOnRed;
            ProFieldColor := LtGreenOnRed;
            ScrollBarColor := RedOnCyan;
            SliderColor := WhiteOnRed;
            HotSpotColor := LtGreenOnRed;

            BlockColor := BlackOnRed;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := RedOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := RedOnWhite;
            SelXrefColor := WhiteOnRed;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnRed;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnRed;
            ClusterColor := RedOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Install_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnRed;
            CtrlColor := WhiteOnRed;
            FrameColor := WhiteOnRed;
            HeaderColor := LtGreenOnRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := LtGrayOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := LtGrayOnRed;
            SelFieldColor := YellowOnRed;
            ProFieldColor := LtGreenOnRed;
            ScrollBarColor := RedOnCyan;
            SliderColor := WhiteOnRed;
            HotSpotColor := LtGreenOnRed;

            BlockColor := BlackOnRed;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := RedOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := RedOnWhite;
            SelXrefColor := WhiteOnRed;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnRed;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnRed;
            ClusterColor := RedOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Copy_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnRed;
            CtrlColor := WhiteOnRed;
            FrameColor := WhiteOnRed;
            HeaderColor := LtGreenOnRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := LtGrayOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := LtGrayOnRed;
            SelFieldColor := YellowOnRed;
            ProFieldColor := LtGreenOnRed;
            ScrollBarColor := RedOnCyan;
            SliderColor := WhiteOnRed;
            HotSpotColor := LtGreenOnRed;

            BlockColor := BlackOnRed;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := RedOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := RedOnWhite;
            SelXrefColor := WhiteOnRed;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnRed;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnRed;
            ClusterColor := RedOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    PROCEDURE Message_Scheme;
    BEGIN
        IF NonStandardDisplay THEN EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnRed;
            CtrlColor := WhiteOnRed;
            FrameColor := WhiteOnRed;
            HeaderColor := LtGreenOnRed;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := DkGrayOnWhite;
            SelPromptColor := LtGrayOnRed;
            ProPromptColor := LtGrayOnRed;
            FieldColor := LtGrayOnRed;
            SelFieldColor := YellowOnRed;
            ProFieldColor := LtGreenOnRed;
            ScrollBarColor := RedOnCyan;
            SliderColor := WhiteOnRed;
            HotSpotColor := LtGreenOnRed;

            BlockColor := BlackOnRed;
            MarkerColor := YellowOnWhite;
            DelimColor := BlackOnWhite;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnWhite;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnWhite;
            HighItemColor := RedOnWhite;
            AltItemColor := BlackOnWhite;
            AltSelItemColor := LtCyanOnWhite;
            FlexAHelpColor := RedOnWhite;
            FlexBHelpColor := GreenOnWhite;
            FlexCHelpColor := RedOnWhite;
            UnselXrefColor := RedOnWhite;
            SelXrefColor := WhiteOnRed;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnRed;
            ButtonColor := BlackOnGreen;
            DefButtonColor := YellowOnGreen;
            HiButtonColor := WhiteOnGreen;
            SelButtonColor := GreenOnYellow;
            ProButtonColor := LtGreenOnGreen;
            BtnShadowColor := BlackOnRed;
            ClusterColor := RedOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    (*****************************************************************************)

    PROCEDURE RedDialog_Scheme;
    BEGIN
        IF NonStandardDisplay THEN
            EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := WhiteOnRed;
            CtrlColor := WhiteOnBlue;
            FrameColor := WhiteOnRed;
            HeaderColor := LtGreenOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := LtGrayOnBlue;
            SelPromptColor := WhiteOnBlue;
            ProPromptColor := LtGrayOnBlue;
            FieldColor := LtGrayOnBlue;
            SelFieldColor := YellowOnBlue;
            ProFieldColor := LtGreenOnBlue;
            ScrollBarColor := BlueOnCyan;
            SliderColor := WhiteOnBlue;
            HotSpotColor := LtRedOnBlue;

            BlockColor := BlackOnBlue;
            MarkerColor := YellowOnBlue;
            DelimColor := BlackOnBlue;
            SelDelimColor := RedOnWhite;
            ProDelimColor := DkGrayOnBlue;
            SelItemColor := BlackOnLtCyan;
            ProItemColor := DkGrayOnBlue;
            HighItemColor := RedOnBlue;
            AltItemColor := BlackOnCyan;
            AltSelItemColor := BlackOnYellow;
            FlexAHelpColor := BrownOnBlue;
            FlexBHelpColor := GreenOnBlue;
            FlexCHelpColor := RedOnBlue;
            UnselXrefColor := WhiteOnBlue;
            SelXrefColor := WhiteOnBlue;
            MouseColor := LtRedOnBlue;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnBlue;

            ButtonColor := BlackOnGreen; {not selected, not pressed}
            SelButtonColor := BlackOnLtGreen; {Selected, but not pressed}
            DefButtonColor := YellowOnGreen; {button pressed color}
            HiButtonColor := WhiteOnGreen; {WhiteOnGreen;}

            ProButtonColor := LtGrayOnGreen;
            BtnShadowColor := BlackOnRed;

            ClusterColor := BlueOnCyan;
            ProClusterColor := LtGrayOnGreen;
            HiClusterColor := WhiteOnCyan;
            SelClusterColor := WhiteOnMagenta;
        END;
        NENFillChar := #$B1;
    END;

    (*****************************************************************************)

    {- it doen't look like NEN, but at least you can see all the field higlights}
    {- and buttons                                                              }

    PROCEDURE OproDialog_Scheme;
    BEGIN
        IF NonStandardDisplay THEN
            EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnLtGray;
            CtrlColor := LtGreenOnCyan;
            FrameColor := WhiteOnLtGray;
            HeaderColor := WhiteOnLtGray;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := BlackOnLtGray;
            SelPromptColor := WhiteOnLtGray;
            ProPromptColor := BlackOnLtGray;
            FieldColor := YellowOnBlue;
            SelFieldColor := WhiteOnBlue;
            ProFieldColor := BlackOnLtGray;
            ScrollBarColor := LtGrayOnBlue;
            SliderColor := LtGrayOnBlue;
            HotSpotColor := LtGrayOnBlue;
            BlockColor := YellowOnBlue;
            MarkerColor := WhiteOnBlue;
            DelimColor := YellowOnLtGray;
            SelDelimColor := BlueOnBlue;
            ProDelimColor := YellowOnLtGray;
            SelItemColor := WhiteOnGreen;
            ProItemColor := LtGrayOnLtGray;
            HighItemColor := WhiteOnLtGray;
            AltItemColor := YellowOnCyan;
            AltSelItemColor := WhiteOnGreen;
            FlexAHelpColor := WhiteOnLtGray;
            FlexBHelpColor := WhiteOnLtGray;
            FlexCHelpColor := LtCyanOnLtGray;
            UnselXrefColor := YellowOnLtGray;
            SelXrefColor := WhiteOnLtBlue;
            MouseColor := WhiteOnRed;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)
    
    PROCEDURE DropBox_Scheme;
    BEGIN
        IF NonStandardDisplay THEN
            EXIT;
        WITH NENColorSet DO BEGIN
            TextColor := WhiteOnBlue; 
            CtrlColor := LtGreenOnCyan; 
            FrameColor := WhiteOnBlue; 
            HeaderColor := WhiteOnBlue; 
            ShadowColor := DkGrayOnBlack; 
            HighlightColor := WhiteOnRed; 
            PromptColor := BlackOnLtGray; 
            SelPromptColor := WhiteOnLtGray; 
            ProPromptColor := BlackOnLtGray; 
            FieldColor := YellowOnBlue; 
            SelFieldColor := WhiteOnBlue; 
            ProFieldColor := BlackOnLtGray; 
            ScrollBarColor := BlueOnCyan; 
            SliderColor := BlueOnCyan; 
            HotSpotColor := BlueOnCyan; 
            BlockColor := YellowOnBlue; 
            MarkerColor := WhiteOnBlue; 
            DelimColor := YellowOnLtGray; 
            SelDelimColor := BlueOnBlue; 
            ProDelimColor := YellowOnLtGray; 
            SelItemColor := WhiteOnGreen; 
            ProItemColor := LtGrayOnLtGray; 
            HighItemColor := WhiteOnLtGray; 
            AltItemColor := WhiteOnGreen; 
            AltSelItemColor := WhiteOnGreen; 
            FlexAHelpColor := WhiteOnLtGray; 
            FlexBHelpColor := WhiteOnLtGray; 
            FlexCHelpColor := LtCyanOnLtGray; 
            UnselXrefColor := YellowOnLtGray; 
            SelXrefColor := YellowOnLtGray; 
            MouseColor := WhiteOnRed; 
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)

    {- Copy scheme colors to passed records without changing global values}
    PROCEDURE GetScheme(Scheme         : SchemeProc;
                        VAR Colors     : ColorSet;
                        VAR dColors    : DialogColorSet);
    VAR
        TCCol          : ColorSet;
        TDCol          : DialogColorSet;
    BEGIN
        TCCol := NENColorSet;
        TDCol := NENDialogSet;
        Scheme;
        Colors := NENColorSet;
        dColors := NENDialogSet;
        NENColorSet := TCCol;
        NENDialogSet := TDCol;
    END;

    (*****************************************************************************)

    {- Copy scheme colors to passed record without changing global values}
    PROCEDURE GetCScheme(Scheme         : SchemeProc;
                         VAR Colors     : ColorSet);
    VAR
        TCCol          : ColorSet;
        TDCol          : DialogColorSet;
    BEGIN
        TCCol := NENColorSet;
        TDCol := NENDialogSet;
        Scheme;
        Colors := NENColorSet;
        NENColorSet := TCCol;
        NENDialogSet := TDCol;
    END;

    (*****************************************************************************)

    {- Copy scheme colors to passed record without changing global values}
    PROCEDURE GetDScheme(Scheme         : SchemeProc;
                         VAR dColors    : DialogColorSet);
    VAR
        TCCol          : ColorSet;
        TDCol          : DialogColorSet;
    BEGIN
        TCCol := NENColorSet;
        TDCol := NENDialogSet;
        Scheme;
        dColors := NENDialogSet;
        NENColorSet := TCCol;
        NENDialogSet := TDCol;
    END;

    (*****************************************************************************)
    PROCEDURE KCyan_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnCyan;       
            CtrlColor := LtRedOnGreen;       
            FrameColor := LtCyanOnCyan;       
            HeaderColor := LtCyanOnCyan;       
            ShadowColor := DkGrayOnBlack;      
            HighlightColor := WhiteOnCyan;        
            PromptColor := DkGrayOnCyan;       
            SelPromptColor := YellowOnCyan;       
            ProPromptColor := DkGrayOnCyan;       
            FieldColor := DkGrayOnCyan;       
            SelFieldColor := BlackOnLtCyan;
            ProFieldColor := DkGrayOnCyan;
            ScrollBarColor := BrownOnCyan;
            SliderColor := MagentaOnCyan;
            HotSpotColor := BlueOnCyan;
            BlockColor := YellowOnLtCyan;
            MarkerColor := WhiteOnMagenta;
            DelimColor := DkGrayOnCyan;
            SelDelimColor := WhiteOnCyan;
            ProDelimColor := LtGrayOnCyan;
            SelItemColor := BrownOnLtCyan;
            ProItemColor := LtGrayOnCyan;
            HighItemColor := WhiteOnCyan;
            AltItemColor := WhiteOnCyan;        
            AltSelItemColor := WhiteOnCyan;        
            FlexAHelpColor := LtRedOnCyan;        
            FlexBHelpColor := WhiteOnCyan;        
            FlexCHelpColor := LtCyanOnCyan;       
            UnselXrefColor := WhiteOnCyan;        
            SelXrefColor := WhiteOnCyan;        
            MouseColor := WhiteOnRed;         
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)

    PROCEDURE KBlue_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnBlue;
            CtrlColor := LtRedOnBlue;
            FrameColor := CyanOnBlue;
            HeaderColor := LtCyanOnBlue;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := CyanOnBlue;
            SelPromptColor := LtCyanOnBlue;
            ProPromptColor := LtGrayOnBlue;
            FieldColor := CyanOnBlue;
            SelFieldColor := YellowOnLtBlue;
            ProFieldColor := LtGrayOnBlue;
            ScrollBarColor := CyanOnBlue;
            SliderColor := CyanOnBlue;
            HotSpotColor := BlackOnCyan;
            BlockColor := YellowOnCyan;
            MarkerColor := WhiteOnMagenta;
            DelimColor := CyanOnBlue;
            SelDelimColor := YellowOnBlue;
            ProDelimColor := LtGrayOnBlue;
            SelItemColor := YellowOnCyan;
            ProItemColor := LtGrayOnBlue;
            HighItemColor := WhiteOnBlue;
            AltItemColor := WhiteOnBlue;
            AltSelItemColor := WhiteOnCyan;
            FlexAHelpColor := LtRedOnBlue;
            FlexBHelpColor := WhiteOnBlue;
            FlexCHelpColor := LtCyanOnBlue;
            UnselXrefColor := WhiteOnBlue;
            SelXrefColor := WhiteOnMagenta;
            MouseColor := WhiteOnRed;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)

    PROCEDURE KBrown_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnBrown;
            CtrlColor := LtRedOnLtGray;
            FrameColor := LtCyanOnBrown;
            HeaderColor := YellowOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnBrown;
            PromptColor := CyanOnBrown;
            SelPromptColor := YellowOnBrown;
            ProPromptColor := CyanOnBrown;
            FieldColor := CyanOnBrown;
            SelFieldColor := BlackOnYellow;
            ProFieldColor := CyanOnBrown;
            ScrollBarColor := CyanOnBrown;
            SliderColor := LtGrayOnBrown;
            HotSpotColor := BlueOnBrown;
            BlockColor := BlackOnYellow;
            MarkerColor := WhiteOnLtGray;
            DelimColor := DkGrayOnBrown;
            SelDelimColor := WhiteOnBrown;
            ProDelimColor := LtGrayOnBrown;
            SelItemColor := BlackOnYellow;
            ProItemColor := LtGrayOnBrown;
            HighItemColor := WhiteOnBrown;
            AltItemColor := WhiteOnBrown;
            AltSelItemColor := WhiteOnBrown;
            FlexAHelpColor := LtRedOnBrown;
            FlexBHelpColor := WhiteOnBrown;
            FlexCHelpColor := LtCyanOnBrown;
            UnselXrefColor := WhiteOnBrown;
            SelXrefColor := WhiteOnBrown;
            MouseColor := WhiteOnLtGreen;
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)

    PROCEDURE KGreen_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnGreen;      
            CtrlColor := LtRedOnBlue;        
            FrameColor := LtCyanOnGreen;      
            HeaderColor := LtCyanOnGreen;      
            ShadowColor := DkGrayOnBlack;      
            HighlightColor := WhiteOnCyan;        
            PromptColor := DkGrayOnGreen;      
            SelPromptColor := YellowOnGreen;      
            ProPromptColor := DkGrayOnGreen;      
            FieldColor := DkGrayOnGreen;      
            SelFieldColor := DkGrayOnLtGreen;
            ProFieldColor := DkGrayOnGreen;      
            ScrollBarColor := BrownOnGreen;       
            SliderColor := LtCyanOnGreen;      
            HotSpotColor := BlueOnGreen;        
            BlockColor := YellowOnCyan;       
            MarkerColor := WhiteOnMagenta;     
            DelimColor := DkGrayOnGreen;      
            SelDelimColor := WhiteOnGreen;       
            ProDelimColor := LtGrayOnGreen;      
            SelItemColor := DkGrayOnLtGreen;
            ProItemColor := LtGrayOnGreen;      
            HighItemColor := WhiteOnGreen;       
            AltItemColor := WhiteOnGreen;       
            AltSelItemColor := WhiteOnGreen;       
            FlexAHelpColor := LtRedOnGreen;       
            FlexBHelpColor := WhiteOnGreen;       
            FlexCHelpColor := LtCyanOnGreen;      
            UnselXrefColor := WhiteOnGreen;       
            SelXrefColor := WhiteOnGreen;       
            MouseColor := WhiteOnRed;         
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)

    PROCEDURE KLtGray_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := BlackOnLtGray;      
            CtrlColor := LtRedOnLtGray + Blink;
            FrameColor := LtCyanOnLtGray;     
            HeaderColor := LtCyanOnLtGray;     
            ShadowColor := DkGrayOnBlack;      
            HighlightColor := WhiteOnLtGray;      
            PromptColor := CyanOnLtGray;
            SelPromptColor := YellowOnLtGray;     
            ProPromptColor := CyanOnLtGray;       
            FieldColor := CyanOnLtGray;       
            SelFieldColor := LtCyanOnLtGray + Blink;
            ProFieldColor := CyanOnLtGray;
            ScrollBarColor := DkGrayOnLtGray;
            SliderColor := LtBlueOnLtGray;
            HotSpotColor := BlueOnLtGray + Blink;
            BlockColor := YellowOnLtGray + Blink;
            MarkerColor := LtGreenOnLtGray + Blink;
            DelimColor := DkGrayOnLtGray;
            SelDelimColor := WhiteOnLtGray;
            ProDelimColor := BrownOnLtGray;
            SelItemColor := YellowOnLtGray + Blink;
            ProItemColor := DkGrayOnLtGray;
            HighItemColor := WhiteOnLtGray;
            AltItemColor := LtCyanOnLtGray;
            AltSelItemColor := LtCyanOnLtGray + Blink;
            FlexAHelpColor := LtRedOnLtGray;      
            FlexBHelpColor := WhiteOnLtGray;      
            FlexCHelpColor := LtCyanOnLtGray;     
            UnselXrefColor := WhiteOnLtGray;      
            SelXrefColor := WhiteOnLtGray;      
            MouseColor := WhiteOnGreen + Blink; 
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)

    PROCEDURE KMagenta_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnMagenta;    
            CtrlColor := LtRedOnBrown;       
            FrameColor := LtCyanOnMagenta;    
            HeaderColor := LtCyanOnMagenta;    
            ShadowColor := DkGrayOnBlack;      
            HighlightColor := WhiteOnMagenta;     
            PromptColor := CyanOnMagenta;      
            SelPromptColor := YellowOnMagenta;    
            ProPromptColor := CyanOnMagenta;      
            FieldColor := CyanOnMagenta;      
            SelFieldColor := LtCyanOnMagenta + Blink;
            ProFieldColor := CyanOnMagenta;      
            ScrollBarColor := CyanOnMagenta;      
            SliderColor := LtGrayOnMagenta;    
            HotSpotColor := BlueOnRed;          
            BlockColor := YellowOnMagenta + Blink;
            MarkerColor := WhiteOnBrown;       
            DelimColor := DkGrayOnMagenta;    
            SelDelimColor := WhiteOnMagenta;     
            ProDelimColor := LtGrayOnMagenta;    
            SelItemColor := YellowOnMagenta + Blink;
            ProItemColor := LtGrayOnMagenta;    
            HighItemColor := WhiteOnMagenta;     
            AltItemColor := WhiteOnMagenta;     
            AltSelItemColor := WhiteOnMagenta;     
            FlexAHelpColor := LtRedOnMagenta;     
            FlexBHelpColor := WhiteOnMagenta;     
            FlexCHelpColor := LtCyanOnMagenta;    
            UnselXrefColor := WhiteOnMagenta;     
            SelXrefColor := WhiteOnMagenta;     
            MouseColor := WhiteOnBlue + Blink;  
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)

    PROCEDURE KRed_Scheme;
    BEGIN
        WITH NENColorSet DO BEGIN
            TextColor := YellowOnRed;        
            CtrlColor := LtRedOnCyan;        
            FrameColor := LtCyanOnRed;        
            HeaderColor := LtCyanOnRed;        
            ShadowColor := DkGrayOnBlack;      
            HighlightColor := WhiteOnRed;         
            PromptColor := CyanOnRed;          
            SelPromptColor := YellowOnRed;        
            ProPromptColor := CyanOnRed;          
            FieldColor := CyanOnRed;          
            SelFieldColor := LtCyanOnRed + Blink;  
            ProFieldColor := CyanOnRed;          
            ScrollBarColor := CyanOnRed;          
            SliderColor := MagentaOnRed;       
            HotSpotColor := BlueOnRed;          
            BlockColor := YellowOnRed + Blink;  
            MarkerColor := WhiteOnBrown;       
            DelimColor := DkGrayOnRed;        
            SelDelimColor := WhiteOnRed;         
            ProDelimColor := LtGrayOnRed;        
            SelItemColor := YellowOnRed + Blink;  
            ProItemColor := LtGrayOnRed;        
            HighItemColor := WhiteOnRed;         
            AltItemColor := WhiteOnRed;         
            AltSelItemColor := WhiteOnRed;         
            FlexAHelpColor := LtRedOnRed;         
            FlexBHelpColor := WhiteOnRed;         
            FlexCHelpColor := LtCyanOnRed;        
            UnselXrefColor := WhiteOnRed;         
            SelXrefColor := WhiteOnRed;         
            MouseColor := WhiteOnBlack + Blink; 
        END;
        WITH NENDialogSet DO BEGIN
            HiPromptColor := YellowOnLtGray;
            ButtonColor := BlackOnGreen;
            DefButtonColor := LtCyanOnGreen;
            HiButtonColor := YellowOnGreen;
            SelButtonColor := WhiteOnGreen;
            ProButtonColor := BlackOnLtGray;
            BtnShadowColor := BlackOnLtGray;
            ClusterColor := BlackOnCyan;
            ProClusterColor := BlackOnLtGray;
            HiClusterColor := YellowOnCyan;
            SelClusterColor := WhiteOnCyan;
        END;
    END;

    (*****************************************************************************)

BEGIN
    NENColorSet := DefaultColorSet; { So Monochrome will have default values }
    WITH NENDialogSet DO BEGIN
        HiPromptMono := $0F;
        ButtonMono := $07;
        DefButtonMono := $07;
        HiButtonMono := $0F;
        SelButtonMono := $0F;
        ProButtonMono := $70;
        BtnShadowMono := $70;
        ClusterMono := $07;
        ProClusterMono := $07;
        HiClusterMono := $0F;
        SelClusterMono := $0F;
    END;
    NENFillChar := #$0;
END.
