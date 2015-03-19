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

Unit UMsgFile;

interface

Uses Dos,OpCrt,OpDos,OpString,OpDate;

  { Routines for Building message file }
Procedure OpenMessageFile(MSname: PathStr);
Procedure CloseMessageFile;
Procedure StripFile(MSname: PathStr; Strip: boolean);
Procedure SetSeed(Num: LongInt);

  { Routines for compiling message file into Language file }
Procedure CompileMessageFile(MSname: PathStr; LngName: PathStr);

implementation

var MsgFile: Text;
    PasFile: Text;
    LngFile: Text;
    SourceLine : String;
    OutLine    : String;
    TempString : String;
    TestString : String;
    QuoteMap : Array[1..100] of byte;
    NumQuotes: Word;
    CurQuote : word;
    SourceNumber : word;
    FileWritten  : boolean;
    FilesProcessed: LongInt;
    MessagesProcessed: LongInt;
    BytesProcessed   : LongInt;

Const
    MsgOpen : boolean = False;
    Seed    : longint = 0;
    Quote   = #$27;

{-------------------------------------------------}
Procedure Encrypt(var S: String);
var I: integer;
begin
For I := 1 to length(S) do
  S[I] := chr(ord(S[I])-48);
end;

{-------------------------------------------------}
Procedure Decrypt(var S: String);
var I: integer;
begin
For I := 1 to length(S) do
  S[I] := chr(ord(S[I])+48);
end;

Procedure OpenMessageFile(MSname: PathStr);
  begin
    Assign(MsgFile,MSname);
    {$I-}
    Reset(MsgFile);
    if IoResult = 0 then
      begin
      Write('Locating highest message');
      While not EOF(MsgFile) do
        ReadLn(MsgFile,SourceLine);
      TempString := ExtractWord(1,SourceLine,[' ']);
      WriteLn(' ',TempString);
      if Str2Long(TempString,Seed) then;
      Close(MsgFile);
      Append(MsgFile);
      WriteLn('Appending '+MSName);
      end
    else
      begin
      Close(MsgFile);
      Rewrite(MsgFile);
      WriteLn('Creating '+MSName);
      end;
    if IoResult <> 0 then MsgOpen := True;
    FilesProcessed := 0;
    MessagesProcessed := 0;
    BytesProcessed := 0;
  end;

Procedure CloseMessageFile;
  begin
    if MsgOpen then Close(MsgFile);
    MsgOpen := False;
    WriteLn('Files Processed     : ',FilesProcessed);
    WriteLn('Messages Moved      : ',MessagesProcessed);
    WriteLn('Total Message Size  : ',BytesProcessed,' bytes');
  end;

Procedure SetSeed(Num: LongInt);
  begin
    Seed := Num;
  end;

Procedure StripFile(MSname: PathStr; Strip: boolean);
  var i: integer;
  begin
    Assign(PasFile,MSName);
    {$I-}
    Reset(PasFile);
    if IoResult <> 0 then
      begin
        WriteLn(MSName,' not Found');
        Exit;
      end;
    WriteLn(MSName);
    Write('Line(');
    SourceNumber := 0;
    FileWritten := False;
    Inc(FilesProcessed);
    While not EOF(PasFile) do
      begin
        ReadLn(PasFile,SourceLine);
        inc(SourceNumber);
        Write(SourceNumber,')');
        GotoXY(6,WhereY);
        NumQuotes := 0;
        for i := 1 to Length(SourceLine) do
          if SourceLine[i] = Quote then
            begin
              inc(NumQuotes);
              QuoteMap[NumQuotes] := i;
            end;
        QuoteMap[NumQuotes+1] := Length(SourceLine);
        if NumQuotes > 1 then
          begin
            CurQuote := 1;
            Repeat
              TempString := Trim(Copy(SourceLine,
                                      QuoteMap[CurQuote],
                                     (QuoteMap[CurQuote+1]-QuoteMap[CurQuote])+1));
              inc(CurQuote,2);
              TestString := StUpCase(TempString);
              Delete(TestString,1,1);
              Delete(TestString,Length(TestString),1);
              if (Length(TempString) > 5) and
                 (not Str2Int(TestString,I)) then
                begin
                  if not FileWritten then
                    begin
                    WriteLn(MsgFile,';');
                    WriteLn(MsgFile,'; Source: '+MSName);
                    WriteLn(MsgFile,'; Msg# Source Message');
                    WriteLn(MsgFile,';----- ------ ------------------------------------------------');
                    FileWritten := True;
                    end;
                  inc(Seed);
                  WriteLn(MsgFile,LeftPadCh(Long2Str(Seed),'0',6),' ',
                          LeftPadCh(Long2Str(SourceNumber),'0',6),' ',
                          TempString);
                  Inc(MessagesProcessed);
                  Inc(BytesProcessed,Length(TempString)+1);
                end;
              Until CurQuote >= NumQuotes;
          end;
      end;
    Flush(MsgFile);
    Close(PasFile);
    WriteLn;
  end;

Procedure CompileMessageFile(MSname: PathStr; LngName: PathStr);
  var CLine: LongInt;
  begin
    Assign(MsgFile,MSname);
    {$I-}
    Reset(MsgFile);
    if IoResult <> 0 then
      begin
        WriteLn(MSName,' not found!');
        Halt(1);
      end;
    Assign(LngFile,LngName);
    Rewrite(LngFile);
    if IoResult <> 0 then
      begin
        WriteLn('Cannot create ',LngName);
        Halt(1);
      end;
    WriteLn('Input:  ',MSNAme);
    WriteLn('Output: ',LngNAme);
    CLine := 0;
    Write('Line(');
    WriteLn(LngFile,LngName,' ',DateToDateString('mm/dd/yy',Today),' ',
            CurrentTimeString('hh:mm te'));
    SourceNumber := 0;
    While not EOF(MsgFile) do
      begin
        ReadLn(MsgFile,SourceLine);
        inc(Cline);
        GotoXY(6,WhereY);
        Write(Cline,')');
        if (SourceLine[1] <> ';') then
          begin
           inc(SourceNumber);
           if (LeftPadCh(Long2Str(SourceNumber),'0',6) = Copy(SourceLine,1,6)) then
             begin
             Delete(SourceLine,1,7);
{             Encrypt(SourceLine);}
             WriteLn(LngFile,SourceLine);
             end;
          end;
      end;
    Flush(MsgFile);
    Close(MsgFile);
    Flush(LngFile);
    Close(LngFile);
    WriteLn;
    WriteLn('Done');
  end;

End.
