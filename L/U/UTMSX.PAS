{ Filename:~modname~    Version:~version~     Date:~MNAme~ ~day~, ~fullyear~  ~time~
*
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer     Description
* ~log~
*
*
*
* ~notes~
* Description
* -----------
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
****************************************************************************

}

{$A+,B-,D+,E+,F+,G-,I+,L+,N-,O+,P-,Q+,T-,V-,X+,Y+}

UNIT UTMSX;
{$I NDEFINE.INC}
INTERFACE
USES
    DOS,
    OpRoot,
    OpString;

TYPE
    {MSX file header}
    MsgHdr         = RECORD
                         Preamble       : ARRAY[1..20] OF CHAR;
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
                         Indx          : LONGINT;
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

    MsgObjModeT = (EREAD, ECREATE, EXLT, ECLOSED);

    {the business end of this unit}
    MsgObjP        = ^MsgObj;
    MsgObj         = OBJECT(ItemCache)
                         {init for read}
                         CONSTRUCTOR Init(Lang : PathStr; CacheSize : WORD);
                         {init for MSX create}
                         CONSTRUCTOR CreateMSX(Lang, Infile : PathStr);
                         {init for MSX -> MSG translate}
                         CONSTRUCTOR UnMSX(Lang, OutFile : PathStr);
                         {shutdown}
                         DESTRUCTOR Done; VIRTUAL;
                         {get a message from MSX}
                         FUNCTION SysMsg(N : LONGINT) : STRING;
                         {switch to new file}
                         FUNCTION OpenMsgFile(Name : PathStr):BOOLEAN;
                         PROCEDURE CloseMsgFile;
                         FUNCTION CheckMsgFile:BOOLEAN;
                         Procedure SetMsgTimeout(Value: LongInt);

                         PRIVATE

                         F              : FILE;
                         H              : MsgHdr;
                         Mode           : MsgObjModeT;
                         LastCheck,
                         TimeOut        : LONGINT;

                         FUNCTION SeekToString(Ind : LONGINT) : BOOLEAN;
                     END;

    (***********************)

IMPLEMENTATION
USES
    OpConst,
    UDIALOG;

