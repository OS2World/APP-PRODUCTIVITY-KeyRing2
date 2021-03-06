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
* KRYPTON DLL
* A Wrapper for KeyRing/2 DES & Blowfish encryption
*
* Copyright 2000, IDK, Inc.
* All Rights Reserved
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}


{$IFDEF DLL}
LIBRARY KRYPTON;
{$ELSE}
UNIT KRYPTON;
INTERFACE
    {$ENDIF}
USES
    ApMisc,
    KREGUTL,
    OpDate,
    OpString,
    {$IFDEF XLATE}
    BLOWFISH,
    DESUNIT,
    {$ELSE}
    {$IFNDEF NOCRYPT}
    {$IFDEF BLO}
    BLOWFISH,
    {$ELSE BLO}
    Desunit,
    {$ENDIF BLO}
    {$ELSE nocrypt}
    Nocrypt,
    {$ENDIF nocrypt}
    {$ENDIF XLATE}
    Os2Base,
    OS2DEF,
    Strings,
    STRCRC,
    SysUtils,
    UREXX,
    UTTIMDAT,
    USE32,
    VARDEC,
    VPUTILS;

    {$IFDEF DLL}
    {$CDecl-,OrgName+,I-,S-,Delphi+}
{$IFNDEF NOCRYPT}
    {$IFDEF BLO}

{$LINKER
        DATA MULTIPLE NONSHARED
        DESCRIPTION      " IDK, Inc. Blowfish encryption wrapper for KeyRing/2 "
        EXPORTS
            CRYPTINIT = CryptInit
            CRYPTBLOCK = CryptBlock
            DECRYPTBLK = DeCryptBlk
            GETCRYPTTYPE = GetCryptType
            CRYPTDEINIT = CryptDeinit
            SQUAWK = Squawk
}
{$ELSE}

{$LINKER
        DATA MULTIPLE NONSHARED
        DESCRIPTION      " IDK, Inc. DES encryption wrapper for KeyRing/2 "
        EXPORTS
            CRYPTINIT = CryptInit
            CRYPTBLOCK = CryptBlock
            DECRYPTBLK = DeCryptBlk
            GETCRYPTTYPE = GetCryptType
            CRYPTDEINIT = CryptDeinit
            SQUAWK = Squawk
}
{$ENDIF blo}
{$ELSE nocrypt}
{$LINKER
        DATA MULTIPLE NONSHARED
        DESCRIPTION      " IDK, Inc. Placeholder encryption wrapper for KeyRing/2 "
        EXPORTS
            CRYPTINIT = CryptInit
            CRYPTBLOCK = CryptBlock
            DECRYPTBLK = DeCryptBlk
            GETCRYPTTYPE = GetCryptType
            CRYPTDEINIT = CryptDeinit
            SQUAWK = Squawk
}

{$ENDIF}
{$ELSE}
PROCEDURE CryptInit(Password : STRING; VAR Hdr : TCryptHead);
{$IFDEF XLATE}
PROCEDURE DESCryptInit(Password : STRING; VAR Hdr : TCryptHead);
PROCEDURE BLOCryptInit(Password : STRING; VAR Hdr : TCryptHead);
PROCEDURE XlateCrypterDeInit(Mode : TCryptStyle);
{$ENDIF XLATE}
FUNCTION CryptBlock(VAR Block : STRING) : STRING;
FUNCTION DeCryptBlk(VAR Block; BlockSize : LONGINT) : STRING;
FUNCTION GetCryptType : STRING;
PROCEDURE CryptDeinit;
FUNCTION Squawk(Challenge:STRING) : LONGINT;
IMPLEMENTATION
    {$ENDIF}

VAR
    CurHdr         : TCryptHead;
    {$IFDEF XLATE}
        {$DEFINE BLO}
    {$ENDIF}

    {$IFDEF BLO}
    P              : PArray;
    S              : SBox;
    {$ENDIF}

    {crypted constants to prevent hacking the dll binary with string search tools}
