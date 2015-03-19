{$C MOVEABLE,DEMANDLOAD,DISCARDABLE}

UNIT dpmidbg;
INTERFACE
USES
    OpRoot;

TYPE
    PHunkNode      = ^THunkNode;
    THunkNode      = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(HunkSize : WORD);
                         DESTRUCTOR Done; VIRTUAL;
                     PRIVATE
                         MyHunk         : POINTER;
                         MySize         : WORD;
                     END;

    PMemGobbler    = ^TMemGobbler;
    TMemGobbler    = OBJECT(Root)
                         CONSTRUCTOR Init(Mem2Leave : LONGINT; HunkSize : WORD);
                         DESTRUCTOR Done; VIRTUAL;
                     PRIVATE
                         HunkList       : SingleListPtr;
                     END;

IMPLEMENTATION
USES
    {KERROR,}
    OpCmd,
    OpConst;

    {-------------}

    CONSTRUCTOR THunkNode.Init(HunkSize : WORD);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;

        GETMEM(MyHunk, HunkSize);
        IF MyHunk = NIL THEN BEGIN
            InitStatus := etFatal + ecOutOfMemory;
            FAIL;
        END;
        MySize := HunkSize;
        {FILLCHAR(MyHunk^, HunkSize, #0);}
    END;

    {-------------}

    DESTRUCTOR THunkNode.Done;
    BEGIN
        INHERITED Done;
        FREEMEM(MyHunk, MySize);
    END;

    {-------------}

    CONSTRUCTOR TMemGobbler.Init(Mem2Leave : LONGINT; HunkSize : WORD);
    VAR
        I              : WORD;
        Ph             : PHunkNode;
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;

        IF Mem2Leave > MEMAVAIL THEN BEGIN
            InitStatus := etFatal + ecOutOfMemory;
            WRITELN('bail1');
            FAIL;
        END;

        IF HunkSize = 0 THEN
            HunkSize := $FF;

        NEW(HunkList, Init);

        IF HunkList = NIL THEN BEGIN
            WRITELN('bail2');
            FAIL;
        END;
        I := 0;
        REPEAT
            IF MAXAVAIL - Mem2Leave > HunkSize THEN BEGIN
                INC(I);
                {writeln(i);}
                NEW(Ph, Init(HunkSize));
                IF Ph = NIL THEN BEGIN
                    InitStatus := etFatal + ecOutOfMemory;
                    WRITELN('bail3 ', MEMAVAIL, ':', MAXAVAIL, ' HLs', HunkList^.Size, ' Chunk:', HunkSize);
                    {DISPOSE(HunkList, Done);
                    FAIL;}
                    EXIT;
                END;
                HunkList^.APPEND(Ph);
            END
            ELSE
                BREAK;
        UNTIL FALSE;
    END;

    {-------------}

    DESTRUCTOR TMemGobbler.Done;
    BEGIN
        DISPOSE(HunkList, Done);
        INHERITED Done;
    END;

    {-------------}
END.
