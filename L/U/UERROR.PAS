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
*
****************************************************************************

}
UNIT UERROR;
{$I OPDEFINE.INC}
{$V-,O+,X+,D+,L+}


INTERFACE

USES
    OpCONST;

CONST
    ecUserAbort = epNonFatal + 300;
    HappyFaceChar = #1;

FUNCTION Autopsy(Strg1, Strg2 : STRING) : BOOLEAN;
FUNCTION AutopsyDeluxe(Strg1, Strg2 : STRING; P : POINTER) : BOOLEAN;
PROCEDURE DispError(Strg1, Strg2 : STRING; Logit : BOOLEAN);
PROCEDURE DispErrorDeluxe(Strg1, Strg2 : STRING; Logit : BOOLEAN; P : POINTER);
FUNCTION ErrorMessage(Status : WORD) : STRING;
PROCEDURE PutMsg(Header, Strg1, Strg2 : STRING);
PROCEDURE KillMsg;
FUNCTION KTimer : LONGINT;
FUNCTION TimeDateNow : STRING;
FUNCTION CheckMemAvail(MemNeeded:LONGINT; LocStrg:STRING; FailLoc:POINTER):BOOLEAN;

{$IFDEF DEBUG}
    {debug proc to detect memory leaks}
    PROCEDURE MemFree(Loc : STRING; P : POINTER);
    {gobble heap until there is MemToLeave bytes free}
    PROCEDURE EatMe(MemToLeave:LONGINT);
    {spit out gobbled heap}
    PROCEDURE Puke;
    {write heap free/used list contents to file}
    {$IFNDEF DPMI}
    {$IFDEF HeapDebug}
    PROCEDURE HeapWalk(Note:STRING; P : POINTER);

    {turn on heap allocation logging}
    PROCEDURE SetKHeapFunc;
    {turn off heap allocation logging}
    PROCEDURE RestoreOldHeapFunc;
    {$ENDIF}
    {$ENDIF}
{$ENDIF}

VAR
    LastQHeapComment : STRING[80];
    ProgramRevision  : STRING[10];
    (****************************************************************************)

IMPLEMENTATION

USES
    Dos,
    UTTIMDAT,
    OpCrt,
    OpDate,
    OpFrame,
    OpInline,
    OpRoot,
    OpString,
    OpWindow,
    QHdrRec,
    UColors,
    UDIALOG,
    UKey,
    ULIB,
    UMsg;


    (****************************************************************************)