CONST
    {12345678}
    SESTRS103 = '�\'#9'�l'#15'��';
    SESTRN103 = 20943;
    SESTRP103 = 37033;

    {--------------}

    {$IFDEF BLO}
    {This function returns true if BlowFish is working as expected and an encrypted heartbeat signal from the KeyRing/2}
    {application EXE has occurred in the last 90 seconds.}
    FUNCTION CheckBlowfishIntegrity(Hdr : TCryptHead) : BOOLEAN;
    VAR
        I,
        J,
        Signature      : LONGINT;
        Strg           : STRING;
    BEGIN
        {guilty until proven innocent}
        Result := FALSE;

        {do initialization of blowfish keyspace, SBoxes and PArray with known 56 char ('iiiiiiiiiii...') password}
        InitBlowFish(CharStr('i', 56), P, S, Hdr);

        {here is where we detect tampering with the executable code by patching the encryption module}
        Signature := - 1;

        FOR I := 1 TO 18 DO       {calc the signature of the PArray}
            Signature := CalcBlockCRC(@P[I], SIZEOF(LONGINT), Signature);

        IF NOT TestStrobe THEN    {trash signature if heartbeat signal from main application is not present}
            INC(Signature);       {someone is using the encryption DLL without the KEYRING2.EXE application running; Fail!}

        {now do the signature for the sboxes - signature is cumulative}
        FOR I := 1 TO 4 DO BEGIN
            FOR J := 0 TO 255 DO BEGIN
                Signature := CalcBlockCRC(@S[I, J], SIZEOF(LONGINT), Signature);
            END;
        END;

        IF Signature <> $BC3B6D5D THEN BEGIN {signature of P and S arrays failed - somebody is messing with the keyspace}
            EXIT;
        END;

        Strg := DecodeStrg(SESTRS103, SESTRN103, SESTRP103); {create a short buffer of known plaintext "12345678"}

        EncryptString(Strg, LENGTH(Strg) + 1, P, S); {encrypt the plain text using BlowFish}

        SetLength(Strg, 8);       {adjust the length, since the Pascal length byte got munched during encryption}

        IF Strg <> 'L�ȣa`�8' THEN BEGIN {compare cyphertext in buffer against the expected cyphertext}
            EXIT;                 {some patch was made to the Blowfish algorithm; fail }
        END;

        Result := TRUE;           {if we made it here, we are good to go}
    END;
    {$ENDIF}

    {--------------}

    PROCEDURE CryptInit(Password : STRING; VAR Hdr : TCryptHead); {$IFDEF DLL} EXPORT ; {$ENDIF}
    VAR
        HdrT           : TCryptHead;
    BEGIN
        IF Hdr.CryptStyle = EUNKNOWN THEN
            {$IFDEF BLO}
            Hdr.CryptStyle := EBFCBC;
        {$ELSE}
            Hdr.CryptStyle := EDESCBC;
        {$ENDIF}

        ChangeInternationalDateFmt(TRUE, TRUE);

        CurHdr := Hdr;
        {$IFNDEF NOCRYPT}
        {$IFDEF BLO}
        FILLCHAR(HdrT, SIZEOF(HdrT), #0);
        HdrT.CryptStyle := EBFCBC;
        IF NOT CheckBlowfishIntegrity(HdrT) THEN BEGIN {if integrity test fails, then go to sleep forever - Take that Kadafi!}
            REPEAT
                DosSleep(100);
            UNTIL FALSE;
        END;

        InitBlowFish(Password, P, S, Hdr);
        {$ELSE}
        InitDES(Password, Hdr);
        {$ENDIF}
        {$ELSE nocrypt}
        InitNoCrypt(Password, Hdr);
        {$ENDIF}
    END;

    {--------------}

    FUNCTION GetCryptType : STRING;
    BEGIN
        {$IFNDEF NOCRYPT}
        {$IFDEF BLO}
        Result := DecodeStrg(SESTRS100, SESTRN100, SESTRP100);
        {$ELSE}
        Result := DecodeStrg(SESTRS101, SESTRN101, SESTRP101);
        {$ENDIF}
        {$ELSE}
        Result := DecodeStrg(SESTRS102, SESTRN102, SESTRP102);
       {$ENDIF NOCRYPT}
    END;

    {--------------}

    {Note: this function returns a string with a corrupt length byte;  make sure you save the original length!}
    FUNCTION CryptBlock(VAR Block : STRING) : STRING; {$IFDEF DLL} EXPORT ; {$ENDIF}
    BEGIN
        {$IFDEF NOCRYPT}
        EncryptString(Block);
        {$ELSE}
        {$IFDEF BLO}
        EncryptString(Block, LENGTH(Block) + 1, P, S);
        {$ELSE}
        DESEncryptString(Block, LENGTH(Block) + 1);
        {$ENDIF}
        {$ENDIF nocrypt}
        Result := Block;
    END;

    {--------------}

    FUNCTION DeCryptBlk(VAR Block; BlockSize : LONGINT) : STRING; {$IFDEF DLL} EXPORT ; {$ENDIF}
    VAR
        Strg           : STRING;
    BEGIN
        {$IFDEF XLATE}
        IF CurHdr.CryptStyle = EDESCBC THEN BEGIN
            DESDecryptString(Block);
        END
        ELSE
            DESDecryptBuff(STRING(Block) [1], BlockSize);
        {$ELSE XLATE}
        {$IFDEF NOCRYPT}
        NoDecrypt(Block);
        {$ELSE}
        {$IFDEF BLO}
        IF CurHdr.CryptStyle = EBFCBC THEN
            DecryptString(Block, P, S)
        ELSE BEGIN
            DecryptBuff(STRING(Block) [1], BlockSize, P, S);
        END;
        {$ELSE}
        IF CurHdr.CryptStyle = EDESCBC THEN BEGIN
            DESDecryptString(Block);
        END
        ELSE
            DESDecryptBuff(STRING(Block) [1], BlockSize);
        {$ENDIF BLO}
        {$ENDIF NOCRYPT}
        {$ENDIF XLATE}
        Result := STRING(Block);
    END;

    {--------------}

    {Return hash of challenge string to caller.  Used by caller to test if KRYPTON.DLL has been replaced by}
    {another encryption module. Returns 32 bit signature. Reply to given challenge changes each day}

    FUNCTION Squawk(Challenge:STRING) : LONGINT;
    BEGIN
        ChangeInternationalDateFmt(TRUE, TRUE);
        Result := CalcPasswordCRC(Challenge) xor  CalcPasswordCRC(DateToStdString(Today));
    END;

    {--------------}

    PROCEDURE CryptDeinit;
    BEGIN
        FILLCHAR(CurHdr, SIZEOF(CurHdr), #0);
        {$IFNDEF NOCRYPT}
        {$IFDEF BLO}
        BFDeinit;
        FILLCHAR(P, SIZEOF(P), #0);
        FILLCHAR(S, SIZEOF(S), #0);
        {$ELSE}
        DESDeinit;
        {$ENDIF}
        {$ENDIF}
    END;

    {--------------}

    {$IFDEF XLATE}
    PROCEDURE DESCryptInit(Password : STRING; VAR Hdr : TCryptHead);
    BEGIN
        IF Hdr.CryptStyle = EUNKNOWN THEN
            Hdr.CryptStyle := EDESCBC;
        CurHdr := Hdr;
        InitDES(Password, Hdr);
    END;

    {--------------}

    PROCEDURE BLOCryptInit(Password : STRING; VAR Hdr : TCryptHead);
    VAR
        HdrT           : TCryptHead;
    BEGIN
        IF Hdr.CryptStyle = EUNKNOWN THEN
            Hdr.CryptStyle := EBFCBC;

        CurHdr := Hdr;
        FILLCHAR(HdrT, SIZEOF(HdrT), #0);
        HdrT.CryptStyle := EBFCBC;
        InitBlowFish(Password, P, S, Hdr);
    END;

    {--------------}

    PROCEDURE XlateCrypterDeInit(Mode : TCryptStyle);
    begin
    end;
    {$ENDIF XLATE}

    {--------------}

    {$IFDEF DLLX}
EXPORTS
    CryptInit name 'CryptInit',
    DeCryptBlk name 'DeCryptBlk',
    GetCryptType name 'GetCyptType',
    CryptBlock name 'CryptBlock',
    CryptDeinit name 'CryptDeinit';
    Squawk name 'Squawk';
{$ENDIF}
    INITIALIZATION
END.

    {--------------}
    {--------------}
