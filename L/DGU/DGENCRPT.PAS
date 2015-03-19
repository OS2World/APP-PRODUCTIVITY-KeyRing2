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
* Report TEM single key crypter/decrypter
*
* Copyright (C) 1996 IDK Inc.  All rights reserved.
*
* ~notesend~
*
****************************************************************************
}
{$I OPDEFINE.INC}
{$I NDEFINE.INC}
{$A+,B-,D+,E+,F+,G+,I+,L+,N-,O+,P-,Q+,T-,V-,X+,Y+}
UNIT DGENCRPT;

INTERFACE
USES
    DGRPT,
    Dos,
    LJVAR;

TYPE
    TEncHdr        = RECORD
                         BinJunk        : ARRAY[1..255] OF BYTE;
                         RecVerMajor,
                         RecVerMinor,
                         PubKey         : WORD;
                         Sig            : LONGINT;
                     END;

    PEncryptedRpt  = ^TEncryptedRpt;
    TEncryptedRpt  = OBJECT(Report)
                         CONSTRUCTOR Init(FName : PathStr; PrnInfo : TPrnCfg);
                         DESTRUCTOR Done; VIRTUAL;

                     PRIVATE

                         CryptedTem     : FILE;
                         Hdr            : TEncHdr;
                         LastRandSeed   : LONGINT;

                         FUNCTION OpenTemFile : BOOLEAN; VIRTUAL;
                         PROCEDURE CloseTemFile; VIRTUAL;
                         FUNCTION ReadTemLine : BOOLEAN; VIRTUAL;
                         FUNCTION Encrypt : BOOLEAN;
                     END;

IMPLEMENTATION
USES
    KERROR,
    OpDate,
    OpRoot,
    OpString,
    UTTIMDAT,
    UTIAM;

