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
!!! Error - This unit is obsolete - Use DGPRINT
UNIT LJ;

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

    PLaserJet      = ^TLaserJet;
    TLaserJet      = OBJECT(ROOT)
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

                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);

                             {call this instead, for descendent object init}
                         FUNCTION InitPrim(PrnInfo        : TPrnCfg;
                                           VAR MyCOP      : CylonP;
                                           Mode           : TxtGraf) : BOOLEAN;
                             {load character translation table for foreign langs}
                         FUNCTION LoadCharTable(Name : PathStr) : BOOLEAN;

                         DESTRUCTOR Done; VIRTUAL;

                             {get last printer error}
                         FUNCTION PrnError : WORD;

                             {return laserjet name}
                         FUNCTION GetDevName : STRING;

                             {change page label string}
                         PROCEDURE SetPageLabel(Strg : STRING);

                             {get the current page label string}
                         FUNCTION GetPageLabel : STRING;

                             {return LJ I/O port or type (file, nul,...)}
                         FUNCTION GetPort : PrnType;

                             {return LJ I/O port name}
                         FUNCTION GetPortName : STRING;

                             {-Enter HPGL/2 graphics mode }
                         PROCEDURE GoHPGL;

                             {-Return to PCL command mode }
                         PROCEDURE GoPCL;

                             {-Reset the printer}
                         PROCEDURE ResetPrn; VIRTUAL;

                             {-Send a string to the printer }
                         FUNCTION PutStr(CONST St : STRING) : BOOLEAN;

                             {-Send a righ justified string to the printer }
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
                         FUNCTION ClearHorizontalMargins : BOOLEAN;

                             {-Update the cursor position...X and Y specified in inches }
                         FUNCTION PrnGotoXY(CONST X, Y : REAL) : BOOLEAN; VIRTUAL;

                             {-Update the horizontal cursor position }
                         FUNCTION PrnGotoX(CONST X : REAL) : BOOLEAN; VIRTUAL;

                             {-Update the vertical cursor position }
                         FUNCTION PrnGotoY(CONST Y : REAL) : BOOLEAN; VIRTUAL;

                             {-Advance the X cursor by Delta inches }
                         FUNCTION PrnAdvanceX(CONST Delta : REAL) : BOOLEAN;

                             {-Advance the Y cursor by Delta inches }
                         FUNCTION PrnAdvanceY(CONST Delta : REAL) : BOOLEAN;

                             {-Eject the current page }
                         FUNCTION FormFeed : BOOLEAN;

                             {-advance to the next line using the current font for delta}
                         FUNCTION LineFeed(VAR NewPos : REAL) : BOOLEAN;

                             {set status of downloaded font}
                         PROCEDURE MakeFontTemporary;

                             {set status of downloaded font}
                         PROCEDURE MakeFontPermanent;

                             {send font to printer}
                         FUNCTION DownloadFont(IDNo           : FontTypeT;
                                               FontFileName   : STRING;
                                               PointSize      : REAL;
                                               Permanent      : BOOLEAN) : BOOLEAN;

                             {-Add a font metric to this object }
                         FUNCTION AddFont(CONST ID       : FontTypeT;
                                          CONST PointSize : REAL;
                                          CONST WidthTable : PathStr;
                                          CONST SelectStr : STRING) : BOOLEAN;

                             {-Find a font with a matching ID }
                         FUNCTION FindFontByID(CONST ID : FontTypeT) : PFont;

                             {-Remove a font from the printer }
                         PROCEDURE RemoveFont(CONST ID : FontTypeT);

                             {-Find a font and make it active }
                         PROCEDURE SelectFont(CONST ID : FontTypeT);

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
                         PROCEDURE SetHMI(CONST Inches : REAL);

                             {-Set the vertical motion index }
                         PROCEDURE SetVMI(CONST Inches : REAL);

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

                             {-Draw a horizontal line at X,Y that is Width inches long }
                         FUNCTION HLine(CONST X, Y, Width : REAL) : BOOLEAN;

                             {-Draw a thick horizontal line at X,Y that is Width inches long }
                         PROCEDURE ThickHLine(CONST X, Y, Width : REAL);

                             {-Draw a vertical line at X,Y that is Height inches long }
                         PROCEDURE VLine(CONST X, Y, Height : REAL);

                             {-Draw a thick vertical line at X,Y that is Height inches long }
                         PROCEDURE ThickVLine(CONST X, Y, Height : REAL);

                             {-Draw a box, filling it if necessary }
                         PROCEDURE Box(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN);

                             {-Draw a thick box, filling it if necessary }
                         PROCEDURE BoxThick(CONST Width, Height : REAL; CONST PctGray : BYTE);

                             {-Draw a box, filling it if desired, with a shadow on it }
                         PROCEDURE BoxShadow(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN);

                             {-Draw a double lined box }
                         PROCEDURE DoubleBox(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE);

                             {-Print a tag and data between Left and Right with a dot leader }
                         PROCEDURE TagAndDataWithLeader(CONST Tag, Data : STRING; CONST LEFT, RIGHT : REAL);

                             {-Center a line of data between to points, returns X coordinate }
                         FUNCTION CenterData(CONST Data : STRING; CONST LEFT, RIGHT : REAL) : REAL;

                             {-Output a block of text, word wrapped to fit margins}
                             {funky paragraph wrapper for pchar string buffers.  Dont use!}
                             {Use the report object (DGRPT) instead!}
                         PROCEDURE OutputTextWrapped(CONST Buf      : PCHAR;
                                                     CONST LEFT, RIGHT : REAL;
                                                     CurPage        : WORD;
                                                     Just           : JustT);

                             {-Print a pie wedge }
                             {Dunsel!  Use DGPIE instead}
                         PROCEDURE PieWedge(CONST X, Y, Radius : WORD; CONST StartAngle, EndAngle, Fill : REAL);

                             {abstract method for descendent objects only!}
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
                         PROCEDURE GraphicsTransparency(CONST On : BOOLEAN);

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
                         PROCEDURE hpglPW(CONST Width : REAL);

                             {*****************************************}
                             {Note: Most of this HPGL stuff is obsolete}
                             {Use GrafDrive/BGI calls instead, because they}
                             {are printer independent!}
                             {*****************************************}

                             {draw HPGL text label at coordinates}
                         PROCEDURE hpglLabel(X, Y : REAL; S : STRING);

                             {draw HPGL box at specified location}
                         PROCEDURE hpglBox(Lx, Ly, BoxW, Boxh : REAL);

                             {draw a line using HPGL}
                         PROCEDURE hpglLine(L1x, L1y, L2x, L2y, Width : REAL);

                             {draw a box using HPGL, filled with black}
                         PROCEDURE hpglBlackBox(Lx, Ly, BoxW, Boxh : REAL);

                             {draw an hpgl pie wedge}
                         PROCEDURE hpglWedge(XOrg, YOrg, Radius : WORD; StartAngle, EndAngle, Fill : REAL);

                             {draw an hpgl leader line}
                         PROCEDURE hpglPointer(OrgX, OrgY, Angle, BeginAt, PLen : REAL);

                             {right justify a string at tabstop}
                         PROCEDURE PrintAtRightTabRow(S : STRING; Row, TabStop : REAL);

                             {return X value to center S between left/right margins}
                         FUNCTION CenterStringX(S : STRING) : REAL;

                             {assign font id to newly downloaded font}
                         PROCEDURE AssignFontID(IDNo : FontTypeT);

                             {send a PCX file to the printer, using specified}
                             {size.  Stretch or squash the picture to fit}
                             {$IFNDEF VirtualPascal}
                         PROCEDURE PutPCX(FName          : STRING;
                                          X1, Y1,
                                          X2, Y2         : REAL;
                                          Density        : INTEGER);

                             {$ENDIF}
                             {draw a shaded box using raster or high level commands}
                         PROCEDURE DrawRasterBox(X,
                                                 Y              : REAL;
                                                 Border,
                                                 DropShadow     : BOOLEAN;
                                                 PctGray,
                                                 Hyt,
                                                 Width          : REAL);
                             {draw a shaded box and put some text on it}
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
                                                     Width          : REAL);
                             {draw a shaded box and put up to 3 independently}
                             {justified strings in the box}
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
                         PROCEDURE SelectTray(T : TLetterHeadTray);

                             {initialize the Letterhead and Blank paper trays }
                             {Infer blank tray if not known                   }
                         PROCEDURE SetTrays(Ltr, Blnk : TLetterHeadTray);

                             {select a paper type - letterhead or blank}
                         PROCEDURE SelectTrayDeluxe(Tray : TPaperStyle);

                             {translate desired color into printer color}
                         FUNCTION TranslateColor(DesiredColor : TPrnColors) : BYTE;

                             {select a text color}
                         PROCEDURE SelectTextColor(C : TPrnColors);
                             {force printer back into black&white text mode}
                         PROCEDURE SelectTextMonoChrome;

                             {set grafdrive resolution}
                         PROCEDURE SetGDRes(R : WORD);

                             {get current grafdrive resolution}
                         FUNCTION GetGDRes : WORD;

                             {set current page number}
                         PROCEDURE SetPageNum(PG : WORD);

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
                     PRIVATE

                         PType          : PrnModelT;
                         ljPrn          : BasePrinterPtr;

                             {-Specify the grayscale % for grayscale fills }
                         FUNCTION ljPatternShade(CONST Percent : BYTE) : BOOLEAN;

                             {-Specify the parameters of the print model rectangle }
                         FUNCTION ljRectDimensions(CONST WidthInDP, HeightInDP : REAL) : BOOLEAN;

                             {-Fill the previously specified rectangle }
                         FUNCTION ljFillRect(CONST Fill : RectFillType) : BOOLEAN;

                             {return halftone bitmap pattern}
                         FUNCTION HalfTone(Level : BYTE; X, Y : WORD) : BYTE;

                             {runlength encoding compression of line }
                         PROCEDURE RLECompress(VAR Line; Len : WORD);

                             {TIFF compression of line}
                         PROCEDURE TIFFCompress(VAR V; Len : WORD);

                             {display message box showing current printer problems}
                         PROCEDURE PostPrnError(P : POINTER);

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
    PPrt           : PLaserJet;

