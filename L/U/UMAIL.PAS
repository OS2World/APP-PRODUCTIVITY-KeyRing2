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
{$A-,V-,O+,F+,X+}
{--------------------------------------------------------}

UNIT UMAIL;
{$I NDEFINE.INC}
{$D+,L+}

INTERFACE
USES
    QHdrRec;

VAR
    NeedsMsgSweep  : BOOLEAN;

    {check for existance of mailbox - dual mode}
FUNCTION CheckMailQueue(Name : STRING) : BOOLEAN;

    { True if mail in box, call infrequently }
FUNCTION CheckMailBox(VAR Messages : INTEGER) : BOOLEAN;

FUNCTION GetNumMsgs(Path : STRING) : WORD;

    { Quick check for mail }
FUNCTION MailInBox : BOOLEAN;

    {dunsel...}
PROCEDURE FormatMailDate(Day : WORD; Month : WORD; Year : WORD;
                         H, M           : WORD;
                         VAR OutDate    : STRING);

PROCEDURE InitMailDeliveryMode;

    {make error logs into messages and send them to the designated person}
FUNCTION XferLogsViaMail:BOOLEAN;

    (******************************************************************************)

IMPLEMENTATION
USES
    Dos,
    MAATTACH,
    MAEDIT,
    MAFTREE,
    UTIAM,
    MAPICK1,
    MAMHS,
    MAMSGNOD,
    MANEN,
    MAPATH,
    SECrypt,
    SECRPTLO,
    SEQUERY,
    SESECURE,
    UTtimdat,
    NetSema,
    UTOOINI,
    OpCrt,
    OpDate,
    OpDos,
    OpMouse,
    OpRoot,
    OpString,
    QDrives,
    QUpTime,
    SHARE,
    UERROR,
    UDIALOG,
    UColors,
    UFkey,
    UGLOBAL,
    ULIB,
    UMsg,
    UWindow;

    (******************************************************************************)

TYPE
    UserName       = STRING[12];


