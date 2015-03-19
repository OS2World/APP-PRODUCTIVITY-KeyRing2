(***************************************************************************
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
* This unit contains objects and methods used to manage enhanced
* INI files.  The enhancements include context sensitivity and implicit
* variable lists in a given scope.  This allows hierarchical organization
* of data, multiple hierarchies, and improved list management.
*
* The new INI file format is as follows:
*
* ; Comment
* CONTEXTNAME
* {
*     NESTEDCONTEXTNAME
*     { ; comment
*         VARNAME_NONLIST ; this is a single var string
*         {
*             = somevalue
*         }
*         VARNAME_LISToVARS  * this is a list
*         {
*             = first value
*             = second value
*             = third value
*         }
*     }
*     ANOTHER
*     {
*        ....
*     }
* }
*
* NEXTCONTEXT
* {
*     ...
* }
*
* Note that the curly brackets must be pair-matched; Comments may appear
* anywhere - parsing of a line terminates when a comment character (* or ;)
* is encountered.  At this time, you may not use degenerate "NAME {"
* bracketing syntax.  This thing is humoungous already and I have no interest
* in writing a look-ahead parser for this special case.  If you don't like
* the bracketing style, rewrite it yourself! So there - Nyea!
*
* In the example above, the node named:
*    ">:CONTEXTNAME:NESTEDCONTEXTNAME:VARNAME_NONLIST" = "somevalue"
*
*    The number inside the square brackets is the instance number...
*
*    ">:CONTEXTNAME:NESTEDCONTEXTNAME:VARNAME_LISToVARS"[1] = "first value"
*    ">:CONTEXTNAME:NESTEDCONTEXTNAME:VARNAME_LISToVARS"[2] = "second value"
*    ">:CONTEXTNAME:NESTEDCONTEXTNAME:VARNAME_LISToVARS"[3] = "third value"
*
* Context names may be up to 255 characters in length, and may be nested to
* any desired depth.  All memory used by the context parser (including names)
* are dynamically allocated.  Depth of nesting, breadth of tree, context name
* length and length of variables affect memory consumption.
*
* There is an implied top level context, to which all other contexts are
* attached.  The name of the top level is ">".  The Colon is the context
* node name delimiter.
*
*
* The ContextNode is central to parsing, storing and searching enhanced
* INI file data.
*
* When initialized, a ContextNode automatically attaches variables and
* child ContextNodes to itself, until the INI file contents is exhausted.
* The resulting tree (called an NTree, due to its non-binary, free-form
* connectivity) may be searched for a hierarchy of branch names.
* If only the topmost part of a branch is known, the childrens names may
* be determined by calling GetNthChild.
*
* FindNode is the search routine that returns a pointer to the target node or
* NIL if not found.
*
* GetxxxVal is probably more useful than FindNode in that after a successful
* search, the designated variable is converted into the desired type and
* returned in a passed var parameter.  If you know that the target node
* contains a list of variables, you can use GetxxxVal's Instance parameter
* to index into each list member.
*
* A context node can report the number of vars it contains via the
* NumVars method.  It reports the number of children nodes (nested contexts)
* it owns via the NumChild method.
*
* Due to the breadth-wise searching methodology used, searches are very
* fast.  The search routine determines at a very early stage wether
* a context branch is of interest.  It will not recurse into a branch that
* is not part of the named search hierarchy.
*
* Kevin McCoy 9-1993
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
*)

UNIT SECONT;

    {$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}

    (****************************************************************************)

INTERFACE

USES
    SECRPTLO,
    OpRoot,
    OpString;

