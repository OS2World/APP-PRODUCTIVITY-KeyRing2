{$A+,B-,D+,E+,F+,G-,I+,L+,N-,O+,P+,Q-,R-,S+,T-,V+,X+,Y-}
{$M 16384,0,655360}
UNIT VesaPCX1;

INTERFACE
FUNCTION ShowPCX(pcxImage       : STRING;
                 VAR ErrorStr   : STRING;
                 TimeoutMS,
                 X,
                 Y              : WORD) : BOOLEAN;

FUNCTION ViewPCX(PCXFName : STRING; VAR ErrorStr : STRING) : BOOLEAN;

IMPLEMENTATION
USES
    GXERRMSG,
    GX_TP,
    KERROR,
    OpCrt,
    OpDos,
    OpString,
    pcx_tp;
    {CrCmd,}

    {-----------}

    FUNCTION ViewPCX(PCXFName : STRING; VAR ErrorStr : STRING) : BOOLEAN;
    VAR
        SB             : POINTER;
        Result         : BOOLEAN;
    BEGIN
        ViewPCX := FALSE;
        IF NOT SaveWindow(1, 1, ScreenWidth, ScreenHeight, TRUE, SB) THEN BEGIN
            ErrorStr := 'Cannot save the current screen';
            EXIT;
        END;
        Result := ShowPCX(PCXFName, ErrorStr, 0, 0, 0);

        TextMode(LASTMODE);
        RestoreWindow(1, 1, ScreenWidth, ScreenHeight, TRUE, SB);
        ViewPCX := Result;
    END;

CONST
    bufmax         = 30000;

