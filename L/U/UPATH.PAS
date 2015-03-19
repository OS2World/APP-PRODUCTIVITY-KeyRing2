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
* This module implements a path selector dialog box that allows the user
* to browse the availible disk drives and paths.  It does NOT show files
* present in the paths.  Optional path validation for typed-in paths
*
* Kevin G. McCoy, NewsMaker Systems
* 11/93
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F+,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
{$I OPDEFINE.INC}
{$D+,L+,X+}
{$I NDEFINE.INC}
{$IFDEF UseDrag}
  {$DEFINE UsingDrag}
{$ELSE}
  {$DEFINE UseDragAnyway} {<--- define this to force use of OPDRAG}
  {$IFDEF UseDragAnyway}
    {$DEFINE UsingDrag}
  {$ENDIF}
{$ENDIF}

{$IFNDEF UseHotSpots}
  !! The settings in OPDEFINE.INC are not compatible with this program.
{$ENDIF}

UNIT UPATH;
    {-Dialog box example with Combo edit control}
INTERFACE
USES
    Dos,
    OpCmd,
    OpCrt,
    OpCtrl,
    OpDialog,
    OpDir,
    UXTree,
    OpPick,
{$IFDEF UsingDrag}
    OpDrag,
{$ENDIF}
    OpRoot;
