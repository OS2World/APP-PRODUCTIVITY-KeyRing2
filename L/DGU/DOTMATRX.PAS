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
* Fujitsu DL6400 driver, plus a field oriented forms printer object that
* implements a field name/coordinates file parser and a filler-inner.
*
* Requires Printer to be in IBM emulation mode!
*
* ~notesend~
*
***************************************************************************

}
{$A+,B-,D+,E+,F+,G+,I+,L+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT DOTMATRX;

INTERFACE
USES
    Dos,
    GLOBTYPE,
    KERROR,
    DGPRINT,
    LJVAR,
    OPPRNLOW,
    OpRoot,
    OpString,
    UTSORT;

TYPE
    {simple dot matrix printer object derived from laserjet}
    PDotMatrix     = ^TDotMatrix;
    TDotMatrix     = OBJECT(TLaserJet)

                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);
                         FUNCTION PrnGotoXY(CONST X, Y : REAL) : BOOLEAN; VIRTUAL;
                             {-Update the cursor position...X and Y specified in inches }
                         FUNCTION PrnGotoX(CONST X : REAL) : BOOLEAN; VIRTUAL;
                             {-Update the horizontal cursor position }
                         FUNCTION PrnGotoY(CONST Y : REAL) : BOOLEAN; VIRTUAL;
                             {-Update the vertical cursor position }
                         PROCEDURE EOJ;
                     PRIVATE
                         CurCol         : REAL;
                     END;

    {holds a single dotmatrix form field}
    PFieldNode     = ^TFieldNode;
    TFieldNode     = OBJECT(DoubleListNode)
                         CONSTRUCTOR Init(FName : STRING; X, Y : REAL; Just : JustT; Font : FontTypeT; Bold, ITALIC : BOOLEAN);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetName : STRING;
                         FUNCTION GetVal : STRING;
                         FUNCTION GetX  : REAL;
                         FUNCTION GetY  : REAL;
                         PROCEDURE Print(PRT : PDotMatrix);
                         PROCEDURE SetVal(Strg : STRING);

                     PRIVATE

                         MyFname        : STRING[20];
                         MyVal          : StringPtr;
                         MyX,
                         MyY            : REAL;
                         MyJust         : JustT;
                         MyFont         : FontTypeT;
                         MyBold,
                         MyItalic       : BOOLEAN;
                     END;

    {list of all fields on form}
    PDMFieldList   = ^TDMFieldList;
    TDMFieldList   = OBJECT(SortListT)
                         CONSTRUCTOR Init(FName : PathStr; PRT : PDotMatrix);
                         {add a value to a named field}
                         FUNCTION AddVal(N, V : STRING) : BOOLEAN;
                             {print the form}
                         PROCEDURE Print;
                     PRIVATE
                         MyPrt          : PDotMatrix;
                         PageLen        : BYTE;
                         XOffset,
                         Yoffset        : REAL;

                         FUNCTION ParseLine(Strg : STRING) : BOOLEAN;
                         FUNCTION ParseJust(Strg : STRING) : JustT;
                         FUNCTION ParseFont(Strg : STRING) : FontTypeT;
                         FUNCTION ParseBool(Strg : STRING) : BOOLEAN;
                     END;

