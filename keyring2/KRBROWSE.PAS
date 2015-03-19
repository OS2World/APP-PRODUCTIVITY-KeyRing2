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
UNIT krbrowse;

INTERFACE
USES
    DGCMD,
    FBrowse,
    Filer,
    KRDB,
    OoFiler,
    OpCRT,
    OpString,
    USE32,
    VARDEC;

TYPE
    PKR2Browser    = ^TKR2Browser;
    TKR2Browser    = OBJECT(FBrowser)
                         Filtering      : BOOLEAN;
                         ClientFilter   : TKR2Rec;
                         TmpClient      : TKR2Rec;
                         HFP            : PKR2DBFile;
                         LocalCP        : TDGUCommandProcessor;

                         CONSTRUCTOR Init(Clients : PKR2DBFile);
                         PROCEDURE BuildOneRow(Row : BYTE; VAR DatS; Len : WORD; RecNum : LONGINT;
                                               Key : IsamKeyStr; VAR S : STRING); VIRTUAL;
                         PROCEDURE ScreenUpdate; VIRTUAL;
                         FUNCTION ClientLine(VAR CL : TKR2Rec; Row : BYTE) : STRING;
                         FUNCTION IsFilteringEnabled : BOOLEAN; VIRTUAL;
                         FUNCTION RecordFilter(RecNum : LONGINT; Key : IsamKeyStr) : BOOLEAN; VIRTUAL;
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE DrawItem(Item : BYTE; Highlight : BOOLEAN); VIRTUAL;
                     PRIVATE
                         MyFAttrs,
                         MyHLFattrs     : FlexAttrs;
                     END;
IMPLEMENTATION
USES
    DGLIB,
    KRCOLOR,
    IsamTool,
    KERROR,
    OpCmd,
    OpCol16,
    OpDate,
    OpFrame,
    OpKey,
    OpMouse,
    OpWindow,
    UTIAM;

