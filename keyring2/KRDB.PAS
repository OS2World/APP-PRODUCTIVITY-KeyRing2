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
{$I OPDEFINE.INC}
{$I BTDEFINE.INC}
{$A+,B-,D+,E+,F+,G+,I+,L+,N-,O+,Q+,R+,S+,T-,V-,X+,Y+}
UNIT KRDB;

INTERFACE

USES
    Dos,
    Filer,
    IsamTool,
    KERROR,
    Message,
    OoFiler,
    {TQuery,}
    USE32,
    VARDEC;

CONST

    KR2DBFileName  = 'KR2.DAT';
    KR2DBKeyLen    = 60;

    KR2DBKeyNum    = 8;

    KR2DBRecIDKey  = 1;
    KR2DBRecTypeKey = 2;
    KR2DBLastUpdateKey = 3;
    KR2DBDescriptionKey = 4;
    KR2DBUserIDKey = 5;
    KR2DBSerialNumberKey = 6;
    KR2DBPasswordKey = 7;
    KR2DBIconKey   = 8;


TYPE
    PKR2DBFile     = ^TKR2DBFile;
    TKR2DBFile     = OBJECT(FileBlock)

                         glDataDir      : PathStr;
                         glStreamDir    : PathStr;
                         glCurRec       : TKR2Rec;
                         glCurKeyNr     : WORD;
                         glCurKeyStr    : IsamKeyStr;
                         glCurRefNr     : LONGINT;

                         RCOP           : CylonP;

                         CONSTRUCTOR Init(FName          : IsamFileBlockName;
                                          DataDir, StreamDir : STRING);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION BuildKey(VAR Rec; KeyNr : WORD) : IsamKeyStr; VIRTUAL;
                         FUNCTION EqualRec(VAR Rec1, Rec2) : BOOLEAN; VIRTUAL;
                         FUNCTION RecLen(VAR Rec)       : WORD; VIRTUAL;
                         PROCEDURE RebuildStatus(KeyNr : WORD; RecsRead, RecsWritten : LONGINT;
                                                 VAR Rec; Len   : WORD); VIRTUAL;
                         FUNCTION CreateID(VAR Rec)       : LONGINT;
                         FUNCTION AddNewRecord(VAR Rec        : TKR2Rec;
                                               VAR NewRecNum  : LONGINT) : WORD;
                         FUNCTION EraseRecord(RefNr : LONGINT; VAR Rec : TKR2Rec) : WORD;
                         FUNCTION EntityName(VAR Rec : TKR2Rec) : STRING;
                         PROCEDURE Purge;
                         FUNCTION UpDateRecord(VAR Rec : TKR2Rec) : WORD;
                     END;


VAR
    ReqdNetType    : NetSupportType;
    BTreeInit      : BOOLEAN;
    KR2DBInit      : BOOLEAN;
    KR2DBFile      : PKR2DBFile;
    Savemode       : BOOLEAN;

FUNCTION InitDBFiles : BOOLEAN;
FUNCTION DeInitDBFiles : BOOLEAN;
FUNCTION InitBTree : BOOLEAN;
FUNCTION DeInitBTree : BOOLEAN;

IMPLEMENTATION

USES
    DGLIB,
    MSGMGR,
    STRCRC,
    OpInline,
    OpDos,
    OpConst,
    OpRoot,
    OpDate,
    OPBCD,
    OpString,
    SysMsg,
    UTIAM;

