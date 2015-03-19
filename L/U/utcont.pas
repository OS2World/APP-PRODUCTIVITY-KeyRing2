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
*             SUBLIST
*             {
*                 = deeply nested value 1
*                 = deeply nested value 2
*             }
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
* CONTEXTNAME and NEXTCONTEXT are called "roots" since they are at the highest
* level in the hierarchy.  You can have as many roots as you like.
*
* Note that the curly brackets must be pair-matched; Comments may appear
* anywhere - parsing of a line terminates when a comment character (* or ;)
* is encountered.  At this time, you may not use degenerate "NAME {"
* bracketing syntax.  This thing is humoungous already and I have no interest
* in writing a look-ahead parser for this special case.  If you don't like
* the bracketing style, rewrite it yourself! So there - Nyea!
*
* Comment characters on an assignment line are included in the value!
*    i.e. " = *.PAS" is interpreted as *.PAS and not a blank line.
*
*
* Access of data within the tree is done with strings similar to DOS paths.
* Each context has a different hierarchical name.  I use a recursive descent
* parser to follow the path string to the desired context node.
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
* The ContextNodeT is central to parsing, storing and searching enhanced
* INI file data.
*
* When initialized, a ContextNodeT automatically attaches variables and
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
* Supports encrypted INI files, if you override the line reader/writer methods
* with appropriate functions.
*
* Kevin McCoy 9-1993
* IDK, Inc.
* released to public domain.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
*)

UNIT UTCONT;

    {$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}

    (****************************************************************************)

INTERFACE

USES
    Dos,
    OpRoot,
    OpString
    {$IFDEF VirtualPascal}
    ,USE32
    {$ENDIF}
    ;

