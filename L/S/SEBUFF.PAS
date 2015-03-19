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
* This unit implements a read-ahead, write-behind disk cache object that
* takes the place of unbuffered BLOCKREAD and BLOCKWRITE calls.
*
* The cache size is defined at instantiation time.  The object supports
* FSEEK and FILEPOS, and attempts to emulate the behavior of similarly
* named Pascal functions.
*
* Assumes a record size of 1 byte.
*
* KGM 4-94
*
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************

}
{$A+,B-,D+,E+,F+,G-,I+,L+,N-,O+,P-,Q+,T-,V-,X+,Y+}


UNIT SEBUFF;

INTERFACE
USES
    Dos,
    OpConst,
    OpRoot;

TYPE
    {a dummy array to allow easier access to the buffers}
    BuffArrayT     = ARRAY[1..$FFFE] OF BYTE;
    BuffArrayP     = ^BuffArrayT;
    {all the possible file modes}
    BufferedFileModeT = (BREAD, BWRITE, BRW, BCLOSED);
    BufferedFileP  = ^BufferedFileT;
    BufferedFileT  = OBJECT(Root)
                         {allocates a buffer and inits data fields}
                         CONSTRUCTOR Init(BuffSize : WORD);
                         {close the file if necessary}
                         DESTRUCTOR Done; VIRTUAL;
                             {opens the disk file}
                         PROCEDURE bASSIGN(Name : PathStr);
                             {opens the file in write mode}
                         PROCEDURE bREWRITE;
                             {opens the file in read mode}
                         PROCEDURE bRESET(ShareMode : WORD);
                             {opens the file in RW mode}
                         PROCEDURE bRESETRW;
                             {read-ahead block read from disk}
                         PROCEDURE bBLOCKREAD(VAR Dest; Size : WORD; VAR NumRead : WORD);
                             {write-behind block write to disk}
                         PROCEDURE bBLOCKWRITE(VAR Src; Size : WORD; VAR NumWritten : WORD);
                             {flush cache and close the disk file}
                         PROCEDURE bCLOSE;
                             {seek into disk file and refresh cache}
                         PROCEDURE bSEEK(N : LONGINT);
                             {returns filepos from cache}
                         FUNCTION bFilePos : LONGINT;
                             {returns the size of the file}
                         FUNCTION bFileSize : LONGINT;
                             {returns disk IO errors if any}
                         FUNCTION bIORESULT : WORD;

                     PRIVATE

                             {stay out of this stuff...}
                         BF             : FILE;
                         Fmode          : BufferedFileModeT;
                         MyBuffSize,
                         _BFilePos,
                         Head,
                         Tail           : LONGINT;
                         Buff           : BuffArrayP;

                             {flush write mode buffer}
                         PROCEDURE bFlush;
                     END;

    {------------------}

