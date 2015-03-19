unit dgpara;
uses
    LJVAR,
    OpRoot;

type
    TParaWordNode = OBJECT(SingleListNode)
                        MyWord : PCHAR;
                        MyAttr : FontTypeT;
                        MyLen  : REAL;
                        CONSTRUCTOR Init(Strg:STRING; Font:FontTypeT);
                        DESTRUCTOR Done; VIRTUAL;
                        FUNCTION GetWord : STRING;
                        FUNCTION GetFont : FontTypeT;
                        FUNCTION GetLen : REAL;
                    END;

    TParaList = OBJECT(SingleList)