TYPE

    NtreeReadModeT = (NTCLOSED, NTREAD, NTWRITE, NTCRYPTEDREAD, NTCRYPTEDWRITE);

    {this object gives unencrypted text file read/write ability to an}
    {Ntree object}
    NTreeReaderP   = ^NTreeReaderT;
    NTreeReaderT   = OBJECT(ROOT)
                         Mode           : NtreeReadModeT;
                         CONSTRUCTOR Init;
                         CONSTRUCTOR ReadInit(Name : PathStr);
                         CONSTRUCTOR WriteInit(Name : PathStr);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetLine(VAR Line : STRING) : BOOLEAN; VIRTUAL; {virtual so you can do encryption}
                         FUNCTION PutLine(Line : STRING) : BOOLEAN; VIRTUAL;
                     PRIVATE
                         T              : TEXT;
                     END;

    {UNIT PRIVATE !}
    {an object to hold dynamically allocated string}

    VarNodeP       = ^VarNode;
    VarNode        = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(V : STRING);
                         CONSTRUCTOR Load(S : BufIDSTREAMPTR);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetVar : STRING;
                         PROCEDURE Store(S : BufIDSTREAMPTR);
                         PROCEDURE VarNodeStream(S : BufIDSTREAMPTR);

                         FUNCTION ChangeVar(V : STRING) : BOOLEAN;
                     PRIVATE

                         Value          : StringPtr;
                     END;


    {UNIT PUBLIC}
    {an object to manage and hold a level/branch of the NTree     }
    {This object can manage: child objects of the same type, data }
    {objects (varnodes), both or neither - all depending on the   }
    {contents and structure of the data file                      }

    ContextNodeP   = ^ContextNodeT;
    ContextNodeT   = OBJECT(SingleListNode)
                         CONSTRUCTOR Init(Cn : STRING; VAR Rp : NTreeReaderP; Level : BYTE);
                         CONSTRUCTOR Load(S : BufIDSTREAMPTR);
                         CONSTRUCTOR InitPrim(Cn : STRING; Level : BYTE);
                         DESTRUCTOR Done; VIRTUAL;

                         PROCEDURE ContextNodeStream(S : BufIDSTREAMPTR);
                         PROCEDURE Store(S : BufIDSTREAMPTR);

                         FUNCTION FindNode(Name : STRING) : ContextNodeP;

                         FUNCTION GetIntVal(Name : STRING; Instance : WORD; VAR I : INTEGER) : BOOLEAN;
                         FUNCTION GetWordVal(Name : STRING; Instance : WORD; VAR W : WORD) : BOOLEAN;
                         FUNCTION GetStringVal(Name : STRING; Instance : WORD; VAR S : STRING) : BOOLEAN;
                         FUNCTION GetRealVal(Name : STRING; Instance : WORD; VAR R : Float) : BOOLEAN;
                         FUNCTION GetLongVal(Name : STRING; Instance : WORD; VAR L : LONGINT) : BOOLEAN;
                             {$IFNDEF DLL}
                         FUNCTION GetYNVal(Name : STRING; Instance : WORD; VAR V : BOOLEAN) : BOOLEAN;
                         FUNCTION GetTFVal(Name : STRING; Instance : WORD; VAR V : BOOLEAN) : BOOLEAN;
                             {$ENDIF}

                         FUNCTION GetNumVars(Name : STRING) : LONGINT;

                         FUNCTION GetNthVal(N : WORD) : STRING;
                         FUNCTION NumVars : WORD;

                         FUNCTION GetNthChild(N : WORD) : STRING;
                         FUNCTION NumChild : WORD;

                             {copy this tree to a file}
                         FUNCTION TraverseCopy(Tc : NTreeReaderP; Ignore : STRING) : BOOLEAN;
                         FUNCTION WriteFileHeader(Tc : NTreeReaderP) : BOOLEAN; VIRTUAL; {abstract!  override only}
                         FUNCTION WriteToINI(Name : STRING) : BOOLEAN; VIRTUAL;
                         FUNCTION AddColon(Name : STRING) : STRING;
                         FUNCTION PushContext(Cont, NewCont : STRING) : STRING;
                         FUNCTION PopContext(Cont : STRING) : STRING;

                             {edit tools for tree data and branches}
                         FUNCTION AddVal(Name : STRING; V : STRING) : BOOLEAN;
                         FUNCTION AddRealVal(Name : STRING; VAR V : Float) : BOOLEAN;

                             {$IFNDEF DLL}
                         FUNCTION AddTFVal(Name : STRING; VAR V : BOOLEAN) : BOOLEAN;
                         FUNCTION AddYNVal(Name : STRING; VAR V : BOOLEAN) : BOOLEAN;
                             {$ENDIF}

                         FUNCTION DelVal(Name : STRING; Instance : WORD) : BOOLEAN;
                         FUNCTION ChangeVal(Name, V : STRING; Instance : WORD) : BOOLEAN;
                         FUNCTION ChangeValStr(Name, OLD, NEW : STRING) : BOOLEAN;
                         FUNCTION DelValStr(Name, OldVal : STRING) : BOOLEAN;
                         FUNCTION SearchForVal(V : STRING) : VarNodeP;
                         FUNCTION DelBranch(Name : STRING) : BOOLEAN;
                         FUNCTION CreateBranch(Name : STRING) : BOOLEAN;
                         FUNCTION RenameContext(Name : STRING) : BOOLEAN;
                     PRIVATE

                         CL,
                         VL             : SingleListPtr;
                         ContName       : StringPtr;
                         CLevel         : BYTE;

                         PROCEDURE PreenLine(VAR L : STRING);
                         FUNCTION GetName : STRING;
                         FUNCTION InitPrimF(Cn : STRING; Level : BYTE) : BOOLEAN;
                     END;


    (****************************************************************************)

IMPLEMENTATION

USES
    {$IFNDEF DLL}
    {$IFNDEF NOTNEN}
    KERROR,
    {$ELSE}
    UERROR,
    {$ENDIF}
    MSGMGR,
    {$ENDIF DLL}
    OpDos,
    OpConst,
    Strings;

