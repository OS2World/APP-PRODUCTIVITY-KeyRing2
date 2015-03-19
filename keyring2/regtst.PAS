PROGRAM regtst;
USES
    KREGUTL,
    KRTree,
    VARDEC,
    OpString;

    PROCEDURE Doit;
    VAR
        PTR            : PTreeReader;
        Rec            : TDataRec;
    BEGIN
        WRITELN(RegisterProduct('sYMaYQU3yZv2tbHC'));
        WRITELN(TestRegCode);
        WRITELN(ShowRegistration);
        WRITELN(GetPWXLifetimeDays);
        NEW(PTR, InitRead('kr2.pwx', 'aaaa', TRUE));
        if ptr <> nil then begin
            PTR^.GetRec(SUCC(LOW(TRecType)), 1, Rec);

            writeln(ptr^.PWXLifetimeExpired);
            {writeln(ptr^.EXEDropdeadExpired);}

            PTR^.GetRec(SUCC(LOW(TRecType)), 1, Rec);
            DISPOSE(PTR, Done);
        end;
    END;

BEGIN
    Doit;
END.

