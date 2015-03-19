program LeastSq;
uses
    OpString;
type
    TXYpoint = RECORD
                   X,
                   Y : REAL;
               END;

procedure Doit;
var
    B,
    X1,
    Y1,
    XY,
    X2,
    Y2,
    J,
    M,
    N : REAL;
    I,
    P : WORD;
    Points : array[1..100] of TXYPoint;
begin
    write('How many points?');
    readln(P);
    N := P;
    FOR I := 1 to P do begin
        write('X'+Long2Str(I)+'?');
        readln(Points[i].x);
        write('Y'+Long2Str(I)+'?');
        readln(Points[i].Y);
    end;
    X1 :=0;
    X2 :=0;
    XY :=0;
    Y1 :=0;
    Y2 :=0;

    FOR I := 1 to P do begin
       X1 := X1 + Points[I].X;
       Y1 := Y1 + Points[I].Y;
       XY := XY + Points[I].X * Points[I].Y;
       X2 := X2 + (Points[I].X * Points[I].X);
    END;
    J:= N * X2 - X1 * X1;
    if abs(J) < 1e-20 then begin
        writeln('no solution found');
        halt(1);
    end;
    M := (N * XY - X1 * Y1) / J;
    B := ((Y1 * X2) - (X1 * XY));
    writeln;
    writeln;
    if b > 0 then begin
        writeln('Y = ',M,' * X + ', B);
    end
    else begin
        writeln('Y = ',M,' * X - ', B);
    end;

end;

begin
    DoIt;
end.
