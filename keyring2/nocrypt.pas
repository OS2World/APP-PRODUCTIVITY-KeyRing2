unit NoCrypt;
interface
uses
    vardec;

    procedure InitNoCrypt(Password : string; Hdr : TCryptHead);
    procedure EncryptString(Block:string);
    procedure NoDecrypt(var Block);

implementation

    procedure InitNoCrypt(Password : string; Hdr : TCryptHead);
    begin
    end;

    procedure EncryptString(Block:string);
    begin
    end;

    procedure NoDecrypt(var Block);
    begin
    end;

end.