VAR
    PopMsgWin      : RawWindowPtr;

    (****************************************************************************)

    PROCEDURE PutMsg(Header, Strg1, Strg2 : STRING);
        {- display a popup message box.  Remove it with KillMsg }
    VAR
        X,
        WinWidth,
        WinHeight      : INTEGER;
        WinOpts,
        TTime          : LONGINT;
        EsColors       : ColorSet;
    BEGIN
        GetCScheme(Red_Scheme, EsColors);

        WinOpts := wBordered + wClear + wSaveContents;

        IF LENGTH(Strg1) > LENGTH(Strg2) THEN
            WinWidth := LENGTH(Strg1)
        ELSE
            WinWidth := LENGTH(Strg2);

        X := (ScreenWidth - WinWidth) DIV 2;

        IF LENGTH(Strg2) > 0 THEN
            WinHeight := 2
        ELSE
            WinHeight := 1;

        NEW(PopMsgWin, InitCustom(X,
                                  10,

                                  X + WinWidth,
                                  10 + WinHeight,

                                  EsColors,
                                  WinOpts));

        IF PopMsgWin = NIL THEN
            EXIT;

        WITH PopMsgWin^ DO BEGIN
            SetCursor(cuHidden);
            wFrame.AddHeader(Header, heTC);
            wFrame.AddShadow(shBR, shSeeThru);
            EnableExplosions(8);
            Draw;
            wFastText(Strg1, 1, 1);
            IF WinHeight = 2 THEN
                wFastText(Strg2, 2, 1);
        END;

        {Beep(ATNBEEP);}

        {UpdateClock;}

    END;

    (****************************************************************************)

    PROCEDURE KillMsg;
        {- Kill a message window }
    BEGIN
        IF PopMsgWin = NIL THEN
            EXIT;
        PopMsgWin^.ERASE;
        DISPOSE(PopMsgWin, Done);
        PopMsgWin := NIL;
    END;

    (****************************************************************************)

    {this is for internal use only - not internationalized or configurable}
    FUNCTION TimeDateNow : STRING;
        {-Return string containing current time and date }
    BEGIN
        TimeDateNow := DateToDateString('www dd nnn yyyy', Today) +
                       CurrentTimeString(' hh:mm:ss te');
    END;                          {of func TimeDateNow}

    (****************************************************************************)

    FUNCTION AutopsyDeluxe(Strg1, Strg2 : STRING; P : POINTER) : BOOLEAN;
    VAR
        TFile          : TEXT;
        LastError      : WORD;
        ExeDir,
        LogDir         : PathStr;
        F              : FILE;
        FTime          : LONGINT;
        T              : OpDate.Time;
        D              : OpDate.Date;
        Hfc            : CHAR;
        Hfa            : BYTE;
        OldX,
        OldY           : BYTE;
    PROCEDURE KWRITELN(VAR T : TEXT; Tag, Strg:STRING);
    BEGIN
        IF LENGTH(Strg) = 0 THEN
            EXIT;
        WRITELN(T, Tag+': '+Strg);
    END;

    BEGIN
        AutopsyDeluxe := FALSE;
        IF SYS <> NIL THEN
            IF SYS^.LogLevel = 0 THEN
                EXIT;             {if thats the way you want it...}

        LogDir := JustPathname(PARAMSTR(0));
        ExeDir := LogDir;

        IF NEN <> NIL THEN BEGIN
            IF LENGTH(NEN^.LogFileDir) <> 0 THEN
                LogDir := NEN^.LogFileDir;
            IF LENGTH(NEN^.SysDir) <> 0 THEN
                ExeDir := NEN^.SysDir;
        END;

        ASSIGN(TFile, AddBackSlash(LogDir) +
               ForceExtension(GetUserName, 'ERR')); {open data files}

        {$I-}
        RESET(TFile);
        LastError := IORESULT;
        {$I+}

        CASE LastError OF
            0 : BEGIN
                    CLOSE(TFile); {found existing file, so append}
                    APPEND(TFile);
                END;
            2 : BEGIN
                    {$I-}
                    REWRITE(TFile); {create new file}
                    LastError := IORESULT;

                    IF LastError <> 0 THEN BEGIN
                        CLOSE(TFile);
                        LastError := IORESULT; {clear possible error if file not open}
                        EXIT;
                    END;
                    {$I+}
                END;
            ELSE BEGIN
                {crash if file error} {boom!}
                EXIT;
            END;
        END;

        WRITELN(TFile, CharStr('*', 10));

        {first, look in the sysdir for the exe}
        ASSIGN(F, AddBackSlash(ExeDir) + JustFileName(PARAMSTR(0)));
        {$I-}
        RESET(F);                 { open current exe file for read}
        LastError := IORESULT;
        {$I+}
        IF LastError = 0 THEN BEGIN
            GetFTime(F, FTime);   { Get creation time }
            CLOSE(F);             { Close file }
            UnpackDOStime(FTime, T, D);

            WRITELN(TFile, AddBackSlash(ExeDir) + JustFileName(PARAMSTR(0)));
            WRITELN(TFile, 'Exe date: ' +
                    DateToDateString('dd nnn yyyy', D) + ' ' +
                    TimeToTimeString('hh:mm:ss', T));
        END
        ELSE BEGIN
            {look on the paramstr path, exe wasn't in sysdir}
            ASSIGN(F, PARAMSTR(0));
            {$I-}
            RESET(F);             { open current exe file for read}
            LastError := IORESULT;
            {$I+}
            IF LastError = 0 THEN BEGIN
                GetFTime(F, FTime); { Get creation time }
                CLOSE(F);         { Close file }
                UnpackDOStime(FTime, T, D);

                WRITELN(TFile, PARAMSTR(0));
                WRITELN(TFile, 'Exe date: ' +
                        DateToDateString('dd nnn yyyy', D) + ' ' +
                        TimeToTimeString('hh:mm:ss', T));
            END
            ELSE BEGIN            {can't find the damned thing anywhere - give up}
                WRITELN(TFile, PARAMSTR(0));
                WRITELN(TFile, 'Exe date: Unknown');
            END;
        END;

        KWRITELN(TFile, 'PrgRev', ProgramRevision);   {revision level of program}
        KWRITELN(TFile, 'PrgRel', '~release~');       {release  level of program}

        WRITELN(TFile, 'Error Date: ' + TimeDateNow);
        WRITELN(TFile, 'L1: ' + Strg1);
        WRITELN(TFile, 'L2: ' + Strg2);
        IF LENGTH(LastQHeapComment) > 0 THEN
            WRITELN(TFile, 'LastQHeapComment: ' + LastQHeapComment);
        IF P <> NIL THEN
            WRITELN(TFile, 'ERRORADDR: ', HexPtr(P));

        OldX := WhereX;
        OldY := WhereY;
        {move to upper left corner of screen}
        GotoXY(1,1);
        {read the happyface if any}
        Hfc := ReadCharAtCursor;
        {read the happy face attribute}
        Hfa := ReadAttrAtCursor;

        KWRITELN(TFile, 'HappyFace', '$' + HexB(Hfa)); {write info to ERR file}

        GotoXY(OldX, OldY);

        GETDIR(0, ExeDir);
        WRITELN(TFile, 'CurDir: ', ExeDir);
        IF SYS <> NIL THEN BEGIN
            WITH SYS^ DO BEGIN
                KWRITELN(TFile, 'StationID', StationID);
                KWRITELN(TFile, 'StationLoc', StationLoc);
                KWRITELN(TFile, 'License', License);
                KWRITELN(TFile, 'Workstations', WorkStations);
                KWRITELN(TFile, 'LogLevel', Long2Str(LogLevel));
{                KWRITELN(TFile, 'UnusedFS', UnusedFS);}   {Name of current q's File Server}
                KWRITELN(TFile, 'ToQFS', ToQFS);         {Name of Copy/Move To Q File Server}
                KWRITELN(TFile, 'HomeFS', HomeFS);       {Name of home file server}
                KWRITELN(TFile, 'BaseFS', BaseFS);       {Name Of Base File Server }
                KWRITELN(TFile, 'SaveGetFS', SaveGetFS);
                KWRITELN(TFile, 'RecordFS', RecordFS);   {Name of record File Server?}
            END;
        END;

        CLOSE(TFile);
        AutopsyDeluxe := TRUE;
    END;

    (****************************************************************************)

    FUNCTION Autopsy(Strg1, Strg2 : STRING):BOOLEAN;
    BEGIN
        Autopsy := AutopsyDeluxe(Strg1, Strg2, NIL);
    END;

    (****************************************************************************)

    FUNCTION KTimer : LONGINT;
        {Returns number of centiseconds (hundredths) since midnight }
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
        GetTime(H, M, S, S100);
        T := (H * HPH) + (M * HPM) + (S * HPS) + S100;
        KTimer := T;
    END;

    (******************************************************************************)

    PROCEDURE DispErrorDeluxe(Strg1, Strg2 : STRING; Logit : BOOLEAN; P : POINTER);
    VAR
        MsgWin         : RawWindowPtr;
        Temp           : BOOLEAN;
        X,
        WinWidth,
        WinHeight      : INTEGER;
        WinOpts,
        TTime          : LONGINT;
        EsColors       : ColorSet;
        Cx,
        Cy             : BYTE;
    BEGIN

        GetCScheme(Red_Scheme, EsColors);
        Cx := WhereXAbs;
        Cy := WhereYAbs;
        Window(1, 1, ScreenWidth, ScreenHeight);

        IF Logit THEN
            AutopsyDeluxe(Strg1, Strg2, P);

        IF MAXAVAIL < 4000 THEN
            EXIT;

        WinOpts := wBordered + wClear + wSaveContents;

        {shrink-wrap the window to fit the size of the message or the size }
        {of the window header, which ever is the largest                   }
        WinWidth := MaxWord(LENGTH(Strg1), LENGTH(Strg2));
        WinWidth := MaxWord(WinWidth, 5);

        X := (ScreenWidth - WinWidth) DIV 2;

        IF LENGTH(Strg2) > 0 THEN
            WinHeight := 2
        ELSE
            WinHeight := 1;

        SetBlink(FALSE);

        {check current video mode flag for graphics
        IF VideoMode <> ALPHA THEN
            TextMode(LASTMODE);}

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
            wFrame.AddShadow(shBR, shSeeThru);
            EnableExplosions(8);
            Draw;
            wFastText(Strg1, 1, 1);
            IF WinHeight = 2 THEN
                wFastText(Strg2, 2, 1);
        END;

        {Beep(TESTFAIL);}

        TTime := KTimer;
        WHILE KTimer - TTime < 400 DO
            KeyWaiting;

        MsgWin^.ERASE;
        DISPOSE(MsgWin, Done);
        GotoXYAbs(Cx, Cy);
    END;

    (******************************************************************************)

    PROCEDURE DispError(Strg1, Strg2 : STRING; Logit : BOOLEAN);
        { display an error message inside a bordered window at location (XY) }
        { size the box to fit the string                                     }
    BEGIN
        DispErrorDeluxe(Strg1, Strg2, Logit, NIL);
    END;

    (******************************************************************************)

    FUNCTION ErrorMessage(Status : WORD) : STRING;
        {-Return Turbo runtime error messages}
    VAR
        S              : STRING;
    BEGIN
        CASE Status DIV 10000 OF
            0 : S := SysMsg(2473); {epFatal}
            1 : S := SysMsg(2474); {epNonFatal}
            2 : S := SysMsg(2475); {epWarning}
            3 : S := SysMsg(2476); {epMessage}
        END;
        CASE Status MOD 10000 OF
            000 : S := '';
            002 : S := S + SysMsg(002213) {'File not found'} ;
            003 : S := S + SysMsg(002214) {'Path not found'} ;
            004 : S := S + SysMsg(002215) {'Too many open files'} ;
            005 : S := S + SysMsg(002216) {'File access denied'} ;
            006 : S := S + SysMsg(002217) {'Invalid file handle'} ;
            008 : S := S + SysMsg(002662) +
            ' '+
            Long2Str(MEMAVAIL)+
            ':'+
            Long2Str(MAXAVAIL); {Insufficient Memory}
            012 : S := S + SysMsg(002218) {'Invalid file access code'} ;
            015 : S := S + SysMsg(002219) {'Invalid drive number'} ;
            016 : S := S + SysMsg(002220) {'Cannot remove current directory'} ;
            017 : S := S + SysMsg(002221) {'Cannot rename across drives'} ;
            018 : S := S + SysMsg(002472) {no more files} ;
            060 : S := S + SysMsg(002666) {'dBase DBF file header invalid; GS 1001'};
            061 : S := S + SysMsg(002667) {'dBase record request beyond EOF; GS 1002'};
            062 : S := S + SysMsg(002668) {'dBase field name is invalid; GS 1003'};
            063 : S := S + SysMsg(002669) {'dBase field is of incorrect type; GS 1004'};
            064 : S := S + SysMsg(002670) {'dBase memo record has format error; GS 1005'};
            065 : S := S + SysMsg(002671) {'Formula expression cannot be translated; GS 1006'};
            066 : S := S + SysMsg(002672) {'Dest file for sort or copy already open; GS 1007'};
            067 : S := S + SysMsg(002673) {'Object is not initialized in file area; GS 1008'};
            068 : S := S + SysMsg(002674) {'Error in GSO_DiskFile.AddToFile; GS 1112'};
            069 : S := S + SysMsg(002675) {'Error in GSO_DiskFile.Close; GS 1103'};
            070 : S := S + SysMsg(002676) {'Error in GSO_DiskFile.Erase; GS 1104'};
            071 : S := S + SysMsg(002677) {'Error in GSO_DiskFile.FileSize; GS 1105'};
            072 : S := S + SysMsg(002678) {'Error in GSO_DiskFile.Flush; GS 1111'};
            073 : S := S + SysMsg(002679) {'Error in GSO_DiskFile.Read; GS 1101'};
            074 : S := S + SysMsg(002680) {'Error in GSO_DiskFile.ReName; GS 1106'};
            075 : S := S + SysMsg(002681) {'Error in GSO_DiskFile.Reset; GS 1107'};
            076 : S := S + SysMsg(002682) {'Error in GSO_DiskFile.Write; GS 1108'};
            077 : S := S + SysMsg(002683) {'Error in GSO_DiskFile.Truncate; GS 1109'};
            078 : S := S + SysMsg(002684) {'Error in GSO_DiskFile.Write; GS 1102'};
            079 : S := S + SysMsg(002685) {'Error in GSO_dBaseDBF.Append; GS 1206'};
            080 : S := S + SysMsg(002686) {'Error in GSO_dBaseFLD.CheckField; GS 1299'};
            081 : S := S + SysMsg(002687) {'Error in GSO_dBaseDBF.GetRec; GS 1207'};
            082 : S := S + SysMsg(002688) {'Error in GSO_dBaseDBF.HdrWrite; GS 1201'};
            083 : S := S + SysMsg(002689) {'Error in GSO_dBaseDBF.Init; GS 1204'};
            084 : S := S + SysMsg(002690) {'Error in GSO_dBaseDBF.PutRec; GS 1202'};
            085 : S := S + SysMsg(002691) {'Error in GSO_dBHandler.Formula; GS 2101'};
            086 : S := S + SysMsg(002692) {'Error in GSO_dBHandler.MemoGet; GS 2102'};
            087 : S := S + SysMsg(002693) {'Error in GSO_dBHandler.MemoGetN; GS 2103'};
            088 : S := S + SysMsg(002694) {'Error in GSO_dBHandler.MemoPutN; GS 2104'};
            089 : S := S + SysMsg(002695) {'Error in GSO_dBHandler.Pack; GS 2105'};
            090 : S := S + SysMsg(002696) {'Error in GSO_dBHandler.SortFile; GS 2107'};
            091 : S := S + SysMsg(002697) {'Error in GSO_dBHandler.Zap; GS 2106'};
            092 : S := S + SysMsg(002698) {'Error in GSO_IndexFile.Init; GS 5101'};
            093 : S := S + SysMsg(002699) {'Error in GSO_IndexFile.Ndx_AdjVal; GS 5102'};
            094 : S := S + SysMsg(002700) {'Error in GSO_IndexFile.KeyUpdate; GS 5103'};
            095 : S := S + SysMsg(002701) {'Error in GSO_IdxColl.RetrieveKey; GS 5211'};
            096 : S := S + SysMsg(002702) {'Error in GSO_dBMemo.Init; GS 6101'};
            097 : S := S + SysMsg(002703) {'Error in GSO_dBMemo.MemoPut; GS 6102'};
            098 : S := S + SysMsg(002704) {'Error in GSO_dBMemo4.MemoSetParam; GS 6199'};
            099 : S := S + SysMsg(002705) {'Accessed a file area that is not Use''d; GS 7101'};
            100 : S := S + SysMsg(002222) {'Disk read error'} ;
            101 : S := S + SysMsg(002223) {'Disk write error'} ;
            102 : S := S + SysMsg(002224) {'File not assigned'} ;
            103 : S := S + SysMsg(002225) {'File not open'} ;
            104 : S := S + SysMsg(002226) {'File not open for input'} ;
            105 : S := S + SysMsg(002227) {'File not open for output'} ;
            150 : S := S + SysMsg(002228) {'Disk is write-protected'} ;
            151 : S := S + SysMsg(002229) {'Unknown unit'} ;
            152 : S := S + SysMsg(002230) {'Drive not ready'} ;
            153 : S := S + SysMsg(2470); {unknown command}
            154 : S := S + SysMsg(002231) {'CRC error in data'} ;
            156 : S := S + SysMsg(002232) {'Disk seek error'} ;
            157 : S := S + SysMsg(002233) {'Unknown media type'} ;
            158 : S := S + SysMsg(002234) {'Sector not found'} ;
            159 : S := S + SysMsg(2471) {printer is out of paper} ;
            160 : S := S + SysMsg(002235) {'Device write fault'} ;
            161 : S := S + SysMsg(002236) {'Device read fault'} ;
            162 : S := S + SysMsg(002237) {'Hardware failure'} ;
            200 : S := S + SysMsg(002238) {'Division by zero'} ;
            201 : S := S + SysMsg(002239) {'Range check error'} ;
            202 : S := S + SysMsg(002240) {'Stack overflow error'} ;
            203 : S := S + SysMsg(002241) {'Heap overflow error'} ;
            204 : S := S + SysMsg(002242) {'Invalid pointer operation'} ;
            205 : S := S + SysMsg(002243) {'Floating point overflow'} ;
            206 : S := S + SysMsg(002244) {'Floating point underflow'} ;
            207 : S := S + SysMsg(002245) {'Invalid floating point operation'} ;
            208 : S := S + SysMsg(002246) {'Overlay manager not installed'} ;
            209 : S := S + SysMsg(002247) {'Overlay file read error'} ;
            210 : S := S + SysMsg(002248) {'Object not initialized'} ;
            211 : S := S + SysMsg(002249) {'Call to abstract method'} ;
            212 : S := S + SysMsg(002250) {'Stream registration error'} ;
            213 : S := S + SysMsg(002251) {'Collection index out of range'} ;
            214 : S := S + SysMsg(002252) {'Collection overflow error'} ;
            215 : S := S + SysMsg(002253) {'Arithmetic overflow error'} ;
            216 : S := S + SysMsg(002254) {'General Protection fault'} ;
            ecUserAbort : S := SysMsg(002665);
            01000 : S := S + SysMsg(2478); {file is empty}
            01101 : S := S + SysMsg(2479); {unknown object id read from stream}
            01102 : S := S + SysMsg(2480); {load constructor failed within Get or GetPtr}
            01103 : S := S + SysMsg(2481); {attempt to read/write bad data}
            01200 : S := S + SysMsg(2482); {can't add entry if name is blank}
            01201 : S := S + SysMsg(2483); {error packing OpLibrary}
            01202 : S := S + SysMsg(2484); {bad signature in directory}
            02000 : S := S + SysMsg(2485); {queue is full. new element rejected}
            02001 : S := S + SysMsg(2486); {queue is empty. no element returned}
            02002 : S := S + SysMsg(2487); {string array from text file exceeds 64K}
            02020 : S := S + SysMsg(2488); {directory full--can't add entry}
            02050 : S := S + SysMsg(2489); {cannot add command due to partial match}
            02051 : S := S + SysMsg(2490); {cannot add command due to full key table}
            02100 : S := S + SysMsg(2491); {insufficient EMS memory to allocate}
            02101 : S := S + SysMsg(2492); {error allocating EMS page}
            02102 : S := S + SysMsg(2493); {EMS operation failed because no EMS available}
            02103 : S := S + SysMsg(2494); {error mapping EMS page}
            02104 : S := S + SysMsg(2495); {cannot deallocate EMS handle}
            02110 : S := S + SysMsg(2496); {error moving memory to/from XMS}
            02111 : S := S + SysMsg(2497); {insufficient XMS memory to allocate}
            02112 : S := S + SysMsg(2498); {unable to free XMS handle}
            02113 : S := S + SysMsg(2499); {no XMS memory present}
            02114 : S := S + SysMsg(2500); {element size is not even}
            02200 : S := S + SysMsg(2590); {too many files to fit into directory buffer}
            07000 : S := S + SysMsg(2591); {field is required}
            07001 : S := S + SysMsg(2592); {bad format (number/date/time, etc.}
            07002 : S := S + SysMsg(2593); {value entered is out of range}
            07003 : S := S + SysMsg(2594); {field contains blanks}
            07004 : S := S + SysMsg(2595); {field contains a partial entry}
            07005 : S := S + SysMsg(2596); {field contains an illegal character}
            07100 : S := S + SysMsg(2597); {search string not found}
            07101 : S := S + SysMsg(2598); {cannot write output to screen}
            07102 : S := S + SysMsg(2599); {invalid number entered}
            07110 : S := S + SysMsg(2600); {edit buffer is full}
            07111 : S := S + SysMsg(2601); {line too long, CRLF inserted}
            07112 : S := S + SysMsg(2602); {max line limit would be exceeded}
            07113 : S := S + SysMsg(2603); {max line limit already exceeded}
            07114 : S := S + SysMsg(2604); {file truncated}
            07115 : S := S + SysMsg(2605); {file too large to fit in buffer}
            07116 : S := S + SysMsg(2606); {block not marked or hidden}
            07117 : S := S + SysMsg(2607); {marker not set}
            07200 : S := S + SysMsg(2608); {divide overflow}
            07201 : S := S + SysMsg(2609); {error returned by 80x87 coprocessor}
            07300 : S := S + SysMsg(2610); {no pick selection made}
            07400 : S := S + SysMsg(2611); {name already in use}
            07401 : S := S + SysMsg(2612); {OpLibrary entry not found}
            08000 : S := S + SysMsg(2613); {string is already in string set}
            08010 : S := S + SysMsg(2614); {user object not registered with stream}
            08011 : S := S + SysMsg(2615); {attempt to register duplicate object id}
            08012 : S := S + SysMsg(2616); {user pointer not registered with stream}
            08050 : S := S + SysMsg(2617); {element size is zero}
            08051 : S := S + SysMsg(2618); {incorrect dimensions for disk file}
            08052 : S := S + SysMsg(2619); {specified row is out of range}
            08053 : S := S + SysMsg(2620); {specified column is out of range}
            08054 : S := S + SysMsg(2621); {specified file is not a OpLarray file}
            08055 : S := S + SysMsg(2622); {Element size is too big}
            08056 : S := S + SysMsg(2623); {an invalid dimension was specified}
            08057 : S := S + SysMsg(2624); {less than one page in RAM}
            08058 : S := S + SysMsg(2625); {error flushing large array file}
            08100 : S := S + SysMsg(2626); {bad coordinates specified for a window}
            08101 : S := S + SysMsg(2627); {window must be active for this operation}
            08102 : S := S + SysMsg(2628); {window must be current for this operation}
            08103 : S := S + SysMsg(2629); {window must be inactive for this operation}
            08104 : S := S + SysMsg(2630); {stacked window not accessible}
            08105 : S := S + SysMsg(2631); {zoomed window cannot be zoomed again}
            08106 : S := S + SysMsg(2632); {invalid header or hot spot index}
            08107 : S := S + SysMsg(2633); {window must be sizeable for this operation}
            08108 : S := S + SysMsg(2634); {no command processor is available}
            08109 : S := S + SysMsg(2635); {operation is not valid on a child window}
            08200 : S := S + SysMsg(2636); {attempt to pick from empty list}
            08201 : S := S + SysMsg(2637); {invalid pick orientation}
            08202 : S := S + SysMsg(2638); {invalid pick command handler}
            08220 : S := S + SysMsg(2639); {invalid help file format}
            08221 : S := S + SysMsg(2640); {no help for specified topic}
            08222 : S := S + SysMsg(2641); {pointer for bound-in help not registered}
            08300 : S := S + SysMsg(2642); {too many fields in a selector/entry screen}
            08301 : S := S + SysMsg(2643); {bad coordinates for a field}
            08302 : S := S + SysMsg(2644); {virtual screen not allocated}
            08303 : S := S + SysMsg(2645); {selector/entry screen has no fields}
            08305 : S := S + SysMsg(2646); {attempt to position cursor on non-existent field}
            08306 : S := S + SysMsg(2647); {can't add window field to ScrollingEntryScreen}
            08307 : S := S + SysMsg(2648); {child window already has parent or is active}
            08400 : S := S + SysMsg(2649); {specified Printer type is invalid}
            08401 : S := S + SysMsg(2650); {printer position out of range}
            08402 : S := S + SysMsg(2651); {no printer position routine specified}
            08403 : S := S + SysMsg(2652); {stack overflow in font stack}
            08404 : S := S + SysMsg(2653); {stack underflow in font stack}
            08405 : S := S + SysMsg(2654); {stack overflow in a byte stack}
            08406 : S := S + SysMsg(2655); {no BasePrinterPtr specified for Printer}
            08420 : S := S + SysMsg(2656); {page to be printed has no active fields}
            08421 : S := S + SysMsg(2657); {attempt to add field when no block defined}
            08422 : S := S + SysMsg(2658); {FieldID represents non-existent field}
            08423 : S := S + SysMsg(2659); {diagonal lines not allowed}
            08500 : S := S + SysMsg(2660); {nil pointer where there shouldn't be one}
            08501 : S := S + SysMsg(2661); {bad parameter to a procedure}
            ELSE
                S := SysMsg(002255) {'Turbo runtime error '} + Long2Str(Status);
        END;
        {Check for SysMsg lookup failure}

        IF (POS('!!', S) > 0) OR (S = '') THEN
            S := 'Runtime Error ' + Long2Str(Status);

        ErrorMessage := S;
    END;

    (*************************************************************************)
VAR
    OldExitProc    : POINTER;

    (*************************************************************************)

    PROCEDURE UErrorExit; FAR;
    VAR
        Strg           : STRING[80];
        LogDir         : PathStr;
    BEGIN
        IF ERRORADDR <> NIL THEN BEGIN
            IF EXITCODE <> $FF THEN BEGIN {prevent ^Break from being logged}
                WINDOW(1, 1, ScreenWidth, ScreenHeight);
                Strg := ErrorMessage(EXITCODE);
                ClrScr;
                WRITELN('Error: ' + Strg + ' @ ' + HexPtr(ERRORADDR));
                LogDir := JustPathname(PARAMSTR(0));

                IF NEN <> NIL THEN BEGIN
                    IF LENGTH(NEN^.LogFileDir) <> 0 THEN
                        LogDir := NEN^.LogFileDir;
                END;
                LogDir := AddBackSlash(LogDir) + ForceExtension(GetUserName, 'ERR');

                IF Autopsy('Fatal Exit: ' + Strg, HexPtr(ERRORADDR)) THEN BEGIN
                    WRITE('Please send the ' + LogDir);
                    WRITELN(' file to NewsMaker for review');
                END;

                Beep(OLDBEEP);
                Delay(2000);
            END;
            ERRORADDR := NIL;
            EXITCODE := 0;
        END;
        EXITPROC := OldExitProc;
    END;

    (****************************)

    FUNCTION CheckMemAvail(MemNeeded:LONGINT; LocStrg:STRING; FailLoc:POINTER):BOOLEAN;
    VAR
       MM,
       MA : LONGINT;
    BEGIN
         CheckMemAvail := FALSE;
         MM := MEMAVAIL;
         MA := MAXAVAIL;
         IF MemNeeded > MA THEN BEGIN
            DispErrorDeluxe('Almost out of memory!',
                            LocStrg+' : '+
                            Long2Str(MM)+
                            ':'+
                            Long2Str(MA),
                            TRUE,
                            FailLoc);
            EXIT;
         END;
         CheckMemAvail := TRUE;
    END;

    (****************************)

{$IFDEF DEBUG}
TYPE
    EMA  = RECORD
               P : POINTER;
               S : LONGINT;
           END;
CONST
    OldHeapFunc    : POINTER = NIL;

VAR
    EatMeArray     : ARRAY[1..8] OF EMA;

    (****************************)

    FUNCTION MakePtr(H,L:WORD):POINTER;
    BEGIN
        MakePtr := LongToPtr(MakeLongInt(H, L));
    END;

    (****************************)

    {special heap error function that logs all heap allocations }
    {from either getmem or new                                  }
    FUNCTION KHeapFunc(Size : Word) : Integer; FAR;
    TYPE
        OS = RECORD
                 O : Word;
                 S : Word;
             END;

    VAR
        X : POINTER;
        {$IFDEF HeapDEBUG}
        S : LONGINT;
        {$ENDIF}
    BEGIN
        {$IFDEF Heap6}
        {$IFDEF HeapDEBUG}
        X := POINTER(Pointer(LONGINT(@Size)+2)^);
        S := PtrDiff(HeapPtr, X);

        {This is to trap specific heap allocations during debug}
        IF PtrDiff(X, MakePtr($6ead, $0000)) = 0 THEN
            X := NIL;

        HeapWalk('HeapFunc alloc: '+ Long2Str(S), X);
        {$ENDIF}
        IF Size = 0 THEN
            KHeapFunc := 2
        ELSE
        {$ENDIF}
            KHeapFunc := 1;
    END;

    (****************************)

    PROCEDURE SetKHeapFunc;
    BEGIN
        OldHeapFunc := HeapError;
        HeapError := @KHeapFunc;
    END;

    (****************************)

    PROCEDURE RestoreOldHeapFunc;
    BEGIN
        IF OldHeapFunc <> NIL THEN
            HeapError := OldHeapFunc;
        OldHeapFunc := NIL;
    END;

    (****************************)

    {- eat up all but MemToLeave bytes of the heap}
    PROCEDURE EatMe(MemToLeave:LONGINT);
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
        I : WORD;
    BEGIN
        I := 1;
        WHILE EatMeArray[I].P <> NIL DO BEGIN
            FreeMemCheck(EatMeArray[I].P, EatMeArray[I].S);
            INC(I);
        END;
    END;

    (****************************)

    {debug proc to detect memory leaks}
    {put Iam() call in P parameter to save map address of MemFree line}
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
        Strg := PAD(Loc, 26) + ': ' +
                PAD(Long2Str(MEMAVAIL), 8) +
                PAD(Long2Str(MAXAVAIL), 8) +
                PAD(Long2Str(MEMAVAIL - MA), 8) +
                PAD(Long2Str(MAXAVAIL - MX), 8) +
                HexPtr(P);

        WRITELN(F, Strg);
        MA := MEMAVAIL;
        MX := MAXAVAIL;
        CLOSE(F);
    END;

    (****************************)

    function PtrDiff(H, L : Pointer) : LongInt;
    {-Return the number of bytes between H^ and L^. H is the higher address}
    TYPE
        SegOfs = record
                     O,
                     S : Word;
                 end;
    var
        High : SegOfs absolute H;
        Low : SegOfs absolute L;
    begin
        PtrDiff := (LongInt(High.S) shl 4+High.O)-(LongInt(Low.S) shl 4+Low.O);
    end;

    (****************************)

    TYPE
        PFreeRec = ^TFreeRec;
        TFreeRec = RECORD
                       Next : PFreeRec;
                       Size : POINTER;
                   END;
        PtrRec   = RECORD
                       Lo,
                       Hi   : WORD;
                   END;
        BlockRec = RECORD
                       Loc : POINTER;
                       Size: LONGINT;
                       Used: BOOLEAN;
                   END;
        BlockArray = ARRAY[1..500] OF BlockRec;

    (****************************)

    {do a bubble sort of a pointer list array}
    PROCEDURE SortArray(VAR A: BlockArray; NumBlocks : WORD);
    VAR
        I : WORD;
        Done : BOOLEAN;
    BEGIN
        REPEAT
            Done := TRUE;
            FOR I := 1 TO NumBlocks-1 DO BEGIN
                IF PtrDiff(A[I].Loc, A[I+1].Loc) > 0 THEN BEGIN
                    ExchangeStructs(A[I], A[I+1], SIZEOF(BlockRec));
                    Done := FALSE;
                END;
            END;
        UNTIL Done;
    END;

    (****************************)
{$IFNDEF DPMI}
    {HeapWalk dumps the addresses of all allocated and free heap blocks}
    {Unfortunately, due to Pascal's management of the heap, individual }
    {heap allocations are concatenated into adjacent blocks.  You can  }
    {hook this function into a HeapFunc function to view all heap      }
    {allocations as they "go by"                                       }

    {Gozintas:  Note - line of text to identify log entry              }
    {           P    - Usually the map address of the calling context  }
    {                  use UTIAM:Iam() for this parameter               }

    PROCEDURE HeapWalk(Note:STRING; P : POINTER);
    CONST
        MA             : LONGINT = 0;
        MX             : LONGINT = 0;
        BreakPtStrg    = '7463';
    VAR
        F : TEXT;
        LastBlock,
        Runner : PFreeRec;
        I,
        BlockAppend ,
        NumBlocks : WORD;
        ListArray : BlockArray;
        DebugBreak,
        FirstFree : BOOLEAN;
        Strg      : STRING[80];
    BEGIN
        FILLCHAR(ListArray, SIZEOF(ListArray), #0);
        DebugBreak := FALSE;
        ASSIGN(F, 'junk.tmp');

        IF MA = 0 THEN
            REWRITE(F)
        ELSE BEGIN
            {$I-}
            APPEND(F);
            IF IORESULT <> 0 THEN
                REWRITE(F);
        END;

        Strg := 'HeapWalk '+HexPtr(P) + '  ';
        WRITE(F, Strg);
        WRITELN(F, TimeDateNow);
        WRITELN(F, Pad(Note, 26));

        (*

        {Un-Rem this to make a debug trap on a certain heap address.}
        {Change address in quotes to match the offending address and}
        {put a breakpoint on the "Note := ''" line                  }

        *)
        IF POS(BreakPtStrg, Note) > 0 THEN
            DebugBreak:=TRUE;
        IF POS(BreakPtStrg, Strg) > 0 THEN
            DebugBreak:=TRUE;
        WRITELN(F);
        WRITELN(F, '    avail   max     deltaAV deltaMax');
        Strg := '    ' +
                PAD(Long2Str(MEMAVAIL), 8) +
                PAD(Long2Str(MAXAVAIL), 8) +
                PAD(Long2Str(MEMAVAIL - MA), 8) +
                PAD(Long2Str(MAXAVAIL - MX), 8);

        WRITELN(F, Strg);
        MA := MEMAVAIL;
        MX := MAXAVAIL;
        WRITELN(F);

        NumBlocks := 0;
        IF PtrDiff(FreeList, HeapOrg) > 0 THEN BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := HeapOrg;
            ListArray[NumBlocks].Size := PtrDiff(FreeList, HeapOrg);
            ListArray[NumBlocks].Used := TRUE;
        END;

        Runner := FreeList;
        FirstFree := TRUE;
        {get all free blocks}
        WHILE Runner <> HeapPtr DO BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := Runner;
            ListArray[NumBlocks].Size:= LONGINT(PtrRec(Runner^.Size).Hi) * 16 + PtrRec(Runner^.Size).Lo;
            ListArray[NumBlocks].Used := FALSE;
            Runner := Runner^.Next;
            IF NumBlocks > 300 THEN
                BREAK;
        END;

        {get heap free at top of heap}
        IF PtrDiff(HeapEnd, HeapPtr) > 0 THEN BEGIN
            INC(NumBlocks);
            ListArray[NumBlocks].Loc := HeapPtr;
            ListArray[NumBlocks].Size:= PtrDiff(HeapEnd, HeapPtr);
            ListArray[NumBlocks].Used := FALSE;
        END;

        SortArray(ListArray, NumBlocks);

        {find holes between free blocks}
        BlockAppend := NumBlocks;
        FOR I := 1 TO NumBlocks DO BEGIN
            IF PtrDiff(ListArray[I+1].Loc, ListArray[I].Loc) > ListArray[I].Size THEN BEGIN
                INC(BlockAppend);
                ListArray[BlockAppend].Loc := AddLongToPtr(ListArray[I].Loc, ListArray[I].Size);
                ListArray[BlockAppend].Size := PtrDiff(ListArray[I+1].Loc, ListArray[BlockAppend].Loc)+1;
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
                        Pad(HexPtr(AddLongToPtr(ListArray[I].Loc, ListArray[I].Size-1)),10) +
                        Pad(Long2Str(ListArray[I].Size), 10),
                        'USED')
            ELSE
                WRITELN(F,
                        '    ' +
                        Pad(HexPtr(ListArray[I].Loc), 10) +
                        Pad(HexPtr(AddLongToPtr(ListArray[I].Loc, ListArray[I].Size-1)),10) +
                        Pad(Long2Str(ListArray[I].Size), 10),
                        'FREE');


        WRITELN(F, CharStr('=', 15));
        CLOSE(F);
        IF DebugBreak THEN
            Note := '';

    END;
{$ENDIF}
    (****************************)

    PROCEDURE EraseFile(FName:PathStr);
    VAR
        F : FILE;
        Res : WORD;
    BEGIN
        {$I-}
        ASSIGN(F, FName);
        ERASE(F);
        Res := IORESULT;
        {$I+}
    END;

{$ENDIF}

    (****************************)

    {unit initialization}
BEGIN
    ProgramRevision := '';
    OldExitProc := EXITPROC;
    EXITPROC := @UErrorExit;
    {$IFDEF HeapDEBUG}
    EraseFile('JUNK.TMP');
    {$ENDIF}
END.
{of unit uerror}
(****************************************************************************)
(****************************************************************************)


