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

unit Deldemo4;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    OKButton: TBitBtn;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    Copyright: TLabel;
    Label1: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.DFM}

end.
 