CONST
    HEADERSIG      = 556989118;
    VerMajor       = 1;
    VerMinor       = 0;

    {-------------}

    CONSTRUCTOR TEncryptedRpt.Init(FName : PathStr; PrnInfo : TPrnCfg);
    VAR
        TemDTR,
        TXMDTR         : DateTimeRec;
        OldRandSeed    : LONGINT;
    BEGIN
        TemplateName := FName;

        IF NOT Report.Init(PrnInfo) THEN
            FAIL;

        OldRandSeed := RANDSEED;

        IF GetFileDTR(ForceExtension(TemplateName, 'TEM'), TemDTR) THEN BEGIN
            IF NOT GetFileDTR(ForceExtension(TemplateName, 'TXM'), TXMDTR) THEN BEGIN
                {tem exists, with no TXM: create TXM}
                IF NOT Encrypt THEN
                    FAIL;
                EXIT;
            END;
            IF DTRCompare(TemDTR, TXMDTR) = Greater THEN
                {tem is newer than the TXM: Recompile a new TXM}
                IF NOT Encrypt THEN
                    FAIL;

        END;
        {we don't care if the TEM or TXM is missing at this point.  We will}
        {catch that later.}
        RANDSEED := OldRandSeed;
    END;

    {-------------}

    FUNCTION TEncryptedRpt.OpenTemFile : BOOLEAN;
    VAR
        OFM,
        Result         : WORD;
    BEGIN
        ASSIGN(CryptedTem, TemplateName);
        {$I-}
        OFM := FILEMODE;
        FILEMODE := 0;
        RESET(CryptedTem, 1);
        FILEMODE := OFM;
        Result := IORESULT;
        IF Result <> 0 THEN BEGIN
            DispErrorDeluxe('File open error: ' + TemplateName, ErrorMessage(Result), TRUE, Iam);
            OpenTemFile := FALSE;
            EXIT;
        END;

        FILLCHAR(Hdr, SIZEOF(Hdr), #0);

        BLOCKREAD(CryptedTem, Hdr, SIZEOF(Hdr), Result);

        IF Result <> SIZEOF(Hdr) THEN BEGIN
            DispErrorDeluxe('File read error : ' + TemplateName, ErrorMessage(IORESULT), TRUE, Iam);
            OpenTemFile := FALSE;
            CLOSE(CryptedTem);
            EXIT;
        END;

        IF Hdr.Sig <> HEADERSIG THEN BEGIN
            DispErrorDeluxe('Invalid signature', TemplateName, TRUE, Iam);
            OpenTemFile := FALSE;
            CLOSE(CryptedTem);
            EXIT;
        END;

        IF (Hdr.RecVerMajor <> VerMajor) OR (Hdr.RecVerMinor <> VerMinor) THEN BEGIN
            DispErrorDeluxe('Invalid version', TemplateName, TRUE, Iam);
            OpenTemFile := FALSE;
            CLOSE(CryptedTem);
            EXIT;
        END;

        OpenTemFile := IORESULT = 0;
        LastRandSeed := Hdr.PubKey;
    END;

    {-------------}

    PROCEDURE TEncryptedRpt.CloseTemFile;
    BEGIN
        CLOSE(CryptedTem);
    END;

    {-------------}

    FUNCTION TEncryptedRpt.ReadTemLine : BOOLEAN;
    VAR
        Result         : WORD;
        Strg           : STRING;
        EntryRandSeed,
        FPos           : LONGINT;
        I              : BYTE;
    BEGIN
        EntryRandSeed := RANDSEED;

        {mark current file position}
        FPos := FILEPOS(CryptedTem);
        {read next 255 chars}
        BLOCKREAD(CryptedTem, Strg, SIZEOF(Strg), Result);
        IF Result = 0 THEN BEGIN
            {we hit EOF, and Strg probably contains garbage}
            TemInputLine := '';
            ReadTemLine := TRUE;
            EXIT;
        END;
        RANDSEED := LastRandSeed;
        {decrypt original string length}
        Strg[0] := CHAR(BYTE(Strg[0]) XOR RANDOM($FF));
        {decrypt rest of string}
        FOR I := 1 TO LENGTH(Strg) DO
            Strg[I] := CHAR(BYTE(Strg[I]) XOR RANDOM($FF));
        {seek backwards to next string position in file}
        SEEK(CryptedTem, FPos + LENGTH(Strg) + 1);
        TemInputLine := Strg;
        ReadTemLine := Result = 0;
        LastRandSeed := RANDSEED;
        RANDSEED := EntryRandSeed;
    END;

    {-------------}

    FUNCTION TEncryptedRpt.Encrypt : BOOLEAN;
    VAR
        Fi             : TEXT;
        Fo             : FILE;
        Result,
        Count          : WORD;
        Header         : TEncHdr;
        Strg           : STRING;
        I              : INTEGER;
        EntryRandSeed  : LONGINT;
    BEGIN
        EntryRandSeed := RANDSEED;
        Encrypt := FALSE;

        RANDOMIZE;
        ASSIGN(Fi, ForceExtension(TemplateName, 'TEM'));
        ASSIGN(Fo, ForceExtension(TemplateName, 'TXM'));
        {$I-}
        RESET(Fi);
        Result := IORESULT;
        IF Result <> 0 THEN BEGIN
            DispErrorDeluxe('Error in crypter: ' + TemplateName, ErrorMessage(Result), TRUE, Iam);
            EXIT;
        END;
        REWRITE(Fo, 1);
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            CLOSE(Fi);
            DispErrorDeluxe('Error in crypter: ' + ForceExtension(TemplateName, 'TXM'), ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;
        FILLCHAR(Header, SIZEOF(Header), #0);
        Header.Sig := HEADERSIG;
        Header.RecVerMajor := VerMajor;
        Header.RecVerMinor := VerMinor;

        {create cryptkey for this file}
        Header.PubKey := RANDOM($FFFF) + 1;

        {write the header}
        BLOCKWRITE(Fo, Header, SIZEOF(Header), Result);
        IF Result <> SIZEOF(Header) THEN BEGIN
            CLOSE(Fi);
            CLOSE(Fo);
            DispErrorDeluxe('Crypter write failure', '', TRUE, Iam);
            InitStatus := 160;
            EXIT;
        END;

        RANDSEED := Header.PubKey;

        REPEAT
            IF COP <> NIL THEN
                COP^.Update;
            {read line of clear text}
            READLN(Fi, Strg);

            {get number of chars in string}
            Count := LENGTH(Strg);

            {crypt entire string, including the length byte}
            FOR I := 0 TO Count DO
                BYTE(Strg[I]) := BYTE(Strg[I]) XOR RANDOM($FF);

            {write the crypted string}
            BLOCKWRITE(Fo, Strg, Count + 1, Result);
        UNTIL EOF(Fi);

        {$I+}
        CLOSE(Fi);
        CLOSE(Fo);
        InitStatus := 0;
        Encrypt := TRUE;
        RANDSEED := EntryRandSeed;
    END;

    {-------------}

    DESTRUCTOR TEncryptedRpt.Done;
    BEGIN
        INHERITED Done;
    END;

    {-------------}

END.

    {-------------}
    {-------------}
