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
* Generic Read-only text file viewer for screen messages, etc.
*
*
* ~notesend~
*
****************************************************************************

}
UNIT TEXTVWR;
INTERFACE
USES
    OpCRT,
    OpMemo,
    OpWindow;

    {------------}

TYPE
    PTextFileViewer = ^TTextFileViewer;
    TTextFileViewer = OBJECT(MemoFile)
                          CONSTRUCTOR Init(Name           : STRING;
                                           X1, Y1,
                                           X2, Y2         : BYTE;
                                           Colors         : ColorSet);
                      PRIVATE
                          Buff           : POINTER;
                          BuffSize       : WORD;
                      END;

    {------------}

IMPLEMENTATION
USES
    OpInline;

    {------------}

    CONSTRUCTOR TTextFileViewer.Init(Name           : STRING;
                                     X1, Y1,
                                     X2, Y2         : BYTE;
                                     Colors         : ColorSet);
    CONST
        MyOptions      = meReadOnly + meWordWrap + meMousePage;
    VAR
        L              : LONGINT;
    BEGIN
        BuffSize := MinLong(MAXAVAIL DIV 2, $FFF0);

        IF NOT InitCustomAndAlloc(X1, Y1, X2, Y2,
                                  Colors,
                                  MyOptions + DefWindowOptions + wBordered,
                                  BuffSize) THEN
            FAIL;

        ReadFile(Name, L);

    END;

    {------------}

END.

    {------------}
    {------------}
