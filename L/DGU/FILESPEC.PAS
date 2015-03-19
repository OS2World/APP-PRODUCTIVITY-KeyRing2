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
* File Wild Card handler
*
* ~notesend~
* ~nokeywords~
***************************************************************************

}
(* -------------------------------------------------------------- *)
(* FileSpec.PAS v1.0a by Robert Walking-Owl November 1993         *)
(* -------------------------------------------------------------- *)

{ Things to add...                                                 }
{ - have # and $ be symbols for ASCII chars in dec/hex?            }

(* Buggie Things:                                                 *)
(* - anti-sets don't work with variable lenght sets, since they   *)
(*   end with the first character NOT in the set...               *)

{$IFDEF DOCZZZ}
{---------------------  DEMO ------------------------- }

(* Demo program to "test" the FileSpec unit                             *)
(* Checks to see if file matches filespec... good for testing/debugging *)
(* the FileSpec object/unit, as well as learning the syntax of FileSpec *)

program FileSpec_Test(input, output);
  uses FileSpec;
var
    p,                                       (* User-entered "filespec"  *)
    d:  String;                              (* Filename to "test"       *)
    FS: TWildCard;                           (* FileSpec Object          *)
begin
  FS.Init;                                   (* Initialize               *)
  WriteLn;
  Write('Enter filespec -> '); ReadLN(p);    (* Get filespec...          *)
  FS.AddSpec(p);                             (* ... Add Spec to list ... *)
  Write('Enter file -----> '); ReadLN(d);    (* ... Get Filename ...     *)
  if FS.FitSpec(d) then                          (* Is the file in the list? *)

    WriteLN('The files match.')
    else
    WriteLN('The files don''t match.');
  FS.Done;                                   (* Done... clean up etc.    *)
end.


FileSpec v1.0a
--------------

"FileSpec" is a public domain Turbo Pascal unit that gives you advanced,
Unix-like filespecs and wildcard-matching capabilities for your software.
This version should be compatible with Turbo Pascal v5.5 upwards (since
it uses OOP).

The advantage is that you can check to see if a filename is within the
specs a user has given--even multiple filespecs; thus utilities like
file-finders or archive-viewers can have multiple file-search specif-
ications.

To use, first initialize the TWildCard object (.Init).

You then use .AddSpec() to add the wildcards (e.g. user-specified) to the
list; and use .FitSpec() to see if a filename "fits" in that list.

When done, use the .Done destructor. (Check your TPascal manual if you do
not understand how to use objects).

"FileSpec" supports standard DOS wilcards (* and ?); also supported are the
undocumented DOS wildcards (eg. FILENAME = FILENAME.* and .EXT = *.EXT).

However, "FileSpec" supports many extended features which can make a program
many times more powerful.  Filenames or wildcards can be in quotes (eg. "*.*"
is equivalent to *.*).

Also supported are "not" (or "but") wildcards using the ~ character.  Thus
a hypothetical directory-lister with the argument *.TXT would list all
files _except_ those that match *.TXT.

Fixed and variable length "sets" are also supported:

[a-m]*.*           <- Any files beginning with letters A-M
[a-z,~ux]*.*       <- Any files beginning with a any letter except X or U
*.[~q]?           <- Any files except those that match *.?Q?
foo[abc]*.*        <- Files of FOO?*.* where '?' is A,B or C
foo["abc"]*.*      <- Same as above.
foo[a-c]*.*        <- Same as above.
test{0-9}.*        <- Files of TEST0.* through TEST9999.*
x{}z.*             <- Filenames beginning with X and ending with Z
x{0123456789}z.*   <- Same as above, only with numbers between X and Z.
("read")*.*        <- Filenames that contain the text "READ"

If this seems confusing, use the FS-TEST.PAS program included with this
archive to experiment and learn the syntax used by "FileSpec".

Playing around with the included demos (LS.PAS, a directory lister; and
XFIND, a file-finder) will also give you an idea how to use the FileSpecs
unit.

One Note: if you use the FileSpec unit with your software, please let users
know about it in the documentation, so that they know they can take full
advantage of the added features.

{$ENDIF}
{$F+}

UNIT FileSpec;

INTERFACE

USES
    Dos
    {$IFDEF VirtualPascal}
    ,USE32
    {$ENDIF}
    ;
TYPE
    TTargetOS      = (EDOS, EUNIX, EOS2);

CONST
    DosNameLen     = 12;          (* Maximum Length of DOS filenames        *)
    UnixNameLen    = 32;          (* Maximum Length of Unix Filenames       *)
    OS2NameLen     = 255;

    MaxWildArgs    = 32;          (* Maximum number of wildcard arguments   *)

    {$IFNDEF VirtualPascal}
    MaxNameLen     = 127;
    {$ELSE}
    MaxNameLen     = 255;
    {$ENDIF}

    fCaseSensitive = $01;         (* Case Sensitive Flag                    *)
    fExtendedWilds = $02;         (* Use extented wildcard forms (not,sets  *)
    fUndocumented  = $80;         (* Use DOS 'undocumented' filespecs       *)

TYPE
    SpecList       = ARRAY[1..MaxWildArgs] OF RECORD
                                                  Name           : STRING[MaxNameLen]; (* or use DOS ParamStr?  *)
                                                  Truth          : BOOLEAN
                                              END;
    PWildCard      = ^TWildCard;
    TWildCard      = OBJECT
                     PRIVATE
                         FileSpecs      : SpecList; (* List of filespecs      *)
                         NumNegs, (* Number of "not" specs  *)
                         FSpCount       : WORD; (* Total number of specs  *)
                         FUNCTION StripQuotes(X : STRING) : STRING;
                         PROCEDURE FileSplit(Path : STRING; VAR Dir, Name, Ext : STRING);
                     PUBLIC
                         PathChar, (* path seperation char   *)
                         NotChar, (* "not" char - init '~'  *)
                         QuoteChar      : CHAR; (* quote char - init '"'  *)
                         Flags,   (* Mode flags ...         *)
                         FileNameLen    : BYTE; (* MaxLength of FileNames *)
                         CONSTRUCTOR Init(Targ : TTargetOS);
                         FUNCTION AddSpec(Name : STRING) : BOOLEAN;
                         FUNCTION FitSpec(Name : STRING) : BOOLEAN;
                         DESTRUCTOR Done;
                             (* Methods to RemoveSpec() or ChangeSpec() aren't added *)
                             (* since for most applications they seem unnecessary.   *)
                             (* An IsValid() spec to see if a specification is valid *)
                             (* syntax is also unnecessary, since no harm is done,   *)
                             (* and DOS and Unix ignore them anyway ....             *)
                     END;


IMPLEMENTATION
USES
    OpString;

    {-----------------}

    CONSTRUCTOR TWildCard.Init(Targ : TTargetOS);
    BEGIN
        FSpCount := 0;
        NumNegs := 0;
        NotChar := '~';
        QuoteChar := '"';
        Flags := fExtendedWilds OR fUndocumented;
        FILLCHAR(FileSpecs, SIZEOF(FileSpecs), #0);
        CASE Targ OF
            EDOS :
                BEGIN
                    PathChar := '\';
                    FileNameLen := DosNameLen;
                END;
            EUNIX :
                BEGIN
                    FileNameLen := UnixNameLen;
                    PathChar := '/';
                END;
            EOS2 :
                BEGIN
                    PathChar := '\';
                    FileNameLen := OS2NameLen;
                END;
        END;
    END;

    {-----------------}

    DESTRUCTOR TWildCard.Done;
    BEGIN
        FSpCount := 0
    END;

    {-----------------}

    FUNCTION TWildCard.StripQuotes(X : STRING) : STRING;
    BEGIN
        IF X <> '' THEN
            IF (X[1] = QuoteChar) AND (X[LENGTH(X)] = QuoteChar) THEN
                StripQuotes := COPY(X, 2, LENGTH(X) - 2)
            ELSE
                StripQuotes := X
    END;

    {-----------------}

    FUNCTION TWildCard.AddSpec(Name : STRING) : BOOLEAN;
    VAR
        Truth          : BOOLEAN;
    BEGIN
        AddSpec := TRUE;
        IF Name <> '' THEN BEGIN
            Truth := TRUE;
            IF (Flags AND fExtendedWilds) <> 0 THEN BEGIN
                IF Name[1] = NotChar THEN BEGIN
                    INC(NumNegs);
                    Truth := FALSE;
                    Name := COPY(Name, 2, PRED(LENGTH(Name)));
                END;
                Name := StripQuotes(Name);
            END;
            IF (FSpCount < MaxWildArgs) AND (Name <> '') THEN BEGIN
                INC(FSpCount);
                FileSpecs[FSpCount].Name := Name;
                FileSpecs[FSpCount].Truth := Truth
            END
            ELSE
                AddSpec := FALSE;
        END
    END;

    {-----------------}

    PROCEDURE TWildCard.FileSplit(Path : STRING; VAR Dir, Name, Ext : STRING);
    VAR
        I,
        P,
        E              : BYTE;
        InSet          : BOOLEAN;
    BEGIN
        P := 0;
        IF (Flags AND fCaseSensitive) = 0 THEN
            Path := StUpCase(Path);

        FOR I := 1 TO LENGTH(Path) DO
            IF Path[I] = PathChar THEN
                P := I;
        I := LENGTH(Path);
        InSet := FALSE;
        E := SUCC(LENGTH(Path));
        REPEAT
            IF NOT InSet THEN
                CASE Path[I] OF
                    '.' :
                        E := I;
                    ']',
                    '}',
                    ')' :
                        InSet := TRUE;
                END
            ELSE
                IF Path[I] IN ['[', '{', '('] THEN
                    InSet := FALSE;
            DEC(I);
        UNTIL I = 0;
        IF P = 0 THEN Dir := ''
        ELSE
            Dir := COPY(Path, 1, P);
        Name := COPY(Path, SUCC(P), PRED(E - P));
        IF E <= LENGTH(Path) THEN
            Ext := COPY(Path, E, SUCC(LENGTH(Path) - E))
        ELSE
            Ext := '';
    END;

    {-----------------}

    FUNCTION TWildCard.FitSpec(Name : STRING) : BOOLEAN;
    VAR
        X,
        B              : SET OF CHAR;

        PROCEDURE GetSet(S : STRING; EndSet : CHAR; VAR K : byte);
        VAR
            C              : CHAR;
            U              : STRING;
            I              : BYTE;
            A              : BOOLEAN;
        BEGIN
            A := FALSE;
            IF S[K] = ',' THEN
            REPEAT
                INC(K)
            UNTIL (K >= FileNameLen) OR (S[K] = EndSet) OR (S[K] <> ',');
            U := '';
            IF (K < FileNameLen) AND (S[K] <> EndSet) THEN BEGIN
                REPEAT
                    U := U + S[K];
                    INC(K);
                UNTIL (K >= FileNameLen) OR (S[K] = EndSet) OR (S[K] = ',');
                IF U <> '' THEN BEGIN
                    IF U[1] = NotChar THEN BEGIN
                        A := TRUE;
                        U := COPY(U, 2, PRED(LENGTH(U)));
                    END;
                    U := StripQuotes(U);
                    IF (LENGTH(U) = 3) AND (U[2] = '-') THEN BEGIN
                        FOR C := U[1] TO U[3] DO
                            IF A THEN
                                B := B + [C]
                            ELSE
                                X := X + [C]
                    END
                    ELSE BEGIN
                        FOR I := 1 TO LENGTH(U) DO
                            IF A THEN
                                B := B + [U[I]]
                            ELSE
                                X := X + [U[I]];
                    END
                END;
            END;
        END;

        FUNCTION Match(N, S : STRING) : BOOLEAN; (* Does a field match? *)
        VAR
            I,
            J,
            K              : byte;
            C              : CHAR;
            T              : BOOLEAN;
            Scrap          : STRING;
        BEGIN
            I := 1;               (* index of filespec *)
            J := 1;               (* index of name     *)
            T := TRUE;
            N := Pad(N, MaxNameLen);
            S := Pad(S, MaxNameLen);
            REPEAT
                IF S[I] = '*' THEN BEGIN
                    I := FileNameLen;
                    BREAK;
                END
                ELSE
                    CASE S[I] OF
                        '(' :
                            IF ((Flags AND fExtendedWilds) <> 0) THEN BEGIN
                                Scrap := '';
                                INC(I);
                                REPEAT
                                    Scrap := Scrap + S[I];
                                    INC(I);
                                UNTIL (I >= FileNameLen) OR (S[I] = ')');
                                Scrap := StripQuotes(Scrap);
                                IF POS(Scrap, COPY(N, J, LENGTH(N))) = 0 THEN
                                    T := FALSE
                                ELSE
                                    BREAK;
                            END;
                        '[' :
                            IF ((Flags AND fExtendedWilds) <> 0) THEN BEGIN
                                X := []; B := [];
                                K := SUCC(I);
                                REPEAT
                                    GetSet(S, ']', K);
                                UNTIL (K >= FileNameLen) OR (S[K] = ']');
                                I := K;
                                IF X = [] THEN
                                    FILLCHAR(X, SIZEOF(X), #255);
                                X := X - B;
                                IF NOT(N[J] IN X) THEN
                                    T := FALSE;
                            END;
                        '{' :
                            IF ((Flags AND fExtendedWilds) <> 0) THEN BEGIN
                                X := []; B := [];
                                K := SUCC(I);
                                REPEAT
                                    GetSet(S, '}', K);
                                UNTIL (K >= FileNameLen) OR (S[K] = '}');
                                I := SUCC(K);
                                IF X = [] THEN
                                    FILLCHAR(X, SIZEOF(X), #255);
                                X := X - B;
                                WHILE (N[J] IN X) AND (J <= FileNameLen) DO
                                    INC(J);
                            END;
                        ELSE
                            IF T AND (S[I] <> '?') THEN
                                IF S[I] <> N[J] THEN
                                    T := FALSE;
                    END;
                INC(I);
                INC(J);
            UNTIL (I >= FileNameLen) OR (J > FileNameLen) OR (NOT T) OR (S[I] = '*');
            Match := T;
        END;

    VAR
        I,
        NumMatches     : BYTE;
        dn,
        de,
        NN,
        ne,
        SN,
        se             : STRING;
        Negate         : BOOLEAN;
    BEGIN
        Negate := FALSE;
        IF FSpCount = 0 THEN
            NumMatches := 1
        ELSE BEGIN
            NumMatches := 0;
            FOR I := 1 TO FSpCount DO BEGIN
                FileSplit(Name, dn, NN, ne);
                FileSplit(FileSpecs[I].Name, de, SN, se);
                IF ne = '' THEN
                    ne := '.   ';
                IF (Flags AND fUndocumented) <> 0 THEN BEGIN
                    IF SN = '' THEN
                        SN := '*';
                    IF se = '' THEN
                        se := '.*';
                    IF dn = '' THEN
                        dn := '*';
                    IF de = '' THEN
                        de := '*';
                END;
                IF (Match(dn, de) AND Match(NN, SN) AND Match(ne, se)) THEN BEGIN
                    INC(NumMatches);
                    IF NOT FileSpecs[I].Truth THEN
                        Negate := TRUE;
                END;
            END;
        END;
        IF (NumNegs = FSpCount) AND (NumMatches = 0) THEN
            FitSpec := TRUE
        ELSE
            FitSpec := (NumMatches <> 0) XOR Negate;
    END;

    {-----------------}

END.

    {-----------------}
    {-----------------}

