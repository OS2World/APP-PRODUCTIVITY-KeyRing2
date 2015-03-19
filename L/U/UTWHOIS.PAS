{.F-}
UNIT utwhois;
    {$H+}
    {&use32+}
    {$i+}

INTERFACE
USES
    Classes,
    DGLIB,
    OpDos,
    OpRoot,
    OpString,
    Os2Base,
    Os2Def,
    OS2SOCKET,
    sockin,
    aslSocket,
    aslAbsSocket,
    aslTCPSocket,
    aslAbsClient,
    netdb,
    strings;
TYPE
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


    tWhois         = Class(TAbsClient)
                     protected
                        WhoisPort      : INTEGER;
                        Cache          : ItemCacheP;
                        log : string;
                     PUBLIC
                        CONSTRUCTOR Create;
                        CONSTRUCTOR CreateDNSCache;
                        FUNCTION QueryDomainName(LookupThisGuy : STRING) : BOOLEAN;
                        FUNCTION QueryIPStrg(IPstring : STRING) : BOOLEAN;
                        FUNCTION GetNextLine(VAR L : STRING) : BOOLEAN;
                        FUNCTION TruncateDomain(Domain : STRING) : STRING;
                        FUNCTION FindWhoisHost(Name : STRING) : STRING;
                        FUNCTION ReverseDNS(Ip : STRING) : STRING;
                        property LogName : string read log write log;
                    END;


IMPLEMENTATION
USES
    KERROR,
    OpConst,
    UTIAM;

CONST
    NICHOST        = 'whois.internic.net';
    WHOIS_FILE     = 'whohosts.txt';

{--------------}

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


CONSTRUCTOR tWhois.Create;
BEGIN
    sock_init;
    INHERITED Create;
    Cache := NIL;
    // Service := 'whois';
    Service := 'ftp';
    // HostName := '';
    // WhoisPort := Socket.ResolvePort(Service);
END;

{--------------}

CONSTRUCTOR tWhois.CreateDNSCache;
BEGIN
    INHERITED Create;
    NEW(Cache, Init(500));
    Service := 'whois';
    WhoisPort := Socket.ResolvePort(Service);
END;

{--------------}

{Turns a pascal string into a pchar - reciprocal function}
{for StrPas                                              }
{Make sure that Strg is long enough for a NULL term char }
{or all hell might break loose!                          }
FUNCTION PasStr(Strg : ShortSTRING) : PCHAR;
VAR
    A              : ARRAY[0..$FF] OF CHAR ABSOLUTE Strg;
BEGIN
    A[LENGTH(Strg) + 1] := #0;    {this is a potential stack muncher}
    PasStr := @A[1];
END;

(****************************************************************************)

FUNCTION tWhois.ReverseDNS(Ip : STRING) : STRING;
VAR
    I              : LONGINT;
    PHE     : PHostEnt;
BEGIN
    I := inet_addr(PasStr(Ip));
    IF Cache <> NIL THEN BEGIN
        IF Cache^.LookFor(I, Result) THEN
            EXIT;
    END;

    PHE := SockGetHostByName(Ip);
    if phe = nil then
        result := ''
    else
        Result := StrPas(PHE^.h_name);

    IF Cache <> NIL THEN
        Cache^.Put(I, Result);
END;

{--------------}

FUNCTION tWhois.QueryDomainName(LookupThisGuy : STRING) : BOOLEAN;
VAR
    WhoisHost : STRING;
    I,
    INetAddr       : ULONG;
    _S             : AnsiString;
    Start          : LONGINT;
    T              : TEXT;
    SL             : TStringList;
BEGIN
    Result := False;
    SL := TStringList.Create;
    IF NOT CreateOrAppendTxt('whois.log', T) THEN
        EXIT;
    WRITELN(T, '>>> ' + LookupThisGuy);
    WhoisHost := FindWhoisHost(LookupThisGuy);
    WRITELN(T, '*** Host: ' + WhoisHost);
    Result := FALSE;
    MuteConnect(WHoishost);
    WRITELN('> ', LookupThisGuy);
    Start := TimeMS;
    SendCommand(LookupThisGuy);

    GetLines(SL);
    for I := 0 to sl.count-1 do
        writeln(t, sl.Strings[I]);
    System.CLOSE(T);
    sl.destroy;
    Result := TRUE;
END;

{--------------}

FUNCTION tWhois.QueryIPStrg(IPString : STRING) : BOOLEAN;
VAR
    S              : STRING;
BEGIN
    // S := GetHostByName(IPString);
    MuteConnect(IPString);
    Result := QueryDomainName(TruncateDomain(S));
END;

{--------------}

FUNCTION tWhois.GetNextLine(VAR L : STRING) : BOOLEAN;
BEGIN
END;

{--------------}

FUNCTION tWhois.TruncateDomain(Domain : STRING) : STRING;
VAR
    I,
    J              : BYTE;
BEGIN
    Result := Domain;
    FOR I := LENGTH(Domain) DOWNTO 1 DO BEGIN
        IF Domain[I] IN ['.', '@'] THEN BEGIN
            FOR J := I - 1 DOWNTO 1 DO BEGIN
                IF Domain[J] IN ['.', '@'] THEN BEGIN
                    Result := COPY(Domain, J + 1, 255);
                    EXIT;
                END;
            END;
        END;
    END;
END;

{--------------}

FUNCTION tWhois.FindWhoisHost(Name : STRING) : STRING;
VAR
    hosts          : TEXT;
    inbuf,
    S,
    hostsfile      : STRING;
    I,
    DotPos         : BYTE;
BEGIN
    Result := NICHOST;

    S := GetEnvironmentString('ETC');

    IF S = '' THEN BEGIN
        DispErrorDeluxe('No path to \ETC directory found!', 'Fix your config.sys!', TRUE, Iam);
        EXIT;
    END;

    hostsfile := AddBackSlash(S) + WHOIS_FILE;

    IF NOT ExistFile(hostsfile) THEN BEGIN
        DispErrorDeluxe('Can''t find whois hosts file as in ' + hostsfile, 'See http://dns.vrx.net/tech/rootzone/whohosts.txt to get a copy', TRUE, Iam);
        EXIT;
    END;

    DotPos := 0;

    FOR I := LENGTH(Name) DOWNTO 1 DO BEGIN
        IF Name[I] = '.' THEN BEGIN
            DotPos := I;
            BREAK;
        END;
    END;

    IF DotPos = 0 THEN BEGIN
        DispErrorDeluxe('can''t find TLD in ' + Name, '', TRUE, Iam);
        EXIT;
    END;

    { dotpos points to .dom }
    IF DotPos <> LENGTH(Name) THEN
        INC(DotPos);              {skip the dot}

    S := COPY(Name, DotPos, 255) + ':';

    ASSIGN(hosts, hostsfile);
    RESET(hosts);

    WHILE NOT EOF(hosts) DO BEGIN
        READLN(hosts, inbuf);
        IF POS(S, inbuf) = 1 THEN BEGIN
            Result := COPY(inbuf, LENGTH(S) + 1, 255);
            System.CLOSE(hosts);
            EXIT;
        END;
    END;
    System.CLOSE(hosts);
END;

{-----------------}
{.F+}

END.
