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
{$A-,R-,S-,V-,O+,F+}

Unit ULanguag;   { Load Language file & set up system }

interface

Uses
  Uini,
  Dos,
  QGlobal,
  OpCrt,
  OpString,
  OpDos,
  OpKey,
  QHdrRec,
  UMsg,
  OpCol16;

Const
  CommandsPerGroup = 15;
  ListGroups       = 10;
  EditGroups       = 11;

Type
  NameStr    = String[12];
  KeyStr     = String[30];
  KeyNameStr = String[8];

  CommandDescriptor = Record
      Command   : Char;            { Command letter *Internal*}
      UserCmd   : Char;            { Command letter user types }
      Name      : String[25];      { Description of command  }
      FKeyName  : KeyNameStr;      { Name of function key assigned }
      HelpIx    : Word;            { Index to hypertext help file }
      Contract  : String[6];       { Name contraction for function key display}
      Active    : Boolean;         { True if User is allowed this command }
      ChildPrg  : String[8];       { Program name if shelled external }
    end;

  GroupDescriptor = Record
      Group       : CommandDescriptor; { Descriptor for group level command }
      NumCommands : word;              { Number of commands in this group }
      Width       : word;              { Optimum width of pulldown submenu }
      Commands    : Array[1..CommandsPerGroup] of CommandDescriptor;
    end;

  CommandSet     = Array[1..50] of GroupDescriptor;
  ListCommandSet = Array[1..ListGroups] of GroupDescriptor;
  EditCommandSet = Array[1..EditGroups] of GroupDescriptor;

  KeyboardLevel = Array[1..72] of word;

  LanguageDescriptor = Record
      MsgFile     : NameStr;
      TDialect    : NameStr;
      HelpFile    : NameStr;
      SpellFile   : NameStr;
      ThesFile    : NameStr;
      SDialect    : DirStr; {may have extra room here}
      CountryCode : word;
      ListCommands: ListCommandSet;
      EditCommands: EditCommandSet;
      NumLGroups  : word;
      NumEGroups  : word;
      NumLCmds    : word;
      NumECmds    : word;
      KBDTable    : KeyboardLevel; {Ctrl+Alt level of keyboard }
    end;
  LanguageDescriptorPtr = ^LanguageDescriptor;

Var
  I            : integer;

Const
  LF           : LanguageDescriptorPtr = nil;

Type
  CmdString     = String[2];
  CommandString = String[20];

Function  LoadLanguage(LFile: PathStr): boolean;
Procedure SetCountryCode(Code: word; var Result: boolean);
Procedure ReplaceLCommand(Cmd: CmdString; NewName: NameStr);
Procedure ReplaceECommand(Cmd: CmdString; NewName: NameStr);
function FindListKeyForCommand(Cmd: CmdString; var KeyName: KeyNameStr; var Scan: word): boolean;
function FindEditKeyForCommand(Cmd: CmdString; var KeyName: KeyNameStr; var Scan: word): boolean;
function CleanupCommand(Cmd: CommandString): CommandString;

implementation

var Regs: Registers;

const
    CurrentLanguage : NameStr = '';

var
    LF2       : LanguageDescriptorPtr;

Procedure SetCountryCode(Code: word; var Result: boolean);
  begin
    with Regs do
      begin
        AH := $38;
        if Code < 255 then
          AL := byte(Code)
        else
          begin
            AL := $FF;
            BX := Code;
          end;
        DX := $FFFF;
        MsDos(Regs);
        Result := not (Ax = 2);
      end;
  end;

