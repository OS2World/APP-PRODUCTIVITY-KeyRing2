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
{$A-,R-,S-,V-,F+}
{$IFNDEF Windows}
{$O+}
{$ENDIF}

Unit UMsg;

interface

Uses
     {$IFNDEF Windows}
     Dos, OpCrt, OpString, OpDOS,
     {$ELSE}
     WinDos, WinSYS, Strings, N_Glo,
     {$ENDIF}
     QGlobal,URline;

Type
  MsgLine = String[80];

  { Routines for accessing message file }
Procedure SetMsgPath(Mspath: DirStr);
Procedure OpenMsgFile(MSname: PathStr);
Function  SysMsg(MsgNum: LongInt): MsgLine;
Procedure CloseMsgFile;
Procedure CheckMsgFile;
Procedure Encrypt(var S: String);
Procedure Decrypt(var S: String);

  { Routines for accessing supplemental translate file }
Function Translate(var InString: String): String;

Const
  LanguageDrive: char = 'C';
  MsgIndexBuffer : PBufferArray = Nil;

implementation

var MFile  : FileOfLinesPtr;    { Fast text object }

Const
    MsgOpen : boolean = False;
    MsgInit : boolean = False;

    Timeout  = 500;           { Milliseconds since last access }
    MsgPath : DirStr = '';

    CacheSize = 15;

Type
    MsgCacheLine = Record
      Msg    : MsgLine;
      MsgNum : LongInt;
      end;

    MsgCacheBuffer = Object
      MsgBuffer : Array[1..CacheSize] of MsgCacheLine;
      CachePtr  : byte;
      Constructor Init;
      Destructor Done;
      procedure UpdateCache(NewNumber: LongInt;NewLine: MsgLine);
      function  InCache(Number: Longint; Var Msg: MsgLine): boolean;
      end;

Var
    LastAccess : LongInt;
    MsgName    : DirStr;
    MsgCache   : ^MsgCacheBuffer;

