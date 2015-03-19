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
{$A-,R-,S-,V-,F+,O+}
Unit UCmdLine;         { Dos command line parser }

{ (C) 1990 NewsMaker Systems. }
{ Provides exact equivalents for PARAMCOUNT and PARAMSTR Turbo functions, }
{ named CPARAMCOUNT and CPARAMSTR that use the slash (/) character as the }
{ delimiter, with or without spaces in between.                           }
{ i.e. MYPROG /n/f/m=1000   or MYPROG /n /f /m=1000                       }
{ in each case, CParamCount would return 3, & CParamStr would return N F  }
{ and M=1000 (note upper case conversion)                                 }
{ A third routine CPARAMDELIMITER lets you change the delimiter character }
{ i.e. CParamDelimiter(',') would allow MYPROG n,f,m=1000                 }
{ Note that the delimiter is not required in front of the first command   }

interface

Uses Dos,OpString;

Type
  CLine = String[80];

Function CParamCount: word;
Function CParamStr(Num: word): CLine;
Procedure CParamDelimiter(D: Char);

implementation

var I: integer;
    Slash: Array[1..40] of byte;
    CommandCount : word;
    CommandLine : Cline;

Const
  Init: boolean = False;
  Delimiter: char = '/';

Procedure BuildSlashMap;
  begin
    if not Init then
      begin
        CommandLine := '';
        CommandCount := 0;
        for I := 1 to ParamCount do
          CommandLine := CommandLine+Trim(ParamStr(I));
        CommandLine := StUpCase(CommandLine);
        if CommandLine[1] <> Delimiter then
          CommandLine := Delimiter+CommandLine;
        Init := True;
        for I := 1 to length(CommandLine) do
          if CommandLine[I] = Delimiter then
            begin
              inc(CommandCount);
              Slash[CommandCount] := I;
            end;
        Slash[CommandCount+1] := Length(CommandLine)+1;
      end;
  end;

Function CParamCount: word;
  begin
    if ParamCount <> 0 then
      begin
        BuildSlashMap;
        CParamCount := CommandCount;
      end
    else
      CParamCount := 0;
  end;

Function CParamStr(Num: word): CLine;
  begin
    BuildSlashMap;
    CParamStr := Copy(CommandLine,Slash[Num]+1,Slash[Num+1]-(Slash[Num]+1));
  end;

Procedure CParamDelimiter(D: Char);
  begin
    Delimiter := D;
  end;

End.
