{$M 65000,0,655360}
UNIT DelayCal;
interface
PROCEDURE DelaySelfCal;
implementation
USES
    OpCRT,
    OpDos;

    {------------}

    PROCEDURE DelaySelfCal;
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
                INC(LongOneMs);
                INC(Elapsed);
            END;
            LongOneMs := TRUNC((LongOneMs * (SampleTime / Elapsed)));

            WRITE('.');

            IF ABS(Error) < (SampleTime / 33.3) THEN
                BREAK;

        UNTIL FALSE;
    END;

end.