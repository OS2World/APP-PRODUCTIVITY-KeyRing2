PROGRAM cryptblw;

{ CryptBlw.Pas (c) 1994 by Walter H. van Holst <2:281/201.4>
  Example program of the usage of the BlowFish unit.

  Hereby donated to the public domain                           }

USES
    Dos,
    BlowFish
    {$IFDEF VirtualPascal}
    ,use32
    {$ENDIF}
    ;

CONST
    BufferSize     = 8192;

    {.$M $9000,0,$20000}

VAR
    Key            : STRING[56];
    InputFile,
    OutputFile     : PathStr;
    Argument       : STRING[2];
    Teller,
    FillBuffer,
    NumRead,
    NumWritten     : WORD;
    INPUT,
    OUTPUT         : FILE;
    Buffer         : ARRAY[0..BufferSize - 1] OF LONGINT;
    InputSize,
    Counter,
    Debug,
    Test1,
    Test2          : LONGINT;
    Buf            : BYTE ABSOLUTE Buffer;
    P              : PArray;
    S              : SBox;
    Hour,
    Minute,
    Second,
    Second100      : WORD;


    FUNCTION File_Exists(CONST FileName : STRING) : BOOLEAN;
    VAR
        F              : FILE;

    BEGIN
        ASSIGN(F, FileName);
        {$i-}
        RESET(F, 1);
        {$i+}
        File_Exists := IORESULT = 0;
    END;


    FUNCTION Passes(InputSize : LONGINT) : LONGINT;
    BEGIN
        Passes := ((InputSize DIV (BufferSize * 4)) + (InputSize MOD (BufferSize * 4)) * 1 -
                   ((InputSize MOD (BufferSize * 4)) * 1 - 1));
    END;

BEGIN
    WRITELN('******');
    Argument := COPY(PARAMSTR(1), 1, 2);
    InputFile := PARAMSTR(3);
    OutputFile := PARAMSTR(4);
    Debug := SIZEOF(Buffer);
    IF (PARAMSTR(1) <> '') AND (PARAMSTR(2) <> '') AND (PARAMSTR(3) <> '') THEN BEGIN
        IF File_Exists(PARAMSTR(3)) THEN BEGIN
            Key := COPY(PARAMSTR(2), 1, 56);
            WRITELN('Initializing key');
            InitBlowFish(Key, P, S);
            FILEMODE := 2;
            ASSIGN(INPUT, InputFile);
            RESET(INPUT, 1);
            InputSize := FILESIZE(INPUT);
            IF OutputFile <> '' THEN
                ASSIGN(OUTPUT, OutputFile) ELSE ASSIGN(OUTPUT, 'OUT.BLW');
            REWRITE(OUTPUT, 1);
            Debug := Passes(InputSize);
            GetTime(Hour, Minute, Second, Second100);
            WRITELN(Hour, ':', Minute, ':', Second, ':', Second100);
            IF Argument = '-e' THEN BEGIN
                FOR Counter := 1 TO Passes(InputSize) DO BEGIN
                    IF Counter < Passes(InputSize) THEN
                        FillBuffer := BufferSize * 4
                    ELSE
                        FillBuffer := InputSize - ((Passes(InputSize) - 1) * (BufferSize * 4));
                    WRITELN('Filling buffer with data');
                    BLOCKREAD(INPUT, Buffer, SIZEOF(Buffer), NumRead);
                    WRITELN('Encrypting the data');
                    FOR Teller := 0 TO (FillBuffer DIV 4) - 1 DO BEGIN
                        BlowEncrypt(Buffer[Teller], Buffer[Teller + 1], P, S);
                        INC(Teller);
                        {WriteLn(Teller);}
                    END;
                    WRITELN('Writing the data');
                    BLOCKWRITE(OUTPUT, Buffer, NumRead, NumWritten);
                    WRITE('Pass ');
                    WRITE(Counter);
                    WRITE(' of ');
                    WRITELN(InputSize DIV BufferSize);
                END;
                CLOSE(INPUT);
                CLOSE(OUTPUT);
            END
            ELSE
                IF PARAMSTR(1) = '-d' THEN BEGIN
                    WRITELN('Decrypting ' + PARAMSTR(3));
                    FOR Counter := 1 TO Passes(InputSize) DO BEGIN
                        IF Counter < Passes(InputSize) THEN
                        FillBuffer := BufferSize * 4 ELSE
                            FillBuffer := InputSize - ((Passes(InputSize) - 1) * (BufferSize * 4));
                        BLOCKREAD(INPUT, Buffer, SIZEOF(Buffer), NumRead);
                        FOR Teller := 0 TO (FillBuffer DIV 4) - 1 DO BEGIN
                            BlowDecrypt(Buffer[Teller], Buffer[Teller + 1], P, S);
                            INC(Teller);
                        END;
                        BLOCKWRITE(OUTPUT, Buffer, NumRead, NumWritten);
                    END;
                    CLOSE(INPUT);
                    CLOSE(OUTPUT);
                END;
            GetTime(Hour, Minute, Second, Second100);
            WRITELN(Hour, ':', Minute, ':', Second, ':', Second100);
        END;
    END;
END.
