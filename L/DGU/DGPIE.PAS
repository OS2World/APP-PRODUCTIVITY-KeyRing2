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
* Piechart generator
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
!!!Error - this unit is obsolete.  Use DGPRINT
UNIT DGPie;
    {$IFDEF VirtualPascal}
    !! This unit is not compatible with Virtual Pascal
    {$ENDIF}
INTERFACE
USES
    Boiler45,
    KERROR,
    LJVAR,
    OPPRNLOW
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

TYPE
    PLJPie         = ^TLJPie;
    TLJPie         = OBJECT(TLaserJet)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);
                         PROCEDURE DrawPie(NoOfSlices     : BYTE;
                                           PieSpec        : TPieArray;
                                           XOrigin,
                                           YOrigin,
                                           Radius         : WORD;
                                           Optimize,
                                           DrawLabels,
                                           DrawShadow     : BOOLEAN;
                                           XShadow,
                                           YShadow,
                                           MinPointerLineLength,
                                           MinVertDistance,
                                           LabelLineStart : INTEGER;
                                           BackgroundColor : BYTE;
                                           TopCaption     : STRING;
                                           TopFont        : FontTypeT;
                                           TCColor        : TPrnColors;
                                           BotCaption     : STRING;
                                           BotFont        : FontTypeT;
                                           BCColor        : TPrnColors;
                                           XStretch,
                                           YStretch       : WORD); VIRTUAL;
                     PRIVATE
                         FUNCTION XOffset(A, B, Amt : INTEGER) : INTEGER;
                         FUNCTION Yoffset(A, B, Amt : INTEGER) : INTEGER;
                         FUNCTION ExplByAngle(InAngle : INTEGER; Radius : LONGINT) : INTEGER;
                         FUNCTION Quadrant(InAngle : INTEGER) : BYTE;
                         PROCEDURE SetFontSize(Font : FontTypeT);
                         PROCEDURE CalcPointers(NoOfSlices     : BYTE;
                                                VAR PieSpec    : TPieArray;
                                                MinPointerLineLength,
                                                MinVertDistance,
                                                Rotation       : INTEGER);
                         FUNCTION CheckPointerVerticalDiffs(NoOfSlices     : BYTE;
                                                            VAR PieSpec    : TPieArray;
                                                            Radius,
                                                            Rotation,
                                                            MinVertDistance : INTEGER) : BOOLEAN;

                         FUNCTION ButtOriented(NoOfSlices : BYTE; VAR PieSpec : TPieArray) : BOOLEAN;
                     END;