TYPE

    {UNIT PRIVATE !}
    {an object to hold dynamically a allocated string}

    VarNodeP       = ^VarNode;
    VarNode        = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(V : STRING);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetVar : STRING;

                     PRIVATE

                         Value          : PCHAR;
                     END;


    {UNIT PUBLIC}
    {an object to manage and hold a level/branch of the NTree     }
    {This object can manage: child objects of the same type, data }
    {objects (varnodes), both or neither - all depending on the   }
    {contents and structure of the data file                      }

    ContextNodeP   = ^ContextNode;
    ContextNode    = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(CN : STRING; VAR Rp : TextCryptPtr; Level : BYTE);
                         DESTRUCTOR Done; VIRTUAL;

                         FUNCTION FindNode(Name : STRING) : ContextNodeP;
                         FUNCTION SearchForwardForNode(Name : STRING; CONST SearchPos : BYTE) : ContextNodeP;

                         FUNCTION GetIntVal(Name : STRING; Instance : WORD; VAR I : INTEGER) : BOOLEAN;
                         FUNCTION GetWordVal(Name : STRING; Instance : WORD; VAR W : WORD) : BOOLEAN;
                         FUNCTION GetStringVal(Name : STRING; Instance : WORD; VAR S : STRING) : BOOLEAN;
                         FUNCTION GetRealVal(Name : STRING; Instance : WORD; VAR R : Float) : BOOLEAN;
                         FUNCTION GetLongVal(Name : STRING; Instance : WORD; VAR L : LONGINT) : BOOLEAN;

                         FUNCTION GetNthVar(N : WORD) : STRING;
                         FUNCTION NumVars : WORD;

                         FUNCTION GetNthChild(N : WORD) : STRING;
                         FUNCTION GetNthChildP(N : WORD) : ContextNodeP;
                         FUNCTION NumChild : WORD;

                         FUNCTION TraverseCopy(TC : TextCryptPtr; Ignore : STRING) : BOOLEAN;

                     PRIVATE

                         Cl,
                         VL             : SingleListPtr;
                         ContName       : PCHAR;
                         CLevel         : BYTE;

                         PROCEDURE PreenLine(VAR L : STRING);
                         FUNCTION GetName : STRING;
                     END;


    (****************************************************************************)

IMPLEMENTATION

