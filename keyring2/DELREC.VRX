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

/*:VRX         AbortButton_Click
*/
AbortButton_Click: 
    DelRecRes = 0
    call quit
return

/*:VRX         DeleteButton_Click
*/
DeleteButton_Click: 
    DelrecRes = 1
    call quit
return

/*:VRX         DELREC_Close
*/
DELREC_Close:
    call Quit
return

/*:VRX         DelRec_LangInit
*/
DelRec_LangInit: 

return

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return DelRecRes

/*:VRX         GetCaption
*/
Getcaption: PROCEDURE EXPOSE Initargs.
    Page = ARG(1)
    Index = ARG(2)
    Strg = Krgetcolumnname(Page, Index)
    IF Strg <> "" THEN DO
        RETURN Strg
    END
    Order = ARG(3)
    Flg = SUBSTR(Order, Index, 1)
    SELECT
        WHEN Flg = "I" THEN DO
            RETURN ""
        END
        WHEN Flg = "D" THEN DO
            RETURN Vlsmsg(143)
        END
        WHEN Flg = "P" THEN DO
            RETURN Vlsmsg(149)
        END
        WHEN Flg = "N" THEN DO
            RETURN Vlsmsg(145)
        END
        WHEN Flg = "S" THEN DO
            RETURN Vlsmsg(147)
        END
        WHEN Flg = "L" THEN DO
            RETURN "ZZZZ"
        END
        WHEN Flg = "E" THEN DO
            RETURN Vlsmsg(154)
        END
        WHEN Flg = "U" THEN DO
            RETURN Vlsmsg(150)
        END
        WHEN Flg = "W" THEN DO
            RETURN Vlsmsg(153)
        END
        OTHERWISE DO
            RETURN "YYYY"
        END
    END
RETURN

/*:VRX         GetEditFieldName
*/
Geteditfieldname: PROCEDURE EXPOSE Initargs.
    /* given a flag, return the name of the corresponding editor field */
    Flag = ARG(1)                                     /* get the flag */
    SELECT
        /* parse the non sequential fields */
        WHEN Flag = "I" THEN DO                               /* icon */
            RETURN "IconField"
        END
        WHEN Flag = "L" THEN DO
            RETURN "LastUpdateField"
        END
        WHEN Flag = "E" THEN DO
            RETURN "CurrentExpDateField"
        END
        OTHERWISE DO
            /* it must be a user-editable text field */

            /* get the order field for this record */
            Ok = Vrmethod(Initargs.1, "GetFieldData", Initargs.2, "Fieldvals." )
            Order = Fieldvals.10
            Fldnum = 0
            /* start stepping through the order list, looking for our flag position */
            DO I = 1 TO LENGTH(Order)
                Tf = SUBSTR(Order, I, 1)/* get the temp flag at this position */
                SELECT
                    /* skip the non sequential fields */
                    WHEN Tf = "I" THEN DO
                    END
                    WHEN Tf = "L" THEN DO
                    END
                    WHEN Tf = "E" THEN DO
                    END
                    WHEN Tf = "O" THEN DO/* paranoia: skip the order field - should never get here */
                    END
                    OTHERWISE DO
                        Fldnum = Fldnum + 1/* accumulate the text field count */
                    END
                END
                IF Flag = Tf THEN DO/* the current flag is the one we are looking for */
                    RETURN "F" || Fldnum/* return the Nth text field from the accumulator */
                END
            END
        END
    END
RETURN "F1"                                 /* should never get here! */

/*:VRX         GetFieldIndex
*/
Getfieldindex: PROCEDURE EXPOSE Initargs.
    /* look up field index for this flag */
    Flag = ARG(1)

    Ok = Vrmethod(Initargs.1, "GetFieldData", Initargs.2, "Fieldvals." )
    Order = Fieldvals.10
    DO I = 1 TO 9
        IF Flag = SUBSTR(Order, I, 1) THEN DO
            RETURN I
        END
    END
RETURN 0

