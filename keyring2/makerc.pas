program MakeRC;
uses
    DOS,
    OpString;

procedure Doit;
var
    DirInfo        : SearchRec; { For Windows, use TSearchRec }
    T   : TEXT;
    C   : LONGINT;
BEGIN
    assign(T, 'junk.rc');
    rewrite(t);
    C := 1;
    FINDFIRST('.\graphics\*.ico', Archive, DirInfo);
    WHILE DOSERROR = 0 DO BEGIN
        IF DirInfo.Name[1] <> '.' THEN BEGIN
            writeln(t, 'ICON '+Long2Str(C)+ ' .\graphics\' + DirInfo.Name);
            inc(C);
        END;
        FindNext(DirInfo);
    END;
    FINDFIRST('.\graphics\*.bmp', Archive, DirInfo);
    WHILE DOSERROR = 0 DO BEGIN
        IF DirInfo.Name[1] <> '.' THEN begin
            writeln(t, 'BITMAP '+Long2Str(C)+ ' .\graphics\' + DirInfo.Name);
            inc(C);
        end;
        FindNext(DirInfo);
    END;
    close(T);
end;

begin
    Doit;
end.
