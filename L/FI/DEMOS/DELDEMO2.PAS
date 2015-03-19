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

unit Deldemo2;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls;

type
  TNetTypeDlg = class(TForm)
    OKBtn: TBitBtn;
    Bevel1: TBevel;
    NoNetBtn: TRadioButton;
    MsNetBtn: TRadioButton;
    NovellBtn: TRadioButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NetTypeDlg: TNetTypeDlg;

implementation

{$R *.DFM}

end.
