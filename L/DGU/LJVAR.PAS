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
* Laserjet low level types and constants
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F-,G-,I+,N-,O+,P-,Q+,T-,V+,X+,Y+}
UNIT LJVAR;

INTERFACE
USES
    Dos,
    OpPrnlow;

CONST
    LJDPI          = 300;
    DegreesToRadians = 0.01745;
    CenterTok      = '';
    BoldTok        = '';
    ULTok          = '';
    ItalicTok      = '';
    InchesPerPt    = 1.0 / 72.0;

TYPE
    TxtGraf        = (EPrnTxt, EPrnGraph, EPrnScreen, EPrnBitMap);

    TPrnPlot       = (EPrtOrient, EPlotOrient);

    TGrafOrient    = (EPortrait, ELandscape);
    TGrafColors    = (E2Color, E8Color, E16Color, E256Color);
    TGrafDPI       = (ELowRes, EMedRes, EHighRes);
    TGrafQual      = (EDraft, ELtrQual);
    TGrafPage      = (EHalfPg, EFullPg);

    FontTypeT      = (
             fNone,
             fSmall,
             fFootnote,
             fMain,
             fItalic,
             fBold,
             fBoldItalic,         {Warning! this is an artifact!}
             fTable,
             fHuge,
             fHugeItalic,
             fMainMedium,
             fItalicMedium,
             fBoldMedium,
             fLinePrint,
             fCourier);

    TStroke        = (SNorm, SBold, SItalic);

    TLetterHeadTray = (TLHSingle,
                       TLHTop,
                       TLHBottom,
                       TLHMan,
                       TLHOpt,
                       TLHManEnvFeed,
                       TLHEnvFeed,
                       TLHUnknown);

    TPaperStyle    = (ELetterhead, EBlank);

    TPrnColors     = (tpcBLACK,   {0}
                      tpcBLUE,    {1}
                      tpcGREEN,   {2}
                      tpcCYAN,    {3}
                      tpcRED,     {4}
                      tpcMAGENTA, {5}
                      tpcBROWN,   {6}
                      tpcLTGRAY,  {7}
                      tpcDKGRAY,
                      tpcLTBLUE,
                      tpcLTGREEN,
                      tpcLTCYAN,
                      tpcLTRED,
                      tpcLTMAGENTA,
                      tpcYELLOW,
                      tpcWHITE);

    TColorWheel    = ARRAY[TPrnColors] OF TPrnColors;
    TRGBTextWheel  = ARRAY[TPrnColors] OF BYTE;

TYPE
    TPieSlice      = RECORD
                         Percent        : WORD;
                         Color,
                         Fill           : INTEGER;
                         Tag            : STRING[40];
                         ExplodeFlag    : BOOLEAN;

                         {this gets calculated}
                         StartAngle,
                         EndAngle,
                         LabelLineLength,
                         LabelLineAngle : INTEGER;
                     END;



CONST
    MaxSlices      = 10;


    {-------------------}

    {Pie drawing routines}
TYPE
    TPieArray      = ARRAY[1..MaxSlices] OF TPieSlice;
    PPieArray      = ^TPieArray;

CONST
    TFontVarient   : ARRAY[FontTypeT, TStroke] OF FontTypeT =
    ((fNone, fNone, fNone),
     (fSmall, fSmall, fSmall),
     (fFootnote, fFootnote, fFootnote),
     (fMain, fBold, fItalic),
     (fItalic, fBold, fItalic),
     (fBold, fBold, fBold),
     (fBoldItalic, fBoldItalic, fBoldItalic),
     (fTable, fBoldMedium, fItalicMedium),
     (fHuge, fHuge, fHuge),
     (fHugeItalic, fHugeItalic, fHugeItalic),
     (fMainMedium, fBoldMedium, fItalicMedium),
     (fItalicMedium, fBoldMedium, fItalicMedium),
     (fBoldMedium, fBoldMedium, fItalicMedium),
     (fLinePrint, fLinePrint, fLinePrint),
     (fCourier, fCourier, fCourier));

    {paragraph wrap stroke flags}
    wrNorm         = 0;
    wrBold         = 1;
    wrUL           = 2;
    wrItalic       = 4;


