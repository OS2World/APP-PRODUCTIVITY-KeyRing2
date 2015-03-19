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
* Self sorting double linked list object.  Uses quicksort.
*
* By Kevin McCoy, CIS: 72470,1233;
*
* IDK, Inc.
* 2217 Aspenpark Ct.
* Thousand Oaks, Ca.  91362-1731  USA
*
* Released to public domain 8/94
*
* WARRANTY:
*
* UTSORT and the associated demo is provided AS IS without any warranty,
* either expressed or implied, including but not limited to fitness for
* a particular purpose.
*
*
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,T-,V-,X+,Y+}
UNIT UTSORT;

INTERFACE

USES
    OpRoot,
    OpString
    {$IFDEF VIRTUALPASCAL}
    ,USE32
    {$ENDIF}
    ;

CONST
    {$IFNDEF VIRTUALPASCAL}
    MAXCACHE       = $FFF0 DIV SIZEOF(DoubleNodePtr);
    {$ELSE}
    MAXCACHE       = $7FFFFFFF DIV SIZEOF(DoubleNodePtr);
    {$ENDIF}

TYPE
    SortDir        = (ASCENDING, Descending);
    CompProc       = FUNCTION(DNP1, DNP2 : DoubleNodePtr; Dir : SortDir) : CompareType;

    {----------------------}

    CacheArrayT    = ARRAY[1..MAXCACHE] OF DoubleNodePtr;
    CacheArrayP    = ^CacheArrayT;

    {self-sorting doublelist object}
    SortListP      = ^SortListT;
    SortListT      = OBJECT(DoubleList)
                         {init the list, with a comparison proc and a sort direction}
                         CONSTRUCTOR Init(CP : CompProc; Dir : SortDir);
                         {call this for descendent object init}
                         FUNCTION InitPrim(CP : CompProc; Dir : SortDir) : BOOLEAN;
                             {do the list sort using quicksort}
                         PROCEDURE SortList; VIRTUAL;
                             {change the comparison proc}
                         PROCEDURE ChangeCompProc(CP : CompProc; Dir : SortDir);
                             {change the sort direction}
                         PROCEDURE ChangeSortDir(Dir : SortDir);
                             {update a screen ticker and check for opr abort}
                             {override this with your own routine}
                         FUNCTION UpDateTicker : BOOLEAN; VIRTUAL;
                             {cached Nth method}
                         FUNCTION cNth(N : LONGINT) : DoubleNodePtr;
                             {-Add element to end of list}
                         PROCEDURE cAPPEND(P : DoubleNodePtr);
                             {-Insert element at start of list}
                         PROCEDURE cInsert(P : DoubleNodePtr);
                             {-Place element P into list _after_ existing element L}
                         PROCEDURE cPlace(P, L : DoubleNodePtr);
                             {-Place element P into list _before_ existing element L}
                         PROCEDURE cPlaceBefore(P, L : DoubleNodePtr);
                             {-Delete existing element in list, disposing of its contents}
                         PROCEDURE cDELETE(P : DoubleNodePtr);
                             {-Remove existing element from list without disposing of it}
                         PROCEDURE cRemove(P : DoubleNodePtr);

                         PROCEDURE InitCache;
                         PROCEDURE FillCache;
                         PROCEDURE FillCacheForward(N : LONGINT);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE KillCache;

                     PRIVATE
                             {sort direction}
                         MyDir          : SortDir;
                             {quicksort pivot point}
                         Pivot          : DoubleNodePtr;
                             {node comparison proc pointer}
                         Compare        : CompProc;
                             {current left node index}
                         CLP,
                             {current right node index}
                         CRP            : LONGINT;
                             {FALSE if ok to continue sorting}
                             {TRUE if operator wants to abort}
                         Bail           : BOOLEAN;
                             {pointers to left and right nodes, respectively}
                         I,
                         J              : DoubleNodePtr;

                             {cache of node addresses, to speed sorting}
                             {ignore cache if NIL}
                         ICP            : CacheArrayP;
                         CacheSize      : LONGINT;

                             {do the quicksort}
                         PROCEDURE Sort(L, R : LONGINT);
                             {generic node swapper used by quicksort}
                         PROCEDURE SwapNodes(VAR L, R : DoubleNodePtr; LP, Rp : LONGINT);
                     END;

    {----------------------}