/*:VRX         GetHintText
*/
Gethinttext: PROCEDURE
    Indx = ARG(1)
    Order = ARG(2)
    Strg = Krgetcolumnenable(Curpagenum, Indx)
    IF Strg = "" THEN DO
        Flg = SUBSTR(Order, Indx, 1)
        SELECT
            WHEN Flg = "I" THEN DO
                RETURN Vlsmsg(157)
            END
            WHEN Flg = "D" THEN DO
                RETURN Vlsmsg(142)
            END
            WHEN Flg = "P" THEN DO
                RETURN Vlsmsg(146)
            END
            WHEN Flg = "N" THEN DO
                RETURN Vlsmsg(144)
            END
            WHEN Flg = "S" THEN DO
                RETURN Vlsmsg(146)
            END
            WHEN Flg = "L" THEN DO
                RETURN ""
            END
            WHEN Flg = "E" THEN DO
                RETURN Vlsmsg(154)
            END
            WHEN Flg = "U" THEN DO
                RETURN Vlsmsg(151)
            END
            WHEN Flg = "W" THEN DO
                RETURN Vlsmsg(152)
            END
            OTHERWISE DO
                RETURN "YYYY"
            END
        END
    END
        ELSE DO
            PARSE VAR Strg Enb "þ" Flg "þ" Hint "þ" Abbrev
            drop abbrev
            RETURN Hint
        END
RETURN
/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         Init
*/
Init:
    Ok = RXFUNCADD("VLLoadFuncs", "VLMSG", "VLLoadFuncs")/* do not modify or move this line! It must be on line #2 of this function */
    CALL Vlloadfuncs/* do not modify or move this line! It must be on line #3 of this function */
    Ok = Vrredirectstdio("On", "keyring2.err")

    DelRecRes = 0

    /* args
        1 container handle
        2 record handle
        3 page#
        4 appname
        5 ininame
    */

    Appname = Initargs.4
    Ininame = Initargs.5
    Curpagenum = Initargs.3

    Langname = Vrgetini( Appname, "LANGUAGE", Ininame )
    IF Langname = "" THEN DO
        Langname = "ENGLISH.MSG"
    END
    Ok = Vlopenlang(Langname, Langname)
    CALL DelRec_LangInit

    Ok = Vrmethod( Initargs.1, "GetFieldData", Initargs.2, "Fieldvals." )

    Iconindx = Getfieldindex("I")
    Lastindx = Getfieldindex("L")
    Expindx = Getfieldindex("E")
    Passindx = Getfieldindex("P")

    Passwordfield = Geteditfieldname("P")

    Order = Fieldvals.10

    DO I = 1 TO 9
        Tflg = SUBSTR(Order, I, 1)
        Tfld = Geteditfieldname(Tflg)
        SELECT
            WHEN I = Iconindx THEN DO
                Ok = Vrset(Tfld, "PicturePath", Fieldvals.i)
                Ok = Vrset(Tfld, "HintText", Gethinttext(I, Order))
            END
            OTHERWISE DO
                Ok = Vrset(Tfld, "Value", Fieldvals.i)
                Ok = Vrset(Tfld, "HintText", Gethinttext(I, Order))
                Ok = Vrset(Tfld || "Caption", "Caption", Getcaption(Curpagenum, I, Order))
            END
        END
    END

    /* set window location */
    Value = Vrgetini( Appname, "DELRECTOP", Ininame )
    IF Value = "" THEN do
        Value = 1156
    end
    Delrectop = Value

    Value = Vrgetini( Appname, "DELRECLEFT", Ininame )
    IF Value = "" THEN do
        Value =434
    end
    DELrecleft = Value

    Value = Vrgetini( Appname, "DELRECHYT", Ininame )
    IF Value = "" THEN do
        Value = 7480
    end
    DELrechyt = Value

    Value = Vrgetini( Appname, "DELRECWID", Ininame )
    IF Value = "" THEN do
        Value = 5974
    end
    DELrecwidth = Value

    Ok = Vrset( "DELREC", "Top", DELrectop )
    Ok = Vrset( "DELREC", "Left", DELrecleft )
    Ok = Vrset( "DELREC", "Height", DELrechyt )
    Ok = Vrset( "DELREC", "Width", DELrecwidth )

    Window = Vrwindow()
    CALL Vrset Window, "Visible", 1
    CALL Vrmethod Window, "Activate"
    DROP Window

    DELresult = ""
return

/*:VRX         Quit
*/
Quit:
    Ok = Vrsetini( Appname, "DELRECTOP", Vrget("DELREC", "Top" ), Ininame)
    Ok = Vrsetini( Appname, "DELRECLEFT", Vrget("DELREC", "Left" ), Ininame)
    Ok = Vrsetini( Appname, "DELRECHYT", Vrget("DELREC", "Height" ), Ininame)
    Ok = Vrsetini( Appname, "DELRECWID", Vrget("DELREC", "Width" ), Ininame)

    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return 
