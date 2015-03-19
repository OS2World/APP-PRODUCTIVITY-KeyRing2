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
{$A-,F+,O+,V-}

Unit UCG;

interface

Uses Dos,OpCrt, OpString, OpDate, OpCol16,
     QHdrIO, QScreen, UMsg, QHdrRec, QFiles, QGlobal,
     QTCode,
     UGlobal,UWindow,UMenu,UDialog,UColors, UHdr, B_Glo;

Type
  TapeNumStr = String[8];

  TapeRec = Record
    Title    : String[20];
    Number   : TapeNumStr;
    Sequence : Word;
    Location : String[15];
    SOM      : String[11];
    Duration : String[11];
    SOMFrames: TimeCode;     { BCD HH:MM:SS:FF }
    DurFrames: TimeCode;
    OnAirDay : TimeCode;
    OnAirTime: TimeCode;
    Bin      : integer;
    Channel  : byte;
    HdrNum   : byte;
    Queue    : String[12];
    Flags    : byte;       { bit field: 1-bug, 2-Live, 4-Pause, 8-Other }
    Status   : word;
    Played   : boolean;
    GPI1     : boolean;    { Toggle on this event }
    GPI2     : boolean;    {   "     "  "     "   }
    GPI1State: boolean;    { State at this event  }
    GPI2State: boolean;
  end;

  MString = String[80];
  TString = String[40];
  MArray = Array[1..100] of MString;
  TArray = Array[1..256] of TapeRec;

Procedure GetTapeNumbers(Q: NameStr; var MM: TArray; var Num: integer;
                         var Changed: boolean; var ChPos: integer; Force: boolean);
Procedure GetMachineMessages(Q: NameStr; var MM: MArray; var Num: integer);

implementation

Procedure GetMachineMessages(Q: NameStr; var MM: MArray; var Num: integer);

Const CtrlZ = 26;

   Var
     HdrDirectory : RundownRec;
     WorkHdr : RundownRec;
     LastCH     : Char;
     LastCH2    : Char;
     Ch         : char;
     Pointer    : integer;             {Next byte to read in buffer}
     Nrecsread  : integer;             {Bytes read by read routine}
     Error      : boolean;
     DoExit     : boolean;
     KeyFileHandle : Integer;
     NumLinesPerPage : Integer;
     WorkHdrAdr : Integer;
     InputLine  : String[255];
     InputLine2  : String[255];
     I          : Integer;
     PastCues   : Boolean;
     Err  : Integer;
     WasInKey   : Boolean;
     InKey      : Boolean;
     ToStory    : String[14];
     ErrCode    : Integer;
     LastLine : String[5];
     LastlineNo : Integer;
     ThisLineNo : Integer;
     AllQ: boolean;
     Escape : Boolean;

      Procedure Msg(M: String; Code: integer);
        begin
          if Dialog(M, 'GetMMC', Red, 'OK','') = 0 then;
        end;

      Procedure AddMessage(M: MString);
        begin
          inc(Num);
          MM[Num] := M;
          WriteCentred(3,'Found: '+Long2Str(Num));
        end;

      Function GetNextDChar (KeyHandle : Integer) : Char;
          Begin
          LastCh2 := LastCh;
          LastCh := CH;
          if Pointer > Bufsize {(Nrecsread * 128)} then
             begin                   {Need to load another buffer full}
             ReadABlock (KeyHandle, TBuffer, Bufsize div 128, Nrecsread);

             If NRecsread = 0 Then Error := True;
             Pointer := 1
             end;

          if Nrecsread = 0 then
             Begin
             Ch := chr (Ctrlz);
             end
             else
             begin
             GetNextDChar := TBuffer [Pointer];
             Pointer := Succ (Pointer)
             end;
          End;

