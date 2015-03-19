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
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,V-,O+,F+}

{-------------------------------------------------}
{ (C) 1990 NewsMaker Systems.                     }
{ Asynch Communications subsystem.                }
{ Provides a complete, self-contained remote      }
{ access system, with Terminal emulation and      }
{ protocol support for Up/Downloads.              }
{ Provides TTY and VT52 terminal emulation modes  }
{ Xmodem, WXmodem and Ymodem protocols            }
{-------------------------------------------------}

UNIT UCOMM;

INTERFACE
{$I NDEFINE.INC}
{$IFNDEF NOTNEN}

USES Dos, OpCrt, OpString, OpEdit, UMSg,
    OpCmd, OpConst, OpRoot, OpFrame, OpWindow, OpEntry, OpMouse, OpDos, OpDrag, OpEditor,
    LctKrnl, LctHayes, LctSupp, LctYmbat, LtXmodem, LtXmkrnl,
    QGlobal, QInput, QHdrRec, QHdr, QHdrIO, QHdrGet, QCS, QDrives, QScreen,
    UGLOBAL, UColors, UWindow, UMENU, OpMenu, ULib, UReadTx, UKey, UDIALOG,
    UCommLib, UTerm, UService, UCapture, UScript, OpKey;

VAR
    Com            : WORD;
    LogF           : TEXT;
    WorkHdr        : ^RunDownRec;

CONST
    LogFile        : PathStr = '';
    LogOpen        : BOOLEAN = FALSE;

PROCEDURE InitRemote(ComPort : WORD; Baud : WORD; Parity : CHAR; Data : WORD;
                     Stop : WORD; XonXoff : BOOLEAN);
PROCEDURE CloseRemote;
PROCEDURE DialRemote(TelNum : PhoneString);
PROCEDURE OpenLogFile(Log : ModemString);
PROCEDURE CloseLogFile;
PROCEDURE GoOnline;
PROCEDURE GoOffline;
PROCEDURE RunRemote(GoService : ServiceType; Go : BOOLEAN);
PROCEDURE InputChar(VAR Ch : CHAR);
FUNCTION InChar : INTEGER;        { Special for CserveB }
PROCEDURE OutputChar(Ch : CHAR);
PROCEDURE CheckMenu;
PROCEDURE InitMenu(VAR M : MenuPtr);
PROCEDURE SendToRemote(Ch : CHAR);
PROCEDURE WaitForLine;
FUNCTION GetNextKey : CHAR;
PROCEDURE EnableMenu;
PROCEDURE DisableMenu;
PROCEDURE OpenLogOrNENFile(VAR FName : DirStr; Log : BOOLEAN);
PROCEDURE UpdateStatusLine;
{$ENDIF}
IMPLEMENTATION
{$IFNDEF NOTNEN}
CONST MaxTime  = 10000;           {CheckStatus calls before timeout }
    BF1            = #187;
    BF2            = #188;
    BF3            = #189;
    BF4            = #190;
    BF5            = #191;
    BF6            = #192;
    BF7            = #193;
    BF8            = #194;
    BF9            = #195;
    BF10           = #196;

    ReDialMax      = 10;

TYPE
    BytePtr        = ^BYTE;

    PtrRec         = RECORD
                         OFS, SEG       : WORD;
                     END;

VAR
    Bl             : BOOLEAN;
    InQueue        : WORD;
    OutQueue       : WORD;
    ErrorStat      : WORD;
    ModemStat      : WORD;
    Modem_ResultString : STRING[20];
    Modem_Result   : INTEGER;
    InputString    : STRING;
    HangUp         : BOOLEAN;
    Ch1            : CHAR;
    IX             : INTEGER;
    IdleCount      : LONGINT;
    IdleCheck      : BOOLEAN;
    ServiceInEffect : BOOLEAN;
    Comm_Quit      : BOOLEAN;
    OnLine         : BOOLEAN;
    ReqNumber      : PhoneString;
    ReqTerm        : WORD;
    CommSet        : BOOLEAN;
    ScriptName     : PathStr;
    Dialing        : BOOLEAN;
    ReDial         : WORD;
    MenuEnabled    : BOOLEAN;


    Baud_Rate      : WORD;
    Data_Bits      : WORD;
    Stop_Bits      : WORD;
    Parity         : CHAR;
    Xon_Xoff       : BOOLEAN;

    Local_Name     : ModemString;
    Remote_Name    : ModemString;

    Path           : PathStr;

    BSize          : WORD;
    RBSize         : INTEGER;
    HandShake      : BYTE;
    BPtr           : BytePtr;
    CRPtr          : BytePtr;
    X_Result       : XMResult;
    BytesRem       : WORD;        (* number of untrans. bytes *)
    XMFile         : FILE;


