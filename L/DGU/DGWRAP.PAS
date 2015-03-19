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
* Generic paragraph wordwrap object
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT DGWRAP;

INTERFACE
USES
    DGPRINT,
    GLOBTYPE,
    OpRoot,
    OpString,
    LJVAR;

CONST
    EmitTok        = '~~';
    HardSpcTok     = '¯';
    IgnoreTok      = '~/';
    AccumulateTok  = '~+';
TYPE
    {holds a single word in a paragraph}
    PWordNode      = ^TWordNode;
    TWordNode      = OBJECT(SingleListNode)
                         MyWord         : StringPtr;
                         MyFont         : PFont;
                         MyWidth        : REAL;
                         CONSTRUCTOR Init(Strg : STRING; MyPrt : PPrinter; CurFont : PFont; Flags : BYTE);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetWord(VAR CurFont : PFont) : STRING;
                         FUNCTION GetWidth : REAL;
                         PROCEDURE Print(MyPrt : PPrinter; VAR FmtFlags : BYTE);
                     END;

    {holds all words in a single paragraph}
    PWordList      = ^TWordList;
    TWordList      = OBJECT(SingleList)
                         LeftMargin,
                         RightMargin    : REAL;
                         MyPrt          : PPrinter;
                         CONSTRUCTOR Init(P : PPrinter);
                         FUNCTION AddWord(W : STRING; CONST CurFont : PFont; Flags : BYTE) : BOOLEAN;
                         FUNCTION GetWidth(N : WORD) : REAL;
                         PROCEDURE PrintWords(StartWord,
                                              WordCnt        : WORD;
                                              VAR FmtFlags   : BYTE;
                                              PartialLine    : BOOLEAN;
                                              Just           : JustT);
                         FUNCTION GetWord(N : WORD) : STRING;
                     END;

    TWrapAddResult = (EADDED, EFAILED, EEMITTED, EACCUMULATE);
    {manages word wrapping of a paragraph}
    PParaWrap      = ^TParaWrap;
    TParaWrap      = OBJECT(ROOT)
                         CONSTRUCTOR Init(P : PPrinter; Just : JustT);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION AddLine(L : STRING) : TWrapAddResult;
                         PROCEDURE Process;
                         PROCEDURE Clear;
                         FUNCTION NumWords : LONGINT;
                         FUNCTION HasWords : BOOLEAN;
                     PRIVATE
                         LeftMargin,
                         RightMargin    : REAL;
                         MyPrt          : PPrinter;
                         MyWords        : PWordList;
                         Flags          : BYTE;
                         MyJust         : JustT;
                         ForceFinalLF   : BOOLEAN;
                     END;

