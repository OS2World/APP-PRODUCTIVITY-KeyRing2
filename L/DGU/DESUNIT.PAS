{
Source for doing DES encryption/decryption in Pascal.

This procedure uses 4 parameters :

InBuff  : 8 byte (64 bit) InBuff
OutBuff : 8 byte (64 bit) OutBuff from DES algorithm
Key     : 8 byte (64 bit) key for DES algorithm
Encrypt : True to encrypt, False to decrypt

The procedure uses typeless parameters so you can use variables of
any type for InBuff, OutBuff and the Key, as long as they are 8 bytes
long (or more).


Delft, 18 april 1995
s795238@dutiws.twi.tudelft.nl

modified by K.G. McCoy 21 Aug 1999 to allow block en/decryption
modified by K.G. McCoy 2  Feb 2000 to allow CBC encryption/decryption

Portions Copyright 2000, IDK, Inc.
All Rights Reserved
}
UNIT Desunit;

INTERFACE
USES
    VARDEC;

TYPE
    TDESCryptMode  = (EENCRYPT, EDECRYPT);

    {encrypt/decrypt a single 8 byte block}
PROCEDURE DES(VAR InBuff; VAR OutBuff; Mode : TDESCryptMode);

    {encrypt an entire buffer, using a string key of any length}
PROCEDURE DESEncryptBuff(VAR Buff; BuffSize : LONGINT);
    {decrypt an entire buffer, using a string key of any length}
PROCEDURE DESDecryptBuff(VAR Buff; BuffSize : LONGINT);

PROCEDURE DESEncryptString(VAR Buff; BuffSize : LONGINT);
PROCEDURE DESDecryptString(VAR Buff);

PROCEDURE InitDES(Password : STRING; Hdr : TCryptHead);
PROCEDURE DESDeinit;

    {------------}

IMPLEMENTATION
USES
    DGMath,
    STRCRC;

TYPE
    TBigArray      = ARRAY[1..$FFFF] OF COMP;
    TLongArray     = ARRAY[1..$3FFF] OF LONGINT;

CONST
    IP             : ARRAY[1..64] OF BYTE = (58, 50, 42, 34, 26, 18, 10, 2,
                                             60, 52, 44, 36, 28, 20, 12, 4,
                                             62, 54, 46, 38, 30, 22, 14, 6,
                                             64, 56, 48, 40, 32, 24, 16, 8,
                                             57, 49, 41, 33, 25, 17, 9, 1,
                                             59, 51, 43, 35, 27, 19, 11, 3,
                                             61, 53, 45, 37, 29, 21, 13, 5,
                                             63, 55, 47, 39, 31, 23, 15, 7);
    InvIP          : ARRAY[1..64] OF BYTE = (40, 8, 48, 16, 56, 24, 64, 32,
                                             39, 7, 47, 15, 55, 23, 63, 31,
                                             38, 6, 46, 14, 54, 22, 62, 30,
                                             37, 5, 45, 13, 53, 21, 61, 29,
                                             36, 4, 44, 12, 52, 20, 60, 28,
                                             35, 3, 43, 11, 51, 19, 59, 27,
                                             34, 2, 42, 10, 50, 18, 58, 26,
                                             33, 1, 41, 9, 49, 17, 57, 25);
    E              : ARRAY[1..48] OF BYTE = (32, 1, 2, 3, 4, 5,
                                             4, 5, 6, 7, 8, 9,
                                             8, 9, 10, 11, 12, 13,
                                             12, 13, 14, 15, 16, 17,
                                             16, 17, 18, 19, 20, 21,
                                             20, 21, 22, 23, 24, 25,
                                             24, 25, 26, 27, 28, 29,
                                             28, 29, 30, 31, 32, 1);
    P              : ARRAY[1..32] OF BYTE = (16, 7, 20, 21,
                                             29, 12, 28, 17,
                                             1, 15, 23, 26,
                                             5, 18, 31, 10,
                                             2, 8, 24, 14,
                                             32, 27, 3, 9,
                                             19, 13, 30, 6,
                                             22, 11, 4, 25);
    SBoxes         : ARRAY[1..8, 0..3, 0..15] OF BYTE =
    (((14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7),
      (0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8),
      (4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0),
      (15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13)),

     ((15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10),
      (3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5),
      (0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15),
      (13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9)),

     ((10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8),
      (13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1),
      (13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7),
      (1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12)),

     ((7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15),
      (13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9),
      (10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4),
      (3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14)),

     ((2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9),
      (14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6),
      (4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14),
      (11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3)),

     ((12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11),
      (10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8),
      (9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6),
      (4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13)),

     ((4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1),
      (13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6),
      (1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2),
      (6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12)),

     ((13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7),
      (1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2),
      (7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8),
      (2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11)));

    PC_1           : ARRAY[1..56] OF BYTE = (57, 49, 41, 33, 25, 17, 9,
                                             1, 58, 50, 42, 34, 26, 18,
                                             10, 2, 59, 51, 43, 35, 27,
                                             19, 11, 3, 60, 52, 44, 36,
                                             63, 55, 47, 39, 31, 23, 15,
                                             7, 62, 54, 46, 38, 30, 22,
                                             14, 6, 61, 53, 45, 37, 29,
                                             21, 13, 5, 28, 20, 12, 4);

    PC_2           : ARRAY[1..48] OF BYTE = (14, 17, 11, 24, 1, 5,
                                             3, 28, 15, 6, 21, 10,
                                             23, 19, 12, 4, 26, 8,
                                             16, 7, 27, 20, 13, 2,
                                             41, 52, 31, 37, 47, 55,
                                             30, 40, 51, 45, 33, 48,
                                             44, 49, 39, 56, 34, 53,
                                             46, 42, 50, 36, 29, 32);

    ShiftTable     : ARRAY[1..16] OF BYTE = (1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1);

