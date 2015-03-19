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
{$A-,V-,O+,F+}

{---------------------------------------------------------}
{ (C) 1990 NewsMaker Systems.                             }
{ Tape Library subsystem.                                 }
{---------------------------------------------------------}

UNIT UTape;

INTERFACE

USES
    BROWSER,
    Dos,
    Filer,
    NetWare,
    NumKeys,
    OpCmd,
    OpCol16,
    OpCrt,
    OpDate,
    OpDos,
    OpEditor,
    OpEntry,
    OpFEdit,
    OpField,
    OpFrame,
    OpKey,
    OpMemo,
    OpMouse,
    OpRoot,
    OpString,
    OpWindow,
    Printer,
    QDrives,
    QHdrRec,
    QInput,
    QNovell,
    QGlobal,
    QScreen,
    Reindex,
    Reorg,
    UASYNCH,
    UBtree,
    UCalndr,
    UColors,
    UCOMM,
    UDIALOG,
    UFkey,
    UGLOBAL,
    UKey,
    ULib,
    UMAIL,
    UMatrix,                      {UVscreen,}
    UMENU,
    UMSg,
    UService,
    UTAPEGLO,
    UTAPE2,
    UTIMER,
    UWindow,
    UWsData;

PROCEDURE OpenTapeLibrary;
PROCEDURE CloseTapeLibrary;
PROCEDURE SearchTapeLibrary;
PROCEDURE SelectTape(VAR Tape : TapeStr);
PROCEDURE AddTapeToLibrary(VAR TapeCont);

CONST
    DefaultPrinter : STRING[10] = '';
    SecurityRequested : BYTE = 0;
    TapeLibraryName : PathStr = 'TAPELIB';


IMPLEMENTATION

    {--------------------------------------------------------------------}
    PROCEDURE CreateTapeLibrary;
    BEGIN
        IF NOT BtreeInitialized THEN
            NEW(TapeLibrary, Init);
        WITH TapeLibrary^ DO BEGIN
            DefineTapeLibraryKeys;
            Create(StUpCase(TapeLibraryName), LibSize, TotalKeys, FixedRecs);
        END;
        TapeLibraryOpen := TapeLibrary^.LastBTstatus = 0;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE OpenTapeLibrary;
    BEGIN
        IF TapeLibraryOpen THEN EXIT;
        NEW(TapeLibrary, Init);
        IF DatabaseExists(TapeLibraryName) THEN
            TapeLibrary^.Open(TapeLibraryName, FixedRecs)
        ELSE
            CreateTapeLibrary;
        TapesInLib := TapeLibrary^.NumRecs;
        TapeLibraryOpen := TapeLibrary^.LastBTstatus = 0;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE CloseTapeLibrary;
    BEGIN
        IF TapeLibraryOpen THEN
            TapeLibrary^.CLOSE;
        DISPOSE(TapeLibrary, Done);
        TapeLibraryOpen := FALSE;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE AddTapeToLibrary(VAR TapeCont);
    VAR
        RecNo          : LONGINT;
        I, J, Key, TV  : INTEGER;
        TapeContents   : TapeArcPtr ABSOLUTE TapeCont;

    BEGIN
        IF TapeLibrary^.LockFile THEN BEGIN
            WITH TapeContents^ DO BEGIN
                TapeContents^.Rebuild := Zero;
                TapeLibrary^.AddRecord(TapeContents^, LibSize);
                RecNo := TapeLibrary^.RecordPos;
                TV := 0;
                TapeVer := '00';
                AddKey(1, Pad(TapeNumber, 10) + TapeVer);
                IF TapeLibrary^.LastBTstatus = 10230 THEN BEGIN
                    REPEAT
                        INC(TV);
                        TapeVer := LeftPadCh(Trim(HexW(TV)), '0', 2);
                        AddKey(1, Pad(TapeNumber, 10) + TapeVer);
                    UNTIL TapeLibrary^.LastBTstatus = 0;
                END;
                IF TapeLibrary^.LastBTstatus = 0 THEN BEGIN
                    AddDateKey(2, Date);
                    AddKey(3, Reporter);
                    AddKey(4, Photographer);
                    AddKey(5, TapeType);
                    J := 5;       { First computed keyword offset is 6 }
                    Key := 10;    { First key number = 11 }
                    BuildKeywords(TapeContents, J, Key, Slug);
                    BuildKeywords(TapeContents, J, Key, Title);
                    FOR I := 1 TO NumKeywords DO
                        IF KeyWords[I] <> '' THEN
                            AddKey(I + 5, KeyWords[I]);
                    TapeLibrary^.SEEK(RecNo);
                    TapeLibrary^.Update(TapeContents^, LibSize);
                END
                ELSE BEGIN
                    IF Dialog(SysMsg(000796) {'Duplicate Tape Number'} , 'ADD',
                              Red, 'OK', '') <> 9 THEN EXIT;
                END;
            END;
            TapeLibrary^.UnlockFile;
            TapesInLib := TapeLibrary^.NumRecs;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE AddTape;
    VAR 
        Date       : DateSt;
    BEGIN