{-------------------------------------------------}
Constructor MsgCacheBuffer.Init;
  begin
    Fillchar(MsgBuffer,SizeOf(MsgBuffer),#0);
    CachePtr := 0;
  end;

{-------------------------------------------------}
Destructor MsgCacheBuffer.Done;
  begin
  end;

{-------------------------------------------------}
Procedure MsgCacheBuffer.UpdateCache(NewNumber: LongInt;NewLine: MsgLine);
  begin
    inc(CachePtr);
    if CachePtr > CacheSize then
      CachePtr := 1;
    MsgBuffer[CachePtr].Msg := NewLine;
    MsgBuffer[CachePtr].MsgNum := NewNumber;
  end;

{-------------------------------------------------}
Function MsgCacheBuffer.InCache(Number: Longint; Var Msg: MsgLine): boolean;
  var i: integer;
  begin
    if CachePtr = 0 then
      begin
        InCache := False;
        exit;
      end;
    for i := 1 to CacheSize do
      if MsgBuffer[i].MsgNum = Number then
        begin
          Msg := MsgBuffer[i].Msg;
          CachePtr := i;
          InCache := True;
          exit;
        end;
    InCache := False;
  end;

{-------------------------------------------------}
Procedure Encrypt(var S: String);
var I: integer;
begin
For I := 1 to length(S) do
  S[I] := chr(ord(S[I])+8);
end;

{-------------------------------------------------}
Procedure Decrypt(var S: String);
var I: integer;
begin
For I := 1 to length(S) do
  S[I] := chr(ord(S[I])-8);
end;

{-------------------------------------------------}
Procedure OpenMsgFile(MSname: PathStr);

  {$IFDEF Windows}
  var Temp: Array[0..79] of char;
      Temp1: Array[0..79] of char;
      Temp2: Array[0..79] of char;

  {$ENDIF}
(*  Type Rec512 = Record
          TheDate : Array[1..512] Of Byte;
          End;

       FRec512 = File Of Rec512;
       PRec512 = ^Rec512; *)

  Var TFIn : File;
      IXPath : PathStr;
      NBuffs : Integer;
      TempIB : Pointer;
      TempPB : PBufferArray;
      TotalLines : LongInt;
      I : Integer;
      SRec : SearchRec;
      SaveFileMode : Byte;

  begin
    if MsgOpen then
      CloseMsgFile;
    FileMode := 0;
    {$IFNDEF Windows}
    If MessageDrive <> ' ' Then
       Begin
       If Pos (':', MsgPath) = 2 Then
          Begin
          MsgPath[1] := MessageDrive;
          End
          Else
          Begin
          MsgPath := MessageDrive + ':' +MsgPath;
          ENd;
       End;

    If MsgIndexBuffer = Nil Then
       Begin
       IXPath := MsgPath+MSName;
       IXPath[Length(IXPath)-2] := 'X';
       IXPath[Length(IXPath)-1] := '0';
       IXPath[Length(IXPath)] := '6';
       FindFirst (IXPath, AnyFile, SRec);
       If (DOSError = 0) And (SRec.Size > 0) Then
          Begin
          SaveFileMode := FileMode;
          FileMode := 0;
          Assign (TFIn, IXPath);
          {$I-}
          Reset (TFIn, SRec.Size);
          {$I+}
          FileMode := SaveFileMode;
          If IOResult = 0 Then
             Begin
             GetMem (MsgIndexBuffer, SRec.Size);
             If MsgIndexBuffer <> Nil Then
                Begin
                {$I-}
                BlockRead (TFIn, MsgIndexBuffer^, 1);
                {$I+}

                If IOResult <> 0 Then
                   begin
                   FreeMem (MsgIndexBuffer, SRec.Size);
                   MsgIndexBuffer := Nil;
                   End;
                End;
             Close (TFIn);
             End;
          End;
       End;

    PermTBuf := MsgIndexBuffer;

    New(MFile,Init(ForceExtension(MsgPath+MSName,'L'+LVersion),512));
    If MsgIndexBuffer = Nil Then
       Begin
       TempIB := MFile^.ReturnBuffAdr (NBuffs,TotalLines);
       TempPB := TempIB;
       GetMem (MsgIndexBuffer, (NBuffs+1)* SizeOf(BufRec));
       If MsgIndexBuffer <> Nil Then
          begin
          MsgIndexBuffer^[1].LNo := TotalLines;
          MsgIndexBuffer^[1].FP := 0;
          Move (TempIB^, MsgIndexBuffer^[2], NBuffs * SizeOf(BufRec));
          Assign (TFIn, IXPath);
          {$I-}
          ReWrite (TFIn, (NBuffs+1) * SizeOf(BufRec));
          {$I+}
          If IOresult = 0 Then
             Begin
             BlockWrite (TFIn, MsgIndexBuffer^, 1);
             If IOResult <> 0 Then
                begin
                FreeMem (MsgIndexBuffer, (NBuffs+1) * SizeOf(BufRec));
                MsgIndexBuffer := Nil;
                End;
             Close (TFIn);
             End;
          End;
       End;

    PermTBuf := Nil;
    {$ELSE}
    StrPCopy(Temp1, MsgPath);
    StrPCopy(Temp2, MSName);
    StrCat(Temp1,Temp2);
    New(MFile,Init(StrPas(ForceExtension(Temp,Temp1,'L'+LVersion)),512));
    {$ENDIF}
    FileMode := 2;
    if MFile^.RFError <> 0 then
      exit;
    MsgName := MSName;
    LastAccess := TimeMS;
    MsgOpen := true;
    if not MsgInit then
      begin
        MsgInit := true;
        New(MsgCache,Init);
      end;
  end;

{-------------------------------------------------}
Function  SysMsg(MsgNum: LongInt): MsgLine;
  var NumString : String[6];
      Temp : MsgLine;
      Temp2: Array[0..10] of char;
      Er   : integer;
  begin
    SysMsg := '';
    if not MsgInit then exit;
    if MsgCache^.InCache(MsgNum,Temp) then
      begin
        SysMsg := Temp;
        exit;
      end;
    if not MsgOpen then OpenMsgFile(MsgName);
    with MFile^ do
      begin
        if RFError <> 0 then
          begin
            SysMsg := RFErrorString;
            exit;
          end;
        SeekLine(MsgNum+1);
        if MFile^.RFerror = 100 then
          begin
            {$IFDEF Windows}
            SysMsg := StrPas(Long2Str(Temp2,MsgNum))+'!!! Message lookup Error';
            {$ELSE}
            SysMsg := Long2Str(MsgNum)+'!!! Message lookup Error';
            {$ENDIF}
            exit;
          end;
        Decrypt(LastLine);
        {$IFNDEF Windows}
        Temp := Trim(LastLine);
        {$ELSE}
        Temp := StrPas(TrimPrim(StrPCopy(Temp2,LastLine)));
        {$ENDIF}
        Delete(Temp,1,1);
        Delete(Temp,Length(Temp),1);
        MsgCache^.UpdateCache(MsgNum,Temp);
        SysMsg := Temp;
        LastAccess := TimeMS;
        MFile^.RFerror := 0;
      end;
  end;

{-------------------------------------------------}
Procedure CloseMsgFile;
  begin
    if not MsgOpen then exit;
    MFile^.FClose;
    Dispose(MFile,Done);
    MsgOpen := False;
  end;

{-------------------------------------------------}
{This function fragments the heap - a lot.  Shut it off during}
{heap debug}
Procedure CheckMsgFile;
  begin
  { $IFNDEF DEBUG}
    if (abs(TimeMS-LastAccess) > Timeout) and (MsgOpen) then
      CloseMsgFile;
  { $ENDIF}
  end;

{-------------------------------------------------}
Procedure SetMsgPath(Mspath: DirStr);
  begin
    MsgPath := MsPath;
    If (MsgPath <> '') And (MsgPath[Length(MsgPath)] <> '\') Then
       MsgPath := MsgPath+'\';
  end;

{-------------------------------------------------}
Function Translate(var InString: String): String;
  begin
    Translate := InString;
  end;

End.
