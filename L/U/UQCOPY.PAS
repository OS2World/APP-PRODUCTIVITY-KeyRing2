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
Unit UQCopy;

interface

Uses Dos,QFiles, UGlobal, MAEdit, UQlist, UNav_DOS, QLib,
     OpCrt, OpString, OpDos, OpEditor,UWindow,QNovell,QCmddsp,
     QCS, QDrive2, QHdr, QGlobal, QHdrRec, QHdrPut, QHdrIo, UMsg;

Type
  Str20 = String[20];

{  procedure CopyFileToQueue(var InputQ, OutputQ : PathStr; Title: Str20);}
  procedure CopyAttachedQHDRToQueue(VAR tHdr : RunDownRec;
                                    VAR F    : FILE);
  procedure CopyMailMsgBufferToQueue(VAR IOB  : IOBuffPtr);

  procedure CopyEditBufferToQueue(Editor: TextEditor;
                                  Var Server   : ServerStr;
                                  Var Volume   : VolumeStr;
                                  Var Path     : PathStr;
                                  Var QDriveID : Char;
                                      Title: Str20);

implementation

  Procedure ReleaseToDrive (Var ChangeToDrive : Drivename);
     begin
     ChangeDrive (ChangeToDrive);
     If Sys^.ToQFS <> '' Then
        Begin
        If (Sys^.ToQFS <> Sys^.BaseFS) And
           (Sys^.ToQFS <> Sys^.HomeFS) And
           (Sys^.ToQFS <> FW^.CurrentQFS) And
           (Sys^.ToQFS <> 'LOCAL') And
           (Sys^.ToQFS <> FW^.FwdLink^.CurrentQFS) Then
           Begin
           If Not ReleaseFileServer (Sys^.ToQFS) Then
              Msg (SysMsg(000310){'Unable To Release FS'},2);
           End;
        Sys^.ToQFS := '';
        End;
     End;

  Function GetUniqueQFilename(var Filenum: integer): boolean;
  var
    Tries: LongInt;
    Handle : Integer;
    ECode : integer;

  begin
  GetUniqueQFilename := False;
  Tries := 0;
  FileNum := Random(32000);
  While Not CreateNewFile ('Q'+Long2Str(FileNum), Handle, ECode) Do
    begin
    FileNum := Random(32000);
    inc(Tries);
    if Tries > 32000 then exit;
    end;
  CloseFile (Handle,True);
  GetUniqueQFilename := True;
end;

