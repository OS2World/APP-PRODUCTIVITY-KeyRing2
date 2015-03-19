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
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,V-,F+,O+}

{$I opdefine.inc}
{$D+,L+}
{$I NDEFINE.INC}
{$X+}
UNIT UDIALOG;

INTERFACE

USES
    Dos,
    FDialog,
    NWBASE,
    OpCmd,
    OpCrt,
    OpCtrl,
    OpDialog,
    OpDir,
    OpPick,
    OpRoot,
    OpWindow,
    OpEditor,
    OpAsciiZ,
    USPXGlo,
    UGLOBAL;

CONST
    MSGSIZE        = 5;

TYPE
    MsgArray       = ARRAY[1..MSGSIZE] OF STRING;

PROCEDURE InitMsgArray(VAR Msg : MsgArray);
PROCEDURE MessageWin(Header         : STRING;
                     VAR Msg        : MsgArray;
                     VAR EsColors   : ColorSet);

FUNCTION MessageBox(Header         : STRING;
                    VAR Msg        : MsgArray;
                    HelpInd        : INTEGER;
                    VAR EsColors   : ColorSet;
                    VAR dColors    : DialogColorSet) : WORD;

PROCEDURE TellUser(Msg : STRING);

FUNCTION KDialog(Msg : STRING; Title : STRING; TitleColor : BYTE;
                 Box1 : STRING; Box2 : STRING) : INTEGER;

FUNCTION Timer : LONGINT;


FUNCTION GetUserName : STRING;
FUNCTION GetUserFullName(ShortName:tnwObjectStr) : STRING;
{FUNCTION GetUserFullName(ShortName:STRING) : STRING;zzzz}

PROCEDURE PickSaveFile(VAR SFile : PathStr);

PROCEDURE PickGetFile(VAR SFile : PathStr);

FUNCTION GetFileName(Mask : DirStr; VAR FileName : PathStr) : BOOLEAN;

FUNCTION GetFileProc(MsgCode : WORD; Prompt : STRING;
                     ForceUp, TrimBlanks, Writing, MustExist : BOOLEAN;
                     MaxLen         : BYTE; DefExt : ExtStr;
                     VAR S          : STRING) : BOOLEAN;

FUNCTION EditProc(MsgCode        : WORD;
                  Prompt         : STRING;
                  ForceUp        : BOOLEAN;
                  TrimBlanks     : BOOLEAN;
                  MaxLen         : BYTE;
                  VAR S          : STRING) : BOOLEAN;

FUNCTION FirstCharUpperEditProc(MsgCode        : WORD;
                                Prompt         : STRING;
                                TrimBlanks     : BOOLEAN;
                                MaxLen         : BYTE;
                                VAR S          : STRING) : BOOLEAN;

FUNCTION CustomEditProc(MsgCode        : WORD;
                        Prompt         : STRING;
                        TrimBlanks     : BOOLEAN;
                        MaxLen         : BYTE;
                        Picture        : STRING;
                        VAR S          : STRING) : BOOLEAN;

FUNCTION YesOrNo(MsgCode : WORD; Prompt : STRING;
                 Default : BYTE; QuitAndAll : BOOLEAN) : BYTE;

PROCEDURE ErrorProc(UnitCode : BYTE; VAR ErrorCode : WORD; ErrorMsg : STRING);

PROCEDURE GetInput(Msg            : STRING;
                   Title          : STRING;
                   TitleColor     : BYTE;
                   Prompt         : STRING;
                   Len            : WORD;
                   VAR Out        : STRING;
                   VAR Escape     : BOOLEAN);

PROCEDURE ReadField(X, Y           : INTEGER;
                    Len            : INTEGER;
                    ForceUpper     : BOOLEAN;
                    Atr            : BYTE;
                    Prefill        : STRING;
                    VAR Dat        : STRING;
                    VAR Escape     : BOOLEAN);

PROCEDURE ReadNumericField(X, Y : INTEGER; Len : INTEGER; Min, Max : WORD;
                           Atr            : BYTE; Prefill : WORD; VAR Dat : WORD;
                           VAR Escape     : BOOLEAN);

PROCEDURE Message(Msg : STRING);

PROCEDURE GetSearchOptions(VAR TE : TextEditor);

PROCEDURE GetDirSpec(VAR DR : DirSpec);

FUNCTION InitDialog(X1, Y1, X2, Y2 : BYTE;
                    Title          : STRING;
                    ColorSetP      : ColorSetProc;
                    VAR DB         : DialogBoxPtr) : WORD;

PROCEDURE GetSerialParameters(VAR SP : SerialPortRec);

CONST
    ChildEditorPtr : TextEditorPtr = NIL;

TYPE
    DriveListPtr   = ^DriveList;
    DriveList      = OBJECT(PickList)
                         CONSTRUCTOR Init(X1, Y1 : BYTE; Colors : ColorSet);
                         FUNCTION GetDrive : STRING;

                         PRIVATE

                         CTP            : CmdTablePtr;
                         ActiveDrives   : ARRAY[diFirstDrive..diLastDrive] OF BOOLEAN;

                         PROCEDURE ItemString(Item           : WORD;
                                              Mode           : pkMode;
                                              VAR IType      : pkItemType;
                                              VAR IString    : STRING); VIRTUAL;

                     END;



    DirDialogPtr   = ^DirDialog;
    DirDialog      = OBJECT(DialogBox)
                         {-Initialize the file dialog box}
                         CONSTRUCTOR Init(X1, Y1 : BYTE; HT : HelpType; Mask : PathStr);

                         {-Initialize the file dialog box with custom window options}
                         CONSTRUCTOR InitCustom(X1, Y1         : BYTE;
                                                VAR Colors     : ColorSet;
                                                Options,
                                                DOptions       : LONGINT;
                                                Header         : STRING;
                                                VAR dColors    : DialogColorSet;
                                                HT             : HelpType;
                                                Mask           : PathStr);

                             {-Dispose of the file dialog box}
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetPath : STRING;

                         PRIVATE

                         ddDrivePtr     : DriveListPtr;
                         ddDirPtr       : PathListPtr;
                         ddSelPath      : PathStr;
                         PROCEDURE ddSetPath(Path : PathStr);
                         PROCEDURE dgPostFocus; VIRTUAL;
                             {-Called just after a control has given up the focus}
                     END;

    CylonObjPtr    = ^CylonObj;
    CylonP         = ^CylonObj;

    CylonObj       = OBJECT(StackWindow)
                         CONSTRUCTOR Init(Header : STRING; CWidth : INTEGER);
                         CONSTRUCTOR InitCFD(Header : STRING; CWidth, CFD : INTEGER);
                         CONSTRUCTOR InitDeluxe(TopHeader, BotHeader : STRING);
                         PROCEDURE Draw; VIRTUAL;
                         FUNCTION Update : BOOLEAN;
                         PROCEDURE Sleep;
                         PROCEDURE MarkCurrent; VIRTUAL;
                         PROCEDURE MarkNotCurrent; VIRTUAL;
                         DESTRUCTOR Done; VIRTUAL;
                         PROCEDURE ChangeTopHeader(Header:STRING);
                         PROCEDURE ChangeBotHeader(Header:STRING);
                         FUNCTION GetTopHeader : STRING;
                         FUNCTION GetBotHeader : STRING;

                         PRIVATE

                         NumDots,
                         Count          : INTEGER;
                         CylonFlashDelay,
                         InitTime,
                         LastTime       : LONGINT;
                         IsDrawn,
                         KeyCap         : BOOLEAN;
                         Parent         : WindowPtr;
                         TopHead,
                         BotHead        : STRING[80];
                     END;

    KTellUserP     = ^KTellUser;
    KTellUser      = OBJECT
                         CONSTRUCTOR Init(Msg:STRING);
                         DESTRUCTOR  Done;

                         PRIVATE

                         MsgWin         : RawWindowPtr;
                     END;

IMPLEMENTATION

USES
    CMDLIN,
    nwbind,
    nwconn,
    {NetBind,}
    OpCol16,
    OpDos,
    OpDrag,
    OpFEdit,
    OpField,
    OpFrame,
    OpInline,
    OpKey,
    OpMemo,
    OpMouse,
    OpString,
    QGlobal,
    QHdrRec,
    QInput,
    QNovell,
    QUpTime,
    UColors,
    UERROR,
    UFKEY,
    {$IFDEF USEIPX}
    UIpxSpx,
    {$ENDIF}
    UKey,
    ULIB,
    UTIAM,
    UWindow;

CONST
    SGFile         : PathStr = '';
    KEYSETMAX      = 100;

VAR
    SaveGet        : DialogBoxPtr;
    DCP            : DragProcessorPtr;
    PCP            : DragProcessorPtr;
    SaveGetDir     : DirListPtr;
    WinOptions     : LONGINT;

TYPE
    UserName       = STRING[8];

