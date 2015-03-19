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
* This unit uses template files, using MAT or MAV syntax.  The templates
* are used to fix column and row positions for fields within a table or page.
* Using method calls, you fill in each desired field value, and then ask this
* object to print the table.  Matrix will print any boilerplate text in the
* template, as well as the field values.  If no field value is supplied, then
* Matrix will not print the field.  If a field value is supplied for a field
* name that does not exist in the template, then Matrix will ignore the value.
*
* Each field can have a different font and color.  Each line can have a
* different graybar density.
*
* Fields within a MAT file are delineated and positioned by @name@ tokens.
* Each name must be unique within a MAT file, or the first one encountered
* will be used.
*
* Matrix supports simple superscripting of field values.  Note that all fields
* are mapped to a 10 point courier grid over the table.  This is to allow the
* printing of IBM block graphics characters, with any sort of proportional
* font text inside the lines and boxes.  The non proportional grid forces
* columns to line up properly, even if a proprotional font is used.
*
* MAV syntax:
*
* a '>' in column 1 indicates a fixed line that has to appear in the output
*
* a '<' in column 1 indicates a line that will not appear in the output if
*    there are no filled in fields in the line.
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
}

{$A+,B-,E-,F+,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT Matrix;

INTERFACE
USES
    GLOBTYPE,
    DGPRINT,
    Dos,
    LJVAR,
    OpRoot,
    OpString;

CONST
    HorizChar      = 'W';
    BlockWidth     = 0.083333333;

TYPE
    {holds a single field value}
    ValNodeP       = ^ValNodeT;
    ValNodeT       = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(Name : STRING; Width, Start, Stop : BYTE; P : PPrinter);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetName : STRING;
                         PROCEDURE SetVal(V              : STRING;
                                          FontID         : FontTypeT;
                                          Just           : JustT;
                                          XOfst, YOfst   : REAL;
                                          Color          : TPrnColors);
                         PROCEDURE ConcatFootnote(V : STRING; FontID : FontTypeT);
                         FUNCTION GetVal(VAR Start, YOfst : REAL; VAR FontID : FontTypeT; VAR Color : TPrnColors) : STRING;
                         FUNCTION GetFootNote(VAR FontID : FontTypeT) : STRING;
                     PRIVATE
                         MyXOfst,
                         MyYOfst        : REAL;
                         MyJust         : JustT; {justification}
                         MaxValWidth, {field width}
                         StartPos       : REAL; {x}
                         MyName,  {fieldname}
                         MyFootNote, {footnote if any}
                         MyVal          : StringPtr; {field value}
                         MyFootNoteFID, {footnote font}
                         MyFontID       : FontTypeT; {field font}
                         MyPR           : PPrinter; {printer to use}
                         MyColor        : TPrnColors;
                     END;

    {-------------}
    PrintStatT     = (EOK, EVSKIP, EERROR);

    {holds a complete line with all fields}
    LineNodeP      = ^LineNodeT;
    LineNodeT      = OBJECT(SingleListNode)
                         {init the object, find all field locations}
                         CONSTRUCTOR Init(L, SP : STRING; P : PPrinter);
                         {kill the line plus all the valnodes}
                         DESTRUCTOR Done; VIRTUAL;
                             {print this line - fixed format}
                         PROCEDURE PrintLine(XOfst, XFudge, YFudge : REAL);
                             {print this line - variable format}
                         FUNCTION VPrintLine(XOfst, XFudge, YFudge, MySpacing : REAL; VAR LastStat : PrintStatT) : PrintStatT;
                             {add a named field value}
                         FUNCTION AddVal(N, V           : STRING;
                                         FontID         : FontTypeT;
                                         Just           : JustT;
                                         XOfst, YOfst, PctGray : REAL;
                                         Color          : TPrnColors) : BOOLEAN;
                             {append a footnote to the named field}
                         FUNCTION ConcatFootnote(N, V : STRING; FontID : FontTypeT) : BOOLEAN;

                         FUNCTION IsVar : BOOLEAN;
                         FUNCTION LineWillPrint : BOOLEAN;
                         PROCEDURE InhibitSpacer;
                         FUNCTION ChangeSpacer(N, SP : STRING) : BOOLEAN;
                     PRIVATE
                             {line darkness}
                         MyGray,
                             {extent of line}
                         MyWidth        : REAL;
                             {list of fields and values}
                         ValList        : SingleListPtr;
                             {boilerplate stuff on this line}
                         MyLine,
                         MySpacer       : StringPtr;
                             {printer to use}
                         MyPR           : PPrinter;
                             {has filled-in fields on line}
                         LiveVals,
                             {is a variable format line?}
                         Variable       : BOOLEAN;
                     END;


    {-------------}

    {fixed size box with sides}

    LineListP      = ^LineListT;
    LineListT      = OBJECT(SingleList)
                         CONSTRUCTOR Init(FName          : PathStr;

                                          XOfst,
                                          YOfst,

                                          XBoxFudge,
                                          YBoxFudge      : REAL;
                                          SP             : STRING;
                                          P              : PPrinter);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION AddLine(L, SP : STRING) : BOOLEAN;
                         FUNCTION AddVal(N, V : STRING; FontID : FontTypeT; Just : JustT) : BOOLEAN;
                         FUNCTION AddGrayBarVal(N, V           : STRING;
                                                FontID         : FontTypeT;
                                                Just           : JustT;
                                                PctGray        : REAL) : BOOLEAN;
                         FUNCTION AddValOffset(N, V           : STRING;
                                               FontID         : FontTypeT;
                                               Just           : JustT;
                                               XOfst, YOfst   : REAL) : BOOLEAN;
                             {color versions of above methods}
                         FUNCTION CAddVal(N, V           : STRING;
                                          FontID         : FontTypeT;
                                          Just           : JustT;
                                          Color          : TPrnColors) : BOOLEAN;
                         FUNCTION CAddGrayBarVal(N, V           : STRING;
                                                 FontID         : FontTypeT;
                                                 Just           : JustT;
                                                 PctGray        : REAL;
                                                 Color          : TPrnColors) : BOOLEAN;
                         FUNCTION CAddValOffset(N, V           : STRING;
                                                FontID         : FontTypeT;
                                                Just           : JustT;
                                                XOfst, YOfst   : REAL;
                                                Color          : TPrnColors) : BOOLEAN;
                         FUNCTION ChangeSpacer(N, SP : STRING) : BOOLEAN;
                         FUNCTION ConcatFootnote(N, V : STRING; FontID : FontTypeT) : BOOLEAN;
                         FUNCTION Print : BOOLEAN;
                         FUNCTION CalcBotPos : REAL; VIRTUAL;
                     PRIVATE
                         MyXBoxFudge,
                         MyYBoxFudge,
                         MyXOfst,
                         MyYOfst        : REAL;
                         MySpacer       : STRING;
                         MyPR           : PPrinter;
                     END;

    {-------------}

    {variable height box with no sides.  Horiz lines fit char height}

    VlineListP     = ^VlineListT;
    VlineListT     = OBJECT(LineListT)
                         CONSTRUCTOR Init(FName          : PathStr;
                                          XOfst, YOfst,
                                          XBoxFudge, YBoxFudge,
                                          Spacing        : REAL;
                                          HSpacer        : STRING;
                                          InhibitLastItemSpacer : BOOLEAN;
                                          P              : PPrinter);
                         FUNCTION Print : BOOLEAN;
                         FUNCTION CalcBotPos : REAL; VIRTUAL;
                     PRIVATE

                         MySpacing      : REAL;
                         MyHSpacer      : STRING;
                         InhibitLast    : BOOLEAN;
                     END;


    {-------------}

IMPLEMENTATION

USES
    KERROR,
    UTIAM;

    CONSTRUCTOR ValNodeT.Init(Name : STRING; Width, Start, Stop : BYTE; P : PPrinter);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        MyJust := ELEFT;
        StartPos := BlockWidth * (Start - 1);
        MyName := StringToHeap(Name);
        MaxValWidth := BlockWidth * Width;
        IF (MyName = NIL) AND (LENGTH(Name) > 0) THEN
            FAIL;
        MyVal := NIL;
        MyFontID := fLinePrint;
        MyFootNoteFID := fLinePrint;
        MyFootNote := NIL;
        MyXOfst := 0.0;
        MyYOfst := 0.0;
        MyPR := P;
        MyColor := tpcBLACK;
    END;

    {-------------}

    DESTRUCTOR ValNodeT.Done;
    BEGIN
        DisposeString(MyName);
        DisposeString(MyFootNote);
        DisposeString(MyVal);
        MyName := NIL;
        MyVal := NIL;
    END;

    {-------------}

    FUNCTION ValNodeT.GetName : STRING;
    BEGIN
        GetName := Trim(StringFromHeap(MyName));
    END;

    {-------------}

    FUNCTION ValNodeT.GetFootNote(VAR FontID : FontTypeT) : STRING;
    BEGIN
        GetFootNote := '';
        GetFootNote := Trim(StringFromHeap(MyFootNote));
        FontID := MyFootNoteFID;
    END;

    {-------------}

    PROCEDURE ValNodeT.SetVal(V : STRING; FontID : FontTypeT; Just : JustT; XOfst, YOfst : REAL; Color : TPrnColors);
    BEGIN
        IF MyVal <> NIL THEN
            DisposeString(MyVal);
        MyJust := Just;
        IF Just <> ESPACEPAD THEN {using spaces to pad value?}
            V := Trim(V);
        MyXOfst := XOfst;
        MyYOfst := YOfst;
        MyVal := StringToHeap(V);
        MyFontID := FontID;
        CASE Just OF
            ESPACEPAD,
            ELEFT : ;
            ECENTER :
                StartPos := StartPos +
                            ((MaxValWidth - MyPR^.ComputeStringWidthF(V, FontID, CtrlSkip)) / 2.0);
            ERIGHT :
                StartPos := StartPos + MaxValWidth - MyPR^.ComputeStringWidthF(V, FontID, CtrlSkip);
        END;
        MyColor := Color;
    END;

    {-------------}

    PROCEDURE ValNodeT.ConcatFootnote(V : STRING; FontID : FontTypeT);
    BEGIN
        IF MyFootNote <> NIL THEN
            DisposeString(MyFootNote);
        MyFootNote := StringToHeap(V);
        MyFootNoteFID := FontID;
    END;

    {-------------}

    FUNCTION ValNodeT.GetVal(VAR Start, YOfst : REAL; VAR FontID : FontTypeT; VAR Color : TPrnColors) : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        Start := StartPos + MyXOfst;
        YOfst := MyYOfst;
        Strg := StringFromHeap(MyVal);
        IF MyJust = ESPACEPAD THEN
            GetVal := Strg
        ELSE
            GetVal := Trim(Strg);
        FontID := MyFontID;
        Color := MyColor;
    END;

    {-------------}

    CONSTRUCTOR LineNodeT.Init(L, SP : STRING; P : PPrinter);
    VAR
        Strg           : STRING;
        CPos,
        StartPos,
        I              : BYTE;
        InDelim        : BOOLEAN;
        VNP            : ValNodeP;
    BEGIN
        MyPR := P;
        MySpacer := NIL;
        MyWidth := 0.0;
        MyGray := 0.0;
        NEW(ValList, Init);
        IF ValList = NIL THEN
            FAIL;
        LiveVals := FALSE;
        Variable := (POS('<', L) = 1);
        IF Variable OR (POS('>', L) = 1) THEN
            DELETE(L, 1, 1);
        CPos := POS('@', L);
        IF CPos = 0 THEN BEGIN
            MyLine := StringToHeap(L);
            EXIT;
        END;
        IF Variable THEN
            MySpacer := StringToHeap(SP);
        InDelim := FALSE;
        Strg := '';
        {scan line for field locations}
        FOR I := 1 TO LENGTH(L) DO BEGIN
            CASE L[I] OF
                '@' :
                    BEGIN
                        L[I] := ' ';
                        InDelim := NOT InDelim;
                        IF InDelim = TRUE THEN BEGIN
                            Strg := '';
                            StartPos := I;
                        END
                        ELSE BEGIN
                            Strg := Strg + '  ';
                            NEW(VNP, Init(Strg, LENGTH(Strg), StartPos, I, MyPR));
                            ValList^.APPEND(VNP);
                            MyWidth := I * BlockWidth;
                            Strg := '';

                        END;
                    END;
                ELSE BEGIN
                    Strg := Strg + L[I];
                    IF InDelim THEN
                        L[I] := ' ';
                END;
            END;                  {CASE}
        END;
        MyLine := StringToHeap(L);
    END;

    {-------------}

    DESTRUCTOR LineNodeT.Done;
    BEGIN
        DISPOSE(ValList, Done);
        DisposeString(MyLine);
        DisposeString(MySpacer);
        INHERITED Done;
    END;

    {-------------}

    {Print a MAT line and all the fields on it}
    PROCEDURE LineNodeT.PrintLine(XOfst, XFudge, YFudge : REAL);
    VAR
        BarHyt,
        LineYLoc,
        FieldYOfst,
        StartPos       : REAL;
        VNP            : ValNodeP;
        S,
        Strg           : STRING;
        I              : BYTE;
        FontID         : FontTypeT;
        Color          : TPrnColors;
    BEGIN
        LineYLoc := MyPR^.CurRow; {save y loc so we can jigger it around}

        {get the first field node}
        VNP := ValNodeP(ValList^.Head);
        {get the boilerplate}
        Strg := StringFromHeap(MyLine);

        {is this a pagebreak?}
        IF Strg[1] = #12 THEN BEGIN
            {do the formfeed - fields are not valid on a pagebreak line}
            MyPR^.DoPageNumAndFF;
            EXIT;
        END;

        MyPR^.SelectFont(fLinePrint);
        MyPR^.PrnGotoX(XOfst + XFudge);

        IF ABS(YFudge) > 0.0 THEN
            MyPR^.PrnAdvanceY(YFudge);

        {print the boilerplate}
        MyPR^.PutStr(Strg);
        IF (MyGray > 0.0) THEN BEGIN
            BarHyt := MyPR^.ljActiveFont^.GetLineSpacing; {zzzz}
            MyPR^.DrawRasterBox(XOfst,
                                LineYLoc - (BarHyt),
                                FALSE,
                                FALSE,
                                MyGray,
                                BarHyt { * 1.3} ,
                                MyWidth);
            MyPR^.PrnGotoXY(XOfst, LineYLoc);

        END;

        IF ABS(YFudge) > 0.0 THEN
            MyPR^.PrnAdvanceY(- YFudge);

        MyPR^.SelectFont(fMain);

        {get the first field node}
        VNP := ValNodeP(ValList^.Head);


        WHILE VNP <> NIL DO BEGIN
            Strg := VNP^.GetVal(StartPos, FieldYOfst, FontID, Color);

            IF ABS(FieldYOfst) > 0.001 THEN
                MyPR^.PrnAdvanceY(FieldYOfst);

            {move to field position}
            MyPR^.PrnGotoX(XOfst + StartPos);
            MyPR^.SelectFont(FontID);
            MyPR^.SelectTextColor(Color);
            MyPR^.PutStr(Strg);
            IF ABS(FieldYOfst) > 0.001 THEN
                MyPR^.PrnAdvanceY(- FieldYOfst);
            Strg := VNP^.GetFootNote(FontID);
            IF Strg <> '' THEN BEGIN
                MyPR^.SelectFont(FontID);
                {superscript}
                MyPR^.PrnAdvanceY(MyPR^.GetLineSpacing * - 0.4);
                MyPR^.PutStr(Strg);
                {return from superscript}
                MyPR^.PrnAdvanceY(MyPR^.GetLineSpacing * 0.4);

                MyPR^.SelectFont(fMain);
            END;
            MyPR^.SelectTextColor(tpcBLACK);
            VNP := ValNodeP(ValList^.Next(VNP));
        END;

        MyPR^.SelectFont(fLinePrint);
        MyPR^.PrnAdvanceY(MyPR^.ljActiveFont^.GetLineSpacing);
        MyPR^.PrnGotoX(MyPR^.GetLeftMargin);
        MyPR^.SelectTextMonoChrome;
    END;

    {-------------}

    FUNCTION LineNodeT.IsVar : BOOLEAN;
    BEGIN
        IsVar := Variable AND LiveVals;
    END;

    {-------------}

    FUNCTION LineNodeT.LineWillPrint : BOOLEAN;
    BEGIN
        LineWillPrint := (Variable AND LiveVals) OR (NOT Variable);
    END;

    {-------------}

    PROCEDURE LineNodeT.InhibitSpacer;
    BEGIN
        DisposeString(MySpacer);
        MySpacer := NIL;
    END;

    {-------------}

    FUNCTION LineNodeT.ChangeSpacer(N, SP : STRING) : BOOLEAN;
    VAR
        VNP            : ValNodeP;
    BEGIN
        ChangeSpacer := FALSE;
        {get the first field node}
        VNP := ValNodeP(ValList^.Head);
        WHILE VNP <> NIL DO BEGIN
            IF CompUCString(VNP^.GetName, N) = EQUAL THEN BEGIN
                InhibitSpacer;
                IF Variable THEN
                    MySpacer := StringToHeap(SP);
                ChangeSpacer := TRUE;
                EXIT;
            END;
            VNP := ValNodeP(ValList^.Next(VNP));
        END;
    END;

    {-------------}

    FUNCTION LineNodeT.VPrintLine(XOfst, XFudge, YFudge, MySpacing : REAL; VAR LastStat : PrintStatT) : PrintStatT;
    VAR
        LineYLoc,
        BarHyt,
        FieldYOfst,
        StartPos       : REAL;
        VNP            : ValNodeP;
        S,
        Strg           : STRING;
        I              : BYTE;
        FontID         : FontTypeT;
        Color          : TPrnColors;
    BEGIN
        VPrintLine := EVSKIP;
        IF Variable AND (NOT LiveVals) THEN BEGIN
            LastStat := EVSKIP;
            EXIT;
        END;

        VPrintLine := EERROR;
        LineYLoc := MyPR^.CurRow; {save y loc so we can jigger it around}

        {get the first field node}
        VNP := ValNodeP(ValList^.Head);

        {get the boilerplate}
        Strg := StringFromHeap(MyLine);

        {since the boilerplate is always in courier, set the font}
        MyPR^.SelectFont(fLinePrint);
        IF ABS(MySpacing) < 1e-3 THEN
            MySpacing := MyPR^.ljActiveFont^.GetLineSpacing / 2.0;

        {move to upperleft corner of box area}
        MyPR^.PrnGotoX(XOfst + XFudge);

        {fudge the line placement if necessary}
        {*** Note, this is a little dangerous on HPDJ ***}
        {dont get carried away with fudge factors larger than 1/3 inch!}
        IF ABS(YFudge) > 0.0 THEN
            MyPR^.PrnAdvanceY(YFudge);
        MyPR^.PutStr(Strg);

        IF (MyGray > 0.0) THEN BEGIN
            BarHyt := MyPR^.ljActiveFont^.GetLineSpacing;
            MyPR^.DrawRasterBox(XOfst,
                                LineYLoc - (BarHyt),
                                FALSE,
                                FALSE,
                                MyGray,
                                BarHyt { * 1.3} ,
                                MyWidth);
            MyPR^.PrnGotoXY(XOfst, LineYLoc);

        END;

        {now put it back}
        IF ABS(YFudge) > 0.0 THEN
            MyPR^.PrnAdvanceY(- YFudge);

        {set the default font}
        MyPR^.SelectFont(fMain);

        {loop through the fields on this line and print them}
        WHILE VNP <> NIL DO BEGIN
            {get a field value}
            Strg := VNP^.GetVal(StartPos, FieldYOfst, FontID, Color);
            {move the printhead to the correct x-pos}
            MyPR^.PrnGotoX(XOfst + StartPos);
            {change fonts if necessary}
            MyPR^.SelectFont(FontID);
            IF ABS(FieldYOfst) > 0.001 THEN
                MyPR^.PrnAdvanceY(FieldYOfst);
            {print the field value}
            MyPR^.SelectTextColor(Color);
            MyPR^.PutStr(Strg);
            IF ABS(FieldYOfst) > 0.001 THEN
                MyPR^.PrnAdvanceY(- FieldYOfst);
            {check for footnotes}
            Strg := VNP^.GetFootNote(FontID);
            IF Strg <> '' THEN BEGIN
                MyPR^.SelectFont(FontID);
                {superscript}
                MyPR^.PrnAdvanceY(MyPR^.GetLineSpacing * - 0.4);
                MyPR^.PutStr(Strg);
                {return from superscript}
                MyPR^.PrnAdvanceY(MyPR^.GetLineSpacing * 0.4);

                MyPR^.SelectFont(fMain);
            END;
            {bump to the next field on the line}
            VNP := ValNodeP(ValList^.Next(VNP));
        END;

        IF MySpacer <> NIL THEN BEGIN
            MyPR^.PrnAdvanceY(MySpacing);
            MyPR^.PrnGotoX(MyPR^.GetLeftMargin);
            {get the boilerplate}
            Strg := StringFromHeap(MySpacer);

            {since the boilerplate is always in courier, set the font}
            MyPR^.SelectFont(fLinePrint);

            {move to upperleft corner of box area}
            MyPR^.PrnGotoX(XOfst + XFudge);

            {fudge the line placement if necessary}
            {*** Note, this is a little dangerous on HPDJ ***}
            {dont get carried away with fudge factors larger than 1/3 inch!}
            IF ABS(YFudge) > 0.0 THEN
                MyPR^.PrnAdvanceY(YFudge);
            MyPR^.PutStr(Strg);
            {now put it back}
            IF ABS(YFudge) > 0.0 THEN
                MyPR^.PrnAdvanceY(- YFudge);

            {set the default font}
        END
        ELSE
            MyPR^.PrnAdvanceY(0.05);

        MyPR^.SelectFont(fMain);
        MyPR^.PrnAdvanceY(MySpacing);
        MyPR^.PrnGotoX(MyPR^.GetLeftMargin);
        MyPR^.SelectTextMonoChrome;
        LastStat := EOK;
        VPrintLine := EOK;
    END;

    {-------------}

    FUNCTION LineNodeT.AddVal(N, V           : STRING;
                              FontID         : FontTypeT;
                              Just           : JustT;
                              XOfst, YOfst, PctGray : REAL;
                              Color          : TPrnColors) : BOOLEAN;
    VAR
        VNP            : ValNodeP;
        SP             : BYTE;
    BEGIN
        AddVal := FALSE;
        VNP := ValNodeP(ValList^.Head);
        WHILE VNP <> NIL DO BEGIN
            IF CompUCString(VNP^.GetName, N) = EQUAL THEN BEGIN
                VNP^.SetVal(V, FontID, Just, XOfst, YOfst, Color);
                MyGray := PctGray; {last addval sets this...}
                LiveVals := TRUE;
                AddVal := TRUE;
                EXIT;
            END;
            VNP := ValNodeP(ValList^.Next(VNP));
        END;
    END;

    {-------------}

    FUNCTION LineNodeT.ConcatFootnote(N, V : STRING; FontID : FontTypeT) : BOOLEAN;
    VAR
        VNP            : ValNodeP;
        SP             : BYTE;
    BEGIN
        ConcatFootnote := FALSE;
        VNP := ValNodeP(ValList^.Head);
        WHILE VNP <> NIL DO BEGIN
            IF CompUCString(VNP^.GetName, N) = EQUAL THEN BEGIN
                VNP^.ConcatFootnote(V, FontID);
                ConcatFootnote := TRUE;
                EXIT;
            END;
            VNP := ValNodeP(ValList^.Next(VNP));
        END;
    END;

    {-------------}

    CONSTRUCTOR LineListT.Init(FName          : PathStr;
                               XOfst, YOfst, XBoxFudge, YBoxFudge : REAL;
                               SP             : STRING;
                               P              : PPrinter);
    VAR
        T              : TEXT;
        L              : STRING;
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        MyPR := P;
        ASSIGN(T, FName);
        {$I-}
        System.RESET(T);
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            DispErrorDeluxe('Problem opening ' + FName, ErrorMessage(InitStatus), TRUE, Iam);
            FAIL;
        END;
        WHILE NOT EOF(T) DO BEGIN
            READLN(T, L);
            AddLine(L, SP);
        END;
        CLOSE(T);
        {$I+}
        MyXOfst := XOfst;
        MyYOfst := YOfst;
        MyXBoxFudge := XBoxFudge;
        MyYBoxFudge := YBoxFudge;
    END;

    {-------------}

    FUNCTION LineListT.AddLine(L, SP : STRING) : BOOLEAN;
    VAR
        LNP            : LineNodeP;
    BEGIN
        AddLine := FALSE;
        NEW(LNP, Init(L, SP, MyPR));
        IF LNP = NIL THEN
            EXIT;
        APPEND(LNP);
        AddLine := TRUE;
    END;

    {-------------}

    FUNCTION LineListT.Print : BOOLEAN;
    VAR
        LNP            : LineNodeP;
    BEGIN
        MyPR^.SelectFont(fLinePrint);
        MyPR^.PrnGotoY(MyYOfst);
        LNP := LineNodeP(Head);
        Print := FALSE;
        WHILE LNP <> NIL DO BEGIN
            LNP^.PrintLine(MyXOfst, MyXBoxFudge, MyYBoxFudge);
            LNP := LineNodeP(Next(LNP));
            Print := TRUE;
        END;
        MyPR^.SelectTextColor(tpcBLACK);
    END;

    {-------------}

    FUNCTION LineListT.CalcBotPos : REAL;
    BEGIN
        CalcBotPos := MyPR^.CurRow + (Size * MyPR^.FindFontByID(fLinePrint)^.GetLineSpacing);
    END;

    {-------------}

    FUNCTION LineListT.CAddValOffset(N, V           : STRING;
                                     FontID         : FontTypeT;
                                     Just           : JustT;
                                     XOfst, YOfst   : REAL;
                                     Color          : TPrnColors) : BOOLEAN;
    VAR
        LNP            : LineNodeP;
    BEGIN
        {scan all the lines and nodes and update the named node with the value}
        LNP := LineNodeP(Head);
        CAddValOffset := FALSE;
        WHILE LNP <> NIL DO BEGIN
            IF LNP^.AddVal(N, V, FontID, Just, XOfst, YOfst, 0.0, Color) THEN BEGIN
                CAddValOffset := TRUE;
                EXIT;
            END;
            LNP := LineNodeP(Next(LNP));
        END;
    END;

    {-------------}

    FUNCTION LineListT.AddValOffset(N, V           : STRING;
                                    FontID         : FontTypeT;
                                    Just           : JustT;
                                    XOfst, YOfst   : REAL) : BOOLEAN;
    BEGIN
        AddValOffset := CAddValOffset(N, V, FontID, Just, XOfst, YOfst, tpcBLACK);
    END;

    {-------------}

    FUNCTION LineListT.AddVal(N, V : STRING; FontID : FontTypeT; Just : JustT) : BOOLEAN;
    BEGIN
        AddVal := CAddVal(N, V, FontID, Just, tpcBLACK);
    END;

    {-------------}

    FUNCTION LineListT.CAddVal(N, V : STRING; FontID : FontTypeT; Just : JustT; Color : TPrnColors) : BOOLEAN;
    VAR
        LNP            : LineNodeP;
    BEGIN
        {scan all the lines and nodes and update the named node with the value}
        LNP := LineNodeP(Head);
        CAddVal := FALSE;
        WHILE LNP <> NIL DO BEGIN
            IF LNP^.AddVal(N, V, FontID, Just, 0.0, 0.0, 0.0, Color) THEN BEGIN
                CAddVal := TRUE;
                EXIT;
            END;
            LNP := LineNodeP(Next(LNP));
        END;
    END;

    {-------------}

    FUNCTION LineListT.CAddGrayBarVal(N, V           : STRING;
                                      FontID         : FontTypeT;
                                      Just           : JustT;
                                      PctGray        : REAL;
                                      Color          : TPrnColors) : BOOLEAN;
    VAR
        LNP            : LineNodeP;
    BEGIN
        {scan all the lines and nodes and update the named node with the value}
        LNP := LineNodeP(Head);
        CAddGrayBarVal := FALSE;
        WHILE LNP <> NIL DO BEGIN
            IF LNP^.AddVal(N, V, FontID, Just, 0.0, 0.0, PctGray, Color) THEN BEGIN
                CAddGrayBarVal := TRUE;
                EXIT;
            END;
            LNP := LineNodeP(Next(LNP));
        END;
    END;

    {-------------}

    FUNCTION LineListT.AddGrayBarVal(N, V           : STRING;
                                     FontID         : FontTypeT;
                                     Just           : JustT;
                                     PctGray        : REAL) : BOOLEAN;
    BEGIN
        AddGrayBarVal := CAddGrayBarVal(N, V, FontID, Just, PctGray, tpcBLACK);
    END;

    {-------------}


    FUNCTION LineListT.ChangeSpacer(N, SP : STRING) : BOOLEAN;
    VAR
        LNP            : LineNodeP;
    BEGIN
        {scan all the lines and nodes and update the named node with the value}
        LNP := LineNodeP(Head);
        ChangeSpacer := FALSE;
        WHILE LNP <> NIL DO BEGIN
            IF LNP^.ChangeSpacer(N, SP) THEN BEGIN
                ChangeSpacer := TRUE;
                EXIT;
            END;
            LNP := LineNodeP(Next(LNP));
        END;
    END;

    {-------------}

    FUNCTION LineListT.ConcatFootnote(N, V : STRING; FontID : FontTypeT) : BOOLEAN;
    VAR
        LNP            : LineNodeP;
    BEGIN
        {scan all the lines and nodes and update the named node with the value}
        LNP := LineNodeP(Head);
        ConcatFootnote := FALSE;
        WHILE LNP <> NIL DO BEGIN
            IF LNP^.ConcatFootnote(N, V, FontID) THEN BEGIN
                ConcatFootnote := TRUE;
                EXIT;
            END;
            LNP := LineNodeP(Next(LNP));
        END;
    END;

    {-------------}

    DESTRUCTOR LineListT.Done;
    BEGIN
        MyPR^.SelectFont(fMain);
        INHERITED Done;
    END;

    {-------------}

    CONSTRUCTOR VlineListT.Init(FName          : PathStr;
                                XOfst, YOfst,
                                XBoxFudge, YBoxFudge,
                                Spacing        : REAL;
                                HSpacer        : STRING;
                                InhibitLastItemSpacer : BOOLEAN;
                                P              : PPrinter);
    BEGIN
        IF NOT INHERITED Init(FName, XOfst, YOfst, XBoxFudge, YBoxFudge, HSpacer, P) THEN
            FAIL;
        MySpacing := Spacing;
        MyHSpacer := HSpacer;
        InhibitLast := InhibitLastItemSpacer;
    END;

    {-------------}

    FUNCTION VlineListT.Print : BOOLEAN;
    VAR
        LNP            : LineNodeP;
        Skip,
        Penultimate    : BOOLEAN;
        LastStat       : PrintStatT;
        Ctr,
        LastVar        : WORD;
    BEGIN
        Print := FALSE;

        IF InhibitLast THEN BEGIN
            LastVar := 0;
            Ctr := 0;

            LNP := LineNodeP(Head);
            WHILE LNP <> NIL DO BEGIN
                INC(Ctr);
                IF LineNodeP(LNP)^.IsVar THEN
                    LastVar := Ctr;
                LNP := LineNodeP(Next(LNP));
            END;

            IF LastVar <> 0 THEN
                LineNodeP(Nth(LastVar))^.InhibitSpacer;
        END;
        MyPR^.SelectFont(fLinePrint);
        MyPR^.PrnGotoY(MyYOfst);

        LNP := LineNodeP(Head);
        WHILE LNP <> NIL DO BEGIN
            LNP^.VPrintLine(MyXOfst, MyXBoxFudge, MyYBoxFudge, MySpacing, LastStat);
            LNP := LineNodeP(Next(LNP));
            Print := TRUE;
        END;
    END;

    {-------------}

    FUNCTION VlineListT.CalcBotPos : REAL;
    VAR
        Ct             : WORD;
        LNP            : LineNodeP;
        BP             : REAL;
    BEGIN
        Ct := 0;
        LNP := LineNodeP(Head);
        WHILE LNP <> NIL DO BEGIN
            IF LNP^.LineWillPrint THEN
                INC(Ct);
            LNP := LineNodeP(Next(LNP));
        END;

        BP := MyPR^.CurRow + (Ct * MyPR^.FindFontByID(fLinePrint)^.GetLineSpacing);
        CalcBotPos := BP;
    END;

    {-------------}


END.
    {-------------}
    {-------------}
