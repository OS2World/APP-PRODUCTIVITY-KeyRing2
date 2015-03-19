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
* Welcome to pointer junction!  The first half of this unit implements a
* huge string object.  This object gives us somewhat familiar Pascal strings
* only with a maximum length of approx 65500 chars.  Unlike ASCIIZ strings,
* huge strings can contain NULL characters.  Please feel free to derive
* new methods for the HsObj or patch in new methods directly.  The HsObj
* is itself derived from singlelistnode, so you can build lists of them if
* necessary.
*
* The last half of this unit contains methods for parsing printer.ini files
* and the primative methods for implementing a queue picker.
*
* This unit introduces the concept of printer attributes.  Attributes are
* named blocks of binary data used to put the printer into a specific mode
* or font.  The contents of an attribute are tagged with a name and an easy
* to use "token".  When you wish to change a printer mode, use one of the
* attribute selection methods to look up and print the attribute data.  If
* the printer you are using does not support the attribute you are trying to
* use, nothing will be sent to the printer.
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F+,G+,I+,L+,N-,O+,P-,Q+,T-,V-,X+,Y+}
UNIT UTPRINT;
{$I NDEFINE.INC}
INTERFACE

USES
    Dos,
    {KEPSON9,
    KEPSON24,
    KHP150,
    KHP300,}
    UTNETPRN,
    OoFaxPrn,
    OpCrt,
    OpCtrl,
    OpPick,
    OpPrnLow,
    OpRoot,
    OpString,
    OpWindow,
    UDIALOG;
TYPE
    TParseMode     = (THEX, TASCII, TDECI, TBAD);
    TKPrintMode    = (Script, Queue, Other);
    TFileType      = (PLAINTXT, FAX);
    THPRes         = (E150, E300, EBAD);
    TPrtType       = (ETEXT,
                      ESENDFAX,
                      EEPSON9,
                      EEPSON24,
                      EPCL4,
                      EPCL5,
                      EPRTBAD);

CONST
    MAXATRIBNAME   = 4;           {attribute name length}
    MAXNAMELEN     = 20;
    ParseModeLUT   : ARRAY[THEX..TBAD] OF STRING[7] =
    ('HEX',
     'ASCII',
     'DECIMAL',
     'BAD');
    PrtTypeLUT     : ARRAY[ETEXT..EPRTBAD] OF STRING[14] =
    { 1234567890123456789}
    ('TEXT',
     'SENDFAX',
     'FAXPRT_EPSON9',
     'FAXPRT_EPSON24',
     'FAXPRT_PCL4',
     'FAXPRT_PCL5',
     'BADBAD');

    PLPrtTypeLUT   : ARRAY[ETEXT..EPRTBAD] OF STRING[7] =
    { 1234567890123456789}
    ('TEXT',
     'SENDFAX',
     'FAXPRT',
     'FAXPRT',
     'FAXPRT',
     'FAXPRT',
     'BADBAD');
TYPE
    PRTRETVAL      = (Timeout, OFFLINE, NOPAPER, PRTERR, ABORT, PRTOK);

    PrtFunc        = FUNCTION : PRTRETVAL;

    {for each additional or deleted format here, you must make a corresponding}
    {change  in TokenLUT below}
    FMTTOKEN       = (
              SOL,
              EOL,
              TOP,
              TOS,
              TOT,
              SOQ,
              SOS,
              EOJ,
              NORM,
              BOLD,
              ITAL,
              Wide,
              ULB,
              ULE,
              RSL,
              REL,
              HSL,
              HEL,
              FM1,
              FM2,
              FM3,
              FM4,
              FM5,
              FM6,
              BADF);
CONST
    TokenLUT       : ARRAY[SOL..BADF] OF STRING[MAXATRIBNAME] =
    {    1234567890}
    (
        'SOL',
        'EOL',
        'TOP',
        'TOS',
        'TOT',
        'SOQ',
        'SOS',
        'EOJ',
        'NORM',
        'BOLD',
        'ITAL',
        'WIDE',
        'ULB',
        'ULE',
        'RSL',
        'REL',
        'HSL',
        'HEL',
        'FM1',
        'FM2',
        'FM3',
        'FM4',
        'FM5',
        'FM6',
        'BAD');

TYPE
    {HugeStrs are public}
    HugeStrPtr     = ^HugeStr;
    HugeStr        = RECORD
                         Len,
                         MaxLen         : WORD; {used by FREEMEM}
                         Strg           : PCHAR; {PCHAR for debugger convienience only}
                     END;

    {Generic HugeString handler object - public}
    HsObjPtr       = ^HsObj;
    HsObj          = OBJECT(SingleListNode)
                         Hs             : HugeStrPtr;

                         CONSTRUCTOR Init(Siz : WORD);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION HStrCat(THS : HugeStrPtr) : BOOLEAN;
                         FUNCTION HRealloc(Siz : WORD) : BOOLEAN;
                         FUNCTION GetHs : HugeStrPtr;
                         PROCEDURE HDispose(THS : HugeStrPtr);
                         PROCEDURE HClear;

                {PRIVATE

                Hs : HugeStrPtr;}
                     END;

    {Parse various formats into a hugestr - Public}
    HsParsePtr     = ^HsParse;
    HsParse        = OBJECT(HsObj)
                         CONSTRUCTOR Init;
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION Parse(Strg : STRING; Mode : TParseMode) : BOOLEAN;

                         PRIVATE

                         FUNCTION HexParse(Strg : STRING) : BOOLEAN;
                         FUNCTION ASCIIParse(Strg : STRING) : BOOLEAN;
                         FUNCTION DECIParse(Strg : STRING) : BOOLEAN;
                     END;

    {An object to hold one printer font attribute - UNIT PRIVATE }
    AttribObjPtr   = ^AttribObj;

    AttribObj      = OBJECT(HsParse)
                         PRIVATE

                         Name           : STRING[MAXATRIBNAME];
                         Tok            : FMTTOKEN;

                         CONSTRUCTOR Init(AName : STRING; T : FMTTOKEN);
                         DESTRUCTOR Done; VIRTUAL;

                         FUNCTION GetName : STRING;
                         FUNCTION GetTok : FMTTOKEN;
                         FUNCTION GetAttr : HugeStrPtr;
                     END;

    {An attriblist makes it somewhat easier to access the nodes in the list}
    {- UNIT PRIVATE }
    AttribList     = OBJECT(SingleList)
                         PRIVATE
                         CarriageWidth,
                         NormpageLen,
                         ScriptPageLen,
                         QueueStartPos,
                         ScriptStartPos : WORD;

                         CONSTRUCTOR Init(IName : PathStr);
                         FUNCTION GetName(I : WORD) : STRING;
                         FUNCTION GetTok(I : WORD) : FMTTOKEN;
                         FUNCTION GetAttr(I : WORD) : HugeStrPtr;
                         FUNCTION SearchSAttr(AName : STRING) : HugeStrPtr;
                         FUNCTION SearchAttr(F : FMTTOKEN) : HugeStrPtr;
                         FUNCTION GetPageLen(Mode : TKPrintMode) : WORD;
                         FUNCTION GetLeftMargin(Mode : TKPrintMode) : WORD;
                     END;

    {A quenode contains the information about one printer queue, including}
    {a list of possible font attributes and methods for accessing the info}
    {- UNIT PRIVATE }
    QueueNodePtr   = ^QueueNode;
    QueueNode      = OBJECT(SingleListNode)

                         PRIVATE

                         HpResolution   : THPRes;
                         PrtType        : TPrtType;
                         MyNumber,
                         Copies         : WORD;
                         Al             : AttribList;
                         Picked         : BOOLEAN;
                         PName,
                         Sname,
                         QName,
                         IName          : STRING[MAXNAMELEN];
                         QID            : LONGINT;

                         CONSTRUCTOR Init(VAR Name,
                                          Server,
                                          Queue,
                                          IniName        : STRING;
                                          Mn             : WORD;
                                          PrinterType    : STRING;
                                          HpRes          : WORD);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE ADump;
                         FUNCTION GetName : STRING;
                         FUNCTION GetServer : STRING;
                         FUNCTION GetQueue : STRING;
                         FUNCTION GetIName : STRING;
                         FUNCTION GetMyNumber : WORD;
                         PROCEDURE Pick(Flg : BOOLEAN);
                         PROCEDURE SetCopies(C : WORD);
                         FUNCTION GetCopies : WORD;
                         FUNCTION IsPicked : BOOLEAN;

                             {parse printer.ini file}
                         FUNCTION AAdd(Name : PathStr) : BOOLEAN;
                         FUNCTION AGetName(A : WORD) : STRING;
                         FUNCTION AGetTok(A : WORD) : FMTTOKEN;
                         FUNCTION AGetAttr(A : WORD) : HugeStrPtr;
                         FUNCTION ASearchSAttr(AName : STRING) : HugeStrPtr;
                         FUNCTION ASearchAttr(F : FMTTOKEN) : HugeStrPtr;
                         FUNCTION GetQid : LONGINT;
                         FUNCTION GetPageLen(Mode : TKPrintMode) : WORD;
                         FUNCTION GetLeftMargin(Mode : TKPrintMode) : WORD;
                         FUNCTION AttachToServer : BOOLEAN;
                         FUNCTION ReleaseServer : BOOLEAN;
                         FUNCTION GetPrtType : TPrtType;
                         FUNCTION GetHPRes : THPRes;
                     END;


    {A Queuelist makes it somewhat easier to access the nodes in the list}
    {Queuelist nodes contain knowledge of a single printer queue, and a list}
    {of all possible printer format strings.}

    {This is the public entry point to the queuelist object}
    {- PUBLIC}
    SelectMode     = (PICKBYPOS, PICKBYPRTNUM);
    QueueListPtr   = ^QueueList;
    QueueList      = OBJECT(SingleList)

                         {load and parse nenprint.ini}
                         CONSTRUCTOR Init(IniName : PathStr; Mode : TKPrintMode);

                         {load and parse nenprint.ini - also set up Cylon}
                         CONSTRUCTOR InitDeluxe(IniName : PathStr; Mode : TKPrintMode; MyCOP : CylonObjPtr);

                             {load and parse nenprint.ini - also set up Cylon.}
                             {This one only parses the printer numbers found  }
                             {in Strg.  Dont use this one for picklist printer}
                             {selectors                                       }
                         CONSTRUCTOR InitDumbDeluxe(IniName        : PathStr;
                                                    Mode           : TKPrintMode;
                                                    MyCOP          : CylonObjPtr;
                                                    Strg           : STRING);

                             {load and parse nenprint.ini - also set up Cylon.}
                             {This one only parses the printer numbers found  }
                             {in Strg.  This one fires up the picklist        }
                             {automatically                                   }
                         CONSTRUCTOR InitPickDeluxe(IniName        : PathStr;
                                                    Mode           : TKPrintMode);

                             {blow off lists and shut down}
                         DESTRUCTOR Done; VIRTUAL;

                             {do command line parse}
                         FUNCTION DumbSelect(Strg : STRING) : BOOLEAN;

                             {used by itemstr}
                         FUNCTION ShowStr(Q : WORD) : STRING; VIRTUAL;

                             {Tag que node as selected/deselected}
                         PROCEDURE Pick(Q : WORD; Flg : BOOLEAN; Mode : SelectMode);

                             {check tag status}
                         FUNCTION IsPicked(Q : WORD; Mode : SelectMode) : BOOLEAN;

                             {Loads attributes for queue}
                         FUNCTION LoadAttr(Q : WORD; Mode : SelectMode) : BOOLEAN;

                             {Loads attributes for queue}
                         PROCEDURE UnLoadAttr(Q : WORD; Mode : SelectMode);

                             {Begin capture}
                         FUNCTION Capture(Q : WORD) : BOOLEAN;

                             {End Capture}
                         FUNCTION EndCap(Q : WORD) : BOOLEAN;

                             {Send attrib string to queue}
                         FUNCTION SendAttr(Q : WORD; F : FMTTOKEN) : BOOLEAN;

                             {Send attrib string to queue}
                         FUNCTION SendSAttr(Q : WORD; Strg : STRING) : BOOLEAN;

                             {Set number of printout copies}
                         PROCEDURE SetCopies(Q : WORD; C : WORD; Mode : SelectMode);

                             {Get number of printout copies for queue}
                         FUNCTION GetCopies(Q : WORD) : WORD;

                             {Get Attr string for queue/attr}
                         FUNCTION GetAttr(Q : WORD; F : FMTTOKEN) : HugeStrPtr;

                             {Get Attr string for queue/attr}
                         FUNCTION GetSAttr(Q : WORD; F : STRING) : HugeStrPtr;

                             {write a CR/LF delimited string to the capture queue}
                         FUNCTION QWRITELN(Strg : STRING) : BOOLEAN;

                             {write string to the capture queue}
                         FUNCTION QWRITE(Strg : STRING) : BOOLEAN;

                             {write a CR/LF delimited string to the capture queue - obey margins}
                         FUNCTION QWRITELNMGN(Strg : STRING) : BOOLEAN;

                             {write string to the capture queue - obey margins}
                         FUNCTION QWRITEMGN(Strg : STRING) : BOOLEAN;

                             {print a complete file out to the printer}
                             {using current font}
                         FUNCTION PrintFile(Q              : WORD;
                                            FName          : PathStr;
                                            FileType       : TFileType;
                                            MyCOP          : CylonObjPtr) : BOOLEAN;

                         PROCEDURE SetCylon(CP : CylonObjPtr);
                         PROCEDURE SetWriteNotify(WNP : WriteNotifyType);
                         PROCEDURE SetLineNotify(LNP : LineNotifyType);
                         PROCEDURE SetPageNotify(PNP : PageNotifyType);

                             {Dump internal data - roll your own showstr}

                             {get the Qth printer model name}
                         FUNCTION GetName(Q : WORD) : STRING;

                             {get the Qth printer server name}
                         FUNCTION GetServer(Q : WORD) : STRING;

                             {get the Qth printer queue name}
                         FUNCTION GetQueue(Q : WORD) : STRING;

                             {get the Qth printer.ini file name}
                         FUNCTION GetIName(Q : WORD) : STRING;

                             {get the QID number}
                         FUNCTION GetQid(Q : WORD) : LONGINT;

                             {get the page length for a given q and mode}
                         FUNCTION GetPageLen(Q : WORD; Mode : TKPrintMode) : WORD;

                             {get the left margin pos for a given q and mode}
                         FUNCTION GetLeftMargin(Q : WORD; Mode : TKPrintMode) : WORD;

                             {return printer type - TEXT, SENDFAX, or faxdisplay}
                         FUNCTION GetPrtType(Q : WORD) : TPrtType;

                         PRIVATE
                         QID            : LONGINT;
                         NP             : NetworkPrnPtr;
                         COP            : CylonObjPtr;
                         LineNotifyFunc : LineNotifyType;
                         WriteNotifyFunc : WriteNotifyType;
                         PageNotifyFunc : PageNotifyType;
                         CurrentCaptureQ: WORD;
                         PrintMode      : TKPrintMode; {Queue, Script, other}

                         FUNCTION GetQNodePtr(PrinterNumber : WORD) : QueueNodePtr;
                         FUNCTION GetHPRes(Q : WORD) : THPRes;
                         PROCEDURE BumpClock;
                         PROCEDURE KillCylon;
                     END;


    {--------------------------------------------------------------------}
    {- UNIT PUBLIC}
    {the obligatory procedural interface... }

