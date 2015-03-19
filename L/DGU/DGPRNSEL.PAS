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
* Generic Printer selector.  Allows selection of printer type and port for two
* printers.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
}
{$I OPDEFINE.INC}
{$A+,B-,E+,F+,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

UNIT DGPRNSEL;

INTERFACE
USES
    DGPRINT,
    LJVAR,
    OpDialog,
    OpPrnlow
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

    {pick a printer model and port}
    {$IFDEF MultiPrint}
PROCEDURE PrinterSelector(VAR CFG : TPrnCfgArray;
                          HelpInd,
                          MsgSelPrn,
                          MsgSpc,
                          MsgConTo,
                          MsgCvPg,
                          MsgPMod,
                          MsgPPort,
                          MsgPTray,
                          MsgInvCombo1,
                          MsgInvCombo2,
                          MsgPri,
                          MsgSec,
                          MsgTer : WORD);
{$ELSE}
PROCEDURE PrinterSelector(VAR CFG        : TPrnCfg;
                          HelpInd,
                          MsgSelPrn,
                          MsgSpc,
                          MsgConTo,
                          MsgCvPg,
                          MsgPMod,
                          MsgPPort,
                          MsgPTray,
                          MsgInvCombo1,
                          MsgInvCombo2,
                          MsgPri,
                          MsgSec,
                          MsgTer         : WORD);
    {$ENDIF}

    {pick either the primary or secondary printer, or no printer at all}
    {select the actual printer model elsewhere!}
FUNCTION DoPrnSelDlg(VAR PriSec     : TPrnPriSec;
                     HelpInd,
                     MsgHdr,
                     MsgOk,
                     MsgCancel,
                     MsgHelp,
                     MsgPick        : WORD) : BOOLEAN;


IMPLEMENTATION

USES
    Colors,
    DefInfo,
    DGHELP,
    DGPICKL,
    GLOBTYPE,
    KERROR,
    Message,
    MSGMGR,
    DGCMD,
    Dos,
    OpInline,
    OpString,
    OpRoot,
    OpCRT,
    OpCol16,
    OpKey,
    {$IFDEF UseMouse}
    OpMouse,
    {$ENDIF}
    OpAbsFld,
    OpCmd,
    OpField,
    OpFrame,
    OpWindow,
    OpSelect,
    OpEntry,
    UTIAM;

    {Entry field constants}
CONST
    idPrimaryPrinterType = 0;
    idPrimaryPrinterPort = idPrimaryPrinterType + 1;
    idPrimaryTray  = idPrimaryPrinterPort + 1;
    idSecondaryPrinterType = idPrimaryTray + 1;
    idSecondaryPrinterPort = idSecondaryPrinterType + 1;
    idSecondaryTray = idSecondaryPrinterPort + 1;

    {Help index constants}
CONST
    {$IFDEF TPLATINUM}
    hiPrimaryPrinterType   = h_PrinterSetup;
    hiPrimaryPrinterPort   = h_PrinterSetup;
    hiSecondaryPrinterType = h_PrinterSetup;
    hiSecondaryPrinterPort = h_PrinterSetup;
    {$ELSE}
    hiPrimaryPrinterType = 1;
    hiPrimaryPrinterPort = hiPrimaryPrinterType + 1;
    hiSecondaryPrinterType = hiPrimaryPrinterPort + 1;
    hiSecondaryPrinterPort = hiSecondaryPrinterType + 1;
    {$ENDIF}
    {-------------}

TYPE
    PPrnModelSelector = ^TPrnModelSelector;
    TPrnModelSelector = OBJECT(EntryScreen)
                            {$IFDEF Multiprint}
                            CONSTRUCTOR Init(VAR CFG : TPrnCfgArray; HelpInd,
                                       MsgSelPrn,
                                       MsgSpc,
                                       MsgConTo,
                                       MsgCvPg,
                                       MsgPMod,
                                       MsgPPort,
                                       MsgPTray,
                                       MsgInvCombo1,
                                       MsgInvCombo2,
                          MsgPri,
                          MsgSec,
                          MsgTer :WORD);

                            FUNCTION IsValid : BOOLEAN;
                            {$ELSE}
                            CONSTRUCTOR Init(VAR CFG        : TPrnCfg; HelpInd,
                                             MsgSelPrn,
                                             MsgSpc,
                                             MsgConTo       : WORD);
                            {$ENDIF}
                            DESTRUCTOR Done; VIRTUAL;
                            PROCEDURE ProcessSelf; VIRTUAL;
                            PROCEDURE DoPickLists;
                            PROCEDURE PtypePL(PS : TPrnPriSec; PlHeader : STRING);
                            PROCEDURE PPortPL(PS : TPrnPriSec; PlHeader : STRING);
                            PROCEDURE PTrayPL(PS : TPrnPriSec; PlHeader : STRING);
                            PROCEDURE ClearPLArr;

                        PRIVATE

                            LocalCP        : TDGUCommandProcessor;

                                {$IFDEF Multiprint}
                            UR : PPrnCfgArray;
                            {$ELSE}
                            UR             : PPrnCfg;
                                {$ENDIF}

                            PLItems        : TPLStrings;
                            PLHeads        : TPLXHeader;
                            MyHelpInd,
                            MyMsgPMod,
                            MyMsgPPort,
                            MyMsgPTray,
                            MyMsgInvCombo1,
                            MyMsgInvCombo2 : WORD;

                            FUNCTION qsDoPickList(X, Y : BYTE; H : STRING;
                                                  DefChoice      : INTEGER) : INTEGER;
                        END;

CONST
    TLetterHeadTrayNames : ARRAY[TLetterHeadTray] OF STRING[16] =
    ('Single',
     'Upper',
     'Lower',
     'Manual',
     'OptSrc',
     'ManEnv',
     'AutoEnv',
     'dont use!');

    PROCEDURE IncLT(VAR Value; FieldID : WORD; Factor : INTEGER; VAR St : STRING); FAR;
    VAR
        Pt             : TLetterHeadTray ABSOLUTE Value;
    BEGIN
        IF (Factor = 1) THEN
            IF (Pt = HIGH(TLetterHeadTray)) THEN
                Pt := LOW(TLetterHeadTray)
            ELSE
                Pt := SUCC(Pt)
        ELSE IF (Factor = - 1) THEN
            IF (Pt = LOW(TLetterHeadTray)) THEN
                Pt := HIGH(TLetterHeadTray)
            ELSE
                Pt := PRED(Pt);

        St := TLetterHeadTrayNames[Pt];
    END;


    PROCEDURE IncPP(VAR Value; FieldID : WORD; Factor : INTEGER; VAR St : STRING); FAR;
    VAR
        Pt             : PrnType ABSOLUTE Value;
    BEGIN
        IF (Factor = 1) THEN
            IF (Pt = HIGH(PrnType)) THEN
                Pt := LOW(PrnType)
            ELSE
                Pt := SUCC(Pt)
        ELSE IF (Factor = - 1) THEN
            IF (Pt = LOW(PrnType)) THEN
                Pt := HIGH(PrnType)
            ELSE
                Pt := PRED(Pt);

        St := PrnNames[Pt];
    END;

    {-------------}

    PROCEDURE IncPT(VAR Value; FieldID : WORD; Factor : INTEGER; VAR St : STRING); FAR;
    VAR
        Pt             : PrnModelT ABSOLUTE Value;
    BEGIN
        IF (Factor = 1) THEN
            IF (Pt = HIGH(PrnModelT)) THEN
                Pt := LOW(PrnModelT)
            ELSE
                Pt := SUCC(Pt)
        ELSE IF (Factor = - 1) THEN
            IF (Pt = LOW(PrnModelT)) THEN
                Pt := HIGH(PrnModelT)
            ELSE
                Pt := PRED(Pt);

        St := PrnModels[Pt];

    END;

    {-------------}

    FUNCTION TPrnModelSelector.qsDoPickList(X, Y           : BYTE;
                                            H              : STRING;
                                            DefChoice      : INTEGER) : INTEGER;
    VAR
        PL             : PGenericPL;
        I              : INTEGER;
    BEGIN
        qsDoPickList := - 1;
        NEW(PL, Init(X, Y, H, PLHeads, PLItems, FDialogColors, DefChoice));
        IF PL = NIL THEN
            EXIT;
        I := PL^.DoSelect;
        DISPOSE(PL, Done);
        qsDoPickList := I;
    END;

    {-------------}

    PROCEDURE TPrnModelSelector.ClearPLArr;
    BEGIN
        FILLCHAR(PLItems, SIZEOF(PLItems), #0);
        FILLCHAR(PLHeads, SIZEOF(PLHeads), #0);
    END;

    {-------------}

    PROCEDURE TPrnModelSelector.PtypePL(PS : TPrnPriSec; PlHeader : STRING);
    VAR
        I              : INTEGER;
        P              : PrnModelT;
    BEGIN
        ClearPLArr;

        FOR P := LOW(P) TO HIGH(P) DO
            PLItems[ORD(P) + 1] := PrnModels[P];

        {$IFDEF MultiPrint}
        I := qsDoPickList(WhereX, WhereY + 1, plheader,
                          INTEGER(UR^[PS].PType) + 1);
        IF I <> - 1 THEN
            UR^[PS].PType := PrnModelT(I - 1);
        {$ELSE}
        I := qsDoPickList(WhereX, WhereY + 1, PlHeader,
                          INTEGER(UR^.PType) + 1);
        IF I <> - 1 THEN
            UR^.PType := PrnModelT(I - 1);
        {$ENDIF}

    END;

    {-------------}

    PROCEDURE TPrnModelSelector.PTrayPL(PS : TPrnPriSec; PlHeader : STRING);
    VAR
        I              : INTEGER;
        P              : TLetterHeadTray;
    BEGIN
        ClearPLArr;

        FOR P := LOW(P) TO HIGH(P) DO
            PLItems[ORD(P) + 1] := TLetterHeadTrayNames[P];

        {$IFDEF MultiPrint}
        if ps = eprimary then begin
            I := qsDoPickList(WhereX, WhereY + 1, plheader,
                              INTEGER(UR^[PS].TrayLtr) + 1);
            IF I <> - 1 THEN
                UR^[PS].TrayLtr := TLetterHeadTray(I - 1);
        end
        else begin

            I := qsDoPickList(WhereX, WhereY + 1, plheader,
                              INTEGER(UR^[PS].TrayBlnk) + 1);
            IF I <> - 1 THEN
                UR^[PS].TrayBlnk := TLetterHeadTray(I - 1);
        end;
        {$ELSE}
        I := qsDoPickList(WhereX, WhereY + 1, PlHeader,
                          INTEGER(UR^.TrayLtr) + 1);
        IF I <> - 1 THEN
            UR^.TrayLtr := TLetterHeadTray(I - 1);
        {$ENDIF}

    END;

    {-------------}

    PROCEDURE TPrnModelSelector.PPortPL(PS : TPrnPriSec; PlHeader : STRING);
    VAR
        I              : INTEGER;
        P              : PrnType;
    BEGIN
        ClearPLArr;

        FOR P := LOW(P) TO HIGH(P) DO
            PLItems[ORD(P) + 1] := PrnNames[P];

        {$IFDEF MultiPrint}
        I := qsDoPickList(WhereX, WhereY + 1, plheader,
                          INTEGER(UR^[PS].PPort) + 1);
        IF I <> - 1 THEN
            UR^[PS].PPort := PrnType(I - 1);
        {$ELSE}
        I := qsDoPickList(WhereX, WhereY + 1, PlHeader,
                          INTEGER(UR^.PPort) + 1);
        IF I <> - 1 THEN
            UR^.PPort := PrnType(I - 1);
        {$ENDIF}
    END;

    {-------------}

    {$IFDEF MULTIPRINT}
    constructor TPrnModelSelector.Init(VAR CFG  : TPrnCfgArray;
                                       HelpInd,
                                       MsgSelPrn,
                                       MsgSpc,
                                       MsgConTo,
                                       MsgCvPg,
                                       MsgPMod,
                                       MsgPPort,
                                       MsgPTray,
                                       MsgInvCombo1,
                                       MsgInvCombo2,
                          MsgPri,
                          MsgSec,
                          MsgTer : WORD);
    {$ELSE}
    CONSTRUCTOR TPrnModelSelector.Init(VAR CFG : TPrnCfg; HelpInd : WORD);
        {$ENDIF}
    CONST
        Frame1         = '…»ªºÕÕ∫∫';
        WinOptions     = wBordered + wClear + wUserContents;
    VAR
        Bottom         : BYTE;
        Y              : BYTE;
    BEGIN
        UR := @CFG;
        MyHelpInd := HelpInd;
        MyMsgPMod := MsgPMod;
        MyMsgPPort := MsgPPort;
        MyMsgPTray := MsgPTray;
        MyMsgInvCombo1 := MsgInvCombo1;
        MyMsgInvCombo2 := MsgInvCombo2;

        {$IFDEF MULTIPRINT}
        {$IFDEF THREEPRINTERS}
        Y := (ScreenHeight - 12) div 2;
        Bottom := Y + 11;
        {$ELSE}
        Y := (ScreenHeight - 8) div 2;
        Bottom := Y + 7;
        {$ENDIF}
        {$ELSE}
        Bottom := 12;
        Y := (ScreenHeight - 4) DIV 2;
        Bottom := Y + 3;
        {$ENDIF}

        IF NOT InitCustom(16, Y {9} , 64, Bottom, EsColors, WinOptions) THEN
            FAIL;

        wFrame.SetFrameType(Frame1);
        EnableExplosions(6);
        {$IFDEF USESHADOWS}
        wFrame.AddShadow(shBR, shSeeThru);
        {$ENDIF}
        wFrame.AddHeader(ScnMsgP^.SysMsg(MsgSelPrn) { Select Printers } , heTC);
        wFrame.AddHeader(ScnMsgP^.SysMsg(MsgSpc) { Press F2 for Picklist or use Spacebar } , heBC);
        SetWrapMode(ExitAtBot);

        UR^[Eprimary].PName := ScnMsgP^.SysMsg(MsgPri);
        UR^[ESECONDARY].PName := ScnMsgP^.SysMsg(MsgSec);
        {$IFDEF THREEPRINTERS}
        UR^[ETERTIARY].PName := ScnMsgP^.SysMsg(MsgTer);
        {$ENDIF}

        {idPrimaryPrinterType:}
        AddChoiceField(
            {$IFDEF MULTIPRINT}
            UR^[eprimary].PName, 2, 3,
            {$ELSE}
            UR^.PName, 2, 3,
            {$ENDIF}
            'XXXXXXXXXXXXXXX', 3, 5,
            MyHelpInd,
            SIZEOF(PrnModelT), IncPT,
            {$IFDEF MULTIPRINT}
            UR^[eprimary].PType
            {$ELSE}
            UR^.PType
            {$ENDIF} );

        {idPrimaryPrinterPort:}
        AddChoiceField(
            ScnMsgP^.SysMsg(MsgConTo) {Connected To :} , 3, 22,
            'XXXXXXXXXXXX', 3, 37,
            MyHelpInd,
            SIZEOF(PrnType), IncPP,
            {$IFDEF MULTIPRINT}
            UR^[eprimary].PPort
            {$ELSE}
            UR^.PPort
            {$ENDIF} );
        {$IFNDEF NOPAPERTRAY}
        {idPrimaryTray}
        AddChoiceField(
            ScnMsgP^.SysMsg(MsgCvPg) {Tray for Cover Page :} , 4, 15,
            'XXXXXXXXXXXX', 4, 37,
            MyHelpInd,
            SIZEOF(TLetterHeadTray),
            IncLT,
            {$IFDEF MULTIPRINT}
            UR^[eprimary].TrayLtr
            {$ELSE}
            UR^.TrayLtr
            {$ENDIF}
            );
        {$ENDIF}

        {$IFDEF MULTIPRINT}
        {idSecondaryPrinterType:}
        AddChoiceField(
                UR^[esecondary].PName, 6, 3,
                'XXXXXXXXXXXXXXX', 7, 5,
                MyHelpInd,
                SIZEOF(PrnModelT), IncPT, UR^[esecondary].PType);

            {idSecondaryPrinterPort:}
        AddChoiceField(
                ScnMsgP^.SysMsg(MsgConTo) {Connected To :} , 7, 22,
                'XXXXXXXXXXXX', 7, 37,
                MyHelpInd,
                SIZEOF(PrnModelT), IncPP, UR^[esecondary].PPort);

        {$IFNDEF NOPAPERTRAY}
            {idSecondaryTray}
            AddChoiceField(
                ScnMsgP^.SysMsg(MsgCvPg) {Tray for Cover Page :}, 8, 15,
                'XXXXXXXXXXXX', 8, 37,
                MyHelpInd,
                SIZEOF(TLetterHeadTray),
                IncLT, ur^[esecondary].TrayBlnk);
        {$ENDIF}
        {$ENDIF}

        {$IFDEF THREEPRINTERS}
        {idSecondaryPrinterType:}
        AddChoiceField(
                UR^[etertiary].PName, 10, 3,
                'XXXXXXXXXXXXXXX', 11, 5,
                MyHelpInd,
                SIZEOF(PrnModelT), IncPT, UR^[etertiary].PType);

            {idSecondaryPrinterPort:}
        AddChoiceField(
                ScnMsgP^.SysMsg(MsgConTo) {Connected To :} , 11, 22,
                'XXXXXXXXXXXX', 11, 37,
                MyHelpInd,
                SIZEOF(PrnModelT), IncPP, UR^[etertiary].PPort);

        {$IFNDEF NOPAPERTRAY}
            {idSecondaryTray}
            AddChoiceField(
                ScnMsgP^.SysMsg(MsgCvPg) {Tray for Cover Page :}, 12, 15,
                'XXXXXXXXXXXX', 12, 37,
                MyHelpInd,
                SIZEOF(TLetterHeadTray),
                IncLT, ur^[etertiary].TrayBlnk);
        {$ENDIF}
        {$ENDIF}

        InitStatus := RawError;
        IF InitStatus <> 0 THEN
            FAIL;

        IF NOT LocalCP.Init(@EntryKeySet, EntryKeyMax) THEN
            FAIL;

        {$IFDEF UseMouse}
        IF MouseInstalled THEN
            WITH EsColors DO BEGIN
                {activate mouse cursor}
                SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) SHL 8) +
                                BYTE(MouseChar));
                ShowMouse;
                {enable mouse support}
                {$IFDEF TPLATINUM}
                LocalCP.cpOptionsOn(cpEnableMouse);
                {$ELSE}
                EntryCommands.cpOptionsOn(cpEnableMouse);
                {$ENDIF}
            END;
        {$ENDIF}

        LocalCP.SetHelpProc(DisplayHelp);
        LocalCP.AddCommand(ccUser2, 1, F2, 0);
        LocalCP.AddCommand(ccHelp, 1, F1, 0);

        SetCommandProcessor(LocalCP);
    END;

    {-------------}

    DESTRUCTOR TPrnModelSelector.Done;
    BEGIN
        INHERITED Done;
        LocalCP.Done;
    END;

    {-------------}

    PROCEDURE TPrnModelSelector.DoPickLists;
    BEGIN
        CASE GetCurrentID OF
            idPrimaryPrinterType :
                PtypePL(Eprimary, ScnMsgP^.SysMsg(MyMsgPMod) { Printer model } );
            idPrimaryPrinterPort :
                PPortPL(Eprimary, ScnMsgP^.SysMsg(MyMsgPPort) { Printer Port } );
            idPrimaryTray :
                PTrayPL(Eprimary, ScnMsgP^.SysMsg(MyMsgPTray) { Paper Tray } );
            {$IFDEF Multiprint}
            idSecondaryPrinterType :
                PtypePL(ESECONDARY, ScnMsgP^.SysMsg(MyMsgPMod) { Printer model });
            idSecondaryPrinterPort :
                PPortPL(ESECONDARY, ScnMsgP^.SysMsg(MyMsgPPort) { Printer Port });
            idSecondaryTray:
                PTrayPL(eSecondary, ScnMsgP^.SysMsg(MyMsgPTray) { Paper Tray });
            {$ENDIF}
        END;
    END;

    {-------------}

    PROCEDURE TPrnModelSelector.ProcessSelf;
    BEGIN
        REPEAT
            INHERITED ProcessSelf;
            CASE GetLastCommand OF
                ccUser2 :
                    DoPickLists;
                ccQuit,
                ccError :
                    BREAK;
                ccHelp :
                    DisplayHelp(5, NIL, MyHelpInd);
                ccExitAtBot,
                ccDone :
                    BEGIN
                        {$ifdef multiprint}
                        {$ifndef DupeLPT}
                        if isvalid then
                            break;
                        {$else}
                        break;
                        {$endif}
                        {$else}
                        BREAK;
                        {$endif}
                    END;
            END;
        UNTIL FALSE;
    END;

    {-------------}

    {$IFDEF MULTIPRINT}
    FUNCTION TPrnModelSelector.IsValid : BOOLEAN;
    VAR
        MBP            : MessageBoxP;
    BEGIN
        IsValid := TRUE;
        NEW(MBP, Init(' ERROR! ' ,
                      ctOk,
                      ctNone,
                      ctHelp,
                      3023));
        IF MBP = NIL THEN
            EXIT;

        WITH MBP^ DO BEGIN
            AddLine(ScnMsgP^.SysMsg(MyMsgInvCombo1) {Invalid printer combination!} , ECENTER);
            AddLine('', ELEFT);
            AddLine(ScnMsgP^.SysMsg(MyMsgInvCombo2) {You have both printers connected to } +
            PrnNames[UR^[eprimary].PPort], ECENTER);
            AddLine('', ECENTER);
            IF UR^[eprimary].PPort = UR^[esecondary].PPort THEN BEGIN
                RingBell;
                IsValid := FALSE;
                Process;
            END;
        END;
        DISPOSE(MBP, Done);
    END;
    {$ENDIF}

    {----------------}

    {$IFDEF MultiPrint}
    PROCEDURE PrinterSelector(VAR CFG : TPrnCfgArray;
                          HelpInd,
                          MsgSelPrn,
                          MsgSpc,
                          MsgConTo,
                          MsgCvPg,
                          MsgPMod,
                          MsgPPort,
                          MsgPTray,
                          MsgInvCombo1,
                          MsgInvCombo2,
                          MsgPri,
                          MsgSec,
                          MsgTer : WORD);
    {$ELSE}
    PROCEDURE PrinterSelector(VAR CFG        : TPrnCfg;
                              HelpInd,
                              MsgSelPrn,
                              MsgSpc,
                              MsgConTo,
                              MsgCvPg,
                              MsgPMod,
                              MsgPPort,
                              MsgPTray,
                              MsgInvCombo1,
                              MsgInvCombo2,
                              MsgPri,
                              MsgSec,
                              MsgTer         : WORD);
        {$ENDIF}
    VAR
        ES             : PPrnModelSelector;
    BEGIN
        NEW(ES, Init(CFG,
                     HelpInd,
                     MsgSelPrn,
                     MsgSpc,
                     MsgConTo,
                     MsgCvPg,
                     MsgPMod,
                     MsgPPort,
                     MsgPTray,
                     MsgInvCombo1,
                     MsgInvCombo2,
                     MsgPri,
                     MsgSec,
                     MsgTer));
        IF ES = NIL THEN BEGIN
            DispErrorDeluxe('Error initializing ES', ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;

        ES^.Process;
        DISPOSE(ES, Done);
    END;

    {-------------}

    {pick either the primary or secondary printer}
    FUNCTION DoPrnSelDlg(VAR PriSec     : TPrnPriSec;
                         HelpInd,
                         MsgHdr,
                         MsgOk,
                         MsgCancel,
                         MsgHelp,
                         MsgPick        : WORD) : BOOLEAN;
    VAR
        DBP            : DialogBoxPtr;
        Status         : WORD;
        Finished       : BOOLEAN;
        Header         : STRING;
        Primary        : TPrnPriSec;
        R              : TDefaultInfo;
        LocalCP        : TDGUCommandProcessor;

        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
            BoxWidth       = 46;
        VAR
            Xl, Xr,
            Yt, Yb         : WORD;
            DlgVSize       : WORD;
            StrOk,
            StrCancel      : STRING[32];

        BEGIN
            {$IFDEF THREEPRINTERS}
            DlgVSize := 8;
            {$ELSE}
            DlgVSize := 7;
            {$ENDIF}

            StrOk := ScnMsgP^.SysMsg(MsgOk) {.&Ok} ;
            StrCancel := ScnMsgP^.SysMsg(MsgCancel) {.&Cancel} ;

            Xl := (ScreenWidth - BoxWidth) DIV 2;
            Xr := Xl + BoxWidth - 1;
            Yt := (ScreenHeight - DlgVSize) DIV 2;
            Yb := Yt + DlgVSize - 1;

            NEW(DBP, InitCustom(
                Xl, Yt, Xr, Yb,
                FDialogColors,
                WinOptions,       {window options}
                dColors
                ));

            IF DBP = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;

            {DBP^.wFrame.AddHeader(ScnMsgP^.SysMsg(MsgPick), heBL);}
            {$IFDEF USESHADOWS}
            DBP^.wFrame.AddShadow(shBR, shSeeThru);
            {$ENDIF}
            DBP^.AddRadioButtons(ScnMsgP^.SysMsg(MsgHdr) {Select printer:} , 2, 2,
                                 3, 2,
                                 13,
                                 {$IFDEF THREEPRINTERS}
                                 3,
                                 {$ELSE}
                                 2,
                                 {$ENDIF}
                                 0, 0, Primary);
            {$IFDEF Multiprint}
            DBP^.AddRadioButtonAt(Pad(zzzPrnNames[R.PrnInfo[eprimary].PType], 39), 1, 1, ORD(eprimary));
            DBP^.AddRadioButtonAt(Pad(zzzPrnNames[R.PrnInfo[ESECONDARY].PType], 39), 2, 1, ORD(esecondary));
            {$IFDEF THREEPRINTERS}
            DBP^.AddRadioButtonAt(Pad(zzzPrnNames[R.PrnInfo[ETERTIARY].PType], 39), 3, 1, ORD(etertiary));
            {$ENDIF}
            {$ENDIF}
            DBP^.AddPushButton(StrOk, DlgVSize - 1, 2, 8, 0, ccSelect, TRUE);
            DBP^.AddPushButton(StrCancel, DlgVSize - 1, 13, 8, 0, ccQuit, FALSE);
            DBP^.AddPushButton(ScnMsgP^.SysMsg(MsgHelp) {.&Help} , DlgVSize - 1, 24, 8, 0, ccHelp, FALSE);

            InitDialogBox := DBP^.RawError;
        END;

    BEGIN
        IF NOT LocalCP.Init(@DialogKeySet, DialogKeyMax) THEN BEGIN
            Status := InitStatus;
            EXIT;
        END;
        LocalCP.AddCommand(ccHelp, 1, F1, 0);
        {select alternate scroll bar arrows}
        Header := ScnMsgP^.SysMsg(MsgHdr) { Select Printer } ;
        Primary := Eprimary;
        GetDefaultInfo(R);

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            LocalCP.Done;
            EXIT;
        END;

        Finished := FALSE;
        DBP^.SetCommandProcessor(LocalCP);
        WHILE NOT Finished DO BEGIN
            DBP^.Process;
            CASE DBP^.GetLastCommand OF
                {$IFDEF USEDRAG}
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(DBP^) = hsRegion3 THEN                    BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                        DoPrnSelDlg := FALSE;
                    END;
                {$ENDIF}
                ccHelp :
                    DisplayHelp(5, NIL, HelpInd);
                ccSelect :
                    BEGIN
                        DoPrnSelDlg := TRUE;
                        Finished := TRUE;
                    END;
                ccQuit :
                    BEGIN
                        DoPrnSelDlg := FALSE;
                        Finished := TRUE;
                    END;
                ELSE
                    DoPrnSelDlg := TRUE;
            END;
        END;
        {$ifdef Multiprint}
        Prisec := Primary;
        {$else}
        PriSec := Eprimary;
        {$ENDIF}

        LocalCP.Done;
        DISPOSE(DBP, Done);
    END;

    {------------}

END.

    {-------------}
    {-------------}