Function LoadLanguage(LFile: PathStr): boolean;
  var Result: boolean;
      G,C: word;
      LanguageFile : File of LanguageDescriptor;

  begin
    if StUpCase(JustName(LFile)) = CurrentLanguage then exit;
    Assign(LanguageFile,ForceExtension(LFile,'C'+LVersion));
    {$I-}
    Reset(LanguageFile);
    if IoResult <> 0 then
      begin
        LoadLanguage := False;
        exit;
      end;
    if LF = nil then
      begin
        New(LF);                    { First time, just read in }
        Read(LanguageFile,LF^);
      end
    else
      begin
        New(LF2);                   { replace current language }
        Read(LanguageFile,LF2^);    { Set active command list from login }
        for G := 1 to LF2^.NumLGroups do
          for C := 1 to LF2^.ListCommands[G].NumCommands do
            begin
              LF2^.ListCommands[G].Commands[C].Active :=
                   LF^.ListCommands[G].Commands[C].Active;
              LF2^.ListCommands[G].Commands[C].FKeyName :=
                   LF^.ListCommands[G].Commands[C].FKeyName;
            end;


        for G := 1 to LF2^.NumEGroups do
          for C := 1 to LF2^.EditCommands[G].NumCommands do
            begin
              LF2^.EditCommands[G].Commands[C].Active :=
                   LF^.EditCommands[G].Commands[C].Active;
              LF2^.EditCommands[G].Commands[C].FKeyName :=
                   LF^.EditCommands[G].Commands[C].FKeyName;
            end;

        Move(LF2^,LF^,SizeOf(LanguageDescriptor));
        LF^.KBDTable := LF2^.KBDTable;
        Dispose(LF2);

      end;
    Close(LanguageFile);
    if IoResult <> 0 then
      begin
        LoadLanguage := False;
        exit;
      end;
    {$I+}
    CurrentLanguage := StUpCase(JustName(LFile));
    OpenMsgFile(LF^.MsgFile);
    LoadLanguage := True;
{    SetCountryCode(LF^.CountryCode,Result);}
  end;

Procedure ReplaceLCommand(Cmd: CmdString; NewName: NameStr);
  var G,C: word;
  begin
    with LF^ do
      begin
        for G := 1 to NumLGroups do
          for C := 1 to ListCommands[G].NumCommands do
            if ListCommands[G].Group.Command +
               ListCommands[G].Commands[C].Command = Cmd then
                 begin
                   ListCommands[G].Commands[C].Name := NewName;
                   exit;
                 end;
      end;
  end;

Procedure ReplaceECommand(Cmd: CmdString; NewName: NameStr);
  var G,C: word;
  begin
    with LF^ do
      begin
        for G := 1 to NumEGroups do
          for C := 1 to EditCommands[G].NumCommands do
            if EditCommands[G].Group.Command +
               EditCommands[G].Commands[C].Command = Cmd then
                 begin
                   EditCommands[G].Commands[C].Name := NewName;
                   exit;
                 end;
      end;
  end;

function CleanupCommand(Cmd: CommandString): CommandString;
begin
  Cmd := StUpCase(Trim(Cmd));
  While Cmd[1] in ['A'..'Z',' '] do
    Delete(Cmd,1,1);
  CleanupCommand := Cmd;
end;

function FindListKeyForCommand(Cmd: CmdString; var KeyName: KeyNameStr; var Scan: word): boolean;
  var G,C: word;
      SC: word;
      I : word;
      Base : byte;
  begin
    FindListKeyForCommand := False;
    with LF^ do
      begin
        for G := 1 to NumLGroups do
          for C := 1 to ListCommands[G].NumCommands do
            if ListCommands[G].Group.Command +
               ListCommands[G].Commands[C].Command = Cmd then
                 begin
                   KeyName := Trim(ListCommands[G].Commands[C].FKeyName);
                   if KeyName = '' then
                     Continue;
                   Case UpCase(KeyName[1]) of
                     'F'    :  Base := $3B;
                     'S'    :  Base := $54;
                     'C'    :  Base := $5E;
                     'A'    :  Base := $68;
                   end;
                   Val(CleanupCommand(KeyName), I, G);
                   Scan := (Base + (I-1)) SHL 8;
                   FindListKeyForCommand := True;
                   exit;
                 end;
      end;
  end;

