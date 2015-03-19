program BldTools;
  {-Simple program to build all B-Tree Filer tool units via Make}

{$I BTDEFINE.INC}

uses
  Filer,
  Vrec,
  {$IFNDEF UseFilerDLL}
  ISCompat,
  VRCompat,
  {$ENDIF}
  {$IFDEF MSDOS}
  MSort,
  TPAlloc,
  {$ENDIF}
  CArrConv,
  DBImpExp,
  {$IFDEF Ver70}
  MSortP,
  {$ENDIF}
  {$IFDEF Ver80}
  MSortP,
  {$ENDIF}
  IsamTool;

begin
end.
