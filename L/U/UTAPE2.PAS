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
{$A+,B-,D+,E+,F+,G+,I-,L+,N-,O+,P-,Q-,T-,V-,X+,Y+}

UNIT UTAPE2;

INTERFACE
USES
    {UBtrieve,}
    UService,
    UTAPEGLO;

CONST
    DefaultPrinter : STRING[10] = '';
TYPE
    UTSTYPE        = STRING[100];

FUNCTION KeySize(Len : BYTE) : BYTE;
PROCEDURE DefineTapeLibraryKeys;
PROCEDURE AddKey(Key : INTEGER; KeySt : UTSTYPE);
PROCEDURE AddDateKey(Key : INTEGER; KeySt : UTSTYPE);
PROCEDURE BuildKeywords(TapeContents   : TapeArcPtr;
                        VAR FC, FK : INTEGER; Field : STRING);
PROCEDURE DisplayCount(Msg : STRING; Len : INTEGER);
PROCEDURE DisplayTape(VAR Accept : BOOLEAN);
PROCEDURE ReadAndDisplayTape(Select : INTEGER);
PROCEDURE PrintSelectedTapes(Format : INTEGER);
PROCEDURE DeleteKey(Key : INTEGER; KeySt : UTSTYPE);
PROCEDURE DeleteDateKey(Key : INTEGER; KeySt : UTSTYPE);
PROCEDURE InitSearchScreen;
PROCEDURE InitEntryScreen;
PROCEDURE PrintReports;
PROCEDURE ReadTape(Lock : BOOLEAN);
PROCEDURE SearchTapes;

