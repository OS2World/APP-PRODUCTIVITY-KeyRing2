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
* OS2 INI file routines
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
UNIT IniMgr;

INTERFACE
USES
    VARDEC;

PROCEDURE BuildCRC(VAR RR : TINIRec);
FUNCTION CheckCRC(RR : TINIRec) : BOOLEAN;
FUNCTION Crypt(VAR RR : TINIRec; Mode : TCryptMode) : TRegStat;
FUNCTION ReadOS2INI(VAR RR : TINIRec) : BOOLEAN;
FUNCTION WriteOS2INI(RR : TINIRec) : BOOLEAN;

IMPLEMENTATION
USES
    ApMisc,
    DGMath,
    OpDate,
    OS2PMAPI,
    STRCRC,
    Strings;

    {----------------}

    PROCEDURE BuildCRC(VAR RR : TINIRec);
    VAR
        I              : WORD;
        TRR            : TINIRec;
        T              : ARRAY[1..$FFF] OF BYTE ABSOLUTE TRR;
        CRC            : LONGINT;
    BEGIN
        TRR := RR;
        CRC := - 1;
        FOR I := 1 TO SIZEOF(RR) - SIZEOF(LONGINT) DO
            CRC := UpDateCrc32(T[I], CRC);

        TRR.CRC := CRC;
        RR := TRR;
    END;

    {----------------}

    FUNCTION CheckCRC(RR : TINIRec) : BOOLEAN;
    VAR
        I              : WORD;
        TRR            : TINIRec;
        T              : ARRAY[1..$FF] OF BYTE ABSOLUTE TRR;
        CRC            : LONGINT;
    BEGIN
        TRR := RR;
        CRC := - 1;
        FOR I := 1 TO SIZEOF(RR) - SIZEOF(LONGINT) DO
            CRC := UpDateCrc32(T[I], CRC);
        CheckCRC := CRC = TRR.CRC;
    END;

    {----------------}

    FUNCTION Crypt(VAR RR : TINIRec; Mode : TCryptMode) : TRegStat;
    VAR
        I              : WORD;
        T              : ARRAY[1..SIZEOF(TINIRec)] OF BYTE ABSOLUTE RR;
        CRC,
        ORS,
        Pub,
        Priv           : LONGINT;
    BEGIN
        IF Mode = Encrypt THEN BEGIN
            {fill grunge fields with garbage}
            RANDOMIZE;
            FOR I := 1 TO SIZEOF(RR.Grunge1) DO
                RR.Grunge1[I] := RANDOM($100);
            FOR I := 1 TO SIZEOF(RR.Grunge2) DO
                RR.Grunge2[I] := RANDOM($100);
            FOR I := 1 TO SIZEOF(RR.Grunge3) DO
                RR.Grunge3[I] := RANDOM($100);
            FOR I := 1 TO SIZEOF(RR.Grunge4) DO
                RR.Grunge4[I] := RANDOM($100);
            FOR I := 1 TO SIZEOF(RR.Grunge5) DO
                RR.Grunge5[I] := RANDOM($100);
            FOR I := 1 TO SIZEOF(RR.Grunge6) DO
                RR.Grunge6[I] := RANDOM($100);
            RR.PubKey := RandLong;
            Pub := RR.PubKey;
            BuildCRC(RR);         {Build CRC on unencrypted data}
        END
        ELSE
            Pub := RR.PubKey;

        ORS := RANDSEED;
        RANDSEED := EPRIVKEY;

        FOR I := 1 TO SIZEOF(RR) - SIZEOF(LONGINT) DO
            T[I] := T[I] XOR BYTE(Pub XOR RANDOM($100));

        RANDSEED := ORS;

        RR.PubKey := Pub;

        IF Mode = Encrypt THEN BEGIN
            Crypt := ERegOk;
        END
        ELSE
            IF CheckCRC(RR) THEN  {Check CRC on unencrypted data}
                Crypt := ERegOk
        ELSE BEGIN
            Crypt := ERegCorrupt;
            FILLCHAR(RR, SIZEOF(RR), #0);
            RR.DropDead := Today + $FFFF;
        END;
    END;

    {----------------}

    FUNCTION ReadOS2INI(VAR RR : TINIRec) : BOOLEAN;
    VAR
        H              : hINI;
        S              : LONGINT;
        Strg           : STRING;
        AppNameP,
        KeyNameP       : ARRAY[1..30] OF CHAR;
    BEGIN
        H := HINI_USERPROFILE;
        S := SIZEOF(RR);

        Strg := DecodeStrg(SESTRS14, SESTRN14, SESTRP14) + #0; {KEYRING}
        StrCopy(@AppNameP, @Strg[1]);

        Strg := DecodeStrg(SESTRS15, SESTRN15, SESTRP15) + #0; {REGISTER}
        StrCopy(@KeyNameP, @Strg[1]);

        Result := PrfQueryProfileData(H, @AppNameP, @KeyNameP, @RR, S);
        IF RR.LastUsed.D = 0 THEN
            RR.LastUsed.D := BADDate;

        IF Result THEN
            Result := Crypt(RR, Decrypt) = ERegOk;
    END;

    {----------------}

    FUNCTION WriteOS2INI(RR : TINIRec) : BOOLEAN;
    VAR
        H              : hINI;
        Strg           : STRING;
        AppNameP,
        KeyNameP       : ARRAY[1..30] OF CHAR;
    BEGIN
        RR.PubKey := RandLong;
        RR.PrgVerMajor := 1;
        RR.PrgVerMinor := 0;
        Crypt(RR, Encrypt);
        H := HINI_USERPROFILE;

        Strg := DecodeStrg(SESTRS14, SESTRN14, SESTRP14) + #0; {KEYRING}
        StrCopy(@AppNameP, @Strg[1]);

        Strg := DecodeStrg(SESTRS15, SESTRN15, SESTRP15) + #0; {REGISTER}
        StrCopy(@KeyNameP, @Strg[1]);

        WriteOS2INI := PrfWriteProfileData(H, @AppNameP, @KeyNameP, @RR, SIZEOF(RR));
    END;

    {----------------}

END.
