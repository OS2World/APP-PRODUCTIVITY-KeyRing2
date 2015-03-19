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
* High level report generator object.  Provides generic knowledge of report
* printing.
*
* ~notesend~
* ~nokeywords~
***************************************************************************

}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT DGRPT;

INTERFACE

USES
    DGPRINT,
    DGWRAP,
    Dos,
    GLOBTYPE,
    LJVAR,
    KERROR,
    OpDate,
    OpPrnlow,
    OpRoot
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

TYPE
    FmtTokensT =
    (
        tagBreakPoint,
        tagRaster,
        tagLetterHead,
        tagBlankPaper,
        tagDate,
        tagPages,
        tagTab,
        tagPage,
        tagPageFF,
        tagCenter,
        tagfSmall,
        tagfMain,
        tagfItalic,
        tagfBold,
        tagfBoldItalic,
        tagfTable,
        tagfHuge,
        tagfHugeItalic,
        tagfMainMedium,
        tagfItalicMedium,
        tagfBoldMedium,
        tagfLinePrint,
        tagBldOn,
        tagBldOff,
        tagULineOn,
        tagULineOff,
        tagItalOn,
        tagItalOff,
        tagPrnGotoXY,
        tagPrnGotoX,
        tagPrnGotoY,
        tagPrnGotoXYM,
        tagPrnGotoXM,
        tagPrnGotoYM,
        tagSetLeftMargin,
        tagSetRightMargin,
        tagSetTopMargin,
        tagSetBotMargin,
        tagHeaderBar,
        tagBox,
        tagMAT,
        tagMessageBox,
        tagChapter,
        tagTOCEntry,
        tagEndIf);

CONST
    TagChar        = '@';

TYPE
    {ifstack object}
    IFP            = ^TIF;
    TIF            = OBJECT(ROOT)
                         MyLine         : LONGINT;
                         MyTF           : BOOLEAN;
                         CONSTRUCTOR Init(TF : BOOLEAN; Line : LONGINT);
                         FUNCTION GetStat(VAR Line : LONGINT) : BOOLEAN;
                     END;
    TChapRec       = RECORD
                         Name           : STRING;
                         ChapNum,
                         PG             : LONGINT;
                     END;

    TTOCRec        = RECORD
                         TOCEntry       : STRING;
                         PG             : LONGINT;
                     END;

    PChapObj       = ^TChapObj;
    TChapObj       = OBJECT(SingleListNode)
                         MyChapRec      : TChapRec;
                         MyTOCList      : SingleList;

                         CONSTRUCTOR Init(VAR C : TChapRec);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetChapName : STRING;
                         FUNCTION GetChapNum : LONGINT;
                         FUNCTION GetChapPage : LONGINT;
                         FUNCTION AppendTOC(T : TTOCRec) : BOOLEAN;
                         PROCEDURE GetChapRec(VAR C : TChapRec);
                         FUNCTION GetTOCCount : LONGINT;
                         FUNCTION GetNthTOC(N : LONGINT; VAR T : TTOCRec) : BOOLEAN;
                     END;

    PTOCObj        = ^TTOCObj;
    TTOCObj        = OBJECT(SingleListNode)
                         MyTOCRec       : TTOCRec;

                         CONSTRUCTOR Init(VAR T : TTOCRec);
                         FUNCTION GetTOCEntry : STRING;
                         FUNCTION GetTOCPage : LONGINT;
                         PROCEDURE GetTOCRec(VAR T : TTOCRec);
                     END;


    {generic report generator - derive other reports from this}
    PReport        = ^Report;
    Report         = OBJECT(ROOT)
                         {pointer to current printer object}
                         PRP            : PPrinter;

                         MyJanuaryMsg,
                         {parser column}
                         ColIndex,
                         {parser index}
                         LineIndex      : WORD;
                         {current TEM input line}
                         TemInputLine,
                         {line for output to printer}
                         OutLine        : STRING;
                         {current TEM line number}
                         TemLineNum     : LONGINT;
                         {name of current template file}
                         TemplateName   : PathStr;
                         {file handle to current template file}
                         Template       : TEXT;
                         {user token dictionary}
                         RptTagDict,
                         {internal dictionary for hardwired format tokens}
                         FmtTagDict     : StringDict;
                         {the ubiqutious cylon - a printer activity indicator}
                         COP            : CylonP;
                         PWRAP          : PParaWrap;

                         {Create/destroy}
                         CONSTRUCTOR Init(PrnInfo : TPrnCfg);

                         CONSTRUCTOR InitPRP(LJP : PPrinter; AllowPrint : BOOLEAN);

                         CONSTRUCTOR InitTOC(LJP : PPrinter; AllowPrint : BOOLEAN; VAR PTOC : SingleListPtr);

                         DESTRUCTOR Done; VIRTUAL;

                             {run the object}
                         PROCEDURE Process; VIRTUAL;

                             {virtualize the next three methods to allow     }
                             {encrypted template readers to be descended from}
                             {this object}
                         FUNCTION OpenTemFile : BOOLEAN; VIRTUAL;
                         PROCEDURE CloseTemFile; VIRTUAL;
                         FUNCTION ReadTemLine : BOOLEAN; VIRTUAL;

                             {descendent object must override this}
                         FUNCTION ProcessUserTag(Tag : LONGINT) : BOOLEAN; VIRTUAL;

                             {generic error message for TEM syntax errors}
                         PROCEDURE BadTemLine(Msg : STRING; LogIt : BOOLEAN; Where : POINTER);

                             {set up for long english/foreign date strings}
                         PROCEDURE SetJanuaryMsgNum(J : WORD);

                             {is current IF context false?}
                         FUNCTION Skipping : BOOLEAN;

                             {push TEM @If@ context on to stack}
                         PROCEDURE PushIf(TF : BOOLEAN);

                             {push TEM @If@ context on to stack}
                         PROCEDURE PushIfNoEmit(TF : BOOLEAN);

                             {concatenate S to end of current printer buffer}
                         PROCEDURE ConcatOutLine(S : STRING);

                             {concatenate S to end of current printer buffer}
                             {and print the buffer }
                         PROCEDURE Putoutline(Strg : STRING);

                             {get parameter(s) associatated with a TEM token}
                         FUNCTION GetNextParam(VAR Strg : STRING) : BOOLEAN;

                         FUNCTION GetNextReal(VAR R : REAL) : BOOLEAN;
                         FUNCTION GetNextLong(VAR L : LONGINT) : BOOLEAN;

                             {print std header bar at top of page}
                         PROCEDURE DoHeaderBar; VIRTUAL;
                         FUNCTION PutRaster(FName : PathStr) : BOOLEAN;
                         FUNCTION GetPgNum : WORD;
                         FUNCTION LoadCharTable(XLCName : PathStr) : BOOLEAN;
                         FUNCTION FormatDate(D : Date) : STRING; VIRTUAL;
                         PROCEDURE DoPageNumAndFF; VIRTUAL;
                         FUNCTION GetChapterCount : LONGINT;
                         FUNCTION GetTOCCountForChapter(ChapterNum : WORD) : LONGINT;
                         FUNCTION GetNthChapter(N : WORD; VAR C : TChapRec; VAR TOCCount : LONGINT) : BOOLEAN;
                         FUNCTION GetTOCEntry(ChapterNum, TOCNum : WORD; VAR T : TTOCRec) : BOOLEAN;
                     PRIVATE
                         IFStack        : PointerStackPtr;
                         ChapList       : SingleListPtr;
                         CenterLine,
                         EjectPage      : BOOLEAN;
                         TabColumn      : BYTE;
                         Result         : WORD;

                             {internal methods}
                         FUNCTION ProcessLine : BOOLEAN;

                         PROCEDURE OutputLine(S : STRING);
                         PROCEDURE OutputCenteredLine(S : STRING);
                         PROCEDURE LineFeed;
                         PROCEDURE PrintRaster;
                         PROCEDURE PrnGotoX;
                         PROCEDURE PrnGotoY;
                         PROCEDURE PrnGotoXY;
                         PROCEDURE PrnGotoXM;
                         PROCEDURE PrnGotoYM;
                         PROCEDURE PrnGotoXYM;
                         PROCEDURE DrawBox;
                         PROCEDURE SetLeftMargin;
                         PROCEDURE SetRightMargin;
                         PROCEDURE SetTopMargin;
                         PROCEDURE SetBotMargin;

                         PROCEDURE PrnMessageBox;
                         FUNCTION ProcessTag(Token : FmtTokensT) : BOOLEAN; VIRTUAL;
                         FUNCTION LongIntFormS(Mask : STRING; L : LONGINT) : STRING;
                         PROCEDURE EmitLine;
                         PROCEDURE StuffWrap(EmitFlg : BOOLEAN);
                         PROCEDURE DoEndif;
                         PROCEDURE WrapDone;
                         PROCEDURE AddChapter;
                         PROCEDURE AddTOCEntry;
                     END;