TYPE
    RectFillType =
    (
        BlackFill,
        EraseFill,
        ShadedFill,
        CrossHatchFill,
        UserDefFill,
        CurrentPatFill,
        NoFill);

    PrnModelT      = (NONE,
                      HPLJ2,
                      HPLJ3,
                      HPLJ4,
                      HPLJ4MP,
                      {$IFDEF ALLOWDUPLEX}
                      HPLJ4Dplx,
                      {$ENDIF}
                      HPDJ,
                      HPDJC,
                      HPDJ5xxC,
                      DL6400,
                      HPDJ1200,
                      HP1600C,
                      HP855C,
                      HP8x0C,
                      {$IFDEF ALLOWDMPRINT}
                      Okidata,
                      Epson,
                      Seikosha,
                      {$ENDIF}
                      Screen);

CONST
    PrnModels      : ARRAY[PrnModelT] OF STRING[18] =
    (                             {12345678901234567890}
        'NONE',
        'HPLJ2',
        'HPLJ3',
        'HPLJ4',
        'HPLJ4MP',
        {$IFDEF ALLOWDUPLEX}
        'HPLJ4/5 Dplx',
        {$ENDIF}
        'HPDJET',
        'HPDJETC',
        'HPDJ5xxC',
        'DL6400',
        'HPDJ1200C',
        'HP1600C',
        'HP855C',
        'HP8x0C',
        {$IFDEF ALLOWDMPRINT}
        'Okidata (Epson)',
        'Epson',
        'Seikosha(Epson)',
        {$ENDIF}
        'Screen');
    {
    TGrafOrient   = (EPortrait, ELandscape);
    TGrafColors   = (E2Color, E8Color, E16Color, E256Color);
    TGrafDPI      = (ELowRes, EMedRes, EHighRes);
    TGrafQual     = (EDraft, ELtrQual);
    TGrafPage     = (EHalfPg, EFullPg);
    }

    {table to map portrait/landscape Graphdrive modes to desired true}
    {orientation.  Graphdrive plotters are 90 degrees out of phase   }
    {EPortrait, ELandscape}
    GrafModeLUT    : ARRAY[PrnModelT, TGrafOrient] OF SHORTINT =
    (
        (- 1, - 1),               {NONE}
        (8, 5),                   {HPLJ2}
        (2, 1),                   {HPLJ3}
        (2, 1),                   {HPLJ4}
        (2, 1),                   {HPLJ4MP}
        {$IFDEF ALLOWDUPLEX}
        (2, 1),                   {HPLJ4Dplx}
        {$ENDIF}
        (8, 5),                   {HPDJET}
        (8, 5),                   {HPDJETC}
        (8, 5),                   {HPDJ5xxC}
        (8, 5),                   {DL6400}
        (8, 5),                   {HPDJ1200C}
        (8, 7),                   {HP1600C}
        (8, 5),                   {HP855C}
        (8, 5),                   {HP8x0C}
        {$IFDEF ALLOWDMPRINT}
        (8, 5),                   {Okidata}
        (8, 5),                   {Epson}
        (8, 5),                   {Seikosha}
        {$ENDIF}
        (127, 127)                {Screen}
        );

    PrnNames       : ARRAY[PrnModelT] OF STRING[30] =
    {             1         2         3         4}
    {    1234567890123456789012345678901234567890}
    (
        'No printer connected',
        'HP LaserJet II',
        'HP LaserJet III',
        'HP LaserJet IV',
        'HP LaserJet 4mp',
        {$IFDEF ALLOWDUPLEX}
        'HP LaserJet 4/5 Duplex',
        {$ENDIF}
        'Generic HP Mono DeskJet',
        'Generic HP Color DeskJet',
        'HP 500 Series Color DeskJet',
        'Fujitsu DL6400 (no graphics)',
        'HP DeskJet 1200C',
        'HP 1600C color',
        'HP DeskJet 855C color',
        'HP DeskJet 870/890C color',
        {$IFDEF ALLOWDMPRINT}
        'Generic Okidata (Epson mode)',
        'Generic Epson',
        'Seikosha (Epson mode)',
        {$ENDIF}
        'Screen - don''t use!');

    zzzPrnNames    : ARRAY[PrnModelT] OF STRING[30] =
    {             1         2         3         4}
    {    1234567890123456789012345678901234567890}
    (
        'No printer connected',
        'HP LaserJet II',
        'HP LaserJet III',
        'HP LaserJet IV',
        'HP LaserJet 4mp',
        {$IFDEF ALLOWDUPLEX}
        'HP LaserJet 4/5 Duplex',
        {$ENDIF}
        'Generic HP Mono DeskJet',
        'Generic HP Color DeskJet',
        'HP 500 Series Color DeskJet',
        'Fujitsu DL6400 (no graphics)',
        'HP DeskJet 1200C',
        'HP 1600C color',
        'HP DeskJet 855C color',
        'HP DeskJet 870/890C color',
        {$IFDEF ALLOWDMPRINT}
        'Generic Okidata (Epson mode)',
        'Generic Epson',
        'Seikosha (Epson mode)',
        {$ENDIF}
        'Screen - don''t use!');

    FontNames      : ARRAY[FontTypeT] OF STRING[20] =
    (
        'fNone',
        'fSmall',
        'fFootnote',
        'fMain',
        'fItalic',
        'fBold',
        'fBoldItalic',
        'fTable',
        'fHuge',
        'fHugeItalic',
        'fMainMedium',
        'fItalicMedium',
        'fBoldMedium',
        'fLinePrint',
        'fCourier'
        );

