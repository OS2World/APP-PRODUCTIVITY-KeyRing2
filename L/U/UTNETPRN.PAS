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
{$A+,B-,D+,E+,F+,G-,I+,L+,N-,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT UTNETPRN;

INTERFACE

USES
    OpPrnLow;

TYPE
    {allow printing with huge strings}
    {- UNIT PRIVATE }
    NetworkPrnPtr  = ^NetworkPrn;
    NetworkPrn     = OBJECT(BiosPrinter)

                         Spooling       : BOOLEAN;

                         CONSTRUCTOR Init(LPTNo : LPTTYPE; SpoolingOn : BOOLEAN);
                         DESTRUCTOR Done; VIRTUAL;

                         PRIVATE

                         PROCEDURE SpoolOn;
                         PROCEDURE SpoolOff;


                     END;
IMPLEMENTATION

USES
    Dos,
    UTIAM,
    OpRoot,
    UERROR;
    {--------------------------------------------------------------------}

    CONSTRUCTOR NetworkPrn.Init(LPTNo : LPTTYPE; SpoolingOn : BOOLEAN);
    BEGIN
        IF NOT BiosPrinter.Init(LPTNo) THEN BEGIN
            DispErrorDeluxe('BiosPrinter Init fail',
                            ErrorMessage(InitStatus),
                            TRUE,
                            Iam);
            FAIL;
        END;
        Spooling := SpoolingOn;
        IF SpoolingOn THEN
            SpoolOn;
    END;

    {--------------------------------------------------------------------}

    DESTRUCTOR NetworkPrn.Done;
    BEGIN
        IF Spooling THEN
            SpoolOff;
        BiosPrinter.Done;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE NetworkPrn.SpoolOn;
    VAR
        Regs           : Registers;
        Result         : BYTE;
    BEGIN
        {set default local printer}
        WITH Regs DO BEGIN
            AX := $B805;
            DH := BYTE(GetLptPort);
        END;
        MSDOS(Regs);

        {Turn on printer spooler}
        WITH Regs DO BEGIN
            AX := $DF00;
            dx := $00;
            MSDOS(Regs);
            Result := Al;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE NetworkPrn.SpoolOff;
    VAR
        Regs           : Registers;
    BEGIN
        {Turn on printer spooler}
        WITH Regs DO BEGIN
            AX := $DF00;
            {DX := $01;}          {ZZZZ this killed CAPTURE dead}
            dx := $03;            {FLUSH instead}
        END;
        MSDOS(Regs);
    END;

    {--------------------------------------------------------------------}

END.

