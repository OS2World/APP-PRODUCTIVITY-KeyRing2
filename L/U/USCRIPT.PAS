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
{$A-,R-,S-,V-,O+,F+}

Unit UScript;   { Communications script processor }

interface

Uses Dos,OpCrt,OpDos,OpString,UGlobal,UWindow,UMenu,UEdit,UDialog,UMsg;

Type
   TokenString = String[20];
   VarString   = String[1];

Procedure CreateScript;
Procedure EditScript;
Procedure ChooseScript(var Name: PathStr);
Procedure OpenScript(Name: PathStr);
Procedure CloseScript;
Function  ScriptVariable(ID: TokenString): VarString;
Function  NextWord: TokenString;
Procedure ReadScriptLine;

var
   Script_Key    : TokenString;
{   ScriptLine    : String[80];}
   ScriptLine    : String[1];
   ScriptInEffect: boolean;

implementation

var
   ScriptName    : PathStr;
   Escape        : boolean;
   Script        : text;
   Script_IX     : word;

   S0            : VarString;
   S1            : VarString;
   S2            : VarString;
   S3            : VarString;
   S4            : VarString;
   S5            : VarString;
   S6            : VarString;
   S7            : VarString;
   S8            : VarString;
   S9            : VarString;

   S_Vars        : Array[0..9] of VarString absolute S0;

Const
  Delims : Set of Char =
    [' ',#$0A,#$0D,'-','+','/','*','<','>','"',','];

{-----------------------------------------------------------}

Procedure CreateScript;
  begin
    ScriptName := '';
    GetInput(SysMsg(000890){'Script Name'},SysMsg(000359){'SCRIPT'},Blue,'',14,ScriptName,Escape);
    if Escape then exit;
    if Pos('.',Scriptname) <> 0 then
      begin
        Delete(ScriptName,Pos('.',ScriptName),4);
      end;
    ScriptName := ScriptName+'.SCR';
    if ExistFile(ScriptName) then
      if Dialog(ScriptName+SysMsg(000891){' exists, Overwrite?'},SysMsg(000359){'SCRIPT'},Red,'Yes','No ') <> 1
        then exit;
    Assign(Script,ScriptName);
    {$I-}
    Rewrite(Script);
    if IoResult <> 0 then exit;
    Close(Script);
    {$I+}
    EditFile(ScriptName);
  end;

{-----------------------------------------------------------}

Procedure EditScript;
  begin
    ChooseAndEditFile('*.SCR',False);
  end;

{-----------------------------------------------------------}

Procedure ChooseScript(var Name: PathStr);
  begin
    with UData^ do
      begin
        LastFilePath := '*.SCR';
        WaitForFilePrompt := False;
        GetFileName(SysMsg(000359){'Script'},Name);
        WaitForFilePrompt := True;
      end;
  end;

{-----------------------------------------------------------}

Procedure OpenScript(Name: PathStr);
  begin
    with UData^ do
      begin
        ScriptName := Name;
        if Pos('.',ScriptName) = 0 then
          ScriptName := ScriptName + '.SCR';
        if not ExistFile(ScriptName) then begin
          exit;
          end;
        Assign(Script,ScriptName);
        {$I-}
        Reset(Script);
        if IoResult <> 0 then exit;
        {$I+}
        ScriptInEffect := True;
      end;
  end;

{-----------------------------------------------------------}

Procedure CloseScript;
  begin
    with UData^ do
      begin
        if ScriptInEffect then
          Close(Script);
        ScriptInEffect := False;
      end;
  end;

{-----------------------------------------------------------}

Procedure ReadScriptLine;
  var I,J: integer;
  begin
    repeat
      ReadLn(Script,ScriptLine);
      ScriptLine := Trim(ScriptLine);
      until ((ScriptLine <> '') and (ScriptLine[1] <> '*'))
            or (EOF(Script));
    Script_Key := StUpCase(Trim(ExtractWord(1,ScriptLine,Delims)));
    Script_Ix  := 1;
    if Pos('"',ScriptLine) <> 0 then
      begin
        I := Pos('"',ScriptLine);
        J := I;
        S0 := '';
        repeat
          inc(I);
          if ScriptLine[I] <> '"' then
            S0 := S0+ScriptLine[I];
          until (I = Length(ScriptLine)) or (ScriptLine[I] = '"');
        Delete(ScriptLine,J,I-J+1);
        Insert('$S0',ScriptLine,J);
      end;
    if EOF(Script) then CloseScript;
  end;

{-----------------------------------------------------------}

Function NextWord: TokenString;
  begin
    NextWord := '';
    inc(Script_IX);
    if Script_IX > WordCount(ScriptLine,Delims) then exit;
    NextWord := StUpCase(ExtractWord(Script_IX,ScriptLine,Delims));
  end;

{-----------------------------------------------------------}

Function ScriptVariable(ID: TokenString): VarString;
  var I: word;
  begin
    if ID[1] <> '$' then exit;
    if ID[2] <> 'S' then exit;
    if Str2Word(Copy(ID,3,2),I) then
      ScriptVariable := S_Vars[I];
  end;

End.
