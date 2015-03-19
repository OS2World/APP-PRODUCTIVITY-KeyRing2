{***************************************************************************
* Filename: ~modname~
* Version:  ~version~
* Date:     ~date~ @ ~time~
* Group:    ~group~
* Release:  ~release~
* ----------------------------
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer   Description
* ~log~
*
*
* ~notes~
* Description
* -----------
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,F+,S+,O+}

Unit UFax;

interface

Uses
  Dos, OpCrt, TpfView, OOFaxPrn;

  function ViewFax(FName: PathStr): boolean;
  Procedure PrintFax(FaxFile: PathStr);

type
  FaxPrinterTypes = (Epson,    Epson24,
                     HPPcl4,   HPPcl5);

  ResolutionTypes = (DPI300, DPI150);

Const
  FaxPrinterType  : FaxPrinterTypes = Epson24;
  Resolution      : ResolutionTypes = DPI150;

implementation

  function ViewFax(FName: PathStr): boolean;
  var
    TV: PFaxViewer;
  begin
    New(TV, Init(FName, $12, 640, 480));
    if (TV = nil) then
      begin
      ViewFax := False;
      Exit;
      end
    else
      begin
{      TV^.SetErrorProc(ShowError);}
      TV^.Process;
      Dispose(TV, Done);
      ViewFax := True;
    end;
  end;

  Procedure PrintFax(FaxFile: PathStr);
  var
    Printer : AbstractPrinterPtr;
    FaxPrn  : FaxPrinterPtr;    {Fax printing object}
  begin
  {Init objects}
  Case FAXPrinterType of
    Epson   : Printer := New(EpsonPrinterPtr,      Init);
    Epson24 : Printer := New(Epson24PinPrinterPtr, Init);
    HPPcl4,
    HPPcl5  : if Resolution = DPI300 then
                Printer := New(HP300PrinterPtr,      Init)
              else
                Printer := New(HP150PrinterPtr,      Init);
    end;
  New(FaxPrn, Init(Printer));

  {Set options}
  if FAXPrinterType = HPPCL5 then
    FaxPrn^.SetPcl5Mode(True);            {Uses PCL5 commands to compress}
  FaxPrn^.SetScaling(True);               {Scale page output}
  FaxPrn^.SetHeader(False);               {Print a header on each page}
  FaxPrn^.SetBlankLineSuppression(True);  {Strip blank areas}

  {Print the fax}
  FaxPrn^.PrintFax('LPT1', FaxFile);

  {Dispose of objects}
  Dispose(FaxPrn, Done);
  Dispose(Printer, Done);

  end;

End.
