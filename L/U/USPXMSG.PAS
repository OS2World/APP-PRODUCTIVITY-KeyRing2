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
{$A-,R-,S-,F+}
{$IFNDEF Windows}
{$O+}
{$ENDIF}

{*********************************************************}
{ (C)1991 NewsMaker Systems.                              }
{ Inter-NEN communication via IPX/SPX NetWare services    }
{                                                         }
{ Provides support routines to supply info for SPX        }
{ conversations                                           }
{*********************************************************}

Unit USpxMsg;

interface

{$IFNDEF Windows}
Uses OpDos, OpString, OpDate, QGlobal, QHDrRec;
{$ELSE}
Uses WinSys, QGlobal, QHDrRec;
{$ENDIF}

Type
   NENStatusRec = Record
       Version   : String[20];
       StationID : Encrypted;
       Location  : Encrypted;
       License   : Encrypted;
       FreeMemory: LongInt;
       W1Queue   : String[8];
       W1Form    : String[8];
       W1File    : String[8];
       W1FileLock: boolean;
       W1FileMod : boolean;
       W2Queue   : String[8];
       W2Form    : String[8];
       W2File    : String[8];
       W2FileLock: boolean;
       W2FileMod : boolean;
     end;

  Procedure BuildNENStatus(var NSTatus: StatusData);

implementation

  Function Decrypt(var S: Encrypted): Encrypted;
  var I: integer;
      O: Encrypted;
  begin
    O := '';
    For I := 1 to length(S) do
      O := O+chr(ord(S[I])+48);
    Decrypt := O;
  end;

  Procedure BuildNENStatus(var NStatus: StatusData);
    var NENStatus : NENStatusRec absolute NStatus;
    begin
      {$IFNDEF Windows}
      FillChar(NENStatus,SizeOf(NENStatusRec),0);
      NENStatus.StationID := Decrypt(NEN^.StationID);
      NENStatus.Location := Decrypt(NEN^.StationLoc);
      NENStatus.License := Decrypt(NEN^.License);
      NENStatus.Version := BannerVersion;
      NENStatus.FreeMemory := MemAvail;
      {$IFNDEF NOTNEN}
      NENStatus.W1Queue := FW^.CurrentDir;
      NENStatus.W1Form := FW^.CurrentFormFamily;
      NENStatus.W1File := '';
      if FW^.Instate = Edit then
        begin
        NENStatus.W1File := 'Q'+Long2Str(FW^.Ecurwin^.EditHdr^.OriginalNameOfFile);
        NENStatus.W1FileLock := not FW^.ECurWin^.Read_Only;
        NENStatus.W1FileMod := FW^.ECurWin^.ChangeFlag;
        end;
      NENStatus.W2Queue := FW^.FwdLink^.CurrentDir;
      NENStatus.W2Form := FW^.FwdLink^.CurrentFormFamily;
      NENStatus.W2File := '';
      if FW^.FwdLink^.Instate = Edit then
        begin
        NENStatus.W2File := 'Q'+Long2Str(FW^.FwdLink^.Ecurwin^.EditHdr^.OriginalNameOfFile);
        NENStatus.W2FileLock := not FW^.FwdLink^.ECurWin^.Read_Only;
        NENStatus.W2FileMod := FW^.FwdLink^.ECurWin^.ChangeFlag;
        end;
      {$ENDIF}
      {$ENDIF}
    end;

End.
