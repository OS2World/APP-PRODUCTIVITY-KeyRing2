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
* Generic Picklist selector for a few items
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$I OPDEFINE.INC}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

UNIT DGPICKL;

INTERFACE
USES
    Dos,
    OpInline,
    OpString,
    OpRoot,
    OpCRT,
    OpCol16,
    {$IFDEF UseMouse}
    OpMouse,
    {$ENDIF}
    OpAbsFld,
    OpCmd,
    OpField,
    OpFrame,
    OpWindow,
    OpPick
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

CONST
    MaxPLStrings   = 20;
    MaxPLXHeaders  = 3;
    MaxPLStringLen = 78;
    MaxHeaderLen   = 70;

TYPE
    PTPLStrings    = ^TPLStrings;
    TPLStrings     = ARRAY[1..MaxPLStrings] OF STRING[MaxPLStringLen];

    PTPLSXHeader   = ^TPLStrings;
    TPLXHeader     = ARRAY[1..MaxPLXHeaders] OF STRING[MaxPLStringLen];

    PGenericPL     = ^TGenericPL;
    TGenericPL     = OBJECT(PickList)
                         NStrings       : WORD;
                         Strings        : TPLStrings;
                         Header         : STRING[MaxHeaderLen];
                         NExtrHead      : WORD;
                         ExtrHead       : TPLXHeader;
                         X1,
                         Y1,
                         X2,
                         Y2             : BYTE;
                         CS             : ColorSet;

                         CONSTRUCTOR Init(X, Y : BYTE; FrHeader : STRING;
                                          XHeaders       : TPLXHeader;
                                          Items          : TPLStrings;
                                          Colors         : ColorSet;
                                          DefChoice      : INTEGER);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE ItemString(Item : WORD; Mode : pkmode;
                                              VAR Itype      : pkitemtype;
                                              VAR IString    : STRING); VIRTUAL;
                         PROCEDURE Draw; VIRTUAL;
                         FUNCTION DoSelect : INTEGER;
                     END;

IMPLEMENTATION


    CONSTRUCTOR TGenericPL.Init(X, Y : BYTE; FrHeader : STRING;
                                XHeaders       : TPLXHeader;
                                Items          : TPLStrings;
                                Colors         : ColorSet;
                                DefChoice      : INTEGER);
    CONST
        Frame1         = '…»ªºÕÕ∫∫';
    VAR
        MaxSLen        : BYTE;
        I              : WORD;
        PLWidth        : WORD;
        WOptions       : LONGINT;

    BEGIN
        WOptions := DefWindowOptions OR wBordered;
        NStrings := 0;
        NExtrHead := 0;
        Strings := Items;
        ExtrHead := XHeaders;
        CS := Colors;
        IF Strings[1, 0] = #0 THEN
            FAIL;                 { No items in PickList }

        MaxSLen := LENGTH(Strings[1]);
        NStrings := 2;
        WHILE (NStrings <= MaxPLStrings) AND
        (Strings[NStrings, 0] <> #0) DO BEGIN
            IF LENGTH(Strings[NStrings]) > MaxSLen THEN
                MaxSLen := LENGTH(Strings[NStrings]);
            INC(NStrings);
        END;
        DEC(NStrings);
        IF NStrings < 2 THEN
            FAIL;                 { PickList with 1 item is not a Picklist}
        IF XHeaders[1, 0] <> #0 THEN BEGIN
            NExtrHead := 1;
            WHILE (NExtrHead <= MaxPLXHeaders) AND
            (XHeaders[NExtrHead, 0] <> #0) DO BEGIN
                IF LENGTH(XHeaders[NExtrHead]) > MaxSLen THEN
                    MaxSLen := LENGTH(XHeaders[NExtrHead]);
                INC(NExtrHead);
            END;
            DEC(NExtrHead);
        END;
        IF LENGTH(FrHeader) > MaxSLen THEN
            MaxSLen := LENGTH(FrHeader);

        IF MaxSLen MOD 2 <> 0 THEN
            INC(MaxSLen);

        IF X = 0 THEN
            X1 := (ScreenWidth - MaxSLen) DIV 2
        ELSE BEGIN
            X1 := X;
            IF X1 < 2 THEN
                X1 := 2
        END;

        IF Y = 0 THEN
            Y1 := (ScreenHeight - (NStrings - NExtrHead)) DIV 2
        ELSE BEGIN
            Y1 := Y;
            IF (Y1 - NExtrHead) < 3 THEN
                Y1 := NExtrHead + 3
        END;

        X2 := X1 + MaxSLen + 1;
        IF X2 > (ScreenWidth - 2) THEN BEGIN
            X2 := ScreenWidth - 2;
            X1 := X2 - MaxSLen - 1;
        END;
        Y2 := Y1 + NStrings - 1;
        IF Y2 > (ScreenHeight - 3) THEN BEGIN
            Y2 := ScreenHeight - 3;
            Y1 := Y2 - NStrings + 1;
        END;

        IF NOT PickList.InitAbstract(X1, Y1, X2, Y2,
                                     Colors,
                                     WOptions,
                                     MaxSLen + 2,
                                     NStrings,
                                     PickVertical,
                                     MultipleChoice) THEN
            FAIL;

        {$IFDEF UseMouse}
        IF MouseInstalled THEN
            pkOptionsOn(pkMousePage);
        {$ENDIF}
        IF NExtrHead <> 0 THEN
            AdjustFrameCoords(X1 - 1, Y1 - NExtrHead - 1, X2 + 1, Y2 + 1);
        SetPadSize(1, 1);
        WITH wFrame DO BEGIN
            SetFrameType(Frame1);
            {$IFDEF USESHADOWS}
            AddShadow(shBR, shSeeThru);
            {$ENDIF}
            IF FrHeader[0] <> #0 THEN
                AddHeader(FrHeader, heTC);
        END;
        IF DefChoice > 0 THEN
            SetInitialChoice(DefChoice);
    END;

    {------------}

    DESTRUCTOR TGenericPL.Done;
    BEGIN
        PickList.Done;
    END;

    {------------}

    PROCEDURE TGenericPL.Draw;
    VAR
        I              : WORD;

    BEGIN
        INHERITED Draw;
        IF NExtrHead <> 0 THEN
            FOR I := 1 TO NExtrHead DO
            BEGIN
                FastWrite(ExtrHead[I], Y1 - NExtrHead + I - 1, X1,
                          ColorMono(CS.PromptColor, CS.PromptMono));
            END;
    END;

    {------------}

    PROCEDURE TGenericPL.ItemString(Item : WORD; Mode : pkmode;
                                    VAR Itype      : pkitemtype;
                                    VAR IString    : STRING);
    BEGIN
        IString := Strings[Item];
    END;

    {------------}

    FUNCTION TGenericPL.DoSelect : INTEGER;
    BEGIN
        WHILE TRUE DO BEGIN
            Process;
            CASE GetLastCommand OF
                ccSelect :
                    BEGIN
                        DoSelect := GetLastChoice;
                        EXIT;
                    END;
                ccQuit :
                    BEGIN
                        DoSelect := - 1;
                        EXIT;
                    END;
                ccHelp : ;
            END;
        END;
    END;

    {------------}

END.

    {------------}
    {------------}
