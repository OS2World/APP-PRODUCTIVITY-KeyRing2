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
* variable declarations
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{~nokeywords~}
{$I OPDEFINE.INC}
{$I NDEFINE.INC}
UNIT VARDEC;
INTERFACE
USES
    Dos,
    OpDate
    {$IFDEF VirtualPascal}
    ,USE32
    {$ENDIF}
    ;


PROCEDURE VarDecInit;

CONST
    IniVerMajor    = 2;
    IniVerMinor    = 0;
    ProgVerMajor   = 2; // keep this up to date with major prog version changes
    MaxHeap        = $FFF8;
    RecSignature   = $4929190;
    DBVerMajor     = 1;
    DBVerMinor     = 0;
    FNWidth        = 30;
    LNWidth        = 50;
    SNWidth        = 30;
    LIMWidth       = 80;
    RNWidth        = 16;
    DropDeadDate   = 146151;
    InceptDate     = 145296;      {10/22/1997}
    ESHORTSIG      = 492;
    EPRIVKEY       = 4927422;

    {KEYRING2}

    SESTRS14       = '“/‚≈Â∆Ä˝';
    SESTRN14       = 29205;
    SESTRP14       = 38890;

    {REGISTER}

    SESTRS15       = 'ï£^úÒˆ';
    SESTRN15       = 32815;
    SESTRP15       = 29564;

    {IDK, Inc. Registration}

    SESTRS16       = 'èM¯G¨,i]në¿]—ËªNÑÚ';
    SESTRN16       = 39590;
    SESTRP16       = 48018;

    {Copyright (C) 1999, IDK, Inc.}

    SESTRS17       = '≠uC"AûuSsìªè˛Wz¸'#26'öÏ«'#13'<µõ3—q›';
    SESTRN17       = 39870;
    SESTRP17       = 21744;

    {All rights reserved.}

    SESTRS18       = '⁄·R¢=f Æ9®íD¯Ê'#41'ä†f';
    SESTRN18       = 60002;
    SESTRP18       = 7744;

    {Unregistered Version - Limited to 10 secrets.}

    SESTRS19       = '∂˝6cRHŸ'#123'°60™6uÍkua\+ΩÎ'#40'?®öˆ@î- ‡òºı°‚eA∑‘p';
    SESTRN19       = 52583;
    SESTRP19       = 56302;

    {Registered Version}

    SESTRS20       = 'êç'#123' ß´√ãà,éÏ¡^¯\';
    SESTRN20       = 32215;
    SESTRP20       = 3365;

    {Registered to:}

    SESTRS21       = 'ò'#123'Q?€æ,l¢kje~';
    SESTRN21       = 52624;
    SESTRP21       = 59292;

    {Serial Number:}

    SESTRS22       = 'qVâ<˘j‡»'#41'1/ø';
    SESTRN22       = 33290;
    SESTRP22       = 22145;

    {About}

    SESTRS23       = '∞]ÓÇ˛';
    SESTRN23       = 45656;
    SESTRP23       = 41823;

    {Reverting to Demo mode.}

    SESTRS24       = 'EıÔÔõ∑,,ÌU˝ÍËJñìR'#40'BR';
    SESTRN24       = 24751;
    SESTRP24       = 44728;

    {Invalid Registration Information!}

    SESTRS25       = 'qb_û™‹íä#©Õt “£`yvÜ∂≥⁄„Ô´ív¡';
    SESTRN25       = 10296;
    SESTRP25       = 44883;

    {Custom Software Design and Consultation}

    SESTRS26       = '‘¢î^\íj⁄~2Ò¿≥¢ÿ'#40' §'#10'f’¬Qõ+å“Ù«'#10'\U7 ';
    SESTRN26       = 19564;
    SESTRP26       = 5757;

    {Credits:}

    SESTRS27       = 'ŒˆÖ';
    SESTRN27       = 43676;
    SESTRP27       = 60104;

    {Design and Coding by}

    SESTRS28       = 'Yßrjwg4Fô&TŒ7uÂ¶';
    SESTRN28       = 41548;
    SESTRP28       = 36059;

    {Kevin G. McCoy}

    SESTRS29       = '°å:≠ Øf‹í'#123'Tv';
    SESTRN29       = 6512;
    SESTRP29       = 50705;

    {(805) 492-9190 (Weekdays, 0800-1800 Pacific Time)}

    SESTRS30       = #26#39'ÒÊˆ≥H'#125#8'Á“$âD≠-◊¥cˇ¯z'#8'Ãﬁ5±cÖM»∫‘P;ùΩh8Ω';
    SESTRN30       = 54579;
    SESTRP30       = 22685;

    {http://www.idk-inc.com}

    SESTRS31       = 'NDt:Y¢'#13'ﬂg“P◊¢t∫ÿ9ñî'#39;
    SESTRN31       = 33419;
    SESTRP31       = 44937;

    {Find software support at:}

    SESTRS32       = ']ñF˙e¿ªƒ'#125'Ê∑-6Ω≈G@”ãÃ8';
    SESTRN32       = 47441;
    SESTRP32       = 44969;

    {Keyring/2 V}

    SESTRS33       = 'ß˝qlã∞ﬁ–›oÒ';
    SESTRN33       = 22019;
    SESTRP33       = 45592;

    {IDK, Inc.}

    SESTRS34       = 'Ñ˚Œ2Ô:ØŸÌ';
    SESTRN34       = 32943;
    SESTRP34       = 62578;

    {1}

    SESTRS35       = '*';
    SESTRN35       = 29376;
    SESTRP35       = 19658;

    {0}

    SESTRS36       = '+';
    SESTRN36       = 24513;
    SESTRP36       = 53548;

    {99}

    SESTRS37       = 'è';
    SESTRN37       = 45612;
    SESTRP37       = 14185;

    {200}

    SESTRS38       = '∂.ì';
    SESTRN38       = 57163;
    SESTRP38       = 19777;

    {100}

    SESTRS39       = '^∏k';
    SESTRN39       = 5340;
    SESTRP39       = 13566;

    {IDK, Inc. Registration}
    SESTRS40       = 'otA<ã£'#10'AÕQ«œL:MÓ-õ';
    SESTRN40       = 21306;
    SESTRP40       = 54706;

    {Database trial period has expired! You may create a new database.}
    SESTRS41       = '0˙Mrﬁ9∑'#123'Z™æ˙BÒ+à†`Î¡øÑú^D@íÕ˘û˚#M:j]≠6¶˝ÃÛeRo˚.N]^ÏY¥ÄP∑';
    SESTRN41       = 11278;
    SESTRP41       = 37267;

    {207}
    SESTRS42       = '™[U';
    SESTRN42       = 223;
    SESTRP42       = 9831;

    {KEYRING2.ERR}

    SESTRS43       = 'q‹àtÀÿ¯1°u•';
    SESTRN43       = 24687;
    SESTRP43       = 41623;

    {stobe fail}

    SESTRS44       = 'b≥ü›°Unœ÷|';
    SESTRN44       = 43311;
    SESTRP44       = 37641;

    {PWX lifetime fail}

    SESTRS45       = 'çΩ˛x—™æé8<“'#39'»9˜ﬂ';
    SESTRN45       = 52754;
    SESTRP45       = 6327;

    {EXE dropdead fail}

    SESTRS46       = 'Úi|¥ùÂ√ﬂú√èÃ'#26;
    SESTRN46       = 23913;
    SESTRP46       = 27348;

    {Blowfish 448 bit CBC encryption}
    SESTRS100 = #23'öõÀn¸|πœ+Ù3ÒÃ'#21'u…!'#20'=ŒV'#2'ü°áƒLq2';
    SESTRN100 = 17539;
    SESTRP100 = 18186;

    {DES 56 bit CBC encryption (export)}
    SESTRS101      = 'Ñı/√§Á'#21'”§ bRM$“AWæßV±»a'#1#8'›ÉªN"Sc4è';
    SESTRN101      = 59334;
    SESTRP101      = 5925;

    {NON ENCRYPTED VERSION! Get your encryption module at www.idk-inc.com!}
    SESTRS102      = 'k´vœó\Rò-£gÕô'#1'ÆÑ¶o'#5'háó¶ôßX#ÿs'#9'á?ó¨¥˛§€W˙'#22'„Ò'#22'vKHùÀzãö~Ω—•Ü=Ïæ€Ä&ÅÓﬁ'#22'∏1';
    SESTRN102      = 38259;
    SESTRP102      = 58805;

    {IDK-KeyRing/2}

    SESTRS238      = 'ÕŸ«?ÊfVºw„úü';
    SESTRN238      = 3738;
    SESTRP238      = 39368;


    {---------------}

    FieldSep       = '˛';

CONST
    NONAGFEATUREBIT = $1;         {inhibit nagger}
    PWXDDFEATUREBIT = $2;         {pwx dropdead}
    PAIDFEATUREBIT = $4;          {no dropdead or pwxlifetime}
    DESFEATUREBIT  = $8;          {des only - for future use}
    BLOFEATUREBIT  = $10;         {blo only - for future use}
    COMFEATUREBIT  = $20;         {committee password - for future use}

    V1FEATUREBIT   = $40;
    V2FEATUREBIT   = $80;
    V4FEATUREBIT   = $100;
    V8FEATUREBIT   = $200;
    V16FEATUREBIT  = $400;
    V32FEATUREBIT  = $800;

    {Beta testers: NONAGFEATUREBIT + today+60}
    {Demo        : PWXDDFEATUREBIT + today+30 years}
    {Paid        : NONAGFEATUREBIT + PAIDFEATUREBIT + today+30 years}


TYPE
    TCryptStyle    = (EDES, EBF, EDESCBC, EBFCBC, EUNKNOWN);

    TRegisterStat  = (ERDUMMY, ERHACK, ERDEMOLIFETIME, EPAID, EPAIDBLO, EPAIDDES, EBETA, EBETABLO, EBETADES);
    TRegQuery      = (EFALSE, ETRUE, EBAD);

    TCryptHead     = RECORD
                         ID             : STRING[30];
                         CryptStyle     : TCryptStyle;
                         VerMaj,
                         VerMin         : BYTE;
                         Seed           : OpDate.DateTimeRec;
                         PubKey         : LONGINT;
                         InceptDate     : OpDate.DateTimeRec;
                         Spare          : STRING[28];
                     END;

    TCryptMode     = (Encrypt, Decrypt);
    TMode          = (InHdr, InPath, InFile, InSplitFile);
    TParseStat     = (NotReady, Ready, ABORTREC);

    TRecType       = (ERNone, EApp, EWWW, EPin, WCombo, EOther1, EOther2);

    PRegisterRec   = ^TRegisterRec;
    PPRegisterRec  = ^PRegisterRec;
    TRegisterRec   = RECORD
                         PrgVerMajor,
                         PrgVerMinor    : WORD;
                         DemoPWXLifetime : LONGINT;
                         DropDead       : Date;
                         InstallDate    : Date;
                         FirstName      : STRING[FNWidth];
                         LastName       : STRING[LNWidth];
                         CompanyName    : STRING[LNWidth];
                         Addr1,
                         Addr2,
                         City,
                         State,
                         Zip,
                         Country        : STRING[LNWidth];
                         Email          : STRING[LNWidth];
                         FeatureBits    : LONGINT;
                         Limits         : STRING[LIMWidth];
                         RegCode        : STRING[RNWidth];
                         MaxRev         : WORD;
                         {$IFDEF ROBOT}
                         BuildDate      : DateTimeRec;
                         WPIName        : STRING;
                         CryptModule    : STRING[10];
                         IP             : STRING[15];
                         Domain,
                         Phone          : STRING[30];
                         Citizen        : STRING[LNWidth];
                         Agree          : BOOLEAN;
                         OrderNum       : STRING[LNWidth];
                         Qty            : LONGINT;
                         Comment        : STRING;
                         {$ENDIF}
                         {don't move or delete this - it keeps block en/decryption from messing up last real field}
                         Filler         : STRING[20];
                     END;

    TRCRec         = RECORD
                         Hdr            : TCryptHead;
                         RR             : TRegisterRec;
                         {don't move or delete this - it keeps block en/decryption from messing up last real field}
                         Filler         : STRING[20];
                     END;

    TINIRec        = RECORD
                         PrgVerMajor    : BYTE;
                         PrgVerMinor    : BYTE;
                         Grunge1        : ARRAY[1..17] OF BYTE;
                         InstallDate    : Date;
                         RegCode        : STRING[RNWidth];
                         Grunge2        : ARRAY[1..3] OF BYTE;
                         PubKey         : LONGINT;
                         Grunge5        : ARRAY[1..42] OF BYTE;
                         LastUsed       : DateTimeRec;
                         Grunge3        : ARRAY[1..6] OF BYTE;
                         DropDead       : Date;
                         Grunge4        : ARRAY[1..20] OF BYTE;
                         LastStrobe     : DateTimeRec;
                         {MaxSecrets     : LONGINT;}
                         Grunge6        : ARRAY[1..61] OF BYTE;
                         CRC            : LONGINT;
                     END;

    TRegStat       = (ENotReg, ERegCorrupt, ERegOk, ERegDropDead);

    TDataRec       = RECORD
                         Icon,
                         Description,
                         Password,
                         UserID,
                         SerialNum,
                         LastUpdate,
                         Expire,
                         URL,
                         Note           : STRING;
                     END;

    {-------------}
VAR
    {CommonFilesPath is usually the EXE location}
    {Userhome and UserPriv are normally the same}
    CommonFilesPath,              {location of shared files}
    UserHomePath,                 {location of user root (cfgs) }
    UserPrivatePath : PathStr;    {location of user generated/owned data}

    {-------------}

IMPLEMENTATION
USES
    KERROR,
    OpString,
    UTTIMDAT;

    PROCEDURE VarDecInit;
    BEGIN
        {get directory of EXE}
        CommonFilesPath := AddBackSlash(JustPathName(PARAMSTR(0)));

        {preload with startup directory}
        GETDIR(0, UserHomePath);
        UserHomePath := AddBackSlash(UserHomePath);
        IF CommonFilesPath = '' THEN
            CommonFilesPath := UserHomePath;
        {preload with startup directory}
        UserPrivatePath := UserHomePath;
        ChangeErrorLogDir(UserPrivatePath);
    END;

END.

    {-------------}
    {-------------}