USES
    Dos,
    OpConst,
    Strings,
    UDIALOG,
    ULIB;

    {Initialize a new variable node - creates space on the heap}
    {for the new variable and stores it                        }
    CONSTRUCTOR VarNode.Init(V : STRING);
    VAR
        CPos           : BYTE;
    BEGIN
        IF NOT SingleListNode.Init THEN
            FAIL;
        CPos := POS('=', V);
        IF CPos > 0 THEN
            V := Trim(COPY(V, CPos + 1, $FF));
        Value := StrNew(PasStr(V));
        IF Value = NIL THEN BEGIN
            InitStatus := epFatal + ecBadFormat;
            FAIL;
        END;
    END;

    (****************************)

    {smudge the string value on the heap and then deallocate it}
    DESTRUCTOR VarNode.Done;
    VAR
        I              : BYTE;
    BEGIN
        FOR I := 1 TO StrLen(Value) DO
            Value[I - 1] := 'x';
        StrDispose(Value);
        Value := NIL;
    END;

    (****************************)

    {return the current string contents}
    FUNCTION VarNode.GetVar : STRING;
    BEGIN
        GetVar := StrPas(Value);
    END;

    (****************************)

    {trim off ; or * comments and any leading or trailing whitespace}
    PROCEDURE ContextNode.PreenLine(VAR L : STRING);
    VAR
        CPos           : BYTE;
    BEGIN
        CPos := POS('*', L);
        IF CPos > 0 THEN
            L[0] := CHAR(CPos - 1);

        CPos := POS(';', L);
        IF CPos > 0 THEN
            L[0] := CHAR(CPos - 1);

        L := Trim(L);
    END;

    (****************************)

    {recursive descent parser that creates NTree}
    {used for context sensitive INI file variable parsing/storage}
    CONSTRUCTOR ContextNode.Init(CN : STRING; VAR Rp : TextCryptPtr; Level : BYTE);
    VAR
        L,
        LastLine       : STRING;
        CNP            : ContextNodeP;
        VNP            : VarNodeP;
    BEGIN
        IF NOT SingleListNode.Init THEN
            FAIL;

        NEW(Cl, Init);
        IF Cl = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            FAIL;
        END;
        NEW(VL, Init);
        IF VL = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            FAIL;
        END;

        ContName := StrNew(PasStr(StUpCase(CN)));
        IF ContName = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            FAIL;
        END;

        CLevel := Level;

        INC(Level);
        LastLine := '';
        WHILE Rp^.GetLine(L) DO BEGIN
            PreenLine(L);
            IF LENGTH(L) > 0 THEN BEGIN
                CASE L[1] OF
                    '{' :         {push - begin recursion to next deeper level}
                        BEGIN
                            NEW(CNP, Init(LastLine, Rp, Level));
                            IF CNP = NIL THEN BEGIN
                                InitStatus := epFatal + ecOutOfMemory;
                                FAIL;
                            END;
                            Cl^.APPEND(CNP);
                        END;
                    '}' : EXIT;   {pop up a level}
                    ELSE BEGIN
                        IF POS('=', L) > 0 THEN BEGIN
                            {found a variable assignment, so make and append}
                            {a new variable node - VarNodes expect a leading '='}
                            NEW(VNP, Init(L));
                            IF VNP = NIL THEN BEGIN
                                InitStatus := epFatal + ecOutOfMemory;
                                FAIL;
                            END;
                            VL^.APPEND(VNP);
                        END;
                    END;
                END;              {case}
                {save the last line, in case we need it for a context name}
                LastLine := L;
            END;
        END;                      {while}

    END;

    (****************************)

    DESTRUCTOR ContextNode.Done;
    VAR
        I              : BYTE;
    BEGIN
        {recursively destroy children}
        DISPOSE(Cl, Done);
        Cl := NIL;
        {recursively attached vars}
        DISPOSE(VL, Done);
        VL := NIL;

        {smudge the heap contents}
        FOR I := 0 TO StrLen(ContName) - 1 DO
            ContName[I] := 'x';

        StrDispose(ContName);
        ContName := NIL;
    END;

    (****************************)

    {Recursive breadth-wise search of NTree for Named node }
    {Input:                                                }
    {Name = '>:PRODUCTS:NENCARD:SERVERS'                   }
    {Output:                                               }
    {Pointer to matching node or NIL, if not found         }
    {                                                      }
    { '>:' is the top level of the NTree - you have to     }
    { start there                                          }

    FUNCTION ContextNode.FindNode(Name : STRING) : ContextNodeP;
    VAR
        I              : WORD;
        CNP            : ContextNodeP;
        SLev           : STRING;
    BEGIN
        FindNode := NIL;
        {Extract THIS level of the NTree path}
        SLev := ExtractWord(CLevel, Name, [':']);
        {If THIS NTree context name matches the level in the search path}
        IF CompUCString(SLev, StrPas(ContName)) = EQUAL THEN BEGIN
            IF WordCount(Name, [':']) > CLevel THEN BEGIN {needs deeper search}
                FOR I := 1 TO Cl^.Size DO BEGIN
                    CNP := ContextNodeP(Cl^.Nth(I))^.FindNode(Name);
                    IF CNP <> NIL THEN BEGIN
                        FindNode := CNP; {found matching child}
                        EXIT;
                    END;
                END;              {for}
            END
            ELSE BEGIN
                FindNode := @Self; {eureka!}
                EXIT;
            END;
        END;
    END;

    (****************************)

    {start a search from somewhere other than the NTree root}
    FUNCTION ContextNode.SearchForwardForNode(Name : STRING; CONST SearchPos : BYTE) : ContextNodeP;
    VAR
        I              : WORD;
        CNP            : ContextNodeP;
        SLev           : STRING;
    BEGIN
        SearchForwardForNode := NIL;
        {Extract THIS level of the NTree path}
        IF SearchPos <= WordCount(Name, [':']) THEN
            SLev := ExtractWord(SearchPos, Name, [':'])
        ELSE                      {possibly at terminal node, so pop a level in search path}
            SLev := ExtractWord(SearchPos - 1, Name, [':']);

        {are we there yet?}
        IF CompUCString(SLev, StrPas(ContName)) = EQUAL THEN BEGIN
            SearchForwardForNode := @Self; {eureka!}
            EXIT;
        END;

        {not there yet, so search child branches}
        FOR I := 1 TO Cl^.Size DO BEGIN
            IF CompUCString(SLev, ContextNodeP(Cl^.Nth(I))^.GetName) = EQUAL THEN BEGIN
                {recurse into the next level}
                CNP := ContextNodeP(Cl^.Nth(I))^.SearchForwardForNode(Name, SearchPos + 1);
                IF CNP <> NIL THEN BEGIN
                    SearchForwardForNode := CNP; {found matching child}
                    EXIT;
                END;
            END;
        END;

    END;

    (****************************)

    FUNCTION ContextNode.GetIntVal(Name : STRING; Instance : WORD; VAR I : INTEGER) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetIntVal := FALSE;
        CNP := FindNode('>:' + Name);
        IF CNP = NIL THEN
            EXIT;
        GetIntVal := Str2Int(CNP^.GetNthVar(Instance), I);
    END;

    (****************************)

    FUNCTION ContextNode.GetWordVal(Name : STRING; Instance : WORD; VAR W : WORD) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetWordVal := FALSE;
        CNP := FindNode('>:' + Name);
        IF CNP = NIL THEN
            EXIT;
        GetWordVal := Str2Word(CNP^.GetNthVar(Instance), W);
    END;

    (****************************)

    FUNCTION ContextNode.GetStringVal(Name : STRING; Instance : WORD; VAR S : STRING) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetStringVal := FALSE;
        CNP := FindNode('>:' + Name);
        IF CNP = NIL THEN
            EXIT;
        S := CNP^.GetNthVar(Instance);
        GetStringVal := S <> '';
    END;

    (****************************)

    FUNCTION ContextNode.GetRealVal(Name : STRING; Instance : WORD; VAR R : Float) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetRealVal := FALSE;
        CNP := FindNode('>:' + Name);
        IF CNP = NIL THEN
            EXIT;
        GetRealVal := Str2Real(CNP^.GetNthVar(Instance), R);
    END;

    (****************************)

    FUNCTION ContextNode.GetLongVal(Name : STRING; Instance : WORD; VAR L : LONGINT) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetLongVal := FALSE;
        CNP := FindNode('>:' + Name);
        IF CNP = NIL THEN
            EXIT;
        GetLongVal := Str2Long(CNP^.GetNthVar(Instance), L);
    END;

    (****************************)


    {This method traverses the entire NTree and recrypts it to the }
    {file designated by TC                                         }
    {Programmed to skip the Ignore branch                          }

    FUNCTION ContextNode.TraverseCopy(TC : TextCryptPtr; Ignore : STRING) : BOOLEAN;
    VAR
        I              : WORD;
        CNP            : ContextNodeP;
        SLev           : STRING;
    BEGIN
        TraverseCopy := FALSE;

        IF CompUCString(Ignore, StrPas(ContName)) = EQUAL THEN BEGIN
            TraverseCopy := TRUE;
            EXIT;
        END;

        {begin context}
        IF CLevel <> 1 THEN BEGIN
            IF NOT TC^.PutLine(CharStr(' ', (CLevel - 2) * 4) +
                               StrPas(ContName)) THEN
                EXIT;

            IF NOT TC^.PutLine(CharStr(' ', (CLevel - 2) * 4) + '{') THEN
                EXIT;
        END;

        {Recurse into children, if any}
        FOR I := 1 TO Cl^.Size DO BEGIN
            IF NOT ContextNodeP(Cl^.Nth(I))^.TraverseCopy(TC, Ignore) THEN
                EXIT;
        END;

        {dump data, if any}
        FOR I := 1 TO VL^.Size DO BEGIN
            IF NOT TC^.PutLine(CharStr(' ', (CLevel - 1) * 4) +
                               '= ' +
                               VarNodeP(VL^.Nth(I))^.GetVar) THEN
                EXIT;
        END;

        {close off context}
        IF CLevel <> 1 THEN BEGIN
            IF NOT TC^.PutLine(CharStr(' ', (CLevel - 2) * 4) + '}') THEN
                EXIT;
        END;

        TraverseCopy := TRUE;
    END;

    (****************************)

    {return the specified var for the current context}
    FUNCTION ContextNode.GetNthVar(N : WORD) : STRING;
    BEGIN
        GetNthVar := '';

        IF (N > VL^.Size) OR (N = 0) THEN
            EXIT;

        GetNthVar := VarNodeP(VL^.Nth(N))^.GetVar;
    END;

    (****************************)

    {return the number of vars (if any) in this context}
    FUNCTION ContextNode.NumVars : WORD;
    BEGIN
        NumVars := VL^.Size;
    END;

    (****************************)

    {return the name of this context}
    FUNCTION ContextNode.GetName : STRING;
    BEGIN
        GetName := StrPas(ContName);
    END;

    (****************************)

    {Return the Nth context attached to this context - if any}
    FUNCTION ContextNode.GetNthChild(N : WORD) : STRING;
    BEGIN
        GetNthChild := '';

        IF (N > Cl^.Size) OR (N = 0) THEN
            EXIT;

        GetNthChild := ContextNodeP(Cl^.Nth(N))^.GetName;
    END;

    (****************************)

    {Return a pointer to the Nth context attached to this context - if any}
    FUNCTION ContextNode.GetNthChildP(N : WORD) : ContextNodeP;
    BEGIN
        GetNthChildP := NIL;

        IF (N > Cl^.Size) OR (N = 0) THEN
            EXIT;

        GetNthChildP := ContextNodeP(Cl^.Nth(N));
    END;

    (****************************)

    {Return the number of attached contexts - if any}
    FUNCTION ContextNode.NumChild : WORD;
    BEGIN
        NumChild := Cl^.Size;
    END;

    (****************************)

END.                              {of unit kcont}
(****************************************************************************)
(****************************************************************************)