CONST

    DefaultName    = 'NEN';

    {-----------------------}

    CONSTRUCTOR DriveList.Init(X1, Y1 : BYTE; Colors : ColorSet);
    VAR
        C              : CHAR;
        NumDrives      : BYTE;
        PickWindowOptions,
        PickListOptions : LONGINT;
    BEGIN
        FILLCHAR(ActiveDrives, SIZEOF(ActiveDrives), #0);

        NumDrives := 0;

        FOR C := 'A' TO 'Z' DO BEGIN
            IF ValidDrive(C) THEN BEGIN
                ActiveDrives[C] := TRUE;
                INC(NumDrives);
            END;
        END;


        PickWindowOptions := DefWindowOptions OR wBordered;
        PickListOptions := pkStick + pkAlterPageRow + pkMousePage + pkDrawActive +
                           pkSetDefault;

        IF NOT PickList.InitAbstractDeluxe(X1 + 1, Y1 + 1, X1 + 3, Y1 + 6,
                                           Colors,
                                           PickWindowOptions,
                                           2,
                                           NumDrives,
                                           PickVertical,
                                           SingleChoice,
                                           PickListOptions) THEN
            FAIL;

        CustomizeCommandProcessor(PickCommands);

        IF NOT GetMemCheck(CTP, KEYSETMAX) THEN
            FAIL;
        FILLCHAR(CTP^, KEYSETMAX, 0);

        PickCommands.SetSecondaryKeyPtr(CTP, KEYSETMAX);

        PickCommands.AddSecondaryCommand(ccUser2, 1, OpKey.F2, 0);
        PickCommands.AddSecondaryCommand(ccUser3, 1, OpKey.F3, 0);
        IF PickCommands.GetLastError <> 0 THEN
            RingBell;
        pkOptionsOn(pkProcessZero);
        PickCommands.cpOptionsOn(cpSwitchPriority);
        SetSearchMode(PickStringSearch);
        AddSearchHeader(10, heBL);
        wFrame.AddScrollBar(frRR, 1, MAXLONGINT, Colors);
        RawWindow.EnableExplosions(8);

    END;

    {-------------------------------------------------------------}

    FUNCTION DriveList.GetDrive : STRING;
    VAR
        I,
        Item           : BYTE;
        C              : CHAR;
        Strg           : STRING;
    BEGIN
        I := 0;
        C := 'A';
        GetDrive := '';
         {IF GetLastCommand <> ccSelect THEN
             EXIT;}
        Item := GetLastChoice;
        WHILE I < Item DO BEGIN
            IF ActiveDrives[C] THEN
                INC(I);
            INC(C);
            IF C > 'Z' THEN
                EXIT;
        END;
        Strg := 'A';
        Strg[1] := PRED(C);
        GetDrive := Strg;
    END;

    {-------------------------------------------------------------}

    PROCEDURE DriveList.ItemString(Item           : WORD;
                                   Mode           : pkMode;
                                   VAR IType      : pkItemType;
                                   VAR IString    : STRING);
    VAR
        I              : BYTE;
        C              : CHAR;
    BEGIN
        I := 0;
        C := 'A';
        IString := '';
        WHILE I < Item DO BEGIN
            IF ActiveDrives[C] THEN
                INC(I);
            INC(C);
            IF C > 'Z' THEN
                EXIT;
        END;
        IString := 'A:';
        IString[1] := PRED(C);
    END;

    {-------------------------------------------------------------}

    {-Initialize the file dialog box}
    CONSTRUCTOR DirDialog.Init(X1, Y1 : BYTE; HT : HelpType; Mask : PathStr);
    VAR
        Colors         : ColorSet;
        dColors        : DialogColorSet;
        WinOptions     : LONGINT;
    BEGIN
        WinOptions := wBordered + wClear + wUserContents;
        GetScheme(FileColors, Colors, dColors);
        IF NOT InitCustom(X1, Y1, Colors, WinOptions, 0, 'Select Path', dColors, HT, Mask) THEN
            FAIL;

    END;

    (****************************************************************************)

    PROCEDURE DriveListMoveProc(P : PickListPtr); FAR;
        {-Called each time the cursor is moved in the file list}
    BEGIN
        WITH DriveListPtr(P)^ DO
            IF (pkChoice <> pkInitChoice) AND
            NOT FlagIsSet(pkSecFlags, pkFakingOneItem) THEN BEGIN
                DirDialogPtr(ParentPtr)^.ddSetPath(GetDrive);
                pkInitChoice := pkChoice;
            END;
    END;

    (****************************************************************************)


CONST
    {ID's for controls in a file dialog box}
    idFileName     = 0;
    idDirName      = 1;
    idFileWin      = 2;
    idDirWin       = 3;
    idOk1          = 4;
    idCancel       = 5;
    idHelp1        = 6;

    hiFileName     = 1;
    hiDirName      = 2;
    hiFileWin      = 3;
    hiDirWin       = 4;
    HiOk1          = 5;
    hiCancel       = 6;
    HiHelp1        = 7;

    iddPathName    = 0;
    iddDriveWin    = 1;
    iddPathWin     = 2;
    iddOk          = 4;
    iddCancel      = 5;
    iddHelp        = 6;

    HidPathName    = 0;
    HidDriveWin    = 1;
    HidPathWin     = 2;
    HidOk          = 4;
    HidCancel      = 5;
    HidHelp        = 6;

    (****************************************************************************)

    PROCEDURE DirDialog.dgPostFocus;
        {-Called just after a control has given up the focus}

        PROCEDURE FixFName;
        BEGIN
        (*
            IF (JustFileName(fdFName) = fdFName) OR
            (POS(':', fdFName) = 0) AND(fdFName[1] <> '\') THEN
                fdFName := AddBackSlash(fdDirName) + fdFName
            ELSE IF (fdFName[1] = '\') THEN
                fdFName := COPY(fdDirName, 1, 2) + fdFName;
        *)
        END;

        PROCEDURE ResetFilename;
        BEGIN
            (*
            fdFilePtr^.SetMask(fdFName, AnyFile - Directory);
            fdFilePtr^.PreLoadDirList;
            fdDirName := JustPathname(fdFilePtr^.diMask);
            IF fdDirName <> JustPathname(fdDirPtr^.diMask) THEN BEGIN
                fdDirPtr^.SetMask(fdFName, Directory);
                fdDirPtr^.PreLoadDirList;
            END;
            fdDirPtr^.diMask := fdFilePtr^.diMask;

            fdFName := JustFileName(fdFName);
            ResetScreen;
            cwCmd := ccNone
            *)
        END;

        PROCEDURE DirectoryCheck;
        BEGIN
            (*
            FixFName;
            IF IsDirectory(fdFName) THEN BEGIN
                {fdFName := AddBackSlash(fdFName) + JustFileName(fdFilePtr^.diMask);}
                ResetFilename;
            END;
            *)
        END;

    BEGIN
        {
        IF cwCmd <> ccSelect THEN
            EXIT;
        }
        CASE GetCurrentID OF
            iddDriveWin : BEGIN
                              {cwCmd := ccNone}
                              SetNextField(iddPathWin);
                          END;
            iddPathWin : BEGIN
                             cwCmd := ccNone;
                             SetNextField(iddOk);
                         END;
            iddOk : BEGIN
                        IF ddSelPath = '' THEN BEGIN
                            cwCmd := ccNone;
                            SetNextField(iddCancel);
                        END;
                    END;
            ELSE
                EXIT;
        END;
        IF GetLastCommand = ccSelect THEN
            FixFName;
    END;

    (****************************************************************************)


    {-Initialize the file dialog box with custom window options}
    CONSTRUCTOR DirDialog.InitCustom(X1, Y1         : BYTE;
                                     VAR Colors     : ColorSet;
                                     Options,
                                     DOptions       : LONGINT;
                                     Header         : STRING;
                                     VAR dColors    : DialogColorSet;
                                     HT             : HelpType;
                                     Mask           : PathStr);
    VAR
        X,
        Y,
        Wid,
        Hyt            : WORD;
    CONST
        ButtonLine     = 13;
    BEGIN
        IF Mask = '' THEN
            Mask := '*.*';

        ddSelPath := '';

        {instantiate dialog box}
        IF NOT DialogBox.InitCustom(X1,
                                    Y1,
                                    X1 + 46,
                                    Y1 + ButtonLine,
                                    Colors,
                                    Options,
                                    dColors) THEN
            FAIL;
        {instantiate file list}
        X := X1 + 1;
        Y := Y1 + 6;

        wFrame.AddHeader(' ' + Header + ' ', heTC);

        NEW(ddDrivePtr, Init(1, 1, Colors));
        IF ddDrivePtr = NIL THEN BEGIN
            X := InitStatus;
            FAIL;
        END;

        ddDrivePtr^.SetMoveProc(DriveListMoveProc);

        NEW(ddDirPtr, InitCustom(2, 2, 31, 7, {Window coordinates}
                                 Colors, {ColorSet}
                                 DefWindowOptions OR wBordered, {Window options}
                                 8000, {Max heap space for files}
                                 PickVertical, {Pick orientation}
                                 SinglePath)); {Command handler}
        IF ddDirPtr = NIL THEN BEGIN
            X := InitStatus;
            DISPOSE(ddDrivePtr, Done);
            FAIL;
        END;

        {iddPathName}
        dgFieldOptionsOn(efProtected);
        AddSimpleEditControl('Path:', 1, 2, 'X', 1, 13, 34, 79, HidPathName, ddSelPath);
        dgFieldOptionsOff(efProtected);

        {idDriveWin}
        AddWindowControl('&Drives', 3, 2, 4, 2, hiDirWin, ccSelect, ddDrivePtr^);
        X := GetLastError;
        IF X <> 0 THEN
            FAIL;

        {idDirWin:}
        AddWindowControl('D&irectories', 3, 13, 4, 13, hiDirWin, ccSelect, ddDirPtr^);
        X := GetLastError;
        IF X <> 0 THEN
            FAIL;

        {idOK:}
        AddPushButton('O&K', ButtonLine, 5, 8, HiOk1, ccSelect, TRUE);

        {idCancel:}
        AddPushButton('Cancel', ButtonLine, 18, 8, hiCancel, ccQuit, FALSE);

        {idHelp:}
        CASE HT OF
            hHidden : dgFieldOptionsOn(efHidden);
            hProtected : dgFieldOptionsOn(efProtected);
        END;
        AddPushButton('Help', ButtonLine, 31, 8, HiHelp1, ccHelp, FALSE);
        dgFieldOptionsOff(efHidden + efProtected);

        IF RawError <> 0 THEN BEGIN
            InitStatus := RawError;
            Done;
            FAIL;
        END;
    END;

    (****************************************************************************)

    PROCEDURE DirDialog.ddSetPath(Path : PathStr);
    BEGIN
        ddSelPath := Path;
        DrawField(iddPathName);
    END;

    (****************************************************************************)


    {-Dispose of the file dialog box}
    DESTRUCTOR DirDialog.Done;
    BEGIN
        DISPOSE(ddDirPtr, Done);
        DISPOSE(ddDrivePtr, Done);
        DialogBox.Done;
    END;

    (****************************************************************************)

    FUNCTION DirDialog.GetPath : STRING;
    BEGIN

    END;

    (****************************************************************************)

    {-------------------------------------------------------------}

    PROCEDURE TellUser(Msg : STRING);
    VAR
        TUP : KTellUserP;
    BEGIN
        NEW(TUP, Init(Msg));
        DISPOSE(TUP, Done);
    END;

    {-------------------------------------------------------------}


    FUNCTION GetUserName : STRING;
    BEGIN

        IF SYS^.NovellSys AND IsLoggedIn THEN
            GetUserName := GetUsersName
        ELSE BEGIN
            IF SYS^.UsersName = 'QLOGIN' THEN BEGIN
                IF Is_Param('U') THEN
                    SYS^.UsersName := Param_Text('U');
            END;
            GetUserName := SYS^.UsersName;
        END;
    END;

    {-------------------------------------------------------}

    {find users full name in bindery when passed the short name}

    FUNCTION GetUserFullName(ShortName:tnwObjectStr) : STRING;
    VAR
        HasProperties    : Boolean;
        ObjType          : Word;
        ObjID            : LongInt;
        ObjSec,
        Result           : Byte;
        ObjIsDynamic     : boolean;
        MoreSegs         : boolean;
        PropVal          : {PropertyValueType}TnwPropValue;
        PropAsciiZ       : AsciiZ absolute PropVal;
    BEGIN
        GetUserFullName := ShortName;
        IF SYS^.NovellSys THEN BEGIN

            {if no shortname, then just quit}
            IF LENGTH(ShortName) = 0 then
                EXIT;

            ShortName := StUpCase(ShortName);

            ObjType := NWboUser;            {look for an user object}
            ObjID   := -1;                  {indicate start of search}
            {scan the bindery for the object}
            Result := nwbScanObject(nwDefaultServer, ObjType, ShortName, ObjID, ObjIsDynamic,
                                ObjSec, HasProperties);
            IF Result <> 0 THEN
                EXIT; {error or no such user}

            {if the user object has no properties,}
            { then no full name is defined for user}
            IF NOT HasProperties THEN
                EXIT;

            {Attempt to read the property value for IDENTIFICATION to }
            {return full name}
            Result := nwbReadPropertyValue(nwDefaultServer,
                                           ObjType,
                                           ShortName,
                                           'IDENTIFICATION',
                                           1,
                                           PropVal,
                                           ObjIsDynamic,
                                           HasProperties,
                                           MoreSegs);

            IF Result <> 0 THEN
                EXIT; {inadequate rights, no fullname defined, or error}

            GetUserFullName := Asc2Str(PropAsciiZ{, SizeOf(PropVal)-1});
        END;
    END;

    {-------------------------------------------------------}
    PROCEDURE GetInput(Msg : STRING; Title : STRING; TitleColor : BYTE;
                       Prompt         : STRING; Len : WORD;
                       VAR Out : STRING; VAR Escape : BOOLEAN);
    BEGIN
        Escape := NOT EditProc(0, Prompt, FALSE, TRUE, Len, Out);
    END;

    {-------------------------------------------------}

    PROCEDURE ReadField(X, Y : INTEGER; Len : INTEGER; ForceUpper : BOOLEAN;
                        Atr : BYTE; Prefill : STRING; VAR Dat : STRING; VAR Escape : BOOLEAN);
    VAR
        Xb, Yb, Lb     : BYTE;
    BEGIN
        Dat := Prefill;
        Escape := NOT EditProc(0, '', FALSE, FALSE, Len, Dat);
    END;

    {-------------------------------------------------}

    PROCEDURE ReadNumericField(X, Y : INTEGER; Len : INTEGER; Min, Max : WORD;
                               Atr            : BYTE; Prefill : WORD; VAR Dat : WORD;
                               VAR Escape     : BOOLEAN);
    VAR
        S              : STRING[6];
        I              : WORD;
    BEGIN
        Dat := Prefill;
        Escape := NOT EditProc(0, '', FALSE, TRUE, Len, S);
        IF NOT Escape THEN
            VAL(S, Dat, I);
    END;

    {------------------------------------------------------------------------}

    FUNCTION InitDialog(X1, Y1, X2, Y2 : BYTE;
                        Title          : STRING;
                        ColorSetP      : ColorSetProc;
                        VAR DB         : DialogBoxPtr) : WORD;
        {-Initialize dialog box}
    CONST
        WinOptions     = wBordered + wClear + wUserContents;
    BEGIN
        ColorSetP;
        NEW(DB, InitCustom(
            X1, Y1, X2, Y2,       {top left corner (X,Y)}
            NENColorSet,          {main color set}
            WinOptions,           {window options}
            NENDialogSet          {dialog box-specific colors}
            ));
        IF DB = NIL THEN BEGIN
            InitDialog := InitStatus;
            EXIT;
        END;
        CustomizeWindow(DB^, Title, LENGTH(Title));

        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        InitDialog := DB^.RawError;
    END;

    {------------------------------------------------------------------------}

    FUNCTION GetFileName(Mask : DirStr; VAR FileName : PathStr) : BOOLEAN;
    VAR
        FDB            : FileDialogPtr;
        Cmd, Status    : WORD;
        Finished       : BOOLEAN;
        FName          : PathStr;
        DragCommands   : DragProcessor;

        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                17, 6,            {top left corner (X,Y)}
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet,     {dialog box-specific colors}
                hProtected,       {help button: *protected*, hidden, or visible}
                Mask              {file mask}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            CustomizeWindow(FDB^, 'Select File', 49);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN
        GetFileName := FALSE;
        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        FileName := '';

        FileColors;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            DispErrorDeluxe('Error initializing dialog box: ', ErrorMessage(Status), TRUE, Iam);
            HALT(1);
        END;

        {initialize DragProcessor}
        DragCommands.Init(@DialogKeySet, DialogKeyMax);
        CustomizeCommandProcessor(DragCommands);
        FDB^.SetCommandProcessor(DragCommands);

        Finished := FALSE;
        FName := '';
        {    StuffKey(Tab);}
        REPEAT
            {process commands}
            FDB^.Process;

            Cmd := FDB^.GetLastCommand;
            CASE Cmd OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(FDB^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                    END;
                ccSelect :
                    BEGIN
                        FileName := FDB^.GetFileName;
                        Finished := TRUE;
                        GetFileName := TRUE;
                    END;
                ccUser40 :
                    KeyboardMove(FDB^);
                ccQuit, ccError :
                    Finished := TRUE;
            END;
        UNTIL Finished;

        FDB^.ERASE;
        DISPOSE(FDB, Done);
    END;

  {$F+}
    FUNCTION GetFileProc(MsgCode : WORD; Prompt : STRING;
                         ForceUp, TrimBlanks, Writing, MustExist : BOOLEAN;
                         MaxLen         : BYTE; DefExt : ExtStr;
                         VAR S          : STRING) : BOOLEAN;
    VAR
        LastCommand    : WORD;
    BEGIN
        GetFileProc := FALSE;
        IF ChildEditorPtr <> NIL THEN
            LastCommand := ChildEditorPtr^.GetLastCommand
        ELSE
            LastCommand := CommandWindowPtr(wStack.TopWindow)^.GetLastCommand;
        CASE LastCommand OF
            ccBlkWrite : PickSaveFile(S);
            ccBlkRead : PickGetFile(S);
            ELSE
                BEGIN
                    IF DefExt = '' THEN
                        DefExt := '*';
                    GetFileName('*.' + DefExt, S);
                END;
        END;
        IF S <> '' THEN
            GetFileProc := TRUE;
    END;

    {------------------------------------------------------------------------}

    PROCEDURE GetSearchOptions(VAR TE : TextEditor);
    VAR
        FDB            : DialogBoxPtr;
        DCP            : DragProcessorPtr;
        Status         : WORD;
        Pic            : CHAR;
        Y              : BYTE;
        Finished       : BOOLEAN;
        S, R           : STRING[30];
        Direction      : WORD;
        Scope          : WORD;
        Origin         : WORD;
        Confirm        : BOOLEAN;
        IgnoreCase     : BOOLEAN;
        Replace        : BOOLEAN;


        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                15, 5, 67, 19,
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            NEW(DCP, Init(@DialogKeySet, DialogKeyMax));
            CustomizeCommandProcessor(DCP^);
            FDB^.SetCommandProcessor(DCP^);
            IF Replace THEN
                CustomizeWindow(FDB^, ' Replace ', 10)
            ELSE
                CustomizeWindow(FDB^, ' Search ', 10);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN
        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        CASE TE.GetLastCommand OF
            ccSearch : Replace := FALSE;
            ccReplace : Replace := TRUE;
        END;

        Gray_Scheme;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            EXIT;
        END;

        Pic := 'X';

        Direction := 1;
        Scope := 1;
        Origin := 1;
        Confirm := TRUE;
        IgnoreCase := FALSE;

        {set field/control options}
        FDB^.dgFieldOptionsOn(efClearFirstChar);

        Y := 2;
        IF NOT Replace THEN Y := 3;
        FDB^.AddSimpleEditControl('&Text to find ', Y, 5, Pic,
                                  Y, 19,
                                  30, 30, 4, S);

        IF Replace THEN
            FDB^.AddSimpleEditControl('&New text     ', 4, 5, Pic,
                                      4, 19,
                                      30, 30, 4, R);

        FDB^.AddCheckBoxes('Options', 6, 5, 7, 5, 23, 2, 23, 13);
        FDB^.AddCheckBox('&Case sensitive', IgnoreCase);
        FDB^.AddCheckBox('&Prompt on replace', Confirm);

        FDB^.AddRadioButtons('Scope', 10, 5, 11, 5, 23, 2, 23, 13, Scope);
        FDB^.AddRadioButton('&Global', 1);
        FDB^.AddRadioButton('&Selected text', 2);

        FDB^.AddRadioButtons('Direction', 6, 31, 7, 31, 19, 2, 19, 13, Direction);
        FDB^.AddRadioButton('Forwar&d', 1);
        FDB^.AddRadioButton('&Backward', 2);

        FDB^.AddRadioButtons('Origin', 10, 31, 11, 31, 19, 2, 19, 13, Origin);
        FDB^.AddRadioButton('&From cursor', 1);
        FDB^.AddRadioButton('&Entire Scope', 2);

        FDB^.AddPushButton('&OK', 14, 5, 8, 0, ccSelect, TRUE);
        FDB^.AddPushButton(' &CANCEL ', 14, 15, 8, 0, ccQuit, FALSE);

        S := '';
        R := '';

        Finished := FALSE;
        WHILE NOT Finished DO BEGIN
            FDB^.Process;
            CASE FDB^.GetLastCommand OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(FDB^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                    END;
                ccSelect : BEGIN
                               Finished := TRUE;
                               IF S = '' THEN BEGIN
                                   TE.SetLastCommand(ccNone);
                               END
                               ELSE
                               BEGIN
                                   TE.teSearchSt := S;
                                   IF Replace THEN
                                       TE.teReplaceSt := R;
                                   S := '';
                                   IF Scope = 1 THEN S := S + 'L';
                                   IF NOT IgnoreCase THEN S := S + 'U';
                                   IF NOT Confirm THEN S := S + 'N';
                                   IF Direction = 2 THEN S := S + 'B';
                                   IF Origin = 2 THEN S := S + 'G';
                                   TE.teOptionSt := S;
                                   IF Replace THEN
                                       TE.teLastSearch := tescReplace
                                   ELSE
                                       TE.teLastSearch := tescSearch;
                                   TE.SetLastCommand(ccReSearch);
                               END;
                           END;
                ccQuit : BEGIN
                             Finished := TRUE;
                             S := '';
                             TE.SetLastCommand(ccNone);
                         END;
            END;
        END;

        DISPOSE(FDB, Done);
        DISPOSE(DCP, Done);

    END;

    {------------------------------------------------------------------------}

    PROCEDURE GetDirSpec(VAR DR : DirSpec);
    VAR
        FDB            : DialogBoxPtr;
        DCP            : DragProcessorPtr;
        Status         : WORD;
        Pic            : CHAR;
        Y              : BYTE;
        Finished       : BOOLEAN;


        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                15, 8, 67, 16,
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            NEW(DCP, Init(@DialogKeySet, DialogKeyMax));
            CustomizeCommandProcessor(DCP^);
            FDB^.SetCommandProcessor(DCP^);
            CustomizeWindow(FDB^, ' Dir Spec ', 10);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN
        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        Gray_Scheme;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            EXIT;
        END;

        Pic := 'X';

        {set field/control options}
        FDB^.dgFieldOptionsOn(efClearFirstChar);

        FDB^.AddSimpleEditControl('&Filespec ', 2, 5, Pic,
                                  2, 19,
                                  30, 30, 4, DR.Path);

        FDB^.AddRadioButtons('Sort by', 4, 4, 5, 4, 23, 2, 23, 13, DR.Sort);
        FDB^.AddRadioButton('&Name', 1);
        FDB^.AddRadioButton('&Time', 2);
        FDB^.AddRadioButton('&Size', 3);

        FDB^.AddCheckBoxes('Direction', 4, 29, 5, 29, 23, 2, 23, 13);
        FDB^.AddCheckBox('&Forward', DR.UpDown);

        FDB^.AddPushButton('&OK', 7, 29, 8, 0, ccSelect, TRUE);
        FDB^.AddPushButton(' &CANCEL ', 7, 39, 8, 0, ccQuit, FALSE);

        Finished := FALSE;
        WHILE NOT Finished DO BEGIN
            FDB^.Process;
            CASE FDB^.GetLastCommand OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(FDB^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                    END;
                ccSelect : BEGIN
                               Finished := TRUE;
                               DR.Path := StUpCase(DR.Path);
                           END;
                ccQuit : BEGIN
                             Finished := TRUE;
                             DR.Path := '';
                         END;
            END;
        END;

        DISPOSE(FDB, Done);
        DISPOSE(DCP, Done);
    END;

    {------------------------------------------------------------------------}

    PROCEDURE GetSerialParameters(VAR SP : SerialPortRec);

    TYPE
        DBSerial       = RECORD
                             Baud           : BYTE;
                             Data           : BYTE;
                             Parity         : BYTE;
                             Stop           : BYTE;
                             XonXoff        : BYTE;
                             CharDelay      : STRING[3];
                         END;

    VAR
        FDB            : DialogBoxPtr;
        DCP            : DragProcessorPtr;
        Status         : WORD;
        Pic            : CHAR;
        Y              : BYTE;
        I              : INTEGER;
        Finished       : BOOLEAN;
        S, R           : STRING[30];
        Direction      : WORD;
        Scope          : WORD;
        Origin         : WORD;
        Confirm        : BOOLEAN;
        IgnoreCase     : BOOLEAN;
        Replace        : BOOLEAN;
        IP             : DBSerial;


        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                21, 5, 52, 21,
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            NEW(DCP, Init(@DialogKeySet, DialogKeyMax));
            CustomizeCommandProcessor(DCP^);
            FDB^.SetCommandProcessor(DCP^);
            InitDialogBox := FDB^.RawError;
        END;

    BEGIN
        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        Debug_Scheme;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            EXIT;
        END;

        CustomizeWindow(FDB^, 'Serial Port', 15);

        Pic := 'X';

        {set field/control options}
        FDB^.dgFieldOptionsOn(efClearFirstChar);

        CASE SP.Baud OF
            300 : IP.Baud := 1;
            1200 : IP.Baud := 2;
            2400 : IP.Baud := 3;
            4800 : IP.Baud := 4;
            9600 : IP.Baud := 5;
            19200 : IP.Baud := 6;
        END;
        CASE SP.Parity OF
            'N' : IP.Parity := 1;
            'O' : IP.Parity := 2;
            'E' : IP.Parity := 3;
            'M' : IP.Parity := 4;
            'S' : IP.Parity := 5;
        END;
        CASE SP.XonXoff OF
            TRUE : IP.XonXoff := 1;
            FALSE : IP.XonXoff := 2;
        END;
        IP.Data := SP.Data;
        IP.Stop := SP.Stop;
        IP.CharDelay := Long2Str(SP.CharDelay);


        WITH FDB^ DO BEGIN
            AddRadioButtons('&Baud Rate', 2, 3, 3, 2, 23, 4, 10, 13, IP.Baud);
            AddRadioButtonAt('38.4', 1, 1, 1);
            AddRadioButtonAt('1200', 1, 11, 2);
            AddRadioButtonAt('2400', 1, 21, 3);
            AddRadioButtonAt('4800', 2, 1, 4);
            AddRadioButtonAt('9600', 2, 11, 5);
            AddRadioButtonAt('19.2K', 2, 21, 6);

            AddRadioButtons('&Data bits', 6, 3, 7, 2, 23, 2, 7, 14, IP.Data);
            AddRadioButtonAt('5', 1, 1, 5);
            AddRadioButtonAt('6', 1, 8, 6);
            AddRadioButtonAt('7', 1, 15, 7);
            AddRadioButtonAt('8', 1, 22, 8);

            AddRadioButtons('&Parity', 9, 3, 10, 2, 10, 5, 10, 15, IP.Parity);
            AddRadioButton('None', 1);
            AddRadioButton('Odd', 2);
            AddRadioButton('Even', 3);
            AddRadioButton('Mark', 4);
            AddRadioButton('Space', 5);

            AddRadioButtons('&Stop bits', 9, 17, 10, 16, 14, 1, 7, 16, IP.Stop);
            AddRadioButtonAt('1', 1, 1, 1);
            AddRadioButtonAt('2', 1, 8, 2);

            AddEditControl('&CDelay: ', 11, 17, '999',
                           11, 29, 3, 16, IP.CharDelay);

            AddRadioButtons('&Flow Control', 12, 17, 13, 16, 14, 1, 13, 17, IP.XonXoff);
            AddRadioButton('Xon/Xoff', 1);
            AddRadioButton('None', 2);

            AddPushButton('&OK', 16, 3, 8, 0, ccSelect, TRUE);
            AddPushButton(' &CANCEL ', 16, 17, 8, 0, ccQuit, FALSE);
        END;

        Finished := FALSE;
        WHILE NOT Finished DO BEGIN
            FDB^.Process;
            CASE FDB^.GetLastCommand OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(FDB^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                    END;
                ccSelect : BEGIN
                               Finished := TRUE;
                               SP.Baud := BaudRates[IP.Baud];
                               SP.Data := IP.Data;
                               SP.Stop := IP.Stop;
                               SP.Parity := Parities[IP.Parity];
                               SP.XonXoff := IP.XonXoff = 1;
                               VAL(IP.CharDelay, SP.CharDelay, I);
                           END;
                ccQuit : BEGIN
                             Finished := TRUE;
                         END;
            END;
        END;

        DISPOSE(FDB, Done);
        DISPOSE(DCP, Done);

    END;

    {------------------------------------------------------------------------}

    FUNCTION EditProc(MsgCode        : WORD;
                      Prompt         : STRING;
                      ForceUp        : BOOLEAN;
                      TrimBlanks     : BOOLEAN;
                      MaxLen         : BYTE;
                      VAR S          : STRING) : BOOLEAN;
    VAR
        FDB            : DialogBoxPtr;
        DCP            : DragProcessorPtr;
        Status         : WORD;
        Pic            : CHAR;
        Finished       : BOOLEAN;

        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                {11, 9, 11+MaxLen+2, 15,} {top left corner (X,Y)}
                22, 10, 63, 16,
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            NEW(DCP, Init(@DialogKeySet, DialogKeyMax));
            CustomizeCommandProcessor(DCP^);
            FDB^.SetCommandProcessor(DCP^);

            CustomizeWindow(FDB^, ' Enter ', 10);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN

        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        Gray_Scheme;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            EXIT;
        END;

        Pic := 'X';
        IF ForceUp THEN Pic := '!';

        {set field/control options}
        FDB^.dgFieldOptionsOn(efClearFirstChar);
        FDB^.dgFieldOptionsOff(efTrimBlanks);

        FDB^.AddSimpleEditControl(Prompt, 3, 5, Pic,
                                  3, 6 + LENGTH(Prompt),
                                  30 - LENGTH(Prompt), MaxLen, 4, S);

        FDB^.AddPushButton('&OK', 5, 5, 8, 0, ccSelect, TRUE);
        FDB^.AddPushButton(' &CANCEL ', 5, 16, 8, 0, ccQuit, FALSE);


        Finished := FALSE;
        WHILE NOT Finished DO BEGIN
            FDB^.Process;
            CASE FDB^.GetLastCommand OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(FDB^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                    END;
                ccSelect : BEGIN
                               EditProc := TRUE;
                               Finished := TRUE;
                           END;
                ccQuit : BEGIN
                             EditProc := FALSE;
                             Finished := TRUE;
                             S := '';
                         END;
                ELSE
                    EditProc := TRUE;
            END;
        END;

        DISPOSE(FDB, Done);
        DISPOSE(DCP, Done);
        IF TrimBlanks THEN
            S := Trim(S);

    END;

    {------------------------------------------------------------------------}

    FUNCTION FirstCharUpperEditProc(MsgCode        : WORD;
                                    Prompt         : STRING;
                                    TrimBlanks     : BOOLEAN;
                                    MaxLen         : BYTE;
                                    VAR S          : STRING) : BOOLEAN;
    VAR
        FDB            : DialogBoxPtr;
        DCP            : DragProcessorPtr;
        Status         : WORD;
        Pic            : STRING[2];
        Finished       : BOOLEAN;

        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                {11, 9, 11+MaxLen+2, 15,} {top left corner (X,Y)}
                22, 10, 63, 16,
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            NEW(DCP, Init(@DialogKeySet, DialogKeyMax));
            CustomizeCommandProcessor(DCP^);

            CustomizeWindow(FDB^, ' Enter ', 10);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN

        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        Gray_Scheme;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            EXIT;
        END;

        Pic := '!L';

        {set field/control options}
        FDB^.dgFieldOptionsOn(efClearFirstChar);

        FDB^.AddEditControl(Prompt, 3, 5, PadCh(Pic, 'L', MaxLen),
                            3, 6 + LENGTH(Prompt),
                            30 - LENGTH(Prompt), 4, S);

        FDB^.AddPushButton('&OK', 5, 5, 8, 0, ccSelect, TRUE);
        FDB^.AddPushButton(' &CANCEL ', 5, 16, 8, 0, ccQuit, FALSE);


        FDB^.Process;
        Finished := FALSE;
        WHILE NOT Finished DO
            CASE FDB^.GetLastCommand OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(FDB^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                    END;
                ccSelect : BEGIN
                               FirstCharUpperEditProc := TRUE;
                               Finished := TRUE;
                           END;
                ccQuit : BEGIN
                             FirstCharUpperEditProc := FALSE;
                             Finished := TRUE;
                             S := '';
                         END;
                ELSE
                    FirstCharUpperEditProc := TRUE;
            END;

        DISPOSE(FDB, Done);
        DISPOSE(DCP, Done);
        IF TrimBlanks THEN
            S := Trim(S);

    END;

    {------------------------------------------------------------------------}

    FUNCTION CustomEditProc(MsgCode        : WORD;
                            Prompt         : STRING;
                            TrimBlanks     : BOOLEAN;
                            MaxLen         : BYTE;
                            Picture        : STRING;
                            VAR S          : STRING) : BOOLEAN;
    VAR
        FDB            : DialogBoxPtr;
        DCP            : DragProcessorPtr;
        Status         : WORD;
        Pic            : STRING[2];
        Finished       : BOOLEAN;

        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                {11, 9, 11+MaxLen+2, 15,} {top left corner (X,Y)}
                22, 10, 63, 16,
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            NEW(DCP, Init(@DialogKeySet, DialogKeyMax));
            CustomizeCommandProcessor(DCP^);

            CustomizeWindow(FDB^, ' Enter ', 10);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN

        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        Gray_Scheme;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            EXIT;
        END;

        IF LENGTH(Picture) < MaxLen THEN
            Picture := PadCh(Picture, Picture[LENGTH(Picture)], MaxLen);

        {set field/control options}
        FDB^.dgFieldOptionsOn(efClearFirstChar);

        FDB^.AddEditControl(Prompt, 3, 5, Picture,
                            3, 6 + LENGTH(Prompt),
                            30 - LENGTH(Prompt), 4, S);

        FDB^.AddPushButton('&OK', 5, 5, 8, 0, ccSelect, TRUE);
        FDB^.AddPushButton(' &CANCEL ', 5, 16, 8, 0, ccQuit, FALSE);


        FDB^.Process;
        Finished := FALSE;
        WHILE NOT Finished DO
            CASE FDB^.GetLastCommand OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(FDB^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                    END;
                ccSelect : BEGIN
                               CustomEditProc := TRUE;
                               Finished := TRUE;
                           END;
                ccQuit : BEGIN
                             CustomEditProc := FALSE;
                             Finished := TRUE;
                             S := '';
                         END;
                ELSE
                    CustomEditProc := TRUE;
            END;

        DISPOSE(FDB, Done);
        DISPOSE(DCP, Done);
        IF TrimBlanks THEN
            S := Trim(S);

    END;

    {------------------------------------------------------------------------}

    FUNCTION YesOrNo(MsgCode : WORD; Prompt : STRING;
                     Default : BYTE; QuitAndAll : BOOLEAN) : BYTE;
    VAR
        FDB            : DialogBoxPtr;
        Status         : WORD;

        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                21, 9, 59, 15,    {top left corner (X,Y)}
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            CustomizeWindow(FDB^, 'Select ', 38);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN
        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        FileColors;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            HALT(1);
        END;

        DialogCommands.Init(@DialogKeySet, DialogKeyMax);
        CustomizeCommandProcessor(DialogCommands);

        FDB^.AddCenteredTextField(Prompt, 2);

        FDB^.AddPushButton('&Yes', 4, 5, 8, 0, 1, TRUE);
        FDB^.AddPushButton('&No ', 4, 15, 8, 0, 2, FALSE);
        FDB^.AddPushButton('&Quit ', 4, 25, 8, 0, 4, FALSE);
        IF QuitAndAll THEN
            FDB^.AddPushButton('&All ', 6, 15, 8, 0, 3, FALSE);

        FDB^.Process;
        CASE FDB^.GetLastCommand OF
            1 : YesOrNo := teYES;
            2 : YesOrNo := teNO;
            3 : YesOrNo := teALL;
            4 : YesOrNo := teQUIT;
        END;
        DISPOSE(FDB, Done);

    END;

    {------------------------------------------------------------------------}

    PROCEDURE ErrorProc(UnitCode : BYTE; VAR ErrorCode : WORD; ErrorMsg : STRING);
    VAR
        FDB            : DialogBoxPtr;
        Status         : WORD;

        FUNCTION InitDialogBox : WORD;
            {-Initialize dialog box}
        CONST
            WinOptions     = wBordered + wClear + wUserContents;
        BEGIN
            NEW(FDB, InitCustom(
                26, 9, 54, 13,    {top left corner (X,Y)}
                NENColorSet,      {main color set}
                WinOptions,       {window options}
                NENDialogSet      {dialog box-specific colors}
                ));
            IF FDB = NIL THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;
            CustomizeWindow(FDB^, ' Info ', 38);

            InitDialogBox := FDB^.RawError;
        END;

    BEGIN
        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;

        ErrorColors;

        {initialize dialog box}
        Status := InitDialogBox;
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing dialog box: ', Status);
            HALT(1);
        END;

        DialogCommands.Init(@DialogKeySet, DialogKeyMax);
        CustomizeCommandProcessor(DialogCommands);

        FDB^.AddCenteredTextField(ErrorMsg+' '+Long2Str(ErrorCode), 2);

        FDB^.AddPushButton('&OK ', 4, 12, 8, 0, ccQuit, TRUE);

        FDB^.Process;

        DISPOSE(FDB, Done);

    END;

    {-------------------------------------------------------}

    PROCEDURE Message(Msg : STRING);
    VAR
        Ch             : CHAR;
        W              : WORD;
        EscFlag, FuncFlag : BOOLEAN;
    BEGIN
        ErrorProc(0, W, Msg);
    END;

    PROCEDURE SaveGetMoveProc(P : PickListPtr);
        {-Called each time the cursor is moved in the directory list}
    BEGIN
        WITH DirListPtr(P)^ DO BEGIN
            IF SGFile <> GetLastChoiceString THEN BEGIN
                SGFile := GetLastChoiceString;
                SaveGet^.UpdateContents;
            END;
        END
    END;

    PROCEDURE NoExtFormat(VAR X : DirRec; VAR PkCat : BYTE;
                          VAR S : STRING; D : DirListPtr);
    BEGIN
        S := Pad(JustName(X.Name), 8);
    END;

    PROCEDURE InitSaveGetDialogBox(Title : STRING; ProtFile : BOOLEAN);
    BEGIN
        Gray_Scheme;
        WinOptions := wBordered + wClear + wUserContents;
        NEW(SaveGet, InitCustom(
            30, 9, 50, 18,        {top left corner (X,Y)}
            NENColorSet,          {main color set}
            WinOptions,           {window options}
            NENDialogSet          {dialog box-specific colors}
            ));
        IF SaveGet = NIL THEN BEGIN
            EXIT;
        END;
        NEW(DCP, Init(@DialogKeySet, DialogKeyMax));

        CustomizeCommandProcessor(DCP^);
        SaveGet^.SetCommandProcessor(DCP^);

        CustomizeWindow(SaveGet^, Title, 10);

        NENColorSet.TextColor := WhiteOnCyan;
        NENColorSet.FrameColor := BlackOnCyan;
        NENColorSet.ScrollBarColor := WhiteOnCyan;
        NENColorSet.SliderColor := WhiteOnCyan;
        NENColorSet.HotSpotColor := LtRedOnCyan;

        NEW(SaveGetDir, InitCustom(5, 5, 12, 9, NENColorSet,
                                   wClear OR wUserContents OR wNoCoversBuffer OR
                                   wBordered,
                                   8192, PickVertical, SingleFile));
        NEW(PCP, Init(@PickKeySet, PickKeyMax));
        CustomizeCommandProcessor(PCP^);
        SaveGetDir^.SetCommandProcessor(PCP^);

        AddScrollBars(SaveGetDir^, FALSE);
        WITH SaveGetDir^ DO BEGIN
            wFrame.SetFrameType(SglWindowFrame);
            SetUserFormat(8, NoExtFormat);
            diOptionsOn(diExitIfOne);
            pkOptionsOn(pkProcessZero);
            SetMoveProc(SaveGetMoveProc);
            SetSortOrder(SortName);
            SetMask(NEN^.PrivateDir + '\' + GetUserName + '\PRIVATE\*.SG', AnyFile - Directory);
            PreLoadDirList;
        END;

        { Add all controls }
        WITH SaveGet^ DO BEGIN
            dgFieldOptionsOff(efProtected);
            IF ProtFile THEN
                dgFieldOptionsOn(efProtected);
            AddSimpleEditControl('&File:',
                                 2, 2,
                                 '!',
                                 2, 8,
                                 8, 8, 1,
                                 SGFile);
            dgFieldOptionsOff(efProtected);
            AddWindowControl('&Dir:', 3, 2, 4, 1, 10, ccSelect, SaveGetDir^);
            AddPushButton('&OK', 5, 12, 8, 6, ccDone, FALSE);
            AddPushButton('&Cancel', 7, 12, 8, 7, ccQuit, FALSE);
            AddPushButton('&Delete', 9, 12, 8, 8, ccUser5, FALSE);
        END;
    END;

    PROCEDURE ProcessSaveGet(VAR Ffile : PathStr);
    VAR 
        Quit           : BOOLEAN;
    BEGIN
        IF SaveGet = NIL THEN EXIT;
        WITH SaveGet^ DO BEGIN
            Quit := FALSE;
            Ffile := '';
            SGFile := ForceExtension(SGFile, '');
            DELETE(SGFile, LENGTH(SGFile), 1);

            WHILE NOT Quit DO BEGIN
                Process;
                CASE GetLastCommand OF
                    ccMouseDown,
                    ccMouseSel :
                        {did user click on the hot spot for closing?}
                        IF HandleMousePress(SaveGet^) = hsRegion3 THEN BEGIN
                            ClearMouseEvents;
                            Quit := TRUE;
                        END;
                    ccSelect : BEGIN
                                   CASE GetHelpIndex(GetCurrentID) OF
                                       1 : Ffile := SGFile;
                                       10 : BEGIN
                                                SGFile := Trim(SaveGetDir^.GetSelectedPath);
                                            END;
                                   END;
                                   Quit := TRUE;
                               END;
                    ccQuit : BEGIN
                                 SGFile := '';
                                 Quit := TRUE;
                             END;
                    ccDone : BEGIN
                                 Quit := TRUE;
                             END;
                END;
                IF SGFile <> '' THEN
                    Ffile := NEN^.PrivateDir + '\' + GetUserName + '\PRIVATE\' +
                             ForceExtension(Trim(StUpCase(JustFileName(SGFile))), 'SG')
                ELSE
                    Ffile := '';
            END;
        END;
    END;

    PROCEDURE CloseSaveGet;
    BEGIN
        SaveGet^.ERASE;
        SaveGet^.RemoveChild(SaveGetDir);
        DISPOSE(SaveGetDir, Done);
        DISPOSE(SaveGet, Done);
        DISPOSE(DCP, Done);
        DISPOSE(PCP, Done);
    END;

    PROCEDURE PickSaveFile(VAR SFile : PathStr);
    BEGIN
        InitSaveGetDialogBox('Save File', FALSE);
        ProcessSaveGet(SFile);
        CloseSaveGet;
    END;

    PROCEDURE PickGetFile(VAR SFile : PathStr);
    BEGIN
        InitSaveGetDialogBox('Get File', TRUE);
        ProcessSaveGet(SFile);
        CloseSaveGet;
    END;

    (****************************************************************************)

    FUNCTION InitDialogBox(VAR EsColors   : ColorSet;
                           VAR dColors    : DialogColorSet;
                           VAR DB1        : DialogBox;
                           VAR Msg        : MsgArray;
                           HT             : HelpType;
                           HelpInd        : INTEGER) : WORD;
        {-Initialize message dialog box}
    CONST
        WinOptions     = wBordered + wClear;
    VAR
        I,
        X,
        Y,
        BoxHeight,
        ButtonLine,
        MsgWidth       : INTEGER;
    BEGIN
        MsgWidth := 0;
        BoxHeight := 0;
        FOR I := 1 TO MSGSIZE DO BEGIN
            IF LENGTH(Msg[I]) > MsgWidth THEN
                MsgWidth := LENGTH(Msg[I]);
            IF LENGTH(Msg[I]) > 0 THEN
                BoxHeight := I;
        END;
        IF BoxHeight = 0 THEN
            EXIT;
        INC(BoxHeight, 4);
        INC(MsgWidth, 6);
        IF MsgWidth < 28 THEN
            MsgWidth := 28;
        ButtonLine := BoxHeight - 2;
        X := (ScreenWidth - MsgWidth - 2) DIV 2;
        Y := (ScreenHeight - BoxHeight) DIV 2;
        WITH DB1 DO BEGIN
            {instantiate dialog box}
            IF NOT InitCustom(X + 2,
                              Y + 2,
                              X + MsgWidth + 3,
                              Y + BoxHeight,
                              EsColors,
                              WinOptions,
                              dColors) THEN BEGIN
                InitDialogBox := InitStatus;
                EXIT;
            END;

            WITH wFrame, EsColors DO BEGIN
      {$IFDEF UseShadows}
                AddShadow(shBR, shSeeThru);
      {$ENDIF}

                {add hot spot for closing the window}
                AddCustomHeader('[ ]', frTL, + 2, 0, HeaderColor, HeaderMono);
                AddCustomHeader('þ', frTL, + 3, 0, $7A, HeaderMono);
                AddHotRegion(frTL, hsRegion3, + 3, 0, 1, 1);

      {$IFDEF UsingDrag}
                    {add hot spot for moving the window}
                    AddHotBar(frTT, MoveHotCode);
      {$ENDIF}
            END;

            CustomizeCommandProcessor(DialogCommands);
            DialogCommands.AddCommand(ccQuit, 1, OpKey.F1, 0);

            EnableExplosions(8);

            FOR I := 1 TO MSGSIZE DO
                AddCenteredTextField(Msg[I], I);

            dgFieldOptionsOn(efAllowEscape);
            dgSecFieldOptionsOn(sefSwitchCommands);

            CASE HT OF
                hVisible :
                    BEGIN
                        {                 prompt           pr  pc  cr  cc  helpindx    cmd    var}
                        AddPushButton('&Ok', ButtonLine, 3, 6, HelpInd, ccDone, TRUE);
                        AddPushButton('&Cancel', ButtonLine, MsgWidth DIV 2, 6, HelpInd, ccQuit, FALSE);
                        AddPushButton('&Help', ButtonLine, MsgWidth - 6, 6, HelpInd, ccHelp, FALSE);
                    END;
                hHidden :
                    BEGIN
                        {                 prompt           pr  pc  cr  cc  helpindx    cmd    var}
                        AddPushButton('&Ok', ButtonLine, 3, 6, HelpInd, ccDone, TRUE);
                        AddPushButton('&Cancel', ButtonLine, MsgWidth - 6, 6, HelpInd, ccQuit, FALSE);
                    END;
                hProtected :
                    BEGIN
                        {                 prompt           pr  pc  cr  cc  helpindx    cmd    var}
                        AddPushButton('&Ok', ButtonLine, 3, 6, HelpInd, ccDone, TRUE);
                        AddPushButton('&Cancel', ButtonLine, MsgWidth DIV 2, 6, HelpInd, ccQuit, FALSE);
                        dgFieldOptionsOn(efProtected);
                        AddPushButton('&Help', ButtonLine, MsgWidth - 6, 6, HelpInd, ccHelp, FALSE);
                        dgFieldOptionsOff(efHidden);
                    END;
            END;

            SetNextField(idOk);

            InitDialogBox := RawError;
        END;
    END;

    (****************************************************************************)


    FUNCTION MessageBox(Header         : STRING;
                        VAR Msg        : MsgArray;
                        HelpInd        : INTEGER;
                        VAR EsColors   : ColorSet;
                        VAR dColors    : DialogColorSet) : WORD;
        {- Display a dialog style message box and wait for user button press }
    VAR
        DB             : DialogBox;
        Cmd,
        Status         : WORD;
        KeyCap,
        Finished       : BOOLEAN;
    BEGIN
        {$IFDEF NoHelp}
        Status := InitDialogBox(EsColors,
                                dColors,
                                DB,
                                Msg,
                                hHidden,
                                HelpInd);
        {$ELSE}
        Status := InitDialogBox(EsColors,
                                dColors,
                                DB,
                                Msg,
                                hVisible,
                                HelpInd);
        {$ENDIF}
        DB.wFrame.AddHeader(Header, heTC);
        IF Status <> 0 THEN BEGIN
            MessageBox := ccError;
            EXIT;
        END;
        {$IFDEF UseDragAnyway}
            {initialize DragProcessor}
            DragCommands.Init(@DialogKeySet, DialogKeyMax);
            DB.SetCommandProcessor(DragCommands);
        {$ELSE}
        {$IFNDEF UsingDrag}
            {$IFDEF UseMouse}
        IF MouseInstalled THEN
            WITH EsColors DO BEGIN
                {activate mouse cursor}
                SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) SHL 8) +
                                BYTE(MouseChar));
                ShowMouse;

                {enable mouse support}
                DialogCommands.cpOptionsOn(cpEnableMouse);
            END;
            {$ENDIF}
        {$ENDIF}
        {$ENDIF}
        CustomizeCommandProcessor(DialogCommands);
        KeyCap := KeyCapture;
        KeyCapture := TRUE;
        IF FKeysUp THEN BEGIN
            ClearFKeys;
            SetTag(1, UnShift, 'EXIT');
        END;
        REPEAT
            {process commands}
            DB.Process;
            Cmd := DB.GetLastCommand;
            CASE Cmd OF
            {$IFDEF UseMouse}
                {$IFDEF UsingDrag}
            ccMouseDown,
            ccMouseSel :
                {did user click on the hot spot for closing?}
                IF HandleMousePress(DB) = hsRegion3 THEN BEGIN
                    ClearMouseEvents;
                    Finished := TRUE;
                    Cmd := ccQuit;
                END;
                {$ELSE}
                ccMouseSel : BEGIN
                                 Finished := TRUE;
                                 Cmd := ccQuit;
                             END;
                {$ENDIF}
            {$ENDIF}
                ccDone,
                ccQuit,
                ccError :
                    Finished := TRUE;
            END;
        UNTIL Finished;

        DB.Done;
        KeyCapture := KeyCap;
        MessageBox := Cmd;
    END;

    (**************************************************************************)

    FUNCTION Timer : LONGINT;
        {Returns number of centiseconds (hundredths) since midnight }
    CONST
        HPH            : LONGINT = 360000;
        HPM            : LONGINT = 6000;
        HPS            : LONGINT = 100;
    VAR
        H,
        M,
        S,
        S100           : WORD;
        T              : LONGINT;
    BEGIN
        GetTime(H, M, S, S100);
        T := (H * HPH) + (M * HPM) + (S * HPS) + S100;
        Timer := T;
    END;

    (******************************************************************************)

    {selectable FlashDelay param}
    CONSTRUCTOR CylonObj.InitCFD(Header : STRING; CWidth, CFD : INTEGER);
    BEGIN
        IF NOT Init(Header, CWidth) THEN
            FAIL;
        CylonFlashDelay := CFD;
    END;

    (******************************************************************************)

    PROCEDURE CylonObj.Sleep;
    BEGIN
        IF Parent <> NIL THEN
            Parent^.MarkCurrent;
    END;

    (******************************************************************************)

    PROCEDURE CylonObj.MarkCurrent;
    BEGIN
        Parent := wStack.TopWindow;
        INHERITED MarkCurrent;
    END;

    (******************************************************************************)

    PROCEDURE CylonObj.MarkNotCurrent;
    BEGIN
        INHERITED MarkNotCurrent;
    END;

    (******************************************************************************)

    CONSTRUCTOR CylonObj.Init(Header : STRING; CWidth : INTEGER);
        {- Initialize moving dot status window object}
    VAR
        WinOpts        : LONGINT;
        X1,
        Y1,
        X2,
        Y2             : INTEGER;
        EsColors       : ColorSet;
    BEGIN
        Parent := NIL;

        TopHead := Header;
        BotHead := '';

        GetCScheme(Yellow_Scheme, EsColors);
        KeyCap := KeyCapture;
        CylonFlashDelay := 150; {1.5 seconds}
        KeyCapture := FALSE;
        IsDrawn := FALSE;
        LastTime := Timer;
        InitTime := LastTime;
        {make sure there is enough room for the header}
        IF CWidth < (LENGTH(Header) + 2) THEN
            CWidth := LENGTH(Header) + 2;

        NumDots := CWidth + 1;
        Count := 0;
        WinOpts := wBordered + wClear + wSaveContents;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - CWidth) DIV 2;
        X2 := X1 + CWidth;
        Y1 := ScreenHeight DIV 2;
        Y2 := Y1;                 {one line high box}

        IF NOT InitCustom(X1, Y1, X2, Y2, EsColors, WinOpts) THEN BEGIN
            KeyCapture := KeyCap;
            FAIL;
        END;

        wFrame.AddHeader(Header, heTC);
        wFrame.AddShadow(shBR, shSeeThru);
        EnableExplosions(8);
    END;

    (****************************************************************************)

    CONSTRUCTOR CylonObj.InitDeluxe(TopHeader, BotHeader : STRING);
        {- Initialize moving dot status window object}
    VAR
        WinOpts        : LONGINT;
        X1,
        Y1,
        X2,
        Y2             : INTEGER;
        EsColors       : ColorSet;
        CWidth          : BYTE;
    BEGIN
        GetCScheme(Yellow_Scheme, EsColors);

        TopHead := TopHeader;
        BotHead := BotHeader;

        KeyCap := KeyCapture;
        KeyCapture := FALSE;
        IsDrawn := FALSE;
        LastTime := Timer;
        InitTime := LastTime;
        CWidth := LENGTH(BotHeader);
        IF CWidth < 10 THEN
            CWidth := 10;
        {make sure there is enough room for the header}
        IF CWidth < (LENGTH(TopHeader) + 2) THEN
            CWidth := LENGTH(TopHeader) + 2;

        NumDots := CWidth + 1;
        Count := 0;
        WinOpts := wBordered + wClear + wSaveContents;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - CWidth) DIV 2;
        X2 := X1 + CWidth;
        Y1 := ScreenHeight DIV 2;
        Y2 := Y1;                 {one line high box}

        IF NOT InitCustom(X1, Y1, X2, Y2, EsColors, WinOpts) THEN BEGIN
            KeyCapture := KeyCap;
            FAIL;
        END;

        wFrame.AddHeader(TopHeader, heTC);
        IF LENGTH(BotHeader) > 0 THEN
            wFrame.AddHeader(BotHeader, heBC);
        wFrame.AddShadow(shBR, shSeeThru);
        EnableExplosions(8);
    END;

    (****************************************************************************)

    PROCEDURE CylonObj.ChangeTopHeader(Header:STRING);
    VAR
        Redraw : BOOLEAN;
        X1,
        X2,
        Y1,
        Y2,
        CWidth : BYTE;
    BEGIN
        IsDrawn := FALSE;
        TopHead := Header;

        CWidth := LENGTH(BotHead);
        IF CWidth < 10 THEN
            CWidth := 10;
        {make sure there is enough room for the header}
        IF CWidth < (LENGTH(TopHead) + 2) THEN
            CWidth := LENGTH(TopHead) + 2;

        NumDots := CWidth + 1;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - CWidth) DIV 2;
        X2 := X1 + CWidth;
        Y1 := ScreenHeight DIV 2;
        Y2 := Y1;                 {one line high box}

        AdjustWindow(X1, Y1, X2, Y2);


        wFrame.ChangeHeaderString(0, Header, Redraw);
        {IF Redraw THEN
            wFrame.UpDateFrame
        ELSE
            wFrame.DrawHeader(0);}
    END;

    (****************************************************************************)

    PROCEDURE CylonObj.ChangeBotHeader(Header:STRING);
    VAR
        Redraw : BOOLEAN;
        X1,
        X2,
        Y1,
        Y2,
        CWidth : BYTE;
    BEGIN
        IsDrawn := FALSE;
        IF wFrame.GetLastHeaderIndex = 0 THEN BEGIN
            wFrame.AddHeader(Header, heBC);
            EXIT;
        END;
        BotHead := Header;
        CWidth := LENGTH(TopHead);
        IF CWidth < 10 THEN
            CWidth := 10;
        {make sure there is enough room for the header}
        IF CWidth < (LENGTH(BotHead) + 2) THEN
            CWidth := LENGTH(BotHead) + 2;

        NumDots := CWidth + 1;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - CWidth) DIV 2;
        X2 := X1 + CWidth;
        Y1 := ScreenHeight DIV 2;
        Y2 := Y1;                 {one line high box}

        AdjustWindow(X1, Y1, X2, Y2);

        wFrame.ChangeHeaderString(1, Header, Redraw);
        {IF Redraw THEN
            wFrame.UpDateFrame
        ELSE
            wFrame.DrawHeader(1);}
    END;

    (****************************************************************************)

    FUNCTION CylonObj.GetTopHeader : STRING;
    BEGIN
        GetTopHeader := TopHead;
    END;

    (****************************************************************************)

    FUNCTION CylonObj.GetBotHeader : STRING;
    BEGIN
        GetBotHeader := BotHead;
    END;

    (****************************************************************************)

    {- Draw a moving dot status window}
    PROCEDURE CylonObj.Draw;
    BEGIN
        HideMouse;
        IF (CylonFlashDelay = 0) OR
           (ABS(Timer - InitTime) > CylonFlashDelay) THEN BEGIN
            INHERITED Draw;
            IsDrawn := TRUE;
            SetCursor(cuHidden);
        END;
    END;

    (****************************************************************************)

    {- move the dot in the moving dot status window.  Also check for user keypress}
    {  of ESC key.  Return FALSE if ESC pressed}
    FUNCTION CylonObj.Update : BOOLEAN;
    VAR
        K              : CHAR;
        Strg           : STRING;
    BEGIN
        Update := TRUE;

        IF NOT IsDrawn THEN
            Draw;

        IF NENFlag THEN
            UpTime
        ELSE
            UpdateWtime(FALSE);

        IF IsDrawn AND (ABS(Timer - LastTime) > 50) THEN BEGIN
            LastTime := Timer;
            INC(Count);           {cylon}
            Count := (Count MOD (NumDots+1));
            FILLCHAR(Strg[1], NumDots, #7);
            Strg[Count] := #42;
            Strg[Count+1] := #15;
            Strg[Count+2] := #42;
            Strg[0] := CHAR(NumDots);

            wFastText(Strg, 1, 1);
            IF KbdKeyPressed THEN BEGIN
                K := ReadKey;
                IF K = #27 THEN
                    Update := FALSE;
            END;
        END;
    END;

    (****************************************************************************)

    DESTRUCTOR CylonObj.Done;
        {- Kill the moving dot status window}
    BEGIN
        IF IsDrawn THEN
            ERASE;
        INHERITED Done;
        ShowMouse;
        KeyCapture := KeyCap;
    END;

    (****************************************************************************)

    CONSTRUCTOR KTellUser.Init(Msg : STRING);
        {- Initialize time delayed message window object}
    VAR
        StartTime,
        WinOpts        : LONGINT;
        Width,
        X1,
        Y1,
        X2,
        Y2             : INTEGER;
        EsColors       : ColorSet;
    BEGIN
        GetCScheme(BrightYellow_Scheme, EsColors);
        Width := 34;
        {make sure there is enough room for the header}
        IF Width < (LENGTH(Msg) + 2) THEN
            Width := LENGTH(Msg) + 2;

        WinOpts := wBordered + wClear + wSaveContents;

        {center the cylon box in mid screen}
        X1 := (ScreenWidth - Width) DIV 2;
        X2 := X1 + Width;
        Y1 := 11;
        Y2 := 14;

        NEW(MsgWin, InitCustom(X1, Y1, X2, Y2, EsColors, WinOpts));
        IF MsgWin = NIL THEN
            FAIL;

        MsgWin^.wFrame.AddShadow(shBR, shSeeThru);
        MsgWin^.EnableExplosions(8);
        HideMouse;
        MsgWin^.Draw;
        MsgWin^.wFastText(Center(Msg, Width-1), 2, 1);
        MsgWin^.SetCursor(cuHidden);
        StartTime := Timer;
        REPEAT
            IF KbdKeyPressed THEN
                BREAK;
        UNTIL ABS(Timer - StartTime) > 200;
    END;

    (****************************************************************************)

    DESTRUCTOR KTellUser.Done;
        {- kill time delayed message window object}
    BEGIN
        MsgWin^.ERASE;
        ShowMouse;
        DISPOSE(MsgWin, Done);
    END;

    (****************************************************************************)

    FUNCTION KDialog(Msg : STRING; Title : STRING; TitleColor : BYTE;
                     Box1 : STRING; Box2 : STRING) : INTEGER;
    VAR
        KMSG           : MsgArray;
        EsColors       : ColorSet;
        dColors        : DialogColorSet;
        Result         : WORD;
    BEGIN
        GetScheme(RedDialog_Scheme, EsColors, dColors);

        FILLCHAR(KMSG, SIZEOF(KMSG), #0);

        KMSG[1] := Msg;
        KMSG[2] := Box1;
        KMSG[3] := Box2;

        Result := MessageBox(Title,
                             KMSG,
                             1000,
                             EsColors,
                             dColors);

        IF Result = ccDone THEN
            KDialog := 1
        ELSE
            KDialog := 2;

    END;

    (****************************************************************************)

    PROCEDURE InitMsgArray(VAR Msg : MsgArray);
    BEGIN
        FILLCHAR(Msg, SIZEOF(Msg), #0);
    END;

    (****************************************************************************)

    {-message window, 5 line max, shrinkwraps the text, no buttons }
    {2 second disp time}
    PROCEDURE MessageWin(Header         : STRING;
                         VAR Msg        : MsgArray;
                         VAR EsColors   : ColorSet);
    CONST
        WinOpts        = wBordered + wClear;
    VAR
        I,
        X,
        Y,
        BoxHeight,
        MsgWidth       : INTEGER;
        MsgWin         : RawWindowPtr;
    BEGIN
        MsgWidth := 0;
        BoxHeight := 0;

        FOR I := 1 TO MSGSIZE DO BEGIN
            IF LENGTH(Msg[I]) > MsgWidth THEN
                MsgWidth := LENGTH(Msg[I]);
            IF LENGTH(Msg[I]) > 0 THEN
                BoxHeight := I;
        END;

        IF BoxHeight = 0 THEN
            EXIT;

        INC(MsgWidth, 6);

        IF MsgWidth < 28 THEN
            MsgWidth := 28;

        X := (ScreenWidth - MsgWidth - 2) DIV 2;
        Y := (ScreenHeight - BoxHeight) DIV 2;

        NEW(MsgWin, InitCustom(X, Y, X + MsgWidth, Y + BoxHeight - 1, EsColors, WinOpts));

        IF MsgWin = NIL THEN
            EXIT;

        MsgWin^.wFrame.AddHeader(Header, heTC);
        MsgWin^.wFrame.AddShadow(shBR, shSeeThru);
        MsgWin^.EnableExplosions(8);

        HideMouse;
        MsgWin^.Draw;
        MsgWin^.SetCursor(cuHidden);

        FOR I := 1 TO BoxHeight DO
            MsgWin^.wFastText(Center(Msg[I], MsgWidth), I, 1);

        Beep(OLDBEEP);
        Delay(3000);
        MsgWin^.ERASE;
        ShowMouse;
        DISPOSE(MsgWin, Done);

    END;

    (****************************************************************************)

END.
