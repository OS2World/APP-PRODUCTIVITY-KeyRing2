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
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,F+,I-,R-,S-,V-,D+,L+,O+}

UNIT INITOOLS;                    {unit for managing INI files - requires Object Professional}

    {***************************************************}
    {*               INITOOLS.PAS  1.03                *}
    {*     Copyright (c) TurboPower Software 1993      *}
    {***************************************************}

(*
  This unit provides an object for creating, maintaining and using Windows-
  format information (INI) files.  This allows programs to maintain a config
  or other program data file in a ASCII text format while treating information
  in the file as an appropriate string, boolean or integer data type.  Items
  are stored in "Title=Value" format, where Title is a unique descriptive name
  for the item, and Value is a string representation of the data.  The equals
  sign is required, and may have spaces on one or both sides.  Similar or
  related items are maintained under "group headers"; all files must have at
  least one group header, in "[GroupName]" format.  The file as used here has
  one restriction that Windows itself does not have: each item must be
  contained in a single line.  Blank lines, and lines beginning with a
  semicolon (;) are considered comments.

  The IniFile object loads the file's contents into a DoubleList for speed
  of access.  If the constructor's boolean parameter "Sparse" is set to True,
  only "active" lines (group headers and item lines) are loaded to conserve
  memory, but the file is then treated as read-only and any attempts to
  change or add items will fail.  If Sparse = False, the entire file is
  loaded; this takes more memory and increases the disk I/O time, but allows
  items to be changed or added. Which mode you use will need to be
  determined by the size of your file, how much memory you want to devote to
  the file and whether modifying or adding items is required in your
  application.

  An example of items in a file:

    [Mouse Support]

    ; controls mouse sensitivity
    MouseXSens=16
    MouseYSens=8

  Items in the file are accessed by group and title, so to access the two
  example items you would use the following code:

  {...}
  var
    MyIni : TIni;
    MXSens : Integer;
    MYSens : Integer;
  {...}
    if MyIni.Init(ForceExtension(ParamStr(0), 'INI'), True) then begin
      MXSens := MyIni.GetProfileInt('MouseXSens', 'Mouse Support', 16);
      MYSens := MyIni.GetProfileInt('MouseYSens', 'Mouse Support', 8);
      MyIni.Done;
    end;
  {...}

  This code instantiates the TIni object in Sparse mode, using a filename of
  the program's name with an extension of INI.  It then looks for the
  MouseXSens item in group Mouse Support, returning the item's value if found,
  otherwise returning the default value provided as the third parameter.  Note
  that while the two string parameters are not case sensitive, and the Group
  name may or may not have the surrounding brackets, they must both exactly
  match the group and item name in all other respects.

  Methods are provided for returning vars of type String, Boolean, Byte,
  Integer, Word and LongInt.  String types do not need to be quoted;
  everything after the separating "=" is returned.  Boolean type items can be
  "True/False", "Yes/No", "On/Off" or "1/0".  Methods to modify an existing
  item or add a new item, in string format, are also provided.  If sparse mode
  is enabled, these two methods will return False immediately.  The FlushFile
  method will also abort immediately if sparse mode is on.

  By default, any time you modify or add an item, the physical file is updated
  to reflect the change.  This behavior may not be desired in all cases, such
  as when you update multiple entries in one block of code, so a method is
  provided (SetFlushMode) to allow you to en/disable the updates as needed.
  When updates are made with flushing turned off, an internal flag is set so
  that the file will be flushed when the object is disposed, or you can
  manually call the FlushFile method to update the physical file as you wish.

  While it is not used often, the ability to scan in all items in a given
  group at one time is occasionally very handy - for example, it allows you
  to have a list of group titles in the .INI file, from which you can choose
  a specific configuration set group.  Similarly, being able to enumerate
  all of the group names in a file is occasionally needed.  In V1.02 I have
  added two new methods that provide these capabilities.  Each takes as a
  parameter a pointer to a DoubleList object, which must be instantiated.
  The DoubleList may be empty or may contain items; the new items are
  appended to the end of the list.  The EnumGroups method takes only the
  pointer parameter and returns the list loaded with the names of all
  groups in the file (stripped of their surrounding brackets).  The
  EnumGroupItems method takes an additional string parameter of the name of
  the group to find, and returns the complete string of each item in the
  group ("title=value" rather than the usual "value" only.)  In both cases,
  the nodes added to the DoubleList are of type PLine.

  Steve Sneed, TurboPower Software

  --------------------------------

  Rev history:

  1.00 - Original release.

  1.01 - Corrected bug that would cause a GPF when adding a new item to an
         empty list.  Corrected bug that left the "=" sign on extracted
         strings, causing the default value to always be used on numeric
         extractions (the Str2Xxx call would always return False.)

  1.02 - Added EnumGroups and EnumGroupItems methods.  Added missing
         compiler directives to top of file.  Changed handling of Group
         names slightly to eliminate potential problems.

  1.03 - Modified to allow use in Windows programs, by popular demand.
         When compiled for Windows, requires our Win/Sys Library.
*)

