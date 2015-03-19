/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
        call VROptions 'NoEchoQuit'
    end
    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
    __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
    if __vrlsWait then do
        call VRFlush
    end
    __vrlsHWnd = VRLoad( VRWindow(), VRWindowPath(), arg(1) )
    if __vrlsHWnd = '' then signal __vrlsDone
    if __vrlsWait \= 1 then signal __vrlsDone
    call VRSet __vrlsHWnd, 'WindowMode', 'Modal' 
    __vrlsTmp = __vrlsWindows.0
    if( DataType(__vrlsTmp) \= 'NUM' ) then do
        __vrlsTmp = 1
    end
    else do
        __vrlsTmp = __vrlsTmp + 1
    end
    __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
    __vrlsWindows.0 = __vrlsTmp
    do while( VRIsValidObject( VRWindow() ) = 1 )
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
    end
    __vrlsTmp = __vrlsWindows.0
    __vrlsWindows.0 = __vrlsTmp - 1
    call VRWindow __vrlsWindows.__vrlsTmp 
    __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         COLORD_Close
*/
COLORD_Close:
    call Quit
return

/*:VRX         DownButton_Click
*/
DownButton_Click: 
    S = VRGet( "ColumnList", "Selected" )
    if S = 0 THEN DO
        Ok = Beep(2000, 500)
        return
    end

    if S < 9 THEN DO
        ok = VRMethod( "ColumnList", "GetStringList",   AllNames. )
        ok = VRMethod( "ColumnList", "GetItemDataList", AllData. )

        N = S + 1

        TempName = AllNames.N
        TempData = AllData.N

        AllNames.N = AllNames.S 
        AllData.N = AllData.S

        AllNames.S = TempName
        AllData.S = TempData

        ok = VRMethod( "ColumnList", "Reset" ) 
        ok = VRMethod( "ColumnList", "AddStringList", AllNames., 1, AllData. )
        ok = VRSet( "ColumnList", "Selected", N )
    END
    ELSE DO
        ok  = Beep( 2000, 500 )
    END

return

/*:VRX         ExitButton_Click
*/
ExitButton_Click: 
    call SetColumnOrder
    Call Quit
return

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         HideShowButton_Click
*/
HideShowButton_Click: 
    S = VRGet( "ColumnList", "Selected" )
    if s = 0 then do
        ok  = Beep( 2000, 500 )
        return
    end

    ok = VRMethod( "ColumnList", "GetStringList",   AllNames. )
    ok = VRMethod( "ColumnList", "GetItemDataList", AllData. )

    String = AllNames.S
    Data = AllData.S

    Data = Data * -1
    String = Substr(String, 2, length(String)-1)
      
    if data < 0 THEN DO
        String = "-" || String
    end
    else do
        String = "+" || String
    end            
    AllNames.S = String
    AllData.S = Data

    ok = VRMethod( "ColumnList", "Reset" ) 
    ok = VRMethod( "ColumnList", "AddStringList", AllNames., 1, AllData. )
    ok = VRSet( "ColumnList", "Selected", S )
return

/*:VRX         Init
*/
Init:
    /* NB page prefixes for containers */
    Contnames.1 = "WWW"
    Contnames.2 = "App"
    Contnames.3 = "PIN"
    Contnames.4 = "Combo"
    Contnames.5 = "Other1"
    Contnames.6 = "Other2"
    Contnames.0 = 6

    window = VRWindow()
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window

    PgNum = SubStr( vrget(initargs.1,"Name"), 3, 1, " " )

    Value = KRGetPageName(PgNum)
    if Value <> "" THEN DO
        ok = VRSet( "COLORD", "Caption", Value )
    END

    do j = 1 to 9 
        ColumnNames.J = KRGetColumnName(PgNum, j)
        if  KRGetPageEnable(PgNum, J) = "1" then do
            ColumnNames.J = "+" || ColumnNames.J
            ColumnData.J = J
        end
        else do
            ColumnNames.J = "-" || ColumnNames.J
            ColumnData.J = J * -1
        end
    end

    ColumnNames.0 = 9
    ColumnData.0 = 9
    
    ok = VRMethod( "ColumnList", "Reset" )
    ok = VRMethod( "ColumnList", "AddStringList", ColumnNames., 1, ColumnData. )
return

/*:VRX         Quit
*/
Quit:
    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return

/*:VRX         SetColumnOrder
*/
SetColumnOrder: 
    
return

/*:VRX         UpButton_Click
*/
UpButton_Click: 
    S = VRGet( "ColumnList", "Selected" )
    if S > 1 THEN DO
        ok = VRMethod( "ColumnList", "GetStringList",   AllNames. )
        ok = VRMethod( "ColumnList", "GetItemDataList", AllData. )

        N = S - 1

        TempName = AllNames.N
        TempData = AllData.N

        AllNames.N = AllNames.S 
        AllData.N = AllData.S

        AllNames.S = TempName
        AllData.S = TempData

        ok = VRMethod( "ColumnList", "Reset" ) 
        ok = VRMethod( "ColumnList", "AddStringList", AllNames., 1, AllData. )
        ok = VRSet( "ColumnList", "Selected", N )
    END
    ELSE DO
        ok  = Beep( 2000, 500 )
    END
return