CONST
    tp_ccSort      = ccUser1;
    tp_ccPrn       = ccUser2;
    tp_ccHelp      = ccUser3;

    CONSTRUCTOR TKR2Browser.Init(Clients : PKR2DBFile);
    CONST
        RowsPerItem    = 3;       {Number of rows per browser item}
        MaxCols        = 78;      {Length of one row}
        Options        = wClear + wBordered;
    BEGIN
        {Add user-defined exit commands}

        IF NOT LocalCP.Init(@FBrowserKeySet, FBrowserKeyMax) THEN
            FAIL;

        WITH LocalCP DO BEGIN
            LocalCP.cpOptionsOn(cpUpcase);
            AddCommand(tp_ccSort, 1, UpS, 0);
            AddCommand(tp_ccPrn, 1, UpP, 0);
            AddCommand(tp_ccHelp, 1, F1, 0);

            AddCommand(ccNone, 1, LEFT, 0);
            AddCommand(ccNone, 1, RIGHT, 0);
            AddCommand(ccNone, 1, Home, 0);
            AddCommand(ccNone, 1, Endkey, 0);
        END;

        FILLCHAR(ClientFilter, SIZEOF(TKR2Rec), 0);
        FILLCHAR(TmpClient, SIZEOF(TKR2Rec), 0);
        HFP := Clients;

        {Initialize the browser}
        IF NOT FBrowser.InitCustom(2, {Left column of window}
                                   5, {Top row of window}
                                   ScreenWidth - 1,
                                   ScreenHeight - 3,
                                   FbColors2, {Color set}
                                   Options, {Window options}
                                   HFP^.IFB, {Fileblock}
                                   HFP^.glCurKeyNr, {Key number}
                                   TmpClient, {Scrap variable}
                                   ScreenHeight - 8, {Maximum rows}
                                   RowsPerItem, {Rows per item}
                                   MaxCols) {Maximum columns}
        THEN
            FAIL;

        {Not filtering initially}
        Filtering := TRUE;

        WITH wFrame DO BEGIN
            AdjustFrameCoords(frXl, 2, frXH, ScreenHeight);
            AddHeaderColor(' Hobbes File List ', heTC,
                           FbColors2.FrameColor, FbColors2.FrameMono);
            AddCustomScrollBar(frRR, 0, MAXLONGINT, 3, 4, #178, #176, FbColors2);
        END;

        {Options}
        fbOptionsOn(fbFlushKbd + fbProcessZero);
        fbOptionsOff(fbSelectOnClick);

        IF GetLastError <> 0 THEN
            FAIL;

        {Set up automatic screen refresh}
        {$IFDEF Novell}
        IF BTNetSupported = Novell THEN
            SetRefreshFunc(SemaphoreRefresh)
        ELSE
            SetRefreshFunc(RefreshPeriodically);
        {$ELSE}
        SetRefreshFunc(RefreshPeriodically);
        {$ENDIF}
        SetCommandProcessor(LocalCP);

        {no highlight bar}
        MyFAttrs[0] := LtGrayOnBlue; {norm}
        MyFAttrs[1] := LtGrayOnBlue; {^A Norm}
        MyFAttrs[2] := LtGreenOnBlue; {^B New}
        MyFAttrs[3] := YellowOnBlue; {^C Auction?}

        {browser highlight bar on item}
        MyHLFattrs[0] := YellowOnCyan; {norm}
        MyHLFattrs[1] := YellowOnCyan; {^A Norm}
        MyHLFattrs[2] := LtGreenOnCyan; {^B New}
        MyHLFattrs[3] := YellowOnCyan; {^C Auction?}
    END;

    {----------------}

    DESTRUCTOR TKR2Browser.Done;
    BEGIN
        LocalCP.Done;
        INHERITED Done;
    END;

    {----------------}

    FUNCTION TKR2Browser.IsFilteringEnabled : BOOLEAN;
    BEGIN
        IsFilteringEnabled := TRUE;
    END;

    {----------------}

    FUNCTION TKR2Browser.RecordFilter(RecNum : LONGINT; Key : IsamKeyStr) : BOOLEAN;
    VAR
        TstRec         : TKR2Rec;
    BEGIN
        RecordFilter := FALSE;
        HFP^.GetRec(RecNum, TstRec);
        IF NOT IsamOk THEN BEGIN
            DispErrorDeluxe('B-Tree ERROR',
                            IsamErrorMessage(IsamError),
                            TRUE, Iam);
            EXIT;
        END;
        RecordFilter := TRUE;
    END;

    {----------------}

    {-Draw the specified (relative) Item of the browse window}
    PROCEDURE TKR2Browser.DrawItem(Item : BYTE; Highlight : BOOLEAN);
    VAR
        S              : STRING;
        SLen           : BYTE ABSOLUTE S;
        Attr           : BYTE;
        R,
        fRow,
        LRow,
        Start,
        I,
        W              : WORD;
        {$IFDEF UseMouse}
        SaveMouse      : BOOLEAN;
        {$ENDIF}
    BEGIN
        {calculate first and last rows}
        fRow := SUCC(PRED(Item) * fbRowsPerItem);

        IF (Item = 0) OR (fRow > Height) THEN
            EXIT;

        INC(fRow, PRED(wYL));

        LRow := fRow + PRED(fbRowsPerItem);

        {$IFDEF UseMouse}
        HideMousePrim(SaveMouse);
        {$ENDIF}

        {get the string}
        W := Width;

        IF Item > fbMaxItems THEN BEGIN
            Attr := ColorMono(wTextColor, wTextMono);
            FOR R := fRow TO LRow DO
                FastFill(W - 1 {!!.KVN} , ' ', R + PRED(wYL), wXL, Attr);
        END
        ELSE BEGIN
            IF Highlight THEN
                Attr := ColorMono(fbSelColor, fbSelMono)
            ELSE
                Attr := ColorMono(fbItemColor, fbItemMono);

            {calculate starting column for the text we want}
            Start := SUCC(fbColOfs) - PRED(fbFirstCol);

            FOR I := 1 TO fbRowsPerItem DO BEGIN
                {extract the appropriate substring}
                S := GetItemString(Item, I);

                {adjust the string as necessary}
                S := PadTrimCtrl(S, W);
                {draw the string}
                IF Highlight THEN
                    FlexWrite(S, fRow + PRED(I), wXL, MyHLFattrs)
                ELSE
                    FlexWrite(S, fRow + PRED(I), wXL, MyFAttrs);

            END;
        END;

        {$IFDEF UseMouse}
        ShowMousePrim(SaveMouse);
        {$ENDIF}
    END;

    {---------------}

    FUNCTION TKR2Browser.ClientLine(VAR CL : TKR2Rec; Row : BYTE) : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        WITH CL.CryptRec DO BEGIN
            CASE Row OF
                1 :
                    Strg := Pad('    ' + Description, 78);
                2 :
                    Strg := Pad(^B + Pad(UserID, 38) + ^B +
                                Pad(Password, 10) +
                                DateToDateString('nnn dd yyyy', LastUpdate.D) +
                                ' ' +
                                TimeToTimeString('hh:mm', LastUpdate.T), 78);
                3 :
                    Strg := ^C + Pad('    ' + COPY(SerialNumber, 1, 71), 78) + ^C;
            END;
        END;
        ClientLine := Strg;
    END;

    {----------------}

    PROCEDURE TKR2Browser.BuildOneRow(Row : BYTE; VAR DatS; Len : WORD;
                                      RecNum         : LONGINT;
                                      Key : IsamKeyStr; VAR S : STRING);
    VAR
        P              : TKR2Rec ABSOLUTE DatS;
        TLen           : BYTE ABSOLUTE S;
    BEGIN
        IF RecNum <> - 1 THEN
            S := ClientLine(P, Row)
        ELSE BEGIN
            {Record is locked, indicate it on screen}
            S := '';
            WHILE TLen < fbMaxCols DO
                S := S + '**   ';
            TLen := fbMaxCols;
        END;
    END;

    {----------------}

    PROCEDURE TKR2Browser.ScreenUpdate;
    CONST
        {         1         2         3         4         5         6         7         8}
        {12345678901234567890123456789012345678901234567890123456789012345678901234567890}

        {        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX Institutional Retire  AA     04/25/1996}
{
        Footer1 =
        ' Use '#24#25' arrows to highlight a record, then hit <Enter> to Select it.        ';
        Footer2 =
        ' F1 Help        New Client                     Erase       Print      <Esc> ';
}
        FAttrs         : FlexAttrs = (BlackOnGreen, WhiteOnGreen, WhiteOnGreen, WhiteOnGreen);
    VAR
        HiAttr         : BYTE;

    BEGIN
        {Write the header line now}
        {         1         2         3         4         5         6         7         8}
        {12345678901234567890123456789012345678901234567890123456789012345678901234567890}
        fFastWrite('File Name                            ³File     ³File       ³File                ',
                   1, 1,
                   ColorMono(FbColors2.FrameColor, FbColors2.FrameMono));
        fFastWrite('    Hobbes Path                      ³Size     ³Date       ³Time                ',
                   2, 1,
                   ColorMono(FbColors2.FrameColor, FbColors2.FrameMono));
        fFastWrite(
            CharStr('Ä', Width), ScreenHeight - 5, 1,
            ColorMono(FbColors2.FrameColor, FbColors2.FrameMono));
        (*
        fFastWrite(ScnMsgP^.SysMsg(1006) { <D> - Delete Record  <N> - New Record   <S> - Sort Records  <P> - Print List } ,
                   ScreenHeight - 4, 1,
                   ColorMono(FbColors2.FrameColor, FbColors2.FrameMono));
        fFastWrite(ScnMsgP^.SysMsg(1007) { <Enter> - View/Modify Record                                    <ESC> - Exit } ,
                   ScreenHeight - 3, 1,
                   ColorMono(FbColors2.FrameColor, FbColors2.FrameMono));
        *)
    END;

    {------------}

END.
    {----------------}
    {----------------}