CONST
    FILEREV = '1.0';

    {translate an MSX file to a MSG file}
    CONSTRUCTOR MsgObj.UnMSX(Lang, OutFile : PathStr);
    VAR
        T              : TEXT;
        Line           : STRING;
        I              : LONGINT;
        COP            : CylonObjPtr;
    BEGIN
        Mode := EXLT;
        IF NOT Init(Lang, 0) THEN
            FAIL;
        NEW(COP, Init('Translating', 10));
        COP^.Draw;
        ASSIGN(T, OutFile);
        REWRITE(T);
        WRITELN(T, ';------------------------------;');
        WRITELN(T, '; (C)1994 NewsMaker Systems    ;');
        WRITELN(T, ';    Language message file     ;');
        WRITELN(T, ';------------------------------;');
        FOR I := 1 TO H.NumIndx DO BEGIN
            Line := LeftPadCH(Long2Str(I), '0', 6) + ' ' + #39 + SysMsg(I) + #39;
            COP^.Update;
            WRITELN(T, Line);
        END;
        DISPOSE(COP, Done);
        CLOSE(T);
    END;

    (***********************)

    {Create an MSX file from a MSG file}
    CONSTRUCTOR MsgObj.CreateMSX(Lang, Infile : PathStr);
    VAR
        T              : TEXT;
        Line,
        Strg           : STRING;
        Result,
        I,
        J              : WORD;
        StrInd,
        CurFP          : LONGINT;
        COP            : CylonObjPtr;
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
        NEW(COP, Init('Creating Lang file',10));
        COP^.Draw;
        {clean out header}
        FILLCHAR(H, SIZEOF(H), #0);
        WITH H DO BEGIN
            PutS(^M^J'NewsMaker Msg File', Preamble);
            PutS(^M^J + Lang, Language);
            PutS(^M^J+FILEREV+^Z, Revision);
            PubKey := RANDOM($FFFF); {make no two files the same}
        END;

        {open MSX file}
        ASSIGN(F, Lang);
        REWRITE(F, 1);
        {write the header}
        BLOCKWRITE(F, H, SIZEOF(H), Result);
        IF Result <> SIZEOF(H) THEN BEGIN
            InitStatus := epFatal + ecDeviceWrite;
            DISPOSE(COP, Done);
            FAIL;
        END;

        {Open the MSG file}
        ASSIGN(T, InFile);
        {$I-}
        SYSTEM.RESET(T);
        {$I+}
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            Done;
            FAIL;
        END;

        {count number of legit lines in file}
        WHILE NOT EOF(T) DO BEGIN
            READLN(T, Strg);
            COP^.UPDATE;
            Strg := Trim(Strg);
            IF Str2Long(ExtractWord(1, Strg, [' ']), StrInd) THEN
                INC(H.NumIndx);
        END;

        {move Msg file pointer back to beginning}
        SYSTEM.RESET(T);

        {Set CurFP to first avail string position}
        CurFP := SIZEOF(H) + (H.NumIndx SHL 2);

        WHILE NOT EOF(T) DO BEGIN
            {read  a line from the msg file}
            READLN(T, Strg);
            COP^.UPDATE;
            {trim mostly trailing space, so that the trailing quote is the last char}
            Strg := Trim(Strg);
            {make sure this line has an index number, put it in strind}
            IF Str2Long(ExtractWord(1, Strg, [' ']), StrInd) THEN BEGIN
                {lop off the index number and leading quote}
                Line := COPY(Strg, POS(#39, Strg)+1, $FF);
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
                BLOCKWRITE(F, CurFP, 4, Result);
                {seek to the string position}
                SEEK(F, CurFP);
                {write the crypted string}
                BLOCKWRITE(F, Line[0], LENGTH(Line) + 1, Result);
                {bump the CurrentFilePos to the next avail string position}
                INC(CurFP, Result);
            END;
        END;
        {seek to the MSX top of file}
        SEEK(F, 0);
        {rewrite the updated header}
        BLOCKWRITE(F, H, SIZEOF(H), Result);
        {clean up}
        DISPOSE(COP, Done);
    END;

    (***********************)

    {init the object for MSX read}
    {CacheSize is the max number of strings to hold in the cache}
    {cached strings are on the heap in dynamicly sized stringpointers}
    CONSTRUCTOR MsgObj.Init(Lang : PathStr; CacheSize : WORD);
    VAR
        OldFM,
        Result         : WORD;
    BEGIN
        IF NOT INHERITED Init(CacheSize) THEN
            FAIL;
        Mode := EREAD;

        {open the MSX file}
        OldFM := FileMode;
        Filemode := 0; {Read Only}
        ASSIGN(F, Lang);
        {$I-}
        SYSTEM.RESET(F, 1);
        {$I+}
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN BEGIN
            FileMode := OldFM;
            FAIL;
        END;
        {read the header}
        BLOCKREAD(F, H, SIZEOF(H), Result);
        IF Result <> SIZEOF(H) THEN BEGIN
            InitStatus := epFatal + ecDeviceRead;
            FileMode := OldFM;
            FAIL;
        END;
        FileMode := OldFM;
    END;

    (***********************)

    {shut down the object}
    DESTRUCTOR MsgObj.Done;
    BEGIN
        {kill the cache}
        INHERITED Done;
        {close the msx file}
        CLOSE(F);
    END;

    (***********************)

    {look up string in file or cache and return it}
    FUNCTION MsgObj.SysMsg(N : LONGINT) : STRING;
    VAR
        Strg           : STRING;
        J              : BYTE;
        FPos           : LONGINT;
        Result         : WORD;
    BEGIN
        SysMsg := 'Invalid Msg# ' + Long2Str(N);

        IF (N <= 0) THEN BEGIN
            InitStatus := epFatal + ecRowOutOfRange;
            EXIT;
        END;

        IF (N > H.NumIndx) OR (Mode <> EREAD) THEN BEGIN
            SysMsg := 'Attempt to read past End Of File: '+Long2Str(N);
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
            BLOCKREAD(F, Strg[0], $FF, Result);

            {seed the random number generator with this line's sequence}
            RANDSEED := N XOR H.PubKey;
            {decrypt the line}
            FOR J := 1 TO LENGTH(Strg) DO
                Strg[J] := CHAR(BYTE(Strg[J]) XOR RANDOM($FF));
        {$IFNDEF DEBUG}
            {put the line in the cache}
            Put(N, Strg);
            LastCheck := Timer;
        END;
        {$ENDIF}
        {return the line from either the cache or the file}
        SysMsg := Strg;
    END;

    (***********************)

    {cange the current language file of the initialized object}
    FUNCTION MsgObj.OpenMsgFile(Name : PathStr):BOOLEAN;
    VAR
        Result : WORD;
    BEGIN
        OpenMsgFile := FALSE;

        CASE Mode OF
            EREAD,
            ECLOSED :;
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
        Result := FileMode;
        FileMode := 0;
        SYSTEM.RESET(F, 1);
        {$I+}
        FileMode := Result;
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN
            EXIT;
        {read the header}
        BLOCKREAD(F, H, SIZEOF(H), Result);
        IF Result <> SIZEOF(H) THEN BEGIN
            InitStatus := epFatal + ecDeviceRead;
            EXIT;
        END;
        Mode := EREAD;
        LastCheck := Timer;
        OpenMsgFile := TRUE;
    END;

    (***********************)

    PROCEDURE MsgObj.CloseMsgFile;
    BEGIN
        CASE Mode OF
        EREAD :;
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

    Procedure MsgObj.SetMsgTimeout(Value: LongInt);
    BEGIN
        TimeOut := Value;
    END;

    (***********************)

    FUNCTION MsgObj.CheckMsgFile:BOOLEAN;
    BEGIN
        if Timeout = 0 then
            exit;
        {$IFNDEF DEBUG}
        if ABS(Timer - LastCheck) > Timeout then
            CloseMsgFile;
        {$ENDIF}
    END;


    (***********************)

    {Using the Index number, seek to the first byte of a string}
    FUNCTION MsgObj.SeekToString(Ind : LONGINT) : BOOLEAN;
    VAR
        I              : LONGINT;
        Result         : WORD;
    BEGIN
        SeekToString := FALSE;
        {calculate the position of the index element in the index table}
        I := SIZEOF(MsgHdr) + ((Ind - 1) SHL 2);
        {seek into the index table}
        SEEK(F, I);

        IF IORESULT <> 0 THEN
            EXIT;
        {read the string position}
        BLOCKREAD(F, I, SIZEOF(LONGINT), Result);
        IF Result <> SIZEOF(LONGINT) THEN
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
                    REMOVE(Runner);
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