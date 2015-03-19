{ PrjBld DLL }
{ Contains utility routines for PrjBld}

library PBUTIL;
uses
    apmisc,
    OPSTRING,
    OS2DEF,
    OS2REXX,
    STRINGS,
    SYSUTILS,
    Use32;

{$CDecl+,OrgName+,I-,S-,Delphi+}

{$D Util functions for PrjBld}    // DLL description

{$LINKER
  DATA MULTIPLE NONSHARED

  EXPORTS
    AREA52      = Area52
    HEXXER       = Hexxer
    SYSLOADFUNCS = SysLoadFuncs
}
var
  Buff : STRING;

Const
  FunctionTable : Array[ 0..1 ] of pChar
                = ( 'Area52',
                    'Hexxer' );

Function SysLoadFuncs( FuncName  : PChar;
                       ArgC      : ULong;
                       Args      : pRxString;
                       QueueName : pChar;
                       Var Ret   : RxString ) : ULong; export;
Var
  j       : Integer;

begin
  Ret.strLength := 0;
  If ArgC > 0 then                        { Do not allow parameters }
    SysLoadFuncs := 40
  else  begin
      For j := Low( FunctionTable ) to High( FunctionTable ) do
        RexxRegisterFunctionDLL( FunctionTable[j],
                                 'PBUTIL',
                                 FunctionTable[j] );
      SysLoadFuncs := 0;
    end;

end;



Function Area52( Name      : PChar;
                 ArgC      : ULong;
                 Args      : pRxString;
                 QueueName : pChar;
                 Var Ret   : RxString ) : ULong; export;
var
    CurByte : BYTE;
    CurCRC  : ULONG;
    {$IFDEF pbDEBUG}
    T       : TEXT;
    {$ENDIF}
begin
    if ArgC <> 2 then begin
        Area52 := 40;
        exit;
    end;
    Area52 := 0;
    CurByte := BYTE(Args^.StrPtr^);
    INC(Args);
    CurCRC := StrToInt(Args^.StrPtr);
    Buff := IntToStr(UpdateCrc32(CurByte, CurCrc));
    Ret.StrPtr := @Buff[1];
    Ret.strLength := LENGTH(Buff);
end;

Function Hexxer( Name      : PChar;
                 ArgC      : ULong;
                 Args      : pRxString;
                 QueueName : pChar;
                 Var Ret   : RxString ) : ULong; export;
begin
    Hexxer := 0;
    Buff := HexL(StrToInt(Args^.StrPtr));
    Ret.StrPtr := @Buff[1];
    Ret.strLength := LENGTH(Buff);
end;

initialization
end.
