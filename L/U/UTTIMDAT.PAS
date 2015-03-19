{****************************************************************************
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
* This unit implements a number of date functions missing from opdate.
* Included are dos style packed time functions that make conversions to and
* from opdate DateTimeRecs.  Note that DOS packed time LONGINTs have a
* granularity of 2 seconds!  Packed Time values are typically used to hold
* file time/date values.  They are economical for the storage of large
* quantities of medium precision timedate values.
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$D+,L+}
{&LocInfo+}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

UNIT UTTIMDAT;


INTERFACE
USES
    Dos,
    OpDate,
    OpString
    {$IFDEF VirtualPascal}
    , Os2Base,
    USE32
    {$ENDIF}
    ;

TYPE
    HiResTimeT     = RECORD
                         D              : Date;
                         T              : LONGINT;
                     END;
    {$ifdef VirtualPascal}
    KDateTimeRec   = RECORD
                         Ftime,
                         FDate          : SmallWord;
                     END;
    TOS2FileDate   = (EOS2LastWrite,
                      EOS2Creation,
                      EOS2LastAccess);

    {$endif}
    TFiscalQtr     = (EQ1, EQ2, EQ3, EQ4);

CONST
    FiscalQtrStr   : ARRAY[TFiscalQtr] OF STRING[3] =
    (
        '1st',
        '2nd',
        '3rd',
        '4th'
        );

    FiscalQtrEndMonth : ARRAY[TFiscalQtr] OF BYTE = (3, 6, 9, 12);

FUNCTION PackNow : LONGINT;
    {-Return longint containing packed current timedate }

PROCEDURE HiResPackNow(VAR T : HiResTimeT);
    {-Return high resolution packed current timedate}

PROCEDURE UnpackDOStime(DoSt : LONGINT; VAR T : OpDate.Time; VAR D : OpDate.Date);
    {-Return OPRO time and date values from packed timedate longint}

PROCEDURE DTRNow(VAR DTR : DateTimeRec);
    {-Return DT record filled with current time and date}

PROCEDURE DoStimeToDT(Dostime : LONGINT; VAR DTR : DateTimeRec);
    {-Return DT record from packed dos time value}

FUNCTION DTtoDOStime(DTR : DateTimeRec) : LONGINT;
    {-Return longint containing packed DOS version of input timedate }

FUNCTION DateTimeDiffSecs(Dt1, DT2 : DateTimeRec) : LONGINT;
    {-Return the positive difference in seconds between two points in time}

FUNCTION ElapsedSecs(Dt1 : DateTimeRec) : LONGINT;
    {-Return the positive elapsed seconds between now and Dt1}

FUNCTION TimedOut(DT1 : DateTimeRec; Seconds:LONGINT):BOOLEAN;
    {-Returns TRUE if Now-DT1 >= Seconds}

FUNCTION ElapsedDays(Dt1, DT2 : DateTimeRec) : LONGINT;
    {-Return the positive difference in days between two points in time}

FUNCTION DateTimeDiffSecsSigned(Dt1, DT2 : DateTimeRec) : LONGINT;
    {-Return the difference seconds between two points in time, returning signed longint}

FUNCTION DTRtoStringDeluxe(VAR DTR : DateTimeRec; ShowSeconds, Military : BOOLEAN) : STRING;
    {- translates DTR into a string - deluxe version}

FUNCTION NowStringDeluxe(ShowSeconds, Military : BOOLEAN) : STRING;
FUNCTION HTMLTime:STRING;
FUNCTION NowStringToDTR(Strg : STRING; ShowSeconds, Military : BOOLEAN; VAR DTR : DateTimeRec) : BOOLEAN; {reciprocal function}
FUNCTION DTRtoString(VAR DTR : DateTimeRec) : STRING;

PROCEDURE ChangeInternationalDateFmt(WholeYear, ZeroPad : BOOLEAN);
    {-change the format returned by DTRtoString}

FUNCTION GetInternationalDateFmt : STRING;
    {-get the current date format }

FUNCTION DateDiffSigned(D1, D2 : Date; VAR Days, Months, Years : INTEGER) : CompareType;

FUNCTION SecondsToTimeDateStr(Secs : LONGINT) : STRING;

FUNCTION DTRCompare(DTR1, DTR2 : DateTimeRec) : CompareType;

FUNCTION GetFileDTR(FName : PathStr; VAR DTR : DateTimeRec) : BOOLEAN;

