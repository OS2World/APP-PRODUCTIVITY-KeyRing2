{**************************************************************************
* Filename: cmdlin.pas
* Version:  1.18
* Date:     03/06/99 @ 13:30:50
* Group:    
* Release:  
* ----------------------------
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer   Description
*  1.0    05/29/93 11:49:01  K_McCoy        
*  virgin
*
*  1.1    08/17/93 09:33:09  K_McCoy        
*  update prior to new uipxspx
*  *
*  1.2    01/25/94 15:48:00  K_McCoy        
*  Added header
*
*  1.3    10/19/94 09:37:55  K_McCoy        
*  Added missing compiler
*  directives
*
*  1.4    09/25/95 18:38:30  K_McCoy
*  
*
*  1.5    09/26/95 14:53:41  K_McCoy        
*  Added header
*
*  1.6    05/09/96 12:20:18  K_McCoy        
*  Put header back
*
*  1.7    05/16/96 09:32:45  K_McCoy        
*  
*
*  1.8    07/21/96 13:32:18  K_McCoy        
*  ECO 7-19-96
*
*  1.9    08/09/96 14:56:54  K_McCoy        
*  Release to Jerry
*
*  1.10   10/27/96 17:01:57  K_McCoy        
*  eco10221996
*
*  1.11   10/27/96 18:13:16  K_McCoy        
*  added mode menu
*
*  1.12   11/07/96 15:32:01  K_McCoy        
*  Attempted fix of Missisip bug
*  *
*  1.13   03/07/97 11:27:30  K_McCoy        
*  Added TPC error trapping
*
*  1.14   11/11/97 08:33:27  K_McCoy        
*  German final release
*
*  1.15   08/25/98 16:39:33  K_McCoy        
*  Added embedded strings in
*  non-flag command line parameters
*
*  1.16   09/09/98 15:09:04  K_McCoy
*  ECO09081998
*
*  1.17   01/28/99 09:03:02  K_McCoy        
*  fixed indices
*
*  1.18   03/06/99 13:30:50  K_McCoy        
*  
*
*
*
* ~notes~
* Description
* -----------
* Command line parameter parsing tools
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT CmdLin;
(*
   This unit will process command line flags, (/N -N)
        a) as present or absent (Is_Param)
        b) with an integer (eg. /N54 /X-76) (Param_Int)
        c) with a real number (eg /J-987.65) (Param_Real)
        d) with strings, including delimited strings with embedded spaces
           ( eg. /X"This is the story!" /YFred)

      Routines are included to count and return the parameters that
      aren't flags (Non_Flag_Count), and to return them without
      counting the flag parameters (Non_Flag_Param).

      So ( /X76 Filename.txt /N"My name is Fred." George ) would count
      two non-flag params, #1 = filename.txt and #2 = george.

      This is completely public domain, all I want in return for your use
      is appreciation.  If you improve this unit, please let me know.
      Some possible improvements would be to allow embedded strings in
      non-flag parameters.  I haven't done this because I haven't needed
      it.


      Jim Walsh      CIS:72571,173

      -----------------------------------

      1998 - Kevin McCoy (kgmccoy@idk-inc.com)

      Added many new features and fixes, including the embedded strings
      mentioned above...  Now it works with long file names with embedded
      spaces - if you use quotes!

      Now you can do:

      /x3 -T -f "C:\this is a long-path\myfilename.DAT"

      without the "p" in "path" getting parsed incorrectly as a parameter.

      Typical call:

        FOR C := '?' TO 'Z' DO BEGIN  {loop through all possible flags}
            IF Is_Param(C) THEN BEGIN {is flag there?}
                CASE C OF             {Eureka!}
                    '?' :
                        ShowHelp;
                    'D' :
                        ReqdNetType := NoNet;
                    'M' :
                        ReqdNetType := MsNet;
                    'N' :
                        ReqdNetType := Novell;
                    'T' :
                        Timeout := Param_Real('T'); {go get numeric values}
                    'C' :
                        Count := Param_Int('C');
                    ELSE BEGIN
                        InvalidOption(C); {garbage on cmdline found!}
                    END;
                END;              {CASE}
            END;                  {IF}
        END;                      {FOR}

        Filename = Non_Flag_Param(1);     {go get non flagged text}

        -------------------------------------------

        2-18-1999 Kevin McCoy
        Added better parsing of command lines containg embedded spaces
