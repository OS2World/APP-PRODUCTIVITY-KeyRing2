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
*
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F-,G-,I+,N-,O+,P-,Q+,T-,V+,X+,Y+}
UNIT DGHPPRN;
INTERFACE

USES
    DGPRINT,
    GLOBTYPE,
    KERROR,
    LJVAR,
    OpString;

TYPE
    THPPRN         = OBJECT(TPrinter)
                         CONSTRUCTOR Init(PrnInfo        : TPrnCfg;
                                          VAR MyCOP      : CylonP;
                                          Mode           : TxtGraf);

                         DESTRUCTOR Done; VIRTUAL;

                             {-Enter HPGL/2 graphics mode }
                         PROCEDURE GoHPGL; VIRTUAL;

                             {-Return to PCL command mode }
                         PROCEDURE GoPCL; VIRTUAL;

                             {-Reset the printer}
                         PROCEDURE ResetPrn; VIRTUAL;

                             {-Update the cursor position...X and Y specified in inches }
                         FUNCTION PrnGotoXY(CONST X, Y : REAL) : BOOLEAN; VIRTUAL;

                             {-Update the horizontal cursor position }
                         FUNCTION PrnGotoX(CONST X : REAL) : BOOLEAN; VIRTUAL;

                             {-Update the vertical cursor position }
                         FUNCTION PrnGotoY(CONST Y : REAL) : BOOLEAN; VIRTUAL;

                             {runlength encoding compression of line }
                         PROCEDURE RLECompress(VAR Line; Len : WORD);

                             {TIFF compression of line}
                         PROCEDURE TIFFCompress(VAR V; Len : WORD);

                             {draw a shaded box using raster or high level commands}
                         PROCEDURE DrawRasterBox(X,
                                                 Y              : REAL;
                                                 Border,
                                                 DropShadow     : BOOLEAN;
                                                 PctGray,
                                                 Hyt,
                                                 Width          : REAL); VIRTUAL;

                         PROCEDURE AssignFontID(IDNo : FontTypeT); VIRTUAL;
                         PROCEDURE MakeFontTemporary; VIRTUAL;
                         PROCEDURE MakeFontPermanent; VIRTUAL;
                         FUNCTION ClearHorizontalMargins : BOOLEAN; VIRTUAL;
                         FUNCTION PrnAdvanceX(CONST Delta : REAL) : BOOLEAN; VIRTUAL;
                         FUNCTION PrnAdvanceY(CONST Delta : REAL) : BOOLEAN; VIRTUAL;
                         PROCEDURE SetHMI(CONST Inches : REAL); VIRTUAL;
                         PROCEDURE SetVMI(CONST Inches : REAL); VIRTUAL;
                         FUNCTION HLine(CONST X, Y, Width : REAL) : BOOLEAN; VIRTUAL;
                         FUNCTION ljRectDimensions(CONST WidthInDP, HeightInDP : REAL) : BOOLEAN; VIRTUAL;
                         FUNCTION ljFillRect(CONST Fill : RectFillType) : BOOLEAN; VIRTUAL;
                         PROCEDURE ThickHLine(CONST X, Y, Width : REAL); VIRTUAL;
                         PROCEDURE VLine(CONST X, Y, Height : REAL); VIRTUAL;
                         PROCEDURE ThickVLine(CONST X, Y, Height : REAL); VIRTUAL;
                         PROCEDURE Box(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN); VIRTUAL;
                         FUNCTION ljPatternShade(CONST Percent : BYTE) : BOOLEAN; VIRTUAL;
                         PROCEDURE BoxThick(CONST Width, Height : REAL; CONST PctGray : BYTE); VIRTUAL;
                         PROCEDURE BoxShadow(CONST X, Y, Width, Height : REAL;
                                             CONST PctGray : BYTE; Border : BOOLEAN); VIRTUAL;
                         PROCEDURE DoubleBox(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE); VIRTUAL;
                         FUNCTION GetDevName : STRING; VIRTUAL;
                         PROCEDURE SelectTray(T : TLetterHeadTray); VIRTUAL;
                         PROCEDURE SetTrays(Ltr, Blnk : TLetterHeadTray); VIRTUAL;
                         PROCEDURE SelectTrayDeluxe(Tray : TPaperStyle); VIRTUAL;
                         PROCEDURE SelectTextColor(C : TPrnColors); VIRTUAL;
                         PROCEDURE SelectTextMonoChrome; VIRTUAL;
                         PROCEDURE SetFormLen(CONST L : LONGINT); VIRTUAL;
                     PRIVATE

                         FUNCTION HPInitPrim(PrnInfo        : TPrnCfg;
                                             VAR MyCOP      : CylonP;
                                             Mode           : TxtGraf) : BOOLEAN;

                     END;

