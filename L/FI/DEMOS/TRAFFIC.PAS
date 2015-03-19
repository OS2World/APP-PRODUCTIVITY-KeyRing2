{Copyright (C) 1992-1994 ENZ EDV-Beratung GmbH}
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)

{-Test program to reach network or multitasking traffic in a given frequency

  Usage:
    Traffic (/N | /M | /O) (/R | /W | /Bx) [/Dy] [/Tz] [/Ff] [/Ll]
  /N : Novell
  /M : MsNet
  /O : without a Net

  /R : read only
  /W : write only
  /B : both read and write (after x reads a write is done)

  /D : delay time of y milliseconds after each operation (default 100ms)

  /T : timeout of z milliseconds for each operation
       (default IsamLockTimeOut ms)

  /F : timeout factor f for fileblock lock in relation to readlock
       (default IsamFBLockTimeOutFactor)

  /L : delay time of l milliseconds after a failed lock attempt
       (default IsamDelayBetwLocks ms)


  If not used with /R the fileblock "TRAFFIC" with TrafficKeys (default 4)
  keys may be created}


{--Conditional defines and compiler options}
{$I BTDefine.Inc}
{$F-,V-,B-,S-,I-,R-}
{$IFDEF CanSetOvrflowCheck}
{$Q-}
{$ENDIF}


PROGRAM Traffic;

USES
  apmisc,
  Kerror,
    {$IFDEF Windows}
  {$IFDEF Ver80}
  SysUtils,
  {$ENDIF}
  WinTypes,
  WinProcs,
  WinCrt,
{$ELSE}
    CRT,
    {$ENDIF}
    Filer;                        {!!.TP}

CONST
    TrafficFBName  = 'TRAFFIC';
    TrafficKeys    = 4;
    {-Must be in range 4..21}
    TrafficFillSize = 300;
    {-Actual Record size will be 5 + (12 * TrafficKeys) + TrafficFillSize}
    RandomMax      = 65535;

TYPE
    TrafficRecDef  = RECORD
                         Null,
                         CheckSum       : LONGINT;
                         S              : STRING[12 * TrafficKeys];
                         Fill           : ARRAY[1..TrafficFillSize] OF BYTE;
                     END;

    OperationModeDef = (ReadOnly, WriteOnly, both);

    JournalRec     = RECORD
                         Reads,
                         Writes,
                         Locks,
                         Dups,
                         CRCFails,
                         StartTime,
                         StopTime       : LONGINT;
                     END;