INTERFACE

USES
    OpString,
    {$IFDEF VirtualPascal}
    Use32,
    {$ENDIF}
    {$IFDEF Windows}
    WsList;
    {$ELSE}
    OpRoot;
    {$ENDIF}

    {$IFDEF Windows}
type
  DoubleListPtr = PDoubleList;
  DoubleListNode = DoubleNode;
{$ENDIF}

TYPE
    PStr           = ^STRING;
    PLine          = ^TLine;
    TLine =
        OBJECT(DoubleListNode)
            PL             : PStr;

            CONSTRUCTOR Init(S : STRING);
            DESTRUCTOR Done; VIRTUAL;
            FUNCTION UpDate(S : STRING) : BOOLEAN;
        END;

    PIni           = ^TIni;
    TIni           = OBJECT(DoubleList)
                         IniName        : STRING;

                         CONSTRUCTOR Init(Fn : STRING; Sparse : BOOLEAN);
        {-Construct our INI file object.  if Sparse=True, load only "active"
          lines (file is considered read-only.)  if Sparse=False, File always
          updates on changes; use SetFlushMode to control.}
                         DESTRUCTOR Done; VIRTUAL;
                             {-Destroy object when done}
                         PROCEDURE FlushFile;
                             {-Force an update of the physical file from the current list}
                         PROCEDURE SetFlushMode(Always : BOOLEAN);
                             {-Turn off/on auto-updating of file when an item is modified}
                         FUNCTION GetProFileString(Title, Group, Default : STRING) : STRING;
                             {-Return string item "Title" in "[Group]", or default if not found}
                         FUNCTION GetProFileBool(Title, Group : STRING; Default : BOOLEAN) : BOOLEAN;
                             {-Return boolean item "Title" in "[Group]", or default if not found}
                         FUNCTION GetProFileByte(Title, Group : STRING; Default : BYTE) : BYTE;
                             {-Return byte item "Title" in "[Group]", or default if not found}
                         FUNCTION GetProFileInt(Title, Group : STRING; Default : INTEGER) : INTEGER;
                             {-Return integer item "Title" in "[Group]", or default if not found}
                         FUNCTION GetProFileWord(Title, Group : STRING; Default : WORD) : WORD;
                             {-Return word item "Title" in "[Group]", or default if not found}
                         FUNCTION GetProFileLong(Title, Group : STRING; Default : LONGINT) : LONGINT;
                             {-Return longint item "Title" in "[Group]", or default if not found}
                         FUNCTION SetProFileString(Title, Group, NewVal : STRING) : BOOLEAN;
                             {-Change existing item "Title" in "[Group]" to "NewVal"}
                         FUNCTION AddProFileString(Title, Group, NewVal : STRING) : BOOLEAN;
        {-Add new item "Title=NewVal" to "[Group]".  Creates [Group] if not
          found, else adds "Title=NewVal" as last item in [Group]}
                         FUNCTION EnumGroups(P : DoubleListPtr) : BOOLEAN;
        {-Return P loaded with the names of all groups in the file.  Returns
          false only on error.  Items on P are of type PLine.}
                         FUNCTION EnumGroupItems(P : DoubleListPtr; Group : STRING) : BOOLEAN;
        {-Return P loaded with all items in group [Group].  Returns false
          if Group not found or error.  Items on P are of type PLine.}

                     PRIVATE      {these used internally only}
                         IniF           : TEXT;
                         NeedUpd        : BOOLEAN;
                         AlwaysUpd      : BOOLEAN;
                         IsSparse       : BOOLEAN;

                         FUNCTION GetIniNode(Title, Group : STRING) : PLine;
                         FUNCTION GetLastNodeInGroup(Group : STRING) : PLine;
                         FUNCTION GetProFilePrim(Title, Group : STRING) : STRING;
                     END;


