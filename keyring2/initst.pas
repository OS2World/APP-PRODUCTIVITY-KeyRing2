{~nokeywords~}
{}
PROGRAM INITST;

USES
    CMDLIN3,
    DGLIB,
    DGMath,
    KERROR,
    KRINI,
    kregutl,
    KRTree,
    {$IFDEF USEUNIT}
    KRYPTON,
    {$ENDIF}
    MsgMgr,
    OpDate,
    OpRoot,
    OpString,
    OS2REXX,
    STRCRC,
    SysMsg,
    SysUtils,
    UTIAM,
    UTTIMDAT,
    VARDEC;
CONST
    MyPassword     = 'aaaa';
    DatName        = 'kr2test.pwx';

var
    Buff : AnsiString;

    {----------------}

    PROCEDURE SetRet(Strg : AnsiString; VAR Ret : RxString);
    BEGIN
        writeln('strg ', Strg);
        Ret.StrLength := LENGTH(Strg);
        if Strg = NIL then
            Buff := #0
        else
            Buff := Strg + #0;

        Ret.StrPtr := @Buff[1];
    END;

    {--------------}

    procedure DoIt1;
    var
        Strg : AnsiString;
        I : word;
        MyRet : RxString;
    begin
        Strg := '';
        for I := 1 to 300 do
            Strg := Strg + '1234567890';
        SetRet(Strg, MyRet);
    end;

    {----------------}

    PROCEDURE DoIt5;
    VAR
        AddrIniTree    : PTreeReader;
        R              : TRecType;
        I              : WORD;
        F              : TField;
        T              : LONGINT;
        ROOT,
        Strg           : STRING;
        DTR            : DateTimeRec;
    BEGIN
        RMFile(DatName);
        T := 0;
        IF FileExists(DatName) THEN BEGIN
            WRITELN('decrypting');
            NEW(AddrIniTree, InitRead(DatName, MyPassword, TRUE)); {read group addresses, if ini exists}
            IF AddrIniTree = NIL THEN BEGIN
                DispErrorDeluxe(DatName + ' decrypt init fail', ErrorMessage(InitStatus), TRUE, Iam);
                HALT;
            END;
            WRITELN('done');
            writeln(addrinitree^.pwxlifetimeexpired);
            writeln(CalcPWXLifetimeLeft(currinceptdate));
            FOR R := LOW(TRecType) TO HIGH(TRecType) DO BEGIN
                FOR I := 1 TO 30 {RandLongRange(1, 10)} DO
                    WRITELN(AddrIniTree^.GetNthField(R, I, EDescr, 1));
            END;
        END
        ELSE BEGIN
            NEW(AddrIniTree, InitWrite(DatName)); {create empty INI if none exists}
            AddrIniTree^.ChangeInceptDate(Today - Param_Int('d', 59)); {d command line parameter sets incept date backwards}
            IF AddrIniTree = NIL THEN
                EXIT;
            FOR R := LOW(TRecType) TO HIGH(TRecType) DO BEGIN
                if r = ernone then
                    continue;
                FOR I := 1 TO RandLongRange(Param_Int('l', 10), Param_Int('h', 30)) DO BEGIN
                    WRITE('.');
                    if (T MOD 100) = 0 THEN
                        StrobeINI;

                    FOR F := LOW(TField) TO HIGH(TField) DO BEGIN
                        if F = EFNone then
                            continue;

                        ROOT := '>:SecretStuff:' + RecTypeNames[R] + ':' + Long2Str(I) + ':' + FieldNames[F];

                        CASE F OF
                            EDescr :
                                Strg := RandCompanyName;
                            ELastUpdate :
                                Strg := RandDTR(Today - 10, Today + 10, DTR);
                            EUserID :
                                Strg := RandFullName;
                            ESerialNumber :
                                Strg := HexL(RandLongRange(1000, 1000000));
                            EPassword :
                                Strg := RandStr(5, 10);
                            EIconResource :
                                Strg := '$ ' + Long2Str(RandLongRange(2,152)) + ':krini';
                            EExpire:
                                Strg := RandDTR(Today - 90, Today + 90, DTR);
                            EURL:
                                Strg := RandURL;
                            ENote:
                                Strg := 'this is a note. 124 1234 12343456346 457457457 sfdasf a sdg sdfg sdfgs gsdfgasf';
                        END;

                        IF NOT AddrIniTree^.AddVal(ROOT, Strg) THEN
                            EXIT;
                    END;
                END;
            END;
            WRITE('Crypting');
            IF NOT AddrIniTree^.WriteINI(DatName, MyPassword, TRUE) THEN
                EXIT;
            WRITELN;
            WRITELN('Done!');
        END;
        DISPOSE(AddrIniTree, Done);
    END;

    {--------------}

    PROCEDURE DoIt2;
    VAR
        AddrIniTree    : PTreeReader;
        R              : TRecType;
        I              : WORD;
        F              : TField;
        ROOT,
        Strg           : STRING;
        DTR            : DateTimeRec;
    BEGIN
        WRITELN('importing');
        NEW(AddrIniTree, InitRead('export.txt', MyPassword, False)); {read group addresses, if ini exists}
        IF AddrIniTree = NIL THEN BEGIN
            DispErrorDeluxe(DatName + ' decrypt init fail', ErrorMessage(InitStatus), TRUE, Iam);
            HALT;
        END;
        WRITELN('done');
        FOR R := LOW(TRecType) TO HIGH(TRecType) DO BEGIN
            FOR I := 1 TO 30 {RandLongRange(1, 10)} DO
                WRITELN(AddrIniTree^.GetNthField(R, I, EDescr, 1));
        END;
        DISPOSE(AddrIniTree, Done);
        writeln('done');
    END;

    {--------------}

    PROCEDURE DoIt3;
    VAR
        AddrIniTree    : PTreeReader;
        R              : TRecType;
        I              : WORD;
        F              : TField;
        ROOT,
        Strg           : STRING;
        DTR            : DateTimeRec;
    BEGIN
        WRITELN('importing');
        NEW(AddrIniTree, InitRead('export.txt', MyPassword, False)); {read group addresses, if ini exists}
        IF AddrIniTree = NIL THEN BEGIN
            DispErrorDeluxe(DatName + ' decrypt init fail', ErrorMessage(InitStatus), TRUE, Iam);
            HALT;
        END;
        WRITELN('done');
        FOR R := LOW(TRecType) TO HIGH(TRecType) DO BEGIN
            FOR I := 1 TO 30 {RandLongRange(1, 10)} DO
                WRITELN(AddrIniTree^.GetNthField(R, I, EDescr, 1));
        END;
        DISPOSE(AddrIniTree, Done);
        writeln('done');
    END;

    {--------------}

    procedure Doit;
    var
        Strg : STRING;
    begin

        writeln(Calc64BitCRC('the quick brown fox jumps over the lazy dogs back'));

        Strg := RandStringLimited(10, 20, ['A'..'Z', ' '..'/', '0'..'9', 'a'..'z']);
        writeln(Strg);
        Strg := RandStringLimited(10, 20, ['A'..'Z', 'a'..'z']);
        writeln(Strg);
        Strg := RandStringLimited(10, 20, ['0'..'9']);
        writeln(Strg);
        Strg := RandStringLimited(10, 20, [' '..'/']);
        writeln(Strg);
    end;

    {--------------}

    procedure Doit6;
    begin
       MsgMgrInit('kr2', 'kr2', ScnMsgP, PrnMsgP);
       writeln(ScnMsgP^.SysMsg(1));
    end;

    {--------------}

    procedure MergeTest;
    var
        MaleTree,
        FemaleTree    : PTreeReader;
    begin
        NEW(FemaleTree, InitRead('test.pwc', MyPassword, False));
        NEW(MaleTree, InitRead('test.pwc', MyPassword, False));
        FemaleTree^.MergeTree(MaleTree);
        FemaleTree^.WriteINI('test.pwc', MyPassword, FALSE);
        dispose(femaletree, done);
        dispose(maletree, done);
   end;

   procedure Doit7;
    VAR
        DTR,
        DTRN           : DateTimeRec;
        OldDate        : STRING;
        Days : LONGINT;
        D,
        M,
        Y              : INTEGER;
   begin
        DTRNow(DTRN);

        DTR.T := 0;
        DTR.D := DMYtoDate(10,11,2001);
        Days := ElapsedDays(DTRN, DTR);

  end;