IMPLEMENTATION
USES
    {$IFNDEF VirtualPascal}
    Boiler45,
    {$ENDIF}
    DGLIB,
    MSGMGR,
    OpCmd,
    OpCRT,
    OpString,
    OpWindow,
    PRINTERS,
    Strings,
    UTIAM;

CONST
    InchPerMM      = 0.03937;
    MaxParaSize    = 8000;
    LJustWrap      = '~>';
    LRJustWrap     = '~|';
    LRJustInWrap   = '~)';
    RJustWrap      = '~<';
    CJustWrap      = '~=';
    RemToken       = '//';

    {-------------}

    CONSTRUCTOR Report.InitPRP(LJP : PPrinter; AllowPrint : BOOLEAN);
    BEGIN
        PWRAP := NIL;
        PRP := LJP;

        IF PRP <> NIL THEN
            COP := PRP^.GetCOP;

        {$IFDEF DEBUG}
        IF ScnMsgP <> NIL THEN
            ScnMsgP^.Clear;
        IF PrnMsgP <> NIL THEN
            PrnMsgP^.Clear;
        {$ENDIF}

        IF PRP <> NIL THEN
            PRP^.SetAllowPrint(AllowPrint);

        IF ChapList = NIL THEN
            NEW(ChapList, Init);

        IF ChapList = NIL THEN BEGIN
            DispErrorDeluxe('chaplist init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        {create stack for @IFxxx@/@endif@ contexts}
        NEW(IFStack, Init(20));
        IF IFStack = NIL THEN BEGIN
            DispErrorDeluxe('ifstack init fail ' + TemplateName, ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        MyJanuaryMsg := 0;

        {Create dictionary}
        FmtTagDict.InitCustom(2048);
        IF InitStatus <> 0 THEN BEGIN
            DispErrorDeluxe('Unable to create report template dictionary',
                            TemplateName + ' ' + ErrorMessage(InitStatus),
                            TRUE, Iam);
            FAIL;
        END;

        {Create dictionary}
        RptTagDict.InitCustom(2048);
        IF InitStatus <> 0 THEN BEGIN
            DispErrorDeluxe('Unable to create report template dictionary',
                            TemplateName + ' ' + ErrorMessage(InitStatus),
                            TRUE, Iam);
            FAIL;
        END;

        FmtTagDict.Add('@Raster@', LONGINT(tagRaster));
        FmtTagDict.Add('@Letterhead@', LONGINT(tagLetterHead));
        FmtTagDict.Add('@BlankPaper@', LONGINT(tagBlankPaper));
        FmtTagDict.Add('@Date@', LONGINT(tagDate));
        FmtTagDict.Add('@Pages@', LONGINT(tagPages));
        FmtTagDict.Add('@PageFF@', LONGINT(tagPageFF));
        FmtTagDict.Add('@Breakpoint@', LONGINT(tagBreakPoint));
        FmtTagDict.Add('@GrayBox@', LONGINT(tagBox));
        FmtTagDict.Add('@HeaderBar@', LONGINT(tagHeaderBar));

        FmtTagDict.Add('@Tab@', LONGINT(tagTab));

        FmtTagDict.Add('@Page@', LONGINT(tagPage));
        FmtTagDict.Add('@Center@', LONGINT(tagCenter));

        FmtTagDict.Add('@fSmall@', LONGINT(tagfSmall));
        FmtTagDict.Add('@fMain@', LONGINT(tagfMain));
        FmtTagDict.Add('@fItalic@', LONGINT(tagfItalic));
        FmtTagDict.Add('@fBold@', LONGINT(tagfBold));
        FmtTagDict.Add('@fBoldItalic@', LONGINT(tagfBold));
        FmtTagDict.Add('@fTable@', LONGINT(tagfTable));
        FmtTagDict.Add('@fHuge@', LONGINT(tagfHuge));
        FmtTagDict.Add('@fHugeItalic@', LONGINT(tagfHugeItalic));
        FmtTagDict.Add('@fMainMedium@', LONGINT(tagfMainMedium));
        FmtTagDict.Add('@fItalicMedium@', LONGINT(tagfItalicMedium));
        FmtTagDict.Add('@fBoldMedium@', LONGINT(tagfBoldMedium));
        FmtTagDict.Add('@fLinePrint@', LONGINT(tagfLinePrint));

        FmtTagDict.Add('@ULB@', LONGINT(tagULineOn));
        FmtTagDict.Add('@ULE@', LONGINT(tagULineOff));
        FmtTagDict.Add('@BLB@', LONGINT(tagBldOn));
        FmtTagDict.Add('@BLE@', LONGINT(tagBldOff));
        FmtTagDict.Add('@ITB@', LONGINT(tagItalOn));
        FmtTagDict.Add('@ITE@', LONGINT(tagItalOff));

        {Commands with arguments}
        FmtTagDict.Add('@PrnGotoXY@', LONGINT(tagPrnGotoXY));
        FmtTagDict.Add('@PrnGotoX@', LONGINT(tagPrnGotoX));
        FmtTagDict.Add('@PrnGotoY@', LONGINT(tagPrnGotoY));
        FmtTagDict.Add('@PrnGotoXYM@', LONGINT(tagPrnGotoXYM));
        FmtTagDict.Add('@PrnGotoXM@', LONGINT(tagPrnGotoXM));
        FmtTagDict.Add('@PrnGotoYM@', LONGINT(tagPrnGotoYM));
        FmtTagDict.Add('@MAT@', LONGINT(tagMAT));
        FmtTagDict.Add('@MessageBox@', LONGINT(tagMessageBox));
        FmtTagDict.Add('@SetLeftMargin@', LONGINT(tagSetLeftMargin));
        FmtTagDict.Add('@SetRightMargin@', LONGINT(tagSetRightMargin));
        FmtTagDict.Add('@SetTopMargin@', LONGINT(tagSetTopMargin));
        FmtTagDict.Add('@SetBotMargin@', LONGINT(tagSetBotMargin));
        FmtTagDict.Add('@endif@', LONGINT(tagEndIf));

        FmtTagDict.Add('@Chapter@', LONGINT(tagChapter));
        FmtTagDict.Add('@TOCEntry@', LONGINT(tagTOCEntry));

        Result := FmtTagDict.GetStatus;

        IF Result <> 0 THEN BEGIN
            DispErrorDeluxe('String dict fail', ErrorMessage(Result), TRUE, Iam);
            FAIL;
        END;

        CenterLine := FALSE;

    END;

    {-------------}

    CONSTRUCTOR Report.InitTOC(LJP : PPrinter; AllowPrint : BOOLEAN; VAR PTOC : SingleListPtr);
    BEGIN
        ChapList := PTOC;
        IF NOT Report.InitPRP(LJP, AllowPrint) THEN
            FAIL;
        PTOC := ChapList;
    END;

    {-------------}

    CONSTRUCTOR Report.Init(PrnInfo : TPrnCfg);
    BEGIN
        PRP := OpenPrinter(PrnInfo, COP, EPrnGraph);
        IF PRP = NIL THEN
            FAIL;

        IF NOT Report.InitPRP(PRP, FALSE) THEN
            FAIL;
    END;

    {-------------}

    DESTRUCTOR Report.Done;
    VAR
        P              : IFP;
        L              : LONGINT;
    BEGIN
        IF PWRAP <> NIL THEN
            DISPOSE(PWRAP, Done);
        PWRAP := NIL;
        {Done with dictionary}
        FmtTagDict.Done;
        RptTagDict.Done;
        P := IFP(IFStack^.PeekTop);
        IF P <> NIL THEN BEGIN
            P^.GetStat(L);
            DispErrorDeluxe('Unmatched @IF@/@ENDIF@ in ' + TemplateName,
                            'Line ' + Long2Str(L),
                            TRUE,
                            Iam);
        END;
        DISPOSE(IFStack, Done);
    END;

    {-------------}

    {initialize an @IFxxx@ context}
    CONSTRUCTOR TIF.Init(TF : BOOLEAN; Line : LONGINT);
    BEGIN
        ROOT.Init;
        MyTF := TF;
        MyLine := Line;
    END;

    {-------------}

    {get the T/F status of this @IFxxx@ context - also return the line}
    {number of the current IF statement}
    FUNCTION TIF.GetStat(VAR Line : LONGINT) : BOOLEAN;
    BEGIN
        Line := MyLine;
        GetStat := MyTF;
    END;

    {-------------}

    {push if statement, flag and line loc on stack to save this context}
    PROCEDURE Report.PushIf(TF : BOOLEAN);
    VAR
        Stat           : WORD;
        P              : IFP;
        PTop           : IFP;
        IFL            : LONGINT;

    BEGIN
        StuffWrap(TRUE);
        PTop := IFP(IFStack^.PeekTop);
        IF PTop <> NIL THEN
            TF := TF AND PTop^.GetStat(IFL);

        NEW(P, Init(TF, TemLineNum));
        IF P = NIL THEN BEGIN
            DispErrorDeluxe('ifobj create fail ' + TemplateName, ErrorMessage(InitStatus), TRUE, Iam);
            HALT(1);
        END;

        IFStack^.PUSH(P);
        Stat := IFStack^.GetStatus;
        IF Stat <> 0 THEN BEGIN
            DispErrorDeluxe('ifstack push fail ' + TemplateName, ErrorMessage(Stat), TRUE, Iam);
            HALT(1);
        END;
    END;

    {-------------}

    {push if statement, flag and line loc on stack to save this context}
    PROCEDURE Report.PushIfNoEmit(TF : BOOLEAN);
    VAR
        Stat           : WORD;
        P              : IFP;
        PTop           : IFP;
        IFL            : LONGINT;

    BEGIN
        StuffWrap(FALSE);
        PTop := IFP(IFStack^.PeekTop);
        IF PTop <> NIL THEN
            TF := TF AND PTop^.GetStat(IFL);

        NEW(P, Init(TF, TemLineNum));
        IF P = NIL THEN BEGIN
            DispErrorDeluxe('ifobj create fail ' + TemplateName, ErrorMessage(InitStatus), TRUE, Iam);
            HALT(1);
        END;

        IFStack^.PUSH(P);
        Stat := IFStack^.GetStatus;
        IF Stat <> 0 THEN BEGIN
            DispErrorDeluxe('ifstack push fail ' + TemplateName, ErrorMessage(Stat), TRUE, Iam);
            HALT(1);
        END;
    END;

    {-------------}

    {pop if statement off stack and toss it (endif hit)}
    {we only care about the topmost stack element flag state}
    PROCEDURE Report.DoEndif;
    VAR
        P              : IFP;
    BEGIN
        P := IFP(IFStack^.Pop);
        IF P = NIL THEN BEGIN
            BadTemLine('IF stack underflow', TRUE, Iam);
            HALT(1);
        END;
        DISPOSE(P, Done);
    END;

    {-------------}

    {check the top stack element to see if we should skip lines of TEM file}
    FUNCTION Report.Skipping : BOOLEAN;
    VAR
        P              : IFP;
        MyIFLine       : LONGINT;
    BEGIN
        Skipping := FALSE;
        P := IFP(IFStack^.PeekTop);
        IF P = NIL THEN           {nothing on stack means no IF statments - don't skip}
            EXIT;
        Skipping := NOT P^.GetStat(MyIFLine); {see if IF statement was FALSE}
    END;

    {-------------}

    {Report text/tag processing}
    PROCEDURE Report.OutputLine(S : STRING);
        {-Add S to end of OutputLine}
    BEGIN
        IF CenterLine THEN BEGIN
            OutLine[0] := CHAR(ColIndex - 1);
            OutLine := OutLine + S;
            INC(ColIndex, LENGTH(S));
        END
        ELSE
            PRP^.PutStr(S);
    END;

    {-------------}

    PROCEDURE Report.WrapDone;
    BEGIN
        IF PWRAP <> NIL THEN
            DISPOSE(PWRAP, Done);
        PWRAP := NIL;
    END;

    {-------------}

    PROCEDURE Report.StuffWrap(EmitFlg : BOOLEAN);
    BEGIN
        IF Skipping THEN BEGIN
            IF (PWRAP <> NIL) AND (NOT PWRAP^.HasWords) THEN
                WrapDone;
            EXIT;
        END;
        IF PWRAP <> NIL THEN BEGIN
            CASE PWRAP^.AddLine(OutLine) OF
                EADDED : ;
                EFAILED,
                EEMITTED :
                    IF EmitFlg THEN
                        WrapDone;
            END;
            OutLine := '';
            ColIndex := 1;
        END;
    END;

    {-------------}

    {output the current line to the printer}
    PROCEDURE Report.EmitLine;
    VAR
        NewPos         : REAL;
    BEGIN
        IF Skipping THEN BEGIN
            IF (PWRAP <> NIL) AND (NOT PWRAP^.HasWords) THEN
                WrapDone;
            EXIT;
        END;

        IF PWRAP <> NIL THEN BEGIN
            CASE PWRAP^.AddLine(OutLine) OF
                EADDED : ;
                EFAILED,
                EEMITTED :
                    WrapDone;
            END;

            OutLine := '';
            ColIndex := 1;
        END
        ELSE BEGIN
            IF ColIndex <> 0 THEN BEGIN
                IF CenterLine THEN
                    PRP^.PutCenteredLine(Trim(OutLine))
                ELSE
                    PRP^.PutLine(OutLine);
            END
            ELSE
                PRP^.LineFeed(NewPos);
            CenterLine := FALSE;
        END;
    END;

    {-------------}

    {get the parameter from the current TEM token}
    FUNCTION Report.GetNextParam(VAR Strg : STRING) : BOOLEAN;
    VAR
        I              : BYTE;
    BEGIN
        GetNextParam := FALSE;
        Strg := '';
        FOR I := LineIndex + 1 TO LENGTH(TemInputLine) DO BEGIN
            IF TemInputLine[I] = '@' THEN BEGIN
                GetNextParam := TRUE;
                BREAK;
            END;
            Strg := Strg + TemInputLine[I];
        END;
        IF Strg <> '' THEN
            INC(LineIndex, LENGTH(Strg) + 1); {move to next param if any}
    END;

    {-------------}

    FUNCTION Report.GetNextReal(VAR R : REAL) : BOOLEAN;
    VAR
        Strg           : STRING;
        Loc            : INTEGER;
    BEGIN
        R := 0.0;
        GetNextReal := FALSE;
        IF NOT GetNextParam(Strg) THEN BEGIN
            BadTemLine('Expecting Real parameter', TRUE, Iam);
            EXIT;
        END;
        VAL(Strg, R, Loc);
        IF Loc <> 0 THEN BEGIN
            BadTemLine('Invalid Real parameter', TRUE, Iam);
            EXIT;
        END;
        GetNextReal := TRUE;
    END;

    {-------------}

    FUNCTION Report.GetNextLong(VAR L : LONGINT) : BOOLEAN;
    VAR
        Strg           : STRING;
        Loc            : INTEGER;
    BEGIN
        L := 0;
        GetNextLong := FALSE;
        IF NOT GetNextParam(Strg) THEN BEGIN
            BadTemLine('Expecting longint parameter', TRUE, Iam);
            EXIT;
        END;
        VAL(Strg, L, Loc);
        IF Loc <> 0 THEN BEGIN
            BadTemLine('Invalid longint parameter', TRUE, Iam);
            EXIT;
        END;
        GetNextLong := TRUE;
    END;

    {-------------}

    FUNCTION Report.PutRaster(FName : PathStr) : BOOLEAN;
    VAR
        BufSize,
        NumRead        : WORD;
        PicFile        : FILE;
        Buff           : PCHAR;
    BEGIN
        FILEMODE := 0;
        ASSIGN(PicFile, FName);
        {$I-}
        RESET(PicFile, 1);
        IF IORESULT <> 0 THEN
            EXIT;
        {$I+}

        IF MAXAVAIL > 10000 THEN
            BufSize := 10000
        ELSE
            BufSize := MAXAVAIL DIV 2;

        GETMEM(Buff, BufSize);

        REPEAT
            BLOCKREAD(PicFile, Buff^, BufSize, NumRead);
            IF COP <> NIL THEN
                COP^.UpDate;
            PRP^.PrnPutBlock(Buff^, NumRead);
        UNTIL NumRead <> BufSize;
        FREEMEM(Buff, BufSize);
        CLOSE(PicFile);
    END;

    {-------------}

    {-Send logo PRN file to printer}
    PROCEDURE Report.PrintRaster;
    VAR
        FName          : PathStr;
    BEGIN
        {read raster file name from template file}
        IF NOT GetNextParam(FName) THEN BEGIN
            BadTemLine('Invalid Raster name', TRUE, Iam);
            EXIT;
        END;
        IF Skipping THEN
            EXIT;
        FName := DefaultExtension(FName, 'LJ');
        PutRaster(FName);
    END;

    {-------------}

    {-Read nn.nn value from TemInputLine and move to that line}
    PROCEDURE Report.PrnGotoXY;
    VAR
        Row,
        Col            : Float;
        S              : STRING;
        CPos           : BYTE;
    BEGIN
        IF NOT GetNextParam(S) THEN BEGIN
            BadTemLine('Invalid params', TRUE, Iam);
            EXIT;
        END;
        IF Skipping THEN
            EXIT;

        CPos := POS(',', S);

        IF CPos = 0 THEN
            EXIT;

        IF NOT Str2Real(COPY(S, 1, CPos - 1), Col) THEN BEGIN
            BadTemLine('Invalid X', TRUE, Iam);
            EXIT;
        END;

        IF NOT Str2Real(COPY(S, CPos + 1, $FF), Row) THEN BEGIN
            BadTemLine('Invalid Y', TRUE, Iam);
            EXIT;
        END;

        PRP^.PrnGotoXY(Col, Row);
    END;

    {-----------}

    {-Read nn.nn value from TemInputLine and move to that line}
    {metric version}
    PROCEDURE Report.PrnGotoXYM;
    VAR
        Row,
        Col            : Float;
        S              : STRING;
        CPos           : BYTE;
    BEGIN
        IF NOT GetNextParam(S) THEN BEGIN
            BadTemLine('Invalid params', TRUE, Iam);
            RingBell;
            EXIT;
        END;
        IF Skipping THEN
            EXIT;

        CPos := POS(',', S);

        IF CPos = 0 THEN
            EXIT;

        IF NOT Str2Real(COPY(S, 1, CPos - 1), Col) THEN BEGIN
            BadTemLine('Invalid X', TRUE, Iam);
            EXIT;
        END;

        IF NOT Str2Real(COPY(S, CPos + 1, $FF), Row) THEN BEGIN
            BadTemLine('Invalid X', TRUE, Iam);
            RingBell;
            EXIT;
        END;

        PRP^.PrnGotoXY(Col * InchPerMM, Row * InchPerMM);
    END;

    {-----------}

    {-Read nn.nn value from TemInputLine and move to that line}
    PROCEDURE Report.PrnGotoY;
    VAR
        Row            : Float;
        S              : STRING;
    BEGIN
        IF NOT GetNextParam(S) THEN BEGIN
            BadTemLine('Invalid y', TRUE, Iam);
            EXIT;
        END;
        IF Skipping THEN
            EXIT;
        IF Str2Real(S, Row) THEN
            PRP^.PrnGotoY(Row);
    END;

    {-----------}

    {-Read nn.nn value from TemInputLine and move to that line}
    {Metric version}
    PROCEDURE Report.PrnGotoYM;
    VAR
        Row            : Float;
        S              : STRING;
    BEGIN
        IF NOT GetNextParam(S) THEN
            EXIT;
        IF Skipping THEN
            EXIT;
        IF Str2Real(S, Row) THEN
            PRP^.PrnGotoY(Row * InchPerMM);
    END;

    {-----------}

    {-Read nn.nn value from TemInputLine and move to that column}
    PROCEDURE Report.PrnGotoX;
    VAR
        Col            : Float;
        S              : STRING;
    BEGIN
        IF NOT GetNextParam(S) THEN
            EXIT;
        IF Skipping THEN
            EXIT;
        IF Str2Real(S, Col) THEN
            PRP^.PrnGotoX(Col);
    END;

    {-----------}

    {-Read nn.nn value from TemInputLine and move to that column}
    {Metric version}
    PROCEDURE Report.PrnGotoXM;
    VAR
        Col            : Float;
        S              : STRING;
    BEGIN
        IF NOT GetNextParam(S) THEN
            EXIT;
        IF Skipping THEN
            EXIT;
        IF Str2Real(S, Col) THEN
            PRP^.PrnGotoX(Col * InchPerMM);
    END;

    {-----------}

    PROCEDURE Report.DrawBox;
        {-Read Wnn.nn, Hnn.nn value from TemInputLine and draw box}
    VAR
        C              : CHAR;
        CommaLoc       : BYTE;
        SNext          : BYTE;
        GrayScale,
        Width,
        Height         : Float;
        S              : STRING;
    BEGIN
        IF NOT GetNextParam(S) THEN
            EXIT;
        IF Skipping THEN
            EXIT;

        {Extract wid,hgt from nn.nn,nn.nn}
        CommaLoc := POS(',', S);
        IF CommaLoc = 0 THEN
            EXIT;

        IF Str2Real(COPY(S, 1, CommaLoc - 1), Width) AND
        Str2Real(COPY(S, CommaLoc + 1, 255), Height) THEN BEGIN
            IF PRP^.GetCanBox THEN
                GrayScale := 10.0
            ELSE
                GrayScale := 10.0;

            PRP^.DrawRasterBox(PRP^.CurColumn,
                               PRP^.CurRow,
                               FALSE,
                               FALSE,
                               GrayScale,
                               Height,
                               Width)
        END
        ELSE
            RingBell;
    END;

    {-----------}

    FUNCTION Report.FormatDate(D : Date) : STRING;
    VAR
        S              : STRING[20];
    BEGIN
        IF MyJanuaryMsg = 0 THEN BEGIN {english is default}
            S := Trim(DateToDateString('nnnnnnnnn', D));
            FormatDate := S + ' ' + Trim(DateToDateString('DD, yyyy', D));
        END
        ELSE                      {foreign lang support is on}
            FormatDate := LongDate(MyJanuaryMsg, D);
    END;

    {-------------}

    {-Returns a formatted string with digits from L merged into the Mask}
    FUNCTION Report.LongIntFormS(Mask : STRING; L : LONGINT) : STRING;
    VAR
        S              : STRING[20];
    BEGIN
        S := LongIntForm(Mask, L);
        IF Trim(S) = '0' THEN
            S := '0%'
        ELSE
            S := S + '%';
        LongIntFormS := S;
    END;

    {-------------}

    FUNCTION Report.ProcessTag(Token : FmtTokensT) : BOOLEAN;
    VAR
        S              : STRING;
    BEGIN
        ProcessTag := FALSE;

        IF COP <> NIL THEN
            COP^.UpDate;

        IF Skipping THEN BEGIN
            ProcessTag := TRUE;
            EXIT;
        END;

        CASE Token OF
            tagHeaderBar :
                DoHeaderBar;
            tagRaster :
                PrintRaster;
            tagDate :
                BEGIN
                    {$IFDEF DEBUG}
                    OutputLine(FormatDate(Today) + ' ' + CurrentTimeString('hh:mm:ss'));
                    {$ELSE}
                    OutputLine(FormatDate(Today));
                    {$ENDIF}
                END;
            tagPages :
                OutputLine(Long2Str(PRP^.GetPageNum));
            tagLetterHead :
                PRP^.SelectTrayDeluxe(ELetterhead);
            tagBlankPaper :
                PRP^.SelectTrayDeluxe(EBlank);
            tagBreakPoint :
                RingBell;
            tagPage :
                PRP^.FormFeed;
            tagPageFF :
                DoPageNumAndFF;
            tagCenter :
                CenterLine := TRUE;
            tagfSmall :
                PRP^.SelectFont(fSmall);
            tagfMain :
                PRP^.SelectFont(fMain);
            tagfItalic :
                PRP^.SelectFont(fItalic);
            tagfBold :
                PRP^.SelectFont(fBold);
            tagfBoldItalic :
                PRP^.SelectFont(fBoldItalic);
            tagfTable :
                PRP^.SelectFont(fTable);
            tagfHuge :
                PRP^.SelectFont(fHuge);
            tagfHugeItalic :
                PRP^.SelectFont(fHugeItalic);
            tagfMainMedium :
                PRP^.SelectFont(fMainMedium);
            tagfItalicMedium :
                PRP^.SelectFont(fItalicMedium);
            tagfBoldMedium :
                PRP^.SelectFont(fBoldMedium);
            tagfLinePrint :
                PRP^.SelectFont(fLinePrint);
            tagBldOn :
                ConcatOutLine(PRP^.GetModeStr(EBOLDON));
            tagBldOff :
                ConcatOutLine(PRP^.GetModeStr(EBOLDOFF));
            tagULineOn :
                ConcatOutLine(PRP^.GetModeStr(EULON));
            tagULineOff :
                ConcatOutLine(PRP^.GetModeStr(EULOFF));
            tagItalOn :
                ConcatOutLine(PRP^.GetModeStr(EITALON));
            tagItalOff :
                ConcatOutLine(PRP^.GetModeStr(EITALOFF));
            tagPrnGotoXY :
                PrnGotoXY;
            tagPrnGotoX :
                PrnGotoX;
            tagPrnGotoY :
                PrnGotoY;
            tagPrnGotoXYM :
                PrnGotoXYM;
            tagPrnGotoXM :
                PrnGotoXM;
            tagPrnGotoYM :
                PrnGotoYM;
            tagBox :
                DrawBox;
            tagMessageBox :
                PrnMessageBox;
            tagSetLeftMargin :
                SetLeftMargin;
            tagSetRightMargin :
                SetRightMargin;
            tagSetTopMargin :
                SetTopMargin;
            tagSetBotMargin :
                SetBotMargin;
            tagChapter :
                AddChapter;
            tagTOCEntry :
                AddTOCEntry;
            ELSE
                BadTemLine('Unknown Tag', TRUE, Iam);
        END;
    END;

    {-----------}

    FUNCTION Report.ProcessLine : BOOLEAN;
    CONST
        MaxTagLen      = 40;
    VAR
        CommandOnly    : BOOLEAN;
        CollectingTag  : BOOLEAN;
        Finished       : BOOLEAN;
        GotText        : BOOLEAN;
        TabPos         : BYTE;
        C              : CHAR;
        Next           : WORD;
        Code           : WORD;
        T              : LONGINT;
        Tag            : STRING[MaxTagLen];
        Sub            : STRING;
        TabCol         : STRING[4];

        FUNCTION InitWrapper(J : JustT) : BOOLEAN;
        BEGIN
            InitWrapper := FALSE;
            {if no tag chars on line and skipping then quit parsing line}
            {to save time                                               }
            IF {(NOT(POS(TagChar, TemInputLine) > 0)) AND} Skipping THEN
                EXIT;
            IF PWRAP <> NIL THEN BEGIN
                PWRAP^.Process;
                DISPOSE(PWRAP, Done);
            END;
            NEW(PWRAP, Init(PRP, J));
            IF PWRAP = NIL THEN BEGIN
                DispErrorDeluxe('Error initializing PWrap', ErrorMessage(InitStatus), TRUE, Iam);
                EXIT;
            END;
            DELETE(TemInputLine, 1, 2);
            InitWrapper := TRUE;
        END;
    BEGIN
        ProcessLine := FALSE;
        CollectingTag := FALSE;
        OutLine := '';
        ColIndex := 1;
        GotText := FALSE;
        LineIndex := 1;

        {check for the various types of paragraph wrapping}
        IF POS(LJustWrap, TemInputLine) = 1 THEN
            IF NOT InitWrapper(ELEFT) THEN
                EXIT;

        IF POS(LRJustWrap, TemInputLine) = 1 THEN
            IF NOT InitWrapper(ELEFTRIGHT) THEN
                EXIT;

        IF POS(LRJustInWrap, TemInputLine) = 1 THEN
            IF NOT InitWrapper(ELEFTRIGHTINDENT) THEN
                EXIT;

        IF POS(RJustWrap, TemInputLine) = 1 THEN
            IF NOT InitWrapper(ERIGHT) THEN
                EXIT;

        IF POS(CJustWrap, TemInputLine) = 1 THEN
            IF NOT InitWrapper(ECENTER) THEN
                EXIT;

        {is this a remark line?}
        IF POS(RemToken, TemInputLine) = 1 THEN BEGIN
            ProcessLine := TRUE;
            EXIT;
        END;

        {scan the line and parse it}
        WHILE LineIndex <= LENGTH(TemInputLine) DO BEGIN
            C := TemInputLine[LineIndex];

            IF CollectingTag THEN BEGIN
                Tag[Next] := C;
                INC(Next);
                IF Next > MaxTagLen THEN BEGIN
                    BadTemLine('Line length overflow!', TRUE, Iam);
                    EXIT;
                END;
            END;

            IF C = TagChar THEN BEGIN
                CollectingTag := NOT CollectingTag;
                IF NOT CollectingTag THEN BEGIN
                    {Got a token, look it up and process it}
                    Tag[0] := CHAR(Next - 1);
                    IF FmtTagDict.Member(Tag, T) THEN
                        IF FmtTokensT(T) = tagEndIf THEN
                            DoEndif
                        ELSE
                            {was a format tag, so send it to parent for parsing}
                            ProcessTag(FmtTokensT(T))
                    ELSE BEGIN
                        IF RptTagDict.Member(Tag, T) THEN BEGIN
                            {was a report tag, so process it locally}
                            IF NOT ProcessUserTag(T) THEN BEGIN
                                BadTemLine('Unknown tag: ' + Tag, TRUE, Iam);
                                HALT(1);
                            END;
                        END
                        ELSE
                            BadTemLine('Unknown tag: ' + Tag, TRUE, Iam);
                    END;
                END
                ELSE BEGIN
                    {First char in tag, start collecting}
                    Tag[1] := TagChar;
                    Next := 2;
                END;
            END;

            IF NOT CollectingTag AND (C <> '@') AND NOT Skipping THEN BEGIN
                OutLine[ColIndex] := C;
                OutLine[0] := CHAR(ColIndex);
                INC(ColIndex);
                IF ColIndex > 255 THEN BEGIN
                    BadTemLine('Outline overflow', TRUE, Iam);
                    HALT(1);
                END;

                GotText := TRUE;
            END;

            INC(LineIndex);
        END;

        {Set CommandOnly if line had just a command on it}
        CommandOnly := (ColIndex = 1) AND
                       (Trim(TemInputLine) <> '') AND
                       NOT GotText
                       OR Skipping;

        IF NOT CommandOnly THEN
            EmitLine;

        ProcessLine := TRUE;
    END;

    {-----------}

    FUNCTION Report.OpenTemFile : BOOLEAN;
    BEGIN
        OpenTemFile := FALSE;
        ASSIGN(Template, TemplateName);
        {$I-}
        RESET(Template);
        {$I+}
        Result := IORESULT;
        IF Result <> 0 THEN BEGIN
            DispErrorDeluxe(' Unable to open template file: ' + TemplateName,
                            ErrorMessage(Result),
                            TRUE,
                            Iam);
            EXIT;
        END;
        OpenTemFile := TRUE;
    END;

    {-------------}

    PROCEDURE Report.CloseTemFile;
    BEGIN
        CLOSE(Template);
    END;

    {-------------}

    FUNCTION Report.ReadTemLine : BOOLEAN;
    BEGIN
        {Get next line from template}
        {$I-}
        READLN(Template, TemInputLine);
        {$I+}
        ReadTemLine := EOF(Template);
    END;

    {-------------}

    PROCEDURE Report.Process;
    VAR
        C              : CHAR;
        IfLevel        : WORD;
        AllDone        : BOOLEAN;
    BEGIN
        PRP^.InitJob;

        IF NOT OpenTemFile THEN
            EXIT;

        {Process all lines in template file}
        HiddenCursor;
        TemLineNum := 0;
        REPEAT
            {Check for abort request}
            IF KeyPressed THEN BEGIN
                C := ReadKey;
                CASE C OF
                    #0 :
                        C := ReadKey;
                    #27 :
                        BEGIN
                            DispErrorDeluxe('User abort', '', FALSE, Iam);
                            InitStatus := ecUserAbort;
                            BREAK;
                        END;
                END;
            END;

            AllDone := ReadTemLine;

            Result := IORESULT;
            IF Result <> 0 THEN
                DispErrorDeluxe('Can''t read', TemplateName, TRUE, Iam);
            INC(TemLineNum);
            ProcessLine;
            {$IFDEF DEBUG}
            IFLevel := IfStack^.SP;
            {$ENDIF}
        UNTIL AllDone;
        CloseTemFile;
    END;

    {-----------}

    PROCEDURE Report.PrnMessageBox;
    BEGIN
    END;

    {-----------}

    PROCEDURE Report.SetLeftMargin;
    VAR
        Strg           : STRING;
        R              : Float;
    BEGIN
        IF NOT GetNextParam(Strg) THEN
            EXIT;
        IF Skipping THEN
            EXIT;
        IF NOT Str2Real(Strg, R) THEN
            EXIT;
        PRP^.SetLeftMargin(R);
    END;

    {-----------}

    PROCEDURE Report.SetRightMargin;
    VAR
        Strg           : STRING;
        R              : Float;
    BEGIN
        IF NOT GetNextParam(Strg) THEN
            EXIT;
        IF Skipping THEN
            EXIT;
        IF NOT Str2Real(Strg, R) THEN
            EXIT;
        PRP^.SetRightMargin(R);
    END;

    {-----------}

    PROCEDURE Report.SetTopMargin;
    VAR
        Strg           : STRING;
        R              : Float;
    BEGIN
        IF NOT GetNextParam(Strg) THEN
            EXIT;
        IF Skipping THEN
            EXIT;
        IF NOT Str2Real(Strg, R) THEN
            EXIT;
        PRP^.SetTopMargin(R);
    END;

    {-----------}

    PROCEDURE Report.SetBotMargin;
    VAR
        Strg           : STRING;
        R              : Float;
    BEGIN
        IF NOT GetNextParam(Strg) THEN
            EXIT;
        IF Skipping THEN
            EXIT;
        IF NOT Str2Real(Strg, R) THEN
            EXIT;
        PRP^.SetBottomMargin(R);
    END;

    {-----------}

    PROCEDURE Report.OutputCenteredLine(S : STRING);
    BEGIN
        PRP^.PutCenteredLine(Trim(S))
    END;

    {-----------}

    PROCEDURE Report.LineFeed;
    VAR
        P              : REAL;
    BEGIN
        PRP^.LineFeed(P);
    END;

    {-----------}

    PROCEDURE Report.ConcatOutLine(S : STRING);
    BEGIN
        (*
        IF (LENGTH(S) + LENGTH(OutLine)) > 255 THEN BEGIN
            EmitLine;
            DispErrorDeluxe('Outline Overflow', COPY(S, 1, 40), TRUE, Iam);
        END;
        *)
        IF (LENGTH(S) + LENGTH(OutLine)) > 255 THEN
            StuffWrap(TRUE);
        OutLine := OutLine + S;
        ColIndex := LENGTH(OutLine) + 1;
    END;

    {-----------}

    PROCEDURE Report.Putoutline(Strg : STRING);
    BEGIN
        ConcatOutLine(Strg);
        EmitLine;
        OutLine := '';
    END;

    {-----------}

    PROCEDURE Report.DoHeaderBar;
    BEGIN
        DispErrorDeluxe('Abstract DoHeaderBar!', TemplateName, TRUE, Iam);
    END;

    {-----------}

    FUNCTION Report.ProcessUserTag(Tag : LONGINT) : BOOLEAN;
    BEGIN
        DispErrorDeluxe('Abstract ProcessUserTag!', '', TRUE, Iam);
        HALT(1);
    END;

    {-----------}

    {generic error message for TEM syntax errors}
    PROCEDURE Report.BadTemLine(Msg : STRING; LogIt : BOOLEAN; Where : POINTER);
    BEGIN
        DispErrorDeluxe(Msg, TemplateName + ' Line ' + Long2Str(TemLineNum), LogIt, Where);
    END;

    {-----------}

    FUNCTION Report.GetPgNum : WORD;
    BEGIN
        GetPgNum := PRP^.GetPageNum;
    END;

    {-----------}

    FUNCTION Report.LoadCharTable(XLCName : PathStr) : BOOLEAN;
    BEGIN
        LoadCharTable := PRP^.LoadCharTable(XLCName);
    END;

    {-----------}

    PROCEDURE Report.SetJanuaryMsgNum(J : WORD);
    BEGIN
        MyJanuaryMsg := J;
    END;

    {-----------}

    {you need to override this if you don't want a centered page number}
    PROCEDURE Report.DoPageNumAndFF;
    VAR
        CurFont        : PFont;
    BEGIN
        {save the current font}
        CurFont := PRP^.ljActiveFont;
        {switch to fMain font}
        PRP^.SelectFont(fMain);
        {move to the bottom margin}
        PRP^.PrnGotoY(PRP^.GetBottomMargin + 0.25);
        {center the page number}
        PRP^.PutCenteredLine(PRP^.GetPageLabel + Long2Str(PRP^.GetPageNum));
        {increment the page number}
        PRP^.SetPageNum(PRP^.GetPageNum + 1);
        {pagefeed}
        PRP^.FormFeed;
        {switch back to the old font}
        PRP^.ljActiveFont := CurFont;
        {home to upper left}
        PRP^.PrnGotoXY(PRP^.GetLeftMargin, PRP^.GetTopMargin);
    END;

    {-----------------}

    PROCEDURE Report.AddChapter;
    VAR
        CP             : PChapObj;
        Chap           : TChapRec;
    BEGIN
        IF NOT GetNextParam(Chap.Name) THEN
            EXIT;
        IF NOT GetNextLong(Chap.ChapNum) THEN
            EXIT;
        Chap.PG := PRP^.GetPageNum;
        NEW(CP, Init(Chap));
        ChapList^.APPEND(CP);
    END;

    {----------}

    PROCEDURE Report.AddTOCEntry;
    VAR
        CP             : PChapObj;
        Chap           : TChapRec;
        TOC            : TTOCRec;
    BEGIN

        IF NOT GetNextParam(TOC.TOCEntry) THEN
            EXIT;
        TOC.PG := PRP^.GetPageNum;
        CP := PChapObj(ChapList^.Tail);
        IF CP = NIL THEN BEGIN
            Chap.Name := 'Chapter 1';
            Chap.ChapNum := 1;
            Chap.PG := PRP^.GetPageNum;
            NEW(CP, Init(Chap));
            ChapList^.APPEND(CP);
        END;
        CP^.AppendTOC(TOC);
    END;

    {----------}


    CONSTRUCTOR TChapObj.Init(VAR C : TChapRec);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        MyChapRec := C;
        IF NOT MyTOCList.Init THEN
            FAIL;
    END;

    {----------}

    DESTRUCTOR TChapObj.Done;
    BEGIN
        MyTOCList.Done;
    END;

    {----------}

    FUNCTION TChapObj.AppendTOC(T : TTOCRec) : BOOLEAN;
    VAR
        Pt             : PTOCObj;
    BEGIN
        AppendTOC := FALSE;
        NEW(Pt, Init(T));
        IF Pt = NIL THEN
            EXIT;
        MyTOCList.APPEND(Pt);
        AppendTOC := TRUE;
    END;

    {----------}

    PROCEDURE TChapObj.GetChapRec(VAR C : TChapRec);
    BEGIN
        C := MyChapRec;
    END;

    {----------}

    FUNCTION TChapObj.GetTOCCount : LONGINT;
    BEGIN
        GetTOCCount := MyTOCList.Size;
    END;

    {----------}

    FUNCTION TChapObj.GetNthTOC(N : LONGINT; VAR T : TTOCRec) : BOOLEAN;
    VAR
        Pt             : PTOCObj;
    BEGIN
        GetNthTOC := FALSE;
        Pt := PTOCObj(MyTOCList.Nth(N));
        IF Pt = NIL THEN
            EXIT;
        Pt^.GetTOCRec(T);
        GetNthTOC := TRUE;
    END;

    {----------}

    FUNCTION TChapObj.GetChapName : STRING;
    BEGIN
        GetChapName := MyChapRec.Name;
    END;

    {----------}

    FUNCTION TChapObj.GetChapNum : LONGINT;
    BEGIN
        GetChapNum := MyChapRec.ChapNum;
    END;

    {----------}

    FUNCTION TChapObj.GetChapPage : LONGINT;
    BEGIN
        GetChapPage := MyChapRec.PG;
    END;

    {----------}

    CONSTRUCTOR TTOCObj.Init(VAR T : TTOCRec);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        MyTOCRec := T;
    END;

    {----------}

    PROCEDURE TTOCObj.GetTOCRec(VAR T : TTOCRec);
    BEGIN
        T := MyTOCRec;
    END;

    {----------}

    FUNCTION TTOCObj.GetTOCEntry : STRING;
    BEGIN
        GetTOCEntry := MyTOCRec.TOCEntry;
    END;

    {----------}

    FUNCTION TTOCObj.GetTOCPage : LONGINT;
    BEGIN
        GetTOCPage := MyTOCRec.PG;
    END;

    {----------}

    FUNCTION Report.GetChapterCount : LONGINT;
    BEGIN
        GetChapterCount := ChapList^.Size;
    END;

    {----------}

    FUNCTION Report.GetTOCCountForChapter(ChapterNum : WORD) : LONGINT;
    VAR
        CP             : PChapObj;
    BEGIN
        GetTOCCountForChapter := 0;
        CP := PChapObj(ChapList^.Nth(ChapterNum));
        IF CP = NIL THEN
            EXIT;
        GetTOCCountForChapter := CP^.GetTOCCount;
    END;

    {----------}

    FUNCTION Report.GetNthChapter(N : WORD; VAR C : TChapRec; VAR TOCCount : LONGINT) : BOOLEAN;
    VAR
        CP             : PChapObj;
    BEGIN
        GetNthChapter := FALSE;
        FILLCHAR(C, SIZEOF(C), #0);
        CP := PChapObj(ChapList^.Nth(N));
        IF CP = NIL THEN
            EXIT;
        CP^.GetChapRec(C);
        TOCCount := CP^.GetTOCCount;
    END;

    {----------}

    FUNCTION Report.GetTOCEntry(ChapterNum, TOCNum : WORD; VAR T : TTOCRec) : BOOLEAN;
    VAR
        CP             : PChapObj;
    BEGIN
        GetTOCEntry := FALSE;
        FILLCHAR(T, SIZEOF(T), #0);
        CP := PChapObj(ChapList^.Nth(ChapterNum));
        IF CP = NIL THEN
            EXIT;
        IF NOT CP^.GetNthTOC(TOCNum, T) THEN
            EXIT;
        GetTOCEntry := TRUE;
    END;

    {----------}

BEGIN
    wStack.Init(100);
END.
