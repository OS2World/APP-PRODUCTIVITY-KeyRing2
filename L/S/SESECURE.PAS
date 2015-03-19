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
* This object provides security check methods, using a dongle or
* Novell server ID as the hardware key. It compares it against a list of
* possible server/dongle IDs found in the encrypted key file.
*
* The Security object is only capable of reading a key.  See other units
* for key creation methods.
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
UNIT SESECURE;

    {$A+,B-,D+,E+,F-,G+,I-,L+,N-,O+,P-,Q-,T-,V-,X+,Y+}

    (***************************)

INTERFACE

USES
    Dos,
    SECONT,
    SEQUERY,
    OpDate;

FUNCTION TimeDateNow : STRING;

CONST
    SEDatePict     = 'dd nnn yyyy';
    SETimePict     = ' hh:mm:ss';

TYPE
    DATERTN        = (DateOk, DATEWARN, DATEFAIL);

    SecurityP      = ^Security;
    Security       = OBJECT(SecQuery)
                         CONSTRUCTOR InitPrim(FName          : PathStr;
                                              Prod           : STRING;
                                              ExeD,
                                              ExeM,
                                              ExeY           : WORD;
                                              WarnWindow,
                                              AllowRefresh   : BOOLEAN);
                         CONSTRUCTOR Init(FName          : PathStr;
                                          Prod           : STRING;
                                          ExeD,
                                          ExeM,
                                          ExeY           : WORD;
                                          WarnWindow,
                                          AllowRefresh   : BOOLEAN);
                         CONSTRUCTOR InitForChallenge(FName          : PathStr;
                                                      Prod           : STRING;
                                                      ExeD,
                                                      ExeM,
                                                      ExeY           : WORD;
                                                      WarnWindow,
                                                      AllowRefresh   : BOOLEAN);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION SecChk : SecStatT;
                         FUNCTION GetStationLoc(Instance : BYTE; VAR Strg : STRING) : BOOLEAN;
                         FUNCTION GetStationID(Instance : BYTE; VAR Strg : STRING) : BOOLEAN;
                         FUNCTION GetAllowedWSCount : STRING;
                         FUNCTION GetNumRunningWS : WORD;
                         FUNCTION GetLicense : STRING;
                         FUNCTION GetExeDate(VAR Dtr : DateTimeRec) : BOOLEAN; VIRTUAL;
                         PROCEDURE ManualRefresh;
                         PROCEDURE GenReplyToChallenge;
                         FUNCTION IsLoggedIn : BOOLEAN;

                     PRIVATE

                         WarnDays,
                         KeySize        : WORD;
                         MyLock         : OpDate.Date;
                         AllowDeadBattery,
                         KeyFound,
                         AllowWarnings,
                         HasLocalDisk,
                         UsedMasterKey,
                         DoKeyRecharge,
                         AlreadyWarned  : BOOLEAN;
                         Comment        : STRING[80];

                         FUNCTION ReadNetID : LONGINT;
                         FUNCTION ReadDongID : LONGINT;
                         FUNCTION CompareID(Hk : LONGINT; VAR CNP : ContextNodeP) : BOOLEAN;
                         FUNCTION DropDeadExpired(D : STRING) : DATERTN;
                         FUNCTION RechargeKey : BOOLEAN;
                         FUNCTION LockExpired(ExeDate, LockDate : STRING) : DATERTN;
                         FUNCTION ChkDateLock(CNP : ContextNodeP) : DATERTN;
                         FUNCTION ChkDropDead(CNP : ContextNodeP) : DATERTN;
                         PROCEDURE PreenDate(VAR Strg : STRING);
                         FUNCTION CheckDates(CurBranchP : ContextNodeP) : SecStatT;
                         FUNCTION CheckBattery : SecStatT;
                     END;

    (***************************)

IMPLEMENTATION

USES
    UTIAM,
    SECRPTLO,
    UTTIMDAT,
    OpCmd,
    OpConst,
    OpCrt,
    OpDos,
    OpRoot,
    OpString,
    NetSema,
    Nwbase,
    QDrive2,
    QHdrRec,
    QNovell,
    SECHALNG,
    SECONST,
    SEDONGLE,
    Strings,
    UDIALOG,
    UERROR;

    (***************************)

    {$I SESTR3.INC}
    {$I SESTR4.INC}
    {$I SESTR5.INC}
    {$I SESTR6.INC}
    {$I SESTR7.INC}
    {$I SESTR8.INC}
    {$I SESTR9.INC}
    {$I SESTR10.INC}
TYPE
    DTRP           = ^DateTimeRec;

    (***************************)

    {-Return string containing current time and date }

    FUNCTION TimeDateNow : STRING;
    BEGIN
        TimeDateNow := DateToDateString(SEDatePict, Today) +
                       CurrentTimeString(SETimePict)
    END;                          {of func TimeDateNow}

    (***************************)
    {$IFDEF SMALLZ}