FUNCTION DiffTimeStr(StartTime, StopTime : DateTimeRec) : STRING;
FUNCTION ElapsedTime(StartTime : DateTimeRec) : STRING;

FUNCTION DaysDiffSigned(D1, D2 : Date) : LONGINT;
FUNCTION MonthsDiffSigned(D1, D2 : Date) : LONGINT;
FUNCTION YearsDiffSigned(D1, D2 : Date) : LONGINT;
FUNCTION WeeksDiffSigned(D1, D2 : Date) : LONGINT;
    {-Return string containing current time and date }
FUNCTION DateToStdString(CONST D : Date) : STRING;

FUNCTION ValidDateStr(Dt : STRING; Mask : STRING) : BOOLEAN;
PROCEDURE ForceValidDate(VAR D          : INTEGER;
                         VAR M          : INTEGER;
                         VAR Y          : INTEGER);
    {$IFDEF VirtualPascal}
FUNCTION OS2FileTimeToDTR(VAR SR : FileFindBuf3; Mode : TOS2FileDate; VAR DTR : DateTimeRec) : BOOLEAN;
PROCEDURE DTRToOS2FileTime(DTR : DateTimeRec; VAR SR : FileFindBuf3; Mode : TOS2FileDate);
    {$ENDIF}
FUNCTION DateToFiscalQtr(CONST D1 : Date) : TFiscalQtr;
FUNCTION LastDayOfMonth(CONST D1 : Date) : Date;
FUNCTION DateToDaysInMonth(CONST D1 : Date) : BYTE;
FUNCTION DateToMonthNum(CONST D1 : Date) : BYTE;

    {return true if Now time is between start and stop times}
FUNCTION TimeInRange(CONST Hstart, Mstart, Sstart : BYTE; Now : Time; Hend, Mend, Send : BYTE) : BOOLEAN;
    (****************************************************************************)


IMPLEMENTATION
USES
    {$IFNDEF DLL}
    KERROR,
    {$ENDIF}
    OpDos,
    OpInline
    {$IFNDEF DLL}
    , UTIAM
    {$ENDIF}
    ;

