program BldBrows;
  {-Simple program to build all B-Tree Filer browsers via Make}

{$I BTDEFINE.INC}

{$IFNDEF Windows}
{$IFDEF Only_OPro}          { <-- This define is set by FILER.MAK }
{$DEFINE HasOpro}
{$ENDIF}
{$IFDEF Both_TPro_OPro}     { <-- This define is set by FILER.MAK }
{$DEFINE HasOpro}
{$ENDIF}
{$ENDIF}

uses
  Filer,
  Vrec,
  {$IFDEF Windows}
   {$IFDEF Ver80}
  FvcBrows;
   {$ELSE}
  WBrowser;
   {$ENDIF}
  {$ELSE}
  {$IFDEF WantTV}           { <-- This define is set by FILER.MAK }
  TVBrows,
  {$ENDIF}
  {$IFDEF HasOPro}
  OPBrow,
  {$ENDIF}
  Browser;
  {$ENDIF}

begin
end.