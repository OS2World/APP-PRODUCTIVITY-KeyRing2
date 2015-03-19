/*:VRX Main */
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
    IF( Argcount > 0 )THEN DO I = 1 TO Argcount
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
    IF __vrlshwnd = '' THEN SIGNAL __vrlsdone
    IF __vrlswait \= 1 THEN SIGNAL __vrlsdone
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

/*:VRX Halt */
Halt:
    SIGNAL _vrehalt
RETURN

/*:VRX Init */
Init:
    Window = Vrwindow()
    CALL Vrmethod Window, "CenterWindow"
    CALL Vrset Window, "Visible", 1
    CALL Vrmethod Window, "Activate"
    DROP Window
RETURN

/*:VRX Quit */
Quit:
    Window = Vrwindow()
    CALL Vrset Window, "Shutdown", 1
    DROP Window
RETURN

/*:VRX Fini */
Fini:
    Window = Vrwindow()
    CALL Vrset Window, "Visible", 0
    DROP Window
RETURN 0

/*:VRX PWXOpen_Close */
Pwxopen_close:
    CALL Quit
RETURN

