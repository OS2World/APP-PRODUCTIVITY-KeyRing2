/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    PARSE SOURCE . Calledas .
    Parent = ""
    Argcount = ARG()
    Argoff = 0
    IF( Calledas \= "COMMAND" )THEN DO
        IF Argcount >= 1 THEN DO
            Parent = ARG(1)
            Argcount = Argcount - 1
            Argoff = 1
        END
    END
        ELSE DO
            CALL Vroptions 'ImplicitNames'
            CALL Vroptions 'NoEchoQuit'
        END
    Initargs.0 = Argcount
    IF( Argcount > 0 )THEN
        DO I = 1 TO Argcount
            Initargs.i = ARG( I + Argoff )
        END
    DROP Calledas Argcount Argoff

/*  Load the windows
*/
    CALL Vrinit
    PARSE SOURCE . . Spec
    _vreprimarywindowpath = ,
        Vrparsefilename( Spec, "dpn" ) || ".VRW"
    _vreprimarywindow = ,
        Vrload( Parent, _vreprimarywindowpath )
    DROP Parent Spec
    IF( _vreprimarywindow == "" )THEN DO
        CALL Vrmessage "", "Cannot load window:" Vrerror(), ,
            "Error!"
        _vrereturnvalue = 32000
        SIGNAL _vreleavemain
    END

/*  Process events
*/
    CALL Init
    SIGNAL ON HALT
    DO While( \ Vrget( _vreprimarywindow, "Shutdown" ) )
        _vreevent = Vrevent()
        INTERPRET _vreevent
    END
_vrehalt:
    _vrereturnvalue = Fini()
    CALL Vrdestroy _vreprimarywindow
_vreleavemain:
    CALL Vrfini
    EXIT _vrereturnvalue

Vrloadsecondary:
    __vrlswait = ABBREV( 'WAIT', TRANSLATE(ARG(2)), 1 )
    IF __vrlswait THEN DO
        CALL Vrflush
    END
    __vrlshwnd = Vrload( Vrwindow(), Vrwindowpath(), ARG(1) )
    IF __vrlshwnd = '' THEN
        SIGNAL __vrlsdone
    IF __vrlswait \= 1 THEN
        SIGNAL __vrlsdone
    CALL Vrset __vrlshwnd, 'WindowMode', 'Modal'
    __vrlstmp = __vrlswindows.0
    IF( DATATYPE(__vrlstmp) \= 'NUM' ) THEN DO
        __vrlstmp = 1
    END
        ELSE DO
            __vrlstmp = __vrlstmp + 1
        END
    __vrlswindows.__vrlstmp = Vrwindow( __vrlshwnd )
    __vrlswindows.0 = __vrlstmp
    DO While( Vrisvalidobject( Vrwindow() ) = 1 )
        __vrlsevent = Vrevent()
        INTERPRET __vrlsevent
    END
    __vrlstmp = __vrlswindows.0
    __vrlswindows.0 = __vrlstmp - 1
    CALL Vrwindow __vrlswindows.__vrlstmp
    __vrlshwnd = ''
__vrlsdone:
RETURN __vrlshwnd

/*:VRX         ExitButton_Click
*/
Exitbutton_click:
    CALL Quit
RETURN

/*:VRX         Fini
*/
Fini:
    Window = Vrwindow()
    CALL Vrset Window, "Visible", 0
    DROP Window
RETURN Vrget( "NewPWField", "Value" )


/*:VRX         Halt
*/
Halt:
    SIGNAL _vrehalt
RETURN

/*:VRX         Init
*/
Init:
    Window = Vrwindow()
    CALL Vrmethod Window, "CenterWindow"
    CALL Vrset Window, "Visible", 1
    CALL Vrmethod Window, "Activate"
    DROP Window
RETURN

/*:VRX         NewPW_Close
*/
Newpw_close:
    CALL Quit
RETURN

/*:VRX         Quit
*/
Quit:
    CALL Saveprops
    Window = Vrwindow()
    CALL Vrset Window, "Shutdown", 1
    DROP Window
RETURN

/*:VRX         RestoreProps
*/
Restoreprops:
RETURN
    Ok = Vrmethod( Vrget(Vrwindow(), "name"), "ListChildren", "child." )

    Lastchild=Child.0+1
    Child.lastchild= Vrget(Vrwindow(), "name")
    Child.0=Lastchild
    Initstring=""
    DO X=1 TO Child.0
        Value = Vrgetini( "KR2", Vrget(Child.x, Name), "KR2.INI", "NOCLOSE" )
        PARSE VAR VALUE Font "þ" Fore "þ" Back
        Ok = Vrset(Child.x, "font", Font)
        Ok = Vrset(Child.x, "forecolor", Fore)
        Ok = Vrset(Child.x, "backcolor", Back)
    END

RETURN

/*:VRX         SaveButton_Click
*/
Savebutton_click:
    /* Save the new password, if they match */
    IF Vrget( "NewPWField", "Value" ) = Vrget( "VerifyPWField", "Value" ) THEN
        CALL Quit
        ELSE DO
            Buttons.1 = "Retry"
            Buttons.2 = "Exit"
            Buttons.0 = 2
            Id = Vrmessage( Vrwindow(), "Password Verification Failure", "Warning", "Warning", "Buttons.", 1, 2 )
            IF Id = 2 THEN DO
                Ok = Vrset( "NewPWField", "Value", "" )
                CALL Quit
            END
        END
RETURN

/*:VRX         SaveProps
*/
Saveprops:
RETURN
    Ok = Vrmethod( Vrget(Vrwindow(), "name"), "ListChildren", "child." )

    Lastchild=Child.0+1
    Child.lastchild = Vrget(Vrwindow(), "name")
    Child.0 = Lastchild
    Initstring = ""
    DO X = 1 TO Child.0
        IF Vrmethod( "Application", "SupportsProperty", Child.x , "font" ) = 1 THEN DO
            IF Vrmethod( "Application", "SupportsProperty", Child.x , "forecolor" ) = 1 THEN DO
                IF Vrmethod( "Application", "SupportsProperty", Child.x , "backcolor" ) = 1 THEN DO
                    Initstrg = Vrget(Child.x, "font") || "þ" Vrget(Child.x, "forecolor") || "þ" Vrget(Child.x, "backcolor")
                    Ok = Vrsetini( "KR2", Vrget(Child.x, "Name"), Initstrg, "KR2.INI", "NOCLOSE" )
                END
            END
        END
    END

RETURN