TYPE
    DriveArray = ARRAY['A'..'Z'] OF BOOLEAN;
    {Internal use only}
    {Drivelist is used to select one of the active disk drives}
    DriveListPtr   = ^DriveList;
    DriveList      = OBJECT(PickList)
                         CONSTRUCTOR Init(X1, Y1 : BYTE; VAR Colors : ColorSet);
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetDrive : CHAR;

                         PRIVATE

                         CTP            : CmdTablePtr;
                         ActiveDrives   : DriveArray;

                         PROCEDURE ItemString(Item           : WORD;
                                              Mode           : pkMode;
                                              VAR IType      : pkItemType;
                                              VAR IString    : STRING); VIRTUAL;

                         PROCEDURE EnableDrives(VAR Enabled : DriveArray);
                     END;

    {a path dialog allows the user to either type in a path or browse the}
    {visible drives for a valid path.  The path browser displays a       }
    {"graphical" representation of the subdirectory hierarchy            }

    PathDialogP    = ^PathDialog;
    PathDialog     = OBJECT(Root)
                         {if CheckValidity is TRUE, don't let the user   }
                         {exit the dialog without a valid, writeable path}
                         CONSTRUCTOR Init(CheckValidity  : BOOLEAN;
                                          Colors         : ColorSet;
                                          dColors        : DialogColorSet);
                         DESTRUCTOR Done; VIRTUAL;

                             {run the dialog}
                         PROCEDURE Process;

                         PROCEDURE EnableDrives(VAR Enabled : DriveArray);

                             {returns the selected path, if any}
                         FUNCTION GetPath : PathStr;

                         FUNCTION GetLastCommand : WORD;

                         PRIVATE

                             {keep your pinkeys out of this stuff}
                         Validate       : BOOLEAN;
                         CurDrive       : CHAR;
                         Path           : XTreePathList;
                         St             : PathStr;
                         PL             : DriveList;
                         Status         : WORD;
                         Finished       : BOOLEAN;
                         Coords         : WindowCoordinates;
                         {$IFDEF UseDragAnyway}
                         DragCommands   : DragProcessor;
                         {$ENDIF}

                         FUNCTION InitPathPick(VAR Colors : ColorSet) : WORD;
                         FUNCTION InitDriveList(VAR Colors : ColorSet) : WORD;
                         FUNCTION InitDialogBox(VAR Colors : ColorSet; VAR dColors : DialogColorSet) : WORD;
                     END;

    {-------------------------------------------------------------}

IMPLEMENTATION
USES
    OpAbsFld,
    OpCol16,
    OpDos,
    OpEnhKbd,
    OpField,
    OpFrame,
    OpInline,
    OpKey,
{$IFDEF UseMouse}
    OpMouse,
{$ENDIF}
    OpSelect,
    OpString,
    OpWindow,
    SHARE,
    STRINGS,
    UColors,
    UDIALOG,
    UWindow,
    WinDos;
    {-------------------------------------------------------------}


CONST
    KEYSETMAX      = 100;
VAR
    FPath : PathStr;
    DBP             : DialogBoxPtr;

    {---------------}

    PROCEDURE DriveMoveProc(P : PickListPtr); FAR;
    VAR
        Drive : CHAR;
        CurPath : PCHAR;
    BEGIN
(*        GetMemCheck(CurPath, 80);
        Drive := DriveListPtr(P)^.GetDrive;
        GetCurDir(CurPath, BYTE(ORD(Drive) - ORD('@')));
        FPath := StrPas(CurPath);
        FreeMemCheck(CurPath, 80);
        {PathDialogP(P^.ParentPtr)^.DB.Draw;}
        DBP^.Select;
        DBP^.Draw; *)
    END;

    {---------------}


    CONSTRUCTOR DriveList.Init(X1, Y1 : BYTE; VAR Colors : ColorSet);
    VAR
        C              : CHAR;
        NumDrives      : BYTE;
        PickWindowOptions,
        PickListOptions : LONGINT;
    BEGIN
        {clear the active drive list}
        FILLCHAR(ActiveDrives, SIZEOF(ActiveDrives), #0);

        NumDrives := 0;

        {set the flags for each valid drive}
        FOR C := 'A' TO 'Z' DO BEGIN
            IF ValidDrive(C) THEN BEGIN
                ActiveDrives[C] := TRUE;
                INC(NumDrives);
            END;
        END;


        PickWindowOptions := DefWindowOptions OR wBordered;
        PickListOptions := pkStick + pkAlterPageRow + pkMousePage + pkDrawActive +
                           pkSetDefault;

        IF NOT PickList.InitAbstractDeluxe(X1 + 1, Y1 + 1, X1 + 3, Y1 + 10,
                                           Colors,
                                           PickWindowOptions,
                                           2,
                                           NumDrives,
                                           PickVertical,
                                           SingleChoice,
                                           PickListOptions) THEN
            FAIL;

        CustomizeCommandProcessor(PickCommands);

        GetMemCheck(CTP, KEYSETMAX);
        IF CTP = NIL THEN
            FAIL;

        FILLCHAR(CTP^, KEYSETMAX, 0);

        PickCommands.SetSecondaryKeyPtr(CTP, KEYSETMAX);

        IF PickCommands.GetLastError <> 0 THEN
            RingBell;

        pkOptionsOn(pkProcessZero);
        PickCommands.cpOptionsOn(cpSwitchPriority);
        SetSearchMode(PickStringSearch);

        AddSearchHeader(10, heBL);
        wFrame.AddScrollBar(frRR, 1, MAXLONGINT, Colors);

        RawWindow.EnableExplosions(8);
        SetMoveProc(DriveMoveProc);
    END;

    {-------------------------------------------------------------}

    DESTRUCTOR DriveList.Done;
    BEGIN
        FreeMemCheck(CTP, KEYSETMAX);
        INHERITED Done;
    END;

    {-------------------------------------------------------------}

    PROCEDURE DriveList.EnableDrives(VAR Enabled : DriveArray);
    VAR
        C : CHAR;
        I : BYTE;
    BEGIN
        I := 0;
        FOR C := 'A' TO 'Z' DO BEGIN
            ActiveDrives[C] := ActiveDrives[C] AND Enabled[C];
            IF ActiveDrives[C] THEN
                INC(I);
        END;
        ChangeNumItems(I);
    END;

    {-------------------------------------------------------------}

    {- return the drive picked by the user}
    FUNCTION DriveList.GetDrive : CHAR;
    VAR
        I,
        Item           : BYTE;
        C              : CHAR;
    BEGIN
        I := 0;
        Item := GetLastChoice;
        GetDrive := #0;
        FOR C := 'A' TO 'Z' DO BEGIN
            IF ActiveDrives[C] THEN
                INC(I);
            IF I = Item THEN BEGIN
                GetDrive := C;
                EXIT;
            END;
        END;

    END;

    {-------------------------------------------------------------}

    {- return formatted drive letter string to the picklist}
    PROCEDURE DriveList.ItemString(Item           : WORD;
                                   Mode           : pkMode;
                                   VAR IType      : pkItemType;
                                   VAR IString    : STRING);
    VAR
        I              : BYTE;
        C              : CHAR;
    BEGIN
        IString := '';
        I := 0;
        FOR C := 'A' TO 'Z' DO BEGIN
            IF ActiveDrives[C] THEN
                INC(I);
            IF I = Item THEN BEGIN
                IString := 'A:';
                IString[1] := C;
                EXIT;
            END;
        END;
    END;

    {-------------------------------------------------------------}


CONST
  {$IFDEF UseMouse}
    MouseChar      : CHAR = #04;
  {$ENDIF}

    {control ID's}
    idDriveSel     = 0;
    idPathEditor   = idDriveSel + 1;
    idPathTree     = idPathEditor + 1;
    idOk           = idPathTree + 1;
    idCancel       = idOk + 1;
    idHelp         = idCancel + 1;

    hiEditor       = 1;
    hiPickEd       = hiEditor + 1;
    hiWindow       = hiPickEd + 1;
    HiOk           = hiWindow + 1;
    hiCancel       = HiOk + 1;
    HiHelp         = hiCancel + 1;

    {-------------------------------------------------------------}

    {- things to do just before dialog changes control focus}
    PROCEDURE PreFocus(DBP : DialogBoxPtr);
    VAR
        Coords         : WindowCoordinates;
    BEGIN
        WITH Coords DO BEGIN
            DBP^.Coordinates(XL, YL, XH, YH);
            CASE DBP^.GetCurrentID OF
                {assign exit command to edit control}
                idDriveSel :
                    BEGIN
                        FastWrite('Press Arrow keys to select drive', YH + 1, XL + 3, WhiteOnLtGray);
                        DialogCommands.AddCommand(ccUser0, 1, Enter, 0);
                    END;
                idPathEditor :
                    BEGIN
                        FastWrite('Press Alt-V for path list       ', YH + 1, XL + 3, WhiteOnLtGray);
                        DialogCommands.AddCommand(ccSelect, 1, Enter, 0);
                    END;
                idOk :
                    BEGIN
                        FastWrite('Press Enter to save/exit        ', YH + 1, XL + 3, WhiteOnLtGray);
                        DialogCommands.AddCommand(ccSelect, 1, Enter, 0);
                    END;
                idCancel :
                    BEGIN
                        FastWrite('Press Enter to exit without save', YH + 1, XL + 3, WhiteOnLtGray);
                        DialogCommands.AddCommand(ccSelect, 1, Enter, 0);
                    END;
                idPathTree :
                    BEGIN
                        FastWrite('Press Enter to view all paths   ', YH + 1, XL + 3, WhiteOnLtGray);
                        DialogCommands.AddCommand(ccSelect, 1, Enter, 0);
                    END;
                idHelp :
                    FastWrite('Press Enter to view help        ', YH + 1, XL + 3, WhiteOnLtGray);

            END;                  {CASE}
        END;
    END;

    {-------------------------------------------------------------}

    {- things to do just after dialog changes focus to a new control}
    PROCEDURE PostFocus(DBP : DialogBoxPtr); FAR;
    BEGIN
        CASE DBP^.GetCurrentID OF
            {remove exit command when done with edit control}
            idPathEditor : {DialogCommands.AddCommand(ccNone, 1, AltDown, 0)};
            idDriveSel :
                BEGIN
                    DBP^.SetNextField(idPathEditor);
                    DialogCommands.AddCommand(ccNone, 1, Enter, 0);
                END;
            {return focus to edit control after selecting pick list}
            idPathTree :
                BEGIN
                    DBP^.SetNextField(idPathEditor);
                    DialogCommands.AddCommand(ccNone, 1, Enter, 0);
                END;
        END;
    END;

    {-------------------------------------------------------------}

    PROCEDURE PathMoveProc(P : PickListPtr); FAR;
    BEGIN
        FPath := StUpCase(PathListPtr(P)^.GetMultiPath(P^.GetLastChoice));
        DBP^.Select;
        DBP^.Draw;
        P^.Select;
        P^.Draw;
    END;

    {---------------------------------------}


    {init the pathpicker (hierarchical subdir picklist)}
    FUNCTION PathDialog.InitPathPick(VAR Colors : ColorSet) : WORD;
    BEGIN
        WITH Path DO BEGIN
            IF NOT InitCustom(29, 9, 54, 17, {Window coordinates}
                              Colors, {ColorSet}
                              DefWindowOptions OR wBordered, {Window options}
                              8000, {Max heap space for files}
                              PickVertical, {Pick orientation}
                              SinglePath) {Command handler}
            THEN BEGIN
                InitPathPick := InitStatus;
                EXIT;
            END;
            CustomizeCommandProcessor(PickCommands);
            paOptionsOn(paAltCurDir);
            SetPadSize(1, 1);
            {$IFDEF UseScrollBars}
            wFrame.AddCustomScrollBar(frRR, 0, MAXLONGINT, 1, 1, 'þ', '°', Colors);
            {$ENDIF}
            InitPathPick := RawError;
            SetMoveProc(PathMoveProc);
        END;
    END;

    {-------------------------------------------------------------}

    {init the drive letter picklist - this could be done elsewhere I guess...}
    FUNCTION PathDialog.InitDriveList(VAR Colors : ColorSet) : WORD;
        {-Initialize pick list}
    BEGIN
        PL.Init(1, 1, Colors);
        InitDriveList := PL.RawError;
    END;

    {-------------------------------------------------------------}

    {- init the dialog box and its controls}
    FUNCTION PathDialog.InitDialogBox(VAR Colors : ColorSet; VAR dColors : DialogColorSet) : WORD;
    CONST
        WinOptions     = wBordered + wClear + wUserContents;
    BEGIN
            {instantiate dialog box}
        NEW(DBP,  InitCustom(09, 4, 72, 20, Colors, WinOptions, dColors));
        IF DBP = NIL THEN BEGIN
            InitDialogBox := InitStatus;
            EXIT;
        END;
        WITH DBP^ DO BEGIN

            WITH wFrame, Colors DO BEGIN
                {$IFDEF UseShadows}
                AddShadow(shBR, shSeeThru);
                {$ENDIF}

                {add hot spot for closing the window}
                AddCustomHeader('[ ]', frTL, + 2, 0, HeaderColor, HeaderMono);
                AddCustomHeader('þ', frTL, + 3, 0, $7A, HeaderMono);
                AddHotRegion(frTL, hsRegion3, + 3, 0, 1, 1);
                AddHeader(' Path Selector ', heTC);

                {$IFDEF UsingDrag}
                {add hot spot for moving the window}
                AddHotBar(frTT, MovehotCode);
                {$ENDIF}
            END;

            {idDriveSel:}
            dgFieldOptionsOn(efAllowEscape);
            dgSecFieldOptionsOn(sefSwitchCommands);
            AddWindowControl('&Drives', 02, 2, 3, 2, hiWindow, ccNone, PL);

            {idPathEditor:}
            dgFieldOptionsOn(efClearFirstChar + efAutoAdvance);
            AddSimpleEditControl(
                '&Path', 2, 12, 'X', 3, 12, 39, 79, hiEditor, FPath);

            {idPathTree:}
            AddPushButton('&View Path', 3, 52, 11, 0, ccUser0, FALSE);


            {idOK:}
            AddPushButton('O&K', 16, 10, 8, HiOk, ccSelect, FALSE);

            {idCancel:}
            AddPushButton('&Cancel', 16, 29, 8, hiCancel, ccQuit, FALSE);

            {$IFNDEF NOHELP}
            {idHelp:}
            AddPushButton('Help', 16, 48, 8, HiHelp, ccHelp, FALSE);
            {$ENDIF}

            {start out on drive selector}
            SetNextField(idDriveSel);

            {set pre- and post-focus procedures}
            SetPreFocusProc(PreFocus);
            SetPostFocusProc(PostFocus);

            InitDialogBox := RawError;
        END;
    END;

    {---------------------------------------}

    {-Init the whole enchilada}
    CONSTRUCTOR PathDialog.Init(CheckValidity  : BOOLEAN;
                                Colors         : ColorSet;
                                dColors        : DialogColorSet);
    VAR
        Strg           : STRING;
        F              : FILE;
        Result         : WORD;
    BEGIN
        FPath := '';
        Validate := CheckValidity;

        {$IFDEF UseScrollBars}
        {select alternate scroll bar arrows}
        DefArrows := TriangleArrows;
        {$ENDIF}

        {initialize PathList}
        Status := InitPathPick(Colors);
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing PathList: ', Status);
            HALT(1);
        END;

        {initialize PickList}
        Status := InitDriveList(Colors);
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing PickList: ', Status);
            HALT(1);
        END;

        {initialize DialogBox}
        Status := InitDialogBox(Colors, dColors);
        IF Status <> 0 THEN BEGIN
            WRITELN('Error initializing DialogBox: ', Status);
            HALT(1);
        END;

        CustomizeCommandProcessor(DialogCommands);

        {$IFDEF UseDragAnyway}
        {initialize DragProcessor}
        DragCommands.Init(@DialogKeySet, DialogKeyMax);
        DBP^.SetCommandProcessor(DragCommands);
        CustomizeCommandProcessor(DragCommands);
        {$ELSE}
        {$IFNDEF UsingDrag}
        {$IFDEF UseMouse}
        if MouseInstalled then
            with Colors do begin
                {activate mouse cursor}
                SoftMouseCursor($0000, (ColorMono(MouseColor, MouseMono) shl 8)+
                                Byte(MouseChar));
                ShowMouse;

                {enable mouse support}
                DialogCommands.cpOptionsOn(cpEnableMouse);
            end;
        {$ENDIF}
        {$ENDIF}
        {$ELSE}
        {$ENDIF}

    END;

    {--------------------------}

    {blow off the whole mess}
    DESTRUCTOR PathDialog.Done;
    BEGIN
        DISPOSE(DBP, Done);
        Path.Done;
    END;

    {--------------------------}

    FUNCTION PathDialog.GetLastCommand : WORD;
    BEGIN
        GetLastCommand := DBP^.GetLastCommand;
    END;

    {--------------------------}

    PROCEDURE PathDialog.EnableDrives(VAR Enabled : DriveArray);
    BEGIN
        PL.EnableDrives(Enabled);
    END;

    {--------------------------}
    {run the dialog and trap some of the more blatant operator errors}
    PROCEDURE PathDialog.Process;
    VAR
        Strg           : STRING;
        F              : FILE;
        Result         : WORD;
        Msg            : MsgArray;
        Colors         : ColorSet;
        dColors        : DialogColorSet;
    BEGIN
        Finished := FALSE;
        InitMsgArray(Msg);

        REPEAT
            {process commands}
            DBP^.Process;

            CASE DBP^.GetLastCommand OF
                {$IFDEF UseMouse}
                {$IFDEF UsingDrag}
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(DBP^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Finished := TRUE;
                    END;
                {$ELSE}
                ccMouseSel :
                    Finished := True;
               {$ENDIF}
               {$ENDIF}
                ccQuit,
                ccError :
                    BEGIN
                        {bail out or error}
                        Finished := TRUE;
                        FPath := '';
                    END;
                ccSelect :
                    IF Validate THEN BEGIN
                        {try to create a temp file in the selected subdir}
                        IF GetTempFileName(FPath, Strg) = 0 THEN BEGIN
                            {was able to creat a file, so now erase it}
                            ASSIGN(F, Strg);
                            {$I-}
                            ERASE(F);
                            Result := IORESULT;
                            {$I+}
                            Finished := TRUE
                        END
                        ELSE BEGIN
                            {was not able to create the file, so yank the users chain}
                            RingBell;
                            Msg[1] := 'Invalid type-in path or insufficient directory rights.';
                            Msg[2] := 'Try another path';
                            GetScheme(RedDialog_Scheme, Colors, dColors);
                            CASE MessageBox(' WARNING ', Msg, 1, Colors, dColors) OF
                                ccQuit : ;
                                ccDone : ;
                                ccError : ;
                            END;  {CASE}
                        END;
                    END
                    ELSE
                        {not validating, so just quit}
                        Finished := TRUE;
                ccUser0 :
                    BEGIN
                        {user selected View Paths, so pop up the hierarchical subdir list}
                        WITH Coords DO BEGIN
                            DBP^.Coordinates(XL, YL, XH, YH);

                            Path.AdjustWindow(XL + 12, YL + 4, XL + 48, YL + 12);
                            HideMouse;
                            {the disk dir scan takes a while, so put up a message}
                            FastWrite(' Working... ', YL + 4, XL + 25, RedOnLtGreen);
                            FastWrite('Press Arrow keys to change paths', YH + 1, XL + 3, WhiteOnLtGray);
                            {find out what drive was picked}
                            CurDrive := PL.GetDrive;
                            {scan the selected drive and display the hier list}
                            St := StUpCase(Path.GetPathName(CurDrive));
                            {clear the message line}
                            FastWrite('            ', YL + 4, XL + 25, LtGrayOnLtGray);
                        END;
                        IF St <> '' THEN
                            FPath := St;
                    END;
            END;
        UNTIL Finished;

    END;

    {-------------------------------------------------------------}

    {- return the current path or empty string if none}
    FUNCTION PathDialog.GetPath : PathStr;
    BEGIN
        GetPath := FPath;
    END;

    {-------------------------------------------------------------}

END.
{-------------------------------------------------------------}
{-------------------------------------------------------------}