CONST                             {for saving object to stream}
    otContextNode  = 2000;
    veContextNode  = 1;
    otVarNode      = 2001;
    veVarNode      = 1;

    {---------------}

    CONSTRUCTOR NTreeReaderT.Init; {called by descendent objects}
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;
    END;

    {---------------}

    {init for text read}
    CONSTRUCTOR NTreeReaderT.ReadInit(Name : PathStr);
    VAR
        OFM            : WORD;
    BEGIN
        IF NOT NTreeReaderT.Init THEN
            FAIL;

        Mode := NTCLOSED;
        IF NOT ExistFile(Name) THEN
            FAIL;
        ASSIGN(T, Name);
        OFM := FILEMODE;
        FILEMODE := 0;
        {$I-}
        RESET(T);
        {$I+}
        InitStatus := IORESULT;
        FILEMODE := OFM;
        IF InitStatus <> 0 THEN
            FAIL;
        Mode := NTREAD;
    END;

    {---------------------}


    {init for text write}
    CONSTRUCTOR NTreeReaderT.WriteInit(Name : PathStr);
    VAR
        OFM            : WORD;
    BEGIN
        Mode := NTCLOSED;
        ASSIGN(T, Name);
        OFM := FILEMODE;
        FILEMODE := 2;
        {$I-}
        REWRITE(T);
        {$I+}
        InitStatus := IORESULT;
        FILEMODE := OFM;
        IF InitStatus <> 0 THEN
            FAIL;
        Mode := NTWRITE;
    END;

    {---------------------}

    {close up shop}
    DESTRUCTOR NTreeReaderT.Done;
    BEGIN
        INHERITED Done;
        IF Mode <> NTCLOSED THEN
            CLOSE(T);
        Mode := NTCLOSED;
    END;

    {---------------------}

    {read a CTX line of text}
    FUNCTION NTreeReaderT.GetLine(VAR Line : STRING) : BOOLEAN;
    VAR
        Res            : BOOLEAN;
    BEGIN
        GetLine := FALSE;
        IF Mode <> NTREAD THEN
            EXIT;
        READLN(T, Line);
        Res := EOF(T);
        GetLine := NOT Res;
    END;

    {---------------------}

    {write a CTX line of text}
    FUNCTION NTreeReaderT.PutLine(Line : STRING) : BOOLEAN;
    BEGIN
        PutLine := FALSE;
        IF Mode <> NTWRITE THEN
            EXIT;
        {$I-}
        WRITELN(T, Line);
        PutLine := IORESULT = 0;
        {$I+}
    END;

    {---------------------}

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
        Value := StringToHeap(V);
        IF Value = NIL THEN BEGIN
            InitStatus := epFatal + ecBadFormat;
            FAIL;
        END;
    END;

    (****************************)

    {load a node from the stream}
    CONSTRUCTOR VarNode.Load(S : BufIDSTREAMPTR);
    BEGIN
        Value := StringToHeap(S^.ReadString)
    END;

    (****************************)

    {register a varnode with the stream manager}
    PROCEDURE VarNode.VarNodeStream(S : BufIDSTREAMPTR);
    BEGIN
        WITH S^ DO BEGIN
            RegisterType(otVarNode, veVarNode, TYPEOF(VarNode),
                         @VarNode.Store,
                         @VarNode.Load);
        END;
    END;

    (****************************)

    {store a varnode to the stream}
    PROCEDURE VarNode.Store(S : BufIDSTREAMPTR);
    BEGIN
        S^.WriteString(GetVar);
    END;

    (****************************)

    {dealloc string value on the heap}
    DESTRUCTOR VarNode.Done;
    BEGIN
        FILLCHAR(Value^, LENGTH(Value^), #0); {clear the string first}
        DisposeString(Value);
    END;

    (****************************)

    {return the current string contents}
    FUNCTION VarNode.GetVar : STRING;
    BEGIN
        GetVar := StringFromHeap(Value);
    END;

    (****************************)

    {change value in place}
    FUNCTION VarNode.ChangeVar(V : STRING) : BOOLEAN;
    BEGIN
        FILLCHAR(Value^, LENGTH(Value^), #0); {clear the string first}
        DisposeString(Value);
        Value := StringToHeap(V);
        ChangeVar := (Value <> NIL) OR (LENGTH(V) = 0);
    END;

    (****************************)

    {trim off ; or * comments and any leading or trailing whitespace}
    PROCEDURE ContextNodeT.PreenLine(VAR L : STRING);
    VAR
        EPos,
        CPos           : BYTE;
    BEGIN

        L := Trim(L);

        EPos := POS('=', L);

        IF EPos <> 1 THEN BEGIN
            CASE L[1] OF
                '*',
                ';' :
                    {$IFDEF VirtualPascal}
                    {$IFOPT H+}
                    SetLength(L, 0);
                    {$ELSE}
                    L[0] := #0;
                    {$ENDIF}
                    {$ELSE}
                    L[0] := #0;
                    {$ENDIF}
            END;
        END;

    END;

    (****************************)

    {append trailing context separator}
    FUNCTION ContextNodeT.AddColon(Name : STRING) : STRING;
    BEGIN
        AddColon := Name;
        IF LENGTH(Name) = 0 THEN
            EXIT;
        IF Name[LENGTH(Name)] <> ':' THEN
            AddColon := Name + ':';
    END;

    (****************************)

    {add a new level to the context string}
    FUNCTION ContextNodeT.PushContext(Cont, NewCont : STRING) : STRING;
    BEGIN
        PushContext := AddColon(Cont) + NewCont;
    END;

    (****************************)

    {pop up a level on the context string}
    FUNCTION ContextNodeT.PopContext(Cont : STRING) : STRING;
    VAR
        Wc,
        I              : WORD;
        Strg           : STRING;
    BEGIN
        Wc := WordCount(Cont, [':']);
        Strg := '';
        FOR I := 1 TO Wc - 1 DO
            Strg := Strg + ExtractWord(I, Cont, [':']) + ':';
        IF LENGTH(Strg) > 0 THEN  {get rid of trailing colon}
            {$IFDEF VirtualPascal}
            {$IFOPT H+}
            SetLength(Strg, PRED(LENGTH(Strg)));
            {$ELSE}
            DEC(Strg[0]);
            {$ENDIF}
            {$ELSE}
            DEC(Strg[0]);
            {$ENDIF}
        PopContext := Strg;
    END;

    (****************************)

    {add a new value node to the named context}
    FUNCTION ContextNodeT.AddVal(Name : STRING; V : STRING) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
        VNP            : VarNodeP;
    BEGIN
        AddVal := FALSE;

        IF NOT CreateBranch(Name) THEN
            EXIT;

        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;

        NEW(VNP, Init(V));
        IF VNP = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            EXIT;
        END;
        CNP^.VL^.APPEND(VNP);
        AddVal := TRUE;
    END;

    (****************************)

    {return number of vars associated with named context}
    FUNCTION ContextNodeT.GetNumVars(Name : STRING) : LONGINT;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetNumVars := 0;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;
        GetNumVars := CNP^.NumVars;
    END;

    (****************************)

    {append a real number value to a named context}
    FUNCTION ContextNodeT.AddRealVal(Name : STRING; VAR V : Float) : BOOLEAN;
    BEGIN
        AddRealVal := AddVal(Name, Real2Str(V, 10, 8));
    END;

    (****************************)
    {$IFNDEF DLL}
    {append a true/false value to a named context}
    FUNCTION ContextNodeT.AddTFVal(Name : STRING; VAR V : BOOLEAN) : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        IF V THEN
            Strg := StrTrue
        ELSE
            Strg := StrFalse;
        AddTFVal := AddVal(Name, Strg);
    END;

    (****************************)

    {append a yes/no value to a named context}
    FUNCTION ContextNodeT.AddYNVal(Name : STRING; VAR V : BOOLEAN) : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        IF V THEN
            Strg := StrYes
        ELSE
            Strg := StrNo;
        AddYNVal := AddVal(Name, Strg);
    END;

    (****************************)
    {$ENDIF DLL}

    {delete a value node from the named context}
    FUNCTION ContextNodeT.DelVal(Name : STRING; Instance : WORD) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
        VNP            : VarNodeP;
    BEGIN
        DelVal := FALSE;
        CNP := FindNode(Name);    {find the sucker}
        IF CNP = NIL THEN
            EXIT;                 {oops!  does not exist!}
        VNP := VarNodeP(CNP^.VL^.Nth(Instance)); {find the var instance we want to munch}
        IF VNP <> NIL THEN
            CNP^.VL^.DELETE(VNP)  {chomp!}
        ELSE
            EXIT;                 {var node did not exist, so there is nothing to do - no error}
        DelVal := TRUE;
    END;

    (****************************)

    {change an existing value node in the named context}
    {or create a brand new context and stuff the value into it if named context does not exist}
    FUNCTION ContextNodeT.ChangeVal(Name, V : STRING; Instance : WORD) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
        VNP            : VarNodeP;
    BEGIN
        ChangeVal := FALSE;
        IF NOT CreateBranch(Name) THEN {create context if it does not exist}
            EXIT;                 {this gives us someplace to put the var}

        CNP := FindNode(Name);    {find the context}
        IF CNP = NIL THEN
            EXIT;

        VNP := VarNodeP(CNP^.VL^.Nth(Instance)); {get the old var, if it exists}

        IF VNP = NIL THEN         {nonexistant instance?}
            ChangeVal := AddVal(Name, V) {add new instance}
        ELSE
            ChangeVal := VNP^.ChangeVar(V); {modify existing in-place}
    END;

    (****************************)

    {search for a given value in a context's value list}
    {return valnodepointer if found or nil}
    FUNCTION ContextNodeT.SearchForVal(V : STRING) : VarNodeP;
    VAR
        VNP            : VarNodeP;
    BEGIN
        SearchForVal := NIL;
        VNP := VarNodeP(VL^.Head);
        WHILE VNP <> NIL DO BEGIN
            IF CompUCString(V, VNP^.GetVar) = EQUAL THEN BEGIN
                SearchForVal := VNP;
                EXIT;
            END;
            VNP := VarNodeP(VL^.Next(VNP));
        END;
    END;

    (****************************)

    {search for a branch and delete it, kill all of its children, and vars}
    FUNCTION ContextNodeT.DelBranch(Name : STRING) : BOOLEAN;
    VAR
        CNPC,
        CNPP           : ContextNodeP;
    BEGIN
        DelBranch := FALSE;

        CNPC := FindNode(Name);   {find children}
        IF CNPC = NIL THEN
            EXIT;

        CNPP := FindNode(PopContext(Name)); {find parent}
        IF CNPP = NIL THEN
            EXIT;

        CNPP^.CL^.DELETE(CNPC);   {kill children}

        DelBranch := TRUE;
    END;

    (****************************)

    FUNCTION ContextNodeT.CreateBranch(Name : STRING) : BOOLEAN;
    VAR
        I              : WORD;
        CNP            : ContextNodeP;
        SLev           : STRING;
    BEGIN
        CreateBranch := FALSE;
        SLev := ExtractWord(CLevel, Name, [':']);
        IF CompUCString(SLev, StringFromHeap(ContName)) = EQUAL THEN BEGIN
            IF WordCount(Name, [':']) > CLevel THEN BEGIN {needs deeper search}
                FOR I := 1 TO CL^.Size DO BEGIN
                    {recurse}
                    IF ContextNodeP(CL^.Nth(I))^.CreateBranch(Name) THEN BEGIN
                        CreateBranch := TRUE;
                        EXIT;
                    END;
                END;              {for}
                SLev := ExtractWord(CLevel + 1, Name, [':']);
                NEW(CNP, InitPrim(SLev, CLevel + 1));
                IF CNP = NIL THEN
                    EXIT;
                CL^.APPEND(CNP);
                CreateBranch := CNP^.CreateBranch(Name);
            END
            ELSE BEGIN
                CreateBranch := TRUE;
                EXIT;
            END;
        END;
    END;

    (****************************)

    {look for a specific value contained in a context and overwrite/add it}
    FUNCTION ContextNodeT.ChangeValStr(Name, OLD, NEW : STRING) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
        VNP            : VarNodeP;
        I              : WORD;
    BEGIN
        ChangeValStr := FALSE;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;

        VNP := CNP^.SearchForVal(OLD);
        IF VNP <> NIL THEN
            ChangeValStr := VNP^.ChangeVar(NEW)
        ELSE
            ChangeValStr := AddVal(Name, NEW); {add new instance}
    END;

    (****************************)

    {look for a value contained in a context and delete it, if found}
    FUNCTION ContextNodeT.DelValStr(Name, OldVal : STRING) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
        VNP            : VarNodeP;
    BEGIN
        DelValStr := FALSE;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;

        VNP := CNP^.SearchForVal(OldVal);
        IF VNP <> NIL THEN BEGIN
            CNP^.VL^.DELETE(VNP);
            DelValStr := TRUE;
            EXIT;
        END;
    END;

    (****************************)

    FUNCTION ContextNodeT.InitPrimF(Cn : STRING; Level : BYTE) : BOOLEAN;
    BEGIN
        InitPrimF := FALSE;
        IF NOT INHERITED Init THEN
            EXIT;

        {create an empty childlist}
        NEW(CL, Init);
        IF CL = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            EXIT;
        END;
        {create an empty varlist}
        NEW(VL, Init);
        IF VL = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            EXIT;
        END;

        {save our name}
        ContName := StringToHeap(StUpCase(Cn));
        IF ContName = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            EXIT;
        END;

        {save the level within the NTree}
        CLevel := Level;
        InitPrimF := TRUE;
    END;

    (****************************)

    CONSTRUCTOR ContextNodeT.InitPrim(Cn : STRING; Level : BYTE);
    BEGIN
        IF NOT INHERITED Init THEN
            FAIL;

        {create an empty childlist}
        NEW(CL, Init);
        IF CL = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            FAIL;
        END;
        {create an empty varlist}
        NEW(VL, Init);
        IF VL = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            FAIL;
        END;

        {save our name}
        ContName := StringToHeap(StUpCase(Cn));
        IF ContName = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            FAIL;
        END;

        {save the level within the NTree}
        CLevel := Level;

    END;

    (****************************)

    {recursive descent parser that creates NTree}
    {used for context sensitive INI file variable parsing/storage}
    CONSTRUCTOR ContextNodeT.Init(Cn : STRING; VAR Rp : NTreeReaderP; Level : BYTE);
    VAR
        L,
        LastLine       : STRING;
        CNP            : ContextNodeP;
        VNP            : VarNodeP;
    BEGIN
        IF NOT InitPrimF(Cn, Level) THEN
            FAIL;
        {move to the next deeper level}
        INC(Level);
        LastLine := '';
        {get a line of text from the CTX file}
        WHILE Rp^.GetLine(L) DO BEGIN
            {clean up and strip comments}
            PreenLine(L);
            {if you don't like my indentation style for CTX,}
            {YOU rewrite this to make it generic (and fast)!}
            IF LENGTH(L) > 0 THEN BEGIN
                CASE L[1] OF
                    '{' :         {push - begin recursion to next deeper level}
                        BEGIN
                            NEW(CNP, Init(LastLine, Rp, Level));
                            IF CNP = NIL THEN BEGIN
                                InitStatus := epFatal + ecOutOfMemory;
                                FAIL;
                            END;
                            CL^.APPEND(CNP); {append self to list}
                        END;
                    '}' :
                        EXIT;     {pop up a level}
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

    {load a context node from the stream}
    CONSTRUCTOR ContextNodeT.Load(S : BufIDSTREAMPTR);
    BEGIN
        NEW(CL, Load(S^));
        IF CL = NIL THEN
            FAIL;
        NEW(VL, Load(S^));
        IF VL = NIL THEN BEGIN
            DISPOSE(CL, Done);
            FAIL;
        END;
        ContName := StringToHeap(S^.ReadString);
        S^.READ(CLevel, SIZEOF(CLevel));
    END;

    (****************************)

    {store a context node to the stream}
    PROCEDURE ContextNodeT.Store(S : BufIDSTREAMPTR);
    BEGIN
        CL^.Store(S^);
        VL^.Store(S^);
        S^.WriteString(StringFromHeap(ContName));
        S^.WRITE(CLevel, SIZEOF(CLevel));
    END;

    (****************************)

    {register a context node with the stream manager}
    PROCEDURE ContextNodeT.ContextNodeStream(S : BufIDSTREAMPTR);
    VAR
        VNP            : VarNodeP;
    BEGIN
        NEW(VNP, Init('= x'));
        VNP^.VarNodeStream(S);
        DISPOSE(VNP, Done);
        WITH S^ DO BEGIN
            RegisterType(otContextNode, veContextNode, TYPEOF(ContextNodeT),
                         @ContextNodeT.Store,
                         @ContextNodeT.Load);
        END;
    END;

    {------------------}

    {warning!  You MUST check that there are no duplicate context names at this level}
    {prior to rename!}
    FUNCTION ContextNodeT.RenameContext(Name : STRING) : BOOLEAN;
    BEGIN
        FILLCHAR(ContName^, LENGTH(ContName^), #0); {clear the string first}
        DisposeString(ContName);
        ContName := StringToHeap(Name);
        RenameContext := ContName <> NIL;
    END;

    {------------------}

    {kill a node, all of its children and vars}
    DESTRUCTOR ContextNodeT.Done;
    BEGIN
        INHERITED Done;
        {recursively destroy children}
        DISPOSE(CL, Done);
        CL := NIL;
        {recursively destroy attached vars}
        DISPOSE(VL, Done);
        VL := NIL;

        FILLCHAR(ContName^, LENGTH(ContName^), #0); {clear the string first}
        DisposeString(ContName);
        ContName := NIL;
    END;

    (****************************)

    {Recursive breadth-wise search of NTree for Named node }
    {Input:                                                }
    { Name = '>:PRODUCTS:NENCARD:SERVERS'                  }
    {Output:                                               }
    { Pointer to matching node or NIL, if not found        }
    {                                                      }
    { '>:' is the top level of the NTree - you have to     }
    { start there                                          }

    FUNCTION ContextNodeT.FindNode(Name : STRING) : ContextNodeP;
    VAR
        I              : WORD;
        CNP            : ContextNodeP;
        SLev           : STRING;
    BEGIN
        FindNode := NIL;
        SLev := ExtractWord(CLevel, Name, [':']);
        IF CompUCString(SLev, StringFromHeap(ContName)) = EQUAL THEN BEGIN
            {are we at the correct search depth?}
            IF WordCount(Name, [':']) > CLevel THEN BEGIN {needs deeper search}
                {loop through children}
                FOR I := 1 TO CL^.Size DO BEGIN
                    {recurse into child}
                    CNP := ContextNodeP(CL^.Nth(I))^.FindNode(Name);
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

    {return the integer value of a node/instance}
    FUNCTION ContextNodeT.GetIntVal(Name : STRING; Instance : WORD; VAR I : INTEGER) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetIntVal := FALSE;
        IF Name[1] <> '>' THEN
            Name := '>:' + Name;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;
        GetIntVal := Str2int(CNP^.GetNthVal(Instance), I);
    END;

    (****************************)

    {return the word value of a node/instance}
    FUNCTION ContextNodeT.GetWordVal(Name : STRING; Instance : WORD; VAR W : WORD) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetWordVal := FALSE;
        IF Name[1] <> '>' THEN
            Name := '>:' + Name;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;
        GetWordVal := Str2Word(CNP^.GetNthVal(Instance), W);
    END;

    (****************************)

    {return the string value of a node/instance}
    FUNCTION ContextNodeT.GetStringVal(Name : STRING; Instance : WORD; VAR S : STRING) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetStringVal := FALSE;
        S := '';

        IF Name[1] <> '>' THEN
            Name := '>:' + Name;

        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;
        S := CNP^.GetNthVal(Instance);
        GetStringVal := S <> '';
    END;

    (****************************)

    {return the real value of a node/instance}
    {FLOAT is defined in Opro.  Change to REAL if it gives you hearburn}
    FUNCTION ContextNodeT.GetRealVal(Name : STRING; Instance : WORD; VAR R : Float) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetRealVal := FALSE;
        IF Name[1] <> '>' THEN
            Name := '>:' + Name;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;
        GetRealVal := Str2Real(CNP^.GetNthVal(Instance), R);
    END;

    (****************************)

    {return the longint value of a node/instance}
    FUNCTION ContextNodeT.GetLongVal(Name : STRING; Instance : WORD; VAR L : LONGINT) : BOOLEAN;
    VAR
        CNP            : ContextNodeP;
    BEGIN
        GetLongVal := FALSE;
        IF Name[1] <> '>' THEN
            Name := '>:' + Name;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;
        GetLongVal := Str2Long(CNP^.GetNthVal(Instance), L);
    END;

    (****************************)

    {$IFNDEF DLL}
    {return boolean value from Yes/No string}
    FUNCTION ContextNodeT.GetYNVal(Name : STRING; Instance : WORD; VAR V : BOOLEAN) : BOOLEAN;
    VAR
        Strg           : STRING;
        CNP            : ContextNodeP;
    BEGIN
        GetYNVal := FALSE;
        IF Name[1] <> '>' THEN
            Name := '>:' + Name;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;
        Strg := StUpCase(CNP^.GetNthVal(Instance));
        V := POS(StUpCase(StrYes), Strg) > 0;
        GetYNVal := (POS(StUpCase(StrYes), Strg) > 0) OR (POS(StUpCase(StrNo), Strg) > 0);
    END;

    (****************************)

    {return boolean value from true/false string}
    FUNCTION ContextNodeT.GetTFVal(Name : STRING; Instance : WORD; VAR V : BOOLEAN) : BOOLEAN;
    VAR
        Strg           : STRING;
        CNP            : ContextNodeP;
    BEGIN
        GetTFVal := FALSE;
        IF Name[1] <> '>' THEN
            Name := '>:' + Name;
        CNP := FindNode(Name);
        IF CNP = NIL THEN
            EXIT;
        Strg := StUpCase(CNP^.GetNthVal(Instance));
        V := POS(StUpCase(StrTrue), Strg) > 0;
        GetTFVal := (POS(StUpCase(StrTrue), Strg) > 0) OR (POS(StUpCase(StrFalse), Strg) > 0);
    END;
    {$ENDIF DLL}
    (****************************)

    {This method traverses the entire NTree and recrypts or copies it to the }
    {file designated by TC                                                   }
    {Programmed to skip the Ignore branch                                    }

    FUNCTION ContextNodeT.TraverseCopy(Tc : NTreeReaderP; Ignore : STRING) : BOOLEAN;
    VAR
        I              : WORD;
        CNP            : ContextNodeP;
        SLev           : STRING;
    BEGIN
        TraverseCopy := FALSE;

        IF CompUCString(Ignore, StringFromHeap(ContName)) = EQUAL THEN BEGIN
            TraverseCopy := TRUE;
            EXIT;
        END;

        {begin context}
        IF CLevel <> 1 THEN BEGIN
            IF NOT Tc^.PutLine(CharStr(' ', (CLevel - 2) * 4) +
                               StringFromHeap(ContName)) THEN
                EXIT;

            IF NOT Tc^.PutLine(CharStr(' ', (CLevel - 2) * 4) + '{') THEN
                EXIT;
        END;

        {Recurse into children, if any}
        FOR I := 1 TO CL^.Size DO BEGIN
            IF NOT ContextNodeP(CL^.Nth(I))^.TraverseCopy(Tc, Ignore) THEN
                EXIT;
        END;

        {dump data, if any}
        FOR I := 1 TO VL^.Size DO BEGIN
            IF NOT Tc^.PutLine(CharStr(' ', (CLevel - 1) * 4) +
                               '= ' +
                               VarNodeP(VL^.Nth(I))^.GetVar) THEN
                EXIT;
        END;

        {close off context}
        IF CLevel <> 1 THEN BEGIN
            IF NOT Tc^.PutLine(CharStr(' ', (CLevel - 2) * 4) + '}') THEN
                EXIT;
        END;

        TraverseCopy := TRUE;
    END;

    (****************************)

    {return the specified var for the current context}
    FUNCTION ContextNodeT.GetNthVal(N : WORD) : STRING;
    BEGIN
        GetNthVal := '';

        IF (N > VL^.Size) OR (N = 0) THEN
            EXIT;

        GetNthVal := VarNodeP(VL^.Nth(N))^.GetVar;
    END;

    (****************************)

    {return the number of vars (if any) in this context}
    FUNCTION ContextNodeT.NumVars : WORD;
    BEGIN
        NumVars := VL^.Size;
    END;

    (****************************)

    {return the name of this context}
    FUNCTION ContextNodeT.GetName : STRING;
    BEGIN
        GetName := StringFromHeap(ContName);
    END;

    (****************************)

    {Return the Nth context attached to this context - if any}
    FUNCTION ContextNodeT.GetNthChild(N : WORD) : STRING;
    BEGIN
        GetNthChild := '';

        IF (N > CL^.Size) OR (N = 0) THEN
            EXIT;

        GetNthChild := ContextNodeP(CL^.Nth(N))^.GetName;
    END;

    (****************************)

    {Return the number of attached contexts - if any}
    FUNCTION ContextNodeT.NumChild : WORD;
    BEGIN
        NumChild := CL^.Size;
    END;

    (****************************)

    {abstract - override this in descendent objects}
    FUNCTION ContextNodeT.WriteFileHeader(Tc : NTreeReaderP) : BOOLEAN;
    BEGIN
    END;

    (****************************)

    {dump NTree in memory to Named ini file}
    FUNCTION ContextNodeT.WriteToINI(Name : STRING) : BOOLEAN;
    VAR
        NTRP           : NTreeReaderP;
    BEGIN
        WriteToINI := FALSE;
        {instantiate an INI writer object}
        NEW(NTRP, WriteInit(Name));
        IF NTRP = NIL THEN
            EXIT;
        {write the header comments, if any}
        IF WriteFileHeader(NTRP) THEN
            WriteToINI := TraverseCopy(NTRP, ''); {write the tree to disk}
        DISPOSE(NTRP, Done);      {close and kill the writer}
    END;

END.                              {of unit utcont}

(****************************************************************************)
(****************************************************************************)

