{$A+,B-,D+,E+,F+,G+,I+,L+,N+,O+,P-,Q+,R-,S+,T-,V-,X+,Y+}
{ Filename:~modname~    Version:~version~     Date:~MNAme~ ~day~, ~fullyear~  ~time~
*
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer     Description
* ~log~
*
*
* ~nokeywords~
*
* Description
* -----------
* 16, 256, 16 million color, up to 1280x1024 PCX file viewer for VESA
* video adapter cards.
*
* If you get "banding" of PCX images on your screen then try recompiling with
* OLDSTUFF defined.  My Genoa 8500VL card needs OLDSTUFF off, all the other
* cards I tried need it on.  If you figure out why this is, then please
* contact Kevin McCoy 72470,1233 on CIS, or KEVIN@NEN on MHS with source and
* info.  Thanks...
*
* I got the original source from CIS and hacked it to make it into a BP7 unit.
* Everex Systems should get most of the credit for the original demo program.
*
* The ShowPCX function has some commented out demo code to show what
* capability your card has and some info about the file you are about
* to display.  Un-comment it while you are playing around and then recomment
* it for a professional looking file viewer unit.
*
* This unit works on DOS and in an OS/2 v2.11 VDM.
*
* Things to fix:  Get rid of the %#^&@~!! globals.
*
* Kevin McCoy
* IDK Inc.
* 2217 Aspenpark Ct.
* Thousand Oaks, Ca.  91362
****************************************************************************

}
{$DEFINE OLDSTUFF}
UNIT VESAPCX;

INTERFACE
USES
    DOS;

FUNCTION ShowPCX(PCXFName : PathStr) : BOOLEAN;

{$IFDEF COMET}
function GetErrorString: String;
function ViewPCX(PCXFName : PathStr) : Boolean;
{$ENDIF}

IMPLEMENTATION

USES
{$IFDEF COMET}
    CmdLin,
    CrCmd,
    OpConst,
    OpCrt,
    kerror,
{$ELSE}
    Crt,
{$ENDIF}
    STRINGS;

    {-----------------------------------------------------------------------}

CONST
    rSequAddr      = $3C4;

    {-----------------------------------------------------------------------}

TYPE
    ColorType      = RECORD
                         R,
                         G,
                         B              : BYTE;
                     END;

    PCXHeaderType  = RECORD
                         manu           : BYTE; {10d=0Ah= ZSoft PCX}
                         vers           : BYTE; {0=v2.5,2=v2.8 w/pal,3=v2.8 wo/pal,5=v3.0}
                         Code           : BYTE; {1=PCX run length}
                         bpp            : BYTE; {bits/pixel/plane}
                         Xmin           : WORD; {image dimensions}
                         Ymin           : WORD;
                         Xmax           : WORD;
                         Ymax           : WORD;
                         hres           : WORD; {Source device horz res}
                         vres           : WORD; {Source device vert res}
                         pal            : ARRAY[$00..$0F] OF ColorType;
                         res0           : BYTE; {reserved}
                         npln           : BYTE; {Number of color planes}
                         bpl            : WORD; {Bytes/scan/plane (usually even)}
                         pinf           : WORD; {Palette info (1=color/BW, 2=gray, 9=????)}
                         dpi            : WORD; {Scanner dpi or VRes}
                         res1           : ARRAY[$00..$37] OF BYTE; {reserved}
                     END;

    ByteBufferPtrType = ^ByteBufferType;
    ByteBufferType = ARRAY[$00..$FFFE] OF BYTE;

    {-----------------------------------------------------------------------}

    s80            = STRING[80];
    s8             = STRING[8];

    DacType        = ARRAY[$00..$FF] OF ColorType;

    {-----------------------------------------------------------------------}

    CharString     = ARRAY[$00..$03] OF CHAR;

    ModeListType   = ARRAY[$00..$FF] OF WORD;

    PageFuncPtrType = POINTER;

    VgaInfoBlockType = RECORD
                           VESASignature  : CharString;
                           VESAVersion    : WORD;
                           {OEMStringPtr   : ^CharString;}
                           OEMStringPtr   : PCHAR;

                           Capabilities   : ARRAY[$00..$03] OF BYTE;
                           VideoModePtr   : ^ModeListType;
                           Reserved       : ARRAY[$00..$ED] OF BYTE; {Pad to 256}
                       END;

    ModeInfoBlockType = RECORD
                            {mandatory information}
                            ModeAttributes : WORD;
                            WinAAttributes : BYTE;
                            WinBAttributes : BYTE;
                            WinGranularity : WORD;
                            WinSize        : WORD;
                            WinASegment    : WORD;
                            WinBSegment    : WORD;
                            WinFuncPtr     : PageFuncPtrType;
                            BytesPerScanLine : WORD;

                            {optional information}
                            XResolution    : WORD;
                            YResolution    : WORD;
                            XCharSize      : BYTE;
                            YCharSize      : BYTE;
                            NumberOfPlanes : BYTE;
                            BitsPerPixel   : BYTE;
                            NumberOfBanks  : BYTE;
                            MemoryModel    : BYTE;
                            BankSize       : BYTE;
                            Reserved       : ARRAY[$00..$E2] OF BYTE; {Pad to 256}
                        END;

    {-----------------------------------------------------------------------}
    {-----------------------------------------------------------------------}