IMPLEMENTATION

    {---------------}

    CONSTRUCTOR TLine.Init(S : STRING);
    BEGIN
        IF NOT DoubleListNode.Init THEN
            FAIL;
        PL := PStr(StringToHeap(S));
        IF PL = NIL THEN
            FAIL;
    END;

    {---------------}

    DESTRUCTOR TLine.Done;
    BEGIN
        IF PL <> NIL THEN
            DisposeString(POINTER(PL));
        DoubleListNode.Done;
    END;

    {---------------}

    FUNCTION TLine.UpDate(S : STRING) : BOOLEAN;
    VAR
        L              : PStr;
    BEGIN
        UpDate := FALSE;
        L := PStr(StringToHeap(S));
        IF L = NIL THEN EXIT;
        DisposeString(POINTER(PL));
        PL := L;
        UpDate := TRUE;
    END;

    {---------------------------------------------------------------------------}

    CONSTRUCTOR TIni.Init(Fn : STRING; Sparse : BOOLEAN);
    VAR
        P              : PLine;
        S              : STRING;
    BEGIN
        IF NOT DoubleList.Init THEN
            FAIL;

        NeedUpd := FALSE;
        AlwaysUpd := TRUE;
        IsSparse := Sparse;

        IniName := DefaultExtension(Fn, 'INI');
        ASSIGN(IniF, IniName);
        System.RESET(IniF);
        IF IORESULT <> 0 THEN BEGIN
            {file doesn't yet exist; drop out}
            NeedUpd := TRUE;
            EXIT;
        END;

        WHILE NOT EOF(IniF) DO BEGIN
            READLN(IniF, S);
            IF IORESULT <> 0 THEN BEGIN
                {read error here means something is wrong; bomb it}
                CLOSE(IniF); IF IORESULT = 0 THEN ;
                Done;
                FAIL;
            END;

            S := Trim(S);
            IF (NOT(Sparse)) OR ((S <> '') AND (S[1] <> ';')) THEN BEGIN
                NEW(P, Init(S));
                IF P = NIL THEN BEGIN
                    {out of memory, bomb it}
                    CLOSE(IniF);
                    IF IORESULT = 0 THEN ;
                    Done;
                    FAIL;
                END;
                APPEND(P);
            END;
        END;
        CLOSE(IniF);
        IF IORESULT = 0 THEN ;
    END;

    {---------------}

    DESTRUCTOR TIni.Done;
    BEGIN
        IF NeedUpd THEN
            FlushFile;
        DoubleList.Done;
    END;

    {---------------}

    PROCEDURE TIni.SetFlushMode(Always : BOOLEAN);
    BEGIN
        AlwaysUpd := Always;
    END;

    {---------------}

    PROCEDURE TIni.FlushFile;
    VAR
        S              : STRING;
        P              : PLine;
    BEGIN
        IF IsSparse THEN
            EXIT;

        ASSIGN(IniF, IniName);
        REWRITE(IniF);
        IF IORESULT <> 0 THEN
            EXIT;

        P := PLine(Head);
        WHILE P <> NIL DO BEGIN
            WRITELN(IniF, P^.PL^);
            IF IORESULT <> 0 THEN BEGIN
                CLOSE(IniF);
                IF IORESULT = 0 THEN ;
                EXIT;
            END;
            P := PLine(Next(P));
        END;

        CLOSE(IniF);
        IF IORESULT = 0 THEN ;
        NeedUpd := FALSE;
    END;

    {---------------}

    FUNCTION TIni.GetIniNode(Title, Group : STRING) : PLine;
    VAR
        P              : PLine;
        S              : STRING;
        GroupSeen      : BOOLEAN;
    BEGIN
        GetIniNode := NIL;
        IF Size = 0 THEN EXIT;

        {fixup strings as needed}
        IF Group[1] <> '[' THEN
            Group := '[' + Group + ']'; {!!.02}
        Group := StUpCase(Group); {!!.02}
        Title := StUpCase(Title);

        {search}
        GroupSeen := FALSE;
        P := PLine(Head);
        WHILE P <> NIL DO BEGIN
            IF P^.PL^[1] = '[' THEN BEGIN
                {a group header...}
                IF StUpCase(P^.PL^) = Group THEN
                    {in our group}
                    GroupSeen := TRUE
                ELSE IF GroupSeen THEN
                    {exhausted all options in our group; get out}
                    EXIT;
            END
            ELSE IF (GroupSeen) AND (P^.PL^[1] <> ';') THEN BEGIN
                {in our group, see if the title matches}
                S := COPY(P^.PL^, 1, POS('=', P^.PL^) - 1);
                S := Trim(S);
                S := StUpCase(S);
                IF Title = S THEN BEGIN
                    GetIniNode := P;
                    EXIT;
                END;
            END;
            P := PLine(Next(P));
        END;
    END;

    {---------------}

    FUNCTION TIni.GetLastNodeInGroup(Group : STRING) : PLine;
    VAR
        P, Q           : PLine;
        S              : STRING;
        GroupSeen      : BOOLEAN;
    BEGIN
        GetLastNodeInGroup := NIL;
        IF Size = 0 THEN EXIT;

        {fixup strings as needed}
        IF Group[1] <> '[' THEN
            Group := '[' + Group + ']'; {!!.02}
        Group := StUpCase(Group); {!!.02}

        {search}
        GroupSeen := FALSE;
        Q := NIL;
        P := PLine(Head);
        WHILE P <> NIL DO BEGIN
            IF P^.PL^[1] = '[' THEN BEGIN
                {a group header...}
                IF StUpCase(P^.PL^) = Group THEN
                    {in our group}
                    GroupSeen := TRUE
                ELSE IF (GroupSeen) THEN BEGIN
                    {exhausted all lines in our group, return the last pointer}
                    IF Q = NIL THEN
                        Q := PLine(P^.dlPrev);
                    GetLastNodeInGroup := Q;
                    EXIT;
                END;
            END;
            Q := P;
            P := PLine(Next(P));
        END;
        IF GroupSeen THEN         {!!.01}
            GetLastNodeInGroup := Q {!!.01}
        ELSE                      {!!.01}
            GetLastNodeInGroup := NIL; {!!.01}
    END;

    {---------------}

    FUNCTION TIni.GetProFilePrim(Title, Group : STRING) : STRING;
    VAR
        P              : PLine;
        S              : STRING;
    BEGIN
        P := GetIniNode(Title, Group);
        IF P = NIL THEN
            GetProFilePrim := ''
        ELSE BEGIN
            S := P^.PL^;
            S := COPY(S, POS('=', S) + 1, 255); {!!.01}
            S := Trim(S);
            GetProFilePrim := S;
        END;
    END;

    {---------------}

    FUNCTION TIni.GetProFileString(Title, Group, Default : STRING) : STRING;
    VAR
        S              : STRING;
    BEGIN
        S := GetProFilePrim(Title, Group);
        IF S = '' THEN
            S := Default;
        GetProFileString := S;
    END;

    {---------------}

    FUNCTION TIni.GetProFileBool(Title, Group : STRING; Default : BOOLEAN) : BOOLEAN;
    VAR
        S              : STRING;
    BEGIN
        S := GetProFilePrim(Title, Group);
        IF S <> '' THEN BEGIN
            S := StUpCase(S);
            IF (S = 'TRUE') OR (S = '1') OR (S = 'YES') THEN
                GetProFileBool := TRUE
            ELSE IF (S = 'FALSE') OR (S = '0') OR (S = 'NO') THEN
                GetProFileBool := FALSE
            ELSE
                GetProFileBool := Default;
        END
        ELSE
            GetProFileBool := Default;
    END;

    {---------------}

    FUNCTION TIni.GetProFileByte(Title, Group : STRING; Default : BYTE) : BYTE;
    VAR
        S              : STRING;
        I              : INTEGER;
    BEGIN
        S := GetProFilePrim(Title, Group);
        IF S <> '' THEN BEGIN
            IF Str2int(S, I) THEN
                GetProFileByte := BYTE(I)
            ELSE
                GetProFileByte := Default;
        END
        ELSE
            GetProFileByte := Default;
    END;

    {---------------}

    FUNCTION TIni.GetProFileInt(Title, Group : STRING; Default : INTEGER) : INTEGER;
    VAR
        S              : STRING;
        I              : INTEGER;
    BEGIN
        S := GetProFilePrim(Title, Group);
        IF S <> '' THEN BEGIN
            IF Str2int(S, I) THEN
                GetProFileInt := I
            ELSE
                GetProFileInt := Default;
        END
        ELSE
            GetProFileInt := Default;
    END;

    {---------------}

    FUNCTION TIni.GetProFileWord(Title, Group : STRING; Default : WORD) : WORD;
    VAR
        S              : STRING;
        I              : WORD;
    BEGIN
        S := GetProFilePrim(Title, Group);
        IF S <> '' THEN BEGIN
            IF Str2Word(S, I) THEN
                GetProFileWord := I
            ELSE
                GetProFileWord := Default;
        END
        ELSE
            GetProFileWord := Default;
    END;

    {---------------}

    FUNCTION TIni.GetProFileLong(Title, Group : STRING; Default : LONGINT) : LONGINT;
    VAR
        S              : STRING;
        I              : LONGINT;
    BEGIN
        S := GetProFilePrim(Title, Group);
        IF S <> '' THEN BEGIN
            IF Str2Long(S, I) THEN
                GetProFileLong := I
            ELSE
                GetProFileLong := Default;
        END
        ELSE
            GetProFileLong := Default;
    END;

    {---------------}

    FUNCTION TIni.SetProFileString(Title, Group, NewVal : STRING) : BOOLEAN;
    VAR
        S              : STRING;
        P              : PLine;
    BEGIN
        SetProFileString := FALSE;
        IF IsSparse THEN EXIT;

        P := GetIniNode(Title, Group);
        IF P = NIL THEN
            EXIT
        ELSE BEGIN
            S := P^.PL^;
            System.DELETE(S, POS('=', S) + 1, 255);
            S := S + NewVal;
            IF P^.UpDate(S) THEN BEGIN
                SetProFileString := TRUE;
                IF AlwaysUpd THEN
                    FlushFile
                ELSE
                    NeedUpd := TRUE;
            END;
        END;
    END;

    {---------------}

    FUNCTION TIni.AddProFileString(Title, Group, NewVal : STRING) : BOOLEAN;
        {!!.01 - Rewritten to correct GPF when adding a string to an empty list}
    VAR
        P, Q           : PLine;
    BEGIN
        AddProFileString := FALSE;
        IF IsSparse THEN EXIT;

        {fixup strings as needed}
        IF Group[1] <> '[' THEN
            Group := '[' + Group + ']'; {!!.02}
        Group := StUpCase(Group); {!!.02}

        P := GetLastNodeInGroup(Group);
        IF P = NIL THEN BEGIN
            {group not found, create a new one}
            NEW(Q, Init(Group));
            IF Q = NIL THEN EXIT;
            APPEND(Q);
            P := Q;
        END;
        {add our new element after}
        NEW(Q, Init(Title + '=' + NewVal));
        IF Q <> NIL THEN BEGIN
            Place(Q, P);
            AddProFileString := TRUE;
            IF AlwaysUpd THEN
                FlushFile
            ELSE
                NeedUpd := TRUE;
        END;
    END;

    {!!.02 begin new routines}
    {---------------}

    FUNCTION StripBrackets(S : STRING) : STRING;
    VAR
        B              : BYTE ABSOLUTE S;
    BEGIN
        S := Trim(S);
        IF S[B] = ']' THEN
            DEC(B);
        IF S[1] = '[' THEN BEGIN
            MOVE(S[2], S[1], B - 1);
            DEC(B);
        END;
        StripBrackets := StUpCase(S);
    END;

    {---------------}

    FUNCTION TIni.EnumGroups(P : DoubleListPtr) : BOOLEAN;
    {-Return P loaded with the names of all groups in the file.  Returns
      false only on error.  Items on P are of type PLine.}
    VAR
        Q, R           : PLine;
    BEGIN
        EnumGroups := FALSE;
        Q := PLine(Head);
        WHILE Q <> NIL DO BEGIN
            IF Q^.PL^[1] = '[' THEN BEGIN
                NEW(R, Init(StripBrackets(Q^.PL^)));
                IF R = NIL THEN
                    EXIT;
                P^.APPEND(R);
            END;
            Q := PLine(Q^.dlNext);
        END;
        EnumGroups := TRUE;
    END;

    {---------------}

    FUNCTION TIni.EnumGroupItems(P : DoubleListPtr; Group : STRING) : BOOLEAN;
    {-Return P loaded with all items in group [Group].  Returns false
      if Group not found or error.  Items on P are of type PLine.}
    VAR
        Q, R           : PLine;
        S              : STRING;
    BEGIN
        EnumGroupItems := FALSE;

        {fixup strings as needed}
        IF Group[1] <> '[' THEN
            Group := '[' + Group + ']';
        Group := StUpCase(Group);

        Q := PLine(Head);
        WHILE Q <> NIL DO BEGIN
            IF StUpCase(Q^.PL^) = Group THEN BEGIN
                Q := PLine(Q^.dlNext);
                WHILE (Q <> NIL) AND (Q^.PL^[1] <> '[') DO BEGIN
                    S := Trim(Q^.PL^);
                    IF (S <> '') AND (S[1] <> ';') THEN BEGIN
                        NEW(R, Init(S));
                        IF R = NIL THEN
                            EXIT
                        ELSE
                            P^.APPEND(R);
                    END;
                    Q := PLine(Q^.dlNext);
                END;
                EnumGroupItems := TRUE;
                EXIT;
            END;
            Q := PLine(Q^.dlNext);
        END;
    END;

END.