IMPLEMENTATION
USES
    CRT,
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

    FUNCTION TLaserJet.HalfTone(Level : BYTE; X, Y : WORD) : BYTE;
    BEGIN
        HalfTone := Mask[Level MOD 9, Y MOD 4];
    END;

    {-----------------}

    PROCEDURE TLaserJet.RLECompress(VAR Line; Len : WORD);
    VAR
        RunCt,
        I,
        J              : WORD;
        LAST,
        B              : BYTE;
        Strg           : STRING;
        RasterLine     : ARRAY[1..65520] OF BYTE ABSOLUTE Line;
    BEGIN
        I := 1;
        RunCt := 0;
        LAST := RasterLine[1];
        FOR I := 2 TO Len DO BEGIN
            B := RasterLine[I];
            IF B = LAST THEN
                INC(RunCt)
            ELSE BEGIN
                PrnPutBlock(RasterLine[I], Len);
                RunCt := 0;
            END;
        END;
    END;

    {-----------------}

    PROCEDURE TLaserJet.TIFFCompress(VAR V; Len : WORD);
    VAR
        RunCt,
        I,
        J              : WORD;
        LAST,
        B              : BYTE;
        Strg           : STRING;
    BEGIN
        (*
        I := 1;
        RunCt := 0;
        Last := V[1];
        FOR I := 1 TO Len DO BEGIN
            B := V[I];
            IF B = Last THEN
                INC(RunCt)
            ELSE BEGIN
                PrnPutBlock(V[ BlockSize : WORD);
            END;
        END;
        *)
    END;

    {-----------------}
    {$IFNDEF VirtualPascal}
    PROCEDURE TLaserJet.PutPCX(FName : STRING; X1, Y1, X2, Y2 : REAL; Density : INTEGER);
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

    PROCEDURE TLaserJet.DrawRasterBox(X,
                                      Y              : REAL;
                                      Border,
                                      DropShadow     : BOOLEAN;
                                      PctGray,
                                      Hyt,
                                      Width          : REAL);
    VAR
        RightEdge,
        H,
        W,
        I,
        J              : WORD;
        LineBuf        : ARRAY[1..320] OF BYTE;
        Tb,
        GrayLevel      : BYTE;
        ShadowSize     : REAL;
        ShadowPixels   : WORD;
    BEGIN
        IF ljCanBox THEN BEGIN
            Box(X, Y, Width, Hyt, ROUND(PctGray), Border);
            EXIT;
        END;

        ShadowSize := 0.125;

        ShadowPixels := ROUND(ShadowSize * 300);
        GrayLevel := ROUND((PctGray / 11.1111) + 0.5);
        PrnGotoXY(X, Y);
        W := ROUND(Width * 300) DIV 8;
        H := ROUND(Hyt * 300);
        RightEdge := W;

        IF DropShadow THEN
            INC(W, (ShadowPixels DIV 8));

        SelectTextMonoChrome;

        PutStr(#27'*t300R' +
               #27'*rbC' +
               #27'*rb0M' +
               #27'*p' + Long2Str(ROUND((X - P1P2[EPrnTxt].LEFT) * 300)) + 'X' +
               #27'*p' + Long2Str(ROUND((Y - P1P2[EPrnTxt].TOP) * 300)) + 'Y' +
               #27'*r1A' +
               #27'*r' + Long2Str(W * 8) + 'S');

        FOR J := 1 TO H DO BEGIN
            PutStr(#27'*b' + Long2Str(W) + 'W');
            FILLCHAR(LineBuf, W, #0);
            IF Border THEN BEGIN
                IF (J < 5) OR (J > (H - 5)) THEN
                    {draw top or bottom edge line}
                    FILLCHAR(LineBuf, RightEdge, #255)
                ELSE BEGIN
                    {fix left and right edges so that the fill looks ok}
                    LineBuf[1] := $F0 OR (HalfTone(GrayLevel, 1, J) AND $F);
                    LineBuf[RightEdge] := $0F OR (HalfTone(GrayLevel, RightEdge, J) AND $F0);

                    {finish the fill in the center part of the box}
                    FOR I := 2 TO RightEdge - 1 DO
                        LineBuf[I] := HalfTone(GrayLevel, I, J);
                END;
            END
            ELSE
                {no border so just do the fill, edge to edge}
                FOR I := 1 TO RightEdge DO
                    LineBuf[I] := HalfTone(GrayLevel, I, J);
            IF DropShadow AND (J > ShadowPixels) THEN
                {fill in right side darker drop shadow}
                FOR I := RightEdge + 1 TO W DO
                    LineBuf[I] := HalfTone(GrayLevel + 2, I, J);
            PrnPutBlock(LineBuf, W);

        END;
        {we are one raster line below the bottom edge now}
        IF DropShadow THEN BEGIN
            {clean out the buffer}
            FILLCHAR(LineBuf, 10, #0);
            {make the bottom part of the drop shadow, offset by 1/4" to right}
            FOR J := 1 TO ShadowPixels DO BEGIN
                FOR I := 9 TO W DO
                    LineBuf[I] := HalfTone(GrayLevel + 2, I, J + H);
                {draw 1/4" high dropshadow}
                PutStr(#27'*b' + Long2Str(W) + 'W');
                PrnPutBlock(LineBuf, W);
            END;
        END;

        PutStr(#27'*rbC');
        PrnGotoXY(X, Y);          {ZZZZ}
    END;

    {-----------------}

    PROCEDURE TLaserJet.DrawShadedTextBox(X,
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

    PROCEDURE TLaserJet.DrawShadedTextBoxDeluxe(X,
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

    CONSTRUCTOR TLaserJet.Init(PrnInfo        : TPrnCfg;
                               VAR MyCOP      : CylonP;
                               Mode           : TxtGraf);
    BEGIN
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

    FUNCTION TLaserJet.InitPrim(PrnInfo        : TPrnCfg;
                                VAR MyCOP      : CylonP;
                                Mode           : TxtGraf) : BOOLEAN;
    VAR
        Strg           : STRING;
        I              : CHAR;
        PError,
        MaxColors      : WORD;
        TrueBlack,
        T              : TPrnColors;
        Tpt            : TP1P2Array;
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

        SetTrays(PrnInfo.TrayLtr, TLHUnknown);

        IF NOT ljFonts.Init THEN
            EXIT;

        ljPrn := NIL;
        MyPort := PrnInfo.PPort;
        PType := PrnInfo.PType;
        MyOutMode := Mode;

        IF Mode <> EPrnScreen THEN BEGIN

            GETDIR(0, Strg);
            IF NOT AddFont(fLinePrint, 10,
                           MyFontPath + 'LPR0000S.CWD', #27'(10U'#27'(s0p12.0h0s0b4099T') THEN
                EXIT;

            IF NOT AddFont(fSmall, 8,
                           MyFontPath + 'TRR0000S.CWD', #27'(8U'#27'(s1P'#27'(s8.0V'#27'(s0S'#27'(s0B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fMain, 12,
                           MyFontPath + 'TRR0000S.CWD', #27'(8U'#27'(s1P'#27'(s12.0V'#27'(s0S'#27'(s0B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fItalic, 12,
                           MyFontPath + 'TRI0000S.CWD', #27'(8U'#27'(s1P'#27'(s12.0V'#27'(s1S'#27'(s0B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fBold, 12,
                           MyFontPath + 'TRB0000S.CWD', #27'(8U'#27'(s1P'#27'(s12.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fBoldItalic, 12,
                           MyFontPath + 'TRB0000S.CWD', #27'(8U'#27'(s1p12.0v1s3b4101T') THEN
                EXIT;

            IF NOT AddFont(fTable, 10,
                           MyFontPath + 'TRR0000S.CWD', #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s0B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fHuge, 16,
                           MyFontPath + 'TRB1600S.CWD',
                           #27'(8U'#27'(s1P'#27'(s16.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fHugeItalic, 16,
                           MyFontPath + 'TRB1600S.CWD',
                           #27'(8U'#27'(s1P'#27'(s16.0V'#27'(s1S'#27'(s3B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fMainMedium, 10,
                           MyFontPath + 'TRR0000S.CWD', #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s0B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fItalicMedium, 10,
                           MyFontPath + 'TRI0000S.CWD',
                           #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s1S'#27'(s0B'#27'(s4101T') THEN
                EXIT;

            IF NOT AddFont(fBoldMedium, 10,
                           MyFontPath + 'TRB0000S.CWD', #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                EXIT;


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

            ljInitStr := StringToHeap(#27'E');
            ljULOn := StringToHeap(#27'&d0D');
            ljULOff := StringToHeap(#27'&d@');
            ljBoldOn := StringToHeap(#27'(s3B');
            ljBoldOff := StringToHeap(#27'(s0B');
            ljItalOn := StringToHeap(#27'(s1S');
            ljItalOff := StringToHeap(#27'(s0S');
            ljNewPage := StringToHeap(^L);

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
        CASE PType OF
            Screen :
                BEGIN
                    P1P2[EPrnTxt].TOP := 0.5;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_LJ';
                    P1P2[EPrnGraph].Driver := '_LJ';
                    P1P2[EPrnScreen].Driver := 'BGI256';
                END;
            NONE,
            DL6400,
            HPLJ2 :
                BEGIN
                    TrueBlack := tpcWHITE;
                    MaxColors := 2;
                    P1P2[EPrnTxt].TOP := 0.5;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_LJ';
                    P1P2[EPrnGraph].Driver := '_LJ';
                    ljCanBox := TRUE;
                    IF Mode <> EPrnScreen THEN
                        IF NOT AddFont(fFootnote,
                                       10,
                                       MyFontPath + 'TRR0000S.CWD',
                                       #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                            EXIT;
                END;
            HPLJ3 :
                BEGIN
                    TrueBlack := tpcWHITE;
                    P1P2[EPrnTxt].TOP := 0.5;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_LJ3R';
                    P1P2[EPrnGraph].Driver := '_HGL2';
                    ljCanBox := TRUE;
                    PrnPlot := EPlotOrient;

                    IF Mode <> EPrnScreen THEN
                        IF NOT AddFont(fFootnote,
                                       10,
                                       MyFontPath + 'TRR0000S.CWD',
                                       #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                            EXIT;
                END;
            HPLJ4 :
                BEGIN
                    TrueBlack := tpcWHITE;
                    P1P2[EPrnTxt].TOP := 0.5;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    ljCanBox := TRUE;
                    ljCanHpgl := TRUE;
                    P1P2[EPrnTxt].Driver := '_LJ4';
                    P1P2[EPrnGraph].Driver := '_HGL2';
                    PrnPlot := EPlotOrient;

                    IF Mode <> EPrnScreen THEN
                        IF NOT AddFont(fFootnote,
                                       10,
                                       MyFontPath + 'TRR0000S.CWD',
                                       #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                            EXIT;
                END;
            HPLJ4MP :
                BEGIN
                    TrueBlack := tpcWHITE;
                    P1P2[EPrnTxt].TOP := 0.5;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    ljCanBox := TRUE;
                    ljCanHpgl := TRUE;
                    P1P2[EPrnTxt].Driver := '_LJ4';
                    P1P2[EPrnGraph].Driver := '_HGL2';
                    PrnPlot := EPlotOrient;

                    IF Mode <> EPrnScreen THEN
                        IF NOT AddFont(fFootnote,
                                       10,
                                       MyFontPath + 'TRR0000S.CWD',
                                       #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
                            EXIT;
                END;
            HPDJ :
                BEGIN
                    P1P2[EPrnTxt].TOP := 0.6;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_DJ';
                    P1P2[EPrnGraph].Driver := '_DJ';
                    FlakeyMixedTextGraph := TRUE;
                    IF Mode <> EPrnScreen THEN
                        IF NOT DownloadFont(fFootnote,
                                            MyFontPath + 'TIR__10H.SFP',
                                            10,
                                            TRUE) THEN

                            EXIT;
                END;
            HPDJ1200 :
                BEGIN
                    TrueBlack := tpcDKGRAY;
                    ljIsColor := TRUE;
                    P1P2[EPrnTxt].TOP := 0.6;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_DJC';
                    P1P2[EPrnGraph].Driver := '_DJC';
                    FlakeyMixedTextGraph := TRUE;

                    IF Mode <> EPrnScreen THEN
                        IF NOT DownloadFont(fFootnote,
                                            MyFontPath + 'TIR__10H.SFP',
                                            10,
                                            TRUE) THEN
                            EXIT;

                END;
            HP1600C :
                BEGIN
                    {FlakeyMixedTextGraph := TRUE;}
                    TrueBlack := tpcWHITE;
                    ljIsColor := TRUE;
                    P1P2[EPrnTxt].TOP := 0.6;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_DJC';
                    P1P2[EPrnGraph].Driver := '_HGL2';
                    PrnPlot := EPlotOrient;
                    PutStr(#27'%-12345X');
                    PutStr('@PJL USTATUSOFF'#13#10);
                    PutStr('@PJL DEFAULT TIMEOUT = 60'#13#10);
                    PutStr('@PJL DEFAULT LANGUAGE = PCL'#13#10);
                    PutStr('@PJL RESET'#13#10);
                    PutStr('@PJL ENTER LANGUAGE = PCL'#13#10);
                    PutStr(#27'%-12345X'#13#10);
                    InitJob;
                    IF Mode <> EPrnScreen THEN
                        IF NOT DownloadFont(fFootnote,
                                            MyFontPath + 'TIR__10H.SFP',
                                            10,
                                            TRUE) THEN
                            EXIT;
                END;
            HPDJ5xxC :
                BEGIN
                    TrueBlack := tpcWHITE;
                    {shut off ^%$@&! color on this piece of shit}
                    ljIsColor := FALSE;
                    P1P2[EPrnTxt].TOP := 0.6;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_DJC';
                    P1P2[EPrnGraph].Driver := '_DJC';
                    FlakeyMixedTextGraph := TRUE;

                    IF Mode <> EPrnScreen THEN
                        IF NOT DownloadFont(fFootnote,
                                            MyFontPath + 'TIR__10H.SFP',
                                            10,
                                            TRUE) THEN
                            EXIT;
                END;
            HPDJC :
                BEGIN
                    TrueBlack := tpcWHITE;
                    ljIsColor := TRUE;
                    P1P2[EPrnTxt].TOP := 0.6;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_DJC';
                    P1P2[EPrnGraph].Driver := '_DJC';
                    FlakeyMixedTextGraph := TRUE;

                    IF Mode <> EPrnScreen THEN
                        IF NOT DownloadFont(fFootnote,
                                            MyFontPath + 'TIR__10H.SFP',
                                            10,
                                            TRUE) THEN
                            EXIT;
                END;
            HP855C :
                BEGIN
                    TrueBlack := tpcWHITE;
                    ljIsColor := TRUE;
                    P1P2[EPrnTxt].TOP := 0.5;
                    P1P2[EPrnTxt].Bot := 10.5;
                    P1P2[EPrnTxt].LEFT := 0.25;
                    P1P2[EPrnTxt].RIGHT := 8.25;
                    P1P2[EPrnTxt].Driver := '_LJ4';
                    P1P2[EPrnGraph].Driver := '_DJC';

                    IF Mode <> EPrnScreen THEN
                        IF NOT DownloadFont(fFootnote,
                                            MyFontPath + 'TIR__10H.SFP',
                                            10,
                                            TRUE) THEN
                            EXIT;
                END;
        END;

        {$IFNDEF VirtualPascal}
        MyPrinter := P1P2[Mode].Driver;
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
        InitPrim := TRUE;
    END;

    {-----------------}

    PROCEDURE TLaserJet.SetPageLabel(Strg : STRING);
    BEGIN
        PageLabel := Strg;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetPageLabel : STRING;
    BEGIN
        GetPageLabel := PageLabel;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetPortName : STRING;
    BEGIN
        GetPortName := PrnNames[MyPort];
    END;

    {-----------------}

    FUNCTION TLaserJet.GetPort : PrnType;
    BEGIN
        GetPort := MyPort;
    END;

    {-----------------}

    PROCEDURE TLaserJet.SetLeftMargin(M : REAL);
    BEGIN
        CurLeftMargin := M;
        CurColumn := M;
    END;

    {-----------------}

    PROCEDURE TLaserJet.SetRightMargin(M : REAL);
    BEGIN
        CurRightMargin := M;
    END;

    {-----------------}

    PROCEDURE TLaserJet.SetTopMargin(M : REAL);
    BEGIN
        CurTopMargin := M;
        CurRow := M;
    END;

    {-----------------}

    PROCEDURE TLaserJet.SetBottomMargin(M : REAL);
    BEGIN
        CurBottomMargin := M;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetLeftMargin : REAL;
    BEGIN
        GetLeftMargin := CurLeftMargin;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetRightMargin : REAL;
    BEGIN
        GetRightMargin := CurRightMargin;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetTopMargin : REAL;
    BEGIN
        GetTopMargin := CurTopMargin;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetBottomMargin : REAL;
    BEGIN
        GetBottomMargin := CurBottomMargin;
    END;

    {-----------------}

    PROCEDURE TLaserJet.hpglLabel(X, Y : REAL; S : STRING);
    BEGIN
        PutStr('SD1,21,2,1,4,18,5,0,6,0,7,52;');
        PutStr('DT~,1;');
        PutStr('PA' + Real2Str(X * 1016.0, 12, 4) + ',' + Real2Str(Y * 1016.0, 12, 4) + ';');
        PutStr('SS;');
        PutStr('LB' + S + '~');
    END;

    {-----------------}

    PROCEDURE TLaserJet.hpglBox(Lx, Ly, BoxW, Boxh : REAL);
    BEGIN
        PutStr('PA');
        PutStr(Real2Str(Lx * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(Ly * 1016.0, 12, 4));
        PutStr(';');
        PutStr('EA');
        PutStr(Real2Str((Lx + BoxW) * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str((Ly + Boxh) * 1016.0, 12, 4));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE TLaserJet.hpglLine(L1x, L1y, L2x, L2y, Width : REAL);
    BEGIN
        hpglPW(Width);
        PutStr('PU;PA');
        PutStr(Real2Str(L1x * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(L1y * 1016.0, 12, 4));
        PutStr('PD;PA');
        PutStr(Real2Str(L2x * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(L2y * 1016.0, 12, 4));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE TLaserJet.hpglBlackBox(Lx, Ly, BoxW, Boxh : REAL);
    BEGIN
        PutStr('PA');
        PutStr(Real2Str(Lx * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(Ly * 1016.0, 12, 4));
        PutStr(';');
        PutStr('FT1;');
        PutStr('RA');
        PutStr(Real2Str((Lx + BoxW) * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str((Ly + Boxh) * 1016.0, 12, 4));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE TLaserJet.hpglWedge(XOrg, YOrg, Radius : WORD; StartAngle, EndAngle, Fill : REAL);
    VAR
        Rx             : REAL;
        RY             : REAL;
        RRadius        : REAL;
    BEGIN
        {Fudges to work with GPU small-page origins}
        XOrg := XOrg + 600;
        {
        yorg := yorg + 460;
        }

        {Conversions}
        Rx := (XOrg / 300.0) + 0.75;
        RY := 9.30 - (YOrg / 300.0);
        RRadius := Radius / 300.0;

        PutStr('PA');
        PutStr(Real2Str(Rx * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(RY * 1016.0, 12, 4));
        PutStr(';');
        PutStr('FT10,');
        PutStr(Real2Str(Fill, 12, 4));
        PutStr(';');
        PutStr('WG');
        PutStr(Real2Str(RRadius * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(StartAngle, 12, 4));
        PutStr(',');
        PutStr(Real2Str(EndAngle - StartAngle, 12, 4));
        PutStr(';');
        PutStr('EW');
        PutStr(Real2Str(RRadius * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(StartAngle, 12, 4));
        PutStr(',');
        PutStr(Real2Str(EndAngle - StartAngle, 12, 4));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE TLaserJet.hpglPointer(OrgX, OrgY, Angle, BeginAt, PLen : REAL);
    CONST
        P180           = PI / 180.0;
    BEGIN
        PutStr('PA');
        PutStr(Real2Str(OrgX * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(OrgY * 1016.0, 12, 4));
        PutStr(';');
        PutStr('PU;');
        PutStr('PR');
        PutStr(Real2Str(COS(P180 * Angle) * BeginAt * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(SIN(P180 * Angle) * BeginAt * 1016.0, 12, 4));
        PutStr(';');
        PutStr('PD;');
        PutStr('PR');
        PutStr(Real2Str(COS(P180 * Angle) * PLen * 1016.0, 12, 4));
        PutStr(',');
        PutStr(Real2Str(SIN(P180 * Angle) * PLen * 1016.0, 12, 4));
        PutStr(';');
        PutStr('PU;');
    END;

    {-----------------}

    FUNCTION TLaserJet.CenterStringX(S : STRING) : REAL;
        {-Return X starting point required to center string S}
    VAR
        Width          : REAL;
    BEGIN
        Width := ComputeStringWidth(S, CtrlForceToSpace);
        CenterStringX := CurLeftMargin + (((CurRightMargin - CurLeftMargin) - Width) / 2.0);
    END;

    {-------------}

    PROCEDURE TLaserJet.AssignFontID(IDNo : FontTypeT);
    BEGIN
        PutStr(#27 + '*c' + Long2Str(BYTE(IDNo) + 1) + 'D');
    END;

    {-------------}

    PROCEDURE TLaserJet.MakeFontTemporary;
    BEGIN
        PutStr(#27 + '*c4F');
    END;

    {-------------}

    PROCEDURE TLaserJet.MakeFontPermanent;
    BEGIN
        PutStr(#27 + '*c5F');
    END;

    {-------------}

    FUNCTION TLaserJet.DownloadFont(IDNo           : FontTypeT;
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
        IF NOT AddFont(IDNo, PointSize, ForceExtension(FontFileName, 'CWD'),
                       #27'(' + Long2Str(BYTE(IDNo) + 1) + 'X') THEN BEGIN
            FILEMODE := OFM;
            EXIT;
        END;

        DownloadFont := TRUE;
        FILEMODE := OFM;
    END;

    {-----------------}

    PROCEDURE TLaserJet.PrintAtRightTabRow(S : STRING; Row, TabStop : REAL);
    BEGIN
        PrnGotoXY(TabStop - ComputeStringWidth(S, CtrlForceToSpace), Row);
        PutStr(S);
    END;

    {-----------------}

    FUNCTION TLaserJet.GetCanBox : BOOLEAN;
    BEGIN
        GetCanBox := ljCanBox;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetCanHPGL : BOOLEAN;
    BEGIN
        GetCanHPGL := ljCanHpgl;
    END;

    {-----------------}

    DESTRUCTOR TLaserJet.Done;
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

    PROCEDURE TLaserJet.GoHPGL;
        {-Enter HPGL/2 graphics mode }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PutStr(#27'%1BIN;SP1;');
    END;

    {-----------------}

    PROCEDURE TLaserJet.GoPCL;
        {-Return to PCL command mode }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PutStr(#27'%0A');
    END;

    {-----------------}

    FUNCTION TLaserJet.PutStr(CONST St : STRING) : BOOLEAN;
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

    FUNCTION TLaserJet.PutStrRJ(CONST St : STRING; CONST X : REAL) : BOOLEAN;
        {-Send a right justified string to the printer }
    BEGIN
        PutStrRJ := PutStrXYRight(St, X, CurRow);
    END;

    {-----------------}

    FUNCTION TLaserJet.PutLine(CONST St : STRING) : BOOLEAN;
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
    FUNCTION TLaserJet.PutCenteredLine(CONST St : STRING) : BOOLEAN;
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
    FUNCTION TLaserJet.PutStrUL(CONST St : STRING) : BOOLEAN;
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
    FUNCTION TLaserJet.PutStrXY(CONST St : STRING; CONST X, Y : REAL) : BOOLEAN;
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
    FUNCTION TLaserJet.PutStrXYRight(CONST St : STRING; CONST X, Y : REAL) : BOOLEAN;
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
    FUNCTION TLaserJet.InitJob : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        InitJob := PutStr(StringFromHeap(ljInitStr));
    END;

    {-----------------}

    FUNCTION TLaserJet.FormFeed : BOOLEAN;
        {-Eject the current page }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        FormFeed := PutStr(StringFromHeap(ljNewPage));

        CurRow := CurTopMargin;
        CurColumn := CurLeftMargin;
    END;

    {-----------------}

    {-Reset the left and right margins to their default }
    FUNCTION TLaserJet.ClearHorizontalMargins : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        ClearHorizontalMargins := PutStr(#27'9');
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

    {-Update the cursor position...X and Y specified in inches }
    FUNCTION TLaserJet.PrnGotoXY(CONST X, Y : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;

        PrnGotoXY := PutStr(#27'&a' + PrnRealStr(InToDP(X -
                                                        P1P2[EPrnTxt].LEFT)) +
                            'h' +
                            PrnRealStr(InToDP(Y -
                                              P1P2[EPrnTxt].TOP)) +
                            'V');
        CurRow := Y;
        CurColumn := X;
    END;

    {-----------------}

    {-Update the horizontal cursor position }
    FUNCTION TLaserJet.PrnGotoX(CONST X : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PrnGotoX := PutStr(#27'&a' + PrnRealStr(InToDP(X - P1P2[EPrnTxt].LEFT)) + 'H');
        CurColumn := X;
    END;

    {-----------------}

    {-Update the vertical cursor position }
    FUNCTION TLaserJet.PrnGotoY(CONST Y : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PrnGotoY := PutStr(#27'&a' + PrnRealStr(InToDP(Y - P1P2[EPrnTxt].TOP)) + 'V');
        CurRow := Y;
    END;

    {-----------------}

    {-Advance the X cursor by Delta inches }
    FUNCTION TLaserJet.PrnAdvanceX(CONST Delta : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF (Delta < 0) THEN
            PrnAdvanceX := PutStr(#27'&a-' + PrnRealStr(InToDP(Delta)) + 'H')
        ELSE IF (Delta > 0) THEN
            PrnAdvanceX := PutStr(#27'&a+' + PrnRealStr(InToDP(Delta)) + 'H');
        CurColumn := CurColumn + Delta;
    END;

    {-----------------}

    {-Advance the Y cursor by Delta inches }
    FUNCTION TLaserJet.PrnAdvanceY(CONST Delta : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF (Delta < 0) THEN
            PrnAdvanceY := PutStr(#27'&a-' + PrnRealStr(InToDP(ABS(Delta))) + 'V')
        ELSE IF (Delta > 0) THEN
            PrnAdvanceY := PutStr(#27'&a+' + PrnRealStr(InToDP(Delta)) + 'V');
        CurRow := CurRow + Delta;

    END;

    {-----------------}

    {-advance to the next line using the current font for delta}
    FUNCTION TLaserJet.LineFeed(VAR NewPos : REAL) : BOOLEAN;
    BEGIN
        LineFeed := FALSE;
        IF NOT PrnAdvanceY(ljActiveFont^.GetLineSpacing) THEN
            EXIT;
        LineFeed := PrnGotoX(CurLeftMargin);
        NewPos := CurRow;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetPointSize : REAL;
    BEGIN
        GetPointSize := ljActiveFont^.fPointSize;
    END;

    {-----------------}

    {-Download a raster graphic to the printer }
    FUNCTION TLaserJet.DownloadGraphic(CONST FName : PathStr) : WORD;
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

    FUNCTION TLaserJet.AddFont(CONST ID       : FontTypeT;
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
    FUNCTION TLaserJet.FindFontByID(CONST ID : FontTypeT) : PFont;
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

    PROCEDURE TLaserJet.RemoveFont(CONST ID : FontTypeT);
        {-Remove a font from the printer }
    VAR
        Font           : PFont;

    BEGIN
        Font := FindFontByID(ID);
        IF (Font <> NIL) THEN
            ljFonts.DELETE(Font);
    END;

    {-----------------}

    PROCEDURE TLaserJet.SelectFont(CONST ID : FontTypeT);
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

    FUNCTION TLaserJet.ComputeStringWidth(CONST St : STRING; CtrlFlg : TCtrlFlg) : REAL;
        {-Compute the width of a string, in inches, for the active font }
    BEGIN
        IF (ljActiveFont = NIL) THEN
            ComputeStringWidth := 0
        ELSE
            ComputeStringWidth := ljActiveFont^.CalcStringWidth(St, CtrlFlg);
    END;

    {-----------------}

    FUNCTION TLaserJet.ComputeStringWidthF(CONST St : STRING; CONST ID : FontTypeT; CtrlFlg : TCtrlFlg) : REAL;
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

    FUNCTION TLaserJet.ComputeStringWidthMF(CONST St : STRING; CONST ID : FontTypeT; Flags : BYTE) : REAL;
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

    FUNCTION TLaserJet.GetLineSpacing : REAL;
        {-Get the recommended line spacing for the current font }
    BEGIN
        IF (ljActiveFont = NIL) THEN
            GetLineSpacing := 0
        ELSE
            GetLineSpacing := ljActiveFont^.GetLineSpacing;
    END;

    {-----------------}

    PROCEDURE TLaserJet.SetHMI(CONST Inches : REAL);
        {-Set the horizontal motion index }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PutStr(#27'&k' + PrnRealStr(Inches * 120) + 'H');
    END;

    {-----------------}

    PROCEDURE TLaserJet.SetVMI(CONST Inches : REAL);
        {-Set the vertical motion index }
    BEGIN
        PutStr(#27'&l' + PrnRealStr(Inches * 48) + 'C');
    END;

    {-----------------}

    FUNCTION TLaserJet.UnderLineOn : BOOLEAN;
        {-Turn on printer underlining }
    BEGIN
        UnderLineOn := PutStr(StringFromHeap(ljULOn));
    END;

    {-----------------}

    FUNCTION TLaserJet.UnderLineOff : BOOLEAN;
        {-Turn off printer underlining }
    BEGIN
        UnderLineOff := PutStr(StringFromHeap(ljULOff));
    END;

    {-----------------}

    FUNCTION TLaserJet.BoldOn : BOOLEAN;
    BEGIN
        BoldOn := PutStr(StringFromHeap(ljBoldOn));
    END;

    {-----------------}

    FUNCTION TLaserJet.BoldOff : BOOLEAN;
    BEGIN
        BoldOff := PutStr(StringFromHeap(ljBoldOff));
    END;

    {-----------------}

    FUNCTION TLaserJet.ItalOn : BOOLEAN;
    BEGIN
        ItalOn := PutStr(StringFromHeap(ljULOn)); {zzzz}
    END;

    {-----------------}

    FUNCTION TLaserJet.ItalOff : BOOLEAN;
    BEGIN
        ItalOff := PutStr(StringFromHeap(ljULOff)); {zzzz}
    END;

    {-----------------}

    {-Draw a horizontal line at X,Y that is Width inches long }
    FUNCTION TLaserJet.HLine(CONST X, Y, Width : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        HLine := TRUE;
        IF NOT ljCanBox THEN
            EXIT;
        HLine := FALSE;
        IF NOT PrnGotoXY(X, Y) THEN
            EXIT;
        ljRectDimensions(InToDP(Width), DotsToDP(3));
        ljFillRect(BlackFill);
        IF COP <> NIL THEN
            COP^.UpDate;
    END;

    {-----------------}

    PROCEDURE TLaserJet.ThickHLine(CONST X, Y, Width : REAL);
        {-Draw a thick horizontal line at X,Y that is Width inches long }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT ljCanBox THEN
            EXIT;
        PrnGotoXY(X, Y);
        ljRectDimensions(InToDP(Width), DotsToDP(6));
        ljFillRect(BlackFill);
    END;

    {-----------------}

    PROCEDURE TLaserJet.VLine(CONST X, Y, Height : REAL);
        {-Draw a vertical line at X,Y that is Height inches long }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT ljCanBox THEN
            EXIT;
        PrnGotoXY(X, Y);
        ljRectDimensions(DotsToDP(3), InToDP(Height));
        ljFillRect(BlackFill);
    END;

    {-----------------}

    {-Draw a thick vertical line at X,Y that is Height inches long }
    PROCEDURE TLaserJet.ThickVLine(CONST X, Y, Height : REAL);
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT ljCanBox THEN
            EXIT;
        PrnGotoXY(X, Y);
        ljRectDimensions(DotsToDP(6), InToDP(Height));
        ljFillRect(BlackFill);
    END;

    {-----------------}

    {-Draw a box, filling it if necessary }
    PROCEDURE TLaserJet.Box(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN);
    BEGIN
        IF NOT ljCanBox THEN
            EXIT;

        IF COP <> NIL THEN
            COP^.UpDate;

        IF Border THEN BEGIN
            HLine(X, Y, Width);
            HLine(X, (Y + Height) - 0.01, Width);
            VLine(X, Y, Height);
            VLine((X + Width) - 0.01, Y, Height);
        END;

        IF (PctGray > 0) THEN BEGIN
            PrnGotoXY(X, Y);
            ljRectDimensions(InToDP(Width), InToDP(Height));
            ljPatternShade(PctGray);
            ljFillRect(ShadedFill);
        END;

    END;

    {-----------------}

    {-Draw a thick box at the current cursor location, filling it if necessary }
    PROCEDURE TLaserJet.BoxThick(CONST Width, Height : REAL; CONST PctGray : BYTE);
    BEGIN
        IF NOT ljCanBox THEN
            EXIT;

        IF COP <> NIL THEN
            COP^.UpDate;
        IF (PctGray > 0) THEN BEGIN
            ljRectDimensions(InToDP(Width), InToDP(Height));
            ljPatternShade(PctGray);
            ljFillRect(ShadedFill);
        END;

        ThickHLine(CurColumn, CurRow, Width);
        ThickHLine(CurColumn, (CurRow + + Height) - 0.02, Width);
        ThickVLine(CurColumn, CurRow, Height);
        ThickVLine((CurColumn + Width) - 0.02, CurColumn, Height);
    END;

    {-----------------}

    {-Draw a box, filling it if desired, with a shadow on it }
    PROCEDURE TLaserJet.BoxShadow(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN);
    VAR
        DPY            : REAL;

    BEGIN
        IF NOT ljCanBox THEN
            EXIT;

        Box(X, Y, Width, Height, PctGray, Border);
        ThickHLine(X + DotsToIn(6), Y + Height, Width);
        ThickHLine(X + DotsToIn(6), Y + Height + DotsToIn(3), Width);
        ThickVLine(X + Width, Y + DotsToIn(6), Height);
        ThickVLine(X + Width + DotsToIn(3), Y + DotsToIn(6), Height);
    END;

    {-----------------}

    {-Draw a double lined box }
    PROCEDURE TLaserJet.DoubleBox(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE);
    VAR
        TenDots        : REAL;

    BEGIN
        IF NOT ljCanBox THEN
            EXIT;

        TenDots := DotsToIn(10);
        Box(X, Y, Width, Height, 0, FALSE);
        Box(X + TenDots, Y + TenDots, Width - (TenDots * 2), Height - (TenDots * 2), PctGray, TRUE);
    END;

    {-----------------}

    {-Print a tag and data between Left and Right with a dot leader }
    PROCEDURE TLaserJet.TagAndDataWithLeader(CONST Tag, Data : STRING; CONST LEFT, RIGHT : REAL);
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
        SelectFont(fBold);

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
        SelectFont(fMainMedium);
    END;

    {-----------------}

    FUNCTION TLaserJet.CenterData(CONST Data : STRING; CONST LEFT, RIGHT : REAL) : REAL;
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

    {-Output a block of text, word wrapped to fit margins}
    {OBSOLETE!  Use DGRPT instead!}
    PROCEDURE TLaserJet.OutputTextWrapped(CONST Buf : PCHAR; CONST LEFT, RIGHT : REAL; CurPage : WORD; Just : JustT);
    VAR
        OnChar         : WORD;
        NewPos,
        R,
        FmtWidth,
        Width,
        MaxWidth       : REAL;
        LastDelimPos   : WORD;
        LastDelim      : BYTE;
        Fmt,
        OutSt          : STRING;
        Center,
        Bold,
        Ul,
        Ital           : BOOLEAN;

    CONST
        DelimSet       = ['`', '~', '!', '@', '#', '%', '^', '&', '*', '=', '+', '\',
        '|', ']', '[', '{', '}', '''', ';', ':', '"', '<', '>', ',', '.',
        '/', '?', ' '];
        PROCEDURE ClearAttrib;
        BEGIN
            PutStr(StringFromHeap(ljBoldOff));
            PutStr(StringFromHeap(ljItalOff));
            PutStr(StringFromHeap(ljULOff));
        END;

        PROCEDURE RestoreAttrib;
        BEGIN
            IF Bold THEN
                Fmt := StringFromHeap(ljBoldOn)
            ELSE
                Fmt := StringFromHeap(ljBoldOff);
            PutStr(Fmt);
            IF Ital THEN
                Fmt := StringFromHeap(ljItalOn)
            ELSE
                Fmt := StringFromHeap(ljItalOff);
            PutStr(Fmt);
            IF Ul THEN
                Fmt := StringFromHeap(ljULOn)
            ELSE
                Fmt := StringFromHeap(ljULOff);
            PutStr(Fmt);
        END;

        PROCEDURE MicrospaceLine;
        VAR
            I              : BYTE;
            Strg           : STRING;
        BEGIN
            FOR I := 1 TO WordCount(OutSt, [' ']) DO
                Strg := ExtractWord(I, OutSt, [' ']);
        END;

        PROCEDURE PutItOut;
        BEGIN
            IF Buf[OnChar] <> #13 THEN BEGIN
                OnChar := LastDelimPos + 1;
                OutSt[0] := CHAR(LastDelim);
            END;

            OutSt := TrimSpaces(OutSt);

            {do a page feed and number it, as we would go over with this line}
            IF CurRow >= (CurBottomMargin - ljActiveFont^.GetLineSpacing) THEN BEGIN
                ClearAttrib;
                DoPageNumAndFF;
                RestoreAttrib;
            END;

            {move cp to center line, if necessary}
            IF Center THEN
                PrnGotoX(CurLeftMargin + (((CurRightMargin - CurLeftMargin) - Width) / 2.0));

            IF Just = ELEFT THEN
                {output the line}
                PutLine(OutSt)
            ELSE
                MicrospaceLine;


            {clear the line buffer}
            OutSt := '';
            LastDelim := 0;
            {scan for next printable character}
            REPEAT
                CASE Buf[OnChar] OF
                    #0,
                    ' ' :
                        BREAK;
                    #13 :
                        BEGIN
                            IF NOT LineFeed(NewPos) THEN BEGIN
                                PostPrnError(Iam);
                                EXIT;
                            END;
                            INC(OnChar);
                            CONTINUE;
                        END;
                    #10 : ;
                    ELSE BEGIN
                        DEC(OnChar);
                        BREAK;
                    END;
                END;
                INC(OnChar);
            UNTIL FALSE;
            FmtWidth := 0.0;
            Width := 0.0;
            Center := FALSE;
        END;

    BEGIN
        IF CurPage <> 0 THEN
            CurPageNum := CurPage;
        OnChar := 0;
        OutSt := '';
        LastDelim := 0;
        LastDelimPos := 0;
        FmtWidth := 0.0;
        MaxWidth := RIGHT - LEFT;
        Bold := FALSE;
        Ul := FALSE;
        Ital := FALSE;
        Center := FALSE;

        SetLeftMargin(LEFT);
        SetRightMargin(RIGHT);
        {PrnGotoXY(CurLeftMargin, CurTopMargin);}

        WHILE (Buf[OnChar] <> #0) DO BEGIN
            IF COP <> NIL THEN
                COP^.UpDate;
            CASE Buf[OnChar] OF
                #10 :
                    INC(OnChar);
                #13 :
                    BEGIN
                        IF (OutSt <> '') THEN
                            PutItOut
                        ELSE
                            IF NOT LineFeed(NewPos) THEN BEGIN
                                PostPrnError(Iam);
                                EXIT;
                            END;
                        IF Buf[OnChar] = #0 THEN
                            CONTINUE;
                        INC(OnChar);
                        Center := FALSE;
                        CONTINUE;
                    END;
                CenterTok :       {Center line between margins (entire line must fit!)}
                    BEGIN
                        Center := TRUE;
                        INC(OnChar);
                    END;
                BoldTok :         {toggle bold}
                    BEGIN
                        Bold := NOT Bold;
                        IF Bold THEN
                            Fmt := StringFromHeap(ljBoldOn)
                        ELSE
                            Fmt := StringFromHeap(ljBoldOff);
                        FmtWidth := FmtWidth + ComputeStringWidth(Fmt, CtrlForceToSpace);
                        OutSt := OutSt + Fmt;
                        INC(OnChar);
                        CONTINUE;
                    END;
                ULTok :           {toggle underline}
                    BEGIN
                        Ul := NOT Ul;
                        IF Ul THEN
                            Fmt := StringFromHeap(ljULOn)
                        ELSE
                            Fmt := StringFromHeap(ljULOff);
                        FmtWidth := FmtWidth + ComputeStringWidth(Fmt, CtrlForceToSpace);
                        OutSt := OutSt + Fmt;
                        INC(OnChar);
                        CONTINUE;
                    END;
                ItalicTok :       {toggle italics}
                    BEGIN
                        Ital := NOT Ital;
                        IF Ital THEN
                            Fmt := StringFromHeap(ljItalOn)
                        ELSE
                            Fmt := StringFromHeap(ljItalOff);
                        FmtWidth := FmtWidth + ComputeStringWidth(Fmt, CtrlForceToSpace);
                        OutSt := OutSt + Fmt;
                        INC(OnChar);
                    END;
                #9 :              {tab - set to every 1/2"}
                    BEGIN
                        LastDelimPos := OnChar;
                        IF FRAC(Width) < 0.5 THEN
                            R := TRUNC(Width) + 0.5
                        ELSE
                            R := ROUND(Width + 0.5);

                        FmtWidth := FmtWidth - (R - Width);

                        Fmt := #27'&a' + PrnRealStr(InToDP(R - P1P2[EPrnTxt].LEFT + CurLeftMargin)) + 'H';
                        FmtWidth := FmtWidth + ComputeStringWidth(Fmt, CtrlForceToSpace);
                        OutSt := OutSt + Fmt;
                        Width := ComputeStringWidth(OutSt, CtrlForceToSpace) - FmtWidth;
                        IF (Width > MaxWidth) THEN
                            PutItOut
                        ELSE
                            INC(OnChar);
                    END;
                #12 :             {formfeed}
                    BEGIN
                        LastDelimPos := OnChar;
                        PutItOut;
                        ClearAttrib;
                        DoPageNumAndFF;
                        RestoreAttrib;
                        INC(OnChar);
                    END;
                ELSE BEGIN
                    ChrCat(OutSt, Buf[OnChar]);
                    IF (Buf[OnChar] IN DelimSet) THEN BEGIN
                        IF NOT((Buf[OnChar] = ',') AND NOT(Buf[SUCC(OnChar)] = ' ')) THEN BEGIN
                            LastDelimPos := OnChar;
                            LastDelim := LENGTH(OutSt);
                        END;
                    END;

                    Width := ComputeStringWidth(OutSt, CtrlForceToSpace) - FmtWidth;
                    IF (Width > MaxWidth) THEN
                        PutItOut
                    ELSE
                        INC(OnChar);
                END;
            END;
        END;

        IF (OutSt <> '') THEN BEGIN
            PutStr(TrimSpaces(OutSt));
            PrnAdvanceY(ljActiveFont^.GetLineSpacing);
            PrnGotoX(LEFT);
        END;
    END;

    {-----------------}

    PROCEDURE TLaserJet.PieWedge(CONST X, Y, Radius : WORD; CONST StartAngle, EndAngle, Fill : REAL);
        {-Print a pie wedge }

        PROCEDURE PutReal(CONST R : REAL; CONST MoreParms : BOOLEAN);
        BEGIN
            PutStr(PrnRealStr(R));
            IF MoreParms THEN
                PutStr(',')
            ELSE
                PutStr(';');
        END;

    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PutStr('PA');
        PutReal(X, TRUE);
        PutReal(Y, FALSE);

        PutStr('FT10,');
        PutReal(Fill, FALSE);

        PutStr('WG');
        PutReal(Radius, TRUE);
        PutReal(StartAngle, TRUE);
        PutReal(EndAngle - StartAngle, FALSE);

        PutStr('EW');
        PutReal(Radius, TRUE);
        PutReal(StartAngle, TRUE);
        PutReal(EndAngle - StartAngle, FALSE);
    END;

    {-----------------}

    PROCEDURE TLaserJet.hpglPW(CONST Width : REAL);
        {-Set the width of the HPGL/2 pen }
    BEGIN
        PutStr('PW');
        PutStr(PrnRealStr(Width));
        PutStr(';');
    END;

    {-----------------}

    PROCEDURE TLaserJet.GraphicsTransparency(CONST On : BOOLEAN);
        {-Set the HPGL/2 transparency mode on or off }
    BEGIN
        IF On THEN
            PutStr('TR1;')
        ELSE
            PutStr('TR0;');
    END;

    {-----------------}

    FUNCTION TLaserJet.ljPatternShade(CONST Percent : BYTE) : BOOLEAN;
    BEGIN
        ljPatternShade := PutStr(#27'*c' + Long2Str(Percent) + 'G');
    END;

    {-----------------}

    FUNCTION TLaserJet.ljRectDimensions(CONST WidthInDP, HeightInDP : REAL) : BOOLEAN;
        {-Specify the parameters of the print model rectangle }
    BEGIN
        ljRectDimensions := PutStr(#27'*c' + PrnRealStr(WidthInDP) + 'h' + PrnRealStr(HeightInDP) + 'V');
    END;

    {-----------------}

    FUNCTION TLaserJet.ljFillRect(CONST Fill : RectFillType) : BOOLEAN;
        {-Fill the previously specified rectangle }
    VAR
        Cmd            : CHAR;

    BEGIN
        IF (Fill = NoFill) THEN
            EXIT;
        CASE Fill OF
            BlackFill :
                Cmd := '0';
            EraseFill :
                Cmd := '1';
            ShadedFill :
                Cmd := '2';
            CrossHatchFill :
                Cmd := '3';
            UserDefFill :
                Cmd := '4';
            CurrentPatFill :
                Cmd := '5';
        END;
        ljFillRect := PutStr(#27'*c' + Cmd + 'P');
    END;

    {-----------------}

    PROCEDURE TLaserJet.PrnPutBlock(VAR Block; BlockSize : WORD);
    BEGIN
        IF (PType <> NONE) AND AllowPrint THEN
            ljPrn^.PrnPutBlock(Block, BlockSize);
    END;

    {-----------------}

    FUNCTION TLaserJet.PrnError : WORD;
    BEGIN
        PrnError := ljPrn^.PrnError;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetPtype : PrnModelT;
    BEGIN
        GetPtype := PType;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetDevName : STRING;
    BEGIN
        GetDevName := 'Unknown';
        CASE PType OF
            HPLJ2,
            HPLJ3,
            HPLJ4 :
                GetDevName := 'HPLJET';
            HPDJ :
                GetDevName := 'HPDJET';
            HPDJC :
                GetDevName := 'HPDJETC';

        END;                      {CASE}
    END;

    {-----------------}

    FUNCTION TLaserJet.GetCOP : CylonP;
    BEGIN
        GetCOP := COP;
    END;

    {-----------------}

    PROCEDURE TLaserJet.PrintAtLeftTabRow(S : STRING; Row, TabStop : REAL);
    BEGIN
        PrnGotoXY(TabStop, Row);
        PutStr(S);
    END;

    {-----------------}

    {center a page number at bottom margin}
    PROCEDURE TLaserJet.DoPageNumAndFF;
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

    FUNCTION TLaserJet.GetModeStr(Mode : CharModeT) : STRING;
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

    FUNCTION TLaserJet.LoadCharTable(Name : PathStr) : BOOLEAN;
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
    PROCEDURE TLaserJet.GrafDriveInit(P1x, P1y, P2x, P2y : REAL;
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

    PROCEDURE TLaserJet.GrafDriveInitBand(P1x, P1y,
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
    PROCEDURE TLaserJet.GrafDriveInitDeluxe(Mode           : TxtGraf;
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
    PROCEDURE TLaserJet.GrafDriveInitPL(Mode           : TxtGraf;
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
    PROCEDURE TLaserJet.GrafDriveFinish;
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

    PROCEDURE TLaserJet.DrawPie(NoOfSlices     : BYTE;
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
    BEGIN
        DispErrorDeluxe('Abstract DrawPie!', '', TRUE, Iam);
        HALT(1);
    END;

    {--------------}

    {convert inches to dots, using current graphdrive device}
    {this assumes viewport=fullpage}
    PROCEDURE TLaserJet.GDIn2XY(Inx, Iny       : REAL;
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

    {reset the printer to known state - ejects page if partial}
    PROCEDURE TLaserJet.ResetPrn;
    BEGIN
        PutStr(#27'E');
    END;

    {-----------------}

    {low level tray selection.  At this level we dont know which     }
    {tray or source has letterhead / blank paper.  Abstraction layer }
    {is in methods found below...                                    }
    PROCEDURE TLaserJet.SelectTray(T : TLetterHeadTray);
    BEGIN
        CASE PType OF
            HPLJ3,
            HPLJ4 :
                BEGIN
                    CASE T OF
                        TLHSingle, {single tray printer}
                        TLHTop :  {select top tray of dual tray}
                            PutStr(#27'&l1H');
                        TLHManEnvFeed : {select manual envelope feeder}
                            PutStr(#27'&l2H');
                        TLHMan :  {select man paper feed}
                            PutStr(#27'&l3H');
                        TLHBottom : {select bottom tray of dual tray}
                            PutStr(#27'&l4H');
                        TLHOpt :  {select optional paper source}
                            PutStr(#27'&l5H');
                        TLHEnvFeed : {select automatic envelope feeder}
                            PutStr(#27'&l6H');
                    END;
                END;
        END;                      {case}
    END;

    {-----------------}

    {initialize the Letterhead and Blank paper trays }
    {Infer blank tray if not known                   }
    PROCEDURE TLaserJet.SetTrays(Ltr, Blnk : TLetterHeadTray);
    BEGIN
        MyLetterHeadTray := Ltr;
        IF Blnk <> TLHUnknown THEN
            MyBlankTray := Blnk
        ELSE BEGIN
            {don't know, so derive the blank page from the top setting}
            CASE Ltr OF
                TLHManEnvFeed,
                TLHMan,
                TLHBottom,
                TLHOpt,
                TLHEnvFeed,
                TLHSingle :
                    MyBlankTray := TLHSingle;
                TLHTop :
                    MyBlankTray := TLHBottom;
            END;
        END;
    END;

    {-----------------}

    {select a paper type - letterhead or blank}
    PROCEDURE TLaserJet.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        CASE Tray OF
            ELetterhead :
                SelectTray(MyLetterHeadTray);
            EBlank :
                SelectTray(MyBlankTray);
        END;
    END;

    {-----------------}

    {translate desired color into printer color}
    FUNCTION TLaserJet.TranslateColor(DesiredColor : TPrnColors) : BYTE;
    BEGIN
        TranslateColor := BYTE(MyWheel[DesiredColor]);
    END;

    {-----------------}

    {select a text color}
    PROCEDURE TLaserJet.SelectTextColor(C : TPrnColors);
    BEGIN
        IF ljIsColor THEN
            PutStr(#27'*p0P'#27'*r3U'#27'*v' +
                   Long2Str(MyRGBTextWheel[C]) +
                   'S');
    END;

    {-----------------}

    {force printer back into black&white text mode}
    PROCEDURE TLaserJet.SelectTextMonoChrome;
    BEGIN
        IF ljIsColor THEN
            PutStr(#27'*p0P'#27'*r1U');
    END;

    {-----------------}

    PROCEDURE TLaserJet.PostPrnError(P : POINTER);
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

    PROCEDURE TLaserJet.SetGDRes(R : WORD);
    BEGIN
        GDRes := R;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetGDRes : WORD;
    BEGIN
        GetGDRes := GDRes;
    END;

    {-----------------}

    PROCEDURE TLaserJet.SetPageNum(PG : WORD);
    BEGIN
        CurPageNum := PG;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetPageNum : WORD;
    BEGIN
        GetPageNum := CurPageNum;
    END;

    {-----------------}

    {set/clear allow print flag}
    {if printing is not allowed, then throw}
    {chars in bitbucket as they are printed}
    PROCEDURE TLaserJet.SetAllowPrint(Allow : BOOLEAN);
    BEGIN
        AllowPrint := Allow;
    END;

    {-----------------}

    FUNCTION TLaserJet.GetAllowPrint : BOOLEAN;
    BEGIN
        GetAllowPrint := AllowPrint;
    END;

    {-----------------}
    {if true, then not a good idea to mix text and graphics}
    {on same line (HPDJ printers)                          }
    FUNCTION TLaserJet.IsFlakeyOnMixedTextGraph : BOOLEAN;
    BEGIN
        IsFlakeyOnMixedTextGraph := FlakeyMixedTextGraph;
    END;

    {-----------------}

    {draw high level chart}
    {$IFNDEF VirtualPascal}
    PROCEDURE TLaserJet.DrawChart(Ch : ChartDef);
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

    FUNCTION TLaserJet.GetCurOrient : TPrnPlot;
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

    FUNCTION TLaserJet.GetCurRow : REAL;
    BEGIN
        GetCurRow := CurRow;
    END;

    {--------------}

END.

    {-----------------}
    {-----------------}

