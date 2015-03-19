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
* An extension to the PathList in OPDIR from Object Professional.
* Sorts the directory alphabetically at each level.
*
* Written 2/2/91, Kim Kokkonen, TurboPower Software.
*
* Modified to get rid of !%#^&! globals and to compartmentalize the unit
* dependencies.
*
* 11/29/93 K. McCoy
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$R-,S-,I-,V-,B-,F+,O+,A-}

UNIT UXTree;
    {-PathList object sorted XTree style}

INTERFACE

USES
    OPDIR;

TYPE
    XTreePathListPtr = ^XTreePathList;
    XTreePathList  = OBJECT(PathList)
                         PROCEDURE paFindAllPaths; VIRTUAL;
                         PROCEDURE xtSort(L, R : WORD; Level : BYTE);

                     PRIVATE

                         Min,
                         D,
                         C,
                         F              : WORD;
                         Rec1,
                         Rec2           : PathRec;
                         Fini           : BOOLEAN;
                     END;

    {===========================}

IMPLEMENTATION

USES
    OpInline,
    OpString,
    OpCRT,
    OpPick;

    {===========================}

    PROCEDURE XTreePathList.xtSort(L, R : WORD; Level : BYTE);
    VAR
        S,
        B,
        E              : WORD;

        FUNCTION Dest(S : WORD) : WORD;
        BEGIN
            IF S >= Min THEN
                Dest := S + B - Min
            ELSE
                Dest := S + E - Min + 1;
        END;

    BEGIN
        {sort nested levels}
        B := L;
        WHILE B <= R DO BEGIN
            IF paDPtr^[B].PLevel > Level THEN BEGIN
                E := B + 1;
                WHILE (E <= R) AND (paDPtr^[E].PLevel > Level) DO
                    INC(E);
                xtSort(B, E - 1, Level + 1);
                B := E;
            END
            ELSE
                INC(B);
        END;

        {sort this level}
        B := L;
        WHILE B <= R DO BEGIN
            {find start of minimum sequence}
            Rec1.PName := #255;
            Min := 0;
            FOR S := B TO R DO
                IF paDPtr^[S].PLevel = Level THEN
                    IF paDPtr^[S].PName < Rec1.PName THEN BEGIN
                        Rec1 := paDPtr^[S];
                        Min := S;
                    END;

            {find end of minimum sequence}
            E := Min + 1;
            WHILE (E <= R) AND (paDPtr^[E].PLevel > Level) DO
                INC(E);
            DEC(E);

            IF Min > B THEN BEGIN
                {move minimum sequence down}
                C := 1;
                F := E;
                Fini := FALSE;
                REPEAT
                    S := F;
                    D := Dest(S);
                    Rec2 := paDPtr^[S];
                    REPEAT
                        IF C > E - B THEN
                            Fini := TRUE;
                        INC(C);
                        Rec1 := paDPtr^[D];
                        paDPtr^[D] := Rec2;
                        S := D;
                        D := Dest(S);
                        Rec2 := Rec1;
                    UNTIL Fini OR (S = F);
                    DEC(F);
                UNTIL Fini;
            END;

            {continue just beyond the minimum sequence}
            INC(B, E - Min + 1);
        END;
    END;

    {===========================}

    PROCEDURE XTreePathList.paFindAllPaths;
    BEGIN
        PathList.paFindAllPaths;
        IF paCurFiles > 1 THEN
            xtSort(2, paCurFiles, 1);
    END;

    {===========================}

END.

{===========================}
{===========================}
