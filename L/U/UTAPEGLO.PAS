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
UNIT UTAPEGLO;

INTERFACE

USES
    Filer,
    OpEntry,
    UBtree,
    UGLOBAL;


CONST
    NumKeywords    = 15;
    TotalKeys      = 20;          { 15 keywords + 5 others }
    FirstKeyword   = 6;
    DateKeys       = [2, 3];
    TapeListSize   = 300;         { Size of final selection menu on tape search }
    GetTapeSize    = 300;
    UTKeyLength    : ARRAY[1..TotalKeys] OF BYTE =
    (12, 4, 10, 10, 5, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11);

TYPE
    TapeStr        = STRING[10];
    TapeNumSt      = STRING[10];
    TapeVerSt      = STRING[2];
    KeyWordSt      = STRING[11];
    KeyArray       = ARRAY[1..NumKeywords] OF KeyWordSt;
    PKeywordSt     = STRING[11];
    PKeyArray      = ARRAY[1..NumKeywords] OF PKeywordSt;
    TapeTypeSt     = STRING[6];
    NameSt         = STRING[10];
    DateSt         = STRING[10];
    DateComp       = STRING[4];
    ReelSt         = STRING[10];
    SMPTESt        = STRING[15];
    TitleSt        = STRING[30];
    SlugSt         = STRING[30];
    AnyString      = STRING[80];

    Searches       = (Strict, Relaxed, Loose);

    Tape_Archive   = RECORD
                         Rebuild        : LONGINT; { For Delete/Reorg }
                         TapeNumber     : TapeNumSt;
                         TapeVer        : TapeVerSt; { For uniqueness }
                         KeyWords       : PKeyArray;
                         TapeType       : TapeTypeSt;
                         Reporter       : NameSt;
                         Photographer   : NameSt;
                         Date           : DateSt;
                         Reel           : ReelSt;
                         StartSMPTE     : SMPTESt;
                         EndSMPTE       : SMPTESt;
                         Title          : TitleSt;
                         Slug           : SlugSt;
                     END;
    TapeArcPtr     = ^Tape_Archive;

    Tape_Search    = RECORD
                         KeyWords       : KeyArray;
                         TapeType       : TapeTypeSt;
                         Reporter       : NameSt;
                         Photographer   : NameSt;
                         Date           : DateSt;
                         EndDate        : DateSt;
                         StartSMPTE     : SMPTESt;
                         EndSMPTE       : SMPTESt;
                         SDate          : DateComp;
                         EDate          : DateComp;
                     END;
    TapeSearchPtr  = ^Tape_Search;

    FieldID        = STRING[12];
    ReportFormat   = RECORD
                         Title          : AnyString;
                         Order          : INTEGER;
                         NumFields      : INTEGER;
                         LENGTH         : INTEGER;
                         Width          : INTEGER;
                         Page           : INTEGER;
                         Fields         : ARRAY[1..15] OF FieldID;
                         Header         : STRING[160];
                     END;
    ReportFormatPtr = ^ReportFormat;

    TapeListType   = ARRAY[1..GetTapeSize] OF BigString;
    TapeListPtr    = ^TapeListType;


VAR
    TapeData       : TapeArcPtr;
    SearchMask     : TapeSearchPtr;
    PrintFormat    : ReportFormat;
    TapeLibrary    : ^DBtree;
    IID            : IsamIndDescr;

CONST

    TapeLibraryOpen : BOOLEAN = FALSE;

    SecurityClearance : BYTE = 3;


VAR
    OldTapeData    : TapeArcPtr;
    ESRSearch      : EntryScreenPtr;
    ESRAdd         : EntryScreenPtr;
    Done           : BOOLEAN;
    Back, Frame    : BYTE;
    FieldsRequested : INTEGER;
    Found          : WORD;
    Choice         : INTEGER;
    SearchMode     : Searches;
    TapeList       : ^TapeListType;
    DeleteFlag     : BOOLEAN;
    PrintFlag      : BOOLEAN;
    UTMatchType    : CHAR;
    LibSize        : INTEGER;
    LineNum        : INTEGER;
    ReportName     : STRING[8];
    SelectedTape   : TapeStr;
    DosExit        : BOOLEAN;
    TapesInLib     : LONGINT;
    TLabel         : STRING[5];

CONST
    SelectHeading =
    '   ' + #$A9 + 'Tape   Time Slug                           Date         ' + #$AA;
    GetTapeHeading =
    '  ' + #$A9 + ' Time Slug                            Type Date          ' + #$AA;
    PrintSelectHeading =
    'Tape   Time Slug                           Date   ';
    PrintGetTapeHeading =
    'Time Slug                            Type Date   ';

    Locked         = TRUE;
    Unlocked       = FALSE;

    TimerVisible   : BOOLEAN = FALSE;

    PgUpPgDn       : BOOLEAN = TRUE;

    Zero           : LONGINT = 0;

    Descending     = FALSE;
    Ascending      = TRUE;

    ListPrefillMode : BOOLEAN = FALSE;

IMPLEMENTATION
END.

