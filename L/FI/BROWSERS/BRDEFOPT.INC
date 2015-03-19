(**************************************************************)
(*    B-Tree Isam/Shell Browser Configuration Ver 5.51        *)
(*     Copyright (C) 1991-1994 ENZ EDV-Beratung GmbH          *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)
(**************************************************************)

{--Definition of to use B-Tree Shell or B-Tree Isam for Browser}
  (********************************************************************)
  (******************)   {$DEFINE BRUseIsam}    (**********************)
  (******************)   { $DEFINE BRUseShell}   (**********************)
  (********************************************************************)
  {-Either BRUseShell or BRUseIsam may be defined, not both. At least one
    of them must be defined to determine whether B-Tree Filer or B-Tree
    Shell is used for the browser}


(**********************************************************************)
(**********************************************************************)
{Don't change anything beyond this point}

{--Test the BRUseXXX defines}
  {$IFDEF BRUseShell}
    {$IFDEF BRUseIsam}
      ** ERROR **  You can only define one of BRUseShell or BRUseIsam
    {$ENDIF}
  {$ELSE}
    {$IFNDEF BRUseIsam}
      ** ERROR **  One of BRUseShell or BRUseIsam *must* be defined
    {$ENDIF}
  {$ENDIF}

{--Conditional defines that affect this unit}
  {$IFDEF BRUseShell}
    {$I SHDefine.Inc}
  {$ENDIF}
  {$IFDEF BRUseIsam}
    {$I BTDefine.Inc}
  {$ENDIF}
