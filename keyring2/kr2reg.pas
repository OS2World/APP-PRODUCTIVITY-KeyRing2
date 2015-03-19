//~nokeywords~
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
* KeyFile creation tool for Keyring/2
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************

}

{.$PMTYPE VIO}
{&Delphi+}

PROGRAM KR2REG;

USES
    CmdLin3,
    DGMATH,
    OpDate,
    OpString,
    Register,
    USE32,
    UTTIMDAT,
    UTSORT,
    VARDEC,
    VPUTILS;

    {$PMTYPE VIO}

    {----------------}

    FUNCTION FillRRFromCmdLine(VAR RR : TRegisterRec) : BOOLEAN;
    VAR
        Strg           : STRING;
    BEGIN
        // -d sets demo mode (30 day database lifetime, 30 year dropdead on exe
        // -k=days overrides EXE dropdead
        // -m=maxrev sets maximum revision. If progrev exceeds this, then go into demo mode (30 day db lifetime)

        // -b sets beta mode, which allows you to further set the first/last name and email
        //    database lifetime is set to infinity

        // -p sets paid mode, which removes all limitations except the maxrev

        FILLCHAR(RR, SIZEOF(RR), #0);
        RR.RegCode := RandStringLimited(16, 16, ['A'..'H', 'J', 'K', 'M', 'N', 'P'..'Z', 'a'..'h', 'j', 'k', 'm', 'n', 'p'..'z', '2'..'9']);
        RR.DropDead := Today + Param_Int('K', 365 * 30);

        IF Is_Param('d') THEN BEGIN {demo}
            RR.DemoPWXLifetime := 30;
            RR.Limits := 'Limited database lifetime! Please register!';
            RR.FirstName := 'Demo';
            RR.LastName := 'Demo';
            RR.Email := 'kr2@idk-inc.com';
            RR.InstallDate := BADDate;
            RR.FeatureBits := PWXDDFEATUREBIT + DESFEATUREBIT + (ProgVerMajor SHL 6);
            RR.DropDead := Today + Param_Int('K', 365 * 30);
            RR.MaxRev := Param_Int('M', 2)
        END;

        IF Is_Param('b') THEN BEGIN {beta}
            RR.FirstName := Param_Text('F');
            RR.Limits := 'Beta';
            RR.LastName := Param_Text('L');
            RR.Email := Param_Text('E');
            RR.DemoPWXLifetime := 999;
            RR.InstallDate := BADDate;
            RR.FeatureBits := PWXDDFEATUREBIT + (ProgVerMajor SHL 6);
            RR.MaxRev := Param_Int('M', 2)
        END;

        IF Is_Param('p') THEN BEGIN {paid}
            RR.DemoPWXLifetime := 999;
            RR.Limits := 'Paid Registration';
            RR.FirstName := Param_Text('F');
            RR.LastName := Param_Text('L');
            RR.Email := Param_Text('E');
            RR.InstallDate := BADDate;
            RR.FeatureBits := BLOFEATUREBIT + DESFEATUREBIT + PAIDFEATUREBIT + NONAGFEATUREBIT + (ProgVerMajor SHL 6);
            RR.MaxRev := Param_Int('M', 2)
        END;

        Result := TRUE;
    END;

    {----------------}

    {&Delphi+}
    PROCEDURE Runit;
    VAR
        PR             : PRegES;
        RR             : TRegisterRec;
        I              : WORD;
        R              : EXTENDED;
        Strg           : STRING;
    BEGIN
        FillRRFromCmdLine(RR);
        NEW(PR, InitGenKey(RR));

        IF Is_Param('d') THEN {demo}
            PR^.MakeAttachment(EDummyCryptDLL)
        ELSE
            PR^.MakeAttachment(ENoCryptDLL);

        DISPOSE(PR, Done);
    END;

    {---------------------}

BEGIN
    Runit;
END.

