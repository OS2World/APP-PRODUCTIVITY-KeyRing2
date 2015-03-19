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
* Descendent command processors that handle extended command tables.  See
* also DGFKEY that adds management of Function key labels and mouse clicks.
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}

{$I OPDEFINE.INC}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}

UNIT DGCMD;
    {-Convert keystrokes to commands}
INTERFACE

USES
    OpDate,
    OpRoot,
    {$IFDEF USEMOUSE}
    OpMouse,
    {$ENDIF}
    OpCmd
    {$IFDEF UseDrag}
    , OpDrag
    {$ENDIF}
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

CONST
    IdleTime       = 2;           {Minutes}

TYPE
    PDGUCommandProcessor = ^TDGUCommandProcessor;
    {$IFDEF UseDrag}
    TDGUCommandProcessor = OBJECT(DragProcessor)
                               CONSTRUCTOR Init(KeysPtr : CmdTablePtr; MaxIndex : WORD);
                               CONSTRUCTOR InitTimeOut(KeysPtr        : CmdTablePtr;
                                                       MaxIndex       : WORD;
                                                       TimeoutMS      : LONGINT;
                                                       TimeOutCmd     : WORD);
                               DESTRUCTOR Done; VIRTUAL;
                               PROCEDURE ChangeTimeout(TimeoutMS : LONGINT; TimeOutCmd : WORD);
                               FUNCTION cpGetKey : WORD; VIRTUAL;
                               FUNCTION cpKeyPressed : BOOLEAN; VIRTUAL;
                           PRIVATE
                               Keys           : CmdTablePtr;
                               Len,
                               MyTimeoutCmd   : WORD;
                               MyTimeOutMS    : LONGINT;
                           END;

    {$ELSE}
    TDGUCommandProcessor = OBJECT(CommandProcessor)
                               CONSTRUCTOR Init(KeysPtr : CmdTablePtr; MaxIndex : WORD);
                               CONSTRUCTOR InitTimeOut(KeysPtr        : CmdTablePtr;
                                                       MaxIndex       : WORD;
                                                       TimeoutMS      : LONGINT;
                                                       TimeOutCmd     : WORD);
                               PROCEDURE ChangeTimeout(TimeoutMS : LONGINT; TimeOutCmd : WORD);
                               DESTRUCTOR Done; VIRTUAL;
                               FUNCTION cpGetKey : WORD; VIRTUAL;
                               FUNCTION cpKeyPressed : BOOLEAN; VIRTUAL;
                           PRIVATE
                               Keys           : CmdTablePtr;
                               Len,
                               MyTimeoutCmd   : WORD;
                               MyTimeOutMS    : LONGINT;
                           END;
    {$ENDIF}


PROCEDURE TpUpdateClock;