TYPE
    DateTimeRec    = RECORD
                         D,
                         T              : LONGINT;
                     END;
{$ENDIF}
    {-Translates a Date-Time string into a pointer to an initialized DateTimeRec}
    FUNCTION TDStr2DTRP(Td : STRING) : DTRP;
    CONST
        Dtr            : DateTimeRec = (D : BadDate; T : 0);
    BEGIN
        Dtr.D := DateStringToDate(SEDatePict, COPY(Td, 1, LENGTH(SEDatePict)));
        Dtr.T := TimeStringToTime(SETimePict, COPY(Td, LENGTH(SEDatePict) + 1, $FF));
        TDStr2DTRP := @Dtr;
    END;

    (***************************)
    {-Translates a Date-Time string into a pointer to an initialized DateTimeRec}
    PROCEDURE TDStr2DTR(Td : STRING; VAR Dtr : DateTimeRec);
    BEGIN
        Dtr.D := DateStringToDate(SEDatePict, COPY(Td, 1, LENGTH(SEDatePict)));
        Dtr.T := TimeStringToTime(SETimePict, COPY(Td, LENGTH(SEDatePict) + 1, $FF));
    END;

    (***************************)

    {refresh the local key with the contents of the network key}
    FUNCTION Security.RechargeKey : BOOLEAN;
    TYPE
        BufArray       = ARRAY[1..$FFFF] OF BYTE;
        BufPtr         = ^BufArray;
    VAR
        TTCP           : TextCryptPtr;
        fi,
        fo             : FILE;
        Strg           : STRING;
        Buff           : BufPtr;
        Tries,
        Result         : WORD;
        BufSize        : LONGINT;
    BEGIN
        RechargeKey := FALSE;

        IF NOT HasLocalDisk THEN
            EXIT;

        {open a temp file and use it for the new local key}
        NEW(TTCP, WriteInit(DecodeStrg(SECON44S, {C:\~~~.~~~}
                                       SECON44N,
                                       SECON44P), {Sec file name}
                            DecodeStrg(SECON18S, {NEN-ENIGMA}
                                       SECON18N,
                                       SECON18P),
                            TimeDateNow, {public key}
                            DecodeStrg(SECON29S, {cIMa GAlINa}
                                       SECON29N,
                                       SECON29P),
                            KeySize, {length of encryption key}
                            4927422,
                            Comment)); {sec file version number}
        IF TTCP = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            EXIT;
        END;

        {copy NTree to local key file, except for battery block}
        IF NOT TraverseCopy(TTCP, GetLabelNC(EBATT)) THEN
            EXIT;


        TTCP^.PutLine(GetLabelNC(EBATT));
        TTCP^.PutLine('{');
        IF DoKeyRecharge THEN BEGIN
            {Recharge the key}
            TTCP^.PutLine(CharStr(' ', 4) + GetLabelNC(ERCHRG));
            TTCP^.PutLine(CharStr(' ', 4) + '{');
            TTCP^.PutLine(CharStr(' ', 8) + '= ' + TimeDateNow);
            TTCP^.PutLine(CharStr(' ', 4) + '}');
        END
        ELSE BEGIN
            {get old charge date}
            IF NOT GetStringVal(GetLabel(EBATT) + GetLabel(ERCHRG), 1, Strg) THEN BEGIN
                InitStatus := epFatal + ecBadFormat;
                EXIT;
            END;

            {retain old charge date}
            TTCP^.PutLine(CharStr(' ', 4) + GetLabelNC(ERCHRG));
            TTCP^.PutLine(CharStr(' ', 4) + '{');
            TTCP^.PutLine(CharStr(' ', 8) + '= ' + Strg);
            TTCP^.PutLine(CharStr(' ', 4) + '}');
        END;
        {update the last-used timedate}
        TTCP^.PutLine(CharStr(' ', 4) + GetLabelNC(ELASTUSE));
        TTCP^.PutLine(CharStr(' ', 4) + '{');
        TTCP^.PutLine(CharStr(' ', 8) + '= ' + TimeDateNow);
        TTCP^.PutLine(CharStr(' ', 4) + '}');
        TTCP^.PutLine('}');

        DISPOSE(TTCP, Done);
        TTCP := NIL;
        {$I+}

        BufSize := MAXAVAIL - $1ff;
        IF BufSize < 0 THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            EXIT;
        END;

        IF BufSize > $1000 THEN
            BufSize := $1000;

        GetMemCheck(Buff, BufSize);
        IF Buff = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            EXIT;
        END;
        {C:\~~~.~~~}
        ASSIGN(fi, DecodeStrg(SECON44S, SECON44N, SECON44P));
        RESET(fi, 1);
        {NEN.KEY}
        ASSIGN(fo, 'C:\' + DecodeStrg(SECON43S, SECON43N, SECON43P));

        Tries := 0;
        REPEAT
            INC(Tries);
            {$I-}
            REWRITE(fo, 1);
            {$I+}
            InitStatus := IORESULT;
            IF InitStatus = 162 THEN BEGIN
                Sound(1000);
                Delay(50);
                NOSOUND;
                Delay(450);
            END;
        UNTIL (InitStatus = 0) OR (Tries > 30);

        IF InitStatus <> 0 THEN BEGIN
            CLOSE(fi);
            FreeMemCheck(Buff, BufSize);
            EXIT;
        END;

        REPEAT
            BLOCKREAD(fi, Buff^, BufSize, Result);
            BLOCKWRITE(fo, Buff^, Result, Result);
        UNTIL Result <> BufSize;

        FreeMemCheck(Buff, BufSize);
        Buff := NIL;
        CLOSE(fi);
        CLOSE(fo);

        ERASE(fi);
        RechargeKey := TRUE;
    END;

    (***************************)

    {-Opens the key file (Network or Local) and verifies its integrity      }
    { Conditionally refreshes the Local key                                 }

    CONSTRUCTOR Security.InitPrim(FName          : PathStr;
                                  Prod           : STRING;
                                  ExeD,
                                  ExeM,
                                  ExeY           : WORD;
                                  WarnWindow,
                                  AllowRefresh   : BOOLEAN);
    VAR
        I              : WORD;
        CNP1,
        CNP2           : ContextNodeP;
        Strg           : STRING;
    BEGIN
        KeyFound := TRUE;
        KeySize := $3000;
        MyLock := DMYtoDate(ExeD, ExeM, ExeY);
        AllowWarnings := WarnWindow;
        AlreadyWarned := FALSE;
        DoKeyRecharge := FALSE;
        UsedMasterKey := FALSE;

        HasLocalDisk := ExistFile('C:\AUTOEXEC.BAT') AND AllowRefresh;

        IF IsLoggedIn THEN BEGIN
            IF ExistFile(AddBackSlash(NEN^.SysDir) + FName) THEN BEGIN
                IF NOT SecQuery.Init(AddBackSlash(NEN^.SysDir) + FName,
                                     {NEN-ENIGMA}
                                     DecodeStrg(SECON18S, SECON18N, SECON18P),
                                     {cIMa GAlINa}
                                     DecodeStrg(SECON29S, SECON29N, SECON29P),
                                     Prod,
                                     KeySize,
                                     4927422,
                                     Comment) THEN
                    FAIL;
                UsedMasterKey := TRUE;
            END
            ELSE BEGIN
                IF NOT HasLocalDisk THEN BEGIN
                    InitStatus := epFatal + ecFileNotFound;
                    FAIL;
                END;
                IF NOT SecQuery.Init('C:\' + JustFileName(FName),
                                     {NEN-ENIGMA}
                                     DecodeStrg(SECON18S, SECON18N, SECON18P),
                                     {cIMa GAlINa}
                                     DecodeStrg(SECON29S, SECON29N, SECON29P),
                                     Prod,
                                     KeySize,
                                     4927422,
                                     Comment) THEN BEGIN
                    IF InitStatus <> epFatal + ecFileNotFound THEN
                        FAIL
                    ELSE BEGIN
                        KeyFound := FALSE;
                        EXIT;
                    END;
                END;
            END
        END
        ELSE BEGIN
            IF NOT SecQuery.Init('C:\' + JustFileName(FName),
                                 {NEN-ENIGMA}
                                 DecodeStrg(SECON18S, SECON18N, SECON18P),
                                 {cIMa GAlINa}
                                 DecodeStrg(SECON29S, SECON29N, SECON29P),
                                 Prod,
                                 KeySize,
                                 4927422,
                                 Comment) THEN
                FAIL;

        END;
    END;

    (***************************)

    CONSTRUCTOR Security.Init(FName          : PathStr;
                              Prod           : STRING;
                              ExeD,
                              ExeM,
                              ExeY           : WORD;
                              WarnWindow,
                              AllowRefresh   : BOOLEAN);
    BEGIN
        AllowDeadBattery := FALSE;
        IF NOT InitPrim(FName, Prod, ExeD, ExeM, ExeY, WarnWindow, AllowRefresh) THEN
            FAIL;
    END;

    (***************************)

    CONSTRUCTOR Security.InitForChallenge(FName          : PathStr;
                                          Prod           : STRING;
                                          ExeD,
                                          ExeM,
                                          ExeY           : WORD;
                                          WarnWindow,
                                          AllowRefresh   : BOOLEAN);
    BEGIN
        AllowDeadBattery := TRUE;
        IF NOT InitPrim(FName, Prod, ExeD, ExeM, ExeY, WarnWindow, AllowRefresh) THEN
            FAIL;
    END;

    (***************************)

    FUNCTION Security.IsLoggedIn : BOOLEAN;
    VAR
        IsLogged       : BOOLEAN;
    BEGIN
        IsLoggedIn := FALSE;
        IF NetWareLoaded(IsLogged) THEN
            IsLoggedIn := IsLogged;
    END;

    (***************************)

    {-Shut down the security object}
    DESTRUCTOR Security.Done;
    BEGIN
        FILLCHAR(Comment, SIZEOF(Comment), #0);
        IF KeyFound THEN
            SecQuery.Done;
    END;

    (***************************)

    FUNCTION Security.CheckDates(CurBranchP : ContextNodeP) : SecStatT;
    BEGIN
        CheckDates := EGOODSEC;
        (*
        IF CurBranchP = NIL THEN BEGIN
            CheckDates := EWARNSEC;
            EXIT;
        END;
        *)

        CASE ChkDropDead(CurBranchP) OF
            DateOk : ;
            DATEWARN :
                BEGIN
                    IF AllowWarnings AND NOT AlreadyWarned THEN BEGIN
                        {key expires soon - call newsmaker}
                        DispError(DecodeStrg(SECON46S, SECON46N, SECON46P), PARAMSTR(0), TRUE);
                        AlreadyWarned := TRUE;
                    END;
                END;
            DATEFAIL :
                BEGIN
                    CheckDates := EBADSEC;
                    EXIT;
                END;
        END;                      {CASE}

        CASE ChkDateLock(CurBranchP) OF
            DateOk : ;
            DATEFAIL :
                BEGIN
                    CheckDates := EBADSEC;
                    EXIT;
                END;
        END;                      {CASE}
    END;

    (***************************)

    FUNCTION Security.CheckBattery : SecStatT;
    VAR
        Strg           : STRING;
        DTR1,
        DTR2           : DateTimeRec;
        Seconds,
        DeltaT         : LONGINT;
        MaxCharge,
        Days           : WORD;
    BEGIN
        CheckBattery := EBADSEC;

        IF NOT UsedMasterKey THEN BEGIN
            {check for rtc tampering}
            IF NOT GetStringVal(GetLabel(EBATT) +
                                GetLabel(ELASTUSE),
                                1,
                                Strg) THEN BEGIN
                IF AllowWarnings THEN
                    {RTC failure}
                    DispErrorDeluxe(DecodeStrg(SESTR4S, SESTR4N, SESTR4P), '', TRUE, NIL);
                InitStatus := epFatal + ecOutOfRange;
                CheckBattery := EBADSEC;
                EXIT;
            END;

            TDStr2DTR(Strg, DTR1);
            DTRNow(DTR2);

            DeltaT := DateTimeDiffSecsSigned(DTR1, DTR2);

            {backwards more than 2 days = bomb}
            IF (DeltaT / SecondsInDay < - 2) THEN BEGIN
                InitStatus := epFatal + ecOutOfRange;
                IF AllowWarnings THEN
                    {RTC failure}
                    DispErrorDeluxe(DecodeStrg(SESTR4S, SESTR4N, SESTR4P), '', TRUE, NIL);
                CheckBattery := EBADSEC;
                EXIT;
            END;

            {check for charge expire}

            {get last charge date}
            IF NOT GetStringVal(GetLabel(EBATT) +
                                GetLabel(ERCHRG),
                                1,
                                Strg) THEN BEGIN
                CheckBattery := EBADSEC;
                EXIT;
            END;

            TDStr2DTR(Strg, DTR1);
            DTRNow(DTR2);

            DateTimeDiff(DTR1, DTR2, Days, Seconds);

            {get charge duration in days}
            IF NOT GetWordVal(GetLabel(EGLOB) + GetLabel(EMAXCHRG), 1, MaxCharge) THEN BEGIN
                InitStatus := epFatal + ecBadFormat;
                CheckBattery := EBADSEC;
                EXIT;
            END;

            {warn or crash depending on key charge}
            IF (WarnDays > MaxCharge) OR (Days > (MaxCharge - WarnDays)) THEN BEGIN
                IF (NOT AllowDeadBattery) AND (Days > MaxCharge) THEN BEGIN
                    IF AllowWarnings THEN
                        {Key charge expired}
                        DispErrorDeluxe(DecodeStrg(SESTR5S, SESTR5N, SESTR5P), '', TRUE, NIL);
                    InitStatus := epFatal + ecOutOfRange;
                    CheckBattery := EBADSEC;
                    EXIT;
                END;

                IF AllowWarnings AND NOT AlreadyWarned THEN BEGIN
                    {Key Refresh Required}
                    DispError(DecodeStrg(SECON45S, SECON45N, SECON45P), PARAMSTR(0), TRUE);
                    AlreadyWarned := TRUE;
                END;
            END;
        END;
        CheckBattery := EGOODSEC;
    END;

    (***************************)

    {-check for and return the status of Security - checks product dropdead }
    { dates, Network ID or Dongle ID validity, Max number of Workstations   }
    { allowed, Etc.                                                         }

    FUNCTION Security.SecChk : SecStatT;
    VAR
        NumberWSOpen   : BYTE;
        MaxCharge,
        Days,
        MaxWs          : WORD;
        SemaHandle     : LONGINT;
        Hk,
        SK             : LONGINT;
        Strg           : STRING;
        CurBranchP,
        CNP            : ContextNodeP;
        AllowBattUse,
        UsingGlobal,
        Found          : BOOLEAN;
        I              : WORD;
        OldDrive       : STRING;
        DTR1,
        DTR2           : DateTimeRec;
        Seconds        : LONGINT;
        DeltaT         : LONGINT;
    BEGIN
        SecChk := EDEMOSEC;
        Found := FALSE;
        UsingGlobal := FALSE;
        IF NOT KeyFound THEN
            EXIT;
        OldDrive := Sys^.CurrentDriveID;

        {find out how much warning we want to give}
        IF NOT GetWordVal(GetLabel(EGLOB) + GetLabel(EBATTWARN), 1, WarnDays) THEN BEGIN
            InitStatus := epFatal + ecBadFormat;
            SecChk := EBADSEC;
            EXIT;
        END;

        IF IsLoggedIn THEN BEGIN
            ChangeDrive(Sys^.SysDrive);

            IF OpenSemaphore(Sys^.SemName, 0, NumberWSOpen, SemaHandle) THEN BEGIN
                IF NOT GetWordVal(GetLabel(EGLOB) + GetLabel(EMAXWS), 1, MaxWs) THEN BEGIN
                    InitStatus := epFatal + ecBadFormat;
                    SecChk := EBADSEC;
                    ChangeDrive(OldDrive);
                    EXIT;
                END;

                {make sure that we dont have too many ws up and running}
                IF NumberWSOpen > MaxWs THEN BEGIN
                    SecChk := EBADSEC;
                    IF AllowWarnings THEN
                        {Max workstation license count exceeded!}
                        DispErrorDeluxe(DecodeStrg(SESTR3S, SESTR3N, SESTR3P), '', TRUE, NIL);
                    InitStatus := epFatal + ecOutOfRange;
                    ChangeDrive(OldDrive);
                    EXIT;
                END;
            END
            ELSE BEGIN
                SecChk := EBADSEC;
                IF AllowWarnings THEN
                    {Semaphore failure}
                    DispErrorDeluxe(DecodeStrg(SESTR6S, SESTR6N, SESTR6P), '', TRUE, NIL);
                InitStatus := epFatal;
                ChangeDrive(OldDrive);
                EXIT;
            END;

            ChangeDrive(OldDrive);

            CurBranchP := NIL;

            {look for valid server section}
            CurBranchP := FindNode('>:' + GetLabel(EPROD) + ProdName + GetLabel(ESERV));
            IF CurBranchP <> NIL THEN BEGIN
                {see if server id compares with any of the crypted server id codes}
                IF CompareID(ReadNetID, CurBranchP) THEN BEGIN
                    SecChk := EGOODSEC;
                    Found := TRUE; {found a server match}
                END;
            END
            ELSE BEGIN
                {no product Serverid exists, so check for global serverid}
                CurBranchP := FindNode('>:' + GetLabel(EGLOB) + GetLabel(ESERV));
                UsingGlobal := CurBranchP <> NIL;
                IF CurBranchP <> NIL THEN BEGIN
                    {check global serverIDs for match}
                    IF CompareID(ReadNetID, CurBranchP) THEN BEGIN
                        SecChk := EGOODSEC;
                        {see if product is mentioned at all}
                        CNP := FindNode('>:' + GetLabel(EPROD) + ProdName);
                        {if product was not mentioned then go into demo mode}
                        Found := CNP <> NIL;
                        IF NOT Found THEN
                            SecChk := EDEMOSEC;
                        Found := CNP <> NIL;
                        {check for product level dates, if any}
                        CASE CheckDates(CNP) OF
                            EBADSEC :
                                BEGIN
                                    SecChk := EBADSEC;
                                    EXIT;
                                END;
                        END;
                    END;
                END;
            END;

            IF NOT Found THEN BEGIN
                {No matching server found, so check for dongle match}
                CurBranchP := FindNode('>:' + GetLabel(EPROD) + ProdName + GetLabel(EDONG));

                {if no product dongles, then check for global ones}
                IF CurBranchP = NIL THEN BEGIN
                    CurBranchP := FindNode('>:' + GetLabel(EGLOB) + GetLabel(EDONG));
                    UsingGlobal := CurBranchP <> NIL;
                END;

                IF CurBranchP <> NIL THEN BEGIN
                    {compare current dongle id with list of dongle #s}
                    IF CompareID(ReadDongID, CurBranchP) THEN BEGIN
                        SecChk := EGOODSEC;
                        Found := TRUE; {found a dongle match}
                    END
                    ELSE BEGIN
                        IF AllowWarnings THEN
                            {Product not authorized on this server or dongle}
                            DispErrorDeluxe(DecodeStrg(SESTR8S, SESTR8N, SESTR8P), '', TRUE, NIL);
                        InitStatus := epFatal + ecInvalidDrive;
                        SecChk := EBADSEC;
                        EXIT;
                    END;
                END;
            END;

            IF Found THEN
                DoKeyRecharge := TRUE;

            CASE ChkDropDead(CurBranchP) OF
                DateOk : ;
                DATEWARN :
                    BEGIN
                        IF AllowWarnings AND NOT AlreadyWarned THEN BEGIN
                            {key expires soon - call newsmaker}
                            DispError(DecodeStrg(SECON46S, SECON46N, SECON46P), PARAMSTR(0), TRUE);
                            AlreadyWarned := TRUE;
                        END;
                    END;
                DATEFAIL :
                    BEGIN
                        SecChk := EBADSEC;
                        EXIT;
                    END;
            END;                  {CASE}

            CASE ChkDateLock(CurBranchP) OF
                DateOk : ;
                DATEFAIL :
                    BEGIN
                        SecChk := EBADSEC;
                        EXIT;
                    END;
            END;                  {CASE}

        END
        ELSE BEGIN
            {Not on the network, so use battery charge unless there }
            {is a dongle visible                                    }
            {If valid dongle then recharge local key                }

            {first, check if there is a product or global battery shutoff}
            IF GetLabelNC(ENOUSEBAT) <> '' THEN BEGIN
                AllowBattUse := (FindNode('>:' + GetLabel(EPROD) + ProdName + GetLabel(ENOUSEBAT)) = NIL) AND
                                (FindNode('>:' + GetLabel(EGLOB) + GetLabel(ENOUSEBAT)) = NIL);
            END
            ELSE
                AllowBattUse := TRUE;

            CurBranchP := NIL;
            Found := FALSE;
            {look for product dongles}
            CurBranchP := FindNode('>:' + GetLabel(EPROD) + ProdName + GetLabel(EDONG));

            {if no product dongle, then look for a global ones}
            IF CurBranchP = NIL THEN BEGIN
                CurBranchP := FindNode('>:' + GetLabel(EGLOB) + GetLabel(EDONG));
                UsingGlobal := CurBranchP <> NIL;
            END;

            IF CurBranchP <> NIL THEN BEGIN
                IF CompareID(ReadDongID, CurBranchP) THEN BEGIN
                    Found := TRUE;
                    DoKeyRecharge := TRUE; {dongle is same as network key}
                    AllowDeadBattery := TRUE;
                    SecChk := EGOODSEC;
                END
                ELSE BEGIN
                    {is battery use explicitly shut off?}
                    IF NOT AllowBattUse THEN BEGIN
                        {yes: Quit}
                        IF AllowWarnings THEN
                            {Product not authorized on this server or dongle}
                            DispErrorDeluxe(DecodeStrg(SESTR8S, SESTR8N, SESTR8P), '', TRUE, NIL);
                        InitStatus := epFatal + ecInvalidDrive;
                        SecChk := EBADSEC;
                        EXIT;
                    END;

                    {check and see if we still have a valid battery charge}
                    {and continue if good}
                    IF CheckBattery = EBADSEC THEN BEGIN
                        IF AllowWarnings THEN
                            {Product not authorized on this server or dongle}
                            DispErrorDeluxe(DecodeStrg(SESTR8S, SESTR8N, SESTR8P), '', TRUE, NIL);
                        InitStatus := epFatal + ecInvalidDrive;
                        SecChk := EBADSEC;
                        EXIT;
                    END
                    ELSE BEGIN
                        {see if product is mentioned at all}
                        CurBranchP := FindNode('>:' + GetLabel(EPROD) + ProdName);
                        Found := CurBranchP <> NIL;
                        IF Found THEN
                            SecChk := EGOODSEC;
                    END;
                END;
            END
            ELSE BEGIN
                {see if product is mentioned at all}
                CurBranchP := FindNode('>:' + GetLabel(EPROD) + ProdName);
                Found := CurBranchP <> NIL;
                IF Found THEN
                    SecChk := EGOODSEC;
            END;

            IF UsingGlobal THEN BEGIN
                {see if product is mentioned at all}
                CNP := FindNode('>:' + GetLabel(EPROD) + ProdName);
                Found := CNP <> NIL;
                {check for product level dates, if any}
                CASE CheckDates(CNP) OF
                    EBADSEC :
                        BEGIN
                            SecChk := EBADSEC;
                            EXIT;
                        END;
                END;
            END;

            IF (NOT Found) THEN
                SecChk := EDEMOSEC;

            CASE CheckDates(CurBranchP) OF
                EBADSEC :
                    BEGIN
                        SecChk := EBADSEC;
                        EXIT;
                    END;
            END;

        END;

        IF NOT AllowDeadBattery THEN BEGIN
            CASE CheckBattery OF
                EBADSEC :
                    BEGIN
                        SecChk := EBADSEC;
                        EXIT;
                    END;
            END;
        END;
        IF (DoKeyRecharge AND HasLocalDisk) THEN BEGIN
            IF NOT RechargeKey THEN BEGIN
                SecChk := EBADSEC;
                EXIT;
            END;
        END;
        IF NOT Found THEN
            SecChk := EDEMOSEC;
    END;

    (***************************)

    PROCEDURE Security.PreenDate(VAR Strg : STRING);
    VAR
        D,
        M,
        Y              : STRING[10];
    BEGIN
        D := LeftPadCh(ExtractWord(1, Strg, [' ', #9]), '0', 2);
        M := StLoCase(ExtractWord(2, Strg, [' ', #9]));
        Y := ExtractWord(3, Strg, [' ', #9]);
        IF LENGTH(Y) < 4 THEN
            Y := '19' + Y;
        M[0] := #3;
        M[1] := UPCASE(M[1]);
        Strg := D + ' ' + M + ' ' + Y;
    END;

    (***************************)

    FUNCTION Security.LockExpired(ExeDate, LockDate : STRING) : DATERTN;
    VAR
        DTR1,
        DTR2           : DateTimeRec;
        T              : LONGINT;
    BEGIN
        {convert Exe compile date into DateTimeRec}
        PreenDate(ExeDate);
        TDStr2DTR(ExeDate, DTR1);
        {clean up bad time element}
        IF DTR1.T < 0 THEN
            DTR1.T := 0;
        {convert lock_date into DateTimeRec}

        PreenDate(LockDate);

        TDStr2DTR(LockDate, DTR2);
        IF DTR2.T < 0 THEN
            DTR2.T := 0;

        {if Exe Date is greater than than lock_date, then Lock Has Expired -> return true}
        T := DateTimeDiffSecsSigned(DTR2, DTR1);

        IF T > 0 THEN
            LockExpired := DATEFAIL
        ELSE
            LockExpired := DateOk;
    END;

    (***************************)

    {- Test if the ID number in Hk matches any of the authorized ID numbers }
    {  in the Key                                                           }

    FUNCTION Security.CompareID(Hk : LONGINT; VAR CNP : ContextNodeP) : BOOLEAN;
    VAR
        I              : WORD;
        SK             : LONGINT;
    BEGIN
        CompareID := FALSE;
        FOR I := 1 TO CNP^.NumChild DO BEGIN
            IF Str2Long(Trim(CNP^.GetNthChild(I)), SK) THEN BEGIN
                IF Hk = SK THEN BEGIN
                    CompareID := TRUE;
                    {move node pointer to location of successful search}
                    CNP := CNP^.GetNthChildP(I);
                    EXIT;
                END;
            END;
        END;
    END;

    (***************************)

    {Read the Dongle and return the internal serial number}
    FUNCTION Security.ReadDongID : LONGINT;
    VAR
        DR             : DongleRecT;
    BEGIN
        ReadDongID := MAXLONGINT;
        {ruHxpxrxdmabiVrl}
        IF NOT ReadDongle(DR, DecodeStrg(SECON6S, SECON6N, SECON6P), 1, 0, FALSE) THEN
            EXIT;

        {you can only write to the dongle 10,000 times}
        IF DR.WriteCount > 9500 THEN BEGIN
            {Dongle nearing end of R/W lifetime!}
            TellUser(DecodeStrg(SECON28S, SECON28N, SECON28P));
            RingBell;
        END;
        ReadDongID := DR.MySn;
    END;

    (***************************)

    {returns 0 if not on network}
    FUNCTION Security.ReadNetID : LONGINT;
    VAR
        L              : LONGINT;
    BEGIN
        IF Str2Long(GetServerSerialNumber, L) THEN
            ReadNetID := L
        ELSE
            ReadNetID := 0;
    END;

    (***************************)

    {read lines from the GLOBAL:STATION_LOC block.  Index into block with Instance}
    FUNCTION Security.GetStationLoc(Instance : BYTE; VAR Strg : STRING) : BOOLEAN;
    BEGIN
        GetStationLoc := FALSE;
        Strg := '';

        IF NOT GetStringVal(GetLabel(EGLOB) +
                            GetLabel(ESTATLOC), Instance, Strg) THEN
            EXIT;

        GetStationLoc := TRUE;
    END;

    (***************************)

    {read lines from the GLOBAL:STATION_ID block.  Index into block with Instance}
    FUNCTION Security.GetStationID(Instance : BYTE; VAR Strg : STRING) : BOOLEAN;
    BEGIN
        GetStationID := FALSE;
        Strg := '';

        IF NOT GetStringVal(GetLabel(EGLOB) +
                            GetLabel(ESTATID), Instance, Strg) THEN
            EXIT;

        GetStationID := TRUE;
    END;

    (***************************)

    {get max workstation count from GLOBAL:MAX_WS}
    FUNCTION Security.GetAllowedWSCount : STRING;
    VAR
        MaxWs          : WORD;
    BEGIN
        GetAllowedWSCount := '';

        IF NOT GetWordVal(GetLabel(EGLOB) + GetLabel(EMAXWS), 1, MaxWs) THEN
            EXIT;

        GetAllowedWSCount := Long2Str(MaxWs);
    END;

    (***************************)

    {check Novell semaphore to determine number of running workstations}
    FUNCTION Security.GetNumRunningWS : WORD;
    VAR
        NumberWSOpen   : BYTE;
        OldDrive       : PathStr;
        SemaHandle     : LONGINT;
    BEGIN
        IF IsLoggedIn THEN BEGIN

            OldDrive := Sys^.CurrentDriveID;

            ChangeDrive(Sys^.SysDrive);

            IF NOT OpenSemaphore(Sys^.SemName, 0, NumberWSOpen, SemaHandle) THEN
                NumberWSOpen := $FF;

            ChangeDrive(OldDrive);

        END
        ELSE
            NumberWSOpen := 1;

        GetNumRunningWS := NumberWSOpen;
    END;

    (***************************)

    {read back GLOBAL:STATION_LIC string}
    FUNCTION Security.GetLicense : STRING;
    VAR
        Strg           : STRING;
    BEGIN

        GetLicense := '';

        Strg := '';

        IF NOT GetStringVal(GetLabel(EGLOB) +
                            GetLabel(ESTATLIC), 1, Strg) THEN
            EXIT;

        GetLicense := Strg;
    END;

    (***************************)

    {- check input date against the lock date }
    {if no DATE_LOCK exists, then assume failed datelock}
    FUNCTION Security.ChkDateLock(CNP : ContextNodeP) : DATERTN;
    VAR
        Strg           : STRING;
        PROCEDURE DoCheck(S : STRING);
        BEGIN
            CASE LockExpired(DateToDateString(SEDatePict, MyLock), S) OF
                DateOk :
                    ChkDateLock := DateOk;
                DATEFAIL :
                    BEGIN
                        IF AllowWarnings THEN
                            {You are not authorized to run this product version.  Use an older one.}
                            DispErrorDeluxe(DecodeStrg(SESTR9S, SESTR9N, SESTR9P), '', TRUE, NIL);
                        InitStatus := epFatal + ecOutOfRange;
                        ChkDateLock := DATEFAIL;
                        EXIT;
                    END;
            END;
        END;
    BEGIN
        ChkDateLock := DATEFAIL;

        {search forward for dropdead in current context}
        IF CNP <> NIL THEN
            CNP := CNP^.SearchForwardForNode(GetLabel(EDATELOCK), 1);

        IF CNP <> NIL THEN BEGIN
            {found server/dongle datelock value}
            Strg := CNP^.GetNthVar(1);
            IF Strg <> '' THEN BEGIN
                DoCheck(Strg);
                EXIT;
            END;
        END;

        IF GetStringVal(GetLabel(EPROD) +
                        ProdName +
                        GetLabel(EGLOB) +
                        GetLabel(EDATELOCK), 1, Strg) THEN BEGIN
            {Product has explicit dropdead date, so check it}
            DoCheck(Strg);
        END
        ELSE BEGIN
            {no product lock date, so check global lock date}
            IF GetStringVal(GetLabel(EGLOB) +
                            GetLabel(EDATELOCK), 1, Strg) THEN BEGIN
                {global dropdead date found, so check it}
                DoCheck(Strg);
                EXIT;
            END;
            ChkDateLock := DateOk; {no maint date}
        END;
    END;

    (************************)

    {- Test to see if Today is greater than the DropDead date string 'D' }
    FUNCTION Security.DropDeadExpired(D : STRING) : DATERTN;
    VAR
        DTR1,
        DTR2           : DateTimeRec;
        T              : LONGINT;
    BEGIN
        PreenDate(D);

        {convert dropdead into DateTimeRec}
        TDStr2DTR(D, DTR1);
        {clean up bad time element if no dropdead time specified}
        IF DTR1.T < 0 THEN
            DTR1.T := 0;
        {read RTC}
        DTRNow(DTR2);

        {check if dropdead is before now}
        T := DateTimeDiffSecsSigned(DTR1, DTR2);

        IF T > 0 THEN
            DropDeadExpired := DATEFAIL
        ELSE IF T > (SecondsInDay * - WarnDays) THEN
            DropDeadExpired := DATEWARN
        ELSE
            DropDeadExpired := DateOk;

    END;

    (************************)

    {- check current date against the dropdead date }
    {It is OK to not have a dropdead date in product or global}
    FUNCTION Security.ChkDropDead(CNP : ContextNodeP) : DATERTN;
    VAR
        Strg           : STRING;
        PROCEDURE DoCheck(S : STRING);
        BEGIN
            CASE DropDeadExpired(S) OF
                DateOk :
                    ChkDropDead := DateOk;
                DATEWARN :
                    BEGIN
                        IF AllowWarnings AND NOT AlreadyWarned THEN BEGIN
                            {Key Expires Soon.  Call NewsMaker!}
                            DispError(DecodeStrg(SECON46S, SECON46N, SECON46P), PARAMSTR(0), TRUE);
                            AlreadyWarned := TRUE;
                        END;
                        ChkDropDead := DATEWARN;
                    END;
                DATEFAIL :
                    BEGIN
                        InitStatus := epFatal + ecOutOfRange;
                        IF AllowWarnings THEN
                            {This product has expired!}
                            DispErrorDeluxe(DecodeStrg(SESTR10S, SESTR10N, SESTR10P), '', TRUE, NIL);
                        ChkDropDead := DATEFAIL;
                        EXIT;
                    END;
            END;
        END;
    BEGIN
        ChkDropDead := DATEFAIL;

        {search forward for dropdead in current context}
        IF CNP <> NIL THEN
            CNP := CNP^.SearchForwardForNode(GetLabel(EDROPDEAD), 1);

        IF CNP <> NIL THEN BEGIN
            {found server/dongle dropdead value}
            Strg := CNP^.GetNthVar(1);
            IF Strg <> '' THEN BEGIN
                DoCheck(Strg);
                EXIT;
            END;
        END;

        {look in product global context for dropdead}
        IF GetStringVal(GetLabel(EPROD) +
                        ProdName +
                        GetLabel(EGLOB) +
                        GetLabel(EDROPDEAD), 1, Strg) THEN BEGIN
            {Product has explicit dropdead date, so check it}
            DoCheck(Strg);
            EXIT;
        END
        ELSE BEGIN
            {no product dropdead date, so check key global dropdead}
            IF GetStringVal(GetLabel(EGLOB) +
                            GetLabel(EDROPDEAD), 1, Strg) THEN BEGIN
                {global dropdead date found, so check it}
                DoCheck(Strg);
                EXIT;
            END;
        END;
        ChkDropDead := DateOk;    {no dropdead found, so default to OK}
    END;

    (************************)

    {-get the compile date of the product}
    {this is virtual so that you can override it with some other method}
    FUNCTION Security.GetExeDate(VAR Dtr : DateTimeRec) : BOOLEAN;
    VAR
        F              : FILE;
        FT             : LONGINT;
    BEGIN
        ASSIGN(F, PARAMSTR(0));
        GetFTime(F, FT);
        DoStimeToDT(FT, Dtr);
    END;

    (************************)

    {method to allow manual recharge of NEN.KEY without dongle or server    }
    {connection.  Requires password supplied by Customer Support in response}
    {to challenge password displayed on customer screen                     }
    PROCEDURE Security.ManualRefresh;
    VAR
        P              : RefreshKeyP;
    BEGIN
        NEW(P, Init);
        IF P = NIL THEN BEGIN
            DispErrorDeluxe('Init fail', ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;
        P^.Process;
        IF P^.CheckReply THEN BEGIN
            IF RechargeKey THEN
                {Recharge Successful}
                IF AllowWarnings THEN
                    DispErrorDeluxe(DecodeStrg(SECON40S, SECON40N, SECON40P), '', TRUE, NIL)
                ELSE
                    {Recharge Failure}
                    IF AllowWarnings THEN
                        DispErrorDeluxe(DecodeStrg(SECON41S, SECON41N, SECON41P), '', TRUE, NIL);
        END
        ELSE
            {Recharge Failure}
            IF AllowWarnings THEN
                DispErrorDeluxe(DecodeStrg(SECON41S, SECON41N, SECON41P), '', TRUE, NIL);


        DISPOSE(P, Done);
    END;

    (************************)

    {method to generate a reply to a challenge.  For use by Support ONLY.}

    PROCEDURE Security.GenReplyToChallenge;
    VAR
        P              : RefreshKeyP;
    BEGIN
        NEW(P, InitDeluxe);
        IF P = NIL THEN BEGIN
            DispErrorDeluxe('Init fail', ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;
        P^.Process;
        READLN;
        DISPOSE(P, Done);
    END;

    (************************)

END.


    (***************************)
    (***************************)



