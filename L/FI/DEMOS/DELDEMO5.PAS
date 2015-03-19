{$A+,B-,D+,F-,G+,I+,K+,L+,N+,P+,Q-,R-,S+,T-,V+,W-,X+,Y+}
{$M 16384,8192}
(*************************************************************************)
(*                                                                       *)
(*                 B-Tree Filer & Delphi Demo                            *)
(*                    Copyright (C) 1995                                 *)
(*                  TurboPower Software Co.                              *)
(*                         Ver 5.51                                      *)
(*                    All rights reserved                                *)
(*************************************************************************)

unit Deldemo5;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons;

type
  TStatForm = class(TForm)
    BitBtn1: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  StatForm: TStatForm;

implementation

{$R *.DFM}

end.