VAR
    Reg            : Registers;
    VesaVgaInfo    : VgaInfoBlockType;
    VesaModeInfo   : ModeInfoBlockType;
    prevVesaMode   : WORD;
    VesaMode       : WORD;
    PcxHeader      : PCXHeaderType;
    pcxfile        : FILE;
    PCXFName       : s80;
    I,
    J              : WORD;
    Ch             : CHAR;
    BankMode       : BOOLEAN;
{$IFDEF COMET}
    ErrorStr       : String;
    Status         : Word;
{$ENDIF}

    {-----------------------------------------------------------------------}
    {-----------------------------------------------------------------------}

    FUNCTION decval(Ch : CHAR) : BYTE;

    BEGIN
        decval := 0;
        IF ((Ch >= '0') AND (Ch <= '9')) THEN
            decval := ORD(Ch) - ORD('0');
        IF ((Ch >= 'A') AND (Ch <= 'F')) THEN
            decval := ORD(Ch) - ORD('A') + $0A;
        IF ((Ch >= 'a') AND (Ch <= 'f')) THEN
            decval := ORD(Ch) - ORD('a') + $0A;
    END;

    (************************)

    FUNCTION hex2dec(S : s80) : WORD;
    VAR
        I              : BYTE;
        tmp            : WORD;
        place          : WORD;
    BEGIN
        I := ORD(S[0]);
        place := 1;
        tmp := 0;
        WHILE (I > 0) DO BEGIN
            tmp := tmp + place * decval(S[I]);
            I := I - 1;
            place := place * $10;
        END;
        hex2dec := tmp;
        {    writeln('hex2dec(',s,') = ',tmp);}
    END;

    {-----------------------------------------------------------------------}

    FUNCTION hexval(X : BYTE) : CHAR;
    BEGIN
        hexval := '0';
        IF ((X >= 0) AND (X <= 9)) THEN
            hexval := CHR(X + ORD('0'));
        IF ((X >= 10) AND (X <= 15)) THEN
            hexval := CHR(X - 10 + ORD('A'));
    END;

    (************************)
    
    FUNCTION dec2hex(X : WORD) : s8;
    VAR
        tmp            : s8;
        place          : WORD;

    BEGIN
        {    tmp   := '0';}
        tmp := ' ';
        IF (X >= $100) THEN
            place := $1000
        ELSE
            place := $10;

        REPEAT
            tmp := tmp + hexval(X DIV place);
            X := X MOD place;
            place := place DIV $10;
        UNTIL (place = $0000);

        dec2hex := tmp + 'h';
    END;

    (************************)
    
    FUNCTION hex(X : WORD) : s8;
    VAR
        tmp            : s8;
        place          : WORD;
    BEGIN
        tmp := '0';
        IF (X >= $100) THEN
            place := $1000
        ELSE
            place := $10;

        REPEAT
            tmp := tmp + hexval(X DIV place);
            X := X MOD place;
            place := place DIV $10;
        UNTIL (place = $0000);

        hex := tmp + 'h';
    END;

    (************************)

    FUNCTION addrhex(X : WORD) : s8;
    VAR
        tmp            : s8;
        place          : WORD;
    BEGIN
        tmp := '';
        place := $1000;

        REPEAT
            tmp := tmp + hexval(X DIV place);
            X := X MOD place;
            place := place DIV $10;
        UNTIL (place = $0000);

        addrhex := tmp;
    END;

    {-----------------------------------------------------------------------}

    FUNCTION Min(M, N : LONGINT) : LONGINT;
    BEGIN
        IF (M < N) THEN
            Min := M
        ELSE
            Min := N;
    END;
    
    (************************)
    
    FUNCTION Max(M, N : LONGINT) : LONGINT;
    BEGIN
        IF (M > N) THEN
            Max := M
        ELSE
            Max := N;
    END;

    {-----------------------------------------------------------------------}

    PROCEDURE SetVesaBank(Gran           : BYTE;
                          Win            : BYTE;
                          Bank           : BYTE);
    VAR
        Reg            : Registers;
    BEGIN
        IF BankMode THEN BEGIN
            reg.AX := $4F05;
            reg.BH := $00;
            reg.BL := win;
            reg.DX := bank;
            intr($10, reg);
        END
        ELSE BEGIN
            Reg.AX := $4F05;
            Reg.bh := $00;
            Reg.bl := Win;
            Reg.dx := Bank * Gran * $4;
            INTR($10, Reg);
        END;
    END;

    {-----------------------------------------------------------------------}

    PROCEDURE GetVesaBank(Win            : BYTE;
                          VAR Bank       : BYTE);
    VAR
        Reg            : Registers;
    BEGIN
        Reg.AX := $4F05;
        Reg.bh := $01;
        Reg.bl := Win;
        INTR($10, Reg);
        Bank := Reg.dx;
    END;

    {-----------------------------------------------------------------------}

    PROCEDURE FindVesaMode(Xsize, Ysize   : WORD;
                           memmodel       : BYTE;
                           bitpixel       : BYTE;
                           VAR bestVesaMode : WORD;
                           VAR bestVesaModeInfo : ModeInfoBlockType);
    VAR
        tmpVesaModeInfo : ModeInfoBlockType;
        I              : BYTE;
        Error          : BOOLEAN;
    BEGIN
        I := $00;
        bestVesaMode := $FFFF;
        Error := FALSE;
        WHILE ((VesaVgaInfo.VideoModePtr^[I] <> $FFFF) AND NOT(Error)) DO BEGIN
            Reg.AX := $4F01;
            Reg.cx := VesaVgaInfo.VideoModePtr^[I];
            Reg.ES := SEG(tmpVesaModeInfo);
            Reg.DI := OFS(tmpVesaModeInfo);
            INTR($10, Reg);

            Error := (Reg.AX <> $004F);

            IF (tmpVesaModeInfo.ModeAttributes AND $02 = $00) THEN BEGIN
                CASE VesaVgaInfo.VideoModePtr^[I] OF
                    $0100,
                    $0101,
                    $0103,
                    $0105,
                    $0107 :
                        BEGIN
                            tmpVesaModeInfo.XCharSize := 0;
                            tmpVesaModeInfo.YCharSize := 0;
                            tmpVesaModeInfo.NumberOfPlanes := 1;
                            tmpVesaModeInfo.BitsPerPixel := 8;
                            tmpVesaModeInfo.NumberOfBanks := 1;
                            tmpVesaModeInfo.MemoryModel := $04;
                            tmpVesaModeInfo.BankSize := 0;
                        END;
                    $0102,
                    $0104,
                    $0106 :
                        BEGIN
                            tmpVesaModeInfo.XCharSize := 0;
                            tmpVesaModeInfo.YCharSize := 0;
                            tmpVesaModeInfo.NumberOfPlanes := 4;
                            tmpVesaModeInfo.BitsPerPixel := 4;
                            tmpVesaModeInfo.NumberOfBanks := 1;
                            tmpVesaModeInfo.MemoryModel := $03;
                            tmpVesaModeInfo.BankSize := 0;
                        END;
                    ELSE
                        tmpVesaModeInfo.XCharSize := 0;

                    tmpVesaModeInfo.YCharSize := 0;
                    tmpVesaModeInfo.NumberOfPlanes := 0;
                    tmpVesaModeInfo.BitsPerPixel := 0;
                    tmpVesaModeInfo.NumberOfBanks := 0;
                    tmpVesaModeInfo.MemoryModel := $FF;
                    tmpVesaModeInfo.BankSize := 0;
                END;

                CASE VesaVgaInfo.VideoModePtr^[I] OF
                    $0100 :
                        BEGIN
                            tmpVesaModeInfo.XResolution := 640;
                            tmpVesaModeInfo.YResolution := 400;
                        END;
                    $0101 :
                        BEGIN
                            tmpVesaModeInfo.XResolution := 640;
                            tmpVesaModeInfo.YResolution := 480;
                        END;
                    $0102,
                    $0103 :
                        BEGIN
                            tmpVesaModeInfo.XResolution := 800;
                            tmpVesaModeInfo.YResolution := 600;
                        END;
                    $0104,
                    $0105 :
                        BEGIN
                            tmpVesaModeInfo.XResolution := 1024;
                            tmpVesaModeInfo.YResolution := 768;
                        END;
                    $0106,
                    $0107 :
                        BEGIN
                            tmpVesaModeInfo.XResolution := 1280;
                            tmpVesaModeInfo.YResolution := 1024;
                        END;
                    ELSE
                        tmpVesaModeInfo.XResolution := 0;
                    tmpVesaModeInfo.YResolution := 0;
                END;
            END;

            IF ((tmpVesaModeInfo.XResolution >= Xsize)
                AND (tmpVesaModeInfo.YResolution >= Ysize)
                AND (tmpVesaModeInfo.MemoryModel = memmodel)
                AND (tmpVesaModeInfo.BitsPerPixel = bitpixel)
                AND (tmpVesaModeInfo.ModeAttributes AND $01 = $01)
                ) THEN BEGIN

                IF (bestVesaMode = $FFFF) THEN BEGIN
                    bestVesaMode := VesaVgaInfo.VideoModePtr^[I];
                    bestVesaModeInfo := tmpVesaModeInfo;
                END ELSE IF ((tmpVesaModeInfo.XResolution >= Xsize)
                             AND (tmpVesaModeInfo.XResolution <= bestVesaModeInfo.XResolution))
                AND ((tmpVesaModeInfo.YResolution >= Ysize)
                     AND (tmpVesaModeInfo.YResolution <= bestVesaModeInfo.YResolution))
                THEN BEGIN

                    bestVesaModeInfo := tmpVesaModeInfo;
                    bestVesaMode := VesaVgaInfo.VideoModePtr^[I];

                END;
            END;

            I := I + 1;
        END;
    END;

    {-----------------------------------------------------------------------}

    PROCEDURE SetVesaMode(VesaMode : WORD);
    VAR
        Reg            : Registers;
    BEGIN
        Reg.AX := $4F02;
        Reg.bx := VesaMode;
        INTR($10, Reg);
    END;

    {-----------------------------------------------------------------------}

    PROCEDURE GetVesaMode(VAR VesaMode : WORD);
    VAR
        Reg            : Registers;
    BEGIN
        Reg.AX := $4F03;
        INTR($10, Reg);
        VesaMode := Reg.bx;
    END;

    {-----------------------------------------------------------------------}

    PROCEDURE DecodeVesaPcx4(VAR pcxfile    : FILE;
                             PcxHeader      : PCXHeaderType;
                             VesaModeInfo   : ModeInfoBlockType);
    VAR
        pcxbuffptr     : ByteBufferPtrType;
        decodebuffptr  : ByteBufferPtrType;
        pcxfileind     : LONGINT;
        pcxind         : WORD;
        decodeind      : WORD;
        scan           : WORD;
        I, tmp         : BYTE;
        mapmask        : BYTE;
        scrnptr        : ByteBufferPtrType;
        writebank      : BYTE;
        readbank       : BYTE;
        scrnofs        : WORD;
        vesabank       : WORD;
        scanrun        : WORD;
        dac            : DacType;
        pal            : ARRAY[$00..$10] OF BYTE;
    BEGIN
{$I-}
        GETMEM(pcxbuffptr, PcxHeader.bpl * 2 * 4);
        GETMEM(decodebuffptr, PcxHeader.bpl * 4);

        FOR I := $00 TO $0F DO
            pal[I] := I;
        pal[$10] := $00;

        Reg.AX := $1002;
        Reg.ES := SEG(pal);
        Reg.dx := OFS(pal);
        INTR($10, Reg);

        SEEK(pcxfile, FILESIZE(pcxfile) - (3 * 256) - 1);
{$IFDEF COMET}
        Status := IoResult;
        if (Status <> 0) then
           begin
           ErrorStr := ErrorMessage(etFatal + Status);
           close(pcxfile);
           exit;
           end;
{$ENDIF}
        I := 0;
        BLOCKREAD(pcxfile, I, 1);
{$IFDEF COMET}
        Status := IoResult;
        if (Status <> 0) then
           begin
           ErrorStr := ErrorMessage(etFatal + Status);
           close(pcxfile);
           exit;
           end;
{$ENDIF}
        IF (I = $0C) THEN BEGIN
            BLOCKREAD(pcxfile, dac, 3 * 256);
{$IFDEF COMET}
            Status := IoResult;
            if (Status <> 0) then
               begin
               ErrorStr := ErrorMessage(etFatal + Status);
               close(pcxfile);
               exit;
               end;
{$ENDIF}
            FOR I := $00 TO $FF DO BEGIN
                dac[I].R := (dac[I].R {+ $03} ) SHR 2;
                dac[I].G := (dac[I].G {+ $03} ) SHR 2;
                dac[I].B := (dac[I].B {+ $03} ) SHR 2;
            END;
            Reg.cx := $0100;
        END ELSE BEGIN
            FOR I := $00 TO $0F DO BEGIN
                dac[I].R := (PcxHeader.pal[I].R {+3} ) SHR 2;
                dac[I].G := (PcxHeader.pal[I].G {+3} ) SHR 2;
                dac[I].B := (PcxHeader.pal[I].B {+3} ) SHR 2;
            END;
            Reg.cx := $0010;
        END;
        Reg.AX := $1012;
        Reg.bx := $0000;
        Reg.ES := SEG(dac);
        Reg.dx := OFS(dac);
        INTR($10, Reg);

        IF (VesaModeInfo.WinAAttributes AND $05 = $05) THEN BEGIN
            writebank := $00;
            scrnptr := PTR(VesaModeInfo.WinASegment, $0000);
        END ELSE IF (VesaModeInfo.WinBAttributes AND $05 = $05) THEN BEGIN
            writebank := $01;
            scrnptr := PTR(VesaModeInfo.WinBSegment, $0000);
        END ELSE BEGIN
            writebank := $00;
            scrnptr := PTR(SegA000, $0000);
        END;

        IF (VesaModeInfo.WinAAttributes AND $03 = $03) THEN BEGIN
            readbank := $00;
        END ELSE IF (VesaModeInfo.WinBAttributes AND $03 = $03) THEN BEGIN
            readbank := $01;
        END ELSE BEGIN
            readbank := $00;
        END;

        SEEK(pcxfile, SIZEOF(PcxHeader));
        pcxfileind := FILEPOS(pcxfile);

        FOR scan := $0000 TO (PcxHeader.Ymax - PcxHeader.Ymin) DO BEGIN
            pcxind := 0;
            decodeind := 0;

            BLOCKREAD(pcxfile, pcxbuffptr^, Min(PcxHeader.bpl * 2 * 4,
                                                FILESIZE(pcxfile) - pcxfileind));
{$IFDEF COMET}
            Status := IoResult;
            if (Status <> 0) then
               begin
               ErrorStr := ErrorMessage(etFatal + Status);
               close(pcxfile);
               exit;
               end;
{$ENDIF}

            WHILE (decodeind < PcxHeader.bpl * 4) DO BEGIN
                IF (pcxbuffptr^[pcxind] AND $C0 = $C0) THEN BEGIN
                    FOR I := $00 TO (pcxbuffptr^[pcxind] AND $3F) - 1 DO
                        decodebuffptr^[decodeind + I] := pcxbuffptr^[pcxind + 1];
                    decodeind := decodeind + (pcxbuffptr^[pcxind] AND $3F);
                    pcxind := pcxind + 2;
                END ELSE BEGIN
                    decodebuffptr^[decodeind] := pcxbuffptr^[pcxind];
                    decodeind := decodeind + 1;
                    pcxind := pcxind + 1;
                END;
            END;

            pcxfileind := pcxfileind + pcxind;
            SEEK(pcxfile, pcxfileind);

            FOR mapmask := $00 TO $03 DO BEGIN

                PORT[rSequAddr] := $02;
                PORT[rSequAddr + 1] := ($01 SHL mapmask);

                vesabank := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine))
                            DIV LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024));
                SetVesaBank(VesaModeInfo.WinGranularity, writebank, vesabank);
                SetVesaBank(VesaModeInfo.WinGranularity, readbank, vesabank);
                scrnofs := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine))
                           MOD LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024));

                scanrun := Min((PcxHeader.Xmax - PcxHeader.Xmin + 1) DIV 8, VesaModeInfo.XResolution DIV 8);

                IF (LONGINT(LONGINT(scrnofs) + LONGINT(scanrun))
                    > LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024))) THEN BEGIN

                    FOR I := $00 TO (LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024)) - LONGINT(scrnofs)) - 1 DO BEGIN
                        tmp := scrnptr^[scrnofs + I];
                        scrnptr^[scrnofs + I] := decodebuffptr^[mapmask * PcxHeader.bpl + I];
                    END;
                    J := I + 1;
                    vesabank := vesabank + 1;
                    SetVesaBank(VesaModeInfo.WinGranularity, writebank, vesabank);
                    SetVesaBank(VesaModeInfo.WinGranularity, readbank, vesabank);
                    scanrun := (LONGINT(LONGINT(scrnofs) +
                                        LONGINT(scanrun) - 1) -
                                LONGINT(LONGINT(VesaModeInfo.WinSize) *
                                        LONGINT(1024)));
                    scrnofs := $0000;
                    FOR I := $00 TO scanrun DO BEGIN
                        tmp := scrnptr^[scrnofs + I];
                        scrnptr^[scrnofs + I] := decodebuffptr^[mapmask * PcxHeader.bpl + J + I];
                    END;
                END ELSE BEGIN
                    FOR I := $00 TO scanrun - 1 DO BEGIN
                        tmp := scrnptr^[scrnofs + I];
                        scrnptr^[scrnofs + I] := decodebuffptr^[mapmask * PcxHeader.bpl + I];
                    END;
                END;

            END;

        END;
{$I+}

    END;

    {-----------------------------------------------------------------------}

    PROCEDURE DecodeVesaPcx8(VAR pcxfile    : FILE;
                             PcxHeader      : PCXHeaderType;
                             VesaModeInfo   : ModeInfoBlockType);
    VAR
        pcxbuffptr     : ByteBufferPtrType;
        decodebuffptr  : ByteBufferPtrType;
        pcxfileind     : LONGINT;
        pcxind         : WORD;
        decodeind      : WORD;
        scan           : WORD;
        scanrun        : WORD;
        I,
        J              : WORD;
        vesabank       : WORD;
        scrnptr        : ByteBufferPtrType;
        writebank      : BYTE;
        readbank       : BYTE;
        scrnofs        : WORD;
        dac            : DacType;
        Reg            : Registers;

    BEGIN
{$I-}
        GETMEM(pcxbuffptr, PcxHeader.bpl * 2);
        GETMEM(decodebuffptr, PcxHeader.bpl);

        SEEK(pcxfile, FILESIZE(pcxfile) - (3 * 256) - 1);
{$IFDEF COMET}
        Status := IoResult;
        if (Status <> 0) then
           begin
           ErrorStr := ErrorMessage(etFatal + Status);
           close(pcxfile);
           exit;
           end;
{$ENDIF}

        I := 0;
        BLOCKREAD(pcxfile, I, 1);
{$IFDEF COMET}
        Status := IoResult;
        if (Status <> 0) then
           begin
           ErrorStr := ErrorMessage(etFatal + Status);
           close(pcxfile);
           exit;
           end;
{$ENDIF}
        IF (I = $0C) THEN BEGIN
            BLOCKREAD(pcxfile, dac, 3 * 256);
{$IFDEF COMET}
            Status := IoResult;
            if (Status <> 0) then
               begin
               ErrorStr := ErrorMessage(etFatal + Status);
               close(pcxfile);
               exit;
               end;
{$ENDIF}
            FOR I := $00 TO $FF DO BEGIN
                dac[I].R := (dac[I].R {+ $03} ) SHR 2;
                dac[I].G := (dac[I].G {+ $03} ) SHR 2;
                dac[I].B := (dac[I].B {+ $03} ) SHR 2;
            END;
            Reg.cx := $0100;
        END ELSE BEGIN
            FOR I := $00 TO $0F DO BEGIN
                dac[I].R := (PcxHeader.pal[I].R {+3} ) SHR 2;
                dac[I].G := (PcxHeader.pal[I].G {+3} ) SHR 2;
                dac[I].B := (PcxHeader.pal[I].B {+3} ) SHR 2;
            END;
            Reg.cx := $0010;
        END;
        Reg.AX := $1012;
        Reg.bx := $0000;
        Reg.ES := SEG(dac);
        Reg.dx := OFS(dac);
        INTR($10, Reg);

        IF (VesaModeInfo.WinAAttributes AND $05 = $05) THEN BEGIN
            writebank := $00;
            scrnptr := PTR(VesaModeInfo.WinASegment, $0000);
        END ELSE IF (VesaModeInfo.WinBAttributes AND $05 = $05) THEN BEGIN
            writebank := $01;
            scrnptr := PTR(VesaModeInfo.WinBSegment, $0000);
        END ELSE BEGIN
            writebank := $00;
            scrnptr := PTR($A000, $0000);
        END;

        IF (VesaModeInfo.WinAAttributes AND $03 = $03) THEN BEGIN
            readbank := $00;
        END ELSE IF (VesaModeInfo.WinBAttributes AND $03 = $03) THEN BEGIN
            readbank := $01;
        END ELSE BEGIN
            readbank := $00;
        END;

        SEEK(pcxfile, SIZEOF(PcxHeader));
{$IFDEF COMET}
        Status := IoResult;
        if (Status <> 0) then
           begin
           ErrorStr := ErrorMessage(etFatal + Status);
           close(pcxfile);
           exit;
           end;
{$ENDIF}
        pcxfileind := FILEPOS(pcxfile);

        FOR scan := $0000 TO (PcxHeader.Ymax - PcxHeader.Ymin) DO BEGIN
            pcxind := 0;
            decodeind := 0;

            BLOCKREAD(pcxfile, pcxbuffptr^, Min(PcxHeader.bpl * 2, FILESIZE(pcxfile) - pcxfileind));
{$IFDEF COMET}
            Status := IoResult;
            if (Status <> 0) then
               begin
               ErrorStr := ErrorMessage(etFatal + Status);
               close(pcxfile);
               exit;
               end;
{$ENDIF}

            WHILE (decodeind < PcxHeader.bpl) DO BEGIN
                IF (pcxbuffptr^[pcxind] AND $C0 = $C0) THEN BEGIN
                    FOR I := $00 TO (pcxbuffptr^[pcxind] AND $3F) - 1 DO
                        decodebuffptr^[decodeind + I] := pcxbuffptr^[pcxind + 1];
                    decodeind := decodeind + (pcxbuffptr^[pcxind] AND $3F);
                    pcxind := pcxind + 2;
                END ELSE BEGIN
                    decodebuffptr^[decodeind] := pcxbuffptr^[pcxind];
                    decodeind := decodeind + 1;
                    pcxind := pcxind + 1;
                END;
            END;

            pcxfileind := pcxfileind + pcxind;
            SEEK(pcxfile, pcxfileind);
{$IFDEF COMET}
            Status := IoResult;
            if (Status <> 0) then
               begin
               ErrorStr := ErrorMessage(etFatal + Status);
               close(pcxfile);
               exit;
               end;
{$ENDIF}

            IF (VesaModeInfo.MemoryModel = $04) THEN BEGIN

                vesabank := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine))
                            DIV LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024));

                SetVesaBank(VesaModeInfo.WinGranularity, writebank, vesabank);

                scrnofs := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine))
                           MOD LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024));

                scanrun := Min(PcxHeader.Xmax - PcxHeader.Xmin, VesaModeInfo.XResolution);

                IF (LONGINT(LONGINT(scrnofs) + LONGINT(scanrun))
                    > LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024))) THEN BEGIN
                    FOR I := $00 TO (LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024)) - LONGINT(scrnofs)) - 1 DO
                        scrnptr^[scrnofs + I] := decodebuffptr^[I];
                    J := I + 1;
                    vesabank := vesabank + 1;
                    SetVesaBank(VesaModeInfo.WinGranularity, writebank, vesabank);
                    GetVesaBank(writebank, BYTE(vesabank));

                    scanrun := (LONGINT(LONGINT(scrnofs) + LONGINT(scanrun) - 1)
                                - LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024)));
                    scrnofs := $0000;
                    FOR I := $00 TO scanrun DO
                        scrnptr^[scrnofs + I] := decodebuffptr^[J + I];
                END ELSE BEGIN
                    FOR I := $00 TO scanrun - 1 DO
                        scrnptr^[scrnofs + I] := decodebuffptr^[I];
                END;

            END ELSE BEGIN        {Sequential 256-color mode}

                scrnofs := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine));
                scanrun := Min(PcxHeader.Xmax - PcxHeader.Xmin, VesaModeInfo.XResolution);

                FOR I := $00 TO scanrun - 1 DO BEGIN
                    PORT[rSequAddr] := $02;
                    PORT[rSequAddr + 1] := ($01 SHL (I MOD 4));

                    J := scrnptr^[scrnofs + (I DIV 4)];
                    scrnptr^[scrnofs + (I DIV 4)] := decodebuffptr^[I];
                END;

            END;

        END;
{$I+}
    END;

    {-----------------------------------------------------------------------}

    PROCEDURE DecodeVesaPcx24bit(VAR pcxfile    : FILE;
                                 PcxHeader      : PCXHeaderType;
                                 VesaModeInfo   : ModeInfoBlockType);
    VAR
        pcxbuffptr     : ByteBufferPtrType;
        decodebuffptr  : ByteBufferPtrType;
        pcxfileind     : LONGINT;
        pcxind         : WORD;
        decodeind      : WORD;
        scan           : WORD;
        I              : WORD;
        scrnptr        : ByteBufferPtrType;
        writebank      : BYTE;
        readbank       : BYTE;
        scrnofs        : WORD;
        vesabank       : WORD;
        scanrun        : WORD;
        bytesperpix    : BYTE;
        tmppix16       : WORD;

    BEGIN
{$I-}
        GETMEM(pcxbuffptr, PcxHeader.bpl * 2 * 3);
        GETMEM(decodebuffptr, PcxHeader.bpl * 3);

        IF (VesaModeInfo.WinAAttributes AND $05 = $05) THEN BEGIN
            writebank := $00;
            scrnptr := PTR(VesaModeInfo.WinASegment, $0000);
        END ELSE IF (VesaModeInfo.WinBAttributes AND $05 = $05) THEN BEGIN
            writebank := $01;
            scrnptr := PTR(VesaModeInfo.WinBSegment, $0000);
        END ELSE BEGIN
            writebank := $00;
            scrnptr := PTR($A000, $0000);
        END;

        IF (VesaModeInfo.WinAAttributes AND $03 = $03) THEN BEGIN
            readbank := $00;
        END ELSE IF (VesaModeInfo.WinBAttributes AND $03 = $03) THEN BEGIN
            readbank := $01;
        END ELSE BEGIN
            readbank := $00;
        END;

        SEEK(pcxfile, SIZEOF(PcxHeader));
{$IFDEF COMET}
        Status := IoResult;
        if (Status <> 0) then
           begin
           ErrorStr := ErrorMessage(etFatal + Status);
           close(pcxfile);
           exit;
           end;
{$ENDIF}
        pcxfileind := FILEPOS(pcxfile);

        FOR scan := $0000 TO (PcxHeader.Ymax - PcxHeader.Ymin) DO BEGIN

            pcxind := 0;
            decodeind := 0;

            BLOCKREAD(pcxfile, pcxbuffptr^, Min(PcxHeader.bpl * 2 * 3,
                                                FILESIZE(pcxfile) - pcxfileind));
{$IFDEF COMET}
            Status := IoResult;
            if (Status <> 0) then
               begin
               ErrorStr := ErrorMessage(etFatal + Status);
               close(pcxfile);
               exit;
               end;
{$ENDIF}

            WHILE (decodeind < PcxHeader.bpl * 3) DO BEGIN
                IF (pcxbuffptr^[pcxind] AND $C0 = $C0) THEN BEGIN
                    FOR I := $00 TO (pcxbuffptr^[pcxind] AND $3F) - 1 DO
                        decodebuffptr^[decodeind + I] := pcxbuffptr^[pcxind + 1];
                    decodeind := decodeind + (pcxbuffptr^[pcxind] AND $3F);
                    pcxind := pcxind + 2;
                END ELSE BEGIN
                    decodebuffptr^[decodeind] := pcxbuffptr^[pcxind];
                    decodeind := decodeind + 1;
                    pcxind := pcxind + 1;
                END;
            END;

            pcxfileind := pcxfileind + pcxind;
            SEEK(pcxfile, pcxfileind);
{$IFDEF COMET}
            Status := IoResult;
            if (Status <> 0) then
               begin
               ErrorStr := ErrorMessage(etFatal + Status);
               close(pcxfile);
               exit;
               end;
{$ENDIF}

            bytesperpix := VesaModeInfo.BitsPerPixel DIV 8;

            IF ((VesaModeInfo.BitsPerPixel = 24) OR (VesaModeInfo.BitsPerPixel = 32)) THEN BEGIN

                vesabank := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine))
                            DIV LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024));
                SetVesaBank(VesaModeInfo.WinGranularity, writebank, vesabank);
                SetVesaBank(VesaModeInfo.WinGranularity, readbank, vesabank);
                scrnofs := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine))
                           MOD LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024));

                scanrun := Min((PcxHeader.Xmax - PcxHeader.Xmin + 1), VesaModeInfo.XResolution);

                IF (LONGINT(LONGINT(scrnofs) + LONGINT(scanrun))
                    > LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024))) THEN BEGIN

                    FOR I := $00 TO (LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024)) - LONGINT(scrnofs)) - 1 DO BEGIN
                        scrnptr^[scrnofs + I * bytesperpix + 0] := decodebuffptr^[2 * PcxHeader.bpl + I];
                        scrnptr^[scrnofs + I * bytesperpix + 1] := decodebuffptr^[1 * PcxHeader.bpl + I];
                        scrnptr^[scrnofs + I * bytesperpix + 2] := decodebuffptr^[0 * PcxHeader.bpl + I];
                    END;
                    J := I + 1;
                    vesabank := vesabank + 1;
                    SetVesaBank(VesaModeInfo.WinGranularity, writebank, vesabank);
                    SetVesaBank(VesaModeInfo.WinGranularity, readbank, vesabank);
                    scanrun := (LONGINT(LONGINT(scrnofs) +
                                        LONGINT(scanrun) - 1) -
                                LONGINT(LONGINT(VesaModeInfo.WinSize) *
                                        LONGINT(1024)));
                    scrnofs := $0000;
                    FOR I := $00 TO scanrun DO BEGIN
                        scrnptr^[scrnofs + I * bytesperpix + 0] := decodebuffptr^[2 * PcxHeader.bpl + J + I];
                        scrnptr^[scrnofs + I * bytesperpix + 1] := decodebuffptr^[1 * PcxHeader.bpl + J + I];
                        scrnptr^[scrnofs + I * bytesperpix + 2] := decodebuffptr^[0 * PcxHeader.bpl + J + I];
                    END;
                END ELSE BEGIN
                    FOR I := $00 TO scanrun - 1 DO BEGIN
                        scrnptr^[scrnofs + I * bytesperpix + 0] := decodebuffptr^[2 * PcxHeader.bpl + I];
                        scrnptr^[scrnofs + I * bytesperpix + 1] := decodebuffptr^[1 * PcxHeader.bpl + I];
                        scrnptr^[scrnofs + I * bytesperpix + 2] := decodebuffptr^[0 * PcxHeader.bpl + I];
                    END;
                END;

            END ELSE IF (VesaModeInfo.BitsPerPixel = 16) THEN BEGIN

                vesabank := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine))
                            DIV LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024));
                SetVesaBank(VesaModeInfo.WinGranularity, writebank, vesabank);
                SetVesaBank(VesaModeInfo.WinGranularity, readbank, vesabank);
                scrnofs := LONGINT(LONGINT(scan) * LONGINT(VesaModeInfo.BytesPerScanLine))
                           MOD LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024));

                scanrun := Min((PcxHeader.Xmax - PcxHeader.Xmin + 1), VesaModeInfo.XResolution);

                IF (LONGINT(LONGINT(scrnofs) + LONGINT(scanrun))
                    > LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024))) THEN BEGIN

                    FOR I := $00 TO (LONGINT(LONGINT(VesaModeInfo.WinSize) * LONGINT(1024)) - LONGINT(scrnofs)) - 1 DO BEGIN
                        tmppix16 := ((decodebuffptr^[0 * PcxHeader.bpl + I] AND $F8) SHL 7)
                                    OR ((decodebuffptr^[1 * PcxHeader.bpl + I] AND $F8) SHL 2)
                                    OR (decodebuffptr^[2 * PcxHeader.bpl + I] SHR 3);
                        scrnptr^[scrnofs + I * bytesperpix] := LO(tmppix16);
                        scrnptr^[scrnofs + I * bytesperpix + 1] := HI(tmppix16);
                    END;
                    J := I + 1;
                    vesabank := vesabank + 1;
                    SetVesaBank(VesaModeInfo.WinGranularity, writebank, vesabank);
                    SetVesaBank(VesaModeInfo.WinGranularity, readbank, vesabank);
                    scanrun := (LONGINT(LONGINT(scrnofs) +
                                        LONGINT(scanrun) - 1) -
                                LONGINT(LONGINT(VesaModeInfo.WinSize) *
                                        LONGINT(1024)));
                    scrnofs := $0000;
                    FOR I := $00 TO scanrun DO BEGIN
                        tmppix16 := ((decodebuffptr^[0 * PcxHeader.bpl + J + I] AND $F8) SHL 7)
                                    OR ((decodebuffptr^[1 * PcxHeader.bpl + J + I] AND $F8) SHL 2)
                                    OR (decodebuffptr^[2 * PcxHeader.bpl + J + I] SHR 3);
                        scrnptr^[scrnofs + I * bytesperpix] := LO(tmppix16);
                        scrnptr^[scrnofs + I * bytesperpix + 1] := HI(tmppix16);
                    END;
                END ELSE BEGIN
                    FOR I := $00 TO scanrun - 1 DO BEGIN
                        tmppix16 := ((decodebuffptr^[0 * PcxHeader.bpl + I] AND $F8) SHL 7)
                                    OR ((decodebuffptr^[1 * PcxHeader.bpl + I] AND $F8) SHL 2)
                                    OR (decodebuffptr^[2 * PcxHeader.bpl + I] SHR 3);
                        scrnptr^[scrnofs + I * bytesperpix] := LO(tmppix16);
                        scrnptr^[scrnofs + I * bytesperpix + 1] := HI(tmppix16);
                    END;
                END;

            END;

        END;
{$I+}
    END;

    {-----------------------------------------------------------------------}
    {-----------------------------------------------------------------------}

    FUNCTION ShowPCX(PCXFName : PathStr) : BOOLEAN;
    BEGIN
        ShowPCX := FALSE;
        Reg.AX := $4F00;
        Reg.ES := SEG(VesaVgaInfo);
        Reg.DI := OFS(VesaVgaInfo);
        INTR($10, Reg);

        IF (Reg.al <> $4F) THEN BEGIN
{$IFNDEF COMET}
            WRITELN('ERROR: VESA Function 00h: Return Super VGA Information not supported.');
{$ELSE}
            ErrorStr := 'VESA Function 00h: Return Super VGA Information not supported.';
{$ENDIF}
            EXIT;
        END;

        IF (Reg.ah <> $00) THEN BEGIN
{$IFNDEF COMET}
            WRITELN('ERROR: VESA Function 00h: Return Super VGA Information failed.');
{$ELSE}
            ErrorStr := 'VESA Function 00h: Return Super VGA Information failed.';
{$ENDIF}
            EXIT;
        END;

