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
*  Unit to read, write and translate specially encrypted MSG files.  This
*  unit is meant to be a replacement for UMSG, who's encryption algorithm
*  has been comprimized.
*
*  Note: You may want to turn off caching during debug of heap leakage.  The
*  cache will produce transient fragmentation of the heap.  Use
*  "$DEFINE DEBUG" to turn cache off.  SysMsg will still work, although
*  it will be a litte slower.
*
*  MSX File Format:
*
*  MSX consists of a header with fixed length record elements.  The preamble
*  identifies the file as being an MSX file.  The language field is for
*  future expansion.  Revision may contain an optional revision string to
*  help track file contents with the VCS.  NumIndx contains the number of
*  strings found in the file.  The PubKey field contains the starting key
*  value used to encrypt the string table elements.  Pubkey is generated at
*  random during MSX file creation.  Generally, this makes all MSX files
*  different, even if the same MSG file was used to create them.  There
*  is nothing to stop you from mass copying a master file, however.
*
*  Following the header is the Lookup table.  The lookup table is a block of
*  longints, one per string.  Each longint value is a "pointer" into the
*  string table portion of the file.  To locate a string, you find the
*  filepointer of interest, seek to the filepointer location and read in the
*  next 255 bytes found there into a pascal string.  Extra bytes are ignored.
*
*  Following the Lookup table is the string table.  Each string in the table
*  can be up to 255 characters in length and may contain any character.  It
*  is not necessary to use double quotes as this format is WYSIWYG.  Each
*  string in the lookup table is variable length and is stored end to end
*  without padding.
*
*  The strings are encrypted.  The encryption algorithm uses a public key
*  value stored in the header.  Each string is separately encrypted by XORing
*  its index number with the public key.  The resulting value is used to seed
*  the random number generator.  Each character (not the length byte) in the
*  string is XORed with a random value from $0-$FF.  The
*  encryption/decryption algorithm is reciprocal.
*
*  Strings are cached in a least recently used (LRU) cache.  When a string
*  is loaded from file or re-accessed, it is moved to the head of the cache.
*  If the cache overflows, the strings at the end of the cache (oldest) are
*  tossed.
*
*  There is a 4Gb file size limitation.  The string count limitation ranges
*  from 1.65e7 to 8.5e8 strings depending on string lengths.
*
*  Do not use this unit for high security applications as it is vulnerable to
*  attack.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}