CONST
    DefaultName    : UserName = 'NEN';


    DoErase        = TRUE;
    DontErase      = FALSE;


    MailBoxLoaded  : BOOLEAN = FALSE;
    OutBasketLoaded : BOOLEAN = FALSE;
    FilingCabinetLoaded : BOOLEAN = FALSE;

    (******************************************************************************)

    FUNCTION SetMailDeliveryMode(ModeStrg : STRING) : DeliveryModeT;
    BEGIN
        IF POS('MHS', ModeStrg) > 0 THEN
            SetMailDeliveryMode := EMHSMAIL
        ELSE
            SetMailDeliveryMode := ENENMAIL
    END;

    {---------------------------------------------------}


    FUNCTION ReadIni(VAR DeliveryMode : DeliveryModeT) : BOOLEAN;
    VAR
        Path           : PathStr;
        ModeStrg       : STRING;
        IRP            : IniReaderP;
    BEGIN
        ReadIni := FALSE;

        {First read system defaults, if possible}
        Path := AddBackSlash(NEN^.SysDir) + 'NEN.INI';
        ModeStrg := 'NEN';

        NEW(IRP, Init(Path, 512));

        IF IRP <> NIL THEN BEGIN
            IF IRP^.SectionExists('MAIL') THEN BEGIN
                NEN^.MailUsersDir := IRP^.FindKeyStringSection('MHS', 'USERSDIR', 'MAIL', 'I:\MHS');
                NEN^.MailStoreDir := IRP^.FindKeyStringSection('MHS', 'STOREDIR', 'MAIL', 'I:\MAIL');
                ModeStrg := StUpCase(IRP^.FindKeyStringSection('DELIVERY', 'MODE', 'MAIL', ModeStrg));
                DeliveryMode := SetMailDeliveryMode(ModeStrg);
                ReadIni := TRUE
            END
            ELSE BEGIN
                {No mail section in NEN.INI so append one}
                DISPOSE(IRP, Done);
                DispErrorDeluxe('No [MAIL] section in NEN.INI', 'Defaulting to MHS mode!', TRUE, Iam);
            END;
        END;

        IF IRP <> NIL THEN
            DISPOSE(IRP, Done);

        {Now read user params, if they exist }
        Path := AddBackSlash(NEN^.SysDir) + ForceExtension(GetUserName, 'INI');


        NEW(IRP, Init(Path, 512));

        IF IRP = NIL THEN
            EXIT;

        IF IRP^.SectionExists('MAIL') THEN BEGIN
            NEN^.MailUsersDir := IRP^.FindKeyStringSection('MHS', 'USERSDIR', 'MAIL', NEN^.MailUsersDir);
            NEN^.MailStoreDir := IRP^.FindKeyStringSection('MHS', 'STOREDIR', 'MAIL', NEN^.MailStoreDir);
            ModeStrg := StUpCase(IRP^.FindKeyStringSection('DELIVERY', 'MODE', 'MAIL', ModeStrg));
            DeliveryMode := SetMailDeliveryMode(ModeStrg);
            DISPOSE(IRP, Done);
            ReadIni := TRUE;
            EXIT;
        END
        ELSE BEGIN
            DispErrorDeluxe(SysMsg(2288) {'Invalid '} + Path, SysMsg(2289) {'Missing [MAIL] section'} , TRUE, Iam);
        END;

        DISPOSE(IRP, Done);

    END;

    {-------------------------------------------------------}


    PROCEDURE InitMailDeliveryMode;
    VAR
        DeliveryMode   : DeliveryModeT;
    BEGIN
        IF GetPathP <> NIL THEN
            DISPOSE(GetPathP, Done);

        GetPathP := NIL;

        IF NOT ReadIni(DeliveryMode) THEN BEGIN
            DispErrorDeluxe('Problem reading INI files', 'GetNumMsgs', TRUE, Iam);
            CloseFKeyDisplay;
            EXIT;
        END;

        {init the MailPathObj}
        CASE DeliveryMode OF
            EMHSMAIL :
                GetPathP := NEW(MHSMailPathObjP, Init);
            ENENMAIL :
                GetPathP := NEW(NENMailPathObjP, Init);
        END;                      {CASE}
    END;

    (******************************************************************************)


    {- Look for un-read message headers}
    FUNCTION GetNumMsgs(Path : STRING) : WORD;
    VAR
        Count          : WORD;
        FR             : SearchRec;
        DM             : DeliveryModeT;
        Ext            : STRING[3];
    BEGIN
        Count := 0;

        IF GetPathP = NIL THEN
            InitMailDeliveryMode;

        DM := GetPathP^.GetDeliveryMode;

        CASE DM OF
            EMHSMAIL :
                FINDFIRST(AddBackSlash(Path) + '*.', ReadOnly+Archive+Hidden, FR);
            ENENMAIL :
                FINDFIRST(AddBackSlash(Path) + '*.SMF', ReadOnly+Archive+Hidden, FR);
        END;

        WHILE DOSERROR = 0 DO BEGIN
            IF (FR.Name[1] <> '.') AND ((FR.Attr AND Hidden) = 0) THEN BEGIN
                CASE DM OF
                EMHSMAIL :
                    INC(Count);
                ENENMAIL :
                    BEGIN
                        FILLCHAR(Ext, 4, #0);
                        Ext := JustExtension(FR.Name);
                        CASE Ext[3] OF
                        'F',
                        'P':
                            INC(Count);
                        END;
                    END;
                END;
            END;
            FindNext(FR);
        END;
        GetNumMsgs := Count;
    END;

    {---------------------------------------------------}

    { Checks for existance of User mail directory       }

    FUNCTION CheckMailQueue(Name : STRING) : BOOLEAN;
    VAR
        FR             : SearchRec;
        Strg           : PathStr;
    BEGIN
        CheckMailQueue := FALSE;

        IF GetPathP = NIL THEN
            InitMailDeliveryMode;

        Strg := AddBackSlash(GetPathP^.AllUsersPath);

        FINDFIRST(Strg + '*.', Directory, FR);
        REPEAT
            IF FR.Name = Name THEN BEGIN
                CheckMailQueue := TRUE;
                EXIT;
            END;
            FindNext(FR);
        UNTIL DOSERROR <> 0;
    END;

    {---------------------------------------------------}


    { Check for mail in mail box, returns # of messages }

    FUNCTION CheckMailBox(VAR Messages : INTEGER) : BOOLEAN;
    VAR
        Err            : INTEGER;
    BEGIN
        Messages := 0;

        IF GetPathP = NIL THEN
            InitMailDeliveryMode;

        CheckMailBox := FALSE;

        IF NOT CheckMailQueue(GetUserName) THEN BEGIN
            {$I-}
            OpenMessage(SysMsg(000970) {'Creating '} + NEN^.PrivateDir + '\' + GetUserName, Cyan_Scheme);
            MKDIR(NEN^.PrivateDir + '\' + GetUserName);
            Delay(200);
            CloseMessage;
            IF IORESULT <> 0 THEN
                EXIT;
            MKDIR(NEN^.PrivateDir + '\' + GetUserName + '\IN');
            IF IORESULT <> 0 THEN
                EXIT;
            MKDIR(NEN^.PrivateDir + '\' + GetUserName + '\CABINET');
            IF IORESULT <> 0 THEN
                EXIT;
            MKDIR(NEN^.PrivateDir + '\' + GetUserName + '\PRIVATE');
            IF IORESULT <> 0 THEN
                EXIT;
            MailBoxLoaded := FALSE;
            {$I+}
        END;
        Messages := GetNumMsgs(GetPathP^.UserRxPath);
        QUpTime.Mail := Messages <> 0;
        CheckMailBox := Messages <> 0;
    END;

    {---------------------------------------------------}
    { Quick Check for mail in mail box, True if Any file}

    FUNCTION MailInBox : BOOLEAN;
    VAR
        Err            : INTEGER;
        S              : SearchRec;
    BEGIN
        IF NOT CheckMailQueue(GetUserName) THEN BEGIN
            MailInBox := FALSE;
            EXIT;
        END;

        IF GetPathP = NIL THEN
            InitMailDeliveryMode;

        CASE GetPathP^.GetDeliveryMode OF
            EMHSMAIL :
                FINDFIRST(AddBackSlash(GetPathP^.UserRxPath) + '*.', ReadOnly+Archive+Hidden, S);
            ENENMAIL :
                FINDFIRST(AddBackSlash(GetPathP^.UserRxPath) + '*.SMF', ReadOnly+Archive+Hidden, S);
        END;

        NeedsMsgSweep := DOSERROR = 0;

        IF NeedsMsgSweep THEN BEGIN
            WHILE DOSERROR = 0 DO {clear novell directory table}
                FindNext(S);
        END;

        MailInBox := NeedsMsgSweep;
    END;

    {---------------------------------------------------}

    {this is obsolete as far as I am concerned... KGM 12-93}
    {ever hear of OpDate or TPDate or functions that return strings?}
    PROCEDURE FormatMailDate(Day            : WORD;
                             Month          : WORD;
                             Year           : WORD;
                             H, M           : WORD;
                             VAR OutDate    : STRING);
    BEGIN
        OutDate := LeftPadCh(Long2Str(Day), '0', 2) + '-' +
                   COPY(MonthString[Month], 1, 3) + '-' +
                   Long2Str(Year MOD 100) + ' ' +
                   LeftPadCh(Long2Str(H), '0', 2) + ':' +
                   LeftPadCh(Long2Str(M), '0', 2);
    END;

    {---------------------------------------------------}

    {- a helper function to return the size and date of a log file}
    FUNCTION GetLogInfo(Name : PathStr; VAR Age : DateTimeRec; VAR Size : LONGINT) : BOOLEAN;
    VAR
        F              : FILE;
        T              : LONGINT;
        R              : WORD;
    BEGIN
        GetLogInfo := FALSE;
        Age.D := BadDate;
        Age.T := 0;
        ASSIGN(F, Name);
        {$I-}
        RESET(F, 1);
        GetFTime(F, T);
        R := IORESULT;
        IF R <> 0 THEN
            EXIT;
        {$I+}
        UnpackDOStime(T, Age.T, Age.D);
        Size := FILESIZE(F);
        CLOSE(F);
        GetLogInfo := TRUE;
    END;

    {---------------------------------------------------}

    {- if enabled, send all ERR files to designated person, then}
    {delete the ERR files                                       }
    FUNCTION XferLogsViaMail:BOOLEAN;
    VAR
        LUTP           : FileLUTP;
        LastPath       : PathStr;
        MNP            : MsgNodeP;
        FR             : SearchRec;
        Now,
        Age            : DateTimeRec;
        Result,
        Days,
        LogMaxAge      : WORD;
        Secs,
        Size,
        SemaHandle,
        LogMaxSize     : LONGINT;
        Strg,
        SendTo         : STRING;
        F              : FILE;
        TF             : TEXT;
        NumberWSOpen   : BYTE;
        IRP            : IniReaderP;

        PROCEDURE CleanUp;
        BEGIN
            IF LUTP <> NIL THEN
                DISPOSE(LUTP, Done);
            LUTP := NIL;
            IF MNP <> NIL THEN
                DISPOSE(MNP, Done);
            MNP := NIL;

            ChDir(LastPath);
        END;

        FUNCTION ReadIni : BOOLEAN;
        VAR
            Path           : PathStr;
            ModeStrg       : STRING;
        BEGIN
            ReadIni := FALSE;
            SendTo := 'NONE';
            {First read system defaults, if possible}
            Path := AddBackSlash(NEN^.SysDir) + 'NEN.INI';
            NEW(IRP, Init(Path, 512));
            IF IRP <> NIL THEN BEGIN
                SendTo := IRP^.FindKeyStringSection('ERRLOG', 'SENDTO', 'MAIL', 'NONE');
                LogMaxSize := IRP^.FindKeyValueSection('ERRLOG', 'SIZETHRESHOLD', 'MAIL', 500);
                LogMaxAge := IRP^.FindKeyValueSection('ERRLOG', 'AGETHRESHOLD', 'MAIL', 5);
                ReadIni := TRUE;
                DISPOSE(IRP, Done);
            END
            ELSE
                {No mail section in NEN.INI so append one}
                DispErrorDeluxe('No [MAIL] section in NEN.INI', 'Defaulting to MHS mode!', TRUE, Iam);
        END;
    BEGIN
        XferLogsViaMail := FALSE;

        GetDir(0, LastPath);

        MNP := NIL;
        LUTP := NIL;

        IF GetPathP = NIL THEN
            InitMailDeliveryMode;
        IF GetPathP = NIL THEN
            EXIT;

        IF NOT ReadIni THEN
            EXIT;

        IF SendTo = 'NONE' THEN BEGIN
            XferLogsViaMail := TRUE;
            EXIT;
        END;

        NEW(LUTP, Init);
        IF LUTP = NIL THEN
            EXIT;

        DTRNow(Now);

        {$I-}
        ChDir(NEN^.LogFileDir);
        {$I+}
        Result := IORESULT;
        IF Result <> 0 THEN BEGIN
            CleanUp;
            DispErrorDeluxe('Failure in ErrorLog CHDIR to:', NEN^.LogFileDir, TRUE, Iam);
            EXIT;
        END;
        FINDFIRST('*.ERR', ReadOnly+Archive+Hidden, FR);
        WHILE DOSERROR = 0 DO BEGIN
            IF GetLogInfo(AddBackSlash(NEN^.LogFileDir) + FR.Name, Age, Size) THEN BEGIN
                DateTimeDiff(Age, Now, Days, Secs);
                IF (Days > LogMaxAge) OR (Size > LogMaxSize) THEN BEGIN
                    Strg := 'Automatic Log Msg ';
                    IF SYS <> NIL THEN
                        Strg := Strg + SYS^.StationId;
                    CASE GetPathP^.GetDeliveryMode OF
                        EMHSMAIL :
                            MNP := NEW(MHSMsgNodeP, InitAutoSend(GetUserName, Strg));
                        ENENMAIL :
                            MNP := NEW(NENMsgNodeP, InitAutoSend(GetUserName, Strg));
                    END;
                    IF MNP <> NIL THEN BEGIN
                        IF NOT MNP^.AddToUser(SendTo) THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem adding user', 'XferLogsViaMail', TRUE, Iam);
                            EXIT;
                        END;
                        IF NOT MNP^.AddLineCRLF('This is a NewsMaker Systems automatically generated message.') THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                            EXIT;
                        END;
                        IF Size > MailBufSize - 600 THEN BEGIN
                            IF NOT MNP^.AddLineCRLF('Please review the attached Error log file.') THEN BEGIN
                                CleanUp;
                                DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                                EXIT;
                            END;
                        END;
                        IF NOT MNP^.AddLineCRLF(' ') THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                            EXIT;
                        END;
                        IF NOT MNP^.AddLineCRLF(' ') THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                            EXIT;
                        END;
                        IF OpenSemaphore(Sys^.SemName, 0, NumberWSOpen, SemaHandle) THEN BEGIN
                            IF NOT MNP^.AddLineCRLF('WS Open: ' + Long2Str(NumberWSOpen)) THEN BEGIN
                                CleanUp;
                                DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                                EXIT;
                            END;
                        END;
                        IF NOT MNP^.AddLineCRLF('File Age: ' + Long2Str(Days)) THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                        EXIT;
                        END;
                        IF NOT MNP^.AddLineCRLF('File Size: ' + Long2Str(Size)) THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                            EXIT;
                        END;
                        IF NOT MNP^.AddLineCRLF(' ') THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                            EXIT;
                        END;
                        IF NOT MNP^.AddLineCRLF('KGM 1-94') THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem adding line', 'XferLogsViaMail', TRUE, Iam);
                            EXIT;
                        END;
                        IF Size > MailBufSize - 600 THEN BEGIN
                            {big ERR file, so make it a message attachment}
                            IF NOT MNP^.AddAttachment(AddBackSlash(NEN^.LogFileDir) + FR.Name, ETEXT, LUTP) THEN BEGIN
                                CleanUp;
                                DispErrorDeluxe('problem adding attachment', 'XferLogsViaMail', TRUE, Iam);
                                EXIT;
                            END;
                        END
                        ELSE BEGIN
                            {small ERR file, so make it part of the message}
                            ASSIGN(TF, AddBackSlash(NEN^.LogFileDir) + FR.Name);

                            {$I-}
                            RESET(TF);
                            Result := IORESULT;
                            {$I-}

                            IF Result <> 0 THEN BEGIN
                                CleanUp;
                                DispErrorDeluxe('problem opening log file', 'XferLogsViaMail', TRUE, Iam);
                                EXIT;
                            END;

                            IF NOT MNP^.AddLineCRLF(CharStr('=',10) + FR.Name + CharStr('=',10)) THEN BEGIN
                                CleanUp;
                                DispErrorDeluxe('problem adding log line', 'XferLogsViaMail', TRUE, Iam);
                                EXIT;
                            END;

                            WHILE NOT EOF(TF) DO BEGIN
                                READLN(TF, Strg);
                                IF NOT MNP^.AddLineCRLF(Strg) THEN BEGIN
                                    CleanUp;
                                    DispErrorDeluxe('problem adding log line', 'XferLogsViaMail', TRUE, Iam);
                                    EXIT;
                                END;
                            END;
                            IF NOT MNP^.AddLineCRLF(CharStr('=',10) +
                                                    ' End of ' +
                                                    FR.Name +
                                                    ' ' +
                                                    CharStr('=',10)) THEN BEGIN
                                CleanUp;
                                DispErrorDeluxe('problem adding log line', 'XferLogsViaMail', TRUE, Iam);
                                EXIT;
                            END;
                            CLOSE(TF);
                        END;
                        {send unsecured plain text message}
                        IF NOT MNP^.AutoSend(ENONE, '') THEN BEGIN
                            CleanUp;
                            DispErrorDeluxe('problem sending msg', 'XferLogsViaMail', TRUE, Iam);
                            EXIT;
                        END;
                        DISPOSE(MNP, Done);
                        MNP := NIL;
                        ASSIGN(F, AddBackSlash(NEN^.LogFileDir) + FR.Name);
                        Result := IORESULT;
                        {$I-}
                        System.ERASE(F);
                        Result := IORESULT;
                        {$I+}
                    END;          {mnp <> nil}
                END;              {mail the log?}
            END;                  {successful open of log}
            FindNext(FR);
        END;                      {found a log to open}
        CleanUp;
        XferLogsViaMail := TRUE;
    END;                          {PROCEDURE XferLogsViaMail}

    {---------------------------------------------------}

BEGIN
    NeedsMsgSweep := FALSE;
END.

{---------------------------------------------------}
{---------------------------------------------------}
