program Drill;
uses
    cmdlin3,
    DGLIB;

procedure Doit(Path:STRING);
begin
    DrillDir(Path);
end;

begin
    DoIt(Non_Flag_Param(1));
end.
