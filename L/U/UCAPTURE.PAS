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

{**********************************************************************}
{ (C) 1990 NewsMaker Systems                                           }
{**********************************************************************}

Unit UCapture;  { Capture buffer routines }

interface

Procedure OpenCaptureBuffer;
Procedure CloseCaptureBuffer;
Procedure WriteCaptureBuffer(Ch: char);

implementation
USES
    OpRoot;

Const MaxBuffSize = 4096;

Type
  BuffType = Array[1..MaxBuffSize] of char;

Var
  BuffSize    : word;
  BuffIndex   : word;

Const
  Buff        : ^BuffType = nil;
  BuffOpen    : boolean = false;

Procedure OpenCaptureBuffer;
  begin
    if MaxAvail > MaxBuffSize then
      begin
        GetMemCheck(Buff,MaxBuffSize);
        BuffSize := MaxBuffSize;
      end
    else
      begin
        BuffSize := MaxAvail;
        GetMemCheck(Buff,BuffSize);
      end;
    if Buff <> nil then
      begin
        Fillchar(Buff^[1],BuffSize,#0);
        BuffOpen := True;
      end;
    BuffIndex := 1;
  end;

Procedure CloseCaptureBuffer;
  begin
    if Buff <> nil then
      FreeMemCheck(Buff,BuffSize);
    BuffOpen := false;
    Buff := nil;
  end;

Procedure WriteCaptureBuffer(Ch: char);
  begin
    if not BuffOpen then exit;
    Buff^[BuffIndex] := Ch;
    inc(BuffIndex);
    if BuffIndex > BuffSize then
      BuffIndex := 1;
  end;

Begin
  Buff := nil;
  BuffOpen := false;
end.

