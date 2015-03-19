program regtest;
uses
    Inimgr,
    kregutl,
    vardec;

procedure doit;
var
    IR : TINIRec;
    RR             : TRegisterRec;
begin
    reados2ini(ir);
    DecryptRES(IR.RegCode, RR);
    writeln(RR.RegCode = IR.RegCode);
end;

begin
    DoIt;
end.
