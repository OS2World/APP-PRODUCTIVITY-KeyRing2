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
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
}
{$R-,S-,A+,F+,I-,V-,B-,O+}

{$I APDEFINE.INC}

UNIT UTEPSN24;

INTERFACE

USES
    UTNETPRN,
    OoFaxPrn;

TYPE
    {Epson24Printer}
    KEpson24PinPrinterPtr = ^KEpson24PinPrinter;
    KEpson24PinPrinter = OBJECT(Epson24PinPrinter)

                             {Constructors/destructors}
                             CONSTRUCTOR Init(NPP : NetworkPrnPtr);
                             {-Allocate and initialize the Epson24Printer object}

                             {Print routines}
                             PROCEDURE PrintOpen; VIRTUAL;
                                 {-Open and prepare print device}
                             PROCEDURE PrintClose; VIRTUAL;
                                 {-Close print device}
                             PROCEDURE FlushPrintBuf; VIRTUAL;

                             PRIVATE

                             NP             : NetworkPrnPtr;
                         END;

IMPLEMENTATION

USES
    ApMisc,
    UTIAM,
    UERROR;
    {---------- Epson24Printer object ----------}

    CONSTRUCTOR KEpson24PinPrinter.Init(NPP : NetworkPrnPtr);
    BEGIN
        IF NPP = NIL THEN BEGIN
            DispErrorDeluxe('Nil NPP ptr', 'Epson24Printer.Init', TRUE, Iam);
            FAIL;
        END;

        IF NOT Epson24PinPrinter.Init THEN
            FAIL;

        NP := NPP;

        {init biosprinter here ZZZZ}
    END;

    (************************************)

    PROCEDURE KEpson24PinPrinter.PrintOpen;
    BEGIN
        PrintBufCount := 0;
    END;

    (************************************)

    PROCEDURE KEpson24PinPrinter.PrintClose;
    BEGIN
        {Flush remaining data in buffer}
        IF PrintBufCount > 0 THEN
            FlushPrintBuf;
        PrintBufCount := 0;
    END;

    (************************************)

    PROCEDURE KEpson24PinPrinter.FlushPrintBuf;
    BEGIN
        {send buffer to biosprinter device}
        {send buffer to biosprinter device}
        NP^.PrnPutBlock(PrintBuf^[0], PrintBufCount);

        AsyncStatus := NP^.PrnError;

        {Clear buffer contents counter}
        PrintBufCount := 0;

        {Call user hook}
        IF CallWriteNotify(PrintBufCount) THEN
            AsyncStatus := ecUserAbort;
    END;

    (************************************)
    (************************************)

END.

