program BldFiler;                                               {!!.51}
  {-Simple program to build all B-Tree Filer units via Make}

{$I BTDEFINE.INC}

uses
{$IFDEF UseFilerDLL}
  RexCHook,
{$ELSE}
  {$IFDEF MSDOS}
  EMSHeap,
  EMSSupp,
  {$ENDIF}
{$ENDIF}
  BaseSupp,
{$IFDEF VER80}
  DosSupp,
{$ENDIF}
  Filer,
  Vrec,
  BufRecIO,
  NumKeys,
  Rebuild,
  Reorg,
  ReIndex,
  VRebuild,
  VReorg,
  FixToVar,
  Restruct;

begin
end.