FUNCTION CmdLinePrintSelect(VAR PQL : QueueListPtr; Mode : TKPrintMode) : BOOLEAN;
FUNCTION PickListPrintSelect(VAR PQL : QueueListPtr; Mode : TKPrintMode) : BOOLEAN;

IMPLEMENTATION
USES
    ApMisc,
    UTEPSON9,
    UTEPSN24,
    UTHP150,
    UTHP300,
    UTIAM,
    UTOOINI,
    OpCmd,
    OpConst,
    OpFrame,
    OpInline,
    OpKey,
    Printer,
    QGlobal,
    QHdrRec,
    QNovell,
    QDrive2,
    QDrives,
    QUpTime,
    Strings,
    UColors,
    UERROR,
    UFkey,
    UGLOBAL,
    ULIB,
    UMsg,
    UWindow;

    {--------------------------------------------------------------------}
CONST

    {number of bytes in secondary command key table}
    KEYSETMAX      = 100;

    {Function key assignments for picklist}
    INCKEY         = 2;
    DECKEY         = 3;
    DONEKEY        = 10;

TYPE
    {derive a picklist capable of selecting printer queues}
    {for use by the procedural interface only}
    PQSelPtr       = ^PQSel;
    PQSel          = OBJECT(PickList)
                         CTP            : CmdTablePtr;
                         QLP            : QueueListPtr;

                         CONSTRUCTOR Init(X1, Y1, X2, Y2 : BYTE;
                                          Colors         : ColorSet;
                                          Mode           : TKPrintMode);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE KProcess;
                         PROCEDURE ItemString(Item           : WORD;
                                              Mode           : pkMode;
                                              VAR IType      : pkItemType;
                                              VAR IString    : STRING); VIRTUAL;

                         FUNCTION NumQueues : WORD;
                         FUNCTION GetQLP : QueueListPtr;
                     END;

    {------------------------------------------------------------}

    {for use by the procedural interface only}
    CONSTRUCTOR PQSel.Init(X1, Y1, X2, Y2 : BYTE; Colors : ColorSet; Mode : TKPrintMode);
    VAR
        PickListOptions,
        PickWindowOptions : LONGINT;
    BEGIN
        PickWindowOptions := DefWindowOptions OR wBordered;
        PickListOptions := pkStick + pkAlterPageRow + pkMousePage + pkDrawActive +
                           pkSetDefault + pkFlexWrite;

        IF NOT PickList.InitAbstractDeluxe(X1, Y1, X2, Y2,
                                           Colors,
                                           PickWindowOptions,
                                           78,
                                           1,
                                           PickVertical,
                                           MultipleChoice,
                                           PickListOptions) THEN BEGIN
            DispErrorDeluxe('PQSel.Init Failure', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;
        CustomizeCommandProcessor(PickCommands);

        pkOptionsOn(pkProcessZero);
        SetSelectMarker(#251, '');

        GetMemCheck(CTP, KEYSETMAX);
        IF CTP = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            DispErrorDeluxe('PQSel.Init', 'Out of memory', TRUE, Iam);
            FAIL;
        END;

        FILLCHAR(CTP^, KEYSETMAX, #0);
        PickCommands.SetSecondaryKeyPtr(CTP, KEYSETMAX);

        PickCommands.cpOptionsOn(cpSwitchPriority);
        wFrame.AddScrollBar(frRR, 1, MAXLONGINT, Colors);

        SetSearchMode(PickStringSearch);
        AddSearchHeader(10, heBL);

        wFrame.AddHeader(SysMsg(2271) {'Print Que       #Copies'} , heTL);

        wFrame.SetSizeLimits(75, 5, 75, 20);
        RawWindow.EnableExplosions(8);
        wFrame.AddShadow(shBR, shSeeThru);

        {Init the queuelist here}
        NEW(QLP, Init(AddBackSlash(NEN^.SysDir) + 'NENPRINT.INI', Mode));
        IF QLP = NIL THEN BEGIN
            DispErrorDeluxe('QLP fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        PickCommands.AddSecondaryCommand(ccQuit,
                                         1, OpKey.F1, 0);
        PickCommands.AddSecondaryCommand(ccUser2, 1, OpKey.F2, 0);
        PickCommands.AddSecondaryCommand(ccUser3, 1, OpKey.F3, 0);
        PickCommands.AddSecondaryCommand(ccUser4, 1, OpKey.F4, 0);
        PickCommands.AddSecondaryCommand(ccUser5, 1, OpKey.F5, 0);
        PickCommands.AddSecondaryCommand(ccUser6, 1, OpKey.F6, 0);
        PickCommands.AddSecondaryCommand(ccUser7, 1, OpKey.F7, 0);
        PickCommands.AddSecondaryCommand(ccUser8, 1, OpKey.F8, 0);
        PickCommands.AddSecondaryCommand(ccUser9, 1, OpKey.F9, 0);
        PickCommands.AddSecondaryCommand(ccUser10, 1, OpKey.F10, 0);
        PickCommands.AddSecondaryCommand(ccUser11, 1, TAB, 0);
        PickCommands.AddSecondaryCommand(ccUser12, 1, Space, 0);
        PickCommands.AddSecondaryCommand(ccUser13, 1, Minus, 0);
        PickCommands.AddSecondaryCommand(ccUser14, 1, PadMinus, 0);
        PickCommands.AddSecondaryCommand(ccUser15, 1, Plus, 0);
        PickCommands.AddSecondaryCommand(ccUser16, 1, PadPlus, 0);
        IF PickCommands.GetLastError <> 0 THEN
            RingBell;

    END;

    {------------------------------------------------------------}

    {clean up the poopoo}
    DESTRUCTOR PQSel.Done;
    BEGIN
        FreeMemCheck(CTP, KEYSETMAX);
        PickList.Done;
    END;

    {------------------------------------------------------------}

    FUNCTION PQSel.GetQLP : QueueListPtr;
    BEGIN
        GetQLP := QLP;
    END;

    {------------------------------------------------------------}

    PROCEDURE PQSel.ItemString(Item           : WORD;
                               Mode           : pkMode;
                               VAR IType      : pkItemType;
                               VAR IString    : STRING);

    BEGIN
        IString := '';
        IF (Item > 0) AND (Item <= QLP^.Size) THEN
            IString := QLP^.ShowStr(Item); {you can also "roll your own" strg here}
    END;

    {------------------------------------------------------------}

    PROCEDURE PQSel.KProcess;
    VAR
        I,
        J,
        N,
        Choice         : WORD;
        AllDone        : BOOLEAN;
    BEGIN
        ClearFKeys;

        REPEAT
            AllDone := FALSE;

            SetTag(1, UnShift, 'EXIT');
            SetTag(INCKEY, UnShift, SysMsg(002269));
            SetTag(DECKEY, UnShift, SysMsg(002270));
            SetTag(DONEKEY, UnShift, SysMsg(002173));
            Select;
            Process;

            Choice := GetLastChoice;

            CASE GetLastCommand OF
                ccError :
                    BEGIN
                        AllDone := TRUE;
                        DispErrorDeluxe(SysMsg(2272) {'Problem in'} , 'PQSel picklist', TRUE, Iam);
                        EXIT;
                    END;
                ccQuit :
                    BEGIN
                        FOR N := 1 TO QLP^.Size DO BEGIN
                            QLP^.Pick(N, FALSE, PICKBYPOS);
                            QLP^.SetCopies(N, 0, PICKBYPOS);
                            QLP^.UnLoadAttr(N, PICKBYPOS);
                        END;
                        AllDone := TRUE;
                    END;
                ccUser12 :
                    BEGIN         {toggle selection}
                        IF ItemIsSelected(Choice) THEN BEGIN
                            DeselectItem(Choice);
                            QLP^.SetCopies(Choice, 0, PICKBYPOS);
                        END
                        ELSE BEGIN
                            SelectItem(Choice);
                            QLP^.SetCopies(Choice, 1, PICKBYPOS);
                        END;
                    END;
                ccUser0 + DONEKEY,
                ccSelect :
                    BEGIN
                        {first, clear all picked flags}
                        FOR N := 1 TO QLP^.Size DO
                            QLP^.Pick(N, FALSE, PICKBYPOS);

                        InitSequence(N);
                        WHILE HaveSelected(N) DO BEGIN
                            QLP^.Pick(N, TRUE, PICKBYPOS);
                            QLP^.LoadAttr(N, PICKBYPOS); {instantiate attribute list for user choice}
                            NextSelected(N);
                        END;
                        SetLastCommand(ccSelect);
                        AllDone := TRUE;
                    END;
                ccUser15,
                ccUser16,
                ccUser0 + INCKEY :
                    BEGIN         {Increment copies}
                        QLP^.SetCopies(Choice, QLP^.GetCopies(Choice) + 1, PICKBYPOS);
                        SelectItem(Choice);
                    END;
                ccUser13,
                ccUser14,
                ccUser0 + DECKEY :
                    BEGIN         {decrement copies}
                        IF QLP^.GetCopies(Choice) > 0 THEN BEGIN
                            QLP^.SetCopies(Choice, QLP^.GetCopies(Choice) - 1, PICKBYPOS);
                            IF QLP^.GetCopies(Choice) = 0 THEN
                                DeselectItem(Choice)
                        END
                        ELSE BEGIN
                            RingBell;
                            DeselectItem(Choice);
                        END;
                    END;
            END;

        UNTIL AllDone;

        ClearFKeys;
    END;

    {------------------------------------------------------------}

    FUNCTION PQSel.NumQueues : WORD;
    BEGIN
        NumQueues := QLP^.Size;
    END;

    {------------------------------------------------------------}

    {procedural interface - picklist style}
    FUNCTION PickListPrintSelect(VAR PQL : QueueListPtr; Mode : TKPrintMode) : BOOLEAN;
    VAR
        P              : PQSelPtr;
        Colors         : ColorSet;
        H,
        W,
        Lx,
        Rx,
        TY,
        By             : BYTE;
    BEGIN
        GetCScheme(Red_Scheme, Colors);

        W := 23;
        H := 8;
        Lx := (ScreenWidth - W) DIV 2;
        Rx := Lx + W;
        TY := (ScreenHeight - H) DIV 2;
        By := TY + H;

        NEW(P, Init(Lx, TY, Rx, By, Colors, Mode));
        P^.ChangeNumItems(P^.NumQueues);
        P^.KProcess;
        P^.ERASE;
        PickListPrintSelect := P^.GetLastCommand = ccSelect;
        PQL := P^.GetQLP;
        DISPOSE(P, Done);
    END;

    {------------------------------------------------------------}

    {procedural interface - dialog box / command line style}
    FUNCTION CmdLinePrintSelect(VAR PQL : QueueListPtr; Mode : TKPrintMode) : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        PQL := NIL;

        CmdLinePrintSelect := FALSE;
        Strg := '';

        IF EditProc(0, SysMsg(2273) {'Enter Printer Numbers'} , TRUE, TRUE, $FE, Strg) THEN BEGIN

            NEW(PQL, Init(AddBackSlash(NEN^.SysDir) + 'NENPRINT.INI', Mode));

            IF PQL = NIL THEN
                EXIT;

            IF NOT PQL^.DumbSelect(Strg) THEN BEGIN
                CASE InitStatus MOD 10000 OF
                    ecInvalidData,
                    ecUserAbort : ;
                    ELSE
                        DispErrorDeluxe(SysMsg(2276) {'Problem selecting printer queue'} ,
                                        SysMsg(2277) {'possible bad ini file'} ,
                                        TRUE,
                                        Iam);
                END;              {CASE}
                DISPOSE(PQL, Done);
                PQL := NIL;
                EXIT;
            END;
            CmdLinePrintSelect := TRUE;
        END;
    END;

    {------------------------------------}

    {- Init a hugestring object and maybe init the string itself}
    CONSTRUCTOR HsObj.Init(Siz : WORD);
    BEGIN

        IF NOT SingleListNode.Init THEN BEGIN
            DispErrorDeluxe('SingleListNode.Init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        Hs := NIL;
        IF Siz > 0 THEN
            IF NOT HRealloc(Siz) THEN BEGIN
                DispErrorDeluxe('HRealloc Fail', ErrorMessage(InitStatus), TRUE, Iam);
                FAIL;
            END;
    END;

    {--------------------------------------------------------------------}

    {- deallocate a hugestring}
    PROCEDURE HsObj.HDispose(THS : HugeStrPtr);
    BEGIN
        IF THS = NIL THEN
            EXIT;
        FreeMemCheck(THS^.Strg, THS^.MaxLen);
        DISPOSE(THS);
    END;

    {--------------------------------------------------------------------}

    {- same as Strg := '';}
    PROCEDURE HsObj.HClear;
    BEGIN
        Hs^.Len := 0;
    END;

    {--------------------------------------------------------------------}

    {- destroy a hugestr object}
    DESTRUCTOR HsObj.Done;
    BEGIN
        HDispose(Hs);
        SingleListNode.Done;
    END;

    {--------------------------------------------------------------------}

    {concatenate two hugestrgs : Hs := Hs + Ths }
    FUNCTION HsObj.HStrCat(THS : HugeStrPtr) : BOOLEAN;
    VAR
        P              : POINTER;
    BEGIN
        HStrCat := FALSE;
        IF Hs = NIL THEN BEGIN
            IF NOT HRealloc(THS^.Len) THEN {Shrink wrap the string}
                EXIT;
            MOVE(THS^.Strg^, Hs^.Strg^, THS^.Len);
            Hs^.Len := THS^.Len;
            HStrCat := TRUE;
            EXIT;
        END;

        {calc size of new hugestr to hold old + new}
        IF NOT HRealloc(THS^.Len + Hs^.Len) THEN
            EXIT;

        {bump pointer to end original string in order to concatenate}
        P := AddLongToPtr(Hs^.Strg, Hs^.Len);

        {copy the new part to the end of the original}
        MOVE(THS^.Strg^, P^, THS^.Len);

        {Set the new string length}
        Hs^.Len := THS^.Len + Hs^.Len;

        HStrCat := TRUE;
    END;

    {--------------------------------------------------------------------}

    {- Resize a hugestr either larger or smaller}
    FUNCTION HsObj.HRealloc(Siz : WORD) : BOOLEAN;
    VAR
        TP             : HugeStrPtr;
        L              : LONGINT;
    BEGIN
        HRealloc := FALSE;
        NEW(TP);
        IF TP = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            EXIT;
        END;
        GetMemCheck(TP^.Strg, Siz);
        IF TP^.Strg = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            DISPOSE(TP);
            EXIT;
        END;
        FILLCHAR(TP^.Strg^, Siz, #0);
        TP^.MaxLen := Siz;
        TP^.Len := 0;

        IF Hs = NIL THEN BEGIN    {just make a new hugestr}
            Hs := TP;             {copy the header pointers}
            Hs^.Strg := TP^.Strg; {copy the strg pointers}
            HRealloc := TRUE;
            EXIT;
        END
        ELSE BEGIN
            {doing realloc of existing hugestr}

            {if newsize is less than oldsize then truncate}
            IF Siz > Hs^.MaxLen THEN
                Siz := Hs^.MaxLen;

            {copy the string contents}
            MOVE(Hs^.Strg^, TP^.Strg^, Siz);
            TP^.Len := Siz;
            HDispose(Hs);         {blow off old hs}
        END;
        HRealloc := TRUE;
        Hs := TP;                 {reassign to temp}
    END;

    {--------------------------------------------------------------------}

    {Return a pointer to the internal data - not for general use!}
    FUNCTION HsObj.GetHs : HugeStrPtr;
    BEGIN
        GetHs := Hs;
    END;

    {--------------------------------------------------------------------}

    {- Init a hugeparser}
    CONSTRUCTOR HsParse.Init;
    BEGIN
        IF NOT HsObj.Init($0) THEN BEGIN
            DispErrorDeluxe('HsParse.Init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;
    END;

    {--------------------------------------------------------------------}

    {- Destroy a hugeparser}
    DESTRUCTOR HsParse.Done;
    BEGIN
        HsObj.Done;
    END;

    {--------------------------------------------------------------------}

    {- Parse a hex format line of ini data}
    FUNCTION HsParse.HexParse(Strg : STRING) : BOOLEAN;
    VAR
        I              : WORD;
        W              : INTEGER;
        HOP            : HsObjPtr;
        THS            : HugeStrPtr;
    BEGIN
        HexParse := FALSE;
        NEW(HOP, Init($FF));
        IF HOP = NIL THEN
            EXIT;

        THS := HOP^.GetHs;

        THS^.Len := 0;
        FOR I := 1 TO WordCount(Strg, [' ', ',']) DO BEGIN
            IF NOT Str2Int('$' + ExtractWord(I, Strg, [' ', ',']), W) THEN
                EXIT;
            IF W > $FF THEN
                EXIT;
            THS^.Strg[THS^.Len] := CHR(W);
            INC(THS^.Len)
        END;
        HexParse := HStrCat(THS);
        DISPOSE(HOP, Done);
    END;

    {--------------------------------------------------------------------}

    { Check for a valid sequence of characters in an ASCII INI file}
    FUNCTION CheckValidSeq(Strg : STRING; Mode : TParseMode; VAR B, Cpos : BYTE) : BOOLEAN;
    VAR
        BadSpot        : INTEGER;
    BEGIN
        CheckValidSeq := FALSE;

        Cpos := POS('>', Strg);

        CASE Mode OF
            THEX :
                BEGIN
                    IF ((Cpos > 3) OR (Cpos < 2)) THEN
                        EXIT;
                    VAL('$' + COPY(Strg, 1, Cpos - 1), B, BadSpot);
                END;
            TDECI :
                BEGIN
                    IF ((Cpos > 4) OR (Cpos < 2)) THEN
                        EXIT;
                    VAL(COPY(Strg, 1, Cpos - 1), B, BadSpot);
                END;
        END;                      {CASE}
        IF BadSpot <> 0 THEN
            EXIT;

        CheckValidSeq := TRUE;

    END;

    {--------------------------------------------------------------------}
    { ASCII style printer.INI file parser.  Uses the following syntax:   }
    {                                                                    }
    { <ESC> = Escape char                                                }
    { <CR>  = Carriage Return                                            }
    { <LF>  = Line Feed                                                  }
    { <^Z>  = control Z.  Replace 'Z' with any char for other ctrl chars }
    { <#nnn>= Replace nnn with decimal equiv char                        }
    { <$hh> = Replace hh with hexidecimal equiv char                     }
    {                                                                    }
    { Note: all characters inside <> MUST be in upper case or they will  }
    { be treated as part of the normal character stream.                 }
    {                                                                    }
    { More Tags can be added to the LUT if desired - just bump the array }
    { size and the parser loop will automatically adjust to include them }

    FUNCTION HsParse.ASCIIParse(Strg : STRING) : BOOLEAN;
    TYPE
        TLUT           = RECORD
                             Tag            : STRING[5];
                             Token          : CHAR;
                         END;
    CONST
        LUT            : ARRAY[1..6] OF TLUT =
        (
            (Tag : '<^'; Token : #0),
            (Tag : '<#'; Token : #1),
            (Tag : '<$'; Token : #2),
            (Tag : '<ESC>'; Token : #27),
            (Tag : '<CR>'; Token : #13),
            (Tag : '<LF>'; Token : #10)
            );
    VAR
        I,
        J              : WORD;
        GoodParse      : BOOLEAN;
        TStrg          : STRING;
        HOP            : HsObjPtr;
        THS            : HugeStrPtr;
        C,
        EPOS           : BYTE;
    BEGIN
        ASCIIParse := FALSE;
        NEW(HOP, Init($FF));
        IF HOP = NIL THEN
            EXIT;

        THS := HOP^.GetHs;

        {Start string scan}
        I := 1;
        WHILE I <= LENGTH(Strg) DO BEGIN
            {check for quoted control sequences}
            CASE Strg[I] OF
                '<' :
                    BEGIN
                        {found a possible quoted control sequence}
                        {so scan the lookup table for a case sensitive match}
                        GoodParse := FALSE;
                        FOR J := LOW(LUT) TO HIGH(LUT) DO BEGIN
                            IF POS(LUT[J].Tag, COPY(Strg, I, $FF)) = 1 THEN BEGIN
                                {found a match}
                                {check special cases}
                                CASE LUT[J].Token OF
                                    #0 :
                                        BEGIN { hat char (^)}
                                            {make sure we have a terminating '>' }

                                            IF Strg[I + 3] <> '>' THEN
                                                BREAK;
                                            {Trap lower case hat chars for consistency}
                                            IF (Strg[I + 2] > #95) OR (Strg[I + 2] < #64) THEN
                                                BREAK;

                                            {convert char to control char and stuff it}
                                            THS^.Strg[THS^.Len] := CHR(ORD(Strg[I + 2]) - 64);
                                            INC(THS^.Len);
                                            INC(I, 4);
                                            GoodParse := TRUE;
                                            BREAK;
                                        END;
                                    #1 :
                                        BEGIN { number sign (#)}
                                            IF CheckValidSeq(COPY(Strg, I + 2, $FF), TDECI, C, EPOS) THEN BEGIN
                                                THS^.Strg[THS^.Len] := CHR(C);
                                                INC(THS^.Len);
                                                INC(I, EPOS + 2);
                                                GoodParse := TRUE;
                                            END;
                                            BREAK;
                                        END;
                                    #2 :
                                        BEGIN { dollar sign ($)}
                                            IF CheckValidSeq(COPY(Strg, I + 2, $FF), THEX, C, EPOS) THEN BEGIN
                                                THS^.Strg[THS^.Len] := CHR(C);
                                                INC(THS^.Len);
                                                INC(I, EPOS + 2);
                                                GoodParse := TRUE;
                                            END;
                                            BREAK;
                                        END;
                                    ELSE BEGIN
                                        {was not a hat so must be normal control}

                                        THS^.Strg[THS^.Len] := LUT[J].Token;
                                        INC(THS^.Len);
                                        INC(I, LENGTH(LUT[J].Tag));
                                        GoodParse := TRUE;
                                        BREAK;
                                    END;
                                END; {CASE}
                            END;  {IF}
                        END;      {FOR}
                        IF NOT GoodParse THEN BEGIN
                            {Not a quoted control char so stuff the '<' }
                            THS^.Strg[THS^.Len] := Strg[I];
                            INC(THS^.Len);
                            INC(I);
                        END;
                    END;
                ELSE BEGIN
                    THS^.Strg[THS^.Len] := Strg[I];
                    INC(THS^.Len);
                    INC(I);
                END;
            END;                  {CASE}
        END;                      {WHILE}
        ASCIIParse := HStrCat(THS);
        DISPOSE(HOP, Done);
    END;


    {--------------------------------------------------------------------}

    {- parse a decimal format line of ini data }
    FUNCTION HsParse.DECIParse(Strg : STRING) : BOOLEAN;
    VAR
        I              : WORD;
        W              : INTEGER;
        THS            : HugeStrPtr;
        HOP            : HsObjPtr;
    BEGIN
        DECIParse := FALSE;
        NEW(HOP, Init($FF));
        IF HOP = NIL THEN
            EXIT;

        THS := HOP^.GetHs;
        THS^.Len := 0;
        FOR I := 1 TO WordCount(Strg, [' ', ',']) DO BEGIN
            IF NOT Str2Int(ExtractWord(I, Strg, [' ', ',']), W) THEN
                EXIT;
            IF (W > $FF) OR (W < 0) THEN
                EXIT;
            THS^.Strg[THS^.Len] := CHR(W);
            INC(THS^.Len)
        END;
        DECIParse := HStrCat(THS);
        DISPOSE(HOP, Done);
    END;

    {--------------------------------------------------------------------}

    {- parser entry point}
    FUNCTION HsParse.Parse(Strg : STRING; Mode : TParseMode) : BOOLEAN;
    BEGIN
        Parse := FALSE;
        InitStatus := epWarning + ecInvalidData;

        CASE Mode OF
            THEX :
                IF NOT HexParse(Strg) THEN
                    EXIT;
            TASCII :
                IF NOT ASCIIParse(Strg) THEN
                    EXIT;
            TDECI :
                IF NOT DECIParse(Strg) THEN
                    EXIT;
            TBAD :
                EXIT;
        END;                      {CASE}
        InitStatus := ecOk;

        Parse := TRUE;
    END;

    {--------------------------------------------------------------------}

    FUNCTION QueueNode.AttachToServer : BOOLEAN;
    VAR
        FSFound        : BOOLEAN;
        ErrCode        : INTEGER;
    BEGIN
        AttachToServer := FALSE;
        FSFound := FALSE;

        SYS^.ToQFS := Sname;
        IF (Sys^.ToQFS <> 'LOCAL') And
           (SYS^.ToQFS = SYS^.HomeFS) THEN
           BEGIN
           ChangeDrive(SYS^.HomeDrive);
           IF NOT MapToDrive(SYS^.ToDrive, 'SYS:', Network,' ') THEN
              BEGIN
              DispErrorDeluxe('Unable to map to server:', Sname, TRUE, Iam);
              EXIT;
              END;
           FSFound := TRUE;
           END;

        {$IFNDEF NOTNEN}
        IF (Sys^.ToQFS <> 'LOCAL') And
           (SYS^.ToQFS = Fw^.CurrentQFS) AND
           (NOT FSFound) THEN BEGIN
            ChangeDrive(Fw^.QDrive);
            IF NOT MapToDrive(SYS^.ToDrive, 'SYS:', Network,' ') THEN BEGIN
                DispErrorDeluxe('Unable to map to server:', Sname, TRUE, Iam);
                EXIT;
            END;
            FSFound := TRUE;
        END;
        {$ENDIF}
        {$IFNDEF NOTNEN}
        IF (Sys^.ToQFS <> 'LOCAL') And
           (SYS^.ToQFS = Fw^.FwdLink^.CurrentQFS) AND (NOT FSFound) THEN BEGIN
            ChangeDrive(Fw^.FwdLink^.QDrive);
            IF NOT MapToDrive(SYS^.ToDrive, 'SYS:', Network,' ') THEN BEGIN
                DispErrorDeluxe('Unable to map to server:', Sname, TRUE, Iam);
                EXIT;
            END;
            FSFound := TRUE;
        END;
        {$ENDIF}

        IF (Sys^.ToQFS <> 'LOCAL') And
           (NOT FSFound) AND (SYS^.ToQFS <> 'LOCAL') THEN BEGIN
            IF NOT AttachFS(SYS^.ToQFS, SYS^.ToDrive, 'SYS:',
                            SYS^.QMGRUserName,
                            SYS^.QMGRPassword, ErrCode) THEN BEGIN
                DispErrorDeluxe('Unable to attach to server:', Sname, TRUE, Iam);
                EXIT;
            END;
        END;
        AttachToServer := TRUE;
    END;

    {--------------------------------------------------------------------}

    FUNCTION QueueNode.ReleaseServer : BOOLEAN;
    Var I : Integer;
    BEGIN
        ReleaseServer := FALSE;
        For I := 1 To 16 Do
           Begin
           If SYS^.FSNames[I] = Sys^.ToQFS Then
              Begin
              If SYS^.FSAttached And LongIntBitMasks[I] = LongIntBitMasks[I] Then
                 Begin
                 ReleaseServer := True;
                 Exit;
                 End;
              End;
           End;


        IF (SYS^.ToQFS <> SYS^.BaseFS) AND
        (SYS^.ToQFS <> SYS^.HomeFS) AND
        (SYS^.ToQFS <> Fw^.CurrentQFS) AND
        (SYS^.ToQFS <> Fw^.FwdLink^.CurrentQFS) AND
        (SYS^.ToQFS <> '') THEN
            IF NOT ReleaseFileServer(SYS^.ToQFS) THEN BEGIN
                DispErrorDeluxe(SysMsg(000191) {'Could Not Release FS'} , '', TRUE, Iam);
                EXIT;
            END;
        SYS^.ToQFS := '';
        ReleaseServer := TRUE;
    END;

    {--------------------------------------------------------------------}

    {- init a queuenode that will eventually contain info for one printer queue}
    CONSTRUCTOR QueueNode.Init(VAR Name,
                               Server,
                               Queue,
                               IniName        : STRING;
                               Mn             : WORD;
                               PrinterType    : STRING;
                               HpRes          : WORD);
    VAR
        SaveDrive      : DriveName;
        Pt             : TPrtType;
    BEGIN
        IF NOT SingleListNode.Init THEN BEGIN
            DispErrorDeluxe('Quenode.init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        Copies := 0;
        Picked := FALSE;
        PName := Name;
        Sname := Server;
        QName := Queue;
        IName := IniName;
        MyNumber := Mn;

        IF HpRes > 150 THEN
            HpResolution := E300
        ELSE
            HpResolution := E150;

        IF HpRes = $FFFF THEN
            HpResolution := EBAD;

        PrinterType := Trim(PrinterType);

        FOR Pt := LOW(TPrtType) TO HIGH(TPrtType) DO BEGIN
            IF CompUCString(PrinterType, PrtTypeLUT[Pt]) = EQUAL THEN
                BREAK;
        END;
        PrtType := Pt;

        CASE PrtType OF
            ESENDFAX :
                BEGIN
                    QID := - 99;
                END;
            ELSE BEGIN
                QID := 0;
            END;
        END;                      {CASE}

        {init the attribute list}
        IF NOT Al.Init(IName) THEN BEGIN
            DispErrorDeluxe('Quenode.init fail',
                            ErrorMessage(InitStatus),
                            TRUE,
                            Iam);
            FAIL;
        END;
    END;

    {--------------------------------------------------------------------}

    {- Destroy a queuenode}
    DESTRUCTOR QueueNode.Done;
    BEGIN
        WHILE Al.Size > 0 DO BEGIN
            Al.DELETE(Al.Head);
        END;
        Al.Done;
    END;

    {--------------------------------------------------------------------}

    FUNCTION QueueNode.GetPrtType : TPrtType;
    BEGIN
        GetPrtType := PrtType;
    END;

    {--------------------------------------------------------------------}

    FUNCTION QueueNode.GetHPRes : THPRes;
    BEGIN
        GetHPRes := HpResolution;
    END;

    {--------------------------------------------------------------------}

    {- return this nodes printer number}
    FUNCTION QueueNode.GetMyNumber : WORD;
    BEGIN
        GetMyNumber := MyNumber;
    END;

    {--------------------------------------------------------------------}

    {- return this nodes printer model name}
    FUNCTION QueueNode.GetName : STRING;
    BEGIN
        GetName := PName;
    END;

    {--------------------------------------------------------------------}

    {- return this nodes printer server name}
    FUNCTION QueueNode.GetServer : STRING;
    BEGIN
        GetServer := Sname;
    END;

    {--------------------------------------------------------------------}

    {- return this nodes printer queue name}
    FUNCTION QueueNode.GetQueue : STRING;
    BEGIN
        GetQueue := QName;
    END;

    {--------------------------------------------------------------------}

    {- return this nodes printer.ini filename}
    FUNCTION QueueNode.GetIName : STRING;
    BEGIN
        GetIName := IName;
    END;

    {--------------------------------------------------------------------}

    {- select/deselect this node for printing}
    PROCEDURE QueueNode.Pick(Flg : BOOLEAN);
    BEGIN
        Picked := Flg;
    END;

    {--------------------------------------------------------------------}

    {- check the selected status of this node}
    FUNCTION QueueNode.IsPicked : BOOLEAN;
    BEGIN
        IsPicked := Picked;
    END;

    {--------------------------------------------------------------------}
    {- read in all the attribute lines from printer.ini and add them to  }
    {  the AL (attribute list)                                           }
    FUNCTION QueueNode.AAdd(Name : PathStr) : BOOLEAN;
    VAR
        Strg           : STRING;
        Mode           : TParseMode;
        I              : WORD;
        F              : FMTTOKEN;
        PAO            : AttribObjPtr;
        IRP            : IniReaderP;
    BEGIN
        AAdd := FALSE;

        NEW(IRP, Init(Name, 512));
        IF IRP = NIL THEN
            EXIT;

        {get the parse mode - hex, ascii, or decimal}

        Strg := IRP^.FindKeyStringSection('STRING', 'FORMAT', 'PRINTERXY', '');

        FOR Mode := LOW(TParseMode) TO HIGH(TParseMode) DO BEGIN
            IF CompUCString(Strg, ParseModeLUT[Mode]) = EQUAL THEN
                BREAK;
        END;

        {the 2nd through the Nth sections contain attribute names and strings}
        {we are going to read all the strings associated with a given attribute, }
        {concatenate them into a hugestrg and place them into individual, named  }
        {attribute list elements.}
        FOR I := 2 TO IRP^.NumberOfSections DO BEGIN
            Strg := IRP^.SectionHeading(I);
            IRP^.FindSection(Strg); {go to the selected heading}

            {look up the current sections attribute name BOLD, SOJ, EOJ...}
            FOR F := LOW(FMTTOKEN) TO HIGH(FMTTOKEN) DO BEGIN
                IF CompUCString(Strg, TokenLUT[F]) = EQUAL THEN
                    BREAK;
            END;

            IF F <> BADF THEN BEGIN
                {We found a valid attribute name, so read in the printer codes}
                {into an attribute node using the correct parser}
                NEW(PAO, Init(Strg, F));
                IF PAO = NIL THEN
                    EXIT;
                WHILE IRP^.NextSectionItem(Strg) DO
                    IF NOT PAO^.Parse(Strg, Mode) THEN BEGIN
                        DispErrorDeluxe(Name + ' AAdd syntax error', Strg, TRUE, Iam);
                        DISPOSE(IRP, Done);
                        DISPOSE(PAO, Done);
                        EXIT;
                    END;
                Al.APPEND(PAO);
            END;

        END;

        DISPOSE(IRP, Done);
        AAdd := TRUE;
    END;

    {--------------------------------------------------------------------}

    {- destroy the attrib list, leaving the queuenode in-tact}
    PROCEDURE QueueNode.ADump;
    BEGIN
        WHILE Al.Size > 0 DO
            Al.DELETE(Al.Head);
    END;

    {--------------------------------------------------------------------}

    {- return the Ath attribute name for the current queue}
    FUNCTION QueueNode.AGetName(A : WORD) : STRING;
    BEGIN
        AGetName := AttribObjPtr(Al.Nth(A))^.GetName;
    END;

    {--------------------------------------------------------------------}

    {- return the Ath attribute token for the current queue}
    FUNCTION QueueNode.AGetTok(A : WORD) : FMTTOKEN;
    BEGIN
        AGetTok := AttribObjPtr(Al.Nth(A))^.GetTok;
    END;

    {--------------------------------------------------------------------}

    {- return a pointer to the Ath attribute Hugestr for the current queue}
    FUNCTION QueueNode.AGetAttr(A : WORD) : HugeStrPtr;
    BEGIN
        AGetAttr := AttribObjPtr(Al.Nth(A))^.GetAttr;
    END;

    {--------------------------------------------------------------------}

    {- look in the attribute list for the specified attribute name ANAME}
    {  returns NIL if not found or a pointer to a hugestr if it exists  }
    FUNCTION QueueNode.ASearchSAttr(AName : STRING) : HugeStrPtr;
    VAR
        I              : WORD;
    BEGIN
        ASearchSAttr := NIL;
        FOR I := 1 TO Al.Size DO BEGIN
            IF CompUCString(AttribObjPtr(Al.Nth(I))^.GetName, AName) = EQUAL THEN BEGIN
                ASearchSAttr := AttribObjPtr(Al.Nth(I))^.GetAttr;
                EXIT;
            END;
        END;
    END;

    {--------------------------------------------------------------------}

    {- look in the attribute list for the specified attribute token F   }
    {  returns NIL if not found or a pointer to a hugestr if it exists  }
    FUNCTION QueueNode.ASearchAttr(F : FMTTOKEN) : HugeStrPtr;
    VAR
        I              : WORD;
        tf : fmttoken;
        si : Word;
    BEGIN
        si := al.size;
        ASearchAttr := NIL;
        FOR I := 1 TO Al.Size DO BEGIN

            tf := AttribObjPtr(Al.Nth(I))^.GetTok;
            IF AttribObjPtr(Al.Nth(I))^.GetTok = F THEN BEGIN
                ASearchAttr := AttribObjPtr(Al.Nth(I))^.GetAttr;
                EXIT;
            END;
        END;
    END;

    {--------------------------------------------------------------------}

    {- set the number of desired copies}
    PROCEDURE QueueNode.SetCopies(C : WORD);
    BEGIN
        Copies := C;
    END;

    {--------------------------------------------------------------------}

    {- return the current number of copies}
    FUNCTION QueueNode.GetCopies : WORD;
    BEGIN
        GetCopies := Copies;
    END;

    {--------------------------------------------------------------------}
    {- Return the novell id code for this queue}
    FUNCTION QueueNode.GetQid : LONGINT;
    BEGIN
        GetQid := QID;
    END;

    {--------------------------------------------------------------------}

    {- return the page length for this queue}
    FUNCTION QueueNode.GetPageLen(Mode : TKPrintMode) : WORD;
    BEGIN
        GetPageLen := Al.GetPageLen(Mode);
    END;

    {--------------------------------------------------------------------}

    {- return the left margin for this queue}
    FUNCTION QueueNode.GetLeftMargin(Mode : TKPrintMode) : WORD;
    BEGIN
        GetLeftMargin := Al.GetLeftMargin(Mode);
    END;

    {--------------------------------------------------------------------}

    {load and parse nenprint.ini}
    CONSTRUCTOR QueueList.Init(IniName : PathStr; Mode : TKPrintMode);
    VAR
        HpRes,
        Mn,
        I              : WORD;
        QNP            : QueueNodePtr;
        Path           : PathStr;
        SecName,
        PName,
        FName,
        QName,
        IName,
        PrinterType    : STRING[MAXNAMELEN];
        IRP            : IniReaderP;
    BEGIN
        LineNotifyFunc := NIL;
        WriteNotifyFunc := NIL;
        PageNotifyFunc := NIL;
        QID := 0;

        NEW(COP, Init('Initializing Printers', 10));
        COP^.Draw;
        IF NOT SingleList.Init THEN BEGIN
            DISPOSE(COP, Done);
            COP := NIL;
            DispErrorDeluxe('QueueList.init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;
        PrintMode := Mode;
        NP := NIL;
        {First read system defaults, if possible}
        Path := AddBackSlash(NEN^.SysDir) + 'NENPRINT.INI';
        COP^.Update;
        NEW(IRP, Init(Path, 512));
        IF IRP <> NIL THEN BEGIN
            FOR I := 1 TO IRP^.NumberOfSections DO BEGIN
                COP^.Update;
                SecName := IRP^.SectionHeading(I);
                IF POS('PRINTER', SecName) = 1 THEN BEGIN
                    PName := IRP^.FindKeyStringSection('PRINTER', 'NAME', SecName, '');
                    FName := IRP^.FindKeyStringSection('FILE', 'SERVER', SecName, '');
                    QName := IRP^.FindKeyStringSection('PRINTER', 'QUEUE', SecName, '');
                    IName := IRP^.FindKeyStringSection('PRINTER', 'INI', SecName, '');
                    PrinterType := IRP^.FindKeyStringSection('PRINTER', 'TYPE', SecName, 'TEXT');
                    Mn := IRP^.FindKeyValueSection('PRINTER', 'NUMBER', SecName, $FFFF);
                    HpRes := IRP^.FindKeyValueSection('FAXPRINT', 'HPRES', SecName, $FFFF);

                    NEW(QNP, Init(PName,
                                  FName,
                                  QName,
                                  IName,
                                  Mn,
                                  PrinterType,
                                  HpRes));
                    IF QNP = NIL THEN BEGIN
                        Done;
                        DISPOSE(COP, Done);
                        DISPOSE(IRP, Done);
                        COP := NIL;
                        DispErrorDeluxe('QNP.init fail', ErrorMessage(InitStatus), TRUE, Iam);
                        FAIL;
                    END;
                    APPEND(QNP);
                END;
            END;
            DISPOSE(IRP, Done);
        END
        ELSE BEGIN
            DISPOSE(COP, Done);
            FAIL;
        END;
        DISPOSE(COP, Done);
        COP := NIL;
    END;

    {--------------------------------------------------------------------}

    CONSTRUCTOR QueueList.InitDeluxe(IniName : PathStr; Mode : TKPrintMode; MyCOP : CylonObjPtr);
    BEGIN
        IF MyCOP <> NIL THEN
            MyCOP^.ERASE;
        IF NOT Init(IniName, Mode) THEN
            FAIL;
        COP := MyCOP;
        IF COP <> NIL THEN
            COP^.Draw;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE QueueList.BumpClock;
    BEGIN
        IF COP <> NIL THEN
            COP^.Update
        ELSE BEGIN
            IF NENFlag THEN
                UpTime
            ELSE
                UpdateWtime(FALSE);
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE QueueList.KillCylon;
    BEGIN
        IF COP <> NIL THEN
            DISPOSE(COP, Done);
        COP := NIL;
    END;

    {--------------------------------------------------------------------}

    CONSTRUCTOR QueueList.InitDumbDeluxe(IniName        : PathStr;
                                         Mode           : TKPrintMode;
                                         MyCOP          : CylonObjPtr;
                                         Strg           : STRING);
    VAR
        PHP            : HsParsePtr;
        THS            : HugeStrPtr;
        HpRes,
        Mn,
        I              : WORD;
        QNP            : QueueNodePtr;
        Path           : PathStr;
        SecName,
        PName,
        FName,
        QName,
        IName,
        PrinterType    : STRING[MAXNAMELEN];
        TagArray       : ARRAY[0..255] OF BYTE;
        NumPrinters,
        Completed      : WORD;
        IRP            : IniReaderP;

        FUNCTION ParseStrg(InStrg : STRING) : BOOLEAN;
        VAR
            AnySelected    : BOOLEAN;
            I,
            PrintersDone   : WORD;
            TUP            : KTellUserP;
        BEGIN
            ParseStrg := FALSE;

            IF LENGTH(Trim(InStrg)) = 0 THEN BEGIN
                InitStatus := epWarning + ecInvalidData;
                EXIT;
            END;

            FILLCHAR(TagArray, SIZEOF(TagArray), #0);
            NEW(PHP, Init);
            IF PHP = NIL THEN BEGIN
                InitStatus := epFatal + ecOutOfMemory;
                DispErrorDeluxe('Queuelist.InitDumbDeluxe fail: parse init', ErrorMessage(InitStatus), TRUE, Iam);
                EXIT;
            END;
            IF NOT PHP^.Parse(Strg, TDECI) THEN BEGIN
                InitStatus := epWarning + ecInvalidData;
                DISPOSE(PHP, Done);
                EXIT;
            END;
            THS := PHP^.GetHs;
            FOR I := 0 TO THS^.Len - 1 DO BEGIN
                INC(TagArray[BYTE(THS^.Strg[I])]);
            END;

            DISPOSE(PHP, Done);
            NumPrinters := 0;
            FOR I := 1 TO 255 DO BEGIN
                IF TagArray[I] > 0 THEN
                    INC(NumPrinters);
            END;

            IF NumPrinters = 0 THEN BEGIN
                NEW(TUP, Init('No Printers Selected'));
                DISPOSE(TUP, Done);
                InitStatus := ecUserAbort;
            END;
            ParseStrg := NumPrinters > 0;
        END;

    BEGIN
        LineNotifyFunc := NIL;
        WriteNotifyFunc := NIL;
        PageNotifyFunc := NIL;
        PrintMode := Mode;
        QID := 0;

        IF NOT ParseStrg(Strg) THEN BEGIN
            CASE InitStatus MOD 10000 OF
                ecInvalidData :
                    BEGIN
                        KDIALOG('Invalid Entry', 'Error', LightRed,
                                Strg, 'Is not a valid printer number');
                        InitStatus := ecUserAbort;
                        FAIL;
                    END;
                ecUserAbort : ;
            END;
        END;

        IF MyCOP <> NIL THEN BEGIN
            MyCOP^.ERASE;

            NEW(COP, Init('Initializing Printers', 10));
            IF COP = NIL THEN
                FAIL;

            COP^.Draw;
        END
        ELSE
            COP := NIL;


        IF NOT SingleList.Init THEN BEGIN
            KillCylon;
            DispErrorDeluxe('QueueList.InitQuickDeluxe fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        PrintMode := Mode;
        NP := NIL;
        {First read system defaults, if possible}
        Path := AddBackSlash(NEN^.SysDir) + 'NENPRINT.INI';

        BumpClock;

        Completed := 0;

        NEW(IRP, Init(Path, 512));

        IF IRP <> NIL THEN BEGIN
            FOR I := 1 TO IRP^.NumberOfSections DO BEGIN
                BumpClock;
                SecName := IRP^.SectionHeading(I);
                IF POS('PRINTER', SecName) = 1 THEN BEGIN
                    Mn := IRP^.FindKeyValueSection('PRINTER', 'NUMBER', SecName, $FFFF);
                    IF TagArray[Mn] > 0 THEN BEGIN
                        PName := IRP^.FindKeyStringSection('PRINTER', 'NAME', SecName, '');
                        FName := IRP^.FindKeyStringSection('FILE', 'SERVER', SecName, '');
                        QName := IRP^.FindKeyStringSection('PRINTER', 'QUEUE', SecName, '');
                        IName := IRP^.FindKeyStringSection('PRINTER', 'INI', SecName, '');
                        PrinterType := IRP^.FindKeyStringSection('PRINTER', 'TYPE', SecName, 'TEXT');
                        HpRes := IRP^.FindKeyValueSection('FAXPRINT', 'HPRES', SecName, $FFFF);

                        NEW(QNP, Init(PName,
                                      FName,
                                      QName,
                                      IName,
                                      Mn,
                                      PrinterType,
                                      HpRes));
                        IF QNP = NIL THEN BEGIN
                            Done;
                            KillCylon;
                            DispErrorDeluxe('QNP.init fail', ErrorMessage(InitStatus), TRUE, Iam);
                            FAIL;
                        END;
                        QNP^.SetCopies(TagArray[Mn]);
                        QNP^.Pick(TRUE);
                        APPEND(QNP);
                        INC(Completed);
                        IF Completed = NumPrinters THEN
                            BREAK;
                    END;
                END;
            END;
            DISPOSE(IRP, Done);
        END
        ELSE BEGIN
            KillCylon;
            FAIL;
        END;
        KillCylon;
        IF Completed <> NumPrinters THEN
            TellUser('One or More Invalid Printer #s');
        COP := MyCOP;
        IF COP <> NIL THEN
            COP^.Draw;
    END;

    {--------------------------------------------------------------------}

TYPE
    PickNodeP      = ^PickNode;
    PickNode       = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(PName,
                                          FName,
                                          QName,
                                          IName          : STRING;
                                          Mn             : WORD;
                                          PrinterType    : STRING;
                                          HpRes          : WORD);
                         FUNCTION GetPickString : STRING;
                         PROCEDURE SetCopies(C : WORD);
                         PROCEDURE IncCopies;
                         PROCEDURE DecCopies;
                         FUNCTION GetCopies : WORD;
                         PROCEDURE Pick(P : BOOLEAN);
                         FUNCTION IsPicked : BOOLEAN;
                         PROCEDURE SpillGuts(VAR PName,
                                             FName,
                                             QName,
                                             IName          : STRING;
                                             VAR Mn         : WORD;
                                             VAR PrinterType : STRING;
                                             VAR HpRes      : WORD);

                         PRIVATE

                         Picked         : BOOLEAN;
                         MyHpRes,
                         MyMn,
                         MyCount        : WORD;
                         MyPrinterType  : TPrtType;
                         MyPName,
                         MyFName,
                         MyQName,
                         MyIName        : STRING[MAXNAMELEN];
                     END;

    {--------------------------------------------------------------------}

    CONSTRUCTOR PickNode.Init(PName,
                              FName,
                              QName,
                              IName          : STRING;
                              Mn             : WORD;
                              PrinterType    : STRING;
                              HpRes          : WORD);
    VAR
        Pt             : TPrtType;
    BEGIN
        IF NOT SingleListNode.Init THEN
            FAIL;
        MyCount := 0;
        MyPName := PName;
        MyFName := FName;
        MyQName := QName;
        MyIName := IName;
        MyMn := Mn;
        FOR Pt := LOW(TPrtType) TO HIGH(TPrtType) DO BEGIN
            IF CompUCString(PrinterType, PrtTypeLUT[Pt]) = EQUAL THEN
                BREAK;
        END;
        MyPrinterType := Pt;
        MyHpRes := HpRes;
    END;

    {--------------------------------------------------------------------}

    FUNCTION PickNode.GetPickString : STRING;
    BEGIN
        GetPickString := Pad(MyPName, 11) +
                         Pad(PLPrtTypeLUT[MyPrinterType], 8) +
                         Pad(Long2Str(MyMn), 8) +
                         Long2Str(MyCount);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PickNode.IncCopies;
    BEGIN
        INC(MyCount);
        IF MyCount > 255 THEN
            MyCount := 255;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PickNode.DecCopies;
    BEGIN
        IF MyCount > 0 THEN
            DEC(MyCount);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PickNode.SetCopies(C : WORD);
    BEGIN
        MyCount := C;
    END;

    {--------------------------------------------------------------------}

    FUNCTION PickNode.GetCopies : WORD;
    BEGIN
        GetCopies := MyCount;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PickNode.Pick(P : BOOLEAN);
    BEGIN
        Picked := P;
    END;

    {--------------------------------------------------------------------}

    FUNCTION PickNode.IsPicked : BOOLEAN;
    BEGIN
        IsPicked := Picked;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PickNode.SpillGuts(VAR PName,
                                 FName,
                                 QName,
                                 IName          : STRING;
                                 VAR Mn         : WORD;
                                 VAR PrinterType : STRING;
                                 VAR HpRes      : WORD);
    BEGIN
        PName := MyPName;
        FName := MyFName;
        QName := MyQName;
        IName := MyIName;
        Mn := MyMn;
        PrinterType := PrtTypeLUT[MyPrinterType];
        HpRes := MyHpRes;
    END;

    {--------------------------------------------------------------------}

TYPE
    {derive a picklist capable of selecting printer queues}
    {for use by the OOP interface only}

    OOPQSelP       = ^OOPQSel;
    OOPQSel        = OBJECT(PickList)
                         CTP            : CmdTablePtr;
                         PrinterList    : SingleListPtr;

                         CONSTRUCTOR Init(X1, Y1, X2, Y2 : BYTE;
                                          Colors         : ColorSet);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE KProcess;
                         FUNCTION GetPrinterList : SingleListPtr;
                         PROCEDURE SpillGuts(N              : WORD;
                                             VAR PName,
                                             FName,
                                             QName,
                                             IName          : STRING;
                                             VAR Mn         : WORD;
                                             VAR PrinterType : STRING;
                                             VAR HpRes      : WORD);
                         PROCEDURE ItemString(Item           : WORD;
                                              Mode           : pkMode;
                                              VAR IType      : pkItemType;
                                              VAR IString    : STRING); VIRTUAL;

                     END;

    {------------------------------------------------------------}

    {for use by the procedural interface only}
    CONSTRUCTOR OOPQSel.Init(X1, Y1, X2, Y2 : BYTE; Colors : ColorSet);
    VAR
        PickListOptions,
        PickWindowOptions : LONGINT;
        PNP            : PickNodeP;
        COP            : CylonObjPtr;
        Path           : PathStr;
        Mn,
        HpRes,
        I              : WORD;
        SecName,
        PName,
        FName,
        QName,
        IName,
        PrinterType    : STRING[MAXNAMELEN];
        IRP            : IniReaderP;
    BEGIN

        NEW(COP, Init('Initializing Printer List', 10));

        IF COP = NIL THEN BEGIN
            FAIL;
        END;

        COP^.Draw;

        PickWindowOptions := DefWindowOptions OR wBordered;
        PickListOptions := pkStick + pkAlterPageRow + pkMousePage + pkDrawActive +
                           pkSetDefault + pkFlexWrite;

        IF NOT PickList.InitAbstractDeluxe(X1, Y1, X2, Y2,
                                           Colors,
                                           PickWindowOptions,
                                           78,
                                           1,
                                           PickVertical,
                                           MultipleChoice,
                                           PickListOptions) THEN BEGIN
            DispErrorDeluxe('OOPQSel.Init Failure', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;
        CustomizeCommandProcessor(PickCommands);

        pkOptionsOn(pkProcessZero);
        SetSelectMarker(#251, '');

        GetMemCheck(CTP, KEYSETMAX);
        IF CTP = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            DispErrorDeluxe('OOPQSel.Init', 'Out of memory', TRUE, Iam);
            FAIL;
        END;

        FILLCHAR(CTP^, KEYSETMAX, #0);
        PickCommands.SetSecondaryKeyPtr(CTP, KEYSETMAX);

        PickCommands.AddSecondaryCommand(ccQuit, 1, OpKey.F1, 0);
        PickCommands.AddSecondaryCommand(ccUser2, 1, OpKey.F2, 0);
        PickCommands.AddSecondaryCommand(ccUser3, 1, OpKey.F3, 0);
        PickCommands.AddSecondaryCommand(ccUser4, 1, OpKey.F4, 0);
        PickCommands.AddSecondaryCommand(ccUser5, 1, OpKey.F5, 0);
        PickCommands.AddSecondaryCommand(ccUser6, 1, OpKey.F6, 0);
        PickCommands.AddSecondaryCommand(ccUser7, 1, OpKey.F7, 0);
        PickCommands.AddSecondaryCommand(ccUser8, 1, OpKey.F8, 0);
        PickCommands.AddSecondaryCommand(ccUser9, 1, OpKey.F9, 0);
        PickCommands.AddSecondaryCommand(ccUser10, 1, OpKey.F10, 0);
        PickCommands.AddSecondaryCommand(ccUser11, 1, TAB, 0);
        PickCommands.AddSecondaryCommand(ccUser12, 1, Space, 0);
        PickCommands.AddSecondaryCommand(ccUser13, 1, Minus, 0);
        PickCommands.AddSecondaryCommand(ccUser14, 1, PadMinus, 0);
        PickCommands.AddSecondaryCommand(ccUser15, 1, Plus, 0);
        PickCommands.AddSecondaryCommand(ccUser16, 1, PadPlus, 0);

        IF PickCommands.GetLastError <> 0 THEN
            RingBell;

        pkOptionsOn(pkProcessZero);

        PickCommands.cpOptionsOn(cpSwitchPriority);
        wFrame.AddScrollBar(frRR, 1, MAXLONGINT, Colors);

        SetSearchMode(PickStringSearch);
        AddSearchHeader(10, heBL);

        wFrame.AddHeader(SysMsg(2271) {'Print Que       #Copies'} , heTL);

        wFrame.SetSizeLimits(75, 5, 75, 20);
        RawWindow.EnableExplosions(8);
        wFrame.AddShadow(shBR, shSeeThru);

        NEW(PrinterList, Init);
        IF PrinterList = NIL THEN BEGIN
            DISPOSE(COP, Done);
            COP := NIL;
            DispErrorDeluxe('OOPQSel.Init Printerlist init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        Path := AddBackSlash(NEN^.SysDir) + 'NENPRINT.INI';
        COP^.Update;

        NEW(IRP, Init(Path, 512));
        IF IRP <> NIL THEN BEGIN
            FOR I := 1 TO IRP^.NumberOfSections DO BEGIN
                COP^.Update;
                SecName := IRP^.SectionHeading(I);
                IF POS('PRINTER', SecName) = 1 THEN BEGIN
                    QName := IRP^.FindKeyStringSection('PRINTER', 'QUEUE', SecName, '');
                    IName := IRP^.FindKeyStringSection('PRINTER', 'INI', SecName, '');
                    PrinterType := IRP^.FindKeyStringSection('PRINTER', 'TYPE', SecName, 'TEXT');
                    HpRes := IRP^.FindKeyValueSection('FAXPRINT', 'HPRES', SecName, $FFFF);
                    FName := IRP^.FindKeyStringSection('FILE', 'SERVER', SecName, '');
                    Mn := IRP^.FindKeyValueSection('PRINTER', 'NUMBER', SecName, $FFFF);
                    PName := IRP^.FindKeyStringSection('PRINTER', 'NAME', SecName, '');

                    {create a singlelist containing all the INI file stuff}
                    NEW(PNP, Init(PName,
                                  FName,
                                  QName,
                                  IName,
                                  Mn,
                                  PrinterType,
                                  HpRes));

                    IF PNP = NIL THEN BEGIN
                        DISPOSE(COP, Done);
                        COP := NIL;
                        DispErrorDeluxe('Failed to create printer PickNode', 'Insufficient Memory?', TRUE, Iam);
                        FAIL;
                    END;

                    PrinterList^.APPEND(PNP);
                END;
            END;
            DISPOSE(IRP, Done);
        END
        ELSE BEGIN
            DISPOSE(COP, Done);
            Done;
            FAIL;
        END;

        DISPOSE(COP, Done);

    END;

    {------------------------------------------------------------}

    {clean up the poopoo}
    DESTRUCTOR OOPQSel.Done;
    BEGIN
        DISPOSE(PrinterList, Done);
        FreeMemCheck(CTP, KEYSETMAX);
        PickList.Done;
    END;

    {------------------------------------------------------------}

    PROCEDURE OOPQSel.ItemString(Item           : WORD;
                                 Mode           : pkMode;
                                 VAR IType      : pkItemType;
                                 VAR IString    : STRING);

    BEGIN
        IString := '';
        IF (Item > 0) AND (Item <= PrinterList^.Size) THEN
            IString := PickNodeP(PrinterList^.Nth(Item))^.GetPickString;
    END;

    {------------------------------------------------------------}

    FUNCTION OOPQSel.GetPrinterList : SingleListPtr;
    BEGIN
        GetPrinterList := PrinterList;
    END;

    {------------------------------------------------------------}

    PROCEDURE OOPQSel.SpillGuts(N              : WORD;
                                VAR PName,
                                FName,
                                QName,
                                IName          : STRING;
                                VAR Mn         : WORD;
                                VAR PrinterType : STRING;
                                VAR HpRes      : WORD);
    BEGIN
        PickNodeP(PrinterList^.Nth(N))^.SpillGuts(PName,
                                                  FName,
                                                  QName,
                                                  IName,
                                                  Mn,
                                                  PrinterType,
                                                  HpRes);
    END;

    {------------------------------------------------------------}

    PROCEDURE OOPQSel.KProcess;
    VAR
        I,
        J,
        N,
        Choice         : WORD;
        AllDone        : BOOLEAN;
    BEGIN
        ClearFKeys;

        REPEAT
            AllDone := FALSE;

            SetTag(1, UnShift, 'EXIT');
            SetTag(INCKEY, UnShift, SysMsg(002269));
            SetTag(DECKEY, UnShift, SysMsg(002270));
            SetTag(DONEKEY, UnShift, SysMsg(002173));

            PickList.ChangeNumItems(PrinterList^.Size);
            PickList.Select;
            PickList.Process;

            Choice := GetLastChoice;

            CASE PickList.GetLastCommand OF
                ccError :
                    BEGIN
                        AllDone := TRUE;
                        DispErrorDeluxe(SysMsg(2272) {'Problem in'} , 'PQSel picklist', TRUE, Iam);
                        EXIT;
                    END;
                ccQuit :
                    BEGIN
                        FOR N := 1 TO PrinterList^.Size DO
                            PickNodeP(PrinterList^.Nth(N))^.SetCopies(0);
                        AllDone := TRUE;
                    END;
                ccUser12 :
                    BEGIN         {toggle selection}
                        IF ItemIsSelected(Choice) THEN BEGIN
                            DeselectItem(Choice);
                            PickNodeP(PrinterList^.Nth(Choice))^.SetCopies(0);
                        END
                        ELSE BEGIN
                            SelectItem(Choice);
                            PickNodeP(PrinterList^.Nth(Choice))^.SetCopies(1);
                        END;
                    END;
                ccUser0 + DONEKEY,
                ccSelect :
                    BEGIN
                        {first, clear all picked flags}
                        FOR N := 1 TO PrinterList^.Size DO
                            PickNodeP(PrinterList^.Nth(N))^.Pick(FALSE);

                        InitSequence(N);
                        WHILE HaveSelected(N) DO BEGIN
                            PickNodeP(PrinterList^.Nth(N))^.Pick(TRUE);
                            NextSelected(N);
                        END;
                        SetLastCommand(ccSelect);
                        AllDone := TRUE;
                    END;
                ccUser15,
                ccUser16,
                ccUser0 + INCKEY :
                    BEGIN         {Increment copies}
                        PickNodeP(PrinterList^.Nth(Choice))^.IncCopies;
                        SelectItem(Choice);
                    END;
                ccUser13,
                ccUser14,
                ccUser0 + DECKEY :
                    BEGIN         {decrement copies}
                        IF PickNodeP(PrinterList^.Nth(Choice))^.GetCopies > 0 THEN BEGIN
                            PickNodeP(PrinterList^.Nth(Choice))^.DecCopies;
                            IF PickNodeP(PrinterList^.Nth(Choice))^.GetCopies = 0 THEN
                                DeselectItem(Choice)
                        END
                        ELSE BEGIN
                            RingBell;
                            DeselectItem(Choice);
                        END;
                    END;
            END;

        UNTIL AllDone;

        ClearFKeys;
    END;

    {------------------------------------------------------------}

    CONSTRUCTOR QueueList.InitPickDeluxe(IniName        : PathStr;
                                         Mode           : TKPrintMode);
    VAR
        HpRes,
        Mn,
        I              : WORD;
        QNP            : QueueNodePtr;
        Path           : PathStr;
        PQP            : OOPQSelP;
        Colors         : ColorSet;
        W,
        H,
        Lx,
        Rx,
        TY,
        By             : BYTE;
        TUP            : KTellUserP;
        PrinterList    : SingleListPtr;
        PrinterType,
        PName,
        FName,
        QName,
        IName          : STRING;
        PNP            : PickNodeP;
    BEGIN
        LineNotifyFunc := NIL;
        WriteNotifyFunc := NIL;
        PageNotifyFunc := NIL;
        COP := NIL;
        PrintMode := Mode;
        QID := 0;

        IF NOT SingleList.Init THEN BEGIN
            DispErrorDeluxe('QueueList.InitPickDeluxe fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;

        GetCScheme(Red_Scheme, Colors);

        W := 34;
        H := 8;
        Lx := (ScreenWidth - W) DIV 2;
        Rx := Lx + W;
        TY := (ScreenHeight - H) DIV 2;
        By := TY + H;

        NEW(PQP, Init(Lx, TY, Rx, By, Colors));
        PQP^.KProcess;
        PQP^.ERASE;
        { check for user abort of picklist - fail if necessary}
        CASE PQP^.GetLastCommand OF
            ccQuit :
                BEGIN
                    NEW(TUP, Init('User abort of printout'));
                    DISPOSE(TUP, Done);
                    InitStatus := ecUserAbort;
                    DISPOSE(PQP, Done);
                    FAIL;
                END;
            ccSelect :
                BEGIN
                    { Now create the queuelistnodes from the picked printers}
                    PrinterList := PQP^.GetPrinterList;
                    FOR I := 1 TO PrinterList^.Size DO BEGIN
                        PNP := PickNodeP(PrinterList^.Nth(I));
                        IF PNP^.IsPicked THEN BEGIN
                            PNP^.SpillGuts(PName,
                                           FName,
                                           QName,
                                           IName,
                                           Mn,
                                           PrinterType,
                                           HpRes);

                            NEW(QNP, Init(PName,
                                          FName,
                                          QName,
                                          IName,
                                          Mn,
                                          PrinterType,
                                          HpRes));
                            IF QNP = NIL THEN BEGIN
                                Done;
                                DISPOSE(PQP, Done);
                                DispErrorDeluxe('QNP.init fail', ErrorMessage(InitStatus), TRUE, Iam);
                                FAIL;
                            END;
                            QNP^.SetCopies(PNP^.GetCopies);
                            QNP^.Pick(TRUE);
                            APPEND(QNP);
                        END;
                    END;          {FOR}
                END;
            ccError :
                BEGIN
                    DISPOSE(PQP, Done);
                    DispErrorDeluxe('Failure in printer picklist init',
                                    ErrorMessage(InitStatus),
                                    TRUE,
                                    Iam);
                    FAIL;
                END;
        END;                      {CASE}


        DISPOSE(PQP, Done);

    END;

    {--------------------------------------------------------------------}

    {- Destroy a list of printer queues an all the Attrib dynamic data}
    DESTRUCTOR QueueList.Done;
    BEGIN
        IF NP <> NIL THEN
            DISPOSE(NP, Done);
        Clear;
    END;

    {--------------------------------------------------------------------}

    {- return a pointer to the object containing the specified printer number}
    FUNCTION QueueList.GetQNodePtr(PrinterNumber : WORD) : QueueNodePtr;
    VAR
        Q              : WORD;
        QNP            : QueueNodePtr;
    BEGIN
        GetQNodePtr := NIL;
        FOR Q := 1 TO Size DO BEGIN
            QNP := QueueNodePtr(Nth(Q));
            IF QNP^.GetMyNumber = PrinterNumber THEN BEGIN
                GetQNodePtr := QNP;
                EXIT;
            END;
        END;                      {FOR}
    END;

    {--------------------------------------------------------------------}

    {- returns the printer model of a printer queue (LaserJet XVII, OkiData...)}
    FUNCTION QueueList.GetName(Q : WORD) : STRING;
    BEGIN
        GetName := '';
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetName := QueueNodePtr(Nth(Q))^.GetName;
    END;

    {--------------------------------------------------------------------}

    {- return the server name of a printer queue}
    FUNCTION QueueList.GetServer(Q : WORD) : STRING;
    BEGIN
        GetServer := '';
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetServer := QueueNodePtr(Nth(Q))^.GetServer;
    END;

    {--------------------------------------------------------------------}

    {- returns the queue name of a printer queue}
    FUNCTION QueueList.GetQueue(Q : WORD) : STRING;
    BEGIN
        GetQueue := '';
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetQueue := QueueNodePtr(Nth(Q))^.GetQueue;
    END;

    {--------------------------------------------------------------------}

    {- return the printer.ini filename for a printer queue}
    FUNCTION QueueList.GetIName(Q : WORD) : STRING;
    BEGIN
        GetIName := '';
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetIName := QueueNodePtr(Nth(Q))^.GetIName;
    END;

    {--------------------------------------------------------------------}

    {- select or unselect a printer queue}
    PROCEDURE QueueList.Pick(Q : WORD; Flg : BOOLEAN; Mode : SelectMode);
    VAR
        QNP            : QueueNodePtr;
    BEGIN
        CASE Mode OF
            PICKBYPOS :
                BEGIN
                    IF (Q > Size) OR (Q <= 0) THEN
                        EXIT;
                    QueueNodePtr(Nth(Q))^.Pick(Flg);
                END;
            PICKBYPRTNUM :
                BEGIN
                    QNP := GetQNodePtr(Q);
                    IF QNP <> NIL THEN
                        QNP^.Pick(Flg)
                    ELSE
                        DispErrorDeluxe('Can''t find', 'Printer #' + Long2Str(Q), TRUE, Iam);
                END;
        END;                      {CASE}
    END;

    {--------------------------------------------------------------------}

    {- return the picked (selected by user) status of a printer queue}
    FUNCTION QueueList.IsPicked(Q : WORD; Mode : SelectMode) : BOOLEAN;
    VAR
        QNP            : QueueNodePtr;
    BEGIN
        IsPicked := FALSE;
        CASE Mode OF
            PICKBYPOS :
                BEGIN
                    IF (Q > Size) OR (Q <= 0) THEN
                        EXIT;
                    IsPicked := QueueNodePtr(Nth(Q))^.IsPicked;
                END;
            PICKBYPRTNUM :
                BEGIN
                    QNP := GetQNodePtr(Q);
                    IF QNP <> NIL THEN
                        IsPicked := QNP^.IsPicked;

                END;
        END;                      {CASE}
    END;

    {--------------------------------------------------------------------}

    {used by itemstr}
    FUNCTION QueueList.ShowStr(Q : WORD) : STRING;
    BEGIN
        ShowStr := '';
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        ShowStr := Pad(GetName(Q), MAXNAMELEN) +
                   ' ' +
                   Pad(Long2Str(GetCopies(Q)), 3);
    END;

    {--------------------------------------------------------------------}

    {Loads attributes for queue from <printer>.INI file}
    FUNCTION QueueList.LoadAttr(Q : WORD; Mode : SelectMode) : BOOLEAN;
    VAR
        QNP            : QueueNodePtr;
        PDFName        : PathStr;
        DriveLtr       : String[2];

    BEGIN
        If Sys^.NovellSys Then
           DriveLtr := Sys^.SysDrive Else
           DriveLtr := 'C:';
        LoadAttr := FALSE;
        CASE Mode OF
            PICKBYPOS :
                BEGIN
                    IF (Q > Size) OR (Q <= 0) THEN BEGIN
                        DispErrorDeluxe('Invalid Printer selected', 'MaxPrinter=' + Long2Str(Size), TRUE, Iam);
                        EXIT;
                    END;
                    PDFName := ForceDrive(AddBackSlash(NEN^.SysDir) + GetIName(Q), DriveLtr);
                    LoadAttr := QueueNodePtr(Nth(Q))^.AAdd(PDFName);
                END;
            PICKBYPRTNUM :
                BEGIN
                    QNP := GetQNodePtr(Q);
                    IF QNP = NIL THEN BEGIN
                        DispErrorDeluxe('Invalid Printer #' + Long2Str(Q), 'MaxPrinter=' + Long2Str(Size), TRUE, Iam);
                        EXIT;
                    END;
                    PDFName := ForceDrive(AddBackSlash(NEN^.SysDir) + GetIName(Posn(QNP)), DriveLtr);
                    LoadAttr := QNP^.AAdd(PDFName);
                END;
        END;

    END;

    {--------------------------------------------------------------------}

    {unloads attributes for queue from <printer>.INI file}
    PROCEDURE QueueList.UnLoadAttr(Q : WORD; Mode : SelectMode);
    VAR
        QNP            : QueueNodePtr;
    BEGIN
        CASE Mode OF
            PICKBYPOS :
                BEGIN
                    IF (Q > Size) OR (Q <= 0) THEN
                        EXIT;

                    QueueNodePtr(Nth(Q))^.ADump;
                END;
            PICKBYPRTNUM :
                BEGIN
                    QNP := GetQNodePtr(Q);
                    IF QNP = NIL THEN
                        EXIT;
                    QNP^.ADump;
                END;
        END;                      {CASE}
    END;

    {--------------------------------------------------------------------}
    {Begin capture}
    FUNCTION QueueList.Capture(Q : WORD) : BOOLEAN;
    VAR
        QNP            : QueueNodePtr;
        PageLen        : INTEGER;
        Cpos,
        V              : WORD;
        Strg           : STRING;
        SaveDrive      : DriveName;
    BEGIN
        Capture := FALSE;

        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;

        CurrentCaptureQ := Q;

        QNP := QueueNodePtr(Nth(Q));
        CASE QNP^.GetPrtType OF
            ESENDFAX : ;
            ETEXT,
            EEPSON9,
            EEPSON24,
            EPCL4,
            EPCL5 :
                BEGIN
                    {$IFDEF BIGDGROUP}
                    SaveDrive := CurrentDriveID;
                    {$ELSE}
                    SaveDrive := SYS^.CurrentDriveID;
                    {$ENDIF}


                    IF NOT QNP^.AttachToServer THEN
                        EXIT;

                    ChangeDrive(SYS^.ToDrive);

                    QID := QNovell.GetQid(QNP^.GetQueue, 3);


                    {QID := GetQid(Q);}

                    IF QID <> 0 THEN BEGIN { use local (capture printer port) if QID = 0}
                        IF NP <> NIL THEN
                            DISPOSE(NP, Done);
                        CASE SYS^.CapturePrinter OF
                            0 :
                                NEW(NP, Init(LPT1, FALSE));
                            1 :
                                NEW(NP, Init(LPT2, FALSE));
                            2 :
                                NEW(NP, Init(LPT3, FALSE));
                        END;      {Case}

                        IF NP = NIL THEN BEGIN
                            DispErrorDeluxe('Queuelist.capture init fail', ErrorMessage(InitStatus), TRUE, Iam);
                            EXIT;
                        END;
                        EndCapture(SYS^.CapturePrinter); {ZZZZ}
                        IF SetCapturePrintQueue(SYS^.CapturePrinter, QID, GetPageLen(Q, PrintMode), FALSE) THEN BEGIN
                            StartCapture(SYS^.CapturePrinter);
                            Capture := TRUE;
                        END;
                    END
                    ELSE BEGIN
                        Strg := GetQueue(Q);
                        IF POS('LPT', Strg) = 0 THEN BEGIN
                            DispErrorDeluxe('I can''t find the ' + Strg + ' printer queue',
                                            'Check your INI file and network settings',
                                            TRUE,
                                            Iam);
                            EXIT;
                        END;

                        VAL(COPY(Strg, 4, 1), V, Cpos);
                        IF Cpos <> 0 THEN
                            V := 1;
                        IF NP <> NIL THEN
                            DISPOSE(NP, Done);

                        CASE V OF
                            1 :
                                NEW(NP, Init(LPT1, FALSE));
                            2 :
                                NEW(NP, Init(LPT2, FALSE));
                            3 :
                                NEW(NP, Init(LPT3, FALSE));
                        END;      {Case}

                        IF NP = NIL THEN BEGIN
                            DispErrorDeluxe('Queuelist.capture init fail#2', ErrorMessage(InitStatus), TRUE, Iam);
                            ChangeDrive(SaveDrive);
                            EXIT;
                        END;
                        Capture := TRUE;
                    END;
                END;
        END;                      {case}
        IF NOT ChangeDrive(SYS^.SysDrive) THEN
            {$I-}
            CHDIR(SYS^.SysDrive); {so there!  Nyea!}
            {$I+}
        IF NOT LoadAttr(Q, PICKBYPOS) THEN
            Capture := FALSE;
        ChangeDrive(SaveDrive);
    END;

    {--------------------------------------------------------------------}

    {End Capture}
    FUNCTION QueueList.EndCap(Q : WORD) : BOOLEAN;
    VAR
        SaveDrive      : DriveName;
    BEGIN
        {$IFDEF BIGDGROUP}
        SaveDrive := CurrentDriveID;
        {$ELSE}
        SaveDrive := SYS^.CurrentDriveID;
        {$ENDIF}
        CurrentCaptureQ := 0;

        ChangeDrive(SYS^.ToDrive);
        IF QID <> 0 THEN          { use local (capture printer port) if QID = 0}
            EndCapture(SYS^.CapturePrinter);

        IF NOT ChangeDrive(SYS^.SysDrive) THEN
            {$I-}
            CHDIR(SYS^.SysDrive);
            {$I+}
        UnLoadAttr(Q, PICKBYPOS);

        ChangeDrive(SaveDrive);

        IF NOT QueueNodePtr(Nth(Q))^.ReleaseServer THEN
            EXIT;

        IF NP <> NIL THEN
            DISPOSE(NP, Done);

        NP := NIL;
    END;

    {--------------------------------------------------------------------}

    {Send attrib string to queue}
    FUNCTION QueueList.SendAttr(Q : WORD; F : FMTTOKEN) : BOOLEAN;
    VAR
        THS            : HugeStrPtr;
        Result         : WORD;
    BEGIN
        SendAttr := FALSE;
        THS := GetAttr(Q, F);
        IF THS = NIL THEN BEGIN   {attribute is MIA}
            SendAttr := TRUE;
            EXIT;
        END;
        NP^.PrnPutBlock(THS^.Strg^, THS^.Len);
        SendAttr := NP^.PrnError = 0;
    END;

    {--------------------------------------------------------------------}

    {Send attrib string to queue}
    FUNCTION QueueList.SendSAttr(Q : WORD; Strg : STRING) : BOOLEAN;
    VAR
        THS            : HugeStrPtr;
        Result         : WORD;
    BEGIN
        SendSAttr := FALSE;
        THS := GetSAttr(Q, Strg);
        IF THS = NIL THEN BEGIN   {attribute is MIA}
            SendSAttr := TRUE;
            EXIT;
        END;
        NP^.PrnPutBlock(THS^.Strg^, THS^.Len);
        SendSAttr := NP^.PrnError = 0;
    END;

    {--------------------------------------------------------------------}

    {Set number of printout copies}
    PROCEDURE QueueList.SetCopies(Q : WORD; C : WORD; Mode : SelectMode);
    VAR
        QNP            : QueueNodePtr;
    BEGIN
        CASE Mode OF
            PICKBYPOS :
                BEGIN
                    IF (Q > Size) OR (Q <= 0) THEN
                        EXIT;
                    QueueNodePtr(Nth(Q))^.SetCopies(C);
                END;
            PICKBYPRTNUM :
                BEGIN
                    QNP := GetQNodePtr(Q);
                    IF QNP = NIL THEN
                        EXIT;
                    QNP^.SetCopies(C);
                END;
        END;
    END;

    {--------------------------------------------------------------------}

    {Get number of printout copies for queue}
    FUNCTION QueueList.GetCopies(Q : WORD) : WORD;
    BEGIN
        GetCopies := 0;
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetCopies := QueueNodePtr(Nth(Q))^.GetCopies;
    END;

    {--------------------------------------------------------------------}

    {Get Attr string for queue/attr}
    FUNCTION QueueList.GetAttr(Q : WORD; F : FMTTOKEN) : HugeStrPtr;
    BEGIN
        GetAttr := NIL;
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetAttr := QueueNodePtr(Nth(Q))^.ASearchAttr(F);
    END;

    {--------------------------------------------------------------------}

    {Get Attr string for queue/attr}
    FUNCTION QueueList.GetSAttr(Q : WORD; F : STRING) : HugeStrPtr;
    BEGIN
        GetSAttr := NIL;
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetSAttr := QueueNodePtr(Nth(Q))^.ASearchSAttr(F);
    END;

    {--------------------------------------------------------------------}

    {- parse a decimal mode string into a hugestr.  Use the hugestr to   }
    {  select the desired printers and the number of copies on each      }
    FUNCTION QueueList.DumbSelect(Strg : STRING) : BOOLEAN;
    VAR
        PHP            : HsParsePtr;
        THS            : HugeStrPtr;
        I,
        J              : WORD;
        QNP            : QueueNodePtr;
        AnySelected    : BOOLEAN;
    BEGIN
        DumbSelect := FALSE;
        IF LENGTH(Trim(Strg)) = 0 THEN BEGIN
            DispErrorDeluxe('Invalid printer number entered', 'Try again', FALSE, Iam);
            InitStatus := epWarning + ecInvalidData;
            EXIT;
        END;

        AnySelected := FALSE;
        NEW(PHP, Init);
        IF PHP = NIL THEN BEGIN
            DispErrorDeluxe('Queuelist.Dumbselect fail: parse init', ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;
        IF NOT PHP^.Parse(Strg, TDECI) THEN BEGIN
            DispErrorDeluxe('Invalid printer number entered', 'Try again', FALSE, Iam);
            InitStatus := epWarning + ecInvalidData;
            DISPOSE(PHP, Done);
            EXIT;
        END;
        THS := PHP^.GetHs;
        FOR I := 0 TO THS^.Len - 1 DO BEGIN
            J := BYTE(THS^.Strg[I]);
            QNP := GetQNodePtr(J);
            IF QNP = NIL THEN
                TellUser('#' + Long2Str(J) + SysMsg(2280) {' Is not a valid printer'} )
            ELSE BEGIN
                IF NOT IsPicked(J, PICKBYPRTNUM) THEN BEGIN
                    Pick(J, TRUE, PICKBYPRTNUM);
                    SetCopies(J, 1, PICKBYPRTNUM);
                    IF NOT LoadAttr(J, PICKBYPRTNUM) THEN BEGIN
                        DispErrorDeluxe('Queuelist.Dumbselect:LoadAttr', ErrorMessage(InitStatus), TRUE, Iam);
                        DISPOSE(PHP, Done);
                        EXIT;
                    END;
                    AnySelected := TRUE;
                END
                ELSE
                    SetCopies(J, GetCopies(J) + 1, PICKBYPRTNUM);
            END;
        END;                      {FOR}

        DISPOSE(PHP, Done);
        DumbSelect := AnySelected;
    END;

    {--------------------------------------------------------------------}

    {- Send a CR/LF delimited string to the current printer capture queue}
    FUNCTION QueueList.QWRITELN(Strg : STRING) : BOOLEAN;
    CONST
        CRLF           : ARRAY[1..2] OF CHAR = (#13, #10);
    VAR
        Result         : WORD;
    BEGIN
        QWRITELN := FALSE;
        IF NOT QWRITE(Strg) THEN
            EXIT;
        NP^.PrnPutBlock(CRLF[1], 2);
        QWRITELN := NP^.PrnError = 0;
    END;

    {--------------------------------------------------------------------}

    {- Send string to the current printer capture queue}
    FUNCTION QueueList.QWRITE(Strg : STRING) : BOOLEAN;
    BEGIN
        NP^.PrnPutBlock(Strg[1], LENGTH(Strg));
        QWRITE := NP^.PrnError = 0;
    END;

    {--------------------------------------------------------------------}

    {- Send a CR/LF delimited string to the current printer capture queue}
    {- obey left margin}
    {this assumes non-proportional font}
    FUNCTION QueueList.QWRITELNMGN(Strg : STRING) : BOOLEAN;
    CONST
        CRLF           : ARRAY[1..2] OF CHAR = (#13, #10);
    VAR
        Result         : WORD;
    BEGIN
        QWRITELNMGN := FALSE;
        IF NOT QWRITEMGN(Strg) THEN
            EXIT;
        NP^.PrnPutBlock(CRLF[1], 2);
        QWRITELNMGN := NP^.PrnError = 0;
    END;

    {--------------------------------------------------------------------}

    {- Send string to the current printer capture queue}
    {- obey left margin}
    {this assumes non-proportional font}
    FUNCTION QueueList.QWRITEMGN(Strg : STRING) : BOOLEAN;
    VAR
        MarginPad : STRING;
        LM : WORD;
    BEGIN
        Lm := GetLeftMargin(CurrentCaptureQ, PrintMode);
        IF Lm > 1 THEN BEGIN
            DEC(Lm);
            MarginPad := CharStr(' ', Lm);
            IF (LENGTH(Strg) + Lm) < 255 THEN
                Strg := MarginPad + Strg;
        END;
        NP^.PrnPutBlock(Strg[1], LENGTH(Strg));
        QWRITEMGN := NP^.PrnError = 0;
    END;

    {--------------------------------------------------------------------}

    {Get Fax Printer type for this queue}
    FUNCTION QueueList.GetPrtType(Q : WORD) : TPrtType;
    BEGIN
        GetPrtType := EPRTBAD;
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetPrtType := QueueNodePtr(Nth(Q))^.GetPrtType;
    END;

    {--------------------------------------------------------------------}

    {Get Hewlett Packard Fax Printer resolution for this queue}
    FUNCTION QueueList.GetHPRes(Q : WORD) : THPRes;
    BEGIN
        GetHPRes := EBAD;
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetHPRes := QueueNodePtr(Nth(Q))^.GetHPRes;
    END;

    {--------------------------------------------------------------------}
VAR
    LNFCOP         : CylonObjPtr;

    {- update Cylon and abort printing if user presses ESC}
    FUNCTION KPrnLineNotify(A, B : WORD) : BOOLEAN; FAR;
    BEGIN
        KPrnLineNotify := TRUE;
        IF LNFCOP <> NIL THEN BEGIN
            KPrnLineNotify := NOT LNFCOP^.Update;
            EXIT;
        END
    END;

    {--------------------------------------------------------------------}

    PROCEDURE QueueList.SetCylon(CP : CylonObjPtr);
    BEGIN
        KillCylon;
        COP := CP;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE QueueList.SetWriteNotify(WNP : WriteNotifyType);
    BEGIN
        WriteNotifyFunc := WNP;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE QueueList.SetLineNotify(LNP : LineNotifyType);
    BEGIN
        LineNotifyFunc := LNP;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE QueueList.SetPageNotify(PNP : PageNotifyType);
    BEGIN
        PageNotifyFunc := PNP;
    END;

    {--------------------------------------------------------------------}

    FUNCTION QueueList.PrintFile(Q              : WORD;
                                 FName          : PathStr;
                                 FileType       : TFileType;
                                 MyCOP          : CylonObjPtr) : BOOLEAN;
    VAR
        T              : TEXT;
        R              : WORD;
        Strg           : STRING;
        APrinter       : AbstractPrinterPtr;
        FaxPrn         : FaxPrinterPtr;

        {---------------------}

        PROCEDURE SetPrnFlag(Mask : BYTE; On : BOOLEAN);
        BEGIN
            IF On THEN
                APrinter^.fpOptionsOn(Mask)
            ELSE
                APrinter^.fpOptionsOff(Mask);
        END;
    BEGIN
        PrintFile := FALSE;

        COP := MyCOP;

        LNFCOP := COP;

        CASE FileType OF
            FAX :
                BEGIN
                    APrinter := NIL;
                    CASE GetPrtType(Q) OF
                        EPCL5,
                        EPCL4 :
                            BEGIN
                                CASE GetHPRes(Q) OF
                                    E150 :
                                        APrinter := NEW(KHP150PrinterPtr, Init(NP));
                                    E300 :
                                        APrinter := NEW(KHP300PrinterPtr, Init(NP));
                                END; {CASE}
                            END;
                        EEPSON9 :
                            APrinter := NEW(KEpson9PrinterPtr, Init(NP));
                        EEPSON24 :
                            APrinter := NEW(KEpson24PinPrinterPtr, Init(NP));
                    END;          {CASE}

                    IF (APrinter = NIL) THEN BEGIN
                        DispErrorDeluxe('Problem initializing FAX printer', '', TRUE, Iam);
                        EXIT;
                    END;

                    SetPrnFlag(fpPcl5Mode, (GetPrtType(Q) = EPCL5));
                    SetPrnFlag(fpScale, TRUE);
                    SetPrnFlag(fpHeader, FALSE);
                    SetPrnFlag(fpSuppressBlanks, FALSE);

                    NEW(FaxPrn, Init(APrinter));

                    { success? }
                    IF (FaxPrn <> NIL) THEN BEGIN
                        WITH FaxPrn^ DO BEGIN
                            {if SetLineNotify not called, then use cylon}
                            IF @LineNotifyFunc = NIL THEN
                                SetLineNotifyFunc(KPrnLineNotify)
                            ELSE
                                SetLineNotifyFunc(LineNotifyFunc);

                            {light 'um if ya got 'um}
                            IF @WriteNotifyFunc <> NIL THEN
                                SetWriteNotifyFunc(WriteNotifyFunc);

                            IF @PageNotifyFunc <> NIL THEN
                                SetPageNotifyFunc(PageNotifyFunc);

                            FaxPrn^.PrintFax('', FName);
                            IF (AsyncStatus <> 0) THEN
                                DispErrorDeluxe('FAX Print Async Error', Long2Str(AsyncStatus), TRUE, Iam);

                            DISPOSE(FaxPrn, Done);
                        END;
                        DISPOSE(APrinter, Done);
                    END
                    ELSE BEGIN
                        DispErrorDeluxe('FaxPrn init failure', ErrorMessage(InitStatus), TRUE, Iam);
                        EXIT;
                    END;
                    PrintFile := TRUE;
                END;
            PLAINTXT :
                BEGIN
                    ASSIGN(T, FName);
                    {$I-}
                    SYSTEM.RESET(T);
                    R := IORESULT;
                    {$I+}
                    IF R <> 0 THEN BEGIN
                        DispErrorDeluxe('Can''t open', FName + ' :' + ErrorMessage(R), TRUE, Iam);
                        EXIT;
                    END;
                    WHILE NOT EOF(T) DO BEGIN
                        READLN(T, Strg);
                        IF NOT QWRITELN(Strg) THEN BEGIN
                            DispErrorDeluxe('Error Writing to printer', Long2Str(NP^.PrnError), TRUE, Iam);
                            CLOSE(T);
                            EXIT;
                        END;
                    END;
                    CLOSE(T);
                    PrintFile := TRUE;
                END;
        END;                      {CASE}
    END;

    {--------------------------------------------------------------------}

    {- return the qth novell queue id code}
    FUNCTION QueueList.GetQid(Q : WORD) : LONGINT;
    BEGIN
        GetQid := 0;
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetQid := QueueNodePtr(Nth(Q))^.GetQid;
    END;

    {--------------------------------------------------------------------}

    {- return the qth page length}
    FUNCTION QueueList.GetPageLen(Q : WORD; Mode : TKPrintMode) : WORD;
    BEGIN
        GetPageLen := 0;
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetPageLen := QueueNodePtr(Nth(Q))^.GetPageLen(Mode);
    END;

    {--------------------------------------------------------------------}

    {- return the qth left margin}
    FUNCTION QueueList.GetLeftMargin(Q : WORD; Mode : TKPrintMode) : WORD;
    BEGIN
        GetLeftMargin := 0;
        IF (Q > Size) OR (Q <= 0) THEN
            EXIT;
        GetLeftMargin := QueueNodePtr(Nth(Q))^.GetLeftMargin(Mode);
    END;

    {--------------------------------------------------------------------}

    {- initialize a printer attribute object.  Aname is the name of the  }
    {attribute (EOJ, BOLD, SOS...) and T is the corresponding Token      }
    CONSTRUCTOR AttribObj.Init(AName : STRING; T : FMTTOKEN);
    BEGIN
        IF NOT HsParse.Init THEN BEGIN
            DispErrorDeluxe('AttribObj.init fail', ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;
        Name := AName;
        Tok := T;
    END;

    {--------------------------------------------------------------------}

    {- Destroy a singel attribute element}
    DESTRUCTOR AttribObj.Done;
    BEGIN
        HsParse.Done;
    END;

    {--------------------------------------------------------------------}

    {- return the name of this attribute}
    FUNCTION AttribObj.GetName : STRING;
    BEGIN
        GetName := Name;
    END;

    {--------------------------------------------------------------------}

    {- return the token of this attribute}
    FUNCTION AttribObj.GetTok : FMTTOKEN;
    BEGIN
        GetTok := Tok;
    END;

    {--------------------------------------------------------------------}

    {- return a pointer to this attributes hugestr}
    FUNCTION AttribObj.GetAttr : HugeStrPtr;
    BEGIN
        GetAttr := GetHs;
    END;

    {--------------------------------------------------------------------}

    {- initialize an empty attribute list and set the global values      }
    { IName is the name of the printer.ini file                          }
    CONSTRUCTOR AttribList.Init(IName : PathStr);
    VAR
        Path           : PathStr;
        IRP            : IniReaderP;
    BEGIN
        IF NOT SingleList.Init THEN BEGIN
            DispErrorDeluxe('SingleList.Init fail', '', TRUE, Iam);
            FAIL;
        END;

        {First read system defaults, if possible}
        Path := AddBackSlash(NEN^.SysDir) + IName;

        NEW(IRP, Init(Path, 512));

        IF IRP <> NIL THEN BEGIN
            CarriageWidth := IRP^.FindKeyValueSection('CARRIAGE', 'WIDTH', 'PRINTERXY', 80);
            NormpageLen := IRP^.FindKeyValueSection('NORMAL', 'PAGE', 'PRINTERXY', 59);
            ScriptPageLen := IRP^.FindKeyValueSection('SCRIPT', 'PAGE', 'PRINTERXY', 24);
            QueueStartPos := IRP^.FindKeyValueSection('CUE', 'START', 'PRINTERXY', 10);
            ScriptStartPos := IRP^.FindKeyValueSection('SCRIPT', 'START', 'PRINTERXY', 10);
        END
        ELSE BEGIN
            DispErrorDeluxe('Can''t open: ' + Path, 'AttribList.Init', TRUE, Iam);
            EXIT;
        END;

        DISPOSE(IRP, Done);
    END;

    {--------------------------------------------------------------------}

    {- return the Ith Attribute name in the list}
    FUNCTION AttribList.GetName(I : WORD) : STRING;
    BEGIN
        GetName := AttribObjPtr(Nth(I))^.GetName;
    END;

    {--------------------------------------------------------------------}

    {- return the page length for a given mode}
    FUNCTION AttribList.GetPageLen(Mode : TKPrintMode) : WORD;
    BEGIN
        GetPageLen := 0;
        CASE Mode OF
            Queue :
                GetPageLen := NormpageLen;
            Script :
                GetPageLen := ScriptPageLen;
            Other :
                GetPageLen := NormpageLen;
        END;
    END;

    {--------------------------------------------------------------------}

    {- return the left margin for a given mode}
    FUNCTION AttribList.GetLeftMargin(Mode : TKPrintMode) : WORD;
    BEGIN
        GetLeftMargin := 0;
        CASE Mode OF
            Queue :
                GetLeftMargin := QueueStartPos;
            Script :
                GetLeftMargin := ScriptStartPos;
            Other :
                GetLeftMargin := 1;
        END;
    END;

    {--------------------------------------------------------------------}

    {- return the Ith Attribute token in the list}
    FUNCTION AttribList.GetTok(I : WORD) : FMTTOKEN;
    BEGIN
        GetTok := AttribObjPtr(Nth(I))^.GetTok;
    END;

    {--------------------------------------------------------------------}

    {- return a pointer to the Ith Attribute hugestr}
    FUNCTION AttribList.GetAttr(I : WORD) : HugeStrPtr;
    BEGIN
        GetAttr := AttribObjPtr(Nth(I))^.GetAttr;
    END;

    {--------------------------------------------------------------------}

    {- look up the hugestr named AName.  Returns NIL if not found}
    FUNCTION AttribList.SearchSAttr(AName : STRING) : HugeStrPtr;
    VAR
        I              : WORD;
    BEGIN
        SearchSAttr := NIL;

        FOR I := 1 TO Size DO BEGIN
            IF CompUCString(AttribObjPtr(Nth(I))^.GetName, AName) = EQUAL THEN BEGIN
                SearchSAttr := AttribObjPtr(Nth(I))^.GetAttr;
                EXIT;
            END;
        END;
    END;

    {--------------------------------------------------------------------}

    {- look up the hugestr corresponding to Token F.  Returns NIL if not found}
    FUNCTION AttribList.SearchAttr(F : FMTTOKEN) : HugeStrPtr;
    VAR
        I              : WORD;
    BEGIN
        SearchAttr := NIL;

        FOR I := 1 TO Size DO BEGIN
            IF AttribObjPtr(Nth(I))^.GetTok = F THEN BEGIN
                SearchAttr := AttribObjPtr(Nth(I))^.GetAttr;
                EXIT;
            END;
        END;
    END;

    {--------------------------------------------------------------------}

END.
{--------------------------------------------------------------------}
{Das ist alles.}
{--------------------------------------------------------------------}

