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
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,V-,O+,F+}
{****************************************************************}
{ (C)1993 NewsMaker Systems - .INI file parser                   }
{ Provides routines to handle free form descriptor lines in      }
{ general format:                                                }
{    words of description = answer                               }
{ For example,the line:                                          }
{   Communications Port baud rate = 9600                         }
{ could be located with the function call:                       }
{  BAUDRATE := FINDKEYVALUE('PORT','RATE',9600); where the rule  }
{ is that the two keywords (PORT and RATE) must occur somewhere  }
{ to the left of the = sign, and in the specified order. Other   }
{ words in the line are ignored. The third parameter is returned }
{ if no matching line is found in the file.                      }
{                                                                }
{ April '93 - Added Section oriented routines, similar to Windows}
{             Profile I/O routines.                              }
{****************************************************************}

UNIT UINI;

INTERFACE

USES
    Dos,
    URline,
    UTOOINI,
    OpRoot;

CONST
     MAXSECTNAMELEN = 30;

    { OpenINIFile: called to open the file for input }
FUNCTION OpenINIFile(Path : PathStr) : BOOLEAN;

    { CloseINIFile: Close file }
PROCEDURE CloseIniFIle;

    { Non-Section oriented routines }

    { FindKeyString: Finds argument, returns as a string. if Default is not '', }
    { and the keys are not found, it is returned instead.                       }
    { If Default is not supplied, and the keys are not found the  function      }
    { returns ''. if Key2 is '', only Key1 is required to match.                }

FUNCTION FindKeyString(Key1, Key2 : STRING; Default : STRING) : STRING;

    { FindKeyValue. Similar to FindKeyString, but default and function result   }
    { are Long integers                                                         }

FUNCTION FindKeyValue(Key1, Key2 : STRING; Default : LONGINT) : LONGINT;

    { FindKeyBoolean. Similar to FindKeyString, but returns true or false depending }
    { on wether result matches default, sets true or false provided if no match     }

FUNCTION FindKeyBoolean(Key1, Key2     : STRING;
                        Match : STRING; Default : BOOLEAN) : BOOLEAN;

    { Section oriented routines }

    { FindKeyStringSection. This is a variant of FindKeyString which operates }
    { similarly to the Windows GetPrivateProfileString routine. It performs the }
    { same tests as FindKeyString, but the string must also be within a section }
    { headed by [SECTION]. There can be multiple occurences of the matching    }
    { key combinations, but only the one in the appropriate section will match }

FUNCTION FindKeyStringSection(Key1, Key2     : STRING;
                              Section        : STRING;
                              Default        : STRING) : STRING;

    { FindKeyStringSection. This is a variant of FindKeyString which operates }
    { similarly to the Windows GetPrivateProfileString routine. It performs the }
    { same tests as FindKeyString, but the string must also be within a section }
    { headed by [SECTION]. There can be multiple occurences of the matching    }
    { key combinations, but only the one in the appropriate section will match }
    { Same routine as FindKeyStringSection except string returned in not}
    { Upcased }

FUNCTION FindKeyStringSectionLC(Key1, Key2     : STRING;
                                Section        : STRING;
                                Default        : STRING) : STRING;

    { FindKeyValueSection - Section oriented version of FindKeyValue }

FUNCTION FindKeyValueSection(Key1, Key2     : STRING;
                             Section        : STRING;
                             Default        : LONGINT) : LONGINT;

    { FindKeyBooleanSection - Section oriented version of FindKeyBoolean }

FUNCTION FindKeyBooleanSection(Key1, Key2     : STRING;
                               Section        : STRING;
                               Match : STRING; Default : BOOLEAN) : BOOLEAN;

    { Returns the number of Section headings in the File }

FUNCTION NumberOfSections : WORD;

    { Check for existance of given section name }

FUNCTION SectionExists(Section : STRING) : BOOLEAN;

    { Returns the Nth Section heading from the file }

FUNCTION SectionHeading(Num : WORD) : STRING;

    { Find the section with specified heading, and leave file pointer there }

FUNCTION FindSection(Section : STRING) : BOOLEAN;

    { Get Next line. Starts at line after FindSection }

FUNCTION NextSectionItem(VAR Line : STRING) : BOOLEAN;

    { Internal routines }
FUNCTION GetArgString : STRING;
FUNCTION GetArgInteger : LONGINT;


    (*****************************************************************)

IMPLEMENTATION

USES
    OpString, QHdrRec;

VAR
    IniFile        : FileOfLinesPtr;
    Line           : STRING[100];
    EqualPos,
    Word1Pos,
    Word2Pos       : WORD;
    MatchFound     : BOOLEAN;

    (*****************************************************************)

    FUNCTION OpenINIFile(Path : PathStr) : BOOLEAN;
    VAR
        PrevFileMode   : BYTE;
    BEGIN
        OpenINIFile := FALSE;
        PrevFileMode := FileMode;
        FileMode := 0;
        if SYS^.NovellSys then
          FileMode := $40;
        NEW(IniFile, Init(Path, 24000)); {was 8000}
        FileMode := PrevFileMode;
        IF IniFile = NIL THEN
            EXIT;
        IF IniFile^.RFerror <> 0 THEN BEGIN
            IniFile^.FClose;
            DISPOSE(IniFile, Done);
            IniFile := NIL;
            EXIT;
        END;
        OpenINIFile := TRUE;
    END;

    (*****************************************************************)

    PROCEDURE CloseIniFIle;
    BEGIN
        IF IniFile = NIL THEN
            EXIT;
        IniFile^.FClose;
        DISPOSE(IniFile, Done);
        IniFile := NIL;
    END;

    (*****************************************************************)

    FUNCTION FindKeyString(Key1, Key2 : STRING; Default : STRING) : STRING;
    var
      e: word;
    BEGIN
        Key1 := StUpCase(Key1);
        Key2 := StUpCase(Key2);
        WITH IniFile^ DO BEGIN
            FSeek(0);
            E := RFError;
            REPEAT
                FReadLn(Line);
                Line := StUpCase(Trim(Line));
                IF Line[1] <> '*' THEN BEGIN
                    EqualPos := POS('=', Line);
                    Word1Pos := POS(Key1, Line);
                    Word2Pos := 0;
                    IF Key2 <> '' THEN
                        Word2Pos := POS(Key2, Line);
                    IF (Word1Pos <> 0) AND
                    (((Key2 <> '') AND(Word2Pos <> 0)) OR(Key2 = '')) AND
                    (Word1Pos < EqualPos) AND(Word2Pos < EqualPos) THEN BEGIN
                        FindKeyString := GetArgString;
                        MatchFound := TRUE;
                        EXIT;
                    END;
                END;
            UNTIL RFerror <> 0;
            MatchFound := FALSE;
            IF Default = '' THEN BEGIN
                FindKeyString := '';
            END
            ELSE BEGIN
                Line := Key1 + ' ' + Key2 + ' = ' + Default;
                EqualPos := POS('=', Line);
                FindKeyString := GetArgString;
            END;
        END;
    END;

    (*****************************************************************)

    FUNCTION FindKeyValue(Key1, Key2 : STRING; Default : LONGINT) : LONGINT;
    BEGIN
        FindKeyString(Key1, Key2, Long2Str(Default));
        FindKeyValue := GetArgInteger;
    END;

    (*****************************************************************)

    FUNCTION FindKeyBoolean(Key1, Key2     : STRING;
                            Match : STRING; Default : BOOLEAN) : BOOLEAN;
    BEGIN
        FindKeyString(Key1, Key2, Match);
        IF MatchFound THEN
            FindKeyBoolean := GetArgString = Match
        ELSE
            FindKeyBoolean := Default;
    END;

    { Second versions of above which provide Windows INI file sectioned functionality }
    { Finds matches only within a section headed by [SECTION NAME] }

    FUNCTION FindKeyStringSection(Key1, Key2     : STRING;
                                  Section        : STRING;
                                  Default        : STRING) : STRING;
    VAR
        InSection      : BOOLEAN;
        CPOS           : BYTE;
        SaveChar       : Char;
    BEGIN
        Key1 := StUpCase(Key1);
        Key2 := StUpCase(Key2);
        Section := StUpCase(Section);
        WITH IniFile^ DO BEGIN
            FSeek(0);
            InSection := FALSE;
            REPEAT
                FReadLn(Line);
                Line := StUpCase(Trim(Line));
                IF Line[1] <> '*' THEN BEGIN
                    IF Line[1] = '[' THEN BEGIN
                        DELETE(Line, 1, 1);
                        CPOS := POS(']', Line);
                        DELETE(Line, CPOS, $FF);
                        InSection := Section = Line;
                        Continue;
                    END;
                    IF NOT InSection THEN
                        Continue;
                    EqualPos := POS('=', Line);
                    Word1Pos := POS(Key1, Line);
                    Word2Pos := 0;
                    SaveChar := Line[Word1POS];
                    Line[Word1Pos] := '!';

                    IF Key2 <> '' THEN
                        Word2Pos := POS(Key2, Line);
                    Line[Word1Pos] := SaveChar;

                    IF (Word1Pos <> 0) AND
                    (((Key2 <> '') AND(Word2Pos <> 0)) OR(Key2 = '')) AND
                    (Word1Pos < EqualPos) AND(Word2Pos < EqualPos) THEN BEGIN
                        FindKeyStringSection := GetArgString;
                        MatchFound := TRUE;
                        EXIT;
                    END;
                END;
            UNTIL RFerror <> 0;
            MatchFound := FALSE;
            FindKeyStringSection := Trim(Default);
        END;
    END;

    (*****************************************************************)
    FUNCTION FindKeyStringSectionLC(Key1, Key2     : STRING;
                                    Section        : STRING;
                                    Default        : STRING) : STRING;
    VAR
        InSection      : BOOLEAN;
        CPOS           : BYTE;
        SaveChar       : Char;
    BEGIN
        Key1 := StUpCase(Key1);
        Key2 := StUpCase(Key2);
        Section := StUpCase(Section);
        WITH IniFile^ DO BEGIN
            FSeek(0);
            InSection := FALSE;
            REPEAT
                FReadLn(Line);
{                Line := StUpCase(Trim(Line));}
                IF Line[1] <> '*' THEN BEGIN
                    IF Line[1] = '[' THEN BEGIN
                        DELETE(Line, 1, 1);
                        CPOS := POS(']', Line);
                        DELETE(Line, CPOS, $FF);
                        InSection := Section = Line;
                        Continue;
                    END;
                    IF NOT InSection THEN
                        Continue;
                    EqualPos := POS('=', Line);
                    Word1Pos := POS(Key1, Line);
                    Word2Pos := 0;
                    SaveChar := Line[Word1POS];
                    Line[Word1Pos] := '!';

                    IF Key2 <> '' THEN
                        Word2Pos := POS(Key2, Line);
                    Line[Word1Pos] := SaveChar;

                    IF (Word1Pos <> 0) AND
                    (((Key2 <> '') AND(Word2Pos <> 0)) OR(Key2 = '')) AND
                    (Word1Pos < EqualPos) AND(Word2Pos < EqualPos) THEN BEGIN
                        FindKeyStringSectionLC := GetArgString;
                        MatchFound := TRUE;
                        EXIT;
                    END;
                END;
            UNTIL RFerror <> 0;
            MatchFound := FALSE;
            FindKeyStringSectionLC := Trim(Default);
        END;
    END;

    (*****************************************************************)

    FUNCTION FindKeyValueSection(Key1, Key2     : STRING;
                                 Section        : STRING;
                                 Default        : LONGINT) : LONGINT;
    BEGIN
        FindKeyStringSection(Key1, Key2, Section, Long2Str(Default));
        FindKeyValueSection := GetArgInteger;
    END;

    (*****************************************************************)

    FUNCTION FindKeyBooleanSection(Key1,
                                   Key2,
                                   Section        : STRING;
                                   Match          : STRING;
                                   Default        : BOOLEAN) : BOOLEAN;
    BEGIN
        FindKeyStringSection(Key1, Key2, Section, Match);
        IF MatchFound THEN
            FindKeyBooleanSection := GetArgString = Match
        ELSE
            FindKeyBooleanSection := Default;
    END;

    (*****************************************************************)

    FUNCTION NumberOfSections : WORD;
    VAR
        NS             : WORD;
    BEGIN
        WITH IniFile^ DO BEGIN
            RFerror := 0;
            FSeek(1);
            FReadLn(Line);
            FSeek(0);
            NS := 0;
            REPEAT
                FReadLn(Line);
                Line := StUpCase(Trim(Line));
                IF Line[1] = '[' THEN BEGIN
                    INC(NS);
                END;
            UNTIL RFerror <> 0;
            FSeek(0);
        END;
        NumberOfSections := NS;
    END;

    (*****************************************************************)

    FUNCTION FindSection(Section : STRING) : BOOLEAN;
    VAR
        NS             : WORD;
        CPOS           : BYTE;
    BEGIN
        WITH IniFile^ DO BEGIN
            RFerror := 0;
            FSeek(0);
            NS := 0;
            REPEAT
                FReadLn(Line);
                Line := StUpCase(Trim(Line));
                IF Line[1] = '[' THEN BEGIN
                    DELETE(Line, 1, 1);
                    CPOS := POS(']', Line);
                    DELETE(Line, CPOS, $FF);
                    IF StUpCase(Line) = StUpCase(Section) THEN BEGIN
                        FindSection := TRUE;
                        EXIT;
                    END;
                END;
            UNTIL RFerror <> 0;
            FSeek(0);
        END;
        FindSection := FALSE;
    END;

    (*****************************************************************)

    FUNCTION NextSectionItem(VAR Line : STRING) : BOOLEAN;
    VAR
        Found          : BOOLEAN;
    BEGIN
        Found := FALSE;
        NextSectionItem := FALSE;
        WITH IniFile^ DO BEGIN
            REPEAT
                FReadLn(Line);
                IF RFError <> 0 THEN
                    EXIT;
                IF Line[1] = '[' THEN
                    EXIT;
                IF (Line <> '') THEN
                    Found := TRUE;
            UNTIL (Found) OR(RFerror <> 0);
            NextSectionItem := RFerror = 0;
        END;
    END;

    (*****************************************************************)

    FUNCTION SectionHeading(Num : WORD) : STRING;
    VAR
        NS             : WORD;
        CPOS           : BYTE;
    BEGIN
        WITH IniFile^ DO BEGIN
            RFerror := 0;
            FSeek(0);
            NS := 0;
            IF Num > NumberOfSections THEN BEGIN
                SectionHeading := '';
                EXIT;
            END;
            REPEAT
                FReadLn(Line);
                Line := StUpCase(Trim(Line));
                IF Line[1] = '[' THEN BEGIN
                    INC(NS);
                    IF NS <> Num THEN
                        Continue;
                    DELETE(Line, 1, 1);
                    CPOS := POS(']', Line);
                    DELETE(Line, CPOS, 255);
                    SectionHeading := StUpCase(Line);
                    EXIT;
                END;
            UNTIL RFerror <> 0;
        END;
    END;

    (*****************************************************************)

    FUNCTION GetArgString : STRING;
    VAR
        CommentPos     : INTEGER;
    BEGIN
        IF Line = '??' THEN
            EXIT;
        CommentPos := POS('*', Line) - 2;
        IF CommentPos <= 0 THEN
            CommentPos := LENGTH(Line);
        GetArgString := Trim(COPY(Line, EqualPos + 1, (CommentPos - EqualPos) + 1));
    END;

    (*****************************************************************)

    FUNCTION SectionExists(Section : STRING) : BOOLEAN;
    VAR
        I              : WORD;
    BEGIN
        SectionExists := FALSE;
        Section := StUpCase(Section);
        FOR I := 1 TO NumberOfSections DO BEGIN
            IF SectionHeading(I) = Section THEN BEGIN
                SectionExists := TRUE;
                EXIT;
            END;
        END;
    END;

    (*****************************************************************)


    FUNCTION GetArgInteger : LONGINT;
    VAR
        I              : LONGINT;
        e              : WORD;
    BEGIN
        VAL(GetArgString, I, e);
        GetArgInteger := I;
    END;

    (*****************************************************************)

BEGIN
    IniFile := NIL;
END.
(*****************************************************************)
(*****************************************************************)

