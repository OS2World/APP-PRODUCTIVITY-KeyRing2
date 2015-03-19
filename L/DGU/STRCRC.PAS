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
* CRC calculators
*
* Copyright 2000, IDK, Inc.
* All Rights Reserved
*
*
* ~notesend~
*
***************************************************************************

}
{$N+,O+}
{&Delphi+}
UNIT STRCRC;
INTERFACE
USES
    ApMisc
    {$IFNDEF DLL}
    , KERROR
    {$ENDIF}
    {$IFDEF VirtualPascal}
    ,use32
    {$ENDIF}
    ;

FUNCTION CalcCRCStr(VAR T : LONGINT; Strg : STRING) : STRING;
FUNCTION CalcCRC(VAR T : LONGINT; Strg : STRING) : LONGINT;
FUNCTION CalcCRCExeSegment(Pstart, PEnd : POINTER; S : STRING; N, P, ExpectedCRC : LONGINT) : LONGINT;
FUNCTION CalcAddrRangeSig(Pstart, PEnd : POINTER) : LONGINT;
FUNCTION Calc64BitCRC(Strg : STRING) : COMP; {case sensitive}
FUNCTION CalcUpCase64BitCRC(Strg : STRING) : COMP; {case insensitive}
FUNCTION CalcFileCRC(FName : STRING {$IFNDEF DLL} ; COP : CylonP {$ENDIF} ) : LONGINT;
FUNCTION CalcBlockCRC(Block : POINTER; BlockSize : WORD; CONST CRC : LONGINT) : LONGINT;
FUNCTION DecodeStrg(S : STRING; PubKey, PrivKey : LONGINT) : STRING;
FUNCTION DecodeStrgP(S : STRING; PubKey, PrivKey : LONGINT) : PCHAR;
FUNCTION CalcPasswordCRC(Strg : STRING) : LONGINT;
FUNCTION EncodeStrg(S : STRING; PubKey, PrivKey : LONGINT) : STRING;
FUNCTION EnHexStrg(S : STRING) : STRING;

    {random string functions}
FUNCTION RandChar : STRING;
FUNCTION RandString(Len : BYTE) : STRING;
FUNCTION MakeARandomPath : STRING;
FUNCTION MakeRandomName : STRING;

    {---------------------}


IMPLEMENTATION

