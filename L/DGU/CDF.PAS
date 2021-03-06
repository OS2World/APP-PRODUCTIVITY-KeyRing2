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
* Comma delimited file reader/writer objects
*
* ~notesend~
*
***************************************************************************

}

UNIT CDF;

    {$A+,B-,D+,E+,F+,G+,I+,L+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

    (****************************************************************************)

INTERFACE
USES
    OPASCIIZ,
    OpDate,
    OpRoot,
    UTIAM
    {$IFDEF VirtualPascal}
    ,USE32
    {$ENDIF}
    ;

CONST
    MaxCDFFieldNameSize = 30;

TYPE
    CDFMode        = (CDFUNINIT, CDFINIT, CDFERROR);

    PCDF           = ^TCDF;
    TCDF           = OBJECT(ROOT)
                         BFile          : FILE;
                         FileName       : STRING;
                         Mode           : CDFMode;
                         MyWidth,
                         MyPrecision    : BYTE;

                         CONSTRUCTOR Init(FName : STRING);
                         CONSTRUCTOR InitOverWrite(FName : STRING);
                         PROCEDURE SetPrecision(Width, Prec : BYTE);
                         FUNCTION PutStrg(Line : STRING) : BOOLEAN;
                         FUNCTION PutReal(R : REAL) : BOOLEAN;
                         FUNCTION PutLong(L : LONGINT) : BOOLEAN;
                         FUNCTION PutHexLong(L : LONGINT) : BOOLEAN;
                         FUNCTION PutDate(D : Date) : BOOLEAN;
                         FUNCTION PutTime(T : Time) : BOOLEAN;
                         FUNCTION PutBool(B : BOOLEAN) : BOOLEAN;
                         FUNCTION PutDTR(DTR : DateTimeRec) : BOOLEAN;
                         FUNCTION PutTerm : BOOLEAN;

                         DESTRUCTOR Done; VIRTUAL;
                     END;

    TFieldType     = (EString,
                      EREAL,
                      ELong,
                      EYN,
                      EBool,
                      EDate,
                      ETime,
                      EDateTime,
                      EByte,
                      EHexLong,
                      EDummy);

    PFieldNode     = ^TFieldNode;
    TFieldNode     = OBJECT(SingleListNode)
                         MyLen          : WORD; {size of dynamic memory allocation}
                         MyType         : TFieldType;
                         MyName         : STRING[MaxCDFFieldNameSize];
                         MyStrLen       : BYTE; {used by string object}
                         MyDest         : POINTER;
                         CONSTRUCTOR Init(FT : TFieldType; Name : STRING; VAR Dest);
                         FUNCTION GetType : TFieldType;
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;

                         FUNCTION AsString : STRING;
                         FUNCTION AsReal : REAL;
                         FUNCTION AsLong : LONGINT;
                         FUNCTION AsYN  : BOOLEAN;
                         FUNCTION AsBool : BOOLEAN;
                         FUNCTION AsDate : Date;
                         FUNCTION AsTime : Time;
                         FUNCTION AsByte : BYTE;
                         FUNCTION AsDTR(VAR DTR : DateTimeRec) : BOOLEAN;
                     PRIVATE
                         FUNCTION PtoS  : STRING;
                         FUNCTION PtoR  : REAL;
                         FUNCTION PtoL  : LONGINT;
                         PROCEDURE PtoDTR(VAR DTR : DateTimeRec);
                         FUNCTION PtoBool : BOOLEAN;
                         FUNCTION PtoByte : BYTE;
                     END;

    PStrgFieldNode = ^TStrgFieldNode;
    TStrgFieldNode = OBJECT(TFieldNode)
                         CONSTRUCTOR Init(Name : STRING; VAR Dest);
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                     END;

    PYNFieldNode   = ^TYNFieldNode;
    TYNFieldNode   = OBJECT(TFieldNode)
                         CONSTRUCTOR Init(Name : STRING; VAR Dest);
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                     END;

    PBoolFieldNode = ^TBoolFieldNode;
    TBoolFieldNode = OBJECT(TFieldNode)
                         CONSTRUCTOR Init(Name : STRING; VAR Dest);
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                     END;

    PByteFieldNode = ^TByteFieldNode;
    TByteFieldNode = OBJECT(TFieldNode)
                         CONSTRUCTOR Init(Name : STRING; VAR Dest);
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                     END;

    PRealFieldNode = ^TRealFieldNode;
    TRealFieldNode = OBJECT(TFieldNode)
                         CONSTRUCTOR Init(Name : STRING; VAR Dest);
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                     END;


    PLongFieldNode = ^TLongFieldNode;
    TLongFieldNode = OBJECT(TFieldNode)
                         CONSTRUCTOR Init(Name : STRING; VAR Dest);
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                     END;

    PDateFieldNode = ^TDateFieldNode;
    TDateFieldNode = OBJECT(TFieldNode)
                         CONSTRUCTOR Init(Name : STRING; VAR Dest);
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                     END;

    PDateTimeFieldNode = ^TDateTimeFieldNode;
    TDateTimeFieldNode = OBJECT(TFieldNode)
                             CONSTRUCTOR Init(Name : STRING; VAR Dest);
                             FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                         END;

    PTimeFieldNode = ^TTimeFieldNode;
    TTimeFieldNode = OBJECT(TFieldNode)
                         CONSTRUCTOR Init(Name : STRING; VAR Dest);
                         FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                     END;

    PDummyFieldNode = ^TDummyFieldNode;
    TDummyFieldNode = OBJECT(TFieldNode)
                          CONSTRUCTOR Init(Name : STRING; VAR Dest);
                          FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                      END;

    PHexLongFieldNode = ^THexLongFieldNode;
    THexLongFieldNode = OBJECT(TFieldNode)
                            CONSTRUCTOR Init(Name : STRING; VAR Dest);
                            FUNCTION ParseField(Field : STRING) : BOOLEAN; VIRTUAL;
                        END;


    PCDFReader     = ^TCDFReader;
    TCDFReader     = OBJECT(SingleList)
                         MyFile         : TEXT;
                         LineBuff       : AsciiZ;
                         crDelim,
                         crQuoteChar    : CHAR;
                         MyLine,
                         TotLines       : LONGINT;

                         CONSTRUCTOR Init(FileName : STRING);
                         FUNCTION AddField(FT : TFieldType; Name : STRING; VAR DataField) : BOOLEAN;
                         FUNCTION LoadRecord : BOOLEAN;
                         FUNCTION ParseTokens : BOOLEAN;
                         FUNCTION LineCount : LONGINT;
                         FUNCTION PctDone : BYTE;
                         FUNCTION NthField(N : LONGINT) : PFieldNode;

                         DESTRUCTOR Done; VIRTUAL;
                     END;

    (****************************************************************************)


IMPLEMENTATION
USES
    Dos,
    KERROR,
    OpDos,
    OpInline,
    OpString,
    UTTIMDAT;

    (****************************************************************************)

    CONSTRUCTOR TCDF.Init(FName : STRING);
    VAR
        InName,
        OutName        : STRING;
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        FileName := FName;
        MyWidth := 10;
        MyPrecision := 4;

        IF LENGTH(Trim(FName)) = 0 THEN BEGIN
            InitStatus := 2;
            FAIL;
        END;
        { Open the file }

        ASSIGN(BFile, FName);     {open data files}
        {$I-}
        RESET(BFile, 1);
        {$I+}
        InitStatus := IORESULT;

        CASE InitStatus OF
            0 :
                SEEK(BFile, FILESIZE(BFile)); {seek to eof}
            2,
            110 :
                REWRITE(BFile, 1); {create new file}
            ELSE BEGIN
                {crash if file error} {boom!}
                {$I-}
                CLOSE(BFile);
                {$I+}
                Mode := CDFERROR;
                FAIL;
            END;
        END;
        Mode := CDFINIT;
    END;

    (****************************************************************************)

    CONSTRUCTOR TCDF.InitOverWrite(FName : STRING);
    VAR
        InName,
        OutName        : STRING;
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        MyWidth := 10;
        MyPrecision := 4;
        FileName := FName;

        IF LENGTH(Trim(FName)) = 0 THEN BEGIN
            InitStatus := 2;
            Mode := CDFERROR;
            FAIL;
        END;
        { Open the file }

        ASSIGN(BFile, FName);     {open data files}
        {$I-}
        REWRITE(BFile, 1);
        {$I+}
        InitStatus := IORESULT;

        IF InitStatus <> 0 THEN
            FAIL;

        Mode := CDFINIT;
    END;

    (****************************************************************************)

    FUNCTION TCDF.PutStrg(Line : STRING) : BOOLEAN;
    VAR
        Strg           : STRING;
        S4,
        Repl           : STRING[1];
        kResult        : WORD;
        Stat           : BOOLEAN;
    BEGIN
        IF POS('"', Line) > 0 THEN BEGIN
            S4 := '"';            {replace double quotes with single quotes}
            Repl := '''';
            Replace(Line[1], LENGTH(Line),
                    S4[1], 1,
                    Repl[1], 1,
                    kResult,
                    LENGTH(Line), TRUE);

        END;
        Strg := '"' + Line + '",';
        BLOCKWRITE(BFile, Strg[1], ORD(Strg[0]), kResult);
        Stat := (kResult = ORD(Strg[0]));
        IF NOT Stat THEN
            Mode := CDFERROR;
        PutStrg := Stat;
    END;

    (****************************************************************************)

    FUNCTION TCDF.PutDate(D : Date) : BOOLEAN;
    BEGIN
        PutDate := PutStrg(DateToDateString('mm/dd/yyyy', D));
    END;

    (****************************************************************************)

    FUNCTION TCDF.PutTime(T : Time) : BOOLEAN;
    BEGIN
        PutTime := PutStrg(TimeToTimeString('hh:mm:ss', T));
    END;

    (****************************************************************************)

    FUNCTION TCDF.PutDTR(DTR : DateTimeRec) : BOOLEAN;
    BEGIN
        PutDTR := PutStrg(DTRtoStringDeluxe(DTR, TRUE, TRUE));
    END;

    (****************************************************************************)

    FUNCTION TCDF.PutBool(B : BOOLEAN) : BOOLEAN;
    VAR
        Strg           : STRING[1];
    BEGIN
        IF B THEN
            Strg := 'T'
        ELSE
            Strg := 'F';

        PutBool := PutStrg(Strg);
    END;

    (****************************************************************************)

    FUNCTION FTOA(N : REAL; W, P : INTEGER) : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        STR(N:W:P, Strg);
        FTOA := Strg;
    END;

    (******************************************************************************)

    FUNCTION TCDF.PutReal(R : REAL) : BOOLEAN;
    VAR
        Strg           : STRING;
        kResult        : WORD;
        Stat           : BOOLEAN;
    BEGIN
        Strg := Trim(FTOA(R, MyWidth, MyPrecision)) + ',';
        BLOCKWRITE(BFile, Strg[1], ORD(Strg[0]), kResult);
        Stat := (kResult = ORD(Strg[0]));
        IF NOT Stat THEN
            Mode := CDFERROR;
        PutReal := Stat;
    END;

    (****************************************************************************)

    FUNCTION TCDF.PutLong(L : LONGINT) : BOOLEAN;
    VAR
        Strg           : STRING;
        kResult        : WORD;
        Stat           : BOOLEAN;
    BEGIN
        Strg := Long2Str(L) + ',';
        BLOCKWRITE(BFile, Strg[1], ORD(Strg[0]), kResult);
        Stat := (kResult = ORD(Strg[0]));
        IF NOT Stat THEN
            Mode := CDFERROR;
        PutLong := Stat;
    END;

    (****************************************************************************)

    FUNCTION TCDF.PutHexLong(L : LONGINT) : BOOLEAN;
    VAR
        Strg           : STRING;
        kResult        : WORD;
        Stat           : BOOLEAN;
    BEGIN
        Strg := '$' + HexL(L) + ',';
        BLOCKWRITE(BFile, Strg[1], ORD(Strg[0]), kResult);
        Stat := (kResult = ORD(Strg[0]));
        IF NOT Stat THEN
            Mode := CDFERROR;
        PutHexLong := Stat;
    END;

    (****************************************************************************)

    FUNCTION TCDF.PutTerm : BOOLEAN;
    VAR
        Strg           : STRING;
        kResult        : WORD;
        Stat           : BOOLEAN;
    BEGIN
        Strg := #13#10;
        SEEK(BFile, FILESIZE(BFile) - 1);
        BLOCKWRITE(BFile, Strg[1], ORD(Strg[0]), kResult);
        Stat := (kResult = ORD(Strg[0]));
        IF NOT Stat THEN
            Mode := CDFERROR;
        PutTerm := Stat;
    END;

    (****************************************************************************)

    PROCEDURE TCDF.SetPrecision(Width, Prec : BYTE);
    BEGIN
        MyWidth := Width;
        MyPrecision := Prec;
    END;

    (****************************************************************************)

    DESTRUCTOR TCDF.Done;
        {- Close up shop and boogie method}
    BEGIN
        CLOSE(BFile);
        Mode := CDFUNINIT;
    END;

    (****************************************************************************)

    CONSTRUCTOR TFieldNode.Init(FT : TFieldType; Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        MyType := FT;
        MyName := Name;
        MyDest := @Dest;
    END;

    {-----------}

    FUNCTION TFieldNode.GetType : TFieldType;
    BEGIN
        GetType := MyType;
    END;

    {-----------}

    FUNCTION TFieldNode.ParseField(Field : STRING) : BOOLEAN;
    BEGIN
        Abstract;
    END;

    {-----------}

    FUNCTION TFieldNode.PtoS : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        MoveFast(MyDest^, Strg, SUCC(BYTE(MyDest^)));
        PtoS := Strg;
    END;

    {-----------}

    FUNCTION TFieldNode.PtoR : REAL;
    VAR
        T              : REAL;
    BEGIN
        MoveFast(MyDest^, T, SIZEOF(T));
        PtoR := T;
    END;

    {-----------}

    FUNCTION TFieldNode.PtoL : LONGINT;
    VAR
        T              : LONGINT;
    BEGIN
        MoveFast(MyDest^, T, SIZEOF(T));
        PtoL := T;
    END;

    {-----------}

    PROCEDURE TFieldNode.PtoDTR(VAR DTR : DateTimeRec);
    BEGIN
        MoveFast(MyDest^, DTR, SIZEOF(DTR))
    END;

    {-----------}

    FUNCTION TFieldNode.PtoBool : BOOLEAN;
    VAR
        T              : BOOLEAN;
    BEGIN
        MoveFast(MyDest^, T, SIZEOF(T));
        PtoBool := T;
    END;

    {-----------}

    FUNCTION TFieldNode.PtoByte : BYTE;
    VAR
        T              : BYTE;
    BEGIN
        MoveFast(MyDest^, T, SIZEOF(T));
        PtoByte := T;
    END;

    {-----------}

    FUNCTION TFieldNode.AsString : STRING;
    VAR
        DTR            : DateTimeRec;
    BEGIN
        CASE MyType OF
            EString :
                AsString := PtoS;
            EREAL :
                AsString := Real2Str(PtoR, 9, 4);
            ELong :
                AsString := Long2Str(PtoL);
            EYN :
                IF PtoBool THEN
                    AsString := 'Y'
                ELSE
                    AsString := 'N';
            EBool :
                IF PtoBool THEN
                    AsString := 'T'
                ELSE
                    AsString := 'F';
            EDate :
                AsString := DateToDateString('mm/dd/yyyy', PtoL);
            EDateTime :
                BEGIN
                    PtoDTR(DTR);
                    AsString := DTRtoStringDeluxe(DTR, TRUE, TRUE);
                END;
            ETime :
                AsString := TimeToTimeString('hh:mm:ss', PtoL);
            EByte :
                AsString := Long2Str(PtoL);
            EDummy :
                AsString := '';
        END;                      {case}
    END;

    {-----------}

    FUNCTION TFieldNode.AsReal : REAL;
    VAR
        R              : Float;
    BEGIN
        CASE MyType OF
            EString :
                IF Str2Real(PtoS, R) THEN
                    AsReal := R
                ELSE
                    AsReal := 0.0;
            EREAL :
                AsReal := PtoR;
            ELong :
                AsReal := PtoL;
            EYN :
                IF PtoBool THEN
                    AsReal := 0.0
                ELSE
                    AsReal := 1.0;
            EBool :
                IF PtoBool THEN
                    AsReal := 0.0
                ELSE
                    AsReal := 1.0;
            EDate :
                AsReal := 0.0;
            EDateTime :
                AsReal := 0.0;
            ETime :
                AsReal := 0.0;
            EByte :
                AsReal := PtoByte;
            EDummy :
                AsReal := 0.0;
        END;                      {case}
    END;

    {-----------}

    FUNCTION TFieldNode.AsLong : LONGINT;
    VAR
        L              : LONGINT;
    BEGIN
        CASE MyType OF
            EString :
                IF Str2Long(PtoS, L) THEN
                    AsLong := L
                ELSE
                    AsLong := 0;
            EREAL :
                AsLong := PtoL;
            ELong :
                AsLong := ROUND(PtoL);
            EYN :
                IF PtoBool THEN
                    AsLong := 0
                ELSE
                    AsLong := 1;
            EBool :
                IF PtoBool THEN
                    AsLong := 0
                ELSE
                    AsLong := 1;
            EDate :
                AsLong := 0;
            EDateTime :
                AsLong := 0;
            ETime :
                AsLong := 0;
            EByte :
                AsLong := PtoByte;
            EDummy :
                AsLong := 0;
        END;                      {case}
    END;

    {-----------}

    FUNCTION TFieldNode.AsYN : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        AsYN := FALSE;
        CASE MyType OF
            EString :
                BEGIN
                    Strg := StUpCase(PtoS);
                    IF Strg = '' THEN
                        EXIT;
                    AsYN := Strg[1] = 'Y'
                END;
            EREAL :
                AsYN := ABS(PtoR) > 0.0;
            ELong :
                AsYN := PtoL > 0;
            EYN :
                AsYN := PtoBool;
            EBool :
                AsYN := PtoBool;
            EDate : ;
            EDateTime : ;
            ETime : ;
            EByte :
                AsYN := PtoByte > 0;
            EDummy : ;
        END;                      {case}
    END;

    {-----------}

    FUNCTION TFieldNode.AsBool : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        AsBool := FALSE;
        CASE MyType OF
            EString :
                BEGIN
                    Strg := StUpCase(PtoS);
                    IF Strg = '' THEN
                        EXIT;
                    AsBool := Strg[1] = 'T'
                END;
            EREAL :
                AsBool := ABS(PtoR) > 0.0;
            ELong :
                AsBool := PtoL > 0;
            EYN :
                AsBool := PtoBool;
            EBool :
                AsBool := PtoBool;
            EDate : ;
            EDateTime : ;
            ETime : ;
            EByte :
                AsBool := PtoByte > 0;
            EDummy : ;
        END;                      {case}
    END;

    {-----------}

    FUNCTION TFieldNode.AsDate : Date;
    VAR
        DTR            : DateTimeRec;
    BEGIN
        AsDate := BADDate;
        CASE MyType OF
            EString :
                AsDate := DateStringToDate('mm/dd/yyyy', PtoS);
            EREAL :
                AsDate := ROUND(PtoR);
            ELong :
                AsDate := PtoL;
            EYN :
                AsDate := BADDate;
            EBool :
                AsDate := BADDate;
            EDate :
                AsDate := PtoL;
            EDateTime :
                BEGIN
                    PtoDTR(DTR);
                    AsDate := DTR.D;
                END;
            ETime :
                AsDate := BADDate;
            EByte :
                AsDate := BADDate;
            EDummy :
                AsDate := BADDate;
        END;                      {case}
    END;

    {-----------}

    FUNCTION TFieldNode.AsDTR(VAR DTR : DateTimeRec) : BOOLEAN;
    BEGIN
        DTR.D := BADDate;
        DTR.T := 0;
        AsDTR := TRUE;
        CASE MyType OF
            EString :
                DTR.D := DateStringToDate('mm/dd/yyyy', PtoS);
            EREAL : ;
            ELong :
                DTR.D := PtoL;
            EYN : ;
            EBool : ;
            EDate :
                DTR.D := PtoL;
            EDateTime :
                BEGIN
                    PtoDTR(DTR);
                END;
            ETime : ;
            EByte : ;
            EDummy : ;
        END;                      {case}
    END;

    {-----------}

    FUNCTION TFieldNode.AsTime : Time;
    VAR
        DTR            : DateTimeRec;
    BEGIN
        CASE MyType OF
            EString :
                AsTime := TimeStringToTime('hh:mm:ss', PtoS);
            EREAL :
                AsTime := ROUND(PtoR);
            ELong :
                AsTime := PtoL;
            EYN :
                AsTime := BadTime;
            EBool :
                AsTime := BadTime;
            EDate :
                AsTime := PtoL;
            ETime :
                AsTime := BadTime;
            EDateTime :
                BEGIN
                    PtoDTR(DTR);
                    AsTime := DTR.T;
                END;
            EByte :
                AsTime := BadTime;
            EDummy :
                AsTime := BadTime;
        END;                      {case}
    END;

    {-----------}

    FUNCTION TFieldNode.AsByte : BYTE;
    VAR
        L              : LONGINT;
    BEGIN
        CASE MyType OF
            EString :
                IF NOT Str2Long(PtoS, L) THEN
                    L := 0;
            EREAL :
                L := ROUND(PtoR);
            ELong :
                L := ROUND(PtoL);
            EYN :
                IF PtoBool THEN
                    L := 0
                ELSE
                    L := 1;
            EBool :
                IF PtoBool THEN
                    L := 0
                ELSE
                    L := 1;
            EDate :
                L := 0;
            ETime :
                L := 0;
            EDateTime :
                L := 0;
            EByte :
                L := PtoByte;
            EDummy :
                L := 0;
        END;                      {case}
        IF L > $FF THEN
            L := $FF;
        IF L < 0 THEN
            L := 0;
        AsByte := L;
    END;

    {-----------}

    CONSTRUCTOR TStrgFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(EString, Name, Dest) THEN
            FAIL;
        MyLen := SIZEOF(STRING);
        IF MyDest = NIL THEN BEGIN
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL;
        END
        ELSE
            MyDest := @Dest;
    END;

    {-----------}

    FUNCTION TStrgFieldNode.ParseField(Field : STRING) : BOOLEAN;
    BEGIN
        MoveFast(Field, MyDest^, SUCC(LENGTH(Field)));
        ParseField := TRUE;
    END;

    {-----------}

    CONSTRUCTOR TYNFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(EYN, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(BOOLEAN);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL;
        END;
    END;

    {-----------}

    FUNCTION TYNFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        B              : BOOLEAN;
    BEGIN
        ParseField := TRUE;
        B := StUpCase(Field) = 'Y';
        MoveFast(B, MyDest^, SIZEOF(B));
    END;

    {-----------}

    CONSTRUCTOR TBoolFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(EBool, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(BOOLEAN);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL
        END;
    END;

    {-----------}

    FUNCTION TBoolFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        B              : BOOLEAN;
    BEGIN
        ParseField := TRUE;
        B := (StUpCase(Field) = 'T') OR (StUpCase(Field) = 'Y');
        MoveFast(B, MyDest^, SIZEOF(B));
    END;

    {-----------}

    CONSTRUCTOR TByteFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(EByte, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(BYTE);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL
        END;
    END;

    {-----------}

    FUNCTION TByteFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        L              : LONGINT;
    BEGIN
        ParseField := FALSE;
        IF NOT Str2Long(Field, L) THEN
            EXIT;
        IF (L < 0) OR (L > 255) THEN
            EXIT;
        MoveFast(L, MyDest^, SIZEOF(BYTE));
        ParseField := TRUE;
    END;

    {-----------}

    CONSTRUCTOR TRealFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(EREAL, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(REAL);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL;
        END;
    END;

    {-----------}

    FUNCTION TRealFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        R              : Float;
    BEGIN
        ParseField := Str2Real(Field, R);
        MoveFast(R, MyDest^, SIZEOF(R));

    END;

    {-----------}

    CONSTRUCTOR TLongFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(ELong, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(LONGINT);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL;
        END;
    END;

    {-----------}


    FUNCTION TLongFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        L              : LONGINT;
    BEGIN
        ParseField := TRUE;
        IF NOT Str2Long(Field, L) THEN BEGIN
            L := 0;
            ParseField := FALSE;
        END;
        MoveFast(L, MyDest^, SIZEOF(L))
    END;

    {-----------}

    CONSTRUCTOR THexLongFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(ELong, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(LONGINT);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL;
        END;
    END;

    {-----------}

    FUNCTION THexLongFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        L              : LONGINT;
    BEGIN
        ParseField := TRUE;
        IF Field[1] <> '$' THEN
            Field := '$' + Field;

        IF NOT Str2Long(Field, L) THEN BEGIN
            L := 0;
            ParseField := FALSE;
        END;
        MoveFast(L, MyDest^, SIZEOF(L))
    END;

    {-----------}


    {-----------}

    CONSTRUCTOR TDateFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(EDate, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(Date);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL;
        END;
    END;

    {-----------}

    FUNCTION TDateFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        D              : Date;
    BEGIN
        D := DateStringToDate('mm/dd/yyyy', Field);
        MoveFast(D, MyDest^, SIZEOF(D));
        ParseField := D <> BADDate;
    END;

    {-----------}

    CONSTRUCTOR TTimeFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(ETime, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(Time);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL;
        END;
    END;

    {-----------}

    FUNCTION TTimeFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        T              : Time;
    BEGIN
        T := TimeStringToTime('hh:mm:ss', Field);
        MoveFast(T, MyDest^, SIZEOF(T));
        ParseField := T <> BadTime;
    END;

    {-----------}

    CONSTRUCTOR TDateTimeFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(EDate, Name, Dest) THEN
            FAIL;
        IF MyDest = NIL THEN BEGIN
            MyLen := SIZEOF(DateTimeRec);
            GETMEM(MyDest, MyLen);
            IF MyDest = NIL THEN
                FAIL;
        END;
    END;

    {-----------}

    FUNCTION TDateTimeFieldNode.ParseField(Field : STRING) : BOOLEAN;
    VAR
        DTR            : DateTimeRec;
    BEGIN
        ParseField := NowStringToDTR(Field, TRUE, TRUE, DTR);
        MoveFast(DTR, MyDest^, SIZEOF(DTR));
    END;

    {-----------}

    CONSTRUCTOR TDummyFieldNode.Init(Name : STRING; VAR Dest);
    BEGIN
        IF NOT INHERITED Init(ETime, Name, Dest) THEN
            FAIL;
        MyDest := NIL;
    END;

    {-----------}

    FUNCTION TDummyFieldNode.ParseField(Field : STRING) : BOOLEAN;
    BEGIN
        {just skip it}
    END;

    {-----------}

    CONSTRUCTOR TCDFReader.Init(FileName : STRING);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
        ASSIGN(MyFile, FileName);
        {$I-}
        System.RESET(MyFile);
        TotLines := - 1;
        MyLine := 0;
        crQuoteChar := '"';
        crDelim := ',';
        IF IORESULT <> 0 THEN
            FAIL;
        {$I+}
    END;

    {-----------}

    FUNCTION TCDFReader.AddField(FT : TFieldType; Name : STRING; VAR DataField) : BOOLEAN;
    VAR
        Pfn            : PFieldNode;
    BEGIN
        {create polymorphic field parser objects and append them to self-list}
        {we pass the address of the destination variable and overwrite it}
        {as we parse each line record.  This saves an assignment step}

        AddField := TRUE;

        CASE FT OF
            EString :
                Pfn := NEW(PStrgFieldNode, Init(Name, DataField));
            EREAL :
                Pfn := NEW(PRealFieldNode, Init(Name, DataField));
            ELong :
                Pfn := NEW(PLongFieldNode, Init(Name, DataField));
            EYN :
                Pfn := NEW(PYNFieldNode, Init(Name, DataField));
            EBool :
                Pfn := NEW(PBoolFieldNode, Init(Name, DataField));
            EDate :
                Pfn := NEW(PDateFieldNode, Init(Name, DataField));
            ETime :
                Pfn := NEW(PTimeFieldNode, Init(Name, DataField));
            EDateTime :
                Pfn := NEW(PDateTimeFieldNode, Init(Name, DataField));
            EByte :
                Pfn := NEW(PByteFieldNode, Init(Name, DataField));
            EHexLong :
                Pfn := NEW(PHexLongFieldNode, Init(Name, DataField));
        END;
        IF Pfn = NIL THEN
            AddField := FALSE
        ELSE
            APPEND(Pfn);
    END;

    {-----------}

    {parse an entire CDF line into all the fields in the list}
    {DOES NOT handle embedded double quotes in strings!}
    {max field width = 255 chars}

    {since we parse the whole line at once, we don't need to shift the}
    {buffer.  This should run faster}

    {all variable fields are filled in at once, so we don't need to query}
    {each field.  Use dummy variable locations if you dont care about a column}
    FUNCTION TCDFReader.ParseTokens : BOOLEAN;
    VAR
        C              : CHAR;
        Pfn            : PFieldNode;
        AnyFieldsFound,
        InQuote        : BOOLEAN;
        Strg           : STRING;
        I              : WORD;
    BEGIN
        ParseTokens := TRUE;
        Pfn := PFieldNode(Head);  {point to the first field parser}
        InQuote := FALSE;
        AscTrim(LineBuff, LineBuff);
        AnyFieldsFound := FALSE;
        {append trailing dummy comma to trigger parsing of last field}
        ConcatStr(LineBuff, ',', LineBuff);

        Strg := '';               {reset collector}

        FOR I := 0 TO LenAsc(LineBuff) DO BEGIN {loop through CDF line}
            C := LineBuff[I];
            CASE C OF
                '"' :
                    InQuote := NOT InQuote; {toggle quote mode}
                ',' :
                    BEGIN         {possible field delimiter - or maybe not...}
                        IF InQuote THEN BEGIN
                            Strg := Strg + C; {quoted comma - collect it}
                            CONTINUE;
                        END
                        ELSE      {have complete field: parse it with virtual parse method}
                            IF NOT Pfn^.ParseField(Strg) THEN BEGIN
                                DispErrorDeluxe('problem parsing ' +
                                                Pfn^.MyName + ' <' + Strg + '> in line: ',
                                                Long2Str(MyLine),
                                                TRUE, Iam);
                                ParseTokens := AnyFieldsFound;
                                EXIT;
                            END
                        ELSE
                            AnyFieldsFound := TRUE;
                        Strg := ''; {reset collector}
                        Pfn := PFieldNode(Next(Pfn)); {move to the next field parser object}
                        IF Pfn = NIL THEN {quit line loop if we are out of fields}
                            BREAK;
                    END;
                ELSE
                    {IF InQuote THEN} {dont collect inter-field spacing}
                    Strg := Strg + C; {collect unquoted character}
            END;
        END;
        {we hit the end of the line, soooooo........}
        {fill any unfulfilled fields with nil values}
        WHILE Pfn <> NIL DO BEGIN {loop until we run out of known fields}
            Pfn^.ParseField('');
            Pfn := PFieldNode(Next(Pfn)); {move to the next field parser object}
        END;
    END;

    {----------}

    FUNCTION TCDFReader.LoadRecord : BOOLEAN;
    BEGIN
        LoadRecord := FALSE;

        REPEAT
            IF NOT ReadLnAsc(MyFile, LineBuff) THEN
                EXIT;
            INC(MyLine);

            AscTrim(LineBuff, LineBuff);

            IF (LineBuff[0] = ';') THEN {skip comment lines}
                LineBuff[0] := #0;

        UNTIL LenAsc(LineBuff) > 0;

        LoadRecord := ParseTokens;
    END;

    {-----------}

    FUNCTION TCDFReader.LineCount : LONGINT;
    VAR
        OldLine,
        OldPos         : LONGINT;
    BEGIN
        OldPos := TextPos(MyFile);
        System.RESET(MyFile);
        OldLine := MyLine;
        MyLine := 0;
        WHILE NOT EOF(MyFile) DO BEGIN
            IF NOT ReadLnAsc(MyFile, LineBuff) THEN
                BREAK;
            INC(MyLine);
        END;
        LineCount := MyLine;
        MyLine := OldLine;
        TextSeek(MyFile, OldPos);
    END;

    {-----------}

    FUNCTION TCDFReader.PctDone : BYTE;
    BEGIN
        IF TotLines = - 1 THEN
            TotLines := LineCount;
        IF TotLines <= 0 THEN
            TotLines := 1;
        PctDone := ROUND((MyLine / TotLines) * 100.0);
    END;

    {-----------}

    FUNCTION TCDFReader.NthField(N : LONGINT) : PFieldNode;
    BEGIN
        NthField := PFieldNode(Nth(N));
    END;

    {-----------}

    DESTRUCTOR TCDFReader.Done;
    BEGIN
        CLOSE(MyFile);
        INHERITED Done;
    END;

    {-----------}

END.                              {of unit cdf}

(****************************************************************************)
(****************************************************************************)

