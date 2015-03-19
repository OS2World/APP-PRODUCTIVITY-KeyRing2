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
* Laserjet Support unit
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}

UNIT DGPRINT;

INTERFACE
USES
    {$IFNDEF VirtualPascal}
    Boiler45,
    {$ENDIF}
    Dos,
    {$IFNDEF VirtualPascal}
    GBuildK,
    {$ENDIF}
    GLOBTYPE,
    KERROR,
    LJVAR,
    OpPrnlow,
    OpRoot,
    OpString
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;
TYPE
    TCtrlFlg       = (CtrlForceToSpace, CtrlSkip, CtrlPassThru);
    PFont          = ^TFont;
    TFont          = OBJECT(SingleListNode)
                         FID            : FontTypeT;
                         fPointSize     : REAL;
                         fHMI           : REAL;
                         fMetrics       : TCharWidthTable;
                         fSelectStr     : StringPtr;

                         CONSTRUCTOR Init(CONST ID       : FontTypeT;
                                          CONST PointSize : REAL;
                                          CONST WidthTable : PathStr;
                                          CONST SelectStr : STRING);
                         DESTRUCTOR Done; VIRTUAL;

                         FUNCTION DesignUnitsToInches(CONST Units : LONGINT) : REAL;
                             {-Convert font design units to inches }
                         FUNCTION CalcStringWidth(CONST St : STRING; CtrlFlg : TCtrlFlg) : REAL;
                             {-Calculate the width, in inches, of a string }
                         FUNCTION CalcCAP(CONST CurX : REAL; CONST St : STRING) : REAL;
                             {-Calculate the Current Active Position after printing a string }
                         PROCEDURE GetMetrics(CONST Ch : CHAR; VAR LeftExt, RightExt, HorizEsc : REAL);
                             {-Get the metrics for one character }
                         FUNCTION GetLineSpacing : REAL;
                             {-Get the recommended inter-line spacing }
                     END;

    TP1P2Rec       = RECORD
                         TOP,
                         Bot,
                         LEFT,
                         RIGHT          : Float;
                         Driver         : STRING[8];
                     END;

    TP1P2Array     = ARRAY[TxtGraf] OF TP1P2Rec;

    PPrinter       = ^TPrinter;
    TPrinter       = OBJECT(ROOT)
                         MyPort         : PrnType;
                         ljInitStr,
                         ljULOn,
                         ljULOff,
                         ljBoldOn,
                         ljItalOn,
                         ljItalOff,
                         ljBoldOff,
                         ljNewPage      : StringPtr;
                         FlakeyMixedTextGraph,
                         AllowPrint,
                         ljIsColor,
                         GrafDriveInited,
                         ljDuplex,
                         ljCanHpgl,
                         ljCanBox       : BOOLEAN;
                         COP            : CylonP;
                         ljActiveFont   : PFont;
                         ljFonts        : SingleList;
                         CharTable      : XlatCharTable;
                         MyPortName,
                         PageLabel      : STRING[40];
                         P1P2           : TP1P2Array;
                         MyWheel        : TColorWheel;
                         MyRGBTextWheel : TRGBTextWheel;
                         CurRow,
                         CurColumn,

                         CurBottomMargin,
                         CurLeftMargin,
                         CurRightMargin,
                         CurTopMargin,
                         CurLineSpace   : Float;

                         MyFontPath     : PathStr;

                         CurPageNum     : WORD;
                         MyLetterHeadTray,
                         MyBlankTray    : TLetterHeadTray;
                         MyOutMode      : TxtGraf;
                         GDRes          : WORD;
                         PrnPlot        : TPrnPlot;
                         PType          : PrnModelT;

                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);

                             {call this instead, for descendent object init}
                         FUNCTION InitPrim(PrnInfo        : TPrnCfg;
                                           VAR MyCOP      : CylonP;
                                           Mode           : TxtGraf) : BOOLEAN;

                         FUNCTION SetupGD(TrueBlack : TPrnColors; MaxColors : WORD) : BOOLEAN;

                             {load character translation table for foreign langs}
                         FUNCTION LoadCharTable(Name : PathStr) : BOOLEAN;

                         DESTRUCTOR Done; VIRTUAL;

                             {get last printer error}
                         FUNCTION PrnError : WORD;

                             {return printer name}
                         FUNCTION GetDevName : STRING; VIRTUAL;

                             {change page label string}
                         PROCEDURE SetPageLabel(Strg : STRING);

                             {get the current page label string}
                         FUNCTION GetPageLabel : STRING;

                             {return LJ I/O port or type (file, nul,...)}
                         FUNCTION GetPort : PrnType;

                             {return LJ I/O port name}
                         FUNCTION GetPortName : STRING;

                         FUNCTION PrinterName : STRING; VIRTUAL;

                             {-Enter HPGL/2 graphics mode }
                         PROCEDURE GoHPGL; VIRTUAL;

                             {-Return to PCL command mode }
                         PROCEDURE GoPCL; VIRTUAL;

                             {-Reset the printer}
                         PROCEDURE ResetPrn; VIRTUAL;

                             {-Send a string to the printer }
                         FUNCTION PutStr(CONST St : STRING) : BOOLEAN;

                             {-Send a right justified string to the printer }
                         FUNCTION PutStrRJ(CONST St : STRING; CONST X : REAL) : BOOLEAN;

                             {-Send a line of text to the printer and advance the cursor}
                         FUNCTION PutLine(CONST St : STRING) : BOOLEAN;

                             {-Send a line of text to the printer and advance the cursor}
                         FUNCTION PutCenteredLine(CONST St : STRING) : BOOLEAN;

                             {-Send a string to the printer, underlining it }
                         FUNCTION PutStrUL(CONST St : STRING) : BOOLEAN;

                             {-Print a string at the specified coordinate }
                         FUNCTION PutStrXY(CONST St : STRING; CONST X, Y : REAL) : BOOLEAN;

                             {-Right justify a string at the specified coordinates }
                         FUNCTION PutStrXYRight(CONST St : STRING; CONST X, Y : REAL) : BOOLEAN;

                             {-Initialize a print job }
                         FUNCTION InitJob : BOOLEAN;

                             {return the current Cylon (activity indicator) pointer}
                         FUNCTION GetCOP : CylonP;

                             {-Reset the left and right hardware margins to their default }
                             {Note: We don't use hardware margins....}
                         FUNCTION ClearHorizontalMargins : BOOLEAN; VIRTUAL;

                         FUNCTION GetCPRow : REAL;
                         FUNCTION GetCPCol : REAL;

                             {-Update the cursor position...X and Y specified in inches }
                         FUNCTION PrnGotoXY(CONST X, Y : REAL) : BOOLEAN; VIRTUAL;

                             {-Update the horizontal cursor position }
                         FUNCTION PrnGotoX(CONST X : REAL) : BOOLEAN; VIRTUAL;

                             {-Update the vertical cursor position }
                         FUNCTION PrnGotoY(CONST Y : REAL) : BOOLEAN; VIRTUAL;

                             {-Advance the X cursor by Delta inches }
                         FUNCTION PrnAdvanceX(CONST Delta : REAL) : BOOLEAN;

                             {-Advance the Y cursor by Delta inches }
                         FUNCTION PrnAdvanceY(CONST Delta : REAL) : BOOLEAN; VIRTUAL;

                             {-Eject the current page }
                         FUNCTION FormFeed : BOOLEAN;

                             {-advance to the next line using the current font for delta}
                         FUNCTION LineFeed(VAR NewPos : REAL) : BOOLEAN;

                             {set status of downloaded font}
                         PROCEDURE MakeFontTemporary; VIRTUAL;

                             {set status of downloaded font}
                         PROCEDURE MakeFontPermanent; VIRTUAL;

                             {send font to printer}
                         FUNCTION DownloadFont(IDNo           : FontTypeT;
                                               FontFileName   : STRING;
                                               PointSize      : REAL;
                                               Permanent      : BOOLEAN) : BOOLEAN; VIRTUAL;

                             {-Add a font metric to this object }
                         FUNCTION AddFont(CONST ID       : FontTypeT;
                                          CONST PointSize : REAL;
                                          CONST WidthTable : PathStr;
                                          CONST SelectStr : STRING) : BOOLEAN; VIRTUAL;

                             {-Find a font with a matching ID }
                         FUNCTION FindFontByID(CONST ID : FontTypeT) : PFont; VIRTUAL;

                             {-Remove a font from the printer }
                         PROCEDURE RemoveFont(CONST ID : FontTypeT); VIRTUAL;

                             {-Find a font and make it active }
                         PROCEDURE SelectFont(CONST ID : FontTypeT); VIRTUAL;

                             {calculate the width of a string in inches using current font.}
                             { Selectively ignore control chars}
                         FUNCTION ComputeStringWidth(CONST St : STRING; CtrlFlg : TCtrlFlg) : REAL;

                             {calculate the width of a string in inches using specified font}
                             { Selectively ignore control chars}
                         FUNCTION ComputeStringWidthF(CONST St : STRING; CONST ID : FontTypeT; CtrlFlg : TCtrlFlg) : REAL;

                             {-Compute the width of a string, in inches, for the active font, multi-typeface ctrls }
                         FUNCTION ComputeStringWidthMF(CONST St : STRING; CONST ID : FontTypeT; Flags : BYTE) : REAL;

                             {get char height + leading of current font}
                         FUNCTION GetLineSpacing : REAL;

                             {return the pointsize of the current font}
                         FUNCTION GetPointSize : REAL;

                             {-Get a mode string (bold, italic,...) , for this printer}
                         FUNCTION GetModeStr(Mode : CharModeT) : STRING;

                             {-Set the character horizontal spacing}
                         PROCEDURE SetHMI(CONST Inches : REAL); VIRTUAL;

                             {-Set the vertical motion index }
                         PROCEDURE SetVMI(CONST Inches : REAL); VIRTUAL;

                             {-Turn on printer underlining }
                         FUNCTION UnderLineOn : BOOLEAN;
                             {-Turn off printer underlining }
                         FUNCTION UnderLineOff : BOOLEAN;
                             {turn on bold}
                         FUNCTION BoldOn : BOOLEAN;
                             {turn off bold}
                         FUNCTION BoldOff : BOOLEAN;
                             {turn on italics}
                         FUNCTION ItalOn : BOOLEAN;
                             {turn off italics}
                         FUNCTION ItalOff : BOOLEAN;

                         PROCEDURE SetDuplexMode(Mode : BOOLEAN); VIRTUAL;

                             {-Draw a horizontal line at X,Y that is Width inches long }
                         FUNCTION HLine(CONST X, Y, Width : REAL) : BOOLEAN; VIRTUAL;

                             {-Draw a thick horizontal line at X,Y that is Width inches long }
                         PROCEDURE ThickHLine(CONST X, Y, Width : REAL); VIRTUAL;

                             {-Draw a vertical line at X,Y that is Height inches long }
                         PROCEDURE VLine(CONST X, Y, Height : REAL); VIRTUAL;

                             {-Draw a thick vertical line at X,Y that is Height inches long }
                         PROCEDURE ThickVLine(CONST X, Y, Height : REAL); VIRTUAL;

                             {-Draw a box, filling it if necessary }
                         PROCEDURE Box(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN); VIRTUAL;

                             {-Draw a thick box, filling it if necessary }
                         PROCEDURE BoxThick(CONST Width, Height : REAL; CONST PctGray : BYTE); VIRTUAL;

                             {-Draw a box, filling it if desired, with a shadow on it }
                         PROCEDURE BoxShadow(CONST X, Y, Width, Height : REAL;
                                             CONST PctGray  : BYTE;
                                             Border         : BOOLEAN); VIRTUAL;

                             {-Draw a double lined box }
                         PROCEDURE DoubleBox(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE); VIRTUAL;

                             {-Print a tag and data between Left and Right with a dot leader }
                         PROCEDURE TagAndDataWithLeader(CONST Tag, Data : STRING;
                                                        CONST LEFT, RIGHT : REAL;
                                                        CONST LineFont : FontTypeT);

                             {-Center a line of data between to points, returns X coordinate }
                         FUNCTION CenterData(CONST Data : STRING; CONST LEFT, RIGHT : REAL) : REAL;

                         (*
                             {-Output a block of text, word wrapped to fit margins}
                             {funky paragraph wrapper for pchar string buffers.  Dont use!}
                             {Use the report object (DGRPT) instead!}
                         PROCEDURE OutputTextWrapped(CONST Buf      : PCHAR;
                                                     CONST LEFT, RIGHT : REAL;
                                                     CurPage        : WORD;
                                                     Just           : JustT);
                         *)

                             {-Print a pie wedge }
                             {Dunsel!  Use DGPIE instead}
                         PROCEDURE PieWedge(CONST X, Y, Radius : WORD; CONST StartAngle, EndAngle, Fill : REAL); VIRTUAL;

                             {draw a piechart}
                         PROCEDURE DrawPie(NoOfSlices     : BYTE;
                                           PieSpec        : TPieArray;
                                           XOrigin,
                                           YOrigin,
                                           Radius         : WORD;
                                           Optimize,
                                           DrawLabels,
                                           DrawShadow     : BOOLEAN;
                                           XShadow,
                                           YShadow,
                                           MinPointerLineLength,
                                           MinVertDistance,
                                           LabelLineStart : INTEGER;
                                           BackgroundColor : BYTE;
                                           TopCaption     : STRING;
                                           TopFont        : FontTypeT;
                                           TCColor        : TPrnColors;
                                           BotCaption     : STRING;
                                           BotFont        : FontTypeT;
                                           BCColor        : TPrnColors;
                                           XStretch,
                                           YStretch       : WORD); VIRTUAL;

                             {-Set the HPGL/2 transparency mode on or off }
                         PROCEDURE GraphicsTransparency(CONST On : BOOLEAN); VIRTUAL;

                             {send a buffer full of chars to the printer}
                         PROCEDURE PrnPutBlock(VAR Block; BlockSize : WORD);

                             {return current printer model (lj3, lj4, ...}
                         FUNCTION GetPtype : PrnModelT;

                             {send binary file to printer.  Dunsel!}
                             {use PutPCX instead!}
                         FUNCTION DownloadGraphic(CONST FName : PathStr) : WORD;

                             {can this printer draw boxes with high level command?}
                         FUNCTION GetCanBox : BOOLEAN;
                             {can this printer parse HPGL/HPGL2}
                         FUNCTION GetCanHPGL : BOOLEAN;

                             {return current left margin (software)}
                         FUNCTION GetLeftMargin : REAL;
                             {return current right margin (software)}
                         FUNCTION GetRightMargin : REAL;
                             {return current top margin (software)}
                         FUNCTION GetTopMargin : REAL;
                             {return current bottom margin (software)}
                         FUNCTION GetBottomMargin : REAL;

                             {set current left margin (software)}
                         PROCEDURE SetLeftMargin(M : REAL);
                             {set current right margin (software)}
                         PROCEDURE SetRightMargin(M : REAL);
                             {set current top margin (software)}
                         PROCEDURE SetTopMargin(M : REAL);
                             {set current bottom margin (software)}
                         PROCEDURE SetBottomMargin(M : REAL);

                             {-Set the width of the HPGL/2 pen }
                         PROCEDURE hpglPW(CONST Width : REAL); VIRTUAL;

                             {*****************************************}
                             {Note: Most of this HPGL stuff is obsolete}
                             {Use GrafDrive/BGI calls instead, because they}
                             {are printer independent!}
                             {*****************************************}

                             {draw HPGL text label at coordinates}
                         PROCEDURE hpglLabel(X, Y : REAL; S : STRING); VIRTUAL;

                             {draw HPGL box at specified location}
                         PROCEDURE hpglBox(Lx, Ly, BoxW, Boxh : REAL); VIRTUAL;

                             {draw a line using HPGL}
                         PROCEDURE hpglLine(L1x, L1y, L2x, L2y, Width : REAL); VIRTUAL;

                             {draw a box using HPGL, filled with black}
                         PROCEDURE hpglBlackBox(Lx, Ly, BoxW, Boxh : REAL); VIRTUAL;

                             {draw an hpgl pie wedge}
                         PROCEDURE hpglWedge(XOrg, YOrg, Radius : WORD; StartAngle, EndAngle, Fill : REAL); VIRTUAL;

                             {draw an hpgl leader line}
                         PROCEDURE hpglPointer(OrgX, OrgY, Angle, BeginAt, PLen : REAL); VIRTUAL;

                             {right justify a string at tabstop}
                         PROCEDURE PrintAtRightTabRow(S : STRING; Row, TabStop : REAL);

                             {return X value to center S between left/right margins}
                         FUNCTION CenterStringX(S : STRING) : REAL;

                             {assign font id to newly downloaded font}
                         PROCEDURE AssignFontID(IDNo : FontTypeT); VIRTUAL;

                             {send a PCX file to the printer, using specified}
                             {size.  Stretch or squash the picture to fit}
                             {$IFNDEF VirtualPascal}
                         PROCEDURE PutPCX(FName          : STRING;
                                          X1, Y1,
                                          X2, Y2         : REAL;
                                          Density        : INTEGER);

                             {$ENDIF}
                             {draw left justified string - this is really stupid}
                         PROCEDURE PrintAtLeftTabRow(S : STRING; Row, TabStop : REAL);

                             {center a page number at bottom margin}
                         PROCEDURE DoPageNumAndFF; VIRTUAL;

                             {$IFNDEF VirtualPascal}
                             {initialize the grafdrive unit}
                         PROCEDURE GrafDriveInit(P1x, P1y,
                                                 P2x, P2y       : REAL;
                                                 Mode           : TxtGraf;
                                                 ResMode        : WORD);
                             {initialize the grafdrive unit, using user-banding}
                         PROCEDURE GrafDriveInitBand(P1x, P1y,
                                                     P2x, P2y       : REAL;
                                                     Mode           : TxtGraf;
                                                     ResMode        : WORD);

                             {initialize the grafdrive unit}
                         PROCEDURE GrafDriveInitDeluxe(Mode           : TxtGraf;
                                                       P1x, P1y,
                                                       P2x, P2y       : REAL;
                                                       ResMode        : WORD);

                             {initialize the grafdrive unit and select portrait/landscape}
                             {using percent of fullpage for extents                      }
                         PROCEDURE GrafDriveInitPL(Mode           : TxtGraf;
                                                   P1x, P1y,
                                                   P2x, P2y       : REAL;
                                                   PL             : TGrafOrient;
                                                   CustomPage     : BOOLEAN);

                             {shut down the grafdrive unit}
                         PROCEDURE GrafDriveFinish;
                             {$ENDIF}

                             {convert inches to dots, using current graphdrive device}
                             {this assumes viewport=fullpage}
                         PROCEDURE GDIn2XY(Inx, Iny       : REAL;
                                           AutoMargin     : BOOLEAN;
                                           VAR X, Y       : LONGINT);
                             {pick a printer paper bin}
                         PROCEDURE SelectTray(T : TLetterHeadTray); VIRTUAL;

                             {initialize the Letterhead and Blank paper trays }
                             {Infer blank tray if not known                   }
                         PROCEDURE SetTrays(Ltr, Blnk : TLetterHeadTray); VIRTUAL;

                             {select a paper type - letterhead or blank}
                         PROCEDURE SelectTrayDeluxe(Tray : TPaperStyle); VIRTUAL;

                             {translate desired color into printer color}
                         FUNCTION TranslateColor(DesiredColor : TPrnColors) : BYTE;

                             {select a text color}
                         PROCEDURE SelectTextColor(C : TPrnColors); VIRTUAL;

                             {force printer back into black&white text mode}
                         PROCEDURE SelectTextMonoChrome; VIRTUAL;

                             {set grafdrive resolution}
                         PROCEDURE SetGDRes(R : WORD);

                             {get current grafdrive resolution}
                         FUNCTION GetGDRes : WORD;

                             {set current page number}
                         PROCEDURE SetPageNum(PG : WORD);

                         PROCEDURE SetFormLen(CONST L : LONGINT); VIRTUAL;

                             {get current page number}
                         FUNCTION GetPageNum : WORD;

                             {set/clear allow print flag}
                             {if printing is not allowed, then throw}
                             {chars in bitbucket as they are printed}
                         PROCEDURE SetAllowPrint(Allow : BOOLEAN);

                         FUNCTION GetAllowPrint : BOOLEAN;

                             {if true, then not a good idea to mix text and }
                             {graphics on same line (HPDJ printers)         }
                         FUNCTION IsFlakeyOnMixedTextGraph : BOOLEAN;
                             {$IFNDEF VirtualPascal}
                             {draw high level chart}
                         PROCEDURE DrawChart(Ch : ChartDef);
                             {$ENDIF}

                         FUNCTION GetCurOrient : TPrnPlot;
                         FUNCTION GetCurRow : REAL;

                         PROCEDURE DrawRasterBox(X,
                                                 Y              : REAL;
                                                 Border,
                                                 DropShadow     : BOOLEAN;
                                                 PctGray,
                                                 Hyt,
                                                 Width          : REAL); VIRTUAL;

                         PROCEDURE DrawShadedTextBox(X,
                                                     Y              : Float;
                                                     Strg           : STRING;
                                                     Font           : FontTypeT;
                                                     JustifyH       : JustT;
                                                     JustifyV       : JustVT;
                                                     TextIndent     : Float;
                                                     Border,
                                                     DropShadow     : BOOLEAN;
                                                     PctGray,
                                                     Hyt,
                                                     Width          : REAL); VIRTUAL;

                         PROCEDURE DrawShadedTextBoxDeluxe(X,
                                                           Y              : Float;
                                                           LStrg          : STRING;
                                                           CStrg          : STRING;
                                                           RStrg          : STRING;
                                                           LFont          : FontTypeT;
                                                           CFont          : FontTypeT;
                                                           RFont          : FontTypeT;
                                                           JustifyV       : JustVT;
                                                           TextIndent     : Float;
                                                           Border,
                                                           DropShadow     : BOOLEAN;
                                                           PctGray,
                                                           Hyt,
                                                           Width          : REAL);
                             {return halftone bitmap pattern}
                         FUNCTION HalfTone(Level : BYTE; X, Y : WORD) : BYTE;
                     PRIVATE

                         ljPrn          : BasePrinterPtr;

                             {-Specify the grayscale % for grayscale fills }
                         FUNCTION ljPatternShade(CONST Percent : BYTE) : BOOLEAN; VIRTUAL;

                             {-Specify the parameters of the print model rectangle }
                         FUNCTION ljRectDimensions(CONST WidthInDP, HeightInDP : REAL) : BOOLEAN; VIRTUAL;

                             {-Fill the previously specified rectangle }
                         FUNCTION ljFillRect(CONST Fill : RectFillType) : BOOLEAN; VIRTUAL;


                             {display message box showing current printer problems}
                         PROCEDURE PostPrnError(P : POINTER);

                             {piechart stuff}
                         FUNCTION XOffset(A, B, Amt : INTEGER) : INTEGER;
                         FUNCTION Yoffset(A, B, Amt : INTEGER) : INTEGER;
                         FUNCTION ExplByAngle(InAngle : INTEGER; Radius : LONGINT) : INTEGER;
                         FUNCTION Quadrant(InAngle : INTEGER) : BYTE;
                         PROCEDURE SetFontSize(Font : FontTypeT);
                         PROCEDURE CalcPointers(NoOfSlices     : BYTE;
                                                VAR PieSpec    : TPieArray;
                                                MinPointerLineLength,
                                                MinVertDistance,
                                                Rotation       : INTEGER);
                         FUNCTION CheckPointerVerticalDiffs(NoOfSlices     : BYTE;
                                                            VAR PieSpec    : TPieArray;
                                                            Radius,
                                                            Rotation,
                                                            MinVertDistance : INTEGER) : BOOLEAN;

                         FUNCTION ButtOriented(NoOfSlices : BYTE; VAR PieSpec : TPieArray) : BOOLEAN;

                     END;

    {-Convert inches to decipoints }
FUNCTION InToDP(CONST Inches : REAL) : REAL;

    {-Convert inches to PCL dots }
FUNCTION InToDots(CONST Inches : REAL) : INTEGER;
    {-Convert PCL dots to inches }
FUNCTION DotsToIn(CONST Dots : LONGINT) : REAL;
    {-Convert PCL dots to decipoints }
FUNCTION DotsToDP(CONST Dots : LONGINT) : REAL;
    {-Convert a real number to a string suitable}
    {for sending to the printer - dunsel?  See MATH.PAS}
FUNCTION PrnRealStr(CONST R : REAL) : STRING;
    {return percent string from real number input - dunsel?  See MATH.PAS}
FUNCTION PercentStr(CONST Pc : REAL) : STRING;

    {status indicator used by grafdrive}
FUNCTION GStat(Cur, Max : INTEGER) : WORD;

    {--------------}

VAR
    PPrt           : PPrinter;

IMPLEMENTATION
USES
    Crt,
    DGCMD,
    DGLIB,
    Graph,
    {$IFNDEF VirtualPascal}
    GraphAdd,
    {$ENDIF}
    Message,
    OpCmd,
    OpConst,
    OpDos,
    OpInline,
    Strings,
    UTIAM;


TYPE
    MaskT          = ARRAY[0..9, 0..3] OF BYTE;

CONST
    {halftone fill patterns}
    Mask           : MaskT =
    (
        ($00, $00, $00, $00),
        ($80, $20, $08, $02),
        ($99, $00, $00, $99),
        ($99, $44, $22, $99),
        ($99, $66, $66, $99),
        ($AA, $55, $AA, $55),
        ($DD, $66, $CC, $77),
        ($EE, $77, $33, $AA),
        ($66, $FF, $FF, $66),
        ($FF, $FF, $FF, $FF)
        );

    {-----------------}

    FUNCTION TPrinter.HalfTone(Level : BYTE; X, Y : WORD) : BYTE;
    BEGIN
        HalfTone := Mask[Level MOD 9, Y MOD 4];
    END;

    {-----------------}

    {$IFNDEF VirtualPascal}
    PROCEDURE TPrinter.PutPCX(FName : STRING; X1, Y1, X2, Y2 : REAL; Density : INTEGER);
    VAR
        L,
        R,
        T,
        B              : LONGINT;
        ViewPort       : ViewPortType;
        VPReset        : BOOLEAN;
        MyOldPrinter   : STRING;
        TempP1P2       : TP1P2Array;
        {$IFNDEF DPMI}
        REGS           : GDregs;
        {$ENDIF}
    BEGIN
        {$IFNDEF DPMI}
        RingBell;
        EXIT;
        {$ENDIF}

        IF MAXAVAIL < $FFF0 THEN BEGIN
            RingBell;
            EXIT;
        END;

        {first check if there is anything to do}
        IF NOT ExistFile(FName) THEN BEGIN
            DispErrorDeluxe('Missing file', FName, TRUE, Iam);
            EXIT;
        END;
        {assume no preturbation of viewport}
        VPReset := FALSE;

        {some color printers use _LJ4 to force vector drawing }
        {we need raster here, so jam it in...                 }
        MyOldPrinter := MyPrinter; {save old printer.  %@^#*~! globals!}
        MyPrinter := P1P2[EPrnBitMap].Driver; {force correct driver}

        IF ljIsColor THEN
            MyPrinter := '_DJC';

        TempP1P2 := P1P2;
        {are we in graphics mode?}
        IF NOT GrafDriveInited THEN
            {nope - make it so}
            GrafDriveInitBand(X1, Y1, X2, Y2, MyOutMode, 0)
        ELSE BEGIN
            {already in graphics mode, so calc viewport}
            GDIn2XY(X1, Y1, FALSE, L, T);
            GDIn2XY(X2, Y2, FALSE, R, B);
            {get/save existing viewport settings}
            GetViewSettings(ViewPort);
            {set new viewport}
            SetViewport(L, T, R, B, FALSE);
            {viewport was preturbed}
            VPReset := TRUE;
        END;
        {output image}
        {$IFDEF DPMI}
        GDPutPCX(FName, CopyPut, 0, Density);
        {$ELSE}
        REPEAT
            GDPutPCX(FName, CopyPut, 0, Density);
            REGS.ax := $ffff;     { trash the AX register }
            GDcall(8, REGS);
        UNTIL REGS.ax <> 1;
        {$ENDIF}

        IF VPReset THEN
            {reset viewport to original}
            SetViewport(ViewPort.X1, ViewPort.Y1, ViewPort.X2, ViewPort.Y2, ViewPort.Clip)
        ELSE
            {close graphics engine}
            GrafDriveFinish;

        P1P2 := TempP1P2;
        MyPrinter := MyOldPrinter; {get old printer.  %@^#*~! globals!}
    END;
    {$ENDIF}

    {-----------------}

    PROCEDURE TPrinter.DrawShadedTextBox(X,
                                         Y              : Float;
                                         Strg           : STRING;
                                         Font           : FontTypeT;
                                         JustifyH       : JustT;
                                         JustifyV       : JustVT;
                                         TextIndent     : Float;
                                         Border,
                                         DropShadow     : BOOLEAN;
                                         PctGray,
                                         Hyt,
                                         Width          : REAL);
    VAR
        Tx,
        Ty             : Float;
    BEGIN
        SelectFont(Font);
        CASE JustifyH OF
            ELEFT :
                Tx := X + TextIndent;
            ECENTER :
                Tx := X + ((Width - ComputeStringWidth(Strg, CtrlForceToSpace)) / 2.0);
            ERIGHT :
                Tx := X + Width - ComputeStringWidth(Strg, CtrlForceToSpace) - TextIndent;
        END;
        CASE JustifyV OF
            ETOP :
                Ty := Y + GetLineSpacing;
            EVCENTER :
                Ty := Y + ((Hyt + (GetLineSpacing / 2.0)) / 2.0);
            EBOT :
                Ty := Y + Hyt - (GetLineSpacing / 2.0);
        END;
        DrawRasterBox(X, Y, Border, DropShadow, PctGray, Hyt, Width);
        PrnGotoXY(Tx, Ty);
        PutStr(Strg);
    END;

    {-----------------}

    PROCEDURE TPrinter.DrawShadedTextBoxDeluxe(X,
                                               Y              : Float;
                                               LStrg          : STRING;
                                               CStrg          : STRING;
                                               RStrg          : STRING;
                                               LFont          : FontTypeT;
                                               CFont          : FontTypeT;
                                               RFont          : FontTypeT;
                                               JustifyV       : JustVT;
                                               TextIndent     : Float;
                                               Border,
                                               DropShadow     : BOOLEAN;
                                               PctGray,
                                               Hyt,
                                               Width          : REAL);
        FUNCTION DoYStuff : Float;
        BEGIN
            CASE JustifyV OF
                ETOP :
                    DoYStuff := Y + GetLineSpacing;
                EVCENTER :
                    DoYStuff := Y + ((Hyt + (GetLineSpacing / 2.0)) / 2.0);
                EBOT :
                    DoYStuff := Y + Hyt - (GetLineSpacing / 2.0);
            END;
        END;
    BEGIN
        IF LStrg <> '' THEN BEGIN
            SelectFont(LFont);
            PrnGotoXY(X + TextIndent, DoYStuff);
            PutStr(LStrg);
        END;
        IF CStrg <> '' THEN BEGIN
            SelectFont(CFont);
            PrnGotoXY(X + ((Width - ComputeStringWidth(CStrg, CtrlForceToSpace)) / 2.0), DoYStuff);
            PutStr(CStrg);
        END;
        IF RStrg <> '' THEN BEGIN
            SelectFont(RFont);
            PrnGotoXY(X + Width - ComputeStringWidth(RStrg, CtrlForceToSpace) - TextIndent, DoYStuff);
            PutStr(RStrg);
        END;
        DrawRasterBox(X, Y, Border, DropShadow, PctGray, Hyt, Width);
    END;

    {-----------------}


    PROCEDURE ChrCat(VAR S : STRING; C : CHAR);
    BEGIN
        S := S + C;
    END;

    {-----------------}

    CONSTRUCTOR TFont.Init(CONST ID       : FontTypeT;
                           CONST PointSize : REAL;
                           CONST WidthTable : PathStr;
                           CONST SelectStr : STRING);
    VAR
        WidthFile      : FILE OF TCharWidthTable;
        OFM            : WORD;
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;

        IF NOT ExistFile(WidthTable) THEN BEGIN
            DispErrorDeluxe('missing file', WidthTable, TRUE, Iam);
            FAIL;
        END;
        {$I-}
        OFM := FILEMODE;
        FILEMODE := 0;
        ASSIGN(WidthFile, WidthTable);
        RESET(WidthFile);
        InitStatus := IORESULT;
        IF (InitStatus <> ecOk) THEN BEGIN
            FILEMODE := OFM;
            DispErrorDeluxe('Problem opening: ' + WidthTable, ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        READ(WidthFile, fMetrics);
        InitStatus := IORESULT;
        IF (InitStatus <> 0) THEN BEGIN
            FILEMODE := OFM;
            FAIL;
        END;

        CLOSE(WidthFile);
        InitStatus := IORESULT;
        IF (InitStatus <> ecOk) THEN BEGIN
            FILEMODE := OFM;
            FAIL;
        END;

        FID := ID;
        fSelectStr := StringToHeap(SelectStr);
        fPointSize := PointSize;

        { if no pitch specified, calculate the pitch }
        fHMI := fMetrics.Spacing;
        IF (fHMI <> 0) THEN
            fHMI := DesignUnitsToInches(TRUNC(fHMI))
        ELSE
            IF NOT fMetrics.Metrics[#32].Defined THEN
                fHMI := 0
        ELSE
            fHMI := DesignUnitsToInches(fMetrics.Metrics[#32].HorizEscape);
        {$I+}
        FILEMODE := OFM;
    END;

    {-----------------}

    DESTRUCTOR TFont.Done;
    BEGIN
        DisposeString(fSelectStr);

        INHERITED Done;
    END;

    {-----------------}

    FUNCTION TFont.DesignUnitsToInches(CONST Units : LONGINT) : REAL;
        {-Convert font design units to inches }
    BEGIN
        DesignUnitsToInches :=
            fMetrics.InchesPerPoint *
            fPointSize *
            (Units / fMetrics.DesignUnits)
    END;

    {-----------------}

    FUNCTION TFont.CalcStringWidth(CONST St : STRING; CtrlFlg : TCtrlFlg) : REAL;
        {-Calculate the width, in inches of a string }
    VAR
        Total          : LONGINT;
        OnChar         : BYTE;
        StLen          : BYTE;
        Strg           : STRING;
    BEGIN
        Strg := St;

        {trap control characters that crash the
        array with a range check error}
        StLen := LENGTH(Strg);
        CASE CtrlFlg OF
            CtrlForceToSpace :
                BEGIN
                    FOR OnChar := 1 TO StLen DO
                        IF (ORD(Strg[OnChar]) < 32) OR (ORD(Strg[OnChar]) > 127) THEN
                            Strg[OnChar] := ' '; {force control chars to spaces}
                END;
            CtrlSkip :
                Strg := Filter(Strg, [#0..#31, #127..#255]);
            CtrlPassThru : ;
        END;


        IF (StLen = 0) THEN BEGIN
            CalcStringWidth := 0;
            EXIT;
        END
        ELSE IF (StLen = 1) THEN BEGIN
            WITH fMetrics.Metrics[Strg[1]] DO BEGIN
                Total := LeftExtent + RightExtent;
                IF (Total = 0) AND (Strg = ' ') THEN
                    Total := HorizEscape;
            END;                  {with}
        END
        ELSE BEGIN
            Total := fMetrics.Metrics[Strg[1]].LeftExtent +
                     fMetrics.Metrics[Strg[1]].HorizEscape +
                     fMetrics.Metrics[Strg[StLen]].RightExtent;

            IF (StLen > 2) THEN
                FOR OnChar := 2 TO PRED(StLen) DO
                    INC(Total, fMetrics.Metrics[Strg[OnChar]].HorizEscape);
        END;

        CalcStringWidth := DesignUnitsToInches(Total);
    END;

    {-----------------}

    FUNCTION TFont.CalcCAP(CONST CurX : REAL; CONST St : STRING) : REAL;
        {-Calculate the Current Active Position after printing a string }
    VAR
        Total          : LONGINT;
        OnChar         : BYTE;
        StLen          : BYTE ABSOLUTE St;

    BEGIN
        Total := 0;
        IF (StLen = 0) THEN BEGIN
            CalcCAP := CurX;
            EXIT;
        END ELSE
            FOR OnChar := 1 TO StLen DO
                Total := Total + fMetrics.Metrics[St[OnChar]].HorizEscape;

        CalcCAP := CurX + DesignUnitsToInches(Total);
    END;

    {-----------------}

    FUNCTION TFont.GetLineSpacing : REAL;
        {-Get the recommended inter-line spacing }
    BEGIN
        GetLineSpacing := DesignUnitsToInches(fMetrics.LineSpacing);
    END;

    {-----------------}

    PROCEDURE TFont.GetMetrics(CONST Ch : CHAR; VAR LeftExt, RightExt, HorizEsc : REAL);
        {-Get the metrics for one character }
    BEGIN
        IF NOT fMetrics.Metrics[Ch].Defined THEN BEGIN
            LeftExt := 0;
            RightExt := 0;
            HorizEsc := fHMI;
        END ELSE BEGIN
            LeftExt := DesignUnitsToInches(fMetrics.Metrics[Ch].LeftExtent);
            RightExt := DesignUnitsToInches(fMetrics.Metrics[Ch].RightExtent);
            HorizEsc := DesignUnitsToInches(fMetrics.Metrics[Ch].HorizEscape);
        END;
    END;

    {-----------------}

    CONSTRUCTOR TPrinter.Init(PrnInfo        : TPrnCfg;
                              VAR MyCOP      : CylonP;
                              Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        GrafDriveInited := FALSE;
        AllowPrint := TRUE;

        COP := NIL;
        IF NOT InitPrim(PrnInfo,
                        MyCOP,
                        Mode) THEN BEGIN
            IF COP <> NIL THEN
                DISPOSE(COP, Done);
            FAIL;
        END;
    END;

    {-----------------}

    FUNCTION TPrinter.InitPrim(PrnInfo        : TPrnCfg;
                               VAR MyCOP      : CylonP;
                               Mode           : TxtGraf) : BOOLEAN;
    VAR
        Strg           : STRING;
        I              : CHAR;
        PError,
        MaxColors      : WORD;
        TrueBlack,
        T              : TPrnColors;
    BEGIN
        InitPrim := FALSE;
        FlakeyMixedTextGraph := FALSE;
        MyFontPath := PrnInfo.FontPath;
        {$IFNDEF VirtualPascal}
        BGIPath := PrnInfo.BGIPath;
        GDRes := FullHi;
        {$ENDIF}
        PrnPlot := EPrtOrient;

        IF PrnInfo.PPort = DiskFile THEN
            MyPortName := PrnInfo.PortName
        ELSE
            MyPortName := PrnNames[PrnInfo.PPort];

        IF Mode <> EPrnScreen THEN
            NEW(COP, InitCFD(' Printing ', 10, 0))
        ELSE
            COP := NIL;

        ljDuplex := FALSE;

        PageLabel := 'Page ';
        CurLeftMargin := 0.25;
        CurRightMargin := 8.25;
        CurTopMargin := 1.0;
        CurBottomMargin := 10.0;

        CurLineSpace := 0.22;
        CurPageNum := 1;

        IF COP <> NIL THEN
            COP^.Draw;
        CurRow := CurTopMargin;
        CurColumn := CurLeftMargin;

        MyCOP := COP;

        InitStatus := 0;

        IF NOT ljFonts.Init THEN
            EXIT;

        ljPrn := NIL;
        ljActiveFont := NIL;

        MyPort := PrnInfo.PPort;
        PType := PrnInfo.PType;
        MyOutMode := Mode;
        MyBlankTray := TLHSingle;

        IF Mode <> EPrnScreen THEN BEGIN

            GETDIR(0, Strg);

            CASE MyPort OF
                LPT1..LPT3 :
                    ljPrn := NEW(BiosPrinterPtr, Init(LPTTYPE(MyPort)));
                Prn,
                DiskFile :
                    ljPrn := NEW(DosPrinterPtr, Init(PrnInfo.PortName, MyPort));
                ELSE BEGIN
                    InitStatus := epFatal + ecInvalidPrinter;
                    ljFonts.Done;
                    EXIT;
                END;
            END;


            IF (ljPrn = NIL) THEN BEGIN
                InitStatus := epFatal + ecOutOfMemory;
                ljFonts.Done;
                EXIT;
            END;

            IF ljPrn^.pLastError <> 0 THEN BEGIN
                DispErrorDeluxe('Printer error',
                                Long2Str(ljPrn^.pLastError),
                                TRUE,
                                Iam);
                ljFonts.Done;
                DISPOSE(ljPrn, Done);
                EXIT;
            END;

            FOR I := #0 TO #255 DO
                CharTable[I] := I;

            ljPrn^.NewXlatCharTable(CharTable);

            ljInitStr := NIL;
            ljULOn := NIL;
            ljULOff := NIL;
            ljBoldOn := NIL;
            ljBoldOff := NIL;
            ljItalOn := NIL;
            ljItalOff := NIL;
            ljNewPage := NIL;

        END;

        ljCanBox := FALSE;
        ljCanHpgl := FALSE;

        {set wheel to all black}
        FILLCHAR(MyWheel, SIZEOF(MyWheel), CHAR(tpcBLACK));
        FILLCHAR(MyRGBTextWheel, SIZEOF(MyWheel), CHAR(tpcBLACK));

        MyRGBTextWheel[tpcBLACK] := 0;
        MyRGBTextWheel[tpcRED] := 1;
        MyRGBTextWheel[tpcGREEN] := 2;
        MyRGBTextWheel[tpcYELLOW] := 3;
        MyRGBTextWheel[tpcBLUE] := 4;
        MyRGBTextWheel[tpcMAGENTA] := 5;
        MyRGBTextWheel[tpcCYAN] := 6;
        MyRGBTextWheel[tpcWHITE] := 7;

        TrueBlack := tpcBLACK;
        ljIsColor := FALSE;
        MaxColors := 0;

        IF PType = Screen THEN BEGIN
            P1P2[EPrnTxt].TOP := 0.5;
            P1P2[EPrnTxt].Bot := 10.5;
            P1P2[EPrnTxt].LEFT := 0.25;
            P1P2[EPrnTxt].RIGHT := 8.25;
            P1P2[EPrnTxt].Driver := '_LJ';
            P1P2[EPrnGraph].Driver := '_LJ';
            P1P2[EPrnScreen].Driver := 'BGI256';
        END;

        InitPrim := TRUE;
    END;

    {-----------------}

    FUNCTION TPrinter.SetupGD(TrueBlack : TPrnColors; MaxColors : WORD) : BOOLEAN;
    VAR
        Tpt            : TP1P2Array;
        T              : TPrnColors;
    BEGIN
        SetupGD := TRUE;
        {$IFNDEF VirtualPascal}
        MyPrinter := P1P2[MyOutMode].Driver;
        {$ENDIF}

        Tpt := P1P2;

        IF MaxColors = 0 THEN BEGIN
            {$IFNDEF VirtualPascal}
            {do dummy init, so we can determine maxcolors}
            GrafDriveInit(1.0, 1.0, 2.0, 2.0, MyOutMode, 0);
            {$ENDIF}
            P1P2 := Tpt;

            {$IFNDEF VirtualPascal}
            MaxColors := GetMaxColor;
            {$ELSE}
                MaxColors := 1;
            {$ENDIF}

            FOR T := LOW(TPrnColors) TO HIGH(TPrnColors) DO
                MyWheel[T] := TPrnColors(BYTE(T) MOD MaxColors);

            {$IFNDEF VirtualPascal}
            GrafDriveFinish;
            {$ENDIF}
        END
        ELSE
            FILLCHAR(MyWheel, SIZEOF(MyWheel), CHAR(tpcWHITE));

        MyWheel[tpcBLACK] := TrueBlack;

        ljActiveFont := FindFontByID(fMain);
        {$IFNDEF VirtualPascal}
        MyPrinter := P1P2[EPrnTxt].Driver;
        {$ENDIF}
    END;

    PROCEDURE TPrinter.SetPageLabel(Strg : STRING);
    BEGIN
        PageLabel := Strg;
    END;

    {-----------------}

    FUNCTION TPrinter.GetPageLabel : STRING;
    BEGIN
        GetPageLabel := PageLabel;
    END;

    {-----------------}

    FUNCTION TPrinter.GetPortName : STRING;
    BEGIN
        GetPortName := PrnNames[MyPort];
    END;

    {-----------------}

    FUNCTION TPrinter.GetPort : PrnType;
    BEGIN
        GetPort := MyPort;
    END;

    {-----------------}

    PROCEDURE TPrinter.SetLeftMargin(M : REAL);
    BEGIN
        CurLeftMargin := M;
        CurColumn := M;
    END;

    {-----------------}

    PROCEDURE TPrinter.SetRightMargin(M : REAL);
    BEGIN
        CurRightMargin := M;
    END;

    {-----------------}

    PROCEDURE TPrinter.SetTopMargin(M : REAL);
    BEGIN
        CurTopMargin := M;
        CurRow := M;
    END;

    {-----------------}

    PROCEDURE TPrinter.SetBottomMargin(M : REAL);
    BEGIN
        CurBottomMargin := M;
    END;

    {-----------------}

    FUNCTION TPrinter.GetLeftMargin : REAL;
    BEGIN
        GetLeftMargin := CurLeftMargin;
    END;

    {-----------------}

    FUNCTION TPrinter.GetRightMargin : REAL;
    BEGIN
        GetRightMargin := CurRightMargin;
    END;

    {-----------------}

    FUNCTION TPrinter.GetTopMargin : REAL;
    BEGIN
        GetTopMargin := CurTopMargin;
    END;

    {-----------------}

    FUNCTION TPrinter.GetBottomMargin : REAL;
    BEGIN
        GetBottomMargin := CurBottomMargin;
    END;

    {-----------------}

    FUNCTION TPrinter.CenterStringX(S : STRING) : REAL;
        {-Return X starting point required to center string S}
    VAR
        Width          : REAL;
    BEGIN
        Width := ComputeStringWidth(S, CtrlForceToSpace);
        CenterStringX := CurLeftMargin + (((CurRightMargin - CurLeftMargin) - Width) / 2.0);
    END;

    {-------------}

    FUNCTION TPrinter.DownloadFont(IDNo           : FontTypeT;
                                   FontFileName   : STRING;
                                   PointSize      : REAL;
                                   Permanent      : BOOLEAN) : BOOLEAN;
    VAR
        ErrNum,
        NumRead        : INTEGER;
        FontFile       : FILE;
        Font           : STRING[128];
        OFM            : WORD;
    BEGIN
        {$I-}
        DownloadFont := FALSE;
        OFM := FILEMODE;
        FILEMODE := 0;
        ASSIGN(FontFile, FontFileName);
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            FILEMODE := OFM;
            DispErrorDeluxe('Problem opening: ' + FontFileName, ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;
        RESET(FontFile, 1);
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            FILEMODE := OFM;
            EXIT;
        END;
        AssignFontID(IDNo);
        WHILE NOT EOF(FontFile) DO BEGIN
            BLOCKREAD(FontFile, Font[1], 128, NumRead);
            InitStatus := IORESULT;
            IF InitStatus <> 0 THEN
                EXIT;
            Font[0] := CHAR(NumRead);
            PutStr(Font);
        END;
        IF Permanent THEN
            MakeFontPermanent
        ELSE
            MakeFontTemporary;
        CLOSE(FontFile);
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            FILEMODE := OFM;
            EXIT;
        END;

        {ZZZZ this is LJ specific}
        IF NOT AddFont(IDNo, PointSize, ForceExtension(FontFileName, 'CWD'),
                       #27'(' + Long2Str(BYTE(IDNo) + 1) + 'X') THEN BEGIN
            FILEMODE := OFM;
            EXIT;
        END;

        DownloadFont := TRUE;
        FILEMODE := OFM;
    END;

    {-----------------}

    PROCEDURE TPrinter.PrintAtRightTabRow(S : STRING; Row, TabStop : REAL);
    BEGIN
        PrnGotoXY(TabStop - ComputeStringWidth(S, CtrlForceToSpace), Row);
        PutStr(S);
    END;

    {-----------------}

    FUNCTION TPrinter.GetCanBox : BOOLEAN;
    BEGIN
        GetCanBox := ljCanBox;
    END;

    {-----------------}

    FUNCTION TPrinter.GetCanHPGL : BOOLEAN;
    BEGIN
        GetCanHPGL := ljCanHpgl;
    END;

    {-----------------}

    DESTRUCTOR TPrinter.Done;
    BEGIN
        {$IFNDEF VirtualPascal}
        IF GrafDriveInited THEN
            GrafDriveFinish;
        {$ENDIF}

        DisposeString(ljNewPage);
        DisposeString(ljULOff);
        DisposeString(ljULOn);
        DisposeString(ljBoldOff);
        DisposeString(ljBoldOn);
        DisposeString(ljInitStr);
        DisposeString(ljItalOff);
        DisposeString(ljItalOn);

        ljFonts.Done;
        DISPOSE(ljPrn, Done);
        IF COP <> NIL THEN BEGIN
            COP^.Select;
            DISPOSE(COP, Done);
        END;
        COP := NIL;
        INHERITED Done;
    END;

    {-----------------}

    FUNCTION TPrinter.PutStr(CONST St : STRING) : BOOLEAN;
        {-Send a string to the printer }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF (PType = NONE) OR (NOT AllowPrint) THEN
            EXIT;
        IF (St <> '') THEN
            ljPrn^.PrnPutBlock((@St[1])^, LENGTH(St));
        PostPrnError(Iam);
        PutStr := ljPrn^.pLastError = 0;
    END;

    {-----------------}

    FUNCTION TPrinter.PutStrRJ(CONST St : STRING; CONST X : REAL) : BOOLEAN;
        {-Send a right justified string to the printer }
    BEGIN
        PutStrRJ := PutStrXYRight(St, X, CurRow);
    END;

    {-----------------}

    FUNCTION TPrinter.PutLine(CONST St : STRING) : BOOLEAN;
    VAR
        T              : BOOLEAN;
        NewPos         : REAL;
    BEGIN
        PutLine := FALSE;
        IF NOT PutStr(St) THEN
            EXIT;
        IF NOT LineFeed(NewPos) THEN
            EXIT;
        PutLine := TRUE;
    END;

    {-----------------}

    {-Send a line of text to the printer and advance the cursor}
    FUNCTION TPrinter.PutCenteredLine(CONST St : STRING) : BOOLEAN;
    BEGIN
        PutCenteredLine := FALSE;
        IF NOT PrnGotoX(CenterStringX(St)) THEN
            EXIT;
        IF NOT PutLine(St) THEN
            EXIT;
        PutCenteredLine := TRUE;
    END;

    {-----------------}

    {-Send a string to the printer, underlining it }
    FUNCTION TPrinter.PutStrUL(CONST St : STRING) : BOOLEAN;
    BEGIN
        PutStrUL := FALSE;
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT UnderLineOn THEN
            EXIT;
        IF NOT PutStr(St) THEN
            EXIT;
        IF NOT UnderLineOff THEN
            EXIT;
        PutStrUL := TRUE;
    END;

    {-----------------}

    {-Print a string at the specify coordinate }
    FUNCTION TPrinter.PutStrXY(CONST St : STRING; CONST X, Y : REAL) : BOOLEAN;
    BEGIN
        PutStrXY := FALSE;
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT PrnGotoXY(X, Y) THEN
            EXIT;
        PutStrXY := PutStr(St);
    END;

    {-----------------}

    {-Right justify a string at the specified coordinates }
    FUNCTION TPrinter.PutStrXYRight(CONST St : STRING; CONST X, Y : REAL) : BOOLEAN;
    BEGIN
        PutStrXYRight := FALSE;
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT PrnGotoXY(X - ComputeStringWidth(St, CtrlForceToSpace), Y) THEN
            EXIT;
        PutStrXYRight := PutStr(St);
    END;

    {-----------------}

    {-Initialize a print job }
    FUNCTION TPrinter.InitJob : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        InitJob := PutStr(StringFromHeap(ljInitStr));
    END;

    {-----------------}

    FUNCTION TPrinter.FormFeed : BOOLEAN;
        {-Eject the current page }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        FormFeed := PutStr(StringFromHeap(ljNewPage));

        CurRow := CurTopMargin;
        CurColumn := CurLeftMargin;
    END;

    {-----------------}

    {-Convert inches to decipoints }
    FUNCTION InToDP(CONST Inches : REAL) : REAL;
    BEGIN
        InToDP := ROUND(Inches * 720 * 10000) / 10000;
    END;

    {-----------------}

    {-Convert inches to PCL dots }
    FUNCTION InToDots(CONST Inches : REAL) : INTEGER;
    BEGIN
        InToDots := ROUND(Inches * LJDPI);
    END;

    {-----------------}

    {-Convert PCL dots to inches }
    FUNCTION DotsToIn(CONST Dots : LONGINT) : REAL;
    BEGIN
        DotsToIn := (Dots / LJDPI);
    END;

    {-----------------}

    {-Convert PCL dots to decipoints }
    FUNCTION DotsToDP(CONST Dots : LONGINT) : REAL;
    BEGIN
        DotsToDP := InToDP(Dots / LJDPI);
    END;

    {-----------------}

    {-Convert a real number to a string suitable for sending to the printer }
    FUNCTION PrnRealStr(CONST R : REAL) : STRING;
    VAR
        St             : STRING;
        StLen          : BYTE ABSOLUTE St;

    BEGIN
        St := Trim(Real2Str(R, 12, 4));
        WHILE (StLen <> 0) AND (St[StLen] = '0') DO
            DEC(StLen);
        IF (StLen <> 0) AND (St[StLen] = '.') THEN
            DEC(StLen);
        IF (StLen = 0) THEN
            PrnRealStr := '0'
        ELSE
            PrnRealStr := St;
    END;

    {-----------------}

    {-advance to the next line using the current font for delta}
    FUNCTION TPrinter.LineFeed(VAR NewPos : REAL) : BOOLEAN;
    BEGIN
        LineFeed := FALSE;
        IF NOT PrnAdvanceY(ljActiveFont^.GetLineSpacing) THEN
            EXIT;
        LineFeed := PrnGotoX(CurLeftMargin);
        NewPos := CurRow;
    END;

    {-----------------}

    FUNCTION TPrinter.GetPointSize : REAL;
    BEGIN
        GetPointSize := ljActiveFont^.fPointSize;
    END;

    {-----------------}

    {-Download a raster graphic to the printer }
    FUNCTION TPrinter.DownloadGraphic(CONST FName : PathStr) : WORD;
    CONST
        DLBufSize      = 1024;

    VAR
        Buffer         : ARRAY[0..DLBufSize] OF CHAR;
        F              : FILE;
        OFM,
        Bytes,
        I              : WORD;
    BEGIN
        {$I-}
        OFM := FILEMODE;
        FILEMODE := 0;
        ASSIGN(F, FName);
        RESET(F, 1);
        InitStatus := IORESULT;
        IF (InitStatus <> ecOk) THEN BEGIN
            {FreeMemCheck(Buffer, DLBufSize);}
            DownloadGraphic := InitStatus;
            FILEMODE := OFM;
            DispErrorDeluxe('Problem opening: ' + FName, ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;

        REPEAT
            IF COP <> NIL THEN
                COP^.UpDate;
            BLOCKREAD(F, Buffer, DLBufSize, Bytes);
            IF Bytes = 0 THEN
                BREAK;
            IF (PType <> NONE) AND AllowPrint THEN
                ljPrn^.PrnPutBlock(Buffer, Bytes);
        UNTIL Bytes <> DLBufSize;

        CLOSE(F);
        InitStatus := IORESULT;
        FILEMODE := OFM;
        DownloadGraphic := ecOk;
        {$I+}
    END;

    {-----------------}

    FUNCTION TPrinter.AddFont(CONST ID       : FontTypeT;
                              CONST PointSize : REAL;
                              CONST WidthTable : PathStr;
                              CONST SelectStr : STRING) : BOOLEAN;
        {-Add a font to the printer }
    VAR
        NewFont        : PFont;

    BEGIN
        NEW(NewFont, Init(ID, PointSize, WidthTable, SelectStr));
        IF (NewFont = NIL) THEN BEGIN
            DispErrorDeluxe('problem adding font ' + WidthTable,
                            ErrorMessage(InitStatus), TRUE, Iam);
            AddFont := FALSE
        END
        ELSE BEGIN
            ljFonts.APPEND(NewFont);
            AddFont := TRUE;
        END;
    END;

    {-----------------}

    {-Find a font with a matching ID }
    FUNCTION TPrinter.FindFontByID(CONST ID : FontTypeT) : PFont;
    VAR
        CurFont        : PFont;
    BEGIN
        CurFont := PFont(ljFonts.Head);
        WHILE (CurFont <> NIL) DO BEGIN
            IF (CurFont^.FID = ID) THEN BEGIN
                FindFontByID := CurFont;
                EXIT;
            END;
            CurFont := PFont(ljFonts.Next(CurFont));
        END;
        FindFontByID := NIL;
    END;

    {-----------------}

    PROCEDURE TPrinter.RemoveFont(CONST ID : FontTypeT);
        {-Remove a font from the printer }
    VAR
        Font           : PFont;

    BEGIN
        Font := FindFontByID(ID);
        IF (Font <> NIL) THEN
            ljFonts.DELETE(Font);
    END;

    {-----------------}

    PROCEDURE TPrinter.SelectFont(CONST ID : FontTypeT);
        {-Find a font and make it active }
    VAR
        Font           : PFont;
        St             : STRING;

    BEGIN
        Font := FindFontByID(ID);
        IF Font = ljActiveFont THEN
            EXIT;
        IF (Font <> NIL) THEN BEGIN
            PutStr(StringFromHeap(Font^.fSelectStr));
            ljActiveFont := Font;
        END;
    END;

    {-----------------}

    FUNCTION TPrinter.ComputeStringWidth(CONST St : STRING; CtrlFlg : TCtrlFlg) : REAL;
        {-Compute the width of a string, in inches, for the active font }
    BEGIN
        IF (ljActiveFont = NIL) THEN
            ComputeStringWidth := 0
        ELSE
            ComputeStringWidth := ljActiveFont^.CalcStringWidth(St, CtrlFlg);
    END;

    {-----------------}

    FUNCTION TPrinter.ComputeStringWidthF(CONST St : STRING; CONST ID : FontTypeT; CtrlFlg : TCtrlFlg) : REAL;
        {-Compute the width of a string, in inches, for a given font }
    VAR
        FP             : PFont;
    BEGIN
        FP := FindFontByID(ID);
        IF (FP = NIL) THEN
            ComputeStringWidthF := 0.0
        ELSE
            ComputeStringWidthF := FP^.CalcStringWidth(St, CtrlFlg);
    END;

    {-----------------}

    {-Compute the width of a string, in inches, for a given font and     }
    { respond to the current typeface control characters embedded in the }
    { string                                                             }

    FUNCTION TPrinter.ComputeStringWidthMF(CONST St : STRING; CONST ID : FontTypeT; Flags : BYTE) : REAL;
    VAR
        I              : BYTE;
        Len            : REAL;
        Strg           : STRING;

        FUNCTION CalcCharWidth(C : CHAR; Flg : BYTE) : REAL;
        VAR
            FP             : PFont;
        BEGIN
            IF (Flg AND wrBold) > 0 THEN
                FP := FindFontByID(TFontVarient[ID, SBold])
            ELSE IF (Flg AND wrItalic) > 0 THEN
                FP := FindFontByID(TFontVarient[ID, SItalic])
            ELSE
                FP := FindFontByID(TFontVarient[ID, SNorm]);

            IF FP <> NIL THEN
                CalcCharWidth := FP^.CalcStringWidth(C, CtrlPassThru)
            ELSE
                CalcCharWidth := 0.1;
        END;

    BEGIN
        Len := 0.0;
        FOR I := 1 TO LENGTH(St) DO BEGIN
            CASE St[I] OF
                BoldTok :
                    Flags := Flags XOR wrBold;
                ItalicTok :
                    Flags := Flags XOR wrItalic;
                ULTok :
                    Flags := Flags XOR wrUL;
                ELSE
                    Len := Len + CalcCharWidth(CharTable[St[I]], Flags);
            END;                  {case}
        END;

        ComputeStringWidthMF := Len;
    END;

    {-----------------}

    FUNCTION TPrinter.GetLineSpacing : REAL;
        {-Get the recommended line spacing for the current font }
    BEGIN
        IF (ljActiveFont = NIL) THEN
            GetLineSpacing := 0
        ELSE
            GetLineSpacing := ljActiveFont^.GetLineSpacing;
    END;

    {-----------------}

    FUNCTION TPrinter.UnderLineOn : BOOLEAN;
        {-Turn on printer underlining }
    BEGIN
        UnderLineOn := PutStr(StringFromHeap(ljULOn));
    END;

    {-----------------}

    FUNCTION TPrinter.UnderLineOff : BOOLEAN;
        {-Turn off printer underlining }
    BEGIN
        UnderLineOff := PutStr(StringFromHeap(ljULOff));
    END;

    {-----------------}

    FUNCTION TPrinter.BoldOn : BOOLEAN;
    BEGIN
        BoldOn := PutStr(StringFromHeap(ljBoldOn));
    END;

    {-----------------}

    FUNCTION TPrinter.BoldOff : BOOLEAN;
    BEGIN
        BoldOff := PutStr(StringFromHeap(ljBoldOff));
    END;

    {-----------------}

    FUNCTION TPrinter.ItalOn : BOOLEAN;
    BEGIN
        ItalOn := PutStr(StringFromHeap(ljULOn)); {zzzz}
    END;

    {-----------------}

    FUNCTION TPrinter.ItalOff : BOOLEAN;
    BEGIN
        ItalOff := PutStr(StringFromHeap(ljULOff)); {zzzz}
    END;

    {-----------------}

    PROCEDURE TPrinter.SetDuplexMode(Mode : BOOLEAN);
    BEGIN
        {override this in specific printers that can handle duplex printing}
    END;

    {-----------------}

    {-Print a tag and data between Left and Right with a dot leader }
    PROCEDURE TPrinter.TagAndDataWithLeader(CONST Tag, Data : STRING;
                                            CONST LEFT, RIGHT : REAL;
                                            CONST LineFont : FontTypeT);
    VAR
        TagWidth       : REAL;
        DataWidth      : REAL;
        LeaderLen      : REAL;
        DotLeft        : REAL;
        DotRight       : REAL;
        DotEsc         : REAL;
        DotWidth       : REAL;
        TwoWidth       : REAL;
        I              : WORD;
        NumDots        : WORD;

    BEGIN
        SelectFont(LineFont);

        TagWidth := ljActiveFont^.CalcCAP(0, Tag);
        DataWidth := ComputeStringWidth(Data, CtrlForceToSpace);

        { put the tag and the data on the page }
        PrnGotoX(RIGHT - DataWidth);
        PutStr(Data);
        PrnGotoX(LEFT);
        PutStr(Tag);

        { calculate the length of the leader }
        LeaderLen := (RIGHT - LEFT) - TagWidth - DataWidth;
        ljActiveFont^.GetMetrics('.', DotLeft, DotRight, DotEsc);

        { calculate the number of dots in the leader }
        DotWidth := DotLeft + DotRight;
        IF (DotWidth > LeaderLen) THEN
            { no dots will fit }
            EXIT;

        TwoWidth := DotWidth + DotEsc;
        IF (TwoWidth > LeaderLen) THEN
            NumDots := 1
        ELSE
            NumDots := ROUND((LeaderLen - TwoWidth) / DotEsc);

        { output the leader }

        {ZZZZ deskjet font metrics kludge}
        IF NumDots >= 3 THEN
            DEC(NumDots, 3);

        PutStr(CharStr('.', NumDots));
        {SelectFont(fMainMedium);}
    END;

    {-----------------}

    FUNCTION TPrinter.CenterData(CONST Data : STRING; CONST LEFT, RIGHT : REAL) : REAL;
        {-Center a line of data between two points }
    VAR
        Distance       : REAL;
        Len            : REAL;
        XPos           : REAL;

    BEGIN
        Distance := RIGHT - LEFT;
        Len := ComputeStringWidth(Data, CtrlForceToSpace);
        IF (Len > Distance) THEN
            XPos := LEFT
        ELSE
            XPos := LEFT + ((Distance - Len) / 2);
        PrnGotoX(XPos);
        PutStr(Data);
        CenterData := XPos;
    END;

    {-----------------}

    PROCEDURE TPrinter.PrnPutBlock(VAR Block; BlockSize : WORD);
    BEGIN
        IF (PType <> NONE) AND AllowPrint THEN
            ljPrn^.PrnPutBlock(Block, BlockSize);
    END;

    {-----------------}

    FUNCTION TPrinter.PrnError : WORD;
    BEGIN
        PrnError := ljPrn^.PrnError;
    END;

    {-----------------}

    FUNCTION TPrinter.GetPtype : PrnModelT;
    BEGIN
        GetPtype := PType;
    END;

    {-----------------}

    FUNCTION TPrinter.GetCOP : CylonP;
    BEGIN
        GetCOP := COP;
    END;

    {-----------------}

    PROCEDURE TPrinter.PrintAtLeftTabRow(S : STRING; Row, TabStop : REAL);
    BEGIN
        PrnGotoXY(TabStop, Row);
        PutStr(S);
    END;

    {-----------------}

    {center a page number at bottom margin}
    PROCEDURE TPrinter.DoPageNumAndFF;
    VAR
        CurFont        : PFont;
    BEGIN
        {save the current font}
        CurFont := ljActiveFont;
        {switch to fMain font}
        SelectFont(fMain);
        {move to the bottom margin}
        PrnGotoY(CurBottomMargin + 0.25);
        {center the page number}
        PutCenteredLine(PageLabel + Long2Str(CurPageNum));
        {increment the page number}
        INC(CurPageNum);
        {pagefeed}
        FormFeed;
        {switch back to the old font}
        ljActiveFont := CurFont;
        {home to upper left}
        PrnGotoXY(CurLeftMargin, CurTopMargin);
    END;

    {-----------------}

    FUNCTION PercentStr(CONST Pc : REAL) : STRING;
    VAR
        S              : STRING[10];
        SLen           : BYTE ABSOLUTE S;

    BEGIN
        S := Form('####.##', Pc);
        WHILE (SLen <> 0) AND (S[SLen] = '0') DO
            DEC(SLen);
        IF (SLen <> 0) AND (S[SLen] = '.') THEN
            DEC(SLen);
        PercentStr := ' (' + Trim(S) + '%)';
    END;

    {-----------------}

    FUNCTION TPrinter.GetModeStr(Mode : CharModeT) : STRING;
    BEGIN
        GetModeStr := '';
        CASE Mode OF
            EINIT :
                GetModeStr := StringFromHeap(ljInitStr);
            EBOLDON :
                GetModeStr := StringFromHeap(ljBoldOn);
            EULON :
                GetModeStr := StringFromHeap(ljULOn);
            EITALON :
                GetModeStr := StringFromHeap(ljItalOn);
            EBOLDOFF :
                GetModeStr := StringFromHeap(ljBoldOff);
            EULOFF :
                GetModeStr := StringFromHeap(ljULOff);
            EITALOFF :
                GetModeStr := StringFromHeap(ljItalOff);
            ENEWPAGE :
                GetModeStr := StringFromHeap(ljNewPage);
        END;                      {case}
    END;

    {-----------------}

    FUNCTION TPrinter.LoadCharTable(Name : PathStr) : BOOLEAN;
    VAR
        F              : FILE OF XlatCharTable;
        OFM            : WORD;
    BEGIN
        LoadCharTable := FALSE;
        OFM := FILEMODE;
        FILEMODE := 0;
        Name := ForceExtension(Name, 'xlc');

        ASSIGN(F, ForcePath(MyFontPath, Name));
        {$I-}
        RESET(F);
        {$I+}
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            DispErrorDeluxe('Problem opening: ' + ForceExtension(Name, 'xlc'), ErrorMessage(InitStatus), TRUE, Iam);
            FILEMODE := OFM;
            EXIT;
        END;

        READ(F, CharTable);
        CLOSE(F);

        ljPrn^.NewXlatCharTable(CharTable);

        FILEMODE := OFM;
        LoadCharTable := TRUE;
    END;

    {--------------}

    {$IFNDEF VirtualPascal}
    PROCEDURE TPrinter.GrafDriveInit(P1x, P1y, P2x, P2y : REAL;
                                     Mode           : TxtGraf;
                                     ResMode        : WORD);
    VAR
        Res            : WORD;
    BEGIN
        IF GrafDriveInited THEN
            GrafDriveFinish;

        MyOutMode := Mode;
        FILLCHAR(Info, SIZEOF(Info), #0);
        IF Mode <> EPrnScreen THEN
            Info.DrvOptions := gdFFno +
                               gdNoReset +
                               gdFinePattern +
                               gdNoCls +
                               {$IFNDEF DPMI}
                               gdUseEMS +
                               {$ENDIF}
                               gdCustomPage
        ELSE
            Info.DrvOptions := gdFFno +
                               gdNoReset +
                               gdFinePattern +
                               {$IFNDEF DPMI}
                               gdUseEMS +
                               {$ENDIF}
                               gdNoCls;

        P1P2[Mode].LEFT := P1x;
        P1P2[Mode].RIGHT := P2x;
        P1P2[Mode].TOP := P1y;
        P1P2[Mode].Bot := P2y;

        IF Mode <> EPrnScreen THEN BEGIN
            Info.Width := ROUND((P2x - P1x) * 1000.0);
            Info.Height := ROUND((P2y - P1y) * 1000.0);
            Info.LeftMargin := ROUND(P1x * 1000.0);
            Info.TopMargin := ROUND(P1y * 1000.0);
        END;

        StatType := UserSTAT;
        Info.StatFunc := @GStat;
        {$IFNDEF DPMI}
        Info.EMSpages := 64;
        {$ELSE}
        info.EMSpages := 0;
        {$ENDIF}

        CASE MyPort OF
            Prn,
            LPT1 :
                Boiler45.MyPort := PortLPT1B;
            LPT2 :
                Boiler45.MyPort := PortLPT2B;
            LPT3 :
                Boiler45.MyPort := PortLPT3B;
            DiskFile :
                BEGIN
                    Boiler45.MyPort := PortFile;
                    MyOutFile := MyPortName;
                END;
        END;                      {case}

        PPrt := @Self;            {this is dangerous! ZZZZ}

        IF NOT GrafDriveInited THEN BEGIN

            IF Mode = EPrnScreen THEN
                Res := ResMode
            ELSE
                Res := GDRes;

            IF MyEnterGraphics(Mode, Res) = 0 THEN BEGIN
                {MyBeginPage;}
                GraphDefaults;
                GrafDriveInited := TRUE;
            END;
        END;
    END;

    {--------------}

    PROCEDURE TPrinter.GrafDriveInitBand(P1x, P1y,
                                         P2x, P2y       : REAL;
                                         Mode           : TxtGraf;
                                         ResMode        : WORD);
    VAR
        Res            : WORD;
    BEGIN
        IF GrafDriveInited THEN
            GrafDriveFinish;

        MyOutMode := Mode;
        FILLCHAR(Info, SIZEOF(Info), #0);
        IF Mode <> EPrnScreen THEN
            Info.DrvOptions := gdFFno +
                               gdNoReset +
                               gdFinePattern +
                               gdNoCls +
                               {$IFNDEF DPMI}
                               gdUseEMS +
                               gdUserBanding +
                               {$ENDIF}
                               gdCustomPage
        ELSE
            Info.DrvOptions := gdFFno +
                               gdNoReset +
                               gdFinePattern +
                               {$IFNDEF DPMI}
                               gdUseEMS +
                               gdUserBanding +
                               {$ENDIF}
                               gdNoCls;

        P1P2[Mode].LEFT := P1x;
        P1P2[Mode].RIGHT := P2x;
        P1P2[Mode].TOP := P1y;
        P1P2[Mode].Bot := P2y;

        IF Mode <> EPrnScreen THEN BEGIN
            Info.Width := ROUND((P2x - P1x) * 1000.0);
            Info.Height := ROUND((P2y - P1y) * 1000.0);
            Info.LeftMargin := ROUND(P1x * 1000.0);
            Info.TopMargin := ROUND(P1y * 1000.0);
        END;

        StatType := UserSTAT;
        Info.StatFunc := @GStat;
        {$IFNDEF DPMI}
        Info.EMSpages := 64;
        {$ELSE}
        info.EMSpages := 0;
        {$ENDIF}

        CASE MyPort OF
            Prn,
            LPT1 :
                Boiler45.MyPort := PortLPT1B;
            LPT2 :
                Boiler45.MyPort := PortLPT2B;
            LPT3 :
                Boiler45.MyPort := PortLPT3B;
            DiskFile :
                BEGIN
                    Boiler45.MyPort := PortFile;
                    MyOutFile := MyPortName;
                END;
        END;                      {case}

        PPrt := @Self;            {this is dangerous! ZZZZ}

        IF NOT GrafDriveInited THEN BEGIN

            IF Mode = EPrnScreen THEN
                Res := ResMode
            ELSE
                Res := GDRes;

            IF MyEnterGraphics(Mode, Res) = 0 THEN BEGIN
                {MyBeginPage;}
                GraphDefaults;
                GrafDriveInited := TRUE;
            END;
        END;
    END;


    {init GrafDrive using new printer/plotter driver}
    PROCEDURE TPrinter.GrafDriveInitDeluxe(Mode           : TxtGraf;
                                           P1x, P1y,
                                           P2x, P2y       : REAL;
                                           ResMode        : WORD);
    BEGIN
        MyPrinter := P1P2[Mode].Driver;
        GrafDriveInit(P1x, P1y, P2x, P2y, Mode, ResMode);
    END;

    {--------------}

    {initialize the grafdrive unit and select portrait/landscape}
    {using percent of fullpage for extents                      }
    PROCEDURE TPrinter.GrafDriveInitPL(Mode           : TxtGraf;
                                       P1x, P1y,
                                       P2x, P2y       : REAL;
                                       PL             : TGrafOrient;
                                       CustomPage     : BOOLEAN);
    VAR
        vP1x, vP1y,
        vP2x, vP2y     : WORD;


        FUNCTION ConvX(X : REAL) : INTEGER;
        BEGIN
            {calc coord based on percent of max}
            ConvX := ROUND((X / 100.0) * GetMaxX);
        END;

        FUNCTION ConvY(Y : REAL) : INTEGER;
        VAR
            M              : WORD;
        BEGIN
            {calc coord based on percent of max}
            ConvY := ROUND((Y / 100.0) * GetMaxY);
        END;
    VAR
        Res            : WORD;
    BEGIN
        GDRes := GrafModeLUT[PType, PL];
        MyPrinter := P1P2[Mode].Driver;

        P1P2[Mode].LEFT := P1x;
        P1P2[Mode].RIGHT := P2x;
        P1P2[Mode].TOP := P1y;
        P1P2[Mode].Bot := P2y;

        IF GrafDriveInited THEN
            GrafDriveFinish;

        MyOutMode := Mode;
        FILLCHAR(Info, SIZEOF(Info), #0);
        Info.DrvOptions := gdFFno +
                           gdNoReset +
                           gdFinePattern +
                           {$IFNDEF DPMI}
                           gdUseEMS +
                           {$ENDIF}
                           gdNoCls;

        IF PrnPlot = EPlotOrient THEN BEGIN
            IF CustomPage THEN BEGIN
                INC(Info.DrvOptions, gdCustomPage);
                IF PL = EPortrait THEN BEGIN
                    Info.Width := ROUND(7.0 * 1000.0);
                    Info.Height := ROUND(9.5 * 1000.0);
                    Info.LeftMargin := ROUND(1.0 * 1000.0);
                    Info.TopMargin := ROUND(0.5 * 1000.0);
                END
                ELSE BEGIN
                    Info.Width := ROUND(10.5 * 1000.0);
                    Info.Height := ROUND(8.0 * 1000.0);
                    Info.LeftMargin := ROUND(0.5 * 1000.0);
                    Info.TopMargin := ROUND(0.5 * 1000.0);
                END;
            END;
        END;

        StatType := UserSTAT;
        Info.StatFunc := @GStat;
        {$IFNDEF DPMI}
        Info.EMSpages := 64;
        {$ELSE}
        info.EMSpages := 0;
        {$ENDIF}

        CASE MyPort OF
            Prn,
            LPT1 :
                Boiler45.MyPort := PortLPT1B;
            LPT2 :
                Boiler45.MyPort := PortLPT2B;
            LPT3 :
                Boiler45.MyPort := PortLPT3B;
            DiskFile :
                BEGIN
                    Boiler45.MyPort := PortFile;
                    MyOutFile := MyPortName;
                END;
        END;                      {case}

        PPrt := @Self;            {this is dangerous! ZZZZ}

        IF NOT GrafDriveInited THEN BEGIN
            IF MyEnterGraphics(Mode, GrafModeLUT[PType, PL]) = 0 THEN BEGIN
                {MyBeginPage;}
                GraphDefaults;
                GrafDriveInited := TRUE;
            END;
        END;

        vP1x := ConvX(P1x);
        vP1y := ConvY(P1y);
        vP2x := ConvX(P2x);
        vP2y := ConvY(P2y);

        SetViewport(vP1x, vP1y, vP2x, vP2y, TRUE);
    END;

    {--------------}

    {shut down grafdrive engine}
    PROCEDURE TPrinter.GrafDriveFinish;
    BEGIN
        IF NOT GrafDriveInited THEN
            EXIT;
        MyEndPage;
        IF ljCanHpgl THEN
            GoPCL;
        MyExitGraphics;           { printer }
        IF blErrCode <> 0 THEN
            PgmAbort(Iam);
        MyOutMode := EPrnTxt;
        GrafDriveInited := FALSE;
    END;

    {--------------}
    {$ENDIF}

    FUNCTION TPrinter.XOffset(A, B, Amt : INTEGER) : INTEGER;
    VAR
        T              : INTEGER;
        BisectedAngle  : REAL;
    BEGIN
        BisectedAngle := (A * 1.0 + B * 1.0) / 2.0;
        BisectedAngle := BisectedAngle * DegreesToRadians;
        T := ROUND(COS(BisectedAngle) * Amt);
        XOffset := T;
    END;

    {-------------------}

    FUNCTION TPrinter.Yoffset(A, B, Amt : INTEGER) : INTEGER;
    VAR
        T              : INTEGER;
        BisectedAngle  : REAL;
    BEGIN
        BisectedAngle := (A * 1.0 + B * 1.0) / 2.0;
        BisectedAngle := BisectedAngle * DegreesToRadians;
        T := ROUND(SIN(BisectedAngle) * Amt);
        Yoffset := T;
    END;

    {-------------------}

    FUNCTION TPrinter.ExplByAngle(InAngle : INTEGER; Radius : LONGINT) : INTEGER;
    VAR
        N              : INTEGER;
    BEGIN
        InAngle := (InAngle MOD 360);
        N := Radius DIV 15;       {zzzz}
        CASE InAngle OF
            0..4 :
                ExplByAngle := ROUND(N * 2.0);
            5..15 :
                ExplByAngle := ROUND(N * 1.8);
            16..45 :
                ExplByAngle := ROUND(N * 1.5);
            46..180 :
                ExplByAngle := ROUND(N * 1.2);
            181..360 :
                ExplByAngle := ROUND(N * 1.0);
        END;
    END;

    {-------------------}

    FUNCTION TPrinter.Quadrant(InAngle : INTEGER) : BYTE;
    BEGIN
        InAngle := (InAngle MOD 360);
        CASE InAngle OF
            0..90 :
                Quadrant := 1;
            91..180 :
                Quadrant := 2;
            181..270 :
                Quadrant := 3;
            271..360 :
                Quadrant := 4;
        END;
    END;

    {-------------------}

    PROCEDURE TPrinter.SetFontSize(Font : FontTypeT);
    BEGIN
        CASE Font OF
            fNone :
                EXIT;
            fSmall :
                SetFont(TriplexFont, HorizDir, 5, 5, PtUnits);
            fLinePrint,
            fCourier :
                SetFont(SansSerifFont, HorizDir, 6, 6, PtUnits);
            fTable :
                SetFont(TriplexFont, HorizDir, 6, 6, PtUnits);
            fMainMedium,
            fItalicMedium,
            fMain,
            fFootnote,
            fItalic :
                SetFont(TriplexFont, HorizDir, 7, 7, PtUnits);
            fBoldMedium,
            fBoldItalic,
            fBold :
                SetFont(TriplexFont, HorizDir, 8, 8, PtUnits);
            fHuge :
                SetFont(TriplexFont, HorizDir, 9, 9, PtUnits);
        END;
    END;

    {-------------------}

    PROCEDURE TPrinter.CalcPointers(NoOfSlices     : BYTE;
                                    VAR PieSpec    : TPieArray;
                                    MinPointerLineLength,
                                    MinVertDistance,
                                    Rotation       : INTEGER);
    VAR
        I              : BYTE;
        CurLen         : INTEGER;
        FirstOne       : BOOLEAN;
        ThisY,
        LastY          : INTEGER;

        {-------------------}

        FUNCTION YVal(InAngle, InLen : INTEGER) : INTEGER;
        BEGIN
            YVal := ROUND(SIN(InAngle * DegreesToRadians) * InLen);
        END;

        {-------------------}

        FUNCTION NewY(InAngle, InLen : INTEGER) : INTEGER;
        BEGIN
            IF (ABS(SIN(InAngle * DegreesToRadians)) < 0.05) THEN
                NewY := InLen
            ELSE
                NewY := ABS(ROUND((InLen * 0.8) / SIN(InAngle * DegreesToRadians)));
        END;

    BEGIN
        { this part should be pretty straightforward... }
        { 1. Establish the new angle of the label line  }
        FOR I := 1 TO NoOfSlices DO BEGIN
            WITH PieSpec[I] DO
                LabelLineAngle := ((StartAngle + Rotation) + (EndAngle + Rotation)) DIV 2;
        END;
        { 2. Set each pointerlength to the default }
        FOR I := 1 TO NoOfSlices DO
            PieSpec[I].LabelLineLength := MinPointerLineLength;

        { 3. This part is a little trickier -- we lengthen pointer lines such
         that the vertical distance between adjacent lines is at least
         MinVertDistance, within the context of each quadrant, going away
         from the x-axis
        }

        { Start in Quadrant #1, we go in "regular" order }
        FirstOne := TRUE;
        FOR I := 1 TO NoOfSlices DO BEGIN
            IF Quadrant(PieSpec[I].LabelLineAngle) = 1 THEN BEGIN
                IF NOT FirstOne THEN BEGIN
                    { if the difference in vertical offset < MinVertDistance then
                    make it equal to MinVertDistance
                    }
                    ThisY := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
                    LastY := YVal(PieSpec[I - 1].LabelLineAngle, PieSpec[I - 1].LabelLineLength);
                    IF (ABS(ThisY - LastY) < MinVertDistance) THEN
                        PieSpec[I].LabelLineLength := NewY(PieSpec[I].LabelLineAngle, LastY + MinVertDistance);
                END
                ELSE
                    FirstOne := FALSE;
            END;
        END;

        { Quadrant #2, we go in "reverse" order }
        FirstOne := TRUE;
        FOR I := NoOfSlices DOWNTO 1 DO BEGIN
            IF Quadrant(PieSpec[I].LabelLineAngle) = 2 THEN BEGIN
                IF NOT FirstOne THEN BEGIN
                    { if the difference in vertical offset < MinVertDistance then
                    make it equal to MinVertDistance
                    }
                    ThisY := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
                    LastY := YVal(PieSpec[I + 1].LabelLineAngle, PieSpec[I + 1].LabelLineLength);
                    IF (ABS(ThisY - LastY) < MinVertDistance) THEN
                        PieSpec[I].LabelLineLength := NewY(PieSpec[I].LabelLineAngle, LastY + MinVertDistance);
                END
                ELSE
                    FirstOne := FALSE;
            END;
        END;

        { Quadrant #3, we go in "regular" order }
        FirstOne := TRUE;
        FOR I := 1 TO NoOfSlices DO BEGIN
            IF Quadrant(PieSpec[I].LabelLineAngle) = 3 THEN BEGIN
                IF NOT FirstOne THEN BEGIN
                    { if the difference in vertical offset < MinVertDistance then
                    make it equal to MinVertDistance
                    }
                    ThisY := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
                    LastY := YVal(PieSpec[I - 1].LabelLineAngle, PieSpec[I - 1].LabelLineLength);
                    IF (ABS(ThisY - LastY) < MinVertDistance) THEN
                        PieSpec[I].LabelLineLength := NewY(PieSpec[I].LabelLineAngle, LastY + MinVertDistance);
                END
                ELSE
                    FirstOne := FALSE;
            END;
        END;

        { Quadrant #4, we go in "reverse" order }
        FirstOne := TRUE;
        FOR I := NoOfSlices DOWNTO 1 DO BEGIN
            IF Quadrant(PieSpec[I].LabelLineAngle) = 4 THEN BEGIN
                IF NOT FirstOne THEN BEGIN
          { if the difference in vertical offset < MinVertDistance then
            make it equal to MinVertDistance
          }
                    ThisY := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
                    LastY := YVal(PieSpec[I + 1].LabelLineAngle, PieSpec[I + 1].LabelLineLength);
                    IF (ABS(ThisY - LastY) < MinVertDistance) THEN
                        PieSpec[I].LabelLineLength := NewY(PieSpec[I].LabelLineAngle, LastY + MinVertDistance);
                END
                ELSE
                    FirstOne := FALSE;
            END;
        END;
    END;

    {-------------------}

    FUNCTION TPrinter.CheckPointerVerticalDiffs(NoOfSlices     : BYTE;
                                                VAR PieSpec    : TPieArray;
                                                Radius,
                                                Rotation,
                                                MinVertDistance : INTEGER) : BOOLEAN;
        {---------------}

        FUNCTION YVal(InAngle, InLen : INTEGER) : INTEGER;
        BEGIN
            YVal := ROUND(SIN(InAngle * DegreesToRadians) * InLen);
        END;
    TYPE
        SepType        = RECORD
                             YVal           : INTEGER;
                             Quad           : BYTE;
                         END;
    VAR
        I,
        J              : BYTE;
        Sep            : ARRAY[1..10] OF SepType;

        TestHeight,
        CurMinHeight   : INTEGER;
    BEGIN
        { idea is, we calculate the vertical distance between each adjacent}
        { wedge, from a point 0.10" inside the circle on the line which    }
        { bisects the wedge                                                }
        FOR I := 1 TO 10 DO BEGIN
            Sep[I].YVal := 0;
            Sep[I].Quad := 1;
        END;

        FOR I := 1 TO NoOfSlices DO BEGIN
            WITH PieSpec[I] DO
                LabelLineAngle := ((StartAngle + Rotation) + (EndAngle + Rotation)) DIV 2;
        END;
        { 2. Set each pointerlength to the default }
        FOR I := 1 TO NoOfSlices DO BEGIN
            WITH PieSpec[I] DO
                { 8/31/93: This should be the radius + explosion - .1"  }
                LabelLineLength := Radius + ExplByAngle(EndAngle - StartAngle, Radius) - 60;
        END;

        FOR I := 1 TO NoOfSlices DO BEGIN
            Sep[I].Quad := Quadrant(PieSpec[I].LabelLineAngle);
            Sep[I].YVal := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
        END;

        { The trick is, we compare quadrants 4 and 1 as a continuum, and }
        { quadrants 3 and 2 as a continuum to look for unacceptable      }
        { vertical heights                                               }

        { actually, to be perfectly lazy, we only need to look for the   }
        { smallest difference between *any* two values in each set of    }
        { 2 quadrants                                                    }

        FOR I := 1 TO NoOfSlices DO BEGIN
            IF (Quadrant(PieSpec[I].LabelLineAngle) = 1) OR (Quadrant(PieSpec[I].LabelLineAngle) = 4) THEN
                Sep[I].Quad := 1
            ELSE
                Sep[I].Quad := 2;
            Sep[I].YVal := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
        END;

        CurMinHeight := 10000;

        FOR I := 1 TO NoOfSlices DO BEGIN
            FOR J := 1 TO NoOfSlices DO BEGIN
                IF (I <> J) AND (Sep[I].Quad = Sep[J].Quad) THEN BEGIN
                    TestHeight := ABS(Sep[I].YVal - Sep[J].YVal);
                    IF TestHeight < CurMinHeight THEN
                        CurMinHeight := TestHeight;
                END;
            END;
        END;

        CheckPointerVerticalDiffs := (CurMinHeight >= MinVertDistance);
    END;

    {-------------------}

    FUNCTION TPrinter.ButtOriented(NoOfSlices : BYTE; VAR PieSpec : TPieArray) : BOOLEAN;
    CONST
        ButtThreshold  = 10;
    VAR
        I,
        J,
        qA,
        qB             : BYTE;
        sA,
        SB             : INTEGER;
        ButtStatus     : BOOLEAN;
    BEGIN
        { if 2 adjacent slices are in Q1 and Q2 or Q3 and Q4 and if they are }
        { less than ButtThreshold degrees then return false                  }
        ButtStatus := FALSE;
        FOR I := 1 TO NoOfSlices DO BEGIN
            IF I < NoOfSlices THEN
                J := I + 1
            ELSE
                J := 1;
            qA := Quadrant(PieSpec[I].LabelLineAngle);
            qB := Quadrant(PieSpec[J].LabelLineAngle);
            sA := ABS(PieSpec[I].EndAngle - PieSpec[I].StartAngle);
            SB := ABS(PieSpec[J].EndAngle - PieSpec[J].StartAngle);
            IF ((qA = 1) AND (qB = 2)) OR
            ((qA = 2) AND (qB = 1)) OR
            ((qA = 3) AND (qB = 4)) OR
            ((qA = 4) AND (qB = 3)) THEN BEGIN
                IF (sA <= ButtThreshold) AND (SB <= ButtThreshold) THEN
                    ButtStatus := TRUE;
            END;
        END;
        ButtOriented := ButtStatus;
    END;

    {-------------------}

    PROCEDURE TPrinter.DrawPie(NoOfSlices     : BYTE;
                               PieSpec        : TPieArray;
                               XOrigin,
                               YOrigin,
                               Radius         : WORD;
                               Optimize,
                               DrawLabels,
                               DrawShadow     : BOOLEAN;
                               XShadow,
                               YShadow,
                               MinPointerLineLength,
                               MinVertDistance,
                               LabelLineStart : INTEGER;
                               BackgroundColor : BYTE;
                               TopCaption     : STRING;
                               TopFont        : FontTypeT;
                               TCColor        : TPrnColors;
                               BotCaption     : STRING;
                               BotFont        : FontTypeT;
                               BCColor        : TPrnColors;
                               XStretch,
                               YStretch       : WORD);

    VAR
        QisOK          : BOOLEAN; { Set by CP's routine when rotation is ok       }
        I              : BYTE;
        FillP          : REAL;
        XAsp,
        YAsp,
        Angle1,
        Angle2,
        LeaderLen      : WORD;
        A,
        B,
        AngDiff,
        Pushed,
        Rotation,
        Drv,
        Mode           : INTEGER;
    BEGIN
        Angle1 := 0;
        IF COP <> NIL THEN
            COP^.UpDate;

        IF MyOutMode = EPrnScreen THEN BEGIN
            SetFillStyle(SOLIDFill, BackgroundColor); { New style }
            Bar(0, 0, GetMaxX, GetMaxY);
        END;

        FOR I := 1 TO NoOfSlices DO BEGIN
            WITH PieSpec[I] DO BEGIN
                Angle2 := ((Percent * 360) DIV 100) + Angle1;
                StartAngle := Angle1;
                EndAngle := Angle2;
                Angle1 := Angle2;
            END;
        END;

        GetAspectRatio(XAsp, YAsp);

        XStretch := MaxWord(XStretch, 1);
        YStretch := MaxWord(YStretch, 1);

        SetAspectRatio(XAsp DIV XStretch, YAsp DIV YStretch);

        IF Optimize THEN BEGIN
            {Rotate till labels fit okay}
            Rotation := - 1;
            REPEAT
                IF COP <> NIL THEN
                    COP^.UpDate;
                INC(Rotation, 1);
                CalcPointers(NoOfSlices,
                             PieSpec,
                             MinPointerLineLength,
                             MinVertDistance,
                             Rotation); ;
                QisOK := CheckPointerVerticalDiffs(NoOfSlices,
                                                   PieSpec,
                                                   Radius,
                                                   Rotation,
                                                   MinVertDistance);
                IF QisOK THEN
                    QisOK := NOT ButtOriented(NoOfSlices, PieSpec);
            UNTIL QisOK OR (Rotation >= 360);
        END;


        IF DrawShadow THEN BEGIN
            {draw shadows in background}
            FOR I := 1 TO NoOfSlices DO BEGIN
                IF COP <> NIL THEN
                    COP^.UpDate;
                WITH PieSpec[I] DO BEGIN
                    SetColor(TranslateColor(tpcBLACK)); {edge color}
                    SetLineStyle(SolidLn, 0, 3);
                    SetFillStyle(SOLIDFill, TranslateColor(tpcBLACK));
                    A := PieSpec[I].StartAngle + Rotation;
                    B := PieSpec[I].EndAngle + Rotation;
                    AngDiff := B - A;
                    Pushed := ExplByAngle(B - A, Radius);
                    IF Percent <> 100 THEN
                        PieSlice(XShadow + XOrigin + XOffset(A, B, Pushed),
                                 YShadow + YOrigin - Yoffset(A, B, Pushed),
                                 A,
                                 B,
                                 Radius)
                    ELSE
                        FillEllipse(XShadow + XOrigin + XOffset(A, B, Pushed),
                                    YShadow + YOrigin - Yoffset(A, B, Pushed),
                                    Radius,
                                    Radius);
                END;
            END;

        END;

        {draw foreground pie slices (the actual data)}
        FOR I := 1 TO NoOfSlices DO BEGIN
            IF COP <> NIL THEN
                COP^.UpDate;
            WITH PieSpec[I] DO BEGIN
                SetColor(TranslateColor(tpcBLACK)); {edge color}
                SetLineStyle(SolidLn, 0, 0);
                SetFillStyle(Fill, TranslateColor(TPrnColors(Color)));

                A := PieSpec[I].StartAngle + Rotation;
                B := PieSpec[I].EndAngle + Rotation;
                AngDiff := B - A;
                Pushed := ExplByAngle(B - A, Radius);
                IF Percent <> 100 THEN
                    PieSlice(XOrigin + XOffset(A, B, Pushed),
                             YOrigin - Yoffset(A, B, Pushed),
                             A, B, Radius)
                ELSE
                    FillEllipse(XOrigin + XOffset(A, B, Pushed),
                                YOrigin - Yoffset(A, B, Pushed),
                                Radius,
                                Radius);
            END;
        END;

        IF TopCaption <> '' THEN BEGIN
            SetColor(TranslateColor(TCColor));
            SetTextStyle(TriplexFont, HorizDir, 1);
            {SetFont(TriplexFont, HorizDir, 7, 7, PtUnits);}
            SetFontSize(TopFont);
            SetTextJustify(CenterText, CenterText);
            OutTextXY(XOrigin, YOrigin - ROUND(Radius * 1.3), TopCaption)
        END;

        IF BotCaption <> '' THEN BEGIN
            SetColor(TranslateColor(BCColor));
            SetTextStyle(TriplexFont, HorizDir, 1);
            {SetFont(TriplexFont, HorizDir, 7, 7, PtUnits);}
            SetFontSize(BotFont);
            SetTextJustify(CenterText, CenterText);
            OutTextXY(XOrigin, YOrigin + ROUND(Radius * 1.3), BotCaption)
        END;

        IF DrawLabels THEN BEGIN
            {SetTextStyle(TriplexFont, HorizDir, 1);}
            SetFontSize(TopFont);
            {SetFont(TriplexFont, HorizDir, 7, 7, PtUnits);}

            {Do graphic labels for DJ}
            LeaderLen := GetMaxX DIV 20;

            SetColor(TranslateColor(tpcBLACK));
            SetFillStyle(SOLIDFill, TranslateColor(tpcBLACK));
            SetLineStyle(SolidLn, 0, 2);

            FOR I := 1 TO NoOfSlices DO BEGIN
                IF COP <> NIL THEN
                    COP^.UpDate;
                WITH PieSpec[I] DO BEGIN
                    A := PieSpec[I].StartAngle + Rotation;
                    B := PieSpec[I].EndAngle + Rotation;
                    CASE Quadrant(LabelLineAngle) OF
                        1,
                        4 :
                            BEGIN
                                MoveTo(XOrigin + XOffset(A, B, Pushed + LabelLineStart),
                                       YOrigin - Yoffset(A, B, Pushed + LabelLineStart));
                                LineRel(LeaderLen, 0);
                                SetTextJustify(LeftText, CenterText);
                                OutText(' ' + Tag);
                            END;
                        2,
                        3 :
                            BEGIN
                                MoveTo(XOrigin + XOffset(A, B, Pushed + LabelLineStart),
                                       YOrigin - Yoffset(A, B, Pushed + LabelLineStart));
                                LineRel(- LeaderLen, 0);
                                SetTextJustify(RightText, CenterText);
                                OutText(' ' + Tag);
                            END;
                    END;
                END;
            END;
        END;
        SetColor(TranslateColor(tpcBLACK));
        SetFillStyle(SOLIDFill, TranslateColor(tpcBLACK));
        SetAspectRatio(XAsp, YAsp);
    END;

    {--------------}

    {convert inches to dots, using current graphdrive device}
    {this assumes viewport=fullpage}
    PROCEDURE TPrinter.GDIn2XY(Inx, Iny       : REAL;
                               AutoMargin     : BOOLEAN;
                               VAR X, Y       : LONGINT);
    VAR
        XDPI,
        YDPI           : WORD;
    BEGIN
        {$IFDEF VirtualPascal}
        EXIT;
        {$ELSE}
        IF NOT GrafDriveInited THEN BEGIN
            X := 0;
            Y := 0;
            EXIT;
        END;
        XDPI := GetMaxX;
        YDPI := GetMaxY;
        GetDPI(XDPI, YDPI);
        IF AutoMargin THEN BEGIN
            CASE GetDeviceType OF
                ScreenDev : ;
                PrintDev :
                    BEGIN
                        Inx := Inx - P1P2[EPrnGraph].LEFT;
                        Iny := Iny - P1P2[EPrnGraph].TOP;
                    END;
                PlotDev :
                    Iny := Iny + P1P2[EPrnGraph].TOP;
            END;
        END;
        X := ROUND(XDPI * Inx);
        Y := ROUND(YDPI * Iny);
        {$ENDIF}
    END;

    {-----------------}

    {translate desired color into printer color}
    FUNCTION TPrinter.TranslateColor(DesiredColor : TPrnColors) : BYTE;
    BEGIN
        TranslateColor := BYTE(MyWheel[DesiredColor]);
    END;

    {-----------------}

    PROCEDURE TPrinter.PostPrnError(P : POINTER);
    VAR
        Strg           : STRING;
        I,
        J              : WORD;
        Flg            : BOOLEAN;
        MBP            : MessageBoxP;
    BEGIN
        IF ljPrn^.pLastError = 0 THEN
            EXIT;

        Strg := '';

        NEW(MBP, Init(' PRINTER ERROR! ',
                      ctOk,
                      ctNone,
                      ctNone,
                      1));
        IF MBP = NIL THEN
            EXIT;

        WITH MBP^ DO BEGIN
            IF ljPrn = NIL THEN
                Strg := 'NIL printer'
            ELSE BEGIN
                FOR I := 0 TO 7 DO BEGIN
                    Flg := (ljPrn^.pLastError AND (1 SHL I)) > 0;
                    CASE I OF
                        0 :
                            IF Flg THEN BEGIN
                                Strg := 'Timeout ';
                                AddLine('Timeout', ELEFT);
                            END;

                        1,
                        2 : ;
                        3 :
                            IF Flg THEN BEGIN
                                Strg := Strg + 'I/O Error ';
                                AddLine('I/O Error', ELEFT);
                            END;
                        4 :
                            IF NOT Flg THEN BEGIN
                                Strg := Strg + 'Off line ';
                                AddLine('Printer is off-line', ELEFT);
                            END;
                        5 :
                            IF Flg THEN BEGIN
                                Strg := Strg + 'Out of paper ';
                                AddLine('Printer is out of paper', ELEFT);
                            END;
                        6 : ;
                        7 :
                            IF Flg THEN BEGIN
                                Strg := Strg + 'Printer busy ';
                                AddLine('Printer is busy', ELEFT);
                            END;
                    END;

                END;
                DispErrorDeluxe('Printer error', Strg, TRUE, Iam);
            END;
            RingBell;
            Process;
        END;
        DISPOSE(MBP, Done);
    END;

    {-----------------}

    PROCEDURE TPrinter.SetGDRes(R : WORD);
    BEGIN
        GDRes := R;
    END;

    {-----------------}

    FUNCTION TPrinter.GetGDRes : WORD;
    BEGIN
        GetGDRes := GDRes;
    END;

    {-----------------}

    PROCEDURE TPrinter.SetPageNum(PG : WORD);
    BEGIN
        CurPageNum := PG;
    END;

    {-----------------}

    FUNCTION TPrinter.GetPageNum : WORD;
    BEGIN
        GetPageNum := CurPageNum;
    END;

    {-----------------}

    {set/clear allow print flag}
    {if printing is not allowed, then throw}
    {chars in bitbucket as they are printed}
    PROCEDURE TPrinter.SetAllowPrint(Allow : BOOLEAN);
    BEGIN
        AllowPrint := Allow;
    END;

    {-----------------}

    FUNCTION TPrinter.GetAllowPrint : BOOLEAN;
    BEGIN
        GetAllowPrint := AllowPrint;
    END;

    {-----------------}
    {if true, then not a good idea to mix text and graphics}
    {on same line (HPDJ printers)                          }
    FUNCTION TPrinter.IsFlakeyOnMixedTextGraph : BOOLEAN;
    BEGIN
        IsFlakeyOnMixedTextGraph := FlakeyMixedTextGraph;
    END;

    {-----------------}

    {draw high level chart}
    {$IFNDEF VirtualPascal}
    PROCEDURE TPrinter.DrawChart(Ch : ChartDef);
    VAR
        Erc            : INTEGER;
    BEGIN
        IF GrafDriveInited THEN BEGIN
            Erc := GBCHART(Ch);
            IF Erc <> 0 THEN
                DispErrorDeluxe('Chart Draw Error', GraphErrorMsg(Erc), TRUE, Iam);
        END;
    END;
    {$ENDIF}
    {-----------------}

    FUNCTION TPrinter.GetCurOrient : TPrnPlot;
    BEGIN
        GetCurOrient := PrnPlot;
    END;

    {-----------------}

    {status indicator used by grafdrive}
    FUNCTION GStat(Cur, Max : INTEGER) : WORD;
    VAR
        COP            : CylonP;
    BEGIN
        GStat := 0;
        COP := PPrt^.GetCOP;
        IF COP = NIL THEN
            EXIT;
        IF NOT COP^.UpDate THEN
            GStat := 1;
    END;

    {--------------}

    FUNCTION TPrinter.GetCurRow : REAL;
    BEGIN
        GetCurRow := CurRow;
    END;

    {--------------}

    {return printer device name}
    FUNCTION TPrinter.GetDevName : STRING;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Enter HPGL/2 graphics mode }
    PROCEDURE TPrinter.GoHPGL;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Return to PCL command mode }
    PROCEDURE TPrinter.GoPCL;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Reset the printer}
    PROCEDURE TPrinter.ResetPrn;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Reset the left and right hardware margins to their default }
    {Note: We don't use hardware margins....}
    FUNCTION TPrinter.ClearHorizontalMargins : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Update the cursor position...X and Y specified in inches }
    FUNCTION TPrinter.PrnGotoXY(CONST X, Y : REAL) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}
    {-Update the horizontal cursor position }
    FUNCTION TPrinter.PrnGotoX(CONST X : REAL) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}
    {-Update the vertical cursor position }
    FUNCTION TPrinter.PrnGotoY(CONST Y : REAL) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Advance the Y cursor by Delta inches }
    FUNCTION TPrinter.PrnAdvanceY(CONST Delta : REAL) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    FUNCTION TPrinter.PrnAdvanceX(CONST Delta : REAL) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {set status of downloaded font}
    PROCEDURE TPrinter.MakeFontTemporary;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {set status of downloaded font}
    PROCEDURE TPrinter.MakeFontPermanent;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Set the character horizontal spacing}
    PROCEDURE TPrinter.SetHMI(CONST Inches : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}


    {-Set the vertical motion index }
    PROCEDURE TPrinter.SetVMI(CONST Inches : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Draw a horizontal line at X,Y that is Width inches long }
    FUNCTION TPrinter.HLine(CONST X, Y, Width : REAL) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Draw a thick horizontal line at X,Y that is Width inches long }
    PROCEDURE TPrinter.ThickHLine(CONST X, Y, Width : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Draw a vertical line at X,Y that is Height inches long }
    PROCEDURE TPrinter.VLine(CONST X, Y, Height : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Draw a thick vertical line at X,Y that is Height inches long }
    PROCEDURE TPrinter.ThickVLine(CONST X, Y, Height : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Draw a box, filling it if necessary }
    PROCEDURE TPrinter.Box(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Draw a thick box, filling it if necessary }
    PROCEDURE TPrinter.BoxThick(CONST Width, Height : REAL; CONST PctGray : BYTE);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Draw a box, filling it if desired, with a shadow on it }
    PROCEDURE TPrinter.BoxShadow(CONST X, Y, Width, Height : REAL;
                                 CONST PctGray  : BYTE;
                                 Border         : BOOLEAN);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Draw a double lined box }
    PROCEDURE TPrinter.DoubleBox(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Print a pie wedge }
    {Dunsel!  Use DGPIE instead}
    PROCEDURE TPrinter.PieWedge(CONST X, Y, Radius : WORD;
                                CONST StartAngle, EndAngle, Fill : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Set the HPGL/2 transparency mode on or off }
    PROCEDURE TPrinter.GraphicsTransparency(CONST On : BOOLEAN);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Set the width of the HPGL/2 pen }
    PROCEDURE TPrinter.hpglPW(CONST Width : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {draw HPGL box at specified location}
    PROCEDURE TPrinter.hpglBox(Lx, Ly, BoxW, Boxh : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {draw a line using HPGL}
    PROCEDURE TPrinter.hpglLine(L1x, L1y, L2x, L2y, Width : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {draw a box using HPGL, filled with black}
    PROCEDURE TPrinter.hpglBlackBox(Lx, Ly, BoxW, Boxh : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {draw an hpgl pie wedge}
    PROCEDURE TPrinter.hpglWedge(XOrg, YOrg, Radius : WORD; StartAngle, EndAngle, Fill : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {draw an hpgl leader line}
    PROCEDURE TPrinter.hpglPointer(OrgX, OrgY, Angle, BeginAt, PLen : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {draw HPGL text label at coordinates}
    PROCEDURE TPrinter.hpglLabel(X, Y : REAL; S : STRING);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {assign font id to newly downloaded font}
    PROCEDURE TPrinter.AssignFontID(IDNo : FontTypeT);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {pick a printer paper bin}
    PROCEDURE TPrinter.SelectTray(T : TLetterHeadTray);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {initialize the Letterhead and Blank paper trays }
    {Infer blank tray if not known                   }
    PROCEDURE TPrinter.SetTrays(Ltr, Blnk : TLetterHeadTray);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {select a paper type - letterhead or blank}
    PROCEDURE TPrinter.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {select a text color}
    PROCEDURE TPrinter.SelectTextColor(C : TPrnColors);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {force printer back into black&white text mode}
    PROCEDURE TPrinter.SelectTextMonoChrome;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    PROCEDURE TPrinter.DrawRasterBox(X,
                                     Y              : REAL;
                                     Border,
                                     DropShadow     : BOOLEAN;
                                     PctGray,
                                     Hyt,
                                     Width          : REAL);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Specify the grayscale % for grayscale fills }
    FUNCTION TPrinter.ljPatternShade(CONST Percent : BYTE) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Specify the parameters of the print model rectangle }
    FUNCTION TPrinter.ljRectDimensions(CONST WidthInDP, HeightInDP : REAL) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {-Fill the previously specified rectangle }
    FUNCTION TPrinter.ljFillRect(CONST Fill : RectFillType) : BOOLEAN;
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}

    {this is mostly for DotMatrix printers with multipart forms}
    PROCEDURE TPrinter.SetFormLen(CONST L : LONGINT);
    BEGIN
        KAbstract(Iam);
    END;

    {--------------}


    FUNCTION TPrinter.PrinterName : STRING;
    BEGIN
        PrinterName := PrnModels[PType];
    END;

    {--------------}

    FUNCTION TPrinter.GetCPRow : REAL;
    BEGIN
        GetCPRow := CurRow;
    END;

    {--------------}

    FUNCTION TPrinter.GetCPCol : REAL;
    BEGIN
        GetCPCol := CurColumn;
    END;

    {--------------}


END.

    {-----------------}
    {-----------------}