*)

INTERFACE
USES
    OpDos,
    OpString
    {$IFDEF VirtualPascal}
    ,Strings,
    Use32
{$ENDIF}
    ;


FUNCTION Is_Param(Flag : CHAR) : BOOLEAN;
    { Responds yes if the flag (ie N) is found in the command line (ie /N or -N) }

FUNCTION Param_Int(Flag : CHAR) : LONGINT;
    { Returns the integer value after the parameter, ie -M100, or -M-123 }

FUNCTION Param_Real(Flag : CHAR) : REAL;
    { Returns the Real value after the parameter, ie -X654.87, or -x-3.14159 }

FUNCTION Param_Text(Flag : CHAR) : STRING;
    { Returns the string after the parameter, ie -MHello -> 'Hello',            }
    {  -m"This is it, baby" -> 'This is it, baby', valid string delims='' "" [] }

FUNCTION Non_Flag_Param(Index : INTEGER) : STRING;
    { Returns the indexth parameter, not preceded with a flag delimeter }
    { /X Text.txt /Y876.76 /G"Yes sir!" MeisterBrau /?                  }
    { For this command line 'Text.txt' is Non Flag Param #1,            }
    {    and 'MeisterBrau is #2.                                        }
    { NB: Delimited Non flag parameters (eg "Meister Brau")             }
    {  is now supported.                                                }

FUNCTION Non_Flag_Count : INTEGER;
    { Returns the number of non-flag type parameters }


FUNCTION WhereFlagOccurs(Flag : CHAR) : INTEGER;
    { Returns the index of any parameter}

VAR
    CompleteCommandLine : STRING;

IMPLEMENTATION
CONST
    Flag_Delims    : SET OF CHAR = ['/', '-'];
    No_of_string_delims = 3;
TYPE
    String_Delim_Type = ARRAY[1..3] OF RECORD
                                           Start,
                                           Stop           : CHAR
                                       END;
CONST
    String_Delims  : String_Delim_Type = (
         (Start : #39; Stop : #39),
         (Start : #34; Stop : #34),
         (Start : '['; Stop : ']')
         );


    FUNCTION LowerCaseChar(C : CHAR) : CHAR;
    BEGIN
        IF (C >= 'A') AND (C <= 'Z') THEN
            LowerCaseChar := CHAR(ORD(C) + $20)
        ELSE
            LowerCaseChar := C;
    END;


    {----------------------------------------------------------------------------}

    FUNCTION WhereFlagOccurs(Flag : CHAR) : INTEGER;
        {  returns the index number of the paramter where the flag occurs  }
        {  if the flag is never found, it returns 0                        }
    VAR
        Ti1            : INTEGER;
        Finished       : BOOLEAN;
        ParamCnt       : INTEGER;
        Ts1            : STRING;
    BEGIN
        Flag := LowerCaseChar(Flag);
        Finished := FALSE;
        Ti1 := 1;
        ParamCnt := PARAMCOUNT;
        WHILE NOT(Finished) DO BEGIN
            IF Ti1 > ParamCnt THEN BEGIN
                Finished := TRUE;
                Ti1 := 0;
            END ELSE BEGIN
                Ts1 := PARAMSTR(Ti1);
                IF (Ts1[1] IN Flag_Delims) AND (LowerCaseChar(Ts1[2]) = Flag) THEN
                    Finished := TRUE;
            END;
            IF NOT(Finished) THEN
                INC(Ti1);
        END;                      {While}
        WhereFlagOccurs := Ti1;
    END;

    {----------------------------------------------------------------------------}

    FUNCTION Is_Param(Flag : CHAR) : BOOLEAN;
    BEGIN
        IF WhereFlagOccurs(Flag) = 0 THEN
            Is_Param := FALSE
        ELSE
            Is_Param := TRUE;

    END;

    {----------------------------------------------------------------------------}

    FUNCTION Param_Int(Flag : CHAR) : LONGINT;
    VAR
        Param_loc      : INTEGER;
        Stat           : LONGINT;
        Ts1            : STRING;
        Ti1            : INTEGER;
    BEGIN
        Param_loc := WhereFlagOccurs(Flag);
        IF Param_loc = 0 THEN
            Stat := 0
        ELSE BEGIN
            Ts1 := PARAMSTR(Param_loc); { Get the string }
            Ts1 := COPY(Ts1, 3, 255); { Get rid of the delim and the flag }
            VAL(Ts1, Stat, Ti1);  { Make the value }
            IF Ti1 <> 0 THEN
                Stat := 0;        { Make sure there is no error }
        END;                      {If/Else}
        Param_Int := Stat
    END;

    {----------------------------------------------------------------------------}

    FUNCTION Param_Real(Flag : CHAR) : REAL;
    VAR
        Param_loc      : INTEGER;
        Stat           : REAL;
        Ts1            : STRING;
        Ti1            : INTEGER;
    BEGIN
        Param_loc := WhereFlagOccurs(Flag);
        IF Param_loc = 0 THEN
            Stat := 0.0
        ELSE BEGIN
            Ts1 := PARAMSTR(Param_loc); { Get the string }
            Ts1 := COPY(Ts1, 3, 255); { Get rid of the delim and the flag }
            VAL(Ts1, Stat, Ti1);  { Make the value }
            IF Ti1 <> 0 THEN
                Stat := 0.0;      { Make sure there is no error }
        END;                      {If/Else}
        Param_Real := Stat;
    END;

    {----------------------------------------------------------------------}

    FUNCTION Which_String_Delim(S : STRING) : BYTE;
  { Returns the index of the strings first character in the array
    of string_delims, if the first char of S isn't a delim it returns 0 }
    VAR
        Tc1            : CHAR;
        Tb1            : BYTE;
        Finished       : BOOLEAN;
        Stat           : BYTE;
    BEGIN
        Tc1 := S[1];
        Tb1 := 1;
        Finished := FALSE;
        WHILE NOT(Finished) DO BEGIN
            IF Tb1 > No_of_string_delims THEN BEGIN
                Stat := 0;
                Finished := TRUE;
            END
            ELSE BEGIN
                IF Tc1 = String_Delims[Tb1].Start THEN BEGIN
                    Stat := Tb1;
                    Finished := TRUE;
                END;
            END;
            IF NOT(Finished) THEN
                INC(Tb1);
        END;                      {While}
        Which_String_Delim := Stat;
    END;                          {function Which_String}

    {-------------------------------------------------------------------------}

    FUNCTION Param_Text(Flag : CHAR) : STRING;
    VAR
        Param_loc      : INTEGER;
        Param_cnt      : INTEGER;
        Stat           : STRING;
        Ts1            : STRING;
        Ti1            : INTEGER;
        S_delim        : BYTE;    { This should be 0(no string), 1', 2", 3[ }
        Finished       : BOOLEAN;
    BEGIN
        Param_loc := WhereFlagOccurs(Flag);
        IF Param_loc = 0 THEN Stat := ''
        ELSE BEGIN
            Ts1 := PARAMSTR(Param_loc); { Get the string }
            Ts1 := COPY(Ts1, 3, 255); { Get rid of the delim and the flag }
            { See if the first char of ts1 is one of the string_delims }
            S_delim := Which_String_Delim(Ts1);
            IF S_delim = 0 THEN
                Stat := Ts1
            ELSE BEGIN
                Stat := COPY(Ts1, 2, 255); { Drop the s_delim }
                Finished := FALSE;
                Param_cnt := PARAMCOUNT;
                WHILE NOT(Finished) DO BEGIN
                    INC(Param_loc);
                    IF Param_loc > Param_cnt THEN
                        Finished := TRUE
                    ELSE BEGIN
                        Ts1 := PARAMSTR(Param_loc);
                        IF Ts1[LENGTH(Ts1)] = String_Delims[S_delim].Stop THEN
                            Finished := TRUE;
                        Stat := Stat + ' ' + Ts1;
                    END;          { If/Else }
                END;              { While }
                Stat[0] := CHAR(LENGTH(Stat) - 1); { Drop the last delimeter }
            END;                  { If/Else a delimited string }
        END;                      { If/Else the flag is found }
        Param_Text := Stat;
    END;

    {---------------------------------------------------------------------------}

TYPE
    CharSet        = SET OF CHAR;

    FUNCTION Filter(S : STRING; CS : CharSet) : STRING;
        {-Return string S after removing all characters in CS from it}
    VAR
        I              : INTEGER;
        Len            : INTEGER;
    BEGIN
        FOR I := LENGTH(S) DOWNTO 1 DO
            IF (S[I] IN CS) THEN BEGIN
                Len := LENGTH(S) - I;
                IF Len <= 0 THEN
                    Len := 1;
                MOVE(S[I + 1], S[I], Len);
                {$IFDEF VirtualPascal}
                setlength(S, length(s)-1);
                {$ELSE}
                DEC(S[0]);
                {$ENDIF}
            END;

        Filter := S;
    END;

    {----------}

    FUNCTION Non_Flag_Param(Index : INTEGER) : STRING;
    VAR
        Param_cnt      : INTEGER;
        Ti1            : INTEGER;
        Strg,
        Ts1            : STRING;
        InQuote,
        Finished       : BOOLEAN;
        Cur_Index      : INTEGER;
        I              : BYTE;
    BEGIN
        Param_cnt := PARAMCOUNT;
        Cur_Index := 0;
        Ti1 := 0;
        Finished := FALSE;
        InQuote := FALSE;
        WHILE NOT(Finished) DO BEGIN
            INC(Ti1);
            IF Ti1 > Param_cnt THEN BEGIN
                Ts1 := '';
                Finished := TRUE;
            END
            ELSE BEGIN
                Ts1 := PARAMSTR(Ti1);

                Strg := '';

                IF (POS('"', Ts1) > 0) THEN BEGIN
                    REPEAT
                        FOR I := 1 TO LENGTH(Ts1) DO
                            IF Ts1[I] = '"' THEN
                                InQuote := NOT InQuote;
                        IF InQuote THEN BEGIN
                            INC(Ti1);
                            Strg := Strg + Ts1 + ' ';
                        END
                        ELSE BEGIN
                            Ts1 := Strg + ' ' + Ts1;
                            BREAK;
                        END;
                        Ts1 := PARAMSTR(Ti1);
                    UNTIL Ti1 > PARAMCOUNT;
                END;

                IF NOT(Ts1[1] IN Flag_Delims) THEN BEGIN
                    INC(Cur_Index);
                    IF Cur_Index = Index THEN BEGIN
                        Ts1 := Filter(Ts1, ['"']);
                        BREAK;
                    END;
                END;

            END;                  {If/Else}
        END;                      {While}
        Non_Flag_Param := Ts1;
    END;

    {---------------------------------------------------------------------------}

    FUNCTION Non_Flag_Count : INTEGER;
    VAR
        Stat           : INTEGER;
        Ti1            : INTEGER;
        Ts1            : STRING;
        InQuote        : BOOLEAN;
        I              : BYTE;
        Strg           : STRING;
    BEGIN
        InQuote := FALSE;
        Stat := 0;
        Ti1 := 1;

        REPEAT
            Ts1 := PARAMSTR(Ti1);
            Strg := '';
            IF (POS('"', Ts1) > 0) THEN
            REPEAT
                FOR I := 1 TO LENGTH(Ts1) DO
                    IF Ts1[I] = '"' THEN
                        InQuote := NOT InQuote;
                IF InQuote THEN BEGIN
                    INC(Ti1);
                    Strg := Strg + Ts1 + ' ';
                END
                ELSE BEGIN
                    Ts1 := Strg + ' ' + Ts1;
                    BREAK;
                END;
                Ts1 := PARAMSTR(Ti1);
            UNTIL Ti1 > PARAMCOUNT;

            IF NOT(Ts1[1] IN Flag_Delims) THEN
                INC(Stat);

            INC(Ti1);
        UNTIL Ti1 > PARAMCOUNT;
        Non_Flag_Count := Stat;
    END;

END.