VAR
    DelayTime      : WORD;
    OperationMode  : OperationModeDef;
    NrOfReadsEachWrite : WORD;
    NetToInit      : NetSupportType;
    TrafficFB      : IsamFileBlockPtr;
    Journal        : JournalRec;
    SaveExitProc   : POINTER;


    PROCEDURE ShowParams;

    BEGIN                         {!!.TP - translations}
        WRITELN;
        WRITELN('Usage:');

        WRITELN('  Traffic (/N | /M | /O) (/R | /W | /Bx) '
                + '[/Dy] [/Tz] [/Ff] [/Ll]');
        WRITELN;
        WRITELN('/N : Novell');
        WRITELN('/M : MsNet (or compatible)');
        WRITELN('/O : No net');
        WRITELN;
        WRITELN('/R : Read only');
        WRITELN('/W : Write only');
        WRITELN('/B : both read and write (after x reads a write is done)');
        WRITELN;
        WRITELN('/D : delay time of y milliseconds after each operation '
                + '(default 100ms)');
        WRITELN;
        WRITELN('/T : timeout of z milliseconds for each operation (default ',
                IsamLockTimeOut, 'ms)');
        WRITELN;
        WRITELN('/F : timeout factor f for fileblock lock in relation '
                + 'to readlock (default ', IsamFBLockTimeOutFactor, ')');
        WRITELN;
        WRITELN('/L : delay time of l milliseconds after a failed '
                + 'lock attempt (default ', IsamDelayBetwLocks, 'ms)')
    END;


    FUNCTION GetParams : BOOLEAN;

    CONST
        MaxParams      = 6;
        FixParams      = 2;

    VAR
        P              : STRING[20];
        Error          : INTEGER;
        Value          : WORD;
        I              : WORD;

    BEGIN
        GetParams := FALSE;

        IF NOT(PARAMCOUNT IN [FixParams..MaxParams]) THEN
            EXIT;

        P := PARAMSTR(1);
        IF P[1] <> '/' THEN
            EXIT;
        DELETE(P, 1, 1);
        IF LENGTH(P) <> 1 THEN
            EXIT;
        CASE UPCASE(P[1]) OF
            'N' :
                NetToInit := Novell;
            'M' :
                NetToInit := MsNet;
            'O' :
                NetToInit := NoNet;
            ELSE EXIT;
        END;                      {Case}

        P := PARAMSTR(2);
        IF P[1] <> '/' THEN
            EXIT;
        DELETE(P, 1, 1);
        IF LENGTH(P) = 0 THEN
            EXIT;
        CASE UPCASE(P[1]) OF
            'R' :
                OperationMode := ReadOnly;
            'W' :
                OperationMode := WriteOnly;
            'B' :
                BEGIN
                    DELETE(P, 1, 1);
                    VAL(P, NrOfReadsEachWrite, Error);
                    IF Error <> 0 THEN
                        EXIT;
                    OperationMode := both;
                END;
            ELSE EXIT;
        END;                      {Case}

        DelayTime := 100;
        FOR I := SUCC(FixParams) TO PARAMCOUNT DO BEGIN
            P := PARAMSTR(I);
            IF P[1] <> '/' THEN
                EXIT;
            DELETE(P, 1, 1);
            IF LENGTH(P) = 0 THEN
                EXIT;
            CASE UPCASE(P[1]) OF
                'D',
                'T',
                'F',
                'L' :
                    BEGIN
                        VAL(COPY(P, 2, 255), Value, Error);
                        IF Error <> 0 THEN
                            EXIT;
                        CASE UPCASE(P[1]) OF
                            'D' :
                                DelayTime := Value;
                            'T' :
                                IsamLockTimeOut := Value;
                            'F' :
                                IsamFBLockTimeOutFactor := Value;
                            'L' :
                                IsamDelayBetwLocks := Value;
                        END;      {Case}
                    END;
                ELSE EXIT;
            END;                  {Case}
        END;

        GetParams := TRUE;
    END;


    FUNCTION GetBiosMSCount : LONGINT;

    TYPE
        PLongInt       = ^LONGINT;

    BEGIN
        {$IFDEF Windows}
        GetBiosMSCount := GetTickCount;
        {$ELSE}
        {$IFDEF DPMI}
        GetBiosMSCount := PLongInt (Ptr (Seg0040, $6C))^ * 55;
        {$ELSE}
        GetBiosMSCount := PLongInt(PTR($40, $6C))^ * 55;
        {$ENDIF}
        {$ENDIF}
    END;


    FUNCTION PrepareFileBlock : BOOLEAN;

    VAR
        PSS            : LONGINT;
        S              : STRING;

        FUNCTION CreateFB : BOOLEAN;

        VAR
            IID            : IsamIndDescr;
            I              : WORD;

        BEGIN
            CreateFB := FALSE;

            WITH IID[1] DO BEGIN
                KeyL := 12;
                AllowDupK := FALSE;
            END;
            FOR I := 2 TO TrafficKeys DO BEGIN
                WITH IID[I] DO BEGIN
                    KeyL := 12;
                    AllowDupK := TRUE;
                END;
            END;
            BTCreateFileBlock(TrafficFBName, SIZEOF(TrafficRecDef),
                              TrafficKeys, IID);
            IF NOT IsamOk THEN
                EXIT;

            CreateFB := TRUE;
        END;


    BEGIN
        PrepareFileBlock := FALSE;
        WRITELN;
        RANDOMIZE;
        PSS := BTInitIsam(NetToInit, MEMAVAIL - 100000, 0);
        IF NOT IsamOk THEN
            EXIT;
        BTOpenFileBlock(TrafficFB, TrafficFBName, FALSE, FALSE, FALSE, TRUE);
        IF IsamError = 9903 THEN BEGIN
            IF OperationMode = ReadOnly THEN
                EXIT;
            IF NOT CreateFB THEN
                EXIT;
            BTOpenFileBlock(TrafficFB, TrafficFBName, FALSE, FALSE, FALSE, TRUE);
            IF NOT IsamOk THEN
                EXIT;
            S := 'created and ';  {!!.TP}
        END ELSE BEGIN
            IF NOT IsamOk THEN
                EXIT;
            S := '';
        END;

        WRITELN('B-Tree Filer initialized with ', PSS SHR 16, '/', {!!.TP}
                PSS AND $FFFF, ' page buffers'); {!!.TP}
        WRITELN('Fileblock TRAFFIC ' + S + 'opened successfully'); {!!.TP}
        CASE BTNetSupported OF
            NoNet :
                S := 'Supported net: NoNet'; {!!.TP}
            Novell :
                S := 'Supported net: Novell'; {!!.TP}
            MsNet :
                S := 'Supported net: MsNet'; {!!.TP}
        END;
        WRITELN(' ==> ' + S + '      Dialog ID: ', {!!.TP}
                BTGetInternalDialogID(TrafficFB));
        WRITELN('Abort test with <Esc>'); {!!.TP}
        PrepareFileBlock := TRUE;
    END;


    FUNCTION DoTraffic : BOOLEAN;

    VAR
        C              : CHAR;
        ReadCount      : WORD;
        CurOper        : OperationModeDef;


        PROCEDURE BuildString(Nr : LONGINT; VAR DataStr : STRING);

        VAR
            I              : WORD;
            St             : ARRAY[1..TrafficKeys] OF STRING[12];

        BEGIN
            STR(Nr:12, St[1]);
            St[2] := '            ';
            FOR I := 1 TO 12 DO BEGIN
                St[2][I] := St[1][13 - I];
            END;
            STR(RandomMax - Nr:12, St[3]);
            FOR I := 4 TO TrafficKeys DO BEGIN
                STR(Nr MOD 10:12, St[I]);
            END;
            DataStr := St[2] + St[1];
            FOR I := 3 TO TrafficKeys DO BEGIN
                DataStr := DataStr + St[I];
            END;
        END;


        FUNCTION getkey(VAR DataStr    : STRING;
                        KeyNr          : INTEGER) : STRING;

        BEGIN
            getkey := '';
            CASE KeyNr OF
                0 : ;
                1 :
                    getkey := COPY(DataStr, 13, 12);
                2 :
                    getkey := COPY(DataStr, 1, 12);
                ELSE BEGIN
                    getkey := COPY(DataStr, SUCC(PRED(KeyNr) * 12), 12);
                END;
            END;                  {Case}
        END;

        function CalcCheckSum(VAR TrafficRec : TrafficRecDef):LONGINT;
        var
            I : WORD;
            CRC : LONGINT;
        begin
            CRC := 0;
            for I := 1 to trafficfillsize do
                CRC := UpdateCrc32(trafficrec.fill[i], CRC);

            CalcCheckSum := CRC;
        end;

        function CheckCRC(VAR TrafficRec:TrafficRecDef):BOOLEAN;
        begin
            CheckCRC := trafficRec.checksum = calcchecksum(trafficRec);
        end;

        procedure RandFill(VAR TrafficRec:TrafficRecDef);
        var
            I : word;
        begin
            FILLCHAR(TrafficRec.Fill, SIZEOF(TrafficRec.Fill), 0);
            for I := 1  to TrafficFillSize do
               trafficrec.fill[i] := random($100);
            trafficrec.checksum := calcCheckSum(TrafficRec);
        end;

        FUNCTION AddRecord : INTEGER;

        VAR
            I              : WORD;
            RefNr          : LONGINT;
            TrafficRec     : TrafficRecDef;
        BEGIN
            TrafficRec.Null := 0;
            BuildString(SUCC(RANDOM(RandomMax)), TrafficRec.S);
            randfill(TrafficRec);
            BTLockFileBlock(TrafficFB);
            AddRecord := BTIsamErrorClass;
            IF NOT IsamOk THEN
                EXIT;
            IF BTKeyExists(TrafficFB, 1, 0, getkey(TrafficRec.S, 1)) THEN BEGIN
                BTUnLockFileBlock(TrafficFB);
                IF IsamOk THEN BEGIN
                    AddRecord := - 1;
                END
                ELSE BEGIN
                    AddRecord := BTIsamErrorClass;
                END;
                EXIT;
            END;
            BTAddRec(TrafficFB, RefNr, TrafficRec);
            IF NOT IsamOk THEN BEGIN
                AddRecord := BTIsamErrorClass;
                BTUnLockFileBlock(TrafficFB);
                IF NOT IsamOk THEN BEGIN
                    AddRecord := BTIsamErrorClass;
                END;
                EXIT;
            END;
            FOR I := 1 TO TrafficKeys DO BEGIN
                BTAddKey(TrafficFB, I, RefNr, getkey(TrafficRec.S, I));
                IF NOT IsamOk THEN BEGIN
                    AddRecord := BTIsamErrorClass;
                    BTUnLockFileBlock(TrafficFB);
                    IF NOT IsamOk THEN BEGIN
                        AddRecord := BTIsamErrorClass;
                    END;
                    EXIT;
                END;
            END;
            BTUnLockFileBlock(TrafficFB);
            AddRecord := BTIsamErrorClass;
        END;


        FUNCTION GetRecord : INTEGER;

        VAR
            RefNr          : LONGINT;
            TrafficRec     : TrafficRecDef;
            MyKey          : IsamKeyStr;
            MyKeyNr        : WORD;

        BEGIN
            BuildString(SUCC(RANDOM(RandomMax)), TrafficRec.S);
            BTReadLockFileBlock(TrafficFB);
            GetRecord := BTIsamErrorClass;
            IF NOT IsamOk THEN
                EXIT;
            MyKeyNr := SUCC(RANDOM(TrafficKeys));
            MyKey := getkey(TrafficRec.S, MyKeyNr);
            RefNr := SUCC(RANDOM(RandomMax));

            BTSearchKeyAndRef(TrafficFB, MyKeyNr, RefNr, MyKey);
            IF NOT IsamOk THEN BEGIN
                GetRecord := BTIsamErrorClass;
                BTUnLockFileBlock(TrafficFB);
                IF NOT IsamOk THEN BEGIN
                    GetRecord := BTIsamErrorClass;
                END;
                EXIT;
            END;
            BTGetRec(TrafficFB, RefNr, TrafficRec, FALSE);
            GetRecord := BTIsamErrorClass;
            BTUnLockFileBlock(TrafficFB);
            IF NOT IsamOk THEN BEGIN
                GetRecord := BTIsamErrorClass;
                exit;
            END;
            if not checkcrc(trafficrec) then
                GetRecord := 3;
        END;


    BEGIN
        DoTraffic := FALSE;
        ReadCount := 0;
        CurOper := OperationMode;
        CheckBreak := FALSE;
        FILLCHAR(Journal, SIZEOF(Journal), 0);
        Journal.StartTime := GetBiosMSCount;
        C := #0;
        REPEAT
            IF OperationMode = both THEN BEGIN
                IF ReadCount >= NrOfReadsEachWrite THEN BEGIN
                    CurOper := WriteOnly;
                    ReadCount := 0;
                END ELSE BEGIN
                    CurOper := ReadOnly;
                    INC(ReadCount);
                END;
            END;
            CASE CurOper OF
                WriteOnly :
                    BEGIN
                        CASE AddRecord OF
                            - 1 : BEGIN
                                      WRITE('O');
                                      INC(Journal.Dups);
                                  END;
                            0 : BEGIN
                                    WRITE(':');
                                    INC(Journal.Writes);
                                END;
                            2 : BEGIN
                                    WRITE('X');
                                    INC(Journal.Locks);
                                END;
                            ELSE EXIT;
                        END;      {Case}
                    END;
                ReadOnly :
                    BEGIN
                        CASE GetRecord OF
                            0 : BEGIN
                                    WRITE('.');
                                    INC(Journal.Reads);
                                END;
                            1 : BEGIN
                                    WRITE('o');
                                END;
                            2 : BEGIN
                                    WRITE('x');
                                    INC(Journal.Locks);
                                END;
                            3:  BEGIN
                                    WRITE('c');
                                   inc(journal.CRCFails);
                                END;
                            ELSE EXIT;
                        END;      {Case}
                    END;
            END;                  {Case}
            IsamDelay(DelayTime);
            IF KeyPressed THEN
                C := ReadKey;
        UNTIL C = #27;
        WRITELN;
        DoTraffic := TRUE;
    END;


    PROCEDURE DisplayJournal;     {!!.TP - translations}

    VAR
        CurTime,
        TimeDiff,
        TotalOps       : LONGINT;

    BEGIN
        WITH Journal DO BEGIN
            StopTime := GetBiosMSCount;
            TimeDiff := (StopTime - StartTime) DIV 1000;
            IF TimeDiff < 1 THEN
                TimeDiff := 1;

            CASE OperationMode OF
                ReadOnly :
                    TotalOps := Reads;
                WriteOnly :
                    TotalOps := Writes;
                both :
                    TotalOps := Reads + Writes;
            END;

            WRITELN;
            WRITELN(' Summary ');
            WRITELN(' ======= ');
            WRITELN(' Test running time    : ', TimeDiff, ' seconds');
            WRITELN;

            WRITE(' Read operations      : ', Reads:10);
            IF Reads <> 0 THEN BEGIN
                WRITELN('     (approx. ', Reads / TimeDiff:6:2, ' per second)');
            END
            ELSE BEGIN
                WRITELN;
            END;

            WRITE(' Write operations     : ', Writes:10);
            IF Writes <> 0 THEN BEGIN
                WRITELN('     (approx. ', Writes / TimeDiff:6:2, ' per second)');
                IF Dups <> 0 THEN BEGIN
                    WRITE('           duplicates : ', Dups:10);
                    WRITELN('     (about every ', Writes DIV Dups,
                            ' writes)');
                END;
            END ELSE BEGIN
                WRITELN;
            END;

            WRITE(' File lock failures   : ', Locks:10);
            IF Journal.Locks <> 0 THEN BEGIN
                WRITELN('     (about every ', TotalOps DIV Locks,
                        ' locks)');
            END
            ELSE BEGIN
                WRITELN;
            END;

            WRITE(' CRC failures         : ', crcfails:10);
            IF Journal.crcfails <> 0 THEN BEGIN
                WRITELN('     (about every ', TotalOps DIV crcfails,
                        ' locks)');
            END
            ELSE BEGIN
                WRITELN;
            END;
        END;
    END;


    {$F+}
    PROCEDURE TrafficExitProc;

    BEGIN
        IF NOT IsamOk THEN BEGIN
            {
            WRITELN;
            WRITELN('IsamError: ', IsamError);
            }
            DispErrorDeluxe('Traffic Panic!',
            ErrorMessage(ISAMERROROFST+IsamError),
            FALSE,
            Iam);
        END;
        EXITPROC := SaveExitProc;
    END;


BEGIN                             {!!.TP - translations}
    ClrScr;

    IF BTNoNetCompiled THEN BEGIN
        WRITELN;
        WRITELN('This test program can only be used when B-Tree Filer has');
        WRITELN('been compiled for network mode.');
        WRITELN('Please activate one of the network compiler defines in');
        WRITELN('BTDEFINE.INC, rebuild the FILER unit, recompile this');
        WRITELN('program and try again.');

        HALT;
    END;

    IF NOT GetParams THEN BEGIN
        ShowParams;
        HALT;
    END;

    SaveExitProc := EXITPROC;
    EXITPROC := @TrafficExitProc;

    IF NOT PrepareFileBlock THEN
        HALT;

    IF DoTraffic THEN BEGIN
        BTCloseFileBlock(TrafficFB);
        IF IsamOk THEN
            BTExitIsam;
    END;

    DisplayJournal;
END.


