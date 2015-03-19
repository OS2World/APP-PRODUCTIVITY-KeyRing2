PROGRAM kr2robot;
    {$PMTYPE VIO}

USES
    CDF,
    CmdLin3,
    DGLIB,
    DGMath,
    Dos,
    KERROR,
    OpCmd,
    OpCol16,
    OpCRT,
    OpDate,
    OpRoot,
    OpString,
    Os2Base,
    OS2DEF,
    Register,
    Strings,
    UTIAM,
    UTTIMDAT,
    UTWHOIS,
    VARDEC;
TYPE
    TSleepMode     = (EScan, EManual, EQuit);

CONST
    FNWidth        = 30;
    LNWidth        = 30;
    LIMWidth       = 80;
    RNWidth        = 16;

    {--------------}

    function DNSLookUp(IP : STRING):string;
    var
        W : tWhois;
    begin
        W := tWhois.Create;
        result := w.reversedns(IP);
        W.destroy;
    end;

    {--------------}

    PROCEDURE MakeMsg(ADDR : STRING);
    VAR
        T              : TEXT;
        FName          : STRING;
    BEGIN
        {create empty, closed text temp file and return handle}
        IF NOT GetTempTextFileHandle(
            {$IFDEF DEBUG}
            '.\junk',
            {$ELSE}
            'f:\prm\kgmccoy\sndnotes',
            {$ENDIF}
            'POP',
            FName,
            T) THEN
            EXIT;

        REWRITE(T);

        WRITELN(T, '' + ADDR);
        WRITELN(T, 'Registration messages');
        WRITELN(T, 'F:\PRM\kgmccoy\keyring_\registra');
        WRITELN(T, '2Normal');
        WRITELN(T, 'Kevin G. McCoy <kgmccoy@idk-inc.com>');
        WRITELN(T, '1Kevin G. McCoy <kgmccoy@idk-inc.com>');
        WRITELN(T, 'KeyRing/2 demo available');
        WRITELN(T, 'Dear Sir or Madam,');
        WRITELN(T, '');
        WRITELN(T, 'Thank you for your interest in our latest IDK Inc. product, KeyRing/2');
        WRITELN(T, '- the Secure Password Keeper for OS/2');
        WRITELN(T, '');
        WRITELN(T, 'Due to the immense response, we have created a web site where you can');
        WRITELN(T, 'download the installer and the free demo. You may also purchase KeyRing/2');
        WRITELN(T, 'there, via the link to BMT Micro''s secure web site.');
        WRITELN(T, '');
        WRITELN(T, 'Please visit us at:');
        WRITELN(T, '');
        WRITELN(T, 'http://www.idk-inc.com/kr2index.htm');
        WRITELN(T, '');
        WRITELN(T, 'you may also use anonymous FTP to download the demo files from:');
        WRITELN(T, '');
        WRITELN(T, 'ftp://idk-inc.com/pub/users/kgmccoy/keyring2');
        WRITELN(T, '(you only need the WPI, the ZIP and the README)');
        WRITELN(T, '');
        WRITELN(T, 'Due to United States cryptographic export laws, we are restricted from');
        WRITELN(T, 'placing the 448 bit encryption module in a public download area. Therefore,');
        WRITELN(T, 'the demo comes _without an encryption module_. You must contact us to');
        WRITELN(T, 'receive the module!');
        WRITELN(T, '');
        WRITELN(T, 'Fill out the request form on the web page to receive a small Email file');
        WRITELN(T, 'attachment containing the appropriate encryption module.  Citizens of non-');
        WRITELN(T, 'terrorist supporting countries are eligible to receive the Blowfish 448-bit');
        WRITELN(T, 'encryption module.');
        WRITELN(T, '');
        WRITELN(T, 'KeyRing/2 DES is field upgradable to Blowfish, if and when we receive');
        WRITELN(T, 'approval from the US Government. The upgrade will be free.');
        WRITELN(T, '');
        WRITELN(T, '----------------------------------------------------------------------------');
        WRITELN(T, 'The demo has a 30 day limitation on database lifetime. Registration revives');
        WRITELN(T, 'any expired databases. You can restart the 30 day "demo clock" by creating');
        WRITELN(T, 'a new database file.');
        WRITELN(T, '');
        WRITELN(T, '----------------------------------------------------------------------------');
        WRITELN(T, '');
        WRITELN(T, '');
        WRITELN(T, '');
        WRITELN(T, 'Sincerely,');
        WRITELN(T, '');
        WRITELN(T, 'Kevin G. McCoy');
        WRITELN(T, 'President, IDK, Inc.');
        WRITELN(T, 'Custom Software Design and Consultation');
        WRITELN(T, '');
        WRITELN(T, '805.492.9190 (Voice)');
        WRITELN(T, '805.492.1533 (Fax)');
        WRITELN(T, 'kgmccoy@idk-inc.com');
        WRITELN(T, 'CIS: 72470,1233');
        WRITELN(T, 'http://www.idk-inc.com');
        CLOSE(T);
    END;

    {--------------}

    FUNCTION SearchCDF(MailAddr : STRING; VAR MyRR : TRegisterRec) : BOOLEAN;
    VAR
        PCDF           : PCDFReader;
    BEGIN
        Result := FALSE;

        NEW(PCDF, Init('g:\keyring2\register.cdf'));
        IF PCDF = NIL THEN
            EXIT;

        WITH PCDF^ DO BEGIN
            AddField(EDate, 'CreateDate', MyRR.BuildDate.D);
            AddField(ETime, 'CreateTime', MyRR.BuildDate.T);
            AddField(EString, 'Firstname', MyRR.FirstName);
            AddField(EString, 'Lastname', MyRR.LastName);

            AddField(EString, 'RegCode', MyRR.RegCode);

            AddField(ELong, 'DemoPWXLifetime', MyRR.DemoPWXLifetime);
            AddField(EDate, 'DropDead', MyRR.DropDead);
            AddField(EString, 'FeatureBits', MyRR.FeatureBits);
            AddField(EString, 'Addr1', MyRR.Addr1);
            AddField(EString, 'Addr2', MyRR.Addr2);
            AddField(EString, 'City', MyRR.City);
            AddField(EString, 'State', MyRR.State);
            AddField(EString, 'Zip', MyRR.Zip);
            AddField(EString, 'Country', MyRR.Country);
            AddField(EString, 'Email', MyRR.Email);
            AddField(EString, 'WPIName', MyRR.WPIName);
            AddField(EString, 'CompanyName', MyRR.CompanyName);
            AddField(EString, 'Crypter', MyRR.CryptModule);
            AddField(EString, 'Limits', MyRR.Limits);

            AddField(EString, 'IP', MyRR.IP);
            AddField(EString, 'Domain', MyRR.Domain);
            AddField(EString, 'Phone', MyRR.Phone);
            AddField(EString, 'Citizen', MyRR.Citizen);
            AddField(EBool, 'Agree', MyRR.Agree);
            AddField(EString, 'Ordernum', MyRR.OrderNum);
            AddField(ELong, 'Qty', MyRR.Qty);
            AddField(EString, 'Comment', MyRR.Comment);
        END;

        FILLCHAR(MyRR, SIZEOF(MyRR), #0);

        WHILE PCDF^.LoadRecord DO BEGIN
            IF CompUCString(MailAddr, MyRR.Email) = EQUAL THEN BEGIN
                Result := TRUE;
                DISPOSE(PCDF, Done);
                EXIT;
            END;
        END;

        DISPOSE(PCDF, Done);
    END;

    {--------------}

    FUNCTION AddSearch(ADDR : STRING) : BOOLEAN;
    VAR
        T              : TEXT;
        Line           : STRING;
    BEGIN
        {return true if address not seen, else return false}
        Result := FALSE;
        ASSIGN(T, 'spamdb.txt');
        {$I-}
        RESET(T);
        IF IORESULT = 110 THEN
            REWRITE(T);
        WHILE NOT EOF(T) DO BEGIN
            READLN(T, Line);
            IF CompUCString(Line, ADDR) = EQUAL THEN BEGIN
                CLOSE(T);
                EXIT;
            END;
        END;
        CLOSE(T);
        APPEND(T);
        Result := TRUE;
        WRITELN(T, ADDR);
        CLOSE(T)
    END;

    {--------------}

CONST
    RobotFieldNames : ARRAY[1..13] OF STRING[13] =
    ('firstname: ',
     'lastname: ',
     'companyname: ',
     'email: ',
     'addr1: ',
     'addr2: ',
     'city: ',
     'state: ',
     'zip: ',
     'country: ',
     'phone: ',
     'citizen: ',
     'agree: ');

    {--------------}

    PROCEDURE RobotSetInfo(VAR RegInfo : TRegisterRec; Indx : BYTE; Value : STRING);
    BEGIN
        WITH RegInfo DO BEGIN
            CASE Indx OF
                1 :
                    FirstName := Value;
                2 :
                    LastName := Value;
                3 :
                    CompanyName := Value;
                4 :
                    Email := Value;
                5 :
                    Addr1 := Value;
                6 :
                    Addr2 := Value;
                7 :
                    City := Value;
                8 :
                    State := Value;
                9 :
                    Zip := Value;
                10 :
                    Country := Value;
                11 :
                    Phone := Value;
                12 :
                    Citizen := Value;
                13 :
                    Agree := (Value = '1');
            END;
        END;
    END;

    {--------------}

TYPE
    TBMTTokens     = (EBAD,
                      ECustName,
                      ECompName,
                      ERegTo,
                      EAddr1,
                      EAddr2,
                      ECity,
                      EState,
                      EZip,
                      ECountry,
                      EHomePh,
                      EWrkPh,
                      EEmail1,
                      EEmail2,
                      EOrderNum,
                      EQty,
                      EComment);
CONST
    BMTFieldNames  : ARRAY[TBMTTokens] OF STRING[20] =
    { 12345678901234567890}
    ('badtoken',
     'Customer Name:',
     'Company Name:',
     'Register To:',
     'Street1:',
     'Street2:',
     'City:',
     'State:',
     'Postal Code:',
     'Country:',
     'Home Phone#:',
     'Work Phone#:',
     'E-mail Address:',
     'Secondary E-mail:',
     'OrderNumber:',
     'Quantity:',
     'Customer Comments:');

    {--------------}

    PROCEDURE BMTSetInfo(VAR RegInfo : TRegisterRec; Indx : TBMTTokens; Value : STRING);
    BEGIN
        WITH RegInfo DO BEGIN
            CASE Indx OF
                ECustName :
                    BEGIN
                        FirstName := ExtractWord(1, Value, [' ']); {first word of customer name}
                        LastName := COPY(Value, WordPosition(2, Value, [' ']), 255); {everything else}
                    END;
                ECompName :
                    CompanyName := Value;
                ERegTo :
                    BEGIN
                        IF Value <> '' THEN
                            CompanyName := Value;
                    END;
                EAddr1 :
                    Addr1 := Value;
                EAddr2 :
                    Addr2 := Value;
                ECity :
                    City := Value;
                EState :
                    State := Value;
                EZip :
                    Zip := Value;
                ECountry :
                    BEGIN
                        Country := Value;
                        Citizen := Value;
                        Agree := TRUE;
                    END;
                EHomePh :
                    Phone := Value;
                EWrkPh :
                    IF Phone = '' THEN
                        Phone := Value;
                EEmail1 :
                    Email := Value;
                EEmail2 :
                    IF Email = '' THEN
                        Email := Value;
                EOrderNum :
                    OrderNum := Value;
                EQty :
                    BEGIN
                        Value := ExtractWord(1, Value, [' ', #9]);
                        IF NOT Str2Long(Value, Qty) THEN
                            Qty := 1;
                    END;
                EComment :
                    Comment := Value;
            END;
        END;
    END;

    {--------------}

    FUNCTION RobotFieldLookup(Line : STRING; VAR Value : STRING) : BYTE;
    VAR
        I,
        P              : BYTE;
    BEGIN
        Result := 0;
        FOR I := LOW(RobotFieldNames) TO HIGH(RobotFieldNames) DO BEGIN
            P := POS(RobotFieldNames[I], Line);
            IF P = 1 THEN BEGIN
                Value := COPY(Line, LENGTH(RobotFieldNames[I]) + 1, 255);
                Result := I;
                EXIT;
            END;
        END;
        Value := '';
    END;

    {--------------}

    FUNCTION BMTFieldLookup(Line : STRING; VAR Value : ANSISTRING) : TBMTTokens;
    VAR
        I              : TBMTTokens;
        P              : BYTE;
    BEGIN
        Result := EBAD;
        FOR I := LOW(BMTFieldNames) TO HIGH(BMTFieldNames) DO BEGIN
            P := POS(BMTFieldNames[I], Line);
            IF P = 1 THEN BEGIN
                Value := Trim(COPY(Line, LENGTH(BMTFieldNames[I]) + 1, 255));
                Result := I;
                EXIT;
            END;
        END;
        Value := '';
    END;

    {--------------}

    FUNCTION ParseRobotPop(PopName : STRING; VAR RegInfo : TRegisterRec) : BOOLEAN;
    VAR
        T              : TEXTFile;
        Value,
        Subject,
        Line           : STRING;
        Indx           : BYTE;
        Res : LONGINT;
    BEGIN
        FILLCHAR(RegInfo, SIZEOF(RegInfo), #0);
        RegInfo.MaxRev := 2;
        Res := IoResult;
        FileMode := open_access_ReadWrite OR open_share_DenyNone; // $42

        Result := FALSE;
        {open the pop file}
        ASSIGN(T, PopName);
        RESET(T);
        Subject := '';
        WHILE NOT EOF(T) DO BEGIN
            READLN(T, Line);
            {get the address from an open pop file}
            IF POS('Subject: ', Line) = 1 THEN
                RegInfo.IP := ExtractWord(5, Line, [' ']);
            Indx := RobotFieldLookup(Line, Value);
            IF Indx > 0 THEN BEGIN
                Result := TRUE;   {at least one valid field}
                RobotSetInfo(RegInfo, Indx, Trim(Value));
            END;
        END;
        CLOSE(T);
    END;

    {--------------}

    FUNCTION ParseBMTPop(PopName : STRING; VAR RegInfo : TRegisterRec) : BOOLEAN;
    VAR
        T              : TEXT;
        Value,
        Subject,
        Line           : ANSISTRING;
        Indx           : TBMTTokens;
        I : INTEGER;
    BEGIN
        FILLCHAR(RegInfo, SIZEOF(RegInfo), #0);
        Result := FALSE;
        {open the pop file}
        ASSIGN(T, PopName);
        RESET(T);
        Subject := '';
        WHILE NOT EOF(T) DO BEGIN
            READLN(T, Line);
            I := Length(Line);
            {get the address from an open pop file}
            Indx := BMTFieldLookup(Line, Value);
            IF Indx > EBAD THEN BEGIN
                Result := TRUE;   {at least one valid field}
                BMTSetInfo(RegInfo, Indx, Value);
            END;
        END;
        CLOSE(T);
    END;

    {--------------}

    PROCEDURE DoRobotDemoRequests;
    VAR
        SR             : FileFindBuf3;
        Rc,
        HDir,
        Count          : ULONG;
        PathZ          : ARRAY[0..cchMaxPathComp] OF CHAR;
        Address,
        StartPath      : STRING;
        TempInfo,
        Info           : TRegisterRec;
        PR             : PRegES;
        Virgin,
        Redraw         : BOOLEAN;
    BEGIN
        Virgin := TRUE;
        {pass pop file names to parse address - if it returns true, then}

        NEW(PR, InitManual(Info, 'D:\SoundFx\SOUNDFX\trumpet.wav'));
        IF PR = NIL THEN BEGIN
            EXIT;
        END;

        {scan demo inquiry directory for pop files}
        StartPath := FExpand('F:\PRM\kgmccoy\keyring_\robot_ms');
        HDir := hDir_Create;
        StrPCopy(PathZ, AddBackSlash(StartPath) + '*.POP');
        Count := 1;
        Rc := DosFindFirst(PathZ,
                           HDir,
                           $37,
                           SR,
                           SIZEOF(SR),
                           Count,
                           fil_Standard);

        WHILE (Rc = 0) DO BEGIN
            IF SR.achName[1] <> '.' THEN BEGIN
                IF SR.Attrfile AND Directory = 0 THEN BEGIN
                    IF ParseRobotPop(AddBackSlash(StartPath) + SR.achName, Info) THEN BEGIN
                        IF SearchCDF(Info.Email, TempInfo) THEN
                            FastWrite('Dupe!', 1, 80 - 5, BlackOnWhite)
                        ELSE
                            FastWrite('     ', 1, 80 - 5, WhiteOnBlack);

                        Info.PrgVerMajor := IniVerMajor;
                        Info.PrgVerMinor := IniVerMinor;
                        //Info.FeatureBits := DESFEATUREBIT + BLOFEATUREBIT + PWXDDFEATUREBIT;
                        Info.FeatureBits := DESFEATUREBIT + BLOFEATUREBIT + NONAGFEATUREBIT + PAIDFEATUREBIT;

                        Info.DropDead := Today + (365 * 30);
                        Info.DemoPWXLifetime := 30;
                        {                        1         2         3         4         5}
                        {               12345678901234567890123456789012345678901234567890}
                        Info.Limits := 'Limited database lifetime! Please register!';
                        Info.Qty := 1;
                        DTRNow(Info.BuildDate);

                        PR^.ChangeRR(Info, FALSE, AddBackSlash(StartPath) + SR.achName);
                        PR^.wFrame.ChangeHeaderString(0, ' Gen KR2 *DEMO* Registration ', Redraw);
                        IF Redraw THEN
                            PR^.wFrame.UpDateFrame
                        ELSE
                            PR^.wFrame.DrawHeader(0);

                        {
                        IF Virgin AND Is_Param('s') THEN
                            PR^.PlaySound;
                        }

                        PR^.Process;

                        Virgin := FALSE;
                    END;
                END;
            END;
            Rc := DosFindNext(HDir, SR, SIZEOF(SR), Count);
        END;
        Rc := DosFindClose(HDir);
        DISPOSE(PR, Done);
    END;

    {---------------}

    PROCEDURE DoBMTPaidUpRequests;
    VAR
        SR             : FileFindBuf3;
        Rc,
        HDir,
        Count          : ULONG;
        PathZ          : ARRAY[0..cchMaxPathComp] OF CHAR;
        Address,
        StartPath      : STRING;
        TempInfo,
        Info           : TRegisterRec;
        PR             : PRegES;
        IsDupe,
        Virgin,
        Redraw         : BOOLEAN;
    BEGIN
        Virgin := FALSE;
        IsDupe := FALSE;
        {pass pop file names to parse address - if it returns true, then}
        NEW(PR, InitManual(Info, 'D:\SoundFx\SOUNDFX\chaching.wav'));
        IF PR = NIL THEN BEGIN
            EXIT;
        END;
        {scan demo inquiry directory for pop files}
        StartPath := FExpand('F:\PRM\kgmccoy\keyring_\send_a_p');
        HDir := hDir_Create;
        StrPCopy(PathZ, AddBackSlash(StartPath) + '*.POP');
        Count := 1;
        Rc := DosFindFirst(PathZ,
                           HDir,
                           $37,
                           SR,
                           SIZEOF(SR),
                           Count,
                           fil_Standard);

        WHILE (Rc = 0) DO BEGIN
            IF SR.achName[1] <> '.' THEN BEGIN
                IF SR.Attrfile AND Directory = 0 THEN BEGIN
                    IF ParseBMTPop(AddBackSlash(StartPath) + SR.achName, Info) THEN BEGIN
                        IsDupe := SearchCDF(Info.Email, TempInfo);

                        Info.PrgVerMajor := IniVerMajor;
                        Info.PrgVerMinor := IniVerMinor;
                        Info.MaxRev := ProgVerMajor;
                        Info.FeatureBits := DESFEATUREBIT + BLOFEATUREBIT + NONAGFEATUREBIT + PAIDFEATUREBIT;
                        Info.DropDead := Today + (365 * 30);
                        Info.DemoPWXLifetime := 30;
                        {                        1         2         3         4         5}
                        {               12345678901234567890123456789012345678901234567890}
                        Info.Limits := 'Paid Registration';
                        DTRNow(Info.BuildDate);
                        PR^.ChangeRR(Info, FALSE, AddBackSlash(StartPath) + SR.achName);

                        PR^.wFrame.ChangeHeaderString(0, ' Gen KR2 Paid Registration ', Redraw);
                        IF Redraw THEN
                            PR^.wFrame.UpDateFrame
                        ELSE
                            PR^.wFrame.DrawHeader(0);

                        {
                        IF Virgin AND Is_Param('s') THEN
                            PR^.PlaySound;
                        }

                        If IsDupe THEN
                            FastWrite('Dupe!', 1, 80 - 5, BlackOnWhite)
                        ELSE
                            FastWrite('     ', 1, 80 - 5, WhiteOnBlack);

                        PR^.Process;
                        Virgin := FALSE;
                    END;
                END;
            END;
            Rc := DosFindNext(HDir, SR, SIZEOF(SR), Count);
        END;
        Rc := DosFindClose(HDir);
        DISPOSE(PR, Done);
    END;

    {--------------}

    PROCEDURE CleanDB;
    VAR
        PCDF           : PCDFReader;
        PR             : PRegES;
        MyRR           : TRegisterRec;
        I              : LONGINT;
    BEGIN
        FILLCHAR(MyRR, SIZEOF(MyRR), #0);
        {pass pop file names to parse address - if it returns true, then}
        NEW(PR, InitManual(MyRR, ''));
        IF PR = NIL THEN BEGIN
            DispErrorDeluxe('Entry screen init fail', ErrorMessage(InitStatus), TRUE, Iam);
            EXIT;
        END;

        NEW(PCDF, Init('g:\keyring2\register.cdf'));
        IF PCDF = NIL THEN
            EXIT;

        WITH PCDF^ DO BEGIN
            AddField(EDateTime, 'BuildDate', MyRR.BuildDate);
            AddField(EString, 'Firstname', MyRR.FirstName);
            AddField(EString, 'Lastname', MyRR.LastName);

            AddField(EString, 'RegCode', MyRR.RegCode);

            AddField(ELong, 'DemoPWXLifetime', MyRR.DemoPWXLifetime);
            AddField(EDate, 'DropDead', MyRR.DropDead);
            AddField(ELong, 'FeatureBits', MyRR.FeatureBits);
            AddField(EString, 'Addr1', MyRR.Addr1);
            AddField(EString, 'Addr2', MyRR.Addr2);
            AddField(EString, 'City', MyRR.City);
            AddField(EString, 'State', MyRR.State);
            AddField(EString, 'Zip', MyRR.Zip);
            AddField(EString, 'Country', MyRR.Country);
            AddField(EString, 'Email', MyRR.Email);
            AddField(EString, 'WPIName', MyRR.WPIName);
            AddField(EString, 'CompanyName', MyRR.CompanyName);
            AddField(EString, 'Crypter', MyRR.CryptModule);
            AddField(EString, 'Limits', MyRR.Limits);

            AddField(EString, 'IP', MyRR.IP);
            AddField(EString, 'Domain', MyRR.Domain);
            AddField(EString, 'Phone', MyRR.Phone);
            AddField(EString, 'Citizen', MyRR.Citizen);
            AddField(EBool, 'Agree', MyRR.Agree);
            AddField(EString, 'Ordernum', MyRR.OrderNum);
            AddField(ELong, 'Qty', MyRR.Qty);
            AddField(EString, 'Comment', MyRR.Comment);
        END;

        FILLCHAR(MyRR, SIZEOF(MyRR), #0);
        I := 0;
        WHILE PCDF^.LoadRecord DO BEGIN
            {autofix area}
            CASE MyRR.FeatureBits OF
                0 :
                    MyRR.Limits := 'Beta';
                $1 :
                    MyRR.Limits := 'Beta';
                $1D :
                    MyRR.Limits := 'Paid Registration';
                $1A :
                    MyRR.Limits := 'Limited Demo Registration.  Please Register!';
                ELSE
                    MyRR.Limits := 'Limited Demo Registration.  Please Register!';
            END;

            IF MyRR.Qty = 0 THEN
                MyRR.Qty := 1;

            IF MyRR.CryptModule <> '' THEN BEGIN
                MyRR.CryptModule := StUpCase(MyRR.CryptModule);
                CASE MyRR.CryptModule[1] OF
                    'T' :
                        MyRR.CryptModule := 'Blowfish';
                    'F' :
                        MyRR.CryptModule := 'DES';
                    'D' :
                        MyRR.CryptModule := 'DES';
                    'B' :
                        MyRR.CryptModule := 'Blowfish';
                END;
            END;
            {end autofix area}

            MyRR.WPIName := JustFileName(MyRR.WPIName);
            PR^.ChangeRR(MyRR, TRUE, '');
            PR^.Process;
            PR^.LogIt('clean.cdf');
            FILLCHAR(MyRR, SIZEOF(MyRR), #0);
        END;

        DISPOSE(PR, Done);
        DISPOSE(PCDF, Done);
    END;

    {----------------}

    FUNCTION FillRRFromCmdLine(VAR RR : TRegisterRec) : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        FILLCHAR(RR, SIZEOF(RR), #0);
        RR.DropDead := Today + Param_Int('K', 365 * 30);
        IF Is_Param('d') THEN BEGIN {demo}
            RR.DemoPWXLifetime := 30;
            RR.FirstName := 'Demo';
            RR.LastName := 'Demo';
            RR.Email := 'kr2@idk-inc.com';
            RR.InstallDate := BADDate;
            RR.FeatureBits := PWXDDFEATUREBIT + DESFEATUREBIT;
            RR.DropDead := Today + Param_Int('K', 365 * 30);
        END;
        IF Is_Param('b') THEN BEGIN {beta}
            RR.FirstName := Param_Text('F');
            RR.LastName := Param_Text('L');
            RR.Email := Param_Text('E');
            RR.DemoPWXLifetime := 999;
            RR.InstallDate := BADDate;
            RR.FeatureBits := PWXDDFEATUREBIT;
        END;
        IF Is_Param('p') THEN BEGIN {paid}
            RR.DemoPWXLifetime := 999;
            RR.InstallDate := BADDate;
            RR.FeatureBits := BLOFEATUREBIT + DESFEATUREBIT + PAIDFEATUREBIT + NONAGFEATUREBIT;
        END;
        Result := TRUE;
    END;

    {----------------}

    {&Delphi+}
    PROCEDURE DoManualRequests;
    VAR
        PR             : PRegES;
        RR             : TRegisterRec;
        Redraw         : BOOLEAN;
    BEGIN
        FillRRFromCmdLine(RR);
        NEW(PR, InitManual(RR, 'D:\SoundFx\SOUNDFX\trumpet.wav'));
        PR^.SetDemoMode;
        PR^.wFrame.ChangeHeaderString(0, ' Gen KR2 Manual Entry ', Redraw);
        IF Redraw THEN
            PR^.wFrame.UpDateFrame
        ELSE
            PR^.wFrame.DrawHeader(0);
        PR^.Process;
        DISPOSE(PR, Done);
    END;

    {---------------------}

    PROCEDURE Manual;
    BEGIN
        (*
        cleandb;
        halt(1);
        {writeln(dnslookup('207.175.252.42'));}
        *)
        DoBMTPaidUpRequests;
        DoRobotDemoRequests;
        DoManualRequests;
    END;

    {---------------------}

CONST
    SecondsPerMinute = 60;
    ScanIntervalSecs = 15 * SecondsPerMinute;

    {sleep for a while and then check for robot and BMT messages}
    {don't check during after-hours, to avoid the tada sound    }
    FUNCTION GoToSleep : TSleepMode;
    VAR
        DTR            : DateTimeRec;
        I              : LONGINT;
        C              : CHAR;
    BEGIN
        I := 0;
        REPEAT
            DosSleep(1000);
            FastWrite(Pad('Current Time:     ' + NowStringDeluxe(TRUE, TRUE), ScreenWidth), 1, 1, BlackOnWhite);
            FastWrite(Pad('Press Esc to quit; S to force scan, M to create manual reg key', ScreenWidth), ScreenHeight, 1, BlackOnWhite);

            INC(I);
            IF I > ScanIntervalSecs THEN BEGIN
                I := 1;
                CASE dayofweek(Today) OF
                    Monday,
                    Tuesday,
                    Wednesday,
                    Thursday,
                    Friday :
                        BEGIN
                            IF TimeInRange(7, 30, 0, CurrentTime, 18, 30, 0) THEN BEGIN
                                FastWrite(Pad('Last Mail Check : ' + NowStringDeluxe(TRUE, TRUE), ScreenWidth), 2, 1, BlackOnWhite);
                                Result := EScan;
                                EXIT;
                            END
                            ELSE
                                FastWrite(Pad('Last Mail Check : Weekday After Hours Mode', ScreenWidth), 2, 1, BlackOnWhite);
                        END;
                    ELSE BEGIN
                        IF TimeInRange(9, 30, 0, CurrentTime, 18, 0, 0) THEN BEGIN
                            FastWrite(Pad('Last Mail Check : ' + NowStringDeluxe(TRUE, TRUE), ScreenWidth), 2, 1, BlackOnWhite);
                            Result := EScan;
                            EXIT;
                        END
                        ELSE
                            FastWrite(Pad('Last Mail Check : Weekend After Hours Mode', ScreenWidth), 2, 1, BlackOnWhite);
                    END;
                END;
            END
            ELSE BEGIN
                IF KeyPressed THEN BEGIN
                    C := ReadKey;
                    CASE C OF
                        'm',
                        'M' :     {create a manual reg key}
                            BEGIN
                                Result := EManual;
                                BREAK;
                            END;
                        'q',
                        'Q',
                        #27 :     {quit}
                            BEGIN
                                Result := EQuit;
                                BREAK;
                            END;
                        's',
                        'S' :     {force a scan}
                            BEGIN
                                Result := EScan;
                                EXIT;
                            END;
                    END;
                END;
            END;
        UNTIL FALSE
    END;

    {---------------------}

    PROCEDURE AutoScan;
    VAR
        ScanCount      : LONGINT;
    BEGIN
        ScanCount := 0;
        REPEAT
            DoBMTPaidUpRequests;
            DoRobotDemoRequests;
            INC(ScanCount);

            FastWrite(Pad('Scan count:       ' + Long2Str(ScanCount), ScreenWidth), 3, 1, BlackOnWhite);

            CASE GoToSleep OF
                EScan : ;
                EManual :
                    DoManualRequests;
                EQuit :
                    BREAK;
            END;

        UNTIL FALSE;
    END;

    {---------------------}

    PROCEDURE Doit;
    BEGIN
        ClrScr;
        IF NOT Is_Param('C') THEN
            AutoScan
        ELSE
            CleanDB;
        ClrScr;
    END;

    {---------------------}

BEGIN
    Doit;
END.

    {---------------------}
    {---------------------}