CONST
    CurComm        : WORD = 1;
    CurBaud        : WORD = 1200;
    CurParity      : CHAR = 'N';
    CurData        : WORD = 8;
    CurStop        : WORD = 1;
    TermIO         : BOOLEAN = FALSE;
    LastLine       : STRING = '';
    ViewLog        : PathStr = '';

    {**********************************************************************}
    { HAYES modem/Async I/O support                                        }
    {**********************************************************************}

    {--------------------------------------------------------}

    PROCEDURE SwitchModemToCommandState;
    CONST 
        Cmd      : ARRAY[1..3] OF CHAR = ('+', '+', '+');
    VAR 
        I          : INTEGER;
    BEGIN
        I := PutStream(Com, Cmd, 3);
    END;

    {--------------------------------------------------------}

    PROCEDURE SelectProtocol(VAR P : INTEGER);
    VAR 
        I          : INTEGER;
    BEGIN
        UGLOBAL.Menu^[1] := 'ASCII';
        UGLOBAL.Menu^[2] := 'XMODEM';
        UGLOBAL.Menu^[3] := 'XMODEM-1K';
        UGLOBAL.Menu^[4] := 'YMODEM';
        OpenMenu(35, 3, 52, 13, UGLOBAL.Menu^, 4, 13, NoSort, '', SysMsg(001053) {'Protocol'} , Gray_Scheme, I);
        I := GetMenu;
        CloseWindow;
        P := I;
    END;

    {--------------------------------------------------------}

    PROCEDURE Upload;
    VAR 
        F          : FILE;
        I              : INTEGER;
        Ch             : CHAR;
        P              : INTEGER;
    BEGIN
        Local_Name := '';
        GetFileName('*.*', Local_Name);
        IF Local_Name = '' THEN EXIT;
        SelectProtocol(P);
        IF P = 0 THEN EXIT;
        Remote_Name := Local_Name;
        CASE P OF
            P_ASCII : BEGIN       { ASCII }
                          ASSIGN(F, Local_Name);
                  {$I-}
                          RESET(F, 1);
                          IF IORESULT <> 0 THEN EXIT;
                          WHILE NOT EOF(F) DO BEGIN
                              BLOCKREAD(F, Ch, 1);
                              IF Ch <> ^Z THEN
                                  SendToRemote(Ch);
                          END;
                          CLOSE(F);
                  {$I+}
                      END;
            P_XMODEM,
            P_XMODEM1K,
            P_YMODEM
            : BEGIN               { Xmodem & derivatives }
              END;
        END;
    END;

    {--------------------------------------------------------}
    PROCEDURE ShowFile(CPort : INTEGER; Name : STRING);
    BEGIN
        WriteStr(WinX + 2, WinY + 2, '                      ', Attr(LightGray, Black));
        WriteStr(WinX + 2, WinY + 2, SysMsg(001055) {'Slug: '} , Attr(LightGray, Black));
        WriteStr(WinX + 14, WinY + 2, WorkHdr^.Slug, Attr(LightGray, Red));
        WriteStr(WinX + 2, WinY + 3, SysMsg(001056) {'File: '} , Attr(LightGray, Black));
        WriteStr(WinX + 14, WinY + 3, Name, Attr(LightGray, Red));
    END;

    {--------------------------------------------------------}
    PROCEDURE ShowXferData(CPort : INTEGER; Rec, Errors, TotErrors : WORD);
    BEGIN
        WriteStr(WinX + 2, WinY + 4, SysMsg(001057) {'Blocks: '} , Attr(LightGray, Black));
        WriteStr(WinX + 14, WinY + 4, Pad(Long2Str(Rec), 4), Attr(LightGray, Red));
        WriteStr(WinX + 2, WinY + 5, SysMsg(001058) {'Errors: '} , Attr(LightGray, Black));
        WriteStr(WinX + 14, WinY + 5, Pad(Long2Str(Errors), 4), Attr(LightGray, Red));
        WriteStr(WinX + 2, WinY + 6, SysMsg(001059) {'Total Errs: '} , Attr(LightGray, Black));
        WriteStr(WinX + 14, WinY + 6, Pad(Long2Str(TotErrors), 4), Attr(LightGray, Red));
    END;

    {--------------------------------------------------------}

    FUNCTION CheckKbd : BOOLEAN;
    VAR 
        Ch         : CHAR;
    BEGIN
        Ch := GetNextKey;
        IF Ch = #27 THEN          { Esc }
            CheckKbd := TRUE
        ELSE
            CheckKbd := FALSE;
    END;

    {------------------------------------------------------------}
    { Download with Xmodem or Xmodem-1K (Automatically detected) }
    PROCEDURE DoXmodemDownload;
    BEGIN
        IF SetFnHook(Com, ShowFile) THEN ;
        IF SetUserHook(Com, ShowXferData) THEN ;
        IF SetAbortHook(Com, CheckKbd) THEN ;

        BSize := 8192;            { want to use 8K buffer }
        BPtr := NIL;
        WHILE (BPtr = NIL) AND    { allocate buffer for proc }
        (BSize > 0) DO
            IF MAXAVAIL >= BSize THEN { enough contig space }
                GetMemCheck(BPtr, BSize) { yes, grab it }
            ELSE
                DEC(BSize, 1024); { no, try 1K less }

        OpenWindow(40, 10, 70, 16, SysMsg(001060) {'DownLoad'} , Gray_Scheme);

        ASSIGN(XMFile, Local_Name);
        ShowFnProc[Com](Com, Local_Name);
    {$I-}
        REWRITE(XMFile, 1);
    {$I+}
        IF IORESULT <> 0 THEN
            FlagAbort(Com);

        X_Result := Success;
        BytesRem := 0;
        CRPtr := BPtr;

        WITH Service^ DO
            IF NOT CommSetup(ComPort, CBaud[Baud], 'N', 8, 1) THEN ; { Change framing }

        HandShake := CRCREQ;      { receive in CRC mode }
        XMReset(Com);
        BatchMode(Com, FALSE);    { Ymodem only }

        WHILE X_Result = Success DO BEGIN
            X_Result := LxmRrec(Com, CRPtr^, RBSize, RTOUT, HandShake);
            IF X_Result = Success THEN BEGIN
                INC(BytesRem, RBSize);
                INC(PtrRec(CRPtr).OFS, RBSize);
                IF BytesRem >= BSize THEN { filled the IO Buffer }
                BEGIN
          {$I-}
                    BLOCKWRITE(XMFile, BPtr^, BSize);
          {$I+}
                    IF IORESULT <> 0 THEN
                        FlagAbort(Com);
                    CRPtr := BPtr; { set current record ptr }
                    BytesRem := 0;
                END;
            END;
            IF X_Result = DupBlk THEN
                X_Result := Success;
        END { while } ;
        IF (BytesRem > 0) AND     { anything left unwritten }
        (X_Result = EndFile) THEN { Is it End of File ? }
            BLOCKWRITE(XMFile, BPtr^, BytesRem); { yes, flush the buffer }

        CLOSE(XMFile);
        BatchMode(Com, FALSE);
        FreeMemCheck(BPtr, BSize);
        XMReset(Com);

        WITH Service^ DO
            IF NOT CommSetup(ComPort, CBaud[Baud], CParity[Parity], DataBits, StopBits) THEN ; { Change framing }

        IF X_Result <> EndFile THEN { if we didn't end OK }
            ERASE(XMFile);

        CloseWindow;

    END;

    {--------------------------------------------------------}

    PROCEDURE Download;
    VAR
        I              : INTEGER;
        P              : INTEGER;
        Escape         : BOOLEAN;
    BEGIN
        SelectProtocol(P);
        Remote_Name := '';
        Local_Name := '';
        OpenLogOrNENFile(Local_Name, FALSE);
        IF Local_Name = '' THEN
            Local_Name := Remote_Name;
        IF Local_Name = '' THEN EXIT;
        CASE P OF
            P_ASCII : BEGIN       { ASCII }
                      END;
            P_XMODEM,
            P_XMODEM1K,
            P_YMODEM
            : BEGIN               { Xmodem & derivatives }
                  CASE P OF
                      P_XMODEM : ;
                      P_XMODEM1K : ;
                      P_YMODEM : ;
                  END;
                  DoXmodemDownload;
              END;
        END;
    END;

    {--------------------------------------------------------}

    PROCEDURE CheckStatus;
    VAR 
        Timeout    : WORD;
        LI, LO         : WORD;
    BEGIN
        UpdateTime(FALSE);
        IF Check4Chars THEN ;
        InQueue := BytesInInput(Com);
        OutQueue := BytesInOutput(Com);
        ErrorStat := ErrorStatus(Com);
        ModemStat := ModemStatus(Com);
    END;

    {--------------------------------------------------------}
    PROCEDURE InputChar(VAR Ch : CHAR);
    VAR 
        B          : BYTE;
    BEGIN
        CheckStatus;
        IF lctGet(Com, B) THEN
            Ch := CHR(B)
        ELSE
            Ch := #0;
        IF Service^.DataBits = 7 THEN
            Ch := CHR(ORD(Ch) AND $7F);
    END;

    {--------------------------------------------------------}
    FUNCTION InChar : INTEGER;    { Special for CserveB }
    VAR 
        Ch         : CHAR;
    BEGIN
        InputChar(Ch);
        InChar := ORD(Ch);
    END;

    {--------------------------------------------------------}
    PROCEDURE OutputChar(Ch : CHAR);
    VAR 
        R          : INTEGER;
    BEGIN
        CheckStatus;
        IF LctPut(Com, BYTE(Ch)) THEN BEGIN
            CheckStatus;
            WHILE OutQueue > 0 DO BEGIN
                CheckStatus;
            END;
        END;
    END;

    {--------------------------------------------------------}
    PROCEDURE SendToRemote(Ch : CHAR);
    BEGIN
        IF Service^.UpperCase THEN Ch := UPCASE(Ch);
        OutputChar(Ch)
    END;

    {--------------------------------------------------------}
    FUNCTION ConvertCodes(St : ModemString) : ModemString;
    VAR 
        R          : INTEGER;
        T              : ModemString;
    BEGIN
        T := St;
        FOR R := 1 TO LENGTH(T) DO BEGIN
            IF T[R] = '<' THEN T[R] := #13; { CR substitute Char }
            IF T[R] = '^' THEN    { Control Char }
            BEGIN
                DELETE(T, R, 1);
                T[R] := CHR(ORD(T[R]) AND $1F);
            END;
            IF T[R] = '|' THEN    { 1 sec delay }
                T[R] := #1;
            IF T[R] = '~' THEN    { BREAK substitute Char }
                T[R] := #2;
            ConvertCodes := T;
        END;
    END;

    {--------------------------------------------------------}
    PROCEDURE OutputLine(St : ModemString);
    VAR 
        R          : INTEGER;
        Timeout        : LONGINT;
    BEGIN
        IF St = '' THEN EXIT;
        CASE St[1] OF
            '`' : DELETE(St, 1, 1); { ` Suppress CR   }
            '~' : BEGIN           { ~ Function code }
                      IF St = '~OFFLINE' THEN BEGIN
                          GoOffline;
                          OnLine := FALSE;
                          ServiceInEffect := FALSE;
                      END;
                      EXIT;
                  END;
        END;
        FOR R := 1 TO LENGTH(St) DO
            CASE St[R] OF
                #1 : BEGIN
                         Delay(1000); { 1 sec pause }
                         WRITELN(SysMsg(001061) {'[1 sec delay]'} );
                     END;
                #2 : BEGIN
                         IF SendBreak(Com) THEN ; { BREAK state }
                         WRITELN(SysMsg(001062) {'[Break]'} );
                     END;
                ELSE
                    SendToRemote(St[R]);
            END;
        CheckStatus;
        WHILE OutQueue > 0 DO
            CheckStatus;
    END;

    {--------------------------------------------------------}
    PROCEDURE WriteLog(Ch : CHAR);
    BEGIN
        IF (ORD(Ch) IN[8, 9, 10, 13, 32..127]) THEN
            WRITE(LogF, Ch);
    END;

    {--------------------------------------------------------}

    PROCEDURE WriteScreen(Ch : CHAR);
    BEGIN
        IF TermIO THEN
            WriteToScreen(Ch);
    END;

    {--------------------------------------------------------}

    PROCEDURE RunScript;
    VAR 
        I, J       : INTEGER;
        X, Y           : WORD;
        ScriptWord     : TokenString;
        Literal        : VarString;
    BEGIN
        IF NOT ScriptInEffect THEN EXIT;
        WHILE ScriptInEffect DO BEGIN
            X := WhereX;
            Y := WhereY;
            UpdateTime(FALSE);
            ReadScriptLine;
            WriteStr(39, 1, Pad(COPY(ScriptLine, 1, 28), 28), Attr(LightGray, Black));
            GoToXY(X, Y);

            IF Script_Key = 'TRANSMIT' THEN BEGIN
                ScriptWord := NextWord;
                IF ScriptWord[1] = '$' THEN BEGIN
                    Literal := ConvertCodes(ScriptVariable(ScriptWord));
                    FOR I := 1 TO LENGTH(Literal) DO BEGIN
                        WriteScreen(Literal[I]);
                        IF LogOpen THEN WriteLog(Literal[I]);
                    END;
                    OutputLine(Literal);
                END;
            END;

            IF Script_Key = 'SETMODEM' THEN BEGIN
                ScriptWord := NextWord;
                IF COPY(ScriptWord, 1, 3) = 'COM' THEN
                    CASE ScriptWord[4] OF
                        '1' : Service^.ComPort := 1;
                        '2' : Service^.ComPort := 2;
                        '3' : Service^.ComPort := 3;
                        '4' : Service^.ComPort := 4;
                    END;
                CurComm := Service^.ComPort;
                ScriptWord := NextWord;
                VAL(ScriptWord, Service^.Baud, I);
                CurBaud := Service^.Baud;
                ScriptWord := NextWord;
                CASE ScriptWord[1] OF
                    'N' : Service^.Parity := 1;
                    'E' : Service^.Parity := 2;
                    'O' : Service^.Parity := 3;
                END;
                CurParity := CParity[Service^.Parity];
                ScriptWord := NextWord;
                VAL(ScriptWord, Service^.DataBits, I);
                CurData := Service^.DataBits;
                ScriptWord := NextWord;
                VAL(ScriptWord, Service^.StopBits, I);
                CurStop := Service^.StopBits;
                ScriptWord := NextWord;
                Service^.XonXoff := ScriptWord = 'ON';
                ServiceSet := TRUE;
                UpdateStatusLine;
            END;

            IF Script_Key = 'EMULATE' THEN BEGIN
                ScriptWord := NextWord;
                IF ScriptWord = 'TTY' THEN Service^.TermType := 1;
                IF ScriptWord = 'VT52' THEN Service^.TermType := 2;
                IF ScriptWord = 'VT100' THEN Service^.TermType := 3;
                IF ScriptWord = 'ANSI' THEN Service^.TermType := 4;
                IF ScriptWord = 'VUTEXT' THEN Service^.TermType := 5;
            END;

            IF Script_Key = 'CONNECT' THEN BEGIN
                ScriptWord := NextWord;
                Service^.Connect := ScriptVariable(ScriptWord);
            END;

            IF Script_Key = 'UPPERCASE' THEN BEGIN
                ScriptWord := NextWord;
                IF ScriptWord = 'ON' THEN
                    Service^.UpperCase := TRUE;
                IF ScriptWord = 'OFF' THEN
                    Service^.UpperCase := FALSE;
            END;

            IF Script_Key = 'DIAL' THEN BEGIN
                ScriptWord := NextWord;
                Service^.Number := ScriptVariable(ScriptWord);
                WITH Service^ DO BEGIN
                    Emulation := TermType;
                    InitRemote(ComPort, Baud, CParity[Parity], DataBits, StopBits, XonXoff);

                    HangUp := FALSE;
                    IdleCount := 0;
                    IdleCheck := TRUE;

                    IF Number <> '' THEN
                        DialRemote(Number);
                    IF NOT OnLine THEN BEGIN
                        HangUp := TRUE; { unsuccessful }
                        EXIT;
                    END;
                    UpdateStatusLine;
                END;
            END;

            IF Script_Key = 'DISCONNECT' THEN BEGIN
                HangUp := TRUE;
                GoOffline;
                EXIT;
            END;

            IF Script_Key = 'TITLE' THEN BEGIN
                ScriptWord := NextWord;
                Literal := ScriptVariable(ScriptWord);
                Service^.Title := Literal;
            END;

            IF Script_Key = 'WAITFOR' THEN BEGIN
                ScriptWord := NextWord;
                Literal := ScriptVariable(ScriptWord);
                REPEAT
                    WaitForLine;
                UNTIL SearchUC(LastLine[1], LENGTH(LastLine),
                               Literal[1], LENGTH(Literal)) <> $FFFF;
            END;

        END;
    END;

    {--------------------------------------------------------}

    PROCEDURE CheckService;
    VAR 
        I          : INTEGER;
    BEGIN
        IF ScriptInEffect THEN ServiceInEffect := FALSE;
        IF NOT ServiceInEffect THEN EXIT;
        IF NOT OnLine THEN EXIT;  { Everything below here Online only! }
        IF LastLine[LENGTH(LastLine)] = Service^.PromptCh THEN
            INC(Service^.Prompts);
        IF Service^.ExitTag <> '' THEN
            IF LastLine = Service^.ExitTag THEN BEGIN
                OutputLine(ConvertCodes(Service^.ExitSt));
                EXIT;
            END;
        IF LastLine = 'NO CARRIER' THEN BEGIN
            HangUp := TRUE;
            GoOffline;
            EXIT;
        END;
        IF Service^.HostTag <> '~~~' THEN
            IF LastLine = Service^.HostTag THEN BEGIN
                OutputLine(ConvertCodes(Service^.Host));
                Service^.Host := '~~~';
                EXIT;
            END;
        IF Service^.IDtag <> '~~~' THEN
            IF LastLine = Service^.IDtag THEN BEGIN
                OutputLine(ConvertCodes(Service^.ID));
                Service^.ID := '~~~';
                EXIT;
            END;
        IF Service^.PassTag <> '~~~' THEN
            IF LastLine = Service^.PassTag THEN BEGIN
                OutputLine(ConvertCodes(Service^.Password) + #13);
                Service^.PassTag := '~~~';
                EXIT;
            END;
        IF Service^.UserTags > 0 THEN
            FOR I := 1 TO Service^.UserTags DO
                IF Service^.UserTag[I] <> '' THEN
                    IF LastLine = Service^.UserTag[I] THEN BEGIN
                        OutputLine(ConvertCodes(Service^.UserSt[I]));
                        Service^.UserTag[I] := '~~~';
                        IF I = Service^.UserTags THEN
                            Service^.UserTags := 0;
                    END;
    END;

    {--------------------------------------------------------}

    PROCEDURE UpdateLastLine;
    BEGIN
        IF InputString <> '' THEN BEGIN
            LastLine := Trim(InputString);
            CheckService;         { Check any Service actions }
        END;
        InputString := '';
    END;

    {--------------------------------------------------------}

    PROCEDURE ChangeBackgroundColor;
    VAR 
        I          : INTEGER;
    BEGIN
    END;

    {--------------------------------------------------------}

    PROCEDURE ChangeForegroundColor;
    VAR 
        I          : INTEGER;
    BEGIN
    END;

    {--------------------------------------------------------}

    FUNCTION GetNextKey : CHAR;
    VAR 
        Ch, Ch2    : CHAR;
        AtSt           : STRING[80];
        I              : INTEGER;
        Scan           : WORD;
    BEGIN
        GetNextKey := #0;
        IF Check4Chars THEN BEGIN
            GetNextChar(Ch, Ch2);
            IF Ch = #0 THEN BEGIN
                Ch := Ch2;
                GetNextKey := Ch;
                CASE Ch OF
                    UGLOBAL.F10 : BEGIN
                                      CheckMenu;
                                      GetNextKey := #0;
                                  END;
                    UGLOBAL.F5 : BEGIN
                                     ChangeBackgroundColor;
                                     GetNextKey := #0;
                                 END;
                    UGLOBAL.F6 : BEGIN
                                     ChangeForegroundColor;
                                     GetNextKey := #0;
                                 END;
                    UGLOBAL.PgUp : Upload;
                    UGLOBAL.PgDn : Download;
                    UGLOBAL.F9 : IF UserSaysYes(SysMsg(001063) {'Quit?'} , EscapemeansNo) THEN
                                     Comm_Quit := TRUE;
                    UGLOBAL.F3 : OnLine := TRUE;
                END;
            END
            ELSE BEGIN
                IF Ch > #2 THEN   { 1 & 2 are Control/Alternate, ch2 is char}
                    GetNextKey := Ch
                ELSE
                    GetNextKey := Ch2;
                NormalCursor;
            END;
        END;
    END;

    {--------------------------------------------------------}
    { Main Remote input routine                              }

    PROCEDURE GetInputData;
    VAR 
        Ch, Ch2    : CHAR;
    BEGIN

        CheckStatus;

        WHILE InQueue > 0 DO BEGIN
            CheckStatus;
            IF InQueue > 0 THEN BEGIN

                IF Check4Chars THEN { Kbd check in case ^O etc. }
                BEGIN
                    WHILE Check4Chars DO BEGIN
                        Ch := GetNextKey;
                        SendToRemote(Ch);
                    END;
                END;

                InputChar(Ch);

                IF Ch <> #0 THEN BEGIN

                    CheckEmulation(Service^.ComPort, Ch);

                    IF Ch <> #0 THEN BEGIN
                        IF Ch IN[#32..#127] THEN
                            InputString := InputString + Ch; { Update our check string }

                        WriteScreen(Ch); { Write rcvd char to scrn }

                        IF LogOpen THEN WriteLog(Ch); { Write rcvd char to log  }

                        WriteCaptureBuffer(Ch);

                        IF Ch = #13 THEN { CR } { if CR, check for keywords }
                        BEGIN
                            UpdateLastLine;
                            IdleCheck := FALSE;
                            IdleCount := 0;
                            EXIT;
                        END;
                    END;
                END;
            END;
        END;
    END;

    {--------------------------------------------------------}
    PROCEDURE WaitForCommandResponse;
    VAR 
        R          : INTEGER;
    BEGIN
        CheckStatus;
        Delay(250);
        CheckStatus;
        IF InQueue > 0 THEN
            GetInputData;
    END;

    {--------------------------------------------------------}
    PROCEDURE WriteCommandToModem(S : ModemString);
    VAR 
        I          : INTEGER;
        T              : LONGINT;
    BEGIN
        OutputLine(S + #13);
        Delay(250);               { Give modem a change to respond }
        WaitForCommandResponse;
    END;

    {**********************************************************************}
    { Log File support                                                     }
    {**********************************************************************}

    {--------------------------------------------------------}
    PROCEDURE OpenLogFile(Log : ModemString);
    BEGIN
        IF Log = '' THEN EXIT;
        LogOpen := FALSE;
        ASSIGN(LogF, Log);
    {$I-}
        RESET(LogF);
        IF IORESULT <> 0 THEN     { No file found, create it }
            REWRITE(LogF)
        ELSE BEGIN
            CLOSE(LogF);          { File found, append to it }
            IF UserSaysYes(SysMsg(001064) {'File exists, Append to it?'} , EscapemeansNo) THEN
                APPEND(LogF)
            ELSE
                EXIT;
        END;
        IF IORESULT <> 0 THEN EXIT;
    {$I+}
        LogOpen := TRUE;
    END;

    {--------------------------------------------------------}
    PROCEDURE CloseLogFile;
    BEGIN
        IF NOT LogOpen THEN EXIT;
        CLOSE(LogF);
        LogOpen := FALSE;
    END;

    {**********************************************************************}
    { Exported routines to provide Remote Comm support                     }
    {**********************************************************************}

    {--------------------------------------------------------}

    PROCEDURE SetupModem;
    BEGIN
        SwitchModemToCommandState; { Force modem into Command mode }

        WriteCommandToModem(ModemReset); { Reset modem }
        WriteCommandToModem(NoEcho); { No Command echo }
        WriteCommandToModem(Result); { Result type }
        WriteCommandToModem(ResultOn); { Results on }
        WriteCommandToModem(Speaker); { Speaker mode }
        WriteCommandToModem(Loud); { Speaker volume }
    END;

    {--------------------------------------------------------}
    PROCEDURE UpdateStatusLine;
    BEGIN
        WITH CommWin^, wFrame DO BEGIN
            {        WriteStr(2,1,pad('',69),Attr(LightGray,Black));}
            UpdateTime(FALSE);
{        WriteChr( 7,1,#$B3,Attr(LightGray,Blue));
        WriteChr(12,1,#$B3,Attr(LightGray,Blue));
        WriteChr(14,1,#$B3,Attr(LightGray,Blue));
        WriteChr(16,1,#$B3,Attr(LightGray,Blue));
        WriteChr(18,1,#$B3,Attr(LightGray,Blue));
        WriteChr(38,1,#$B3,Attr(LightGray,Blue));}
            WriteStr(6, frYH, 'COM' + Long2Str(CurComm) + #$B3 +
                     Pad(Long2Str(CurBaud), 4) + #$B3 + CurParity + #$B3 +
                     Long2Str(CurData) + #$B3 + Long2Str(CurStop), frHeaderColor);
            WriteStr(frXH - LENGTH(Service^.Title) - 1,
                     frYH,
                     Service^.Title, frHeaderColor);
            IF LogOpen THEN
                WriteStr(19, frYH, LogFile, frHeaderColor);
            {        WriteChr(1,1,#$F0,Attr(LightGray,Yellow));}
            {    Window(1,2,80,25);}
        END;
    END;

    {--------------------------------------------------------}
    PROCEDURE InitRemote(ComPort : WORD; Baud : WORD; Parity : CHAR; Data : WORD;
                         Stop : WORD; XonXoff : BOOLEAN);
    BEGIN
        GoToXY(1, 1);
        Com := ComPort;
        UpdateStatusLine;
        Bl := CommOpen(Com, Baud, Parity, Data, Stop, InBufSize, OutBufSize, TRUE);
        IF NOT Bl THEN HALT(1);
        CASE Com OF
            COM3 : Bl := PortChange(Com, IntReg3, $10, Vector3); { Special chained vectors }
            COM4 : Bl := PortChange(Com, IntReg4, $08, Vector4); { for Com3 & 4            }
        END;

        IF XonXoff THEN
            Bl := EnableXon(Com, XonXoff);

        CheckStatus;

        CurComm := Com;
        CurBaud := Baud;
        CurParity := Parity;
        CurData := Data;
        CurStop := Stop;

        TermIO := FALSE;

        OpenWindow(21, 9, 51, 15, '', Gray_Scheme);
        TextColor(White);
        HiddenCursor;
        WriteCentred(3, SysMsg(001065) {'Initializing Modem'} );

        SetWindowColors;
        NormalCursor;

        SetupModem;

        CloseWindow;
        TermIO := TRUE;

        InputString := '';
        LastLine := '';
        ServiceInEffect := TRUE;
        OnLine := FALSE;
        CommSet := TRUE;
        Comm_Quit := FALSE;
    END;

    {--------------------------------------------------------}
    PROCEDURE GoOffline;
    BEGIN
        IF CommSet THEN BEGIN
            CommSet := FALSE;
            SwitchModemToCommandState;
            IF NOT HangUp THEN
                WriteCommandToModem(OnHook);
            WRITELN(SysMsg(001066) {'[Disconnect]'} );
            CommClose(Service^.ComPort, TRUE);
        END;
        OnLine := FALSE;
        HangUp := TRUE;
        ServiceInEffect := FALSE;
        ScriptInEffect := FALSE;
    END;

    {--------------------------------------------------------}

    PROCEDURE WaitForLine;
    VAR 
        Ch         : CHAR;
        W              : WORD;
    BEGIN
        W := 0;
        REPEAT
            INC(W);
            InputChar(Ch);
            IF Ch <> #0 THEN
                LastLine := LastLine + Ch;
        UNTIL (Ch = #13) OR(W >= 30000);
    END;

    {--------------------------------------------------------}

    PROCEDURE DialRemote(TelNum : PhoneString);
    CONST
        BUSYst         : STRING[4] = 'BUSY';
        CONNECTst      : STRING[7] = 'CONNECT';
    VAR 
        Busy, Timeout : BOOLEAN;
        Ch             : CHAR;
        Ch1, Ch2       : CHAR;
        TCount         : WORD;
    BEGIN
        OpenWindow(21, 9, 51, 15, '', Gray_Scheme);
        TextColor(Red);
        HiddenCursor;
        ReDial := 0;
        WriteCentred(2, SysMsg(001067) {'Dialing'} );
        WriteCentred(3, TelNum);

        IF PurgeRXBuff(Com) THEN ;
        TermIO := FALSE;
        ServiceInEffect := TRUE;

        Busy := TRUE;
        Timeout := FALSE;
        TCount := 0;
        WHILE Busy DO BEGIN
            WriteCentred(2, SysMsg(001068) {'    Dialing    '} );
            SwitchModemToCommandState;
            WriteCommandToModem(ToneDial + TelNum);
            OnLine := FALSE;
            LastLine := '';
            REPEAT
                INC(TCount);
                IF TCount > 50000 THEN Timeout := TRUE;
                IF Check4Chars THEN BEGIN
                    GetNextChar(Ch1, Ch2);
                    Timeout := TRUE;
                END;
                WaitForLine;
            UNTIL (Search(LastLine[1], LENGTH(LastLine), BUSYst[1], 4) <> $FFFF) OR
            (Search(LastLine[1], LENGTH(LastLine), CONNECTst[1], 7) <> $FFFF) OR
            Timeout;
            IF (Search(LastLine[1], LENGTH(LastLine), CONNECTst[1], 4) <> $FFFF) THEN BEGIN
                Busy := FALSE;
                OnLine := TRUE;
            END;
            IF Busy THEN BEGIN
                OnLine := FALSE;
                WriteCommandToModem('+++' + OnHook);
                INC(ReDial);
                IF ReDial > ReDialMax THEN
                    Busy := FALSE;
                WriteCentred(2, SysMsg(001069) {'BUSY, Redialing'} );
            END;
            IF (NOT Busy) AND OnLine THEN BEGIN
                Busy := FALSE;
                WriteCentred(3, SysMsg(001070) {'[Connection Established]'} );
            END;
        END;
        IF Timeout THEN BEGIN
            WriteCentred(3, SysMsg(001071) {'Time Out'} );
            GoOffline;
            SetupModem;
        END;
        CloseWindow;
        TermIO := TRUE;
        GoToXY(1, 1);
        TextAttr := NENColorSet.TextColor;
        HideMouse;
        {    ClrScr;}
        ShowMouse;
        MouseGotoXY(1, 1);
        IF OnLine THEN
            OutputLine(ConvertCodes(Service^.Connect));
        LastLine := '';
    END;

    {--------------------------------------------------------}

    PROCEDURE DisableMenu;
    BEGIN
        TopMenu^.ERASE;
        DISPOSE(TopMenu, Done);
        ShowMouse;
    END;

    {--------------------------------------------------------}

    PROCEDURE EnableMenu;
    BEGIN
        HideMouse;
        InitMenu(TopMenu);
        TopMenu^.Draw;
        UpdateStatusLine;
        ShowMouse;
    END;

    {--------------------------------------------------------}

    PROCEDURE OpenLogOrNENFile(VAR FName : DirStr; Log : BOOLEAN);
    VAR
        HdrAddress     : INTEGER;
        I              : INTEGER;
        TempWin        : POINTER;
        Escape         : BOOLEAN;
    BEGIN
        ChangeDrive(CW^.QDrive);
        IF ExistFile('QHDR') THEN BEGIN
            TimeDisplayOn := FALSE;
            NEW(WorkHdr);
            InitInUseHdr(WorkHdr^);
            MsgString := '';
            GetFileName('*.LOG', MsgString);
            IF Escape THEN EXIT;
            IF SaveWindow(1, 1, 80, 25, TRUE, TempWin) THEN ;
            ScreenOn := TRUE;
            ChangeDrive(CW^.QDrive);
            FName := MsgString;
            WorkHdr^.Slug := FName;
            NewFile(FName, FALSE);
            RestoreWindow(1, 1, 80, 25, TRUE, TempWin);
            ChangeDrive(CW^.QDrive);
            IF NOT GetHdr(WorkHdr^.Slug, CW^.WorkHeapHdr, I) THEN
                EXIT;
            ScreenOn := FALSE;
            Local_Name := 'Q' + Long2Str(CW^.WorkHeapHdr^.Hdr^.DOSScriptFile);
            ChangeDrive(CW^.QDrive);
            IF Log THEN BEGIN
                LogFile := Local_Name;
                ASSIGN(LogF, LogFile);
           {$I-}
                APPEND(LogF);
                IF IORESULT = 0 THEN
                    LogOpen := TRUE;
           {$I+}
            END;
            DISPOSE(WorkHdr);
        END
        ELSE BEGIN
            FName := '';
            GetFileName('*.LOG', FName);
            IF Log THEN BEGIN
                IF LogOpen THEN
                    CloseLogFile;
                LogFile := FName;
                IF LogFile <> '' THEN
                    OpenLogFile(LogFile);
            END;
        END;
    END;

    {--------------------------------------------------------}

    PROCEDURE ExecuteMenuChoice(Cmd : WORD);
    VAR 
        Newlog     : PathStr;
        I              : WORD;
        Err            : INTEGER;
        AlreadyOnline  : BOOLEAN;
        Escape         : BOOLEAN;
    BEGIN
        CASE Cmd OF
            2 : BEGIN             { Open Log }
                    OpenLogOrNENFile(Newlog, TRUE);
                    TopMenu^.EraseCurrentSubMenu;
                END;
            3 : BEGIN             { Close Log }
                    IF LogOpen THEN
                        CloseLogFile;
                    TopMenu^.EraseCurrentSubMenu;
                END;
            4 : BEGIN             { View File }
                    ViewLog := '';
                    IF LogFile <> '' THEN
                        UData^.LastFilePath := LogFile;
                    GetFileName('*.LOG', ViewLog);
                    TopMenu^.EraseCurrentSubMenu;
                    {            Window(1,1,80,25);}
                    IF ViewLog <> '' THEN BEGIN
                        DisableMenu;
                        Window(1, 1, 80, 25);
                        NormalCursor;
                        GoToXY(1, 2);
                        WRITE(SysMsg(001074) {'Reading File '} + ViewLog + ' ......');
                        ReadFile(ViewLog);
                    END;
                    {            Window(1,2,80,25);}
                    UpdateStatusLine;
                END;
            7 : BEGIN             { Quit }
                    TopMenu^.EraseCurrentSubMenu;
           (*if UserSaysYes(SysMsg(001063){'Quit?'},EscapeMeansNo) THEN BEGIN *)
                    Comm_Quit := TRUE;
                    IF OnLine THEN
                        GoOffline;
                    {end;}
                END;
            13 : BEGIN            { Edit Service }
                     IF NOT OnLine THEN
                         SelectService(I)
                     ELSE
                         I := CurrentService;
                     IF I <> 0 THEN BEGIN
                         SetupService(I);
                         EditService(Service^);
                         {                if SetMenuItemName(TopMenu,22+CurrentService,Service^.Title) then ;}
                     END;
                     TopMenu^.EraseCurrentSubMenu;
                 END;
            14 : BEGIN            { Add Service }
                     AddNewService;
                     DISPOSE(TopMenu, Done);
                     InitMenu(TopMenu);
                 END;
            16 : BEGIN            { Dial }
                     TopMenu^.EraseCurrentSubMenu;
                     DisableMenu;
                     BlankService(Service^);
                     CurrentService := $FFFF;
                     Service^.Title := SysMsg(000872) {'**Temporary**'} ;
                     EditService(Service^);
                     IF Service^.Number <> '' THEN
                         GoOnline;
                 END;
            17 : BEGIN            { Hang Up }
                     TopMenu^.EraseCurrentSubMenu;
                     DisableMenu;
                     GoOffline;
                 END;
            18 : Upload;
            19 : Download;
            22..40 : BEGIN        { Go Service }
                         SetupService(Cmd - 21);
                         Com := Service^.ComPort;
                         ServiceSet := TRUE;
                         Baud_Rate := CBaud[Service^.Baud];
                         TopMenu^.EraseCurrentSubMenu;
                         DisableMenu;
                         Comm_Quit := FALSE;
                         GoOnline;
                     END;
            51 : BEGIN
                     ChooseScript(ScriptName);
                     IF ScriptName <> '' THEN BEGIN
                         OpenScript(ScriptName);
                         TopMenu^.EraseCurrentSubMenu;
                         DisableMenu;
                         AlreadyOnline := OnLine;
                         RunScript;
                         IF (OnLine) AND(NOT AlreadyOnline) THEN GoOnline;
                     END;
                 END;
            52 : BEGIN
                     CreateScript;
                 END;
            53 : BEGIN
                     EditScript;
                 END;
        END;
        UpdateStatusLine;
    END;

    {--------------------------------------------------------}

    PROCEDURE CheckMenu;
    VAR 
        SaveX, SaveY : WORD;
        Scan, Scan2    : WORD;
        NK             : BYTE;
    BEGIN
        SaveX := WhereX;
        SaveY := WhereY;
        ShowMouse;

        EnableMenu;
        WITH TopMenu^ DO BEGIN
            Process;
            GetCommandProcessor^.GetKeyAssignment(GetLastCommand, NK, Scan, Scan2);
        END;
        CASE Scan OF
            OpKey.F5 : ChangeBackgroundColor;
            OpKey.F6 : ChangeForegroundColor;
            OpKey.F9,
            OpKey.Esc : IF UserSaysYes(SysMsg(001063) {'Quit?'} , EscapemeansNo) THEN
                            Comm_Quit := TRUE;
            ELSE BEGIN
                    ExecuteMenuChoice(TopMenu^.ActiveItemPtr^.ItemKey);
                END;
        END;
        IF OnLine THEN
            DisableMenu;
        WriteStr(1, 1, #$F0, Attr(LightGray, Yellow));
        {    Window(1,2,80,25);}
        GoToXY(SaveX, SaveY);
        NormalCursor;
    END;

    {--------------------------------------------------------}
    PROCEDURE GoOnline;
    BEGIN
        IF NOT ServiceSet THEN EXIT;
        IF NOT OnLine THEN BEGIN
            WITH Service^ DO BEGIN
                InitRemote(ComPort, CBaud[Baud], CParity[Parity], DataBits, StopBits, XonXoff);

                Emulation := TermType;

                HangUp := FALSE;
                ServiceInEffect := TRUE;
                IdleCount := 0;
                IdleCheck := TRUE;

                IF Number <> '' THEN
                    DialRemote(Number);
                IF NOT OnLine THEN BEGIN
                    HangUp := TRUE; { unsuccessful }
                    EXIT;
                END;
            END;
        END;

        UpdateStatusLine;

        WHILE NOT HangUp DO BEGIN
            WHILE (NOT Check4Chars) AND(NOT HangUp) DO { Loop waiting for keyboard input }
            BEGIN
                CheckStatus;      { Check I/O buffers }
                IF InQueue > 0 THEN BEGIN
                    IdleCount := 0;
                    IdleCheck := TRUE; { Input pending, go process }
                    GetInputData;
                END
                ELSE BEGIN
                    IF IdleCheck THEN { No input, bump idle count }
                        INC(IdleCount);
                END;
                { char time timeout = BaudRate/10 bits per char }
                IF IdleCount >= ((CBaud[Service^.Baud]DIV 10) * ChTimes) THEN { if Idle timeout, update last line }
                BEGIN
                    IdleCount := 0;
                    UpdateLastLine;
                    IdleCheck := FALSE;
                END;
            END;

            IF HangUp THEN EXIT;
            WHILE (Check4Chars) AND(NOT HangUp) DO { Send from keyboard }
            BEGIN
                Ch1 := GetNextKey;
                IF NOT OnLine THEN EXIT; { GetNextKey disconnected }
                IF Ch1 <> #0 THEN
                    SendToRemote(Ch1);
            END;
        END;
    END;

    {--------------------------------------------------------}
    PROCEDURE CloseRemote;
    BEGIN
        CloseLogFile;
        IF CommSet THEN
            CommClose(Com, TRUE);
        CommSet := FALSE;
        {    CloseWindow;}
        RestorePrompt;
    END;


    {--------------------------------------------------------}
    PROCEDURE InitMenu;
    VAR
        I              : INTEGER;
        Xb             : BYTE;
    CONST
        Frame1         : FrameArray = '…»ªºÕÕ∫∫';
        Frame2         : FrameArray = '…»ªºÕÕ∫∫';
        {  Frame2 : FrameArray = #203+'»'+#203+'ºÕÕ∫∫';}

    BEGIN
        {Customize this call for special exit characters and custom item displays}
        Gray_Scheme;
        WITH CommWin^, wFrame DO
            NEW(TopMenu, InitCustom(frXl + 1, frYL + 1, frXH - 1, frYL + 1,
                                    NENColorSet,
                                    wClear + wUserContents, Horizontal));

        TextColors;
        Xb := CommWin^.wFrame.frXl + 1;
        WITH TopMenu^ DO BEGIN
            mnOptionsOn(mnAlphaMatch + mnSelectOnMatch + mnArrowSelect + mnAllHotSpots);
            AddShadows(FALSE, shBR, shSeeThru);
            CustomizeCommandProcessor(MenuCommands);

            AddItem(SysMsg(000974) {'File'} , 3, 1, 1);
            AddFramedSubMenu(Xb + 3, 6, Xb + 16, 13, Vertical, Frame2);
            AddShadows(FALSE, shBR, shSeeThru);
            AddItem(SysMsg(001075) {'Open Log'} , 1, 1, 2);
            AddItem(SysMsg(001076) {'Close log'} , 2, 1, 3);
            AddSeparator(#$C7, #$C4, #$B6, 3);
            AddItem(SysMsg(000932) {'View File'} , 4, 1, 4);
            AddItem(SysMsg(001077) {'Print File'} , 5, 1, 5);
            AddItem(SysMsg(001078) {'Delete File'} , 6, 1, 6);
            AddSeparator(#$C7, #$C4, #$B6, 7);
            AddItem(SysMsg(000660) {'Quit'} , 8, 1, 7);
            ItemsDone;

            AddItem(SysMsg(001079) {'Printer'} , 9, 1, 8);
            AddFramedSubMenu(Xb + 9, 6, Xb + 17, 8, Vertical, Frame2);
            AddShadows(FALSE, shBR, shSeeThru);
            AddItem(SysMsg(000661) {'Select'} , 1, 1, 9);
            AddItem('On', 2, 1, 10);
            AddItem('Off', 3, 1, 11);
            ItemsDone;

            AddItem(SysMsg(001080) {'Modify'} , 18, 1, 12);
            AddFramedSubMenu(Xb + 18, 6, Xb + 31, 7, Vertical, Frame2);
            AddShadows(FALSE, shBR, shSeeThru);
            AddItem(SysMsg(001081) {'Edit Service'} , 1, 1, 13);
            AddItem(SysMsg(001082) {'Add Service'} , 2, 1, 14);
            ItemsDone;

            AddItem(SysMsg(000870) {'Action'} , 27, 1, 15);
            AddFramedSubMenu(Xb + 27, 6, Xb + 37, 10, Vertical, Frame2);
            AddShadows(FALSE, shBR, shSeeThru);
            AddItem(SysMsg(001083) {'Dial'} , 1, 1, 16);
            AddItem(SysMsg(001084) {'Hang Up'} , 2, 1, 17);
            AddItem(SysMsg(001085) {'Upload'} , 3, 1, 18);
            AddItem(SysMsg(001060) {'Download'} , 4, 1, 19);
            AddItem(SysMsg(001086) {'Transfer'} , 5, 1, 20);
            ItemsDone;

            AddItem(SysMsg(001087) {'Service'} , 35, 1, 21);
            AddFramedSubMenu(Xb + 35, 6, Xb + 50, 12, Vertical, Frame2);
            AddShadows(FALSE, shBR, shSeeThru);
            BuildServiceMenu;
            ItemsDone;
            ItemsDone;
        END;

        UpdateStatusLine;
        TopMenu^.Draw;
        BlankService(Service^);
    END;

    {--------------------------------------------------------}
    PROCEDURE RunRemote(GoService : ServiceType; Go : BOOLEAN);
    VAR 
        Ch         : CHAR;
        Res            : INTEGER;
        SaveNENFlag    : BOOLEAN;
        SaveClockX, SaveClockY : INTEGER;
        SaveClockAttr, SaveBorderAttr : BYTE;
        CommCommands   : DragProcessorPtr;
    CONST
        HelpSt         : STRING[17] = 'F1-HELP, F10-EXIT';
    BEGIN
        TextColors;
        NEW(CommCommands, Init(@EditorKeySet, EditorKeyMax));
        NEW(CommWin, InitCustom(5, 4, 75, 21, NENColorSet,
                                DefWindowOptions OR wResizeable OR wBordered,
                                CommCommands^, UcNone));
        CustomizeCommandProcessor(CommCommands^);

        WITH CommWin^ DO BEGIN
            CustomizeWindow(CommWin^, ' Communications ', 16);
            CX := 1;
            Cy := 1;
            Colors := NENColorSet;
            Draw;
        END;

        WITH UData^ DO BEGIN
            HelpSt := SysMsg(1091);
            TimeDisplayOn := FALSE;
            FirstletterHighlight := TRUE;
            SaveNENFlag := NENFlag;
            NENFlag := FALSE;
            OnLine := FALSE;

            IF NOT Go THEN
                BlankService(Service^);

            DisableControlC;
            CheckBreak := FALSE;  { ^C must be passed to remote }

            SetBlink(FALSE);
            SetPaletteRegister(6, 38);

            SavePrompt;
            {    OpenWindow(2,2,79,24,'',TextColors);}
            {    Window(1,2,80,25);}

            LastFilePath := '*.LOG';

            GoToXY(1, 1);
            SetWindowColors;
            NormalCursor;
            Comm_Quit := FALSE;
            ReqNumber := GoService.Number;
            ReqTerm := GoService.TermType;
            SetClockMode(TRUE);
            SaveClockX := ClockX;
            SaveClockY := ClockY;
            SaveClockAttr := ClockAttr;
            SaveBorderAttr := BorderAttr;
            ClockX := 70;
            ClockY := 1;
            ClockAttr := Attr(LightGray, Blue);
            BorderAttr := Attr(LightGray, LightGray);
            Baud_Rate := GoService.Baud;
            Data_Bits := GoService.DataBits;
            MouseGotoXY(40, 12);
            ShowMouse;
            ServiceSet := FALSE;
            CommSet := FALSE;

            IF Go THEN BEGIN
                DisableMenu;
                Service^ := GoService;
                ServiceSet := TRUE;
                WriteStr(CommWin^.wFrame.frXH - LENGTH(Service^.Title) - 1,
                         CommWin^.wFrame.frYH,
                         Service^.Title, Attr(LightGray, White));
            END;
            {    Window(1,2,80,25);}
            NormalCursor;
            GoToXY(1, 1);

            IF NOT Go THEN
                CheckMenu;

            OpenCaptureBuffer;

            WHILE NOT Comm_Quit DO { Main offline loop }
                { once GoOnline is called, Loop is there }
                { Control returns here when GoOffline is called }
            BEGIN
                IF Go THEN GoOnline { if 'GO' mode, go directly online }
                ELSE CheckMenu;   { else, wait for menu action       }
                Go := FALSE;
            END;

            CloseCaptureBuffer;
            CloseService;
            TopMenu^.ERASE;
            DISPOSE(TopMenu, Done);
            CloseRemote;          { Someone caused Comm_Quit to be set, Close up }
            TimeDisplayOn := TRUE;
            NENFlag := SaveNENFlag;
            ClockX := SaveClockX;
            ClockY := SaveClockY;
            ClockAttr := SaveClockAttr;
            BorderAttr := SaveBorderAttr;
            FirstletterHighlight := FALSE;
            CommWin^.ERASE;
            DISPOSE(CommWin, Done);
            DISPOSE(CommCommands, Done);
        END;

    END;
{$ENDIF} {notnen}
END.