(*

    WRITELN;
    WRITELN('VESA PCX file decoder');
    WRITELN('A demonstration of hardware independent VESA programming.');
    WRITELN('1991 Everex Systems, Inc.');
    WRITELN;


    IF (PARAMCOUNT = 0) THEN BEGIN
        WRITE('Input name of PCX file to display >> ');
        READLN(pcxfname);
    END ELSE
        pcxfname := PARAMSTR(1);

    WRITELN('---------------------------------------');
    WRITELN;

    WRITELN('VESA VGA Information:');

    WRITE('    VESA Signature: ');
    FOR i := $00 TO $03 DO
        WRITE(VesaVgaInfo.VESASignature[i]);
    WRITELN;

    WRITE('    VESA Version  : v');
    WRITE(VesaVgaInfo.VESAVersion DIV $100);
    WRITE('.');
    WRITE(VesaVgaInfo.VESAVersion MOD $100);
    WRITELN;

    WRITE('    OEM String    : ');
    WRITE(StrPas(VesaVgaInfo.OEMStringPtr));
    {
    i := $00;
    WHILE (VesaVgaInfo.OEMStringPtr^[i] <> #00) DO BEGIN
        WRITE(VesaVgaInfo.OEMStringPtr^[i]);
        i := i + 1;
    END;
    }
    WRITELN;

    WRITE('    Capabilities  : ');
    FOR j := $00 TO $03 DO
        FOR i := $00 TO $07 DO
            IF ((VesaVgaInfo.Capabilities[j] AND ($80 SHR i)) = $00) THEN
                WRITE('0')
            ELSE
                WRITE('1');
    WRITELN;

    WRITE('    Modes         : ');
    i := $00;
    WHILE (VesaVgaInfo.VideoModePtr^[i] <> $FFFF) DO BEGIN
        IF ((i MOD 8) = 0) THEN BEGIN
            WRITELN;
            WRITE('        ');
        END;
        WRITE(addrhex(VesaVgaInfo.VideoModePtr^[i]), 'h ');
        i := i + 1;
    END;
    WRITELN;
{}
    READLN;
{}
*)

{$I-}
        ASSIGN(pcxfile, PCXFName);
        RESET(pcxfile, 1);
{$I+}
{$IFDEF COMET}
        Status := IoResult;
        if (Status <> 0) then
           begin
           ErrorStr := ErrorMessage(etFatal + Status);
           exit;
           end;
{$ENDIF}
        IF (FILESIZE(pcxfile) < SIZEOF(PcxHeader)) THEN BEGIN
{$IFNDEF COMET}
            WRITELN('ERROR: Invalid PCX image file specified.');
{$ELSE}
            ErrorStr := 'Invalid PCX image file specified.';
{$ENDIF}
            CLOSE(pcxfile);
            EXIT;
        END;

{$I-}
        BLOCKREAD(pcxfile, PcxHeader, SIZEOF(PcxHeader));
{$I+}
{$IFDEF COMET}
        Status := IoResult;
        if (Status <> 0) then
           begin
           ErrorStr := ErrorMessage(etFatal + Status);
           close(pcxfile);
           exit;
           end;
{$ENDIF}

        IF (PcxHeader.manu <> $0A) THEN BEGIN {Check if PCX file}
{$IFNDEF COMET}
            WRITELN('ERROR: Invalid PCX file format.');
{$ELSE}
            ErrorStr := 'Invalid PCX file format.';
{$ENDIF}
            CLOSE(pcxfile);
            EXIT;
        END;

        IF ((PcxHeader.vers <> 5) {Check for right version}
            OR (PcxHeader.Code <> 1)) {Check for encoding technique}
        THEN BEGIN
{$IFNDEF COMET}
            WRITELN('ERROR: Unsupported PCX file format.');
{$ELSE}
            ErrorStr := 'Unsupported PCX file format.';
{$ENDIF}
            CLOSE(pcxfile);
            EXIT;
        END;

        WITH PcxHeader DO BEGIN
            (*WRITELN('PCX image size: ', (xmax - xmin + 1), 'x', (ymax - ymin + 1), 'x', bpp * npln);*)
            {4 bit, 1 plane}
            IF ((PcxHeader.bpp = 1) AND (PcxHeader.npln = 4)) THEN BEGIN
                FindVesaMode((Xmax - Xmin + 1), (Ymax - Ymin + 1), $03, 4, VesaMode, VesaModeInfo);
                IF (VesaMode = $FFFF) THEN BEGIN
{$IFNDEF COMET}
                    WRITELN('ERROR: Can not find an adequate VESA 4-bit mode.');
{$ELSE}
                    ErrorStr := 'Can not find an adequate VESA 4-bit mode.';
{$ENDIF}
                    CLOSE(pcxfile);
                    EXIT;
                END
                ELSE BEGIN
                (*WRITE('VESA mode res : ', VesaModeInfo.XResolution, 'x');
                WRITELN(VesaModeInfo.YResolution, 'x', VesaModeInfo.BitsPerPixel);
                READLN;*)
                    GetVesaMode(prevVesaMode);
                    SetVesaMode(VesaMode);
                    DecodeVesaPcx4(pcxfile, PcxHeader, VesaModeInfo);
                    {SetVesaMode(prevVesaMode);}
                    CLOSE(pcxfile);
                    ShowPCX := TRUE;
                END;
            {8 bit, 1 plane}
            END ELSE IF ((PcxHeader.bpp = 8) AND (PcxHeader.npln = 1)) THEN BEGIN
                FindVesaMode((Xmax - Xmin + 1), (Ymax - Ymin + 1), $04, 8, VesaMode, VesaModeInfo);
                IF (VesaMode = $FFFF) THEN
                    FindVesaMode((Xmax - Xmin + 1), (Ymax - Ymin + 1), $05, 8, VesaMode, VesaModeInfo);
                IF (VesaMode = $FFFF) THEN BEGIN
{$IFNDEF COMET}
                    WRITELN('ERROR: Can not find an adequate VESA 8-bit mode.');
{$ELSE}
                    ErrorStr := 'Can not find an adequate VESA 8-bit mode.';
{$ENDIF}
                    CLOSE(pcxfile);
                    EXIT;
                END
                ELSE BEGIN
                (*WRITE('VESA mode res : ', VesaModeInfo.XResolution, 'x');
                WRITELN(VesaModeInfo.YResolution, 'x', VesaModeInfo.BitsPerPixel);
                READLN;*)
                    GetVesaMode(prevVesaMode);
                    SetVesaMode(VesaMode);
                    DecodeVesaPcx8(pcxfile, PcxHeader, VesaModeInfo);
                    {SetVesaMode(prevVesaMode);}
                    CLOSE(pcxfile);
                    ShowPCX := TRUE;
                END;
            {24 bit, 3 plane}
            END ELSE IF ((PcxHeader.bpp = 8) AND (PcxHeader.npln = 3)) THEN BEGIN
                FindVesaMode((Xmax - Xmin + 1), (Ymax - Ymin + 1), $04, 32, VesaMode, VesaModeInfo);
                IF (VesaMode = $FFFF) THEN
                    FindVesaMode((Xmax - Xmin + 1), (Ymax - Ymin + 1), $04, 24, VesaMode, VesaModeInfo);
                IF (VesaMode = $FFFF) THEN
                    FindVesaMode((Xmax - Xmin + 1), (Ymax - Ymin + 1), $04, 16, VesaMode, VesaModeInfo);
                IF (VesaMode = $FFFF) THEN BEGIN
{$IFNDEF COMET}
                    WRITELN('ERROR: Can not find an adequate VESA High Color/True Color mode.');
{$ELSE}
                    ErrorStr := 'Can not find an adequate VESA High Color/True Color mode.';
{$ENDIF}
                    CLOSE(pcxfile);
                    EXIT;
                END
                ELSE BEGIN
                (*WRITE('VESA mode res : ', VesaModeInfo.XResolution, 'x');
                WRITELN(VesaModeInfo.YResolution, 'x', VesaModeInfo.BitsPerPixel);
                READLN;*)
                    GetVesaMode(prevVesaMode);
                    SetVesaMode(VesaMode);
                    DecodeVesaPcx24bit(pcxfile, PcxHeader, VesaModeInfo);
                    {SetVesaMode(prevVesaMode);}
                    CLOSE(pcxfile);
                    ShowPCX := TRUE;
                END;
            END ELSE BEGIN
{$IFNDEF COMET}
                WRITELN('ERROR: VESA PCX file decoder only supports VGA 4, 8, and 24 bit formats.');
{$ELSE}
                    ErrorStr := 'VESA PCX file decoder only supports VGA 4, 8, and 24 bit formats.';
{$ENDIF}
                CLOSE(pcxfile);
                EXIT;
            END;
        END;
    END;

{$IFDEF COMET}
function GetErrorString: String;
begin
   GetErrorString := ErrorStr;
end;

function ViewPCX(PCXFName : PathStr): Boolean;
var
   SB     : Pointer;
   Result : Boolean;

begin
   ViewPCX := FALSE;
   BankMode := NOT Is_Param('S');
   ErrorStr := '';
   if not SaveWindow(1, 1, ScreenWidth, ScreenHeight, TRUE, SB) then
      begin
      ErrorStr := 'Cannot save the current screen';
      exit;
      end;
   Result := ShowPCX(PCXFName);
   if Result and (Status = 0) then
      Read_Key
   else
      Result := False;

   TextMode(LASTMODE);
   RestoreWindow(1, 1, ScreenWidth, ScreenHeight, TRUE, SB);
   ViewPCX := Result;
end;
{$ENDIF}


END.
{-----------------------------------------------------------------------}
{-----------------------------------------------------------------------}

