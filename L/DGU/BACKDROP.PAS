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
* $KLog$
* Change Date: 09-12-1997 08:34:13 By: Kevin
*    Virgin 
*
*
*
* ~notes~
* Description
* -----------
* Draw a backdrop window on top of existing one;  Preserve original screen
* and restore it on exit
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$I OPDEFINE.INC}
UNIT BACKDROP;
INTERFACE
USES
    OpRoot,
    OpWindow;

TYPE
    PBackDrop      = ^TBackDrop;
    TBackDrop      = OBJECT(ROOT)
                         CONSTRUCTOR InitFullScn;
                         CONSTRUCTOR InitFreeTopline;
                         CONSTRUCTOR InitCustomFull(Fill : CHAR; Color : BYTE);
                         CONSTRUCTOR InitCustom(Fill : CHAR; Color : BYTE; X1, Y1, X2, Y2 : BYTE);
                         DESTRUCTOR Done; VIRTUAL;
                     PRIVATE
                         W              : StackWindowPtr;
                     END;

IMPLEMENTATION
USES
    Colors,
    OpCol16,
    OpCRT;

    {----------}

    CONSTRUCTOR TBackDrop.InitCustom(Fill : CHAR; Color : BYTE; X1, Y1, X2, Y2 : BYTE);
    BEGIN
        {Make backdrop}
        NEW(W, InitCustom(X1, Y1, X2, Y2,
                          EsColors,
                          wClear + wSaveContents));

        IF InitStatus <> 0 THEN
            FAIL;

        IF W = NIL THEN
            FAIL;

        W^.EnableExplosions(6);

        W^.Draw;

        TextChar := Fill;
        TextAttr := Color;

        WINDOW(X1, Y1, X2, Y2);
        ClrScr;
    END;

    {----------}

    CONSTRUCTOR TBackDrop.InitFullScn;
    BEGIN
        IF NOT InitCustom(#177, BlackOnLtGray, 1, 1, ScreenWidth, ScreenHeight) THEN
            FAIL;
    END;

    {----------}

    CONSTRUCTOR TBackDrop.InitCustomFull(Fill : CHAR; Color : BYTE);
    BEGIN
        IF NOT InitCustom(Fill, Color, 1, 1, ScreenWidth, ScreenHeight) THEN
            FAIL;
    END;

    {----------}

    CONSTRUCTOR TBackDrop.InitFreeTopline;
    BEGIN
        IF NOT InitCustom(#177, BlackOnLtGray, 1, 2, ScreenWidth, ScreenHeight) THEN
            FAIL;
    END;

    {----------}

    DESTRUCTOR TBackDrop.Done;
    BEGIN
        DISPOSE(W, Done);
        INHERITED Done;
    END;

    {----------}

END.

    {----------}
    {----------}
