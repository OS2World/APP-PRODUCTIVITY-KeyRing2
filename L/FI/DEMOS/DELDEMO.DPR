program Deldemo;

uses
  Forms,
  Deldemo1 in 'DELDEMO1.PAS' {DemoForm},
  Deldemo2 in 'DELDEMO2.PAS' {NetTypeDlg},
  Deldemo3 in 'DELDEMO3.PAS' {EditDlg},
  Deldemo4 in 'DELDEMO4.PAS' {AboutBox},
  Deldemo5 in 'DELDEMO5.PAS' {StatForm};

{$R *.RES}

begin
  Application.CreateForm(TDemoForm, DemoForm);
  Application.CreateForm(TNetTypeDlg, NetTypeDlg);
  Application.CreateForm(TEditDlg, EditDlg);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TStatForm, StatForm);
  Application.Run;
end.
