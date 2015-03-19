program Test;

uses
    uttimdat,
    USE32;

procedure Test1;
var
    d,
    m,
    y : integer;
begin
    d := 31;
    m := 2;
    y := 1955;
    ForceValidDate(d,m,y);

    d := 32;
    m := 10;
    y := 1954;
    ForceValidDate(d,m,y);

end;

begin
    Test1;
end.