IMPLEMENTATION
USES
    OpCrt,
    OpInline;

    CONSTRUCTOR BufferedFileT.Init(BuffSize : WORD);
    BEGIN
        IF NOT GetMemCheck(Buff, BuffSize) THEN BEGIN
            InitStatus := etFatal + ecOutOfMemory;
            FAIL;
        END;
        MyBuffSize := BuffSize;
        Head := 1;
        Tail := 1;
        _BFilePos := 1;
        InitStatus := 0;
        Fmode := BCLOSED;
    END;

    {------------------}

    PROCEDURE BufferedFileT.bASSIGN(Name : PathStr);
    BEGIN
        IF Fmode = BCLOSED THEN
            ASSIGN(BF, Name);
    END;

    {------------------}

    PROCEDURE BufferedFileT.bRESET(ShareMode : WORD);
    VAR
        OldFileMode,
        Tries          : WORD;
    BEGIN
        IF Fmode <> BCLOSED THEN
            bCLOSE;
        Tries := 0;
        OldFileMode := FILEMODE;
        FILEMODE := ShareMode;
        REPEAT
            INC(Tries);
            {open the file for read}
            {$I-}
            RESET(BF, 1);
            {$I+}
            InitStatus := IORESULT;
            IF InitStatus = 162 THEN BEGIN
                Sound(1000);
                Delay(50);
                NOSOUND;
                Delay(450);
            END;
        UNTIL (InitStatus = 0) OR (Tries > 30);
        IF InitStatus <> 0 THEN
            EXIT;
        FILEMODE := OldFileMode;
        Fmode := BREAD;
        Head := 1;
        Tail := 0;
    END;

    {------------------}

    PROCEDURE BufferedFileT.bRESETRW;
    VAR
        OldFileMode,
        Result         : WORD;
    BEGIN
        OldFileMode := FILEMODE;
        bRESET(2);
        IF InitStatus = 0 THEN
            Fmode := BRW;
        FILEMODE := OldFileMode;
    END;

    {------------------}

    PROCEDURE BufferedFileT.bREWRITE;
    VAR
        OldFileMode    : WORD;
    BEGIN
        OldFileMode := FILEMODE;
        FILEMODE := 2;
        IF Fmode <> BCLOSED THEN
            bCLOSE;
        {$I-}
        REWRITE(BF, 1);
        {$I+}
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            FILEMODE := OldFileMode;
            EXIT;
        END;
        Head := 1;
        Tail := MyBuffSize;
        Fmode := BWRITE;
    END;

    {------------------}

    PROCEDURE BufferedFileT.bFlush;
    VAR
        Result         : WORD;
    BEGIN
        CASE Fmode OF
            BWRITE,
            BRW :
                IF (Head < 2) THEN
                    EXIT;
            ELSE
                EXIT;
        END;

        BLOCKWRITE(BF, Buff^, Head - 1, Result);
        IF (Head - 1) <> Result THEN BEGIN
            InitStatus := IORESULT;
            IF InitStatus = 0 THEN
                InitStatus := 101;
        END;
        Head := 1;
    END;

    {------------------}

    PROCEDURE BufferedFileT.bCLOSE;
    VAR
        Result         : WORD;
    BEGIN
        {need to flush the buffer?}
        CASE Fmode OF
            BWRITE,
            BRW :
                IF (Head > 1) THEN
                    bFlush;
        END;

        Fmode := BCLOSED;
        CLOSE(BF);
    END;

    {------------------}

    DESTRUCTOR BufferedFileT.Done;
    BEGIN
        Root.Done;
        IF Fmode <> BCLOSED THEN
            CLOSE(BF);
        FreeMemCheck(Buff, MyBuffSize);
    END;

    {------------------}

    PROCEDURE BufferedFileT.bBLOCKREAD(VAR Dest; Size : WORD; VAR NumRead : WORD);
    VAR
        Result         : WORD;
        D              : BuffArrayT ABSOLUTE Dest;
    BEGIN
        NumRead := 0;
        IF Fmode <> BREAD THEN
            EXIT;
        REPEAT
            {request is fully cached}
            IF Size + Head < Tail + 1 THEN BEGIN
                MOVE(Buff^[Head], D[NumRead + 1], Size);
                INC(NumRead, Size);
                INC(Head, Size);
                EXIT;
            END;
            {part of request in in cache, may need to get rest of request}
            IF Head <= Tail THEN BEGIN
                Result := MinWord((Tail - Head + 1), Size);
                MOVE(Buff^[Head], D[NumRead + 1], Result);
                {dec request size, 'cause we already got some of it}
                DEC(Size, Result);
                INC(NumRead, Result);
                {if we hit End of File then don't bother reloading cache}
                IF EOF(BF) THEN BEGIN
                    {make next read attempt fail}
                    Head := Tail + 1;
                    EXIT;
                END;
            END;
            {reload cache}
            {$I-}
            _BFilePos := FILEPOS(BF);
            BLOCKREAD(BF, Buff^, MyBuffSize, Result);
            IF MyBuffSize <> Result THEN BEGIN
                InitStatus := IORESULT;
                IF InitStatus = 103 THEN
                    Fmode := BCLOSED;
            END;
            {$I+}
            Head := 1;
            Tail := Result;
            _BFilePos := FILEPOS(BF);
            InitStatus := 0;
        UNTIL Result = 0;
    END;

    {------------------}

    PROCEDURE BufferedFileT.bBLOCKWRITE(VAR Src; Size : WORD; VAR NumWritten : WORD);
    VAR
        Result         : WORD;
        D              : BuffArrayT ABSOLUTE Src;
    BEGIN
        NumWritten := 0;
        IF (Fmode = BCLOSED) OR (Fmode = BREAD) THEN
            EXIT;

        REPEAT
            {cache has enough room for all of request}
            IF Size + Head < MyBuffSize + 1 THEN BEGIN
                MOVE(D[NumWritten + 1], Buff^[Head], Size);
                INC(NumWritten, Size);
                INC(Head, Size);
                EXIT;
            END;
            {put part of request in in cache, flush and repeat}
            IF Head <= MyBuffSize THEN BEGIN
                Result := MinWord((MyBuffSize - Head + 1), Size);
                MOVE(D[NumWritten + 1], Buff^[Head], Result);
                {dec request size, 'cause we already got some of it}
                DEC(Size, Result);
                INC(NumWritten, Result);
            END;
            {Flush cache}
            BLOCKWRITE(BF, Buff^, MyBuffSize, Result);
            IF MyBuffSize <> Result THEN BEGIN
                InitStatus := IORESULT;
                IF InitStatus = 0 THEN
                    InitStatus := 101;
            END;
            Head := 1;
            _BFilePos := FILEPOS(BF);
        UNTIL Size = 0;
    END;

    {------------------}

    PROCEDURE BufferedFileT.bSEEK(N : LONGINT);
    VAR
        CurPos         : LONGINT;
    BEGIN
        IF N < 0 THEN
            EXIT;

        CASE Fmode OF
            BCLOSED : ;
            BREAD :
                BEGIN
                    {$I-}
                    SEEK(BF, N);
                    {$I+}
                    InitStatus := IORESULT;
                    Head := 1;
                    Tail := 0;
                    (*
                    CurPos := FILEPOS(BF);
                    {if seek is outside cache range then force cache reload}
                    IF (N >= CurPos) OR (N < (CurPos - MyBuffSize)) THEN BEGIN
                        {$I-}
                        SEEK(BF, N);
                        {$I+}
                        InitStatus := IORESULT;
                        Head := 1;
                        Tail := 0;
                        EXIT;
                    END;
                    IF CurPos > MyBuffSize + 1 THEN
                        {cache contains other than first file segment}
                        Head := CurPos - N - MyBuffSize + 1
                    ELSE
                        {cache contains first file segment}
                        Head := N - 1;
                    *)
                END;
            BWRITE :
                BEGIN
                    bFlush;
                    {$I-}
                    SEEK(BF, N);
                    {$I+}
                    InitStatus := IORESULT;
                    Head := 1;
                    Tail := MyBuffSize;
                    (*
                    CurPos := FILEPOS(BF);
                    {if seek is outside cache range then force cache reload}
                    IF (N < CurPos) OR (N >= (CurPos + MyBuffSize)) THEN BEGIN
                        bFlush;
                        {$I-}
                        SEEK(BF, N);
                        {$I+}
                        InitStatus := IORESULT;
                        Head := 1;
                        Tail := MyBuffSize;
                        EXIT;
                    END;
                    Head := CurPos - N + MyBuffSize + 1;
                    *)
                END;
        END;                      {CASE}
    END;

    {------------------}

    FUNCTION BufferedFileT.bIORESULT : WORD;
    BEGIN
        bIORESULT := InitStatus;
    END;

    {------------------}

    FUNCTION BufferedFileT.bFilePos : LONGINT;
    BEGIN
        CASE Fmode OF
            BCLOSED :
                bFilePos := 0;
            BREAD :
                bFilePos := FILEPOS(BF) - Head;
            BWRITE :
                bFilePos := FILEPOS(BF) + Head;
        END;                      {CASE}
    END;

    {------------------}

    FUNCTION BufferedFileT.bFileSize : LONGINT;
    BEGIN
        CASE Fmode OF
            BCLOSED :
                bFileSize := 0;
            BRW,
            BREAD :
                bFileSize := FILESIZE(BF);
            BWRITE :
                bFileSize := FILESIZE(BF) + Head - 1;
        END;                      {CASE}
    END;

    {------------------}

END.

{------------------}
{------------------}