TYPE
    CharModeT      = (EINIT, EBOLDON, EULON, EITALON, EBOLDOFF, EULOFF, EITALOFF, ENEWPAGE);

    PCharWidthEntry = ^TCharWidthEntry;
    TCharWidthEntry = RECORD
                          HorizEscape    : INTEGER;
                          LeftExtent     : INTEGER;
                          RightExtent    : INTEGER;
                          Defined        : BOOLEAN;
                      END;

    PCharWidthTable = ^TCharWidthTable;
    TCharWidthTable = RECORD
                          InchesPerPoint : REAL;
                          DesignUnits    : REAL;
                          Spacing        : INTEGER;
                          LineSpacing    : INTEGER;
                          Metrics        : ARRAY[#32..#255] OF TCharWidthEntry;
                      END;

    {holds a single printer}
    PPrnCfg        = ^TPrnCfg;
    TPrnCfg        = RECORD
                         PName          : STRING[30]; {recco, enroll, ...}
                         PType          : PrnModelT; {HPLJ2...}
                         PPort          : PrnType; {LPT2}
                         TrayLtr,
                         TrayBlnk       : TLetterHeadTray;
                         PortName,
                         FontPath,
                         BGIPath        : PathStr; {diskfilename, 'lpt1'...}
                     END;

    {$IFDEF MULTIPRINT}
type
    TPrnPriSec = (EPRIMARY, ESECONDARY, ETERTIARY, ENULLPRT, ESCREEN);
    TPrnCfgArray = ARRAY[TPrnPriSec] OF TPrnCfg;
    {$ELSE}
TYPE
    TPrnCfgArray   = TPrnCfg;
    TPrnPriSec     = (Eprimary, ENULLPRT, EScreen);
    {$ENDIF}
    PPrnCfgArray   = ^TPrnCfgArray;

IMPLEMENTATION
END.