USES
    OpInline,
    OpRoot,
    OpString,
    {$ifdef virtualpascal}
    OS2BASE,
    OS2DEF,
    {$endif}
    Strings,
    UTTIMDAT;

    {------------}

    FUNCTION EnHexStrg(S : STRING) : STRING;
    VAR
        I,
        C              : BYTE;
        Strg           : STRING;
    BEGIN
        Strg := '';
        FOR I := 1 TO LENGTH(S) DO
            Strg := Strg + HexB(BYTE(S[I]));
        EnHexStrg := Strg;
    END;


    {------------}

    FUNCTION DecodeStrg(S : STRING; PubKey, PrivKey : LONGINT) : STRING;
    VAR
        Strg           : STRING;
        I              : BYTE;
        ORS            : LONGINT;
    BEGIN
        ORS := RANDSEED;
        RANDSEED := PubKey;
        {$IFDEF VirtualPascal}
        {$IFOPT H+}
        setlength(Strg, LENGTH(S));
        {$ELSE}
        Strg[0] := S[0];
        {$ENDIF}
        {$ELSE}
        Strg[0] := S[0];
        {$ENDIF virtualpascal}
        FOR I := 1 TO LENGTH(S) DO
            Strg[I] := CHAR(ORD(S[I]) XOR RANDOM($100) XOR PrivKey);
        DecodeStrg := Strg;
        RANDSEED := ORS;
    END;

    {--------------}

    FUNCTION DecodeStrgP(S : STRING; PubKey, PrivKey : LONGINT) : PCHAR;
    VAR
        Strg           : STRING;
    BEGIN
        Strg := DecodeStrg(S, PubKey, PrivKey);
        Strg[LENGTH(Strg) + 1] := #0;
        DecodeStrgP := StrNew(@Strg[1]);
    END;

    {--------------}

    FUNCTION EncodeStrg(S : STRING; PubKey, PrivKey : LONGINT) : STRING;
    BEGIN
        EncodeStrg := DecodeStrg(S, PubKey, PrivKey);
    END;

    {--------------}

    FUNCTION CalcAddrRangeSig(Pstart, PEnd : POINTER) : LONGINT;
    VAR
        I,
        J              : LONGINT;
    BEGIN
        J := 0;
        FOR I := PtrToLong(Pstart) TO PtrToLong(PEnd) DO
            J := UpDateCrc32(ORD(CHAR(LongToPtr(I)^)), J);
        CalcAddrRangeSig := J;
    END;

    {--------------}

    {if expectedcrc = 0 -> use encoded string crc value}
    {if expectedcrc =-1 -> return calculated  crc value}
    {else expectedcrc = NNNN.  If NNNN does not match calc'd value then halt}
    FUNCTION CalcCRCExeSegment(Pstart, PEnd : POINTER; S : STRING; N, P, ExpectedCRC : LONGINT) : LONGINT;
    VAR
        TFile          : TEXT;
        LastError      : WORD;
        J              : LONGINT;
    BEGIN
        J := CalcAddrRangeSig(Pstart, PEnd);
        IF ExpectedCRC = 0 THEN
            IF NOT Str2Long(DecodeStrg(S, N, P), ExpectedCRC) THEN
                HALT;

        IF (ExpectedCRC <> - 1) AND (J <> ExpectedCRC) THEN
            HALT;

        CalcCRCExeSegment := J;
    END;

    {--------------}

    FUNCTION CalcCRCStr(VAR T : LONGINT; Strg : STRING) : STRING;
    VAR
        I              : BYTE;
        S              : STRING;
    BEGIN
        FOR I := 1 TO LENGTH(Strg) DO
            T := UpDateCrc32(ORD(UPCASE(Strg[I])), T);

        CalcCRCStr := HexL(T);
    END;

    {------------}

    FUNCTION CalcCRC(VAR T : LONGINT; Strg : STRING) : LONGINT;
    VAR
        I              : BYTE;
        S              : STRING;
    BEGIN
        FOR I := 1 TO LENGTH(Strg) DO
            T := UpDateCrc32(ORD(UPCASE(Strg[I])), T);

        CalcCRC := T;
    END;

    {------------}

    FUNCTION CalcUpCase64BitCRC(Strg : STRING) : COMP;
    VAR
        C              : COMP;
        L              : ARRAY[1..2] OF LONGINT ABSOLUTE C;
        T              : LONGINT;
        I              : BYTE;
    BEGIN
        L[1] := - 1;
        L[2] := - 1;

        FOR I := 1 TO LENGTH(Strg) DO
            IF ODD(I) THEN
                L[1] := UpDateCrc32(ORD(UPCASE(Strg[I])), L[1])
            ELSE
                L[2] := UpDateCrc32(ORD(UPCASE(Strg[I])), L[2]);

        CalcUpCase64BitCRC := C;
    END;

    {------------}

    FUNCTION Calc64BitCRC(Strg : STRING) : COMP;
    VAR
        C              : COMP;
        L              : ARRAY[1..2] OF LONGINT ABSOLUTE C;
        T              : LONGINT;
        I              : BYTE;
    BEGIN
        L[1] := - 1;
        L[2] := - 1;

        FOR I := 1 TO LENGTH(Strg) DO
            IF ODD(I) THEN
                L[1] := UpDateCrc32(ORD(Strg[I]), L[1])
            ELSE
                L[2] := UpDateCrc32(ORD(Strg[I]), L[2]);

        Calc64BitCRC := C;
    END;

    {------------}

    FUNCTION CalcPasswordCRC(Strg : STRING) : LONGINT;
    VAR
        T              : LONGINT;
    BEGIN
        T := 0;
        CalcPasswordCRC := CalcCRC(T, StUpCase(Strg));
    END;

    {------------}

    {$IFNDEF VirtualPascal}
    FUNCTION CalcFileCRC(FName : STRING; COP : CylonP) : LONGINT;
    CONST
        ChunkSize      = $8000;
    VAR
        F              : FILE;
        I              : WORD;
        R              : WORD;
        C              : LONGINT;
        Buff           : ARRAY[1..ChunkSize] OF BYTE;
    BEGIN
        C := - 1;
        InitStatus := 0;
        CalcFileCRC := C;
        FILEMODE := $40;
        ASSIGN(F, FName);
        {$I-}
        RESET(F, 1);
        InitStatus := IORESULT;
        CASE InitStatus OF
            0 : ;                 {no error}
            $20 :                 {the file is in use, try later}
                BEGIN
                    InitStatus := 0;
                    EXIT;
                END;
            ELSE
                EXIT;
        END;
        REPEAT
            IF COP <> NIL THEN BEGIN
                IF NOT COP^.UpDate THEN BEGIN
                    InitStatus := ecUserAbort;
                    C := - 1;
                    BREAK;
                END;
            END;
            BLOCKREAD(F, Buff, ChunkSize, R);
            FOR I := 1 TO R DO
                C := UpDateCrc32(Buff[I], C);
        UNTIL R <> ChunkSize;
        CLOSE(F);
        {$I+}
        FILEMODE := $42;
        CalcFileCRC := C;
    END;

    {$ELSE}                       {virtual pascal}

    {------------}

    FUNCTION CalcFileCRC(FName : STRING{$IFNDEF DLL}; COP : CylonP{$ENDIF}) : LONGINT;
    CONST
        CHUNKSIZE      = $8000;
    VAR
        F              : FILE;
        I              : WORD;
        R         : WORD;
        C              : LONGINT;
        Buff           : ARRAY[1..CHUNKSIZE] OF BYTE;
        rc             : APIRet;
    BEGIN
        C := -1;
        if Fname <> '' then begin
        InitStatus := 0;
        CalcFileCRC := C;
        FILEMODE := $40;
        ASSIGN(F, FName);
        rc := DosError(ferr_DisableHardErr);
        {$I-}
        RESET(F, 1);
        rc := DosError(ferr_EnableHardErr);
        InitStatus := IORESULT;
        case initstatus of
        0:; {no error}
        $20: {the file is in use, try later}
            begin
                InitStatus := 0;
                exit;
            end;
        else
            EXIT;
        end;
        REPEAT
            {$IFNDEF DLL}
            IF COP <> NIL THEN BEGIN
                IF NOT COP^.Update THEN BEGIN
                    InitStatus := ecUserAbort;
                    C := - 1;
                    BREAK;
                END;
            END;
            {$ENDIF}
            BLOCKREAD(F, Buff, CHUNKSIZE, R);
            FOR I := 1 TO R DO
                C := UpdateCrc32(Buff[I], C);
        UNTIL R <> CHUNKSIZE;
        CLOSE(F);
        {$I+}
        FILEMODE := $42;
        end;
        CalcFileCRC := NOT C;
    END;
    {$ENDIF}

    {------------}
TYPE
    PBigBuff       = ^TBigBuff;
    {$IFDEF VirtualPascal}
    TBigBuff       = ARRAY[$0..MAXLONGINT] OF BYTE;
    {$ELSE}
    TBigBuff       = ARRAY[$0..$FFFE] OF BYTE;
    {$ENDIF}

    FUNCTION CalcBlockCRC(Block : POINTER; BlockSize : WORD; CONST CRC : LONGINT) : LONGINT;
    VAR
        C,
        I              : LONGINT;
    BEGIN
        C := CRC;
        FOR I := 0 TO BlockSize - 1 DO
            C := UpDateCrc32(PBigBuff(Block)^[I], C);
        CalcBlockCRC := C;
    END;

    {------------}

    FUNCTION RandChar : STRING;
    BEGIN
        RandChar := CHAR(ORD('A') + RANDOM(26));
    END;

    {---------------------}

    FUNCTION RandString(Len : BYTE) : STRING;
    VAR
        I              : BYTE;
        Strg           : STRING;
    BEGIN
        Strg := '';
        FOR I := 1 TO Len DO
            Strg := Strg + RandChar;
        RandString := Strg;
    END;

    {---------------------}

    FUNCTION MakeARandomPath : STRING;
    VAR
        Strg           : STRING;
        I,
        J              : BYTE;
    BEGIN
        {drive letter}
        Strg := RandChar + ':\';

        {some subdirs}
        FOR I := 1 TO RANDOM(8) DO
            Strg := AddBackSlash(Strg + RandString(RANDOM(10)));

        MakeARandomPath := Strg;
    END;

    {---------------------}

    FUNCTION MakeRandomName : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        Strg := RandString(RANDOM(15) + 1) + '.';

        MakeRandomName := Strg + RandString(RANDOM(3) + 1);
    END;

    {---------------------}

END.

    {---------------------}
    {---------------------}