IMPLEMENTATION
USES
    KERROR,
    OpString,
    OpCol16,
    OpConst,
    OpCRT,
    OpDos
    {$IFDEF VirtualPascal}
    ,OS2BASE,
    VPUTILS
    {$ENDIF}
    ;

    {-----------}

    {- Write heap status, time and date to crt status line}
    PROCEDURE TpUpdateClock;
    CONST
        LAST           : LONGINT = 0;
        LastBlink      : LONGINT = 0;
        BLK            : BOOLEAN = TRUE;
        Ts             : ARRAY[BOOLEAN] OF STRING[5] =
        ('hh mm', 'hh:mm');
    VAR
        S1             : STRING[32];
    BEGIN
        IF ABS(TimeMS - LastBlink) > 500 THEN BEGIN
            BLK := NOT BLK;
            LastBlink := TimeMS;
        END;

        IF ABS(TimeMS - LAST) > 100 THEN BEGIN { 100 Ms update interval !!.KVN}
            S1 := Pad(DateToDateString('www dd-nnn-yyyy', Today) + ' ' +
                      TimeToTimeString(Ts[BLK], CurrentTime), 25);
            FastWrite(S1, 1, 1, ColorMono(BlackOnLtGray, BlackOnLtGray));
            {$IFDEF DEBUG}
            {$IFDEF VirtualPascal}
            S1 := LeftPad(LongIntForm('###,###,###', MemUsed), 15);
            {$ELSE}
            S1 := LeftPad(Long2Str(MEMAVAIL) + ':' + Long2Str(MAXAVAIL), 15);
            {$ENDIF VirtualPascal}
            FastWrite(S1, 1, 25, ColorMono(BlackOnLtGray, BlackOnLtGray));
            {$ENDIF}
            LAST := TimeMS;
        END;
    END;

    {-----------}

    FUNCTION TDGUCommandProcessor.cpKeyPressed : BOOLEAN;
    VAR
        Prs            : BOOLEAN;
    BEGIN
        CurrentClockProc;
        {$IFDEF USEMOUSE}
        Prs := KeyOrButtonPressed;
        {$ELSE}
        Prs := KeyPressed;
        {$ENDIF}
        IF NOT Prs THEN
            {$IFNDEF VirtualPascal}
            INLINE($CD / $28);    { Allow TSRs to pop up }
        {$ELSE}
            DosSleep(50);
        {$ENDIF}
        cpKeyPressed := Prs;
    END;

    {-----------}
    {$IFDEF VirtualPascal}
    {&Delphi+}
    FUNCTION TDGUCommandProcessor.cpGetKey : WORD;
    VAR
        K              : WORD;
        StartTime      : LONGINT;
    BEGIN
        try
            StartTime := TimeMS;
            REPEAT
                IF cpKeyPressed THEN
                    BREAK;
                IF (MyTimeOutMS > 0) AND (ABS(TimeMS - StartTime) > MyTimeOutMS) THEN BEGIN
                    cpGetKey := MyTimeoutCmd;
                    RingBell;
                    EXIT;
                END;
            UNTIL FALSE;

            {$IFDEF USEMOUSE}
            K := ReadKeyOrButton;
            {$ELSE}
            K := ReadKeyword;
            {$ENDIF}
            cpGetKey := K;
        except
            halt(1);
        end;
    END;
    {&Delphi+}
    {$ELSE}

    {---------------------}

    FUNCTION TDGUCommandProcessor.cpGetKey : WORD;
    VAR
        K              : WORD;
        StartTime      : LONGINT;
    BEGIN
        StartTime := TimeMS;
        REPEAT
            IF cpKeyPressed THEN
                BREAK;
            IF (MyTimeOutMS > 0) AND (ABS(TimeMS - StartTime) > MyTimeOutMS) THEN BEGIN
                cpGetKey := MyTimeoutCmd;
                RingBell;
                EXIT;
            END;
        UNTIL FALSE;

        {$IFDEF USEMOUSE}
        K := ReadKeyOrButton;
        {$ELSE}
        K := ReadKeyWord;
        {$ENDIF}
        cpGetKey := K;
    END;
    {$ENDIF}
    {-----------}

    CONSTRUCTOR TDGUCommandProcessor.Init(KeysPtr : CmdTablePtr; MaxIndex : WORD);
    BEGIN
        Keys := NIL;
        GETMEM(Keys, MaxIndex);
        IF Keys = NIL THEN BEGIN
            InitStatus := epFatal + ecOutOfMemory;
            FAIL;
        END;
        MOVE(KeysPtr^, Keys^, MaxIndex);
        {$IFDEF UseDrag}
        IF NOT DragProcessor.Init(Keys, MaxIndex) THEN
            FAIL;
        {$ELSE}
        IF NOT CommandProcessor.Init(Keys, MaxIndex) THEN
            FAIL;
        {$ENDIF}
        cpOptionsOn(cpUpcase);
        {$IFDEF UseMouse}
        IF MouseInstalled THEN
            cpOptionsOn(cpEnableMouse);
        {$ENDIF}
        Len := MaxIndex;
        MyTimeOutMS := - 1;
    END;

    {-----------}

    CONSTRUCTOR TDGUCommandProcessor.InitTimeOut(KeysPtr        : CmdTablePtr;
                                                 MaxIndex       : WORD;
                                                 TimeoutMS      : LONGINT;
                                                 TimeOutCmd     : WORD);
    BEGIN
        IF NOT TDGUCommandProcessor.Init(KeysPtr, MaxIndex) THEN
            FAIL;
        MyTimeOutMS := TimeoutMS;
        MyTimeoutCmd := TimeOutCmd;
    END;

    {-----------}

    PROCEDURE TDGUCommandProcessor.ChangeTimeout(TimeoutMS : LONGINT; TimeOutCmd : WORD);
    BEGIN
        MyTimeOutMS := TimeoutMS;
        MyTimeoutCmd := TimeOutCmd;
    END;

    {-----------}

    DESTRUCTOR TDGUCommandProcessor.Done;
    BEGIN
        {$IFDEF UseDrag}
        DragProcessor.Done;
        {$ELSE}
        CommandProcessor.Done;
        {$ENDIF}
        IF Keys <> NIL THEN
            FREEMEM(Keys, Len);
        Keys := NIL
    END;

    {-----------}

END.
