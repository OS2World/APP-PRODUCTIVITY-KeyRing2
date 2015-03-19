PROGRAM BFTest;
USES
    BlowFish,
    Desunit,
    DGMath,
    STRCRC,
    VARDEC;

    {------------}

    PROCEDURE Bf;
    VAR
        P              : PArray;
        S              : SBox;
        I,
        L              : LONGINT;
        Strg           : STRING;
        Hdr : TCryptHead;
    BEGIN
        Strg := 'Now is the time for all good men to come to the aid of their countries';
        L := LENGTH(Strg) + 1;

        InitBlowFish('Your momma cant dance', P, S, Hdr);

        EncryptBuff(Strg, L, P, S);

        InitBlowFish('Your momma cant dance', P, S, Hdr);
        DecryptBuff(Strg, L, P, S);
        WRITELN(Strg);
    END;

    {------------}

    PROCEDURE DEStst;
    VAR
        Instrg,
        OutStrg,
        Key            : STRING;
        L              : BYTE;
        C              : COMP;
    BEGIN
        {                 1         2         3         4       }
        {        12345678901234567890123456789012345678901234567}
        Instrg := 'This is a test of the DES algorithm hello world1';
        Key := 'helloworld';
        (*
        C := Calc64BitCRC(Key);
        DES(instrg, instrg, C, EENCRYPT);
        writeln(OutStrg);
        DES(Instrg, Instrg, C, EDECRYPT);
        Writeln(InStrg);
        *)
        L := LENGTH(Instrg);
        DESEncryptBuff(Instrg, L);
        writeln(InStrg);
        DESDecryptBuff(Instrg, L);
        writeln(InStrg);
    END;

    {------------}

    PROCEDURE DoIt;
    VAR
        I              : LONGINT;
        C              : COMP;
    BEGIN
        Bf;
        DEStst;
    END;

    {------------}

BEGIN
    DoIt;
END.