TYPE
    PByteArray     = ^TByteArray;
    TByteArray     = ARRAY[1..$FFFF] OF BYTE;

    {------------}

    PROCEDURE Crypter(DataPtr        : POINTER; {!!.50}
                      DataLen        : LONGINT;
                      PostRead       : BOOLEAN;
                      HookPtr        : POINTER);
    VAR
        I              : LONGINT;
    BEGIN
        FOR I := 1 TO DataLen DO
            PByteArray(DataPtr)^[I] := PByteArray(DataPtr)^[I] XOR $FF;
    END;

    {------------}

    CONSTRUCTOR TKR2DBFile.Init(FName          : IsamFileBlockName;
                                DataDir,
                                StreamDir      : STRING);
    VAR
        IID            : IsamIndDescr;
        NetMode        : BOOLEAN;
        RCOPHeader     : STRING;
        {-----------------}
        PROCEDURE InitIID;
        BEGIN

            IID[KR2DBRecIDKey].KeyL := 8;
            IID[KR2DBRecIDKey].AllowDupK := FALSE;

            IID[KR2DBRecTypeKey].KeyL := KR2DBKeyLen;
            IID[KR2DBRecTypeKey].AllowDupK := TRUE;

            IID[KR2DBLastUpdateKey].KeyL := KR2DBKeyLen;
            IID[KR2DBLastUpdateKey].AllowDupK := TRUE;

            IID[KR2DBDescriptionKey].KeyL := KR2DBKeyLen;
            IID[KR2DBDescriptionKey].AllowDupK := TRUE;

            IID[KR2DBUserIDKey].KeyL := KR2DBKeyLen;
            IID[KR2DBUserIDKey].AllowDupK := TRUE;

            IID[KR2DBSerialNumberKey].KeyL := KR2DBKeyLen;
            IID[KR2DBSerialNumberKey].AllowDupK := TRUE;

            IID[KR2DBPasswordKey].KeyL := KR2DBKeyLen;
            IID[KR2DBPasswordKey].AllowDupK := TRUE;

            IID[KR2DBIconKey].KeyL := KR2DBKeyLen;
            IID[KR2DBIconKey].AllowDupK := TRUE;
        END;
        {---------------}

        FUNCTION Setup : BOOLEAN;
        BEGIN
            Setup := FALSE;
            AllocTempRec(SectSize);
            IF TempRecPtr = NIL THEN
                EXIT;
            Setup := TRUE;
        END;
        {---------------}

    BEGIN

        glDataDir := DataDir;
        glStreamDir := AddBackSlash(StreamDir);
        glCurKeyNr := KR2DBRecIDKey;
        glCurRefNr := 0;

        FILLCHAR(glCurKeyStr, SIZEOF(IsamKeyStr), 0);
        FILLCHAR(glCurRec, SIZEOF(TKR2Rec), 0);

        RCOP := NIL;
        NetMode := (BTNetSupported <> NoNet);

        IF FileBlock.Init(FName, FALSE, FALSE, Savemode, NetMode) THEN
            IF NOT Setup THEN
                FAIL
            ELSE
                EXIT;             {Existing file is Opened with success!}
        CASE IsamError OF
            9903 :
                IF YesNoCancel('Warning', 'Hobbes data file not found. Create New Database?', TRUE, BadMsg, BadMsg, BadMsg) = ctYes THEN BEGIN
                    InitIID;
                    IF FileBlock.Create(FName, SIZEOF(TKR2Rec), KR2DBKeyNum, IID,
                                        FALSE, FALSE, Savemode, NetMode) THEN
                        IF NOT Setup THEN
                            FAIL
                        ELSE
                            EXIT;
                END;              {9903}
            10010 :
                IF YesNoCancel('Warning', 'KR2DB index is defective. Rebuild?', TRUE, BadMsg, BadMsg, BadMsg) = ctYes THEN BEGIN
                    InitIID;
                    RCOPHeader := 'Rebuilding Hobbes Index';
                    NEW(RCOP, Init(RCOPHeader, LENGTH(RCOPHeader) + 4));
                    RCOP^.Draw;
                    IF FileBlock.Recover(FName, SIZEOF(TKR2Rec), KR2DBKeyNum, IID, TRUE,
                                         FALSE, FALSE, Savemode, NetMode) THEN BEGIN
                        DISPOSE(RCOP, Done);
                        RCOP := NIL;
                        IF NOT Setup THEN
                            FAIL
                        ELSE
                            EXIT;
                    END;
                END;              {10010}
            ELSE                  {*** CASE ***}
                IF YesNoCancel('Error!', ErrorMessage(ISAMERROROFST + IsamError) + '. Rebuild?', TRUE, BadMsg, BadMsg, BadMsg) = ctYes THEN BEGIN
                    InitIID;
                    RCOPHeader := 'Rebuilding Hobbes Index';
                    NEW(RCOP, Init(RCOPHeader, LENGTH(RCOPHeader) + 4));
                    RCOP^.Draw;
                    IF FileBlock.Recover(FName, SIZEOF(TKR2Rec), KR2DBKeyNum, IID, TRUE,
                                         FALSE, FALSE, Savemode, NetMode) THEN BEGIN
                        DISPOSE(RCOP, Done);
                        RCOP := NIL;
                        IF NOT Setup THEN
                            FAIL
                        ELSE
                            EXIT;
                    END;
                END;              {*** else CASE ***}
        END;                      {*** CASE ***}
        DispErrorDeluxe(FName,
                        ErrorMessage(ISAMERROROFST + IsamError),
                        TRUE, Iam);
        IF RCOP <> NIL THEN
            DISPOSE(RCOP, Done);
        RCOP := NIL;
        InitStatus := epFatal;
        FAIL;
    END;

    {---------------}

    DESTRUCTOR TKR2DBFile.Done;
    BEGIN
        IF RCOP <> NIL THEN
            DISPOSE(RCOP, Done);
        RCOP := NIL;
        FileBlock.Done;
    END;

    {---------------}

    FUNCTION TKR2DBFile.EntityName(VAR Rec : TKR2Rec) : STRING;
    BEGIN
        EntityName := Rec.CryptRec.Description + Rec.CryptRec.UserID + Rec.CryptRec.Password;
    END;

    {---------------}

    FUNCTION TKR2DBFile.BuildKey(VAR Rec; KeyNr : WORD) : IsamKeyStr;
    BEGIN
        WITH TKR2Rec(Rec).CryptRec DO
            CASE KeyNr OF
                KR2DBRecIDKey :
                    BuildKey := HexL(RecID);
                KR2DBRecTypeKey :
                    BuildKey := HexL(BYTE(RecType));
                KR2DBLastUpdateKey :
                    BuildKey := DateToSortString(BADDate - LastUpdate.D) +
                                TimeToSortString(BadTime - LastUpdate.T);
                KR2DBDescriptionKey :
                    BuildKey := PadTrim(StUpCase(Description), HIGH(IsamKeyStr));
                KR2DBUserIDKey :
                    BuildKey := PadTrim(StUpCase(UserID), HIGH(IsamKeyStr));
                KR2DBSerialNumberKey :
                    BuildKey := PadTrim(StUpCase(SerialNumber), HIGH(IsamKeyStr));
                KR2DBPasswordKey :
                    BuildKey := PadTrim(StUpCase(Password), HIGH(IsamKeyStr));
                KR2DBIconKey :
                    BuildKey := PadTrim(StUpCase(IconResource), HIGH(IsamKeyStr));
            END;
    END;

    {---------------}

    FUNCTION TKR2DBFile.EqualRec(VAR Rec1, Rec2) : BOOLEAN;
    VAR
        P1             : TKR2Rec ABSOLUTE Rec1;
        P2             : TKR2Rec ABSOLUTE Rec2;
    BEGIN
        EqualRec := (CompStruct(P1, P2, SIZEOF(P1)) = EQUAL);
    END;

    {---------------}

    FUNCTION TKR2DBFile.RecLen(VAR Rec)       : WORD;
    BEGIN
        RecLen := SIZEOF(TKR2Rec);
    END;

    {---------------}

    PROCEDURE TKR2DBFile.RebuildStatus(KeyNr : WORD; RecsRead, RecsWritten : LONGINT;
                                       VAR Rec; Len   : WORD);
    BEGIN
        {update a cylon here...}
        IF RCOP <> NIL THEN
            RCOP^.UpDate;
    END;

    {---------------}

    FUNCTION TKR2DBFile.CreateID(VAR Rec)       : LONGINT;
    VAR
        TmpID          : LONGINT;
    BEGIN
        TmpID := TimeMS;
        TmpID := CalcCRC(TmpID, EntityName(TKR2Rec(Rec)));
        CreateID := TmpID;
    END;

    {---------------}

    FUNCTION TKR2DBFile.AddNewRecord(VAR Rec        : TKR2Rec;
                                     VAR NewRecNum  : LONGINT) : WORD;
    VAR
        NbOfRec        : LONGINT;
    BEGIN
        NewRecNum := 0;
        Rec.RecVerMajor := DBVerMajor;
        Rec.RecVerMinor := DBVerMinor;
        REPEAT
            Rec.CryptRec.RecID := CreateID(Rec);
            AddRecord(NbOfRec, Rec);
        UNTIL IsamError <> 10230;
        NewRecNum := NbOfRec;
        AddNewRecord := IsamError;
    END;

    {---------------}

    FUNCTION TKR2DBFile.EraseRecord(RefNr : LONGINT; VAR Rec : TKR2Rec) : WORD;
    VAR
        F              : FILE;
        Status         : WORD;
    BEGIN
        DeleteRecord(RefNr, Rec);
        IF NOT IsamOk THEN BEGIN
            EraseRecord := IsamError;
            EXIT;
        END;
        EraseRecord := 0;
    END;

    {---------------}

    FUNCTION TKR2DBFile.UpDateRecord(VAR Rec : TKR2Rec) : WORD;
    CONST
        CurRefNr       : LONGINT = 0;
        CurKeyStr      : IsamKeyStr = '';
        CurRecord      : TKR2Rec = ();
    VAR
        Retries        : WORD;
        MyCOP          : CylonP;
    BEGIN
        UpDateRecord := 0;

        Rec.RecVerMajor := DBVerMajor;
        Rec.RecVerMinor := DBVerMinor;

        CurKeyStr := BuildKey(Rec, KR2DBRecIDKey);
        FindKey(KR2DBRecIDKey, CurRefNr, CurKeyStr);

        CASE IsamOk OF
            TRUE :
                BEGIN
                    {Record found. Modify or delete it!}
                    GetRec(CurRefNr, CurRecord);
                    IF IsamOk THEN BEGIN
                        ModifyRecord(CurRefNr, CurRecord, Rec);
                        IF NOT IsamOk THEN
                            DispErrorDeluxe('Slink update ModifyRecord IsamOk fail ' + Long2Str(CurRefNr),
                                            ErrorMessage(ISAMERROROFST + IsamError),
                                            TRUE, Iam);
                    END
                    ELSE
                        DispErrorDeluxe('Slink getrecord fail ' + Long2Str(CurRefNr),
                                        ErrorMessage(ISAMERROROFST + IsamError),
                                        TRUE, Iam);
                END;
            FALSE :
                BEGIN
                    IF IsamError <> 10200 THEN BEGIN
                        {B-Tree Error}
                        DispErrorDeluxe('Slink findrec fail',
                                        ErrorMessage(ISAMERROROFST + IsamError), TRUE, Iam);
                        UpDateRecord := IsamError;
                        EXIT;
                    END;
                    {Record is not found. Add New!}
                    AddRecord(CurRefNr, Rec);
                    IF NOT IsamOk THEN
                        DispErrorDeluxe('Slink add fail - ', ErrorMessage(ISAMERROROFST + IsamError),
                                        TRUE,
                                        Iam);
                END;
        END;
        UpDateRecord := IsamError;
    END;

    {-----------}

    PROCEDURE TKR2DBFile.Purge;
    VAR
        RCOPHeader     : STRING;
    BEGIN
        RCOPHeader := 'Rebuilding Hobbes Index';
        NEW(RCOP, Init(RCOPHeader, LENGTH(RCOPHeader) + 4));
        IF RCOP = NIL THEN
            EXIT;

        RCOP^.Draw;

        REBUILD;
        glCurRefNr := 0;
        glCurKeyStr := '';

        IF RCOP <> NIL THEN
            DISPOSE(RCOP, Done);
        RCOP := NIL;
    END;

    {----------}

    FUNCTION InitBTree : BOOLEAN;
    BEGIN
        IF BTreeInit THEN BEGIN
            InitBTree := TRUE;
            EXIT;
        END;
        IF BTInitIsam(ReqdNetType, MinimizeUseOfNormalHeap, 0) = 0 THEN
            {Error returned in IsamError} ;
        IF NOT IsamOk THEN BEGIN
            DispErrorDeluxe('Initializing Filer',
                            IsamErrorMessage(IsamError),
                            TRUE, Iam);
            BTreeInit := FALSE;
            InitBTree := FALSE;
            EXIT
        END;
        InitBTree := TRUE;
        BTreeInit := TRUE;
    END;

    {---------------}

    FUNCTION DeInitBTree : BOOLEAN;
    BEGIN
        DeInitBTree := TRUE;
        IF NOT BTreeInit THEN
            EXIT
        ELSE BEGIN
            BTExitIsam;
            BTreeInit := FALSE;
        END;
    END;

    {---------------}

    FUNCTION InitDBFiles : BOOLEAN;
    BEGIN
        {Initialize database files}
        InitDBFiles := FALSE;
        IF NOT KR2DBInit THEN BEGIN
            KR2DBFile := NEW(PKR2DBFile, Init(UserPrivatePath + KR2DBFileName,
                                              UserPrivatePath,
                                              UserPrivatePath));
            IF NOT IsamOk THEN BEGIN
                DispErrorDeluxe('Can not init KR2DB file',
                                IsamErrorMessage(IsamError),
                                TRUE,
                                Iam);
                EXIT;
            END;
            KR2DBInit := TRUE;
            BTSetCharConvert(KR2DBFile^.IFB,
                             Crypter,
                             NIL,
                             FALSE);

        END;
        InitDBFiles := TRUE;
    END;

    {---------------}

    FUNCTION DeInitDBFiles : BOOLEAN;
    BEGIN
        DeInitDBFiles := TRUE;
        IF KR2DBInit THEN BEGIN
            KR2DBInit := FALSE;
            DISPOSE(KR2DBFile, Done);
            IF NOT IsamOk THEN BEGIN
                DispErrorDeluxe('KR2DB data file may be corrupt',
                                IsamErrorMessage(IsamError),
                                TRUE,
                                Iam);
                DeInitDBFiles := FALSE;
            END;
        END;
    END;

    {---------------}

BEGIN
    BTreeInit := FALSE;
    KR2DBInit := FALSE;
    KR2DBFile := NIL;
    ReqdNetType := NoNet;
END.

    {---------------}
    {---------------}