IMPLEMENTATION
USES
    BROWSER,
    Dos,
    Filer,
    NumKeys,
    OpCmd,
    OpCol16,
    OpCrt,
    OpDate,
    OpEntry,
    OpField,
    OpFrame,
    OpString,
    OpWindow,
    Printer,
    QHdrRec,
    QNovell,
    {TPMOUSE,ZZZZ}
    UBtree,
    UCalndr,
    UColors,
    UFkey,
    UGLOBAL,
    ULib,
    UMatrix,
    UMENU,
    UMSg,
    UTIMER,
    UWindow;
{$F+}
    {--------------------------------------------------------------------}
    { Computes 6-bit packed size of key, input is unpacked length        }
    FUNCTION KeySize(Len : BYTE) : BYTE;
    BEGIN
        KeySize := (Len * 6) DIV 8 + ORD((Len * 6) MOD 8 <> 0);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE DefineTapeLibraryKeys;
    VAR I          : INTEGER;
    BEGIN
        WITH TapeLibrary^ DO
        BEGIN
            FILLCHAR(IID, SIZEOF(IID), #0);
            DefineKey(1, KeySize(UTKeyLength[1]), Unique);
            DefineKey(2, UTKeyLength[2], AllowDuplicates);
            FOR I := 3 TO TotalKeys DO
                DefineKey(I, KeySize(UTKeyLength[I]), AllowDuplicates);
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE AddKey(Key : INTEGER; KeySt : UTSTYPE);
    BEGIN
        IF KeySt = '' THEN EXIT;
        TapeLibrary^.AddIndex(Key, Pack6BitKeyUC(Trim(KeySt), KeySize(UTKeyLength[Key])));
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DeleteKey(Key : INTEGER; KeySt : UTSTYPE);
    BEGIN
        IF KeySt = '' THEN EXIT;
        TapeLibrary^.DeleteIndex(Key, Pack6BitKeyUC(Trim(KeySt), KeySize(UTKeyLength[Key])));
        IF TapeLibrary^.LastBTstatus <> 0 THEN
            IF Dialog(SysMsg(000726) {'Key: '} +
                      Long2Str(Key) + ' ' +
                      KeySt, SysMsg(000727) {'ERROR'} , Red, 'OK', '') = 0 THEN ;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ChangeKey(Key : INTEGER; OldKeySt : UTSTYPE; KeySt : UTSTYPE);
    BEGIN
        IF OldKeySt = KeySt THEN EXIT;
        DeleteKey(Key, OldKeySt);
        AddKey(Key, KeySt);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE AddDateKey(Key : INTEGER; KeySt : UTSTYPE);
    BEGIN
        IF KeySt = '' THEN EXIT;
        TapeLibrary^.AddIndex(Key,
                              LongToKey(DateStringToDate('mm/dd/yyyy', Trim(KeySt))));
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DeleteDateKey(Key : INTEGER; KeySt : UTSTYPE);
    BEGIN
        IF KeySt = '' THEN EXIT;
        KeySt := LongToKey(DateStringToDate('mm/dd/yyyy', Trim(KeySt)));
        TapeLibrary^.DeleteIndex(Key, KeySt);
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ChangeDateKey(Key : INTEGER; OldKeySt : UTSTYPE; KeySt : UTSTYPE);
    BEGIN
        DeleteDateKey(Key, OldKeySt);
        AddDateKey(Key, KeySt);
    END;

    {--------------------------------------------------------------------}

    FUNCTION DuplicateKey(TapeContents   : TapeArcPtr;
                          VAR Keyword : KeyWordSt; Num : INTEGER) : BOOLEAN;
    VAR I          : INTEGER;
    BEGIN
        WITH TapeContents^ DO
        BEGIN
            FOR I := 1 TO NumKeywords DO
                IF I <> Num THEN
                    IF Trim(Keyword) = Trim(KeyWords[I]) THEN
                    BEGIN
                        Keyword := '';
                        DuplicateKey := TRUE;
                        EXIT;
                    END;
            DuplicateKey := FALSE;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE BuildKeywords(TapeContents   : TapeArcPtr;
                            VAR FC, FK : INTEGER; Field : STRING);
    CONST
        Delims         : SET OF CHAR = [' ', '-'];
    VAR I          : INTEGER;
        KeyW           : KeyWordSt;
    BEGIN
        WITH TapeContents^ DO
        BEGIN
            FOR I := 1 TO WordCount(Field, Delims) DO
            BEGIN
                INC(FK);
                INC(FC);
                IF FK <= TotalKeys THEN
                BEGIN
                    KeyW := ExtractWord(I, Field, Delims);
                    IF NOT DuplicateKey(TapeContents, KeyW, FC) THEN
                        KeyWords[FC] := KeyW;
                END
            END;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE LoadReport(Form : PathStr);
    VAR F          : TEXT;
        Line           : AnyString;
        Tag            : STRING[15];
        Temp           : STRING[15];
        I, J           : INTEGER;
    CONST
        Delims         : SET OF CHAR = [' ', #$0D, #$0A];
    BEGIN
        ASSIGN(F, Form);
    {$I-}
        RESET(F);
        IF IORESULT <> 0 THEN
            EXIT;
    {$I+}
        FILLCHAR(PrintFormat, SIZEOF(ReportFormat), #0);
        PrintFormat.LENGTH := 62;
        WHILE NOT EOF(F) DO
        BEGIN
            READLN(F, Line);
            Line := StUpCase(Trim(Line));
            IF Line[1] <> '*' THEN
                WITH PrintFormat DO
                BEGIN
                    Tag := ExtractWord(1, Line, Delims);
                    IF Tag = SysMsg(000728) {'NAME:'} THEN
                        Title := Trim(COPY(Line, 7, 70));
                    IF Tag = SysMsg(000729) {'ORDER:'} THEN
                    BEGIN
                        Temp := ExtractWord(2, Line, Delims);
                        IF Temp = SysMsg(000730) {'TAPENUMBER'} THEN
                            Order := 1;
                        IF Temp = SysMsg(000731) {'DATE'} THEN
                            Order := 2;
                        IF Temp = SysMsg(000732) {'KEYWORD'} THEN
                            Order := 3;
                    END;
                    IF Tag = SysMsg(000733) {'FORM:'} THEN
                    BEGIN
                        Temp := ExtractWord(2, Line, Delims);
                        VAL(Temp, LENGTH, I);
                    END;
                    IF Tag = SysMsg(000734) {'WIDTH:'} THEN
                    BEGIN
                        Temp := ExtractWord(2, Line, Delims);
                        VAL(Temp, Width, I);
                    END;
                    IF COPY(Tag, 1, 5) = SysMsg(000735) {'FIELD'} THEN
                    BEGIN
                        Temp := Line[6];
                        IF Line[7] <> ':' THEN
                            Temp := Temp + Line[7];
                        VAL(Temp, I, J);
                        Fields[I] := ExtractWord(2, Line, Delims);
                        INC(NumFields);
                    END;
                END;
        END;
        CLOSE(F);
        WITH PrintFormat DO
        BEGIN
            FOR I := 1 TO NumFields DO
            BEGIN
                IF Fields[I] = SysMsg(000730) {'TAPENUMBER'} THEN
                    Header := Header + Pad(SysMsg(000736) {'TAPE'} , 10);
                IF Fields[I] = SysMsg(000731) {'DATE'} THEN
                    Header := Header + Pad(SysMsg(000731) {'DATE'} , 11);
                IF Fields[I] = SysMsg(000737) {'SLUG'} THEN
                    Header := Header + Pad(SysMsg(000737) {'SLUG'} , 31);
                IF Fields[I] = SysMsg(000738) {'TITLE'} THEN
                    Header := Header + Pad(SysMsg(000738) {'TITLE'} , 31);
                IF Fields[I] = SysMsg(000739) {'REPORTER'} THEN
                    Header := Header + Pad(SysMsg(000739) {'REPORTER'} , 11);
                IF Fields[I] = SysMsg(000740) {'PHOTOGRAPHER'} THEN
                    Header := Header + Pad(SysMsg(000741) {'PHOTOG.'} , 11);
                IF Fields[I] = SysMsg(000742) {'TAPETYPE'} THEN
                    Header := Header + Pad(SysMsg(000743) {'TYPE'} , 7);
                IF Fields[I] = SysMsg(000744) {'REEL'} THEN
                    Header := Header + Pad(SysMsg(000744) {'REEL'} , 11);
                IF Fields[I] = SysMsg(000745) {'STARTTIME'} THEN
                    Header := Header + Pad(SysMsg(000746) {'START'} , 5);
                IF Fields[I] = SysMsg(000747) {'ENDTIME'} THEN
                    Header := Header + Pad(SysMsg(000748) {' END'} , 5);
                IF COPY(Fields[I], 1, 7) = SysMsg(000732) {'KEYWORD'} THEN
                    Header := Header + Pad(SysMsg(000732) {'KEYWORD'} , 12);
            END;
            Header := TrimTrail(Header);
        END;
    END;

    {-----------------------------------------------------------}

    PROCEDURE ReadTape(Lock : BOOLEAN);
    BEGIN
        CASE Lock OF
            TRUE : TapeLibrary^.GetLocked(LibSize, TapeData^);
            FALSE : TapeLibrary^.GetReadOnly(LibSize, TapeData^);
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE SelectPrinter(VAR QID : LONGINT);
    VAR I, J       : INTEGER;
        First          : BOOLEAN;
        FS             : AnyString;
    BEGIN

        QID := 0;

        { Display list of Network Print queues }
        Menu^[1] := SysMsg(000222) {'LOCAL'} ;
        I := 1;
        WITH UData^ DO BEGIN
            IF Sys^.NovellSys THEN BEGIN
                First := TRUE;
                REPEAT
                    WorkS := NextBinderyObject(3, First);
                    First := FALSE;
                    IF WorkS <> '' THEN BEGIN
                        INC(I);
                        Menu^[I] := WorkS;
                    END;
                UNTIL WorkS = '';
            END;
        END;

        IF I = 1 THEN BEGIN
            IF PrinterStatus <> $90 THEN BEGIN
                QID := - 2;
                IF Dialog(SysMsg(000749) {'Printer not Ready'} , SysMsg(000750) {'PRINT'} , LightRed, 'OK', '') = 0 THEN ;
            END;
            EXIT;
        END;

        IF DefaultPrinter <> '' THEN BEGIN
            FOR J := 1 TO I DO
                IF DefaultPrinter = StUpCase(Menu^[J]) THEN
                    I := J;
        END
        ELSE BEGIN
            OpenMenu(WinX + 4, WinY + 2, WinX + 16, WinY + 12, Menu^, I, 12, NoSort, '',
                     SysMsg(000751) {' Select Printer '} , Copyright_Scheme, I);
            I := GetMenu;
            CloseWindow;
        END;

        IF I > 0 THEN BEGIN
            FS := Menu^[I];
            IF I > 2 THEN
                QID := GetQid(FS, 3)
            ELSE
                IF PrinterStatus <> $90 THEN BEGIN
                    QID := - 2;
                    IF Dialog(SysMsg(000749) {'Printer not Ready'} , SysMsg(000750) {'PRINT'} , LightRed, 'OK', '') = 0 THEN ;
                END;
        END
        ELSE BEGIN
            FS := '';
            QID := - 1;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PrintTapes(Format : INTEGER);
    VAR I          : INTEGER;
        S              : STRING[55];
    BEGIN
        OpenMessage(SysMsg(000350) {'Printing...'} , BrightYellow_Scheme);
        CASE Format OF
            1 : WRITELN(LST, PrintSelectHeading);
            2 : WRITELN(LST, PrintGetTapeHeading);
        END;
        FOR I := 1 TO Found DO
        BEGIN
            S := Menus[ScreenNum - 1]^.List^[I];
            WRITELN(LST, COPY( {TapeList^[I]} S, 1, 55));
        END;
        CloseMessage;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PrintSelectedTapes(Format : INTEGER);
    VAR
        QID            : LONGINT;
    BEGIN
        SelectPrinter(QID);
        IF QID < 0 THEN EXIT;
        IF QID = 0 THEN
        BEGIN
            PrintTapes(Format);
        END
        ELSE
        BEGIN
            IF SetCapturePrintQueue(0, QID, 65, FALSE) THEN
            BEGIN
                IF StartCapture(0) THEN
                    PrintTapes(Format);
                IF EndCapture(0) THEN ;
            END;
        END;
    END;

    {-------------------------------------------------------------}

    PROCEDURE PrintTape;
    VAR I, J, K    : INTEGER;
        Line           : STRING[160];
    BEGIN
        ReadTape(Unlocked);
        Line := '';
        WITH TapeData^ DO
        BEGIN
            WITH PrintFormat DO
            BEGIN
                FOR I := 1 TO NumFields DO
                BEGIN
                    IF Fields[I] = SysMsg(000730) {'TAPENUMBER'} THEN
                        Line := Line + Pad(TapeNumber, 10);
                    IF Fields[I] = SysMsg(000731) {'DATE'} THEN
                        Line := Line + Pad(Date, 11);
                    IF Fields[I] = SysMsg(000737) {'SLUG'} THEN
                        Line := Line + Pad(Slug, 31);
                    IF Fields[I] = SysMsg(000738) {'TITLE'} THEN
                        Line := Line + Pad(TapeData^.Title, 31);
                    IF Fields[I] = SysMsg(000739) {'REPORTER'} THEN
                        Line := Line + Pad(Reporter, 11);
                    IF Fields[I] = SysMsg(000740) {'PHOTOGRAPHER'} THEN
                        Line := Line + Pad(Photographer, 11);
                    IF Fields[I] = SysMsg(000742) {'TAPETYPE'} THEN
                        Line := Line + Pad(TapeType, 7);
                    IF Fields[I] = SysMsg(000744) {'REEL'} THEN
                        Line := Line + Pad(Reel, 11);
                    IF Fields[I] = SysMsg(000745) {'STARTTIME'} THEN
                        Line := Line + Pad(StartSMPTE, 5);
                    IF Fields[I] = SysMsg(000747) {'ENDTIME'} THEN
                        Line := Line + Pad(EndSMPTE, 5);
                    IF COPY(Fields[I], 1, 7) = SysMsg(000732) {'KEYWORD'} THEN
                    BEGIN
                        VAL(COPY(Fields[I], 8, 2), J, K);
                        Line := Line + Pad(KeyWords[J], 12);
                    END;
                END;
                WRITELN(LST, TrimTrail(Line));
            END;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE PrintHeader;
    VAR M, D, Y, DW : WORD;
        Line           : STRING[160];
        Temp           : STRING[20];
    BEGIN
        GetDate(Y, M, D, DW);
        INC(PrintFormat.Page);
        Line := Center(PrintFormat.Title, PrintFormat.Width);
        Temp := SysMsg(000752) {'Page: '} + Long2Str(PrintFormat.Page);
        DELETE(Line, 1, LENGTH(Temp));
        Line := Temp + Line;
        Temp := Long2Str(M) + '/' + Long2Str(D) + '/' + Long2Str(Y);
        DELETE(Line, PrintFormat.Width - LENGTH(Temp) - 2, LENGTH(Temp));
        Line := Line + Temp;
        WRITELN(LST, TrimTrail(Line));
        WRITELN(LST, TrimTrail(PrintFormat.Header));
        WRITELN(LST, PadCh('', '-', PrintFormat.Width - 1));
    END;

    {--------------------------------------------------------------------}
    FUNCTION LoadReportFormat : BOOLEAN;
    VAR Index      : INTEGER;
    BEGIN
        LoadReportFormat := FALSE;
        BuildDirectory('*.TRF', TRUE, AnyFile, Menu^, Index);
        IF Index = 0 THEN
        BEGIN
            Index := Dialog(SysMsg(000753) {'No Report Formats'} , 'TAPELIB', Red, 'OK', '');
            EXIT;
        END;
        OpenMenu(WinX + 2, WinY + 2, WinX + 25, WinY + 6, Menu^, Index, 8, NoSort, '', SysMsg(000754) {' Formats '} ,
                 Blue_scheme, Index);
        Index := GetMenu;
        CloseWindow;
        IF Index = 0 THEN EXIT;

        LoadReport(Menu^[Index] + '.TRF');
        LoadReportFormat := TRUE;
        ReportName := Menu^[Index];

    END;

    {--------------------------------------------------------------------}
    PROCEDURE PrintAllTapes;
    VAR Index      : INTEGER;
        First          : BOOLEAN;
    BEGIN
        IF NOT LoadReportFormat THEN EXIT;

        First := TRUE;
        LineNum := 0;
        PrintFormat.Page := 0;
        Index := 2;
        OpenMessage(SysMsg(000348) {'Printing '} + Menu^[1], Red_Scheme);
        PrintHeader;
        WHILE TapeLibrary^.LastBTstatus = 0 DO
        BEGIN
            UpdateTime(FALSE);
            IF First THEN
                TapeLibrary^.Search(#0, Index)
            ELSE
                TapeLibrary^.Next;
            First := FALSE;
            IF TapeLibrary^.LastBTstatus = 0 THEN
            BEGIN
                PrintTape;
                INC(LineNum);
                IF LineNum > PrintFormat.LENGTH THEN
                BEGIN
                    LineNum := 0;
                    PrintHeader;
                END;
            END;
        END;
        CloseMessage;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE ClearSearchMask;
    BEGIN
        FILLCHAR(SearchMask^, SIZEOF(Tape_Search), #0);
        SearchMask^.Date := '  /  /    ';
        SearchMask^.EndDate := '  /  /    ';
    END;

    {--------------------------------------------------------------------}

    PROCEDURE ProcessHelp(ESR : EntryScreen; VAR TapeRec : Tape_Search);
    VAR Yr, Mo, Da : WORD;
    BEGIN
        CASE ESR.GetCurrentID OF
            3..7 : BEGIN
                       OpenWindow(10, 6, 70, 18, ' KEYWORDS ', White_Scheme);
                       GoToXY(1, 2);
                       SetWindowColors;
                       WRITELN(' Enter a Keyword. Tape Library will be searched');
                       WRITELN(' for a matching word anywhere in the keywords,');
                       WRITELN(' Slug or Description fields.');
                       WRITELN(' Keyword may be followed by a special character');
                       WRITELN(' to change the type of matching performed');
                       WRITELN(' e.g.   FRENCH');
                       WRITELN(' would match FRENCH PRESIDENT or FRENCH-PRESIDENT');
                       WRITELN(' but not FRENCHMAN');
                       WRITELN('        FRENCH*');
                       WRITELN(' would match FRENCHMAN as well');
                       WRITELN('        FRENCH?');
                       WRITELN(' would match any word that "sounds like" FRENCH');
                       WaitForEscape;
                       CloseWindow;
                   END;
            11 : BEGIN
                     Yr := 0;
                     SelectDate(40, 5, Yr, Mo, Da, BrightYellow_Scheme);
                     IF Yr <> 0 THEN
                         TapeRec.Date := DateToDateString('mm/dd/yyyy', DMYtoDate(Da, Mo, Yr));
                 END;
            12 : BEGIN
                     Yr := 0;
                     SelectDate(40, 5, Yr, Mo, Da, BrightYellow_Scheme);
                     IF Yr <> 0 THEN
                         TapeRec.EndDate := DateToDateString('mm/dd/yyyy', DMYtoDate(Da, Mo, Yr));
                 END;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE FindPrimaryKey(VAR Index : WORD);
    BEGIN
        WITH SearchMask^ DO
        BEGIN
            Index := 2;
            IF Trim(Date) = '-  -' THEN
                INC(Index)
            ELSE
            BEGIN
                SDate := LongToKey(DateStringToDate('mm-dd-yyyy', Date));
                IF Trim(EndDate) <> '-  -' THEN
                    EDate := LongToKey(DateStringToDate('mm-dd-yyyy', EndDate))
                ELSE
                    EDate := '';
                EXIT;
            END;
            IF Trim(Reporter) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Photographer) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(TapeType) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(KeyWords[1]) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(KeyWords[2]) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(KeyWords[3]) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(KeyWords[4]) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(KeyWords[5]) = '' THEN
                Index := 0;
        END;
    END;

    {-------------------------------------------------------------}

    FUNCTION GetRequestedKey(Num : WORD) : STRING;
    BEGIN
        WITH SearchMask^ DO
            CASE Num OF
                1 : BEGIN
                        GetRequestedKey := ''
                    END;
                2 : BEGIN
                        IF Trim(Date) = '-  -' THEN
                            GetRequestedKey := ''
                        ELSE
                            GetRequestedKey := Date;
                    END;
                3 : GetRequestedKey := Trim(Reporter);
                4 : GetRequestedKey := Trim(Photographer);
                5 : GetRequestedKey := Trim(TapeType);
                6..TotalKeys : GetRequestedKey := Trim(KeyWords[Num - 5]);
            END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE SetFieldCount;
    VAR I          : INTEGER;
    BEGIN
        FieldsRequested := 0;
        FOR I := 1 TO TotalKeys DO
            IF GetRequestedKey(I) <> '' THEN
                INC(FieldsRequested);
    END;

    {-------------------------------------------------------------}

    { Compares dates in SearchMask with Tape date }

    FUNCTION CompareDates(TapeDate : KeyWordSt) : BOOLEAN;
    BEGIN
        WITH SearchMask^ DO
        BEGIN
            IF EDate = '' THEN
                CompareDates := KeyToLong(TapeDate) = KeyToLong(SDate)
            ELSE
                CompareDates := (KeyToLong(TapeDate) >= KeyToLong(SDate)) AND
                                (KeyToLong(TapeDate) <= KeyToLong(EDate));
        END;
    END;

    {-------------------------------------------------------------}

    FUNCTION CompareStrings(Key1, Key2 : KeyWordSt) : BOOLEAN;
    VAR Result     : BOOLEAN;
    BEGIN
        IF Key1[LENGTH(Key1)]IN['*', '?'] THEN
        BEGIN
            DELETE(Key1, LENGTH(Key1), 1);
        END;
        Key1 := Trim(Key1);
        Key2 := Trim(Key2);
        CASE UTMatchType OF
            ' ' : Result := Key1 = Key2;
            '*' : Result := POS(Key1, Key2) <> 0;
            '?' : Result := Soundex(Key1) = Soundex(Key2);
        END;
        CompareStrings := Result;
    END;

    {-------------------------------------------------------------}


    FUNCTION CompareKeys(Key : INTEGER; Key1, Key2 : KeyWordSt) : BOOLEAN;
    VAR Result     : BOOLEAN;
    BEGIN
        CASE Key OF
            2 : Result := CompareDates(Key2);
            1, 3..TotalKeys : Result := CompareStrings(Key1, Unpack6BitKeyUC(Key2));
        END;
        CompareKeys := Result;
    END;

    {-------------------------------------------------------------}


    PROCEDURE SearchKey(TKey : INTEGER; VAR First : BOOLEAN;
                        Key : KeyWordSt; VAR Done : BOOLEAN);
    BEGIN
        UpdateTime(FALSE);
        IF First THEN
        BEGIN
            UTMatchType := ' ';
            IF Key[LENGTH(Key)]IN['*', '?'] THEN
            BEGIN
                UTMatchType := Key[LENGTH(Key)];
                DELETE(Key, LENGTH(Key), 1);
            END;
            IF TKey <> 2 THEN     { below was find }
            BEGIN
                IF UTMatchType = ' ' THEN
                BEGIN
                    TapeLibrary^.Find(Pack6BitKeyUC(Key, KeySize(UTKeyLength[TKey])), TKey);
                END
                ELSE
                BEGIN
                    TapeLibrary^.Search(Pack6BitKeyUC(Key, KeySize(UTKeyLength[TKey])), TKey);
                END;
            END
            ELSE
            BEGIN
                IF SearchMask^.EDate = '' THEN
                BEGIN
                    TapeLibrary^.Find(SearchMask^.SDate, TKey);
                END
                ELSE
                BEGIN
                    TapeLibrary^.Search(SearchMask^.SDate, TKey);
                END;
            END;
            First := FALSE;
        END
        ELSE
        BEGIN
            TapeLibrary^.Next;
        END;
        IF (TapeLibrary^.LastBTstatus <> 0) OR
        (NOT CompareKeys(TKey, Key, TapeLibrary^.LastKey)) THEN
        BEGIN
            Done := TRUE;
        END
        ELSE
        BEGIN
            IF NOT PrintFlag THEN
            BEGIN
                Matrix^.Add(TapeLibrary^.Position);
                IF Matrix^.OverFlow THEN
                BEGIN
                    StopTimer;
                    IF Dialog(SysMsg(000812) {'Too many Tapes in search!'} ,
                              SysMsg(000794) {'SEARCH'} ,
                              Red, 'Ok', '') = 0 THEN ;
                    Done := TRUE;
                    ReStartTimer;
                    EXIT;
                END;
                IF FilterMode THEN
                    WriteCentred(3, SysMsg(000813) {'Filtering: '} + Pad(Long2Str(Matrix^.Filtered), 6))
                ELSE
                    WriteCentred(3, SysMsg(000814) {'Possible : '} + Pad(Long2Str(Matrix^.Found), 6));
            END
            ELSE
            BEGIN
                WriteCentred(3, SysMsg(000815) {'Printing : '} + Pad(Long2Str(Matrix^.Found), 6));
                IF LineNum = 0 THEN
                    PrintHeader;
                INC(LineNum);
                IF LineNum > PrintFormat.LENGTH THEN
                BEGIN
                    LineNum := 0;
                    PrintHeader;
                END;
                PrintTape;
            END;
            Done := FALSE;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE DisplayCount(Msg : STRING; Len : INTEGER);
    BEGIN
        SetBorderColors;
        WITH UData^, Coords[ScreenNum]^ DO
        BEGIN
            wFrame.AddHeader(RConnect + leftpad(Msg, Len) + LConnect, heBR);
            wFrame.UpdateFrame;
        END;
    END;

    {--------------------------------------------------------------------}

    FUNCTION ReadTapeFromMenu(Item : INTEGER) : BOOLEAN;
    VAR RecNo      : LONGINT;
        IX             : INTEGER;
    BEGIN
        ReadTapeFromMenu := FALSE;
        IF NOT Str2Long(Trim(COPY(TapeList^[Item], 56, 10)), RecNo) THEN EXIT;
        TapeLibrary^.SEEK(RecNo);
        IF TapeLibrary^.LastBTstatus = 0 THEN
        BEGIN
            ReadTape(Unlocked);
            ReadTapeFromMenu := TRUE;
        END
        ELSE
            ReadTapeFromMenu := FALSE;
    END;

    {--------------------------------------------------------------------}

    FUNCTION RecordHasChanged : BOOLEAN;
    BEGIN
        IF (OldTapeData^.TapeNumber <> TapeData^.TapeNumber) OR
        (OldTapeData^.KeyWords[1] <> TapeData^.KeyWords[1]) OR
        (OldTapeData^.KeyWords[2] <> TapeData^.KeyWords[2]) OR
        (OldTapeData^.KeyWords[3] <> TapeData^.KeyWords[3]) OR
        (OldTapeData^.KeyWords[4] <> TapeData^.KeyWords[4]) OR
        (OldTapeData^.KeyWords[5] <> TapeData^.KeyWords[5]) OR
        (OldTapeData^.TapeType <> TapeData^.TapeType) OR
        (OldTapeData^.Reporter <> TapeData^.Reporter) OR
        (OldTapeData^.Photographer <> TapeData^.Photographer) OR
        (OldTapeData^.Date <> TapeData^.Date) OR
        (OldTapeData^.StartSMPTE <> TapeData^.StartSMPTE) OR
        (OldTapeData^.EndSMPTE <> TapeData^.EndSMPTE) OR
        (OldTapeData^.Title <> TapeData^.Title) OR
        (OldTapeData^.Slug <> TapeData^.Slug) THEN
        RecordHasChanged := TRUE ELSE
            RecordHasChanged := FALSE;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE UpdateTape;
    VAR I, J, Key, TV : INTEGER;
    BEGIN
        WITH TapeLibrary^ DO
        BEGIN
            Update(TapeData^, LibSize);
            TV := 0;
            IF OldTapeData^.TapeNumber <> TapeData^.TapeNumber THEN
            BEGIN
                IF UserSaysYes(SysMsg(000799) {'Change Tape Number?'} , EscapemeansNo) THEN
                BEGIN
                    TapeData^.TapeVer := '00';
                    ChangeKey(1, Pad(OldTapeData^.TapeNumber, 10) + OldTapeData^.TapeVer,
                              Pad(TapeData^.TapeNumber, 10) + TapeData^.TapeVer);
                    IF TapeLibrary^.LastBTstatus = 10230 THEN
                    BEGIN
                        WITH TapeData^ DO
                        BEGIN
                            REPEAT
                                INC(TV);
                                TapeVer := LeftPadCh(Trim(HexW(TV)), '0', 2);
                                AddKey(1, Pad(TapeNumber, 10) + TapeVer);
                            UNTIL TapeLibrary^.LastBTstatus = 0;
                        END;
                    END
                    ELSE
                    BEGIN
                        TapeData^.TapeNumber := OldTapeData^.TapeNumber;
                        TapeData^.TapeVer := OldTapeData^.TapeVer;
                    END;
                END;
                Update(TapeData^, LibSize);
            END;
            ChangeDateKey(2, OldTapeData^.Date, TapeData^.Date);
            ChangeKey(3, OldTapeData^.Reporter, TapeData^.Reporter);
            ChangeKey(4, OldTapeData^.Photographer, TapeData^.Photographer);
            ChangeKey(5, OldTapeData^.TapeType, TapeData^.TapeType);
            J := 5;               { First computed keyword offset is 6 }
            Key := 10;            { First key number = 11 }
            BuildKeywords(TapeData, J, Key, TapeData^.Slug);
            BuildKeywords(TapeData, J, Key, TapeData^.Title);
            FOR I := 1 TO NumKeywords DO
                IF TapeData^.KeyWords[I] <> '' THEN
                    ChangeKey(I + 5, OldTapeData^.KeyWords[I],
                              TapeData^.KeyWords[I]);
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE ProcessDisplayHelp(ESR : EntryScreen; VAR TapeRec : Tape_Archive);
    VAR Yr, Mo, Da : INTEGER;
    BEGIN
        CASE ESR.GetCurrentID OF
            3..7 : BEGIN
                       OpenWindow(10, 6, 70, 18, ' KEYWORDS ', White_Scheme);
                       GoToXY(1, 2);
                       SetWindowColors;
                       WRITELN(' Enter a Keyword. Tape Library will be searched');
                       WRITELN(' for a matching word anywhere in the keywords,');
                       WRITELN(' Slug or Description fields.');
                       WRITELN(' Keyword may be followed by a special character');
                       WRITELN(' to change the type of matching performed');
                       WRITELN(' e.g.   FRENCH');
                       WRITELN(' would match FRENCH PRESIDENT or FRENCH-PRESIDENT');
                       WRITELN(' but not FRENCHMAN');
                       WRITELN('        FRENCH*');
                       WRITELN(' would match FRENCHMAN as well');
                       WRITELN('        FRENCH?');
                       WRITELN(' would match any word that "sounds like" FRENCH');
                       WaitForEscape;
                       CloseWindow;
                   END;
            11 : BEGIN
                     IF NOT DateStringToDMY('mm/dd/yyyy', TapeRec.Date, Da, Mo, Yr) THEN
                         Yr := 0;
                     SelectDate(10, 5, WORD(Yr), WORD(Mo), WORD(Da), BrightYellow_Scheme);
                     IF Yr <> 0 THEN
                         TapeRec.Date := DateToDateString('mm/dd/yyyy', DMYtoDate(Da, Mo, Yr));
                 END;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE MovePreviousMenu(Item : INTEGER);
    BEGIN
        {    Dec(ScreenNum);}
        NENColorSet := Menus[ScreenNum]^.Colors;
        WITH Menus[ScreenNum]^ DO
        BEGIN
            MoveSelection(pkChoice + Item);
            Choice := Ref^[pkChoice];
        END;
        MarkItemAsSelected;
        {    Inc(ScreenNum);}
        NENColorSet := Coords[ScreenNum]^.Colors;
    END;

    {--------------------------------------------------------------------}


    PROCEDURE DisplayTape(VAR Accept : BOOLEAN);
    BEGIN
        (*    ESRAdd^.wFastWrite(SysMsg(000800){'Tape Data'},1,2,Attr(Blue,LightGreen));*)
        Done := FALSE;
        Accept := FALSE;
        SavePrompt;
        Prompt(SysMsg(000803) {'PgUp=Previous, PgDn=Next'} );
        {MouseWindow(1, 1, 80, 25); ZZZZ}
        WHILE NOT Done DO
        BEGIN
            ClearFKeys;
            IF SecurityClearance = 3 THEN
                SetTag(7, UnShift, SysMsg(000804) {'STORE'} );
            SetTag(1, UnShift, SysMsg(000247) {'HELP'} );
            IF ListPrefillMode THEN
                SetTag(2, UnShift, SysMsg(000805) {'PICK'} );
            OldTapeData^ := TapeData^;
            ESRAdd^.Process;
            CASE ESRAdd^.GetLastCommand OF
                ccDone,
                ccUser0,
                ccQuit : BEGIN
                             IF (RecordHasChanged) AND(SecurityClearance = 3) THEN
                                 IF UserSaysYes(SysMsg(000806) {'Update Tape Changes?'} , EscapeMeansYes) THEN
                                     UpdateTape;
                             Done := TRUE;
                         END;
                ccUser7 : BEGIN
                              IF (SecurityClearance = 3) AND RecordHasChanged THEN
                                  IF UserSaysYes(SysMsg(000807) {'Change Tape Entry?'} , EscapemeansNo) THEN
                                      UpdateTape;
                          END;
                ccUser1 : BEGIN
                              ProcessDisplayHelp(ESRAdd^, TapeData^);
                          END;
                ccUser2 : BEGIN
                              IF ListPrefillMode THEN
                              BEGIN
                                  SelectedTape := TapeData^.TapeNumber;
                                  Done := TRUE;
                              END;
                          END;
                ccPrevRec : BEGIN
                                IF (RecordHasChanged) AND(SecurityClearance = 3) THEN
                                    IF UserSaysYes(SysMsg(000806) {'Update Tape Changes?'} , EscapeMeansYes) THEN
                                        UpdateTape;
                                IF (PgUpPgDn) AND(Found > 1) THEN
                                BEGIN
{                              EnableVirtualScreen(Coords[ScreenNum-1].x1,
                                                  Coords[ScreenNum].y1);
                              VirtualMenu := false;}
                                    MovePreviousMenu(- 1);
                                    IF ReadTapeFromMenu(Choice) THEN ;
{                              With Coords[ScreenNum] do
                                ClearVirtualScreen(x1,y1,x2,y2,Back,' ');
                              UpdateScreen;
                              DisableVirtualScreen;
                              VirtualMenu := True;}
                                END;
                            END;
                ccNextRec : BEGIN
                                IF (RecordHasChanged) AND(SecurityClearance = 3) THEN
                                    IF UserSaysYes(SysMsg(000806) {'Update Tape Changes?'} , EscapeMeansYes) THEN
                                        UpdateTape;
                                IF (PgUpPgDn) AND(Found > 1) THEN
                                BEGIN
{                              EnableVirtualScreen(Coords[ScreenNum-1].x1,
                                                  Coords[ScreenNum].y1);
                              VirtualMenu := false;}
                                    MovePreviousMenu(1);
                                    IF ReadTapeFromMenu(Choice) THEN ;
{                              With Coords[ScreenNum] do
                                ClearVirtualScreen(x1,y1,x2,y2,Back,' ');
                              UpdateScreen;
                              DisableVirtualScreen;
                              VirtualMenu := True; }
                                END;
                            END;
            END;
        END;
        ESRAdd^.ERASE;
        ClearFKeys;
        RestorePrompt;
        IF ListPrefillMode THEN
        BEGIN
            StuffKey($011B);      { Close Tape menu }
        END;
    END;

    {--------------------------------------------------------------------}


    PROCEDURE ReadAndDisplayTape(Select : INTEGER);
    VAR RecNo      : LONGINT;
        Done           : BOOLEAN;
    BEGIN
        IF ReadTapeFromMenu(Select) THEN
            DisplayTape(Done)
        ELSE
        BEGIN
            IF Dialog(SysMsg(000810) {'Search Error on '} + Trim(COPY(TapeList^[Select], 11, 31)), SysMsg(000811) {'READ'} ,
                      Red, 'Ok', '') = 0 THEN ;
        END;
    END;

    {-------------------------------------------------------------}

    PROCEDURE DoSearch;

    VAR Index      : WORD;
        XPos, Ypos, YDepth : INTEGER;
        DataLen        : WORD;
        Selected       : LONGINT;
        KeyStr         : IsamKeyStr;
        ExitKey        : Bktype;
        I, J           : INTEGER;
        Done           : BOOLEAN;
        SearchDone     : BOOLEAN;
        Hit            : BOOLEAN;
        HitCount       : WORD;
        First          : BOOLEAN;
        Key            : KeyWordSt;
        KeyNum         : INTEGER;
        TestKey        : INTEGER;
        KeyDone        : BOOLEAN;
        SubSearchDone  : BOOLEAN;
        SelectMenuUp   : BOOLEAN;
        MatchMenuUp    : BOOLEAN;
        ValidSelection : BOOLEAN;
        Match          : CHAR;
        ExactFound     : WORD;
        CloseFound     : WORD;
        LooseFound     : WORD;
        FirstItem, LastItem : WORD;

    LABEL StartSearch, DisplaySelections, EndSearch, NextBatch;

    BEGIN

        FindPrimaryKey(Index);
        IF Index = 0 THEN
        BEGIN
            IF Dialog(SysMsg(000829) {'Must select at least 1 key'} , SysMsg(000794) {'SEARCH'} , Red, 'OK', '') = 0 THEN ;
            EXIT;
        END;

        ResetTimer;
        StartTimer;

        OpenMessage(SysMsg(000830) {' Searching for '} + Pad(GetRequestedKey(Index), 15), BrightYellow_Scheme);

        SetFieldCount;
        SearchMode := Strict;
        Found := 0;
        Matrix^.RESET;


        { Multi-key matrix search. Searches by each requested key & builds }
        { a matrix of each record found & number of times it was hit.      }

        KeyNum := 20;
        SearchDone := FALSE;
        WHILE NOT SearchDone DO
        BEGIN
            UpdateTime(FALSE);
        {$B+}
            IF ((KeyNum = 5) OR((KeyNum = 2) AND(SearchMask^.EDate <> '')))
            AND(Matrix^.Found > 0) THEN
                FilterMode := TRUE
            ELSE
                FilterMode := FALSE;
        {$B-}
            IF GetRequestedKey(KeyNum) <> '' THEN
            BEGIN
                WriteCentred(2, SysMsg(000830) {' Searching for '} + Pad(GetRequestedKey(KeyNum), 15));
                Key := GetRequestedKey(KeyNum);
                KeyDone := FALSE;
                First := TRUE;
                WHILE NOT KeyDone DO
                BEGIN
                    IF MEM[$40:$17]AND $08 <> 0 THEN { <Alt> }
                        IF Dialog(SysMsg(000831) {'End Search Now?'} ,
                                  SysMsg(000794) {'SEARCH'} ,
                                  Green,
                                  SysMsg(64),
                                  SysMsg(65)) = 1 THEN
                        BEGIN
                            KeyDone := TRUE;
                            SearchDone := TRUE;
                        END;
                    IF KeyNum <= 5 THEN
                        SearchKey(KeyNum, First, Key, KeyDone)
                    ELSE
                    BEGIN
                        FOR TestKey := 6 TO TotalKeys DO
                        BEGIN
                            SubSearchDone := FALSE;
                            First := TRUE;
                            WHILE NOT SubSearchDone DO
                            BEGIN
                                SearchKey(TestKey, First, Key, SubSearchDone);
                                IF MEM[$40:$17]AND $08 <> 0 THEN { <Alt> }
                                    IF Dialog(SysMsg(000831) {'End Search Now?'} ,
                                              SysMsg(000794) {'SEARCH'} , Green,
                                              SysMsg(64), SysMsg(65)) = 1 THEN
                                    BEGIN
                                        KeyDone := TRUE;
                                        SearchDone := TRUE;
                                        SubSearchDone := TRUE;
                                        TestKey := TotalKeys;
                                    END;
                            END;
                        END;
                        KeyDone := TRUE;
                    END;
                END;
            END;
            DEC(KeyNum);
            IF KeyNum < 1 THEN
                SearchDone := TRUE;
        END;

        MatchMenuUp := FALSE;

        IF PrintFlag THEN
        BEGIN
            WRITELN(LST, SysMsg(000832) {'Report '} + ReportName + SysMsg(000833) {' Complete'} );
            StopTimer;
            LineNum := 0;
            GOTO EndSearch;
        END;

        { Matrix built. Now, each record in the matrix that has a hit count }
        { equal to the number of requested keys is a AND mode match.        }
        { Every record is a OR mode match.                                  }

StartSearch: { Back here for relaxed search }

        IF Matrix^.Found = 0 THEN
        BEGIN
            StopTimer;
            Choice := Dialog(SysMsg(000834) {'No Matching Tapes'} , SysMsg(000794) {'SEARCH'} , LightRed, 'OK', '');
            CloseMessage;
            EXIT;
        END;

        CloseMessage;

        IF FieldsRequested > 1 THEN
        BEGIN
            ExactFound := 0;
            CloseFound := 0;
            LooseFound := 0;
            FOR I := 1 TO Matrix^.Found DO
            BEGIN
                Matrix^.GetElement(I, Selected, HitCount);
                IF HitCount = FieldsRequested THEN
                    INC(ExactFound);
                IF (HitCount > 1) AND(HitCount < FieldsRequested) THEN
                    INC(CloseFound);
                IF HitCount = 1 THEN
                    INC(LooseFound);
            END;


            IF LooseFound + CloseFound > 0 THEN
            BEGIN
                StopTimer;
                ClearFKeys;
                Menu^[1] := SysMsg(000835) {'Exact match on '} + Long2Str(ExactFound) + SysMsg(000809) {' Tapes'} ;
                Menu^[2] := SysMsg(000836) {'Close match on '} + Long2Str(CloseFound) + SysMsg(000809) {' Tapes'} ;
                Menu^[3] := SysMsg(000837) {'Some  match on '} + Long2Str(LooseFound) + SysMsg(000809) {' Tapes'} ;
                IF NOT MatchMenuUp THEN
                BEGIN
                    OpenMenu(34, 5, 69, 11, Menu^, 3, 30, NoSort, ''
                             , SysMsg(000839) {'Match Result'} , Black_Scheme, I);
                    WITH Menus[ScreenNum]^ DO
                    BEGIN
                        wFrame.AddHeader(Long2Str(Matrix^.Found) + SysMsg(000838) {' Hits'} , heBR);
                        wFrame.UpdateFrame;
                    END;
                END;
                IF NOT MatchMenuUp THEN
                    IF ExactFound <> 0 THEN { Pop exact menu up first time }
                        StuffKey(OpKey.Enter);
                MatchMenuUp := TRUE;
                ValidSelection := FALSE;
                WHILE NOT ValidSelection DO
                BEGIN
                    CASE GetMenu OF
                        0 : BEGIN
                                CloseWindow;
                                MatchMenuUp := FALSE;
                                EXIT;
                            END;
                        1 : BEGIN
                                IF ExactFound > 0 THEN
                                    ValidSelection := TRUE;
                                SearchMode := Strict;
                            END;
                        2 : BEGIN
                                IF CloseFound > 0 THEN
                                    ValidSelection := TRUE;
                                SearchMode := Relaxed;
                            END;
                        3 : BEGIN
                                IF LooseFound > 0 THEN
                                    ValidSelection := TRUE;
                                SearchMode := Loose;
                            END;
                    END;
                END;
            END;
        END
        ELSE
            SearchMode := Loose;

        FirstItem := 1;
        LastItem := FirstItem + TapeListSize;
        IF LastItem > Matrix^.Found THEN LastItem := Matrix^.Found;

NextBatch:

        OpenMessage(SysMsg(000840) {'Reading & Selecting Tapes'} , BrightYellow_Scheme);

        Found := 0;
        I := FirstItem - 1;
        REPEAT
            BEGIN
                INC(I);
                UpdateTime(FALSE);
                Matrix^.GetElement(I, Selected, HitCount);
                Hit := FALSE;
                CASE SearchMode OF
                    Strict : BEGIN { Only those matching all keys }
                                 IF FieldsRequested = HitCount THEN
                                     Hit := TRUE;
                             END;
                    Relaxed : BEGIN { match more than one but not all }
                                  IF (HitCount > 1) AND(HitCount < FieldsRequested) THEN
                                      Hit := TRUE;
                              END;
                    Loose : BEGIN { match any key }
                                IF (HitCount = 1) THEN
                                    Hit := TRUE;
                            END;
                END;
                IF Hit THEN
                BEGIN
                    TapeLibrary^.SEEK(Selected);
                    ReadTape(Unlocked);
                    INC(Found);
                    IF Found > TapeListSize THEN
                    BEGIN
                        StopTimer;
                        DEC(Found);
                        GOTO DisplaySelections;
                    END;
                    WriteCentred(3, SysMsg(000820) {'Found: '} + Pad(Long2Str(Found), 6));
                    TapeList^[Found] := Pad(TapeData^.TapeNumber, 6) + ' ' +
                                        Pad(COPY(TapeData^.StartSMPTE, 1, 4), 4) + ' ' +
                                        Pad(TapeData^.Slug, 30) + ' ' +
                                        COPY(TapeData^.Date, 7, 4) + '-' +
                                        COPY(TapeData^.Date, 1, 2) + '-' +
                                        COPY(TapeData^.Date, 4, 2);
                    TapeList^[Found] := Pad(TapeList^[Found], 55) +
                                        Long2Str(TapeLibrary^.Position);
                END
                ELSE
                BEGIN
                    IF {Matrix^.Found} I > TapeListSize THEN
                    BEGIN
                        INC(LastItem);
                        IF LastItem > Matrix^.Found THEN
                        BEGIN
                            DEC(LastItem);
                            GOTO DisplaySelections;
                        END;
                    END;
                END;
            END;
        UNTIL (Found >= TapeListSize) OR(FirstItem + Found > Matrix^.Found) OR
        (I = Matrix^.Found);

        StopTimer;
DisplaySelections:

        CloseMessage;

        XPos := 13;
        Ypos := 9;
        YDepth := 8;
        IF Found < YDepth THEN
            YDepth := Found + 1;

        Choice := 1;
        SelectMenuUp := FALSE;

        IF Found = 0 THEN GOTO EndSearch;

        SetupSort(Descending, 45, 54); { openmenu will reset to defaults }
        OpenMenu(XPos, Ypos, XPos + 61, Ypos + YDepth, TapeList^, Found, 55, Sort,
                 SelectHeading,
                 SysMsg(000841) {' Selected Tapes '} , Red_Scheme, I);

        DisplayCount(Long2Str(Found) + SysMsg(000809) {' Tapes'} , 11);

        TextAttr := Attr(Red, LightCyan);
        WriteCentred(YDepth + 4,
                     SysMsg(000842) {'Searched '} +
                     Long2Str(FirstItem) +
                     SysMsg(000843) {' to '} +
                     Long2Str(LastItem) +
                     SysMsg(000844) {' of '} +
                     Long2Str(Matrix^.Found));

        ClearFKeys;

        SelectMenuUp := TRUE;

        EnableFunctionKeyExit := TRUE;
        WHILE NOT EscapePressed DO
        BEGIN
            SetTag(6, UnShift, SysMsg(000750) {'PRINT'} );
            IF LastItem < Matrix^.Found THEN
                SetTag(10, UnShift, SysMsg(000156) {'NEXT'} );
            IF FirstItem > 1 THEN
                SetTag(9, UnShift, SysMsg(000155) {'PREV'} );
            IF ListPrefillMode THEN
                SetTag(2, UnShift, SysMsg(000805) {'PICK'} );
            Choice := GetMenu;
            IF Choice <> 0 THEN
            BEGIN
                IF Choice < 1000 THEN
                    ReadAndDisplayTape(Choice)
                ELSE
                BEGIN
                    IF Choice DIV 1000 = 6 THEN
                    BEGIN
                        PrintSelectedTapes(1);
                    END;
                    IF Choice DIV 1000 = 2 THEN
                    BEGIN
                        IF ListPrefillMode THEN
                        BEGIN
                            GetMenuString(Choice - 2000, Key);
                            MOVE(Key[1], SelectedTape[1], 6);
                            SelectedTape[0] := #6;
                            SelectedTape := Trim(SelectedTape);
                            StuffKey($011B);
                            GOTO EndSearch;
                        END;
                    END;
                    IF Choice DIV 1000 = 10 THEN
                    BEGIN
                        IF LastItem < Matrix^.Found THEN
                        BEGIN
                            FirstItem := LastItem + 1;
                            LastItem := FirstItem + TapeListSize;
                            IF LastItem > Matrix^.Found THEN LastItem := Matrix^.Found;
                            CloseWindow;
                            ResetTimer;
                            StartTimer;
                            GOTO NextBatch;
                        END;
                    END;
                    IF Choice DIV 1000 = 9 THEN
                    BEGIN
                        IF FirstItem > 1 THEN
                        BEGIN
                            FirstItem := FirstItem - TapeListSize;
                            LastItem := FirstItem + TapeListSize;
                            IF LastItem > Matrix^.Found THEN LastItem := Matrix^.Found;
                            IF FirstItem < 0 THEN FirstItem := 1;
                            CloseWindow;
                            ResetTimer;
                            StartTimer;
                            GOTO NextBatch;
                        END;
                    END;
                END;
            END;
        END;
        EnableFunctionKeyExit := FALSE;

EndSearch:

        IF SelectMenuUp THEN
            CloseWindow;
        ClearFKeys;
        SelectMenuUp := FALSE;

        IF MatchMenuUp THEN
            GOTO StartSearch;

    END;

    {--------------------------------------------------------------------}

    { Search tape library via any of the indexed keys }
    PROCEDURE SearchTapes;
    VAR Done       : BOOLEAN;
    BEGIN
        ClearSearchMask;
(*
    with ESRSearch^ do
      begin
        wFastWrite(SysMsg(000790){'Enter Search fields'},1,2,Attr(Green,White));
        wFastWrite(Long2Str(TapeLibrary^.NumRecs)+SysMsg(000791){' Tapes in Library'},
                        12,2,Attr(Green,White));
        wFastWrite(SysMsg(000792){'F10=Search'},13,2,Attr(Green,LightGreen));
      end;
*)
        Done := FALSE;
        DrawTimer;
        ResetTimer;

        WHILE NOT Done DO
        BEGIN
            ClearFKeys;
            SetTag(5, UnShift, SysMsg(000793) {'CLEAR'} );
            SetTag(1, UnShift, SysMsg(000247) {'HELP'} );
            SetTag(10, UnShift, SysMsg(000794) {'SEARCH'} );
            IF (ListPrefillMode) AND(SelectedTape <> '') THEN
                Done := TRUE;
            ESRSearch^.Process;
            CASE ESRSearch^.GetLastCommand OF
                ccNone : BEGIN
                             IF Dialog(SysMsg(000795) {'Error!'} , SysMsg(000794) {'SEARCH'} , Red, 'OK', '') = 0 THEN ;
                             Done := TRUE;
                         END;
                {ccDone,}
                ccQuit : Done := TRUE;
                ccUser1 : BEGIN
                              ProcessHelp(ESRSearch^, SearchMask^);
                          END;
                ccUser5 : BEGIN
                              ClearSearchMask;
                          END;
                ccUser0 : BEGIN
                              DoSearch;
                          END;
                ccError : Done := TRUE;
            END;
        END;
        ESRSearch^.ERASE;
        EraseTimer;
        ClearFKeys;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PrintReports;
    VAR
        QID            : LONGINT;
        I              : INTEGER;
    BEGIN
        Menu^[1] := SysMsg(000755) {'Print All Tapes'} ;
        Menu^[2] := SysMsg(000756) {'Print Selected Tapes'} ;
        OpenMenu(WinX + 2, WinY + 2, WinX + 30, WinY + 6, Menu^, 2, 20, NoSort, '', SysMsg(000757) {' Reports '} ,
                 Mauve_Scheme, I);
        I := GetMenu;
        CloseWindow;
        IF I = 0 THEN EXIT;
        SelectPrinter(QID);
        IF QID < 0 THEN EXIT;
        IF QID = 0 THEN
        BEGIN
            PrintFlag := TRUE;
            CASE I OF
                1 : PrintAllTapes;
                2 : BEGIN
                        IF NOT LoadReportFormat THEN EXIT;
                        LineNum := 0;
                        PrintFormat.Page := 0;
                        SearchTapes;
                    END;
            END;
            PrintFlag := FALSE;
        END
        ELSE
        BEGIN
            IF SetCapturePrintQueue(0, QID, 65, FALSE) THEN
            BEGIN
                IF StartCapture(0) THEN
                BEGIN
                    PrintFlag := TRUE;
                    CASE I OF
                        1 : PrintAllTapes;
                        2 : BEGIN
                                IF NOT LoadReportFormat THEN EXIT;
                                LineNum := 0;
                                PrintFormat.Page := 0;
                                SearchTapes;
                            END;
                    END;
                    PrintFlag := FALSE;
                END;
                IF EndCapture(0) THEN ;
            END;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE InitSearchScreen;
    VAR dummy      : STRING[2];
    BEGIN
        ClearSearchMask;
        SearchMask^.Date := '  /  /    ';
        SearchMask^.EndDate := '  /  /    ';

        Green_Scheme;

        WITH NENColorSet DO
        BEGIN
            SetPromptAttr(DkGrayOnGreen, $07);
            SetProtectedPromptAttr(WhiteOnGreen, $07);
            SetTextAttr(BlackOnGreen, $07);
            SetFieldAttr(BlackOnGreen, $07);
            SetSelectedFieldAttr(BlackOnLtGreen, $07);
        END;

        NEW(ESRSearch, InitCustom(9, 8, 35, 20, NENColorSet,
                                  DefWindowOptions OR wBordered));
        CustomizeWindow(ESRSearch^, ' Search  ', 6);

        CustomizeCommandProcessor(EntryCommands);
        WITH ESRSearch^, EntryCommands DO
        BEGIN
            AddCommand(ccUser1, 1, $3B00, 0); { F1 }
            AddCommand(ccUser2, 1, $3C00, 0); { F2 }
            AddCommand(ccUser3, 1, $3D00, 0); { F3 }
            AddCommand(ccUser4, 1, $3E00, 0); { F4 }
            AddCommand(ccUser5, 1, $3F00, 0); { F5 }
            AddCommand(ccUser6, 1, $4000, 0); { F6 }
            AddCommand(ccUser7, 1, $4100, 0); { F7 }
            AddCommand(ccUser8, 1, $4200, 0); { F8 }
            AddCommand(ccUser9, 1, $4300, 0); { F9 }
            AddCommand(ccUser0, 1, $4400, 0); { F10 }
        END;

        WITH ESRSearch^ DO
        BEGIN
            esFieldOptionsOn(efClearFirstChar);
            esFieldOptionsOff(efRequired);
            esFieldOptionsOn(efProtected);
            TLabel := '';
            AddStringField(SysMsg(000790) {'Enter Search fields'} , 1, 2, '', 1, 22, 1, 1, TLabel);
            esFieldOptionsOff(efProtected);
            AddStringField(SysMsg(000783) {'Keyword : '} , 2, 2, '!!!!!!!!!!!!!!!', 2, 12, 15, 3, SearchMask^.KeyWords[1]);
            AddStringField(SysMsg(000783) {'Keyword : '} , 3, 2, '!!!!!!!!!!!!!!!', 3, 12, 15, 4, SearchMask^.KeyWords[2]);
            AddStringField(SysMsg(000783) {'Keyword : '} , 4, 2, '!!!!!!!!!!!!!!!', 4, 12, 15, 5, SearchMask^.KeyWords[3]);
            AddStringField(SysMsg(000783) {'Keyword : '} , 5, 2, '!!!!!!!!!!!!!!!', 5, 12, 15, 6, SearchMask^.KeyWords[4]);
            AddStringField(SysMsg(000783) {'Keyword : '} , 6, 2, '!!!!!!!!!!!!!!!', 6, 12, 15, 7, SearchMask^.KeyWords[5]);
            AddStringField(SysMsg(000784) {'Type    : '} , 7, 2, '!!!!!!', 7, 12, 6, 8, SearchMask^.TapeType);
            AddStringField(SysMsg(000785) {'Reporter: '} , 8, 2, '!!!!!!!!!!', 8, 12, 10, 9, SearchMask^.Reporter);
            AddStringField(SysMsg(000786) {'Photog. : '} , 9, 2, '!!!!!!!!!!', 9, 12, 10, 10, SearchMask^.Photographer);
            AddDateStField(SysMsg(000787) {'Date 1  : '} , 10, 2, 'mm/dd/yyyy', 10, 12, 11, SearchMask^.Date);
            AddDateStField(SysMsg(000788) {'Date 2  : '} , 11, 2, 'mm/dd/yyyy', 11, 12, 12, SearchMask^.EndDate);
            esFieldOptionsOn(efProtected);
            TapesInLib := 0;
            AddLongField(Trim(SysMsg(000791)) {' Tapes in Library'} , 13, 2, '9,999,999',
                         13, 19, 13, 0, 0, TapesInLib);
            esFieldOptionsOff(efProtected);
        END;

    END;

    {--------------------------------------------------------------------}
    PROCEDURE InitEntryScreen;
    BEGIN
        FileColors;

        NEW(ESRAdd, InitCustom(32, 5, 75, 20, NENColorSet,
                               DefWindowOptions OR wBordered));
        CustomizeWindow(ESRAdd^, '', 10);

        CustomizeCommandProcessor(EntryCommands);
        WITH ESRAdd^, EntryCommands DO
        BEGIN
            AddCommand(ccUser1, 1, $3B00, 0); { F1 }
            AddCommand(ccUser2, 1, $3C00, 0); { F2 }
            AddCommand(ccUser3, 1, $3D00, 0); { F3 }
            AddCommand(ccUser4, 1, $3E00, 0); { F4 }
            AddCommand(ccUser5, 1, $3F00, 0); { F5 }
            AddCommand(ccUser6, 1, $4000, 0); { F6 }
            AddCommand(ccUser7, 1, $4100, 0); { F7 }
            AddCommand(ccUser8, 1, $4200, 0); { F8 }
            AddCommand(ccUser9, 1, $4300, 0); { F9 }
            AddCommand(ccUser0, 1, $4400, 0); { F10 }
            AddCommand(ccNextRec, 1, OpKey.PgDn, 0);
            AddCommand(ccPrevRec, 1, OpKey.PgUp, 0);
        END;

        WITH ESRAdd^ DO
        BEGIN
            esFieldOptionsOn(efRequired);
            AddStringField(SysMsg(000758) {'Tape Number: '} , 2, 2, '!!!!!!!!!!', 2, 15, 10, 1, TapeData^.TapeNumber);
            esFieldOptionsOff(efRequired);
            esFieldOptionsOff(efProtected);
            AddStringField(SysMsg(000759) {'Slug       : '} , 3, 2, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                           , 3, 15, 30, 2, TapeData^.Slug);
            AddStringField(SysMsg(000760) {'Description: '} , 4, 2, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                           , 4, 15, 30, 2, TapeData^.Title);
            AddStringField(SysMsg(000761) {'Keyword 1  : '} , 5, 2, '!!!!!!!!!!!!!!!', 5, 15, 15, 3, TapeData^.KeyWords[1]);
            AddStringField(SysMsg(000762) {'Keyword 2  : '} , 6, 2, '!!!!!!!!!!!!!!!', 6, 15, 15, 4, TapeData^.KeyWords[2]);
            AddStringField(SysMsg(000763) {'Keyword 3  : '} , 7, 2, '!!!!!!!!!!!!!!!', 7, 15, 15, 5, TapeData^.KeyWords[3]);
            AddStringField(SysMsg(000764) {'Keyword 4  : '} , 8, 2, '!!!!!!!!!!!!!!!', 8, 15, 15, 6, TapeData^.KeyWords[4]);
            AddStringField(SysMsg(000765) {'Keyword 5  : '} , 9, 2, '!!!!!!!!!!!!!!!', 9, 15, 15, 7, TapeData^.KeyWords[5]);
            AddStringField(SysMsg(000766) {'Type       : '} , 10, 2, '!!!!!!', 10, 15, 6, 8, TapeData^.TapeType);
            AddStringField(SysMsg(000767) {'Reporter   : '} , 11, 2, '!!!!!!!!!!', 11, 15, 10, 9, TapeData^.Reporter);
            AddStringField(SysMsg(000768) {'Photog     : '} , 12, 2, '!!!!!!!!!!', 12, 15, 10, 10, TapeData^.Photographer);
            AddDateStField(SysMsg(000769) {'Date       : '} , 13, 2, 'mm/dd/yyyy', 13, 15, 11, TapeData^.Date);
            AddStringField(SysMsg(000770) {'Reel       : '} , 14, 2, '!!!!!!!!!!', 14, 15, 10, 12, TapeData^.Reel);
            AddStringField(SysMsg(000771) {'Start Time : '} , 15, 2, '', 15, 15, 15, 13, TapeData^.StartSMPTE);
            AddStringField(SysMsg(000772) {'End   Time : '} , 16, 2, '', 16, 15, 15, 14, TapeData^.EndSMPTE);
        END;

    END;

    {--------------------------------------------------------------------}


END.