IMPLEMENTATION
CONST
    HPI            = 360.0;       {X}
    HPMAX          = $FFFF;

    VPI            = 180.0;       {Y}
    VPMAX          = $FF;

    {------------}


    {move the printhead to an absolute position on the x axis}
    FUNCTION TDotMatrix.PrnGotoX(CONST X : REAL) : BOOLEAN;
    VAR
        Delta          : REAL;
        Strg           : STRING;
    BEGIN
        Delta := X;
        Delta := Delta * HPI;
        Strg := '';
        PrnGotoX := TRUE;
        IF Delta > 0 THEN BEGIN
            WHILE Delta >= 0 DO BEGIN
                IF Delta <= HPMAX THEN BEGIN
                    Strg := #27'$' + CHAR(ROUND(Delta) MOD 255) + CHAR(ROUND(Delta) DIV 255);
                    PrnGotoX := PutStr(Strg);
                    BREAK;
                END
                ELSE BEGIN
                    Strg := #27'$' + CHAR($FF) + CHAR($FF);
                    PrnGotoX := PutStr(Strg);
                    Delta := Delta - VPMAX;
                END;
            END;
        END;
        CurCol := X;
    END;

    {------------}

    PROCEDURE TDotMatrix.EOJ;
    BEGIN
        PutStr(^L);
    END;

    {------------}

    {move the printhead to an absolute position on the yaxis}
    {this method is very much a state machine that is supposed to track   }
    {the real position of the dot matrix print head.  It is very easy to  }
    {screw this up if lines wrap, or control codes are sent to the printer}
    FUNCTION TDotMatrix.PrnGotoY(CONST Y : REAL) : BOOLEAN;
    VAR
        Delta          : REAL;
        Strg           : STRING;
    BEGIN
        IF ABS(Y - CurRow) < 0.001 THEN
            EXIT;

        Delta := Y - CurRow;
        Delta := Delta * VPI;
        Strg := '';
        PrnGotoY := FALSE;
        IF Delta > 0 THEN BEGIN
            {move paper forewards}
            WHILE Delta >= 0 DO BEGIN
                IF Delta <= VPMAX THEN BEGIN
                    Strg := ' '#27'J' + CHAR(ROUND(Delta));
                    PrnGotoY := PutStr(Strg);
                    BREAK;
                END
                ELSE BEGIN
                    Strg := ' '#27'J' + CHAR(VPMAX);
                    PrnGotoY := PutStr(Strg);
                    Delta := Delta - VPMAX;
                END;
            END;
        END
        ELSE BEGIN
            {move paper backwards}
            WHILE Delta < 0 DO BEGIN
                IF ABS(Delta) <= VPMAX THEN BEGIN
                    Strg := ' '#27'j' + CHAR(ROUND(Delta));
                    PrnGotoY := PutStr(Strg);
                    BREAK;
                END
                ELSE BEGIN
                    Strg := ' '#27'j' + CHAR(VPMAX);
                    PrnGotoY := PutStr(Strg);
                    Delta := Delta + VPMAX;
                END;
            END;
        END;
        CurRow := Y;
    END;

    {------------}

    FUNCTION TDotMatrix.PrnGotoXY(CONST X, Y : REAL) : BOOLEAN;
    BEGIN
        PrnGotoXY := FALSE;
        IF NOT PrnGotoY(Y) THEN
            EXIT;
        PrnGotoXY := PrnGotoX(X);
    END;

    {------------}

    CONSTRUCTOR TDotMatrix.Init(PrnInfo        : TPrnCfg;
                                VAR MyCOP      : CylonP;
                                Mode           : TxtGraf);
    BEGIN
        IF NOT InitPrim(PrnInfo, MyCOP, Mode) THEN
            FAIL;
        GrafDriveInited := FALSE;
        CurRow := 0.0;
    END;

    {------------}

    {instantiate a single field}
    CONSTRUCTOR TFieldNode.Init(FName : STRING; X, Y : REAL; Just : JustT; Font : FontTypeT; Bold, ITALIC : BOOLEAN);
    BEGIN
        InitStatus := 0;
        MyFname := FName;
        MyVal := NIL;
        MyX := X;
        MyY := Y;
        MyJust := Just;
        MyFont := Font;
        MyBold := Bold;
        MyItalic := ITALIC;
    END;

    {------------}

    {blow off a field}
    DESTRUCTOR TFieldNode.Done;
    BEGIN
        IF MyVal <> NIL THEN
            DisposeString(MyVal);
    END;

    {------------}

    {returns the name of the field}
    FUNCTION TFieldNode.GetName : STRING;
    BEGIN
        GetName := MyFname;
    END;

    {------------}

    {returns the current field value, if any}
    FUNCTION TFieldNode.GetVal : STRING;
    BEGIN
        GetVal := '';
        IF MyVal <> NIL THEN
            GetVal := StringFromHeap(MyVal);
    END;

    {------------}

    {change or init the field value}
    PROCEDURE TFieldNode.SetVal(Strg : STRING);
    BEGIN
        IF MyVal <> NIL THEN
            DisposeString(MyVal);
        MyVal := StringToHeap(Strg);
    END;

    {------------}

    {return the y position of the field}
    FUNCTION TFieldNode.GetY : REAL;
    BEGIN
        GetY := MyY;
    END;

    {------------}

    {return the x position of the field}
    FUNCTION TFieldNode.GetX : REAL;
    BEGIN
        GetX := MyX;
    END;

    {------------}

    {print this field}
    PROCEDURE TFieldNode.Print(PRT : PDotMatrix);
    VAR
        Width          : REAL;
        Strg           : STRING;
        X,
        Y              : REAL;
    BEGIN
        Strg := GetVal;
        Width := LENGTH(Strg) * 0.0833;
        {calculate the justification}
        CASE MyJust OF
            ELEFT :
                PRT^.PrnGotoXY(MyX, MyY);
            ERIGHT :
                PRT^.PrnGotoXY(MyX - Width, MyY);
            ECENTER :
                PRT^.PrnGotoXY(MyX - (Width / 2.0), MyY);
        END;
        PRT^.PutStr(Strg);
    END;

    {------------}

    {node comparitor to facilitate quicksort.  Sort first by the y-axis position}
    {then do tie-breaker sort by the x-axis position, if necessary}
    FUNCTION SortByY(DNP1, DNP2 : DoubleNodePtr; Dir : SortDir) : CompareType; FAR;
        FUNCTION COMP(X1, X2, Y1, Y2 : REAL) : CompareType;
        BEGIN
            IF Y1 > Y2 THEN
                COMP := Greater
            ELSE
                IF Y1 < Y2 THEN
                    COMP := Less
            ELSE BEGIN
                {y-axis was equal}
                {tie breaker on x axis}
                IF X1 > X2 THEN
                    COMP := Greater
                ELSE
                    IF X1 < X2 THEN
                        COMP := Less
                ELSE
                    COMP := EQUAL;
            END;
        END;
    BEGIN

        IF Dir = ASCENDING THEN
            SortByY := COMP(PFieldNode(DNP1)^.GetX,
                            PFieldNode(DNP2)^.GetX,
                            PFieldNode(DNP1)^.GetY,
                            PFieldNode(DNP2)^.GetY)
        ELSE
            SortByY := COMP(PFieldNode(DNP2)^.GetX,
                            PFieldNode(DNP1)^.GetX,
                            PFieldNode(DNP2)^.GetY,
                            PFieldNode(DNP1)^.GetY);

    END;

    {------------}

    {open the fieldlist file, parse it and build a list of locations/names}
    CONSTRUCTOR TDMFieldList.Init(FName : PathStr; PRT : PDotMatrix);
    VAR
        T              : TEXT;
        Strg           : STRING;
        LineNum        : LONGINT;
    BEGIN
        MyPrt := PRT;
        LineNum := 0;
        XOffset := 0.0;
        Yoffset := 0.0;
        PageLen := 14;

        IF NOT InitPrim(SortByY, ASCENDING) THEN
            FAIL;

        ASSIGN(T, FName);
        {$I-}
        System.RESET(T);
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN
            FAIL;
        {$I+}
        WHILE NOT EOF(T) DO BEGIN
            READLN(T, Strg);
            INC(LineNum);
            Strg := Trim(Strg);
            IF LENGTH(Strg) > 0 THEN BEGIN
                CASE Strg[1] OF
                    ';',
                    '*' : ;
                    ELSE
                        IF NOT ParseLine(Strg) THEN
                            DispErrorDeluxe('Problem in ' + FName, 'Line: ' + Long2Str(LineNum), TRUE, Iam);
                END;              {case}
            END;
        END;
        CLOSE(T);
    END;

    {------------}

    {stuff a value into a field name node}
    FUNCTION TDMFieldList.AddVal(N, V : STRING) : BOOLEAN;
    VAR
        Pfn            : PFieldNode;
    BEGIN
        Pfn := PFieldNode(Head);
        AddVal := FALSE;
        WHILE Pfn <> NIL DO BEGIN
            IF CompUCString(Pfn^.GetName, N) = EQUAL THEN BEGIN
                Pfn^.SetVal(V);
                AddVal := TRUE;
                EXIT;
            END;
            Pfn := PFieldNode(Next(Pfn));
        END;
    END;

    {------------}

    {print the form}
    PROCEDURE TDMFieldList.Print;
    VAR
        Pfn            : PFieldNode;
    BEGIN
        MyPrt^.PutStr(#27'C'#0 + CHR(PageLen));

        {first, we sort the xy locations for best printer efficiency}
        SortList;
        {get the first field}
        Pfn := PFieldNode(Head);
        WHILE Pfn <> NIL DO BEGIN
            {print the field}
            Pfn^.Print(MyPrt);
            {move to the next field, if any}
            Pfn := PFieldNode(Next(Pfn));
        END;
        {MyPRT^.EOJ;}
    END;

    {------------}

    {parse justification token from fieldlist file}
    FUNCTION TDMFieldList.ParseJust(Strg : STRING) : JustT;
    VAR
        J              : JustT;
    BEGIN
        Strg := StUpCase(Strg);
        J := ELEFT;
        FOR J := LOW(J) TO HIGH(J) DO
            IF StUpCase(JustHNames[J]) = Strg THEN
                ParseJust := J;
    END;

    {------------}

    {parse font token from fieldlist file}
    FUNCTION TDMFieldList.ParseFont(Strg : STRING) : FontTypeT;
    VAR
        J              : FontTypeT;
    BEGIN
        Strg := StUpCase(Strg);
        J := LOW(FontTypeT);
        FOR J := LOW(FontTypeT) TO HIGH(FontTypeT) DO
            IF StUpCase(FontNames[J]) = Strg THEN
                ParseFont := J;
    END;

    {------------}

    {parse boolean token from fieldlist file}
    FUNCTION TDMFieldList.ParseBool(Strg : STRING) : BOOLEAN;
    BEGIN
        ParseBool := StUpCase(Trim(Strg)) = 'TRUE';
    END;

    {------------}

    {parse a line from fieldlist file}
    FUNCTION TDMFieldList.ParseLine(Strg : STRING) : BOOLEAN;
    VAR
        Pfn            : PFieldNode;
        S              : STRING;
        X,
        Y              : REAL;
        Just           : JustT;
        Font           : FontTypeT;
        Bold,
        ITALIC         : BOOLEAN;
    BEGIN
        ParseLine := FALSE;
        Strg := Substitute(Strg, #9, ' ');

        IF NOT Str2Real(ExtractWord(2, Strg, [' ']), X) THEN
            EXIT;

        IF NOT Str2Real(ExtractWord(3, Strg, [' ']), Y) THEN BEGIN
            {if no column 3, then it must be an offset value}
            S := StUpCase(ExtractWord(1, Strg, [' ']));
            IF (S = 'OFFSETX') THEN
                XOffset := X;
            IF (S = 'OFFSETY') THEN
                Yoffset := X;
            {$R-}
            IF (S = 'PAGELEN') THEN
                PageLen := ROUND(X);
            {$R+}
            ParseLine := TRUE;
            EXIT;
        END;

        Just := ParseJust(ExtractWord(4, Strg, [' ']));
        Font := ParseFont(ExtractWord(5, Strg, [' ']));
        Bold := ParseBool(ExtractWord(6, Strg, [' ']));
        ITALIC := ParseBool(ExtractWord(7, Strg, [' ']));

        {instantiate a field node}
        NEW(Pfn, Init(ExtractWord(1, Strg, [' ']),
                      X + XOffset, Y + Yoffset,
                      Just,
                      Font,
                      Bold,
                      ITALIC));

        IF Pfn = NIL THEN
            EXIT;

        {append the node to the end of the list - we will sort the list}
        {later on}
        APPEND(Pfn);
        ParseLine := TRUE;
    END;

    {------------}


END.
    {------------}
    {------------}