(*
    with ESRAdd^ DO BEGIN
        wFastWrite(SysMsg(000797){'Enter Tape Info'},1,2,Attr(Blue,LightGreen));
        wFastWrite(SysMsg(000798){'Press Enter to Add, Esc to leave'},17,2,Attr(Blue,LightGreen));
      end;
*)
        Done := FALSE;
        ESRAdd^.AsCurId := 0;
        FILLCHAR(TapeData^, LibSize, #0);
        TapeData^.Date := '  -  -    ';
        WHILE NOT Done DO BEGIN
            ESRAdd^.Process;
            CASE ESRAdd^.GetLastCommand OF
                ccDone,
                ccQuit : Done := TRUE;
                ccUser0 : BEGIN
                              IF Trim(TapeData^.TapeNumber) <> '' THEN BEGIN
                                  AddTapeToLibrary(TapeData);
                                  Date := TapeData^.Date;
                                  FILLCHAR(TapeData^, LibSize, #0);
                                  TapeData^.Date := Date;
                                  ESRAdd^.AsCurId := 0;
                              END;
                          END;
            END;
        END;
        ESRAdd^.ERASE;
    END;

    {--------------------------------------------------------------------}

    FUNCTION GetLibraryKey(Num : WORD) : STRING;
    BEGIN
        WITH TapeData^ DO
            CASE Num OF
                1 : BEGIN
                        IF Trim(Pad(Trim(TapeNumber), 10) + TapeVer) = TapeVer THEN
                            GetLibraryKey := ''
                        ELSE
                            GetLibraryKey := Pad(Trim(TapeNumber), 10) + TapeVer;
                    END;
                2 : BEGIN
                        IF Trim(Date) = '-  -' THEN
                            GetLibraryKey := ''
                        ELSE
                            GetLibraryKey := Date;
                    END;
                3 : GetLibraryKey := Trim(Reporter);
                4 : GetLibraryKey := Trim(Photographer);
                5 : GetLibraryKey := Trim(TapeType);
                6..TotalKeys : GetLibraryKey := Trim(KeyWords[Num - 5]);
            END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE BuildRow(VAR RR         : RowRec;
                       KeyNr          : INTEGER;
                       VAR DatS;
                       DatLen         : WORD);
    BEGIN
        WITH RR, Tape_Archive(DatS) DO BEGIN
            Row := Pad(TapeData^.TapeNumber, 6) + ' ' +
                   Pad(COPY(TapeData^.StartSMPTE, 1, 4), 4) + ' ' +
                   Pad(TapeData^.Slug, 30) + ' ' +
                   COPY(TapeData^.Date, 7, 4) + '-' +
                   COPY(TapeData^.Date, 1, 2) + '-' +
                   COPY(TapeData^.Date, 4, 2);
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DisplayRow(VAR RR : RowRec; KeyNr, RowNr, StartRow : INTEGER;
                         HighLight : BOOLEAN; VAR HorizOfs : INTEGER);
                    VAR
                        Atr        : BYTE;
    BEGIN
        WITH RR, NENColorSet DO BEGIN
            Atr := FieldColor;
            IF HighLight THEN
                Atr := SelFieldColor;
            WriteStr(WinX + 6, WinY + StartRow + RowNr - 1, Row, Atr);
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ListTapes;
    VAR
        Index          : WORD;
        Security       : INTEGER;
        XPos, Ypos, YDepth : INTEGER;
        DataLen        : WORD;
        Selected       : LONGINT;
        KeyStr         : IsamKeyStr;
        ExitKey        : Bktype;
        Result         : INTEGER;
        Done           : BOOLEAN;

    BEGIN
        XPos := 13;
        Ypos := 7;
        YDepth := 12;
        IF TapeLibrary^.NumRecs < YDepth THEN
            YDepth := TapeLibrary^.NumRecs;
        OpenWindow(XPos, Ypos, XPos + 61, Ypos + YDepth, SysMsg(000808) {' All Tapes '} , Red_Scheme);

        Index := 2;               { List by Date}
        Done := FALSE;
        Selected := 1;
        KeyStr := '';
        WHILE NOT Done DO BEGIN
            PgUpPgDn := FALSE;
            BrowseKeyPtr := @UKey.GetKey;
            ExitKey := BkNone;
            Coords[ScreenNum]^.wFastWrite(SelectHeading, 1, 2, Attr(Red, LightRed));
            DisplayCount(Long2Str(TapeLibrary^.NumRecs) + SysMsg(000809) {' Tapes'} , 11);
            Result := Browse(TapeLibrary^.FB,
                             FALSE, { has variable recs }
                             Index, { Key #             }
                             '', #255, { Low, High key     }
                             2, YDepth, { Start, Num rows   }
                             TapeData^, { Data buffer       }
                             DataLen, { length returned   }
                             Selected, { item # selected   }
                             KeyStr, { key selected      }
                             ExitKey, { Key used to exit  }
                             NIL, { Special task      }
                             @BuildRow, { Build row proc.   }
                             @DisplayRow); { Display Row proc. }
            IF Result = 0 THEN BEGIN
                IF ExitKey <> BkQuit THEN BEGIN
                    Security := SecurityClearance;
                    SecurityClearance := 1; { Cannot update from browse }
                    DisplayTape(Done);
                    SecurityClearance := Security;
                END
                ELSE
                    Done := TRUE;
            END
            ELSE
                Done := TRUE;
        END;
        CloseWindow;
        PgUpPgDn := TRUE;
    END;

    {--------------------------------------------------------------------}

    { Get all items on a specified tape }
    PROCEDURE GetTape;
    VAR 
        Escape     : BOOLEAN;
        TapeNo         : TapeNumSt;
        First          : BOOLEAN;
        SearchDone     : BOOLEAN;
        I              : INTEGER;
        XPos, Ypos     : INTEGER;
        YDepth         : INTEGER;
    BEGIN
        TapeNo := '';
        Found := 0;
        DrawTimer;
        ResetTimer;
        GetInput(SysMsg(000816) {'Enter Tape Number'} , SysMsg(000817) {'GET TAPE'} , Green, '#', 10, TapeNo, Escape);
        IF Escape THEN BEGIN
            EraseTimer;
            EXIT;
        END;
        TapeNo := StUpCase(Trim(TapeNo));

        OpenMessage(SysMsg(000818) {'Locating Tape # '} + TapeNo, BrightYellow_Scheme);

        ResetTimer;
        StartTimer;

        First := TRUE;
        SearchDone := FALSE;
        WHILE NOT SearchDone DO BEGIN
            WITH TapeLibrary^ DO BEGIN
                IF First THEN
                    TapeLibrary^.Search(Pack6BitKeyUC(Pad(TapeNo, 10) + '00', KeySize(UTKeyLength[1])), 1)
                ELSE
                    Next;
                First := FALSE;
                IF LastBTstatus = 0 THEN BEGIN
                    ReadTape(Unlocked);
                    IF Trim(TapeNo) = Trim(COPY(TapeData^.TapeNumber, 1, 9)) THEN BEGIN
                        INC(Found);
                        IF Found > TapeListSize THEN BEGIN
                            StopTimer;
                            IF Dialog(SysMsg(000819) {'Too many items!'} , SysMsg(000794) {'SEARCH'} , Red,
                                      'OK', '') = 0 THEN ;
                            DEC(Found);
                            CloseWindow;
                            CloseMessage;
                            ClearEscape;
                            EXIT;
                        END;
                        WriteCentred(3, SysMsg(000820) {'Found: '} + Pad(Long2Str(Found), 6));
                        TapeList^[Found] := Pad(COPY(TapeData^.StartSMPTE, 1, 4), 4) + ' ' +
                                            Pad(TapeData^.Slug, 30) + ' ' +
                                            Pad(TapeData^.TapeType, 5) + ' ' +
                                            COPY(TapeData^.Date, 7, 4) + '-' +
                                            COPY(TapeData^.Date, 1, 2) + '-' +
                                            COPY(TapeData^.Date, 4, 2);
                        TapeList^[Found] := Pad(TapeList^[Found], 55) +
                                            Long2Str(Position);
                    END
                    ELSE
                        SearchDone := TRUE;
                END
                ELSE
                    SearchDone := TRUE;
            END;
        END;

        CloseMessage;

        IF Found = 0 THEN BEGIN
            StopTimer;
            IF Dialog(SysMsg(000821) {'Cannot locate Tape '} + TapeNo, SysMsg(000817) {'GET TAPE'} , Red, 'Ok', '') = 0 THEN ;
            EraseTimer;
            EXIT;
        END;

        StopTimer;

        XPos := 13;
        Ypos := 7;
        YDepth := 13;
        IF Found < YDepth THEN
            YDepth := Found + 1;

        SetupSort(Ascending, 45, 54); { openmenu will reset to defaults }
        OpenMenu(XPos, Ypos, XPos + 61, Ypos + YDepth, TapeList^, Found, 55, Sort,
                 GetTapeHeading,
                 SysMsg(000822) {' Tape '} + TapeNo + SysMsg(000823) {' Contents'} , Red_Scheme, I);

        DisplayCount(Long2Str(Found) + SysMsg(000824) {' Items'} , 11);

        TextAttr := Attr(Red, LightCyan);
        WriteCentred(YDepth, SysMsg(000825) {'F6 to Print'} );
        ClearFKeys;

        IF DeleteFlag THEN EXIT;  { We were called by DeleteTape }

        EnableFunctionKeyExit := TRUE;
        WHILE NOT EscapePressed DO BEGIN
            SetTag(6, UnShift, SysMsg(000750) {'PRINT'} );
            Choice := GetMenu;
            IF Choice <> 0 THEN BEGIN
                IF Choice < 1000 THEN
                    ReadAndDisplayTape(Choice)
                ELSE
                    IF Choice DIV 1000 = 6 THEN BEGIN
                        PrintSelectedTapes(2);
                    END;
            END;
        END;
        CloseWindow;
        EraseTimer;
        EnableFunctionKeyExit := FALSE;
        ClearFKeys;

    END;

    {--------------------------------------------------------------------}

    PROCEDURE DeleteItem(Num : INTEGER);
    VAR 
        Key        : INTEGER;
        RecNo          : LONGINT;
    BEGIN
        IF NOT Str2Long(Trim(COPY(TapeList^[Num], 56, 10)), RecNo) THEN
            EXIT;
        TapeLibrary^.SEEK(RecNo);
        ReadTape(Locked);
        IF TapeLibrary^.LastBTstatus = 0 THEN BEGIN
            FOR Key := 1 TO TotalKeys DO BEGIN
                IF Key <> 2 THEN
                    DeleteKey(Key, GetLibraryKey(Key))
                ELSE
                    DeleteDateKey(Key, GetLibraryKey(Key))
            END;
            IF TapeData^.Rebuild = Zero THEN BEGIN
                TapeLibrary^.DeleteRecord;
                IF TapeLibrary^.LastBTstatus <> 0 THEN
                    IF Dialog(SysMsg(000194) {'Error '} + Long2Str(TapeLibrary^.LastBTstatus),
                              SysMsg(000826) {'DELETE'} , Red, 'OK', '') = 0 THEN ;
            END
            ELSE BEGIN
                IF Dialog(SysMsg(000827) {'Already Deleted!'} , SysMsg(000826) {'DELETE'} , Magenta, 'OK', '') = 0 THEN ;
            END;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE DeleteTape;
    VAR 
        I, Key     : INTEGER;
        RecNo          : LONGINT;

    BEGIN
        DeleteFlag := TRUE;
        GetTape;
        IF Found <> 0 THEN BEGIN
            FOR I := 1 TO Found DO BEGIN
                MoveSelection(I);
                IF NOT Str2Long(Trim(COPY(TapeList^[I], 56, 10)), RecNo) THEN
                    EXIT;
                TapeLibrary^.SEEK(RecNo);
                ReadTape(Unlocked);
                IF Dialog(SysMsg(000828) {'Delete '} +
                          TapeData^.Slug + '?',
                          SysMsg(000826) {'DELETE'} , Brown,
                          SysMsg(64), SysMsg(65)) = 1 THEN
                    DeleteItem(I);
            END;
            CloseWindow;
            EraseTimer;
            EnableFunctionKeyExit := FALSE;
            ClearEscape;
        END;
        DeleteFlag := FALSE;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DumpTapeLibrary;
    VAR 
        Rec        : LONGINT;
        TFile          : PathStr;
        TF             : TEXT;
        Line           : STRING[100];
        I, J           : INTEGER;
        Escape         : BOOLEAN;
        First          : BOOLEAN;
    CONST
        QC             = #$27 + ',' + #$27;
        q              = #$27;
    BEGIN
        TFile := '';
        GetInput(SysMsg(000845) {'Text Filename?'} , SysMsg(000846) {'DUMP TAPE'} , Green, '', 30, TFile, Escape);
        IF Escape THEN EXIT;
        ASSIGN(TF, TFile);
    {$I-}
        RESET(TF);
        IF IORESULT = 0 THEN BEGIN
            IF Dialog(SysMsg(000847) {'File already exists!'} , SysMsg(000848) {'DUMP FILE'} , LightRed, 'OK', '') = 0 THEN ;
            CLOSE(TF);
            EXIT;
        END;
        REWRITE(TF);
        IF IORESULT <> 0 THEN BEGIN
            IF Dialog(SysMsg(000849) {'Cannot Create File'} , SysMsg(000848) {'DUMP FILE'} , LightRed, 'OK', '') = 0 THEN ;
            EXIT;
        END;
    {$I+}
        OpenMessage(SysMsg(000850) {'Writing to '} + TFile, BrightYellow_Scheme);
        First := TRUE;
        WITH TapeLibrary^ DO BEGIN
            REPEAT
                BEGIN
                    UpdateTime(FALSE);
                    IF First THEN
                        Search(#0, 2)
                    ELSE
                        Next;
                    IF LastBTstatus = 0 THEN BEGIN
                        ReadTape(Escape);
                        First := FALSE;
                        Line := '';
                        WITH TapeData^ DO BEGIN
                            FOR J := 1 TO LENGTH(Slug) DO
                                IF (Slug[J] = ',') OR
                                (Slug[J] = #$27) OR
                                (Slug[J] < #$20) THEN BEGIN
                                    System.DELETE(Slug, J, 1);
                                END;
                            FOR J := 1 TO LENGTH(Title) DO
                                IF (Title[J] = ',') OR
                                (Title[J] = #$27) OR
                                (Title[J] < #$20) THEN BEGIN
                                    System.DELETE(Title, J, 1);
                                END;
                            Line := q + Slug + QC + Title + QC;
                            FOR I := 1 TO 5 DO
                                IF KeyWords[I] <> '' THEN BEGIN
                                    KeyWords[I] := Trim(KeyWords[I]);
                                    FOR J := 1 TO LENGTH(KeyWords[I]) DO
                                        IF (KeyWords[I][J] = ',') OR
                                        (KeyWords[I][J] = #$27) OR
                                        (KeyWords[I][J] < #$20) THEN BEGIN
                                            System.DELETE(KeyWords[I], J, 1);
                                        END;
                                    Line := Line + Trim(KeyWords[I]) + '-';
                                END;
                            IF Line[LENGTH(Line)] = '-' THEN
                                DEC(Line[0]);
                            Line := Line + QC + COPY(Date, 9, 2) + '-' + COPY(Date, 1, 5) + QC +
                                    Trim(TapeNumber) + '-';
                            IF TapeType = SysMsg(000851) {'NATL'} THEN
                                Line := Line + SysMsg(000851) {'NATL'} + q
                            ELSE
                                Line := Line + Trim(StartSMPTE) + q;
                        END;
                        WRITELN(TF, Line);
                        WriteCentred(2, TapeData^.Slug);
                    END;
                END;
            UNTIL LastBTstatus = 10250;
        END;
        CLOSE(TF);
        CloseMessage;
    END;

    {--------------------------------------------------------------------}
    FUNCTION BuildaKey(VAR DatS; KeyNr : INTEGER) : IsamKeyStr;
    VAR 
        Drec       : Tape_Archive ABSOLUTE DatS;
        Keys           : IsamKeyStr;
    BEGIN
        MOVE(DatS, TapeData^, LibSize);
        IF TapeData^.Rebuild <> 0 THEN BEGIN
            BuildaKey := '';
            EXIT;
        END;
        Keys := GetLibraryKey(KeyNr);
        IF KeyNr <> 2 THEN
            BuildaKey := Pack6BitKeyUC(Keys, KeySize(UTKeyLength[KeyNr]))
        ELSE
            BuildaKey := LongToKey(DateStringToDate('mm-dd-yyyy', Keys));
        IF KeyNr = 1 THEN
            WriteCentred(2, SysMsg(000852) {'Indexing '} + Pad(TapeData^.TapeNumber, 10) + TapeData^.TapeVer);
    END;

{$F+}
    {--------------------------------------------------------------------}
    FUNCTION ConvertRec(VAR DatSold; VAR DatSnew) : BOOLEAN;
    VAR 
        OldRec     : Tape_Archive ABSOLUTE DatSold;
    BEGIN
        MOVE(OldRec, DatSnew, LibSize);
        TextAttr := Attr(Yellow, Black);
        IF OldRec.Rebuild <> 0 THEN BEGIN
            WriteCentred(2, SysMsg(000853) {'Deleting '} + Pad(OldRec.TapeNumber, 10) + OldRec.TapeVer);
            ConvertRec := FALSE;
            EXIT;
        END;
        WriteCentred(2, SysMsg(000854) {'Adding   '} + Pad(OldRec.TapeNumber, 10) + OldRec.TapeVer);
        ConvertRec := TRUE;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE RebuildLibrary;
    VAR 
        I          : INTEGER;
        Size           : LONGINT;
    BEGIN
        Menu^[1] := SysMsg(000064) {'Yes '} ;
        Menu^[2] := SysMsg(000856) {'DOS (Yes)'} ;
        Menu^[3] := SysMsg(65);
        DosExit := FALSE;
        CASE AskUser(27, 9,       { x1,y1,x2,y2 }
                     SysMsg(000855) {'Rebuild Database?'} ,
                     SysMsg(000857) {'REBUILD'} , { as for Dialog }
                     White_Scheme, { main colors }
                     Blue,        { Title background }
                     Brown,       { Box background }
                     LightBlue,   { First letter }
                     Blue,        { Remaining letters }
                     3,           { Number of items }
                     Menu^) OF    { item list }
            0, 3 : EXIT;
            2 : DosExit := TRUE;
        END;
        OpenMessage(SysMsg(000858) {'Rebuilding..Please Wait'} , Yellow_Scheme);
        DefineTapeLibraryKeys;
        MOVE(TapeLibrary^.IID, IID, SIZEOF(IsamIndDescr));
        AutoAllocate := FALSE;
        CloseTapeLibrary;
        Size := LibSize;
        CASE Dialog('Rebuild Type', 'TAPELIB', Blue, 'Reorg', 'Index') OF
            1 : ReorgFileBlock(TapeLibraryName,
                               Size,
                               20,
                               IID,
                               Size,
                               @UTape.BuildaKey,
                               @UTape.ConvertRec);
            2 : ReIndexFileBlock(TapeLibraryName,
                                 Size,
                                 20,
                                 IID,
                                 @UTape.BuildaKey);
        END;
        CloseMessage;
        IF DosExit THEN BEGIN
            StuffKey($011B);
            StuffKey($011B);
        END;
        OpenTapeLibrary;
        AutoAllocate := TRUE;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE MemoryFail;
    BEGIN
        WRITELN(SysMsg(000859) {'Not enough memory!'} );
        HALT(1);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE AllocateMemory;
    BEGIN
        NEW(SearchMask);
        IF SearchMask = NIL THEN
            MemoryFail;
        NEW(TapeData);
        IF TapeData = NIL THEN
            MemoryFail;
        NEW(OldTapeData);
        IF OldTapeData = NIL THEN
            MemoryFail;
        NEW(TapeList);
        IF TapeList = NIL THEN
            MemoryFail;
        NEW(Matrix);
        IF Matrix = NIL THEN
            MemoryFail;
        Matrix^.Init;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE DeAllocateMemory;
    BEGIN
        DISPOSE(TapeList);
        DISPOSE(TapeData);
        DISPOSE(OldTapeData);
        DISPOSE(SearchMask);
        DISPOSE(ESRSearch, Done);
        DISPOSE(ESRAdd, Done);
        Matrix^.Done;
        DISPOSE(Matrix);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE SetSecurityLevel;
    VAR 
        NetPathBase, BaseFlags,
        Rights, DirRights, StationRights : BYTE;
        DrvPathMap     : NovellPath;
        CurDir         : PathStr;
        Drive, Flags   : BYTE;
    BEGIN
        GETDIR(0, CurDir);
        IF (UPCASE(CurDir[1]) IN['A'..'E']) OR(NOT Sys^.NovellSys) THEN BEGIN
            IF SecurityRequested <> 0 THEN
                SecurityClearance := SecurityRequested
            ELSE
                SecurityClearance := 3; { Top level if local }
            EXIT;
        END
        ELSE BEGIN
            Drive := GetDirHandle(CurDir[1], Flags);
            GetDriveBaseMap(Drive, NetPathBase, BaseFlags);
            IF GetDirPath(Drive, CurDir) = 0 THEN ;
            IF GetDirRights(Drive, CurDir, Rights) = 0 THEN ;

            IF Rights AND 128 <> 0 THEN SecurityClearance := 3 { M }
            ELSE IF Rights AND 32 <> 0 THEN SecurityClearance := 2 { P }
            ELSE SecurityClearance := 1;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE SearchTapeLibrary;
    VAR 
        M, I       : INTEGER;
    BEGIN

        AllocateMemory;

        InitSearchScreen;
        InitEntryScreen;

        SetSecurityLevel;

        DeleteFlag := FALSE;
        Filer.DatExtension := 'DBF';
        Savemode := TRUE;
        PrintFlag := FALSE;
        DosExit := FALSE;
        LibSize := SIZEOF(Tape_Archive);

        SavePrompt;
        UData^.PromptLine := 0;
        OpenFKeyDisplay(23);

        IF NENFlag THEN BEGIN
            ReserveHeapSpace(40000); { Give Btree 20K if under NEN }
            {      ReserveHeapSpace(MemAvail-30000);} { Give Btree 20K if under NEN }
            TapeLibraryName := 'TAPELIB';
        END
        ELSE
            ReserveHeapSpace(MEMAVAIL - 40000); { 40K if stand-alone }
        ReserveHeapSpace(40000);  { Give Btree 20K if under NEN }

        IF NENFlag THEN
            TapeLibraryName := NEN^.TapeLibDir + '\' + TapeLibraryName;

        OpenTapeLibrary;
        IF NOT TapeLibraryOpen THEN BEGIN
            IF BtreeFailure THEN
                IF Dialog(SysMsg(92), 'Tapelib', Red, 'OK', '') = 0 THEN
                ELSE
                    IF Dialog(SysMsg(000860) {'DB Error '} +
                        Long2Str(TapeLibrary^.LastBTstatus),
                        SysMsg(000861) {'Tape Library'} ,
                        Red, 'OK', '') = 0 THEN ;
            DeAllocateMemory;
            CloseFKeyDisplay;
            EXIT;
        END;

        CASE SecurityClearance OF
            3 : BEGIN
                    Menu^[1] := SysMsg(000862) {'Search for Tape'} ;
                    Menu^[2] := SysMsg(000863) {'Get Tape Contents'} ;
                    Menu^[3] := SysMsg(000864) {'Browse thru Tapes'} ;
                    Menu^[4] := SysMsg(000865) {'Add a Tape'} ;
                    Menu^[5] := SysMsg(000866) {'Delete a Tape'} ;
                    Menu^[6] := SysMsg(000867) {'Maintenance'} ;
                    Menu^[7] := SysMsg(000868) {'Dump to File'} ;
                    Menu^[8] := SysMsg(000869) {'Print Reports'} ;
                    Menu^[9] := SysMsg(000660) {'Quit'} ;
                    I := 9;
                END;
            2 : BEGIN
                    Menu^[1] := SysMsg(000862) {'Search for Tape'} ;
                    Menu^[2] := SysMsg(000863) {'Get Tape Contents'} ;
                    Menu^[3] := SysMsg(000864) {'Browse thru Tapes'} ;
                    Menu^[4] := SysMsg(000865) {'Add a Tape'} ;
                    Menu^[5] := SysMsg(000660) {'Quit'} ;
                    I := 5;
                END;
            1 : BEGIN
                    Menu^[1] := SysMsg(000862) {'Search for Tape'} ;
                    Menu^[2] := SysMsg(000863) {'Get Tape Contents'} ;
                    Menu^[3] := SysMsg(000864) {'Browse thru Tapes'} ;
                    Menu^[4] := SysMsg(000660) {'Quit'} ;
                    I := 4;
                END;
        END;

        OpenMenu(6, 5, 27, 6 + I, Menu^, I, 17, NoSort, '', SysMsg(000870) {'Action'} , Orange_Scheme, M);
        WHILE NOT EscapePressed DO BEGIN
            M := GetMenu;
            IF M = 0 THEN BEGIN
                IF NOT DosExit THEN
                    IF NOT NENFlag THEN
                        IF NOT UserSaysYes(SysMsg(000871) {'Quit Tape Library?'} , EscapemeansNo) THEN
                            ClearEscape;
            END;
            CASE SecurityClearance OF
                3 : CASE M OF     { Can do everything }
                        1 : SearchTapes;
                        2 : GetTape;
                        3 : ListTapes;
                        4 : AddTape;
                        5 : DeleteTape;
                        6 : RebuildLibrary;
                        7 : DumpTapeLibrary;
                        8 : PrintReports;
                        9 : ForceEscape;
                    END;
                2 : CASE M OF     { Can Add & Update, but not Delete }
                        1 : SearchTapes;
                        2 : GetTape;
                        3 : ListTapes;
                        4 : AddTape;
                        5 : ForceEscape;
                    END;
                1 : CASE M OF     { Can only read }
                        1 : SearchTapes;
                        2 : GetTape;
                        3 : ListTapes;
                        4 : ForceEscape;
                    END;
            END;
        END;

        CloseWindow;

        CloseFKeyDisplay;

        UData^.PromptLine := 25;
        RestorePrompt;

        CloseTapeLibrary;

        DeAllocateMemory;

    END;

    {--------------------------------------------------------------------}
    PROCEDURE SelectTape(VAR Tape : TapeStr);
    VAR 
        M, I       : INTEGER;
    BEGIN

        AllocateMemory;

        InitSearchScreen;
        InitEntryScreen;

        SetSecurityLevel;

        SecurityClearance := 1;

        DeleteFlag := FALSE;
        Filer.DatExtension := 'DBF';
        Savemode := TRUE;
        PrintFlag := FALSE;
        LibSize := SIZEOF(Tape_Archive);

        SavePrompt;
        UData^.PromptLine := 0;
        OpenFKeyDisplay(23);

        IF NENFlag THEN BEGIN
            ReserveHeapSpace(MEMAVAIL - 30000); { Give Btree 20K if under NEN }
            TapeLibraryName := 'TAPELIB';
        END
        ELSE
            ReserveHeapSpace(MEMAVAIL - 40000); { 40K if stand-alone }

        IF NENFlag THEN
            TapeLibraryName := NEN^.TapeLibDir + '\' + TapeLibraryName;

        OpenTapeLibrary;
        IF NOT TapeLibraryOpen THEN BEGIN
            IF Dialog(SysMsg(000860) {'DB Error '} + Long2Str(TapeLibrary^.LastBTstatus), SysMsg(000861) {'Tape Library'} ,
                      Red, 'Ok', '') = 0 THEN ;
        END;

        ListPrefillMode := TRUE;
        SelectedTape := '';
        SearchTapes;
        ListPrefillMode := FALSE;
        Tape := SelectedTape;

        CloseFKeyDisplay;

        UData^.PromptLine := 25;
        RestorePrompt;

        CloseTapeLibrary;

        DeAllocateMemory;
    END;

END.