TYPE
    TBuffer        = ARRAY[1..bufmax] OF BYTE;
    PBuffer        = ^TBuffer;

    {-------}

    FUNCTION GetGxXYZ(Mode : WORD; VAR X, Y, Z : WORD) : BOOLEAN;
    BEGIN
        GetGxXYZ := TRUE;
        CASE Mode OF
            gxCGA_4 :
                BEGIN
                    X := 320;
                    Y := 200;
                    Z := 4;
                END;
            gxCGA_6 :
                BEGIN
                    X := 640;
                    Y := 200;
                    Z := 2;
                END;
            gxEGA_D :
                BEGIN
                    X := 320;
                    Y := 200;
                    Z := 16;
                END;
            gxEGA_E :
                BEGIN
                    X := 640;
                    Y := 200;
                    Z := 16;
                END;
            gxEGA_F :
                BEGIN
                    X := 640;
                    Y := 350;
                    Z := 2;
                END;
            gxEGA_10 :
                BEGIN
                    X := 640;
                    Y := 350;
                    Z := 16;
                END;
            gxVGA_11 :
                BEGIN
                    X := 640;
                    Y := 480;
                    Z := 2;
                END;
            gxVGA_12 :
                BEGIN
                    X := 640;
                    Y := 480;
                    Z := 16;
                END;
            gxVGA_13 :
                BEGIN
                    X := 320;
                    Y := 200;
                    Z := 256;
                END;
            gxHERC :
                BEGIN
                    X := 720;
                    Y := 348;
                    Z := 2;
                END;
            gxTS_29 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 16;
                END;
            gxTS_2D :
                BEGIN
                    X := 640;
                    Y := 350;
                    Z := 256;
                END;
            gxTS_2E :
                BEGIN
                    X := 640;
                    Y := 480;
                    Z := 256;
                END;
            gxTS_30 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 256;
                END;
            gxTS_38 :
                BEGIN
                    X := 1024;
                    Y := 768;
                    Z := 256;
                END;
            gxPAR_58 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 16;
                END;
            gxPAR_59 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 2;
                END;
            gxPAR_5E :
                BEGIN
                    X := 640;
                    Y := 400;
                    Z := 256;
                END;
            gxPAR_5F :
                BEGIN
                    X := 640;
                    Y := 480;
                    Z := 256;
                END;
            gxPAR_5C :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 256;
                END;
            gxPAR_60 :
                BEGIN
                    X := 1024;
                    Y := 768;
                    Z := 256;
                END;
            gxV7_62 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 16;
                END;
            gxV7_66 :
                BEGIN
                    X := 640;
                    Y := 400;
                    Z := 256;
                END;
            gxV7_67 :
                BEGIN
                    X := 640;
                    Y := 480;
                    Z := 256;
                END;
            gxV7_69 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 256;
                END;
            gxV7_6A :
                BEGIN
                    X := 1024;
                    Y := 768;
                    Z := 256;
                END;
            gxATI_54 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 16;
                END;
            gxATI_61 :
                BEGIN
                    X := 640;
                    Y := 400;
                    Z := 256;
                END;
            gxATI_62 :
                BEGIN
                    X := 640;
                    Y := 480;
                    Z := 256;
                END;
            gxATI_63 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 256;
                END;
            gxATI_64 :
                BEGIN
                    X := 1024;
                    Y := 768;
                    Z := 256;
                END;
            gxTRI_5B :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 16;
                END;
            gxTRI_5C :
                BEGIN
                    X := 640;
                    Y := 400;
                    Z := 256;
                END;
            gxTRI_5D :
                BEGIN
                    X := 640;
                    Y := 480;
                    Z := 256;
                END;
            gxTRI_5E :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 256;
                END;
            gxTRI_62 :
                BEGIN
                    X := 1024;
                    Y := 768;
                    Z := 256;
                END;
            gxVESA_100 :
                BEGIN
                    X := 640;
                    Y := 400;
                    Z := 256;
                END;
            gxvesa_101 :
                BEGIN
                    X := 640;
                    Y := 480;
                    Z := 256;
                END;
            gxVESA_102 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 16;
                END;
            gxVESA_103 :
                BEGIN
                    X := 800;
                    Y := 600;
                    Z := 256;
                END;
            gxVESA_105 :
                BEGIN
                    X := 1024;
                    Y := 768;
                    Z := 256;
                END;
            ELSE BEGIN
                X := 0;
                Y := 0;
                Z := 0;
                GetGxXYZ := FALSE;
            END;

        END;
    END;

    {-----------}

    FUNCTION ShowPCX(pcxImage       : STRING;
                     VAR ErrorStr   : STRING;
                     TimeoutMS,
                     X,
                     Y              : WORD) : BOOLEAN;
    VAR
        VESAinfo       : GXVESAINFO;
        Header         : PCXHEADER;
        pcxtype        : INTEGER;
        Retcode        : INTEGER;
        tempcode       : INTEGER;
        Key            : CHAR;
        pcxpal         : ARRAY[1..768] OF BYTE;
        pb             : PBuffer;
        StartTime      : LONGINT;
        Z,
        Width,
        Height         : WORD;
    BEGIN
        ShowPCX := FALSE;
        NEW(pb);
        IF pb = NIL THEN BEGIN
            DispErrorDeluxe('PCX buffer fail', 'Insufficient memory', TRUE, Iam);
            EXIT;
        END;

        ErrorStr := 'Ok';
        { Allocate a larger toolkit buffer, to speed up file and display speed. }
        { The toolkit defaults to using an internal 4KB buffer, but if we can   }
        { spare more memory than that, declare a new buffer.                    }
        { REMEMBER: This MUST be a GLOBAL buffer (ie, declare OUTSIDE of procs) }

        Retcode := gxSetBuffer(pb, bufmax);
        { See if a supported chipset present }
        IF (gxQueryChipset = chipUNKNOWN) THEN BEGIN
            { No, see if VESA BIOS is present }
            IF (gxVESAInstalled(VESAinfo) = gxSUCCESS) THEN BEGIN
                { Yes, so use it if necessary }
                Retcode := gxSetChipset(chipVESA);
            END;
        END;

        Retcode := gxQueryChipset;
        Retcode := gxSetChipset(chipVESA); {zzzz added- kgm}
        IF (Retcode <> gxSUCCESS) THEN BEGIN
            DispErrorDeluxe('Invalid display type', '', TRUE, Iam);
            DISPOSE(pb);
            EXIT;
        END;

        { Get PCX header from the file }
        Retcode := pcxGetFileHeader(pcxImage, Header);
        IF (Retcode = gxSUCCESS) THEN BEGIN

            { Get display type from file }
            pcxtype := pcxGetFileType(pcxImage);

            { See if we can display the image with current hardware }
            IF (gxVerifyDisplayType(pcxtype) <> gxSUCCESS) THEN BEGIN

                { No, so try to map it to another type }
                pcxtype := gxMapDisplayType(INTEGER(Header.Nplanes), INTEGER(Header.BitPx));
            END;

            { make sure we did determine the display type }
            IF ((pcxtype >= pcxMINDISP) AND (pcxtype <= pcxMAXDISP)) THEN BEGIN

                { Set the display type and mode we will be using }
                Retcode := gxSetDisplay(pcxtype);
                {Retcode := gxSetDisplay(gxvesa_101);}

                IF (Retcode = gxSUCCESS) THEN BEGIN

                    { Now enter graphics mode }
                    Retcode := gxSetMode(gxGRAPHICS);
                    IF (Retcode = gxSUCCESS) THEN BEGIN

                        { We are in graphics mode, so set the image file palette            }
                        { NOTE: If all your images use a default BIOS palette (or the       }
                        {       default Paintbrush palette), just SKIP setting the palette! }

                        IF (pcxGetFilePalette(pcxtype, pcxImage, @pcxpal) = gxSUCCESS) THEN BEGIN
                            { Now set it }
                            Retcode := gxSetDisplayPalette(@pcxpal);
                        END;

                        if GetGxXYZ(pcxtype, X, Y, Z) then begin
                            Width := Header.X2 - Header.X1;
                            Height := Header.Y2 - Header.Y1;
                            X := (X - Width) DIV 2;
                            Y := (Y - Height) DIV 2;
                            { Now display the image file }
                            Retcode := pcxFileDisplay(pcxImage, X, Y, 0);
                        end;

                        {empty the kbd buffer}
                        WHILE KeyPressed DO
                            ReadKey;

                        IF Retcode = gxSUCCESS THEN BEGIN
                            StartTime := TimeMS;

                            {Wait for a key or timeout}
                            WHILE NOT KeyPressed DO BEGIN
                                IF TimeMS - StartTime > TimeoutMS THEN
                                    BREAK;
                            END;

                            IF KeyPressed THEN
                                Key := ReadKey;
                        END;

                        {Return to text mode}
                        tempcode := gxSetMode(gxTEXT);

                        IF (Retcode <> gxSUCCESS) THEN BEGIN
                            { Error displaying the file }
                            ErrorStr := 'pcxFileDisplay error: ' + GxErrorMessage(Retcode);
                            DISPOSE(pb);
                            EXIT;
                        END;
                    END
                    ELSE BEGIN
                        { Error setting the mode }
                        ErrorStr := 'gxSetMode error: ' + GxErrorMessage(Retcode);
                        DISPOSE(pb);
                        EXIT;
                    END;
                END
                ELSE BEGIN
                    { Error setting the display type (should not occur) }
                    ErrorStr := 'gxSetDisplay error: ' + GxErrorMessage(Retcode);
                    DISPOSE(pb);
                    EXIT;
                END;
            END
            ELSE BEGIN
                { Error determining display type }
                ErrorStr := 'Image requires different hardware: ' + Long2Str(pcxtype);
                DISPOSE(pb);
                EXIT;
            END;
        END
        ELSE BEGIN
            { Error reading PCX header }
            ErrorStr := 'pcxGetFileHeader error: ' + GxErrorMessage(Retcode);
            DISPOSE(pb);
            EXIT;
        END;
        DISPOSE(pb);
        ShowPCX := TRUE;
    END;

    {-----------}

END.

{-----------}
{-----------}