CONST MAXKEY = 152;

TYPE
    TestArray = ARRAY[0..MAXKEY] OF BYTE;
    TestArrayPtr = ^TestArray;

    {- This method checks the randomness of the key sequence}
    {- The return value should be within +-2*SQRT(255) OF 255 (+-31.9?)}
    FUNCTION ChiSquare:REAL;
    VAR
        T : REAL;
        I : WORD;
        TAP : TestArrayPtr;
    BEGIN
        NEW(TAP);
        FILLCHAR(TAP^, SIZEOF(TestArray), 0);
        FOR I := 0 TO MAXKEY DO
            INC(TAP^[RandLongRange(0,152)]);

        T := 0.0;
        FOR I:=0 TO MAXKEY-1 DO
            T := T+TAP^[I]*TAP^[I];

        Result := ((255.0 * T/MAXKEY)-MAXKEY);
        DISPOSE(TAP);
    END;

    procedure Doit9;
    var
        I : WORD;
    begin
        for I := 1 to 100 do
            writeln(ChiSquare:3:3);
    end;
BEGIN
    writeln(InternationalDate(TRUE, TRUE));

    randomize;
    // writeln(DateStringToDate('dd/mm/yyyy', '01/12/1999'));
    // MergeTest;
    DoIt5;  // create some random records
    // Doit9;
    // Doit5;
END.
