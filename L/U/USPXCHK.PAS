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
{$A-,V-,F+,X+}
{$O+}
Unit USPXCHK;     { SPX Activity check for NEN }

interface

Uses Dos, OpDos, OpCrt, OpString, OpDate,
     NetWare, NetBind,
     QGlobal, QHDrRec, QInput, QNovell,
     USpxGlo, USpxDat, UGlobal, UDirec, UCpuID, USpxMsg, R_Glo, UIpxSpx;

  Procedure CheckForIPXCall;

implementation

  Function Timeout(LastTime, TimeoutVal: LongInt): boolean;
  var
    LT: LongInt;
    CT: LongInt;
  begin
    CT := TimeMS;
    if CT < LastTime then
      LT := 86400000-LastTime     { accounts for midnight rollover }
    else
      LT := LastTime;
    Timeout := CT-LT > TimeoutVal;
  end;

    { Main polling routine, called by Uptime }
    { Calls each active task to check for activity }
    { if Task has terminated, it will be deallocated here }

  Procedure CheckForIPXCall;
    var C: integer;
    begin
      if MsBetweenChecks > 0 then
        if not Timeout(LastIPXCheck, MsBetweenChecks) then exit;
      IPXMessagePending := False;
      if not SYS^.NovellSys then exit;
      for C := 0 to MaxConversations do
        if Sub_Channel[C] <> nil then
          begin
            Sub_Channel[C]^.Check;
            if Sub_Channel[C]^.MessagePending then
              IPXMessagePending := True;
            if Sub_Channel[C]^.Destroy then
              begin
                if C > 0 then
                  begin
                    Dispose(Sub_Channel[C],Done);
                    Sub_Channel[C] := Nil;
                  end;
              end;
          end;
      LastIPXCheck := TimeMS;
    end;

End.
