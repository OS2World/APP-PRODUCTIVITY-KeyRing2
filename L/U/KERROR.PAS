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
* Generic error handler
* If you include this unit in your code, it will automatically log all fatal
* program crashes to a hard disk error file.
*
* ~notesend~
*
****************************************************************************
}
{$I OPDEFINE.INC}
{$I NDEFINE.INC}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
{$D+,L+}
{&LocInfo+}

UNIT KERROR;

INTERFACE
USES
    Dos,
    Mutex,
    OpConst,
    OpCRT,
    OpCtrl,
    OpRoot,
    OpWindow
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

CONST
    MsgSize        = 5;
    ecUserAbort    = epNonFatal + 999;
    ISAMERROROFST  = 70000;
    DispErrorDelayMS : WORD = 400;
TYPE
    BeepType       = (OldBeep,    {low beep }
                      TRIPLE,     {high beep beep beep}
                      BADKEY,     {med beep}
                      OprError,   {med beep beep}
                      TESTFAIL,   {crash 'n burn}
                      TESTPASS,   {weep weep weep}
                      WEEP3,      {weep woop weep woop weep woop}
                      RANDBEEP,   {B-Movie computer noises}
                      ATNBEEP,    {ta da}
                      CQBEEP);    {morse code}

    MsgArray       = ARRAY[1..MsgSize] OF STRING;

    ClockProcT     = PROCEDURE;
    TUserErrorMessageProc = FUNCTION(Status : LONGINT) : STRING;

    {cylon is moving dot activity indicator useful to tell user that time consuming tasks}
    {are actually making progress.  Use for printing, serial comm, database crunching... }

    CylonObjPtr    = ^CylonObj;
    CylonP         = ^CylonObj;

    CylonObj       = OBJECT(StackWindow)
                         {normal init}
                         CONSTRUCTOR Init(Header : STRING; CWidth : INTEGER);
                         {init with delayed display to prevent flashing (Cylon Flash Delay)}
                         CONSTRUCTOR InitCFD(Header : STRING; CWidth, CFD : INTEGER);
                             {Init with custom top and bottom headers}
                         CONSTRUCTOR InitDeluxe(TopHeader, BotHeader : STRING);
                             {draw the cylon on screen}
                         PROCEDURE Draw; VIRTUAL;
                             {move dot on screen}
                         FUNCTION UpDate : BOOLEAN;
                             {go to standby mode}
                         PROCEDURE Sleep;
                             {deal with stacked windows}
                         PROCEDURE MarkCurrent; VIRTUAL;
                         PROCEDURE MarkNotCurrent; VIRTUAL;
                             {dispose of cylon}
                         DESTRUCTOR Done; VIRTUAL;
                             {change top header string}
                         PROCEDURE ChangeTopHeader(Header : STRING);
                             {change bottom header string}
                         PROCEDURE ChangeBotHeader(Header : STRING);
                             {return top header string}
                         FUNCTION GetTopHeader : STRING;
                             {return bottom header string}
                         FUNCTION GetBotHeader : STRING;
                             {force new cylon flash delay}
                         PROCEDURE SetCFD(NewCFD : LONGINT);

                     PRIVATE

                         NumDots,
                         Count          : INTEGER;
                         CylonFlashDelay,
                         InitTime,
                         LastTime       : LONGINT;
                         IsDrawn,
                         KeyCap         : BOOLEAN;
                         Parent         : WindowPtr;
                         TopHead,
                         BotHead        : STRING[80];
                     END;

    (****************************************************************************)
PROCEDURE VidSemPush;
PROCEDURE VidSemPop;
    {- returns string containing meaning of Opro and TP error codes}
FUNCTION ErrorMessage(Status : LONGINT) : STRING;

    {- display a two line, dynamically sized error dialog and log the error to disk}
PROCEDURE DispError(Strg1, Strg2 : STRING; LogIt : BOOLEAN);
    {Change name of error log file from default <exename>.ERR}
PROCEDURE ChangeErrorLogFile(Name : STRING);
    {change path of error log file from default <exedir>}
PROCEDURE ChangeErrorLogDir(Name : STRING);

    {- display a two line, dynamically sized error dialog and log the error}
    {  and MAP file address of the error line of code                      }
PROCEDURE DispErrorDeluxe(Strg1,
                          Strg2          : STRING;
                          LogIt          : BOOLEAN;
                          P              : POINTER);

    {- return current time in centiseconds since midnight (100 = 1 second past midnite)}
FUNCTION KTimer : LONGINT;

    {- return formatted current time and date - US format only}
FUNCTION TimeDateNow : STRING;

    {- log a two line error message to the PROGNAME.ERR file }
PROCEDURE Autopsy(Strg1, Strg2 : STRING);

    {- log a two line error message to the PROGNAME.ERR file, along with the }
    {   MAP file address of the error line                                   }
PROCEDURE AutopsyDeluxe(Strg1, Strg2 : STRING; P : POINTER);

PROCEDURE KAbstract(P : POINTER);

    {- make all sorts of wierd noises}
PROCEDURE Beep(Tone : BeepType);

    {- if opro init fails with InitStatus = 0 then probably out of memory}
PROCEDURE CheckNilInit;

    {- set the name of the person/company to alert when an error occurs}
PROCEDURE SetCompanyName(Name : STRING);
    {- set string containing biz hours of company phone support}
PROCEDURE SetCompanyHours(Msg : STRING);

PROCEDURE KillCompanyName;
    {- draw a clock on the screen}
PROCEDURE DefaultClock;
    {- use this if you don't want to draw a clock on screen}
PROCEDURE NILClock;

    {$IFDEF DEBUG}
    {debug proc to detect memory leaks}
PROCEDURE MemFree(Loc : STRING; P : POINTER);
    {$IFNDEF DPMI}
PROCEDURE HeapWalk(Note : STRING; P : POINTER);
    {$IFNDEF VirtualPascal}
    {gobble heap until there is MemToLeave bytes free}
PROCEDURE EatMe(MemToLeave : LONGINT);
    {spit out gobbled heap}
PROCEDURE Puke;

    {write list of used and free heap blocks to file in ascii text}
    {$ENDIF}
    {$ENDIF}
    {$ENDIF}
    (********************************************)
VAR
    ProgramRevision : STRING;
    ProgramDate    : STRING[30];
    CurrentClockProc : ClockProcT;
    CurrentUserErrorMessageProc : TUserErrorMessageProc;
    ScreenSem,
    ErrorLogSem : tMutexSem;

    LastCX : BYTE;
    LastCY : BYTE;


CONST
    ProgramRelease : STRING[30] = '~release~';

    {~nokeywords~}

IMPLEMENTATION

USES
    {$IFDEF PENTIUMII}
    DELAYCAL,
    {$ENDIF}
    DGLib,
    Strings,
    {$IFDEF DEMO}
    {CRC,}
    {$ENDIF}
    FDIALOG,
    {$IFDEF AllowIsamErrorMessages}
    IsamTool,
    {$ENDIF}
    OpCmd,
    OpCol16,
    OpDate,
    OpDialog,
    OpDos,
    OpField,
    OpFrame,
    OpInline,
    OpKey,
    {$IFDEF VirtualPascal}
    SysUtils,
    vputils,
    {$ENDIF}
    {$IFDEF USEMOUSE}
    OpMouse,
    {$ENDIF}
    OpString,
    UTIAM,
    UTLCS,
    UTTIMDAT;

    (********************************************)
VAR
    CompanyName,
    CompanyHours   : StringPtr;
    LogName        : STRING;

    PROCEDURE VidSemPush;
    BEGIN
        IF Assigned(ScreenSem) then begin
            ScreenSem.Request;
            LastCX := WhereXAbs;
            LastCY := WhereYAbs;
        end;
    END;

    (********************************************)

    PROCEDURE VidSemPop;
    BEGIN
        IF Assigned(ScreenSem) then begin
            GotoXYabs(LastCX, LastCY);
            ScreenSem.Release;
        end;
    END;

    (********************************************)

    FUNCTION NilUserErrorMessageProc(Status : LONGINT) : STRING; FAR;
    BEGIN
        NilUserErrorMessageProc := '';
    END;

    (********************************************)

    PROCEDURE ChangeErrorLogFile(Name : STRING);
    BEGIN
        LogName := Name;
    END;

    (********************************************)

    PROCEDURE ChangeErrorLogDir(Name : STRING);
    BEGIN
        LogName := ForcePath(Name, LogName);
    END;

    (********************************************)

    {Turns a pascal string into a pchar - reciprocal function }
    {for StrPas                                               }
    {Warning: Possible heap leakage if you fail to deallocate!}
    FUNCTION PasStr(Strg : STRING) : PCHAR;
    VAR
        T              : PCHAR;
        L              : BYTE;
    BEGIN
        PasStr := NIL;
        L := LENGTH(Strg);
        GetMemCheck(T, L + 1);
        IF T = NIL THEN
            EXIT;
        MOVE(Strg[1], T^, L);
        T[L + 1] := #0;
        PasStr := T;
    END;

    (****************************************************************************)

    {- set the name of the person/company to alert when an error occurs}
    PROCEDURE SetCompanyName(Name : STRING);
    BEGIN
        CompanyName := StringToHeap(Name);
    END;

    (********************************************)

    PROCEDURE SetCompanyHours(Msg : STRING);
    BEGIN
        CompanyHours := StringToHeap(Msg);
    END;

    (********************************************)

    PROCEDURE KillCompanyName;
    BEGIN
        DisposeString(CompanyName);
        DisposeString(CompanyHours);
        CompanyName := NIL;
        CompanyHours := NIL;
    END;

    (********************************************)
VAR
    Ds             : DateString;
    Ts             : STRING[15];

    {- return current formatted time and date - not internationalized or configurable}
    FUNCTION TimeDateNow : STRING;
    BEGIN
        TimeDateNow := DateToDateString(Ds, Today) +
                       CurrentTimeString(Ts);
    END;                          {of func TimeDateNow}

    (****************************************************************************)

    PROCEDURE NILClock;
    BEGIN
    END;

    {------------------}

    {draw a clock on screen.  Useful inside keyboard keyget routines}
    PROCEDURE DefaultClock;
    CONST
        LastTime       : LONGINT = 0;
        SLen           : BYTE = 0;
    BEGIN
        IF ABS(KTimer - LastTime) > 100 THEN BEGIN
            {$IFDEF DEBUG}
            SetBlink(FALSE);
            {$ENDIF}

            IF SLen = 0 THEN
                SLen := LENGTH(TimeDateNow);

            FastWrite(Pad(Long2Str(MEMAVAIL) + ':' + Long2Str(MAXAVAIL), 14),
                      ScreenHeight,
                      1,
                      ColorMono(YellowOnBlue, LtGrayOnWhite));

            FastWrite(TimeDateNow, ScreenHeight, ScreenWidth - SLen, ColorMono(YellowOnBlue, LtGrayOnWhite));
            LastTime := KTimer;
        END;
    END;

    {--------------------------------------------------------}

    {Opro color scheme for error messages}
    PROCEDURE SetErrorColors(VAR KColorSet : ColorSet);
    BEGIN
        WITH KColorSet DO BEGIN
            TextColor := YellowOnCyan;
            CtrlColor := LtGreenOnCyan;
            FrameColor := WhiteOnCyan;
            HeaderColor := BlackOnCyan;
            ShadowColor := DkGrayOnBlack;
            HighlightColor := WhiteOnRed;
            PromptColor := BlackOnLtGray;
            SelPromptColor := WhiteOnLtGray;
            ProPromptColor := BlackOnLtGray;
            FieldColor := YellowOnBlue;
            SelFieldColor := WhiteOnBlue;
            ProFieldColor := BlackOnLtGray;
            ScrollBarColor := LtGrayOnBlue;
            SliderColor := LtGrayOnBlue;
            HotSpotColor := LtGrayOnBlue;
            BlockColor := YellowOnBlue;
            MarkerColor := WhiteOnBlue;
            DelimColor := YellowOnLtGray;
            SelDelimColor := BlueOnBlue;
            ProDelimColor := YellowOnLtGray;
            SelItemColor := WhiteOnGreen;
            ProItemColor := LtGrayOnLtGray;
            HighItemColor := WhiteOnLtGray;
            AltItemColor := YellowOnCyan;
            AltSelItemColor := WhiteOnGreen;
            FlexAHelpColor := WhiteOnLtGray;
            FlexBHelpColor := WhiteOnLtGray;
            FlexCHelpColor := LtCyanOnLtGray;
            UnselXrefColor := YellowOnLtGray;
            SelXrefColor := WhiteOnLtBlue;
            MouseColor := WhiteOnRed;
        END;
    END;

    (*****************************)

    {selectable FlashDelay param}
    CONSTRUCTOR CylonObj.InitCFD(Header : STRING; CWidth, CFD : INTEGER);
    BEGIN
        VidSemPush;
        IF NOT Init(Header, CWidth) THEN
            FAIL;
        CylonFlashDelay := CFD;
        VidSemPop;
    END;

    (******************************************************************************)

    {force new cylon flash delay}
    PROCEDURE CylonObj.SetCFD(NewCFD : LONGINT);
    BEGIN
        CylonFlashDelay := NewCFD;
    END;

    (******************************************************************************)

    PROCEDURE CylonObj.Sleep;
    BEGIN
        VidSemPush;
        IF Parent <> NIL THEN
            Parent^.MarkCurrent;
        VidSemPop;

    END;

    (******************************************************************************)

    PROCEDURE CylonObj.MarkCurrent;
    BEGIN
        VidSemPush;
        Parent := wStack.TopWindow;
        INHERITED MarkCurrent;
        VidSemPop;
    END;

    (******************************************************************************)

    PROCEDURE CylonObj.MarkNotCurrent;
    BEGIN
        VidSemPush;
        INHERITED MarkNotCurrent;
        VidSemPop;
    END;

    (******************************************************************************)

    {- Initialize moving dot status window object}
    CONSTRUCTOR CylonObj.Init(Header : STRING; CWidth : INTEGER);
    VAR
        WinOpts        : LONGINT;
        X1,
        Y1,
        X2,
        Y2             : INTEGER;
        EsColors       : ColorSet;
    BEGIN
        Parent := NIL;

        TopHead := Header;
        BotHead := '';

        SetErrorColors(EsColors);
        CylonFlashDelay := 150;   {1.5 seconds}
        IsDrawn := FALSE;
        LastTime := KTimer;
        InitTime := LastTime;
        {make sure there is enough room for the header}
        IF CWidth < (LENGTH(Header) + 2) THEN
            CWidth := LENGTH(Header) + 2;

        NumDots := CWidth + 1;
        Count := 0;
        WinOpts := wBordered + wClear + wSaveContents;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - CWidth) DIV 2;
        X2 := X1 + CWidth;
        Y1 := ScreenHeight DIV 2;
        Y2 := Y1;                 {one line high box}

        VidSemPush;
        IF NOT InitCustom(X1, Y1, X2, Y2, EsColors, WinOpts) THEN BEGIN
            FAIL;
        END;

        wFrame.AddHeader(Header, heTC);
        {$IFDEF UseShadows}
        wFrame.AddShadow(shBR, shSeeThru);
        {$ENDIF}
        VidSemPop;

        EnableExplosions(8);
    END;

    (****************************************************************************)

    CONSTRUCTOR CylonObj.InitDeluxe(TopHeader, BotHeader : STRING);
        {- Initialize moving dot status window object}
    VAR
        WinOpts        : LONGINT;
        X1,
        Y1,
        X2,
        Y2             : INTEGER;
        EsColors       : ColorSet;
        CWidth         : BYTE;
    BEGIN
        SetErrorColors(EsColors);

        TopHead := TopHeader;
        BotHead := BotHeader;

        IsDrawn := FALSE;
        LastTime := KTimer;
        InitTime := LastTime;
        CWidth := LENGTH(BotHeader);
        IF CWidth < 10 THEN
            CWidth := 10;
        {make sure there is enough room for the header}
        IF CWidth < (LENGTH(TopHeader) + 2) THEN
            CWidth := LENGTH(TopHeader) + 2;

        NumDots := CWidth + 1;
        Count := 0;
        WinOpts := wBordered + wClear + wSaveContents;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - CWidth) DIV 2;
        X2 := X1 + CWidth;
        Y1 := ScreenHeight DIV 2;
        Y2 := Y1;                 {one line high box}

        VidSemPush;
        IF NOT InitCustom(X1, Y1, X2, Y2, EsColors, WinOpts) THEN BEGIN
            VidSemPop;
            FAIL;
        END;

        wFrame.AddHeader(TopHeader, heTC);
        IF LENGTH(BotHeader) > 0 THEN
            wFrame.AddHeader(BotHeader, heBC);
        {$IFDEF UseShadows}
        wFrame.AddShadow(shBR, shSeeThru);
        {$ENDIF}
        EnableExplosions(8);
        VidSemPop;
    END;

    (****************************************************************************)

    PROCEDURE CylonObj.ChangeTopHeader(Header : STRING);
    VAR
        Redraw         : BOOLEAN;
        X1,
        X2,
        Y1,
        Y2,
        CWidth         : BYTE;
    BEGIN
        {$IFDEF UseAdjustableWindows}
        IsDrawn := FALSE;
        TopHead := Header;

        CWidth := LENGTH(BotHead);
        IF CWidth < 10 THEN
            CWidth := 10;
        {make sure there is enough room for the header}
        IF CWidth < (LENGTH(TopHead) + 2) THEN
            CWidth := LENGTH(TopHead) + 2;

        NumDots := CWidth + 1;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - CWidth) DIV 2;
        X2 := X1 + CWidth;
        Y1 := ScreenHeight DIV 2;
        Y2 := Y1;                 {one line high box}

        VidSemPush;
        AdjustWindow(X1, Y1, X2, Y2);

        ERASE;
        IsDrawn := FALSE;
        LastTime := - 1;
        wFrame.ChangeHeaderString(0, Header, Redraw);
        (*
        IF Redraw THEN
            wFrame.UpDateFrame
        ELSE
            wFrame.DrawHeader(0);
        *)
        UpDate;
        VidSemPop;
        {$ELSE}
        RingBell;
        {$ENDIF}
    END;

    (****************************************************************************)

    PROCEDURE CylonObj.ChangeBotHeader(Header : STRING);
    VAR
        Redraw         : BOOLEAN;
        X1,
        X2,
        Y1,
        Y2,
        CWidth         : BYTE;
    BEGIN
        {$IFDEF UseAdjustableWindows}
        IsDrawn := FALSE;
        VidSemPush;
        IF wFrame.GetLastHeaderIndex = 0 THEN BEGIN
            wFrame.AddHeader(' ', heBC);
            {EXIT;}
        END;
        VidSemPop;
        BotHead := Header;
        CWidth := LENGTH(TopHead);
        IF CWidth < 10 THEN
            CWidth := 10;
        {make sure there is enough room for the header}
        IF CWidth < (LENGTH(BotHead) + 2) THEN
            CWidth := LENGTH(BotHead) + 2;

        NumDots := CWidth + 1;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - CWidth) DIV 2;
        X2 := X1 + CWidth;
        Y1 := ScreenHeight DIV 2;
        Y2 := Y1;                 {one line high box}

        VidSemPush;
        AdjustWindow(X1, Y1, X2, Y2);

        wFrame.ChangeHeaderString(1, Header, Redraw);
        IF Redraw THEN
            wFrame.UpDateFrame
        ELSE
            wFrame.DrawHeader(1);
        VidSemPop;
        {$ELSE}
        RingBell;
        {$ENDIF}
    END;

    (****************************************************************************)

    FUNCTION CylonObj.GetTopHeader : STRING;
    BEGIN
        GetTopHeader := TopHead;
    END;

    (****************************************************************************)

    FUNCTION CylonObj.GetBotHeader : STRING;
    BEGIN
        GetBotHeader := BotHead;
    END;

    (****************************************************************************)

    {- Draw a moving dot status window}
    PROCEDURE CylonObj.Draw;
    BEGIN
        VidSemPush;
        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        IF (CylonFlashDelay = 0) OR
        (ABS(KTimer - InitTime) > CylonFlashDelay) THEN BEGIN
            INHERITED Draw;
            IsDrawn := TRUE;
            SetCursor(cuHidden);
        END;
        VidSemPop;
    END;

    (****************************************************************************)

    {- move the dot in the moving dot status window.  Also check for user keypress}
    {  of ESC key.  Return FALSE if ESC pressed}
    FUNCTION CylonObj.UpDate : BOOLEAN;
    VAR
        K              : CHAR;
        Strg           : STRING;
    BEGIN
        UpDate := TRUE;

        IF NOT IsDrawn THEN
            Draw;

        IF IsDrawn AND (ABS(KTimer - LastTime) > 50) THEN BEGIN
            LastTime := KTimer;
            INC(Count);           {cylon}
            Count := (Count MOD (NumDots + 1));
            FILLCHAR(Strg[1], NumDots, #7);
            Strg[Count] := #42;
            Strg[Count + 1] := #15;
            Strg[Count + 2] := #42;
            Strg[0] := CHAR(NumDots);
            VidSemPush;
            CurrentClockProc;

            wFastText(Strg, 1, 1);
            VidSemPop;
            IF KeyPressed THEN BEGIN
                K := ReadKey;
                IF K = #27 THEN
                    UpDate := FALSE;
            END;
        END;
    END;

    (****************************************************************************)

    DESTRUCTOR CylonObj.Done;
        {- Kill the moving dot status window}
    BEGIN
        VidSemPush;
        IF IsDrawn THEN
            ERASE;
        INHERITED Done;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
        VidSemPop;
    END;

    (****************************************************************************)

    {- log a two line error message to the PROGNAME.ERR file, along with the }
    {   MAP file address of the error line                                   }
    {
       Sample call:
        .
        .
        .
        LastError := IORESULT;
        IF LastError <> 0 THEN BEGIN
            AutopsyDeluxe('Failure copying file: '+Filename, ErrorMessage(LastError), TRUE, Iam);
            Halt(1);
        END;

        This will display a message on the screen like:
                "Failure copying file: C:\AUTOEXEC.BAT"
                "File not found"

        And log the messages and location in the source code of the AutopsyDeluxe line in <thisexename>.ERR

        ErrorMessage() can parse most known error message codes returned by BP7, Opro and Filer
        Iam() returns source code location as Seg:Offset map file location
    }
    {$I-}
    PROCEDURE AutopsyDeluxe(Strg1, Strg2 : STRING; P : POINTER);
    VAR
        TFile          : TEXT;
        OFM,
        I,
        LastError      : WORD;
        ExeDir         : STRING;
        f              : FILE;
        Ftime          : LONGINT;
        T              : OpDate.Time;
        D              : OpDate.Date;
        {$IFDEF VirtualPascal}
        FileName       : STRING;
        LineNo         : LONGINT;
        {$ENDIF}
        Strg           : STRING;
        PROCEDURE KWRITELN(VAR T : TEXT; Tag, Strg : STRING);
        BEGIN
            IF LENGTH(Strg) = 0 THEN
                EXIT;
            WRITELN(T, Tag + ': ' + Strg);
        END;
    BEGIN

        IF ASSIGNED(ErrorLogSem) THEN
            ErrorLogSem.Request;
        {the log and exe dirs are separate because the original code}
        {supported Novell mapped drives and alternate error log dirs}

        IF LogName = '' THEN
            LogName := ForceExtension(FExpand(PARAMSTR(0)), 'ERR');

        ExeDir := JustPathName(FExpand(PARAMSTR(0)));
        {open log file}
        ASSIGN(TFile, LogName);

        RESET(TFile);
        LastError := IORESULT;

        CASE LastError OF
            0 : BEGIN
                    CLOSE(TFile); {found existing file, so append}
                    APPEND(TFile);
                END;
            110,
            2 : BEGIN
                    REWRITE(TFile); {create new file}
                    LastError := IORESULT;

                    IF LastError <> 0 THEN BEGIN
                        CLOSE(TFile);
                        IF ASSIGNED(ErrorLogSem) THEN
                            ErrorLogSem.Release;
                        EXIT;
                    END;
                END;
            ELSE BEGIN
                {crash if file error} {boom!}
                IF ASSIGNED(ErrorLogSem) THEN
                    ErrorLogSem.Release;
                EXIT;
            END;
        END;

        WRITELN(TFile, CharStr('*', 10));
        WRITELN(TFile);
        KWRITELN(TFile, 'L1', Strg1);
        KWRITELN(TFile, 'L2', Strg2);
        KWRITELN(TFile, 'Error Date', TimeDateNow);
        {$IFDEF VirtualPascal}
        KWRITELN(TFile, 'MEMUSED', Long2Str(MemUsed));
        IF P = NIL THEN
            P := ERRORADDR;
        {$ELSE}
        KWRITELN(TFile, 'MEM', Long2Str(MEMAVAIL) + ' : ' + Long2Str(MAXAVAIL));
        {$ENDIF}
        IF P <> NIL THEN BEGIN
            {$IFDEF VirtualPascal}
            if GetLocationInfo( P, FileName, LineNo ) <> NIL then
                Strg := FileName +'#'+ Long2Str(LineNo)+' $'+HexPtr(P)
            else begin
                Strg := '$'+HexPtr(P);
                {$IFDEF DEBUGGETLOCATION}
                beep(ATNBEEP);
                {$ENDIF}
            end;
            Strg := Strg +' TID=' + Long2Str(GetThreadID);
            {$ELSE}
            Strg := HexPtr(P);
            {$ENDIF}
            KWRITELN(TFile, 'ERRORADDR', Strg);
        END;
        Strg := '';

        FOR I := 1 TO PARAMCOUNT DO
            Strg := Strg + PARAMSTR(I) + ' ';

        KWRITELN(TFile, 'Cmdline', Strg);

        OFM := FILEMODE;
        FILEMODE := 0;
        ASSIGN(f, AddBackSlash(ExeDir) + JustFileName(PARAMSTR(0)));
        RESET(f);                 { open current exe file for read}
        FILEMODE := OFM;
        LastError := IORESULT;
        IF LastError = 0 THEN BEGIN
            {$IFNDEF DPMI}
            GetFTime(f, Ftime);   { Get creation time }
            CLOSE(f);             { Close file }
            UnpackDOStime(Ftime, T, D);

            WRITELN(TFile, AddBackSlash(ExeDir) + JustFileName(PARAMSTR(0)));
            WRITELN(TFile, 'Exe date: ' +
                    DateToDateString('dd nnn yyyy', D) + ' ' +
                    TimeToTimeString('hh:mm:ss', T));
            {$ELSE}
            WRITELN(TFile, PARAMSTR(0));
            WRITELN(TFile, 'Exe date: Unknown - DPMI app; VCS= '+Programdate);
            {$ENDIF}
            {$IFDEF VirtualPascal}
            KWRITELN(TFile, 'Platform', 'VP2');
            {$ENDIF}
        END
        ELSE BEGIN
            {$IFNDEF DPMI}
            {look on the paramstr path, exe wasn't in sysdir}
            ASSIGN(f, PARAMSTR(0));
            RESET(f);             { open current exe file for read}
            LastError := IORESULT;
            IF LastError = 0 THEN BEGIN
                GetFTime(f, Ftime); { Get creation time }
                CLOSE(f);         { Close file }
                UnpackDOStime(Ftime, T, D);

                WRITELN(TFile, PARAMSTR(0));
                WRITELN(TFile, 'Exe date: ' +
                        DateToDateString('dd nnn yyyy', D) + ' ' +
                        TimeToTimeString('hh:mm:ss', T));
            END
            ELSE BEGIN            {can't find the damned thing anywhere - give up}
                WRITELN(TFile, PARAMSTR(0));
                WRITELN(TFile, 'Exe date: Unknown');
            END;
            {$ELSE}
            WRITELN(TFile, PARAMSTR(0));
            WRITELN(TFile, 'Exe date: Unknown - DPMI app; VCS= '+Programdate);
            {$ENDIF}
        END;

        KWRITELN(TFile, 'PrgRev', ProgramRevision); {revision level of program}
        KWRITELN(TFile, 'PrgRel', ProgramRelease); {release  level of program}
        {~nokeywords~}
        WRITELN(TFile);

        CLOSE(TFile);
        IF ASSIGNED(ErrorLogSem) THEN
            ErrorLogSem.Release;
  END;
    {$I+}

    (****************************************************************************)
    {Returns number of centiseconds (hundredths) since midnight }
    FUNCTION KTimer : LONGINT;
    CONST
        HPH            : LONGINT = 360000;
        HPM            : LONGINT = 6000;
        HPS            : LONGINT = 100;
    VAR
        H,
        M,
        S,
        S100           : WORD;
        T              : LONGINT;
    BEGIN
        {$IFNDEF VirtualPascal}
        KTimer := TimeMS DIV 10;
        GetTime(H, M, S, S100);
        T := (H * HPH) + (M * HPM) + (S * HPS) + S100;
        KTimer := T;
        {$ELSE}
        KTimer := TimeMs DIV 10;
        {$ENDIF}
    END;

    (******************************************************************************)

    {- display a two line, dynamically sized error dialog and log the error}
    {  and MAP file address of the error line                              }
    {  See autopsydeluxe for logging information                           }
    PROCEDURE DispErrorDeluxe(Strg1,
                              Strg2          : STRING;
                              LogIt          : BOOLEAN;
                              P              : POINTER);
    VAR
        MsgWin         : RawWindowPtr;
        Temp           : BOOLEAN;
        X,
        WinWidth,
        WinHeight      : INTEGER;
        WinOpts,
        TTime          : LONGINT;
        EsColors       : ColorSet;
        CX,
        cy             : BYTE;
    BEGIN

        SetErrorColors(EsColors);
        CX := WhereXAbs;
        cy := WhereYAbs;
        WINDOW(1, 1, ScreenWidth, ScreenHeight);

        IF LogIt THEN
            AutopsyDeluxe(Strg1, Strg2, P);

        WinOpts := wBordered + wClear + wSaveContents;

        WinWidth := MaxWord(LENGTH(Strg1), LENGTH(Strg2));

        IF WinWidth > (ScreenWidth - 4) THEN BEGIN
            Strg1 := TruncStr(Strg1, ScreenWidth - 4);
            Strg2 := TruncStr(Strg2, ScreenWidth - 4);
            WinWidth := ScreenWidth - 4;
        END;

        WinWidth := MaxWord(WinWidth, 18);

        X := (ScreenWidth - WinWidth) DIV 2;

        IF LENGTH(Strg2) > 0 THEN
            WinHeight := 2
        ELSE
            WinHeight := 1;

        SetBlink(FALSE);

        {check current video mode flag for graphics
        IF VideoMode <> ALPHA THEN
            TextMode(LASTMODE);}

        VidSemPush;
        NEW(MsgWin, InitCustom(X,
                               10,

                               X + WinWidth,
                               10 + WinHeight,

                               EsColors,
                               WinOpts));

        IF MsgWin = NIL THEN
            EXIT;

        WITH MsgWin^ DO BEGIN
            SetCursor(cuHidden);
            wFrame.AddHeader('ERROR', heTC);
            {$IFDEF TDG}
            wFrame.AddHeader(' Press any key ', heBC);
            {$ENDIF}
            {$IFDEF UseShadows}
            wFrame.AddShadow(shBR, shSeeThru);
            {$ENDIF}
            EnableExplosions(8);
            Draw;
            wFastText(Strg1, 1, 1);
            IF WinHeight = 2 THEN
                wFastText(Strg2, 2, 1);
        END;
        VidSemPop;

        {Beep(TESTFAIL);}
        {$IFDEF VirtualPascal}
        SysUtils.Beep;
        {$ENDIF}
        {$IFDEF TDG}
        readkey;
        {$ELSE}
        TTime := KTimer;
        {4 second delay - you could add a background task here}
        {like updating the screen clock or whatever}
        WHILE KTimer - TTime < DispErrorDelayMS DO ;
        {$ENDIF}
        VidSemPush;
        MsgWin^.ERASE;
        DISPOSE(MsgWin, Done);
        GotoXYabs(CX, cy);
        VidSemPop;
    END;

    (******************************************************************************)

    {- display a two line, dynamically sized error dialog and log the error}
    PROCEDURE DispError(Strg1, Strg2 : STRING; LogIt : BOOLEAN);
    BEGIN
        DispErrorDeluxe(Strg1, Strg2, LogIt, NIL);
    END;

    (******************************************************************************)

    PROCEDURE KAbstract(P : POINTER);
    BEGIN
        DispErrorDeluxe('Error', 'Abstract function called', TRUE, P);
    END;

    {----------}
    {$IFDEF SuppressErrorMessages}
    FUNCTION ErrorMessage(Status : LONGINT) : STRING;
    BEGIN
        ErrorMessage := '';
    END;
    {$ELSE}
    {- returns string containing meaning of Opro and TP error codes}
    FUNCTION ErrorMessage(Status : LONGINT) : STRING;
        {-Return Turbo runtime error messages}
    VAR
        S              : STRING;
    BEGIN
        S := '';
        CASE Status DIV 10000 OF
            0 : S := 'etFatal + ';
            1 : S := 'etNonFatal + ';
            2 : S := 'etWarning + ';
            3 : S := 'etMessage + ';
            {$IFDEF AllowDongleErrorMessages}
            6 : S := 'Sentinel Error: ';
            {$ENDIF}
            {$IFDEF AllowIsamErrorMessages}
            7,
            8 :
                BEGIN
                    ErrorMessage := 'Isam Error + ' +
                                    IsamErrorMessage(WORD(Status - 70000));
                    EXIT;
                END;
            {$ENDIF}
        END;
        CASE Status MOD 10000 OF
            000 : S := '';
            002 : S := S + 'File not found';
            003 : S := S + 'Path not found';
            004 : S := S + 'Too many open files';
            005 : S := S + 'File access denied';
            006 : S := S + 'Invalid file handle';
            008 : S := S + 'Insufficient Memory';
            012 : S := S + 'Invalid file access code';
            015 : S := S + 'Invalid drive number';
            016 : S := S + 'Cannot remove current directory';
            017 : S := S + 'Cannot rename across drives';
            018 : S := S + 'No more files';
            {$IFDEF VirtualPascal}
            019 : S := S + 'The drive is currently write-protected';
            020 : S := S + 'The system cannot find the device specified';
            021 : S := S + 'The drive is not ready';
            022 : S := S + 'The device does not recognize the command';
            023 : S := S + 'Data error (cyclic redundancy check)';
            024 : S := S + 'The command length is incorrect';
            025 : S := S + 'The drive cannot locate a specific area or track on the disk';
            026 : S := S + 'The specified disk or diskette cannot be accessed';
            027 : S := S + 'The drive cannot find the sector (area) requested';
            028 : S := S + 'Printer out of paper or not enough space to create spool file';
            029 : S := S + 'The system cannot write to the specified device';
            030 : S := S + 'The system cannot write to the specified device';
            031 : S := S + 'A device attached to the system is not functioning';
            032 : S := S + 'The file is already being used by another process';
            033 : S := S + 'A portion of the file is locked by another process';
            052 : S := S + 'A duplicate name exists on the network';
            053 : S := S + 'The network path was not found';
            087 : S := S + 'Invalid DLL Parameter';
            {$ENDIF}
            100 : S := S + 'Disk read error';
            101 : S := S + 'Disk write error';
            102 : S := S + 'File not assigned';
            103 : S := S + 'File not open';
            104 : S := S + 'File not open for input';
            105 : S := S + 'File not open for output';
            150 : S := S + 'Disk is write-protected';
            151 : S := S + 'Unknown unit';
            152 : S := S + 'Drive not ready';
            153 : S := S + 'Unknown command';
            154 : S := S + 'CRC error in data';
            156 : S := S + 'Disk seek error';
            157 : S := S + 'Unknown media type';
            158 : S := S + 'Sector not found';
            159 : S := S + 'Printer is out of paper';
            160 : S := S + 'Device write fault';
            161 : S := S + 'Device read fault';
            162 : S := S + 'Hardware failure';
            200 : S := S + 'Division by zero';
            201 : S := S + 'Range check error';
            202 : S := S + 'Stack overflow error';
            203 : S := S + 'Heap overflow error';
            204 : S := S + 'Invalid pointer operation';
            205 : S := S + 'Floating point overflow';
            206 : S := S + 'Floating point underflow';
            207 : S := S + 'Invalid floating point operation';
            208 : S := S + 'Overlay manager not installed';
            209 : S := S + 'Overlay file read error';
            210 : S := S + 'Object not initialized';
            211 : S := S + 'Call to abstract method';
            212 : S := S + 'Stream registration error';
            213 : S := S + 'Collection index out of range';
            214 : S := S + 'Collection overflow error';
            215 : S := S + 'Arithmetic overflow error';
            216 : S := S + 'General Protection fault';
            217 : S := S + 'Unhandled Exception';
            219 : S := S + 'Invalid Typecast';
            250..998 :
                S := S + CurrentUserErrorMessageProc(Status MOD 10000);

            {$IFDEF AllowOPROErrorMessages}
            ecUserAbort : S := 'User Abort';
            01000 : S := S + 'File is empty';
            01101 : S := S + 'Unknown object id read from stream';
            01102 : S := S + 'Load constructor failed within Get or GetPtr';
            01103 : S := S + 'Attempt to read/write bad data';
            01200 : S := S + 'Can''t add entry if name is blank';
            01201 : S := S + 'Error packing OpLibrary';
            01202 : S := S + 'Bad signature in directory';
            02000 : S := S + 'Queue is full. new element rejected';
            02001 : S := S + 'Queue is empty. no element returned';
            02002 : S := S + 'String array from text file exceeds 64K';
            02020 : S := S + 'Directory full--can''t add entry';
            02050 : S := S + 'Cannot add command due to partial match';
            02051 : S := S + 'Cannot add command due to full key table';
            02100 : S := S + 'Insufficient EMS memory to allocate';
            02101 : S := S + 'Error allocating EMS page';
            02102 : S := S + 'EMS operation failed because no EMS available';
            02103 : S := S + 'Error mapping EMS page';
            02104 : S := S + 'Cannot deallocate EMS handle';
            02110 : S := S + 'Error moving memory to/from XMS';
            02111 : S := S + 'Insufficient XMS memory to allocate';
            02112 : S := S + 'Unable to free XMS handle';
            02113 : S := S + 'No XMS memory present';
            02114 : S := S + 'Element size is not even';
            02200 : S := S + 'Too many files to fit into directory buffer';
            {$ENDIF}

            {$IFDEF AllowAproErrorMessages}
            {APUART port errors}
            02900 : S := S + 'Can''t open port, no slots available';
            02901 : S := S + 'UART receiver overrun';
            02902 : S := S + 'UART receiver parity error';
            02903 : S := S + 'UART receiver framing error';
            {APINT14 port errors}
            02910 : S := S + 'Int14 transmit failed';
            02911 : S := S + 'Int14 receive failed';
            {APCOM/OOCOM errors/status}
            02920 : S := S + 'Block shorter than requested';
            02921 : S := S + 'No room for new char in buffer';
            02922 : S := S + 'No characters to get';
            02923 : S := S + 'Timed out waiting for something';
            02924 : S := S + 'String shorter than requested';
            02925 : S := S + 'String longer than 255';
            02926 : S := S + 'User aborted during "wait"';
            {APMODEM/OOMODEM errors}
            02930 : S := S + 'No room in table to add new entry';
            02931 : S := S + 'Modem - no command registered';
            {Tracing/EventFile file errors}
            02940 : S := S + 'Failed to open or write to the event file';
            02941 : S := S + 'Failed to open or write to the trace file';
            {Other device layer errors}
            02950 : S := S + 'No fossil installed';
            02960 : S := S + 'Generic Digiboard failure code';
            {$ENDIF}

            {$IFDEF AllowDongleErrorMessages}
            04539 : S := S + 'Invalid password or permission level';
            04541 : S := S + 'Invalid parameter string';
            04542 : S := S + 'Missing Dongle';
            04543 : S := S + 'Invalid request char';
            04636 : S := S + 'Invalid bios address';
            04637,
            04639 : S := S + 'driver corrupted';
            04640 : S := S + 'busy or missing';
            04641 : S := S + 'OS/2 parallel port access failure';
            04642 : S := S + 'Windows task ID not found in handle table';
            {$ENDIF}

            {$IFDEF AllowFilerErrorMessages}
            {Filer errors}
            06000 : S := S + 'init error--window/max rows too small';
            06001 : S := S + 'init error--Fileblock is not indexed';
            06002 : S := S + 'Fatal error accessing data or index file';
            06003 : S := S + 'No records found in requested range';
            06004 : S := S + 'Selected record no longer exists';
            06005 : S := S + 'Lock error while reading selected record';
            06006 : S := S + 'File is locked';
            {$ENDIF}

            07000 : S := S + 'Field is required';
            07001 : S := S + 'Bad format (number/date/time, etc.';
            07002 : S := S + 'Value entered is out of range';
            07003 : S := S + 'Field contains blanks';
            07004 : S := S + 'Field contains a partial entry';
            07005 : S := S + 'Field contains an illegal character';
            07100 : S := S + 'Search string not found';
            07101 : S := S + 'Cannot write output to screen';
            07102 : S := S + 'Invalid number entered';
            07110 : S := S + 'Edit buffer is full';
            07111 : S := S + 'Line too long, CRLF inserted';
            07112 : S := S + 'Max line limit would be exceeded';
            07113 : S := S + 'Max line limit already exceeded';
            07114 : S := S + 'File truncated';
            07115 : S := S + 'File too large to fit in buffer';
            07116 : S := S + 'Block not marked or hidden';
            07117 : S := S + 'Marker not set';
            07200 : S := S + 'Divide overflow';
            07201 : S := S + 'Error returned by 80x87 coprocessor';
            07300 : S := S + 'No pick selection made';
            07400 : S := S + 'Name already in use';
            07401 : S := S + 'OpLibrary entry not found';
            08000 : S := S + 'String is already in string set';
            08010 : S := S + 'User object not registered with stream';
            08011 : S := S + 'Attempt to register duplicate object id';
            08012 : S := S + 'User pointer not registered with stream';
            08050 : S := S + 'Element size is zero';
            08051 : S := S + 'Incorrect dimensions for disk file';
            08052 : S := S + 'Specified row is out of range';
            08053 : S := S + 'Specified column is out of range';
            08054 : S := S + 'Specified file is not a OpLarray file';
            08055 : S := S + 'Element size is too big';
            08056 : S := S + 'An invalid dimension was specified';
            08057 : S := S + 'Less than one page in RAM';
            08058 : S := S + 'Error flushing large array file';
            08100 : S := S + 'Bad coordinates specified for a window';
            08101 : S := S + 'Window must be active for this operation';
            08102 : S := S + 'Window must be current for this operation';
            08103 : S := S + 'Window must be inactive for this operation';
            08104 : S := S + 'Stacked window not accessible';
            08105 : S := S + 'Zoomed window cannot be zoomed again';
            08106 : S := S + 'Invalid header or hot spot index';
            08107 : S := S + 'Window must be sizeable for this operation';
            08108 : S := S + 'No command processor is available';
            08109 : S := S + 'Operation is not valid on a child window';
            08200 : S := S + 'Attempt to pick from empty list';
            08201 : S := S + 'Invalid pick orientation';
            08202 : S := S + 'Invalid pick command handler';
            08220 : S := S + 'Invalid help file format';
            08221 : S := S + 'No help for specified topic';
            08222 : S := S + 'Pointer for bound-in help not registered';
            08300 : S := S + 'Too many fields in a selector/entry screen';
            08301 : S := S + 'Bad coordinates for a field';
            08302 : S := S + 'Virtual screen not allocated';
            08303 : S := S + 'Selector/entry screen has no fields';
            08305 : S := S + 'Attempt to position cursor on non-existent field';
            08306 : S := S + 'Can''t add window field to ScrollingEntryScreen';
            08307 : S := S + 'Child window already has parent or is active';
            08400 : S := S + 'Specified Printer type is invalid';
            08401 : S := S + 'Printer position out of range';
            08402 : S := S + 'No printer position routine specified';
            08403 : S := S + 'Stack overflow in font stack';
            08404 : S := S + 'Stack underflow in font stack';
            08405 : S := S + 'Stack overflow in a byte stack';
            08406 : S := S + 'No BasePrinterPtr specified for Printer';
            08420 : S := S + 'Page to be printed has no active fields';
            08421 : S := S + 'Attempt to add field when no block defined';
            08422 : S := S + 'FieldID represents non-existent field';
            08423 : S := S + 'Diagonal lines not allowed';
            08500 : S := S + 'Nil pointer where there shouldn''t be one';
            08501 : S := S + 'Bad parameter to a procedure';

            {$IFDEF AllowGifErrorMessages}
            8600 : S := 'File is not a gif file';
            8601 : S := 'No Global Color table found';
            8602 : S := 'Image descriptor preceeded by other unknown data';
            8603 : S := 'Block has no data';
            8604 : S := 'Unexpected EOF';
            8605 : S := 'Bad code size';
            8606 : S := 'Bad code was found';
            8607 : S := 'Bit size went beyond 12 bits';
            8608 : S := 'Error in extension block';
            {$ENDIF}

            {$IFDEF AllowAproErrorMessages}
            {APCOM/OOCOM port errors}
            08900 : S := S + 'Out-of-range port number';
            08901 : S := S + 'General out-of-range error';
            08902 : S := S + 'Port not open';
            08903 : S := S + 'Bad baud rate for this device';
            08904 : S := S + 'General programming error';
            08905 : S := S + 'No device layer installed';
            08906 : S := S + 'Couldn''t find a uart at this address';
            08907 : S := S + 'Bad parity option for this device';
            08910 : S := S + 'Operation only allowed on buffered ports';
            08911 : S := S + 'Function not supported by device-layer';
            {APFAX error codes}
            09800 : S := S + 'Call is VOICE';
            09801 : S := S + 'Call is DATA';
            09802 : S := S + 'called modem is busy';
            09803 : S := S + 'could not find font file';
            09804 : S := S + 'CASMGR TSR not installed';
            09805 : S := S + 'unexpected response in init';
            09806 : S := S + 'Failed to train with remote modem';
            09807 : S := S + 'Error during session';
            09808 : S := S + 'No connection after dial';
            09809 : S := S + 'Failed to send page after retries';
            {APABSPCL/OOABSPCL status codes}
            09900 : S := S + 'Xmodem init failed';
            09901 : S := S + 'Xmodem init was canceled on request';
            09902 : S := S + 'Cancel requested';
            09903 : S := S + 'Duplicate block received';
            09904 : S := S + 'Wrong block number received';
            09905 : S := S + 'Directory not found in protocol transmit';
            09906 : S := S + 'No matching files in protocol transmit';
            09907 : S := S + 'Long packet received during protocol';
            09908 : S := S + 'End of transmitted file';
            09909 : S := S + 'Initial protocol handshake in progress';
            09910 : S := S + 'Incoming file was renamed';
            09911 : S := S + 'Incoming file already exists';
            09912 : S := S + 'Ymodem header has bad file size';
            09913 : S := S + 'Ymodem header has bad date/time';
            09914 : S := S + 'Unexpected char during protocol';
            09915 : S := S + 'Incorrect CRC or checksum received';
            09916 : S := S + 'No search mask specified for transmit';
            09917 : S := S + 'No filename specifed in xmodem download';
            09918 : S := S + 'Ascii receive in progress';
            09919 : S := S + 'Receiver rejected file';
            09920 : S := S + 'Too many errors received during protocol';
            09921 : S := S + 'No end of list marker found in file list';
            {APZMODEM/OOZMODEM status codes}
            09925 : S := S + 'Zmodem - got CrcE DataSubpacket';
            09926 : S := S + 'Zmodem - got CrcW DataSubpacket';
            09927 : S := S + 'Zmodem - got CrcQ DataSubpacket';
            09928 : S := S + 'Zmodem - got CrcG DataSubpacket';
            09929 : S := S + 'Zmodem - got garbage from remote';
            09930 : S := S + 'Zmodem - skip file';
            09931 : S := S + 'Zmodem - bad file position';
            09932 : S := S + 'Zmodem - specified file doesn''t exist';
            09933 : S := S + 'Zmodem - not allowed to overwrite file';
            09934 : S := S + 'Zmodem - never got proper handshake';
            09935 : S := S + 'Zmodem - no files to receive';
            09936 : S := S + 'ZModem - port buffers too small';
            09937 : S := S + 'Zmodem - got a complete header';
            09938 : S := S + 'Zmodem - (internal) no header yet';
            {APMODEM/OOMODEM status codes}
            09940 : S := S + 'Unexpected char in modem result string';
            09941 : S := S + 'Modem response - CONNECT';
            09942 : S := S + 'Modem response - RING';
            09943 : S := S + 'Modem response - NO CARRIER';
            09944 : S := S + 'Modem response - NO DIALTONE';
            09945 : S := S + 'Modem response - BUSY';
            09947 : S := S + 'Modem response - NO ANSWER';
            09948 : S := S + 'Modem response - RINGING';
            09949 : S := S + 'Modem response - VOICE';
            09950 : S := S + 'Modem response - ERROR';
            {APKERMIT/OOKERMIT status codes}
            09954 : S := S + 'Kermit - got packet';
            09955 : S := S + 'Kermit - no data yet';
            {Archive status messages}
            09960 : S := S + 'Unknown compression method';
            09961 : S := S + 'Cannot extract--file is encrypted';
            09962 : S := S + 'Bad CRC--file is probably corrupted';
            09963 : S := S + 'Unable to create output file';
            09964 : S := S + 'Bad archive file format';
            09965 : S := S + 'Not an LZH file';
            09966 : S := S + 'Not a ZIP file';
            09967 : S := S + 'File mask list is empty';
            {FAX conversion error/warnings}
            09970 : S := S + 'Not a valid APRO fax file';
            09971 : S := S + 'Bad font format or unsupported feature';
            09972 : S := S + 'Converting font';
            09973 : S := S + 'Bad tiff/pcx format or unsupported feature';
            09974 : S := S + 'Bad escape sequence in PCL file';
            {CaptureTerminalWindow error codes}
            09980 : S := S + 'Scroll back buffer > 64k';
            {APBPLUS/OOBPLUS status codes}
            09985 : S := S + 'Resyncing with host';
            09986 : S := S + 'Waiting for ACK';
            09987 : S := S + 'Dropout';
            09988 : S := S + 'Host cancel';
            09989 : S := S + 'Attempting resume';
            09990 : S := S + 'Host resuming';
            09991 : S := S + 'Resumed OK';
            09992 : S := S + 'Failed to resume';
            09993 : S := S + 'Invalid packet type';
            {$ENDIF}
            ELSE
                S := 'Turbo runtime error ' + Long2Str(Status);
        END;
        ErrorMessage := S;
    END;
    {$ENDIF}

    (*************************************************************************)


    {- log a two line error message to the PROGNAME.ERR file }

    PROCEDURE Autopsy(Strg1, Strg2 : STRING);
    BEGIN
        AutopsyDeluxe(Strg1, Strg2, NIL);
    END;

    (****************************************************************************)

    PROCEDURE CheckNilInit;
    BEGIN
        IF InitStatus = 0 THEN
            InitStatus := 8
    END;

    (****************************************************************************)

    {- make all sorts of wierd noises}
    PROCEDURE Beep(Tone : BeepType);
    CONST
        CQ             = '-.-. --.-  -.. .  -. -.... . -.- ..';
        MorseDelay     = 40;
    VAR
        J,
        I              : INTEGER;
        Dummy          : BOOLEAN;
        Strg           : STRING;
    BEGIN
        {$IFNDEF PENTIUMII}
        DelayCalibrate;
        {$ENDIF}
        {$IFNDEF VirtualPascal}
        NOSOUND;
        {$ENDIF}

        CASE Tone OF
            TRIPLE :
                BEGIN
                    {high beep beep beep}
                    FOR I := 1 TO 3 DO BEGIN
                        {$IFNDEF VirtualPascal}
                        Sound(4000);
                        Delay(40);
                        NOSOUND;
                        {$ELSE}
                        PlaySound(4000,40);
                        {$ENDIF}
                        Delay(40);
                    END;
                END;
            OldBeep :
                BEGIN
                    {low beep }
                    {$IFNDEF VirtualPascal}
                    Sound(880);
                    Delay(100);
                    NOSOUND;
                    {$ELSE}
                    PlaySound(880,100);
                    {$ENDIF}
                END;
            ATNBEEP :
                BEGIN
                    {ta da}
                    {$IFNDEF VirtualPascal}
                    Sound(2000);
                    Delay(100);
                    NOSOUND;
                    Delay(100);
                    Sound(2000);
                    Delay(300);
                    NOSOUND;
                    {$ELSE}
                    PlaySound(2000, 100);
                    delay(100);
                    PlaySound(2000, 200);
                    {$ENDIF}
                END;
            BADKEY :
                BEGIN
                    {med beep}
                    {$IFNDEF VirtualPascal}
                    Sound(2000);
                    Delay(100);
                    NOSOUND;
                    {$ELSE}
                    PlaySound(2000, 100);
                    {$ENDIF}
                END;
            OprError :
                BEGIN
                    {med beep beep}
                    FOR I := 1 TO 2 DO BEGIN
                        {$IFNDEF VirtualPascal}
                        Sound(2500);
                        Delay(100);
                        NOSOUND;
                        Delay(100);
                        {$ELSE}
                        PlaySound(2500, 100);
                        Delay(100);
                        {$ENDIF}
                    END;
                END;
            TESTFAIL :
                BEGIN
                    {crash 'n burn}
                    {$IFNDEF VirtualPascal}
                    FOR I := 500 DOWNTO 1 DO BEGIN {powerdive to runway}
                        Sound(2000 + I);
                        Delay(2);
                        {$ELSE}
                    FOR I := 500 DOWNTO 1 DO BEGIN
                        if (i mod 8) = 0 then
                            PlaySound(2000 + I, 1);
                    {$ENDIF}
                    END;
                    FOR I := 1 TO 85 DO BEGIN {explosion}
                        {$IFNDEF VirtualPascal}
                        Sound(RANDOM(1000));
                        Delay(5);
                        {$ELSE}
                        PlaySound(RANDOM(1000), 1);
                        {$ENDIF}
                    END;
                    {$IFNDEF VirtualPascal}
                    NOSOUND;
                    {$ENDIF}
                END;
            TESTPASS :
                BEGIN
                    {weep weep weep}
                    FOR J := 1 TO 3 DO BEGIN
                        FOR I := 1 TO 200 DO BEGIN
                            {$IFNDEF VirtualPascal}
                            Sound(2000 + I);
                            Delay(1);
                            {$ELSE}
                            PlaySound(2000 + I, 1);
                            {$ENDIF}
                        END;
                    END;
                    {$IFNDEF VirtualPascal}
                    NOSOUND;
                    {$ENDIF}
                END;
            RANDBEEP :
                BEGIN
                    {B-Movie computer noises}
                    {DANGER Wil Robinson!... Flail Arms}
                    FOR I := 1 TO 20 DO BEGIN
                        {$IFNDEF VirtualPascal}
                        Sound(RANDOM(4000));
                        Delay(RANDOM(200));
                        {$ELSE}
                        PlaySound(RANDOM(4000), RANDOM(200));
                        {$ENDIF}
                    END;
                    {$IFNDEF VirtualPascal}
                    NOSOUND;
                    {$ENDIF}
                END;
            WEEP3 :
                BEGIN
                    {weep woop weep woop weep woop}
                    FOR I := 1 TO 3 DO BEGIN
                        FOR J := 1 TO 200 DO BEGIN
                            {$IFNDEF VirtualPascal}
                            Sound(2000 + J + (I * 150));
                            Delay(1);
                            {$ELSE}
                            PlaySound(2000 + J + (I * 150), 1);
                            {$ENDIF}
                        END;
                        FOR J := 200 DOWNTO 1 DO BEGIN
                            {$IFNDEF VirtualPascal}
                            Sound(2000 + J + (I * 150));
                            Delay(1);
                            {$ELSE}
                            PlaySound(2000 + J + (I * 150), 1);
                            {$ENDIF}
                        END;
                    END;
                    {$IFNDEF VirtualPascal}
                    NOSOUND;
                    {$ENDIF}
                END;
            CQBEEP :              {send 'CQ de N6EKI' in morse code}
                BEGIN
                    Strg := CQ;
                    {$IFNDEF VirtualPascal}
                    NOSOUND;
                    {$ENDIF}
                    FOR I := 1 TO LENGTH(Strg) DO BEGIN {generic morse code transmitter}
                        CASE Strg[I] OF
                            '-' : {dah}
                                BEGIN
                                    {$IFNDEF VirtualPascal}
                                    Sound(2000);
                                    Delay(MorseDelay * 3);
                                    {$ELSE}
                                    PlaySound(2000, MorseDelay * 3);
                                    {$ENDIF}
                                END;
                            '.' : {dit}
                                BEGIN
                                    {$IFNDEF VirtualPascal}
                                    Sound(2000);
                                    Delay(MorseDelay * 1);
                                    {$ELSE}
                                    PlaySound(2000, MorseDelay);
                                    {$ENDIF}
                                END;
                            ' ' : {word space}
                                Delay(MorseDelay * 2);
                        END;
                        {$IFNDEF VirtualPascal}
                        NOSOUND;
                        {$ENDIF}
                        Delay(MorseDelay * 1); {char space}
                    END;
                    {$IFNDEF VirtualPascal}
                    NOSOUND;
                    {$ENDIF}
                END;

        END;
    END;

    {-------------------------------------------------}
VAR
    OldExitProc    : POINTER;

    {- Traps fatal crashes - expands cryptic TP error code and logs crash}
    {  to error log                                                      }
    PROCEDURE UErrorExit; FAR;
    VAR
        Strg           : STRING[80];
    BEGIN
        IF ERRORADDR <> NIL THEN BEGIN
            IF EXITCODE <> $FF THEN BEGIN {prevent ^Break from being logged}

                {parse the error code}
                Strg := ErrorMessage(EXITCODE);

                {reset crt so we can display message}
                SelectFont8x8(FALSE);
                {$IFDEF USEMOUSE}
                HideMouse;
                {$ENDIF}
                NormalCursor;
                WINDOW(1, 1, ScreenWidth, ScreenHeight);
                TextChar := ' ';
                TextAttr := WhiteOnBlack;
                ClrScr;

                IF LogName = '' THEN
                    LogName := ForceExtension(FExpand(PARAMSTR(0)), 'ERR');

                {write the error message stuff to the screen}
                WRITELN('Fatal Error: ' + Strg + ' @ ' + HexPtr(ERRORADDR));

                IF CompanyName <> NIL THEN BEGIN
                    WRITE('Please send the ');
                    WRITE(LogName);
                    WRITELN(' file to:');
                    WRITELN(StringFromHeap(CompanyName) + ' for review');
                    IF CompanyHours <> NIL THEN BEGIN
                        TextColor(LtRedOnBlack);
                        WRITELN('  Office Hours: ' + StringFromHeap(CompanyHours));
                        TextColor(WhiteOnBlack);
                    END;
                END
                ELSE BEGIN
                    WRITE('Please review the: ');
                    WRITE(LogName);
                    WRITELN(' error log file');
                END;

                {create an error log entry}
                Autopsy(Strg, HexPtr(ERRORADDR));
                Beep(OldBeep);
                WRITELN;
                WRITELN;
                WRITELN('Press Enter to continue');
                READLN;
            END;
            {clean up error handler chain and boogie}
            ERRORADDR := NIL;
            EXITCODE := 0;
        END;
        EXITPROC := OldExitProc;
    END;

    (********************************************)

    PROCEDURE InitMsgArray(VAR Msg : MsgArray);
    BEGIN
        FILLCHAR(Msg, SIZEOF(Msg), #0);
    END;

    (****************************************************************************)

    {-message window, 5 line max, shrinkwraps the text, no buttons }
    {2 second disp time}
    PROCEDURE MessageWin(Header         : STRING;
                         VAR Msg        : MsgArray;
                         VAR EsColors   : ColorSet);
    CONST
        WinOpts        = wBordered + wClear;
    VAR
        I,
        X,
        Y,
        BoxHeight,
        MsgWidth       : INTEGER;
        MsgWin         : RawWindowPtr;
    BEGIN
        MsgWidth := 0;
        BoxHeight := 0;

        FOR I := 1 TO MsgSize DO BEGIN
            IF LENGTH(Msg[I]) > MsgWidth THEN
                MsgWidth := LENGTH(Msg[I]);
            IF LENGTH(Msg[I]) > 0 THEN
                BoxHeight := I;
        END;

        IF BoxHeight = 0 THEN
            EXIT;

        INC(MsgWidth, 6);

        IF MsgWidth < 28 THEN
            MsgWidth := 28;

        X := (ScreenWidth - MsgWidth - 2) DIV 2;
        Y := (ScreenHeight - BoxHeight) DIV 2;

        NEW(MsgWin, InitCustom(X, Y, X + MsgWidth, Y + BoxHeight - 1, EsColors, WinOpts));

        IF MsgWin = NIL THEN
            EXIT;

        MsgWin^.wFrame.AddHeader(Header, heTC);
        {$IFDEF UseShadows}
        MsgWin^.wFrame.AddShadow(shBR, shSeeThru);
        {$ENDIF}
        MsgWin^.EnableExplosions(8);

        {$IFDEF USEMOUSE}
        HideMouse;
        {$ENDIF}
        MsgWin^.Draw;
        MsgWin^.SetCursor(cuHidden);

        FOR I := 1 TO BoxHeight DO
            MsgWin^.wFastText(Center(Msg[I], MsgWidth), I, 1);

        Beep(OldBeep);
        Delay(3000);
        MsgWin^.ERASE;
        {$IFDEF USEMOUSE}
        ShowMouse;
        {$ENDIF}
        DISPOSE(MsgWin, Done);

    END;

    (**************************)

    FUNCTION InitDialogBox(VAR EsColors   : ColorSet;
                           VAR dColors    : DialogColorSet;
                           VAR DB1        : DialogBox;
                           VAR Msg        : MsgArray;
                           HT             : HelpType;
                           HelpInd        : INTEGER) : WORD;
        {-Initialize message dialog box}
    CONST
        WinOptions     = wBordered + wClear;
    VAR
        I,
        X,
        Y,
        BoxHeight,
        ButtonLine,
        MsgWidth       : INTEGER;
    BEGIN
        MsgWidth := 0;
        BoxHeight := 0;
        FOR I := 1 TO MsgSize DO BEGIN
            IF LENGTH(Msg[I]) > MsgWidth THEN
                MsgWidth := LENGTH(Msg[I]);
            IF LENGTH(Msg[I]) > 0 THEN
                BoxHeight := I;
        END;
        IF BoxHeight = 0 THEN
            EXIT;
        INC(BoxHeight, 4);
        INC(MsgWidth, 6);
        IF MsgWidth < 28 THEN
            MsgWidth := 28;
        ButtonLine := BoxHeight - 2;
        X := (ScreenWidth - MsgWidth - 2) DIV 2;
        Y := (ScreenHeight - BoxHeight) DIV 2;
        WITH DB1 DO BEGIN
            {instantiate dialog box}
            IF NOT InitCustom(X + 2,
                              Y + 2,
                              X + MsgWidth + 3,
                              Y + BoxHeight,
                              EsColors,
                              WinOptions,
                              dColors) THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;

            WITH wFrame, EsColors DO BEGIN
                {$IFDEF UseShadows}
                AddShadow(shBR, shSeeThru);
                {$ENDIF}

                {$IFDEF UseHotSpots}
                {add hot spot for closing the window}
                AddCustomHeader('[ ]', frTL, + 2, 0, HeaderColor, HeaderMono);
                AddCustomHeader('þ', frTL, + 3, 0, $7A, HeaderMono);
                AddHotRegion(frTL, hsRegion3, + 3, 0, 1, 1);
                {$ENDIF}

                {$IFDEF UsingDrag}
                {add hot spot for moving the window}
                AddHotBar(frTT, MoveHotCode);
                {$ENDIF}
            END;

            {CustomizeCommandProcessor(DialogCommands);}
            DialogCommands.AddCommand(ccQuit, 1, OpKey.F1, 0);

            EnableExplosions(8);

            FOR I := 1 TO MsgSize DO
                AddCenteredTextField(Msg[I], I);

            dgFieldOptionsOn(efAllowEscape);
            dgSecFieldOptionsOn(sefSwitchCommands);

            CASE HT OF
                hVisible :
                    BEGIN
                        {                 prompt           pr  pc  cr  cc  helpindx    cmd    var}
                        AddPushButton('&Ok', ButtonLine, 3, 6, HelpInd, ccDone, TRUE);
                        AddPushButton('&Cancel', ButtonLine, MsgWidth DIV 2, 6, HelpInd, ccQuit, FALSE);
                        AddPushButton('&Help', ButtonLine, MsgWidth - 6, 6, HelpInd, ccHelp, FALSE);
                    END;
                hHidden :
                    BEGIN
                        {                 prompt           pr  pc  cr  cc  helpindx    cmd    var}
                        AddPushButton('&Ok', ButtonLine, 3, 6, HelpInd, ccDone, TRUE);
                        AddPushButton('&Cancel', ButtonLine, MsgWidth - 6, 6, HelpInd, ccQuit, FALSE);
                    END;
                hProtected :
                    BEGIN
                        {                 prompt           pr  pc  cr  cc  helpindx    cmd    var}
                        AddPushButton('&Ok', ButtonLine, 3, 6, HelpInd, ccDone, TRUE);
                        AddPushButton('&Cancel', ButtonLine, MsgWidth DIV 2, 6, HelpInd, ccQuit, FALSE);
                        dgFieldOptionsOn(efProtected);
                        AddPushButton('&Help', ButtonLine, MsgWidth - 6, 6, HelpInd, ccHelp, FALSE);
                        dgFieldOptionsOff(efHidden);
                    END;
            END;

            SetNextField(idOk);

            InitDialogBox := RawError;
        END;
    END;

    (**********************)

    {heap leakage and fragmentation tools}
    {debug proc to detect memory leaks}
    {put Iam() call in P parameter to save map address of MemFree line}

    {$IFDEF DEBUG}
    {$IFNDEF VirtualPascal}
    PROCEDURE MemFree(Loc : STRING; P : POINTER);
    CONST
        MA             : LONGINT = 0;
        MX             : LONGINT = 0;
    VAR
        Strg           : STRING;
        F              : TEXT;
    BEGIN
        ASSIGN(F, 'junk.tmp');
        {$I-}
        APPEND(F);
        IF IORESULT <> 0 THEN
            REWRITE(F);
        IF MA = 0 THEN BEGIN
            WRITELN(F, '');
            WRITELN(F, TimeDateNow);
            WRITELN(F, 'Loc                         avail   max     deltaAV deltaMax   addr');
        END;
        {$I+}
        Strg := Pad(Loc, 26) + ': ' +
                Pad(Long2Str(MEMAVAIL), 8) +
                Pad(Long2Str(MAXAVAIL), 8) +
                Pad(Long2Str(MEMAVAIL - MA), 8) +
                Pad(Long2Str(MAXAVAIL - MX), 8) +
                HexPtr(P);

        WRITELN(F, Strg);
        MA := MEMAVAIL;
        MX := MAXAVAIL;
        CLOSE(F);
    END;

    FUNCTION PtrDiff(H, L : POINTER) : LONGINT;
        {-Return the number of bytes between H^ and L^. H is the higher address}
    TYPE
        SegOfs         = RECORD
                             O,
                             S              : WORD;
                         END;
    VAR
        HIGH           : SegOfs ABSOLUTE H;
        LOW            : SegOfs ABSOLUTE L;
    BEGIN
        PtrDiff := (LONGINT(HIGH.S) SHL 4 + HIGH.O) - (LONGINT(LOW.S) SHL 4 + LOW.O);
    END;

    (****************************)

TYPE
    PFreeRec       = ^TFreeRec;
    TFreeRec       = RECORD
                         Next           : PFreeRec;
                         Size           : POINTER;
                     END;
    PtrRec         = RECORD
                         LO,
                         HI             : WORD;
                     END;
    BlockRec       = RECORD
                         Loc            : POINTER;
                         Size           : LONGINT;
                         Used           : BOOLEAN;
                     END;
    BlockArray     = ARRAY[1..500] OF BlockRec;

    (****************************)

    {really lame bubble sort, but luckly there are rarely more than a couple hundred blocks}
    PROCEDURE SortArray(VAR A : BlockArray; NumBlocks : WORD);
    VAR
        I              : WORD;
        Done           : BOOLEAN;
    BEGIN
        REPEAT
            Done := TRUE;
            FOR I := 1 TO NumBlocks - 1 DO BEGIN
                IF PtrDiff(A[I].Loc, A[I + 1].Loc) > 0 THEN BEGIN
                    ExchangeStructs(A[I], A[I + 1], SIZEOF(BlockRec));
                    Done := FALSE;
                END;
            END;
        UNTIL Done;
    END;

    (****************************)

    {$IFNDEF DPMI}
    PROCEDURE HeapWalk(Note : STRING; P : POINTER);
    CONST
        MA             : LONGINT = 0;
        MX             : LONGINT = 0;
    VAR
        F              : TEXT;
        LastBlock,
        Runner         : PFreeRec;
        I,
        BlockAppend,
        NumBlocks      : WORD;
        ListArray      : BlockArray;
        FirstFree      : BOOLEAN;
        Strg           : STRING[80];
    BEGIN
        FILLCHAR(ListArray, SIZEOF(ListArray), #0);

        ASSIGN(F, 'junk.tmp');

        IF MA = 0 THEN
            REWRITE(F)
        ELSE BEGIN
            {$I-}
            APPEND(F);
            IF IORESULT <> 0 THEN
                REWRITE(F);
        END;

        WRITE(F, 'HeapWalk ' + HexPtr(P) + '  ');
        WRITELN(F, TimeDateNow);
        WRITELN(F, Pad(Note, 26));

        WRITELN(F);
        WRITELN(F, '    avail   max     deltaAV deltaMax');
        Strg := '    ' +
                Pad(Long2Str(MEMAVAIL), 8) +
                Pad(Long2Str(MAXAVAIL), 8) +
                Pad(Long2Str(MEMAVAIL - MA), 8) +
                Pad(Long2Str(MAXAVAIL - MX), 8);

        WRITELN(F, Strg);
        MA := MEMAVAIL;
        MX := MAXAVAIL;
        WRITELN(F);

        NumBlocks := 0;
        IF PtrDiff(FREELIST, HEAPORG) > 0 THEN BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := HEAPORG;
            ListArray[NumBlocks].Size := PtrDiff(FREELIST, HEAPORG);
            ListArray[NumBlocks].Used := TRUE;
        END;

        Runner := FREELIST;
        FirstFree := TRUE;
        {get all free blocks}
        WHILE Runner <> HEAPPTR DO BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := Runner;
            ListArray[NumBlocks].Size := LONGINT(PtrRec(Runner^.Size).HI) * 16 + PtrRec(Runner^.Size).LO;
            ListArray[NumBlocks].Used := FALSE;
            Runner := Runner^.Next;
            IF NumBlocks > 300 THEN
                BREAK;
        END;

        {get heap free at top of heap}
        IF PtrDiff(HEAPEND, HEAPPTR) > 0 THEN BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := HEAPPTR;
            ListArray[NumBlocks].Size := PtrDiff(HEAPEND, HEAPPTR);
            ListArray[NumBlocks].Used := FALSE;
        END;

        SortArray(ListArray, NumBlocks);

        {find holes between free blocks}
        BlockAppend := NumBlocks;
        FOR I := 1 TO NumBlocks DO BEGIN
            IF PtrDiff(ListArray[I + 1].Loc, ListArray[I].Loc) > ListArray[I].Size THEN BEGIN
                INC(BlockAppend);
                ListArray[BlockAppend].Loc := AddLongToPtr(ListArray[I].Loc, ListArray[I].Size);
                ListArray[BlockAppend].Size := PtrDiff(ListArray[I + 1].Loc, ListArray[BlockAppend].Loc) + 1;
                ListArray[BlockAppend].Used := TRUE;
            END;
        END;

        NumBlocks := BlockAppend;
        SortArray(ListArray, NumBlocks);

        {write out all the used/free blocks to file}
        WRITELN(F, '    Addr      To        Size      Free/Used');
        FOR I := 1 TO NumBlocks DO
            IF ListArray[I].Used THEN
                WRITELN(F,
                        '    ' +
                        Pad(HexPtr(ListArray[I].Loc), 10) +
                        Pad(HexPtr(AddLongToPtr(ListArray[I].Loc, ListArray[I].Size - 1)), 10) +
                        Pad(Long2Str(ListArray[I].Size), 10),
                        'USED')
            ELSE
                WRITELN(F,
                        '    ' +
                        Pad(HexPtr(ListArray[I].Loc), 10) +
                        Pad(HexPtr(AddLongToPtr(ListArray[I].Loc, ListArray[I].Size - 1)), 10) +
                        Pad(Long2Str(ListArray[I].Size), 10),
                        'FREE');


        WRITELN(F, CharStr('=', 15));
        CLOSE(F);
    END;
    {$ENDIF DPMI}

    {$ELSE}

    PROCEDURE MemFree(Loc : STRING; P : POINTER);
    CONST
        MA             : LONGINT = -1;
    VAR
        Strg           : STRING;
        F              : TEXT;
        FileName: String;
        LineNo: Longint;
    BEGIN
        ASSIGN(F, 'junk.tmp');
        {$I-}
        APPEND(F);
        IF IORESULT <> 0 THEN
            REWRITE(F);
        IF MA = -1 THEN BEGIN
            MA := 0;
            WRITELN(F, '');
            WRITELN(F, CharStr('-', 70));
            WRITELN(F, TimeDateNow);
            {                    1         2         3         4         5         6         7}
            {           1234567890123456789012345678901234567890123456789012345678901234567890}
            WRITELN(F, 'Message                     used            delta              addr');
            WRITELN(F, CharStr('-', 70));
        END;
        {$I+}

        Strg := Pad(Loc, 26) + ': ' +
                Pad(Long2Str(MemUsed), 15) +
                Pad(Long2Str(MA - MemUsed), 15);

        if GetLocationInfo( P, FileName, LineNo ) <> NIL then
            Strg := Strg +  '  ' + FileName +':'+ Long2Str(LineNo)
        else
            Strg := Strg + '  ' +  HexPtr(P);

        WRITELN(F, Strg);
        MA := MemUsed;
        CLOSE(F);
    END;

    PROCEDURE HeapWalk(Note : STRING; P : POINTER);
    BEGIN
    END;

(*
    {vp/2 version}
    PROCEDURE HeapWalk(Note : STRING; P : POINTER);
    CONST
        MA             : LONGINT = 0;
        MX             : LONGINT = 0;
    VAR
        F              : TEXT;
        LastBlock,
        Runner         : PHeapRec;
        I,
        BlockAppend,
        NumBlocks      : WORD;
        FirstFree      : BOOLEAN;
        Strg           : STRING[80];
    BEGIN
        ASSIGN(F, 'junk.tmp');

        IF MA = 0 THEN
            REWRITE(F)
        ELSE BEGIN
            {$I-}
            APPEND(F);
            IF IORESULT <> 0 THEN
                REWRITE(F);
        END;

        WRITE(F, 'HeapWalk ' + HexPtr(P) + '  ');
        WRITELN(F, TimeDateNow);
        WRITELN(F, Pad(Note, 26));

        WRITELN(F);
        WRITELN(F, '    avail   max     deltaAV deltaMax');
        Strg := '    ' +
                Pad(Long2Str(MEMAVAIL), 8) +
                Pad(Long2Str(MAXAVAIL), 8) +
                Pad(Long2Str(MEMAVAIL - MA), 8) +
                Pad(Long2Str(MAXAVAIL - MX), 8);

        WRITELN(F, Strg);
        MA := MEMAVAIL;
        MX := MAXAVAIL;
        WRITELN(F);

        NumBlocks := 0;
        IF PtrDiff(FREELIST, HEAPORG) > 0 THEN BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := HEAPORG;
            ListArray[NumBlocks].Size := PtrDiff(FREELIST, HEAPORG);
            ListArray[NumBlocks].Used := TRUE;
        END;

        Runner := FREELIST;
        FirstFree := TRUE;
        {get all free blocks}
        WHILE Runner <> HEAPPTR DO BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := Runner;
            ListArray[NumBlocks].Size := LONGINT(PtrRec(Runner^.Size).HI) * 16 + PtrRec(Runner^.Size).LO;
            ListArray[NumBlocks].Used := FALSE;
            Runner := Runner^.Next;
            IF NumBlocks > 300 THEN
                BREAK;
        END;

        {get heap free at top of heap}
        IF PtrDiff(HEAPEND, HEAPPTR) > 0 THEN BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := HEAPPTR;
            ListArray[NumBlocks].Size := PtrDiff(HEAPEND, HEAPPTR);
            ListArray[NumBlocks].Used := FALSE;
        END;

        SortArray(ListArray, NumBlocks);

        {find holes between free blocks}
        BlockAppend := NumBlocks;
        FOR I := 1 TO NumBlocks DO BEGIN
            IF PtrDiff(ListArray[I + 1].Loc, ListArray[I].Loc) > ListArray[I].Size THEN BEGIN
                INC(BlockAppend);
                ListArray[BlockAppend].Loc := AddLongToPtr(ListArray[I].Loc, ListArray[I].Size);
                ListArray[BlockAppend].Size := PtrDiff(ListArray[I + 1].Loc, ListArray[BlockAppend].Loc) + 1;
                ListArray[BlockAppend].Used := TRUE;
            END;
        END;

        NumBlocks := BlockAppend;
        SortArray(ListArray, NumBlocks);

        {write out all the used/free blocks to file}
        WRITELN(F, '    Addr      To        Size      Free/Used');
        FOR I := 1 TO NumBlocks DO
            IF ListArray[I].Used THEN
                WRITELN(F,
                        '    ' +
                        Pad(HexPtr(ListArray[I].Loc), 10) +
                        Pad(HexPtr(AddLongToPtr(ListArray[I].Loc, ListArray[I].Size - 1)), 10) +
                        Pad(Long2Str(ListArray[I].Size), 10),
                        'USED')
            ELSE
                WRITELN(F,
                        '    ' +
                        Pad(HexPtr(ListArray[I].Loc), 10) +
                        Pad(HexPtr(AddLongToPtr(ListArray[I].Loc, ListArray[I].Size - 1)), 10) +
                        Pad(Long2Str(ListArray[I].Size), 10),
                        'FREE');


        WRITELN(F, CharStr('=', 15));
        CLOSE(F);
    END;
*)
    {$ENDIF}
    (********************************************)

    {$IFNDEF DPMI}
    {$IFNDEF VirtualPascal}
TYPE
    EMA            = RECORD
                         P              : POINTER;
                         S              : LONGINT;
                     END;
VAR
    EatMeArray     : ARRAY[1..8] OF EMA;

    {- eat up all but MemToLeave conventional memory bytes of the heap}
    {for stress testing                           }
    PROCEDURE EatMe(MemToLeave : LONGINT);
    VAR
        T              : LONGINT;
        I,
        MouthFull      : WORD;
    BEGIN
        FILLCHAR(EatMeArray, SIZEOF(EatMeArray), #0);

        I := 1;
        T := MEMAVAIL;
        T := MAXAVAIL;
        WHILE T > MemToLeave DO BEGIN
            MouthFull := $FFF0;
            IF T - MemToLeave < MouthFull THEN
                MouthFull := T - MemToLeave;
            GetMemCheck(EatMeArray[I].P, MouthFull);
            EatMeArray[I].S := MouthFull;
            INC(I);
            T := MAXAVAIL;
        END;
    END;

    (****************************)

    {- spit out all of eaten heap}
    PROCEDURE Puke;
    VAR
        I              : WORD;
    BEGIN
        I := 1;
        WHILE EatMeArray[I].P <> NIL DO BEGIN
            FreeMemCheck(EatMeArray[I].P, EatMeArray[I].S);
            INC(I);
        END;
    END;

    (****************************)

    {$ENDIF}
    {$ENDIF}
    {$ENDIF}
    (*************************************************************************)
    {$IFNDEF DLL}
VAR
    TP,
    HC             : POINTER;
    I              : LONGINT;
    J              : WORD;
BEGIN
    OldExitProc := EXITPROC;
    EXITPROC := @UErrorExit;
    LogName := '';
    CurrentClockProc := DefaultClock;
    CurrentUserErrorMessageProc := NilUserErrorMessageProc;

    {to keep the Brits happy with their backwards date strings ;-) }
    Ds := InternationalDate(TRUE, TRUE);

    Ts := ' hh:mm:ss';

    ProgramRevision := '';
    CompanyName := NIL;
    CompanyHours := NIL;
    {$ENDIF}
END.

(********************************************)
(********************************************)