function FindEditKeyForCommand(Cmd: CmdString; var KeyName: KeyNameStr; var Scan: word): boolean;
  var G,C: word;
      SC: word;
      I : word;
      Base : byte;
  begin
    FindEditKeyForCommand := False;
    with LF^ do
      begin
        for G := 1 to NumEGroups do
          for C := 1 to EditCommands[G].NumCommands do
            if EditCommands[G].Group.Command +
               EditCommands[G].Commands[C].Command = Cmd then
                 begin
                   KeyName := Trim(EditCommands[G].Commands[C].FKeyName);
                   if KeyName = '' then
                     Continue;
                   Case UpCase(KeyName[1]) of
                     'F'    :  Base := $3B;
                     'S'    :  Base := $54;
                     'C'    :  Base := $5E;
                     'A'    :  Base := $68;
                   end;
                   Val(CleanupCommand(KeyName), I, G);
                   Scan := (Base + (I-1)) SHL 8;
                   FindEditKeyForCommand := True;
                   exit;
                 end;
      end;
  end;

procedure GetDefaultLanguage;
Var
  SRec : SearchRec;
  FirstName : String[13];
  CurFile      : PathStr;
  Param : AnyString;

   Begin
   if OpenINIFile(DefaultCmdLine.NENINIFile) then
      begin
      CurFile := FindKeyString('SYSTEM',    'DIRECTORY', '\NENSYS');
      If CurFile[Length(CurFile)] = ' ' Then
         Delete (CurFile, Length(CurFile),1);
      If CurFile[Length(CurFile)] <> '\' Then
         CurFile := CurFile + '\';
      SetMsgPath(CurFile);
      CloseIniFIle;
      end
      else
      Begin
      WriteLn('! NEN.INI not Found');
      Halt;
      End;

   If DefaultCmdLine.DefaultLanguage = '' Then
      Begin
      FindFirst (CurFile + '*.LAN',AnyFile, SRec);
      If DOSError <> 0 Then
         Begin
         DefaultCmdLine.DefaultLanguage := 'ENGLISH';
         End
         Else
         begin
         FirstName := SRec.Name;

         FindNext (Srec);
         If DOSError <> 0 Then
            Begin
            FirstName[0] := Chr(Pos('.',FirstName)-1);
            DefaultCmdLine.DefaultLanguage := FirstName;
            End
            Else
            Begin
            DefaultCmdLine.DefaultLanguage := 'ENGLISH';
            Repeat
               FindNext (Srec);
            Until DOSError <> 0;
            End;
         End;
      End;

   If OpenINIFile(CurFile + DefaultCmdLine.DefaultLanguage+'.LAN') Then
      Begin
      With Sys^ Do
         begin
         SpellLanguage := FindKeyString('SPELL','LANGUAGE','AMERICAN');

         Param := FindKeyString ('THESAURUS', 'TYPE', 'STREET');
         ThesaurusDictType := ThesTypeLut[SLStreet];
         If Param = 'FINANCIAL' Then   { Banking, Finance and Insurance   }
            ThesaurusDictType := ThesTypeLut[SLFinancial];
         If Param = 'LEGAL'     Then   { Legal                            }
            ThesaurusDictType := ThesTypeLut[SLLegal];
         If Param = 'MEDICAL'   Then   { Medicine                         }
            ThesaurusDictType := ThesTypeLut[SLMedical];
         If Param = 'SCIENCE'   Then   { Science                          }
            ThesaurusDictType := ThesTypeLut[SLScience];
         If Param = 'STREET'    Then   { None of the above (KGM)          }
            ThesaurusDictType := ThesTypeLut[SLStreet];

         CmdFilelanguage := FindKeyString ('COMMAND', 'LANGUAGE', 'ENGLISH');
         End;
      CloseINIFile;
      End
      Else
      Begin
      With Sys^ Do
         Begin
         SpellLanguage := 'AMERICAN';
         ThesaurusDictType := ThesTypeLut[SLStreet];
         CmdFilelanguage := 'ENGLISH';
         End;
      End;

   if not LoadLanguage(CurFile+Sys^.CmdFileLanguage) then
      begin
      if not LoadLanguage('ENGLISH.C'+LVersion) then
         WriteLn('Cannot load '+DefaultCmdLine.DefaultLanguage+'.C'+LVersion+'!');
      end;
   End;



var
  OPath: ^PathStr;

Begin
   New(OPath);
   GetDir(0, OPath^);
   LanguageDrive := UpCase(OPath^[1]);
   Dispose(OPath);
   GetDefaultLanguage;

End.