TYPE
    TBuf2L         = RECORD
                         LBuff,
                         RBuff          : LONGINT;
                     END;

VAR
    IV             : TBuf2L;
    MyCryptStyle   : TCryptStyle;
    Key64          : COMP;

    {-----------}

    PROCEDURE DES(VAR InBuff; VAR OutBuff; Mode : TDESCryptMode);
    VAR
        InputValue     : ARRAY[1..64] OF BYTE;
        OutputValue    : ARRAY[1..64] OF BYTE;
        RoundKeys      : ARRAY[1..16, 1..48] OF BYTE;
        L,
        R,
        FunctionResult : ARRAY[1..32] OF BYTE;
        C,
        D              : ARRAY[1..28] OF BYTE;

        {-----------}

        FUNCTION GetBit(VAR Data; Index : BYTE) : BYTE;
        VAR
            Bits           : ARRAY[0..7] OF BYTE ABSOLUTE Data;
        BEGIN
            DEC(Index);
            IF Bits[Index DIV 8] AND (128 SHR (Index MOD 8)) > 0 THEN
                GetBit := 1
            ELSE
                GetBit := 0;
        END;                      {GetBit}

        {-----------}

        PROCEDURE SetBit(VAR Data; Index, Value : BYTE);

        VAR
            Bits           : ARRAY[0..7] OF BYTE ABSOLUTE Data;
            Bit            : BYTE;
        BEGIN
            DEC(Index);
            Bit := 128 SHR (Index MOD 8);
            CASE Value OF
                0 :
                    Bits[Index DIV 8] := Bits[Index DIV 8] AND (NOT Bit);
                1 :
                    Bits[Index DIV 8] := Bits[Index DIV 8] OR Bit;
            END;
        END;                      {SetBit}

        {-----------}

        PROCEDURE F(VAR FR, FK, OutBuff);
        VAR
            R              : ARRAY[1..48] OF BYTE ABSOLUTE FR;
            K              : ARRAY[1..48] OF BYTE ABSOLUTE FK;
            Temp1          : ARRAY[1..48] OF BYTE;
            Temp2          : ARRAY[1..32] OF BYTE;
            N,
            H,
            I,
            J,
            Row,
            Column         : INTEGER;
            TotalOut       : ARRAY[1..32] OF BYTE ABSOLUTE OutBuff;
        BEGIN
            FOR N := 1 TO 48 DO
                Temp1[N] := R[E[N]] XOR K[N];
            FOR N := 1 TO 8 DO BEGIN
                I := (N - 1) * 6;
                J := (N - 1) * 4;
                Row := Temp1[I + 1] * 2 + Temp1[I + 6];
                Column := Temp1[I + 2] * 8 + Temp1[I + 3] * 4 + Temp1[I + 4] * 2 + Temp1[I + 5];
                FOR H := 1 TO 4 DO BEGIN
                    CASE H OF
                        1 :
                            Temp2[J + H] := (SBoxes[N, Row, Column] AND 8) DIV 8;
                        2 :
                            Temp2[J + H] := (SBoxes[N, Row, Column] AND 4) DIV 4;
                        3 :
                            Temp2[J + H] := (SBoxes[N, Row, Column] AND 2) DIV 2;
                        4 :
                            Temp2[J + H] := (SBoxes[N, Row, Column] AND 1);
                    END;
                END;
            END;
            FOR N := 1 TO 32 DO
                TotalOut[N] := Temp2[P[N]];
        END;                      {F}

        {-----------}

        PROCEDURE Shift(VAR SubKeyPart);
        VAR
            SKP            : ARRAY[1..28] OF BYTE ABSOLUTE SubKeyPart;
            N,
            B              : BYTE;
        BEGIN
            B := SKP[1];
            FOR N := 1 TO 27 DO
                SKP[N] := SKP[N + 1];
            SKP[28] := B;
        END;                      {Shift}

        {-----------}

        PROCEDURE SubKey(ROUND : BYTE; VAR SubKey);
        VAR
            SK             : ARRAY[1..48] OF BYTE ABSOLUTE SubKey;
            N,
            B              : BYTE;
        BEGIN
            FOR N := 1 TO ShiftTable[ROUND] DO BEGIN
                Shift(C);
                Shift(D);
            END;
            FOR N := 1 TO 48 DO BEGIN
                B := PC_2[N];
                IF B <= 28 THEN
                    SK[N] := C[B]
                ELSE
                    SK[N] := D[B - 28];
            END;
        END;                      {SubKey}
    VAR
        N,
        I,
        B,
        ROUND          : BYTE;
        Outputje       : ARRAY[1..64] OF BYTE;
        K              : ARRAY[1..48] OF BYTE;
        FI             : TEXT;
    BEGIN
        FOR N := 1 TO 64 DO
            InputValue[N] := GetBit(InBuff, N);
        FOR N := 1 TO 28 DO BEGIN
            C[N] := GetBit(Key64, PC_1[N]);
            D[N] := GetBit(Key64, PC_1[N + 28]);
        END;
        FOR N := 1 TO 16 DO
            SubKey(N, RoundKeys[N]);
        FOR N := 1 TO 64 DO
            IF N <= 32 THEN
                L[N] := InputValue[IP[N]]
            ELSE
                R[N - 32] := InputValue[IP[N]];
        FOR ROUND := 1 TO 16 DO BEGIN
            IF Mode = EENCRYPT THEN
                F(R, RoundKeys[ROUND], FunctionResult)
            ELSE
                F(R, RoundKeys[17 - ROUND], FunctionResult);
            FOR N := 1 TO 32 DO
                FunctionResult[N] := FunctionResult[N] XOR L[N];
            L := R;
            R := FunctionResult;
        END;
        FOR N := 1 TO 64 DO BEGIN
            B := InvIP[N];
            IF B <= 32 THEN
                OutputValue[N] := R[B]
            ELSE
                OutputValue[N] := L[B - 32];
        END;
        FOR N := 1 TO 64 DO
            SetBit(OutBuff, N, OutputValue[N]);
    END;

    {-------------}

    PROCEDURE DESEncryptBuff(VAR Buff; BuffSize : LONGINT);
    VAR
        I              : LONGINT;
        TBuff          : TBigArray ABSOLUTE Buff;
    BEGIN
        I := 1;
        WHILE I <= (BuffSize DIV 8) DO BEGIN
            DES(TBuff[I], TBuff[I], EENCRYPT);
            INC(I);
        END;
    END;

    {-------------}

    PROCEDURE DESDecryptBuff(VAR Buff; BuffSize : LONGINT);
    VAR
        I              : LONGINT;
        TBuff          : TBigArray ABSOLUTE Buff;
    BEGIN
        I := 1;
        WHILE I <= (BuffSize DIV 8) DO BEGIN
            DES(TBuff[I], TBuff[I], EDECRYPT);
            INC(I);
        END;
    END;

    {------------}

    PROCEDURE DESEncryptString(VAR Buff; BuffSize : LONGINT);
    VAR
        I,
        D              : LONGINT;
        TBuff          : TBigArray ABSOLUTE Buff;
        CBCBuff        : TLongArray ABSOLUTE Buff;
        Strg           : STRING ABSOLUTE Buff;
    BEGIN
        I := 1;
        D := 1;
        IF BuffSize >= 4 THEN BEGIN
            WHILE I <= (BuffSize DIV 8) DO BEGIN
                {$IFDEF USECBC}
                IF MyCryptStyle = EDESCBC THEN BEGIN
                    CBCBuff[d] := CBCBuff[d] XOR IV.LBuff;
                    CBCBuff[d + 1] := CBCBuff[d + 1] XOR IV.RBuff;
                END;
                {$ENDIF}
                DES(TBuff[I], TBuff[I], EENCRYPT);
                {$IFDEF USECBC}
                IF MyCryptStyle = EDESCBC THEN BEGIN
                    IV.LBuff := CBCBuff[d];
                    IV.RBuff := CBCBuff[d + 1];
                END;
                {$ENDIF}
                INC(I);
                INC(D, 2);
            END;
            EXIT;
        END
        ELSE BEGIN
            {$IFDEF USECBC}
            IF MyCryptStyle = EDESCBC THEN BEGIN
                CBCBuff[d] := CBCBuff[d] XOR IV.LBuff;
                CBCBuff[d + 1] := CBCBuff[d + 1] XOR IV.RBuff;
            END;
            {$ENDIF}
            DES(TBuff[I], TBuff[I], EENCRYPT);
            {$IFDEF USECBC}
            IF MyCryptStyle = EDESCBC THEN BEGIN
                IV.LBuff := CBCBuff[d];
                IV.RBuff := CBCBuff[d + 1];
            END;
            {$ENDIF}
        END;
    END;

    {------------}

    PROCEDURE DESDecryptString(VAR Buff);
    VAR
        D,
        I              : LONGINT;
        TBuff          : TBigArray ABSOLUTE Buff;
        CBCBuff        : TLongArray ABSOLUTE Buff;
        RStrg          : STRING ABSOLUTE Buff;
        BuffSize       : BYTE ABSOLUTE Buff;
        XBuf           : TBuf2L;
    BEGIN
        I := 1;
        D := 1;
        {$IFDEF USECBC}
        XBuf.LBuff := CBCBuff[d];
        XBuf.RBuff := CBCBuff[d + 1];
        {$ENDIF}
        DES(TBuff[I], TBuff[I], EDECRYPT);
        {$IFDEF USECBC}
        IF MyCryptStyle = EDESCBC THEN BEGIN
            CBCBuff[d] := CBCBuff[d] XOR IV.LBuff;
            CBCBuff[d + 1] := CBCBuff[d + 1] XOR IV.RBuff;

            IV := XBuf;
        END;
        {$ENDIF}
        INC(D, 2);
        INC(I);

        INC(BuffSize);            {account for length byte}

        IF BuffSize >= 4 THEN BEGIN
            WHILE I <= (BuffSize DIV 8) DO BEGIN

                {$IFDEF USECBC}
                XBuf.LBuff := CBCBuff[d];
                XBuf.RBuff := CBCBuff[d + 1];
                {$ENDIF}

                DES(TBuff[I], TBuff[I], EDECRYPT);

                {$IFDEF USECBC}
                IF MyCryptStyle = EDESCBC THEN BEGIN
                    CBCBuff[d] := CBCBuff[d] XOR IV.LBuff;
                    CBCBuff[d + 1] := CBCBuff[d + 1] XOR IV.RBuff;

                    IV := XBuf;
                END;
                {$ENDIF}

                INC(I);
                INC(D, 2);
            END;
        END;
        DEC(BYTE(RStrg[0]));
    END;

    {------------}

    PROCEDURE InitDES(Password : STRING; Hdr : TCryptHead);
    BEGIN
        Key64 := CalcUpcase64BitCRC(Password);

        {$IFDEF USECBC}
        MyCryptStyle := Hdr.CryptStyle; {now set up for data encryption}

        IF MyCryptStyle = EDES THEN
            FILLCHAR(IV, SIZEOF(IV), #0)
        ELSE BEGIN
            IV.LBuff := Hdr.Seed.D;
            IV.RBuff := Hdr.Seed.T;
        END;
        {$ENDIF}
    END;

    {------------}

    PROCEDURE DESDeinit;
    BEGIN
        FILLCHAR(IV, SIZEOF(IV), #0);
        MyCryptStyle := LOW(TCryptStyle);
        Key64 := 0;
    END;

    {------------}

END.

    {------------}
    {------------}

