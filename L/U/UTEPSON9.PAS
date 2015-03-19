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

UNIT UTEPSON9;

INTERFACE

USES
    UTNETPRN,
    OoFaxPrn;

TYPE
    {KEpson9Printer}
    KEpson9PrinterPtr = ^KEpson9Printer;
    KEpson9Printer = OBJECT(EpsonPrinter)

                         {Constructors/destructors}
                         CONSTRUCTOR Init(NPP : NetworkPrnPtr);
                         {-Allocate and initialize the KEpson9Printer object}

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
    {---------- KEpson9Printer object ----------}

    CONSTRUCTOR KEpson9Printer.Init(NPP : NetworkPrnPtr);
    BEGIN
        IF NPP = NIL THEN BEGIN
            DispErrorDeluxe('Nil NPP ptr', 'KEpson9Printer.Init', TRUE, Iam);
            FAIL;
        END;

        IF NOT EpsonPrinter.Init THEN
            FAIL;

        NP := NPP;
    END;

    (************************************)

    PROCEDURE KEpson9Printer.PrintOpen;
    BEGIN
        PrintBufCount := 0;
    END;

    (************************************)

    PROCEDURE KEpson9Printer.PrintClose;
    BEGIN
        {Flush remaining data in buffer}
        IF PrintBufCount > 0 THEN
            FlushPrintBuf;
    END;

    (************************************)

    PROCEDURE KEpson9Printer.FlushPrintBuf;
    BEGIN
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
