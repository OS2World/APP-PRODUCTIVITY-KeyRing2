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
* This is a generic, text string oriented file encryption object that uses
* two keys (could be public/private) to encrypt the strings.  It is currently
* set up to create encryption keys based on the filename and the recipient
* name of a message.  This object can detect wether an expected encryption
* header is present, and will switch to non encrypted mode on file read if
* the header is missing.  The intent of this object is to create difficult
* to decrypt message files in an E-Mail environment, that is both simple and
* fast to decode at the receiving end.
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$I NDEFINE.INC}
UNIT SECRYPT;

INTERFACE
USES
    Dos,
    {$IFDEF NEN3MAIL}
    KEDIT,
    {$ELSE}
    MAEDIT,
    {$ENDIF}
    OpRoot,
    UDIALOG;

CONST
    MAXKEY         = MailBufSize;

TYPE
    CryptModeT     = (EBUFFER, EFile);
    CryptLevelT    = (ENONE, ESECRET, ETOPSECRET);
    CrypterPtr     = ^Crypter;

    Crypter        = OBJECT(Root)
                         CONSTRUCTOR SendInit(OutName, ToName : STRING);
                         CONSTRUCTOR RcvInit(FName, MyName : STRING);
                             {$IFDEF BUFFEREDCRYPT}
                         CONSTRUCTOR BufSendInit(CryptLevel     : CryptLevelT;
                                                 Buf            : IoBuffPtr;
                                                 VAR PW         : STRING);
                         CONSTRUCTOR BufRcvInit(VAR Buf : IoBuffPtr; From, Subject : PCHAR);
                         CONSTRUCTOR FileBufRcvInit(FName          : PathStr;
                                                    VAR Buf        : IoBuffPtr;
                                                    BufAvail       : WORD;
                                                    From,
                                                    Subject        : PCHAR);

                         CONSTRUCTOR FileBufSendInit(CryptLevel     : CryptLevelT;
                                                     VAR F          : FILE;
                                                     VAR Buf        : IoBuffPtr;
                                                     VAR PW         : STRING;
                                                     COP            : CylonP);
                         FUNCTION BufSend(VAR F : FILE; COP : CylonP) : BOOLEAN;
                             {$ENDIF}
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetLine(VAR L : STRING) : BOOLEAN;
                         FUNCTION AutoCrypt(InName : STRING) : BOOLEAN;
                         FUNCTION PutLine(L : STRING) : BOOLEAN;
                         FUNCTION CryptStat : BOOLEAN;
                         FUNCTION FSeek(L : LONGINT) : BOOLEAN;

                     PRIVATE

                         CurName        : STRING;
                         BF             : FILE;
                         TF             : TEXT;
                         IsCrypted      : BOOLEAN;
                         CryptMode      : CryptModeT;
                         BuffCursor,
                         HeaderEnd,
                         EOB,
                         Rotor          : WORD;
                         PublicKey      : LONGINT;
                         Key            : ARRAY[0..MAXKEY] OF BYTE;
                         CryptBuff      : IoBuffPtr;

                         PROCEDURE KeyInit(Key1, Key2 : STRING);
                         PROCEDURE IncrementRotor;

                         FUNCTION MakeRandLong : LONGINT;

                             {$IFDEF DEBUG}
                         FUNCTION ChiSquare:REAL;
                         {$ENDIF}
                     END;

    (****************************************************************************)

IMPLEMENTATION

USES
    ApMisc,
    Crc,
    {$IFDEF NEN3MAIL}
    KCABEDIT,
    {$ELSE}
    MACABEDT,
    {$ENDIF}
    UTIAM,
    OpConst,
    OpCrt,
    OpDos,
    OpInline,
    OpCmd,
    OpString,
    QInput,
    Strings,
    UColors,
    UERROR,
    ULIB;

    (****************************************************************************)

CONST
    {this stuff is just to make a red-herring, interesting looking header}
    {for would-be hackers                                                }
    CryptID        = 'NEN-AMGINE'; {enigma spelled backwards}
    CryptVer       = 4927422;     {my phone number}
    {                              1234567890123456789012345678901234567890}
    BuffCryptID    : STRING[36] = 'NewsMaker Encrypted Message - Date: ';