(*
  procedure CopyFileToQueue(var InputQ, OutputQ : PathStr; Title: Str20);
  const
    IoBufSize = 2048;
  type
    IoBufType = Array[1..IoBufSize] of byte;
  var
    RetryCount               : Integer;
    DoExit                   : Boolean;
    Rc, IoRes                : Integer;
    FileVar                  : file;
    W                        : Word;
    ErrorCount               : LongInt;
    ErrorCode                : Integer;
    FileName                 : integer;
    i                        : integer;
    IFileName                : PathStr;
    OldFileName              : PathStr;
    NewFileName              : PathStr;
    CDir                     : DirStr;
    WLog                     : Text;
    IoBuf                    : ^IoBufType;
    HdrDirectory             : RundownRec;
    SaveDrive                : DriveName;
  begin
  SaveDrive := Sys^.CurrentDriveID;
  ChngToNENQ(OutputQ);

  DoExit := False;
  RetryCount := 0;

  ErrorCount := 0;
  while (not HdrOpenWrite(i)) and (ErrorCount < MaxLongInt) do
    Inc(ErrorCount);

  if ErrorCount < MaxLongInt then { Didn't fail timeout }
    begin
    if not ReadHdr(HdrDirectory, 0) then Exit;
    if HdrDirectory.FirstFree = 0 then
      begin
      if not ReadHdr(Hdr, HdrDirectory.LastLink) then Exit;
      HdrAddress := HdrDirectory.LastLink;
      ErrorCode := 1;
      ErrorCount := 0;
      end;
    end;

    if not GetUniqueQFilename(Filename) then exit;

    New(IoBuf);
    CopyFile(InputQ, NewFileName, IoBuf, IoBufSize);  {!!!DLK}
    Dispose(IoBuf);

    OutputQ := NewFileName;

    InitInUseHdr(Hdr);

    { Put header data into file header }

    Hdr.DosScriptFile := FileName;
    Hdr.Slug := Title;

    ErrorCode  := 1;
    ErrorCount := 0;

    while ErrorCode = 1 do
      begin
      if not PutHdr(Hdr, nil, HdrAddress, ErrorCode, False) then
        begin
        if not ((ErrorCode > 1) or(ErrorCount = MaxLongInt)) then
          begin
          Inc(ErrorCount);
          GetDir(0, CDir);
          if ErrorCount > 5000 then
            Halt(1);
          end;
        end;
      end;
    CloseHdr;

  ReleaseToDrive (SaveDrive);
  end;
 *)

  procedure CopyAttachedQHDRToQueue(VAR tHdr : RunDownRec;
                                    VAR F : FILE);
  const
    IoBufSize = 2048;
  type
    IoBufType = Array[1..IoBufSize] of byte;
  var
    Rc, IoRes                : Integer;
    FileVar                  : file;
    W                        : Word;
    ErrorCount               : LongInt;
    ErrorCode                : Integer;
    FileName                 : integer;
    i                        : integer;
    NewFileName              : String[8];
    CDir                     : DirStr;
    WLog                     : Text;
    IoBuf                    : ^IoBufType;
    HdrDirectory             : RundownRec;
    AllQ                     : Boolean;
    Queue                    : AnyString;
    SaveDrive                : DriveName;
    Result                   : Integer;
    T                        : File;
    Server                   : ServerStr;
    Volume                   : VolumeStr;
    Path                     : PathStr;
    QRights                  : Access;
    QType                    : QueueTypes;
    QDrive                   : Char;
    AllLevels                : Boolean;

  begin
  AllQ := False;
  AllLevels := False;
  Server := '';
  Volume := '';
  Path := '';
  QType := qtAll;
  if Not ChooseQueue(Server, Volume, Path, QRights, QType, QDrive,
     AllQ, AllLevels, 'Select Queue') then
     Exit;

  SaveDrive := Sys^.CurrentDriveID;

  If Not CheckIfGoodQ (Server, Volume, Path, QDrive, Result,Sys^.ToDrive,
     Sys^.ToQFS, False) Then
     Begin
     Case Result Of
        1 : Begin
            if Dialog(SysMsg(002383{Cannot Put Into A Wire Q}),SysMsg(254), Red,
                      SysMsg(002384{OK}),'','')=0 then;
            ReleaseToDrive(SaveDrive);
        End;

        2 : Begin
            if Dialog(SysMsg(002382{Cannot Put Into An Archive Q}),SysMsg(254), Red,
                      SysMsg(002384{OK}),'','')=0 then;
            ReleaseToDrive(SaveDrive);
        End;
        End; {Case}
     Exit;
     End;
  ChangeDrive (Sys^.ToDrive);

  If Not HdrOpenWrite(i) Then
     Begin
     if Dialog(SysMsg(000050{Unable To Open Hdr}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive (SaveDrive);
     Exit;
     End;

  if not ReadHdr(HdrDirectory, 0) then
     Begin
     CloseHdr;
     ReleaseToDrive (SaveDrive);
     Exit;
     End;

  if (HdrDirectory.QType = ArchiveQ) Then
     begin
     CloseHdr;
     if Dialog(SysMsg(002382{Cannot Put Into An Archive Q}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive (SaveDrive);
     Exit;
     End;

  if (HdrDirectory.QType = WireQ) Then
     begin
     CloseHdr;
     if Dialog(SysMsg(002383{Cannot Put Into A Wire Q}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive (SaveDrive);
     Exit;
     End;

  if not GetUniqueQFilename(Filename) then
     Begin
     CloseHdr;
     ReleaseToDrive (SaveDrive);
     exit;
     End;

  Str (FileName, NewFileName);

  New(IoBuf);
  If IoBuf = Nil Then
     Begin
     CloseHdr;
     ReleaseToDrive (SaveDrive);
     End;

  Assign (T,'Q'+NewFileName);
  ReWrite (T,1);
  REPEAT
      BLOCKREAD(F, IOBuf^, SIZEOF(IOBuf^), Result);
      BLOCKWRITE(T, IOBuf^, Result, Result);
  UNTIL Result <> SIZEOF(IOBuf^);
  Dispose(IoBuf);
  Close (T);

  THdr.DosScriptFile := FileName;

  { Put header data into file header }


  ErrorCode  := 1;
  ErrorCount := 0;
  NENFlag := False;

  while ErrorCode = 1 do
    begin
    if not PutHdr(THdr, nil, HdrAddress, ErrorCode, False) then
      begin
      if not ((ErrorCode > 1) or(ErrorCount = MaxLongInt)) then
        begin
        Inc(ErrorCount);
        GetDir(0, CDir);
        if ErrorCount > 5000 then
          Halt(1);
        end;
      end;
    end;
  NENFlag := True;
  CloseHdr;

  ReleaseToDrive (SaveDrive);
  end;



  procedure CopyMailMsgBufferToQueue(VAR IOB  : IOBuffPtr);

Var
    AllQ                     : Boolean;
    Queue                    : AnyString;
    SaveDrive                : DriveName;
    T                        : Text;
    THdr                     : RundownRec;
    HdrDirectory             : RundownRec;
    ErrorCount               : LongInt;
    ErrorCode                : Integer;
    i                        : integer;
    FileName                 : integer;
    NewFileName              : String[8];
    CDir                     : DirStr;
    NewSlug                  : SlugSt;
    Server                   : ServerStr;
    Volume                   : VolumeStr;
    Path                     : PathStr;
    QRights                  : Access;
    AllLevels                : Boolean;
    QType                    : QueueTypes;
    QDrive                   : Char;
    LeftMargin               : Word;
    RightMargin              : Word;


Procedure CompressToken (Var TokenLine : String;
                             Token : UserName;
                             Attribute : Byte);

Var TokenPos : Integer;
    AttributeS : String[1];

   Begin
   AttributeS := Chr(Attribute);
   TokenPos := Pos (Token, TokenLine);
   If TokenPos = 0 Then
      Exit;
   Delete (TokenLine, TokenPos, Length(Token));
   System.Insert (AttributeS, TokenLine, TokenPos);
   End;

Function CountCharsInLine (Var CLIn : String) : Word;
Var W : Word;
    I : Integer;

   Begin
   CompressToken (CLIn, SysMsg (002387){BoldMode}, 2);
   CompressToken (CLin, SysMsg (002388){NoPromptMode}, 3);
   CompressToken (CLin, SysMsg (002547){UnderlineMode}, 4);
   CompressToken (CLin, SysMsg (002389){NormalMode}, 5);
   CompressToken (CLin, SysMsg (002390){KeywordMode}, 6);
   CompressToken (CLin, SysMsg (002391){BadSpellMode}, 7);
   CompressToken (CLin, SysMsg (002392){NoCaptionMode}, 8);
   CompressToken (CLin, SysMsg (002393){NoCaptionMode}, 15);
   CompressToken (CLin, SysMsg (002394){ChyronMode}, 18);
   CompressToken (CLin, SysMsg (002395){ChyronStart},22);

   W := 0;
   For I := 1 To Length(CLIn) Do
      If CLIn[I] >= ' ' Then
         W := W + 1;
   CountCharsInLine := W;
   End;

Procedure CheckForWordWrap (Var CurrentLine : String;
                            Var Margin : Word;
                            Var LineNumber : LongInt;
                                DoOutput : Boolean;
                                LeftSide : Boolean);

Var OverflowLine : String;
    L : Word;
    I : Integer;
    S : String[5];

   Begin
   If CountCharsInLine (CurrentLine) <= Margin Then
      Exit;

   OverFlowLine := CurrentLine;
   L := Margin;
   While (L > 0) And (CurrentLine[L] <> ' ') Do
      L := L -1;

   If L > 0 Then
      Begin
      OverFlowLine[0] := Chr(L-1);
      Delete (Currentline,1,L);
      End
      Else
      begin
      CurrentLine := '';
      OverFlowLine := OverFlowLine + ' ';
      End;

   LineNumber := LineNumber + 1;
   If Not DoOutput Then
      Exit;

   If LeftSide Then
      Begin
      Str (LineNumber-1,S);
      For I := 1 To Length(S) Do
         Write (T,S[I]);
      Write (T,':');
      End;

   For I := 1 To Length(OverFlowLine) Do
      Write (T,OverFlowLine[I]);
   Write (T,#$0D);
   Write (T,#$0A);
   End;


Procedure OutputScriptText (LeftSide : Boolean);
Var LeftLine, RightLine : String[80];
    BuffCount : Longint;
    MaxBuffCount : Longint;
    FirstLeft, FirstRight : Boolean;
    LeftLineNumber : Longint;
    RightLineNumber : Longint;
    InLeftSide : Boolean;
    LineS : String[5];
    I : Integer;
    WasLineEnd : Boolean;


   begin
   RightLine := '';
   LeftLine := '';
   InLeftSide := False;
   Firstleft := False;
   FirstRight := False;
   BuffCount := 1;
   MaxBuffCount := 1;
   LeftLineNumber := 1;
   RightLineNumber := 1;
   WasLineEnd := False;
   Repeat
      Begin
      MaxBuffCount := MaxBuffCount + 1;
      End
   Until (IOB^[maxBuffCount] = #26) Or (MaxBuffCount > MailBufSize);

   If IOB^[MaxBuffCount] = #26 Then
      begin
      MaxBuffCount := MaxBuffCount - 3;
      While (MaxBuffCount > 1) And (IOB^[MaxBuffCount] = '-') Do
         MaxBuffCount := MaxBuffCount - 1;
      End
      Else
      begin
      MaxBuffCount := MailBufSize;
      End;

   Repeat
      Begin
      Case IOB^[BuffCount] Of
      #$0A : Begin
      If InLeftSide Then
         Begin
         Str (LeftLineNumber, LineS);
         If LeftSide Then
            Begin
            For I := 1 To Length(LineS) Do
               Write (T,LineS[I]);
            Write (T,':');
            For I := 1 To Length(LeftLine) Do
               Write (T,LeftLine[I]);
{            Write (T,#$0D);
            Write (T,#$0A); }
            Write (T,#$0D);
            Write (T,#$0A);
            LeftLine := '';
            WasLineEnd := False;
            End;
         End
         Else
         Begin
         If Not LeftSide Then
            Begin
            For I := 1 To Length(RightLine) Do
               Write (T,RightLine[I]);
{            Write (T,#$0D);
            Write (T,#$0A); }
            Write (T,#$0D);
            Write (T,#$0A);
            End;

         RightLine := '';
         If Not WasLineEnd Then
            RightLineNumber := RightLineNumber + 1;
         WasLineEnd := True;
         End;
      End;
      #$0D : Begin
      End;
      '<' : Begin
      If FirstLeft Then
         Begin
         InLeftSide := True;
         End
         Else
         Begin
         FirstLeft := True;
         End;
      End;
      '>' : Begin
      If FirstRight Then
         Begin
         If InLeftSide Then
            Begin
            Str (LeftLineNumber, LineS);
            If LeftSide Then
               Begin
               For I := 1 To Length(LineS) Do
                  Write (T,LineS[I]);
               Write (T,':');
               For I := 1 To Length(LeftLine) Do
                  Write (T,LeftLine[I]);
               Write (T,#$0D);
               Write (T,#$0A);
{               Write (T,#$0D);
               Write (T,#$0A); }
               LeftLine := '';
               WasLineEnd := False;
               End;
            End;
         InLeftSide := False;
         End
         Else
         Begin
         FirstRight := True;
         End;
      End;
      Else
      Begin
      WasLineEnd := False;
      If InLeftSide Then
         Begin
         If FirstRight Then
            begin
            LeftLine := LeftLine + '>';
            End;
         LeftLine := LeftLine + IOB^[BuffCount];
         If RightLineNumber > LeftLineNumber Then
            LeftLineNumber := RightLineNumber - 1;
         If LeftSide Then
            CheckForWordWrap (LeftLine, LeftMargin, LeftLineNumber,
               True,LeftSide);
            CheckForWordWrap (LeftLine, LeftMargin, LeftLineNumber,
               False,LeftSide);
         End
         Else
         Begin
         If FirstLeft Then
            begin
            RightLine := RightLine + '<';
            End;
         RightLine := RightLine + IOB^[BuffCount];
         If RightLineNumber > LeftLineNumber Then
            LeftLineNumber := RightLineNumber - 1;
         If Not LeftSide Then
            CheckForWordWrap (RightLine, RightMargin, RightLineNumber,
               True, LeftSide);
            CheckForWordWrap (RightLine, RightMargin, RightLineNumber,
               False, LeftSide);
         End;
      FirstRight := False;
      FirstLeft := False;
      End;
      End; {Case}
      BuffCount := BuffCount + 1;
      End;
   Until (BuffCount > MaxBuffCount);
   End;

  begin
  AllQ := False;
  AllLevels := False;
  Server := '';
  Volume := '';
  Path := '';
  QType := qtAll;
  if Not ChooseQueue(Server, Volume, Path, QRights, QType, QDrive,
     AllQ, AllLevels, 'Select Queue') then
     Exit;

  SaveDrive := Sys^.CurrentDriveID;

  If Not CheckIfGoodQ (Server, Volume, Path, QDrive, i, Sys^.ToDrive,
     Sys^.ToQFS, False) Then
     Begin
     Case I Of
        1 : Begin
            if Dialog(SysMsg(002383{Cannot Put Into A Wire Q}),SysMsg(254), Red,
                      SysMsg(002384{OK}),'','')=0 then;
            ReleaseToDrive(SaveDrive);
        End;

        2 : Begin
            if Dialog(SysMsg(002382{Cannot Put Into An Archive Q}),SysMsg(254), Red,
                      SysMsg(002384{OK}),'','')=0 then;
            ReleaseToDrive(SaveDrive);
        End;
        End; {Case}

     Exit;
     End;

  ChangeDrive (Sys^.ToDrive);

  If Not HdrOpenWrite(i) Then
     Begin
     if Dialog(SysMsg(000050{Unable To Open Hdr}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive (SaveDrive);
     Exit;
     End;

  if not ReadHdr(HdrDirectory, 0) then
     Begin
     CloseHdr;
     ReleaseToDrive (SaveDrive);
     Exit;
     End;

  if (HdrDirectory.QType = ArchiveQ) Then
     begin
     CloseHdr;
     if Dialog(SysMsg(002382{Cannot Put Into An Archive Q}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive (SaveDrive);
     Exit;
     End;

  if (HdrDirectory.QType = WireQ) Then
     begin
     CloseHdr;
     if Dialog(SysMsg(002383{Cannot Put Into A Wire Q}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive (SaveDrive);
     Exit;
     End;

  InitInUseHdr (THdr);

  Case HdrDirectory.ScriptOrText of
      sn_Script      : THdr.BStatus := THdr.BStatus or S_Script;
      sn_Text        : THdr.BStatus := THdr.BStatus and (not S_Script);
      sn_Default     : if HdrDirectory.Qtype = RundownQ then
                         THdr.BStatus := THdr.BStatus or S_Script
                       else
                         THdr.BStatus := THdr.BStatus and (not S_Script);
      sn_Ask         : Case Dialog('Script or Text?','File As',Blue,'Script','Text','') of
                         1 : THdr.BStatus := THdr.BStatus or S_Script;
                         2 : THdr.BStatus := THdr.BStatus and (not S_Script);
                       end;
    end;

  if not GetUniqueQFilename(Filename) then
     Begin
     CloseHdr;
     ReleaseToDrive (SaveDrive);
     exit;
     End;

  Str (FileName, NewFileName);

  Assign (T,'Q'+NewFileName);
  ReWrite (T);

  If THdr.BStatus And S_Script = S_Script Then
     Begin
     RightMargin := Sys^.ScriptRMargin;
     LeftMargin  := Sys^.CuesRMargin;

     Write (T,Chr(8));
     Write (T,Chr(1));
     For I := 1 To 20 Do
        Begin
        If I <= Length (THdr.Slug) Then
           Write (T,THdr.Slug[I]) Else
           Write (T,' ');
        End;

     OutputScriptText (True);
{Insert left Side Stuff here}
     Write (T,Chr(9));
     Write (T,Chr(8));
     Write (T,Chr(9));
     OutputScriptText (False);
     End
     Else
     begin
     I := 1;
     Repeat
        Begin
        Write (T,IOB^[I]);
        Inc (I);
        End
     Until (IOB^[I] = #26) Or (I > MailBufSize);
     End;

  Write(T,Chr(26));
  Write(T,Chr(26));
  Close (T);

  NewSlug := '';
  I := 1;
  Repeat
     Begin
     NewSlug := NewSlug + IOB^[I];
     Inc (I);
     End;
  Until (I > 20) Or (IOB^[I] = #26) Or
        (IOB^[I] = #13) Or (IOB^[I] = #10);

  While (NewSlug <> '') And (NewSlug[Length(NewSlug)] = ' ') Do
     Delete (NewSlug, Length(NewSlug), 1);

  If NewSlug = '' Then
     NewSlug := SysMsg (002397){This Slug From Mail};

  THdr.Slug := NewSlug;
  THdr.DosScriptFile := FileName;
  If THdr.BStatus And S_Script = S_Script Then
     THdr.TextRMargin := SYS^.ScriptRMargin;
  THdr.BStatus := THdr.BStatus Or S_ReformatMe;
  { Put header data into file header }

  ErrorCode  := 1;
  ErrorCount := 0;
  NENFlag := False;

  while ErrorCode = 1 do
    begin
    if not PutHdr(THdr, nil, HdrAddress, ErrorCode, False) then
      begin
      if not ((ErrorCode > 1) or(ErrorCount = MaxLongInt)) then
        begin
        Inc(ErrorCount);
        GetDir(0, CDir);
        if ErrorCount > 5000 then
          Halt(1);
        end;
      end;
    end;
  NENFlag := True;
  CloseHdr;

  ReleaseToDrive (SaveDrive);
  end;


  procedure CopyEditBufferToQueue (Editor: TextEditor;
                                  Var Server   : ServerStr;
                                  Var Volume   : VolumeStr;
                                  Var Path     : PathStr;
                                  Var QDriveID : Char;
                                      Title: Str20);
  var
    RetryCount               : Integer;
    DoExit                   : Boolean;
    Rc, IoRes                : Integer;
    FileVar                  : file;
    W                        : Word;
    ErrorCount               : LongInt;
    ErrorCode                : Integer;
    FileName                 : integer;
    i                        : integer;
    IFileName                : PathStr;
    OldFileName              : PathStr;
    NewFileName              : PathStr;
    CDir                     : DirStr;
    WLog                     : Text;
    HdrDirectory             : RundownRec;
    SaveName                 : PathStr;
    S                        : PathStr;
    F                        : File;
    Header                   : Array[1..25] of char;
    SaveDrive                : DriveName;
    Hdr                      : RunDownRec;
    ErrCode                  : Integer;
    MakeAScript              : Boolean;

  begin
  MakeAScript := False;
  SaveDrive := Sys^.CurrentDriveID;

  If Not CheckIfGoodQ (Server, Volume, Path, QDriveID, ErrCode, Sys^.ToDrive,
     Sys^.ToQFS, False) Then
     Begin
     Case ErrCode Of
        1 : Begin
            if Dialog(SysMsg(002383{Cannot Put Into A Wire Q}),SysMsg(254), Red,
                      SysMsg(002384{OK}),'','')=0 then;
            ReleaseToDrive(SaveDrive);
        End;

        2 : Begin
            if Dialog(SysMsg(002382{Cannot Put Into An Archive Q}),SysMsg(254), Red,
                      SysMsg(002384{OK}),'','')=0 then;
            ReleaseToDrive(SaveDrive);
        End;
        End; {Case}

     Exit;
     End;

  ChangeDrive (Sys^.ToDrive);

  If Not HdrOpenWrite(i) Then
     Begin
     if Dialog(SysMsg(000050{Unable To Open Hdr}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive(SaveDrive);
     Exit;
     End;

  if not ReadHdr(HdrDirectory, 0) then
     Begin
     CloseHdr;
     ReleaseToDrive(SaveDrive);
     Exit;
     End;

  if (HdrDirectory.QType = ArchiveQ) Then
     begin
     CloseHdr;
     if Dialog(SysMsg(002382{Cannot Put Into An Archive Q}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive(SaveDrive);
     Exit;
     End;

  if (HdrDirectory.QType = WireQ) Then
     begin
     CloseHdr;
     if Dialog(SysMsg(002383{Cannot Put Into A Wire Q}),SysMsg(254), Red,
               SysMsg(002384{OK}),'','')=0 then;
     ReleaseToDrive(SaveDrive);
     Exit;
     End;

  if not GetUniqueQFilename(Filename) then
     Begin
     CloseHdr;
     ReleaseToDrive(SaveDrive);
     exit;
     End;

  Str(FileName, NewFileName);
  NewFileName := 'Q' + NewFileName;

  InitInUseHdr(Hdr);

  { Put header data into file header }

  Hdr.DosScriptFile := FileName;
  Hdr.Slug := Title;

  Case HdrDirectory.ScriptOrText of
      sn_Script      : Hdr.BStatus := Hdr.BStatus or S_Script;
      sn_Text        : Hdr.BStatus := Hdr.BStatus and (not S_Script);
      sn_Default     : if HdrDirectory.Qtype = RundownQ then
                         Hdr.BStatus := Hdr.BStatus or S_Script
                       else
                         Hdr.BStatus := Hdr.BStatus and (not S_Script);
      sn_Ask         : Case Dialog('Script or Text?','File As',Blue,'Script','Text','') of
                         1 : Hdr.BStatus := Hdr.BStatus or S_Script;
                         2 : Hdr.BStatus := Hdr.BStatus and (not S_Script);
                       end;
    end;

  If Hdr.BStatus And S_Script = S_Script Then
     Hdr.TextRMargin := SYS^.ScriptRMargin;

  Hdr.BStatus := Hdr.BStatus Or S_ReformatMe;

  with Editor do
     begin
     meSaveCurrentLine(True);
     Assign(F, NewFileName);
     Rewrite(F, 1);
     I := IoResult;
     if I <> 0 then
       Close(F)
     else
       begin
       if Hdr.BStatus and S_Script <> 0 then
         begin
         Header[1] := #8;
         Header[2] := #1;
         S := Pad(Title,20);
         Move(S[1],Header[3],20);
         Header[23] := #9;
         Header[24] := #8;
         Header[25] := #9;
         BlockWrite(F, Header, 25);
         end;
       I := meTotalBytes;
       BlockWrite(F, meBufPtr^, I);
       I := IoResult;
       Close(F);
       end;
     End;
{  OutputQ := NewFileName;}

  ErrorCode  := 1;
  ErrorCount := 0;
  NENFlag := False;

  while ErrorCode = 1 do
    begin
    if not PutHdr(Hdr, nil, HdrAddress, ErrorCode, False) then
      begin
      if not ((ErrorCode > 1) or (ErrorCount = MaxLongInt)) then
        begin
        Inc(ErrorCount);
        GetDir(0, CDir);
        if ErrorCount > 5000 then
          Halt(1);
        end;
      end;
    end;
  NENFlag := True;
  CloseHdr;

  ReleaseToDrive (SaveDrive);
  end;

End.