Label PastIfs1;
Label PastIfs2;
Label PastIfs3;

      Begin
      Num := 0;
      OpenMessage('Building Cues List from '+Q,BrightYellow_Scheme);
      ChDir (NEN^.RootDir+'\'+Q);
      If Not HdrOpenRead Then
         Begin
         Msg (SysMsg(000050){'Unable To Open Hdr'},2);
         Exit;
         End;

      If Not ReadHdr (HdrDirectory,0) Then
         Begin
         Msg (SysMsg(000069){'Unable To Read Directory'},2);
         CloseHdr;
         Exit;
         ENd;

      If HdrDirectory.QType <> RunDownQ Then
         Begin
         Msg (SysMsg(000422){'Sorry, Current Q Is Not A Rundown Q'},1);
         Exit;
         End;

      WorkHdrAdr := HdrDirectory.FirstLink;

      While WorkHdrAdr <> 0 Do
         Begin
         If Not ReadHdr (WorkHdr, WorkHdrAdr) Then
            Begin
            Msg (SysMsg(000427){'Unable To Read Q'},2);
            CloseHdr;
            End;

         If WorkHdr.BStatus And S_Hold <> S_Hold Then
            Begin
            LastCh := #0;
            LastCh2 := #0;
            Error := false;
            PastCues := False;
            WasInKey := False;
            InKey := False;
            Pointer := Succ (Bufsize);        {Force read on the first time}
            Nrecsread := 0;
            DoExit := False;
            InputLine := '';
            InputLine2 := '';
            Str (WorkHdr.DOSScriptFile, ToStory);
            ToStory := 'Q' + ToStory;
            OpenFile (ToStory,$40, KeyFileHandle,Errcode);

            If ErrCode <> 0 Then GoTo PastIfs3;

            CH := GetNextDChar (KeyFileHandle);
            If (CH <> Chr (NoCaptionMode)) And
               (CH <> Chr (OldUserNoteST)) Then
               begin
               Pointer := Pointer - 1;
               CloseFile (KeyFileHandle,False);
               GoTo PastIfs3;
               End;

            While Not DoExit Do
               Begin
               Ch := GetNextDChar (KeyFileHandle);

               If Ord(Ch) > Ctrlz Then GoTo PastIfs2;


               If (Ch = Chr (OldUserNoteEnd)) Or
                  (Ch = Chr (NoCaptionMode)) Then
                  Begin
                  If PastCues Then
                     Begin
                     DoExit := True;
                     End
                     Else
                     Begin
                     PastCues := True;
                     End;
                  GoTo PastIfs1;
                  End;

               If Ch = Chr (NoCaptionMode) Then
                  Begin
                  GoTo PastIfs1;
                  End;

               If Ch = DefineSt Then GoTo PastIfs1;

               If Ch = DefineEnd Then GoTo PastIfs1;

               If Ord (Ch) = CtrlM Then GoTo PastIfs1;

               If Ord (Ch) = Ctrlj Then
                  begin
                  If LastCH2 = Chr(CtrlJ) Then
                     Begin
                     LastCh2 := #0;
                     Ch := #0;
{                     repeat
                       Ch := GetNextDChar(KeyFileHandle);
                       until Ch = ':';
                     Ch := GetNextDChar(KeyFileHandle);
                     Ch := ' ';
                     GoTo PastIfs1;}
                     End;

{**}
                  LastLine := InputLine;
                  If Pos (':',InputLine) > 0 Then
                     LastLine[0] := Chr(Pos(':',InputLine)-1);

                  Val (LastLine, ThisLineNo, I);
                  Delete (InputLine, 1, Pos(':',InputLine));
                  While (InputLine <> '') And
                     (InputLine[Length(InputLine)] = ' ') Do
                     Delete (Inputline, Length(InputLine), 1);

                  InputLine2 := Inputline;
                  Repeat
                     Begin
                     If Not InKey Then
                        While (InputLine2 <> '') And
                           (InputLine2[1] <> Chr(ChyronStart)) Do
                           Delete (InputLine2,1,1);

                     If (InputLine2 <> '') And
                        (InputLine2[1] = Chr(ChyronStart)) Then
                           InKey := True;

                     InputLine := '';
                     While (InputLine2 <> '') And
                        (InputLine2[1] <> Chr(ChyronEnd)) Do
                           Begin
                           InputLine := InputLine + InputLine2[1];
                           Delete (InputLine2,1,1);
                           End;

                     If (InputLine2[1] = Chr(ChyronStart)) And
                        (InputLine2 <> '') And
                        (InputLine = '') Then
                        {WriteLn ('')};

                     If (InputLine2 <> '') And
                        (InputLine2[1] = Chr(ChyronEnd)) Then
                           Begin
                           Delete (InputLine2,1,1);
                           If InKey Then
                              WasInKey := True;
                           InKey := False;
                           End
                           Else
                           Begin
                           If InputLine <> '' Then
                              InKey := True;
                           End;

                     If (InputLine <> '') And
                        (InputLine[1] = Chr(ChyronStart)) Then
                           Delete (InputLine,1,1);

{                     If Sys^.CharacterGenerator <> '' Then
                        Begin
                        If Pos (Sys^.CharacterGenerator,InputLine) > 0 Then
                           Delete (InputLine,
                                   Pos (Sys^.CharacterGenerator, InputLine),
                                   Length (Sys^.CharacterGenerator));
                        End;                                                }

                     If (InKey) Or (WasInKey) Then
                        Begin
                        If InputLine <> '' Then
                           Begin
                           AddMessage(InputLine);
{                           If WasInKey Then
                              WriteLn ('') Else
                              Write (' ');}
                           WasInKey := False;
                           End;
                        End;
                     InputLine := '';
                     End;

                  Until InputLine2 = '';
                  GoTo PastIfs1;
                  End;

               If (Ord (Ch) = CtrlZ) Or (Error) Then
                  Begin
                  DoExit := True;
                  Delete (InputLine, 1, Pos(':',InputLine));
                  While (InputLine <> '') And
                     (InputLine[Length(InputLine)] = ' ') Do
                     Delete (Inputline, Length(InputLine), 1);


                  InputLine2 := Inputline;
                  If Not InKey Then
                     While (InputLine2 <> '') And
                        (InputLine2[1] <> Chr(ChyronStart)) Do
                         Delete (InputLine2,1,1);

                  InputLine := '';
                  While (InputLine2 <> '') And
                     (InputLine2[1] <> Chr(ChyronEnd)) Do
                     Begin
                     InputLine := InputLine + InputLine2[1];
                     Delete (InputLine2,1,1);
                     End;

                  If (InputLine2 <> '') And
                     (InputLine2[1] = Chr(ChyronEnd)) Then
                     Begin
                     Delete (InputLine2,1,1);
                     WasInKey := True;
                     End;

                  If (InputLine <> '') And
                     (InputLine[1] = Chr(ChyronStart)) Then
                        Delete (InputLine,1,1);


                  If InputLine <> '' Then
                     Begin
                     AddMessage(InputLine);
{                     If WasInKey Then
                        WriteLn ('');}
                     End;
                  InputLine := '';
                  GoTo PastIfs1;
                  End;

PastIfs2:
               If Not PastCues Then
                  Begin
                  InputLine := InputLine + Ch;

                  If Length(Inputline) = sizeof(inputline) Then
                     begin
                     msg (SysMsg(000428){'Line Too Long'},2);
                     TBuffer[Pointer] := Chr(CtrlJ);
                     Pointer := Pred(Pointer);
                     End;
                  End;

PastIfs1:
               End;
            End;

         CloseFile (KeyFileHandle,False);

PastIfs3:

         WorkHdrAdr := WorkHdr.NextLink;
         End;

{      EditDestxtdes  (PrintLine);}
      CloseHdr;
(*      Msg (SysMsg(000178){'Printout Queued'},0); *)
      ChDir (NEN^.SysDir);
      CloseMessage;
      End;

      Function GetQDay(HdrDirectory: RundownRec): integer;
      var i: integer;
      const
        Days : Array[0..6] of byte = (64,32,16,8,4,2,1);
        begin
          for i := 0 to 6 do
            if HdrDirectory.DaysOfTheWeek and Days[i] <> 0 then
              begin
                GetQDay := i+1;
                exit;
              end;
        end;


Procedure GetTapeNumbers(Q: NameStr; var MM: TArray; var Num: integer;
                         var Changed: boolean; var ChPos: integer; Force: boolean);

Const CtrlZ = 26;

   Var
     HdrDirectory : RundownRec;
     WorkHdr : RundownRec;
     StartQ     : NameStr;
     LastCH     : Char;
     LastCH2    : Char;
     Ch         : char;
     Pointer    : integer;             {Next byte to read in buffer}
     Nrecsread  : integer;             {Bytes read by read routine}
     Error      : boolean;
     DoExit     : boolean;
     KeyFileHandle : Integer;
     NumLinesPerPage : Integer;
     WorkHdrAdr : Integer;
     I,J        : Integer;
     PastCues   : Boolean;
     Err  : Integer;
     TimesThru : integer;
     WasInKey   : Boolean;
     InKey      : Boolean;
     ToStory    : String[14];
     ErrCode    : Integer;
     LastLine : String[5];
     LastlineNo : Integer;
     ThisLineNo : Integer;
     AllQ: boolean;
     Escape : Boolean;
     OldMM : ^TArray;
     TimeBase : DateTimeRec;
     BaseDayNum : integer;
     TimeEvent : DateTimeRec;
     EventDayNum : integer;
     TC : TimeCode;
     Frames: LongInt;
     TotalFrames: LongInt;
     Temp: LongInt;
     TimeInFrames: LongInt;
     NumDays: word;
     Seconds: LongInt;
     FirstTimeThru : boolean;
     FirstItemInQueue : boolean;
     FirstActualItem: boolean;
     QuitNow: boolean;
const
  Days : Array[0..6] of byte = (64,32,16,8,4,2,1);

Label Top, Bottom;

      Procedure Msg(M: String; Code: integer);
        begin
          FastWrite(M, 23,9, WhiteOnRed);
        end;

      Procedure AddMessage(M1: MString; M2: MString);
        var i: integer;
            c: char;
            Frames: LongInt;
            D,M,Y: integer;
        const
            ZeroTC: TimeCode = (0,0,0,0);
        begin
          inc(Num);
          MM[Num].Title    := M1;
          MM[Num].Number   := StUpcase(M2);
          MM[Num].Location := ^C'Unknown'^C;
          MM[Num].SOM      := '00:00';
          MM[Num].Duration := '00:00';
          Move(WorkHdr.StartTimeCode, MM[Num].SOMFrames,4);
          MM[Num].OnAirTime:= ZeroTC;
          DateToDMY(TimeEvent.D, D,M,Y);
          MM[Num].OnAirDay[1] := D;
          MM[Num].OnAirDay[2] := M;
          MM[Num].OnAirDay[3] := Y;
          MM[Num].Bin      := 0;
          MM[Num].Played := False;
          MM[Num].Queue := '';
          Frames:= CalcDurationTimeCode(WorkHdr);
{          if Frames = 0 then
            if WorkHdr.DesiredRunTime <> $FFFF then
              Frames := SecondsToFrames(WorkHdr.DesiredRunTime)
            else
              Frames := 0;}
          FramesToTimeCode(Frames, DropFrame, MM[Num].DurFrames);

          if FirstItemInQueue then
            begin
              TotalFrames := 0;
            end;
          TimeInFrames := LongSecondsToFrames(HdrDirectory.TimeOfShow)+TotalFrames;
          if FirstActualItem then
            FramesToTimeCode(TimeInFrames, DropFrame, MM[Num].OnAirTime);
          FirstItemInQueue := False;
          TotalFrames := TotalFrames + Frames;
          if (UseSystemClock) and (PlaylistControlsTiming) and (TimeInFrames < LongSecondsToFrames(OpDate.CurrentTime+60))
             and (Force) then
            begin
              Dec(Num);
              Exit;
            end;

          if (PlaylistControlsTiming) and (Frames = 0) then
            begin
              Dec(Num);
              Exit;
            end;
          FirstActualItem := False;
          MM[Num].HdrNum   := WorkHdrAdr;
          MM[Num].Flags    := WorkHdr.CartFlags;
          MM[Num].Status   := 0;
          MM[Num].Queue    := StUpCase(Q);
          MM[Num].GPI1     := False;
          c  := UpCase(WorkHdr.Category);
          if c in ['A'..'D'] then
            MM[Num].Channel := Ord(c)-64
          else
            MM[Num].Channel := 0;
{          WriteCentred(3,'Found: '+Long2Str(Num));}
          for i := 1 to 256 do
            if (MM[Num].Number = OldMM^[i].Number) and
               (MM[Num].HdrNum = OldMM^[i].HdrNum) then
              begin
                MM[Num].Status := OldMM^[i].Status;
                MM[Num].Bin := OldMM^[i].Bin;
                MM[Num].Location := OldMM^[i].Location;
                MM[Num].SOM      := OldMM^[i].SOM;
                MM[Num].Queue    := OldMM^[i].Queue;
                MM[Num].Duration := OldMM^[i].Duration;
                MM[Num].Sequence := OldMM^[i].Sequence;
                MM[Num].Played   := OldMM^[i].Played;
                MM[Num].GPI1     := OldMM^[i].GPI1;
                MM[Num].GPI2     := OldMM^[i].GPI2;
                MM[Num].GPI1State:= OldMM^[i].GPI1State;
                MM[Num].GPI2State:= OldMM^[i].GPI2State;
                if ChannelAssign then
                  MM[Num].Channel := OldMM^[i].Channel;
                exit;
              end;
        end;

{  Function GetRelativeEventTime(OfsTimeIn: TimeCode): LongInt;
    begin
      EventDayNum := GetQDay(HdrDirectory);
      TimeEvent.D := TimeBase.D;
      TimeEvent.T := TimeBase.T;
      J := EventDayNum-BaseDayNum;
      if J < 0 then J := J+7;
      IncDate(TimeEvent.D, J, 0, 0);
      LongSecondsToTimeCode(HdrDirectory.TimeOfShow, TC);
      AddTimeCodes(TC, OfsTimeIn, TC);
      TimeEvent.T := FramesToLongSeconds(TimeCodeToFrames(TC, DropFrame), DropFrame);
      DateTimeDiff(TimeBase, TimeEvent, NumDays, Seconds);
      if NumDays > 0 then
        Seconds := (NumDays * SecondsInDay) + Seconds;
      GetRelativeEventTime := Seconds;
    end;}

    Begin
      Num := 0;
      Seconds := 0;
      StartQ := Q;
      FirstTimeThru := True;
      TimesThru := 0;
      QuitNow := False;
TOP:
      Seconds := 0;
      FirstItemInQueue := True;
      FirstActualItem := True;
      Inc(TimesThru);
      if TimesThru >= 3 then
        begin
          Dispose(OldMM);
          exit;
        end;
      FastWrite(Pad('Scanning '+Q+' for Tapes',30),23,9,BlueOnLtGray);
      {$I-}
      ChDir('F:');
      ChDir (NEN^.RootDir+'\'+Q);
      if Ioresult <> 0 then
        begin
          if Dialog('Cannot switch to '+NEN^.RootDir+'\'+Q,'GetTapes',Red,'OK','')=0 then;
          exit;
        end;
      {$I+}
      If Not HdrOpenRead Then
         Begin
         Msg ('Unable To Open Hdr '+Q,2);
         ChDir (NEN^.SysDir);
         Exit;
         End;

      If Not ReadHdr (HdrDirectory, 0) Then
         Begin
         Msg ('Unable To Read Directory '+Q,2);
         CloseHdr;
         ChDir (NEN^.SysDir);
         Exit;
         ENd;

      If HdrDirectory.QType <> RunDownQ Then
         Begin
         Msg (SysMsg(000422){'Sorry, Current Q Is Not A Rundown Q'},1);
         CloseHdr;
         Exit;
         End;

      WorkHdrAdr := HdrDirectory.FirstLink;

      if FirstTimeThru then
        with HdrDirectory do
          begin
            New(OldMM);
            Move(MM, OldMM^, SizeOf(TArray));
            FillChar(MM, Sizeof(TArray), 0);
            FirstTimeThru := False;
            if UseSystemClock then
              TimeBase.T := OpDate.CurrentTime
            else
              TimeBase.T := HdrDirectory.TimeOfShow;
            TimeBase.D := Today;
            BaseDayNum :=  Ord(DayOfWeek(Today))+1;
            if (UseSystemClock) and (OpDate.CurrentTime > EndTimeOfShow) then
              if AutoSyncOnStartup then
                begin
                  CloseHdr;
                  SelectQBasedOnTime(Q, Queue);
                  Q := Queue;
                  ChDir (NEN^.SysDir);
                  Goto Top;
                end;
          end;

      While WorkHdrAdr <> 0 Do
         Begin
         If Not ReadHdr (WorkHdr, WorkHdrAdr) Then
            Begin
            Msg ('Unable To Read Hdr '+Q,2);
            CloseHdr;
            ChDir (NEN^.SysDir);
            exit;
            End;

         with WorkHdr do
           begin
             EventDayNum := GetQDay(HdrDirectory);
             TimeEvent.D := TimeBase.D;
             TimeEvent.T := TimeBase.T;
             J := EventDayNum-BaseDayNum;
             if J < 0 then J := J+7;
             IncDate(TimeEvent.D, J, 0, 0);
             if BStatus and S_Hold <> S_Hold then
               begin
                 Frames:= CalcDurationTimeCode(WorkHdr);
{                 if Frames = 0 then
                   if WorkHdr.DesiredRunTime <> $FFFF then
                     Frames := SecondsToFrames(WorkHdr.DesiredRunTime)
                   else
                     Frames := 0;}
                 Seconds := Seconds+FramesToLongSeconds(Frames,DropFrame);
                 TimeEvent.T := TimeBase.T+Seconds;
               end;
           end;

         if not RemoveAiredStories then
           WorkHdr.BStatus := WorkHdr.BStatus and (not S_Aired);

         If (WorkHdr.BStatus And S_Hold  <> S_Hold) and
            (WorkHdr.BStatus and S_Aired <> S_Aired) Then
            Begin
              If ((Trim(WorkHdr.TapeNum) <> '') and (Copy(Trim(WorkHdr.TapeNum),1,1) <> '*')) or
                 (WorkHdr.CartFlags and (EF_Live+EF_Pause) <> 0) Then
                 Begin
                   if ((MaxMinsAhead > 0) and
                      (Seconds > (MaxMinsAhead*60))) then
                     begin
                        QuitNow := True;
                        FastWrite(DateToDateString('mm/dd/yy',TimeEvent.D)+
                              ' '+TimeToTimeString('hh:mm:ss',TimeEvent.T)+
                              ' Time!',23,9,RedOnLtGray);
                        Goto Bottom;
                     end;
                   AddMessage(Pad(WorkHdr.Slug,21),WorkHdr.TapeNum);
                   if (MaxReadAhead > 0) and (Num = MaxReadAhead) then
                     WorkHdr.NextLink := 0;
                 End;
            end;
         WorkHdrAdr := WorkHdr.NextLink;
         End;

      if not QuitNow then
        if (HdrDirectory.NextQueue <> '') and (MaxReadAhead > 0) and
           (Num < MaxReadAhead) then
          begin
            CloseHdr;
            ChDir (NEN^.SysDir);
            Q := HdrDirectory.NextQueue;
            if Q = '' then Goto Bottom;
            if Q = StartQ then
              begin
                FastWrite('Can''t find enough Events!',23,9,RedOnLtGray);
              end
            else
              Goto Top;
          end;


Bottom:
      Changed := False;
      ChPos := 0;
      j := 0;
      for i := 1 to num do
        if OldMM^[i].Sequence = MM[1].Sequence then
          if j = 0 then
            j := i;
      for i := 1 to num do
        begin
          if (MM[i].Number <> OldMM^[j].Number) or
             (MM[i].Flags  <> OldMM^[j].Flags ) or
             (TimeCodeToFrames(MM[i].DurFrames, DropFrame) <>
             (TimeCodeToFrames(OldMM^[j].DurFrames,DropFrame))) then
            Changed := True;
          inc(j);
          if ChPos = 0 then ChPos := i;
        end;
      if MM[1].Sequence = 0 then
        Changed := True;
      Dispose(OldMM);

{      if MM[1].Queue <> '' then
        Queue := MM[1].Queue;}

      CloseHdr;
      ChDir (NEN^.SysDir);
      FastWrite(Pad(Long2Str(Num),4)+'Tapes found at '+CurrentTimeString('hh:mm:ss'),23,54,BlueOnLtGray);
{      CloseMessage;}
      End;

End.
