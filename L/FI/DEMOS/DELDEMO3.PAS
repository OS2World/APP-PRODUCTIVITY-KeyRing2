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

unit Deldemo3;

interface

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls;

type
  TEditDlg = class(TForm)
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    HelpBtn: TBitBtn;
    Bevel1: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    FName: TEdit;
    LName: TEdit;
    StreetEdit: TEdit;
    CityEdit: TEdit;
    Cntry: TEdit;
    ZipCode: TEdit;
    PhoneEdit: TEdit;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EditDlg: TEditDlg;

implementation

{$R *.DFM}

procedure TEditDlg.FormShow(Sender: TObject);
begin
  ActiveControl := FName;
end;

end.
