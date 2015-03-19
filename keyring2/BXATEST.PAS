program BXATest;
uses
    vardec;

    PROCEDURE CryptInit(Password : STRING; CryptStyle : TCryptHead); EXTERNAL 'KRYPTON' Name 'CryptInit';
    FUNCTION CryptBlock(Block : STRING) : STRING; EXTERNAL 'KRYPTON' Name 'CryptBlock';
    FUNCTION DeCryptBlk(var Block; BlockSize : LONGINT) : STRING; EXTERNAL 'KRYPTON' Name 'DeCryptBlk';
    FUNCTION GetCryptType : STRING; EXTERNAL 'KRYPTON' Name 'GetCryptType';
    PROCEDURE CryptDeinit; EXTERNAL 'KRYPTON' Name 'CryptDeinit';
    FUNCTION Squawk(Challenge:STRING):LONGINT; EXTERNAL 'KRYPTON' Name 'Squawk';

procedure Doit;
var
    Pw,
    Strg : string;
    Hdr : TCryptHead;
begin
    fillchar(hdr, sizeof(hdr), #0);
    Hdr.CryptStyle := EBFCBC;
    CryptInit('aaaa', Hdr);
    writeln(Squawk('Hello worldzx'));
    Strg := '12345678';
    CryptBlock(Strg);
    SetLength(Strg, 8);
    DeCryptBlk(Strg, 8);
end;
begin
   DoIt;
end.
