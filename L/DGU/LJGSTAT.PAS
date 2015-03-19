unit ljgstat;
{$C MOVEABLE,DEMANDLOAD,DISCARDABLE}

interface

function GStat(cur, max : INTEGER) : WORD;

implementation

    function GStat(cur, max : INTEGER) : WORD;
    VAR
        COP            : CylonP;
    BEGIN
        GStat := 0;
        COP := PPrt^.GetCOP;
        IF COP = NIL THEN
            EXIT;
        IF NOT COP^.Update THEN
            GStat := 1;
    END;
end.