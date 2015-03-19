{***************************************************************************
* Filename: qinput.pas
* Version:  5.3
* Date:     11/27/95 @ 15:30:36
* Group:    
* Release:  11291995
* ----------------------------
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer   Description
*  1.0    06/09/93 15:54:04  K_McCoy      virgin
*
*  1.1    06/15/93 08:09:34  K_McCoy      dual ini files and improved procmsg
*                                         *
*  1.2    01/16/94 19:27:03  K_McCoy      added headers
*
*  5.0    07/05/94 10:33:25  K_McCoy      dean upd
*
*  5.1    09/25/95 18:34:02  K_McCoy      
*
*  5.2    09/26/95 14:53:21  K_McCoy      New dean units
*
*  5.3    11/27/95 15:30:36  K_McCoy
*
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
{$A-,R-,S-,V-,O+,F+,X+}
{-------------------------------------------------}
{ (C) 1990 NewsMaker Systems. QInput              }
{ NEN System Keyboard/Mouse handler               }
{ NOTE: Check4Chars and GetNextChar should ALWAYS }
{ be used instead of KeyPressed & ReadKey. if a   }
{ lower level call must be made, use KeyPending   }
{ MOUSE Notes: if a mouse button is pressed, does }
{ NOT wait until button is released. If you wish  }
{ to wait call WAITUNTILBUTTONRELEASED in UKEY    }
{ after receiving the mouse flag char ($EF)       }
{-------------------------------------------------}

{ Release 4. June 1992 }
{ Substantially rewritten to depend solely on the scan code ring buffer   }
{ Translation to NEN style ch1, ch2 values now takes place in GetNextChar }

Unit UInput;

Interface

Uses
     DOS,
     OpCrt,
     OpMouse,      { Mouse interface }
     OpKey,
     UTFkey,
     OpString;

Var
    ShellOutRequested : Boolean;
    SavingFX : Boolean;
    Char1 : Char;
    Char2 : Char;
    LastChar1 : Char;
    LastChar2 : Char;
{    FxSaveFile : Text; }        {Save Fx Key Char File}
    ConsoleOff : Boolean;
    FxInputFile : Text;        {Alternate Source Input character file}

Const
    KeyCapture   : boolean = True;       { Set false to supress Check4Chars }
    DoubleDefineChars : SET OF Byte = [71, 72, 73, 76, 79, 80, 81];


  Procedure PushScanCode(Scan: word);
  Function KeyPending(Var Scan: word): boolean;
  FUNCTION Check4Chars : Boolean;
  Function GetNextChar(VAR Char1, Char2 : Char): word;
  procedure ClearKeyboard;
  procedure FlushDuplicateKeys(Key: word);

Implementation

Const
  KBSize = 100;             { Ring buffer size }

Type
  TKeyboardBuffer = Array[1..KBSize] of word; { Scan code ring buffer }

Var
  InputFxKey : Char;
  MState: boolean;
  Kbd: byte;
  LastF: byte;

  KeyboardBuffer : ^TKeyboardBuffer;    { Scan code ring buffer }
  KBIn : byte;
  KBOut: byte;

Const
  AltFlag   = $08;
  CtrlFlag  = $04;
  ShiftFlag = $03;

  MapCharacters : boolean = False;

{ Clear all scan codes from the ring buffer }

procedure ClearKeyboard;
begin
  KBin := 0;
  KBOut := 0;
  Fillchar(KeyboardBuffer^ ,SizeOf(KeyboardBuffer^),#0);
end;

{ Adds a scan code to the ring buffer }

{$IFNDEF COMET}
Procedure PushScanCode(Scan: word);
begin
  with LF^ do
    begin
      if Scan = 0 then exit;
      if (KbdFlags and $F) and ShiftFlag <> 0 then
        begin
        if Scan = OpKey.Up then Scan := OpKey.ShUp;
        if Scan = OpKey.Down then Scan := OpKey.ShDown;
        if Scan = OpKey.Left then Scan := OpKey.ShLeft;
        if Scan = OpKey.Right then Scan := OpKey.ShRight;
        end;
      inc(KBIn);
      if KBIn > KBSize then
        KBIn := 1;
      KeyboardBuffer^[KBIn] := Scan;
    end;
end;
{$ELSE}
Procedure PushScanCode(Scan: word);
begin
   if Scan = 0 then exit;
   if (KbdFlags and $F) and ShiftFlag <> 0 then
     begin
     if Scan = OpKey.Up then Scan := OpKey.ShUp;
     if Scan = OpKey.Down then Scan := OpKey.ShDown;
     if Scan = OpKey.Left then Scan := OpKey.ShLeft;
     if Scan = OpKey.Right then Scan := OpKey.ShRight;
     end;
   inc(KBIn);
   if KBIn > KBSize then
     KBIn := 1;
   KeyboardBuffer^[KBIn] := Scan;
end;
{$ENDIF}

{ Get next scan code from ring buffer, skipping any zero values }
{ Zero scan codes may be created by the flushduplicates routine }

Function GetScanCode: word;
var Scan,Where: word;
begin
If KBIn = 0 Then
   Exit;
  Repeat
    inc(KBOut);
    if KBOut > KBSize then
      KBOut := 1;
    Scan := KeyboardBuffer^[KBOut];
    KeyboardBuffer^[KBOut] := 0;
  Until (Scan <> 0) or (KbOut = KbIn);
  GetScanCode := Scan;
end;

{ Returns true if unprocessed scan codes in ring buffer }

Function KeyInBuffer: boolean;
begin
  KeyInBuffer := (KBIn <> KBOut);
end;

{ Removes duplicates of key from the ring buffer }

procedure FlushDuplicateKeys(Key: word);
var tkIn, tkOut: word;
    Scan, LScan: word;
begin
  If kbIn = 0 Then
     Exit;
  tkOut := kbOut;
  LScan := 0;
  repeat
    Scan := KeyboardBuffer^[tkOut];
    if (Scan = Key) and (Scan = LScan) then
      begin
        KeyboardBuffer^[tkOut] := 0;
      end;
    LScan := Scan;
    inc(tkOut);
    if tkOut > KBSize then
      tkOut := 1;
  Until tkOut = kbIn;
end;

{ Check keyboard, and move any pending scan codes into ring buffer }

Procedure CheckKeyboard;
  var
      ID   : word;
      Scan : word;
{$IFDEF COMET}
      i    : Integer;
{$ENDIF}
begin

  Kbd := KbdFlags and $F;

  if (FkeysUp ) and (Kbd <> LastF) then
    begin
      if (Kbd and ShiftFlag) <> 0 then
        ReDrawFkeys(Shift);
      if (Kbd and AltFlag) <> 0 then
        ReDrawFkeys(Alt);
      if (Kbd and CtrlFlag) <> 0 then
        ReDrawFkeys(Ctrl);
      if Kbd = 0 then
        ReDrawFkeys(UnShift);
      LastF := Kbd;
    end;

  if (FkeysUp) and (MousePressed) then
    begin
    WaitForButtonRelease := True;
    if MouseKeyword = MouseLft then
      for i := 1 to 10 do
        if Fkeys[i]^.MouseOnKey(Scan) then
          begin
          PushScanCode(Scan);
          Exit;
          end;
    end;

  if CheckKBD(Scan) then
    begin
      Scan := 0;
      while CheckKBD(Scan) do
        begin
          Scan := ReadKeyOrButton;
          PushScanCode(Scan);
        end;
    end;

end;

{---------------------------------------------------------}
{ Main keyboard/Mouse input routine. if Keypressed, gets  }
{ scan code & flushes key from MSDOS buffer.              }
{---------------------------------------------------------}

Function KeyPending(Var Scan: word): boolean;
var ID: word;
begin
  CheckKeyboard;

  if not KeyInBuffer then
    begin
      KeyPending := False;
      exit;
    end;

  Scan := GetScanCode;

  Case Scan of
    $3B00..$4400,  { Prevent function keys stacking up in buffer }
    $5400..$5D00,
    $6800..$7100,
    $5E00..$6700 :  FlushDuplicateKeys(Scan);
  end;

  if FkeysUp then
    begin
      Case Scan of
          $3B00..$4400 : if FKeysUp then PushKey((Scan shr 8)-$3A); { Unshft }
          $5400..$5D00 : if FKeysUp then PushKey((Scan shr 8)-$53); { Shift  }
          $6800..$7100 : if FKeysUp then PushKey((Scan shr 8)-$67); { Control}
          $5E00..$6700 : if FKeysUp then PushKey((Scan shr 8)-$5D); { Alt    }
        end;
    end;

  KeyPending := Scan <> 0;

end;

{$IFNDEF COMET}
Function DOWPShell : Boolean;

Var Regs : registers;

   begin
   DOWPShell := False;
   If (CW^.AHdrIsOpen <> 0) Or (CW^.FwdLink^.AHdrIsOpen <> 0) Then
      Exit;
   DoWPShell := True;
   With Regs Do
      Begin
      AH := $51;
      AL := SYS^.WPOfficeID;
      Intr ($1A, Regs);
      End;
   ShelloutRequested := False;
   End;
{$ENDIF}

{-------------------------------------------------------}
{ Check4Chars - Use instead of turbo KeyPressed function}
{ will return True if a key or mouse button has been    }
{ pressed, or data has been pushed with PushInputChars. }
{ Also checks for EOF if reading from macro file.       }

FUNCTION Check4Chars : Boolean;
BEGIN
  Check4Chars := False;
{$IFNDEF COMET}
  If ShelloutRequested Then
     DoWPShell;
{$ENDIF}
  if not KeyCapture then exit;

  CheckKeyboard;

  If ConsoleOff Then
    Begin
     if not EoF(FxInputFile) then
        Begin
          Check4Chars := True;
          Exit;
        End
     else
        Begin
          Close(FxInputFile);
          ConsoleOff := False;
        End;
     end;

     Check4Chars :=  KbIn <> KbOut;
  end;

function GetNormalChar(var Ch1, Ch2: char): word;
var
    Scan: word;
begin
  Scan := 0;
  Kbd := KbdFlags and $F;
  IF NOT ConsoleOff THEN
    BEGIN
      if KeyPending(Scan) then
        BEGIN
         If ((Kbd And CtrlFlag) <> 0) And
            ((Kbd And AltFlag)  <> 0) Then
            Begin
            If Scan = 28672 Then  {F9}
               Begin
               Ch1 := #3;
               Ch2 := #1;
               GetNormalChar := Scan;
               Exit;
               End;

            If Scan = 28928 Then {F10}
               Begin
               Ch1 := #3;
               Ch2 := #2;
               GetNormalChar := Scan;
               Exit;
               End;
{$IFNDEF COMET}
            If Scan = 14624 Then {Space} {was 512}
               Begin
               If Sys^.WPOfficeActive Then
                  Begin
                  If Not DoWPShell Then
                     ShelloutRequested := True;
                  End;
{
               Ch1 := #3;
               Ch2 := #4;
               GetNormalChar := Scan;
               Exit;
}
               End;
{$ENDIF}
            End;

         If (Kbd and CtrlFlag) <> 0 Then
           begin
              If (Scan = 37120) Or (Scan = 36096) Then
                 Begin
                 Ch1 := Chr(1);
                 Ch2 := Chr(Scan Shr 8);
                 End
                 Else
                 Begin
                 If (Scan And $FF In [1..26]) Then
                    Begin
                    Ch1 := Chr(1);
                    Ch2 := Chr(Scan And $FF);
                    End
                    Else
                    Begin
                    Ch1 := Chr(Scan AND $FF);
                    Ch2 := Chr(Scan SHR 8);
                    End;
                 End;
            end;

         If (Kbd and AltFlag) <> 0 Then
            Begin
            If Scan Shr 8 In [16..50,152,155,157,160] Then
               Begin
               Ch1 := Chr(2);
               Ch2 := Chr(Scan Shr 8);
               End
               Else
               Begin
               Ch1 := Chr(Scan AND $FF);
               Ch2 := Chr(Scan SHR 8);
               End;
            End;

         If (Kbd and (CtrlFlag or AltFlag)) = 0 Then
            Begin
            If (Scan And $FF = 43) Then
               Begin
               If (Kbd and ShiftFlag) <> 0 Then
                  Begin
                  Ch1 := Chr(Scan AND $FF);
                  Ch2 := Chr(Scan SHR 8);
                  End
                  Else
                  Begin
                  Ch1 := Chr(3);
                  Ch2 := Chr(Scan And $FF);
                  End;
               End
               Else
               Begin
               If (Scan And $FF = 32) Then
                  Begin
                  If (Kbd and ShiftFlag) = 0 Then
                     Begin
                     Ch1 := Chr(Scan AND $FF);
                     Ch2 := Chr(Scan SHR 8);
                     End
                     Else
                     Begin
                     Ch1 := Chr(3);
                     Ch2 := Chr(Scan And $FF);
                     End;
                  End
                  Else
                  Begin
                  If (Scan And $FF = 13) Then
                     Begin
                     If (Kbd and ShiftFlag) = 0 Then
                        Begin
                        Ch1 := Chr(Scan AND $FF);
                        Ch2 := Chr(Scan SHR 8);
                        End
                        Else
                        Begin
                        Ch1 := Chr(3);
                        Ch2 := Chr(Scan And $FF);
                        End;
                     End
                     Else
                     Begin
                     If (Scan Div 256 In DoubleDefineChars) Then
                        Begin
                        If (Kbd and ShiftFlag) = 0 Then
                           Begin
                           Ch1 := Chr(Scan AND $FF);
                           Ch2 := Chr(Scan SHR 8);
                           End
                           Else
                           Begin
                           Ch1 := Chr(3);
                           Ch2 := Chr(Scan SHR 8);
                           End;
                        End
                        Else
                        Begin
                        Ch1 := Chr(Scan AND $FF);
                        Ch2 := Chr(Scan SHR 8);
                        End;
                     End;
                  End;
               End;
            End;
          END;
    END;
  GetNormalChar := Scan;
end;

  function CharToMacro(MacroChar : Char) : Word;
  {-Converts a character to a keyboard code/char representation. This table
    holds all scan code values for ASCII characters from 0 to 63. All alpha
    characters can be mapped to this table by subtracting a number divisible
    by 32 that would put that alpha in the range of 0..63.}
  const
    ScanCodes : array[0..63] of Byte =
    (
      $03, {@} $1E, {A} $30, {B} $2E, {C} $20, {D} $12, {E} $21, {F} $22, {G}
      $23, {H} $17, {I} $24, {J} $25, {K} $26, {L} $32, {M} $31, {N} $18, {O}
      $19, {P} $10, {Q} $13, {R} $1f, {S} $14, {T} $16, {U} $2f, {V} $11, {W}
      $2d, {X} $15, {Y} $2c, {Z} $1a, {[} $2b, {\} $1b, {]} $07, {^} $0c, {_}
      $39, { } $02, {!} $28, {"} $04, {#} $5, { $} $06, {%} $08, {&} $28, {'}
      $0A, {(} $0b, {)} $09, {*} $0d, {+} $33, {,} $0c, {-} $34, {.} $35, {/}
      $0b, {0} $02, {1} $03, {2} $04, {3} $05, {4} $06, {5} $07, {6} $08, {7}
      $09, {8} $0A, {9} $27, {:} $27, {;} $33, {<} $0d, {=} $34, {>} $35 {?}
      );
  var
    CharCode : Byte absolute MacroChar;
  begin
    case MacroChar of
      ^M : CharToMacro := $1C0D;
      ^[ : CharToMacro := $011B;  {!!.13}
      #4..'?'  : CharToMacro := (ScanCodes[CharCode] shl 8) or CharCode;
      '@'..'_' : CharToMacro := (ScanCodes[CharCode-64] shl 8) or CharCode;
      '`', '~' : CharToMacro := $2900 or CharCode;
      'a'..'}' : CharToMacro := (ScanCodes[CharCode-96] shl 8) or CharCode;
      #127     : CharToMacro := $0EFF;
    else CharToMacro := CharCode;
    end;
  end;

{-------------------------------------------------------}
{ GetNextChar - Use instead of Turbo ReadKey function   }
{ Gets the next character(s) from the current input     }
{ stream (keyboard, PushString, keyboard Macro)         }

FUNCTION GetNextChar(VAR Char1, Char2 : Char): word;
{$IFNDEF COMET}
VAR
    DoExit        : Boolean;
    DoWrite       : Boolean;
    NumBytesWrote : Integer;
    SC            : Array[1..2] of char;
    ScanCode      : word absolute SC;
    FXIndex       : Integer;
    FXSt          : String[2];
    FXFile        : File Of KbdTable;
    CurrentDrive  : DriveName;

BEGIN
DoExit := False;
Char2 := #0;

CheckKeyboard;

REPEAT
  BEGIN
  IF Check4Chars THEN
     BEGIN
     IF (ConsoleOff) And Not (DoExit) THEN
        BEGIN
        ScanCode := 0;
        Read(FxInputFile, Char1);
        Read(FxInputFile, Char2);
        Read(FxInputFile, SC[1]);
        Read(FxInputFile, SC[2]);

{        If Not EOF (FXInputFile) Then} {Changed to get last scancode out of macro}
          GetNextChar := ScanCode;
        DoExit := True;
        END;

     IF Not (ConsoleOff) And Not (DoExit) THEN
        BEGIN
        ScanCode := GetNormalChar(Char1, Char2);
        GetNextChar := ScanCode;
        DoExit := True;
        END;

     IF SavingFX THEN
        BEGIN
        DoWrite := True;
        If Sys^.AltMacro Then
           Begin
           If ((Char1 = #2) And (Char2 = FXMacroKey)) Or
              ((Char1 = #0) And (FXMacroKey >= #120) And
               (FXMacroKey <= #129) And (Char2 = FXMacroKey)) Then
              Begin
              DoWrite := False;
              CloseFile(Sys^.FxSaveFile, False);
              Sys^.AltMacro := False;
              Msg(SysMsg(000250){'Recording Keys Has Stopped'}, 0);
              SavingFX := False;
              Char1 := #0;
              Char2 := #0;
              End;
           ENd
           Else
           begin
           If (Char1 = #0) And (Char2 = FXMacroKey) Then
              Begin
              DoWrite := False;
              If (CW^.InState = MailFromEditor) Or
                 (CW^.InState = MailFromList) Then
                 Begin
                 CloseFile(Sys^.FxSaveFile, False);
                 Msg(SysMsg(000250){'Recording Keys Has Stopped'}, 0);
                 SavingFX := False;
                 Char1 := #0;
                 Char2 := #0;

                 FXIndex := Ord(FXMacroKey);
                 If FXIndex < 84 Then
                 FXIndex := FXIndex - 58 Else
                 FXIndex := FXIndex - 73;
                 If CW^.InState = MailFromEditor Then
                    begin
                    If Sys^.EFxTable[FXIndex].KeyType = MacroBeingBuilt Then
                       Sys^.EFxTable[FXIndex].KeyType := Macro;
                    End
                    Else
                    Begin
                    If Sys^.QFxTable[FXIndex].KeyType = MacroBeingBuilt Then
                       Sys^.QFxTable[FXIndex].KeyType := Macro;
                    End;

                 CurrentDrive := Sys^.CurrentDriveID;

                 ChangeDrive (Sys^.BaseDrive);
                 Str (FXIndex,FXSt);
                 Assign (FXFile, NEN^.KeyBoardDir + '\' + Sys^.UsersName+'.KBD');
                 {$I-}
                 ReWrite (FXFile);
                 {$I+}
                 I := IOResult;
                 If I <> 0 Then
                    Begin
                    Msg (SysMsg(000251){'Unable To Update User KeyTable'},2);
                    End
                    Else
                    begin
                    Write (FXFile,Sys^.QFXTable);
                    Write (FXFile,Sys^.EFXTable);
                    Close (FXFile);
                    End;

                 ChangeDrive (CurrentDrive);
                 SavingFX := False;
                 End;
              End;
           End;

        If DoWrite Then
           BEGIN
           If Write2File (Sys^.FxSaveFile, Char1, 1, NumBytesWrote) Then
              If Write2File (Sys^.FxSaveFile, Char2, 1, NumBytesWrote) Then
                begin
                Write2File (Sys^.FxSaveFile, SC[1], 1, NumBytesWrote);
                Write2File (Sys^.FxSaveFile, SC[2], 1, NumBytesWrote);
                end;
           END;
        END;
     END
     ELSE
     BEGIN
     IF ConsoleOff THEN
        BEGIN
        Close(FxInputFile);
        ConsoleOff := False;
        END
        Else
        Begin
        Char1 := #0;
        Char2 := #0;
        GetNextChar := $FFFF;
        DoExit := True;
        End;
     END;
 END;
UNTIL DoExit;
END;
{$ELSE}
var
    DoExit        : Boolean;
    SC            : Array[1..2] of char;
    ScanCode      : word absolute SC;

begin

   DoExit := False;
   Char2 := #0;

   CheckKeyboard;

   repeat
      if Check4Chars then
          begin

          ScanCode := GetNormalChar(Char1, Char2);
          GetNextChar := ScanCode;
          DoExit := True;
          END;
   until DoExit;
end;
{$ENDIF}

{$IFNDEF COMET}
{-------------------------------------------------------}

PROCEDURE SwitchInput(FXIndex : Integer);
Var  FxChar : Char;
     I : Integer;
     FXSt : String[2];
BEGIN
IF ConsoleOff THEN
   BEGIN
(*         Msg(SysMsg(000235){'Cannot Chain Function Keys'}, 2); *)
   END;

IF NOT ConsoleOff THEN
   BEGIN
   If InCmnd Then
      Begin
      GoToXY (AtX,AtY);
      AtX := 0;
      InCmnd := False;
      CW^.CurrentForm := CW^.ListForm;
      End;

   ChangeDrive (Sys^.BaseDrive);
   If FXIndex = 999 Then
      Begin
      Assign(FXInputFile, NEN^.KeyBoardDir + '\' +
         Sys^.UsersName+'.INT');

      {$I-}
      Reset(FxInputFile);
      {$I+}
      I := IOResult;
      IF I <> 0 THEN
         BEGIN
         Assign(FXInputFile, NEN^.KeyBoardDir + '\NEN.INT');

         {$I-}
         Reset(FxInputFile);
         {$I+}
         I := IOResult;
         IF I <> 0 THEN
            BEGIN
            Msg(SysMsg(000236){'No Startup Macro Saved'}, 2);
            END
            ELSE
            BEGIN
            ConsoleOff := True;
            END;
         End
         Else
         Begin
         ConsoleOff := True;
         End;

      ChangeDrive (CW^.QDrive);
      End
      Else
      Begin
      Str (FXIndex,FXSt);
      If CW^.InState = Edit Then
         Assign(FXInputFile, NEN^.KeyBoardDir + '\' +
            Sys^.UsersName+'.E'+FXSt)
         Else
         Assign(FXInputFile, NEN^.KeyBoardDir + '\' +
            Sys^.UsersName+'.L'+FXSt);

      {$I-}
      Reset(FxInputFile);
      {$I+}
      I := IOResult;
      IF I <> 0 THEN
         BEGIN
         Str (FXIndex,FXSt);
         If CW^.InState = Edit Then
            Assign(FXInputFile, NEN^.KeyBoardDir + '\' +
               'NEN'+'.E'+FXSt)
            Else
            Assign(FXInputFile, NEN^.KeyBoardDir + '\' +
               'NEN'+'.L'+FXSt);

         {$I-}
         Reset(FxInputFile);
         {$I+}
         I := IOResult;
         IF I <> 0 THEN
            BEGIN
            END
            ELSE
            BEGIN
            ConsoleOff := True;
            END;
         END
         ELSE
         BEGIN
         ConsoleOff := True;
         END;
      ChangeDrive (CW^.QDrive);
      End;
   END;
End;
{$ENDIF}
{-------------------------------------------------------}

Procedure InitQInput;
Begin
  ShellOutRequested := False;
  ConsoleOff := False;
  SavingFX := False;
  MState := False;
  KBIn := 0;
  KBOut := 0;
  New(KeyboardBuffer);
  FillChar(KeyboardBuffer^, SizeOf(KeyboardBuffer), #0);
End;

Begin
  InitQInput;
End.