TYPE
    CryptHead      = RECORD
                         ID             : STRING[10];
                         Vers,
                         PubKey         : LONGINT;
                     END;


    CryptMode      = (READ, WRITE, Error);

    (****************************************************************************)

    {bump to next avail key or wrap around}
    PROCEDURE Crypter.IncrementRotor;
    BEGIN
        INC(Rotor);
        Rotor := Rotor MOD MAXKEY;
    END;

    (****************************************************************************)
    {$IFDEF DEBUG}
TYPE
    TestArray = ARRAY[0..MAXKEY] OF BYTE;
    TestArrayPtr = ^TestArray;

    {- This method checks the randomness of the key sequence}
    {- The return value should be within +-2*SQRT(255) OF 255}
    FUNCTION Crypter.ChiSquare:REAL;
    VAR
        T : REAL;
        I : WORD;
        TAP : TestArrayPtr;
    BEGIN
        NEW(TAP);
        FILLCHAR(TAP^, SIZEOF(TestArray), 0);
        FOR I := 0 TO MAXKEY DO
            INC(TAP^[Key[I]]);

        T := 0.0;
        FOR I:=0 TO MAXKEY-1 DO
            T := T+TAP^[I]*TAP^[I];

        ChiSquare := ((255.0 * T/MAXKEY)-MAXKEY);
        DISPOSE(TAP);
    END;
    {$ENDIF}

    (****************************************************************************)

    PROCEDURE Crypter.KeyInit(Key1, Key2 : STRING);
    VAR
        I,
        J,
        K              : WORD;
        Seed           : BYTE;
    BEGIN

        Seed := 0;
        FILLCHAR(Key, MAXKEY, 0);
        Key1 := StUpCase(Trim(Key1));
        Key2 := StUpCase(Trim(Key2));
        Rotor := 0;

        {Create a seed for the random number generator based on the filename}
        {or embedded public key, and the addressee's name}
        J := 0;
        IF LENGTH(Key1) > 0 THEN BEGIN
            {public key string supplied so create CRC checksum}
            FOR I := 1 TO LENGTH(Key1) DO
                CalcCRC(ORD(Key1[I]), J);
            PublicKey := J;
        END
        ELSE                      {no key string - so must be a decrypt operation - use public key}
            {value from file header}
            J := PublicKey;

        {now create private key from private key value from key2 string}
        FOR I := 1 TO LENGTH(Key2) DO
            CalcCRC(ORD(Key2[I]), J);

        RANDSEED := J;

        {Generate the random number sequence}
        FOR I := 0 TO MAXKEY DO
            Key[I] := RANDOM(255);

        {$IFDEF DEBUGCHISQ}
        WRITELN(ChiSquare);
        {$ENDIF}
    END;

    (****************************************************************************)

    FUNCTION Crypter.CryptStat : BOOLEAN;
    BEGIN
        CryptStat := IsCrypted;
    END;

    (****************************************************************************)

    CONSTRUCTOR Crypter.SendInit(OutName, ToName : STRING);
    VAR
        Result         : WORD;
        Head           : CryptHead;
        Strg           : STRING;
        FoundTO        : BOOLEAN;
    BEGIN
        InitStatus := 0;
    {
        IF NOT Root.Init THEN
            FAIL;
        }
        CryptMode := EFile;
        CurName := OutName;
        CryptBuff := NIL;
        KeyInit(JustName(OutName), ToName);

        FILLCHAR(Head, SIZEOF(Head), 0);
        Head.ID := CryptID;
        Head.Vers := CryptVer;
        Head.PubKey := PublicKey;

        ASSIGN(BF, ForceExtension(OutName, 'MSG'));
        Result := IORESULT;
        REWRITE(BF, 1);

        Result := IORESULT;


        BLOCKWRITE(BF, Head, SIZEOF(Head), Result);

        IF Result <> SIZEOF(Head) THEN BEGIN
            CLOSE(BF);
            FAIL;
        END;

        IsCrypted := TRUE;

    END;

    (****************************************************************************)

    {$IFDEF BUFFEREDCRYPT}
    {On entry, Buf points to buffer full of SMF header and (possibly) Hex }
    {crypted text.  On exit, Buf points to buffer full of clear text, if  }
    {the password was correct (Top Secret)                                }

    CONSTRUCTOR Crypter.BufRcvInit(VAR Buf : IoBuffPtr; From, Subject : PCHAR);
    VAR
        B,
        I,
        J,
        ClearTxtCursor,
        EndOfBuff,
        StartOfBuff,
        PrivPos,
        Result         : WORD;
        L,
        PW,
        ToName         : STRING;
        Flg,
        PrivateKey     : LONGINT;
        LenByte        : BYTE;
        Colors         : ColorSet;
    BEGIN
        InitStatus := 0;
        {
        IF NOT Root.Init THEN
            FAIL;
        }
        CryptBuff := NIL;
        CryptMode := EBUFFER;

        {search for the encryption preamble, if any}
        StartOfBuff := Search(Buf^, LENGTH(BuffCryptID) + 10, BuffCryptID[1], LENGTH(BuffCryptID));
        IF StartOfBuff = $FFFF THEN BEGIN
            IsCrypted := FALSE;
            EXIT;
        END;
        INC(StartOfBuff);

        ToName := ': ';

        {find LF after public key (For: Name) CR/LF}
        PrivPos := Search(Buf^[StartOfBuff], $FF,
                          ToName[1], LENGTH(ToName));
        IF PrivPos = $FFFF THEN BEGIN
            InitStatus := epWarning + ecBadFormat;
            FAIL;
        END;

        INC(PrivPos, StartOfBuff);
        {Privpos now points to the flg location in the encrypted buffer}

        MOVE(Buf^[PrivPos + 2], ToName[1], $F0);
        ToName[0] := CHAR($F0);
        I := POS(#10, ToName);
        IF I = 0 THEN BEGIN
            InitStatus := epWarning + ecBadFormat;
            FAIL;
        END;

        ToName[0] := CHR(I);
        I := PrivPos + LENGTH(ToName) + 2;
        L[0] := CHAR((SIZEOF(LONGINT) * 2) + 1);
        L[1] := '$';
        MOVE(Buf^[I + 6], L[2], 2);
        MOVE(Buf^[I + 4], L[4], 2);
        MOVE(Buf^[I + 2], L[6], 2);
        MOVE(Buf^[I], L[8], 2);

        IF NOT Str2Long(L, Flg) THEN BEGIN
            InitStatus := epWarning + ecBadFormat;
            FAIL;
        END;

        I := PrivPos + LENGTH(ToName) + (SIZEOF(LONGINT) * 2) + 2;

        IF NOT ODD(Flg) THEN BEGIN {is topsecret}
            L[0] := CHAR((SIZEOF(LONGINT) * 2) + 1);
            L[1] := '$';
            MOVE(Buf^[I + 6], L[2], 2);
            MOVE(Buf^[I + 4], L[4], 2);
            MOVE(Buf^[I + 2], L[6], 2);
            MOVE(Buf^[I], L[8], 2);
            INC(I, SIZEOF(LONGINT) * 2);
            IF NOT Str2Long(L, Flg) THEN BEGIN
                InitStatus := epWarning + ecBadFormat;
                FAIL;
            END;

            Flg := Flg XOR CryptVer;


            GetCScheme(Cyan_Scheme, Colors);
            PW := '';

            CASE EditPassWord(PW, Colors, EREAD, From, Subject) OF
                ccDone,
                ccExitAtBot : ;
                ccError : FAIL;
                ccQuit :
                    BEGIN
                        InitStatus := epWarning;
                        FAIL;
                    END;
            END;                  {case}

            PrivateKey := 0;

            FOR B := 1 TO LENGTH(PW) DO
                PrivateKey := UpdateCRC32(BYTE(PW[B]), PrivateKey);

            IF PrivateKey <> Flg THEN BEGIN
                InitStatus := epWarning;
                FAIL;
            END;
        END
        ELSE BEGIN
            PW := HexL(PrivateKey);
            L[0] := CHAR((SIZEOF(LONGINT) * 2) + 1);
            L[1] := '$';
            MOVE(Buf^[I + 6], L[2], 2);
            MOVE(Buf^[I + 4], L[4], 2);
            MOVE(Buf^[I + 2], L[6], 2);
            MOVE(Buf^[I], L[8], 2);
            INC(I, SIZEOF(LONGINT) * 2);
            IF NOT Str2Long(L, PrivateKey) THEN BEGIN
                InitStatus := epWarning + ecBadFormat;
                FAIL;
            END;
        END;

        KeyInit(ToName, HexL(PrivateKey));

        J := 1;
        L[0] := #3;
        L[1] := '$';              {so we dont have to concatenate the dollar sign in the loop}
        REPEAT
            MOVE(Buf^[I], L[2], 2);
            INC(I, 2);
            CASE L[2] OF          {look at char to right of $}
                ^M : ;
                ^Z :
                    BEGIN
                        Buf^[J] := ^Z;
                        EXIT;
                    END;
                ELSE BEGIN
                    {L = '$FF' or somesuch}
                    Str2Word(L, B);
                    {overwrite buffer with decrypted text}
                    Buf^[J] := CHR(B XOR Key[Rotor]);
                    IncrementRotor;
                    INC(J);
                END;
            END;                  {case}
        UNTIL I >= MailBufSize;

    END;

    (****************************************************************************)

    CONSTRUCTOR Crypter.FileBufRcvInit(FName          : PathStr;
                                       VAR Buf        : IoBuffPtr;
                                       BufAvail       : WORD;
                                       From,
                                       Subject        : PCHAR);
    VAR
        L,
        PW,
        ToName,
        CryptLine      : STRING;
        B,
        I,
        J,
        StartOfBuff,
        StartOfBody,
        PrivPos,
        Result         : WORD;
        Flg,
        PrivateKey     : LONGINT;
        Colors         : ColorSet;
    BEGIN
        CryptBuff := NIL;
        CryptMode := EBUFFER;
        L := #10#10;
        {search for the body marker, if any}
        StartOfBody := Search(Buf^, $FFFF, L[1], 2);
        IF StartOfBody = $FFFF THEN BEGIN
            IsCrypted := FALSE;
            EXIT;
        END;

        {search in text body for crypt signature}
        StartOfBuff := Search(Buf^[StartOfBody + 2], LENGTH(BuffCryptID) + 10, BuffCryptID[1], LENGTH(BuffCryptID));
        IF StartOfBuff = $FFFF THEN BEGIN
            IsCrypted := FALSE;
            EXIT;
        END;
        StartOfBuff := StartOfBuff + StartOfBody + 2;
        ToName := ': ';

        {find LF after public key (For: Name) CR/LF}
        PrivPos := Search(Buf^[StartOfBuff], $FF,
                          ToName[1], LENGTH(ToName));
        IF PrivPos = $FFFF THEN BEGIN
            InitStatus := epWarning + ecBadFormat;
            FAIL;
        END;

        INC(PrivPos, StartOfBuff);
        {Privpos now points to the flg location in the encrypted buffer}

        MOVE(Buf^[PrivPos + 2], ToName[1], $F0);
        ToName[0] := CHAR($F0);   {contains date time}
        I := POS(#10, ToName);
        IF I = 0 THEN BEGIN
            InitStatus := epWarning + ecBadFormat;
            FAIL;
        END;

        ToName[0] := CHR(I);
        I := PrivPos + LENGTH(ToName) + 2;
        L[0] := CHAR((SIZEOF(LONGINT) * 2) + 1);
        L[1] := '$';
        MOVE(Buf^[I + 6], L[2], 2);
        MOVE(Buf^[I + 4], L[4], 2);
        MOVE(Buf^[I + 2], L[6], 2);
        MOVE(Buf^[I], L[8], 2);

        IF NOT Str2Long(L, Flg) THEN BEGIN
            InitStatus := epWarning + ecBadFormat;
            FAIL;
        END;

        I := PrivPos + LENGTH(ToName) + (SIZEOF(LONGINT) * 2) + 2;

        IF NOT ODD(Flg) THEN BEGIN {is topsecret}
            L[0] := CHAR((SIZEOF(LONGINT) * 2) + 1);
            L[1] := '$';
            MOVE(Buf^[I + 6], L[2], 2);
            MOVE(Buf^[I + 4], L[4], 2);
            MOVE(Buf^[I + 2], L[6], 2);
            MOVE(Buf^[I], L[8], 2);
            INC(I, SIZEOF(LONGINT) * 2);
            IF NOT Str2Long(L, Flg) THEN BEGIN
                InitStatus := epWarning + ecBadFormat;
                FAIL;
            END;

            Flg := Flg XOR CryptVer;


            GetCScheme(Cyan_Scheme, Colors);
            PW := '';

            CASE EditPassWord(PW, Colors, EREAD, From, Subject) OF
                ccDone,
                ccExitAtBot : ;
                ccError : FAIL;
                ccQuit :
                    BEGIN
                        InitStatus := epWarning;
                        FAIL;
                    END;
            END;                  {case}

            PrivateKey := 0;

            FOR B := 1 TO LENGTH(PW) DO
                PrivateKey := UpdateCRC32(BYTE(PW[B]), PrivateKey);

            IF PrivateKey <> Flg THEN BEGIN
                InitStatus := epWarning;
                FAIL;
            END;
        END
        ELSE BEGIN
            PW := HexL(PrivateKey);
            L[0] := CHAR((SIZEOF(LONGINT) * 2) + 1);
            L[1] := '$';
            MOVE(Buf^[I + 6], L[2], 2);
            MOVE(Buf^[I + 4], L[4], 2);
            MOVE(Buf^[I + 2], L[6], 2);
            MOVE(Buf^[I], L[8], 2);
            INC(I, SIZEOF(LONGINT) * 2);
            IF NOT Str2Long(L, PrivateKey) THEN BEGIN
                InitStatus := epWarning + ecBadFormat;
                FAIL;
            END;
        END;

        KeyInit(ToName, HexL(PrivateKey));
        ASSIGN(TF, FName);
        FILEMODE := 0;
        RESET(TF);
        TextSeek(TF, I - 1);
        J := StartOfBuff;
        L[0] := #3;
        L[1] := '$';              {so we dont have to concatenate the dollar sign in the loop}
        WHILE NOT EOF(TF) DO BEGIN
            READLN(TF, CryptLine);
            FOR I := 1 TO LENGTH(CryptLine) DO BEGIN
                MoveFast(CryptLine[I], L[2], 2);
                CASE L[2] OF      {look at char to right of $}
                    ^M : ;
                    ^Z :
                        BEGIN
                            Buf^[J] := ^Z;
                            EXIT;
                        END;
                    ELSE BEGIN
                        {L = '$FF' or somesuch}
                        Str2Word(L, B);
                        {overwrite buffer with decrypted text}
                        Buf^[J] := CHR(B XOR Key[Rotor]);
                        IncrementRotor;
                        INC(J);
                    END;
                END;              {case}
                INC(I);           {so we can step by 2}
            END;
        END;
        CLOSE(TF);
        {UNTIL I >= MailBufSize;}

    END;
    {$ENDIF}

    (****************************************************************************)

    FUNCTION Crypter.MakeRandLong : LONGINT;
    TYPE
        LongRec        = RECORD
                             H,
                             L              : WORD;
                         END;
    VAR
        L              : LONGINT;
        HL             : LongRec ABSOLUTE L;
    BEGIN
        HL.L := RANDOM($FFFF);
        HL.H := RANDOM($FFFF);
        MakeRandLong := L;
        L := 0;
    END;

    (****************************************************************************)

    {$IFDEF BUFFEREDCRYPT}
    CONSTRUCTOR Crypter.BufSendInit(CryptLevel     : CryptLevelT;
                                    Buf            : IoBuffPtr;
                                    VAR PW         : STRING);
    VAR
        EOL,
        I,
        J,
        K,
        ClearCursor,
        CryptCursor    : WORD;
        Strg,
        L              : STRING;
        CrLf           : STRING[2];
        Flg,
        Pk             : LONGINT;
        Colors         : ColorSet;
    BEGIN
        InitStatus := 0;
        {
        IF NOT Root.Init THEN
            FAIL;
        }
        CryptMode := EBUFFER;
        IF NOT GetMemCheck(CryptBuff, MailBufSize) THEN BEGIN
            InitStatus := ecOutOfMemory;
            FAIL;
        END;
        FILLCHAR(CryptBuff^, MailBufSize, #0);
        ClearCursor := 1;
        CryptCursor := 1;
        L := ^Z;
        EOB := Search(Buf^, MailBufSize, L[1], 1);
        IF EOB = $FFFF THEN BEGIN
            InitStatus := epWarning + ecBadFormat;
            FAIL;
        END;

        INC(EOB);

        {put the preamble into the buffer}
        MOVE(BuffCryptID[1], CryptBuff^, LENGTH(BuffCryptID));

        {create the obvious public key}
        L := TimeDateNow + ^M^J;
        INC(CryptCursor, LENGTH(BuffCryptID));
        {concatenate the public key with the existing buffer contents}
        MOVE(L[1], CryptBuff^[CryptCursor], LENGTH(L));
        INC(CryptCursor, LENGTH(L));
        HeaderEnd := CryptCursor;
        RANDOMIZE;
        Flg := MakeRandLong;

        {create a private key}
        IF CryptLevel = ETOPSECRET THEN BEGIN
            {$R-}
            IF ODD(Flg) THEN
                INC(Flg);         {topsecret is Even}
            IF PW = '' THEN BEGIN
                GetCScheme(Cyan_Scheme, Colors);
                CASE EditPassWord(PW, Colors, EWRITE, NIL, NIL) OF
                    ccDone,
                    ccExitAtBot : ;
                    ccError : FAIL;
                    ccQuit :
                        BEGIN
                            InitStatus := ecUserAbort;
                            FreeMemCheck(CryptBuff, MailBufSize);
                            CryptBuff := NIL;
                            FAIL;
                        END;
                END;              {case}
            END;
            Pk := 0;
            FOR I := 1 TO LENGTH(PW) DO
                Pk := UpdateCRC32(BYTE(PW[I]), Pk);
        END
        ELSE BEGIN
            IF NOT ODD(Flg) THEN
                INC(Flg);
            Pk := MakeRandLong;
        END;
        {init the encryption key with the public and private key values}
        KeyInit(L, HexL(Pk));

        MOVE(Flg, CryptBuff^[CryptCursor], SIZEOF(Flg));
        INC(CryptCursor, SIZEOF(Flg));

        IF CryptLevel = ETOPSECRET THEN BEGIN
            {create a "checksum" value to validate }
            {the recipient supplied password       }
            Pk := Pk XOR CryptVer;
            MOVE(Pk, CryptBuff^[CryptCursor], SIZEOF(Pk));
        END
        ELSE
            MOVE(Pk, CryptBuff^[CryptCursor], SIZEOF(Pk));

        INC(CryptCursor, SIZEOF(Pk) - 1);

        FOR J := 1 TO EOB DO BEGIN
            CryptBuff^[CryptCursor + J] := CHR(ORD(Buf^[J]) XOR Key[Rotor]);
            IncrementRotor;
        END;
    END;

    (****************************************************************************)

    CONSTRUCTOR Crypter.FileBufSendInit(CryptLevel     : CryptLevelT;
                                        VAR F          : FILE;
                                        VAR Buf        : IoBuffPtr;
                                        VAR PW         : STRING;
                                        COP            : CylonP);
    VAR
        Result,
        EOL,
        I,
        J,
        K,
        ClearCursor,
        CryptCursor    : WORD;
        Strg           : STRING;
        CrLf           : STRING[2];
        Flg,
        Pk             : LONGINT;
        Colors         : ColorSet;
        Kc             : BOOLEAN;
        FUNCTION HexReverse(S : STRING) : STRING;
        VAR
            I              : BYTE;
            R              : STRING;
        BEGIN
            R := COPY(S, 7, 2);
            R := R + COPY(S, 5, 2);
            R := R + COPY(S, 3, 2);
            R := R + COPY(S, 1, 2);
            HexReverse := R;
        END;
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;

        CryptBuff := NIL;
        IF COP <> NIL THEN
            COP^.Update;

        CryptMode := EBUFFER;
        ClearCursor := 1;
        CryptCursor := 1;
        Strg := ^Z;
        EOB := Search(Buf^, MailBufSize, Strg[1], 1);
        IF EOB = $FFFF THEN BEGIN
            InitStatus := epWarning + ecBadFormat;
            FAIL;
        END;

        INC(EOB);

        RANDOMIZE;
        Flg := MakeRandLong;

        {create a private key}
        IF CryptLevel = ETOPSECRET THEN BEGIN
            {$R-}
            IF ODD(Flg) THEN
                INC(Flg);         {topsecret is Even}
            IF PW = '' THEN BEGIN
                GetCScheme(Cyan_Scheme, Colors);
                Kc := KeyCapture;
                KeyCapture := TRUE;
                CASE EditPassWord(PW, Colors, EWRITE, NIL, NIL) OF
                    ccDone,
                    ccExitAtBot : ;
                    ccError :
                        FAIL;
                    ccQuit :
                        BEGIN
                            InitStatus := ecUserAbort;
                            CryptBuff := NIL;
                            KeyCapture := Kc;

                            FAIL;
                        END;
                END;              {case}
                KeyCapture := Kc;
            END;
            Pk := 0;
            FOR I := 1 TO LENGTH(PW) DO
                Pk := UpdateCRC32(BYTE(PW[I]), Pk);
        END
        ELSE BEGIN
            IF NOT ODD(Flg) THEN
                INC(Flg);
            Pk := MakeRandLong;
        END;

        {init the encryption key with the public and private key values}
        Strg := TimeDateNow + ^M^J;
        KeyInit(Strg, HexL(Pk));

        {Create the first line of the message}
        Strg := BuffCryptID + Strg;

        {write the preamble}
        BLOCKWRITE(F, Strg[1], LENGTH(Strg), Result);

        {create pub and priv header}
        Strg := HexReverse(HexL(Flg));

        {create a "checksum" value to validate }
        {the recipient supplied password       }
        IF CryptLevel = ETOPSECRET THEN
            Pk := Pk XOR CryptVer;

        Strg := Strg + HexReverse(HexL(Pk));

        FOR I := 1 TO EOB DO BEGIN
            Strg := Strg + HexB(BYTE(BYTE(Buf^[I]) XOR BYTE(Key[Rotor])));
            IncrementRotor;
            {batch crypted lines into 70 char hex strings}
            IF LENGTH(Strg) > 70 THEN BEGIN
                IF COP <> NIL THEN
                    COP^.Update;
                Strg := Strg + ^M^J;
                BLOCKWRITE(F, Strg[1], LENGTH(Strg), Result);
                Strg := '';
            END;
        END;
        Strg := Strg + ^Z;
        BLOCKWRITE(F, Strg[1], LENGTH(Strg), Result);
    END;


    {$ENDIF}
    (****************************************************************************)

    {$IFDEF BUFFEREDCRYPT}
    FUNCTION Crypter.BufSend(VAR F : FILE; COP : CylonP) : BOOLEAN;
    VAR
        LCount,
        I,
        Result         : WORD;
        L              : STRING[2];
        Strg           : STRING;
    BEGIN
        BufSend := FALSE;

        {don't enhex the header}
        BLOCKWRITE(F, CryptBuff^, HeaderEnd - 1, Result);
        IF Result <> HeaderEnd - 1 THEN
            EXIT;

        Strg := '';
        FOR I := HeaderEnd TO EOB + HeaderEnd + (SIZEOF(LONGINT) * 2) - 1 DO BEGIN
            Strg := Strg + HexB(BYTE(CryptBuff^[I]));
            {batch crypted lines into 70 char hex strings}
            IF LENGTH(Strg) > 70 THEN BEGIN
                Strg := Strg + ^M^J;
                BLOCKWRITE(F, Strg[1], LENGTH(Strg), Result);
                Strg := '';
            END;
        END;
        Strg := Strg + ^Z;
        BLOCKWRITE(F, Strg[1], LENGTH(Strg), Result);
        BufSend := Result = LENGTH(Strg);
    END;
    {$ENDIF}

    (****************************************************************************)

    FUNCTION Crypter.AutoCrypt(InName : STRING) : BOOLEAN;
    VAR
        Strg           : STRING;
        COP            : CylonP;
    BEGIN
        AutoCrypt := FALSE;
        NEW(COP, Init('Encrypting', 10));
        IF COP = NIL THEN
            EXIT;
        COP^.Draw;
        ASSIGN(TF, InName);
        {$I-}
        RESET(TF);
        IF IORESULT <> 0 THEN
            EXIT;
        WHILE NOT EOF(TF) DO BEGIN
            READLN(TF, Strg);

            IF ((NOT PutLine(Strg)) OR (NOT COP^.Update)) THEN BEGIN
                CLOSE(TF);
                EXIT;
            END;
        END;
        CLOSE(TF);
        DISPOSE(COP, Done);
        AutoCrypt := TRUE;
    END;

    (****************************************************************************)

    CONSTRUCTOR Crypter.RcvInit(FName, MyName : STRING);
    VAR
        Header         : CryptHead;
        R              : INTEGER;
    BEGIN
        InitStatus := 0;

        IF LENGTH(FName) = 0 THEN
            FAIL;
        CryptBuff := NIL;

        CryptMode := EFile;
        CurName := FName;
        {$I-}
        R := IORESULT;
        ASSIGN(BF, FName);
        RESET(BF, 1);
        R := IORESULT;
        IF R <> 0 THEN
            FAIL;
        BLOCKREAD(BF, Header, SIZEOF(CryptHead));
        {$I+}
        IsCrypted := (Header.ID = CryptID) AND (Header.Vers = CryptVer);

        R := IORESULT;
        {IF R <> 0 THEN
            FAIL;}

        {if header contents indicates the file was not crypted then close}
        {binary file and reopen as text file}
        IF NOT IsCrypted THEN BEGIN
            CLOSE(BF);
            ASSIGN(TF, FName);
            RESET(TF);
            R := IORESULT;
            IF R <> 0 THEN
                FAIL;
            EXIT;
        END;
        PublicKey := Header.PubKey;
        KeyInit('', MyName);
    END;

    (****************************************************************************)

    FUNCTION Crypter.FSeek(L : LONGINT) : BOOLEAN;
    BEGIN
        {$I-}
        SEEK(BF, L);
        {$I+}
        FSeek := IORESULT = 0;
    END;

    (****************************************************************************)

    DESTRUCTOR Crypter.Done;
    VAR
        R              : INTEGER;
    BEGIN
        IF CryptMode = EFile THEN BEGIN
            {$I-}
            IF IsCrypted THEN
                CLOSE(BF)
            ELSE
                CLOSE(TF);
            R := IORESULT;
            {$I+}
        END
        ELSE BEGIN
            IF CryptBuff <> NIL THEN
                FreeMemCheck(CryptBuff, MailBufSize);
        END;
    END;

    (****************************************************************************)

    FUNCTION Crypter.GetLine(VAR L : STRING) : BOOLEAN;
    VAR
        I,
        LenByte        : BYTE;
        Result         : WORD;
    BEGIN

        GetLine := FALSE;
        IF CryptMode <> EFile THEN
            EXIT;
        L := '';
        IF IsCrypted THEN BEGIN
            {First, read in the string length byte (encrypted)}
            BLOCKREAD(BF, LenByte, 1, Result);

            IF Result <> 1 THEN   {CHECK FOR EOF}
                EXIT;

            {Decrypt the string length}
            LenByte := LenByte XOR Key[Rotor];
            IncrementRotor;

            {set the string length}
            L[0] := CHR(LenByte);

            {dont bother with read if zero length string}
            IF LenByte > 0 THEN BEGIN
                {read in the encrypted string}
                BLOCKREAD(BF, L[1], LenByte, Result);
                {everything ok?}
                IF LenByte = Result THEN BEGIN
                    {decrypt the string}
                    FOR I := 1 TO LenByte DO BEGIN
                        L[I] := CHR(ORD(L[I]) XOR ORD(Key[Rotor]));
                        IncrementRotor;
                    END;          {FOR}
                    GetLine := TRUE;
                END;              {IF}
            END
            ELSE
                GetLine := TRUE;
        END                       {IF}
        ELSE BEGIN
            {not crypted, so do raw read of input file}
            {$I-}
            READLN(TF, L);
            GetLine := (NOT EOF(TF)) AND (IORESULT = 0);
            {$I+}
        END;
    END;

    (****************************************************************************)

    FUNCTION Crypter.PutLine(L : STRING) : BOOLEAN;
    VAR
        Result         : WORD;
        I              : BYTE;
        SLen           : BYTE;
    BEGIN

        SLen := LENGTH(L);
        PutLine := FALSE;
        IF CryptMode <> EFile THEN
            EXIT;
        {encrypt string contents, including length byte}
        FOR I := 0 TO SLen DO BEGIN
            L[I] := CHR(ORD(L[I]) XOR Key[Rotor]);
            IncrementRotor;
        END;                      {FOR}

        {Write the encrypted string to file}
        BLOCKWRITE(BF, L, SLen + 1, Result);

        {make sure all the bytes were written}
        PutLine := Result = SLen + 1;

    END;

    (****************************************************************************)
    {unit initialization}

END.                              {of unit krypt}
(****************************************************************************)
(****************************************************************************)


