{$M 65000,0,655360}
PROGRAM DelayX;
USES
    OpCRT,
    OpDos,
    KERROR;

    {------------}

    PROCEDURE SelfCal;
    VAR
        Error          : REAL;
        Factor,
        Elapsed,
        T              : LONGINT;
    CONST
        SampleTime     = 2000;
    BEGIN
        REPEAT
            T := TimeMS;
            Delay(SampleTime);
            Elapsed := (TimeMS - T);
            Error := SampleTime - Elapsed;
            IF Elapsed = 0 THEN BEGIN
                INC(OneMs);
                INC(Elapsed);
            END;
            OneMs := TRUNC((OneMs * (SampleTime / Elapsed)));

            WRITELN('onems: ', OneMs, '  Elapsed: ', Elapsed, ' Error: ', Error:3:3);


            IF ABS(Error) < (SampleTime / 33.3) THEN
                BREAK;

        UNTIL FALSE;
    END;

    {------------}

    PROCEDURE Doit;
    VAR
        I              : WORD;
    BEGIN
        REPEAT
            DelayCalibrate;
            WRITELN(OneMs);
            SelfCal;
        UNTIL FALSE;
    END;

    {------------}

    PROCEDURE Hammer;
    BEGIN
        REPEAT
            DelayCalibrate;
            WRITELN(OneMs);
        UNTIL FALSE;
    END;

    {------------}

BEGIN
    ClrScr;
    {Hammer;}
    Doit;
END.

    {------------}
    {------------}
