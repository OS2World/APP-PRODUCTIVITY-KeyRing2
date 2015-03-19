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
{$A-,R-,S-,V-,O+,F+}
Unit UStats;

interface

Uses Dos,OpCrt,Graph,QHdrRec,UWindow,UrStats,UHdrDos;

procedure WriterWorkload;

implementation

Var
  GraphModeOn: boolean;
  Gd,Gm      : integer;
  Pie_Chart  : PieChartType;
  Bar_Chart  : HistogramType;
  Stats      : BreakDown;
  HeaderDirectory : ^RundownRec;
  Header          : ^RundownRec;
  WorkTag         : Array[1..20] of String[10];
  WorkData        : Array[1..20] of integer;
  WorkPtr         : integer;

procedure OpenGraphicsMode;
  begin
    if GraphModeOn then exit;
    Gd := Detect;
    InitGraph(Gd,Gm,'');
    if GraphResult = 0 then GraphModeOn := true;
  end;

procedure CloseGraphicsMode;
  begin
    if not GraphModeOn then exit;
    CloseGraph;
    RestoreCrtMode;
  end;

procedure WriterWorkload;
  var I: integer;
      found : boolean;
      ShowLength: LongInt;
  begin
    OpenGraphicsMode;
    New(Bar_Chart,Init(10,19,1,400,300,'Writer Workload',White,Black,stats));
    New(HeaderDirectory);
    New(Header);
    With Bar_Chart^ do
      begin
        Draw;
        OpenHeader('\NEN2\6PM');
        if not GetHeaderDirectory(HeaderDirectory^) then
          begin
            CloseGraphicsMode;
            CloseHeader;
            exit;
          end;
        WorkPtr := 0;
        While GetHeader(Header^) do
          begin
            With Header^ do
              begin
                if WorkPtr = 0 then
                  begin
                    inc(WorkPtr);
                    WorkTag[WorkPtr] := Reporter;
                    WorkData[WorkPtr] := DesiredRunTime;
                  end
                else
                  begin
                    found := false;
                    for I := 1 to WorkPtr do
                      if WorkTag[I] = Reporter then
                        begin
                          found := true;
                          WorkData[I] := WorkData[I]+DesiredRunTime;
                        end;
                    if not found then
                      begin
                        inc(WorkPtr);
                        WorkTag[WorkPtr] := Reporter;
                        WorkData[WorkPtr] := DesiredRunTime;
                      end;
                  end;
              end;
          end;
        CloseHeader;
        SetColor(White);
        with HeaderDirectory^ do
          ShowLength := EndTimeOfShow-TimeOfShow;
        DrawAxis(0,ShowLength,ShowLength div 50,50,'Length of Show',
                 1,WorkPtr,1,WorkPtr,'Writer');
        For I := 1 to WorkPtr do
          DrawBar(I,
                  WhatPercentOf((300-14),PercentOf(ShowLength,WorkData[I])*2),
                  I+8,WorkTag[I]);
      end;
    WaitForEscape;
    Dispose(Header);
    Dispose(HeaderDirectory);
    Dispose(Bar_Chart,Done);
    CloseGraphicsMode;
  end;

begin
  GraphModeOn := False;
end.
