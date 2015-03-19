program BldNetTl;
  {-Simple program to build all B-Tree Filer network tool units via Make}

{$I BTDEFINE.INC}

uses
  {$IFDEF DPMIOrWnd}
  DPMI,
  {$ENDIF}
  NetBIOS,
  NWBase, NWConn, NWFile, NWBind, NWSema, NWMsg, NWTTS, NWPrint,
  NWIPXSPX,
  OOPSema,
  Share;

begin
end.