CONST
    Ds             : DateString = 'mm/dd/yyyy';

    FUNCTION PackNow : LONGINT;
    VAR
        DTR            : DateTimeRec;
        T              : LONGINT;
    BEGIN
        DTRNow(DTR);
        DateTimeToPacked(DTR, T);
        PackNow := T;
    END;

    (****************************************************************************)

    {-Return high resolution packed current timedate}
    PROCEDURE HiResPackNow(VAR T : HiResTimeT);
    VAR
        Dt             : Dos.DateTime;
        Sec100         : WORD;
    BEGIN
        T.D := Today;
        {$IFDEF VirtualPascal}
        T.T := TimeMS;
        {$ELSE}
        GetTime(Dt.Hour, Dt.Min, Dt.Sec, Sec100);
        T.T := (CurrentTime SHL 7) + Sec100;
        {$ENDIF}
    END;

    {-------------------}

    FUNCTION DTtoDOStime(DTR : DateTimeRec) : LONGINT;
    VAR
        Dt             : Dos.DateTime;
        Dummy          : WORD;
        T              : LONGINT;
        H, M, S        : BYTE;
        D, Mo, Y       : INTEGER;
    BEGIN
        TimeToHMS(DTR.T, H, M, S);
        DateToDMY(DTR.D, D, Mo, Y);
        WITH Dt DO BEGIN
            Hour := H;
            Min := M;
            Sec := S;
            Day := D;
            Month := Mo;
            Year := Y;
        END;
        PackTime(Dt, T);
        DTtoDOStime := T;
    END;

    (****************************************************************************)

    PROCEDURE UnpackDOStime(DoSt : LONGINT; VAR T : OpDate.Time; VAR D : OpDate.Date);
    VAR
        Dt             : Dos.DateTime;
    BEGIN
        UnPackTime(DoSt, Dt);
        T := HMStoTime(Dt.Hour, Dt.Min, Dt.Sec);
        D := DMYToDate(Dt.Day, Dt.Month, Dt.Year);
    END;

    (****************************************************************************)

    FUNCTION GetFileDTR(FName : PathStr; VAR DTR : DateTimeRec) : BOOLEAN;
    VAR
        f              : FILE;
        DoSt           : LONGINT;
        OFM,
        Stat           : WORD;
    BEGIN
        GetFileDTR := FALSE;
        DTR.D := BADDate;
        DTR.T := BadTime;
        IF NOT ExistFile(FName) THEN
            EXIT;

        ASSIGN(f, FName);
        OFM := FILEMODE;
        FILEMODE := 0;
        {$I-}
        RESET(f);
        Stat := IORESULT;
        IF Stat = 162 THEN BEGIN
            FILEMODE := OFM;
            EXIT;                 {somebody else has it open already}
        END;
        IF Stat <> 0 THEN BEGIN
            {$IFNDEF DLL}
            DispErrorDeluxe('Problem opening ' + FName,
                            ErrorMessage(Stat), TRUE, Iam);
            {$ENDIF}
            EXIT;
        END;
        GetFTime(f, DoSt);
        CLOSE(f);
        FILEMODE := OFM;
        DoStimeToDT(DoSt, DTR);
        {$I+}
        GetFileDTR := TRUE;
    END;

    (****************************************************************************)

    PROCEDURE DTRNow(VAR DTR : DateTimeRec);
    BEGIN
        DTR.D := Today;
        DTR.T := OpDate.CurrentTime;
    END;

    (****************************************************************************)

    PROCEDURE DoStimeToDT(Dostime : LONGINT; VAR DTR : DateTimeRec);
        {-Return DT record from packed dos time value}
    VAR
        Dt             : Dos.DateTime;
    BEGIN
        UnPackTime(Dostime, Dt);
        DTR.D := DMYToDate(Dt.Day, Dt.Month, Dt.Year);
        DTR.T := HMStoTime(Dt.Hour, Dt.Min, Dt.Sec);
    END;

    (****************************************************************************)

    FUNCTION DateTimeDiffSecs(Dt1, DT2 : DateTimeRec) : LONGINT;
        {-Return the difference seconds between two points in time}
    VAR
        Days           : Longint;
    BEGIN
        {swap if DT1 later than DT2}
        IF (Dt1.D > DT2.D) OR ((Dt1.D = DT2.D) AND (Dt1.T > DT2.T)) THEN
            ExchangeStructs(Dt1, DT2, SIZEOF(DateTimeRec));

        {the difference in days is easy}
        Days := DT2.D - Dt1.D;

        {Prevent overflow}
        if Days > 24854 then
            Days := 24854;

        {difference in seconds}
        IF DT2.T < Dt1.T THEN BEGIN
            {subtract one day, add 24 hours}
            DEC(Days);
            INC(DT2.T, SecondsInDay);
        END;
        {$R-}
        DateTimeDiffSecs := (DT2.T - Dt1.T) + (Days * SecondsInDay);
        {$R+}
    END;

    (****************************************************************************)

    FUNCTION ElapsedSecs(Dt1 : DateTimeRec) : LONGINT;
        {-Return the positive elapsed seconds between now and Dt1}
    VAR
        DTR: DateTimeRec;
    BEGIN
        DTRNow(DTR);
        ElapsedSecs := DateTimeDiffSecs(DTR, Dt1);
    END;

    (****************************************************************************)

    FUNCTION TimedOut(DT1 : DateTimeRec; Seconds:LONGINT):BOOLEAN;
    {-Returns TRUE if Now-DT1 >= Seconds}
    BEGIN
        TimedOut := ElapsedSecs(DT1) >= Seconds;
    END;

    (****************************************************************************)

    {-Return the positive difference in days between two points in time}
    FUNCTION ElapsedDays(Dt1, DT2 : DateTimeRec) : LONGINT;
    BEGIN
        ElapsedDays := DateTimeDiffSecs(Dt1, DT2) DIV SecondsInDay;
    END;

    (****************************************************************************)

    FUNCTION DateDiffSigned(D1, D2 : Date; VAR Days, Months, Years : INTEGER) : CompareType;
    BEGIN
        DateDiff(D1, D2, Days, Months, Years);
        IF D1 > D2 THEN
            DateDiffSigned := Greater
        ELSE
            IF D1 < D2 THEN
                DateDiffSigned := Less
        ELSE
            DateDiffSigned := EQUAL;
    END;

    (****************************************************************************)

    FUNCTION DaysDiffSigned(D1, D2 : Date) : LONGINT;
    BEGIN
        DaysDiffSigned := D1 - D2;
    END;

    (****************************************************************************)

    FUNCTION WeeksDiffSigned(D1, D2 : Date) : LONGINT;
    BEGIN
        WeeksDiffSigned := DaysDiffSigned(D1, D2) DIV 7;
    END;

    (****************************************************************************)

    FUNCTION MonthsDiffSigned(D1, D2 : Date) : LONGINT;
    VAR
        D,
        M,
        Y              : INTEGER;
        Tot,
        Sign           : LONGINT;
    BEGIN
        IF D1 > D2 THEN
            Sign := - 1
        ELSE
            Sign := 1;

        DateDiff(D1, D2, D, M, Y);
        Tot := M + (Y * 12);
        MonthsDiffSigned := Tot * Sign;
    END;

    (****************************************************************************)

    FUNCTION YearsDiffSigned(D1, D2 : Date) : LONGINT;
    VAR
        D,
        M,
        Y              : INTEGER;
        Sign           : LONGINT;
    BEGIN
        IF D1 > D2 THEN
            Sign := - 1
        ELSE
            Sign := 1;

        DateDiff(D1, D2, D, M, Y);
        YearsDiffSigned := Y * Sign;
    END;

    (****************************************************************************)

    FUNCTION DateTimeDiffSecsSigned(Dt1, DT2 : DateTimeRec) : LONGINT;
        {-Return the difference seconds between two points in time, using signed longint}
    VAR
        Days           : LONGINT;
        Sign           : LONGINT;
    BEGIN
        Sign := 1;
        {swap if DT1 later than DT2}
        IF (Dt1.D > DT2.D) OR ((Dt1.D = DT2.D) AND (Dt1.T > DT2.T)) THEN BEGIN
            ExchangeStructs(Dt1, DT2, SIZEOF(DateTimeRec));
            Sign := - 1;
        END;

        {the difference in days is easy}
        Days := DT2.D - Dt1.D;

        {difference in seconds}
        IF DT2.T < Dt1.T THEN BEGIN
            {subtract one day, add 24 hours}
            DEC(Days);
            INC(DT2.T, SecondsInDay);
        END;
        DateTimeDiffSecsSigned := ((DT2.T - Dt1.T) + (Days * SecondsInDay)) * Sign;
    END;

    (****************************************************************************)

    FUNCTION DTRCompare(DTR1, DTR2 : DateTimeRec) : CompareType;
    BEGIN
        DTRCompare := EQUAL;
        IF DTR1.D > DTR2.D THEN BEGIN
            DTRCompare := Greater;
            EXIT;
        END;
        IF DTR1.D < DTR2.D THEN BEGIN
            DTRCompare := Less;
            EXIT;
        END;
        IF DTR1.T > DTR2.T THEN BEGIN
            DTRCompare := Greater;
            EXIT;
        END;
        IF DTR1.T < DTR2.T THEN BEGIN
            DTRCompare := Less;
            EXIT;
        END;
    END;

    (****************************************************************************)

    FUNCTION DTRtoString(VAR DTR : DateTimeRec) : STRING;
        {-Return string containing current time and date }
    BEGIN
        DTRtoString := DateToDateString(Ds, DTR.D) +
                       TimeToTimeString(' hh:mm:ss te', DTR.T);
    END;                          {of func TimeDateNow}

    (****************************************************************************)

    {-Return string containing current time and date }
    FUNCTION DateToStdString(CONST D : Date) : STRING;
    BEGIN
        DateToStdString := DateToDateString(Ds, D);
    END;

    (****************************************************************************)

    {-Return string containing current time and date }
    FUNCTION DTRtoStringDeluxe(VAR DTR : DateTimeRec; ShowSeconds, Military : BOOLEAN) : STRING;
    VAR
        Strg           : STRING[30];
    BEGIN
        Strg := ' hh:mm';

        IF ShowSeconds THEN
            Strg := Strg + ':ss';

        IF NOT Military THEN
            Strg := Strg + ' te';

        DTRtoStringDeluxe := DateToDateString(Ds, DTR.D) +
                             TimeToTimeString(Strg, DTR.T);
    END;                          {of func DTRtoStringDeluxe}

    (****************************************************************************)

    FUNCTION NowStringDeluxe(ShowSeconds, Military : BOOLEAN) : STRING;
    VAR
        DTR            : DateTimeRec;
    BEGIN
        DTRNow(DTR);
        NowStringDeluxe := DTRtoStringDeluxe(DTR, ShowSeconds, Military);
    END;

    (****************************************************************************)

    FUNCTION HTMLTime:STRING;
    VAR
        Strg : STRING;
    BEGIN
        {20030428;17414974}
        HTMLTime := DateToDateString('yyyymmdd', Today) +';'+TimeToTimeString('hhmmss', OpDate.CurrentTime) + '50';
    END;

    (****************************************************************************)

    FUNCTION NowStringToDTR(Strg : STRING; ShowSeconds, Military : BOOLEAN; VAR DTR : DateTimeRec) : BOOLEAN;
    VAR
        TimeMask,
        TimeStr        : STRING;
    BEGIN
        DTR.D := DateStringToDate(Ds, COPY(Strg, 1, LENGTH(Ds)));
        TimeStr := Trim(COPY(Strg, LENGTH(Ds) + 1, 255));
        IF ShowSeconds THEN
            TimeMask := 'hh:mm:ss'
        ELSE
            TimeMask := 'hh:mm';

        IF NOT Military THEN
            TimeMask := TimeMask + ' te';
        DTR.T := TimeStringToTime(TimeMask, TimeStr);
        NowStringToDTR := DTR.D <> BADDate;
    END;

    (****************************************************************************)

    {-change the format returned by DTRtoString}
    PROCEDURE ChangeInternationalDateFmt(WholeYear, ZeroPad : BOOLEAN);
    BEGIN
        Ds := InternationalDate(WholeYear, ZeroPad);
    END;

    (****************************************************************************)

    FUNCTION GetInternationalDateFmt : STRING;
    BEGIN
        GetInternationalDateFmt := Ds;
    END;

    (****************************************************************************)

    FUNCTION SecondsToTimeDateStr(Secs : LONGINT) : STRING;
    VAR
        Strg           : STRING;
        D,
        H,
        M,
        S              : LONGINT;
        Neg            : BOOLEAN;
    BEGIN
        Strg := '';
        Neg := Secs < 0;
        Secs := ABS(Secs);
        H := (Secs DIV SecondsInHour) MOD 24;
        M := (Secs DIV SecondsInMinute) MOD 60;
        S := (Secs MOD SecondsInMinute) MOD 60;
        D := Secs DIV SecondsInDay;
        IF D > 0 THEN
            Strg := Long2Str(D) + ' Days, ';
        Strg := Strg +
                LeftPadCh(Long2Str(H), '0', 2) +
                ':' +
                LeftPadCh(Long2Str(M), '0', 2) +
                ':' +
                LeftPadCh(Long2Str(S), '0', 2);
        IF Neg THEN
            Strg := 'Minus ' + Strg;
        SecondsToTimeDateStr := Strg;
    END;

    (****************************************************************************)

    FUNCTION DiffTimeStr(StartTime, StopTime : DateTimeRec) : STRING;
    BEGIN
        DiffTimeStr := SecondsToTimeDateStr(DateTimeDiffSecsSigned(StartTime, StopTime));
    END;

    (****************************************************************************)

    FUNCTION ElapsedTime(StartTime : DateTimeRec) : STRING;
    VAR
        DTR            : DateTimeRec;
    BEGIN
        DTRNow(DTR);
        ElapsedTime := DiffTimeStr(StartTime, DTR);
    END;

    (****************************************************************************)

    FUNCTION ValidDateStr(Dt : STRING; Mask : STRING) : BOOLEAN;
    VAR
        D,
        M,
        Y              : INTEGER;
    BEGIN
        ValidDateStr := DateStringToDMY(Mask, Dt, D, M, Y);
    END;

    (****************************************************************************)

    PROCEDURE ForceValidDate(VAR D          : INTEGER;
                             VAR M          : INTEGER;
                             VAR Y          : INTEGER);
    BEGIN
        WHILE NOT ValidDate(D, M, Y) DO BEGIN
            M := M MOD 12;
            IF M = 0 THEN
                M := 1;
            D := D MOD DaysInMonth(M, Y);
            IF D = 0 THEN
                D := 1;
        END;
    END;

    (****************************************************************************)

    {$IFDEF VirtualPascal}

    FUNCTION OS2FileTimeToDTR(VAR SR : FileFindBuf3; Mode : TOS2FileDate; VAR DTR : DateTimeRec) : BOOLEAN;
    VAR
        Time           : LONGINT;
        FDateTime      : KDateTimeRec ABSOLUTE Time;
    BEGIN
        WITH SR DO BEGIN
            WITH FDateTime DO BEGIN
                CASE Mode OF
                    EOS2LastWrite :
                        BEGIN
                            Ftime := ftimelastwrite;
                            FDate := fDatelastwrite;
                        END;
                    EOS2Creation :
                        BEGIN
                            FDate := fdateCreation;
                            Ftime := ftimeCreation;
                        END;
                    EOS2LastAccess :
                        BEGIN
                            FDate := fdateLastAccess;
                            Ftime := ftimeLastAccess;
                        END;
                END;
            END;
        END;
        PackedToDateTime(Time, DTR);
    END;

    (****************************************************************************)

    PROCEDURE DTRToOS2FileTime(DTR : DateTimeRec; VAR SR : FileFindBuf3; Mode : TOS2FileDate);
    VAR
        Time           : LONGINT;
        FDateTime      : KDateTimeRec ABSOLUTE Time;
    BEGIN
        DateTimeToPacked(DTR, Time);
        WITH SR DO BEGIN
            WITH FDateTime DO BEGIN
                CASE Mode OF
                    EOS2LastWrite :
                        BEGIN
                            ftimelastwrite := Ftime;
                            fDatelastwrite := FDate;
                        END;
                    EOS2Creation :
                        BEGIN
                            fdateCreation := FDate;
                            ftimeCreation := Ftime;
                        END;
                    EOS2LastAccess :
                        BEGIN
                            fdateLastAccess := FDate;
                            ftimeLastAccess := Ftime;
                        END;
                END;
            END;
        END;
    END;

    (****************************************************************************)
    {$ENDIF}

    FUNCTION DateToFiscalQtr(CONST D1 : Date) : TFiscalQtr;
    VAR
        D,
        M,
        Y              : INTEGER;
    BEGIN
        DateToDMY(D1, D, M, Y);   {extract year}

        {1jan - 31 Mar}
        IF (D1 >= DMYToDate(1, 1, Y)) AND (D1 <= DMYToDate(31, 3, Y)) THEN
            DateToFiscalQtr := EQ1;

        {1apr - 30Jun}
        IF (D1 >= DMYToDate(1, 4, Y)) AND (D1 <= DMYToDate(30, 6, Y)) THEN
            DateToFiscalQtr := EQ2;

        {1jul - 30sep}
        IF (D1 >= DMYToDate(1, 7, Y)) AND (D1 <= DMYToDate(30, 9, Y)) THEN
            DateToFiscalQtr := EQ3;

        {1oct - 31dec}
        IF (D1 >= DMYToDate(1, 10, Y)) AND (D1 <= DMYToDate(31, 12, Y)) THEN
            DateToFiscalQtr := EQ4;
    END;

    {-------------}

    FUNCTION LastDayOfMonth(CONST D1 : Date) : Date;
    VAR
        Day,
        Month,
        Year           : INTEGER;
    BEGIN

        DateToDMY(D1, Day, Month, Year); {get dmy}
        INC(Month);               {bump to next month}

        Month := Month MOD 12;    {detect december rollover}
        IF Month = 0 THEN BEGIN
            INC(Month);
            INC(Year);
        END;

        {calc day before beginning of next month (end of this month)}
        LastDayOfMonth := DMYToDate(1, Month, Year) - 1;
    END;

    {-------------}

    FUNCTION DateToDaysInMonth(CONST D1 : Date) : BYTE;
    VAR
        Day,
        Month,
        Year           : INTEGER;
    BEGIN
        DateToDMY(D1, Day, Month, Year);
        DateToDaysInMonth := DaysInMonth(Month, Year);
    END;

    {-------------}

    FUNCTION DateToMonthNum(CONST D1 : Date) : BYTE;
    VAR
        Day,
        Month,
        Year           : INTEGER;
    BEGIN
        DateToDMY(D1, Day, Month, Year);
        DateToMonthNum := Month;
    END;

    {-------------}

    {return true if Now time is between start and stop times}
    FUNCTION TimeInRange(CONST Hstart, Mstart, Sstart : BYTE; Now : Time; Hend, Mend, Send : BYTE) : BOOLEAN;
    VAR
        Start,
        Stop           : Time;
    BEGIN
        Start := HMStoTime(Hstart, Mstart, Sstart);
        Stop := HMStoTime(Hend, Mend, Send);
        TimeInRange := (Now >= Start) AND (Now <= Stop)
    END;

    {unit initialization}
    {$IFNDEF DLL}
BEGIN
    Ds := InternationalDate(TRUE, TRUE);
    {$IFDEF HeapDEBUG}
    SetKHeapFunc;
    {$ENDIF}
    {$ENDIF DLL}
END.                              {of unit ktimedat}

(****************************************************************************)
(****************************************************************************)