{$IFDEF VirtualPascal}
{$A+,B-,E+,F-,G+,H-,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
{$ENDIF}

UNIT SysMsg;
    {$I NDEFINE.INC}
INTERFACE
USES
    Dos,
    OpRoot,
    {$IFDEF VirtualPascal}
    OS2DEF,
    {$ENDIF}
    OpString;

TYPE
    TGetLang       = FUNCTION : STRING;

    {MSX file header}
    MsgHdr         = RECORD
                         PreAmble       : ARRAY[1..20] OF CHAR;
                         Language       : ARRAY[1..20] OF CHAR;
                         Revision       : ARRAY[1..10] OF CHAR;
                         NumIndx        : LONGINT;
                         PubKey         : WORD;
                     END;

    {an item cache is an LRU cache.  The most recent items are               }
    {added to the head of the list.  As the list grows past the maximum size }
    {the items at the end of the list are destroyed                          }
    {reused cache elements are moved to the head of the list                 }
    ItemCacheP     = ^ItemCache;
    ItemCache      = OBJECT(SingleList)
                         CONSTRUCTOR Init(MaxSize : WORD);
                         PROCEDURE ClearCache;
                         FUNCTION LookFor(Indx : LONGINT; VAR Strg : STRING) : BOOLEAN;
                         FUNCTION Put(Indx : LONGINT; Strg : STRING) : BOOLEAN;
                             {$IFDEF SHOWSTATS}
                         FUNCTION GetHitPercent : STRING;
                         {$ENDIF}

                     PRIVATE

                         MaxItems       : WORD;
                             {$IFDEF SHOWSTATS}
                         HitCount,
                         NumLooks       : LONGINT;
                         {$ENDIF}
                     END;

    {data storage element for a cache item}
    ItemRec        = RECORD
                         Indx           : LONGINT;
                         SP             : StringPtr;
                     END;

    {a cache item object}
    ItemNodeP      = ^ItemNode;
    ItemNode       = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(Rec : LONGINT; Strg : STRING);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetIndx : LONGINT;
                         FUNCTION GetStrg : STRING;

                     PRIVATE

                         IR             : ItemRec;
                     END;


    (***********************)

    MsgObjModeT    = (EREAD, ECREATE, EXLT, ECLOSED, ERES);

    {the business end of this unit}
    MsgObjP        = ^MsgObj;
    MsgObj         = OBJECT(ItemCache)
                         {init for read}
                         CONSTRUCTOR Init(Lang : PathStr; CacheSize : WORD; Rev : STRING);

                         {$IFDEF VirtualPascal}
                         {Init for read from string resource}
                         CONSTRUCTOR InitRES(DLLName : PChar);
                         {$ENDIF}

                         {init for MSX create}
                         CONSTRUCTOR CreateMSX(Lang, InFile : PathStr; Rev : STRING);
                         {init for XSM create (creates backwards MSX for testing)}
                         CONSTRUCTOR CreateXSM(Lang, InFile : PathStr; Rev : STRING);

                             {init for MSX -> MSG translate}
                         CONSTRUCTOR UnMSX(Lang, OutFile : PathStr; LRev : STRING);
                             {shutdown}
                         DESTRUCTOR Done; VIRTUAL;
                             {get a message from MSX}
                         FUNCTION SysMsg(N : LONGINT) : STRING;

                             {$IFDEF VirtualPascal}
                             {get a message from RES resource}
                         FUNCTION SysMsgRES(N : LONGINT) : STRING;

                         {given variable length argument list V, format the resource string by inserting the arguments}
                         FUNCTION SysMsgRESfmt(N: LONGINT; const V : array of const):STRING;
                         FUNCTION ChangeLangRES(DLLName: PChar) : BOOLEAN;
                         {$ENDIF}

                             {get a message from MSX and return in in a pchar string}
                             {you must dispose of the 255 char PChar string manually}
                         FUNCTION SysMsgP(N : LONGINT) : PCHAR;

                             {switch to new file}
                         FUNCTION OpenMsgFile(Name : PathStr) : BOOLEAN;
                         PROCEDURE CloseMsgFile;
                         FUNCTION CheckMsgFile : BOOLEAN;
                         PROCEDURE SetMsgTimeout(Value : LONGINT);
                         FUNCTION GetCurLang : STRING;
                     PRIVATE

                         F              : FILE;
                         H              : MsgHdr;
                         Mode           : MsgObjModeT;
                         LastCheck,
                         TimeOut        : LONGINT;
                             {$IFDEF VirtualPascal}
                         GetLang : TGetLang;
                         MyModule : HModule; // String RES DLL Handle
                         {$ENDIF}
                         FUNCTION SeekToString(Ind : LONGINT) : BOOLEAN;
                             {$IFDEF VirtualPascal}
                         FUNCTION LoadRESDLL(DllName:PCHAR):BOOLEAN;
                         {$ENDIF}
                     END;
CONST
    BadMsg         = $FFFFFFFF;

    (***********************)

IMPLEMENTATION
USES
    DGLIB,
    KERROR,
    OpConst,
    OpCmd,
    OpDos,
    Strings,
    {$IFDEF VirtualPascal}
    OS2Base,
    SysUtils,
    {$ENDIF}
    UTIAM,
    UTTIMDAT;

CONST
    FileREV        = '1.0';

    {translate an MSX file to a MSG file}
    CONSTRUCTOR MsgObj.UnMSX(Lang, OutFile : PathStr; LRev : STRING);
    VAR
        T              : TEXT;
        Line           : STRING;
        I              : LONGINT;
        COP            : CylonP;
    BEGIN
        Mode := EXLT;
        IF NOT Init(Lang, 0, LRev) THEN
            FAIL;
        NEW(COP, Init('Translating', 10));
        COP^.Draw;
        ASSIGN(T, OutFile);
        REWRITE(T);
        WRITELN(T, ';------------------------------;');
        WRITELN(T, '; (C)1998 IDK, Inc.            ;');
        WRITELN(T, ';    Language message file     ;');
        WRITELN(T, ';------------------------------;');
        FOR I := 1 TO H.NumIndx DO BEGIN
            Line := LeftPadCh(Long2Str(I), '0', 6) + ' ' + #39 + SysMsg(I) + #39;
            COP^.UpDate;
            WRITELN(T, Line);
        END;
        DISPOSE(COP, Done);
        CLOSE(T);
    END;

    (***********************)

    PROCEDURE LogIt(FileName, Line2Log : STRING);
    VAR
        T              : TEXT;
    BEGIN
        CreateOrAppendTxt(FileName, T);
        WRITELN(T, NowStringDeluxe(TRUE, TRUE));
        WRITELN(T, Line2Log);
        CLOSE(T);
    END;


    {Create an MSX file from a MSG file}
    CONSTRUCTOR MsgObj.CreateMSX(Lang, InFile : PathStr; Rev : STRING);
    VAR
        T              : TEXT;
        Line,
        Strg           : STRING;
        {$IFDEF VirtualPascal}
        Stat : LONGINT;
        {$ELSE}
        Stat           : WORD;
        {$ENDIF}
        I,
        J              : WORD;
        L,
        StrInd,
        CurFP          : LONGINT;
        {$IFNDEF DLL}
        COP            : CylonObjPtr;
        {$ENDIF}
        PROCEDURE PutS(S : STRING; VAR T);
        BEGIN
            MOVE(S[1], T, LENGTH(S));
        END;
    BEGIN
        {init the cache ancestor}
        IF NOT INHERITED Init(0) THEN
            FAIL;

        Mode := ECREATE;

        RANDOMIZE;
        {$IFNDEF DLL}
        NEW(COP, Init('Creating Lang file', 10));
        COP^.Draw;
        {$ENDIF}
        {clean out header}
        FILLCHAR(H, SIZEOF(H), #0);
        WITH H DO BEGIN
            PutS('IDK, Inc. Msg File'^M^J, PreAmble);
            PutS(JustName(Lang) + ^M^J^Z, Language);
            MOVE(Rev[1], H.Revision, LENGTH(Rev));
            PubKey := RANDOM($FFFF); {make no two files the same}
        END;

        {open MSX file}
        ASSIGN(F, Lang);
        {$I-}
        REWRITE(F, 1);

        Stat := IORESULT;

        {$I+}
        IF Stat <> 0 THEN BEGIN
            {$IFNDEF DLL}
            DispErrorDeluxe('File error : ' + Lang, ErrorMessage(Stat), TRUE, Iam);
            {$ENDIF}
            InitStatus := Stat;
            FAIL;
        END;
        {write the header}
        BLOCKWRITE(F, H, SIZEOF(H), Stat);
        IF Stat <> SIZEOF(H) THEN BEGIN
            InitStatus := epFatal + ecDeviceWrite;
            {$IFNDEF DLL}
            DISPOSE(COP, Done);
            {$ENDIF}
            FAIL;
        END;

        {Open the MSG file}
        ASSIGN(T, InFile);
        {$I-}
        System.RESET(T);
        {$I+}
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            Done;
            FAIL;
        END;

        {init true line counter}
        L := 0;
        {count number of legit lines in file}
        WHILE NOT EOF(T) DO BEGIN
            {read a line of msg file}
            READLN(T, Strg);
            {inc line counter}
            INC(L);
            {$IFNDEF DLL}
            COP^.UpDate;
            {$ENDIF}
            Strg := Trim(Strg);
            {valid line number?}
            IF Str2Long(ExtractWord(1, Strg, [' ']), StrInd) THEN BEGIN
                {yep - inc the msg counter in the msx header}
                INC(H.NumIndx);
                {does the line number string match the current message #?}
                IF StrInd <> H.NumIndx THEN BEGIN
                    {nope!  line numbers are out of sync!  die!}
                    {$IFNDEF DLL}
                    DispErrorDeluxe('SysMsg line sync error', 'Line: ' + Long2Str(L), TRUE, Iam);
                    {$ENDIF}
                    InitStatus := 1103;
                    FAIL;
                END;
            END;
        END;

        {move Msg file pointer back to beginning}
        System.RESET(T);

        {Set CurFP to first avail string position}
        CurFP := SIZEOF(H) + (H.NumIndx SHL 2);

        WHILE NOT EOF(T) DO BEGIN
            {read  a line from the msg file}
            READLN(T, Strg);
            {$IFNDEF DLL}
            COP^.UpDate;
            {$ENDIF}
            {trim mostly trailing space, so that the trailing quote is the last char}
            Strg := Trim(Strg);
            {make sure this line has an index number, put it in strind}
            IF Str2Long(ExtractWord(1, Strg, [' ']), StrInd) THEN BEGIN
                {lop off the index number and leading quote}
                Line := COPY(Strg, POS(#39, Strg) + 1, $FF);
                {lop off the trailing quote}
                IF Line[LENGTH(Line)] = #39 THEN
                    DEC(Line[0]);

                {seed the random number generator to start a line}
                {specific key sequence}
                RANDSEED := StrInd XOR H.PubKey;
                {encrypt the line}
                FOR J := 1 TO LENGTH(Line) DO
                    Line[J] := CHAR(BYTE(Line[J]) XOR RANDOM($FF));
                {seek into the file index table}
                SEEK(F, SIZEOF(MsgHdr) + ((StrInd - 1) SHL 2));
                {write the location of the string we are about to write}
                BLOCKWRITE(F, CurFP, 4, Stat);
                {seek to the string position}
                SEEK(F, CurFP);
                {write the crypted string}
                BLOCKWRITE(F, Line[0], LENGTH(Line) + 1, Stat);
                {bump the CurrentFilePos to the next avail string position}
                INC(CurFP, Stat);
            END;
        END;
        {seek to the MSX top of file}
        SEEK(F, 0);
        {rewrite the updated header}
        BLOCKWRITE(F, H, SIZEOF(H), Stat);
        {clean up}
        {$IFNDEF DLL}
        DISPOSE(COP, Done);
        {$ENDIF}
        CLOSE(T);
    END;

    (***********************)

    {Create an XSM file from a MSG file}
    {This is for test purposes only!}
    CONSTRUCTOR MsgObj.CreateXSM(Lang, InFile : PathStr; Rev : STRING);
    VAR
        T              : TEXT;
        Line,
        Strg           : STRING;
        {$IFDEF VirtualPascal}
        Stat : LONGINT;
        {$ELSE}
        Stat           : WORD;
        {$ENDIF}
        I,
        J              : WORD;
        L,
        StrInd,
        CurFP          : LONGINT;
        COP            : CylonP;

        PROCEDURE PutS(S : STRING; VAR T);
        BEGIN
            MOVE(S[1], T, LENGTH(S));
        END;

        FUNCTION Invert(S : STRING) : STRING;
        VAR
            Strg           : STRING;
            I              : BYTE;
        BEGIN
            Strg := '';
            FOR I := LENGTH(S) DOWNTO 1 DO
                Strg := Strg + S[I];
            Invert := Strg;

        END;
    BEGIN
        {init the cache ancestor}
        IF NOT INHERITED Init(0) THEN
            FAIL;

        Mode := ECREATE;

        RANDOMIZE;
        NEW(COP, Init('Creating Gnal file', 10));
        COP^.Draw;
        {clean out header}
        FILLCHAR(H, SIZEOF(H), #0);
        WITH H DO BEGIN
            PutS(^M^J'IDK, Inc. Gsm File', PreAmble);
            PutS(^M^J + Lang, Language);
            MOVE(Rev[1], H.Revision, LENGTH(Rev));
            PubKey := RANDOM($FFFF); {make no two files the same}
        END;

        {open MSX file}
        ASSIGN(F, Lang);
        REWRITE(F, 1);
        {write the header}
        BLOCKWRITE(F, H, SIZEOF(H), Stat);
        IF Stat <> SIZEOF(H) THEN BEGIN
            InitStatus := epFatal + ecDeviceWrite;
            DISPOSE(COP, Done);
            FAIL;
        END;

        {Open the MSG file}
        ASSIGN(T, InFile);
        {$I-}
        System.RESET(T);
        {$I+}
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            Done;
            FAIL;
        END;

        {init true line counter}
        L := 0;
        {count number of legit lines in file}
        WHILE NOT EOF(T) DO BEGIN
            {read a line of msg file}
            READLN(T, Strg);
            {inc line counter}
            INC(L);
            COP^.UpDate;
            Strg := Trim(Strg);
            {valid line number?}
            IF Str2Long(ExtractWord(1, Strg, [' ']), StrInd) THEN BEGIN
                {yep - inc the msg counter in the msx header}
                INC(H.NumIndx);
                {does the line number string match the current message #?}
                IF StrInd <> H.NumIndx THEN BEGIN
                    {nope!  line numbers are out of sync!  die!}
                    {$IFNDEF DLL}
                    DispErrorDeluxe('SysMsg line sync error', 'Line: ' + Long2Str(L), TRUE, Iam);
                    {$ENDIF}
                    InitStatus := 1103;
                    FAIL;
                END;
            END;
        END;

        {move Msg file pointer back to beginning}
        System.RESET(T);

        {Set CurFP to first avail string position}
        CurFP := SIZEOF(H) + (H.NumIndx SHL 2);

        WHILE NOT EOF(T) DO BEGIN
            {read  a line from the msg file}
            READLN(T, Strg);
            COP^.UpDate;
            {trim mostly trailing space, so that the trailing quote is the last char}
            Strg := Trim(Strg);
            {make sure this line has an index number, put it in strind}
            IF Str2Long(ExtractWord(1, Strg, [' ']), StrInd) THEN BEGIN
                {lop off the index number and leading quote}
                Line := COPY(Strg, POS(#39, Strg) + 1, $FF);
                {lop off the trailing quote}
                IF Line[LENGTH(Line)] = #39 THEN
                    DEC(Line[0]);

                {seed the random number generator to start a line}
                {specific key sequence}
                RANDSEED := StrInd XOR H.PubKey;

                {dont reverse hotkey lines}
                IF POS('HOTKEY_', Line) = 0 THEN
                    Line := Invert(Line);

                {encrypt the line}
                FOR J := 1 TO LENGTH(Line) DO
                    Line[J] := CHAR(BYTE(Line[J]) XOR RANDOM($FF));
                {seek into the file index table}
                SEEK(F, SIZEOF(MsgHdr) + ((StrInd - 1) SHL 2));
                {write the location of the string we are about to write}
                BLOCKWRITE(F, CurFP, 4, Stat);
                {seek to the string position}
                SEEK(F, CurFP);
                {write the crypted string}
                BLOCKWRITE(F, Line[0], LENGTH(Line) + 1, Stat);
                {bump the CurrentFilePos to the next avail string position}
                INC(CurFP, Stat);
            END;
        END;
        {seek to the MSX top of file}
        SEEK(F, 0);
        {rewrite the updated header}
        BLOCKWRITE(F, H, SIZEOF(H), Stat);
        {clean up}
        CLOSE(T);
        DISPOSE(COP, Done);
    END;

    (***********************)

    {init the object for MSX read}
    {CacheSize is the max number of strings to hold in the cache}
    {cached strings are on the heap in dynamicly sized stringpointers}
    CONSTRUCTOR MsgObj.Init(Lang : PathStr; CacheSize : WORD; Rev : STRING);
    VAR
        I,
        OldFM          : WORD;
        {$IFDEF VirtualPascal}
        Stat : LONGINT;
        {$ELSE}
        Stat           : WORD;
        {$ENDIF}
    BEGIN
        IF NOT INHERITED Init(CacheSize) THEN
            FAIL;
        Mode := EREAD;

        {open the MSX file}
        OldFM := FILEMODE;
        FILEMODE := 0;            {Read Only}
        ASSIGN(F, ForceExtension(Lang, 'MSX'));
        {$I-}
        System.RESET(F, 1);
        {$I+}
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            FILEMODE := OldFM;
            FAIL;
        END;
        {read the header}
        BLOCKREAD(F, H, SIZEOF(H), Stat);
        IF Stat <> SIZEOF(H) THEN BEGIN
            InitStatus := epFatal + ecDeviceRead;
            FILEMODE := OldFM;
            FAIL;
        END;
        FOR I := 1 TO LENGTH(Rev) DO BEGIN
            IF Rev[I] <> H.Revision[I] THEN BEGIN
                InitStatus := 154;
                FAIL;
            END;
        END;
        FILEMODE := OldFM;
    END;

    (***********************)

    {$IFDEF VirtualPascal}
    FUNCTION MsgObj.LoadRESDLL(DllName:PCHAR):BOOLEAN;
    var
        FailedModule   : ARRAY[0..259] OF CHAR;
    BEGIN
        LoadResDLL := FALSE;

        if mymodule <> $FFFF then
            DosFreeModule(MyModule);

        InitStatus := DosLoadModule(FailedModule, SIZEOF(FailedModule), DllName, MyModule);
        if initstatus <> 0 then
            if initstatus <> 87 then
                exit;

        InitStatus := DosQueryProcAddr(MyModule, 1, NIL, @GetLang);

        LoadResDLL := InitStatus = 0;
    END;

    (***********************)

    {Init for read from string resource}
    CONSTRUCTOR MsgObj.InitRES(DLLName : PChar);
    BEGIN
        MyModule := $FFFF;
        IF NOT INHERITED Init(0) THEN
            FAIL;
        Mode := ERES;
        IF NOT LoadResDll(DllName) THEN
            FAIL;
    END;
    {$ENDIF}

    (***********************)

    {shut down the object}
    DESTRUCTOR MsgObj.Done;
    BEGIN
        {kill the cache}
        INHERITED Done;
        {close the msx file}
        IF Mode <> ERES THEN
            CLOSE(F)
            {$IFDEF VirtualPascal}
        ELSE
            DosFreeModule(MyModule);
        {$ELSE}
            ;
        {$ENDIF}
    END;

    (***********************)

    {look up string in file or cache and return it}
    FUNCTION MsgObj.SysMsg(N : LONGINT) : STRING;
    VAR
        Strg           : STRING;
        J              : BYTE;
        OldSeed        : LONGINT;
        {$IFDEF VirtualPascal}
        Stat         : LONGINT;
        {$ELSE}
        Stat           : WORD;
        {$ENDIF}
        FPos           : LONGINT;
    BEGIN
        IF N = BadMsg THEN BEGIN
            SysMsg := '';
            EXIT;
        END;

        SysMsg := 'Invalid Msg# ' + Long2Str(N);

        IF (N <= 0) THEN BEGIN
            InitStatus := epFatal + ecRowOutOfRange;
            EXIT;
        END;

        IF (N > H.NumIndx) OR (Mode <> EREAD) THEN BEGIN
            SysMsg := 'Attempt to read past End Of File: ' + Long2Str(N);
            InitStatus := epFatal + ecRowOutOfRange;
            EXIT;
        END;

        {first, look in cache for the string}
        {$IFNDEF DEBUG}
        IF NOT LookFor(N, Strg) THEN BEGIN
            {$ENDIF}
            {string not found in cache, so seek into the index table}
            IF NOT SeekToString(N) THEN BEGIN
                SysMsg := 'Seek Fail- Msg# ' + Long2Str(N);
                InitStatus := epFatal + ecSeekError;
                EXIT;
            END;

            {read in the next 255 bytes - the first byte is unencrypted}
            {length byte}
            BLOCKREAD(F, Strg[0], $FF, Stat);

            OldSeed := RANDSEED;
            {seed the random number generator with this line's sequence}
            RANDSEED := N XOR H.PubKey;
            {decrypt the line}
            FOR J := 1 TO LENGTH(Strg) DO
                Strg[J] := CHAR(BYTE(Strg[J]) XOR RANDOM($FF));
            RANDSEED := OldSeed;
            {$IFNDEF DEBUG}
            {put the line in the cache}
            Put(N, Strg);
            LastCheck := KTimer;
        END;
        {$ENDIF}
        {return the line from either the cache or the file}
        SysMsg := Strg;
    END;

    (***********************)

    {$IFDEF VirtualPascal}
    {look up string in RES resource}
    FUNCTION MsgObj.SysMsgRES(N : LONGINT) : STRING;
    VAR
        Strg : STRING;
    BEGIN
        {$IFDEF VirtualPascal}
        IF N = BadMsg THEN BEGIN
            SysMsgRES := '';
            EXIT;
        END;

        IF (N <= 0) THEN BEGIN
            InitStatus := epFatal + ecRowOutOfRange;
            EXIT;
        END;
        {$IFNDEF DEBUG}
        IF NOT LookFor(N, Strg) THEN BEGIN
        {$ENDIF}

            Strg := DLLLoadStr(MyModule, N);
            {$IFNDEF DEBUG}
            Put(N, Strg);
            {$ENDIF}
            LastCheck := KTimer;
        {$IFNDEF DEBUG}
        END;
        {$ENDIF}
        SysMsgRES := Strg;
        {$ELSE}
        SysMsgRES := SysMsg(N);
        {$ENDIF}
    END;

    (***********************)

    FUNCTION MsgObj.SysMsgRESfmt(N: LONGINT; const V : array of const):STRING;
    VAR
         S : STRING;
    BEGIN
        IF N = BadMsg THEN BEGIN
            SysMsgRESfmt := '';
            EXIT;
        END;

        IF (N <= 0) THEN BEGIN
            InitStatus := epFatal + ecRowOutOfRange;
            EXIT;
        END;

        SysMsgRESfmt := Format(SysMsgRES(N), V);
    end;

    {$ENDIF}

    {-------------------}

    {get a message from MSX and return in in a pchar string}
    {you MUST manually dispose of the PChar string!        }
    FUNCTION MsgObj.SysMsgP(N : LONGINT) : PCHAR;
    VAR
        P              : PCHAR;
        Strg           : STRING;
    BEGIN
        SysMsgP := NIL;
        IF NOT GetMemCheck(P, $FF) THEN
            EXIT;
        Strg := SysMsg(N);
        MoveFast(Strg[1], P^, ORD(Strg[0]));
        P[ORD(Strg[0])] := #0;
        SysMsgP := P;
    END;

    (***********************)

    {change the current language file of the initialized object}
    FUNCTION MsgObj.OpenMsgFile(Name : PathStr) : BOOLEAN;
    VAR
        {$IFDEF VirtualPascal}
        Stat : LONGINT;
        {$ELSE}
        Stat           : WORD;
        {$ENDIF}
    BEGIN
        OpenMsgFile := FALSE;

        CASE Mode OF
            EREAD,
            ECLOSED : ;
            ELSE BEGIN
                InitStatus := epFatal + ecNotOpen;
                EXIT;
            END;
        END;

        {blow off the cache}
        Clear;
        {close the current file}
        CLOSE(F);
        {open the new file}
        ASSIGN(F, Name);
        {$I-}
        Stat := FILEMODE;
        FILEMODE := 0;
        System.RESET(F, 1);
        {$I+}
        FILEMODE := Stat;
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN
            EXIT;
        {read the header}
        BLOCKREAD(F, H, SIZEOF(H), Stat);
        IF Stat <> SIZEOF(H) THEN BEGIN
            InitStatus := epFatal + ecDeviceRead;
            EXIT;
        END;
        Mode := EREAD;
        LastCheck := TimeMS;
        OpenMsgFile := TRUE;
    END;

    (***********************)

    PROCEDURE MsgObj.CloseMsgFile;
    BEGIN
        CASE Mode OF
            EREAD : ;
            ECLOSED :
                EXIT;
            ELSE BEGIN
                InitStatus := epFatal + ecNotOpen;
                EXIT;
            END;
        END;
        CLOSE(F);
        Mode := ECLOSED;
        Clear;
    END;

    (***********************)

    PROCEDURE MsgObj.SetMsgTimeout(Value : LONGINT);
    BEGIN
        TimeOut := Value;
    END;

    (***********************)

    FUNCTION MsgObj.CheckMsgFile : BOOLEAN;
    BEGIN
        IF TimeOut = 0 THEN
            EXIT;
        {$IFNDEF DEBUG}
        IF ABS(KTimer - LastCheck) > TimeOut THEN
            CloseMsgFile;
        {$ENDIF}
    END;


    (***********************)

    FUNCTION MsgObj.GetCurLang : STRING;
    BEGIN
        {$IFDEF VirtualPascal}
        if mode = eres then
            GetCurLang := GetLang
        else
        {$ENDIF}
        GetCurLang := StrPas(@H.Language);
    END;

    (***********************)

    {$IFDEF VirtualPascal}
    FUNCTION MsgObj.ChangeLangRES(DLLName: PChar) : BOOLEAN;
    BEGIN
        ChangeLangRes := LoadRESDLL(DllName);
    END;
    {$ENDIF}

    (***********************)

    {Using the Index number, seek to the first byte of a string}
    FUNCTION MsgObj.SeekToString(Ind : LONGINT) : BOOLEAN;
    VAR
        {$IFDEF VirtualPascal}
        Stat : LONGINT;
        {$ELSE}
        Stat           : WORD;
        {$ENDIF}
        I              : LONGINT;
    BEGIN
        SeekToString := FALSE;
        {calculate the position of the index element in the index table}
        I := SIZEOF(MsgHdr) + ((Ind - 1) SHL 2);
        {$I-}
        {seek into the index table}
        SEEK(F, I);

        IF IORESULT <> 0 THEN
            EXIT;
        {$I+}
        {read the string position}
        BLOCKREAD(F, I, SIZEOF(LONGINT), Stat);
        IF Stat <> SIZEOF(LONGINT) THEN
            EXIT;
        {seek to the string position}
        SEEK(F, I);
        SeekToString := IORESULT = 0;
    END;

    (***********************)

    {store a cache element}
    CONSTRUCTOR ItemNode.Init(Rec : LONGINT; Strg : STRING);
    BEGIN
        IF NOT SingleListNode.Init THEN
            FAIL;
        IR.Indx := Rec;
        IR.SP := StringToHeap(Strg);
        IF (IR.SP = NIL) AND (LENGTH(Strg) > 0) THEN BEGIN
            InitStatus := epWarning + ecOutOfMemory;
            FAIL;
        END;
    END;

    {--------------------------------------------------------------------}

    {kill a cache element}
    DESTRUCTOR ItemNode.Done;
    BEGIN
        DisposeString(IR.SP);
    END;

    {--------------------------------------------------------------------}

    {return the index number of a cache element}
    FUNCTION ItemNode.GetIndx : LONGINT;
    BEGIN
        GetIndx := IR.Indx;
    END;

    {--------------------------------------------------------------------}

    {return the string portion of a cache element}
    FUNCTION ItemNode.GetStrg : STRING;
    BEGIN
        GetStrg := StringFromHeap(IR.SP);
    END;

    {--------------------------------------------------------------------}

    {init a cache list}
    CONSTRUCTOR ItemCache.Init(MaxSize : WORD);
    BEGIN
        IF NOT SingleList.Init THEN
            FAIL;
        {$IFNDEF DEBUG}
        MaxItems := MaxSize;
        {$ELSE}
        MaxItems := 0;
        {$ENDIF}
        {$IFDEF SHOWSTATS}
        NumLooks := 0;
        HitCount := 0;
        {$ENDIF}
    END;

    {--------------------------------------------------------------------}

    {kill all cache elements}
    PROCEDURE ItemCache.ClearCache;
    BEGIN
        Clear;
    END;

    {--------------------------------------------------------------------}

    {$IFDEF SHOWSTATS}
    {calculate the cache hit rate}
    FUNCTION ItemCache.GetHitPercent : STRING;
    VAR
        S              : STRING;
    BEGIN
        STR((HitCount / NumLooks) * 100.0:5:2, S);
        GetHitPercent := 'Hit Rate: %' + S;
    END;
    {$ENDIF}

    {--------------------------------------------------------------------}

    {search cache for an index number; return Strg and TRUE if found}
    FUNCTION ItemCache.LookFor(Indx : LONGINT; VAR Strg : STRING) : BOOLEAN;
    VAR
        Runner         : ItemNodeP;
    BEGIN
        LookFor := FALSE;
        {$IFDEF SHOWSTATS}
        {update cache statistics}
        INC(NumLooks);
        {$ENDIF}
        Strg := '';
        {start at list head}
        Runner := ItemNodeP(Head);
        WHILE Runner <> NIL DO BEGIN
            {is this the element we want?}
            IF Runner^.GetIndx = Indx THEN BEGIN
                {yep - get the string}
                Strg := Runner^.GetStrg;
                {move runner^ to head for reprieve, if not already head}
                IF Runner <> ItemNodeP(Head) THEN BEGIN
                    {remove the element from the list}
                    Remove(Runner);
                    {place the element at list head for faster access next time}
                    INSERT(Runner);
                END;
                {update cache statistics}
                {$IFDEF SHOWSTATS}
                INC(HitCount);
                {$ENDIF}
                LookFor := TRUE;
                EXIT;
            END;
            {nope- not found, so move to next list item}
            Runner := ItemNodeP(Next(Runner));
        END;
    END;

    {--------------------------------------------------------------------}

    {put a string into the cache}
    FUNCTION ItemCache.Put(Indx : LONGINT; Strg : STRING) : BOOLEAN;
    VAR
        I              : WORD;
        INP            : ItemNodeP;
    BEGIN
        Put := FALSE;
        {if cache is full, kill the last (oldest) element in the cache list}
        IF Size + 1 > MaxItems THEN
            DELETE(Tail);
        {make a new element}
        NEW(INP, Init(Indx, Strg));
        IF INP = NIL THEN
            EXIT;
        {place it at head of list for fast access (pushes everything else back)}
        INSERT(INP);
        Put := TRUE;
    END;

    (***********************)


END.

