PROGRAM asctst;

    PROCEDURE Doit;
    VAR
        T              : TEXT;
        I              : CHAR;
    BEGIN
        ASSIGN(T, 'junk.pas');
        REWRITE(T);
        FOR I := #255 DOWNTO #0 DO
        case i of
        #0..#27:
            WRITELN(T, '    writeln(''hello world'' + #',byte(I),') {', BYTE(I), ' zzzzz}');
        else
            WRITELN(T, '    writeln(''hello world''+''' + I + ''') {', BYTE(I), '}');
        end;
        CLOSE(T);
    END;

BEGIN
    Doit;
END.
