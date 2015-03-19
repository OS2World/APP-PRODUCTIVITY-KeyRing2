{ Filename:~modname~    Version:~version~     Date:~date~ ~day~, ~fullyear~  ~time~
*
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer     Description
* ~log~
*
*
* ~nokeywords~
*
* Description
* -----------
* This unit provides similar functionality to the UINI unit, yet allows
* multiple instances of IniReaders to be in operation simultaneously.  The
* functionality has been extended to allow (hopefully) faster reading of
* section oriented INI files.  The old unit repeatedly re-read the entire
* INI file, every time it looked for a new section value.  This unit takes
* the approach of reading the entire INI file once, storing the locations of
* all section headers.  When a section needs to be read, we scan a linked
* list of section names and then seek to the corresponding line in the file.
*
* Do not wrap this object in a procedural interface, as the ability to
* instantiate multiple instances of the IniReader will be lost.  We will also
* eat up more DGROUP with globals.  If you want a procedural interface, then
* use UINI...
*
****************************************************************************

}
{$A+,B-,D+,E+,F+,G-,I+,L+,N-,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT UTooIni;

INTERFACE

USES
    {$IFDEF WINDOWS}
    WINDOS,
    {$ELSE}
    Dos,
    {    URLINE,}
    {$ENDIF}
    OpRoot,
    OpConst
    {$IFDEF VirtualPascal}
    ,use32
    {$ENDIF}
    ;

CONST
    MAXSECTNAMELEN = 30;

TYPE
    SectionNodeP   = ^SectionNode;
    SectionNode    = OBJECT(SingleListNode)

                     PRIVATE

                         CONSTRUCTOR Init(Name : STRING; LN : LONGINT);
                         FUNCTION CheckName(Name : STRING) : LONGINT;
                         FUNCTION GetName : STRING;
                         FUNCTION GetLine : LONGINT;

                     PRIVATE

                         MyName         : STRING[MAXSECTNAMELEN];
                         MyLine         : LONGINT;
                     END;

    IniReaderP     = ^IniReader;
    IniReader      = OBJECT(Root)
                         CONSTRUCTOR Init(Path : PathStr; BufSize : WORD);
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE ChangeCommentChar(C : CHAR);
                         FUNCTION FindKeyString(Key1, Key2 : STRING; Default : STRING) : STRING;
                         FUNCTION FindKeyValue(Key1, Key2 : STRING; Default : LONGINT) : LONGINT;
                         FUNCTION FindKeyBoolean(Key1,
                                                 Key2           : STRING;
                                                 Match          : STRING;
                                                 Default        : BOOLEAN) : BOOLEAN;
                         FUNCTION FindKeyStringSection(Key1,
                                                       Key2           : STRING;
                                                       Section        : STRING;
                                                       Default        : STRING) : STRING;
                         FUNCTION FindKeyValueSection(Key1,
                                                      Key2           : STRING;
                                                      Section        : STRING;
                                                      Default        : LONGINT) : LONGINT;
                         FUNCTION FindKeyBooleanSection(Key1,
                                                        Key2           : STRING;
                                                        Section        : STRING;
                                                        Match          : STRING;
                                                        Default        : BOOLEAN) : BOOLEAN;

                         FUNCTION NumberOfSections : WORD;
                         FUNCTION SectionExists(Section : STRING) : BOOLEAN;
                         FUNCTION SectionHeading(Num : WORD) : STRING;
                         FUNCTION FindSection(Section : STRING) : BOOLEAN;
                         FUNCTION NextSectionItem(VAR SectionItem : STRING) : BOOLEAN;
                         PROCEDURE SetToUpCase(ForceUp : BOOLEAN);

                     PRIVATE

                         IniFile        : TEXT;
                         CurrentSection : WORD;
                         MyCommentChar  : CHAR;
                    {
                    EqualPos,
                    Word1Pos,
                    Word2Pos       : WORD;
                    }
                             {True if matching keys, false if default used}
                         MatchFound     : BOOLEAN;
                         ToUpCase       : BOOLEAN;
                         Curline,
                         LastSectLine   : LONGINT;

                         SectionList    : SingleListPtr;

                         FUNCTION SearchForSection(SecName : STRING; VAR NextSect : LONGINT) : LONGINT;
                         FUNCTION GetArgString(Strg : STRING; EqualPos : BYTE) : STRING;
                             {FUNCTION GetArgInteger(Strg:STRING; EqualPos : BYTE) : LONGINT;}


                     END;


    CreateINIMode  = (INIOVERWRITE, INIAPPEND);

    CreateIniObjPtr = ^CreateINIObj;
    CreateINIObj   = OBJECT(Root)
                         CONSTRUCTOR Init(Name : STRING; Mode : CreateINIMode);
                         DESTRUCTOR Done; virtual;
                         PROCEDURE ChangeCommentChar(C : CHAR);
                         FUNCTION PutComment(Comment : STRING) : BOOLEAN;
                         FUNCTION PutString(Tag1, Tag2 : STRING; Value : STRING) : BOOLEAN;
                         FUNCTION PutBoolean(Tag1, Tag2 : STRING; Value : BOOLEAN) : BOOLEAN;
                         FUNCTION PutValue(Tag1, Tag2 : STRING; Value : LONGINT) : BOOLEAN;
                         FUNCTION PutSection(Tag1 : STRING) : BOOLEAN;
                         FUNCTION GetLastError : WORD; VIRTUAL;
                     PRIVATE

                         MyCommentChar  : CHAR;
                         TF             : TEXT;
                         Res            : WORD;
                     END;


IMPLEMENTATION

USES
    OpString;

    (*************************************************************)

    CONSTRUCTOR SectionNode.Init(Name : STRING; LN : LONGINT);
    BEGIN
        IF NOT SingleListNode.Init THEN
            FAIL;
        MyName := Trim(Name);
        MyLine := LN;
    END;

    (*************************************************************)

    FUNCTION SectionNode.CheckName(Name : STRING) : LONGINT;
    BEGIN
        CheckName := 0;
        IF CompUCString(Name, MyName) = EQUAL THEN
            CheckName := MyLine;
    END;

    (*************************************************************)

    FUNCTION SectionNode.GetName : STRING;
    BEGIN
        GetName := MyName;
    END;

    (*************************************************************)

    FUNCTION SectionNode.GetLine : LONGINT;
    BEGIN
        GetLine := MyLine;
    END;

    (*************************************************************)

    CONSTRUCTOR IniReader.Init(Path : PathStr; BufSize : WORD);
    VAR
        CPos,
        PrevFileMode   : BYTE;
        SNP            : SectionNodeP;
        Line,
        Section        : STRING;
    BEGIN
        IF NOT Root.Init THEN
            FAIL;
        MyCommentChar := '*';

        {no sections assumed until section methods called}
        ToUpCase := TRUE;
        CurrentSection := 1;
        LastSectLine := MAXLONGINT;

        PrevFileMode := FILEMODE;

        FILEMODE := 0;

        ASSIGN(IniFile, Path);

        FILEMODE := PrevFileMode;
        {$I-}
        RESET(IniFile);
        {$I+}
        InitStatus := IORESULT;
        IF InitStatus <> 0 THEN
            FAIL;

        NEW(SectionList, Init);
        IF SectionList = NIL THEN BEGIN
            CLOSE(IniFile);
            FAIL;
        END;

        {read entire ini file, locate all section lines, }
        {creating a section node for each one            }

        {a little do-see-do to work around a urline bug}
        Curline := 0;
        WHILE NOT EOF(IniFile) DO BEGIN
            READLN(IniFile, Line);
            INC(Curline);
            Line := StUpCase(Trim(Line));
            IF Line[1] <> '*' THEN BEGIN
                IF Line[1] = '[' THEN BEGIN
                    DELETE(Line, 1, 1);
                    CPos := POS(']', Line);
                    DELETE(Line, CPos, $FF);
                    NEW(SNP, Init(Line, Curline));
                    IF SNP = NIL THEN BEGIN
                        IniReader.Done;
                        FAIL;
                    END;
                    SectionList^.APPEND(SNP);
                END;
            END;
        END;
        RESET(IniFile);
        Curline := 1
    END;

    (*************************************************************)

    PROCEDURE IniReader.ChangeCommentChar(C : CHAR);
    BEGIN
        MyCommentChar := C;
    END;

    (*************************************************************)

    DESTRUCTOR IniReader.Done;
    BEGIN
        DISPOSE(SectionList, Done);
        CLOSE(IniFile);
    END;

    (*************************************************************)

    PROCEDURE IniReader.SetToUpCase(ForceUp : BOOLEAN);
    BEGIN
        ToUpCase := ForceUp;
    END;

    (*************************************************************)

    FUNCTION IniReader.FindKeyString(Key1, Key2 : STRING; Default : STRING) : STRING;
    VAR
        Line           : STRING;
        Line1          : STRING;
        EqualPos,
        Word1Pos,
        Word2Pos       : BYTE;
    BEGIN
        Key1 := StUpCase(Key1);
        Key2 := StUpCase(Key2);
        RESET(IniFile);
        WHILE NOT EOF(IniFile) DO BEGIN
            READLN(IniFile, Line);
            Line := Trim(Line);
            Line1 := Line;
            Line := StUpCase(Line);
            IF Line[1] <> '*' THEN BEGIN
                EqualPos := POS('=', Line);
                Word1Pos := POS(Key1, Line);
                Word2Pos := 0;
                IF Key2 <> '' THEN
                    Word2Pos := POS(Key2, Line);
                IF (Word1Pos <> 0) AND
                (((Key2 <> '') AND (Word2Pos <> 0)) OR (Key2 = '')) AND
                (Word1Pos < EqualPos) AND (Word2Pos < EqualPos) THEN BEGIN
                    IF ToUpCase THEN
                        FindKeyString := GetArgString(Line, EqualPos)
                    ELSE
                        FindKeyString := GetArgString(Line1, EqualPos);
                    MatchFound := TRUE;
                    EXIT;
                END;
            END;
        END;
        MatchFound := FALSE;
        FindKeyString := Trim(Default);
    END;

    (*************************************************************)

    FUNCTION IniReader.FindKeyValue(Key1, Key2 : STRING; Default : LONGINT) : LONGINT;
    VAR
        V              : LONGINT;
        ErrLoc         : WORD;
    BEGIN
        FindKeyValue := Default;

        VAL(FindKeyString(Key1, Key2, Long2Str(Default)), V, ErrLoc);
        IF ErrLoc = 0 THEN
            FindKeyValue := V;

    END;

    (*************************************************************)

    FUNCTION IniReader.FindKeyBoolean(Key1,
                                      Key2           : STRING;
                                      Match          : STRING;
                                      Default        : BOOLEAN) : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        Strg := FindKeyString(Key1, Key2, Match);

        IF MatchFound THEN
            FindKeyBoolean := Strg = Match
        ELSE
            FindKeyBoolean := Default;
    END;

    (*************************************************************)

    {search sectinlist for matching section name.  If found, return  }
    {line number of first line of section data (SectionNameLine + 1) }
    FUNCTION IniReader.SearchForSection(SecName : STRING; VAR NextSect : LONGINT) : LONGINT;
    VAR
        NS,
        I              : WORD;
        T              : LONGINT;
    BEGIN
        SearchForSection := 0;
        NextSect := MAXLONGINT;
        SecName := Trim(SecName);
        NS := SectionList^.Size;
        FOR I := 1 TO SectionList^.Size DO BEGIN
            T := SectionNodeP(SectionList^.Nth(I))^.CheckName(SecName);
            IF T > 0 THEN BEGIN
                SearchForSection := T;
                IF I < NS THEN
                    NextSect := SectionNodeP(SectionList^.Nth(I + 1))^.GetLine;
                BREAK;
            END;
        END;
    END;

    (*************************************************************)

    FUNCTION IniReader.FindKeyStringSection(Key1,
                                            Key2           : STRING;
                                            Section        : STRING;
                                            Default        : STRING) : STRING;
    VAR
        InSection      : BOOLEAN;
        EqualPos,
        Word1Pos,
        Word2Pos,
        CPos           : BYTE;
        T              : LONGINT;
        Line           : STRING;
        {----}
        Line1          : STRING;
    BEGIN
        Key1 := StUpCase(Key1);
        Key2 := StUpCase(Key2);
        Section := StUpCase(Section);
        Default := Trim(Default);

        Curline := SearchForSection(Section, LastSectLine);
        IF Curline = 0 THEN BEGIN
            {Section name not found, so use default}
            FindKeyStringSection := Default;
            EXIT;
        END;
        RESET(IniFile);
        FOR T := 1 TO Curline DO
            READLN(IniFile, Line);

        InSection := TRUE;
        WHILE NOT EOF(IniFile) DO BEGIN
            READLN(IniFile, Line);
            INC(Curline);
            Line := Trim(Line);
            Line1 := Line;
            Line := StUpCase(Line);
            IF Line[1] <> '*' THEN BEGIN
                EqualPos := POS('=', Line);
                Word1Pos := POS(Key1, Line);
                Word2Pos := 0;
                IF Key2 <> '' THEN
                    Word2Pos := POS(Key2, Line);
                IF (Word1Pos <> 0) AND
                (((Key2 <> '') AND (Word2Pos <> 0)) OR (Key2 = '')) AND
                (Word1Pos < EqualPos) AND (Word2Pos < EqualPos) THEN BEGIN
                    IF ToUpCase THEN
                        FindKeyStringSection := GetArgString(Line, EqualPos)
                    ELSE
                        FindKeyStringSection := GetArgString(Line1, EqualPos);
                    MatchFound := TRUE;
                    EXIT;
                END;
            END;
            IF (Curline = LastSectLine) THEN
                BREAK;
        END;
        MatchFound := FALSE;
        FindKeyStringSection := Trim(Default);
    END;

    (*************************************************************)

    FUNCTION IniReader.FindKeyValueSection(Key1,
                                           Key2           : STRING;
                                           Section        : STRING;
                                           Default        : LONGINT) : LONGINT;
    VAR
        V              : LONGINT;
        ErLoc          : WORD;
    BEGIN
        FindKeyValueSection := Default;

        VAL(FindKeyStringSection(Key1, Key2, Section, Long2Str(Default)), V, ErLoc);

        IF ErLoc = 0 THEN
            FindKeyValueSection := V;
    END;

    (*************************************************************)

    FUNCTION IniReader.FindKeyBooleanSection(Key1,
                                             Key2           : STRING;
                                             Section        : STRING;
                                             Match          : STRING;
                                             Default        : BOOLEAN) : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        Strg := FindKeyStringSection(Key1, Key2, Section, Match);
        IF MatchFound THEN
            FindKeyBooleanSection := Strg = Match
        ELSE
            FindKeyBooleanSection := Default;
    END;

    (*************************************************************)

    FUNCTION IniReader.NumberOfSections : WORD;
    BEGIN
        NumberOfSections := SectionList^.Size;
    END;

    (*************************************************************)

    FUNCTION IniReader.SectionExists(Section : STRING) : BOOLEAN;
    VAR
        TCurLine,
        TLastSectLine  : LONGINT;
    BEGIN
        TCurLine := SearchForSection(Section, TLastSectLine);
        SectionExists := TCurLine > 0;
    END;

    (*************************************************************)

    FUNCTION IniReader.SectionHeading(Num : WORD) : STRING;
    BEGIN
        SectionHeading := '';
        IF (Num < 1) OR (Num > SectionList^.Size) THEN
            EXIT;
        SectionHeading := SectionNodeP(SectionList^.Nth(Num))^.GetName;
    END;

    (*************************************************************)

    FUNCTION IniReader.FindSection(Section : STRING) : BOOLEAN;
    VAR
        I              : LONGINT;
        Line           : STRING;
    BEGIN
        FindSection := FALSE;
        Curline := SearchForSection(Section, LastSectLine);
        IF Curline = 0 THEN
            EXIT;

        RESET(IniFile);

        FOR I := 1 TO Curline DO BEGIN
            READLN(IniFile, Line);
            IF EOF(IniFile) THEN
                EXIT;
        END;
        FindSection := TRUE;
    END;

    (*************************************************************)

    FUNCTION IniReader.NextSectionItem(VAR SectionItem : STRING) : BOOLEAN;
    BEGIN
        REPEAT
            READLN(IniFile, SectionItem);
            INC(Curline);
        UNTIL ((SectionItem <> '') OR EOF(IniFile));
        NextSectionItem := (Curline < LastSectLine) AND (NOT EOF(IniFile));
    END;

    (*************************************************************)

    FUNCTION IniReader.GetArgString(Strg : STRING; EqualPos : BYTE) : STRING;
    VAR
        CommentPos     : INTEGER;
    BEGIN
        IF Strg = '??' THEN
            EXIT;
        CommentPos := POS(MyCommentChar, Strg) - 2;
        IF CommentPos <= 0 THEN
            CommentPos := LENGTH(Strg);
        GetArgString := Trim(COPY(Strg, EqualPos + 1, (CommentPos - EqualPos) + 1));
    END;

    (*****************************************************************)

    CONSTRUCTOR CreateINIObj.Init(Name : STRING; Mode : CreateINIMode);
    BEGIN
        IF NOT Root.Init THEN
            FAIL;
        MyCommentChar := '*';
        {$I-}
        ASSIGN(TF, Name);
        CASE Mode OF
            INIOVERWRITE :
                REWRITE(TF);
            INIAPPEND :
                BEGIN
                     APPEND(TF);
                     Res := IORESULT;
                     IF Res = 2 THEN
                         REWRITE(TF);
                END;
        END;                      {CASE}
        Res := IORESULT;
        IF Res <> 0 THEN begin
            InitStatus := Res;
            FAIL;
        end;
        {$I+}
    END;

    (*****************************************************************)

    DESTRUCTOR CreateINIObj.Done;
    BEGIN
        CLOSE(TF);
    END;

    (*************************************************************)

    PROCEDURE CreateINIObj.ChangeCommentChar(C : CHAR);
    BEGIN
        MyCommentChar := C;
    END;

    (*************************************************************)

    FUNCTION CreateINIObj.PutComment(Comment : STRING) : BOOLEAN;
    BEGIN
        WRITELN(TF, MyCommentChar+' ' + Comment);
        Res := IORESULT;
        PutComment := Res = 0;
    END;

    (*************************************************************)

    FUNCTION CreateINIObj.PutString(Tag1, Tag2 : STRING; Value : STRING) : BOOLEAN;
        {$IFNDEF COMET}
    BEGIN
        WRITELN(TF, CharStr(' ', 5) + Tag1 + ' ' + Tag2 + ' = ' + Value);
        Res := IORESULT;
        PutString := Res = 0;
    END;
    {$ELSE}
    var
       TmpStr : String;

    BEGIN
        {$I-}
        TmpStr := Tag1;
        if Tag2 <> '' then
           TmpStr := TmpStr + ' ' + Tag2;

        WRITELN(TF, TmpStr+ '=' + Value);
        Res := IORESULT;

        PutString := Res = 0;
        {$I+}
    END;
{$ENDIF}

    (*************************************************************)

    FUNCTION CreateINIObj.PutBoolean(Tag1, Tag2 : STRING; Value : BOOLEAN) : BOOLEAN;
        {$IFNDEF COMET}
    BEGIN
        IF Value THEN
            WRITELN(TF, CharStr(' ', 5) + Tag1 + ' ' + Tag2 + ' = YES')
        ELSE
            WRITELN(TF, CharStr(' ', 5) + Tag1 + ' ' + Tag2 + ' = NO');
        Res := IORESULT;
        PutBoolean := Res = 0;
    END;
    {$ELSE}
    var
       TmpStr : String;
    BEGIN

        {$I-}
        TmpStr := Tag1;
        if Tag2 <> '' then
           TmpStr := TmpStr + ' ' + Tag2;
        IF Value THEN
            WRITELN(TF, TmpStr + '=YES')
        ELSE
            WRITELN(TF, TmpStr + '=NO');
        Res := IORESULT;
        PutBoolean := Res = 0;
        {$I+}
    end;
{$ENDIF}

    (*************************************************************)

    FUNCTION CreateINIObj.PutValue(Tag1, Tag2 : STRING; Value : LONGINT) : BOOLEAN;
        {$IFNDEF COMET}
    BEGIN
        WRITELN(TF, CharStr(' ', 5) + Tag1 + ' ' + Tag2 + ' = ' + Long2Str(Value));
        Res := IORESULT;
        PutValue := Res = 0;
    END;
    {$ELSE}
    var
       TmpStr : String;
    BEGIN

        {$I-}
        TmpStr := Tag1;
        if Tag2 <> '' then
           TmpStr := TmpStr + ' ' + Tag2;
        WRITELN(TF, TmpStr + '=' + Long2Str(Value));
        Res := IORESULT;
        PutValue := Res = 0;
    END;
        {$I+}
{$ENDIF}

    (*************************************************************)

    FUNCTION CreateINIObj.PutSection(Tag1 : STRING) : BOOLEAN;
    BEGIN
        {$I-}
        WRITELN(TF, '[' + Tag1 + ']');
        Res := IORESULT;
        PutSection := Res = 0;
        {$I+}
    END;

    (*************************************************************)

    FUNCTION CreateINIObj.GetLastError : WORD;
    BEGIN
        InitStatus := Res;
        GetLastError := Res;
    END;

    (*************************************************************)

END.
(*************************************************************)
(*************************************************************)

