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
PROGRAM KR2TST;

USES
    {ccsess,}
    DGLIB,
    DGMath,
    FBrowse,
    Filer,
    krbrowse,
    KRDB,
    IsamTool,
    KERROR,
    OpCRT,
    OpDate,
    OpDos,
    OpInline,
    OpString,
    {SFTP,}
    Strings,
    USE32,
    UTIAM,
    UTTIMDAT,
    VARDEC;

    {---------------}

    {clear a filerec;  If ClrAll = false, then leave the path alone}
    PROCEDURE ClrRec(VAR FR : TKR2Rec; ClrAll : BOOLEAN);
    VAR
        Strg           : STRING;
    BEGIN
        EXIT;
        (*
        IF ClrAll THEN
            Strg := ''
        ELSE
            Strg := FR.Path;

        FILLCHAR(FR, SIZEOF(FR), #0);
        FR.FDate := BadDate;
        FR.Path := Trim(Strg);
        *)
    END;

    {-------------}

    (*
    {parse a line out of 00IndexD }
    FUNCTION ParseFileLine(Strg : STRING; VAR FR : TKR2Rec; Mode : TMode) : TParseStat;
    VAR
        S,
        M,
        D,
        T,
        Y              : STRING[80];

        Wc,
        I              : BYTE;
        Ofst           : SHORTINT;
    BEGIN
        {asume failure}
        ParseFileLine := NotReady;

        {count words in line}
        Wc := WordCount(Strg, [' ']);

        {set wordcount offset default}
        Ofst := - 1;

        IF Mode = Infile THEN BEGIN
            {we are not in splitline mode, so clear the record}
            ClrRec(FR, FALSE);
            {fill in the name}
            FR.Name := ExtractWord(1, Strg, [' ']);
            {don't need an offset}
            Ofst := 0;
        END;

        {only one word on line means long filename with file info on 2nd line}
        IF Wc = 1 THEN            {bail if split name/info}
            EXIT;

        WITH FR DO BEGIN
            {get the filesize}
            S := ExtractWord(2 + Ofst, Strg, [' ']);

            {was this a nested subdirectory entry?}
            IF S = '-' THEN BEGIN
                {yup: Bail!}
                ParseFileLine := ABORTREC;
                EXIT;
            END;

            {converts string to filesize}
            Str2Long(S, FSize);

            {get filedate/time}
            M := ExtractWord(3 + Ofst, Strg, [' ']);
            D := ExtractWord(4 + Ofst, Strg, [' ']);
            Y := ExtractWord(5 + Ofst, Strg, [' ']);

            {was the year field populated with a time?}
            IF POS(':', Y) > 0 THEN BEGIN
                {yes: assume year is this year}
                T := Y;
                Y := DateToDateString('yyyy', Today);
            END
            ELSE
                T := '00:00';     {no time field, so set to midnight}

            {convert time and date strings into Opro date/time}
            FDate := DateStringToDate('nnn dd yyyy', M + ' ' + D + ' ' + Y);
            Ftime := TimeStringToTime('hh:mm', T);

            {if file has a description, then go get it}
            IF Wc > 5 THEN BEGIN
                {get all words, except for the last one}
                FOR I := 6 + Ofst TO Wc - 1 DO
                    Desc := Desc + ExtractWord(I, Strg, [' ']) + ' ';

                {now get the last word, but don't append trailing space}
                Desc := Desc + ExtractWord(Wc, Strg, [' ']);
            END;

            ParseFileLine := Ready;
        END;
    END;

    {-------------}

    {state machine to deal with 00IndexD syntax}
    FUNCTION ParseLine(Strg : STRING; VAR FR : TKR2Rec) : TParseStat;
    CONST
        Mode           : TMode = InHdr;
    VAR
        OldPath        : STRING;
    BEGIN
        ParseLine := NotReady;
        Strg := StripCtrl(Strg);
        CASE Mode OF
            InHdr :               {toss header stuff}
                BEGIN
                    IF LENGTH(Strg) = 0 THEN
                        Mode := InPath;
                    EXIT;
                END;
            InPath :              {found a path line}
                BEGIN
                    IF LENGTH(Strg) = 0 THEN
                        EXIT;
                    ClrRec(FR, TRUE);
                    FR.Path := Trim(Strg);
                    {trim off the colon}
                    IF LENGTH(FR.Path) > 0 THEN
                        DEC(FR.Path[0]);
                    Mode := Infile;
                    EXIT;
                END;
            InSplitFile,          {handling a long filename with split info}
            Infile :              {found a file line or embedded subpath}
                BEGIN
                    IF LENGTH(Strg) = 0 THEN BEGIN
                        Mode := InPath;
                        EXIT;
                    END;

                    OldPath := FR.Path;

                    CASE ParseFileLine(Strg, FR, Mode) OF
                        Ready :
                            BEGIN
                                ParseLine := Ready;
                                Mode := Infile; {incase of split completion}
                            END;
                        NotReady :
                            Mode := InSplitFile;
                        ABORTREC :
                            BEGIN
                                ClrRec(FR, TRUE); {was embedded path-toss rec}
                                FR.Path := OldPath;
                            END;
                    END;
                END;
        END;
    END;

    {---------------}

    {parse a buffer full of ascii data}
    FUNCTION ParseBuff(P              : PCHAR;
                       BuffSize       : WORD;
                       FILEPOS        : LONGINT;
                       VAR FR         : TKR2Rec;
                       COP            : CylonP;
                       VAR LineNum    : LONGINT) : LONGINT;
    VAR
        LastGood,
        TP             : PCHAR;
        NewRecN,
        BuffUsed,
        CharsLeft,
        Size           : LONGINT;
    BEGIN
        {Strtok works the same as the C lib func with the same name}
        TP := StrTok(P, #10);     {Get next LF delimited pchar string}
        WHILE TP <> NIL DO BEGIN
            LastGood := TP;
            IF NOT COP^.Update THEN
                BREAK;
            INC(LineNum);
            IF ParseLine(StrPas(TP), FR) = Ready THEN
                IF KR2DBFile^.AddNewRecord(FR, NewRecN) <> 0 THEN
                    DispErrorDeluxe('Can not add record to Hobbes Database.  Line: ' +
                                    Long2Str(LineNum),
                                    IsamErrorMessage(IsamError),
                                    TRUE,
                                    Iam);
            TP := StrTok(NIL, #10); {Get next LF delimited pchar string}
        END;

        {calc new file pointer from dregs left over in buffer}

        {how many bytes were left over in buffer due to an unprocessed}
        {partial line?  Calc new filepointer to load it on next pass  }
        BuffUsed := (PtrToLong(LastGood) + StrLen(LastGood) + 1) - PtrToLong(P);
        CharsLeft := BuffUsed - BuffSize;
        ParseBuff := CharsLeft + FILEPOS;
    END;

    {---------------}
    *)

    PROCEDURE BrowseDB;
    VAR
        HBP            : PKR2Browser;
        I              : WORD;
    BEGIN
        NEW(HBP, Init(KR2DBFile));
        {
        HobbesFileIDKey = 1;
        HobbesFilePathKey = 2;
        HobbesFileNameKey = 3;
        KR2DBFileizeKey = 4;
        HobbesFileDateKey = 5;
        }
        FOR I := 2 TO 5 DO BEGIN
            KR2DBFile^.glCurKeyNr := I;
            KR2DBFile^.glCurKeyStr := KR2DBFile^.BuildKey(KR2DBFile^.glCurRec, KR2DBFile^.glCurKeyNr);
            HBP^.SetKeyNumber(KR2DBFile^.glCurKeyNr);
            HBP^.SetCurrentRecord(KR2DBFile^.glCurKeyStr, KR2DBFile^.glCurRefNr);
            HBP^.fbOptionsOn(fbForceUpdate);
            HBP^.Process;
        END;
        DISPOSE(HBP, Done);
    END;

    {---------------}

    PROCEDURE MakeDummyRec(VAR FR : TKR2Rec);
    BEGIN
        WITH FR.CryptRec DO BEGIN
            RecType := TRecType(RandLongRange(0, ORD(HIGH(TRecType))));
            Description := RandCompanyName;
            UserID := RandFullName;
            SerialNumber := RandPhoneNumber;
            Password := RandStr(8, 30);
            IconResource := RandLastName + '.ico';
            DTRNow(LastUpdate);
        END;
    END;

    {---------------}

    PROCEDURE MakeSomeRecs;
    VAR
        NewRecN        : LONGINT;
        I              : WORD;
        FR             : TKR2Rec;
    BEGIN
        FOR I := 1 TO 50 DO BEGIN
            MakeDummyRec(FR);
            IF KR2DBFile^.AddNewRecord(FR, NewRecN) <> 0 THEN
                DispErrorDeluxe('Can not add record to Database',
                                IsamErrorMessage(IsamError),
                                TRUE,
                                Iam);
        END;
    END;

    {---------------}

    PROCEDURE Doit;
    VAR
        ID             : FILE;
        Buff           : PCHAR;
        Result,
        BuffSize       : WORD;
        LineNum,
        NewPos         : LONGINT;
        FR             : TKR2Rec;
        COP            : CylonP;
        NeedsRefresh   : BOOLEAN;
    BEGIN
        Savemode := FALSE;
        SelectFont8x8(TRUE);
        WINDOW(1, 1, ScreenWidth, ScreenHeight);
        ClrScr;
        {$IFDEF Novell}
        {Initialize synchronization semaphore for Novell}
        IF BTNetSupported = Novell THEN
            IF Sync.Init(FName, 2) THEN
                RefreshPeriod := 9 {check every half of a second}
            ELSE BEGIN
                DispErrorDeluxe('Error initializing semaphore object. Aborting', '', TRUE, Iam);
                HALT(1);
            END;

        {$ENDIF}

        NeedsRefresh := NOT ExistFile(KR2DBFileName);

        {Initialize DATABASE}
        InitBTree;

        InitDBFiles;

        MakeSomeRecs;

        (*
        IF NeedsRefresh THEN BEGIN
            BuffSize := MinLong(MaxHeap, MAXAVAIL);
            GETMEM(Buff, BuffSize);
            IF Buff = NIL THEN BEGIN
                DispErrorDeluxe('Insufficient memory', '', TRUE, Iam);
                EXIT;
            END;

            ASSIGN(ID, '00global.txt');
            RESET(ID, 1);

            NEW(COP, Init('Refreshing Database', 10));
            COP^.Draw;

            LineNum := 0;

            REPEAT
                COP^.Update;
                BLOCKREAD(ID, Buff^, BuffSize, Result);

                newpos := ParseBuff(Buff, Result, FILEPOS(ID), FR, COP, LineNum);
                IF BuffSize <> Result THEN
                    BREAK;

                {back up a little and take care of dregs left in last buffer}
                SEEK(ID, newpos);
            UNTIL FALSE;

            {end of the ascii file, so close up shop}
            CLOSE(ID);
            FREEMEM(Buff, BuffSize);
            DISPOSE(COP, Done);
        END
        ELSE
        *)
        BrowseDB;

        DeInitDBFiles;
        DeInitBTree;
        SelectFont8x8(FALSE);
        WINDOW(1, 1, ScreenWidth, ScreenHeight);
        ClrScr;
    END;

BEGIN
    Doit;
END.


