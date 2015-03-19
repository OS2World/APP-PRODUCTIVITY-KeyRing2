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
{$A-,R-,S-,F+,O+}
{.$D+}

{ Provides Quick Access to NEN Queue headers from external DOS applications }

Unit UHdrDos;

Interface

Uses Dos,OpCrt,OpDos,QGlobal,QhdrRec,Qhdr,QHdrIo;

    Procedure OpenHeader(Q: DirStr);
    Function  GetHeaderDirectory(Var Header: RundownRec): boolean;
    Function  GetHeader(Var Header: RundownRec): boolean;
    Procedure CloseHeader;

Const
    HeaderOpen: boolean = False;

implementation

Var Q: DirStr;
    OQ: DirStr;
    Hdr : RundownRec;
    HdrDirectory: RundownRec;
    WorkHdrAdr : integer;
    Num: integer;
    NumS: String[5];

{-----------------------------------------------------------------}

Procedure OpenHeader(Q: DirStr);
Begin
GetDir(0,OQ);

{$I-}
Q := NEN^.RootDir+'\'+Q;
ChDir(Q);
if IoResult <> 0 then
  begin
  ChDir(OQ);
  exit;
  end;
{$I+}

If (not ExistFile('QHDR')) or (Not HdrOpenRead) Then
   Begin
   Chdir(OQ);
   HeaderOpen := False;
   Exit;
   End;

HeaderOpen := True;

End;

{-----------------------------------------------------------------}

Function  GetHeaderDirectory(Var Header: RundownRec): boolean;
Begin
If Not ReadHdr (HdrDirectory,0) Then
   Begin
   CloseHdr;
   GetHeaderDirectory := False;
   Exit;
   End;
Header := HdrDirectory;
GetHeaderDirectory := True;
WorkHdrAdr := HdrDirectory.FirstLink;
end;


{-----------------------------------------------------------------}

Function GetHeader(Var Header: RundownRec): boolean;
Begin
If WorkHdrAdr <> 0 Then
  begin
  If ReadHdr (Hdr, WorkHdrAdr) Then
    begin
    Header := Hdr;
    WorkHdrAdr := Header.NextLink;
    GetHeader := True;
    end
  Else
    Begin
    CloseHdr;
    GetHeader := false;
    end;
  end
Else
  Begin
  CloseHdr;
  GetHeader := false;
  end;
End;

{-----------------------------------------------------------------}

Procedure CloseHeader;
Begin
if HeaderOpen then
  CloseHdr;
HeaderOpen := False;
ChDir(OQ);
end;

End.
