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
* a field oriented forms printer object that
* implements a field name/coordinates file parser and a filler-inner.
*
* ~notesend~
*
***************************************************************************

}
{$A+,B-,D+,E+,F+,G+,I+,L+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT DGXYFORM;

INTERFACE
USES
    DGPRINT,
    GLOBTYPE,
    LJVAR,
    OpRoot,
    OpString,
    UTSORT;

TYPE
    {holds a single dotmatrix form field}
    PFieldNode     = ^TFieldNode;
    TFieldNode     = OBJECT(DoubleListNode)
                         CONSTRUCTOR Init(FName : STRING; X, Y : REAL; Just : JustT; Font : FontTypeT);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetName : STRING;
                         FUNCTION GetVal : STRING;
                         FUNCTION GetX  : REAL;
                         FUNCTION GetY  : REAL;
                         PROCEDURE Print(PRT : PPrinter);
                         PROCEDURE SetVal(Strg : STRING);

                     PRIVATE

                         MyFName        : STRING[20];
                         MyVal          : StringPtr;
                         MyX,
                         MyY            : REAL;
                         MyJust         : JustT;
                         MyFont         : FontTypeT;
                     END;

    {list of all fields on form}
    PXYFieldList   = ^TXYFieldList;
    TXYFieldList   = OBJECT(SortListT)
                         CONSTRUCTOR Init(FName : STRING; PRT : PPrinter);
                         {add a value to a named field}
                         FUNCTION AddVal(N, V : STRING) : BOOLEAN;
                             {print the form}
                         PROCEDURE Print;
                         DESTRUCTOR Done; VIRTUAL;
                     PRIVATE
                         MyPrt          : PPrinter;
                         XOffset,
                         Yoffset        : REAL;
                         LineNumber     : LONGINT;
                         MyFName        : STRING;

                         FUNCTION ParseLine(Strg : STRING) : BOOLEAN;
                         FUNCTION ParseJust(Strg : STRING) : JustT;
                         FUNCTION ParseFont(Strg : STRING) : FontTypeT;
                         FUNCTION ParseBool(Strg : STRING) : BOOLEAN;
                         PROCEDURE ParseError(Strg : STRING);
                     END;

IMPLEMENTATION
USES
    KERROR,
    UTIAM;

    {------------}

    {instantiate a single field}
    CONSTRUCTOR TFieldNode.Init(FName : STRING; X, Y : REAL; Just : JustT; Font : FontTypeT);
    BEGIN
        InitStatus := 0;
        MyFName := FName;
        MyVal := NIL;
        MyX := X;
        MyY := Y;
        MyJust := Just;
        MyFont := Font;
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
        GetName := MyFName;
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
    PROCEDURE TFieldNode.Print(PRT : PPrinter);
    VAR
        Width          : REAL;
        Strg           : STRING;
        X,
        Y              : REAL;
    BEGIN
        Strg := GetVal;

        PRT^.SelectFont(MyFont);

        Width := PRT^.ComputeStringWidthF(Strg, MyFont, CtrlSkip);

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
    CONSTRUCTOR TXYFieldList.Init(FName : STRING; PRT : PPrinter);
    VAR
        T              : TEXT;
        Strg           : STRING;
    BEGIN
        MyPrt := PRT;
        LineNumber := 0;
        XOffset := 0.0;
        Yoffset := 0.0;
        MyFName := FName;

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
            INC(LineNumber);
            Strg := Trim(Strg);
            IF LENGTH(Strg) > 0 THEN BEGIN
                CASE Strg[1] OF
                    ';',
                    '*' : ;
                    ELSE
                        IF NOT ParseLine(Strg) THEN
                            DispErrorDeluxe('Problem in ' + FName, 'Line: ' + Long2Str(LineNumber), TRUE, Iam);
                END;              {case}
            END;
        END;
        CLOSE(T);
    END;

    {------------}

    DESTRUCTOR TXYFieldList.Done;
    BEGIN
        MyPrt^.ResetPrn;          {reset form length}
        INHERITED Done;
    END;

    {------------}

    {stuff a value into a field name node}
    FUNCTION TXYFieldList.AddVal(N, V : STRING) : BOOLEAN;
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
    PROCEDURE TXYFieldList.Print;
    VAR
        Pfn            : PFieldNode;
    BEGIN
        {first, we sort the xy locations for best printer efficiency}
        SortList;

        MyPrt^.SelectFont(fCourier);

        {get the first field}
        Pfn := PFieldNode(Head);
        WHILE Pfn <> NIL DO BEGIN
            {print the field}
            Pfn^.Print(MyPrt);
            {move to the next field, if any}
            Pfn := PFieldNode(Next(Pfn));
        END;
        MyPrt^.FormFeed;
    END;

    {------------}

    PROCEDURE TXYFieldList.ParseError(Strg : STRING);
    BEGIN
        DispErrorDeluxe('Invalid line in: ' + MyFName + ' Line:' + Long2Str(LineNumber), Strg, TRUE, Iam);
    END;

    {------------}

    {parse justification token from fieldlist file}
    FUNCTION TXYFieldList.ParseJust(Strg : STRING) : JustT;
    VAR
        J              : JustT;
    BEGIN
        Strg := StUpCase(Strg);
        ParseJust := ELEFT;
        FOR J := LOW(J) TO HIGH(J) DO
            IF StUpCase(JustHNames[J]) = Strg THEN BEGIN
                ParseJust := J;
                EXIT;
            END;
        ParseError(Strg);
    END;

    {------------}

    {parse font token from fieldlist file}
    FUNCTION TXYFieldList.ParseFont(Strg : STRING) : FontTypeT;
    VAR
        J              : FontTypeT;
    BEGIN
        Strg := StUpCase(Strg);
        ParseFont := LOW(FontTypeT);
        FOR J := LOW(FontTypeT) TO HIGH(FontTypeT) DO
            IF StUpCase(FontNames[J]) = Strg THEN BEGIN
                ParseFont := J;
                EXIT;
            END;
        ParseError(Strg);
    END;

    {------------}

    {parse boolean token from fieldlist file}
    FUNCTION TXYFieldList.ParseBool(Strg : STRING) : BOOLEAN;
    BEGIN
        ParseBool := StUpCase(Trim(Strg)) = 'TRUE';
    END;

    {------------}

    {parse a line from fieldlist file}
    FUNCTION TXYFieldList.ParseLine(Strg : STRING) : BOOLEAN;
    VAR
        Pfn            : PFieldNode;
        S              : STRING;
        X,
        Y              : REAL;
        Just           : JustT;
        Font           : FontTypeT;
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
            IF (S = 'FORMLEN') THEN
                MyPrt^.SetFormLen(TRUNC(X));
            ParseLine := TRUE;
            EXIT;
        END;

        Just := ParseJust(ExtractWord(4, Strg, [' ']));
        Font := ParseFont(ExtractWord(5, Strg, [' ']));

        {instantiate a field node}
        NEW(Pfn, Init(ExtractWord(1, Strg, [' ']),
                      X + XOffset, Y + Yoffset,
                      Just,
                      Font));

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