IMPLEMENTATION

    PROCEDURE THPPRN.RLECompress(VAR Line; Len : WORD);
    VAR
        RunCt,
        I,
        J              : WORD;
        LAST,
        B              : BYTE;
        Strg           : STRING;
        RasterLine     : ARRAY[1..65520] OF BYTE ABSOLUTE Line;
    BEGIN
        I := 1;
        RunCt := 0;
        LAST := RasterLine[1];
        FOR I := 2 TO Len DO BEGIN
            B := RasterLine[I];
            IF B = LAST THEN
                INC(RunCt)
            ELSE BEGIN
                PrnPutBlock(RasterLine[I], Len);
                RunCt := 0;
            END;
        END;
    END;

    {-----------------}

    PROCEDURE THPPRN.TIFFCompress(VAR V; Len : WORD);
    VAR
        RunCt,
        I,
        J              : WORD;
        LAST,
        B              : BYTE;
        Strg           : STRING;
    BEGIN
        (*
        I := 1;
        RunCt := 0;
        Last := V[1];
        FOR I := 1 TO Len DO BEGIN
            B := V[I];
            IF B = Last THEN
                INC(RunCt)
            ELSE BEGIN
                PrnPutBlock(V[ BlockSize : WORD);
            END;
        END;
        *)
    END;

    {-----------------}

    PROCEDURE THPPRN.AssignFontID(IDNo : FontTypeT);
    BEGIN
        PutStr(#27 + '*c' + Long2Str(BYTE(IDNo) + 1) + 'D');
    END;

    {-------------}

    PROCEDURE THPPRN.MakeFontTemporary;
    BEGIN
        PutStr(#27 + '*c4F');
    END;

    {-------------}

    PROCEDURE THPPRN.MakeFontPermanent;
    BEGIN
        PutStr(#27 + '*c5F');
    END;

    {-------------}

    PROCEDURE THPPRN.GoHPGL;
        {-Enter HPGL/2 graphics mode }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PutStr(#27'%1BIN;SP1;');
    END;

    {-----------------}

    PROCEDURE THPPRN.GoPCL;
        {-Return to PCL command mode }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PutStr(#27'%0A');
    END;

    {-----------------}

    {-Reset the left and right margins to their default }
    FUNCTION THPPRN.ClearHorizontalMargins : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        ClearHorizontalMargins := PutStr(#27'9');
    END;

    {-----------------}

    {-Update the cursor position...X and Y specified in inches }
    FUNCTION THPPRN.PrnGotoXY(CONST X, Y : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;

        PrnGotoXY := PutStr(#27'&a' + PrnRealStr(InToDP(X -
                                                        P1P2[EPrnTxt].LEFT)) +
                            'h' +
                            PrnRealStr(InToDP(Y -
                                              P1P2[EPrnTxt].TOP)) +
                            'V');
        CurRow := Y;
        CurColumn := X;
    END;

    {-----------------}

    {-Update the horizontal cursor position }
    FUNCTION THPPRN.PrnGotoX(CONST X : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PrnGotoX := PutStr(#27'&a' + PrnRealStr(InToDP(X - P1P2[EPrnTxt].LEFT)) + 'H');
        CurColumn := X;
    END;

    {-----------------}

    {-Update the vertical cursor position }
    FUNCTION THPPRN.PrnGotoY(CONST Y : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PrnGotoY := PutStr(#27'&a' + PrnRealStr(InToDP(Y - P1P2[EPrnTxt].TOP)) + 'V');
        CurRow := Y;
    END;

    {-----------------}

    {-Advance the X cursor by Delta inches }
    FUNCTION THPPRN.PrnAdvanceX(CONST Delta : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF (Delta < 0) THEN
            PrnAdvanceX := PutStr(#27'&a-' + PrnRealStr(InToDP(Delta)) + 'H')
        ELSE IF (Delta > 0) THEN
            PrnAdvanceX := PutStr(#27'&a+' + PrnRealStr(InToDP(Delta)) + 'H');
        CurColumn := CurColumn + Delta;
    END;

    {-----------------}

    {-Advance the Y cursor by Delta inches }
    FUNCTION THPPRN.PrnAdvanceY(CONST Delta : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF (Delta < 0) THEN
            PrnAdvanceY := PutStr(#27'&a-' + PrnRealStr(InToDP(ABS(Delta))) + 'V')
        ELSE IF (Delta > 0) THEN
            PrnAdvanceY := PutStr(#27'&a+' + PrnRealStr(InToDP(Delta)) + 'V');
        CurRow := CurRow + Delta;

    END;

    {-----------------}

    PROCEDURE THPPRN.SetHMI(CONST Inches : REAL);
        {-Set the horizontal motion index }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        PutStr(#27'&k' + PrnRealStr(Inches * 120) + 'H');
    END;

    {-----------------}

    PROCEDURE THPPRN.SetVMI(CONST Inches : REAL);
        {-Set the vertical motion index }
    BEGIN
        PutStr(#27'&l' + PrnRealStr(Inches * 48) + 'C');
    END;

    {-----------------}

    {-Draw a horizontal line at X,Y that is Width inches long }
    FUNCTION THPPRN.HLine(CONST X, Y, Width : REAL) : BOOLEAN;
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        HLine := TRUE;
        IF NOT ljCanBox THEN
            EXIT;
        HLine := FALSE;
        IF NOT PrnGotoXY(X, Y) THEN
            EXIT;
        ljRectDimensions(InToDP(Width), DotsToDP(3));
        ljFillRect(BlackFill);
        IF COP <> NIL THEN
            COP^.UpDate;
    END;

    {-----------------}

    PROCEDURE THPPRN.ThickHLine(CONST X, Y, Width : REAL);
        {-Draw a thick horizontal line at X,Y that is Width inches long }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT ljCanBox THEN
            EXIT;
        PrnGotoXY(X, Y);
        ljRectDimensions(InToDP(Width), DotsToDP(6));
        ljFillRect(BlackFill);
    END;

    {-----------------}

    PROCEDURE THPPRN.VLine(CONST X, Y, Height : REAL);
        {-Draw a vertical line at X,Y that is Height inches long }
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT ljCanBox THEN
            EXIT;
        PrnGotoXY(X, Y);
        ljRectDimensions(DotsToDP(3), InToDP(Height));
        ljFillRect(BlackFill);
    END;

    {-----------------}

    {-Draw a thick vertical line at X,Y that is Height inches long }
    PROCEDURE THPPRN.ThickVLine(CONST X, Y, Height : REAL);
    BEGIN
        IF COP <> NIL THEN
            COP^.UpDate;
        IF NOT ljCanBox THEN
            EXIT;
        PrnGotoXY(X, Y);
        ljRectDimensions(DotsToDP(6), InToDP(Height));
        ljFillRect(BlackFill);
    END;

    {-----------------}

    {-Draw a box, filling it if necessary }
    PROCEDURE THPPRN.Box(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN);
    BEGIN
        IF NOT ljCanBox THEN
            EXIT;

        IF COP <> NIL THEN
            COP^.UpDate;

        IF Border THEN BEGIN
            HLine(X, Y, Width);
            HLine(X, (Y + Height) - 0.01, Width);
            VLine(X, Y, Height);
            VLine((X + Width) - 0.01, Y, Height);
        END;

        IF (PctGray > 0) THEN BEGIN
            PrnGotoXY(X, Y);
            ljRectDimensions(InToDP(Width), InToDP(Height));
            ljPatternShade(PctGray);
            ljFillRect(ShadedFill);
        END;

    END;

    {-----------------}

    {-Draw a thick box at the current cursor location, filling it if necessary }
    PROCEDURE THPPRN.BoxThick(CONST Width, Height : REAL; CONST PctGray : BYTE);
    BEGIN
        IF NOT ljCanBox THEN
            EXIT;

        IF COP <> NIL THEN
            COP^.UpDate;
        IF (PctGray > 0) THEN BEGIN
            ljRectDimensions(InToDP(Width), InToDP(Height));
            ljPatternShade(PctGray);
            ljFillRect(ShadedFill);
        END;

        ThickHLine(CurColumn, CurRow, Width);
        ThickHLine(CurColumn, (CurRow + + Height) - 0.02, Width);
        ThickVLine(CurColumn, CurRow, Height);
        ThickVLine((CurColumn + Width) - 0.02, CurColumn, Height);
    END;

    {-----------------}

    {-Draw a box, filling it if desired, with a shadow on it }
    PROCEDURE THPPRN.BoxShadow(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE; Border : BOOLEAN);
    VAR
        DPY            : REAL;

    BEGIN
        IF NOT ljCanBox THEN
            EXIT;

        Box(X, Y, Width, Height, PctGray, Border);
        ThickHLine(X + DotsToIn(6), Y + Height, Width);
        ThickHLine(X + DotsToIn(6), Y + Height + DotsToIn(3), Width);
        ThickVLine(X + Width, Y + DotsToIn(6), Height);
        ThickVLine(X + Width + DotsToIn(3), Y + DotsToIn(6), Height);
    END;

    {-----------------}

    {-Draw a double lined box }
    PROCEDURE THPPRN.DoubleBox(CONST X, Y, Width, Height : REAL; CONST PctGray : BYTE);
    VAR
        TenDots        : REAL;

    BEGIN
        IF NOT ljCanBox THEN
            EXIT;

        TenDots := DotsToIn(10);
        Box(X, Y, Width, Height, 0, FALSE);
        Box(X + TenDots, Y + TenDots, Width - (TenDots * 2), Height - (TenDots * 2), PctGray, TRUE);
    END;

    {-----------------}

    (*
    {-Output a block of text, word wrapped to fit margins}
    {OBSOLETE!  Use DGRPT instead!}
    PROCEDURE THPPRN.OutputTextWrapped(CONST Buf : PCHAR; CONST LEFT, RIGHT : REAL; CurPage : WORD; Just : JustT);
    VAR
        OnChar         : WORD;
        NewPos,
        R,
        FmtWidth,
        Width,
        MaxWidth       : REAL;
        LastDelimPos   : WORD;
        LastDelim      : BYTE;
        Fmt,
        OutSt          : STRING;
        Center,
        Bold,
        Ul,
        Ital           : BOOLEAN;

    CONST
        DelimSet       = ['`', '~', '!', '@', '#', '%', '^', '&', '*', '=', '+', '\',
        '|', ']', '[', '{', '}', '''', ';', ':', '"', '<', '>', ',', '.',
        '/', '?', ' '];
        PROCEDURE ClearAttrib;
        BEGIN
            PutStr(StringFromHeap(ljBoldOff));
            PutStr(StringFromHeap(ljItalOff));
            PutStr(StringFromHeap(ljULOff));
        END;

        PROCEDURE RestoreAttrib;
        BEGIN
            IF Bold THEN
                Fmt := StringFromHeap(ljBoldOn)
            ELSE
                Fmt := StringFromHeap(ljBoldOff);
            PutStr(Fmt);
            IF Ital THEN
                Fmt := StringFromHeap(ljItalOn)
            ELSE
                Fmt := StringFromHeap(ljItalOff);
            PutStr(Fmt);
            IF Ul THEN
                Fmt := StringFromHeap(ljULOn)
            ELSE
                Fmt := StringFromHeap(ljULOff);
            PutStr(Fmt);
        END;

        PROCEDURE MicrospaceLine;
        VAR
            I              : BYTE;
            Strg           : STRING;
        BEGIN
            FOR I := 1 TO WordCount(OutSt, [' ']) DO
                Strg := ExtractWord(I, OutSt, [' ']);
        END;

        PROCEDURE PutItOut;
        BEGIN
            IF Buf[OnChar] <> #13 THEN BEGIN
                OnChar := LastDelimPos + 1;
                OutSt[0] := CHAR(LastDelim);
            END;

            OutSt := TrimSpaces(OutSt);

            {do a page feed and number it, as we would go over with this line}
            IF CurRow >= (CurBottomMargin - ljActiveFont^.GetLineSpacing) THEN BEGIN
                ClearAttrib;
                DoPageNumAndFF;
                RestoreAttrib;
            END;

            {move cp to center line, if necessary}
            IF Center THEN
                PrnGotoX(CurLeftMargin + (((CurRightMargin - CurLeftMargin) - Width) / 2.0));

            IF Just = ELEFT THEN
                {output the line}
                PutLine(OutSt)
            ELSE
                MicrospaceLine;


            {clear the line buffer}
            OutSt := '';
            LastDelim := 0;
            {scan for next printable character}
            REPEAT
                CASE Buf[OnChar] OF
                    #0,
                    ' ' :
                        BREAK;
                    #13 :
                        BEGIN
                            IF NOT LineFeed(NewPos) THEN BEGIN
                                PostPrnError(Iam);
                                EXIT;
                            END;
                            INC(OnChar);
                            CONTINUE;
                        END;
                    #10 : ;
                    ELSE BEGIN
                        DEC(OnChar);
                        BREAK;
                    END;
                END;
                INC(OnChar);
            UNTIL FALSE;
            FmtWidth := 0.0;
            Width := 0.0;
            Center := FALSE;
        END;

    BEGIN
        IF CurPage <> 0 THEN
            CurPageNum := CurPage;
        OnChar := 0;
        OutSt := '';
        LastDelim := 0;
        LastDelimPos := 0;
        FmtWidth := 0.0;
        MaxWidth := RIGHT - LEFT;
        Bold := FALSE;
        Ul := FALSE;
        Ital := FALSE;
        Center := FALSE;

        SetLeftMargin(LEFT);
        SetRightMargin(RIGHT);
        {PrnGotoXY(CurLeftMargin, CurTopMargin);}

        WHILE (Buf[OnChar] <> #0) DO BEGIN
            IF COP <> NIL THEN
                COP^.UpDate;
            CASE Buf[OnChar] OF
                #10 :
                    INC(OnChar);
                #13 :
                    BEGIN
                        IF (OutSt <> '') THEN
                            PutItOut
                        ELSE
                            IF NOT LineFeed(NewPos) THEN BEGIN
                                PostPrnError(Iam);
                                EXIT;
                            END;
                        IF Buf[OnChar] = #0 THEN
                            CONTINUE;
                        INC(OnChar);
                        Center := FALSE;
                        CONTINUE;
                    END;
                CenterTok :       {Center line between margins (entire line must fit!)}
                    BEGIN
                        Center := TRUE;
                        INC(OnChar);
                    END;
                BoldTok :         {toggle bold}
                    BEGIN
                        Bold := NOT Bold;
                        IF Bold THEN
                            Fmt := StringFromHeap(ljBoldOn)
                        ELSE
                            Fmt := StringFromHeap(ljBoldOff);
                        FmtWidth := FmtWidth + ComputeStringWidth(Fmt, CtrlForceToSpace);
                        OutSt := OutSt + Fmt;
                        INC(OnChar);
                        CONTINUE;
                    END;
                ULTok :           {toggle underline}
                    BEGIN
                        Ul := NOT Ul;
                        IF Ul THEN
                            Fmt := StringFromHeap(ljULOn)
                        ELSE
                            Fmt := StringFromHeap(ljULOff);
                        FmtWidth := FmtWidth + ComputeStringWidth(Fmt, CtrlForceToSpace);
                        OutSt := OutSt + Fmt;
                        INC(OnChar);
                        CONTINUE;
                    END;
                ItalicTok :       {toggle italics}
                    BEGIN
                        Ital := NOT Ital;
                        IF Ital THEN
                            Fmt := StringFromHeap(ljItalOn)
                        ELSE
                            Fmt := StringFromHeap(ljItalOff);
                        FmtWidth := FmtWidth + ComputeStringWidth(Fmt, CtrlForceToSpace);
                        OutSt := OutSt + Fmt;
                        INC(OnChar);
                    END;
                #9 :              {tab - set to every 1/2"}
                    BEGIN
                        LastDelimPos := OnChar;
                        IF FRAC(Width) < 0.5 THEN
                            R := TRUNC(Width) + 0.5
                        ELSE
                            R := ROUND(Width + 0.5);

                        FmtWidth := FmtWidth - (R - Width);

                        Fmt := #27'&a' + PrnRealStr(InToDP(R - P1P2[EPrnTxt].LEFT + CurLeftMargin)) + 'H';
                        FmtWidth := FmtWidth + ComputeStringWidth(Fmt, CtrlForceToSpace);
                        OutSt := OutSt + Fmt;
                        Width := ComputeStringWidth(OutSt, CtrlForceToSpace) - FmtWidth;
                        IF (Width > MaxWidth) THEN
                            PutItOut
                        ELSE
                            INC(OnChar);
                    END;
                #12 :             {formfeed}
                    BEGIN
                        LastDelimPos := OnChar;
                        PutItOut;
                        ClearAttrib;
                        DoPageNumAndFF;
                        RestoreAttrib;
                        INC(OnChar);
                    END;
                ELSE BEGIN
                    ChrCat(OutSt, Buf[OnChar]);
                    IF (Buf[OnChar] IN DelimSet) THEN BEGIN
                        IF NOT((Buf[OnChar] = ',') AND NOT(Buf[SUCC(OnChar)] = ' ')) THEN BEGIN
                            LastDelimPos := OnChar;
                            LastDelim := LENGTH(OutSt);
                        END;
                    END;

                    Width := ComputeStringWidth(OutSt, CtrlForceToSpace) - FmtWidth;
                    IF (Width > MaxWidth) THEN
                        PutItOut
                    ELSE
                        INC(OnChar);
                END;
            END;
        END;

        IF (OutSt <> '') THEN BEGIN
            PutStr(TrimSpaces(OutSt));
            PrnAdvanceY(ljActiveFont^.GetLineSpacing);
            PrnGotoX(LEFT);
        END;
    END;
    *)

    FUNCTION THPPRN.ljPatternShade(CONST Percent : BYTE) : BOOLEAN;
    BEGIN
        ljPatternShade := PutStr(#27'*c' + Long2Str(Percent) + 'G');
    END;

    {-----------------}

    FUNCTION THPPRN.ljRectDimensions(CONST WidthInDP, HeightInDP : REAL) : BOOLEAN;
        {-Specify the parameters of the print model rectangle }
    BEGIN
        ljRectDimensions := PutStr(#27'*c' + PrnRealStr(WidthInDP) + 'h' + PrnRealStr(HeightInDP) + 'V');
    END;

    {-----------------}

    FUNCTION THPPRN.ljFillRect(CONST Fill : RectFillType) : BOOLEAN;
        {-Fill the previously specified rectangle }
    VAR
        Cmd            : CHAR;

    BEGIN
        IF (Fill = NoFill) THEN
            EXIT;
        CASE Fill OF
            BlackFill :
                Cmd := '0';
            EraseFill :
                Cmd := '1';
            ShadedFill :
                Cmd := '2';
            CrossHatchFill :
                Cmd := '3';
            UserDefFill :
                Cmd := '4';
            CurrentPatFill :
                Cmd := '5';
        END;
        ljFillRect := PutStr(#27'*c' + Cmd + 'P');
    END;

    {-----------------}

    FUNCTION THPPRN.GetDevName : STRING;
    BEGIN
        GetDevName := 'Unknown';
        CASE PType OF
            HPLJ2,
            HPLJ3,
            HPLJ4 :
                GetDevName := 'HPLJET';
            HPDJ :
                GetDevName := 'HPDJET';
            HPDJC :
                GetDevName := 'HPDJETC';

        END;                      {CASE}
    END;

    {-----------------}

    {reset the printer to known state - ejects page if partial}
    PROCEDURE THPPRN.ResetPrn;
    BEGIN
        PutStr(#27'E');
    END;

    {-----------------}

    {low level tray selection.  At this level we dont know which     }
    {tray or source has letterhead / blank paper.  Abstraction layer }
    {is in methods found below...                                    }
    PROCEDURE THPPRN.SelectTray(T : TLetterHeadTray);
    BEGIN
        CASE PType OF
            HPLJ3,
            HPLJ4 :
                BEGIN
                    CASE T OF
                        TLHSingle, {single tray printer}
                        TLHTop :  {select top tray of dual tray}
                            PutStr(#27'&l1H');
                        TLHManEnvFeed : {select manual envelope feeder}
                            PutStr(#27'&l2H');
                        TLHMan :  {select man paper feed}
                            PutStr(#27'&l3H');
                        TLHBottom : {select bottom tray of dual tray}
                            PutStr(#27'&l4H');
                        TLHOpt :  {select optional paper source}
                            PutStr(#27'&l5H');
                        TLHEnvFeed : {select automatic envelope feeder}
                            PutStr(#27'&l6H');
                    END;
                END;
        END;                      {case}
    END;

    {-----------------}

    {initialize the Letterhead and Blank paper trays }
    {Infer blank tray if not known                   }
    PROCEDURE THPPRN.SetTrays(Ltr, Blnk : TLetterHeadTray);
    BEGIN
        MyLetterHeadTray := Ltr;
        IF Blnk <> TLHUnknown THEN
            MyBlankTray := Blnk
        ELSE BEGIN
            {don't know, so derive the blank page from the top setting}
            CASE Ltr OF
                TLHManEnvFeed,
                TLHMan,
                TLHBottom,
                TLHOpt,
                TLHEnvFeed,
                TLHSingle :
                    MyBlankTray := TLHSingle;
                TLHTop :
                    MyBlankTray := TLHBottom;
            END;
        END;
    END;

    {-----------------}

    {select a paper type - letterhead or blank}
    PROCEDURE THPPRN.SelectTrayDeluxe(Tray : TPaperStyle);
    BEGIN
        CASE Tray OF
            ELetterhead :
                SelectTray(MyLetterHeadTray);
            EBlank :
                SelectTray(MyBlankTray);
        END;
    END;

    {-----------------}

    {select a text color}
    PROCEDURE THPPRN.SelectTextColor(C : TPrnColors);
    BEGIN
        IF ljIsColor THEN
            PutStr(#27'*p0P'#27'*r3U'#27'*v' +
                   Long2Str(MyRGBTextWheel[C]) +
                   'S');
    END;

    {-----------------}

    {force printer back into black&white text mode}
    PROCEDURE THPPRN.SelectTextMonoChrome;
    BEGIN
        IF ljIsColor THEN
            PutStr(#27'*p0P'#27'*r1U');
    END;

    {-----------------}

    PROCEDURE THPPRN.DrawRasterBox(X,
                                   Y              : REAL;
                                   Border,
                                   DropShadow     : BOOLEAN;
                                   PctGray,
                                   Hyt,
                                   Width          : REAL);
    VAR
        RightEdge,
        H,
        W,
        I,
        J              : WORD;
        LineBuf        : ARRAY[1..320] OF BYTE;
        Tb,
        GrayLevel      : BYTE;
        ShadowSize     : REAL;
        ShadowPixels   : WORD;
    BEGIN
        IF ljCanBox THEN BEGIN
            Box(X, Y, Width, Hyt, ROUND(PctGray), Border);
            EXIT;
        END;

        ShadowSize := 0.125;

        ShadowPixels := ROUND(ShadowSize * 300);
        GrayLevel := ROUND((PctGray / 11.1111) + 0.5);
        PrnGotoXY(X, Y);
        W := ROUND(Width * 300) DIV 8;
        H := ROUND(Hyt * 300);
        RightEdge := W;

        IF DropShadow THEN
            INC(W, (ShadowPixels DIV 8));

        SelectTextMonoChrome;

        PutStr(#27'*t300R' +
               #27'*rbC' +
               #27'*rb0M' +
               #27'*p' + Long2Str(ROUND((X - P1P2[EPrnTxt].LEFT) * 300)) + 'X' +
               #27'*p' + Long2Str(ROUND((Y - P1P2[EPrnTxt].TOP) * 300)) + 'Y' +
               #27'*r1A' +
               #27'*r' + Long2Str(W * 8) + 'S');

        FOR J := 1 TO H DO BEGIN
            PutStr(#27'*b' + Long2Str(W) + 'W');
            FILLCHAR(LineBuf, W, #0);
            IF Border THEN BEGIN
                IF (J < 5) OR (J > (H - 5)) THEN
                    {draw top or bottom edge line}
                    FILLCHAR(LineBuf, RightEdge, #255)
                ELSE BEGIN
                    {fix left and right edges so that the fill looks ok}
                    LineBuf[1] := $F0 OR (HalfTone(GrayLevel, 1, J) AND $F);
                    LineBuf[RightEdge] := $0F OR (HalfTone(GrayLevel, RightEdge, J) AND $F0);

                    {finish the fill in the center part of the box}
                    FOR I := 2 TO RightEdge - 1 DO
                        LineBuf[I] := HalfTone(GrayLevel, I, J);
                END;
            END
            ELSE
                {no border so just do the fill, edge to edge}
                FOR I := 1 TO RightEdge DO
                    LineBuf[I] := HalfTone(GrayLevel, I, J);
            IF DropShadow AND (J > ShadowPixels) THEN
                {fill in right side darker drop shadow}
                FOR I := RightEdge + 1 TO W DO
                    LineBuf[I] := HalfTone(GrayLevel + 2, I, J);
            PrnPutBlock(LineBuf, W);

        END;
        {we are one raster line below the bottom edge now}
        IF DropShadow THEN BEGIN
            {clean out the buffer}
            FILLCHAR(LineBuf, 10, #0);
            {make the bottom part of the drop shadow, offset by 1/4" to right}
            FOR J := 1 TO ShadowPixels DO BEGIN
                FOR I := 9 TO W DO
                    LineBuf[I] := HalfTone(GrayLevel + 2, I, J + H);
                {draw 1/4" high dropshadow}
                PutStr(#27'*b' + Long2Str(W) + 'W');
                PrnPutBlock(LineBuf, W);
            END;
        END;

        PutStr(#27'*rbC');
        PrnGotoXY(X, Y);          {ZZZZ}
    END;

    {-----------------}

    CONSTRUCTOR THPPRN.Init(PrnInfo        : TPrnCfg;
                            VAR MyCOP      : CylonP;
                            Mode           : TxtGraf);
    BEGIN
        IF NOT INHERITED Init(PrnInfo, MyCOP, Mode) THEN
            FAIL;

        SetTrays(PrnInfo.TrayLtr, TLHUnknown);

        IF NOT AddFont(fLinePrint, 10,
                       MyFontPath + 'LPR0000S.CWD', #27'(10U'#27'(s0p12.0h0s0b4099T') THEN
            FAIL;

        IF NOT AddFont(fSmall, 8,
                       MyFontPath + 'TRR0000S.CWD', #27'(8U'#27'(s1P'#27'(s8.0V'#27'(s0S'#27'(s0B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fMain, 12,
                       MyFontPath + 'TRR0000S.CWD', #27'(8U'#27'(s1P'#27'(s12.0V'#27'(s0S'#27'(s0B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fItalic, 12,
                       MyFontPath + 'TRI0000S.CWD', #27'(8U'#27'(s1P'#27'(s12.0V'#27'(s1S'#27'(s0B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fBold, 12,
                       MyFontPath + 'TRB0000S.CWD', #27'(8U'#27'(s1P'#27'(s12.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fBoldItalic, 12,
                       MyFontPath + 'TRB0000S.CWD', #27'(8U'#27'(s1p12.0v1s3b4101T') THEN
            EXIT;

        IF NOT AddFont(fTable, 10,
                       MyFontPath + 'TRR0000S.CWD', #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s0B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fHuge, 16,
                       MyFontPath + 'TRB1600S.CWD',
                       #27'(8U'#27'(s1P'#27'(s16.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fHugeItalic, 16,
                       MyFontPath + 'TRB1600S.CWD',
                       #27'(8U'#27'(s1P'#27'(s16.0V'#27'(s1S'#27'(s3B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fMainMedium, 10,
                       MyFontPath + 'TRR0000S.CWD',
                       #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s0B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fItalicMedium, 10,
                       MyFontPath + 'TRI0000S.CWD',
                       #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s1S'#27'(s0B'#27'(s4101T') THEN
            EXIT;

        IF NOT AddFont(fBoldMedium, 10,
                       MyFontPath + 'TRB0000S.CWD', #27'(8U'#27'(s1P'#27'(s10.0V'#27'(s0S'#27'(s3B'#27'(s4101T') THEN
            EXIT;

        ljInitStr := StringToHeap(#27'E');
        ljULOn := StringToHeap(#27'&d0D');
        ljULOff := StringToHeap(#27'&d@');
        ljBoldOn := StringToHeap(#27'(s3B');
        ljBoldOff := StringToHeap(#27'(s0B');
        ljItalOn := StringToHeap(#27'(s1S');
        ljItalOff := StringToHeap(#27'(s0S');
        ljNewPage := StringToHeap(^L);

        ljActiveFont := FindFontByID(fMain);

    END;

    {-----------------}

    {call this instead, for descendent object init}
    FUNCTION THPPRN.HPInitPrim(PrnInfo        : TPrnCfg;
                               VAR MyCOP      : CylonP;
                               Mode           : TxtGraf) : BOOLEAN;
    BEGIN
    END;

    {-----------------}

    DESTRUCTOR THPPRN.Done;
    BEGIN
        INHERITED Done;
    END;

    {-----------------}

    PROCEDURE THPPRN.SetFormLen(CONST L : LONGINT);
    BEGIN
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}