IMPLEMENTATION

    {instantiate a new word for the current paragraph}
    CONSTRUCTOR TWordNode.Init(Strg : STRING; MyPrt : PPrinter; CurFont : PFont; Flags : BYTE);
    BEGIN
        IF NOT SingleListNode.Init THEN
            FAIL;
        {save the word string on the heap}
        MyWord := StringToHeap(Strg);
        {are we out of heap?}
        IF (MyWord = NIL) AND (LENGTH(Strg) > 0) THEN BEGIN
            InitStatus := 8;      {out of memory}
            FAIL;
        END;
        {save the font}
        MyFont := CurFont;
        {calculate the width of the string}
        MyWidth := MyPrt^.ComputeStringWidthMF(Strg, MyFont^.FID, Flags);
    END;

    {-----------}

    {blow off the word}
    DESTRUCTOR TWordNode.Done;
    BEGIN
        DisposeString(MyWord);
        INHERITED Done;
    END;

    {-----------}

    {return the word and font}
    FUNCTION TWordNode.GetWord(VAR CurFont : PFont) : STRING;
    BEGIN
        CurFont := MyFont;
        GetWord := StringFromHeap(MyWord);
    END;

    {-----------}

    {return the width of the word}
    FUNCTION TWordNode.GetWidth : REAL;
    BEGIN
        GetWidth := MyWidth;
    END;

    {-----------}

    {print a single word on the printer}
    PROCEDURE TWordNode.Print(MyPrt          : PPrinter;
                              VAR FmtFlags   : BYTE);
    VAR
        Strg           : STRING;
        I              : BYTE;
    BEGIN
        Strg := '';
        FOR I := 1 TO LENGTH(MyWord^) DO BEGIN
            CASE MyWord^[I] OF
                ItalicTok :
                    BEGIN
                        {toggle italics}
                        MyPrt^.PutStr(Strg);
                        Strg := '';
                        FmtFlags := FmtFlags XOR wrItalic;
                        IF (FmtFlags AND wrItalic) <> 0 THEN
                            MyPrt^.PutStr(StringFromHeap(MyPrt^.ljItalOn))
                        ELSE
                            MyPrt^.PutStr(StringFromHeap(MyPrt^.ljItalOff));
                    END;
                ULTok :           {toggle underline}
                    BEGIN
                        FmtFlags := FmtFlags XOR wrUL;
                        MyPrt^.PutStr(Strg);
                        Strg := '';
                        IF (FmtFlags AND wrUL) <> 0 THEN
                            MyPrt^.PutStr(StringFromHeap(MyPrt^.ljULOn))
                        ELSE
                            MyPrt^.PutStr(StringFromHeap(MyPrt^.ljULOff));
                    END;
                BoldTok :         {toggle bold}
                    BEGIN
                        FmtFlags := FmtFlags XOR wrBold;
                        MyPrt^.PutStr(Strg);
                        Strg := '';
                        IF (FmtFlags AND wrBold) <> 0 THEN
                            MyPrt^.PutStr(StringFromHeap(MyPrt^.ljBoldOn))
                        ELSE
                            MyPrt^.PutStr(StringFromHeap(MyPrt^.ljBoldOff));
                    END;
                HardSpcTok :
                    Strg := Strg + ' ';
                ELSE
                    Strg := Strg + MyWord^[I];
            END;                  {case}
        END;
        MyPrt^.PutStr(Strg);
    END;

    {-----------}

    {instantiate the list that will hold all the words in a paragraph}
    CONSTRUCTOR TWordList.Init(P : PPrinter);
    BEGIN
        IF NOT SingleList.Init THEN
            FAIL;
        MyPrt := P;
    END;

    {-----------}

    {add a word to the paragraph word list}
    {W = word to add}
    {CurFont= is the baseline font for the paragraph}
    {Flags= holds the current typeface modification flags (bold,italic,...) set by previous words}
    FUNCTION TWordList.AddWord(W : STRING; CONST CurFont : PFont; Flags : BYTE) : BOOLEAN;
    VAR
        P              : PWordNode;
    BEGIN
        AddWord := FALSE;
        NEW(P, Init(W, MyPrt, CurFont, Flags));
        IF P = NIL THEN
            EXIT;
        APPEND(P);
        AddWord := TRUE;
    END;

    {-----------}

    {return the width of the Nth word}
    FUNCTION TWordList.GetWidth(N : WORD) : REAL;
    BEGIN
        GetWidth := PWordNode(Nth(N))^.GetWidth;
    END;

    {-----------}

    {print all the words in the paragraph}
    PROCEDURE TWordList.PrintWords(StartWord,
                                   WordCnt        : WORD;
                                   VAR FmtFlags   : BYTE;
                                   PartialLine    : BOOLEAN;
                                   Just           : JustT);
    VAR
        I              : WORD;
        CPos,
        Slack,
        LLen           : REAL;
    BEGIN
        Slack := 0.0;
        LLen := 0.0;

        {calc line length}
        FOR I := StartWord TO StartWord + WordCnt - 1 DO
            LLen := LLen + GetWidth(I);

        {where are the current margins?}
        LeftMargin := MyPrt^.GetLeftMargin;
        RightMargin := MyPrt^.GetRightMargin;

        IF (StartWord = 1) AND
        (Just = ELEFTRIGHTINDENT) THEN
            LeftMargin := LeftMargin + 0.5;

        IF NOT PartialLine THEN BEGIN
            {prevent div by zero on single word lines}
            I := WordCnt;
            IF I <= 1 THEN
                I := 2;

            Slack := ((RightMargin - LeftMargin) - LLen) / (I - 1);
        END
        ELSE
            Slack := MyPrt^.ComputeStringWidth(' ', CtrlSkip);

        {Nothing to print, so boogie}
        IF LLen = 0.0 THEN
            EXIT;

        {calc start postion of line for various justification modes}
        CASE Just OF
            ESPACEPAD,            {???}
            ELEFT :
                BEGIN
                    CPos := LeftMargin;
                    Slack := 0.0;
                END;
            ECENTER :
                BEGIN
                    CPos := LeftMargin + (((RightMargin - LeftMargin) - LLen) / 2.0);
                    Slack := 0.0;
                END;
            ERIGHT :
                BEGIN
                    CPos := RightMargin - LLen;
                    Slack := 0.0;
                END;
            ELEFTRIGHTINDENT,
            ELEFTRIGHT :
                CPos := LeftMargin;
        END;

        {move to justification start point}
        MyPrt^.PrnGotoX(CPos);

        {step through this line of words}
        FOR I := StartWord TO (StartWord + WordCnt - 1) DO BEGIN
            {print the word}
            PWordNode(Nth(I))^.Print(MyPrt, FmtFlags);
            {calc the position of the next word on the line}
            CPos := CPos + GetWidth(I) + Slack;

            IF NOT PartialLine THEN
                MyPrt^.PrnGotoX(CPos);
        END;

    END;

    {-----------}

    FUNCTION TWordList.GetWord(N : WORD) : STRING;
    VAR
        CurFont        : PFont;
    BEGIN
        GetWord := PWordNode(Nth(N))^.GetWord(CurFont);
    END;

    {-----------}

    CONSTRUCTOR TParaWrap.Init(P : PPrinter; Just : JustT);
    BEGIN
        IF NOT ROOT.Init THEN
            FAIL;
        Flags := wrNorm;
        MyJust := Just;
        LeftMargin := P^.GetLeftMargin;
        RightMargin := P^.GetRightMargin;
        MyPrt := P;
        NEW(MyWords, Init(P));
        IF MyWords = NIL THEN
            FAIL;
        ForceFinalLF := FALSE;
    END;

    {-----------}

    DESTRUCTOR TParaWrap.Done;
    BEGIN
        ROOT.Done;
        DISPOSE(MyWords, Done);
    END;

    {-----------}

    FUNCTION TParaWrap.AddLine(L : STRING) : TWrapAddResult;
    VAR
        I,
        J,
        K              : BYTE;
        MyFont         : PFont;
        Strg           : STRING;
        LLen           : REAL;
        Emit           : BOOLEAN;

        {detect flags spanning multiple words}
        PROCEDURE InitFlags(S : STRING);
        VAR
            C              : BYTE;
        BEGIN
            FOR C := 1 TO LENGTH(S) DO BEGIN
                CASE S[C] OF
                    ItalicTok :   {toggle flags}
                        Flags := Flags XOR wrItalic;
                    BoldTok :
                        Flags := Flags XOR wrBold;
                    ULTok :
                        Flags := Flags XOR wrUL;
                END;
            END;
        END;

    BEGIN
        AddLine := EFAILED;

        Strg := Trim(L);
        {check length of incoming line}
        J := LENGTH(Strg);

        IF J = 0 THEN BEGIN
            {paragraph break, so wrap what we have accumulated so far}
            ForceFinalLF := TRUE;
            Process;
            AddLine := EEMITTED;
            EXIT;
        END;

        {Was the IgnoreToken the only chars in the line?}
        IF Strg = IgnoreTok THEN BEGIN
            AddLine := EADDED;
            EXIT;
        END;

        {Was the AccumulateToken the only chars in the line?}
        IF Strg = AccumulateTok THEN BEGIN
            AddLine := EACCUMULATE;
            EXIT;
        END;

        {look for ignore tokens that appear embedded in line}
        {they are bogus if not the only item on the line    }
        K := POS(IgnoreTok, Strg);

        IF K > 0 THEN BEGIN       {found IgnoreTok, so remove it}
            DELETE(Strg, K, LENGTH(IgnoreTok));
            L := Strg;
            J := LENGTH(Strg);
        END;

        {Was the EmitToken the last two chars in the line?}
        IF (J > 1) AND (POS(EmitTok, Strg) = (J - 1)) THEN BEGIN
            L := Strg;
            DEC(L[0], 2);         {clean off the EmitTok}
            Emit := TRUE;         {set the paragraph break flag}
        END
        ELSE
            Emit := FALSE;        {Clear the paragraph break flag}

        {accumulating, so save the current font}
        MyFont := MyPrt^.ljActiveFont;

        {count the space delimited words on the line}
        J := WordCount(L, [' ']);

        {step through the line and build the word list}
        FOR I := 1 TO J DO BEGIN
            {get a word}
            Strg := ExtractWord(I, L, [' ']);
            {tag on a trailing space}
            Strg := Strg + ' ';
            {add the word to the list}
            IF NOT MyWords^.AddWord(Strg, MyFont, Flags) THEN
                EXIT;             {failed}
            InitFlags(Strg);
        END;

        IF Emit THEN BEGIN
            {EmitTok paragraph break, so wrap what we have accumulated so far}
            ForceFinalLF := TRUE;
            Process;
            AddLine := EEMITTED;
            EXIT;
        END;
        AddLine := EADDED;
    END;

    {-----------}

    PROCEDURE TParaWrap.Process;
    VAR
        WordCnt,
        StartWord,
        I              : WORD;
        NewPos,
        WLen,
        LLen           : REAL;
        FmtFlags       : BYTE;
        Strg           : STRING;
        PartialLine    : BOOLEAN;
    BEGIN
        StartWord := 1;
        WordCnt := 0;
        FmtFlags := 0;
        {move printhead to left margin}
        MyPrt^.PrnGotoX(MyPrt^.GetLeftMargin);
        REPEAT
            {find max # words that will fit between the margins}
            LLen := LeftMargin;
            PartialLine := TRUE;
            FOR I := StartWord TO MyWords^.Size DO BEGIN
                WLen := MyWords^.GetWidth(I);
                Strg := MyWords^.GetWord(I);
                IF (I = 1) AND (MyJust = ELEFTRIGHTINDENT) THEN
                    LLen := LLen + 0.5;

                IF (LLen + WLen) <= RightMargin THEN BEGIN
                    {the current word will fit on the line}
                    LLen := LLen + WLen;
                    {increment the word counter for this line}
                    INC(WordCnt);
                END
                ELSE BEGIN
                    {we hit the peg with some more words left}
                    PartialLine := FALSE;
                    BREAK;
                END;
            END;

            {print this line of text}
            MyWords^.PrintWords(StartWord, WordCnt, FmtFlags, PartialLine, MyJust);
            {move word cursor to the start of the next line of text}
            INC(StartWord, WordCnt);
            {move printhead to next line, left margin}
            IF NOT PartialLine THEN
                IF NOT MyPrt^.LineFeed(NewPos) THEN
                    EXIT;
            {reset wordcount for line}
            WordCnt := 0;
        UNTIL StartWord > MyWords^.Size;
        IF ForceFinalLF THEN BEGIN
            IF PartialLine THEN
                IF NOT MyPrt^.LineFeed(NewPos) THEN
                    EXIT;
            IF NOT MyPrt^.LineFeed(NewPos) THEN
                EXIT;
            ForceFinalLF := FALSE;
        END;
        Clear;                    {paragraph printing complete, so free the wordlist}
    END;

    {-----------}

    PROCEDURE TParaWrap.Clear;
    BEGIN
        {Blow off the wordlist}
        MyWords^.Clear;
    END;

    {-----------}

    FUNCTION TParaWrap.NumWords : LONGINT;
    BEGIN
        NumWords := MyWords^.Size;
    END;

    {-----------}

    FUNCTION TParaWrap.HasWords : BOOLEAN;
    BEGIN
        HasWords := NumWords > 0;
    END;

    {-----------}

END.
    {-----------}
    {-----------}