IMPLEMENTATION

    {instantiate a sortlist object and init internal vars}
    CONSTRUCTOR SortListT.Init(CP : CompProc; Dir : SortDir);
    BEGIN
        IF NOT InitPrim(CP, Dir) THEN
            FAIL;
    END;

    {----------------------}

    FUNCTION SortListT.InitPrim(CP : CompProc; Dir : SortDir) : BOOLEAN;
    BEGIN
        InitPrim := FALSE;
        IF NOT DoubleList.Init THEN
            EXIT;
        Compare := CP;
        ICP := NIL;
        CacheSize := 0;
        MyDir := Dir;
        Pivot := NIL;
        CLP := 0;
        CRP := 0;
        Bail := FALSE;
        I := NIL;
        J := NIL;
        InitPrim := TRUE;
    END;

    {----------------------}

    {override this virtual method with something useful that you}
    {would like to do in the background while sorting}
    FUNCTION SortListT.UpDateTicker : BOOLEAN;
    BEGIN
        UpDateTicker := FALSE;
    END;

    {----------------------}

    {generic node swapper used by quicksort routine - works with           }
    {any node derived from doublenode object.                              }
    {Only list element linkages are changed, no memory moves or heap usage }
    PROCEDURE SortListT.SwapNodes(VAR L, R : DoubleNodePtr; LP, Rp : LONGINT);
    VAR
        OldL           : DoubleNodePtr;
    BEGIN
        {don't bother swapping if the pointers point to same node}
        IF L = R THEN
            EXIT;

        OldL := L^.dlPrev;
        Remove(L);
        Place(L, R);
        Remove(R);
        Place(R, OldL);

        {L and R pointers are now reversed, so swap them back}
        OldL := L;
        L := R;
        R := OldL;

        {if the item cache is alive, then swap the cache pointers}
        IF ICP <> NIL THEN BEGIN
            OldL := ICP^[Rp];
            ICP^[Rp] := ICP^[LP];
            ICP^[LP] := OldL;
        END;
    END;

    {----------------------}

    FUNCTION SortListT.cNth(N : LONGINT) : DoubleNodePtr;
    BEGIN
        IF (N > Size) OR (N = 0) THEN BEGIN
            cNth := NIL;
            EXIT;
        END;

        {if the itemcache is alive (non-nil) then use it}
        IF ICP <> NIL THEN
            cNth := ICP^[N]
        ELSE                      {out of memory or too many elements - use slower Nth method}
            cNth := Nth(N);
    END;

    {----------------------}

    {$S+}
    PROCEDURE SortListT.Sort(L, R : LONGINT);
    VAR
        LP,
        Rp             : LONGINT;
    BEGIN
        LP := L;
        Rp := R;
        {get pointers for left and right elements}
        I := cNth(L);
        J := cNth(R);

        {Save pivot}
        {pivot is half way between left and right}
        Pivot := cNth((L + R) SHR 1);

        {paranoia}
        IF Pivot = NIL THEN
            EXIT;

        REPEAT

            {check for ESC and update the screen in background}
            Bail := UpDateTicker;

            IF Bail THEN
                EXIT;             {user hit ESC, pop one stack level}

            {check from left to pivot point}
            WHILE Compare(I, Pivot, MyDir) = Less DO BEGIN
                I := Next(I);
                INC(LP);
            END;

            {check from right to pivot point}
            WHILE Compare(Pivot, J, MyDir) = Less DO BEGIN
                J := Prev(J);
                DEC(Rp);
            END;

            IF LP <= Rp THEN BEGIN
                {Swap elements I and J}
                SwapNodes(I, J, LP, Rp);
                I := Next(I);
                INC(LP);
                J := Prev(J);
                DEC(Rp);
            END;
        UNTIL LP > Rp;

        {recurse, if necessary}
        IF L < Rp THEN
            Sort(L, Rp);

        IF Bail THEN
            EXIT;                 {stop recursing}

        {if you don't stop recursing, we'll have to }
        {wash your object out with soap!            }

        IF LP < R THEN
            Sort(LP, R);
    END;
    {$S-}

    {----------------------}

    PROCEDURE SortListT.FillCacheForward(N : LONGINT);
    VAR
        DNP            : DoubleNodePtr;
        IX             : LONGINT;
    BEGIN
        IF (ICP = NIL) OR (Size > (CacheSize DIV SIZEOF(DoubleNodePtr))) THEN BEGIN
            InitCache;
            N := 1;
            FILLCHAR(ICP^, Size * SIZEOF(DoubleNodePtr), #0);
        END;

        IF ICP = NIL THEN
            EXIT;

        {fill cache array with pointers to each node}
        DNP := cNth(N);
        IF DNP = NIL THEN BEGIN
            DNP := Head;
            N := 1;
        END;

        IX := N;
        WHILE DNP <> NIL DO BEGIN
            ICP^[IX] := DNP;
            DNP := Next(DNP);
            INC(IX);
        END;
    END;

    {----------------------}

    PROCEDURE SortListT.FillCache;
    BEGIN
        IF ICP <> NIL THEN
            FILLCHAR(ICP^, CacheSize, #0);
        FillCacheForward(1);
    END;

    {----------------------}

    PROCEDURE SortListT.InitCache;
    BEGIN
        IF ICP <> NIL THEN
            FreeMemCheck(ICP, CacheSize);
        {create an item cache, if possible}
        {if not possible (not enough heap or too many nodes) then   }
        {SortList will use the slower element lookup method: Nth()  }
        IF Size <= MAXCACHE THEN BEGIN
            CacheSize := ROUND((SUCC(Size) * 1.2)) * SIZEOF(DoubleNodePtr); {20% pad}
            GETMEM(ICP, CacheSize);
        END
        ELSE
            ICP := NIL;
    END;

    {----------------------}

    PROCEDURE SortListT.KillCache;
    BEGIN
        {blow off the item cache, if any}
        IF ICP <> NIL THEN
            FreeMemCheck(ICP, CacheSize);
        CacheSize := 0;
        ICP := NIL;
    END;

    {----------------------}

    {-Add element to end of list}
    PROCEDURE SortListT.cAPPEND(P : DoubleNodePtr);
    BEGIN
        APPEND(P);
        FillCache;
    END;

    {----------------------}

    {-Insert element at start of list}
    PROCEDURE SortListT.cInsert(P : DoubleNodePtr);
    BEGIN
        INSERT(P);
        FillCache;
    END;

    {----------------------}

    {-Place element P into list _after_ existing element L}
    PROCEDURE SortListT.cPlace(P, L : DoubleNodePtr);
    BEGIN
        Place(P, L);
        FillCache;
    END;

    {----------------------}

    {-Place element P into list _before_ existing element L}
    PROCEDURE SortListT.cPlaceBefore(P, L : DoubleNodePtr);
    BEGIN
        PlaceBefore(P, L);
        FillCache;
    END;

    {----------------------}

    {-Delete existing element in list, disposing of its contents}
    PROCEDURE SortListT.cDELETE(P : DoubleNodePtr);
    BEGIN
        DELETE(P);
        FillCache;
    END;

    {----------------------}

    {-Remove existing element from list without disposing of it}
    PROCEDURE SortListT.cRemove(P : DoubleNodePtr);
    BEGIN
        Remove(P);
        FillCache;
    END;

    {----------------------}

    DESTRUCTOR SortListT.Done;
    BEGIN
        KillCache;
        INHERITED Done;
    END;

    {----------------------}

    {start the sort process}
    PROCEDURE SortListT.SortList;
    BEGIN
        {it takes two to tango}
        IF Size < 2 THEN
            EXIT;

        FillCache;

        {sort the list}
        Sort(1, Size);
    END;

    {----------------------}

    {change the comparison proc and the sort direction}
    PROCEDURE SortListT.ChangeCompProc(CP : CompProc; Dir : SortDir);
    BEGIN
        Compare := CP;
        MyDir := Dir;
    END;

    {----------------------}

    {change the sort direction only}
    PROCEDURE SortListT.ChangeSortDir(Dir : SortDir);
    BEGIN
        MyDir := Dir;
    END;

    {----------------------}

END.
(********************)
(********************)
