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

UNIT UTHP150;

INTERFACE

USES
    UTNETPRN,
    OoFaxPrn;

TYPE
    {KHP150Printer}
    KHP150PrinterPtr = ^KHP150Printer;
    KHP150Printer  = OBJECT(HP150Printer)

                         {Constructors/destructors}
                         CONSTRUCTOR Init(NPP : NetworkPrnPtr);
                         {-Allocate and initialize the KHP150Printer object}
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
    {---------- KHP150Printer object ----------}

    CONSTRUCTOR KHP150Printer.Init(NPP : NetworkPrnPtr);
    BEGIN
        IF NPP = NIL THEN BEGIN
            DispErrorDeluxe('Nil NPP ptr', 'KHP150Printer.Init', TRUE, Iam);
            FAIL;
        END;

        IF NOT HP150Printer.Init THEN
            FAIL;

        NP := NPP;

        {init biosprinter here ZZZZ}
    END;

    (************************************)

    PROCEDURE KHP150Printer.PrintOpen;
    BEGIN
        PrintBufCount := 0;
    END;

    (************************************)

    PROCEDURE KHP150Printer.PrintClose;
    BEGIN
        {Flush remaining data in buffer}
        IF PrintBufCount > 0 THEN
            FlushPrintBuf;
    END;

    (************************************)

    PROCEDURE KHP150Printer.FlushPrintBuf;
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