IMPLEMENTATION
USES
    Graph,
    GraphAdd,
    DGMath,
    OpInline;

    {-------------------}

    FUNCTION TLJPie.XOffset(A, B, Amt : INTEGER) : INTEGER;
    VAR
        T              : INTEGER;
        BisectedAngle  : REAL;
    BEGIN
        BisectedAngle := (A * 1.0 + B * 1.0) / 2.0;
        BisectedAngle := BisectedAngle * DegreesToRadians;
        T := ROUND(COS(BisectedAngle) * Amt);
        XOffset := T;
    END;

    {-------------------}

    FUNCTION TLJPie.Yoffset(A, B, Amt : INTEGER) : INTEGER;
    VAR
        T              : INTEGER;
        BisectedAngle  : REAL;
    BEGIN
        BisectedAngle := (A * 1.0 + B * 1.0) / 2.0;
        BisectedAngle := BisectedAngle * DegreesToRadians;
        T := ROUND(SIN(BisectedAngle) * Amt);
        Yoffset := T;
    END;

    {-------------------}

    FUNCTION TLJPie.ExplByAngle(InAngle : INTEGER; Radius : LONGINT) : INTEGER;
    VAR
        N              : INTEGER;
    BEGIN
        InAngle := (InAngle MOD 360);
        N := Radius DIV 15;       {zzzz}
        CASE InAngle OF
            0..4 :
                ExplByAngle := ROUND(N * 2.0);
            5..15 :
                ExplByAngle := ROUND(N * 1.8);
            16..45 :
                ExplByAngle := ROUND(N * 1.5);
            46..180 :
                ExplByAngle := ROUND(N * 1.2);
            181..360 :
                ExplByAngle := ROUND(N * 1.0);
        END;
    END;

    {-------------------}

    FUNCTION TLJPie.Quadrant(InAngle : INTEGER) : BYTE;
    BEGIN
        InAngle := (InAngle MOD 360);
        CASE InAngle OF
            0..90 :
                Quadrant := 1;
            91..180 :
                Quadrant := 2;
            181..270 :
                Quadrant := 3;
            271..360 :
                Quadrant := 4;
        END;
    END;

    {-------------------}

    PROCEDURE TLJPie.SetFontSize(Font : FontTypeT);
    BEGIN
        CASE Font OF
            fNone :
                EXIT;
            fSmall :
                SetFont(TriplexFont, HorizDir, 5, 5, PtUnits);
            fLinePrint,
            fCourier :
                SetFont(SansSerifFont, HorizDir, 6, 6, PtUnits);
            fTable :
                SetFont(TriplexFont, HorizDir, 6, 6, PtUnits);
            fMainMedium,
            fItalicMedium,
            fMain,
            fFootnote,
            fItalic :
                SetFont(TriplexFont, HorizDir, 7, 7, PtUnits);
            fBoldMedium,
            fBoldItalic,
            fBold :
                SetFont(TriplexFont, HorizDir, 8, 8, PtUnits);
            fHuge :
                SetFont(TriplexFont, HorizDir, 9, 9, PtUnits);
        END;
    END;

    {-------------------}

    PROCEDURE TLJPie.CalcPointers(NoOfSlices     : BYTE;
                                  VAR PieSpec    : TPieArray;
                                  MinPointerLineLength,
                                  MinVertDistance,
                                  Rotation       : INTEGER);
    VAR
        I              : BYTE;
        CurLen         : INTEGER;
        FirstOne       : BOOLEAN;
        ThisY,
        LastY          : INTEGER;

        {-------------------}

        FUNCTION YVal(InAngle, InLen : INTEGER) : INTEGER;
        BEGIN
            YVal := ROUND(SIN(InAngle * DegreesToRadians) * InLen);
        END;

        {-------------------}

        FUNCTION NewY(InAngle, InLen : INTEGER) : INTEGER;
        BEGIN
            IF (ABS(SIN(InAngle * DegreesToRadians)) < 0.05) THEN
                NewY := InLen
            ELSE
                NewY := ABS(ROUND((InLen * 0.8) / SIN(InAngle * DegreesToRadians)));
        END;

    BEGIN
        { this part should be pretty straightforward... }
        { 1. Establish the new angle of the label line  }
        FOR I := 1 TO NoOfSlices DO BEGIN
            WITH PieSpec[I] DO
                LabelLineAngle := ((StartAngle + Rotation) + (EndAngle + Rotation)) DIV 2;
        END;
        { 2. Set each pointerlength to the default }
        FOR I := 1 TO NoOfSlices DO
            PieSpec[I].LabelLineLength := MinPointerLineLength;

        { 3. This part is a little trickier -- we lengthen pointer lines such
         that the vertical distance between adjacent lines is at least
         MinVertDistance, within the context of each quadrant, going away
         from the x-axis
        }

        { Start in Quadrant #1, we go in "regular" order }
        FirstOne := TRUE;
        FOR I := 1 TO NoOfSlices DO BEGIN
            IF Quadrant(PieSpec[I].LabelLineAngle) = 1 THEN BEGIN
                IF NOT FirstOne THEN BEGIN
                    { if the difference in vertical offset < MinVertDistance then
                    make it equal to MinVertDistance
                    }
                    ThisY := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
                    LastY := YVal(PieSpec[I - 1].LabelLineAngle, PieSpec[I - 1].LabelLineLength);
                    IF (ABS(ThisY - LastY) < MinVertDistance) THEN
                        PieSpec[I].LabelLineLength := NewY(PieSpec[I].LabelLineAngle, LastY + MinVertDistance);
                END
                ELSE
                    FirstOne := FALSE;
            END;
        END;

        { Quadrant #2, we go in "reverse" order }
        FirstOne := TRUE;
        FOR I := NoOfSlices DOWNTO 1 DO BEGIN
            IF Quadrant(PieSpec[I].LabelLineAngle) = 2 THEN BEGIN
                IF NOT FirstOne THEN BEGIN
                    { if the difference in vertical offset < MinVertDistance then
                    make it equal to MinVertDistance
                    }
                    ThisY := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
                    LastY := YVal(PieSpec[I + 1].LabelLineAngle, PieSpec[I + 1].LabelLineLength);
                    IF (ABS(ThisY - LastY) < MinVertDistance) THEN
                        PieSpec[I].LabelLineLength := NewY(PieSpec[I].LabelLineAngle, LastY + MinVertDistance);
                END
                ELSE
                    FirstOne := FALSE;
            END;
        END;

        { Quadrant #3, we go in "regular" order }
        FirstOne := TRUE;
        FOR I := 1 TO NoOfSlices DO BEGIN
            IF Quadrant(PieSpec[I].LabelLineAngle) = 3 THEN BEGIN
                IF NOT FirstOne THEN BEGIN
                    { if the difference in vertical offset < MinVertDistance then
                    make it equal to MinVertDistance
                    }
                    ThisY := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
                    LastY := YVal(PieSpec[I - 1].LabelLineAngle, PieSpec[I - 1].LabelLineLength);
                    IF (ABS(ThisY - LastY) < MinVertDistance) THEN
                        PieSpec[I].LabelLineLength := NewY(PieSpec[I].LabelLineAngle, LastY + MinVertDistance);
                END
                ELSE
                    FirstOne := FALSE;
            END;
        END;

        { Quadrant #4, we go in "reverse" order }
        FirstOne := TRUE;
        FOR I := NoOfSlices DOWNTO 1 DO BEGIN
            IF Quadrant(PieSpec[I].LabelLineAngle) = 4 THEN BEGIN
                IF NOT FirstOne THEN BEGIN
          { if the difference in vertical offset < MinVertDistance then
            make it equal to MinVertDistance
          }
                    ThisY := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
                    LastY := YVal(PieSpec[I + 1].LabelLineAngle, PieSpec[I + 1].LabelLineLength);
                    IF (ABS(ThisY - LastY) < MinVertDistance) THEN
                        PieSpec[I].LabelLineLength := NewY(PieSpec[I].LabelLineAngle, LastY + MinVertDistance);
                END
                ELSE
                    FirstOne := FALSE;
            END;
        END;
    END;

    {-------------------}

    FUNCTION TLJPie.CheckPointerVerticalDiffs(NoOfSlices     : BYTE;
                                              VAR PieSpec    : TPieArray;
                                              Radius,
                                              Rotation,
                                              MinVertDistance : INTEGER) : BOOLEAN;
        {---------------}

        FUNCTION YVal(InAngle, InLen : INTEGER) : INTEGER;
        BEGIN
            YVal := ROUND(SIN(InAngle * DegreesToRadians) * InLen);
        END;
    TYPE
        SepType        = RECORD
                             YVal           : INTEGER;
                             Quad           : BYTE;
                         END;
    VAR
        I,
        J              : BYTE;
        Sep            : ARRAY[1..10] OF SepType;

        TestHeight,
        CurMinHeight   : INTEGER;
    BEGIN
        { idea is, we calculate the vertical distance between each adjacent}
        { wedge, from a point 0.10" inside the circle on the line which    }
        { bisects the wedge                                                }
        FOR I := 1 TO 10 DO BEGIN
            Sep[I].YVal := 0;
            Sep[I].Quad := 1;
        END;

        FOR I := 1 TO NoOfSlices DO BEGIN
            WITH PieSpec[I] DO
                LabelLineAngle := ((StartAngle + Rotation) + (EndAngle + Rotation)) DIV 2;
        END;
        { 2. Set each pointerlength to the default }
        FOR I := 1 TO NoOfSlices DO BEGIN
            WITH PieSpec[I] DO
                { 8/31/93: This should be the radius + explosion - .1"  }
                LabelLineLength := Radius + ExplByAngle(EndAngle - StartAngle, Radius) - 60;
        END;

        FOR I := 1 TO NoOfSlices DO BEGIN
            Sep[I].Quad := Quadrant(PieSpec[I].LabelLineAngle);
            Sep[I].YVal := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
        END;

        { The trick is, we compare quadrants 4 and 1 as a continuum, and }
        { quadrants 3 and 2 as a continuum to look for unacceptable      }
        { vertical heights                                               }

        { actually, to be perfectly lazy, we only need to look for the   }
        { smallest difference between *any* two values in each set of    }
        { 2 quadrants                                                    }

        FOR I := 1 TO NoOfSlices DO BEGIN
            IF (Quadrant(PieSpec[I].LabelLineAngle) = 1) OR (Quadrant(PieSpec[I].LabelLineAngle) = 4) THEN
                Sep[I].Quad := 1
            ELSE
                Sep[I].Quad := 2;
            Sep[I].YVal := YVal(PieSpec[I].LabelLineAngle, PieSpec[I].LabelLineLength);
        END;

        CurMinHeight := 10000;

        FOR I := 1 TO NoOfSlices DO BEGIN
            FOR J := 1 TO NoOfSlices DO BEGIN
                IF (I <> J) AND (Sep[I].Quad = Sep[J].Quad) THEN BEGIN
                    TestHeight := ABS(Sep[I].YVal - Sep[J].YVal);
                    IF TestHeight < CurMinHeight THEN
                        CurMinHeight := TestHeight;
                END;
            END;
        END;

        CheckPointerVerticalDiffs := (CurMinHeight >= MinVertDistance);
    END;

    {-------------------}

    FUNCTION TLJPie.ButtOriented(NoOfSlices : BYTE; VAR PieSpec : TPieArray) : BOOLEAN;
    CONST
        ButtThreshold  = 10;
    VAR
        I,
        J,
        qA,
        qB             : BYTE;
        sA,
        SB             : INTEGER;
        ButtStatus     : BOOLEAN;
    BEGIN
        { if 2 adjacent slices are in Q1 and Q2 or Q3 and Q4 and if they are }
        { less than ButtThreshold degrees then return false                  }
        ButtStatus := FALSE;
        FOR I := 1 TO NoOfSlices DO BEGIN
            IF I < NoOfSlices THEN
                J := I + 1
            ELSE
                J := 1;
            qA := Quadrant(PieSpec[I].LabelLineAngle);
            qB := Quadrant(PieSpec[J].LabelLineAngle);
            sA := ABS(PieSpec[I].EndAngle - PieSpec[I].StartAngle);
            SB := ABS(PieSpec[J].EndAngle - PieSpec[J].StartAngle);
            IF ((qA = 1) AND (qB = 2)) OR
            ((qA = 2) AND (qB = 1)) OR
            ((qA = 3) AND (qB = 4)) OR
            ((qA = 4) AND (qB = 3)) THEN BEGIN
                IF (sA <= ButtThreshold) AND (SB <= ButtThreshold) THEN
                    ButtStatus := TRUE;
            END;
        END;
        ButtOriented := ButtStatus;
    END;

    {-------------------}

    CONSTRUCTOR TLJPie.Init(PrnInfo        : TPrnCfg;
                            VAR MyCOP      : CylonP;
                            Mode           : TxtGraf);
    BEGIN
        IF NOT TLaserJet.Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;
    END;

    {-------------------}

    PROCEDURE TLJPie.DrawPie(NoOfSlices     : BYTE;
                             PieSpec        : TPieArray;
                             XOrigin,
                             YOrigin,
                             Radius         : WORD;
                             Optimize,
                             DrawLabels,
                             DrawShadow     : BOOLEAN;
                             XShadow,
                             YShadow,
                             MinPointerLineLength,
                             MinVertDistance,
                             LabelLineStart : INTEGER;
                             BackgroundColor : BYTE;
                             TopCaption     : STRING;
                             TopFont        : FontTypeT;
                             TCColor        : TPrnColors;
                             BotCaption     : STRING;
                             BotFont        : FontTypeT;
                             BCColor        : TPrnColors;
                             XStretch,
                             YStretch       : WORD);

    VAR
        QisOK          : BOOLEAN; { Set by CP's routine when rotation is ok       }
        I              : BYTE;
        FillP          : REAL;
        XAsp,
        YAsp,
        Angle1,
        Angle2,
        LeaderLen      : WORD;
        A,
        B,
        AngDiff,
        Pushed,
        Rotation,
        Drv,
        Mode           : INTEGER;
    BEGIN
        Angle1 := 0;
        IF COP <> NIL THEN
            COP^.UpDate;

        IF MyOutMode = EPrnScreen THEN BEGIN
            SetFillStyle(SOLIDFill, BackgroundColor); { New style }
            Bar(0, 0, GetMaxX, GetMaxY);
        END;

        FOR I := 1 TO NoOfSlices DO BEGIN
            WITH PieSpec[I] DO BEGIN
                Angle2 := ((Percent * 360) DIV 100) + Angle1;
                StartAngle := Angle1;
                EndAngle := Angle2;
                Angle1 := Angle2;
            END;
        END;

        GetAspectRatio(XAsp, YAsp);

        XStretch := MaxWord(XStretch, 1);
        YStretch := MaxWord(YStretch, 1);

        SetAspectRatio(XAsp DIV XStretch, YAsp DIV YStretch);

        IF Optimize THEN BEGIN
            {Rotate till labels fit okay}
            Rotation := - 1;
            REPEAT
                IF COP <> NIL THEN
                    COP^.UpDate;
                INC(Rotation, 1);
                CalcPointers(NoOfSlices,
                             PieSpec,
                             MinPointerLineLength,
                             MinVertDistance,
                             Rotation); ;
                QisOK := CheckPointerVerticalDiffs(NoOfSlices,
                                                   PieSpec,
                                                   Radius,
                                                   Rotation,
                                                   MinVertDistance);
                IF QisOK THEN
                    QisOK := NOT ButtOriented(NoOfSlices, PieSpec);
            UNTIL QisOK OR (Rotation >= 360);
        END;


        IF DrawShadow THEN BEGIN
            {draw shadows in background}
            FOR I := 1 TO NoOfSlices DO BEGIN
                IF COP <> NIL THEN
                    COP^.UpDate;
                WITH PieSpec[I] DO BEGIN
                    SetColor(TranslateColor(tpcBLACK)); {edge color}
                    SetLineStyle(SolidLn, 0, 3);
                    SetFillStyle(SOLIDFill, TranslateColor(tpcBLACK));
                    A := PieSpec[I].StartAngle + Rotation;
                    B := PieSpec[I].EndAngle + Rotation;
                    AngDiff := B - A;
                    Pushed := ExplByAngle(B - A, Radius);
                    IF Percent <> 100 THEN
                        PieSlice(XShadow + XOrigin + XOffset(A, B, Pushed),
                                 YShadow + YOrigin - Yoffset(A, B, Pushed),
                                 A,
                                 B,
                                 Radius)
                    ELSE
                        FillEllipse(XShadow + XOrigin + XOffset(A, B, Pushed),
                                    YShadow + YOrigin - Yoffset(A, B, Pushed),
                                    Radius,
                                    Radius);
                END;
            END;

        END;

        {draw foreground pie slices (the actual data)}
        FOR I := 1 TO NoOfSlices DO BEGIN
            IF COP <> NIL THEN
                COP^.UpDate;
            WITH PieSpec[I] DO BEGIN
                SetColor(TranslateColor(tpcBLACK)); {edge color}
                SetLineStyle(SolidLn, 0, 0);
                SetFillStyle(Fill, TranslateColor(TPrnColors(Color)));

                A := PieSpec[I].StartAngle + Rotation;
                B := PieSpec[I].EndAngle + Rotation;
                AngDiff := B - A;
                Pushed := ExplByAngle(B - A, Radius);
                IF Percent <> 100 THEN
                    PieSlice(XOrigin + XOffset(A, B, Pushed),
                             YOrigin - Yoffset(A, B, Pushed),
                             A, B, Radius)
                ELSE
                    FillEllipse(XOrigin + XOffset(A, B, Pushed),
                                YOrigin - Yoffset(A, B, Pushed),
                                Radius,
                                Radius);
            END;
        END;

        IF TopCaption <> '' THEN BEGIN
            SetColor(TranslateColor(TCColor));
            SetTextStyle(TriplexFont, HorizDir, 1);
            {SetFont(TriplexFont, HorizDir, 7, 7, PtUnits);}
            SetFontSize(TopFont);
            SetTextJustify(CenterText, CenterText);
            OutTextXY(XOrigin, YOrigin - ROUND(Radius * 1.3), TopCaption)
        END;

        IF BotCaption <> '' THEN BEGIN
            SetColor(TranslateColor(BCColor));
            SetTextStyle(TriplexFont, HorizDir, 1);
            {SetFont(TriplexFont, HorizDir, 7, 7, PtUnits);}
            SetFontSize(BotFont);
            SetTextJustify(CenterText, CenterText);
            OutTextXY(XOrigin, YOrigin + ROUND(Radius * 1.3), BotCaption)
        END;

        IF DrawLabels THEN BEGIN
            {SetTextStyle(TriplexFont, HorizDir, 1);}
            SetFontSize(TopFont);
            {SetFont(TriplexFont, HorizDir, 7, 7, PtUnits);}

            {Do graphic labels for DJ}
            LeaderLen := GetMaxX DIV 20;

            SetColor(TranslateColor(tpcBLACK));
            SetFillStyle(SOLIDFill, TranslateColor(tpcBLACK));
            SetLineStyle(SolidLn, 0, 2);

            FOR I := 1 TO NoOfSlices DO BEGIN
                IF COP <> NIL THEN
                    COP^.UpDate;
                WITH PieSpec[I] DO BEGIN
                    A := PieSpec[I].StartAngle + Rotation;
                    B := PieSpec[I].EndAngle + Rotation;
                    CASE Quadrant(LabelLineAngle) OF
                        1,
                        4 :
                            BEGIN
                                MoveTo(XOrigin + XOffset(A, B, Pushed + LabelLineStart),
                                       YOrigin - Yoffset(A, B, Pushed + LabelLineStart));
                                LineRel(LeaderLen, 0);
                                SetTextJustify(LeftText, CenterText);
                                OutText(' ' + Tag);
                            END;
                        2,
                        3 :
                            BEGIN
                                MoveTo(XOrigin + XOffset(A, B, Pushed + LabelLineStart),
                                       YOrigin - Yoffset(A, B, Pushed + LabelLineStart));
                                LineRel(- LeaderLen, 0);
                                SetTextJustify(RightText, CenterText);
                                OutText(' ' + Tag);
                            END;
                    END;
                END;
            END;
        END;
        SetColor(TranslateColor(tpcBLACK));
        SetFillStyle(SOLIDFill, TranslateColor(tpcBLACK));
        SetAspectRatio(XAsp, YAsp);
    END;
END.
